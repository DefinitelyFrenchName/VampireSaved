#!/usr/bin/env python3
"""gen_skill_guide.py — GENERATE the human GUIDE.md beside a level-0 SKILL.md.

  python3 tools/gen_skill_guide.py                 # write GUIDE.md for every level-0 skill
  python3 tools/gen_skill_guide.py --check         # regenerate in memory, diff against disk
  python3 tools/gen_skill_guide.py --prefix MFI    # one skill
  python3 tools/gen_skill_guide.py --root DIR ...  # a copy of the tree (the gate's controls)

WHY THIS EXISTS (14z-134, maintainer-ruled 2026-09-05). The level-0 skills
(`mame-fbneo-instruments` [MFI], `mister-jtframe-core` [MJC]) are meant to be
REUSED on other projects, so each needs the SMS shape: `SKILL.md` (the rules)
plus `GUIDE.md` (the human rendition — the same rules, same IDs, with the
INCIDENT that taught each one). In the SMS project the guide was hand-written
and ID-locked to the skill. Here it can be GENERATED, because every rule is
already anchored `**[PFX-N]**` at the exact paragraph of the project docs
that records its incident: the guide is that paragraph, quoted, under the
rule. Generated means it cannot drift from either the skill or the docs, and
`--check` (gate `tests/test_skill_guides.sh`, ci_portable) says so.

WHAT A GUIDE ENTRY IS: the rule verbatim from SKILL.md; then the incident —
the nearest `#` heading above the anchor and the anchored BLOCK (the
blank-line-delimited paragraph holding the anchor; a heading-line anchor takes
the heading plus its first paragraph; a table-row anchor takes the row), with
every `**[PFX-N]**` marker stripped so the guide carries no anchors of its
own (the census walks only the docs; a guide is an OUTPUT). Sections follow
SKILL.md's own `##` order. The skill directory — SKILL.md + GUIDE.md — is the
self-contained unit: copy it into `~/.claude/skills/` on another machine.
ROM-free, emulator-free, ~0.1 s.
"""
import argparse
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import checkskills  # noqa: E402

REPO = HERE.parent
LEVEL0 = ["MFI", "MJC"]
ANCHOR_ANY = re.compile(r"\*\*\[[A-Z]+-\d+\]\*\*\s*")
HEADER_RE = re.compile(r"^(#{1,6})\s+(.*)$")
RULE_RE = re.compile(r"^- \[([A-Z]+-\d+)\]\s+(.*)$")
ORIGIN = ("Project VAMPIRE SAVED — the full-roster Vampire Savior romhack on the real "
          "CPS-2 engine (FBNeo and MAME as instruments, a jtframe core on MiSTer)")


def find_block(text, anchor):
    """(heading, block) for the paragraph carrying `anchor` in `text`."""
    lines = text.split("\n")
    idx = next((i for i, l in enumerate(lines) if anchor in l), None)
    if idx is None:
        return None, None
    heading = ""
    for j in range(idx, -1, -1):
        m = HEADER_RE.match(lines[j])
        if m and j != idx:
            heading = m.group(2)
            # a wrapped `##` heading continues on the previous line(s)
            k = j - 1
            while k >= 0 and HEADER_RE.match(lines[k]) and HEADER_RE.match(lines[k]).group(1) == m.group(1):
                heading = HEADER_RE.match(lines[k]).group(2) + " " + heading
                k -= 1
            break
    if HEADER_RE.match(lines[idx]):
        # anchor on a heading line: the heading itself + its first paragraph
        head = HEADER_RE.match(lines[idx]).group(2)
        k = idx + 1
        while k < len(lines) and lines[k].strip() == "":
            k += 1
        para = []
        while k < len(lines) and lines[k].strip() != "" and not HEADER_RE.match(lines[k]):
            para.append(lines[k]); k += 1
        return heading, head + "\n\n" + "\n".join(para)
    def is_row(i):
        return 0 <= i < len(lines) and "|" in lines[i] and (
            lines[i].lstrip().startswith("|")
            or (i > 0 and lines[i - 1].lstrip().startswith("|"))
            or (i + 1 < len(lines) and lines[i + 1].lstrip().startswith("|")))
    if is_row(idx):
        return heading, lines[idx]          # a table row: the row alone
    a = idx
    while a > 0 and lines[a - 1].strip() != "" and not HEADER_RE.match(lines[a - 1]):
        a -= 1
    b = idx
    while b + 1 < len(lines) and lines[b + 1].strip() != "" and not HEADER_RE.match(lines[b + 1]):
        b += 1
    # a LIST ITEM inside a list block: the item and its indented continuation
    if LIST_RE.match(lines[idx]):
        b = idx
        while b + 1 < len(lines) and lines[b + 1].startswith("  ") and not LIST_RE.match(lines[b + 1]):
            b += 1
        a = idx
    block = "\n".join(lines[a:b + 1])
    return heading, window(block, anchor)


LIST_RE = re.compile(r"^\s*(?:[-*+]|\d+\.)\s+")
WINDOW = 1800   # a run-on paragraph (HANDOFF's MiSTer section is one 15 KB
                # paragraph) is quoted as a WINDOW around the anchor, on
                # sentence boundaries, with the cut marked — the guide is a
                # reminder of the incident, the doc is the incident.


def window(block, anchor):
    if len(block) <= WINDOW:
        return block
    pos = block.find(anchor)
    lo = max(0, pos - WINDOW // 3)
    hi = min(len(block), pos + 2 * WINDOW // 3)
    # widen/narrow to sentence boundaries where one is near
    m = re.search(r"[.!?]\s+", block[:lo][::-1][:200]) if lo > 0 else None
    if m:
        lo -= m.start()
    m2 = re.search(r"[.!?](\s|$)", block[hi:hi + 200]) if hi < len(block) else None
    if m2:
        hi += m2.end()
    out = block[lo:hi].strip()
    return ("… " if lo > 0 else "") + out + (" … *(the paragraph continues in the origin doc)*" if hi < len(block) else "")


def clean(s):
    s = ANCHOR_ANY.sub("", s)
    return re.sub(r"[ \t]+\n", "\n", s).strip()


def render(root, prefix):
    cfg = checkskills.SKILLS[prefix]
    skill_path = root / cfg["path"]
    skill = skill_path.read_text(encoding="utf-8")
    body = skill.split("\n---\n", 1)[-1]
    name = re.search(r"^name: (.+)$", skill, re.M).group(1).strip()
    title = next((l[2:] for l in body.splitlines() if l.startswith("# ")), name)
    docs = {rel: (root / rel).read_text(encoding="utf-8") for rel in cfg["docs"] if (root / rel).is_file()}

    out = [f"# {title} — the guide", "",
           f"The human rendition of `SKILL.md` in this directory: the same rules, the same",
           f"IDs, each followed by the INCIDENT that taught it. **GENERATED** by",
           f"`tools/gen_skill_guide.py` of the originating project from the documentation",
           f"paragraph every rule is anchored to — never hand-edited; regenerate there.",
           f"Origin: {ORIGIN}. The incidents therefore name that project's game, builds,",
           f"gates and session tags (`14z-N`); the RULES do not. The rule is the reminder,",
           f"the incident is the fact. IDs are stable and never reused; a gap means the",
           f"rule stayed at the origin's board-specific level.", "",
           f"**To use this skill elsewhere:** copy this directory (`SKILL.md` + `GUIDE.md`)",
           f"into `~/.claude/skills/{name}/`. Nothing in it depends on the origin tree.", ""]
    section_open = False
    for line in body.splitlines():
        m = HEADER_RE.match(line)
        if m and m.group(1) == "##":
            out += [f"## {m.group(2)}", ""]
            section_open = True
            continue
        r = RULE_RE.match(line)
        if not r:
            continue
        rid, rule = r.group(1), r.group(2).strip()
        anchor = f"**[{rid}]**"
        hit = next(((rel, t) for rel, t in docs.items() if anchor in t), None)
        out += [f"**[{rid}]** {rule}", ""]
        if hit is None:
            out += [f"> *Incident: anchor `[{rid}]` not found in the origin docs.*", ""]
            continue
        rel, t = hit
        heading, block = find_block(t, anchor)
        where = f"`{rel}`" + (f" › *{clean(heading)}*" if heading else "")
        quoted = "\n".join("> " + l if l else ">" for l in clean(block).split("\n"))
        out += [f"> **Incident** ({where}):", ">", quoted, ""]
    return "\n".join(out).rstrip("\n") + "\n", skill_path.parent / "GUIDE.md"


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--prefix", action="append", help="default: every level-0 skill")
    ap.add_argument("--root", default=str(REPO))
    args = ap.parse_args()
    root = Path(args.root)
    prefixes = args.prefix or LEVEL0
    fails = 0
    for p in prefixes:
        text, out_path = render(root, p)
        if args.check:
            have = out_path.read_text(encoding="utf-8") if out_path.exists() else ""
            if have != text:
                fails += 1
                print(f"  FAIL  {out_path.relative_to(root)} is STALE against SKILL.md + the docs "
                      f"— regenerate with tools/gen_skill_guide.py --prefix {p}")
            else:
                n = text.count("\n**[")
                print(f"  ok    {out_path.relative_to(root)} is current ({n} rules)")
        else:
            out_path.write_text(text, encoding="utf-8")
            print(f"wrote {out_path.relative_to(root)} ({len(text.encode())} B)")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
