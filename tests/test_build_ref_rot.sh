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
#
# ── 14z-97: TWO GAPS CLOSED, and the second one is a different failure ──────
#
# (1) COVERAGE. The pattern matched `VAR="${1:-build/x}"` only — a POSITIONAL
#     default. Eleven references use the named-env idiom
#     `BUILD="${BUILD:-build/don_m7}"` and were invisible to this gate, in a
#     gate whose entire purpose is to have no blind spot. None of the eleven
#     is rotted today, so this closes a hole rather than fixing a breakage —
#     which is the only time it is cheap to close one.
#
# (2) CURRENCY, which rot cannot see. Every reference above reports "ok" the
#     moment it LOADS, and a superseded build loads perfectly. That is how
#     GitHub #96 happened one level up: the M2 battery judged today's build
#     against `donovan-m2c`, five generations back, and was green about it for
#     weeks. `test_merged_render_content` had the same shape at 14z-92 (its
#     huitzil leg produced NO measurement since 14z-86 while printing a
#     content mismatch), and `audit_pyron_ring` at 14z-95 (it compared two
#     builds that stop being comparable at f4741).
#
#     So currency is now REPORTED, by two mechanical signals that need no
#     external source of truth:
#       - registry: fingerprint the referenced build, look the set up in
#         tests/expected/registry.tsv, and compare against the newest row of
#         its family (donovan-mN / huitzil-mN / pyron-mN).
#       - family disagreement: when several gates name different dirs for the
#         same role, at most one can be current. This is what catches the
#         MERGED build, which has no registry row by design.
#
#     IT REPORTS AND DOES NOT FAIL, deliberately. A superseded reference is
#     often CORRECT — the pre-fix build in an A/B audit, a known-bad
#     ground-truth reference — and only the gate's author knows which. Failing
#     on it would either be wrong or would force ~27 declarations written by
#     somebody guessing at intent. The report is the triage worksheet; turning
#     any row into an assertion is a per-gate decision with the intent in hand.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #94 → 14z-97) A hardcoded `build/<name>` default must not
#   have ROTTED (present, read as a romset, too old to carry the members the
#   reader needs). **Extended 14z-97 twice:** the pattern matched POSITIONAL
#   defaults only, so eleven named-env references
#   (`BUILD="${BUILD:-build/don_m7}"`) were invisible — coverage 21 → 32; and
#   it now REPORTS CURRENCY, which rot cannot see, because a superseded build
#   loads perfectly (that is how #96 happened one level up). Currency reports
#   and never fails: a superseded reference is often correct, and only the
#   gate's author knows which. Today: 3 current, 16 superseded.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

python3 - <<'PY'
import glob, os, re, sys, zipfile

# The default-reference idioms this gate is about. BOTH forms, 14z-97:
#   VAR="${1:-build/name}"      positional
#   VAR="${VAR:-build/name}"    named env — eleven references, previously unseen
DEF = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)='
                 r'"\$\{(?:[0-9]+|[A-Za-z_][A-Za-z0-9_]*):-(build/[a-z0-9_]+)\}"', re.M)

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

# ── CURRENCY (14z-97): reported, never failed. See the header. ─────────────
sys.path.insert(0, "tools")
try:
    import build_fingerprint as _bf
except Exception as _e:                       # never let this section break rot
    _bf = None
    print(f"\n  (currency check unavailable: {_e})")

# Wrapped, because a gate whose REPORT can abort its VERDICT reports the
# wrong thing when it breaks — the shell would see a nonzero exit and print
# "no reference has rotted: FAIL", which is a sentence about the wrong half.
# (Today's own lesson, one file over: a verdict control that crashed read as a
# control that fired.)
try:
  if _bf is not None:
      reg, fam_newest = {}, {}
      for line in open("tests/expected/registry.tsv", errors="replace"):
          if line.startswith("#") or "\t" not in line:
              continue
          f = line.split("\t")
          reg[f[0].strip()] = f[1].strip()
      for name in reg.values():
          m = re.match(r"^([a-z]+)-m(\d+)$", name)      # tenant freezes only;
          if m:                                          # -stock/-stage4 are
              fam, n = m.group(1), int(m.group(2))       # battery targets, not
              if n > fam_newest.get(fam, (-1, ""))[0]:   # a tenant generation
                  fam_newest[fam] = (n, name)

      # Currency covers EVERY matched reference, not just the ones read as a
      # romset. The romset distinction is about MEMBERS and belongs to the rot
      # check; a superseded reference is superseded however the script opens it.
      # Without this, audit_merged_legacy's three leg-(b) solos — the only
      # references in the tree that DO name the current freeze — were absent
      # from the report, because they are passed to a helper rather than
      # dereferenced as "$VAR/rompath" here, and the picture read bleaker than
      # the tree actually is.
      seen, rows = {}, []
      for _script, _var, bdir, _w in ok + [(a, b, c, "") for a, b, c, _ in skipped]:
          if not os.path.isdir(bdir):
              continue
          if bdir not in seen:
              zs = ([z for z in glob.glob(f"{bdir}/rompath/*.zip") if "vsavjw" in z]
                    or glob.glob(f"{bdir}/rompath/*.zip"))
              try:
                  seen[bdir] = reg.get(_bf.program_sha1(zs[0]), None)
              except Exception:
                  seen[bdir] = None
          rows.append((bdir, _script, _var, seen[bdir]))

      # signal 2: several gates naming DIFFERENT dirs of the same family. At most
      # one can be current, and this is what catches the merged build, which has
      # no registry row by design.
      fam_dirs = {}
      for bdir in sorted(seen):
          fam_dirs.setdefault(re.sub(r"\d+$", "", bdir), set()).add(bdir)

      print("\n== currency (REPORT ONLY — a superseded reference is often correct)")
      stale = 0
      for bdir, _script, _var, expset in sorted(rows):
          if expset is None:
              # Two different reasons, and the gate cannot tell them apart:
              # merged builds and the legacy-only instrument have NO row by
              # design (registry.tsv says so at the top), while an old solo is
              # unregistered because its set was carried-renamed away at a later
              # freeze. Both are "not a named generation"; neither is a verdict.
              note = "no registry row (by design for merged/instrument, or a pre-freeze build)"
          else:
              m = re.match(r"^([a-z]+)-m(\d+)$", expset)
              newest = fam_newest.get(m.group(1), (None, None))[1] if m else None
              if newest and newest != expset:
                  note = f"SUPERSEDED — {expset}; newest is {newest}"
                  stale += 1
              else:
                  note = f"current — {expset}"
          print(f"  {bdir:<22} {_script:<34} {note}")
      split = {f: d for f, d in fam_dirs.items() if len(d) > 1}
      if split:
          print("\n  families referenced at MORE THAN ONE generation — at most one")
          print("  of each can be current:")
          for f, d in sorted(split.items()):
              print(f"      {f + '*':<18} {', '.join(sorted(d))}")
      print(f"\n  {stale} registered reference(s) point at a superseded set."
            f" That is information, not a verdict: re-point the ones that meant"
            f" 'the current build', and leave the ones that meant 'that build'.")
except Exception as _e:
    print(f"\n  (currency report failed: {_e} — the ROT verdict below is unaffected)")

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
