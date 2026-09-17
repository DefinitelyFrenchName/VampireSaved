#!/bin/sh
# tap_latch_reads.sh — WHICH CODE READS THE SELECT-CONFIRM LATCH BYTES on one
# leg (GitHub #151 step 3, 14z-161). Plays a replay with its pokes under the
# non-debug PC-attributed read tap (tests/lua/read_tap.lua) over both fighter
# blocks' latch windows and reduces the log to one line per (PC, latched byte):
#
#   <set>  <side>  <byte>  <offset>  <what>  <PC>  <reads>  <first-frame>  <last-frame>  <values>
#
# `values` is every distinct byte the reader SAW (the poked native Phobos reads
# flavor 01 where a real pick reads 00 — the value is the evidence, not the read).
#
# for the six bytes a poked leg can carry wrong — P1 +0x3BD/+0x3C2/+0x3E0
# (RAM:$FF87BD/$FF87C2/$FF87E0) and P2's (RAM:$FF8BBD/$FF8BC2/$FF8BE0)
# (tests/audit_forced_pick_fidelity.sh). The mask column names the BYTE
# (ff00 = the even address, 00ff = its odd neighbour — the 14z-160 trap), so a
# read of +0x3C3 is never counted as +0x3C2.
#
# LIVENESS: the log must carry the boot-POST W lines and END; a run with no R
# line at all prints VOID. A leg whose P1 is Phobos on vsav2 reads +0x3C2 every
# match frame from PRG:0x026322 — the positive control any batch should carry.
#
# Usage: ROMDIR=... [MAME_BIN=...] tools/tap_latch_reads.sh <set> <replay.rpl> <pokes|-> <frames> <out.tsv> [rompath]
#   set: vsav2 (native) or vsavjw (a WIDE build — pass its rompath dir as the 6th argument)
set -eu
[ $# -ge 5 ] || { echo "usage: $0 <set> <replay> <pokes|-> <frames> <out.tsv> [rompath]"; exit 2; }
SET="$1"; RPL="$2"; PK="$3"; FR="$4"; OUT="$5"; RP="${6:-}"
# canonicalise every path first ([VSP-108]): the legs run from a scratch dir
[ -f "$RPL" ] || { echo "FAIL: no replay at $RPL"; exit 1; }
RPL="$(cd "$(dirname "$RPL")" && pwd)/$(basename "$RPL")"
OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "FAIL: no MAME at $MAME_BIN"; exit 1; }
[ "$PK" = "-" ] && PK=""
case "$SET" in
    vsav2) MRP="$ROMDIR" ;;
    vsavjw) [ -n "$RP" ] && [ -f "$RP/vsavjw.zip" ] || { echo "FAIL: vsavjw needs a rompath holding vsavjw.zip"; exit 1; }
            MRP="$(cd "$RP" && pwd);$ROMDIR" ;;
    *) echo "FAIL: set must be vsav2 or vsavjw"; exit 2 ;;
esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
: > "$OUT"
for blk in ff87bc ff8bbc; do
    ( cd "$W" && REPLAY="$RPL" POKES="$PK" RTAP="$blk,40" WINDOW="0,$FR" FRAMES="$FR" \
      TRACE_OUT="$W/tap_$blk.txt" MAME_SANDBOX="$W/sb_$blk" MAME_ROMPATH="$MRP" \
      "$REPO/tools/run_mame.sh" "$SET" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/mame_$blk.log" 2>&1 ) </dev/null || true
    [ -s "$W/tap_$blk.txt" ] || { echo "VOID: no tap log for $blk — MAME said:"; tail -5 "$W/mame_$blk.log"; exit 1; }
    grep -q '^W ' "$W/tap_$blk.txt" || { echo "VOID: no W line in the $blk tap — dead instrument"; exit 1; }
    grep -q '^END' "$W/tap_$blk.txt" || { echo "VOID: no END line in the $blk tap"; exit 1; }
done
python3 - "$W" "$SET" "$OUT" <<'EOF'
import sys, collections
W, SET, OUT = sys.argv[1:4]
LATCH = {0x3BD: "id-copy", 0x3C2: "flavor", 0x3E0: "id-copy-2"}
rows = collections.OrderedDict()
for blk, base, side in (("ff87bc", 0xFF8400, "P1"), ("ff8bbc", 0xFF8800, "P2")):
    for line in open(f"{W}/tap_{blk}.txt"):
        p = line.split()
        if not p or p[0] != "R": continue
        frame, pc, addr, data, mask = int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16), int(p[9], 16)
        # the mask names the byte(s): ff00 = even address, 00ff = odd, ffff = both;
        # the data word carries the even byte high, the odd byte low
        bytes_ = []
        if mask & 0xFF00: bytes_.append((addr, (data >> 8) & 0xFF))
        if mask & 0x00FF: bytes_.append((addr + 1, data & 0xFF))
        for b, v in bytes_:
            off = b - base
            if off in LATCH:
                k = (side, b, off, pc)
                r = rows.setdefault(k, [0, frame, frame, set()])
                r[0] += 1; r[2] = frame; r[3].add(v)
with open(OUT, "w") as f:
    f.write("set\tside\tbyte\toffset\twhat\tpc\treads\tfirst\tlast\tvalues\n")
    for (side, b, off, pc), (n, f0, f1, vals) in sorted(rows.items(), key=lambda kv: (kv[0][0], kv[0][2], kv[0][3])):
        f.write(f"{SET}\t{side}\t{b:06x}\t+0x{off:03X}\t{LATCH[off]}\t{pc:06x}\t{n}\t{f0}\t{f1}\t{','.join(f'{v:02x}' for v in sorted(vals))}\n")
print(f"{len(rows)} (PC, latched byte) pairs -> {OUT}")
EOF
