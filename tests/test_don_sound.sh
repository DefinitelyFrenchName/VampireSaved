#!/bin/sh
# test_don_sound.sh — Donovan sound gate (session 14z-52).
#
# THE TRIPWIRE THAT MATTERS: vsavj's sound-id range 0x700-0x7FF holds
# MUSIC TRACKS, while vs2 uses that same range for Donovan's voice bank
# (measured both sets, docs/project/m5/, engine_internals "Sound subsystem").
# Mapping any of those ids through to the vsavj sound driver is what made
# 214P/214K play MUSIC in the round-2 playtest. This gate replays
# Donovan's moveset and asserts that NO id in the music range is ever
# enqueued into the 68k sound ring (RAM:$FF0E0E, 16-byte entries; the id
# low word lands at entry+2 because a 68k move.l splits into two word
# writes — see GOTCHAS).
#
# It also locks the id INVENTORY per replay: any newly-appearing id is a
# loud failure, not a silent behavior change (sound is invisible to every
# RAM/pixel gate we have, so this is the only detector).
#
# Usage: ROMDIR=... [SET=vsavjw] tests/test_don_sound.sh [rompath_dir]
#   SET selects the driver, so this gate can be pointed at a CPS-2 WIDE
#   build (packed as vsavjw) as well as a stock one. The tripwire below is
#   the SAME either way — and it matters MORE on the WIDE track, which is
#   where the per-node sfx helper is actually live.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

for rp in 12_donovan_vs_cpu 19_don_dp_spam 25_don_darkforce 56_don_es_ls; do
    REPLAY="$REPO/tests/replays/$rp.rpl" FRAMES=3400 \
        TRACE_OUT="$WORK/$rp.txt" MAME_SANDBOX="$WORK/$rp" \
        CHECKSUM_OUT="$WORK/$rp/c.log" MAME_ROMPATH="$RPDIR;$ROMDIR" \
        tools/run_mame.sh "${SET:-vsavj}" \
        -autoboot_script "$REPO/tests/lua/ring_tap.lua" > /dev/null 2>&1
done

python3 - "$WORK" <<'PYEOF'
import sys, os, re
work = sys.argv[1]
# frozen id inventories, measured on ae701ffb (14z-52, phase-1 restore).
# 0x0000/0xFFFF are ring housekeeping writes, not sounds.
EXPECT = {
 '12_donovan_vs_cpu': {0x2,0x5,0xa,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xf3,0xfe,0x106,
                       0x10c,0x170,0x171,0x2e2,0x403,0x40a,0x410,0x429,0x4c1,0x4c7,
                       0x4c9,0xff00,0xff05,0xff07},
 '19_don_dp_spam':    {0x2,0x5,0xa,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xf3,0xfe,0x104,
                       0x105,0x170,0x171,0x470,0x471,0x498,0x49a,0x621,0x62b,
                       0xff00,0xff05,0xff07},
 '25_don_darkforce':  {0x2,0x5,0xa,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xfe,0x170,0x171,
                       0x470,0x471,0x498,0x49a,0x62b,0xff00,0xff05,0xff07},
 '56_don_es_ls':      {0x2,0x5,0xa,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xf3,0xfe,0x117,
                       0x170,0x171,0x470,0x471,0x498,0x49a,0x62b,0xff00,0xff05,
                       0xff07},
}
# ── WIDE-track overlay (14z-59i) ─────────────────────────────────────────
# On the CPS-2 WIDE build the per-node sfx helper is LIVE and the ported
# record array is present, so Donovan's shared sfx finally reach the ring.
# These ids are ADDITIONS to the stock inventory, and every one of them is
# from the keep_ids allowlist (samples verified identical on vsavj). The
# music range stays empty — that assert above is unchanged and is the
# property that actually matters.
WIDE_EXTRA = {
    "12_donovan_vs_cpu": {0x110, 0x111, 0x112},
    "19_don_dp_spam":    {0x110, 0x111},
    "25_don_darkforce":  {0x110},
    "56_don_es_ls":      {0x119},
}
if os.environ.get("SET", "vsavj").endswith("w"):
    for _rp, _extra in WIDE_EXTRA.items():
        EXPECT[_rp] = EXPECT[_rp] | _extra

fail = 0
for rp in sorted(EXPECT):
    p = os.path.join(work, f"{rp}.txt")
    assert os.path.exists(p), f"{rp}: no trace captured"
    ids = set()
    for line in open(p):
        m = re.match(r"f(\d+) id (\w+)", line)
        if m:
            v = int(m.group(2), 16)
            if v not in (0x0000, 0xFFFF):
                ids.add(v)
    music = sorted(hex(i) for i in ids if 0x700 <= i <= 0x7FF)
    assert not music, (
        f"{rp}: MUSIC-RANGE ids reached the sound ring: {music} — a ported "
        f"sound path is handing vsavj a vs2 voice id. This is the round-2 "
        f"music bug; do not tolerate it, re-check the sound_table allowlist.")
    new = sorted(hex(i) for i in ids - EXPECT[rp])
    gone = sorted(hex(i) for i in EXPECT[rp] - ids)
    if new or gone:
        print(f"  FAIL {rp}: id inventory changed (new={new} missing={gone})")
        fail += 1
    else:
        print(f"  ok: {rp} — {len(ids)} ids, none in the music range")
sys.exit(1 if fail else 0)
PYEOF
echo "PASS: Donovan sound gate (no music-range ids; inventories frozen)"
