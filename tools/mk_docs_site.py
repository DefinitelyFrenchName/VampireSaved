#!/usr/bin/env python3
"""mk_docs_site.py — render the documentation corpus as a navigable local site.

  python3 tools/mk_docs_site.py                 # -> docs/site/, then open index.html
  python3 tools/mk_docs_site.py --check         # parse and resolve everything, write nothing
  python3 tools/mk_docs_site.py --census        # the construct census, per md_subset
  python3 tools/mk_docs_site.py --verify DIR    # is DIR what a fresh render produces?
  python3 tools/mk_docs_site.py --root DIR --out DIR

WHY THIS EXISTS (14z-140, living-docs slice L4). The effort's second problem
is a true claim in a file nobody opens (`docs/project/living_docs_scope.md`
§1.2). The corpus is 3.8 MB of markdown across 74 files that cross-reference
each other by BACKTICKED PATH far more than by markdown link — 1,568 such code
spans against 138 links — so reading it as text means resolving those by hand.
This renders all of it, resolves them, and adds the two indexes that only a
generated site can carry: every documented program address with every file
that names it, and a search over every heading and every `**[PFX-N]**` rule.

THE SITE IS A PROJECTION, NEVER A SOURCE. It is generated into a GITIGNORED
directory and never committed (ruled 2026-09-07, §9.8 decision 1, the
`mister_core.html` precedent); editing happens in the markdown. `--verify`
answers "is this directory what a fresh render produces?" on demand, and the
generator REFUSES to write into any tracked path.

WHAT IT BUILDS
  index.html        `docs/README.md` — the routing table first, then Contents
  <doc>.html        every row of `docs/doc_shape.tsv`, plus the two skill GUIDEs
  <dir>/index.html  for a directory the corpus links to that has no README.md
  addresses.html    every program address, with every carrier, from
                    `gen_annotations.collect()` — see THE ADDRESS INDEX below
  search.json       every h1-h3, every document title, every anchor ID
  style.css         from `tools/_pagestyle.py`, the theme the MiSTer page uses

THE ADDRESS INDEX IS BUILT FROM THE MODULE, NOT FROM THE RENDERED PAGE, and
that is load-bearing. `docs/annotations.md`'s `where` cell cannot be parsed
back: 688 headings in this corpus contain ` — ` (its file/section separator)
and 103 contain `;` (its carrier separator), `gen_annotations.cell()` rewrites
every backtick to `'`, and `MAX_CARRIERS` truncates to six with `+N more`.
Parsing that page resolves 540 of 825 carrier pairs to no heading; importing
`collect()` resolves 329 of 329 document-tier pairs and loses nothing
(measured 14z-140). A section that resolves to no emitted id FAILS the
generator — the enforcement the slice hoped for, reachable only this way.

WHAT IT LINKS, AND WHAT IT DELIBERATELY DOES NOT (§9.8):
  - a backticked `*.md` token becomes a link only when it resolves
    UNAMBIGUOUSLY to one rendered document, repo-relative or `docs/`-relative
    (decision 2). A bare basename stays a code span: `ram.md` has three
    candidates, and guessing is the ambiguity that made L1's first matcher
    unsound.
  - a `PRG:`/`CPU:` address token links to its row in the address index, but
    only if that address is one `collect()` knows.
  - `docs/project/mister_core.html`, the DRAWN page with its 17 re-derived
    figures, is NOT linked (decision 4). It is gitignored and built on demand,
    so linking it would mean weakening "every href resolves to a written file"
    — the one assertion that catches a broken site. Its page carries a NOTE
    naming the command instead.

Stdlib only, python 3.9. ROM-free, emulator-free (ci_portable,
tests/test_docs_site.sh).
"""
import argparse
import filecmp
import html as _html
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import md_subset                                                  # noqa: E402
from _pagestyle import theme_vars                                 # noqa: E402
import gen_annotations as ga                                      # noqa: E402
import checkdocshape                                              # noqa: E402

SHAPE_TSV = "docs/doc_shape.tsv"
GUIDE_GLOB = ".claude/skills/*/GUIDE.md"
IMAGE_DIR = "docs/project/images"
IMAGE_EXT = (".png", ".jpg", ".jpeg")
# The drawn MiSTer page: named, never linked (decision 4).
DRAWN_PAGE = "docs/project/mister_core.html"
DRAWN_SRC = "docs/project/mister_core.md"
DRAWN_CMD = "python3 tools/mk_mister_page.py"
# Address tokens we link. Deliberately NOT gen_annotations.ADDR_RE, whose bare
# `0x…` arm would turn every hex literal in the corpus into a link.
SITE_ADDR_RE = re.compile(r"(?:PRG:0x|CPU:\$)([0-9A-Fa-f]{5,6})\b")
TICK_DOC_RE = re.compile(r"^[\w./-]+\.md$")
ANCHOR_ID_RE = re.compile(r"\[([A-Z]+-\d+)\]")


class SiteError(Exception):
    pass


# --- the page set ------------------------------------------------------------

def slugify(text):
    """GitHub's rule, with our anchor markers stripped first. One function, so
    the address index and the rendered heading cannot disagree."""
    t = ANCHOR_ID_RE.sub("", text)
    t = re.sub(r"[`*_~]", "", t).strip().lower()
    t = re.sub(r"[^a-z0-9\s-]", "", t)
    return re.sub(r"[\s-]+", "-", t).strip("-")


def site_path(rel):
    """A repo-relative document -> its path inside the site."""
    if rel == "docs/README.md":
        return "index.html"
    if rel.startswith("docs/"):
        return rel[len("docs/"):-len(".md")] + ".html"
    if rel.startswith(".claude/skills/"):
        return "skills/" + rel.split("/")[2] + ".html"
    return rel[:-len(".md")] + ".html"


def collect_pages(root):
    """{repo-relative md -> site path}, in a stable order."""
    shape = checkdocshape.read_shape(root)
    pages = {}
    for rel in sorted(shape):
        if (root / rel).is_file():
            pages[rel] = site_path(rel)
    for p in sorted(root.glob(GUIDE_GLOB)):
        rel = p.relative_to(root).as_posix()
        pages[rel] = site_path(rel)
    return pages, shape


def rel_href(from_site, to_site, frag=""):
    h = os.path.relpath(to_site, os.path.dirname(from_site) or ".")
    return h + (("#" + frag) if frag else "")


# --- link and code-span resolution -------------------------------------------

class Resolver(object):
    """Turns a markdown target or a code span into an href, or None."""

    def __init__(self, root, pages, dirs, addrs, cur_rel, problems, slugcache):
        self.root, self.pages, self.dirs = root, pages, dirs
        self.addrs, self.problems = addrs, problems
        self.cur_rel, self.cur_site = cur_rel, pages[cur_rel]
        self.cur_dir = os.path.dirname(cur_rel)
        self.slugcache = slugcache

    def _slugs(self, rel):
        if rel not in self.slugcache:
            self.slugcache[rel] = set(heading_slugs(self.root, rel).values())
        return self.slugcache[rel]

    def _frag_ok(self, rel, frag, shown):
        """A `#fragment` must name a heading the target page emits — otherwise
        the link lands at the top and the reader never learns it missed."""
        if not frag or rel not in self.pages:
            return True
        if frag in self._slugs(rel) or ANCHOR_ID_RE.fullmatch("[" + frag + "]"):
            return True
        self.problems.append("%s: dangling anchor -> %s (no heading '%s' in %s)"
                             % (self.cur_rel, shown, frag, rel))
        return False

    def _repo_rel(self, target):
        """A markdown target, resolved against the document that wrote it."""
        t = target.split("#", 1)[0]
        if not t:
            return self.cur_rel
        return os.path.normpath(os.path.join(self.cur_dir, t))

    def link(self, target):
        if target.startswith(("http://", "https://", "mailto:")):
            return target
        frag = target.split("#", 1)[1] if "#" in target else ""
        if target.startswith("#"):
            self._frag_ok(self.cur_rel, frag, target)
            return target
        rel = self._repo_rel(target)
        if target.startswith("#"):
            rel = self.cur_rel
        if rel in self.pages:
            self._frag_ok(rel, frag, target)
            return rel_href(self.cur_site, self.pages[rel], frag)
        if target.rstrip("/") and (target.endswith("/") or (self.root / rel).is_dir()):
            key = rel.rstrip("/")
            if key in self.dirs:
                return rel_href(self.cur_site, self.dirs[key], frag)
        self.problems.append("%s: unresolved link -> %s" % (self.cur_rel, target))
        return None

    def code(self, span):
        """The two auto-links, both SCOPED (decision 2)."""
        s = span.strip()
        m = SITE_ADDR_RE.fullmatch(s)
        if m:
            v = int(m.group(1), 16)
            if v in self.addrs:
                return rel_href(self.cur_site, "addresses.html", "PRG-0x%06X" % v)
            return None
        if not TICK_DOC_RE.match(s):
            return None
        for cand in (s, "docs/" + s, os.path.normpath(os.path.join(self.cur_dir, s))):
            cand = cand.lstrip("./")
            if cand in self.pages:
                return rel_href(self.cur_site, self.pages[cand])
        return None


# --- rendering ---------------------------------------------------------------

CSS_BODY = """
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);
  font:15px/1.62 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
.wrap{max-width:60rem;margin:0 auto;padding:1.2rem 1.4rem 5rem}
header.top{position:sticky;top:0;z-index:5;background:var(--surface);
  border-bottom:1px solid var(--rule);padding:.5rem 1.4rem;display:flex;
  gap:.9rem;align-items:center;flex-wrap:wrap}
header.top a{color:var(--ink-2);text-decoration:none;font-weight:600}
header.top a:hover{color:var(--accent)}
.shape{font-size:.72rem;letter-spacing:.06em;text-transform:uppercase;
  color:var(--on-fill);background:var(--accent);border-radius:.25rem;
  padding:.1rem .42rem}
#q{flex:1;min-width:11rem;padding:.34rem .55rem;border:1px solid var(--rule);
  border-radius:.35rem;background:var(--paper);color:var(--ink);font:inherit}
#hits{position:absolute;top:2.6rem;left:0;right:0;max-height:70vh;overflow:auto;
  background:var(--surface);border:1px solid var(--rule);border-radius:.4rem;
  box-shadow:var(--shadow);display:none;z-index:9}
#hits a{display:block;padding:.35rem .7rem;color:var(--ink);font-weight:400}
#hits a:hover{background:var(--sunken)}
#hits .d{color:var(--ink-3);font-size:.8rem}
h1,h2,h3{line-height:1.25;margin:1.8rem 0 .7rem}
h1{font-size:1.7rem;margin-top:.6rem}
h2{font-size:1.28rem;border-bottom:1px solid var(--rule);padding-bottom:.25rem}
h3{font-size:1.06rem;color:var(--ink-2)}
a{color:var(--accent)}
code{background:var(--sunken);border-radius:.24rem;padding:.06em .3em;
  font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.88em}
a.cs{text-decoration:none}
a.cs code{border-bottom:1px dotted var(--accent)}
pre{background:var(--sunken);border:1px solid var(--rule);border-radius:.4rem;
  padding:.75rem .9rem;overflow-x:auto}
pre code{background:none;padding:0;font-size:.84em;line-height:1.45}
blockquote{margin:.9rem 0;padding:.5rem .95rem;border-left:3px solid var(--accent-soft);
  background:var(--surface);color:var(--ink-2)}
table{border-collapse:collapse;margin:1rem 0;font-size:.92em}
.scroller{overflow-x:auto}
th,td{border:1px solid var(--rule);padding:.34rem .55rem;text-align:left;
  vertical-align:top}
th{background:var(--sunken)}
hr{border:0;border-top:1px solid var(--rule);margin:2rem 0}
.note{border:1px solid var(--accent-soft);background:var(--surface);
  border-radius:.4rem;padding:.7rem .95rem;margin:1rem 0}
.addr td:first-child{white-space:nowrap;font-family:ui-monospace,monospace}
footer{margin-top:3rem;color:var(--ink-3);font-size:.85rem}
"""

SEARCH_JS = """
(function(){
  var q=document.getElementById('q'),h=document.getElementById('hits'),D=null;
  if(!q)return;
  function load(cb){ if(D)return cb(); var x=new XMLHttpRequest();
    x.open('GET',BASE+'search.json',true);
    x.onload=function(){ try{D=JSON.parse(x.responseText)}catch(e){D=[]} cb() };
    x.onerror=function(){D=[];cb()}; x.send(); }
  function run(){
    var v=q.value.trim().toLowerCase();
    if(v.length<2){h.style.display='none';return}
    load(function(){
      var out=[],i,e;
      for(i=0;i<D.length&&out.length<30;i++){ e=D[i];
        if(e.t.toLowerCase().indexOf(v)>=0) out.push(e); }
      h.innerHTML=out.map(function(e){
        return '<a href="'+BASE+e.d+(e.s?'#'+e.s:'')+'">'+e.t.replace(/[<>&]/g,'')+
               ' <span class="d">'+e.f+'</span></a>'; }).join('')||
        '<a class="d">nothing matches</a>';
      h.style.display='block';
    });
  }
  q.addEventListener('input',run);
  q.addEventListener('focus',run);
  document.addEventListener('click',function(e){
    if(e.target!==q) h.style.display='none'; });
})();
"""


def page_html(title, shape, body, site_rel, base):
    head = ('<header class="top"><a href="%sindex.html">docs</a>'
            '<a href="%saddresses.html">addresses</a>'
            '<span style="position:relative;flex:1">'
            '<input id="q" type="search" placeholder="search headings, titles, rule IDs…" '
            'autocomplete="off"><span id="hits"></span></span>'
            % (base, base))
    tag = '<span class="shape">%s</span>' % _html.escape(shape) if shape else ""
    return ("<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">"
            "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
            "<title>%s</title><link rel=\"stylesheet\" href=\"%sstyle.css\"></head>"
            "<body>%s<div class=\"wrap\">%s\n%s\n<footer>%s — generated by "
            "<code>tools/mk_docs_site.py</code>; the markdown is the source."
            "</footer></div>"
            "<script>var BASE=%s;</script><script>%s</script></body></html>\n"
            % (_html.escape(title), base, head, tag, body,
               _html.escape(site_rel), json.dumps(base), SEARCH_JS))


def render_doc(root, rel, pages, dirs, addrs, shape, problems, search, slugcache):
    text = (root / rel).read_text(encoding="utf-8", errors="replace")
    blocks = md_subset.parse(text, rel)
    site = pages[rel]
    base = "../" * site.count("/")
    res = Resolver(root, pages, dirs, addrs, rel, problems, slugcache)

    seen = {}

    def slug(t):
        s = slugify(t) or "section"
        if s in seen:
            seen[s] += 1
            return "%s-%d" % (s, seen[s])
        seen[s] = 1
        return s

    title = next((b.text for b in blocks if b.kind == "heading" and b.meta == 1), rel)
    # the search index: the title, every heading, every anchor ID
    search.append({"t": _plain(title), "d": site, "s": "", "f": rel})
    for b in blocks:
        if b.kind != "heading":
            continue
        for a in ANCHOR_ID_RE.findall(b.text):
            search.append({"t": a, "d": site, "s": a, "f": _plain(b.text)[:60]})
    body = []
    if rel == DRAWN_SRC:
        body.append('<div class="note"><strong>This document also has a DRAWN '
                    'page</strong> with figures re-derived from the constants '
                    'the gates freeze. It is generated separately and is not '
                    'part of this site:<br><code>%s</code> then open '
                    '<code>%s</code>.</div>' % (_html.escape(DRAWN_CMD),
                                                _html.escape(DRAWN_PAGE)))
    rendered = md_subset.to_html(blocks, slug=slug, link=res.link, code=res.code)
    # record every heading's slug for the search index and the address index
    seen2 = {}
    for b in blocks:
        if b.kind != "heading":
            continue
        s = slugify(b.text) or "section"
        if s in seen2:
            seen2[s] += 1
            s = "%s-%d" % (s, seen2[s])
        else:
            seen2[s] = 1
        search.append({"t": _plain(b.text), "d": site, "s": s, "f": rel})
    body.append(rendered)
    return page_html(_plain(title), shape, "\n".join(body), site, base)


def _plain(t):
    t = ANCHOR_ID_RE.sub("", t)
    return re.sub(r"[`*~]", "", t).strip()


def heading_slugs(root, rel):
    """Every heading slug a document emits, wrap-aware and duplicate-suffixed —
    the same numbering `render_doc` uses, so the address index can only link to
    an id that exists."""
    text = (root / rel).read_text(encoding="utf-8", errors="replace")
    out, seen = {}, {}
    for b in md_subset.parse(text, rel, strict=False):
        if b.kind != "heading":
            continue
        s = slugify(b.text) or "section"
        if s in seen:
            seen[s] += 1
            s = "%s-%d" % (s, seen[s])
        else:
            seen[s] = 1
        # Key on BOTH the raw heading and the form `gen_annotations.scan_doc`
        # records: it strips the `**[PFX-N]**` anchor and collapses runs of
        # whitespace, and it records ONE CONSTITUENT of a wrapped header (the
        # last it saw), not the merged text. Keying only on `b.text` reports
        # every anchored heading as missing — 200-odd false failures on the
        # first run, all of them real headings.
        for key in [b.text] + list(b.items):
            out.setdefault(key, s)
            out.setdefault(_ga_section(key), s)
    return out


def _ga_section(text):
    """A heading as `gen_annotations.scan_doc` records it."""
    return re.sub(r"\s+", " ", ga.ANCHOR_RE.sub("", text).strip())


# --- the address index -------------------------------------------------------

def build_addresses(root, pages, problems):
    rows = ga.collect(root)
    slugs = {}
    out = ['<h1>Addresses</h1>',
           '<p>Every program-space address this tree names, with every file '
           'that names it, in tier order — the atlas first, then '
           '<code>engine_internals.md</code>, then the other documents, then '
           'the manifests, then code. Built from '
           '<code>gen_annotations.collect()</code>, so it carries every '
           'carrier rather than the first six. An index, not a source: the '
           'fact lives in the carrier.</p>',
           '<div class="scroller"><table class="addr"><thead><tr><th>address</th>'
           '<th>where named</th></tr></thead><tbody>']
    for v in sorted(rows):
        cells, seen = [], set()
        for tier, rel, sec, hint in sorted(rows[v]):
            key = (rel, sec, hint)
            if key in seen:
                continue
            seen.add(key)
            label = rel + ((" — " + sec) if sec else "") + ((" [%s]" % hint) if hint else "")
            if rel in pages and sec:
                if rel not in slugs:
                    slugs[rel] = heading_slugs(root, rel)
                s = slugs[rel].get(sec)
                if s is None:
                    problems.append("address index: %s names section %r in %s, "
                                    "which is no heading there"
                                    % ("PRG:0x%06X" % v, sec, rel))
                    cells.append(_html.escape(label))
                    continue
                cells.append('<a href="%s">%s</a>'
                             % (_html.escape(rel_href("addresses.html", pages[rel], s)),
                                _html.escape(label)))
            elif rel in pages:
                cells.append('<a href="%s">%s</a>'
                             % (_html.escape(rel_href("addresses.html", pages[rel])),
                                _html.escape(label)))
            else:
                cells.append("<code>%s</code>" % _html.escape(label))
        out.append('<tr id="PRG-0x%06X"><td><code>PRG:0x%06X</code></td><td>%s</td></tr>'
                   % (v, v, "; ".join(cells)))
    out.append("</tbody></table></div>")
    return "\n".join(out), set(rows)


# --- directory index pages ---------------------------------------------------

def directory_targets(root, pages):
    """Directories the corpus LINKS to. One gets a page only when it has no
    README.md of its own — otherwise the README is the directory's page."""
    wanted = set()
    for rel in pages:
        text = (root / rel).read_text(encoding="utf-8", errors="replace")
        cur = os.path.dirname(rel)
        for m in re.finditer(r"\]\(([^)#\s]+/)\)", text):
            t = m.group(1)
            if t.startswith(("http://", "https://")):
                continue
            wanted.add(os.path.normpath(os.path.join(cur, t)))
    dirs = {}
    for d in sorted(wanted):
        readme = d + "/README.md"
        if readme in pages:
            dirs[d] = pages[readme]
        else:
            dirs[d] = (d[len("docs/"):] if d.startswith("docs/") else d) + "/index.html"
    return dirs


def render_dir_page(d, site, pages, shape_of):
    base = "../" * site.count("/")
    members = sorted(r for r in pages if r.startswith(d + "/"))
    rows = "".join(
        '<li><a href="%s">%s</a> %s</li>'
        % (_html.escape(rel_href(site, pages[r])), _html.escape(r[len(d) + 1:]),
           '<span class="shape">%s</span>' % shape_of.get(r, "") if shape_of.get(r) else "")
        for r in members)
    body = ("<h1>%s</h1><p>The documents under this directory. It has no "
            "<code>README.md</code> of its own, so this page is generated to "
            "keep every link in the corpus resolvable.</p><ul>%s</ul>"
            % (_html.escape(d + "/"), rows))
    return page_html(d + "/", "", body, site, base)


# --- the build ---------------------------------------------------------------

def build(root, out, check=False):
    problems = []
    pages, shape = collect_pages(root)
    dirs = directory_targets(root, pages)
    addr_html, addrs = build_addresses(root, pages, problems)

    search, slugcache = [], {}
    written = {}
    for rel in sorted(pages):
        cls = shape.get(rel, {}).get("cls", "")
        if rel.startswith(".claude/"):
            cls = "SKILL GUIDE"
        try:
            written[pages[rel]] = render_doc(root, rel, pages, dirs, addrs,
                                             cls, problems, search, slugcache)
        except md_subset.SubsetError as e:
            problems.append(str(e))
    shape_of = {r: shape.get(r, {}).get("cls", "") for r in pages}
    for d, site in sorted(dirs.items()):
        if site.endswith("/index.html") and site not in written:
            written[site] = render_dir_page(d, site, pages, shape_of)
    written["addresses.html"] = page_html("Addresses", "", addr_html,
                                          "addresses.html", "")
    written["style.css"] = theme_vars() + CSS_BODY
    written["search.json"] = json.dumps(
        sorted(search, key=lambda e: (e["d"], e["s"], e["t"])),
        separators=(",", ":"), sort_keys=True)

    images = sorted(p for p in (root / IMAGE_DIR).glob("*")
                    if p.suffix.lower() in IMAGE_EXT) if (root / IMAGE_DIR).is_dir() else []

    if check:
        return problems, written, images

    _refuse_tracked(root, out)
    if out.exists():
        shutil.rmtree(out)
    for site, text in sorted(written.items()):
        p = out / site
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")
    for img in images:
        dst = out / IMAGE_DIR[len("docs/"):] / img.name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(img, dst)
    return problems, written, images


def _refuse_tracked(root, out):
    """Never write into a tracked path. The site is a projection; a projection
    that lands in git is a second source (§5.1)."""
    try:
        r = subprocess.run(["git", "-C", str(root), "ls-files", "--error-unmatch",
                            str(Path(out).relative_to(root))],
                           capture_output=True, text=True)
    except (ValueError, OSError):
        return
    if r.returncode == 0 and r.stdout.strip():
        raise SiteError("refusing to write into a TRACKED path: %s" % out)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=None)
    ap.add_argument("--out", default=None)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--verify", default=None)
    a = ap.parse_args()
    root = Path(a.root).resolve() if a.root else Path(__file__).resolve().parent.parent
    out = Path(a.out).resolve() if a.out else root / "docs" / "site"

    if a.census:
        pages, _ = collect_pages(root)
        from collections import Counter
        total = Counter()
        for rel in sorted(pages):
            total.update(md_subset.census(
                (root / rel).read_text(encoding="utf-8", errors="replace"), rel))
        for k in sorted(total):
            print("  %-24s %6d" % (k, total[k]))
        return 0

    if a.verify:
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            fresh = Path(d) / "site"
            build(root, fresh)
            diff = _tree_diff(Path(a.verify), fresh)
        for f in diff:
            print("  DIFFERS %s" % f)
        print("verify: %d file(s) differ from a fresh render" % len(diff))
        return 1 if diff else 0

    problems, written, images = build(root, out, check=a.check)
    for p in problems:
        print("  FAIL  %s" % p)
    if problems:
        return 1
    print("%s %d pages, %d images%s"
          % ("would write" if a.check else "wrote", len(written), len(images),
             "" if a.check else " -> %s" % out))
    if not a.check:
        print("open %s" % (out / "index.html"))
    return 0


def _tree_diff(a, b):
    out = []
    for p in sorted(b.rglob("*")):
        if p.is_dir():
            continue
        rel = p.relative_to(b)
        q = a / rel
        if not q.is_file() or not filecmp.cmp(p, q, shallow=False):
            out.append(str(rel))
    for p in sorted(a.rglob("*")):
        if p.is_file() and not (b / p.relative_to(a)).is_file():
            out.append(str(p.relative_to(a)) + " (not in a fresh render)")
    return out


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SiteError as e:
        print("  FAIL  %s" % e)
        sys.exit(1)
