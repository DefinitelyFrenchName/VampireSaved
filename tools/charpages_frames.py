#!/usr/bin/env python3
"""charpages_frames.py — which FRAME shows a move, for the internal character
pages' sprites (14z-121 (7)).

  python3 tools/charpages_frames.py pick   <work_dir>               # traces + chains + move lists -> frames.tsv
  python3 tools/charpages_frames.py choose <work_dir> <tenant:build_dir> ...   # frames.tsv + captures -> chosen.tsv

pick — per naming-rig event (tests/replays/naming/<tenant>_<part>.json) and
the move row it names (longest prefix in build/manifest/moves_<tenant>.toml):
the first frame P1's node pointer (the field_trace in <work_dir>/t_<tenant>_<part>.txt)
is an ATTACK node of the row's chain ("active"), else the chain's first node
("first") — and for a "first" row, PROBE frames every 6 f up to +120, because
a move whose fighter chain never attacks hits through an object it OWNS
(Press of Death's foot, the flying Killshread, every projectile), and that
object's hit lands later than the chain's start.
  tsv: tenant  part  frame  kind  table:seq  <Move-Name>__0xSS  event

choose — for each (tenant, move+seq) the frame to render: the "active" frame;
else the first probe at which an object P1 owns (the capture's O lines,
tests/lua/sprite_capture.lua) carries an attack record with REAL POWER in the
owner's hitbox_proj table (a record with power 0 is a dormant placeholder —
Press of Death's foot carries one for its whole flight); else the "first" frame.
  tsv: tenant  <Move-Name>__0xSS  frame  active|object|first  part
"""
import collections
import glob
import html
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _minitoml  # noqa: E402

REPO = Path(__file__).resolve().parent.parent


def name_key(mv, sq):
    return html.escape(mv).replace(" ", "-") + f"__0x{sq:02x}"


def pick(W):
    out = []
    for t in ("donovan", "huitzil", "pyron"):
        chains = {}
        for name in ("a", "a2", "b", "c", "proj"):
            p = Path(W) / f"chains_{t}" / f"{name}.json"
            if not p.exists(): continue
            for seq, c in json.load(open(p))["chains"].items():
                chains[(name, int(seq, 16))] = [(int(n["addr"], 16), n["hbA"]) for n in (c.get("nodes") or [])]
        moves = _minitoml.loads((REPO / "build/manifest" / f"moves_{t}.toml").read_text())["move"]
        for tr in sorted(glob.glob(f"{W}/t_{t}_*.txt")):
            part = tr.rsplit("_", 1)[-1][:-4]
            sched = json.load(open(REPO / "tests/replays/naming" / f"{t}_{part}.json"))
            rows = {}
            for l in open(tr):
                f = l.split()
                if len(f) >= 3 and f[0] == "F":
                    rows[int(f[1])] = {k: int(v) for k, v in (kv.split("=") for kv in f[2:])}
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
                t0, t1 = e["frame"], e["frame"] + e["gap"]
                found = None
                for want, kind in ((atk, "active"), (any_, "first")):
                    for fr in range(t0, t1):
                        v = rows.get(fr)
                        if v and (v["node"] & 0xffffffff) in want:
                            found = (fr, kind, want[v["node"] & 0xffffffff]); break
                    if found: break
                if not found: continue
                fr, kind, sq = found
                out.append((t, part, fr, kind, f"{m['table']}:0x{sq:02x}", name_key(m["name"], sq), e["name"]))
                if kind == "first":
                    for k in range(6, 121, 6):
                        out.append((t, part, fr + k, "probe", f"{m['table']}:0x{sq:02x}", name_key(m["name"], sq), e["name"]))
    return out


def choose(W, builds):
    import hitbox_records
    H = {t: hitbox_records.HitboxSet(Path(b) / "extract") for t, b in builds.items()}
    live = collections.defaultdict(list)   # (tenant, part, frame) -> owned objects with a REAL attack record
    for cap in glob.glob(f"{W}/cap/*.txt"):
        t, part = Path(cap).stem.rsplit("_", 1)
        for l in open(cap):
            if not (l.startswith("O") and l[1:2].isdigit()): continue
            fr, rest = l[1:].split(" ", 1); d = dict(kv.split("=") for kv in rest.split())
            hba = int(d["hbA"])
            if not hba: continue
            try:
                rec = H[t].record(hba >> 8, proj=True)
            except Exception:
                continue
            if rec["real"] > 0 and any(rec["box"]):
                live[(t, part, int(fr))].append(d)
    groups = collections.OrderedDict()
    for l in open(f"{W}/frames.tsv"):
        f = l.rstrip("\n").split("\t")
        if len(f) < 7: continue
        groups.setdefault((f[0], f[5]), []).append((int(f[2]), f[3], f[1]))
    chosen = []
    for (t, name), cands in groups.items():
        anchor = [c for c in cands if c[1] in ("active", "first")][0]
        pick_ = anchor
        if anchor[1] == "first":
            for fr, kind, part in sorted(cands):
                if live.get((t, part, fr)):
                    pick_ = (fr, "object", part); break
        chosen.append((t, name, pick_[0], pick_[1], pick_[2]))
    return chosen


def main():
    cmd, W = sys.argv[1], sys.argv[2]
    if cmd == "pick":
        rows = pick(W)
        Path(W, "frames.tsv").write_text("\n".join("\t".join(map(str, r)) for r in rows) + "\n")
        print(f"{len(rows)} frames ({sum(1 for r in rows if r[3] != 'probe')} anchors)", file=sys.stderr)
    elif cmd == "choose":
        builds = dict(a.split(":", 1) for a in sys.argv[3:])
        rows = choose(W, builds)
        Path(W, "chosen.tsv").write_text("\n".join("\t".join(map(str, r)) for r in rows) + "\n")
        print(collections.Counter(r[3] for r in rows), file=sys.stderr)
    else:
        sys.exit("pick | choose")


if __name__ == "__main__":
    main()
