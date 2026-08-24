#!/bin/sh
# test_mister_prg_probe.sh — the ROM-free half of the slice D4 discriminator
# (14z-107 (11)). It locks the CONTRACT of the 68k program-ROM read probe and
# of the tool that reads it, without a ROM, an emulator or 40 minutes of
# Verilator. The live end-to-end runs are the emulator tier.
#
# WHY THE PROBE EXISTS. D4 declares a 6 MB program window on cores/cps2w and
# the only evidence for it was that its lines are in the RTL: the SDRAM census
# proves the bytes are PLACED above CPU:$400000, nothing proved the 68k could
# READ them. That gap made "profile-on and profile-off are frame-for-frame
# identical" ambiguous — it reads as "the profile is innocent" only if the
# decode WORKS, and a DEAD decode produces the same identity for the opposite
# reason. The probe splits the two.
#
# WHAT THIS GATE LOCKS:
#  1. THE PROBE IS INERT BY CONSTRUCTION. Every non-comment line
#     emu/jtcores-patches/0016-cps2w-prg-read-probe.patch adds to
#     jtcps2_main.v sits inside an `ifdef JTCPS2W_PRGPROBE region, so a build
#     without the macro — every synthesis build, and every other simulation —
#     is character for character what slice D4 shipped. The checker is itself
#     controlled: a copy of the patch with one added line hoisted above the
#     guard must be REJECTED.
#  2. THE PROBE'S WINDOW IS THE DECODE'S WINDOW. The probe classifies a read
#     as "above $400000" by rom_addr[21], and rom_addr is A[22:1]; the decode
#     extends rom_cs over A[23:21]==3'b010. Both are re-read from the RTL, so
#     a decode moved without moving the probe (or the reverse) fails here
#     rather than silently reporting the wrong window.
#  3. THE PROBE IS DECODE-INDEPENDENT ON THE ADDRESS SIDE. It counts 68k bus
#     cycles by A[23:21] whether or not anything selects them. That half is
#     what still speaks when `wide_en` is CLEAR and rom_cs cannot assert in
#     the window at all — without it, a zero could not distinguish "the CPU
#     never addressed $400000+" from "it did and the decode ignored it".
#  4. THE VERDICT LOGIC IS ITSELF TESTED (CLAUDE.md §4). tools/prgprobe_verdict.py
#     is run against SYNTHETIC probe logs whose answer is known by
#     construction: all three verdicts, and BOTH refusals — a silent control
#     sample, and a control sample that does not verify. A tool that cannot
#     say "I refuse" is not an instrument, it is an opinion.
#  5. THE RUNNER REFUSES --prgprobe ON THE REFERENCE CORE, which has no such
#     block; asking for it there would produce a silent zero.
# Usage: tests/test_mister_prg_probe.sh   (no ROMs, no emulator, ~3s)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

PATCH="$REPO/emu/jtcores-patches/0016-cps2w-prg-read-probe.patch"
HDL="$REPO/emu/jtcores/cores/cps2w/hdl/jtcps2_main.v"

# ── 1 the probe is inert unless the macro is defined ───────────────────────
guard_check() {   # guard_check <patch file>; 0 = every added code line guarded
    python3 - "$1" <<'PY'
import re, sys
stack, bad, inside = [], [], False
for line in open(sys.argv[1], errors="replace"):
    if line.startswith("@@"):
        stack, inside = [], False
        continue
    if not line.startswith("+") or line.startswith("+++"):
        continue
    t = line[1:].strip()
    if t.startswith("`ifdef") or t.startswith("`ifndef"):
        stack.append(t); continue
    if t.startswith("`endif"):
        if stack: stack.pop()
        continue
    if not t or t.startswith("//"):
        continue
    if not any(x.startswith("`ifdef JTCPS2W_PRGPROBE") for x in stack):
        bad.append(t)
if stack:
    bad.append("hunk ends inside an unclosed `ifdef")
if bad:
    print("UNGUARDED: " + " | ".join(bad[:4]))
    sys.exit(1)
PY
}
if [ ! -f "$PATCH" ]; then
    echo "SKIP: no $PATCH (tools/setup_jtcores.sh regenerates the series)"; exit 77
fi
if out="$(guard_check "$PATCH")"; then
    ok "1 every code line the probe adds is inside \`ifdef JTCPS2W_PRGPROBE"
else
    bad "1 the probe patch adds code OUTSIDE its guard: $out"
fi
# the control: hoist one added line above the guard
awk '{ if (!done && $0 ~ /^\+`ifdef JTCPS2W_PRGPROBE$/) { print "+integer leak;"; done=1 } print }' \
    "$PATCH" > "$W/leaky.patch"
if cmp -s "$PATCH" "$W/leaky.patch"; then
    bad "1C control could not perturb the patch (no \`ifdef line found)"
elif guard_check "$W/leaky.patch" >/dev/null 2>&1; then
    bad "1C control did NOT fire: an unguarded added line passed the checker"
else
    ok "1C control fired (a line hoisted above the guard is rejected)"
fi

# ── 2/3 the probe's window IS the decode's window ──────────────────────────
if [ ! -f "$HDL" ]; then
    echo "  note: emu/jtcores not initialised — 2/3 not run"
else
    grep -q "rom_cs      <= (A\[23:22\] == 2'b00) |" "$HDL" \
      && grep -q "(wide_en & RnW & (A\[23:21\] == 3'b010));" "$HDL" \
      && ok "2a the decode window is still A[23:21]==3'b010, read from the RTL" \
      || bad "2a the 6 MB decode window MOVED — the probe's discriminator no longer matches it"
    grep -q "rom_addr    <= A\[22:1\];" "$HDL" \
      && ok "2b rom_addr is A[22:1] — its INDEX is the 68k address bit" \
      || bad "2b rom_addr is no longer A[22:1] — rom_addr[21] is not the window bit"
    grep -q "if( prg_a\[22\] ) begin" "$HDL" \
      && ok "2c the probe splits HI from LO on rom_addr[22], which IS A[22]" \
      || bad "2c the probe's HI/LO discriminator is not rom_addr[22] — see the [21] trap"
    grep -q "if( A\[23:21\]==3'b010 ) begin" "$HDL" \
      && ok "3a the ADDRESS half classifies by A[23:21], with no chip select in the condition" \
      || bad "3a the probe's address half is not decode-independent"
    grep -q "prg_asn_l && !ASn && BGACKn" "$HDL" \
      && ok "3b ...on the FALL of ASn, i.e. once per 68k bus cycle" \
      || bad "3b the address half does not count one record per bus cycle"
    grep -q "if( rom_cs && rom_ok && rom_ok2 ) begin" "$HDL" \
      && ok "3c the DATA half samples on the same condition bus_busy releases the 68k with" \
      || bad "3c the data half does not sample on rom_ok & rom_ok2"
fi

# ── 4 the verdict logic, on synthetic logs whose answer is known ───────────
# A 1 MB fake .rom: 64-byte header then a byte pattern. The probe records are
# generated FROM it, so "correct" and "wrong" are constructed, not judged.
python3 - "$W" <<'PY'
import os, sys
W = sys.argv[1]
HDR = 64
SIZE = 0x700000
rom = bytearray(HDR + SIZE)
for i in range(SIZE):
    rom[HDR + i] = (i * 7 + (i >> 11) * 13) & 0xFF
open(os.path.join(W, "fake.rom"), "wb").write(bytes(rom))

def word(a):
    return (rom[HDR + a] << 8) | rom[HDR + a + 1]

def emit(path, lo, hi, lo_ok=True, hi_ok=True):
    with open(path, "w") as f:
        f.write("# PRGPROBE synthetic\n")
        for n in range(lo):
            a = 0x001000 + n * 2
            f.write("LO %d %06x %04x %04x 5\n" % (10 + n, a, word(a), word(a) if lo_ok else word(a) ^ 0xFFFF))
        for n in range(hi):
            a = 0x400100 + n * 2
            f.write("HI %d %06x %04x %04x 5\n" % (20 + n, a, word(a), word(a) if hi_ok else 0xFFFF))
            f.write("CYC %d R %06x 5\n" % (20 + n, a))
        f.write("PRGPROBE frame 100 wide 1 cyc %d cyc_hi_rd %d cyc_hi_wr 0 rd_hi %d rd_lo %d"
                " blocks %d first_frame %d first_addr 400100 min 400100 max 40ffff\n"
                % (lo + hi, hi, hi, lo, 1 if hi else 0, 20 if hi else -1))

emit(os.path.join(W, "answer2.txt"), 40, 12)
emit(os.path.join(W, "answer3.txt"), 40, 12, hi_ok=False)
emit(os.path.join(W, "answer1.txt"), 40, 0)
emit(os.path.join(W, "refuse_silent.txt"), 0, 12)
emit(os.path.join(W, "refuse_control.txt"), 40, 12, lo_ok=False)

# THE BYTE ORDER IS DERIVED, NOT ASSUMED: the same records with every word
# byte-swapped must still reach ANSWER 2, because the control sample picks the
# order and then the window is judged with it. A tool that hard-coded one order
# would call this ANSWER 3 and blame the core for a convention.
def swap(v):
    return ((v & 0xFF) << 8) | (v >> 8)
with open(os.path.join(W, "swapped.txt"), "w") as f:
    f.write("# PRGPROBE synthetic — the other byte order\n")
    for n in range(40):
        a = 0x001000 + n * 2
        f.write("LO %d %06x %04x %04x 5\n" % (10 + n, a, swap(word(a)), swap(word(a))))
    for n in range(12):
        a = 0x400100 + n * 2
        f.write("HI %d %06x %04x %04x 5\n" % (20 + n, a, swap(word(a)), swap(word(a))))
    f.write("PRGPROBE frame 100 wide 1 cyc 52 cyc_hi_rd 12 cyc_hi_wr 0 rd_hi 12 rd_lo 40"
            " blocks 1 first_frame 20 first_addr 400100 min 400100 max 400118\n")

# THE DECRYPTOR CASE — the real 14z-107 (11) result, and the verdict bug it
# caught. The RAW words are all the .rom's and the CPU received something else
# for every one of them. The first version of the tool judged only the raw word
# and reported "D4 WORKS" over ten fetches the 68k took as garbage.
with open(os.path.join(W, "latched.txt"), "w") as f:
    f.write("# PRGPROBE synthetic — raw right, latched wrong\n")
    for n in range(40):
        a = 0x001000 + n * 2
        f.write("LO %d %06x %04x %04x 5\n" % (10 + n, a, word(a), word(a)))
    for n in range(10):
        a = 0x4BE7C0 + n * 2
        f.write("HI %d %06x %04x %04x 2\n" % (1119, a, word(a) ^ 0x3330, word(a)))
    f.write("PRGPROBE frame 2300 wide 1 cyc 71326093 cyc_hi_rd 10 cyc_hi_wr 7198"
            " rd_hi 10 rd_lo 40 blocks 1 first_frame 1119 first_addr 4be7c0"
            " min 4be7c0 max 4be7d2\n")

# THE MISLABELLED PROBE — the defect the first draft of the RTL block shipped
# with: HI records whose addresses are BELOW $400000, because the discriminator
# read rom_addr[21] where the window bit is rom_addr[22]. The counts look
# perfectly healthy; only the addresses give it away.
with open(os.path.join(W, "refuse_mislabel.txt"), "w") as f:
    f.write("# PRGPROBE synthetic — mislabelled\n")
    for n in range(40):
        a = 0x001000 + n * 2
        f.write("LO %d %06x %04x %04x 5\n" % (10 + n, a, word(a), word(a)))
    for n in range(12):
        a = 0x38C2A0 + n * 2          # A[21] set, A[22] CLEAR: not in the window
        f.write("HI %d %06x %04x %04x 5\n" % (20 + n, a, word(a), word(a)))
    f.write("PRGPROBE frame 100 wide 1 cyc 52 cyc_hi_rd 0 cyc_hi_wr 6 rd_hi 12 rd_lo 40"
            " blocks 1 first_frame 20 first_addr 38c2a0 min 38c2a0 max 3d8256\n")
PY
run_verdict() {   # run_verdict <log> ; echoes the exit code
    python3 "$REPO/tools/prgprobe_verdict.py" "$W/$1" --rom "$W/fake.rom" > "$W/$1.out" 2>&1
    echo $?
}
for case in "answer2.txt 0 ANSWER 2" "answer3.txt 3 ANSWER 3" "answer1.txt 1 ANSWER 1" \
            "refuse_silent.txt 2 REFUSED" "refuse_control.txt 2 REFUSED" \
            "refuse_mislabel.txt 2 REFUSED" "swapped.txt 0 ANSWER 2" \
            "latched.txt 3 ANSWER 3"; do
    # shellcheck disable=SC2086
    set -- $case
    got="$(run_verdict "$1")"
    if [ "$got" = "$2" ]; then
        ok "4 $1 -> exit $got ($3$([ $# -gt 3 ] && echo " $4"))"
    else
        bad "4 $1 -> exit $got, expected $2"
        sed 's/^/       /' "$W/$1.out" | tail -6
    fi
done
grep -q "ANSWER 2" "$W/answer2.txt.out" && grep -q "ANSWER 3" "$W/answer3.txt.out" \
  && grep -q "ANSWER 1" "$W/answer1.txt.out" \
  && ok "4b each verdict names itself in words as well as in an exit code" \
  || bad "4b a verdict's exit code and its text disagree"
grep -q "ZERO reads BELOW" "$W/refuse_silent.txt.out" \
  && ok "4c the silent-control refusal says WHY (the instrument did not fire)" \
  || bad "4c the silent-control refusal does not name its reason"
grep -q "comparison procedure itself is wrong" "$W/refuse_control.txt.out" \
  && ok "4d the failing-control refusal blames the PROCEDURE, not the core" \
  || bad "4d the failing-control refusal does not name its reason"
grep -q "OPCODE fetches" "$W/latched.txt.out" \
  && ok "4g raw-right/latched-wrong is ANSWER 3, and it names the decryptor" \
  || bad "4g the tool judged only the raw word — the verdict bug of 14z-107 (11)"
grep -q "rom\[off+1\]<<8|rom\[off\] (it accounts" "$W/swapped.txt.out" \
  && ok "4f the byte order is DERIVED from the control, not hard-coded" \
  || bad "4f the byte-order derivation did not pick the order the control validates"
grep -q "MISLABELLED" "$W/refuse_mislabel.txt.out" \
  && ok "4e a probe whose HI records sit BELOW \$400000 is refused before any verdict" \
  || bad "4e the mislabelled-probe refusal did not fire — the tool would have believed the label"

# ── 5 --prgprobe refuses the reference core ────────────────────────────────
out="$(ROMDIR="$REPO" "$REPO/tools/run_sim_jtcps2.sh" x.rpl "$W/out5" --core cps2 --prgprobe 2>&1 || true)"
case "$out" in
    *"needs --core cps2w"*) ok "5 --prgprobe refuses cores/cps2, which has no such block" ;;
    *) bad "5 --prgprobe did not refuse the reference core: $(echo "$out" | tail -1)" ;;
esac

[ "$fail" = 0 ] && echo "PASS test_mister_prg_probe" || echo "FAIL test_mister_prg_probe"
exit "$fail"
