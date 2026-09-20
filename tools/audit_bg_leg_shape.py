#!/usr/bin/env python3
"""audit_bg_leg_shape.py — THE UNSAFE BACKGROUNDED-EMULATOR-LEG SHAPE (14z-171).

  python3 tools/audit_bg_leg_shape.py [tests_dir] [--json out] [--verbose]

WHAT IT BARS. A gate that backgrounds an emulator leg in a subshell and then
writes that leg's exit status into a file:

    ( cd "$d" && "$REPO/tools/run_mame.sh" vsavjw ... > mame.log 2>&1
      echo $? > "$d/rc" ) &                       # <-- UNSAFE under set -e

Under the script's own `set -e` the subshell DIES on the emulator's non-zero
exit, so `echo $? > rc` never runs and the waiting parent reads NO status at
all. MAME segfaults at TEARDOWN often enough for this to matter — after the
instrument has closed its log — so the leg's artifacts are COMPLETE while its
status file is absent, and the parent reports `exited none` on a good run
(paid 14z-168, `docs/platform/gotchas.md`; the first scripted repair then put
`set +e` on the WRONG subshell in three gates, which a green run cannot show).

THE SAFE SHAPE is the one the repaired gates use — `set +e` FIRST, inside the
group, so the status write is always reached:

    ( set +e; cd "$d" && "$REPO/tools/run_mame.sh" ... > mame.log 2>&1
      _st=$?; grep -q '^END ' out && _st=0; echo $_st > "$d/rc" ) </dev/null &

A group that captures no status at all is NOT flagged: it has no status to
lose and its verdict comes from its artifacts.

HOW IT PARSES. Shell is not parsed, it is BALANCED: every line whose tail
closes a group and backgrounds it (`) ... &`, never `&&`) is walked BACKWARD
by paren delta — `$( )`, quotes and comments excluded — until the group opens.
A group that cannot be balanced is reported UNRESOLVED and FAILS, because a
parser that silently skips what it cannot read measures nothing ([VSP-148]).

MEASURED at birth over tests/: 103 groups, 0 unresolved, 99 running an
emulator wrapper, 22 of those capturing a status and ALL 22 already safe.
So this is a FORWARD guard: it holds the 14z-168 repair in place.
"""
import glob
import json
import os
import re
import sys

EMU = re.compile(r'run_mame\.sh|run_replay_mame\.sh|run_replay_guarded\.sh'
                 r'|run_inp_guarded\.sh|run_replay_fbneo\.sh')
STATUS = re.compile(r'\$\?')
CLOSE = re.compile(r'\)[^)&]*&\s*$')
NOTAND = re.compile(r'&&\s*$')
SET_E = re.compile(r'^\s*set\s+-[a-z]*e')
SET_PLUS_E = re.compile(r'set\s+\+[a-z]*e')


def delta(line):
    """Paren balance of one line, ignoring $(...), quoted text and comments."""
    out, i, n, quote = 0, 0, len(line), None
    while i < n:
        c = line[i]
        if quote:
            if c == '\\' and quote == '"':
                i += 2
                continue
            if c == quote:
                quote = None
            i += 1
            continue
        if c in "'\"":
            quote = c
            i += 1
            continue
        if c == '#' and (i == 0 or line[i - 1].isspace()):
            break
        if c == '$' and i + 1 < n and line[i + 1] == '(':
            i += 2
            d = 1
            while i < n and d:
                if line[i] == '(':
                    d += 1
                elif line[i] == ')':
                    d -= 1
                i += 1
            continue
        if c == '(':
            out += 1
        elif c == ')':
            out -= 1
        i += 1
    return out


def scan(tests_dir):
    groups, unresolved = [], []
    for path in sorted(glob.glob(os.path.join(tests_dir, "*.sh"))):
        with open(path, encoding="utf-8", errors="replace") as fh:
            src = fh.read().splitlines()
        errexit = any(SET_E.match(l) for l in src)
        for j, line in enumerate(src):
            if not CLOSE.search(line) or NOTAND.search(line):
                continue
            bal, k = delta(line), j
            while bal < 0 and k > 0:
                k -= 1
                bal += delta(src[k])
            if bal != 0:
                unresolved.append({"file": path, "line": j + 1})
                continue
            body = "\n".join(src[k:j + 1])
            groups.append({
                "file": path, "line": j + 1, "open": k + 1,
                "errexit": errexit,
                "emulator": bool(EMU.search(body)),
                "captures_status": bool(STATUS.search(body)),
                "set_plus_e": bool(SET_PLUS_E.search(body)),
            })
    return groups, unresolved


def main(argv):
    tests_dir = "tests"
    out_json, verbose = None, False
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--json":
            i += 1
            out_json = argv[i]
        elif a == "--verbose":
            verbose = True
        elif a.startswith("--"):
            sys.exit("unknown option %s" % a)
        else:
            tests_dir = a
        i += 1

    groups, unresolved = scan(tests_dir)
    emu = [g for g in groups if g["emulator"]]
    status = [g for g in emu if g["captures_status"]]
    risky = [g for g in status if g["errexit"] and not g["set_plus_e"]]

    print("backgrounded groups: %d   unresolved: %d" % (len(groups), len(unresolved)))
    print("  running an emulator wrapper: %d" % len(emu))
    print("  of those capturing a status: %d   already safe (set +e): %d"
          % (len(status), len([g for g in status if g["set_plus_e"]])))
    print("  RISKY: %d" % len(risky))
    for g in risky:
        print("    %s:%d — backgrounded emulator leg captures $? under set -e "
              "with no `set +e` in the group (opens at line %d)"
              % (g["file"], g["line"], g["open"]))
    for u in unresolved:
        print("    UNRESOLVED %s:%d — the group could not be balanced; the "
              "parser is blind here, which is a FAIL, not a skip"
              % (u["file"], u["line"]))
    if verbose:
        for g in emu:
            print("    %s:%d emu status=%s set+e=%s"
                  % (g["file"], g["line"], g["captures_status"], g["set_plus_e"]))
    if out_json:
        with open(out_json, "w", encoding="utf-8") as fh:
            json.dump({"groups": groups, "unresolved": unresolved,
                       "risky": risky}, fh, indent=1)
    return 1 if (risky or unresolved) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
