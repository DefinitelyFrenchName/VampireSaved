#!/bin/sh
# test_package_release_safety.sh — THE PACKAGER TOUCHES NOTHING OUTSIDE ITS RELEASE, AND A FAILED RUN KEEPS THE OLD ONE (14z-197, GitHub #246, #247). ci_portable: no ROM, ~10 s.
#
# WHAT: tools/package_release.py refuses a --name that is not one safe path component (`../victim`, an absolute
#   path, a separator, `.`/`..`, a leading dot) before touching anything, and so does
#   tools/package_release_platforms.py; a run that fails early (a missing reference dump) or late (a corrupt
#   build zip) leaves the previous package at <out>/<name> byte-identical and no staging directory behind; a
#   run that succeeds replaces the previous package whole.
# HOW: synthetic reference and build zips (no ROM bytes) and a stub `xdelta3` on PATH that writes a placeholder
#   patch, the packager run as shipped; a sentinel file planted in the previous package and in a sibling
#   `victim` directory.
# EXPECTS: every unsafe name refused with `victim/sentinel` intact; both failures keep `good/sentinel`; the
#   successful run leaves a manifest and no sentinel. The 14z-197 shapes: `--name ../victim` deleted the
#   sibling, and the previous package was deleted before the first dump was opened.
#
# MUST-FIRE: shadow-tool: name-unchecked — a copy of the packager with the name check (and the staging names' accidental `/` guard) removed must replace `victim` on a successful `--name ../victim` run and FAIL section 1 (mode: the copy is the packager under test)
# MUST-FIRE: shadow-tool: delete-first — a copy of the packager that builds in place after deleting the old package (the pre-#247 order) must lose `good/sentinel` on a failed run and FAIL section 2 (mode: the copy is the packager under test)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/shadow_tools.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
rc=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; rc=1; }

mkdir -p "$W/bin" "$W/romdir" "$W/rompath" "$W/badpath" "$W/empty"
# the stub answers -V as the version tools/package_release.py requires (#279), or the packager refuses it first
printf '#!/bin/sh\n[ "$1" = -V ] && { echo "Xdelta version 3.2.0 (stub)" >&2; exit 0; }\nfor a in "$@"; do last="$a"; done\nprintf "stub patch" > "$last"\n' > "$W/bin/xdelta3"
chmod +x "$W/bin/xdelta3"
python3 - "$W" <<'PY'
import os, sys, zipfile
w = sys.argv[1]
def mk(path, members):
    with zipfile.ZipFile(path, "w") as z:
        for n, b in members.items():
            z.writestr(n, b)
mk(f"{w}/romdir/vsavj.zip", {"vm3j.03d": b"\x01" * 64, "vm3j.04d": b"\x02" * 64})
mk(f"{w}/romdir/vsav.zip", {"vm3.01": b"\x03" * 64})
mk(f"{w}/romdir/vsav2.zip", {"vs2j.03": b"\x04" * 64})
mk(f"{w}/romdir/qsound_hle.zip", {"dl-1425.bin": b"\x05" * 64})
mk(f"{w}/rompath/vsavj.zip", {"vm3j.03d": b"\x01" * 64, "vm3j.04d": b"\x09" * 64})   # one pristine, one patched
mk(f"{w}/badpath/vsavj.zip", {"vm3j.03d": b"\x01" * 64})
open(f"{w}/badpath/aaa.zip", "wb").write(b"not a zip at all")                        # read first: a late failure
PY

# name_unchecked / delete_first <copy> — the two pre-fix packagers, each one substitution in a shadow copy
perturb() {   # perturb <name> <copy>
    python3 - "$1" "$2" <<'PY'
import sys
name, p = sys.argv[1], sys.argv[2]
s = open(p).read()
subs = {
    "name-unchecked": [('    if not SAFE_NAME.fullmatch(name or ""):\n', "    if False:\n"),
                       ("    if os.path.dirname(os.path.realpath(rel)) != root:\n", "    if False:\n"),
                       # the staging names embed --name, and mkdtemp refuses a `/` in a prefix: an ACCIDENTAL
                       # guard that would make this copy crash harmlessly instead of reaching the replace
                       ('prefix=f".stage-{a.name}-"', 'prefix=".stage-"'),
                       ('prefix=f".old-{a.name}-"', 'prefix=".old-"')],
    "delete-first": [('    rel = tempfile.mkdtemp(dir=a.out, prefix=f".stage-{a.name}-")\n',
                      "    rel = final; shutil.rmtree(final, ignore_errors=True); os.makedirs(final)\n")],
}[name]
for old, new in subs:
    if s.count(old) != 1:
        sys.exit(f"perturb {name}: {old.strip()!r} found {s.count(old)} times, not once")
    s = s.replace(old, new)
open(p, "w").write(s)
PY
}
PKG="$REPO/tools/package_release.py"
if vs_ctl_is name-unchecked || vs_ctl_is delete-first; then
    PKG="$(shadow_tool "$W/mode" package_release.py)" && perturb "$VS_CTL" "$PKG" \
        || { echo "REFUSED: CONTROL=$VS_CTL could not build its copy"; exit 3; }
fi

pkg() {  # pkg <packager> <rompath> <romdir> <out> <name> <log> — exit status
    PATH="$W/bin:$PATH" python3 "$1" "$2" "$4" --romdir "$3" --name "$5" --version T > "$6" 2>&1; echo $?; }
plant() {  # plant <out> — a previous package `good` and a sibling `victim`, each holding a sentinel
    rm -rf "$1" "$1/../victim"; mkdir -p "$1/good" "$1/../victim"
    echo previous > "$1/good/sentinel"; echo precious > "$1/../victim/sentinel"; }
leftovers() { ls -A "$1" | grep -E '^\.(stage|old|work)-' || true; }

section1() {  # section1 <packager> <dir> — one line per breach
    for n in ../victim "$2/victim" a/b . .. .hidden; do
        plant "$2/out"
        e="$(pkg "$1" "$W/rompath" "$W/romdir" "$2/out" "$n" "$2/n.log")"
        [ "$e" = 0 ] && echo "    --name '$n': ACCEPTED (exit 0)"
        [ -f "$2/victim/sentinel" ] || echo "    --name '$n': victim/sentinel is GONE"
        [ "$e" != 0 ] && ! grep -q "refusing --name" "$2/n.log" && echo "    --name '$n': failed, but not by the name check: $(tail -1 "$2/n.log")"
    done
    plant "$2/out"
    if python3 "$REPO/tools/package_release_platforms.py" "$W/rompath" "$2/out" --romdir "$W/romdir" \
           --name ../victim --version T > "$2/p.log" 2>&1 || ! grep -q "refusing --name" "$2/p.log"; then
        echo "    package_release_platforms.py --name ../victim: not refused by the name check: $(tail -1 "$2/p.log")"
    fi
    [ -f "$2/victim/sentinel" ] || echo "    package_release_platforms.py: victim/sentinel is GONE"
}
echo "== 1. an unsafe --name is refused before anything is touched (#246)"
section1 "$PKG" "$W/s1" > "$W/s1.txt" 2>&1
[ -s "$W/s1.txt" ] && { bad "an unsafe name got through:"; cat "$W/s1.txt"; } || ok "../victim, an absolute path, a/b, ., .., .hidden: each refused, victim/sentinel intact (both packagers)"

section2() {  # section2 <packager> <dir> — one line per breach
    for case in early late; do
        plant "$2/out"
        if [ "$case" = early ]; then e="$(pkg "$1" "$W/rompath" "$W/empty" "$2/out" good "$2/$case.log")"
        else                       e="$(pkg "$1" "$W/badpath" "$W/romdir" "$2/out" good "$2/$case.log")"; fi
        [ "$e" = 0 ] && echo "    $case failure: the run exited 0"
        [ "$(cat "$2/out/good/sentinel" 2>/dev/null)" = previous ] || echo "    $case failure: the previous package's sentinel is GONE"
        [ -z "$(leftovers "$2/out")" ] || echo "    $case failure: left behind: $(leftovers "$2/out" | tr '\n' ' ')"
    done
}
echo "== 2. a failed run keeps the previous package (#247)"
section2 "$PKG" "$W/s2" > "$W/s2.txt" 2>&1
[ -s "$W/s2.txt" ] && { bad "a failed run damaged the previous package:"; cat "$W/s2.txt"; } \
    || ok "early (missing dump) and late (corrupt build zip) failures: good/sentinel byte-identical, no staging left"

echo "== 3. POSITIVE CONTROL — a successful run replaces the previous package whole"
plant "$W/s3/out"
e="$(pkg "$PKG" "$W/rompath" "$W/romdir" "$W/s3/out" good "$W/s3.log")"
if [ "$e" = 0 ] && [ -f "$W/s3/out/good/manifest.json" ] && [ ! -e "$W/s3/out/good/sentinel" ] && [ -z "$(leftovers "$W/s3/out")" ]; then
    ok "exit 0: manifest.json written, the old sentinel gone with the old package, nothing staged left"
else
    bad "the successful run (exit $e):"; tail -5 "$W/s3.log" | sed 's/^/        /'; ls -A "$W/s3/out" "$W/s3/out/good" 2>&1 | sed 's/^/        /'
fi

if vs_ctl_is name-unchecked || vs_ctl_is delete-first; then
    [ "$rc" = 1 ] && { echo "FAIL: test_package_release_safety (control mode: $VS_CTL)"; exit 1; }
    echo "FAIL: test_package_release_safety — control mode $VS_CTL left the gate green"; exit 1
fi

echo "== 4. controls"
C1="$(shadow_tool "$W/c1" package_release.py)"
if ! perturb name-unchecked "$C1" > "$W/c1b.txt" 2>&1; then vs_ctl_dead name-unchecked "the copy could not be built: $(tail -1 "$W/c1b.txt")" || rc=1
elif section1 "$C1" "$W/c1s" > "$W/c1.txt" 2>&1 && [ ! -s "$W/c1.txt" ]; then vs_ctl_dead name-unchecked "the unchecked copy passed section 1" || rc=1
elif grep -q "'../victim': victim/sentinel is GONE" "$W/c1.txt"; then vs_ctl_fired name-unchecked "the unchecked copy replaced the sibling: $(grep -m1 GONE "$W/c1.txt" | sed 's/^ *//')"
else vs_ctl_dead name-unchecked "section 1 failed for another reason: $(head -1 "$W/c1.txt")" || rc=1; fi
C2="$(shadow_tool "$W/c2" package_release.py)"
if ! perturb delete-first "$C2" > "$W/c2b.txt" 2>&1; then vs_ctl_dead delete-first "the copy could not be built: $(tail -1 "$W/c2b.txt")" || rc=1
elif section2 "$C2" "$W/c2s" > "$W/c2.txt" 2>&1 && [ ! -s "$W/c2.txt" ]; then vs_ctl_dead delete-first "the delete-first copy passed section 2" || rc=1
elif grep -q "early failure: the previous package's sentinel is GONE" "$W/c2.txt"; then vs_ctl_fired delete-first "the delete-first copy lost the previous package on a failed run"
else vs_ctl_dead delete-first "section 2 failed for another reason: $(head -1 "$W/c2.txt")" || rc=1; fi

[ "$rc" = 0 ] && echo "PASS: test_package_release_safety" || echo "FAIL: test_package_release_safety"
exit "$rc"
