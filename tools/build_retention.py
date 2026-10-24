#!/usr/bin/env python3
"""build_retention.py — what under build/ is kept, archived or pruned, and why (#307, 14z-208).

THE RULE (docs/project/build_dir_triage.md, "The retention rule"; maintainer-ruled 2026-10-24: closed work's evidence is
"Archive, then move to files-hades (10.20.0.39)"). Each build/ top-level directory is ONE unit; inside the session-tooling
families the planner also judges sub-units (a snapshot run's listing file, a rule-checker staging folder, a sheet page
folder). A unit is decided by the first rule that holds:

  KEEP     input        tests/expected/build_dirs.tsv classes it `input` (a gate reads it); build dirs follow [VSP-96].
                        FIRST, and never overridden: the emulator run records (`emu_*`) are input, so every one is
                        kept (14z-208: an emulator-record rule placed before it archived 33 and pruned 50 of them, and
                        this gate's real-tree check caught it in the first tier that ran on the real build/)
  KEEP     code         a tracked program under tools/ or tests/, or build/manifest/, names it on a line that is not a
                        comment ([VSP-96]'s first two places; a comment counted as a read keeps everything — 14z-112)
  KEEP     open-ticket  an open or parked ticket's row in docs/project/tickets.tsv, or its GitHub text (--issues DIR)
  KEEP     start-here   docs/NEXT_SESSION.md's START HERE
  KEEP     state        STATE.md (the current session groups, their evidence and the --confirm base)
  KEEP     close        the newest two close run folders (build/agent<N>/close) and the --prev the newest one names
  KEEP     family       a session-tooling family's top folder (rulecheck, static_runs, snapshot_runs, sheets): judged
                        by its sub-units instead
  sub-units of the families:
  PRUNE    listing      a snapshot run's listing.tsv, but the newest NEWEST_LISTINGS (record.txt and runner.log stay)
  KEEP     unrecorded   a rule-checker staging folder whose run has no ledger row yet (record still reads it)
  PRUNE    recorded     a rule-checker staging folder whose run is recorded (the run keeps its packet and sha1s)
  PRUNE    old-sheets   a sheet page folder older than the newest freeze/* tag (proof_sheets.py rebuilds pages)
  the rest:
  ARCHIVE  evidence     everything else: closed work's evidence, cited only by archives, live documents, the
                        rule-checker's records, comments, or nothing. It is tarred (`archive`), the tars are moved to
                        files-hades, and only a unit whose tar the destination's sha256 confirms (`verify`) is deleted.

Usage:
  build_retention.py plan [--root R] [--issues DIR] [--no-sizes] [--out plan.tsv]
  build_retention.py fetch-issues --out DIR [--root R]     open/parked tickets' GitHub text, for --issues
  build_retention.py archive --out DIR [--root R] [--issues DIR]   one tar per ARCHIVE unit + manifest.tsv
  build_retention.py verify --archive DIR --dest-sums FILE   FILE: `shasum -a 256` output taken ON the destination
  build_retention.py apply --archive DIR [--root R] [--issues DIR] [--yes]   delete PRUNE units and VERIFIED archives
  build_retention.py --selftest
Deleting is apply's alone, and only with --yes; without it apply lists what it would delete. [VSP-96]: run
`tests/run_all_static.sh --strict` before committing anything a deletion affected.
"""
import argparse, glob, hashlib, json, os, re, shutil, subprocess, sys, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_dirs as bd  # noqa: E402

B = "build"
FAMILIES = ("rulecheck", "static_runs", "snapshot_runs", "sheets")
NEWEST_LISTINGS = 3
NAMED = re.compile(r"(?<![\w.-])build/([A-Za-z0-9_.][\w.-]*)")
CODE_EXT = (".sh", ".py", ".lua", ".js", ".mjs", ".bat", ".command", ".html")


def git(root, *a):
    return subprocess.run(["git", "-C", root, *a], capture_output=True, text=True).stdout


def carrier(path):
    b = os.path.basename(path)
    if re.search(r"_(?:HISTORY|history)\.md$", b) or path.startswith("docs/project/findings/"):
        return "archive"
    if path.startswith("tests/rulecheck/"):
        return "rulecheck"
    if path == "docs/project/tickets.tsv":
        return "tickets_tsv"
    if path == "STATE.md":
        return "state"
    if path == "docs/NEXT_SESSION.md":
        return "next_session"
    if path.startswith(B + "/manifest/"):
        return "manifest"
    if path.startswith(("tools/", "tests/")):
        return "code" if (path.endswith(CODE_EXT) or "." not in b) else "data"
    return "livedoc"


def is_comment(text, path):
    t = text.lstrip()
    if path.endswith(".lua"):
        return t.startswith("--")
    if path.endswith((".js", ".mjs")):
        return t.startswith(("//", "*", "/*"))
    if path.endswith(".bat"):
        return t.upper().startswith("REM") or t.startswith("::")
    return t.startswith("#")


def references(root):
    """-> {top: {carrier: count}} from every tracked text line naming build/<top>."""
    refs = {}
    for line in git(root, "grep", "-n", "-I", "-F", B + "/").splitlines():
        try:
            path, _, text = line.split(":", 2)
        except ValueError:
            continue
        car = carrier(path)
        if car in ("code", "data") and is_comment(text, path):
            car = "comment"
        for m in NAMED.finditer(text):
            top = m.group(1).rstrip(".")
            refs.setdefault(top, {}).setdefault(car, 0)
            refs[top][car] += 1
    return refs


def ticket_rows(root):
    """-> ({top named by an open/parked row}, [open/parked issue numbers])"""
    named, nums = set(), []
    p = os.path.join(root, "docs", "project", "tickets.tsv")
    if not os.path.exists(p):
        return named, nums
    for l in open(p, encoding="utf-8"):
        if l.startswith("#"):
            continue
        f = l.rstrip("\n").split("\t")
        if len(f) > 2 and f[2] in ("open", "parked"):
            nums.append(f[0])
            named |= {m.group(1).rstrip(".") for m in NAMED.finditer(l)}
    return named, nums


def issue_names(issues, nums):
    named = set()
    if not issues:
        return named
    for n in nums:
        p = os.path.join(issues, n + ".md")
        if os.path.exists(p):
            named |= {m.group(1).rstrip(".") for m in NAMED.finditer(open(p, encoding="utf-8", errors="replace").read())}
    return named


def start_here(root):
    p = os.path.join(root, "docs", "NEXT_SESSION.md")
    if not os.path.exists(p):
        return set()
    sh = open(p, encoding="utf-8").read().split("## START HERE", 1)[-1].split("\n## ", 1)[0]
    return {m.group(1).rstrip(".") for m in NAMED.finditer(sh)}


def close_tops(root):
    """the newest two close folders' tops, and the top of the --prev the newest one names"""
    params = sorted(glob.glob(os.path.join(root, B, "agent*", "close", "close_params.tsv")), key=os.path.getmtime)
    keep = {os.path.basename(os.path.dirname(os.path.dirname(p))) for p in params[-2:]}
    if params:
        for l in open(params[-1], encoding="utf-8"):
            if l.startswith("PREV\t"):
                rel = os.path.relpath(l.split("\t", 1)[1].strip(), os.path.join(root, B))
                if not rel.startswith(".."):
                    keep.add(rel.split(os.sep)[0])
    return keep


def recorded_runs(root):
    p = os.path.join(root, "tests", "rulecheck", "ledger.tsv")
    if not os.path.exists(p):
        return set()
    return {l.split("\t", 1)[0] for l in open(p, encoding="utf-8") if l.strip() and not l.startswith("#")}


def last_freeze_time(root):
    out = git(root, "for-each-ref", "--sort=-creatordate", "--format=%(creatordate:unix)", "refs/tags/freeze/").split()
    return int(out[0]) if out else None


def unit_time(root, name, path):
    """a sheet folder named by a commit: that commit's time; otherwise the folder's mtime"""
    t = git(root, "log", "-1", "--format=%ct", name + "^{commit}", "--").strip() if re.fullmatch(r"[0-9a-f]{7,40}", name) else ""
    return int(t) if t.isdigit() else int(os.path.getmtime(path))


def size(path):
    kb = n = 0
    stack = [path]
    while stack:
        p = stack.pop()
        try:
            st = os.lstat(p)
        except OSError:
            continue
        n += 1
        kb += st.st_blocks // 2
        if os.path.isdir(p) and not os.path.islink(p):
            try:
                stack.extend(os.path.join(p, e) for e in os.listdir(p))
            except OSError:
                pass
    return kb, n


def plan(root, issues=None, sizes=True):
    """-> [(unit, kind, build_class, decision, rule, why, kb, files)]"""
    rows = bd.load()
    refs = references(root)
    trow, nums = ticket_rows(root)
    tgh = issue_names(issues, nums)
    sh, cl, recorded = start_here(root), close_tops(root), recorded_runs(root)
    freeze = last_freeze_time(root)
    out = []

    def add(unit, kind, cls, dec, rule, why):
        kb, n = size(os.path.join(root, B, unit)) if sizes else (0, 0)
        out.append((unit, kind, cls or "-", dec, rule, why, kb, n))

    for top in bd.live_dirs(root):
        cls = bd.classify(rows, top)
        r = refs.get(top, {})
        cited = ",".join(f"{k}:{v}" for k, v in sorted(r.items())) or "none"
        if cls == "input":
            add(top, "top", cls, "KEEP", "input", "build_dirs.tsv classes it input; build dirs follow [VSP-96]")
        elif r.get("code") or r.get("manifest") or r.get("data"):
            add(top, "top", cls, "KEEP", "code", "named by a tracked program or data line (" + cited + ")")
        elif top in trow or top in tgh:
            add(top, "top", cls, "KEEP", "open-ticket", "named by an open/parked ticket")
        elif top in sh:
            add(top, "top", cls, "KEEP", "start-here", "named in START HERE")
        elif r.get("state"):
            add(top, "top", cls, "KEEP", "state", "named in STATE.md")
        elif top in cl:
            add(top, "top", cls, "KEEP", "close", "a current or previous close folder")
        elif top in FAMILIES:
            add(top, "top", cls, "KEEP", "family", "a session-tooling family, judged by its sub-units")
        else:
            add(top, "top", cls, "ARCHIVE", "evidence", "closed work's evidence; cited " + cited)
    snap = os.path.join(root, B, "snapshot_runs")
    if os.path.isdir(snap):
        runs = sorted(d for d in os.listdir(snap) if os.path.isfile(os.path.join(snap, d, "listing.tsv")))
        for d in runs[:-NEWEST_LISTINGS] if len(runs) > NEWEST_LISTINGS else []:
            add(os.path.join("snapshot_runs", d, "listing.tsv"), "file", "scratch", "PRUNE", "listing",
                f"an old snapshot listing (the newest {NEWEST_LISTINGS} are kept)")
    rc = os.path.join(root, B, "rulecheck")
    if os.path.isdir(rc):
        for d in sorted(os.listdir(rc)):
            if os.path.isdir(os.path.join(rc, d)):
                if d in recorded:
                    add(os.path.join("rulecheck", d), "sub", "scratch", "PRUNE", "recorded", "the run is recorded in the ledger")
                else:
                    add(os.path.join("rulecheck", d), "sub", "scratch", "KEEP", "unrecorded", "the run has no ledger row yet")
    sh_dir = os.path.join(root, B, "sheets")
    if os.path.isdir(sh_dir) and freeze:
        for d in sorted(os.listdir(sh_dir)):
            p = os.path.join(sh_dir, d)
            if os.path.isdir(p) and unit_time(root, d, p) < freeze:
                add(os.path.join("sheets", d), "sub", "scratch", "PRUNE", "old-sheets", "older than the newest freeze/* tag")
    return out


HEAD = "unit\tkind\tbuild_class\tdecision\trule\twhy\tkb\tfiles"


def write_plan(rows, out):
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(HEAD + "\n")
        for r in rows:
            f.write("\t".join(str(x) for x in r) + "\n")


def summary(rows):
    tot = {}
    for r in rows:
        t = tot.setdefault((r[3], r[4]), [0, 0, 0])
        t[0] += 1; t[1] += r[6]; t[2] += r[7]
    for (dec, rule), (n, kb, files) in sorted(tot.items()):
        print(f"  {dec:8s} {rule:12s} {n:5d} unit(s) {kb / 1048576:8.2f} GB {files:9d} entries")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


MANIFEST = "manifest.tsv"
VERIFIED = "verified.tsv"


def manifest_rows(arch):
    p = os.path.join(arch, MANIFEST)
    if not os.path.exists(p):
        return {}
    out = {}
    for l in open(p, encoding="utf-8"):
        f = l.rstrip("\n").split("\t")
        if f[0] != "unit" and len(f) >= 7:
            out[f[0]] = {"tar": f[3], "sha256": f[5]}
    return out


def verified_rows(arch):
    p = os.path.join(arch, VERIFIED)
    if not os.path.exists(p):
        return {}
    return {f[0]: f[1] for f in (l.rstrip("\n").split("\t") for l in open(p, encoding="utf-8")) if len(f) >= 2}


def archive(root, arch, issues=None):
    os.makedirs(arch, exist_ok=True)
    have = manifest_rows(arch)
    mp = os.path.join(arch, MANIFEST)
    if not os.path.exists(mp):
        open(mp, "w", encoding="utf-8", newline="\n").write("unit\tkb\tfiles\ttar\ttar_bytes\tsha256\tmembers_tar\tmembers_find\n")
    bad = 0
    for r in plan(root, issues, sizes=True):
        if r[3] != "ARCHIVE" or r[0] in have:
            continue
        tar = r[0] + ".tar"
        tp = os.path.join(arch, tar)
        subprocess.run(["tar", "-cf", tp, "-C", os.path.join(root, B), r[0]], check=True)
        listed = sum(1 for _ in subprocess.run(["tar", "-tf", tp], capture_output=True, text=True, check=True).stdout.splitlines())
        found = 1                                    # the unit's own folder
        for _, ds, fs in os.walk(os.path.join(root, B, r[0])):
            found += len(ds) + len(fs)
        sha = sha256(tp)
        with open(mp, "a", encoding="utf-8", newline="\n") as f:
            f.write(f"{r[0]}\t{r[6]}\t{r[7]}\t{tar}\t{os.path.getsize(tp)}\t{sha}\t{listed}\t{found}\n")
        ok = listed == found
        bad += not ok
        print(f"  {'ok ' if ok else 'BAD'} {tar} {os.path.getsize(tp)} bytes sha256 {sha} members tar {listed} find {found}")
    return bad


def verify(arch, dest_sums):
    """record as verified each tar whose sha256, computed ON the destination, equals the manifest's"""
    dest = {}
    for l in open(dest_sums, encoding="utf-8"):
        m = re.match(r"^([0-9a-f]{64})\s+\*?(.+)$", l.strip())
        if m:
            dest[os.path.basename(m.group(2))] = m.group(1)
    man, done = manifest_rows(arch), verified_rows(arch)
    n = 0
    with open(os.path.join(arch, VERIFIED), "a", encoding="utf-8", newline="\n") as f:
        for unit, m in sorted(man.items()):
            if unit in done:
                continue
            if dest.get(m["tar"]) == m["sha256"]:
                f.write(f"{unit}\t{m['sha256']}\t{os.path.basename(dest_sums)}\t{time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n")
                n += 1
            else:
                print(f"  not verified: {m['tar']} (destination {dest.get(m['tar'], 'absent')})")
    print(f"verified {n} tar(s)")


def apply(root, arch, issues=None, yes=False):
    man, ver = manifest_rows(arch), verified_rows(arch)
    refused, todo = [], []
    for r in plan(root, issues, sizes=False):
        if r[3] == "PRUNE":
            todo.append(r[0])
        elif r[3] == "ARCHIVE":
            m = man.get(r[0])
            if m and ver.get(r[0]) == m["sha256"]:
                todo.append(r[0])
            else:
                refused.append(r[0])
    for u in todo:
        p = os.path.join(root, B, u)
        print(("delete " if yes else "would delete ") + u)
        if yes:
            shutil.rmtree(p) if os.path.isdir(p) and not os.path.islink(p) else os.remove(p)
    for u in refused:
        print(f"REFUSED {u}: an ARCHIVE unit with no tar verified on the destination")
    return 1 if refused else 0


def fetch_issues(root, out):
    os.makedirs(out, exist_ok=True)
    _, nums = ticket_rows(root)
    for n in nums:
        r = subprocess.run(["gh", "issue", "view", n, "--json", "body,comments"], cwd=root, capture_output=True, text=True)
        if r.returncode == 0:
            d = json.loads(r.stdout)
            open(os.path.join(out, n + ".md"), "w", encoding="utf-8", newline="\n").write(
                d.get("body", "") + "\n" + "\n".join(c.get("body", "") for c in d.get("comments", [])))
    print(f"fetched {len(nums)} open/parked ticket(s) into {out}")


# ---- the selftest: a synthetic tree where every rule must decide one planted unit --------------------------------
def selftest():
    fails = []
    with tempfile.TemporaryDirectory() as td:
        root = os.path.join(td, "r")
        os.makedirs(root)
        def w(rel, text, mtime=None):
            p = os.path.join(root, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w", encoding="utf-8").write(text)
            if mtime:
                os.utime(p, (mtime, mtime))
        bdir = B + "/"
        w("tools/reader.sh", "cat " + bdir + "rd_code/x.txt\n")
        w("tools/notes.sh", "# measured once in " + bdir + "rd_comment\n")
        w("docs/project/tickets.tsv", "# header\n901\tbug\topen\tt\t" + bdir + "rd_ticket\tnone\tnone\tnone\t-\n"
                                      "902\tbug\tdone\tt\t" + bdir + "rd_closed\tnone\tnone\tnone\t-\n")
        w("docs/x_HISTORY.md", "evidence in " + bdir + "rd_archive (local)\n")
        w("docs/NEXT_SESSION.md", "# n\n## START HERE\n1. see " + bdir + "rd_start\n## OTHER\n")
        w("STATE.md", "# s\n(" + bdir + "rd_state, local)\n")
        w("tests/rulecheck/ledger.tsv", "# ledger\n2026-01-01-1\tx\n")
        for d in ("rd_code", "rd_comment", "rd_ticket", "rd_closed", "rd_archive", "rd_start", "rd_state", "rd_none",
                  "rulecheck/2026-01-01-1", "rulecheck/2026-01-01-2", "agent9001/close"):
            w(os.path.join(B, d, "f.txt"), "x\n")
        w(os.path.join(B, "agent9001", "close", "close_params.tsv"), "KEY\t14z-9001\n")
        t0 = time.time() - 3600
        w(os.path.join(B, "emu_old", "commit.txt"), "aaaaaaa\n")
        w(os.path.join(B, "emu_old", "results.tsv"), "gate\tlane\tscope\tverdict\tseconds\ng1\tmame\trelease\tPASS\t1\n", t0)
        w(os.path.join(B, "emu_new", "commit.txt"), "bbbbbbb\n")
        w(os.path.join(B, "emu_new", "results.tsv"), "gate\tlane\tscope\tverdict\tseconds\ng2\tmame\trelease\tPASS\t1\n", t0 + 60)
        w(os.path.join(B, "emu_void", "commit.txt"), "ccccccc\n")
        w(os.path.join(B, "emu_void", "results.tsv"), "gate\tlane\tscope\tverdict\tseconds\n", t0 - 60)
        w("docs/project/tickets.tsv", open(os.path.join(root, "docs/project/tickets.tsv")).read()
          + "903\tbug\tparked\tt\tnone\tnone\tnone\tnone\t-\n")
        issues = os.path.join(td, "issues")
        os.makedirs(issues)
        open(os.path.join(issues, "903.md"), "w").write("the GitHub text names " + bdir + "rd_gh\n")
        open(os.path.join(issues, "902.md"), "w").write("a CLOSED ticket's text names " + bdir + "rd_gh_closed\n")
        for d in ("rd_gh", "rd_gh_closed"):
            w(os.path.join(B, d, "f.txt"), "x\n")
        for i in range(NEWEST_LISTINGS + 1):
            w(os.path.join(B, "snapshot_runs", f"2026010{i}T000000-aaaa", "listing.tsv"), "x\n")
        w(os.path.join(B, "sheets", "oldpage", "index.html"), "x\n", t0 - 7200)
        os.utime(os.path.join(root, B, "sheets", "oldpage"), (t0 - 7200, t0 - 7200))
        subprocess.run(["git", "init", "-q", root], check=True)
        subprocess.run(["git", "-C", root, "add", "tools", "docs", "STATE.md", "tests"], check=True)
        subprocess.run(["git", "-C", root, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "t"], check=True)
        subprocess.run(["git", "-C", root, "-c", "user.email=t@t", "-c", "user.name=t", "tag", "-a", "-m", "f",
                        "freeze/x"], check=True)
        got = {r[0]: (r[3], r[4]) for r in plan(root, issues, sizes=False)}
        want = {
            "rd_code": ("KEEP", "code"), "rd_comment": ("ARCHIVE", "evidence"), "rd_ticket": ("KEEP", "open-ticket"),
            "rd_closed": ("ARCHIVE", "evidence"), "rd_archive": ("ARCHIVE", "evidence"), "rd_start": ("KEEP", "start-here"),
            "rd_state": ("KEEP", "state"), "rd_none": ("ARCHIVE", "evidence"), "agent9001": ("KEEP", "close"),
            "emu_old": ("KEEP", "input"), "emu_new": ("KEEP", "input"), "emu_void": ("KEEP", "input"),
            "rulecheck/2026-01-01-1": ("PRUNE", "recorded"), "rulecheck/2026-01-01-2": ("KEEP", "unrecorded"),
            "rd_gh": ("KEEP", "open-ticket"), "rd_gh_closed": ("ARCHIVE", "evidence"),
            os.path.join("snapshot_runs", "20260100T000000-aaaa", "listing.tsv"): ("PRUNE", "listing"),
            os.path.join("snapshot_runs", f"2026010{NEWEST_LISTINGS}T000000-aaaa", "listing.tsv"): None,
            os.path.join("sheets", "oldpage"): ("PRUNE", "old-sheets"),
            "snapshot_runs": ("KEEP", "family"), "sheets": ("KEEP", "family"),
        }
        for u, exp in sorted(want.items()):
            if got.get(u) != exp:
                fails.append(f"{u}: planned {got.get(u)}, expected {exp}")
            print(f"  {'ok  ' if got.get(u) == exp else 'FAIL'} {u:24s} {got.get(u)}")
        # apply: a verified archive is deleted, an unverified one is refused and stays
        arch = os.path.join(td, "arch")
        os.makedirs(arch)
        sha = "0" * 64
        open(os.path.join(arch, MANIFEST), "w").write("unit\tkb\tfiles\ttar\ttar_bytes\tsha256\tmembers_tar\tmembers_find\n"
                                                      f"rd_none\t0\t0\trd_none.tar\t0\t{sha}\t0\t0\n"
                                                      f"rd_archive\t0\t0\trd_archive.tar\t0\t{sha}\t0\t0\n")
        open(os.path.join(arch, VERIFIED), "w").write(f"rd_none\t{sha}\tsums\tnow\n")
        with open(os.devnull, "w") as dn:
            old, sys.stdout = sys.stdout, dn
            try:
                rc = apply(root, arch, issues, yes=True)
            finally:
                sys.stdout = old
        gone = lambda u: not os.path.exists(os.path.join(root, B, u))
        checks = [("a verified archive is deleted", gone("rd_none")),
                  ("an unverified archive is refused and stays", not gone("rd_archive") and rc == 1),
                  ("an unarchived evidence unit stays", not gone("rd_comment")),
                  ("a PRUNE unit is deleted", gone("rulecheck/2026-01-01-1")),
                  ("an input-classed unit nothing names stays", not gone("emu_void")),
                  ("every KEEP unit stays", not any(gone(u) for u, e in want.items() if e and e[0] == "KEEP"))]
        for what, ok in checks:
            print(f"  {'ok  ' if ok else 'FAIL'} apply: {what}")
            if not ok:
                fails.append("apply: " + what)
    print("SELFTEST " + ("PASS" if not fails else "FAIL"))
    for f in fails:
        print("  " + f)
    return 0 if not fails else 1


def main():
    if sys.argv[1:] == ["--selftest"]:
        return selftest()
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for c in ("plan", "archive", "apply", "fetch-issues", "verify"):
        s = sub.add_parser(c)
        s.add_argument("--root", default=os.path.join(HERE, ".."))
        s.add_argument("--issues")
        if c == "plan":
            s.add_argument("--no-sizes", action="store_true")
            s.add_argument("--out")
        if c in ("archive", "fetch-issues"):
            s.add_argument("--out", required=True)
        if c in ("apply", "verify"):
            s.add_argument("--archive", required=True)
        if c == "verify":
            s.add_argument("--dest-sums", required=True)
        if c == "apply":
            s.add_argument("--yes", action="store_true")
    a = ap.parse_args()
    root = os.path.abspath(a.root)
    if a.cmd == "plan":
        rows = plan(root, a.issues, sizes=not a.no_sizes)
        if a.out:
            write_plan(rows, a.out)
        summary(rows)
        if not a.issues:
            print("NOTE: no --issues DIR: open tickets' GitHub text was not read (fetch-issues writes it)")
        return 0
    if a.cmd == "fetch-issues":
        fetch_issues(root, a.out); return 0
    if a.cmd == "archive":
        return 1 if archive(root, os.path.abspath(a.out), a.issues) else 0
    if a.cmd == "verify":
        verify(a.archive, a.dest_sums); return 0
    return apply(root, a.archive, a.issues, a.yes)


if __name__ == "__main__":
    sys.exit(main())
