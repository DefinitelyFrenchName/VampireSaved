#!/bin/sh
# audit_trap_airborne.sh — THE PLASMA TRAP DOME AND A JUMPING VICTOR, native vs merged (14z-181, GitHub #163's last open item): the dome NEVER connects with the victim in the air — he jumps over the active dome to apex 127 and is hit on the frame he lands (y back to the ground's 40) — and from that frame the victim's freeze, shock sub-state and HP and Phobos's freeze are frame-for-frame identical, the class byte the ruled marker (0x52 native / 0x38 merged), as on the ground.
#
# WHAT: what the Plasma Trap dome does to a victim who JUMPS while it is active: on the deep-overlap
#   trap rig with Victor pressing up at 3490 the jump takes (y 40 -> apex 127 -> 40, 3493-3528), the
#   dome does not touch him in the air, and it hits him on the LANDING frame (f3529, y 43 -> 40) on
#   both legs; the shock then plays as on the ground — freeze from 0x18, sub-state 4, Phobos never
#   frozen — the class byte 0x52 on native and the marker 0x38 on the merged build (the class-0x52
#   rule, ruled 2026-09-18); frozen per leg as steps. THE GROUND IS y = 40 (engine_internals.md), so
#   "airborne" is y > 40 — reading y > 0 as airborne is the error rule-checker run 2026-09-25-164
#   caught in this gate's first form.
# HOW: two MAME runs (native vsav2, the merged build) of tests/replays/hui/92_hui_trap_shock.rpl
#   with one added line (P2 up at 3490), the trap gate's forced-pick pokes, level and RNG pins;
#   the victim's class, freeze, sub-state, HP and height and Phobos's freeze traced every frame
#   3395-3620; the STEPS of each field frozen per leg with the jump's airborne span, apex and
#   landing frame; both legs must be identical in every field but the class marker; the jump must
#   have TAKEN (apex > 40), the hit must land ON the landing frame (y > 40 the frame before, 40 at
#   the hit) and never inside the airborne span.
# EXPECTS: the frozen rows; the two legs equal but for 0x52 / 0x38; the hit on the landing frame on
#   both; the three controls failing. SWEEP=1 adds the five other jump timings whose jump takes and
#   lands while the dome is active (3466, 3470, 3474, 3480, 3486): each asserted the same way,
#   printed, never frozen. Not covered: an airborne hit by the dome (none exists in this rig —
#   every press timing 3440-3499 was traced on native: 3440-3460 land before the dome's attack
#   box switches on (f3500 in this rig, measured 14z-182 by tools/trap_air_probe.sh),
#   3461-3498 are hit on the landing frame, 3499+ never jump; a lower arc or a juggled victim is not
#   tried — GitHub #175), the solo Phobos track.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/trap_airborne.tsv
#   tests/lua/field_trace.lua tests/replays/hui/92_hui_trap_shock.rpl tools/run_mame.sh
#   tools/setup_mame.sh tests/lib/controls.sh
#
# MUST-FIRE: perturbed-copy: air-class — a copy of the merged leg's rows with the victim's class steps rewritten to the air stager's 7 (what a dome hit routed to the AIR case would read) must FAIL the frozen compare, so "the dome takes the ground path" is read from the rows, not assumed (in-gate: the perturbed copy must differ from the frozen rows; mode: the merged rows are rewritten and the compare FAILs)
# MUST-FIRE: perturbed-copy: air-hit — a copy of the merged leg's rows with the first hit moved INSIDE the airborne span (hit = the span's first frame + 10, y 95 -> 100) must FAIL the landing-frame clause of the same check (y > 40 the frame before, 40 at the hit, hit == landing), so a dome that DID connect in the air could not pass as a landing hit — the clause the conclusion rests on, exercised on its own (in-gate: the perturbed copy must fail the check; mode: the merged rows are rewritten and the check FAILs)
# MUST-FIRE: perturbed-copy: grounded-hit — a copy of the merged leg's rows with the jump erased (apex 40, no airborne span, the hit two frames before the landing) must FAIL the "the jump took and the hit is on the landing frame" check, so a victim who never left the ground cannot pass as the airborne case — the first form's defect (in-gate: the perturbed copy must fail the check; mode: the merged rows are rewritten and the check FAILs)
#
# WHY. #163 (the class-0x52 rule, shipped in M19) kept one item open: a column hit or a Plasma Trap
# hit on an AIRBORNE victim — the air stager's case — was not measured. 14z-181 measured both: the
# column on a jumping Demitri (height 103) takes the air stager (class 7) identically on both legs
# (tests/audit_column_shock.sh section 1c); the dome never reaches a jumping Victor in the air — of
# the presses 3440-3499 on native, 3440-3460 land before the dome is active and are hit on the
# ground, 3461-3498 are airborne across or after the box's switch-on at f3500 (apex 127) and are
# hit as they LAND (a jumping Victor's one airborne hurtbox sits 33 px above his feet, over the
# box's 12 px — GitHub #175, tests/audit_trap_air_hit.sh for the victim who IS hit in the air), 3499 never
# jumps; the landing-frame hits take the ground path, identically on both games. The first form of this gate read y > 0 as airborne and
# called the landing-frame hit "the falling victim at height 40"; rule-checker run 2026-09-25-164
# found it from the sweep (jumps pressed after the hit still read 40). So with this rig no dome hit
# reaches the air stager, and whether ANY arc can is the open question of the ticket that carries it.
#
# Usage: ROMDIR=... [MAME_BIN=...] [MERGED=build/m3b_merged28] [FREEZE=1] [SWEEP=1 [SWEEP_JUMPS="3440 3441 ..."]] [CONTROL=air-class|grounded-hit|air-hit] tests/audit_trap_airborne.sh
#   emulator tier, MAME: two legs in parallel, ~1 min (SWEEP=1: five more pairs, ~6 min).
set -u
ROMDIR="${ROMDIR:?set ROMDIR}"; if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
MERGED="${MERGED:-build/m3b_merged28}"; case "$MERGED" in /*) ;; *) MERGED="$REPO/$MERGED" ;; esac
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
EXPECT="$REPO/tests/expected/trap_airborne.tsv"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$MERGED/rompath/vsavjw.zip" ] || { echo "SKIP: no merged build at $MERGED"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { printf '  ok    %s\n' "$1"; }; bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
JUMP=3490
SWEEP_JUMPS="${SWEEP_JUMPS:-3466 3470 3474 3480 3486}"   # override to re-run the 14z-181 census: every press 3440-3499 (build/agent181/trap_airborne_sweep_14z181.txt)
PK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,3640)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,3640)))")"
# legs <dir> <jump>: the two legs of the trap rig with P2 up at <jump>, traces at <dir>/{native,merged}.ft
legs() {
    _d="$1"; _j="$2"; mkdir -p "$_d"
    { sed '/^3900 wait/d' tests/replays/hui/92_hui_trap_shock.rpl | grep -v '^#'; echo "$_j-$((_j + 2)) p2=U"; echo "3900 wait"; } > "$_d/air.rpl"
    for leg in native merged; do
        if [ $leg = native ]; then set_=vsav2; rp="$ROMDIR"; else set_=vsavjw; rp="$MERGED/rompath;$ROMDIR"; fi
        mkdir -p "$_d/$leg"
        ( set +e; cd "$_d/$leg" && MAME_SANDBOX="$_d/$leg/sb" MAME_ROMPATH="$rp" REPLAY="$_d/air.rpl" POKES="$PK" \
            FIELDS="ff8406:b:seq,ff845c:b:frz,ff8806:b:p2seq,ff8807:b:p2sub,ff8854:b:p2cls,ff885c:b:p2frz,ff8850:w:p2hp,ff8814:w:p2y,ff8782:b:id,ff8b82:b:p2id" \
            FIELD_OUT="$_d/$leg.ft" FIELD_FROM=3395 FIELD_TO=3620 FRAMES=3620 \
            "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/$leg/mame.log" 2>&1; rm -rf "$_d/$leg/sb" ) </dev/null &
    done
    wait
    for leg in native merged; do [ -s "$_d/$leg.ft" ] || bad "$leg (P2 up at $_j): no samples"; done
}
# rows <dir>: the per-leg step rows from <dir>/{native,merged}.ft to <dir>/rows.tsv
rows() {
python3 - "$1" > "$1/rows.tsv" 2> "$1/err" <<'PY' || bad "rows: $(cat "$1/err")"
import sys
W = sys.argv[1]
def load(p):
    d = {}
    for l in open(p):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
    return d
def steps(d, k): return ",".join("%d:%d" % (f, d[f][k]) for f in sorted(d) if f - 1 in d and d[f][k] != d[f - 1][k])
for leg in ("native", "merged"):
    d = load(f"{W}/{leg}.ft")
    if 3395 not in d or max(d) < 3619: sys.exit(f"VOID: {leg} trace incomplete")
    if (d[3400]["id"], d[3400]["p2id"]) != (0x10, 0x03): sys.exit(f"VOID: {leg} ids at 3400 read {d[3400]['id']:#x}/{d[3400]['p2id']:#x}, not Phobos/Victor")
    hits = [f for f in range(3396, 3620) if d[f]["p2hp"] < d[f - 1]["p2hp"]]
    if not hits: sys.exit(f"VOID: {leg} the dome never connected")
    GROUND = 40   # the fighters' y on the ground (engine_internals.md); airborne is y > 40
    air = [f for f in range(3396, 3620) if d[f]["p2y"] > GROUND]
    apex = max(d[f]["p2y"] for f in range(3396, 3620))
    span = f"{air[0]}..{air[-1]}" if air else "none"
    landing = (air[-1] + 1) if air else 0
    print(f"air\t{leg}\thits={','.join(map(str, hits))}\ty_at_hit={d[hits[0]]['p2y']}\ty_before={d[hits[0] - 1]['p2y']}\tapex={apex}\tairborne={span}\tlanding={landing}\tcls={steps(d, 'p2cls')}\tp2frz={steps(d, 'p2frz')}\tp2sub={steps(d, 'p2sub')}\tp2hp={steps(d, 'p2hp')}\tp1frz={steps(d, 'frz')}")
PY
}
# jump_took <rows.tsv> <label>: on every row the jump TOOK (apex > 40) and the first hit is ON the landing frame (y > 40 the frame before, 40 at the hit, hit == landing)
jump_took() {
    python3 - "$1" <<'PY'
import sys, re
ok = True
for l in open(sys.argv[1]):
    if not l.startswith("air\t"): continue
    f = dict(kv.split("=", 1) for kv in l.rstrip("\n").split("\t")[2:])
    hit = int(f["hits"].split(",")[0])
    if int(f["apex"]) <= 40 or f["airborne"] == "none": ok = False; print(f"    the jump never took ({l.split(chr(9))[1]}: apex {f['apex']}, airborne {f['airborne']})")
    elif not (int(f["y_before"]) > 40 and int(f["y_at_hit"]) == 40 and hit == int(f["landing"])): ok = False; print(f"    the hit is not on the landing frame ({l.split(chr(9))[1]}: hit {hit}, landing {f['landing']}, y {f['y_before']} -> {f['y_at_hit']})")
sys.exit(0 if ok else 1)
PY
}
# same_but_marker <dir> <label>: the two legs equal in every field but the class marker (0x52 native = 82, 0x38 merged = 56), on the ground path
same_but_marker() {
    sed 's/^/  /' "$1/rows.tsv" | cut -c1-200
    _n="$(awk -F'\t' '$2=="native" {sub(/^air\tnative\t/, ""); print}' "$1/rows.tsv" | sed 's/:82,/:56,/g')"
    _m="$(awk -F'\t' '$2=="merged" {sub(/^air\tmerged\t/, ""); print}' "$1/rows.tsv")"
    [ -n "$_n" ] && [ "$_n" = "$_m" ] && ok "$2: the merged leg equals native's frame for frame in hits, height, freeze, sub-state, HP and Phobos's freeze (the class 0x52 native / 0x38 merged, the ruled marker)" || bad "$2: the merged leg differs from native's beyond the class marker"
    grep -q '	cls=[0-9]*:56,' "$1/rows.tsv" && grep -q '	p2sub=.*:4,' "$1/rows.tsv" && ok "$2: the dome takes the GROUND shock path (marker 0x38, sub-state 4) — not the air stager's 7" || bad "$2: the merged leg's class/sub-state are not the ground shock's"
    jump_took "$1/rows.tsv" && ok "$2: the jump TOOK (apex > 40) on both legs and the dome hit ON the landing frame — never in the air" || bad "$2: the victim did not jump over the dome, or the hit is not on the landing frame"
}
echo "== 1. the two legs (the trap rig, P2 up at $JUMP)"
legs "$W" "$JUMP"
[ $fail = 0 ] || { echo "FAIL: audit_trap_airborne (a leg did not run)"; exit 1; }
echo "== 2. the rows"
rows "$W"
same_but_marker "$W" "P2 up at $JUMP"
if [ "${SWEEP:-0}" = 1 ]; then
    echo "== 2b. SWEEP: the five other jump timings ($SWEEP_JUMPS) whose jump lands on the active dome, each pair asserted, none frozen"
    for _j in $SWEEP_JUMPS; do
        legs "$W/j$_j" "$_j"; [ -s "$W/j$_j/native.ft" ] && [ -s "$W/j$_j/merged.ft" ] || continue
        rows "$W/j$_j"; same_but_marker "$W/j$_j" "P2 up at $_j"
    done
fi
# THE PERTURBATIONS: (1) the merged leg's class steps rewritten to the air stager's 7; (2) the merged leg's jump erased
sed -E '/^air\tmerged\t/ s/cls=([0-9]*):56/cls=\1:7/' "$W/rows.tsv" > "$W/rows_pert.tsv"
python3 - "$W/rows.tsv" "$W/rows_ground.tsv" <<'PY'
import sys, re
out = []
for l in open(sys.argv[1]):
    if l.startswith("air\tmerged\t"):
        f = l.rstrip("\n").split("\t"); d = dict(kv.split("=", 1) for kv in f[2:])
        hit = int(d["hits"].split(",")[0]) - 2
        d["hits"] = str(hit); d["y_before"] = "40"; d["apex"] = "40"; d["airborne"] = "none"; d["landing"] = "0"
        l = "\t".join(f[:2] + [f"{k}={v}" for k, v in d.items()]) + "\n"
    out.append(l)
open(sys.argv[2], "w").write("".join(out))
PY
if jump_took "$W/rows_ground.tsv" > /dev/null; then vs_ctl_dead grounded-hit "the merged rows with the jump erased still pass the landing-frame check"; fail=1
else vs_ctl_fired grounded-hit "the merged rows with the jump erased (apex 40, no airborne span, the hit before the landing) fail the landing-frame check"; fi
# (3) the merged leg's first hit moved INSIDE the airborne span: the jump stands, the landing-frame clause alone must refuse it
python3 - "$W/rows.tsv" "$W/rows_airhit.tsv" <<'PY'
import sys
out = []
for l in open(sys.argv[1]):
    if l.startswith("air\tmerged\t"):
        f = l.rstrip("\n").split("\t"); d = dict(kv.split("=", 1) for kv in f[2:])
        first = int(d["airborne"].split("..")[0]) if d["airborne"] != "none" else int(d["hits"].split(",")[0])
        d["hits"] = str(first + 10); d["y_before"] = "95"; d["y_at_hit"] = "100"
        l = "\t".join(f[:2] + [f"{k}={v}" for k, v in d.items()]) + "\n"
    out.append(l)
open(sys.argv[2], "w").write("".join(out))
PY
if jump_took "$W/rows_airhit.tsv" > /dev/null; then vs_ctl_dead air-hit "the merged rows with the hit moved into the airborne span still pass the landing-frame check"; fail=1
else vs_ctl_fired air-hit "the merged rows with the hit moved into the airborne span (y 95 -> 100, ten frames after take-off) fail the landing-frame clause"; fi
vs_ctl_is air-class && { cp "$W/rows_pert.tsv" "$W/rows.tsv"; echo "MODE: air-class — the merged leg's class rewritten to 7"; }
vs_ctl_is grounded-hit && { cp "$W/rows_ground.tsv" "$W/rows.tsv"; echo "MODE: grounded-hit — the merged leg's jump erased"; jump_took "$W/rows.tsv" && ok "the jump took" || bad "the merged rows with the jump erased fail the landing-frame check"; }
vs_ctl_is air-hit && { cp "$W/rows_airhit.tsv" "$W/rows.tsv"; echo "MODE: air-hit — the merged leg's hit moved into the airborne span"; jump_took "$W/rows.tsv" && ok "the hit is on the landing frame" || bad "the merged rows with the hit in the air fail the landing-frame clause"; }
if [ "${FREEZE:-0}" = 1 ]; then
    [ $fail = 0 ] || { echo "REFUSED FREEZE: a check above is red"; echo "FAIL: audit_trap_airborne"; exit 1; }
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED FREEZE: under a control mode"; exit 1; }
    { echo "# tests/expected/trap_airborne.tsv — the Plasma Trap dome on a JUMPING Victor, native vsav2 vs the merged build"
      echo "# ($(basename "$MERGED")): the steps of the victim's class, freeze, sub-state and HP and Phobos's freeze from f3395, P2 up at $JUMP; the jump's apex, airborne span and landing frame (the ground is y = 40)"
      echo "# (tests/audit_trap_airborne.sh). Evidence class: in-emulator. Frozen 14z-181 with FREEZE=1 (GitHub #163's airborne item)."
      echo "#--"; cat "$W/rows.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if cmp -s "$W/want.tsv" "$W/rows.tsv"; then ok "every row as frozen"; else bad "differs from the frozen rows"; diff "$W/want.tsv" "$W/rows.tsv" | cut -c1-160 | sed 's/^/        /'; fi
if [ -z "${VS_CTL:-}" ]; then
    if cmp -s "$W/want.tsv" "$W/rows_pert.tsv"; then vs_ctl_dead air-class "the merged rows with the air stager's class still match the frozen rows"; fail=1
    else vs_ctl_fired air-class "the merged rows with the air stager's class 7 in place of the marker differ from the frozen rows"; fi
fi
if [ -n "${VS_CTL:-}" ]; then [ $fail = 0 ] && { echo "PASS (the control mode did NOT reach FAIL)"; exit 0; } || { echo "FAIL: audit_trap_airborne (control mode)"; exit 1; }; fi
[ $fail = 0 ] && echo "PASS: audit_trap_airborne" || echo "FAIL: audit_trap_airborne"
exit $fail
