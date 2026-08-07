#!/bin/sh
# test_census_regions.sh — ground truth for tools/census_regions.py (the
# 14z-66 data_in_code + pcrel-escape censuses, promoted to a tool for the
# D4 step-2 Pyron early warning, 14z-67).
#
# Section 1 — INSTRUMENT VALIDATION on the full Huitzil extraction (the
# known inventory, frozen):
#   data_in_code: EXACTLY the 5 shipped manifest rows (readers 0x056020/
#     0x05604C/0x056458/0x056484/0x08BFF6), all covered — zero false
#     positives on the shape.
#   escapes: x02592a 89->35 and x026142 9->6 (both EXACTLY the
#     generator's own emitted counts, both covered); code->x057456
#     20 sites whose targets ALL land in the adjacently-placed x057456
#     (same delta, contiguous => pcrel-safe by construction, asserted
#     from placements.json); x068c78 1 + x028122 1 = known operand
#     false positives (matched words are move.l/move.w immediates);
#     x05c800 2 sites -> 0x635FC = the latent escape THIS CENSUS found
#     (14z-67), fixed the same session by a [[pcrel_escape_fix]] row +
#     the 0x635FC -> 0x5B25C recon twin — now asserted covered.
#   Growth in ANY census number = stop and root-cause (the x026142
#   lesson: latent escapes bite later, not never).
#
# Section 2 — PYRON EARLY WARNING (D4 step 2): his current single code
# region censuses CLEAN (0 data_in_code, 0 escapes). His support-zone
# roots are not extracted yet; when his R1 census grows the region set,
# the region-count lock fails loudly -> rerun and re-freeze.
#
# Usage: ROMDIR=... tests/test_census_regions.sh [hui_build_dir]
#   hui_build_dir: an existing tenant build (needs extract/ + patch/);
#   self-builds stage 4 from huitzil.toml if absent (code regions
#   place at stage 4 — the adjacency assert needs them placed). ~6 min.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

HB="${1:-}"
if [ -z "$HB" ]; then
    echo "== self-building Huitzil (stage 4, full-roots extraction)"
    TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
        GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
        tools/build_donovan.sh 4 "$W/hb" > "$W/hb.log" 2>&1 \
        || { tail -10 "$W/hb.log"; echo "FAIL: H stage-4 build errored"; exit 1; }
    HB="$W/hb"
fi

echo "== section 1: instrument ground truth (Huitzil inventory)"
python3 tools/census_regions.py "$HB/extract" \
    --manifest build/manifest/huitzil.toml --json "$W/h.json" > "$W/h.txt"
python3 - "$W/h.json" "$HB/patch/placements.json" <<'PY'
import json, sys
c = json.load(open(sys.argv[1]))
pl = json.load(open(sys.argv[2]))["regions"]

dc = {h["reader"]: h for h in c["data_in_code"]}
want = {0x056020, 0x05604C, 0x056458, 0x056484, 0x08BFF6}
assert set(dc) == want, f"data_in_code readers drifted: {sorted(map(hex, dc))}"
assert all(h["covered"] for h in dc.values()), "known reader lost coverage"
print("  ok: data_in_code = exactly the 5 known covered sites")

e = c["escapes"]
EXPECT = {  # region: (count, n_unique, covered)
    "x02592a": (89, 35, True),
    "x026142": (9, 6, True),
    "code":    (20, 4, False),
    "x05c800": (2, 1, True),   # covered 14z-67: the gfx-rung fix landed
    "x068c78": (1, 1, False),
    "x028122": (1, 1, False),
}
assert set(e) == set(EXPECT), f"escape region set drifted: {sorted(e)}"
for name, (cnt, uq, cov) in EXPECT.items():
    r = e[name]
    assert (r["count"], len(r["unique_targets"]), r["covered"]) \
        == (cnt, uq, cov), f"{name} drifted: {r}"
print("  ok: escape inventory frozen (89/35 + 9/6 covered; 4 triaged)")

# the code->x057456 sites are safe iff the pair is placed contiguously
# at one delta (pcrel displacements preserved across the boundary)
cd_, xd = pl["code"], pl["x057456"]
assert cd_["dst"] - cd_["src"] == xd["dst"] - xd["src"], "deltas differ"
assert cd_["dst"] + cd_["len"] == xd["dst"], "pair no longer contiguous"
lo, hi = xd["src"], xd["src"] + xd["len"]
assert all(lo <= t < hi for t in e["code"]["unique_targets"]), \
    "code escape target outside x057456"
print("  ok: code->x057456 escapes adjacency-safe (same delta, contiguous)")

assert e["x05c800"]["unique_targets"] == [0x635FC], "x05c800 target moved"
print("  ok: x05c800 escape pair covered (0x635FC -> 0x5B25C recon row, "
      "the 14z-67 pcrel_escape_fix)")
PY

echo "== section 2: Pyron early warning"
python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$W/p" \
    --char 0x11 --oracle "$ROMDIR/vhunt2.zip" > "$W/p.log" 2>&1 \
    || { tail -10 "$W/p.log"; echo "FAIL: 0x11 extraction errored"; exit 1; }
python3 tools/census_regions.py "$W/p" --json "$W/pc.json" > "$W/pc.txt"
python3 - "$W/pc.json" <<'PY'
import json, sys
c = json.load(open(sys.argv[1]))
assert c["code_regions"] == ["code"], \
    f"Pyron code-region set grew: {c['code_regions']} — rerun the census " \
    "over the new regions and re-freeze"
assert not c["data_in_code"] and not c["escapes"], \
    f"Pyron census no longer clean: {c}"
print("  ok: Pyron's code region censuses CLEAN (0 data_in_code, 0 escapes)")
PY

echo "PASS: region censuses ground-truthed (H inventory frozen; P clean)"
