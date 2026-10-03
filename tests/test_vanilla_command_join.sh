#!/bin/sh
# test_vanilla_command_join.sh — WHICH ANIM CHAIN EACH VANILLA CHARACTER'S
# COMMAND NORMALS (6+BUTTON, 3+BUTTON) ENTER, MEASURED ON vsavj (14z-189,
# GitHub #117 — the community cross-check's first slice past the plain normals).
#
# WHAT: which anim chain each vanilla character enters on toward+button (6x) and on
#   down-toward+button (3x) at the far pin, measured on vsavj — the join that names the
#   `6x`/`3x` command normals the cross-check could not reach, a chain other than the
#   character's far standing (resp. crouching) one being a command normal by measurement.
# HOW: tools/vanilla_join_rig.py performs each button with R and with DR held (30 legs on
#   MAME in parallel), the entered chain read from the node pointer +0x1C within the event
#   window and mapped onto the decoded graph; the rigs must regenerate byte-identically;
#   the control swaps one character's 6x and 3x rows. One more leg connects Lei-Lei's 6x
#   at 128 px and counts P2's HP drops.
# EXPECTS: every event fires, the 180 rows equal the frozen map, the structural rules on
#   the values (ground moves, a2 chains, the plain-normal fallbacks), LE 6HP lands ONE hit;
#   the swapped rows and the three-hit row fail.
# FOLLOWS: emu/mame-patches/ tests/expected/vanilla_command_slots.tsv
#   tests/expected/vanilla_normal_slots.tsv tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh tests/lua/field_trace.lua tools/run_mame.sh
#   tools/setup_mame.sh tools/vanilla_join_rig.py
#
# MUST-FIRE: perturbed-copy: swapped-commands — swapping one character's 6x/3x rows in a copy of the frozen command map must fail the section-3 compare against the measured map (mode: section 3 compares the measured map against that swapped copy and must fail)
# MUST-FIRE: perturbed-copy: three-hits — Lei-Lei's measured 6HP hit row rewritten to the workbook's three hits must fail the section-5 one-hit check (mode: section 5 reads that rewritten row and must fail)
#
# WHY IT EXISTS. The community cross-check (tools/crosscheck_framedata.py,
# docs/project/tables/community_crosscheck.md) joins a workbook row only where our
# chain carries the row's own name, and the names come from measurement, never
# from a fit against the sheet being checked ([VSP-166]). The plain normals were
# named by tests/test_vanilla_frame_join.sh and tests/test_vanilla_aerial_join.sh;
# the workbook's 19 `6x`/`3x` rows (BU 6MP/6MK/3HK, GA 6MK, ZA 6LP-6HK, AN 6MK,
# BI 6LP-6HK, LE 6MP/6HP) had no name to join to. This gate asks the GAME: each
# button performed with toward held (R — P1 faces right at the far pin) and with
# down-toward held (DR), at the FAR pin so 6+MP/HP is out of throw range (the
# workbook's `6MPor6HP` rows are the throws). The verdict is the chain the
# fighter's own node pointer +0x1C entered inside the event window
# (tests/lua/field_trace.lua), mapped onto tools/anim_nodes.py's graph; a 6x
# chain OTHER than the far standing chain of tests/expected/vanilla_normal_slots.tsv
# is that character's `6x`, a 3x chain other than the crouching chain (and the
# 6x one) its `3x` — named by tools/vanilla_frames.command_slots().
#
#   1. the rigs regenerate byte-identically (the schedule is code, not a file);
#   2. all 30 legs (and section 5's hit leg) run on vsavj and every event fires (never UNFIRED);
#   3. the measured table equals tests/expected/vanilla_command_slots.tsv;
#   4. STRUCTURE, from the values not the frozen text: every command attack is
#      performed on the ground (Sasquatch's 3LK, his self-lifting 2LK chain, is
#      declared and asserted) and enters a table-a2 chain; a 6x that is not a
#      command normal enters the far standing chain (the frozen normal map), a
#      3x that is not one enters the crouching chain (a2 0x0c-0x11); the command
#      chains found are reported;
#   5. LEI-LEI'S 6HP LANDS ONCE: the workbook lists it as three hits whose values
#      are its first three attack records to the byte; its one active run holds
#      seven records sharing hit id 1, and consecutive same-id attack nodes land
#      once (tests/test_rehit_ring.sh). Measured: at 128 px (P1 x 600, P2 x 728;
#      the far pin is out of its reach) it enters a2:0x1f and P2's HP (+0x50)
#      drops ONCE in the event window — on the idle standing victim, as every
#      hit count on the cross-check's page is read;
#   6. MUST-FIRE CONTROLS: swapping one character's 6x and 3x rows must FAIL the
#      compare; Lei-Lei's 6HP row rewritten to three hits must FAIL section 5.
#
# Usage: ROMDIR=... tests/test_vanilla_command_join.sh   # emulator tier (MAME, 31 legs in parallel; 29-30 s on ERIS, 14z-189)
#        CHARS="BU ZA" to measure a subset; FREEZE=1 to re-freeze; KEEP=dir keeps the traces.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
EXP=tests/expected/vanilla_command_slots.tsv
NORMAL=tests/expected/vanilla_normal_slots.tsv
IMG="${IMG:-build/out/vsavj_data.bin}"
W="$(mktemp -d)"
if [ -n "${KEEP:-}" ]; then mkdir -p "$KEEP"; trap 'cp -R "$W"/. "$KEEP"/ 2>/dev/null; rm -rf "$W"' EXIT; else trap 'rm -rf "$W"' EXIT; fi
bad=0
ok()  { echo "  ok    $1"; }
nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"

# ONE perturbation, called by the section-6 control (on the frozen file) and by
# the executable mode (on the compare baseline): swap BU's cmd/cmd_df labels,
# preserving file order so a line-for-line compare against the measured map fails.
swap_cmds() {  # swap_cmds <in> <out>
    awk -F'\t' 'BEGIN{OFS="\t"} $1=="BU" && ($2=="cmd"||$2=="cmd_df"){$2=($2=="cmd")?"cmd_df":"cmd"} {print}' "$1" > "$2"
}

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset"; exit 0; }
if [ ! -f "$IMG" ]; then
    . "$REPO/tests/lib/decrypt_cache.sh"
    decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 \
        || { echo "SKIP: no vsavj data view and the cache could not fill it"; exit 0; }
    IMG="$W/vsavj_data.bin"
fi

ALL="BU:0x00 DE:0x01 GA:0x02 VI:0x03 ZA:0x04 MO:0x05 AN:0x06 FE:0x07 BI:0x08 AU:0x09 SA:0x0a QB:0x0c LE:0x0d LI:0x0e JE:0x0f"
WANT="${CHARS:-}"
FIELDS="ff8414:w:p1y,ff840b:b:p1face,ff841c:l:node,ff8420:b:cnt"
DIRS="cmd cmd_df"
HITPIN="600 728"     # section 6: Lei-Lei's 6x at 128 px, inside 6HP's reach (the far pin, 176 px, is not)
HITFIELDS="ff841c:l:node,ff8420:b:cnt,ff8850:w:p2hp,ff8414:w:p1y"

echo "== test_vanilla_command_join: the command-normal map (6x, 3x), measured on vsavj =="

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
DO_HIT=1
[ -n "$WANT" ] && { case " $WANT " in *" LE "*) ;; *) DO_HIT=0;; esac; }
if [ "$DO_HIT" = 1 ]; then
    mkdir -p "$W/LE_hit"
    python3 tools/vanilla_join_rig.py gen 0x0d cmd "$W/LE_hit.rpl" "$W/LE_hit.json" $HITPIN >/dev/null || nope "gen LE hit"
    P="$(python3 -c "import json;print(';'.join(json.load(open('$W/LE_hit.json'))['pokes']))")"
    FR="$(python3 -c "import json;print(json.load(open('$W/LE_hit.json'))['frames'])")"
    ( cd "$W/LE_hit" && MAME_SANDBOX="$W/LE_hit/sb" REPLAY="$W/LE_hit.rpl" POKES="$P" \
        FIELDS="$HITFIELDS" FIELD_OUT="$W/LE_hit/t.txt" FIELD_FROM=2400 FIELD_TO="$FR" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > l.log 2>&1 ) </dev/null &
    n=$((n + 1))
fi
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
if grep -v '^#' "$W/got.txt" | grep -q UNFIRED; then nope "some events never fired:"; grep -v '^#' "$W/got.txt" | grep UNFIRED | sed 's/^/        /'
else ok "every event entered a chain (no UNFIRED)"; fi

echo "== 3. against the frozen table"
if [ "${FREEZE:-0}" = 1 ]; then cp "$W/got.txt" "$EXP"; echo "  FROZE $EXP ($(grep -vc '^#' "$EXP") rows)"; fi
if [ -n "$WANT" ]; then
    grep -v '^#' "$EXP" > "$W/exp_all.txt"
    for tab in $WANT; do grep "^$tab	" "$W/exp_all.txt"; done > "$W/exp.txt"
    grep -v '^#' "$W/got.txt" > "$W/g.txt"
else
    grep -v '^#' "$EXP" > "$W/exp.txt"; grep -v '^#' "$W/got.txt" > "$W/g.txt"
fi
# THE EXECUTABLE MODE: the compare baseline becomes the SWAPPED table, so the
# measured map no longer equals it and the gate reaches its own FAIL.
if [ "$MODE" = swapped-commands ]; then swap_cmds "$W/exp.txt" "$W/exp.txt.sw" && mv "$W/exp.txt.sw" "$W/exp.txt"; fi
if cmp -s "$W/exp.txt" "$W/g.txt"; then ok "the measured command map equals $EXP ($(grep -c . "$W/g.txt") rows)"
else nope "the command map moved"; diff "$W/exp.txt" "$W/g.txt" | head -20; fi

echo "== 4. the structure, from the values"
python3 - "$W/g.txt" "$NORMAL" <<'PY' || bad=$((bad + 1))
import sys, re
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
far = {}
for l in open(sys.argv[2]):
    if l.strip() and not l.startswith("#"):
        t, d, b, c = l.rstrip("\n").split("\t")[:4]
        if d == "far":
            far[(t, b)] = c
bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c
BTN = ["LP", "MP", "HP", "LK", "MK", "HK"]
crouch = {b: f"a2:{0x0c + i:#04x}" for i, b in enumerate(BTN)}
six = [r for r in rows if r[1] == "cmd"]; three = [r for r in rows if r[1] == "cmd_df"]
chk(len(six) == len(three) and six and len(rows) == len(six) + len(three), f"{len(six)} 6x + {len(three)} 3x rows")
# SASQUATCH'S 3LK IS HIS 2LK, AND THAT MOVE LIFTS HIM (measured 14z-189 on ERIS): DR+LK
# enters a2:0x0f, his crouching-LK chain, whose first node raises p1y from the press
# frame (40 -> 54 -> 40 over +0..+12) — the same y profile, frame for frame, as the
# plain crouch rig's D+LK (`vanilla_join_rig.py gen 0x0a crouch`, analysed --airborne:
# `SA crouch LK a2:0x0f air`). Not a jump (a jump enters a:0x0e first); declared here
# and ASSERTED so the fact cannot rot.
sa = [r for r in rows if (r[0], r[1], r[2]) == ("SA", "cmd_df", "LK")]
chk(not sa or (sa[0][3], sa[0][4]) == ("a2:0x0f", "air"),
    "SASQUATCH 3LK enters his crouching-LK chain a2:0x0f, which lifts p1y from the press frame (declared 'air')")
chk(all(r[4] == "ground" for r in rows if r not in sa),
    "every other command attack was performed on the GROUND (p1y never left the pre-event value during the press)")
chk(all(r[3].startswith("a2:") for r in rows), "every command attack enters a table-a2 chain")
cmd6 = [(r[0], r[2], r[3]) for r in six if r[3] != far.get((r[0], r[2]))]
cmd3 = [(r[0], r[2], r[3]) for r in three if r[3] != crouch[r[2]]]
chk(all((r[0], r[2]) in far for r in six), "every 6x row has its far standing row in the frozen normal map")
print(f"  note  6x: {len(cmd6)} of {len(six)} rows enter a chain OTHER than the far standing one: " +
      ", ".join(f"{c} 6{b}->{ch}" for c, b, ch in cmd6))
print(f"  note  3x: {len(cmd3)} of {len(three)} rows enter a chain OTHER than the crouching one: " +
      ", ".join(f"{c} 3{b}->{ch}" for c, b, ch in cmd3))
sys.exit(bad)
PY

echo "== 5. Lei-Lei's 6HP lands once"
# hit_check <chains.tsv> <damage.tsv>: 6HP entered a2:0x1f and P2's HP dropped exactly once
hit_check() {
    python3 - "$1" "$2" <<'PY'
import sys
ch = {r[2]: r[3] for r in (l.rstrip("\n").split("\t") for l in open(sys.argv[1])) if len(r) > 3}
dm = {r[2]: r[3] for r in (l.rstrip("\n").split("\t") for l in open(sys.argv[2])) if len(r) > 3}
ok = ch.get("HP") == "a2:0x1f" and dm.get("HP") == "1"
print(("  ok    " if ok else "  FAIL  ") + f"LE 6HP at 128 px enters {ch.get('HP')} (a2:0x1f expected) and lands {dm.get('HP')} hit(s) (1 expected; the workbook lists 3)")
sys.exit(0 if ok else 1)
PY
}
# ONE perturbation, used by the section-6 control and by the executable mode: the
# measured HP hit row rewritten to the workbook's three hits.
three_hits() { awk -F'\t' 'BEGIN{OFS="\t"} $3=="HP"{$4="3"} {print}' "$1" > "$2"; }
if [ "$DO_HIT" = 1 ]; then
    if [ -s "$W/LE_hit/t.txt" ]; then
        python3 tools/vanilla_join_rig.py analyse "$W/LE_hit/t.txt" "$W/LE_hit.json" "$IMG" 0x0d --tab LE --tsv > "$W/hit_chain.tsv"
        python3 tools/vanilla_join_rig.py analyse "$W/LE_hit/t.txt" "$W/LE_hit.json" "$IMG" 0x0d --tab LE --damage > "$W/hit_dmg.tsv"
        if [ "$MODE" = three-hits ]; then three_hits "$W/hit_dmg.tsv" "$W/hit_dmg.sw" && mv "$W/hit_dmg.sw" "$W/hit_dmg.tsv"; fi
        hit_check "$W/hit_chain.tsv" "$W/hit_dmg.tsv" || bad=$((bad + 1))
    else
        nope "leg LE hit: no samples (see $W/LE_hit/l.log)"
    fi
else
    echo "  (skipped: CHARS does not include LE)"
fi

echo "== 6. must-fire controls"
# Build the swapped copy from the FROZEN file directly (not $W/exp.txt, which the
# mode above may already have swapped) and prove it differs from the frozen map.
grep -v '^#' "$EXP" > "$W/orig.txt"
swap_cmds "$W/orig.txt" "$W/swapped.txt"
if cmp -s "$W/orig.txt" "$W/swapped.txt"; then vs_ctl_dead swapped-commands "swapping BU's 6x/3x rows leaves the table unchanged (a vacuous table)"; nope "control swapped-commands"
else vs_ctl_fired swapped-commands "swapping one character's 6x/3x rows changes the table (section 3 compares the measured map against it under the mode)"; fi
if [ "$DO_HIT" = 1 ] && [ -s "$W/hit_dmg.tsv" ]; then
    three_hits "$W/hit_dmg.tsv" "$W/hit_bad.tsv"
    if hit_check "$W/hit_chain.tsv" "$W/hit_bad.tsv" > /dev/null; then vs_ctl_dead three-hits "the one-hit check passed a three-hit row"; nope "control three-hits"
    else vs_ctl_fired three-hits "the one-hit check refuses Lei-Lei's 6HP rewritten to the workbook's three hits"; fi
elif [ "$DO_HIT" = 1 ]; then vs_ctl_dead three-hits "no measured hit row to perturb"; nope "control three-hits"
fi

[ "$bad" = 0 ] && { echo "PASS: test_vanilla_command_join"; exit 0; }
echo "FAIL: test_vanilla_command_join ($bad)"; exit 1
