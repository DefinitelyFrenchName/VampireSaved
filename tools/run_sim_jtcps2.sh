#!/bin/sh
# run_sim_jtcps2.sh — run one replay on a jtcps2 core under Verilator and dump
# 68k work RAM at chosen frames (14z-107; the MiSTer leg of the CLAUDE.md §4
# dual-emulator protocol, applied to a THIRD implementation).
#
# WHAT IT IS. `docs/platform/mister.md` "Recipe" as ONE idempotent command:
# scratch clone -> ~/.mame/roms symlinks -> jtframe env + Go tool -> MRA/.rom
# -> rom.bin/core.mod -> .rpl translation -> the simulation, with the
# fork's `JTFRAME_SIM_WRAMDUMP` hook writing wram/dump_<frame>_ff0000.bin in
# 68k byte order — exactly the files tools/compare_fields.py consumes.
#
# WHY WORK RAM NEEDS A HOOK AT ALL (measured 14z-107, and it RETRACTS the
# 14z-106 note that said work RAM was already reachable): on CPS-2
# JTFRAME_SIM_IODUMP dumps the 128-byte EEPROM, not RAM (cps2 has no
# cfg/mem.yaml, so ioctl_din is driven only by the serial EEPROM,
# cores/cps1/hdl/jtcps1_sdram.v:462-478), and JTFRAME_SAVESDRAM exists only in
# the Verilog SDRAM model (modules/jtframe/hdl/ver/mt48lc16m16a2.v:193-209),
# which the Verilator lane never instantiates.
#
# WHERE WORK RAM LIVES (RTL, then CONFIRMED against the running core,
# 14z-107): jtcps1_sdram.v:158-164 WRAM_OFFSET = 23'h30_0000 (16-bit WORDS),
# jtcps2_main.v:127,185 ram_cs => addr = {2'b0, A[15:1]}, jtframe_ram_rq.v:94
# sdram_addr = addr + offset. So on the REFERENCE core 68k RAM:$FF0000-$FFFFFF
# is SDRAM bank 0 byte offset 0x600000 — **ON cps2w IT IS 0x648000**, because
# slice D2 re-packed bank 0; see the per-core constant below — 64 KB,
# confirmed by dumping the whole 16 MB bank at a boot
# frame and diffing it against the post-download image: the only touched
# regions were VRAM/ORAM (0x400000-0x42FFFF) and exactly 297 bytes at
# 0x600000, the same 297 MAME carries at that point of the boot memory test.
# test.cpp swaps bytes symmetrically on load and on dump, so the dumped file
# is big-endian 68k order: measured, the sim's RAM at game frame 74/76/78
# differs from MAME's at 76/78/80 in 1-2 bytes of 65,536, while the
# byte-SWAPPED comparison differs in 416.
#
# THE DOWNLOAD IS NOT SKIPPABLE ON CPS-2, and this cost a run to learn
# (14z-107). Dropping -load makes test.cpp preload sdram_bank?.bin at t=0 and
# shorten the download to 32 bytes (test.cpp:263-281, 611-651) — the ROM
# CONTENT is then right, but the CPS-2 DECRYPTION KEY is not: it is latched
# into core REGISTERS while the download streams (jtcps1_prom_we cps2_key_we
# -> jtcps2_keyload), and no SDRAM image can restore it. Measured: a
# 1,841-frame run with the banks preloaded left 68k work RAM ALL ZEROS from
# the first frame to the last — the 68k never executed. So every run pays the
# ~462-simulated-frame download (~7-8 min wall). `-setname` IS still dropped:
# jtsim:503-506 compares a RELATIVE `readlink rom.bin` against the ABSOLUTE
# $ROMFILE so it always re-links and re-runs getset.sh for nothing; this
# script makes the rom.bin symlink and copies core.mod itself.
#
# BECAUSE THE DOWNLOAD IS SIMULATED, IT CONSUMES INPUT LINES: sim_inputs.hex
# advances on every LVBL fall, download frames included, while the core is
# held in reset until the transfer ends. So the .rpl must be SHIFTED by the
# download length — that is what --offset is for (default DWNLD_FRAMES).
#
# FRAME OUTPUT IS OFF BY DEFAULT, AND THAT IS A CORRECTNESS DECISION
# (14z-107 (7)). jtframe's Verilator harness forks a child per CHANGED frame to
# run ImageMagick -- ALWAYS, `-video` is not what enables it -- and until fork
# commit 9 that child ended with exit(0). exit() runs the C stdio cleanup;
# libc++'s basic_filebuf is a FILE*; and fclose() on a seekable read stream
# repositions the SHARED file description back to the stream's logical
# position. So every forked child REWOUND the parent's sim_inputs.hex and the
# simulated CONTROLLER was replayed at the next buffer refill -- and since the
# number of forks follows the PICTURE, so did the simulated 68k's state. That
# is the whole of slice D1's "the anchor is video-sensitive": measured, a core
# rendering black and a core rendering the game diverge at frame 2051 in one
# byte, RAM:$FF8060, the START bitmask.
# Fork commit 9 fixes it at the root (_exit(0), no cleanup, no rewind). This
# default is the belt to that fix's braces: a run being used as a STATE oracle
# should not be doing anything with the pixels in the first place, and with
# JTFRAME_SIM_NOVIDEO it provably is not. `off` vs `fork` is the control that
# proved the mechanism, and tests/test_mister_sim_anchor.sh asserts the mode
# its numbers were frozen under.
#
# RULE 7. The .rom, the SDRAM banks and the RAM dumps are ROM-derived: they
# live in the scratch clone and in an out-dir OUTSIDE this repo, never in it.
# This script refuses an out-dir inside the tree.
#
# Usage:
#   ROMDIR=... tools/run_sim_jtcps2.sh <replay.rpl> <outdir> \
#       [--frames N] [--wram FIRST LAST] [--core cps2|cps2w] [--offset K] \
#       [--no-load] [--region BANK OFF LEN ADDR] [--frame-output MODE] [--stats] \
#       [--wide BUILD_DIR] [--post-frames N] [--keep-banks]
#   --frames N   ABSOLUTE frames to simulate, the ~462 download frames
#                INCLUDED — as are --wram and the dump file names. (jtsim's
#                own -frame counts from the end of the transfer; this script
#                converts.) A MAME frame f sits at simulated frame f + 460.
#   --no-load    skip the ROM download. DIAGNOSTICS ONLY — the 68k will not
#                run (see above); it is also the inertness control's cheap run.
#   --region     override the dumped block (default: the CPS-2 68k work RAM).
#   --frame-output MODE   what the HOST does with the pixels. This is part of
#                the run's identity, not a cosmetic choice -- see
#                "FRAME OUTPUT IS OFF BY DEFAULT" below.
#                  off     (DEFAULT) -d JTFRAME_SIM_NOVIDEO=1: the harness's
#                          per-frame image writer is compiled out. No fork, no
#                          ImageMagick, no frames/. The lane's state oracle
#                          runs in this mode.
#                  fork    upstream's behaviour: one fork()+ImageMagick child
#                          per CHANGED frame, jpgs left in the core's ver/game.
#                          The control leg, and what a picture is debugged in.
#                  collect fork, plus jtsim -video, plus collecting
#                          <outdir>/frames. jtsim builds an mp4 once more than
#                          250 jpgs exist, so keep the window short.
#   --video      alias for --frame-output collect.
#   --frame-window FIRST LAST [STRIDE]
#                which frames the image writer may write (ABSOLUTE frames,
#                download included). Only meaningful with --frame-output
#                fork|collect. Without it every CHANGED frame is written,
#                which on a 3,700-frame run is ~3,000 forks, ~3,000
#                ImageMagick invocations and a directory nobody can find
#                anything in. STRIDE defaults to 1; use it for a filmstrip
#                across a whole run (e.g. 0 999999 20).
#   --wide BUILD_DIR
#                run the CPS-2 WIDE romset (`vsavjw`) instead of stock
#                `vsavj`. The WIDE set is a CLONE whose PARENT is the BUILD's
#                own vsav.zip, so the .rom cannot be made from the pristine
#                $ROMDIR alone: this delegates to tools/mister_mra.sh, which
#                stages a PRIVATE $HOME for the generator (added 14z-107 (9),
#                MiSTer slice D2, for the SDRAM image census).
#                **THE IMAGE IS ALWAYS GENERATED BY `cps2w`, whatever --core
#                says**, and it has to be: the WIDE machine entry is tagged
#                `sourcefile="capcom/cps2w.cpp"` while `cores/cps2` parses
#                `sourcefile=["cps2.cpp"]`, so the REFERENCE core emits no
#                WIDE MRA and no .rom at all (measured 14z-107 (9), which is
#                slice D0's profile gate working as designed). So
#                `--core cps2 --wide` means "hand the reference core the WIDE
#                download image", not "ask it to build one" — which is the
#                right shape for a control anyway.
#   --post-frames N
#                simulate N frames AFTER the ROM transfer. Unlike --frames it
#                does not assume the transfer is DWNLD_FRAMES long, which the
#                WIDE image's is not (66 MB vs 46 MB). Use it when what you
#                want is the post-download SDRAM image and nothing else.
#   --rdprobe BANK LO HI
#                arm one SDRAM READ PROBE: count every 16-bit word the CORE
#                reads from bank BANK at a byte offset in [LO,HI). Repeatable,
#                at most FOUR times (the harness carries four slots — enough to
#                arm the windows under test AND one that MUST see traffic, so a
#                zero result is evidence about the core, not about the probe).
#                Writes
#                `RDPROBE frame N p0 .. p1 ..` lines into jtsim.log for every
#                frame with traffic, a `RDPROBE SUMMARY` line per probe at the
#                end, and <outdir>/rdprobe_<k>.txt listing the DISTINCT 128-byte
#                blocks touched — on CPS-2 GFX that list IS the list of tile
#                codes fetched, because a tile code is its own SDRAM address
#                (docs/project/mister_core.md section 5).
#                THIS IS A FETCH-SIDE OBSERVABLE: it answers "did the core read
#                those bytes", which a rendered frame only implies. Units are
#                BURST BEATS, not ACTIVATE commands — do not compare them with
#                `--stats` numbers without dividing by the burst length.
#                THE WINDOW IS A PHYSICAL ADDRESS, so it is invalidated by any
#                memory-map change: derive it from the RTL constants, never
#                from memory (14z-107 (9) paid for that rule twice).
#   --prgprobe   arm the 68k PROGRAM-ROM READ PROBE in cores/cps2w (slice D4's
#                discriminator, 14z-107 (11)): -d JTCPS2W_PRGPROBE=1. It
#                classifies every 68k BUS CYCLE by A[23:21] — decode-independent,
#                so it still speaks when `wide_en` is CLEAR and `rom_cs` cannot
#                assert in the window — and logs every COMPLETED program-ROM
#                read with the word the CPU LATCHED and the raw SDRAM word
#                behind it. Writes `PRGPROBE frame ...` lines into jtsim.log
#                (the last one is the run's summary) and <outdir>/prgprobe.txt
#                with the per-access records. Reads BELOW CPU:$400000 are
#                counted and sampled in the SAME counters: that is the probe's
#                own must-fire control, and comparing those bytes against the
#                .rom validates the comparison procedure on addresses the game
#                is provably executing from. cps2w only — cores/cps2 has no
#                such block, by construction.
#   --keep-banks collect the four post-download SDRAM bank images into
#                <outdir>/sdram/sdram_bank[0-3].bin. test.cpp writes them once,
#                right after a FULL download (test.cpp:915 `if(
#                dwn.FullDownload() ) sdram.dump()`), so this costs only the
#                download. 64 MB of ROM-derived data: rule 7, out-dir only.
#   --stats      jtsim -stats: instantiate jtframe_sdram_stats_sim, which prints
#                per-bank ACTIVE counts, kiB/s, per-bank share and per-bank
#                same-row hit rate + longest same-row run every 16.667 ms of
#                SIMULATED time (~one line per frame). The lines land in
#                <outdir>/jtsim.log interleaved with the frame counter, which is
#                how tests/audit_sdram_bank_load.sh dates them.
#   env JTSIM_SCRATCH=<dir>   where the scratch clone lives (default
#                             ${TMPDIR:-/tmp}/vampire-saved-jtsim). It is a
#                             CACHE: deleting it costs a re-clone and a
#                             Verilator build, nothing else. NEVER simulate
#                             inside emu/jtcores — jtsim litters
#                             cores/<core>/ver/game/.
# Budget: ~0.98 s per simulated frame on Apple Silicon, download included
# (measured 14z-107). A 2,880-frame run is ~47 min: launch it detached and
# poll the PID, do not trust a notification.
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# The ROM transfer takes this many simulated frames on jtcps2 with vsavj —
# log line "ROM file transfered (frame 462)", measured 14z-106 and 14z-107.
DWNLD_FRAMES=462
# ...and the WIDE image is 66,265,152 B rather than 46,407,744 B, so its
# transfer is longer. Measured 14z-107 (9) on the SDRAM image census: "ROM file
# transfered (frame 659)". A run with --wide asserts the log against this.
DWNLD_FRAMES_WIDE=659
RPL=""; OUTDIR=""; FRAMES=""; WFIRST=""; WLAST=""; CORE=cps2; OFFSET=""; LOAD=1
RBANK=""; ROFF=""; RLEN=""; RADDR=""; FRAMEOUT=off; STATS=0
WIDEBUILD=""; SETNAME=vsavj; POSTFRAMES=""; KEEPBANKS=0
NPROBE=0; PBANK=""; PLO=""; PHI=""; PRGPROBE=0
VFIRST=""; VLAST=""; VSTRIDE=""
while [ $# -gt 0 ]; do
    case "$1" in
    --frames) shift; FRAMES="${1:?--frames needs N}" ;;
    --wram)   shift; WFIRST="${1:?--wram needs FIRST LAST}"; shift; WLAST="${1:?--wram needs FIRST LAST}" ;;
    --core)   shift; CORE="${1:?--core needs cps2|cps2w}" ;;
    --offset) shift; OFFSET="${1:?--offset needs K}" ;;
    --no-load) LOAD=0 ;;
    --video)  FRAMEOUT=collect ;;
    --frame-window) shift; VFIRST="${1:?--frame-window needs FIRST LAST [STRIDE]}"; shift
              VLAST="${1:?--frame-window needs FIRST LAST [STRIDE]}"
              case "${2:-}" in [0-9]*) shift; VSTRIDE="$1" ;; esac ;;
    --frame-output) shift; FRAMEOUT="${1:?--frame-output needs off|fork|collect}" ;;
    --stats)  STATS=1 ;;
    --prgprobe) PRGPROBE=1 ;;
    --wide)   shift; WIDEBUILD="${1:?--wide needs a build dir}"; SETNAME=vsavjw ;;
    --post-frames) shift; POSTFRAMES="${1:?--post-frames needs N}" ;;
    --keep-banks)  KEEPBANKS=1 ;;
    --rdprobe) shift
              _b="${1:?--rdprobe needs BANK LO HI}"; shift
              _l="${1:?--rdprobe needs BANK LO HI}"; shift
              _h="${1:?--rdprobe needs BANK LO HI}"
              [ "$NPROBE" -lt 4 ] || { echo "at most four --rdprobe windows (the harness has four slots)" >&2; exit 2; }
              PBANK="$PBANK $_b"; PLO="$PLO $_l"; PHI="$PHI $_h"
              NPROBE=$((NPROBE + 1)) ;;
    --region) shift; RBANK="${1:?--region needs BANK OFF LEN ADDR}"; shift
              ROFF="${1:?--region needs BANK OFF LEN ADDR}"; shift
              RLEN="${1:?--region needs BANK OFF LEN ADDR}"; shift
              RADDR="${1:?--region needs BANK OFF LEN ADDR}" ;;
    -h|--help) sed -n '2,184p' "$0"; exit 0 ;;
    -*) echo "unknown option '$1' (try --help)" >&2; exit 2 ;;
    *)  if [ -z "$RPL" ]; then RPL="$1"; elif [ -z "$OUTDIR" ]; then OUTDIR="$1";
        else echo "unexpected argument '$1'" >&2; exit 2; fi ;;
    esac
    shift
done
[ -n "$RPL" ] && [ -n "$OUTDIR" ] || { echo "usage: run_sim_jtcps2.sh <replay.rpl> <outdir> [opts]" >&2; exit 2; }
# CHECKED BEFORE ROMDIR, so a clean checkout can assert the refusal.
if [ "$PRGPROBE" = 1 ] && [ "$CORE" != cps2w ]; then
    echo "--prgprobe needs --core cps2w (the block lives in cores/cps2w/hdl/jtcps2_main.v);" >&2
    echo "  asking cores/cps2 for it would compile out silently and report a zero." >&2
    exit 2
fi
ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
ROMDIR="$(CDPATH= cd "$ROMDIR" && pwd)"
RPL="$(CDPATH= cd "$(dirname "$RPL")" && pwd)/$(basename "$RPL")"
case "$CORE" in cps2|cps2w) ;; *) echo "--core must be cps2 or cps2w" >&2; exit 2 ;; esac
case "$FRAMEOUT" in off|fork|collect) ;; *) echo "--frame-output must be off, fork or collect" >&2; exit 2 ;; esac
if [ -n "$WIDEBUILD" ] && [ "$LOAD" = 0 ]; then
    echo "--wide needs the ROM transfer (do not combine it with --no-load)" >&2; exit 2
fi

# THE CPS-2 CONSTANTS live here (a CPS-2 tool), not in jtframe: the harness
# hook is core-agnostic and takes them as macros.
#
# **AND SINCE SLICE D2 THE WORK-RAM OFFSET IS PER CORE. This is not a detail,
# it is the one thing that will silently invalidate every measurement in this
# lane if it is got wrong** (measured 14z-107 (9): it turned
# tests/test_mister_wide_inert.sh red in all 101 frames, and the RTL was
# innocent). The hook dumps an SDRAM ADDRESS, not a 68k address, and D2
# RE-PACKED SDRAM bank 0 to make room for a 6 MB PRG region. So:
#   cores/cps2  : RAM:$FF0000 is bank 0 byte 0x600000 (WRAM_OFFSET word
#                 0x30_0000, upstream v1.7.3)
#   cores/cps2w : RAM:$FF0000 is bank 0 byte 0x648000 (WRAM_OFFSET word
#                 0x32_4000, cores/cps2w/hdl/jtcps1_sdram.v)
# and 0x600000 on cps2w is VRAM, which is a perfectly plausible-looking
# 64 KB of changing bytes — the failure does not announce itself.
WRAM_BANK=0; WRAM_LEN=0x10000; WRAM_ADDR=0xff0000
case "$CORE" in
    cps2)  WRAM_OFF=0x600000 ;;
    cps2w) WRAM_OFF=0x648000 ;;
esac
if [ -n "$RBANK" ]; then
    WRAM_BANK="$RBANK"; WRAM_OFF="$ROFF"; WRAM_LEN="$RLEN"; WRAM_ADDR="$RADDR"
fi
# THE INPUT SCRIPT IS SHIFTED BY THE TRANSFER, and the transfer is longer on
# the WIDE image. sim_inputs.hex advances on every LVBL fall, download frames
# included, so a --wide run that used the stock 462 would start the replay ~200
# frames early and every anchor derived from it would be wrong.
XFER=$DWNLD_FRAMES
[ -n "$WIDEBUILD" ] && XFER=$DWNLD_FRAMES_WIDE
if [ -z "$OFFSET" ]; then
    if [ "$LOAD" = 1 ]; then OFFSET=$XFER; else OFFSET=0; fi
fi

mkdir -p "$OUTDIR"
OUTDIR="$(CDPATH= cd "$OUTDIR" && pwd)"
case "$OUTDIR/" in
    "$REPO"/*) echo "REFUSING: out-dir $OUTDIR is inside the repo. RAM dumps are"
               echo "  ROM-derived (CLAUDE.md rule 7) — write them to a scratch dir." >&2; exit 2 ;;
esac

SCRATCH="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"
case "$SCRATCH" in
    "$REPO"|"$REPO"/*) echo "REFUSING: JTSIM_SCRATCH is inside the repo ($SCRATCH)." >&2
                       echo "  jtsim writes obj_dir/, sdram_bank?.bin, rom.bin into the core dir." >&2; exit 2 ;;
esac

PIN="$(sed -n 's/^PINNED="\([0-9a-f]*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
[ -n "$PIN" ] || { echo "cannot read PINNED from tools/setup_jtcores.sh" >&2; exit 1; }

say() { echo "[run_sim_jtcps2] $*"; }

# ---------------------------------------------------------------- 1. clone
if [ ! -d "$SCRATCH/.git" ]; then
    say "cloning the fork into $SCRATCH (from emu/jtcores)"
    # -e, not -d: in an initialised SUBMODULE .git is a gitfile, not a
    # directory (measured 14z-107 (3) — the -d form refused a perfectly good
    # checkout and only ever passed because a scratch clone already existed).
    [ -e "$REPO/emu/jtcores/.git" ] || { echo "emu/jtcores not initialised — run tools/setup_jtcores.sh" >&2; exit 1; }
    git clone --quiet "$REPO/emu/jtcores" "$SCRATCH"
    git -C "$SCRATCH" remote set-url origin "$(git -C "$REPO/emu/jtcores" remote get-url origin)"
fi
if [ "$(git -C "$SCRATCH" rev-parse HEAD)" != "$PIN" ]; then
    say "checking out the pin $PIN in the scratch clone"
    # THE LOCAL SUBMODULE IS FETCHED FIRST, and it has to be: fork commits are
    # LOCAL-ONLY until the maintainer authorises a push, while `origin` here is
    # the public GitHub URL the clone is re-pointed at (so `jtsim` reports a
    # sane remote). Fetching only origin would leave the scratch clone unable
    # to reach a pin that exists nowhere but emu/jtcores — measured 14z-107 (6).
    git -C "$SCRATCH" fetch --quiet "$REPO/emu/jtcores" \
        '+refs/heads/*:refs/remotes/local/*' 2>/dev/null || true
    git -C "$SCRATCH" fetch --quiet origin 2>/dev/null || true
    git -C "$SCRATCH" checkout --quiet "$PIN" || {
        echo "scratch clone cannot reach the pin $PIN — delete $SCRATCH and rerun" >&2; exit 1; }
fi
[ -f "$SCRATCH/modules/fx68k/hdl/fx68k.sv" ] || \
    git -C "$SCRATCH" submodule update --init modules/fx68k modules/jt12 modules/jt51 modules/jteeprom modules/jtdsp16

# ------------------------------------------------- 2. ROM access for the MRA tool
# mrazip.go:23 hard-codes $HOME/.mame/roms. Symlinks only; nothing is copied.
mkdir -p "$HOME/.mame/roms"
link_rom() {  # link_rom <name in ~/.mame/roms> <file in ROMDIR>
    _want="$ROMDIR/$2"; _at="$HOME/.mame/roms/$1"
    [ -f "$_want" ] || { echo "missing $_want" >&2; exit 1; }
    if [ -L "$_at" ]; then
        [ "$(readlink "$_at")" = "$_want" ] || { echo "REFUSING: $_at points at $(readlink "$_at"), not $_want" >&2; exit 1; }
    elif [ -e "$_at" ]; then
        echo "REFUSING: $_at exists and is not our symlink" >&2; exit 1
    else
        ln -s "$_want" "$_at"; say "linked $_at -> $_want"
    fi
}
link_rom vsavj.zip vsavj.zip
link_rom vsav.zip  vsav.zip
link_rom qsound.zip qsound_hle.zip

# ------------------------------------------------------------- 3. environment
JTROOT="$SCRATCH"; JTFRAME="$JTROOT/modules/jtframe"; CORES="$JTROOT/cores"
ROM="$JTROOT/rom"; RLS="$JTROOT/release"; JTBIN="$RLS"; MRA="$RLS/mra"
POCKET="$JTFRAME/target/pocket"; MODULES="$JTROOT/modules"; MAME="$JTROOT/doc/mame"
export JTROOT JTFRAME CORES ROM RLS JTBIN MRA POCKET MODULES MAME
GNUBIN=""
for d in /opt/homebrew/opt/coreutils/libexec/gnubin /opt/homebrew/opt/gnu-sed/libexec/gnubin \
         /usr/local/opt/coreutils/libexec/gnubin /usr/local/opt/gnu-sed/libexec/gnubin; do
    if [ -d "$d" ]; then GNUBIN="$GNUBIN$d:"; fi
done
PATH="$GNUBIN$PATH:.:$JTFRAME/bin"
export PATH
for t in verilator xmlstarlet convert; do
    command -v "$t" >/dev/null 2>&1 || { echo "$t not found — see docs/platform/mister.md Recipe step 1" >&2; exit 1; }
done
JTF="$JTFRAME/src/jtframe/jtframe"
if [ ! -x "$JTF" ]; then
    command -v go >/dev/null 2>&1 || { echo "go not found (brew install go)" >&2; exit 1; }
    say "building the jtframe Go tool"
    ( cd "$JTFRAME/src/jtframe" && go build -o jtframe . )
fi

# -------------------------------------------------------- 4. MRA + the .rom
GAME="$CORES/$CORE/ver/game"
[ -d "$GAME" ] || { echo "no $GAME — core '$CORE' has no ver/game dir" >&2; exit 1; }
# THE .rom IS REBUILT WHEN THE CORE CHANGES, and that is not paranoia: since
# slice D1 the two cores' TOMLs differ, so a `.rom` cached from the other core
# would hide exactly the kind of bug this lane exists to catch (a stock header
# that is not what cores/cps2 emits). The stamp costs one `jtframe mra` run
# (~15 s) per core change and nothing at all on a repeat run.
# THE WIDE LEG GOES THROUGH tools/mister_mra.sh, and it has to: `vsavjw` is a
# CLONE set whose parent is the BUILD's vsav.zip, while the stock leg needs the
# PRISTINE one, and `jtframe mra` reads a HARD-CODED $HOME/.mame/roms. One
# $HOME cannot be both, so that script stages a private one per run.
STAMP="${WIDEBUILD:+cps2w}${WIDEBUILD:-$CORE}:$SETNAME${WIDEBUILD:+:$WIDEBUILD}"
if [ ! -s "$ROM/$SETNAME.rom" ] || [ "$(cat "$ROM/.built_by" 2>/dev/null || true)" != "$STAMP" ]; then
    rm -f "$ROM/$SETNAME.rom"
    if [ -n "$WIDEBUILD" ]; then
        # ALWAYS cps2w, never $CORE: cores/cps2 cannot see the WIDE set (the
        # cps2w.cpp sourcefile gate) and would emit no .rom at all.
        say "tools/mister_mra.sh --core cps2w --wide $WIDEBUILD (builds $ROM/$SETNAME.rom; the IMAGE is cps2w's whatever --core says)"
        ROMDIR="$ROMDIR" JTSIM_SCRATCH="$SCRATCH" "$REPO/tools/mister_mra.sh" \
            --core cps2w --wide "$WIDEBUILD" --quiet
    else
        say "jtframe mra $CORE (builds $ROM/$SETNAME.rom — scratch only, rule 7)"
        ( cd "$JTROOT" && "$JTF" mra "$CORE" >/dev/null )
    fi
    mkdir -p "$ROM" && printf '%s\n' "$STAMP" > "$ROM/.built_by"
fi
[ -s "$ROM/$SETNAME.rom" ] || { echo "no $ROM/$SETNAME.rom was produced" >&2; exit 1; }
ROMFILE="$ROM/$SETNAME.rom"
say "rom  $ROMFILE $(wc -c < "$ROMFILE" | tr -d ' ') B sha1 $(shasum "$ROMFILE" | cut -c1-40)"

# ------------------------------------------- 5. rom.bin and core.mod, by hand
# What `-setname` would do, minus the pointless re-link and getset.sh run.
cd "$GAME"
if [ ! -e rom.bin ] || [ "$(readlink rom.bin || true)" != "$ROMFILE" ]; then
    ln -sf "$ROMFILE" rom.bin
    say "linked rom.bin -> $ROMFILE"
fi
if [ -s "$ROM/$SETNAME.mod" ]; then cp "$ROM/$SETNAME.mod" core.mod; fi
# The bank dumps are 64 MB of ROM-derived litter that -load would move to
# sdram.old/ anyway; drop them so a long series of runs does not fill the disk.
rm -f sdram_bank?.bin sdram_bank?.hex
rm -rf sdram.old

# ------------------------------------------------- 6. inputs and the run
# --frames is ABSOLUTE (download frames included), like --wram and the dump
# file names; jtsim's own -frame is counted from the END of the transfer, so
# convert here rather than making every caller remember it.
python3 "$REPO/tools/rpl2siminputs.py" "$RPL" "$GAME/sim_inputs.hex" \
    ${FRAMES:+--frames "$FRAMES"} --offset "$OFFSET"
rm -rf "$GAME/wram"
SIMARGS="-verilator -sysname $CORE"
# -stats needs the module FILE too: jtsim adds the macro (bin/jtsim:416-418)
# and game_test.v:380-392 instantiates jtframe_sdram_stats_sim, but nothing
# ever puts hdl/sdram/jtframe_sdram_stats_sim.v on the compile list, so plain
# `jtsim -verilator -stats` dies with "Cannot find file containing module"
# (measured 14z-107 (3); upstream bug at v1.7.3, reported in the fork commit
# message). -args appends to the simulator command line (bin/jtsim:289).
if [ "$STATS" = 1 ]; then
    # ...and --timing, because the reporter is an `initial forever #16_666_667`
    # (jtframe_sdram_stats_sim.v:112, and the same construct in
    # jtframe_romrq_bcache.v:266) and Verilator 5 refuses delays without it
    # (%Error-NEEDTIMINGOPT). --no-timing would compile and never report.
    SIMARGS="$SIMARGS -stats -args --timing"
    SIMARGS="$SIMARGS -args $JTFRAME/hdl/sdram/jtframe_sdram_stats_sim.v"
fi
# NOTE the ordering: jtsim's -video consumes the NEXT word as a frame count
# unless it starts with '-' (bin/jtsim:422-428), so -video is never last.
case "$FRAMEOUT" in
    off)     SIMARGS="$SIMARGS -d JTFRAME_SIM_NOVIDEO=1" ;;
    collect) SIMARGS="$SIMARGS -video" ;;
esac
SIMARGS="$SIMARGS -inputs"
if [ "$LOAD" = 1 ]; then SIMARGS="$SIMARGS -load"; fi
if [ -n "$POSTFRAMES" ]; then
    # ABSOLUTE-frame arithmetic assumes a 462-frame transfer; the WIDE image's
    # is ~660. --post-frames is counted from the END of the transfer, which is
    # jtsim's own convention, so nothing has to know the length.
    SIMARGS="$SIMARGS -frame $POSTFRAMES"
elif [ -n "$FRAMES" ]; then
    if [ "$LOAD" = 1 ]; then
        JTF_FRAMES=$((FRAMES - XFER))
        if [ "$JTF_FRAMES" -le 0 ]; then
            echo "--frames $FRAMES is inside the $XFER-frame download" >&2; exit 2
        fi
    else
        JTF_FRAMES="$FRAMES"
    fi
    SIMARGS="$SIMARGS -frame $JTF_FRAMES"
fi
if [ -n "$WFIRST" ]; then
    SIMARGS="$SIMARGS -d JTFRAME_SIM_WRAMDUMP=$WFIRST -d JTFRAME_SIM_WRAMDUMP_END=$WLAST"
    SIMARGS="$SIMARGS -d JTFRAME_SIM_WRAMDUMP_BANK=$WRAM_BANK -d JTFRAME_SIM_WRAMDUMP_OFF=$WRAM_OFF"
    SIMARGS="$SIMARGS -d JTFRAME_SIM_WRAMDUMP_LEN=$WRAM_LEN -d JTFRAME_SIM_WRAMDUMP_ADDR=$WRAM_ADDR"
    say "RAM dump frames $WFIRST..$WLAST (ABSOLUTE, download included) from $CORE SDRAM bank $WRAM_BANK byte $WRAM_OFF -> wram/dump_<frame>_${WRAM_ADDR#0x}.bin"
else
    say "NO --wram: the harness hook stays compiled out (negative control)"
fi
if [ -n "$VFIRST" ]; then
    if [ "$FRAMEOUT" = off ]; then
        echo "--frame-window needs --frame-output fork or collect" >&2; exit 2
    fi
    SIMARGS="$SIMARGS -d JTFRAME_SIM_VIDEO_FIRST=$VFIRST -d JTFRAME_SIM_VIDEO_LAST=$VLAST"
    [ -n "$VSTRIDE" ] && SIMARGS="$SIMARGS -d JTFRAME_SIM_VIDEO_STRIDE=$VSTRIDE"
    say "frame writer bounded to frames $VFIRST..$VLAST stride ${VSTRIDE:-1}"
fi
if [ "$NPROBE" -gt 0 ]; then
    SIMARGS="$SIMARGS -d JTFRAME_SIM_RDPROBE=1"
    k=0
    for _b in $PBANK; do
        _l="$(echo $PLO | cut -d' ' -f$((k + 1)))"
        _h="$(echo $PHI | cut -d' ' -f$((k + 1)))"
        SIMARGS="$SIMARGS -d JTFRAME_SIM_RDPROBE${k}_BANK=$_b"
        SIMARGS="$SIMARGS -d JTFRAME_SIM_RDPROBE${k}_LO=$_l -d JTFRAME_SIM_RDPROBE${k}_HI=$_h"
        say "SDRAM read probe $k: bank $_b bytes $_l..$_h"
        k=$((k + 1))
    done
    rm -f "$GAME"/rdprobe_?.txt
else
    say "NO --rdprobe: the read probe stays compiled out (negative control)"
fi
if [ "$PRGPROBE" = 1 ]; then
    SIMARGS="$SIMARGS -d JTCPS2W_PRGPROBE=1"
    say "68k program-ROM read probe ARMED (prgprobe.txt + PRGPROBE lines in jtsim.log)"
    rm -f "$GAME/prgprobe.txt"
else
    say "NO --prgprobe: the 68k read probe stays compiled out (negative control)"
fi
say "jtsim $SIMARGS"
T0="$(date +%s)"
bash "$JTFRAME/bin/jtsim" $SIMARGS > "$OUTDIR/jtsim.log" 2>&1 \
    || { echo "jtsim failed — tail of $OUTDIR/jtsim.log:"; tail -20 "$OUTDIR/jtsim.log"; exit 1; }
T1="$(date +%s)"
say "jtsim wall $(( (T1 - T0) / 60 ))m$(( (T1 - T0) % 60 ))s"
grep -a "ROM file transfered" "$OUTDIR/jtsim.log" | sed 's/^/[run_sim_jtcps2] /' || true

# --------------------------------------------------------------- 7. collect
if [ -d "$GAME/wram" ]; then
    mv "$GAME/wram" "$OUTDIR/wram"
    say "collected $(ls "$OUTDIR/wram" | wc -l | tr -d ' ') dumps into $OUTDIR/wram"
else
    say "no wram/ produced"
fi
# ---------------------------------------------------- 7b. dump INTEGRITY
# A LOST OR SHORT DUMP MUST BE LOUD (14z-107 (7)). tools/compare_fields.py GLOBS a
# directory: it compares whatever frames it finds, so a missing file does not
# fail, it silently changes WHICH frames exist -- and on an anchor search that
# means a different anchor, reported as a disagreement between
# implementations. The producer is the only place that knows what SHOULD be
# there, so it is checked here: every frame in [FIRST..LAST], each exactly
# WRAM_LEN bytes, nothing extra.
if [ -n "$WFIRST" ]; then
    python3 "$REPO/tools/check_wram_dumps.py" "$OUTDIR/wram" \
        --first "$WFIRST" --last "$WLAST" --size "$WRAM_LEN" --addr "$WRAM_ADDR" || exit 1
fi
if [ "$KEEPBANKS" = 1 ]; then
    mkdir -p "$OUTDIR/sdram"; n=0
    for b in 0 1 2 3; do
        if [ -s "$GAME/sdram_bank$b.bin" ]; then
            mv "$GAME/sdram_bank$b.bin" "$OUTDIR/sdram/"; n=$((n + 1))
        fi
    done
    [ "$n" = 4 ] || { echo "FAIL: --keep-banks got $n of 4 SDRAM bank images —" >&2
                      echo "  test.cpp dumps them only after a FULL download" >&2; exit 1; }
    say "collected 4 SDRAM bank images into $OUTDIR/sdram"
fi
if [ "$FRAMEOUT" = collect ] && [ -d "$GAME/frames" ]; then
    rm -rf "$OUTDIR/frames"; mv "$GAME/frames" "$OUTDIR/frames"
    say "collected $(ls "$OUTDIR/frames" | wc -l | tr -d ' ') rendered frames into $OUTDIR/frames"
fi
if [ "$STATS" = 1 ]; then
    say "$(grep -ac 'BA STATS' "$OUTDIR/jtsim.log" || true) SDRAM stats lines in $OUTDIR/jtsim.log"
fi
if [ "$NPROBE" -gt 0 ]; then
    for k in 0 1 2 3; do
        [ -f "$GAME/rdprobe_$k.txt" ] && mv "$GAME/rdprobe_$k.txt" "$OUTDIR/"
    done
    grep -a "^RDPROBE SUMMARY" "$OUTDIR/jtsim.log" | sed 's/^/[run_sim_jtcps2] /' || \
        say "NO RDPROBE SUMMARY line in the log — the probe did not run"
fi
if [ "$PRGPROBE" = 1 ]; then
    if [ -s "$GAME/prgprobe.txt" ]; then
        mv "$GAME/prgprobe.txt" "$OUTDIR/prgprobe.txt"
        say "collected $(wc -l < "$OUTDIR/prgprobe.txt" | tr -d ' ') prgprobe records into $OUTDIR/prgprobe.txt"
    else
        echo "FAIL: --prgprobe produced no prgprobe.txt — the probe did not run" >&2; exit 1
    fi
    grep -a "^PRGPROBE frame" "$OUTDIR/jtsim.log" | tail -1 | sed 's/^/[run_sim_jtcps2] /' || \
        say "NO PRGPROBE line in the log"
fi
cp "$GAME/sim_inputs.hex" "$OUTDIR/sim_inputs.hex"
say "done: $OUTDIR"
