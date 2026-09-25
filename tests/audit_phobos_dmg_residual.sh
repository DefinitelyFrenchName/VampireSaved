#!/bin/sh
# audit_phobos_dmg_residual.sh — PHOBOS TAKES ONE MORE HP THAN NATIVE FROM DEMITRI'S 5HP, WITH HIS DEFENSE ROW ALREADY VS2'S, frozen AS MEASURED (14z-170): native vs2 11, our merged build 12, the same at three RNG pins — the residual the M19 defense-row fix left (merged-m18 read 13); a LEGACY victim reads the same +1 (14z-181), so it is vsavj's own damage pipeline — #161 ruled not-ours 2026-09-25, this gate kept as the record.
#
# WHAT: Phobos takes one more HP than native from Demitri's 5HP with his defense row already
#   vs2's — native 11, ours 12, at three RNG pins — frozen as measured as the record of
#   #161 (ruled not-ours 2026-09-25); the premise 'his rows are already native' is checked from the build's
#   own image.
# HOW: twelve MAME runs, two at a time: the #136 parts huitzil_5 and huitzil_6 on native and
#   ours (the merged wheel's Phobos path, the part's pokes, the level pin) at RNG pins
#   0000/1234/5a5a, P1's HP traced every frame from 2300 and every loss frozen; the build's
#   curve row 0x10 and threshold words compared with vs2's; the control replaces our step by
#   native's.
# EXPECTS: one P1 HP step per part on the same frame on both legs, not moving with the pin,
#   the rows equal to vs2's, the frozen 11/12; AND, since 14z-181, the LEGACY pair — Demitri's
#   5HP on Victor, real picks on pristine vsavj and pristine vsav2, Victor's row byte-identical
#   between the games — frozen at vsavj 12 / vsav2 11, two hits per leg on the same frames: the
#   same +1 with no port in the loop, so the residual is the two ENGINES' damage pipelines, not
#   ours (#161's answer; the maintainer ruled it not-ours 2026-09-25); both planted steps fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/phobos_dmg_residual.tsv tests/replays/judge/04_demitri_5hp_victor.rpl
#   tests/expected/registry.tsv tests/lib/controls.sh tests/lua/field_trace.lua
#   tests/replays/ tools/build_fingerprint.py tools/name_moves.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: legacy-same — a copy of the legacy pair's rows with vsav2's step in place of vsavj's (what two engines that agreed would read) must FAIL the frozen compare, so the +1 the LEGACY victim takes on vsavj is read from the rows, not assumed (in-gate: the perturbed copy must differ from the frozen rows; mode: the rows are rewritten and the compare FAILs) — 14z-181, #161
# MUST-FIRE: perturbed-copy: residual-gone — a copy of our leg's HP trace with native's step in place of ours (what a fix of the residual looks like) must FAIL the frozen compare, so the gate reads the step it claims to read (in-gate: the planted copy must differ from the frozen rows; mode: the planted copy IS our leg and the gate FAILs)
#
# WHY. The maintainer ruled the #136 defense-row fix (vs2's defense curve and threshold rows for
# Phobos and Donovan, 2026-09-18) and, when the M19 freeze measured it, "Freeze, ticket it
# (Recommended)" (2026-09-19): M19 is frozen as built, the attribution gate carried the two rows as
# the open class PHOBOS-DMG-OPEN (tools/move_parity_attribution.py; DMG-VSAVJ since the 2026-09-25
# ruling), and this gate was the ticket's reproducer; 14z-181's legacy pair answered it, and #161
# closed as not-ours (DECISIONS_HISTORY.md "Ruled 2026-09-25 (14z-182) — #161"). Measured in scratch
# (build/rc170/freeze/dmg/) and captured here ([VSP-18]).
#
# THE RIG: the #136 naming parts huitzil_5 and huitzil_6 (Phobos P1 against Demitri P2; Demitri's
# 5HP lands once, at f5966 and f7725), native vsav2 as authored, ours through the merged wheel's real
# cursor path for Phobos (the parity gate's OURS_PATH "D D D"), the part's pokes plus the speed-level
# pin; the RNG word RAM:$FF80D4 pinned from 2363 at 0000, 1234 and 5a5a in turn. P1's HP (+0x50,
# RAM:$FF8450) is traced every frame from 2300; each leg's ids are read at 2300 (P1 +0x382 =
# 0x10 Phobos, P2 +0x382 = 0x01 Demitri).
#
# FROZEN: tests/expected/phobos_dmg_residual.tsv — `<part> <pin> <leg> <frame> <hp before> <hp after>`
# for every P1 HP LOSS, plus one `ours build <registry row> <whole-set key>` row. FREEZE=1 rewrites it.
# THE STRUCTURAL CHECKS, independent of the frozen rows: the build's defense curve row 0x10 and
# rally threshold word (ids 0x10-0x11) equal vs2's own (the premise of "the rows are already native" —
# read from the build's data image against vs2's: PRG:0x0B8940 + 0x10*32 against PRG:0x0D2ABE + 0x10*32,
# PRG:0x0BCC80 + 0x10 against PRG:0x0D6E1E + 0x10); every leg is the tenant and
# Demitri by its own trace; each part has exactly ONE P1 HP step, on the same frame on both legs; and
# the step does not move with the RNG pin on either leg.
#
# NOT COVERED: WHY the extra point (the ticket's question — the chain after the defense row: combo
# tables, low-HP rally, the final 2D map); other attackers and moves; Donovan; FBNeo and the MiSTer
# core.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_phobos_dmg_residual.sh
#   emulator tier, MAME; twelve runs of up to 9240 frames, two at a time (~4 min quiet)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/phobos_dmg_residual.tsv"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no data image at $BUILD/verify_data.bin"; exit 0; }
[ -f "$REPO/build/out/vsav2_data.bin" ] || { echo "SKIP: no vs2 data image (build/out/vsav2_data.bin)"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
PARTS="huitzil_5 huitzil_6"; PINS="0000 1234 5a5a"

echo "== 1. the premise: the build's defense rows for 0x10 are vs2's"
if python3 - "$BUILD/verify_data.bin" "$REPO/build/out/vsav2_data.bin" <<'PY'
import sys
d = open(sys.argv[1], "rb").read(); v = open(sys.argv[2], "rb").read()
curve = d[0x0B8940 + 0x200:0x0B8940 + 0x220]; thr = d[0x0BCC80 + 0x10:0x0BCC80 + 0x12]
sys.exit(0 if len(curve) == 0x20 and curve == v[0x0D2ABE + 0x200:0x0D2ABE + 0x220]
         and len(thr) == 2 and thr == v[0x0D6E1E + 0x10:0x0D6E1E + 0x12] else 1)
PY
then ok "Phobos's defense curve row (0x10) and rally threshold word (ids 0x10-0x11) equal vs2's own"
else bad "Phobos's defense curve row or threshold word is not vs2's — not an M19-shaped build, the residual's premise does not hold"; fi

leg() {  # leg <part> <pin> <native|ours>
    _p="$1"; _v="$2"; _l="$3"; _d="$W/$_p.$_v.$_l"; mkdir -p "$_d"
    _j="$REPO/tests/replays/naming/$_p.json"; _r="$REPO/tests/replays/naming/$_p.rpl"
    _last="$(awk -F'[- ]' '/^[0-9]/{print $1}' "$_r" | sort -n | tail -1)"; _fr=$((_last + 60))
    if [ "$_l" = native ]; then _set=vsav2; _rp="$ROMDIR"; cp "$_r" "$_d/r.rpl"
    else _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"
        awk -v path="D D D" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
            /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$_r" > "$_d/r.rpl"
    fi
    _pk="$(python3 -c "import json;print(';'.join(json.load(open('$_j'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$_fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:$_v' for f in range(2363,$_fr)))")"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$_rp" REPLAY="$_d/r.rpl" POKES="$_pk" \
        FIELDS="ff8450:w:p1hp,ff8782:b:id,ff8b82:b:p2id" FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO=$_fr FRAMES=$_fr \
        "$REPO/tools/run_mame.sh" $_set -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
# THE LEGACY PAIR (14z-181, #161): Demitri's 5HP on VICTOR on pristine vsavj and pristine vsav2 — real picks on
# both wheels, Victor's defense row byte-identical between the games — so the same +1 here is the two ENGINES'
lleg() {  # lleg <pin> <vsavj|vsav2>
    _v="$1"; _g="$2"; _d="$W/legacy.$_v.$_g"; mkdir -p "$_d"; _fr=3600
    _pk="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$_fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:$_v' for f in range(2363,$_fr)))")"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/judge/04_demitri_5hp_victor.rpl" POKES="$_pk" \
        FIELDS="ff8850:w:p2hp,ff8782:b:id,ff8b82:b:p2id" FIELD_OUT="$_d/f.ft" FIELD_FROM=2300 FIELD_TO=$_fr FRAMES=$_fr \
        "$REPO/tools/run_mame.sh" $_g -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
echo "== 2. the legs ($PARTS x pins $PINS x native/ours $(basename "$BUILD"); the legacy pair x pins x vsavj/vsav2)"
for p in $PARTS; do for v in $PINS; do
    leg "$p" "$v" native & leg "$p" "$v" ours & wait
done; done
for v in $PINS; do lleg "$v" vsavj & lleg "$v" vsav2 & wait; done
for v in $PINS; do for g in vsavj vsav2; do
    f="$W/legacy.$v.$g/f.ft"
    [ -s "$f" ] || { bad "legacy pin $v $g: the leg produced no trace — VOID"; continue; }
    ids="$(awk '$1=="F" && $2==2300 {for(i=3;i<=NF;i++){split($i,kv,"="); if(kv[1]=="id") a=kv[2]; if(kv[1]=="p2id") b=kv[2]}; printf "%02x %02x", a, b}' "$f")"
    [ "$ids" = "01 03" ] || bad "legacy pin $v $g: ids at 2300 read '$ids', not Demitri 01 against Victor 03 — the real picks did not land"
done; done
n=0
for p in $PARTS; do for v in $PINS; do for l in native ours; do
    f="$W/$p.$v.$l/f.ft"
    [ -s "$f" ] || { bad "$p pin $v $l: the leg produced no trace — VOID"; continue; }
    n=$((n + 1))
    ids="$(awk '$1=="F" && $2==2300 {for(i=3;i<=NF;i++){split($i,kv,"="); if(kv[1]=="id") a=kv[2]; if(kv[1]=="p2id") b=kv[2]}; printf "%02x %02x", a, b}' "$f")"
    [ "$ids" = "10 01" ] || bad "$p pin $v $l: ids at 2300 read '$ids', not Phobos 10 against Demitri 01 — the pick did not land"
done; done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_phobos_dmg_residual"; exit 1; }
ok "$n legs ran; every leg is Phobos (0x10) against Demitri (0x01) by its own trace at 2300"

steps() {  # steps <trace> [field] -> "<frame> <before> <after>" per HP LOSS of the field (default p1hp; the match-start fill 0 -> 288 is a gain, not a hit)
    awk -v k="${2:-p1hp}=" '$1=="F"{for(i=3;i<=NF;i++) if(index($i,k)==1){h=substr($i,length(k)+1)+0; if(prev!="" && h<prev) print $2, prev, h; prev=h}}' "$1"
}
: > "$W/got.tsv"
for p in $PARTS; do for v in $PINS; do for l in native ours; do
    steps "$W/$p.$v.$l/f.ft" | while read -r fr a b; do printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$p" "$v" "$l" "$fr" "$a" "$b"; done >> "$W/got.tsv"
done; done; done
for v in $PINS; do for g in vsavj vsav2; do
    steps "$W/legacy.$v.$g/f.ft" p2hp | while read -r fr a b; do printf 'legacy\t%s\t%s\t%s\t%s\t%s\n' "$v" "$g" "$fr" "$a" "$b"; done >> "$W/got.tsv"
done; done
# THE PERTURBATIONS: ours' step replaced by native's, row by row (what a fix of the residual looks like); and the
# legacy pair's vsavj step replaced by vsav2's (what "the engines agree" would look like — legacy-same)
python3 - "$W/got.tsv" "$W/pl.tsv" "$W/pl2.tsv" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1])]
nat = {(r[0], r[1], r[3]): r for r in rows if r[2] in ("native", "vsav2")}
out, out2 = [], []
for r in rows:
    r2 = r
    if r[2] == "ours" and (r[0], r[1], r[3]) in nat: r = r[:4] + nat[(r[0], r[1], r[3])][4:]
    if r2[2] == "vsavj" and (r2[0], r2[1], r2[3]) in nat: r2 = r2[:4] + nat[(r2[0], r2[1], r2[3])][4:]
    out.append("\t".join(r)); out2.append("\t".join(r2))
open(sys.argv[2], "w").write("\n".join(out) + ("\n" if out else ""))
open(sys.argv[3], "w").write("\n".join(out2) + ("\n" if out2 else ""))
PY
[ "$MODE" = residual-gone ] && cp "$W/pl.tsv" "$W/got.tsv"
[ "$MODE" = legacy-same ] && cp "$W/pl2.tsv" "$W/got.tsv"
_bid="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --registry "$REPO/tests/expected/registry.tsv" 2>/dev/null | tail -1)"
_bfp="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --set-key 2>/dev/null | tail -1 | cut -c1-8)"
_brow="$(printf 'ours\tbuild\t%s\t%s' "${_bid:-unregistered}" "${_bfp:-?}")"
echo "$_brow" >> "$W/got.tsv"; echo "$_brow" >> "$W/pl.tsv"; echo "$_brow" >> "$W/pl2.tsv"
echo "== 3. the steps"
sed 's/^/     /' "$W/got.tsv"
for p in $PARTS; do
    for l in native ours; do
        c="$(awk -F'\t' -v p="$p" -v l="$l" '$1==p && $3==l' "$W/got.tsv" | wc -l | tr -d ' ')"
        [ "$c" = 3 ] || bad "$p $l: $c HP steps over the three pins, not exactly one per pin — the rig does not land the one 5HP"
        u="$(awk -F'\t' -v p="$p" -v l="$l" '$1==p && $3==l {print $4, $5, $6}' "$W/got.tsv" | sort -u | wc -l | tr -d ' ')"
        [ "$u" = 1 ] || bad "$p $l: the step moves with the RNG pin ($u distinct) — the residual is not deterministic"
    done
    fn="$(awk -F'\t' -v p="$p" '$1==p && $3=="native" {print $4; exit}' "$W/got.tsv")"
    fo="$(awk -F'\t' -v p="$p" '$1==p && $3=="ours" {print $4; exit}' "$W/got.tsv")"
    [ -n "$fn" ] && [ "$fn" = "$fo" ] || bad "$p: the hit lands on f$fn native and f$fo ours — not the same event"
done
for g in vsavj vsav2; do
    c="$(awk -F'\t' -v g="$g" '$1=="legacy" && $3==g' "$W/got.tsv" | wc -l | tr -d ' ')"
    [ "$c" = 6 ] || bad "legacy $g: $c HP steps over the three pins, not exactly two per pin (the two 5HPs) — the rig does not land them"
    u="$(awk -F'\t' -v g="$g" '$1=="legacy" && $3==g {print $4, $5, $6}' "$W/got.tsv" | sort -u | wc -l | tr -d ' ')"
    [ "$u" = 2 ] || bad "legacy $g: the steps move with the RNG pin ($u distinct for two hits)"
done
fj="$(awk -F'\t' '$1=="legacy" && $3=="vsavj" {print $4}' "$W/got.tsv" | sort -u | tr '\n' ' ')"; f2="$(awk -F'\t' '$1=="legacy" && $3=="vsav2" {print $4}' "$W/got.tsv" | sort -u | tr '\n' ' ')"
[ -n "$fj" ] && [ "$fj" = "$f2" ] || bad "legacy: the hits land on f$fj vsavj and f$f2 vsav2 — not the same events"
[ "$fail" = 0 ] && ok "one P1 HP step per part and pin, on the same frame on both legs, unmoved by the RNG pin; the legacy pair two steps per game and pin on the same frames ($fj)"
echo "== 4. the frozen rows"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    [ "$fail" = 0 ] || { echo "FAIL: not freezing a table whose structural checks failed"; exit 1; }
    { echo "# tests/expected/phobos_dmg_residual.tsv — every P1 (Phobos) HP step on the #136 naming parts huitzil_5/huitzil_6 (Demitri's"
      echo "# 5HP), native vsav2 against our merged build, at RNG pins 0000/1234/5a5a (tests/audit_phobos_dmg_residual.sh). Evidence"
      echo "# class: in-emulator, MAME. Frozen AS MEASURED with FREEZE=1 on $(basename "$BUILD") — #161, ruled not-ours 2026-09-25: native 11,"
      echo "# ours one more with the defense row already vs2's. Columns: <part> <pin> <leg> <frame> <hp before> <hp after>; one build row."
      echo "# Since 14z-181 the \`legacy\` rows: Demitri's 5HP on VICTOR (P2, its HP) on pristine vsavj and pristine vsav2 at the same pins —"
      echo "# vsavj 12 / vsav2 11 with Victor's row byte-identical between the games: the +1 is the two engines' (GitHub #161)."
      echo "#--"
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/got.tsv"; then ok "every row as frozen"
else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/got.tsv" | sed 's/^/        /'; fi
if [ -z "$MODE" ]; then
    if cmp -s "$W/want.tsv" "$W/pl.tsv"; then vs_ctl_dead residual-gone "our trace with native's step still matches the frozen rows" || fail=1
    else vs_ctl_fired residual-gone "our trace with native's step differs from the frozen rows ($(diff "$W/want.tsv" "$W/pl.tsv" | grep -c '^>') rows)"; fi
    if cmp -s "$W/want.tsv" "$W/pl2.tsv"; then vs_ctl_dead legacy-same "the legacy pair with vsav2's step in vsavj's place still matches the frozen rows" || fail=1
    else vs_ctl_fired legacy-same "the legacy pair with vsav2's step in vsavj's place differs from the frozen rows ($(diff "$W/want.tsv" "$W/pl2.tsv" | grep -c '^>') rows) — the +1 between the two ENGINES is what the rows hold"; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_phobos_dmg_residual"; else echo "FAIL: audit_phobos_dmg_residual"; exit 1; fi
