#!/usr/bin/env python3
"""freeze_bytediff.py — the newest freeze's WHOLE program change, byte by byte, recorded and held (14z-193,
GitHub #231 part 2).

WHY. A freeze's delta was read as op sets, which cannot see a byte that changes inside a placed data file (#194's
byte at M22; docs/project/gotchas.md "AN OP-SET DELTA CANNOT SEE A BYTE INSIDE A PLACED FILE"). The M23 freeze
measured every track's program change with tools/program_bytediff.py by hand. This makes it a step the freeze
cannot skip: the newest freeze's record must exist and equal a fresh measurement, and a freeze that adds registry
rows without writing it leaves the gate red.

WHAT. The tracks are donovan, huitzil, pyron and merged. For each, the NEWEST registry row (tests/expected/
registry.tsv, rows in freeze order) and the row before it on the same track give a pair of expectation sets; each
set's build directory is the `build dir` line of its annotated tag freeze/<set>. The record is
`program_bytediff.py --record` over the four pairs — ranges and whole-image sha1s, NO BYTES (CLAUDE.md rule 7) —
under a header naming the sets, at tests/expected/freeze_bytediff/<newest merged set>.txt. The stock twin and the
stage-4 image are untagged pipeline images and are not in it.

    python3 tools/freeze_bytediff.py plan              # the four pairs: track, sets, build dirs
    python3 tools/freeze_bytediff.py render            # the record, to stdout
    python3 tools/freeze_bytediff.py check [--record FILE]   # exit 0 iff FILE (default: the newest freeze's) equals a fresh render
    python3 tools/freeze_bytediff.py freeze            # write the record (after reviewing `render`)

Static; needs the eight build directories and the tags. Decrypts eight romsets (~16 s a pair on the M2 Pro).
"""
import os, re, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRACKS = ("donovan", "huitzil", "pyron", "merged")
OUT_DIR = os.path.join(REPO, "tests", "expected", "freeze_bytediff")


def registry_sets():
    out = []
    for ln in open(os.path.join(REPO, "tests", "expected", "registry.tsv")):
        if ln.startswith("#") or not ln.strip():
            continue
        cols = ln.rstrip("\n").split("\t")
        if len(cols) > 1 and re.fullmatch(r"(%s)-m\d+" % "|".join(TRACKS), cols[1]):
            out.append(cols[1])
    return out


def tag_build_dir(name):
    msg = subprocess.run(["git", "-C", REPO, "tag", "-l", "--format=%(contents)", f"freeze/{name}"],
                         capture_output=True, text=True).stdout
    m = re.search(r"^build dir\s+(build/\S+)\s*$", msg, re.M)
    if not m:
        sys.exit(f"freeze_bytediff: tag freeze/{name} names no `build dir` (or the tag is missing)")
    return m.group(1)


def plan():
    sets = registry_sets()
    pairs = []
    for t in TRACKS:
        mine = [s for s in sets if s.startswith(t + "-m")]
        if len(mine) < 2:
            sys.exit(f"freeze_bytediff: track {t} has fewer than two registry rows")
        old, new = mine[-2], mine[-1]
        pairs.append((t, old, new, tag_build_dir(old), tag_build_dir(new)))
    return pairs


def render(pairs):
    lines = ["# freeze_bytediff record (tools/freeze_bytediff.py, #231): every program range the newest freeze changed,",
             "# per track, measured by tools/program_bytediff.py --record from each build's own decrypted romset.",
             "# Ranges and whole-image sha1s only, never bytes (CLAUDE.md rule 7). Reviewed at the freeze, then FREEZE=1."]
    for t, old, new, od, nd in pairs:
        lines.append(f"TRACK {t} {old} -> {new}")
        for d in (od, nd):
            if not os.path.isfile(os.path.join(REPO, d, "rompath", "vsavjw.zip")) and \
               not os.path.isfile(os.path.join(REPO, d, "rompath", "vsavj.zip")):
                sys.exit(f"freeze_bytediff: SKIP-WORTHY: no romset under {d}/rompath")
        r = subprocess.run([sys.executable, os.path.join(REPO, "tools", "program_bytediff.py"), "--record", od, nd],
                           capture_output=True, text=True, cwd=REPO)
        if r.returncode != 0:
            sys.exit(f"freeze_bytediff: program_bytediff failed on {od} -> {nd}: {r.stderr.strip()[-300:]}")
        lines += r.stdout.rstrip("\n").split("\n")
    return "\n".join(lines) + "\n"


def record_path(pairs):
    return os.path.join(OUT_DIR, [p for p in pairs if p[0] == "merged"][0][2] + ".txt")


def main(argv):
    cmd = argv[0] if argv else ""
    pairs = plan()
    if cmd == "plan":
        for p in pairs:
            print("\t".join(p))
    elif cmd == "render":
        sys.stdout.write(render(pairs))
    elif cmd == "freeze":
        os.makedirs(OUT_DIR, exist_ok=True)
        open(record_path(pairs), "w").write(render(pairs))
        print(f"wrote {os.path.relpath(record_path(pairs), REPO)}")
    elif cmd == "check":
        rec = argv[argv.index("--record") + 1] if "--record" in argv else record_path(pairs)
        if not os.path.isfile(rec):
            print(f"FAIL: no byte-diff record {os.path.relpath(rec, REPO)} for the newest freeze — review "
                  f"`python3 tools/freeze_bytediff.py render`, then `freeze`")
            return 1
        want, got = open(rec).read(), render(pairs)
        if want != got:
            import difflib
            print(f"FAIL: {os.path.relpath(rec, REPO)} differs from a fresh measurement:")
            sys.stdout.writelines("  " + l + "\n" for l in difflib.unified_diff(
                want.splitlines(), got.splitlines(), "record", "measured", lineterm="", n=0))
            return 1
        n = sum(1 for l in got.splitlines() if l.startswith("RANGE "))
        print(f"OK: {os.path.relpath(rec, REPO)} equals a fresh measurement ({n} ranges over {len(pairs)} tracks)")
    else:
        sys.exit(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
