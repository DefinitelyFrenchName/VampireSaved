#!/usr/bin/env python3
"""audit_header_defaults.py — A GATE'S HEADER MUST STATE THE DEFAULT THE CODE
ACTUALLY USES (14z-128).

  python3 tools/audit_header_defaults.py            # report every mismatch
  python3 tools/audit_header_defaults.py --fix      # rewrite the header lines
  python3 tools/audit_header_defaults.py --root DIR # a copy of the tree (controls)

WHY THIS EXISTS. `tests/test_build_ref_rot.sh` (14z-94, GitHub #94) closed the
class where a gate's CODE default points at a build dir that has been pruned:
"somebody ran the audit months later and it died before measuring anything".
The freeze ritual's re-point sweep has kept those honest — measured 14z-128,
zero emulator-tier gates have a rotted code default.

Their HEADERS are another matter. Measured the same day: 37 lines across 37
gates told the reader to run

    ROMDIR=... [BUILD=build/m3b_merged11] tests/audit_don_grab_pose.sh

while the code said `BUILD="${BUILD:-build/m3b_merged23}"`. The dir named in
the header had been pruned three freezes earlier. Nothing breaks — the code
default is right — but the maintainer ruled at 14z-122 that a gate's WHY lives
in its header, and the gate index (`docs/project/gate_index.md`) is generated
FROM those headers. A header that names a dead dir is a documented instruction
that cannot be followed, in the one place a reader looks before running the
gate.

THE RULE, deliberately narrow so it is mechanical and cannot be argued with:
every `build/<dir>` that appears on a line of the header presenting itself as
an INVOCATION or a DEFAULT — a `Usage:` line, or a line saying "default(s)" —
must be one of the defaults the code actually sets. Any other mention is left
alone: a header may cite the build a measurement was taken on, and that build
being pruned does not make the citation wrong. That distinction is the whole
reason this is not simply "no dead dirs in comments".

CODE DEFAULTS are the `${VAR:-build/x}` and `${1:-build/x}` forms, with or
without a `$REPO/` prefix, read from non-comment lines only.

WHAT IT DOES NOT CHECK: whether the code default itself still exists — that is
test_build_ref_rot.sh's job, and duplicating it here would put two gates on
one claim.
"""
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

CODE_DEFAULT = re.compile(
    r'\$\{(?:\d|[A-Za-z_][A-Za-z0-9_]*):-\s*"?(?:\$\{?REPO\}?/)?(build/[A-Za-z0-9_]+)')
CLAIM_LINE = re.compile(r'usage\s*:|defaults?\b', re.I)
DIR = re.compile(r'build/[A-Za-z0-9_]+')
# A backticked token is code being DISCUSSED, not an instruction — the rot gate
# test_build_ref_rot.sh quotes `${1:-build/pyron22}` while explaining the class
# it exists for, and flagging that would be this tool misreading prose as an
# invocation.
BACKTICKED = re.compile(r'`[^`]*`')


def header_lines(path):
    """The leading comment block: every `#` line after the shebang."""
    out = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines()[1:400]:
        if not line.startswith("#"):
            break
        out.append(line)
    return out


def code_defaults(path):
    body = "\n".join(l for l in path.read_text(encoding="utf-8", errors="replace").splitlines()
                     if not l.lstrip().startswith("#"))
    return set(CODE_DEFAULT.findall(body))


# A block introduced as "(verbatim; ...)" is an ARCHIVE — most gate headers
# carry HANDOFF's old gate-index note, moved in at 14z-123 and labelled
# verbatim. Rewriting a default inside one falsifies the quote, and archived
# entries are never rewritten ([VSP-13]). The live Usage line above it is the
# instruction; the note is dated history and reads as such.
VERBATIM = re.compile(r'\(verbatim[;,)]', re.I)


def audit(root):
    problems = []
    for p in sorted((root / "tests").glob("*.sh")):
        defaults = code_defaults(p)
        in_verbatim = False
        for i, line in enumerate(header_lines(p)):
            if VERBATIM.search(line):
                in_verbatim = True
            elif line.strip() == "#":
                in_verbatim = False
            if in_verbatim:
                continue
            if not CLAIM_LINE.search(line):
                continue
            quoted = [(m.start(), m.end()) for m in BACKTICKED.finditer(line)]
            for m in DIR.finditer(line):
                if any(a <= m.start() < b for a, b in quoted):
                    continue
                # `build/emu_sweep_<stamp>` is a TEMPLATE, not a dir. The test
                # cannot live in the regex: `[A-Za-z0-9_]+(?!<)` simply
                # backtracks off the trailing `_` and matches anyway.
                if line[m.end():m.end() + 1] == "<":
                    continue
                if m.group(0) not in defaults:
                    problems.append((p, i, m.group(0), line.rstrip(), sorted(defaults)))
    return problems


def fix(root, problems):
    """Rewrite each offending line, substituting the code's own default.

    Only acts when the code has EXACTLY ONE default: with several, which one a
    given header line means is a judgement, and a tool that guesses at that
    writes a confident wrong sentence into the place a reader trusts.
    """
    by_file = {}
    for p, i, dead, line, defaults in problems:
        by_file.setdefault(p, []).append((i, dead, defaults))
    fixed = skipped = 0
    for p, items in by_file.items():
        lines = p.read_text(encoding="utf-8").splitlines(keepends=True)
        touched = False
        for i, dead, defaults in items:
            if len(defaults) != 1:
                skipped += 1
                continue
            lines[i + 1] = lines[i + 1].replace(dead, defaults[0])
            fixed += 1
            touched = True
        if touched:                      # never rewrite a file we did not change
            p.write_text("".join(lines), encoding="utf-8")
    return fixed, skipped


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(REPO))
    ap.add_argument("--fix", action="store_true")
    a = ap.parse_args()
    root = Path(a.root).resolve()
    problems = audit(root)
    if a.fix:
        n, skipped = fix(root, problems)
        print(f"rewrote {n} header line(s); {skipped} left for a human "
              f"(the gate has more than one code default)")
        problems = audit(root)
    if not problems:
        print("ok    every header Usage/default line names a current code default")
        return 0
    print(f"{len(problems)} header line(s) name a build dir the code does not default to:")
    seen = set()
    for p, i, dead, line, defaults in problems:
        rel = p.relative_to(root)
        if rel not in seen:
            print(f"\n  {rel}   code defaults: {', '.join(defaults) or '(none)'}")
            seen.add(rel)
        print(f"      header line {i + 2}: {line.strip()[:96]}")
        print(f"      names {dead}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
