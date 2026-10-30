#!/bin/sh
# test_history_index.sh — every archive opens with a CURRENT generated index (GitHub #282 item E, 14z-201).
# ci_portable: no ROM, no build dir, no emulator, ~2 s.
#
# WHAT: each `*_HISTORY.md` at the root and each `*_history.md` / `*_HISTORY.md` under docs/ carries, after its title,
#   the block tools/gen_history_index.py generates — one `- L<line> <heading>` line per entry, the line number exact in
#   the file as written — and the block equals a fresh regeneration; no archive exists that the tool does not configure.
# HOW: tools/gen_history_index.py --check over the tree (~2 s); controls on a copy of the archives append an entry,
#   hand-edit the block, and add an unconfigured archive.
# EXPECTS: the tree passes; each perturbed copy fails --check and the failure names what moved.
#
# MUST-FIRE: perturbed-copy: new-entry — a `## ` entry appended to DECISIONS_HISTORY.md must fail --check as a STALE index, or an entry can be archived without reaching the index
# MUST-FIRE: perturbed-copy: hand-edited-index — a line hand-added to an index block must fail --check, or the index stops being generated
# MUST-FIRE: perturbed-copy: unconfigured-archive — a new docs/**/*_history.md the tool has no entry pattern for must fail --check by name, or a new archive goes unindexed
#
# WHY. The maintainer's ask (#282): "_HISTORY FILES should beging with an index to immediately be able to access a
# section". The archives run to thousands of lines (STATE_HISTORY.md over 30,000); an index with exact line numbers
# lets a reader open an entry with one Read at its offset. Every edit above an entry moves the numbers, so the index
# is regenerated in the commit that changes the archive (`python3 tools/gen_history_index.py`), and this gate fails a
# stale one. The tool writes only the block: archived entries are never rewritten (CLAUDE.md [VSP-17]).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_history_index — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM

FILES="$(python3 -c "import sys; sys.path.insert(0, 'tools'); import gen_history_index as g; print(' '.join(sorted(set(g.archives('.')) | set(g.ENTRY))))")"
mkcopy() { for f in $FILES; do [ -f "$f" ] || continue; mkdir -p "$1/$(dirname "$f")"; cp "$f" "$1/$f"; done; }
perturb() {  # perturb <name> <dir>; EXPECT = the failure's substring
    case "$1" in
    new-entry)            printf '\n## Ruled 2099-01-01 (14z-999) — a synthetic entry for the control\nbody\n' >> "$2/DECISIONS_HISTORY.md"; EXPECT="STALE index in DECISIONS_HISTORY.md" ;;
    hand-edited-index)    python3 - "$2/docs/project/tenant_manifest_history.md" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("<!-- /HISTORY INDEX -->", "- L1 a line somebody hand-added\n<!-- /HISTORY INDEX -->", 1)
open(p, "w").write(s)
PY
                          EXPECT="STALE index in docs/project/tenant_manifest_history.md" ;;
    unconfigured-archive) printf '# A synthetic archive\n\n## an entry\n' > "$2/docs/project/zz_control_history.md"; EXPECT="UNCONFIGURED archive docs/project/zz_control_history.md" ;;
    *) echo "no such perturbation: $1"; exit 3 ;;
    esac
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the tree the main check reads, and this run must FAIL.
ROOT="$REPO"
if [ -n "$VS_CTL" ]; then mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT="$W/mode"; fi

echo "== test_history_index: every archive opens with a current generated index =="
if python3 tools/gen_history_index.py --root "$ROOT" --check >"$W/tree.log" 2>&1; then
    ok "$(tail -1 "$W/tree.log")"
else
    bad "gen_history_index.py --check FAILS:"; sed 's/^/        /' "$W/tree.log" | head -20
fi

control() {  # control <name>
    d="$W/$1"; mkcopy "$d"; perturb "$1" "$d"
    if python3 tools/gen_history_index.py --root "$d" --check >"$d/log" 2>&1; then
        vs_ctl_dead "$1" "the perturbed copy PASSED — the check is not checking"; bad "$1"
    elif grep -qF "$EXPECT" "$d/log"; then
        vs_ctl_fired "$1" "$EXPECT"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$d/log" | head -8
    fi
}
for n in $(vs_ctl_declared "$0"); do control "$n"; done

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
