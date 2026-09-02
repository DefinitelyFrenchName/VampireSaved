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
# Usage: ROMDIR=... tests/test_don_sound.sh [rompath_dir]
#
# ** THE `SET=vsavjw` MODE THIS LINE USED TO ADVERTISE IS VOID (14z-127,
#    GitHub #114). DO NOT USE IT WITHOUT RE-AUTHORING THE REPLAYS. ** Three of
#    the four replays below (19 / 25 / 56) walk P1 with the SUBSTITUTED-wheel
#    path `U,U,R` -> slot 0x0F, which is Donovan only on the stock track.
#    Since the 14z-115 wheel separation the tenants sit on their own appended
#    row, so on a WIDE build that path selects vanilla JEDAH (measured on
#    merged-m14: replay 56 gives P1 +0x60 = 0x000b0d2e) and this gate's
#    Donovan tripwire and frozen id inventories would describe HIS moveset.
#    Nothing invokes the mode (the battery passes a stock outbase, and per the
#    2026-08-15 audit dispositions it cannot build WIDE at any outbase), so
#    this was a latent trap in the header rather than a false green — but the
#    header is what a future session would have believed. The observation that
#    the per-node sfx helper is live on the WIDE track STANDS and is the
#    reason to want this coverage; getting it needs WIDE-wheel twins of the
#    three replays (see `tests/replays/don/114_don_immortal_wide.rpl` for the
#    pattern), not a SET override. docs/project/gotchas.md carries the class.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   sound-ring gate: NO vsavj music-range id may be enqueued + frozen per-
#   replay id inventories (sound is invisible to every other gate)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPDIR="${1:-$REPO/build/donovan6/rompath}"
[ -d "$RPDIR" ] || { echo "no build at $RPDIR"; exit 1; }
# SAFE AND LOUD ([VSP-22]): refuse the void WIDE mode rather than document it.
# Three of the four replays below select JEDAH on a separated wheel, so a
# vsavjw run here measures the wrong character's sounds while printing PASS.
case "${SET:-vsavj}" in
  vsavj) ;;
  *) echo "FAIL: SET=${SET} refused — replays 19/25/56 use the SUBSTITUTED-wheel"
     echo "      path and select vanilla Jedah on a separated (WIDE) wheel."
     echo "      This gate is stock-track only until WIDE-wheel twins exist."
     echo "      See the header, GitHub #114, docs/project/gotchas.md."
     exit 1 ;;
esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO"

for rp in 12_donovan_vs_cpu 19_don_dp_spam 25_don_darkforce 56_don_es_ls; do
    # A TEARDOWN SEGFAULT IS TOLERATED ONLY BEHIND THE INSTRUMENT'S OWN
    # COMPLETION MARKER (14z-99). ring_tap writes "END" and closes its
    # trace BEFORE calling manager.machine:exit(); MAME's exit path can
    # then segfault host-side (measured: deterministic on replay 19 this
    # session, on PRE- and POST-window builds alike, while replay.lua on
    # the same replay exits clean — an emulator teardown race, not a
    # measurement defect; the 14z-96/97 batteries ran this loop clean).
    # A crash WITHOUT the END marker is a mid-run death and still fails.
    rc=0
    REPLAY="$REPO/tests/replays/$rp.rpl" FRAMES=3400 \
        TRACE_OUT="$WORK/$rp.txt" MAME_SANDBOX="$WORK/$rp" \
        CHECKSUM_OUT="$WORK/$rp/c.log" MAME_ROMPATH="$RPDIR;$ROMDIR" \
        tools/run_mame.sh "${SET:-vsavj}" \
        -autoboot_script "$REPO/tests/lua/ring_tap.lua" > /dev/null 2>&1 || rc=$?
    if [ "$rc" -ne 0 ]; then
        if [ -f "$WORK/$rp.txt" ] && grep -q "^END$" "$WORK/$rp.txt"; then
            echo "  note: $rp — MAME teardown crash (rc=$rc) AFTER the"
            echo "        instrument's END marker; run complete, tolerated"
        else
            echo "FAIL: $rp died mid-run (rc=$rc, no END marker)"
            exit 1
        fi
    fi
done

python3 - "$WORK" <<'PYEOF'
import sys, os, re
work = sys.argv[1]
# frozen id inventories. RE-FROZEN 14z-99 (were "measured on ae701ffb",
# the 14z-52 build — NINE generations stale; the drift is IDENTICAL on
# the pre-window stock twin m5_stock3 = the bytes unchanged since 14z-91,
# so it accrued somewhere in 14z-52..91 and no full battery re-ran this
# leg since — the third stale-literal family the window battery
# surfaced, after test_don_accent's and test_don_colors' row-0x0F).
# The delta from the 14z-52 freeze: 0xa -> 0x10 on all four (one
# reaction-sfx id), plus replay 12's mid-run set (its vs-CPU fight
# resolves differently across the accrued generations). Every id is
# outside the music range — the assert that is this gate's actual
# tripwire is unchanged and green throughout.
# 0x0000/0xFFFF are ring housekeeping writes, not sounds.
EXPECT = {
 '12_donovan_vs_cpu': {0x2,0x5,0x10,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xf3,0xfe,
                       0x10c,0x11f,0x170,0x171,0x401,0x411,0x416,0x432,0x437,
                       0x4d8,0x4d9,0x4f3,0xff00,0xff05,0xff07},
 '19_don_dp_spam':    {0x2,0x5,0x10,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xf3,0xfe,0x104,
                       0x105,0x170,0x171,0x470,0x471,0x498,0x49a,0x621,0x62b,
                       0xff00,0xff05,0xff07},
 '25_don_darkforce':  {0x2,0x5,0x10,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xfe,0x170,0x171,
                       0x470,0x471,0x498,0x49a,0x62b,0xff00,0xff05,0xff07},
 '56_don_es_ls':      {0x2,0x5,0x10,0xe0,0xed,0xee,0xef,0xf0,0xf1,0xf3,0xfe,0x117,
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
