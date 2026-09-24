#!/usr/bin/env python3
"""audit_poke_readback.py — THE POKE READ-BACK CENSUS: which gates SAMPLE an address
their own rig POKES (GitHub #171 slice Q6, shape 4 of
docs/project/gate_qualification_scope.md).

  python3 tools/audit_poke_readback.py                 # every finding: gate, address, poke frames, sample, leg
  python3 tools/audit_poke_readback.py --gate test_x   # one gate, with what it pokes and samples
  python3 tools/audit_poke_readback.py --root DIR      # over a copy of the tree (the gate's controls)

THE SHAPE IT CATCHES. `tools/name_moves.py` pokes `ff8509 := 09` sixty frames before
every event of a meter part, and `tests/test_killshread_es.sh` samples `ff8509` as its
`stock` column — so that column reads the rig's own poke back, and a value in it is
evidence the poke landed, not evidence about the engine's meter (rule-checker run
2026-09-22-91, Q3; the gate's header says so). A value poked BEFORE an event and read
AFTER it can be a legitimate observation (the poke sets the stage, the game changes
it, the gate measures the change), so every intersection is a FINDING for a human to
classify — OBSERVES or READS-BACK — never a verdict of this tool.

WHAT IT READS, per registry gate (tests/ci_emulator.tsv):
  POKES   literal `frame:addr:hexbytes` tokens anywhere in the script's non-comment
          text (the replay.lua grammar; a token composed from a variable still shows
          its literal address), plus the pokes of every rig the gate GENERATES —
          `tools/name_moves.py gen <tenant> <part>` and `tools/vanilla_join_rig.py gen
          <id> <dist>` are run for the (tenant, part) / (id, dist) pairs the text names,
          and for every part of a tenant the text names without a part (the loops).
  SAMPLES `FIELDS=addr:size:name` (b/w/l), `DUMPS=frame:lo-hi`, `TAP=`/`WATCH=`/`RTAP=`
          `addr,len`, `FBNEO_HTAP=lo-hi`.
  A FINDING is a poked byte range that overlaps a sampled one: (gate, address, the
  poke frames, the sample that reads it).

THE LEG (rule-checker run 2026-09-24-144, Q1/Q4): a poke that belongs to a CONTROL leg — a
known-bad plant the control expects to read back — joined to the measuring leg's sample is
not the shape above. The census cannot follow a variable into the leg that uses it, so it
attributes by the LINE: a token on a line that names a plant, a control, a mode or the
control reader (`PLANT`, `plant`, `ctl`, `CONTROL`, `VS_CTL`, `vs_ctl_is`, `MODE`) is a
CONTROL poke; every other literal and every rig-generated poke is MAIN. A finding's leg is
`main`, `control` or `mixed`, and the frozen table carries it so the maintainer can rule a
control-leg row for what it is. The attribution is textual and is checked by the gate's
`control-leg-flagged` control; a plant assigned on a line that names none of those words
reads as MAIN — a stated blind spot, not a silent one.

NOT READ (the census's stated reach): the census compares ADDRESSES, not dataflow (scope
§7): what a reducer does with a column afterwards
(a sampled-and-poked column that the verdict never compares is still reported — the
classification says whether it matters); pokes and samples whose ADDRESS is composed
from a variable with no literal in the script; the -debug watchpoint scripts'
addresses (GUARD_PROBE, breakpoints) — they report PCs, not sampled values.

The frozen classification lives in tests/expected/poke_readback.tsv; its gate
tests/test_poke_readback.sh re-derives every finding and holds the table to it.
"""
import argparse, json, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gate_follows as gf

POKE_RE = re.compile(r"(?<![\w])(\d{3,5}):([0-9a-fA-F]{4,6}):([0-9a-fA-F]+|\$\{?\w+\}?)")
CONTROL_LINE_RE = re.compile(r"PLANT|plant|\bctl\b|_ctl\b|ctl_|CONTROL|VS_CTL|vs_ctl_is|\bMODE\b")
FIELD_RE = re.compile(r"(?<![\w])([0-9a-fA-F]{4,6}):([bwl]):([A-Za-z0-9_]+)")
DUMP_RE = re.compile(r"(?<![\w])(\d{3,5}|\$\{?[A-Za-z_]\w*\}?):([0-9a-fA-F]{4,6})-([0-9a-fA-F]{4,6})")
TAP_RE = re.compile(r"\b(TAP|WATCH|RTAP)=\"?([0-9a-fA-F]{4,6},\d+(?:;[0-9a-fA-F]{4,6},\d+)*)")
HTAP_RE = re.compile(r"\bFBNEO_HTAP=\"?([0-9a-fA-F]{4,6})-([0-9a-fA-F]{4,6})")
NM_LIT_RE = re.compile(r"""name_moves(?:\.py)?\s+gen\s+["']?([a-z_]+)["']?\s+["']?(\d+)["']?|nm\.gen\(\s*["']([a-z_]+)["']\s*,\s*["']?(\d+)["']?""")
VJ_LIT_RE = re.compile(r"""vanilla_join_rig(?:\.py)?\s+gen\s+["']?(0x[0-9a-fA-F]+|\d+)["']?\s+["']?([a-z]+)["']?""")
SIZE = {"b": 1, "w": 2, "l": 4}


def body(root, gate):
    p = os.path.join(root, f"tests/{gate}.sh")
    if not os.path.exists(p):
        return ""
    return "\n".join(gf._body_lines(open(p, encoding="utf-8", errors="replace").read()))


def rig_pokes(root, text):
    """The pokes of every rig the text generates: {addr: [set(frames), width]}, plus the rig list."""
    out, rigs = {}, []
    if "name_moves" in text:
        sys.path.insert(0, os.path.join(root, "tools"))
        import name_moves as nm
        pairs = set()
        for m in NM_LIT_RE.finditer(text):
            t, p = (m.group(1), m.group(2)) if m.group(1) else (m.group(3), m.group(4))
            if t in nm.SCHEDULES and p in nm.SCHEDULES[t]:
                pairs.add((t, p))
        if not pairs:   # the loops: every part of every tenant the text names, else every tenant
            tenants = [t for t in nm.SCHEDULES if t in text] or list(nm.SCHEDULES)
            for t in tenants:
                for p in nm.SCHEDULES[t]:
                    pairs.add((t, p))
        d = tempfile.mkdtemp()
        for t, p in sorted(pairs):
            try:
                import io, contextlib
                with contextlib.redirect_stdout(io.StringIO()):
                    nm.gen(t, p, f"{d}/{t}_{p}.rpl", f"{d}/{t}_{p}.json")
                for tok in json.load(open(f"{d}/{t}_{p}.json"))["pokes"]:
                    fr, a, v = tok.split(":")
                    e = out.setdefault(a.lower(), [set(), 1]); e[0].add(int(fr)); e[1] = max(e[1], max(1, len(v) // 2))
                rigs.append(f"name_moves {t} {p}")
            except Exception as e:  # a part that cannot generate is reported, never skipped silently
                rigs.append(f"name_moves {t} {p} FAILED: {e}")
    if "vanilla_join_rig" in text:
        sys.path.insert(0, os.path.join(root, "tools"))
        import vanilla_join_rig as vj
        pairs = set()
        for m in VJ_LIT_RE.finditer(text):
            pairs.add((int(m.group(1), 0), m.group(2)))
        if not pairs:
            dists = [d for d in ("near", "far", "hit", "crouch") if re.search(rf"\b{d}\b", text)] or ["near", "far"]
            for cid in range(0x00, 0x0F):
                for dist in dists:
                    pairs.add((cid, dist))
        d = tempfile.mkdtemp()
        for cid, dist in sorted(pairs):
            try:
                import io, contextlib
                with contextlib.redirect_stdout(io.StringIO()):
                    vj.gen(cid, dist, f"{d}/{cid}_{dist}.rpl", f"{d}/{cid}_{dist}.json")
                for tok in json.load(open(f"{d}/{cid}_{dist}.json")).get("pokes", []):
                    fr, a, v = tok.split(":")
                    e = out.setdefault(a.lower(), [set(), 1]); e[0].add(int(fr)); e[1] = max(e[1], max(1, len(v) // 2))
                rigs.append(f"vanilla_join_rig {cid:#04x} {dist}")
            except Exception as e:
                rigs.append(f"vanilla_join_rig {cid:#04x} {dist} FAILED: {e}")
    return out, rigs


def pokes_of(root, gate):
    """-> ({addr: (lo, hi, frames, legs)}, rigs): every poked byte range with its frames and
    the legs its tokens sit on ({'main'}, {'control'} or both)."""
    text = body(root, gate)
    found = {}
    for line in text.split("\n"):
        leg = "control" if CONTROL_LINE_RE.search(line) else "main"
        for m in POKE_RE.finditer(line):
            fr, a, v = int(m.group(1)), m.group(2).lower(), m.group(3)
            n = 1 if v.startswith("$") else max(1, len(v) // 2)
            lo = int(a, 16); e = found.setdefault(a, [lo, lo + n, set(), set()])
            e[2].add(fr); e[1] = max(e[1], lo + n); e[3].add(leg)
    rp, rigs = rig_pokes(root, text)
    for a, (frames, width) in rp.items():   # a rig poke is as wide as its hex value (ff8850:01200120 is 4 bytes)
        lo = int(a, 16)
        e = found.setdefault(a, [lo, lo + width, set(), set()]); e[2].update(frames); e[1] = max(e[1], lo + width); e[3].add("main")
    return found, rigs


def samples_of(root, gate):
    """-> [(kind, label, lo, hi)] every sampled byte range."""
    text = body(root, gate)
    out = []
    for m in FIELD_RE.finditer(text):
        lo = int(m.group(1), 16); out.append(("FIELDS", m.group(3), lo, lo + SIZE[m.group(2)]))
    for m in DUMP_RE.finditer(text):
        out.append(("DUMPS", f"f{m.group(1)}", int(m.group(2), 16), int(m.group(3), 16)))
    for m in TAP_RE.finditer(text):
        for part in m.group(2).split(";"):
            a, n = part.split(","); lo = int(a, 16); out.append((m.group(1), a.lower(), lo, lo + int(n)))
    for m in HTAP_RE.finditer(text):
        out.append(("FBNEO_HTAP", m.group(1).lower(), int(m.group(1), 16), int(m.group(2), 16) + 1))
    return out


def findings(root, gate):
    pk, rigs = pokes_of(root, gate)
    sm = samples_of(root, gate)
    out = []
    for a, (lo, hi, frames, legs) in sorted(pk.items()):
        leg = "mixed" if len(legs) > 1 else next(iter(legs))
        for kind, label, slo, shi in sm:
            if lo < shi and slo < hi:
                out.append((gate, a, f"{min(frames)}-{max(frames)}x{len(frames)}" if frames else "-", f"{kind}:{label}", leg))
    return sorted(set(out)), rigs, pk, sm


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--root", default=os.path.dirname(HERE))
    ap.add_argument("--gate", help="one gate: its pokes, samples and findings")
    a = ap.parse_args()
    rows = gf.registry_rows(a.root)
    gates = [a.gate] if a.gate else sorted(rows)
    total = 0; failed = []
    for g in gates:
        f, rigs, pk, sm = findings(a.root, g)
        if a.gate:
            print(f"== {g}: {len(pk)} poked address(es), {len(sm)} sample range(s), rigs: {rigs or '-'}")
            for addr, (lo, hi, frames, legs) in sorted(pk.items()):
                print(f"  poke  {addr} [{lo:#x},{hi:#x}) leg {'/'.join(sorted(legs))} frames {sorted(frames)[:6]}{'…' if len(frames) > 6 else ''}")
            for kind, label, lo, hi in sm:
                print(f"  sample {kind}:{label} [{lo:#x},{hi:#x})")
        for row in f:
            print("\t".join(row)); total += 1
        failed += [r for r in rigs if "FAILED" in r]
    print(f"{total} finding(s) over {len(gates)} gate(s)" + (f"; {len(failed)} rig(s) FAILED to generate: {failed}" if failed else ""), file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
