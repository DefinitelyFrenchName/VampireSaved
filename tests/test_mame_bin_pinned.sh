#!/bin/sh
# test_mame_bin_pinned.sh — a gate that boots `vsavjw` through a MAME wrapper
# must PIN the MAME binary (14z-133). ROM-free, ~1 s.
#
# MUST-FIRE: perturbed-copy: stripped-pin — a pinned in-class gate with its MAME_BIN lines removed must be reported UNPINNED (the tool's --selftest; the mode strips the first pinned gate in a copy of tests/ and scans the copy)
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

# THE EXECUTABLE FORM: under CONTROL=stripped-pin the first pinned in-class
# gate loses its pin lines in a COPY of tests/ and section 1 scans the copy —
# it must FAIL.
SCAN=tests
if vs_ctl_is stripped-pin; then
    python3 - "$W/mode" <<'PY'
import sys, pathlib, shutil
sys.path.insert(0, "tools"); import audit_mame_bin_pin as m
dst = pathlib.Path(sys.argv[1]); dst.mkdir()
for f in pathlib.Path("tests").glob("*.sh"): shutil.copy(f, dst / f.name)
src = next(f for f in sorted(dst.glob("*.sh")) if m.verdict(f) == "pinned")
src.write_text("\n".join(l for l in src.read_text(errors="replace").splitlines() if not m.PIN.search(l)) + "\n")
print(f"  mode: {src.name} minus its pin lines, in a copy of tests/")
PY
    SCAN="$W/mode"
fi

echo "== 1. every gate that boots vsavjw through a MAME wrapper pins its binary =="
python3 tools/audit_mame_bin_pin.py "$SCAN" || fail=1

echo "== 2. MUST-FIRE CONTROL: a removed pin is reported; a stock-set gate is not =="
if python3 tools/audit_mame_bin_pin.py --selftest; then vs_ctl_fired stripped-pin "a pinned gate minus its pin lines is reported UNPINNED"
else vs_ctl_dead stripped-pin "the tool's self-test did not fire"; fail=1; fi

if [ "$fail" -eq 0 ]; then
    echo "PASS: every vsavjw-booting gate pins its MAME binary, and the control fires"
else
    echo "FAIL: mame-bin pin gate"
    exit 1
fi
