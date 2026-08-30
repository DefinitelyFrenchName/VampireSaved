#!/bin/sh
# test_mister_prg_window.sh — SLICE D4's OWN EVIDENCE: what the 68k does with
# CPU:$400000-$5FFFFF on the core. 14z-107 (11). Emulator tier: ROMDIR +
# Verilator + ~2 x 40 min. NOT ci_portable, NOT ci_static.
#
# THE QUESTION, AND WHY IT IS THREE-WAY. D4 declares a 6 MB program window.
# The SDRAM image census proves the CPS-2 WIDE romset's bytes are PLACED above
# CPU:$400000; nothing proved the 68k could READ them. That gap made the
# strongest elimination in the boot-failure report AMBIGUOUS: "the same .rom
# with the profile bit clear is frame-for-frame identical" reads as "the
# profile is innocent" only if the decode WORKS — a DEAD decode produces the
# same identity for the opposite reason, because with it dead `wide_en` set
# behaves exactly like `wide_en` clear for every read above $400000.
#
#   zero reads   -> the relocation is not implicated, and D4 stays UNPROVEN
#   right bytes  -> D4 works; the sound path is the right hunt
#   wrong bytes  -> D4 IS the bug and the sound divergence is a symptom
#
# THE INSTRUMENT is the sim-only probe in cores/cps2w/hdl/jtcps2_main.v (fork
# commit 16, `JTCPS2W_PRGPROBE`), and it is deliberately two instruments:
#   * THE ADDRESS half classifies every 68k bus cycle by A[23:21] with NO chip
#     select in the condition. That is the half that still speaks on the
#     control leg, where `rom_cs` cannot assert in the window at all — without
#     it a zero could not separate "the CPU never addressed $400000+" from
#     "it did and the decode ignored it".
#   * THE DATA half logs every COMPLETED program-ROM read with the word the
#     CPU LATCHED and the raw SDRAM word behind it.
# Its must-fire control is in the same counters: reads BELOW $400000 are
# counted and sampled, and tools/prgprobe_verdict.py REFUSES a verdict unless
# that control is loud AND its bytes verify against the .rom. It also refuses
# any record that falls outside the window its label claims — the failure the
# probe's first draft shipped with (docs/platform/gotchas.md, 14z-107 (11)).
#
# THE TWO LEGS DIFFER BY ONE BYTE OF ONE FILE, exactly as in
# tests/test_mister_gfxc_fetch.sh: the WIDE `.rom` as emitted (header byte 41
# = 0xFE, CPS-2 WIDE ON) and the SAME bytes with 41 = 0xFF (the generator's
# own fill, CPS-2 WIDE OFF). The control leg is not "another build"; it is the
# profile bit.
#
# WHAT IS FROZEN: tests/expect/mister_prg_window.txt, one line per leg, from
# the probe's own last per-frame report. A count that MOVES is a finding, not
# noise — the simulation is deterministic and the replay is fixed.
#
# Usage:
#   ROMDIR=... [JTSIM_SCRATCH=...] tests/test_mister_prg_window.sh [OUTDIR]
#         [--frames N] [--build DIR] [--rpl FILE]
#         [--pos-log DIR --neg-log DIR]   re-analyse two finished run dirs
#         [--freeze]                      rewrite the frozen expectation
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier manual/emulator (~2 x 40 min)) THE MEASURED PAIR, FROZEN. Runs
#   `11_pick_donovan` on `cps2w` with the WIDE romset twice, on `.rom` images
#   that differ in ONE BYTE (header 41 `0xFE`/`0xFF`), and freezes the probe's
#   own last per-frame report for each leg in
#   `tests/expect/mister_prg_window.txt`. Structural assertions independent of
#   the frozen numbers: `wide_en` really is 1 and 0; the must-fire count below
#   `$400000` is in the tens of millions in BOTH legs; the CONTROL leg
#   completes exactly ZERO reads above `$400000` (the decode is gated by
#   construction); and both legs issue the same number of 68k bus READ cycles
#   into the window. `--pos-log DIR --neg-log DIR` re-analyses finished runs;
#   `--freeze` rewrites the expectation deliberately
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }

RPL="$REPO/tests/replays/11_pick_donovan.rpl"
BUILD="build/m3b_merged21"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
FRAMES=2900
EXPECT="$REPO/tests/expect/mister_prg_window.txt"
OUTDIR=""; POSLOG=""; NEGLOG=""; FREEZE=0
while [ $# -gt 0 ]; do
    case "$1" in
    --frames)  shift; FRAMES="${1:?--frames needs N}" ;;
    --build)   shift; BUILD="${1:?--build needs a dir}" ;;
    --rpl)     shift; RPL="${1:?--rpl needs a file}" ;;
    --pos-log) shift; POSLOG="${1:?--pos-log needs a dir}" ;;
    --neg-log) shift; NEGLOG="${1:?--neg-log needs a dir}" ;;
    --freeze)  FREEZE=1 ;;
    -h|--help) sed -n '2,50p' "$0"; exit 0 ;;
    -*) echo "unknown option '$1'" >&2; exit 2 ;;
    *)  OUTDIR="$1" ;;
    esac
    shift
done

if [ -z "$POSLOG" ] || [ -z "$NEGLOG" ]; then
    [ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this gate runs the real romset)"; exit 77; }
    command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed"; exit 77; }
    [ -d "$REPO/$BUILD" ] || { echo "SKIP: no $BUILD (build the WIDE romset first)"; exit 77; }
    [ -e "$REPO/emu/jtcores/.git" ] || { echo "SKIP: emu/jtcores not initialised"; exit 77; }
    [ -n "$OUTDIR" ] || OUTDIR="$(mktemp -d)"
    mkdir -p "$OUTDIR"
    case "$OUTDIR/" in "$REPO"/*) echo "REFUSING: OUTDIR is inside the repo (rule 7)"; exit 2 ;; esac
    POSLOG="$OUTDIR/pos"; NEGLOG="$OUTDIR/neg"
    SCRATCH="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"
    probe_args="--prgprobe --rdprobe 0 4194304 6291456 --rdprobe 0 0 4194304"

    echo "== positive leg (cps2w, the WIDE .rom as emitted; ~40 min) =="
    # shellcheck disable=SC2086
    "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$POSLOG" --core cps2w \
        --wide "$BUILD" --frames "$FRAMES" $probe_args \
        || { echo "FAIL: the positive leg did not complete"; exit 1; }
    ROMF="$SCRATCH/rom/vsavjw.rom"
    [ -s "$ROMF" ] || { echo "FAIL: no $ROMF after the positive leg"; exit 1; }
    cp "$ROMF" "$POSLOG/rom_used.bin"
    python3 - "$ROMF" <<'PY' || exit 1
import sys
with open(sys.argv[1], "r+b") as f:
    f.seek(41); b = f.read(1)
    if b != b"\xfe":
        sys.exit("FAIL: header byte 41 is %r, expected 0xFE (the WIDE MRA's)" % b)
    f.seek(41); f.write(b"\xff")
print("  control image: header byte 41 0xFE -> 0xFF (CPS-2 WIDE off)")
PY
    echo "== control leg (cps2w, the SAME .rom with the profile bit clear) =="
    # shellcheck disable=SC2086
    "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$NEGLOG" --core cps2w \
        --wide "$BUILD" --frames "$FRAMES" $probe_args \
        || { echo "FAIL: the control leg did not complete"; exit 1; }
    cp "$ROMF" "$NEGLOG/rom_used.bin"
    python3 - "$ROMF" <<'PY'
import sys
with open(sys.argv[1], "r+b") as f:
    f.seek(41); f.write(b"\xfe")
PY
fi

# ── the verdict tool on each leg, against the .rom that leg ran ────────────
for leg in pos neg; do
    case "$leg" in pos) D="$POSLOG" ;; neg) D="$NEGLOG" ;; esac
    R="$D/rom_used.bin"
    [ -s "$R" ] || R="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}/rom/vsavjw.rom"
    if [ ! -s "$D/prgprobe.txt" ]; then bad "$leg: no prgprobe.txt in $D"; continue; fi
    python3 "$REPO/tools/prgprobe_verdict.py" "$D/prgprobe.txt" --rom "$R" > "$D/verdict.txt" 2>&1
    v=$?
    sed 's/^/     /' "$D/verdict.txt" | sed -n '/the instrument against its own label/,$p'
    case "$v" in
        2) bad "$leg: the verdict tool REFUSED — the instrument, not the core, is what failed" ;;
        *) ok  "$leg: verdict tool exit $v (0=works 1=never exercised 3=wrong bytes)" ;;
    esac
done

# ── the frozen pair ────────────────────────────────────────────────────────
SUM="$(mktemp)"
for leg in pos neg; do
    case "$leg" in pos) D="$POSLOG" ;; neg) D="$NEGLOG" ;; esac
    grep -a "^PRGPROBE frame" "$D/prgprobe.txt" | tail -1 \
      | sed "s/^PRGPROBE /$leg /" >> "$SUM"
done
if [ "$FREEZE" = 1 ]; then
    { echo "# tests/test_mister_prg_window.sh — the frozen pair. One line per leg,"
      echo "# the probe's own last per-frame report. Regenerate DELIBERATELY (--freeze):"
      echo "# a moved count on a deterministic simulation is a finding."
      cat "$SUM"; } > "$EXPECT"
    echo "  FROZE $EXPECT:"; sed 's/^/     /' "$EXPECT"
elif [ -f "$EXPECT" ]; then
    EW="$(mktemp)"; grep -v '^#' "$EXPECT" > "$EW"
    if cmp -s "$EW" "$SUM"; then
        ok "the pair matches the frozen expectation"
    else
        bad "the pair MOVED:"
        diff "$EW" "$SUM" | sed 's/^/       /'
    fi
    rm -f "$EW"
else
    bad "no frozen expectation at $EXPECT — run once with --freeze"
fi

# ── the structural assertions, independent of the frozen numbers ───────────
field() { grep -a "^$1 " "$SUM" | tr ' ' '\n' | grep -A1 -x "$2" | tail -1; }
pos_lo="$(field pos rd_lo)"; neg_lo="$(field neg rd_lo)"
pos_hi="$(field pos rd_hi)"; neg_hi="$(field neg rd_hi)"
pos_cyc="$(field pos cyc_hi_rd)"; neg_cyc="$(field neg cyc_hi_rd)"
pos_w="$(field pos wide)"; neg_w="$(field neg wide)"
[ "$pos_w" = 1 ] && [ "$neg_w" = 0 ] \
  && ok "the profile bit reached the RTL in both legs (wide_en 1 / 0)" \
  || bad "wide_en is $pos_w / $neg_w — the two legs are not the two profile states"
[ "${pos_lo:-0}" -gt 100000 ] && [ "${neg_lo:-0}" -gt 100000 ] \
  && ok "MUST-FIRE: the probe counted $pos_lo / $neg_lo program reads BELOW \$400000" \
  || bad "MUST-FIRE FAILED: only $pos_lo / $neg_lo reads below \$400000 — a zero above the line would mean nothing"
[ "${neg_hi:-1}" = 0 ] \
  && ok "the CONTROL leg completed ZERO reads above \$400000 — the decode is gated, by construction" \
  || bad "the control leg read above \$400000 with the profile CLEAR ($neg_hi) — the gate leaks"
# The two legs do NOT issue the same number of cycles, and after slice D5 that
# is the point: with the profile ON the 68k RUNS the code in the extension, and
# with it clear the extension is unreadable and the program cannot get there.
# What must hold is the asymmetry, in the right direction.
[ "${pos_hi:-0}" -gt 1000 ] \
  && ok "the profile-ON leg COMPLETES $pos_hi program-ROM reads above \$400000 — the 68k runs from the extension" \
  || bad "the profile-ON leg completed only ${pos_hi:-0} reads above \$400000; before slice D5 this was 10 and the boot died"
[ "${pos_cyc:-0}" -gt "${neg_cyc:-0}" ] \
  && ok "the profile-ON leg addresses the window far more than the control ($pos_cyc vs $neg_cyc)" \
  || bad "the control addresses the window as much as the positive leg ($pos_cyc vs $neg_cyc) — that is not the expected asymmetry"
rm -f "$SUM"

[ "$fail" = 0 ] && echo "PASS test_mister_prg_window" || echo "FAIL test_mister_prg_window"
exit "$fail"
