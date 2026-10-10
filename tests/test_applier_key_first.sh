#!/bin/sh
# test_applier_key_first.sh — THE PYTHON APPLIER WRITES NOTHING IT HAS NOT VERIFIED, THE SET KEY INCLUDED (14z-197, GitHub #255). ci_portable: no ROM, ~5 s.
#
# WHAT: tools/apply_release.py checks the built set's key against the manifest BEFORE writing, and writes each
#   zip through a temporary file renamed into place, so a key mismatch leaves an empty output directory empty
#   and an earlier output byte-identical, with no temporary file behind; a release whose key matches still
#   writes its set.
# HOW: a synthetic release packaged by tools/package_release.py from synthetic dumps (every member a pristine
#   copy, so no patch is needed; a stub `xdelta3` on PATH satisfies its check), then the applier run as shipped
#   against that manifest and against a copy whose `applied_set_key` is wrong.
# EXPECTS: the true manifest -> exit 0 and the set written; the wrong key -> non-zero exit naming the key, the
#   empty output still empty, the earlier output unchanged. The 14z-197 shape: the key was checked after the zips
#   were written, so the command failed while a playable-looking set sat in the output for a launcher to pick.
#
# MUST-FIRE: shadow-tool: write-first — a copy of the applier with the key check moved after the write (the pre-#255 order) must leave a set in the empty output on a key mismatch and FAIL section 2 (mode: the copy is the applier under test)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
rc=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; rc=1; }

mkdir -p "$W/bin" "$W/romdir" "$W/rompath"
printf '#!/bin/sh\nexit 0\n' > "$W/bin/xdelta3"; chmod +x "$W/bin/xdelta3"
python3 - "$W" <<'PY'
import sys, zipfile
w = sys.argv[1]
def mk(path, members):
    with zipfile.ZipFile(path, "w") as z:
        for n, b in members.items():
            z.writestr(n, b)
mk(f"{w}/romdir/vsavj.zip", {"vm3j.03d": b"\x01" * 64, "vm3j.04d": b"\x02" * 64})
mk(f"{w}/romdir/vsav.zip", {"vm3.01": b"\x03" * 64})
mk(f"{w}/romdir/vsav2.zip", {"vs2j.03": b"\x04" * 64})
mk(f"{w}/romdir/qsound_hle.zip", {"dl-1425.bin": b"\x05" * 64})
mk(f"{w}/rompath/vsavj.zip", {"vm3j.03d": b"\x01" * 64, "vm3.01": b"\x03" * 64})   # pristine copies only
PY
if ! PATH="$W/bin:$PATH" python3 tools/package_release.py "$W/rompath" "$W/rel" --romdir "$W/romdir" --name r1 --version T > "$W/pkg.log" 2>&1; then
    echo "FAIL: could not package the synthetic release:"; tail -3 "$W/pkg.log"; exit 1
fi
MAN="$W/rel/r1/manifest.json"
python3 - "$MAN" "$W/wrong.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
assert m.get("applied_set_key"), "the synthetic manifest declares no applied_set_key"
m["applied_set_key"] = "0" * 40
json.dump(m, open(sys.argv[2], "w"))
PY

write_first() {   # write_first <copy> — the applier with its key block moved after the write
    python3 - "$REPO/tools/apply_release.py" "$1" <<'PY'
import sys
s = open(sys.argv[1]).read()
a = s.find('    key_field = "applied_set_key_no_qsound_bios"')
b = s.find("    # 5. write")
c = s.find('    variant = "without the optional QSound BIOS member"')
if not (0 < a < b < c):
    sys.exit("write_first: the key block, the write and the report are not where this control expects them")
open(sys.argv[2], "w").write(s[:a] + s[b:c] + s[a:b] + s[c:])
PY
}
APPLY="$REPO/tools/apply_release.py"
if vs_ctl_is write-first; then
    write_first "$W/write_first.py" || { echo "REFUSED: CONTROL=write-first could not build its copy"; exit 3; }
    APPLY="$W/write_first.py"
fi
apply() {  # apply <applier> <manifest> <out> <log> — exit status
    python3 "$1" --romdir "$W/romdir" --out "$3" --manifest "$2" > "$4" 2>&1; echo $?; }
zips_in() { ls -A "$1" 2>/dev/null | tr '\n' ' '; }

echo "== 1. POSITIVE CONTROL — the true manifest writes its set"
e="$(apply "$APPLY" "$MAN" "$W/good" "$W/good.log")"
[ "$e" = 0 ] && [ -f "$W/good/vsavj.zip" ] && ok "exit 0, vsavj.zip written" || { bad "the true manifest (exit $e):"; tail -3 "$W/good.log" | sed 's/^/        /'; }

section2() {  # section2 <applier> <dir> — one line per breach
    mkdir -p "$2/empty"
    e="$(apply "$1" "$W/wrong.json" "$2/empty" "$2/e.log")"
    [ "$e" = 0 ] && echo "    empty output: the wrong key exited 0"
    grep -q "does not match the manifest's applied_set_key" "$2/e.log" || echo "    empty output: the key mismatch was not reported: $(tail -1 "$2/e.log")"
    [ -z "$(zips_in "$2/empty")" ] || echo "    empty output: left behind: $(zips_in "$2/empty")"
    cp -R "$W/good" "$2/prev"
    printf 'previous run' > "$2/prev/vsavj.zip"; before="$(shasum -a 1 < "$2/prev/vsavj.zip")"
    e="$(apply "$1" "$W/wrong.json" "$2/prev" "$2/p.log")"
    [ "$e" = 0 ] && echo "    earlier output: the wrong key exited 0"
    [ "$(shasum -a 1 < "$2/prev/vsavj.zip")" = "$before" ] || echo "    earlier output: vsavj.zip was OVERWRITTEN"
    [ "$(zips_in "$2/prev")" = "vsavj.zip " ] || echo "    earlier output: the directory now holds: $(zips_in "$2/prev")"
}
echo "== 2. a key mismatch writes nothing (#255)"
section2 "$APPLY" "$W/s2" > "$W/s2.txt" 2>&1
[ -s "$W/s2.txt" ] && { bad "the wrong key left output behind:"; cat "$W/s2.txt"; } \
    || ok "wrong key: non-zero exit naming it; the empty output still empty; the earlier output byte-identical"

if vs_ctl_is write-first; then
    [ "$rc" = 1 ] && { echo "FAIL: test_applier_key_first (control mode: write-first)"; exit 1; }
    echo "FAIL: test_applier_key_first — control mode write-first left the gate green"; exit 1
fi

echo "== 3. control"
if ! write_first "$W/ctl.py" > "$W/ctlb.txt" 2>&1; then vs_ctl_dead write-first "the copy could not be built: $(tail -1 "$W/ctlb.txt")" || rc=1
elif section2 "$W/ctl.py" "$W/c" > "$W/c.txt" 2>&1 && [ ! -s "$W/c.txt" ]; then vs_ctl_dead write-first "the write-first copy passed section 2" || rc=1
elif grep -q 'empty output: left behind: vsavj.zip' "$W/c.txt"; then vs_ctl_fired write-first "the write-first copy left vsavj.zip in the empty output on a key mismatch"
else vs_ctl_dead write-first "section 2 failed for another reason: $(head -1 "$W/c.txt")" || rc=1; fi

[ "$rc" = 0 ] && echo "PASS: test_applier_key_first" || echo "FAIL: test_applier_key_first"
exit "$rc"
