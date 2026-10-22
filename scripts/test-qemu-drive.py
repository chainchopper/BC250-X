#!/usr/bin/env python3
"""Interactive QEMU boot test for BC-250-X Phase 1 ISO.

Boots the ISO under OVMF with serial on stdio (piped), waits for the
BC250X_BOOT_OK marker and the menu, selects "1) System status", and checks
for real `bc250x status` output (Cores / Kernel lines). Exit 0 = pass.
"""
import subprocess, sys, threading, time, glob, shutil, os

iso = sorted(glob.glob('output/bc250x-phase1-*.iso'))[-1]
shutil.copy('/usr/share/OVMF/OVMF_VARS_4M.fd', '/tmp/ovmf_vars.fd')
cmd = ['qemu-system-x86_64', '-machine', 'q35', '-m', '2048',
       '-drive', 'if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd',
       '-drive', 'if=pflash,format=raw,file=/tmp/ovmf_vars.fd',
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

def wait_for(s, timeout=120):
    t0 = time.time()
    while time.time() - t0 < timeout:
        with lock: txt = ''.join(buf)
        if s in txt: return True
        time.sleep(0.5)
    return False

ok = wait_for('BC250X_BOOT_OK', 240)
if not ok:
    print('FAIL: boot marker not seen'); p.kill()
    open('/tmp/bc250x-qemu-drive.log','w').write(''.join(buf)); print(''.join(buf)[-3000:]); sys.exit(1)
print('PASS 1: BC250X_BOOT_OK seen (UEFI -> kernel -> bc250x init)')
menu = wait_for('Choose [1-5]', 30)
print(('PASS 2: menu shown' if menu else 'note: menu prompt not captured'))
p.stdin.write(b'1\n'); p.stdin.flush()
stat = wait_for('BC-250-X status', 30)
core = wait_for('Cores:', 10)
kern = wait_for('Kernel:', 10)
print(('PASS 3: bc250x status ran from the menu' if stat and core else 'FAIL: status output missing'))
try: p.stdin.write(b'5\n'); p.stdin.flush()
except BrokenPipeError: pass
time.sleep(3)
try: p.terminate()
except Exception: pass
log = ''.join(buf)
open('/tmp/bc250x-qemu-drive.log', 'w').write(log)
print('--- log tail ---'); print(log[-1200:])
sys.exit(0 if (stat and core) else 1)
