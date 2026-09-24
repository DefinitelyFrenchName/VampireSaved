#!/bin/sh
# test_host_libs.sh — tools/check_host_libs.py, the rule a Linux release folder is held to
# (every file's DIRECT NEEDED sonames are shipped in the folder and resolve there, or are
# on tests/expected/linux_host_provided.tsv; nothing "not found"), against STUB `readelf`
# and `ldd` on PATH — so the verdict logic is proven on any host, not only on the Linux
# box that runs the release gate. ROM-free, no Linux toolchain needed, ~1 s.
#
# WHAT: tools/check_host_libs.py holds a Linux release folder to its rule — every file's
#   direct NEEDED sonames are shipped and resolve in the folder, or are on the external
#   host-provided list (manylinux_2_39 plus ruled exceptions); nothing 'not found' — proven
#   on any host with stub readelf and ldd.
# HOW: a fixture folder under stub tools: it passes and counts what it asks the host for; a
#   soname on no list fails; a 'not found' fails; an empty list and a folder without ELF
#   refuse; the real list file's shape is checked; controls remove the bundled libSDL2 and
#   strip the RUNPATH.
# EXPECTS: the five sections as listed, both controls failing rules R1 and R2.
#
# MUST-FIRE: perturbed-copy: bundled-lib-removed — the fixture folder with its bundled libSDL2 removed must FAIL rule R1 (the change the release gate's absolute-reference control makes on Linux) (mode: section 1 checks that copy)
# MUST-FIRE: perturbed-copy: runpath-lost — the fixture with the executable's RUNPATH gone, so the stub loader resolves the SHIPPED libSDL2 from /usr/lib, must FAIL rule R2 (mode: section 1 checks that copy)
#
# WHY (2026-09-13, the first Linux run of tests/test_release_binaries.sh). The gate's
# Linux self-containment check accepted any library resolved under /usr/lib as "host
# runtime", and on a build host EVERY bundled library also lives there (measured 18 of
# 18 in the MAME folder, 17 of 17 in FBNeo's), so the absolute-reference control removed
# libSDL2 and passed. The maintainer ruled the anchor: an EXTERNAL published list
# (manylinux_2_39, auditwheel 6.4.2) plus exceptions ruled one by one — never the
# bundler's own policy ([VSP-166]). The real folders were checked with the same tool
# the same day: both pass, the removed libSDL2 FAILs R1, a stripped RUNPATH FAILs R2.
#
# Sections: 1 the fixture passes and counts what it asks the host for; 2 a soname on no
# list FAILs; 3 a "not found" FAILs; 4 an empty list and a folder with no ELF REFUSE;
# 5 the real list file: shape, counts, a reason on every ruled row, no duplicate.
#
# Usage: tests/test_host_libs.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
TOOL="$REPO/tools/check_host_libs.py"
LIST="$REPO/tests/expected/linux_host_provided.tsv"

# ---- the stub toolchain. NEEDED entries are recorded per file NAME, trimmed from the real
# linux-x86_64 MAME folder of 2026-09-13; the loader resolves a shipped soname inside the
# folder unless the folder carries a .no-runpath marker, everything else from /usr/lib.
mkdir -p "$W/bin"
cat > "$W/bin/readelf" <<'EOF'
#!/bin/sh
case "$(basename "$2")" in
  cps2)             set -- libSDL2-2.0.so.0 libasound.so.2 libstdc++.so.6 libc.so.6 ;;
  libSDL2-2.0.so.0) set -- libX11.so.6 libwayland-client.so.0 libm.so.6 libc.so.6 ;;
  libodd.so.1)      set -- libnotonanylist.so.9 libc.so.6 ;;
  *)                set -- libc.so.6 ;;
esac
for n; do printf ' 0x0000000000000001 (NEEDED)             Shared library: [%s]\n' "$n"; done
EOF
cat > "$W/bin/ldd" <<'EOF'
#!/bin/sh
d="$(cd "$(dirname "$1")" && pwd)"
for so in $(readelf -d "$1" | sed -n 's/.*\[\(.*\)\].*/\1/p'); do
  if [ "${STUB_NOTFOUND:-}" = "$so" ]; then printf '\t%s => not found\n' "$so"
  elif [ -e "$d/$so" ] && [ ! -e "$d/.no-runpath" ]; then printf '\t%s => %s/%s (0x1000)\n' "$so" "$d" "$so"
  else printf '\t%s => /usr/lib/x86_64-linux-gnu/%s (0x1000)\n' "$so" "$so"; fi
done
EOF
chmod +x "$W/bin/readelf" "$W/bin/ldd"
PATH="$W/bin:$PATH"; export PATH

elf() { printf '\177ELF' > "$1"; }
fixture() {  # fixture <dir>: an executable and one bundled library, plus a record
    mkdir -p "$1"; elf "$1/cps2"; elf "$1/libSDL2-2.0.so.0"; echo "record" > "$1/BINARY.txt"
}
perturb_removed() { rm -f "$1/libSDL2-2.0.so.0"; }
perturb_runpath() { : > "$1/.no-runpath"; }
check() { python3 "$TOOL" "$1" "$2" > "$3" 2>&1; }   # check <folder> <list> <out>; returns the tool's status
show()  { sed 's/^/        /' "$1"; }

[ -f "$TOOL" ] && [ -f "$LIST" ] || { echo "FAIL: missing $TOOL or $LIST"; echo "FAIL: test_host_libs"; exit 1; }

# ---- 1. the fixture passes, and the count is what it asks the host for
fixture "$W/f1"
vs_ctl_is bundled-lib-removed && perturb_removed "$W/f1"
vs_ctl_is runpath-lost && perturb_runpath "$W/f1"
if check "$W/f1" "$LIST" "$W/s1.txt"; then
    if grep -q 'ask the host for 6 sonames, every one on the host-provided list (4 manylinux, 2 ruled)' "$W/s1.txt"; then
        echo "  1 ok: the fixture passes — 6 sonames asked of the host, 4 manylinux + 2 ruled"
    else
        echo "FAIL: section 1 passed with the wrong count:"; show "$W/s1.txt"; fail=1
    fi
else
    echo "FAIL: section 1 — a self-contained fixture fails:"; show "$W/s1.txt"; fail=1
fi
# ---- 2. a soname on no list FAILs R1
fixture "$W/f2"; elf "$W/f2/libodd.so.1"
if check "$W/f2" "$LIST" "$W/s2.txt"; then
    echo "FAIL: section 2 — a soname on no list PASSED"; fail=1
elif grep -q 'libodd.so.1 needs libnotonanylist.so.9: not in this folder and not on the host-provided list' "$W/s2.txt"; then
    echo "  2 ok: a soname on no list fails, naming the file and the soname"
else
    echo "FAIL: section 2 failed for another reason:"; show "$W/s2.txt"; fail=1
fi
# ---- 3. "not found" FAILs R3
fixture "$W/f3"
if STUB_NOTFOUND=libasound.so.2 check "$W/f3" "$LIST" "$W/s3.txt"; then
    echo "FAIL: section 3 — a not-found soname PASSED"; fail=1
elif grep -q 'cps2 needs libasound.so.2, NOT FOUND on this host' "$W/s3.txt"; then
    echo "  3 ok: a soname the loader cannot find fails"
else
    echo "FAIL: section 3 failed for another reason:"; show "$W/s3.txt"; fail=1
fi
# ---- 4. empty inputs REFUSE (exit 2), never pass
fixture "$W/f4"; : > "$W/empty.tsv"; mkdir -p "$W/noelf"; echo x > "$W/noelf/BINARY.txt"
rc=0; check "$W/f4" "$W/empty.tsv" "$W/s4a.txt" || rc=$?
[ "$rc" = 2 ] && grep -q '^REFUSED:' "$W/s4a.txt" || { echo "FAIL: section 4 — an empty list did not REFUSE (exit $rc):"; show "$W/s4a.txt"; fail=1; }
rc=0; check "$W/noelf" "$LIST" "$W/s4b.txt" || rc=$?
[ "$rc" = 2 ] && grep -q '^REFUSED:' "$W/s4b.txt" || { echo "FAIL: section 4 — a folder with no ELF did not REFUSE (exit $rc):"; show "$W/s4b.txt"; fail=1; }
[ "$fail" = 0 ] && echo "  4 ok: an empty list and a folder with no ELF both REFUSE (exit 2)"
# ---- 5. the real list file
python3 - "$LIST" <<'PY' || fail=1
import sys, collections
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip() and not l.startswith("#")]
bad = [r for r in rows if len(r) != 3 or r[1] not in ("manylinux", "ruled")]
by = collections.Counter(r[1] for r in rows if len(r) == 3)
dups = [s for s, n in collections.Counter(r[0] for r in rows).items() if n > 1]
unreasoned = [r[0] for r in rows if len(r) == 3 and r[1] == "ruled" and r[2].strip() in ("", "-")]
ok = not bad and not dups and not unreasoned and by["manylinux"] == 23 and by["ruled"] == 13
if not ok:
    print(f"FAIL: section 5 — the list: malformed {bad[:2]}, duplicates {dups}, ruled without a reason {unreasoned}, "
          f"counts manylinux {by['manylinux']} (want 23) ruled {by['ruled']} (want 13)")
    sys.exit(1)
print("  5 ok: the list — 23 manylinux_2_39 + 13 ruled, each ruled row with its reason, no duplicate")
PY

# ---- must-fire controls: each perturbation of the fixture must FAIL, for its stated reason
fixture "$W/c1"; perturb_removed "$W/c1"
if check "$W/c1" "$LIST" "$W/c1.txt"; then
    vs_ctl_dead bundled-lib-removed "the fixture without its bundled libSDL2 passed" || true; fail=1
elif grep -q 'cps2 needs libSDL2-2.0.so.0: not in this folder and not on the host-provided list' "$W/c1.txt"; then
    vs_ctl_fired bundled-lib-removed "$(grep -m1 'needs libSDL2' "$W/c1.txt")"
else
    vs_ctl_dead bundled-lib-removed "failed for another reason: $(head -1 "$W/c1.txt")" || true; fail=1
fi
fixture "$W/c2"; perturb_runpath "$W/c2"
if check "$W/c2" "$LIST" "$W/c2.txt"; then
    vs_ctl_dead runpath-lost "a shipped library resolved from /usr/lib passed" || true; fail=1
elif grep -q 'RUNPATH does not reach the folder' "$W/c2.txt"; then
    vs_ctl_fired runpath-lost "$(grep -m1 'RUNPATH' "$W/c2.txt")"
else
    vs_ctl_dead runpath-lost "failed for another reason: $(head -1 "$W/c2.txt")" || true; fail=1
fi

[ "$fail" = 0 ] && echo "PASS: test_host_libs" || { echo "FAIL: test_host_libs"; exit 1; }
