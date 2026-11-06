#!/usr/bin/env python3
"""signal_traps.py — a shell script that traps INT, TERM, HUP or QUIT must END in that trap (#359, 14z-221c).

A POSIX shell runs a signal trap's action and then RESUMES the script after the command it interrupted; only an `exit`
in the action ends it. So `trap '<cleanup>' EXIT INT TERM` — 228 traps in 221 files at a152efa7 — let a gate that a
runner's timeout(1) sent TERM run its cleanup and then KEEP RUNNING, its work directory already removed, after the
runner had recorded TIMEOUT (measured 14z-218 on macOS /bin/sh and PILOT's dash and bash; docs/platform/gotchas.md).
The form this census accepts keeps the cleanup on EXIT alone and ends on the signal with 128 + its number, which runs
that EXIT trap once:   trap '<cleanup>' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM

A static census, read without running anything, of every SHELL file (`.sh` / `.bash`, or a sh-family shebang) under
tests/ and tools/ — the tracked ones when --root is a git checkout's top, else every file under it — except
tests/rulecheck/ (rule-checker packets: frozen copies of gates as they stood, data, never run). Each `trap` command is
read by tools/tmp_hygiene.py's reader (_trap_cmds: quotes, comments, heredoc bodies, continuations and quoted actions
across lines handled). For a trap whose signal list names INT, TERM, HUP or QUIT (by name, SIG-prefixed, or number):
  RESUMES   its action — its own text, plus the body of each function of the same file it names, followed through the
            functions those name — runs no `exit` (outside quotes): the script carries on after the signal;
  EXITS0    its action's exit is a bare `exit` or `exit 0`: the script ends, but with the status of its last command
            or 0, so a TERM'd gate can exit 0 (a runner that reads the status before its own timeout would see PASS);
  UNREAD    tmp_hygiene could not read the trap's words (an unbalanced quote, an action that is only a variable): the
            census cannot say, so it is named.
The signal list ends at its first word that is no signal name (the reader can run on past a trailing comment).
THE LIMIT: a lint over shell TEXT, not a shell interpreter — a trap set through `eval`, an action reaching its exit
through a sourced library's function, or one written in another language's string (a .py writing a script) is not
read. A trap on EXIT alone is never named: it runs once, at the end.

Usage: signal_traps.py [--root DIR] [--extra FILE ...]   exit 1 when any trap is named; the last line is the count.
"""
import argparse, os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tmp_hygiene as th  # noqa: E402  (the trap reader; read-only use)

STOPPING = {"HUP", "INT", "QUIT", "TERM", "1", "2", "3", "15"}
SIGNAMES = {"EXIT", "HUP", "INT", "QUIT", "ILL", "TRAP", "ABRT", "IOT", "EMT", "FPE", "KILL", "BUS", "SEGV", "SYS",
            "PIPE", "ALRM", "TERM", "URG", "STOP", "TSTP", "CONT", "CHLD", "CLD", "TTIN", "TTOU", "IO", "POLL", "XCPU",
            "XFSZ", "VTALRM", "PROF", "WINCH", "INFO", "PWR", "USR1", "USR2", "ERR", "DEBUG", "RETURN", "STKFLT"}
SKIP_PREFIX = ("tests/rulecheck/",)
SHEBANG = re.compile(r"#!.*\b(?:ba|da|z|k)?sh\b")
EXIT_CMD = re.compile(r"(?:^|[\s;&|({])exit(?=$|[\s;&|)}])(?:[ \t]+(\S+))?")


def signal_words(sigs):
    """the leading words of a trap's argument list that are signal names, normalised (SIG prefix dropped)"""
    out = []
    for s in sigs:
        u = s[3:] if s.upper().startswith("SIG") and s[3:] else s
        if not (u.isdigit() or (u == u.upper() and u in SIGNAMES)):
            break
        out.append({"0": "EXIT"}.get(u, u))
    return out


def shell_files(root):
    top = None
    try:
        top = subprocess.run(["git", "-C", root, "rev-parse", "--show-toplevel"], capture_output=True, text=True,
                             timeout=60).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    if top and os.path.realpath(top) == os.path.realpath(root):
        rels = subprocess.run(["git", "-C", root, "ls-files", "--", "tests", "tools"], capture_output=True, text=True,
                              check=True, timeout=120).stdout.split("\n")
    else:
        rels = []
        for d in ("tests", "tools"):
            for dp, dns, fns in os.walk(os.path.join(root, d)):
                dns[:] = [x for x in dns if x != "__pycache__"]
                rels += [os.path.relpath(os.path.join(dp, f), root) for f in fns]
    out = []
    for rel in sorted(r for r in rels if r):
        rel = rel.replace(os.sep, "/")
        if rel.startswith(SKIP_PREFIX):
            continue
        p = os.path.join(root, rel)
        if not os.path.isfile(p):
            continue
        if rel.endswith((".sh", ".bash")):
            out.append(rel); continue
        try:
            with open(p, "rb") as fh:
                first = fh.readline(200).decode("utf-8", "replace")
        except OSError:
            continue
        if SHEBANG.match(first):
            out.append(rel)
    return out


def check(rel, src):
    """-> (named, n_traps, n_signal_traps); named: (tag, line, signals, action) per trap that fails the rule"""
    if "trap" not in src:
        return [], 0, 0
    reads, unread = th._trap_cmds(src)
    named = [("UNREAD", line, "-", why) for line, why in unread]
    fns = th._functions(th._code_lines(src))
    nsig = 0
    for line, _col, act, sigs in reads:
        sw = signal_words(sigs)
        if not act or not (set(sw) & STOPPING):
            continue                                   # a reset / listing, or no stopping signal
        nsig += 1
        if act.strip() == "":
            continue                                   # `trap '' INT`: the signal is ignored, nothing resumes
        seen, text = set(), [act]
        todo = [w for w in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", act) if w in fns]
        while todo:
            f = todo.pop()
            if f in seen:
                continue
            seen.add(f); text.append(fns[f])
            todo += [w for w in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", fns[f]) if w in fns and w not in seen]
        exits = [m.group(1) for m in EXIT_CMD.finditer(th._blank_quotes("\n".join(text)))]
        short = act.replace("\n", "\\n")[:100]
        if not exits:
            named.append(("RESUMES", line, " ".join(sw), short))
        elif any(e is None or e == "0" for e in exits):
            named.append(("EXITS0", line, " ".join(sw), short))
    return named, len(reads), nsig


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--extra", nargs="*", default=[], help="further files to read (a control's planted script)")
    a = ap.parse_args()
    files = shell_files(a.root)
    bad = nt = ns = 0
    for rel in files + a.extra:
        p = rel if os.path.isabs(rel) else os.path.join(a.root, rel)
        src = open(p, encoding="utf-8", errors="replace").read()
        named, t, s = check(rel, src)
        nt += t; ns += s
        for tag, line, sigs, what in named:
            bad += 1
            why = {"RESUMES": "its action runs no exit: the script resumes after the signal",
                   "EXITS0": "its exit names no non-zero status: a signalled script can exit 0",
                   "UNREAD": "the census cannot read it"}[tag]
            print(f"{tag}\t{rel}:{line}\t[{sigs}]\t{what}\t{why} (#359)")
    print(f"{len(files) + len(a.extra)} shell file(s), {nt} trap command(s) read, {ns} on INT/TERM/HUP/QUIT; "
          f"{bad} named")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
