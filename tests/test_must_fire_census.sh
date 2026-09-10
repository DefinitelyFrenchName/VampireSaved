#!/bin/sh
# test_must_fire_census.sh — THE MUST-FIRE DOCTRINE, MACHINE-READ under the
# R10 grammar: which gates DECLARE a must-fire control (`# MUST-FIRE: <shape>:
# <name> — …`, frozen so the inventory can only GROW), which declare and print
# no run-time verdict (HEADER-ONLY, shrinks only), and which still MENTION a
# control in the pre-grammar spellings without declaring one (the RETROFIT
# DEBT, shrinks only). (14z-145 step one; 14z-147 step two switched the census
# to the contract's own reader, tests/lib/controls.sh.)
#
# MUST-FIRE: perturbed-copy: dropped-declaration — a copy of tests/ with one gate's `# MUST-FIRE:` line neutered must drop that gate from the declaring inventory (section 1 fails), or the inventory is not read from the header
# MUST-FIRE: perturbed-copy: neutered-verdict — a copy with one declaring gate's `CONTROL FIRED:` lines commented out must put that gate in the header-only set (section 2 fails), or "prints a verdict" is not measured
#
# WHY. [VSP-19] says verdict logic is itself tested and the project's convention
# for that is the MUST-FIRE CONTROL — a perturbation that must turn the gate
# red. Measured 2026-09-10: 77 of 314 gates declared one, in roughly fifteen
# spellings, and NOTHING read them — the count in harness_scope.md was a hand
# grep, and the BBX extraction found six such counts wrong on any other host
# (docs/project/gotchas.md, the ugrep entry). Worse, 10 of the 77 declared a
# control in the header and printed no control verdict at run time: a promise
# with no evidence in the log, which is how the two dead controls of 14z-133
# hid until a sweep read the logs by hand. Step two (14z-147) gave the
# declaration ONE grammar and the runners a reader; this gate freezes the
# three inventories the reader sees.
#
# WHAT IT HOLDS (static, ROM-free, ~1 s):
#   1. every gate whose LEADING COMMENT BLOCK carries an R10 declaration is in
#      the frozen inventory — a gate dropping its declaration FAILS, a new
#      declaring gate must be added (the list only grows);
#   2. the HEADER-ONLY set — declaring gates whose non-comment code prints no
#      `CONTROL FIRED:` / `CONTROL DEAD:` line (as the literal or through the
#      lib's `vs_ctl_fired` / `vs_ctl_dead`) — equals the frozen debt or is
#      SMALLER; a gate JOINING it FAILS. Retiring a row means the gate now
#      prints its control's verdict;
#   3. the RETROFIT DEBT — gates that mention `must-fire` in any spelling and
#      declare nothing under the grammar — can only SHRINK;
#   4. the two controls above, on perturbed copies of tests/, through the same
#      census function.
# WHAT IT DOES NOT CLAIM: that a printed verdict is HONEST. That is the
# runners' job now — every runner reads FIRED/DEAD against the header, and
# run_all_static.sh EXECUTES each declared control (`CONTROL=<name>`) and
# requires the gate's own FAIL. This gate only makes the doctrine countable.
#
# Usage: tests/test_must_fire_census.sh   [FREEZE=1 to re-freeze]   # ci_portable
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
EXP=tests/expected/must_fire_census.tsv
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
bad=0; ok() { echo "  ok    $1"; }; nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }

# The census as ONE function over a tests dir, so the controls run the real thing.
census() {  # $1 = tests dir -> "declares|header-only|retrofit-debt\t<gate>" lines, sorted
    for f in "$1"/*.sh; do
        g="$(basename "$f" .sh)"
        if [ -n "$(vs_ctl_declared "$f")" ]; then
            echo "declares	$g"
            /usr/bin/grep -v '^[[:space:]]*#' "$f" | /usr/bin/grep -qE 'CONTROL (FIRED|DEAD): |vs_ctl_(fired|dead) ' \
                || echo "header-only	$g"
        elif /usr/bin/grep -qiE 'must[- ]?fire' "$f" && [ -z "$(vs_ctl_none "$f")" ]; then
            echo "retrofit-debt	$g"
        fi
    done | sort
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the input.
SRC=tests
if vs_ctl_is dropped-declaration; then
    mkdir -p "$W/in"; cp tests/*.sh "$W/in/"; SRC="$W/in"
    d1="$(census tests | /usr/bin/grep '^declares' | head -1 | cut -f2)"
    perl -pi -e 's/^# MUST-FIRE: /# MUST-XX: /' "$SRC/$d1.sh"
elif vs_ctl_is neutered-verdict; then
    mkdir -p "$W/in"; cp tests/*.sh "$W/in/"; SRC="$W/in"
    h1="$(census tests | awk -F'\t' '$1=="declares"{d[$2]=1} $1=="header-only"{h[$2]=1} END{for(g in d) if(!(g in h)) print g}' | sort | head -1)"
    perl -pi -e 'next if /^\s*#/; s/CONTROL (FIRED|DEAD): /CONTROL XXXXX: /g; s/vs_ctl_(fired|dead) /vs_ctl_XXXX /g' "$SRC/$h1.sh"
fi

echo "== test_must_fire_census: the must-fire doctrine, machine-read (R10 grammar) =="
census "$SRC" > "$W/got.txt"
nd="$(/usr/bin/grep -c '^declares' "$W/got.txt")"; nh="$(/usr/bin/grep -c '^header-only' "$W/got.txt")"; nr="$(/usr/bin/grep -c '^retrofit-debt' "$W/got.txt")"
echo "  measured: $nd gates declare under the grammar; $nh header-only; $nr mention a control without declaring (retrofit debt)"
echo "NOTE: must-fire.declaring $nd header-only $nh retrofit-debt $nr"

if [ "${FREEZE:-0}" = 1 ] && [ "$SRC" = tests ]; then
    { echo "# tests/expected/must_fire_census.tsv — gates that DECLARE a must-fire control under"
      echo "# the R10 grammar (grows only), those whose control is HEADER-ONLY (shrinks only),"
      echo "# and the RETROFIT DEBT — pre-grammar mentions with no declaration (shrinks only)."
      echo "# Gate: tests/test_must_fire_census.sh. Regenerate with FREEZE=1 after review."
      echo "# class<TAB>gate"; cat "$W/got.txt"; } > "$EXP"
    echo "  FROZE $EXP ($nd declaring, $nh header-only, $nr retrofit debt)"
fi
[ -f "$EXP" ] || { nope "no $EXP — freeze it first (FREEZE=1)"; echo "FAIL: test_must_fire_census"; exit 1; }
/usr/bin/grep -v '^#' "$EXP" > "$W/exp.txt"

cls() { /usr/bin/grep "^$1	" "$2" | sort; }
echo "== 1. the declaring inventory can only GROW"
cls declares "$W/exp.txt" > "$W/exp_d.txt"; cls declares "$W/got.txt" > "$W/got_d.txt"
if comm -23 "$W/exp_d.txt" "$W/got_d.txt" | /usr/bin/grep -q .; then
    nope "a gate DROPPED its must-fire declaration:"; comm -23 "$W/exp_d.txt" "$W/got_d.txt" | sed 's/^/        /'
else ok "every frozen declaring gate still declares ($(wc -l < "$W/exp_d.txt" | tr -d ' ') frozen)"; fi
if comm -13 "$W/exp_d.txt" "$W/got_d.txt" | /usr/bin/grep -q .; then
    nope "new declaring gate(s) not in the inventory — add them (FREEZE=1 after review):"; comm -13 "$W/exp_d.txt" "$W/got_d.txt" | sed 's/^/        /'
else ok "no unlisted declaring gate"; fi

echo "== 2. the header-only DEBT can only SHRINK"
cls header-only "$W/exp.txt" > "$W/exp_h.txt"; cls header-only "$W/got.txt" > "$W/got_h.txt"
if comm -13 "$W/exp_h.txt" "$W/got_h.txt" | /usr/bin/grep -q .; then
    nope "a gate JOINED the header-only debt (declares a control, prints no CONTROL FIRED/DEAD line):"; comm -13 "$W/exp_h.txt" "$W/got_h.txt" | sed 's/^/        /'
else ok "no gate joined the header-only debt ($(wc -l < "$W/exp_h.txt" | tr -d ' ') frozen)"; fi
if comm -23 "$W/exp_h.txt" "$W/got_h.txt" | /usr/bin/grep -q .; then
    echo "  note  retired from the debt (re-freeze to record):"; comm -23 "$W/exp_h.txt" "$W/got_h.txt" | sed 's/^/        /'
fi

echo "== 3. the RETROFIT DEBT (pre-grammar mentions, no declaration) can only SHRINK"
cls retrofit-debt "$W/exp.txt" > "$W/exp_r.txt"; cls retrofit-debt "$W/got.txt" > "$W/got_r.txt"
if comm -13 "$W/exp_r.txt" "$W/got_r.txt" | /usr/bin/grep -q .; then
    nope "a gate JOINED the retrofit debt (mentions a must-fire control, declares none — write the # MUST-FIRE: line):"; comm -13 "$W/exp_r.txt" "$W/got_r.txt" | sed 's/^/        /'
else ok "no gate joined the retrofit debt ($(wc -l < "$W/exp_r.txt" | tr -d ' ') frozen)"; fi
if comm -23 "$W/exp_r.txt" "$W/got_r.txt" | /usr/bin/grep -q .; then
    echo "  note  retired from the retrofit debt (re-freeze to record):"; comm -23 "$W/exp_r.txt" "$W/got_r.txt" | sed 's/^/        /'
fi

echo "== 4. must-fire controls on the census"
mkdir -p "$W/t1" "$W/t2"; cp tests/*.sh "$W/t1/"; cp tests/*.sh "$W/t2/"
d1="$(/usr/bin/grep '^declares' "$W/got.txt" | head -1 | cut -f2)"
perl -pi -e 's/^# MUST-FIRE: /# MUST-XX: /' "$W/t1/$d1.sh"
if census "$W/t1" | /usr/bin/grep -qx "declares	$d1"; then vs_ctl_dead dropped-declaration "removing $d1's declaration left it in the census"; nope "control (a)"
else vs_ctl_fired dropped-declaration "a neutered declaration ($d1) drops out of the inventory"; ok "control (a) fires"; fi
h1="$(awk -F'\t' '$1=="declares"{d[$2]=1} $1=="header-only"{h[$2]=1} END{for(g in d) if(!(g in h)) print g}' "$W/got.txt" | sort | head -1)"
perl -pi -e 'next if /^\s*#/; s/CONTROL (FIRED|DEAD): /CONTROL XXXXX: /g; s/vs_ctl_(fired|dead) /vs_ctl_XXXX /g' "$W/t2/$h1.sh"
if census "$W/t2" | /usr/bin/grep -qx "header-only	$h1"; then vs_ctl_fired neutered-verdict "$h1 with its FIRED/DEAD lines neutered joins the header-only set"; ok "control (b) fires"
else vs_ctl_dead neutered-verdict "$h1 with its verdict lines neutered did not join the header-only set"; nope "control (b)"; fi

[ "$bad" = 0 ] && { echo "PASS: test_must_fire_census — $nd declaring, $nh header-only, $nr retrofit debt"; exit 0; }
echo "FAIL: test_must_fire_census ($bad)"; exit 1
