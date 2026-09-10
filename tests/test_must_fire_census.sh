#!/bin/sh
# test_must_fire_census.sh — THE MUST-FIRE DOCTRINE, MACHINE-READ: which gates
# declare a must-fire control, frozen so the inventory can only GROW, and which
# of them carry the control as HEADER PROSE ONLY, frozen so that debt can only
# SHRINK. (14z-145, step one of the maintainer's ruling on the BBX finding.)
#
# WHY. [VSP-19] says verdict logic is itself tested and the project's convention
# for that is the MUST-FIRE CONTROL — a perturbation that must turn the gate
# red. Measured 2026-09-10: 77 of 314 gates declare one, in roughly fifteen
# spellings, and NOTHING read them — the count in harness_scope.md was a hand
# grep, and the BBX extraction found six such counts wrong on any other host
# (docs/project/gotchas.md, the ugrep entry). Worse, 10 of the 77 declare a
# control in the header and print no control verdict at run time: a promise
# with no evidence in the log, which is how the two dead controls of 14z-133
# hid until a sweep read the logs by hand.
#
# WHAT IT HOLDS (static, ROM-free, ~1 s):
#   1. every gate under tests/*.sh that MENTIONS a must-fire control (one regex,
#      owned here, covering the spellings in use) is in the frozen inventory —
#      a gate dropping its declaration FAILS, a new declaring gate must be added
#      (the list only grows);
#   2. the HEADER-ONLY set — declaring gates whose non-comment code prints no
#      control verdict (no `control`/`fired` outside comments) — equals the
#      frozen debt or is SMALLER; a gate JOINING it FAILS. Retiring a row means
#      the gate now prints its control's verdict;
#   3. MUST-FIRE CONTROLS on the census itself: a copy of the tree with one
#      declaration removed fails 1; a copy with one gate's control lines
#      commented out fails 2.
# WHAT IT DOES NOT CLAIM: that a printed verdict is HONEST — a control that
# writes a value and asserts it is not something else prints "fired" too
# (14z-144). That is step two, the run-time contract, and a [VSP-19] review per
# control; this gate only makes the doctrine countable and the debt visible.
#
# Usage: tests/test_must_fire_census.sh   [FREEZE=1 to re-freeze]   # ci_portable
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
EXP=tests/expected/must_fire_census.tsv
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
bad=0; ok() { echo "  ok    $1"; }; nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }

# The census as ONE function over a tests dir, so the controls run the real thing.
census() {  # $1 = tests dir -> prints "declares\t<gate>" and "header-only\t<gate>" lines, sorted
    for f in "$1"/*.sh; do
        g="$(basename "$f" .sh)"
        /usr/bin/grep -qiE 'must[- ]?fire' "$f" || continue
        echo "declares	$g"
        if ! /usr/bin/grep -v '^[[:space:]]*#' "$f" | /usr/bin/grep -qiE 'control|fired'; then
            echo "header-only	$g"
        fi
    done | sort
}

echo "== test_must_fire_census: the must-fire doctrine, machine-read =="
census tests > "$W/got.txt"
nd="$(/usr/bin/grep -c '^declares' "$W/got.txt")"; nh="$(/usr/bin/grep -c '^header-only' "$W/got.txt")"
echo "  measured: $nd gates declare a must-fire control; $nh of them as header prose only"

if [ "${FREEZE:-0}" = 1 ]; then
    { echo "# tests/expected/must_fire_census.tsv — gates that DECLARE a must-fire control"
      echo "# (grows only) and those whose control is HEADER PROSE ONLY (shrinks only)."
      echo "# Gate: tests/test_must_fire_census.sh. Regenerate with FREEZE=1 after review."
      echo "# class<TAB>gate"; cat "$W/got.txt"; } > "$EXP"
    echo "  FROZE $EXP ($nd declaring, $nh header-only)"
fi
[ -f "$EXP" ] || { nope "no $EXP — freeze it first (FREEZE=1)"; echo "FAIL: test_must_fire_census"; exit 1; }
/usr/bin/grep -v '^#' "$EXP" > "$W/exp.txt"

echo "== 1. the declaring inventory can only GROW"
/usr/bin/grep '^declares' "$W/exp.txt" | sort > "$W/exp_d.txt"; /usr/bin/grep '^declares' "$W/got.txt" | sort > "$W/got_d.txt"
if comm -23 "$W/exp_d.txt" "$W/got_d.txt" | /usr/bin/grep -q .; then
    nope "a gate DROPPED its must-fire declaration:"; comm -23 "$W/exp_d.txt" "$W/got_d.txt" | sed 's/^/        /'
else ok "every frozen declaring gate still declares ($(wc -l < "$W/exp_d.txt" | tr -d ' ') frozen)"; fi
if comm -13 "$W/exp_d.txt" "$W/got_d.txt" | /usr/bin/grep -q .; then
    nope "new declaring gate(s) not in the inventory — add them (FREEZE=1 after review):"; comm -13 "$W/exp_d.txt" "$W/got_d.txt" | sed 's/^/        /'
else ok "no unlisted declaring gate"; fi

echo "== 2. the header-only DEBT can only SHRINK"
/usr/bin/grep '^header-only' "$W/exp.txt" | sort > "$W/exp_h.txt"; /usr/bin/grep '^header-only' "$W/got.txt" | sort > "$W/got_h.txt"
if comm -13 "$W/exp_h.txt" "$W/got_h.txt" | /usr/bin/grep -q .; then
    nope "a gate JOINED the header-only debt (declares a control, prints no verdict for it):"; comm -13 "$W/exp_h.txt" "$W/got_h.txt" | sed 's/^/        /'
else ok "no gate joined the header-only debt ($(wc -l < "$W/exp_h.txt" | tr -d ' ') frozen)"; fi
if comm -23 "$W/exp_h.txt" "$W/got_h.txt" | /usr/bin/grep -q .; then
    echo "  note  retired from the debt (re-freeze to record):"; comm -23 "$W/exp_h.txt" "$W/got_h.txt" | sed 's/^/        /'
fi

echo "== 3. must-fire controls on the census"
mkdir -p "$W/t1" "$W/t2"; cp tests/*.sh "$W/t1/"; cp tests/*.sh "$W/t2/"
d1="$(/usr/bin/grep '^declares' "$W/got.txt" | head -1 | cut -f2)"
perl -pi -e 's/must[- ]?fire/must-XX/gi' "$W/t1/$d1.sh"     # case-INsensitive, like the census
census "$W/t1" | /usr/bin/grep -qx "declares	$d1" && nope "control (a) did not fire: removing $d1's declaration left it in the census" || ok "control (a) fires: a removed declaration ($d1) drops out of the inventory"
h1="$(/usr/bin/grep '^declares' "$W/got.txt" | cut -f2 | while read -r g; do /usr/bin/grep -qx "header-only	$g" "$W/got.txt" || { echo "$g"; break; }; done)"
perl -pe 'next if /^\s*#/; s/control/cXntrol/gi; s/fired/fXred/gi' "tests/$h1.sh" > "$W/t2/$h1.sh"   # non-comment lines only, case-insensitive
census "$W/t2" | /usr/bin/grep -qx "header-only	$h1" && ok "control (b) fires: $h1 with its control lines neutered joins the header-only set" || nope "control (b) did not fire on $h1"

[ "$bad" = 0 ] && { echo "PASS: test_must_fire_census — $nd declaring, $nh header-only"; exit 0; }
echo "FAIL: test_must_fire_census ($bad)"; exit 1
