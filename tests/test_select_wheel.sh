#!/bin/sh
# test_select_wheel.sh — the character-select cursor mechanism: decoded from
# the ROM, and MEASURED in the emulator.
#
# WHY THIS EXISTS. The roster plan (option 1: append three cells) rests
# entirely on how the select cursor moves and what it commits. That
# mechanism had been recorded in a session log only — one address of it
# wrong — with nothing in the repo able to check it. This gate re-derives
# it from the ROM every run and then requires the EMULATOR to agree.
#
# WHAT IS ESTABLISHED (docs/game/atlas/select_screen.md):
#   TABLE A PRG:0x0211D4  joystick nibble -> direction 0-7 ($ff = illegal)
#   TABLE B PRG:0x0211E4  8-way adjacency, 8 bytes/cell, 32 rows
#   commit  PRG:0x020A7C  move.b d0,$3(a6)     cursor cell
#           PRG:0x020A80  move.b d0,$382(a6)   character id (SAME value)
# The row index is UNMASKED (`lsl.w #3` on the whole byte), which is why the
# table has 32 rows and why cells 0x10-0x1F are addressable at all — the
# fact the roster design depends on.
#
# SECTIONS
#   1  static decode + structure, vsavj and vsav2 (no emulator)
#   2  generate the full-coverage walk
#   3  MEASURED: that walk visiting every (cell,direction) pair, tapped in
#      MAME, compared press-by-press — plus four negative controls on the
#      checker's own verdict logic
#   4  MEASURED: where each cell sits on screen (palette-0x1E cursor ring)
#   5  the layout proposer refuses an unsound wheel (no emulator)
#
# Sections 3-4 need a working MAME; set WHEEL_STATIC_ONLY=1 to skip them.
#
# Usage: ROMDIR=... tests/test_select_wheel.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   the select cursor, 4 sections: tables decoded from the ROM; a generated
#   walk over all 128 (cell,direction) pairs measured in MAME; four negative
#   controls on the checker's verdicts; and all 16 cell screen positions
#   measured
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"        # GitHub #68: not a predictable name
trap 'rm -rf "$WORK"' EXIT
fail=0

note() { printf '%s\n' "$*"; }
check() {  # check <label> <expected-rc> <cmd...>
    _label="$1"; _want="$2"; shift 2
    if "$@" >"$WORK/out.txt" 2>&1; then _rc=0; else _rc=$?; fi
    if [ "$_rc" = "$_want" ]; then
        note "  PASS  $_label"
    else
        note "  FAIL  $_label (rc=$_rc, wanted $_want)"
        sed 's/^/        /' "$WORK/out.txt" | tail -12
        fail=1
    fi
}

note "== section 1: static decode and structure =="
ROMDIR="${ROMDIR:-}"
if [ -z "$ROMDIR" ]; then
    note "  SKIP  (ROMDIR unset — the decode needs the reference images)"
    exit 0
fi
python3 tools/audit_roms.py "$ROMDIR" >"$WORK/audit.txt" 2>&1 || {
    note "  FAIL  ROM audit"; sed 's/^/        /' "$WORK/audit.txt"; exit 1; }
note "  PASS  ROM audit (reference sets match docs/checksums.txt)"

for s in vsavj vsav2; do
    decrypt_view $s "$WORK/${s}_op.bin" "$WORK/${s}_dat.bin" || {
        note "  FAIL  decrypt $s"; sed 's/^/        /' "$WORK/dec_$s.txt"; exit 1; }
    check "$s tables decode and verify" 0 \
        python3 tools/select_wheel.py "$WORK/${s}_dat.bin" --set "$s"
done

# The two facts the roster design rests on, asserted as text so a change to
# either fails here rather than surfacing as a broken wheel in a build.
python3 tools/select_wheel.py "$WORK/vsavj_dat.bin" --set vsavj \
    >"$WORK/vsavj_wheel.txt" 2>&1
grep -q "known cursor paths reproduce" "$WORK/vsavj_wheel.txt" || {
    note "  FAIL  vsavj: recorded cursor paths no longer reproduce"; fail=1; }
grep -q "upper 16 rows == lower 16 rows (whole-half alias): True" \
    "$WORK/vsavj_wheel.txt" || {
    note "  FAIL  vsavj: the variant half is no longer a verbatim alias"; fail=1; }
python3 tools/select_wheel.py "$WORK/vsav2_dat.bin" --set vsav2 \
    >"$WORK/vsav2_wheel.txt" 2>&1
grep -q "VARIANT half (0x10-0x1F): navigable 10 11 13" "$WORK/vsav2_wheel.txt" || {
    note "  FAIL  vsav2: cells 10/11/13 are no longer navigable"; fail=1; }
note "  PASS  frozen facts: vsavj paths + alias half; vsav2 navigates 10/11/13"

note "== section 2: generate the full-coverage walk =="
python3 tools/select_wheel.py "$WORK/vsavj_dat.bin" --set vsavj \
    --walk-rpl "$WORK/walk.rpl" --walk-expect "$WORK/walk.json" \
    >"$WORK/gen.txt" 2>&1 || { note "  FAIL  walk generation"; exit 1; }
grep -q "covering 128/128 (cell,direction) pairs" "$WORK/gen.txt" || {
    note "  FAIL  the generated walk does not cover all 128 pairs"; fail=1; }
note "  PASS  generated walk covers all 128 (cell,direction) pairs"

note "== section 3: MEASURED — the walk, tapped in MAME =="
if [ "${WHEEL_STATIC_ONLY:-0}" = "1" ]; then
    note "  SKIP  (WHEEL_STATIC_ONLY=1)"
else
    REPLAY="$WORK/walk.rpl" TAP=ff8402,2 FRAMES=1450 \
        TRACE_OUT="$WORK/tap.txt" MAME_SANDBOX="$WORK/sandbox" \
        tools/run_mame.sh vsavj -autoboot_script tests/lua/tap_writes.lua \
        >"$WORK/mame.txt" 2>&1 || {
        note "  FAIL  MAME run"; tail -12 "$WORK/mame.txt"; exit 1; }
    check "measured walk reproduces TABLE B (all 128 pairs)" 0 \
        python3 tools/check_wheel_walk.py "$WORK/tap.txt" "$WORK/walk.json"

    # A checker that cannot fail proves nothing (CLAUDE.md §4). Corrupt the
    # expectation four ways; each must be caught. 'pc' is the one that
    # matters historically — it feeds the PREVIOUSLY RECORDED commit
    # address 0x020A84, and its failure here is the correction's evidence.
    python3 - "$WORK/walk.json" "$WORK" <<'PY'
import json, sys, os
exp = json.load(open(sys.argv[1])); work = sys.argv[2]
def emit(name, mod):
    e = json.loads(json.dumps(exp)); mod(e)
    json.dump(e, open(os.path.join(work, "neg_%s.json" % name), "w"))
emit("cell",  lambda e: e["presses"][40].__setitem__("to",
                        (e["presses"][40]["to"] + 1) & 0xF))
emit("count", lambda e: e["presses"].pop(3))
emit("pc",    lambda e: e.__setitem__("commit_pc", 0x020A84))
emit("frame", lambda e: [p.__setitem__("frame", p["frame"] + (7 if i > 60 else 0))
                         for i, p in enumerate(e["presses"])])
PY
    for n in cell count pc frame; do
        check "negative control '$n' is caught" 1 \
            python3 tools/check_wheel_walk.py "$WORK/tap.txt" "$WORK/neg_$n.json"
    done
fi

note "== section 4: MEASURED — where each cell sits on screen =="
if [ "${WHEEL_STATIC_ONLY:-0}" = "1" ]; then
    note "  SKIP  (WHEEL_STATIC_ONLY=1)"
else
    # Positions cannot be read statically: the wheel record lists 18 OBJ
    # entries in DRAWING order, not cell order. Measured instead by parking
    # the cursor on each cell and reading the palette-0x1E ring out of OBJ
    # RAM. Needed to place three new cells relative to the existing ones.
    python3 tools/wheel_positions.py --data "$WORK/vsavj_dat.bin" \
        --tour "$WORK/tour.rpl" --meta "$WORK/tour.json" >/dev/null 2>&1
    TDUMPS=$(python3 -c "import json;print(json.load(open('$WORK/tour.json'))['dumps'])")
    REPLAY="$WORK/tour.rpl" DUMPS="$TDUMPS" CHECKSUM_OUT="$WORK/tour_ck.log" \
        MAME_SANDBOX="$WORK/tour_sbx" \
        tools/run_mame.sh vsavj -autoboot_script tests/lua/replay.lua \
        >"$WORK/tour_run.log" 2>&1 || {
        note "  FAIL  tour run"; tail -8 "$WORK/tour_run.log"; fail=1; }
    python3 tools/wheel_positions.py --meta "$WORK/tour.json" \
        --extract "$WORK" >"$WORK/pos.txt" 2>&1 || {
        note "  FAIL  position extraction"; tail -5 "$WORK/pos.txt"; fail=1; }
    # frozen: measured 14z-60, docs/game/atlas/select_screen.md
    cat >"$WORK/pos.want" <<'POS'
  cell 00: (224, 112)
  cell 01: (160, 112)
  cell 02: (280,  80)
  cell 03: (192,  96)
  cell 04: (304,  96)
  cell 05: (336, 112)
  cell 06: (192, 128)
  cell 07: (208,  80)
  cell 08: (224, 144)
  cell 09: (272, 144)
  cell 0A: (304, 128)
  cell 0B: (248, 152)
  cell 0C: (248,  96)
  cell 0D: (248, 128)
  cell 0E: (272, 112)
  cell 0F: (248,  64)
POS
    miss=0
    while IFS= read -r line; do
        grep -qF "$line" "$WORK/pos.txt" || { miss=$((miss + 1))
            note "        missing: $line"; }
    done <"$WORK/pos.want"
    if [ "$miss" = 0 ]; then
        note "  PASS  all 16 cell positions match the frozen map"
    else
        note "  FAIL  $miss cell positions moved"; fail=1
    fi
fi

note "== section 5: the layout proposer refuses an unsound wheel =="
# An 0xFF inside a LIVE row is committed straight into $3(a6) AND $382(a6)
# (no validity check on TABLE B's read), i.e. character id 0xFF indexing
# ~1KB past every 32-entry table. Vanilla never does it — its idiom for
# "no move that way" is SELF-REFERENCE (cell 0x0B Down, cell 0x0F Up). The
# proposer's first draft emitted 0xFF and its validator passed it; both are
# fixed, and this pins them.
cat >"$WORK/lay_ok.json" <<'JSON'
{"cells": {"10": {"pos": [224,168]}, "13": {"pos": [272,168]},
           "11": {"pos": [248,176]}},
 "edges_in": [{"from":"0x0B","dir":"DL","to":"0x10"},
              {"from":"0x0B","dir":"DR","to":"0x13"},
              {"from":"0x0B","dir":"D","to":"0x11"}]}
JSON
cat >"$WORK/lay_ff.json" <<'JSON'
{"cells": {"10": {"pos": [224,168], "adjacency": {"D": "0xFF"}},
           "13": {"pos": [272,168]}, "11": {"pos": [248,176]}},
 "edges_in": [{"from":"0x0B","dir":"DL","to":"0x10"},
              {"from":"0x0B","dir":"DR","to":"0x13"},
              {"from":"0x0B","dir":"D","to":"0x11"}]}
JSON
check "the snapped layout validates" 0 \
    python3 tools/wheel_layout.py propose --data "$WORK/vsavj_dat.bin" \
        --layout "$WORK/lay_ok.json"
check "an 0xFF in a live row is REJECTED" 1 \
    python3 tools/wheel_layout.py propose --data "$WORK/vsavj_dat.bin" \
        --layout "$WORK/lay_ff.json"
grep -q "no live vanilla row contains 0xFF\|self-reference" tools/wheel_layout.py \
    && note "  PASS  the self-reference idiom is documented at the fallback" \
    || { note "  FAIL  fallback rationale missing"; fail=1; }

if [ "$fail" = 0 ]; then
    note "SELECT WHEEL: PASS"
else
    note "SELECT WHEEL: FAIL"
fi
exit "$fail"
