#!/bin/sh
# audit_move_parity_attribution.sh — EVERY DIFF ROW OF THE #136 MOVE-PARITY TABLE HAS A MEASURED CAUSE, frozen (14z-168, GitHub #136): each root found by ablation (its event's inputs removed, both legs re-run, the rows that vanish are its) and named by a measured signature; no root may be OTHER and no row UNATTRIBUTED.
#
# WHAT: every DIFF row of the #136 move-parity table has a MEASURED cause: each root is
#   found by ablation (its event's inputs removed, both legs re-run, the rows that vanish
#   are its) and named by a measured signature class (METER-SWAP, SLOWDOWN, DF-STOCK,
#   ENTRANCE, GUARD-REENTRY, P2-DISPLACEMENT, TRAP-REMAP, COLUMN-SHOCK, DEFENSE-ROW /
#   PHOBOS-DMG-OPEN); no root is OTHER and no row UNATTRIBUTED.
# HOW: tools/move_parity_attribution.py on MAME: step 0 re-runs the committed rigs and must
#   reproduce the frozen table, then iterative ablation over the ~19 parts carrying a DIFF
#   with each root's signature read from its own window; the control disables ablation,
#   which must leave rows unattributed.
# EXPECTS: the frozen root and row tables equal (a fix changes them by design and is read as
#   the fix's effect), no OTHER, no UNATTRIBUTED; the no-ablation run fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/move_parity_attribution.tsv
#   tests/expected/move_parity_events.tsv tools/move_parity_attribution.py
#   tools/setup_mame.sh
#
# MUST-FIRE: shadow-tool: no-ablation — the tool with ablation disabled (roots classified, never removed) must leave rows UNATTRIBUTED and FAIL, so every attribution rests on a row actually vanishing when its root's inputs are removed (in-gate: donovan_11 alone with ablation disabled must leave its row unattributed; mode: the whole table with ablation disabled FAILs)
#
# WHY. The maintainer, 2026-09-18 (14z-168): "here we have many divergences which may
# or may not share sources so let's finish all the analysis first. Then we'll fix and
# then relentlessly test for regressions". tests/audit_move_parity.sh freezes 108 DIFF
# rows; a DIFF after an earlier one in its part may be downstream of it. This gate
# re-derives, on every run, WHICH root each row belongs to and WHAT kind of root it is,
# so a fix is judged by the rows it removes and a new divergence cannot hide inside an
# old family: a root no signature explains is OTHER and FAILS. The method, the steps
# and the signatures: tools/move_parity_attribution.py's docstring. The families, as
# frozen at 14z-168 on merged-m18: #157's throw meter (METER-SWAP), the Blizzard Sword
# CPU overruns (SLOWDOWN), the ruled Dark Force cost (DF-STOCK), the rig's opening
# (ENTRANCE), vsavj's block re-entry (GUARD-REENTRY, tests/audit_guard_reentry.sh), #159
# (P2-DISPLACEMENT), the ruled trap remap (TRAP-REMAP), the column shock (COLUMN-SHOCK,
# tests/audit_column_shock.sh), the defense row (DEFENSE-ROW; the vs2 rows ruled 2026-09-18, BUILT at the M19 freeze — on a build whose row
# 0x10 is already vs2's the same signature is PHOBOS-DMG-OPEN: Demitri's 5HP 11 native / 12 ours, cause unmeasured, an
# open ticket, ruled 2026-09-19 "Freeze, ticket it (Recommended)").
#
# WHAT IT FREEZES (tests/expected/move_parity_attribution.tsv), the tool's rows:
#   root <part:event | opening> <event name> <class> step=<n> <the signature's evidence>
#   row  <part> <event> <base | surfaced> <root> <class>
# ("surfaced": a row DIFF only once an earlier root is removed — a throw the committed
# rig never lands). A FIX CHANGES THIS FILE BY DESIGN: re-freeze it with the move-parity
# table, and read the diff as the fix's effect (rows gone, roots gone), never as noise.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [JOBS=6] [FREEZE=1] tests/audit_move_parity_attribution.sh
#   emulator tier, MAME; ~12 ablation steps over the 19 parts carrying a DIFF — measured 14z-168 on this MacBook, solo: ~5 min wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/move_parity_attribution.tsv"
EVENTS="$REPO/tests/expected/move_parity_events.tsv"
JOBS="${JOBS:-6}"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|no-ablation) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
TOOL="$REPO/tools/move_parity_attribution.py"

echo "== 1. the attribution (steps 0, E, 1..N)"
NA=""; [ "$CONTROL" = no-ablation ] && NA="--no-ablate"
python3 "$TOOL" run --build "$BUILD" --romdir "$ROMDIR" --work "$W/run" --jobs "$JOBS" --mame-bin "$MAME_BIN" $NA > "$W/got.tsv" 2> "$W/err" \
    || { bad "the tool: $(tail -1 "$W/err")"; }
[ "$fail" = 0 ] || { echo "FAIL: audit_move_parity_attribution"; exit 1; }
ok "$(grep -c '^root' "$W/got.tsv" | tr -d ' ') roots, $(grep -c '^row' "$W/got.tsv" | tr -d ' ') rows"
awk -F'\t' '$1=="row"{print "  " $6}' "$W/got.tsv" | sort | uniq -c | sed 's/^/ /'
n_other="$(awk -F'\t' '($1=="root" && $4=="OTHER") || ($1=="row" && ($5=="UNATTRIBUTED" || $6=="OTHER"))' "$W/got.tsv" | grep -c . || true)"
[ "$n_other" = 0 ] || { bad "$n_other root(s)/row(s) with no measured cause:"; awk -F'\t' '($1=="root" && $4=="OTHER") || ($1=="row" && ($5=="UNATTRIBUTED" || $6=="OTHER"))' "$W/got.tsv" | sed 's/^/        /' | head -12; }
# coverage both ways: every DIFF row of the frozen move-parity table is attributed, and nothing else is called base
awk -F'\t' '!/^#/ && $4=="DIFF" {print $1 "\t" $2}' "$EVENTS" | sort > "$W/diff_frozen.txt"
awk -F'\t' '$1=="row" && $4=="base" {print $2 "\t" $3}' "$W/got.tsv" | sort > "$W/diff_attr.txt"
if diff "$W/diff_frozen.txt" "$W/diff_attr.txt" > "$W/cov.txt"; then ok "every one of the $(wc -l < "$W/diff_frozen.txt" | tr -d ' ') frozen DIFF rows is attributed"
else bad "the attributed rows and the frozen DIFF rows differ:"; sed 's/^/        /' "$W/cov.txt" | head -10; fi

echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] || { echo "FAIL: refusing to freeze an attribution with unexplained rows"; exit 1; }
    {
        echo "# tests/expected/move_parity_attribution.tsv — the cause of every DIFF row of tests/expected/move_parity_events.tsv, by ablation"
        echo "# and a measured signature (tests/audit_move_parity_attribution.sh; tools/move_parity_attribution.py). Evidence class:"
        echo "# in-emulator. Frozen 14z-168 with FREEZE=1 on $(basename "$BUILD") (GitHub #136). A FIX CHANGES THIS FILE BY DESIGN — re-freeze it"
        echo "# with the move-parity table and read the diff as the fix's effect."
        echo "# Columns: root <part:event|opening> <name> <class> step=<n> <evidence> | row <part> <event> <base|surfaced> <root> <class>"
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt" | head -20; fi

echo "== 3. must-fire control"
if [ "$CONTROL" = no-ablation ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: no-ablation — without removing roots, rows stay unattributed"; echo "FAIL: audit_move_parity_attribution (control mode)"; exit 1
    else echo "CONTROL DEAD: no-ablation — the table was attributed without any ablation"; echo "FAIL: audit_move_parity_attribution"; exit 1; fi
fi
python3 "$TOOL" run --build "$BUILD" --romdir "$ROMDIR" --work "$W/ctl" --jobs "$JOBS" --mame-bin "$MAME_BIN" --parts donovan_11 --no-ablate > "$W/ctl.tsv" 2>/dev/null || true
if awk -F'\t' '$1=="row" && $2=="donovan_11" && $5=="UNATTRIBUTED"' "$W/ctl.tsv" | grep -q .; then
    echo "CONTROL FIRED: no-ablation — donovan_11's row stays UNATTRIBUTED when its root is not removed"
else echo "CONTROL DEAD: no-ablation — donovan_11 was attributed without ablation ($(grep '^row' "$W/ctl.tsv" | head -1))"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_move_parity_attribution"; else echo "FAIL: audit_move_parity_attribution"; exit 1; fi
