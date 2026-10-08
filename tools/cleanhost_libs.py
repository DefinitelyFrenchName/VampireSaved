#!/usr/bin/env python3
"""cleanhost_libs.py — which host libraries did a release package ASK FOR at run time?

Usage: tools/cleanhost_libs.py <ld_debug log> <package dir as seen in the run> <host-provided.tsv> [--drop SONAME]

Reads one process's `LD_DEBUG=libs` log (glibc 2.39 form) from a run of a Linux release binary on a
CLEAN host (tests/audit_release_linux_cleanhost.sh) and judges, for every library search:

  C1  a search made through a PACKAGE file's RUNPATH (the "(RUNPATH from file <pkg>/...)" line names
      the package) that resolved OUTSIDE the package asked the HOST for that soname, so the soname
      must be on the host-provided list — this sees the libraries SDL loads with dlopen, which the
      static check (tools/check_host_libs.py, DT_NEEDED only) cannot;
  C2  every search resolves: its last `trying file=` that was then initialised (`calling init:`).

Libraries brought in by HOST libraries (Mesa's, PulseAudio's own dependencies) are the host's
business and are only counted. --drop removes one soname from the list (the gate's control: a list
missing a library the run asked for must fail C1).
Prints one line per host soname asked for, then `CLEANHOST asked=N listed=N unlisted=N unresolved=N`;
exits 1 on any unlisted or unresolved, 0 otherwise.
"""
import os
import re
import sys


def main(argv):
    args = [a for a in argv[1:]]
    drop = None
    if "--drop" in args:
        i = args.index("--drop"); drop = args[i + 1]; del args[i:i + 2]
    log, pkg, tsv = args
    pkg = pkg.rstrip("/") + "/"
    listed = set()
    for line in open(tsv):
        if line.startswith("#") or not line.strip() or line.startswith("soname\t"):
            continue
        listed.add(line.split("\t")[0])
    if drop:
        listed.discard(drop)
    blocks, cur, inits = [], None, set()
    for line in open(log, errors="replace"):
        body = line.split(":\t", 1)[-1].rstrip("\n")
        m = re.match(r"find library=(\S+) \[\d+\]; searching", body)
        if m:
            cur = {"so": m.group(1), "by": None, "tries": []}; blocks.append(cur); continue
        m = re.search(r"\((?:RUNPATH|RPATH) from file (\S+)\)", body)
        if m and cur is not None and cur["by"] is None:
            cur["by"] = m.group(1)
        m = re.match(r"\s+trying file=(\S+)", body)
        if m and cur is not None:
            cur["tries"].append(m.group(1))
        m = re.match(r"calling init: (\S+)", body)
        if m:
            inits.add(m.group(1))
    if not blocks:
        print(f"CLEANHOST no library searches in {log} — not an LD_DEBUG=libs log (VOID)")
        return 1
    asked, unresolved = {}, []
    for b in blocks:
        got = [t for t in b["tries"] if t in inits]
        if not got:
            unresolved.append(b); continue
        if b["by"] and b["by"].startswith(pkg) and not got[-1].startswith(pkg):
            asked.setdefault(b["so"], set()).add(os.path.basename(b["by"]))
    for so in sorted(asked):
        print(f"  {'listed  ' if so in listed else 'UNLISTED'} {so}  (search through {', '.join(sorted(asked[so]))})")
    for b in unresolved:
        print(f"  UNRESOLVED {b['so']} (search through {b['by'] and os.path.basename(b['by'])})")
    unl = [s for s in asked if s not in listed]
    print(f"CLEANHOST asked={len(asked)} listed={len(asked) - len(unl)} unlisted={len(unl)} unresolved={len(unresolved)}"
          f" host-objects={len([p for p in inits if not p.startswith(pkg)])}{' (list without ' + drop + ')' if drop else ''}")
    return 1 if unl or unresolved else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
