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
#  8. A LOST OR SHORT DUMP IS LOUD (14z-107 (7)). compare_fields.py GLOBS a
#     directory, so a dump that never gets written does not fail a
#     comparison — it silently changes WHICH frames exist, and on an anchor
#     search that is indistinguishable from the two implementations
#     disagreeing about when the match starts. tools/check_wram_dumps.py is
#     the assertion, and it is itself controlled here: a hole, a truncated
#     file, a stray frame and a wrong address must each FAIL it.
#  9. FRAME OUTPUT IS OFF BY DEFAULT in the lane (14z-107 (7)). jtframe's
#     harness forks an ImageMagick child per CHANGED frame, so the host work
#     a run does follows the PICTURE; fork commit 8 makes that suppressible
#     and run_sim_jtcps2.sh suppresses it for every state measurement. The
#     default is asserted, with the flipped-default control.
# 10. THE FORK-FLUSH MECHANISM, GROUND-TRUTHED (14z-107 (7)). The gotcha
#     entry claims that a forked child's exit(0) flushes a COPY of the
#     PARENT's buffered stdout into the shared file description, so a line
#     printed once appears once per child. That is the whole reason a run's
#     LOG is not trustworthy with frame output on, and it is asserted here
#     rather than believed: N children that call exit() and N that call
#     _exit() must give exactly N+1 copies. Skipped where there is no C++
#     compiler.
# 11. THE INPUT-SCRIPT REWIND, GROUND-TRUTHED (14z-107 (7)) — the defect
#     fork commit 9 fixes, and the reason a rendering difference could reach
#     the simulated CPU at all. A forked child's exit(0) fclose()s the COPY
#     it inherited of the parent's read stream; POSIX makes fclose()
#     reposition the SHARED file description back to the stream's logical
#     position, so the parent's next buffer refill re-reads lines it had
#     already consumed. In test.cpp that stream is sim_inputs.hex, i.e. the
#     simulated controller. Asserted here on a file large enough to force
#     refills: with exit() children the read sequence goes BACKWARDS; with
#     _exit() children (what the fork now does) it does not.
# 12. THE SIMULATED CONTROLLER PRESSES ONLY WHAT THE SCRIPT SAYS (14z-107 (8)).
#     At v1.7.3 SimInputs held buttons 5 and 6 DOWN: parse_inputs() masked
#     the joystick word with `&0xf0` on a port that is [9:0] and ACTIVE LOW,
#     and the constructor seeded joystick1..4 with 0xff, which
#     parse_inputs() never corrects for players 2-4. On a 6-button core those
#     bits are wired (jtcps2_main.v:266-268), so the MAME leg and the sim leg
#     of the anchor oracle were not running the same inputs. Fork commit 10
#     fixes it; this check holds the PINNED test.cpp to it, with the control
#     that a softened copy is detected. Measured evidence:
#     docs/platform/mister.md "SimInputs HELD BUTTONS 5 AND 6 DOWN".
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

# 8 the dump-integrity assertion, with its four must-fire controls
CK="$REPO/tools/check_wram_dumps.py"
mkdir -p "$T/int"
i=100
while [ $i -le 120 ]; do
    dd if=/dev/zero of="$T/int/dump_${i}_ff0000.bin" bs=1024 count=64 2>/dev/null
    i=$((i + 1))
done
python3 "$CK" "$T/int" --first 100 --last 120 --size 0x10000 --addr 0xff0000 >/dev/null 2>&1 \
    && ok "8 a complete 21-frame dump set passes the integrity check" \
    || bad "8 a complete dump set was rejected"
cp -R "$T/int" "$T/int_hole" && rm -f "$T/int_hole/dump_110_ff0000.bin"
if python3 "$CK" "$T/int_hole" --first 100 --last 120 --size 0x10000 > "$T/o8a" 2>&1
then bad "8a CONTROL DID NOT FIRE: a missing dump passed"
else grep -q "MISSING frame(s)" "$T/o8a" && ok "8a control fired: a lost dump is a LOUD failure" \
     || { bad "8a wrong failure:"; sed 's/^/      /' "$T/o8a"; }; fi
cp -R "$T/int" "$T/int_short" && dd if=/dev/zero of="$T/int_short/dump_110_ff0000.bin" bs=1024 count=17 2>/dev/null
if python3 "$CK" "$T/int_short" --first 100 --last 120 --size 0x10000 > "$T/o8b" 2>&1
then bad "8b CONTROL DID NOT FIRE: a truncated dump passed"
else grep -q "not 65536 bytes" "$T/o8b" && ok "8b control fired: a short dump is a LOUD failure" \
     || { bad "8b wrong failure:"; sed 's/^/      /' "$T/o8b"; }; fi
cp -R "$T/int" "$T/int_stray" && cp "$T/int/dump_100_ff0000.bin" "$T/int_stray/dump_999_ff0000.bin"
if python3 "$CK" "$T/int_stray" --first 100 --last 120 --size 0x10000 > "$T/o8c" 2>&1
then bad "8c CONTROL DID NOT FIRE: a stray out-of-range dump passed"
else ok "8c control fired: a dump outside the requested window is rejected"; fi
cp -R "$T/int" "$T/int_addr" && mv "$T/int_addr/dump_110_ff0000.bin" "$T/int_addr/dump_110_ff8000.bin"
if python3 "$CK" "$T/int_addr" --first 100 --last 120 --size 0x10000 --addr 0xff0000 > "$T/o8d" 2>&1
then bad "8d CONTROL DID NOT FIRE: a dump of the wrong window passed"
else ok "8d control fired: a dump naming another address is rejected"; fi
# --contiguous is what a directory of unknown extent (the MAME leg) gets
python3 "$CK" "$T/int" --contiguous --size 0x10000 >/dev/null 2>&1 \
    && ok "8e --contiguous accepts an unbroken run" || bad "8e --contiguous rejected an unbroken run"
if python3 "$CK" "$T/int_hole" --contiguous > "$T/o8f" 2>&1
then bad "8f CONTROL DID NOT FIRE: --contiguous passed a run with a hole"
else grep -q "HOLE" "$T/o8f" && ok "8f control fired: --contiguous reports the hole" \
     || { bad "8f wrong failure:"; sed 's/^/      /' "$T/o8f"; }; fi

# 9 the lane suppresses host frame output by default
RS="$REPO/tools/run_sim_jtcps2.sh"
checkdefault() {   # $1 = script to inspect
    grep -q 'FRAMEOUT=off; STATS=0' "$1" || return 1
    grep -q 'off)     SIMARGS="$SIMARGS -d JTFRAME_SIM_NOVIDEO=1" ;;' "$1" || return 1
    return 0
}
checkdefault "$RS" && ok "9 run_sim_jtcps2.sh defaults to --frame-output off (-d JTFRAME_SIM_NOVIDEO=1)" \
                   || bad "9 the lane no longer suppresses host frame output by default"
sed 's/FRAMEOUT=off; STATS=0/FRAMEOUT=fork; STATS=0/' "$RS" > "$T/flipped.sh"
if checkdefault "$T/flipped.sh"
then bad "9c CONTROL DID NOT FIRE: a flipped default passed the check"
else ok "9c control fired: a flipped frame-output default is rejected"; fi
# and the fork commit that makes it possible wraps upstream's writer without
# deleting a line of it
P8="$REPO/emu/jtcores-patches/0008-jtframe-sim-optional-frame-writer.patch"
if [ -f "$P8" ]; then
    del="$(sed -n '/^diff --git/,$p' "$P8" | grep -c '^-[^-]' || true)"
    files="$(grep -c '^diff --git' "$P8")"
    grep -q '^+#ifndef _JTFRAME_SIM_NOVIDEO' "$P8" \
        && grep -q '^+                while( waitpid(-1,nullptr,WNOHANG) > 0 ) ;' "$P8" \
        && [ "$del" = 0 ] && [ "$files" = 1 ] \
        && ok "9b patch 0008 wraps upstream's frame writer (0 deleted lines, 1 file) and reaps" \
        || bad "9b patch 0008 is not the declared shape (deleted lines $del, files $files)"
fi
# and the child must END HARD: exit() is what corrupted the input script
P9="$REPO/emu/jtcores-patches/0009-jtframe-sim-child-must-exit-hard.patch"
if [ -f "$P9" ]; then
    grep -q '^+                        _exit(0);' "$P9" \
        && grep -q '^-                        exit(0);' "$P9" \
        && ok "9d patch 0009 replaces the child's exit(0) with _exit(0)" \
        || bad "9d patch 0009 no longer turns the child's exit(0) into _exit(0)"
    TCPP="$REPO/emu/jtcores/modules/jtframe/hdl/ver/test.cpp"
    if [ -f "$TCPP" ]; then
        # the child must end HARD. `[^_]exit(0)` catches a plain exit(0) at
        # any indentation while allowing _exit(0); BSD grep has no \s, so the
        # class is spelled out.
        n_hard="$(grep -c '_exit(0);' "$TCPP" || true)"
        n_soft="$(grep -cE '(^|[^_[:alnum:]])exit\(0\);' "$TCPP" || true)"
        [ "$n_hard" -ge 1 ] && [ "$n_soft" = 0 ] \
            && ok "9e the pinned test.cpp's forked child ends with _exit, not exit ($n_hard _exit, $n_soft exit)" \
            || bad "9e the pinned test.cpp still has $n_soft plain exit(0) in a forked child — that rewinds sim_inputs.hex"
        # and the checker is controlled: a copy with _exit softened must fail
        sed 's/_exit(0);/exit(0);/' "$TCPP" > "$T/soft.cpp"
        [ "$(grep -cE '(^|[^_[:alnum:]])exit\(0\);' "$T/soft.cpp")" -ge 1 ] \
            && ok "9f control fired: a copy with _exit softened back to exit is detected" \
            || bad "9f CONTROL DID NOT FIRE: the exit(0) detector matches nothing"
    else
        echo "  note: emu/jtcores not initialised — 9e not run"
    fi
fi

# 10 the fork-flush mechanism the gotcha entry rests on
if command -v c++ >/dev/null 2>&1; then
    cat > "$T/ft.cpp" <<'FTCPP'
#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <sys/wait.h>
// N children that call _exit() (no flush) and N that call exit() (flush the
// inherited COPY of the parent's buffered stdout). Redirected stdout is
// block-buffered, so the line below is still in the buffer when they fork.
int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 3;
    printf("PARENT PRINTED THIS ONCE\n");
    for (int i = 0; i < n; i++) if (fork() == 0) _exit(0);
    for (int i = 0; i < n; i++) if (fork() == 0) exit(0);
    while (waitpid(-1, nullptr, 0) > 0) ;
    return 0;
}
FTCPP
    if c++ -O0 -o "$T/ft" "$T/ft.cpp" 2>"$T/ft.err"; then
        c3="$("$T/ft" 3 > "$T/ft3.txt"; grep -c 'PARENT PRINTED THIS ONCE' "$T/ft3.txt")"
        c7="$("$T/ft" 7 > "$T/ft7.txt"; grep -c 'PARENT PRINTED THIS ONCE' "$T/ft7.txt")"
        [ "$c3" = 4 ] && [ "$c7" = 8 ] \
            && ok "10 fork-flush ground truth: N exiting children duplicate the parent's buffered stdout N times (3->4, 7->8 copies)" \
            || bad "10 fork-flush ground truth got $c3 and $c7 copies, expected 4 and 8 — the gotcha's mechanism claim needs re-measuring"
    else
        echo "  note: c++ present but the ground-truth program did not build — check 10 not run"
    fi
else
    echo "  note: no c++ compiler — the fork-flush ground truth (check 10) not run"
fi

# 11 the input-script rewind: the defect fork commit 9 fixes
if command -v c++ >/dev/null 2>&1; then
    python3 -c "open('$T/big.txt','w').write(''.join('%05d\n'%i for i in range(1,5001)))"
    cat > "$T/rw.cpp" <<'RWCPP'
// A parent reading a file line by line while forking one child per line.
// libc++'s basic_filebuf is a FILE*; exit() fcloses it in the child, and
// fclose() on a seekable read stream repositions the SHARED file description
// to the stream's logical position -- so the parent's next buffer refill
// re-reads consumed lines. _exit() skips the stdio cleanup and does not.
#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>
#include <sys/wait.h>
#include <cstdlib>
int main(int argc, char **argv) {
    std::string mode = argc > 1 ? argv[1] : "exit";
    std::ifstream fin("big.txt");
    std::string s, prev;
    int n = 0, back = 0;
    while (std::getline(fin, s) && n < 3000) {
        n++;
        if (!prev.empty() && std::stoi(s) <= std::stoi(prev)) back++;
        prev = s;
        if (mode != "nofork") {
            if (fork() == 0) { if (mode == "_exit") _exit(0); else exit(0); }
        }
        while (waitpid(-1, nullptr, WNOHANG) > 0) ;
    }
    std::cout << n << " " << prev << " " << back << "\n";
    return 0;
}
RWCPP
    if ( cd "$T" && c++ -O0 -o rw rw.cpp 2>/dev/null ); then
        r_no="$( cd "$T" && ./rw nofork )"
        r_hard="$( cd "$T" && ./rw _exit )"
        r_soft="$( cd "$T" && ./rw exit )"
        b_no="$(echo "$r_no" | awk '{print $3}')"
        b_hard="$(echo "$r_hard" | awk '{print $3}')"
        b_soft="$(echo "$r_soft" | awk '{print $3}')"
        [ "$b_no" = 0 ] && [ "$b_hard" = 0 ] \
            && ok "11 _exit() children leave the parent's read stream INTACT (0 backward steps, as with no fork at all)" \
            || bad "11 _exit() children perturbed the read stream ($r_hard) — the fork-commit-9 fix does not hold"
        [ "$b_soft" -gt 0 ] \
            && ok "11c control fired: exit() children REWIND the shared read offset ($b_soft backward steps; the parent ended at line $(echo "$r_soft" | awk '{print $2}') of 3000)" \
            || bad "11c CONTROL DID NOT FIRE: exit() children did not rewind — re-derive the mechanism before trusting the gotcha"
    else
        echo "  note: the rewind ground-truth program did not build — check 11 not run"
    fi
fi

# 12 the harness must not assert buttons the input script never pressed
P10="$REPO/emu/jtcores-patches/0010-jtframe-sim-joystick-top-bits.patch"
if [ -f "$P10" ]; then
    files="$(grep -c '^diff --git' "$P10")"
    grep -q '^-        dut.joystick1    = (dut.joystick1&0xf0) | (v&0xf);' "$P10" \
        && grep -q '^+        dut.joystick1    = (dut.joystick1&~0xf) | (v&0xf);' "$P10" \
        && grep -q '^-        dut.joystick2 = 0xff;' "$P10" \
        && grep -q '^+        dut.joystick2 = 0x3ff;' "$P10" \
        && [ "$files" = 1 ] \
        && ok "12a patch 0010 widens the direction mask AND the 4 joystick seeds (1 file)" \
        || bad "12a patch 0010 is not the declared shape (files $files)"
    TCPP="$REPO/emu/jtcores/modules/jtframe/hdl/ver/test.cpp"
    if [ -f "$TCPP" ]; then
        # THE TWO WAYS THE 8-BIT ASSUMPTION SHOWS UP, both must be gone:
        # a direction mask that keeps only bits 7:0, and a seed that is 0xff
        # rather than 0x3ff on a [9:0] ACTIVE-LOW port.
        n_mask="$(grep -c 'dut.joystick1&0xf0' "$TCPP" || true)"
        n_seed="$(grep -cE 'dut\.joystick[1-4] = 0xff;' "$TCPP" || true)"
        n_good="$(grep -c 'dut.joystick1&~0xf' "$TCPP" || true)"
        [ "$n_mask" = 0 ] && [ "$n_seed" = 0 ] && [ "$n_good" -ge 1 ] \
            && ok "12b the pinned test.cpp releases buttons 5 and 6 ($n_good widened masks, 0 8-bit masks, 0 8-bit seeds)" \
            || bad "12b the pinned test.cpp still holds buttons 5/6 ($n_mask 8-bit masks, $n_seed 8-bit seeds)"
        sed 's/dut.joystick1&~0xf/dut.joystick1\&0xf0/' "$TCPP" > "$T/soft8.cpp"
        [ "$(grep -c 'dut.joystick1&0xf0' "$T/soft8.cpp")" -ge 1 ] \
            && ok "12c control fired: a copy with the mask narrowed back to 8 bits is detected" \
            || bad "12c CONTROL DID NOT FIRE: the 8-bit-mask detector matches nothing"
    else
        echo "  note: emu/jtcores not initialised — 12b not run"
    fi
fi

rm -rf "$T"
[ $fail = 0 ] && echo "PASS test_sim_wram_contract" || { echo "FAIL test_sim_wram_contract"; exit 1; }
