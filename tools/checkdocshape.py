#!/usr/bin/env python3
"""checkdocshape.py — every hand-written doc's SHAPE is declared and enforced.

  python3 tools/checkdocshape.py                # check the tree, then self-test
  python3 tools/checkdocshape.py --only PATH    # lint one file (a doc commit's check)
  python3 tools/checkdocshape.py --no-pending   # PENDING rows fail too (the end state)
  python3 tools/checkdocshape.py --list-files   # every file the gate's copies need
  python3 tools/checkdocshape.py --root DIR     # a copy of the tree (controls)

WHY THIS EXISTS (14z-122, the documentation rationalization pass). The
maintainer's brief: reference documents had been appended with session-by-
session discovery logs until looking one fact up meant reading chronology.
The pass moves that chronology into `<name>_history.md` twins — and THIS
gate is what stops it growing back: a document declared REFERENCE may not
gain a session-shaped header again.

THE DECLARATION (`docs/doc_shape.tsv`): path, class, history_twin, requires —
classes and their rules are documented in the TSV header. COMPLETENESS: every
`.md` under docs/ (excluding docs/project/tables/chars/, which is generated
wholesale) plus HANDOFF.md must have a row, so a new document is classified
at birth.

THE HEADER RULE (REFERENCE and REGISTER): for each `#`..`###` header line,
one TRAILING parenthetical group is stripped — a scanner, tolerant of an
unclosed group at end-of-line (headers wrap) — but only when it opens with a
provenance word (paid/measured/ruled/...) or CONTAINS a session token, and
never when the group carries a retraction/history word (those must stay
visible); the residue must not look like chronology:
`14z-N` / `Session N` / a date / "appended 14z" (the digest style;
bare "appended" is a GAME term — the ROM-appended window/cells) /
"(HISTORY" / "superseded" /
"second|third pass" / "RETRACTED". So
  `## Hitboxes and attack records (measured 14z-120)`   passes
  `### 14z-70: the explosion's tiles LOCATED`           fails.
Allowances live in docs/doc_shape_allow.tsv; a row matching no header FAILS
as dead, so the list cannot outlive its reasons.

ALSO CHECKED: ORIENT = one `# ` header, no `(HISTORY` header (the twin holds
history); HIST = carries no `**[PFX-N]**` anchor; every named history_twin
exists and is classed HIST; `requires` = banner (a `**STATUS` line in the
first 40 lines) / atlas-rows (every `## ` section names an atlas file — a
`## ` line directly after another is the same header WRAPPED, one section);
LINKS — every markdown link or backticked `docs/...md` path in docs/README.md,
HANDOFF.md and CLAUDE.md resolves; CITATIONS — every `docs/x.md 'Section'`
quoted-section citation in tools/ and tests/ names a real header of that file
(the `x.md §N` numeric form is NOT checked — section numbers are too loosely
written to verify; the quoted-string form is the load-bearing one).
ROM-free, emulator-free, ~1 s (ci_portable, tests/test_docshape.sh).
"""
import argparse
import re
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SHAPE_TSV = "docs/doc_shape.tsv"
ALLOW_TSV = "docs/doc_shape_allow.tsv"
CLASSES = {"REFERENCE", "REGISTER", "LOG", "HIST", "ORIENT", "INDEX",
           "GENERATED", "EXEMPT", "PENDING"}
LINT_CLASSES = {"REFERENCE", "REGISTER"}

HEADER_RE = re.compile(r"^(#{1,3})\s+(.*)$")
ANCHOR_RE = re.compile(r"\*\*\[[A-Z]+-\d+\]\*\*")
SESSION_TOKEN = re.compile(r"(?i)\b14z-\d+[a-z]?\b|\bsession \d|\b20\d\d-\d\d-\d\d\b")
CHRONO = re.compile(r"(?i)\b14z-\d+[a-z]?\b|\bsession \d|\b20\d\d-\d\d-\d\d\b"
                    r"|\bappended 14z|\(HISTORY|\bsuperseded\b"
                    r"|\b(second|third) pass\b|\bRETRACT(S|ED)?\b")
PROVENANCE_OPENER = re.compile(
    r"(?i)^\((paid|measured|named|session|ruled|opened|audited|static|confirmed"
    r"|as built|since|decided|frozen|re-pointed|corrected|updated|rewritten"
    r"|maintainer|the previous|superseded)\b")
ATLAS_NAMES = ("atlas", "ram.md", "character_tables.md", "id_space.md",
               "select_screen.md", "sprite_lists.md", "venue_assets.md")
LINK_RE = re.compile(r"\]\(([^)#\s]+\.md)\)|`(docs/[\w./-]+\.md)`")
CITATION_RE = re.compile(r"(docs/[\w./-]+\.md)\s+\"([^\"]{3,90})\"")
LINK_DOCS = ["docs/README.md", "HANDOFF.md", "CLAUDE.md"]
CITATION_DIRS = ["tools", "tests"]


def strip_trailing_paren(text):
    """Strip ONE trailing parenthetical group opened by a provenance word or a
    session token. Tolerates an unclosed group (wrapped header). Returns the
    residue (the group itself is discarded from the lint's view)."""
    t = text.rstrip()
    # find the last top-level '(' whose group runs to the end of the line
    # (closed at the very end, or never closed = wrapped)
    depth = 0
    start = None
    for idx, ch in enumerate(t):
        if ch == "(":
            if depth == 0:
                start = idx
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)
            if depth == 0 and idx != len(t) - 1:
                start = None  # the group closed before the end: not trailing
    if start is None:
        return t
    group = t[start:]
    keep_words = re.search(r"(?i)RETRACT|supersed|appended|second pass|third pass|HISTORY", group)
    if not keep_words and (PROVENANCE_OPENER.match(group) or SESSION_TOKEN.search(group)):
        return t[:start].rstrip()
    return t


def read_shape(root, path=SHAPE_TSV):
    rows = {}
    p = root / path
    if not p.is_file():
        raise SystemExit(f"FAIL: no shape table at {p}")
    for ln, line in enumerate(p.read_text().splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        cols = [c.strip() for c in line.split("\t")]
        if len(cols) < 4:
            raise SystemExit(f"{path}:{ln}: expected 4 tab-separated columns, got {len(cols)}")
        rel, cls, twin, req = cols[:4]
        if cls not in CLASSES:
            raise SystemExit(f"{path}:{ln}: unknown class {cls!r}")
        rows[rel] = dict(cls=cls, twin=None if twin == "-" else twin,
                         req=[] if req == "-" else [r.strip() for r in req.split(",")],
                         line=ln)
    return rows


def read_allow(root, path=ALLOW_TSV):
    rows = []
    p = root / path
    if not p.is_file():
        return rows
    for ln, line in enumerate(p.read_text().splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        cols = [c.strip() for c in line.split("\t")]
        if len(cols) < 3:
            raise SystemExit(f"{path}:{ln}: expected 3 tab-separated columns")
        rows.append(dict(rel=cols[0], rx=re.compile(cols[1]), reason=cols[2],
                         line=ln, hit=False))
    return rows


def walk_docs(root):
    rels = {"HANDOFF.md"}
    for p in (root / "docs").rglob("*.md"):
        rel = p.relative_to(root).as_posix()
        if rel.startswith("docs/project/tables/chars/"):
            continue
        rels.add(rel)
    return sorted(r for r in rels if (root / r).is_file())


def lint_headers(rel, text, cls, allows):
    fails = []
    lines = text.splitlines()
    for n, line in enumerate(lines, 1):
        m = HEADER_RE.match(line)
        if not m:
            continue
        # consecutive header lines of the SAME level are one WRAPPED header
        # (the gotchas-bucket convention; gen_gotchas_index merges them too):
        # lint the merged text once, at the first line.
        if n >= 2 and lines[n-2].startswith(m.group(1) + " "):
            continue
        merged = m.group(2)
        k = n
        while k < len(lines) and lines[k].startswith(m.group(1) + " "):
            merged += " " + lines[k][len(m.group(1)) + 1:]
            k += 1
        residue = strip_trailing_paren(merged)
        cm = CHRONO.search(residue)
        if not cm:
            continue
        allowed = False
        for a in allows:
            if a["rel"] == rel and a["rx"].search(line):
                a["hit"] = True
                allowed = True
        if not allowed:
            fails.append(f"{rel}:{n} SESSION-SHAPED HEADER in a {cls} doc "
                         f"('{cm.group(0)}'): {line.strip()[:110]}")
    return fails


def check_file(root, rel, row, allows, no_pending):
    fails = []
    p = root / rel
    if not p.is_file():
        return [f"{rel}: declared in {SHAPE_TSV} but MISSING from the tree"]
    cls = row["cls"]
    if cls == "PENDING":
        return [f"{rel}: still PENDING"] if no_pending else []
    text = p.read_text(encoding="utf-8", errors="replace")
    if cls in LINT_CLASSES:
        fails += lint_headers(rel, text, cls, allows)
    if cls == "ORIENT":
        h1 = [ln for ln, l in enumerate(text.splitlines(), 1) if re.match(r"^# ", l)]
        if len(h1) != 1:
            fails.append(f"{rel}: ORIENT doc must have exactly one '# ' header, has {len(h1)}")
        for n, l in enumerate(text.splitlines(), 1):
            if HEADER_RE.match(l) and "(HISTORY" in l:
                fails.append(f"{rel}:{n} ORIENT doc carries a (HISTORY header — that lives in the twin")
    if cls == "HIST":
        for n, l in enumerate(text.splitlines(), 1):
            if ANCHOR_RE.search(l):
                fails.append(f"{rel}:{n} ANCHOR IN HISTORY-class doc: {l.strip()[:90]}")
    if row["twin"]:
        pass  # twin existence/class is checked at table level
    if "banner" in row["req"]:
        head = "\n".join(text.splitlines()[:40])
        if not re.search(r"\*\*STATUS", head, re.IGNORECASE):
            fails.append(f"{rel}: NO STATUS BANNER in the first 40 lines (requires banner)")
    if "atlas-rows" in row["req"]:
        for s in h2_sections(text):
            title = s.splitlines()[0][:60]
            if not any(a in s for a in ATLAS_NAMES):
                fails.append(f"{rel}: section '## {title}' names no atlas row (requires atlas-rows)")
    return fails


def h2_sections(text):
    """The `## ` sections of a doc, WRAP-AWARE: a `## ` line that directly
    follows another `## ` line is the same header wrapped (the house style
    for long section titles), not a new, empty section. Returns each section
    as its text without the leading `## ` (the first line is the title)."""
    secs, cur, prev_h2 = [], None, False
    for line in text.splitlines(keepends=True):
        is_h2 = line.startswith("## ")
        if is_h2 and not prev_h2:
            if cur is not None:
                secs.append(cur)
            cur = line[3:]
        elif cur is not None:
            cur += line
        prev_h2 = is_h2
    if cur is not None:
        secs.append(cur)
    return secs


def check_links(root):
    fails = []
    for rel in LINK_DOCS:
        p = root / rel
        if not p.is_file():
            continue
        base = p.parent
        for n, line in enumerate(p.read_text(errors="replace").splitlines(), 1):
            for m in LINK_RE.finditer(line):
                tgt = m.group(1) or m.group(2)
                if tgt.startswith(("http:", "https:")):
                    continue
                cand = (base / tgt) if m.group(1) else (root / tgt)
                if not cand.is_file() and not (root / tgt).is_file():
                    fails.append(f"{rel}:{n} DANGLING LINK: {tgt}")
    return fails


def check_citations(root):
    fails = []
    for d in CITATION_DIRS:
        dp = root / d
        if not dp.is_dir():
            continue
        for p in sorted(dp.rglob("*")):
            if p.suffix not in (".py", ".sh", ".lua", ".md", ".txt") or not p.is_file():
                continue
            rel = p.relative_to(root).as_posix()
            try:
                text = p.read_text(errors="replace")
            except OSError:
                continue
            for n, line in enumerate(text.splitlines(), 1):
                for m in CITATION_RE.finditer(line):
                    doc, quoted = m.group(1), m.group(2)
                    dpth = root / doc
                    if not dpth.is_file():
                        fails.append(f"{rel}:{n} CITES A MISSING DOC: {doc}")
                        continue
                    hdrs = " \n ".join(
                        ANCHOR_RE.sub("", h.group(2)).replace("`", "").lower()
                        for h in (HEADER_RE.match(l) for l in dpth.read_text(errors="replace").splitlines())
                        if h)
                    want = quoted.replace("`", "").lower()
                    if want.endswith("..."):
                        want = want[:-3].rstrip()  # an ellipsis-truncated title
                    if want not in hdrs:
                        fails.append(f"{rel}:{n} CITES A SECTION THAT DOES NOT EXIST: "
                                     f"{doc} \"{quoted}\"")
    return fails


def check(root, only=None, no_pending=False, verbose=False):
    fails = []
    shape = read_shape(root)
    allows = read_allow(root)
    # completeness both ways
    walked = walk_docs(root)
    for rel in walked:
        if rel not in shape:
            fails.append(f"UNDECLARED {rel} — add a row to {SHAPE_TSV}")
    # twins exist and are HIST
    for rel, row in shape.items():
        if row["twin"]:
            if row["twin"] not in shape:
                fails.append(f"{rel}: history_twin {row['twin']} has no row")
            elif shape[row["twin"]]["cls"] != "HIST":
                fails.append(f"{rel}: history_twin {row['twin']} is not classed HIST")
    pending = [r for r, row in shape.items() if row["cls"] == "PENDING"]
    for rel, row in sorted(shape.items()):
        if only and rel != only:
            continue
        fails += check_file(root, rel, row, allows, no_pending)
    if only is None:
        for a in allows:
            if not a["hit"]:
                # a row for a file we did not lint (PENDING) is not dead yet
                if shape.get(a["rel"], {}).get("cls") in LINT_CLASSES:
                    fails.append(f"{ALLOW_TSV}:{a['line']} dead allow row for {a['rel']} "
                                 f"(matches no header): {a['rx'].pattern}")
        fails += check_links(root)
        fails += check_citations(root)
    if verbose:
        print(f"  {len(shape)} declared ({len(pending)} PENDING), {len(walked)} walked")
    return fails, pending


def selftests():
    bad = []
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / "docs").mkdir()
        (root / "tools").mkdir()
        (root / "tests").mkdir()

        def shape(rows):
            (root / SHAPE_TSV).write_text(
                "\n".join("\t".join(r) for r in rows) + "\n")

        def doc(rel, body):
            (root / rel).parent.mkdir(parents=True, exist_ok=True)
            (root / rel).write_text(body)

        doc("HANDOFF.md", "# H\n")
        doc("docs/a.md", "# A file\n## Topic one (measured 14z-101)\nfacts\n")
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "REFERENCE", "-", "-")])
        f, _ = check(root)
        if f:
            bad.append(f"a clean synthetic tree fails: {f}")
        # a provenance suffix passes; a chronology header fails
        doc("docs/a.md", "# A file\n### 14z-70: the tiles LOCATED\n")
        f, _ = check(root)
        if not any("SESSION-SHAPED" in x for x in f):
            bad.append("a chronology header was not caught")
        # the paren-stripper tolerates a wrapped (unclosed) group
        if strip_trailing_paren("Hitboxes (phase 2 of the map, 14z-120 (5),") != "Hitboxes":
            bad.append(f"unclosed trailing group not stripped: "
                       f"{strip_trailing_paren('Hitboxes (phase 2 of the map, 14z-120 (5),')!r}")
        if strip_trailing_paren("The (real) thing (paid: 14z-95)") != "The (real) thing":
            bad.append("closed trailing provenance group not stripped")
        if strip_trailing_paren("A (14z-70) middle group") == "A":
            bad.append("a NON-trailing group was stripped")
        # ORIENT: one # header, no (HISTORY
        doc("docs/a.md", "# One\n## (HISTORY) old opener\n")
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "ORIENT", "-", "-")])
        f, _ = check(root)
        if not any("(HISTORY header" in x for x in f):
            bad.append("an ORIENT (HISTORY header was not caught")
        # HIST: no anchors
        doc("docs/a.md", "old text **[VSE-1]** moved here\n")
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "HIST", "-", "-")])
        f, _ = check(root)
        if not any("ANCHOR IN HISTORY" in x for x in f):
            bad.append("an anchor in a HIST doc was not caught")
        # completeness: an undeclared doc fails
        doc("docs/b.md", "# B\n")
        f, _ = check(root)
        if not any("UNDECLARED docs/b.md" in x for x in f):
            bad.append("an undeclared doc was not caught")
        (root / "docs/b.md").unlink()
        # a twin must exist and be HIST
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "LOG", "docs/x_history.md", "-")])
        f, _ = check(root)
        if not any("has no row" in x for x in f):
            bad.append("a missing twin row was not caught")
        # banner requirement
        doc("docs/a.md", "# A\ncontent\n")
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "REFERENCE", "-", "banner")])
        f, _ = check(root)
        if not any("NO STATUS BANNER" in x for x in f):
            bad.append("a missing banner was not caught")
        # atlas-rows: a WRAPPED `## ` header is one section (its body names
        # the atlas), and a section naming no atlas file still fails
        doc("docs/a.md", "# A\n## A long title that wraps onto a\n## second header line\n"
            "Atlas rows: `atlas/ram.md`.\n## Bare section\nnothing named\n")
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "REFERENCE", "-", "atlas-rows")])
        f, _ = check(root)
        atlas_f = [x for x in f if "names no atlas row" in x]
        if any("second header line" in x or "A long title" in x for x in atlas_f):
            bad.append("a wrapped `## ` header was split into an empty section")
        if not any("Bare section" in x for x in atlas_f):
            bad.append("a section naming no atlas row was not caught")
        # dangling link in README
        doc("docs/a.md", "# A\n")
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "REFERENCE", "-", "-"),
               ("docs/README.md", "INDEX", "-", "-")])
        doc("docs/README.md", "# idx\nsee [x](nope.md)\n")
        f, _ = check(root)
        if not any("DANGLING LINK" in x for x in f):
            bad.append("a dangling link was not caught")
        doc("docs/README.md", "# idx\n")
        (root / "docs/README.md").unlink()
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "REFERENCE", "-", "-")])
        # a citation of a nonexistent section
        (root / "tools/t.py").write_text('# see docs/a.md \x22A Section That Is Not There\x22\n')
        f, _ = check(root)
        if not any("SECTION THAT DOES NOT EXIST" in x for x in f):
            bad.append("a bad quoted-section citation was not caught")
        (root / "tools/t.py").write_text('# see docs/a.md \x22A\x22\n')
        f, _ = check(root)
        if any("SECTION" in x for x in f):
            bad.append("a good quoted-section citation was rejected")
        # dead allow row
        (root / ALLOW_TSV).write_text("docs/a.md\tnever-matches-anything\twhy\n")
        f, _ = check(root)
        if not any("dead allow row" in x for x in f):
            bad.append("a dead allow row was not caught")
        (root / ALLOW_TSV).unlink()
        # PENDING skips, --no-pending fails
        doc("docs/a.md", "### 14z-70: chronology\n")
        shape([("HANDOFF.md", "EXEMPT", "-", "-"), ("docs/a.md", "PENDING", "-", "-")])
        f, _ = check(root)
        if f:
            bad.append(f"a PENDING doc was linted: {f}")
        f, _ = check(root, no_pending=True)
        if not any("still PENDING" in x for x in f):
            bad.append("--no-pending did not fail a PENDING row")
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=str(REPO))
    ap.add_argument("--only", default=None, help="lint just this repo-relative doc")
    ap.add_argument("--no-pending", action="store_true")
    ap.add_argument("--list-files", action="store_true")
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--no-selftest", action="store_true")
    a = ap.parse_args()
    root = Path(a.root)
    if a.list_files:
        rels = set(walk_docs(root)) | {SHAPE_TSV, ALLOW_TSV, "CLAUDE.md"}
        print("\n".join(sorted(r for r in rels if (root / r).exists())))
        return
    fails, pending = check(root, a.only, a.no_pending, a.verbose)
    if not a.no_selftest:
        fails += [f"SELF-TEST: {b}" for b in selftests()]
    if fails:
        for f in fails:
            print(f"  FAIL  {f}")
        print(f"\n{len(fails)} problem(s)")
        sys.exit(1)
    scope = a.only or "the tree"
    print(f"ALL PASS ({scope}: shapes declared and enforced; "
          f"{len(pending)} still PENDING)")


if __name__ == "__main__":
    main()
