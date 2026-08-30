#!/usr/bin/env python3
"""doc_anchor_census.py — freeze WHERE every skill anchor lives: file AND section.

  python3 tools/doc_anchor_census.py --check            # diff against the frozen census
  python3 tools/doc_anchor_census.py --freeze           # rewrite the frozen census
  python3 tools/doc_anchor_census.py -v                 # print every row with its line
  python3 tools/doc_anchor_census.py --list-files       # every file this tool AND
                                                        #   checkskills.py read (for copies)
  python3 tools/doc_anchor_census.py --root DIR --check # a copy of the tree (controls)

WHY THIS EXISTS (14z-122, the documentation rationalization pass).
`tools/checkskills.py` locks every `- [PFX-N]` rule to exactly ONE
`**[PFX-N]**` anchor somewhere in that prefix's doc list. It never records
WHICH file or WHICH section — so an anchored paragraph moved between two
files of the same list, or from one section to another, is silently
accepted, and the skill keeps citing a paragraph that no longer says what it
said where it said it. A restructuring pass that moves hundreds of paragraphs
needs that movement to be a REVIEWED DIFF, not an invisible drift.

THE CENSUS. One row per anchor:  id  file  section  status
  section = the nearest preceding markdown header (anchor tokens stripped,
            whitespace collapsed, 100 chars), or "(top)"
  status  = IN-LIST      the file is in that prefix's `docs` list (checkskills)
            OUT-OF-LIST  the file is walked but not in the list (a stray token
                         in an archive — frozen as REVIEWED, so a new one diffs)
            HISTORY      the file is a `*_history.md` / `*_HISTORY.md` twin —
                         history carries NO anchors, so this is a hard failure
                         when the id is a rule a skill defines
Line numbers are printed with -v but NOT frozen: an edit above an anchor must
not churn the census; a MOVE must.

WHAT --check FAILS ON: (1) any difference from the frozen file (the diff is
printed — read every changed row; a section-only change is expected in a
doc commit, a file change must be named by the commit); (2) a defined rule
anchored in a HISTORY file; (3) a defined rule on more than one IN-LIST /
HISTORY row (checkskills catches the in-list half; this extends it to twins).

FILES WALKED: the union of every checkskills `docs` list, plus the archives
checkskills never reads (STATE_HISTORY.md, DECISIONS_HISTORY.md — the two
SESSION archives, which are not history twins and are never classed HISTORY;
docs/NEXT_SESSION.md, docs/GOTCHAS.md, docs/project/patch_notes.md), plus
every `*_history.md` / `*_HISTORY.md` under docs/ and the repo root, plus
every path declared in docs/doc_shape.tsv when that file exists (so the
shape lint and this census cannot disagree about what counts as a doc).
ROM-free, emulator-free, ~0.3 s (ci_portable, tests/test_doc_anchor_census.sh).
"""
import argparse
import difflib
import re
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import checkskills  # noqa: E402  (SKILLS, ANCHOR_DOC, skill_defs)

REPO = HERE.parent
EXPECTED = "tests/expected/doc_anchor_census.tsv"
EXTRA_FILES = ["STATE_HISTORY.md", "DECISIONS_HISTORY.md", "docs/NEXT_SESSION.md",
               "docs/GOTCHAS.md", "docs/project/patch_notes.md"]
HISTORY_RE = re.compile(r"_(history|HISTORY)\.md$")
# The two SESSION archives predate the pass and are not twins of a reference
# document: they are walked (a stray token there is a reviewed OUT-OF-LIST
# row) but never classed HISTORY.
SESSION_ARCHIVES = {"STATE_HISTORY.md", "DECISIONS_HISTORY.md"}
HEADER_RE = re.compile(r"^(#{1,6})\s+(.*)$")
SECTION_MAX = 100


def is_history(rel):
    return rel not in SESSION_ARCHIVES and bool(HISTORY_RE.search(rel))


def walk_files(root, skills=None):
    """Repo-relative paths this census reads, sorted, existing only."""
    skills = skills if skills is not None else checkskills.SKILLS
    rels = set()
    for cfg in skills.values():
        rels.update(cfg["docs"])
    rels.update(EXTRA_FILES)
    for pattern in ("*_history.md", "*_HISTORY.md", "docs/**/*_history.md", "docs/**/*_HISTORY.md"):
        for p in root.glob(pattern):
            rels.add(p.relative_to(root).as_posix())
    shape = root / "docs" / "doc_shape.tsv"
    if shape.is_file():
        for line in shape.read_text().splitlines():
            if line.strip() and not line.lstrip().startswith("#"):
                rels.add(line.split("\t")[0].strip())
    return sorted(r for r in rels if (root / r).is_file())


def section_name(header_text):
    t = checkskills.ANCHOR_DOC.sub("", header_text)
    t = re.sub(r"\s+", " ", t).strip()
    return t[:SECTION_MAX] if t else "(untitled)"


def census(root, skills=None):
    """Return rows (id, file, section, status, line) over the walked files."""
    skills = skills if skills is not None else checkskills.SKILLS
    in_list = {prefix: set(cfg["docs"]) for prefix, cfg in skills.items()}
    rows = []
    for rel in walk_files(root, skills):
        text = (root / rel).read_text(encoding="utf-8", errors="replace")
        section = "(top)"
        for n, line in enumerate(text.splitlines(), 1):
            m = HEADER_RE.match(line)
            if m:
                section = section_name(m.group(2))
            for am in checkskills.ANCHOR_DOC.finditer(line):
                i = am.group(1)
                prefix = i.split("-")[0]
                if is_history(rel):
                    status = "HISTORY"
                elif rel in in_list.get(prefix, set()):
                    status = "IN-LIST"
                else:
                    status = "OUT-OF-LIST"
                rows.append((i, rel, section, status, n))

    def key(r):
        p, num = r[0].split("-")
        return (p, int(num), r[1], r[4])
    return sorted(rows, key=key)


def render(rows):
    out = ["# tests/expected/doc_anchor_census.tsv — every skill anchor's FILE and SECTION,",
           "# frozen by tools/doc_anchor_census.py --freeze (gate tests/test_doc_anchor_census.sh).",
           "# A changed row is a MOVED anchor: review it, then --freeze in the same commit.",
           "# id\tfile\tsection\tstatus"]
    out += ["\t".join(r[:4]) for r in rows]
    return "\n".join(out) + "\n"


def hard_failures(root, rows, skills=None):
    skills = skills if skills is not None else checkskills.SKILLS
    defined = set()
    for cfg in skills.values():
        p = root / cfg["path"]
        if p.is_file():
            defined.update(checkskills.skill_defs(p.read_text(encoding="utf-8")))
    fails = []
    seen = {}
    for i, rel, section, status, n in rows:
        if i not in defined:
            continue
        if status == "HISTORY":
            fails.append(f"{i} anchored in HISTORY file {rel}:{n} — history carries no anchors")
        if status in ("IN-LIST", "HISTORY"):
            seen.setdefault(i, []).append(f"{rel}:{n}")
    for i, locs in sorted(seen.items()):
        if len(locs) > 1:
            fails.append(f"{i} anchored on more than one row: {', '.join(locs)}")
    return fails


def check(root, expected_path, verbose=False, skills=None):
    rows = census(root, skills)
    fails = hard_failures(root, rows, skills)
    got = render(rows)
    exp_file = root / expected_path
    if not exp_file.is_file():
        fails.append(f"no frozen census at {expected_path} — run --freeze first")
    else:
        want = exp_file.read_text()
        if want != got:
            diff = difflib.unified_diff(want.splitlines(), got.splitlines(),
                                        "frozen", "tree", lineterm="", n=0)
            lines = [d for d in diff if not d.startswith(("---", "+++", "@@"))]
            fails.append("census DIFFERS from the frozen file — moved anchor(s):\n      "
                         + "\n      ".join(lines[:60])
                         + ("\n      ..." if len(lines) > 60 else ""))
    if verbose:
        for i, rel, section, status, n in rows:
            print(f"  {i:<9} {status:<11} {rel}:{n}  § {section}")
    return fails, rows


SYN_SKILL = "---\nname: x\ndescription: y\n---\n- [XX-1] one\n- [XX-2] two\n"


def selftests():
    bad = []
    saved = checkskills.SKILLS
    try:
        skills = {"XX": dict(path="skill.md", docs=["doc.md"], logs=["doc.md"], forbid=[])}
        checkskills.SKILLS = skills
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "skill.md").write_text(SYN_SKILL)
            (root / "doc.md").write_text("# Top\ntext **[XX-1]** a\n\n## Second **[ZZ-9]** part\n**[XX-2]** b\n")
            rows = census(root, skills)
            got = [(r[0], r[2], r[3]) for r in rows]
            want = [("XX-1", "Top", "IN-LIST"), ("XX-2", "Second part", "IN-LIST"),
                    ("ZZ-9", "Second part", "OUT-OF-LIST")]
            if got != want:
                bad.append(f"census extractor drifted: {got}")
            if hard_failures(root, rows, skills):
                bad.append("a clean synthetic tree reports hard failures")
            # a section move changes the frozen rendering
            (root / "doc.md").write_text("# Top\n\n## Moved\ntext **[XX-1]** a\n\n## Second\n**[XX-2]** b\n")
            if render(census(root, skills)) == render(rows):
                bad.append("a section move did not change the census")
            # a defined rule anchored in a history twin is a hard failure
            (root / "doc_history.md").write_text("## old\n**[XX-2]** moved here\n")
            fails = hard_failures(root, census(root, skills), skills)
            if not any("HISTORY file" in f for f in fails):
                bad.append("an anchor in a history file was not caught")
            (root / "doc_history.md").unlink()
            # the same rule on two in-list rows is a hard failure
            (root / "doc.md").write_text("**[XX-1]** a\n**[XX-1]** again\n**[XX-2]** b\n")
            if not any("more than one row" in f for f in hard_failures(root, census(root, skills), skills)):
                bad.append("a duplicated anchor was not caught")
            # an undefined stray token is a row, never a failure
            (root / "doc.md").write_text("**[XX-1]** a\n**[XX-2]** b\n")
            (root / "doc_history.md").write_text("**[QQ-1]** stray\n")
            if hard_failures(root, census(root, skills), skills):
                bad.append("an undefined stray token was reported as a failure")
    finally:
        checkskills.SKILLS = saved
    return bad


def list_files(root):
    rels = set(walk_files(root))
    for cfg in checkskills.SKILLS.values():
        rels.add(cfg["path"])
        rels.update(cfg["docs"])
        rels.update(cfg["logs"])
    rels.add(EXPECTED)
    return sorted(r for r in rels if (root / r).exists())


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=str(REPO))
    ap.add_argument("--expected", default=EXPECTED)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--freeze", action="store_true")
    ap.add_argument("--list-files", action="store_true")
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--no-selftest", action="store_true")
    a = ap.parse_args()
    root = Path(a.root)

    if a.list_files:
        print("\n".join(list_files(root)))
        return
    if a.freeze:
        rows = census(root)
        fails = hard_failures(root, rows)
        if fails:
            for f in fails:
                print(f"  FAIL  {f}")
            sys.exit("refusing to freeze a census with hard failures")
        (root / a.expected).parent.mkdir(parents=True, exist_ok=True)
        (root / a.expected).write_text(render(rows))
        print(f"froze {len(rows)} anchor rows over {len(walk_files(root))} files -> {a.expected}")
        return

    fails, rows = check(root, a.expected, a.verbose)
    if not a.no_selftest:
        fails += [f"SELF-TEST: {b}" for b in selftests()]
    if fails:
        for f in fails:
            print(f"  FAIL  {f}")
        print(f"\n{len(fails)} problem(s)")
        sys.exit(1)
    n_in = sum(1 for r in rows if r[3] == "IN-LIST")
    n_out = sum(1 for r in rows if r[3] == "OUT-OF-LIST")
    print(f"ALL PASS ({len(rows)} anchors frozen by file+section: {n_in} in-list, "
          f"{n_out} reviewed out-of-list, 0 in history files)")


if __name__ == "__main__":
    main()
