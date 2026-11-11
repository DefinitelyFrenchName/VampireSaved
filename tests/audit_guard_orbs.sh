#!/bin/sh
# audit_guard_orbs.sh — #357: DONOVAN'S GUARD ORBS ON OURS EQUAL NATIVE vs2'S, PIECE BY PIECE (14z-221c; the maintainer,
# 2026-11-05: "we should port the orbs unless we find out we technically cannot").
#
# WHAT: at Donovan's guard native vs2 draws eight small red orbs (effect type 0x72 sub 0x16, the effect-piece pool
#   RAM:$FFB800) around the fighters for about 14 frames; until #357's port ours drew none. They are spawned by a
#   type-0x13 WATCHER in the $FFD400 pool (his set-up creates it once per round); vsavj's row 0x13 of that pool's
#   38-row table (PRG:0x080AAC + 19*4 = PRG:0x080AF8) is the bare-rts stub PRG:0x080B44, and the port points it at a
#   copy of vs2's handler PRG:0x090EDA (docs/game/engine_internals.md «Donovan's guard orbs»). The orbs then move by
#   vs2's class-0x72 sub-0x16 code in his x088512 copy, which reads vs2's 64-entry motion table PRG:0x0D1BBE; the
#   port pins that operand to a whole copy of the table (14z-221c: it had resolved into his hitbox_proj copy, which
#   ends 0x16 bytes into the table, so on the first scratch build one orb of five guard events took y += 0xFB).
# HOW: step 0 reads the images: pristine vsavj's row 0x13 is the stub and vs2's is 0x090EDA (tests/lib/decrypt_cache.sh);
#   ours (BUILD's verify_op.bin / verify_data.bin, the placements from BUILD's patch/atlas_fragment.md): row 0x13
#   names the placed x090eda copy, whose 0x168 bytes equal vs2's outside its five absolute operands, and the
#   motion-table operand of his x088512 copy (+0xF74) names 0x100 data-view bytes equal to vs2's table. Step 1 runs
#   MAME (non-debug, tests/lua/guard_orb_tap.lua, f2300-7240) on native vsav2 and on ours with the parity gate's
#   protocol on naming part donovan_15 (Ifrit Sword, guard-cancel events; P2 Demitri): real cursor picks (ours "D D DR
#   DR"), speed level pinned 6 from f2000, RNG 0000 from f2363, the part's own pokes. Step 2 compares every frame.
# EXPECTS (frozen 14z-221c on the scratch build build/agent221c/m34x, whose program 2c594c29 the M26 freeze's
#   merged-m26 (build/m3b_merged34, 14z-222) carries unchanged; BUILD re-pointed there at that freeze): both legs
#   complete (END); P1's seq/sub equal on both legs from f2363 (the match anchor) on; every DRAWN class-0x72 piece
#   (vis 01) equal on both legs frame by frame — slot, sub, x, y — and the drawn sub-0x16 piece-frames number 1,400
#   on each leg (frozen, measured: 175 frames in nine runs — f2797-2810, 3217-3230, 3636-3650, 4056-4087, 4476-4507,
#   4896-4927, 5316-5330, 5736-5740, 6157-6172 — eight orbs a frame). Not compared: undrawn pieces (vis 00) —
#   on each spawn frame a freshly allocated slot keeps its previous occupant's x/y on native and reads 0 on ours (the
#   tenant's alloc_wrap clears the slot, [VSE-23]); nothing is drawn that frame.
#   Not covered: a piece's other bytes — its sprite, anim node, palette and priority are not compared (the tap reads
#   sub, vis, x and y of each slot; the anim node is an address that differs between the games by construction), so the
#   look rests on the capture the maintainer read ("looks identical", the first guard run's frames); Dark Force
#   guards; Donovan as P2; FBNeo and MiSTer; the other guard parts.
# MUST-FIRE: perturbed-copy: orbs-dropped — ours' sub-0x16 pieces removed from its trace (the build before #357's port) must fail the comparison (in-gate; mode: the copy replaces ours and the gate FAILs)
# MUST-FIRE: perturbed-copy: orb-displaced — one drawn orb per guard event on ours moved by y += 0xFB from its second drawn frame on (the first scratch build's truncated motion table) must fail the comparison (in-gate; mode: the copy replaces ours and the gate FAILs)
# FOLLOWS: build/manifest/ emu/mame-patches/ tools/setup_mame.sh tools/run_mame.sh tests/lua/guard_orb_tap.lua tests/lua/emu_clock.lua
#   tests/lua/pokes_spec.lua tests/replays/naming/donovan_15.json tests/replays/naming/donovan_15.rpl tests/lib/decrypt_cache.sh tests/lib/controls.sh tools/name_moves.py
#
# SHEET: none — the guard's capture for the maintainer is build/agent221c/t357/sheets/357_fixed2_p1.png (local); this gate judges the piece records only
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged34] [KEEP=<dir>: the two traces are copied there] tests/audit_guard_orbs.sh
#   emulator tier, MAME; 2 runs
# SHARES: self
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged34}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] && [ -f "$BUILD/verify_op.bin" ] && [ -f "$BUILD/verify_data.bin" ] \
    || { echo "SKIP: no WIDE build with verify_op.bin and verify_data.bin at $BUILD"; exit 0; }
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; trap 'exit 143' INT TERM
fail=0
echo "  host  $(uname -sm); MAME_BIN $MAME_BIN; build $(basename "$BUILD")"

echo "== 0. row 0x13 of the \$FFD400 pool's table, the watcher copy and the orbs' motion table"
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin" || { vs_ctl_nj "no vsavj view"; echo "FAIL: audit_guard_orbs (no vsavj view)"; exit 1; }
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2_data.bin" || { vs_ctl_nj "no vsav2 view"; echo "FAIL: audit_guard_orbs (no vsav2 view)"; exit 1; }
python3 - "$W/vj_op.bin" "$W/v2_op.bin" "$W/v2_data.bin" "$BUILD/verify_op.bin" "$BUILD/verify_data.bin" \
    "$BUILD/patch/atlas_fragment.md" <<'PY' || fail=1
import re, struct, sys
vj, v2, v2d, oo, od = (open(p, "rb").read() for p in sys.argv[1:6])
atlas = open(sys.argv[6]).read()
L = lambda b, a: struct.unpack(">I", b[a:a + 4])[0]
bad = 0
def chk(c, m):
    global bad
    print(f"  {'ok  ' if c else 'FAIL'}  {m}"); bad |= not c
def placed(name, ln):
    m = re.findall(rf"\| `PRG:0x([0-9A-F]+)` \| 0x{ln:X} \| VS2 \| donovan {name} ", atlas)
    return int(m[0], 16) if len(m) == 1 else None
chk(L(vj, 0x080AF8) == 0x080B44, f"pristine vsavj row 0x13 (PRG:0x080AF8) -> {L(vj, 0x080AF8):#08x}, the stub 0x080b44")
chk(L(v2, 0x08F1D6 + 0x4C) == 0x090EDA, f"vsav2 row 0x13 (PRG:0x08F222) -> {L(v2, 0x08F222):#08x}, its watcher 0x090eda")
w = placed("x090eda", 0x168)
chk(w is not None, f"ours places the watcher copy x090eda at {w and hex(w)} (atlas)")
if w is not None:
    chk(L(oo, 0x080AF8) == w, f"ours row 0x13 -> {L(oo, 0x080AF8):#08x}, the placed copy")
    ops = {0x80, 0xC4, 0xCA, 0x114, 0x164}   # the five absolute operands (extract refs; the rest is vs2's own)
    skip = {o + k for o in ops for k in range(4)}
    d = [i for i in range(0x168) if i not in skip and oo[w + i] != v2[0x090EDA + i]]
    chk(not d, f"the copy's 0x168 bytes equal vs2's 0x090EDA outside its five operands ({len(d)} differ)")
x = placed("x088512", 0x2F00)
chk(x is not None, f"ours places his x088512 copy at {x and hex(x)} (atlas)")
if x is not None:
    t = L(oo, x + 0xF74)
    chk(od[t:t + 0x100] == v2d[0x0D1BBE:0x0D1BBE + 0x100],
        f"the motion-table operand (x088512+0xF74, the movea.l at vs2 0x089484) -> {t:#08x}: its 0x100 data-view bytes equal vs2's table 0x0D1BBE")
sys.exit(bad)
PY
[ "$fail" = 0 ] || vs_ctl_nj "step 0's image precondition failed, not the control"

echo "== 1. the legs: native vsav2 / ours $(basename "$BUILD") (donovan_15, f2300-7240)"
J="$REPO/tests/replays/naming/donovan_15.json"; R="$REPO/tests/replays/naming/donovan_15.rpl"
FR="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['frames'])" "$J")"
PK="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$J");2000-$((FR-1)):ff8116:06;2363-$((FR-1)):ff80d4:0000"
awk -v path="D D DR DR" '/^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
    for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
    /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$R" > "$W/ours.rpl"
leg() {  # leg <name> <set> <rompath> <rpl>
    mkdir -p "$W/$1"
    ( cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$PK" FRAMES="$FR" SOUT="$W/$1/st" \
        SFROM=2300 STO=7240 timeout 900 "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/guard_orb_tap.lua" > "$W/$1/mame.log" 2>&1
      rm -rf "$W/$1/sb" ) </dev/null || true
}
leg native vsav2 "$ROMDIR" "$R" &
leg ours vsavjw "$BUILD/rompath;$ROMDIR" "$W/ours.rpl" &
wait
[ -z "${KEEP:-}" ] || { mkdir -p "$KEEP"; cp "$W/native/st" "$KEEP/native.st" 2>/dev/null || true; cp "$W/ours/st" "$KEEP/ours.st" 2>/dev/null || true; }

prc=0; echo "== 2. the checks"
W="$W" MODE="$MODE" python3 - > "$W/main.log" <<'PY' || prc=$?
import os, sys
W, MODE = os.environ["W"], os.environ["MODE"]
ORBS = 1400          # frozen 14z-221c: drawn sub-0x16 piece-frames on each leg (175 frames x 8 orbs)
fail = 0
def load(path):
    try: lines = open(path).read().splitlines()
    except OSError: return None
    F, O, end = {}, {}, None
    for l in lines:
        t = l.split()
        if not t: continue
        if t[0] == "F": F[int(t[1])] = {k: v for k, v in (x.split("=") for x in t[2:])}
        elif t[0] == "O":
            f = int(t[1]); d = {k: v for k, v in (x.split("=") for x in t[3:])}; d["slot"] = t[2]
            O.setdefault(f, []).append(d)
        elif t[0] == "END": end = int(t[1])
    return (F, O) if end is not None and F else None
L = {g: load(f"{W}/{g}/st") for g in ("native", "ours")}
dead = [g for g, x in L.items() if not x or any(f not in x[0] for f in range(2300, 7241))]
if dead:
    print(f"  FAIL  {', '.join(dead)}: the tap never reached its END line with every frame 2300-7240 — VOID"); sys.exit(4)   # a dead leg: nothing judged (the shell's vs_ctl_nj)
def drawn(O, f):
    return sorted((p["slot"], p["sub"], p["x"], p["y"]) for p in O.get(f, []) if p["vis"] == "01")
def dropped(O):
    return {f: [p for p in v if p["sub"] != "16"] for f, v in O.items()}
def displaced(O):
    # one drawn orb per event (the lowest slot drawn on the event's first drawn frame) moved y += 0xFB from its second
    # drawn frame on, for as long as it stays drawn
    out = {f: [dict(p) for p in v] for f, v in O.items()}
    prev, slot, seen = False, None, 0
    for f in sorted(out):
        orbs = [p for p in out[f] if p["sub"] == "16" and p["vis"] == "01"]
        if orbs and not prev: slot, seen = min(p["slot"] for p in orbs), 0
        if not orbs: slot = None
        for p in orbs:
            if p["slot"] == slot:
                seen += 1
                if seen >= 2: p["y"] = format((int(p["y"], 16) + 0xFB) & 0xFFFF, "04x")
        prev = bool(orbs)
    return out
def judge(n, o, quiet=False):
    (nf, no), (of, oo) = n, o
    out = []
    p1 = [f for f in range(2363, 7241) if (nf[f]["p1seq"], nf[f]["p1sub"]) != (of[f]["p1seq"], of[f]["p1sub"])]
    if p1: out.append(f"P1 seq/sub differ from f{p1[0]} ({len(p1)} frames) — the legs do not play the same part")
    diff = [f for f in range(2300, 7241) if drawn(no, f) != drawn(oo, f)]
    cnt = {g: sum(1 for f in range(2300, 7241) for p in x.get(f, []) if p["sub"] == "16" and p["vis"] == "01") for g, x in (("native", no), ("ours", oo))}
    msg = (f"drawn class-0x72 pieces equal on {4941 - len(diff)} of 4941 frames"
           + (f" (first difference f{diff[0]}: native {drawn(no, diff[0])[:3]}, ours {drawn(oo, diff[0])[:3]})" if diff else "")
           + f"; drawn sub-0x16 piece-frames native {cnt['native']}, ours {cnt['ours']} (frozen {ORBS})")
    if diff or cnt["native"] != ORBS or cnt["ours"] != ORBS: out.append(msg)
    elif not quiet: print(f"  ok    {msg}")
    if not p1 and not quiet: print("  ok    P1 seq/sub equal on both legs f2363-7240")
    return out
n, o = L["native"], L["ours"]
if MODE == "orbs-dropped": o = (o[0], dropped(o[1]))
if MODE == "orb-displaced": o = (o[0], displaced(o[1]))
for m in judge(n, o): print(f"  FAIL  {m}"); fail = 1
if not MODE:
    for c, f in (("orbs-dropped", dropped), ("orb-displaced", displaced)):
        h = judge(L["native"], (L["ours"][0], f(L["ours"][1])), True)
        if h: print(f"CONTROL FIRED: {c} — the gate fails on the perturbed copy: {h[0]}")
        else: print(f"CONTROL DEAD: {c} — the gate passes on the perturbed copy"); fail = 1
sys.exit(fail)
PY
cat "$W/main.log"
# a dead leg (exit 4) judged nothing: NOT JUDGED under a mode, never a fired control (14z-221c, rule-checker run 2026-11-05-1653)
if [ "${prc:-0}" = 4 ]; then
    vs_ctl_nj "the native or ours leg never reached its END line with every frame 2300-7240"
    echo "FAIL: audit_guard_orbs (a dead leg: nothing judged)"; exit 1
fi
[ "${prc:-0}" = 0 ] || fail=1
if [ -n "$MODE" ]; then
    [ "$fail" = 1 ] || vs_ctl_left_green "$MODE" "FAIL: audit_guard_orbs (control mode)"
    # #369: honoured only on the comparison's own finding in step 2's output
    case "$MODE" in
    orbs-dropped) WANT='^  FAIL  drawn class-0x72 pieces equal on [0-9]+ of 4941 frames .*; drawn sub-0x16 piece-frames native [1-9][0-9]*, ours 0 \(frozen [0-9]+\)$' ;;
    orb-displaced) WANT='^  FAIL  drawn class-0x72 pieces equal on [0-9]+ of 4941 frames \(first difference f[0-9]+: .*; drawn sub-0x16 piece-frames native [1-9][0-9]*, ours [1-9][0-9]* \(frozen [0-9]+\)$' ;;
    *) WANT='' ;;
    esac
    vs_ctl_caught "$W/main.log" "$WANT" || :
    echo "FAIL: audit_guard_orbs (control mode)"; exit 1
fi
if [ "$fail" = 0 ]; then echo "PASS: audit_guard_orbs"; else echo "FAIL: audit_guard_orbs"; exit 1; fi
