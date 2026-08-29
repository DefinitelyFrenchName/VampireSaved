#!/bin/sh
# test_mister_gfxc_fetch.sh — THE PAYOFF GATE: it goes green the day the core
# FETCHES a tenant tile. IT IS RED, AND HAS NEVER BEEN GREEN (see STATUS).
# 14z-107 (10), MiSTer slice D3 (+D4). Emulator tier: ROMDIR + Verilator +
# ~2 x 65 min. NOT ci_portable, NOT ci_static.
#
# WHAT IT PROVES, AND WHY IT IS NOT A PICTURE. Slices D0-D2 built the MRA, the
# runtime profile gate and the SDRAM placement, and every one of them was
# proven with a STATIC artefact: the .rom's bytes, an exhaustive bench, an
# image census. None of them changed a single fetch in the running game —
# `rom0_bank[2]` was tied low and the two group-C read slots were provably
# unreachable. D3 unties it. So the claim to prove is a claim about the MEMORY
# BUS: "the core issued READS into the group-C destinations", which a rendered
# frame only implies.
#
# THE INSTRUMENT is the harness's SDRAM read probe (fork commit 12,
# JTFRAME_SIM_RDPROBE): the simulated SDRAM model already sees every read
# address, so the probe is a counter over it. Four windows are armed, and the
# four are what make ONE run self-certifying:
#   p0  SDRAM bank 1, GFXC4_OFFSET .. +8 MB   group C obj bank 4 (fighter art)
#   p1  SDRAM bank 0, GFXC5_OFFSET .. +8 MB   group C obj bank 5 (wheel art)
#   p2  SDRAM bank 2, the whole bank          vanilla obj banks 0/2
#   p3  SDRAM bank 3, the whole bank          vanilla obj banks 1/3 + scroll
# p2/p3 MUST see traffic in every leg. Without them a zero on p0/p1 would be
# ambiguous between "the core did not fetch" and "the probe does not count".
#
# THE TWO LEGS DIFFER BY ONE BYTE OF ONE FILE.
#   POSITIVE: the WIDE .rom exactly as tools/mister_mra.sh emits it, whose
#             header byte 41 is 0xFE — CPS-2 WIDE ON (slice D1's runtime gate).
#   CONTROL : the SAME .rom with byte 41 set to 0xFF, the generator's own fill
#             value, i.e. CPS-2 WIDE OFF. Same core, same RTL, same replay,
#             same probes, same binary.
# So the control is not "a different build": it is the profile bit, and it
# exercises the gate end to end — the download-side redirect, the read-side
# select and the promote all collapse to the reference core's expressions
# together. p0 and p1 must be EXACTLY ZERO there.
#
# WHAT THE ADDRESSES ADD. On CPS-2 a tile code IS its SDRAM address: the
# download scramble undoes the .rom's interleave, so tile code c occupies
# [c*128, c*128+128) inside its obj bank (docs/project/mister_core.md section
# 5). The probe therefore reports a TILE-CODE LIST, and the codes must land
# inside the roster's frozen live extents — 0xEE73 in obj bank 4 and 0xFFDB in
# bank 5 (tests/audit_mister_map_fit.sh). A promote that produced a wrong bank
# would still light the window up, but with codes scattered over the whole
# 8 MB; a promote that dropped a bit would not light it at all.
#
# THE WINDOWS ARE DERIVED FROM THE RTL, NOT TYPED IN. Both are physical
# addresses, and 14z-107 (9) paid for that rule twice: an instrument that names
# a physical address is invalidated by a memory-map change, and a placement
# slice IS a memory-map change. GFXC4_OFFSET/GFXC5_OFFSET and the BANK each
# group-C slot sits in are read out of cores/cps2w/hdl/jtcps1_sdram.v on every
# run.
#
# STATUS 14z-107 (11): THE WHEEL HALF IS GREEN — THE CORE FETCHES TENANT ART —
# AND THE FIGHTER HALF IS STILL RED, HONESTLY. Slice D5 (the CPS-2 decryption
# range) unblocked the boot, and on `11_pick_donovan` over 2,900 simulated
# frames this gate now measures:
#   * obj bank 5 (the select-wheel art): 9,038,400 reads over 105 DISTINCT
#     TILE CODES, first at frame 1556, codes 0x74D6-0xFE41 — all inside the
#     roster's frozen live extent 0xFFDB. The control leg reads ZERO.
#   * obj bank 4 (the fighter art): ZERO, in both legs. **That is the replay,
#     not the RTL**: the window ends at the select screen and no match starts,
#     so no fighter sprite is ever emitted. It stays RED and this gate stays
#     failing until a replay that reaches a match is run, because a gate that
#     is green on evidence it does not have is worse than a red one.
# Previous status, for the record: RED on every leg (14z-107 (10)), because the
# WIDE romset did not get past its own boot sequence and not one sprite of ANY
# kind was drawn. Root cause and fix: docs/platform/mister.md "CAN THE 68k READ
# ABOVE 4 MB?".
# TWO DEFECTS IN THIS GATE were found by its first real measurement, both
# corrected below: the tile code was computed from the ABSOLUTE SDRAM address
# rather than relative to the armed window's base (so a correct promote read as
# 0x170D6-0x1FA41 against an extent of 0xFFDB), and the instrument's own
# positive control demanded vanilla obj traffic in the CONTROL leg — an image
# whose group-C art aliases over vanilla's obj banks by construction, and which
# therefore cannot boot at all.
# Do not weaken this gate to make it green.
#
# Usage:
#   ROMDIR=... [JTSIM_SCRATCH=...] tests/test_mister_gfxc_fetch.sh [OUTDIR]
#         [--frames N] [--build DIR] [--rpl FILE]
#         [--pos-log DIR --neg-log DIR]   re-analyse two finished run dirs
# --pos-log/--neg-log take the OUTDIR of a previous run (jtsim.log +
# rdprobe_*.txt) and skip the simulation, the way
# tests/audit_sdram_bank_load.sh --log does.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }

RPL="$REPO/tests/replays/11_pick_donovan.rpl"
BUILD="build/m3b_merged21"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
FRAMES=4000
OUTDIR=""; POSLOG=""; NEGLOG=""
while [ $# -gt 0 ]; do
    case "$1" in
    --frames)  shift; FRAMES="${1:?--frames needs N}" ;;
    --build)   shift; BUILD="${1:?--build needs a dir}" ;;
    --rpl)     shift; RPL="${1:?--rpl needs a file}" ;;
    --pos-log) shift; POSLOG="${1:?--pos-log needs a dir}" ;;
    --neg-log) shift; NEGLOG="${1:?--neg-log needs a dir}" ;;
    -h|--help) sed -n '2,60p' "$0"; exit 0 ;;
    -*) echo "unknown option '$1'" >&2; exit 2 ;;
    *)  OUTDIR="$1" ;;
    esac
    shift
done

[ -e "$REPO/emu/jtcores/.git" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }
SD="$REPO/emu/jtcores/cores/cps2w/hdl/jtcps1_sdram.v"

# ── the windows, READ OUT OF THE RTL ───────────────────────────────────────
# The offsets are 23-bit WORD constants; the bank is whichever jtframe slot
# module instance carries the slot whose chip select is gfxc4_cs / gfxc5_cs.
eval "$(python3 - "$SD" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
def off(name):
    m = re.search(name + r"\s*=\s*23'h([0-9A-Fa-f_]+)", src)
    if not m: sys.exit("cannot read " + name + " from the RTL")
    return int(m.group(1).replace("_", ""), 16) * 2
# which u_bankN instance carries each group-C slot
bank = {}
for m in re.finditer(r"u_bank(\d)\s*\(", src):
    n = int(m.group(1))
    body = src[m.end(): m.end() + 4000]
    body = body.split("\n);")[0]
    for cs in ("gfxc4_cs", "gfxc5_cs"):
        if re.search(r"\.slot\d_cs\s*\(\s*" + cs + r"\s*\)", body):
            bank[cs] = n
if set(bank) != {"gfxc4_cs", "gfxc5_cs"}:
    sys.exit("cannot locate the group-C read slots in the RTL: %r" % bank)
print("GFXC4_BYTE=%d" % off("GFXC4_OFFSET"))
print("GFXC5_BYTE=%d" % off("GFXC5_OFFSET"))
print("GFXC4_BANK=%d" % bank["gfxc4_cs"])
print("GFXC5_BANK=%d" % bank["gfxc5_cs"])
PY
)" || { echo "FAIL: could not derive the group-C windows from the RTL"; exit 1; }
SPAN=$((8 * 1024 * 1024))
printf '  windows from the RTL: obj bank 4 -> SDRAM ba%d byte %#x, obj bank 5 -> ba%d byte %#x, 8 MB each\n' \
    "$GFXC4_BANK" "$GFXC4_BYTE" "$GFXC5_BANK" "$GFXC5_BYTE"

probe_args="--rdprobe $GFXC4_BANK $GFXC4_BYTE $((GFXC4_BYTE + SPAN))"
probe_args="$probe_args --rdprobe $GFXC5_BANK $GFXC5_BYTE $((GFXC5_BYTE + SPAN))"
probe_args="$probe_args --rdprobe 2 0 $((16 * 1024 * 1024)) --rdprobe 3 0 $((16 * 1024 * 1024))"
# --stats costs this run nothing and buys the SDRAM bank-load figures out of
# the SAME leg (14z-108). The repack risk that `audit_sdram_bank_load` was
# built to bound — group-C obj fetches interleaving with the QSound stream
# INSIDE bank 1 — needs a tenant in a match, which is exactly the run this
# gate makes when it is pointed at a tenant-picking replay. Re-analyse the
# positive leg's jtsim.log with `audit_sdram_bank_load.sh --log`.
probe_args="$probe_args --stats"

# ── the two legs ───────────────────────────────────────────────────────────
if [ -z "$POSLOG" ] || [ -z "$NEGLOG" ]; then
    [ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this gate runs the real romset)"; exit 77; }
    command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed"; exit 77; }
    [ -d "$REPO/$BUILD" ] || { echo "SKIP: no $BUILD (build the WIDE romset first)"; exit 77; }
    [ -n "$OUTDIR" ] || OUTDIR="$(mktemp -d)"
    mkdir -p "$OUTDIR"
    case "$OUTDIR/" in "$REPO"/*) echo "REFUSING: OUTDIR is inside the repo (rule 7)"; exit 2 ;; esac
    POSLOG="$OUTDIR/pos"; NEGLOG="$OUTDIR/neg"

    SCRATCH="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"
    echo "== positive leg (cps2w, the WIDE .rom as emitted; ~65 min) =="
    ( cd "$REPO" && "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$POSLOG" --core cps2w \
        --wide "$BUILD" --frames "$FRAMES" $probe_args ) \
        || { echo "FAIL: the positive leg did not complete"; exit 1; }

    # THE CONTROL IMAGE: the same bytes, byte 41 = 0xFF. It is built by
    # PATCHING the positive leg's own .rom, so the two legs cannot differ by
    # anything else — not even by a regeneration.
    ROMF="$SCRATCH/rom/vsavjw.rom"
    [ -s "$ROMF" ] || { echo "FAIL: no $ROMF after the positive leg"; exit 1; }
    python3 - "$ROMF" <<'PY' || exit 1
import sys
p = sys.argv[1]
with open(p, "r+b") as f:
    f.seek(41); b = f.read(1)
    if b != b"\xfe":
        sys.exit("FAIL: header byte 41 is %r, expected 0xFE (the WIDE MRA's)" % b)
    f.seek(41); f.write(b"\xff")
print("  control image: header byte 41 0xFE -> 0xFF (CPS-2 WIDE off)")
PY
    echo "== control leg (cps2w, the SAME .rom with the profile bit clear) =="
    ( cd "$REPO" && "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$NEGLOG" --core cps2w \
        --wide "$BUILD" --frames "$FRAMES" $probe_args ) \
        || { echo "FAIL: the control leg did not complete"; exit 1; }
    # ...and put the image back, so the next run of anything does not silently
    # inherit a profile-off .rom.
    python3 - "$ROMF" <<'PY'
import sys
with open(sys.argv[1], "r+b") as f:
    f.seek(41); f.write(b"\xfe")
PY
fi

# ── the verdict ────────────────────────────────────────────────────────────
python3 - "$POSLOG" "$NEGLOG" "$GFXC4_BANK" "$GFXC5_BANK" <<'PY' || fail=1
import re, sys, os
pos, neg, ba4, ba5 = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])

# the roster's frozen live extents, tests/audit_mister_map_fit.sh
EXTENT = {0: 0xEE73, 1: 0xFFDB}    # probe slot 0 = obj bank 4, slot 1 = bank 5
bad = 0
def ok(m):  print("  PASS " + m)
def no(m):
    global bad; bad = 1; print("  FAIL " + m)

def read(d, label):
    log = os.path.join(d, "jtsim.log")
    if not os.path.exists(log):
        no("%s: no jtsim.log in %s" % (label, d)); return None
    raw = open(log, "rb").read().decode("utf-8", "replace")
    sums = {}
    for m in re.finditer(r"RDPROBE SUMMARY (\d) bank (\d) window ([0-9A-F]+)-([0-9A-F]+)"
                         r" reads (\d+) distinct (\d+) first_frame (-?\d+)"
                         r" first_addr ([0-9A-F]+) min ([0-9A-F]+) max ([0-9A-F]+)", raw):
        k = int(m.group(1))
        sums[k] = dict(bank=int(m.group(2)), lo=int(m.group(3), 16), hi=int(m.group(4), 16),
                       reads=int(m.group(5)), distinct=int(m.group(6)),
                       first_frame=int(m.group(7)), first_addr=int(m.group(8), 16),
                       lo_hit=int(m.group(9), 16), hi_hit=int(m.group(10), 16))
    if len(sums) != 4:
        no("%s: %d RDPROBE SUMMARY lines, expected 4 — the probe did not run" % (label, len(sums)))
        return None
    for k in range(4):
        f = os.path.join(d, "rdprobe_%d.txt" % k)
        sums[k]["blocks"] = ([int(x) for x in open(f)] if os.path.exists(f) else [])
    return sums

P = read(pos, "positive"); N = read(neg, "control")
if P is None or N is None: sys.exit(1)

# the two legs must have probed the SAME windows, or nothing below compares
for k in range(4):
    if (P[k]["bank"], P[k]["lo"], P[k]["hi"]) != (N[k]["bank"], N[k]["lo"], N[k]["hi"]):
        no("probe %d was armed differently in the two legs" % k)
if P[0]["bank"] != ba4 or P[1]["bank"] != ba5:
    no("the probes are not on the banks the RTL puts group C in")

print("== the fetch ==")
for k, name in ((0, "group C obj bank 4 (fighter art)"), (1, "group C obj bank 5 (wheel art)")):
    p = P[k]
    if p["reads"] > 0:
        # THE TILE CODE IS RELATIVE TO THE WINDOW'S BASE. A CPS-2 tile code is
        # its SDRAM address only INSIDE its own obj bank, and group C's banks
        # do not start at 0 (GFXC5_OFFSET = 0x7E0000, GFXC4_OFFSET = 0x800000
        # in bank 1). Subtracting the armed window's LO is what turns an SDRAM
        # address back into a code the roster's frozen extent can be compared
        # against. (Fixed 14z-107 (11): without it the first real fetch this
        # gate ever saw reported codes 0x170D6-0x1FA41 against an extent of
        # 0xFFDB and called a correct promote a defect.)
        code_lo, code_hi = (p["lo_hit"] - p["lo"]) >> 7, (p["hi_hit"] - p["lo"]) >> 7
        ok("%s: %d reads, %d distinct tiles, first at frame %d, tile codes 0x%04X-0x%04X"
           % (name, p["reads"], p["distinct"], p["first_frame"], code_lo, code_hi))
        if code_hi <= EXTENT[k]:
            ok("  ...and every code is inside the roster's frozen live extent 0x%04X" % EXTENT[k])
        else:
            no("  ...but code 0x%04X is ABOVE the frozen live extent 0x%04X — the promote is"
               " producing addresses the art does not occupy" % (code_hi, EXTENT[k]))
    else:
        no("%s: ZERO reads. The promote did not reach SDRAM." % name)

print("== the control: the same image, profile bit clear ==")
for k, name in ((0, "group C obj bank 4"), (1, "group C obj bank 5")):
    if N[k]["reads"] == 0:
        ok("%s: 0 reads with wide_en clear" % name)
    else:
        no("%s: %d reads with wide_en CLEAR — the profile gate is not gating"
           % (name, N[k]["reads"]))

# THE INSTRUMENT'S OWN POSITIVE CONTROL, and the two legs are held to DIFFERENT
# things on purpose (corrected 14z-107 (11) — the original demanded vanilla obj
# traffic in BOTH legs, which is impossible by construction).
#   * The POSITIVE leg boots, so BOTH vanilla obj banks must see traffic.
#   * The CONTROL leg is a WIDE image with the profile CLEAR, i.e. an image
#     whose 16 MB of group-C art ALIASES over vanilla's obj banks 0/1 and the
#     whole scroll window, because the download redirect is off. That machine
#     cannot boot and never could: it renders a flat yellow field with the
#     CAPCOM logo and loops. Requiring obj-bank-2 traffic there was asking a
#     deliberately-broken image to behave like a working one. What the control
#     leg CAN be held to, and is, is that the probe is demonstrably counting
#     (bank 3 is millions of reads) and that its working set is the LOOPING
#     boot's rather than a healthy one's — far fewer distinct blocks than the
#     positive leg's. Both are assertions about the same probe in the same run.
print("== the instrument's own positive control ==")
for k in (2, 3):
    if P[k]["reads"] > 0:
        ok("positive leg, SDRAM bank %d (vanilla obj): %d reads — the probe counts in this run"
           % (P[k]["bank"], P[k]["reads"]))
    else:
        no("positive leg, SDRAM bank %d: 0 reads. The positive leg BOOTS, so vanilla object"
           " traffic cannot be zero; a zero on p0/p1 would prove nothing" % P[k]["bank"])
if N[3]["reads"] > 0:
    ok("control leg, SDRAM bank %d: %d reads — the probe counts in the control run too"
       % (N[3]["bank"], N[3]["reads"]))
else:
    no("control leg, SDRAM bank %d: 0 reads. The probe is not counting there, so its"
       " zeros on p0/p1 prove nothing" % N[3]["bank"])
if N[3]["distinct"] < P[3]["distinct"]:
    ok("control leg's working set is the LOOPING boot's: %d distinct blocks against the"
       " positive leg's %d" % (N[3]["distinct"], P[3]["distinct"]))
else:
    no("control leg touched %d distinct blocks against the positive leg's %d — it is not"
       " looping, so the two legs are not the experiment this gate describes"
       % (N[3]["distinct"], P[3]["distinct"]))
sys.exit(1 if bad else 0)
PY

[ $fail = 0 ] && echo "PASS test_mister_gfxc_fetch" \
              || { echo "FAIL test_mister_gfxc_fetch"; exit 1; }
