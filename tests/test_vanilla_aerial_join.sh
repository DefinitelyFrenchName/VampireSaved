#!/bin/sh
# test_vanilla_aerial_join.sh — WHICH ANIM CHAIN EACH VANILLA CHARACTER'S JUMPING
# NORMALS ENTER FROM A NEUTRAL JUMP AND FROM A FORWARD JUMP, MEASURED ON vsavj
# (14z-145, the community cross-check's aerial join).
#
# WHY IT EXISTS. The cross-check's seven aerial outliers (BI J.HP/J.LP, BU J.MP,
# VI J.HP, FE J.HK/J.LK, SA J.MP) were the rows the community corpus lists as
# TWO moves — a neutral-jump `8J.x` and a forward-jump `9J.x` / `J.x` — while
# our slot map carried ONE chain per aerial button (a2 0x12-0x17). Static read
# first (14z-145): a2 0x18-0x1D is a SECOND aerial set — VI aliases 0x12-0x17
# on every button but HP, BU on LP/LK/HK, and where the two sets DIFFER is
# exactly where mizuumi splits the move (BU MP/HP/MK, BI LP/HP, FE LK/HK, LI
# HK, SA LP/LK, VI HP); under the workbook's +1 startup convention 0x12-0x17
# reads as the 8J rows and 0x18-0x1D as the 9J rows. A fit against the source
# being checked is not evidence ([VSP-166], the standing-normal lesson), so
# this gate asks the GAME: tools/vanilla_join_rig.py performs each button
# during a neutral jump (U) and during a forward jump (UR) and the verdict is
# the chain the fighter's own node pointer +0x1C entered inside the event
# window (tests/lua/field_trace.lua), mapped onto tools/anim_nodes.py's graph.
# 360 rows (15 characters x 4 directions x 6 buttons — neutral, forward,
# neutral-then-D+button and forward-then-D+button (14z-146), the last two REPORTED
# not constrained except Anakaris's, whose J.2K they are) frozen in
# tests/expected/vanilla_aerial_slots.tsv.
#
#   1. the rigs regenerate byte-identically (the schedule is code, not a file);
#   2. all 60 legs run on vsavj and every event fires (never UNFIRED);
#   3. the measured table equals tests/expected/vanilla_aerial_slots.tsv;
#   4. STRUCTURE, from the values not the frozen text: a neutral-jump attack
#      enters 0x12-0x17 only and a forward-jump attack 0x18-0x1D only, or the
#      very chain its neutral slot aliases; ANAKARIS's six neutral rows are
#      UNFIRED — his neutral jump is a HOVER (a:0x12) that takes no normal —
#      declared and asserted so the fact cannot rot; ZABEL's forward jump enters
#      his NEUTRAL set on all six buttons although his 0x18-0x1D hold different
#      chains (so those are not his forward-jump normals — what enters them is
#      unmeasured);
#   5. MUST-FIRE CONTROL: swapping one character's neutral and forward rows
#      must FAIL the compare.
#
# Usage: ROMDIR=... tests/test_vanilla_aerial_join.sh   # emulator tier (MAME, ~10 min, legs in parallel)
#        CHARS="BU VI" to measure a subset; FREEZE=1 to re-freeze; KEEP=dir keeps the traces.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
EXP=tests/expected/vanilla_aerial_slots.tsv
IMG="${IMG:-build/out/vsavj_data.bin}"
W="$(mktemp -d)"
if [ -n "${KEEP:-}" ]; then mkdir -p "$KEEP"; trap 'cp -R "$W"/. "$KEEP"/ 2>/dev/null; rm -rf "$W"' EXIT; else trap 'rm -rf "$W"' EXIT; fi
bad=0
ok()  { echo "  ok    $1"; }
nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset"; exit 0; }
if [ ! -f "$IMG" ]; then
    . "$REPO/tests/lib/decrypt_cache.sh"
    decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 \
        || { echo "SKIP: no vsavj data view and the cache could not fill it"; exit 0; }
    IMG="$W/vsavj_data.bin"
fi

ALL="BU:0x00 DE:0x01 GA:0x02 VI:0x03 ZA:0x04 MO:0x05 AN:0x06 FE:0x07 BI:0x08 AU:0x09 SA:0x0a QB:0x0c LE:0x0d LI:0x0e JE:0x0f"
WANT="${CHARS:-}"
FIELDS="ff8410:w:p1x,ff8414:w:p1y,ff840b:b:p1face,ff841c:l:node,ff8420:b:cnt,ff8810:w:p2x,ff8850:w:p2hp,ff8782:b:id,ff8b82:b:p2id"
DIRS="jump jump_fwd jump_down jump_fwd_down"   # jump_fwd_down (14z-146): a FORWARD jump then D+button — Anakaris's J.2K

echo "== test_vanilla_aerial_join: the aerial slot map by jump direction, measured on vsavj =="

echo "== 1. the rigs regenerate byte-identically"
for pair in $ALL; do
    tab="${pair%%:*}"; cid="${pair##*:}"
    [ -n "$WANT" ] && { case " $WANT " in *" $tab "*) ;; *) continue;; esac; }
    for d in $DIRS; do
        python3 tools/vanilla_join_rig.py gen "$cid" "$d" "$W/${tab}_$d.rpl" "$W/${tab}_$d.json" >/dev/null || nope "gen $tab $d"
        python3 tools/vanilla_join_rig.py gen "$cid" "$d" "$W/re.rpl" "$W/re.json" >/dev/null
        cmp -s "$W/${tab}_$d.rpl" "$W/re.rpl" && cmp -s "$W/${tab}_$d.json" "$W/re.json" || nope "rig $tab $d is not a pure function of its inputs"
    done
done
[ "$bad" = 0 ] && ok "every rig is a pure function of (character, direction)"

echo "== 2. the legs"
n=0
for pair in $ALL; do
    tab="${pair%%:*}"; cid="${pair##*:}"
    [ -n "$WANT" ] && { case " $WANT " in *" $tab "*) ;; *) continue;; esac; }
    for d in $DIRS; do
        mkdir -p "$W/${tab}_$d"
        P="$(python3 -c "import json;print(';'.join(json.load(open('$W/${tab}_$d.json'))['pokes']))")"
        FR="$(python3 -c "import json;print(json.load(open('$W/${tab}_$d.json'))['frames'])")"
        ( cd "$W/${tab}_$d" && MAME_SANDBOX="$W/${tab}_$d/sb" REPLAY="$W/${tab}_$d.rpl" POKES="$P" \
            FIELDS="$FIELDS" FIELD_OUT="$W/${tab}_$d/t.txt" FIELD_FROM=2400 FIELD_TO="$FR" FRAMES="$FR" \
            "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > l.log 2>&1 ) </dev/null &
        n=$((n + 1))
        [ $((n % 8)) -eq 0 ] && wait
    done
done
wait
ok "$n legs ran"

: > "$W/got.txt"
awk '/^#/{print; next} {exit}' "$EXP" > "$W/hdr.txt" 2>/dev/null || : > "$W/hdr.txt"
cat "$W/hdr.txt" > "$W/got.txt"
for pair in $ALL; do
    tab="${pair%%:*}"; cid="${pair##*:}"
    [ -n "$WANT" ] && { case " $WANT " in *" $tab "*) ;; *) continue;; esac; }
    for d in $DIRS; do
        [ -s "$W/${tab}_$d/t.txt" ] || { nope "leg $tab $d: no samples (see $W/${tab}_$d/l.log)"; continue; }
        python3 tools/vanilla_join_rig.py analyse "$W/${tab}_$d/t.txt" "$W/${tab}_$d.json" "$IMG" "$cid" \
            --tab "$tab" --tsv --airborne >> "$W/got.txt" || nope "analyse $tab $d"
    done
done
# ANAKARIS HAS NO NEUTRAL-JUMP ATTACKS — measured 14z-145, not a rig miss: on U he
# enters a:0x0e then the HOVER chain a:0x12 (y +8 px, held ~112 frames) and every
# button inside it is ignored, while his forward jump (a:0x10 pre-jump, then the
# a2 attack at y +38) fires on all six. The community corpus lists one aerial
# set for him. So his six neutral rows are EXPECTED UNFIRED, declared here and
# ASSERTED in section 4 (a leg that did not produce the event is VOID, never
# a pass — [VSP-170]; here the void is the finding).
# jump_down rows may be UNFIRED where D+button in the air is not an attack at all
# (a character whose neutral jump takes no normal — AN — or whose down-input is
# eaten): reported in section 4, never a rig failure.
if grep -v -E '^AN	jump	|^[A-Z]+	jump_down	|^[A-Z]+	jump_fwd_down	' "$W/got.txt" | grep -q UNFIRED; then nope "some events never fired:"; grep -v -E '^AN	jump	|^[A-Z]+	jump_down	|^[A-Z]+	jump_fwd_down	' "$W/got.txt" | grep UNFIRED | sed 's/^/        /'
else ok "every event entered a chain (no UNFIRED outside the declared Anakaris neutral-jump exception; jump_down and jump_fwd_down reported in 4)"; fi

echo "== 3. against the frozen table"
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE $EXP ($(grep -vc '^#' "$EXP") rows)"; fi
if [ -n "$WANT" ]; then
    grep -v '^#' "$EXP" > "$W/exp_all.txt"
    for tab in $WANT; do grep "^$tab	" "$W/exp_all.txt"; done > "$W/exp.txt"
    grep -v '^#' "$W/got.txt" > "$W/g.txt"
else
    grep -v '^#' "$EXP" > "$W/exp.txt"; grep -v '^#' "$W/got.txt" > "$W/g.txt"
fi
if cmp -s "$W/exp.txt" "$W/g.txt"; then ok "the measured aerial slot map equals $EXP ($(grep -c . "$W/g.txt") rows)"
else nope "the aerial slot map moved"; diff "$W/exp.txt" "$W/g.txt" | head -20; fi

echo "== 4. the structure, from the values"
python3 - "$W/g.txt" <<'PY' || bad=$((bad + 1))
import sys, re
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c
def slot(chain):
    m = re.match(r"a2:0x([0-9a-f]+)$", chain); return int(m.group(1), 16) if m else None
down = [r for r in rows if r[1] == "jump_down"]
fwd_down = [r for r in rows if r[1] == "jump_fwd_down"]
rows = [r for r in rows if r[1] not in ("jump_down", "jump_fwd_down")]
# jump_fwd_down (14z-146): a FORWARD jump then D+button. ANAKARIS — whose neutral
# jump is a hover — has D+KICK aerials only from a real jump: all three kicks enter
# ONE chain, a2:0x1e (outside both aerial sets), and D+punch is his forward-jump
# punch (a2:0x12-0x14). Asserted for him; REPORTED for everyone else.
an_fd = {r[2]: r[3] for r in fwd_down if r[0] == "AN"}
if an_fd:
    chk(all(an_fd.get(b) == "a2:0x1e" for b in ("LK", "MK", "HK")),
        f"ANAKARIS's forward-jump D+kicks all enter a2:0x1e (one chain, his J.2K): {an_fd.get('LK')} {an_fd.get('MK')} {an_fd.get('HK')}")
    chk(all(an_fd.get(b) == c for b, c in (("LP", "a2:0x12"), ("MP", "a2:0x13"), ("HP", "a2:0x14"))),
        "ANAKARIS's forward-jump D+punches are his forward-jump punches (a2:0x12-0x14)")
    others = sorted({(r[0], r[2], r[3]) for r in fwd_down if r[0] != "AN" and r[3] != "UNFIRED"})
    print(f"  note  jump_fwd_down on the other {len({o[0] for o in others})} characters: {len(others)} fired rows, reported not constrained")
an_neu = [r for r in rows if r[1] == "jump" and r[0] == "AN"]
chk(not an_neu or all(r[3] == "UNFIRED" for r in an_neu),
    "ANAKARIS neutral-jump attacks are UNFIRED on every button (his neutral jump is a hover that takes no normal)")
rows = [r for r in rows if not (r[1] == "jump" and r[0] == "AN")]
neu = [r for r in rows if r[1] == "jump"]; fwd = [r for r in rows if r[1] == "jump_fwd"]
chk(len(neu) + len(an_neu) == len(fwd) == len(down) and neu, f"{len(neu)} neutral + {len(fwd)} forward + {len(down)} down rows (+{len(an_neu)} Anakaris neutral, void by measurement)")
chk(all(r[4] == "air" for r in rows + down if r[3] != "UNFIRED"), "every attack was performed AIRBORNE (p1y left the ground before the press)")
chk(all(slot(r[3]) is not None and 0x12 <= slot(r[3]) <= 0x17 for r in neu),
    "NEUTRAL jump attacks enter a2 0x12-0x17 only")
# THE DOWN-ATTACK ROWS (jump_down: U, then D+button): REPORTED against the neutral
# row, never constrained — most characters have no D+button aerial and enter the
# plain aerial; the ones with a J.2x move (ZA, AN, QB, AU per the workbook) enter
# something else, and which slot that is is the finding (ZA's 0x1B-0x1D).
byn = {(r[0], r[2]): r[3] for r in rows if r[1] == "jump"}
other = [(r[0], r[2], r[3]) for r in down if r[3] != byn.get((r[0], r[2])) and r[3] != "UNFIRED"]
print(f"  note  jump_down: {len(down)} rows; {len(other)} enter a chain OTHER than the neutral attack: " +
      ", ".join(f"{c} {b}->{ch}" for c, b, ch in other))
by = {(r[0], r[2]): r[3] for r in neu}
# a forward slot may ALIAS the neutral chain (the same node address in both table
# entries — BU LP/LK/HK, VI everything but HP, LI HP); the node map names a shared
# address by its first slot, so such a forward attack reads as the neutral slot.
an = {r[0] for r in an_neu}
chk(all(slot(r[3]) is not None and (0x18 <= slot(r[3]) <= 0x1d or r[3] == by.get((r[0], r[2]))
        or (r[0] in an and 0x12 <= slot(r[3]) <= 0x17)) for r in fwd),
    "FORWARD jump attacks enter a2 0x18-0x1D, or the very chain the neutral slot enters (an alias — or, ZA, the neutral SET although his 0x18-0x1D differ)")
same = sum(1 for r in fwd if by.get((r[0], r[2])) == r[3])
print(f"  note  {same} of {len(fwd)} forward rows enter the SAME chain address as neutral (aliased slots)")
sys.exit(bad)
PY

echo "== 5. must-fire control"
grep -v '^#' "$EXP" | awk -F'\t' 'BEGIN{OFS="\t"} $1=="BU" && ($2=="jump"||$2=="jump_fwd"){$2=($2=="jump")?"jump_fwd":"jump"} {print}' | sort > "$W/swapped.txt"
grep -v '^#' "$EXP" | sort > "$W/orig.txt"
if cmp -s "$W/orig.txt" "$W/swapped.txt"; then nope "control did not fire: swapping BU's directions leaves the table unchanged (a vacuous table)"
else ok "control fires: swapping one character's neutral/forward rows changes the table"; fi

[ "$bad" = 0 ] && { echo "PASS: test_vanilla_aerial_join"; exit 0; }
echo "FAIL: test_vanilla_aerial_join ($bad)"; exit 1
