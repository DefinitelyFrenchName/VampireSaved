#!/bin/sh
# test_session_close.sh — the session close has ONE copy, a step table its driver runs (GitHub #282 item C, 14z-201).
# ci_portable: no ROM, no build dir, no emulator, ~2 s.
#
# WHAT: docs/project/session_close.md's step table parses (six cells a row, ids unique, kind auto or manual, every auto
#   step one backticked command and a verdict `exit 0` or `line <regex>`), its commands name only tools and tests that
#   exist and only the placeholders tools/close.py fills, and CLAUDE.md, STATE.md, HANDOFF.md and docs/NEXT_SESSION.md
#   each point to it; tools/close.py --selftest passes (order, placeholders, a verdict line judged over the exit code,
#   done only at the step the close is at).
# HOW: tools/close.py check over the tree, and the self-test; controls on a copy of the doc and the four live documents.
# EXPECTS: the tree passes; each perturbed copy fails naming what broke; the known-bad driver fails its self-test.
#
# MUST-FIRE: perturbed-copy: unknown-placeholder — a step command given `{NOPE}` must fail as an UNKNOWN placeholder, or a step could run with a hole in it
# MUST-FIRE: perturbed-copy: missing-tool — a step naming tools/no_such_tool.py must fail by name, or a renamed tool leaves the close a step that cannot run
# MUST-FIRE: perturbed-copy: pointer-lost — STATE.md without its pointer to docs/project/session_close.md must fail, or a second copy of the ritual can grow back unnoticed
# MUST-FIRE: known-bad: verdict-ignored — tools/close.py --selftest --perturb verdict-ignored (every step read as passed) must print SELFTEST FAIL, or a red tier could walk on to the push
#
# WHY. The maintainer (#282): the close "is almost never compeletely executed by default". A census found the ritual in
# 58 places across 30 files, none of them complete, 8 sets disagreeing. Ruled "Doc + driver (Recommended)"
# (DECISIONS_HISTORY.md "Ruled 2026-10-15 (14z-201) — #282 item C"): one table, read by the driver that runs it.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

DOC=docs/project/session_close.md
mkcopy() {   # the doc, the four live documents, and every tools/ and tests/ script a step names
    for f in $DOC CLAUDE.md STATE.md HANDOFF.md docs/NEXT_SESSION.md \
             $(grep -oE '(tools|tests)/[A-Za-z0-9_./-]+\.(py|sh)' "$DOC" | sort -u); do
        [ -f "$f" ] || continue; mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"
    done
}
perturb() {  # perturb <name> <dir>; EXPECT = the failure's substring
    case "$1" in
    unknown-placeholder) python3 - "$2/$DOC" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("python3 tools/gen_history_index.py", "python3 tools/gen_history_index.py {NOPE}", 1)
open(p, "w").write(s)
PY
                         EXPECT="UNKNOWN placeholder {NOPE}" ;;
    missing-tool)        python3 - "$2/$DOC" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("python3 tools/gen_history_index.py", "python3 tools/no_such_tool.py", 1)
open(p, "w").write(s)
PY
                         EXPECT="tools/no_such_tool.py, which does not exist" ;;
    pointer-lost)        sed -i.bak 's#docs/project/session_close\.md#docs/project/elsewhere.md#g' "$2/STATE.md"; rm -f "$2/STATE.md.bak"
                         EXPECT="STATE.md does not point to $DOC" ;;
    verdict-ignored)     EXPECT="SELFTEST FAIL" ;;
    *) echo "no such perturbation: $1"; exit 3 ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy (or the known-bad driver) IS what the main check reads.
ROOT="$REPO"; PERT=""
if [ -n "$VS_CTL" ]; then
    if [ "$VS_CTL" = verdict-ignored ]; then PERT="--perturb verdict-ignored"
    else mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; fi
fi

echo "== test_session_close: one step table, its commands real, the live documents pointing to it, the driver self-tested =="
if python3 tools/close.py check --root "$ROOT" >"$W/tree.log" 2>&1; then ok "$(tail -1 "$W/tree.log")"
else bad "tools/close.py check FAILS:"; sed 's/^/        /' "$W/tree.log" | head -12; fi
if python3 tools/close.py --selftest $PERT >"$W/self.log" 2>&1 && grep -q '^SELFTEST PASS' "$W/self.log"; then ok "tools/close.py --selftest: $(grep -c '^  ok:' "$W/self.log") checks pass"
else bad "tools/close.py --selftest:"; grep 'FAIL' "$W/self.log" | head -4 | sed 's/^/        /'; fi

control() {  # control <name>
    if [ "$1" = verdict-ignored ]; then
        python3 tools/close.py --selftest --perturb verdict-ignored >"$W/vi.log" 2>&1
        if grep -q '^SELFTEST FAIL' "$W/vi.log"; then vs_ctl_fired "$1" "$(grep '^  FAIL' "$W/vi.log" | head -1 | cut -c1-120)"; ok "$1: fires"
        else vs_ctl_dead "$1" "the known-bad driver passed its self-test"; bad "$1"; fi
        return
    fi
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    if python3 tools/close.py check --root "$d" >"$d.log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep -qF -e "$EXPECT" "$d.log"; then
        vs_ctl_fired "$1" "$(grep -F -e "$EXPECT" "$d.log" | head -1)"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d.log" | head -6
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
