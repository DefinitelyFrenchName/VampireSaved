#!/bin/sh
# audit_chains174.sh — THE TENANTS' ONCE NEVER-ENTERED a2 ATTACK CHAINS, ENTERED ON NATIVE AND COMPARED WITH OURS (GitHub #174, 14z-184).
#
# WHAT: the eight a2 chains of the three tenants that carry attack records and that no naming
#   rig entered (#174's census, 36 never-entered starts, 8 with attack records): Phobos's Reflect
#   Wall from a crouching block (a2:0x4b) and from an air block (a2:0x4d), his Genocide Vulcan
#   (ES) catching a jump-in (a2:0x50 then a2:0x29), Donovan's ES pursuit connecting after Sword
#   Grapple (a2:0x4f), Pyron's Piled Hell with three kicks (a2:0x48) and his 6MP and 6HP at range
#   (a2:0x03, a2:0x05) — each rig first proven to ENTER its chain on native vs2, then compared
#   ours against native event by event.
# HOW: the rigs are tools/chains174_rigs.py's (built with tools/name_moves.py's machinery, kept
#   OUTSIDE the naming corpus in tests/replays/chains174/, maintainer-ruled 2026-09-27 "Dedicated
#   gate (Recommended)"); each tenant's rig on MAME on native vs2 and on the merged WIDE build as
#   the parity gate runs them (real cursor picks, level 6 from 2000, the RNG from the match
#   anchor); the native trace read against the chain graph decoded from the tenant's vs2 extract
#   (tools/name_moves.py analyse); the two traces compared per event by tools/move_parity.py.
# EXPECTS: the committed rigs equal a regeneration; every event enters its TARGET chain(s) on
#   native; every rig pin of x, stock and P2 HP lands on its listed frame on both legs; the
#   per-event rows equal tests/expected/chains174.tsv; every control fails.
# THE RIG'S OWN PINS (maintainer-ruled 2026-09-27, 14z-185: "OBSERVES + both checks"): the three
#   poke read-back rows of this gate (x ff8410, stock ff8509, P2 HP ff8850, tests/expected/
#   poke_readback.tsv) are OBSERVES — the comparator skips each field's own pin frames and reads
#   stock and P2 HP as frame-to-frame changes, so what it compares is the game's change after the
#   pin. That rests on two things this gate now checks: the pins LAND on their listed frames (the
#   frames the exclusion removes), and the exclusion is live on all three fields (pins-ignored).
#   What it cannot see: each event after a pin starts from the rig's shared position BY DESIGN, and
#   a verdict reports only the FIRST difference of its window (measured 14z-185, build/agent185/poke5:
#   no pin in a compared window erased a difference before the comparator read it).
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/chains174.tsv
#   tests/lib/controls.sh tests/lib/decrypt_cache.sh tests/lua/field_trace.lua
#   tests/replays/chains174/ tools/anim_nodes.py tools/build_fingerprint.py tools/chains174_rigs.py
#   tools/move_parity.py tools/name_moves.py tools/run_mame.sh tools/setup_mame.sh
#
# MUST-FIRE: perturbed-copy: wrong-target — the entry check run with every event's target replaced by a chain the rig never enters (a:0x7f) must report MISSING for every event, so "enters its target" is something the check can refuse (in-gate: the first tenant's events, each must read MISSING; mode: every tenant's targets replaced, and the gate FAILs)
# MUST-FIRE: perturbed-copy: order-swapped — the entry check run with every multi-chain target REVERSED (Genocide Vulcan's a2:0x50 then a2:0x29 read as a2:0x29 then a2:0x50) must report those events MISSING, so the check reads the ORDER of the entered chains, not only their presence (in-gate: the first tenant's multi-chain events; mode: every tenant's multi-chain targets reversed, and the gate FAILs) — added 14z-184 on rule-checker run 2026-09-25-308 Q4
# MUST-FIRE: perturbed-copy: pins-ignored — a copy of OUR trace altered on exactly the rig's own pin frames of ONE field (x +7 on each pin frame; stock +1 and P2 HP -5 as a step from each pin frame on) must leave every verdict as the real run under the pin exclusion and move at least one with the exclusion off, so the exclusion is proven live on all three pinned fields (in-gate: every tenant, each of the three fields; mode: every tenant's ours altered on all three fields and compared with the exclusion off, and the table FAILs) — added 14z-185
# MUST-FIRE: perturbed-copy: pins-shifted — the landing check reading every pin one frame EARLY must fail and read no pin as landing on its listed frame, so "lands on its listed frame" is something the check can refuse (in-gate: every tenant; mode: every tenant's pins read one frame early, and the gate FAILs) — added 14z-185
# MUST-FIRE: perturbed-copy: x-moved — a copy of OUR trace with x moved by +3 on ONE frame ten frames into every event must turn every event DIFF on x, so an IDENT row is proven to rest on the compared x path (in-gate: the first tenant; mode: every tenant's ours trace perturbed, and the table FAILs)
#
# THE SETUPS, AND WHERE THEY CAME FROM. Each is the static reading of vs2's command handler for
# that chain (build/agent184/t174_hypotheses.md), confirmed by the probes build/agent184/t174/p1-p6
# at vs2's default play mode before this gate re-checks it at level 6: Reflect Wall picks a2:0x4d
# when P1 is airborne (+0x38), a2:0x4b when the crouch flag +0x121 is set, else the standing
# a2:0x4c the naming rigs reach; Genocide Vulcan's ES version (+0x102 = 6) takes a2:0x50 when the
# trap has caught the opponent; the ES pursuit takes a2:0x4f on contact with a live victim; Piled
# Hell takes a2:0x48 when the button-pair index +0x107 = 6 (all three kicks); a2:0x03/0x05 are
# Pyron's 6+button attacks. Donovan's ES pursuit connects only off Sword Grapple — the maintainer,
# 2026-09-27: "it connects after 63214+MP/HP but not after regular throw (4/6+MP/HP)".
#
# NOT COVERED: the other 28 never-entered a2 starts (no attack record); the never-entered chains
# of tables a, b and c; P2 as the tenant; the ES pursuit's KKK/PP inputs and Sword Grapple [MP]; the NON-ZERO random
# path — the RNG pin 0000 is the routine's fixed point, every draw 0 (#183, kept as the basis 2026-09-30; with
# RNG_WORD=0100 the 14 parity rows read as at 0000, measured 14z-186 by audit_rng_forms).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] [DON=build/don_m27 HUI=build/hui61 PYR=build/pyron46] [FREEZE=1] [KEEP=<dir>] [RNG_WORD=0100] [RNG_UNTIL=2600] tests/audit_chains174.sh
#   RNG_WORD / RNG_UNTIL (#183, 14z-186): a PROBE knob, as audit_move_parity's; FREEZE=1 refuses either
#   emulator tier, MAME; ~2 min (6 legs in parallel)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
[ -n "${FREEZE:-}" ] && { [ -n "${RNG_WORD:-}" ] || [ -n "${RNG_UNTIL:-}" ]; } && { echo "REFUSED: FREEZE=1 with the RNG_WORD/RNG_UNTIL probe knob (#183) — the expectation is frozen at the 0000 pin only"; exit 3; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged31}"; case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
DON="${DON:-build/don_m27}"; HUI="${HUI:-build/hui61}"; PYR="${PYR:-build/pyron46}"
EXPECT="$REPO/tests/expected/chains174.tsv"
RIGS="$REPO/tests/replays/chains174"
TENANTS="huitzil donovan pyron"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
[ -f "$BUILD/patch/placements.json" ] || { echo "SKIP: no placements.json at $BUILD"; exit 0; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi   # KEEP=<dir> keeps the traces
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
# the parity gate's field list, pins and ours cursor path (tests/audit_move_parity.sh, copied)
FIELDS="ff841c:l:node,ff8420:b:cnt,ff8406:b:seq,ff8407:b:sub,ff8509:b:stock,ff8410:w:x,ff8414:w:y,ff8450:w:p1hp,ff8782:b:id,ff802e:b:df,ff840b:b:face,ff8116:b:lvl,ff850a:w:meter,ff8850:w:p2hp,ff8852:w:p2white,ff8452:w:p1white,ff881c:l:p2node,ff8b82:b:p2id"
OURS_PATH_donovan="D D DR DR"; OURS_PATH_huitzil="D D D"; OURS_PATH_pyron="D D D D"
extract_of() { case "$1" in donovan) echo "$DON/extract" ;; huitzil) echo "$HUI/extract" ;; pyron) echo "$PYR/extract" ;; esac; }

echo "== 1. the committed rigs equal a regeneration"
for t in $TENANTS; do
    python3 tools/chains174_rigs.py gen "$t" "$W/$t.rpl" "$W/$t.json" > /dev/null || { bad "$t: gen"; continue; }
    if cmp -s "$W/$t.rpl" "$RIGS/${t}_c174.rpl" && cmp -s "$W/$t.json" "$RIGS/${t}_c174.json"; then ok "$t: rig as committed"
    else bad "$t: tests/replays/chains174/${t}_c174.* drifted from tools/chains174_rigs.py — regenerate"; fi
done
[ "$fail" = 0 ] || { echo "FAIL: audit_chains174"; exit 1; }

echo "== 2. the legs (native vs2 and ours, parity pins), and the chain graphs"
# the build under test, named by its program fingerprint (rule-checker run 2026-09-28-389: a row read with no build named is a premise)
echo "  build under test: $BUILD — program fingerprint $(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath;$ROMDIR" --set vsavjw --sha-only 2>/dev/null | cut -c1-8)"
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
    fr="$(python3 -c "import json;print(json.load(open('$RIGS/${t}_c174.json'))['frames'])")"
    base="$(python3 -c "import json;print(';'.join(json.load(open('$RIGS/${t}_c174.json'))['pokes']))")"
    pins="$(python3 -c "print(f'{2000}-{($fr)-1}:ff8116:06' + ';' + f'{2363}-{(${RNG_UNTIL:-$fr})-1}:ff80d4:${RNG_WORD:-0000}')")"
    eval "cur=\$OURS_PATH_$t"
    cp "$RIGS/${t}_c174.rpl" "$W/$t.native.rpl"
    awk -v p="$cur" '
        /^1104-1106 p2=R$/ && !done { n = split(p, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$RIGS/${t}_c174.rpl" > "$W/$t.ours.rpl"
    for leg in native ours; do
        if [ "$leg" = native ]; then set_=vsav2; rp="$ROMDIR"; else set_=vsavjw; rp="$BUILD/rompath;$ROMDIR"; fi
        mkdir -p "$W/$t.$leg"
        ( cd "$W/$t.$leg" && MAME_SANDBOX="$W/$t.$leg/sb" MAME_ROMPATH="$rp" REPLAY="$W/$t.$leg.rpl" POKES="$base;$pins" \
            FIELDS="$FIELDS" FIELD_OUT="$W/tr_$t.$leg.txt" FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" \
            "$REPO/tools/run_mame.sh" "$set_" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$t.$leg/mame.log" 2>&1
          rm -rf "$W/$t.$leg/sb" ) </dev/null &
    done
done
wait
for t in $TENANTS; do for leg in native ours; do
    command grep -q FIELDSUMMARY "$W/tr_$t.$leg.txt" 2>/dev/null || bad "$t $leg: no complete trace (see $t.$leg/mame.log)"
done; done
[ "$fail" = 0 ] || { echo "FAIL: audit_chains174"; exit 1; }

# the entry check: every event's target chains among the chains its native window entered
entry() {  # entry <tenant> [wrong|swap] -> rows "entry <t> <k> <name> <target> ENTERED|MISSING:<chains>" (a multi-chain target must be entered IN ORDER)
    python3 tools/name_moves.py analyse "$RIGS/$1_c174.json" "$W/tr_$1.native.txt" "$W/chains_$1" --json "$W/an_$1.json" > /dev/null 2>&1 || { echo "entry $1 - - - VOID"; return; }
    python3 - "$1" "$W/an_$1.json" "${2:-}" <<'PY'
import json, sys
sys.path.insert(0, "tools")
import chains174_rigs as c
t, an, wrong = sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3]
for k, e in enumerate(an["events"]):
    if e["name"] not in c.TARGET:   # a spacer (tools/chains174_rigs.py): no target, never counted
        print(f"entry\t{t}\t{k}\t{e['name']}\t-\tSPACER"); continue
    tgt = ("a:0x7f" if wrong == "wrong" else c.TARGET[e["name"]]).split()
    if wrong == "swap": tgt = tgt[::-1]
    got = [x["chain"] for x in e.get("entered", [])]
    # the targets as an ORDERED subsequence of the entered chains; a target not reached in order is missing
    miss, i = [], 0
    for g in tgt:
        j = next((n for n in range(i, len(got)) if got[n] == g), None)
        if j is None: miss.append(g)
        else: i = j + 1
    print(f"entry\t{t}\t{k}\t{e['name']}\t{' '.join(tgt)}\t" + ("ENTERED" if not miss else "MISSING:" + ",".join(miss)))
PY
}
perturb_x() {  # perturb_x <schedule.json> <trace in> <trace out> — x +3 on one frame ten frames into every event
    python3 - "$1" "$2" "$3" <<'PY'
import json, sys
at = {e["frame"] + 10 for e in json.load(open(sys.argv[1]))["events"]}
with open(sys.argv[2]) as fi, open(sys.argv[3], "w") as fo:
    for line in fi:
        f = line.split()
        if len(f) >= 3 and f[0] == "F" and int(f[1]) in at:
            line = " ".join(("x=%d" % (int(v[2:]) + 3)) if v.startswith("x=") else v for v in f) + "\n"
        fo.write(line)
PY
}
parity() {  # parity <tenant> <ours trace> [--no-pin-exclusion] -> the comparator's per-event rows
    fe="$(python3 -c "import json;print(json.load(open('$RIGS/$1_c174.json'))['events'][0]['frame'])")"
    python3 tools/move_parity.py events "$1" c174 "$W/tr_$1.native.txt" "$2" "$BUILD/patch/placements.json" \
        --first-event "$fe" --events "$RIGS/$1_c174.json" ${3:-} 2>/dev/null || true
}
# perturb_pins <schedule.json> <field> <trace in> <trace out> — OUR trace altered on exactly the frames the rig pins
# that field (the pins-ignored control's copy, [VSP-181]: one function, the control and the mode): x +7 on each pin
# frame; stock +1 and p2hp -5 as a STEP from each pin frame on, which is what a pin does to a cumulative field (the
# comparator reads those two as frame-to-frame changes, so only the pin frame's change differs). field "all" applies
# the three in turn. Prints how many frames were altered.
perturb_pins() {
    python3 - "$@" <<'PY'
import json, sys
sched, which, src, dst = sys.argv[1:5]
F = {"x": ("ff8410", 7, False), "stock": ("ff8509", 1, True), "p2hp": ("ff8850", -5, True)}
pokes = json.load(open(sched))["pokes"]
lines = open(src).read().splitlines(keepends=True); n = 0
for fld in (F if which == "all" else [which]):
    addr, d, cum = F[fld]; pins = sorted({int(p.split(":")[0]) for p in pokes if p.split(":")[1].lower() == addr})
    for i, line in enumerate(lines):
        t = line.split()
        if len(t) >= 3 and t[0] == "F":
            k = sum(1 for p in pins if p <= int(t[1])) if cum else int(int(t[1]) in pins)
            if k:
                lines[i] = " ".join(f"{fld}={int(v.split('=')[1]) + d * k}" if v.startswith(fld + "=") else v for v in t) + "\n"; n += 1
open(dst, "w").writelines(lines); print(n)
PY
}
# landing <tenant> [shift] -> where each rig pin of x/stock/p2hp LANDS, read from both legs' traces with no comparator:
# per pin "pin <t> <leg> <field> <frame> <value> AT-F|UNKNOWN|LATE+n|NEVER" (UNKNOWN: F f-1 already held the value, so
# the landing cannot be read), then per (field, leg) "landsum <t> <field> <leg> at-f N unknown N late N never N".
# shift moves every listed pin frame (the pins-shifted control reads them one frame EARLY). Exit 1 on any LATE/NEVER,
# or a (field, leg) with no pin read AT-F (a check that can read no landing is not a check).
landing() {
    python3 - "$RIGS/$1_c174.json" "$W/tr_$1.native.txt" "$W/tr_$1.ours.txt" "$1" "${2:-0}" <<'PY'
import json, sys, collections
sched, nat, ours, t, shift = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5])
FIELD = {"ff8410": "x", "ff8509": "stock", "ff8850": "p2hp"}
def val(addr, h):
    v = int(h[:2], 16) if addr == "ff8509" else int(h[:4], 16)
    return v - 0x10000 if addr == "ff8410" and v & 0x8000 else v
def load(p):
    d = {}
    for l in open(p):
        s = l.split()
        if s and s[0] == "F": d[int(s[1])] = {k: int(v) for k, v in (kv.split("=") for kv in s[2:])}
    return d
sums = collections.defaultdict(collections.Counter); bad = 0
for leg, path in (("native", nat), ("ours", ours)):
    d = load(path)
    for p in json.load(open(sched))["pokes"]:
        f, addr, h = p.split(":")
        if addr.lower() not in FIELD: continue
        fld, v, f = FIELD[addr.lower()], val(addr.lower(), h), int(f) + shift
        if f - 1 not in d: c = "NEVER"
        elif d[f - 1][fld] == v: c = "UNKNOWN"
        else:
            g = next((g for g in range(f, f + 60) if g in d and d[g][fld] == v), None)
            c = "NEVER" if g is None else ("AT-F" if g == f else f"LATE+{g - f}")
        sums[(fld, leg)][c.split("+")[0]] += 1; bad += c.startswith(("LATE", "NEVER"))
        print(f"pin\t{t}\t{leg}\t{fld}\t{f}\t{v}\t{c}")
for fld in ("x", "stock", "p2hp"):
    for leg in ("native", "ours"):
        s = sums[(fld, leg)]; bad += s["AT-F"] == 0
        print(f"landsum\t{t}\t{fld}\t{leg}\tat-f {s['AT-F']} unknown {s['UNKNOWN']} late {s['LATE']} never {s['NEVER']}")
sys.exit(1 if bad else 0)
PY
}

echo "== 3. native enters every target, and ours vs native per event"
: > "$W/got.tsv"
for t in $TENANTS; do
    if vs_ctl_is wrong-target; then entry "$t" wrong >> "$W/got.tsv"; elif vs_ctl_is order-swapped; then entry "$t" swap >> "$W/got.tsv"; else entry "$t" >> "$W/got.tsv"; fi
    ours="$W/tr_$t.ours.txt"
    if vs_ctl_is x-moved; then perturb_x "$RIGS/${t}_c174.json" "$ours" "$W/tr_$t.ours.pert.txt"; ours="$W/tr_$t.ours.pert.txt"; fi
    # the pins-ignored MODE: every tenant's ours perturbed on all three fields' pin frames, compared with the exclusion off
    if vs_ctl_is pins-ignored; then perturb_pins "$RIGS/${t}_c174.json" all "$ours" "$W/tr_$t.ours.pins.txt" > /dev/null
        parity "$t" "$W/tr_$t.ours.pins.txt" --no-pin-exclusion | sed 's/^/parity\t/' >> "$W/got.tsv"
    else parity "$t" "$ours" | sed 's/^/parity\t/' >> "$W/got.tsv"; fi
done
sed 's/^/  | /' "$W/got.tsv"
n_miss="$(command grep -c '	MISSING' "$W/got.tsv" || true)"; n_void="$(command grep -c '	VOID$' "$W/got.tsv" || true)"
if [ "$n_miss" = 0 ] && [ "$n_void" = 0 ]; then ok "every event entered its target on native ($(command grep '^entry' "$W/got.tsv" | command grep -vc '	SPACER$') events, spacers apart)"
else bad "$n_miss event(s) did not enter their target on native, $n_void void"; fi
# the rig's own pins (x, stock, P2 HP) land ON their listed frame on both legs — the premise of the pin exclusion,
# which skips exactly those frames (maintainer-ruled 2026-09-27, 14z-185: the three poke read-back rows OBSERVES,
# "OBSERVES + both checks"). The pins-shifted MODE reads every pin one frame early, and the check FAILs.
_sh=0; vs_ctl_is pins-shifted && _sh=-1
: > "$W/landing.txt"; lf=0
for t in $TENANTS; do landing "$t" "$_sh" >> "$W/landing.txt" || lf=1; done
command grep '^landsum' "$W/landing.txt" | sed 's/^/  | /'
if [ "$lf" = 0 ]; then ok "every observable rig pin of x, stock and P2 HP lands on its listed frame, both legs ($(command grep -c '	AT-F$' "$W/landing.txt") read, $(command grep -c '	UNKNOWN$' "$W/landing.txt") already held)"
else bad "a rig pin did not land on its listed frame, or a (field, leg) had none readable:"; command grep -E '	(LATE|NEVER)' "$W/landing.txt" | head -10 | sed 's/^/        /'; command grep -E '^landsum.*at-f 0 ' "$W/landing.txt" | sed 's/^/        /'; fi
if [ "${FREEZE:-0}" = 1 ]; then
    [ -z "${VS_CTL:-}" ] || { echo "REFUSED: FREEZE=1 in control mode"; exit 3; }
    [ "$fail" = 0 ] || { echo "REFUSED: FREEZE=1 on a failing entry check"; exit 3; }
    { sed -n '/^#/p' "$EXPECT" 2>/dev/null; cat "$W/got.tsv"; } > "$W/new.tsv"
    command grep -q '^#' "$W/new.tsv" || { echo "REFUSED: $EXPECT has no header to keep"; exit 3; }
    mv "$W/new.tsv" "$EXPECT"; echo "FROZEN: $EXPECT ($(command grep -vc '^#' "$EXPECT") rows) — VERIFY by re-running without FREEZE"; exit 0
fi
command grep -v '^#' "$EXPECT" > "$W/want.tsv"
# the pins-ignored MODE judges the VERDICT columns only (kind, replay, event, name, verdict, first, fields): with the
# exclusion off the `excluded` count reads 0 whatever the trace, so a full-row compare would fail without any verdict moving
if vs_ctl_is pins-ignored; then cut -f1-7 "$W/want.tsv" > "$W/want7.tsv"; cut -f1-7 "$W/got.tsv" > "$W/got7.tsv"; mv "$W/want7.tsv" "$W/want.tsv"; mv "$W/got7.tsv" "$W/got.tsv"; fi
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "$(wc -l < "$W/got.tsv" | tr -d ' ') rows as frozen"
else bad "rows differ from $(basename "$EXPECT"):"; sed 's/^/        /' "$W/diff.txt" | head -30; fi

echo "== 4. must-fire controls"
if vs_ctl_is wrong-target || vs_ctl_is order-swapped || vs_ctl_is x-moved || vs_ctl_is pins-ignored || vs_ctl_is pins-shifted; then
    if [ "$fail" = 1 ]; then vs_ctl_fired "$VS_CTL" "the perturbed real input fails the gate"; echo "FAIL: audit_chains174 (control mode)"; exit 1
    else vs_ctl_dead "$VS_CTL" "the perturbed real input still passed" || true; echo "FAIL: audit_chains174"; exit 1; fi
fi
t0="$(echo $TENANTS | cut -d' ' -f1)"
wm="$(entry "$t0" wrong | command grep -c '	MISSING' || true)"; wn="$(command grep "^entry	$t0	" "$W/got.tsv" | command grep -vc "	SPACER$" || true)"
if [ "$wn" -gt 0 ] && [ "$wm" = "$wn" ]; then vs_ctl_fired wrong-target "$t0: all $wn events read MISSING with the target replaced"
else vs_ctl_dead wrong-target "$t0: $wm of $wn events read MISSING with the target replaced" || fail=1; fi
om="$(entry "$t0" swap | awk -F'\t' '$5 ~ / / && $6 ~ /^MISSING/' | wc -l | tr -d ' ')"; on="$(command grep "^entry	$t0	" "$W/got.tsv" | awk -F'\t' '$5 ~ / /' | wc -l | tr -d ' ')"
if [ "$on" -gt 0 ] && [ "$om" = "$on" ]; then vs_ctl_fired order-swapped "$t0: all $on multi-chain events read MISSING with their target reversed"
else vs_ctl_dead order-swapped "$t0: $om of $on multi-chain events read MISSING with their target reversed" || fail=1; fi
perturb_x "$RIGS/${t0}_c174.json" "$W/tr_$t0.ours.txt" "$W/ctl.txt"
xd="$(parity "$t0" "$W/ctl.txt" | awk -F'\t' '$3 !~ /^spacer/ && $4 == "DIFF" && $6 ~ /(^|,)x(,|$)/' | wc -l | tr -d ' ')"
if [ "$wn" -gt 0 ] && [ "$xd" = "$wn" ]; then vs_ctl_fired x-moved "$t0: x moved on one frame of each of its $wn events turns every one DIFF on x"
else vs_ctl_dead x-moved "$t0: $xd of $wn events DIFF on x with x moved" || fail=1; fi
# pins-ignored: EVERY tenant, EACH of the three fields — ours perturbed on that field's pin frames must leave the
# verdict columns (replay, event, name, verdict, first, fields) as the real run under the exclusion, and move at
# least one of them with the exclusion off. The OFF baseline is the real trace with the exclusion off too.
pd=""; pn=0
for t in $TENANTS; do
    parity "$t" "$W/tr_$t.ours.txt" | cut -f1-6 > "$W/pi_on.tsv"; parity "$t" "$W/tr_$t.ours.txt" --no-pin-exclusion | cut -f1-6 > "$W/pi_off.tsv"
    for fld in x stock p2hp; do
        n="$(perturb_pins "$RIGS/${t}_c174.json" "$fld" "$W/tr_$t.ours.txt" "$W/pi.txt")"
        parity "$t" "$W/pi.txt" | cut -f1-6 > "$W/pi_pon.tsv"; parity "$t" "$W/pi.txt" --no-pin-exclusion | cut -f1-6 > "$W/pi_poff.tsv"
        mon="$(command diff "$W/pi_on.tsv" "$W/pi_pon.tsv" | command grep -c '^>' || true)"; moff="$(command diff "$W/pi_off.tsv" "$W/pi_poff.tsv" | command grep -c '^>' || true)"
        pn=$((pn + 1)); if [ "$n" -gt 0 ] && [ -s "$W/pi_on.tsv" ] && [ "$mon" = 0 ] && [ "$moff" -gt 0 ]; then :; else pd="$pd $t/$fld(frames $n, moved on $mon, off $moff)"; fi
    done
done
if [ -z "$pd" ]; then vs_ctl_fired pins-ignored "all $pn (tenant, field) pairs: ours altered on its own pin frames moves no verdict under the exclusion and at least one without it"
else vs_ctl_dead pins-ignored "$pd" || fail=1; fi
# pins-shifted: the landing reader on every tenant with the pin list read one frame EARLY must fail and read no pin AT-F
sf=0; sa=0
for t in $TENANTS; do landing "$t" -1 > "$W/ls.txt" && sf=1; sa=$((sa + $(command grep -c '	AT-F$' "$W/ls.txt" || true))); done
if [ "$sf" = 0 ] && [ "$sa" = 0 ]; then vs_ctl_fired pins-shifted "every tenant's landing check fails with its pins read one frame early, none read AT-F"
else vs_ctl_dead pins-shifted "a tenant passed ($sf) or $sa pins still read AT-F with the pins read one frame early" || fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_chains174 — every once never-entered a2 attack chain entered on native and compared with ours, as frozen"
else echo "FAIL: audit_chains174"; exit 1; fi
