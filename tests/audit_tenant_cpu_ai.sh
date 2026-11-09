#!/bin/sh
# audit_tenant_cpu_ai.sh — THE TENANT CPU-AI DECISION POINTS, COUNTED AT THEIR BREAKPOINTS: PHOBOS'S CONTINUATION GUARD
# (BEHAVIOUR A), HIS PORTED CALLER 0x418952, AND VS2'S LOW-ATTACK CROUCH TEST (BEHAVIOUR B), OURS AGAINST NATIVE VSAV2
# (GitHub #129, 14z-215; promoted from the capture worker's ERIS scripts, build/agent215/t129/scripts/, by [VSP-18])
#
# WHAT: the two CPU-AI differences (Behaviour A and Behaviour B) that docs/game/engine_internals.md "The CPU AI action-script system" names, measured as counts
#   of logging-breakpoint stops on the soak's own rig (tests/audit_tenant_cpu_soak.sh: P1 by the real cursor, the CPU by
#   the ladder's own draw steered by venue/mask, speed level 6, HP and timer pinned, the RNG free), ours = the merged build
#   against native vsav2, both on the WIDE MAME build. Per leg it freezes:
#   A  the class-0x10 continuation-check calls (vs2 PRG:0x2CB50 / vsavj PRG:0x2D374, conditional on +0x382 == 0x10), those
#      with +0x1BC != 0, native's refusals at the guard (stops at vs2 PRG:0x2CB7A with +0x1BC != 0), the checks returning
#      1 with +0x1BC != 0 (the return sites vs2 0x025AA6 / 0x056E68, ours 0x41FA4C / 0x418958), and the continuations
#      taken (vs2 0x026B50, ours 0x41EFDE) by +0x1BC before the increment — so ours' +0x1BC 1 -> 2 is the `01` bucket;
#      asserted besides: on native every call with +0x1BC != 0 is refused and no continuation starts at +0x1BC = 1;
#   R  the CPU's entries into state family +0x06 = 0x14 (per-frame trace) and the reaches of the ported caller ours
#      PRG:0x418952 / native PRG:0x056E62 (the `jsr` in the state's handler), with +0x1BC at each reach and d0 at its
#      return; asserted besides: both sides reach it on the CONF=1702 pair, every reach at +0x1BC = 0;
#   B  on every native leg, the Lua copy of vs2 PRG:0x2CD38 (tests/lua/tenant_ai_tap.lua) evaluated at the routine's entry
#      against the routine's RETURN as its callers read it: 0x2CD38 returns its answer in the Z flag, and each of its six
#      callers branches on it with a `bne` at its return address (vs2 0x021A72, 0x021B52, 0x021BE0, 0x022516, 0x0236FE,
#      and the internal bsr.w's 0x02CD18) — so each entry stop (whose logged ret= is the long at the active a7, the
#      return address) is paired with the next stop AT THAT ADDRESS, and the real answer is 1 when SR's Z bit is clear
#      there; every entry must be paired (none unread), 0 disagreements, calls on every native leg but the passive one
#      (a still P1 draws none), and at least one real 1. The routine's own exit sites (0x2CD88, 0x2CD9A, the btst of bit
#      (d3 mod 32) of d4) are kept only as a cross-check (xchk = formula/return mismatches, frozen);
#      and, in each adaptive leg on its own, inside that leg's live window, the EVENT — on vs2: the real test returns 1
#      while the opponent's +0x121 is 0; on ours: a crouch-decision block (vsavj PRG:0x023068, 0x02313E, 0x0231C4,
#      0x023998, 0x024AC8) reached with the shadow 1 and the opponent's +0x121 0 — frozen as a PER-LEG measurement
#      (asserted: the detector fires at least once in each adaptive leg). B is NOT compared between the builds: the two
#      legs' starting positions differ entirely (the maintainer on the #129 captures, 2026-10-31), so the two counts are
#      two separate measurements; a matched-start B capture is a separate piece of work.
#   Only counts are claimed; what they change in play was read by the maintainer on the #129 capture sheets, not here.
# HOW: nine MAME legs under -debug (logging breakpoints whose stops are logged and resumed), at most JOBS (5) at once:
#   pa_native / pa_ours   CPU Phobos, P1 Donovan, ACTIVE (the soak's leg: confirm at 1700)       A, R (0 reaches), B agreement
#   pp_native / pp_ours   the same, PASSIVE (the soak's other Phobos leg)                         A, R
#   p2_native / p2_ours   the same with the confirm moved to 1702 (another RNG stream)              A, R (both sides reach)
#   lw_native / lw_ours   CPU Phobos, adaptive P1 standing LK (CONF=1704, ADAPT=4:48:3000:60)     B event (per leg), B agreement
#   da_native             CPU Donovan, P1 Phobos, ACTIVE (the most native calls of 0x2CD38)         B agreement
#   chosen from the capture worker's 42 legs as the fewest that exercise each claim (A and R on both builds, B's event
#   in one adaptive leg per build); the frozen figures are this rig's, not the worker's table (whose sums run over 15
#   legs a side); the first run on the Mac reproduced every figure the worker's ERIS legs gave for the same rig. Three
#   more legs for the in-gate controls: ctl_guard (pa_native with the guard's breakpoint shifted), ctl_drop (lw_native
#   with the shadow's SHADOW_DROP class), ctl_retshift (lw_native, its six return breakpoints shifted) and ctl_wrong
#   (the native rig on vsavj, 3000 frames); return-flag-swapped re-reads the plain legs' own stops.
# EXPECTS: the header names the reference set (tools/audit_roms.py against docs/checksums.txt), the MAME
#   (tests/lib/mame_ident.sh) and the build (its whole-set key, also a frozen line); every leg ran the set it names (its
#   SYSTEM line), every tap complete (END at FRAMES, emu_clock's ALIGN frames == emulated); every ACTIVE and PASSIVE leg
#   LIVE on every frame of 2900..FRAMES by the soak's own check (in the match, the expected classes, P2's loaded base
#   unchanged, the pins held), every
#   adaptive leg live from 2900 to its frozen last live frame with the pins held throughout (those legs leave the match
#   part-way, reason not measured; the B figures count only inside the window); the assertions above; and every line
#   equal to tests/expected/tenant_cpu_ai.txt (FREEZE=1 writes it; MAME runs are deterministic). Every control fires.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/tenant_cpu_ai.txt tests/lib/controls.sh tests/lib/mame_ident.sh
#   tests/lua/tenant_ai_tap.lua tests/lua/emu_clock.lua tests/lua/pokes_spec.lua tools/run_mame.sh tools/setup_mame.sh
#   tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: no-picture — what it judges are breakpoint-stop counts over whole legs under -debug (thousands of stops a leg), with no frame to show; the #129 capture sheets of these moments were made from the same rig by the capture worker (build/agent215/t129/sheets/, 14z-215) and read by the maintainer
#
# POKE READ-BACK (tests/expected/poke_readback.tsv): the liveness check reads the rig's OWN pins back ($FF8450, $FF8850,
#   $FF8109, $FF8116 — a RIG RECORD that the round stayed stationary, as in the soak); the venue and mask only steer the
#   ladder's draw, whose class write ($FF8B82) is the game's own.
#
# MUST-FIRE: perturbed-copy: guard-tap-shifted — the native refusal breakpoint moved from vs2 PRG:0x2CB7A to 0x2CB7C (an address no leg stops at: 0 stops, measured) must read 0 refusals against the calls with +0x1BC != 0, so the refusal count rests on that breakpoint (in-gate: ctl_guard; mode: every native leg's breakpoint shifted, which FAILs A's refusal assertion and the frozen compare)
# MUST-FIRE: shadow-tool: shadow-class-removed — the Lua copy of vs2 PRG:0x2CD38 with one attack class answered 0 (SHADOW_DROP, the class of the native real-1 calls) must disagree with the real routine, so the 0-disagreement verdict can see a wrong copy (in-gate: ctl_drop; mode: every leg's shadow perturbed — ours' event is read through the same copy — which FAILs B's agreement, ours' event and the frozen compare)
# MUST-FIRE: perturbed-copy: return-tap-shifted — the six return-address breakpoints each moved 2 bytes (0x021A74 ... 0x02CD1A) must leave the native entries of 0x2CD38 with no return read, so B's real side rests on those breakpoints, not on a formula (in-gate: ctl_retshift; mode: every native leg's return breakpoints shifted, which FAILs B's every-entry-paired assertion and the frozen compare)
# MUST-FIRE: perturbed-copy: return-flag-swapped — the return read through SR's C bit (a flag no caller tests) instead of Z must disagree with the shadow (measured: on most calls, C is clear where Z is set), so the agreement rests on the flag the callers branch on (in-gate: the plain legs re-read; mode: every native leg read through C, which FAILs B's agreement and the frozen compare)
# MUST-FIRE: known-bad: wrong-build — the native rig run on vsavj instead of vsav2 must be refused by the leg-identity check (its SYSTEM line), so a native figure can only come from vsav2 (in-gate: ctl_wrong, 3000 frames; mode: every native leg on vsavj, which FAILs the identity check)
#
# NOT COVERED: the shadow on OUR build — it is checked against the real routine only on native legs; vsavj code has no
#   0x2CD38, so its output on the merged build's memory (read at the five crouch blocks) has no real counterpart, and
#   lw_ours's event count rests on the shadow reading ours' opponent records correctly: untested here; the shadow's
#   other classes — every native real 1 here is class 0x02, so its 0x03 / 0x38 / 0x39 branches agree only on real 0s;
#   any native-vs-ours comparison of B (above); Pyron's and Donovan's CPU on Behaviour A (A is
#   Phobos-only by its guard's id test) and B's event for them (no adaptive leg of theirs runs here); the worker's other
#   35 legs, the sweep rig, low-attack specials; what either behaviour changes in play (captures, the maintainer's); why
#   the adaptive legs leave the match;
#   any difficulty but the default, any ladder rung but the first; FBNeo and MiSTer; frame-level comparison (the legs
#   diverge from the first random draw by construction).
#
# Usage: ROMDIR=... [MAME_BIN=~/.cache/vampire-saved/mame/cps2] [BUILD=build/m3b_merged34] [JOBS=5] [FREEZE=1] [KEEP=<dir>]
#        tests/audit_tenant_cpu_ai.sh
#   emulator tier, MAME; 12 legs of 22,880 frames (one of 3,000), JOBS at once; ~1 min on the Mac (M2 Pro) at JOBS=5
# SHARES: self
set -u
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
export ROMDIR
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
cd "$REPO"
BUILD="${BUILD:-build/m3b_merged34}"
FRAMES=22880
JOBS="${JOBS:-5}"
# MAME_BIN is PINNED (test_mame_bin_pinned): the WIDE build, which also runs native vsav2 (the soak's choice)
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
EXPECT="$REPO/tests/expected/tenant_cpu_ai.txt"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$HERE/$(basename "$0")"; MODE="${VS_CTL:-}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD";; esac
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME binary at $MAME_BIN"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no merged build at $BUILD (rompath/vsavjw.zip)"; exit 1; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep >/dev/null 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
SETKEY="$(python3 "$REPO/tools/build_fingerprint.py" "$BUILD/rompath;$ROMDIR" --set vsavjw --set-key 2>/dev/null)" || true
[ -n "$SETKEY" ] || { echo "FAIL: no whole-set key for the build at $BUILD (tools/build_fingerprint.py)"; exit 1; }
REGNAME="$(awk -F'\t' -v k="$SETKEY" '$1 == k && $1 !~ /^#/ {print $2}' "$REPO/tests/expected/registry.tsv")"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else
    W="$(mktemp -d)" || { echo "FAIL: audit_tenant_cpu_ai — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; fi
W="$(cd "$W" && pwd)"
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsav2.zip sha1 $(python3 -c 'import hashlib,sys; print(hashlib.sha1(open(sys.argv[1],"rb").read()).hexdigest())' "$ROMDIR/vsav2.zip")"
echo "  build $BUILD: whole-set key $SETKEY (registry row: ${REGNAME:-none})"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); host $(hostname) $(uname -sm)"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

# THE RIG — tests/audit_tenant_cpu_soak.sh's, verbatim in its routes, steering, pins and active cycle; CONF moves the
# confirm press (1700 in the soak), ADAPT is the instrument's adaptive P1 (tenant_ai_tap.lua).
# tenant : venue : mask : CPU class : ours P1 route : vs2 P1 route : P1 class
TENANTS="phobos:02:00000000:16:L L D D:R R:19
donovan:00:00000040:19:D D D:L L L:16"
field() { echo "$TENANTS" | awk -F: -v t="$1" -v i="$2" '$1 == t { print $i }'; }
mkrpl() { # out cond conf moves...
    _o=$1; _c=$2; _cf=$3; shift 3; _f=1000
    { echo "300-305 sys=C1"; echo "800-803 sys=S1"
      for _m in "$@"; do echo "$_f-$((_f + 2)) p1=$_m"; _f=$((_f + 40)); done
      echo "$_cf-$((_cf + 2)) p1=1"
      if [ "$_c" = active ]; then
          _f=3000
          while [ $((_f + 180)) -le "$FRAMES" ]; do
              echo "$_f-$((_f + 29)) p1=R"; echo "$((_f + 40))-$((_f + 42)) p1=U"
              echo "$((_f + 80))-$((_f + 81)) p1=1"; echo "$((_f + 100))-$((_f + 112)) p1=D"
              echo "$((_f + 104))-$((_f + 105)) p1=D5"; echo "$((_f + 130))-$((_f + 160)) p1=L"
              _f=$((_f + 180))
          done
      fi; } > "$_o"
}
TRACEF="ff8008:l:scr,ff8782:b:p1id,ff8b82:b:p2id,ff8860:l:p2base,ff8806:b:seq,ff8450:w:p1hp,ff8850:w:p2hp,ff8109:b:timer,ff8116:b:lvl"
# the breakpoints: A (class 0x10 only), R, B — native vs2 and ours (the merged build); GUARD is the refusal site
GUARD=2cb7a; DROP=""; NATSET=vsav2; NATFR=$FRAMES; RFLAG=Z
RETS="21a72|21b52|21be0|22516|236fe|2cd18"   # the return addresses of 0x2CD38's six callers (each followed by a bne)
DROPCLASS=02   # the class of EVERY native real-1 call of 0x2CD38 in these legs (measured: the frozen B lines' real1_class)
# THE CONTROLS' PERTURBATIONS — one function each, called by the in-gate leg and by the mode
perturb() { case "$1" in guard-tap-shifted) GUARD=2cb7c;; shadow-class-removed) DROP=$DROPCLASS;; wrong-build) NATSET=vsavj; NATFR=3000;;
    return-tap-shifted) RETS="21a74|21b54|21be2|22518|23700|2cd1a";; return-flag-swapped) RFLAG=C;; esac; }
nat_sites() { echo "2cb50@b@(a6+382)==10|$1|25aa6@b@(a6+382)==10|26b50@b@(a6+382)==10|56d84|56e1c|56e24|56e62|56e68|2cd38|2cd88|2cd9a|$RETS"; }
# 14z-216 (M24): the seven ours sites re-derived +0xDC0 — #294's records block ahead of Phobos's regions (code@huitzil
# 0x414140 -> 0x414F00, x02592a and x026142 likewise); each new address holds the old one's opcode bytes (M23: 41d40c,
# 41e21e, 416234, 4162cc, 4162d4, 416312, 416318; build/agent216/m24/eris_reds/). A placement constant follows the romset.
# 14z-220 (M25): the seven ours sites re-derived +0x1610 — #356's speed-line copy and #345 A1b's table copy at the
# wide_ext head (0x400010, 0x4013E0) push every later placement; each new address holds the old one's opcode bytes
# (M24: 41e1cc, 41efde, 416ff4, 41708c, 417094, 4170d2, 4170d8). A placement constant follows the romset.
# 14z-222 (M26): the seven ours sites re-derived +0x270 — #357's two copies at the wide_ext head (0x400310, 0x400480)
# push every later placement; each new address holds the old one's 8 opcode-view bytes (build/agent222/m26/cpu_ai_sites.txt;
# M25: 41f7dc, 4205ee, 418604, 41869c, 4186a4, 4186e2, 4186e8).
OURS_SITES="2d374@b@(a6+382)==10|41fa4c|42085e|418874|41890c|418914|418952|418958|23068|2313e|231c4|23998|24ac8"
OURS_SHADOW="23068,2313e,231c4,23998,24ac8"
leg() { # name tenant cond side conf adapt guard drop set frames
    _n=$1; _t=$2; _c=$3; _s=$4; _cf=$5; _ad=$6; _g=$7; _dr=$8; _set=$9; _fr=${10}; _d="$W/$_n"; rm -rf "$_d"; mkdir -p "$_d"
    if [ "$_s" = ours ]; then _rp="$BUILD/rompath;$ROMDIR"; _mv="$(field "$_t" 5)"; _si="$OURS_SITES"; _sh="$OURS_SHADOW"
    else _rp="$ROMDIR"; _mv="$(field "$_t" 6)"; _si="$(nat_sites "$_g")"; _sh=2cd38; fi
    # shellcheck disable=SC2086
    mkrpl "$_d/leg.rpl" "$_c" "$_cf" $_mv
    _V="$(field "$_t" 2)"; _M="$(field "$_t" 3)"
    _pk="1750-2860:ff8121:$_V;1750-2860:ff8110:$_M;2000-99999:ff8116:06;2880-99999:ff8450:0120;2880-99999:ff8850:0120;2880-99999:ff8109:63"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$_rp" REPLAY="$_d/leg.rpl" POKES="$_pk" FRAMES="$_fr" \
        SITES="$_si" SHADOW="$_sh" SHADOW_DROP="$_dr" ADAPT="$_ad" FIELDS="$TRACEF" OUT="$_d/tap.txt" ALIGN_OUT="$_d/align.txt" \
        timeout -k 30 3000 "$REPO/tools/run_mame.sh" "$_set" -debug -debugger none \
        -autoboot_script "$REPO/tests/lua/tenant_ai_tap.lua" > "$_d/mame.log" 2>&1
      rm -rf "$_d/sb" ) </dev/null 2>/dev/null || true   # a teardown segfault is not a verdict: the tap decides
    echo "$_n $_t $_c $_s $_set $_fr" > "$_d/leg.id"
}
pids=""; nj=0
launch() { "$@" & pids="$pids $!"; nj=$((nj + 1)); if [ "$nj" -ge "$JOBS" ]; then for p in $pids; do wait "$p"; done; pids=""; nj=0; fi; }
drain() { for p in $pids; do wait "$p"; done; pids=""; nj=0; }

LEGS="pa_native pa_ours pp_native pp_ours p2_native p2_ours lw_native lw_ours da_native"
[ -n "$MODE" ] && perturb "$MODE"
echo "== 1. the legs (MAME -debug: ours = the merged build, native = vsav2)${MODE:+ — under $MODE}"
LW="4:48:3000:60"
launch leg pa_native phobos active native 1700 "" "$GUARD" "$DROP" "$NATSET" "$NATFR"
launch leg pa_ours   phobos active ours   1700 "" "$GUARD" "$DROP" vsavjw "$FRAMES"
launch leg pp_native phobos passive native 1700 "" "$GUARD" "$DROP" "$NATSET" "$NATFR"
launch leg pp_ours   phobos passive ours   1700 "" "$GUARD" "$DROP" vsavjw "$FRAMES"
launch leg p2_native phobos active native 1702 "" "$GUARD" "$DROP" "$NATSET" "$NATFR"
launch leg p2_ours   phobos active ours   1702 "" "$GUARD" "$DROP" vsavjw "$FRAMES"
launch leg lw_native phobos lowrig native 1704 "$LW" "$GUARD" "$DROP" "$NATSET" "$NATFR"
launch leg lw_ours   phobos lowrig ours   1704 "$LW" "$GUARD" "$DROP" vsavjw "$FRAMES"
launch leg da_native donovan active native 1700 "" "$GUARD" "$DROP" "$NATSET" "$NATFR"
ctl_leg() { # the in-gate controls' own legs, each perturbed by the mode's own function (launch runs it in a subshell)
    perturb "$1"
    case "$1" in
        guard-tap-shifted)    leg ctl_guard phobos active native 1700 "" "$GUARD" "" vsav2 "$FRAMES" ;;
        shadow-class-removed) leg ctl_drop phobos lowrig native 1704 "$LW" 2cb7a "$DROP" vsav2 "$FRAMES" ;;
        wrong-build)          leg ctl_wrong phobos active native 1700 "" 2cb7a "" "$NATSET" "$NATFR" ;;
        return-tap-shifted)   leg ctl_retshift phobos lowrig native 1704 "$LW" 2cb7a "" vsav2 "$FRAMES" ;;
    esac
}
if [ -z "$MODE" ]; then for c in guard-tap-shifted shadow-class-removed wrong-build return-tap-shifted; do launch ctl_leg "$c"; done; fi
drain

echo "== 2. the analysis"
GOT="$W/got.txt"
python3 - "$W" "$FRAMES" "$SETKEY" "$MODE" "$LEGS" "$DROPCLASS" "$RFLAG" > "$GOT" 2> "$W/analysis.err" <<'PY'
import sys, os
from collections import Counter
W, FRAMES, SETKEY, MODE, LEGS, DROPC, RFLAG = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5].split(), sys.argv[6], sys.argv[7]
FLAGBIT = {"Z": 0x4, "C": 0x1}   # SR bits: the callers branch on Z (bne); C is the return-flag-swapped control's reading
RETSITES = ("021a72", "021b52", "021be0", "022516", "0236fe", "02cd18")
EXP = {"phobos": (0x13, 0x10), "donovan": (0x10, 0x13)}   # (P1 class, CPU class)
WANTSET = {"native": "vsav2", "ours": "vsavjw"}
def load(n):
    d = f"{W}/{n}"
    lid = open(f"{d}/leg.id").read().split()
    L = {"name": n, "tenant": lid[1], "cond": lid[2], "side": lid[3], "set": lid[4], "frames": int(lid[5]),
         "system": None, "drop": None, "S": [], "F": {}, "site": {}, "end": None, "align": None}
    try:
        for l in open(f"{d}/tap.txt"):
            q = l.split()
            if not q: continue
            if q[0] == "S":
                r = dict(kv.split("=") for kv in q[3:]); r["f"] = int(q[1]); r["pc"] = q[2]; L["S"].append(r)
            elif q[0] == "F":
                L["F"][int(q[1])] = {k: int(v) for k, v in (kv.split("=") for kv in q[2:])}
            elif q[0] == "SYSTEM": L["system"] = q[1]
            elif q[0] == "SHADOW_DROP": L["drop"] = q[1]
            elif q[0] == "SITE": L["site"][q[1]] = int(q[2])
            elif q[0] == "END": L["end"] = dict(kv.split("=") for kv in q[1:])
    except FileNotFoundError:
        pass
    try:
        a = open(f"{d}/align.txt").read().split()
        L["align"] = (int(a[a.index("frames") + 1]), int(a[a.index("emulated") + 1]))
    except (FileNotFoundError, ValueError, IndexError):
        pass
    return L
def complete(L):
    """'' when the tap ran to its last frame, else why not"""
    if L["system"] is None: return "no tap output"
    if not L["end"] or int(L["end"]["frames"]) != L["frames"]: return f"tap END {L['end']} short of {L['frames']} frames"
    if not L["align"] or L["align"][0] != L["align"][1] or L["align"][0] != L["frames"]: return f"ALIGN frames/emulated {L['align']}, want {L['frames']}"
    return ""
def identity(L):
    want = WANTSET[L["side"]]
    return "" if L["system"] == want else f"ran {L['system']}, not {want}"
def live(L):
    """(ok, last live frame, why): active and passive legs live on every frame 2900..FRAMES; adaptive legs from 2900 to the frame
    before the first frame out of the match or with another pairing, the pins held throughout"""
    p1, p2 = EXP[L["tenant"]]; F = L["F"]; d = F.get(2900)
    if not d or d["p1id"] != p1 or d["p2id"] != p2 or d["p2base"] == 0 or d["scr"] != 0x40000:
        return False, None, f"at 2900 p1id/p2id/p2base/scr = {d and (d['p1id'], d['p2id'], d['p2base'], hex(d['scr']))}, want {p1}/{p2}/loaded/0x40000"
    end = None
    for f in range(2900, L["frames"] + 1):
        r = F.get(f)
        if r is None: return False, None, f"no trace at f{f}"
        if r["scr"] != 0x40000 or r["p1id"] != p1 or r["p2id"] != p2 or r["p2base"] != d["p2base"]:
            end = f - 1; break
    end = end if end is not None else L["frames"]
    nopin = [f for f in range(2900, end + 1) if (F[f]["p1hp"], F[f]["p2hp"], F[f]["timer"], F[f]["lvl"]) != (0x120, 0x120, 99, 6)]
    if nopin: return False, end, f"the pins did not hold on {len(nopin)} frames (first f{nopin[0]})"
    if L["cond"] != "lowrig" and end != L["frames"]:
        return False, end, f"left the match or the pairing at f{end + 1}"
    return True, end, ""
def A(L):
    nat = L["side"] == "native"
    entry, ret, cont = ("02cb50", "025aa6", "026b50") if nat else ("02d374", "41fa4c", "42085e")
    S = L["S"]
    calls = [s for s in S if s["pc"] == entry]
    nz = sum(1 for s in calls if s["c1bc"] != "00")
    refused = sum(1 for s in S if s["pc"] == "02cb7a" and s["c1bc"] != "00") if nat else None
    r1 = 0; last = None
    for s in S:
        if s["pc"] == entry: last = s
        elif s["pc"] in (ret, "056e68", "418958") and last is not None:
            if (int(s["d0"], 16) & 0xff) and last["c1bc"] != "00": r1 += 1
            last = None
    cc = Counter(s["c1bc"] for s in S if s["pc"] == cont)
    c1 = [s["f"] for s in S if s["pc"] == cont and s["c1bc"] == "01"]
    return dict(calls=len(calls), nz=nz, refused="-" if refused is None else refused, ret1nz=r1, cont=dict(sorted(cc.items())), cont1=c1)
def R(L):
    nat = L["side"] == "native"
    site, rsite = ("056e62", "056e68") if nat else ("418952", "418958")
    ent = []; prev = None
    for f in sorted(L["F"]):
        if f < 2900: continue
        s = L["F"][f]["seq"]
        if s == 0x14 and prev != 0x14: ent.append(f)
        prev = s
    S = L["S"]; c1bc = Counter(); d0 = Counter(); last = None
    for s in S:
        if s["pc"] == site: c1bc[s["c1bc"]] += 1; last = s
        elif s["pc"] == rsite and last is not None:
            d0[int(s["d0"], 16) & 0xff] += 1; last = None
    return dict(entries=ent, reach=L["site"].get(site, 0), c1bc=dict(sorted(c1bc.items())), d0=dict(sorted(d0.items())))
def B(L, end, flag=None):
    S = L["S"]; bit = FLAGBIT[flag or RFLAG]
    if L["side"] == "native":
        # each entry is paired with the next stop at ITS return address (ret= at the entry: the long at the active a7);
        # the real answer is the flag the callers' bne reads there (rts leaves the flags as the routine set them)
        calls = 0; unread = 0; agree = Counter(); disagree = []; cls1 = Counter(); ev = []; res = Counter(); xchk = 0
        last = None; fx = None
        for s in S:
            if s["pc"] == "02cd38":
                calls += 1
                if last is not None: unread += 1
                last = s; fx = None
            elif s["pc"] in ("02cd88", "02cd9a") and last is not None:
                fx = 0 if s["pc"] == "02cd88" else (int(s["d4"], 16) >> (int(s["d3"], 16) & 31)) & 1
            elif last is not None and s["pc"] == last["ret"]:
                real = 0 if int(s["sr"], 16) & bit else 1
                if fx is not None and fx != real: xchk += 1
                ok = last.get("sh") == str(real)
                agree[ok] += 1
                if not ok: disagree.append((last["f"], last.get("sh"), real, last.get("shc")))
                if real: cls1[last.get("shc")] += 1
                if 2900 <= last["f"] <= end:
                    res[(real, last["o121"])] += 1
                    if real and last["o121"] == "00": ev.append(last["f"])
                last = None
        if last is not None: unread += 1
        rets = dict(sorted(Counter(s["ret"] for s in S if s["pc"] == "02cd38").items()))
        return dict(calls=calls, unread=unread, disagree=len(disagree), first_disagree=disagree[:3], real1=sum(cls1.values()),
                    real1_class=dict(sorted(cls1.items())), xchk=xchk, rets=rets, live=dict(sorted(res.items())), event=ev)
    b = [s for s in S if s["pc"] in ("023068", "02313e", "0231c4", "023998", "024ac8") and 2900 <= s["f"] <= end]
    c = Counter((s.get("sh"), s["o121"]) for s in b)
    ev = [s["f"] for s in b if s.get("sh") == "1" and s["o121"] == "00"]
    return dict(blocks=len(b), live=dict(sorted(c.items())), event=ev)
def fmt(d): return " ".join(f"{k}={v}".replace(" ", "") for k, v in d.items() if not k.startswith("first_"))

legs = {n: load(n) for n in LEGS}
ctl = {n: load(n) for n in ("ctl_guard", "ctl_drop", "ctl_wrong", "ctl_retshift") if os.path.isdir(f"{W}/{n}")}
P = sys.stderr   # the verdict stream; stdout is the frozen figures
bad = []; dead = []; refused = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg, file=P)
    if not ok: bad.append(msg)
# --- the plant (a mode whose perturbation did not reach the legs measured nothing it claims)
if MODE:
    nat = [L for L in legs.values() if L["side"] == "native"]
    if MODE == "guard-tap-shifted": planted = all("02cb7c" in L["site"] and "02cb7a" not in L["site"] for L in nat)
    elif MODE == "shadow-class-removed": planted = all(L["drop"] == DROPC for L in legs.values())
    elif MODE == "return-tap-shifted": planted = all("021a74" in L["site"] and not set(RETSITES) & set(L["site"]) for L in nat)
    elif MODE == "return-flag-swapped": planted = RFLAG == "C"
    else: planted = all(L["system"] == "vsavj" for L in nat)
    print("PLANT " + ("applied" if planted else "missing"), file=P)
    if not planted: sys.exit(3)
# --- 1. complete and identity
for n, L in legs.items():
    why = complete(L)
    if why: dead.append(f"{n}: {why}")
for n, L in legs.items():
    why = identity(L)
    if why: refused.append(f"{n}: {why}")
for m in refused: print(f"  FAIL  identity: {m} — refused, nothing it measured is judged", file=P)
if refused: sys.exit(5)
print(f"  ok    identity: {len(legs)} legs each ran the set it names ({', '.join(sorted({L['system'] for L in legs.values()}))})", file=P)
if dead:
    for m in dead: print(f"  DEAD  {m}", file=P)
    sys.exit(4)
# --- 2. liveness
print(f"BUILD {SETKEY}")
ends = {}
for n, L in legs.items():
    ok, end, why = live(L)
    if not ok: dead.append(f"{n}: {why}"); print(f"  DEAD  {n}: {why}", file=P); continue
    ends[n] = end
    print(f"LIVE {n} {L['system']} window=2900-{end}")
    print(f"  ok    {n}: live 2900-{end} ({end - 2899} frames){' — the whole window' if end == L['frames'] else ''}, pins held", file=P)
if dead: sys.exit(4)
# --- 3. Behaviour A, R, B
a = {}; r = {}; b = {}
for n, L in legs.items():
    if L["tenant"] == "phobos" and L["cond"] in ("active", "passive"):
        a[n] = A(L); print(f"A {n} {fmt(a[n])}")
        r[n] = R(L); print(f"R {n} {fmt(r[n])}")
for n, L in legs.items():
    b[n] = B(L, ends[n]); print(f"B {n} {fmt(b[n])}")
natA = [n for n in a if legs[n]["side"] == "native"]; oursA = [n for n in a if legs[n]["side"] == "ours"]
say(all(a[n]["refused"] == a[n]["nz"] and a[n]["nz"] > 0 for n in natA),
    "A native: every class-0x10 call with +0x1BC != 0 refused at the guard: " + ", ".join(f"{n} {a[n]['refused']}/{a[n]['nz']}" for n in natA))
say(all(not a[n]["cont1"] and a[n]["ret1nz"] == 0 for n in natA),
    "A native: no continuation at +0x1BC = 1, no check returning 1 with +0x1BC != 0: " + ", ".join(f"{n} {len(a[n]['cont1'])}/{a[n]['ret1nz']}" for n in natA))
say(sum(len(a[n]["cont1"]) for n in oursA) > 0,
    "A ours: continuations with +0x1BC 1 -> 2: " + ", ".join(f"{n} {len(a[n]['cont1'])} at {a[n]['cont1']}" for n in oursA))
say(r["p2_native"]["reach"] > 0 and r["p2_ours"]["reach"] > 0 and all(set(r[n]["c1bc"]) <= {"00"} for n in r),
    "R the ported caller reached on both sides of the CONF=1702 pair (native 0x056E62 %d, ours 0x418952 %d), +0x1BC 0 at every reach; soak pair %d / %d"
    % (r["p2_native"]["reach"], r["p2_ours"]["reach"], r["pa_native"]["reach"], r["pa_ours"]["reach"]))
natB = [n for n in b if legs[n]["side"] == "native"]
say(all(b[n]["unread"] == 0 for n in natB),
    "B every native entry of 0x2CD38 paired with a stop at its own return address: " + ", ".join(f"{n} {b[n]['calls'] - b[n]['unread']}/{b[n]['calls']} (unread {b[n]['unread']})" for n in natB))
say(all(b[n]["disagree"] == 0 for n in natB) and all(b[n]["calls"] - b[n]["unread"] > 0 for n in natB if legs[n]["cond"] != "passive") and sum(b[n]["real1"] for n in natB) > 0,
    "B the Lua copy of 0x2CD38 agrees with the routine's RETURN (SR's %s bit at the callers' bne) on every native call: " % RFLAG
    + ", ".join(f"{n} {b[n]['calls'] - b[n]['unread'] - b[n]['disagree']}/{b[n]['calls'] - b[n]['unread']} (real 1 at the return: {b[n]['real1']}; exit-site formula mismatches {b[n]['xchk']})" for n in natB)
    + "".join(f"; first disagreements {n} {b[n]['first_disagree']}" for n in natB if b[n]["disagree"]))
for n in ("lw_native", "lw_ours"):   # per-leg measurements, never compared (the two legs do not start alike)
    say(len(b[n]["event"]) > 0, f"B {n}'s own event count (a per-leg measurement, not compared with the other build): {len(b[n]['event'])} at {b[n]['event']}")
# --- 4. the in-gate controls (a plain run only)
if not MODE:
    def ctl_line(name, fired, ev):
        print(f"CONTROL FIRED: {name} — {ev}" if fired else f"CONTROL DEAD: {name} — {ev}", file=P)
        if not fired: bad.append(name)
    k = ctl.get("ctl_guard")
    if k and not complete(k) and not identity(k) and live(k)[0]:
        ka = A(k)
        ctl_line("guard-tap-shifted", ka["refused"] == 0 and ka["nz"] > 0 and ka["refused"] != ka["nz"],
                 f"with the breakpoint at 0x2CB7C the refusals read {ka['refused']} against {ka['nz']} calls with +0x1BC != 0 (the real site: {a['pa_native']['refused']}/{a['pa_native']['nz']}); 0x2CB7C stopped {k['site'].get('02cb7c')} times")
    else:
        ctl_line("guard-tap-shifted", False, f"its leg did not complete live: {k and (complete(k) or identity(k) or live(k)[2])}")
    k = ctl.get("ctl_drop")
    if k and not complete(k) and not identity(k):
        kb = B(k, k["frames"])
        ctl_line("shadow-class-removed", k["drop"] == DROPC and kb["disagree"] > 0,
                 f"SHADOW_DROP {k['drop']}: {kb['disagree']} disagreements of {kb['calls']} calls (first {kb['first_disagree']}); the unperturbed lw_native {b['lw_native']['disagree']}")
    else:
        ctl_line("shadow-class-removed", False, f"its leg did not complete: {k and (complete(k) or identity(k))}")
    k = ctl.get("ctl_retshift")
    if k and not complete(k) and not identity(k):
        kb = B(k, k["frames"])
        ctl_line("return-tap-shifted", kb["calls"] > 0 and kb["unread"] == kb["calls"],
                 f"with the return breakpoints moved 2 bytes, {kb['unread']} of {kb['calls']} entries have no return read (the real sites: lw_native {b['lw_native']['unread']} of {b['lw_native']['calls']}); shifted sites stopped {sum(v for a, v in k['site'].items() if a not in ('02cd38',) and a in ('021a74', '021b54', '021be2', '022518', '023700', '02cd1a'))} times")
    else:
        ctl_line("return-tap-shifted", False, f"its leg did not complete: {k and (complete(k) or identity(k))}")
    sw = {n: B(legs[n], ends[n], flag="C") for n in natB}
    nsw = sum(x["disagree"] for x in sw.values())
    ctl_line("return-flag-swapped", nsw > 0,
             f"the plain legs' returns read through SR's C bit: {nsw} disagreements over {sum(x['calls'] - x['unread'] for x in sw.values())} paired calls; through Z: {sum(b[n]['disagree'] for n in natB)}")
    k = ctl.get("ctl_wrong")
    ctl_line("wrong-build", bool(k and k["system"] == "vsavj" and identity(k)),
             f"the native rig on {k and k['system']}: the identity check says {k and identity(k)!r}")
sys.exit(1 if bad else 0)
PY
rc=$?
cat "$W/analysis.err" | grep -v '^Traceback\|^  File\|^    ' || true
if grep -q '^Traceback' "$W/analysis.err"; then
    sed -n '/^Traceback/,$p' "$W/analysis.err"
    echo "NOT JUDGED: the analysis crashed"; echo "FAIL: audit_tenant_cpu_ai"; exit 1
fi
if [ "$rc" = 3 ]; then echo "REFUSED: CONTROL=$MODE — the plant did not reach the legs (above)"; exit 3; fi
if [ "$rc" = 5 ]; then echo "FAIL: audit_tenant_cpu_ai (a leg ran another set than it names: refused before any figure)"; exit 1; fi
if [ "$rc" = 4 ]; then
    for l in $LEGS; do [ -f "$W/$l/mame.log" ] && tail -2 "$W/$l/mame.log" | sed "s|^|    $l: |"; done
    [ -n "$MODE" ] && echo "NOT JUDGED: a leg is dead or incomplete under $MODE, so this run judged nothing"
    echo "FAIL: audit_tenant_cpu_ai (a leg is dead or incomplete)"; exit 1
fi
fail=0; [ "$rc" = 0 ] || fail=1
grep -E '^(BUILD|LIVE|A|R|B) ' "$GOT" | sed 's/^/    /'

echo "== 3. the frozen figures"
if [ "${FREEZE:-0}" = 1 ]; then
    [ -z "$MODE" ] || { echo "FAIL: FREEZE=1 refused under CONTROL=$MODE"; exit 1; }
    [ "$fail" = 0 ] || { echo "FAIL: FREEZE=1 refused — the run is not clean"; exit 1; }
    { echo "# tests/expected/tenant_cpu_ai.txt — written by tests/audit_tenant_cpu_ai.sh FREEZE=1 (GitHub #129, 14z-215)."
      echo "# Evidence class: in-emulator (MAME -debug, logging breakpoints). Per leg: the build's whole-set key, each leg's"
      echo "# live window, Behaviour A (class-0x10 continuation-check calls, +0x1BC != 0, native refusals, returns of 1 with"
      echo "# +0x1BC != 0, continuations by +0x1BC before the increment and the frames of the 01 bucket), R (state 0x14 entries,"
      echo "# the ported caller's reaches, +0x1BC and d0 at each), B (native: entries of 0x2CD38, entries with no return read,"
      echo "# shadow-vs-return disagreements, real 1s at the return by class, exit-site formula mismatches, entries per return"
      echo "# address, the live (real, opponent +0x121) table and event frames; ours: crouch-block stops by (shadow, opponent"
      echo "# +0x121) and event frames — B's event counts are per leg, never compared between the builds)."
      echo "# Counts, frames and addresses only, no ROM bytes. VERIFY by re-running."
      cat "$GOT"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1)"; exit 1; }
if grep -v '^#' "$EXPECT" | diff - "$GOT" > "$W/diff.txt"; then
    echo "  ok    every figure as frozen ($(grep -vc '^#' "$EXPECT") lines)"
else
    echo "  FAIL  the figures moved ($(grep -c '^[<>]' "$W/diff.txt") line(s)):"; sed 's/^/      /' "$W/diff.txt" | head -20; fail=1
fi

if [ -n "$MODE" ]; then   # the mode's verdict is the gate's own: it must FAIL
    [ "$fail" = 1 ] && { echo "FAIL: audit_tenant_cpu_ai (control mode $MODE)"; exit 1; }
    vs_ctl_left_green "$MODE" "FAIL: audit_tenant_cpu_ai (control mode $MODE left it green)"
fi
[ "$fail" = 0 ] && { echo "PASS: audit_tenant_cpu_ai — Behaviour A (native refuses every class-0x10 continuation at +0x1BC != 0, ours continues), the ported caller 0x418952 reached on both sides, the 0x2CD38 copy agrees on every native call, each adaptive leg's own B event count, all as frozen"; exit 0; }
echo "FAIL: audit_tenant_cpu_ai"; exit 1
