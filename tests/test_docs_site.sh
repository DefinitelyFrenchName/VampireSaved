#!/bin/sh
# test_docs_site.sh — the documentation site renders, resolves and is
# deterministic (14z-140, living-docs slice L4).
# ci_portable: no ROM, no build dir, no emulator, ~25 s.
#
# MUST-FIRE: perturbed-copy: unsupported-construct — a REFERENCE doc gaining an h4 heading must fail --check (mode: on a copy of the real corpus)
# MUST-FIRE: perturbed-copy: unresolved-link — a README link to a page that is not there must fail --check
# MUST-FIRE: perturbed-copy: dangling-anchor — a link to a heading no page has must fail --check
# MUST-FIRE: perturbed-copy: address-index-no-heading — an unclosed code span that swallows the heading an address sits under must fail the address index (the two parsers disagree; nothing else catches it)
# MUST-FIRE: perturbed-copy: unclosed-header — the rendered index.html with its </header> removed must fail the tag-balance check (the defect the maintainer found by opening the page, 14z-141)
#
# WHAT IT HOLDS. `tools/mk_docs_site.py` renders every document declared in
# docs/doc_shape.tsv plus the two skill GUIDEs, an ADDRESS INDEX built from
# `gen_annotations.collect()`, and a search index. This gate asserts that the
# whole corpus parses and every reference RESOLVES; that the rendered tree has
# the page set, the images and nothing else; that it loads NOTHING from the
# network; that every in-tree href points at a file the render actually wrote;
# and that two renders are byte-identical.
#
# WHY. The site is a PROJECTION, never a source (living_docs_scope.md §5.1),
# so the generator is what gets reviewed and the HTML is disposable. Two
# consequences this gate encodes: determinism is the hand-edit invariant here
# (a hand-edited page differs from a fresh render, which is what `--verify`
# reports on demand), and the href walk is INDEPENDENT of the generator — it
# re-derives the file set from the rendered tree rather than trusting the
# generator's own bookkeeping.
#
# THE HREF WALK STRIPS <script> FIRST. The search box is one inline script
# that builds hrefs by string concatenation, and a naive scan reads
# `'<a href="'+BASE+…` as 80 broken links — measured on the first run.
#
# NO EXEMPTIONS IN THE HREF WALK, and that is a RULING: the drawn MiSTer page
# (docs/project/mister_core.html) is gitignored and built on demand, so the
# site does NOT link it (§9.8 decision 4). Its page carries a NOTE naming the
# command instead. An external link a document deliberately writes (there are
# two, to an artifact and a GitHub issue) is a content link the reader clicks,
# not a LOAD — the assertion is that nothing is FETCHED from the network.
#
# EVERY PAGE CLOSES WHAT IT OPENS (section 9). The other checks all read the
# page as TEXT — hrefs, loaded origins, byte-equality — and a malformed page is
# deterministic and self-consistent, so every one of them passed while
# `page_html` emitted `<header class="top">` and never closed it (paid 14z-141,
# `docs/project/gotchas.md`). Structure is its own invariant and needs its own
# reader.
#
# MUST-FIRE CONTROLS on synthetic roots (section 7), each must fail for its
# stated reason: an unsupported construct; an unresolved link; a dangling
# anchor; an address-index section that is no heading. Section 8 is the
# must-NOT-fire side: a `<name>` inside a code span renders and does not trip
# the tag check. Section 9 carries its own control, on the rendered tree.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
TOOL=tools/mk_docs_site.py
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

echo "== test_docs_site: the corpus renders, resolves and is deterministic =="
[ -f "$TOOL" ] || { echo "FAIL: $TOOL is absent"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# --- 1. everything parses and every reference resolves ----------------------
# THE EXECUTABLE FORM: under CONTROL=<name> the perturbation is applied to a
# COPY OF THE REAL CORPUS (every carrier the renderer reads) and --check runs
# on the copy — it must FAIL. unclosed-header perturbs the RENDERED site below.
ROOT_ARGS=""
case "$VS_CTL" in
""|unclosed-header) ;;
*)  mkdir -p "$W/mode/build" "$W/mode/.claude"
    cp -R docs tools tests "$W/mode/"; cp -R build/manifest "$W/mode/build/"; cp -R .claude/skills "$W/mode/.claude/"
    case "$VS_CTL" in
    unsupported-construct)     printf '\n#### an h4 nobody may write\n' >> "$W/mode/docs/game/atlas/id_space.md" ;;
    unresolved-link)           printf '\nsee [x](game/atlas/nope_file.md)\n' >> "$W/mode/docs/README.md" ;;
    dangling-anchor)           printf '\nsee [sec](game/atlas/id_space.md#no-such-heading-anywhere)\n' >> "$W/mode/docs/README.md" ;;
    address-index-no-heading)  printf '\nrun `bbh one\n## Topic none\ntwo` and stop\n\nfacts about `PRG:0x0F1234`\n' >> "$W/mode/docs/project/mister_fit.md" ;;
    esac
    ROOT_ARGS="--root $W/mode" ;;
esac

if python3 "$TOOL" $ROOT_ARGS --check > "$W/check.log" 2>&1; then
    ok "--check: $(tail -1 "$W/check.log")"
else
    bad "--check FAILS:"; sed 's/^/        /' "$W/check.log" | head -20
fi

# --- 2. the rendered tree --------------------------------------------------
if python3 "$TOOL" --out "$W/site" > "$W/render.log" 2>&1; then
    ok "rendered: $(head -1 "$W/render.log")"
else
    bad "the render FAILED:"; sed 's/^/        /' "$W/render.log" | head -10
fi
for f in index.html addresses.html search.json style.css; do
    [ -s "$W/site/$f" ] && ok "$f written" || bad "$f is missing or empty"
done
# one page per declared document, plus the two GUIDEs
python3 - "$W/site" <<'PY' || fail=1
import sys, json
from pathlib import Path
sys.path.insert(0, "tools")
import mk_docs_site as S
site = Path(sys.argv[1])
pages, _ = S.collect_pages(Path("."))
missing = [p for p in sorted(pages.values()) if not (site / p).is_file()]
if missing:
    print("  FAIL  %d declared document(s) have no page: %s"
          % (len(missing), ", ".join(missing[:5])))
    sys.exit(1)
print("  ok    every one of the %d declared documents has a page" % len(pages))
ext = sorted({p.suffix for p in site.rglob("*") if p.is_file()})
if ext != [".css", ".html", ".jpg", ".json", ".png"]:
    print("  FAIL  unexpected file kinds in the site: %s" % ext); sys.exit(1)
print("  ok    the site holds only %s" % " ".join(ext))
n = len(json.loads((site / "search.json").read_text()))
print("  ok    search.json carries %d entries (headings, titles, rule IDs)" % n)
PY

# --- 3. nothing is loaded from the network, nothing names build/out ---------
python3 - "$W/site" <<'PY' || fail=1
import re, sys
from pathlib import Path
site = Path(sys.argv[1])
loads, romderived = [], []
pat = re.compile(r'<(script|link|img|iframe)\b[^>]*?(?:src|href)="(https?://[^"]+)"')
# A PATH IN PROSE IS NOT A REFERENCE. The corpus names build/out/vsavj_data.bin
# in commands constantly (HANDOFF, the atlas README, the gotchas), so grepping
# the page TEXT for it fails three documents for quoting a filename — measured
# on this gate's first run. What rule 7 bars is the site LINKING to or
# EMBEDDING a ROM-derived artefact, which is an attribute, not a word.
href = re.compile(r'(?:src|href)="([^"]+)"')
for p in sorted(site.rglob("*.html")):
    t = p.read_text()
    loads += ["%s: <%s %s>" % (p.name, m.group(1), m.group(2)) for m in pat.finditer(t)]
    for m in href.finditer(t):
        if m.group(1).startswith(("build/", "../build/")) or "/build/out" in m.group(1):
            romderived.append("%s -> %s" % (p.relative_to(site), m.group(1)))
if loads:
    print("  FAIL  the site LOADS from the network: %s" % loads[:3]); sys.exit(1)
print("  ok    nothing is fetched from the network (no external script/link/img)")
if romderived:
    print("  FAIL  a page LINKS into build/: %s" % romderived[:3]); sys.exit(1)
print("  ok    no page links into build/ (rule 7: prose may name a path, the "
      "site may not reference one)")
PY

# --- 4. every in-tree href resolves, by an INDEPENDENT walk -----------------
python3 - "$W/site" <<'PY' || fail=1
import os, re, sys
from pathlib import Path
site = Path(sys.argv[1])
files = {str(p.relative_to(site)) for p in site.rglob("*") if p.is_file()}
SCRIPT = re.compile(r"<script\b[^>]*>.*?</script>", re.S)   # a JS string is not an href
bad = []
for p in sorted(site.rglob("*.html")):
    rel = str(p.relative_to(site))
    for m in re.finditer(r'(?:href|src)="([^"]+)"', SCRIPT.sub("", p.read_text())):
        t = m.group(1)
        if t.startswith(("http://", "https://", "mailto:", "#", "data:")):
            continue
        tgt = os.path.normpath(os.path.join(os.path.dirname(rel), t.split("#")[0]))
        if tgt and tgt not in files:
            bad.append("%s -> %s" % (rel, t))
if bad:
    print("  FAIL  %d in-tree href(s) point at nothing: %s" % (len(bad), bad[:5]))
    sys.exit(1)
print("  ok    every in-tree href resolves to a file the render wrote (%d files)"
      % len(files))
PY

# --- 5. determinism — the hand-edit invariant's real form -------------------
python3 "$TOOL" --out "$W/site2" > /dev/null 2>&1
if diff -r "$W/site" "$W/site2" > "$W/diff.log" 2>&1; then
    ok "two renders are byte-identical (a hand-edited page would differ)"
else
    bad "two renders DIFFER:"; sed 's/^/        /' "$W/diff.log" | head -6
fi

# --- 6. the output directory is gitignored (decision 1's tripwire) ---------
if git -C "$REPO" rev-parse --git-dir > /dev/null 2>&1; then
    if git -C "$REPO" check-ignore -q docs/site; then
        ok "docs/site is gitignored — the site can never be committed"
    else
        bad "docs/site is NOT gitignored: the projection can be committed as a source"
    fi
else
    echo "  note: not a git checkout, the gitignore tripwire is not checked"
fi

# --- 7. MUST-FIRE controls on synthetic roots ------------------------------
mkroot() {  # mkroot <dir> <README body> <a.md body>
    mkdir -p "$1/docs"
    printf 'docs/README.md\tINDEX\t-\t-\ndocs/a.md\tREFERENCE\t-\t-\n' > "$1/docs/doc_shape.tsv"
    printf '%b' "$2" > "$1/docs/README.md"
    printf '%b' "$3" > "$1/docs/a.md"
}
control() {  # control <name> <root> <expected substring>
    if python3 "$TOOL" --root "$2" --check > "$2/log" 2>&1; then
        vs_ctl_dead "$1" "the generator ACCEPTED it — the check is not checking"; bad "$1"
    elif grep -q "$3" "$2/log"; then
        vs_ctl_fired "$1" "$3"; ok "$1: fires ($3)"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$2/log" | head -4
    fi
}
CLEAN_README='# idx\n\nsee [a](a.md) and [sec](a.md#topic-one)\n'
CLEAN_A='# A file\n\n## Topic one\n\nfacts\n'

mkroot "$W/r0" "$CLEAN_README" "$CLEAN_A"
if python3 "$TOOL" --root "$W/r0" --check > "$W/r0/log" 2>&1; then
    ok "a clean synthetic root renders (the controls' baseline)"
else
    bad "the clean synthetic root FAILS:"; sed 's/^/        /' "$W/r0/log" | head -6
fi

mkroot "$W/r1" "$CLEAN_README" '# A file\n\n#### an h4\n'
control unsupported-construct "$W/r1" "unsupported construct"

mkroot "$W/r2" '# idx\n\nsee [x](nope.md)\n' "$CLEAN_A"
control unresolved-link "$W/r2" "unresolved link"

mkroot "$W/r3" '# idx\n\nsee [sec](a.md#no-such-heading)\n' "$CLEAN_A"
control dangling-anchor "$W/r3" "dangling anchor"

# THE ADDRESS INDEX refuses a carrier whose section resolves to no heading —
# a link into a page that would land nowhere. Reaching it takes a real
# DISAGREEMENT between the two parsers, and there is one worth catching: an
# UNCLOSED CODE SPAN swallows the headings that follow it. md_subset joins the
# paragraph until the span closes (rule 1) and emits no heading, while
# gen_annotations' line-based HDR_RE records one and files the address under
# it. Nothing else in the tree catches that, which is this check's value.
#
# TWO WAYS THIS CONTROL WAS DEAD BEFORE IT WORKED, both worth stating:
#   - the document must sit where gen_annotations.CARRIERS LOOKS. Its patterns
#     are explicit directories (docs/game/atlas/*.md, docs/project/*.md,
#     HANDOFF.md, …); at docs/a.md nothing scans it and collect() returns zero
#     addresses, so the control passed by not firing.
#   - an address in a document's PREAMBLE does not give section "(top)": the
#     `# ` title has already set the section by then.
mkdir -p "$W/r4/docs/project"
printf 'docs/README.md\tINDEX\t-\t-\ndocs/project/a.md\tREFERENCE\t-\t-\n' \
    > "$W/r4/docs/doc_shape.tsv"
printf '# idx\n\nsee [a](project/a.md)\n' > "$W/r4/docs/README.md"
printf '# A file\n\nrun `bbh one\n## Topic one\ntwo` and stop\n\nfacts about `PRG:0x0F1234`\n' \
    > "$W/r4/docs/project/a.md"
# the control's own liveness: the address must actually be collected
if [ "$(python3 -c "import sys;sys.path.insert(0,'tools');import gen_annotations as g;from pathlib import Path;print(len(g.collect(Path('$W/r4'))))")" = "0" ]; then
    vs_ctl_dead address-index-no-heading "the fixture collects NO address — the control is dead"; bad "address-index-no-heading"
else
    control address-index-no-heading "$W/r4" "address index"
fi

# --- 8. MUST-NOT-FIRE: a placeholder inside a code span ---------------------
mkroot "$W/r5" "$CLEAN_README" '# A file\n\n## Topic one\n\nrun `tools/x.py <name>` now\n'
if python3 "$TOOL" --root "$W/r5" --check > "$W/r5/log" 2>&1; then
    ok "a <name> placeholder inside a code span: accepted (no over-fire)"
else
    bad "a <name> in a code span was REJECTED:"; sed 's/^/        /' "$W/r5/log" | head -4
fi

# --- 9. every rendered page CLOSES what it opens ----------------------------
# A stack-based read of the emitted HTML: every non-void tag must be closed,
# in order. This is the check that was missing when the site shipped with an
# unclosed sticky flex <header> — the browser nested the WHOLE page inside it,
# so the nav rendered as a vertically-centred left column and the sticky bar
# was visible only mid-page, while --check, the href walk and determinism were
# all green. Reads <script> as CDATA (HTMLParser does), so the search box's
# concatenated hrefs are never parsed as markup.
balance() {   # balance <site dir>; nonzero + a report on any malformed page
    python3 - "$1" <<'PY'
import sys, pathlib
from html.parser import HTMLParser
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link",
        "meta", "param", "source", "track", "wbr"}
class Reader(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.open, self.err = [], []
    def handle_starttag(self, tag, attrs):
        if tag not in VOID:
            self.open.append(tag)
    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if not self.open:
            self.err.append("</%s> closes nothing" % tag)
        elif self.open[-1] == tag:
            self.open.pop()
        elif tag in self.open:
            while self.open[-1] != tag:
                self.err.append("<%s> is never closed (</%s> closed it)"
                                % (self.open.pop(), tag))
            self.open.pop()
        else:
            self.err.append("</%s> closes nothing that is open" % tag)
site = pathlib.Path(sys.argv[1])
bad, pages = [], 0
for p in sorted(site.rglob("*.html")):
    r = Reader(); r.feed(p.read_text(encoding="utf-8")); r.close(); pages += 1
    for e in r.err + ["<%s> is never closed" % t for t in r.open]:
        bad.append("%s: %s" % (p.relative_to(site), e))
if bad:
    for b in bad[:10]:
        print(b)
    print("%d structural error(s) across %d page(s)" % (len(bad), pages))
    sys.exit(1)
print("%d pages, every tag closed in order" % pages)
PY
}
# its MUST-FIRE control: the exact defect, reintroduced on a COPY of the
# rendered site. Perturbing the rendered output is the right surface — the
# check reads rendered output, and a control must prove THE CHECK is alive.
# Under CONTROL=unclosed-header the perturbed copy IS the site the positive
# check reads, and this run must FAIL.
cp -R "$W/site" "$W/site_bad"
python3 - "$W/site_bad/index.html" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
assert "</header>" in t, "the fixture has no </header> to remove"
p.write_text(t.replace("</header>", "", 1), encoding="utf-8")
PY
SITE="$W/site"; vs_ctl_is unclosed-header && SITE="$W/site_bad"
if balance "$SITE" > "$W/bal.log" 2>&1; then
    ok "$(tail -1 "$W/bal.log")"
else
    bad "malformed page(s):"; sed 's/^/        /' "$W/bal.log" | head -8
fi
if balance "$W/site_bad" > "$W/bal_bad.log" 2>&1; then
    vs_ctl_dead unclosed-header "an unclosed <header> was ACCEPTED — the structure check is dead"; bad "unclosed-header"
elif grep -q "header" "$W/bal_bad.log"; then
    vs_ctl_fired unclosed-header "an unclosed <header> is caught ($(head -1 "$W/bal_bad.log"))"
else
    vs_ctl_dead unclosed-header "the structure control fired for the wrong reason"; bad "unclosed-header:"
    sed 's/^/        /' "$W/bal_bad.log" | head -4
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
