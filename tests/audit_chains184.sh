#!/bin/sh
# audit_chains184.sh — THE TENANTS' ONCE NEVER-ENTERED a2 CHAINS WITH NO ATTACK RECORD, ENTERED ON NATIVE AND COMPARED WITH OURS (GitHub #184, 14z-186).
#
# WHAT: the ten of #184's 31 never-entered a2 seqs that a focused native rig enters — Donovan a2:0x2b (Killshread
#   Surf/Dive's blocked rebound), 0x3d (Change Immortal's miss, Up held), 0x42 (Sword Grapple's whiff), 0x4d (a normal
#   Foot Stab connecting off Sword Grapple), 0x59 (the Start-button taunt); Phobos a2:0x3d/0x3e (Sitting Attack
#   connecting off a sweep), 0x4f (Circuit Scrapper's whiff), 0x53 (his taunt); Pyron a2:0x1f (his taunt and Planet
#   Burning's whiff) — each rig first proven to ENTER its chain on native vs2, then compared ours against native event
#   by event. The other 21 are answered in docs/game/engine_internals.md (#184's paragraphs): replaced by design, the
#   passage of another chain, inside audit_chains174's windows, or no vs2 code path found.
# HOW: the rigs are tools/chains184_rigs.py's (tools/name_moves.py's machinery, kept OUTSIDE the naming corpus in
#   tests/replays/chains184/, as #174's); each tenant's rig on MAME on native vs2 and on the merged WIDE build as the
#   parity gate runs them (real cursor picks, level 6 from 2000, the RNG from the match anchor); the ENTRY read from a
#   third, native-only leg — a non-debug write tap (tests/lua/tap_writes.lua) on P1's node field +0x1C, a write from
#   vs2's chain-start instruction PRG:0x02713C counting as a START only when the node before it is not that node's
#   predecessor in any chain (tools/chains184_rigs.py entry): landing on a start node is NOT entering it (the 14z-185b
#   miscount of Pyron's a2:0x49, the tail of j.LP; Donovan's a2:0x3d is a2:0x3c minus its first node); the traces
#   compared per event by tools/move_parity.py. The tap leg and the traced native leg are SEPARATE runs, so the gate
#   first proves they played identically (tools/chains184_rigs.py agree: every node change the native trace samples is a
#   tap write of that node on that frame, and the tap run reached its END line — its MAME teardown segfault is not a
#   failure, a missing END is) — rule-checker run 2026-09-30-468.
# EXPECTS: the committed rigs equal a regeneration; the tap run agrees with the traced native run; every event's OUTCOME
#   holds on native — P2's HP falls, or never falls, from the event's first target chain on (tools/chains184_rigs.py
#   OUTCOME, P2's HP words +0x50 and +0x52 both read: the hit and contact events DAMAGE, the blocks, misses, whiffs and
#   taunts do not) — so a whiff cannot pass for the hit control (rule-checker run 2026-09-30-469); every event's TARGET — an ORDERED list of starts, `!chain` a start
#   that must NOT happen (the two separating controls: a HIT surf does not rebound, a Down-held Change Immortal contacts)
#   — holds on native; the per-event rows equal tests/expected/chains184.tsv; every control fails.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/chains184.tsv tests/lib/controls.sh tests/lua/field_trace.lua
#   tests/lua/tap_writes.lua tests/replays/chains184/ tools/anim_nodes.py tools/build_fingerprint.py
#   tools/chains184_rigs.py tools/move_parity.py tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: wrong-target — the entry check with every event's target replaced by a chain no rig starts (a2:0x7f) must report MISSING for every event, so "enters its target" is something the check can refuse (in-gate: every tenant; mode: the targets replaced and the gate FAILs)
# MUST-FIRE: perturbed-copy: order-swapped — the entry check with every multi-chain target REVERSED must report every such event MISSING, so the check reads the ORDER of the starts, not only their presence (in-gate: every tenant; mode: reversed and the gate FAILs)
# MUST-FIRE: perturbed-copy: passage-counted — the entry check with its predecessor filter OFF (every write of a start node counted as a start) must fail the Down-held Change Immortal control, whose walk through a2:0x3c's second node — a2:0x3d's start — is then read as a2:0x3d, so the filter that tells entry from passage is proven live (in-gate: donovan; mode: filter off on every tenant and the gate FAILs)
# MUST-FIRE: perturbed-copy: tap-shifted — the agreement check reading the tap's frames three frames late must match no node change, so "the tap run played what the trace sampled" is something the check can refuse (in-gate: every tenant; mode: every tenant's tap shifted and the gate FAILs) — added 14z-186 on rule-checker run 2026-09-30-468 Q1
# MUST-FIRE: perturbed-copy: outcome-flipped — the outcome check with every expectation inverted must report every event WRONG, so "the hit hit and the whiff whiffed" is something the check can refuse (in-gate: every tenant; mode: inverted and the gate FAILs) — added 14z-186 on rule-checker run 2026-09-30-469 Q4
# MUST-FIRE: perturbed-copy: node-moved — a copy of OUR trace with the node moved by one node (+0x18) on ONE frame two frames after the event's LAST target chain starts must turn every event DIFF on node, so an IDENT row is proven to rest on the compared chain path INSIDE the target chain, not in its lead-in (in-gate: every tenant; mode: every tenant's ours trace perturbed and the table FAILs) — added 14z-186 on rule-checker run 2026-09-30-468 Q4, moved into the target chain on run -469 Q4
# MUST-FIRE: perturbed-copy: x-moved — a copy of OUR trace with x moved by +3 on ONE frame two frames after the event's LAST target chain starts must turn every event DIFF on x, so an IDENT row is proven to rest on the compared x path inside the target chain (in-gate: every tenant; mode: every tenant's ours trace perturbed, and the table FAILs)
#
# NOT COVERED: every entry and verdict holds at the parity gates' pins only — the speed level 6 on every frame from 2000
#   and the RNG word $FF80D4 held at 0000 from 2363, on both legs (the ruled equalised input, STATE "Standing rulings";
#   0000 is the RNG's fixed point, every draw 0 — #183, kept as the basis 2026-09-30; with RNG_WORD=0100 the Sword
#   Grapple whiff at +8 no longer starts a2:0x41 on native, measured 14z-186 by audit_rng_forms);
#   [RESOLVED 14z-186, #193: tools/move_parity.py now compares both white HP words +0x52 as well — the rows were
#   re-frozen, only their excluded-sample counts moved; the gap it closed: Phobos's pursuit damages +0x52 only]
#   the 21 other seqs (see WHAT); P2 as the tenant; FBNeo; the chains' boxes and properties beyond what
#   tools/move_parity.py compares; the phase-sensitive grab whiffs at timings other than the rig's (Sword Grapple's
#   window is P2's jump input at +8/+9, Circuit Scrapper's +16/+17 in this rig, Planet Burning's +16 only — measured
#   14z-186; a schedule change moves them, the double-pass phase of GitHub #168).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged29] [DON=build/don_m25 HUI=build/hui59 PYR=build/pyron44] [FREEZE=1] [KEEP=<dir>] [RNG_WORD=0100] [RNG_UNTIL=2600] tests/audit_chains184.sh
#   RNG_WORD / RNG_UNTIL (#183, 14z-186): a PROBE knob, as audit_move_parity's; FREEZE=1 refuses either
#   emulator tier, MAME; ~3 min (9 legs in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
[ -n "${FREEZE:-}" ] && { [ -n "${RNG_WORD:-}" ] || [ -n "${RNG_UNTIL:-}" ]; } && { echo "REFUSED: FREEZE=1 with the RNG_WORD/RNG_UNTIL probe knob (#183) — the expectation is frozen at the 0000 pin only"; exit 3; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged29}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
DON="${DON:-build/don_m25}"; HUI="${HUI:-build/hui59}"; PYR="${PYR:-build/pyron44}"
EXPECT="$REPO/tests/expected/chains184.tsv"
RIGS="$REPO/tests/replays/chains184"
TENANTS="donovan huitzil pyron"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json at $BUILD"; exit 0; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"   # absolute: every leg cd's into its own directory before writing (a relative KEEP broke every leg)
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
# the parity gate's field list and ours cursor path (tests/audit_move_parity.sh, copied as audit_chains174 copies it)
FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff8410:w:x,ff8414:w:y,ff8450:w:p1hp,ff8782:b:id,ff802e:b:df,ff840b:b:face,ff8116:b:lvl,ff850a:w:meter,ff8850:w:p2hp,ff881c:l:p2node,ff8b82:b:p2id,ff8852:w:p2white,ff8452:w:p1white"   # both white HP words: compared by tools/move_parity.py since #193 (14z-186), P2's also read by the outcome check
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
extract_of() { case "$1" in donovan) echo "$DON/extract" ;; huitzil) echo "$HUI/extract" ;; pyron) echo "$PYR/extract" ;; esac; }

# the revision this run is: every log carries it, so a freeze, its modes and its verify are tied to one revision
# by their own output (rule-checker run 2026-09-30-470)
echo "revision: tests/audit_chains184.sh $(shasum "$REPO/tests/audit_chains184.sh" | cut -c1-40) tools/chains184_rigs.py $(shasum "$REPO/tools/chains184_rigs.py" | cut -c1-40) tests/expected/chains184.tsv $(shasum "$EXPECT" | cut -c1-40)"
echo "== 1. the committed rigs equal a regeneration"
for t in $TENANTS; do
    python3 tools/chains184_rigs.py gen "$t" "$W/$t.rpl" "$W/$t.json" > /dev/null || { bad "$t: gen"; continue; }
    if cmp -s "$W/$t.rpl" "$RIGS/${t}_c184.rpl" && cmp -s "$W/$t.json" "$RIGS/${t}_c184.json"; then ok "$t: rig as committed"
    else bad "$t: tests/replays/chains184/${t}_c184.* drifted from tools/chains184_rigs.py — regenerate"; fi
done
[ "$fail" = 0 ] || { echo "FAIL: audit_chains184"; exit 1; }

echo "== 2. the legs (native and ours traced, native tapped), and the chain graphs"
echo "  build under test: $BUILD — whole-set key $(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath;$ROMDIR" --set vsavjw --set-key 2>/dev/null | cut -c1-8)"
for t in $TENANTS; do
    ex="$(extract_of "$t")"; [ -f "$ex/regions.json" ] || { echo "SKIP: no $ex/regions.json"; exit 0; }
    mkdir -p "$W/chains_$t"
    python3 - "$ex" "$W/chains_$t" <<'PY' || { bad "$t: decode"; continue; }
import json, subprocess, sys
ex, w = sys.argv[1], sys.argv[2]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]),
                           "--table", hex(ptr["anim_index_" + name]), "--name", name, "--end", hex(r["src"] + r["len"]),
                           "--json", f"{w}/{name}.json"], stdout=subprocess.DEVNULL)
PY
    fr="$(python3 -c "import json;print(json.load(open('$RIGS/${t}_c184.json'))['frames'])")"
    base="$(python3 -c "import json;print(';'.join(json.load(open('$RIGS/${t}_c184.json'))['pokes']))")"
    pins="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)) + ';' + ';'.join(f'{f}:ff80d4:${RNG_WORD:-0000}' for f in range(2363,${RNG_UNTIL:-$fr})))")"
    eval "cur=\$OURS_PATH_$t"
    cp "$RIGS/${t}_c184.rpl" "$W/$t.native.rpl"
    awk -v p="$cur" '
        /^1104-1106 p2=R$/ && !done { n = split(p, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$RIGS/${t}_c184.rpl" > "$W/$t.ours.rpl"
    for leg in native ours; do
        if [ "$leg" = native ]; then set_=vsav2; rp="$ROMDIR"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; fi
        mkdir -p "$W/$t.$leg"
        ( cd "$W/$t.$leg" && MAME_SANDBOX="$W/$t.$leg/sb" MAME_ROMPATH="$rp" REPLAY="$W/$t.$leg.rpl" POKES="$base;$pins" \
            FIELDS="$FIELDS" FIELD_OUT="$W/tr_$t.$leg.txt" FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" \
            "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$t.$leg/mame.log" 2>&1
          rm -rf "$W/$t.$leg/sb" ) </dev/null &
    done
    mkdir -p "$W/$t.tap"
    ( cd "$W/$t.tap" && MAME_SANDBOX="$W/$t.tap/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$t.native.rpl" POKES="$base;$pins" \
        TAP="ff841c,4" WINDOW="2300,$fr" TRACE_OUT="$W/tap_$t.txt" FRAMES="$fr" \
        "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/tap_writes.lua" > "$W/$t.tap/mame.log" 2>&1
      rm -rf "$W/$t.tap/sb" ) </dev/null &
done
wait
for t in $TENANTS; do
    for leg in native ours; do command grep -q FIELDSUMMARY "$W/tr_$t.$leg.txt" 2>/dev/null || bad "$t $leg: no complete trace (see $t.$leg/mame.log)"; done
    nt="$(command grep -c ' PC 02713c ' "$W/tap_$t.txt" 2>/dev/null || true)"
    [ "${nt:-0}" -gt 0 ] || bad "$t: the tap recorded no write from the chain-start instruction (see $t.tap/mame.log)"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_chains184"; exit 1; }
# the tap run and the traced native run are SEPARATE runs: prove they played identically, and that the tap run finished
for t in $TENANTS; do
    fr="$(python3 -c "import json;print(json.load(open('$RIGS/${t}_c184.json'))['frames'])")"
    _sh=""; vs_ctl_is tap-shifted && _sh=shift
    if a="$(python3 tools/chains184_rigs.py agree "$W/tap_$t.txt" "$W/tr_$t.native.txt" "$fr" $_sh)"; then ok "$t: the tap run agrees with the traced native run ($a)"
    else bad "$t: the tap run and the traced native run disagree or the tap run did not finish ($a)"; fi
done
# every event's OUTCOME on native: P2's HP falls, or not, from its first target chain on (the hit hit, the whiff whiffed)
: > "$W/outcome.txt"
for t in $TENANTS; do
    _fl=""; vs_ctl_is outcome-flipped && _fl=flip
    python3 tools/chains184_rigs.py outcome "$t" "$W/tr_$t.native.txt" "$W/tap_$t.txt" "$W/chains_$t" "$RIGS/${t}_c184.json" $_fl >> "$W/outcome.txt" || true
done
on_="$(command grep -c '^outcome' "$W/outcome.txt" || true)"; ow="$(command grep -c '	WRONG' "$W/outcome.txt" || true)"
if [ "${on_:-0}" -gt 0 ] && [ "${ow:-0}" = 0 ]; then ok "every event's outcome holds on native ($on_ events: P2's HP falls exactly where a hit or contact is expected)"
else bad "${ow:-?} of ${on_:-?} event outcome(s) wrong on native:"; command grep '	WRONG' "$W/outcome.txt" | head -8 | sed 's/^/        /'; fi
[ "$fail" = 0 ] || { echo "FAIL: audit_chains184"; exit 1; }

entry() {  # entry <tenant> [wrong|swap|nofilter]
    python3 tools/chains184_rigs.py entry "$1" "$W/tap_$1.txt" "$W/chains_$1" "$RIGS/$1_c184.json" ${2:-} || true
}
tframes() {  # tframes <tenant> -> "<frame> ..." two frames after each event's LAST target chain starts (on the traced run)
    python3 tools/chains184_rigs.py target-frames "$1" "$W/tap_$1.txt" "$W/chains_$1" "$RIGS/$1_c184.json" | awk -F'\t' '$2 != "-" { printf "%d ", $2 + 2 }'
}
perturb_node() {  # perturb_node <tenant> <trace in> <trace out> — node +0x18 (one node) on the in-chain frame of every event
    python3 - "$(tframes "$1")" "$2" "$3" <<'PY'
import sys
at = {int(x) for x in sys.argv[1].split()}
with open(sys.argv[2]) as fi, open(sys.argv[3], "w") as fo:
    for line in fi:
        f = line.split()
        if len(f) >= 3 and f[0] == "F" and int(f[1]) in at:
            line = " ".join(("node=%d" % (int(v[5:]) + 0x18)) if v.startswith("node=") else v for v in f) + "\n"
        fo.write(line)
PY
}
perturb_x() {  # perturb_x <tenant> <trace in> <trace out> — x +3 on the in-chain frame of every event
    python3 - "$(tframes "$1")" "$2" "$3" <<'PY'
import sys
at = {int(x) for x in sys.argv[1].split()}
with open(sys.argv[2]) as fi, open(sys.argv[3], "w") as fo:
    for line in fi:
        f = line.split()
        if len(f) >= 3 and f[0] == "F" and int(f[1]) in at:
            line = " ".join(("x=%d" % (int(v[2:]) + 3)) if v.startswith("x=") else v for v in f) + "\n"
        fo.write(line)
PY
}
parity() {  # parity <tenant> <ours trace> -> the comparator's per-event rows
    fe="$(python3 -c "import json;print(json.load(open('$RIGS/$1_c184.json'))['events'][0]['frame'])")"
    python3 tools/move_parity.py events "$1" c184 "$W/tr_$1.native.txt" "$2" "$BUILD/patch/placements.json" \
        --first-event "$fe" --events "$RIGS/$1_c184.json" 2>/dev/null || true
}

echo "== 3. native enters every target, and ours vs native per event"
: > "$W/got.tsv"
for t in $TENANTS; do
    if vs_ctl_is wrong-target; then entry "$t" wrong >> "$W/got.tsv"
    elif vs_ctl_is order-swapped; then entry "$t" swap >> "$W/got.tsv"
    elif vs_ctl_is passage-counted; then entry "$t" nofilter >> "$W/got.tsv"
    else entry "$t" >> "$W/got.tsv"; fi
    ours="$W/tr_$t.ours.txt"
    if vs_ctl_is x-moved; then perturb_x "$t" "$ours" "$W/tr_$t.ours.pert.txt"; ours="$W/tr_$t.ours.pert.txt"; fi
    if vs_ctl_is node-moved; then perturb_node "$t" "$ours" "$W/tr_$t.ours.pert.txt"; ours="$W/tr_$t.ours.pert.txt"; fi
    parity "$t" "$ours" | sed 's/^/parity\t/' >> "$W/got.tsv"
done
sed 's/^/  | /' "$W/got.tsv"
n_ev="$(command grep -c '^entry' "$W/got.tsv" || true)"; n_miss="$(command grep -c '	MISSING' "$W/got.tsv" || true)"
if [ "$n_ev" -gt 0 ] && [ "$n_miss" = 0 ]; then ok "every event's target holds on native ($n_ev events, the two separating controls included)"
else bad "$n_miss of $n_ev event(s) do not hold their target on native"; fi
if [ "${FREEZE:-0}" = 1 ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: FREEZE=1 in control mode"; exit 3; }
    [ "$fail" = 0 ] || { echo "REFUSED: FREEZE=1 on a failing entry check"; exit 3; }
    { sed -n '/^#/p' "$EXPECT" 2>/dev/null; cat "$W/got.tsv"; } > "$W/new.tsv"
    command grep -q '^#' "$W/new.tsv" || { echo "REFUSED: $EXPECT has no header to keep"; exit 3; }
    mv "$W/new.tsv" "$EXPECT"; echo "FROZEN: $EXPECT ($(command grep -vc '^#' "$EXPECT") rows) — VERIFY by re-running without FREEZE"; exit 0
fi
command grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "$(wc -l < "$W/got.tsv" | tr -d ' ') rows as frozen"
else bad "rows differ from $(basename "$EXPECT"):"; sed 's/^/        /' "$W/diff.txt" | head -30; fi

echo "== 4. must-fire controls"
if vs_ctl_is wrong-target || vs_ctl_is order-swapped || vs_ctl_is passage-counted || vs_ctl_is x-moved || vs_ctl_is node-moved || vs_ctl_is tap-shifted || vs_ctl_is outcome-flipped; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the perturbed real input fails the gate"; echo "FAIL: audit_chains184 (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the perturbed real input still passed" || true; echo "FAIL: audit_chains184"; exit 1; fi
fi
: > "$W/ctl.tsv"; for t in $TENANTS; do entry "$t" wrong >> "$W/ctl.tsv"; done
wm="$(command grep -c '	MISSING' "$W/ctl.tsv" || true)"
if [ "$n_ev" -gt 0 ] && [ "$wm" = "$n_ev" ]; then vs_ctl_fired wrong-target "all $n_ev events read MISSING with their target replaced"
else vs_ctl_dead wrong-target "$wm of $n_ev events read MISSING with their target replaced" || fail=1; fi
on="$(awk -F'\t' '$1 == "entry" { n = 0; k = split($5, g, " "); for (i = 1; i <= k; i++) if (g[i] !~ /^!/) n++; if (n > 1) c++ } END { print c + 0 }' "$W/got.tsv")"
: > "$W/ctl.tsv"; for t in $TENANTS; do entry "$t" swap >> "$W/ctl.tsv"; done
om="$(awk -F'\t' '$1 == "entry" { n = 0; k = split($5, g, " "); for (i = 1; i <= k; i++) if (g[i] !~ /^!/) n++; if (n > 1 && $6 ~ /^MISSING/) c++ } END { print c + 0 }' "$W/ctl.tsv")"
if [ "$on" -gt 0 ] && [ "$om" = "$on" ]; then vs_ctl_fired order-swapped "all $on multi-chain events read MISSING with their target reversed"
else vs_ctl_dead order-swapped "$om of $on multi-chain events read MISSING with their target reversed" || fail=1; fi
entry donovan nofilter > "$W/ctl.tsv"
pm="$(awk -F'\t' '$4 ~ /^Change Immortal, Down held/ && $6 ~ /MISSING:.*!a2:0x3d/' "$W/ctl.tsv" | wc -l | tr -d ' ')"
if [ "$pm" = 1 ]; then vs_ctl_fired passage-counted "with the predecessor filter off, the Down-held Change Immortal control reads a false a2:0x3d start"
else vs_ctl_dead passage-counted "with the predecessor filter off, the Down-held control did not read a false a2:0x3d" || fail=1; fi
xd=0; xn=0
for t in $TENANTS; do
    perturb_x "$t" "$W/tr_$t.ours.txt" "$W/ctl.txt"
    xn=$((xn + $(python3 -c "import json;print(len(json.load(open('$RIGS/${t}_c184.json'))['events']))")))
    xd=$((xd + $(parity "$t" "$W/ctl.txt" | awk -F'\t' '$4 == "DIFF" && $6 ~ /(^|,)x(,|$)/' | wc -l | tr -d ' ')))
done
if [ "$xn" -gt 0 ] && [ "$xd" = "$xn" ]; then vs_ctl_fired x-moved "x moved on one frame of each of the $xn events turns every one DIFF on x"
else vs_ctl_dead x-moved "$xd of $xn events DIFF on x with x moved" || fail=1; fi
nd=0
for t in $TENANTS; do
    perturb_node "$t" "$W/tr_$t.ours.txt" "$W/ctl.txt"
    # a DIFF on node whose FIRST difference falls at or after the event's last target chain start: inside the chain
    python3 tools/chains184_rigs.py target-frames "$t" "$W/tap_$t.txt" "$W/chains_$t" "$RIGS/${t}_c184.json" > "$W/tf.txt"
    parity "$t" "$W/ctl.txt" > "$W/pn.txt"
    nd=$((nd + $(python3 - "$W/pn.txt" "$W/tf.txt" "$RIGS/${t}_c184.json" <<'PY'
import json, sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
tf = {int(l.split("\t")[0]): l.split("\t")[1] for l in open(sys.argv[2]) if l.strip()}
ev = json.load(open(sys.argv[3]))["events"]
n = 0
for r in rows:
    k = int(r[1])
    if r[3] == "DIFF" and "node" in r[5].split(",") and tf.get(k, "-") != "-" and int(r[4].lstrip("+")) >= int(tf[k]) - ev[k]["frame"]:
        n += 1
print(n)
PY
)))
done
if [ "$xn" -gt 0 ] && [ "$nd" = "$xn" ]; then vs_ctl_fired node-moved "ours' node moved by one node inside each event's target chain turns all $xn DIFF on node, each first difference at or after that chain's start"
else vs_ctl_dead node-moved "$nd of $xn events DIFF on node with the node moved" || fail=1; fi
fw=0
for t in $TENANTS; do
    fw=$((fw + $(python3 tools/chains184_rigs.py outcome "$t" "$W/tr_$t.native.txt" "$W/tap_$t.txt" "$W/chains_$t" "$RIGS/${t}_c184.json" flip | command grep -c '	WRONG' || true)))
done
if [ "$xn" -gt 0 ] && [ "$fw" = "$xn" ]; then vs_ctl_fired outcome-flipped "every one of the $xn events reads WRONG with its outcome inverted"
else vs_ctl_dead outcome-flipped "$fw of $xn events read WRONG with their outcome inverted" || fail=1; fi
sm=0
for t in $TENANTS; do
    fr="$(python3 -c "import json;print(json.load(open('$RIGS/${t}_c184.json'))['frames'])")"
    python3 tools/chains184_rigs.py agree "$W/tap_$t.txt" "$W/tr_$t.native.txt" "$fr" shift > /dev/null || sm=$((sm + 1))
done
if [ "$sm" = 3 ]; then vs_ctl_fired tap-shifted "every tenant's agreement check fails with the tap read three frames late"
else vs_ctl_dead tap-shifted "$sm of 3 tenants' agreement checks fail with the tap read three frames late" || fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_chains184 — every measured once never-entered a2 chain of #184 entered on native and compared with ours, as frozen"
else echo "FAIL: audit_chains184"; exit 1; fi
