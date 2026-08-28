#!/bin/sh
# audit_df_gold.sh — Phobos' Dark Force uploads HIS gold block; Bulleta's
# DF does not leak it (14z-84, the huitzil-m6 feature's guard). ~10 min,
# 2 controlled DF legs on the build under test.
#
# The palette path is RAM-gate-blind (the standing 14z-79 lesson), so
# this guard reads the LIVE CPS palette RAM during a controlled DF
# ($FF8509 stock bank + $FF802E asserted — the ratified rig) and
# compares rows against the build's OWN placed gold block (read from its
# patch.json via the fragment's data-block note — no reference decrypt
# needed, and drift in the block itself is caught by the same read).
#
#   leg 1  P1 = Phobos (0x10): DF on; >=1 palette row in 90c000-90c400
#          BYTE-EQUAL to a gold-block row (the upload is live);
#   leg 2  P1 = Bulleta (0x00): DF on; ZERO rows equal any gold row
#          (the anti-leak control — her purple stays hers).
#
# Usage: ROMDIR=... tests/audit_df_gold.sh [builddir]   (default hui32)
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
   # RE-POINTED 14z-94 (GitHub #94): was build/hui32, a pre-WIDE-v1.1 set
   # (19 members, no vsw.z01/z02) — the script could not run at all.
   # Its frozen inventory may still describe the OLD build: run it
   # before trusting a green, and re-measure rather than absorb.
BUILD="${1:-build/hui49}"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

for leg in phobos:10 bulleta:00; do
    name="${leg%%:*}"; id="${leg##*:}"
    d="$W/$name"; mkdir -p "$d"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:05;1450:ff8b82:05;1500:ff8b82:05;3100:ff8509:03;3120:ff8509:03"
    ( cd "$d" && MAME_ROMPATH="$REPO/$BUILD/rompath;$ROMDIR" \
      MAME_SANDBOX="$d/sb" POKES="$PK" \
      REPLAY="$REPO/tests/replays/hui/85_hui_df_vs2.rpl" \
      DUMPS="3400:ff8020-ff805f;3400:90c000-90c400;3500:90c000-90c400" \
      FRAMES=3520 CHECKSUM_OUT="$d/c.ram" \
      "$REPO/tools/run_mame.sh" vsavjw \
      -autoboot_script "$REPO/tests/lua/replay.lua" > "$d/out" 2>&1 ) \
        || { echo "FAIL: $name leg did not run"; fail=1; }
done

python3 - "$W" "$BUILD" <<'PY' || fail=1
import json, re, sys
W, build = sys.argv[1], sys.argv[2]
errs = []
# the build's own gold block: address from the fragment note, bytes from
# the patch op at that address
frag = open(f"{build}/patch/patch_notes_fragment.md").read()
m = re.search(r"data\s+0x([0-9a-f]+)\s+\+0x100\s+site_thunk "
              r"df_gold_variant_id data block", frag)
if not m:
    print("FAIL: no df_gold data-block note in the build's fragment")
    sys.exit(1)
addr = int(m.group(1), 16)
ops = json.load(open(f"{build}/patch/patch.json"))["ops"]
op = next((o for o in ops if "addr" in o
           and int(o["addr"], 16) == addr and "hex" in o), None)
if op is None or len(op["hex"]) != 0x200:
    print(f"FAIL: no 0x100-byte op at the fragment's address {addr:#x}")
    sys.exit(1)
gold = bytes.fromhex(op["hex"])
# the uploader ORs the alpha nibble onto each color word (the documented
# copier behavior — the select-sword thunk's "F000 alpha OR"), so live
# palette rows are the ROM rows with the top nibble set: compare on the
# 0x0FFF color bits. (The first run of this guard compared raw bytes and
# called a WORKING upload dead — the screens showed gold.)
def rowkey(b):
    return bytes(x & (0x0F if i % 2 == 0 else 0xFF)
                 for i, x in enumerate(b))
gold_rows = {rowkey(gold[i:i+0x20]) for i in range(0, 0x100, 0x20)}
print(f"  gold block read from the build: {addr:#x}, "
      f"{len(gold_rows)} distinct rows (alpha-masked)")
for name, want_gold in (("phobos", True), ("bulleta", False)):
    df = open(f"{W}/{name}/dump_3400_ff8020.bin", "rb").read()[0x0E]
    if df != 1:
        errs.append(f"{name}: NOT in Dark Force ($FF802E={df}) — "
                    "verdict vacuous, the rig regressed")
        continue
    found = 0
    for fr in (3400, 3500):
        pal = open(f"{W}/{name}/dump_{fr}_90c000.bin", "rb").read()
        for r in range(0, min(len(pal), 0x400), 0x20):
            if rowkey(pal[r:r+0x20]) in gold_rows:
                found += 1
    if want_gold and not found:
        errs.append(f"{name}: DF on but NO palette row equals a gold row "
                    "— the upload is dead")
    elif not want_gold and found:
        errs.append(f"{name}: {found} GOLD row(s) in Bulleta's DF — the "
                    "tenant block leaked into a legacy character (the "
                    "14z-69p class)")
    else:
        print(f"  ok: {name} — DF on, gold rows "
              f"{'present (' + str(found) + ')' if want_gold else 'absent'}")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: DF gold guard"; exit 1; }
echo "PASS: Phobos' DF uploads his gold block; Bulleta's DF is untouched"
