#!/usr/bin/env python3
"""run_record.py — WHAT A RUN RAN ON, recorded at its start and end (14z-185b, GitHub #189, maintainer-ruled
2026-09-29: "R-reach, both runners").

WHY. A runner's only record was `commit.txt`: HEAD plus the paths of dirty TRACKED files. In the 14z-185 close,
rule-checker runs 429-431, 434, 435 and 441 each had to rebuild, after the fact, what an emulator run had executed:
untracked files, the tree then against the tree now, removed files, files changed during the run. This record
makes that one comparison. It does NOT record what a run's logs showed: that stays the logs' job.

A RECORD (JSON) holds:
  head        `git rev-parse HEAD`
  status      `git status --porcelain --untracked-files=all`, build/ and docs/site/ left out (untracked by
              convention; a run's build products are fingerprinted by the runner itself)
  files       sha256 of every path the status names that exists (dirty, added and untracked alike)
  submodules  each submodule's checked-out SHA, a sha256 of its `git diff HEAD`, and its untracked files
  argv        the runner's exact command line
  env         the value of every ALLOWED variable that is set (ALLOW below), and the NAMES of all others —
              never a value outside the allow-list, never a name that reads as a secret (SECRETISH). An END
              record carries the START's environment (a runner exports its own defaults after the start)
              and keeps what it saw as env_at_end, never compared
  reach       sha256 of every program in the reach of the registered gates and the runner: ONE strict
              closure (tools/battery_reach.py, code lines only) at start; the end record re-hashes the
              start's list (no second closure)

Usage:
  python3 tools/run_record.py write OUT --phase start|end --registry REG [--registry REG]... [--runner PATH]
                              [--start START.json] -- ARGV...
      REG is a registry file whose first column names gates (tests/ci_portable.txt, tests/ci_static.txt,
      tests/ci_emulator.tsv). An END record given --start re-hashes the start's reach list.
  python3 tools/run_record.py compare A.json (B.json | --now)
      prints every field that differs, one line per difference; --now builds a fresh record of the tree
      (argv and env are not compared against --now: they are the caller's). Exit 0 none, 1 any.
  python3 tools/run_record.py --selftest
      a synthetic repository with a submodule: one planted change per recorded field, each named by
      compare (a plant may be named under two fields: an edited program is a status line AND a reach
      change); an untracked build/ product and a record against itself are not differences.
"""
import hashlib, json, os, re, subprocess, sys, tempfile, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

ALLOW = re.compile(r"^(ROMDIR|MAME_\w+|FBNEO_\w+|WIDE_\w+|JTSIM_\w+|MISTER_\w+|STALE|CONTROL|VS_\w+|BBH_\w+|KEY_SET|"
                   r"GEN_FLAGS|TENANT_\w+|STATIC_\w+|EMU_\w+|SNAP_\w+|FREEZE|LANE|CADENCE|PATH|PYTHONPATH)$")
SECRETISH = re.compile(r"TOKEN|SECRET|PASSW|AUTH|CREDENTIAL|COOKIE|SESSION_KEY|API_?KEY", re.I)
SKIP_PREFIXES = ("build/", "docs/site/")


def git(root, *a):
    return subprocess.run(["git", *a], cwd=root, capture_output=True, text=True).stdout


def sha_file(path):
    h = hashlib.sha256()
    try:
        with open(path, "rb") as fh:
            for b in iter(lambda: fh.read(1 << 20), b""):
                h.update(b)
    except OSError:
        return "unreadable"
    return h.hexdigest()


def status(root):
    lines, paths = [], []
    for l in git(root, "status", "--porcelain", "--untracked-files=all", "--ignore-submodules=none").split("\n"):
        if not l.strip():
            continue
        p = l[3:].split(" -> ")[-1].strip('"')
        if p.startswith(SKIP_PREFIXES):
            continue
        lines.append(l)
        paths.append(p)
    return sorted(lines), sorted(set(paths))


def submodules(root):
    out = {}
    for l in git(root, "submodule", "status", "--recursive").split("\n"):
        f = l.split()
        if len(f) < 2:
            continue
        path = f[1]
        d = os.path.join(root, path)
        diff = subprocess.run(["git", "diff", "HEAD"], cwd=d, capture_output=True).stdout
        untracked = git(d, "ls-files", "--others", "--exclude-standard").split()
        out[path] = {"sha": f[0].lstrip("+-U"), "diff_sha256": hashlib.sha256(diff).hexdigest(),
                     "untracked": sorted(untracked)}
    return out


def env():
    vals, names = {}, []
    for k, v in sorted(os.environ.items()):
        if SECRETISH.search(k):
            continue
        names.append(k)
        if ALLOW.match(k):
            vals[k] = v
    return {"values": vals, "names": names}


def reach_list(root, registries, runner):
    import battery_reach as br
    starts = [runner] if runner else []
    for reg in registries:
        for line in open(os.path.join(root, reg), encoding="utf-8"):
            n = line.split("#", 1)[0].split("\t")[0].strip()
            if n:
                for ext in (".sh", ".py", ".lua"):
                    if os.path.isfile(os.path.join(root, "tests", n + ext)):
                        starts.append(f"tests/{n}{ext}")
                        break
    br.STRICT[0] = True
    br.EXTRA[:] = []
    seen, _ = br.closure(root, starts, br.index(root, []))
    return sorted(seen)


def build(root, registries=(), runner=None, start=None, argv=None, phase="now"):
    lines, paths = status(root)
    rec = {"phase": phase, "utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "head": git(root, "rev-parse", "HEAD").strip(), "status": lines,
           "files": {p: sha_file(os.path.join(root, p)) for p in paths if os.path.isfile(os.path.join(root, p))},
           "submodules": submodules(root), "argv": argv or [], "env": env()}
    if start is not None:
        rlist = sorted(start.get("reach", {}))
    elif registries:
        rlist = reach_list(root, registries, runner)
    else:
        rlist = []
    rec["reach"] = {p: sha_file(os.path.join(root, p)) for p in rlist}
    return rec


def compare(a, b, with_caller=True):
    diffs = []
    if a["head"] != b["head"]:
        diffs.append(f"head: {a['head'][:12]} -> {b['head'][:12]}")
    sa, sb = set(a["status"]), set(b["status"])
    for l in sorted(sa - sb):
        diffs.append(f"status: gone   {l}")
    for l in sorted(sb - sa):
        diffs.append(f"status: new    {l}")
    for p in sorted(set(a["files"]) & set(b["files"])):
        if a["files"][p] != b["files"][p]:
            diffs.append(f"files: content changed  {p}")
    for p in sorted(set(a["submodules"]) | set(b["submodules"])):
        x, y = a["submodules"].get(p), b["submodules"].get(p)
        if x != y:
            what = [k for k in ("sha", "diff_sha256", "untracked") if (x or {}).get(k) != (y or {}).get(k)]
            diffs.append(f"submodule: {p} {'/'.join(what) or 'added or removed'}")
    for p in sorted(set(a["reach"]) & set(b["reach"])):
        if a["reach"][p] != b["reach"][p]:
            diffs.append(f"reach: program changed  {p}")
    if with_caller:
        if a["argv"] != b["argv"]:
            diffs.append(f"argv: {' '.join(a['argv'])!r} -> {' '.join(b['argv'])!r}")
        va, vb = a["env"]["values"], b["env"]["values"]
        for k in sorted(set(va) | set(vb)):
            if va.get(k) != vb.get(k):
                diffs.append(f"env: {k}")
    return diffs


def selftest():
    ok = True
    def say(cond, what):
        nonlocal ok
        print(("  ok: " if cond else "  FAIL: ") + what)
        ok = ok and cond
    with tempfile.TemporaryDirectory() as d:
        def sh(cwd, *cmd):
            subprocess.run(cmd, cwd=cwd, check=True, capture_output=True)
        def w(rel, t, root=None):
            p = os.path.join(root or repo, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w").write(t)
        cfg = ["-c", "user.email=t@t", "-c", "user.name=t", "-c", "protocol.file.allow=always"]
        sub = os.path.join(d, "sub")
        os.makedirs(sub)
        sh(sub, "git", "init", "-q")
        w("lib.txt", "x\n", sub)
        sh(sub, "git", *cfg, "add", "-A")
        sh(sub, "git", *cfg, "commit", "-qm", "s")
        repo = os.path.join(d, "repo")
        os.makedirs(repo)
        sh(repo, "git", "init", "-q")
        w("tests/ci_portable.txt", "g_one\n")
        w("tests/g_one.sh", "#!/bin/sh\npython3 tools/helper.py\n")
        w("tools/helper.py", "print(1)\n")
        w("tools/battery_reach.py", open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "battery_reach.py")).read())
        w("doc.md", "text\n")
        w("gone.md", "text\n")
        w(".gitignore", "build/\n")
        sh(repo, "git", *cfg, "add", "-A")
        sh(repo, "git", *cfg, "commit", "-qm", "c1")
        sh(repo, "git", *cfg, "submodule", "add", "-q", sub, "emu/sub")
        sh(repo, "git", *cfg, "commit", "-qm", "c2")
        os.environ.pop("ROMDIR", None)
        os.environ["ROMDIR"] = "/roms/a"
        os.environ["SELFTEST_API_TOKEN"] = "hunter2"
        base = build(repo, ["tests/ci_portable.txt"], "tests/g_one.sh", argv=["runner", "--strict"], phase="start")
        say("tools/helper.py" in base["reach"], "the reach holds the program the gate runs (tools/helper.py)")
        say("SELFTEST_API_TOKEN" not in base["env"]["names"] and "hunter2" not in json.dumps(base),
            "a secret-looking variable is neither named nor valued")
        say(base["env"]["values"].get("ROMDIR") == "/roms/a", "an allow-listed variable is recorded with its value")
        w("build/product.bin", "p\n")
        say(compare(base, build(repo, start=base, argv=base["argv"])) == [], "an untracked build/ product is not a difference")
        plants = [
            ("head", lambda: (w("new.md", "n\n"), sh(repo, "git", *cfg, "add", "new.md"), sh(repo, "git", *cfg, "commit", "-qm", "c3"))),
            ("dirtied", lambda: w("doc.md", "changed\n")),
            ("removed", lambda: os.remove(os.path.join(repo, "gone.md"))),
            ("untracked", lambda: w("stray.txt", "s\n")),
            ("submodule", lambda: w("lib.txt", "y\n", os.path.join(repo, "emu/sub"))),
            ("reach", lambda: w("tools/helper.py", "print(2)\n")),
            # a file ALREADY dirty, edited again: its status line does not change, only its content hash —
            # the during-a-run case commit.txt could never show
            ("re-edited", lambda: w("doc.md", "changed again\n")),
        ]
        expect = {"head": "head:", "dirtied": "doc.md", "removed": "gone.md", "untracked": "stray.txt",
                  "submodule": "submodule: emu/sub", "reach": "reach: program changed  tools/helper.py",
                  "re-edited": "files: content changed  doc.md"}
        prev = base
        for name, act in plants:
            act()
            now = build(repo, start=base, argv=base["argv"])
            ds = compare(prev, now)
            say(any(expect[name] in x for x in ds) and len(ds) >= 1,
                f"plant {name}: compare names it ({'; '.join(ds)[:140]})")
            prev = now
        a = build(repo, start=base, argv=["runner", "--strict"])
        os.environ["ROMDIR"] = "/roms/b"
        b = build(repo, start=base, argv=["runner", "--tier", "static"])
        ds = compare(a, b)
        say(any(x.startswith("argv:") for x in ds), "plant argv: a different command line is named")
        say(any(x == "env: ROMDIR" for x in ds), "plant env: a changed allow-listed variable is named")
        say(compare(b, b) == [], "a record compared with itself has no difference")
        os.environ.pop("SELFTEST_API_TOKEN", None)
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or os.getcwd()
    if a[:1] == ["write"] and len(a) >= 2:
        out = a[1]
        argv = a[a.index("--") + 1:] if "--" in a else []
        head = a[:a.index("--")] if "--" in a else a
        opt = lambda k: [head[i + 1] for i, x in enumerate(head) if x == k]
        start = json.load(open(opt("--start")[0])) if opt("--start") else None
        rec = build(root, opt("--registry"), (opt("--runner") or [None])[0], start, argv, (opt("--phase") or ["?"])[0])
        if start is not None:
            # an END record's environment is the one the run STARTED with: a runner exports its own
            # defaults after the start (measured 14z-185b: the emulator driver's MAME_BIN), which is not
            # a change to what the run was given. What the end saw is kept, and never compared.
            rec["env_at_end"], rec["env"] = rec["env"], start["env"]
        os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
        with open(out, "w") as fh:
            json.dump(rec, fh, indent=1, sort_keys=True)
        return 0
    if a[:1] == ["compare"] and len(a) == 3:
        A = json.load(open(a[1]))
        if a[2] == "--now":
            B, caller = build(root, start=A), False
        else:
            B, caller = json.load(open(a[2])), True
        ds = compare(A, B, caller)
        for x in ds:
            print(x)
        print(f"differences: {len(ds)}")
        return 1 if ds else 0
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main())
