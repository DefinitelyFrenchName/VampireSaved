#!/bin/sh
# audit_don_speed_lines.sh — DONOVAN'S DASH SPEED LINES EQUAL NATIVE vs2's, PIECE FOR PIECE: #356, fixed by a tenant-only
# copy of vs2's speed-line effect (the maintainer, 2026-11-02: "ideally Option 1 (new copy of the effect, using vs2
# effect)", then "Yes, next session (Recommended)" and "Raw allocator (Recommended)"; DECISIONS_HISTORY.md).
#
# WHAT: vs2 widened the speed-line effect (class 0x0F) from 12 subs to 14 for Donovan's two dashes (forward sub 0x0C,
#   back sub 0x0D); ours sent his dash to vsavj's 12-row spawner, whose handler read past both its tables: junk
#   positions, every piece culled. The fix places vs2's handler, tables and spawner as Donovan's own effect type 124
#   (0x7C; donovan.toml [[obj_hook_extra]], the root x06e1d2). This gate requires, on two naming parts (donovan_1: the
#   forward and back dash; donovan_2: three back dashes before Blizzard Sword and two forward dashes before Sword
#   Grapple), every speed-line piece record on ours — type 0x7C — to equal native vs2's type-0x0F record of the same
#   frame: sub, piece index, position RELATIVE TO DONOVAN, and the on-screen flag; and no type-0x0F piece of
#   Donovan's on ours. A LEGACY leg (Lilith's two dashes, vsavj's own class 0x0F) must be identical on vsavj and ours.
#   OUT OF SCOPE, measured 14z-219: inside Dark Force (donovan_6) two of the four pieces alternate one frame out of
#   phase with native (28 of 49 records equal native's at the adjacent frame) — the part is not judged here.
# HOW: MAME, tests/lua/speed_line_tap.lua (non-debug, every frame): native vsav2, OURS (BUILD), and BAD — the same
#   build with Donovan's dash `jmp` operand put back to vsavj's spawner PRG:0x061ED4 in the emulator's decrypted-opcode
#   share (OPATCH, nothing built). A precondition reads BUILD's opcode image: the relocated walker's row 124 is the
#   copy, the copy's spawner stamps 0x7C and calls the raw allocator PRG:0x016FBA, exactly one `jmp` and one `jsr`
#   reach the spawner copy, and the legacy row 15 is still vsavj's PRG:0x061C42. Legs: the parity gate's protocol
#   (real cursor picks, speed level pinned 6 from f2000, RNG 0000 from f2363).
# EXPECTS: every leg complete (END), P1 id 0x13 from 2500 on the Donovan legs and 0x0E on the legacy legs; ours'
#   records equal native's in every dash group JUDGED — a group is judged only while P1's state agrees on both legs
#   through it, else VOID and printed; donovan_1's two and donovan_2's first three groups (before f3098, native's own
#   lost frame) must be judged (frozen native counts from the 14z-219 build build/agent219/t356/mg1: donovan_1 97,
#   donovan_2 242); 0 type-0x0F pieces owned by P1 on ours; the legacy leg's S and T lines identical vsavj vs ours.
#   Not covered: Donovan as P2; Dark Force (above); FBNeo and MiSTer; pixels (the 14z-219 capture sheets).
# MUST-FIRE: known-bad: reverted — the BAD leg (the dash jmp back to vsavj's 12-row spawner) must differ from native: its pieces are type 0x0F with no record equal to native's, so the comparison cannot pass blind (in-gate; mode: the BAD leg replaces ours and the gate FAILs)
# MUST-FIRE: perturbed-copy: shifted — every ours record's x moved by one pixel must fail the comparison (in-gate; mode: the shift is applied to ours and the gate FAILs)
# FOLLOWS: build/manifest/ emu/mame-patches/ tools/setup_mame.sh tools/name_moves.py tools/gen_donovan_patch.py tools/build_donovan.sh tests/lua/speed_line_tap.lua tests/lua/emu_clock.lua
#   tests/lua/pokes_spec.lua tests/replays/naming/ tests/replays/don/356_legacy_lilith_dash.rpl tools/run_mame.sh tests/lib/controls.sh
#
# SHEET: none — the capture sheets for the maintainer are a separate step (14z-219, build/agent219/t356/rig/sheets/); this gate judges piece records only
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged34] [JOBS=4] tests/audit_don_speed_lines.sh
#   emulator tier, MAME; 8 runs
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged34}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] && [ -f "$BUILD/verify_op.bin" ] || { echo "SKIP: no WIDE build with verify_op.bin at $BUILD"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; trap 'exit 143' INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN; build $(basename "$BUILD")"

echo "== 0. the build carries #356's speed-line copy"
PRE="$(python3 - "$BUILD/verify_op.bin" <<'PY'
import re, sys
o = open(sys.argv[1], "rb").read()
L = lambda a: int.from_bytes(o[a:a + 4], "big")
sig = bytes.fromhex("4ded38001b7c002000b54a1667127000102e0002d040d040207b0012")   # the 0x05E52A walker, relocated verbatim
ws = [m.start() for m in re.finditer(re.escape(sig), o) if m.start() != 0x05E52A]
if len(ws) != 1: print(f"BAD the relocated effect walker found {len(ws)} times"); sys.exit()
t = ws[0] + 0x2C; cp = L(t + 124 * 4); spn = cp + 0x2D4
why = []
if L(t + 15 * 4) != 0x061C42: why.append(f"legacy row 15 is {L(t + 15*4):#x}, not vsavj's 0x061c42")
if o[spn + 0x0C:spn + 0x12].hex() != "197c007c0002": why.append(f"the spawner copy at {spn:#x} does not stamp type 0x7C")
if o[spn + 0x02:spn + 0x08].hex() != "4eb900016fba": why.append("the spawner copy does not call the raw allocator 0x016FBA")
if o[cp + 0x50:cp + 0x56].hex() != "41f900283690": why.append("the handler copy does not read vsavj's anim table 0x283690")
j = [m.start() for m in re.finditer(re.escape(bytes.fromhex("4ef9") + spn.to_bytes(4, "big")), o)]
s = [m.start() for m in re.finditer(re.escape(bytes.fromhex("4eb9") + spn.to_bytes(4, "big")), o)]
if len(j) != 1 or len(s) != 1: why.append(f"{len(j)} jmp and {len(s)} jsr reach the spawner copy, not one each")
if why: print("BAD " + "; ".join(why)); sys.exit()
print(f"OK {ws[0]:x} {cp:x} {spn:x} {j[0] + 2:x}")
PY
)"
case "$PRE" in
    OK*) set -- $PRE; WALK=$2; COPY=$3; SPN=$4; SITE=$5
         ok "walker copy $WALK: row 124 -> the copy $COPY (spawner $SPN: stamps 0x7C, raw allocator); Donovan's dash jmp operand at $SITE"
         ;;
    *)   bad "${PRE#BAD }"; echo "FAIL: audit_don_speed_lines"; exit 1 ;;
esac

JOBS="${JOBS:-4}"
leg() {  # leg <dir> <set> <rompath> <rpl> <pokes> <frames> <opatch>
    mkdir -p "$1"
    ( cd "$1" && MAME_SANDBOX="$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$6" OPATCH="$7" SOUT="$1/st" \
        SFROM=2300 STYPES=0f,7c timeout 1200 "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/speed_line_tap.lua" > "$1/mame.log" 2>&1
      rm -rf "$1/sb" ) </dev/null || true
}
ours_rpl() {  # the naming rig's native cursor path -> ours' (the parity gate's rewrite)
    awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$1" > "$2"
}
echo "== 1. the legs: native vsav2 / ours $(basename "$BUILD") / bad (the dash jmp back to PRG:0x061ED4, OPATCH)"
JOBLIST="$W/jobs"; : > "$JOBLIST"
for p in 1 2; do
    J="$REPO/tests/replays/naming/donovan_$p.json"; R="$REPO/tests/replays/naming/donovan_$p.rpl"
    FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$J")"
    PK="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$J");2000-$((FR-1)):ff8116:06;2363-$((FR-1)):ff80d4:0000"
    mkdir -p "$W/d$p"; ours_rpl "$R" "$W/d$p/ours.rpl"
    printf '%s\n' "d$p/native|vsav2|$ROMDIR|$R|$PK|$FR|" "d$p/ours|vsavjw|$BUILD/rompath;$ROMDIR|$W/d$p/ours.rpl|$PK|$FR|" \
        "d$p/bad|vsavjw|$BUILD/rompath;$ROMDIR|$W/d$p/ours.rpl|$PK|$FR|$SITE:00061ed4" >> "$JOBLIST"
done
LR="$REPO/tests/replays/don/356_legacy_lilith_dash.rpl"
LPK="2550:ff8850:01200120;2950:ff8850:01200120;3350:ff8850:01200120;2000-3649:ff8116:06;2363-3649:ff80d4:0000"
printf '%s\n' "lg/vsavj|vsavj|$ROMDIR|$LR|$LPK|3650|" "lg/ours|vsavjw|$BUILD/rompath;$ROMDIR|$LR|$LPK|3650|" >> "$JOBLIST"
n=0
while IFS='|' read -r d set rp rpl pk fr op; do
    leg "$W/$d" "$set" "$rp" "$rpl" "$pk" "$fr" "$op" &
    n=$((n + 1)); if [ "$n" -ge "$JOBS" ]; then wait; n=0; fi
done < "$JOBLIST"
wait

echo "== 2. the checks"
W="$W" MODE="$MODE" SITE="$SITE" python3 - <<'PY' || fail=1
import collections, os, sys
W, MODE, SITE = os.environ["W"], os.environ["MODE"], os.environ["SITE"]
FROZEN = {"d1": 97, "d2": 242}        # native's speed-line records, 14z-219 (build/agent219/t356/rig/runs/census_mg1.txt)
fail = 0
def bad(m):
    global fail; fail = 1; print(f"  FAIL  {m}")
def ok(m): print(f"  ok    {m}")
def load(path):
    try: lines = open(path).read().splitlines()
    except OSError: return None
    P, S, T, end, rb = {}, [], [], None, None
    for l in lines:
        t = l.split()
        if not t: continue
        if t[0] == "P": P[int(t[1])] = (int(t[4], 16), int(t[5], 16), l.split("id=")[1].split("/")[0])
        elif t[0] == "S": S.append((int(t[1]), dict(x.split("=") for x in t[3:])))
        elif t[0] == "T": T.append(l)
        elif t[0] == "END": end = int(t[1])
        elif t[0] == "OPATCH": rb = t[-1]
    return P, S, T, end, rb
L = {}
for d in ("d1/native", "d1/ours", "d1/bad", "d2/native", "d2/ours", "d2/bad", "lg/vsavj", "lg/ours"):
    x = load(f"{W}/{d}/st")
    if not x or x[3] is None or not x[0]:
        bad(f"{d}: the tap never reached its END line — VOID"); continue
    want = "0e" if d.startswith("lg") else "13"
    ids = {v[2] for f, v in x[0].items() if f >= 2500}
    if ids != {want}: bad(f"{d}: P1's id from 2500 is {sorted(ids)}, not {{{want}}} — the leg is not the character it names")
    L[d] = x
if fail:
    print("FAIL: legs incomplete"); sys.exit(1)
def recs(x, typ, shift=0):
    P, S = x[0], x[1]; c = collections.Counter()
    for fr, k in S:
        if k["hdr"][4:6] != typ or k["own"] != "8400": continue
        px, py, _ = P[fr]
        c[(fr, k["sub"], k["i"], (int(k["x"], 16) + shift - px) & 0xFFFF, (int(k["y"], 16) - py) & 0xFFFF, k["hdr"][2:4])] += 1
    return c
use = "bad" if MODE == "reverted" else "ours"
# A DASH GROUP IS JUDGED ONLY WHILE THE TWO LEGS PLAY THE SAME MATCH (14z-219, [VSP-170]): a group = native's records from
# a spawn frame until a 6-frame gap; it is judged when P1's state/sub/x/y agree on native and ours on every frame from 2500
# to the group's last frame, else it is VOID (printed, never passed). Measured 14z-219: on #345 A1b's build P1's state
# first differs at f3113 (inside Blizzard Sword [HP], #345's lost-frame business), so donovan_2's two later Sword Grapple
# dashes compare two different matches. The five groups before f3098 (native's own lost frame) must always be judged.
MUST = {"d1": [3324, 3474], "d2": [2604, 2824, 3044]}
def pstate(x): return {f: (v[0], v[1]) for f, v in x[0].items()}
def pseq(path):
    out = {}
    for l in open(path):
        if l.startswith("P "):
            t = l.split(); out[int(t[1])] = tuple(t[2:6])
    return out
def groups(c):
    g, last = [], None
    for k in sorted(c):
        if last is None or k[0] - last > 5: g.append([k[0], k[0]])
        g[-1][1] = k[0]; last = k[0]
    return g
judged_all = {}
for p in ("d1", "d2"):
    n = recs(L[f"{p}/native"], "0f")
    o = recs(L[f"{p}/{use}"], "7c", 1 if MODE == "shifted" else 0)
    o0f = sum(recs(L[f"{p}/{use}"], "0f").values())
    sn, so = pseq(f"{W}/{p}/native/st"), pseq(f"{W}/{p}/{use}/st")
    div = next((f for f in sorted(sn) if f >= 2500 and f in so and sn[f] != so[f]), None)
    judged, void, same, tot = [], [], 0, 0
    for g0, g1 in groups(n):
        nn = collections.Counter({k: v for k, v in n.items() if g0 <= k[0] <= g1 + 5})
        oo = collections.Counter({k: v for k, v in o.items() if g0 <= k[0] <= g1 + 5})
        if div is not None and div <= g1 + 5:
            void.append(g0); continue
        judged.append(g0); tot += sum(nn.values()); same += sum((nn & oo).values())
        if nn != oo: bad(f"[{p}] group f{g0}: native {sum(nn.values())} records, {use} {sum(oo.values())}, equal {sum((nn & oo).values())}")
    judged_all[p] = judged
    miss = [g for g in MUST[p] if g not in judged]
    msg = (f"[{p}] native {sum(n.values())} speed-line records (frozen {FROZEN[p]}); groups judged {judged} "
           f"({same} of {tot} records equal: frame, sub, piece, x and y relative to Donovan, on-screen flag), VOID {void} "
           f"(P1's state first differs at f{div}); {use} type-0x0F pieces of P1 {o0f}")
    good = sum(n.values()) == FROZEN[p] and same == tot and o0f == 0 and not miss
    (ok if good else bad)(msg + (f"; MUST-judge groups not judged: {miss}" if miss else ""))
    vis = sum(v for k, v in n.items() if k[5] == "01")
    print(f"        native on screen {vis} of {sum(n.values())}")
# the known-bad leg: reverted to vsavj's 12-row spawner, its pieces are type 0x0F and none equals native's
fired = True; ev = []
for p in ("d1", "d2"):
    rb = L[f"{p}/bad"][4]
    n = recs(L[f"{p}/native"], "0f"); b0 = recs(L[f"{p}/bad"], "0f"); b7 = recs(L[f"{p}/bad"], "7c")
    lim = max(MUST[p]) + 20
    n = collections.Counter({k: v for k, v in n.items() if k[0] <= lim}); b0 = collections.Counter({k: v for k, v in b0.items() if k[0] <= lim})
    eq = sum((n & b0).values()); vis = sum(v for k, v in b0.items() if k[5] == "01")
    ev.append(f"{p} readback {rb}, type-0x0F {sum(b0.values())} (on screen {vis}), equal to native {eq}, type 0x7C {sum(b7.values())}")
    if rb != "00061ed4" or sum(b0.values()) == 0 or eq != 0 or sum(b7.values()) != 0: fired = False
if MODE: pass
elif fired: print("CONTROL FIRED: reverted — with the dash jmp back to PRG:0x061ED4 the pieces are vsavj's class again and none equals native's: " + "; ".join(ev))
else: print("CONTROL DEAD: reverted — " + "; ".join(ev)); fail = 1
if not MODE:
    sh = [sum((recs(L[f"{p}/native"], "0f") & recs(L[f"{p}/ours"], "7c", 1)).values()) for p in ("d1", "d2")]   # every record, judged or not
    if sh == [0, 0]: print("CONTROL FIRED: shifted — with every ours record moved one pixel in x no record equals native's (0, 0)")
    else: print(f"CONTROL DEAD: shifted — {sh} records still equal native's"); fail = 1
# the legacy leg: vsavj's own class 0x0F on Lilith's dashes, identical on vsavj and ours
a, b = L["lg/vsavj"], L["lg/ours"]
sa = [(f, k) for f, k in a[1]]; sb = [(f, k) for f, k in b[1]]
n_l = sum(1 for f, k in sa if k["hdr"][4:6] == "0f")
(ok if sa == sb and a[2] == b[2] and n_l > 0 else bad)(
    f"[legacy] Lilith's dashes: {n_l} type-0x0F records on vsavj; S lines identical {sa == sb}, pool (T) lines identical {a[2] == b[2]}")
sys.exit(fail)
PY
if [ -n "$MODE" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $MODE — the gate failed with the control applied"
    else echo "CONTROL DEAD: $MODE — every check passed with the control applied"; fi
    echo "FAIL: audit_don_speed_lines (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_don_speed_lines"; else echo "FAIL: audit_don_speed_lines"; exit 1; fi
