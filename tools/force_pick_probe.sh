#!/bin/sh
# force_pick_probe.sh — forced-id boot probe (14z-65, the variant-id ladder
# instrument). Boots the vanilla select flow, confirms at the DEFAULT cell,
# then POKES the P1 char id ($FF8782 — the commit field, atlas
# select_screen.md:104) to the given id across the commit->load window, and
# reports whether a match forms with that character.
#
# Usage: ROMDIR=... tools/force_pick_probe.sh <rompath> <id-hex> <outdir>
#   e.g. tools/force_pick_probe.sh build/hui4/rompath 10 /tmp/probe
# SET=vsavjw (default vsavj) selects the romset; with vsavjw also set
# MAME_BIN=~/.cache/vampire-saved/mame/cps2 (the WIDE-patched binary).
#
# Prints three verdicts:
#   id-hold   the poked id is still in $FF8782 mid-VS (frame 2600)
#   load      the hitbox-base pair at $FF8460 at frame 3600 (a loaded char
#             shows its table row's pointer; ZEROS = the load path WEDGED —
#             the measured 14z-65 state for id 0x10 on a stage-4 ladder
#             build: poke holds, struct never forms, guard clean)
#   guard     crash-guard cleanliness
set -eu

RP="${1:?usage: force_pick_probe.sh <rompath> <id-hex> <outdir>}"
ID="${2:?id hex byte, e.g. 10}"
OUT="${3:?outdir}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUT"

cat > "$OUT/pick.rpl" <<'RPL'
300-305 sys=C1
800-803 sys=S1
1700-1702 p1=1
RPL

if POKES="1704:ff8782:$ID;1760:ff8782:$ID;1900:ff8782:$ID;2100:ff8782:$ID;2400:ff8782:$ID" \
   DUMPS="2600:ff8780-ff8788;3600:ff8460-ff8468" \
   SNAP_FRAMES="2900,3400" \
   MAME_ROMPATH="$(cd "$RP" && pwd);$ROMDIR" \
   "$REPO/tools/run_replay_guarded.sh" "${SET:-vsavj}" "$OUT/pick.rpl" \
       "$OUT/out.log" "$OUT/box" > "$OUT/run.out" 2>&1; then
    GUARD="clean"
else
    GUARD="TRIPPED (see $OUT/run.out)"
fi

MID="$(xxd -p "$OUT/dump_2600_ff8780.bin" 2>/dev/null | cut -c5-6 || echo '??')"
BASE="$(xxd -p "$OUT/dump_3600_ff8460.bin" 2>/dev/null | cut -c1-8 || echo '????????')"
echo "id-hold @2600: \$FF8782 = 0x$MID (wanted 0x$ID)"
if [ "$BASE" = "00000000" ]; then
    echo "load    @3600: hitbox base ZEROS — WEDGED or WATCHDOG-REBOOTED"
    echo "               (zeros can be fresh-boot state — CHECK THE"
    echo "               SNAPSHOTS in $OUT/box/snap/ before concluding;"
    echo "               a QSound splash = the machine reset. GOTCHAS 14z-65)"
else
    echo "load    @3600: hitbox base 0x$BASE — char LOADED"
fi
echo "guard        : $GUARD"
