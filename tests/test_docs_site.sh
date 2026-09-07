#!/bin/sh
# test_docs_site.sh — the documentation site renders, resolves and is
# deterministic (14z-140, living-docs slice L4).
# ci_portable: no ROM, no build dir, no emulator, ~25 s.
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
# MUST-FIRE CONTROLS on synthetic roots (section 5), each must fail for its
# stated reason: an unsupported construct; an unresolved link; a dangling
# anchor; an address-index section that is no heading. Section 6 is the
# must-NOT-fire side: a `<name>` inside a code span renders and does not trip
# the tag check.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
TOOL=tools/mk_docs_site.py

echo "== test_docs_site: the corpus renders, resolves and is deterministic =="
[ -f "$TOOL" ] || { echo "FAIL: $TOOL is absent"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# --- 1. everything parses and every reference resolves ----------------------
if python3 "$TOOL" --check > "$W/check.log" 2>&1; then
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
control() {  # control <label> <root> <expected substring>
    if python3 "$TOOL" --root "$2" --check > "$2/log" 2>&1; then
        bad "$1: the generator ACCEPTED it — the check is not checking"
    elif grep -q "$3" "$2/log"; then
        ok "$1: fires ($3)"
    else
        bad "$1: failed for the wrong reason:"; sed 's/^/        /' "$2/log" | head -4
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
control "an unsupported construct" "$W/r1" "unsupported construct"

mkroot "$W/r2" '# idx\n\nsee [x](nope.md)\n' "$CLEAN_A"
control "an unresolved link" "$W/r2" "unresolved link"

mkroot "$W/r3" '# idx\n\nsee [sec](a.md#no-such-heading)\n' "$CLEAN_A"
control "a dangling anchor" "$W/r3" "dangling anchor"

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
    bad "an address-index section that is no heading: the fixture collects NO address — the control is dead"
else
    control "an address-index section that is no heading" "$W/r4" "address index"
fi

# --- 8. MUST-NOT-FIRE: a placeholder inside a code span ---------------------
mkroot "$W/r5" "$CLEAN_README" '# A file\n\n## Topic one\n\nrun `tools/x.py <name>` now\n'
if python3 "$TOOL" --root "$W/r5" --check > "$W/r5/log" 2>&1; then
    ok "a <name> placeholder inside a code span: accepted (no over-fire)"
else
    bad "a <name> in a code span was REJECTED:"; sed 's/^/        /' "$W/r5/log" | head -4
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
