#!/bin/sh
# naming_shift_sheet.sh — ONE NAMING EVENT, BEFORE AND AFTER A SCHEDULE SHIFT, AS
# PICTURES. Promoted from a 14z-172 scratch probe (GitHub #168).
#
# WHY. A chain id says WHICH chain an event entered; it does not show what the two
# fighters did, and a rig change that alters an event's outcome has to be looked at
# before it is described ([VSP-173], and the maintainer's standing preference for a
# capture over a number). BEFORE is the rig regenerated from a copy of
# tools/name_moves.py with its round-start floor removed (ROUND_START = 0, i.e. the
# pre-#168 schedule); AFTER is the committed schedule. Both legs are native vsav2 and
# both are sampled at the SAME OFFSETS from their own event frame, so the two rows
# show the same moment of the same recipe.
#
# MEASURED 14z-172: on pyron_3 ev0 (Corona Whip [6MP]) BEFORE shows Pyron punching
# and Demitri standing untouched, AFTER shows the throw connecting; on pyron_5 ev0
# (Planet Burning [MP] step back) BEFORE shows no contact and no FIRST ATTACK banner,
# AFTER shows Demitri caught inside the burning planet. Those two events are the ones
# GitHub #168's shift corrects, and the pictures are what identified them.
#
# It is a PROBE, not a gate. Edit the two `spec` lines for other events.
#
# Usage: ROMDIR=... [MAME_BIN=~/.cache/vampire-saved/mame/cps2] tools/naming_shift_sheet.sh <outdir>
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="$(cd "${ROMDIR:-../ROMS}" && pwd)"; export ROMDIR
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
O="$1"; mkdir -p "$O"; O="$(cd "$O" && pwd)"
sed 's/^ROUND_START = 2545/ROUND_START = 0/' tools/name_moves.py > "$O/nm_before.py"
# offsets past the event frame: the motion, the button, the move's first active frames
OFF="0 20 40 55 70 90"
for spec in "pyron 3 0 corona_6MP" "pyron 5 0 planetburning_MP"; do
    set -- $spec
    T="$1"; P="$2"; EV="$3"; NAME="$4"
    for leg in before after; do
        d="$O/${NAME}_$leg"; rm -rf "$d"; mkdir -p "$d/sb"
        gen="tools/name_moves.py"; [ "$leg" = before ] && gen="$O/nm_before.py"
        python3 "$gen" gen "$T" "$P" "$d/r.rpl" "$d/r.json" > /dev/null
        f="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['events'][$EV]['frame'])" "$d/r.json")"
        pk="$(python3 -c "import json,sys;print(';'.join(json.load(open(sys.argv[1]))['pokes']))" "$d/r.json")"
        sn="$(python3 -c "print(','.join(str($f+int(x)) for x in '$OFF'.split()))")"
        last="$(python3 -c "print($f+90+10)")"
        ( set +e; cd "$d" && MAME_SANDBOX="$d/sb" REPLAY="$d/r.rpl" POKES="$pk" SNAP_FRAMES="$sn" \
            FRAMES="$last" TRACE_OUT="$d/idx.txt" \
            "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" > "$d/mame.log" 2>&1 )
        echo "$NAME $leg: event frame $f, snaps $(ls "$d"/sb/snap/vsav2/*.png 2>/dev/null | wc -l | tr -d ' ')"
    done
done
