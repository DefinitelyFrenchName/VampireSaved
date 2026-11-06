#!/bin/sh
# audit_don_trail_nodraw.sh — DONOVAN'S CLASS-0x72 TRAIL PIECES TAKE vs2's NO-DRAW RECORDS, THROUGH HIS OWN COPY OF vs2's
# TABLE: #345 option A1b, which also removes #346's ice streak (the maintainer, 2026-11-03: "A1b (Recommended)";
# DECISIONS_HISTORY.md "Ruled 2026-11-03 (14z-219) — #345").
#
# WHAT: Blizzard Sword's trail pieces (class 0x72, sub 0x00) pick their animation from the shared effect anim table, vs2
#   PRG:0x1D7428 / vsavj PRG:0x1F3FD2. vs2's copy reaches only no-draw records (format 10); vsavj's reaches drawing ones
#   and is live legacy content (Sasquatch). Ours resolved the operand to vsavj's, so the pieces drew (#346's streak) and
#   cost #345's extra pass time. A1b places vs2's whole table as a Donovan-only, WIDE-only region (the root x1d7428, the
#   `:dp` form) and the class's operand resolves into it. This gate requires, on the build: the operand names a WIDE copy
#   whose 403 pointer fields all point into the copy and whose other bytes equal vs2's, vsavj's table bytes equal pristine
#   vsavj's; and, under the move-parity rig, on donovan_2 (Blizzard Sword [LP]/[MP]/[HP]) and donovan_11 (Blizzard Sword
#   [LP] blocked), every live sub-0 piece on ours reads a format-10 record through a node inside the copy, as on
#   native vs2 (whose sub-0 pieces are all format 10 too, the basis).
# HOW: MAME, tests/lua/class72_tap.lua (non-debug, every frame): native vsav2, OURS (BUILD), and BAD — the same build with
#   the class's operand put back to vsavj's PRG:0x1F3FD2 in the emulator's decrypted-opcode share (OPATCH, nothing built).
#   A precondition reads BUILD's images (verify_op.bin / verify_data.bin) and the pristine vsav2/vsavj data views.
#   Legs: the parity gate's protocol (real cursor picks, speed level 6 from f2000, RNG 0000 from f2363).
# EXPECTS: every leg complete (END), P1 0x13 on Donovan's legs; ours' and native's sub-0 piece-frames all format 10, ours'
#   nodes inside the copy, ours' sub-0 piece-frame counts at least the frozen floor below (14z-219, build
#   build/agent219/t345a/mg); BAD's include non-format-10 records. MEASURED, not asserted: the other sub-types' counts.
#   Not covered: pixels (the 14z-219 capture sheets), the lost-frame timing (tests/audit_pass_overrun.sh,
#   tests/audit_lag_budget.sh), legacy (tests/audit_merged_legacy.sh; by construction here: vsavj's table unchanged),
#   Donovan as P2, FBNeo and MiSTer.
# MUST-FIRE: known-bad: operand-reverted — the BAD leg (the class's table operand back to vsavj's PRG:0x1F3FD2) must show sub-0 pieces drawing non-format-10 records, so the format check cannot pass blind (in-gate; mode: the BAD leg replaces ours and the gate FAILs)
# MUST-FIRE: perturbed-copy: copy-ptr — the static check, given a copy of BUILD's data image with one of the copy's 403 pointer fields moved by 2, must fail (in-gate; mode: the perturbed image is the one checked and the gate FAILs)
# FOLLOWS: build/manifest/ emu/mame-patches/ tools/setup_mame.sh tools/name_moves.py tools/gen_donovan_patch.py tools/build_donovan.sh tools/extract_char.py tests/lua/class72_tap.lua
#   tests/lua/emu_clock.lua tests/lua/pokes_spec.lua tests/replays/naming/ tools/run_mame.sh tests/lib/controls.sh tests/lib/decrypt_cache.sh
#
# SHEET: none — the capture sheets for the maintainer are a separate step (14z-219, build/agent219/t345/after/snap/sheets/); this gate judges records only
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged34] [JOBS=3] tests/audit_don_trail_nodraw.sh
#   emulator tier, MAME; 6 runs
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged34}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] && [ -f "$BUILD/verify_op.bin" ] && [ -f "$BUILD/verify_data.bin" ] || {
    echo "SKIP: no WIDE build with verify_op.bin/verify_data.bin at $BUILD"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; trap 'exit 143' INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN; build $(basename "$BUILD")"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsav2 "$W/vs2_op.bin" "$W/vs2_da.bin" || { echo "FAIL: vsav2 views not delivered"; exit 1; }
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_da.bin" || { echo "FAIL: vsavj views not delivered"; exit 1; }

echo "== 0. the build carries #345 A1b's table copy"
static() {  # static <data image>  -> OK <handler> <copy> <operand addr> | BAD <why>
    python3 - "$BUILD/verify_op.bin" "$1" "$W/vs2_da.bin" "$W/vj_da.bin" <<'PY'
import re, sys
op = open(sys.argv[1], "rb").read(); da = open(sys.argv[2], "rb").read()
vs = open(sys.argv[3], "rb").read(); vj = open(sys.argv[4], "rb").read()
U = lambda b, a: int.from_bytes(b[a:a + 4], "big")
SRC, LEN, VJT = 0x1D7428, 0x1308, 0x1F3FD2
sig = bytes.fromhex("4ded38001b7c002000b54a1667127000102e0002d040d040207b0012")   # the 0x05E52A walker, relocated verbatim
ws = [m.start() for m in re.finditer(re.escape(sig), op) if m.start() != 0x05E52A]
if len(ws) != 1: print(f"BAD the relocated effect walker found {len(ws)} times"); sys.exit()
h = U(op, ws[0] + 0x2C + 0x72 * 4)
if op[h + 0xAC:h + 0xAE].hex() != "207c": print(f"BAD no movea.l #imm,a0 at the class-0x72 handler {h:#x}+0xAC"); sys.exit()
t = U(op, h + 0xAE)
why = []
if t < 0x400000: why.append(f"the class's table operand is {t:#x}, not a WIDE copy")
ptr = [o for o in range(0, LEN - 3, 2) if SRC <= U(vs, SRC + o) < SRC + LEN]
if len(ptr) != 403: why.append(f"vs2's table has {len(ptr)} self-pointer fields, not 403")
badp = [o for o in ptr if U(da, t + o) != U(vs, SRC + o) - SRC + t]
cover = set(); [cover.update(range(o, o + 4)) for o in ptr]
badb = [o for o in range(LEN) if o not in cover and da[t + o] != vs[SRC + o]]
if badp: why.append(f"{len(badp)} of {len(ptr)} pointer fields do not point into the copy (first +{badp[0]:#x})")
if badb: why.append(f"{len(badb)} non-pointer bytes differ from vs2's table (first +{badb[0]:#x})")
if da[VJT:VJT + LEN] != vj[VJT:VJT + LEN]: why.append("vsavj's table PRG:0x1F3FD2 differs from pristine vsavj's")
if why: print("BAD " + "; ".join(why)); sys.exit()
print(f"OK {h:x} {t:x} {h + 0xAE:x} {len(ptr)}")
PY
}
PRE="$(static "$BUILD/verify_data.bin")"
case "$PRE" in
    OK*) set -- $PRE; H=$2; COPY=$3; OPND=$4
         ok "class-0x72 handler $H: its table operand ($OPND) names the copy $COPY; all $5 pointer fields point into it, every other byte is vs2's, vsavj's table PRG:0x1F3FD2 is pristine"
         ;;
    *)   bad "${PRE#BAD }"; echo "FAIL: audit_don_trail_nodraw"; exit 1 ;;
esac
# the copy-ptr control: one of the copy's pointer fields moved by 2 must fail the static check
CPF="$(python3 - "$BUILD/verify_data.bin" "$W/vs2_da.bin" "$W/cp.bin" "$COPY" <<'PY'
import sys
da = bytearray(open(sys.argv[1], "rb").read()); vs = open(sys.argv[2], "rb").read(); t = int(sys.argv[4], 16)
SRC, LEN = 0x1D7428, 0x1308
U = lambda b, a: int.from_bytes(b[a:a + 4], "big")
o = next(o for o in range(0, LEN - 3, 2) if SRC <= U(vs, SRC + o) < SRC + LEN)
da[t + o:t + o + 4] = (U(da, t + o) + 2).to_bytes(4, "big"); open(sys.argv[3], "wb").write(da); print(f"+{o:#x}")
PY
)"
CPR="$(static "$W/cp.bin")"
if [ "$MODE" = copy-ptr ]; then
    case "$CPR" in OK*) ok "(mode copy-ptr) the perturbed image passes the static check";; *) bad "(mode copy-ptr) ${CPR#BAD }";; esac
elif [ -z "$MODE" ]; then
    case "$CPR" in
        BAD*) echo "CONTROL FIRED: copy-ptr — with the copy's pointer field $CPF moved by 2 the static check reads: ${CPR#BAD }" ;;
        *)    echo "CONTROL DEAD: copy-ptr — the perturbed image ($CPF) passed the static check"; fail=1 ;;
    esac
fi

JOBS="${JOBS:-3}"
leg() {  # leg <dir> <set> <rompath> <rpl> <pokes> <frames> <opatch>
    mkdir -p "$1"
    ( cd "$1" && MAME_SANDBOX="$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$6" OPATCH="$7" SOUT="$1/st" \
        SFROM=2300 TYPES=72 timeout 1200 "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/class72_tap.lua" > "$1/mame.log" 2>&1
      rm -rf "$1/sb" ) </dev/null || true
}
ours_rpl() {
    awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
        for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$1" > "$2"
}
echo "== 1. the legs: native vsav2 / ours $(basename "$BUILD") / bad (the table operand back to PRG:0x1F3FD2, OPATCH)"
JL="$W/jobs"; : > "$JL"
for p in 2 11; do
    J="$REPO/tests/replays/naming/donovan_$p.json"; R="$REPO/tests/replays/naming/donovan_$p.rpl"
    FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$J")"
    PK="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$J");2000-$((FR-1)):ff8116:06;2363-$((FR-1)):ff80d4:0000"
    mkdir -p "$W/d$p"; ours_rpl "$R" "$W/d$p/ours.rpl"
    printf '%s\n' "d$p/native|vsav2|$ROMDIR|$R|$PK|$FR|" "d$p/ours|vsavjw|$BUILD/rompath;$ROMDIR|$W/d$p/ours.rpl|$PK|$FR|" \
        "d$p/bad|vsavjw|$BUILD/rompath;$ROMDIR|$W/d$p/ours.rpl|$PK|$FR|$OPND:001f3fd2" >> "$JL"
done
n=0
while IFS='|' read -r d set rp rpl pk fr opx; do
    leg "$W/$d" "$set" "$rp" "$rpl" "$pk" "$fr" "$opx" &
    n=$((n + 1)); if [ "$n" -ge "$JOBS" ]; then wait; n=0; fi
done < "$JL"
wait

echo "== 2. the checks"
W="$W" MODE="$MODE" COPY="$COPY" python3 - <<'PY' || fail=1
import collections, os, sys
W, MODE, COPY = os.environ["W"], os.environ["MODE"], int(os.environ["COPY"], 16)
FLOOR = {"d2": 2000, "d11": 700}    # ours' sub-0 piece-frames, a floor under the 14z-219 measurement (2,324 and 824 on build/agent219/t345a/mg)
fail = 0
def bad(m):
    global fail; fail = 1; print(f"  FAIL  {m}")
def ok(m): print(f"  ok    {m}")
def load(path):
    try: lines = open(path).read().splitlines()
    except OSError: return None
    K, end, rb = [], None, None
    for l in lines:
        t = l.split()
        if not t: continue
        if t[0] == "K": K.append((int(t[1]), t[4], dict(x.split("=") for x in t[6:])))
        elif t[0] == "END": end = int(t[1])
        elif t[0] == "OPATCH": rb = t[-1]
    return K, end, rb
L = {}
for d in ("d2/native", "d2/ours", "d2/bad", "d11/native", "d11/ours", "d11/bad"):
    x = load(f"{W}/{d}/st")
    if not x or x[1] is None: bad(f"{d}: the tap never reached its END line — VOID"); continue
    L[d] = x
if fail: print("FAIL: legs incomplete"); sys.exit(1)
use = "bad" if MODE == "operand-reverted" else "ours"
# every class-0x72 piece is counted, whoever owns it: P2 is Demitri, who spawns none (the 14z-219 census: no legacy
# character reaches class 0x72). The owner word +0x30 is NOT a filter: measured 14z-219 on build/agent219/t345a/mg,
# native's pieces carry a mix (0x0000, 0x8400, 0x8800, 0xC680) and ours' all 0x0000 (not attributed) — printed below.
def sub0(x): return [(fr, k) for fr, sub, k in x[0] if sub == "00"]
def profile(x):
    c = collections.Counter()
    for fr, sub, k in x[0]: c[sub] += 1
    return dict(sorted(c.items()))
def owners(x): return dict(collections.Counter(k["own"] for fr, sub, k in x[0]))
for p in ("d2", "d11"):
    nat, our = sub0(L[f"{p}/native"]), sub0(L[f"{p}/{use}"])
    nf = collections.Counter(k["fmt"] for _, k in nat); of = collections.Counter(k["fmt"] for _, k in our)
    inside = sum(1 for _, k in our if COPY <= int(k["node"], 16) < COPY + 0x1308)
    (ok if nat and set(nf) == {"10"} else bad)(f"[{p}] native sub-0 piece-frames {len(nat)}, formats {dict(nf)} (the basis: all format 10)")
    good = len(our) >= FLOOR[p] and set(of) == {"10"} and inside == len(our)
    (ok if good else bad)(f"[{p}] {use} sub-0 piece-frames {len(our)} (floor {FLOOR[p]}), formats {dict(of)}, nodes inside the copy {inside}")
    print(f"        MEASURE per-sub class-0x72 piece-frames: native {profile(L[f'{p}/native'])}; ours {profile(L[f'{p}/ours'])}")
    print(f"        MEASURE owner words (+0x30): native {owners(L[f'{p}/native'])}; ours {owners(L[f'{p}/ours'])}")
if not MODE:
    ev = []; fired = True
    for p in ("d2", "d11"):
        b0 = sub0(L[f"{p}/bad"]); bf = collections.Counter(k["fmt"] for _, k in b0); rb = L[f"{p}/bad"][2]
        ev.append(f"{p} readback {rb}, sub-0 formats {dict(bf)}")
        if rb != "001f3fd2" or not b0 or set(bf) == {"10"}: fired = False
    if fired: print("CONTROL FIRED: operand-reverted — with the operand back to PRG:0x1F3FD2 the sub-0 pieces draw vsavj's records: " + "; ".join(ev))
    else: print("CONTROL DEAD: operand-reverted — " + "; ".join(ev)); fail = 1
sys.exit(fail)
PY
if [ -n "$MODE" ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $MODE — the gate failed with the control applied"
    else echo "CONTROL DEAD: $MODE — every check passed with the control applied"; fi
    echo "FAIL: audit_don_trail_nodraw (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_don_trail_nodraw"; else echo "FAIL: audit_don_trail_nodraw"; exit 1; fi
