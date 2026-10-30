#!/bin/sh
# audit_vanilla_pursuits.sh — THE VSAVJ PURSUITS, MEASURED: every vanilla character's pursuit and ES pursuit starts
# only on a downed victim, lands the damage the game staged, and stages the records it does — for the community
# cross-check (GitHub #229; the 14z-194 method rebuilt as a gate 14z-205, its scratch rigs lost with ERIS's files).
# Emulator tier, MAME lane, the vsavj ROM (the reference MAME build run_mame.sh pins for a stock set).
#
# WHAT: for each of the 15 vanilla characters, five events after a walk-in to contact: the knockdown (2HK; Jedah's
#   5HK) then U+LP, U+LK, U+PP (one stock), U+KK (one stock) at a per-character offset inside the measured connect
#   band (tools/vanilla_pursuit_rigs.py PRESS), and the CONTROL — the same U+LP at the same offset with NO knockdown.
#   Each knockdown event: the pursuit STARTS (P1's seq 0x0E for 8P/8K, 0x10 for 8PP/8KK), P2's downed flag +0x117 is
#   set at the press, every record the fighter applier staged lies in the attacker's own attack table or her own projectile hitbox set and LANDS (a
#   fall of P2's HP in the same run within 2 frames), an ES pursuit spends exactly one stock; the CONTROL never
#   starts a pursuit. Each event's frozen line: started, the flag, the ES spend, whether 8K / 8PP / 8KK enter the
#   chain 8P does, and a 16-hex SHA-256 of the event's numeric signature (start offset, chain, falls, meter fraction
#   gained, stock spent, the staged records with their power CLASS) — the numbers are not in the tree (the frame-data
#   ruling, 14z-126); a red prints them from the run. STARTUP and ACTIVE in ENGINE TICKS (startup = ticks on non-attack
#   nodes before the first attack node, active = ticks on attack nodes, and the runs of consecutive attack ticks) are
#   frozen the same way, as a second hash column. THE CONNECT-BAND EDGES: for 8P and 8PP of every character, one
#   single-offset leg each at lo-1, lo, hi, hi+1 frames after the knockdown press (connected = the pursuit started
#   and P2's HP fell after it), frozen per leg in tests/expected/vanilla_pursuit_bands.tsv. Also: the rigs' row set
#   equals the workbook's pursuit rows.
# HOW: tools/vanilla_pursuit_rigs.py gen builds the rigs (tests/replays/vanilla_pursuits/, a fresh gen must equal
#   them); each rig runs as THREE legs: FIELD (tests/lua/field_trace.lua, no debugger: the start, flag, chain, falls,
#   meter, stock), NOSTOP (tests/lua/replay_guard.lua without -debug: the snapshots at each event's first fall, for
#   the capture sheet) and P0189EA (replay_guard.lua -debug, one logging breakpoint at the fighter applier's record
#   read PRG:0x0189EA, with P2's HP dumped on every event frame: the staged records, each judged LANDED on that leg's
#   OWN falls — a breakpoint stop skews its timeline, [VSP-129]) — plus TAP (tests/lua/tap_writes.lua, no debugger, a
#   write tap over P1 +0x1C..+0x23: every node entry and every engine tick, PRG:0x027F70, read by tools/tick_durations.py).
#   The capture sheet <OUT>/capture.png. The band legs: tools/vanilla_pursuit_rigs.py genbands writes 120 single-offset
#   rigs from its BANDS (one press per run: in a multi-event rig an edge moves 1-2 frames with the events before it,
#   measured 14z-205 on 39 of 60 bands), each run under field_trace.
# EXPECTS: 75 events, every one judged and equal to its frozen line (both hashes); 120 band legs equal to theirs;
#   the row set equal to the workbook's (30 rows)
#   where the workbook is present. The two replay_guard legs on emulated time at their frozen game clocks, the
#   staging reference leg on replay.lua's checksum (#228 step 4, option A; tests/lib/instr_align.sh).
# NOT TESTED: the characters are FORCED by the early-window poke; positions, P2's HP and P1's stock and meter are
#   re-pinned before each event — the ROM is pristine, the RAM is not. ONE offset per (character, button); the band
#   edges of 8K and 8KK are not frozen (equal to 8P's and 8PP's in every multi-event sweep; not measured single-
#   offset). The victim is Victor (Demitri for Victor) only. Recovery, FBNeo. What the sheet's `active` counts (ours
#   is the attack-node ticks; the sheet's figures are not a constant offset of it). A record
#   staged at the object-hit applier (PRG:0x02979A) is not read — every knockdown event must stage one at 0x0189EA.
#
# MUST-FIRE: known-bad: drift-clock — the probe leg under the OLD frame_done clock (INSTR_CLOCK=frame_done) must miss its frozen game clock (in-gate: one extra run; mode: every replay_guard leg runs the old clock and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: first-frame-skip — the staging reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum (in-gate; mode: the staging leg runs the skip and the gate FAILs on the alignment)
# MUST-FIRE: known-bad: es-no-stock — Demitri's rig with the ES events' stock poke set to 0 must start NO ES pursuit on either ES event, and the gate must FAIL (mode: the DE rig runs with no stock)
# MUST-FIRE: perturbed-copy: control-as-pursuit — the CONTROL rows read as knockdown events must fail the start clause on all 15 (mode: the rows carry the relabelled CONTROL)
# MUST-FIRE: perturbed-copy: foreign-record — every probe line's A3 moved past the end of its attacker's attack table must fail the identity clause on every knockdown event (mode: the rows are built from the shifted probe logs)
# MUST-FIRE: perturbed-copy: class-raw — the rows built from each record's RAW power byte (the pre-#241 reader) must change the frozen line of Zabel's flagged pursuit records, and the gate must FAIL (mode: the rows read the raw bytes)
# MUST-FIRE: perturbed-copy: tick-dropped — every tap log with the first engine tick at or after press+5 removed on each event must change the tick hash of every knockdown event, and the gate must FAIL (mode: the rows read the dropped taps)
# MUST-FIRE: perturbed-copy: band-moved — the frozen band file with every 8P band's low edge moved one frame later (its `lo` row reads `no`) must fail 15 rows, and the gate must FAIL (mode: the band section reads the moved file)
# MUST-FIRE: perturbed-copy: phantom-record — a staged damaging record planted on every event's press frame (no knockdown event falls in the 2 frames after it) must read NOT LANDED on every knockdown event, and the gate must FAIL (mode: the rows read the planted probes)
# MUST-FIRE: known-bad: foreign-image — an image one byte off vsavj's data view must fail the provenance check (tests/lib/pristine_vsavj.sh; in-gate; mode: the check is handed that image and the gate FAILs)
# MUST-FIRE: known-bad: foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip must fail the provenance check (in-gate; mode: the check audits that ROMDIR and the gate FAILs)
# MUST-FIRE: known-bad: foreign-rompath — MAME_ROMPATH pointed away from the audited ROMDIR must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# MUST-FIRE: known-bad: foreign-mame — a MAME_BIN that is not the pin's release must fail the provenance check (in-gate; mode: the check runs with it set and the gate FAILs)
# A MODE exits 1 only when ITS perturbation made ITS clause fail (ctl_judge, the same predicate the control section
# reads); otherwise it prints REFUSED and exits 3 (docs/project/must_fire_contract.md).
# FOLLOWS: build/manifest/bank_map.toml tests/expected/vanilla_pursuits.tsv tests/expected/vanilla_pursuit_bands.tsv
#   tests/lua/tap_writes.lua tools/tick_durations.py tests/lib/controls.sh
#   tests/lib/decrypt_cache.sh tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/replay_guard.lua
#   tests/replays/vanilla_pursuits/ tools/vanilla_pursuit_rigs.py tools/ground_throw_rigs.py tools/hitbox_records.py
#   tools/name_moves.py tools/run_mame.sh tools/run_replay_guarded.sh tools/setup_mame.sh tools/vanilla_frames.py
#   tools/vanilla_join_rig.py tools/anim_nodes.py tools/xlsx_read.py emu/mame-patches/ tests/expected/instr_gameclock/
#   tests/lib/instr_align.sh tests/lua/emu_clock.lua tests/lua/replay.lua
#   tests/lib/pristine_vsavj.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tools/cps2_decrypt.py tests/expected/registry.tsv tests/lib/mame_ident.sh tools/setup_mame.sh tools/run_mame.sh
#
# SHEET: none — measures pristine vsavj only; no leg of our build
#
# WHY: #229's pursuit family, measured 14z-194 with scratch rigs and never gated ([VSP-18]); the damage figure is the
# record's power CLASS (#241), the record found by what the GAME staged (the applier's A3) and held to the fall it
# caused, never by a table lookup of our own.
#
# Usage: ROMDIR=... [JOBS=1] [OUT=<dir>] [SHEET=<workbook.xlsx>] tests/audit_vanilla_pursuits.sh [--freeze-clock]
#   (~14 min on an M2 Pro at JOBS=1: 60 rig legs ~6 min, 120 band legs ~6.5 min; a control mode other than
#   band-moved skips the band legs)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
. "$REPO/tests/lib/instr_align.sh"
FREEZE_CLOCK=0; [ "${1:-}" = "--freeze-clock" ] && FREEZE_CLOCK=1
CLOCKS="tests/expected/instr_gameclock/audit_vanilla_pursuits.tsv"
[ "$FREEZE_CLOCK" = 1 ] && [ -n "$MODE" ] && { echo "REFUSED: --freeze-clock in control mode"; exit 3; }
_clk=""; [ "$MODE" = drift-clock ] && _clk="INSTR_CLOCK=frame_done"
[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR not set"; exit 0; }
ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
JOBS="${JOBS:-1}"
RIGS=tests/replays/vanilla_pursuits
EXP=tests/expected/vanilla_pursuits.tsv
T=tools/vanilla_pursuit_rigs.py
WB="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
W="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/vpursuit.XXXXXX")}" || { echo "FAIL: audit_vanilla_pursuits — mktemp -d failed (W)"; exit 2; }; mkdir -p "$W"
[ -n "${OUT:-}" ] || trap 'rm -rf "$W"' EXIT
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_data.bin" >/dev/null 2>&1 || { echo "SKIP: the vsavj data view could not be made"; exit 0; }
# WHICH ROM AND WHICH IMAGE (14z-209, rule-checker run 2026-10-25-1294 Q1/Q4): tests/lib/pristine_vsavj.sh.
. "$REPO/tests/lib/pristine_vsavj.sh"
vs_pristine_vsavj "$W/pv" "$W/vsavj_data.bin" || { echo "FAIL: audit_vanilla_pursuits (the ROM or the analysed image is not pristine vsavj)"; exit 1; }
if [ -z "$MODE" ]; then vs_pristine_vsavj_controls "$W/pv" || { echo "FAIL: audit_vanilla_pursuits (a provenance control is dead)"; exit 1; }; fi

# THE PERTURBATIONS, one function each, called by the control section and by the mode alike.
nostock_rig() {  # nostock_rig <out dir>: the DE rig with the ES events' stock poke set to 0
    mkdir -p "$1"; cp "$RIGS/pu_DE.rpl" "$1/pu_DE.rpl"
    python3 - "$RIGS/pu_DE.json" "$1/pu_DE.json" <<'PY' || return 1
import json, sys
s = json.load(open(sys.argv[1])); n = 0
es = {e["frame"] for e in s["events"] if e["button"] in ("PP", "KK")}
for i, p in enumerate(s["pokes"]):
    f, a, v = p.split(":")
    if a == "ff8509" and int(f) + 20 in es and v == "010000":
        s["pokes"][i] = f"{f}:ff8509:000000"; n += 1
assert n == 2, f"nostock_rig: {n} ES stock pokes found, not 2"
json.dump(s, open(sys.argv[2], "w"), indent=1)
PY
}
raw_tool() {  # raw_tool <out path>: a copy of the rows reader that reads the RAW power byte (the pre-#241 reader)
    sed -e 's/"real": bb\[8\] & 0x1F, "white": bb\[9\] & 0x1F/"real": bb[8], "white": bb[9]/' \
        -e "s|Path(__file__).resolve().parent.parent / \"build/manifest/bank_map.toml\"|Path(\"$REPO/build/manifest/bank_map.toml\")|" \
        -e "s|sys.path.insert(0, str(Path(__file__).resolve().parent))|sys.path.insert(0, \"$REPO/tools\")|" \
        "$T" > "$1"
    grep -q '"real": bb\[8\], "white": bb\[9\]' "$1" || { echo "raw_tool: the class read was not found" >&2; return 1; }
    return 0
}
shift_logs() {  # shift_logs <legs root> <out root>: every probe log's A3 moved past any attack table (other files linked)
    python3 - "$1" "$2" <<'PY'
import os, re, sys
src, dst = sys.argv[1:]
for rig in sorted(os.listdir(src)):
    s = os.path.join(src, rig, "p0189ea")
    if not os.path.isdir(s):
        continue
    d = os.path.join(dst, rig, "p0189ea"); os.makedirs(d, exist_ok=True)
    for f in os.listdir(s):
        p = os.path.join(s, f)
        if not os.path.isfile(p):
            continue
        if f == "run.log":
            txt = re.sub(r"A3=([0-9a-fA-F]{8})", lambda m: f"A3={int(m.group(1), 16) + 0x100000:08x}", open(p, errors="replace").read())
            open(os.path.join(d, f), "w").write(txt)
        else:
            os.symlink(p, os.path.join(d, f))
    os.symlink(os.path.join(src, rig, "field"), os.path.join(dst, rig, "field"))
PY
}
rows_of() {  # rows_of <rig dir> <legs root> <tool> [probe extra] [tap root] -> rows.jsonl on stdout
    for _j in "$1"/pu_*.json; do
        _b="$(basename "$_j" .json)"
        PYTHONPATH="$REPO/tools" python3 "$3" rows "$_j" "$2/$_b/field/t.txt" "$2/$_b/p0189ea" "$W/vsavj_data.bin" ${4:+"$4"} \
            --tap "${5:-$2}/$_b/tap/t.tap"
    done
}
drop_ticks() {  # drop_ticks <legs root> <out root>: each rig's tap with its first tick at or after press+5 removed per event
    python3 - "$1" "$2" "$REPO/$RIGS" <<'PY'
import json, os, sys
src, dst, rigs = sys.argv[1:]
for rig in sorted(os.listdir(src)):
    t = os.path.join(src, rig, "tap", "t.tap")
    if not os.path.isfile(t):
        continue
    presses = [e["press"] for e in json.load(open(os.path.join(rigs, rig + ".json")))["events"]]
    os.makedirs(os.path.join(dst, rig, "tap"), exist_ok=True)
    left = sorted(presses); out = []
    for ln in open(t):
        p = ln.split()
        if left and ln.startswith("frame") and p[3] == "027f70" and int(p[1]) >= left[0] + 5:
            left.pop(0); continue
        out.append(ln)
    assert not left, f"{rig}: {len(left)} press(es) with no tick to drop"
    open(os.path.join(dst, rig, "tap", "t.tap"), "w").writelines(out)
PY
}
move_band() {  # move_band <band file> <out>: every 8P band's low edge one frame later (its lo row reads no)
    python3 - "$1" "$2" <<'PY'
import sys, collections
rows = [l.rstrip("\n") for l in open(sys.argv[1])]
lo = collections.defaultdict(lambda: 10**9)
for l in rows:
    if l and not l.startswith("#"):
        t, b, o, c = l.split("\t")
        if b == "P" and c == "yes":
            lo[t] = min(lo[t], int(o))
out, n = [], 0
for l in rows:
    if l and not l.startswith("#"):
        t, b, o, c = l.split("\t")
        if b == "P" and int(o) == lo[t]:
            l = "\t".join((t, b, o, "no")); n += 1
    out.append(l)
assert n == 15, f"move_band: {n} low edges moved, not 15"
open(sys.argv[2], "w").write("\n".join(out) + "\n")
PY
}
relabel() {  # relabel <rows in> <rows out>: every CONTROL row read as a knockdown event (the start clause must fail)
    python3 - "$1" "$2" <<'PY'
import json, sys
with open(sys.argv[2], "w") as o:
    for l in open(sys.argv[1]):
        r = json.loads(l)
        if r["event"] == "CONTROL":
            r["event"] = "P"
        o.write(json.dumps(r) + "\n")
PY
}
ctl_judge() {  # ctl_judge <control> <expect.txt> <rows.jsonl>
    case "$1" in
        tick-dropped) _n=$(grep -c '^BAD' "$2"); echo "$_n events differ with a tick dropped"; [ "$_n" = 60 ] ;;
        band-moved) _n=$(grep -c '^BAD' "$2"); echo "$_n band rows differ from the moved file"; [ "$_n" = 15 ] ;;
        es-no-stock) _n=$(python3 -c "import json,sys;print(sum(1 for l in open(sys.argv[1]) if json.loads(l)['sheet']=='DE' and json.loads(l)['event'].startswith('ES') and json.loads(l)['started'] is None))" "$3")
                     echo "$_n of 2 DE ES events started no ES pursuit"; [ "$_n" = 2 ] && grep -q '^BAD' "$2" ;;
        control-as-pursuit) _n=$(grep -c 'NO PURSUIT started' "$2"); echo "$_n of 15 relabelled CONTROL rows fail the start clause"; [ "$_n" = 15 ] ;;
        foreign-record) _n=$(grep -c 'outside the attacker' "$2"); echo "$_n of 60 knockdown events fail the identity clause"; [ "$_n" = 60 ] ;;
        class-raw) echo "$(grep -c '^BAD' "$2") events differ; Zabel's: $(grep -c "^BAD ('ZA'" "$2")"; grep -q "^BAD ('ZA'" "$2" ;;
        phantom-record) _n=$(grep -c 'damage the victim never took' "$2"); echo "$_n of 60 knockdown events read the planted record NOT LANDED"; [ "$_n" = 60 ] ;;
        *) echo "no such control: $1"; return 2 ;;
    esac
}

echo "== audit_vanilla_pursuits: the vsavj ROM ($(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$ROMDIR/vsavj.zip")); tree $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo 'no git'); host $(hostname)"
echo "== 1. the committed rigs are what the generator writes, and cover the workbook's rows"
python3 "$T" gen "$W/fresh" > /dev/null
if diff -r "$W/fresh" "$RIGS" > "$W/rigs.diff" 2>&1; then ok "$RIGS equals a fresh gen ($(ls "$RIGS"/*.rpl | wc -l | tr -d ' ') rigs)"
else bad "the committed rigs differ from a fresh gen:"; sed 's/^/        /' "$W/rigs.diff" | head -10; fi
if [ -f "$WB" ]; then
    if python3 "$T" rowset "$WB" > "$W/rowset.txt" 2>&1; then ok "$(head -1 "$W/rowset.txt")"
    else bad "the rigs' row set differs from the workbook's:"; sed 's/^/        /' "$W/rowset.txt"; fi
else
    echo "  NOTE  no workbook at $WB: the row set is not checked here (it is third-party and lives outside the tree)"
fi

G="$RIGS"; vs_ctl_is es-no-stock && { mkdir -p "$W/ns"; cp "$RIGS"/*.rpl "$RIGS"/*.json "$W/ns/"; nostock_rig "$W/ns" || exit 1; G="$W/ns"; }
FIELDS="$(python3 -c "import sys;sys.path.insert(0,'tools');import vanilla_pursuit_rigs as v;print(v.FIELDS)")"
run_rig() {  # run_rig <rig dir> <name> <legs dir>: FIELD, then NOSTOP (snapshots dated by FIELD) and P0189EA
    _j="$1/$2.json"; _r="$REPO/$1/$2.rpl"; case "$1" in /*) _r="$1/$2.rpl" ;; esac
    _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$_j")"
    _f="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$_j")"
    mkdir -p "$3/$2/field" "$3/$2/nostop" "$3/$2/p0189ea"
    ( cd "$3/$2/field" && MAME_SANDBOX="$3/$2/field/sb" REPLAY="$_r" POKES="$_p" FIELDS="$FIELDS" FIELD_OUT="$3/$2/field/t.txt" \
        FIELD_FROM=2400 FIELD_TO="$_f" FRAMES="$_f" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" \
        > "$3/$2/field/run.out" 2>&1 ) </dev/null
    rm -rf "$3/$2/field/sb"
    mkdir -p "$3/$2/tap"
    ( cd "$3/$2/tap" && MAME_SANDBOX="$3/$2/tap/sb" REPLAY="$_r" POKES="$_p" TAP="$(python3 -c "import sys;sys.path.insert(0,'$REPO/tools');import vanilla_pursuit_rigs as v;print(v.TAP)")" \
        WINDOW="2700,$_f" FRAMES="$_f" TRACE_OUT="$3/$2/tap/t.tap" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/tap_writes.lua" \
        > "$3/$2/tap/run.out" 2>&1 ) </dev/null
    rm -rf "$3/$2/tap/sb"
    PYTHONPATH="$REPO/tools" python3 "$T" rows "$_j" "$3/$2/field/t.txt" "$3/$2/p0189ea" "$W/vsavj_data.bin" > "$3/$2/field/rows0.jsonl" 2>/dev/null
    _s="$(python3 "$T" snaps "$_j" "$3/$2/field/rows0.jsonl" 2>/dev/null)"
    _d="$(python3 "$T" dumps "$_j")"
    printf '%s' "POKES=$_p SNAP_FRAMES=$_s GUARD_DEBUG=0" > "$3/$2/nostop/env"
    # shellcheck disable=SC2086
    ( env $_clk GUARD_DEBUG=0 POKES="$_p" SNAP_FRAMES="$_s" ALIGN_OUT="$3/$2/nostop/align" \
        tools/run_replay_guarded.sh vsavj "$_r" "$3/$2/nostop/run.log" "$3/$2/nostop/sb" > "$3/$2/nostop/run.out" 2>&1 )
    printf '%s' "POKES=$_p GUARD_PROBE=0189ea DUMPS=$_d" > "$3/$2/p0189ea/env"
    # shellcheck disable=SC2086
    ( env $_clk POKES="$_p" GUARD_PROBE=0189ea DUMPS="$_d" ALIGN_OUT="$3/$2/p0189ea/align" \
        tools/run_replay_guarded.sh vsavj "$_r" "$3/$2/p0189ea/run.log" "$3/$2/p0189ea/sb" > "$3/$2/p0189ea/run.out" 2>&1 )
}

echo "== 2. the legs (FIELD, TAP, NOSTOP, P0189EA per rig)"
t0=$(date +%s); _n=0
for j in "$G"/pu_*.json; do
    run_rig "$G" "$(basename "$j" .json)" "$W/legs" &
    _n=$((_n + 1)); [ $((_n % JOBS)) -eq 0 ] && wait
done
wait
dead=0
# A leg is judged by its content, never MAME's exit code: a TAP leg's END line is written immediately before
# machine:exit(), so a teardown segfault (exit 139) after it is accepted with the full output (#320, root-caused 14z-210:
# MAME 0.288's change-notifier binding; tests/lua/tap_writes.lua pins the thread, docs/platform/gotchas.md).
for j in "$G"/pu_*.json; do b=$(basename "$j" .json)
    grep -q '^FIELDSUMMARY' "$W/legs/$b/field/t.txt" 2>/dev/null || { bad "leg $b/field did not complete"; dead=1; }
    grep -q '^END' "$W/legs/$b/tap/t.tap" 2>/dev/null || { bad "leg $b/tap did not complete"; dead=1; }
    for pc in nostop p0189ea; do grep -q '^END ' "$W/legs/$b/$pc/run.log" 2>/dev/null || { bad "leg $b/$pc did not end: $(tail -1 "$W/legs/$b/$pc/run.out" 2>/dev/null | cut -c1-120)"; dead=1; }
        grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$W/legs/$b/$pc/run.log" 2>/dev/null && { bad "leg $b/$pc CRASHED"; dead=1; }; done
done
[ "$dead" = 0 ] && ok "$((_n * 4)) legs ended clean in $(( $(date +%s) - t0 )) s"
for j in "$G"/pu_*.json; do b=$(basename "$j" .json)
    for pc in nostop p0189ea; do
        _e="$(sed 's/SNAP_FRAMES=$//; s/SNAP_FRAMES= / /' "$W/legs/$b/$pc/env")"
        _rp="$REPO/$G/$b.rpl"; case "$G" in /*) _rp="$G/$b.rpl" ;; esac
        ia_note_run "$W/manifest.tsv" "$pc" "$b" vsavj - "$_rp" "$_e" "$W/legs/$b/$pc/align"
    done
done

echo "== 3. every event against its frozen line"
TOOL="$REPO/$T"; vs_ctl_is class-raw && { raw_tool "$W/tool_raw.py" || exit 1; TOOL="$W/tool_raw.py"; }
LEGS="$W/legs"; vs_ctl_is foreign-record && { shift_logs "$W/legs" "$W/legs_shift"; LEGS="$W/legs_shift"; }
EXTRA=""; vs_ctl_is phantom-record && EXTRA="+0:auto"
TAPS="$LEGS"; vs_ctl_is tick-dropped && { drop_ticks "$W/legs" "$W/taps_drop"; TAPS="$W/taps_drop"; }
rows_of "$G" "$LEGS" "$TOOL" "$EXTRA" "$TAPS" > "$W/rows.jsonl"
vs_ctl_is control-as-pursuit && { relabel "$W/rows.jsonl" "$W/rows_rel.jsonl"; mv "$W/rows_rel.jsonl" "$W/rows.jsonl"; }
if [ -n "${FREEZE:-}" ] && [ -z "${VS_CTL:-}" ]; then python3 "$T" freeze "$W/rows.jsonl" > "$EXP"; echo "  FROZE $EXP ($(grep -vc '^#' "$EXP") events)"; fi
if python3 "$T" expect "$W/rows.jsonl" "$EXP" > "$W/expect.txt" 2>&1; then ok "$(tail -1 "$W/expect.txt")"
else bad "$(tail -1 "$W/expect.txt")"; grep -A3 '^BAD' "$W/expect.txt" | head -16 | sed 's/^/        /'; fi
[ -f "$WB" ] && python3 "$T" crosscheck "$W/rows.jsonl" "$WB" > "$W/crosscheck.txt" 2>&1 && echo "  NOTE  the workbook cross-check: $W/crosscheck.txt ($(grep -c '^TALLY' "$W/crosscheck.txt") tallies)"

echo "== 3c. the connect-band edges (8P / 8PP, one single-offset leg per lo-1, lo, hi, hi+1)"
BEXP=tests/expected/vanilla_pursuit_bands.tsv
if [ -z "$MODE" ] || [ "$MODE" = band-moved ]; then
    python3 "$T" genbands "$W/bands" > /dev/null
    t1=$(date +%s); _bd=0
    for j in "$W"/bands/pb_*.json; do b=$(basename "$j" .json); mkdir -p "$W/bruns/$b"
        _p="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$j")"
        _f="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$j")"
        ( cd "$W/bruns/$b" && MAME_SANDBOX="$W/bruns/$b/sb" REPLAY="$W/bands/$b.rpl" POKES="$_p" FIELDS="$FIELDS" \
            FIELD_OUT="$W/bruns/$b/t.txt" FIELD_FROM=2400 FIELD_TO="$_f" FRAMES="$_f" \
            "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/bruns/$b/run.out" 2>&1 ) </dev/null
        rm -rf "$W/bruns/$b/sb"
        if grep -q '^FIELDSUMMARY' "$W/bruns/$b/t.txt" 2>/dev/null; then python3 "$T" bandrows "$j" "$W/bruns/$b/t.txt"
        else echo "$b DEAD" >&2; _bd=$((_bd + 1)); fi
    done > "$W/bands_got.tsv" 2> "$W/bands_dead.txt"
    [ "$_bd" = 0 ] && ok "$(ls "$W"/bands/pb_*.json | wc -l | tr -d ' ') band legs ended clean in $(( $(date +%s) - t1 )) s" || bad "$_bd band leg(s) did not complete: $(head -3 "$W/bands_dead.txt" | tr '\n' ' ')"
    if [ -n "${FREEZE:-}" ] && [ -z "$MODE" ]; then
        python3 -c "import sys;sys.path.insert(0,'tools');import vanilla_pursuit_rigs as v;print(v.BAND_HEADER)" > "$BEXP"; sort "$W/bands_got.tsv" >> "$BEXP"
        echo "  FROZE $BEXP ($(grep -vc '^#' "$BEXP") band legs)"
    fi
    BX="$BEXP"; vs_ctl_is band-moved && { move_band "$BEXP" "$W/bands_moved.tsv" || exit 1; BX="$W/bands_moved.tsv"; }
    if python3 "$T" bandexpect "$W/bands_got.tsv" "$BX" > "$W/bands_expect.txt" 2>&1; then ok "$(tail -1 "$W/bands_expect.txt")"
    else bad "$(tail -1 "$W/bands_expect.txt")"; grep '^BAD' "$W/bands_expect.txt" | head -8 | sed 's/^/        /'; fi
    vs_ctl_is band-moved && { if _ev="$(ctl_judge band-moved "$W/bands_expect.txt" -)"; then vs_ctl_fired band-moved "$_ev (mode)"; echo "FAIL"; exit 1; fi
        echo "REFUSED: mode band-moved — its perturbation did not make its own clause fail ($_ev): a dead mode, not a verdict"; exit 3; }
else
    echo "  NOTE  skipped in control mode $MODE (the band legs are not its clause)"
fi

if [ -n "${VS_CTL:-}" ] && [ "$MODE" != drift-clock ] && [ "$MODE" != first-frame-skip ]; then
    if _ev="$(ctl_judge "$VS_CTL" "$W/expect.txt" "$W/rows.jsonl")"; then
        vs_ctl_fired "$VS_CTL" "$_ev (mode)"; echo "FAIL"; exit 1
    fi
    echo "REFUSED: mode $VS_CTL — its perturbation did not make its own clause fail ($_ev): a dead mode, not a verdict"
    exit 3
fi

echo "== 3b. the instrument's alignment (#228 step 4, option A)"
if [ "$FREEZE_CLOCK" = 1 ]; then
    [ "$fail" = 0 ] || { echo "REFUSED: sections 1-3 failed — nothing frozen"; exit 1; }
    ia_freeze "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" "$W/fz" "$JOBS" "$W/clocks.tsv" \
        > "$W/fz.txt" || { sed 's/^/  /' "$W/fz.txt"; echo "REFUSED: the alignment does not hold — nothing frozen"; exit 1; }
    mkdir -p "$(dirname "$CLOCKS")"
    { echo "# $CLOCKS — the game clock RAM:\$FF8080 at each run's last frame, frozen from REFERENCE legs (#228 step 4,"
      echo "# option A) by \`tests/audit_vanilla_pursuits.sh --freeze-clock\` at $(git rev-parse --short=8 HEAD): pristine vsavj; legs nostop and"
      echo "# p0189ea per rig; every reference leg held to replay.lua run live, every guarded leg to its reference leg's game clock."
      echo "# leg<TAB>replay<TAB>frames<TAB>gameclock"
      cat "$W/clocks.tsv"; } > "$CLOCKS"
    echo "froze $(wc -l < "$W/clocks.tsv" | tr -d ' ') game clocks into $CLOCKS"
    exit 0
fi
if ia_check_manifest "$CLOCKS" "$W/manifest.tsv" > "$W/align_bad.txt"; then ok "every guarded leg on emulated time, at its frozen game clock"
else bad "$(wc -l < "$W/align_bad.txt" | tr -d ' ') problem(s) off the frozen alignment:"; head -8 "$W/align_bad.txt" | sed 's/^/        /'; fi
ia_stage audit_vanilla_pursuits "$CLOCKS" "$REPO/tests/lua/replay_guard.lua" "$W/manifest.tsv" 2 "$W/st" "$MODE" || fail=1
if [ "$MODE" = drift-clock ] || [ "$MODE" = first-frame-skip ]; then
    [ "$fail" = 1 ] && { echo "FAIL (control mode: $MODE)"; exit 1; }
    echo "FAIL — control mode $MODE left the gate green"; exit 1
fi
if [ "$IA_DRIFT" = fired ]; then vs_ctl_fired drift-clock "$IA_DRIFT_MSG"; else vs_ctl_dead drift-clock "$IA_DRIFT_MSG" || fail=1; fi
if [ "$IA_SKIP" = fired ]; then vs_ctl_fired first-frame-skip "$IA_SKIP_MSG"; else vs_ctl_dead first-frame-skip "$IA_SKIP_MSG" || fail=1; fi

echo "== 4. the capture sheet (snapshots at each event's first fall, in the no-stop legs above)"
if ls "$W"/legs/*/nostop/sb/snap/*/*.png > /dev/null 2>&1; then
    python3 "$T" sheet "$W/capture.png" "$W/legs" "$G" "$W/rows.jsonl" > "$W/sheet.txt" 2>&1 \
        && ok "$(cat "$W/sheet.txt")" || echo "  NOTE  no capture sheet: $(tail -1 "$W/sheet.txt")"
else
    echo "  NOTE  no snapshots"
fi

echo "== 5. controls"
judge() {  # judge <control> <expect.txt> <rows.jsonl>
    if _ev="$(ctl_judge "$1" "$2" "$3")"; then vs_ctl_fired "$1" "$_ev"; else vs_ctl_dead "$1" "$_ev"; fail=1; fi
}
relabel "$W/rows.jsonl" "$W/rows_rel.jsonl"; python3 "$T" expect "$W/rows_rel.jsonl" "$EXP" > "$W/x_rel.txt" 2>&1
judge control-as-pursuit "$W/x_rel.txt" "$W/rows_rel.jsonl"
shift_logs "$W/legs" "$W/c_shift"; rows_of "$RIGS" "$W/c_shift" "$REPO/$T" > "$W/rows_shift.jsonl"
python3 "$T" expect "$W/rows_shift.jsonl" "$EXP" > "$W/x_shift.txt" 2>&1
judge foreign-record "$W/x_shift.txt" "$W/rows_shift.jsonl"
if raw_tool "$W/tool_raw.py"; then rows_of "$RIGS" "$W/legs" "$W/tool_raw.py" > "$W/rows_raw.jsonl"; else : > "$W/rows_raw.jsonl"; fi
python3 "$T" expect "$W/rows_raw.jsonl" "$EXP" > "$W/x_raw.txt" 2>&1
judge class-raw "$W/x_raw.txt" "$W/rows_raw.jsonl"
rows_of "$RIGS" "$W/legs" "$REPO/$T" "+0:auto" > "$W/rows_phantom.jsonl"
python3 "$T" expect "$W/rows_phantom.jsonl" "$EXP" > "$W/x_phantom.txt" 2>&1
judge phantom-record "$W/x_phantom.txt" "$W/rows_phantom.jsonl"
drop_ticks "$W/legs" "$W/c_drop"; rows_of "$RIGS" "$W/legs" "$REPO/$T" "" "$W/c_drop" > "$W/rows_drop.jsonl"
python3 "$T" expect "$W/rows_drop.jsonl" "$EXP" > "$W/x_drop.txt" 2>&1
judge tick-dropped "$W/x_drop.txt" "$W/rows_drop.jsonl"
if move_band "$BEXP" "$W/c_bands_moved.tsv"; then python3 "$T" bandexpect "$W/bands_got.tsv" "$W/c_bands_moved.tsv" > "$W/x_bands.txt" 2>&1
    judge band-moved "$W/x_bands.txt" -
else vs_ctl_dead band-moved "could not build the moved band file"; fail=1; fi
if nostock_rig "$W/nsc"; then
    run_rig "$W/nsc" pu_DE "$W/legs_ns"
    rows_of "$W/nsc" "$W/legs_ns" "$REPO/$T" > "$W/rows_ns.jsonl"
    python3 "$T" expect "$W/rows_ns.jsonl" "$EXP" > "$W/x_ns.txt" 2>&1
    judge es-no-stock "$W/x_ns.txt" "$W/rows_ns.jsonl"
else vs_ctl_dead es-no-stock "could not build the no-stock rig"; fail=1; fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
