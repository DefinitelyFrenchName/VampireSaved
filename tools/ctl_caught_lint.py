#!/usr/bin/env python3
"""ctl_caught_lint.py — #369's static lint (14z-224; maintainer-ruled 2026-11-08 "A1, B1, c1").

A control mode is HONOURED only on `CONTROL CAUGHT: <mode> — <line>`, printed by tests/lib/controls.sh vs_ctl_caught
from the gate's main check output (tests/lib/classify.sh). This lint holds what the run-time rule cannot see:

  [a] `CONTROL CAUGHT` is printed only through the helper: no CODE file under tests/ or tools/, at any depth
      (code_files: a code extension or a `#!` line), carries the literal outside the helper, the classifier and this lint
      (ALLOW_LITERAL); the ground-truth gates that write synthetic logs
      (GROUND_TRUTH) may carry it, but never `CONTROL CAUGHT:` in an echo or printf statement (also /bin/echo, after
      `VAR=x`, `env`, `exec` or a glued `(`) whose output an unquoted `>`/`>>` does not send to a file (/dev/stdout,
      /dev/stderr, /dev/fd/N and /dev/tty are not files: they reach the mode's log), nor on a line that begins with it
      (direct_prints). THE STATED LIMIT (maintainer, 2026-11-09: "Land with a stated limit (Recommended)"): in those six
      files the lint covers echo or printf written on one line; any other printer (awk, cat of a file, tee) and a line
      assembled at run time are review, not lint. BEYOND THAT RULING, stated by the session and
      accepted by the maintainer 2026-11-09 (14z-225: "(a) Accept them as stated limits."): THE READER IS TEXTUAL — it reads each statement as written, never as the shell evaluates it — so a
      one-line echo or printf it mis-splits (a `>` in a trailing comment read as a redirect), a redirect target held in a
      variable (`>> "$OUT"`, read as a file), a later redirect that overrides an earlier one (`>/dev/null 1>&2`, the first
      one read), eval, aliases and functions pass it (rule-checker runs 2026-11-09-1748 and -1749);
  [b] no vs_ctl_caught call whose ERE is missing or a catch-all ('', '.', '.*', 'FAIL', '^FAIL', '^ *FAIL');
  [c] no gate off the debt list calls vs_ctl_fired with the mode variable ($VS_CTL, $CONTROL) as its name;
  [d] every gate that declares a MUST-FIRE mode calls vs_ctl_caught, unless it is on the debt list;
  [e] in a gate off the debt list with more than one mode, every vs_ctl_caught ERE is computed per mode (holds a `$`);
  [debt] tests/expected/ctl_caught_debt.tsv only shrinks: each row names one gate, once, that exists, declares a mode,
      does not call vs_ctl_caught yet, existed at the base commit (a new gate never joins the list), and is in --allowed:
      the rows of the list's first version and of every committed version since (a deleted row never comes back).

NOT held here, by design (named in docs/project/must_fire_contract.md § #369): a vs_ctl_caught call handed a file other
than the main check's output, and a per-mode ERE that still matches any failure of the check. Both are review. Nor, in
ANY file, a literal assembled at run time (split, formatted, built in a variable): rule [a] reads the literal written
whole; nor code outside tests/ and tools/, nor a data file (a fixture, a kept log) that something executes or a gate
prints into a mode's log. Nor,
in a GROUND_TRUTH gate, any printer but echo/printf (awk, cat of a file, tee), a line assembled at run time (the literal
split, or built in a variable, a function, a command substitution or a format) and then printed (the stated limit
above), nor what the textual reader mis-reads (stated by the session, above).

Usage: ctl_caught_lint.py --root DIR --decl FILE --base FILE --allowed FILE
  --root  the tree to lint (DIR/tests/*.sh are the gates; DIR/tests/lib, DIR/tools are scanned for [a])
  --decl  `<gate basename>\t<mode>` rows, from tests/lib/controls.sh vs_ctl_declared (the one grammar reader)
  --base  the gate basenames present at the base commit, one per line
  --allowed  the rows the list may hold: the intersection of its first version and every committed version since
Prints `  FAIL  [rule] <path>[:line]: <what>` per finding, then NOTE lines; exits 1 on any finding, 0 otherwise.
"""
import argparse
import os
import re
import shlex
import sys

DEBT = 'tests/expected/ctl_caught_debt.tsv'
BASE_COMMIT = '8464fa3f'
ALLOW_LITERAL = {   # files that may carry the literal `CONTROL CAUGHT` anywhere, and why
    'tests/lib/controls.sh',            # the one printer (vs_ctl_caught) and the plain-run check
    'tests/lib/classify.sh',            # the one reader
    'tools/ctl_caught_lint.py',          # this file
}
GROUND_TRUTH = {    # files that may carry it in synthetic logs and stubs, never printed to their own stdout
    'tests/test_control_classifier.sh',  # synthetic mode logs: the classifier's ground truth
    'tests/test_controls_contract.sh',   # synthetic logs: the helpers' ground truth
    'tests/test_ctl_caught_lint.sh',     # this lint's planted gates
    'tests/test_static_runner.sh',       # stub gates: the runners' ground truth (a CAUGHT line beside a crash)
    'tests/test_emulator_runner.sh',     # as above
    'tests/test_controls_concurrent.sh', # synthetic control logs for the overlap scorer's ground truth
}
CATCH_ALL = {'', '.', '.*', 'FAIL', '^FAIL', '^ *FAIL'}
# a call is the helper's name at a COMMAND position (line start, or after ; & | ( { then else do); the same word inside
# a quoted message or a planted string is not a call
CMD = r'(?:^|[;&|({]|\bthen|\belse|\bdo)\s*'
CALL = re.compile(CMD + r'vs_ctl_caught(?![A-Za-z0-9_(])')
# A GROUND-TRUTH gate's direct print: a shell statement (split on unquoted ; & | and newline) whose command word is
# echo or printf, whose text carries `CONTROL CAUGHT:` anywhere (in any quote, any position: the format string or an
# argument), and whose stdout is not redirected to a file by an unquoted `>`/`>>` (a `>&2` or `2>` is not: mode logs are
# captured with 2>&1). Rule-checker runs 2026-11-09-1743 and -1744: a `>` inside the message, a `>&2` and a
# `printf '%s\n' "..."` each passed the regex this replaced.
LITERAL = 'CONTROL CAUGHT:'
PREFIX_WORDS = {'then', 'else', 'do', '{', '(', '!', 'if', 'elif', 'while', 'until', 'command', 'builtin', 'exec',
                'env', 'nohup', 'time'}
ASSIGN = re.compile(r'[A-Za-z_][A-Za-z0-9_]*=')


def statements(line):
    """Split `line` on unquoted ; & | (and && ||; not the & of >&, &>), yielding (text, unquoted-mask) per statement."""
    out, cur, mask, q, esc = [], [], [], None, False
    for n, ch in enumerate(line):
        if q is None:
            redir_amp = ch == '&' and ((n and line[n - 1] == '>') or line[n + 1:n + 2] == '>')   # >&2, 2>&1, &>
            if ch in ';&|' and not redir_amp:
                out.append((''.join(cur), mask)); cur, mask = [], []
                continue
            cur.append(ch); mask.append(True)
            if ch in '\'"':
                q = ch
                mask[-1] = False
        else:
            cur.append(ch); mask.append(False)
            if q == '"' and esc:
                esc = False
            elif q == '"' and ch == '\\':
                esc = True
            elif ch == q:
                q = None
    out.append((''.join(cur), mask))
    return out


def stdout_to_file(text, mask):
    """True when an unquoted `>`/`>>` (fd 1 or none, or &> both) sends stdout to a file, not to another fd."""
    k = 0
    while k < len(text):
        if text[k] == '>' and mask[k]:
            prev = text[k - 1] if k else ' '
            if prev.isdigit() and prev != '1':
                k += 1
                continue
            m = k + 1
            if m < len(text) and text[m] == '>':
                m += 1
            while m < len(text) and text[m] in ' \t':
                m += 1
            if m < len(text) and text[m] != '&':
                tgt = text[m:].split()[0].strip('"\'') if text[m:].split() else ''
                if not tgt.startswith('/dev/') or tgt == '/dev/null':   # /dev/stdout, /dev/stderr, /dev/fd/N, /dev/tty
                    return True                                          # reach the mode's log (captured with 2>&1)
            k = m
        k += 1
    return False


def direct_prints(line):
    """True when `line` holds a statement that prints the literal to its own stdout (see above), or BEGINS with the
    literal: such a line is the body of a multi-line string or a heredoc, which this line-at-a-time reader cannot follow
    to its redirect, so it is refused (a heredoc to a file is refused too: write the line with printf ... > file)."""
    if line.lstrip().startswith(LITERAL):
        return True
    for text, mask in statements(line):
        if LITERAL not in text:
            continue
        words = text.split()
        while words:
            w = words[0].lstrip('({!')                    # `(echo`, `{echo` glued to its opener
            if not w or w in PREFIX_WORDS or ASSIGN.match(w) or (w.endswith(')') and '(' not in w):
                words = words[1:]                         # a keyword, `VAR=x`, or a case pattern `pat)`
                continue
            words[0] = w
            break
        if words and words[0].rsplit('/', 1)[-1] in ('echo', 'printf') and not stdout_to_file(text, mask):
            return True
    return False
FIRED_MODE_VAR = re.compile(CMD + r'vs_ctl_fired\s+"?\$\{?(VS_CTL|CONTROL)(?![A-Za-z0-9_])')


CODE_EXT = ('.sh', '.py', '.lua', '.mjs', '.js', '.awk', '.pl', '.rb', '.bat', '.ps1', '.tcl')
SKIP_DIRS = {'.git', '__pycache__', 'node_modules'}


def code_files(root):
    """Every CODE file under tests/ and tools/, at any depth (rule-checker run 2026-11-09-1746): a code extension, or a
    first line starting `#!`. Data files (expectations, logs, rule-checker packets, .tsv/.txt/.md) are not executed and
    not read."""
    out = []
    for top in ('tests', 'tools'):
        for d, dirs, files in os.walk(os.path.join(root, top)):
            dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
            for f in sorted(files):
                p = os.path.join(d, f)
                rel = os.path.relpath(p, root)
                if f.endswith(CODE_EXT):
                    out.append(rel)
                    continue
                try:
                    with open(p, 'rb') as fh:
                        if fh.read(2) == b'#!':
                            out.append(rel)
                except OSError:
                    pass
    return out


def code_lines(path):
    """(line number, text) of every line that is not a comment line."""
    with open(path, encoding='utf-8', errors='replace') as f:
        for n, line in enumerate(f, 1):
            if line.lstrip().startswith('#'):
                continue
            yield n, line.rstrip('\n')


def caught_calls(path):
    """(line, args) of each vs_ctl_caught call; args None when the call cannot be parsed."""
    out = []
    for n, line in code_lines(path):
        for m in CALL.finditer(line):
            rest = line[m.end():]
            try:
                lex = shlex.shlex(rest, posix=True, punctuation_chars=';&|()')
                lex.whitespace_split = True
                lex.commenters = ''
                args = []
                for tok in lex:
                    if tok and set(tok) <= set(';&|()'):
                        break
                    args.append(tok)
            except ValueError:
                args = None
            out.append((n, args))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', required=True)
    ap.add_argument('--decl', required=True)
    ap.add_argument('--base', required=True)
    ap.add_argument('--allowed', required=True)
    a = ap.parse_args()
    root = a.root
    findings = []

    def bad(rule, where, what):
        findings.append(f'  FAIL  [{rule}] {where}: {what}')

    decl = {}
    with open(a.decl, encoding='utf-8') as f:
        for row in f:
            row = row.rstrip('\n')
            if row:
                g, mode = row.split('\t')
                decl.setdefault(g, []).append(mode)
    with open(a.base, encoding='utf-8') as f:
        base = {l.strip() for l in f if l.strip()}
    with open(a.allowed, encoding='utf-8') as f:
        allowed = {l.strip() for l in f if l.strip()}

    debt, seen = [], set()
    dpath = os.path.join(root, DEBT)
    if not os.path.isfile(dpath):
        bad('debt', DEBT, 'the debt list is missing')
    else:
        with open(dpath, encoding='utf-8') as f:
            for n, row in enumerate(f, 1):
                row = row.rstrip('\n')
                if row.startswith('#'):
                    continue
                if not re.fullmatch(r'[A-Za-z0-9_.-]+\.sh', row):
                    bad('debt', f'{DEBT}:{n}', f'not one gate basename: {row!r}')
                    continue
                if row in seen:
                    bad('debt', f'{DEBT}:{n}', f'{row} is listed twice')
                seen.add(row)
                debt.append((n, row))

    gates = sorted(x for x in os.listdir(os.path.join(root, 'tests')) if x.endswith('.sh'))
    calls = {g: caught_calls(os.path.join(root, 'tests', g)) for g in gates}
    listed = {g for _, g in debt}

    for n, g in debt:
        where = f'{DEBT}:{n}'
        if g not in gates:
            bad('debt', where, f'{g} is not a gate in tests/ (gone: delete the row)')
            continue
        if not decl.get(g):
            bad('debt', where, f'{g} declares no MUST-FIRE mode (delete the row)')
        if calls[g]:
            bad('debt', where, f'{g} calls vs_ctl_caught at line {calls[g][0][0]}: migrated, so delete the row')
        if g not in base:
            bad('debt', where, f'{g} did not exist at {BASE_COMMIT}: a new gate never joins the list (migrate it instead)')
        if g not in allowed:
            bad('debt', where, f'{g} is not on every earlier version of the list: the list never grows (migrate it instead)')

    for g in gates:
        p = os.path.join(root, 'tests', g)
        rel = f'tests/{g}'
        modes = decl.get(g, [])
        if g in listed:
            continue
        if modes and not calls[g]:
            bad('d', rel, f'declares {len(modes)} mode(s) and never calls vs_ctl_caught, and is not on {DEBT}')
        for n, line in code_lines(p):
            if FIRED_MODE_VAR.search(line):
                bad('c', f'{rel}:{n}', 'vs_ctl_fired names the mode variable: under a mode only vs_ctl_caught is evidence')
        for n, args in calls[g]:
            if args is None:
                bad('b', f'{rel}:{n}', 'a vs_ctl_caught call this lint cannot parse (keep it on one line)')
                continue
            if args == ['$@']:   # a wrapper forwarding its own arguments (a ground-truth stub)
                continue
            if len(args) < 2:
                bad('b', f'{rel}:{n}', f'vs_ctl_caught is given no finding to look for (args {args})')
                continue
            ere = args[1]
            if ere.strip() in CATCH_ALL or ere in CATCH_ALL:
                bad('b', f'{rel}:{n}', f'vs_ctl_caught is given the catch-all ERE {ere!r}')
            elif len(modes) > 1 and '$' not in ere:
                bad('e', f'{rel}:{n}', f'{len(modes)} modes share the fixed ERE {ere!r}: compute it per mode')

    scan = code_files(root)
    for rel in scan:
        if rel in ALLOW_LITERAL:
            continue
        for n, line in code_lines(os.path.join(root, rel)):
            if 'CONTROL CAUGHT' not in line:
                continue
            if rel not in GROUND_TRUTH:
                bad('a', f'{rel}:{n}', 'prints the CONTROL CAUGHT literal: only tests/lib/controls.sh vs_ctl_caught may')
            elif direct_prints(line):
                bad('a', f'{rel}:{n}', 'a ground-truth gate prints the CONTROL CAUGHT literal to its own stdout: '
                    'only tests/lib/controls.sh vs_ctl_caught may')

    for line in findings:
        print(line)
    mode_gates = sum(1 for g in gates if decl.get(g))
    migrated = sum(1 for g in gates if decl.get(g) and g not in listed)
    print(f'NOTE: ctl_caught.debt_gates {len(debt)}')
    print(f'NOTE: ctl_caught.migrated_gates {migrated}/{mode_gates}')
    print(f'{"FAIL" if findings else "PASS"}: ctl_caught_lint — {len(findings)} finding(s); '
          f'{len(gates)} gates, {mode_gates} declare modes, {migrated} migrated, {len(debt)} on the debt list')
    return 1 if findings else 0


if __name__ == '__main__':
    sys.exit(main())
