#!/bin/sh
# test_gate_descriptions.sh — EVERY GATE THAT DESCRIBES ITSELF KEEPS DOING SO, and the
# remainder only shrinks (GitHub #171 slice Q0, ruled 2026-09-24 — DECISIONS_HISTORY.md
# "Ruled 2026-09-24 (14z-180) — #171 gate qualification": "I want for each test a
# human-readable description of the test (at least what it tests, how it tests and what
# is the expected result)"). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: the census of `# WHAT:` / `# HOW:` / `# EXPECTS:` header fields over every
#   tests/*.sh — which gates DECLARE all three (grows only) and which are still
#   UNDECLARED (shrinks only) — equals the frozen tests/expected/gate_descriptions.tsv.
# HOW: tools/gate_descriptions.py (the ONE reader, shared with the gate-index generator)
#   parses each script's leading comment block; this gate compares the two classes with
#   the frozen file: a frozen `declares` gate that no longer declares is a red, a new
#   declaring gate is a red until the file is re-frozen after review (FREEZE=1), an
#   `undeclared` gate that now declares is likewise a re-freeze.
# EXPECTS: PASS when the census equals the frozen file exactly. A red names the gate
#   and its direction (lost its description / new description not yet frozen).
#
# MUST-FIRE: perturbed-copy: dropped-field — a copy of the tree with one declaring gate's `# WHAT:` field removed must class it undeclared and FAIL against the frozen file (mode: the census runs on that copy)
# MUST-FIRE: perturbed-copy: field-outside-block — a copy where a declaring gate's three fields sit below the first non-comment line must class it undeclared and FAIL (mode: the census runs on that copy)
#
# WHY A FROZEN CLASS FILE: the must-fire census's pattern (tests/test_must_fire_census.sh)
# — a retrofit over 378 scripts lands by family over several sittings, and "declares grows
# only" is what stops a description being dropped by a later edit unnoticed.
#
# Usage: tests/test_gate_descriptions.sh      # FREEZE=1 rewrites the frozen file after review
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
EXP=tests/expected/gate_descriptions.tsv
W="$(mktemp -d "${TMPDIR:-/tmp}/gdesc.XXXXXX")"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

census() { python3 tools/gate_descriptions.py --root "$1" 2>/dev/null | cut -f1,2 | sort; }
cls() { awk -F'\t' -v c="$1" '$1==c{print $2}' "$2" | sort; }

# perturb NAME ROOT — a copy of tests/ under ROOT with one defect planted
perturb() {
    mkdir -p "$2/tests"; cp tests/*.sh "$2/tests/"
    g="$(census . | awk -F'\t' '$1=="declares"{print $2; exit}')"
    [ -n "$g" ] || { echo "NONE"; return 1; }
    case "$1" in
        dropped-field) sed -i.bak '/^# WHAT:/d' "$2/tests/$g.sh" ;;
        field-outside-block)
            python3 - "$2/tests/$g.sh" <<'PY'
import re, sys
p = sys.argv[1]; lines = open(p).read().splitlines(True)
head, rest, fields, cur = [], [], [], None
for i, l in enumerate(lines):
    if i == 0 or (l.startswith('#') and not rest): head.append(l)
    else: rest.append(l)
kept = []
for l in head:
    if re.match(r'^# (WHAT|HOW|EXPECTS):', l): cur = True; fields.append(l); continue
    if cur and re.match(r'^#  +\S', l): fields.append(l); continue
    cur = None; kept.append(l)
open(p, 'w').write(''.join(kept) + ''.join(rest[:1]) + ''.join(fields) + ''.join(rest[1:]))
PY
            ;;
    esac
    rm -f "$2/tests/"*.bak
    echo "$g"
}

root="."
if [ -n "$VS_CTL" ]; then
    g="$(perturb "$VS_CTL" "$W/mode")"; root="$W/mode"
    [ "$g" != NONE ] || { echo "FAIL: no declaring gate in the tree to perturb — the control cannot run"; exit 1; }
    echo "MODE: control $VS_CTL — the census runs on a copy where $g.sh is perturbed"
fi

echo "== 1. the census against $EXP"
if [ ! -f "$EXP" ]; then
    [ "${FREEZE:-0}" = 1 ] || { echo "FAIL: $EXP missing — run FREEZE=1 after review"; exit 1; }
    echo "  (no frozen file yet — FREEZE=1 writes the first census)"; : > "$W/empty.tsv"; EXP_READ="$W/empty.tsv"
else EXP_READ="$EXP"; fi
census "$root" > "$W/got.tsv"
nd="$(grep -c '^declares' "$W/got.tsv")"; nu="$(grep -c '^undeclared' "$W/got.tsv")"
echo "  census: $nd declares, $nu undeclared"
cls declares "$EXP_READ" > "$W/exp_d.txt"; cls declares "$W/got.tsv" > "$W/got_d.txt"
lost="$(comm -23 "$W/exp_d.txt" "$W/got_d.txt")"
new="$(comm -13 "$W/exp_d.txt" "$W/got_d.txt")"
if [ -n "$lost" ]; then bad "a frozen declaring gate LOST its description: $(echo "$lost" | tr '\n' ' ')"; else ok "every frozen declaring gate still declares ($(wc -l < "$W/exp_d.txt" | tr -d ' ') frozen)"; fi
if [ -n "$new" ]; then
    if [ "${FREEZE:-0}" = 1 ]; then ok "new declaring gate(s) to freeze: $(echo "$new" | tr '\n' ' ')"
    else bad "new declaring gate(s) not yet frozen (review, then FREEZE=1): $(echo "$new" | tr '\n' ' ')"; fi
fi
cls undeclared "$EXP_READ" > "$W/exp_u.txt"; cls undeclared "$W/got.tsv" > "$W/got_u.txt"
grew="$(comm -13 "$W/exp_u.txt" "$W/got_u.txt")"
grew="$(printf '%s\n' "$grew" | grep -vxF -f "$W/exp_d.txt" || true)"   # a lost declarer is reported above, once
if [ -n "$grew" ]; then
    if [ "${FREEZE:-0}" = 1 ]; then ok "new undeclared gate(s) (new scripts) to freeze: $(echo "$grew" | tr '\n' ' ')"
    else bad "undeclared grew by a gate the frozen file does not know (a new script: describe it, or FREEZE=1 after review): $(echo "$grew" | tr '\n' ' ')"; fi
fi

if [ "${FREEZE:-0}" = 1 ] && [ -z "$VS_CTL" ]; then
    { echo "# tests/expected/gate_descriptions.tsv — which gates DESCRIBE themselves with the"
      echo "# three header fields # WHAT: / # HOW: / # EXPECTS: (declares GROWS only) and which"
      echo "# do not yet (undeclared SHRINKS only). GitHub #171 slice Q0. Gate:"
      echo "# tests/test_gate_descriptions.sh; reader tools/gate_descriptions.py. Regenerate"
      echo "# with FREEZE=1 after review. class<TAB>gate"
      cat "$W/got.tsv"; } > "$EXP"
    echo "  FROZE $EXP ($nd declares, $nu undeclared)"; fail=0
fi

if [ -z "$VS_CTL" ]; then
    echo "== 2. controls: each perturbation of a copy must be caught"
    for c in dropped-field field-outside-block; do
        g="$(perturb "$c" "$W/$c")"
        [ "$g" != NONE ] || { vs_ctl_dead "$c" "no declaring gate in the tree to perturb"; fail=1; continue; }
        if census "$W/$c" | grep -qx "declares	$g"; then vs_ctl_dead "$c" "$g still classed declares after the perturbation"; fail=1
        else vs_ctl_fired "$c" "$g classed undeclared on the perturbed copy"; fi
    done
fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
