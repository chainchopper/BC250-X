#!/bin/sh
# Build the NetBoot iPXE binary with boot.ipxe embedded.
set -eu
cd "$(dirname "$0")/.."
mkdir -p build output
[ -d build/ipxe ] || git clone --depth 1 https://github.com/ipxe/ipxe.git build/ipxe
cp ipxe/boot.ipxe build/ipxe/src/bc250x.ipxe
make -C build/ipxe/src -j"$(nproc)" bin-x86_64-efi/ipxe.efi EMBED=bc250x.ipxe
cp build/ipxe/src/bin-x86_64-efi/ipxe.efi output/bc250x-ipxe.efi
echo "Built output/bc250x-ipxe.efi  (serve ipxe/boot.ipxe payloads from NETBOOT_BASE)"
