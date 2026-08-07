#!/bin/sh
# test_gfx_layout3.sh — fact-locks for the 3-tenant group-C tile layout
# (D4 opener step 1, session 14z-67). Static: reads the reference zips
# only, no MAME, no build output. ~90s (one vs2 decrypt).
#
# Locks (measured 2026-08-07, instrument tools/obj_records.py over the
# ratified extraction anim spans — spans verified verbatim slices of the
# vs2 data image):
#   1. All three tenants read vs2 BANK 3 (bank-table rows 0x10/0x11/0x13
#      at PRG:0x27530 all 0x6000) — the one-source-bank premise.
#   2. Frozen tile inventories: H 15,034 unique / band 0x0AF6-0x4EFC;
#      P 14,225 / band 0x4ED5-0x8647; D 15,612 / band 0x863F-0xC2EF.
#      (Re-frozen 14z-67b: walker entry-bounds fix + per-tenant sweep.)
#   3. THE LAYOUT INVARIANT: max(H∪P native code) < 0xAD80 (Donovan's
#      SAFE_LO) — delta-0 placement for H/P is disjoint from Donovan's
#      frozen band+shelf by interval, no enumeration needed.
#   4. THE FLIP CONDITION (D4): H∪P exact union + Donovan's whole safe
#      window fits bank 4 with headroom — three tenants fit group C.
#   5. The manifest (build/manifest/gfx_layout3.toml) agrees with the
#      measurement (bands, deltas, spans).
# Drift in any number means the walker, the extraction shapes, or the
# understanding moved: stop and root-cause, do not re-freeze.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

python3 "$REPO/tools/cps2_decrypt.py" "$ROMDIR/vsav2.zip" "$W/vs2_op.bin" \
    --data-out "$W/vs2_data.bin" > /dev/null 2>&1

python3 - "$REPO" "$W" <<'PY'
import json, sys, os
repo, work = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(repo, "tools"))

from _minitoml import loads as toml_loads

op = open(os.path.join(work, "vs2_op.bin"), "rb").read()
dat = open(os.path.join(work, "vs2_data.bin"), "rb").read()
man = toml_loads(open(os.path.join(repo,
    "build/manifest/gfx_layout3.toml")).read())
ten = {t["name"]: t for t in man["tenant"]}
fails = []

def check(cond, msg):
    if cond:
        print("  ok:", msg)
    else:
        fails.append(msg); print("FAIL:", msg)

# 1. one source bank: rows 0x10/0x11/0x13 of the vs2 bank table
rows = {i: int.from_bytes(op[0x27530 + 2*i: 0x27532 + 2*i], "big")
        for i in (0x10, 0x11, 0x13)}
check(all(v == 0x6000 for v in rows.values()),
      "vs2 bank-table rows 0x10/0x11/0x13 all 0x6000 (bank 3): "
      + ", ".join(f"{k:#x}={v:#06x}" for k, v in rows.items()))

# 2. inventories re-derived from the data image (obj_records walk over
#    the ratified spans). EXPECT rows: (unique, band_lo, band_hi, n_band).
import subprocess
# counts re-frozen 14z-67b after the walker refinement (entry-bounds
# check + per-tenant sweep windows — H/P sweep = their own bands, so
# their offset-computed overlay records now inventory; Donovan keeps
# the historical window and is UNCHANGED, bit-exactness preserved)
EXPECT = {
    "huitzil": (15034, 0x0AF6, 0x4EFC, 15010),
    "pyron":   (14225, 0x4ED5, 0x8647, 14171),
    "donovan": (15612, 0x863F, 0xC2EF, 15498),
}
tiles = {}
for name, (uniq, blo, bhi, nband) in EXPECT.items():
    t = ten[name]
    base, ln = t["anim_base"], t["anim_len"]
    img = os.path.join(work, name + "_anim.bin")
    open(img, "wb").write(dat[base: base + ln])
    out = os.path.join(work, name + "_tiles.json")
    subprocess.run([sys.executable,
        os.path.join(repo, "tools/obj_records.py"), img,
        "--base", hex(base), "--start", hex(base), "--end", hex(base + ln),
        "--cptr-lo", "0x300000", "--cptr-hi", "0x361000",
        "--sweep-lo", hex(t["sweep_lo"]), "--sweep-hi", hex(t["sweep_hi"]),
        "--json", out], check=True, stdout=subprocess.DEVNULL)
    tv = set(json.load(open(out)))
    tiles[name] = tv
    band = [c for c in tv if blo <= c <= bhi]
    check(len(tv) == uniq and len(band) == nband
          and min(band) == blo and max(band) == bhi,
          f"{name} inventory locked ({len(tv)} unique; band "
          f"{min(band):#06x}-{max(band):#06x} {len(band)} tiles)")
    # manifest agreement
    check(t["band_lo"] == blo and t["band_hi"] == bhi,
          f"{name} manifest band row matches measurement")

# 3. the layout invariant: delta-0 H∪P strictly below Donovan's SAFE_LO
hp = tiles["huitzil"] | tiles["pyron"]
safe_lo = ten["donovan"]["safe_lo"]
check(ten["huitzil"]["delta"] == 0 and ten["pyron"]["delta"] == 0,
      "manifest: H and P at delta 0")
check(ten["donovan"]["delta"] == 0x2750,
      "manifest: Donovan frozen at delta +0x2750")
check(max(hp) < safe_lo,
      f"H∪P max native code {max(hp):#06x} < Donovan SAFE_LO {safe_lo:#06x} "
      "(disjoint by interval)")

# 4. the flip condition: worst-case bank-4 occupancy fits with headroom
worst = len(hp) + (ten["donovan"]["safe_hi"] - safe_lo + 1)
check(worst <= 0x10000 - 4096,
      f"three tenants fit bank 4: worst-case {worst}/65536 "
      f"({0x10000 - worst} codes headroom)")

# shared codes are same-source by construction (all bank 3, delta 0) —
# record the counts so growth is visible
d = tiles["donovan"]
print(f"  ok: shared codes H∩P={len(tiles['huitzil'] & tiles['pyron'])} "
      f"P∩D={len(tiles['pyron'] & d)} H∩D={len(tiles['huitzil'] & d)} "
      "(same-source, delta-0 compatible)")

sys.exit(1 if fails else 0)
PY
rc=$?
[ "$rc" = 0 ] && echo "PASS: 3-tenant group-C layout fact-locks" \
              || echo "FAIL: 3-tenant group-C layout fact-locks"
exit "$rc"
