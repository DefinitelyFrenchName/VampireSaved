#!/bin/sh
# audit_df_moves.sh — THE TENANTS' MOVES INSIDE THEIR DARK FORCE, ours (Dark Force Change, P+K) vs native (the vs2 personal-Dark-Force EX install), frozen AS MEASURED (14z-168, GitHub #136): every in-DF event of the #136 naming schedules re-run inside a mode that is ENTERED on both legs, compared by its ORDERED hits (damage, P2 reaction class) and gauge steps — all 29 events match in hits and damage but for the known remaps; the gauge differs by the two ruled rules.
#
# MUST-FIRE: perturbed-copy: mode-lost — our Change field +0x111 zeroed at the first compared event's frame (what a rig that outran the mode would read) must be refused by the in-mode check, so every compared event is MEASURED inside the mode on both legs, not assumed from the rig's spacing (in-gate: the zeroed copy must fail the check; mode: our field is zeroed before the check and the gate FAILs)
# MUST-FIRE: perturbed-copy: idle-leg — our P1 state held still over the first compared event's window (what an input that produced nothing would read) must be refused by the acted check, so no SAME row can be two legs agreeing on nothing (in-gate: the held copy must fail the check; mode: our state is held before the check and the gate FAILs)
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
# 2623+PP — measured; the canonical inputs are the maintainer's to confirm), the moves
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
# ($FF8116) and RNG ($FF80D4) pins. The two globals mean the same on vsav2: the level is the play
# mode tests/audit_move_parity.sh's unpinned-level control shows governing the native leg, and
# the RNG seed selects vsav2's own draws in tests/expected/entrance_draw.tsv.
# WHAT IT DOES NOT SHOW: that the named move came out AS that move. The acted check proves P1
# acts on both legs, and the printed state paths show what it did: measured 14z-168, the two
# Killshread [LK] inputs enter the kick state 0x0A on both legs, not the special. A jump
# normal's attack is not told apart from the jump itself. An L button's swing cost is 0
# (docs/game/atlas/ram.md +0x10A), so the no-hit L rows have no gauge step whether or not the
# attack came out.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [FREEZE=1] tests/audit_df_moves.sh
#   emulator tier, MAME; 10 legs in parallel — measured 14z-168 on this MacBook, solo: ~40 s wall
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/df_moves.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|hit-dropped|mode-lost|idle-leg) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== 1. the rigs (the in-DF events of the #136 schedules, per-leg activation)"
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
for tenant, srcs in SRC.items():
    groups, cur, used = [], [], 0
    for part, evs in srcs:
        for k in evs:
            e = nm.SCHEDULES[tenant][part][k]
            if cur and (used + e[2] > OURS_MODE - G_ACT - 10 or len(cur) == 2):
                groups.append(cur); cur, used = [], 0
            cur.append(e); used += e[2]
    if cur: groups.append(cur)
    parts, p, span = [], [], 0
    for g in groups:
        if p and span + GROUP_SPAN > 7000: parts.append(p); p, span = [], 0
        p.append(g); span += GROUP_SPAN
    if p: parts.append(p)
    for i, pg in enumerate(parts, 1):
        name = f"dfx{i}"
        for leg, act in (("native", EX[tenant]), ("ours", PK)):
            sched = []
            for g in pg:
                sched.append(("mode activation", act, G_ACT, "far"))
                for e in g: sched.append((e[0], e[1], e[2], "far"))
                sched.append(("mode expiry wait", [], GROUP_SPAN - G_ACT - sum(e[2] for e in g), "far"))
            nm.SCHEDULES[tenant][name] = sched
            with contextlib.redirect_stdout(io.StringIO()):
                nm.gen(tenant, name, f"{OUT}/{tenant}_{name}.{leg}.rpl", f"{OUT}/{tenant}_{name}.{leg}.json")
        j = json.load(open(f"{OUT}/{tenant}_{name}.ours.json"))
        for e in j["events"]:
            if e["name"] == "mode activation": j["pokes"].append(f"{e['frame'] - 10}:ff8509:09")
        json.dump(j, open(f"{OUT}/{tenant}_{name}.json", "w"))
        print(f"{tenant}_{name}")
PY
) > "$W/parts.txt" 2> "$W/gen.err" || { echo "FAIL: rig generation: $(tail -1 "$W/gen.err")"; exit 1; }
PARTS="$(tr '\n' ' ' < "$W/parts.txt")"
ok "parts: $PARTS"

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
done
wait
for part in $PARTS; do for leg in native ours; do _rc="$(cat "$W/$part.$leg/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "$part $leg exited $_rc"; done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves"; exit 1; }
python3 - "$W" "$PARTS" > "$W/got.tsv" 2> "$W/err" <<'PY' || bad "$(cat "$W/err")"
import sys, json
W, parts = sys.argv[1], sys.argv[2].split()
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
    ev = json.load(open(f"{W}/{part}.json"))["events"]
    for k, e in enumerate(ev):
        lo = e["frame"]; hi = ev[k + 1]["frame"] if k + 1 < len(ev) else lo + e["gap"]
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
[ "$fail" = 0 ] || { echo "FAIL: audit_df_moves (a leg was VOID)"; exit 1; }
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

if [ "${FREEZE:-0}" = 1 ]; then
    { echo "# tests/expected/df_moves.tsv — the tenants' in-DF moves, ours (Dark Force Change, P+K; merged-m18) vs native vsav2 (the tenant's"
      echo "# vs2 EX install), ordered hits (damage, P2 class) and gauge steps per event (tests/audit_df_moves.sh; field_trace)."
      echo "# Evidence class: in-emulator. Frozen 14z-168 with FREEZE=1 (GitHub #136). The gauge rows are frozen AS MEASURED (#157's"
      echo "# Dark Force tail: our tenants' start-up gauge in the mode); a fix re-freezes this file DELIBERATELY."
      echo "#--"; cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt" | head -10; fi
if [ "$CONTROL" = hit-dropped ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: hit-dropped — our rows missing an altered attack's hit lose the frozen rows"; echo "FAIL: audit_df_moves (control mode)"; exit 1
    else echo "CONTROL DEAD: hit-dropped — the rewrite changed nothing"; echo "FAIL: audit_df_moves"; exit 1; fi
fi
drop_hit "$W/got.tsv" "$W/ctl.tsv"
if diff -q "$W/got.tsv" "$W/ctl.tsv" > /dev/null; then echo "CONTROL DEAD: hit-dropped — no hit to drop"; fail=1
else echo "CONTROL FIRED: hit-dropped — dropping one of our hits changes $(diff "$W/got.tsv" "$W/ctl.tsv" | grep -c '^<' | tr -d ' ') row"; fi
if [ "$fail" = 0 ]; then echo "PASS: audit_df_moves"; else echo "FAIL: audit_df_moves"; exit 1; fi
