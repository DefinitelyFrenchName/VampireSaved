#!/usr/bin/env python3
"""close_findings.py — the close ritual's MISSING-HOME check (item 2 of the
adapted close checklist, trialled 14z-167b): every address a session group
names in STATE.md must appear in a LIVE document, or the finding it belongs to
has no home. PROTOTYPE — its verdict is a list for the working agent to answer,
not a gate.

WHAT IT CANNOT SEE (rule-checker run 2026-09-18-44, Q4): it proves an ADDRESS is
present in a live document, not that the FINDING is. An address that older
text already names homes any new finding about it (14z-167's cnt-family
observation names `$FF8081`, which the atlas has carried since 14z-158), and a
finding with no address is invisible to it. It is necessary, not sufficient:
the close's findings table (checklist item 1) is the sufficient check.
`--selftest` is its must-fire control: a planted address named nowhere must be
reported, and a known-homed one must not.

  python3 tools/close_findings.py 14z-167 [--state STATE.md]

Addresses are the tokens `PRG:0x..`, `CPU:$..`, `RAM:$..`, `$FFxxxx` and bare
`0x` hex of five or more digits (code and data offsets); they are compared by
NUMERIC value, so `0x01886C` and `0x1886C` are one address. The live documents
are docs/game, docs/platform and docs/project (every *.md but the *_history.md
twins and the GENERATED indexes), HANDOFF.md, the skills, and the leading
comment block of every tests/*.sh (a gate's WHY lives in its header, ruled
14z-122). An address named
only in STATE, the archives, a ticket or a build/ artifact is reported. An address
inside a fighter block ($FF8400 / $FF8800) is homed by its OFFSET in the atlas
(ram.md documents fighter fields as `+0xNN`).
"""
import argparse, re, sys
from pathlib import Path
R = Path(__file__).resolve().parent.parent
TOK = re.compile(r"(?:PRG:|CPU:)?0x([0-9A-Fa-f]{5,8})\b|(?:RAM:|CPU:)?\$([0-9A-Fa-f]{4,8})\b")
GENERATED = {"annotations.md", "gate_index.md", "GOTCHAS.md", "tickets.md"}

def addrs(text):
    out = {}
    for m in TOK.finditer(text):
        h = m.group(1) or m.group(2)
        v = int(h, 16)
        if m.group(2) and len(h) == 4: v |= 0xFF0000        # a short $xxxx in a RAM context is $FFxxxx
        out.setdefault(v, m.group(0))
    return out

def live_docs():
    for d in ("docs/game", "docs/platform", "docs/project"):
        for p in (R / d).rglob("*.md"):
            if p.name.endswith("_history.md") or p.name in GENERATED: continue
            yield p
    yield R / "HANDOFF.md"
    yield from (R / ".claude/skills").rglob("SKILL.md")
    for p in sorted((R / "tests").glob("*.sh")):
        yield ("header", p)

def selftest():
    """the must-fire control: a synthetic group naming one address present nowhere and one the atlas homes"""
    import tempfile
    planted, homed = "PRG:0x7FFFF1", "RAM:$FF812D"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
        f.write(f"## Session 99z-1 — **selftest**\n\n| | |\n|---|---|\n| (1) | {planted} and {homed} |\n\n---\n")
    import subprocess
    out = subprocess.run([sys.executable, __file__, "99z-1", "--state", f.name], capture_output=True, text=True).stdout
    ok = ("0x7FFFF1" in out) and ("FF812D" not in out.split("\n", 1)[1])
    print(("CONTROL FIRED: planted-address — " if ok else "CONTROL DEAD: planted-address — ") + out.splitlines()[0])
    sys.exit(0 if ok else 1)

def main():
    if "--selftest" in sys.argv: selftest()
    ap = argparse.ArgumentParser(); ap.add_argument("session"); ap.add_argument("--state", default=str(R / "STATE.md"))
    a = ap.parse_args()
    s = Path(a.state).read_text()
    m = re.search(rf"^## Session {re.escape(a.session)} — .*?(?=^## Session |^---$)", s, re.M | re.S)
    if not m: sys.exit(f"no session group {a.session} in {a.state}")
    group = m.group(0)
    want = addrs(group)
    have = set()
    for p in live_docs():
        if isinstance(p, tuple):   # a gate: its leading comment block only
            head = []
            for l in p[1].read_text(errors="replace").splitlines()[1:]:
                if not l.startswith("#"): break
                head.append(l)
            have |= set(addrs("\n".join(head)))
        else:
            have |= set(addrs(p.read_text(errors="replace")))
    # a fighter-block field is documented as an OFFSET (`+0x1C`) from the block base (atlas ram.md), so an
    # address inside P1's ($FF8400) or P2's ($FF8800) block is homed by its offset appearing in the atlas
    atlas = (R / "docs/game/atlas/ram.md").read_text(errors="replace")
    offs = {int(h, 16) for h in re.findall(r"\+0x([0-9A-Fa-f]{1,4})\b", atlas)}
    def homed(v):
        if v in have: return True
        for base in (0xFF8400, 0xFF8800):
            if base <= v < base + 0x400 and (v - base) in offs: return True
        return False
    missing = {v: t for v, t in want.items() if not homed(v)}
    print(f"session {a.session}: {len(want)} addresses named in its STATE group, {len(want) - len(missing)} in a live document, {len(missing)} with no home")
    for v, t in sorted(missing.items()):
        rows = [l.split("|")[1].strip()[:60] for l in group.splitlines() if t in l and l.startswith("|")]
        print(f"  NO HOME  {t:<14} (0x{v:X})  in: {'; '.join(rows) or 'the banner'}")

if __name__ == "__main__":
    main()
