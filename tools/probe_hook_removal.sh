#!/bin/sh
# probe_hook_removal.sh — CAUSAL attribution for a legacy-cycle regression:
# rebuild a tenant with named hooks REMOVED and re-measure a legacy replay
# against the vanilla masked basis.
#
# WHY (14z-89). Two promoted legacy replays diverged from vanilla and never
# re-converged — 38_victor_p1_vsavj (donovan-m5) and 24_don_winmash (all
# three sets). Both are "one main-loop iteration lost/gained at a heavy
# frame", and both reach GAMEPLAY state (HP, positions) because replay
# inputs are scheduled by FRAME: once the loop is one logic step out, every
# later input lands on a different step. Attribution by dump diff got as far
# as "extra cycles somewhere" and no further — the sprite lists are
# byte-identical at the onset and the palette fade was a wrong guess. What
# actually names the culprit is REMOVING a hook and re-running: the probe is
# not shippable (the tenant loses a feature) but the LEGACY replay does not
# care, because it never touches the tenant.
#
# MEASURED WITH IT (14z-89, donovan-m5, both causes independent):
#   38_victor_p1_vsavj <- site_thunk fixture_row0f_override_bank0/1.
#       Those two thunks replace `movea.l #0x3B5940,a0` at the venue
#       fixture-load sites 0x01C586/0x01C59A with two `cmpi.b #id,abs.l`
#       + branches. Their own manifest comment says the sites are "shared
#       by match intro AND attract — both measured", i.e. LEGACY runs them
#       on every venue load, and the match-intro frame already sits at the
#       VBL edge. Removing the pair: the replay lands on the ratified 2P
#       shape (composite 829 889-2091), 2909 identical frames after.
#   24_don_winmash <- the two [[obj_hook]] type-dispatch table extensions
#       (per-object dispatch, hot every frame). Removing them: re-converges
#       with 5787 identical frames after.
#   BOTH removed: 38 -> `window 889 2091`, 24 -> `composite 12313,12733
#       889-2091` — i.e. the two causes are COMPLETE for this build's two
#       failures, and the resulting shapes are CLEANER than the frozen
#       classes (38 loses its 829 flicker frame too), so any fix re-freezes.
# CONTROL (run it): the unmodified build must still FAIL the same replay.
# An attribution that does not reproduce the failure on the reference build
# is measuring something else.
#
# Usage: ROMDIR=... [MAME_BIN=...] [OUT=build/probe_<tag>] \
#          tools/probe_hook_removal.sh <tag> <replay-name> <hook-name>...
#   hook-name: a [[site_thunk]] `name`, or the literal `obj_hook` to drop
#   every [[obj_hook]] block. ~4 min per build + ~1 min per run.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
TAG="${1:?usage: probe_hook_removal.sh <tag> <replay> <hook>...}"
RPL="${2:?replay name}"; shift 2
[ $# -ge 1 ] || { echo "no hook names given"; exit 2; }
SRC="${TENANT_MANIFEST:-build/manifest/donovan.toml}"
OUT="${OUT:-build/probe_$TAG}"
MAN="build/manifest/probe_$TAG.toml"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

NAMES="$*" SRC="$SRC" python3 - "$MAN" <<'PY'
import os, sys
drop = set(os.environ["NAMES"].split())
lines = open(os.environ["SRC"]).read().split("\n")
out, i, removed = [], 0, []
while i < len(lines):
    if lines[i].strip() == "[[obj_hook]]" and "obj_hook" in drop:
        removed.append("obj_hook")
        while i < len(lines) and lines[i].strip() != "":
            i += 1
        continue
    if lines[i].strip() == "[[site_thunk]]":
        k, name = i + 1, None
        while k < len(lines) and not (lines[k].startswith("[[") or
              (lines[k].startswith("[") and lines[k].rstrip().endswith("]"))):
            if lines[k].startswith("name = ") and name is None:
                name = lines[k].split('"')[1]
            k += 1
        if name in drop:
            removed.append(name); i = k; continue
    out.append(lines[i]); i += 1
open(sys.argv[1], "w").write("\n".join(out))
missing = drop - set(removed)
if missing:
    sys.exit("NOT FOUND in the manifest: " + ", ".join(sorted(missing)))
print("  removed: " + ", ".join(removed))
PY

TENANT_MANIFEST="$MAN" KEY_SET=vsavj \
GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
    tools/build_donovan.sh 6 "$OUT" > "$W/build.log" 2>&1 \
    || { echo "  BUILD FAILED:"; tail -5 "$W/build.log"; exit 1; }
echo "  built $OUT ($(sed -n 's/^build fingerprint: //p' "$W/build.log"))"
MASK="$(cat tests/expected/donovan-m5/mask)"
MASK_RANGES="$MASK" MAME_ROMPATH="$PWD/$OUT/rompath;$ROMDIR" \
    tools/run_replay_mame.sh vsavjw "tests/replays/$RPL.rpl" "$W/$RPL.log" "$W/sb" \
    >"$W/run.log" 2>&1 || { echo "  RUN FAILED"; tail -5 "$W/run.log"; exit 1; }
BASE="tests/expected/vsavj/masked-v2/logs/$RPL.log"
[ -f "$BASE" ] || { echo "  no vanilla basis log for $RPL"; exit 1; }
python3 tools/describe_masked_shape.py "$BASE" "$W/$RPL.log" | sed 's/^/  /'
