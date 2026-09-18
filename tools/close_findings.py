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

  python3 tools/close_findings.py 14z-167 [--state STATE.md] [--base <commit>]

OUTPUT (ruled 2026-09-18, 14z-167b): the GAPS only — an address named in the
group and in no live document — then the REVIEW list, then one line saying a
clean result proves nothing about findings. It never prints a count of homed
addresses, because that count read as a completeness verdict the one time it
was cited (rule-checker run 2026-09-18-44). REVIEW lists the session's
addresses whose only homes PREDATE the session: no line added since the
session's base commit (the parent of the first commit that added its STATE
heading, or --base) names them — the case where a new finding about an old
address has no home of its own (`$FF8081`, 14z-167). REVIEW is a list to
answer, not a failure: an address named only as context lands there too.
PROMISES (checklist item 4) lists every commitment in the group and in the
sitting's rule-checker resolutions (ledger rows whose session starts with the
key) matching PROMISE_PATTERNS; each must be fulfilled or become an open item.

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
import argparse, re, subprocess, sys
from pathlib import Path
R = Path(__file__).resolve().parent.parent
TOK = re.compile(r"(?:PRG:|CPU:)?0x([0-9A-Fa-f]{5,8})\b|(?:RAM:|CPU:)?\$([0-9A-Fa-f]{4,8})\b")
GENERATED = {"annotations.md", "gate_index.md", "GOTCHAS.md", "tickets.md"}
PROMISE_PATTERNS = r"from here on|from now on|will be (?:done|added|written|stated|fixed|measured)|\bwe will\b|\bI will\b|\bI'll\b|next session|is stated so|to be (?:done|added|written|fixed)|later this sitting|until (?:the|a) "

def promises(key, group):
    pat = re.compile(PROMISE_PATTERNS, re.I)
    texts = [("STATE " + key, group)]
    led = R / "tests/rulecheck/ledger.tsv"
    if led.exists():
        for l in led.read_text().splitlines():
            t = l.split("\t")
            if len(t) > 9 and t[2].startswith(key): texts.append(("ledger " + t[0], t[9]))
    out = []
    for src, text in texts:
        for m in pat.finditer(text):
            a = max(0, m.start() - 70)
            out.append(f"  PROMISE  {src}: ...{text[a:m.end() + 50]}...".replace("\n", " ")[:220])
    return out

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

def git(*a):
    return subprocess.run(["git", "-C", str(R), *a], capture_output=True, text=True).stdout

def session_base(key):
    first = git("log", "--reverse", "--format=%H", f"-S## Session {key} —", "--", "STATE.md").split()
    return git("rev-parse", "--verify", "--quiet", f"{first[0]}^").strip() if first else None

def added_since(base):
    """addresses on lines ADDED since base in the live documents (committed and uncommitted)"""
    paths = [str(p[1] if isinstance(p, tuple) else p).replace(str(R) + "/", "") for p in live_docs()]
    diff = git("diff", "-U0", base, "--", *paths)
    return set(addrs("\n".join(l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++"))))

def selftest():
    """the must-fire control: a synthetic group naming one address present nowhere and one the atlas homes"""
    import tempfile
    planted, homed = "PRG:0x7FFFF1", "RAM:$FF812D"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
        f.write(f"## Session 99z-1 — **selftest**\n\n| | |\n|---|---|\n| (1) | {planted} and {homed}; PLANTED-PROMISE: this is stated so from here on |\n\n---\n")
    import subprocess
    out = subprocess.run([sys.executable, __file__, "99z-1", "--state", f.name], capture_output=True, text=True).stdout
    gaps = out.split("REVIEW")[0]
    ok = ("0x7FFFF1" in gaps) and ("FF812D" not in gaps) and ("PLANTED-PROMISE" in out)
    print(("CONTROL FIRED: planted-address — " if ok else "CONTROL DEAD: planted-address — ") + "the planted address is a gap, the homed one is not, and the planted promise is listed")
    # the review control: an address the atlas homes, with the base at HEAD, has no line added since the base
    out2 = subprocess.run([sys.executable, __file__, "99z-1", "--state", f.name, "--base", "HEAD"], capture_output=True, text=True).stdout
    rev = out2.split("REVIEW", 1)[1] if "REVIEW" in out2 else ""
    ok2 = "FF812D" in rev
    print(("CONTROL FIRED: old-home-only — " if ok2 else "CONTROL DEAD: old-home-only — ") + "an address homed only by older text is listed for review")
    sys.exit(0 if ok and ok2 else 1)

def main():
    if "--selftest" in sys.argv: selftest()
    ap = argparse.ArgumentParser(); ap.add_argument("session"); ap.add_argument("--state", default=str(R / "STATE.md"))
    ap.add_argument("--base", help="the commit before the session (default: the parent of the first commit adding its STATE heading)")
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
    def where(t):
        rows = [l.split("|")[1].strip()[:60] for l in group.splitlines() if t in l and l.startswith("|")]
        return "; ".join(rows) or "the banner"
    print(f"session {a.session}: {len(want)} addresses checked")
    print("GAPS (named in the group, in no live document):")
    for v, t in sorted(missing.items()): print(f"  NO HOME  {t:<14} (0x{v:X})  in: {where(t)}")
    if not missing: print("  none")
    base = a.base or session_base(a.session)
    print(f"REVIEW (homed only by text older than the session, base {base[:8] if base else 'unknown'}; answer each: a new finding needs its own line):")
    if base:
        fresh = added_since(base)
        old_only = {v: t for v, t in want.items() if homed(v) and v not in fresh}
        for v, t in sorted(old_only.items()): print(f"  REVIEW   {t:<14} (0x{v:X})  in: {where(t)}")
        if not old_only: print("  none")
    else:
        print("  (no base: the session's STATE heading was not found in git)")
    pr = promises(a.session, group)
    print("PROMISES (item 4; each fulfilled or made an open item):")
    for l in pr: print(l)
    if not pr: print("  none")
    print("A CLEAN RESULT PROVES NOTHING ABOUT FINDINGS: this tool sees addresses, not findings; the findings table (checklist item 1) and the documentation packet (item 6) are the checks that do.")

if __name__ == "__main__":
    main()
