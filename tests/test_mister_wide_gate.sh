#!/bin/sh
# test_mister_wide_gate.sh — THE CPS-2 WIDE RUNTIME PROFILE GATE, on MiSTer.
# 14z-107 (6), slice D1; EXTENDED 14z-107 (9) for slice D2. ROM-free; seconds
# without Verilator, ~30 s with it.
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
#  3. PROFILE-GATED — the THREE gated modules are SIMULATED, exhaustively:
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
#     * jtcps2w_obj_bank (slice D3) over ALL 65,536 y-words in both profile
#       states: with wide_en low bank[2] is STUCK AT ZERO and bank[1:0] is the
#       stock expression; with it high bank[2] == y[12] and DOES move; and the
#       six y-words tools/gfx_tiles.py emits for banks 0-5 each decode to
#       their own bank, none of them setting y bit 15 — the sprite-list
#       TERMINATOR, which is the trap the promote exists to avoid.
#  4. REACHABLE — `jtframe files` must resolve cps2w to OUR files and to none
#     of the shared originals, and cps2 to the originals and to none of ours.
#     A gate that proves an unreachable module is worth nothing.
#  5. AND SINCE SLICE D2, DECLARATIVE ABOUT PLACEMENT (section 7 below). The
#     SDRAM map exists in TWO places — docs/project/mister_map.md section 5 and
#     the localparams in cores/cps2w/hdl/jtcps1_sdram.v — and a disagreement
#     between them is invisible until a bring-up. Every offset the map names is
#     re-read from the RTL here, in BYTES, and compared against the frozen
#     table. The live end-to-end proof that the download honours them is
#     tests/test_mister_sdram_census.sh; this is the cheap static twin of it.
#
# MUST-FIRE CONTROLS (four, all perturbations of the REAL module sources into
# a temp dir; the originals are never touched):
#   A. the bank latch with the gate BYPASSED (`wide_en ?` -> always the wide
#      arm) must FAIL the wide_en-low leg;
#   B. the profile decoder pointed at byte 40 instead of 41 — the off-by-one
#      that would silently collide with jtframe's JOY_BYTE — must FAIL;
#   C. the profile decoder with the polarity FLIPPED must FAIL, because a
#      0xFF-filled stock header would then turn the profile on;
#   D. a perturbed copy of an overridden file must FAIL the frozen delta;
#   E. (D3) the obj promote with the gate BYPASSED must FAIL the wide_en-low
#      leg — the superset-invariant failure;
#   F. (D3) the obj promote reading bank bit 2 from y[15] instead of y[12] —
#      the profile's FIRST DRAFT, which would end the sprite list at the first
#      tenant sprite — must FAIL the encoding contract.
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
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~30 s with Verilator, seconds without)) SLICE D1, the
#   RTL trust surface. The frozen line-by-line delta of the two OVERRIDDEN
#   files vs the shared originals (`tests/expect/cps2w_rtl_delta.txt`); the
#   profile byte agreeing in all three copies (TOML `offset=41 data="fe"`, RTL
#   `PROFILE_BYTE=6'd41`, `~profile[0]`) plus the `fill=0xff` and `JOY_BYTE`
#   facts the polarity rests on; the widths, and that `PCM_AW` is NOT widened
#   (it cannot be — `jtframe_romrq_bcache.v:74`); MAME's three qsound.cpp
#   lines that validate `dsp_ab[7]`; and `jtframe files` resolving cps2w to
#   OUR nine overrides + three new modules + the new jtframe slot module, and
#   cps2 to NONE of ours (the two lists differ in exactly 22 entries). Then
#   Verilator: `jtcps2w_qsnd_bank` over all 65,536 `dsp_ab` values in both
#   profile states (bank[7] stuck at 0 with `wide_en` low, moving 16,384 times
#   with it high) and `jtcps2w_profile` over a real 64-byte header stream.
#   FOUR must-fire controls: gate bypassed; profile byte moved to 40; polarity
#   flipped; an override perturbed by one width. EXTENDED AT D2 (section 7):
#   every SDRAM placement constant re-read from `jtcps1_sdram.v` in BYTES and
#   compared against `mister_map.md` §5 (VRAM `0x600000`, ORAM `0x640000`,
#   WRAM `0x648000`, Z80 `0x658000`, PCM-high `0x6E0000`, group-C obj bank 5
#   `0x7E0000`, obj bank 4 bank-1 `0x800000`); all four `wide_en` conjunctions
#   re-read verbatim; the CPS1 arm of the re-pack still the reference values;
#   and `jtframe_ram1_7slots` NOT in jtframe's shared `jtframe_sdram64.yaml`.
#   EXTENDED AGAIN AT D3+D4 (section 8): a third Verilator bench,
#   `jtcps2w_obj_bank` over all 65,536 y-words in both profile states (bank[2]
#   stuck at 0 with `wide_en` low, set 32,768 times with it high) which also
#   transcribes `tools/gfx_tiles.py`'s `bank_word` table and requires each of
#   the six encodings to decode to its own bank with none of them setting y
#   bit 15 — the sprite-list TERMINATOR; the sprite-list terminator test in
#   the override asserted IDENTICAL to the reference core's AND at an earlier
#   line than the promote; the 3-bit bank asserted at all six ports between
#   the frame table and SDRAM; `rom0_bank[2]` now UNTIED; and D4's `wide_en &
#   RnW` read decode, 22-bit `rom_addr`/`main_rom_addr`/`SLOT3_AW`, the `4'h6`
#   wait-state boundary and the surviving `!RnW` on `objcfg_cs`. TWO more
#   must-fire controls: the promote's gate bypassed, and the promote reading
#   `y[15]` instead of `y[12]` — the profile's first draft
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
    echo "=== jtcps1_sdram.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps1/hdl/jtcps1_sdram.v"   "$HDL/jtcps1_sdram.v"
    echo "=== jtcps1_prom_we.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps1/hdl/jtcps1_prom_we.v" "$HDL/jtcps1_prom_we.v"
    echo "=== jtcps2_obj_scan.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps2/hdl/jtcps2_obj_scan.v" "$HDL/jtcps2_obj_scan.v"
    echo "=== jtcps2_obj.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps2/hdl/jtcps2_obj.v"      "$HDL/jtcps2_obj.v"
    echo "=== jtcps1_obj_draw.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps1/hdl/jtcps1_obj_draw.v" "$HDL/jtcps1_obj_draw.v"
    echo "=== jtcps1_video.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps1/hdl/jtcps1_video.v"    "$HDL/jtcps1_video.v"
    echo "=== jtcps2_main.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps2/hdl/jtcps2_main.v"     "$HDL/jtcps2_main.v"
    echo "=== jtcps2_decrypt.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
    delta "$SRC/cores/cps2/hdl/jtcps2_decrypt.v"  "$HDL/jtcps2_decrypt.v"
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
        echo "=== jtcps1_sdram.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps1/hdl/jtcps1_sdram.v"   "$HDL/jtcps1_sdram.v"
        echo "=== jtcps1_prom_we.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps1/hdl/jtcps1_prom_we.v" "$HDL/jtcps1_prom_we.v"
        echo "=== jtcps2_obj_scan.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps2/hdl/jtcps2_obj_scan.v" "$HDL/jtcps2_obj_scan.v"
        echo "=== jtcps2_obj.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps2/hdl/jtcps2_obj.v"      "$HDL/jtcps2_obj.v"
        echo "=== jtcps1_obj_draw.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps1/hdl/jtcps1_obj_draw.v" "$HDL/jtcps1_obj_draw.v"
        echo "=== jtcps1_video.v : cores/cps1/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps1/hdl/jtcps1_video.v"    "$HDL/jtcps1_video.v"
        echo "=== jtcps2_main.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps2/hdl/jtcps2_main.v"     "$HDL/jtcps2_main.v"
        echo "=== jtcps2_decrypt.v : cores/cps2/hdl -> cores/cps2w/hdl ==="
        delta "$SRC/cores/cps2/hdl/jtcps2_decrypt.v"  "$HDL/jtcps2_decrypt.v"
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
# CHANGED AT D2 AND THAT IS THE POINT. D1 fed the slot qsnd_addr[22:0] and
# left bit 23 produced-but-unrouted; D2 hands jtcps1_sdram the FULL 24 bits and
# the split on bit 23 happens there (checks 7i/7l below).
grep -q "\.pcm_addr    ( qsnd_addr     )" "$HDL/jtcps2_game.v" \
    && ok "3c the game top hands jtcps1_sdram the full 24-bit qsnd_addr (D2 splits on bit 23)" \
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
    want_own="cores/cps2w/hdl/jtcps15_sound.v cores/cps2w/hdl/jtcps2_game.v cores/cps2w/hdl/jtcps1_sdram.v cores/cps2w/hdl/jtcps1_prom_we.v cores/cps2w/hdl/jtcps2_obj_scan.v cores/cps2w/hdl/jtcps2_obj.v cores/cps2w/hdl/jtcps1_obj_draw.v cores/cps2w/hdl/jtcps1_video.v cores/cps2w/hdl/jtcps2_main.v cores/cps2w/hdl/jtcps2w_profile.v cores/cps2w/hdl/jtcps2w_qsnd_bank.v cores/cps2w/hdl/jtcps2w_obj_bank.v modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v"
    shared_orig="cores/cps2/hdl/jtcps2_game.v cores/cps15/hdl/jtcps15_sound.v cores/cps1/hdl/jtcps1_sdram.v cores/cps1/hdl/jtcps1_prom_we.v cores/cps2/hdl/jtcps2_obj_scan.v cores/cps2/hdl/jtcps2_obj.v cores/cps1/hdl/jtcps1_obj_draw.v cores/cps1/hdl/jtcps1_video.v cores/cps2/hdl/jtcps2_main.v"
    a=0
    for f in $want_own; do grep -qx "$f" "$W/list_cps2w.txt" || a=1; done
    for f in $shared_orig; do grep -qx "$f" "$W/list_cps2w.txt" && a=2; done
    case "$a" in
        0) ok "5a cps2w compiles OUR ten overrides, its three new modules and the new jtframe slot module, and NONE of the ten shared originals" ;;
        1) bad "5a cps2w does not compile all thirteen of its own files" ;;
        2) bad "5a cps2w compiles a shared original TOO — duplicate module, and the override is not overriding" ;;
    esac
    b=0
    for f in $shared_orig; do grep -qx "$f" "$W/list_cps2.txt" || b=1; done
    grep -q  "cores/cps2w/"                 "$W/list_cps2.txt" && b=2
    grep -q  "jtframe_ram1_7slots"          "$W/list_cps2.txt" && b=3
    case "$b" in
        0) ok "5b the reference core cps2 still compiles the originals, none of ours, and NOT the new jtframe module" ;;
        1) bad "5b cps2 lost one of its own files" ;;
        2) bad "5b cps2 pulled a cps2w file — the profile leaked into the reference core" ;;
        3) bad "5b cps2 pulled jtframe_ram1_7slots — the new module was added to a SHARED jtframe yaml" ;;
    esac
    d="$(diff "$W/list_cps2.txt" "$W/list_cps2w.txt" | grep -c '^[<>]')"
    [ "$d" = "24" ] && ok "5c the two cores' file lists differ in exactly 24 entries (10 out, 14 in)" \
                    || bad "5c the file lists differ in $d entries, expected 24"
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
    run_tb objbank "$REPO/tests/rtl/tb_obj_bank.v"  "$HDL/jtcps2w_obj_bank.v"  pass
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
    # control E (D3): the promote with the gate bypassed — the same
    # superset-invariant failure, in the object path
    sed "s/{ wide_en & table_y\[12\], table_y\[14:13\] }/{ table_y[12], table_y[14:13] }/" \
        "$HDL/jtcps2w_obj_bank.v" > "$W/ctlE.v"
    cmp -s "$HDL/jtcps2w_obj_bank.v" "$W/ctlE.v" \
        && bad "6E control could not bypass the promote's gate" \
        || run_tb ctlE "$REPO/tests/rtl/tb_obj_bank.v" "$W/ctlE.v" fail
    # control F (D3): THE FIRST DRAFT. Reading bank bit 2 from y[15] rather
    # than promoting y[12] is the mistake Correction A2 exists to record: y[15]
    # is the sprite-list terminator, so bank 4 would end the list at the first
    # tenant sprite. It must break the encoding contract with gfx_tiles.py.
    sed "s/{ wide_en & table_y\[12\], table_y\[14:13\] }/{ wide_en \& table_y[15], table_y[14:13] }/" \
        "$HDL/jtcps2w_obj_bank.v" > "$W/ctlF.v"
    cmp -s "$HDL/jtcps2w_obj_bank.v" "$W/ctlF.v" \
        && bad "6F control could not move the promoted bit to y[15]" \
        || run_tb ctlF "$REPO/tests/rtl/tb_obj_bank.v" "$W/ctlF.v" fail
else
    note "6 verilator not installed; the gated modules were not simulated"
fi

# ── 7. THE PLACEMENT MAP, IN THE RTL AND IN THE DOCUMENT (slice D2) ────────
# The map lives in two places and they must not drift. The RTL constants are
# 23-bit WORD offsets; the map's tables are in BYTES, so the check converts and
# compares in bytes — which is also how a reader of either document sees them.
# A missing constant fails as loudly as a wrong one.
SD="$HDL/jtcps1_sdram.v"
want_off() {   # want_off <NAME> <byte offset> <what it is>
    # two shapes: a plain `NAME = 23'hXX` and the re-pack's
    # `NAME = CPS==2 ? 23'hWIDE : 23'hREFERENCE` (the CPS-2 arm is ours)
    _v="$(sed -n "s/.*$1 *= *CPS==2 ? 23'h\([0-9A-Fa-f_]*\).*/\1/p" "$SD" | head -1 | tr -d '_')"
    [ -n "$_v" ] || _v="$(sed -n "s/.*$1 *= *23'h\([0-9A-Fa-f_]*\).*/\1/p" "$SD" | head -1 | tr -d '_')"
    if [ -z "$_v" ]; then bad "7 $1 is not defined in cores/cps2w/hdl/jtcps1_sdram.v"; return; fi
    _b=$(( 0x$_v * 2 ))
    if [ "$_b" = "$2" ]; then
        ok "7 $1 = 23'h$_v = byte $(printf '%#08x' "$2") — $3"
    else
        bad "7 $1 = 23'h$_v = byte $(printf '%#x' "$_b"), the map says $(printf '%#x' "$2") — $3"
    fi
}
want_off VRAM_OFFSET  $((0x600000)) "VRAM, above the 6 MB PRG region"
want_off ORAM_OFFSET  $((0x640000)) "OBJ RAM"
want_off WRAM_OFFSET  $((0x648000)) "68k work RAM (RAM:\$FF0000)"
want_off SND_OFFSET   $((0x658000)) "Z80 program"
want_off PCMH_OFFSET  $((0x6E0000)) "QSound DSP sample banks 0x80+, 1 MB window"
want_off GFXC5_OFFSET $((0x7E0000)) "GFX group C obj bank 5, bank 0"
want_off GFXC4_OFFSET $((0x400000 * 2)) "GFX group C obj bank 4, bank 1 byte 0x800000"
# the CPS1 column of the re-pack must still be the reference values, or a CPS1
# build of this copy would silently re-place
grep -q "VRAM_OFFSET  = CPS==2 ? 23'h30_0000 : 23'h20_0000" "$SD" \
    && ok "7h the re-pack is CPS==2 only; a CPS1 build keeps the reference offsets" \
    || bad "7h the CPS1 arm of the bank-0 re-pack is gone — a CPS1 build would silently re-place"
# the two behavioural selects must both be ANDed with wide_en
grep -q "assign pcmh_sel    = wide_en & pcm_addr\[PCM_AW\];" "$SD" \
    && ok "7i the QSound read split is gated (wide_en & pcm_addr[PCM_AW])" \
    || bad "7i the QSound read split is not gated on wide_en"
grep -q "assign gfxc_sel  = wide_en & rom0_bank\[2\];" "$SD" \
    && ok "7j the group-C read select is gated (wide_en & rom0_bank[2])" \
    || bad "7j the group-C read select is not gated on wide_en"
PW="$HDL/jtcps1_prom_we.v"
grep -q "wire is_gfxc  = wide_en & gfx_addr\[25\];" "$PW" \
    && ok "7k the download-side group-C redirect is gated (wide_en & gfx_addr[25])" \
    || bad "7k the download-side group-C redirect is not gated on wide_en"
grep -q "wire is_pcmhi = wide_en & pcm_addr\[23\];" "$PW" \
    && ok "7l the download-side QSound split is gated (wide_en & pcm_addr[23])" \
    || bad "7l the download-side QSound split is not gated on wide_en"
# 7m WAS "rom0_bank[2] is still tied low" until slice D3. D2 built the
# destination and deliberately left it unreachable; D3 DRIVES it, so the check
# inverts: the tie must be GONE and the bank must be the object engine's.
code "$HDL/jtcps2_game.v" | grep -q "rom0_bank_sdram" \
    && bad "7m the game top still ties rom0_bank[2] low — slice D3 unties it" \
    || ok "7m the D2 tie on rom0_bank[2] is gone (slice D3 drives it)"
grep -q "wire \[ 2:0\] rom0_bank;" "$HDL/jtcps2_game.v" \
    && ok "7m2 the game top's rom0_bank is the object engine's 3-bit bank" \
    || bad "7m2 the game top's rom0_bank is not 3 bits"
# and the new slot module must be an ADDITION, never a change to a shared list
grep -q "jtframe_ram1_7slots" "$SRC/modules/jtframe/hdl/sdram/jtframe_sdram64.yaml" \
    && bad "7n jtframe_ram1_7slots was added to the SHARED jtframe_sdram64.yaml — every core would compile it" \
    || ok "7n jtframe_ram1_7slots is pulled by cores/cps2w alone, not by a shared jtframe yaml"

# ── 8. THE D3 PROMOTE AND THE D4 PROGRAM WINDOW, re-read in the RTL ────────
# Section 6 proves the promote's EXPRESSION exhaustively; this proves the
# expression is the one the object scanner actually uses, and that the chain
# from it to SDRAM is three bits wide the whole way. A width that stayed at 2
# anywhere in between would silently drop bank bit 2 and the core would fetch
# vanilla art for every tenant sprite — a picture bug, not a build error.
OS="$HDL/jtcps2_obj_scan.v"
grep -q "st3_bank <= promoted_bank;" "$OS" \
    && ok "8a the obj scanner takes its bank from jtcps2w_obj_bank" \
    || bad "8a jtcps2_obj_scan does not use the gated promote module"
# THE ORDER IS THE WHOLE RULE. The promote may only be read AFTER the
# sprite-list terminator test, and that test must be UNCHANGED from the
# reference core — if it moved, bit 15 could be consumed as a bank bit and the
# list would end at the first tenant sprite (cps2_wide.md Correction A2).
term="if( table_y\[15\] || table_attr\[15:8\]==8'hff || &table_addr ) begin"
if grep -q "$term" "$OS" && grep -q "$term" "$SRC/cores/cps2/hdl/jtcps2_obj_scan.v"; then
    a="$(grep -n "$term" "$OS" | cut -d: -f1)"
    b="$(grep -n "st3_bank <= promoted_bank;" "$OS" | cut -d: -f1)"
    [ "$b" -gt "$a" ] \
        && ok "8b the terminator test is the reference core's, VERBATIM, and the promote is read after it (line $a < $b)" \
        || bad "8b the promote is read at line $b, BEFORE the terminator test at $a"
else
    bad "8b the sprite-list terminator test is not the reference core's — bit 15 must stay the terminator"
fi
for pair in "jtcps2_obj_scan.v:output reg \[ 2:0\]  dr_bank" \
            "jtcps2_obj.v:output     \[ 2:0\]  rom_bank," \
            "jtcps2_obj.v:wire \[ 2:0\] dr_bank;" \
            "jtcps1_obj_draw.v:input      \[ 2:0\]  obj_bank," \
            "jtcps1_obj_draw.v:output reg \[ 2:0\]  rom_bank," \
            "jtcps1_video.v:output     \[ 2:0\]  rom0_bank,"; do
    f="${pair%%:*}"; pat="${pair#*:}"
    grep -q "$pat" "$HDL/$f" \
        && ok "8c $f: $pat" \
        || bad "8c $f does not carry a 3-bit bank ($pat) — bank bit 2 would be dropped here"
done
# wide_en must reach the scanner, or the promote is gated by nothing
grep -q "\.wide_en    ( wide_en       )," "$HDL/jtcps2_obj.v" \
    && ok "8d wide_en reaches the object scanner" || bad "8d wide_en does not reach the object scanner"
grep -q "\.wide_en        ( wide_en       )," "$HDL/jtcps2_game.v" \
    && ok "8e wide_en reaches the video block" || bad "8e wide_en does not reach jtcps1_video"
# --- D4, the program window
MN="$HDL/jtcps2_main.v"
grep -q "(wide_en & RnW & (A\[23:21\] == 3'b010))" "$MN" \
    && ok "8f the 6 MB program decode is gated AND read-only (wide_en & RnW)" \
    || bad "8f jtcps2_main's extended rom_cs is not 'wide_en & RnW & A[23:21]==3'b010'"
grep -q "rom_addr    <= A\[22:1\];" "$MN" \
    && ok "8g rom_addr is 22 bits (8 MB reach, 6 MB loaded)" || bad "8g rom_addr was not widened"
grep -q "A\[23:20\] < (wide_en ? 4'h6 : 4'h5)" "$MN" \
    && ok "8h the wait-state boundary moves with the profile — no zero-wait megabyte inside PRG" \
    || bad "8h one_wait still stops at 4'h5; \$500000-\$5FFFFF would be ZERO-wait while the rest of PRG is one-wait"
grep -q "objcfg_cs   <= ((dec_en && A\[23:20\] == 4'h4) || (!dec_en && A\[23:4\] == ~20'h0)) && !RnW;" "$MN" \
    && ok "8i the objcfg port is still WRITE-ONLY — which is what makes the read decode collision-free" \
    || bad "8i objcfg_cs lost its !RnW qualifier — the 6 MB read decode now COLLIDES with it"
grep -q "wire \[22:1\] main_rom_addr;" "$HDL/jtcps2_game.v" \
    && ok "8j the game top carries a 22-bit main_rom_addr" || bad "8j main_rom_addr is not [22:1]"
grep -q "\.SLOT3_AW    ( CPS==2 ? 22 : 21 )" "$HDL/jtcps1_sdram.v" \
    && ok "8k bank 0's program slot reaches 6 MB on CPS-2 and is unchanged on CPS-1" \
    || bad "8k SLOT3_AW did not follow main_rom_addr — the top address bit would be dropped"

# ── 9. (D5) THE DECRYPTION RANGE ───────────────────────────────────────────
# The CPS-2 key's encrypted-opcode RANGE word is stored COMPLEMENTED. MAME and
# FBNeo read it that way (`~decoded[9] & 0x3ff`); jtcps2_dec_ctrl does not, so
# the reference core decrypts opcode fetches FIFTEEN TIMES further than the
# hardware does — CPU:$000000-$F03FFF instead of $000000-$0FFFFF on vsavj. No
# stock game notices: only Capcom's own encrypted code ever executes, and DATA
# reads are never decrypted either way. CPS-2 WIDE is the first thing to put
# EXECUTABLE content above the window. Measured 14z-107 (11): five opcode
# fetches at CPU:$4BE7C0-$4BE7C8 whose RAW words matched the .rom byte for byte
# and whose LATCHED words were the decryptor's output.
DEC="$HDL/jtcps2_decrypt.v"
if [ ! -f "$DEC" ]; then
    bad "9 no $DEC — slice D5's override is missing"
else
    grep -q 'wire \[15:0\] rng_eff = wide_en ? { addr_rng\[15:10\], ~addr_rng\[9:0\] } : addr_rng;' "$DEC" \
      && ok "9a the range word is complemented ONLY with the profile on (rng_eff)" \
      || bad "9a jtcps2_decrypt's gated range expression is not the frozen one"
    grep -q '\.range     ( rng_eff       ),' "$DEC" \
      && ok "9b jtcps2_dec_ctrl is fed rng_eff, not addr_rng" \
      || bad "9b the decrypt controller is still fed the raw range word"
    grep -q 'input             wide_en,' "$DEC" \
      && ok "9c jtcps2_decrypt takes wide_en" || bad "9c jtcps2_decrypt has no wide_en port"
    grep -q '\.wide_en    ( wide_en   ),' "$HDL/jtcps2_main.v" \
      && ok "9d the game's 68k block routes wide_en into the decryptor" \
      || bad "9d wide_en does not reach u_decrypt"
    # jtcps2_dec_ctrl itself stays a REFERENCE file on purpose: the fix sits
    # one level UPSTREAM of the comparison, so the comparison nobody validated
    # for the rest of the CPS-2 library is left exactly as it was.
    if [ -f "$HDL/jtcps2_dec_ctrl.v" ]; then
        bad "9e cores/cps2w overrides jtcps2_dec_ctrl — the D5 fix is meant to leave it alone"
    else
        ok "9e jtcps2_dec_ctrl is NOT overridden (the fix is one expression upstream of it)"
    fi
    grep -q 'en_latch <= op_fetch && en && (addr\[14+:10\] <= range\[9:0\]);' \
        "$SRC/cores/cps2/hdl/jtcps2_dec_ctrl.v" \
      && ok "9f the reference comparison is still the UNcomplemented one D5 corrects for" \
      || bad "9f cores/cps2/hdl/jtcps2_dec_ctrl.v changed — re-derive D5 before trusting it"
    # 9G MUST-FIRE: strip wide_en from the range fix and the frozen delta must move.
    sed 's/wide_en ? { addr_rng\[15:10\], ~addr_rng\[9:0\] } : addr_rng/{ addr_rng[15:10], ~addr_rng[9:0] }/' \
        "$DEC" > "$W/dec_ungated.v"
    if cmp -s "$DEC" "$W/dec_ungated.v"; then
        bad "9G control could not perturb the gated expression"
    else
        delta "$SRC/cores/cps2/hdl/jtcps2_decrypt.v" "$W/dec_ungated.v" > "$W/dec_ungated.delta"
        delta "$SRC/cores/cps2/hdl/jtcps2_decrypt.v" "$DEC" > "$W/dec_real.delta"
        cmp -s "$W/dec_ungated.delta" "$W/dec_real.delta" \
          && bad "9G control did NOT fire: an UNGATED range fix produced the same delta" \
          || ok "9G control fired (removing wide_en from the range fix changes the frozen delta)"
    fi
fi

[ $fail = 0 ] && echo "PASS test_mister_wide_gate" \
              || { echo "FAIL test_mister_wide_gate"; exit 1; }
