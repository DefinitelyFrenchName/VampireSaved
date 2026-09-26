#!/bin/sh
# audit_victim_parity.sh — THE TENANT AS THE VICTIM, ours vs native (14z-181, GitHub #136): the `<tenant>_victim` rigs of tools/name_moves.py — Victor attacking the tenant with every contact class — run on BOTH legs as REAL cursor picks, and the victim's reaction per contact (class byte, freeze, chain path, frames back to a stand) compared through ONE decoder.
#
# WHAT: what the tenant DOES when hit, blocked or anti-aired, ours against native vs2, per
#   contact of the victim rigs: the class byte +0x54, the freeze +0x5C, the chain PATH the
#   reaction runs (table:seq@entry-node) and the frames until a stand chain returns — the
#   phase-3 reaction map (tests/test_reactions.sh) given its ours leg, frozen per contact.
# HOW: both legs on MAME as REAL cursor picks (P1 Victor, P2 the tenant, the routes decoded
#   from each game's own select wheel by tools/select_paths.py — no id poke on either leg),
#   the speed level pinned at 8 on both (vs2's TURBO, the level the victim rigs and
#   test_reactions' lines were measured at; our build's own is NORMAL 6 — matched modes,
#   ruled 2026-09-15) and the RNG at 0000, P2's HP re-pinned 10 frames before each event (never
#   inside a compared window: the reader refuses one); our P2 node pointers translated into
#   the native address space (placements.json) and both legs read by tools/reaction_map.py
#   over the tenant's vs2 extract (asserted byte-identical to the decrypted vsav2's anim region,
#   as our data view is to the decrypted romset; its a/a2/b/c chains asserted to decode to the
#   same shapes from our build); P1 asserted Victor on each leg and never inside one of his
#   REACTION chains whose data differs between the games (tools/audit_same_data_p2.py, run by
#   the gate on the two data views), and every row attributed (`attacker=`) to the differing
#   ATTACK chains of his that ran inside its event, and charged (`attributed=`) to the attacker
#   only when nothing but the timing (len, frz) differs AND the attacker's own shift explains it
#   (the contact and the return each on the same frame or his delta earlier, the freeze within
#   it) — a chain-path or class difference, or a timing difference of another size, is the
#   tenant's whatever ran beside it.
# EXPECTS: every contact row as frozen in tests/expected/victim_parity.tsv (SAME, or the
#   frozen DIFFER rows); the native leg reading test_reactions' frozen lines exactly; both ids
#   from each leg's trace; no schedule poke inside a compared window; the ten declared controls
#   failing (every MUST-FIRE line below has its in-gate fire and its mode). The contact FRAME is printed, not compared (#168).
# FOLLOWS: build/manifest/ emu/mame-patches/ tools/audit_same_data_p2.py
#   tests/expected/victim_parity.tsv tests/expected/reactions_ tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh tests/lib/measures.sh
#   tests/lua/field_trace.lua tests/replays/naming/ tools/anim_nodes.py tools/name_moves.py
#   tools/reaction_map.py tools/victim_parity.py tools/move_parity.py tools/select_paths.py
#   tools/select_wheel.py tools/cps2_decrypt.py tools/audit_same_data_p2.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: no-translation — our leg's contact lines decoded WITHOUT the placements translation (what a reader that took our node pointers for native addresses would read) must differ from the translated lines, so the translation is proven load-bearing and not a no-op (in-gate: the untranslated lines of the first part must differ; mode: every part is compared untranslated and the gate FAILs)
# MUST-FIRE: perturbed-copy: p1-planted — our first part's trace with one P1 node set to a Victor chain whose data differs between the games must be REFUSED by the P1 check, so "Victor never entered a differing chain" is an assertion that can fail (in-gate: the planted copy must fail p1check; mode: the plant is applied to the real trace and the gate FAILs)
# MUST-FIRE: perturbed-copy: pin-in-window — a schedule poke planted (in memory) one frame after the first contact of the first part must be refused by the pins check, so no compared window carries a rig write shared by both legs (the df_moves gotcha, 14z-181) (in-gate: the planted copy must be refused; mode: the plant is applied and the gate FAILs)
# MUST-FIRE: perturbed-copy: unpinned-level — the first part's OURS leg run WITHOUT the level pin (the build's own play-mode level, NORMAL 6; the RNG pin kept) must read contact lines that differ from the level-8 pinned ours, so the level pin both legs share is shown load-bearing rather than assumed (in-gate: the unpinned lines against the pinned; mode: our leg of that part is replaced by the unpinned one and the gate FAILs)
# MUST-FIRE: perturbed-copy: chains-planted — our data view with one valid chain's first node dur +1 (the first tenant) must be REFUSED by the chain-shape identity check, so "the tenant's chains decode to the same shapes on both builds" is a check that can fail (in-gate: the planted copy must fail chains-identical; mode: the planted view replaces the real one and the gate FAILs) — rule-checker run 2026-09-25-156 Q4
# MUST-FIRE: perturbed-copy: label-planted — the first part's ours lines with one chain label replaced by a walk-into-data seq must be flagged by the label check, so "every label is a compared chain" is shown live (in-gate: the planted lines must be flagged; mode: the planted lines replace the real ones and the gate FAILs) — rule-checker run 2026-09-25-156 Q4
# MUST-FIRE: perturbed-copy: tenant-planted — the first part's ours lines with one chain label changed on a line INSIDE an attacker-differing event must read that row `attributed=tenant` (or `attacker+tenant`), never the attacker's, so a victim-side difference is not absorbed by co-occurrence with the attacker's differing chain (in-gate: the planted copy's row must be charged to the tenant; mode: the planted lines replace the real ones and the table FAILs) — rule-checker run 2026-09-25-158 Q4
# MUST-FIRE: perturbed-copy: timing-planted — the first part's ours lines with one contact's length +3 on a line INSIDE an attacker-differing event must read that row `attributed=tenant`, so a timing difference the attacker's own one-frame shift cannot explain is not charged to him by co-occurrence (in-gate: the planted copy's row must be charged to the tenant; mode: the planted lines replace the real ones and the table FAILs) — rule-checker run 2026-09-25-159 Q4
# MUST-FIRE: perturbed-copy: extract-planted — a copy of the first tenant's vs2 extract with one bit flipped must be REFUSED against the decrypted vsav2, so "the extract both legs are labelled from is vs2's own bytes" is a check that can fail (in-gate: the flipped copy must be refused; mode: the flipped copy stands in for the extract in the check and the gate FAILs) — rule-checker run 2026-09-25-161 Q4
# MUST-FIRE: perturbed-copy: hit-dropped — our rows recomputed with the first part's first contact line removed (what a leg that lost a contact would read) must differ from the frozen rows, so the frozen rows are what the legs did (in-gate: the perturbed rows must differ from the frozen file; mode: our lines are dropped before the compare and the table FAILs)
# MEASURES: victim-parity-rows — 58 the ev rows of the frozen table (58 measured at the 14z-181 freeze: donovan parts 1-3 = 20, huitzil 1-2 = 19, pyron 1-2 = 19 contacts); an empty or shrunken table is what this floor refuses
#
# WHY. #136's 14z-164 census (GitHub #136, "Also found") listed the tenant AS VICTIM among
# the things "measured ours-vs-native nowhere": test_reactions.sh runs the native leg ONLY
# (our build supplies the extract the decoder reads, nothing more). The maintainer's ruling
# of 2026-09-17 (DECISIONS_HISTORY.md "Ruled 2026-09-17 (14z-164b)") asks for a P2 whose
# data is the same on both games; here the ATTACKER is the legacy character, and Victor's
# ATTACK chains (table a) are the same data on both games — his differing chains are his own
# b/c reaction sets (same_data_p2.tsv row 0x03), which the attacker never enters while the
# victim stays passive or blocking. Each leg's trace asserts exactly that. The picks are REAL
# on both legs (the #151 lesson: a poked pick carries the cursor cell's confirm-time latch),
# which is why the native leg is re-run rather than read from test_reactions' frozen file —
# and the re-run is ASSERTED against it: at level 8 the real-pick, per-event-pinned, RNG-pinned
# native leg reproduces test_reactions' frozen (poked-pick, every-400-pinned, unpinned) lines
# EXACTLY (measured 14z-181: 13/13 on donovan_victim 1 and pyron_victim 1, the level pinned at 8
# or absent alike), so the pick and the pins are shown to move nothing on these rigs; at level 6
# every line's length moved and Pyron's j.HP whiffed — the rigs were tuned at vs2's own 8, which
# is why this gate pins 8 where tests/audit_move_parity.sh pins 6 (both legs matched either way).
#
# WHAT IT FREEZES (tests/expected/victim_parity.tsv), measured 14z-181 on merged-m19: 58 contact
# rows, 41 SAME and 17 DIFFER in TWO families (the paths compared in FULL — a first form cut them
# at 8 labels and two of Pyron's throw rows read SAME with the release chain hidden behind the
# throw's eight `c:` labels; rule-checker run 2026-09-25-156 Q4). (1) The THROW, all three tenants: Victor's throw
# start a2:0x38 is one data frame shorter on vsavj (24 vs 25: its first node dur 1 vs 2 — his
# data, not ours), so five of the six throw hits land one frame earlier on our leg (the third, f4319,
# on the same frame) and the victim's release chains read `len` +1 / the last hit's freeze 11 for 10 —
# the TIMING differences of those rows are charged `attributed=attacker` (10 rows; a first form charged
# every row inside the throw by co-occurrence and absorbed Pyron's label difference — run 158 Q4 — and
# a second charged a timing difference of any size — run 159 Q4: now only a shift of his own delta,
# on the contact or on the return: Donovan's stand follows the release (4440/4439), Phobos's is a fixed
# length from the grab (4439 on both), both within the rule). The tenant's own a/a2/b/c chains decode to the SAME shapes from
# our build as from the vs2 extract (step 1's chains-identical), so a chain label means one thing on both legs.
# (2) PYRON ONLY, unattributed: on Victor's 5HP (class 0x04), j.HP (0x37) and the throw's
# release, native Pyron enters b:0x19 (a 4-node 12-frame loop) where ours enters the generic
# b:0x03 (12 nodes, 24 frames held) — class, freeze and length equal; the capture is the
# maintainer's (build/agent181/cap_victim_pyron_5hp.png, sent 2026-09-25). Pyron's seven throw
# rows (k=4-10) carry BOTH families: their `attacker=a2:0x38` explains the frame, the
# b:0x19/b:0x03 release label is family (2) — so family (2) is on 9 of Pyron's rows, 2 of them
# outside the throw. Tickets: family (2) is GitHub #173 (opened
# 14z-181); family (1) is Victor's data on the two games, not a ticket.
#
# WHAT IS NOT COVERED: P2's HP (the defense rows are ruled, docs/project/tables/defense_rows.md),
# the contact FRAME (printed), Victor's own reactions (the tenant never attacks here), and
# WHICH attack made the contact (the event name is the rig's, the class byte the engine's).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged28] [DON=build/don_m24 HUI=build/hui58 PYR=build/pyron43] [TENANTS="donovan pyron huitzil"] [FREEZE=1] [CONTROL=<name>] [GOT_OUT=<rows.tsv>] [KEEP=<dir>] tests/audit_victim_parity.sh
#   emulator tier, MAME: 15 legs, a tenant's legs in parallel (~2 min per tenant on this MacBook).
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged28}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
DON="${DON:-build/don_m24}"; HUI="${HUI:-build/hui58}"; PYR="${PYR:-build/pyron43}"
TENANTS="${TENANTS:-donovan pyron huitzil}"
EXPECT="$REPO/tests/expected/victim_parity.tsv"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/measures.sh"
. "$REPO/tests/lib/decrypt_cache.sh"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json at $BUILD"; exit 0; }
[ -f "$BUILD/verify_data.bin" ] || { echo "SKIP: no verify_data.bin at $BUILD"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
VP="python3 $REPO/tools/victim_parity.py"
FIELDS="ff841c:l:node,ff8782:b:id,ff8814:w:p2y,ff881c:l:p2node,ff8854:b:p2cls,ff8850:w:p2hp,ff8852:w:p2white,ff885c:b:p2frz,ff8b82:b:p2id"
FIRST_T="${TENANTS%% *}"   # the control legs run on the first part of the first tenant

echo "== 0. the two select wheels, the real routes, and Victor's differing-data chains"
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_da.bin" || { echo "FAIL: no vsav2 decrypt view"; exit 1; }
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || { echo "FAIL: no vsavj decrypt view"; exit 1; }
# THE ATTACKER'S DATA, per game: VS's Victor attacks on our leg, VS2's on the native one. The census names every
# chain of his whose data differs (a2: his throw start a2:0x38 among 18; b/c: his reaction sets), so p1check can
# refuse a hit attacker and compare() can attribute a row to the two Victors (14z-181, the throw family).
python3 tools/audit_same_data_p2.py "$W/vj_da.bin" "$W/v2_da.bin" --ids 03 --json "$W/victor_same.json" > "$W/same.log" 2>&1 || { echo "FAIL: the same-data census for Victor did not run: $(tail -1 "$W/same.log")"; exit 1; }
SAME="$W/victor_same.json"
# THE DATA VIEW IS THE ROMSET (rule-checker run 2026-09-25-158 Q1): the chain-shape check reads $BUILD/verify_data.bin
# while our leg runs $BUILD/rompath/vsavjw.zip — so the zip is decrypted here (~8 s) and its data view must be
# byte-identical to the file the check reads, or the premise "the shapes are the build's" is not measured
python3 tools/cps2_decrypt.py "$BUILD/rompath/vsavjw.zip" "$W/wide_op.bin" --data-out "$W/wide_da.bin" > "$W/decrypt.log" 2>&1 || { echo "FAIL: the build's romset did not decrypt: $(tail -1 "$W/decrypt.log")"; exit 1; }
if cmp -s "$W/wide_da.bin" "$BUILD/verify_data.bin"; then ok "the build's data view (verify_data.bin, $(wc -c < "$BUILD/verify_data.bin" | tr -d ' ') bytes) is byte-identical to the decrypted rompath/vsavjw.zip our leg runs"
else echo "FAIL: $BUILD/verify_data.bin is not the decrypted rompath/vsavjw.zip — the chain-shape check would read another build"; exit 1; fi
ok "Victor's differing-data chains (audit_same_data_p2 on the two data views): $(python3 -c "import json;d=json.load(open('$SAME'))['0x03']['anim_seqs_diff'];print(' '.join(f'{t}={len(v[\"differ\"])}' for t,v in d.items()))")"
python3 tools/select_wheel.py "$W/v2_da.bin" --set vsav2 --json "$W/wheel_native.json" > "$W/w1.log" 2>&1 || { echo "FAIL: vsav2 wheel"; exit 1; }
python3 tools/select_wheel.py "$BUILD/verify_data.bin" --set vsavj --json "$W/wheel_ours.json" > "$W/w2.log" 2>&1 || { echo "FAIL: our wheel"; exit 1; }
route() {  # route <leg> <player> <cell hex> -> the moves, space separated
    python3 tools/select_paths.py "$W/wheel_$1.json" --cell "$3" --player "$2" | sed 's/^.*: //'
}
P1_native="$(route native 1 03)"; P1_ours="$(route ours 1 03)"
[ -n "$P1_native" ] && [ -n "$P1_ours" ] && ok "P1 Victor (0x03): native '$P1_native', ours '$P1_ours'" || bad "no route to Victor's cell"

# leg_rpl <committed rpl> <p1 moves> <p2 moves> <out>: replay 17's prologue replaced by the real routes
leg_rpl() {
    python3 - "$1" "$2" "$3" "$4" <<'PY' || return 1
import sys
sys.path.insert(0, "tools")
import name_moves as nm
src = open(sys.argv[1]).read()
old = nm.REPLAY17_PROLOGUE
assert src.count(old) == 1, "the committed rig does not carry replay 17's prologue verbatim"
new = nm.prologue_for(sys.argv[2].split(), sys.argv[3].split())
open(sys.argv[4], "w").write(src.replace(old, new))
PY
}
# leg_pokes <schedule.json> <with level 1|0> <sched out> <all out>: the schedule's pokes WITHOUT
# the id pokes and WITHOUT the every-400 HP pins, PLUS one HP pin 10 frames before each event;
# then the level and RNG pins every frame (the parity gates' equalised input since 14z-158)
leg_pokes() {
    python3 - "$1" "$2" "$3" "$4" <<'PY' || return 1
import json, sys
j = json.load(open(sys.argv[1])); lvl = sys.argv[2] == "1"
ids = [p for p in j["pokes"] if p.split(":")[1] in ("ff8782", "ff8b82")]
hp = [p for p in j["pokes"] if p.split(":")[1] == "ff8850"]
rest = [p for p in j["pokes"] if p not in ids and p not in hp]
assert len(ids) == 6, "expected the six early-window id pokes, found %d" % len(ids)
assert len(hp) + len(ids) + len(rest) == len(j["pokes"])
sched = rest + ["%d:ff8850:01200120" % (e["frame"] - 10) for e in j["events"]]
fr = j["frames"]
pins = (["%d:ff8116:08" % f for f in range(2000, fr)] if lvl else []) + ["%d:ff80d4:0000" % f for f in range(2363, fr)]
open(sys.argv[3], "w").write(";".join(sched))
open(sys.argv[4], "w").write(";".join(sched + pins))
print("dropped %d id pokes and %d cadence HP pins; %d event HP pins; %d other; level pin %s; RNG pin on" % (len(ids), len(hp), len(j["events"]), len(rest), "on" if lvl else "OFF"))
PY
}
run_leg() {  # run_leg <tag> <set> <rompath> <rpl> <pokes file> <frames> <trace out>
    mkdir -p "$W/$1"
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$(cat "$5")" FIELDS="$FIELDS" \
        FIELD_OUT="$7" FIELD_FROM=2300 FIELD_TO="$6" FRAMES="$6" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      rm -rf "$W/$1/sb" ) </dev/null &
}

: > "$W/rows.tsv"; : > "$W/rows_dropped.tsv"; : > "$W/rows_raw.tsv"; : > "$W/poked.tsv"
for TENANT in $TENANTS; do
    case $TENANT in donovan) EX="$DON/extract"; ID=13;; huitzil) EX="$HUI/extract"; ID=10;; pyron) EX="$PYR/extract"; ID=11;; esac
    [ -f "$EX/regions.json" ] || { echo "SKIP: no $EX/regions.json"; exit 0; }
    # THE EXTRACT IS vs2's OWN BYTES (rule-checker run 2026-09-25-161 Q1/Q4): both legs are labelled from
    # $EX/region_anim.bin, so it must equal the decrypted vsav2's anim region byte for byte, or the labels
    # and the chain-shape identity would rest on bytes vs2 does not run
    EXREG="$EX/region_anim.bin"
    if [ "$TENANT" = "$FIRST_T" ]; then
        python3 - "$EX" "$W/extract_planted.bin" <<'PY' > "$W/extract_plant.log" 2>&1 || bad "extract-planted could not build its copy"
import sys, json
ex, out = sys.argv[1], sys.argv[2]
b = bytearray(open(f"{ex}/region_anim.bin", "rb").read()); i = len(b) // 2; b[i] ^= 0x01
open(out, "wb").write(bytes(b)); print("planted: one bit flipped at region offset %#x of the extract copy" % i)
PY
        if python3 - "$EX" "$W/extract_planted.bin" "$W/v2_da.bin" <<'PY'
import sys, json
ex, cand, v2 = sys.argv[1:4]; r = json.load(open(f"{ex}/regions.json"))["regions"]["anim"]
sys.exit(0 if open(cand, "rb").read() == open(v2, "rb").read()[r["src"]:r["src"] + r["len"]] else 1)
PY
        then vs_ctl_dead extract-planted "a bit flipped in a copy of the extract still equals the decrypted vsav2"; fail=1
        else vs_ctl_fired extract-planted "$(cat "$W/extract_plant.log") — refused against the decrypted vsav2"; fi
        if vs_ctl_is extract-planted; then EXREG="$W/extract_planted.bin"; echo "MODE: extract-planted — $(cat "$W/extract_plant.log")"; fi
    fi
    if python3 - "$EX" "$EXREG" "$W/v2_da.bin" <<'PY'
import sys, json
ex, cand, v2 = sys.argv[1:4]; r = json.load(open(f"{ex}/regions.json"))["regions"]["anim"]
e = open(cand, "rb").read(); v = open(v2, "rb").read()[r["src"]:r["src"] + r["len"]]
print("extract %d bytes at src %#x: %s" % (len(e), r["src"], "equal to the decrypted vsav2" if e == v else "DIFFERS from the decrypted vsav2"))
sys.exit(0 if e == v else 1)
PY
    then ok "the vs2 extract is vsav2's own bytes ($(python3 -c "import json;r=json.load(open('$EX/regions.json'))['regions']['anim'];print(r['len'])") bytes at src)"
    else bad "the vs2 extract $EXREG is not the decrypted vsav2's anim region — the labels would rest on other bytes"; fi
    V="${TENANT}_victim"
    PARTS="$(python3 -c "import sys; sys.path.insert(0,'tools'); import name_moves; print(' '.join(p for p in sorted(name_moves.SCHEDULES['$V'], key=int) if ('$V', p) not in name_moves.PHASE2_PARTS))")"
    [ "$TENANT" = donovan ] || PARTS="1 2"   # as test_reactions.sh: the anti-air part exists for Donovan only
    P2_native="$(route native 2 "$ID")"; P2_ours="$(route ours 2 "$ID")"
    echo "######## $TENANT (parts $PARTS) — P2 routes native '$P2_native', ours '$P2_ours'"
    fail0=$fail   # the hard stops below (rigs, legs) read THIS tenant's reds only
    [ -n "$P2_native" ] && [ -n "$P2_ours" ] || { bad "no route to cell 0x$ID"; continue; }
    echo "== 1. rigs equal a regeneration; chains decoded from $EX"
    for p in $PARTS; do
        python3 tools/name_moves.py gen "$V" "$p" "$W/r_$p.rpl" "$W/r_$p.json" > /dev/null || bad "gen $p"
        cmp -s "$W/r_$p.rpl" "tests/replays/naming/${V}_$p.rpl" && cmp -s "$W/r_$p.json" "tests/replays/naming/${V}_$p.json" || bad "part $p: tests/replays/naming/${V}_$p.* drifted — regenerate"
    done
    rm -rf "$W/chains"; mkdir -p "$W/chains"
    python3 - "$EX" "$W/chains" <<'PY' || bad "decode"
import json, subprocess, sys
ex, w = sys.argv[1], sys.argv[2]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]), "--table", hex(ptr["anim_index_" + name]),
                           "--name", name, "--end", hex(r["src"] + r["len"]), "--json", f"{w}/{name}.json"], stdout=subprocess.DEVNULL)
PY
    # THE PORTED-BYTES PREMISE, MEASURED (rule-checker run 2026-09-25-156 Q1): one decoder reads the vs2 extract for
    # both legs, so the tenant's chains must decode to the SAME SHAPES from our build — else a label means two things
    OURS_IMG="$BUILD/verify_data.bin"
    if [ "$TENANT" = "$FIRST_T" ]; then
        # the chains-planted control: our data view with one valid chain's first node dur +1 must be REFUSED
        $VP chains-plant "$EX" "$BUILD/verify_data.bin" "$BUILD/patch/placements.json" "$TENANT" "$W/planted_data.bin" > "$W/chains_plant.log" 2>&1 || bad "chains-plant could not build its copy: $(cat "$W/chains_plant.log")"
        if $VP chains-identical "$EX" "$W/planted_data.bin" "$BUILD/patch/placements.json" "$TENANT" > "$W/chains_planted.txt" 2>&1; then vs_ctl_dead chains-planted "a node dur changed in our data view still reads identical in shape"; fail=1
        else vs_ctl_fired chains-planted "$(cat "$W/chains_plant.log") — the identity check refuses it ($(grep -o '[0-9]* differ in shape: [^;]*' "$W/chains_planted.txt" | head -1))"; fi
        if vs_ctl_is chains-planted; then OURS_IMG="$W/planted_data.bin"; echo "MODE: chains-planted — $(cat "$W/chains_plant.log")"; fi
    fi
    if $VP chains-identical "$EX" "$OURS_IMG" "$BUILD/patch/placements.json" "$TENANT" > "$W/chains_$TENANT.txt" 2>&1; then ok "chains identical in shape on our build and the vs2 extract: $(tr '\n' ';' < "$W/chains_$TENANT.txt")"
    else bad "the tenant's chains differ in shape between our build and the vs2 extract: $(tr '\n' ';' < "$W/chains_$TENANT.txt")"; fi
    [ "$fail" = "$fail0" ] || { echo "FAIL: audit_victim_parity ($TENANT: rigs)"; exit 1; }
    echo "== 2. the legs (real picks, level + RNG pinned, one HP pin per event)"
    for p in $PARTS; do
        J="$W/r_$p.json"; FR="$(python3 -c "import json;print(json.load(open('$J'))['frames'])")"
        leg_rpl "$W/r_$p.rpl" "$P1_native" "$P2_native" "$W/${TENANT}_$p.native.rpl" || bad "native rpl $p"
        leg_rpl "$W/r_$p.rpl" "$P1_ours" "$P2_ours" "$W/${TENANT}_$p.ours.rpl" || bad "ours rpl $p"
        leg_pokes "$J" 1 "$W/${TENANT}_$p.sched.pokes" "$W/${TENANT}_$p.pokes" > "$W/${TENANT}_$p.pokes.log" || bad "pokes $p"
        run_leg "${TENANT}_$p.native" vsav2 "$ROMDIR" "$W/${TENANT}_$p.native.rpl" "$W/${TENANT}_$p.pokes" "$FR" "$W/${TENANT}_$p.native.ft"
        run_leg "${TENANT}_$p.ours" vsavjw "$BUILD/rompath;$ROMDIR" "$W/${TENANT}_$p.ours.rpl" "$W/${TENANT}_$p.pokes" "$FR" "$W/${TENANT}_$p.ours.ft"
        if [ "$TENANT" = "$FIRST_T" ] && [ "$p" = "${PARTS%% *}" ]; then
            leg_pokes "$J" 0 "$W/unpinned.sched.pokes" "$W/unpinned.pokes" > "$W/unpinned.pokes.log" || bad "unpinned pokes"
            run_leg "unpinned.ours" vsavjw "$BUILD/rompath;$ROMDIR" "$W/${TENANT}_$p.ours.rpl" "$W/unpinned.pokes" "$FR" "$W/unpinned.ours.ft"
            UP_PART="$p"
        fi
    done
    wait
    sed -n 1p "$W/${TENANT}_${PARTS%% *}.pokes.log" | sed 's/^/  pokes: /'
    for p in $PARTS; do for leg in native ours; do
        [ -s "$W/${TENANT}_$p.$leg.ft" ] || bad "part $p $leg: no samples ($W/${TENANT}_$p.$leg/mame.log)"
    done; done
    [ "$fail" = "$fail0" ] || { echo "FAIL: audit_victim_parity ($TENANT: a leg did not run)"; exit 1; }
    echo "== 3. identity and the attacker's chains, per leg"
    for p in $PARTS; do for leg in native ours; do
        if [ $leg = native ]; then img="$W/v2_da.bin"; lay=vsav2; else img="$BUILD/verify_data.bin"; lay=vsavj; fi
        T="$W/${TENANT}_$p.$leg.ft"
        if [ "$leg" = ours ] && vs_ctl_is p1-planted && [ "$TENANT" = "$FIRST_T" ] && [ "$p" = "${PARTS%% *}" ]; then
            $VP plant-p1 "$T" "$img" "$lay" "$W/planted.ft" --same "$SAME" > "$W/plant.log" && T="$W/planted.ft"; echo "MODE: p1-planted — $(cat "$W/plant.log")"
        fi
        if $VP p1check "$T" "$img" "$lay" "$ID" --same "$SAME" --from 2300 > "$W/p1_${p}_$leg.txt" 2>&1; then ok "part $p $leg: $(sed -n 1p "$W/p1_${p}_$leg.txt"); differing attack chains run: $(grep -c '^P1DIFF' "$W/p1_${p}_$leg.txt" | tr -d ' ') span(s) $(grep '^P1DIFF' "$W/p1_${p}_$leg.txt" | cut -d' ' -f2- | tr '\n' ' ')"
        else bad "part $p $leg: $(grep FAIL "$W/p1_${p}_$leg.txt" | head -2 | tr '\n' ' ')"; fi
    done; done
    if [ "$TENANT" = "$FIRST_T" ]; then
        p="${PARTS%% *}"
        $VP plant-p1 "$W/${TENANT}_$p.ours.ft" "$BUILD/verify_data.bin" vsavj "$W/planted_ctl.ft" --same "$SAME" > "$W/plant_ctl.log" || bad "plant-p1 control could not be built"
        if $VP p1check "$W/planted_ctl.ft" "$BUILD/verify_data.bin" vsavj "$ID" --same "$SAME" --from 2300 > "$W/p1_planted.txt" 2>&1; then vs_ctl_dead p1-planted "a P1 node planted in a differing Victor reaction chain passed the P1 check"; fail=1
        else vs_ctl_fired p1-planted "$(cat "$W/plant_ctl.log"); the P1 check refuses it"; fi
    fi
    echo "== 4. the contact lines, our node pointers translated"
    for p in $PARTS; do
        $VP translate "$W/${TENANT}_$p.ours.ft" "$BUILD/patch/placements.json" "$TENANT" "$W/${TENANT}_$p.ours.tr.ft" > "$W/tr_$p.log" || bad "translate $p"
        $VP contacts "$W/r_$p.json" "$W/${TENANT}_$p.native.ft" "$W/chains" > "$W/${TENANT}_$p.native.lines" || bad "contacts native $p"
        $VP contacts "$W/r_$p.json" "$W/${TENANT}_$p.ours.tr.ft" "$W/chains" > "$W/${TENANT}_$p.ours.lines" || bad "contacts ours $p"
        $VP contacts "$W/r_$p.json" "$W/${TENANT}_$p.ours.ft" "$W/chains" > "$W/${TENANT}_$p.ours.raw.lines" || bad "contacts ours raw $p"
        ok "part $p: $(cat "$W/tr_$p.log"); native $(grep -c . "$W/${TENANT}_$p.native.lines") contacts, ours $(grep -c . "$W/${TENANT}_$p.ours.lines")"
        if [ "$TENANT" = "$FIRST_T" ] && [ "$p" = "${PARTS%% *}" ]; then
            if cmp -s "$W/${TENANT}_$p.ours.lines" "$W/${TENANT}_$p.ours.raw.lines"; then vs_ctl_dead no-translation "the untranslated lines equal the translated ones — the translation is a no-op here"; fail=1
            else vs_ctl_fired no-translation "part $p untranslated reads $(diff "$W/${TENANT}_$p.ours.lines" "$W/${TENANT}_$p.ours.raw.lines" | grep -c '^>') line(s) differently (OFF: nodes)"; fi
        fi
        if vs_ctl_is no-translation; then cp "$W/${TENANT}_$p.ours.raw.lines" "$W/${TENANT}_$p.ours.lines"; echo "MODE: no-translation — part $p compared on the untranslated lines"; fi
    done
    # every label the legs' lines carry must be a COMPARED chain, never a walk into data — else the identity check
    # above would not cover the chains this tenant's rows rest on
    label_check() {  # label_check <lines file> -> the FAIL lines (empty = clean)
        grep -o '[abc]2\?:0x[0-9a-f]*' "$1" | sort -u | while read -r lab; do
            tab="${lab%%:*}"; seq="${lab#*:}"
            if grep "^NOTCHAIN $tab " "$W/chains_$TENANT.txt" | tr ' ' '\n' | grep -qx "$seq"; then echo "  FAIL  $(basename "$1"): label $lab is a walk into data, not a compared chain"; fi
        done
    }
    if [ "$TENANT" = "$FIRST_T" ]; then
        # the label-planted control: a copy of the first part's ours lines with one label replaced by a walk-into-data
        # seq (the first NOTCHAIN entry) must be flagged by the label check
        nc="$(grep '^NOTCHAIN' "$W/chains_$TENANT.txt" | head -1 | awk '{print $2 ":" $3}')"
        p="${PARTS%% *}"; first_lab="$(grep -o '[abc]2\?:0x[0-9a-f]*' "$W/${TENANT}_$p.ours.lines" | head -1)"
        sed "s/$first_lab/$nc/" "$W/${TENANT}_$p.ours.lines" > "$W/label_planted.lines"
        if [ -n "$nc" ] && [ -n "$(label_check "$W/label_planted.lines")" ]; then vs_ctl_fired label-planted "a line's $first_lab replaced by the walk-into-data $nc is flagged"
        else vs_ctl_dead label-planted "a walk-into-data label planted in the lines passed the label check (nc='$nc')"; fail=1; fi
        if vs_ctl_is label-planted; then cp "$W/label_planted.lines" "$W/${TENANT}_$p.ours.lines"; echo "MODE: label-planted — part $p's ours lines carry $nc for $first_lab"; fi
    fi
    for p in $PARTS; do for leg in native ours; do label_check "$W/${TENANT}_$p.$leg.lines"; done; done > "$W/labels_$TENANT.txt"
    if [ -s "$W/labels_$TENANT.txt" ]; then cat "$W/labels_$TENANT.txt"; fail=1; else ok "every chain label of the lines is a compared chain ($(grep -oh '[abc]2\?:0x[0-9a-f]*' "$W"/${TENANT}_*.lines | sort -u | wc -l | tr -d ' ') distinct)"; fi
    echo "== 5. no schedule poke inside a compared window"
    for p in $PARTS; do for leg in native ours; do
        PK="$W/${TENANT}_$p.sched.pokes"
        if vs_ctl_is pin-in-window && [ "$TENANT" = "$FIRST_T" ] && [ "$p" = "${PARTS%% *}" ] && [ $leg = native ]; then
            f1="$(sed -n 1p "$W/${TENANT}_$p.native.lines" | awk -F'\t' '{print substr($7,2)}')"; printf '%s;%d:ff8850:01200120' "$(cat "$PK")" "$((f1 + 1))" > "$W/planted.pokes"; PK="$W/planted.pokes"; echo "MODE: pin-in-window — an HP pin planted at f$((f1 + 1))"
        fi
        if $VP pinscheck "$PK" "$W/${TENANT}_$p.$leg.lines" > "$W/pins_${p}_$leg.txt"; then ok "part $p $leg: $(sed -n 1p "$W/pins_${p}_$leg.txt")"
        else bad "part $p $leg: $(grep FAIL "$W/pins_${p}_$leg.txt" | head -3 | tr '\n' ' ')"; fi
    done; done
    if [ "$TENANT" = "$FIRST_T" ]; then
        p="${PARTS%% *}"; f1="$(sed -n 1p "$W/${TENANT}_$p.native.lines" | awk -F'\t' '{print substr($7,2)}')"
        printf '%s;%d:ff8850:01200120' "$(cat "$W/${TENANT}_$p.sched.pokes")" "$((f1 + 1))" > "$W/planted_ctl.pokes"
        if $VP pinscheck "$W/planted_ctl.pokes" "$W/${TENANT}_$p.native.lines" > "$W/pins_planted.txt"; then vs_ctl_dead pin-in-window "an HP pin planted at f$((f1 + 1)), inside the first contact window, passed the pins check"; fail=1
        else vs_ctl_fired pin-in-window "an HP pin planted at f$((f1 + 1)), inside the first contact window, is refused"; fi
    fi
    echo "== 6. the rows, and the real-pick native leg against test_reactions' frozen (poked, level-8) lines"
    if [ "$TENANT" = "$FIRST_T" ]; then
        p="$UP_PART"
        $VP translate "$W/unpinned.ours.ft" "$BUILD/patch/placements.json" "$TENANT" "$W/unpinned.ours.tr.ft" > /dev/null || bad "translate unpinned"
        $VP contacts "$W/r_$p.json" "$W/unpinned.ours.tr.ft" "$W/chains" > "$W/unpinned.lines" || bad "contacts unpinned"
        # POSIX sh: no process substitution — strip the frames into files first
        sed -E 's/\t@[0-9]+$//' "$W/${TENANT}_$p.ours.lines" > "$W/pinned.nf"; sed -E 's/\t@[0-9]+$//' "$W/unpinned.lines" > "$W/unpinned.nf"
        if cmp -s "$W/pinned.nf" "$W/unpinned.nf"; then vs_ctl_dead unpinned-level "part $p's ours leg reads the same contact lines at the build's own level as at the pin (frames stripped)"; fail=1
        else vs_ctl_fired unpinned-level "part $p's ours leg at the build's own level (NORMAL, 6) reads $(diff "$W/pinned.nf" "$W/unpinned.nf" | grep -c '^>') line(s) differently from the level-8 pin (frames stripped), so the level pin is load-bearing"; fi
        if vs_ctl_is unpinned-level; then cp "$W/unpinned.lines" "$W/${TENANT}_$p.ours.lines"; echo "MODE: unpinned-level — part $p's ours leg replaced by the unpinned one"; fi
    fi
    if [ "$TENANT" = "$FIRST_T" ]; then
        # the tenant-planted control: a chain label changed on a line INSIDE an attacker-differing event must be
        # charged to the TENANT (attributed=tenant), never absorbed as the attacker's (rule-checker run 2026-09-25-158 Q4)
        p="${PARTS%% *}"
        if $VP swap-label "$W/${TENANT}_$p.ours.lines" "$W/tenant_planted.lines" "$W/p1_${p}_native.txt" "$W/p1_${p}_ours.txt" --events "$W/r_$p.json" > "$W/tenant_plant.log" 2>&1; then
            $VP compare "$TENANT" "$p" "$W/${TENANT}_$p.native.lines" "$W/tenant_planted.lines" --events "$W/r_$p.json" --p1 "$W/p1_${p}_native.txt" "$W/p1_${p}_ours.txt" > "$W/tenant_planted_rows.tsv"
            if grep -q '	DIFFER([^)]*path[^)]*)	.*	attacker=[^-].*	attributed=tenant$' "$W/tenant_planted_rows.tsv" || grep -q '	DIFFER([^)]*path[^)]*)	.*	attacker=[^-].*	attributed=attacker+tenant$' "$W/tenant_planted_rows.tsv"; then vs_ctl_fired tenant-planted "$(cat "$W/tenant_plant.log") — the row inside the attacker's span is charged to the tenant"
            else vs_ctl_dead tenant-planted "a label changed inside an attacker-differing span was not charged to the tenant: $(grep 'DIFFER' "$W/tenant_planted_rows.tsv" | head -2 | cut -c1-160)"; fail=1; fi
        else bad "tenant-planted could not build its copy: $(cat "$W/tenant_plant.log")"; fi
        if vs_ctl_is tenant-planted; then cp "$W/tenant_planted.lines" "$W/${TENANT}_$p.ours.lines"; echo "MODE: tenant-planted — $(cat "$W/tenant_plant.log")"; fi
        # the timing-planted control: a TIMING change the attacker's shift cannot explain (len +3) on a line inside an
        # attacker-differing event must be charged to the TENANT (rule-checker run 2026-09-25-159 Q4)
        if $VP swap-label "$W/${TENANT}_$p.ours.lines" "$W/timing_planted.lines" "$W/p1_${p}_native.txt" "$W/p1_${p}_ours.txt" --events "$W/r_$p.json" --timing > "$W/timing_plant.log" 2>&1; then
            $VP compare "$TENANT" "$p" "$W/${TENANT}_$p.native.lines" "$W/timing_planted.lines" --events "$W/r_$p.json" --p1 "$W/p1_${p}_native.txt" "$W/p1_${p}_ours.txt" > "$W/timing_planted_rows.tsv"
            if grep -q '	DIFFER([^)]*len[^)]*)	.*	attacker=[^-].*	attributed=tenant$' "$W/timing_planted_rows.tsv"; then vs_ctl_fired timing-planted "$(cat "$W/timing_plant.log") — a len +3 the attacker's one-frame shift cannot explain is charged to the tenant"
            else vs_ctl_dead timing-planted "a len +3 inside an attacker-differing event was charged to the attacker: $(grep 'DIFFER' "$W/timing_planted_rows.tsv" | head -2 | cut -c1-160)"; fail=1; fi
        else bad "timing-planted could not build its copy: $(cat "$W/timing_plant.log")"; fi
        if vs_ctl_is timing-planted; then cp "$W/timing_planted.lines" "$W/${TENANT}_$p.ours.lines"; echo "MODE: timing-planted — $(cat "$W/timing_plant.log")"; fi
    fi
    for p in $PARTS; do
        $VP compare "$TENANT" "$p" "$W/${TENANT}_$p.native.lines" "$W/${TENANT}_$p.ours.lines" --events "$W/r_$p.json" --p1 "$W/p1_${p}_native.txt" "$W/p1_${p}_ours.txt" >> "$W/rows.tsv" || bad "compare $p"
        OL="$W/${TENANT}_$p.ours.lines"
        if [ "$TENANT" = "$FIRST_T" ] && [ "$p" = "${PARTS%% *}" ]; then $VP drop-first "$OL" "$W/dropped.lines" > /dev/null; OL="$W/dropped.lines"; fi
        $VP compare "$TENANT" "$p" "$W/${TENANT}_$p.native.lines" "$OL" --events "$W/r_$p.json" --p1 "$W/p1_${p}_native.txt" "$W/p1_${p}_ours.txt" >> "$W/rows_dropped.tsv" || bad "compare (dropped) $p"
        $VP poked "$p" "$W/${TENANT}_$p.native.lines" "tests/expected/reactions_$TENANT.txt" > "$W/poked_$p.txt" || bad "poked $p"
        sed -n 1p "$W/poked_$p.txt" | sed "s/^poked\t/poked\t$TENANT\t/" >> "$W/poked.tsv"
        # THE RIG PREMISE, MEASURED: at level 8 the real-pick, per-event-pinned, RNG-pinned native leg must read
        # test_reactions' frozen lines (poked pick, every-400 pins, no pins on the level or RNG) EXACTLY — 14z-181
        # measured 13/13 on donovan_victim 1 and pyron_victim 1, pinned and unpinned alike; at level 6 every line moved
        if sed -n 1p "$W/poked_$p.txt" | grep -q '	differ=0	contacts=\([0-9]*\)/\1$'; then ok "part $p: the native leg reads test_reactions' frozen lines exactly, the pre-contact stance's entry index aside ($(sed -n 1p "$W/poked_$p.txt" | cut -f3-))"
        else bad "part $p: the native leg does not reproduce tests/expected/reactions_$TENANT.txt ($(sed -n 1p "$W/poked_$p.txt" | cut -f3-)) — the pick, the pins or the level moved the rig:"; sed -n '2,$p' "$W/poked_$p.txt" | head -6; fi
    done
    grep -E "^ev	$TENANT	" "$W/rows.tsv" | awk -F'\t' '{print "  " $6 "\t" $9 "\t" $10}' | sort | uniq -c | sort -rn | sed 's/^/ /'
done

cat "$W/poked.tsv" >> "$W/rows.tsv"; cat "$W/poked.tsv" >> "$W/rows_dropped.tsv"
N_EV="$(grep -c '^ev	' "$W/rows.tsv")"; N_SAME="$(grep -c '	SAME	' "$W/rows.tsv")"
echo "== 7. the table: $N_EV contact rows, $N_SAME SAME"
vs_measured victim-parity-rows "$N_EV"
if vs_ctl_is hit-dropped; then cp "$W/rows_dropped.tsv" "$W/rows.tsv"; echo "MODE: hit-dropped — the first part's first contact line dropped from our leg before the compare"; fi
if [ "${FREEZE:-0}" = 1 ]; then
    [ $fail = 0 ] || { echo "REFUSED FREEZE: a check above is red"; echo "FAIL: audit_victim_parity"; exit 1; }
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED FREEZE: under a control mode"; echo "FAIL: audit_victim_parity"; exit 1; }
    vs_meas_guard "$0" victim-parity-rows "$N_EV" || { echo "FAIL: audit_victim_parity"; exit 1; }
    { echo "# tests/expected/victim_parity.tsv — the tenant AS THE VICTIM, ours ($(basename "$BUILD")) vs native vsav2, per contact of the"
      echo "# victim rigs: cls, frz, len, path (translated) and the contact frame (@f, printed, not compared). tests/audit_victim_parity.sh;"
      echo "# rows: ev <tenant> <part> <k> <event> SAME|DIFFER(fields) native=cls,frz,len,path@f ours=... attacker=<Victor chains whose data"
      echo "# differs between the games that ran inside the row's event, or -> attributed=<attacker: only len/frz differ inside such an"
      echo "# event | tenant: cls or the chain path differs | attacker+tenant | ->; poked <tenant> <part> same= differ="
      echo "# = the real-pick, per-event-pinned, level/RNG-pinned native leg against test_reactions' frozen (poked-pick) lines."
      echo "# Evidence class: in-emulator. Frozen 14z-181 with FREEZE=1 (GitHub #136: the tenant as victim, measured ours-vs-native nowhere before)."
      echo "#--"; cat "$W/rows.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($N_EV ev rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if [ "${FIRST_T} ${TENANTS#* }" = "$TENANTS" ] && [ "$TENANTS" = "donovan pyron huitzil" ]; then
    if diff "$W/want.tsv" "$W/rows.tsv" > "$W/diff.txt"; then ok "every row as frozen ($N_EV ev rows)"; else bad "differs from the frozen rows ($(grep -c '^[<>]' "$W/diff.txt") diff lines):"; head -20 "$W/diff.txt"; fi
    # hit-dropped, in-gate: the perturbed rows must differ from the frozen file
    if diff -q "$W/want.tsv" "$W/rows_dropped.tsv" > /dev/null; then vs_ctl_dead hit-dropped "dropping a contact from our leg leaves the frozen rows unchanged"; fail=1
    else vs_ctl_fired hit-dropped "dropping one contact from our leg changes $(diff "$W/want.tsv" "$W/rows_dropped.tsv" | grep -c '^>') frozen row(s)"; fi
else
    for t in $TENANTS; do
        grep -E "^(ev|poked)	$t	" "$W/want.tsv" > "$W/want_$t.tsv"; grep -E "^(ev|poked)	$t	" "$W/rows.tsv" > "$W/got_$t.tsv"
        if diff "$W/want_$t.tsv" "$W/got_$t.tsv" > "$W/diff_$t.txt"; then ok "$t: every row as frozen"; else bad "$t differs from the frozen rows:"; head -20 "$W/diff_$t.txt"; fi
    done
    echo "  (a TENANTS subset: the hit-dropped control is read on the full set only)"
    grep -E "^(ev|poked)	$FIRST_T	" "$W/want.tsv" > "$W/want_1.tsv"; grep -E "^(ev|poked)	$FIRST_T	" "$W/rows_dropped.tsv" > "$W/got_1d.tsv"
    if diff -q "$W/want_1.tsv" "$W/got_1d.tsv" > /dev/null; then vs_ctl_dead hit-dropped "dropping a contact from our leg leaves the frozen rows unchanged"; fail=1
    else vs_ctl_fired hit-dropped "dropping one contact from our leg changes $(diff "$W/want_1.tsv" "$W/got_1d.tsv" | grep -c '^>') frozen row(s)"; fi
fi
[ -n "${GOT_OUT:-}" ] && cp "$W/rows.tsv" "$GOT_OUT"
[ -n "${KEEP:-}" ] && { mkdir -p "$KEEP"; cp "$W"/*.ft "$W"/*.lines "$W"/p1_*.txt "$W"/rows.tsv "$KEEP"/ 2>/dev/null; echo "  kept traces, lines and P1 checks in $KEEP"; }
if [ -n "${VS_CTL:-}" ]; then [ $fail = 0 ] && { echo "PASS (the control mode did NOT reach FAIL — the control is dead)"; exit 0; } || { echo "FAIL: audit_victim_parity (control mode)"; exit 1; }; fi
[ $fail = 0 ] && echo "PASS: audit_victim_parity" || echo "FAIL: audit_victim_parity"
exit $fail
