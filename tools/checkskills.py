#!/usr/bin/env python3
"""checkskills.py — lock the two MiSTer skills to the docs they distil.

  python3 tools/checkskills.py            # check the tree, then self-test
  python3 tools/checkskills.py -v         # ...and list every ID and number
  python3 tools/checkskills.py --root DIR # check a copy of the tree (the gate's
                                          # must-fire controls use this)

WHY THIS EXISTS (14z-114). A skill is a distillation of the docs and loads
BEFORE the work, so a stale skill is a confidently wrong instruction. The
SMS project's `checkskills.py` ID-locked a skill to a second hand-written
human rendition; here the docs themselves are the human rendition, so each
rule is ANCHORED to the paragraph it distils and three things are asserted:

  1. ID-LOCK, both ways.  Every `- [MSC-N]` / `- [MSV-N]` DEFINITION in a
     skill has exactly ONE anchor `**[MSC-N]**` in the source docs, and every
     anchor has a definition. Deleting or rewriting an anchored paragraph
     breaks the lock; so does adding a rule without anchoring it. A plain
     `[MSC-N]` (no bold, not opening a bullet) is a cross-reference and is
     ignored on both sides.
  2. LIFTABILITY (mister_scope.md §1).  The level-1 skill is game-independent:
     "if it names vsav, a tenant, a ceiling of ours, a fingerprint or a build
     dir, it is level 2."  A fixed token list is grepped, case-insensitively.
  3. NUMBERS CITE THE LOG.  Every numeric literal a skill quotes (hex,
     comma-grouped integers, decimals, 4+-digit integers, $-addresses, hash
     fragments) must appear verbatim in a LOG file — never only in the
     synthesis `mister_core.md` (that document's own staleness rule).

The extractors are negative-controlled on synthetic content every run: a
family that has stopped matching passes every claim it no longer finds.
ROM-free, emulator-free, runs anywhere (ci_portable).
"""
import argparse
import re
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# --- the two skills -----------------------------------------------------
SKILLS = {
    "MSC": ".claude/skills/mister-cps2-wide-core/SKILL.md",
    "MSV": ".claude/skills/mister-vampire-saved/SKILL.md",
}
# Where anchors may live (same set for both prefixes; the prefix decides
# which skill a marker belongs to).
ANCHOR_DOCS = [
    "docs/platform/mister.md",
    "docs/project/mister_core.md",
    "docs/project/mister_map.md",
    "docs/project/mister_fit.md",
    "docs/project/mister_field.md",
    "docs/project/cps2_wide.md",
    "docs/project/release_format.md",
    "docs/platform/gotchas.md",
    "docs/project/gotchas.md",
    "HANDOFF.md",
    "CLAUDE.md",
]
# The LOGS a quoted number must appear in. NOT mister_core.md, on purpose.
LOG_DOCS = [
    "docs/platform/mister.md",
    "docs/project/mister_map.md",
    "docs/project/mister_fit.md",
    "docs/project/mister_field.md",
    "docs/project/release_format.md",
    "docs/platform/gotchas.md",
    "docs/project/gotchas.md",
    "release/bitstreams/18269/BITSTREAM.txt",
]
# Level-1 must not name any of these (case-insensitive substring match).
LEVEL1_FORBIDDEN = [
    "vsav", "vampire", "donovan", "huitzil", "phobos", "pyron", "tenant",
    "roster", "demitri", "jedah", "victor", "bishamon",
    "0xEE73", "0xFFDB", "0x8E57F0", "0x5FFF1E", "32007911",
    "build/", "merged", "m3b_",
]

ID = r"\[([A-Z]+-\d+)\]"
DEF_SKILL = re.compile(rf"^- {ID}", re.M)        # `- [MSC-3] ...`
ANCHOR_DOC = re.compile(rf"\*\*{ID}\*\*")         # `**[MSC-3]**` anywhere
NUM_PATTERNS = [
    re.compile(r"0x[0-9A-Fa-f]{3,}"),
    re.compile(r"\$[0-9A-Fa-f]{4,}"),
    re.compile(r"(?<![\d.])\d{1,3}(?:,\d{3})+(?!\d)"),
    re.compile(r"(?<![\d.])\d+\.\d+(?![\d.])"),
    re.compile(r"(?<![\d.,])\d{4,}(?![\d.])"),
    re.compile(r"(?<![0-9A-Za-z])[0-9a-f]{8,}(?![0-9A-Za-z])"),
]


def skill_defs(text):
    return DEF_SKILL.findall(text)


def doc_anchors(text):
    return ANCHOR_DOC.findall(text)


def numbers(text):
    found = set()
    for pat in NUM_PATTERNS:
        for m in pat.finditer(text):
            tok = m.group(0)
            if re.fullmatch(r"\d{4}", tok) and tok.startswith("20"):
                continue  # years
            if re.fullmatch(r"\d\.\d", tok):
                continue  # section numbers (1.3, 2.5)
            if re.fullmatch(r"[0-9a-f]{8,}", tok) and tok.isdigit():
                continue  # long decimal caught by the integer pattern
            found.add(tok)
    # a decimal run inside a hex/$ token is not a number of its own
    return {t for t in found
            if not (t.isdigit() and any(t != u and t in u for u in found))}


def check(root, verbose=False):
    root = Path(root)
    fails = []
    docs = {}
    for rel in ANCHOR_DOCS:
        p = root / rel
        if p.exists():
            docs[rel] = p.read_text(encoding="utf-8")
        else:
            fails.append(f"anchor doc missing: {rel}")
    log_text = ""
    for rel in LOG_DOCS:
        p = root / rel
        if p.exists():
            log_text += "\n" + p.read_text(encoding="utf-8")
        else:
            fails.append(f"log missing: {rel}")

    # all anchors across the doc set, with where each one lives
    anchors = {}
    for rel, text in docs.items():
        for i in doc_anchors(text):
            anchors.setdefault(i, []).append(rel)

    for prefix, rel in SKILLS.items():
        p = root / rel
        if not p.exists():
            fails.append(f"{prefix}: skill {rel} does not exist")
            continue
        text = p.read_text(encoding="utf-8")
        if not re.match(r"^---\nname: [a-z0-9-]+\ndescription: .+\n---\n", text):
            fails.append(f"{prefix}: {rel} lacks the name/description frontmatter")
        defs = skill_defs(text)
        if verbose:
            print(f"  {prefix}: {len(defs)} rules defined in {rel}")
        if not defs:
            fails.append(f"{prefix}: the skill defines NO rules — has the syntax changed?")
        dupes = sorted({i for i in defs if defs.count(i) > 1})
        if dupes:
            fails.append(f"{prefix}: duplicate definition(s): {', '.join(dupes)}")
        foreign = sorted({i for i in defs if not i.startswith(prefix + "-")})
        if foreign:
            fails.append(f"{prefix}: DEFINES foreign-prefix rule(s) {', '.join(foreign)}")

        # 1. ID-lock
        mine = {i: locs for i, locs in anchors.items() if i.startswith(prefix + "-")}
        key = lambda i: int(i.split("-")[1])
        only_skill = sorted(set(defs) - set(mine), key=key)
        only_docs = sorted(set(mine) - set(defs), key=key)
        if only_skill:
            fails.append(f"{prefix}: defined in the skill, ANCHORED NOWHERE: {', '.join(only_skill)}")
        if only_docs:
            fails.append(f"{prefix}: anchored in the docs, NOT DEFINED in the skill: {', '.join(only_docs)}")
        multi = sorted((i for i, locs in mine.items() if len(locs) > 1), key=key)
        for i in multi:
            fails.append(f"{prefix}: {i} anchored in more than one place: {', '.join(mine[i])}")

        # 2. liftability
        if prefix == "MSC":
            body = text.split("\n---\n", 1)[-1]  # the frontmatter names the sibling skill
            for tok in LEVEL1_FORBIDDEN:
                for n, line in enumerate(body.splitlines(), 1):
                    if tok.lower() in line.lower():
                        fails.append(f"MSC: level-1 skill names '{tok}' at line {n} — that is level 2")
                        break

        # 3. numbers cite the log
        missing = sorted(t for t in numbers(text) if t not in log_text)
        if verbose:
            print(f"  {prefix}: {len(numbers(text))} numeric tokens quoted")
        if missing:
            fails.append(f"{prefix}: number(s) quoted but in NO log: {', '.join(missing)}")
    return fails


SYN_SKILL = ("---\nname: x\ndescription: y\n---\n"
             "- [XX-1] rule one, see [YY-9] and 0x600000 and 2609\n- [XX-2] rule two\n")
SYN_DOC = "text **[XX-1]** anchor one. Also **[XX-2]** anchor two. plain [XX-3] is a ref\n"
SYN_LOG = "the log says 0x600000 and 2609\n"


def selftests():
    bad = []
    if skill_defs(SYN_SKILL) != ["XX-1", "XX-2"]:
        bad.append("skill extractor no longer matches the definition syntax")
    if doc_anchors(SYN_DOC) != ["XX-1", "XX-2"]:
        bad.append("doc extractor no longer matches the anchor syntax (or counts a plain ref)")
    if "YY-9" in skill_defs(SYN_SKILL):
        bad.append("a cross-reference was read as a definition")
    if numbers("see 0x600000, 2609, 66,265,152, 0.125, $FF8058, 46fc74af, 12 MB, 2026") != \
            {"0x600000", "2609", "66,265,152", "0.125", "$FF8058", "46fc74af"}:
        bad.append(f"number extractor drifted: {numbers('see 0x600000, 2609, 66,265,152, 0.125, $FF8058, 46fc74af, 12 MB, 2026')}")

    # Build a synthetic tree and run the real check() on it, with the module's
    # tables swapped to the synthetic pair.
    global SKILLS, ANCHOR_DOCS, LOG_DOCS, LEVEL1_FORBIDDEN
    saved = (SKILLS, ANCHOR_DOCS, LOG_DOCS, LEVEL1_FORBIDDEN)
    try:
        SKILLS = {"XX": "skill.md"}
        ANCHOR_DOCS = ["doc.md"]
        LOG_DOCS = ["log.md"]
        LEVEL1_FORBIDDEN = ["vsav"]
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)

            def write(skill=SYN_SKILL, doc=SYN_DOC, log=SYN_LOG):
                (root / "skill.md").write_text(skill)
                (root / "doc.md").write_text(doc)
                (root / "log.md").write_text(log)

            write()
            if check(root):
                bad.append(f"a matched synthetic tree FAILS — the checks are wrong: {check(root)}")
            write(skill=SYN_SKILL + "- [XX-3] unanchored\n")
            if not any("ANCHORED NOWHERE" in f for f in check(root)):
                bad.append("an unanchored rule was not caught")
            write(doc=SYN_DOC + "**[XX-4]** orphan\n")
            if not any("NOT DEFINED" in f for f in check(root)):
                bad.append("an orphan anchor was not caught")
            write(doc=SYN_DOC + "again **[XX-1]**\n")
            if not any("more than one place" in f for f in check(root)):
                bad.append("a duplicate anchor was not caught")
            write(skill=SYN_SKILL + "- [XX-2] again\n")
            if not any("duplicate definition" in f for f in check(root)):
                bad.append("a duplicate definition was not caught")
            write(skill=SYN_SKILL + "- [ZZ-1] wrong tier\n")
            if not any("foreign-prefix" in f for f in check(root)):
                bad.append("a foreign-prefix definition was not caught")
            write(skill=SYN_SKILL + "- [XX-2] x\n")  # reset below
            write(skill=SYN_SKILL.replace("rule two", "rule two about vsav"))
            SKILLS = {"MSC": "skill.md"}
            write(skill=SYN_SKILL.replace("XX-", "MSC-").replace("rule two", "rule two about VSAV"),
                  doc=SYN_DOC.replace("XX-", "MSC-"))
            if not any("level-1 skill names" in f for f in check(root)):
                bad.append("a game-specific token in the level-1 skill was not caught")
            SKILLS = {"XX": "skill.md"}
            write(skill=SYN_SKILL.replace("rule two", "rule two quotes 0x123456"))
            if not any("in NO log" in f for f in check(root)):
                bad.append("a number missing from every log was not caught")
    finally:
        SKILLS, ANCHOR_DOCS, LOG_DOCS, LEVEL1_FORBIDDEN = saved
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--root", default=str(REPO), help="tree to check (default: this repo)")
    ap.add_argument("--no-selftest", action="store_true")
    args = ap.parse_args()

    fails = check(args.root, args.verbose)
    if not args.no_selftest:
        fails += [f"SELF-TEST: {b}" for b in selftests()]
    if fails:
        for line in fails:
            print(f"  FAIL  {line}")
        print(f"\n{len(fails)} problem(s) between the skills and the docs")
        sys.exit(1)
    n = sum(len(skill_defs((Path(args.root) / rel).read_text())) for rel in SKILLS.values())
    print(f"ALL PASS ({n} rules across {len(SKILLS)} skills: every rule anchored once, "
          "every anchor defined, level 1 game-free, every number in a log)")


if __name__ == "__main__":
    main()
