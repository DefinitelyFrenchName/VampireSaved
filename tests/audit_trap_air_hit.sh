#!/bin/sh
# audit_trap_air_hit.sh — THE PLASMA TRAP DOME HITS AN AIRBORNE VICTIM, native vs2 and ours alike (14z-182, GitHub #175): Felicia's j.HP, whose node 4 carries a hurtbox reaching below her feet, meets the dome's flat box on her last descent frame (y 42) and is hit IN THE AIR — class 0x07, the air stager — frame-identical on both legs; one press later she is hit on the landing frame, the ground path.
#
# WHAT: whether the Plasma Trap can hit an airborne opponent, measured ours vs native: with Felicia
#   pressing j.HP at 3508 she is hit on her last descent frame (y 42, j.HP node 4) with class 0x07
#   (the air stager) on native vs2 and on the merged build alike, every traced field equal; pressing
#   at 3511 she passes over the box and is hit on the landing frame (the ground path, class 0x52
#   native / the ruled marker 0x38 ours).
# HOW: tools/trap_air_probe.sh on MAME, four legs in parallel (native and merged, press 3508 and
#   3511): the trap rig of tests/replays/hui/92_hui_trap_shock.rpl with REAL cursor picks (P1 Phobos,
#   P2 Felicia 0x07, tools/select_paths.py on each leg's own wheel), Felicia pinned at x 695 and
#   Phobos at x 540 over 3470-3489 (before the window), a neutral jump at 3490, j.HP at the press;
#   level 6 and RNG 0000 pinned (the ruled equalised input); the victim's position, HP, class,
#   freeze, sequence, family ids, node, facing and RESOLVED world-space hurtboxes, the dome's type,
#   live attack record and box extents, and Phobos's x, HP and freeze traced 3500-3530 and reduced to
#   per-field steps (raw table pointers and node addresses differ by build and are compared through
#   what they resolve to); the fighters named by their hitbox base against each image's bank row.
# EXPECTS: P1 0x10 and P2 0x07 on every leg; the 3508 legs hit at a frame with y > 40 in a2:0x14#4
#   with class 0x07, identical in every field; the 3511 legs hit on the landing frame (y > 40 the
#   frame before, 40 at the hit), identical but for the class byte 0x52 / 0x38; the frozen rows;
#   the victim's resolved hurtboxes equal on every frame whose node has the same static boxes in both
#   games' Felicia data (the air-hit frame among them), differing only where those static boxes differ
#   (frozen per leg: the victim is each game's own Felicia, by the superset invariant — 14z-182, her
#   b:0x0f head hurtbox (-8, 70, 12, 8) ours / (-3, 76, 17, 14) native), with our build's Felicia
#   equal to PRISTINE vsavj's (build/out/vsavj_data.bin) on every node our legs enter;
#   the three data files it reads byte-identical to the decrypted romsets the legs run; the seven
#   controls failing.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/trap_air_hit.tsv tests/lib/controls.sh
#   tests/lua/field_trace.lua tests/replays/hui/92_hui_trap_shock.rpl tools/anim_nodes.py
#   tools/hitbox_records.py tools/name_moves.py tools/run_mame.sh tools/select_paths.py
#   tools/select_wheel.py tools/setup_mame.sh tools/trap_air_boxes.py tools/trap_air_probe.sh
#   tools/trap_air_prologue.py tools/cps2_decrypt.py tools/_minitoml.py
#
# MUST-FIRE: perturbed-copy: air-grounded — a copy of the merged 3508 row with the hit's height set to the ground's 40 (what a dome that only hits grounded victims would read) must FAIL the airborne-hit check, so "hit in the air" is read from the height at the hit (in-gate: the perturbed row must fail the check; mode: the row is rewritten and the gate FAILs)
# MUST-FIRE: perturbed-copy: air-class — a copy of the merged 3508 row with the class at the hit rewritten to the ground marker 0x38 must FAIL the air-stager check, so class 0x07 is read, not assumed (in-gate: the perturbed row must fail; mode: the row is rewritten and the gate FAILs)
# MUST-FIRE: perturbed-copy: stale-image — a copy of our build's decrypted data view with one byte changed must FAIL the comparison with the romset our leg runs, so every box the gate reads is shown to come from the data MAME executes (in-gate: the planted copy must differ; mode: the planted copy is compared and the gate FAILs) — rule-checker run 2026-09-25-221 Q1/Q4
# MUST-FIRE: perturbed-copy: merge-corrupt — a copy of our build's static Felicia boxes with a charged node's vuln0 moved by a pixel (what a merge that corrupted her data would read) must FAIL the pristine-vsavj check, so a difference charged to "her own data" is shown to be vsavj's own (in-gate: the planted copy must fail; mode: the planted copy is the check's input and the gate FAILs) — rule-checker run 2026-09-25-220 Q1/Q4
# MUST-FIRE: perturbed-copy: box-drift — a copy of the merged 3508 row with the victim's first resolved hurtbox on a SAME-DATA frame moved must FAIL the legs-equal check, so the hurtboxes are compared wherever Felicia's data is the same on both games (in-gate: the perturbed pair must differ; mode: the row is rewritten and the gate FAILs) — rule-checker run 2026-09-25-219 Q1/Q4
# MUST-FIRE: perturbed-copy: dome-drift — a copy of the merged 3508 row with the dome's box x extent moved must FAIL the legs-equal check, so the dome's own state (its type, live record and box extents) is compared, not only the victim's (in-gate: the perturbed pair must differ; mode: the row is rewritten and the gate FAILs) — rule-checker run 2026-09-25-219 Q1/Q4
# MUST-FIRE: perturbed-copy: ours-drift — a copy of the merged 3508 row with one y step moved by a pixel must FAIL the legs-equal check, so "frame-identical" compares every traced field (in-gate: the perturbed pair must differ; mode: the row is rewritten and the gate FAILs)
#
# WHY. #175 asked whether the dome can hit an airborne opponent at all (the maintainer, 2026-09-25:
# "whether the trap can hit airborne opponents at all … can be confirmed in VS2"). tests/audit_trap_airborne.sh
# had shown a jumping Victor is never hit in the air; 14z-182 measured why and where the limit is: the
# dome's attack record is (0, 0, 40, 6) — a flat box, top 6 px above the ground — its hit test runs on
# EVERY pass against an airborne victim (the fighter-hit loop, vs2 0x1699c/0x169f0/0x16a46, A6 = the
# dome; a vuln id of 0 is no box and is skipped), and a jumping Victor's one airborne hurtbox has its
# bottom 33 px above his feet. tools/air_hurtbox_census.py found nodes whose hurtbox reaches the feet
# on six characters' jump attacks; Felicia's j.HP node 4 (bottom -6) is the one this rig drives. The
# maintainer read the capture sheets (tools/trap_air_sheet.sh) identical on 2026-09-25 and #175 closed
# on it. The facts: docs/game/engine_internals.md "Hitboxes and attack records".
#
# Usage: ROMDIR=... [MAME_BIN=...] [MERGED=build/m3b_merged27] [FREEZE=1] [CONTROL=air-grounded|air-class|ours-drift|dome-drift|box-drift|merge-corrupt|stale-image] tests/audit_trap_air_hit.sh
#   emulator tier, MAME: four legs in parallel, ~2 min.
set -u
ROMDIR="${ROMDIR:?set ROMDIR}"; if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
MERGED="${MERGED:-build/m3b_merged27}"; case "$MERGED" in /*) ;; *) MERGED="$REPO/$MERGED" ;; esac
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN ROMDIR MERGED
EXPECT="$REPO/tests/expected/trap_air_hit.tsv"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$MERGED/rompath/vsavjw.zip" ] || { echo "SKIP: no merged build at $MERGED"; exit 0; }
[ -f "$REPO/build/out/vsav2_data.bin" ] && [ -f "$REPO/build/out/vsavj_data.bin" ] || { echo "SKIP: no build/out/vsav2_data.bin / vsavj_data.bin (tools/cps2_decrypt.py)"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { printf '  ok    %s\n' "$1"; }; bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 0. THE DATA FILES ARE THE ROMSETS THE LEGS RUN (rule-checker run 2026-09-25-221 Q1/Q4)"
# every box this gate reads comes from a data view on disk; each is decrypted here from the zip MAME actually runs
# ($ROMDIR/vsav2.zip native, $ROMDIR/vsavj.zip for the pristine check, rompath/vsavjw.zip ours) and must be byte-identical
img_ok() {   # img_ok <zip> <data file the gate reads> <label>
    python3 tools/cps2_decrypt.py "$1" "$W/dv_$3.op" --data-out "$W/dv_$3.da" > "$W/dv_$3.log" 2>&1 || { bad "$3: $1 did not decrypt ($(tail -1 "$W/dv_$3.log"))"; return 1; }
    cmp -s "$W/dv_$3.da" "$2"
}
img_ok "$ROMDIR/vsav2.zip" "$REPO/build/out/vsav2_data.bin" vsav2 && ok "native: build/out/vsav2_data.bin is the data view of the vsav2.zip the native leg runs" || bad "native: build/out/vsav2_data.bin is NOT the running vsav2.zip's data view"
img_ok "$ROMDIR/vsavj.zip" "$REPO/build/out/vsavj_data.bin" vsavj && ok "pristine: build/out/vsavj_data.bin is the data view of \$ROMDIR/vsavj.zip" || bad "pristine: build/out/vsavj_data.bin is NOT vsavj.zip's data view"
img_ok "$MERGED/rompath/vsavjw.zip" "$MERGED/verify_data.bin" merged && ok "ours: $(basename "$MERGED")/verify_data.bin is the data view of the rompath/vsavjw.zip our leg runs" || bad "ours: verify_data.bin is NOT the running vsavjw.zip's data view"
# the planted copy is of the FILE the gate reads (a stale verify_data.bin), fed through img_ok's own comparison
cp "$MERGED/verify_data.bin" "$W/stale.da"; printf '\377' | dd of="$W/stale.da" bs=1 seek=4096 conv=notrunc 2>/dev/null
cmp -s "$MERGED/verify_data.bin" "$W/stale.da" && { bad "stale-image: the plant did not change the copy (byte 4096 already 0xff?)"; }
if cmp -s "$W/dv_merged.da" "$W/stale.da"; then vs_ctl_dead stale-image "a data file with one byte changed still compares equal to the running romset"; fail=1
else vs_ctl_fired stale-image "a copy of our data view with one byte changed fails the romset comparison"; fi
vs_ctl_is stale-image && { echo "MODE: stale-image"; cmp -s "$W/dv_merged.da" "$W/stale.da" || bad "ours: the (planted) data file is NOT the running vsavjw.zip's data view"; }
[ $fail = 0 ] || [ -n "${VS_CTL:-}" ] || { echo "FAIL: audit_trap_air_hit (a data file is not the running romset)"; exit 1; }

echo "== 1. the four legs (native / merged x j.HP at 3508 / 3511)"
for leg in native merged; do for p in 3508 3511; do
    LEG=$leg PICK=real P2CELL=07 XPIN="695@3470-3489" P1XPIN="540@3470-3489" ATK="$p-$((p + 2)) p2=3" \
        FROM=3500 TO=3530 sh tools/trap_air_probe.sh "$W/$leg-$p" > "$W/$leg-$p.out" 2>&1 &
done; done
wait
for leg in native merged; do for p in 3508 3511; do
    [ -s "$W/$leg-$p/trace.ft" ] && [ -s "$W/$leg-$p/boxes.txt" ] || { bad "$leg $p: no trace ($(tail -1 "$W/$leg-$p.out"))"; continue; }
    grep -q '^# fighters by hitbox base: P1 id 16, P2 id 7$' "$W/$leg-$p/boxes.txt" && ok "$leg $p: P1 Phobos (0x10) and P2 Felicia (0x07) by their hitbox bases" \
        || bad "$leg $p: the fighters are not Phobos / Felicia: $(grep '^# fighters' "$W/$leg-$p/boxes.txt")"
done; done
[ $fail = 0 ] || { echo "FAIL: audit_trap_air_hit (a leg did not run as intended)"; exit 1; }

echo "== 2. the rows"
# the victim is each game's OWN Felicia (on ours vsavj's, by the superset invariant): per NODE, her hurtboxes are
# resolved statically from each leg's own data image (vs2's; our build's verify_data.bin, vsavj layout); a frame
# whose node has the SAME static boxes on both images is compared strictly, and only a frame whose static boxes
# DIFFER is charged to her own data and frozen per leg (14z-182: her b:0x0f head hurtbox; rule-checker run
# 2026-09-25-219 Q1/Q4, sharpened from a whole-chain census that also charged j.HP, whose boxes are equal)
# one row per (press, leg): the first hit's frame, height before/at, class and node at the hit, then
# the steps of every traced field over 3500-3530 (a step = frame:value where the value changes)
python3 - "$W" "$REPO/build/out/vsav2_data.bin" "$MERGED/verify_data.bin" > "$W/rows.tsv" <<'PY'
import sys
sys.path.insert(0, "tools")
from trap_air_boxes import static_node_boxes
W = sys.argv[1]
SB = {"native": static_node_boxes(sys.argv[2], "vsav2", 7), "merged": static_node_boxes(sys.argv[3], "vsavj", 7)}
def charged(label):   # the node's static hurtboxes differ between the two games' Felicia data
    return SB["native"].get(label) != SB["merged"].get(label)
FIELDS = ("vx", "vy", "vhp", "vcls", "vfrz", "vseq", "vfam", "p1x", "p1hp", "p1frz")
for p in (3508, 3511):
    for leg in ("native", "merged"):
        d = {}
        for l in open(f"{W}/{leg}-{p}/trace.ft"):
            t = l.split()
            if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
        node, flip, vbox, dome = {}, {}, {}, {}
        cur = None
        for l in open(f"{W}/{leg}-{p}/boxes.txt"):
            if l.startswith("f") and "node=" in l:
                cur = int(l.split()[0][1:]); node[cur] = l.split("node=")[1].strip()
                t = dict(kv.split("=", 1) for kv in l.split("node=")[0].split() if "=" in kv)
                flip[cur] = t.get("flip"); vbox[cur] = t.get("vboxes"); dome.setdefault(cur, "-")
            elif cur is not None and l.strip().startswith("slot"):
                w = l.split()   # slotK type=.. rec=.. box y a..b x c..d gaps(...)
                dome[cur] = f"{w[1][5:]}/{w[2][4:]}/y{w[5]}/x{w[7]}"   # type/record/y extent/x extent — never the slot or the node ADDRESS, which differ by build
        if min(d) != 3500 or max(d) != 3530: sys.exit(f"VOID: {leg} {p} trace is {min(d)}..{max(d)}, not 3500..3530")
        hits = [f for f in range(3501, 3531) if d[f]["vhp"] < d[f - 1]["vhp"]]
        if not hits: sys.exit(f"VOID: {leg} {p}: the dome never connected")
        h = hits[0]
        steps = {k: ",".join("%d:%d" % (f, d[f][k] & 0xFFFFFFFF if k == "vfam" else d[f][k]) for f in sorted(d)
                             if f == 3500 or d[f][k] != d[f - 1][k]) for k in FIELDS}
        def st(m): return ",".join(f"{f}:{m.get(f)}" for f in sorted(d) if f == 3500 or m.get(f) != m.get(f - 1))
        nsteps = st(node)
        vsame = {f: (vbox.get(f) if not charged(node.get(f)) else "charged") for f in d}
        vchg = {f: (vbox.get(f) if charged(node.get(f)) else "-") for f in d}
        print("\t".join([f"p{p}", leg, f"hit={h}", f"y_before={d[h - 1]['vy']}", f"y_at_hit={d[h]['vy']}",
                         f"cls_at_hit={d[h]['vcls']}", f"node_at_hit={node.get(h)}"]
                        + [f"{k}={v}" for k, v in steps.items()] + [f"node={nsteps}", f"vflip={st(flip)}", f"vboxes_same={st(vsame)}", f"dome={st(dome)}", f"vboxes_charged={st(vchg)}"]))
PY
[ -s "$W/rows.tsv" ] || { cat "$W/rows.tsv"; bad "the rows did not reduce"; echo "FAIL: audit_trap_air_hit"; exit 1; }
cut -c1-150 "$W/rows.tsv" | sed 's/^/  /'
# air_ok <rows>: every p3508 row is hit IN THE AIR (y > 40 at the hit) in a2:0x14#4 with the air stager's class 7
air_ok() { awk -F'\t' '$1=="p3508"{n++; split($5,a,"="); split($6,c,"="); split($7,m,"=");
    if (a[2]+0 <= 40 || c[2]+0 != 7 || m[2] != "a2:0x14#4") { bad=1; print "    " $2 ": y_at_hit " a[2] ", class " c[2] ", node " m[2] } }
    END{ exit (n == 2 && !bad) ? 0 : 1 }' "$1"; }
# ground_ok <rows>: every p3511 row is hit on the LANDING frame (y > 40 before, 40 at the hit), native 0x52 / merged 0x38
ground_ok() { awk -F'\t' '$1=="p3511"{n++; split($4,b,"="); split($5,a,"="); split($6,c,"=");
    want = ($2 == "native") ? 82 : 56
    if (b[2]+0 <= 40 || a[2]+0 != 40 || c[2]+0 != want) { bad=1; print "    " $2 ": y " b[2] " -> " a[2] ", class " c[2] } }
    END{ exit (n == 2 && !bad) ? 0 : 1 }' "$1"; }
# legs_equal <rows> <press> <marker-substitute 1|0>: the merged row equals native's, the class marker aside when asked
legs_equal() {
    _n="$(awk -F'\t' -v p="p$2" '$1==p && $2=="native"{ $1=""; $2=""; $NF=""; print }' OFS='\t' "$1")"
    _m="$(awk -F'\t' -v p="p$2" '$1==p && $2=="merged"{ $1=""; $2=""; $NF=""; print }' OFS='\t' "$1")"
    [ "$3" = 1 ] && _n="$(printf '%s' "$_n" | sed -E 's/cls_at_hit=82/cls_at_hit=56/; s/(vcls=[^	]*):82/\1:56/g')"
    [ -n "$_n" ] && [ "$_n" = "$_m" ]
}
# every frame whose hurtboxes differ between the legs must lie in a chain the census charges to Felicia's data
python3 - "$W/rows.tsv" <<'PY' && ok "the only hurtbox differences between the legs are on frames whose node has DIFFERENT static hurtboxes in the two games' Felicia data (charged to her own data, frozen per leg)" || bad "a hurtbox differs between the legs on a frame whose node has the same static hurtboxes on both games"
import sys
rows = {}
for l in open(sys.argv[1]):
    f = l.rstrip("\n").split("\t"); rows[(f[0], f[1])] = dict(kv.split("=", 1) for kv in f[2:])
bad = 0
for p in ("p3508", "p3511"):
    if rows[(p, "native")]["vboxes_same"] != rows[(p, "merged")]["vboxes_same"]: bad = 1; print("    " + p + ": vboxes_same differs")
sys.exit(bad)
PY
# OUR FELICIA IS PRISTINE vsavj's (rule-checker run 2026-09-25-220 Q1/Q4): the charge above calls a difference "her
# own data" — true only if every node she passes through on our leg has the SAME static hurtboxes in our build's
# data view as in pristine vsavj's; checked here for every node our legs enter, charged ones included
# merge_ok <plant 0|1>: 0 = the real check; 1 = a copy of our build's static boxes with the first charged node's
# vuln0 moved by a pixel (what a merge that corrupted her data would read) — must FAIL
merge_ok() {
    PLANT="$1" python3 - "$W" "$MERGED/verify_data.bin" "$REPO/build/out/vsavj_data.bin" "$REPO/build/out/vsav2_data.bin" <<'PY'
import os, sys
sys.path.insert(0, "tools")
from trap_air_boxes import static_node_boxes
W = sys.argv[1]
ours = static_node_boxes(sys.argv[2], "vsavj", 7); vj = static_node_boxes(sys.argv[3], "vsavj", 7); v2 = static_node_boxes(sys.argv[4], "vsav2", 7)
seen = []
for p in (3508, 3511):
    for l in open(f"{W}/merged-{p}/boxes.txt"):
        if l.startswith("f") and "node=" in l:
            n = l.split("node=")[1].strip()
            if n not in seen: seen.append(n)
if os.environ.get("PLANT") == "1":
    first = next(n for n in seen if ours.get(n) != v2.get(n))
    b = list(ours[first]); x, y, hw, hh = b[0]; b[0] = (x + 1, y, hw, hh); ours = dict(ours); ours[first] = tuple(b)
bad = [n for n in seen if ours.get(n) != vj.get(n)]
charged = [n for n in seen if ours.get(n) != v2.get(n)]
print(f"    {len(seen)} nodes entered on our legs, {len(charged)} charged to Felicia's data ({' '.join(charged)}); ours != pristine vsavj on {len(bad)}" + (f": {' '.join(bad)}" if bad else ""))
sys.exit(1 if bad or not seen else 0)
PY
}
merge_ok 0 && ok "our build's Felicia is PRISTINE vsavj's on every node our legs enter (static hurtboxes equal), so a charged difference is vsavj's own data against vs2's" \
    || bad "our build's Felicia differs from pristine vsavj's on a node our legs enter — the merge, not her data"
if merge_ok 1 > /dev/null; then vs_ctl_dead merge-corrupt "a planted one-pixel change in our build's static boxes still passes the pristine check"; fail=1
else vs_ctl_fired merge-corrupt "a one-pixel change planted in our build's static boxes for a charged node fails the pristine-vsavj check"; fi
vs_ctl_is merge-corrupt && { echo "MODE: merge-corrupt"; merge_ok 1 || bad "the pristine-vsavj check refuses the planted change"; }
# the air-hit frame's hurtboxes must be COMPARED, not charged: the value of vboxes_same at the hit frame, both legs
python3 - "$W/rows.tsv" <<'PY' && ok "the air-hit frame (a2:0x14#4) is compared STRICTLY: its static hurtboxes are the same in both games' Felicia data" || bad "the air-hit frame's hurtboxes are charged to Felicia's data, not compared"
import sys, re
for l in open(sys.argv[1]):
    f = l.rstrip("\n").split("\t")
    if f[0] != "p3508": continue
    d = dict(kv.split("=", 1) for kv in f[2:]); hit = int(d["hit"]); v = None
    for m in re.finditer(r"(\d{4}):(.*?)(?=,\d{4}:|$)", d["vboxes_same"]):
        if int(m.group(1)) <= hit: v = m.group(2)
    if v in (None, "charged", "-"): print(f"    {f[1]}: vboxes_same at {hit} = {v}"); sys.exit(1)
PY
air_ok "$W/rows.tsv" && ok "j.HP at 3508: hit IN THE AIR on both legs (y > 40 at the hit, a2:0x14#4, class 0x07 — the air stager)" || bad "j.HP at 3508: not an airborne hit with the air stager's class on both legs"
ground_ok "$W/rows.tsv" && ok "j.HP at 3511: hit on the LANDING frame on both legs (the ground path: 0x52 native, the ruled marker 0x38 ours)" || bad "j.HP at 3511: not a landing-frame ground hit on both legs"
legs_equal "$W/rows.tsv" 3508 0 && ok "3508: the merged leg equals native's in every traced field, frame for frame (the hurtboxes on every frame whose static data agrees)" || bad "3508: the merged leg differs from native's"
legs_equal "$W/rows.tsv" 3511 1 && ok "3511: the merged leg equals native's but for the class byte (0x52 / 0x38, ruled)" || bad "3511: the merged leg differs from native's beyond the class marker"

# THE PERTURBATIONS (the merged 3508 row): the hit's height grounded; the class the ground marker; one y step moved
awk -F'\t' 'BEGIN{OFS="\t"} $1=="p3508" && $2=="merged"{ $5="y_at_hit=40" } {print}' "$W/rows.tsv" > "$W/rows_grounded.tsv"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="p3508" && $2=="merged"{ $6="cls_at_hit=56" } {print}' "$W/rows.tsv" > "$W/rows_class.tsv"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="p3508" && $2=="merged"{ for (i=8;i<=NF;i++) if ($i ~ /^dome=/) { sub(/x[0-9]+\.\./, "x999..", $i); break } } {print}' "$W/rows.tsv" > "$W/rows_dome.tsv"
awk -F'\t' 'BEGIN{OFS="\t"} $1=="p3508" && $2=="merged"{ for (i=8;i<=NF;i++) if ($i ~ /^vy=/) { split($i,s,","); n=split(s[2],q,":"); s[2]=q[1] ":" q[2]+1; $i=s[1]; for (j=2;j<=length(s);j++) $i=$i "," s[j]; break } } {print}' "$W/rows.tsv" > "$W/rows_drift.tsv"
if air_ok "$W/rows_grounded.tsv" > /dev/null; then vs_ctl_dead air-grounded "the merged row with the hit at y 40 still passes the airborne check"; fail=1
else vs_ctl_fired air-grounded "the merged row with the hit's height grounded (40) fails the airborne-hit check"; fi
if air_ok "$W/rows_class.tsv" > /dev/null; then vs_ctl_dead air-class "the merged row with the ground marker still passes the air-stager check"; fail=1
else vs_ctl_fired air-class "the merged row with the class 0x38 at the hit fails the air-stager check"; fi
if legs_equal "$W/rows_drift.tsv" 3508 0; then vs_ctl_dead ours-drift "the merged row with a y step moved still equals native's"; fail=1
else vs_ctl_fired ours-drift "the merged row with one y step moved by a pixel differs from native's"; fi
awk -F'\t' 'BEGIN{OFS="\t"} $1=="p3508" && $2=="merged"{ for (i=8;i<=NF;i++) if ($i ~ /^vboxes_same=/) { sub(/3500:[0-9-]+,/, "3500:999,", $i); break } } {print}' "$W/rows.tsv" > "$W/rows_box.tsv"
if legs_equal "$W/rows_box.tsv" 3508 0 || cmp -s "$W/rows_box.tsv" "$W/rows.tsv"; then vs_ctl_dead box-drift "the merged row with a same-data hurtbox moved still equals native's"; fail=1
else vs_ctl_fired box-drift "the merged row with a hurtbox moved on a same-data frame differs from native's"; fi
vs_ctl_is box-drift && { cp "$W/rows_box.tsv" "$W/rows.tsv"; echo "MODE: box-drift"; legs_equal "$W/rows.tsv" 3508 0 || bad "the legs-equal check refuses the moved hurtbox"; }
if legs_equal "$W/rows_dome.tsv" 3508 0 || cmp -s "$W/rows_dome.tsv" "$W/rows.tsv"; then vs_ctl_dead dome-drift "the merged row with the dome's box moved still equals native's"; fail=1
else vs_ctl_fired dome-drift "the merged row with the dome's x extent moved differs from native's"; fi
vs_ctl_is dome-drift && { cp "$W/rows_dome.tsv" "$W/rows.tsv"; echo "MODE: dome-drift"; legs_equal "$W/rows.tsv" 3508 0 || bad "the legs-equal check refuses the moved dome"; }
vs_ctl_is air-grounded && { cp "$W/rows_grounded.tsv" "$W/rows.tsv"; echo "MODE: air-grounded"; air_ok "$W/rows.tsv" > /dev/null || bad "the airborne-hit check refuses the grounded row"; }
vs_ctl_is air-class && { cp "$W/rows_class.tsv" "$W/rows.tsv"; echo "MODE: air-class"; air_ok "$W/rows.tsv" > /dev/null || bad "the air-stager check refuses the ground marker"; }
vs_ctl_is ours-drift && { cp "$W/rows_drift.tsv" "$W/rows.tsv"; echo "MODE: ours-drift"; legs_equal "$W/rows.tsv" 3508 0 || bad "the legs-equal check refuses the drifted row"; }

if [ "${FREEZE:-0}" = 1 ]; then
    [ $fail = 0 ] || { echo "REFUSED FREEZE: a check above is red"; echo "FAIL: audit_trap_air_hit"; exit 1; }
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED FREEZE: under a control mode"; exit 1; }
    { echo "# tests/expected/trap_air_hit.tsv — the Plasma Trap dome and an AIRBORNE Felicia (j.HP node 4), native vsav2 vs the merged build"
      echo "# ($(basename "$MERGED")): per (press, leg) the first hit's frame, height before/at, class and node, then the steps of every traced field 3500-3530"
      echo "# (tests/audit_trap_air_hit.sh). Evidence class: in-emulator. Frozen 14z-182 with FREEZE=1 (GitHub #175)."
      echo "#--"; cat "$W/rows.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/rows.tsv"; then ok "every row as frozen"; else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/rows.tsv" | cut -c1-160 | sed 's/^/        /'; fi
if [ -n "${VS_CTL:-}" ]; then [ $fail = 0 ] && { echo "PASS (the control mode did NOT reach FAIL)"; exit 0; } || { echo "FAIL: audit_trap_air_hit (control mode)"; exit 1; }; fi
[ $fail = 0 ] && echo "PASS: audit_trap_air_hit" || echo "FAIL: audit_trap_air_hit"
exit $fail
