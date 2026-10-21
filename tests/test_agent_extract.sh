#!/bin/sh
# test_agent_extract.sh — SLICE S3 OF GitHub #172: the transcript EXTRACT the procedural
# checker (C1) reads says what the transcript says (`tools/agent/extract.py`, 2026-09-23).
#
# WHAT: the transcript EXTRACT the procedural checker reads (tools/agent/extract.py) says
#   what the transcript says: statements without private reasoning, each tool call and its
#   result head, tracked launches and completions, DETACHED launches, unsourced figures, and
#   workers' specs, commands and reports — a BACKGROUND worker's report being the hand-back the
#   session received (#208), never its first text, and `NOT DELIVERED` when it had not handed back;
#   and (since #271, 14z-199) a RULE-CHECKER reader's figure quoted from its own prompt is not
#   flagged, while one in neither its prompt nor its results still is; and (since #277, 14z-205c) a decimal written
#   to fewer places than its source is sourced, a figure or path cited past a result line's 160-character cut is quoted
#   (A@/W@), and a --from span opens with the event lines before its cut, marked `<`; and (since #262) a maintainer
#   message sent mid-turn, stored only as a `queued_command` attachment from a human, is an M line, once; and (since
#   #263) under a W# line, W§ quotes the file lines a worker's report cites beside a listed figure, from its own read.
# HOW: drives the extractor's selftest over a synthetic transcript with known answers (a
#   sourced figure, an invented one, non-figures, an open task, a marker merely quoted); two
#   controls run copies with the launch test loosened and the figure finder blinded and must
#   fail the selftest; and (since 14z-189, #208) runs the extractor on tests/agent/handback_fixture/,
#   cut from the 14z-188 transcript: rule-checker run 2026-10-02-562's reader B as its transcript
#   stood when that close's extract was made (six seconds before its SubagentHandback) plus the
#   hand-back the session received — and on a copy without that hand-back.
# EXPECTS: the selftest's checks all pass and the controls fail on their copies; the fixture's
#   WX is the hand-back's verdict (Q1 VIOLATED ... VERDICT VIOLATED), marked as the session's, and
#   never "Let me read all the named files."; without the hand-back it reads NOT DELIVERED; a red
#   names the check, and an extract that lies is a procedure check that cannot see.
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
# MUST-FIRE: perturbed-copy: loose-launch — a copy whose launch test (agentlib.tracked_launch) accepts the marker ANYWHERE in a result (the pre-14z-176 test) must invent the quoted task, and the selftest must FAIL (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: handback-ignored — a copy whose extractor ignores the hand-backs the SESSION received (session_handbacks' result dropped) must stop showing the fixture's delivered verdict, and the gate must FAIL (#208; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: judge-prompt-unsourced — a copy whose extractor does not count a RULE-CHECKER reader's prompt as a source (the pre-#271 extractor, JUDGE_PROMPT_SOURCED off) must flag the selftest reader's quoted claim figure 2560, and the selftest must FAIL (#271, 14z-199: a calibration plant's reader quoting its claim's frames 2550/2560 failed procedure runs from 14z-179 to 14z-198; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: rounding-off — a copy whose figure matcher has no rounding clause (the pre-#277 extractor) must flag the selftest's 10.5 sourced only by `real 10.45`, and the selftest must FAIL (#277, 14z-205c; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: cut-cites-off — a copy whose cut_cites returns nothing must drop the A@ line quoting the cited figure and path past the 160-character cut, and the selftest must FAIL (#277; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: prelude-off — a copy whose prelude holds no lines must open a --from span bare, and the selftest must FAIL (#277; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: mid-turn-blind — a copy whose mid_turn_message reads nothing (the pre-#262 extractor) must drop the selftest's mid-turn maintainer message, and the selftest must FAIL (#262, 14z-205c; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: cites-in-word — a copy whose A@ finder accepts a figure inside a word (a hash, a key) must quote the selftest's 35 from inside a commit hash, and the selftest must FAIL (#277, run 2026-10-20-1157; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: said-global — a copy whose M-line set is never cleared (one M line per TEXT for the whole transcript) must drop the selftest's second, later "identical Phobos confirmed", and the selftest must FAIL (#262, run 2026-10-20-1158; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: rounding-far — a copy whose rounded sources are looked for in the whole transcript must source the selftest's 1.9 from a load average 60 records back, and the selftest must FAIL (#277, run 2026-10-20-1157; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: rounding-version — a copy whose rounded source may be part of a version must source the selftest's 2.5 from git version 2.54.0, and the selftest must FAIL (#277, run 2026-10-20-1157; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: reads-merged — a copy whose cited_lines treats two files of one basename as one must quote a cfg.txt line for the selftest's 5678, and the selftest must FAIL (#263, run 2026-10-21-1160; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: cited-lines-off — a copy whose cited_lines returns nothing must drop the W§ line quoting name_moves.py.txt:77 and 699 under the selftest worker's derived 2550, and the selftest must FAIL (#263, 14z-205c; mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: blind-figures — a copy whose figure finder returns nothing must stop flagging the invented figure, and the selftest must FAIL (mode: the gate runs against that copy)
#
# Usage: tests/test_agent_extract.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# make_copy <name> — a copy of tools/agent with ONE perturbation (in agentlib.py or extract.py)
make_copy() {
    mkdir -p "$W/$1"; cp -R tools/agent "$W/$1/agent"
    python3 - "$W/$1/agent" "$1" <<'PY'
import os, sys; d, name = sys.argv[1:3]
# loose-launch perturbs agentlib (the ONE launch test, since the maintainer applied it
# 14z-176); blind-figures perturbs the extractor itself
p = os.path.join(d, "agentlib.py" if name == "loose-launch" else "extract.py"); s = open(p).read()
# judge-prompt-unsourced (#271) turns the rule-checker prompt source off
edits = {
    "loose-launch": ("    if not s.startswith(_LAUNCH_HEADS):\n        return None\n",
                     "    if not any(k in s for k in TRACKED_RESULT):  # CONTROL loose-launch\n        return None\n"),
    "blind-figures": ('    """-> the figures a statement reports, normalised (thousands separators dropped)."""\n',
                      '    """-> the figures a statement reports, normalised (thousands separators dropped)."""\n    return []  # CONTROL blind-figures\n'),
    "judge-prompt-unsourced": ("JUDGE_PROMPT_SOURCED = True", "JUDGE_PROMPT_SOURCED = False  # CONTROL judge-prompt-unsourced"),
    "handback-ignored": ("    sess_hb = session_handbacks(path)\n",
                         "    sess_hb = {}  # CONTROL handback-ignored\n"),
    # #277 (14z-205c)
    "rounding-off": ("        rounds = lambda m: Decimal(m).quantize(q, ROUND_HALF_UP) == want\n",
                     "        rounds = lambda m: False  # CONTROL rounding-off\n"),
    "cut-cites-off": ('    prints (RESULT_CHARS), with its context from the latest such result. `results` is [(record, full text)]."""\n',
                      '    prints (RESULT_CHARS), with its context from the latest such result. `results` is [(record, full text)]."""\n    return []  # CONTROL cut-cites-off\n'),
    "mid-turn-blind": ('    a = (r.get("attachment") or {}) if r.get("type") == "attachment" else {}\n',
                       '    return None  # CONTROL mid-turn-blind\n'),
    "cited-lines-off": ('    is quoted from either), a cited line the reads do not hold is marked, and lines past the cap are counted"""\n',
                        '    is quoted from either), a cited line the reads do not hold is marked, and lines past the cap are counted"""\n    return []  # CONTROL cited-lines-off\n'),
    "cites-in-word": ("                continue   # inside a word: not this figure's source\n", "                pass  # CONTROL cites-in-word\n"),
    "said-global": ("            said.clear()   # #262", "            pass  # CONTROL said-global #262"),
    "rounding-far": ("                    miss = [f for f in figures(txt) if not sourced(f, corpus, near)]", "                    miss = [f for f in figures(txt) if not sourced(f, corpus)]  # CONTROL rounding-far"),
    "rounding-version": ("(?![\\w]|\\.\\d)\"))", "(?![\\w])\"))  # CONTROL rounding-version"),
    "reads-merged": ("            if len(files) > 1:   # which file the report means is unknown: quote neither", "            if False:  # CONTROL reads-merged"),
    "prelude-off": ("    before = collections.deque(maxlen=max(prelude, 0))", "    before = collections.deque(maxlen=0)  # CONTROL prelude-off"),
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
if vs_ctl_is loose-launch || vs_ctl_is blind-figures || vs_ctl_is handback-ignored || vs_ctl_is judge-prompt-unsourced \
   || vs_ctl_is rounding-off || vs_ctl_is cut-cites-off || vs_ctl_is prelude-off || vs_ctl_is mid-turn-blind \
   || vs_ctl_is cited-lines-off || vs_ctl_is cites-in-word || vs_ctl_is said-global \
   || vs_ctl_is rounding-far || vs_ctl_is rounding-version || vs_ctl_is reads-merged; then EX="$(make_copy "$VS_CTL")"; fi
python3 "$EX" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q -- '-> PASS$' "$W/self.txt" || { echo "FAIL: the extractor's selftest"; fail=1; }

# fixture_check <extract.py> <out-prefix> — #208 on the real cut: prints the two verdict words
fixture_check() {
    F=tests/agent/handback_fixture
    python3 "$1" "$F/s.jsonl" > "$2.full" 2>&1 || true
    mkdir -p "$2.nohb/s"; cp -R "$F/s/subagents" "$2.nohb/s/"; head -1 "$F/s.jsonl" > "$2.nohb/s.jsonl"
    python3 "$1" "$2.nohb/s.jsonl" > "$2.nohb.out" 2>&1 || true
    if grep -q ' WX (the hand-back the session received at record 1' "$2.full" && grep -q ' WX | VERDICT: VIOLATED$' "$2.full" \
       && ! grep -q ' WX | Let me read' "$2.full"; then echo "delivered-ok"; else echo "delivered-WRONG"; fi
    if grep -q ' WX (NOT DELIVERED when this extract was made' "$2.nohb.out" && grep -q ' WX | (no report)$' "$2.nohb.out" \
       && ! grep -q ' WX | Let me read' "$2.nohb.out"; then echo "undelivered-ok"; else echo "undelivered-WRONG"; fi
}
echo "-- #208: the real hand-back fixture (tests/agent/handback_fixture/)"
r="$(fixture_check "$EX" "$W/fx")"
echo "  $(echo "$r" | tr '\n' ' ')"
case "$r" in *WRONG*) echo "FAIL: the hand-back fixture: $(echo "$r" | tr '\n' ' ')"; grep -E ' (WX|W ) ' "$W/fx.full" | head -3 | cut -c1-140; fail=1 ;; esac

if [ -z "${VS_CTL:-}" ]; then
    for c in loose-launch blind-figures judge-prompt-unsourced rounding-off cut-cites-off prelude-off mid-turn-blind cited-lines-off cites-in-word said-global rounding-far rounding-version reads-merged; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q -- '-> FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'WRONG' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
    HX="$(make_copy handback-ignored)"
    r="$(fixture_check "$HX" "$W/ctl_hb")"
    case "$r" in delivered-WRONG*) vs_ctl_fired handback-ignored "the copy that ignores the session's hand-backs shows the fixture's worker as: $(grep -m1 ' WX ' "$W/ctl_hb.full" | cut -c1-110 | sed 's/^\[[^]]*\] //')" ;;
                 *) vs_ctl_dead handback-ignored "the copy that ignores the session's hand-backs still showed the delivered verdict ($(echo "$r" | tr '\n' ' '))" || fail=1 ;; esac
fi

if [ "$fail" = 0 ]; then echo "PASS: the extract sources and flags figures (a rounded decimal sourced), quotes what a cut result line hid, opens a cut span with its prelude, shows a mid-turn maintainer message, quotes the lines a worker cites for a listed figure, excludes reasoning, lists detached, open and only REAL tracked launches, and shows a background worker's DELIVERED report (or NOT DELIVERED), never its first text"
else echo "FAIL: test_agent_extract"; exit 1; fi
