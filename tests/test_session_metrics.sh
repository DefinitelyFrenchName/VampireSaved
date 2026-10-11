#!/bin/sh
# test_session_metrics.sh — the session dashboard's collector reads every source as its rule says and labels
# every figure with its class (`tools/session_metrics.py`, 14z-198, GitHub #264).
#
# WHAT: tools/session_metrics.py reads the rule-checker ledger, the static tier's run records, git log, STATE's
#   session headings and findings rows, the retraction files, the ticket index and the session transcripts, and
#   emits the dashboard's datasets, each figure carrying {value, class, source, rule}.
# HOW: builds a SYNTHETIC repository and project directory (no real transcript is committed: one carries the
#   user's identity) holding every shape the collector must read right — a session key and its letter
#   continuation (14z-9 / 14z-9b), a ledger row keyed by the transcript id instead of the key, an assistant
#   message spread over two records (one usage), a mid-turn message recorded as a queue enqueue AND a user
#   record (one message), harness noise, a transcript id on one STATE heading and none on the other (mapped by
#   its commits), a tier run inside the span and one outside it — and requires the collector's exact figures;
#   then `check` must pass, a PLANTED ledger row must move the run count by exactly one, and three controls run
#   shadow copies with one perturbation each, each of which must fail the comparison for its own reason.
# EXPECTS: 14z-9: 4 rule-checker runs (one keyed by its transcript id), 2 VIOLATED, Q1/Q4/QP3 1 each, 3 packets,
#   1 re-check, longest 2; 1 commit (14z-9b's not counted); 3 findings; 2 retracted wordings; 2 tickets;
#   2 maintainer messages; reply median 10.0 min; 700 output tokens; 1 worker; 1 tier run, 0.03 h, 1 FAIL.
#   14z-10: its transcript found by its commit (DERIVED). check: 0 bad. The plant: 5 runs. Each control FIRES.
#
# MUST-FIRE: shadow-tool: usage-per-record — a copy that sums usage per transcript record, not per message id, must count 1,000 output tokens, and the comparison must FAIL (mode: the gate reads that copy)
# MUST-FIRE: shadow-tool: key-prefix — a copy that reads a commit's session key without its letter suffix must count 14z-9b's commit as 14z-9's, and the comparison must FAIL (mode: the gate reads that copy)
# MUST-FIRE: shadow-tool: key-only-ledger — a copy that matches ledger rows by the session key alone must miss the row keyed by the transcript id, and the comparison must FAIL (mode: the gate reads that copy)
#
# Usage: tests/test_session_metrics.sh      # ci_portable, ~2 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
TOOL=tools/session_metrics.py
R="$W/repo"; P="$W/projects"
mkdir -p "$R/tests/rulecheck/retractions" "$R/docs/project" "$P/aaaabbbb-0000/subagents" "$R/build/static_runs"

# ---- the synthetic repository
git -C "$W" init -q repo
gc() { (cd "$R" && echo "$2" > "f_$2" && git add -A && GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" \
        git -c user.name=t -c user.email=t@t commit -q -m "$3"); }
gc 2026-01-01T10:30:00Z a "14z-9: the first"
gc 2026-01-01T11:00:00Z b "14z-9b: the continuation"
gc 2026-01-02T09:30:00+02:00 c "14z-10: the next"
cat > "$R/STATE.md" <<'EOF'
# STATE

## Session 14z-10 — the next. (no transcript id)

| | |
|---|---|
| opened with | x |

## Session 14z-9 — the first. A session (transcript `aaaabbbb`).

| | |
|---|---|
| **(2) THE FINDINGS TABLE** (checklist step 1) | (a) one — `x` / none; (b) two (a parenthesis (c) inside) — `y` / none; (c) three — `z` / none |
EOF
printf '%s\n' "# retractions" "old wording	why	retracted" "older wording	why	gone" "new wording	control	reach:1" \
    > "$R/tests/rulecheck/retractions/14z-9.tsv"
{ echo "# tickets"; printf 'issue\tkind\tstatus\ttitle\trepro\tdecided\tlearned\twrong\tsessions\n'
  printf '2\tbug\topen\tt\tnone\tnone\tnone\tnone\t14z-9\n'; printf '1\tbug\tdone\tt\tnone\tnone\tnone\tnone\t14z-8, 14z-9\n'
  printf '3\tbug\topen\tt\tnone\tnone\tnone\tnone\t14z-9b\n'; } > "$R/docs/project/tickets.tsv"
{ echo "# ledger"
  printf 'id\tdate\tsession\tdecision\tsubject\tcontrol\tcontrol_verdict\tverdict\tviolated\tresolution\tmodel\n'
  printf '2026-01-01-01\t2026-01-01\t14z-9\trecommendation\tthe close: the packet — first\tp\tCAUGHT\tVIOLATED\tQ1 Q4\tfixed\tm\n'
  printf '2026-01-01-02\t2026-01-01\t14z-9\trecommendation\tthe close: the packet — re-check after run 01\tp\tCAUGHT\tOK\t-\t-\tm\n'
  printf '2026-01-01-03\t2026-01-01\t14z-9\texpectation\ta freeze\tp\tCAUGHT\tOK\t-\t-\tm\n'
  printf '2026-01-01-04\t2026-01-01\taaaabbbb\tprocedure\tC1 part 1\tp\tCAUGHT\tVIOLATED\tQP3\tanswered\tm\n'
  printf '2026-01-01-05\t2026-01-01\t14z-9b\texpectation\tother\tp\tCAUGHT\tOK\t-\t-\tm\n'; } > "$R/tests/rulecheck/ledger.tsv"

# ---- two tier runs: one inside 14z-9's transcript span, one outside every span
mk_run() {  # mk_run <dirname> <start utc> <end utc> <head>
    d="$R/build/static_runs/$1"; mkdir -p "$d"
    printf '# static results\n# head %s\n# args --strict\n# gate\tverdict\tseconds\tdeclared\tfired\thonoured\n' "$4" > "$d/results.tsv"
    printf 'test_a\tPASS\t10\t0\t0\t0\ntest_b\tFAIL\t5\t0\t0\t0\ntest_c\tSKIP\t0\t0\t0\t0\n' >> "$d/results.tsv"
    printf '# control times\n# gate\tcontrol\tverdict\tseconds\ntest_a\tx\tHONOURED\t7\ntest_a\ty\tHONOURED\t3\n' > "$d/results.controls.tsv"
    printf '{"utc": "%s"}\n' "$2" > "$d/run_record_start.json"; printf '{"utc": "%s"}\n' "$3" > "$d/run_record_end.json"
}
mk_run 20260101T103000Z_1 2026-01-01T10:30:00Z 2026-01-01T10:31:40Z deadbeef
mk_run 20260105T000000Z_2 2026-01-05T00:00:00Z 2026-01-05T00:10:00Z cafef00d

# ---- the transcripts
python3 - "$P" <<'PY'
import json, sys, os
P = sys.argv[1]
def w(path, recs):
    with open(path, "w") as f:
        for r in recs: f.write(json.dumps(r) + "\n")
u = lambda n: {"input_tokens": 1, "cache_creation_input_tokens": 10, "cache_read_input_tokens": 100, "output_tokens": n}
w(os.path.join(P, "aaaabbbb-0000.jsonl"), [
    {"type": "user", "timestamp": "2026-01-01T10:00:00Z", "message": {"content": "start the work"}},
    {"type": "assistant", "timestamp": "2026-01-01T10:00:10Z", "message": {"id": "m1", "usage": u(300),
        "content": [{"type": "tool_use", "id": "t1", "name": "Bash", "input": {"command": "x", "run_in_background": True}}]}},
    {"type": "assistant", "timestamp": "2026-01-01T10:00:11Z", "message": {"id": "m1", "usage": u(300),
        "content": [{"type": "tool_use", "id": "t2", "name": "Read", "input": {}}]}},
    {"type": "user", "timestamp": "2026-01-01T10:00:20Z", "message": {"content": "<task-notification> done </task-notification>"}},
    {"type": "assistant", "timestamp": "2026-01-01T10:20:00Z", "message": {"id": "m2", "usage": u(400),
        "content": [{"type": "text", "text": "Done. What next?"}]}},
    {"type": "queue-operation", "operation": "enqueue", "timestamp": "2026-01-01T10:30:00Z", "content": "do the next thing"},
    {"type": "user", "timestamp": "2026-01-01T10:30:00Z", "message": {"content": "do the next thing"}},
    {"type": "assistant", "timestamp": "2026-01-01T11:00:00Z", "message": {"id": "m3",
        "content": [{"type": "tool_use", "id": "t3", "name": "Bash", "input": {"command": "y"}}]}},
])
sd = os.path.join(P, "aaaabbbb-0000", "subagents")
json.dump({"agentType": "measurer", "description": "measure x"}, open(os.path.join(sd, "agent-1.meta.json"), "w"))
w(os.path.join(sd, "agent-1.jsonl"), [
    {"type": "assistant", "timestamp": "2026-01-01T10:05:00Z", "message": {"id": "w1", "model": "claude-sonnet-5-5", "usage": u(50), "content": []}},
    {"type": "assistant", "timestamp": "2026-01-01T10:05:01Z", "message": {"id": "w1", "model": "claude-sonnet-5-5", "usage": u(50), "content": []}},
])
w(os.path.join(P, "ccccdddd-0000.jsonl"), [
    {"type": "user", "timestamp": "2026-01-02T07:00:00Z", "message": {"content": "go"}},
    {"type": "assistant", "timestamp": "2026-01-02T08:00:00Z", "message": {"id": "n1", "content": [{"type": "text", "text": "ok"}]}},
])
PY

shadow() {  # shadow <control> — a copy of the collector with ONE perturbation, beside the real tools/agent
    mkdir -p "$W/$1/tools"; cp "$TOOL" "$W/$1/tools/session_metrics.py"; ln -s "$REPO/tools/agent" "$W/$1/tools/agent"
    python3 - "$W/$1/tools/session_metrics.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "usage-per-record": ('usage[m["id"]] = m["usage"]', 'usage[len(usage)] = m["usage"]'),
    "key-prefix": ('m = re.match(r"(14z-\\d+[a-z]?)[: ]", subj)', 'm = re.match(r"(14z-\\d+)", subj)'),
    "key-only-ledger": ('if r.get("session") in (key, tid)]', 'if r.get("session") == key]'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/tools/session_metrics.py"
}

# figures <tool> <out dir> — the collector over the synthetic tree, one "session metric value class" line per figure
figures() {
    python3 "$1" collect --keys 14z-9..14z-10 --repo "$R" --projects "$P" --static-runs "$R/build/static_runs" --out "$2" \
        > "$2.log" 2>&1 || return 1
    python3 -c "
import json, sys
for r in json.load(open(sys.argv[1] + '/figures.json')): print(r['session'], r['metric'], r['value'], r['class'])
" "$2" > "$2.txt"
}
EXPECT='14z-9 rc_runs 4 MEASURED
14z-9 rc_violated 2 MEASURED
14z-9 q_Q1 1 MEASURED
14z-9 q_Q4 1 MEASURED
14z-9 q_QP3 1 MEASURED
14z-9 packets 3 ESTIMATED
14z-9 rechecks 1 ESTIMATED
14z-9 longest_packet 2 ESTIMATED
14z-9 commits 1 MEASURED
14z-9 findings 3 MEASURED
14z-9 retracted 2 MEASURED
14z-9 tickets_touched 2 MEASURED
14z-9 transcript aaaabbbb MEASURED
14z-9 span_h 1.0 DERIVED
14z-9 maint_msgs 2 MEASURED
14z-9 reply_median_min 10.0 DERIVED
14z-9 out_tok 700 MEASURED
14z-9 in_tok 222 MEASURED
14z-9 bg_jobs 1 MEASURED
14z-9 workers 1 MEASURED
14z-9 worker_out_tok 50 MEASURED
14z-9 tier_runs 1 DERIVED
14z-9 tier_wall_h 0.03 DERIVED
14z-9 tier_fail 1 DERIVED
14z-10 transcript ccccdddd DERIVED
14z-10 commits 1 MEASURED'
compare() {  # compare <figures.txt> — 0 when every expected line is present
    echo "$EXPECT" | while IFS= read -r line; do grep -qxF "$line" "$1" || { echo "missing: $line"; return 1; }; done
}

echo "== test_session_metrics: #264 — the session dashboard's collector =="
fail=0
T="$TOOL"
if vs_ctl_is usage-per-record || vs_ctl_is key-prefix || vs_ctl_is key-only-ledger; then T="$(shadow "$VS_CTL")"; fi
if figures "$T" "$W/real" && compare "$W/real.txt" > "$W/real.cmp"; then
    echo "  ok    every expected figure, with its class ($(echo "$EXPECT" | wc -l | tr -d ' ') lines)"
else echo "  FAIL  the collector's figures on the synthetic tree:"; cat "$W/real.cmp" "$W/real.log" 2>/dev/null | sed 's/^/        /'; fail=1; fi

if [ -z "${VS_CTL:-}" ]; then
    if python3 "$TOOL" check "$W/real" > "$W/check.txt" 2>&1; then echo "  ok    check: $(tail -1 "$W/check.txt")"
    else echo "  FAIL  check: $(tail -1 "$W/check.txt")"; fail=1; fi
    # a figure with no class must fail check (the check is not a pass-through)
    python3 -c "
import json, sys; p = sys.argv[1] + '/figures.json'; rows = json.load(open(p))
rows.append(dict(rows[0], metric='planted', **{'class': 'GUESSED'})); json.dump(rows, open(p, 'w'))" "$W/real"
    if python3 "$TOOL" check "$W/real" > /dev/null 2>&1; then echo "  FAIL  check passed a figure whose class is GUESSED"; fail=1
    else echo "  ok    check refuses a figure whose class is not one of the five"; fi
    # THE PLANT: one more ledger row for 14z-9 must move its run count by exactly one
    printf '2026-01-01-06\t2026-01-01\t14z-9\texpectation\tplanted\tp\tCAUGHT\tOK\t-\t-\tm\n' >> "$R/tests/rulecheck/ledger.tsv"
    figures "$TOOL" "$W/plant" || true
    if grep -qx '14z-9 rc_runs 5 MEASURED' "$W/plant.txt"; then echo "  ok    PLANT: a planted ledger row moves 14z-9's runs 4 -> 5"
    else echo "  FAIL  PLANT: $(grep '^14z-9 rc_runs' "$W/plant.txt" || echo 'no rc_runs line')"; fail=1; fi
    sed -i.bak '$d' "$R/tests/rulecheck/ledger.tsv"
    for c in usage-per-record key-prefix key-only-ledger; do
        case "$c" in
        usage-per-record) want='^14z-9 out_tok 1000 MEASURED$' ;;
        key-prefix)       want='^14z-9 commits 2 MEASURED$' ;;
        key-only-ledger)  want='^14z-9 rc_runs 3 MEASURED$' ;;
        esac
        if figures "$(shadow "$c")" "$W/ctl_$c" && compare "$W/ctl_$c.txt" > /dev/null; then
            vs_ctl_dead "$c" "the perturbed copy still read every figure as expected" || fail=1
        elif grep -qE "$want" "$W/ctl_$c.txt" 2>/dev/null; then vs_ctl_fired "$c" "$(grep -m1 -E "$want" "$W/ctl_$c.txt")"
        else vs_ctl_dead "$c" "the copy failed, but not for its reason: $(tail -1 "$W/ctl_$c.log")" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: the collector reads every source by its rule and labels every figure"
else echo "FAIL: test_session_metrics"; exit 1; fi
