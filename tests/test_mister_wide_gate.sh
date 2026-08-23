#!/bin/sh
# test_mister_wide_gate.sh — THE CPS-2 WIDE RUNTIME PROFILE GATE, on MiSTer.
# 14z-107 (6), slice D1. ROM-free; seconds without Verilator, ~30 s with it.
#
# WHAT THIS GATE IS FOR. Slice D1 is the first time `cores/cps2w` carries RTL,
# so it is the first time the MiSTer leg has a trust surface at all. Rule 1 v2
# asks that such a change be BOUNDED, DECLARATIVE, PROFILE-GATED, REVIEWABLE
# and MIRRORED. This gate is where each of those words is turned into a check:
#
#  1. BOUNDED + REVIEWABLE — the diff of each OVERRIDDEN file against the
#     shared original is frozen in tests/expect/cps2w_rtl_delta.txt. Anything
#     that changes in cores/cps2w/hdl and is not in that file fails here. (The
#     reference cores being byte-untouched is tests/test_jtcores_twin.sh 2e.)
#  2. DECLARATIVE — the profile byte exists in THREE places (the fork's TOML,
#     the RTL decoder, this gate) and all three must say 41/0xFE/active-low.
#     A one-byte disagreement between the MRA and the RTL is invisible at
#     build time and catastrophic at run time: it would either leave the WIDE
#     set running as stock, or — the polarity failure — turn the profile ON
#     for every stock MRA, which is a superset-invariant break.
#  3. PROFILE-GATED — the two gated modules are SIMULATED, exhaustively:
#     * jtcps2w_qsnd_bank over ALL 65,536 values of dsp_ab in BOTH profile
#       states: with wide_en low, bank[7] (= qsnd_addr[23]) must be STUCK AT
#       ZERO and bank[6:0] must equal the stock expression; with wide_en high
#       it must MOVE. That is the "qsnd_addr[23] moves only when gated" probe
#       the slice asked for, applied to the whole input space rather than to
#       whatever addresses one 45-minute core run happens to visit.
#     * jtcps2w_profile over a real 64-byte header stream: the generator's
#       0xFF fill must leave the profile OFF, byte 41 = 0xFE must raise it,
#       every other address and the NVRAM path must be inert, and it must
#       re-default on the next download.
#  4. REACHABLE — `jtframe files` must resolve cps2w to OUR four files and to
#     neither shared original, and cps2 to the originals and to none of ours.
#     A gate that proves an unreachable module is worth nothing.
#
# MUST-FIRE CONTROLS (four, all perturbations of the REAL module sources into
# a temp dir; the originals are never touched):
#   A. the bank latch with the gate BYPASSED (`wide_en ?` -> always the wide
#      arm) must FAIL the wide_en-low leg;
#   B. the profile decoder pointed at byte 40 instead of 41 — the off-by-one
#      that would silently collide with jtframe's JOY_BYTE — must FAIL;
#   C. the profile decoder with the polarity FLIPPED must FAIL, because a
#      0xFF-filled stock header would then turn the profile on;
#   D. a perturbed copy of an overridden file must FAIL the frozen delta.
#
# CHECK 3g EXISTS BECAUSE OF A REAL FAILURE. `cores/cps2w/hdl` shipped without
# `pal_lut.hex` and the core rendered a BLACK SCREEN — and, through the
# Verilator harness's per-changed-frame `fork()`, that moved the simulated
# match-start anchor by 107 frames and turned test_mister_sim_anchor RED.
# `*.hex` is gitignored in jtcores, so nothing warned.
# (ROOT-CAUSED 14z-107 (7): the fork's child called `exit(0)`, which
# `fclose()`d the inherited `FILE*` behind the parent's `sim_inputs.hex`
# stream and rewound the SHARED offset — so the simulated CONTROLLER was
# replayed once per fork, and the number of forks follows the picture. Fixed
# by fork commits 8 and 9. This check stands on its own merits regardless:
# a core that renders black is a broken core.) See docs/platform/gotchas.md.
#
# Usage: tests/test_mister_wide_gate.sh     (no ROMs; Verilator optional)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
SRC="$REPO/emu/jtcores"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }
note(){ echo "  note: $1"; }

[ -f "$SRC/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }
HDL="$SRC/cores/cps2w/hdl"
TOML="$SRC/cores/cps2w/cfg/mame2mra.toml"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# ── 1. the frozen RTL delta ────────────────────────────────────────────────
# PYTHON's difflib, not the system `diff`, ON PURPOSE: two diff
# implementations may emit different-but-equally-minimal edit scripts, and a
# frozen expectation compared with the platform's `diff` would red on CI while
# staying green on the machine that wrote it. difflib is the same everywhere
# python3 is.
delta() {   # delta <original> <override>
    python3 - "$1" "$2" <<'PYD'
import difflib, sys
a = open(sys.argv[1]).read().splitlines(True)
b = open(sys.argv[2]).read().splitlines(True)
for line in difflib.unified_diff(a, b, n=0):
    if line[:3] in ("---", "+++"):
        continue
    if line[:1] in "+-":
        sys.stdout.write(line if line.endswith("\n") else line + "\n")
PYD
}
{
    echo "# FROZEN RTL DELTA — cores/cps2w/hdl vs the SHARED files it overrides."
    echo "# Regenerate deliberately; tests/test_mister_wide_gate.sh compares against it."
    echo "=== jtcps2_game.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps2/hdl/jtcps2_game.v"    "$HDL/jtcps2_game.v"
    echo "=== jtcps15_sound.v : cores/cps15/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps15/hdl/jtcps15_sound.v" "$HDL/jtcps15_sound.v"
} > "$W/delta.txt"
if cmp -s "$W/delta.txt" "$REPO/tests/expect/cps2w_rtl_delta.txt"; then
    ok "1 the RTL override delta is the frozen one ($(grep -c '^[+-]' "$W/delta.txt") changed lines)"
else
    bad "1 the RTL override delta MOVED:"
    diff "$REPO/tests/expect/cps2w_rtl_delta.txt" "$W/delta.txt" | head -30 | sed 's/^/       /'
fi
# control D: rebuild the SAME frozen-delta document with one override file
# perturbed by a single width, and it must stop matching. Without this, check 1
# could be comparing a document to itself in every way that matters.
sed 's/wire \[23:0\] qsnd_addr;/wire [22:0] qsnd_addr;/' "$HDL/jtcps2_game.v" > "$W/perturbed.v"
if cmp -s "$HDL/jtcps2_game.v" "$W/perturbed.v"; then
    bad "1D control could not perturb the file"
else
    {
        head -2 "$REPO/tests/expect/cps2w_rtl_delta.txt"
        echo "=== jtcps2_game.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps2/hdl/jtcps2_game.v"    "$W/perturbed.v"
        echo "=== jtcps15_sound.v : cores/cps15/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps15/hdl/jtcps15_sound.v" "$HDL/jtcps15_sound.v"
    } > "$W/delta_ctlD.txt"
    cmp -s "$W/delta_ctlD.txt" "$REPO/tests/expect/cps2w_rtl_delta.txt" \
        && bad "1D control did NOT fire: a one-width perturbation still matched the frozen delta" \
        || ok "1D control fired (a perturbed override breaks the frozen delta)"
fi

# ── 2. the profile byte agrees in all three copies ─────────────────────────
row="$(grep -n 'setname="vsavjw".*offset=41' "$TOML" | sed 's/^[0-9]*: *//')"
case "$row" in
    *'offset=41'*'data="fe"'*) ok "2a the MRA writes header byte 41 = 0xFE for setname=vsavjw" ;;
    *) bad "2a the fork's TOML has no { setname=\"vsavjw\", offset=41, data=\"fe\" } row: [$row]" ;;
esac
grep -q "^fill=0xff" "$TOML" \
    && ok "2b the header is 0xFF-filled — which is WHY the bit is active low" \
    || bad "2b [header] fill is no longer 0xff; the active-low polarity assumes it"
grep -q "PROFILE_BYTE = 6'd41" "$HDL/jtcps2w_profile.v" \
    && ok "2c the RTL decodes header byte 41" \
    || bad "2c jtcps2w_profile.v does not decode byte 41"
grep -q "assign wide_en = ~profile\[0\];" "$HDL/jtcps2w_profile.v" \
    && ok "2d the RTL polarity is ACTIVE LOW (~profile[0])" \
    || bad "2d jtcps2w_profile.v polarity is not ~profile[0] — a 0xFF-filled stock header would arm the profile"
# byte 41 must not be one jtcps1_prom_we consumes: 0-7 starts, 8-39 is_cps,
# 40 JOY_BYTE, 44-63 the CPS-2 key. 41-43 fall through every branch.
grep -q "JOY_BYTE      = 6'h28" "$SRC/cores/cps1/hdl/jtcps1_prom_we.v" \
    && ok "2e jtcps1_prom_we still uses byte 40 for joymode, so 41 is still free" \
    || bad "2e jtcps1_prom_we's JOY_BYTE moved — re-check that byte 41 is unused"

# ── 3. the widths, and the PCM_AW correction ───────────────────────────────
grep -q "output     \[23:0\] qsnd_addr" "$HDL/jtcps15_sound.v" \
    && ok "3a jtcps15_sound exports a 24-bit qsnd_addr" || bad "3a qsnd_addr is not [23:0]"
grep -q "wire \[23:0\] qsnd_addr;" "$HDL/jtcps2_game.v" \
    && ok "3b the game top carries a 24-bit qsnd_addr" || bad "3b the game top's qsnd_addr is not [23:0]"
grep -q "\.pcm_addr    ( qsnd_addr\[22:0\] )" "$HDL/jtcps2_game.v" \
    && ok "3c the PCM slot is fed qsnd_addr[22:0] (bit 23 is slice D2's)" \
    || bad "3c the PCM slot connection changed"
# THE MEASURED CORRECTION. cps2_wide.md and mister.md both said the fix was
# "PCM_AW 23 -> 24". It is not, and the failure is a BUILD failure:
# jtframe_romrq_bcache.v:74 is `{SDRAMW-AW{1'b0}}`, a replication of -1 once
# AW exceeds SDRAMW=23, which Verilator rejects outright. Nothing in this core
# may set it.
code() { sed 's,//.*,,' "$1" | sed 's,/\*.*\*/,,'; }   # comments are prose, not RTL
code "$HDL/jtcps2_game.v" | grep -q "PCM_AW" \
    && bad "3d the game top overrides PCM_AW — jtframe's 8-bit slot cannot exceed SDRAMW=23 (jtframe_romrq_bcache.v:74)" \
    || ok "3d PCM_AW is NOT widened (the 8-bit slot caps at SDRAMW; see the header)"
grep -q "{SDRAMW-AW{1'b0}}" "$SRC/modules/jtframe/hdl/sdram/jtframe_romrq_bcache.v" \
    && ok "3e ...and jtframe still carries the expression that makes it so" \
    || bad "3e jtframe_romrq_bcache.v:74 changed — re-measure whether PCM_AW can grow"
# exactly one writer of the bank bits
n="$(code "$HDL/jtcps15_sound.v" | grep -c "qsnd_addr\[")"
[ "$n" = "0" ] && ok "3f nothing in jtcps15_sound writes qsnd_addr bit-slices any more" \
               || bad "3f jtcps15_sound still has $n qsnd_addr[...] reference(s) beside the two-half assign"

# ── 3g. THE NON-VERILOG ASSETS A CORE MUST CARRY ───────────────────────────
# PAID FOR IN 14z-107 (6), AND IT COST FOUR 50-MINUTE SIMULATION RUNS.
# `cores/cps2w/hdl` was missing `pal_lut.hex`, the palette brightness LUT.
# Every core that instantiates `jtcps1_pal` carries its own copy — cps1, cps15
# and cps2 all do — because `jtframe_ram` resolves `SYNFILE` by BARE NAME and
# `jtsim` symlinks `$CORES/<core>/hdl/*.hex` into the sim directory. Without
# it `$readmemh` fails with a warning nobody reads, the LUT reads back zero,
# and red/green/blue are pinned to 0: THE CORE RENDERS A BLACK SCREEN.
# `*.hex` is in jtcores' own .gitignore, so a new core loses it SILENTLY.
# The rule is general, so the check is general: every non-Verilog asset the
# reference cores carry in hdl/ must exist in cps2w's and be byte-identical.
miss=""
for src in "$SRC/cores/cps2/hdl" "$SRC/cores/cps15/hdl"; do
    for a in "$src"/*.hex; do
        [ -e "$a" ] || continue
        b="$HDL/$(basename "$a")"
        if [ ! -f "$b" ]; then miss="$miss $(basename "$a"):absent"
        elif ! cmp -s "$a" "$b"; then miss="$miss $(basename "$a"):differs"; fi
    done
done
[ -z "$miss" ] && ok "3g cps2w carries every hdl/*.hex the reference cores do, byte-identical" \
               || bad "3g cores/cps2w/hdl is missing or differs on:$miss — a missing pal_lut.hex renders a BLACK SCREEN and moves the sim anchor"

# ── 4. the bank bit is dsp_ab[7] — the reference, pinned ───────────────────
QS="$REPO/emu/mame/src/devices/sound/qsound.cpp"
if [ -f "$QS" ]; then
    a=0
    grep -q 'map(0x0000, 0x7fff).mirror(0x8000).r(FUNC(qsound_device::dsp_sample_r));' "$QS" || a=1
    grep -q 'm_rom_bank = (m_rom_bank & 0x8000U) | offset;' "$QS" || a=1
    grep -q 'read_byte((u32(m_rom_bank) << 16) | m_rom_offset)' "$QS" || a=1
    [ "$a" = 0 ] && ok "4 MAME's LLE QSound still says the bank is a STRAIGHT ab[14:0] (so bit 7 is dsp_ab[7])" \
                 || bad "4 MAME's qsound.cpp no longer carries the three lines the width fix rests on — RE-VALIDATE the bank bit"
else
    note "4 emu/mame not present; the bank-bit reference could not be re-read"
fi

# ── 5. reachability: the file list resolves to OUR copies ──────────────────
JTF=""
for c in "$SRC/modules/jtframe/src/jtframe/jtframe" \
         "${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}/modules/jtframe/src/jtframe/jtframe"; do
    [ -x "$c" ] && { JTF="$c"; break; }
done
if [ -n "$JTF" ]; then
    JTROOT="$SRC"; JTFRAME="$SRC/modules/jtframe"; CORES="$SRC/cores"
    ROM="$SRC/rom"; MODULES="$SRC/modules"; JTBIN="$SRC/release"
    export JTROOT JTFRAME CORES ROM MODULES JTBIN
    for core in cps2 cps2w; do
        ( cd "$W" && rm -f game.f && "$JTF" files sim "$core" -t mister >/dev/null 2>&1 )
        sed "s|$SRC/||" "$W/game.f" > "$W/list_$core.txt" 2>/dev/null
    done
    want_own="cores/cps2w/hdl/jtcps15_sound.v cores/cps2w/hdl/jtcps2_game.v cores/cps2w/hdl/jtcps2w_profile.v cores/cps2w/hdl/jtcps2w_qsnd_bank.v"
    a=0
    for f in $want_own; do grep -qx "$f" "$W/list_cps2w.txt" || a=1; done
    grep -qx "cores/cps2/hdl/jtcps2_game.v"    "$W/list_cps2w.txt" && a=2
    grep -qx "cores/cps15/hdl/jtcps15_sound.v" "$W/list_cps2w.txt" && a=2
    case "$a" in
        0) ok "5a cps2w compiles OUR four files and NEITHER shared original" ;;
        1) bad "5a cps2w does not compile all four override files" ;;
        2) bad "5a cps2w compiles a shared original TOO — duplicate module, and the override is not overriding" ;;
    esac
    b=0
    grep -qx "cores/cps2/hdl/jtcps2_game.v"    "$W/list_cps2.txt" || b=1
    grep -qx "cores/cps15/hdl/jtcps15_sound.v" "$W/list_cps2.txt" || b=1
    grep -q  "cores/cps2w/"                    "$W/list_cps2.txt" && b=2
    case "$b" in
        0) ok "5b the reference core cps2 still compiles the originals and none of ours" ;;
        1) bad "5b cps2 lost one of its own files" ;;
        2) bad "5b cps2 pulled a cps2w file — the profile leaked into the reference core" ;;
    esac
    d="$(diff "$W/list_cps2.txt" "$W/list_cps2w.txt" | grep -c '^[<>]')"
    [ "$d" = "6" ] && ok "5c the two cores' file lists differ in exactly 6 entries (2 out, 4 in)" \
                   || bad "5c the file lists differ in $d entries, expected 6"
else
    note "5 no built jtframe tool (tools/setup_jtcores.sh); reachability not checked"
fi

# ── 6. the gated modules, simulated ────────────────────────────────────────
if command -v verilator >/dev/null 2>&1; then
    run_tb() {   # run_tb <name> <tb.v> <dut.v> <expect pass|fail>
        _n="$1"; _tb="$2"; _dut="$3"; _want="$4"
        if ! ( cd "$W" && verilator --binary --timing -Wno-fatal -Wno-TIMESCALEMOD \
               --top-module "$(basename "$_tb" .v)" -Mdir "obj_$_n" -o "$_n" \
               "$_tb" "$_dut" >"$W/$_n.build" 2>&1 ); then
            bad "6 $_n: Verilator build failed"; tail -5 "$W/$_n.build" | sed 's/^/       /'; return
        fi
        "$W/obj_$_n/$_n" > "$W/$_n.out" 2>&1
        _got=fail; grep -q "^PASS " "$W/$_n.out" && _got=pass
        if [ "$_got" = "$_want" ]; then
            if [ "$_want" = pass ]; then
                ok "6 $_n: $(grep -E '^(checked|PASS)' "$W/$_n.out" | tr '\n' ' ')"
            else
                ok "6 $_n control fired: $(grep -m1 '^FAIL' "$W/$_n.out")"
            fi
        else
            bad "6 $_n: expected $_want, got $_got"
            grep -m4 '^FAIL' "$W/$_n.out" | sed 's/^/       /'
        fi
    }
    run_tb bank    "$REPO/tests/rtl/tb_qsnd_bank.v" "$HDL/jtcps2w_qsnd_bank.v" pass
    run_tb profile "$REPO/tests/rtl/tb_profile.v"   "$HDL/jtcps2w_profile.v"   pass
    # control A: bypass the gate
    sed "s/bank <= wide_en ? dsp_ab\[7:0\]/bank <= 1'b1 ? dsp_ab[7:0]/" \
        "$HDL/jtcps2w_qsnd_bank.v" > "$W/ctlA.v"
    cmp -s "$HDL/jtcps2w_qsnd_bank.v" "$W/ctlA.v" \
        && bad "6A control could not perturb the gate" \
        || run_tb ctlA "$REPO/tests/rtl/tb_qsnd_bank.v" "$W/ctlA.v" fail
    # control B: the byte-40 off-by-one (jtframe's JOY_BYTE)
    sed "s/PROFILE_BYTE = 6'd41/PROFILE_BYTE = 6'd40/" "$HDL/jtcps2w_profile.v" > "$W/ctlB.v"
    cmp -s "$HDL/jtcps2w_profile.v" "$W/ctlB.v" \
        && bad "6B control could not move the profile byte" \
        || run_tb ctlB "$REPO/tests/rtl/tb_profile.v" "$W/ctlB.v" fail
    # control C: the polarity flip — the superset-invariant failure
    sed "s/assign wide_en = ~profile\[0\];/assign wide_en = profile[0];/" \
        "$HDL/jtcps2w_profile.v" > "$W/ctlC.v"
    cmp -s "$HDL/jtcps2w_profile.v" "$W/ctlC.v" \
        && bad "6C control could not flip the polarity" \
        || run_tb ctlC "$REPO/tests/rtl/tb_profile.v" "$W/ctlC.v" fail
else
    note "6 verilator not installed; the gated modules were not simulated"
fi

[ $fail = 0 ] && echo "PASS test_mister_wide_gate" \
              || { echo "FAIL test_mister_wide_gate"; exit 1; }
