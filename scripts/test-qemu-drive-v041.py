#!/usr/bin/env python3
"""QEMU gate for the BC-250-X v0.4.1 production ISO (flashrom edition).

Extends scripts/test-qemu-drive-prod.py (PASS A-C == old 1/2/3/4) with:

  PASS D  flashrom is in the image and its internal-programmer probe runs
          (no chip in QEMU is expected and fine; a crash / missing-lib /
          missing binary is NOT).
  PASS E  `bc250x pray` in the VM must pass require_live (the init-created
          /run/bc250x-live marker), reach the verified-backup step, and
          fail ONLY there, because flashrom finds no flash chip. If pray
          ever reaches Step 2/3 or the "Type PRAY" prompt in QEMU, the VM
          is killed immediately and the run is a RED failure (exit 3) —
          a write must never be attempted against an emulated probe.
  PASS F  Flash Mode: boot selecting the GRUB "BC-250-X Flash Mode" entry
          (sendkey navigation; falls back to booting the identical
          netboot kernel+initrd with bc250x.flashmode=1 if the key timing
          misses) -> init runs `bc250x flashmode`, which must report no
          staged image, and the system still reaches the menu.

Log: build/qemu-drive-v041.log. Exit 0 = all pass, 1 = a pass failed,
3 = RED (pray proceeded past the probe — stop everything and report).
"""
import subprocess, sys, threading, time, glob, shutil, os, re, socket

ISO = 'output/bc250x-prod-20261028.iso'
LOG = 'build/qemu-drive-v041.log'
EXPECTED_SHA = '48fbe5d366e6a56e2fdffdca848426216ba1f083610dab63db89d2f4e6c940b5'

if not os.path.exists(ISO):
    print(f'FAIL: {ISO} missing — run scripts/build-iso.sh first')
    sys.exit(1)

buf = []
lock = threading.Lock()

def reader(p):
    while True:
        b = p.stdout.readline()
        if not b:
            break
        with lock:
            buf.append(b.decode(errors='replace'))

def text():
    with lock:
        return ''.join(buf)

def wait_for(s, timeout=120):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if s in text():
            return True
        time.sleep(0.3)
    return False

def wait_re(pattern, timeout=120):
    rx = re.compile(pattern)
    t0 = time.time()
    while time.time() - t0 < timeout:
        m = rx.search(text())
        if m:
            return m
        time.sleep(0.3)
    return None

def boot(args, monitor_sock=None):
    cmd = ['qemu-system-x86_64', '-machine', 'q35', '-m', '2048',
           '-display', 'none', '-serial', 'stdio', '-monitor', 'none']
    if monitor_sock:
        cmd[-2:] = ['-monitor', f'unix:{monitor_sock},server,nowait']
    cmd += args
    print('Booting:', ' '.join(cmd))
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
    t = threading.Thread(target=reader, args=(p,), daemon=True)
    t.start()
    return p

def boot_iso(monitor_sock=None):
    shutil.copy('/usr/share/OVMF/OVMF_VARS_4M.fd', '/tmp/ovmf_vars_041.fd')
    return boot(['-drive', 'if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd',
                 '-drive', 'if=pflash,format=raw,file=/tmp/ovmf_vars_041.fd',
                 '-cdrom', ISO, '-boot', 'd'], monitor_sock)

def sendkey(mon_path, key, tries=20):
    for _ in range(tries):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(mon_path)
            s.recv(4096)
            s.sendall(f'sendkey {key}\n'.encode())
            time.sleep(0.2)
            s.close()
            return True
        except OSError:
            time.sleep(0.5)
    return False

def save_log():
    os.makedirs('build', exist_ok=True)
    open(LOG, 'w').write(text())

def kill(p):
    try:
        p.kill()
    except Exception:
        pass

results = {}

# ---------------------------------------------------------------- boot 1
p = boot_iso()
ok = wait_for('BC250X_BOOT_OK', 240)
if not ok:
    print('FAIL A: boot marker not seen'); kill(p); save_log(); sys.exit(1)
m = re.search(r'BC250X_BOOT_OK kernel=(\S+)', text())
kver = m.group(1) if m else '?'
results['A'] = (kver == '6.12.0')
print(f"PASS A: BC250X_BOOT_OK kernel={kver}" if results['A']
      else f"FAIL A: kernel is {kver}, expected 6.12.0")

menu = wait_for('Choose [1-5]', 30)
p.stdin.write(b'1\n'); p.stdin.flush()
stat = wait_for('BC-250-X status', 30)
results['B'] = bool(menu and stat and wait_for('Cores:', 10))
print('PASS B: menu shown, bc250x status ran' if results['B'] else 'FAIL B: menu/status')

# shell for C/D/E
wait_for('Choose [1-5]', 30)
p.stdin.write(b'3\n'); p.stdin.flush()
if not wait_for("Type 'exit' to return", 15):
    print('FAIL: shell (menu 3) did not open'); kill(p); save_log(); sys.exit(1)

# PASS C — verify bundled payload (non-destructive)
p.stdin.write(b'bc250x verify /usr/share/bc250x/payload/BC250_3.00_CHIPSETMENU.ROM\n'); p.stdin.flush()
c_ok = wait_for('OK: size gate passed', 60)
mh = wait_re(r'sha256: ([0-9a-f]{64})', 10)
results['C'] = bool(c_ok and mh and mh.group(1) == EXPECTED_SHA)
print(f"PASS C: bc250x verify OK, sha256={mh.group(1) if mh else '?'}" if results['C']
      else 'FAIL C: verify output/hash mismatch')

# PASS D — flashrom present + probe executes (no chip expected)
base = len(text())
p.stdin.write(b'echo D_BEGIN; command -v flashrom; flashrom --version; flashrom -p internal; echo D_PROBE_RC=$?\n')
p.stdin.flush()
d_seen = wait_for('D_PROBE_RC=', 180)
seg = text()[base:]
has_path = '/usr/sbin/flashrom' in seg or '/usr/bin/flashrom' in seg
has_ver = re.search(r'flashrom v?\d+\.\d+', seg) is not None
results['D'] = bool(d_seen and has_path and has_ver
                    and 'error while loading shared libraries' not in seg)
print('PASS D: flashrom present, version + probe executed (no chip in QEMU is expected)'
      if results['D'] else 'FAIL D: flashrom missing or failed to execute')
for line in seg.splitlines():
    if 'flashrom' in line or 'chipset' in line.lower() or 'D_' in line:
        print('   [D]', line.strip()[:160])

# PASS E — pray must die at the backup step on the missing chip, nowhere else
base = len(text())
p.stdin.write(b'bc250x pray\n'); p.stdin.flush()
red = None
t0 = time.time()
last_len, last_change = 0, time.time()
while time.time() - t0 < 240:
    seg = text()[base:]
    if 'Type PRAY' in seg or '-- Step 2/3' in seg or '-- Step 3/3' in seg:
        red = 'pray proceeded past the backup/probe stage in QEMU'
        break
    if 'Reading flash twice' in seg and re.search(
            r'No chipset found|No EEPROM/flash device found|Could not read|read .*fail|ERROR|not seem to be', seg):
        break
    # quiescence: pray exited (shell prompt waiting, no console reader) —
    # after the backup step was reached, 15 s of silence means it stopped.
    if len(seg) != last_len:
        last_len, last_change = len(seg), time.time()
    elif 'Reading flash twice' in seg and time.time() - last_change > 15:
        break
    time.sleep(0.5)
seg = text()[base:]
if red:
    print(f'RED FAIL E: {red} — killing VM, nothing was typed at any prompt')
    kill(p); save_log(); sys.exit(3)
reached_backup = '-- Step 1/3' in seg and 'Reading flash twice' in seg
no_chip_fail = re.search(r'No chipset found|No EEPROM/flash device found|Could not read|ERROR|not seem to be', seg) is not None
no_write = ('Step 2/3' not in seg and 'Type PRAY' not in seg
            and 'Writing with flashrom' not in seg)
results['E'] = bool(reached_backup and no_chip_fail and no_write)
print('PASS E: bc250x pray passed require_live, reached the verified-backup step,'
      ' and failed only on the missing flash chip (no write attempted)'
      if results['E'] else 'FAIL E: pray trace does not match the expected shape')
print('--- pray trace (PASS E evidence) ---')
for line in seg.splitlines():
    if line.strip():
        print('   [E]', line.rstrip()[:200])
print('--- end pray trace ---')

# clean exit from shell + poweroff
try:
    p.stdin.write(b'exit\n'); p.stdin.flush()
    wait_for('Choose [1-5]', 15)
    p.stdin.write(b'5\n'); p.stdin.flush()
except BrokenPipeError:
    pass
time.sleep(3)
kill(p)

# ---------------------------------------------------------------- boot 2 (PASS F)
before = len(text())
mon = '/tmp/qemu-mon-041.sock'
try:
    os.unlink(mon)
except OSError:
    pass
p = boot_iso(monitor_sock=mon)
# GRUB keys: buffered by the PS/2 controller, consumed when the menu polls.
# Entry order: 0=Live, 1=verbose, 2=Flash Mode -> down, down, ret.
time.sleep(2.0); sendkey(mon, 'down')
time.sleep(0.5); sendkey(mon, 'down')
time.sleep(0.5); sendkey(mon, 'ret')
fm = wait_for('Flash Mode: no staged image', 180)
fell_back = False
if not fm:
    # key timing missed the menu: fall back to the identical kernel+initrd
    # (output/netboot carries the same bzImage+rootfs the ISO embeds).
    print('note: GRUB sendkey selection missed; falling back to netboot kernel+initrd')
    kill(p); time.sleep(1)
    p = boot(['-kernel', 'output/netboot/vmlinuz',
              '-initrd', 'output/netboot/rootfs.cpio.gz',
              '-append', 'console=ttyS0,115200 bc250x.live bc250x.flashmode=1 loglevel=3'])
    fell_back = True
    fm = wait_for('Flash Mode: no staged image', 180)
menu2 = wait_for('Choose [1-5]', 60) if fm else False
results['F'] = bool(fm and menu2)
print(('PASS F: Flash Mode boot -> `bc250x flashmode` reported no staged image, menu reached'
       + (' (via netboot kernel+initrd fallback)' if fell_back else ' (via the GRUB entry itself)'))
      if results['F'] else 'FAIL F: flashmode run did not complete cleanly')
try:
    p.stdin.write(b'5\n'); p.stdin.flush()
except BrokenPipeError:
    pass
time.sleep(3)
kill(p)
save_log()

print('=== SUMMARY ===')
for k in 'ABCDEF':
    print(f"PASS {k}: {'yes' if results.get(k) else 'NO'}")
sys.exit(0 if all(results.get(k) for k in 'ABCDEF') else 1)
