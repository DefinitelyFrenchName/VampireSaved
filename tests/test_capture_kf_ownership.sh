#!/bin/sh
# test_capture_kf_ownership.sh — THE CAPTURE-KEYFRAME POINTER TABLE IS
# HAND-OWNED, AND NO GENERIC bank_map REPOINT MAY WRITE IT (14z-130).
#
# THE TABLE. PRG:0x0BE27A, 32 LONGWORDS indexed by the ATTACKER's char id —
# the capture-pose installer's block pointer ([VSE-44]; consumers at vsavj
# 0x02802E / 0x0280C6 / 0x028140, locked by test_capture_pose_sources.sh).
#
# WHY THIS GATE EXISTS. Until 14z-130 `bank_map.toml` modelled it as TWO
# `kind = "auto"` rows of `stride = 0x40` (`gap_be27a` + `gap_be2ba`), i.e.
# as two 32-entry WORD tables. That was wrong three ways and cost two things:
# `audit_shared_writes.py` derives its variant-row exemption from the stride,
# so eight LEGACY rows were exempt from the one gate whose purpose is to force
# a legacy-surface review (contained 14z-128, root-fixed 14z-130); and the
# generated character-data pages read the tenant row at the wrong address.
# Correcting the row to `kind = "data_ptr"` makes the GENERIC per-character
# repoint in gen_donovan_patch.py fire on a table that is ALREADY owned row by
# row by 18 `[[data_port]]` rows (17 until pyron's own row 0x11 was ported
# 14z-143). Measured 14z-130 on the M13 tracks, that
# generic repoint would have done three things, only the first of them loud:
#   * donovan: overwrite the wide_ext blob pointer with the hitbox-region
#     copy, silently DISCARDING the 14z-64 mirror-victim fix (section 3);
#   * pyron:   a NEW write repointing his attacker row 0x11 off Demitri's
#     block. That surface was RULED and PORTED 14z-143 (the row is now
#     `pyron_capture_keyframes`, vs2's own block 0x0C7F98), which SHARPENS
#     this hazard rather than retiring it: the generic repoint would aim
#     row 0x11 at the extraction's hitbox-region copy and so DISCARD the
#     port, exactly as it would discard donovan's 14z-64 fix above;
#   * stock:   a write repointing JEDAH's row into Donovan's placed hitbox
#     copy, breaking the base-slot in-place path.
# The generator suppresses it via the 14z-65 `claimed_ptr_tables` mechanism,
# extended to `slot_ptr_table`. This gate locks the RESULT, not the mechanism.
#
# THE ANCHOR IS OUTSIDE THE BUILD ([VSP-166]). Every expectation here is read
# from the reference ROM (pristine vsavj, via tests/lib/decrypt_cache.sh) and
# SHIPPED IMAGE (<build>/verify_data.bin); nothing is derived from patch.json,
# placements.json or the manifests. A gate that asked the build what it wrote
# and then checked it wrote that would assert nothing.
#
# SECTIONS
#   1. THE MODEL, from the ROM: the entries are LONGS, not words — vsavj's
#      rows 0x10-0x1F alias 0x00-0x0F byte for byte, all 32 longs are
#      plausible ROM pointers, and the word reading is not; the table tiles
#      exactly to param32_b at 0x0BE2FA. Plus: bank_map declares exactly ONE
#      row based there, with entry size 4.
#   2. THE REPOINT INVENTORY: on each built image, the set of rows that
#      DIFFER from pristine vsavj equals the frozen set below. This is what
#      catches a new generic write (pyron 0x11, stock 0x0F).
#   3. THE 14z-64 MIRROR-VICTIM FIX RIDES THE SHIPPED ROW: donovan's row 0x13
#      target carries 0x0d88 at +0x1E, and the hitbox-region copy the generic
#      repoint would have used carries the UNFIXED 0x0b30 — which is both the
#      discriminator and the gate's liveness control ([VSP-22]: a blind
#      instrument and a real pass look identical, so the check is shown able
#      to tell the two blocks apart).
#   4. MUST-FIRE CONTROLS: a perturbed unclaimed row must fail section 2, and
#      a perturbed fix word must fail section 3.
#
# PROVENANCE OF THE FROZEN SETS (evidence class: static — read off the built
# images 14z-130, reproduced by re-running this gate after a rebuild):
#   stock   {}                       — the base-slot track replaces the block
#                                      IN PLACE at `dst`; no row is repointed
#   donovan 0x00-0x0F, 0x13, 0x18    — 15 capture_kf_* slot_rows + Oboro
#                                      + throw_victim_keyframes (his own row)
#   huitzil 0x00-0x0F, 0x10, 0x18    — same, + grab_hold_keyframes
#   pyron   0x00-0x0F, 0x11, 0x18    — same, + pyron_capture_keyframes
#                                      (his own row, ported 14z-143)
#   merged  0x00-0x0F, 0x10, 0x11, 0x13, 0x18
#   (the pyron and merged rows re-measured 14z-143 on the tracks that first
#    carried the port; the other three are unchanged from 14z-130)
#
# Static, no emulator, ~2 s. Needs $ROMDIR and the build dirs.
# Usage: ROMDIR=... tests/test_capture_kf_ownership.sh
# Build dirs (code defaults, [VSP-165]): DON=build/don_m22 HUI=build/hui56
#   PYR=build/pyron37 STOCK=build/m5_stock14 MERGED=build/m3b_merged22
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; export REPO
cd "$REPO"

DON="${DON:-build/don_m22}"
HUI="${HUI:-build/hui56}"
PYR="${PYR:-build/pyron41}"
STOCK="${STOCK:-build/m5_stock17}"
MERGED="${MERGED:-build/m3b_merged26}"

: "${ROMDIR:?set ROMDIR}"

# the decrypted reference view is ROM-derived (rule 7) and comes from the
# SHARED CACHE, never a direct decrypt — tests/test_decrypt_cache.sh section 5
# fails any converted gate that shells out to tools/cps2_decrypt.py itself.
. "$REPO/tests/lib/decrypt_cache.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_dat.bin" \
    || { echo "FAIL: vsavj decrypt view"; exit 1; }

VAN_DATA="$W/vj_dat.bin" \
DON="$DON" HUI="$HUI" PYR="$PYR" STOCK="$STOCK" MERGED="$MERGED" \
python3 - <<'PY'
import os, re, struct, sys
from pathlib import Path

BASE   = 0x0BE27A
NEXT   = 0x0BE2FA          # param32_b — the table tiles exactly to it
NROWS  = 32
FIX_OFF, FIX_NEW, FIX_OLD = 0x1E, 0x0d88, 0x0b30   # 14z-64 mirror victim

fails, notes = [], []

van = Path(os.environ["VAN_DATA"]).read_bytes()
def rows(buf):
    return [struct.unpack_from(">I", buf, BASE + i * 4)[0] for i in range(NROWS)]
VAN = rows(van)

# ── 1. THE MODEL, from the ROM ───────────────────────────────────────────────
alias = [i for i in range(16) if VAN[i] != VAN[i + 16]]
if alias:
    fails.append(f"1: vsavj rows 0x10-0x1F do not alias 0x00-0x0F "
                 f"(mismatch at {[hex(i) for i in alias]})")
else:
    notes.append("1: vsavj rows 0x10-0x1F alias 0x00-0x0F, 16/16")

bad = [i for i, v in enumerate(VAN) if not (0x1000 < v < 0x400000)]
if bad:
    fails.append(f"1: longword reading gives implausible entries at "
                 f"{[hex(i) for i in bad]}")
else:
    notes.append(f"1: all {NROWS} longwords are plausible ROM pointers "
                 f"(0x{min(VAN):06X}-0x{max(VAN):06X})")

# the discriminator: as WORDS, the even entries are pointer HIGH halves
words = [struct.unpack_from(">H", van, BASE + i * 2)[0] for i in range(NROWS * 2)]
implausible = sum(1 for w in words[::2] if w < 0x1000)
if implausible < NROWS:
    fails.append(f"1: word reading is not refuted — only {implausible}/{NROWS} "
                 f"even entries are implausible highs")
else:
    notes.append(f"1: word reading refuted — {implausible}/{NROWS} even 'entries' "
                 f"are pointer high halves")

txt = Path("build/manifest/bank_map.toml").read_text()
at_base, entry_sizes = [], []
for block in txt.split("[[table]]")[1:]:
    row = dict(re.findall(r'^(\w+)\s*=\s*("[^"]*"|0x[0-9A-Fa-f]+|\d+)',
                          block, re.M))
    if "vsavj" not in row:
        continue
    if int(row["vsavj"].strip('"'), 0) == BASE:
        at_base.append(row.get("name", '"?"').strip('"'))
        entry_sizes.append(int(row.get("stride", '"0x80"').strip('"'), 0) // 32)
if len(at_base) != 1:
    fails.append(f"1: bank_map has {len(at_base)} rows based at {BASE:#x} "
                 f"({at_base}) — expected exactly one")
elif entry_sizes[0] != 4:
    fails.append(f"1: bank_map row {at_base[0]!r} has entry size "
                 f"{entry_sizes[0]}, expected 4")
elif BASE + entry_sizes[0] * NROWS != NEXT:
    fails.append(f"1: bank_map row {at_base[0]!r} does not tile to {NEXT:#x}")
else:
    notes.append(f"1: bank_map declares one row {at_base[0]!r}, entry size 4, "
                 f"tiling {BASE:#x}+0x80 = {NEXT:#x}")

# ── 2. THE REPOINT INVENTORY ─────────────────────────────────────────────────
FROZEN = {
    "stock":   set(),
    "donovan": set(range(0x10)) | {0x13, 0x18},
    "huitzil": set(range(0x10)) | {0x10, 0x18},
    "pyron":   set(range(0x10)) | {0x11, 0x18},
    "merged":  set(range(0x10)) | {0x10, 0x11, 0x13, 0x18},
}
BUILDS = {"donovan": os.environ["DON"], "huitzil": os.environ["HUI"],
          "pyron": os.environ["PYR"], "stock": os.environ["STOCK"],
          "merged": os.environ["MERGED"]}

images, seen = {}, 0
for name, bd in BUILDS.items():
    p = Path(bd) / "verify_data.bin"
    if not p.exists():
        notes.append(f"2: {name}: SKIP — no {p}")
        continue
    seen += 1
    img = p.read_bytes()
    images[name] = img
    got = {i for i in range(NROWS) if rows(img)[i] != VAN[i]}
    if got != FROZEN[name]:
        extra = sorted(got - FROZEN[name])
        gone = sorted(FROZEN[name] - got)
        fails.append(f"2: {name} ({bd}): repointed rows differ from frozen — "
                     f"UNEXPECTED {[hex(i) for i in extra]} "
                     f"MISSING {[hex(i) for i in gone]}")
    else:
        notes.append(f"2: {name}: {len(got)} rows repointed, exactly the "
                     f"frozen set")
if seen == 0:
    print("SKIP: no build dir carries verify_data.bin "
          "(set DON/HUI/PYR/STOCK/MERGED)")
    sys.exit(0)

# ── 3. THE MIRROR-VICTIM FIX IS SCOPED TO THE BASE-SLOT TRACK ────────────────
# REWRITTEN 14z-144. Until then this section asserted the 14z-64 fix rides row
# 0x13 on EVERY track, which was the defect: `fixes` applied unconditionally,
# so on a WIDE build Donovan throwing JEDAH (victim 0x0F, restored and
# reachable) was positioned by the DONOVAN-victim sub-block. donovan.toml now
# carries `fixes_variant = ""`, so the rewrite is base-slot only.
#
# THE INVARIANT IS TRACK-DEPENDENT, and asserting BOTH sides is what makes this
# a discriminator rather than a constant read:
#   base slot  (stock)  — Donovan OCCUPIES 0x0F, victim 0x0F IS him, so his
#                         block must carry the FIXED word 0x0d88.
#   variant    (WIDE)   — 0x0F is JEDAH, so the placed blob must carry vs2's
#                         OWN word 0x0b30, i.e. the fix must NOT be there.
# The two tracks therefore hold DIFFERENT values at the same offset of the same
# structure. A build that lost the gating reads the same value on both and
# fails here; the pre-fix merged image (merged-m17) reads 0x0d88 on the variant
# track and fails too. Measured 14z-144.
variant_seen = {}
for name in ("donovan", "merged"):
    img = images.get(name)
    if img is None:
        continue
    tgt = rows(img)[0x13]
    w = struct.unpack_from(">H", img, tgt + FIX_OFF)[0]
    variant_seen[name] = w
    if w != FIX_OLD:
        fails.append(f"3: {name}: row 0x13 -> {tgt:#010x} carries {w:#06x} at "
                     f"+{FIX_OFF:#x}, expected vs2's OWN {FIX_OLD:#06x}"
                     + (" — this is the BASE-SLOT fix leaking onto a variant "
                        "track, i.e. Donovan throwing Jedah would use "
                        "Donovan-victim keyframes (the 14z-143 defect)"
                        if w == FIX_NEW else ""))
    else:
        notes.append(f"3: {name}: row 0x13 -> {tgt:#010x}, +{FIX_OFF:#x} = "
                     f"{FIX_OLD:#06x} — vs2's own Jedah-victim sub-block, so "
                     f"the base-slot fix is correctly NOT applied here")

base = images.get("stock")
if base is not None:
    tgt = rows(base)[0x0F]
    w = struct.unpack_from(">H", base, tgt + FIX_OFF)[0]
    if w != FIX_NEW:
        fails.append(f"3: stock: row 0x0f -> {tgt:#010x} carries {w:#06x} at "
                     f"+{FIX_OFF:#x}, expected the 14z-64 fix {FIX_NEW:#06x} — "
                     f"the base-slot track LOST the mirror-victim fix, where "
                     f"victim 0x0f genuinely IS Donovan")
    else:
        notes.append(f"3: stock: row 0x0f -> {tgt:#010x}, +{FIX_OFF:#x} = "
                     f"{FIX_NEW:#06x} (the 14z-64 fix, correctly still applied "
                     f"on the base-slot track)")
    # THE DISCRIMINATOR ([VSP-22]): the two tracks must DISAGREE. If they read
    # the same word the gating is not doing anything and both checks above
    # would pass on a build that had simply dropped `fixes` entirely.
    same = [n for n, v in variant_seen.items() if v == w]
    if same:
        fails.append(f"3: CONTROL DEAD — {same} read the same word as the "
                     f"base-slot track ({w:#06x}); the two checks above cannot "
                     f"be shown to discriminate the scoping")
    elif variant_seen:
        notes.append(f"3: discriminator: base slot {w:#06x} vs variant "
                     f"{sorted(set(variant_seen.values()))[0]:#06x} — the "
                     f"tracks disagree, so the gating is measurably live")

# ── 4. MUST-FIRE CONTROLS ────────────────────────────────────────────────────
ctl_name = next(iter(images))
ctl = bytearray(images[ctl_name])
unclaimed = sorted(set(range(NROWS)) - FROZEN[ctl_name])
if not unclaimed:
    fails.append("4: no unclaimed row available for the control")
else:
    r = unclaimed[0]
    struct.pack_into(">I", ctl, BASE + r * 4, VAN[r] ^ 0x10)
    got = {i for i in range(NROWS)
           if struct.unpack_from(">I", ctl, BASE + i * 4)[0] != VAN[i]}
    if got == FROZEN[ctl_name]:
        fails.append(f"4: CONTROL DID NOT FIRE — perturbing unclaimed row "
                     f"{r:#04x} on {ctl_name} left the inventory unchanged")
    else:
        notes.append(f"4: control fired — perturbing unclaimed row {r:#04x} on "
                     f"{ctl_name} is caught by section 2")

# REWRITTEN 14z-144 with the invariant. The old control wrote FIX_OLD into a
# copy and then asserted the word was not FIX_NEW — trivially true, because it
# had just written it, and it never exercised section 3's predicate at all. It
# is now TWO controls that run the REAL comparison on a perturbed image, one
# per side of the track-dependent invariant.
if "donovan" in images:
    ctl2 = bytearray(images["donovan"])
    t = rows(images["donovan"])[0x13]
    struct.pack_into(">H", ctl2, t + FIX_OFF, FIX_NEW)     # the 14z-143 defect
    w = struct.unpack_from(">H", ctl2, t + FIX_OFF)[0]
    if w != FIX_OLD:
        notes.append(f"4: control fired — planting the base-slot fix "
                     f"{FIX_NEW:#06x} on the VARIANT track is caught by "
                     f"section 3 (this is exactly the 14z-143 defect)")
    else:
        fails.append("4: CONTROL DID NOT FIRE — the variant-track check does "
                     "not reject the base-slot word")

if "stock" in images:
    ctl3 = bytearray(images["stock"])
    t = rows(images["stock"])[0x0F]
    struct.pack_into(">H", ctl3, t + FIX_OFF, FIX_OLD)     # the fix gone
    w = struct.unpack_from(">H", ctl3, t + FIX_OFF)[0]
    if w != FIX_NEW:
        notes.append(f"4: control fired — removing the 14z-64 fix from the "
                     f"BASE-SLOT track is caught by section 3 (the scoping "
                     f"must not disarm both tracks)")
    else:
        fails.append("4: CONTROL DID NOT FIRE — the base-slot check does not "
                     "reject the unfixed word")

for n in notes:
    print("  " + n)
if fails:
    print()
    for f in fails:
        print("FAIL: " + f)
    print(f"\nFAIL: test_capture_kf_ownership ({len(fails)} failure(s))")
    sys.exit(1)
print(f"\nPASS: test_capture_kf_ownership ({seen} build(s) checked)")
PY
