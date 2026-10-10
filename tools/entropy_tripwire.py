#!/usr/bin/env python3
"""entropy_tripwire.py — rule 7's tripwire: no file in the tree may look like ROM content.

  python3 tools/entropy_tripwire.py [--root DIR] [--tracked] [--untracked] [--extra PATH ...]

  --tracked     every path in the INDEX (`git ls-files`): committed files AND staged additions
  --untracked   every untracked, non-ignored path (`git ls-files --others --exclude-standard`)
  --extra PATH  one more file, judged as if tracked (a gate's planted control)

With neither --tracked nor --untracked, both are scanned. Exit 0 when every file above the
threshold matches an ALLOWED class below; exit 1 naming each one that does not.

WHY (14z-197, GitHub #249). The CI step this replaces selected `git status` lines whose
status was `??` — untracked files only. On a CI checkout every file is committed and clean,
and in a developer tree a staged addition reads `A`, so the step printed "ok" over exactly
the case its own comment said it caught: a committed binary blob. Reading the INDEX covers
both. The untracked half is kept for CI, where nothing untracked is expected; a developer
tree's untracked build/ outputs are why `tests/test_entropy_tripwire.sh` scans tracked only.

THE THRESHOLD, 6.0 bits/byte over the first 64 KiB, files of 512 bytes or more, is the
CI step's own, measured 14z-93 (`e50a87df`, its comment in ci.yml): ci_portable.txt 4.72,
gen_donovan_patch.py 4.76, STATE.md 5.15, a placed code blob 5.60, a DECRYPTED ROM IMAGE
6.56 — above what the tree holds as text and code, below ROM content.

THE ALLOWED CLASSES. Entropy is a proxy; the tree legitimately holds four compressed formats
above the threshold (measured 14z-197 over the index: 574 of 15,275 files, all four classes).
A file passes only when its PATH matches the class AND its first bytes carry the format's
MAGIC, so a ROM blob renamed into an allowed path still fails. A class is not a licence for
its content — the xdelta patches' own rule-7 scan is `tests/test_release_roundtrip.sh`
(reference-ROM chunk scan), and that gate, not this one, is what clears them.
"""
import argparse
import collections
import fnmatch
import math
import os
import subprocess
import sys

THRESHOLD = 6.0
WINDOW = 65536
MIN_SIZE = 512

# (name, path glob, magic prefix, why) — fnmatch globs, where `*` ALSO matches `/`, so
# "release/*.xdelta" covers every release layout (merged-m6's single `patches/` and the
# per-platform `<platform>/patches/` since).
ALLOWED = (
    ("xdelta", "release/*.xdelta", b"\xd6\xc3\xc4",
     "a release's VCDIFF patches; their reference-chunk scan is test_release_roundtrip"),
    ("inp", "tests/inp/*/*.inp", b"MAMEINP\x00",
     "a hand-played MAME recording (zlib-compressed input log), [VSP-20]"),
    ("png", "*.png", b"\x89PNG\r\n\x1a\n",
     "a rendered frame or figure — derived work, ruled outside rule 7 (14z-91, #73)"),
    ("jpg", "docs/*.jpg", b"\xff\xd8\xff",
     "a documentation photograph"),
)


def entropy(path):
    with open(path, "rb") as f:
        b = f.read(WINDOW)
    if len(b) < MIN_SIZE:
        return None, b
    n = len(b)
    h = -sum((c / n) * math.log2(c / n) for c in collections.Counter(b).values())
    return h, b


def allowed(rel, head):
    for name, glob, magic, _ in ALLOWED:
        if fnmatch.fnmatchcase(rel, glob) and head.startswith(magic):
            return name
    return None


def git_paths(root, args):
    out = subprocess.run(["git", "-C", root, "ls-files", "-z", *args],
                         capture_output=True, check=True).stdout
    return [p.decode() for p in out.split(b"\0") if p]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--tracked", action="store_true")
    ap.add_argument("--untracked", action="store_true")
    ap.add_argument("--extra", action="append", default=[])
    a = ap.parse_args()
    both = not (a.tracked or a.untracked)
    paths = []
    if a.tracked or both:
        paths += [(p, "tracked") for p in git_paths(a.root, [])]
    if a.untracked or both:
        paths += [(p, "untracked") for p in git_paths(a.root, ["--others", "--exclude-standard"])]
    scanned, high, bad = 0, collections.Counter(), []
    for rel, kind in paths:
        full = os.path.join(a.root, rel)
        if os.path.islink(full) or not os.path.isfile(full):
            continue
        h, head = entropy(full)
        scanned += 1
        if h is None or h <= THRESHOLD:
            continue
        cls = allowed(rel, head)
        if cls:
            high[cls] += 1
        else:
            bad.append((rel, kind, h))
    for x in a.extra:
        h, head = entropy(x)
        scanned += 1
        if h is not None and h > THRESHOLD and not allowed(x, head):
            bad.append((x, "extra", h))
    print(f"  scanned {scanned} files; above {THRESHOLD} bits/byte in an allowed class: "
          + (", ".join(f"{k} {v}" for k, v in sorted(high.items())) or "none"))
    if bad:
        print(f"FAIL: {len(bad)} high-entropy file(s) in no allowed class (rule 7 — no ROM content):")
        for rel, kind, h in bad:
            print(f"  {rel}  [{kind}]  {h:.2f} bits/byte (limit {THRESHOLD})")
        return 1
    print("ok: no high-entropy file outside the allowed classes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
