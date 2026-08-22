#!/bin/sh
# test_jtcores_twin.sh — the MiSTer core scaffold is a TWIN of the reference
# core, and the three copies of its delta agree (14z-106).
#
# WHAT IT LOCKS (ROM-free, no emulator, seconds; ci_portable):
#  1. emu/jtcores sits at the pin tools/setup_jtcores.sh names.
#  2. cores/cps2w/cfg is cores/cps2/cfg modulo EXACTLY the lines the
#     scaffold is allowed to change: CORENAME in macros.def, the mustbe
#     block in mame2mra.toml, and the msg banner. game.yaml (the RTL pull
#     list) must be IDENTICAL — that is what makes "no RTL differs yet"
#     true by construction, and any later RTL override must move this gate
#     deliberately.
#  3. emu/jtcores-patches/0001-cps2w-scaffold.patch reproduces
#     `git format-patch <v1.7.3>..<pin>` of the submodule byte-for-byte —
#     the in-tree reviewable mirror cannot drift from the fork.
#  4. Must-fire control: a perturbed copy of game.yaml FAILS section 2.
# Usage: tests/test_jtcores_twin.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/emu/jtcores"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }
[ -f "$SRC/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }

PIN="$(sed -n 's/^PINNED="\([0-9a-f]*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
UP="$(sed -n 's/^UPSTREAM_TAG_SHA="\([0-9a-f]*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
HEAD="$(git -C "$SRC" rev-parse HEAD)"
[ "$HEAD" = "$PIN" ] && ok "1 pin $PIN" || bad "1 emu/jtcores at $HEAD, pin $PIN"

A="$SRC/cores/cps2/cfg"; B="$SRC/cores/cps2w/cfg"
cmp -s "$A/game.yaml" "$B/game.yaml" && ok "2a game.yaml identical (no RTL override)" || bad "2a game.yaml differs"
d="$(diff "$A/macros.def" "$B/macros.def" | grep '^[<>]' | tr '\n' '|')"
[ "$d" = "< CORENAME=JTCPS2|> CORENAME=JTCPS2W|" ] && ok "2b macros.def differs by CORENAME only" || bad "2b macros.def delta: $d"
d="$(diff "$A/mame2mra.toml" "$B/mame2mra.toml" | grep '^[<>]' | grep -v '^> #' | tr '\n' '|')"
[ "$d" = '> mustbe.machines=[ "vsav" ]|' ] && ok "2c mame2mra.toml differs by the vsav mustbe only" || bad "2c mame2mra.toml delta: $d"
[ -f "$B/msg" ] && ok "2d msg present" || bad "2d msg missing"

P="$REPO/emu/jtcores-patches/0001-cps2w-scaffold.patch"
if git -C "$SRC" format-patch --stdout "$UP..$PIN" | cmp -s - "$P"; then ok "3 patch mirror == format-patch $UP..$PIN"; else bad "3 patch mirror drifted"; fi

# 4 must-fire control (pure-text twin of check 2a).
T="$(mktemp)"; { cat "$A/game.yaml"; echo "      - jtcps2_extra.v"; } > "$T"
cmp -s "$A/game.yaml" "$T" && bad "4 control: perturbed yaml compared equal" || ok "4 control fired"
rm -f "$T"
[ $fail = 0 ] && echo "PASS test_jtcores_twin" || { echo "FAIL test_jtcores_twin"; exit 1; }
