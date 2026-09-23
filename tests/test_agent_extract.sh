#!/bin/sh
# test_agent_extract.sh — SLICE S3 OF GitHub #172: the transcript EXTRACT the procedural
# checker (C1) reads says what the transcript says (`tools/agent/extract.py`, 2026-09-23).
#
# C1 is context-free by ruling, so everything it can judge is in this extract: the
# maintainer's messages, the agent's statements (never its private reasoning), each tool
# call and the head of its result, every tracked launch and completion, every DETACHED
# launch, and under each statement the figures no earlier tool output, input or
# maintainer message contains. The extractor's selftest drives a synthetic transcript
# with known answers: a figure printed with a thousands separator and reported without
# one is SOURCED, an invented one is FLAGGED, an issue number, a session key, a year and
# a hex value are not figures, reasoning is excluded, a nohup launch is DETACHED, a
# tracked task with no notification is OPEN, and a result that merely QUOTES the launch
# marker is NOT a launch (the phantom-task defect of 14z-176: 7 of 798 marker-carrying
# results in the archive were quotes).
#
# MUST-FIRE: perturbed-copy: loose-launch — a copy whose launch test accepts the marker ANYWHERE in a result (the pre-14z-176 test) must invent the quoted task, and the selftest must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: blind-figures — a copy whose figure finder returns nothing must stop flagging the invented figure, and the selftest must FAIL (mode: the gate runs against that copy)
#
# Usage: tests/test_agent_extract.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# make_copy <name> — a copy of tools/agent with ONE perturbation in extract.py
make_copy() {
    mkdir -p "$W/$1"; cp -R tools/agent "$W/$1/agent"
    python3 - "$W/$1/agent/extract.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "loose-launch": ("    if not s.startswith(_LAUNCH_HEADS):\n        return None\n",
                     "    if not any(k in s for k in agentlib.TRACKED_RESULT):  # CONTROL loose-launch\n        return None\n"),
    "blind-figures": ('    """-> the figures a statement reports, normalised (thousands separators dropped)."""\n',
                      '    """-> the figures a statement reports, normalised (thousands separators dropped)."""\n    return []  # CONTROL blind-figures\n'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/agent/extract.py"
}

echo "== test_agent_extract: #172 slice S3 — the extract C1 reads =="
fail=0
EX=tools/agent/extract.py
if vs_ctl_is loose-launch || vs_ctl_is blind-figures; then EX="$(make_copy "$VS_CTL")"; fi
python3 "$EX" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q -- '-> PASS$' "$W/self.txt" || { echo "FAIL: the extractor's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in loose-launch blind-figures; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q -- '-> FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'WRONG' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: the extract sources and flags figures, excludes reasoning, and lists detached, open and only REAL tracked launches"
else echo "FAIL: test_agent_extract"; exit 1; fi
