#!/bin/sh
# test_static_confirm.sh — the static tier's carry-forward predictor marks a gate STALE by every rule
# it states (`tools/static_confirm.py`, 14z-185b, GitHub #188 route A — wired 14z-188).
#
# WHAT: tools/static_confirm.py's predictions mean what they say: a changed path makes a gate STALE
#   when it is a program in the gate's reach (R1), is named by basename on a code line of the reach
#   (R2), lies under a directory the reach reads (R3), the reach reads the whole tree (R4), a data
#   file the reach names names it (R5), a templated path in the reach matches it (R6), or it is a
#   .gitignore/.gitattributes and the reach runs git (R7); a binary in the reach names nothing (14z-188,
#   the traced test's misses and its two TIMEOUTs; a shell or python line starting `--` is code); any
#   other gate is CARRIED.
# HOW: drives the predictor's selftest over a synthetic repo of sixteen gates, one per reader class
#   plus the seven of #188 option B's two narrowings (14z-190), with known answers; twelve controls run copies
#   with one rule removed (directory, whole-tree, data, template, git), `--` read as a comment outside Lua
#   (battery_reach.is_comment), binaries read as text, either narrowing switched off, or N-B's quoted-literal
#   clause dropped, its prose strings paired across code, or R6 directory templates read as one component, and each must fail the selftest.
# EXPECTS: the selftest's thirteen cases pass and every control fails on its copy. The HISTORY
#   backtest (tests/expected/static_confirm_backtest.tsv, `static_confirm.py backtest`) takes
#   minutes of worktrees and is run by hand, not here.
#
# WIRED 14z-188 (*"Build the wiring"*, after the strace test read 0 misses): tests/run_all_static.sh --confirm
# runs its `plan` (the confirm mode's own test is tests/test_static_runner.sh sections 18-19). This gate locks its rules; it does not claim they are
# enough — only a Linux run of the tier under strace, every gate's ACTUAL reads, can show that.
#
# MUST-FIRE: perturbed-copy: no-dir-rule — a copy with R3 (directory readers) removed must carry the gate that globs docs/game, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: no-whole-rule — a copy with R4 (whole-tree readers) removed must carry the git ls-files gate, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: no-data-rule — a copy with R5 (data-file readers) removed must carry the gate whose data file names the change, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: no-template-rule — a copy with R6 (templated paths) removed must carry the gate whose `item_$n.toml` matches, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: no-git-rule — a copy with R7 (git reads .gitignore) removed must carry the git gate on a .gitignore change, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: dashdash-comment — a copy whose battery_reach.is_comment reads `--` as a comment in every language must drop the shell option continuation that names cfg/base, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: binary-as-text — a copy that reads binaries as text must mark the binary's gate stale for the names inside it, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: narrow-build-off — a copy without N-A must mark the gate that names only the bare `build` directory stale for a build/ change, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: narrow-state-off — a copy without N-B must mark the gate that only echoes STATE.md in a message stale, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: narrow-literal-blind — a copy of N-B without its quoted-literal clause must carry the gate whose inline script opens 'STATE.md', and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: dir-template-off — a copy whose R6 reads a template ending in a placeholder (`"build/$b"`) as one path component only must carry the gate that names its builds only that way for a change under build/m1/, and the selftest must FAIL (mode: that copy's selftest; the class of the 15 traced misses of 14z-190)
# MUST-FIRE: perturbed-copy: prose-pairing — a copy of N-B whose prose regex skips short quoted strings (pairing a path's closing quote with the next opening one) must mark the gate stale whose `[ -f "$D/x.diverge" ] && echo "... STATE.md ..."` line names STATE.md only in a message, and the selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_static_confirm.sh      # ci_portable, ~1 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

make_copy() {  # make_copy <control> — a copy of tools/ with ONE perturbation in the predictor
    mkdir -p "$W/$1/tools"; cp tools/static_confirm.py tools/battery_reach.py "$W/$1/tools/"
    python3 - "$W/$1/tools/static_confirm.py" "$1" <<'PY'
import os, sys; p, name = sys.argv[1:3]
if name == "dashdash-comment":   # the one control that perturbs the copy's battery_reach.py
    p = os.path.join(os.path.dirname(p), "battery_reach.py")
s = open(p).read()
edits = {
    "dashdash-comment": ('(str(path).endswith(".lua") and s.startswith("--"))', 's.startswith("--")'),
    "no-dir-rule": ('+ [("R3", rx, d) for d, rx in dps]', '+ []  # CONTROL no-dir-rule'),
    "no-whole-rule": ("        if not why and changed and WHOLE.search(blob):", "        if False:  # CONTROL no-whole-rule"),
    "no-data-rule": ("    for d in data_files(root, blob):", "    for d in []:  # CONTROL no-data-rule"),
    "no-template-rule": ("    for rx, tok, is_path in templates(root, blob):", "    for rx, tok, is_path in []:  # CONTROL no-template-rule"),
    "no-git-rule": ('    if base in (".gitignore", ".gitattributes") and GIT_RUN.search(blob):', "    if False:  # CONTROL no-git-rule"),
    "binary-as-text": ('t = "" if b"\\0" in raw[:8192] else raw', "t = raw"),
    "narrow-build-off": ("        if k == 1 and parts[0] in NARROW_R3_TOP:   # N-A", "        if False:  # CONTROL narrow-build-off"),
    "narrow-state-off": ("    if bpat and base in NARROW_R2:   # N-B", "    if False:  # CONTROL narrow-state-off"),
    "narrow-literal-blind": ("    lit = re.search(", "    lit = None and re.search("),
    "dir-template-off": ('tail = r"(?:/.*)?$" if PLACE.fullmatch(parts[-1]) else r"$"   # R6 directory template', 'tail = r"$"   # CONTROL dir-template-off'),
    "prose-pairing": ('QUOTED.sub(lambda m: "" if re.search(r"\s", m.group(0)) else m.group(0), t)',
                      're.sub(r"\\"[^\\"\\n]*\\s[^\\"\\n]*\\"|\'[^\'\\n]*\\s[^\'\\n]*\'", "", t)'),
}
a, b = edits[name]
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
PY
    echo "$W/$1/tools/static_confirm.py"
}

echo "== test_static_confirm: #188 route A — the carry-forward predictor =="
fail=0
SC=tools/static_confirm.py
[ -n "${VS_CTL:-}" ] && SC="$(make_copy "$VS_CTL")"
python3 "$SC" --selftest > "$W/self.txt" 2>&1 || true
sed 's/^/  /' "$W/self.txt"
grep -q '^SELFTEST PASS$' "$W/self.txt" || { echo "FAIL: the predictor's selftest"; fail=1; }

if [ -z "${VS_CTL:-}" ]; then
    for c in no-dir-rule no-whole-rule no-data-rule no-template-rule no-git-rule dashdash-comment binary-as-text narrow-build-off narrow-state-off narrow-literal-blind prose-pairing dir-template-off; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: the predictor marks STALE by each of its seven rules, narrows as #188 option B rules, and carries the rest"
else echo "FAIL: test_static_confirm"; exit 1; fi
