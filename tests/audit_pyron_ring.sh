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
# THE FIX (open, STATE 14z-85 decisions-pending): per-tenant curated
# record arrays (pyr_sfx_records @row 0x11, hui_sfx_records @row 0x10)
# following the don_sfx_records keep/zero policy.
#
# VERDICT until that fix ships: the merged-vs-solo id-set DIFF must
# equal the FROZEN KNOWN-OPEN inventory below, per replay — any NEW id
# (or a solo id going missing on merged) is DRIFT and fails. When the
# sfx-records fix lands, re-freeze both sets to empty.
# Housekeeping ids 0x0000/0xFFFF excluded (test_don_sound precedent).
#
# pyron/71 NEEDS the meter pokes or the EX never fires (replay header).
#
# Usage: ROMDIR=... tests/audit_pyron_ring.sh [merged builddir] [solo builddir]
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MERGED="${1:-build/m3b_merged}"
SOLO="${2:-build/pyron21}"
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
import collections, re, sys
W = sys.argv[1]
def inv(path):
    ids = collections.Counter()
    seen_end = False
    for ln in open(path):
        m = re.match(r"f(\d+) id ([0-9a-f]{4}) pc", ln)
        if m and int(m.group(2), 16) not in (0, 0xFFFF):
            ids[int(m.group(2), 16)] += 1
        elif ln.startswith("END"):
            seen_end = True
    return ids, seen_end
errs = []
for name in ("cosmo", "mash"):
    m, m_end = inv(f"{W}/{name}_merged/ring.txt")
    s, s_end = inv(f"{W}/{name}_solo/ring.txt")
    if not (m_end and s_end):
        errs.append(f"{name}: a tap run did not complete (no END line)")
        continue
    if len(s) < 10:
        errs.append(f"{name}: solo inventory only {len(s)} ids — dead rig "
                    "(verdict vacuous)")
        continue
    # FROZEN KNOWN-OPEN (14z-85, the per-node sfx helper class — header):
    # the measured merged-only id set per replay. Re-freeze to empty when
    # the per-tenant sfx-records fix ships.
    KNOWN_OPEN = {"cosmo": {0x110},
                  "mash":  {0x110, 0x111, 0x112, 0x31B, 0x729}}[name]
    extra = set(m) - set(s)
    missing = set(s) - set(m)
    if extra != KNOWN_OPEN:
        new = sorted(hex(i) for i in extra - KNOWN_OPEN)
        gone = sorted(hex(i) for i in KNOWN_OPEN - extra)
        errs.append(f"{name}: merged-only id set drifted from the frozen "
                    f"known-open inventory (new: {new or '-'}; no longer "
                    f"seen: {gone or '-'}) — re-measure, never absorb")
    if missing:
        errs.append(f"{name}: solo id(s) "
                    f"{sorted(hex(i) for i in missing)} MISSING on merged "
                    "— a family path stopped sounding")
    if extra == KNOWN_OPEN and not missing:
        print(f"  ok: {name} — merged/solo diff matches the frozen "
              f"known-open inventory ({sorted(hex(i) for i in KNOWN_OPEN)})")
for e in errs:
    print("FAIL:", e)
sys.exit(1 if errs else 0)
PY

[ "$fail" = 0 ] || { echo "FAIL: pyron ring audit"; exit 1; }
echo "PASS: merged-vs-solo ring diff matches the frozen known-open"
echo "      inventory (the per-node sfx helper class, STATE 14z-85) —"
echo "      no drift, no missing solo ids"
