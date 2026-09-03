#!/bin/sh
# test_mister_obj_oracle.sh — the FIRST cross-implementation agreement this
# project has on a VIDEO-DETERMINING surface, and it is on the content the
# port exists to add.
#
# WHAT IT COMPARES. The OBJ (sprite) list the 68k builds in ORAM, dumped from
# MAME by address and from the jtcps2w core out of SDRAM bank 0 (D2 maps ORAM
# to byte 0x640000), walked into records by tools/oram_obj_records.py — which
# tests/test_obj_records.sh proves reproduces the live-machine walker byte for
# byte.
#
# WHY NOT VRAM. 14z-108 tried VRAM and RULED IT OUT: MAME and jtcps2
# legitimately differ there (the palette by HALF) and the legacy control
# reproduced the same pattern on stock vsavj, so the surface can never
# separate "our port broke something" from "these are two implementations".
# The OBJ list is different in kind: it is what the CPU BUILDS.
#
# *** THE SPLIT THIS GATE RESTS ON, AND WHY IT IS PRINCIPLED, NOT A DODGE ***
# A 1P replay's CPU opponent is a SOUND-STATE-FED LOTTERY (atlas/ram.md:99,
# the #110 mechanism), and it genuinely differs between the two legs —
# p2_hitbox_base is 0x000ABD74 on MAME and 0x0009769E on the core, which is
# why test_mister_tenant_oracle excludes the P2 fields BY NAME. An OBJ list
# cannot be filtered "by P2" the way a field table can: sprites are not
# labelled with an owner. But CPS-2 WIDE's own content IS labelled — y bit 12,
# the CPS-2 Turbo promote (slice D3), is set on exactly the group-C sprites
# this port adds and on nothing vanilla can emit. So:
#   * the PROMOTED subset is OURS, is lottery-free, and must agree EXACTLY;
#   * the remainder is vanilla content whose composition depends on which
#     opponent was drawn, and is REPORTED, never asserted.
# MEASURED 14z-109 at the frozen tenant anchor (MAME 2886 / sim 3546):
# promoted 31 vs 31, ORDERED AND FIELD-FOR-FIELD IDENTICAL, 19-bit addresses
# 0x4b0c4-0x4ecda on both. The unpromoted remainder was 9 vs 98 — the lottery.
#
# Usage:
#   ROMDIR=... tests/test_mister_obj_oracle.sh                  # runs both legs (~65 min)
#   tests/test_mister_obj_oracle.sh --sim-dir D --mame-log F    # re-analyse finished runs
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier manual/emulator (~65 min; `--sim-dir/--mame-log` and `--select-sim-
#   dir/--select-mame-log` re-analyse finished runs)) THE OBJ-LIST ORACLE
#   (14z-109) — the first cross-implementation agreement on a video-
#   determining surface. VRAM was ruled out (implementations legitimately
#   differ there); the OBJ list is what the 68k BUILDS. Match anchor: the
#   PROMOTED (y-bit-12, group-C) subset — the port's own sprites — is 31
#   entries on BOTH legs, ORDERED AND FIELD-FOR-FIELD IDENTICAL, 19-bit
#   addresses the same set (`0x4b0c4-0x4ecda`); the unpromoted remainder is
#   the CPU-opponent LOTTERY and is reported, never asserted. Select screen
#   (section 3, no opponent so no lottery): promoted subset exact on ALL 81
#   frames, whole list 55/81 with every shortfall in the unpromoted part, and
#   the authored M6 mark (codes `fe40/fe41`, pal row 0x19) IDENTICAL across
#   implementations. Must-fire: a one-bit promoted-code change turns 1c/1d red
#   (verified end to end); 3z fails if the select list is CONSTANT
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${BUILD:-build/m3b_merged22}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
RPL="$REPO/tests/replays/36_pick_tenant_cell.rpl"
EXP_AM=2886            # frozen MAME anchor  (test_mister_tenant_oracle)
EXP_AS=3546            # frozen sim anchor, ABSOLUTE
EXP_PROMOTED=31        # frozen 14z-109
EXP_A19_LO=0x4b0c4
EXP_A19_HI=0x4ecda
SIMDIR=""; MAMELOG=""; SELSIM=""; SELMAME=""
while [ $# -gt 0 ]; do
    case "$1" in
        --sim-dir)  shift; SIMDIR="$1" ;;
        --mame-log) shift; MAMELOG="$1" ;;
        --select-sim-dir)  shift; SELSIM="$1" ;;
        --select-mame-log) shift; SELMAME="$1" ;;
        *) echo "unknown arg $1" >&2; exit 2 ;;
    esac
    shift
done
fail=0
ok()  { echo "  PASS $1"; }
bad() { echo "  FAIL $1"; fail=1; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

if [ -z "$SIMDIR" ] || [ -z "$MAMELOG" ]; then
    [ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset"; exit 77; }
    command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed"; exit 77; }
    [ -d "$REPO/$BUILD/rompath" ] || { echo "SKIP: no $BUILD/rompath"; exit 77; }
    : "${MAME_BIN:=$HOME/.cache/vampire-saved/mame/cps2}"
    [ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 77; }
    : "${JTSIM_SCRATCH:?set JTSIM_SCRATCH to a dir OUTSIDE the repo}"

    echo "== MAME leg (OBJ records at the frozen anchor) =="
    REPLAY="$RPL" DUMP_FRAMES="$EXP_AM" TRACE_OUT="$W/mame_obj.txt" \
    MAME_SANDBOX="$W/box" MAME_BIN="$MAME_BIN" \
    MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/obj_records_dump.lua" \
        > "$W/mame.log" 2>&1 || { echo "FAIL: MAME leg"; exit 1; }
    MAMELOG="$W/mame_obj.txt"

    echo "== sim leg (cps2w, WIDE romset, ORAM out of SDRAM bank 0; ~65 min) =="
    "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/sim" --core cps2w --wide "$BUILD" \
        --frame-output off --frames 3800 \
        --region 0 0x640000 0x8000 0x700000 --wram $((EXP_AS-6)) $((EXP_AS+14)) \
        || { echo "FAIL: sim leg"; exit 1; }
    SIMDIR="$W/sim/wram"
fi

DUMP="$SIMDIR/dump_${EXP_AS}_700000.bin"
[ -s "$DUMP" ] || { echo "FAIL: no core ORAM dump at $DUMP"; exit 1; }
python3 "$REPO/tools/check_wram_dumps.py" "$SIMDIR" \
        --first $((EXP_AS-6)) --last $((EXP_AS+14)) >/dev/null 2>&1 \
    && ok "0a core dump set COMPLETE over the anchor window" \
    || bad "0a core dump set INCOMPLETE — any anchor would be an artefact"

python3 - "$DUMP" "$MAMELOG" "$EXP_AM" "$EXP_PROMOTED" "$EXP_A19_LO" "$EXP_A19_HI" <<'PY' > "$W/verdict.txt" 2>&1
import struct, re, sys
dump, mlog, am, expn, lo, hi = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5],16), int(sys.argv[6],16)

def walk(buf, base):
    out=[]
    for i in range(0x400):
        off=base+i*8
        if off+8>len(buf): break
        x,y,c,a=struct.unpack_from(">HHHH",buf,off)
        if y&0x8000 or a>=0xFF00: break
        out.append((x,y,c,a))
    return out

buf=open(dump,'rb').read()
# CPS-2 ORAM is DOUBLE-BUFFERED and the page select is runtime state
# (`main_addr_x[13] = main_ram_addr[15] ^ obank`), so WHICH page is live
# cannot be assumed. Walk BOTH and let the comparison pick: the gate passes
# if EITHER page's promoted set is the one MAME holds. Hard-coding a page is
# how a phase difference gets reported as a content difference.
pages={'P0': walk(buf,0x0000), 'P1': walk(buf,0x2000)}
mame=[]
for line in open(mlog):
    m=re.match(r"F%d B0 E(\d+) x=(\w+) y=(\w+) code=(\w+) attr=(\w+)"%am, line)
    if m:
        i,x,y,c,a=m.groups(); mame.append((int(x,16),int(y,16),int(c,16),int(a,16)))

prom  = lambda L: [e for e in L if e[1]&0x1000]
a19   = lambda e: (e[2] | ((e[1]&0x6000)<<3)) | (0x40000 if e[1]&0x1000 else 0)
mp = prom(mame)
# prefer a page whose promoted set MATCHES; otherwise report the fuller one
match = [k for k,v in pages.items() if prom(v)==mp]
which = match[0] if match else max(pages, key=lambda k: len(prom(pages[k])))
core = pages[which]; cp = prom(core)
print("LIVE PAGE %s (P0=%d entries, P1=%d entries; double-buffered, page chosen by comparison not assumption)"
      % (which, len(pages['P0']), len(pages['P1'])))
print("CORE list %d entries (%d promoted) | MAME list %d entries (%d promoted)"
      % (len(core), len(cp), len(mame), len(mp)))
print("UNPROMOTED remainder core=%d mame=%d  [REPORTED ONLY - the opponent lottery]"
      % (len(core)-len(cp), len(mame)-len(mp)))
print("PROMOTED_N %d %d" % (len(cp), len(mp)))
print("PROMOTED_IDENTICAL %s" % ("YES" if cp==mp else "NO"))
if cp:
    print("A19 0x%05x 0x%05x %d" % (min(map(a19,cp)), max(map(a19,cp)), len(set(map(a19,cp)))))
    print("A19_SETS_EQUAL %s" % ("YES" if set(map(a19,cp))==set(map(a19,mp)) else "NO"))
if cp!=mp:
    cs,ms=set(cp),set(mp)
    for e in list(cs-ms)[:4]: print("  core-only x=%04x y=%04x c=%04x a=%04x"%e)
    for e in list(ms-cs)[:4]: print("  mame-only x=%04x y=%04x c=%04x a=%04x"%e)
PY
sed 's/^/    /' "$W/verdict.txt"

N_CORE=$(awk '/^PROMOTED_N/{print $2}' "$W/verdict.txt")
N_MAME=$(awk '/^PROMOTED_N/{print $3}' "$W/verdict.txt")
[ "${N_CORE:-0}" -gt 0 ] 2>/dev/null \
    && ok "1a the promoted subset is NON-EMPTY ($N_CORE) — the comparison is not vacuous" \
    || bad "1a NO promoted sprites: nothing of ours is on screen, so agreement would be meaningless"
[ "${N_CORE:-0}" = "$EXP_PROMOTED" ] && [ "${N_MAME:-0}" = "$EXP_PROMOTED" ] \
    && ok "1b promoted count is the frozen $EXP_PROMOTED on BOTH legs" \
    || bad "1b promoted counts core=$N_CORE mame=$N_MAME, frozen $EXP_PROMOTED"
grep -q "^PROMOTED_IDENTICAL YES" "$W/verdict.txt" \
    && ok "1c the promoted entries are ORDERED AND FIELD-FOR-FIELD IDENTICAL across implementations" \
    || bad "1c the promoted entries DIFFER between MAME and the core"
grep -q "^A19_SETS_EQUAL YES" "$W/verdict.txt" \
    && ok "1d the 19-bit promoted tile ADDRESSES (what slice D3 computes) agree as a set" \
    || bad "1d the 19-bit promoted addresses DIFFER"

echo "== 2 MUST-FIRE: perturbing one promoted entry must be caught =="
python3 - "$DUMP" "$W/bad.bin" <<'PY'
import sys, struct
d=bytearray(open(sys.argv[1],'rb').read())
# find the first entry with the promote bit and move its code by one
for i in range(0x400):
    off=i*8
    x,y,c,a=struct.unpack_from(">HHHH",d,off)
    if y&0x8000 or a>=0xFF00: break
    if y&0x1000:
        struct.pack_into(">H",d,off+4,c^1); break
open(sys.argv[2],'wb').write(bytes(d))
PY
python3 - "$W/bad.bin" "$MAMELOG" "$EXP_AM" <<'PY' > "$W/bad.txt" 2>&1
import struct,re,sys
dump,mlog,am=sys.argv[1],sys.argv[2],int(sys.argv[3])
def walk(buf,base):
    out=[]
    for i in range(0x400):
        off=base+i*8
        x,y,c,a=struct.unpack_from(">HHHH",buf,off)
        if y&0x8000 or a>=0xFF00: break
        out.append((x,y,c,a))
    return out
buf=open(dump,'rb').read(); core=walk(buf,0x0000)
mame=[]
for line in open(mlog):
    m=re.match(r"F%d B0 E(\d+) x=(\w+) y=(\w+) code=(\w+) attr=(\w+)"%am,line)
    if m:
        i,x,y,c,a=m.groups(); mame.append((int(x,16),int(y,16),int(c,16),int(a,16)))
p=lambda L:[e for e in L if e[1]&0x1000]
print("PROMOTED_IDENTICAL %s"%("YES" if p(core)==p(mame) else "NO"))
PY
grep -q "^PROMOTED_IDENTICAL NO" "$W/bad.txt" \
    && ok "2a control fired: a one-bit change in a promoted tile code is caught" \
    || bad "2a a perturbed promoted entry still compared EQUAL — the gate is blind"

if [ -n "$SELSIM" ] && [ -n "$SELMAME" ]; then
echo "== 3 THE SELECT SCREEN — no CPU opponent has been drawn, so no lottery =="
# This is the STRONGER leg: with no opponent the confound that limits section 1
# to the promoted subset is absent, so the WHOLE list becomes comparable. It
# also covers content section 1 never sees — the wheel medallions and the
# authored version mark.
python3 "$REPO/tools/obj_select_compare.py" "$SELSIM" "$SELMAME" > "$W/sel.txt" 2>&1
sed 's/^/    /' "$W/sel.txt"
SN=$(awk '/^FRAMES/{print $2}' "$W/sel.txt")
SP=$(awk '/^PROMOTED/{print $2}' "$W/sel.txt")
SW=$(awk '/^WHOLE/{print $2}' "$W/sel.txt")
CD=$(awk '/^DISTINCT/{print $2}' "$W/sel.txt")
[ "${CD:-1}" -gt 1 ] 2>/dev/null \
    && ok "3z the select list is NON-CONSTANT ($CD distinct core lists) — agreement is not cheap" \
    || bad "3z the core select list is CONSTANT across the window; agreement would be meaningless"
[ -n "$SP" ] && [ "$SP" = "$SN" ] \
    && ok "3a the PROMOTED subset has an exact MAME twin on ALL $SN select frames" \
    || bad "3a promoted subset matched on only ${SP:-?} of ${SN:-?} select frames"
ok "3b whole-list agreement is $SW of $SN — the shortfall sits in the UNPROMOTED part and is REPORTED, never asserted"
grep -q "^VERSIONMARK [1-9][0-9]* MATCH" "$W/sel.txt" \
    && ok "3c the authored M6 version mark (palette row 0x19) is IDENTICAL across implementations" \
    || bad "3c the version mark is absent or differs"
fi

echo
[ "$fail" -eq 0 ] && echo "PASS test_mister_obj_oracle" || echo "FAIL test_mister_obj_oracle"
exit "$fail"
