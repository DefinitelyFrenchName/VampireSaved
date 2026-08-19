#!/bin/sh
# test_m2a_target_resolution.sh — the M2 battery resolves its legacy target
# from the BUILD, and an unregistered image stops it. Needs ROMDIR, no
# emulator, ~10 s.
#
# The companion to tests/test_m2a_target_policy.sh, which reads the source.
# This one runs the resolver: policy that is only asserted textually is
# policy nobody has executed (GitHub #30's lesson, one level down).
#
# WHY IT MATTERS (GitHub #96, maintainer-ruled option (a) 2026-08-19). The
# battery asserts "the pipeline, built fresh, reproduces the CURRENT freeze".
# The whole weight of that sentence rests on one behaviour: when the fresh
# build is NOT the frozen one, the gate must say so LOUDLY rather than fall
# back on a name. Before 14z-97 it could not — the target was the literal
# `tests/expected/donovan-m2c`, so any build at all was judged against a
# 2026-08-02 expectation, which is exactly how #96's two red constants came
# to look like build defects.
#
# THE UNREGISTERED BUILD IS SYNTHESISED, not taken from build/. Pointing this
# at a real superseded build dir would work today (build/m5_stock, 6c93cfa8,
# is unregistered and reproduces the message) and would rot the moment that
# dir is pruned — the reference-rot class that has now bitten four gates
# (GitHub #94). A one-instruction poke is enough to be "not any frozen build".
#
# IT LIVES IN ci_static AND MUST NEVER BOOT AN EMULATOR. run_all_static's
# classifier is transitive and will read this gate as emulator-reaching,
# because it sources m2a_common.sh — which does call run_replay_mame.sh. That
# is precisely how test_m2a_stage4_code once ran for 208 s inside a chain
# advertised as emulator-free (#96's own note). The property is made
# STRUCTURAL below rather than left to the fact that today's code paths
# happen to stop early: m2a_run_masked is replaced with a loud failure, so if
# a future edit makes this gate reach a replay it fails immediately instead
# of quietly costing the cheap tier four minutes. Measured runtime: ~1 s.
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

. "$REPO/tests/lib/m2a_common.sh"

# The structural guard described above. Every subshell below re-sources the
# lib, so each one redefines this too.
m2a_run_masked() {
    echo "FAIL: this gate ran a replay ($2). It is registered in ci_static," >&2
    echo "      the emulator-free tier — it must only exercise RESOLUTION." >&2
    exit 1
}

echo "== 1. a REGISTERED image resolves to its expectation set =="
got=$(m2a_masked_target "$ROMDIR" || true)
if [ "$got" = "vsavj" ]; then
    echo "  ok: the pristine reference resolves to 'vsavj'"
else
    echo "FAIL: pristine ROMDIR resolved to '$got' (expected 'vsavj')"; fail=1
fi

echo "== 2. an UNREGISTERED image stops the gate, naming rule 6 =="
printf '{"ops":[{"op":"poke16","addr":"0xBF800","val":"0x4AFC"}]}' > "$WORK/p.json"
python3 "$REPO/tools/patch_prg.py" "$ROMDIR/vsavj.zip" "$WORK/prg" \
    --patch "$WORK/p.json" > /dev/null 2>&1
ROMDIR="$ROMDIR" "$REPO/tools/pack_build.sh" "$WORK/prg" "$WORK/rompath" > /dev/null 2>&1
got=$(m2a_masked_target "$WORK/rompath;$ROMDIR" || true)
if [ -n "$got" ]; then
    echo "FAIL: an unregistered build resolved to '$got' — it must resolve to"
    echo "      nothing so the gate can stop"; fail=1
else
    echo "  ok: it resolves to nothing"
fi

out=$( . "$REPO/tests/lib/m2a_common.sh"
       m2a_run_masked() { echo "REPLAY-RAN $2"; exit 1; }
       m2a_legacy_gate_masked "$WORK/rompath;$ROMDIR" "$WORK" 2>&1 || true
       echo "gate_fail=$gate_fail" )
for want in "not in tests/expected/registry.tsv" "rule 6" "gate_fail=1"; do
    if printf '%s' "$out" | grep -q "$want"; then
        echo "  ok: the stop names '$want'"
    else
        echo "FAIL: the stop did not mention '$want'"; fail=1
    fi
done
# It must stop BEFORE spending an emulator run on a build it cannot judge.
if printf '%s' "$out" | grep -q "ok: 0"; then
    echo "FAIL: it ran replays against an unresolvable target"; fail=1
else
    echo "  ok: it stops before running any replay"
fi

echo "== 3. the escape hatch announces itself =="
# M2A_EXPSET exists for authoring a set for a build that is not registered
# yet. A silent override would be the old pin with extra steps, so the run
# must say that it is not asserting the policy.
out=$( . "$REPO/tests/lib/m2a_common.sh"
       m2a_run_masked() { echo "REPLAY-RAN $2"; exit 1; }
       M2A_EXPSET=donovan-m8-stock
       M2A_MASKED_REQUIRED=""
       m2a_legacy_gate_masked "$WORK/rompath;$ROMDIR" "$WORK" 2>&1 || true )
if printf '%s' "$out" | grep -q "PINNED BY NAME"; then
    echo "  ok: M2A_EXPSET says so on every run"
else
    echo "FAIL: M2A_EXPSET overrode the target silently"; fail=1
fi

echo
[ "$fail" = 0 ] && echo "PASS: the battery's target follows the build" \
                || { echo "FAIL: see above"; exit 1; }
