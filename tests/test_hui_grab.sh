#!/bin/sh
# test_hui_grab.sh — Circuit Scrapper gate (14z-66, playtest round-1
# item 4: the 63214 command grab "did not come out").
#
# Root (measured): recognition was ALWAYS live (probe-proven); the
# move-start died on x026142's oracle-invisible pcrel escapes — fixed
# by pcrel_escape_fix. 14z-67: the THROW-ARC fix (site_thunk
# throw_arc_tables — the physics-row installer cloned with vs2's FULL
# superset tables; map1 prefix + shared rows byte-identical, five vs2
# rows added; measured launch yv 16.0 == native, FBNeo tap A/B).
# Static leg below asserts the thunk + placed tables; the runtime
# sub-state/damage legs continue to arbitrate the connect.
# This gate runs the 2P-dummy connect replay and
# asserts the NATIVE-MATCHED signature (frame-identical sub-state
# progression + damage on the native A/B of record): P1 enters the
# 0x0E grab seq and the victim takes the 0x13 damage.
#
# Usage: ROMDIR=... tests/test_hui_grab.sh [existing-stage4-builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
if [ $# -ge 1 ]; then BUILD="$1"; echo "== using existing build $BUILD"; else
    echo "== stage 4 build"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
    GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
        || { tail -15 "$WORK/build.log"; echo "FAIL: build"; exit 1; }
    BUILD="$WORK/hui4"
fi
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no vsavjw.zip"; exit 1; }
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

echo "== static: throw-arc thunk + placed superset tables"
python3 - "$BUILD" "$ROMDIR" <<'PY2'
import json, sys, subprocess, os
outbase, romdir = sys.argv[1], sys.argv[2]
notes = open(os.path.join(outbase, "patch", "patch_notes_fragment.md")).read()
assert "throw_arc_tables" in notes, "throw_arc_tables thunk missing"
# the two data_subst blocks: find their placed addresses in the notes
import re
m = re.findall(r"data\s+0x([0-9a-f]+) \+0x(54|370)\s+site_thunk throw_arc_tables", notes)
assert len(m) == 2, f"expected 2 placed table blocks, got {m}"
print("  ok: thunk emitted with both table blocks placed:", m)
PY2
d="$WORK/g"; mkdir -p "$d"
( cd "$d" && POKES="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10" \
  DUMPS="3200:ff8400-ff8500;3230:ff8800-ff8900;3300:ff8800-ff8900" \
  MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
  "$REPO/tools/run_replay_guarded.sh" vsavjw "$REPO/tests/replays/hui/80_hui_grab_2p.rpl" \
      "$d/g.log" "$d/box" > "$d/g.out" 2>&1 ) || {
    echo "FAIL: guard tripped:"; grep -m2 -E "CRASH|REGS" "$d/g.log" || tail -5 "$d/g.out"; exit 1; }
python3 - "$d" <<'PYEOF'
import struct, sys
d = sys.argv[1]
p1 = open("%s/dump_3200_ff8400.bin" % d, 'rb').read()
p2a = open("%s/dump_3230_ff8800.bin" % d, 'rb').read()
p2b = open("%s/dump_3300_ff8800.bin" % d, 'rb').read()
seq_ok = p1[0x06] == 0x0E
hp_a = struct.unpack('>H', p2a[0x50:0x52])[0]
hp_b = struct.unpack('>H', p2b[0x50:0x52])[0]
print("  P1 seq byte=%02x  victim hp @3230=%04x @3300=%04x" % (p1[0x06], hp_a, hp_b))
if not (seq_ok and hp_a == 0x10D and hp_b == 0x10D):
    print("FAIL: grab signature off (native datum: seq 0x0E, hp 0x120->0x10D)")
    sys.exit(1)
PYEOF
echo "  ok: grab connects with the native damage"
echo "PASS: Circuit Scrapper (native-matched grab on the 2P dummy)"
