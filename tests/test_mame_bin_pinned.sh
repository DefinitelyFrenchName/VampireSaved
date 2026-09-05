#!/bin/sh
# test_mame_bin_pinned.sh — a gate that boots `vsavjw` through a MAME wrapper
# must PIN the MAME binary (14z-133). ROM-free, ~1 s.
#
# THE CLASS. tools/run_mame.sh falls back to `mame` on PATH when MAME_BIN is
# unset — Homebrew's stock build here — which answers "Unknown system 'vsavjw'"
# and exits. A leg that boots our WIDE build then produces NO DUMPS: a gate
# with a liveness check reports "held the victim on only 0 frames" and fails
# honestly; a gate without one may read the empty leg as a verdict. The
# emulator runner exports no MAME_BIN, so this fires precisely under a release
# run and never in a developer shell that exported the variable earlier.
#
# WHAT IT COST. The M16 freeze sweep (14z-133) went red on THREE release-scope
# gates this way — test_phasec_image (whose 14z-132 red had been root-caused to
# a relative $ROMDIR, a real defect with the SAME symptom, and "pinning
# MAME_BIN changed nothing" had been measured in a shell that already exported
# it), audit_pyron_capture_block and audit_tenant_throw_geometry (both 14z-131,
# green standalone, first sweep ever). "Name MAME_BIN for a vsavjw run" had
# been an item in two earlier session openers and never a rule; this gate is
# the rule ([VSP-18]: enforcement, not prose).
#
# THE RULE is mechanical and lives in tools/audit_mame_bin_pin.py: a script
# under tests/ whose non-comment text both invokes a MAME wrapper
# (run_mame / run_replay_mame / run_replay_guarded) and names vsavjw must
# carry a real pin — an assignment or export of the variable. A bracketed
# mention in a Usage line is documentation and does not count. Stock-set
# gates (vsavj, vsav2) are out of the class: Homebrew's binary runs them,
# on an instrument other than the pinned reference build — recorded in STATE
# 14z-133 as an observation, not gated here.
#
# Section 2 is the must-fire control: a pinned in-class gate with its pin
# lines removed must be reported, and the same file switched to a stock set
# must drop out of the class.
#
# Usage: tests/test_mame_bin_pinned.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0

echo "== 1. every gate that boots vsavjw through a MAME wrapper pins its binary =="
python3 tools/audit_mame_bin_pin.py tests || fail=1

echo "== 2. MUST-FIRE CONTROL: a removed pin is reported; a stock-set gate is not =="
python3 tools/audit_mame_bin_pin.py --selftest || fail=1

if [ "$fail" -eq 0 ]; then
    echo "PASS: every vsavjw-booting gate pins its MAME binary, and the control fires"
else
    echo "FAIL: mame-bin pin gate"
    exit 1
fi
