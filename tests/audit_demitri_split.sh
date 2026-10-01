#!/bin/sh
# audit_demitri_split.sh — DEMITRI'S DATA DIFFERS BETWEEN VSAVJ AND VS2, with no port in the loop: vs2 lengthened Chaos Flare's recovery and lowered its fireball's and several attacks' power, so his Chaos Flare runs its later nodes 1-2 frames earlier on vsavj and its fireball takes one more HP (GitHub #192, ruled not-ours 2026-10-01).
#
# WHAT: Demitri's (0x01) a2 and proj chains that differ between pristine vsavj and pristine vsav2,
#   each with WHAT differs per node (durations, attack records' red/white power), and his Chaos
#   Flare (236+LP) on both games: the frames on which his node changes and the HP the fireball
#   takes from Victor — the record of #192.
# HOW: tools/audit_same_data_p2.py --ids 01 --chains a2,proj over the two data views (the census's
#   own comparison, per chain); two MAME runs (pristine vsavj and vsav2, Demitri P1 against Victor
#   P2, Chaos Flare at 3000 and 3400, the level pinned 6 from 2000 and the RNG word 0000 from 2363,
#   tests/replays/dmg192/chaos_flare.rpl), Demitri's node and Victor's two HP words traced every
#   frame; every row compared with the frozen table.
# EXPECTS: every row equal to tests/expected/demitri_split.tsv — on 2026-10-01: Chaos Flare
#   a2:0x1e-0x21 differ ONLY in node 5's duration (30 -> 32/33/34/31), proj 0x00-0x02 red power
#   12 -> 11 and 0x03 15 -> 14; the node changes equal through +20 and from +45 earlier on vsavj
#   at both inputs; Victor losing 11 red on vsavj and 10 on vs2 per fireball; and section 3: each
#   game given the other game's five bytes (the hold duration, the fireball's four records) reads the
#   other game's rows exactly, an own-value poke changes nothing; the hold duration ALONE moves the
#   node rows and the four records ALONE the hit rows, both games; the hold node's ticks counted
#   (30 in 25/24 frames, 32 in 26/26, the level-6 double ticks deciding one frame or two); both
#   controls fire.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/demitri_split.tsv tests/replays/dmg192/
#   tests/lib/controls.sh tests/lua/field_trace.lua tests/lua/rom_poke.lua tools/audit_same_data_p2.py tools/hitbox_records.py
#   tools/anim_nodes.py tools/cps2_decrypt.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: games-agree — the rows with every vsavj in-emulator row replaced by its vsav2 twin's (what two games with the same Demitri would read) must FAIL the frozen compare, so the split is read from the rows, not assumed (in-gate: the perturbed rows differ from the frozen ones; mode: the perturbed rows are the gate's rows and the compare FAILs)
# MUST-FIRE: perturbed-copy: cause-unswapped — each game given the OTHER game's five bytes must read the other game's rows; with the UNPOKED traces in place of the swapped ones that must FAIL, and in-gate the unpoked games' rows must differ (in-gate: they differ; mode: the unpoked traces stand in and the gate FAILs)
#
# WHY. #192 (14z-186) saw Demitri's Chaos Flare change nodes 1-2 frames earlier on vsavj than on
# vsav2 from +45, with no port in the loop, and the maintainer saw a different sprite at +47. 14z-187b
# found it in the DATA: the hold node's duration byte (vsavj 30, vs2 32), the same with the fireball
# connecting at +17 or +24 (contact plays no part), and the fireball's power lowered by one. The
# maintainer: "agreed but we document the finding about the difference in the two games, as we did
# for the other differences found" (docs/game/engine_internals.md "DEMITRI'S DATA DIFFERS BETWEEN
# VSAVJ AND VS2"). Scratch origin: build/agent187b/t192/ (run.sh, summ.py, chain_of.py, a2_kinds.py).
#
# Usage: ROMDIR=... [MAME_BIN=...] [FREEZE=1] tests/audit_demitri_split.sh   # emulator tier, MAME, two runs (~1 min)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
EXPECT="$REPO/tests/expected/demitri_split.tsv"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$REPO/build/out/vsavj_data.bin" ] && [ -f "$REPO/build/out/vsav2_data.bin" ] || {
    echo "SKIP: no data images (build/out/vsavj_data.bin, build/out/vsav2_data.bin: tools/cps2_decrypt.py --data-out)"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. Demitri's differing a2 and proj chains, per node (tools/audit_same_data_p2.py --chains)"
python3 "$REPO/tools/audit_same_data_p2.py" "$REPO/build/out/vsavj_data.bin" "$REPO/build/out/vsav2_data.bin" --ids 01 --chains a2,proj \
    > "$W/census.txt"
grep '^chain ' "$W/census.txt" | sed 's/^/static\t/' > "$W/static.tsv"
ok "$(wc -l < "$W/static.tsv" | tr -d ' ') differing chains listed"

echo "== 2. Chaos Flare on pristine vsavj and vsav2 (Demitri P1, Victor P2)"
PK="$(python3 -c "print(f'{2000}-{(3800)-1}:ff8116:06' + ';' + f'{2363}-{(3800)-1}:ff80d4:0000')")"
for g in vsavj vsav2; do
    d="$W/$g"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/dmg192/chaos_flare.rpl" POKES="$PK" \
        FIELDS="ff841c:l:node,ff8420:b:cnt,ff8850:w:p2hp,ff8852:w:p2white,ff8782:b:id,ff8b82:b:p2id" \
        FIELD_OUT="$d/f.ft" FIELD_FROM=2300 FIELD_TO=3800 FRAMES=3800 \
        "$REPO/tools/run_mame.sh" "$g" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) </dev/null &
done
wait
cat > "$W/legs.py" <<'PY'
import sys
W = sys.argv[1]
for pair in sys.argv[2:]:
    g, d = pair.split("=")
    R, summ = {}, False
    for l in open(f"{d}/f.ft"):
        s = l.split()
        if s and s[0] == "F": R[int(s[1])] = {k: int(v) for k, v in (kv.split("=") for kv in s[2:])}
        elif "FIELDSUMMARY" in l: summ = True
    if not summ or 2300 not in R: print(f"PROBLEM {g}: incomplete trace", file=sys.stderr); continue
    if (R[2300]["id"], R[2300]["p2id"]) != (1, 3): print(f"PROBLEM {g}: ids {R[2300]['id']}/{R[2300]['p2id']}, not Demitri/Victor", file=sys.stderr)
    for base in (3000, 3400):
        ch = [f - base for f in range(base, base + 90) if R[f]["node"] != R[f - 1]["node"]]
        print(f"leg\t{g}\t{base}\tnodes\t" + " ".join(f"+{c}" for c in ch))
        for f in range(base, base + 90):
            a, b = (R[f - 1]["p2hp"], R[f - 1]["p2white"]), (R[f]["p2hp"], R[f]["p2white"])
            if a != b: print(f"leg\t{g}\t{base}\thit\t+{f - base}\tred {a[0] - b[0]}\twhite {a[1] - b[1]}")
PY
python3 "$W/legs.py" "$W" "vsavj=$W/vsavj" "vsav2=$W/vsav2" > "$W/legs.tsv" 2> "$W/problems.txt" || true
if [ -s "$W/problems.txt" ]; then bad "the legs: $(tr '\n' ' ' < "$W/problems.txt")"; else ok "both legs complete, Demitri P1 against Victor P2 as forced"; fi
sed 's/^/     /' "$W/legs.tsv"
cat "$W/static.tsv" "$W/legs.tsv" > "$W/got.tsv"
# the control's perturbed copy: every vsavj leg row takes its vsav2 twin's content
# the key: input frame + row kind, and for a hit row its offset (a nodes row's content IS the measurement, never its key)
awk -F'\t' 'BEGIN{OFS="\t"} function key(a, b, c, d) { return d == "hit" ? b FS d FS c : b FS d }
    $1=="leg" && $2=="vsav2" {v[key($1, $3, $5, $4)]=$0} {rows[NR]=$0} END {
    for (i = 1; i <= NR; i++) { split(rows[i], f, "\t")
        if (f[1] == "leg" && f[2] == "vsavj") { k = key(f[1], f[3], f[5], f[4]); if (k in v) { r = v[k]; sub(/\tvsav2\t/, "\tvsavj\t", r); print r; continue } }
        print rows[i] } }' "$W/got.tsv" > "$W/got_agree.tsv"
[ "$MODE" = games-agree ] && cp "$W/got_agree.tsv" "$W/got.tsv"

echo "== 3. the cause: the hold node's duration byte and the fireball's records, swapped (counterfactual, 14z-187b)"
# After rule-checker run 2026-10-01-517 Q1/Q4: the data difference was measured, the CAUSE only inferred. Each game is
# given the OTHER game's five bytes — the hold node a2:0x1e#5's duration (vsavj 0x12e592 = 30, vs2 0x1201d0 = 32) and the
# red power of the records Chaos Flare's fireball chains proj 0x00-0x03 point to (vsavj 12/12/12/15 at 0x946dc/0x946fc/
# 0x9471c/0x9473c, vs2 11/11/11/14 at 0xa3ad0/0xa3af0/0xa3b10/0xa3b30; located by tools/audit_same_data_p2.py's walker and
# tools/hitbox_records.py) — through tests/lua/rom_poke.lua, and must read the OTHER game's rows exactly; poking each game's
# own values must change nothing. The bytes' values are asserted first, so a drift fails here, not silently below.
python3 - "$REPO" <<'PY' > "$W/bytes.txt" 2>&1 || bad "the five bytes are not as measured: $(cat "$W/bytes.txt")"
import sys; R = sys.argv[1]
want = {"vsavj": {0x12e592: 30, 0x946dc: 12, 0x946fc: 12, 0x9471c: 12, 0x9473c: 15},
        "vsav2": {0x1201d0: 32, 0xa3ad0: 11, 0xa3af0: 11, 0xa3b10: 11, 0xa3b30: 14}}
bad = 0
for g, m in want.items():
    img = open(f"{R}/build/out/{g}_data.bin", "rb").read()
    for a, v in m.items():
        if img[a] != v: print(f"{g} {a:#x} is {img[a]}, not {v}"); bad = 1
print("bytes as measured" if not bad else "")
sys.exit(bad)
PY
JSW="12e592:20,946dc:0b,946fc:0b,9471c:0b,9473c:0e"; VSW="1201d0:1e,a3ad0:0c,a3af0:0c,a3b10:0c,a3b30:0f"
JSM="12e592:1e,946dc:0c,946fc:0c,9471c:0c,9473c:0f"; VSM="1201d0:20,a3ad0:0b,a3af0:0b,a3b10:0b,a3b30:0e"
sleg192() {  # sleg192 <game> <tag> <ROMPOKE> — section 2's leg through rom_poke.lua
    d="$W/S.$1.$2"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/tests/replays/dmg192/chaos_flare.rpl" POKES="$PK" ROMPOKE="$3" \
        FIELDS="ff841c:l:node,ff8420:b:cnt,ff8850:w:p2hp,ff8852:w:p2white,ff8782:b:id,ff8b82:b:p2id" \
        FIELD_OUT="$d/f.ft" FIELD_FROM=2300 FIELD_TO=3800 FRAMES=3800 \
        "$REPO/tools/run_mame.sh" "$1" -autoboot_script "$REPO/tests/lua/rom_poke.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) </dev/null
}
JDUR="12e592:20"; VDUR="1201d0:1e"; JREC="946dc:0b,946fc:0b,9471c:0b,9473c:0e"; VREC="a3ad0:0c,a3af0:0c,a3b10:0c,a3b30:0f"
sleg192 vsavj swap "$JSW" & sleg192 vsavj same "$JSM" & sleg192 vsav2 swap "$VSW" & sleg192 vsav2 same "$VSM" &
sleg192 vsavj dur "$JDUR" & sleg192 vsav2 dur "$VDUR" & sleg192 vsavj rec "$JREC" & sleg192 vsav2 rec "$VREC" & wait
[ "$(cat "$W"/S.*/mame.log | grep -c '^ROMPOKE ok')" = 30 ] && ! grep -q 'ROMPOKE FAIL' "$W"/S.*/mame.log \
    && ok "all thirty byte writes verified through the program space" || bad "a byte write did not verify"
for g in vsavj vsav2; do
    python3 "$W/legs.py" "$W" "$g=$W/S.$g.same" > "$W/same.$g.tsv" 2>/dev/null || true
    awk -F'\t' -v g="$g" '$1 == "leg" && $2 == g' "$W/legs.tsv" > "$W/base.$g.tsv"
    # byte for byte (rule-checker run 2026-10-01-521): the own-value leg's whole trace equals the unpoked leg's (same FIELDS)
    cmp -s "$W/same.$g.tsv" "$W/base.$g.tsv" && cmp -s "$W/S.$g.same/f.ft" "$W/$g/f.ft" \
        && ok "$g: poking the five bytes to their own values changes nothing (the whole trace, byte for byte)" || bad "$g: the own-value poke moved the rows or the trace"
done
SJ="$W/S.vsavj.swap"; SV="$W/S.vsav2.swap"
if [ "$MODE" = cause-unswapped ]; then SJ="$W/vsavj"; SV="$W/vsav2"; fi
python3 "$W/legs.py" "$W" "vsav2=$SJ" > "$W/swap.j.tsv" 2>/dev/null || true    # vsavj given vs2's bytes, labelled as the twin it must equal
python3 "$W/legs.py" "$W" "vsavj=$SV" > "$W/swap.v.tsv" 2>/dev/null || true
cmp -s "$W/swap.j.tsv" "$W/base.vsav2.tsv" && ok "vsavj given vs2's five bytes reads vs2's rows exactly (node changes and damage, both inputs)" \
    || { bad "vsavj given vs2's bytes does not read vs2's rows:"; diff "$W/base.vsav2.tsv" "$W/swap.j.tsv" | sed 's/^/        /' | head -6; }
cmp -s "$W/swap.v.tsv" "$W/base.vsavj.tsv" && ok "vs2 given vsavj's five bytes reads vsavj's rows exactly" \
    || { bad "vs2 given vsavj's bytes does not read vsavj's rows:"; diff "$W/base.vsavj.tsv" "$W/swap.v.tsv" | sed 's/^/        /' | head -6; }
if [ -z "$MODE" ]; then
    awk -F'\t' 'BEGIN{OFS="\t"} {$2="X"; print}' "$W/base.vsavj.tsv" > "$W/x.j"; awk -F'\t' 'BEGIN{OFS="\t"} {$2="X"; print}' "$W/base.vsav2.tsv" > "$W/x.v"
    if cmp -s "$W/x.j" "$W/x.v"; then
        vs_ctl_dead cause-unswapped "the two games' unpoked rows are already equal; the swap proves nothing" || fail=1
    else vs_ctl_fired cause-unswapped "the unpoked games' rows differ ($(diff "$W/base.vsavj.tsv" "$W/base.vsav2.tsv" | grep -c '^>') rows), so the swap's equality is something the comparison can refuse"; fi
fi

# THE SPLIT (after rule-checker run 2026-10-01-520 Q1/Q4: the five bytes were swapped together, so which byte moves the
# timing and which the damage was not separated): each game given the OTHER game's hold duration ALONE must read the
# other game's NODE rows and its OWN hit rows; given the other game's four fireball records ALONE, the other game's HIT
# rows and its own node rows. Measured 14z-187b: exactly so, both games, both events.
pick() { awk -F'\t' -v k="$2" 'BEGIN{OFS="\t"} $4 == k {$2 = "G"; print}' "$1"; }
for g in vsavj vsav2; do
    o=vsav2; [ "$g" = vsav2 ] && o=vsavj
    for t in dur rec; do python3 "$W/legs.py" "$W" "$g=$W/S.$g.$t" > "$W/split.$g.$t.tsv" 2>/dev/null || true; done
    if [ -n "$(pick "$W/split.$g.dur.tsv" nodes)" ] && [ "$(pick "$W/split.$g.dur.tsv" nodes)" = "$(pick "$W/base.$o.tsv" nodes)" ] \
        && [ "$(pick "$W/split.$g.dur.tsv" hit)" = "$(pick "$W/base.$g.tsv" hit)" ]; then
        ok "$g given $o's hold duration alone reads $o's node rows and its own hit rows"
    else bad "$g given $o's hold duration alone: nodes/hits not as split ($(pick "$W/split.$g.dur.tsv" nodes | head -1))"; fi
    if [ -n "$(pick "$W/split.$g.rec.tsv" hit)" ] && [ "$(pick "$W/split.$g.rec.tsv" hit)" = "$(pick "$W/base.$o.tsv" hit)" ] \
        && [ "$(pick "$W/split.$g.rec.tsv" nodes)" = "$(pick "$W/base.$g.tsv" nodes)" ]; then
        ok "$g given $o's four fireball records alone reads $o's hit rows and its own node rows"
    else bad "$g given $o's records alone: hits/nodes not as split ($(pick "$W/split.$g.rec.tsv" hit | head -1))"; fi
done
# the split can refuse: the games' node rows differ AND their hit rows differ (else one half of the split is vacuous)
if [ "$(pick "$W/base.vsavj.tsv" nodes)" != "$(pick "$W/base.vsav2.tsv" nodes)" ] && [ "$(pick "$W/base.vsavj.tsv" hit)" != "$(pick "$W/base.vsav2.tsv" hit)" ]; then
    ok "the two games' node rows differ and their hit rows differ, so each half of the split can fail"
else bad "the games' node rows or hit rows are already equal — that half of the split proves nothing"; fi
# WHY ONE FRAME ON ONE EVENT AND TWO ON THE OTHER (run 520 Q1): the hold node's tick counter (+0x20) drops by 2 on the
# level-6 double-tick frames (docs/game/engine_internals.md, the speed level). Counted over the hold node of each leg —
# measured 14z-187b: the first event 30 ticks in 25 frames (5 double) against 32 in 26 (6, the extra one at +45 a double
# frame); the second 30 in 24 (6) against 32 in 26 (6; +45 and +46 single frames).
python3 - "$W" <<'PY' > "$W/ticks.txt"
import sys; W = sys.argv[1]
for g in ("vsavj", "vsav2"):
    R = {}
    for l in open(f"{W}/{g}/f.ft"):
        s = l.split()
        if s and s[0] == "F": R[int(s[1])] = {k: int(v) for k, v in (kv.split("=") for kv in s[2:])}
    for ev in (3000, 3400):
        ch = [f - ev for f in range(ev, ev + 90) if R[f]["node"] != R[f - 1]["node"]]
        a, b = max(zip(ch, ch[1:]), key=lambda p: p[1] - p[0])
        dbl = [o for o in range(a + 1, b + 1) if R[ev + o - 1]["cnt"] - R[ev + o]["cnt"] == 2]
        print(f"ticks {g} {ev} hold +{a}..+{b} frames {b - a} entry {R[ev + a]['cnt']} doubles {len(dbl)} " + " ".join(f"+{o}" for o in dbl))
PY
sed 's/^/     /' "$W/ticks.txt"
[ "$(cut -d' ' -f2-11 "$W/ticks.txt" | tr '\n' '|')" = "vsavj 3000 hold +20..+45 frames 25 entry 30 doubles 5|vsavj 3400 hold +21..+45 frames 24 entry 30 doubles 6|vsav2 3000 hold +20..+46 frames 26 entry 32 doubles 6|vsav2 3400 hold +21..+47 frames 26 entry 32 doubles 6|" ] \
    && ok "the hold node: 30 ticks in 25/24 frames on vsavj, 32 in 26/26 on vs2 — two extra ticks cost one frame where one falls on a double-tick frame (+45, first event) and two where none does" \
    || bad "the hold node's ticks are not as measured: $(tr '\n' '|' < "$W/ticks.txt")"

echo "== 4. the frozen rows"
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    [ "$fail" = 0 ] || { echo "FAIL: not freezing over a failed leg"; exit 1; }
    { echo "# tests/expected/demitri_split.tsv — Demitri's data differences between pristine vsavj and pristine vsav2 (tests/audit_demitri_split.sh,"
      echo "# GitHub #192): the static chain lines of tools/audit_same_data_p2.py --chains a2,proj, and his Chaos Flare on both games"
      echo "# (node-change offsets, and Victor's red/white loss per fireball hit). Evidence class: static (the two data views) +"
      echo "# in-emulator, MAME. Frozen AS MEASURED with FREEZE=1."
      echo "#--"
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/got.tsv"; then ok "every row as frozen"
else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/got.tsv" | sed 's/^/        /' | head -20; fi
if [ -z "$MODE" ]; then
    if cmp -s "$W/want.tsv" "$W/got_agree.tsv"; then vs_ctl_dead games-agree "the rows with vs2's legs in vsavj's place still match the frozen rows" || fail=1
    else vs_ctl_fired games-agree "the rows with vs2's legs in vsavj's place differ from the frozen rows ($(diff "$W/want.tsv" "$W/got_agree.tsv" | grep -c '^>') rows) — the split is what the rows hold"; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_demitri_split"; else echo "FAIL: audit_demitri_split"; exit 1; fi
