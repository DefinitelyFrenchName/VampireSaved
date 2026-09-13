#!/usr/bin/env python3
"""record_build_environment.py — compose one entry of docs/project/build_environments.md
from what a host MEASURED: the BINARY.txt records tools/build_release_emulators.sh wrote
(their `built`, `tree`, `jobs` and `env` lines) and the log of
tests/test_release_binaries.sh that PASSED on the same host.

Usage: tools/record_build_environment.py <os-arch> <gate.log> <BINARY.txt> [<BINARY.txt> ...]

Prints the entry (markdown) on stdout. REFUSES, exit 2, when the gate log has no
`PASS: test_release_binaries (<os-arch>)` line, when a record is for another os-arch,
or when a record carries no `env` line — an entry rests on a capture, never on memory
(the maintainer's minimum bar, 2026-09-13: "knowing in what exact circumstances is the
build known to be a success").
"""
import os
import re
import sys


def refuse(msg):
    print(f"REFUSED: {msg}")
    sys.exit(2)


def parse_record(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    lines = text.splitlines()
    rec = {"path": path, "env": []}
    m = re.match(r"^(\S+) — .* prebuilt for (\S+)\s*$", lines[0] if lines else "")
    if not m:
        refuse(f"{path}: the first line does not name the binary and its os-arch")
    rec["kind"], rec["osarch"] = m.group(1), m.group(2)
    for line in lines:
        key, _, val = line.partition(" ")
        val = val.strip()
        if key in ("pin", "tree", "jobs"):
            rec[key] = val
        elif key == "patch":
            s = re.search(r"sha1 ([0-9a-f]{40})", val)
            rec["patch"] = s.group(1) if s else "?"
        elif key == "built":
            b = re.match(r"^(\S+) on (.*), by ", val)
            rec["date"], rec["host"] = (b.group(1), b.group(2)) if b else ("?", val)
        elif key == "env":
            rec["env"].append(val)
    if not rec["env"]:
        refuse(f"{path}: no `env` line — this record predates the environment capture, so an "
               f"entry from it would rest on memory")
    return rec


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__.split("\n\n")[1])
    osarch, gatelog, paths = sys.argv[1], sys.argv[2], sys.argv[3:]
    log = open(gatelog, encoding="utf-8", errors="replace").read()
    passline = f"PASS: test_release_binaries ({osarch})"
    if passline not in log.splitlines():
        refuse(f"{gatelog} has no `{passline}` line — only a host where the gate PASSED is an entry")
    recs = [parse_record(p) for p in paths]
    for r in recs:
        if r["osarch"] != osarch:
            refuse(f"{r['path']} is a record for {r['osarch']}, not {osarch}")
    names = {"fbneo": "FBNeo", "cps2": "MAME"}
    kinds = " + ".join(names.get(r["kind"], r["kind"]) for r in recs)
    dates = sorted({r["date"] for r in recs})
    system = [e for e in recs[0]["env"] if not re.match(r"^(brew|dpkg|pacman) ", e)]
    pkgs, seen = [], {}
    for r in recs:
        for e in r["env"]:
            m = re.match(r"^(brew|dpkg|pacman) (\S+) (.+)$", e)
            if m:
                seen.setdefault((m.group(1), m.group(2)), set()).add(m.group(3))
    for (mgr, pkg), vers in sorted(seen.items()):
        pkgs.append(f"{mgr} `{pkg}` {' / '.join(sorted(vers))}")
    out = [f"### {osarch} — {kinds}, built {', '.join(dates)}", "", "| | |", "|---|---|"]
    out.append(f"| host | {recs[0]['host']} |")
    if system:
        out.append(f"| system | {'; '.join(system)} |")
    out.append(f"| packages | {', '.join(pkgs)} |")
    out.append("| emulators | " + "; ".join(
        f"{names.get(r['kind'], r['kind'])} `{r.get('pin', '?')[:12]}`, patch sha1 `{r.get('patch', '?')[:8]}`" for r in recs) + " |")
    out.append("| built from | " + "; ".join(
        f"{names.get(r['kind'], r['kind'])} tree `{r.get('tree', '?')}`, jobs {r.get('jobs', '?')}" for r in recs) + " |")
    out.append(f"| gate | `{passline}` ({os.path.basename(gatelog)}) |")
    print("\n".join(out))


if __name__ == "__main__":
    main()
