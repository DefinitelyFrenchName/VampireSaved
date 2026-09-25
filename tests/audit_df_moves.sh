#!/bin/sh
# audit_df_moves.sh — THE TENANTS' MOVES INSIDE THEIR DARK FORCE, ours (Dark Force Change, P+K) vs native (the vs2 personal-Dark-Force EX install), frozen AS MEASURED (14z-168, GitHub #136): every in-DF event of the #136 naming schedules re-run inside a mode that is ENTERED on both legs, compared by its ORDERED hits (damage, P2 reaction class) and gauge steps — all 29 events match in hits and damage but for the known remaps; the gauge differs by the two ruled rules.
#
# WHAT: the tenants' moves INSIDE their Dark Force, ours (Change, P+K) against native (the
#   vs2 personal-Dark-Force EX install), frozen as measured: all 29 in-DF events match in
#   ordered hits and damage but for the known remaps, and the gauge differs by the two ruled
#   rules — with the mode proven ENTERED on both legs at every activation. Since 14z-181 also
#   the CONTACT group (#109's folded leg): Phobos's beams with P2 grounded at a near pin and
#   jumping into the band, far and near, its own part.
# HOW: the legs in parallel on MAME, the #136 in-DF events re-run ONE per activation (110
#   frames after it, stocks re-poked, groups spaced past the longer mode; no rig write of any
#   kind inside a compared window since 14z-181), both legs' ordered hits (damage, class), gauge steps, palette page and RNG reads
#   compared; nine controls (the mode lost, an idle leg, a blind palette, a dead RNG pin, a
#   moved form, a dropped hit, an HP pin inside a compared window, the native leg unpinned, a
#   poke inside the sword window) each must be refused.
#   CAPTURE=<dir> also snapshots the CONTACT group's events at their hit frames on both legs.
# EXPECTS: SAME on every event but the frozen DIFFER rows, every activation entered on both
#   legs (else VOID), the nine controls failing. Not shown: that the named move came out AS
#   that move — the printed state paths say what it did.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/df_moves.tsv
#   tests/expected/registry.tsv tests/lua/field_trace.lua tests/lua/read_tap.lua
#   tests/lua/snapshot_frames.lua tests/lua/sprite_capture.lua tools/build_fingerprint.py
#   tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: mode-lost — our Change field +0x111 zeroed at the first compared event's frame (what a rig that outran the mode would read) must be refused by the in-mode check, so every compared event is MEASURED inside the mode on both legs, not assumed from the rig's spacing (in-gate: the zeroed copy must fail the check; mode: our field is zeroed before the check and the gate FAILs)
# MUST-FIRE: perturbed-copy: idle-leg — our P1 state held still over the first compared event's window (what an input that produced nothing would read) must be refused by the acted check, so no SAME row can be two legs agreeing on nothing (in-gate: the held copy must fail the check; mode: our state is held before the check and the gate FAILs)
# MUST-FIRE: perturbed-copy: palette-blind — the form reducer run with our palette page replaced by native's own (what a read that never reached our palette RAM would compare) must be refused, because no HUD palette is then seen differing, so the palette comparison is proven to see a real difference (in-gate: the blind rows must fail the checks; mode: the blind rows replace the real ones and the gate FAILs)
# MUST-FIRE: perturbed-copy: rng-dead — the form rows with our leg's RNG reads set to 0 (a pin that never reached the RNG) must be refused, so the sword's seed test is proven non-vacuous (in-gate: the rewritten rows must fail the checks; mode: the rows are rewritten and the gate FAILs)
# MUST-FIRE: perturbed-copy: form-moved — a copy of the form rows with Pyron's colours reported different at f2730 (what a palette the port got wrong would read) must be refused by the colour check, so "identical" is measured on the palette RAM, not the eye (in-gate: the rewritten copy must fail the check; mode: the rows are rewritten before the check and the gate FAILs)
# MUST-FIRE: perturbed-copy: pin-in-window — an HP pin planted (in memory) inside the first compared event's window must be refused by the compare, so no compared window carries ANY rig write shared by both legs (the reader refuses every poke address; since 14z-181 the rig itself puts none there: one event per activation, no pin on the expiry wait, the HP pins moved) (in-gate: the planted copy must be refused; mode: the pin is planted before the compare and the gate FAILs) — 14z-181, rule-checker run 2026-09-25-148 Q3
# MUST-FIRE: perturbed-copy: pins-unpinned — one native leg (UNPIN_PART, default huitzil_dfx2) run with the schedule's pokes only, vsav2's own play-mode level and RNG, must read rows that DIFFER from the pinned native's (or be refused), so the level and RNG pins both legs share are shown load-bearing rather than assumed (the 14z-158 ruling's control, brought to this gate 14z-181 — rule-checker run 2026-09-25-152 Q3; in-gate: the unpinned rows against the pinned; mode: the native leg is replaced by the unpinned one and the gate FAILs)
# MUST-FIRE: perturbed-copy: sword-poke-planted — a schedule poke planted (in memory) at T5+10, inside the sword flight window, must be refused by the sword-window check, so the check that keeps the frozen form rows free of any shared rig write is itself shown live (in-gate: the planted copy must be refused; mode: the poke is planted before the check and the gate FAILs) — 14z-181, rule-checker run 2026-09-25-154 Q4
# MUST-FIRE: perturbed-copy: hit-dropped — a copy of our rows with the first event's first hit removed (what a mode that lost an altered attack would read) must FAIL the frozen compare, so the frozen rows are what the altered attacks did (in-gate: the perturbed copy must differ from the frozen rows; mode: our rows are rewritten before the compare and the table FAILs)
#
# WHY. The #136 parity rigs outran the 360-frame Dark Force (25 NOT-IN-DF rows). Put to the
# maintainer 2026-09-17 as "that needs a rig change, not a comparator change", answered
# "agreed and this should be in next_session.md" (DECISIONS_HISTORY.md "Ruled 2026-09-17
# (14z-164b) — the in-DF batteries need a RIG change"). The FORM — the mode re-activated per
# group of at most two events — is this gate's design, not ruled. Its first version
# compared our P+K with vs2's P+K, which is a DIFFERENT MODE (Dark Force Power); the
# maintainer caught it (2026-09-18, 14z-168): *"VS2's dark force power costs 2 meters
# instead of 1, has no invincibility at startup, is a global buff, has no specific moves
# while VS dark force (sometimes called dark force change) is a character altering
# ability with startup invincibility"* — the tenants' vs2 reference is their personal
# Dark Force, a timed EX move (DECISIONS_HISTORY.md "Ruled 2026-09-18 (14z-168) — the
# tenants' Dark Force"; docs/game/engine_internals.md, "Dark Force POWER, Dark Force CHANGE"). This gate is the rig on that baseline: our leg presses
# P+K, the native leg the tenant's vs2 EX input (Donovan 421+KK, Phobos 263+PP, Pyron
# 2623+PP — measured; the maintainer, 14z-169: "as far as I know these are the correct
# inputs in VS2 ... I assume they are indeed correct"), the moves
# start 110 frames after the activation (Phobos's vs2 EX takes his form ~75 frames in;
# at 70 his first move was lost on the native leg — measured), every event pinned far
# (552/728), the stock re-poked to 9 before each activation, the groups spaced past the
# LONGER mode (native's EX, 509 frames of +0x111) plus the 36-frame end state (seq 0x1A).
# Both legs must ENTER the mode at every activation (a stock spent on each; our flag up)
# or the leg is VOID.
#
# WHAT IT FREEZES (tests/expected/df_moves.tsv): per in-DF event,
#   ev <part> <k> <name> <SAME|DIFFER(...)> native=<hits (dmg,class)> @<frames> m1=<P1 gauge steps> m2=<P2 gauge steps>
#       ours=<the same>
# As measured 14z-168 on merged-m18: Donovan 24 of 25 match in hits and damage (the
# 25th is Lightning Sword's class byte 0x4E native / 0x06 ours — the 14z-35/42 remap,
# equal damage and frame); Phobos's clone beams and Pyron's Sol Smasher match; every
# m1 difference is the gauge: vs2's EX install pays start-up and hit gauge, ours pays
# no hit gauge (vsav's rule; the maintainer, 2026-09-18: *"I see, it makes sense that you
# can't build meter during DF"*, DECISIONS_HISTORY.md) but still pays the tenants'
# start-up gauge (GitHub #157's Dark Force tail — a fix re-freezes this file).
#
# SHARED BY BOTH LEGS, BY DESIGN: the move inputs, the far X pins, the stock re-poke, the level
# ($FF8116) and RNG ($FF80D4) pins — written on EVERY frame of every compared window on both legs; the
# method the maintainer ruled for test_don_immortal_native on 2026-09-15 (DECISIONS_HISTORY.md "Ruled
# 2026-09-15 (14z-158)"), taken as this gate's design, not a ruling over every comparison; its control,
# `pins-unpinned`, is here since 14z-181. The two globals mean the same on vsav2: the level is the play
# mode tests/audit_move_parity.sh's unpinned-level control shows governing the native leg, and
# the RNG seed selects vsav2's own draws in tests/expected/entrance_draw.tsv.
# WHAT IT DOES NOT SHOW: that the named move came out AS that move. The acted check proves P1
# acts on both legs, and the printed state paths show what it did: measured 14z-168, the two
# Killshread [LK] inputs enter the kick state 0x0A on both legs, not the special. A jump
# normal's attack is not told apart from the jump itself. An L button's swing cost is 0
# (docs/game/atlas/ram.md +0x10A), so the no-hit L rows have no gauge step whether or not the
# attack came out.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged27] [FREEZE=1] tests/audit_df_moves.sh
#   emulator tier, MAME; 10 legs in parallel — measured 14z-168 on this MacBook, solo: ~40 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged27}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/df_moves.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|hit-dropped|mode-lost|idle-leg|form-moved|rng-dead|palette-blind|pin-in-window|pins-unpinned|sword-poke-planted) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. the rigs (the in-DF events of the #136 schedules, per-leg activation)"
# THE BUILD IS HELD TO THE REGISTRY (14z-181, rule-checker run 2026-09-25-149 Q1/Q4): its WHOLE-SET dispatch key
# (`--set-key`; the program key alone is one build/merged1 also carries) must be a registry row, or the run is VOID.
_wkey="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --set-key 2>/dev/null)"
_pkey="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath" --set vsavjw --sha-only 2>/dev/null)"
_reg="$(awk -F'\t' -v k="$_wkey" '$1==k {print $2; exit}' "$REPO/tests/expected/registry.tsv")"
if [ -n "$_reg" ]; then ok "ours: $(basename "$BUILD") = registry row '$_reg' (whole-set $(echo "$_wkey" | cut -c1-8), program $(echo "$_pkey" | cut -c1-8))"
else echo "FAIL: VOID — $(basename "$BUILD")'s whole-set key $(echo "$_wkey" | cut -c1-8) is no row of tests/expected/registry.tsv (an unregistered build is a rule-6 stop)"; exit 1; fi
( cd "$REPO" && python3 - "$W" <<'PY'
import sys, json, os, contextlib, io
sys.path.insert(0, "tools"); import name_moves as nm
OUT = sys.argv[1]
G_ACT = 110; OURS_MODE = 360 + 28; GROUP_SPAN = 509 + 36 + 60
EX = {"donovan": [(0, 2, "L"), (4, 6, "D"), (8, 12, "DL"), (10, 14, "46")],
      "huitzil": [(0, 2, "D"), (4, 6, "R"), (8, 12, "DR"), (10, 14, "13")],
      "pyron":   [(0, 2, "D"), (4, 6, "R"), (8, 10, "D"), (12, 16, "DR"), (14, 18, "13")]}
PK = [(0, 4, "14")]
SRC = {"donovan": [("6", range(3, 27)), ("4", [22])], "huitzil": [("4", [12, 13])], "pyron": [("4", [13, 14])]}
# THE CONTACT GROUP (14z-181): the positive-contact damage leg GitHub #109 left open, FOLDED into #136 at 14z-157
# (DECISIONS_HISTORY.md "Ruled 2026-09-15 (14z-157)", the maintainer on that decision sheet: *"I agree with all
# recommendations"*; #109's own description of the leg: "P2 jumped into the beam band, comparing damage with
# native"). Its hand rigs (tests/replays/df/103 ours, 104 native) were mistimed for a compared run (the mode ended
# before their later attacks; no beam reached P2 at their range — build/agent181/clone_beam_contact_run1.log), so
# the leg lives HERE, on the generator: Phobos's 5LP/5HP PRESSES inside the mode with P2 GROUNDED at a NEAR pin
# (640, the far pin's 728 overridden on the P2 poke only — both legs share it) and with P2 JUMPING at the event
# (Victor's neutral jump 10 frames before the press), far and near. Each its own group in its own part, so the dfx1
# rows above are untouched. WHICH ATTACK produced a hit is NOT shown — this gate's stated limit (above): a 2-damage
# hit read 8-9 frames after the press at the far pin (dfx1's 5LP) or 6-8 frames after it at the near pin, and 14
# frames after it on the far jumping row, is what the far-pin 5LP rows already read as the beams; the near jumping
# row's hit lands 3 frames after the press for 5 with native gauge 18, the timing and damage of the punch itself.
# Neither reading is asserted; the rows freeze the hits.
EXTRA = {"huitzil": [("5LP press in DF, P2 grounded near", [(0, 3, "1")], 220, "far", 640),
                     ("5HP press in DF, P2 grounded near", [(0, 3, "3")], 220, "far", 640),
                     ("5LP press in DF, P2 jumping far", [(0, 2, "U", "p2"), (10, 13, "1")], 220, "far", None),
                     ("5LP press in DF, P2 jumping near", [(0, 2, "U", "p2"), (10, 13, "1")], 220, "far", 640)]}
for tenant, srcs in SRC.items():
    groups, cur, used = [], [], 0
    for part, evs in srcs:
        for k in evs:
            e = nm.SCHEDULES[tenant][part][k]
            # ONE EVENT PER ACTIVATION (14z-181, rule-checker run 2026-09-25-150 Q1/Q4): with two, the second
            # event's x pins (name_moves.py: both fighters at t-40) landed INSIDE the first event's compared
            # window — a shared rig write on both legs that could move P2 out of a later hit's path.
            if cur and (used + e[2] > OURS_MODE - G_ACT - 10 or len(cur) == 1):
                groups.append(cur); cur, used = [], 0
            cur.append(e); used += e[2]
    if cur: groups.append(cur)
    parts, p, span = [], [], 0
    for g in groups:
        if p and span + GROUP_SPAN > 7000: parts.append(p); p, span = [], 0
        p.append(g); span += GROUP_SPAN
    if p: parts.append(p)
    if tenant in EXTRA: parts.append([[e[:4]] for e in EXTRA[tenant]])   # the contact group: one event per activation, its own part
    near = {e[0]: e[4] for e in EXTRA.get(tenant, []) if e[4]}
    for i, pg in enumerate(parts, 1):
        name = f"dfx{i}"
        for leg, act in (("native", EX[tenant]), ("ours", PK)):
            sched = []
            for g in pg:
                sched.append(("mode activation", act, G_ACT, "far"))
                for e in g: sched.append((e[0], e[1], e[2], "far"))
                # the expiry wait carries NO pin (until 14z-181 it was tagged "far", so both fighters' x were
                # rewritten 40 frames before the group's last compared window ended — rule-checker run 2026-09-25-150)
                sched.append(("mode expiry wait", [], GROUP_SPAN - G_ACT - sum(e[2] for e in g)))
            nm.SCHEDULES[tenant][name] = sched
            with contextlib.redirect_stdout(io.StringIO()):
                nm.gen(tenant, name, f"{OUT}/{tenant}_{name}.{leg}.rpl", f"{OUT}/{tenant}_{name}.{leg}.json")
        j = json.load(open(f"{OUT}/{tenant}_{name}.ours.json"))
        for e in j["events"]:
            if e["name"] == "mode activation": j["pokes"].append(f"{e['frame'] - 10}:ff8509:09")
            if e["name"] in near:   # the NEAR pin: P2's x poke of this event's far pin moved in; shared by both legs
                k = f"{e['frame'] - 40}:ff8810:{nm.PIN['far'][1]:04x}"
                assert k in j["pokes"], (e["name"], k)
                j["pokes"][j["pokes"].index(k)] = f"{e['frame'] - 40}:ff8810:{near[e['name']]:04x}"
        # HP PINS OUT OF THE COMPARED WINDOWS (14z-181, rule-checker run 2026-09-25-148 Q3): the rig's P2 HP pin
        # (tools/name_moves.py, every HP_PIN_EVERY frames from the first event) writes the compared field on BOTH
        # legs, and a pin inside a compared window could erase a hit both legs took on that frame. Every pin that
        # lands inside a compared event's window is moved to the frame before the window (the pin's frame is free:
        # it exists so a projectile-fed P2 never dies); the compare below REFUSES any pin left inside one.
        ev = j["events"]
        wins = [(e["frame"], ev[k + 1]["frame"] if k + 1 < len(ev) else e["frame"] + e["gap"]) for k, e in enumerate(ev)
                if e["name"] not in ("mode activation", "mode expiry wait")]
        # (windows of one group are CONTIGUOUS — an event's window ends where the next begins — so the pin
        # steps back until it is outside EVERY compared window, which lands it inside the activation's own span)
        moved = []
        for i, pk in enumerate(j["pokes"]):
            f, addr, val = pk.split(":")
            if addr != "ff8850": continue
            g = int(f); f0 = g
            while any(lo <= g < hi for lo, hi in wins): g = min(lo for lo, hi in wins if lo <= g < hi) - 1
            if g != f0: j["pokes"][i] = f"{g}:{addr}:{val}"; moved.append([f0, g])
        j["hp_pins_moved"] = moved
        json.dump(j, open(f"{OUT}/{tenant}_{name}.json", "w"))
        print(f"{tenant}_{name}")
        if moved: print(f"HP pins moved out of compared windows: {tenant}_{name} {moved}", file=sys.stderr)
PY
) > "$W/parts.txt" 2> "$W/gen.err" || { echo "FAIL: rig generation: $(tail -1 "$W/gen.err")"; exit 1; }
PARTS="$(tr '\n' ' ' < "$W/parts.txt")"
ok "parts: $PARTS"
grep '^HP pins moved' "$W/gen.err" | sed 's/^/  ok    /' || true

echo "== 2. the legs"
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
FIELDS="ff8509:b:stock,ff802e:b:df,ff850a:w:meter,ff890a:w:p2meter,ff8850:w:p2hp,ff8854:b:p2cls,ff8782:b:id,ff8511:b:mode,ff8406:b:seq,ff8407:b:sub"
for part in $PARTS; do
    t="${part%_*}"; eval "path=\$OURS_PATH_$t"
    fr="$(python3 -c "import json;print(json.load(open('$W/$part.json'))['frames'])")"
    pk="$(python3 -c "import json;print(';'.join(json.load(open('$W/$part.json'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$fr)))")"
    awk -v path="$path" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$W/$part.ours.rpl" > "$W/$part.ours.cur.rpl"
    for leg in native ours; do
        if [ $leg = native ]; then set_=vsav2; rp="$ROMDIR"; r="$W/$part.native.rpl"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; r="$W/$part.ours.cur.rpl"; fi
        d="$W/$part.$leg"; mkdir -p "$d"
        # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
        # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
        # completed (docs/project/gotchas.md, the set -e capture entry)
        ( set +e; cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$r" POKES="$pk" FIELDS="$FIELDS" \
            FIELD_OUT="$d.ft" FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" \
            "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
          _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$d.ft" 2>/dev/null && _st=0; echo $_st > "$d/rc"; rm -rf "$d/sb" ) </dev/null &
    done
    # THE UNPINNED NATIVE LEG (14z-181, rule-checker run 2026-09-25-152 Q3): the level and RNG pins are written on
    # every frame of every window on BOTH legs; the 14z-158 ruling that introduced that method for one gate came
    # with a control that leaves the RNG unpinned and must diverge. This is that control here: one native leg of
    # UNPIN_PART with the schedule's pokes only (vsav2 then runs its own TURBO level and its own RNG), whose rows
    # must DIFFER from the pinned native's — else the pins are not load-bearing and the comparison is not the one claimed.
    if [ "$part" = "${UNPIN_PART:-huitzil_dfx2}" ]; then
        d="$W/$part.native.unpinned"; mkdir -p "$d"
        ( set +e; cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$W/$part.native.rpl" POKES="$(python3 -c "import json;print(';'.join(json.load(open('$W/$part.json'))['pokes']))")" FIELDS="$FIELDS" \
            FIELD_OUT="$d.ft" FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" \
            "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
          _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$d.ft" 2>/dev/null && _st=0; echo $_st > "$d/rc"; rm -rf "$d/sb" ) </dev/null &
    fi
done
wait
for part in $PARTS; do for leg in native ours; do _rc="$(cat "$W/$part.$leg/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$part $leg exited $_rc"; done; done
UP="${UNPIN_PART:-huitzil_dfx2}"; _rc="$(cat "$W/$UP.native.unpinned/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$UP native.unpinned exited $_rc"
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves"; exit 1; }
if [ "$CONTROL" = pins-unpinned ]; then cp "$W/$UP.native.unpinned.ft" "$W/$UP.native.ft"; echo "MODE: control pins-unpinned — $UP's native leg replaced by the one that ran with vsav2's own level and RNG"; fi
rows() {  # rows <W> <parts> [plant] -> the ev rows; a VOID on stderr exits 1; `plant` puts an HP pin inside the first compared window in memory (the pin-in-window control)
    python3 - "$1" "$2" "${3:-}" <<'PY'
import sys, json
W, parts, plant = sys.argv[1], sys.argv[2].split(), sys.argv[3] == "plant"
def load(p):
    d = {}
    for l in open(p):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
    return d
for part in parts:
    n, o = load(f"{W}/{part}.native.ft"), load(f"{W}/{part}.ours.ft")
    ids = {"donovan": 0x13, "huitzil": 0x10, "pyron": 0x11}[part.rsplit("_", 1)[0]]
    if n[2300]["id"] != ids or o[2300]["id"] != ids: sys.exit(f"VOID: {part} is not the tenant on both legs")
    J = json.load(open(f"{W}/{part}.json")); ev = J["events"]
    pins = {int(p.split(":")[0]) for p in J["pokes"]}   # EVERY rig poke, whatever it writes (14z-181, runs 2026-09-25-148/150)
    for k, e in enumerate(ev):
        lo = e["frame"]; hi = ev[k + 1]["frame"] if k + 1 < len(ev) else lo + e["gap"]
        if e["name"] not in ("mode activation", "mode expiry wait"):
            if plant: pins.add(lo + 5); plant = False
            inside = sorted(f for f in pins if lo <= f < hi)
            if inside: sys.exit(f"VOID: {part} ev{k} {e['name']}: a rig poke at {inside} inside the compared window {lo}-{hi} — a shared write on both legs (rule-checker runs 2026-09-25-148 Q3 / -150 Q4)")
        if e["name"] == "mode activation":
            for leg, d in (("native", n), ("ours", o)):
                if d[lo - 5]["stock"] - d[lo + 60]["stock"] != 1: sys.exit(f"VOID: {part} {leg} did not spend one stock at the activation {lo}")
            if not any(o[f]["df"] for f in range(lo, lo + 60)): sys.exit(f"VOID: {part} ours never raised the Dark Force flag at {lo}")
            continue
        if e["name"] == "mode expiry wait": continue
        def seqs(d):
            hits = [(d[f - 1]["p2hp"] - d[f]["p2hp"], d[f]["p2cls"]) for f in range(lo + 1, hi) if d[f]["p2hp"] < d[f - 1]["p2hp"]]
            at = [f - lo for f in range(lo + 1, hi) if d[f]["p2hp"] < d[f - 1]["p2hp"]]
            m1 = [d[f]["meter"] - d[f - 1]["meter"] for f in range(lo + 1, hi) if d[f]["meter"] != d[f - 1]["meter"]]
            m2 = [d[f]["p2meter"] - d[f - 1]["p2meter"] for f in range(lo + 1, hi) if d[f]["p2meter"] != d[f - 1]["p2meter"]]
            return hits, at, m1, m2
        a, b = seqs(n), seqs(o)
        diff = [nm for nm, x, y in (("hits", a[0], b[0]), ("p1meter", a[2], b[2]), ("p2meter", a[3], b[3])) if x != y]
        tag = "SAME" if not diff else "DIFFER(" + ",".join(diff) + ")"
        print(f"ev\t{part}\t{k}\t{e['name']}\t{tag}\tnative={a[0]}@{a[1]} m1={a[2]} m2={a[3]}\tours={b[0]}@{b[1]} m1={b[2]} m2={b[3]}")
PY
}
_pl=""; [ "$CONTROL" = pin-in-window ] && _pl=plant
rows "$W" "$PARTS" "$_pl" > "$W/got.tsv" 2> "$W/err" || bad "$(cat "$W/err")"
if [ "$CONTROL" = pin-in-window ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: pin-in-window — an HP pin inside a compared window is refused"; echo "FAIL: audit_df_moves (control mode)"; exit 1
    else echo "CONTROL DEAD: pin-in-window — the planted pin was not seen"; echo "FAIL: audit_df_moves"; exit 1; fi
fi
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves (a leg was VOID)"; exit 1; }
if rows "$W" "$PARTS" plant > /dev/null 2>&1; then echo "CONTROL DEAD: pin-in-window — an HP pin planted inside the first compared window was not seen"; fail=1
else echo "CONTROL FIRED: pin-in-window — an HP pin planted inside the first compared window is refused"; fi
# pins-unpinned, in-gate: the unpinned native leg's rows against the pinned native's, for UNPIN_PART alone
W2="$W/unpinned"; mkdir -p "$W2"; ln -sf "$W/$UP.json" "$W2/$UP.json"; ln -sf "$W/$UP.ours.ft" "$W2/$UP.ours.ft"; ln -sf "$W/$UP.native.unpinned.ft" "$W2/$UP.native.ft"
if [ "$CONTROL" != pins-unpinned ]; then
    grep "^ev	$UP	" "$W/got.tsv" | sed -E 's/@\[[0-9, ]*\]/@[]/g' > "$W2/pinned.tsv"   # the printed hit FRAMES stripped: only hits, class and gauge decide (run 2026-09-25-153 Q4)
    if rows "$W2" "$UP" 2> "$W2/void.err" | sed -E 's/@\[[0-9, ]*\]/@[]/g' > "$W2/rows.tsv" && [ -s "$W2/rows.tsv" ]; then
        if diff -q "$W2/pinned.tsv" "$W2/rows.tsv" > /dev/null; then echo "CONTROL DEAD: pins-unpinned — $UP's native leg reads the same rows with vsav2's own level and RNG as with the pins"; fail=1
        else echo "CONTROL FIRED: pins-unpinned — $UP's native leg with vsav2's own level and RNG reads $(diff "$W2/pinned.tsv" "$W2/rows.tsv" | grep -c '^>' | tr -d ' ') row(s) differently in hits, class or gauge (frames stripped), so the pins are load-bearing"; fi
    else echo "CONTROL FIRED: pins-unpinned — $UP's native leg with vsav2's own level and RNG is refused: $(head -1 "$W2/void.err")"; fi
fi
# IN THE MODE, MEASURED (14z-168, rule-checker run 2026-09-18-47 Q4): the rig's spacing is arithmetic
# (OURS_MODE = 360 + 28); that every compared event really runs inside the mode is read here — the
# P1 Change field +0x111 non-zero on BOTH legs at the event frame and at every hit frame of both legs.
# ONE reader, shared by the gate, the in-gate control and the mode; `lose` zeroes our +0x111 on the
# first event's frame in memory (what a rig that outran the mode would read).
in_mode() {  # in_mode <W> <parts> [lose]: prints the count checked, exits 1 naming any event outside
    python3 - "$1" "$2" "${3:-}" <<'PY'
import sys, json
W, parts, lose = sys.argv[1], sys.argv[2].split(), sys.argv[3] == "lose"
def load(p):
    d = {}
    for l in open(p):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
    return d
bad, n, first = [], 0, True
for part in parts:
    L = {leg: load(f"{W}/{part}.{leg}.ft") for leg in ("native", "ours")}
    ev = json.load(open(f"{W}/{part}.json"))["events"]
    for k, e in enumerate(ev):
        if e["name"] in ("mode activation", "mode expiry wait"): continue
        lo = e["frame"]; hi = ev[k + 1]["frame"] if k + 1 < len(ev) else lo + e["gap"]
        if lose and first: L["ours"][lo]["mode"] = 0; first = False
        frames = {lo} | {f for d in L.values() for f in range(lo + 1, hi) if d[f]["p2hp"] < d[f - 1]["p2hp"]}
        out = [f"{leg}@{f}" for leg, d in L.items() for f in sorted(frames) if not d[f]["mode"]]
        if out: bad.append(f"{part} ev{k} {e['name']}: +0x111 is 0 at {','.join(out)}")
        n += 1
for b in bad: print(b, file=sys.stderr)
print(n)
sys.exit(1 if bad else 0)
PY
}
if [ "$CONTROL" = mode-lost ]; then _lose=lose; else _lose=; fi
if _n="$(in_mode "$W" "$PARTS" $_lose 2> "$W/inmode.err")"; then ok "all $_n events run inside the mode on both legs (+0x111 at the event and at every hit)"
else bad "an event ran outside the mode:"; sed 's/^/        /' "$W/inmode.err"; fi
if [ "$CONTROL" = mode-lost ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: mode-lost — an event whose mode field reads 0 is refused"; echo "FAIL: audit_df_moves (control mode)"; exit 1
    else echo "CONTROL DEAD: mode-lost — the zeroed mode field was not seen"; echo "FAIL: audit_df_moves"; exit 1; fi
fi
if in_mode "$W" "$PARTS" lose > /dev/null 2>&1; then echo "CONTROL DEAD: mode-lost — zeroing our +0x111 at the first event was not seen"; fail=1
else echo "CONTROL FIRED: mode-lost — zeroing our +0x111 at the first event is refused"; fi
# P1 ACTED, MEASURED (14z-168, rule-checker run 2026-09-18-48 Q3/Q4): a compared event whose input
# produced nothing on EITHER leg would read SAME. So P1's state (+0x06 seq, +0x07 sub) must leave its
# value of two frames before the event within the event's first 60 frames on BOTH legs; ONE reader,
# shared by the gate, the in-gate control and the mode; `idle` holds our leg's state still over the
# first event's window in memory (what an input that came out on neither leg would read). For every
# event with no hit on either leg the reader also PRINTS P1's collapsed state path on both legs — the
# evidence of what the input did (not frozen: its frame phase is not a compared quantity).
acted() {  # acted <W> <parts> [idle]: prints the paths of the no-hit events, exits 1 naming an idle leg
    python3 - "$1" "$2" "${3:-}" <<'PY'
import sys, json
W, parts, idle = sys.argv[1], sys.argv[2].split(), sys.argv[3] == "idle"
def load(p):
    d = {}
    for l in open(p):
        t = l.split()
        if t and t[0] == "F": d[int(t[1])] = {k: int(v) for k, v in (kv.split("=", 1) for kv in t[2:])}
    return d
bad, first = [], True
for part in parts:
    L = {leg: load(f"{W}/{part}.{leg}.ft") for leg in ("native", "ours")}
    ev = json.load(open(f"{W}/{part}.json"))["events"]
    for k, e in enumerate(ev):
        if e["name"] in ("mode activation", "mode expiry wait"): continue
        lo = e["frame"]; hi = ev[k + 1]["frame"] if k + 1 < len(ev) else lo + e["gap"]
        if idle and first:
            for f in range(lo, lo + 60): L["ours"][f].update(seq=L["ours"][lo - 2]["seq"], sub=L["ours"][lo - 2]["sub"])
            first = False
        for leg, d in L.items():
            s0 = (d[lo - 2]["seq"], d[lo - 2]["sub"])
            if all((d[f]["seq"], d[f]["sub"]) == s0 for f in range(lo, lo + 60)):
                bad.append(f"{part} ev{k} {e['name']}: P1 never left {s0[0]:02x}/{s0[1]:02x} on {leg}")
        if not any(d[f]["p2hp"] < d[f - 1]["p2hp"] for d in L.values() for f in range(lo + 1, hi)):
            paths = []
            for leg, d in L.items():
                p = []
                for f in range(lo - 2, lo + 60):
                    v = f"{d[f]['seq']:02x}/{d[f]['sub']:02x}"
                    if not p or p[-1][1] != v: p.append((f - lo, v))
                paths.append(f"{leg} " + " ".join(f"{o}:{v}" for o, v in p))
            print(f"{part} ev{k} {e['name']} (no hit on either leg): " + " | ".join(paths))
for b in bad: print(b, file=sys.stderr)
sys.exit(1 if bad else 0)
PY
}
if [ "$CONTROL" = idle-leg ]; then _idle=idle; else _idle=; fi
if acted "$W" "$PARTS" $_idle > "$W/acted.out" 2> "$W/acted.err"; then ok "P1 acts on both legs in every compared event; the no-hit events' state paths:"; sed 's/^/        /' "$W/acted.out"
else bad "an input produced nothing on a leg:"; sed 's/^/        /' "$W/acted.err"; fi
if [ "$CONTROL" = idle-leg ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: idle-leg — an event whose P1 never acts is refused"; echo "FAIL: audit_df_moves (control mode)"; exit 1
    else echo "CONTROL DEAD: idle-leg — the held state was not seen"; echo "FAIL: audit_df_moves"; exit 1; fi
fi
if acted "$W" "$PARTS" idle > /dev/null 2>&1; then echo "CONTROL DEAD: idle-leg — holding our P1 still at the first event was not seen"; fail=1
else echo "CONTROL FIRED: idle-leg — holding our P1 still at the first event is refused"; fi

if [ -n "${CAPTURE:-}" ]; then   # PNG snapshots of the CONTACT group at its hit frames, both legs, for the maintainer's read (14z-181)
    case "$CAPTURE" in /*) ;; *) CAPTURE="$REPO/$CAPTURE" ;; esac   # the legs cd into their own dirs
    mkdir -p "$CAPTURE"
    CAPTURE_EVENTS="${CAPTURE_EVENTS:-huitzil_dfx2:*}"   # part:ev or part:* — the contact group
    CAPTURE_NAMES="${CAPTURE_NAMES:-2HP in DF}"          # semicolon-separated event NAMES captured in every part — the row 14z-181 re-froze at three hits
    for part in $PARTS; do
        _sel=""; for _s in $CAPTURE_EVENTS; do [ "${_s%%:*}" = "$part" ] && _sel="$_sel ${_s#*:}"; done
        python3 - "$W" "$part" "$_sel" "$CAPTURE_NAMES" <<'PY' > "$W/cap_$part.txt"
import sys, json, re
W, part, sel, names = sys.argv[1], sys.argv[2], sys.argv[3].split(), [n for n in sys.argv[4].split(";") if n]
ev = json.load(open(f"{W}/{part}.json"))["events"]
for l in open(f"{W}/got.tsv"):
    f = l.rstrip("\n").split("\t")
    if f[0] != "ev" or f[1] != part: continue
    k = int(f[2]); lo = ev[k]["frame"]
    if "*" not in sel and str(k) not in sel and f[3] not in names: continue
    offs = set()
    for side in (f[5], f[6]):
        m = re.search(r"@\[([0-9, ]*)\]", side)
        if m and m.group(1).strip(): offs |= {int(x) for x in m.group(1).split(",")}
    frames = sorted({lo, lo + 4} | {lo + o for o in offs} | {lo + o + 1 for o in offs} | {lo + 30})
    print(k, ",".join(str(x) for x in frames))
PY
        fr="$(python3 -c "import json;print(json.load(open('$W/$part.json'))['frames'])")"
        pk="$(python3 -c "import json;print(';'.join(json.load(open('$W/$part.json'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$fr)))")"
        while read -r k frames; do
            [ -n "$frames" ] || continue
            for leg in native ours; do
                if [ $leg = native ]; then set_=vsav2; rp="$ROMDIR"; r="$W/$part.native.rpl"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; r="$W/$part.ours.cur.rpl"; fi
                d="$W/cap_${part}_${k}_$leg"; mkdir -p "$d"
                ( set +e; cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$r" POKES="$pk" SNAP_FRAMES="$frames" FRAMES="$((${frames##*,} + 1))" \
                    TRACE_OUT="$d/snap.txt" "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" > "$d/mame.log" 2>&1
                  i=0; for f in $(echo "$frames" | tr ',' ' '); do src="$(ls "$d/sb/snap/$set_/"*.png 2>/dev/null | sed -n "$((i + 1))p")"; [ -n "$src" ] && cp "$src" "$CAPTURE/${part}_ev${k}_${leg}_f${f}.png"; i=$((i + 1)); done
                  rm -rf "$d/sb" ) </dev/null &
            done
        done < "$W/cap_$part.txt"
        wait
    done
    ok "captures: $(ls "$CAPTURE"/*.png 2>/dev/null | wc -l | tr -d ' ') PNGs under $CAPTURE"
fi

echo "== 3b. how the forms LOOK: Pyron's palette, Donovan's sword (14z-168, the maintainer's questions on the captures)"
# The captures (build/p136_14z168/cap_dfx_*) showed Pyron's form in what looked like another palette
# at f2700, and Donovan's sword in another pose. Measured, and ruled identical by the maintainer
# (2026-09-18, DECISIONS_HISTORY.md, the 14z-168 captures entry): the pieces in Pyron's area use OBJ
# palettes 0x0a/0x0b, whose 16 colours are identical on both legs (the idle loop is at another phase
# at 2690-2710; the pieces realign inside the 5LP by 2730); Donovan's sword (P1's projectile slot 0,
# type 0x3d) is NOT RNG-driven (a second RNG seed leaves each leg's node sequence unchanged), its
# idle loop starts 10 frames later natively (3215 vs 3205), its 5HP flight path is identical and its
# spin angle follows the idle phase. OBJ dumps: tests/lua/sprite_capture.lua (read-only).
spr() {  # spr <name> <set> <rompath> <rpl> <pokes> <frames list> <max frame>   (background)
    mkdir -p "$W/$1"
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" DUMP_FRAMES="$6" FRAMES="$7" \
        TRACE_OUT="$W/$1.spr" "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/sprite_capture.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q '^OBJDUMPSUMMARY' "$W/$1.spr" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
# THE SWORD WINDOW IS ANCHORED TO THE 5HP EVENT (14z-181): until then it was the literal 3200-3361, the frames the
# 14z-168 schedule put the 5HP at; one event per activation moved every event, so the window is [T5-115, T5+46).
T5="$(python3 -c "import json;print(next(e['frame'] for e in json.load(open('$W/donovan_dfx1.json'))['events'] if e['name']=='5HP in DF'))")"
# THE SWORD WINDOWS CARRY NO SCHEDULE WRITE (14z-181, rule-checker run 2026-09-25-153 Q1): the 5HP's own x pins land
# at T5-40 (tools/name_moves.py: both fighters, both legs), so the idle-hold search stops at T5-41, the flight and
# the RNG count start at T5, and any schedule poke inside [T5-114, T5-41) or [T5, T5+46) is a VOID.
sword_clear() {  # sword_clear <json> <T5> [plant]: exits 1 naming any schedule poke inside a sword window; `plant` adds one in memory (the control)
    python3 - "$1" "$2" "${3:-}" <<'PY'
import sys, json
J, T5, plant = json.load(open(sys.argv[1])), int(sys.argv[2]), sys.argv[3] == "plant"
pokes = list(J["pokes"]) + ([f"{T5 + 10}:ff8850:01200120"] if plant else [])
inside = sorted(p for p in pokes if (T5 - 114 <= int(p.split(":")[0]) < T5 - 41) or (T5 <= int(p.split(":")[0]) < T5 + 46))
if inside: sys.exit(f"VOID: schedule poke(s) inside the sword windows [T5-114,T5-41) / [T5,T5+46): {inside}")
PY
}
_sp=""; [ "$CONTROL" = sword-poke-planted ] && _sp=plant
if sword_clear "$W/donovan_dfx1.json" "$T5" "$_sp"; then ok "no schedule poke inside the sword windows [T5-114,T5-41) / [T5,T5+46) (T5 = $T5)"
else bad "$(sword_clear "$W/donovan_dfx1.json" "$T5" "$_sp" 2>&1)"; fi
if [ "$CONTROL" = sword-poke-planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: sword-poke-planted — a schedule poke planted inside the sword window is refused"; echo "FAIL: audit_df_moves (control mode)"; exit 1
    else echo "CONTROL DEAD: sword-poke-planted — the planted poke was not seen"; echo "FAIL: audit_df_moves"; exit 1; fi
fi
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves (a schedule poke inside a sword window)"; exit 1; }
if sword_clear "$W/donovan_dfx1.json" "$T5" plant > /dev/null 2>&1; then echo "CONTROL DEAD: sword-poke-planted — a poke planted at T5+10 inside the sword window was not seen"; fail=1
else echo "CONTROL FIRED: sword-poke-planted — a poke planted at T5+10 inside the sword window is refused"; fi
[ -n "${FORM_EXTRA_POKES:-}" ] && echo "  PROBE  FORM_EXTRA_POKES in effect on the form legs: $FORM_EXTRA_POKES"
for part in pyron_dfx1 donovan_dfx1; do
    fr="$(python3 -c "import json;print(json.load(open('$W/$part.json'))['frames'])")"
    base="$(python3 -c "import json;print(';'.join(json.load(open('$W/$part.json'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))")"
    if [ $part = pyron_dfx1 ]; then FL="2690,2700,2710,2730"; MX=2735; SEEDS="0000"; else FL="$(python3 -c "print(','.join(str(f) for f in range($T5-115,$T5+46)))")"; MX=$((T5+46)); SEEDS="0000 1234"; fi
    for seed in $SEEDS; do
        pks="$base;$(python3 -c "print(';'.join(f'{f}:ff80d4:$seed' for f in range(2363,$MX)))")${FORM_EXTRA_POKES:+;$FORM_EXTRA_POKES}"   # FORM_EXTRA_POKES: a PROBE knob for attributing a form-row change to a rig write (never set in a gated run)
        spr "$part.native.$seed" vsav2  "$ROMDIR" "$W/$part.native.rpl" "$pks" "$FL" "$MX"
        spr "$part.ours.$seed"   vsavjw "$BUILD/rompath;$ROMDIR" "$W/$part.ours.cur.rpl" "$pks" "$FL" "$MX"
    done
done
wait
for r in pyron_dfx1.native.0000 pyron_dfx1.ours.0000 donovan_dfx1.native.0000 donovan_dfx1.ours.0000 donovan_dfx1.native.1234 donovan_dfx1.ours.1234; do
    _rc="$(cat "$W/$r/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$r exited $_rc and wrote no OBJDUMPSUMMARY"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves (a sprite dump was VOID)"; exit 1; }
# THE RNG IS READ in the sword's window (rule-checker run 2026-09-18-49 Q4: a pin that never reaches
# the RNG would make "seed-independent" vacuous): a read tap on the RNG word $FF80D4 over the 5HP flight window [T5, T5+45] on
# both legs (seed 0000) counts the reads; each leg must read it. tests/audit_entrance_draw.sh shows the
# same pin SELECTING a draw on vsav2 and on ours.
for leg in native ours; do
    if [ $leg = native ]; then set_=vsav2; rp="$ROMDIR"; r="$W/donovan_dfx1.native.rpl"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; r="$W/donovan_dfx1.ours.cur.rpl"; fi
    fr="$(python3 -c "import json;print(json.load(open('$W/donovan_dfx1.json'))['frames'])")"
    pks="$(python3 -c "import json;print(';'.join(json.load(open('$W/donovan_dfx1.json'))['pokes']))");$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$T5+46)))")${FORM_EXTRA_POKES:+;$FORM_EXTRA_POKES}"
    mkdir -p "$W/rng.$leg"
    ( set +e; cd "$W/rng.$leg" && MAME_SANDBOX="$W/rng.$leg/sb" MAME_ROMPATH="$rp" REPLAY="$r" POKES="$pks" RTAP=ff80d4,2 \
        WINDOW=$T5,$((T5+45)) FRAMES=$((T5+46)) TRACE_OUT="$W/rng.$leg.tap" \
        "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/rng.$leg/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$W/rng.$leg.tap" 2>/dev/null && _st=0; echo $_st > "$W/rng.$leg/rc"; rm -rf "$W/rng.$leg/sb" ) </dev/null &
done
wait
for leg in native ours; do _rc="$(cat "$W/rng.$leg/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "rng tap $leg exited $_rc and wrote no END"; done
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves (an RNG tap was VOID)"; exit 1; }
# ONE reducer: the form rows. `blind` compares our palette page with NATIVE's own (what a read that
# did not reach our palette RAM would compare) — the palette-blind control's perturbation.
form_reduce() {  # form_reduce <W> [blind]
    python3 - "$1" "${2:-}" <<'PY'
import sys, re, collections
W, blind = sys.argv[1], sys.argv[2] == "blind"
def load(name):
    ent, pal, obj = collections.defaultdict(list), {}, collections.defaultdict(dict)
    for l in open(f"{W}/{name}.spr"):
        if l.startswith("F"):
            m = re.match(r"F(\d+) B0 E\d+ x=(\w+) y=(\w+) code=\w+ attr=\w+ pal=(\w+)", l)
            if m: ent[int(m.group(1))].append((int(m.group(2), 16) & 0x3ff, int(m.group(3), 16) & 0x3ff, int(m.group(4), 16)))
        elif l.startswith("P"):
            fr, hx = l.split(); pal[int(fr[1:])] = bytes.fromhex(hx)
        elif l.startswith("O"):
            m = re.match(r"O(\d+) pool=p slot=0 type=3d x=(\d+) y=(\d+) node=(\w+)", l)
            if m: obj[int(m.group(1))] = (int(m.group(4), 16), int(m.group(2)), int(m.group(3)))
    return ent, pal, obj
pn, po = load("pyron_dfx1.native.0000"), load("pyron_dfx1.ours.0000")
if blind: po = (po[0], pn[1], po[2])
# THE PALETTE PAGE: tests/lua/sprite_capture.lua dumps 4 KB at $90C000 (atlas ram.md), read here as 32-byte
# palettes indexed by an OBJ entry's attr palette number (the layout tools/sprite_render.py draws with).
# Pyron's AREA: OBJ x 90..260, y 64..223 — below the HUD rows (the life bars, palette 0x00, reach y 56)
# and before f2742, where the "FIRST ATTACK" banner (HUD text, palette 0x02, y 88) is drawn over him.
box = lambda x, y: 90 <= x <= 260 and 64 <= y <= 223
hudrow = lambda y: y < 64 or y >= 224
for fr in (2690, 2700, 2710, 2730):
    diff = {p for p in range(32) if pn[1][fr][p * 32: p * 32 + 32] != po[1][fr][p * 32: p * 32 + 32]}
    inb = [(x, y, p) for e in (pn[0][fr], po[0][fr]) for x, y, p in e if box(x, y)]
    if not inb: sys.exit(f"VOID: no OBJ pieces in Pyron's area at f{fr}")
    used = sorted({p for _, _, p in inb})
    ndiff = sum(1 for _, _, p in inb if p in diff)
    same_pos = sorted(t for t in pn[0][fr] if box(t[0], t[1])) == sorted(t for t in po[0][fr] if box(t[0], t[1]))
    print(f"form\tpyron\tf{fr}\tpalettes={','.join(f'{p:02x}' for p in used)}\tdiffering_pieces={ndiff}\tpieces={'same' if same_pos else 'moved'}")
    # THE COMPARISON'S LIVENESS: every palette whose colours differ, and those among them with pieces in the HUD
    # ROWS (y < 64 or >= 224): the life bars (0x00) and the HUD text are there, and so is one native stage object
    hud = sorted({p for e in (pn[0][fr], po[0][fr]) for x, y, p in e if hudrow(y)} & diff)
    print(f"form\tpalettes_differing\tf{fr}\tall={','.join(f'{p:02x}' for p in sorted(diff)) or 'none'}\tin_hud_rows={','.join(f'{p:02x}' for p in hud) or 'none'}")
S = {k: load(f"donovan_dfx1.{k}")[2] for k in ("native.0000", "ours.0000", "native.1234", "ours.1234")}
for leg in ("native", "ours"):
    a, b = S[f"{leg}.0000"], S[f"{leg}.1234"]
    if not a: sys.exit(f"VOID: no sword object on {leg}")
    print(f"sword\tdonovan\t{leg}\tseed_independent={'yes' if a == b else 'NO'}")
nat, our = S["native.0000"], S["ours.0000"]
import json as _json
T5 = next(e["frame"] for e in _json.load(open(f"{W}/donovan_dfx1.json"))["events"] if e["name"] == "5HP in DF")
def loop_start(s):   # the start of the idle loop's 21-frame hold of one node, in the 100 frames before the 5HP
    run = 0
    for f in range(T5 - 114, T5 - 41):   # before the 5HP's own x pin at T5-40
        run = run + 1 if s[f][0] == s[f - 1][0] else 0
        if run == 20: return f - 20
    return None
hn, ho = loop_start(nat), loop_start(our)
if hn is None or ho is None: sys.exit("VOID: the sword's 21-frame idle hold was not found on a leg")
print(f"sword\tdonovan\tidle_hold_starts\tnative=5hp{hn - T5:+d}\tours=5hp{ho - T5:+d}\toffset={hn - ho}")
first_x = next((f for f in range(T5, T5 + 46) if nat[f][1] != our[f][1]), None)
first_y = next((f for f in range(T5, T5 + 46) if nat[f][2] != our[f][2]), None)
ys = sorted({nat[f][2] for f in range(T5, T5 + 46)} | {our[f][2] for f in range(T5, T5 + 46)})
print(f"sword\tdonovan\tflight_x\tsame_from_5hp_to=+{((first_x - 1) if first_x else T5 + 45) - T5}\tfirst_px_diff={('+%d' % (first_x - T5)) if first_x else None}")
print(f"sword\tdonovan\tflight_y\tfirst_diff={first_y}\tvalues={','.join(map(str, ys))}")
for leg in ("native", "ours"):
    n = sum(1 for l in open(f"{W}/rng.{leg}.tap") if l.startswith("R "))
    print(f"sword\tdonovan\trng_reads_5hp_window\t{leg}={n}")
PY
}
form_reduce "$W" > "$W/form.tsv" 2> "$W/form.err" || bad "form: $(cat "$W/form.err")"
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves (the form rows were VOID)"; exit 1; }
# ONE set of checks, run on the real rows, on each control's perturbed rows, and in each control's mode
form_checks() {  # form_checks <rows>: exits 1 naming the first failed check
    awk -F'\t' '$1=="form" && $2=="pyron" && $5!="differing_pieces=0" {exit 1}' "$1" || { echo "a piece in Pyron's area is drawn with a palette that differs between the legs"; return 1; }
    awk -F'\t' '$1=="form" && $2=="palettes_differing" && $5=="in_hud_rows=none" {exit 1}' "$1" || { echo "no palette drawing in the HUD rows is seen differing — the palette comparison is blind"; return 1; }
    awk -F'\t' '$1=="sword" && $4 ~ /^seed_independent/ && $4!="seed_independent=yes" {exit 1}' "$1" || { echo "the sword's animation depends on the RNG seed"; return 1; }
    awk -F'\t' '$1=="sword" && $3=="rng_reads_5hp_window" {split($4, a, "="); if (a[2] + 0 == 0) exit 1}' "$1" || { echo "a leg never reads the RNG in the sword's window — the seed test is vacuous"; return 1; }
}
form_moved() {  # Pyron's colours reported different at f2730
    awk -F'\t' 'BEGIN{OFS="\t"} $1=="form" && $2=="pyron" && $3=="f2730" {$5="differing_pieces=17"} {print}' "$1" > "$2"
}
rng_dead() {  # the RNG never read on our leg
    awk -F'\t' 'BEGIN{OFS="\t"} $1=="sword" && $3=="rng_reads_5hp_window" && $4 ~ /^ours=/ {$4="ours=0"} {print}' "$1" > "$2"
}
case "$CONTROL" in
    form-moved)    form_moved "$W/form.tsv" "$W/form.p" && mv "$W/form.p" "$W/form.tsv" ;;
    rng-dead)      rng_dead "$W/form.tsv" "$W/form.p" && mv "$W/form.p" "$W/form.tsv" ;;
    palette-blind) form_reduce "$W" blind > "$W/form.p" 2>/dev/null && mv "$W/form.p" "$W/form.tsv" ;;
esac
sed 's/^/  /' "$W/form.tsv"
if _why="$(form_checks "$W/form.tsv")"; then ok "the form rows: no differing palette in Pyron's area, the HUD-row palettes seen differing, the sword seed-independent with the RNG read on both legs"
else bad "$_why"; fi
cat "$W/form.tsv" >> "$W/got.tsv"
case "$CONTROL" in form-moved|rng-dead|palette-blind)
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $CONTROL — the form checks refuse the perturbed rows"; echo "FAIL: audit_df_moves (control mode)"; exit 1
    else echo "CONTROL DEAD: $CONTROL"; echo "FAIL: audit_df_moves"; exit 1; fi ;;
esac
form_moved "$W/form.tsv" "$W/ctl_f1.tsv"; rng_dead "$W/form.tsv" "$W/ctl_f2.tsv"; form_reduce "$W" blind > "$W/ctl_f3.tsv" 2>/dev/null
for c in form-moved:ctl_f1 rng-dead:ctl_f2 palette-blind:ctl_f3; do
    if _w="$(form_checks "$W/${c#*:}.tsv")"; then echo "CONTROL DEAD: ${c%%:*} — the perturbed rows passed"; fail=1
    else echo "CONTROL FIRED: ${c%%:*} — $_w"; fi
done
drop_hit() { python3 - "$1" "$2" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1])]
done = False
with open(sys.argv[2], "w") as o:
    for r in rows:
        if not done and r[0] == "ev" and r[6].startswith("ours=[(") :
            r[6] = "ours=[]" + r[6][r[6].index("]") + 1:]; done = True
        o.write("\t".join(r) + "\n")
PY
}
if [ "$CONTROL" = hit-dropped ]; then drop_hit "$W/got.tsv" "$W/got.hd" && mv "$W/got.hd" "$W/got.tsv"; fi
ok "$(grep -c '^ev' "$W/got.tsv" | tr -d ' ') in-DF events; $(awk -F'\t' '$5=="SAME"' "$W/got.tsv" | grep -c . || true) SAME, $(awk -F'\t' '$5=="DIFFER(p1meter)"' "$W/got.tsv" | grep -c . || true) differing only in P1's gauge, $(awk -F'\t' '$1=="ev" && $5!="SAME" && $5!="DIFFER(p1meter)"' "$W/got.tsv" | grep -c . || true) other"
awk -F'\t' '$1=="ev" && $5!="SAME" && $5!="DIFFER(p1meter)" {print "        " $2 " ev" $3 " " $4 ": " $5}' "$W/got.tsv"

# THE FREEZE COMES LAST AND IS REFUSED ON ANY RED (14z-181, rule-checker run 2026-09-25-149 Q4: until then the
# block sat before the hit-dropped control and never read $fail, so a run with an event outside the mode, an idle
# leg, a failed form check or a DEAD control would still have frozen).
drop_hit "$W/got.tsv" "$W/ctl.tsv"
if diff -q "$W/got.tsv" "$W/ctl.tsv" > /dev/null; then echo "CONTROL DEAD: hit-dropped — no hit to drop"; fail=1
else echo "CONTROL FIRED: hit-dropped — dropping one of our hits changes $(diff "$W/got.tsv" "$W/ctl.tsv" | grep -c '^<' | tr -d ' ') row"; fi
if [ "${FREEZE:-0}" = 1 ] && [ -z "$CONTROL" ]; then
    if [ "$fail" != 0 ]; then echo "REFUSED FREEZE: a check failed or a control was DEAD above — nothing written"; echo "FAIL: audit_df_moves"; exit 1; fi
    { echo "# tests/expected/df_moves.tsv — the tenants' in-DF moves, ours (Dark Force Change, P+K; $(basename "$BUILD")) vs native vsav2 (the tenant's"
      echo "# vs2 EX install), ordered hits (damage, P2 class) and gauge steps per event (tests/audit_df_moves.sh; field_trace)."
      echo "# Evidence class: in-emulator. Frozen 14z-168 with FREEZE=1 (GitHub #136). The gauge rows are frozen AS MEASURED (#157's"
      echo "# Dark Force tail: our tenants' start-up gauge in the mode); a fix re-freezes this file DELIBERATELY. Since 14z-168 also the"
      echo "# form rows (section 3b): Pyron's palettes in his area, Donovan's sword (RNG independence, idle phase, flight x)."
      echo "# Re-frozen 14z-181 (rule-checker runs 2026-09-25-148/149): the CONTACT group (huitzil_dfx2, #109's folded leg) and"
      echo "# donovan_dfx1 ev25 (2HP in DF) at three hits, with every rig HP pin moved out of the compared windows (the shared-pin"
      echo "# gotcha); runs 2026-09-25-150..155 moved the sword windows past the 5HP x pin and re-anchored them (see the sword rows)."
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
[ -n "${GOT_OUT:-}" ] && cp "$W/got.tsv" "$GOT_OUT"   # the measured rows, for an attribution by (part, event name) when the indices moved
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows ($(grep -c '^[<>]' "$W/diff.txt" | tr -d ' ') diff lines; GOT_OUT=<file> keeps the measured rows)"; sed 's/^/        /' "$W/diff.txt" | head -10; fi
if [ "$CONTROL" = hit-dropped ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: hit-dropped — our rows missing an altered attack's hit lose the frozen rows"; echo "FAIL: audit_df_moves (control mode)"; exit 1
    else echo "CONTROL DEAD: hit-dropped — the rewrite changed nothing"; echo "FAIL: audit_df_moves"; exit 1; fi
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_df_moves"; else echo "FAIL: audit_df_moves"; exit 1; fi
