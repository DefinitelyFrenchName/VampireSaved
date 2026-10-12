#!/usr/bin/env python3
"""retraction_grep.py — the close ritual's RETRACTION GREP (CLAUDE.md [VSP-13]
step 3), promoted from the inline script of the 14z-181 close after
rule-checker runs 184-187 (the pattern was narrower than its carrier three
times, and the script itself lived in no tracked file). The rule it applies is
docs/project/gotchas.md '"EVERY" MEANS EVERY, AND A RETRACTION GREP MUST MATCH
THE CARRIER'S SHAPE' (rule half 2).

  python3 tools/retraction_grep.py tests/rulecheck/retractions/14z-181.tsv [out]
  python3 tools/retraction_grep.py --selftest [--nofold]   # the matcher on planted texts

The TSV has three tab-separated columns: pattern, source (the run that
retracted it, or what the control proves), kind — `retracted` for a wording
that must be found only in quoted retractions and records, `reach` for a
CONTROL: a wording known to be live that MUST be found (a heading; a corrected
wording in its plain and code-spanned carriers; a carrier line-wrapped across a
`#` comment prefix) — `reach:N` demands at least N hits, so a control with two
known carriers (plain and code-spanned) fails when either is missed. Each file under the roots is read WHOLE, with runs of
whitespace, backticks and `#` or `--` comment prefixes at line starts collapsed to one
space (`--` since 14z-184: a wording wrapped across Lua comment lines was invisible, rule-checker run 2026-09-25-317) and the text CASE-FOLDED, and each pattern is matched the same way — so a wrapped, code-spanned or
comment-wrapped carrier is found. Since 14z-195 (#242) also a Markdown quote prefix (`> `) on a wrapped line,
a code string join (`...")` then `A("...` on the next line), `**` emphasis, and — in a rendered `.html`
page — the tags and entities are collapsed, each with a self-test plant (`--nomarkup` is the known-bad
variant without them). Every hit is printed with its file and the
matched text; the CLASSING of retracted hits is the working agent's, written
in the artifact by hand below the tool's output. EXIT 1 when any reach control
reads fewer hits than it demands (0, or N for `reach:N`) or any `gone` wording
reads a hit; EXIT 3 (REFUSED) on a malformed or duplicated pattern line, named by
its file line — a refusal is not a verdict. The header carries a TREE FINGERPRINT (sha1 of every scanned
file's normalised text): an output is a SNAPSHOT of one tree, and the gates
re-run the tool on the live tree, so a stale artifact is never the check (the
grep did not reach the tree) — that is its must-fire. Since #268 (14z-199) the
whole-tree run of every pattern file is tests/test_retraction_reach.sh, at a
freeze and a release, and every tier runs tests/test_close_tools.sh's touched
scan of every file's gone wordings:

  python3 tools/retraction_grep.py --each A.tsv B.tsv ...   # every file judged on ONE scan
  python3 tools/retraction_grep.py --touched LIST --each A.tsv ...   # only LIST's paths (one per
      line) that the full scan reads: gone wordings judged, reach controls listed but not judged

`--each` prints one `FILE <tsv>: PASS — ...` or `FILE <tsv>: FAIL: ...` line per
file and `EACH: N file(s), F failed`; it skips the `retracted` wordings, whose
hits are a listing for the hand classing, never a verdict. The cost of a scan
is the normalising of ~10,000 files (~25 s), not the matching, so one scan for
all files costs about what one file did.

Scanned: EVERY TRACKED FILE (`git ls-files`: README.md, SPEC.md, HANDOFF_HISTORY.md,
the skills, release/ and every other root document included — run 2026-09-25-204
found README.md, a home in the findings table, outside the old root list) PLUS
every file, tracked or not, under docs HANDOFF.md STATE.md STATE_HISTORY.md
DECISIONS_HISTORY.md tests tools build/manifest — GENERATED pages included
(docs/GOTCHAS.md, the gate pages): a generated page left stale is a live carrier
(rule-checker run 2026-09-25-189). A file holding a NUL byte is binary and
skipped; excluded only tests/rulecheck/runs/ (staged packets), this tool and
the patterns TSVs themselves. A pattern file's reach control that lives only in
a root document (README.md) makes a scan that stopped reaching the root
documents a red.
"""
import pathlib
import re
import sys

ROOTS = ["docs", "HANDOFF.md", "STATE.md", "STATE_HISTORY.md", "DECISIONS_HISTORY.md", "tests", "tools", "build/manifest"]
EXCLUDE = ("tests/rulecheck/runs", "tools/retraction_grep.py", "tests/rulecheck/retractions")


NOFOLD = False   # --nofold: case-folding disabled — a KNOWN-BAD variant for test_close_tools' case-fold-dropped mode
NOMARKUP = False   # --nomarkup: the #242 collapses disabled — a KNOWN-BAD variant for test_close_tools' markup-dropped mode


def unhtml(t):
    """A rendered page (docs/site/*.html) carries a wording through tags and entities (`<code>…</code>`,
    `&quot;`): strip the tags and unescape the entities before matching (#242, 14z-195)."""
    import html
    return html.unescape(re.sub(r"<[^>]+>", " ", t))


def norm(t):
    t = re.sub(r"(^|\n)[ \t]*(?:#+|--)[ \t]*", " ", t)   # shell/python `#` and Lua `--` (14z-184, run 317)
    if not NOMARKUP:   # #242 (14z-195): carriers the collapse above did not reach
        t = re.sub(r"(^|\n)[ \t]*(?:>[ \t]*)+", " ", t)   # a Markdown quote prefix on a wrapped line
        t = re.sub(r"[\"']\)?[ \t]*\n[ \t]*(?:[A-Za-z_][\w.]*\()?[\"']", " ", t)   # a code string join: `...")` / `A("...` or `"` / `"`
        t = t.replace("**", "")   # Markdown emphasis inside a wording
    t = re.sub(r"\s+", " ", t.replace("`", ""))
    return t if NOFOLD else t.lower()   # case-folded: a HEADING carries a wording too (run 196)


def selftest():
    """The matcher on PLANTED texts, not the tree (run 199 Q4: a reach pattern over the tree
    cannot isolate the matcher — a stray carrier of the other case masks a missing fold)."""
    cases = [("upper-case heading", "## THE GROUND IS Y = 40 — a heading\n", "the ground is y = 40"),
             ("comment-wrapped", "# first half of the\n# wrapped wording here\n", "of the wrapped wording"),
             ("lua-comment-wrapped", "-- first half of the\n-- lua wrapped wording\n", "of the lua wrapped wording"),
             ("code-spanned", "the `LEAD=0` for the walk\n", "LEAD=0 for the walk"),
             # #242 (14z-195): the four carriers the collapse did not reach
             ("quote-wrapped", "> the old claim had five\n>    call sites in all\n", "five call sites"),
             ("html-rendered", "<p>it read &quot;the <code>+9</code> is dealt&quot; once</p>", '"the +9 is dealt"'),
             ("string-joined", '    A("the wording runs on ")\n    A("into the next line")\n', "runs on into the next"),
             ("emphasis-split", "the **ground** is y = 40\n", "the ground is y = 40")]
    bad = [name for name, text, pat in cases
           if norm(pat).strip() not in norm(unhtml(text) if name == "html-rendered" and not NOMARKUP else text)]
    if bad:
        print("SELFTEST FAIL: the matcher missed the planted " + ", ".join(bad) + " case(s)" + (" (no-fold variant)" if NOFOLD else "") + (" (no-markup variant)" if NOMARKUP else ""))
        sys.exit(1)
    print("SELFTEST PASS: the upper-case heading, comment-wrapped (`#` and Lua `--`), code-spanned, quote-wrapped, html-rendered, string-joined and emphasis-split plants are each matched")
    sys.exit(0)


def read_patterns(tsv):
    """The TSV's pattern lines, or REFUSED (exit 3) on a malformed or repeated line — before any scan."""
    pats = []
    seen = {}
    for ln, line in enumerate(tsv.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cols = line.split("\t")
        if len(cols) != 3 or not re.fullmatch(r"retracted|gone|reach(:\d+)?", cols[2]):
            print(f"REFUSED: {tsv} line {ln} is not `pattern<TAB>source<TAB>retracted|gone|reach[:N]`: {line[:80]!r}"); sys.exit(3)
        if cols[0] in seen:
            print(f"REFUSED: {tsv} line {ln} repeats the pattern of line {seen[cols[0]]}: {cols[0]!r}"); sys.exit(3)
        seen[cols[0]] = ln
        pats.append(tuple(cols))
    return pats


def universe():
    """Every path the scan reads: every file under ROOTS plus every tracked file, minus EXCLUDE. A TEST HARNESS may
    set RETRACTION_GREP_UNIVERSE to a file of paths (one per line) to stand in for the tree — test_close_tools' routing
    control proves in ~1 s which scan a pattern file gets, not by a whole-tree pass (#268) — and the scan's header then
    says RESTRICTED, so a real run under a stray value is visible."""
    import os
    import subprocess
    if os.environ.get("RETRACTION_GREP_UNIVERSE"):
        return [pathlib.Path(x.strip()) for x in pathlib.Path(os.environ["RETRACTION_GREP_UNIVERSE"]).read_text().splitlines() if x.strip()]
    files = set()
    for r in ROOTS:
        p = pathlib.Path(r)
        files |= {p} if p.is_file() else {f for f in p.rglob("*") if f.is_file()}
    files |= {pathlib.Path(f) for f in subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True).stdout.splitlines()}
    return [f for f in files if not str(f).startswith(EXCLUDE)]


def load(files):
    """Each readable text file's NORMALISED text (a file holding a NUL byte is binary and skipped)."""
    texts = {}
    for f in files:
        try:
            b = f.read_bytes()
        except OSError:
            continue
        if b"\0" in b:
            continue   # binary
        t = b.decode("utf-8", errors="ignore")
        texts[f] = norm(unhtml(t) if f.suffix == ".html" and not NOMARKUP else t)
    return texts


def judge(pats, texts, reach=True, listing=True):
    """One pattern file against the loaded texts: (report lines, dead reach controls, gone wordings back).
    reach=False (a --touched scan reads part of the tree) lists reach hits but judges none of them;
    listing=False (--each, which prints verdicts only) skips the `retracted` wordings, whose hits are a
    listing for the close's hand classing and never a verdict."""
    out = []
    dead = []; alive = []
    order = sorted(texts.items(), key=lambda kv: str(kv[0]))   # sorted: a snapshot diffs cleanly
    for p, src, kind in pats:
        if kind == "retracted" and not listing:
            continue
        q = norm(p).strip()
        hits = []
        for f, t in order:
            if q not in t:   # a substring test first: most files hold no pattern, and `in` is the cheap read
                continue
            for m in re.finditer(re.escape(q), t):
                hits.append(f"{f}: ...{t[max(0, m.start() - 60):m.end() + 60]}...")
        out.append(f"== [{kind}] '{p}'  ({src}): {len(hits)} hit(s)")
        out += ["   " + h[:260] for h in hits]
        need = int(kind.split(":")[1]) if kind.startswith("reach:") else 1
        if reach and kind.startswith("reach") and len(hits) < need:
            dead.append(f"{p} ({len(hits)} < {need})")
        if kind == "gone" and hits:
            alive.append(f"{p} ({len(hits)} hit(s))")
    return out, dead, alive


def verdict(pats, dead, alive, reach=True):
    """The pattern file's closing lines: its FAIL lines, or its REACH/GONE line."""
    out = []
    if dead:
        out.append("FAIL: reach control(s) read fewer hits than demanded — the grep did not reach the tree: " + " | ".join(dead))
    if alive:
        out.append("FAIL: a wording marked GONE is back in the tree: " + " | ".join(alive))
    if not dead and not alive:
        nr = sum(1 for _, _, k in pats if k.startswith('reach'))
        ng = sum(1 for _, _, k in pats if k == 'gone')
        out.append((f"REACH: every reach control found ({nr}); " if reach else f"REACH: not judged ({nr} control(s)) — a touched scan reads part of the tree; ")
                   + f"GONE: every gone wording absent ({ng})")
    return out


def main():
    global NOFOLD
    global NOMARKUP
    if "--nofold" in sys.argv:
        NOFOLD = True; sys.argv.remove("--nofold")
    if "--nomarkup" in sys.argv:
        NOMARKUP = True; sys.argv.remove("--nomarkup")
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        selftest()
    touched = None
    if "--touched" in sys.argv:   # --touched LIST: scan only the listed paths (one per line) that the full scan reads
        i = sys.argv.index("--touched")
        listed = {pathlib.Path(x.strip()) for x in pathlib.Path(sys.argv[i + 1]).read_text(encoding="utf-8").splitlines() if x.strip()}
        del sys.argv[i:i + 2]
        touched = listed
    if len(sys.argv) > 1 and sys.argv[1] == "--each":
        each(sys.argv[2:], touched)
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    tsv = pathlib.Path(sys.argv[1])
    pats = read_patterns(tsv)
    files = universe()
    if touched is not None:
        files = [f for f in files if f in touched]
    texts = load(files)
    import hashlib
    # the fingerprint leaves out tests/rulecheck/ledger.tsv: `rulecheck record`, `resolve` and
    # `prepare` append to it AFTER every snapshot by construction, so a fingerprint that
    # included it could never match a fresh run's (run 2026-09-25-198's prepare). The ledger is
    # still SCANNED for hits; it is only left out of the currency check.
    fp = hashlib.sha1("".join(f"{f}\n{t}\n" for f, t in sorted(texts.items(), key=lambda kv: str(kv[0])) if str(f) != "tests/rulecheck/ledger.tsv").encode("utf-8", "ignore")).hexdigest()[:12]
    scope = (f"the {len(texts)} TOUCHED files of the scan's set (--touched: gone wordings judged, reach controls not)" if touched is not None
             else f"{len(texts)} files (every tracked text file, plus every file under {' '.join(ROOTS)})")
    out = [f"# retraction_grep.py {tsv}: {len(pats)} patterns over {scope}; shape match — whole file, whitespace/backtick/comment-prefix collapsed, case-folded; TREE FINGERPRINT {fp} (sha1 of every scanned file's normalised text except tests/rulecheck/ledger.tsv, which the rule-checker's own record/resolve/prepare append to after every snapshot — an output whose fingerprint differs from a fresh run's was made on another tree)"]
    body, dead, alive = judge(pats, texts, reach=touched is None)
    out += body + verdict(pats, dead, alive, reach=touched is None)
    text = "\n".join(out) + "\n"
    if len(sys.argv) > 2:
        pathlib.Path(sys.argv[2]).write_text(text, encoding="utf-8")
    sys.stdout.write(text if len(sys.argv) <= 2 else out[0] + "\n" + out[-1] + "\n")
    sys.exit(1 if (dead or alive) else 0)


def each(tsvs, touched=None):
    """--each A.tsv B.tsv ...: EVERY pattern file judged on ONE scan of the tree (#268, 14z-199: the gate
    ran one full scan per file — twenty scans of the same ~15,000 files, ~25 s each, where the
    normalising, not the matching, is the cost). Every file is read first, so a malformed one REFUSES
    before the scan. Prints one verdict line per file — `FILE <tsv>: PASS — REACH ...` or
    `FILE <tsv>: FAIL: ...` — then `EACH: N file(s), F failed`; exit 1 when any file fails."""
    if not tsvs:
        sys.exit(__doc__)
    sets = [(t, read_patterns(pathlib.Path(t))) for t in tsvs]   # named as GIVEN: pathlib folds `//`, and a caller matches its own spelling
    files = universe()
    if touched is not None:
        files = [f for f in files if f in touched]
    texts = load(files)
    scope = (f"the {len(texts)} TOUCHED files of the scan's set (gone wordings judged, reach controls not)" if touched is not None
             else f"{len(texts)} files (every tracked text file, plus every file under {' '.join(ROOTS)})")
    import os
    if os.environ.get("RETRACTION_GREP_UNIVERSE"):
        scope += f" — RESTRICTED by RETRACTION_GREP_UNIVERSE to {os.environ['RETRACTION_GREP_UNIVERSE']} (a test harness, never a check)"
    print(f"# retraction_grep.py --each: {len(sets)} pattern file(s), {sum(len(p) for _, p in sets)} patterns, ONE scan over {scope}")
    failed = 0
    for tsv, pats in sets:
        _, dead, alive = judge(pats, texts, reach=touched is None, listing=False)
        lines = verdict(pats, dead, alive, reach=touched is None)
        if dead or alive:
            failed += 1
            for ln in lines:
                print(f"FILE {tsv}: {ln}")
        else:
            print(f"FILE {tsv}: PASS — {lines[-1]}")
    print(f"EACH: {len(sets)} file(s), {failed} failed")
    sys.exit(1 if failed else 0)

if __name__ == "__main__":
    main()
