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
whitespace, backticks and `#` comment prefixes at line starts collapsed to one
space and the text CASE-FOLDED, and each pattern is matched the same way — so a wrapped, code-spanned or
comment-wrapped carrier is found. Every hit is printed with its file and the
matched text; the CLASSING of retracted hits is the working agent's, written
in the artifact by hand below the tool's output. EXIT 1 when any reach control
reads fewer hits than it demands (0, or N for `reach:N`) or any `gone` wording
reads a hit; EXIT 3 (REFUSED) on a malformed or duplicated pattern line, named by
its file line — a refusal is not a verdict. The header carries a TREE FINGERPRINT (sha1 of every scanned
file's normalised text): an output is a SNAPSHOT of one tree, and the gate
re-runs the tool on the live tree at every tier, so a stale artifact is never
the check (the grep did not reach the tree) — that is its must-fire.

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


def norm(t):
    t = re.sub(r"(^|\n)[ \t]*#+[ \t]*", " ", t)
    t = re.sub(r"\s+", " ", t.replace("`", ""))
    return t if NOFOLD else t.lower()   # case-folded: a HEADING carries a wording too (run 196)


def selftest():
    """The matcher on PLANTED texts, not the tree (run 199 Q4: a reach pattern over the tree
    cannot isolate the matcher — a stray carrier of the other case masks a missing fold)."""
    cases = [("upper-case heading", "## THE GROUND IS Y = 40 — a heading\n", "the ground is y = 40"),
             ("comment-wrapped", "# first half of the\n# wrapped wording here\n", "of the wrapped wording"),
             ("code-spanned", "the `LEAD=0` for the walk\n", "LEAD=0 for the walk")]
    bad = [name for name, text, pat in cases if norm(pat).strip() not in norm(text)]
    if bad:
        print("SELFTEST FAIL: the matcher missed the planted " + ", ".join(bad) + " case(s)" + (" (no-fold variant)" if NOFOLD else ""))
        sys.exit(1)
    print("SELFTEST PASS: the upper-case heading, comment-wrapped and code-spanned plants are each matched")
    sys.exit(0)


def main():
    global NOFOLD
    if "--nofold" in sys.argv:
        NOFOLD = True; sys.argv.remove("--nofold")
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        selftest()
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    tsv = pathlib.Path(sys.argv[1])
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
    files = set()
    for r in ROOTS:
        p = pathlib.Path(r)
        files |= {p} if p.is_file() else {f for f in p.rglob("*") if f.is_file()}
    import subprocess
    files |= {pathlib.Path(f) for f in subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True).stdout.splitlines()}
    files = [f for f in files if not str(f).startswith(EXCLUDE)]
    texts = {}
    for f in files:
        try:
            b = f.read_bytes()
        except OSError:
            continue
        if b"\0" in b:
            continue   # binary
        texts[f] = norm(b.decode("utf-8", errors="ignore"))
    import hashlib
    # the fingerprint leaves out tests/rulecheck/ledger.tsv: `rulecheck record`, `resolve` and
    # `prepare` append to it AFTER every snapshot by construction, so a fingerprint that
    # included it could never match a fresh run's (run 2026-09-25-198's prepare). The ledger is
    # still SCANNED for hits; it is only left out of the currency check.
    fp = hashlib.sha1("".join(f"{f}\n{t}\n" for f, t in sorted(texts.items(), key=lambda kv: str(kv[0])) if str(f) != "tests/rulecheck/ledger.tsv").encode("utf-8", "ignore")).hexdigest()[:12]
    out = [f"# retraction_grep.py {tsv}: {len(pats)} patterns over {len(texts)} files (every tracked text file, plus every file under {' '.join(ROOTS)}); shape match — whole file, whitespace/backtick/comment-prefix collapsed, case-folded; TREE FINGERPRINT {fp} (sha1 of every scanned file's normalised text except tests/rulecheck/ledger.tsv, which the rule-checker's own record/resolve/prepare append to after every snapshot — an output whose fingerprint differs from a fresh run's was made on another tree)"]
    dead = []; alive = []
    for p, src, kind in pats:
        q = norm(p).strip()
        hits = []
        for f, t in sorted(texts.items(), key=lambda kv: str(kv[0])):   # sorted: a snapshot diffs cleanly
            for m in re.finditer(re.escape(q), t):
                hits.append(f"{f}: ...{t[max(0, m.start() - 60):m.end() + 60]}...")
        out.append(f"== [{kind}] '{p}'  ({src}): {len(hits)} hit(s)")
        out += ["   " + h[:260] for h in hits]
        need = int(kind.split(":")[1]) if kind.startswith("reach:") else 1
        if kind.startswith("reach") and len(hits) < need:
            dead.append(f"{p} ({len(hits)} < {need})")
        if kind == "gone" and hits:
            alive.append(f"{p} ({len(hits)} hit(s))")
    if dead:
        out.append("FAIL: reach control(s) read fewer hits than demanded — the grep did not reach the tree: " + " | ".join(dead))
    if alive:
        out.append("FAIL: a wording marked GONE is back in the tree: " + " | ".join(alive))
    if not dead and not alive:
        out.append(f"REACH: every reach control found ({sum(1 for _, _, k in pats if k.startswith('reach'))}); GONE: every gone wording absent ({sum(1 for _, _, k in pats if k == 'gone')})")
    text = "\n".join(out) + "\n"
    if len(sys.argv) > 2:
        pathlib.Path(sys.argv[2]).write_text(text, encoding="utf-8")
    sys.stdout.write(text if len(sys.argv) <= 2 else out[0] + "\n" + out[-1] + "\n")
    sys.exit(1 if (dead or alive) else 0)


if __name__ == "__main__":
    main()
