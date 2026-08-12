#!/bin/sh
# audit_objhook_owner_census.sh — which OWNER does each extended obj_hook
# type carry at DISPATCH TIME? (14z-81b; the vec3-fix design measurement.)
#
# WHY. The merged obj_hook union gives a MULTI-OWNER type (114-120, the
# x088512 pool family — all three tenants port it) ONE extended-table entry,
# and the fix needs a runtime owner read. This census measures, per dispatch,
# the object's `+0x30` word class on a SINGLE-TENANT build (hui29), where the
# ground truth is known: every dispatch is Huitzil-owned.
#
# MEASURED 14z-81b (and the reason the owner-walk stub did NOT ship the same
# day):
#   type 117: +0x30 hi-byte = 0x84 (P1 struct, depth 1)   — walk works
#   type 119: +0x30 hi-byte = 0xB8 (creator object, d.2)  — walk works
#   type 115: +0x30 hi-byte = 0x00 AT DISPATCH TIME, while the SAME frame's
#             end-of-frame dump shows 0x84 in the same slot (and the slot's
#             type byte reads 117 in the dump vs 115 at dispatch) — the
#             field is TIME-VARYING WITHIN A FRAME for this type. An
#             owner-walk dispatched on it would tripwire legitimate 115s.
#   types 114/116/118/120: NOT OBSERVED by these two replays — a design
#             that assumes their shape is guessing; extend the replay list
#             when one of them matters.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/audit_objhook_owner_census.sh [build]
# Default build: build/hui30. ~6 min: two guarded runs. REPORT-ONLY (exit 0
# unless the rig is dead): this is a measurement, not a gate.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${1:-build/hui30}"

[ -d "$BUILD/rompath" ] || { echo "SKIP: no $BUILD/rompath"; exit 0; }
[ -x "$MAME_BIN" ]      || { echo "SKIP: no WIDE MAME binary"; exit 0; }

# The probe sits on the build's obj_hook THUNK for site 0x5E542 (at thunk
# entry D0 still holds type*4; at site+6 it is already cleared). Scraped
# from the fragment: the LAST "obj_hook thunk" line is site 0x5E542's
# (rows are emitted in site order; site 0x54470's thunk comes first).
THUNK="$(sed -n 's/^code *0x0*\([0-9a-f]*\) obj_hook thunk .*/\1/p' \
         "$BUILD/patch/patch_notes_fragment.md" | tail -1)"
[ -n "$THUNK" ] || { echo "FAIL: no obj_hook thunk line in $BUILD's fragment"; exit 1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

run() {  # run <replay-rel> <pokes> <out>
    POKES="$2" MAME_ROMPATH="$(abspath "$BUILD")/rompath;$ROMDIR" \
    GUARD_PROBE="$THUNK" GUARD_PROBE_COND="d0 >= 0x1c8" \
    GUARD_PROBE_MAX=20000 GUARD_PROBE_MEM=A6+30 \
        tools/run_replay_guarded.sh vsavjw "tests/replays/$1.rpl" \
        "$3" "$W/box_$(basename "$3")" >/dev/null 2>&1 || true
}
run hui/70_hui_mash "1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10" "$W/mash.log"
run hui/83_hui_fx   "1400:ff8782:10;1450:ff8782:10;1500:ff8782:10" "$W/fx.log"

python3 - "$W/mash.log" "$W/fx.log" <<'PY'
import re, sys, collections
total = 0
for path in sys.argv[1:]:
    seen = collections.defaultdict(collections.Counter)
    for line in open(path):
        m = re.match(r"PROBE (\d+) D0=([0-9a-f]+) .*A6=([0-9a-f]+) "
                     r".*MEM\[A6\+30=[0-9a-f]+\]=([0-9a-f]+)", line)
        if m:
            typ = int(m.group(2), 16) // 4
            hb = m.group(4)
            cls = {"84": "P1", "88": "P2"}.get(
                hb, "object" if hb.startswith("b") else
                    ("ZERO" if hb == "00" else "other:" + hb))
            seen[typ][cls] += 1
            total += 1
    print(f"== {path.rsplit('/',1)[-1]}: type -> owner-class at +0x30 (dispatch time)")
    for t in sorted(seen):
        print(f"   type {t}: {dict(seen[t])}")
    for t in range(114, 121):
        if t not in seen:
            print(f"   type {t}: NOT OBSERVED (no verdict — do not assume its shape)")
if total == 0:
    print("FAIL: zero extended-type dispatches — the rig is dead "
          "(wrong thunk address, or the pokes stopped forming the match)")
    sys.exit(1)
PY
echo "census complete (REPORT-ONLY — the fix design consumes this, no gate here)"
