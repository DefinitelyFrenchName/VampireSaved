#!/usr/bin/env python3
"""md_subset.py — the markdown SUBSET this corpus uses, parsed strictly.

  python3 tools/md_subset.py --census PATH...   # count constructs, never fail
  python3 tools/md_subset.py --check PATH...    # strict: an unsupported
                                                # construct is an error
  python3 tools/md_subset.py --html PATH        # render one file (a smoke test)

WHY THIS EXISTS (14z-140, living-docs slice L4). The rendered site
(`tools/mk_docs_site.py`) needs a markdown renderer and the pre-commit tier
has no dependencies, so this is a second implementation of markdown — which
is only safe if its subset is a CENSUS of what the corpus actually writes
rather than a guess. A construct outside the subset FAILS loudly here instead
of rendering wrong somewhere a reader would not notice. The census that
defined it is `docs/project/living_docs_scope.md` §9.2, and §9.3 is the four
things it found that the plan had not.

THE ORDER IS LOAD-BEARING: BLOCKS FIRST, INLINE SECOND. A paragraph's lines
are JOINED before the inline pass, because a code span can open on one source
line and close on the next — 34 of the corpus's `<name>`-shaped placeholders
live in such a span, and a line-based scanner splits them and then sees a
stray `<name>` in prose (measured 14z-140: a line-based census reported 76
raw-HTML violations where a block-based one reports 42).

THE SUBSET, and what is deliberately outside it:

  IN   headings h1-h3 (consecutive same-level lines with no blank between are
       ONE WRAPPED header, the house style `checkdocshape.h2_sections` and
       `gen_gotchas_index` already merge); paragraphs; ul/ol with one nesting
       level and joined continuations; pipe tables; fenced code with an info
       string; blockquotes; `---` rules; HTML comments (stripped); and inline
       code spans, links, `~~strike~~`, `**bold**`, `*italic*`.
  IN   `<details>` and `<summary>` — the ONLY raw HTML, 16 tags emitted by
       `tools/charmap_md.py` into the three generated `tables/chars/*.md` to
       fold long tables (ruled 2026-09-07, §9.8 decision 7).
  OUT  footnotes, images, task lists, autolinks, reference-link definitions,
       setext headings, 4-space code blocks, h4-h6, and every other HTML tag.
       All measured at ZERO occurrences in the corpus.

THREE RULES THE CORPUS FORCED, each of which a naive parser gets wrong and
each of which has a NEGATIVE control in `tests/test_md_subset.sh`:

  1. A CODE SPAN MAY WRAP a line break (above).
  2. `\\|` IS AN ESCAPED PIPE inside a table cell — 21 of them in 8 files. A
     naive split on `|` counts them and reads 15 tables in 9 files as ragged.
  3. A TABLE ROW'S LEADING PIPE IS OPTIONAL, as it is on GitHub — 22 rows in
     4 files rely on it, including `HANDOFF.md:45`, whose row opens with two
     bold anchor markers before the first pipe (ruled, §9.8 decision 9).

And a fourth, decision 8: a `<word>` in prose is TEXT. 26 placeholders —
`<name>`, `<build>`, `<tenant>`, `<seed>`, `<dir outside the repo>` — live in
prose across 22 files. `<...>` is escaped and renders as the author wrote it;
only a KNOWN HTML tag name outside a code span is an error.

Stdlib only, python 3.9. ROM-free, emulator-free (ci_portable,
tests/test_md_subset.sh).
"""
import argparse
import html as _html
import re
import sys
from collections import Counter
from pathlib import Path

# --- the subset's vocabulary -------------------------------------------------

# Raw HTML we accept, and nothing else (decision 7).
BLOCK_HTML_OK = ("details", "summary")

# Tag names a browser would ACT on. A `<...>` whose name is not in here is
# prose (decision 8) and is escaped; one that is, outside a code span, is an
# error. Deliberately a list of real tags rather than "any word", because the
# corpus writes `<tenant>` and `<dir outside the repo>` in English.
KNOWN_HTML = frozenset("""
a abbr address area article aside audio b base bdi bdo blockquote body br
button canvas caption cite code col colgroup data datalist dd del dfn dialog
div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6
head header hgroup hr html i iframe img input ins kbd label legend li link
main map mark menu meta meter nav noscript object ol optgroup option output p
param picture pre progress q rp rt ruby s samp script section select slot
small source span strong style sub summary sup table tbody td template
textarea tfoot th thead time title tr track u ul var video wbr details
""".split())

FENCE_RE   = re.compile(r"^\s*```(.*)$")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
RULE_RE    = re.compile(r"^\s*(-{3,}|\*{3,}|_{3,})\s*$")
ULI_RE     = re.compile(r"^(\s*)([-*+])\s+(.*)$")
OLI_RE     = re.compile(r"^(\s*)(\d+)[.)]\s+(.*)$")
BQ_RE      = re.compile(r"^\s*>\s?(.*)$")
HTML_OPEN  = re.compile(r"^\s*</?(%s)\b" % "|".join(BLOCK_HTML_OK))
# A code span: double backticks first (they may contain a single one).
CODESPAN_RE = re.compile(r"``(.+?)``|`([^`]*)`", re.S)
TAG_RE      = re.compile(r"</?([A-Za-z][A-Za-z0-9]*)(?:\s[^<>]*)?/?>")
LINK_RE     = re.compile(r"(!?)\[([^\]]*)\]\(([^)\s]*)\)")
STRIKE_RE   = re.compile(r"~~(.+?)~~", re.S)
BOLD_RE     = re.compile(r"\*\*(.+?)\*\*", re.S)
ITALIC_RE   = re.compile(r"(?<![*\w])\*([^*\s][^*]*)\*(?!\*)", re.S)
ANCHOR_RE   = re.compile(r"\[([A-Z]+-\d+)\]")

# constructs that are OUT, each measured at zero
FOOTNOTE_RE = re.compile(r"\[\^[^\]\s]+\]")
AUTOLINK_RE = re.compile(r"<https?://")
TASK_RE     = re.compile(r"^\s*[-*+]\s+\[[ xX]\]\s")
REFDEF_RE   = re.compile(r"^\[[^\]]+\]:\s+\S")
SETEXT_RE   = re.compile(r"^\s*(={3,})\s*$")


class SubsetError(Exception):
    """A construct outside the subset. Carries file:line:construct."""

    def __init__(self, path, line, construct, detail=""):
        self.path, self.line, self.construct, self.detail = path, line, construct, detail
        super().__init__("%s:%d: unsupported construct: %s%s"
                         % (path, line, construct, (" — " + detail) if detail else ""))


class Block(object):
    __slots__ = ("kind", "line", "meta", "text", "rows", "items")

    def __init__(self, kind, line, meta=None, text="", rows=None, items=None):
        self.kind, self.line, self.meta = kind, line, meta
        self.text, self.rows, self.items = text, rows or [], items or []

    def __repr__(self):
        return "Block(%s, line=%d, meta=%r)" % (self.kind, self.line, self.meta)


# --- table cells: `\|` is an ESCAPED PIPE, the leading pipe is OPTIONAL ------

def split_cells(row):
    """Split a table row into cells on UNESCAPED pipes OUTSIDE code spans.

    `\\|` is a literal pipe in a cell (rule 2) — a naive `row.split('|')`
    counts it and the row reads one cell too wide. The leading pipe is
    optional (rule 3), and the trailing one is dropped when present.

    AND A PIPE INSIDE A CODE SPAN IS CONTENT (rule 4). The corpus writes
    `` `WATCH=addr,len[,r|w|rw]` `` and `` `who ∈ p1|p2|sys` `` inside table
    cells; GFM would split there (it demands `\\|` even in a code span) and so
    would a naive splitter, which is four of the seven ragged rows the first
    strict pass found. Rendering the author's obvious intent is the better
    projection, and it is the only one under which those documents are right.
    """
    cells, cur, i, tick = [], [], 0, 0
    while i < len(row):
        ch = row[i]
        if ch == "\\" and i + 1 < len(row) and row[i + 1] == "|":
            cur.append("|"); i += 2; continue
        if ch == "`":
            run = len(row[i:]) - len(row[i:].lstrip("`"))
            if tick == 0:
                tick = run
            elif tick == run:
                tick = 0
            cur.append(row[i:i + run]); i += run; continue
        if ch == "|" and tick == 0:
            cells.append("".join(cur)); cur = []; i += 1; continue
        cur.append(ch); i += 1
    cells.append("".join(cur))
    if cells and not cells[0].strip():
        cells.pop(0)                      # a leading pipe, when there is one
    if cells and not cells[-1].strip():
        cells.pop()                       # the trailing pipe
    return [c.strip() for c in cells]


def is_table_row(line):
    """A table row: contains an unescaped pipe and ends with one. The leading
    pipe is optional, which is how HANDOFF.md:45 puts its anchor markers
    before the first cell."""
    s = line.rstrip()
    if not s.endswith("|"):
        return False
    body = s[:-1]
    return bool(re.search(r"(?<!\\)\|", body)) or s.lstrip().startswith("|")


def is_separator_row(line):
    return bool(re.match(r"^\s*\|?[\s:|-]+\|?\s*$", line)) and "-" in line


# --- the block pass ----------------------------------------------------------

def parse(text, path="<text>", strict=True):
    """Split into blocks, JOINING continuation lines. Blocks first, inline
    second — a code span may wrap a line break (rule 1)."""
    lines = text.splitlines()
    out, i, n = [], 0, len(lines)

    def bad(ln, construct, detail=""):
        if strict:
            raise SubsetError(path, ln, construct, detail)

    while i < n:
        line, ln = lines[i], i + 1

        m = FENCE_RE.match(line)
        if m:
            info, body = m.group(1).strip(), []
            i += 1
            while i < n and not FENCE_RE.match(lines[i]):
                body.append(lines[i]); i += 1
            if i >= n:
                bad(ln, "unclosed fenced code block")
            i += 1
            out.append(Block("fence", ln, info, "\n".join(body)))
            continue

        if not line.strip():
            i += 1
            continue

        if line.lstrip().startswith("<!--"):
            while i < n and "-->" not in lines[i]:
                i += 1
            i += 1
            out.append(Block("comment", ln))
            continue

        if HTML_OPEN.match(line):
            out.append(Block("html", ln, text=line.strip()))
            i += 1
            continue

        m = HEADING_RE.match(line)
        if m:
            level = len(m.group(1))
            if level > 3:
                bad(ln, "h%d heading" % level,
                    "the subset is h1-h3; the corpus has no h4+")
            parts = [m.group(2)]
            i += 1
            while i < n:
                m2 = HEADING_RE.match(lines[i])
                if not m2 or len(m2.group(1)) != level:
                    break
                parts.append(m2.group(2)); i += 1
            out.append(Block("heading", ln, level, " ".join(parts),
                             items=parts))          # items = the constituents
            continue

        if RULE_RE.match(line):
            out.append(Block("rule", ln)); i += 1; continue

        if SETEXT_RE.match(line) and out and out[-1].kind == "paragraph":
            bad(ln, "setext heading", "write `## Title` instead")

        # A TABLE REQUIRES ITS DELIMITER ROW, as GFM does (rule 6). Without
        # this, any prose line that happens to contain a pipe and end with one
        # opens a table — which is how a `bbh` subcommand list written inside a
        # wrapped code span became a 7-cell table, and how three "tables with
        # no separator row" appeared in the first census.
        if is_table_row(line) and i + 1 < n and is_separator_row(lines[i + 1]):
            rows = []
            while i < n and is_table_row(lines[i]):
                rows.append((i + 1, lines[i])); i += 1
            header = split_cells(rows[0][1])
            body, ragged = [], []
            sep_seen = False
            for rln, r in rows[1:]:
                if not sep_seen and is_separator_row(r):
                    sep_seen = True
                    continue
                cells = split_cells(r)
                if len(cells) != len(header):
                    # NOT fatal. A ragged row is a table that renders
                    # differently from what its author may have meant, not a
                    # construct outside the subset — and GFM renders it too,
                    # by padding and truncating. Failing on it would fail two
                    # ARCHIVES that are never rewritten ([VSP-17]). Normalise
                    # as GFM does and COUNT it, so the number is visible.
                    ragged.append(rln)
                    cells = (cells + [""] * len(header))[:len(header)]
                body.append(cells)
            blk = Block("table", ln, sep_seen, rows=[header] + body)
            blk.items = [("ragged", r) for r in ragged]
            out.append(blk)
            continue

        if BQ_RE.match(line):
            body = []
            while i < n and BQ_RE.match(lines[i]):
                body.append(BQ_RE.match(lines[i]).group(1)); i += 1
            out.append(Block("blockquote", ln, text=" ".join(body).strip()))
            continue

        mu, mo = ULI_RE.match(line), OLI_RE.match(line)
        if mu or mo:
            kind = "ul" if mu else "ol"
            items = []
            while i < n:
                m2 = ULI_RE.match(lines[i]) if kind == "ul" else OLI_RE.match(lines[i])
                other = OLI_RE.match(lines[i]) if kind == "ul" else ULI_RE.match(lines[i])
                if not m2:
                    if other or not lines[i].strip() or HEADING_RE.match(lines[i]) \
                       or FENCE_RE.match(lines[i]) or is_table_row(lines[i]) \
                       or RULE_RE.match(lines[i]):
                        break
                    if items:                     # a continuation line: JOIN it
                        items[-1] = (items[-1][0], items[-1][1] + " " + lines[i].strip())
                        i += 1
                        continue
                    break
                if TASK_RE.match(lines[i]):
                    bad(i + 1, "task list item")
                indent = len(m2.group(1))
                items.append((indent, m2.group(3)))
                i += 1
            out.append(Block("list", ln, kind, items=items))
            continue

        if REFDEF_RE.match(line):
            bad(ln, "reference-link definition")

        para, start = [], ln
        while i < n and lines[i].strip():
            l2 = lines[i]
            # ALWAYS consume the first line. Every block starter has been
            # tested above and declined it (a table-shaped line with no
            # delimiter row lands here), so breaking before consuming
            # anything is an infinite loop — which is exactly what rule 6
            # caused on its first run.
            # RULE 1 AT THE BLOCK LEVEL: while a code span is still OPEN, the
            # next line is this paragraph's continuation whatever it looks
            # like. `docs/NEXT_SESSION_HISTORY.md:109` opens a span listing
            # `bbh` subcommands separated by pipes; without this, line 110
            # matches is_table_row() and a paragraph becomes a 7-cell table.
            if para and _spans_open("".join(para)) == 0 and (
                    HEADING_RE.match(l2) or FENCE_RE.match(l2) or RULE_RE.match(l2)
                    or is_table_row(l2) or BQ_RE.match(l2) or ULI_RE.match(l2)
                    or OLI_RE.match(l2) or l2.lstrip().startswith("<!--")
                    or HTML_OPEN.match(l2)):
                break
            para.append(l2.strip()); i += 1
        out.append(Block("paragraph", start, text=" ".join(para)))

    if strict:
        for b in out:
            if b.kind in ("fence", "comment", "html"):
                continue
            for chunk in ([b.text] if b.kind != "table"
                          else [c for row in b.rows for c in row]):
                check_inline(chunk, path, b.line)
            for _, it in b.items if b.kind == "list" else []:
                check_inline(it, path, b.line)
    return out


def _spans_open(text):
    """The backtick run length of a code span left OPEN at the end of `text`,
    else 0 — the block splitter's test for rule 1 (a span may wrap a line)."""
    i, tick = 0, 0
    while i < len(text):
        if text[i] == "`":
            run = len(text[i:]) - len(text[i:].lstrip("`"))
            if tick == 0:
                tick = run
            elif tick == run:
                tick = 0
            i += run
            continue
        i += 1
    return tick


def _outside_code(text):
    """The text with every code span blanked, so an inline scan cannot see
    into one. This is what makes `<name>` inside backticks invisible."""
    return CODESPAN_RE.sub(lambda m: "\x00" * len(m.group(0)), text)


def check_inline(text, path, line):
    """The forbidden inline constructs, measured OUTSIDE code spans."""
    bare = _outside_code(text)
    for m in TAG_RE.finditer(bare):
        name = m.group(1).lower()
        if name in BLOCK_HTML_OK:
            continue
        if name in KNOWN_HTML:
            raise SubsetError(path, line, "raw HTML <%s>" % name,
                              "only %s are allowed; a `<word>` in prose is text"
                              % "/".join("<%s>" % t for t in BLOCK_HTML_OK))
    if FOOTNOTE_RE.search(bare):
        raise SubsetError(path, line, "footnote reference")
    if AUTOLINK_RE.search(bare):
        raise SubsetError(path, line, "autolink", "write [text](url)")
    for m in LINK_RE.finditer(bare):
        if m.group(1):
            raise SubsetError(path, line, "image", "the corpus has none")


# --- the inline pass ---------------------------------------------------------

def inline(text, link=None, code=None):
    """Render inline markup to HTML.

    Precedence: code span > link > strike > bold > italic; everything else is
    escaped. `link(target) -> href or None` rewrites a markdown link's target;
    `code(span) -> href or None` may turn a CODE SPAN into a link (the site's
    auto-link for `docs/...md` paths and address tokens, ruled scoped).
    """
    out, pos = [], 0
    for m in CODESPAN_RE.finditer(text):
        out.append(_inline_rest(text[pos:m.start()], link))
        span = m.group(1) if m.group(1) is not None else m.group(2)
        esc = _html.escape(span)
        href = code(span) if code else None
        out.append('<a class="cs" href="%s"><code>%s</code></a>' % (_html.escape(href), esc)
                   if href else "<code>%s</code>" % esc)
        pos = m.end()
    out.append(_inline_rest(text[pos:], link))
    return "".join(out)


def _inline_rest(text, link):
    s = _html.escape(text)

    def do_link(m):
        label, target = m.group(2), m.group(3)
        href = link(target) if link else target
        if href is None:
            return _html.escape("[%s](%s)" % (label, target))
        return '<a href="%s">%s</a>' % (_html.escape(href), _emph(label))

    # the label/target were escaped with the rest, so match on the escaped form
    s = re.sub(r"(!?)\[([^\]]*)\]\(([^)\s]*)\)", do_link, s)
    return _emph_done(s)


def _emph(s):
    return _emph_done(_html.escape(s))


def _emph_done(s):
    s = STRIKE_RE.sub(lambda m: "<s>%s</s>" % m.group(1), s)
    s = BOLD_RE.sub(lambda m: "<strong>%s</strong>" % m.group(1), s)
    s = ITALIC_RE.sub(lambda m: "<em>%s</em>" % m.group(1), s)
    return s


# --- rendering (the site adds its own chrome around this) --------------------

def to_html(blocks, slug=None, link=None, code=None):
    """Render blocks. `slug(text) -> id` gives a heading its anchor."""
    out = []
    for b in blocks:
        if b.kind == "comment":
            continue
        if b.kind == "html":
            out.append(b.text)
        elif b.kind == "fence":
            cls = ' class="lang-%s"' % _html.escape(b.meta) if b.meta else ""
            out.append("<pre><code%s>%s</code></pre>" % (cls, _html.escape(b.text)))
        elif b.kind == "heading":
            ids = ""
            if slug:
                ids = ' id="%s"' % _html.escape(slug(b.text))
            body = inline(b.text, link, code)
            extra = "".join('<a id="%s"></a>' % _html.escape(a)
                            for a in ANCHOR_RE.findall(b.text))
            out.append("<h%d%s>%s%s</h%d>" % (b.meta, ids, extra, body, b.meta))
        elif b.kind == "rule":
            out.append("<hr>")
        elif b.kind == "blockquote":
            out.append("<blockquote>%s</blockquote>" % inline(b.text, link, code))
        elif b.kind == "list":
            tag = b.meta
            items, depth = [], 0
            for indent, txt in b.items:
                want = 1 if indent else 0
                while depth < want:
                    items.append("<%s>" % tag); depth += 1
                while depth > want:
                    items.append("</%s>" % tag); depth -= 1
                items.append("<li>%s</li>" % inline(txt, link, code))
            items.append("</%s>" % tag * depth if depth else "")
            out.append("<%s>%s</%s>" % (tag, "".join(items), tag))
        elif b.kind == "table":
            head = b.rows[0]
            body = b.rows[1:]
            th = "".join("<th>%s</th>" % inline(c, link, code) for c in head)
            trs = "".join("<tr>%s</tr>" % "".join("<td>%s</td>" % inline(c, link, code)
                                                  for c in r) for r in body)
            out.append("<table><thead><tr>%s</tr></thead><tbody>%s</tbody></table>"
                       % (th, trs))
        else:
            out.append("<p>%s</p>" % inline(b.text, link, code))
    return "\n".join(out)


# --- census ------------------------------------------------------------------

def census(text, path="<text>"):
    c = Counter()
    blocks = parse(text, path, strict=False)
    for b in blocks:
        if b.kind == "heading":
            c["h%d" % b.meta] += 1
            if len(b.items) > 1:
                c["heading.wrapped"] += 1
        elif b.kind == "list":
            c["list." + b.meta] += len(b.items)
            c["list.%s.nested" % b.meta] += sum(1 for ind, _ in b.items if ind)
        elif b.kind == "table":
            c["table"] += 1
            c["table.rows"] += len(b.rows) - 1
            c["table.ragged"] += len(b.items)
            if not b.meta:
                c["table.no-separator"] += 1
        elif b.kind == "fence":
            c["fence"] += 1
            if b.meta:
                c["fence-info:" + b.meta] += 1
        else:
            c[b.kind] += 1
        chunks = ([c2 for row in b.rows for c2 in row] if b.kind == "table"
                  else [t for _, t in b.items] if b.kind == "list"
                  else [b.text])
        if b.kind in ("fence", "comment", "html"):
            continue
        for chunk in chunks:
            c["codespan"] += len(CODESPAN_RE.findall(chunk))
            bare = _outside_code(chunk)
            c["bold"] += len(BOLD_RE.findall(bare))
            c["italic"] += len(ITALIC_RE.findall(bare))
            c["strike"] += len(STRIKE_RE.findall(bare))
            for m in LINK_RE.finditer(bare):
                c["link"] += 1
                t = m.group(3)
                c["link.http" if t.startswith(("http://", "https://"))
                  else "link.md" if ".md" in t else "link.other"] += 1
            for m in TAG_RE.finditer(bare):
                nm = m.group(1).lower()
                c["html.ok" if nm in BLOCK_HTML_OK
                  else "html.KNOWN" if nm in KNOWN_HTML else "placeholder"] += 1
    return c


# --- selftests ---------------------------------------------------------------

def selftests():
    bad = []

    def want(label, text, cond, **kw):
        try:
            blocks = parse(text, "t.md", **kw)
        except SubsetError as e:
            bad.append("%s: raised %s" % (label, e)); return
        if not cond(blocks):
            bad.append("%s: parsed wrong: %r" % (label, blocks))

    def raises(label, text, construct):
        try:
            parse(text, "t.md")
        except SubsetError as e:
            if construct not in str(e):
                bad.append("%s: raised the wrong thing: %s" % (label, e))
            return
        bad.append("%s: did NOT raise" % label)

    # --- the supported constructs ---
    want("h1-h3", "# a\n\n## b\n\n### c\n",
         lambda b: [x.meta for x in b if x.kind == "heading"] == [1, 2, 3])
    want("wrapped heading", "## one\n## two\n",
         lambda b: len(b) == 1 and b[0].text == "one two" and len(b[0].items) == 2)
    want("paragraph joins its lines", "alpha\nbeta\n",
         lambda b: b[0].kind == "paragraph" and b[0].text == "alpha beta")
    want("list", "- a\n- b\n",
         lambda b: b[0].kind == "list" and len(b[0].items) == 2)
    want("list continuation joins", "- a\n  more\n- b\n",
         lambda b: b[0].items[0][1] == "a more")
    want("nested list", "- a\n  - b\n",
         lambda b: [i[0] for i in b[0].items] == [0, 2])
    want("ordered list", "1. a\n2. b\n",
         lambda b: b[0].kind == "list" and b[0].meta == "ol")
    want("fence", "```sh\nx | y\n```\n",
         lambda b: b[0].kind == "fence" and b[0].meta == "sh" and b[0].text == "x | y")
    want("blockquote", "> a\n> b\n",
         lambda b: b[0].kind == "blockquote" and b[0].text == "a b")
    want("rule", "---\n", lambda b: b[0].kind == "rule")
    want("comment stripped", "<!-- x -->\n", lambda b: b[0].kind == "comment")
    want("table", "| a | b |\n|---|---|\n| 1 | 2 |\n",
         lambda b: b[0].kind == "table" and b[0].rows == [["a", "b"], ["1", "2"]])

    # --- THE THREE RULES THE CORPUS FORCED (§9.3) ---
    want("rule 1: a code span may WRAP a line break",
         "see `tools/x.py <name>\n<out>` and stop\n",
         lambda b: b[0].kind == "paragraph")
    if census("a `<name>\nmore` b").get("placeholder"):
        bad.append("rule 1: a wrapped code span's <name> leaked into the census")
    want("rule 2: `\\|` is an escaped pipe",
         "| a | b |\n|---|---|\n| x \\| y | 2 |\n",
         lambda b: b[0].rows[1] == ["x | y", "2"])
    want("rule 3: the leading pipe is optional",
         "| a | b |\n|---|---|\n**[X-1]** x | 2 |\n",
         lambda b: b[0].kind == "table" and len(b[0].rows) == 2)
    want("decision 8: a <word> in prose is TEXT",
         "the build dir is <name> and <dir outside the repo>\n",
         lambda b: b[0].kind == "paragraph")
    want("decision 7: <details>/<summary> pass",
         "<details><summary>x</summary>\n\n| a |\n|---|\n\n</details>\n",
         lambda b: b[0].kind == "html")

    # --- the forbidden constructs, all measured at zero in the corpus ---
    raises("h4", "#### x\n", "h4 heading")
    raises("raw html", "a <div>x</div> b\n", "raw HTML <div>")
    raises("raw html b", "a <b>x</b> b\n", "raw HTML <b>")
    raises("footnote", "a[^1] b\n", "footnote")
    raises("image", "![alt](x.png)\n", "image")
    raises("autolink", "see <https://x.example> ok\n", "autolink")
    raises("task list", "- [ ] a\n", "task list")
    raises("reference-link definition", "[x]: http://e.example\n",
           "reference-link definition")
    # a ragged row is NORMALISED and COUNTED, never fatal (it would fail two
    # archives, and GFM renders it too) — so the assertion is on the count
    want("rule 5: a ragged row is normalised, not fatal",
         "| a | b |\n|---|---|\n| 1 | 2 | 3 |\n",
         lambda b: b[0].rows[1] == ["1", "2"] and len(b[0].items) == 1)
    if census("| a | b |\n|---|---|\n| 1 |\n").get("table.ragged") != 1:
        bad.append("rule 5: a short row was not counted as ragged")
    want("rule 4: a pipe inside a code span is CONTENT",
         "| a | b |\n|---|---|\n| `p1|p2|sys` | 2 |\n",
         lambda b: b[0].rows[1] == ["`p1|p2|sys`", "2"])
    want("rule 1 at BLOCK level: an open code span swallows a table-shaped line",
         "run `bbh a | b |\nc | d | e |` and stop\n",
         lambda b: len(b) == 1 and b[0].kind == "paragraph")
    raises("unclosed fence", "```\nx\n", "unclosed fenced code block")

    # a KNOWN tag INSIDE a code span is fine — the negative control
    want("a known tag inside a code span is code", "use `<div>` here\n",
         lambda b: b[0].kind == "paragraph")

    # --- inline rendering ---
    checks = [
        ("code span escaped", inline("a `<b>` c"), "<code>&lt;b&gt;</code>"),
        ("bold", inline("a **b** c"), "<strong>b</strong>"),
        ("italic", inline("a *b* c"), "<em>b</em>"),
        ("strike", inline("a ~~b~~ c"), "<s>b</s>"),
        ("escape outside code", inline("a < b & c"), "&lt;"),
        ("link", inline("[t](x.md)"), '<a href="x.md">t</a>'),
    ]
    for label, got, needle in checks:
        if needle not in got:
            bad.append("%s: %r lacks %r" % (label, got, needle))
    if "<strong>" in inline("a `**b**` c"):
        bad.append("a code span's content was parsed as bold")
    return bad


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("paths", nargs="*")
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--html", action="store_true")
    ap.add_argument("--no-selftest", action="store_true")
    a = ap.parse_args()

    rc = 0
    if not a.no_selftest and not a.html:
        bad = selftests()
        for b in bad:
            print("  FAIL  SELF-TEST: %s" % b)
        if bad:
            return 1

    total = Counter()
    for p in a.paths:
        text = Path(p).read_text(encoding="utf-8", errors="replace")
        if a.html:
            print(to_html(parse(text, p)))
            continue
        if a.census:
            total.update(census(text, p))
            continue
        try:
            parse(text, p)
        except SubsetError as e:
            print("  FAIL  %s" % e); rc = 1
    if a.census:
        for k in sorted(total):
            print("  %-24s %6d" % (k, total[k]))
    elif not a.html and rc == 0 and a.paths:
        print("ALL PASS (%d file(s) parse inside the subset)" % len(a.paths))
    elif not a.paths and not a.html:
        print("ALL PASS (self-tests)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
