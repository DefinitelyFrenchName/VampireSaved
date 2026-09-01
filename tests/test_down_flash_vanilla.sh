#!/bin/sh
# test_down_flash_vanilla.sh — GitHub #113 ground truth (14z-112; #113 CLOSED
# 2026-09-01 as vanilla, board-confirmed — this gate is what keeps that verdict
# honest, so it stays): the one-frame
# WHOLE-SCREEN WHITE at a down is VANILLA Vampire Savior behaviour, not ours.
#
# Runs tests/lua/inp_probe.lua (per-frame framebuffer fnv1a64 + fighter death
# flags) on STOCK vsavj with 104_1p_auto_ko_win.rpl (a real KO at ~f6550, no
# pokes needed — measured this session) and asserts the WHITE-FRAME INVENTORY:
#   * the all-white hash (eab1fb569cb99b25 at 384x224, measured on merged AND
#     vanilla) appears exactly at the attributable events — the match-intro
#     pair (two frames, 2 apart, t=63 before HP is set), ONE frame at match
#     start (150..220 after HP is set to 288 — measured +183 on both), and ONE frame 50..120 frames after the
#     first death flag (+0x11F) rises;
#   * and NOWHERE ELSE (negative control: a white frame with no attributable
#     event FAILS — that would be a new flash, ours or the emulator's).
# Measured 14z-112: vanilla 104 -> 1909/1911, 2148, 6646 (down at 6550, +96);
# merged play-merged-m9-01 -> same shape at 864/866, 1103, 6153 (+79), 7853
# (+96), 17272 (+57). The +N varies with the fall animation; the window is
# generous on purpose — the claim is "one, after the down", not the offset.
# Usage: ROMDIR=... [MAME_BIN=<ref or wide binary>] tests/test_down_flash_vanilla.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
[ -x "$BIN" ] || BIN="$HOME/.cache/vampire-saved/mame/cps2"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"
MAME_BIN="$BIN" MAME_SANDBOX="$W/sb" REPLAY="$REPO/tests/replays/104_1p_auto_ko_win.rpl" \
  MAX_FRAMES=7000 CHECKSUM_OUT="$W/probe.log" \
  tools/run_mame.sh vsavj -autoboot_script "$REPO/tests/lua/inp_probe.lua" > "$W/out" 2>&1 || true
grep -q '^END 7000' "$W/probe.log" || { echo "FAIL test_down_flash_vanilla: probe did not finish"; tail -3 "$W/out"; exit 1; }
python3 - "$W/probe.log" <<'PY'
import sys, re
WHITE = "eab1fb569cb99b25"
rows = []
for ln in open(sys.argv[1]):
    if not ln.startswith("V "): continue
    f = ln.split()
    d = dict(kv.split("=") for kv in f[3:])
    rows.append((int(f[1]), f[2], int(d["hp1"]), int(d["hp2"]), d["d1"], d["d2"], int(d["t"], 16)))
white = [r[0] for r in rows if r[1] == WHITE]
by = {r[0]: r for r in rows}
first_down = next((r[0] for r in rows if r[4] != "00" or r[5] != "00"), None)
hp_set = next((r[0] for r in rows if r[2] == 288 and r[3] == 288), None)
print(f"white frames: {white}  first death flag: {first_down}  HP set: {hp_set}")
fail = 0
def need(cond, msg):
    global fail
    print(("  ok   " if cond else "  FAIL ") + msg); fail |= (not cond)
need(len(white) > 0, "the instrument saw at least one white frame (RH-15)")
need(first_down is not None and hp_set is not None, "a KO and a match start occurred inside the window")
intro = [w for w in white if hp_set and w < hp_set and by[w][2] == 0 and by[w][6] == 0x63]
start = [w for w in white if hp_set and 150 <= w - hp_set <= 220]   # measured +183 on vanilla 104 AND merged play-01
down  = [w for w in white if first_down and 50 <= w - first_down <= 120]
need(len(intro) == 2 and intro[1] - intro[0] == 2, f"match-intro pair, 2 frames apart: {intro}")
need(len(start) == 1, f"exactly one white frame at match start: {start}")
need(len(down) == 1, f"exactly one white frame 50..120 after the first down: {down} (down at {first_down})")
stray = sorted(set(white) - set(intro) - set(start) - set(down))
need(not stray, f"no unattributed white frames (negative control): {stray}")
print("PASS test_down_flash_vanilla" if not fail else "FAIL test_down_flash_vanilla"); sys.exit(fail)
PY
