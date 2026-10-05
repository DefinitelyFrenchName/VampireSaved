#!/usr/bin/env python3
"""static_confirm.py — WHICH STATIC-TIER GATES MUST RE-RUN AFTER A CHANGE? (14z-185b, GitHub #188,
route A, maintainer-ruled 2026-09-29: "A, backtested"; then "History for now, traced on WSL2 later").

WIRED 14z-188 (the maintainer, shown the traced test: *"Build the wiring"*): `tests/run_all_static.sh --confirm
<results.tsv>` runs `plan` below. The traced test (every static gate's ACTUAL reads under strace on Linux, ERIS):
at `4e1859d9`, 195/195 gates, 36,722 reads, 0 misses; the predictor as of `d1f9c6e8` on the same traces, 271 misses
in eight gates and two TIMEOUTs (the control that the analysis can see a miss); its gate list equals the runner's.
Its limits stand: reads by path only, relative paths resolved at the root only, ignored files not counted, and eleven
gates exited non-zero under strace (their reads may be short of a passing run's).

THE PREDICTION, over-approximate by design (a wrong STALE costs a re-run; a wrong CARRIED hides a red).
A registered gate (tests/ci_portable.txt, tests/ci_static.txt) is STALE for a changed path c when:
  R1 c is a program in the gate's reach (tools/battery_reach.py's STRICT closure from tests/<gate>.sh:
     paths and imports on CODE lines — a comment runs nothing; measured 14z-185b, the non-strict set
     marked 160 of 185 gates stale for a STATE.md-only change, because comments name most tools);
  R2 a CODE line of a file in the reach names c's basename (word bounded, as battery_reach's --dirty);
  R3 a file in the reach names one of c's ancestor directories as a directory — the token followed by
     an optional `/` and then a non-path character (a quote, space, `*`, `)`, end of line), or as
     quoted components joined by commas (`"docs", "project"`);
  R4 the reach reads the whole tree (`git ls-files`, `git grep`, `git status`, `os.walk(`, `rglob(`,
     `find .`, `glob.glob(` with `**`): every change;
  R5 a DATA file the reach names (a tracked .tsv/.txt/.json/.toml/.csv whose path or basename a code line
     carries) names c by path or basename — the reader takes its file list from data (docs/doc_locks.tsv,
     docs/doc_shape.tsv, docs/project/tickets.tsv; 14z-188, the traced test's misses);
  R6 a TEMPLATED path in the reach matches c: a token carrying a placeholder (`$n`, `${n}`, `{expr}`, `%s`,
     `*`) with its placeholders read as one path component each and a leading all-placeholder component
     dropped (`build/manifest/charmap_$n.toml`, `"patch/effect_c5*.json"`), matched as a path suffix when it
     holds a `/`, else against c's basename when its literal part is more than an extension;
  R7 c is a `.gitignore` or `.gitattributes` and the reach runs `git` (git reads them on every command).
TWO NARROWINGS (14z-190, #188 option B, maintainer-ruled 2026-10-04: "Let's go for B"; PROVISIONAL until a fresh
ERIS trace scores them at 0 misses — until then a close does not lean on them for a saving claim):
  N-A (R3) a change under `build/` is not STALE for a gate whose reach names only the bare `build` directory:
     every tier writes untracked files there, so the bare name made ~75 gates stale at every close; a deeper
     name (`build/m3b_merged31`, a templated `build/$B/...`) still counts, and R6 reads a template ENDING in a
     placeholder (`"build/$b"`, `f"build/{b}"`) as the whole directory under it — the trace of B as first built
     found 15 reads in 2 gates that only the bare name had caught (14z-190, maintainer: "Land the fixed B").
     NARROW_R3_TOP lists the top directories.
  N-B (R2) for a basename in NARROW_R2 (`STATE.md`), a mention counts only as a quoted literal or a path
     component (`"STATE.md"`, `'STATE.md'`, `$ROOT/STATE.md`) or where it survives with every PROSE string
     (quoted text holding a space: messages, echo lines) removed — a bare shell argument still counts. Every close
     edits STATE.md, and ~63 gates' tools name it only in messages.
Otherwise the gate is CARRIED. A BINARY file in the reach (a NUL in its first 8 KiB — the FBNeo executable
is one) has no text: it names nothing, and R1 still covers a change to it (14z-188: read as text, its 42 MB
made every rule search take seconds and two gates ran past the traced test's 600 s cap).

Usage:
  python3 tools/static_confirm.py predict --root DIR (--base COMMIT [--head COMMIT] | --changed PATH ...)
      the changed set is `git diff --name-only BASE HEAD` in DIR (HEAD defaults to the working
      tree: tracked changes plus untracked files), and/or the --changed paths; prints each STALE gate
      with its first reason, the CARRIED count, and the share of gates re-run.
  python3 tools/static_confirm.py backtest EVENTS --repo DIR
      EVENTS: `gate<TAB>base<TAB>head<TAB>extra changed paths (space-separated, or -)<TAB>note`,
      one recorded red per row. Each head is checked out in a temporary worktree; the red gate must
      be STALE. Exit 1 on any miss.
  python3 tools/static_confirm.py plan --root DIR --results FILE
      WIRED into tests/run_all_static.sh --confirm FILE (14z-188, ruled "Build the wiring"): FILE is a previous
      run's results.tsv (written by the runner on every run: `# head <sha>`, `# utc <start>`, `# dirty <path>`
      lines, then gate<TAB>verdict<TAB>seconds<TAB>declared<TAB>fired<TAB>honoured). Prints one line per
      registered gate: `RERUN<TAB>gate<TAB>reason` — not PASS in FILE, absent from it, or STALE by the rules
      above — or `CARRY<TAB>gate<TAB>declared<TAB>fired<TAB>honoured`. The changed set: `git diff --name-only
      <head>` (tracked, working tree) + every path dirty at that run + every untracked, unignored file modified
      after the run's start (an untracked file older than the run cannot have changed since). An unknown head
      re-runs everything.
  python3 tools/static_confirm.py --selftest
      a synthetic repo of five gates, one per reader class, with known answers.
"""
import os, re, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import battery_reach as br   # noqa: E402

WHOLE = re.compile(r"git\s+(?:ls-files|grep|status)\b|os\.walk\(|\.rglob\(|\bfind\s+\.(?:\s|$)|glob\.glob\([^)]*\*\*")
_TEXT = {}


def text(root, p):
    """a file's CODE: comment lines (`#`; `--` in Lua only, battery_reach.is_comment) and python docstrings
    dropped, as battery_reach's strict set does — a comment runs nothing and reads nothing."""
    k = (root, p)
    if k not in _TEXT:
        try:
            with open(os.path.join(root, p), "rb") as fh:
                raw = fh.read()
            t = "" if b"\0" in raw[:8192] else raw.decode("utf-8", errors="replace")
        except OSError:
            t = ""
        skip = br.docstring_lines(p, t)
        _TEXT[k] = "\n".join("" if (i + 1) in skip or br.is_comment(p, l) else l
                              for i, l in enumerate(t.split("\n")))
    return _TEXT[k]


def registry(root):
    names = []
    for f in ("tests/ci_portable.txt", "tests/ci_static.txt"):
        fp = os.path.join(root, f)
        if os.path.exists(fp):
            for line in open(fp, encoding="utf-8"):
                n = line.split("#", 1)[0].strip()
                if n:
                    names.append(n)
    return names


def reach(root, gate, files):
    br.STRICT[0] = True
    br.EXTRA[:] = []
    seen, _ = br.closure(root, [f"tests/{gate}.sh"], files)
    return sorted(seen)


NARROW_R3_TOP = ("build",)     # N-A: the bare top directory is not a reader of what changes under it
NARROW_R2 = ("STATE.md",)      # N-B: R2 for these basenames ignores a mention inside a prose string
QUOTED = re.compile(r"\"(?:[^\"\\\n]|\\.)*\"|'(?:[^'\\\n]|\\.)*'")   # EVERY quoted string, in order
_PROSE = {}


def deprose(t):
    """N-B: the text with every prose string (quoted text holding a space) removed, cached per text."""
    k = hash(t)
    if k not in _PROSE:
        # every quoted string is consumed left to right (a short quoted path must close its own quote, or the
        # next pair is read inside out — run_suite.sh's `"$EXPDIR/$name.diverge" ] && ...` line, 14z-190);
        # only those holding whitespace (prose) are dropped
        _PROSE[k] = QUOTED.sub(lambda m: "" if re.search(r"\s", m.group(0)) else m.group(0), t)
    return _PROSE[k]


def narrow_search(base, t):
    """N-B: does t name `base` as a quoted literal or path component, or outside every prose string?"""
    e = re.escape(base)
    lit = re.search(r"(?<=[\"'/])" + e + r"(?![\w-])", t)   # N-B literal clause
    return bool(lit or re.search(r"(?<![\w.-])" + e + r"(?![\w-])", deprose(t)))


def dir_patterns(c):
    parts = c.split("/")[:-1]
    pats = []
    for k in range(1, len(parts) + 1):
        if k == 1 and parts[0] in NARROW_R3_TOP:   # N-A
            continue
        d = "/".join(parts[:k])
        pats.append((d, re.compile(r"(?<![\w.-])" + re.escape(d) + r"/?(?=[\"'\s*)\]]|$)", re.M)))
        if k > 1:
            joined = r"[\"']\s*,\s*[\"']".join(re.escape(x) for x in parts[:k])
            pats.append((d, re.compile(r"[\"']" + joined + r"[\"']")))
    return pats


def patterns(c):
    """-> (basename regex, [(dir, regex)]) for a changed path, compiled once per path."""
    base = os.path.basename(c)
    return (re.compile(r"(?<![\w.-])" + re.escape(base) + r"(?![\w-])") if base else None, dir_patterns(c))


DATA_EXT = (".tsv", ".txt", ".json", ".toml", ".csv")
_DATA = {}
_TMPL = {}
GIT_RUN = re.compile(r"(?<![\w.-])git\s+(?:-C\s+\S+\s+)?[a-z][\w-]*")
TOKEN = re.compile(r"[\w./${}*%<>-]+")
PLACE = re.compile(r"\$\{\w+\}|\$\w+|\{[^{}/]*\}|%[sd]|\*")


def data_files(root, blob):
    """R5: the tracked data files the reach's code names, by path or basename (one scan per blob)."""
    k = (root, hash(blob))
    if k not in _DATA:
        tracked = _tracked(root)
        out = []
        for f in tracked:
            if f.endswith(DATA_EXT):
                b = os.path.basename(f)
                if b in blob and re.search(r"(?<![\w.-])" + re.escape(b) + r"(?![\w-])", blob):
                    out.append(f)
        _DATA[k] = out
    return _DATA[k]


_TRACKED = {}


def _tracked(root):
    if root not in _TRACKED:
        r = subprocess.run(["git", "ls-files"], cwd=root, capture_output=True, text=True)
        _TRACKED[root] = r.stdout.splitlines() if r.returncode == 0 else []
    return _TRACKED[root]


def templates(root, blob):
    """R6: (regex, token, is_path) for every templated path token in the reach's code."""
    k = (root, hash(blob))
    if k not in _TMPL:
        out, seen = [], set()
        for tok in TOKEN.findall(blob):
            if tok in seen or not PLACE.search(tok) or not ("/" in tok or "." in tok):
                continue
            seen.add(tok)
            parts = tok.split("/")
            while parts and PLACE.sub("", parts[0]) == "":
                parts = parts[1:]
            if not parts:
                continue
            t = "/".join(parts)
            lit = PLACE.sub("", t)
            rx = "".join("[^/]*" if PLACE.fullmatch(x) else re.escape(x) for x in re.split(r"(" + PLACE.pattern + r")", t) if x)
            if "/" in t:
                if len(lit.replace("/", "")) < 3:
                    continue
                # a template ENDING in a placeholder names a directory (`"build/$b"`, `f"build/{b}"`): it covers
                # everything under it (14z-190: without this, N-A missed 15 traced reads in test_pcrel_escapes and
                # test_shared_writes, which the bare `build` directory had caught by accident)
                tail = r"(?:/.*)?$" if PLACE.fullmatch(parts[-1]) else r"$"   # R6 directory template
                out.append((re.compile(r"(?:^|/)" + rx + tail), tok, True))
            else:
                stem = re.sub(r"\.[\w]+$", "", lit)
                if len(stem) < 3:
                    continue
                out.append((re.compile(r"^" + rx + r"$"), tok, False))
        _TMPL[k] = out
    return _TMPL[k]


def stale_reason(root, rch, blob, c, pats):
    """the first rule that makes this gate STALE for c; `blob` is the reach's texts joined (searched
    once), the file is named only on a hit."""
    if c in rch:
        return f"R1 {c} is in the reach"
    bpat, dps = pats
    base = os.path.basename(c)
    if bpat and base in NARROW_R2:   # N-B
        if narrow_search(base, blob):
            where = next((p for p in rch if narrow_search(base, text(root, p))), "?")
            return f"R2 {where} names {base}"
        bpat = None
    tests = ([("R2", bpat, base)] if bpat else []) + [("R3", rx, d) for d, rx in dps]
    for rule, rx, what in tests:
        if rx.search(blob):
            where = next((p for p in rch if rx.search(text(root, p))), "?")
            return f"R2 {where} names {what}" if rule == "R2" else f"R3 {where} reads directory {what}"
    base = os.path.basename(c)
    for d in data_files(root, blob):
        if d == c:
            continue
        t = text(root, d)
        if c in t or (bpat and base in t and bpat.search(t)):
            return f"R5 the data file {d} names {c}"
    for rx, tok, is_path in templates(root, blob):
        if rx.search(c if is_path else base):
            return f"R6 the template {tok} matches {c}"
    if base in (".gitignore", ".gitattributes") and GIT_RUN.search(blob):
        return f"R7 the reach runs git, which reads {c}"
    return None


def changed_set(root, base, head, extra):
    out = set(extra)
    if base:
        args = ["git", "diff", "--name-only", base] + ([head] if head else [])
        out |= set(subprocess.run(args, cwd=root, capture_output=True, text=True, check=True).stdout.splitlines())
        if not head:   # one path per LINE: a name with a space is one path (14z-188: `.split()` made two)
            out |= set(subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], cwd=root,
                                      capture_output=True, text=True).stdout.splitlines())
    return sorted(out)


_REFS = {}


def _cached_refs(orig):
    def refs(root, p, files):
        k = (root, p)
        if k not in _REFS:
            _REFS[k] = orig(root, p, files)
        return _REFS[k]
    return refs


br.refs = _cached_refs(br.refs)   # one reference scan per file, shared by every gate's closure


def predict(root, changed):
    files = br.index(root, [])
    gates = registry(root)
    pats = {c: patterns(c) for c in changed}
    stale, carried = {}, []
    for g in gates:
        rch = reach(root, g, files)
        blob = "\n".join(text(root, p) for p in rch)
        why = None
        for c in changed:
            why = stale_reason(root, rch, blob, c, pats[c])
            if why:
                break
        if not why and changed and WHOLE.search(blob):
            where = next((p for p in rch if WHOLE.search(text(root, p))), "?")
            why = f"R4 {where} reads the whole tree"
        if why:
            stale[g] = why
        else:
            carried.append(g)
    return gates, stale, carried


def show(gates, stale, carried, changed):
    print(f"changed paths: {len(changed)}")
    for g, why in stale.items():
        print(f"  STALE   {g:40s} {why}")
    share = 100.0 * len(stale) / len(gates) if gates else 0.0
    print(f"stale {len(stale)} / {len(gates)} gates ({share:.1f}% re-run), carried {len(carried)}")


def backtest(events, repo):
    miss = 0
    for n, line in enumerate(open(events, encoding="utf-8"), 1):
        if not line.strip() or line.startswith("#"):
            continue
        gate, base, head, extra, note = (line.rstrip("\n").split("\t") + ["", "", "", "", ""])[:5]
        extra = [] if extra in ("", "-") else extra.split()
        with tempfile.TemporaryDirectory() as d:
            wt = os.path.join(d, "wt")
            subprocess.run(["git", "worktree", "add", "--detach", "-q", wt, head], cwd=repo, check=True)
            try:
                _TEXT.clear(); _REFS.clear(); _DATA.clear(); _TMPL.clear(); _TRACKED.clear()
                changed = changed_set(wt, base, head, extra)
                gates, stale, carried = predict(wt, changed)
                ok = gate in stale
                miss += not ok
                share = 100.0 * len(stale) / len(gates) if gates else 0.0
                print(f"{'CAUGHT' if ok else 'MISSED'} {gate} ({base[:8]}..{head[:8]}, {len(changed)} changed): "
                      f"{stale.get(gate, 'carried')}; re-run {len(stale)}/{len(gates)} ({share:.1f}%) — {note}")
            finally:
                subprocess.run(["git", "worktree", "remove", "--force", wt], cwd=repo)
    print(f"backtest: {'no miss' if not miss else str(miss) + ' MISSED'}")
    return 1 if miss else 0


def selftest():
    ok = True
    with tempfile.TemporaryDirectory() as root:
        def w(rel, t, x=False):
            p = os.path.join(root, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w").write(t)
            if x:
                os.chmod(p, 0o755)
        w("tests/ci_portable.txt", "g_named\ng_prog\ng_dir\ng_join\ng_whole\ng_data\ng_tmpl\ng_git\ng_bin\n"
          "g_buildbare\ng_buildsub\ng_buildtmpl\ng_statemsg\ng_stateread\ng_statearg\ng_statepair\n")
        # N-A: a bare `build` reader and a deeper one; N-B: a message, an inline read and a bare argument
        w("tests/g_buildbare.sh", "#!/bin/sh\nls build > /dev/null\n", True)
        w("tests/g_buildsub.sh", "#!/bin/sh\nfor f in build/m1/*; do :; done\n", True)
        # a directory TEMPLATE: the build name comes from data, the code names only "build/$b"
        w("tests/g_buildtmpl.sh", "#!/bin/sh\nfor b in m1 m2; do python3 -c \"print(1)\" \"build/$b\"; done\n", True)
        w("tests/g_statemsg.sh", "#!/bin/sh\necho \"the ruling lives in STATE.md now\"\n", True)
        w("tests/g_stateread.sh", "#!/bin/sh\npython3 -c \"import sys; print(open('STATE.md').read())\"\n", True)
        w("tests/g_statearg.sh", "#!/bin/sh\nwc -l STATE.md\n", True)
        # a short quoted path before the message must close its own quote (the pairing trap)
        w("tests/g_statepair.sh", "#!/bin/sh\n[ -f \"$D/x.diverge\" ] && echo \"freeze it, as a STATE.md decision\"\n", True)
        w("tests/g_data.sh", "#!/bin/sh\npython3 -c \"print(open('lists/locks.tsv').read())\"\n", True)
        w("lists/locks.tsv", "notes/locked.md\tfirst\n")
        w("notes/locked.md", "x\n")
        w("tests/g_tmpl.sh", "#!/bin/sh\nfor n in a b; do cat cfg/rows/item_$n.toml; done\nls $W/$n.out\ndiff -q $W/x \\\n    --from-file \"cfg/base/$n.txt\"\n", True)
        w("cfg/rows/item_a.toml", "x\n")
        w("tests/g_git.sh", "#!/bin/sh\ngit -C sub diff --stat\n", True)
        w("tests/g_bin.sh", "#!/bin/sh\nemu/tool --run\n", True)
        w("emu/tool", "\0" * 16 + "notes/locked.md lists/locks.tsv\n", True)   # an extensionless executable, as emu/fbneo/fbneo
        w("tests/g_named.sh", "#!/bin/sh\ngrep x docs/data/table.tsv\n", True)
        w("tests/g_prog.sh", "#!/bin/sh\npython3 tools/helper.py\n", True)
        w("tools/helper.py", "import sys\n")
        w("tests/g_dir.sh", "#!/bin/sh\nfor f in docs/game/*.md; do :; done\n", True)
        w("tests/g_join.sh", "#!/bin/sh\npython3 -c \"import os; os.listdir(os.path.join('x', 'docs', 'project'))\"\n", True)
        w("tests/g_whole.sh", "#!/bin/sh\ngit ls-files | wc -l\n", True)
        cases = [
            # g_join names 'docs' as a bare quoted directory: every change under docs/ is STALE for it
            # (over-approximate by design, R3 at depth 1)
            ("docs/data/table.tsv", {"g_named", "g_join", "g_whole"}),
            ("tools/helper.py", {"g_prog", "g_whole"}),
            ("docs/game/new.md", {"g_dir", "g_join", "g_whole"}),
            ("docs/project/x.md", {"g_join", "g_whole"}),
            # N-B: the message does not read STATE.md; the inline read and the bare argument do
            ("STATE.md", {"g_whole", "g_stateread", "g_statearg"}),
            # N-A: the bare `build` reader is carried, the deeper reader is not
            ("build/m1/new.log", {"g_buildsub", "g_buildtmpl", "g_whole"}),
            ("tests/g_named.sh", {"g_named", "g_whole"}),
            # R5: g_data reads a data file that names the changed file
            ("notes/locked.md", {"g_data", "g_whole"}),
            # R6: g_tmpl's templated path matches; `$W/$n.out` is too generic to count (no stem)
            ("cfg/rows/item_b.toml", {"g_tmpl", "g_whole"}),
            ("cfg/other.out", {"g_whole"}),
            # an option continuation (`    --from-file "cfg/base/$n.txt"`) is code in a shell file, not a Lua comment
            ("cfg/base/x.txt", {"g_tmpl", "g_whole"}),
            # R7: every git user reads .gitignore
            (".gitignore", {"g_git", "g_whole"}),
            # a binary in the reach names nothing (R1 still covers the binary itself): read as text, the
            # names inside it would make g_bin stale for notes/locked.md above
            ("emu/tool", {"g_bin", "g_whole"}),
        ]
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        for c, want in cases:
            _TEXT.clear(); _REFS.clear(); _DATA.clear(); _TMPL.clear(); _TRACKED.clear()
            _, stale, _ = predict(root, [c])
            got = set(stale)
            good = got == want
            ok = ok and good
            print(f"  {'ok' if good else 'FAIL'}: {c} -> stale {sorted(got)}" + ("" if good else f", expected {sorted(want)}"))
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def plan(root, results):
    import time, calendar
    head, utc, dirty, rows = None, None, [], {}
    for line in open(results, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("# head "):
            head = line.split()[2]
        elif line.startswith("# utc "):
            utc = line.split()[2]
        elif line.startswith("# dirty "):
            dirty.append(line[len("# dirty "):])
        elif line and not line.startswith("#"):
            c = line.split("\t")
            rows[c[0]] = c
    gates = registry(root)
    known = head and subprocess.run(["git", "cat-file", "-e", head + "^{commit}"], cwd=root,
                                    capture_output=True).returncode == 0
    if not known:
        return [("RERUN", g, f"the previous run's head {head or '(none)'} is not in this repository") for g in gates]
    changed = set(subprocess.run(["git", "diff", "--name-only", head], cwd=root, capture_output=True, text=True,
                                 check=True).stdout.splitlines()) | set(dirty)
    t0 = calendar.timegm(time.strptime(utc, "%Y-%m-%dT%H:%M:%SZ")) if utc else 0
    for f in subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], cwd=root, capture_output=True,
                            text=True).stdout.splitlines():
        try:
            if os.path.getmtime(os.path.join(root, f)) >= t0:
                changed.add(f)
        except OSError:
            changed.add(f)
    _, stale, _ = predict(root, sorted(changed)) if changed else (gates, {}, gates)
    out = []
    for g in gates:
        r = rows.get(g)
        if r is None:
            out.append(("RERUN", g, "absent from the previous run"))
        elif r[1] != "PASS":
            out.append(("RERUN", g, f"{r[1]} in the previous run"))
        elif g in stale:
            out.append(("RERUN", g, "STALE: " + stale[g]))
        else:
            out.append(("CARRY", g, r[3] if len(r) > 3 else "0", r[4] if len(r) > 4 else "0", r[5] if len(r) > 5 else "0"))
    return out


def main():
    a = sys.argv[1:]
    if a[:1] == ["--selftest"]:
        return selftest()
    def opt(k, many=False):
        v = [a[i + 1] for i, x in enumerate(a) if x == k]
        return v if many else (v[0] if v else None)
    if a[:1] == ["plan"] and opt("--root") and opt("--results"):
        for row in plan(os.path.abspath(opt("--root")), opt("--results")):
            print("\t".join(row))
        return 0
    if a[:1] == ["predict"] and opt("--root"):
        root = os.path.abspath(opt("--root"))
        changed = changed_set(root, opt("--base"), opt("--head"), opt("--changed", True))
        gates, stale, carried = predict(root, changed)
        show(gates, stale, carried, changed)
        return 0
    if a[:1] == ["backtest"] and len(a) >= 2 and opt("--repo"):
        return backtest(a[1], os.path.abspath(opt("--repo")))
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main())
