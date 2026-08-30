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
# Section 2 — PYRON (re-frozen 14z-67 moveset arc: his roots now pull
# the shared zones + the satellite handler family, 17 code regions).
# His OWN code region stays clean; the shared-zone findings mirror H's
# inventory exactly and are covered by his manifest rows (x026142 9->6,
# x05c800 2->1, the x088512 pod table) — plus the SAME two operand
# false positives (x028122 0x2CC64, x068c78 0x6B644). Growth beyond
# this = stop and root-cause.
#
# Usage: ROMDIR=... tests/test_census_regions.sh [hui_build_dir]
#   hui_build_dir: an existing tenant build (needs extract/ + patch/);
#   self-builds stage 4 from huitzil.toml if absent (code regions
#   place at stage 4 — the adjacency assert needs them placed). ~6 min.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   ground truth for tools/census_regions.py (14z-67): the data_in_code +
#   pcrel-escape censuses — H's frozen inventory (5 sites, 89/35 + 9/6
#   escapes, adjacency-safe class, 2 known false positives, the x05c800 KNOWN-
#   OPEN latent pair) + Pyron clean. Self-builds stage 4 unless given a build
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
# the five original sites, each covered by a [[data_in_code]] manifest row
want_rows = {0x056020, 0x05604C, 0x056458, 0x056484, 0x08BFF6}
# 14z-69i: x06cac0's own seven pc-rel tables. They became VISIBLE when the
# census learned the deferred-reader shapes (the post-increment walk 0x3e
# bytes away in a bsr subroutine, and two indexed reads 3-4 instructions
# later), and they are covered by a DIFFERENT mechanism: the region's forced
# tail is emitted RAW, so the data reads return the bytes verbatim. No
# manifest row, and none wanted — verify_pcrel_data.py / the build check
# confirm all seven byte-for-byte.
want_raw = {0x06CD5E, 0x06CFDC, 0x06D206, 0x06D542, 0x06D594, 0x06D5E0,
            0x06D628}
# RE-FROZEN 14z-94 (GitHub #30), +1 site: 0x08C038, an `indexed-far` reader
# in the x088512 pod zone whose table sits at 0x08C0A2 (walk distance 0x54).
# Measured covered=1 AND raw_emitted=1 — i.e. the SAME benign mechanism as
# the x06cac0 seven above: the region's forced tail is emitted RAW, so the
# read returns the bytes verbatim and no manifest row is wanted.
#
# It is a SEPARATE name rather than an addition to want_raw because it has a
# different host region; lumping it in would hide which zone grew.
#
# This gate has gone stale-red this way before and the precedent is recorded
# a few lines down (x022400, "caught by the 14z-68 end-of-session sweep, not
# by a run at the time"). This time it was caught by tests/run_all_static.sh
# on its first full execution — which is the entire point of #30. Growth
# BEYOND this set still means stop and root-cause.
want_raw_x088512 = {0x08C038}
assert set(dc) == want_rows | want_raw | want_raw_x088512, \
    f"data_in_code readers drifted: {sorted(map(hex, dc))}"
assert all(dc[r]["covered"] and not dc[r].get("raw_emitted")
           for r in want_rows), "a manifest-row reader lost coverage"
assert all(dc[r]["raw_emitted"] for r in want_raw), \
    "an x06cac0 table left the raw-emitted tail"
# The new site is held to the same bar it was admitted on: covered AND raw.
# If it ever stops being raw-emitted it needs a manifest row, and this is
# where that must surface.
assert all(dc[r]["raw_emitted"] and dc[r]["covered"] for r in want_raw_x088512), \
    "the x088512 reader is no longer covered+raw-emitted — it now needs a " \
    "[[data_in_code]] manifest row, not a re-freeze"
print("  ok: data_in_code = 5 row-covered sites + 7 raw-emitted (x06cac0)"
      " + 1 raw-emitted (x088512)")

e = c["escapes"]
EXPECT = {  # region: (count, n_unique, covered)
    # x022400 = the 14z-67 effect-object zone clone. It entered the
    # roots after this inventory was first frozen, so the gate went
    # STALE-RED and was caught by the 14z-68 end-of-session sweep, not
    # by a run at the time. Its escapes are COVERED (huitzil.toml
    # carries a pcrel_escape_fix row for it), so adding it is a
    # legitimate re-freeze, not a loosening.
    "x022400": (118, 11, True),
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

echo "== section 2: Pyron (full-roots extraction via a stage-1 build)"
TENANT_MANIFEST=build/manifest/pyron.toml TENANT_CHAR=0x11 \
    GEN_FLAGS="--profile cps2-wide-v1" \
    tools/build_donovan.sh 1 "$W/pb" > "$W/pb.log" 2>&1 \
    || { tail -10 "$W/pb.log"; echo "FAIL: P stage-1 build errored"; exit 1; }
python3 tools/census_regions.py "$W/pb/extract" \
    --manifest build/manifest/pyron.toml --json "$W/pc.json" > "$W/pc.txt"
python3 - "$W/pc.json" <<'PY'
import json, sys
c = json.load(open(sys.argv[1]))
assert len(c["code_regions"]) == 17, \
    f"Pyron code-region count {len(c['code_regions'])} != 17 — roots " \
    "changed; rerun the census and re-freeze"
dc = {h["reader"]: h["covered"] for h in c["data_in_code"]}
assert dc == {0x08BFF6: True}, f"data_in_code drifted: {dc}"
e = {k: (v["count"], len(v["unique_targets"]), v["covered"])
     for k, v in c["escapes"].items()}
assert e == {"x026142": (9, 6, True), "x05c800": (2, 1, True),
             "x028122": (1, 1, False), "x068c78": (1, 1, False)}, \
    f"escape inventory drifted: {e}"
print("  ok: Pyron census frozen (own code clean; shared-zone findings "
      "covered; the two known operand false positives)")
PY

echo "PASS: region censuses ground-truthed (H inventory frozen; P clean)"
