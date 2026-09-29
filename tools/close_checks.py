#!/usr/bin/env python3
"""close_checks.py — the close's check runner: every check timed, one check re-run alone, and a
run of record that says whether it was FULL (14z-185b, GitHub #187, maintainer-ruled 2026-09-29
"D + E + F now").

WHY. The 14z-185 close ran its scratch check runner 62 times, 18,799 s in all
(tools/agent/close_loop_cost.py), always every check, and never recorded which check took the
time. This runner keeps every check and every plant; what it changes is that a fix is iterated
on the check being fixed (`--only`), each check's seconds are recorded, and the run of record
before a rule-checker `prepare` is visibly FULL.

THE CHECKS FILE (a session's own, under build/; tab-separated, `#` comments):
    name<TAB>expected exit<TAB>command
A command runs with `sh -c` from the repository root; its stdout and stderr go to
<out>/runs/<name>.out. A check is OK when its exit equals the expected exit (a plant expects
non-zero). A name is [A-Za-z0-9_.-]+ and unique.

Usage:
  python3 tools/close_checks.py run CHECKS --out DIR [--only NAME]...
      FULL without --only: every check, and <DIR>/exits.tsv is rewritten, its first line
      `# run: full <UTC> <HEAD> <checks sha256[:16]>`. With --only: only those checks, their rows
      replaced in the existing exits.tsv, and the first line becomes `# run: partial ...` — a
      partial run never reads as the run of record. Prints each check's verdict and seconds, the
      total and the five slowest; exit 0 when every check RUN is as expected.
  python3 tools/close_checks.py status CHECKS --out DIR
      exit 0 only when the last run was FULL, every row is OK, its checks file is the current one
      (same sha256), and every check of the file has a row — the state a `prepare` may cite.
  python3 tools/close_checks.py --selftest
      a synthetic checks file in a temp dir: a pass, an expected failure (a plant), a check NOT
      as expected; FULL then --only then status, each against its known answer.
"""
import hashlib, os, re, subprocess, sys, tempfile, time

NAME = re.compile(r"^[A-Za-z0-9_.-]+$")


def read_checks(path):
    rows, seen = [], set()
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        f = line.rstrip("\n").split("\t")
        if len(f) != 3 or not NAME.match(f[0]) or not re.match(r"^-?\d+$", f[1]) or not f[2].strip():
            sys.exit(f"{path}:{n}: expected name<TAB>expected exit<TAB>command")
        if f[0] in seen:
            sys.exit(f"{path}:{n}: duplicate check name {f[0]}")
        seen.add(f[0])
        rows.append((f[0], int(f[1]), f[2]))
    return rows


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()[:16]


def head(root):
    try:
        return subprocess.run(["git", "rev-parse", "--short=8", "HEAD"], cwd=root, capture_output=True,
                              text=True).stdout.strip() or "no-git"
    except OSError:
        return "no-git"


def read_exits(path):
    first, rows = "", {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            if line.startswith("# run:"):
                first = line.rstrip("\n")
            elif line.strip() and not line.startswith(("#", "name\t")):
                f = line.rstrip("\n").split("\t")
                rows[f[0]] = f
    return first, rows


def run(checks, out, only, root):
    rows = read_checks(checks)
    names = [r[0] for r in rows]
    for o in only:
        if o not in names:
            sys.exit(f"--only {o}: no such check in {checks}")
    todo = [r for r in rows if not only or r[0] in only]
    os.makedirs(os.path.join(out, "runs"), exist_ok=True)
    exits = os.path.join(out, "exits.tsv")
    _, old = read_exits(exits) if only else ("", {})
    new, bad = {}, 0
    for name, expect, cmd in todo:
        t0 = time.time()
        with open(os.path.join(out, "runs", name + ".out"), "w") as fh:
            st = subprocess.run(["sh", "-c", cmd], cwd=root, stdout=fh, stderr=subprocess.STDOUT).returncode
        secs = round(time.time() - t0, 1)
        verdict = "OK" if st == expect else "NOT AS EXPECTED"
        bad += verdict != "OK"
        new[name] = [name, str(expect), str(st), verdict, str(secs), cmd]
        print(f"  {name:40s} {verdict:16s} {secs:8.1f}s")
    merged = dict(old)
    merged.update(new)
    kind = "partial" if only else "full"
    stamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    with open(exits, "w", encoding="utf-8") as fh:
        fh.write(f"# run: {kind} {stamp} {head(root)} {sha(checks)}\n")
        fh.write("name\texpect\texit\tverdict\tseconds\tcommand\n")
        for n in names:
            if n in merged:
                fh.write("\t".join(merged[n]) + "\n")
    total = sum(float(v[4]) for v in new.values())
    slow = sorted(new.values(), key=lambda v: -float(v[4]))[:5]
    print(f"run: {kind}  checks run {len(new)}  not as expected {bad}  seconds {total:.1f}")
    print("slowest: " + "  ".join(f"{v[0]} {float(v[4]):.1f}s" for v in slow))
    return 0 if bad == 0 else 1


def status(checks, out):
    first, rows = read_exits(os.path.join(out, "exits.tsv"))
    names = [r[0] for r in read_checks(checks)]
    problems = []
    f = first.split()
    if len(f) < 6:
        problems.append("no run record")
    else:
        if f[2] != "full":
            problems.append(f"the last run was {f[2]}, not full")
        if f[5] != sha(checks):
            problems.append("the checks file changed since the last run")
    missing = [n for n in names if n not in rows]
    red = [n for n, r in rows.items() if r[3] != "OK"]
    if missing:
        problems.append("no row: " + " ".join(missing))
    if red:
        problems.append("not as expected: " + " ".join(red))
    print(first or "# run: none")
    print("status: " + ("RUN OF RECORD, all as expected" if not problems else "NOT A RUN OF RECORD — " + "; ".join(problems)))
    return 0 if not problems else 1


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as d:
        checks = os.path.join(d, "checks.tsv")
        out = os.path.join(d, "out")
        with open(checks, "w") as fh:
            fh.write("# synthetic\npasses\t0\techo fine\nplant\t1\texit 1\nwrong\t0\texit 3\n")
        def say(cond, what):
            nonlocal ok
            print(("  ok: " if cond else "  FAIL: ") + what)
            ok = ok and cond
        rc = run(checks, out, [], d)
        first, rows = read_exits(os.path.join(out, "exits.tsv"))
        say(rc == 1, "a full run with one check NOT as expected exits 1")
        say(rows["passes"][3] == "OK" and rows["plant"][3] == "OK" and rows["wrong"][3] == "NOT AS EXPECTED",
            "a pass and an expected failure read OK; a wrong exit reads NOT AS EXPECTED")
        say(first.split()[2] == "full", "a run without --only is recorded full")
        say(all(re.match(r"^\d+(\.\d)?$", r[4]) for r in rows.values()), "every row carries its seconds")
        with open(checks, "w") as fh:
            fh.write("# synthetic\npasses\t0\techo fine\nplant\t1\texit 1\nwrong\t0\ttrue\n")
        rc = run(checks, out, ["wrong"], d)
        first, rows = read_exits(os.path.join(out, "exits.tsv"))
        say(rc == 0 and rows["wrong"][3] == "OK" and first.split()[2] == "partial",
            "--only re-runs the one check, replaces its row, and records the run partial")
        say(status(checks, out) == 1, "status refuses a partial run as the run of record")
        run(checks, out, [], d)
        say(status(checks, out) == 0, "status accepts a full, all-OK run of the current checks file")
        with open(checks, "a") as fh:
            fh.write("added\t0\ttrue\n")
        say(status(checks, out) == 1, "status refuses a run older than its checks file")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    if len(a) < 4 or a[0] not in ("run", "status") or "--out" not in a:
        sys.exit(__doc__)
    checks, out = a[1], a[a.index("--out") + 1]
    only = [a[i + 1] for i, x in enumerate(a) if x == "--only"]
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd()
    return run(checks, out, only, root) if a[0] == "run" else status(checks, out)


if __name__ == "__main__":
    sys.exit(main())
