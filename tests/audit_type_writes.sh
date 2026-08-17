#!/bin/sh
# audit_type_writes.sh — the DYNAMIC half of the 14z-82 type-stamp census:
# which PCs actually write extended-family type bytes on the ground-truth
# single-tenant builds, and do they all map to the FROZEN static inventory?
#
# ON-DEMAND (6 MAME runs, ~8 min). Run BEFORE trusting any change to the
# type-renumbering emit path, and after any change that could add a family
# stamp site.
#
# WHY. The static census (tools/audit_type_stamps.py) is blind to
# register-sourced writes, computed immediates, and template-copy spawns —
# its own NOT-COVERED statement. The renumber fix rewrites the static
# inventory's sites; a family write from a PC OUTSIDE that inventory means
# an object can still receive an ORIGINAL type number in a renumbered
# tenant's build — the exact silent mis-dispatch class the fix exists to
# kill. So: every observed 114-120-valued type-byte write must map to a
# frozen stamp row, or this audit FAILS and the inventory must be extended
# FIRST (never the other way around).
#
# Also answers, per the 14z-81c close-out:
#   * is type 120 (no static stamp in any ported span) ever stamped?
#   * which PC performs the 115->117 morph (expect x088512+0x27CE)?
#   * the 59-75 observations are REPORTED per writer class (ported vs
#     vanilla-engine PC) as the 0x54470-family deferral record, not gated —
#     vanilla vsavj legitimately writes that range for its own objects.
#
# Rig-liveness control: the 117 stamp PC (x088512 dst+0x27CE) must appear
# on the hui29 legs — a census that observes nothing reads exactly like a
# clean result (list_type_census.py's lesson).
#
# Usage: ROMDIR=... tests/audit_type_writes.sh [outdir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUT="${1:-$(mktemp -d)}"   # GitHub #68: not a predictable default
mkdir -p "$OUT"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary ($MAME_BIN)"; exit 0; }

abspath() { case "$1" in /*) printf '%s\n' "$1";; *) printf '%s/%s\n' "$PWD" "$1";; esac; }

python3 tools/audit_roms.py "$ROMDIR" >/dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

# the pool sweep: projectile pool $FF9400 (0x100-stride), the $FFB800
# effect/companion pool (0x80-stride, the crash pool) and the $FFC800
# local pool (0x80-stride, own table at x088512+0x3494) in one tap range
TAP_RANGE="ff9400,3c00"

# forced-pick pokes: same strings as audit_merged_legacy.sh (the template
# rig; both-struct pokes for the vs-CPU legs)
HUI_SOAK="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"
HUI_FX="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"
PYR_SOAK="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11"
PYR_COSMO="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3300:ff8509:03;3700:ff8509:03;4100:ff8509:03"
POK13="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13;1400:ff8b82:13;1450:ff8b82:13;1500:ff8b82:13"

run_leg() {  # run_leg <name> <build> <replay> <pokes>
    name="$1"; build="$2"; rpl="$3"; pk="$4"
    # exit code deliberately ignored: MAME can die in TEARDOWN after the
    # log is complete (docs/GOTCHAS.md); the END line decides validity
    REPLAY="tests/replays/$rpl.rpl" TAP="$TAP_RANGE" FRAMES=7000 \
    POKES="$pk" TRACE_OUT="$OUT/$name.txt" \
    MAME_ROMPATH="$(abspath "$build")/rompath;$ROMDIR" \
    MAME_BIN="$MAME_BIN" MAME_SANDBOX="$OUT/sbx_$name" \
        tools/run_mame.sh vsavjw \
        -autoboot_script tests/lua/type_write_census.lua \
        >"$OUT/$name.log" 2>&1 || true
    printf '.'
}

echo "running 6 tap legs (~8 min):"
run_leg hui_70  build/hui30   hui/70_hui_mash        "$HUI_SOAK"
run_leg hui_83  build/hui30   hui/83_hui_fx          "$HUI_FX"
run_leg pyr_70  build/pyron21 pyron/70_pyron_mash    "$PYR_SOAK"
run_leg pyr_72  build/pyron21 pyron/72_pyron_cosmo_2p "$PYR_COSMO"
run_leg don_12  build/m5_wide 12_donovan_vs_cpu      "$POK13"
run_leg don_20  build/m5_wide 20_don_round2          "$POK13"
echo

python3 - "$OUT" <<'PY'
import glob, json, os, sys, collections
out = sys.argv[1]

# frozen inventory: src_addr -> row (stamps only)
stamps = {}
kind = None
cur = {}
for ln in open("build/manifest/type_stamps.toml"):
    s = ln.strip()
    if s.startswith("[["):
        if kind == "stamp" and "src_addr" in cur:
            stamps[int(cur["src_addr"], 0)] = dict(cur)
        kind = s.strip("[]"); cur = {}
    elif "=" in s and not s.startswith("#"):
        k, _, v = s.partition("=")
        cur[k.strip()] = v.split("#")[0].strip().strip('"')
if kind == "stamp" and "src_addr" in cur:
    stamps[int(cur["src_addr"], 0)] = dict(cur)

BUILDS = {"hui": "build/hui30", "pyr": "build/pyron21", "don": "build/m5_wide"}
placed = {}
for tag, b in BUILDS.items():
    placed[tag] = json.load(open(f"{b}/patch/placements.json"))["regions"]

def classify(tag, pc):
    for name, r in placed[tag].items():
        if r["dst"] <= pc < r["dst"] + r["len"]:
            return name, r["src"] + (pc - r["dst"])
    return None, None

fail = 0
seen_types = collections.Counter()
unknown_high = []   # 114-120 writes with no inventory row
by_writer = collections.defaultdict(lambda: collections.Counter())
incomplete = []
hui_117_live = False
H117 = None
for name, r in placed["hui"].items():
    if name == "x088512":
        H117 = r["dst"] + 0x27CE

for f in sorted(glob.glob(out + "/*.txt")):
    leg = os.path.basename(f)[:-4]
    tag = leg[:3]
    body = open(f).read()
    if "\nEND " not in body and not body.startswith("END "):
        incomplete.append(leg); continue
    for ln in body.splitlines():
        p = ln.split()
        if not p or p[0] != "W":
            continue
        pc = int(p[4], 16); addr = int(p[6], 16); data = int(p[8], 16)
        tt = (data >> 8) & 0xFF
        seen_types[tt] += 1
        region, src = classify(tag, pc)
        key = (leg, pc, region or "ENGINE", src)
        by_writer[key][tt] += 1
        if 0x72 <= tt <= 0x78:
            if tag == "hui" and pc == H117:
                hui_117_live = True
            if src is None or src not in stamps:
                unknown_high.append((leg, pc, region, src, tt, addr))

print("tap logs complete: %d/6" % (6 - len(incomplete)))
if incomplete:
    print("FAIL: legs with no END line: %s" % " ".join(incomplete)); fail = 1

print("\nobserved family type-byte writes by writer:")
for (leg, pc, region, src), tts in sorted(by_writer.items()):
    loc = f"{region}+0x{src:X}" if src is not None else "vanilla-engine"
    if region and src is not None:
        loc = f"{region} src 0x{src:06X}"
    inv = ""
    if src is not None and src in stamps:
        inv = " [inventory: %s t%s]" % (stamps[src]["form"], stamps[src]["type"])
    elif src is not None and any(0x72 <= t <= 0x78 for t in tts):
        inv = " [NOT IN INVENTORY]"
    print("  %-7s PC %06X %-28s %s%s" %
          (leg, pc, loc, " ".join(f"t{t}x{n}" for t, n in sorted(tts.items())), inv))

print("\n114-120 observation table:")
for t in range(114, 121):
    n = seen_types.get(0x72 + (t - 114), 0)
    v = 0x72 + (t - 114)
    n = seen_types.get(v, 0)
    print("  type %d (0x%02X): %s" %
          (t, v, ("%d writes" % n) if n else
           "NOT OBSERVED (no verdict — do not assume its shape)"))

if unknown_high:
    print("\nFAIL: 114-120-family writes from PCs OUTSIDE the frozen "
          "inventory (%d):" % len(unknown_high))
    seen = set()
    for leg, pc, region, src, tt, addr in unknown_high:
        k = (pc, tt)
        if k in seen:
            continue
        seen.add(k)
        loc = f"{region} src 0x{src:06X}" if src is not None else "ENGINE/unplaced"
        print("  %s PC %06X (%s) wrote type 0x%02X at %06X" %
              (leg, pc, loc, tt, addr))
    print("  -> extend build/manifest/type_stamps.toml (re-scan + re-review)"
          "\n     BEFORE any renumber emit; never absorb silently.")
    fail = 1
else:
    print("\nPASS: every observed 114-120 write maps to a frozen stamp row")

if not hui_117_live:
    print("FAIL: rig-liveness — the 117 stamp PC (x088512+0x27CE) never "
          "fired on the hui legs; the census observed nothing and proves "
          "nothing")
    fail = 1
else:
    print("PASS: rig-liveness — hui legs exercised the known 117 stamp")

sys.exit(fail)
PY
