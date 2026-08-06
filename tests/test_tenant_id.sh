#!/bin/sh
# test_tenant_id.sh — the tenant's character id is a BUILD INPUT, and the
# frozen reference must stay reproducible while a move is in progress.
#
# WHY (M3a, 14z-61). De-substitution moves the tenant off a legacy
# character's slot onto its own variant id. That is roster work, so it
# belongs to the WIDE track (14z-59g); the stock build is the frozen
# compatibility artifact and has nowhere to put the tenant's tiles other
# than the host's gfx band. While the move is INCOMPLETE the manifest must
# keep the id the frozen reference was built with. 14z-64: M3a IS
# COMPLETE and the re-freeze bundle declares `id_by_profile =
# "cps2-wide-v1=0x13"` — the WIDE track's default is now the native id
# (the old references 9bac6ee3/ae701ffb are superseded by the bundle's
# new pair; this gate flipped in the same change, as it always said it
# would).
#
# Four checks, no emulator, no build (~1s):
#   1. default (no profile)      -> the manifest id, with its variant mirror
#   2. WIDE profile, no override -> the DE-SUBSTITUTED id 0x13 via
#      id_by_profile (flipped 14z-64 with the re-freeze bundle)
#   3. --tenant-id 0x13          -> same id, mirror_variant FALSE so the
#      tenant can never touch Victor's row 0x03
#   4. a variant id with NO profile -> REFUSED, with the reason
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0

run() {  # run <profile-or-> <override-or-> -> "id mirror" or "REFUSED"
    python3 - "$1" "$2" <<'PY'
import sys
sys.path.insert(0, "tools")
from pathlib import Path
from gen_donovan_patch import normalise_tenants, toml_loads
prof = None if sys.argv[1] == "-" else sys.argv[1]
over = None if sys.argv[2] == "-" else int(sys.argv[2], 0)
doc = toml_loads(Path("build/manifest/donovan.toml").read_text())
try:
    p = normalise_tenants(dict(doc), prof, over)["port"]
    print("%#04x %s" % (p["dst_slot"], p["mirror_variant"]))
except SystemExit as e:
    print("REFUSED %s" % e)
PY
}

check() {  # check <desc> <expected> <profile> <override>
    got="$(run "$3" "$4")"
    case "$got" in
    $2) echo "  ok: $1 -> $got" ;;
    *)  echo "  FAIL: $1 -> '$got' (expected '$2')"; fail=1 ;;
    esac
}

echo "== tenant id resolution =="
check "default, no profile"            "0x0f True"  -             -
check "WIDE profile, no override"      "0x13 False" cps2-wide-v1  -
check "--tenant-id 0x13 on WIDE"       "0x13 False" cps2-wide-v1  0x13
check "variant id without a profile"   "REFUSED*"   -             0x13

# The declaration guard, flipped 14z-64: the WIDE default must now BE
# the de-substituted id — a manifest that lost the declaration would
# silently rebuild the WIDE track at 0x0F again.
if grep -q '^id_by_profile = "cps2-wide-v1=0x13"' build/manifest/donovan.toml; then
    echo "  ok: id_by_profile declares the WIDE default 0x13 (M3a landed)"
else
    echo "  FAIL: id_by_profile missing/changed — the WIDE track would"
    echo "        silently rebuild at the substituted slot 0x0F"
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant id gate"; exit 1; }
echo "PASS: tenant id gate (resolution, the variant-id refusal, and the"
echo "      frozen-reference reproducibility guard)"
