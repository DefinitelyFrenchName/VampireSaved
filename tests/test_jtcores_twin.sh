#!/bin/sh
# test_jtcores_twin.sh — the MiSTer core scaffold is a TWIN of the reference
# core, and the three copies of its delta agree (14z-106).
#
# WHAT IT LOCKS (ROM-free, no emulator, seconds; ci_portable):
#  1. emu/jtcores sits at the pin tools/setup_jtcores.sh names.
#  2. cores/cps2w is cores/cps2 modulo EXACTLY the delta the core is DECLARED
#     to carry — the checks below hold the list verbatim: CORENAME in
#     macros.def; in mame2mra.toml the `vsav` mustbe, the cps2w.cpp sourcefile
#     opt-in, the `qsoundw` trim region (slice D0) and the profile header byte
#     (slice D1); and in game.yaml the RTL override set, which slice D2 grew
#     from four files to six and slice D3 to eleven and slice D4 to TWELVE, and which is frozen in
#     tests/expect/cps2w_game_yaml_delta.txt rather than inline (the list
#     inlines cores/cps1/cfg/common.yaml minus the files it overrides, so
#     it runs to 75 lines and a shell string stopped being readable).
#     **MOVED DELIBERATELY 14z-107 (6), and this is the governance milestone:
#     check 2a used to read "game.yaml identical (no RTL override)".** cps2w
#     now carries RTL, so the declaration grows from "nothing" to an ENUMERATED
#     LIST — and an undeclared file appearing in cores/cps2w/hdl still fails,
#     which is the property that mattered then and matters now.
#  2f. AND NOTHING UNDECLARED LANDED ANYWHERE IN THE FORK. `git diff
#     --name-status` over the WHOLE tree must equal the list held below. That
#     is what catches an addition OUTSIDE cores/cps2w — slice D2 makes one on
#     purpose (jtframe gains hdl/sdram/jtframe_ram1_7slots.v, a mechanical
#     member of the ram1_Nslots family that upstream stops at 5) and a gate
#     that only watched cores/ would never have seen it.
#  2e. THE REFERENCE CORES ARE BYTE-UNTOUCHED. `git diff` of the whole fork
#     against upstream v1.7.3 must touch nothing under cores/cps1, cores/cps2
#     or cores/cps15. This is the strongest form of "profile-gated by
#     construction" available in a text gate: it does not matter what our
#     copies say if the originals cannot have moved.
#  3. emu/jtcores-patches/ reproduces the fork's commits as a PATCH SERIES,
#     byte-for-byte: file i == `git format-patch -1 <i-th commit after
#     v1.7.3>`, the directory holds EXACTLY the declared names, and the
#     series length equals the commit count. The in-tree reviewable mirror
#     cannot drift from the fork, and a new fork commit cannot land
#     unmirrored (14z-107: it was a single hardcoded file until the sim
#     work-RAM hook became commit 2).
#  4. Must-fire control: a perturbed copy of game.yaml FAILS section 2.
# Usage: tests/test_jtcores_twin.sh
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable) pin, cps2w-vs-cps2 twin, the patch SERIES == `format-
#   patch` per commit
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/emu/jtcores"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }
[ -f "$SRC/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
PIN="$(sed -n 's/^PINNED="\([0-9a-f]*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
UP="$(sed -n 's/^UPSTREAM_TAG_SHA="\([0-9a-f]*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
HEAD="$(git -C "$SRC" rev-parse HEAD)"
[ "$HEAD" = "$PIN" ] && ok "1 pin $PIN" || bad "1 emu/jtcores at $HEAD, pin $PIN"

A="$SRC/cores/cps2/cfg"; B="$SRC/cores/cps2w/cfg"
# 2a THE RTL OVERRIDE SET, ENUMERATED. A file lives in cores/cps2w/hdl only
# when it MUST differ (docs/platform/mister.md "How the CPS-2 core is put
# together"), and the two halves below have to agree: what is on disk, and
# what game.yaml pulls. An undeclared file in either place fails here.
hdl="$(ls "$SRC/cores/cps2w/hdl" 2>/dev/null | tr '\n' ' ')"
want='jtcps15_sound.v jtcps1_obj_draw.v jtcps1_prom_we.v jtcps1_sdram.v jtcps1_video.v jtcps2_decrypt.v jtcps2_game.v jtcps2_main.v jtcps2_obj.v jtcps2_obj_scan.v jtcps2w_obj_bank.v jtcps2w_profile.v jtcps2w_qsnd_bank.v pal_lut.hex '
[ "$hdl" = "$want" ] && ok "2a cores/cps2w/hdl holds exactly the declared override set" \
                     || bad "2a cores/cps2w/hdl holds [$hdl], declared [$want]"
EXP="$REPO/tests/expect/cps2w_game_yaml_delta.txt"
diff "$A/game.yaml" "$B/game.yaml" | grep '^[<>]' | grep -v '^> *#' | grep -v '^> *$' > "$W/yaml.txt"
if cmp -s "$W/yaml.txt" "$EXP"; then
    ok "2a2 game.yaml delta is exactly the declared D1+D2 override list ($(wc -l < "$EXP" | tr -d ' ') lines)"
else
    bad "2a2 game.yaml delta drifted:"; diff "$EXP" "$W/yaml.txt" | head -20 | sed 's/^/       /'
fi
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
> main_setnames=[ "vsavjw" ]
>     { setname="vsavjw",   offset=41, data="fe" },
>     { name="qsoundw", skip=true },
>     { name="qsoundw", width=16, setname="vsavjw", parts=[
>         { name="vsw.21m", crc="<build>", map="12", length=0x0F0000, offset=0 },
>     ] },
<     "audiocpu", "qsound",
>     "audiocpu", "qsound", "qsoundw",'
if [ "$d" = "$want" ]; then ok "2c mame2mra.toml delta is exactly the declared D0+D1 set"
else bad "2c mame2mra.toml delta drifted:"; printf '%s\n' "$d" | sed 's/^/       /'; fi
[ -f "$B/msg" ] && ok "2d msg present" || bad "2d msg missing"
# 2f nothing undeclared landed ANYWHERE in the fork — including outside cores/
git -C "$SRC" diff --name-status "$UP..$PIN" | sort | tr '\t' ' ' > "$W/tree_got.txt"
cat > "$W/tree_want.txt" <<'TREE'
A cores/cps2w/README.md
A cores/cps2w/cfg/game.yaml
A cores/cps2w/cfg/macros.def
A cores/cps2w/cfg/mame2mra.toml
A cores/cps2w/cfg/msg
A cores/cps2w/hdl/jtcps15_sound.v
A cores/cps2w/hdl/jtcps1_obj_draw.v
A cores/cps2w/hdl/jtcps1_prom_we.v
A cores/cps2w/hdl/jtcps1_sdram.v
A cores/cps2w/hdl/jtcps1_video.v
A cores/cps2w/hdl/jtcps2_decrypt.v
A cores/cps2w/hdl/jtcps2_game.v
A cores/cps2w/hdl/jtcps2_main.v
A cores/cps2w/hdl/jtcps2_obj.v
A cores/cps2w/hdl/jtcps2_obj_scan.v
A cores/cps2w/hdl/jtcps2w_obj_bank.v
A cores/cps2w/hdl/jtcps2w_profile.v
A cores/cps2w/hdl/jtcps2w_qsnd_bank.v
A cores/cps2w/hdl/pal_lut.hex
A cores/cps2w/ver/game/Makefile
A cores/cps2w/ver/game/rom2hex.cc
A modules/jtframe/hdl/sdram/jtframe_ram1_7slots.v
M doc/mame.xml
M modules/jtframe/hdl/sdram/jtframe_sdram_stats_sim.v
M modules/jtframe/hdl/ver/test.cpp
TREE
if cmp -s "$W/tree_want.txt" "$W/tree_got.txt"; then
    ok "2f the fork's whole-tree delta is exactly the declared 25 paths (1 ADDED jtframe file, 3 modified, the rest cores/cps2w)"
else
    bad "2f the fork touched something nobody declared:"
    diff "$W/tree_want.txt" "$W/tree_got.txt" | head -12 | sed 's/^/       /'
fi
# 2e the reference cores cannot have moved, whatever our copies say
moved="$(git -C "$SRC" diff --name-only "$UP..$PIN" -- cores/cps1 cores/cps2 cores/cps15 | tr '\n' ' ')"
[ -z "$moved" ] && ok "2e cores/cps1, cores/cps2 and cores/cps15 are BYTE-UNTOUCHED vs v1.7.3" \
                || bad "2e the fork MODIFIED a reference core: $moved"

NAMES="$(sed -n 's/^PATCH_NAMES="\(.*\)".*/\1/p' "$REPO/tools/setup_jtcores.sh")"
[ -n "$NAMES" ] || bad "3 cannot read PATCH_NAMES from tools/setup_jtcores.sh"
i=1
for name in $NAMES; do
    sha="$(git -C "$SRC" rev-list --reverse "$UP..$PIN" | sed -n "${i}p")"
    if [ -z "$sha" ]; then bad "3 no fork commit $i for $name"; break; fi
    if git -C "$SRC" format-patch --stdout --no-signature -1 "$sha" | cmp -s - "$REPO/emu/jtcores-patches/$name"
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

# 4 MUST-FIRE CONTROLS, both text twins of what 2a checks — an UNDECLARED RTL
# file must fail whether it appears on disk or only in the pull list. This is
# the property check 2a inherited from the "game.yaml identical" era and the
# one that must survive every future slice.
extra="$(printf '%s\n' "$hdl" | sed 's/$/jtcps2w_extra.v /')"
[ "$extra" = "$want" ] \
    && bad "4a control: an extra hdl file compared equal to the declared set" \
    || ok "4a control fired (an undeclared cores/cps2w/hdl file fails 2a)"
T="$(mktemp)"; { cat "$B/game.yaml"; echo "      - jtcps2w_extra.v"; } > "$T"
diff "$A/game.yaml" "$T" | grep '^[<>]' | grep -v '^> *#' | grep -v '^> *$' > "$W/yaml_ctl.txt"
cmp -s "$W/yaml_ctl.txt" "$EXP" && bad "4b control: a perturbed game.yaml matched the frozen delta" \
                                || ok "4b control fired (an undeclared pull fails 2a2)"
rm -f "$T"
[ $fail = 0 ] && echo "PASS test_jtcores_twin" || { echo "FAIL test_jtcores_twin"; exit 1; }
