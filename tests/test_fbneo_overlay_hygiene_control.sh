#!/bin/sh
# test_fbneo_overlay_hygiene_control.sh — the ground truth for #38's gate.
# Reconstructs the PRE-FIX runner (bare `ln -sfn`, no clear) and requires
# tests/test_fbneo_overlay_hygiene.sh to FAIL against it. A hygiene gate that
# has never seen the defect is indistinguishable from one that cannot see it.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT INT TERM
python3 - "$T/prefix.sh" <<'PY'
import sys
src = open("tools/run_replay_fbneo.sh").read()
start = src.index("else\n    # 14z-94 (#38): CLEAR IT FIRST.")
end = src.index("fi\n", src.index('ln -sfn "$ROMDIR" "$WORK/roms"')) + 3
open(sys.argv[1], "w").write(
    src[:start] + 'else\n    ln -sfn "$ROMDIR" "$WORK/roms"\nfi\n' + src[end:])
PY
chmod +x "$T/prefix.sh"
if RUNNER="$T/prefix.sh" tests/test_fbneo_overlay_hygiene.sh > "$T/out" 2>&1; then
    echo "FAIL: the gate PASSED against the pre-fix runner — it cannot see #38"
    sed 's/^/    /' "$T/out"
    exit 1
fi
if grep -q "still serves the previous overlay" "$T/out"; then
    echo "PASS: the gate fails on the pre-fix runner, naming the stale overlay."
else
    echo "FAIL: it failed for some OTHER reason — the control proves nothing:"
    sed 's/^/    /' "$T/out"
    exit 1
fi
