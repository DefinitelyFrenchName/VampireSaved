#!/usr/bin/env python3
"""check_host_libs.py — does a Linux release folder ask the HOST only for what a
player's machine may be assumed to have?

Usage: tools/check_host_libs.py <folder> <host-provided.tsv>

For every ELF file in <folder>, from its own dynamic section (`readelf -d`) and
its loader resolution on this host (`ldd`):

  R1  a NEEDED soname NOT shipped in the folder is asked of the host, so it must
      be on the host-provided list (an EXTERNAL list plus ruled exceptions —
      tests/expected/linux_host_provided.tsv; never the bundler's own policy,
      which would be the test written from the algorithm, [VSP-166]);
  R2  a NEEDED soname the folder DOES ship must resolve to the folder's copy —
      otherwise RUNPATH does not reach it and a player's machine will not find it;
  R3  nothing may be "not found".

WHY NOT A PATH CHECK (measured 2026-09-13, the first Linux run of the release
gate): the bundler copies its libraries out of the build host's system
directories, so on the build host EVERY bundled library also resolves
system-wide (18 of 18 in the MAME folder, 17 of 17 in FBNeo's). "Resolved under
/usr/lib, therefore host runtime" cannot see a missing bundled library there —
the gate's absolute-reference control removed libSDL2 and passed.

Only DIRECT NEEDED entries of the folder's own files are judged: what a host
library pulls in transitively (PulseAudio's codecs, libxcb's Xau) belongs to
the host that provides it.

FAIL lines on stdout, one `ok:` summary line when clean; exit 1 on any FAIL,
exit 2 on a REFUSAL (no ELF file, an empty list) — an empty input is never a
clean folder ([VSP-148]).
"""
import os
import re
import subprocess
import sys


def is_elf(path):
    try:
        with open(path, "rb") as f:
            return f.read(4) == b"\x7fELF"
    except OSError:
        return False


def needed(path):
    out = subprocess.run(["readelf", "-d", path], capture_output=True, text=True).stdout
    return re.findall(r"\(NEEDED\)\s+Shared library: \[(.+?)\]", out)


def resolution(path):
    """soname -> resolved path, or None when ldd says not found"""
    out = subprocess.run(["ldd", path], capture_output=True, text=True).stdout
    res = {}
    for line in out.splitlines():
        line = line.strip()
        if "=>" not in line:
            continue
        so, right = (x.strip() for x in line.split("=>", 1))
        if right.startswith("not found"):
            res[so] = None
        else:
            p = right.rsplit(" (0x", 1)[0].strip()
            if p:
                res[so] = p
    return res


def load_list(tsv):
    allowed = {}
    with open(tsv) as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            cols = line.rstrip("\n").split("\t")
            allowed[cols[0]] = cols[1] if len(cols) > 1 else "?"
    return allowed


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__.split("\n\n")[1])
    folder, tsv = sys.argv[1], sys.argv[2]
    real = os.path.realpath(folder)
    files = sorted(os.path.join(folder, n) for n in os.listdir(folder) if is_elf(os.path.join(folder, n)))
    if not files:
        print(f"REFUSED: no ELF file in {folder} — nothing was checked")
        sys.exit(2)
    allowed = load_list(tsv)
    if not allowed:
        print(f"REFUSED: {tsv} lists no soname — an empty list would pass nothing and prove nothing")
        sys.exit(2)
    shipped = set(os.listdir(folder))
    fails, asked = [], {}
    for f in files:
        name = os.path.basename(f)
        res = resolution(f)
        for so in needed(f):
            if so in shipped:
                p = res.get(so)
                if p is not None and os.path.dirname(os.path.realpath(p)) != real:
                    fails.append(f"FAIL: {name} resolves {so} to {p}, but this folder ships it — RUNPATH does not reach the folder")
                continue
            asked.setdefault(so, []).append(name)
            if so not in allowed:
                fails.append(f"FAIL: {name} needs {so}: not in this folder and not on the host-provided list ({os.path.basename(tsv)})")
        for so, p in res.items():
            if p is None:
                fails.append(f"FAIL: {name} needs {so}, NOT FOUND on this host")
    for line in fails:
        print(line)
    if fails:
        sys.exit(1)
    src = {}
    for so in asked:
        src[allowed[so]] = src.get(allowed[so], 0) + 1
    detail = ", ".join(f"{n} {k}" for k, n in sorted(src.items()))
    print(f"ok: {len(files)} ELF files ask the host for {len(asked)} sonames, every one on the host-provided list ({detail})")


if __name__ == "__main__":
    main()
