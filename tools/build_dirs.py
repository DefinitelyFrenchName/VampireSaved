#!/usr/bin/env python3
"""build_dirs.py — the ONE classing of build/'s top-level directories, and the forms generated from it (#304,
14z-207; maintainer-ruled 2026-10-23, "Adopt all four (Recommended)").

THE LIST is tests/expected/build_dirs.tsv: `class<TAB>pattern<TAB>reason`, class scratch | input | kept | fixture, a
pattern one path component (a glob of `*`, `?`, `[...]`). A name's class is the first of CLASSES with a row matching
it. From the `scratch` rows this module GENERATES the two forms the planner uses, so they are never written twice:
  scratch_regex()   `^build/(?:<one alternative per row>)/` — tools/static_confirm.py's N-D rule (drop_scratch)
  pathspecs()       `:(exclude,glob)build/<pattern>/**` — the planner's pruned `git ls-files --others`
Written apart they disagreed (14z-207, build/agent207/t304/recheck/plant_prune.txt): the regex `agent\\d+\\w*` keeps
build/agent7-x/ and build/agent7.d/, which the glob `agent[0-9]*` prunes. A glob row is the source; the regex is
translated from it one component wide (`*` -> `[^/]*`), which is git's glob magic for one component. Both are
case-sensitive (git's pathspec is, under core.ignorecase too: measured on this Mac, 14z-207).

THE CENSUS (`census`): every build/<top> a tracked program under tools/ or tests/ names literally, and every directory
under build/ in the tree, must be classed; a name matching a scratch row and a row of another class fails; with
--plant, a throwaway git repository with each scratch pattern's instance and its near misses (`<x>-x`, `<x>.d`, a
changed case, a suffix) must give the same verdict from the pathspec listing and from the regex, path by path.

Usage:
  python3 tools/build_dirs.py classify NAME...         the class of each build/ top-level name
  python3 tools/build_dirs.py regex | pathspec          the generated scratch forms
  python3 tools/build_dirs.py census [--root DIR] [--plant] [--list FILE]
  python3 tools/build_dirs.py --selftest
"""
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
# a gate that runs a COPY of the planner in a synthetic root copies the list beside it (copy_beside)
LIST = next((p for p in (os.path.join(HERE, "..", "tests", "expected", "build_dirs.tsv"),
                         os.path.join(HERE, "build_dirs.tsv")) if os.path.exists(p)),
            os.path.join(HERE, "..", "tests", "expected", "build_dirs.tsv"))
CLASSES = ("scratch", "input", "kept", "fixture")
PATTERN = re.compile(r"[\w.*?\[\]!^-]+")
# the code the census reads: tracked PROGRAMS under tools/ and tests/, not their data and fixture trees
# tools/build_dirs.py itself is skipped: its selftest names hypothetical build/ dirs (plants and near misses) on
# purpose. Fork J ran the census before this file was tracked, so git ls-files never fed it these (14z-207)
CODE_SKIP = re.compile(r"^(?:tests/(?:rulecheck|expected|expect|replays|inp|goldens|fixtures|agent)/|tools/build_dirs\.py$)")
CODE_PROG = re.compile(r"\.(?:sh|py|lua|mjs|js)$")
NAMED = re.compile(r"(?<![\w.-])build/([A-Za-z0-9_.][\w.-]*)")
FILE_EXT = re.compile(r"\.[A-Za-z][A-Za-z0-9]{0,8}$")   # a top-level FILE (x.log, out.bin): out of the list's scope


def copy_beside(dest):
    """copy this module and its list into dest, where a copied tools/static_confirm.py imports them"""
    import shutil
    shutil.copy(os.path.join(HERE, "build_dirs.py"), dest)
    shutil.copy(LIST, os.path.join(dest, "build_dirs.tsv"))


def load(path=None):
    rows = []
    for n, line in enumerate(open(path or LIST, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        c = line.split("\t")
        if len(c) != 3 or c[0] not in CLASSES or not PATTERN.fullmatch(c[1]) or not c[2].strip():
            raise ValueError(f"{path or LIST}:{n}: not `class<TAB>pattern<TAB>reason` with a known class: {line!r}")
        rows.append((c[0], c[1], c[2]))
    return rows


def glob_rx(pat):
    """one path component's glob as a regex: `*` and `?` never cross `/` (git's glob magic)"""
    out, i = [], 0
    while i < len(pat):
        ch = pat[i]
        if ch == "*":
            out.append("[^/]*")
        elif ch == "?":
            out.append("[^/]")
        elif ch == "[":
            j = pat.index("]", i + 1)
            body = pat[i + 1:j]
            if body[:1] in ("!", "^"):
                body = "^" + body[1:]
            out.append("[" + body.replace("\\", "\\\\") + "]")
            i = j
        else:
            out.append(re.escape(ch))
        i += 1
    return "".join(out)


def scratch_rows(rows):
    return [p for c, p, _ in rows if c == "scratch"]


def scratch_regex(rows=None):
    return re.compile(r"^build/(?:" + "|".join(glob_rx(p) for p in scratch_rows(rows or load())) + r")/")


def pathspecs(rows=None):
    return [f":(exclude,glob)build/{p}/**" for p in scratch_rows(rows or load())]


def classify(rows, name):
    for cls in CLASSES:
        if any(c == cls and re.fullmatch(glob_rx(p), name) for c, p, _ in rows):
            return cls
    return None


def code_names(root):
    r = subprocess.run(["git", "ls-files", "tools", "tests"], cwd=root, capture_output=True, text=True)
    names = {}
    for f in r.stdout.splitlines():
        if CODE_SKIP.match(f) or not CODE_PROG.search(f):
            continue
        try:
            t = open(os.path.join(root, f), encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for m in NAMED.finditer(t):
            n = m.group(1).rstrip(".")
            if n and not FILE_EXT.search(n):
                names.setdefault(n, f)
    return names


def live_dirs(root):
    b = os.path.join(root, "build")
    return sorted(d for d in os.listdir(b) if os.path.isdir(os.path.join(b, d))) if os.path.isdir(b) else []


def plant_names(rows):
    """each scratch pattern's instance and near misses on both sides of the rule"""
    out = set()
    for p in scratch_rows(rows):
        inst = re.sub(r"\[([^\]])[^\]]*\]", r"\1", p.replace("[!", "[")).replace("*", "7").replace("?", "q")
        inst = inst.replace("[", "").replace("]", "")
        out |= {inst, inst + "-x", inst + ".d", inst + "x", inst + "_x", inst.upper(), "x" + inst, inst + "7"}
        if "*" in p:
            out |= {p.replace("*", ""), p.replace("*", "-x"), p.replace("*", ".d")}
    out |= {"agent7-x", "agent7.d", "agentX", "agent", "agents", "agent_7", "sheets2", "sheet", "rulecheckX",
            "static_runsX", "Agent7", "SHEETS"}
    return sorted(n for n in out if PATTERN.fullmatch(n) and "[" not in n and "*" not in n and "?" not in n)


def plant_check(rows):
    """-> (problems, lines): the pathspec listing and the regex judge each planted path alike"""
    rx, specs = scratch_regex(rows), pathspecs(rows)
    names = plant_names(rows)
    lines, problems = [], []
    with tempfile.TemporaryDirectory() as P:
        subprocess.run(["git", "init", "-q"], cwd=P, check=True)
        for n in names:
            d = os.path.join(P, "build", n)
            os.makedirs(os.path.join(d, "sub"), exist_ok=True)
            for f in ("f.txt", os.path.join("sub", "g.sh")):
                open(os.path.join(d, f), "w").write("x\n")
        full = subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], cwd=P, capture_output=True,
                              text=True, check=True).stdout.splitlines()
        kept = set(subprocess.run(["git", "ls-files", "--others", "--exclude-standard", "--", "."] + specs, cwd=P,
                                  capture_output=True, text=True, check=True).stdout.splitlines())
    for p in sorted(full):
        by_spec, by_rx = p not in kept, bool(rx.match(p))
        lines.append(f"{'PRUNED' if by_spec else 'KEPT  '} {'DROPPED' if by_rx else 'JUDGED '} {p}")
        if by_spec != by_rx:
            problems.append(f"PLANT {p}: the pathspec {'prunes' if by_spec else 'keeps'} it, the regex "
                            f"{'drops' if by_rx else 'judges'} it")
    if not full:
        problems.append("PLANT: the throwaway repository listed nothing")
    return problems, lines


def census(root, rows, plant=False):
    problems, lines = [], []
    named = code_names(root)
    for n, f in sorted(named.items()):
        cls = classify(rows, n)
        lines.append(f"code  {cls or 'UNCLASSED':9s} build/{n}   ({f})")
        if cls is None:
            problems.append(f"UNCLASSED build/{n}: named by {f}")
    for n in live_dirs(root):
        cls = classify(rows, n)
        lines.append(f"tree  {cls or 'UNCLASSED':9s} build/{n}/")
        if cls is None:
            problems.append(f"UNCLASSED build/{n}/: a directory of this tree")
    for n in sorted(set(named) | set(live_dirs(root)) | set(plant_names(rows))):
        hit = {c for c, p, _ in rows if re.fullmatch(glob_rx(p), n)}
        if "scratch" in hit and len(hit) > 1:
            problems.append(f"AMBIGUOUS build/{n}: scratch and {', '.join(sorted(hit - {'scratch'}))}")
    if plant:
        pp, pl = plant_check(rows)
        problems += pp
        lines += ["plant " + x for x in pl]
    return problems, lines


def selftest():
    ok = True
    rows = [("scratch", "agent[0-9]*", "r"), ("scratch", "sheets", "r"), ("input", "out", "r"),
            ("input", "m5_*", "r"), ("kept", "*_14z[0-9]*", "r"), ("fixture", "x", "r")]
    rx = scratch_regex(rows)
    for c, want in (("build/agent7/a", True), ("build/agent207b/a", True), ("build/agent7-x/a", True),
                    ("build/agent7.d/a", True), ("build/agentX/a", False), ("build/agent/a", False),
                    ("build/sheets/a", True), ("build/sheets2/a", False), ("build/SHEETS/a", False),
                    ("build/out/a", False), ("tools/agent7/a", False), ("build/agent7", False)):
        good = bool(rx.match(c)) == want
        ok = ok and good
        print(f"  {'ok' if good else 'FAIL'}: scratch_regex({c}) = {bool(rx.match(c))}")
    for n, want in (("agent9", "scratch"), ("m5_stock22", "input"), ("advancing_guard_14z123", "kept"),
                    ("x", "fixture"), ("nope", None), ("m5", None)):
        good = classify(rows, n) == want
        ok = ok and good
        print(f"  {'ok' if good else 'FAIL'}: classify({n}) = {classify(rows, n)}")
    good = pathspecs(rows) == [":(exclude,glob)build/agent[0-9]*/**", ":(exclude,glob)build/sheets/**"]
    ok = ok and good
    print(f"  {'ok' if good else 'FAIL'}: pathspecs = {pathspecs(rows)}")
    problems, _ = plant_check(rows)
    good = not problems
    ok = ok and good
    print(f"  {'ok' if good else 'FAIL'}: the generated pathspec and regex agree on {len(plant_names(rows))} planted names"
          + ("" if good else "; " + "; ".join(problems[:3])))
    # the census of a synthetic repository: a program names build/zz_code/ and build/agent7/, the tree holds
    # build/zz_live/ and build/agent9/, and one more row makes build/agent7x both scratch and input
    with tempfile.TemporaryDirectory() as R:
        os.makedirs(os.path.join(R, "tools"))
        open(os.path.join(R, "tools", "w.py"), "w").write('OUT = "build/zz_code/a"\nTMP = "build/agent7/b"\n'
                                                         'X = "build/agent7x/c"\n')
        for d in ("zz_live", "agent9"):
            os.makedirs(os.path.join(R, "build", d))
        subprocess.run(["git", "init", "-q"], cwd=R, check=True)
        subprocess.run(["git", "add", "tools/w.py"], cwd=R, check=True)
        problems, _ = census(R, rows + [("input", "agent7x", "r")])
        for want in ("UNCLASSED build/zz_code: named by tools/w.py", "UNCLASSED build/zz_live/: a directory of this tree",
                     "AMBIGUOUS build/agent7x: scratch and input"):
            good = want in problems
            ok = ok and good
            print(f"  {'ok' if good else 'FAIL'}: census reports {want!r}")
        good = len(problems) == 3
        ok = ok and good
        print(f"  {'ok' if good else 'FAIL'}: census reports nothing else ({len(problems)} problem(s))"
              + ("" if good else f": {problems}"))
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    def opt(k):
        return a[a.index(k) + 1] if k in a else None
    rows = load(opt("--list"))
    if a[:1] == ["classify"]:
        for n in a[1:]:
            print(f"{n}\t{classify(rows, n) or 'UNCLASSED'}")
        return 0
    if a[:1] == ["regex"]:
        print(scratch_regex(rows).pattern)
        return 0
    if a[:1] == ["pathspec"]:
        print("\n".join(pathspecs(rows)))
        return 0
    if a[:1] == ["census"]:
        problems, lines = census(os.path.abspath(opt("--root") or "."), rows, "--plant" in a)
        for x in lines:
            print("  " + x)
        for x in problems:
            print("PROBLEM: " + x)
        print(f"census: {len(problems)} problem(s)")
        return 1 if problems else 0
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main())
