#!/usr/bin/env python3
"""Supplementary PASS E run on -machine i440fx (PIIX3, no SPI controller).

Why: on q35, QEMU emulates an ICH9 SPI window and flashrom misdetects it
as a 256 kB ST M95M02 EEPROM whose transactions all fail — the backup read
grinds instead of failing fast (see build/qemu-drive-v041.log; pray still
never passed its gates: no Step 2/3, no Type PRAY, no write). On i440fx
there is no emulated SPI flash at all, which is the environment PASS E
specifies: flashrom finds NO chip, and `bc250x pray` must pass
require_live, reach the verified-backup step, and die there — only there.

RED guard identical to the main gate: if Step 2/3 or "Type PRAY" ever
appears, kill the VM and exit 3. Log: build/qemu-pray-i440fx.log.
"""
import subprocess, sys, threading, time, os, re, shutil

ISO = 'output/bc250x-prod-20261028.iso'
LOG = 'build/qemu-pray-i440fx.log'
buf, lock = [], threading.Lock()

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
        if 'Type PRAY' in text() or '-- Step 2/3' in text():
            return False
        time.sleep(0.3)
    return False

shutil.copy('/usr/share/OVMF/OVMF_VARS_4M.fd', '/tmp/ovmf_vars_i440.fd')
cmd = ['qemu-system-x86_64', '-machine', 'pc', '-m', '2048',
       '-drive', 'if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd',
       '-drive', 'if=pflash,format=raw,file=/tmp/ovmf_vars_i440.fd',
       '-cdrom', ISO, '-boot', 'd',
       '-display', 'none', '-serial', 'stdio', '-monitor', 'none']
print('Booting:', ' '.join(cmd))
p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.STDOUT)
threading.Thread(target=reader, args=(p,), daemon=True).start()

def save():
    os.makedirs('build', exist_ok=True)
    open(LOG, 'w').write(text())

if not wait_for('BC250X_BOOT_OK', 240):
    print('FAIL: no boot marker'); p.kill(); save(); sys.exit(1)
print('boot ok on i440fx')
wait_for('Choose [1-5]', 30)
p.stdin.write(b'3\n'); p.stdin.flush()
if not wait_for("Type 'exit' to return", 15):
    print('FAIL: no shell'); p.kill(); save(); sys.exit(1)

base = len(text())
p.stdin.write(b'bc250x pray\n'); p.stdin.flush()
red = done = False
t0 = time.time()
while time.time() - t0 < 240:
    seg = text()[base:]
    if 'Type PRAY' in seg or '-- Step 2/3' in seg or '-- Step 3/3' in seg \
            or 'Writing with flashrom' in seg:
        red = True
        break
    if 'Reading flash twice' in seg and re.search(
            r'No chipset found|No EEPROM/flash device found|Flash detection will most likely fail', seg):
        done = True
        break
    time.sleep(0.4)

if red:
    print('RED: pray proceeded past the backup/probe stage — killing VM')
    p.kill(); save(); sys.exit(3)

seg = text()[base:]
# prove pray exited and the shell is responsive again
p.stdin.write(b'echo PRAY_SHELL_BACK\n'); p.stdin.flush()
shell_back = wait_for('PRAY_SHELL_BACK', 30)
seg = text()[base:]
live_ok = 'ABORT: flash writes run from' not in seg
reached = '-- Step 1/3' in seg and 'Reading flash twice' in seg
nochip = re.search(r'No chipset found|No EEPROM/flash device found|Flash detection will most likely fail', seg) is not None
passed = bool(done and live_ok and reached and nochip and shell_back)
print('PASS E (i440fx): require_live passed, backup step reached, flashrom found no chip,'
      ' pray exited there, shell responsive — no write attempted'
      if passed else 'FAIL E (i440fx): trace mismatch')
print('--- pray trace (i440fx) ---')
for line in seg.splitlines():
    if line.strip() and 'Transaction error' not in line:
        print('  ', line.rstrip()[:200])
print('--- end trace ---')
try:
    p.stdin.write(b'exit\n'); p.stdin.flush()
    wait_for('Choose [1-5]', 15)
    p.stdin.write(b'5\n'); p.stdin.flush()
except BrokenPipeError:
    pass
time.sleep(3)
p.kill(); save()
sys.exit(0 if passed else 1)
