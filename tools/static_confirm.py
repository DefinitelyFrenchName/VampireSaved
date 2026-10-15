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
#274 (14z-200; scored on a fresh trace of all 222 gates at 6e329411, PILOT, with the session scratch present):
  R1 the reach is closed again over SIBLING programs — a quoted `name.py`/`.sh`/`.lua` in a reach file that exists
     beside that file (`os.path.join(os.path.dirname(__file__), "gen_applier_page.py")`, which battery_reach does
     not follow);
  R3c a quoted last component of a directory, in a reach file that sits in that directory's parent
     (`os.path.join(HERE, "applier")`, tools/applier/);
  R4 also in LIST form (`["git", "-C", root, "ls-files", ...]`); the two misses the trace found at HEAD before
     this change, 15,013 reads in test_entropy_tripwire and 4 in test_applier_key_first, are these three;
  N-C (R3) a directory counts as read where it is named as a path: a token that follows a quote or `/` anywhere,
     or a bare token in non-python code once every prose string is removed; NOT a python identifier (`docs`),
     prose ("the control tests nothing"), a case-pattern glob (`*tests/*.sh*`), or a directory joined to a
     further LITERAL component (`"docs" / "checksums.txt"`, `"tools", "x.py"`: that names a file, R2's);
     `,`- or `/`-joined quoted components still name the deeper directory;
  N-C also counts a directory named as a shell default or assignment value (`${1:-release/x}`, `REL=release/x`):
     the trace of the nine gates the first #274 trace could not score (node, Chromium, xdelta3 and the community
     workbook present on PILOT, #269 "C first", 14z-200) found 9 reads of release/merged-m23/mame in
     test_applier_vcdiff that N-C as first built missed and the predictor before #274 caught;
  N-D the session tooling's untracked scratch — build/agent<N>*/, build/rulecheck/, build/static_runs/,
     build/snapshot_runs/ (SCRATCH) — leaves every gate's change set but the whole-tree readers' (R4): the trace
     shows no gate opening a file under them, and three list them through git's untracked walk
     (test_emulator_staleness, test_run_on_snapshot, test_session_metrics), which a path trace cannot score.
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
      re-runs everything. THE SESSION RUN (#269, 14z-200; ruled 2026-10-12, *"I agree with your proposal to turn the
      static tier around"*, and 2026-10-14, the three-gate core after the maintainer's *"C first"*): two more reasons re-run a gate that is PASS and
      not STALE — the CORE, a gate whose script carries the line `# CONFIRM: always` (test_commit_subject,
      test_close_tools, test_rule_checker: their inputs move outside the tracked tree), and a gate whose recorded
      controls were not all executed and honoured in FILE (`honoured` below `declared`: a base run made with
      --exec-controls none or portable), so a carried gate's controls were executed in the run it is carried from.
  THE DIRTY SUBMODULE (#286 (b), 14z-202, maintainer-ruled 2026-10-15): `emu/fbneo` carries our applied patches, so it
      is dirty at every run and `git diff --name-only` names it at every confirm (21 gates re-ran for it in each of the
      14z-201 close's passes). The runner records `# subfp <path> <fingerprint>` for every initialised submodule (the
      `subfp` command below); a changed submodule path whose fingerprint equals the base run's is dropped from the
      changed set. A base run without the line keeps the path changed.
      The fingerprint: the submodule's HEAD, its `git diff --binary HEAD` (staged and unstaged) and every untracked,
      unignored file's name and content.
  CONTROLS ONLY ON A REAL CHANGE (#286 (c), 14z-202, maintainer-ruled 2026-10-15: *"with controls only when a gate or
      its real inputs changed"*): a RERUN row carries a 4th field. `controls` when the gate's controls must execute:
      the gate is absent from the base, not PASS there, its base controls were not all executed, or the gate's CODE
      names a changed path directly (`direct_read`: R1 a program in its reach, R2 a code line naming the file, R6 a
      templated path matching it). Otherwise — STALE only by an indirect rule (R3 a directory it lists, R4 the whole
      tree, R5 a data file that mentions the path, R7 git's own files), or the core with nothing it names changed —
      `carry-controls<TAB>declared<TAB>fired<TAB>honoured` from the base row: the gate re-runs and its controls are
      carried, as a carried gate's are. Measured 14z-202 (section 22 of tests/test_static_runner.sh): a data file a
      gate reads with `cat` is R2, not R1 — the reach holds programs only. A freeze and a release execute every
      control (--confirm is refused there).
  python3 tools/static_confirm.py subfp --root DIR
      one line `<path> <fingerprint>` per initialised submodule of DIR (#286 (b)).
  python3 tools/static_confirm.py --selftest
      a synthetic repo of five gates, one per reader class, with known answers.
"""
import os, re, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import battery_reach as br   # noqa: E402

WHOLE = re.compile(r"git\s+(?:ls-files|grep|status)\b|os\.walk\(|\.rglob\(|\bfind\s+\.(?:\s|$)|glob\.glob\([^)]*\*\*"
                   # R4 in LIST form (14z-200, #274: tools/entropy_tripwire.py's ["git", "-C", root, "ls-files", ...] was
                   # unseen, 15,013 traced reads missed in test_entropy_tripwire)
                   r"|[\"']git[\"']\s*,\s*(?:[\"']-C[\"']\s*,\s*[^,\n]+,\s*)?[\"'](?:ls-files|grep|status)[\"']")
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


SIBLING_PROG = re.compile(r"[\"']([\w.-]+\.(?:py|sh|lua))[\"']")


def reach(root, gate, files):
    """the STRICT closure from the gate script, closed again over SIBLING programs: a quoted `name.py`/`.sh`/`.lua`
    in a reach file that exists beside that file (14z-200, #274: tools/package_release.py runs
    os.path.join(os.path.dirname(__file__), "gen_applier_page.py"), which battery_reach does not follow, and the
    four tools/applier/ reads that script makes were missed in test_applier_key_first)"""
    br.STRICT[0] = True
    br.EXTRA[:] = []
    seeds = [f"tests/{gate}.sh"]
    while True:
        seen, _ = br.closure(root, seeds, files)
        add = set()
        for p in seen:
            if not p.endswith((".py", ".sh", ".lua")):
                continue
            d = os.path.dirname(p)
            for m in SIBLING_PROG.finditer(text(root, p)):
                q = os.path.join(d, m.group(1)) if d else m.group(1)
                if q not in seen and os.path.isfile(os.path.join(root, q)):
                    add.add(q)
        if not add:
            return sorted(seen)
        seeds = sorted(set(seen) | add)


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


_R3B = {}


def r3_blob(root, rch, blob):
    """N-C: the reach's non-python code with every prose string removed — where a BARE directory token counts"""
    k = (root, hash(blob))
    if k not in _R3B:
        _R3B[k] = "\n".join(deprose(text(root, p)) for p in rch if not p.endswith(".py"))
    return _R3B[k]


# N-D: untracked scratch the session tooling writes under build/ is not an input of any static gate
SCRATCH = re.compile(r"^build/(?:agent\d+\w*|rulecheck|static_runs|snapshot_runs)/")


def drop_scratch(c):
    return bool(SCRATCH.match(c))


def narrow_search(base, t):
    """N-B: does t name `base` as a quoted literal or path component, or outside every prose string?"""
    e = re.escape(base)
    lit = re.search(r"(?<=[\"'/])" + e + r"(?![\w-])", t)   # N-B literal clause
    return bool(lit or re.search(r"(?<![\w.-])" + e + r"(?![\w-])", deprose(t)))


JOINED_LIT = r"(?![\"']\s*[,/]\s*[\"'][^\"'{}$*%\n]*[\"'])"   # N-C: `"tools", "x.py"` / `"docs" / "a.txt"` name a FILE


def dir_patterns(c):
    """-> [(dir, kind, regex)]: kind `bare` (searched on deprosed non-python text), `lit` (a quoted or `/`-led
    token, searched on every text) or `join` (quoted components joined by `,` or `/`, every text)."""
    parts = c.split("/")[:-1]
    pats = []
    for k in range(1, len(parts) + 1):
        if k == 1 and parts[0] in NARROW_R3_TOP:   # N-A
            continue
        d = "/".join(parts[:k])
        e = re.escape(d)
        pats.append((d, "bare", re.compile(r"(?<![\w.*-])" + e + r"/?(?=[\"'\s*)\]]|$)" + JOINED_LIT, re.M)))
        pats.append((d, "lit", re.compile(r"(?<=[\"'/])" + e + r"/?(?=[\"'\s*)\]]|$)" + JOINED_LIT, re.M)))
        # a path as a shell default or assignment value: `${1:-release/x/y}`, `REL=release/x` (14z-200, the
        # #269 "C first" trace: test_applier_vcdiff's `REL="${1:-release/merged-m23/mame}"`, 9 reads N-C missed)
        pats.append((d, "lit", re.compile(r"(?:(?<=:[-=+?])|(?<==))" + e + r"/?(?=[\"'\s*)\]}]|$)", re.M)))   # SHELL-DEFAULT
        if k > 1:
            joined = r"[\"']\s*[,/]\s*[\"']".join(re.escape(x) for x in parts[:k])
            pats.append((d, "join", re.compile(r"[\"']" + joined + r"[\"']")))
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
    if bpat and bpat.search(blob):
        where = next((p for p in rch if bpat.search(text(root, p))), "?")
        return f"R2 {where} names {base}"
    for d in [x for x, _, _ in dps if "/" in x]:   # R3c (14z-200, #274): os.path.join(HERE, "applier") beside it
        par, name = d.rsplit("/", 1)
        sib = re.compile(r"(?<=[\"'])" + re.escape(name) + r"/?(?=[\"'])" + JOINED_LIT)
        for p in rch:
            if os.path.dirname(p) == par and sib.search(text(root, p)):
                return f"R3 {p} reads its sibling directory {d}"
    for d, kind, rx in dps:   # N-C: R3 by kind; a bare token counts only outside python and outside prose
        hay = r3_blob(root, rch, blob) if kind == "bare" else blob
        if rx.search(hay):
            if kind == "bare":
                where = next((p for p in rch if not p.endswith(".py") and rx.search(deprose(text(root, p)))), "?")
            else:
                where = next((p for p in rch if rx.search(text(root, p))), "?")
            return f"R3 {where} reads directory {d}"
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


def direct_read(root, rch, blob, c, pats):
    """#286 (c): does the gate's CODE name c directly — R1 (a program in the reach), R2 (a code line names its
    basename, N-B applied) or R6 (a templated path matches it)? The indirect rules (R3 a directory, R4 the whole tree,
    R5 a data file's mention, R7 git's own files) are not a direct read."""
    if c in rch:
        return True
    bpat, _ = pats
    base = os.path.basename(c)
    if bpat and base in NARROW_R2:
        if narrow_search(base, blob):
            return True
    elif bpat and bpat.search(blob):
        return True
    return any(rx.search(c if is_path else base) for rx, _, is_path in templates(root, blob))


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


def predict(root, changed, r1=None):
    """the STALE map; when `r1` is a dict, r1[gate] is set, for a STALE gate, to whether its code names a changed path
    DIRECTLY (direct_read: R1, R2 or R6; #286 (c))"""
    files = br.index(root, [])
    gates = registry(root)
    pats = {c: patterns(c) for c in changed}
    stale, carried = {}, []
    # N-D: the session tooling's scratch under build/ is judged by R4 alone (a whole-tree reader lists it); measured
    # 14z-200 on the trace at 6e329411 with the scratch present: no gate opened a file under it
    eff = [c for c in changed if not drop_scratch(c)]
    for g in gates:
        rch = reach(root, g, files)
        blob = "\n".join(text(root, p) for p in rch)
        why = None
        for c in eff:
            why = stale_reason(root, rch, blob, c, pats[c])
            if why:
                break
        if not why and changed and WHOLE.search(blob):
            where = next((p for p in rch if WHOLE.search(text(root, p))), "?")
            why = f"R4 {where} reads the whole tree"
        if why:
            stale[g] = why
            if r1 is not None:
                r1[g] = any(direct_read(root, rch, blob, c, pats[c]) for c in eff)
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
          "g_buildbare\ng_buildsub\ng_buildtmpl\ng_statemsg\ng_stateread\ng_statearg\ng_statepair\n"
          "g_prose\ng_pyident\ng_pyfile\ng_casepat\ng_pylist\ng_pydeep\ng_gitlist\ng_sib\ng_shdef\n")
        # 14z-200 (#269 "C first"): a directory named only as a shell parameter default
        w("tests/g_shdef.sh", "#!/bin/sh\nREL=\"${1:-rel/m23/mame}\"\n[ -f \"$REL/manifest.json\" ] && ls \"$REL\"\n", True)
        # 14z-200 (#274): R4 in list form; a sibling program run by a path beside its caller, which reads a
        # directory it names by its last component (R3c)
        w("tests/g_gitlist.sh", "#!/bin/sh\npython3 tools/gitlist.py\n", True)
        w("tools/gitlist.py", "import subprocess\nsubprocess.run([\"git\", \"-C\", \".\", \"ls-files\", \"-z\"])\n")
        w("tests/g_sib.sh", "#!/bin/sh\npython3 tools/sibmain.py\n", True)
        w("tools/sibmain.py", "import os, subprocess, sys\nsubprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), \"sibchild.py\")])\n")
        w("tools/sibchild.py", "import os\nHERE = os.path.dirname(__file__)\nprint(os.listdir(os.path.join(HERE, \"sibdata\")))\n")
        w("tools/sibdata/a.mjs", "x\n")
        # N-C: prose naming a directory, a python identifier, a joined literal FILE, a case-pattern glob — none
        # reads the directory; a quoted directory listed in python, and a joined pair listed, do
        w("tests/g_prose.sh", "#!/bin/sh\necho \"the control tests nothing; outside tools/ and docs\"\n", True)
        w("tests/g_pyident.sh", "#!/bin/sh\npython3 tools/pyident.py\n", True)
        w("tools/pyident.py", "docs = []\nprint(len(docs), [t for t in docs])\n")
        w("tests/g_pyfile.sh", "#!/bin/sh\npython3 tools/pyfile.py\n", True)
        w("tools/pyfile.py", "import os, pathlib\nR = pathlib.Path('.')\nm = R / \"docs\" / \"sums.txt\"\nn = os.path.join('.', \"tests\", \"one.sh\")\n")
        w("tests/g_casepat.sh", "#!/bin/sh\ncase \"$1\" in *tests/*.sh*) : ;; esac\n", True)
        w("tests/g_pylist.sh", "#!/bin/sh\npython3 tools/pylist.py\n", True)
        w("tools/pylist.py", "import os\nprint(os.listdir(os.path.join('.', \"tests\")))\n")
        w("tests/g_pydeep.sh", "#!/bin/sh\npython3 tools/pydeep.py\n", True)
        w("tools/pydeep.py", "import pathlib\nprint(list((pathlib.Path('.') / \"tests\" / \"expected\").glob('*')))\n")
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
            # N-C: g_join's 'docs' is joined to the literal 'project', so it names docs/project, not docs
            ("docs/data/table.tsv", {"g_named", "g_whole"}),
            ("tools/helper.py", {"g_prog", "g_whole"}),
            ("docs/game/new.md", {"g_dir", "g_whole"}),
            # N-C: prose, a python identifier, a joined literal file and a case-pattern glob read no directory;
            # the python listing of the quoted directory does (tests/new.sh), and the joined pair's listing
            # reads tests/expected/ (and only it)
            ("docs/other.md", {"g_whole"}),
            # (g_casepat's `*tests/*.sh*` is still an R6 TEMPLATE for a tests/*.sh name; N-C's `*` rule is only R3's)
            ("tests/new.sh", {"g_casepat", "g_pylist", "g_whole"}),
            ("tests/data/new.txt", {"g_pylist", "g_whole"}),
            ("tests/expected/new.txt", {"g_pylist", "g_pydeep", "g_whole"}),
            ("docs/sums.txt", {"g_pyfile", "g_whole"}),
            ("docs/project/x.md", {"g_join", "g_whole"}),
            # N-B: the message does not read STATE.md; the inline read and the bare argument do
            ("STATE.md", {"g_whole", "g_stateread", "g_statearg"}),
            # N-A: the bare `build` reader is carried, the deeper reader is not
            ("build/m1/new.log", {"g_buildsub", "g_buildtmpl", "g_whole"}),
            ("tests/g_named.sh", {"g_casepat", "g_named", "g_pylist", "g_whole"}),
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
            # N-D: scratch under build/agent<N>/ is out of every gate's change set but the whole-tree reader's,
            # even for g_buildtmpl, whose "build/$b" template would match it; a build directory is not scratch
            ("build/agent9/t1/x.sh", {"g_whole"}),
            ("build/rulecheck/2026-01-01-01/a/p.md", {"g_whole"}),
            ("build/m2/x.log", {"g_buildtmpl", "g_whole"}),
            # R3c through the sibling closure: tools/sibchild.py (run by tools/sibmain.py beside it) lists sibdata/
            ("tools/sibdata/b.mjs", {"g_sib", "g_whole"}),
            # the shell default `${1:-rel/m23/mame}` names the directory every file under it is read from
            ("rel/m23/mame/README.md", {"g_shdef", "g_whole"}),
        ]
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        for c, want in cases:
            _TEXT.clear(); _REFS.clear(); _DATA.clear(); _TMPL.clear(); _TRACKED.clear()
            _, stale, _ = predict(root, [c])
            got = set(stale)
            want = want | {"g_gitlist"}   # the list-form whole-tree reader is stale for every change, as g_whole
            good = got == want
            ok = ok and good
            print(f"  {'ok' if good else 'FAIL'}: {c} -> stale {sorted(got)}" + ("" if good else f", expected {sorted(want)}"))
    # N-D: the session tooling's untracked scratch under build/ is out of the change set, a build is not
    for c, want in (("build/agent200/t1/x.sh", True), ("build/rulecheck/2026-01-01-01/a/p.md", True),
                    ("build/static_runs/x/results.tsv", True), ("build/snapshot_runs/x/y", True),
                    ("build/m3b_merged31/rompath/vsavjw.zip", False), ("build/agentless/x", False),
                    ("build/manifest/donovan.toml", False), ("tools/agent200.py", False)):
        good = drop_scratch(c) == want
        ok = ok and good
        print(f"  {'ok' if good else 'FAIL'}: drop_scratch({c}) = {drop_scratch(c)}")
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def submodules(root):
    """the initialised submodules' paths, from .gitmodules (#286 (b))"""
    r = subprocess.run(["git", "config", "-f", ".gitmodules", "--get-regexp", r"submodule\..*\.path"], cwd=root,
                       capture_output=True, text=True)
    out = []
    for line in r.stdout.splitlines():
        p = line.split(None, 1)[1] if " " in line else ""
        if p and os.path.exists(os.path.join(root, p, ".git")):
            out.append(p)
    return out


def subfp(root, p):
    """#286 (b): a submodule's state — HEAD, `git diff --binary HEAD`, and each untracked unignored file's name and
    content. Equal fingerprints mean the submodule's checkout did not change between two runs."""
    import hashlib
    d = os.path.join(root, p)
    h = hashlib.sha1()
    for args in (["rev-parse", "HEAD"], ["diff", "--binary", "HEAD"]):
        r = subprocess.run(["git", "-C", d] + args, capture_output=True)
        if r.returncode != 0:
            return None
        h.update(r.stdout + b"\0")
    r = subprocess.run(["git", "-C", d, "ls-files", "-z", "--others", "--exclude-standard"], capture_output=True)
    if r.returncode != 0:
        return None
    for f in sorted(x for x in r.stdout.split(b"\0") if x):
        h.update(f + b"\0")
        try:
            with open(os.path.join(d, f.decode("utf-8", "surrogateescape")), "rb") as fh:
                h.update(hashlib.sha1(fh.read()).digest())
        except OSError:
            h.update(b"?")
    return h.hexdigest()


def core(root, g):
    """#269: a gate whose script carries `# CONFIRM: always` re-runs at every confirm (its inputs move off-tree)."""
    try:
        return any(l.rstrip() == "# CONFIRM: always" or l.startswith("# CONFIRM: always ")
                   for l in open(os.path.join(root, "tests", g + ".sh"), encoding="utf-8", errors="replace"))
    except OSError:
        return False


def plan(root, results):
    import time, calendar
    head, utc, dirty, rows, fps = None, None, [], {}, {}
    for line in open(results, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("# head "):
            head = line.split()[2]
        elif line.startswith("# utc "):
            utc = line.split()[2]
        elif line.startswith("# dirty "):
            dirty.append(line[len("# dirty "):])
        elif line.startswith("# subfp "):
            _p = line[len("# subfp "):].rsplit(" ", 1)
            if len(_p) == 2:
                fps[_p[0]] = _p[1]
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
    for p in [p for p in fps if p in changed]:   # SUBMODULE-UNCHANGED (#286 (b))
        if subfp(root, p) == fps[p]:
            changed.discard(p)
    r1 = {}
    _, stale, _ = predict(root, sorted(changed), r1) if changed else (gates, {}, gates)

    def ctl(r):   # #286 (c): carry the base row's controls unless a path in the reach changed
        if r1.get(r[0]) or len(r) < 6:   # CONTROLS-ON-REACH
            return ("controls",)
        return ("carry-controls", r[3], r[4], r[5])
    out = []
    for g in gates:
        r = rows.get(g)
        if r is None:
            out.append(("RERUN", g, "absent from the previous run", "controls"))
        elif r[1] != "PASS":
            out.append(("RERUN", g, f"{r[1]} in the previous run", "controls"))
        elif len(r) > 5 and r[3].isdigit() and r[5].isdigit() and int(r[5]) < int(r[3]):   # CONTROLS-UNEXECUTED
            out.append(("RERUN", g, f"{r[5]} of its {r[3]} declared controls executed and honoured in the previous run",
                        "controls"))
        elif core(root, g):   # CORE-ALWAYS
            out.append(("RERUN", g, "the core: its script carries `# CONFIRM: always` (#269)") + ctl(r))
        elif g in stale:
            out.append(("RERUN", g, "STALE: " + stale[g]) + ctl(r))
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
    if a[:1] == ["subfp"] and opt("--root"):
        root = os.path.abspath(opt("--root"))
        for p in submodules(root):
            fp = subfp(root, p)
            if fp:
                print(f"{p} {fp}")
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
