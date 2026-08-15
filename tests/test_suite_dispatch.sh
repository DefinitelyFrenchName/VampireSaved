#!/bin/sh
# test_suite_dispatch.sh — ground truth for the auto-detecting runner's
# dispatch pieces (no emulator needed; the emulator-side behaviors they gate
# are proven by test_m2_repoint.sh and the suite itself):
#   1. build_fingerprint: vanilla rompath -> 'vsavj'; a patched build ->
#      loud UNREGISTERED failure (exit 2).
#   2. check_diverge verdicts on synthetic logs: divergence at exactly the
#      expected frame PASSes; early divergence, no divergence, and a missing
#      base log all FAIL.
#
# Usage: ROMDIR=... tests/test_suite_dispatch.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# --- 1. fingerprint dispatch -------------------------------------------------
got=$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR")
if [ "$got" = "vsavj" ]; then
    echo "  ok: vanilla rompath -> expectation set 'vsavj'"
else
    echo "FAIL: vanilla fingerprint mapped to '$got'"; fail=1
fi

printf '{"ops":[{"op":"poke16","addr":"0xBF800","val":"0x4AFC"}]}' > "$WORK/p.json"
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/prg" --patch "$WORK/p.json" > /dev/null
ROMDIR="$ROMDIR" "$REPO/tools/pack_build.sh" "$WORK/prg" "$WORK/rompath" > /dev/null
rc=0
python3 "$REPO/tools/build_fingerprint.py" "$WORK/rompath;$ROMDIR" > /dev/null 2>&1 || rc=$?
if [ "$rc" = "2" ]; then
    echo "  ok: unregistered patched build fails loudly (exit 2)"
else
    echo "FAIL: unregistered build rc=$rc (expected 2)"; fail=1
fi

# --- 2. check_diverge verdicts on synthetic logs -----------------------------
EXPROOT="$WORK/expected"
mkdir -p "$EXPROOT/base/logs"
python3 - "$EXPROOT" "$WORK" <<'PY'
import sys
exproot, work = sys.argv[1], sys.argv[2]
base = [f"{i} {i:016x}" for i in range(1, 101)]
open(f"{exproot}/base/logs/case.log", "w").write("\n".join(base + ["END 100"]))
exact = list(base); exact[41] = "42 deadbeefdeadbeef"        # diverges at 42
open(f"{work}/exact.log", "w").write("\n".join(exact + ["END 100"]))
early = list(base); early[9] = "10 deadbeefdeadbeef"         # diverges at 10
open(f"{work}/early.log", "w").write("\n".join(early + ["END 100"]))
open(f"{work}/same.log", "w").write("\n".join(base + ["END 100"]))
PY
printf 'base 42' > "$WORK/case.diverge"

cd_run() { python3 "$REPO/tools/check_diverge.py" "$1" "$WORK/case.diverge" "$EXPROOT" > /dev/null 2>&1; }

if cd_run "$WORK/exact.log"; then
    echo "  ok: divergence at exactly 42 -> PASS"
else
    echo "FAIL: exact-divergence case rejected"; fail=1
fi
if cd_run "$WORK/early.log"; then
    echo "FAIL: early divergence accepted"; fail=1
else
    echo "  ok: early divergence -> FAIL"
fi
if cd_run "$WORK/same.log"; then
    echo "FAIL: no-divergence accepted"; fail=1
else
    echo "  ok: no divergence -> FAIL"
fi
printf 'nosuchset 42' > "$WORK/case.diverge"
if cd_run "$WORK/exact.log"; then
    echo "FAIL: missing base log accepted"; fail=1
else
    echo "  ok: missing base log -> FAIL"
fi

# --- 3. the runner knows every expectation kind it can meet ------------------
# A kind the runner does not implement is silently useless — and a `.pending`
# that read as a skip would be the exact "unvalidated looks green" failure
# the WIDE freeze exists to avoid (14z-61). Cheap structural check: every
# kind used anywhere under tests/expected/ must be handled in run_suite.sh.
echo "  -- expectation kinds"
# Only files whose stem is an actual replay name are expectations; PNGs,
# frozen logs and stray .DS_Store are data, not kinds.
kinds=$(for f in "$REPO"/tests/expected/*/*.*; do
            [ -f "$f" ] || continue
            b="$(basename "$f")"; stem="${b%.*}"; ext="${b##*.}"
            [ -f "$REPO/tests/replays/$stem.rpl" ] || continue
            [ "$ext" = "sha1" ] && continue
            echo "$ext"
        done | sort -u)
# 14z-90 (issue #7): the check used to demand that EVERY kind be handled by
# run_suite.sh. That is wrong for MARKER kinds. `.legacy-exempt` records the
# maintainer's 61/62 ruling and is read by tests/audit_legacy_pairings.sh; the
# replays it annotates carry a `.sha1` beside it and ARE dispatched normally.
# So the gate was a false RED. The fix is not to loosen it — "handled by some
# script somewhere" would green-light a genuinely undispatched kind — but to
# name the OWNER per kind and assert that owner actually reads it. A kind
# missing from this table is a hard failure, so a new marker cannot appear
# unannounced, and an orphaned marker whose owner was deleted now goes red
# (which the old check could not see).
#
#   <kind>:<owner script>:<how the owner is reached>
#     battery  = must be invoked from tests/run_battery_m2.sh
#     toplevel = run directly by the operator; HANDOFF.md documents it.
#                Declared, not assumed: an owner may not silently claim
#                coverage it does not have.
KIND_OWNERS="masked:tests/run_suite.sh:toplevel
pending:tests/run_suite.sh:toplevel
skip:tests/run_suite.sh:toplevel
diverge:tests/run_suite.sh:toplevel
legacy-exempt:tests/audit_legacy_pairings.sh:toplevel"

for k in $kinds; do
    row=$(echo "$KIND_OWNERS" | grep "^$k:" || true)
    if [ -z "$row" ]; then
        echo "FAIL: '.$k' expectations exist but the kind is not in the owner table"
        fail=1
        continue
    fi
    owner=$(echo "$row" | cut -d: -f2)
    chain=$(echo "$row" | cut -d: -f3)
    if [ ! -f "$REPO/$owner" ]; then
        echo "FAIL: '.$k' names owner $owner, which does not exist"
        fail=1
    elif grep -q "\.$k\"" "$REPO/$owner"; then
        echo "  ok: '.$k' expectations are read by $owner ($chain)"
    else
        echo "FAIL: '.$k' names owner $owner, but that script never reads the kind"
        fail=1
    fi
    if [ "$chain" = battery ] \
       && ! grep -q "$(basename "$owner")" "$REPO/tests/run_battery_m2.sh"; then
        echo "FAIL: '.$k' owner $owner claims to run in the battery, but"
        echo "      tests/run_battery_m2.sh never invokes it"
        fail=1
    fi
done

# And every .masked CLASS in use must be a class the runner implements.
classes=$(cat "$REPO"/tests/expected/*/*.masked 2>/dev/null | awk '{print $1}' | sort -u)
for c in $classes; do
    if grep -q "^        $c)" "$REPO/tests/run_suite.sh"; then
        echo "  ok: masked class '$c' is implemented"
    else
        echo "FAIL: masked class '$c' is used in an expectation but not implemented"
        fail=1
    fi
done

[ "$fail" = 0 ] && echo "PASS: suite dispatch verdicts validated" \
    || { echo "SUITE RED"; exit 1; }
