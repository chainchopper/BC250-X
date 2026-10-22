#!/bin/sh
# QEMU UEFI boot test for the Phase 1 ISO — drives the serial console via python.
set -eu
cd "$(dirname "$0")/.."
exec python3 scripts/test-qemu-drive.py
