#!/bin/sh
# audit_column_flash_cause.sh — WHY THE DEITY FLASHED ORANGE as Donovan's Killshread Lightning column ended (14z-189,
# GitHub #162's open question, answered): the fighter's PALETTE RELOAD kept vsavj's per-character mask, which lacks
# Donovan's bit, so our build reloaded his block rows 1-3 — and block row 1, an orange ramp, landed in row 11.
# RE-FROZEN 14z-216 TO "OURS = NATIVE" (#127/#162's (M), the maintainer 2026-11-01: "1. Yes, (M) at the next freeze,
# closing both (recommended) -> agreed"): the build carries vs2's mask word at PRG:0x02ADB2, so ours reloads row 0x0A
# only, as native does; the old shape is now the KNOWN-BAD leg, vsavj's word put back in the emulator's opcode share.
#
# WHAT: at frames 2807 and 2858 (the move's start and end) P1's fighter block (Donovan, id 0x13) runs the palette
#   RELOAD entry — vsavj/ours PRG:0x02ADAC, vs2 PRG:0x02A102: `movea.l $3a4(a6),a0 / bsr 0x2AD3C` (block row 0 into
#   palette row +0x18B), then `move.l #mask,d1 / move.b $382(a6),d0 / btst.l d0,d1 / bne -> rts`, else block rows
#   1-3 into the next three rows. vs2's mask (PRG:0x02A108) sets bit 0x13, so native reloads row 0 ONLY; vsavj's
#   (PRG:0x02ADB2) does not. Since (M) ours carries vs2's word and reloads row 0 only; the BAD leg puts vsavj's word
#   back in the emulator's decrypted-opcode share (nothing built, nothing on disk) and reloads rows 1-3 too, row 11
#   ($90C160) getting block row 1 — the orange ramp (Donovan's sprite-palette block, placed by `[[palette]]`). A STATIC
#   CENSUS of every `move.l #mask,Dn / move.b $382(An),Dm / btst` site pairs vs2's to ours and records where a TENANT
#   bit differs.
# HOW: the naming part donovan_4 (audit_column_flash.sh's rig: the part's pokes, the level and RNG pins, ours through
#   the merged wheel's real cursor path) on MAME, three legs at once — native vsav2, ours, BAD (ours with OPATCH
#   02adb4:ef92, vsavj's word) — each
#   under tests/lua/upload_tap.lua: a NON-DEBUG write tap on the object palette that logs, per uploader instruction,
#   the CPU registers at that instant (a0 = source + 0x10, the destination) and the requester's +0x382/+0x18B/+0x3A4.
#   A -debug breakpoint would read the same registers but desynchronise the replay ([MFI-5]). Then
#   tools/audit_charid_masks.py over vs2's, our build's and vsavj's opcode images.
# EXPECTS: the frozen rows; C1 ours uploads exactly as native at both frames (block row 0 into 0x0A and, since #294 at
#   M24, the per-frame routine's row 0x0C), and nothing writes row 11 after the move's 2813 upload; C2 native reloads
#   row 0 only, no row-11 write at either frame; C3 the BAD leg reloads block rows 1-3 into rows 0x0B-0x0D BEYOND
#   native at both frames (row 11 from block row 1) and writes row 11 after 2813 — the defect,
#   so the word is what decides; C4 the census reads the #162 site SAME (vs2 and ours both set bit 0x13).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/column_flash_cause.tsv tests/lib/controls.sh
#   tests/lua/upload_tap.lua tests/lua/pokes_spec.lua tests/replays/naming/donovan_4.json
#   tests/replays/naming/donovan_4.rpl tests/replays/naming/donovan_4.json tests/replays/naming/donovan_4.rpl tools/audit_charid_masks.py tools/name_moves.py
#   tools/run_mame.sh tools/setup_mame.sh tests/lib/sheet.sh
#
# SHEET: legs vs2,ours — moments: the two palette reloads the checks judge (2807, the move's start; 2858, its end), on native vs2, ours and the BAD leg (vsavj's mask word in the opcode share), each picture EVENT-PROVEN on that leg's own upload_tap.lua log in f-1..f+1 — not comparable: each game's stage, the palette rows other than 0x0A-0x0D, and P2's art (each game's own copy; [VSP-168]); the BAD leg's patch is in the emulator's opcode share only, built nowhere
#
# MUST-FIRE: perturbed-copy: mask-bit-planted — the census re-read with bit 0x13 flipped in our mask at PRG:0x02ADB2 (vsavj's value again) must read the #162 site DIFF, so C4 reads the bit it claims to read (in-gate: C4 must fail on the planted census; mode: the planted census IS the census and the gate FAILs)
# MUST-FIRE: known-bad: revert-ignored — C1 evaluated on the BAD leg (vsavj's mask word) instead of ours must fail, so C1 sees the defect it guards against (in-gate; mode: the BAD leg replaces ours in C1 and the gate FAILs)
#
# WHY. #162: the maintainer saw the deity above Donovan flash orange as the column ends. 14z-170/171 found the row
# (11), the writer (the uploader 0x02AD64/0x02AD78) and the source (his sprite-palette block row 1), and left open
# WHICH PATH points the uploader there; audit_column_flash.sh freezes the symptom. This gate freezes the path, the
# native comparison, the one-bit counterfactual and the class (the census). Since 14z-216 the counterfactual is
# the build, and the old shape is the BAD leg.
#
# NOT COVERED: how it LOOKS (the maintainer read the #162 sheets before the ruling, 14z-216: "probe is indeed the
# correct behavior"); row 11 BEFORE the move (ours holds the orange block row 1 from the
# match-start load where native holds another row — measured by palette dumps in this work's scratch, not frozen
# here); what the census's other DIFF sites do in play (static only); FBNeo and the MiSTer core.
#
# Usage: ROMDIR=... [MAME_BIN=~/.cache/vampire-saved/mame/cps2] [BUILD=build/m3b_merged33] [FREEZE=1] tests/audit_column_flash_cause.sh
#   emulator tier, MAME; three runs of 2870 frames at once
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged33}"
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
echo "== 1. three legs: native vsav2, ours $(basename "$BUILD"), BAD: ours with vsavj's mask word put back in the emulator (OPATCH 02adb4:ef92)"
leg native vsav2 "$ROMDIR" "$R" 02a0ba,02a0ce "" &
leg ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" 02ad64,02ad78 "" &
leg bad vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" 02ad64,02ad78 "02adb4:ef92" &
wait
for l in native ours bad; do
    _t="$W/$l/u.tap"
    grep -q '^END ' "$_t" 2>/dev/null || bad "$l: the tap never reached its END line — VOID"
    awk '$1=="W" && $2 < 100 {n++} END {exit n ? 0 : 1}' "$_t" 2>/dev/null || bad "$l: no boot write to the palette — a dead tap"
    grep -q '^ERR' "$_t" 2>/dev/null && bad "$l: the tap's register read raised an error"
    awk '$1=="U" && $2 >= 2800 {n++} END {exit n ? 0 : 1}' "$_t" 2>/dev/null || bad "$l: no uploader write from 2800 — the leg did not reach the move"
done
grep -q '^OPATCH 02adb4:ef92 readback ef92ef96$' "$W/bad/u.tap" 2>/dev/null || bad "bad: the opcode-share write did not read back as ef92ef96 — the BAD leg is void"
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
C1LEG=ours; [ "$MODE" = revert-ignored ] && C1LEG=bad
echo "== 2. the checks"
for f in 2807 2858; do
    o="$(upl_at "$W/$C1LEG/u.tap" $f)"; n="$(upl_at "$W/native/u.tap" $f)"; x="$(upl_at "$W/bad/u.tap" $f)"
    # 14z-216 (M24): C1 compares ours with NATIVE's uploads at the frame, not a fixed string — since #294 ours runs vs2's
    # per-frame routine, which re-uploads row 0x0C from block row 2 (blk+040) every frame of the move as native does, so
    # both legs read "0a:blk+000 0c:blk+040[ 0c:blk+040]"; the fixed "0a:blk+000" was frozen on a build without #294.
    [ -n "$n" ] && [ "$o" = "$n" ] && ok "[C1] ours ($C1LEG) at $f uploads exactly as native ($o)" || bad "[C1] ours ($C1LEG) at $f: '$o' (native '$n')"
    case " $n " in *" 0a:blk+000 "*) case "$n" in *0b:*) bad "[C2] native at $f writes row 11 ($n)" ;; *) ok "[C2] native at $f reloads block row 0 only, no row-11 write ($n)" ;; esac ;;
        *) bad "[C2] native at $f: no block-row-0 reload ('$n')" ;; esac
    # C3: what the BAD leg uploads BEYOND native at the frame (a multiset difference) must be block rows 1-3 into rows
    # 0x0B-0x0D — the reload vsavj's word lets through; native's own uploads (row 0x0A, and #294's per-frame 0x0C) cancel.
    xs="$(python3 -c 'import sys,collections; a=collections.Counter(sys.argv[1].split()); b=collections.Counter(sys.argv[2].split()); print(" ".join(sorted((a-b).elements())))' "$x" "$n")"
    [ "$xs" = "0b:blk+020 0c:blk+040 0d:blk+060" ] && ok "[C3] the BAD leg (vsavj's word) at $f reloads block rows 1-3 into rows 0x0B-0x0D beyond native — row 11 from block row 1 ($x; beyond native: $xs)" \
        || bad "[C3] the BAD leg at $f: '$x' — beyond native '$xs' (expected 0b:blk+020 0c:blk+040 0d:blk+060)"
done
_a="$(row11_after "$W/$C1LEG/u.tap" 2813)"; _b="$(row11_after "$W/bad/u.tap" 2813)"
[ "$_a" = 0 ] && ok "[C1] ours ($C1LEG): nothing writes row 11 after the move's 2813 upload" || bad "[C1] ours ($C1LEG): $_a writes to row 11 after 2813"
[ "$_b" != 0 ] && ok "[C3] the BAD leg writes row 11 $_b times after 2813 — the flash's write" || bad "[C3] the BAD leg writes row 11 nothing after 2813"
# the census
CEN="$W/census.txt"; PLANT="$W/census_planted.txt"
python3 "$REPO/tools/audit_charid_masks.py" "$V2OP" "$BUILD/verify_op.bin" "$VJOP" > "$CEN"
python3 "$REPO/tools/audit_charid_masks.py" "$V2OP" "$BUILD/verify_op.bin" "$VJOP" --plant-bit 02adb2,13 > "$PLANT"
[ "$MODE" = mask-bit-planted ] && cp "$PLANT" "$CEN"
c4() {  # c4 <census> -> 0 when the #162 site reads SAME with vs2's and ours' 0x13 both set
    awk '$1=="ROW" && $2=="02a108" && $4=="02adb2" {found=1; if ($7 ~ /1$/ && $8 ~ /1$/ && $9=="SAME") good=1} END {exit (found && good) ? 0 : 1}' "$1"
}
c4 "$CEN" && ok "[C4] the census reads the #162 site SAME: vs2 PRG:0x02A108 and ours PRG:0x02ADB2 both set bit 0x13" \
    || bad "[C4] the census does not read the #162 site as vs2-set / ours-set"
echo "     census (tenant bits 0x10 0x11 0x13 per site, vs2 | ours):"
awk '$1=="ROW" {printf "       vs2 %s / ours %s  %s | %s  %s\n", $2, $4, $7, $8, $9}' "$CEN"

# THE SHEET (#291, D2): with SHEET_OUT set, the three legs these checks read, re-run under upload_tap.lua itself (the
# BAD leg's OPATCH travels in its env) and EVENT-PROVEN on each leg's own log around the two reload frames.
. "$REPO/tests/lib/sheet.sh"
if sheet_on && [ -z "$MODE" ] && [ "${FREEZE:-0}" != 1 ]; then
    sheet_new cause "Killshread Lightning column (donovan_4): P1's palette reloads, native vs2 above ours and the BAD leg" donovan "#162" \
        "each game's stage, the palette rows other than 0x0A-0x0D, and P2's art (each game's own copy; [VSP-168]); the BAD leg's patch (vsavj's mask word) is in the emulator's opcode share only, built nowhere"
    sheet_leg cause native vs2 vsav2 "$ROMDIR" "$R" "$PK" "$FR"
    sheet_tap cause native tests/lua/upload_tap.lua "UTAP=90c000,1024;UPCS=02a0ba,02a0ce;WINDOW=2780,2870;FRAMES=$FR;OPATCH="
    sheet_leg cause ours ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" "$PK" "$FR"
    sheet_tap cause ours tests/lua/upload_tap.lua "UTAP=90c000,1024;UPCS=02ad64,02ad78;WINDOW=2780,2870;FRAMES=$FR;OPATCH="
    sheet_leg cause bad ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" "$PK" "$FR"
    sheet_tap cause bad tests/lua/upload_tap.lua "UTAP=90c000,1024;UPCS=02ad64,02ad78;WINDOW=2780,2870;FRAMES=$FR;OPATCH=02adb4:ef92"
    _sf_native="$(sheet_file cause native.tap "$W/native/u.tap")"; _sf_ours="$(sheet_file cause ours.tap "$W/ours/u.tap")"
    _sf_bad="$(sheet_file cause bad.tap "$W/bad/u.tap")"
    for f in 2807 2858; do
        o="$(upl_at "$W/ours/u.tap" $f)"; n="$(upl_at "$W/native/u.tap" $f)"; x="$(upl_at "$W/bad/u.tap" $f)"
        if [ "$o" = "0a:blk+000" ] && [ "$x" = "0a:blk+000 0b:blk+020 0c:blk+040 0d:blk+060" ]; then _sv="ours and native reload block row 0 only; the BAD leg rows 0-3 (row 11 from block row 1)"; else _sv="not the frozen shape"; fi
        sheet_moment cause "f$f" "f$f, P1's palette reload" "$_sv" "native: $n; ours: $o; BAD: $x"
        sheet_at cause "f$f" native "$f" event "$_sf_native:$((f - 1))-$((f + 1))"
        sheet_at cause "f$f" ours "$f" event "$_sf_ours:$((f - 1))-$((f + 1))"
        sheet_at cause "f$f" bad "$f" event "$_sf_bad:$((f - 1))-$((f + 1))"
    done
fi

# the frozen rows: P1's uploads per leg, the census's tenant-bit rows (never a mask's bytes), the build
{ for l in native ours bad; do summ "$l" "$W/$l/u.tap"; done
  awk '$1=="SITES" {printf "census\tsites\tvs2 %s ours %s vsavj %s\n", $3, $5, $7} $1=="ROW" {printf "census\t%s\t%s\t%s\t%s\t%s\n", $2, $4, $7, $8, $9}' "$CEN"
} > "$W/got.tsv"
echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    [ "$fail" = 0 ] || { echo "FAIL: audit_column_flash_cause — refusing to freeze a red"; exit 1; }
    { echo "# tests/expected/column_flash_cause.tsv — #162's cause, frozen AS MEASURED by tests/audit_column_flash_cause.sh on"
      echo "# $(basename "$BUILD"). Evidence class: in-emulator (MAME, a non-debug palette write tap with register reads) and static"
      echo "# (the char-id mask census). Columns: <leg> upload <palette row> <source: blk+off in the requester's +0x3A4 block, else its"
      echo "# address> <count> <first-last frame>, P1's uploads in frames 2800-2866; census <vs2 pc> <ours pc> <tenant bits 0x10 0x11 0x13"
      echo "# vs2> <ours> <SAME|DIFF> — addresses and derived bits only, never palette or mask bytes (rule 7). Legs: native vsav2, ours,"
      echo "# bad (ours with vsavj's mask word in the emulator's opcode share, OPATCH 02adb4:ef92) — re-frozen to ours = native 14z-216 ((M))."
      echo "#--"
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/got.tsv"; then ok "every row as frozen"
else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/got.tsv" | sed 's/^/        /'; fi
if [ -z "$MODE" ]; then
    if c4 "$PLANT"; then echo "CONTROL DEAD: mask-bit-planted — the census still reads the #162 site SAME with the bit flipped"; fail=1
    else echo "CONTROL FIRED: mask-bit-planted — with bit 0x13 flipped at PRG:0x02ADB2 the census reads the #162 site $(awk '$1=="ROW" && $2=="02a108" {print $9}' "$PLANT")"; fi
    # C1's OWN test on the BAD leg (rule-checker run 2026-11-01-1550 Q4: this used the pre-#294 fixed "0a:blk+000", which no
    # leg produces since M24, so the control reduced to the row-11 write count): the BAD leg's uploads equal native's at a frame
    _k=0; for f in 2807 2858; do [ "$(upl_at "$W/bad/u.tap" $f)" = "$(upl_at "$W/native/u.tap" $f)" ] && _k=$((_k + 1)); done
    if [ "$_k" = 0 ] && [ "$(row11_after "$W/bad/u.tap" 2813)" != 0 ]; then
        echo "CONTROL FIRED: revert-ignored — C1 on the BAD leg fails: it reloads rows 1-3 at 2807/2858 and writes row 11 after 2813"
    else echo "CONTROL DEAD: revert-ignored — the BAD leg passes C1"; fail=1; fi
fi
if [ -n "$MODE" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $MODE — the gate's checks failed with the control applied"
    else echo "CONTROL DEAD: $MODE — every check passed with the control applied"; fi
    echo "FAIL: audit_column_flash_cause (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_column_flash_cause"; else echo "FAIL: audit_column_flash_cause"; exit 1; fi
