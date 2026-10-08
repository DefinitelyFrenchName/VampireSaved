#!/bin/sh
# test_mame_ident.sh — A GATE'S HEADER NAMES WHICH MAME RAN (14z-195, rule-checker run 2026-10-08-740 Q1).
# ci_static: stub binaries only, no emulator, <1 s.
#
# WHAT: tests/lib/mame_ident.sh's vs_mame_ident accepts a binary whose `-version` is the release of the pin
#   tools/setup_mame.sh holds and names which pinned build it is (stock reference: `-listfull vsavjw` finds no
#   system; CPS-2 WIDE: it knows vsavjw), and refuses one of another release or one that answers neither.
# HOW: four stub executables written here answer -version and -listfull as each case needs; the pin is read from
#   the real tools/setup_mame.sh, so a moved pin moves the expectation with it.
# EXPECTS: stock 0.288 accepted as "the stock reference build"; WIDE 0.288 accepted as "the CPS-2 WIDE build";
#   0.287 REFUSED (not the pin's release); an executable that is not MAME REFUSED (neither answer).
# FOLLOWS: tests/lib/mame_ident.sh tools/setup_mame.sh tests/lib/controls.sh
#
# MUST-FIRE: perturbed-copy: release-ignored — a copy of the helper with its release comparison removed must ACCEPT the 0.287 stub, so the refusal case catches it (in-gate; as a mode the copy is used and the gate FAILs)
#
# WHY: the #118 gates (audit_mizuumi_inputs, audit_extra_pass, audit_mizuumi_attack) proved only that $MAME_BIN was
# executable; their logs named the path, never the MAME.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/mameid.XXXXXX")"; trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

stub() {  # stub <name> <version line> <listfull first line>
    printf '#!/bin/sh\ncase "$1" in -version) echo "%s" ;; -listfull) echo "%s" ;; esac\n' "$2" "$3" > "$W/$1"; chmod +x "$W/$1"
}
WANT="$(sed -n 's/^PINNED=.*# tag mame\([0-9]\)\([0-9]*\).*/\1.\2/p' tools/setup_mame.sh | head -1)"
[ -n "$WANT" ] || { echo "FAIL: no pin tag in tools/setup_mame.sh"; exit 1; }
stub stock "$WANT (unknown)" "No matching systems found for 'vsavjw'"
stub wide "$WANT (unknown)" "Name:             Description:"
stub old "0.0 (unknown)" "No matching systems found for 'vsavjw'"
cp /bin/echo "$W/notmame"

helper() {  # helper <out> — the helper as shipped, or (release-ignored) with its release comparison removed
    if [ "${1:-}" = release-ignored ]; then
        sed 's/^    case "\$_ver" in .*$/    :/' tests/lib/mame_ident.sh > "$W/helper.sh"
        cmp -s tests/lib/mame_ident.sh "$W/helper.sh" && { echo "REFUSED: the perturbation changed nothing"; exit 3; }
    else cp tests/lib/mame_ident.sh "$W/helper.sh"; fi
}
run() { ( . "$W/helper.sh"; vs_mame_ident "$W/$1" ) > "$W/$1.out" 2>&1; }

judge() {  # judge -> sets the four verdicts from the current helper
    run stock && grep -q 'the stock reference build' "$W/stock.out" && S_OK=1 || S_OK=0
    run wide && grep -q 'the CPS-2 WIDE build' "$W/wide.out" && WI_OK=1 || WI_OK=0
    run old && O_OK=0 || { grep -q "is not the pin's release" "$W/old.out" && O_OK=1 || O_OK=0; }
    run notmame && N_OK=0 || { grep -q 'gave neither answer' "$W/notmame.out" && N_OK=1 || N_OK=0; }
}

helper "$( [ "${VS_CTL:-}" = release-ignored ] && echo release-ignored )"
judge
echo "== the pin: release $WANT (tools/setup_mame.sh)"
[ "$S_OK" = 1 ] && ok "a stock $WANT binary is accepted as the stock reference build" || bad "the stock stub: $(cat "$W/stock.out")"
[ "$WI_OK" = 1 ] && ok "a WIDE $WANT binary is accepted as the CPS-2 WIDE build" || bad "the WIDE stub: $(cat "$W/wide.out")"
[ "$O_OK" = 1 ] && ok "a 0.0 binary is REFUSED (not the pin's release)" || bad "the 0.0 stub was not refused for its release: $(cat "$W/old.out")"
[ "$N_OK" = 1 ] && ok "an executable that is not MAME is REFUSED" || bad "the non-MAME executable was not refused: $(cat "$W/notmame.out")"

if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 1 ] && { vs_ctl_fired "$VS_CTL" "the helper without its release comparison accepted the 0.0 stub"; echo "FAIL: test_mame_ident (control mode)"; exit 1; }
    echo "REFUSED: CONTROL=$VS_CTL — the perturbation did not make the gate fail: a dead mode, not a verdict"; exit 3
fi
echo "== controls"
helper release-ignored; judge
[ "$O_OK" = 0 ] && vs_ctl_fired release-ignored "the copy without the release comparison let the 0.0 stub through" \
    || { vs_ctl_dead release-ignored "the copy still refused the 0.0 stub" || fail=1; }
if [ "$fail" = 0 ]; then echo "PASS: test_mame_ident"; else echo "FAIL: test_mame_ident"; exit 1; fi
