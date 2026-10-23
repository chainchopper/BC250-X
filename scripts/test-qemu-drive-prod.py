#!/usr/bin/env python3
"""Interactive QEMU boot test for the BC-250-X production (Buildroot) ISO.

Same drive pattern as the Phase 1 test, but for output/bc250x-prod-*.iso and
with a hard assertion that the boot marker reports the CUSTOM kernel
(BC250X_BOOT_OK kernel=6.12.x) — not the Phase 1 distro kernel.
Exit 0 = pass. Log is saved to build/qemu-drive-prod.log either way.
"""
import subprocess, sys, threading, time, glob, shutil, os, re

isos = sorted(glob.glob('output/bc250x-prod-*.iso'))
if not isos:
    print('FAIL: no output/bc250x-prod-*.iso — run scripts/build-iso.sh first')
    sys.exit(1)
iso = isos[-1]
shutil.copy('/usr/share/OVMF/OVMF_VARS_4M.fd', '/tmp/ovmf_vars_prod.fd')
cmd = ['qemu-system-x86_64', '-machine', 'q35', '-m', '2048',
       '-drive', 'if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd',
       '-drive', 'if=pflash,format=raw,file=/tmp/ovmf_vars_prod.fd',
       '-cdrom', iso, '-boot', 'd',
       '-display', 'none', '-serial', 'stdio', '-monitor', 'none']
print('Booting', iso)
p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
buf = []
lock = threading.Lock()
def reader():
    while True:
        b = p.stdout.readline()
        if not b: break
        with lock: buf.append(b.decode(errors='replace'))
t = threading.Thread(target=reader, daemon=True); t.start()

def text():
    with lock: return ''.join(buf)

def wait_for(s, timeout=120):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if s in text(): return True
        time.sleep(0.5)
    return False

def save_log():
    os.makedirs('build', exist_ok=True)
    open('build/qemu-drive-prod.log', 'w').write(text())

ok = wait_for('BC250X_BOOT_OK', 240)
if not ok:
    print('FAIL: boot marker not seen'); p.kill(); save_log()
    print(text()[-3000:]); sys.exit(1)
m = re.search(r'BC250X_BOOT_OK kernel=(\S+)', text())
kver = m.group(1) if m else '?'
print(f'PASS 1: BC250X_BOOT_OK seen (UEFI -> kernel {kver} -> bc250x init)')
if not kver.startswith('6.12'):
    print(f'FAIL: expected custom kernel 6.12.x, got {kver}')
    p.kill(); save_log(); sys.exit(1)
print('PASS 1b: custom kernel confirmed (6.12.x, not the Phase 1 distro kernel)')
menu = wait_for('Choose [1-5]', 30)
print(('PASS 2: menu shown' if menu else 'note: menu prompt not captured'))
p.stdin.write(b'1\n'); p.stdin.flush()
stat = wait_for('BC-250-X status', 30)
core = wait_for('Cores:', 10)
kern = wait_for('Kernel:', 10)
passed = bool(stat and core)
print(('PASS 3: bc250x status ran from the menu' if passed else 'FAIL: status output missing'))
try: p.stdin.write(b'5\n'); p.stdin.flush()
except BrokenPipeError: pass
time.sleep(3)
try: p.terminate()
except Exception: pass
save_log()
print('--- log tail ---'); print(text()[-1200:])
sys.exit(0 if passed else 1)
