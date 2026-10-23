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
#286 (a) (14z-202, maintainer-ruled 2026-10-15: "(a) is good too"): THE RECORD FILES STOP RE-RUNNING CODE GATES. The
14z-201 close's second tier pass followed a commit of STATE.md and 35 rule-checker run files only and re-ran 135 of
206 gates; most by a MENTION, not a read. Four narrowings, scored on a trace before they land (#225):
  N-B is widened from STATE.md to every `.md` basename (NARROW_R2): `CLAUDE.md`, `DECISIONS_HISTORY.md` and the rest
     are named in messages by dozens of tools (R2 `tests/lib/masked_compare.sh names CLAUDE.md`, 12 gates at 6544c713);
  N-E (R5) a data file names c only where c stands as a PATH: at the start of the text, a line or a field (after a
     tab), after a quote, a backtick, `/`, `,` with no space, `[`, `;` or `; ` — not inside prose (the notes column of
     tests/expected/registry.tsv: "frozen 2026-07-28, STATE.md", 34 gates at c81dc932; tests/ci_emulator.tsv's
     "(maintainer-ruled 2026-10-09, DECISIONS_HISTORY.md ...", 11 at ab89682d); docs/project/tickets.tsv's
     `DECISIONS_HISTORY.md § ...` links stand at a field start and still count;
  N-F a file under tests/rulecheck/runs/ concerns only a reach that names `rulecheck/runs` (every reader of the run
     records does, through its `RUNS` constant): as DATA (R5), the basename `manifest.tsv` in a message made all 1,014
     run manifests data of 15 to 21 gates per pass, and the manifests list STATE.md and DECISIONS_HISTORY.md; as a
     CHANGED path (any rule; N-F-CHANGE), a new run's `manifest.tsv` re-ran every gate whose code names that basename
     (19 gates on the c81dc932 change set);
  N-G (R3) a change under tests/rulecheck/ is not STALE for a gate whose reach names only the bare `tests` directory
     (N-A's form; NARROW_R3_UNDER): the run records and the ledger land there at every close (12 gates, 326 s with
     their controls, at c81dc932); `tests/rulecheck` and deeper still count, and so does the bare `tests` in a reach
     that walks recursively (RECURSIVE: the PILOT trace at 1c59a7cd found test_docshape reading 2,225 files there
     through an `rglob` of `tests`);
  N-H (R4) a walk (`os.walk`, `.rglob`, `glob('**')`, `find .`) is whole-tree only from the repo root (ROOTISH);
     a walk of a named directory is R3's. R7 gains `.gitmodules` (git reads it for every submodule-aware command):
     the trace found test_release_recipe_text reading it, which only the coarse R4 had covered.
  SCORED (14z-202, PILOT, the traces of all 225 gates at 1c59a7cd, the scorer with #283's split lines re-joined): this
     version 0 misses over 84,378 (gate, file read) pairs; the version before #286 (a) 0; the over-narrowed control 59
     misses in 6 gates (fired); a first cut of N-G and N-H 2,226 misses in 2 gates (corrected above). Four gates exited
     non-zero under the trace: test_applier_page and test_applier_page_browser (#280, #281), test_release_roundtrip
     (#279) and test_emulator_staleness (PILOT's own emulator run records are stale). On the 14z-201 close's final-pass
     change set (37 paths): 112 stale gates before, 56 after.
#286 (14z-203): THREE MORE NARROWINGS, NOT YET SCORED ON A TRACE (PILOT and ERIS unavailable; they land only after
the trace of every gate shows 0 misses, #225). mid2's record-only change set (DECISIONS_HISTORY.md, STATE.md,
tests/rulecheck/ledger.tsv) re-ran 44 gates as STALE; the PILOT traces at 1c59a7cd show 31 of them opening none of
the three files.
  N-I (R4) a `git ls-files` with pathspecs lists only them: a glob (`'*.sh'`, `'tools/*.py'`) or a directory
     (`tools tests`); a variable, `.` or a bare listing stays whole-tree. R7's GIT_RUN gains the list form, since a
     scoped listing leaves R4. The scorer judges each read by whole_covers().
  N-J (N-G) the exception holds only for a recursive walk OF the directory: its own line, or the three before it,
     names the directory, and it is not a walk of a cd target or of a subdirectory (walks_dir). Until now any walk
     anywhere in the reach cancelled N-G: tests/lib/shadow_tools.sh only symlinks `tests`.
  N-F without the planner's own text: this file names `rulecheck/runs` in N-F's rule and self-test, so every gate
     reaching the planner was a run-record reader (names_runs; data_files drops this file's text).
  Seen while building them, for the scoring: R3 does not count a quoted `"docs"` in a tuple of directories walked
     through a variable (the g_constwalk fixture is stale for tests/ changes, not for docs/ ones); the 14z-202 trace
     found no gate of that shape for docs, so it is a known gap, not a measured miss.
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
     build/snapshot_runs/, and since #313 (14z-207) build/sheets/ (SCRATCH, generated since #304 from the `scratch` rows of
     tests/expected/build_dirs.tsv) — leaves every gate's change set but the whole-tree readers' (R4): the trace
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
  python3 tools/static_confirm.py plan --root DIR --results FILE [--jobs N]
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
      test_close_tools, test_rule_checker: their inputs move outside the tracked tree; test_close_tools is `ondemand`
      since #288, so a session run defers it whatever its mark, #300), and a gate whose recorded
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
      the gate is absent from the base, not PASS there, its base controls were not all executed, or a PROGRAM in its
      reach changed (R1: its own script, a library it sources, a runner or tool it calls, a module it imports). That
      is where a gate's verdict logic can break, so that is where its controls must prove themselves again. NARROWED
      14z-205 (maintainer-ruled 2026-10-18, the static tier's scope, GitHub #298): until then a direct read of DATA
      (R2 a code line naming the file, R6 a templated path) executed them too; measured on the record of 104 static
      runs (2026-10-02..18), 6,429 session-cadence control executions were all HONOURED, and on the 14z-205 tier-2
      plan the rule cut the gates executing controls from 117 to 17. Otherwise — STALE only by a data or indirect
      rule (R2, R3 a directory it lists, R4 the whole tree, R5 a data file that mentions the path, R6, R7 git's own
      files), or the core with no program of its reach changed —
      `carry-controls<TAB>declared<TAB>fired<TAB>honoured` from the base row: the gate re-runs and its controls are
      carried, as a carried gate's are. Measured 14z-202 (section 22 of tests/test_static_runner.sh): a data file a
      gate reads with `cat` is R2, not R1 — the reach holds programs only. A freeze and a release execute every
      control (--confirm is refused there).
  THE CADENCE'S @code TRIGGER (14z-205, #297, maintainer-ruled 2026-10-18 "Own code changed"): `reach --root R g...`
      prints each gate's reach (the same closure R1 reads), one `gate<TAB>program` per line; tests/run_all_static.sh
      reads it for every tests/ci_cadence.tsv row whose triggers are `@code`, so such a gate is pulled back into a
      session run exactly when a program of its own reach changed, never by a data change.
  THE PLAN'S COST (#259, 14z-204): `plan` prints its progress every 25 gates and a closing timing line on stderr, which
      tests/run_all_static.sh shows as it runs (the 14z-195 close's plan ran 20 min 22 s silent). R5 searches each data
      basename once per gate and lists the data files once per root, and battery_reach's module lookup is memoised:
      measured on the 14z-195 close's change set (79bb33c9..23a56fc8, 228 paths, in a worktree of 23a56fc8) 167 s -> 49 s,
      one changed path 21 s -> 13 s, and a plan of this tree from the 14z-203 close's results 3 min 39 s -> 52 s; the
      output byte-identical in each. The 194 rule-checker run files of that change set cost nothing as CHANGED paths,
      before this change too (36 paths without them: 171 s on the old planner); what cost was R5 searching each run
      record reader's blob once per run file, i.e. their presence as tracked data.
  A LARGE UNTRACKED TREE (#313, 14z-207): the 14z-206 commit tier's plan judged 25 of 229 gates in 1,902 s against
      23,803 changed paths, 20,271 of them #291's proof sheets under build/sheets/, and ran into its 2 h timeout. Two
      changes. build/sheets/ joins N-D's scratch (tools/proof_sheets.py writes it; no static gate opens a file under
      it: the PILOT trace of all 229 gates at 1a2210f6, with a 23,552-name replica of the 8b82d5d247c6 sheet tree
      present, scored 0 misses over 88,235 reads and its over-narrowed control 102; the one gate that touched the tree,
      test_emulator_staleness, opened its directories only, git's untracked walk, and is an R4 reader). And the
      per-path work is bounded, with
      every rule unchanged: R2/R5 and R3 search only where a test NECESSARY for a hit passes, a directory's R3 verdict
      is kept per reach, R6 asks one alternation first, and R4's scopes are read once per text (see `may_name`); the
      selftest's g_bound cases require the reference's verdict and reason (BOUND off) path by path.
  THE PLAN'S LISTING, ORDER, WORKERS AND BUDGET (#304, 14z-207; maintainer-ruled 2026-10-23, "Adopt all four
      (Recommended)", build/agent207/t304/recommendation.md). ONE LIST: build/'s top-level directories are classed in
      tests/expected/build_dirs.tsv (tools/build_dirs.py, census tests/test_build_dirs.sh); N-D's SCRATCH and the pruned
      listing's pathspecs are both generated from its scratch rows (written twice, the regex and the glob disagreed on
      build/agent7-x/, build/agent207/t304/recheck/plant_prune.txt). PRUNED LISTING: `git ls-files --others` runs with
      the scratch excluded (the #304 analysis on this Mac: 0.3-0.4 s against 26.5-26.9 s, build/agent207/t304/
      snapsteps.txt); the scratch a
      whole-tree reader (R4) still needs is found by ScratchChanges, exactly as the full listing gave it, asked last and
      lazily, newest directory first. TRACKED FIRST: tracked and dirty paths are judged before untracked ones; a STALE
      verdict does not depend on the order, only the reason shown can. WORKERS: the gate loop runs in PLAN_JOBS forked
      workers once the read caches are warm, with the serial verdicts. BUDGET: the plan prints its changed paths by
      prefix and refuses (exit 3) past PLAN_BUDGET effective untracked paths or PLAN_TIME_LIMIT seconds; the runner
      then stops with "the plan FAILED", a fault instead of a hang. The selftest's plan cases A-E hold each on a git repo.
  python3 tools/static_confirm.py subfp --root DIR
      one line `<path> <fingerprint>` per initialised submodule of DIR (#286 (b)).
  python3 tools/static_confirm.py --selftest
      a synthetic repo of five gates, one per reader class, with known answers.
"""
import os, re, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import battery_reach as br   # noqa: E402

_WHOLE_COARSE = re.compile(r"git\s+(?:ls-files|grep|status)\b|os\.walk\(|\.rglob\(|\bfind\s+\.(?:\s|$)|glob\.glob\([^)]*\*\*"
                   # R4 in LIST form (14z-200, #274: tools/entropy_tripwire.py's ["git", "-C", root, "ls-files", ...] was
                   # unseen, 15,013 traced reads missed in test_entropy_tripwire)
                   r"|[\"']git[\"']\s*,\s*(?:[\"']-C[\"']\s*,\s*[^,\n]+,\s*)?[\"'](?:ls-files|grep|status)[\"']")
# N-H (#286 (a), 14z-202): a walk counts as the WHOLE tree only when it starts at the repo root. `os.walk(src)`,
# `(root / "docs").rglob(`, `Path(args[0]).rglob(` and `cd "$1" && find .` read one directory, which R3 covers when the
# code names it; 38 of the 68 gates the c81dc932 change set left stale were R4 hits of this kind. The git forms
# (`git ls-files|grep|status`) stay whole-tree readers.
ROOTISH = (r"(?<![\w.])(?:root|ROOT|REPO|repo|REPO_ROOT|\"\.\"|'\.'|(?:pathlib\.)?Path\(\s*[\"']\.[\"']\s*\)"
           r"|(?:pathlib\.)?Path\.cwd\(\)|os\.getcwd\(\)|os\.curdir)")


class _Whole:
    """R4's test: `search(text)` is truthy when the text reads the whole tree (N-H applied); `scopes(text)` says how
    much of it (N-I)."""
    @staticmethod
    def _hit(t, m):
        """one _WHOLE_COARSE hit: None if it is no whole-tree read (N-H), else the set of scopes it covers"""
        hit = m.group(0)
        if hit.startswith("os.walk("):   # N-H
            return {ALL} if re.match(r"\s*" + ROOTISH + r"\s*[,)]", t[m.end():]) else None
        if hit == ".rglob(":
            return {ALL} if re.search(ROOTISH + r"\s*\)?\s*$", t[max(0, m.start() - 60):m.start()]) else None
        if hit.startswith("find"):
            return None if re.search(r"\bcd\s", t[t.rfind("\n", 0, m.start()) + 1:m.start()]) else {ALL}
        if hit.startswith("glob.glob("):
            ok = re.match(r"glob\.glob\(\s*(?:os\.path\.join\(\s*" + ROOTISH + r"\s*,\s*)?[\"']\*\*", hit)
            return {ALL} if ok else None
        if "ls-files" in hit:   # N-I (14z-203, #286): a pathspec narrows a listing to what it names
            return _lsf_scopes(t, m)
        return {ALL}   # git grep / git status

    def search(self, t):
        return any(ALL in (self._hit(t, m) or ()) for m in _WHOLE_COARSE.finditer(t)) or bool(self.scopes(t))

    def scopes(self, t):
        """None when the text reads no whole tree; a set holding ALL for an unscoped read; otherwise the pathspecs
        its `git ls-files` lists (a directory, or a glob such as `*.sh`). Cached per text (#313: whole_covers asked
        it once per CHANGED PATH, a scan of the whole reach each time)"""
        k = hash(t)
        if k not in _SCOPES:
            out = set()
            for m in _WHOLE_COARSE.finditer(t):
                out |= self._hit(t, m) or set()
            _SCOPES[k] = frozenset(out) or None
        return _SCOPES[k]


_SCOPES = {}


ALL = "*ALL*"
_LSF_ITEM = re.compile(r"\s*,\s*(?:([\"'])(.*?)\1|([^,\])\s]+))")


def _lsf_scopes(t, m):
    """N-I: the pathspecs after one `git ls-files` hit, or {ALL} when there is none, or one the text cannot fix
    (a variable, `.`, a substitution): over-approximate, as R4 always was"""
    specs = []
    if m.group(0).rstrip().endswith(("\"ls-files\"", "'ls-files'")):   # list form: ["git", ..., "ls-files", "a", B]
        i = m.end()
        while True:
            n = _LSF_ITEM.match(t, i)
            if not n:
                break
            i = n.end()
            if n.group(3) is not None:
                return {ALL}   # an unquoted item: a variable the text does not fix
            specs.append(n.group(2))
    else:   # shell form: the rest of the command
        end = len(t)
        for ch in "\n|;&)>`#":
            k = t.find(ch, m.end())
            if k != -1:
                end = min(end, k)
        seg = t[m.end():end]
        try:
            import shlex
            specs = shlex.split(seg)
        except ValueError:
            return {ALL}
    out = set()
    for a in specs:
        if a.startswith("-"):
            continue   # an option: --others, -z, -x … none widens beyond the pathspecs
        if any(ch in a for ch in "$`{") or a.strip("/") in ("", ".", "*") or re.fullmatch(ROOTISH, a):
            return {ALL}
        out.add(a.rstrip("/"))
    return out or {ALL}


def whole_covers(blob, c):
    """N-I: does the reach's whole-tree reading cover the changed path c? (R4, per path)"""
    import fnmatch
    sc = WHOLE.scopes(blob)
    if not sc:
        return False
    if ALL in sc:
        return True
    for s_ in sc:
        if any(ch in s_ for ch in "*?["):
            if fnmatch.fnmatch(c, s_):
                return True
        elif c == s_ or c.startswith(s_ + "/"):
            return True
    return False


WHOLE = _Whole()
# N-G's exception (14z-202, the PILOT trace at 1c59a7cd: test_docshape's citation check walks `tests` with `rglob` and
# reads 2,225 files under tests/rulecheck/): a reach that walks a directory recursively reads what lies under it
# (a `find` with a path or option after it, not the English word; `**` inside a quoted glob, not markdown bold)
RECURSIVE = re.compile(r"os\.walk\(|\.rglob\(|\bfind\s+(?:[.\"'$/~]|[\w./-]+\s+-(?:type|name|path|maxdepth|print))"
                       r"|[\"'/]\*\*(?:[/\"']|$)|recursive\s*=\s*True|\bls\s+-[a-zA-Z]*R")
_TEXT = {}


def walks_dir(root, rch, d):
    """N-J (14z-203, #286): N-G's exception holds only for a recursive walk that can reach the directory d, judged
    walk by walk. A walk of a `cd` target on its line (N-H's rule for `find`) or of a literal subdirectory of d
    (`"tests", "replays"`, `tests/replays`) does not reach it; a walk whose line names d does; a walk of a variable
    (`for d in CITATION_DIRS: ... rglob`) does when its file names d anywhere — the safe side, since the variable's
    value is not read. Until 14z-203 any walk anywhere in the reach cancelled N-G: mid2's ledger re-runs reached a bare
    `tests` through tests/lib/shadow_tools.sh, which only symlinks it, while another file walked `$1` or tests/replays.
    (A first cut judged a variable walk by the three lines before it and dropped test_docshape, which reads 2,225 files
    under tests/rulecheck/ through CITATION_DIRS: the 14z-202 trace's miss, caught by the session before scoring.)"""
    bare = re.compile(r"(?<![\w.-])" + re.escape(d) + r"(?![\w-])")
    sub = re.compile(r"(?<![\w.-])" + re.escape(d) + r"(?:\s*/\s*[\w$]|[\"']\s*,\s*[\"']\w|[\"']\s*\)\s*/\s*[\"']\w)")
    for p in rch:
        t = text(root, p)
        for m in RECURSIVE.finditer(t):
            a = t.rfind("\n", 0, m.start()) + 1
            b = t.find("\n", m.end()); b = len(t) if b == -1 else b
            line = t[a:b]
            if re.search(r"\bcd\s", t[a:m.start()]):
                continue   # the walk of a cd target
            if bare.search(line):
                if sub.search(line) and len(bare.findall(line)) == len(sub.findall(line)):
                    continue   # every mention on its line is of a subdirectory: a walk of that subdirectory
                return True   # its line names d itself
            if bare.search(t):
                return True   # a walk of a variable, in a file that names d
    return False


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
class _NarrowR2(tuple):
    """N-B's basenames: STATE.md (14z-190) and, since #286 (a), every `.md` basename."""
    def __contains__(self, b):
        return tuple.__contains__(self, b) or str(b).endswith(".md")   # N-B-MD


NARROW_R2 = _NarrowR2(("STATE.md",))   # N-B: R2 for these basenames ignores a mention inside a prose string
NARROW_R3_UNDER = (("tests/rulecheck/", 1),)   # N-G: under this prefix, directory depths <= 1 (bare `tests`) do not count
RUNS_DATA = "tests/rulecheck/runs/"   # N-F: data files here count only for a reach that names `rulecheck/runs`


def names_runs(root, rch):
    """N-F's test, since 14z-203 (#286) without the planner's own text: tools/static_confirm.py names `rulecheck/runs`
    in N-F's rule and its self-test, which made every gate reaching the planner (test_emulator_staleness, the gate
    indexes, the static runner) a reader of the 1,000+ run records on every new run"""
    return any("rulecheck/runs" in text(root, p) for p in rch if p != "tools/static_confirm.py")
DATA_PATH_PRE = "\t\n\"'`/,[;"   # N-E: the characters a PATH mention may follow in a data file
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
# N-K (14z-207, #286): a python program fed to python3 from a shell HEREDOC is python, so N-C's bare clause skips it as
# it skips a .py file: tests/test_tenant_loop.sh's `docs = []` (in `python3 - <<'PY' ... PY`) made 7 gates readers of
# docs/, and tests/test_manifest_merge.sh's `docs = load(...)` one more (lane F's record-only tier on PILOT, 14z-207:
# all 8 open no file under docs/). The shell lines around the heredoc still count; only the body between the opener
# and its terminator line leaves the BARE haystack (the lit and join forms still search the whole text).
PY_HEREDOC = re.compile(r"^([^\n#]*\bpython3?\b[^\n]*<<-?[ \t]*(['\"]?)(\w+)\2[^\n]*\n)(.*?)(^[ \t]*\3[ \t]*$)",
                        re.M | re.S)
NARROW_HEREDOC = True
_SHPY = {}


def shell_code(t):
    """N-K: a shell text with the BODIES of its python heredocs removed, cached per text"""
    k = hash(t)
    if k not in _SHPY:
        _SHPY[k] = PY_HEREDOC.sub(lambda m: m.group(1) + m.group(5), t) if NARROW_HEREDOC else t
    return _SHPY[k]


def r3_text(root, p):
    """N-C and N-K: one non-python file of the reach as R3's bare clause reads it"""
    t = text(root, p)
    return deprose(shell_code(t) if p.endswith(".sh") else t)


def r3_blob(root, rch, blob):
    """N-C: the reach's non-python code with every prose string removed — where a BARE directory token counts"""
    k = (root, hash(blob))
    if k not in _R3B:
        _R3B[k] = "\n".join(r3_text(root, p) for p in rch if not p.endswith(".py"))
    return _R3B[k]


# N-D: untracked scratch the session tooling writes under build/ is not an input of any static gate; build/sheets/,
# tools/proof_sheets.py's pages and its clean checkouts, since #313 (14z-207)
# GENERATED from tests/expected/build_dirs.tsv's scratch rows (#304, 14z-207): the one list classing build/'s top
# directories; the pruned listing's pathspecs come from the same rows (build_dirs.pathspecs), so the two never disagree
import build_dirs   # noqa: E402
BUILD_DIRS = build_dirs.load()
SCRATCH = build_dirs.scratch_regex(BUILD_DIRS)


def drop_scratch(c):
    return bool(SCRATCH.match(c))


def narrow_search(base, t):
    """N-B: does t name `base` as a quoted literal or path component, or outside every prose string?"""
    e = re.escape(base)
    lit = re.search(r"(?<=[\"'/])" + e + r"(?![\w-])", t)   # N-B literal clause
    return bool(lit or re.search(r"(?<![\w.-])" + e + r"(?![\w-])", deprose(t)))


JOINED_LIT = r"(?![\"']\s*[,/]\s*[\"'][^\"'{}$*%\n]*[\"'])"   # N-C: `"tools", "x.py"` / `"docs" / "a.txt"` name a FILE


_DIRPATS = {}


def dir_patterns(c):
    """-> [(dir, kind, regex)]: kind `bare` (searched on deprosed non-python text), `lit` (a quoted or `/`-led
    token, searched on every text) or `join` (quoted components joined by `,` or `/`, every text). Depends on c's
    directory only, so compiled once per directory (#313: 23,552 sheet files in 3,412 directories)."""
    k = c.rsplit("/", 1)[0] if "/" in c else ""
    if k not in _DIRPATS:
        _DIRPATS[k] = _dir_patterns(c)
    return _DIRPATS[k]


def _dir_patterns(c):
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
GIT_RUN = re.compile(r"(?<![\w.-])git\s+(?:-C\s+\S+\s+)?[a-z][\w-]*"
                     r"|[\"']git[\"']\s*,\s*[\"']")   # and the list form ["git", ...] (N-I, 14z-203: a scoped
                     # listing leaves R4, so R7 must see a list-form git user itself)
TOKEN = re.compile(r"[\w./${}*%<>-]+")
PLACE = re.compile(r"\$\{\w+\}|\$\w+|\{[^{}/]*\}|%[sd]|\*")


# #313 (14z-207): THE PER-PATH WORK IS BOUNDED. `predict` judges every changed path against every gate, so an
# untracked tree of 20,271 files (#291's proof sheets under build/sheets/, 14z-206) planned 25 gates in 1,902 s. The
# rules are unchanged; each per-path search is answered from a per-reach cache or ruled out by a test that is
# NECESSARY for a hit, and only a path that passes it is searched as before, so every verdict and reason is the one
# the uncached planner gives (selftest g_bound; the before/after comparison in the issue):
#   R2 and R5 (N-E): a basename made only of [\w.-] can match `(?<![\w.-])base(?![\w-])`, or stand at a path position
#      of a data file, only at the START of a maximal [\w.-] run of the text (the character before it is outside the
#      class), so it is a PREFIX of one of the text's runs (may_name: one bisect in the sorted runs);
#   R3 and R3c: a directory's verdict for a reach depends on the directory, not on the file under it (memo per reach
#      and pattern; N-G's test, which reads the path, is applied before the memo as before); and every R3 form of a
#      directory `a/b/.../name` (bare, lit, shell default, quoted join) puts each component after the first between
#      `/` or a quote and a `/`, a quote, a space or a closing bracket, so a hit needs each of them to be a WHOLE
#      maximal [\w.-] run of the text searched (has_run; R3c's sibling `name` likewise; a directory with no `/` is
#      searched as before);
#   R6: one alternation of the reach's templates says whether ANY matches; the first is then found as before.
# BOUND = False is the reference (every prefilter and memo off): the selftest's g_bound cases require the same verdict
# and reason from both, path by path.
BOUND = True
CLASS_RUN = re.compile(r"[\w.-]+")
_RUNS = {}


def may_name(t, base):
    """#313: False only when no R2 basename match and no N-E path-position mention of `base` in t is possible"""
    if not BOUND or not CLASS_RUN.fullmatch(base):
        return True   # a character outside the class: no shortcut, the search decides
    k = hash(t)
    if k not in _RUNS:
        _RUNS[k] = sorted(set(CLASS_RUN.findall(t)))
    import bisect
    r = _RUNS[k]
    i = bisect.bisect_left(r, base)
    return i < len(r) and r[i].startswith(base)


_RUNSET = {}


def has_run(t, name):
    """#313: False only when `name` (a directory component after the first) cannot be a whole maximal [\\w.-] run
    of t"""
    if not BOUND or not CLASS_RUN.fullmatch(name):
        return True
    k = hash(t)
    if k not in _RUNSET:
        _RUNSET[k] = frozenset(CLASS_RUN.findall(t))
    return name in _RUNSET[k]


_R3MEMO = {}
_TANY = {}


def _tmpl_any(root, blob):
    """#313: (path alternation, basename alternation) of the reach's R6 templates, or None for an empty side"""
    k = (root, hash(blob))
    if k not in _TANY:
        tm = templates(root, blob)
        alt = lambda xs: re.compile("|".join("(?:%s)" % rx.pattern for rx in xs)) if xs else None
        _TANY[k] = (alt([rx for rx, _, p in tm if p]), alt([rx for rx, _, p in tm if not p]))
    return _TANY[k]


def data_names(t, c, bpat):
    """N-E (#286 (a)): does the data text t name c as a PATH — by path or by basename, at the start of t, a line or a
    field, or after one of DATA_PATH_PRE or `; ` — rather than inside prose?"""
    hits = [m.start() for m in re.finditer(re.escape(c), t)]
    if bpat:
        hits += [m.start() for m in bpat.finditer(t)]
    for i in hits:
        if i == 0 or t[i - 1] in DATA_PATH_PRE or (t[i - 1] == " " and i > 1 and t[i - 2] == ";"):
            return True
    return False


def data_files(root, blob):
    """R5: the tracked data files the reach's code names, by path or basename (one scan per blob, ONE SEARCH PER
    BASENAME: #259, 14z-204 — on the 14z-195 close's change set the run-record readers searched their blob once per
    run file, 3,750 times for 7 basenames; 36,023 whole-blob searches over the registry, 124 of the plan's 179 s)."""
    k = (root, hash(blob))
    if k not in _DATA:
        out, named = [], {}
        pl = text(root, "tools/static_confirm.py") if os.path.exists(os.path.join(root, "tools/static_confirm.py")) else ""
        runs_reader = "rulecheck/runs" in (blob.replace(pl, "") if pl else blob)   # N-F, without the planner's own text; once per blob (#259)
        for f in _data_tracked(root):
            if f.startswith(RUNS_DATA) and not runs_reader:   # N-F
                continue
            b = os.path.basename(f)
            if b not in named:
                named[b] = b in blob and re.search(r"(?<![\w.-])" + re.escape(b) + r"(?![\w-])", blob) is not None
            if named[b]:
                out.append(f)
        _DATA[k] = out
    return _DATA[k]


_TRACKED = {}
_DATAF = {}


def _data_tracked(root):
    """the tracked data files (DATA_EXT), listed once per root (#259)"""
    if root not in _DATAF:
        _DATAF[root] = [f for f in _tracked(root) if f.endswith(DATA_EXT)]
    return _DATAF[root]


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
    if bpat and may_name(blob, base) and bpat.search(blob):   # #313: may_name rules a miss out first
        where = next((p for p in rch if bpat.search(text(root, p))), "?")
        return f"R2 {where} names {base}"
    kb = (root, hash(blob))
    if not BOUND:   # #313: the reference judges every path afresh
        _R3MEMO.clear()
    for d in [x for x, _, _ in dps if "/" in x]:   # R3c (14z-200, #274): os.path.join(HERE, "applier") beside it
        mk = kb + ("R3c", d)   # #313: per directory, not per file
        if mk not in _R3MEMO and not has_run(blob, d.rsplit("/", 1)[1]):
            _R3MEMO[mk] = None
        if mk not in _R3MEMO:
            par, name = d.rsplit("/", 1)
            sib = re.compile(r"(?<=[\"'])" + re.escape(name) + r"/?(?=[\"'])" + JOINED_LIT)
            _R3MEMO[mk] = next((f"R3 {p} reads its sibling directory {d}" for p in rch
                                if os.path.dirname(p) == par and sib.search(text(root, p))), None)
        if _R3MEMO[mk]:
            return _R3MEMO[mk]
    for d, kind, rx in dps:   # N-C: R3 by kind; a bare token counts only outside python and outside prose
        if (any(c.startswith(pre) and d.count("/") + 1 <= n for pre, n in NARROW_R3_UNDER)
                and not walks_dir(root, rch, d)):   # N-G, N-J
            continue
        mk = kb + (kind, rx.pattern)   # #313: per directory pattern, not per file
        if mk not in _R3MEMO:
            hay = r3_blob(root, rch, blob) if kind == "bare" else blob
            where = None
            if all(has_run(hay, x) for x in d.split("/")[1:]) and rx.search(hay):
                if kind == "bare":
                    where = next((p for p in rch if not p.endswith(".py") and rx.search(r3_text(root, p))), "?")
                else:
                    where = next((p for p in rch if rx.search(text(root, p))), "?")
            _R3MEMO[mk] = where and f"R3 {where} reads directory {d}"
        if _R3MEMO[mk]:
            return _R3MEMO[mk]
    base = os.path.basename(c)
    for d in data_files(root, blob):
        if d == c:
            continue
        t = text(root, d)
        if not may_name(t, base):   # #313: no path-position mention is possible
            continue
        if (c in t or (bpat and base in t)) and data_names(t, c, bpat):   # N-E
            return f"R5 the data file {d} names {c}"
    pany, bany = _tmpl_any(root, blob)   # #313: one search says whether any template matches
    tany = not BOUND or (pany and pany.search(c)) or (bany and bany.search(base))
    for rx, tok, is_path in templates(root, blob):
        if not tany:
            break
        if rx.search(c if is_path else base):
            return f"R6 the template {tok} matches {c}"
    if base in (".gitignore", ".gitattributes", ".gitmodules") and GIT_RUN.search(blob):
        return f"R7 the reach runs git, which reads {c}"
    return None


# predict()'s judgment of one gate for one changed path, in three parts it calls and tools/trace_static_reads.py
# calls too (14z-206, #286): the scorer judged each traced read by stale_reason alone and never applied N-F-CHANGE, so a
# run-record read the predictor carries was invisible to it (rule-checker run 2026-10-20-1156).
def runs_reader(root, rch, blob):
    """N-F-CHANGE's test, once per gate: does the reach name `rulecheck/runs`, the planner's own text aside?"""
    return names_runs(root, rch)


def run_link(root, blob, c):
    """N-F-LINK (14z-206, #286): a run record a DATA file of the reach names by its whole PATH, at a path position
    (N-E), is read through that file although the reach's code never names `rulecheck/runs`. test_tickets resolves
    every link of docs/project/tickets.tsv (tools/tickets.py Tree.link_error), and row 156 links
    tests/rulecheck/runs/2026-09-17-22/verdict_real.txt: the PILOT trace at b91532d8 saw it opened, and N-F-CHANGE
    carried it (the narrowed N-F and the committed one alike). A basename alone never counts: that is N-F-CHANGE's
    manifest.tsv."""
    for f in data_files(root, blob):
        t = text(root, f)
        if f != c and c in t and data_names(t, c, None):
            return f"R5 the data file {f} links the run record {c} (N-F-LINK)"
    return None


def change_reason(root, rch, blob, c, pats, reader):
    """the rule that makes this gate STALE for the changed path c, R4 aside (whole_covers): none for the session
    scratch (N-D) or for a run record when the reach reads none (`reader`, runs_reader's answer), else stale_reason's"""
    if drop_scratch(c):   # N-D
        return None
    if c.startswith(RUNS_DATA) and not reader:   # N-F-CHANGE
        return run_link(root, blob, c)   # N-F-LINK
    return stale_reason(root, rch, blob, c, pats)


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
_MODS = {}


def _cached_resolve(orig):
    def resolve_mod(name, files):
        k = (id(files), name)
        if k not in _MODS:
            _MODS[k] = (files, orig(name, files))   # the list is held, so its id is not reused while cached
        return _MODS[k][1]
    return resolve_mod


br.resolve_mod = _cached_resolve(br.resolve_mod)   # #259: one index scan per module name, not per import (2,549 scans, 10.7 s of a one-path plan's 21 s, 14z-204)


def covers(sc, c):
    """whole_covers on a reach's R4 scopes (WHOLE.scopes), without its text: what the plan asks of a gate's R4 after
    its worker has returned (#304)"""
    import fnmatch
    if not sc:
        return False
    if ALL in sc:
        return True
    for s_ in sc:
        if any(ch in s_ for ch in "*?["):
            if fnmatch.fnmatch(c, s_):
                return True
        elif c == s_ or c.startswith(s_ + "/"):
            return True
    return False


class PlanRefused(Exception):
    """#304 (d): the plan stops with its reason instead of running into the runner's timeout"""


_CTX = {}


def _judge(g):
    """one gate's verdict over the non-scratch change set, in a worker or inline: (gate, reason or None, R1 flag, the
    reach's R4 scopes, and each reach file's own scopes in reach order — what R4 needs, without the text)"""
    root, files, pats, eff = _CTX["root"], _CTX["files"], _CTX["pats"], _CTX["eff"]
    rch = reach(root, g, files)
    blob = "\n".join(text(root, p) for p in rch)
    reader = runs_reader(root, rch, blob)
    why = None
    for c in eff:
        why = change_reason(root, rch, blob, c, pats[c], reader)
        if why:
            break
    per = [(p, WHOLE.scopes(text(root, p))) for p in rch]
    return g, why, any(c in rch for c in eff), WHOLE.scopes(blob), [x for x in per if x[1]]


def predict(root, changed, r1=None, progress=None, scratch=(), jobs=1, deadline=None, tracked=None):
    """the STALE map; when `r1` is a dict, r1[gate] is set, for a STALE gate, to whether a PROGRAM in its reach
    changed (R1: its own script, a script it sources or runs, a module it imports; 14z-205, narrowing #286 (c)); `progress(done, total)` is called every 25 gates and at the end
    (#259: the 14z-195 close's plan ran 20 min silent, which looks the same as a hang).
    #304 (14z-207): `scratch` holds more changed scratch paths, read by R4 alone and asked last and lazily (plan's
    ScratchChanges: the pruned listing leaves them out); `tracked` is the tracked change set, judged first (the
    verdict cannot depend on the order, only the reason shown can); `jobs` > 1 judges the gates in that many forked
    workers once the read caches are warm; past `deadline` (time.monotonic()) the plan is refused (PlanRefused)."""
    import time
    files = br.index(root, [])
    gates = registry(root)
    pats = {c: patterns(c) for c in changed}
    stale, carried = {}, []
    # N-D: the session tooling's scratch under build/ is judged by R4 alone (a whole-tree reader lists it); measured
    # 14z-200 on the trace at 6e329411 with the scratch present: no gate opened a file under it
    eff = [c for c in changed if not drop_scratch(c)]
    if tracked is not None:   # TRACKED-FIRST (#304 (b))
        eff = [c for c in eff if c in tracked] + [c for c in eff if c not in tracked]
    _CTX.update(root=root, files=files, pats=pats, eff=eff)

    def late():
        if deadline is not None and time.monotonic() > deadline:
            raise PlanRefused(f"the plan ran past its time limit, {PLAN_TIME_LIMIT} s ({len(changed)} changed paths)")
    results = []
    if jobs > 1 and len(gates) > 1:   # PLAN-JOBS (#304 (c)): caches warmed here, shared with the workers by fork
        import multiprocessing as mp
        _tracked(root)
        _data_tracked(root)
        pool = mp.get_context("fork").Pool(jobs)
        try:
            it = pool.imap(_judge, gates, chunksize=1)
            for n in range(1, len(gates) + 1):
                while True:
                    try:
                        results.append(it.next(timeout=5))
                        break
                    except mp.TimeoutError:
                        late()
                late()
                if progress and (n % 25 == 0 or n == len(gates)):
                    progress(n, len(gates))
        finally:
            pool.terminate()
            pool.join()
    else:
        for n, g in enumerate(gates, 1):
            results.append(_judge(g))
            late()
            if progress and (n % 25 == 0 or n == len(gates)):
                progress(n, len(gates))
    for g, why, prog, sc, per in results:
        if not why and sc and (any(covers(sc, c) for c in changed) or any(covers(sc, c) for c in scratch)):
            # N-I: per changed path; the scratch R4 alone judges is asked last, and lazily (#304 (a))
            where = next((p for p, s_ in per if any(covers(s_, c) for c in changed)
                          or any(covers(s_, c) for c in scratch)), "?")
            psc = dict(per).get(where) or ()
            why = f"R4 {where} reads the whole tree" if ALL in psc else f"R4 {where} lists {' '.join(sorted(psc))}"
        if why:
            stale[g] = why
            if r1 is not None:   # PROGRAM-CHANGED (14z-205, ruled 2026-10-18): R1 alone, a program in the reach
                r1[g] = prog
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
                _TEXT.clear(); _REFS.clear(); _DATA.clear(); _TMPL.clear(); _TRACKED.clear(); _DATAF.clear(); _MODS.clear()
                _SCOPES.clear(); _RUNS.clear(); _RUNSET.clear(); _R3MEMO.clear(); _TANY.clear(); _DIRPATS.clear()   # #313
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
          "g_prose\ng_pyident\ng_pyfile\ng_casepat\ng_pylist\ng_pydeep\ng_gitlist\ng_sib\ng_shdef\n"
          "g_mdmsg\ng_mdread\ng_reg\ng_mani\ng_maniruns\ng_cdfind\ng_walksub\ng_walkroot\ng_testswalk\ng_testslink\n"
          "g_lsglob\ng_lsdir\ng_lsvar\ng_cdwalk\ng_subwalk\ng_planner\ng_constwalk\ng_runlink\ng_dotend\n"
          "g_pyheredoc\ng_shdocs\n")
        w("tests/g_testswalk.sh", "#!/bin/sh\npython3 tools/testswalk.py\n", True)
        w("tests/g_testslink.sh", "#!/bin/sh\necho \"a copy would **not** find the tests otherwise\"\nls tests > /dev/null\n", True)
        w("tools/testswalk.py", "import pathlib\nfor d in (\"tests\",):\n    for p in sorted((pathlib.Path('.') / d).rglob('*')):\n        pass\n")
        # N-H: a find after a cd, and a walk of a named subdirectory, are not whole-tree reads; a walk of root is
        w("tests/g_cdfind.sh", "#!/bin/sh\n( cd \"$1\" && find . -type f | sort ) > /dev/null\n", True)
        w("tests/g_walksub.sh", "#!/bin/sh\npython3 tools/walksub.py\n", True)
        w("tools/walksub.py", "import os, sys\nsrc = sys.argv[1]\nfor d, _, fs in os.walk(src):\n    pass\n")
        w("tests/g_walkroot.sh", "#!/bin/sh\npython3 tools/walkroot.py\n", True)
        w("tools/walkroot.py", "import os\nroot = '.'\nfor d, _, fs in os.walk(root):\n    pass\n")
        # #286 (a): N-B on every .md (a message vs a read); N-E (a data file's prose mention vs a path); N-F (a run
        # manifest named by basename only vs a reader of the runs); N-G (a bare `tests` lister vs a run record)
        w("tests/g_mdmsg.sh", "#!/bin/sh\necho \"the rule is in CLAUDE.md, read it\"\n", True)
        w("tests/g_mdread.sh", "#!/bin/sh\ngrep -c rule CLAUDE.md\n", True)
        w("CLAUDE.md", "x\n")
        w("tests/g_reg.sh", "#!/bin/sh\npython3 -c \"print(open('lists/reg.tsv').read())\"\n", True)
        w("lists/reg.tsv", "a\tfrozen 2026-07-28, notes/ruled.md\nnotes/listed.md \u00a7 Ruled x ; notes/second.md \u00a7 y\n")
        w("tests/g_mani.sh", "#!/bin/sh\necho \"each run keeps a manifest.tsv\" > /dev/null; ls manifest.tsv 2>/dev/null\n", True)
        w("tests/g_maniruns.sh", "#!/bin/sh\nfor m in tests/rulecheck/runs/*/manifest.tsv; do cat \"$m\"; done\n", True)
        w("tests/rulecheck/runs/2026-01-01-01/manifest.tsv", "notes/man.md\tabc\n")
        w("notes/man.md", "x\n")
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
        # N-I (14z-203, #286): a pathspec narrows a listing; a variable pathspec does not
        w("tests/g_lsglob.sh", "#!/bin/sh\ngit ls-files '*.sh' | while read f; do :; done\n", True)
        w("tests/g_lsdir.sh", "#!/bin/sh\npython3 tools/lsdir.py\n", True)
        w("tools/lsdir.py", "import subprocess\nsubprocess.run([\"git\", \"ls-files\", \"docs/game\"])\n")
        w("tests/g_lsvar.sh", "#!/bin/sh\ngit ls-files $PATHS | wc -l\n", True)
        # N-J (14z-203): a bare `tests` lister whose other walk is of a cd target, or of a subdirectory, keeps N-G
        w("tests/g_cdwalk.sh", "#!/bin/sh\nls tests > /dev/null\n( cd \"$1\" && find . -type f | sort ) > /dev/null\n", True)
        w("tests/g_subwalk.sh", "#!/bin/sh\nls tests > /dev/null\npython3 tools/subwalk.py\n", True)
        w("tools/subwalk.py", "import os\nroot = '.'\nfor d, _, fs in os.walk(os.path.join(root, \"tests\", \"replays\")):\n    pass\n")
        # N-J: a walk of a directory constant defined far from it (test_docshape's CITATION_DIRS) still reaches tests
        w("tests/g_constwalk.sh", "#!/bin/sh\npython3 tools/constwalk.py\n", True)
        w("tools/constwalk.py", "import pathlib\nDIRS = (\"docs\", \"tests\")\n\n\n\n\n\ndef f():\n    for d in DIRS:\n"
          "        for p in sorted((pathlib.Path('.') / d).rglob('*')):\n            pass\n")
        # N-F (14z-203): the planner's own text naming rulecheck/runs does not make its callers run-record readers
        w("tests/g_planner.sh", "#!/bin/sh\npython3 tools/static_confirm.py plan > /dev/null; ls manifest.tsv 2>/dev/null\n", True)
        w("tools/static_confirm.py", "RUNS = 'tests/rulecheck/runs/'\n")
        # N-F-LINK (14z-206): test_tickets' shape — a data file whose row links one run record by path; its basename
        # alone (a second run's verdict.txt) is no link
        w("tests/g_runlink.sh", "#!/bin/sh\ncat lists/links.tsv > /dev/null\n", True)
        w("lists/links.tsv", "id\tlink\n1\ttests/rulecheck/runs/2026-01-01-01/verdict.txt\n")
        w("tests/rulecheck/runs/2026-01-01-01/verdict.txt", "Q1 HOLDS\n")
        # N-K (#286, 14z-207): a python heredoc's `docs = []` is python, not a shell read of docs/ (test_tenant_loop's
        # shape); a shell `ls docs` after a heredoc still reads it
        w("tests/g_pyheredoc.sh", "#!/bin/sh\npython3 - \"$1\" <<'PY' || exit 1\nimport sys\ndocs = []\nprint(len(docs))\nPY\n", True)
        w("tests/g_shdocs.sh", "#!/bin/sh\npython3 - <<'PY'\nx = 1\nPY\nls docs > /dev/null\n", True)
        # #313: a basename R2 matches where a `.` follows it (`end.tsv.*`) is not a whole [\w.-] run of the text
        w("tests/g_dotend.sh", "#!/bin/sh\nfor f in data/end.tsv.*; do :; done\n", True)
        cases = [
            # g_join names 'docs' as a bare quoted directory: every change under docs/ is STALE for it
            # (over-approximate by design, R3 at depth 1)
            # N-C: g_join's 'docs' is joined to the literal 'project', so it names docs/project, not docs
            ("docs/data/table.tsv", {"g_named", "g_shdocs", "g_whole"}),
            ("tools/helper.py", {"g_prog", "g_whole"}),
            ("docs/game/new.md", {"g_dir", "g_lsdir", "g_shdocs", "g_whole"}),
            # N-C: prose, a python identifier, a joined literal file and a case-pattern glob read no directory;
            # the python listing of the quoted directory does (tests/new.sh), and the joined pair's listing
            # reads tests/expected/ (and only it)
            ("docs/other.md", {"g_shdocs", "g_whole"}),   # N-K: not g_pyheredoc
            # (g_casepat's `*tests/*.sh*` is still an R6 TEMPLATE for a tests/*.sh name; N-C's `*` rule is only R3's)
            ("tests/new.sh", {"g_casepat", "g_cdwalk", "g_constwalk", "g_lsglob", "g_pylist", "g_subwalk", "g_testswalk", "g_testslink", "g_whole"}),
            ("tests/data/new.txt", {"g_cdwalk", "g_constwalk", "g_pylist", "g_subwalk", "g_testswalk", "g_testslink", "g_whole"}),
            ("tests/expected/new.txt", {"g_cdwalk", "g_constwalk", "g_pylist", "g_pydeep", "g_subwalk", "g_testswalk", "g_testslink", "g_whole"}),
            ("docs/sums.txt", {"g_pyfile", "g_shdocs", "g_whole"}),
            ("docs/project/x.md", {"g_join", "g_shdocs", "g_whole"}),
            # N-B: the message does not read STATE.md; the inline read and the bare argument do
            ("STATE.md", {"g_whole", "g_stateread", "g_statearg"}),
            # N-A: the bare `build` reader is carried, the deeper reader is not
            ("build/m1/new.log", {"g_buildsub", "g_buildtmpl", "g_whole"}),
            ("tests/g_named.sh", {"g_casepat", "g_cdwalk", "g_constwalk", "g_lsglob", "g_named", "g_pylist", "g_subwalk", "g_testswalk", "g_testslink", "g_whole"}),
            # R5: g_data reads a data file that names the changed file
            ("notes/locked.md", {"g_data", "g_whole"}),
            # R6: g_tmpl's templated path matches; `$W/$n.out` is too generic to count (no stem)
            ("cfg/rows/item_b.toml", {"g_tmpl", "g_whole"}),
            ("cfg/other.out", {"g_whole"}),
            # an option continuation (`    --from-file "cfg/base/$n.txt"`) is code in a shell file, not a Lua comment
            ("cfg/base/x.txt", {"g_tmpl", "g_whole"}),
            # R7: every git user reads .gitignore
            (".gitignore", {"g_git", "g_lsdir", "g_lsglob", "g_whole"}),
            # a binary in the reach names nothing (R1 still covers the binary itself): read as text, the
            # names inside it would make g_bin stale for notes/locked.md above
            ("emu/tool", {"g_bin", "g_whole"}),
            # N-D: scratch under build/agent<N>/ is out of every gate's change set but the whole-tree reader's,
            # even for g_buildtmpl, whose "build/$b" template would match it; a build directory is not scratch
            ("build/agent9/t1/x.sh", {"g_lsglob", "g_whole"}),
            ("build/rulecheck/2026-01-01-01/a/p.md", {"g_whole"}),
            ("build/m2/x.log", {"g_buildtmpl", "g_whole"}),
            # R3c through the sibling closure: tools/sibchild.py (run by tools/sibmain.py beside it) lists sibdata/
            ("tools/sibdata/b.mjs", {"g_sib", "g_whole"}),
            # the shell default `${1:-rel/m23/mame}` names the directory every file under it is read from
            ("rel/m23/mame/README.md", {"g_shdef", "g_whole"}),
            # #286 (a) N-B on .md: the message does not read CLAUDE.md, the grep does
            ("CLAUDE.md", {"g_mdread", "g_whole"}),
            # N-E: a prose mention in a data file is not a read; a path at a field start, or after ` ; `, is
            ("notes/ruled.md", {"g_whole"}),
            ("notes/listed.md", {"g_reg", "g_whole"}),
            ("notes/second.md", {"g_reg", "g_whole"}),
            # N-F: the run manifest is data only of the gate that names rulecheck/runs (g_mani names manifest.tsv bare)
            ("notes/man.md", {"g_maniruns", "g_whole"}),   # N-F: not g_planner, whose only `rulecheck/runs` is the planner's
            # N-G: a new run record is not a change for the bare `tests` lister g_pylist; the runs reader sees it
            ("tests/rulecheck/runs/2026-01-02-01/packet.md", {"g_maniruns", "g_whole"}),
            # N-F-CHANGE: a new run's manifest.tsv is no change for g_mani, which names the basename only
            ("tests/rulecheck/runs/2026-01-02-01/manifest.tsv", {"g_maniruns", "g_whole"}),
            # N-F-LINK: the run record g_runlink's data file links by path is a change for it; another run's
            # verdict.txt, whose basename only the link shares, is not
            ("tests/rulecheck/runs/2026-01-01-01/verdict.txt", {"g_maniruns", "g_runlink", "g_whole"}),
            ("tests/rulecheck/runs/2026-01-02-01/verdict.txt", {"g_maniruns", "g_whole"}),
            # N-G: the ledger is no change for the bare `tests` lister; N-J: nor for g_cdwalk (its find walks a cd target)
            # or g_subwalk (it walks tests/replays), whose bare `tests` a walk elsewhere in the reach no longer reinstates
            ("tests/rulecheck/ledger.tsv", {"g_constwalk", "g_testswalk", "g_whole"}),
            # R7: .gitmodules is read by every git user, as .gitignore
            (".gitmodules", {"g_git", "g_lsdir", "g_lsglob", "g_whole"}),
            # #313: R2 still sees `end.tsv` followed by `.` (may_name tests a PREFIX of a run, not a whole run)
            ("data/end.tsv", {"g_dotend", "g_whole"}),
            # #313 N-D: #291's sheet pages are scratch, even for g_buildtmpl's "build/$b"
            ("build/sheets/abc123/gates/g_x/legs/h1.native.rpl", {"g_whole"}),
        ]
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        subprocess.run(["git", "add", "-A"], cwd=root, check=True)
        for c, want in cases:
            _TEXT.clear(); _REFS.clear(); _DATA.clear(); _TMPL.clear(); _TRACKED.clear(); _DATAF.clear(); _MODS.clear()
            _SCOPES.clear(); _RUNS.clear(); _RUNSET.clear(); _R3MEMO.clear(); _TANY.clear(); _DIRPATS.clear()   # #313
            _, stale, _ = predict(root, [c])
            got = set(stale)
            want = want | {"g_gitlist", "g_walkroot", "g_lsvar"}   # the list-form, root-walk and variable-pathspec readers are stale for every change
            good = got == want
            ok = ok and good
            print(f"  {'ok' if good else 'FAIL'}: {c} -> stale {sorted(got)}" + ("" if good else f", expected {sorted(want)}"))
        # g_bound (#313): the bounded planner gives every gate the verdict AND the reason the reference gives (BOUND off:
        # no prefilter, no per-directory memo), path by path, over every case path and deeper ones under the same
        # directories, where the memo and the prefilters do their work
        global BOUND
        deeper = ["docs/game/sub/x.md", "tools/sibdata/deep/y.mjs", "rel/m23/mame/x/y.json", "cfg/rows/item_c.toml",
                  "cfg/base/deep/z.txt", "tests/expected/sub/new.txt", "build/m1/sub/new.log", "lists/sub/locks.tsv"]
        for c in [c for c, _ in cases] + deeper:
            got = {}
            for bound in (True, False):
                BOUND = bound
                _TEXT.clear(); _REFS.clear(); _DATA.clear(); _TMPL.clear(); _TRACKED.clear(); _DATAF.clear(); _MODS.clear()
                _SCOPES.clear(); _RUNS.clear(); _RUNSET.clear(); _R3MEMO.clear(); _TANY.clear(); _DIRPATS.clear()
                got[bound] = predict(root, [c])[1]
            BOUND = True
            good = got[True] == got[False]
            ok = ok and good
            print(f"  {'ok' if good else 'FAIL'}: g_bound {c}: {len(got[True])} stale, bounded = reference"
                  + ("" if good else f"; bounded {got[True]}, reference {got[False]}"))
    # N-D: the session tooling's untracked scratch under build/ is out of the change set, a build is not
    for c, want in (("build/agent200/t1/x.sh", True), ("build/rulecheck/2026-01-01-01/a/p.md", True),
                    ("build/static_runs/x/results.tsv", True), ("build/snapshot_runs/x/y", True),
                    ("build/m3b_merged31/rompath/vsavjw.zip", False), ("build/agentless/x", False),
                    ("build/manifest/donovan.toml", False), ("tools/agent200.py", False),
                    ("build/sheets/8b82d5d247c6/index.html", True), ("build/sheets/8b82d5d247c6.tree/STATE.md", True),
                    ("build/sheetsx/a", False)):
        good = drop_scratch(c) == want
        ok = ok and good
        print(f"  {'ok' if good else 'FAIL'}: drop_scratch({c}) = {drop_scratch(c)}")
    ok = selftest_plan() and ok
    print("SELFTEST " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def selftest_plan():
    """#304 (14z-207): plan() on a synthetic git repository — the pruned listing holds no scratch, a whole-tree reader
    is still STALE on a scratch change alone (asked lazily) and CARRIED when the scratch is older than the base run, a
    template reader of build/ stays CARRIED for scratch, workers give the serial verdicts, and the budget and the time
    limit refuse"""
    global PLAN_BUDGET, PLAN_TIME_LIMIT, SCRATCH_WALK_CAP
    import time
    ok = True

    def check(name, good, detail=""):
        nonlocal ok
        ok = ok and good
        print(f"  {'ok' if good else 'FAIL'}: plan {name}" + ("" if good else f" — {detail}"))
    with tempfile.TemporaryDirectory() as root:
        def w(rel, t, x=False):
            p = os.path.join(root, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, "w").write(t)
            if x:
                os.chmod(p, 0o755)
        w("tests/ci_portable.txt", "p_whole\np_tmpl\np_doc\n")
        w("tests/p_whole.sh", "#!/bin/sh\ngit ls-files | wc -l\n", True)
        w("tests/p_tmpl.sh", "#!/bin/sh\nfor b in a b; do ls \"build/$b\"; done\n", True)
        w("tests/p_doc.sh", "#!/bin/sh\ncat docs/a.md\n", True)
        w("docs/a.md", "x\n")
        g = ["git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-c", "user.name=s",
             "-c", "user.email=s@s"]
        for args in (["init", "-q"], ["add", "-A"], ["commit", "-q", "-m", "base"]):
            subprocess.run(g + args, cwd=root, check=True, capture_output=True)
        head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=root, capture_output=True, text=True).stdout.strip()
        t0 = int(time.time()) - 5
        res = os.path.join(root, "base_results.tsv")   # untracked itself, older than the base run below
        open(res, "w").write(f"# head {head}\n# utc {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(t0))}\n"
                             + "".join(f"{x}\tPASS\t1\t0\t0\t0\n" for x in ("p_whole", "p_tmpl", "p_doc")))
        os.utime(res, (t0 - 100, t0 - 100))
        for rel in ("build/agent7/x.txt", "build/agent7/sub/y.sh", "build/sheets/a/b.html"):
            w(rel, "s\n")

        def run(jobs=1):
            _TEXT.clear(); _SCOPES.clear(); _TRACKED.clear(); _DATAF.clear()
            return {r[1]: r for r in plan(root, res, jobs)}
        a = run()
        check("A: the pruned listing holds no scratch", LAST_PLAN.get("listed_scratch") == 0, str(LAST_PLAN))
        check("A: a whole-tree reader is STALE on scratch alone", a["p_whole"][0] == "RERUN" and "R4" in a["p_whole"][2],
              str(a["p_whole"]))
        check("A: a build/ template reader stays CARRIED for scratch", a["p_tmpl"][0] == "CARRY", str(a["p_tmpl"]))
        check("A: the scratch was asked lazily", LAST_PLAN.get("scratch_seen", 0) >= 1, str(LAST_PLAN))
        w("docs/a.md", "y\n")
        b1, b2 = run(1), run(2)
        check("B: a tracked change re-runs its reader", b1["p_doc"][0] == "RERUN", str(b1["p_doc"]))
        check("B: two workers give the serial plan", b1 == b2, f"serial {b1}, workers {b2}")
        subprocess.run(g + ["checkout", "-q", "--", "docs/a.md"], cwd=root, check=True)
        os.utime(os.path.join(root, "docs/a.md"), (t0 - 100, t0 - 100))
        for d, _, fs in os.walk(os.path.join(root, "build")):
            for f in fs:
                os.utime(os.path.join(d, f), (t0 - 100, t0 - 100))
        c = run()
        check("C: scratch older than the base run re-runs nothing", c["p_whole"][0] == "CARRY", str(c["p_whole"]))
        cap = SCRATCH_WALK_CAP
        try:   # F: with no file walked, git's own listing of the scratch answers R4, old scratch and new alike
            SCRATCH_WALK_CAP = 0
            f1 = run()
            check("F: from git's listing, old scratch re-runs nothing", f1["p_whole"][0] == "CARRY"
                  and LAST_PLAN.get("scratch_listed"), f"{f1['p_whole']} {LAST_PLAN}")
            os.utime(os.path.join(root, "build/sheets/a/b.html"), None)
            f2 = run()
            check("F: from git's listing, a new scratch file re-runs the whole-tree reader", f2["p_whole"][0] == "RERUN"
                  and LAST_PLAN.get("scratch_listed"), f"{f2['p_whole']} {LAST_PLAN}")
            os.utime(os.path.join(root, "build/sheets/a/b.html"), (t0 - 100, t0 - 100))
        finally:
            SCRATCH_WALK_CAP = cap
        for k in range(12):
            w(f"build/leak/f{k}.txt", "l\n")
        budget, limit = PLAN_BUDGET, PLAN_TIME_LIMIT
        try:
            PLAN_BUDGET = 10
            try:
                run()
                check("D: the budget refuses 12 untracked paths over 10", False, "no refusal")
            except PlanRefused as e:
                check("D: the budget refuses 12 untracked paths over 10, naming the prefix", "build/leak 12" in str(e), str(e))
            PLAN_BUDGET, PLAN_TIME_LIMIT = budget, -1
            try:
                run()
                check("E: the time limit refuses", False, "no refusal")
            except PlanRefused as e:
                check("E: the time limit refuses", "time limit" in str(e), str(e))
        finally:
            PLAN_BUDGET, PLAN_TIME_LIMIT = budget, limit
    return ok


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


# #304 (14z-207; maintainer-ruled 2026-10-23, "Adopt all four (Recommended)"): THE PLAN'S BUDGET. Before judging, the
# plan prints its changed paths by prefix; it REFUSES (exit 3, the prefixes named) past PLAN_BUDGET effective untracked
# paths — measured normals 53 (the 14z-206 close's base) and 405 (an older base), against 41,276 when a new scratch
# directory leaked through (build/agent207/t304/prof/) — or past PLAN_TIME_LIMIT seconds of judging (the bounded plan
# of #313 took 22 s on PILOT; the leak above 649 s). A leak then reads as a fault, never as a hang.
PLAN_BUDGET = 5000
LAST_PLAN = {}   # what the last plan() listed and asked of the scratch (its selftest reads it)
PLAN_TIME_LIMIT = 600
# PLAN_JOBS: the gate loop's workers (#304 (c)). Measured 14z-207 on this Mac, the 14z-206 close's base, twice each
# (build/agent207/t304/J/jobs_cost/times.txt): 1 job 27.8/27.4 s, 2 jobs 16.3/16.4 s, 4 jobs 10.2/10.3 s, 6 jobs 8.1/8.2 s,
# every plan identical to the serial one; and on the final code (build/agent207/t304/J/jobs12/times.txt) 1 job
# 27.2/26.8 s, 6 jobs 8.0/8.0 s, 8 jobs 7.1/7.0 s, 12 jobs 7.3/7.1 s, each plan identical to the serial one. 12 is the
# maintainer's default (DECISIONS_HISTORY.md "Ruled 2026-10-23 (14z-207) — #304: fork J's four judgement calls
# stand"); on a smaller host (PILOT, 6 vCPUs) pass --jobs
PLAN_JOBS = 12
SCRATCH_WALK_CAP = 20000   # ScratchChanges: files walked before it finishes from git's listing


class ScratchChanges:
    """#304 (a): the changed SCRATCH paths, which the pruned listing leaves out and R4 alone reads, found lazily and
    exactly as the full listing would give them: untracked, unignored, modified at or after the base run's start (an
    unreadable one counts), a nested repository as one `dir/` entry. The walk takes the newest directories first and
    stops as soon as R4 has its answer: a confirm run writes its own run record under build/static_runs/ before it
    plans, so a whole-tree reader is answered by the first file looked at (0.1 s, 549 files walked, measured 14z-207 on
    this Mac's 5.1 M scratch files). Past SCRATCH_WALK_CAP files it finishes from git's own listing of the scratch
    directories, the old plan's cost (a whole walk with nothing newer took 114.7 s against git's 28.0 s + 11.3 s of
    mtimes: build/agent207/t304/J/jobs_cost/scratch_cost.txt); only a reader scoped narrower than the whole tree, or a
    base run newer than every scratch file, gets that far."""

    def __init__(self, root, t0, rows=None):
        self.root, self.t0 = root, t0
        self.rows = rows if rows is not None else BUILD_DIRS
        self.seen, self.done, self.walked, self.listed = [], False, 0, False
        self._gen = self._walk()

    def _tops(self):
        b = os.path.join(self.root, "build")
        rx = [re.compile(build_dirs.glob_rx(p)) for p in build_dirs.scratch_rows(self.rows)]
        try:
            names = [d for d in os.listdir(b) if any(r.fullmatch(d) for r in rx)]
        except OSError:
            return []
        return sorted((os.path.join("build", d) for d in names if os.path.isdir(os.path.join(b, d))),
                      key=lambda d: -self._mt(d))

    def _mt(self, rel):
        try:
            return os.stat(os.path.join(self.root, rel)).st_mtime
        except OSError:
            return 0

    def _files(self):
        tracked = set(_tracked(self.root))
        stack = list(reversed(self._tops()))
        while stack:
            d = stack.pop()
            try:
                ents = list(os.scandir(os.path.join(self.root, d)))
            except OSError:
                continue
            subs = []
            for e in ents:
                rel = d + "/" + e.name
                if e.is_dir(follow_symlinks=False):
                    if os.path.exists(os.path.join(e.path, ".git")):
                        yield rel + "/"   # a nested repository: git lists it as one entry
                    else:
                        subs.append(rel)
                elif rel not in tracked:
                    yield rel
            stack.extend(sorted(subs, key=self._mt))   # popped newest first

    def _new(self, rel):
        try:
            return os.path.getmtime(os.path.join(self.root, rel)) >= self.t0
        except OSError:
            return True

    def _walk(self):
        batch, size, out = [], 8, set()
        for rel in self._files():
            if self.walked >= SCRATCH_WALK_CAP:   # WALK-CAP: the rest from git's own listing, at the old cost
                break
            self.walked += 1
            if self._new(rel):
                batch.append(rel)
            if batch and (len(batch) >= size or self.walked % 256 == 0):
                for c in self._unignored(batch):
                    out.add(c)
                    yield c
                batch, size = [], min(size * 4, 4096)
        else:
            for c in self._unignored(batch):
                yield c
            return
        for c in self._unignored(batch):
            out.add(c)
            yield c
        self.listed = True
        tops = self._tops()
        r = subprocess.run(["git", "ls-files", "--others", "--exclude-standard", "--"] + tops, cwd=self.root,
                           capture_output=True, text=True) if tops else None
        for c in (r.stdout.splitlines() if r else []):
            if c not in out and self._new(c):
                yield c

    def _unignored(self, paths):
        if not paths:
            return []
        r = subprocess.run(["git", "check-ignore", "--stdin", "-z"], cwd=self.root, input="\0".join(paths) + "\0",
                           capture_output=True, text=True)
        ign = set(x for x in r.stdout.split("\0") if x) if r.returncode in (0, 1) else set()
        return [p for p in paths if p not in ign and p.rstrip("/") not in ign]

    def __iter__(self):
        yield from self.seen
        if self.done:
            return
        for c in self._gen:
            self.seen.append(c)
            yield c
        self.done = True


def prefixes(paths, n=8):
    """the changed paths counted by their first two components, largest first"""
    from collections import Counter
    k = Counter("/".join(p.split("/")[:2]) for p in paths)
    return ", ".join(f"{p} {c}" for p, c in k.most_common(n))


def plan(root, results, jobs=None):
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
    tracked = set(subprocess.run(["git", "diff", "--name-only", head], cwd=root, capture_output=True, text=True,
                                 check=True).stdout.splitlines()) | set(dirty)
    changed = set(tracked)
    t0 = calendar.timegm(time.strptime(utc, "%Y-%m-%dT%H:%M:%SZ")) if utc else 0
    untracked = set()
    # PRUNED-LISTING (#304 (a)): the scratch rows' pathspecs, generated with SCRATCH from the one list
    listed = subprocess.run(["git", "ls-files", "--others", "--exclude-standard", "--", "."] + build_dirs.pathspecs(BUILD_DIRS),
                            cwd=root, capture_output=True, text=True).stdout.splitlines()
    LAST_PLAN.clear()
    LAST_PLAN.update(listed=len(listed), listed_scratch=sum(1 for f in listed if drop_scratch(f)))
    for f in listed:
        try:
            if os.path.getmtime(os.path.join(root, f)) >= t0:
                untracked.add(f)
        except OSError:
            untracked.add(f)
    changed |= untracked
    for p in [p for p in fps if p in changed]:   # SUBMODULE-UNCHANGED (#286 (b))
        if subfp(root, p) == fps[p]:
            changed.discard(p)
    scratch = ScratchChanges(root, t0)
    eff_unt = [c for c in untracked if c in changed and not drop_scratch(c)]
    print(f"plan: {len(changed)} changed paths ({len(tracked)} tracked or dirty, {len(eff_unt)} untracked) by prefix: "
          f"{prefixes(changed) or 'none'}", file=sys.stderr, flush=True)
    if len(eff_unt) > PLAN_BUDGET:   # PLAN-BUDGET (#304 (d))
        raise PlanRefused(f"{len(eff_unt)} changed untracked paths, past the plan's budget of {PLAN_BUDGET} — a new "
                          f"output directory leaking into the change set? Class it in tests/expected/build_dirs.tsv. "
                          f"By prefix: {prefixes(eff_unt)}")
    r1 = {}
    t_plan = time.monotonic()
    tell = lambda n, total: print(f"plan: {n}/{total} gates judged against {len(changed)} changed paths, "
                                  f"{time.monotonic() - t_plan:.0f} s", file=sys.stderr, flush=True)
    _, stale, _ = predict(root, sorted(changed), r1, tell, scratch, jobs or PLAN_JOBS, t_plan + PLAN_TIME_LIMIT, tracked) if changed or any(True for _ in scratch) else (gates, {}, gates)
    print(f"plan: {len(changed)} changed paths, {len(stale)} of {len(gates)} gates STALE, "
          f"{time.monotonic() - t_plan:.1f} s (#259); scratch: {len(scratch.seen)} changed path(s) asked of R4, "
          f"{scratch.walked} file(s) walked{'' if scratch.done else ', walk stopped early'} (#304)",
          file=sys.stderr, flush=True)
    LAST_PLAN.update(scratch_seen=len(scratch.seen), walked=scratch.walked, scratch_done=scratch.done,
                     scratch_listed=scratch.listed)

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
        try:
            rows = plan(os.path.abspath(opt("--root")), opt("--results"), int(opt("--jobs") or 0) or None)
        except PlanRefused as e:   # #304 (d): a fault with its reason, never a hang
            print(f"plan: REFUSED — {e}", file=sys.stderr, flush=True)
            return 3
        for row in rows:
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
    if a[:1] == ["reach"] and opt("--root"):   # 14z-205 (#297): `gate<TAB>program` per line, the cadence's @code trigger
        root = os.path.abspath(opt("--root"))
        files = br.index(root, [])
        for g in a[a.index("--root") + 2:]:
            for prog in reach(root, g, files):
                print(f"{g}\t{prog}")
        return 0
    if a[:1] == ["backtest"] and len(a) >= 2 and opt("--repo"):
        return backtest(a[1], os.path.abspath(opt("--repo")))
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main())
