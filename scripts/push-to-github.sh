#!/bin/sh
# After the empty repo exists at github.com/chainchopper/BC250-X, run this once.
# (Repo creation itself must be done by the account owner on github.com —
#  the Muse GitHub App cannot create repositories: 403, verified Oct 15 + Oct 20 2026.)
set -eu
cd "$(dirname "$0")/.."
git remote get-url origin >/dev/null 2>&1 || git remote add origin https://github.com/chainchopper/BC250-X.git
git push -u origin main
echo "Pushed. Live catalog will be at:"
echo "  https://raw.githubusercontent.com/chainchopper/BC250-X/main/catalog/os.json"
echo "  https://raw.githubusercontent.com/chainchopper/BC250-X/main/catalog/bios.json"
