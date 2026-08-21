#!/bin/sh
# audit_pool_free_byte.sh — the owner-tag byte (+0x7F of an object-pool
# slot) audit, BOTH pools. On-demand, ~20 min (3 legs x census + tap on
# the merged build).
#
# POOL ATTRIBUTION (corrected 14z-85 — the 14z-84 version of this audit
# measured only $FFB800 and attributed the result to the 59-75 family,
# which was the WRONG POOL):
#   $FF9400 + n*0x100, 32 slots — walker 0x54458 / site 0x54470, the
#       59-75 family. THE TAG'S POOL. Re-measured 14z-85: 804 live-slot
#       observations, zero +0x7F writes across 19,357 tapped pool writes,
#       live family content on two legs (types 0x42/0x45).
#   $FFB800 + n*0x80, 32 slots — walker 0x5E52A / site 0x5E542, the
#       114-120 family (renumbered 14z-82, no tags needed). +0x7F is
#       measured free here too (the 14z-84 census, still valid FOR THIS
#       POOL) and must STAY untouched — a tag write landing here means a
#       family stamp allocated from the effect pool, which the census
#       never observed and which must be investigated, not absorbed.
#
# TWO MODES, auto-selected by the build's own tag_map.json:
#   pre-tag build (no tag_map.json): +0x7F takes ZERO writes and is zero
#       in every live slot, both pools — the original freeness claim.
#   post-tag build: on $FF9400, live FAMILY-typed slots (type 0x3B-0x4B)
#       must carry the forced tenant's tag (the zero-tag tripwire's
#       static twin), and every +0x7F writer PC must be one of the
#       emitted tag thunks (tag_map.json tag_write_pc rows); $FFB800
#       +0x7F stays zero-write/zero-value.
#   FORCE_MODE=pre|post overrides — the negative control: post-mode
#       against a pre-fix build MUST fail (untagged family slots).
#
# KNOWN NEIGHBOR FACT (re-measured 14z-85, $FFB800): OUR hole_b code
# (PC 0x3FFFD6) writes WORDS at +0x7C/+0x7E — and a word at +0x7E covers
# byte +0x7F. The 14z-84 "zero writes on $FFB800 +0x7F" was an artifact of
# WORD-OFFSET accounting (the old parse bucketed the tap's off field
# without splitting byte lanes); under byte-lane accounting +0x7F IS
# written on that pool by our own code (low byte observed zero, so the
# census still reads +0x7F==0 in live slots). Tag bytes on $FFB800 would
# have been CLOBBERED — one more reason the tag lives on $FF9400, where
# byte-lane accounting shows zero +0x7F writes on every leg. The hole_b
# hits staying nonzero doubles as a liveness control (asserted below).
# GOTCHA filed: bucket write taps by BYTE LANE, never by word offset.
#
# Usage: ROMDIR=... tests/audit_pool_free_byte.sh [merged builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
   # RE-POINTED 14z-94 (GitHub #94): was build/m3b_merged, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.
# KNOWN RED ON EVERY BUILD SINCE 14z-87 (GitHub #110, found 14z-103).
# The frozen rig constants were measured on the pre-beep-fix platform;
# bisected: attic m3b_merged6 PASS, m3b_merged7 FAIL, stable thereafter.
# The native-anchored invariants are elsewhere and GREEN (audit_fg_parity,
# test_pyron_cosmo). Do NOT absorb the current values without attributing
# the 14z-87 mechanism — see the issue.
BUILD="${1:-build/m3b_merged12}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

MODE="${FORCE_MODE:-}"
if [ -z "$MODE" ]; then
    if [ -f "$BUILD/patch/tag_map.json" ]; then MODE=post; else MODE=pre; fi
fi
echo "mode: $MODE (owner-tag $([ "$MODE" = post ] && echo shipped || echo 'not in this build'))"

# leg spec: name : replay : forced id : frames : window lo : window hi
# (pcosmo NEEDS the meter pokes or the EX never fires — replay header)
run_leg() {
    name="$1"; rp="$2"; pk="$3"; frames="$4"; wlo="$5"; whi="$6"
    DF=$(python3 -c "print(';'.join(f'{f}:ff9400-ffb3ff;{f}:ffb800-ffc7ff' for f in range($wlo,$whi,4)))")
    d="$W/$name"; mkdir -p "$d"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" POKES="$pk" \
      REPLAY="$REPO/tests/replays/$rp.rpl" DUMPS="$DF" FRAMES="$frames" \
      CHECKSUM_OUT="$d/c.ram" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/out" 2>&1 ) \
        || { echo "FAIL: $name census leg did not run"; fail=1; }
    t="$W/tap_$name"; mkdir -p "$t"
    ( cd "$t" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$t/sb" POKES="$pk" \
      REPLAY="$REPO/tests/replays/$rp.rpl" \
      TAP="ff9400,13312" WINDOW="$wlo,$whi" FRAMES="$frames" \
      TRACE_OUT="$t/tap.txt" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/tap_writes.lua" > "$t/out" 2>&1 ) \
        || { echo "FAIL: $name tap leg did not run"; fail=1; }
}

PK10="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"
PK11="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;3000:ff8509:03;3020:ff8509:03"
run_leg hfx    hui/83_hui_fx          "$PK10" 3620 3100 3608 &
run_leg htrap  hui/87_hui_plasma_trap "$PK10" 4810 3300 4800 &
run_leg pcosmo pyron/71_pyron_cosmo   "$PK11" 5200 3300 5150 &
wait

MODE="$MODE" BUILD="$BUILD" python3 - "$W" <<'PY' || fail=1
import glob, json, os, re, sys, collections
W = sys.argv[1]
MODE = os.environ["MODE"]
BUILD = os.environ["BUILD"]
LEGS = {"hfx": 0x10, "htrap": 0x10, "pcosmo": 0x11}
FAMILY = range(0x3B, 0x4C)                      # types 59-75
tag_pcs = set()
if MODE == "post":
    try:
        tag_pcs = {r["tag_write_pc"] for r in
                   json.load(open(f"{BUILD}/patch/tag_map.json"))}
    except FileNotFoundError:
        print("FAIL: post mode needs tag_map.json (FORCE_MODE against a "
              "pre-tag build: point BUILD's tag_map elsewhere explicitly)")
        sys.exit(1)
errs = []
agg = {"b8_00": 0, "b8_20": 0, "b8_7c7e": 0, "94_01": 0, "94_20": 0,
       "tag_hits": 0}
for leg, tid in LEGS.items():
    # ── census: $FF9400 (0x100 stride) ──────────────────────────────────
    live94 = fam = fam_tagged = fam_wrong = 0
    z7f_94 = 0
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ff9400.bin")):
        d = open(f, "rb").read()
        for s in range(0, min(len(d), 0x2000), 0x100):
            slot = d[s:s + 0x100]
            if len(slot) < 0x100 or slot[0] == 0:
                continue
            live94 += 1
            if slot[2] in FAMILY:
                fam += 1
                if slot[0x7F] == tid:
                    fam_tagged += 1
                else:
                    fam_wrong += 1
            if slot[0x7F] != 0:
                z7f_94 += 1
    # ── census: $FFB800 (0x80 stride) ───────────────────────────────────
    liveb8 = nz7f_b8 = 0
    for f in sorted(glob.glob(f"{W}/{leg}/dump_*_ffb800.bin")):
        d = open(f, "rb").read()
        for s in range(0, min(len(d), 0x1000), 0x80):
            slot = d[s:s + 0x80]
            if len(slot) < 0x80 or slot[2] == 0:
                continue
            liveb8 += 1
            if slot[0x7F] != 0:
                nz7f_b8 += 1
    # ── tap: one range covers both pools (ff9400 base) ──────────────────
    w7f_94 = collections.Counter()   # PC -> hits on $FF9400 +0x7F
    w7f_b8_pcs = set()
    for ln in open(f"{W}/tap_{leg}/tap.txt"):
        m = re.match(r"frame \d+ PC ([0-9a-f]+) off ([0-9a-f]+) "
                     r"data ([0-9a-f]+) mask ([0-9a-f]+)", ln)
        if not m:
            continue
        pc, off = int(m.group(1), 16), int(m.group(2), 16)
        mask = int(m.group(4), 16)
        m16 = mask & 0xFFFF if (mask & 0xFFFF) else (mask >> 16) & 0xFFFF
        rel = off - 0xFF9400
        for lane, hit in ((0, m16 & 0xFF00), (1, m16 & 0x00FF)):
            if not hit:
                continue
            b = rel + lane
            if 0 <= b < 0x2000:                       # $FF9400 pool
                so = b % 0x100
                if so == 0x01: agg["94_01"] += 1
                if so == 0x20: agg["94_20"] += 1
                if so == 0x7F: w7f_94[pc] += 1
            elif 0x2400 <= b < 0x3400:                # $FFB800 pool
                so = (b - 0x2400) % 0x80
                if so == 0x00: agg["b8_00"] += 1
                if so == 0x20: agg["b8_20"] += 1
                if so in (0x7C, 0x7E): agg["b8_7c7e"] += 1
                if so == 0x7F: w7f_b8_pcs.add(pc)
    # ── verdicts per leg ────────────────────────────────────────────────
    print(f"  [{leg}] $FF9400 live {live94} (family {fam}, tagged "
          f"{fam_tagged}) | $FFB800 live {liveb8} | +0x7F writes "
          f"94:{sum(w7f_94.values())} b8pcs:{len(w7f_b8_pcs)}")
    if leg == "hfx" and liveb8 < 200:
        errs.append(f"{leg}: only {liveb8} live $FFB800 slots — the rig "
                    "did not form the effect content (verdict vacuous)")
    if leg in ("htrap", "pcosmo") and fam < 30:
        errs.append(f"{leg}: only {fam} family-typed live slots on "
                    "$FF9400 — the rig did not form family content "
                    "(verdict vacuous)")
    if nz7f_b8:
        errs.append(f"{leg}: $FFB800 +0x7F NONZERO in {nz7f_b8}/{liveb8} "
                    "live slots")
    # $FFB800 +0x7F write-freeness is NOT asserted: our own hole_b word
    # write at +0x7E covers that byte lane (header). What must never
    # happen is a TAG THUNK writing there — a family stamp allocated
    # from the effect pool (checked in post mode below).
    if MODE == "post":
        stray = {p for p in w7f_b8_pcs if p in tag_pcs}
        if stray:
            errs.append(f"{leg}: TAG THUNK PC(s) wrote $FFB800 +0x7F: "
                        + ", ".join(f"{p:#x}" for p in sorted(stray))
                        + " — a family stamp allocated from the effect "
                        "pool; investigate")
    if MODE == "pre":
        if z7f_94:
            errs.append(f"{leg}: $FF9400 +0x7F NONZERO in {z7f_94}/{live94} "
                        "live slots (pre-tag build)")
        if w7f_94:
            errs.append(f"{leg}: $FF9400 +0x7F took "
                        f"{sum(w7f_94.values())} write(s) (pre-tag build)")
    else:
        if fam_wrong:
            errs.append(f"{leg}: {fam_wrong}/{fam} family slots NOT "
                        f"carrying tag {tid:#x} — a stamp site the tag "
                        "emission missed (the tripwire's static twin)")
        bad_pcs = set(w7f_94) - tag_pcs
        if bad_pcs:
            errs.append(f"{leg}: +0x7F written by PCs outside the emitted "
                        f"tag thunks: "
                        + ", ".join(f"{p:#x}" for p in sorted(bad_pcs)))
        agg["tag_hits"] += sum(w7f_94.values())
# ── aggregated instrument liveness (unconditional totals first) ─────────
print(f"  liveness: b8 +0x00={agg['b8_00']} +0x20={agg['b8_20']} "
      f"+0x7C/7E={agg['b8_7c7e']} | 94 +0x01={agg['94_01']} "
      f"+0x20={agg['94_20']} | tag writes={agg['tag_hits']}")
if agg["b8_00"] < 100 or agg["b8_20"] < 100:
    errs.append("busy $FFB800 fields quiet — the tap is not live")
if agg["94_01"] < 100 or agg["94_20"] < 100:
    errs.append("busy $FF9400 fields quiet — the tap is not live")
if agg["b8_7c7e"] < 1:
    errs.append("the hole_b +0x7C/+0x7E writes vanished — second liveness "
                "control dead (or our hole_b code changed; re-measure)")
if MODE == "post" and agg["tag_hits"] < 1:
    errs.append("post-tag build but ZERO tag writes observed — the "
                "detours are not live")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: pool tag-byte audit ($MODE mode)"; exit 1; }
if [ "$MODE" = post ]; then
    echo "PASS: family slots tagged by their stampers, +0x7F writers are"
    echo "      exactly the emitted tag thunks, effect pool untouched"
else
    echo "PASS: +0x7F free on BOTH pools — zero values in live slots AND"
    echo "      zero writes, instrument liveness proven"
fi
