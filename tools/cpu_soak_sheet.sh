#!/bin/sh
# cpu_soak_sheet.sh — CAPTURE SHEETS for the tenant CPU soak: native vs2 above ours, each leg photographed at ITS
# OWN entries into the same animation nodes (GitHub #129, 14z-189).
#
# WHY IT EXISTS. tests/audit_tenant_cpu_soak.sh reduces each leg to distributions, and the legs diverge from the
# first random draw, so the same frame number is NOT the same moment on both legs (unlike tools/naming_pair_sheet.sh,
# whose rigs pin the RNG). A distance is a number; the maintainer reads a CPU's behaviour from pictures. This tool
# picks the N nodes both legs enter most (by the smaller of the two shares, nodes read back through the build's
# placements exactly as tools/cpu_soak_dist.py does), takes each leg's k-th entry into each, and photographs both legs
# a few frames into it. Same node = the same move or pose, at a moment of each leg's own choosing.
#
# It is an INSTRUMENT, not a gate: it asserts nothing. It replays a leg the gate KEPT (KEEP=<dir> on the gate):
# that leg's own leg.rpl, and the gate's pokes recomputed by the same formula (venue and mask before the draw; level,
# both HP pins and the timer pin), which is the same input up to every snapshot frame. A leg that took fewer snapshots than
# asked is VOID.
#
# Usage: ROMDIR=... tools/cpu_soak_sheet.sh <keep dir> <tenant> <cond> <out.png> [N nodes, default 6] [entry k, default 3]
#   tenant phobos|pyron|donovan, cond passive|active. Env: BUILD (default build/m3b_merged30), SCALE (default 0.5),
#   OFFSETS (frames after the action start, default "2,8,16")
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 4 ] || { sed -n '/^# Usage:/,/^#   OFFSETS/p' "$0"; exit 2; }
K="$(cd "$1" && pwd)"; T="$2"; C="$3"; OUT="$4"; N="${5:-6}"; KTH="${6:-3}"
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
BUILD="${BUILD:-build/m3b_merged30}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
case "$T" in
    phobos) V=02; M=00000000; R=anim@huitzil ;;
    pyron) V=04; M=00000002; R=anim@pyron ;;
    donovan) V=00; M=00000040; R=anim ;;
    *) echo "FAIL: tenant phobos|pyron|donovan"; exit 2 ;;
esac
for s in ours native; do [ -f "$K/${T}_${C}_$s/trace.txt" ] && [ -f "$K/${T}_${C}_$s/leg.rpl" ] || { echo "FAIL: no kept leg $K/${T}_${C}_$s"; exit 1; }; done
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
python3 - "$K/${T}_${C}_ours/trace.txt" "$K/${T}_${C}_native/trace.txt" "$BUILD/patch/placements.json" "$R" "$N" "$KTH" "${OFFSETS:-2,8,16}" > "$W/plan.txt" <<'PY'
import json, sys
from collections import Counter
ta, tb, pl, reg, n, kth, offs = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]), int(sys.argv[6]), [int(x) for x in sys.argv[7].split(",")]
r = json.load(open(pl))["regions"][reg]
def tr_a(v): return v - r["dst"] + r["src"] if r["dst"] <= v < r["dst"] + r["len"] else v
def entries(path, tr):
    # ACTION STARTS: a frame where the state family +0x06 changes to a non-zero value, keyed by (seq, node) — the
    # moment the CPU commits to something; idle-loop node cycling (the bulk of raw node entries) never keys here
    ent, prev = {}, None
    for l in open(path):
        if not l.startswith("F "): continue
        q = l.split(); f = int(q[1]); d = dict(kv.split("=") for kv in q[2:])
        if f < 2900 or int(d["scr"]) != 0x40000: continue
        sq = int(d["seq"])
        if sq != prev and sq != 0:
            ent.setdefault((sq, tr(int(d["node"]))), []).append(f)
        prev = sq
    return ent
import os; LATE = int(os.environ.get("LATE", "6000"))
def late(fs): return [f for f in fs if f >= LATE]
ea, eb = entries(ta, tr_a), entries(tb, lambda v: v)
ca, cb = Counter({k: len(v) for k, v in ea.items()}), Counter({k: len(v) for k, v in eb.items()})
sa, sb = sum(ca.values()) or 1, sum(cb.values()) or 1
shared = [k for k in ca if k in cb and len(late(ea[k])) >= kth and len(late(eb[k])) >= kth]
shared.sort(key=lambda k: -min(ca[k] / sa, cb[k] / sb))
for k in shared[:n]:
    fa, fb = late(ea[k])[kth - 1], late(eb[k])[kth - 1]
    print(f"NODE seq{k[0]:02x}/{k[1]:#08x} {ca[k] * 100 / sa:.1f}% {cb[k] * 100 / sb:.1f}% ours {','.join(str(fa + o) for o in offs)} native {','.join(str(fb + o) for o in offs)}")
PY
[ -s "$W/plan.txt" ] || { echo "VOID: no shared node entered $KTH times on both legs"; exit 1; }
cat "$W/plan.txt"
for s in ours native; do
    fr="$(awk -v s="$s" '{ for (i = 1; i <= NF; i++) if ($i == s) print $(i + 1) }' "$W/plan.txt" | tr '\n' ',' | tr ',' '\n' | awk 'NF' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')"
    max="$(echo "$fr" | tr ',' '\n' | sort -n | tail -1)"
    pk="1750-2860:ff8121:$V;1750-2860:ff8110:$M;2000-$((max + 2)):ff8116:06;2880-$((max + 2)):ff8450:0120;2880-$((max + 2)):ff8850:0120;2880-$((max + 2)):ff8109:63"
    if [ "$s" = ours ]; then set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; else set_=vsav2; rp="$ROMDIR"; fi
    mkdir -p "$W/$s"
    ( cd "$W/$s" && MAME_SANDBOX="$W/$s/sb" MAME_ROMPATH="$rp" REPLAY="$K/${T}_${C}_$s/leg.rpl" POKES="$pk" \
        SNAP_FRAMES="$fr" FRAMES="$((max + 2))" TRACE_OUT="$W/$s/index.txt" \
        "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" > "$W/$s/mame.log" 2>&1 ) </dev/null &
done
wait
python3 - "$W" "$OUT" "${T} CPU (${C} P1): native vs2 above ours, each leg at its own ${KTH}th late start of the same action (state family + node, after f${LATE:-6000})" "${SCALE:-0.5}" <<'PY'
import glob, os, sys
from PIL import Image, ImageDraw
W, out, title, S = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4])
def shots(leg):
    idx = {}
    for l in open(os.path.join(W, leg, "index.txt")):
        t = l.split()
        if len(t) == 4 and t[0] == "SNAP" and t[2] == "frame": idx[int(t[3])] = t[1]
    subs = glob.glob(os.path.join(W, leg, "sb", "snap", "*", ""))
    if not subs: sys.exit(f"VOID: the {leg} leg took no snapshots")
    return {f: os.path.join(subs[0], n + ".png") for f, n in idx.items()}
legs = {leg: shots(leg) for leg in ("native", "ours")}
rows = []
for l in open(os.path.join(W, "plan.txt")):
    q = l.split()
    node, pa, pb = q[1], q[2], q[3]
    fo = [int(x) for x in q[q.index("ours") + 1].split(",")]
    fn = [int(x) for x in q[q.index("native") + 1].split(",")]
    for leg, fr, share in (("native", fn, pb), ("ours", fo, pa)):
        miss = [f for f in fr if f not in legs[leg] or not os.path.exists(legs[leg][f])]
        if miss: sys.exit(f"VOID: the {leg} leg has no snapshot at {miss}")
        rows.append((f"action {node}\n{'native vs2' if leg == 'native' else 'ours'} ({share} of starts)", [(f, legs[leg][f]) for f in fr]))
w0, h0 = Image.open(rows[0][1][0][1]).size
cw, ch = int(w0 * S), int(h0 * S)
LW, TH, CAP = 190, 30, 14
img = Image.new("RGB", (LW + max(len(r[1]) for r in rows) * cw, TH + len(rows) * (ch + CAP)), "white")
d = ImageDraw.Draw(img)
d.text((6, 8), title, fill="black")
for r, (label, cells) in enumerate(rows):
    y = TH + r * (ch + CAP)
    d.multiline_text((6, y + ch // 2 - 6), label, fill="black")
    for c, (f, p) in enumerate(cells):
        img.paste(Image.open(p).convert("RGB").resize((cw, ch)), (LW + c * cw, y + CAP))
        d.text((LW + c * cw + 4, y + 1), f"f{f}", fill="black")
img.save(out); print(f"WROTE {out} {img.size[0]}x{img.size[1]}, {len(rows)} rows")
PY
