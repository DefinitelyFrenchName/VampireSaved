#!/bin/sh
# test_jtcores_twin.sh — the MiSTer core scaffold is a TWIN of the reference
# core, and the three copies of its delta agree (14z-106).
#
# WHAT IT LOCKS (ROM-free, no emulator, seconds; ci_portable):
#  1. emu/jtcores sits at the pin tools/setup_jtcores.sh names.
#  2. cores/cps2w/cfg is cores/cps2/cfg modulo EXACTLY the lines the core is
#     DECLARED to change (check 2c carries the list verbatim): CORENAME in
#     macros.def, and in mame2mra.toml the `vsav` mustbe, the cps2w.cpp
#     sourcefile opt-in and the `qsoundw` trim region of slice D0. game.yaml
#     (the RTL pull list) must be IDENTICAL — that is what makes "no RTL
#     differs yet" true by construction, and any later RTL override must move
#     this gate deliberately.
#  3. emu/jtcores-patches/ reproduces the fork's commits as a PATCH SERIES,
#     byte-for-byte: file i == `git format-patch -1 <i-th commit after
#     v1.7.3>`, the directory holds EXACTLY the declared names, and the
#     series length equals the commit count. The in-tree reviewable mirror
#     cannot drift from the fork, and a new fork commit cannot land
#     unmirrored (14z-107: it was a single hardcoded file until the sim
#     work-RAM hook became commit 2).
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
# 2c THE DECLARED cfg DELTA. Comments and blank lines on the cps2w side are
# filtered out (prose is meant to be edited); every SUBSTANTIVE line is frozen
# below, so a region row, an order entry or a parse key that nobody declared
# fails here. The `parts=` CRC is normalised away on purpose — it is the built
# romset's identity, not the core's structure, and tests/test_mister_mra_map.sh
# is what checks it is the CURRENT build's. MOVED DELIBERATELY 14z-107 (5)
# when slice D0 added the MiSTer QSound trim; it was "the vsav mustbe only".
d="$(diff "$A/mame2mra.toml" "$B/mame2mra.toml" | grep '^[<>]' \
     | grep -v '^> *#' | grep -v '^> *$' | sed 's/crc="[0-9a-f]*"/crc="<build>"/')"
want='< sourcefile=[ "cps2.cpp" ]
> sourcefile=[ "cps2.cpp", "cps2w.cpp" ]
> mustbe.machines=[ "vsav" ]
>     { name="qsoundw", skip=true },
>     { name="qsoundw", width=16, setname="vsavjw", parts=[
>         { name="vsw.21m", crc="<build>", map="12", length=0x0F0000, offset=0 },
>     ] },
<     "audiocpu", "qsound",
>     "audiocpu", "qsound", "qsoundw",'
if [ "$d" = "$want" ]; then ok "2c mame2mra.toml delta is exactly the declared D0 set"
else bad "2c mame2mra.toml delta drifted:"; printf '%s\n' "$d" | sed 's/^/       /'; fi
[ -f "$B/msg" ] && ok "2d msg present" || bad "2d msg missing"

NAMES="$(sed -n 's/^PATCH_NAMES="\(.*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
[ -n "$NAMES" ] || bad "3 cannot read PATCH_NAMES from tools/setup_jtcores.sh"
i=1
for name in $NAMES; do
    sha="$(git -C "$SRC" rev-list --reverse "$UP..$PIN" | sed -n "${i}p")"
    if [ -z "$sha" ]; then bad "3 no fork commit $i for $name"; break; fi
    if git -C "$SRC" format-patch --stdout -1 "$sha" | cmp -s - "$REPO/emu/jtcores-patches/$name"
    then ok "3.$i $name == format-patch -1 $(echo "$sha" | cut -c1-8)"
    else bad "3.$i $name drifted from commit $(echo "$sha" | cut -c1-8)"; fi
    i=$((i + 1))
done
extra="$(git -C "$SRC" rev-list --reverse "$UP..$PIN" | sed -n "${i}p")"
[ -z "$extra" ] && ok "3z series length == commit count ($((i - 1)))" \
                || bad "3z fork commit $(echo "$extra" | cut -c1-8) is NOT mirrored — add a PATCH_NAMES entry"
onfile="$(ls "$REPO/emu/jtcores-patches" | tr '\n' ' ')"
want="$(printf '%s ' $NAMES)"
[ "$onfile" = "$want" ] && ok "3y patches dir holds exactly the declared series" \
                        || bad "3y patches dir holds [$onfile], declared [$want]"

# 4 must-fire control (pure-text twin of check 2a).
T="$(mktemp)"; { cat "$A/game.yaml"; echo "      - jtcps2_extra.v"; } > "$T"
cmp -s "$A/game.yaml" "$T" && bad "4 control: perturbed yaml compared equal" || ok "4 control fired"
rm -f "$T"
[ $fail = 0 ] && echo "PASS test_jtcores_twin" || { echo "FAIL test_jtcores_twin"; exit 1; }
