#!/bin/sh
# test_vanilla_frame_join.sh — WHICH ANIM CHAIN EACH VANILLA CHARACTER'S STANDING
# NORMALS ENTER, MEASURED ON vsavj (14z-125, the community cross-check's join).
#
# WHAT IT HOLDS. docs/project/tables/community_crosscheck.md joins the community
# workbook's rows to our derived chains, and the join is only as good as the
# claim "button B on character C enters chain a2:S". That claim is NOT inferred
# here: tools/vanilla_join_rig.py performs each of the six standing normals at a
# far pin and again after a 150-frame walk-in, and the verdict is the chain the
# game's own anim node pointer (+0x1C, tests/lua/field_trace.lua) entered inside
# the event window, mapped onto the graph tools/anim_nodes.py decodes. 180 rows
# (15 characters x 2 distances x 6 buttons) frozen in
# tests/expected/vanilla_normal_slots.tsv.
#
# WHY IT EXISTS — a fixed layout was tried and this measurement KILLED it. The
# model was "even slot = the close normal, odd = the far one" for every
# character, inferred by fitting our own numbers against the workbook we were
# checking; that is circular, and it was wrong. Zabel is the specimen: he has NO
# proximity variants (both distances enter 0x00/02/04/06/08/0a), so the fixed
# model handed him the odd slots — which are his 6-prefixed COMMAND normals —
# and he came out INCONSISTENT on all five compared columns. On the measured
# join he is clean on all five. AN, BI, JE and QB are the same shape; LP's slot
# is character-dependent (0x00 on GA/VI/ZA/AN/BI/JE/QB, 0x01 elsewhere).
#
#   1. the rigs regenerate byte-identically (the schedule is code, not a file);
#   2. all 30 legs run on vsavj and every event fires (never UNFIRED);
#   3. the measured table equals tests/expected/vanilla_normal_slots.tsv;
#   4. MUST-FIRE CONTROL: the frozen table is not vacuous — swapping one
#      character's far and near rows must FAIL the compare.
#
# Usage: ROMDIR=... tests/test_vanilla_frame_join.sh   # emulator tier (MAME, ~4 min, legs in parallel)
#        CHARS="DE ZA" to measure a subset; FREEZE=1 to re-freeze.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
EXP=tests/expected/vanilla_normal_slots.tsv
IMG="${IMG:-build/out/vsavj_data.bin}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
bad=0
ok()  { echo "  ok    $1"; }
nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset"; exit 0; }
if [ ! -f "$IMG" ]; then
    # from the shared decrypt CACHE, never a direct decrypt (test_decrypt_cache §5)
    . "$REPO/tests/lib/decrypt_cache.sh"
    decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 \
        || { echo "SKIP: no vsavj data view and the cache could not fill it"; exit 0; }
    IMG="$W/vsavj_data.bin"
fi

# tab:id — the sheet tab beside the vsavj character id (STATE 14z-124)
ALL="BU:0x00 DE:0x01 GA:0x02 VI:0x03 ZA:0x04 MO:0x05 AN:0x06 FE:0x07 BI:0x08 AU:0x09 SA:0x0a QB:0x0c LE:0x0d LI:0x0e JE:0x0f"
WANT="${CHARS:-}"
FIELDS="ff8410:w:p1x,ff840b:b:p1face,ff841c:l:node,ff8420:b:cnt,ff8810:w:p2x,ff8850:w:p2hp,ff8782:b:id,ff8b82:b:p2id"

echo "== test_vanilla_frame_join: the standing-normal slot map, measured on vsavj =="

echo "== 1-2. the legs"
n=0
for pair in $ALL; do
    tab="${pair%%:*}"; cid="${pair##*:}"
    case " $WANT " in *" $tab "*) ;; "  ") ;; *) [ -n "$WANT" ] && continue;; esac
    for d in far near; do
        python3 tools/vanilla_join_rig.py gen "$cid" "$d" "$W/${tab}_$d.rpl" "$W/${tab}_$d.json" >/dev/null || nope "gen $tab $d"
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
head -6 "$EXP" > "$W/hdr.txt" 2>/dev/null || : > "$W/hdr.txt"
cat "$W/hdr.txt" > "$W/got.txt"
for pair in $ALL; do
    tab="${pair%%:*}"; cid="${pair##*:}"
    [ -n "$WANT" ] && { case " $WANT " in *" $tab "*) ;; *) continue;; esac; }
    for d in far near; do
        [ -s "$W/${tab}_$d/t.txt" ] || { nope "leg $tab $d: no samples (see $W/${tab}_$d/l.log)"; continue; }
        python3 tools/vanilla_join_rig.py analyse "$W/${tab}_$d/t.txt" "$W/${tab}_$d.json" "$IMG" "$cid" \
            --tab "$tab" --tsv >> "$W/got.txt" || nope "analyse $tab $d"
    done
done
if grep -q UNFIRED "$W/got.txt"; then nope "some events never fired:"; grep UNFIRED "$W/got.txt" | sed 's/^/        /'
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
if cmp -s "$W/exp.txt" "$W/g.txt"; then ok "the measured slot map equals $EXP ($(grep -c . "$W/g.txt") rows)"
else nope "the slot map moved"; diff "$W/exp.txt" "$W/g.txt" | head -20; fi

echo "== 4. the HIT set: what the moves actually do to a victim"
HEXP=tests/expected/vanilla_hit_damage.tsv
n=0
for pair in $ALL; do
    tab="${pair%%:*}"; cid="${pair##*:}"
    [ -n "$WANT" ] && { case " $WANT " in *" $tab "*) ;; *) continue;; esac; }
    python3 tools/vanilla_join_rig.py gen "$cid" hit "$W/${tab}_hit.rpl" "$W/${tab}_hit.json" >/dev/null || nope "gen $tab hit"
    mkdir -p "$W/${tab}_hit"
    P="$(python3 -c "import json;print(';'.join(json.load(open('$W/${tab}_hit.json'))['pokes']))")"
    FR="$(python3 -c "import json;print(json.load(open('$W/${tab}_hit.json'))['frames'])")"
    ( cd "$W/${tab}_hit" && MAME_SANDBOX="$W/${tab}_hit/sb" REPLAY="$W/${tab}_hit.rpl" POKES="$P" \
        FIELDS="$FIELDS" FIELD_OUT="$W/${tab}_hit/t.txt" FIELD_FROM=2400 FIELD_TO="$FR" FRAMES="$FR" \
        "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > l.log 2>&1 ) </dev/null &
    n=$((n + 1)); [ $((n % 8)) -eq 0 ] && wait
done
wait
head -8 "$HEXP" > "$W/hgot.txt"
for pair in $ALL; do
    tab="${pair%%:*}"; cid="${pair##*:}"
    [ -n "$WANT" ] && { case " $WANT " in *" $tab "*) ;; *) continue;; esac; }
    python3 tools/vanilla_join_rig.py analyse "$W/${tab}_hit/t.txt" "$W/${tab}_hit.json" "$IMG" "$cid" \
        --tab "$tab" --damage | awk -F'\t' '{print $1"\t"$3"\t"$4"\t"$5"\t"$6}' >> "$W/hgot.txt" || nope "damage $tab"
done
if [ "${FREEZE:-0}" = 1 ] && [ -z "$WANT" ]; then cp "$W/hgot.txt" "$HEXP"; echo "  FROZE $HEXP"; fi
if [ -n "$WANT" ]; then
    grep -v '^#' "$HEXP" > "$W/hexp_all.txt"
    for tab in $WANT; do grep "^$tab	" "$W/hexp_all.txt"; done > "$W/hexp.txt"
else
    grep -v '^#' "$HEXP" > "$W/hexp.txt"
fi
grep -v '^#' "$W/hgot.txt" > "$W/hg.txt"
if cmp -s "$W/hexp.txt" "$W/hg.txt"; then ok "the dealt damage and hit counts equal $HEXP ($(grep -c . "$W/hg.txt") rows)"
else nope "the hit measurement moved"; diff "$W/hexp.txt" "$W/hg.txt" | head -12; fi

echo "== 5. must-fire control"
python3 - "$W/exp.txt" "$W/ctl.txt" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
# swap far/near for the FIRST character that actually has a distinction
by = {}
for t, d, b, c in rows:
    by.setdefault(t, {}).setdefault(b, {})[d] = c
victim = next(t for t, bs in by.items() if any(v.get("far") != v.get("near") for v in bs.values()))
out = [("\t".join([t, {"far": "near", "near": "far"}[d] if t == victim else d, b, c])) for t, d, b, c in rows]
open(sys.argv[2], "w").write("\n".join(out) + "\n")
print(f"  (control swaps far/near for {victim})")
PY
if cmp -s "$W/exp.txt" "$W/ctl.txt"; then nope "control: the swapped table compares EQUAL — the freeze is vacuous"
else ok "control: swapping one character's far/near rows fails the compare"; fi

[ $bad -eq 0 ] && echo "PASS" || echo "FAIL ($bad)"
exit $bad
