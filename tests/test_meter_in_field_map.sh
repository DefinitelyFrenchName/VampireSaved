#!/bin/sh
# test_meter_in_field_map.sh — the dual-emulator oracle must actually compare
# meter (14z-94, GitHub #83). ROM-free, no emulator, ~2 s.
#
# THE DEFECT. CLAUDE.md §4 states the dual-emulator protocol compares "mapped
# gameplay state at sync anchors ... character IDs, HP, positions, timer,
# METER, and the other fields in docs/game/atlas/ram.md". tests/fields_m2a.tsv
# mapped everything in that sentence EXCEPT meter — both halves of it, both
# players. compare_fields.py only reads what the TSV lists, so a cross-emulator
# meter regression during gain, conversion or consumption passed the stage-4
# oracle green while every mapped field agreed.
#
# It is the specific promise, not a general one: meter is NAMED in the rule.
#
# WHAT IS ASSERTED. That the four fields are present, that their addresses are
# the ones the atlas documents (so the map cannot drift from ram.md), and —
# the part that matters — that a difference confined to a meter byte is
# actually CAUGHT. Section 3 is the control: without it this gate would pass
# on a TSV whose rows are present but never read.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

TSV="tests/fields_m2a.tsv"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM

echo "== 1. the four meter fields are mapped, at the atlas's addresses =="
python3 - <<'PY' || rc=1
import sys, re
sys.path.insert(0, "tools")
from compare_fields import parse_fields, P1_BASE, P2_BASE

want = {
    "p1_meter_stock": (P1_BASE + 0x109, 1),
    "p2_meter_stock": (P2_BASE + 0x109, 1),
    "p1_meter_frac":  (P1_BASE + 0x10A, 2),
    "p2_meter_frac":  (P2_BASE + 0x10A, 2),
}
got = {f[0]: (f[1], f[2]) for f in parse_fields("tests/fields_m2a.tsv")}
bad = 0
for n, (addr, w) in want.items():
    if n not in got:
        print(f"  FAIL: {n} is not in the field map — CLAUDE.md 4 names meter"
              f" in the compared set"); bad = 1
    elif got[n] != (addr, w):
        print(f"  FAIL: {n} maps {got[n][0]:#x}/{got[n][1]}B, expected"
              f" {addr:#x}/{w}B"); bad = 1
    else:
        print(f"  ok: {n:<16} {addr:#08x} {w}B")

# Bind to the atlas rather than to my memory of it: ram.md is the source the
# TSV header cites, so a change there must not silently desync the map.
ram = open("docs/game/atlas/ram.md").read()
for off, label in (("+0x109", "stock"), ("+0x10A.w", "meter-bar fraction")):
    row = [l for l in ram.splitlines() if l.startswith(f"| {off} ")]
    if not row:
        print(f"  FAIL: ram.md no longer documents {off} — the map now cites"
              f" an address the atlas does not describe"); bad = 1
    elif label.split()[0].lower() not in row[0].lower():
        print(f"  FAIL: ram.md {off} no longer describes '{label}':"
              f" {row[0][:90]}"); bad = 1
    else:
        print(f"  ok: ram.md {off} still documents the {label}")
sys.exit(bad)
PY

# Synthesize two sides of per-frame dumps. Format (compare_fields docstring):
# dump_<frame>_<addr>.bin, 68k-logical order, inclusive ranges.
# mkside <dir> <p1_stock> <p1_frac>
mkside() {
    python3 - "$@" <<'PY'
import sys, os, struct
d, stock, frac = sys.argv[1], int(sys.argv[2], 0), int(sys.argv[3], 0)
os.makedirs(d, exist_ok=True)
BASE, LEN = 0xFF8000, 0xC00
# The anchor is the rising edge of the match-start predicate, DEBOUNCED 30
# frames (compare_fields.py) — a 6-frame fixture produced "transient/
# uncovered predicate edge ... ignored" and no anchor at all. Section 2
# caught that, which is why it exists.
for fr in range(100, 141):
    b = bytearray(LEN)
    if fr > 100:                       # anchor is the RISING edge
        struct.pack_into(">I", b, 0x004, 0x40000)
        struct.pack_into(">I", b, 0x008, 0x40000)
        struct.pack_into(">H", b, 0x450, 0x120)   # P1 HP
        struct.pack_into(">H", b, 0x850, 0x120)   # P2 HP
    b[0x509] = stock                                  # p1 +0x109
    struct.pack_into(">H", b, 0x50A, frac)            # p1 +0x10A.w
    open(os.path.join(d, f"dump_{fr}_{BASE:06x}.bin"), "wb").write(bytes(b))
PY
}

echo "== 2. two IDENTICAL sides agree (the fixture is sane) =="
mkside "$T/a" 3 0x40
mkside "$T/b" 3 0x40
if python3 tools/compare_fields.py "$T/a" "$T/b" --fields "$TSV" \
     --follow 0 > "$T/same" 2>&1; then
    echo "  ok: identical dumps compare equal"
else
    fail "identical dumps did NOT agree — the fixture is broken, so section 3"
    fail "      would 'catch' something for the wrong reason:"
    sed 's/^/        /' "$T/same" | head -5
fi

echo "== 3. THE CONTROL — a difference confined to METER must be caught =="
for case in "stock:4:0x40:p1_meter_stock" "frac:3:0x41:p1_meter_frac"; do
    what=${case%%:*}; rest=${case#*:}
    st=${rest%%:*}; rest=${rest#*:}
    fr=${rest%%:*}; want=${rest#*:}
    rm -rf "$T/c"; mkside "$T/c" "$st" "$fr"
    if python3 tools/compare_fields.py "$T/a" "$T/c" --fields "$TSV" \
         --follow 0 > "$T/diff" 2>&1; then
        fail "a $what-only difference was NOT caught — meter is in the TSV but"
        fail "      is not being compared, so the oracle is still blind to it"
    elif grep -q "$want" "$T/diff"; then
        echo "  ok: a $what-only difference is caught, and named ($want)"
    else
        fail "a $what-only difference failed the run but did not name $want:"
        sed 's/^/        /' "$T/diff" | head -4
    fi
done

echo "== 4. CLAUDE.md still makes the promise this gate enforces =="
# If the rule is ever reworded, this gate should be re-read, not silently kept.
if grep -q "meter" CLAUDE.md; then
    echo "  ok: CLAUDE.md 4 still names meter in the mapped set"
else
    fail "CLAUDE.md no longer names meter — re-check whether this gate still"
    fail "      reflects the ratified protocol"
fi

echo
[ "$rc" = 0 ] && echo "PASS: meter is mapped, bound to the atlas, and compared." \
             || echo "FAIL: see above."
exit $rc
