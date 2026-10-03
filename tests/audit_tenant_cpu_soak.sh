#!/bin/sh
# audit_tenant_cpu_soak.sh — THE TENANT CPU SOAK: what each tenant does as a CPU opponent on our build, against the same character's CPU on native vsav2, as DISTRIBUTIONS over a long round (GitHub #129, 14z-189)
#
# WHAT: #129 asks whether the tenants' CPU AI is lackluster on our build. Statically their AI blocks are byte-identical
#   to vs2's (14z-189 analysis); this gate measures what the CPU DOES. For each tenant (Phobos, Pyron, Donovan) and
#   two player conditions it reduces one long in-match window per leg to distributions — animation-node entries (the
#   node read back to its vsav2 address through the build's placements), frames per state family +0x06, CPU AI
#   current-command entries +0x241, frames per AI script index +0x205, mean |x1-x2|, airborne frames — and prints the
#   total-variation distance between the legs (tools/cpu_soak_dist.py). It judges no "plays the same": the figures
#   are frozen as measured, and what they mean is the maintainer's to read from the capture sheets.
# HOW: 12 MAME legs (3 tenants x 2 conditions x {ours, native}), 1P arcade. P1 picks by its REAL cursor route
#   (tools/select_paths.py: ours Donovan L,L,D,D and Phobos D,D,D; vs2 Donovan R,R and Phobos L,L,L) and the
#   ladder's OWN draw (PRG:0x0AEF6 / vs2 0x973C) picks the CPU, steered only by the venue byte $FF8121 and the in-use
#   mask $FF8110 poked before the draw — our tenant rows of table A are byte-identical to vs2's (vsavj 0x0B268,
#   vs2 0x09B2A, measured 14z-189), so the same venue and mask draw the same class on both legs: Donovan P1 venue
#   0x02 -> CPU Phobos; Donovan P1 venue 0x04 mask bit 1 -> CPU Pyron; Phobos P1 venue 0x00 mask bit 6 -> CPU
#   Donovan. Pins on both legs: the speed level $FF8116 = 6 from 2000 (the parity rigs' matched level, [VSE-84]),
#   both fighters' HP ($FF8450, $FF8850 = 0x120) and the round timer $FF8109 = 99 from 2880 — ONE stationary round,
#   neither side ever at a lower HP (the first ERIS run without the P2 pin let the active P1 win rounds and end the
#   match, so later in-match frames could belong to the next opponent — 14z-189, the check below now refuses that).
#   The RNG is NOT pinned: the AI's random choices are the subject.
#   Conditions: PASSIVE (P1 still after the confirm) and ACTIVE (a fixed 180-frame P1 cycle from 3000: walk forward,
#   jump, LP, crouch + MK, hold back). field_trace.lua samples every frame from 2880 to FRAMES.
# EXPECTS: every leg LIVE — on EVERY frame of the window P1 and P2 hold the expected classes, P2 its loaded hitbox
#   base, the match is on ($FF8008 == 0x40000) and the pins held (a wrong opponent, a lost round or a broken pin is a
#   DEAD leg, never a pass) — and every analysis line equal to
#   tests/expected/tenant_cpu_soak.txt (FREEZE=1 writes it; MAME runs are deterministic). Both controls fire.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/tenant_cpu_soak.txt tests/lib/controls.sh
#   tests/lua/field_trace.lua tests/lua/pokes_spec.lua tools/cpu_soak_dist.py tools/run_mame.sh tools/setup_mame.sh
#
# POKE READ-BACK (tests/expected/poke_readback.tsv): the pins' check reads the rig's OWN pokes back ($FF8450,
#   $FF8850, $FF8109, $FF8116 — a RIG RECORD that the round stayed stationary); the venue and mask only steer the ladder's
#   draw, whose class write ($FF8B82) and load (+0x60) are the game's own (OBSERVES).
#
# MUST-FIRE: shadow-tool: no-translation — comparing our RAW anim-node pointers with native's, without reading them back through the build's placements, must change the frozen NODE figures (the keys stop meeting), so every NODE figure is proven to rest on the translation (in-gate: on the Phobos passive pair; mode: every pair untranslated, which FAILs the frozen compare)
# MUST-FIRE: perturbed-copy: wrong-character — each tenant's ours leg compared with ANOTHER tenant's native CPU must change the frozen figures, so the instrument can tell one character's CPU from another's (in-gate: ours Phobos vs native Pyron, passive; mode: every pair rotated, which FAILs the frozen compare)
#
# NOT COVERED: the meaning of the AI commands and scripts (not decoded); any player behaviour but the two fixed
#   conditions; a CPU that is losing (P1 never wins a round here), later ladder rungs, difficulty settings other than
#   the default; FBNeo; a frame-level comparison (the legs diverge from the first random draw by construction).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged30] [FRAMES=22880] [FREEZE=1] [KEEP=<dir>]
#        tests/audit_tenant_cpu_soak.sh
#   emulator tier, MAME; 12 legs in parallel, ~20000 match frames each
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
export ROMDIR
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${BUILD:-build/m3b_merged30}"
FRAMES="${FRAMES:-22880}"
EXPECT="$REPO/tests/expected/tenant_cpu_soak.txt"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD";; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no merged build at $BUILD (rompath/vsavjw.zip)"; exit 1; }
[ -f "$BUILD/patch/placements.json" ] || { echo "FAIL: no patch/placements.json in $BUILD"; exit 1; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "FAIL: no vsav2.zip in ROMDIR"; exit 1; }
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  host $(uname -sm); MAME_BIN ${MAME_BIN:-unset (tools/run_mame.sh defaults by set name)}"
echo "build under test: $BUILD ($(shasum "$BUILD/prg/vm3j.04d" | cut -c1-8) vm3j.04d), FRAMES=$FRAMES"
fail=0
PL="$BUILD/patch/placements.json"

# tenant : venue : mask : CPU class : anim region : ours P1 route : vs2 P1 route : P1 class
TENANTS="phobos:02:00000000:16:anim@huitzil:L L D D:R R:19
pyron:04:00000002:17:anim@pyron:L L D D:R R:19
donovan:00:00000040:19:anim:D D D:L L L:16"
field() { echo "$TENANTS" | awk -F: -v t="$1" -v i="$2" '$1 == t { print $i }'; }

mkrpl() { # out cond moves...
    _o=$1; _c=$2; shift 2; _f=1000
    { echo "300-305 sys=C1"; echo "800-803 sys=S1"
      for _m in "$@"; do echo "$_f-$((_f + 2)) p1=$_m"; _f=$((_f + 40)); done
      echo "1700-1702 p1=1"
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
FIELDS="ff8008:l:scr,ff8782:b:p1id,ff8b82:b:p2id,ff8860:l:p2base,ff881c:l:node,ff8806:b:seq,ff8807:b:sub,ff8810:w:x2,ff8814:w:y2,ff8410:w:x1,ff8a05:b:ai205,ff8a41:b:ai241,ff8a2b:b:ai22b,ff8a08:b:ai208,ff8450:w:p1hp,ff8850:w:p2hp,ff8109:b:timer,ff8116:b:lvl"
leg() { # tenant cond side
    _t=$1; _c=$2; _s=$3; _d="$W/${_t}_${_c}_$_s"; rm -rf "$_d"; mkdir -p "$_d"
    if [ "$_s" = ours ]; then _set=vsavjw; _rp="$BUILD/rompath;$ROMDIR"; _mv="$(field "$_t" 6)"
    else _set=vsav2; _rp="$ROMDIR"; _mv="$(field "$_t" 7)"; fi
    # shellcheck disable=SC2086
    mkrpl "$_d/leg.rpl" "$_c" $_mv
    # one literal string, so tools/audit_poke_readback.py's census sees every poked address (its grammar wants a
    # digit frame and a hex or $var value); the pins run to 99999, past any FRAMES, which never reaches them
    _V="$(field "$_t" 2)"; _M="$(field "$_t" 3)"
    _pk="1750-2860:ff8121:$_V;1750-2860:ff8110:$_M;2000-99999:ff8116:06;2880-99999:ff8450:0120;2880-99999:ff8850:0120;2880-99999:ff8109:63"
    ( cd "$_d" && MAME_SANDBOX="$_d/sb" MAME_ROMPATH="$_rp" REPLAY="$_d/leg.rpl" POKES="$_pk" FIELDS="$FIELDS" \
        FIELD_OUT="$_d/trace.txt" FIELD_FROM=2880 FRAMES="$FRAMES" \
        "$REPO/tools/run_mame.sh" "$_set" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$_d/mame.log" 2>&1
      rm -rf "$_d/sb" ) </dev/null 2>/dev/null &
}

echo "== 1. the legs (MAME: ours = the merged build, native = vsav2)"
for t in phobos pyron donovan; do for c in passive active; do for s in ours native; do leg "$t" "$c" "$s"; done; done; done
wait   # a teardown segfault (MFI-12) is not a verdict: the traces decide

echo "== 2. liveness and the pins"
for t in phobos pyron donovan; do for c in passive active; do for s in ours native; do
    _d="$W/${t}_${c}_$s"
    if python3 - "$_d/trace.txt" "$(field "$t" 8)" "$(field "$t" 4)" "$FRAMES" "${t}_${c}_$s" <<'PY'; then :; else fail=1; fi
import sys
path, p1, p2, frames, name = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
rows = {}
try:
    for l in open(path):
        if l.startswith("F "):
            q = l.split(); rows[int(q[1])] = {k: int(v) for k, v in (kv.split("=") for kv in q[2:])}
except FileNotFoundError:
    sys.exit(f"  DEAD  {name}: no trace")
win = [f for f in rows if f >= 2900]
d = rows.get(2900)
bad = []
if not d or d["p1id"] != p1 or d["p2id"] != p2 or d["p2base"] == 0 or d["scr"] != 0x40000:
    bad.append(f"at 2900 p1id/p2id/p2base/scr = {d and (d['p1id'], d['p2id'], d['p2base'], hex(d['scr']))}, want {p1}/{p2}/loaded/0x40000")
if len(win) != frames - 2900 + 1:
    bad.append(f"window has {len(win)} frames, want {frames - 2900 + 1}")
nopin = sum(1 for f in win if rows[f]["p1hp"] != 0x120 or rows[f]["p2hp"] != 0x120 or rows[f]["timer"] != 99 or rows[f]["lvl"] != 6)
if nopin:
    bad.append(f"the pins did not hold on {nopin} frames")
if d:
    off = sum(1 for f in win if rows[f]["scr"] != 0x40000 or rows[f]["p1id"] != p1 or rows[f]["p2id"] != p2 or rows[f]["p2base"] != d["p2base"])
    if off:
        bad.append(f"{off} window frames out of the match or with another pairing (first f{min(f for f in win if rows[f]['scr'] != 0x40000 or rows[f]['p1id'] != p1 or rows[f]['p2id'] != p2 or rows[f]['p2base'] != d['p2base'])})")
if bad:
    print(f"  DEAD  {name}: " + "; ".join(bad)); sys.exit(1)
print(f"  ok    {name}: P1 {p1:#04x} vs CPU {p2:#04x} (base {d['p2base']:#08x}) on all {len(win)} frames, in match, pins held")
PY
done; done; done

echo "== 3. the distributions"
GOT="$W/got.txt"; : > "$GOT"
nxt() { case "$1" in phobos) echo pyron;; pyron) echo donovan;; donovan) echo phobos;; esac; }
for t in phobos pyron donovan; do for c in passive active; do
    _nat="$t"; _raw=""
    vs_ctl_is wrong-character && _nat="$(nxt "$t")"
    vs_ctl_is no-translation && _raw=--raw
    echo "== $t $c" >> "$GOT"
    # shellcheck disable=SC2086
    python3 tools/cpu_soak_dist.py "$W/${t}_${c}_ours/trace.txt" "$W/${_nat}_${c}_native/trace.txt" "$PL" \
        "$(field "$t" 5)" --from 2900 $_raw >> "$GOT" || { echo "  FAIL: cpu_soak_dist.py errored on $t $c"; fail=1; }
done; done
grep -E "^== |^(FRAMES|DIST|AIR|NODE|SEQ|CMD|SCRIPT) " "$GOT" | sed 's/^/    /'

echo "== 4. the must-fire controls (in-gate)"
python3 tools/cpu_soak_dist.py "$W/phobos_passive_ours/trace.txt" "$W/phobos_passive_native/trace.txt" "$PL" anim@huitzil --from 2900 > "$W/ctl_right.txt" || fail=1
python3 tools/cpu_soak_dist.py "$W/phobos_passive_ours/trace.txt" "$W/phobos_passive_native/trace.txt" "$PL" anim@huitzil --from 2900 --raw > "$W/ctl_raw.txt" || fail=1
python3 tools/cpu_soak_dist.py "$W/phobos_passive_ours/trace.txt" "$W/pyron_passive_native/trace.txt" "$PL" anim@huitzil --from 2900 > "$W/ctl_wrong.txt" || fail=1
sh_of() { awk -v k="$2" '$1 == k && $2 == "tvd" { for (i = 1; i <= NF; i++) if ($i == "shared") print $(i + 1) }' "$1"; }
tv_of() { awk -v k="$2" '$1 == k && $2 == "tvd" { print $3 }' "$1"; }
r_sh="$(sh_of "$W/ctl_right.txt" NODE)"; raw_sh="$(sh_of "$W/ctl_raw.txt" NODE)"
if [ -n "$r_sh" ] && [ -n "$raw_sh" ] && [ "$raw_sh" -lt "$r_sh" ]; then
    vs_ctl_fired no-translation "Phobos passive: NODE keys shared $r_sh translated, $raw_sh raw (tvd $(tv_of "$W/ctl_right.txt" NODE) -> $(tv_of "$W/ctl_raw.txt" NODE))"
else
    vs_ctl_dead no-translation "raw pointers shared [$raw_sh] NODE keys against [$r_sh] translated — the translation is not what makes them meet" || fail=1
fi
r_tv="$(tv_of "$W/ctl_right.txt" NODE)"; w_tv="$(tv_of "$W/ctl_wrong.txt" NODE)"
if python3 -c "import sys; sys.exit(0 if float('$w_tv') > float('$r_tv') else 1)" 2>/dev/null \
   && ! cmp -s "$W/ctl_right.txt" "$W/ctl_wrong.txt"; then
    vs_ctl_fired wrong-character "ours Phobos vs native Pyron: NODE tvd $w_tv (same character $r_tv); SEQ $(tv_of "$W/ctl_right.txt" SEQ) -> $(tv_of "$W/ctl_wrong.txt" SEQ), CMD $(tv_of "$W/ctl_right.txt" CMD) -> $(tv_of "$W/ctl_wrong.txt" CMD)"
else
    vs_ctl_dead wrong-character "another character's CPU read NODE tvd [$w_tv] against [$r_tv] — the instrument cannot tell them apart" || fail=1
fi

echo "== 5. the frozen figures"
if [ "${FREEZE:-0}" = 1 ]; then
    [ -z "${VS_CTL:-}" ] || { echo "FAIL: FREEZE=1 refused under CONTROL=$VS_CTL"; exit 1; }
    [ "$fail" = 0 ] || { echo "FAIL: FREEZE=1 refused — the run is not clean"; exit 1; }
    { echo "# tests/expected/tenant_cpu_soak.txt — written by tests/audit_tenant_cpu_soak.sh FREEZE=1 (GitHub #129, 14z-189)."
      echo "# Evidence class: in-emulator (MAME). Per tenant x condition, tools/cpu_soak_dist.py's output on the ours leg"
      echo "# (merged build) against the native vsav2 leg: distributions of node entries, state families, AI commands and"
      echo "# script indices, and their total-variation distances. Figures only, no ROM bytes. VERIFY by re-running."
      cat "$GOT"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1)"; exit 1; }
grep -v '^#' "$GOT" > "$W/got_figures.txt"
if grep -v '^#' "$EXPECT" | diff - "$W/got_figures.txt" > "$W/diff.txt"; then
    echo "  ok    every figure as frozen"
else
    echo "  FAIL  the figures moved ($(grep -c '^[<>]' "$W/diff.txt") line(s)):"; sed 's/^/      /' "$W/diff.txt" | head -20; fail=1
fi

if [ -n "${VS_CTL:-}" ]; then   # the mode's verdict is the gate's own: it must FAIL; a PASS here is a dead control
    if [ "$fail" = 1 ]; then
        vs_ctl_fired "$VS_CTL" "the gate ran with $VS_CTL applied to every pair and failed"
        echo "FAIL: audit_tenant_cpu_soak (control mode)"; exit 1
    fi
    vs_ctl_dead "$VS_CTL" "the gate PASSED with the control applied" || true
    echo "PASS: audit_tenant_cpu_soak (control mode — the control is DEAD)"; exit 0
fi
[ "$fail" = 0 ] && { echo "PASS: audit_tenant_cpu_soak"; exit 0; }
echo "FAIL: audit_tenant_cpu_soak"; exit 1
