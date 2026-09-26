#!/bin/sh
# audit_column_flash.sh — THE ORANGE FLASH ON THE DEITY AS DONOVAN'S KILLSHREAD LIGHTNING COLUMN ENDS, frozen AS MEASURED (14z-170, the maintainer's capture read): palette row 11 holds a FIRE ramp on our merged build where native vs2 keeps its BLUE ramp through the move's end — the colour swap the maintainer saw, recorded as the palette RAM it is, for the open cosmetic ticket.
#
# WHAT: the orange flash on the deity as Donovan's Killshread Lightning column ends, frozen
#   AS MEASURED for the open cosmetic ticket: our merged build's palette row 11 holds a fire
#   ramp where native vs2 keeps its blue ramp through the move's end, and the extra 2858
#   palette-sequence upload is ours alone.
# HOW: the naming part donovan_4 on native vs2 and on the build (the merged wheel's real
#   cursor path, the parity gate's pins) on MAME; palette RAM dumped at 2858/2860/2866 and
#   hashed per leg (a hash, never the bytes: rule 7), plus a non-debug write tap on row 11
#   attributing every writer PC; the control replaces our row 11 by native's.
# EXPECTS: the frozen hashes per leg, native's row constant over the three frames and ours
#   equal to native at 2858 (so a leg that missed the move cannot pass), every writer the
#   uploader's `movem.l` in its own opcode image. A red is the flash gone or moved; which
#   sequence id we upload, and why, is NOT covered.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/column_flash.tsv
#   tests/expected/registry.tsv tests/lib/controls.sh tests/lua/read_tap.lua
#   tests/lua/replay.lua tests/replays/ tools/build_fingerprint.py tools/name_moves.py
#   tools/run_mame.sh tools/run_replay_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: flash-gone — a copy of our leg's palette dumps with row 11 replaced by native's (what a fix of the flash looks like) must FAIL the frozen compare, so the gate reads the row it claims to read (in-gate: the planted copy must differ from the frozen rows; mode: the planted copy IS our leg and the gate FAILs)
#
# WHY. The maintainer, on the 14z-170 capture of the fixed column: "The orange flash at 2860
# is cosmetic but strange as it's the sprite of the stand-like entity above Donovan that turns
# orange instead of staying blue: looks like a wrong palette since the rest is clean, just the
# colors swapped. Only cosmetic however why it happens would answer whether it's a minor side
# effect or something that could have impacts elsewhere." Ruled "Ticket it, go on". Measured
# in scratch (build/rc170/flash/) and captured here ([VSP-18]): the OBJ lists at 2858/2860 use
# the SAME palettes on both games; the difference is the CONTENT of palette row 11
# (RAM:$90C160). WHO WRITES IT (the writer leg, a non-debug write tap on the row): inside the
# move's window ONLY the palette-SEQUENCE uploader (the `movem.l d0-d3,(a1)` pair — vsavj
# PRG:0x02AD64/0x02AD78, vs2 PRG:0x02A0BA/0x02A0CE; engine_internals.md "The palette-SEQUENCE
# uploader"), ours at 2807, 2813 and 2858, native at 2813 only — the 2858 upload is ours alone,
# and it is the fire ramp. merged-m18 shows the same swap 6 frames later (its whole move runs 6
# frames later), so the M19 fixes did not cause it. CORRECTED 14z-170: this header first said the
# engine's fade staging copy (vsavj PRG:0x01433E) rewrote the row "on the same frames on both
# games" — a -debug watch's frame column, which counts debugger stops ([CPE-5],
# docs/platform/gotchas.md "Debugger stops DESYNC replay frame counting", PAID AGAIN); the copy
# writes row 11 only at the round-start fade.
#
# THE RIG: the naming part donovan_4 (Killshread Lightning [MP] at frame 2800), native as
# authored, ours through the merged wheel's real cursor path (the parity gate's OURS_PATH),
# the part's pokes plus the speed-level and RNG pins; palette RAM $90C000-$90C3FF dumped at
# frames 2858, 2860 and 2866 on both legs.
#
# FROZEN: tests/expected/column_flash.tsv — `<leg> <frame> <row 11's SHA-1, 12 hex>` (a hash, never the
# palette bytes: rule 7), plus one
# `ours build <registry row> <whole-set key>` row naming the build. FREEZE=1 rewrites it.
# THE STRUCTURAL CHECKS, independent of the frozen bytes: native's row 11 is ONE ramp at all
# three frames (it never changes through the move's end), and ours equals native at 2858
# (before the swap) — so a leg that did not reach the move cannot pass by accident.
#
# THE WRITER ROWS: `<leg> writer <pc> <frames>` — every PC that writes row 11 from frame 2780
# (the move starts at 2800) and the frames it writes on — then `<leg> run <pc> <count>`, every
# writer over the whole run with its write count (the boot clear, the round-start fade stepper
# vsavj PRG:0x01433C / vs2 PRG:0x0129B4, the uploader); each PC's instruction must be the
# uploader's `movem.l d0-d3,(a1)` in that leg's own opcode image (vs2's pristine view for native,
# the build's verify_op.bin for ours), and each tap must be live (the boot clear logged).
#
# NOT COVERED: WHICH sequence id our build uploads at 2807 and 2858, and why (the ticket's open
# question); other palette rows; FBNeo and the MiSTer core.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged28] [FREEZE=1] tests/audit_column_flash.sh
#   emulator tier, MAME; four runs of 2870 frames (two dump legs, two write taps), all at once
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged28}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/column_flash.tsv"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FRAMES_AT="2858 2860 2866"
J="$REPO/tests/replays/naming/donovan_4.json"; R="$REPO/tests/replays/naming/donovan_4.rpl"; FR=2870
PK="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$FR)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$FR)))")"
DUMPS="$(for f in $FRAMES_AT; do printf '%s:90c000-90c400;' "$f"; done | sed 's/;$//')"
# ours: the merged wheel's real cursor path for Donovan (tests/audit_move_parity.sh's OURS_PATH)
awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R" > "$W/ours.rpl"
leg() {  # leg <name> <set> <rompath> <rpl>
    _d="$W/$1"; mkdir -p "$_d"
    ( cd "$_d" && MAME_ROMPATH="$3" POKES="$PK" DUMPS="$DUMPS" FRAMES="$FR" \
        "$REPO/tools/run_replay_mame.sh" "$2" "$4" "$_d/ram.log" "$_d/sb" > "$_d/out" 2>&1; echo $? > "$_d/rc" ) </dev/null
}
tap() {  # tap <name> <set> <rompath> <rpl> — a non-debug WRITE tap on row 11 (reads not logged)
    _d="$W/tap_$1"; mkdir -p "$_d"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$PK" RTAP="90c160,32" \
        WINDOW="99999998,99999999" TRACE_OUT="$_d/t.tap" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
echo "== 1. the two legs (native vsav2 as authored; ours $(basename "$BUILD") through the cursor path), each dumped and write-tapped"
leg native vsav2 "$ROMDIR" "$R" &
leg ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" &
tap native vsav2 "$ROMDIR" "$R" &
tap ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" &
wait
for l in native ours; do
    _t="$W/tap_$l/t.tap"
    grep -q '^END ' "$_t" 2>/dev/null || bad "$l: the write tap never reached its END line — VOID"
    awk '$1=="W" && $2 < 100 {n++} END {exit n ? 0 : 1}' "$_t" 2>/dev/null || bad "$l: the write tap logged no boot clear of the row — a dead tap"
    awk '$1=="W" && $2 >= 2780 {n++} END {exit n ? 0 : 1}' "$_t" 2>/dev/null || bad "$l: no write to row 11 from 2780 — the leg did not reach the move"
done
for l in native ours; do
    for f in $FRAMES_AT; do
        [ -s "$W/$l/dump_${f}_90c000.bin" ] || bad "$l: no palette dump at frame $f (exit $(cat "$W/$l/rc" 2>/dev/null)) — VOID"
    done
done
[ "$fail" = 0 ] || { echo "FAIL: audit_column_flash"; exit 1; }
# row 11 as a HASH, never its bytes: palette content is ROM-derived data, and the tree keeps
# hashes of such data, not the data (CLAUDE.md rule 7; the frame-data rule of 14z-126)
row11() { python3 -c "import sys,hashlib; print(hashlib.sha1(open(sys.argv[1],'rb').read()[11*32:12*32]).hexdigest()[:12])" "$1"; }
plant() {  # THE PERTURBATION: our dumps with row 11 replaced by native's, frame by frame
    for f in $FRAMES_AT; do python3 - "$W/ours/dump_${f}_90c000.bin" "$W/native/dump_${f}_90c000.bin" "$W/pl_$f.bin" <<'PY'
import sys
o = bytearray(open(sys.argv[1], "rb").read()); n = open(sys.argv[2], "rb").read()
o[11*32:12*32] = n[11*32:12*32]; open(sys.argv[3], "wb").write(o)
PY
    done
}
table() {  # table <ours dump prefix> > rows
    for f in $FRAMES_AT; do printf 'native\t%s\t%s\n' "$f" "$(row11 "$W/native/dump_${f}_90c000.bin")"; done
    for f in $FRAMES_AT; do printf 'ours\t%s\t%s\n' "$f" "$(row11 "$1_${f}.bin")"; done
}
_ours="$W/ours/dump"; for f in $FRAMES_AT; do cp "$W/ours/dump_${f}_90c000.bin" "$W/ours/dump_${f}.bin"; done
plant
[ "$MODE" = flash-gone ] && _ours="$W/pl"
table "$_ours" > "$W/got.tsv"
_bid="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --registry "$REPO/tests/expected/registry.tsv" 2>/dev/null | tail -1)"
_bfp="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --set-key 2>/dev/null | tail -1 | cut -c1-8)"
for l in native ours; do
    awk -v l="$l" '$1=="W" && $2 >= 2780 { if (!($4 in f)) { o[++n] = $4; f[$4] = "" }; if (!index("," f[$4] ",", "," $2 ",")) f[$4] = f[$4] (f[$4] == "" ? "" : ",") $2 }
        END { for (i = 1; i <= n; i++) printf "%s\twriter\t%s\t%s\n", l, o[i], f[o[i]] }' "$W/tap_$l/t.tap"
    # every writer over the WHOLE run, with its write count (the boot clear, the round-start fade stepper, the uploader)
    awk -v l="$l" '$1=="W" { if (!($4 in c)) o[++n] = $4; c[$4]++ } END { for (i = 1; i <= n; i++) printf "%s\trun\t%s\t%d\n", l, o[i], c[o[i]] }' "$W/tap_$l/t.tap"
done > "$W/wr_all.tsv"
awk -F'\t' '$2 == "writer"' "$W/wr_all.tsv" > "$W/wr.tsv"
cat "$W/wr_all.tsv" >> "$W/got.tsv"
printf 'ours\tbuild\t%s\t%s\n' "${_bid:-unregistered}" "${_bfp:-?}" >> "$W/got.tsv"
echo "== 2. the rows"
sed 's/^/     /' "$W/got.tsv"
n_native="$(awk -F'\t' '$1=="native" && $2 ~ /^[0-9]+$/ {print $3}' "$W/got.tsv" | sort -u | wc -l | tr -d ' ')"
[ "$n_native" = 1 ] && ok "native's row 11 is one ramp at all three frames" || bad "native's row 11 changes across the frames ($n_native values) — the reference moved"
_n58="$(awk -F'\t' '$1=="native" && $2==2858 {print $3}' "$W/got.tsv")"; _o58="$(awk -F'\t' '$1=="ours" && $2==2858 {print $3}' "$W/got.tsv")"
[ "$_n58" = "$_o58" ] && ok "ours equals native at 2858, before the swap — both legs reached the move" || bad "ours differs from native already at 2858 — not the frozen shape"
if python3 - "$W/wr.tsv" "$REPO/build/out/vsav2_opcodes.bin" "$BUILD/verify_op.bin" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
img = {"native": open(sys.argv[2], "rb").read(), "ours": open(sys.argv[3], "rb").read()}
bad = [f"{r[0]} {r[2]}" for r in rows if img[r[0]][int(r[2], 16):int(r[2], 16) + 4].hex() != "48d1000f"]
print("  writers:", ", ".join(f"{r[0]} {r[2]} at {r[3]}" for r in rows))
sys.exit(1 if bad or not rows else 0)
PY
then ok "every writer of row 11 from 2780 is a movem.l d0-d3,(a1) — the palette-sequence uploader — in its own leg's opcode image"
else bad "a writer of row 11 from 2780 is not the uploader's movem.l d0-d3,(a1) (or there is none)"; fi
echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    { echo "# tests/expected/column_flash.tsv — palette row 11 (RAM:\$90C160, 32 bytes, HASHED) at the end of Donovan's Killshread Lightning"
      echo "# column (naming part donovan_4), native vsav2 against our merged build (tests/audit_column_flash.sh). Evidence class:"
      echo "# in-emulator, MAME. Frozen AS MEASURED with FREEZE=1 on $(basename "$BUILD"): native keeps its blue ramp, ours turns to a"
      echo "# fire ramp — the open cosmetic ticket. Columns: <leg> <frame> <row 11 SHA-1, 12 hex — never the bytes>; then"
      echo "# <leg> writer <pc> <frames>: every writer of row 11 from 2780 (a non-debug write tap); <leg> run <pc> <count>: every"
      echo "# writer over the whole run; one ours build row."
      echo "#--"
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/got.tsv"; then ok "every row as frozen"
else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/got.tsv" | sed 's/^/        /'; fi
if [ -z "$MODE" ]; then
    { table "$W/pl"; cat "$W/wr_all.tsv"; } > "$W/ctl.tsv"; printf 'ours\tbuild\t%s\t%s\n' "${_bid:-unregistered}" "${_bfp:-?}" >> "$W/ctl.tsv"
    if cmp -s "$W/want.tsv" "$W/ctl.tsv"; then echo "CONTROL DEAD: flash-gone — our dumps with native's row 11 still match the frozen rows"; fail=1
    else echo "CONTROL FIRED: flash-gone — our dumps with native's row 11 differ from the frozen rows ($(diff "$W/want.tsv" "$W/ctl.tsv" | grep -c '^>') rows)"; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_column_flash"; else echo "FAIL: audit_column_flash"; exit 1; fi
