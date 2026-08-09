#!/bin/sh
# test_pyron_cosmo.sh — the COSMO DISRUPTION gate (14z-74).
#
# THE DEFECT (maintainer playtest): Pyron's EX — 41236 + hold/release 2P or
# 2K, costs one meter stock — CRASHED and reset the game.
#
# ROOT CAUSE, and why this gate looks the way it does. The shared engine
# dispatches the move's sub-state through a self-encoding, pc-relative jump
# table:
#     018460  move.w $18468(pc,d0.w),d1
#     018464  jmp    $18468(pc,d1.w)
# With d0 = 0xa2 (entry 81). That entry is IN RANGE — the table holds 265
# entries and entry 0 (0x0212) self-encodes the length — but vsavj stores
# 0x0006 there, a displacement pointing back INTO the table. vs2's twin
# (table 0x016d34, 277 entries) stores a real handler. So vsav ships the row
# as a STUB where vs2 fills it: the BEAM's defect class. The jmp executes the
# table's own bytes until it hits an illegal instruction, and the watchdog
# resets the board.
#
# The fix is ONE WORD. vs2's handler is eight position-independent bytes
# (`move.b 0x17(a3),0x54(a1) / rts`) and vsavj ALREADY CONTAINS them at
# 0x01868C = table + 0x224 — which is the table's most common entry, i.e.
# the shared handler vanilla already points many live states at. Repointing
# entry 81 to 0x0224 reproduces vs2 exactly with no ported code, no displaced
# instruction and no legacy cycles.
#
# SECTIONS
#   1. STATIC — the build emits the guarded word and the target really is
#      vs2's handler byte-for-byte.
#   2. DEADNESS (the safety argument, measured not argued) — entry 81 is
#      never dispatched by vanilla. The table is read PC-RELATIVELY, so the
#      watchpoint MUST use the opcodes space (a plain wpset is blind to
#      pc-relative reads and reports a clean zero — 14z-71). Reads are
#      filtered BY PC: the boot ROM-checksum sweep (PC 0x000926, frame 1)
#      touches every ROM byte and would otherwise look like a live dispatch.
#      A same-instrument positive control on the live entry-0 slot proves the
#      probe can see what it is looking for.
#   3. RUNTIME — the crash rig no longer crashes, the EX still FIRES (a stock
#      is spent; an empty meter would silently downgrade it — the DF/ES trap),
#      and the match state survives (a watchdog reset is not a 68k exception,
#      so the crash guard alone cannot prove this — the field trace does).
#
# Usage: ROMDIR=... tests/test_pyron_cosmo.sh [wide-builddir]   (default build/pyron7)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/pyron7}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no $BUILD/rompath/vsavjw.zip"; exit 1; }
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3300:ff8509:03;3700:ff8509:03;4100:ff8509:03"
RPL="$REPO/tests/replays/pyron/72_pyron_cosmo_2p.rpl"

echo "== 1. static: the guarded word + the target is vs2's handler"
grep -q "code_word cosmo_substate81 (0006 -> 0224)" \
    "$BUILD/patch/patch_notes_fragment.md" \
    || { echo "FAIL: cosmo_substate81 not emitted by this build"; exit 1; }
python3 - "$ROMDIR" "$W" <<'PY' || exit 1
import subprocess, sys, os
romdir, W = sys.argv[1], sys.argv[2]
for s in ("vsavj", "vsav2"):
    subprocess.run([sys.executable, "tools/cps2_decrypt.py", f"{romdir}/{s}.zip",
                    f"{W}/{s}_op.bin", "--data-out", f"{W}/{s}_dat.bin"],
                   check=True, capture_output=True)
vj = open(f"{W}/vsavj_op.bin", "rb").read()
v2 = open(f"{W}/vsav2_op.bin", "rb").read()
TB, VTB = 0x18468, 0x16d34
ok = True
if int.from_bytes(vj[TB:TB+2], "big") != 0x0212:
    print(f"FAIL: vsavj table length word moved ({vj[TB:TB+2].hex()})"); ok = False
if int.from_bytes(vj[TB+0xA2:TB+0xA4], "big") != 0x0006:
    print("FAIL: vsavj entry 81 is no longer the 0x0006 stub"); ok = False
h = v2[0x16f70:0x16f78]
if h != bytes.fromhex("136b001700544e75"):
    print(f"FAIL: vs2 handler bytes moved ({h.hex()})"); ok = False
if vj[TB+0x224:TB+0x224+8] != h:
    print("FAIL: vsavj table+0x224 is not vs2's handler byte-for-byte"); ok = False
if int.from_bytes(v2[VTB+0xA2:VTB+0xA4], "big") == 0x0006:
    print("FAIL: vs2 entry 81 is a stub too — the premise is wrong"); ok = False
print("  ok: entry 81 stub confirmed; table+0x224 == vs2's handler (8 bytes)" if ok else "")
sys.exit(0 if ok else 1)
PY

echo "== 2. deadness: vanilla never dispatches entry 81 (opcodes space, PC-filtered)"
probe() {  # $1 addr  $2 replay -> prints dispatcher-sourced read count
    d="$W/p_$1_$2"; mkdir -p "$d/s1"
    ( cd "$d" && WATCH="$1,2,r,o" REPLAY="$REPO/tests/replays/$2.rpl" \
      TRACE_OUT="$d/t.txt" FRAMES=4000 MAME_SANDBOX="$d/s1" \
      "$REPO/tools/run_mame.sh" vsavj -debug -debugger none \
      -autoboot_script "$REPO/tests/lua/trace_writes.lua" >"$d/o" 2>&1 ) || true
    grep '^frame' "$d/t.txt" 2>/dev/null | grep -c "PC 018464" || true
}
dead=0; ctl=0
for r in 02_demitri_vs_cpu 03_two_player_vs; do
    n=$(probe 1850a "$r"); c=$(probe 18468 "$r")
    echo "   $r: entry81 dispatcher-reads=$n   control(entry0)=$c"
    dead=$((dead + n)); ctl=$((ctl + c))
done
[ "$ctl" -gt 0 ] || { echo "FAIL: the control saw ZERO reads — the probe is blind (opcodes space? PC filter?)"; exit 1; }
[ "$dead" -eq 0 ] || { echo "FAIL: vanilla DOES dispatch entry 81 ($dead reads) — the row is not dead"; exit 1; }
echo "  ok: 0 dispatcher reads of entry 81 against a live control ($ctl)"

echo "== 3. runtime: no crash, the EX fires, the match survives"
d="$W/run"; mkdir -p "$d"
MAME_ROMPATH="$BUILD/rompath;$ROMDIR" POKES="$PK" \
    "$REPO/tools/run_replay_guarded.sh" vsavjw "$RPL" "$d/g.log" "$d/box" >"$d/o" 2>&1 || true
if grep -q "^CRASH" "$d/g.log"; then
    echo "FAIL: still crashing:"; grep -m1 "^CRASH" "$d/g.log"; exit 1
fi
echo "  ok: guarded run clean ($(grep -m1 '^END' "$d/g.log"))"
d2="$W/ft"; mkdir -p "$d2/s1"
( cd "$d2" && MAME_ROMPATH="$BUILD/rompath;$ROMDIR" REPLAY="$RPL" POKES="$PK" \
  FIELDS="ff8509:b:stk,ff8406:b:seq,ff8450:w:hp,ff8782:b:ch" \
  FIELD_OUT="$d2/f.txt" FIELD_FROM=3390 FIELD_TO=4400 FRAMES=4500 MAME_SANDBOX="$d2/s1" \
  "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/field_trace.lua" >"$d2/o" 2>&1 ) || true
python3 - "$d2/f.txt" <<'PY' || exit 1
import sys
rows = []
for l in open(sys.argv[1]):
    if l.startswith("F "):
        p = l.split()
        d = {k: int(v) for k, v in (t.split("=") for t in p[2:])}
        d["F"] = int(p[1]); rows.append(d)
if not rows:
    print("FAIL: no field samples"); sys.exit(1)
reset = [r for r in rows if r["ch"] != 0x11 or r["hp"] == 0]
spends = [r["F"] for i, r in enumerate(rows) if i and r["stk"] < rows[i-1]["stk"]]
seqs = sorted({r["seq"] for r in rows})
print(f"   reset-signature frames={len(reset)}  stock spends={spends[:4]}  seqs={seqs}")
ok = True
if reset:
    print(f"FAIL: match state vanished at f{reset[0]['F']} — the watchdog reset is back"); ok = False
if not spends:
    print("FAIL: no stock spent — the EX never fired, so this run proves nothing"); ok = False
if 18 not in seqs:
    print("FAIL: the EX sub-state (seq 18) never appeared"); ok = False
sys.exit(0 if ok else 1)
PY
echo "  ok: EX fires (stock spent, seq 18) and the match survives"
echo
echo "PASS: Cosmo Disruption — the dead sub-state row is filled, the crash is"
echo "      gone, the move still fires, and vanilla never reaches that row"
