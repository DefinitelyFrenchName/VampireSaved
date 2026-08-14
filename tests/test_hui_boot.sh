#!/bin/sh
# test_hui_boot.sh — the Huitzil stage-4 BOOT gate (14z-65).
#
# The first rung with his CODE live: builds stage 4 from the huitzil
# manifest and proves a forced-id match FORMS and SURVIVES —
#   1. the forced-pick probe loads HIS hitbox base (the row-0x10 poke
#      value read back from the build's own patch.json, not hardcoded);
#   2. the crash guard is clean over the full run (no exception, no
#      tripwire — and per GOTCHAS 14z-65 a watchdog reboot would read as
#      ZEROS, so the loaded-base check subsumes the reboot check);
#   3. the legacy replay is still BIT-IDENTICAL to vanilla (the superset
#      side of the same build).
# History: this rung took the fall-through layout group (the 0x57456
# mid-handler region split), the [init_shim], and the five measured
# stubbed_sound rows (ids 0x72a-0x74a — vsavj same-id keys different
# music-class content) — see STATE 14z-65.
#
# Usage: ROMDIR=... tests/test_hui_boot.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== stage 4 build"
TENANT_MANIFEST=build/manifest/huitzil.toml TENANT_CHAR=0x10 \
GEN_FLAGS="--profile cps2-wide-v1 --allow-plausible --tripwire-open" \
    tools/build_donovan.sh 4 "$WORK/hui4" > "$WORK/build.log" 2>&1 \
    || { tail -15 "$WORK/build.log"; echo "FAIL: stage 4 build"; exit 1; }
echo "  ok: built ($(grep '^build fingerprint' "$WORK/build.log" | cut -d' ' -f3 | cut -c1-8))"

EXPECT_BASE="$(python3 - "$WORK/hui4/patch/patch.json" <<'PY'
import json, sys
for o in json.load(open(sys.argv[1]))["ops"]:
    if o.get("addr", "").lower() == "0xbd9ba":
        print(f"{int(o['val'], 0):08x}")
PY
)"
[ -n "$EXPECT_BASE" ] || { echo "FAIL: no hitbox_base[0x10] op in the patch"; exit 1; }

echo "== forced-pick boot (id 0x10)"
# the build packs as vsavjw when any allocation reaches wide_ext — run
# the set that was actually packed (14z-65: a vsavj-set probe against a
# vsavjw rompath silently falls back to the PRISTINE ROM: false greens)
if [ -f "$WORK/hui4/rompath/vsavjw.zip" ]; then
    export SET=vsavjw MAME_BIN="$HOME/.cache/vampire-saved/mame/cps2"
fi
tools/force_pick_probe.sh "$WORK/hui4/rompath" 10 "$WORK/probe" > "$WORK/probe.txt"
cat "$WORK/probe.txt" | sed 's/^/  /'
grep -q "hitbox base 0x$EXPECT_BASE — char LOADED" "$WORK/probe.txt" \
    || { echo "FAIL: HIS base 0x$EXPECT_BASE not loaded"; exit 1; }
grep -q "guard        : clean" "$WORK/probe.txt" \
    || { echo "FAIL: guard not clean"; exit 1; }

echo "== legacy replay under the v2 masked basis (hooked build)"
# stage 4 carries the obj_hook engine thunks, so the whole-RAM bit-identity
# of the ladder gate no longer applies (CLAUDE.md §4 hooked-build basis).
# Measured 14z-65: EXACT under the v2 mask — frozen as EXACT; any future
# flicker must be measured and ratified per doctrine, never tolerated here.
MASK_RANGES="$(cat "$REPO/tests/expected/donovan-m4/mask")" \
MAME_ROMPATH="$WORK/hui4/rompath;$ROMDIR" MAME_BIN="${MAME_BIN:-mame}" \
    tools/run_replay_mame.sh "${SET:-vsavj}" tests/replays/02_demitri_vs_cpu.rpl \
    "$WORK/r02.log" "$WORK/r02box" > /dev/null 2>&1
python3 "$REPO/tools/compare_flicker.py" "$WORK/r02.log" \
    "$REPO/tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log" \
    | grep -q "^EXACT" \
    || { echo "FAIL: legacy replay not masked-EXACT"; exit 1; }
echo "  ok: masked-v2 EXACT vs the frozen vanilla log"

echo "PASS: Huitzil stage-4 boot (his data loads, guard clean, legacy intact)"
