#!/bin/sh
# charpages_internal.sh — regenerate the INTERNAL character pages with sprites
# (14z-121 (6)). The published artifacts (docs/project/tables/chars/<t>.html)
# carry no art by ruling; these pages do, and they live OUTSIDE the tracked
# tree: build/charpages/<tenant>_internal.html.
#
# The pipeline, every step rerunnable and every number from an instrument:
#   A. tests/lua/field_trace.lua on every naming rig part (tests/replays/naming/
#      <tenant>_<part>.*, native vs2): P1's node pointer per frame.
#   B. the FRAME PICKER: per event the first frame P1's node is an ATTACK node
#      of the move's chain (tools/anim_nodes.py's graph), else the chain's
#      first frame -> build/p3_sprites/frames.tsv.
#   C. tests/lua/sprite_capture.lua at those frames: the OBJ list + the palette
#      page ($90C000) as the game had them.
#   D. tools/sprite_render.py: the tenant's entries (its records' tile set,
#      obj_records.walk; the bank from the OBJ bank table; the LEFT x-cluster — the rigs pin
#      P1 left of P2) drawn from $ROMDIR/vsav2.zip's tiles -> PNG per move.
#   E. tools/charmap_html.py --sprites: the page with the sprite beside each
#      chain's box diagram.
# ~15 min (A and C are ~24 MAME legs each, six in parallel). Needs ROMDIR.
# Usage: ROMDIR=... tools/charpages_internal.sh [DON=build/don_m18 HUI=build/hui52 PYR=build/pyron36]
set -u
: "${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
DON="${DON:-build/don_m18}"; HUI="${HUI:-build/hui52}"; PYR="${PYR:-build/pyron36}"
W="$REPO/build/p3_sprites"; rm -rf "$W"; mkdir -p "$W/cap" "$W/png" "$REPO/build/charpages"
FIELDS="ff841c:l:node,ff8410:w:x,ff8414:w:y,ff8782:b:id,ff840b:b:face"

echo "== chains + tile sets"
for t in donovan:$DON huitzil:$HUI pyron:$PYR; do n="${t%%:*}"; b="${t#*:}"; mkdir -p "$W/chains_$n"
  python3 - "$b/extract" "$W/chains_$n" "$W/tiles_$n.txt" <<'PY' || exit 1
import json, subprocess, sys
sys.path.insert(0, "tools"); import obj_records
ex, w, tiles_out = sys.argv[1:4]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]), "--table", hex(ptr["anim_index_" + name]), "--name", name, "--end", hex(r["src"] + r["len"]), "--json", f"{w}/{name}.json"], stdout=subprocess.DEVNULL)
img = open(f"{ex}/region_anim.bin", "rb").read()
aux = [v for k, v in rj["regions"].items() if k.startswith("aux")]
ok = lambda p: any(a["src"] <= p < a["src"] + a["len"] for a in aux) or (r["src"] <= p < r["src"] + r["len"])
tiles, _, _ = obj_records.walk(img, r["src"], r["src"], r["src"] + r["len"], ok)
open(tiles_out, "w").write("\n".join(f"{t:x}" for t in sorted(tiles)))
PY
done

PARTS="$(ls tests/replays/naming/ | grep -v victim | grep '\.json$' | sed 's/\.json//' | tr '\n' ' ')"
pokes() { python3 -c "import json;print(';'.join(json.load(open('tests/replays/naming/$1.json'))['pokes']))"; }
frames() { python3 -c "import json;print(json.load(open('tests/replays/naming/$1.json'))['frames'])"; }

echo "== A. node traces"
n=0
for rig in $PARTS; do
  ( cd "$W" && MAME_SANDBOX="$W/sb_$rig" REPLAY="$REPO/tests/replays/naming/$rig.rpl" POKES="$(pokes $rig)" FIELDS="$FIELDS" FIELD_OUT="$W/t_$rig.txt" FIELD_FROM=2300 FIELD_TO="$(frames $rig)" FRAMES="$(frames $rig)" \
    "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/l_$rig.log" 2>&1 ) </dev/null &
  n=$((n + 1)); [ $((n % 6)) = 0 ] && wait
done; wait

echo "== B. the frame picker"
python3 - "$W" <<'PY' > "$W/frames.tsv" || exit 1
import json, sys, glob, html
sys.path.insert(0, "tools"); import _minitoml
W = sys.argv[1]
for t in ("donovan", "huitzil", "pyron"):
    chains = {}
    for name in ("a", "a2", "b", "c", "proj"):
        for seq, c in json.load(open(f"{W}/chains_{t}/{name}.json"))["chains"].items():
            chains[(name, int(seq, 16))] = [(int(n["addr"], 16), n["hbA"]) for n in (c.get("nodes") or [])]
    moves = _minitoml.loads(open(f"build/manifest/moves_{t}.toml").read())["move"]
    for tr in sorted(glob.glob(f"{W}/t_{t}_*.txt")):
        part = tr.rsplit("_", 1)[-1][:-4]
        sched = json.load(open(f"tests/replays/naming/{t}_{part}.json"))
        rows = {}
        for l in open(tr):
            f = l.split()
            if len(f) >= 3 and f[0] == "F": rows[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
        for e in sched["events"]:
            if e["name"].startswith("walk-in"): continue
            m = max((mv for mv in moves if e["name"].startswith(mv["name"])), key=lambda mv: len(mv["name"]), default=None)
            if not m or not m.get("table"): continue
            seqs = [int(s, 16) for s in str(m["seq"]).split(",") if s.strip()]
            atk, any_ = {}, {}
            for sq in seqs:
                for addr, hba in chains.get((m["table"], sq), []):
                    any_[addr] = sq
                    if hba: atk[addr] = sq
            t0, t1 = e["frame"], e["frame"] + e["gap"]; pick = None
            for want, kind in ((atk, "active"), (any_, "first")):
                for fr in range(t0, t1):
                    v = rows.get(fr)
                    if v and (v["node"] & 0xffffffff) in want:
                        pick = (fr, kind, want[v["node"] & 0xffffffff]); break
                if pick: break
            if pick:
                print(f"{t}\t{part}\t{pick[0]}\t{pick[1]}\t{m['table']}:0x{pick[2]:02x}\t{html.escape(m['name']).replace(' ', '-')}__0x{pick[2]:02x}\t{e['name']}")
PY

echo "== C. captures"
n=0
for rig in $(cut -f1,2 "$W/frames.tsv" | sort -u | tr '\t' '_'); do
  FRS="$(awk -F'\t' -v t="${rig%_*}" -v p="${rig##*_}" '$1==t && $2==p {print $3}' "$W/frames.tsv" | sort -n | uniq | tr '\n' ',' | sed 's/,$//')"
  MX="$(echo "$FRS" | tr ',' '\n' | sort -n | tail -1)"
  ( cd "$W/cap" && MAME_SANDBOX="$W/cap/sb_$rig" REPLAY="$REPO/tests/replays/naming/$rig.rpl" POKES="$(pokes $rig)" DUMP_FRAMES="$FRS" TRACE_OUT="$W/cap/$rig.txt" FRAMES=$((MX + 1)) \
    "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/sprite_capture.lua" > "$W/cap/$rig.log" 2>&1 ) </dev/null &
  n=$((n + 1)); [ $((n % 6)) = 0 ] && wait
done; wait

echo "== D. renders (first occurrence of a move+seq wins)"
python3 - "$W" "$ROMDIR" <<'PY' || exit 1
import subprocess, collections, sys
W, romdir = sys.argv[1:3]
BANK = {"donovan": "3", "huitzil": "3", "pyron": "3"}   # vs2's OBJ bank table 0x27530 (opcode view), id-indexed: ids 0x10/0x11/0x13 -> 0x6000 = bank 3 (measured on the captures: the fighters' mid-screen entries; bank 1 is the HUD)
seen = set(); per = collections.defaultdict(dict)
for l in open(f"{W}/frames.tsv"):
    t, part, fr, kind, ts, name, ev = l.rstrip("\n").split("\t")
    if (t, name) in seen: continue
    seen.add((t, name)); per[(t, part)][int(fr)] = name
n = 0
for (t, part), names in sorted(per.items()):
    r = subprocess.run(["python3", "tools/sprite_render.py", f"{W}/cap/{t}_{part}.txt", f"{romdir}/vsav2.zip:vs2", f"{W}/png/{t}", "--groups", "ab",
                        "--tile-set", f"{W}/tiles_{t}.txt", "--bank", BANK[t], "--names", ",".join(f"{fr}={nm}" for fr, nm in names.items()), "--frames", ",".join(map(str, names))],
                       capture_output=True, text=True)
    n += r.stdout.count(".png")
    if r.returncode: print(t, part, "render FAILED", r.stderr[-200:], file=sys.stderr)
print(f"rendered {n} sprites")
PY

echo "== E. the pages"
for t in donovan:$DON huitzil:$HUI pyron:$PYR; do n="${t%%:*}"; b="${t#*:}"
  python3 tools/charmap_html.py "$n" "$b" "build/charpages/${n}_internal.html" --sprites "$W/png/$n"
done
echo "open build/charpages/<tenant>_internal.html — NOT for publishing"
