#!/bin/sh
# test_build_ref_rot.sh — a hardcoded build/<name> default must not have
# rotted (14z-94, GitHub #94). ROM-free, ~2 s.
#
# THE CLASS. Build dirs are UNTRACKED by design (rule 7 keeps romset-derived
# artifacts out of the tree), so every `${1:-build/pyron22}` default is a
# pointer with a shelf life. Four instances surfaced in a single session —
# hui31, pyron20, pyron17, pyron22 — each found the same way: somebody ran the
# audit months later and it died before measuring anything.
#
# The individual fix is one line each. The class is this gate: nothing told
# you a reference had rotted until you ran the audit, and these are on-demand
# audits that can go months between runs.
#
# THE SIGNATURE IS PRECISE. A rotted reference here is a build predating WIDE
# v1.1 — 19 members, no vsw.z01/z02 — while every current build has 21. That
# is not a guess: all four instances, plus build/m3b_merged and build/pyron18,
# match it exactly.
#
# AND IT MUST CONSIDER WHAT THE SCRIPT READS. build_merged.sh's H_EX default
# is build/hui32, whose rompath zip IS pre-v1.1 — but it reads that build's
# `extract/` directory, never its romset, so it is NOT rotted. Flagging it
# would be a false positive, and a gate that cries wolf about a working
# reference is one people switch off. So a default is only checked when the
# script actually reads its `rompath`.
#
# ABSENT IS NOT ROTTED. On a clean checkout every build dir is missing; that
# is reported, never failed (GitHub #29's distinction). The failure condition
# is a reference that is STALE — present, read as a romset, and too old to
# carry the members the reader needs.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - <<'PY'
import glob, os, re, sys, zipfile

# VAR="${N:-build/name}"  — the default-reference idiom this gate is about
DEF = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)="\$\{[0-9]+:-(build/[a-z0-9_]+)\}"', re.M)

rotted, absent, ok, skipped = [], [], [], []
for path in sorted(glob.glob("tests/*.sh")):
    src = open(path, errors="replace").read()
    body = "\n".join(l for l in src.splitlines() if not l.lstrip().startswith("#"))
    for var, bdir in DEF.findall(body):
        # Only defaults the script reads as a ROMSET. A build referenced for
        # its extract/ or patch/ dir is a different contract.
        if f'${var}/rompath' not in body and f'${{{var}}}/rompath' not in body:
            skipped.append((os.path.basename(path), var, bdir, "not read as a romset"))
            continue
        if not os.path.isdir(bdir):
            absent.append((os.path.basename(path), var, bdir))
            continue
        zips = [z for z in glob.glob(f"{bdir}/rompath/*.zip") if "vsavjw" in z] \
               or glob.glob(f"{bdir}/rompath/*.zip")
        if not zips:
            rotted.append((os.path.basename(path), var, bdir, "no romset zip"))
            continue
        names = zipfile.ZipFile(zips[0]).namelist()
        wide = [n for n in names if n.startswith("vsw.")]
        if wide and "vsw.z01" not in names:
            rotted.append((os.path.basename(path), var, bdir,
                           f"{len(names)} members, no vsw.z01 (pre-WIDE v1.1)"))
        else:
            ok.append((os.path.basename(path), var, bdir, f"{len(names)} members"))

print(f"== {len(ok)} live, {len(absent)} unbuilt, {len(rotted)} ROTTED"
      f" ({len(skipped)} not romset refs)")
for s, v, d, w in ok:
    print(f"  ok      {d:<22} {s} (${v}) — {w}")
for s, v, d in absent:
    print(f"  unbuilt {d:<22} {s} (${v}) — not built here; not a failure")
for s, v, d, w in rotted:
    print(f"  ROTTED  {d:<22} {s} (${v}) — {w}")

if rotted:
    print()
    print("  A rotted default means the script cannot run at all: it dies before")
    print("  measuring anything, and it says so only when somebody runs it.")
    print("  Re-point it at a current build, or parameterise it the way")
    print("  audit_merged_legacy.sh's leg (b) was at 14z-94.")
sys.exit(1 if rotted else 0)
PY
st=$?

echo
if [ "$st" = 0 ]; then
    echo "PASS: no hardcoded romset reference has rotted."
else
    echo "FAIL: see above."
fi
exit $st
