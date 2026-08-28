#!/bin/sh
# audit_df_framework.sh — THE DF FRAMEWORK TABLE, FROZEN (14z-104).
#
# 14z-101 measured, and the maintainer then RULED (2026-08-21, DECIDED:
# "we absolutely, categorically, keep vsavj DF durations"), the tenants'
# Dark Force framework: vsavj semantics — cost 1 STOCK, PER-CHARACTER
# duration, an activation seq — with the tenants reading 360/377/360 and
# Phobos legitimately entering the 0x18 clone-train class (legacy ids
# 0x0C/0x0F share it at the same 377). STATE 14z-101 closed with
# "instrument promotion (an audit freezing the framework table) can now
# proceed on the confirmed reading" — this is that audit. It exists so a
# future porting change that silently moves a tenant's DF cost, duration
# or class fails LOUDLY against the ruled values.
#
# WHAT IT ASSERTS, per leg (rig df/97: activate with poked stocks, then
# fully idle so the mode's own timer expires undisturbed):
#   1. DF ACTIVATES: $FF802E rises to 1 (never inferred from the fighter
#      block — the 14z-69 rule), and falls again in-window.
#   2. COST: exactly ONE stock across the activation ($FF8509 3 -> 2).
#   3. DURATION: the df==1 SPAN (onset..last; Phobos's documented
#      activation-window flicker zeros are tolerated <=24f after onset),
#      equal to the FROZEN per-character value. Per-frame sampled, exact.
#   4. The LEGACY CONTROL (Demitri 0x01) must read the vanilla 360/1 —
#      if the control drifts, the instrument (or the engine) moved and
#      no tenant number is trustworthy this run.
#
# FROZEN (14z-101 measurement, maintainer-ruled 2026-08-21):
#   0x01 Demitri  dur 360  (the legacy control)
#   0x13 Donovan  dur 360
#   0x10 Phobos   dur 377  (the 0x16->0x18 clone-train class)
#   0x11 Pyron    dur 360
# All at cost 1 stock. Any doubt about the exact per-tenant lengths is
# the MAINTAINER'S to research from period sources (the ruling); this
# audit freezes what ships, it does not retune.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged12] [JOBS=4]
#        tests/audit_df_framework.sh          (~4 legs x ~2 min)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged18}"  # re-pointed 14z-115 (select-wheel freeze) <- 14z-113 (merged-m10: one-zip repackaging of merged-m9, same program)
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/df/97_df_mech.rpl"
FIELDS="ff802e:b:df,ff8509:b:stocks,ff8406:b:p1seq"

for leg in ctl:01 don:13 hui:10 pyr:11; do
    n="${leg%%:*}"; id="${leg#*:}"
    d="$W/$n"; mkdir -p "$d/sb"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" REPLAY="$RPL" POKES="$PK" FIELDS="$FIELDS" \
      FIELD_OUT="$d/field.txt" FIELD_FROM=3100 FIELD_TO=7000 FRAMES=7050 \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/out" 2>&1 ) &
done
wait

python3 - "$W" <<'PY' || { echo "FAIL: DF framework audit"; exit 1; }
import sys
W = sys.argv[1]
# The frozen table (14z-101 measurement, maintainer-ruled 2026-08-21).
FROZEN = {"ctl": 360, "don": 360, "hui": 377, "pyr": 360}
errs = []
for leg, want in FROZEN.items():
    rows = {}
    for line in open(f"{W}/{leg}/field.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        d = dict(kv.split("=") for kv in f[2:])
        rows[int(f[1])] = {k: int(v) for k, v in d.items()}
    if not rows:
        errs.append(f"{leg}: no field samples — dead leg"); continue
    dffr = [fr for fr in sorted(rows) if rows[fr]["df"] == 1]
    if not dffr:
        errs.append(f"{leg}: DF never activated ($FF802E never 1) — "
                    "downgrade trap or dead rig; nothing measured"); continue
    if rows[max(rows)]["df"] == 1:
        errs.append(f"{leg}: DF still active at the last sample — window "
                    "too short, duration unreadable (do not truncate)"); continue
    onset, last = dffr[0], dffr[-1]
    # DURATION IS THE SPAN, not the df==1 frame count: Phobos' documented
    # activation-window flag FLICKER (14z-101 — his unique tell, ~f3289-3307
    # relative here to onset) puts zeros INSIDE the mode. Zeros inside the
    # span are tolerated only in the first 24 frames after onset; a zero
    # later than that is a mode drop and fails as a gap.
    dur = last - onset + 1
    gaps = [fr for fr in range(onset, last + 1)
            if fr in rows and rows[fr]["df"] == 0]
    late_gaps = [fr for fr in gaps if fr > onset + 24]
    if late_gaps:
        errs.append(f"{leg}: df flag dropped mid-mode at {late_gaps[:4]} — "
                    "not the documented activation-window flicker")
    # COST: the decrement lands slightly BEFORE the flag rises, so compare
    # the pre-activation plateau (max after the pokes settle) against the
    # in-mode value.
    pre = [rows[fr]["stocks"] for fr in sorted(rows) if 3130 <= fr < onset]
    stocks_before = max(pre) if pre else None
    stocks_after = rows[onset + 2]["stocks"] if onset + 2 in rows else None
    cost = (stocks_before - stocks_after) if None not in (stocks_before, stocks_after) else None
    if cost != 1:
        errs.append(f"{leg}: DF cost {cost} stocks (before {stocks_before} "
                    f"after {stocks_after}) — the vsavj framework is 1")
    if dur != want:
        errs.append(f"{leg}: DF duration {dur} frames, frozen value {want} "
                    "— the ruled per-character duration moved; that is a "
                    "porting change or an engine change, name it")
    else:
        print(f"  ok: {leg} — onset f{onset}, duration {dur}, cost 1 stock")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: the DF framework table holds (cost 1 stock; durations"
echo "      360/360/377/360 ctl/don/hui/pyr — maintainer-ruled 2026-08-21)"
