#!/usr/bin/env python3
"""tmp_hygiene.py — every temporary directory or file a tool or gate makes is removed when its maker exits (#303, 14z-207).

A static census, read without running anything:
  PYTHON (tools/*.py, tests/*.py, tests/lib/*.py): every tempfile.mkdtemp(), tempfile.mkstemp() and
    NamedTemporaryFile(..., delete=False) must be CLEANED: its assigned name is passed to atexit.register(...) on the
    same statement line, or removed (shutil.rmtree / os.remove / os.unlink / .unlink()) in the same function, or the
    site is in ALLOW below with the reason it outlives its maker. A context-managed TemporaryDirectory() is clean.
  SHELL (tests/*.sh, tools/*.sh): every `X="$(mktemp ...)"` must be removed by a trap on EXIT in the same script that names "$X".
  Every `mktemp -d` site in tests/*.sh, tests/lib/*.sh and tools/*.sh must STOP when mktemp fails (UNGUARDED, #333; see
  sh_scan), and no EXIT trap set BEFORE a site may name "$X/..." or "$X"/* (TRAPPED, #337; see sh_trap_order): the
  guard's stop runs that trap with $X empty.
The census that found the leaks ran every static gate and each of its controls in a fresh TMPDIR on PILOT (14z-207,
build/agent207/P/ on the maintainer's Mac): six gates left Python tempfile directories (up to 145 per run).

Usage: tmp_hygiene.py [--root DIR] [FILE ...]      exit 1 on an uncleaned site
"""
import argparse, ast, os, re, shlex, sys

ALLOW = {
    # "path:function": "why this site is clean although the census cannot see it, or why it outlives its maker"
    "tools/audit_module_refs.py:main": "the NamedTemporaryFile's name is copied to plant_path, which a finally unlinks",
    "tools/run_mame.sh:SANDBOX": "the by-hand default: with MAME_SANDBOX unset the sandbox is made and MAME is exec'd, so nothing removes it; ruled 2026-10-23 (14z-207, #303): callers pass a sandbox and the runner stays as it is — every scripted call is held by runner_calls() below",
    "tools/run_fbneo.sh:SANDBOX": "the by-hand default, as run_mame.sh (FBNEO_SANDBOX unset, then FBNeo is exec'd); every scripted call passes FBNEO_SANDBOX (runner_calls(), ruled 2026-10-23)",
    "tools/run_replay_mame.sh:WORK": "the by-hand default when no [sandbox] argument is given; every scripted call passes one (runner_calls(), ruled 2026-10-23, 14z-207)",
    "tools/run_replay_guarded.sh:WORK": "the by-hand default when no [sandbox] argument is given; every scripted call passes one (runner_calls(), ruled 2026-10-23, 14z-207)",
    "tools/run_wide.sh:PB": "the by-hand WIDE_PLAYBACK path copies the recorded nvram to a throwaway dir and then execs MAME; a human's session tool, run by no gate",
}
SH_MKTEMP = re.compile(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z_0-9]*)="?(?:\$\{[A-Za-z_0-9]+:-)?\$\(\s*mktemp\b[^)]*\)')


def py_sites(path, src):
    """(line, function, kind, var, cleaned) per temp maker in a python source"""
    tree = ast.parse(src, path)
    lines = src.split("\n")
    out = []
    funcs = [n for n in ast.walk(tree) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))]

    def enclosing(node):
        best = None
        for f in funcs:
            if f.lineno <= node.lineno <= getattr(f, "end_lineno", f.lineno) and (best is None or f.lineno > best.lineno):
                best = f
        return best

    for n in ast.walk(tree):
        if not isinstance(n, ast.Call):
            continue
        f = n.func
        name = f.attr if isinstance(f, ast.Attribute) else f.id if isinstance(f, ast.Name) else ""
        kind = None
        if name in ("mkdtemp", "mkstemp"):
            kind = name
        elif name == "NamedTemporaryFile" and any(k.arg == "delete" and isinstance(k.value, ast.Constant) and k.value.value is False for k in n.keywords):
            kind = "NamedTemporaryFile(delete=False)"
        if not kind:
            continue
        fn = enclosing(n)
        scope_lines = lines[fn.lineno - 1:fn.end_lineno] if fn else lines
        line = lines[n.lineno - 1]
        m = re.search(r"([A-Za-z_][A-Za-z_0-9]*)\s*=\s*[^=\n]*\b" + re.escape(name) + r"\(", line)   # d = Path(tempfile.mkdtemp())
        if m and name == "mkstemp":   # fd, path = tempfile.mkstemp(): the path is the second name
            m = re.search(r"[A-Za-z_][A-Za-z_0-9]*\s*,\s*([A-Za-z_][A-Za-z_0-9]*)\s*=\s*[^=\n]*\bmkstemp\(", line) or m
        wm = re.search(r"\bas\s+([A-Za-z_][A-Za-z_0-9]*)\s*:", line)
        var = (m.group(1) if m else wm.group(1) if wm else "")
        body = "\n".join(scope_lines)
        cleaned = "atexit.register" in line
        if not cleaned and var:
            v = re.escape(var)
            cleaned = bool(re.search(rf"(rmtree|os\.remove|os\.unlink)\(\s*{v}\b|{v}(\.name)?\)?\.unlink\(|atexit\.register\([^\n]*\b{v}\b", body)) \
                or bool(re.search(rf"atexit\.register\([^\n]*{v}\.name", body))
        out.append((n.lineno, fn.name if fn else "<module>", kind, var, cleaned))
    return out


def sh_sites(path, src):
    """(line, var, cleaned) per `X="$(mktemp ...)"` in a shell script. Cleaned: an EXIT trap anywhere on a line (an
    `if` branch included) removes "$X", or names a function whose body removes it; or X is made inside a directory
    variable that is itself cleaned (`mktemp -d "$W/x.XXXXXX"`)."""
    lines = src.split("\n")
    code = [l.split("#", 1)[0] if not l.lstrip().startswith("#") else "" for l in lines]
    traps = [m.group(1) for c in code for m in re.finditer(r"\btrap\s+('[^']*'|\"[^\"]*\"|\S+)\s+[^;\n]*\bEXIT\b", c)]
    def body(fn):
        for i, c in enumerate(code):
            if re.match(r"\s*" + re.escape(fn) + r"\s*\(\)\s*\{", c):
                out = [c]
                for c2 in code[i + 1:]:
                    out.append(c2)
                    if c2.strip().startswith("}"):
                        break
                return "\n".join(out) if "}" in out[0] or len(out) > 1 else out[0]
        return ""
    removers = []
    for t in traps:
        t = t.strip("'\"")
        removers.append(t if " " in t or "rm" in t else body(t))
    plain_rm = [c for c in code if re.search(r"\brm\s+-[a-z]*f", c)]   # a plain rm on the script's own path counts too

    def removed(v):
        pat = r"\$\{?" + re.escape(v) + r"\b"
        return any(re.search(r"\brm\b", r) and re.search(pat, r) for r in removers) or any(re.search(pat, c) for c in plain_rm)
    made = {}
    for i, c in enumerate(code, 1):
        m = SH_MKTEMP.match(c)
        if m:
            parent = re.search(r'mktemp\s+(?:-d\s+)?"?\$\{?([A-Za-z_][A-Za-z_0-9]*)\}?/', c)
            made[m.group(1)] = (i, parent.group(1) if parent else None)
    out = []
    for v, (i, parent) in made.items():
        out.append((i, v, removed(v) or (parent is not None and parent in made and removed(parent))))
    return sorted(out)


# EVERY `$(mktemp ... -d ...)` substitution, wherever it stands on a line (rule-checker run 2026-10-29-1366 Q4: the
# line-start form alone left ~33 sites unread — an `else` arm, `[ -n "$O" ] || O=...`, a `case` arm, an inline argument,
# an assignment after `;`, `-dt`); a -d flag alone or combined (`-dt`, `-td`)
# mktemp need not be the substitution's first word (`$(TMPDIR=... mktemp -d)`, `$(command mktemp -d)`,
# `$(/usr/bin/mktemp -d)`, `$(cd "$A" && mktemp -d)`: rule-checker run 2026-10-29-1374)
SH_SUBST_D = re.compile(r'\$\((?:[^()]*?[\s;&|/"])?mktemp\b(?:[^)]*?\s)?(?:-[A-Za-z]*d[A-Za-z]*\b|--directory\b)')
STOPS = re.compile(r"\b(?:exit|return)\b")
SH_ASSIGN_END = re.compile(r'(?:^\s*|[;&|({]\s*|\b(?:then|else|do)\s+|\)\s*)(?:(local|export|readonly)\s+)?'
                           r'([A-Za-z_][A-Za-z_0-9]*)="?(?:\$\{[A-Za-z_0-9]+:-)?$')


def _quote_at(code, pos):
    """the quoting in force at code[pos]: 'sq', 'dq' or '' (text inside quotes is never a heredoc opener; single-quoted
    text is never run here)"""
    sq = dq = False
    k = 0
    while k < pos:
        ch = code[k]
        if ch == "\\" and not sq:
            k += 2; continue
        if ch == "'" and not dq:
            sq = not sq
        elif ch == '"' and not sq:
            dq = not dq
        k += 1
    return "sq" if sq else "dq" if dq else ""


def _in_single_quotes(code, pos):
    return _quote_at(code, pos) == "sq"


def _arm_stops(rest, can_return=True):
    """rest starts with `||`: does THAT arm stop the script — an `exit` or `return` in its own `{ ... }` block, or
    before the next `;`, `&&` or `|` (rule-checker run 2026-10-29-1371: `|| true; ... || exit` is not a guard). The word
    counts only outside quotes (`|| echo "cannot exit"` does not stop), and `return` only where it returns: inside a
    function body or at a sourced library's top level (`can_return`); at an executed script's top level bash prints an
    error and runs on (rule-checker run 2026-10-29-1379)"""
    a = rest[2:].lstrip()
    if a.startswith("{"):
        depth, k = 0, 0
        while k < len(a):
            depth += {"{": 1, "}": -1}.get(a[k], 0)
            if depth == 0:
                break
            k += 1
        seg = a[:k + 1]
    else:
        seg = re.split(r";|&&|(?<!\|)\|(?!\|)", a, 1)[0]
    words, d = [], 0                                   # only words outside any `( ... )` the arm opens: in a
    for ch in _blank_quotes(seg):                      # subshell `|| (exit 2)` only the subshell exits (run 1380)
        d += {"(": 1, ")": -1}.get(ch, 0)
        words.append(ch if d <= 0 and ch not in "()" else " ")
    words = "".join(words)
    return bool(re.search(r"\bexit\b", words) or (can_return and re.search(r"\breturn\b", words)))


def _heredoc_opener(code):
    """the word a heredoc opener on this code line names, or None: never a here-string `<<<`, a `<<` inside quotes, or
    the shift inside `(( ... ))` / `$(( ... ))` (each once could hide a whole file's rest)"""
    flat = re.sub(r"\(\(.*?\)\)", "", code)
    for h in re.finditer(r"(?<!<)<<-?(?!<)\s*['\"]?([A-Za-z_][A-Za-z_0-9]*)['\"]?", flat):
        if _quote_at(flat, h.start()) == "":
            return h.group(1)
    return None


SH_BACKTICK_D = re.compile(r"`(?:[^`]*?[\s;&|/\"])?mktemp\b[^`]*?(?:\s-[A-Za-z]*d[A-Za-z]*\b|\s--directory\b)[^`]*`")


def _blank_quotes(code):
    """code with every quoted character turned into a space: a `set -e` inside quotes (`sh -c 'x; set -e'`,
    `echo "a; set -e"`) is text, never this script's own set -e (rule-checker run 2026-10-29-1374)"""
    out, sq, dq, k = [], False, False, 0
    while k < len(code):
        ch = code[k]
        if ch == "\\" and not sq:                     # one backslash (it compared with two until run 2026-10-29-1379)
            out.append("  " if (sq or dq) else code[k:k + 2]); k += 2; continue
        if ch == "'" and not dq:
            sq = not sq; out.append(ch)
        elif ch == '"' and not sq:
            dq = not dq; out.append(ch)
        else:
            out.append(" " if (sq or dq) else ch)
        k += 1
    return "".join(out)


def _code_lines(src):
    """(line, code) per LOGICAL line (a `\\` continuation joined; the line is the first physical one), its comment cut
    off, heredoc bodies left out (they are text, not code)"""
    phys = src.split("\n")
    logical, k = [], 0
    while k < len(phys):
        start, text = k + 1, phys[k]
        while text.rstrip().endswith("\\") and k + 1 < len(phys) and not text.lstrip().startswith("#"):
            k += 1; text = text.rstrip()[:-1] + " " + phys[k].lstrip()
        logical.append((start, text)); k += 1
    def code_of(raw):
        # a `#` opens a comment at a line's start or after a blank, and only OUTSIDE quotes (rule-checker run
        # 2026-10-30-1410: `echo "a #b"; trap ... EXIT` was cut at the quoted ` #`, hiding the trap and any site after it)
        if raw.lstrip().startswith("#"):
            return ""
        for m in re.finditer(r"(?:^|(?<=\s))#", raw):
            if _quote_at(raw, m.start()) == "":
                return raw[:m.start()]
        return raw
    codes, here = [], None
    for start, raw in logical:
        if here is not None:
            if raw.strip() == here:
                here = None
            continue
        code = code_of(raw)
        codes.append((start, code))
        h = _heredoc_opener(code)
        if h:
            here = h
    return codes


def sh_scan(src, sourced=False, stops=None):
    """(line, var, guarded) per `mktemp -d` substitution — `$( ... )` or backticks, `-d` alone or combined (`-dt`) or
    `--directory` — read on LOGICAL lines (a `\\` continuation joined; the line is the first physical one). An
    ASSIGNMENT `X="$(mktemp -d ...)"` (at a line's start or after `;`, `&&`, `||`, `then`, `else`, `do`, a `case` arm's
    `)`, `${X:-...}` included) is guarded by a `||` whose own arm stops (`exit` / `return`), by a `[ -n "$X" ] || ...`
    test whose arm stops on one of the next three code lines before X is used, or — a plain statement only — by
    `set -e` in force AT the line (the last `set -e` / `set +e` among the code lines before it; a function body is
    read where it stands, not where it is called). NEVER guarded: `local` / `export` / `readonly X="$(...)"` (the
    builtin's own status 0 hides the failure), an assignment that prefixes a command (`X="$(...)" cmd`), an inline
    argument (`cmd "$(mktemp -d)"`, var `-`). Not code, so not read: a heredoc body (see _heredoc_opener) and text in
    single quotes. Widened after rule-checker runs 2026-10-29-1366, -1368 and -1371. Since run 2026-10-29-1379: a
    `set -e` inside an open `( ... )` / `$( ... )` on its line is the subshell's, not the script's; a `|| return` stops
    only inside a function body (tracked by its braces: `name() {` / `function name {` to the brace that closes it) or
    at the top level of a SOURCED file (`sourced`, the census passes it for tests/lib/); an arm's `exit` / `return`
    counts only outside quotes; `\\"` no longer flips the quote state. Since run 2026-10-29-1380: an arm's stop inside
    a `( ... )` it opens is the subshell's (`|| (exit 2)` runs on), and `set -o errexit` / `set +o errexit` are read as
    `set -e` / `set +e`. Since run 2026-10-29-1382: a `set -e` behind `&&`, `||`, `then`, `do`, `else` or a case arm
    is conditional and never read as in force, and a `set +e` there (or after `{`) still turns it off. THE LIMIT: this
    is a lint over shell TEXT, not a shell interpreter — a form outside the known answers of tests/test_tmp_hygiene.sh
    (a multi-line `if` around `set -e`, a function's `set -e` read where the function is called, `eval`) is not
    read as the shell would run it."""
    codes = _code_lines(src)
    out, sete = [], False
    depth, fns = 0, []                                 # brace depth over code lines; [start depth, opened] per function
    FN_HEAD = re.compile(r"^\s*(?:function\s+[A-Za-z_][A-Za-z0-9_]*(?:\s*\(\))?|[A-Za-z_][A-Za-z0-9_]*\s*\(\))\s*(?:\{|$)")
    for n, (start, code) in enumerate(codes):
        blank = _blank_quotes(code)
        if FN_HEAD.match(blank):
            fns.append([depth, False])
        in_fn = bool(fns)
        peak = depth
        for ch in blank:
            if ch in "{}":
                depth += 1 if ch == "{" else -1; peak = max(peak, depth)
        for f in fns:
            f[1] = f[1] or peak > f[0]
        while fns and fns[-1][1] and depth <= fns[-1][0]:
            fns.pop()
        can_return = in_fn or sourced
        for se in re.finditer(r"(^|[;&|({)]|\bthen|\bdo|\belse)\s*set\s+([-+])(?:[a-zA-Z]*e|o\s+errexit\b)", blank):
            pre = blank[:se.start() + (1 if blank[se.start()] == "(" else 0)]
            if pre.count("(") - pre.count(")") > 0:    # inside a subshell opened on this line: not this script's
                continue
            # run 2026-10-29-1382: a `set -e` behind `&&`, `||`, `then`, `do`, `else` or a case arm's `)` runs only when
            # its condition holds, so it is never read as in force; a `set +e` anywhere turns it off (the cautious side)
            cond = se.group(1) in ("&", "|", ")", "then", "do", "else")
            if se.group(2) == "+":
                sete = False
            elif not cond:
                sete = True                            # the LAST unconditional `set -e` / any `set +e` on the line wins
        found = [(m.start(), "paren") for m in SH_SUBST_D.finditer(code)] + \
                [(m.start(), "tick") for m in SH_BACKTICK_D.finditer(code)]
        for pos, kind in sorted(found):
            if _in_single_quotes(code, pos):
                continue
            mk = code.find("mktemp", pos + 1)          # the word itself, quoted inside its own substitution, is text
            if _quote_at(code[pos + 2:mk], mk - pos - 2) != "":
                continue
            if kind == "paren":
                j, depth = pos + 1, 0
                while j < len(code):                   # the substitution's own closing parenthesis
                    depth += {"(": 1, ")": -1}.get(code[j], 0)
                    if depth == 0:
                        break
                    j += 1
            else:
                j = code.find("`", pos + 1)
            a = SH_ASSIGN_END.search(code[:pos])
            rest = code[j + 1:].lstrip('"}').lstrip()
            if a is None:                              # an inline argument: the command runs with an empty one
                out.append((start, "-", False)); continue
            kw, v = a.group(1), a.group(2)
            if kw in ("local", "export", "readonly"):   # the builtin's own status, 0, is what `||` and set -e see
                out.append((start, v, False)); continue
            if rest.startswith("||") and _arm_stops(rest, can_return):
                out.append((start, v, True)); continue
            tested = False
            for _l, nxt in codes[n + 1:n + 4]:          # `[ -n "$X" ] || exit` before X is used
                t = re.search(r'\[\s+-n\s+"?\$\{?' + re.escape(v) + r'\b[^\]]*\]\s*(\|\|.*)', nxt)
                if t:
                    tested = _arm_stops(t.group(1), can_return)
                    if tested and stops is not None:   # #337 (run 2026-10-30-1407): the stop is on THIS later line
                        stops[(start, v)] = (_l, t.start(1))
                    break
                if re.search(r"\$\{?" + re.escape(v) + r"\b", nxt):
                    break
            if tested:
                out.append((start, v, True)); continue
            plain = rest == "" or rest.startswith((";", "fi", "done", "esac", ")"))
            out.append((start, v, bool(sete and plain)))
    return out


SH_TRAP_WORD = re.compile(r"(?<![A-Za-z0-9_\-.])(trap)(?![A-Za-z0-9_\-.])")
SH_ARG_BEFORE = re.compile(r"[A-Za-z0-9_\-.$}\]\"'/=:,@%+]$")   # the word before `trap` ends an ordinary word
SH_CMD_WORDS = ("then", "do", "else", "elif", "if", "while", "until", "time", "builtin", "command", "exec", "!")


def _trap_positions(text):
    """every `trap` word of text (quotes already blanked) that is not an ARGUMENT: rule-checker run 2026-10-30-1409 found
    a whitelist of command positions (line start, ; & | ( { !, then, do, else) blind to a case arm's `pat) trap`, so the
    rule is inverted — a `trap` is a command unless the text before it ends an ordinary word that is not a shell keyword
    or command prefix (then, do, else, elif, if, while, until, time, builtin, command, exec)"""
    out = []
    for m in SH_TRAP_WORD.finditer(text):
        before = text[:m.start()].rstrip()
        last = re.search(r"([A-Za-z_!][A-Za-z0-9_]*)$", before)
        if before and SH_ARG_BEFORE.search(before) and not (last and last.group(1) in SH_CMD_WORDS
                                                             and not re.search(r"[A-Za-z0-9_\-.$]$", before[:last.start()])):
            continue
        out.append(m.start(1))
    return out
FN_DEF = re.compile(r"^\s*(?:function\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*\(\))?|([A-Za-z_][A-Za-z0-9_]*)\s*\(\))\s*\{?")


def _functions(codes):
    """{name: body text} per shell function: from its `name() {` / `function name {` line to the brace that closes it
    (quoted braces are text), a one-line body included"""
    out = {}
    for n, (_l, code) in enumerate(codes):
        m = FN_DEF.match(_blank_quotes(code))
        if not m:
            continue
        name, depth, opened, body = m.group(1) or m.group(2), 0, False, []
        for _l2, c2 in codes[n:]:
            body.append(c2)
            for ch in _blank_quotes(c2):
                if ch in "{}":
                    depth += 1 if ch == "{" else -1; opened = True
            if opened and depth <= 0:
                break
        out[name] = "\n".join(body)
    return out


def sh_trap_order(src, sourced=False):
    """(site line, var, trap line) per GUARDED `mktemp -d` site (sh_scan) that an EXIT trap set BEFORE ITS GUARD'S STOP
    could hurt (#337): a guard's `|| exit` / `set -e` stop runs the EXIT trap in force, and with the site's variable
    empty an action naming "$X/<sub>" or "$X"/* (an `rm`, or a `cp -R "$X"/.`: X, or any `${X...}` expansion such as
    `${X%/}` or `${X:-}`, followed by `/` or `*`) acts on a path under /. The action is the trap's own text plus the body
    of each function of the same file it names, followed through the functions those name (sh_exit_traps). The STOP is
    the site's own line (`|| exit`, `set -e`), or the later `[ -n "$X" ] ||` test's line when that is the guard
    (rule-checker run 2026-10-30-1407: a trap set between the two is in force when the test exits); a trap counts when
    it stands before the stop — an earlier line, or earlier on the stop's line. Every such trap counts, not only the last
    (which one is in force can hang on a branch the text does not decide), and a trap inside a function body counts at
    the place the function is written (the cautious side). A `|| return` guard is read like an exit (also cautious: a
    return runs no trap). The census's limit holds: a lint over shell TEXT, so a trap set through `eval`, or an action
    reaching X through another variable, is not read."""
    traps = sh_exit_traps(src)
    codes = _code_lines(src)
    out, stops = [], {}
    for site, v, guarded in sh_scan(src, sourced, stops):
        if not guarded or v == "-":
            continue
        # the guard's STOP: the site's own line (`|| exit`, `set -e`), or the later `[ -n "$X" ] ||` test's line (run
        # 2026-10-30-1407: a trap set between the site and that test is in force when the test exits)
        stop = stops.get((site, v)) or (site, next((c.find(v + "=") for l, c in codes if l == site), 0))
        ref = re.compile(r"\$(?:" + re.escape(v) + r"\b|\{" + re.escape(v) + r"(?:[^A-Za-z0-9_}][^}]*)?\})\"?(?:/|\*)")
        for tl, tc, text in traps:
            if (tl, tc) < stop and ref.search(text):   # TRAP-BEFORE
                out.append((site, v, tl))
    return out


def _trap_cmds(src):
    """-> (reads, unread). reads: (line, column, action, signals) per `trap` command — every word `trap` outside quotes,
    comments and heredoc bodies that is not an argument (_trap_positions: after a separator, a case arm's `)`, a line's
    start, a keyword or `builtin` / `command` / `exec`) — whose words shlex reads from the source text itself (rule-checker run 2026-10-30-1406: a quoted
    action across physical lines, `trap -- ...`, the `'\\''` idiom); a `trap` alone, `-p` / `-l` or a `-` reset are
    reads that set nothing. unread: (line, why) per such `trap` whose action cannot be read — an unbalanced quote,
    an action that is only a variable (`trap "$CMD" EXIT`), no signal after the action — so THOSE forms are named, not
    skipped. Not named: an EXIT trap whose signal is spelled other than `EXIT` or `0` (`exit`, `SIGEXIT`), read as a
    trap of another signal (rule-checker run 2026-10-30-1411; a stated limit)."""
    phys = src.split("\n")
    codes = _code_lines(src)
    starts = [l for l, _c in codes] + [len(phys) + 1]
    reads, unread = [], []
    for n, (start, code) in enumerate(codes):
        if not re.search(r"\btrap\b", code):
            continue
        end = starts[n + 1] - 1
        span = "\n".join(phys[start - 1:max(end, start)])
        for pos in _trap_positions(_blank_quotes(span.replace("\\\n", "  "))):
            line = start + span.count("\n", 0, pos)
            text = (span[pos:] + "\n" + "\n".join(phys[end:end + 40])).replace("\\\n", " ")
            lx = shlex.shlex(text, posix=True, punctuation_chars=";&|()\n")
            lx.whitespace, lx.whitespace_split = " \t\r", True
            words = []
            try:
                for tok in lx:
                    if tok and set(tok) <= set(";&|()\n"):
                        break
                    words.append(tok)
            except ValueError as e:
                unread.append((line, "the trap's words cannot be read (%s)" % e)); continue
            args = words[1:]
            if args[:1] == ["--"]:
                args = args[1:]
            if not args or args[0] in ("-p", "-l") or args[0] == "-":
                reads.append((line, pos, "", args[1:])); continue
            act, sigs = args[0], args[1:]
            if not sigs:
                unread.append((line, "a trap action with no signal after it")); continue
            if re.fullmatch(r"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?", act.strip()):
                unread.append((line, "the trap's action is only a variable (%s)" % act.strip())); continue
            reads.append((line, pos, act, sigs))
    return reads, unread


def sh_exit_traps(src):
    """(line, column, action text) per EXIT trap (`EXIT` or `0` among its signals, _trap_cmds); the action text is the
    trap's own plus the body of each function DEFINED IN THE SAME FILE that it names, followed through the functions
    those name (a sourced library's function is not followed)"""
    fns = _functions(_code_lines(src))
    traps = []
    for line, col, act, sigs in _trap_cmds(src)[0]:
        if not act or not ({"EXIT", "0"} & set(sigs)):   # a `trap - EXIT` reset, a listing: no action runs
            continue
        seen, text = set(), [act]
        todo = [w for w in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", act) if w in fns]
        while todo:
            f = todo.pop()
            if f in seen:
                continue
            seen.add(f); text.append(fns[f])
            todo += [w for w in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", fns[f]) if w in fns and w not in seen]
        traps.append((line, col, "\n".join(text)))
    return traps


def sh_unguarded(src, sourced=False):
    """(line, var) per `mktemp -d` substitution that carries on when mktemp FAILS (#333): see sh_scan"""
    return [(i, v) for i, v, g in sh_scan(src, sourced) if not g]


RUNNERS_ARG = ("run_replay_mame.sh", "run_replay_guarded.sh")   # [sandbox] is their 4th positional argument
RUNNERS_ENV = {"run_mame.sh": "MAME_SANDBOX", "run_fbneo.sh": "FBNEO_SANDBOX"}
CMD_START = {"&&", "||", ";", "|", "(", "{", "then", "do", "else", "!", "if", "while", "until", "elif"}
CMD_STOP = {"&&", "||", ";", "|", "&", ")", "}", "then", "do", "fi", "done"}
# deliberate calls that use a runner's default sandbox: "path:line-text-fragment": why
ALLOW_CALLS = {}


def collapse_subst(s):
    """every $( ... ) span (nested) and every `...` span becomes one word, so it counts as one argument"""
    out, i = [], 0
    while i < len(s):
        if s.startswith("$(", i):
            depth, j = 1, i + 2
            while j < len(s) and depth:
                depth += {"(": 1, ")": -1}.get(s[j], 0)
                j += 1
            out.append("SUBST"); i = j
        elif s[i] == "`":
            j = s.find("`", i + 1)
            out.append("SUBST"); i = (j + 1) if j > 0 else len(s)
        else:
            out.append(s[i]); i += 1
    return "".join(out)


def runner_calls(path, src):
    """(line, runner, sandboxed) per CALL of an emulator runner in a shell script: the runner is the command word of a
    command (after env assignments, `env`, `timeout N`, `sh`). A replay runner is sandboxed when it gets a 4th
    positional argument; run_mame.sh / run_fbneo.sh when the command's env assigns MAME_SANDBOX / FBNEO_SANDBOX, or
    the script assigns or exports it (#303's emulator half, ruled 2026-10-23: callers pass a sandbox). TMPDIR alone
    does not count: macOS's /usr/bin/mktemp -d with no template ignores it (measured 14z-207). A call through a
    variable ("$GUARDED") or from python is not read."""
    code_lines = src.split("\n")
    file_sets = {env: bool(re.search(rf"^\s*(export\s+)?{env}=|\b{env}=", "\n".join(
        l.split("#", 1)[0] for l in code_lines if not l.lstrip().startswith("#")), re.M)) for env in RUNNERS_ENV.values()}
    out, buf, start = [], "", None
    for i, l in enumerate(code_lines, 1):
        if start is None:
            start = i
        s = l.rstrip()
        if s.endswith("\\"):
            buf += s[:-1] + " "
            continue
        line, buf, ln = buf + s, "", start
        start = None
        if line.lstrip().startswith("#"):
            continue
        try:
            toks = shlex.split(collapse_subst(line), comments=True, posix=True)
        except ValueError:
            continue
        k, at_start = 0, True
        while k < len(toks):
            t = toks[k]
            if t in CMD_START:
                at_start = True; k += 1; continue
            if not at_start:
                if t in CMD_STOP:
                    at_start = True
                k += 1; continue
            envs = []
            while k < len(toks) and re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", toks[k]):
                envs.append(toks[k].split("=", 1)[0]); k += 1
            while k < len(toks) and toks[k] in ("env", "sh", "nice", "exec"):
                k += 1
            if k < len(toks) and toks[k] == "timeout":
                k += 1
                while k < len(toks) and (toks[k].startswith("-") or re.match(r"^\d+[smh]?$", toks[k])):
                    k += 1
            while k < len(toks) and re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", toks[k]):
                envs.append(toks[k].split("=", 1)[0]); k += 1
            if k >= len(toks):
                break
            word = os.path.basename(toks[k])
            at_start = False
            if word in RUNNERS_ARG:
                n, j = 0, k + 1
                while j < len(toks) and toks[j] not in CMD_STOP and not re.match(r"^\d*[<>]", toks[j]):
                    n += 1; j += 1
                out.append((ln, word, n >= 4))
            elif word in RUNNERS_ENV:
                env = RUNNERS_ENV[word]
                out.append((ln, word, env in envs or file_sets[env]))
            k += 1
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("files", nargs="*")
    a = ap.parse_args()
    files = a.files or sorted(
        [os.path.join(d, f) for d in ("tools", "tests", "tests/lib") if os.path.isdir(os.path.join(a.root, d))
         for f in os.listdir(os.path.join(a.root, d)) if f.endswith((".py", ".sh"))])
    bad = n = calls = mk = nt = 0
    for rel in files:
        p = rel if os.path.isabs(rel) else os.path.join(a.root, rel)
        src = open(p, encoding="utf-8", errors="replace").read()
        if p.endswith(".py"):
            try:
                sites = py_sites(p, src)
            except SyntaxError:
                continue
            for line, fn, kind, var, cleaned in sites:
                n += 1
                if not cleaned and f"{rel}:{fn}" not in ALLOW:
                    bad += 1; print(f"UNCLEANED\t{rel}:{line}\t{fn}\t{kind}\t{var or '?'}")
        elif p.endswith(".sh"):
            if os.path.basename(os.path.dirname(p)) in ("tests", "tools", "lib"):
                lib = os.path.basename(os.path.dirname(p)) == "lib"   # a sourced library: its top-level `return` returns
                mk += len(sh_scan(src, lib))   # the substitutions the scan READ (a file it is blinded in shows here)
                nt += len(sh_exit_traps(src))  # and the EXIT traps the trap-order check read (#337)
                for line, why in _trap_cmds(src)[1]:
                    bad += 1; print(f"UNREADTRAP\t{rel}:{line}\tshell\ttrap\t-\t{why}: the trap-order check cannot see it (#337)")
                for line, var in sh_unguarded(src, lib):
                    bad += 1; print(f"UNGUARDED\t{rel}:{line}\tshell\tmktemp -d\t{var}\ta failed mktemp carries on with ${var} empty (#333)")
                for line, var, tl in sh_trap_order(src, lib):
                    bad += 1; print(f"TRAPPED\t{rel}:{line}\tshell\tmktemp -d\t{var}\tthe EXIT trap set at line {tl}, before the "
                                    f"site, names \"${var}/...\": a failed mktemp stops into it with ${var} empty (#337)")
            if os.path.basename(os.path.dirname(p)) in ("tests", "tools"):
                for line, var, cleaned in sh_sites(p, src):
                    n += 1
                    if not cleaned and f"{rel}:{var}" not in ALLOW:
                        bad += 1; print(f"UNCLEANED\t{rel}:{line}\tshell\tmktemp\t{var}")
            if os.path.basename(p) in RUNNERS_ARG or os.path.basename(p) in RUNNERS_ENV:
                continue
            for line, runner, sandboxed in runner_calls(p, src):
                calls += 1
                if not sandboxed and not any(rel + ":" + str(line) == k for k in ALLOW_CALLS):
                    bad += 1; print(f"UNSANDBOXED\t{rel}:{line}\t{runner}\tthe call passes no sandbox, so the runner's default outlives it")
    print(f"{n} temp maker(s) and {calls} emulator-runner call(s) read; {bad} not removed at exit, passing no sandbox or "
          f"carrying on after a failed mktemp -d or stopping into an EXIT trap set before it ({mk} mktemp -d "
          f"substitution(s) and {nt} EXIT trap(s) read)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
