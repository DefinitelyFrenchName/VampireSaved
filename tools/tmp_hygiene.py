#!/usr/bin/env python3
"""tmp_hygiene.py — every temporary directory or file a tool or gate makes is removed when its maker exits (#303, 14z-207).

A static census, read without running anything:
  PYTHON (tools/*.py, tests/*.py, tests/lib/*.py): every tempfile.mkdtemp(), tempfile.mkstemp() and
    NamedTemporaryFile(..., delete=False) must be CLEANED: its assigned name is passed to atexit.register(...) on the
    same statement line, or removed (shutil.rmtree / os.remove / os.unlink / .unlink()) in the same function, or the
    site is in ALLOW below with the reason it outlives its maker. A context-managed TemporaryDirectory() is clean.
  SHELL (tests/*.sh, tools/*.sh): every `X="$(mktemp ...)"` must be removed by a trap on EXIT in the same script that names "$X".
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
    bad = n = calls = 0
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
    print(f"{n} temp maker(s) and {calls} emulator-runner call(s) read; {bad} not removed at exit or passing no sandbox")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
