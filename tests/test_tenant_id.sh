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
#
# EXTENDED 14z-77 (M3b slice C) with the ROW-OWNERSHIP family, same
# properties — pure functions, no emulator, no build:
#   5. per-FILE ownership stamping (the loader is what knows a row's owner)
#   6. row_applies() truth table: both gate keys x both owner kinds
#   7. row_hex() variant selection, including the fallback
#   8. the multi-tenant refusal, in BOTH directions. It was asserted by no
#      test at all before this; the loop slice DELETES it, so a control that
#      fires today and is flipped then is the honest record of when
#      multi-tenant builds actually arrived.
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


# ── row ownership (M3b slice C) ─────────────────────────────────────────
# The gating family asks "is THIS ROW's owning tenant a variant id?", not
# "is THE tenant a variant id?". These are the pure functions that answer
# it; they are module-level for exactly this reason (slice A's precedent).
echo "== row ownership =="
if python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
from pathlib import Path
from gen_donovan_patch import (toml_loads, manifest_owner, stamp_owner,
                               row_owner, row_applies, row_hex,
                               normalise_tenants)

bad = []
def eq(what, got, want):
    if got != want:
        bad.append("%s: got %r, expected %r" % (what, got, want))

# 5. per-FILE stamping. Every row of every section carries the file's tenant.
for f, owner in (("huitzil", "huitzil"), ("pyron", "pyron"),
                 ("donovan", "donovan")):
    doc = toml_loads(Path("build/manifest/%s.toml" % f).read_text())
    eq("%s manifest_owner" % f, manifest_owner(doc), owner)
    stamp_owner(doc, manifest_owner(doc))
    seen = 0
    for k, v in doc.items():
        rows = v if isinstance(v, list) else [v] if isinstance(v, dict) else []
        for r in rows:
            if isinstance(r, dict):
                seen += 1
                eq("%s.%s row _owner" % (f, k), r.get("_owner"), owner)
    if seen < 10:
        bad.append("%s: only %d rows stamped — did the walk miss sections?"
                   % (f, seen))

# A manifest with no [[tenant]] (the legacy [port] shape) has no owner to
# stamp, and its rows fall back to the build's tenant.
eq("legacy manifest_owner", manifest_owner({"port": {"dst_slot": 0x0F}}), None)

BASE = {"name": "d", "dst_slot": 0x0F}
VAR  = {"name": "h", "dst_slot": 0x13}
TEN  = [BASE, VAR]
eq("row_owner by name",    row_owner({"_owner": "h"}, TEN, BASE), VAR)
eq("row_owner unowned",    row_owner({}, TEN, BASE), BASE)
eq("row_owner unknown",    row_owner({"_owner": "zz"}, TEN, BASE), BASE)

# 6. row_applies: both keys against both owner kinds, plus an unkeyed row.
eq("only_base   @base",    row_applies({"only_base_slot": True}, BASE), True)
eq("only_base   @variant", row_applies({"only_base_slot": True}, VAR), False)
eq("only_variant@base",    row_applies({"only_variant_slot": True}, BASE), False)
eq("only_variant@variant", row_applies({"only_variant_slot": True}, VAR), True)
eq("unkeyed     @base",    row_applies({}, BASE), True)
eq("unkeyed     @variant", row_applies({}, VAR), True)
# section-declared variant-only (select_records, win_pal_variant carry no key)
eq("section-only_variant@base",
   row_applies({}, BASE, only_variant=True), False)
eq("section-only_variant@variant",
   row_applies({}, VAR, only_variant=True), True)

# 7. row_hex: the variant twin only when the OWNER is at a variant id.
ROW = {"new_hex": "4000", "new_hex_variant": "1000"}
eq("row_hex @base",            row_hex(ROW, "new_hex", BASE), "4000")
eq("row_hex @variant",         row_hex(ROW, "new_hex", VAR), "1000")
eq("row_hex @variant no twin", row_hex({"new_hex": "6000"}, "new_hex", VAR),
   "6000")

# 8. the multi-tenant refusal, BOTH directions.
one = {"tenant": [{"name": "a", "src_set": "vsav2", "src_char": 0x13,
                   "id": 0x0F}]}
two = {"tenant": [dict(one["tenant"][0]),
                  dict(one["tenant"][0], name="b", id=0x10)]}
try:
    normalise_tenants(dict(one))
    eq("1 tenant accepted", True, True)
except SystemExit as e:
    bad.append("1 tenant was REFUSED: %s" % e)
try:
    normalise_tenants(dict(two))
    bad.append("2 tenants were ACCEPTED — the refusal is gone, but main() "
               "does not iterate yet")
except SystemExit as e:
    if "multi-tenant" not in str(e):
        bad.append("2 tenants refused for the wrong reason: %s" % e)

for b in bad:
    print("  FAIL: %s" % b)
sys.exit(1 if bad else 0)
PY
then
    echo "  ok: stamping, row_owner, row_applies, row_hex, and the"
    echo "      multi-tenant refusal (both directions)"
else
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant id gate"; exit 1; }
echo "PASS: tenant id gate (resolution, the variant-id refusal, the"
echo "      frozen-reference reproducibility guard, and row ownership)"
