#!/usr/bin/env python3
"""reuse_identity.py — MAY A RELEASE REUSE THE FREEZE'S TIER RESULTS? (#316, 14z-208, the maintainer: "yes, let's
file this and do it before we freeze".)

  python3 tools/reuse_identity.py emit [--root DIR] [--tree HASH]    # this checkout's identity, one `key value` line each
                                                                     # (--tree: the caller's own `git stash create` tree)
  python3 tools/reuse_identity.py compare FREEZE NOW                 # the two identities, key by key; exit 0 only if equal
  python3 tools/reuse_identity.py plan --root DIR --results FREEZE   # which freeze rows a release may reuse (static tier)
  python3 tools/reuse_identity.py --selftest

WHY. A freeze runs the freeze-cadence static tier with every control and the emulator battery; a release then ran its
own full tier on the same commit, repeating verdicts the same tree had just earned (about 5 h each, recorded). The
ruling that a freeze and a release ALWAYS run their full tier on the commit they build from is kept: every test still
runs on that commit, once. A release reuses a freeze's row only when NOTHING the row could depend on has moved:

THE IDENTITY, every key compared, any difference refuses the whole reuse (the release then runs everything, as before):
  tree        the tracked content: `git stash create` (HEAD plus every tracked change) as a tree hash, else HEAD's tree
  untracked   a sha256 over every untracked, unignored file outside build/ (path and content; OS metadata dropped),
              with the count: a gate that globs a directory reads an untracked file the tree hash cannot see
  subfp       one line per initialised submodule, tools/static_confirm.py's fingerprint (HEAD, diff, untracked)
  romdir      a sha256 over every regular file of $ROMDIR (name and content; OS metadata dropped), with the count;
              `none` when ROMDIR is unset
  instrument  the sha256 of each instrument's file: mame-wide and mame-ref (the paths tests/run_all_emulator.sh
              resolves, MAME_WIDE_BIN / MAME_REF_BIN overriding), fbneo (emu/fbneo/fbneo), MAME_BIN when the caller set
              it, and python3 (the interpreter running this tool, by its real path, with its version); `missing`
              when absent — so an instrument that appears or vanishes is a difference too
  build       per build placeholder of tests/run_all_emulator.sh (MERGED, DON, HUI, PYR, STOCK: its defaults, the
              environment overriding, as the runner resolves them), a sha256 over its rompath's files; `absent`

Content, never paths: a run on a snapshot (tests/run_on_snapshot.sh, a private HOME, a copied instrument cache) has
the same identity as a run in the working tree when every byte is the same.

THE PLAN (static tier). A freeze results.tsv is reusable only when it is the freeze's run of record: its trailer says
`# cadence freeze`, `# strict 1`, `# tier all`, `# romdir set`, `# exec_controls all` and `# verdict GREEN`, its
`# args` carry no --confirm and no --reuse, and its tree did not move during the run (`# tree` = `# tree_end`) nor its
identity (`# id` = `# id_end`). Then, per registered gate:
  REUSE  a PASS row whose every declared control was executed and honoured in the freeze run
  RUN    anything else, with the reason: absent from the freeze run, not PASS there, a control not executed, a gate
         of `release` cadence (tests/ci_cadence.tsv — a release-cadence row is NEVER reused: the release is its
         cadence), or a gate whose script reads VS_CADENCE (its verdict depends on the cadence it runs at)
A refused file prints `plan: REFUSED — <reason>` and exits 3: the runner then runs everything.
"""
import hashlib
import os
import re
import subprocess
import sys

OS_METADATA = re.compile(r'(^|/)\.DS_Store$')   # tests/lib/os_metadata.sh's one definition
BUILDS = ("MERGED", "DON", "HUI", "PYR", "STOCK")


def git(root, *args):
    r = subprocess.run(["git", "-C", root] + list(args), capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def sha_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def sha_files(base, names):
    """a sha256 over `name NUL content-sha NUL` of each file, sorted by name"""
    h = hashlib.sha256()
    for n in sorted(names):
        h.update(n.encode("utf-8", "surrogateescape") + b"\0" + sha_file(os.path.join(base, n)).encode() + b"\0")
    return h.hexdigest()


def tree_id(root):
    sc = git(root, "stash", "create")
    t = git(root, "rev-parse", (sc or "HEAD") + "^{tree}")
    return t or "none"


def untracked_id(root):
    # the top-level entries but build/ as pathspecs, so git never walks build/ (26 s on the working tree, 2026-10-24)
    tops = sorted(e for e in os.listdir(root) if e not in ("build", ".git"))
    out = git(root, "ls-files", "-z", "--others", "--exclude-standard", "--", *tops) if tops else ""
    if out is None:
        return "none"
    names = [n for n in out.split("\0") if n and not n.startswith("build/") and not OS_METADATA.search(n)
             and os.path.isfile(os.path.join(root, n))]
    return f"{sha_files(root, names)} {len(names)}"


def romdir_id(romdir):
    if not romdir:
        return "none"
    if not os.path.isdir(romdir):
        return "missing"
    names = []
    for dp, _dn, fn in os.walk(romdir):
        for f in fn:
            rel = os.path.relpath(os.path.join(dp, f), romdir)
            if not OS_METADATA.search(rel) and os.path.isfile(os.path.join(romdir, rel)):
                names.append(rel)
    return f"{sha_files(romdir, names)} {len(names)}"


def file_id(path):
    return sha_file(path) if path and os.path.isfile(path) else "missing"


def runner_defaults(root):
    """the build placeholders' defaults as tests/run_all_emulator.sh assigns them: NAME="${NAME:-default}" """
    out = {}
    try:
        text = open(os.path.join(root, "tests/run_all_emulator.sh"), errors="replace").read()
    except OSError:
        return out
    for n in BUILDS:
        m = re.search(r'^%s="\$\{%s:-([^}]*)\}"' % (n, n), text, re.M)
        if m:
            out[n] = m.group(1)
    return out


def build_id(root, d):
    rp = os.path.join(root, d, "rompath") if not os.path.isabs(d) else os.path.join(d, "rompath")
    if not os.path.isdir(rp):
        return "absent"
    names = []
    for dp, _dn, fn in os.walk(rp):
        for f in fn:
            rel = os.path.relpath(os.path.join(dp, f), rp)
            if not OS_METADATA.search(rel) and os.path.isfile(os.path.join(rp, rel)):
                names.append(rel)
    return sha_files(rp, names)


def emit(root, tree=None):
    home = os.path.expanduser("~")
    lines = []
    lines.append(f"tree {tree or tree_id(root)}")   # ID-TREE
    lines.append(f"untracked {untracked_id(root)}")   # ID-UNTRACKED
    sys.path.insert(0, os.path.join(root, "tools"))
    try:
        import static_confirm as sc   # the ONE submodule fingerprint (#286 (b))
        for p in sc.submodules(root):
            lines.append(f"subfp {p} {sc.subfp(root, p) or 'none'}")
    except Exception as e:   # a root without the tool: say so, never pass silently
        lines.append(f"subfp unreadable {type(e).__name__}")
    lines.append(f"romdir {romdir_id(os.environ.get('ROMDIR', ''))}")   # ID-ROMDIR
    inst = [("mame-wide", os.environ.get("MAME_WIDE_BIN") or f"{home}/.cache/vampire-saved/mame/cps2"),
            ("mame-ref", os.environ.get("MAME_REF_BIN") or f"{home}/.cache/vampire-saved/mame-ref/cps2"),
            ("fbneo", os.path.join(root, "emu/fbneo/fbneo")),
            ("MAME_BIN", os.environ.get("MAME_BIN") or "")]
    for n, p in inst:
        lines.append(f"instrument {n} {file_id(p) if p else 'unset'}")   # ID-INSTRUMENT
    py = os.path.realpath(sys.executable)
    lines.append(f"instrument python3 {file_id(py)} {sys.version.split()[0]}")
    dflt = runner_defaults(root)
    for n in BUILDS:
        d = os.environ.get(n) or dflt.get(n)
        lines.append(f"build {n} {build_id(root, d) if d else 'unset'}")
    return lines


def read_id(path, prefix):
    """identity lines of a file: lines starting with `prefix` (`# id ` in a results.tsv), or every line of a bare
    identity file (prefix "")"""
    out = []
    for line in open(path, errors="replace"):
        line = line.rstrip("\n")
        if prefix and not line.startswith(prefix):
            continue
        line = line[len(prefix):]
        if line and not line.startswith("#"):
            out.append(line)
    return out


def keyed(lines):
    d = {}
    for line in lines:
        f = line.split(" ")
        k = " ".join(f[:2]) if f[0] in ("subfp", "instrument", "build") else f[0]
        d[k] = line[len(k):].strip()
    return d


def compare(a, b, la="freeze", lb="now"):
    """print each key, same or DIFFERS; True when equal and the key sets match"""
    ka, kb = keyed(a), keyed(b)
    ok = bool(ka)
    if not ka:
        print(f"  DIFFERS  ({la} carries no identity)")
    for k in sorted(set(ka) | set(kb)):
        va, vb = ka.get(k, "(absent)"), kb.get(k, "(absent)")
        if va == vb:
            print(f"  same     {k} {va[:16]}")
        else:
            print(f"  DIFFERS  {k}: {la} {va[:24]} now {vb[:24]}")   # REUSE-DIFFERS
            ok = False
    return ok


class Refused(Exception):
    pass


def header(path):
    h = {}
    for line in open(path, errors="replace"):
        if line.startswith("# ") and not line.startswith("# id ") and not line.startswith("# id_end "):
            f = line[2:].rstrip("\n").split(" ", 1)
            h.setdefault(f[0], f[1] if len(f) > 1 else "")
    return h


def cadence_of(root):
    cad = {}
    p = os.path.join(root, "tests/ci_cadence.tsv")
    if os.path.isfile(p):
        for line in open(p, errors="replace"):
            if line.startswith("#") or not line.strip():
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) > 1:
                cad[f[0]] = f[1]
    return cad


def plan(root, results):
    h = header(results)
    want = {"cadence": "freeze", "strict": "1", "tier": "all", "romdir": "set", "exec_controls": "all",
            "verdict": "GREEN"}
    for k, v in want.items():   # REUSE-FREEZE-OF-RECORD
        if h.get(k) != v:
            raise Refused(f"not a freeze's run of record: `# {k}` is {h.get(k, '(absent)')!r}, a reusable run has {v!r}")
    args = " " + h.get("args", "") + " "
    for flag in ("--confirm", "--reuse"):
        if f" {flag} " in args or f" {flag}=" in args:
            raise Refused(f"the freeze run carried {flag}: it did not run every gate itself")
    if not h.get("tree") or h.get("tree") != h.get("tree_end"):
        raise Refused(f"the freeze run's tree moved during it ({h.get('tree')} -> {h.get('tree_end')})")
    if read_id(results, "# id ") != read_id(results, "# id_end "):
        raise Refused("the freeze run's identity moved during it (`# id` differs from `# id_end`)")
    cad = cadence_of(root)
    rows = {}
    for line in open(results, errors="replace"):
        if line.startswith("#") or not line.strip():
            continue
        f = line.rstrip("\n").split("\t")
        rows[f[0]] = f
    out = []
    for g, r in rows.items():
        c = cad.get(g, "session")
        try:
            reads_cadence = "VS_CADENCE" in open(os.path.join(root, "tests", g + ".sh"), errors="replace").read()
        except OSError:
            reads_cadence = False
        if c == "release":   # REUSE-NOT-RELEASE
            out.append(("RUN", g, "release cadence: a release-cadence row is never reused"))
        elif reads_cadence:   # REUSE-NOT-CADENCE-READER
            out.append(("RUN", g, "its script reads VS_CADENCE: its verdict depends on the cadence it runs at"))
        elif len(r) < 6 or r[1] != "PASS":
            out.append(("RUN", g, f"{r[1] if len(r) > 1 else '?'} in the freeze run"))
        elif not (r[3].isdigit() and r[5].isdigit()) or int(r[5]) != int(r[3]):   # REUSE-CONTROLS-ALL
            out.append(("RUN", g, f"{r[5]} of its {r[3]} declared controls executed and honoured in the freeze run"))
        else:
            out.append(("REUSE", g, r[3], r[4], r[5]))
    return out


def selftest():
    import tempfile
    fails = []
    def check(name, cond):
        print(("  ok: " if cond else "  FAIL: ") + name)
        if not cond:
            fails.append(name)
    a = ["tree t1", "untracked u 0", "romdir r 5", "instrument mame-wide m1", "build MERGED b1"]
    check("equal identities compare equal", compare(a, list(a)))
    for i, k in enumerate(a):
        b = list(a); b[i] = k + "x"
        check(f"a changed `{k.split()[0]}` differs", not compare(a, b))
    check("an added key differs", not compare(a, a + ["instrument fbneo f"]))
    check("an empty freeze identity differs", not compare([], []))
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, "tests"))
        open(os.path.join(d, "tests/ci_cadence.tsv"), "w").write("g_rel\trelease\t-\n")
        open(os.path.join(d, "tests/g_cad.sh"), "w").write('echo "${VS_CADENCE:-}"\n')
        good = ["# args --strict --cadence freeze", "# tree T", "# id tree T", "# gate\tverdict\tseconds\tdeclared\tfired\thonoured",
                "g_ok\tPASS\t1\t2\t2\t2", "g_rel\tPASS\t1\t0\t0\t0", "g_cad\tPASS\t1\t0\t0\t0",
                "g_fail\tFAIL\t1\t0\t0\t0", "g_ctl\tPASS\t1\t2\t2\t1",
                "# tree_end T", "# id_end tree T", "# verdict GREEN", "# strict 1", "# tier all", "# romdir set",
                "# cadence freeze", "# exec_controls all"]
        p = os.path.join(d, "r.tsv")
        def write(lines):
            open(p, "w").write("\n".join(lines) + "\n")
        write(good)
        got = {r[1]: r[0] for r in plan(d, p)}
        check("a PASS row with every control honoured is reused", got.get("g_ok") == "REUSE")
        check("a release-cadence row is never reused", got.get("g_rel") == "RUN")
        check("a VS_CADENCE reader is never reused", got.get("g_cad") == "RUN")
        check("a FAIL row is run", got.get("g_fail") == "RUN")
        check("a row with a control not honoured is run", got.get("g_ctl") == "RUN")
        for old, new, what in (("# cadence freeze", "# cadence session", "a session run"),
                               ("# verdict GREEN", "# verdict NOT GREEN", "a red freeze run"),
                               ("# exec_controls all", "# exec_controls none", "a run without its controls"),
                               ("# tree_end T", "# tree_end U", "a run whose tree moved"),
                               ("# id_end tree T", "# id_end tree U", "a run whose identity moved"),
                               ("# args --strict --cadence freeze", "# args --strict --cadence freeze --confirm x", "a confirm run")):
            write([new if x == old else x for x in good])
            try:
                plan(d, p); check(f"{what} is refused", False)
            except Refused:
                check(f"{what} is refused", True)
    print("selftest: " + ("PASS" if not fails else f"FAIL ({len(fails)})"))
    return 1 if fails else 0


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    def opt(k):
        return a[a.index(k) + 1] if k in a and a.index(k) + 1 < len(a) else None
    if a[:1] == ["emit"]:
        for line in emit(os.path.abspath(opt("--root") or "."), opt("--tree")):
            print(line)
        return 0
    if a[:1] == ["compare"] and len(a) == 3:
        def load(p):   # a static results.tsv carries `# id ` lines; an identity file (emit's output) is bare lines
            with open(p, errors="replace") as fh:
                results = fh.readline().startswith("# static results")
            return read_id(p, "# id ") if results else read_id(p, "")
        return 0 if compare(load(a[1]), load(a[2])) else 1
    if a[:1] == ["plan"] and opt("--root") and opt("--results"):
        try:
            rows = plan(os.path.abspath(opt("--root")), opt("--results"))
        except (Refused, OSError) as e:
            print(f"plan: REFUSED — {e}", file=sys.stderr)
            return 3
        for r in rows:
            print("\t".join(r))
        return 0
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main())
