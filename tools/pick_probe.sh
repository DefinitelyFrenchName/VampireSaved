#!/bin/sh
# pick_probe.sh — reusable character-pick experiment (vsavj flow).
#
# Usage: ROMDIR=... tools/pick_probe.sh <outdir> [move ...]
#   e.g. tools/pick_probe.sh /tmp/probe R R D
#
# Boots, coins at 300, starts at 800, applies the given cursor moves from
# frame 1000 (40 frames apart), confirms at 1700, then:
#   - snapshot at 1690 (select screen, cursor name visible)
#   - dumps P1 hitbox-base ptr (RAM:$FF8460) at 3600 (in match)
# The pointer identifies the character slot via the table at PRG:0x0BD97A
# (docs/game/atlas/character_tables.md). This is the rerunnable form of the
# slot->character mapping experiments.
set -eu

OUT="${1:?usage: pick_probe.sh <outdir> [moves...]}"
shift
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUT"

RPL="$OUT/pick.rpl"
{
    echo "300-305 sys=C1"
    echo "800-803 sys=S1"
    fr=1000
    for m in "$@"; do
        echo "$fr-$((fr+2)) p1=$m"
        fr=$((fr+40))
    done
    echo "1700-1702 p1=1"
} > "$RPL"

DUMPS="3600:ff8460-ff8468" REPLAY="$RPL" CHECKSUM_OUT="$OUT/checksums.log" \
    MAME_SANDBOX="$OUT/sandbox" SNAP_FRAMES="1690" \
    "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/replay.lua"

echo "select snapshot: $OUT/sandbox/snap/vsavj/0000.png"
python3 - "$OUT/dump_3600_ff8460.bin" "$REPO/build/out/vsavj_data.bin" <<'EOF'
import struct, sys
ptr = struct.unpack(">I", open(sys.argv[1],"rb").read()[:4])[0]
d = open(sys.argv[2],"rb").read()
tbl = [struct.unpack(">I", d[0xBD97A+i*4:0xBD97A+i*4+4])[0] for i in range(32)]
slots = [i for i,v in enumerate(tbl) if v == ptr]
print(f"P1 hitbox base 0x{ptr:06x} -> slot(s) {slots}")
EOF
