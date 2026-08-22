#!/bin/sh
# test_sim_wram_contract.sh — the ROM-free half of the MiSTer simulation
# oracle (14z-107). It locks the CONTRACT between the fork's Verilator
# work-RAM hook and tools/compare_fields.py, without a ROM, an emulator or
# an hour of simulation (the live end-to-end run is
# tests/test_mister_sim_anchor.sh, emulator tier).
#
# WHAT IT LOCKS:
#  1. The dump NAMING contract: wram/dump_<frame>_ff0000.bin is exactly what
#     compare_fields.py's DUMP_RE consumes, and a 64 KB $FF0000 window covers
#     every field in tests/fields_m2a.tsv plus the anchor predicate.
#  2. The BYTE-ORDER contract: the hook writes 68k big-endian (test.cpp
#     applies the same j^1 swap SDRAM::dump() applies). A byte-swapped side
#     must FAIL — that is the must-fire control, and it is the one mistake
#     that would otherwise produce a confidently wrong "the core disagrees
#     with MAME" report.
#  3. Anchor mode absorbs cross-implementation frame skew: the same content
#     at a different frame index still compares equal.
#  4. A perturbed NON-predicate field must be REPORTED (the second
#     must-fire control).
#  5. tools/run_sim_jtcps2.sh REFUSES to write RAM dumps inside the repo
#     (rule 7) and refuses to simulate inside it (jtsim litters the core dir).
#  6. The harness patch is INERT by construction: every non-comment line
#     emu/jtcores-patches/0002-jtframe-sim-wramdump.patch adds to test.cpp
#     sits inside an `#ifdef _JTFRAME_SIM_WRAMDUMP` block.
#  7. The CPS-2 constants in run_sim_jtcps2.sh agree with the pinned RTL
#     (jtcps1_sdram.v WRAM_OFFSET, jtcps2_main.v ram_cs) — noted, not run,
#     when emu/jtcores is not initialised.
# Usage: tests/test_sim_wram_contract.sh   (no ROMs, no emulator, ~5s)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; fail=0
ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }
cd "$REPO"

python3 - "$T" <<'PY'
import sys, pathlib
T = pathlib.Path(sys.argv[1])
BASE = 0xFF0000
def blank(): return bytearray(0x10000)
def put(buf, addr, width, val):
    for i in range(width):                      # big-endian, 68k order
        buf[addr - BASE + i] = (val >> (8 * (width - 1 - i))) & 0xFF
def live(seed):
    b = blank()
    put(b, 0xFF8004, 4, 0x40000); put(b, 0xFF8008, 4, 0x40000)
    put(b, 0xFF8450, 2, 0x120);   put(b, 0xFF8850, 2, 0x120)   # both HP full
    put(b, 0xFF8109, 1, 0x99)                                   # timer
    put(b, 0xFF8460, 4, 0x0BD9FA); put(b, 0xFF8860, 4, 0x0B3450)  # hitbox bases
    put(b, 0xFF8509, 1, 0x02);    put(b, 0xFF8909, 1, 0x02)     # meter stock
    put(b, 0xFF8410, 2, 0x0140);  put(b, 0xFF8810, 2, 0x02C0)   # x
    b[0x1234] = seed & 0xFF                                     # unmapped noise
    return b
def side(d, first_live, n_dead=6, n_live=40, swap=False, perturb=None):
    d.mkdir(parents=True, exist_ok=True)
    for k in range(n_dead):
        fr = first_live - n_dead + k
        (d / f"dump_{fr}_{BASE:06x}.bin").write_bytes(bytes(blank()))
    for k in range(n_live):
        b = live(k)
        if perturb is not None and k == perturb:
            put(b, 0xFF8109, 1, 0x98)            # timer one off (NOT a
            # predicate field: perturbing HP would move the anchor instead
            # of being reported, and the control would silently not fire)
        raw = bytes(b)
        if swap:
            raw = bytes(raw[i ^ 1] for i in range(len(raw)))
        (d / f"dump_{first_live + k}_{BASE:06x}.bin").write_bytes(raw)
side(T / "a", 100)
side(T / "b", 107)                       # same content, +7 frames of skew
side(T / "swap", 107, swap=True)         # byte order flipped
side(T / "bad", 107, perturb=0)          # one field wrong at the anchor
PY

CF="python3 $REPO/tools/compare_fields.py"
F="$REPO/tests/fields_m2a.tsv"

# 1 naming + coverage: the anchor is found in a 64 KB $FF0000 window
A="$($CF "$T/a" --list-anchors --fields "$F" 2>/dev/null | tr '\n' ' ')"
[ "$A" = "100 " ] && ok "1 anchor found in a 64 KB \$FF0000 dump (frame $A)" \
                  || bad "1 anchors were [$A], expected [100 ]"

# 3 anchor mode absorbs skew (7 frames here)
if $CF "$T/a" "$T/b" --fields "$F" --follow 0,10 --label-a mame --label-b sim > "$T/o1" 2>&1
then ok "3 skewed sides agree at the anchor"; else bad "3 skewed sides disagreed:"; sed 's/^/      /' "$T/o1"; fi

# 2 must-fire: a byte-swapped side is not 68k order, so the predicate dies
if $CF "$T/a" "$T/swap" --fields "$F" --follow 0 > "$T/o2" 2>&1
then bad "2 CONTROL DID NOT FIRE: byte-swapped side compared equal"
else ok "2 control fired: byte-swapped side rejected ($(head -1 "$T/o2" | cut -c1-46))"; fi

# 4 must-fire: one perturbed field is reported
if $CF "$T/a" "$T/bad" --fields "$F" --follow 0 > "$T/o3" 2>&1
then bad "4 CONTROL DID NOT FIRE: perturbed timer compared equal"
else grep -q "MISMATCH.*timer" "$T/o3" && ok "4 control fired: timer mismatch reported" \
                                       || { bad "4 wrong failure:"; sed 's/^/      /' "$T/o3"; }; fi

# 5 the runner's rule-7 / scratch refusals
out="$(ROMDIR="$T" "$REPO/tools/run_sim_jtcps2.sh" "$REPO/tests/replays/05_timeout_idle.rpl" \
        "$REPO/build/should_never_exist_14z107" 2>&1)"; st=$?
[ $st != 0 ] && echo "$out" | grep -q "REFUSING" && ok "5a out-dir inside the repo refused (rule 7)" \
    || bad "5a in-repo out-dir was NOT refused (exit $st)"
rmdir "$REPO/build/should_never_exist_14z107" 2>/dev/null
out="$(ROMDIR="$T" JTSIM_SCRATCH="$REPO/emu/jtcores" "$REPO/tools/run_sim_jtcps2.sh" \
        "$REPO/tests/replays/05_timeout_idle.rpl" "$T/out" 2>&1)"; st=$?
[ $st != 0 ] && echo "$out" | grep -q "REFUSING" && ok "5b JTSIM_SCRATCH inside the repo refused" \
    || bad "5b in-repo JTSIM_SCRATCH was NOT refused (exit $st)"

# 6 the harness patch is inert unless the macro is defined. The checker is
# itself controlled (CLAUDE.md §4 "verdict logic is itself tested"): the same
# script must REJECT a copy of the patch with one line moved outside the guard.
cat > "$T/guardcheck.py" <<'GUARDPY'
import re, sys
# Every CODE line the patch adds must sit inside an `#ifdef
# _JTFRAME_SIM_WRAMDUMP` region of the RESULTING file, so a build without the
# macro is byte-for-byte upstream's. Preprocessor directives are structural,
# not code: the patch legitimately adds an `#endif` that closes the preceding
# hook's block before opening ours.
lines = open(sys.argv[1], errors="replace").read().split("\n")
bad, touched, cur, hunk = [], set(), None, None
guarded_code = 0
def walk(h):
    global guarded_code
    stack = []
    for added, text in h:
        t = text.strip()
        if re.match(r"#\s*if", t):
            stack.append(t)
            continue
        if t.startswith("#endif"):
            if stack: stack.pop()
            elif added: bad.append("added #endif with no opener in the hunk")
            continue
        if not added or not t or t.startswith("//"):
            continue
        if any(x.startswith("#ifdef _JTFRAME_SIM_WRAMDUMP") for x in stack):
            guarded_code += 1
        else:
            bad.append(t[:60])
    if stack:
        bad.append("hunk ends inside an unclosed #ifdef")
for ln in lines:
    if ln == "-- ":            # git's signature block ends the patch body
        break
    if ln.startswith("diff --git"):
        if hunk is not None: walk(hunk)
        hunk = None; cur = ln.split()[-1]; continue
    if ln.startswith("@@"):
        if hunk is not None: walk(hunk)
        hunk = []; continue
    if hunk is None or ln.startswith("+++") or ln.startswith("---"):
        continue
    if ln.startswith("+"):
        hunk.append((True, ln[1:])); touched.add(cur)
    elif ln.startswith(" "):
        hunk.append((False, ln[1:]))
    elif ln.startswith("-"):
        bad.append("the patch DELETES a line: " + ln[1:].strip()[:50])
if hunk is not None: walk(hunk)
if touched != {"b/modules/jtframe/hdl/ver/test.cpp"}:
    bad.append("patch touches %s, expected only test.cpp" % sorted(touched))
if guarded_code < 5:
    bad.append("only %d guarded code lines - the patch looks degenerate" % guarded_code)
for b in bad: print("      unguarded:", b)
sys.exit(1 if bad else 0)
GUARDPY
PATCH="$REPO/emu/jtcores-patches/0002-jtframe-sim-wramdump.patch"
if python3 "$T/guardcheck.py" "$PATCH"; then
    ok "6 every added code line is inside #ifdef _JTFRAME_SIM_WRAMDUMP"
else
    bad "6 the harness patch adds code OUTSIDE the macro guard"
fi
# the control: hoist one added line above the guard
awk '{ if (!done && $0 ~ /^\+#ifdef _JTFRAME_SIM_WRAMDUMP$/) { print "+    int leak=1;"; done=1 } print }' \
    "$PATCH" > "$T/leak.patch"
if python3 "$T/guardcheck.py" "$T/leak.patch" > "$T/o6" 2>&1
then bad "6c CONTROL DID NOT FIRE: an unguarded line passed the checker"
else ok "6c control fired: an unguarded added line is rejected"; fi

# 7 the CPS-2 constants agree with the pinned RTL
SRC="$REPO/emu/jtcores"
if [ -f "$SRC/cores/cps1/hdl/jtcps1_sdram.v" ]; then
    grep -q "WRAM_OFFSET  = 23'h30_0000" "$SRC/cores/cps1/hdl/jtcps1_sdram.v" \
        && grep -q "WRAM_OFF=0x600000" "$REPO/tools/run_sim_jtcps2.sh" \
        && grep -q "addr      = ram_cs ? {2'b0, A\[15:1\] }" "$SRC/cores/cps2/hdl/jtcps2_main.v" \
        && grep -q "WRAM_LEN=0x10000" "$REPO/tools/run_sim_jtcps2.sh" \
        && ok "7 WRAM_OFFSET 23'h30_0000 words = byte 0x600000, A[15:1] = 64 KB" \
        || bad "7 run_sim_jtcps2.sh constants no longer match the pinned RTL"
else
    echo "  note: emu/jtcores not initialised — RTL cross-check not run"
fi

rm -rf "$T"
[ $fail = 0 ] && echo "PASS test_sim_wram_contract" || { echo "FAIL test_sim_wram_contract"; exit 1; }
