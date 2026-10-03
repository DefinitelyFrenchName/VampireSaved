#!/bin/sh
# audit_column_flash_cause.sh — WHY THE DEITY FLASHES ORANGE as Donovan's Killshread Lightning column ends (14z-189,
# GitHub #162's open question, answered): the fighter's PALETTE RELOAD keeps vsavj's per-character mask, which lacks
# Donovan's bit, so on our build it reloads his block rows 1-3 — and block row 1, an orange ramp, lands in row 11.
#
# WHAT: at frames 2807 and 2858 (the move's start and end) P1's fighter block (Donovan, id 0x13) runs the palette
#   RELOAD entry — vsavj/ours PRG:0x02ADAC, vs2 PRG:0x02A102: `movea.l $3a4(a6),a0 / bsr 0x2AD3C` (block row 0 into
#   palette row +0x18B), then `move.l #mask,d1 / move.b $382(a6),d0 / btst.l d0,d1 / bne -> rts`, else block rows
#   1-3 into the next three rows. vs2's mask (PRG:0x02A108) sets bit 0x13, so native reloads row 0 ONLY; vsavj's
#   (PRG:0x02ADB2, unchanged in our build) does not, so ours also reloads rows 1-3 and row 11 ($90C160) gets block
#   row 1 — the orange ramp (Donovan's sprite-palette block, PRG:0x0CEB50, placed by `[[palette]]`). A COUNTERFACTUAL
#   leg sets the bit in the emulator's decrypted-opcode share (nothing built, nothing on disk): the 2858 reload then
#   writes row 0 only and nothing writes row 11 after the move's own 2813 upload. A STATIC CENSUS of every
#   `move.l #mask,Dn / move.b $382(An),Dm / btst` site pairs vs2's to ours and records where a TENANT bit differs.
# HOW: the naming part donovan_4 (audit_column_flash.sh's rig: the part's pokes, the level and RNG pins, ours through
#   the merged wheel's real cursor path) on MAME, three legs at once — native vsav2, ours, ours with OPATCH — each
#   under tests/lua/upload_tap.lua: a NON-DEBUG write tap on the object palette that logs, per uploader instruction,
#   the CPU registers at that instant (a0 = source + 0x10, the destination) and the requester's +0x382/+0x18B/+0x3A4.
#   A -debug breakpoint would read the same registers but desynchronise the replay ([MFI-5]). Then
#   tools/audit_charid_masks.py over vs2's, our build's and vsavj's opcode images.
# EXPECTS: the frozen rows; C1 ours reloads block rows 0-3 into rows 0x0A-0x0D at both frames, row 11 from block
#   row 1; C2 native reloads row 0 only, no row-11 write at either frame; C3 the counterfactual reloads row 0 only
#   and leaves row 11 untouched after 2813; C4 the census reads the #162 site DIFF (vs2 bit 0x13 set, ours clear).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/column_flash_cause.tsv tests/lib/controls.sh
#   tests/lua/upload_tap.lua tests/lua/pokes_spec.lua tests/replays/naming/donovan_4.json
#   tests/replays/naming/donovan_4.rpl tests/replays/ tools/audit_charid_masks.py tools/name_moves.py
#   tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: mask-bit-planted — the census re-read with bit 0x13 flipped in our mask at PRG:0x02ADB2 (what the fix would ship) must read the #162 site SAME, so C4 reads the bit it claims to read (in-gate: C4 must fail on the planted census; mode: the planted census IS the census and the gate FAILs)
# MUST-FIRE: known-bad: fix-ignored — C3 evaluated on OUR unpatched leg instead of the counterfactual must fail, so the counterfactual leg is what C3 measures (in-gate; mode: ours replaces the counterfactual and the gate FAILs)
#
# WHY. #162: the maintainer saw the deity above Donovan flash orange as the column ends. 14z-170/171 found the row
# (11), the writer (the uploader 0x02AD64/0x02AD78) and the source (his sprite-palette block row 1), and left open
# WHICH PATH points the uploader there; audit_column_flash.sh freezes the symptom. This gate freezes the path, the
# native comparison, the one-bit counterfactual and the class (the census).
#
# NOT COVERED: how the flash LOOKS with the bit set (no capture — the maintainer's 14z-170 capture shows the bug;
# a fix would need a before/after capture); row 11 BEFORE the move (ours holds the orange block row 1 from the
# match-start load where native holds another row — measured by palette dumps in this work's scratch, not frozen
# here); what the census's other DIFF sites do in play (static only); FBNeo and the MiSTer core.
#
# Usage: ROMDIR=... [MAME_BIN=~/.cache/vampire-saved/mame/cps2] [BUILD=build/m3b_merged30] [FREEZE=1] tests/audit_column_flash_cause.sh
#   emulator tier, MAME; three runs of 2870 frames at once
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged30}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/column_flash_cause.tsv"
V2OP="$REPO/build/out/vsav2_opcodes.bin"; VJOP="$REPO/build/out/vsavj_opcodes.bin"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/verify_op.bin" ] && [ -f "$V2OP" ] && [ -f "$VJOP" ] || { echo "SKIP: no opcode images (build/out, $BUILD/verify_op.bin)"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN; build $(basename "$BUILD")"

FR=2870
J="$REPO/tests/replays/naming/donovan_4.json"; R="$REPO/tests/replays/naming/donovan_4.rpl"
PK="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))");2000-$((FR-1)):ff8116:06;2363-$((FR-1)):ff80d4:0000"
awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R" > "$W/ours.rpl"
leg() {  # leg <name> <set> <rompath> <rpl> <uploader pcs> <opatch>
    _d="$W/$1"; mkdir -p "$_d"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$PK" UTAP="90c000,1024" UPCS="$5" \
        WINDOW="2780,2870" TRACE_OUT="$_d/u.tap" FRAMES="$FR" OPATCH="$6" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/upload_tap.lua" > "$_d/mame.log" 2>&1; rm -rf "$_d/sb" ) </dev/null
}
echo "== 1. three legs: native vsav2, ours $(basename "$BUILD"), ours with vs2's mask bit set in the emulator (OPATCH 02adb4:ef9a)"
leg native vsav2 "$ROMDIR" "$R" 02a0ba,02a0ce "" &
leg ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" 02ad64,02ad78 "" &
leg fix vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" 02ad64,02ad78 "02adb4:ef9a" &
wait
for l in native ours fix; do
    _t="$W/$l/u.tap"
    grep -q '^END ' "$_t" 2>/dev/null || bad "$l: the tap never reached its END line — VOID"
    awk '$1=="W" && $2 < 100 {n++} END {exit n ? 0 : 1}' "$_t" 2>/dev/null || bad "$l: no boot write to the palette — a dead tap"
    grep -q '^ERR' "$_t" 2>/dev/null && bad "$l: the tap's register read raised an error"
    awk '$1=="U" && $2 >= 2800 {n++} END {exit n ? 0 : 1}' "$_t" 2>/dev/null || bad "$l: no uploader write from 2800 — the leg did not reach the move"
done
grep -q '^OPATCH 02adb4:ef9a readback ef9aef96$' "$W/fix/u.tap" 2>/dev/null || bad "fix: the opcode-share write did not read back as ef9aef96 — the counterfactual is void"
[ "$fail" = 0 ] || { echo "FAIL: audit_column_flash_cause"; exit 1; }

# P1's uploads per (destination row, source) with counts and first/last frame; a source inside the requester's
# own block (+0x3A4) is written relative to it, anything else as its address — addresses, never palette bytes
summ() {  # summ <leg> <tap>
    python3 - "$1" "$2" <<'PY'
import sys
leg, path = sys.argv[1], sys.argv[2]
rows = {}
for l in open(path):
    if not l.startswith("U "):
        continue
    t = l.split(); f = int(t[1]); kv = dict(zip(t[2::2], t[3::2]))
    if kv["A6"] != "ff8400" or not 2800 <= f <= 2866:
        continue
    src = int(kv["A0"], 16) - 0x10; blk = int(kv["BLK"], 16); dst = int(kv["DST"], 16)
    if dst & 0x1F:
        continue                                   # the second half-row write of the same upload
    s = f"blk+{src - blk:03x}" if blk and 0 <= src - blk < 0x500 else f"{src:06x}"
    k = (f"{(dst - 0x90c000) // 0x20:02x}", s)
    r = rows.setdefault(k, [0, f, f, []]); r[0] += 1; r[2] = f; r[3].append(f)
for (d, s), (n, a, b, fs) in sorted(rows.items()):
    print(f"{leg}\tupload\t{d}\t{s}\t{n}\t{a}-{b}")
PY
}
upl_at() {  # upl_at <tap> <frame> -> "row:src ..." for P1's uploads at that frame
    python3 - "$1" "$2" <<'PY'
import sys
out = []
for l in open(sys.argv[1]):
    if not l.startswith("U "):
        continue
    t = l.split(); kv = dict(zip(t[2::2], t[3::2]))
    dst = int(kv["DST"], 16)
    if int(t[1]) != int(sys.argv[2]) or kv["A6"] != "ff8400" or dst & 0x1F:
        continue
    src = int(kv["A0"], 16) - 0x10; blk = int(kv["BLK"], 16)
    out.append(f"{(dst - 0x90c000) // 0x20:02x}:" + (f"blk+{src - blk:03x}" if blk and 0 <= src - blk < 0x500 else f"{src:06x}"))
print(" ".join(sorted(out)))
PY
}
row11_after() {  # row11_after <tap> <frame> -> count of writes to row 11 ($90C160-$90C17F) by ANY pc after <frame>
    awk -v f0="$2" '$1=="W" && $2 > f0 && $6 >= "90c160" && $6 < "90c180" {n++} END {print n + 0}' "$1"
}
FIXLEG=fix; [ "$MODE" = fix-ignored ] && FIXLEG=ours
echo "== 2. the checks"
for f in 2807 2858; do
    o="$(upl_at "$W/ours/u.tap" $f)"; n="$(upl_at "$W/native/u.tap" $f)"; x="$(upl_at "$W/$FIXLEG/u.tap" $f)"
    [ "$o" = "0a:blk+000 0b:blk+020 0c:blk+040 0d:blk+060" ] && ok "[C1] ours at $f reloads block rows 0-3 into rows 0x0A-0x0D — row 11 from block row 1 ($o)" \
        || bad "[C1] ours at $f: '$o' (expected 0a:blk+000 0b:blk+020 0c:blk+040 0d:blk+060)"
    case " $n " in *" 0a:blk+000 "*) case "$n" in *0b:*) bad "[C2] native at $f writes row 11 ($n)" ;; *) ok "[C2] native at $f reloads block row 0 only, no row-11 write ($n)" ;; esac ;;
        *) bad "[C2] native at $f: no block-row-0 reload ('$n')" ;; esac
    [ "$x" = "0a:blk+000" ] && ok "[C3] the counterfactual ($FIXLEG) at $f reloads block row 0 only ($x)" || bad "[C3] the counterfactual ($FIXLEG) at $f: '$x' (expected 0a:blk+000)"
done
_a="$(row11_after "$W/$FIXLEG/u.tap" 2813)"; _o="$(row11_after "$W/ours/u.tap" 2813)"
[ "$_a" = 0 ] && ok "[C3] the counterfactual ($FIXLEG): nothing writes row 11 after the move's 2813 upload (ours unpatched: $_o writes)" \
    || bad "[C3] the counterfactual ($FIXLEG): $_a writes to row 11 after 2813"
# the census
CEN="$W/census.txt"; PLANT="$W/census_planted.txt"
python3 "$REPO/tools/audit_charid_masks.py" "$V2OP" "$BUILD/verify_op.bin" "$VJOP" > "$CEN"
python3 "$REPO/tools/audit_charid_masks.py" "$V2OP" "$BUILD/verify_op.bin" "$VJOP" --plant-bit 02adb2,13 > "$PLANT"
[ "$MODE" = mask-bit-planted ] && cp "$PLANT" "$CEN"
c4() {  # c4 <census> -> 0 when the #162 site reads DIFF with vs2's 0x13 set and ours' clear
    awk '$1=="ROW" && $2=="02a108" && $4=="02adb2" {found=1; if ($7 ~ /1$/ && $8 ~ /0$/ && $9=="DIFF") good=1} END {exit (found && good) ? 0 : 1}' "$1"
}
c4 "$CEN" && ok "[C4] the census reads the #162 site DIFF: vs2 PRG:0x02A108 sets bit 0x13, ours PRG:0x02ADB2 does not" \
    || bad "[C4] the census does not read the #162 site as vs2-set / ours-clear"
echo "     census (tenant bits 0x10 0x11 0x13 per site, vs2 | ours):"
awk '$1=="ROW" {printf "       vs2 %s / ours %s  %s | %s  %s\n", $2, $4, $7, $8, $9}' "$CEN"

# the frozen rows: P1's uploads per leg, the census's tenant-bit rows (never a mask's bytes), the build
{ for l in native ours fix; do summ "$l" "$W/$l/u.tap"; done
  awk '$1=="SITES" {printf "census\tsites\tvs2 %s ours %s vsavj %s\n", $3, $5, $7} $1=="ROW" {printf "census\t%s\t%s\t%s\t%s\t%s\n", $2, $4, $7, $8, $9}' "$CEN"
} > "$W/got.tsv"
echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    [ "$fail" = 0 ] || { echo "FAIL: audit_column_flash_cause — refusing to freeze a red"; exit 1; }
    { echo "# tests/expected/column_flash_cause.tsv — #162's cause, frozen AS MEASURED by tests/audit_column_flash_cause.sh on"
      echo "# $(basename "$BUILD"). Evidence class: in-emulator (MAME, a non-debug palette write tap with register reads) and static"
      echo "# (the char-id mask census). Columns: <leg> upload <palette row> <source: blk+off in the requester's +0x3A4 block, else its"
      echo "# address> <count> <first-last frame>, P1's uploads in frames 2800-2866; census <vs2 pc> <ours pc> <tenant bits 0x10 0x11 0x13"
      echo "# vs2> <ours> <SAME|DIFF> — addresses and derived bits only, never palette or mask bytes (rule 7)."
      echo "#--"
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/got.tsv"; then ok "every row as frozen"
else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/got.tsv" | sed 's/^/        /'; fi
if [ -z "$MODE" ]; then
    if c4 "$PLANT"; then echo "CONTROL DEAD: mask-bit-planted — the census still reads the #162 site DIFF with the bit flipped"; fail=1
    else echo "CONTROL FIRED: mask-bit-planted — with bit 0x13 flipped at PRG:0x02ADB2 the census reads the #162 site $(awk '$1=="ROW" && $2=="02a108" {print $9}' "$PLANT")"; fi
    _k=0; for f in 2807 2858; do [ "$(upl_at "$W/ours/u.tap" $f)" = "0a:blk+000" ] && _k=$((_k + 1)); done
    if [ "$_k" = 0 ] && [ "$(row11_after "$W/ours/u.tap" 2813)" != 0 ]; then
        echo "CONTROL FIRED: fix-ignored — C3 on our unpatched leg fails: it reloads rows 1-3 at 2807/2858 and writes row 11 after 2813"
    else echo "CONTROL DEAD: fix-ignored — our unpatched leg passes C3"; fail=1; fi
fi
if [ -n "$MODE" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $MODE — the gate's checks failed with the control applied"
    else echo "CONTROL DEAD: $MODE — every check passed with the control applied"; fi
    echo "FAIL: audit_column_flash_cause (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_column_flash_cause"; else echo "FAIL: audit_column_flash_cause"; exit 1; fi
