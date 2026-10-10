#!/usr/bin/env python3
"""submodule_pins.py — does every submodule pin in the commit about to be pushed EXIST on its remote?
(14z-197, GitHub #260; maintainer-ruled 2026-10-09 "A ticket for the check (close-check line or pre-push hook).")

WHY. At the 14z-192 M23 freeze `main`'s emu/jtcores pin moved to 793339da, a commit of the jtcores fork that was
committed on the Mac and never pushed, while `main` was. Every fresh clone's `git submodule update` then failed to
fetch the pin (CI died at checkout, run 37842839748). The pin moves at every freeze, and HANDOFF's push-order note
("pushing a pin bump ahead of the fork commit it names breaks a fresh clone's `git submodule update`") is a
sentence, not a check. The local submodule clone HOLDS the commit, which is why nothing local could see it: only
the remote can answer.

THE CHECK. For each gitlink (mode 160000) in REV's tree, the URL is the one REV's .gitmodules gives (what a fresh
clone uses, not this checkout's .git/config), and the pin is fetched BY SHA into an empty scratch repository:
`git fetch --depth=1 --filter=tree:0 <url> <sha>` — the commit object only, under a second against GitHub
(measured 14z-197 on the jtcores and MAME pins). The remote answers `not our ref` for a commit it does not have
(a fetch by sha succeeds for any commit reachable from the remote's refs, a branch tip or not; measured on
GitHub and on a file:// remote, 14z-197). That is the exact operation a fresh clone's `git submodule update`
performs, so the verdict is the clone's.

  OK       the remote served the pinned commit
  MISSING  the remote refused it — push the submodule's commit first, then this repository
  ERROR    the check could not ask (network, an unknown repository, a relative URL, a timeout): not a pass

Usage:
  python3 tools/submodule_pins.py [--rev REV] [--root DIR]
      exit 0 every pin OK, 1 any MISSING, 2 any ERROR (and none MISSING), 3 the check could not run
  python3 tools/submodule_pins.py --plant PATH [--rev REV]
      the same check with PATH's pin replaced by a commit made in a scratch repository now, which no remote
      has: the close's plant, which must exit 1 naming PATH (exit 3 when the plant cannot be built)
  python3 tools/submodule_pins.py --selftest
      a bare file:// remote, a clone holding one commit it never pushed, and a superproject pinning a tip, an
      ancestor, the unpushed commit, an unreachable URL and a plant — each against its known exit
"""
import argparse, os, subprocess, sys, tempfile

TIMEOUT = 120
REFUSED = ("not our ref", "couldn't find remote ref", "no such remote ref")


def die(msg, code=3):
    """exit 3: the check could not run (never 1, which a plant row reads as its expected refusal)."""
    print(f"submodule_pins: {msg}", file=sys.stderr)
    sys.exit(code)


def git(args, cwd, timeout=TIMEOUT, env=None):
    return subprocess.run(["git"] + args, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=env)


def pins(root, rev):
    """[(path, sha, url)] for every gitlink in REV, the URL from REV's .gitmodules (None when absent)."""
    t = git(["ls-tree", "-r", rev], root)
    if t.returncode:
        die(f"git ls-tree {rev}: {t.stderr.strip()}")
    links = []
    for line in t.stdout.splitlines():
        meta, path = line.split("\t", 1)
        mode, kind, sha = meta.split()
        if mode == "160000":
            links.append((path, sha))
    urls = {}
    if links:
        c = git(["config", "--blob", f"{rev}:.gitmodules", "--get-regexp", r"^submodule\..*\.(path|url)$"], root)
        byname = {}
        for line in c.stdout.splitlines():
            key, _, val = line.partition(" ")
            name, field = key[len("submodule."):].rsplit(".", 1)
            byname.setdefault(name, {})[field] = val
        urls = {d["path"]: d.get("url") for d in byname.values() if "path" in d}
    return [(p, s, urls.get(p)) for p, s in links]


def fresh_commit():
    """A commit made now in a scratch repository: a real-shaped sha no remote holds."""
    with tempfile.TemporaryDirectory() as d:
        git(["init", "-q"], d)
        env = dict(os.environ, GIT_AUTHOR_NAME="plant", GIT_AUTHOR_EMAIL="plant@invalid",
                   GIT_COMMITTER_NAME="plant", GIT_COMMITTER_EMAIL="plant@invalid")
        r = git(["commit", "-q", "--allow-empty", "-m", f"submodule_pins plant {os.urandom(8).hex()}"], d, env=env)
        if r.returncode:
            die(f"could not make the plant commit: {r.stderr.strip()}")
        return git(["rev-parse", "HEAD"], d).stdout.strip()


def ask(url, sha):
    """('OK'|'MISSING'|'ERROR', detail) — the remote's own answer to a fetch of SHA."""
    if not url:
        return "ERROR", "no url in .gitmodules for this path"
    if url.startswith("."):
        return "ERROR", f"relative url {url} (resolve it against the superproject's remote first)"
    with tempfile.TemporaryDirectory() as d:
        git(["init", "-q"], d)
        try:
            r = git(["-c", "protocol.version=2", "fetch", "-q", "--no-tags", "--depth=1", "--filter=tree:0",
                     url, sha], d, env=dict(os.environ, GIT_TERMINAL_PROMPT="0"))
        except subprocess.TimeoutExpired:
            return "ERROR", f"the fetch took over {TIMEOUT} s"
        err = " ".join(l for l in r.stderr.strip().splitlines() if "filtering not recognized" not in l)
        if r.returncode == 0:
            got = git(["cat-file", "-t", sha], d).stdout.strip()
            return ("OK", "served") if got == "commit" else ("ERROR", f"the fetch succeeded but {sha[:8]} is {got or 'absent'}")
        if any(m in err for m in REFUSED):
            return "MISSING", err
        return "ERROR", err or f"git fetch exited {r.returncode}"


def check(root, rev, plant=None):
    rows = pins(root, rev)
    if plant:
        if plant not in [p for p, _, _ in rows]:
            die(f"--plant {plant}: no gitlink at that path in {rev}")
        new = fresh_commit()
        rows = [(p, new if p == plant else s, u) for p, s, u in rows]
        print(f"  plant {plant}: pin replaced by {new[:8]}, a commit made now that no remote holds")
    counts = {"OK": 0, "MISSING": 0, "ERROR": 0}
    for path, sha, url in rows:
        v, detail = ask(url, sha)
        counts[v] += 1
        if v == "OK":
            print(f"  OK       {path} {sha[:8]} on {url}")
        elif v == "MISSING":
            print(f"  MISSING  {path} {sha[:8]} is not on {url} — push it first "
                  f"(`git -C {path} push <remote> {sha[:8]}:<branch>`), then this repository: {detail}")
        else:
            print(f"  ERROR    {path} {sha[:8]} could not be checked on {url}: {detail}")
    print(f"pins checked {len(rows)}  ok {counts['OK']}  missing {counts['MISSING']}  unchecked {counts['ERROR']}  (rev {rev})")
    return 1 if counts["MISSING"] else 2 if counts["ERROR"] else 0


def selftest():
    ok = True
    env = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t",
               GIT_COMMITTER_EMAIL="t@t")
    with tempfile.TemporaryDirectory() as w:
        remote, clone, sup = (os.path.join(w, n) for n in ("remote.git", "clone", "super"))
        git(["init", "-q", "--bare", remote], w)
        git(["init", "-q", clone], w)
        shas = []
        for msg in ("a", "b", "c"):
            git(["commit", "-q", "--allow-empty", "-m", msg], clone, env=env)
            shas.append(git(["rev-parse", "HEAD"], clone).stdout.strip())
            if msg == "b":
                git(["push", "-q", remote, "HEAD:refs/heads/main"], clone)
        a, b, c = shas   # a: an ancestor on the remote, b: its tip, c: ONLY in the clone (the 14z-192 shape)
        git(["init", "-q", sup], w)
        url = "file://" + remote

        def pin(pairs, gone_url=None):
            mods = ""
            for path, sha in pairs:
                u = gone_url if (gone_url and path == "emu/y") else url
                mods += f'[submodule "{path}"]\n\tpath = {path}\n\turl = {u}\n'
                git(["update-index", "--add", "--cacheinfo", f"160000,{sha},{path}"], sup)
            open(os.path.join(sup, ".gitmodules"), "w").write(mods)
            git(["add", ".gitmodules"], sup)
            git(["commit", "-q", "--allow-empty", "-m", "pin"], sup, env=env)

        cases = [
            ("a tip on the remote", [("emu/x", b)], None, None, 0),
            ("an ancestor on the remote, not a tip", [("emu/x", a)], None, None, 0),
            ("a commit only the local clone holds", [("emu/x", c)], None, None, 1),
            ("one of two pins unpushed", [("emu/x", b), ("emu/y", c)], None, None, 1),
            ("an unreachable remote", [("emu/x", b), ("emu/y", b)], "file://" + os.path.join(w, "gone.git"), None, 2),
            ("the plant on a passing tree", [("emu/x", b)], None, "emu/x", 1),
        ]
        for name, pairs, gone, plant, want in cases:
            git(["rm", "-q", "-r", "--cached", "--ignore-unmatch", "emu"], sup)
            pin(pairs, gone)
            print(f"-- case {name}")
            got = check(sup, "HEAD", plant)
            g = got == want
            ok = ok and g
            print(("  ok: " if g else "  FAIL: ") + f"case {name}: exit {got}, expected {want}")
        have = git(["cat-file", "-t", c], clone).stdout.strip()
        g = have == "commit"
        ok = ok and g
        print(("  ok: " if g else "  FAIL: ") + f"the unpushed commit {c[:8]} is present locally ({have or 'absent'}), "
              "so a check that asked the local clone would have passed it")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--rev", default="HEAD")
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--plant", metavar="PATH")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    return check(a.root, a.rev, a.plant)


if __name__ == "__main__":
    sys.exit(main())
