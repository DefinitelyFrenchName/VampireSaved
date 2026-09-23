#!/bin/sh
# test_agent_defs.sh — SLICE S4 OF GitHub #172, step 1: every worker definition under
# `.claude/agents/` STATES its caps (tools/agent/agent_defs.py), ruled 2026-09-23 (14z-177,
# DECISIONS_HISTORY.md "Ruled 2026-09-23 (14z-177)"): at most Opus-class, effort at most xhigh.
#
# Why a static gate at all: measured the same sitting (tools/agent/probe_agents.sh), a definition
# with no `model` runs on its CALLER's model (A9) and one with no `effort` at its caller's effort
# (A4) — and S5 makes the caller Fable — while a `hooks:` block in the frontmatter did not fire
# (A6), so a definition must state both caps and must not carry a key that reads as enforcement.
# What this gate does NOT hold: the Agent CALL's `model` beats the definition's (A2) — that is the
# call gate's (step 3 of the ruled order), not this one's.
#
# The real `.claude/agents/` must pass, the required definitions present; then each control is a
# COPY of it with ONE planted defect, which the check must refuse with that defect's reason.
#
# MUST-FIRE: perturbed-copy: fable-model — measurer.md's model set to claude-fable-5-1 must be refused as above Opus-class, and the gate must FAIL (mode: the gate checks that copy)
# MUST-FIRE: perturbed-copy: missing-effort — measurer.md's effort line removed must be refused (it would follow the caller's effort), and the gate must FAIL (mode: the gate checks that copy)
# MUST-FIRE: perturbed-copy: max-effort — measurer.md's effort set to max must be refused, and the gate must FAIL (mode: the gate checks that copy)
# MUST-FIRE: perturbed-copy: frontmatter-hooks — a hooks: block added to reader.md must be refused, and the gate must FAIL (mode: the gate checks that copy)
# MUST-FIRE: perturbed-copy: write-tool — Write added to reader.md's tools must be refused, and the gate must FAIL (mode: the gate checks that copy)
# MUST-FIRE: perturbed-copy: context-leak — rule-checker.md's omitClaudeMd line removed must be refused (it would receive CLAUDE.md, probe_agents A13), and the gate must FAIL (mode: the gate checks that copy)
#
# Since 14z-178 the pinned rule-checker (step 4) is required too, and must carry
# `omitClaudeMd: true` (measured by probe_agents.sh A13 to keep CLAUDE.md out of its context).
#
# Usage: tests/test_agent_defs.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT INT TERM
REAL=".claude/agents"
CHECK="python3 tools/agent/agent_defs.py"

# perturb NAME DIR — plant control NAME's one defect into a copy at DIR; echo the reason
# fragment the check must print for it
perturb() {
    rm -rf "$2"; cp -R "$REAL" "$2"
    case "$1" in
        fable-model)    sed -i.bak 's/^model: .*/model: claude-fable-5-1/' "$2/measurer.md"; echo "is not Opus-class";;
        missing-effort) sed -i.bak '/^effort:/d' "$2/measurer.md"; echo "effort missing";;
        max-effort)     sed -i.bak 's/^effort: .*/effort: max/' "$2/measurer.md"; echo "effort 'max'";;
        frontmatter-hooks)
            python3 - "$2/reader.md" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("\ntools:", "\nhooks:\n  PreToolUse:\n    - matcher: Bash\ntools:", 1)
open(p, "w").write(s)
PY
            echo "key 'hooks' not allowed";;
        write-tool)     sed -i.bak 's/^tools: .*/&, Write/' "$2/reader.md"; echo "tool 'Write'";;
        context-leak)   sed -i.bak '/^omitClaudeMd:/d' "$2/rule-checker.md"; echo "omitClaudeMd: true missing";;
    esac
    rm -f "$2"/*.bak
}

fail=0
target="$REAL"
if [ -n "$VS_CTL" ]; then
    target="$W/mode"
    want="$(perturb "$VS_CTL" "$target")"
    echo "MODE: control $VS_CTL — checking a copy with that defect planted ($want)"
fi
echo "== the definitions under $target"
out="$($CHECK "$target" 2>&1)" && rc=0 || rc=$?
echo "$out" | sed 's/^/  /'
if [ "$rc" -ne 0 ]; then echo "FAIL: a definition breaks the caps"; fail=1; fi
for n in measurer reader rule-checker; do
    echo "$out" | grep -q "^OK  $n.md$" || { echo "FAIL: $n.md is not an OK definition"; fail=1; }
done

if [ -z "$VS_CTL" ]; then
    echo "== controls: one planted defect per copy, each must be refused with its reason"
    for c in fable-model missing-effort max-effort frontmatter-hooks write-tool context-leak; do
        want="$(perturb "$c" "$W/$c")"
        got="$($CHECK "$W/$c" 2>&1)" && crc=0 || crc=$?
        if [ "$crc" -ne 0 ] && echo "$got" | grep '^BAD ' | grep -qF "$want"; then
            vs_ctl_fired "$c" "refused: $(echo "$got" | grep '^BAD ' | head -1 | cut -c1-120)"
        else
            vs_ctl_dead "$c" "the planted defect was not refused with '$want' (exit $crc)" || fail=1
        fi
    done
fi

if [ "$fail" -eq 0 ]; then echo "PASS: every worker definition states its caps (model at most Opus-class, effort at most xhigh, an allowed tool list) and carries no unapproved key; the rule-checker launches without CLAUDE.md"
else echo "FAIL: test_agent_defs"; fi
exit "$fail"
