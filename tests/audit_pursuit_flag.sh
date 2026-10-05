#!/bin/sh
# audit_pursuit_flag.sh — THE CLASS-0x51 PURSUIT FLAG: after Cosmo Disruption and Ifrit Sword (ES), the tenant's pursuit starts and connects as on native vs2 (GitHub #195, 14z-188).
#
# WHAT: vs2's knockdown tail sets the victim's +0x117 (the pursuit flag the attacker-side check reads) for reaction class
#   0x51 alone; our tenants' 0x51 records are remapped to 0x44, which never sets it, until #195's two hooks (the
#   hit-time mark at PRG:0x01868C and the tail at PRG:0x024D92 — build/manifest/staged/195_pursuit_mark.patch). On a
#   build that CARRIES the hooks, every event of the two rigs equals native: P2's +0x117 at the press, the pursuit
#   starting (P1 seq 0xe) and connecting (P2's HP falling) on the same frames. On a build WITHOUT them (every freeze up to
#   merged-m21), the known gap: the flag 0 and the pursuit never starting where native's does — so the gate holds today
#   and turns over to equality, by itself, on the freeze that applies the patch.
# HOW: the rigs are tools/pursuit_rigs.py's (tools/name_moves.py's machinery, kept OUTSIDE the naming corpus in
#   tests/replays/pursuit195/): cosmo (Pyron P1; Cosmo [41236 PP] then U+LP at +160..+200) and ifrit (Donovan P1;
#   Ifrit Sword (ES) [623 PP, near] then U+LP at +72..+92), each with the throw-then-pursuit CONTROL; each on MAME on
#   native vs2 and on the merged WIDE build as the parity gates run them (real cursor picks, level 6 from 2000, the RNG
#   from the match anchor); whether the build carries the hooks is read from its own opcode view at the two sites
#   (verify_op.bin: a jsr at both, or the original bytes at both — anything else fails); tools/pursuit_rigs.py compare
#   --expect same|gap reads every event. Then the MARK's discriminator (hooked builds): a non-debug write tap
#   (tests/lua/read_tap.lua) on P2's +0x293 over the naming rig pyron_4 (tests/replays/naming/), whose Pyron hits
#   four times with projectile record 4 (class 0x44 natively) and then four times with record 21 (Cosmo, vs2 0x51);
#   and the same rig with Pyron on P2 (tools/pursuit_rigs.py p2rig, his real cursor path from the build's own decoded
#   wheel), tapping P1's +0x293 — the hook reads the ATTACKER's id from A0, so P2's hits must mark P1 alike. A third
#   rig, lsword (Donovan's Lightning Sword (ES) then U+LP at +40..+180), holds GitHub #200's answer: native marks the
#   victim at the hit and clears the flag at +150 while Donovan is still in the move, so no pursuit starts on either
#   game — `--expect inert` on every build (the hooks do not touch class 0x4E's path).
# EXPECTS: the committed rigs equal a regeneration; native knocks the victim down on every event (+0x117 = 1 at every
#   press) and starts the pursuit on at least one target event (VOID otherwise, never a pass); hooked build: every row
#   equal to native; unhooked build: the gap on every target event, the control equal; the mark's byte writes in play
#   are, in order, 0 0 0 0 1 1 1 1 on a hooked build (record 4 clears, record 21 marks) and none on an unhooked one,
#   with Pyron on either side; lsword inert (the flag set natively at some press, no pursuit on native, ours equal
#   to native on every other field);
#   every control fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lua/field_trace.lua tests/replays/pursuit195/
#   tests/lua/read_tap.lua tests/replays/naming/pyron_4.rpl tests/replays/naming/pyron_4.json tools/select_paths.py
#   tools/select_wheel.py
#   tools/build_fingerprint.py tools/name_moves.py tools/pursuit_rigs.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: expect-flipped — the comparison run with the OTHER expectation (same on an unhooked build, gap on a hooked one) must fail on every rig, so the verdict is something the comparison can refuse (in-gate: both rigs; mode: the expectation flipped and the gate FAILs)
# MUST-FIRE: perturbed-copy: flag-zeroed — the comparison of OUR trace with P2's +0x117 read as 0 at every press must fail --expect same on every rig, so the flag at the press is something the verdict reads — discriminating on a HOOKED build only: on an unhooked one ours' flag is already 0 and the pursuit already differs (in-gate: both rigs, against --expect same; mode: ours zeroed against --expect same and the gate FAILs)
# MUST-FIRE: perturbed-copy: inert-as-same — the lsword rig compared with --expect same must fail on the flag, so "inert" is a comparison that sees the flag differ, not a blind one (in-gate: lsword; mode: lsword judged --expect same and the gate FAILs)
# MUST-FIRE: perturbed-copy: record4-marked — the mark check run on a copy of the tap log with every clearing write (record 4's) turned into a mark and one stray mark added must fail, so "record 4 stays unmarked" (hooked) and "no mark is written" (unhooked) are things the check can refuse (in-gate: on the real tap log; mode: the copy checked and the gate FAILs)
#
# THE PINS ARE RANGES (`F1-F2:addr:hex`, #201): a per-frame list over these rigs' lengths passes 128 KiB, and Linux
#   refuses one environment string over that (the lsword and pyron_4 legs went VOID on ERIS, 14z-188).
# NOT COVERED: the pins (level 6 from 2000, RNG 0000 from 2363 — the ruled equalised input); the pursuit itself with the
#   tenant on P2 (the P2 side is held at the mark, not at +0x117 and the pursuit); the three rigs' moves only (the
#   LP/MP/HP Lightning Swords, other distances and unpinned play are not measured for #200); FBNeo; the solo tracks.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] [KEEP=<dir>] tests/audit_pursuit_flag.sh
#   emulator tier, MAME; ~3 min (8 legs in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
BUILD="${BUILD:-build/m3b_merged31}"
[ -d "$BUILD" ] && BUILD="$(cd "$BUILD" && pwd)"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no $BUILD/rompath/vsavjw.zip"; exit 1; }
[ -f "$BUILD/verify_op.bin" ] || { echo "FAIL: no $BUILD/verify_op.bin (the build's opcode view: the hooks are read from it)"; exit 1; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
RIGS=tests/replays/pursuit195

echo "== 0. the rigs equal a regeneration"
python3 tools/pursuit_rigs.py gen "$W/regen" > /dev/null
for r in cosmo ifrit lsword; do
    for x in rpl json; do
        cmp -s "$RIGS/$r.$x" "$W/regen/$r.$x" && ok "$r.$x == regeneration" || bad "$r.$x differs from tools/pursuit_rigs.py gen"
    done
done

echo "== 1. does the build carry #195's hooks? (its own opcode view)"
HOOK="$(python3 - "$BUILD/verify_op.bin" <<'PY'
import sys
b = open(sys.argv[1], "rb").read()
hit, tail = b[0x1868C:0x18692], b[0x24D92:0x24D98]
orig = (hit == bytes.fromhex("136b00170054"), tail == bytes.fromhex("2d7cffff8e39"))
jsr = (hit[:2] == b"\x4e\xb9", tail[:2] == b"\x4e\xb9")
print("hooked" if all(jsr) else "unhooked" if all(orig) else f"MIXED hit={hit.hex()} tail={tail.hex()}")
PY
)"
case "$HOOK" in
    hooked)   EXPECT=same; FLIP=gap;  ok "both sites jsr-routed: hooked -> every event must equal native" ;;
    unhooked) EXPECT=gap;  FLIP=same; ok "both sites original: unhooked -> the known gap on every target event" ;;
    *)        bad "the hook sites disagree ($HOOK)"; echo "FAIL: audit_pursuit_flag"; exit 1 ;;
esac
FP="$(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw --sha-only 2>/dev/null || true)"
echo "  ours: $BUILD (vsavjw fingerprint ${FP:-?})"

echo "== 2. the legs (native vs2 and ours, both rigs)"
FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff8410:w:x,ff8414:w:y,ff8450:w:p1hp,ff8782:b:id,ff802e:b:df,ff840b:b:face,ff8116:b:lvl,ff850a:w:meter,ff8850:w:p2hp,ff881c:l:p2node,ff8b82:b:p2id,ff8810:w:p2x,ff8814:w:p2y,$(python3 -c 'import sys; sys.path.insert(0,"tools"); import pursuit_rigs as p; print(p.EXTRA_FIELDS)')"
cursor() {  # cursor <rpl> <path> — the merged wheel's real cursor path in place of the native select lines
    awk -v p="$2" '
        /^1104-1106 p2=R$/ && !done { n = split(p, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$1"
}
leg() {  # leg <rig> <native|ours>
    r=$1; side=$2; J="$RIGS/$r.json"
    fr="$(python3 -c "import json;print(json.load(open('$J'))['frames'])")"
    pk="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))");2000-$((fr - 1)):ff8116:06;2363-$((fr - 1)):ff80d4:0000"
    if [ "$side" = native ]; then s=vsav2; rp="$ROMDIR"; R="$REPO/$RIGS/$r.rpl"
    else
        s=vsavjw; rp="$BUILD/rompath;$ROMDIR"; R="$W/$r.ours.rpl"
        case $r in cosmo) CUR="D D D D";; ifrit|lsword) CUR="D D DR DR";; esac   # the merged wheel's real paths (HANDOFF [VSP-123])
        cursor "$RIGS/$r.rpl" "$CUR" > "$R"
    fi
    d="$W/$r.$side"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$R" POKES="$pk" FIELDS="$FIELDS" \
        FIELD_OUT="$W/tr_$r.$side.txt" FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" \
        "$REPO/tools/run_mame.sh" "$s" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null
}
tapleg() {  # tapleg <p1|p2> — the mark tap over pyron_4 on ours, Pyron on that side, the VICTIM's +0x292 word tapped
    J=tests/replays/naming/pyron_4.json; R="$W/pyron_4.$1.rpl"; d="$W/tap_$1"; rm -rf "$d"; mkdir -p "$d"
    fr="$(python3 -c "import json;print(json.load(open('$J'))['frames'])")"
    if [ "$1" = p1 ]; then
        cursor tests/replays/naming/pyron_4.rpl "D D D D" > "$R"; tap=ff8a92
        pk="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))");2000-$((fr - 1)):ff8116:06;2363-$((fr - 1)):ff80d4:0000"
    else
        python3 tools/select_wheel.py "$BUILD/verify_data.bin" --set vsavj --json "$W/wheel.json" > "$W/wheel.log" 2>&1
        python3 tools/select_paths.py "$W/wheel.json" --rpl-prologue 0x01 0x11 > "$W/p2_prologue.txt"
        python3 tools/pursuit_rigs.py p2rig tests/replays/naming/pyron_4.rpl "$J" "$W/p2_prologue.txt" "$R" "$W/p2.pokes"
        tap=ff8692; pk="$(cat "$W/p2.pokes")"
    fi
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" REPLAY="$R" POKES="$pk" RTAP="$tap,2" \
        WINDOW="2300,$fr" TRACE_OUT="$W/tap_mark_$1.txt" FRAMES="$fr" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true   # MAME can segfault at teardown after the log is written: the END line decides
}
for r in cosmo ifrit lsword; do for side in native ours; do leg "$r" "$side" & done; done
tapleg p1 & tapleg p2 &
wait
for t in p1 p2; do
    grep -q '^END ' "$W/tap_mark_$t.txt" 2>/dev/null && ok "pyron_4 mark tap, Pyron on $t: complete" || bad "pyron_4 mark tap, Pyron on $t: no END line (see $W/tap_$t/mame.log)"
done
for r in cosmo ifrit lsword; do for side in native ours; do
    grep -q FIELDSUMMARY "$W/tr_$r.$side.txt" 2>/dev/null && ok "$r $side: complete trace" || bad "$r $side: no complete trace (see $W/$r.$side/mame.log)"
done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_pursuit_flag (a leg did not complete — VOID)"; exit 1; }

echo "== 3. the verdict (expect=$EXPECT)"
cmpx() {  # cmpx <rig> <expect> [--zero-flag]
    python3 tools/pursuit_rigs.py compare "$RIGS/$1.json" "$W/tr_$1.native.txt" "$W/tr_$1.ours.txt" --expect "$2" ${3:-}
}
for r in cosmo ifrit; do
    e=$EXPECT; z=
    vs_ctl_is expect-flipped && e=$FLIP
    vs_ctl_is flag-zeroed && { e=same; z=--zero-flag; }
    if cmpx "$r" "$e" $z > "$W/cmp_$r.txt" 2>&1; then ok "$r: $(tail -1 "$W/cmp_$r.txt")"
    else bad "$r: $(tail -1 "$W/cmp_$r.txt")"; grep '^  FAIL' "$W/cmp_$r.txt" | head -12; fi
done
e=inert; vs_ctl_is inert-as-same && e=same
if cmpx lsword "$e" > "$W/cmp_lsword.txt" 2>&1; then ok "lsword (#200): $(tail -1 "$W/cmp_lsword.txt")"
else bad "lsword (#200): $(tail -1 "$W/cmp_lsword.txt")"; grep '^  FAIL' "$W/cmp_lsword.txt" | head -12; fi

echo "== 4. the mark: record 4 clears, record 21 marks (pyron_4, the victim's +0x293, Pyron on either side)"
marks() {  # marks <tap log> — the byte writes of +0x293 in play (after the match anchor), in order
    awk '$1 == "W" && $2 > 2400 && $10 == "000000ff" { print substr($8, length($8)) }' "$1" | tr '\n' ' ' | sed 's/ $//'
}
perturb() {  # every clearing write turned into a mark, plus one stray mark
    awk '$1 == "W" && $2 > 2400 && $10 == "000000ff" && $8 == "00000000" { $8 = "00000101" } 1
         END { print "W 99999 PC 000000 off ff8a92 data 00000101 mask 000000ff" }' "$1"
}
case $HOOK in hooked) WANT="0 0 0 0 1 1 1 1";; *) WANT="";; esac
for t in p1 p2; do
    GOT="$(marks "$W/tap_mark_$t.txt")"
    if vs_ctl_is record4-marked; then
        perturb "$W/tap_mark_$t.txt" > "$W/tap_mark_$t.ctl"
        GOT="$(marks "$W/tap_mark_$t.ctl")"
    fi
    [ "$GOT" = "$WANT" ] && ok "Pyron on $t: mark writes in play [$GOT] (expected [$WANT] on a $HOOK build)" || bad "Pyron on $t: mark writes in play [$GOT], expected [$WANT] on a $HOOK build"
done

echo "== 5. the controls"
for r in cosmo ifrit; do
    if cmpx "$r" "$FLIP" > /dev/null 2>&1; then
        vs_ctl_dead expect-flipped "$r passes with --expect $FLIP too: the comparison cannot tell the two states apart" || fail=1
    else vs_ctl_fired expect-flipped "$r fails --expect $FLIP"; fi
    if cmpx "$r" same --zero-flag > /dev/null 2>&1; then
        vs_ctl_dead flag-zeroed "$r with ours' +0x117 read as 0 still passes --expect same" || fail=1
    else vs_ctl_fired flag-zeroed "$r fails --expect same with ours' +0x117 read as 0"; fi
done

if cmpx lsword same > /dev/null 2>&1; then
    vs_ctl_dead inert-as-same "lsword passes --expect same: the comparison cannot see the flag differ" || fail=1
else vs_ctl_fired inert-as-same "lsword fails --expect same on the flag"; fi
for t in p1 p2; do
    perturb "$W/tap_mark_$t.txt" > "$W/tap_mark_$t.pert"
    if [ "$(marks "$W/tap_mark_$t.pert")" = "$WANT" ]; then
        vs_ctl_dead record4-marked "the mark check accepts the perturbed log (Pyron on $t)" || fail=1
    else vs_ctl_fired record4-marked "the perturbed log reads [$(marks "$W/tap_mark_$t.pert")] with Pyron on $t, refused"; fi
done

[ "$fail" = 0 ] && echo "PASS: audit_pursuit_flag ($HOOK build: expect=$EXPECT on both rigs)" || { echo "FAIL: audit_pursuit_flag"; exit 1; }
