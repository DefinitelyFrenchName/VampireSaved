#!/bin/sh
# test_mister_qsound_ext.sh — THE QSOUND EXTENSION IS FETCHED ON THE CORE
# (14z-108). The roster's own voices live in DSP sample banks 0x80-0x8E, which
# stock CPS-2 cannot address at all: `qsnd_addr[22:16] <= dsp_ab[6:0]` keeps
# seven bank bits, so bank 0x8N plays as 0x0N. Reaching them needs slice D1's
# sample-bank WIDTH fix AND slice D2's QSound SPLIT across two SDRAM banks
# (`pcmh_sel = wide_en & pcm_addr[PCM_AW]`, a 1 MB window at PCMH_OFFSET).
#
# This gate counts the SDRAM reads the core issues into that window while a
# tenant is fighting, and requires the same image with the profile bit CLEAR
# to issue NONE. It is the last major subsystem of the profile to get any
# coverage at all (docs/project/mister_core.md section 12).
#
# WHAT THE BUILD'S OWN LEDGER SAYS IS THERE (tools/qs_ledger.py on the WIDE
# romset): 58 samples, image bytes 0x800000-0x8E5800 = 0.896 MB, banks
# 0x80..0x8E. That is what makes a zero meaningful — the region is POPULATED.
#
# MEASURED 14z-108, `108_tenant_voice.rpl`, 4,400 frames:
#   QSound HIGH   210,180 reads, 76 distinct blocks, first at frame 3783,
#                 image bytes 0x830AA0-0x83FFFE — DSP BANK 0x83, overlapping
#                 8 of the ledger's extension samples
#   control leg   0 reads, while still issuing 54,113,994 in QSound LOW
# The first read lands 224 frames INTO the match, during the button mash —
# where an attack voice belongs, not at boot.
#
# IT ALSO CONFIRMS THE SLOT5_AW=20 TRUNCATION IS SAFE. `pcmh_addr =
# pcm_addr[PCM_AW-1:0]` narrows 23 bits to 20 and Quartus warns (10230); it is
# the window MASK by design, valid only while the extension stays inside 1 MB.
# Every address observed here has pcm_addr[22:20] == 0, which is the condition
# that makes the mask lossless.
#
# WHY THE LIVENESS PROBE IS QSOUND LOW AND NOT SOMETHING CONVENIENT: a zero in
# the high window has to be attributable to the PROFILE, not to a DSP that
# never played anything. The control leg reading 54 M in the low window is
# what makes its zero in the high window evidence about `wide_en`.
#
# COST: two ~75 min legs. EMULATOR tier.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }

RPL="$REPO/tests/replays/108_tenant_voice.rpl"
BUILD="${BUILD:-build/m3b_merged21}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
FRAMES="${FRAMES:-4400}"
OUTDIR=""; POSLOG=""; NEGLOG=""
while [ $# -gt 0 ]; do
    case "$1" in
    --frames)  shift; FRAMES="${1:?}" ;;
    --build)   shift; BUILD="${1:?}" ;;
    --pos-log) shift; POSLOG="${1:?}" ;;
    --neg-log) shift; NEGLOG="${1:?}" ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    -*) echo "unknown option '$1'" >&2; exit 2 ;;
    *)  OUTDIR="$1" ;;
    esac; shift
done

[ -e "$REPO/emu/jtcores/.git" ] || { echo "SKIP: emu/jtcores not initialised"; exit 77; }
SD="$REPO/emu/jtcores/cores/cps2w/hdl/jtcps1_sdram.v"

# ── the window, READ OUT OF THE RTL, never hard-coded ──────────────────────
# A hard-coded physical constant is a check with an unwritten expiry date, and
# a placement slice IS a memory-map change (THE INSTRUMENT PROTOCOL).
eval "$(python3 - "$SD" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"PCMH_OFFSET\s*=\s*23'h([0-9A-Fa-f_]+)", src)
if not m: sys.exit("cannot read PCMH_OFFSET from the RTL")
print("PCMH_BYTE=%d" % (int(m.group(1).replace("_",""), 16) * 2))
w = re.search(r"SLOT5_AW\s*\(\s*(\d+)\s*\)", src)
if not w: sys.exit("cannot read SLOT5_AW from the RTL")
print("PCMH_AW=%s" % w.group(1))
bank = None
for mm in re.finditer(r"u_bank(\d)\s*\(", src):
    body = src[mm.end(): mm.end()+4000].split("\n);")[0]
    if re.search(r"\.slot\d_cs\s*\(\s*pcmh_cs\s*\)", body): bank = int(mm.group(1))
if bank is None: sys.exit("cannot locate the pcmh read slot in the RTL")
print("PCMH_BANK=%d" % bank)
PY
)" || { echo "FAIL: could not derive the QSound HIGH window from the RTL"; exit 1; }
PCMH_SPAN=$((1 << PCMH_AW))
printf '  window from the RTL: QSound HIGH -> SDRAM ba%d byte %#x, %d KiB (SLOT5_AW=%d)\n' \
    "$PCMH_BANK" "$PCMH_BYTE" $((PCMH_SPAN / 1024)) "$PCMH_AW"

probe="--rdprobe $PCMH_BANK $PCMH_BYTE $((PCMH_BYTE + PCMH_SPAN))"
probe="$probe --rdprobe 1 0 $((8 * 1024 * 1024))"          # QSound LOW: liveness
probe="$probe --rdprobe 3 0 $((16 * 1024 * 1024))"          # bank 3: liveness

if [ -z "$POSLOG" ] || [ -z "$NEGLOG" ]; then
    [ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset"; exit 77; }
    command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed"; exit 77; }
    [ -d "$REPO/$BUILD" ] || { echo "SKIP: no $BUILD"; exit 77; }
    [ -n "$OUTDIR" ] || OUTDIR="$(mktemp -d)"; mkdir -p "$OUTDIR"
    case "$OUTDIR/" in "$REPO"/*) echo "REFUSING: OUTDIR inside the repo (rule 7)"; exit 2 ;; esac
    POSLOG="$OUTDIR/pos"; NEGLOG="$OUTDIR/neg"
    SCRATCH="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"

    echo "== positive leg (cps2w, the WIDE .rom as emitted; ~75 min) =="
    ( cd "$REPO" && "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$POSLOG" --core cps2w \
        --wide "$BUILD" --frames "$FRAMES" --stats $probe ) \
        || { echo "FAIL: the positive leg did not complete"; exit 1; }

    ROMF="$SCRATCH/rom/vsavjw.rom"
    [ -s "$ROMF" ] || { echo "FAIL: no $ROMF after the positive leg"; exit 1; }
    python3 - "$ROMF" <<'PY' || exit 1
import sys
with open(sys.argv[1], "r+b") as f:
    f.seek(41); b = f.read(1)
    if b != b"\xfe": sys.exit("FAIL: header byte 41 is %r, expected 0xFE" % b)
    f.seek(41); f.write(b"\xff")
print("  control image: header byte 41 0xFE -> 0xFF (CPS-2 WIDE off)")
PY
    echo "== control leg (the SAME .rom, profile bit clear) =="
    ( cd "$REPO" && "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$NEGLOG" --core cps2w \
        --wide "$BUILD" --frames "$FRAMES" --stats $probe ) \
        || { echo "FAIL: the control leg did not complete"; exit 1; }
    # put it back, so nothing downstream inherits a profile-off image
    python3 - "$ROMF" <<'PY'
import sys
with open(sys.argv[1], "r+b") as f: f.seek(41); f.write(b"\xfe")
print("  image restored: header byte 41 -> 0xFE")
PY
fi

sum_of(){ grep -a "RDPROBE SUMMARY $2 " "$1/jtsim.log" 2>/dev/null | tail -1; }
field(){ echo "$1" | sed -n "s/.* $2 \([0-9A-Fa-fx]*\).*/\1/p"; }

P0="$(sum_of "$POSLOG" 0)"; P1="$(sum_of "$POSLOG" 1)"; P3="$(sum_of "$POSLOG" 3)"
N0="$(sum_of "$NEGLOG" 0)"; N1="$(sum_of "$NEGLOG" 1)"; N3="$(sum_of "$NEGLOG" 3)"
[ -n "$P0" ] && [ -n "$N0" ] || { echo "FAIL: no RDPROBE SUMMARY lines — was --rdprobe armed?"; exit 1; }

echo "== the fetch =="
r0="$(field "$P0" reads)"; d0="$(field "$P0" distinct)"; f0="$(field "$P0" first_frame)"
mn="$(field "$P0" min)"; mx="$(field "$P0" max)"
[ "${r0:-0}" -gt 0 ] 2>/dev/null \
    && ok "QSound EXTENSION fetched: $r0 reads, $d0 distinct blocks, first at frame $f0 ($mn-$mx)" \
    || bad "QSound extension: ZERO reads. AMBIGUOUS, not necessarily a defect — see the replay header"

# every address must sit in DSP banks 0x80-0x8E, i.e. pcm_addr[22:20] == 0
python3 - "$PCMH_BYTE" "$mn" "$mx" <<'PY'
import sys
base = int(sys.argv[1]); lo = int(sys.argv[2], 16); hi = int(sys.argv[3], 16)
i_lo, i_hi = 0x800000 + (lo - base), 0x800000 + (hi - base)
b_lo, b_hi = i_lo >> 16, i_hi >> 16
okrange = 0x80 <= b_lo <= 0x8E and 0x80 <= b_hi <= 0x8E
mask_ok = ((i_lo >> 20) & 7) == 0 and ((i_hi >> 20) & 7) == 0
print(f"  image bytes 0x{i_lo:07X}-0x{i_hi:07X}  DSP banks 0x{b_lo:02X}-0x{b_hi:02X}")
print(("  PASS " if okrange else "  FAIL ") + "every address inside the ledger's extension banks 0x80-0x8E")
print(("  PASS " if mask_ok else "  FAIL ") +
      "pcm_addr[22:20] == 0 throughout — the SLOT5_AW=20 mask is LOSSLESS here (Quartus warning 10230)")
sys.exit(0 if (okrange and mask_ok) else 1)
PY
[ $? = 0 ] || fail=1

echo "== the control: the same image, profile bit clear =="
[ "$(field "$N0" reads)" = "0" ] && ok "QSound extension: 0 reads with wide_en clear" \
                                 || bad "control leg read $(field "$N0" reads) from the extension — the zero above would mean nothing"

echo "== the instrument's own positive controls =="
for pair in "positive:$P1:QSound LOW" "control:$N1:QSound LOW" "positive:$P3:bank 3" "control:$N3:bank 3"; do
    leg="${pair%%:*}"; rest="${pair#*:}"; line="${rest%:*}"; what="${rest##*:}"
    n="$(field "$line" reads)"
    [ "${n:-0}" -gt 0 ] 2>/dev/null \
        && ok "$leg leg, $what: $n reads — the probe counts in this run" \
        || bad "$leg leg, $what: ZERO — the probe is not counting, so no verdict above is safe"
done

[ $fail = 0 ] && echo "PASS test_mister_qsound_ext" || { echo "FAIL test_mister_qsound_ext"; exit 1; }
