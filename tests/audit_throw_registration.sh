#!/bin/sh
# audit_throw_registration.sh — THE HIT-REGISTRATION PAIR AT A TENANT THROW, ours vs native, frozen: on every tenant throw contact native's throw code writes the engine's (attacker, victim) registration pair right before the generic hit stager awards meter. Through M19 our placed copies of those stores wrote vs2's displacements (dead on vsavj), so the vsavj stager read the collision pass's leftover pair reversed — the attacker got the victim's flat 8 and the victim the throw record's meter, the mechanism behind GitHub #136's meter-fraction family (14z-166). Since M20 (14z-183, #157) the stores are re-pointed at vsavj's live pair and ours pays like native; the gate freezes that.
#
# WHAT: the hit-registration pair at a tenant throw, ours vs native: native's throw code
#   writes the engine's (attacker, victim) pair before the generic hit stager awards meter.
#   Through M19 our placed copies wrote vs2's displacements (dead on vsavj), so the stager
#   read the collision pass's leftover pair reversed — the attacker got the flat 8 and the
#   victim the record's meter (#136's meter family, #157); the legacy control shows both
#   engines register the pair, so it was a port defect. Since M20 (14z-183) the stores are
#   re-pointed at vsavj's live pair.
# HOW: read taps on MAME over the live pair, the dead pair and both meters for pyron_3,
#   huitzil_3 and donovan_5 (7 tap runs each, the parity gate's rig and pins) and the legacy
#   Demitri-throws-Victor part on pristine vsavj and vs2 with real picks; contact rows,
#   writer rows and the legacy ids frozen; controls swap the P1/P2 steps, plant a reader of
#   the dead pair, and plant a second write on a contact frame.
# EXPECTS: the frozen rows — since the 14z-183 re-freeze ours pays like native (p1=record
#   p2=+8), the defect rows (ours p1=+8 p2=record) live in the file's git history; no in-play
#   reader of the dead pair, the legacy legs paying the attacker the record on both engines;
#   all three controls fail.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/throw_registration.tsv
#   tests/lua/read_tap.lua tests/replays/ tools/name_moves.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: legs-swapped — a copy of our reduced rows with the P1 and P2 meter steps swapped (the fixed shape) must FAIL the frozen compare (in-gate: the perturbed copy is diffed against the frozen rows and must differ; mode: the real rows are swapped and the gate FAILs)
# MUST-FIRE: perturbed-copy: dead-reader-planted — a copy of our dead-pair tap with ONE in-play read planted at a game PC must add a reader row and FAIL the frozen compare (in-gate: the planted copy is reduced and must differ; mode: the real tap is planted and the gate FAILs)
# MUST-FIRE: perturbed-copy: double-write — a copy of our first part's P1 meter tap with a SECOND write planted on its first contact frame (the same value, a game PC) must print the `/2w` marker and FAIL the frozen compare, so the frozen rows' one-write reading is something the reducer can refuse and not merely a marker that never printed (in-gate: the planted copy is reduced and must differ from the frozen rows and carry /2w; mode: the P1 meter tap of every ours leg is planted and the table FAILs) — added 14z-167 on rule-checker run 2026-09-18-41 Q4
#
# WHY. tests/expected/move_parity_events.tsv froze 28 DIFF rows whose first differing
# field is `meter`, every one at a tenant THROW contact or downstream of one. The
# mechanism, measured 14z-166 (build/meter_probe_14z166, rule-checker runs
# 2026-09-17-30/31): the generic hit stager (vs2 0x172F2, vsavj 0x18980) awards the
# record's +0x14 to the fighter registered at A5-0x4B74 (vs2) / A5-0x4BC6 (vsavj)
# and a flat 8 to the one at A5-0x4B72 / A5-0x4BC4. Native's throw code writes that
# pair (attacker, victim) at vs2 0x289C6/0x289CA and 0x28A94/0x28A98 on the contact
# frame; each tenant's x028122 copy carries those stores UNRECONCILED by design (the
# 14x rollback of the 14v fix, build/manifest/donovan.toml stage-99 rows), so on ours
# they write RAM:$FF348C-F — on vsavj two words of a hit-value ring PRG:0x0194AE shifts
# (trigger unmeasured; no ported instruction reads them, and no reader but the boot
# RAM test fired in these rigs) — and the vsavj stager
# reads its own pair at RAM:$FF343A-D — written in play only by the per-frame
# collision registration (vsavj 0x17FF8/0x18000), whose last write before the throw's
# damage call leaves (P2, P1). The three parts cover one tenant each and both throw
# kinds Phobos has (ground and the Sky Capture air throw). Pyron's air throw (Galactic
# Throw) was not produced by the Demitri-P2 rig until 14z-181 fixed the shared air_throw
# recipe (#169, P2's jump lead); since then pyron_3 carries it (f5182, f5602) on both legs —
# the frozen rows did not see it until the 14z-183 re-freeze (docs/project/gotchas.md "A RIG
# CHANGE RE-FROZEN IN THE GATES IT WAS MADE FOR LEAVES EVERY OTHER GATE ... STALE").
#
# THE LEGACY CONTROL — the maintainer, 2026-09-18, in their own words: "correct me if I'm wrong but that measurement could give us an answer because if legacy characters exhibit the same behaviour this is a nothing burger but if they don't that at least tells us what it is not"
# and "the values are quite widly different, we really need that control you're doing with a legacy character". The same taps on a LEGACY throw —
# Demitri (0x01) throws Victor (0x03), tests/replays/judge/02_throw.rpl, the tenant-throw
# audit's all-legacy leg — on PRISTINE vsavj and on vsav2. Real cursor picks on both games (no id poke), the ids
# tapped and frozen. Both engines register the
# pair at their own throw site (vsavj 0x029694/98, vs2 0x0289C6/CA) and pay the
# attacker the record (+9) and the victim +8: the host engine's rule IS vs2's, so
# the tenant rows above are a port defect, not an engine-generation difference.
# Part `legacy_demitri`, legs `vsavj` and `native`.
#
# WHAT IT FREEZES, per part and leg (tests/expected/throw_registration.tsv):
#   ids rows (legacy part only) — both fighters' id bytes as the last pre-match byte write left them, with the
#     writer's PC (real picks; a write with any mask but ff00 is the neighbour byte and is skipped);
#   contact rows — every frame with a throw-site write of that leg's LIVE pair from
#     a non-collision PC (native: vs2's pair at its throw sites; ours: vsavj's pair
#     from the placed copies' re-pointed stores) or, on ours, of the dead vs2 pair
#     (the unfixed stores — the M19-and-earlier shape; 14z-183 widened the rule so
#     one reducer reads both), with the P1 and P2 meter steps on that frame. Frozen
#     14z-166..182 as THE DEFECT (ours p1=+8 p2=record); RE-FROZEN 14z-183 on the
#     #157 fix (M20): ours pays the attacker the record like native;
#   writer rows — the non-collision writer PCs of the engine's live pair
#     (native: the throw sites; ours: none) and, on ours, the writer and reader PC
#     sets of the dead vs2 pair (readers: the boot RAM test only).
# The rig, pokes (rig + speed level 6 + RNG) and both players' real cursor routes are
# tests/audit_move_parity.sh's, copied here; every tap is tests/lua/read_tap.lua,
# non-debug, so frames are replay-exact; a tap log without END is VOID, never read.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged28] [PARTS="pyron_3 huitzil_3 donovan_5 legacy_demitri"] [FREEZE=1] tests/audit_throw_registration.sh
#   emulator tier, MAME; ~3 min (7 tap runs per part, in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged28}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/throw_registration.tsv"
CONTROL="${CONTROL:-}"
PARTS="${PARTS:-pyron_3 huitzil_3 donovan_5 legacy_demitri}"
FLOOR=2300
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|legs-swapped|dead-reader-planted|double-write) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
R="$REPO/tests/replays/naming"
# --- the rig as tests/audit_move_parity.sh builds it (pokes_for / rpl_for / OURS_PATH, copied) ---
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
pokes_for() {  # pokes_for <json> <frames>
    _b="$(python3 -c "import json;print(';'.join(json.load(open('$1'))['pokes']))")"
    _l="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$2)))")"
    _r="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$2)))")"
    printf '%s;%s;%s' "$_b" "$_l" "$_r"
}
rpl_for() {  # rpl_for <tenant> <rig.rpl> <leg> <out.rpl>
    if [ "$3" = native ]; then cp "$2" "$4"; return; fi
    eval "_path=\$OURS_PATH_$1"
    awk -v path="$_path" '
        /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$2" > "$4"
}
tap() {  # tap <name> <set> <rompath> <rpl> <pokes> <frames> <rtap> <out.txt>   (background)
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$6" \
        RTAP="$7" WINDOW="0,$6" TRACE_OUT="$8" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$1/mame.log" 2>&1
      rm -rf "$W/$1/sb" ) </dev/null &
}
# ONE reducer, shared by the gate and both control modes ([VSP-181]): tap logs -> rows
reduce() {  # reduce <part> <leg> <meter_p1.txt> <meter_p2.txt> <pair.txt> <dead.txt|-> -> rows on stdout
    python3 - "$@" "$FLOOR" <<'PY'
import sys
part, leg, mp1, mp2, pair, dead, floor = sys.argv[1:8]; floor = int(floor)
def lines(p, kind):
    out = []
    ended = False
    for l in open(p):
        t = l.split()
        if not t: continue
        if t[0] == "END": ended = True
        if t[0] == kind: out.append((int(t[1]), t[3], int(t[7], 16)))
    if not ended: sys.exit(f"VOID: {p} has no END line (a dead tap is not evidence)")
    return out
COLLISION = {"017ff8", "018000", "016870", "016878"}   # the per-frame collision registration, vsavj / vs2
THROW = {"0289c6", "0289ca", "028a94", "028a98"}      # vs2's throw-site stores (native) — ours' placed twins are found by frame
pw = [x for x in lines(pair, "W") if x[0] >= floor and x[1] not in COLLISION]
# a contact is a frame with a non-collision write to the leg's LIVE pair (native: vs2's throw sites; ours since the
# 14z-183 fix: the placed copies' re-pointed stores) — and, on ours, also a frame with a write to the DEAD vs2 pair (the
# unfixed placed stores, M19 and earlier), so one rule reads a fixed and an unfixed build alike
contacts = sorted({f for f, pc, v in pw} | ({f for f, pc, v in lines(dead, "W") if f >= floor} if leg == "ours" else set()))
def steps(p):
    # the FRAME's net change of the meter word: the deltas of every write on that frame summed (a contact frame
    # with two writes — a swing and a hit — reads as their sum; the count of writes is kept for the row)
    prev, st, n = None, {}, {}
    for f, pc, v in lines(p, "W"):
        if prev is not None and f >= floor: st[f] = st.get(f, 0) + (v - prev); n[f] = n.get(f, 0) + 1
        prev = v
    return st, n
(s1, n1), (s2, n2) = steps(mp1), steps(mp2)
def fmt(d, n): return (f"{d:+d}" + (f"/{n}w" if n > 1 else "")) if d is not None else "none"
for f in contacts:
    # the meter's net change on the contact frame (a stock crossing wraps by 0x90 — the raw signed sum is reported);
    # `/Nw` marks a frame with more than one write to that meter word
    print(f"{part}\t{leg}\tcontact\t{f}\tp1={fmt(s1.get(f), n1.get(f, 0))}\tp2={fmt(s2.get(f), n2.get(f, 0))}")
print(f"{part}\t{leg}\tlive-pair-writers\t-\t{','.join(sorted({pc for f,pc,v in pw})) or '-'}\t-")
if part.startswith("legacy_"):
    import os
    base = os.path.dirname(mp1); pre = os.path.basename(mp1).replace(".m1.txt", "")
    def last_id(p):
        # the id is a BYTE at an even address: the tap reports the 16-bit word, mask ff00 for a byte store to it and
        # ffff for a word (or long) store covering it — both count (14z-167, rule-checker run 2026-09-18-41 Q1: the
        # filter was ==ff00 and dropped word stores); mask 00ff is a store to the NEIGHBOUR (+0x383) alone, skipped;
        # the writer PC is kept with the value
        ws = []
        for l in open(p):
            t = l.split()
            if t and t[0] == "W" and int(t[1]) < floor and int(t[9], 16) & 0xff00:
                ws.append(f"{(int(t[7], 16) >> 8) & 0xff:02x}@{t[3]}")
        if not any(l.startswith("END") for l in open(p)): sys.exit(f"VOID: {p} has no END line")
        return ws[-1] if ws else "none"
    print(f"{part}\t{leg}\tids\t-\tp1={last_id(os.path.join(base, pre + '.id1.txt'))}\tp2={last_id(os.path.join(base, pre + '.id2.txt'))}")
if leg == "ours":
    dw = sorted({pc for f, pc, v in lines(dead, "W") if f >= floor})
    dr = sorted({pc for f, pc, v in lines(dead, "R")})
    print(f"{part}\t{leg}\tdead-pair-writers\t-\t{','.join(dw) or '-'}\t-")
    print(f"{part}\t{leg}\tdead-pair-readers\t-\t{','.join(dr) or '-'}\t-")
PY
}
# the two perturbations, ONE function each (the control section and the mode both call them)
swap_legs()   { awk -F'\t' 'BEGIN{OFS="\t"} $3=="contact" {t=$5; $5=$6; $6=t; sub(/^p2=/,"p1=",$5); sub(/^p1=/,"p2=",$6)} {print}' "$1"; }
plant_double(){ awk -v f="$(awk -F'\t' '$3=="contact"{print $4; exit}' "$1")" '{print} $1=="W" && $2==f && !d {d=1; $4="0189a0"; print}' "$2"; }   # plant_double <rows> <meter tap> -> the tap with its contact-frame write doubled
plant_reader(){ awk -v f="$FLOOR" '{print} /^END/ && !d {d=1} 1==0' "$1"; printf 'R %d PC 0189a0 off ff348c data 00008400 mask 0000ffff\n' "$((FLOOR + 800))" >> "$2"; }

echo "== 1. the taps, both legs, per part"
legs_of() { case "$1" in legacy_*) echo "vsavj native" ;; *) echo "native ours" ;; esac; }
for p in $PARTS; do
    case "$p" in legacy_demitri)
        fr=3450; r="$REPO/tests/replays/judge/02_throw.rpl"
        # REAL picks, no id poke: P1's default cell is Demitri 0x01 and P2's R,R is Victor 0x03 on BOTH wheels
        # (tools/select_paths.py --resolve on the decoded vsavj and vsav2 wheels, 14z-166); the ids are TAPPED and frozen
        pk="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$fr)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$fr)))")"
        tap "$p.j.m1" vsavj "$ROMDIR" "$r" "$pk" "$fr" ff850a,2 "$W/$p.vsavj.m1.txt"
        tap "$p.j.m2" vsavj "$ROMDIR" "$r" "$pk" "$fr" ff890a,2 "$W/$p.vsavj.m2.txt"
        tap "$p.j.pr" vsavj "$ROMDIR" "$r" "$pk" "$fr" ff343a,4 "$W/$p.vsavj.pair.txt"
        tap "$p.j.i1" vsavj "$ROMDIR" "$r" "$pk" "$fr" ff8782,2 "$W/$p.vsavj.id1.txt"
        tap "$p.j.i2" vsavj "$ROMDIR" "$r" "$pk" "$fr" ff8b82,2 "$W/$p.vsavj.id2.txt"
        tap "$p.n.m1" vsav2 "$ROMDIR" "$r" "$pk" "$fr" ff850a,2 "$W/$p.native.m1.txt"
        tap "$p.n.m2" vsav2 "$ROMDIR" "$r" "$pk" "$fr" ff890a,2 "$W/$p.native.m2.txt"
        tap "$p.n.pr" vsav2 "$ROMDIR" "$r" "$pk" "$fr" ff348c,4 "$W/$p.native.pair.txt"
        tap "$p.n.i1" vsav2 "$ROMDIR" "$r" "$pk" "$fr" ff8782,2 "$W/$p.native.id1.txt"
        tap "$p.n.i2" vsav2 "$ROMDIR" "$r" "$pk" "$fr" ff8b82,2 "$W/$p.native.id2.txt"
        continue ;;
    esac
    t="${p%_*}"; j="$R/$p.json"; r="$R/$p.rpl"
    [ -f "$j" ] && [ -f "$r" ] || { bad "$p: no naming rig $j / $r"; continue; }
    fr="$(python3 -c "import json;print(json.load(open('$j'))['frames'])")"
    pk="$(pokes_for "$j" "$fr")"
    rpl_for "$t" "$r" native "$W/$p.native.rpl"; rpl_for "$t" "$r" ours "$W/$p.ours.rpl"
    ORP="$BUILD/rompath;$ROMDIR"
    tap "$p.o.m1" vsavjw "$ORP"    "$W/$p.ours.rpl"   "$pk" "$fr" ff850a,2 "$W/$p.ours.m1.txt"
    tap "$p.o.m2" vsavjw "$ORP"    "$W/$p.ours.rpl"   "$pk" "$fr" ff890a,2 "$W/$p.ours.m2.txt"
    tap "$p.o.pr" vsavjw "$ORP"    "$W/$p.ours.rpl"   "$pk" "$fr" ff343a,4 "$W/$p.ours.pair.txt"
    tap "$p.o.dd" vsavjw "$ORP"    "$W/$p.ours.rpl"   "$pk" "$fr" ff348c,4 "$W/$p.ours.dead.txt"
    tap "$p.n.m1" vsav2  "$ROMDIR" "$W/$p.native.rpl" "$pk" "$fr" ff850a,2 "$W/$p.native.m1.txt"
    tap "$p.n.m2" vsav2  "$ROMDIR" "$W/$p.native.rpl" "$pk" "$fr" ff890a,2 "$W/$p.native.m2.txt"
    tap "$p.n.pr" vsav2  "$ROMDIR" "$W/$p.native.rpl" "$pk" "$fr" ff348c,4 "$W/$p.native.pair.txt"
done
wait
: > "$W/got.tsv"
for p in $PARTS; do
    for leg in $(legs_of "$p"); do
        for f in m1 m2 pair; do [ -s "$W/$p.$leg.$f.txt" ] || { bad "$p $leg: tap $f produced nothing"; continue 2; }; done
        dead="-"
        if [ "$leg" = ours ]; then
            dead="$W/$p.ours.dead.txt"; [ -s "$dead" ] || { bad "$p ours: the dead-pair tap produced nothing"; continue; }
            if [ "$CONTROL" = dead-reader-planted ]; then plant_reader "$dead" "$dead"; fi
        fi
        if ! reduce "$p" "$leg" "$W/$p.$leg.m1.txt" "$W/$p.$leg.m2.txt" "$W/$p.$leg.pair.txt" "$dead" > "$W/$p.$leg.rows" 2> "$W/$p.$leg.err"; then
            bad "$p $leg: $(cat "$W/$p.$leg.err")"; continue
        fi
        if [ "$CONTROL" = legs-swapped ] && [ "$leg" = ours ]; then swap_legs "$W/$p.$leg.rows" > "$W/$p.$leg.sw" && mv "$W/$p.$leg.sw" "$W/$p.$leg.rows"; fi
        if [ "$CONTROL" = double-write ] && [ "$leg" = ours ]; then
            plant_double "$W/$p.$leg.rows" "$W/$p.$leg.m1.txt" > "$W/$p.$leg.m1.dbl"
            reduce "$p" "$leg" "$W/$p.$leg.m1.dbl" "$W/$p.$leg.m2.txt" "$W/$p.$leg.pair.txt" "$dead" > "$W/$p.$leg.rows" 2>> "$W/$p.$leg.err" || bad "$p $leg: the double-write reduction failed"
        fi
        cat "$W/$p.$leg.rows" >> "$W/got.tsv"
        ok "$p $leg: $(grep -c 'contact' "$W/$p.$leg.rows" | tr -d ' ') throw contacts — $(awk -F'\t' '$3=="contact"{printf "%s:%s/%s ", $4, $5, $6}' "$W/$p.$leg.rows")"
    done
done
[ "$fail" = 0 ] || { echo "FAIL: audit_throw_registration (a leg did not run or was VOID)"; exit 1; }

echo "== 2. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/throw_registration.tsv — the hit-registration pair at every tenant throw contact, ours vs native"
        echo "# (tests/audit_throw_registration.sh; tests/lua/read_tap.lua, non-debug). Evidence class: in-emulator (MAME,"
        echo "# native vsav2 and the WIDE build $(basename "$BUILD"); frames >= $FLOOR). Frozen 14z-166 with FREEZE=1 on the"
        echo "# defect (ours p1=+8 p2=<record> where native read p1=<record> p2=+8 — GitHub #136's meter family, #157);"
        echo "# RE-FROZEN 14z-183 on the #157 fix (M20: the placed copies' pair stores re-pointed at vsavj's live pair), with"
        echo "# its rule-checker run named in the commit. A new dead-pair READER or WRITER on ours is a finding; a contact"
        echo "# frame that moves means the rig moved — re-derive before re-freezing."
        echo "# Columns: part, leg, kind (contact | live-pair-writers | dead-pair-writers | dead-pair-readers), frame, a, b"
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
for p in $PARTS; do for leg in $(legs_of "$p"); do
    awk -F'\t' -v p="$p" -v l="$leg" '!/^#/ && $1==p && $2==l' "$EXPECT" > "$W/$p.$leg.want"
    if diff "$W/$p.$leg.want" "$W/$p.$leg.rows" > "$W/$p.$leg.diff"; then ok "$p $leg: as frozen"
    else bad "$p $leg: differs from the frozen rows"; sed 's/^/        /' "$W/$p.$leg.diff"; fi
done; done

echo "== 3. must-fire controls"
if [ "$CONTROL" = legs-swapped ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: legs-swapped — the swapped steps lose the frozen rows"; echo "FAIL: audit_throw_registration (control mode)"; exit 1
    else echo "CONTROL DEAD: legs-swapped — the swapped steps still matched"; echo "FAIL: audit_throw_registration"; exit 1; fi
fi
if [ "$CONTROL" = dead-reader-planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: dead-reader-planted — the planted in-play reader is a new row"; echo "FAIL: audit_throw_registration (control mode)"; exit 1
    else echo "CONTROL DEAD: dead-reader-planted — the planted reader was not seen"; echo "FAIL: audit_throw_registration"; exit 1; fi
fi
if [ "$CONTROL" = double-write ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: double-write — a second write on a contact frame prints /2w and loses the frozen rows"; echo "FAIL: audit_throw_registration (control mode)"; exit 1
    else echo "CONTROL DEAD: double-write — the doubled write still matched"; echo "FAIL: audit_throw_registration"; exit 1; fi
fi
first="$(echo $PARTS | awk '{print $1}')"
swap_legs "$W/$first.ours.rows" > "$W/ctl.sw"
if diff -q "$W/$first.ours.want" "$W/ctl.sw" > /dev/null; then echo "CONTROL DEAD: legs-swapped — swapping P1/P2 steps on $first ours still matches the frozen rows"; fail=1
else echo "CONTROL FIRED: legs-swapped — a copy of $first ours with P1/P2 steps swapped differs from the frozen rows"; fi
cp "$W/$first.ours.dead.txt" "$W/ctl.dead"; plant_reader "$W/ctl.dead" "$W/ctl.dead"
if reduce "$first" ours "$W/$first.ours.m1.txt" "$W/$first.ours.m2.txt" "$W/$first.ours.pair.txt" "$W/ctl.dead" > "$W/ctl.rows" 2>/dev/null && ! diff -q "$W/$first.ours.want" "$W/ctl.rows" > /dev/null; then
    echo "CONTROL FIRED: dead-reader-planted — one planted in-play read of the dead pair adds a reader row on $first ours"
else echo "CONTROL DEAD: dead-reader-planted — the planted read changed nothing"; fail=1; fi
plant_double "$W/$first.ours.rows" "$W/$first.ours.m1.txt" > "$W/ctl.m1"
if reduce "$first" ours "$W/ctl.m1" "$W/$first.ours.m2.txt" "$W/$first.ours.pair.txt" "$W/$first.ours.dead.txt" > "$W/ctl.dbl" 2>/dev/null \
   && grep -q '/2w' "$W/ctl.dbl" && ! diff -q "$W/$first.ours.want" "$W/ctl.dbl" > /dev/null; then
    echo "CONTROL FIRED: double-write — a second write planted on $first ours' first contact frame prints $(grep -o '[+-][0-9]*/2w' "$W/ctl.dbl" | head -1) and differs from the frozen rows"
else echo "CONTROL DEAD: double-write — the planted second write was not seen"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_throw_registration"; else echo "FAIL: audit_throw_registration"; exit 1; fi
