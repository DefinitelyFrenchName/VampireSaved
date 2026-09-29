#!/bin/sh
# test_rulings_verbatim.sh — a quote a session attributes to the maintainer is the maintainer's own words,
# and every message the maintainer sent is on record (`tools/agent/rulings_verbatim.py`, 14z-185b, #190 P2).
#
# WHAT: tools/agent/rulings_verbatim.py fails on each of its conditions and only then: a quote labelled
#   the maintainer's that none of their messages or answers contains (NOT FOUND — including the
#   session's own question relabelled as the maintainer's), a maintainer message or answer quoted in no
#   record and not exempt (UNHOMED), and an exempt row matching no message or without a reason (STALE);
#   a clean record passes, two questions joined by "and" stay the session's, and an answer introduced
#   by "then, asked X," is checked as the maintainer's.
# HOW: drives the tool's selftest (eight cases over a synthetic transcript with a user message, a
#   mid-turn enqueue, a task notification and an AskUserQuestion answer); four controls, one per
#   condition of the verdict (#185 item 5), run copies with it switched off, and each must fail.
# EXPECTS: the selftest's eight cases read as designed and all four controls fail on their copies.
#
# WHY. The 14z-185 close's rule-checker runs 425, 443, 444 and 445 found rulings quoted only from the
# session's own record, a heading quote the maintainer never wrote, a mid-turn message never recorded
# and a ruling with no standing line; its first run on 14z-185b found the maintainer's #189/#190
# instruction quoted only in a scratch file. The maintainer ruled the promotion: "P1+P2, then P4".
#
# MUST-FIRE: perturbed-copy: notfound-ignored — a copy that never counts a NOT FOUND quote must pass the altered-quote case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: questions-unseen — a copy that never classes a QUESTION must check the session's question as the maintainer's, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: unhomed-ignored — a copy that never counts an UNHOMED message must pass the unhomed case, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: stale-ignored — a copy that never counts a STALE exempt row must pass the stale case, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_rulings_verbatim.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of the tool with ONE perturbation
    mkdir -p "$W/$1"; cp tools/agent/rulings_verbatim.py "$W/$1/"
    python3 - "$W/$1/rulings_verbatim.py" "$1" <<'PY'
import sys; p, name = sys.argv[1:3]; s = open(p).read()
edits = {
    "notfound-ignored": ("none of their messages: {q[:120]}\")\n                            bad += 1\n",
                         "none of their messages: {q[:120]}\")  # CONTROL notfound-ignored\n"),
    "questions-unseen": ("    if QUEST.search(tail):\n", "    if False:  # CONTROL questions-unseen\n"),
    "unhomed-ignored": ("        print(f\"  UNHOMED    {ts[:16]} {n[:110]}\")\n        bad += 1\n",
                        "        print(f\"  UNHOMED    {ts[:16]} {n[:110]}\")  # CONTROL unhomed-ignored\n"),
    "stale-ignored": ("\"matches no message\"))\n            bad += 1\n", "\"matches no message\"))  # CONTROL stale-ignored\n"),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/rulings_verbatim.py"
}

echo "== test_rulings_verbatim: #190 P2 — the maintainer's words, verbatim, and every message on record =="
fail=0
RV=tools/agent/rulings_verbatim.py
case "${VS_CTL:-}" in notfound-ignored|questions-unseen|unhomed-ignored|stale-ignored) RV="$(make_copy "$VS_CTL")" ;; esac
python3 "$RV" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the tool's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in notfound-ignored questions-unseen unhomed-ignored stale-ignored; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 '  FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: each failure condition fails the check; the session's questions stay its own"
else echo "FAIL: test_rulings_verbatim"; exit 1; fi
