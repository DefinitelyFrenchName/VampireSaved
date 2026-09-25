#!/bin/sh
# trap_air_probe.sh — THE PLASMA TRAP DOME'S ATTACK BOX AGAINST A JUMPING VICTIM'S HURTBOXES, frame
# by frame (14z-182, GitHub #175). An INSTRUMENT, not a gate.
#
# WHAT: for each frame of a window, the dome's resolved attack box and each of the victim's three
#   vuln (hurt) boxes, in world coordinates, and the overlap margins between them — so "did the
#   boxes touch on a frame the victim was airborne?" is read from the data the engine resolves,
#   not from the picture.
# HOW: the deep-overlap trap rig of tests/audit_trap_airborne.sh (tests/replays/hui/92_hui_trap_shock.rpl,
#   Phobos P1 vs Victor P2, the same forced-pick pokes, level pin 6 and RNG pin 0000) with P2
#   jumping (DIR) at JUMP, one MAME leg under tests/lua/field_trace.lua sampling the victim's position, facing,
#   class, HP and hitbox fields (+0x80/+0x84/+0x88 vuln tables, +0x94 family ids) and every slot
#   of the $FF9400 projectile pool (+0x02 type, +0x0B facing, +0x10/+0x14 position, +0x1C node,
#   +0x8C attack-record table); tools/trap_air_boxes.py resolves the boxes through the leg's own
#   decrypted DATA image (the encoding of docs/game/engine_internals.md "Hitboxes and attack
#   records": box (x, y, hw, hh) signed words, centre at (X + (flip ? -x : x), Y + y), y up,
#   ground y = 40; a node's hbA word (+0xA) >> 8 is the attack-record index, 0x20 bytes a record).
#
# Usage: ROMDIR=... [LEG=native|merged] [JUMP=3490] [DIR=U|UL|UR (P2's jump direction, replay grammar)] [XPIN=<x>@<from>-<to>] [P1XPIN=<x>@<from>-<to>] [ORDER=1] [SNAP=f1,f2] [PICK=forced|real] [P2CELL=03] [ATK='<from>-<to> p2=<btn>'] [FROM=3505] [TO=3535] [MERGED=build/m3b_merged27]
#          tools/trap_air_probe.sh [out_dir]
#   native: vsav2 from $ROMDIR, boxes read from build/out/vsav2_data.bin;
#   merged: the merged build, boxes read from <MERGED>/verify_data.bin.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"; [ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
LEG="${LEG:-native}"; JUMP="${JUMP:-3490}"; DIR="${DIR:-U}"; XPIN="${XPIN:-}"; PICK="${PICK:-forced}"; P2CELL="${P2CELL:-03}"; ATK="${ATK:-}"; FROM="${FROM:-3505}"; TO="${TO:-3535}"
MERGED="${MERGED:-build/m3b_merged27}"; case "$MERGED" in /*) ;; *) MERGED="$REPO/$MERGED" ;; esac
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
OUT="${1:-$REPO/build/trap_air_probe/$LEG-$DIR-j$JUMP${XPIN:+-x$XPIN}}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
case "$LEG" in
    native) SET=vsav2; RP="$ROMDIR"; DATA="$REPO/build/out/vsav2_data.bin"; LAYOUT=vsav2 ;;
    merged) SET=vsavjw; RP="$MERGED/rompath;$ROMDIR"; DATA="$MERGED/verify_data.bin"; LAYOUT=vsavj ;;
    *) echo "FAIL: LEG must be native or merged"; exit 1 ;;
esac
[ -x "$MAME_BIN" ] || { echo "FAIL: no MAME at $MAME_BIN"; exit 1; }
[ -f "$DATA" ] || { echo "FAIL: no data image $DATA"; exit 1; }
# the rig's pokes, as tests/audit_trap_airborne.sh sets them; PICK=real drops the id pokes and picks
# both fighters by their REAL cursor routes on this leg's own wheel (tools/select_paths.py), P1 Phobos
# (0x10) and P2 the cell P2CELL — a forced-pick leg carries the cursor character's confirm latch (#151)
if [ "$PICK" = real ]; then IDPK=""; else IDPK="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10;1400:ff8b82:$P2CELL;1450:ff8b82:$P2CELL;1500:ff8b82:$P2CELL;"; fi
PK="$IDPK$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$TO+20)))");$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$TO+20)))")"
# XPIN="<x>@<from>-<to>": pin P2's x word ($FF8810) over a frame range BEFORE the jump (never inside the
# observed window: a rig write on a compared field is the "shared pin" gotcha), to set where he jumps from
if [ -n "$XPIN" ]; then PK="$PK;$(python3 -c "
x, r = '$XPIN'.split('@'); a, b = map(int, r.split('-'))
print(';'.join(f'{f}:ff8810:{int(x):04x}' for f in range(a, b + 1)))")"; fi
# P1XPIN: the same for P1's x ($FF8410) — to park Phobos out of the victim's attack reach once the
# trap is placed (the dome is its own object and stays where it rolled)
if [ -n "${P1XPIN:-}" ]; then PK="$PK;$(python3 -c "
x, r = '$P1XPIN'.split('@'); a, b = map(int, r.split('-'))
print(';'.join(f'{f}:ff8410:{int(x):04x}' for f in range(a, b + 1)))")"; fi
{ sed '/^3900 wait/d' tests/replays/hui/92_hui_trap_shock.rpl | grep -v '^#'; echo "$JUMP-$((JUMP + 2)) p2=$DIR"; [ -n "$ATK" ] && echo "$ATK"; echo "3900 wait"; } > "$OUT/air.rpl"
if [ "$PICK" = real ]; then
    WSET=$([ "$LEG" = native ] && echo vsav2 || echo vsavj)
    python3 tools/select_wheel.py "$DATA" --set "$WSET" --json "$OUT/wheel.json" > "$OUT/wheel.log" 2>&1 || { echo "FAIL: wheel"; exit 1; }
    R1="$(python3 tools/select_paths.py "$OUT/wheel.json" --cell 10 --player 1 | sed 's/^.*: //')"
    R2="$(python3 tools/select_paths.py "$OUT/wheel.json" --cell "$P2CELL" --player 2 | sed 's/^.*: //')"
    python3 tools/trap_air_prologue.py "$OUT/air.rpl" "$R1" "$R2" || { echo "FAIL: prologue"; exit 1; }
    echo "real picks on $LEG: P1 Phobos '$R1', P2 cell $P2CELL '$R2'"
fi
F="ff8460:l:p1base,ff8860:l:p2base,ff881c:l:vnode,ff845c:b:p1frz,ff8450:w:p1hp,ff885c:b:vfrz,ff8410:w:p1x,ff8810:w:vx,ff8814:w:vy,ff880b:b:vflip,ff8854:b:vcls,ff8850:w:vhp,ff8806:b:vseq,ff8880:l:vt0,ff8884:l:vt1,ff8888:l:vt2,ff8894:l:vfam"
F="$F$(python3 -c "
b=0xff9400
print(''.join(f',{b+k*0x100+0x02:x}:b:s{k}type,{b+k*0x100+0x0b:x}:b:s{k}flip,{b+k*0x100+0x10:x}:w:s{k}x,{b+k*0x100+0x14:x}:w:s{k}y,{b+k*0x100+0x1c:x}:l:s{k}node,{b+k*0x100+0x8c:x}:l:s{k}rec' for k in range(32)))")"
# SNAP="f1,f2,...": ALSO photograph those frames (tests/lua/snapshot_frames.lua, the same replay and
# pokes) into <out>/snap/NNNN.png, in SNAP order — for tools/trap_air_sheet.sh
if [ -n "${SNAP:-}" ]; then
    mkdir -p "$OUT/snapsb"
    ( cd "$OUT" && MAME_SANDBOX="$OUT/snapsb" MAME_ROMPATH="$RP" REPLAY="$OUT/air.rpl" POKES="$PK" SNAP_FRAMES="$SNAP" \
        TRACE_OUT="$OUT/snap_index.txt" "$REPO/tools/run_mame.sh" "$SET" -autoboot_script "$REPO/tests/lua/snapshot_frames.lua" > "$OUT/snap.log" 2>&1 ) </dev/null || true
    rm -rf "$OUT/snap"; mv "$OUT/snapsb/snap/$SET" "$OUT/snap" 2>/dev/null; rm -rf "$OUT/snapsb"
    [ -s "$OUT/snap/0000.png" ] || { echo "FAIL: no snapshots ($OUT/snap.log)"; exit 1; }
fi
# ORDER=1: instead of the box trace, a -debug write tap on the victim's y word ($FF8814) and HP word
# ($FF8850), armed at FROM (no debugger stop before it, so the timeline up to FROM is the plain
# run's — [CPE-5]); the log lists the writes IN EXECUTION ORDER with the writing PC, which says
# whether the hit's HP write comes before or after the landing's y write within the same pass.
if [ "${ORDER:-0}" = 1 ]; then
    ( cd "$OUT" && MAME_SANDBOX="$OUT/sb" MAME_ROMPATH="$RP" REPLAY="$OUT/air.rpl" POKES="$PK" \
        WATCH="${ORDER_WATCH:-ff8814,2,w;ff8850,2,w}" WATCH_FROM="$FROM" TRACE_OUT="$OUT/order.txt" FRAMES="$TO" \
        "$REPO/tools/run_mame.sh" "$SET" -debug -debugger none -autoboot_script "$REPO/tests/lua/trace_writes.lua" > "$OUT/mame.log" 2>&1 ) </dev/null || true
    rm -rf "$OUT/sb"
    [ -s "$OUT/order.txt" ] || { echo "FAIL: no tap log ($OUT/mame.log)"; exit 1; }
    cat "$OUT/order.txt"; exit 0
fi
( cd "$OUT" && MAME_SANDBOX="$OUT/sb" MAME_ROMPATH="$RP" REPLAY="$OUT/air.rpl" POKES="$PK" FIELDS="$F" \
    FIELD_OUT="$OUT/trace.ft" FIELD_FROM="$FROM" FIELD_TO="$TO" FRAMES="$TO" \
    "$REPO/tools/run_mame.sh" "$SET" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$OUT/mame.log" 2>&1 ) </dev/null || true
rm -rf "$OUT/sb"
[ -s "$OUT/trace.ft" ] || { echo "FAIL: no samples ($OUT/mame.log)"; exit 1; }
python3 "$REPO/tools/trap_air_boxes.py" "$OUT/trace.ft" "$DATA" --layout "$LAYOUT" | tee "$OUT/boxes.txt"
