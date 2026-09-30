#!/usr/bin/env python3
"""freeze_expectation_set.py — THE committed freeze driver for expectation sets (14z-185b, GitHub #150, maintainer-
ruled 2026-09-29 "D1 full driver"). What each freeze's scratch carry.py + run.sh did, once, with its three
silent-green failure modes closed by construction (docs/project/gotchas.md, 14z-159):

  1. MAME_BIN is PINNED here (`$HOME/.cache/vampire-saved/mame/cps2`, the tree's pin, unless already set): an
     unpinned run falls back to Homebrew's MAME, which has no `vsavjw`.
  2. The authored classes are CARRIED from the predecessor (P1: the family's highest lower number) BEFORE the
     freeze — `.masked`, `.skip` and `mask`, byte-verbatim — so a freeze never starts from an empty directory.
  3. A `merged-m*` set's `.sha1` and `logs/` are REMOVED after the freeze (#111: tenant-content expectations
     belong to the solo sets) — AFTER the set's verify, which reads them (see the note in one()).
Every set is VERIFIED (`tests/run_suite.sh` without --freeze) and its SHAPE checked
(`tools/freeze_set_shape.py --set`).

PRECONDITIONS it refuses without: the new set must not exist yet; the build's rompath must exist; the build's
fingerprint must already be registered to THAT set name in tests/expected/registry.tsv (the suite selects the set
by fingerprint, so a wrong row would freeze into the wrong directory).

Usage:
  python3 tools/freeze_expectation_set.py BUILD_DIR:NEW_SET [BUILD_DIR:NEW_SET ...] [--jobs N] [--set-key vsavjw]
      BUILD_DIR under build/ (its rompath/ is fronted before $ROMDIR); ROMDIR must be set. Logs go to
      build/freeze_<UTC>/<set>.{carry,freeze,verify,shape}.log; a summary line per set and exit 0 only when every
      set froze, verified and passed the shape gate.
  python3 tools/freeze_expectation_set.py --selftest
      a synthetic tree with a fake suite: the carry, the MAME_BIN pin handed to the suite, the merged cleanup,
      the three refusals.
"""
import concurrent.futures, os, re, shutil, subprocess, sys, tempfile, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import freeze_set_shape as fss  # noqa: E402

PIN = os.path.expanduser("~/.cache/vampire-saved/mame/cps2")


def predecessor(root, new):
    m = fss.FAM.match(new)
    if not m:
        return None
    best = None
    for d in os.listdir(os.path.join(root, "tests/expected")):
        n = fss.FAM.match(d)
        if n and n.group(1) == m.group(1) and n.group(3) == m.group(3) and int(n.group(2)) < int(m.group(2)):
            if best is None or int(n.group(2)) > best[0]:
                best = (int(n.group(2)), d)
    return best[1] if best else None


def registered_set(root, build, romdir, set_key, fp_cmd=None):
    rp = f"{os.path.join(root, 'build', build, 'rompath')};{romdir}"
    cmd = fp_cmd or [sys.executable, os.path.join(root, "tools/build_fingerprint.py"), rp, "--set", set_key, "--fronted"]
    r = subprocess.run(cmd, cwd=root, capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def carry(root, old, new, build):
    src, dst = (os.path.join(root, "tests/expected", x) for x in (old, new))
    os.makedirs(dst)
    auth = sorted(f for f in os.listdir(src) if f.endswith((".masked", ".skip")) or f == "mask")
    for f in auth:
        shutil.copy2(os.path.join(src, f), os.path.join(dst, f))
    rd = os.path.join(src, "README.md")
    if os.path.exists(rd):
        hdr = (f"# `{new}`\n\n*(CARRIED {time.strftime('%Y-%m-%d', time.gmtime())} from `{old}` by "
               f"tools/freeze_expectation_set.py: the authored `.masked` specs, the `.skip` markers and the mask copied "
               f"verbatim, then frozen and verified on `build/{build}`. The body below is the carried README; the "
               f"fingerprints it names are its history.)*\n\n")
        open(os.path.join(dst, "README.md"), "w").write(hdr + open(rd).read())
    return len(auth)


def one(root, build, new, romdir, set_key, logdir, suite=None):
    L = lambda k: open(os.path.join(logdir, f"{new}.{k}.log"), "w")
    old = predecessor(root, new)
    if os.path.exists(os.path.join(root, "tests/expected", new)):
        return new, f"REFUSED: tests/expected/{new} exists"
    if not os.path.isdir(os.path.join(root, "build", build, "rompath")):
        return new, f"REFUSED: build/{build}/rompath missing"
    got = registered_set(root, build, romdir, set_key, None if suite is None else suite["fp"])
    if got != new:
        return new, f"REFUSED: build/{build}'s fingerprint is registered to {got!r}, not {new!r}"
    if old is None:
        return new, f"REFUSED: {new} has no predecessor to carry from"
    with L("carry") as fh:
        fh.write(f"carry {old} -> {new}: {carry(root, old, new, build)} authored files\n")
    env = dict(os.environ, MAME_BIN=os.environ.get("MAME_BIN") or PIN, ROMDIR=romdir,
               MAME_ROMPATH=f"{os.path.join(root, 'build', build, 'rompath')};{romdir}")
    run = (suite or {}).get("run") or [os.path.join(root, "tests/run_suite.sh")]
    for step, args in (("freeze", ["--freeze", set_key]), ("verify", [set_key])):
        with L(step) as fh:
            rc = subprocess.run(run + args, cwd=root, env=env, stdout=fh, stderr=subprocess.STDOUT).returncode
        if rc != 0:
            return new, f"FAILED at {step} (exit {rc}; {logdir}/{new}.{step}.log)"
    # A MERGED set's self-frozen tenant .sha1 are removed AFTER its verify (#111): verified while they exist, the
    # set is GREEN; once removed, a plain suite run reads 16 NO-EXPECTATION BY DESIGN (docs/project/gotchas.md
    # "THE MERGED EXPECTATION SET MUST HAVE ITS 16 SELF-FROZEN `.sha1` DELETED") — so the verify cannot follow it.
    if new.startswith("merged-m"):
        d = os.path.join(root, "tests/expected", new)
        gone = [f for f in os.listdir(d) if f.endswith(".sha1")]
        for f in gone:
            os.remove(os.path.join(d, f))
        shutil.rmtree(os.path.join(d, "logs"), ignore_errors=True)
        with L("merged_cleanup") as fh:
            fh.write(f"removed {len(gone)} .sha1 and logs/ after the verify (#111)\n")
    with L("shape") as fh:
        rc = subprocess.run([sys.executable, os.path.join(root, "tools/freeze_set_shape.py"), "--set", new, "--root", root],
                            cwd=root, stdout=fh, stderr=subprocess.STDOUT).returncode
    return new, ("OK: carried from " + old + ", frozen, verified, shape clean") if rc == 0 else f"FAILED at the shape gate ({logdir}/{new}.shape.log)"


def drive(root, pairs, jobs, set_key, romdir, suite=None, logdir=None):
    logdir = logdir or os.path.join(root, "build", "freeze_" + time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()))
    os.makedirs(logdir, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as ex:
        res = list(ex.map(lambda p: one(root, p[0], p[1], romdir, set_key, logdir, suite), pairs))
    for new, verdict in res:
        print(f"  {new:22s} {verdict}")
    bad = [r for r in res if not r[1].startswith("OK")]
    print(f"sets {len(res)}  ok {len(res) - len(bad)}  logs {logdir}")
    return 0 if not bad else 1


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as root:
        exp = os.path.join(root, "tests/expected")
        def mk(d, files):
            os.makedirs(os.path.join(exp, d), exist_ok=True)
            for f in files:
                open(os.path.join(exp, d, f), "w").write("mask-bytes" if f == "mask" else "x")
        mk("donovan-m1", ["a.masked", "b.skip", "mask", "t.sha1", "README.md"])
        mk("merged-m1", ["a.masked", "mask"])
        for b in ("don2", "mer2", "wrong"):
            os.makedirs(os.path.join(root, "build", b, "rompath"))
        os.makedirs(os.path.join(root, "tools"))
        shutil.copy2(os.path.join(os.path.dirname(os.path.abspath(__file__)), "freeze_set_shape.py"), os.path.join(root, "tools"))
        # the fake suite: records MAME_BIN, writes a .sha1 per replay on --freeze (as run_suite does), and a logs/ copy
        fake = os.path.join(root, "fake_suite.py")
        open(fake, "w").write(
            "import os, sys\nfreeze = '--freeze' in sys.argv\nrp = os.environ['MAME_ROMPATH'].split(';')[0]\n"
            "s = {'don2': 'donovan-m2', 'mer2': 'merged-m2', 'wrong': 'donovan-m9'}[rp.split('/build/')[1].split('/')[0]]\n"
            "d = os.path.join('tests/expected', s)\nopen(os.path.join(d, '.mame_bin_seen'), 'w').write(os.environ.get('MAME_BIN', ''))\n"
            "if freeze:\n    open(os.path.join(d, 't.sha1'), 'w').write('sha')\n    os.makedirs(os.path.join(d, 'logs'), exist_ok=True)\n"
            "    open(os.path.join(d, 'logs', 't.log'), 'w').write('log')\n"
            "elif not os.path.exists(os.path.join(d, 't.sha1')) and not os.path.exists(os.path.join(d, 't.masked')):\n"
            "    print('t NO-EXPECTATION'); sys.exit(1)\n")
        fp = os.path.join(root, "fake_fp.py")
        open(fp, "w").write("import sys\nrp = sys.argv[1].split(';')[0]\nprint({'don2': 'donovan-m2', 'mer2': 'merged-m2', 'wrong': 'donovan-m9'}[rp.split('/build/')[1].split('/')[0]])\n")
        env_before = os.environ.pop("MAME_BIN", None)
        def run_pairs(pairs):
            out = []
            for b, s in pairs:
                suite = {"run": [sys.executable, fake], "fp": [sys.executable, fp, f"{os.path.join(root, 'build', b, 'rompath')};/roms"]}
                out.append(one(root, b, s, "/roms", "vsavjw", os.path.join(root, "logs"), suite))
            return out
        os.makedirs(os.path.join(root, "logs"))
        (n1, v1), (n2, v2) = run_pairs([("don2", "donovan-m2"), ("mer2", "merged-m2")])
        def say(cond, what):
            nonlocal ok
            print(("  ok: " if cond else "  FAIL: ") + what)
            ok = ok and cond
        d2, m2 = os.path.join(exp, "donovan-m2"), os.path.join(exp, "merged-m2")
        say(v1.startswith("OK") and v2.startswith("OK"), f"both sets freeze, verify and pass the shape gate ({v1[:40]}; {v2[:40]})")
        say(all(os.path.exists(os.path.join(d2, f)) for f in ("a.masked", "b.skip", "mask")) and
            open(os.path.join(d2, "mask")).read() == "mask-bytes", "the authored files are CARRIED verbatim before the freeze")
        say(open(os.path.join(d2, ".mame_bin_seen")).read() == PIN, "the suite ran with MAME_BIN pinned to the tree's pin")
        say(not [f for f in os.listdir(m2) if f.endswith(".sha1")] and not os.path.exists(os.path.join(m2, "logs")),
            "the merged set's .sha1 and logs/ are removed (#111)")
        say(os.path.exists(os.path.join(d2, "t.sha1")), "a solo set keeps its self-frozen .sha1")
        say(open(os.path.join(d2, "README.md")).read().startswith("# `donovan-m2`\n\n*(CARRIED"), "the README is carried under a CARRIED header")
        (_, r1), = run_pairs([("don2", "donovan-m2")])
        say(r1.startswith("REFUSED") and "exists" in r1, "an existing set is refused")
        (_, r2), = run_pairs([("wrong", "donovan-m3")])
        say(r2.startswith("REFUSED") and "registered to" in r2, "a build registered to a different set is refused")
        if env_before is not None:
            os.environ["MAME_BIN"] = env_before
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    pairs = [tuple(x.split(":", 1)) for x in a if ":" in x and not x.startswith("--")]
    if not pairs:
        sys.exit(__doc__)
    romdir = os.environ.get("ROMDIR")
    if not romdir:
        sys.exit("set ROMDIR")
    jobs = int(a[a.index("--jobs") + 1]) if "--jobs" in a else 1
    key = a[a.index("--set-key") + 1] if "--set-key" in a else "vsavjw"
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()
    return drive(root, pairs, jobs, key, os.path.abspath(romdir))


if __name__ == "__main__":
    sys.exit(main())
