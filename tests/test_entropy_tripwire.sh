#!/bin/sh
# test_entropy_tripwire.sh — RULE 7'S TRIPWIRE READS THE INDEX, NOT `??` LINES (14z-197, GitHub #249). ci_portable: no ROM, ~10 s.
#
# WHAT: tools/entropy_tripwire.py, the check CI runs, flags a high-entropy file that is COMMITTED or STAGED as well as
#   one left untracked, passes the tree's four allowed compressed formats only when path AND magic match, and the
#   tracked tree itself carries no high-entropy file outside them.
# HOW: (1) the tool over this tree's index; (2) a scratch git repository: 64 KiB of random bytes staged, then
#   committed, then left untracked, a real-magic PNG, the same random bytes renamed .png, and plain text — each judged
#   by the tool in the mode CI uses.
# EXPECTS: (1) exit 0; (2) the staged, committed and untracked blobs and the renamed blob each FAIL, the PNG and the
#   text pass. The 14z-197 shape: CI's old selector `awk '$1=="??"'` returned nothing for a staged (`A`) or committed
#   blob, so the step printed "ok" over the case its own comment said it caught.
#
# MUST-FIRE: known-bad: planted-blob — 64 KiB of random bytes judged with the tracked tree (`--extra`) must FAIL section 1 (mode: section 1 judges the planted file too)
# MUST-FIRE: shadow-tool: old-selector — a copy of the tool that lists no tracked path (the pre-#249 `??`-only selector) must pass the staged and committed blobs and FAIL section 2 (mode: the copy is the tool under test)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
rc=0
python3 -c 'import os,sys; open(sys.argv[1],"wb").write(os.urandom(65536))' "$W/planted.bin"

old_selector() {   # old_selector <copy> — the tool with its tracked listing emptied
    python3 - "$REPO/tools/entropy_tripwire.py" "$1" <<'PY'
import sys
s = open(sys.argv[1]).read()
old = '        paths += [(p, "tracked") for p in git_paths(a.root, [])]\n'
if s.count(old) != 1:
    sys.exit(f"old_selector: the tracked listing found {s.count(old)} times, not once")
open(sys.argv[2], "w").write(s.replace(old, "        pass\n"))
PY
}
TOOL="$REPO/tools/entropy_tripwire.py"
if vs_ctl_is old-selector; then
    old_selector "$W/old_selector.py" || { echo "REFUSED: CONTROL=old-selector could not build its copy"; exit 3; }
    TOOL="$W/old_selector.py"
fi

echo "== 1. the tracked tree"
EXTRA=""; vs_ctl_is planted-blob && EXTRA="--extra $W/planted.bin"
# shellcheck disable=SC2086
if python3 tools/entropy_tripwire.py --tracked $EXTRA > "$W/s1.txt" 2>&1; then
    sed 's/^/  /' "$W/s1.txt"
else
    sed 's/^/  /' "$W/s1.txt"; echo "  FAIL  a high-entropy file outside the allowed classes"; rc=1
fi

# section2 <tool> — prints one line per wrong verdict, exit 1 if any
section2() {
    R="$(mktemp -d "$W/repo.XXXXXX")"
    git -C "$R" init -q
    printf 'plain text, well below the threshold\n%.0s' $(seq 1 60) > "$R/notes.txt"
    git -C "$R" add notes.txt
    git -C "$R" -c user.email=t@t -c user.name=t commit -qm base
    bad=0
    judge() {   # judge <label> <want 0|1> <tool args...>
        label="$1"; want="$2"; shift 2
        python3 "$TOOL" --root "$R" "$@" > "$W/j.txt" 2>&1; got=$?
        [ "$got" = 1 ] && v=1 || v=0
        [ "$got" -gt 1 ] && { echo "    $label: the tool crashed (exit $got): $(tail -1 "$W/j.txt")"; bad=1; return; }
        [ "$v" = "$want" ] || { echo "    $label: exit $got, want $( [ "$want" = 1 ] && echo FAIL || echo pass)"; bad=1; }
    }
    judge "plain text" 0
    cp "$W/planted.bin" "$R/sample.bin"; git -C "$R" add sample.bin
    judge "a STAGED blob" 1 --tracked
    git -C "$R" -c user.email=t@t -c user.name=t commit -qm blob
    judge "a COMMITTED blob" 1 --tracked
    git -C "$R" rm -q --cached sample.bin
    judge "an UNTRACKED blob" 1 --untracked
    rm "$R/sample.bin"
    python3 - "$R/figure.png" <<'PY'
import os, sys
open(sys.argv[1], "wb").write(b"\x89PNG\r\n\x1a\n" + os.urandom(65536))
PY
    git -C "$R" add figure.png
    judge "a real-magic PNG" 0 --tracked
    cp "$W/planted.bin" "$R/renamed.png"; git -C "$R" add renamed.png
    judge "random bytes renamed .png" 1 --tracked
    return $bad
}
echo "== 2. ground truth on a scratch repository (the CI mode's verdicts)"
if section2 > "$W/s2.txt" 2>&1; then
    echo "  ok    staged, committed, untracked and renamed blobs FAIL; a real PNG and plain text pass"
else
    echo "  FAIL  a wrong verdict:"; cat "$W/s2.txt"; rc=1
fi

if vs_ctl_is planted-blob || vs_ctl_is old-selector; then
    [ "$rc" = 1 ] && { echo "FAIL: test_entropy_tripwire (control mode: $VS_CTL)"; exit 1; }
    echo "FAIL: test_entropy_tripwire — control mode $VS_CTL left the gate green"; exit 1
fi

echo "== 3. controls"
if python3 tools/entropy_tripwire.py --tracked --extra "$W/planted.bin" > "$W/c1.txt" 2>&1; then
    vs_ctl_dead planted-blob "the planted random bytes passed" || rc=1
elif grep -q 'planted.bin  \[extra\]' "$W/c1.txt"; then
    vs_ctl_fired planted-blob "$(grep -m1 'planted.bin' "$W/c1.txt" | sed 's/^ *//')"
else
    vs_ctl_dead planted-blob "the check failed but did not name the planted file: $(tail -1 "$W/c1.txt")" || rc=1
fi
if ! old_selector "$W/ctl_old.py" > "$W/c2b.txt" 2>&1; then
    vs_ctl_dead old-selector "the copy could not be built: $(tail -1 "$W/c2b.txt")" || rc=1
else
    TOOL="$W/ctl_old.py"
    if section2 > "$W/c2.txt" 2>&1; then
        vs_ctl_dead old-selector "the untracked-only selector passed section 2" || rc=1
    elif grep -q 'a STAGED blob: exit 0' "$W/c2.txt" && grep -q 'a COMMITTED blob: exit 0' "$W/c2.txt"; then
        vs_ctl_fired old-selector "the staged and the committed blob both passed the untracked-only selector"
    else
        vs_ctl_dead old-selector "section 2 failed for another reason: $(head -1 "$W/c2.txt")" || rc=1
    fi
    TOOL="$REPO/tools/entropy_tripwire.py"
fi

[ "$rc" = 0 ] && echo "PASS: test_entropy_tripwire" || echo "FAIL: test_entropy_tripwire"
exit "$rc"
