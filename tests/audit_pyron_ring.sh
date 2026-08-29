#!/bin/sh
# audit_pyron_ring.sh — Pyron's merged-vs-solo sound-ring inventory,
# frozen (14z-85). On-demand, ~10 min (2 replays x merged+solo = 4 runs).
#
# WHAT 14z-85 MEASURED (the owner-tag fix's own before/after): the ring
# inventory is IDENTICAL before and after the owner tag — the music
# retrigger is NOT the 64-75 dispatch defect. Root cause, measured the
# same session: donovan's [[sound_table]] row UN-STUBS the engine's
# per-node sfx helper (vs2 0x5122 -> vsavj 0x4CE2) engine-wide, but
# repoints only HIS per-char ptr row (0x0BF41A + 4*char: row 0x13). On
# the MERGED build pyron's nodes fire through the vanilla row 0x11
# pointer — wrong records, ids incl. vsavj MUSIC track 0x729. Solo
# pyron has no donovan row, the helper stays stubbed, nothing fires.
# THE FIX SHIPPED 14z-85b (maintainer-ruled option (a)): pyr_sfx_records
# @row 0x11 (+ hui_sfx_records @row 0x10), the don_sfx_records keep/zero
# policy — docs/project/tables/sfx_records.md. Measured on the rebuilt
# merged build vs pyron-m4: the diff is EMPTY — every known-open id
# (incl. music 0x729) gone, no solo id missing.
#
# VERDICT: the merged-vs-solo id-set DIFF must equal the FROZEN
# inventory below (now EMPTY), per replay — any NEW id (or a solo id
# going missing on merged) fails.
# Housekeeping ids 0x0000/0xFFFF excluded (test_don_sound precedent).
#
# pyron/71 NEEDS the meter pokes or the EX never fires (replay header).
#
# Usage: ROMDIR=... tests/audit_pyron_ring.sh [merged builddir] [solo builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
# RE-POINTED 14z-94 (GitHub #94). Both defaults had rotted: build/m3b_merged
# and build/pyron22 are pre-WIDE-v1.1 sets (19 members, no vsw.z01/z02), so
# this audit could not run at all — it died before measuring anything. Build
# dirs are untracked by design (rule 7), which makes every hardcoded default
# a pointer with a shelf life; tests/test_build_ref_rot.sh is the standing
# check that now catches this class instead of a person tripping over it.
# GREEN AGAIN 14z-95 (GitHub #98) — and the inventory was never re-frozen.
# The drift this reported after 14z-94 re-pointed the defaults was NOT a
# sound defect: `mash` diverges at f4741 with merged one frame AHEAD of solo,
# after which a mash rig is playing two different fights, so the whole-run
# id-SET comparison was invalid rather than failing. The comparison is now
# event-stream-with-a-frozen-onset; see the block below for the measurements.
MERGED="${1:-build/m3b_merged21}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
SOLO="${2:-build/pyron36}"    # pyron-m15 (14z-105; was pyron-m13, the shipping solo (carries  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
                              # pyr_sfx_records, as pyron-m4 did at 14z-85b)
[ -f "$MERGED/rompath/vsavjw.zip" ] || { echo "SKIP: no $MERGED"; exit 0; }
[ -f "$SOLO/rompath/vsavjw.zip" ] || { echo "SKIP: no $SOLO"; exit 0; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

PK="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;3000:ff8509:03;3020:ff8509:03"
for leg in cosmo:pyron/71_pyron_cosmo:5200 mash:pyron/70_pyron_mash:8400; do
    name="${leg%%:*}"; rest="${leg#*:}"; rp="${rest%:*}"; fr="${rest##*:}"
    for bd in merged:"$MERGED" solo:"$SOLO"; do
        side="${bd%%:*}"; build="${bd#*:}"
        d="$W/${name}_$side"; mkdir -p "$d"
        ( cd "$d" && MAME_ROMPATH="$REPO/$build/rompath;$ROMDIR" \
          MAME_SANDBOX="$d/sb" POKES="$PK" \
          REPLAY="$REPO/tests/replays/$rp.rpl" FRAMES="$fr" \
          TRACE_OUT="$d/ring.txt" \
          "$REPO/tools/run_mame.sh" vsavjw \
          -autoboot_script "$REPO/tests/lua/ring_tap.lua" > "$d/out" 2>&1 ) &
    done
done
wait

python3 - "$W" <<'PY' || fail=1
import re, sys
W = sys.argv[1]

# ── WHY THIS COMPARES EVENT STREAMS AND NOT WHOLE-RUN ID SETS ────────────────
# GitHub #98, resolved 14z-95. The set comparison this used to do reported
#   "solo id(s) 0x51d, 0x9e, 0xf5 MISSING on merged — a family path stopped
#    sounding"
# which reads as a merge regression. It is not one. MEASURED:
#   - `cosmo` runs in PERFECT LOCKSTEP: 112 of 112 events identical, frame for
#     frame, merged vs solo. So the instrument and the comparison are sound.
#   - `mash` is in lockstep for 136 events and then DIVERGES AT f4741, where
#     merged fires id 010c ONE FRAME EARLIER than solo, and never re-syncs.
#     Everything after that point is TWO DIFFERENT FIGHTS on a mash rig, so a
#     whole-run id-set diff there compares things that are not comparable.
#     The three "missing" ids and five "gained" ids are all downstream of it.
#   - The divergence is DETERMINISTIC: three merged runs are event-identical.
#   - It is not a build-generation artifact either: the SOLO is id-identical
#     between pyron-m9 and pyron-m10, so nothing moved on that side.
# A one-frame lead on TENANT CONTENT between merged and solo is the expected
# class — merged carries three tenants' hooks — and audit_merged_legacy leg (b)
# already treats merged-vs-solo tenant content as "first-divergence floor +
# classified report" rather than bit-identity. What was wrong here was the
# VOCABULARY, not the builds.
#
# So: compare the event streams up to the FROZEN divergence onset, and freeze
# the onset itself. An onset moving LATER is fine (more agreement); an onset
# moving EARLIER is a FAILURE — the same discipline test_dualtrack uses, and
# the reason this is strictly stronger than either re-freezing the drifted
# inventory (which absorbs) or the old set compare (which cries wolf).
import os
ONSET = {"cosmo": None,   # None = must agree for the WHOLE run
         "mash":  4741}   # frozen 14z-95, merged one frame ahead of solo
# MUST-FIRE CONTROL. "an onset moving EARLIER is a FAILURE" is this gate's
# load-bearing assertion, and a frozen constant that happens to match is
# indistinguishable from a comparison that cannot fail. PYRON_RING_ONSET
# overrides the mash constant so the control can demand a RED; no shipped
# caller sets it.
if os.environ.get("PYRON_RING_ONSET"):
    ONSET["mash"] = int(os.environ["PYRON_RING_ONSET"])

def events(path):
    out, end = [], False
    for ln in open(path):
        m = re.match(r"f(\d+) id ([0-9a-f]{4}) pc", ln)
        if m and int(m.group(2), 16) not in (0, 0xFFFF):
            out.append((int(m.group(1)), m.group(2)))
        elif ln.startswith("END"):
            end = True
    return out, end

errs = []
for name in ("cosmo", "mash"):
    m, m_end = events(f"{W}/{name}_merged/ring.txt")
    s, s_end = events(f"{W}/{name}_solo/ring.txt")
    if not (m_end and s_end):
        errs.append(f"{name}: a tap run did not complete (no END line)")
        continue
    if len(s) < 10:
        errs.append(f"{name}: solo stream only {len(s)} events — dead rig "
                    "(verdict vacuous)")
        continue
    # how far do the two builds agree, event for event?
    agree = 0
    for a, b in zip(m, s):
        if a != b:
            break
        agree += 1
    want = ONSET[name]
    if want is None:
        if agree != len(m) or len(m) != len(s):
            f = m[agree] if agree < len(m) else ("-", "-")
            g = s[agree] if agree < len(s) else ("-", "-")
            errs.append(f"{name}: expected WHOLE-RUN agreement, diverged at "
                        f"event {agree} (merged f{f[0]} id {f[1]} | solo "
                        f"f{g[0]} id {g[1]}) — merged and solo no longer "
                        f"play this rig identically")
        else:
            print(f"  ok: {name} — merged and solo agree on all {agree} "
                  f"ring events, frame for frame")
        continue
    if agree >= len(m) or agree >= len(s):
        print(f"  ok: {name} — agreement now runs the WHOLE stream "
              f"({agree} events), beyond the frozen onset f{want}. That is "
              f"an improvement; re-freeze ONSET to None deliberately.")
        continue
    onset = m[agree][0]
    if onset < want:
        errs.append(f"{name}: divergence onset moved EARLIER — f{onset}, "
                    f"frozen f{want}. Merged and solo stop agreeing sooner "
                    f"than measured; root-cause it, do not re-freeze "
                    f"(CLAUDE.md §4 standing watch)")
    elif onset > want:
        print(f"  note: {name} — onset f{onset} is LATER than the frozen "
              f"f{want} (more agreement, not less)")
    else:
        print(f"  ok: {name} — {agree} events identical, divergence at the "
              f"frozen onset f{onset} (merged one frame ahead)")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: pyron ring audit"; exit 1; }
echo "PASS: merged/solo ring streams agree to their frozen onsets"
echo "      (cosmo whole-run; mash to f4741, where merged runs one frame"
echo "      ahead — GitHub #98, measured 14z-95)"
