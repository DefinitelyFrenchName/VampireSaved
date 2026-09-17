#!/bin/sh
# test_commit_subject.sh — no unpushed commit message may carry a GitHub CLOSING
# keyword before an issue reference (14z-162, GitHub #151). ROM-free, ~1 s.
#
# MUST-FIRE: perturbed-copy: closing-subject — a message file carrying the flagged
# shape (a closing keyword directly before `#N`) must be REPORTED by the tool and
# fail the gate; the mode feeds the tool such a file and section 1 must FAIL
#
# THE CLASS. GitHub closes an issue when a commit pushed to the default branch
# carries `close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved`
# (optional colon) directly before `#N`, `owner/repo#N` or an issue URL, and it
# attributes the close to the PUSHING account. This project's session-close
# subjects were shaped `14z-N CLOSE: #<ticket> ...`; that shape closed #151 twice
# and #136 once as a side effect of pushing, and one of those closes was then
# recorded as a deliberate act of the maintainer, who was never asked — the
# 14z-162 trust breach (docs/project/gotchas.md, "A COMMIT SUBJECT THAT CLOSES A
# TICKET"). Closing a ticket is a decision ([VSP-182]), never a commit side effect.
#
# THE RULE is mechanical and lives in tools/check_commit_subject.py: every line
# of every message in `origin/main..HEAD` is scanned; a closing keyword adjacent
# to an issue reference fails. A dash, a word, or the reference coming first all
# break the adjacency and are allowed, so a subject can still name the ticket it
# resolves — it just cannot let GitHub act on the phrasing.
#
# Section 2 is the must-fire control: the tool fed a message that carries the
# shape must report it and return non-zero.
#
# Usage: tests/test_commit_subject.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

echo "== 1. no unpushed commit message would close an issue on push =="
if vs_ctl_is closing-subject; then
    # THE EXECUTABLE FORM: the REAL check is pointed at a message carrying the
    # flagged shape (assembled from pieces so this gate's own text never has it),
    # and must fail exactly as it would on such a commit.
    printf '%s\n' "14z-N $(printf 'CLOSE'): $(printf '#')999 the mode message" > "$W/msg"
    python3 tools/check_commit_subject.py --file "$W/msg" || fail=1
else
    python3 tools/check_commit_subject.py --range origin/main..HEAD || fail=1
fi

echo "== 2. MUST-FIRE CONTROL: the tool flags a message carrying the closing shape =="
if python3 tools/check_commit_subject.py --selftest >/dev/null; then
    vs_ctl_fired closing-subject "the selftest fixtures classify exactly — the flagged shape is caught, adjacency-broken forms pass"
else
    vs_ctl_dead closing-subject "the tool's selftest fixtures did not all classify as frozen"; fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "PASS: no unpushed commit message would close an issue, and the control fires"
else
    echo "FAIL: commit-subject gate"
    exit 1
fi
