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
#   other gate is CARRIED. Since #274 (14z-200): the reach closes over sibling programs, R3c reads a
#   directory named beside its caller, R4 reads git in list form, R3 skips prose, python identifiers,
#   case globs and a directory joined to a literal file (N-C), and the session's build/ scratch leaves
#   every change set but a whole-tree reader's (N-D). Since #286 (a) (14z-202): N-B covers every `.md` basename, a
#   data file names a path only at a path position (N-E), a rule-checker run file is data only of a reach naming
#   `rulecheck/runs`, and a run file changed is a change only for such a reach (N-F), and a change under tests/rulecheck/
#   is not STALE for a bare `tests` lister that does not walk recursively (N-G); a walk is whole-tree only from the
#   repo root (N-H); R7 covers .gitmodules.
# HOW: drives the predictor's selftest over a synthetic repo of twenty-five gates (since 14z-200), one per reader class
#   plus the seven of #188 option B's two narrowings (14z-190), with known answers; twelve controls run copies
#   with one rule removed (directory, whole-tree, data, template, git), `--` read as a comment outside Lua
#   (battery_reach.is_comment), binaries read as text, either narrowing switched off, or N-B's quoted-literal
#   clause dropped, its prose strings paired across code, or R6 directory templates read as one component, and each must fail the selftest.
# EXPECTS: the selftest's cases pass (twenty-three changed paths since 14z-200, plus the eight drop_scratch cases) and every control fails on its copy. The HISTORY
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
# MUST-FIRE: perturbed-copy: r3-prose-off — a copy whose R3 searches every text (python identifiers and prose strings included) must mark the gate that echoes "the control tests nothing" stale for a tests/ change, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: r3-joined-off — a copy whose R3 reads a directory joined to a further literal (`"docs" / "sums.txt"`) as the directory must mark that gate stale for docs/other.md, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: r3c-off — a copy without R3c must carry the gate whose sibling program lists `os.path.join(HERE, "sibdata")` for a change under tools/sibdata, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: sibling-off — a copy whose reach does not close over sibling programs must carry that same gate, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: shdef-off — a copy whose R3 does not read a directory named as a shell default (`${1:-rel/m23/mame}`) must carry that gate for a change under rel/m23/mame, and the selftest must FAIL (mode: that copy's selftest; the 9 reads the #269 "C first" trace found N-C missing, 14z-200)
# MUST-FIRE: perturbed-copy: list-git-off — a copy without R4's list form must carry the gate whose python runs ["git", "-C", ".", "ls-files"], and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: scratch-off — a copy whose change set keeps build/agent<N>/ scratch must mark the `"build/$b"` template gate stale for it, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: md-narrow-off — a copy whose N-B covers STATE.md only must mark the gate that only echoes CLAUDE.md in a message stale, and the selftest must FAIL (mode: that copy's selftest; #286 (a))
# MUST-FIRE: perturbed-copy: data-position-off — a copy without N-E must mark g_reg stale for notes/ruled.md, which its data file mentions only in prose, and the selftest must FAIL (mode: that copy's selftest; #286 (a))
# MUST-FIRE: perturbed-copy: runs-data-off — a copy without N-F must make the run manifest data of g_mani, which names `manifest.tsv` only in a message, and the selftest must FAIL (mode: that copy's selftest; #286 (a))
# MUST-FIRE: perturbed-copy: runs-change-off — a copy without N-F-CHANGE must mark g_mani stale for a new run's manifest.tsv, which it names only by basename, and the selftest must FAIL (mode: that copy's selftest; #286 (a))
# MUST-FIRE: perturbed-copy: runs-link-off — a copy without N-F-LINK must carry g_runlink, whose data file links a run record by path, for that record, and the selftest must FAIL (mode: that copy's selftest; 14z-206, test_tickets' traced read)
# MUST-FIRE: perturbed-copy: runs-link-basename — a copy whose N-F-LINK counts a basename must mark g_runlink stale for another run's verdict.txt, and the selftest must FAIL (mode: that copy's selftest; 14z-206)
# MUST-FIRE: perturbed-copy: recursive-off — a copy whose N-G ignores a recursive walk must carry g_testswalk, which rglobs `tests`, for a ledger change, and the selftest must FAIL (mode: that copy's selftest; the PILOT trace's 2,225 test_docshape reads, 14z-202)
# MUST-FIRE: perturbed-copy: recursive-loose — a copy whose RECURSIVE test matches the word `find` and markdown `**` must keep g_testslink, an `ls tests` lister whose message says "**not** find", stale for a ledger change, and the selftest must FAIL (mode: that copy's selftest; 14z-202)
# MUST-FIRE: perturbed-copy: whole-coarse-off — a copy whose R4 counts every `os.walk(`, `.rglob(` and `find .` as whole-tree (N-H off) must mark g_cdfind and g_walksub stale for every change, and the selftest must FAIL (mode: that copy's selftest; #286 (a))
# MUST-FIRE: perturbed-copy: lsf-scope-off — a copy whose `git ls-files` ignores its pathspecs (N-I off, 14z-203, #286) must mark g_lsglob and g_lsdir stale for every change, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: walks-dir-loose — a copy whose N-G exception is cancelled by any recursive walk in the reach (N-J off, 14z-203, #286) must mark g_cdwalk and g_subwalk stale on the ledger, and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: runs-self-off — a copy whose N-F counts the planner's own `rulecheck/runs` (14z-203, #286) must mark g_planner stale on a run record's own change (the fixture run's packet.md and manifest.tsv), and the selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: runs-dir-off — a copy without N-G must mark the bare `tests` lister g_pylist stale for a new run record, and the selftest must FAIL (mode: that copy's selftest; #286 (a))
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
    "no-dir-rule": ("    for d, kind, rx in dps:   # N-C: R3 by kind; a bare token counts only outside python and outside prose", "    for d, kind, rx in []:  # CONTROL no-dir-rule"),
    "r3-prose-off": ('        hay = r3_blob(root, rch, blob) if kind == "bare" else blob', "        hay = blob  # CONTROL r3-prose-off"),
    "r3-joined-off": ('JOINED_LIT = r"', 'JOINED_LIT = "" and r"'),
    "r3c-off": ('    for d in [x for x, _, _ in dps if "/" in x]:', "    for d in []:  # CONTROL r3c-off"),
    "sibling-off": ("            for m in SIBLING_PROG.finditer(text(root, p)):", "            for m in []:  # CONTROL sibling-off"),
    "shdef-off": ("        pats.append((d, \"lit\", re.compile(r\"(?:(?<=:[-=+?])", "        None and pats.append((d, \"lit\", re.compile(r\"(?:(?<=:[-=+?])"),   # CONTROL shdef-off: never appended
    "list-git-off": ('r"|[\\"\']git[\\"\']\\s*,\\s*(?:', 'r"|NEVER[\\"\']git[\\"\']\\s*,\\s*(?:'),
    "scratch-off": ("    return bool(SCRATCH.match(c))", "    return False  # CONTROL scratch-off"),
    "no-whole-rule": ("        if not why and changed and any(whole_covers(blob, c) for c in changed):   # N-I: per changed path", "        if False:  # CONTROL no-whole-rule"),
    "no-data-rule": ("    for d in data_files(root, blob):", "    for d in []:  # CONTROL no-data-rule"),
    "no-template-rule": ("    for rx, tok, is_path in templates(root, blob):", "    for rx, tok, is_path in []:  # CONTROL no-template-rule"),
    "no-git-rule": ('    if base in (".gitignore", ".gitattributes", ".gitmodules") and GIT_RUN.search(blob):', "    if False:  # CONTROL no-git-rule"),
    "md-narrow-off": ('return tuple.__contains__(self, b) or str(b).endswith(".md")   # N-B-MD', "return tuple.__contains__(self, b)  # CONTROL md-narrow-off"),
    "data-position-off": ("        if (c in t or (bpat and base in t)) and data_names(t, c, bpat):   # N-E", "        if c in t or (bpat and base in t and bpat.search(t)):  # CONTROL data-position-off"),
    "runs-data-off": ('            if f.startswith(RUNS_DATA) and not runs_reader:   # N-F', "            if False:  # CONTROL runs-data-off"),
    "runs-change-off": ("    if c.startswith(RUNS_DATA) and not reader:   # N-F-CHANGE", "    if False:  # CONTROL runs-change-off"),
    "runs-link-off": ("        return run_link(root, blob, c)   # N-F-LINK", "        return None  # CONTROL runs-link-off"),
    "runs-link-basename": ("        if f != c and c in t and data_names(t, c, None):", "        if f != c and data_names(t, c, patterns(c)[0]):  # CONTROL runs-link-basename"),
    "recursive-loose": ('RECURSIVE = re.compile(r"os', 'RECURSIVE = re.compile(r"\\bfind\\s|\\*\\*|os'),
    "whole-coarse-off": ('        hit = m.group(0)\n        if hit.startswith("os.walk("):   # N-H', '        hit = m.group(0)\n        return {ALL}  # CONTROL whole-coarse-off\n        if hit.startswith("os.walk("):   # N-H'),
    "lsf-scope-off": ('            return _lsf_scopes(t, m)', '            return {ALL}  # CONTROL lsf-scope-off'),
    "walks-dir-loose": ('    bare = re.compile(r"(?<![\\w.-])" + re.escape(d)', '    return bool(RECURSIVE.search("\\n".join(text(root, p) for p in rch)))  # CONTROL walks-dir-loose\n    bare = re.compile(r"(?<![\\w.-])" + re.escape(d)'),
    "runs-self-off": ('    return any("rulecheck/runs" in text(root, p) for p in rch if p != "tools/static_confirm.py")', '    return any("rulecheck/runs" in text(root, p) for p in rch)  # CONTROL runs-self-off'),
    "runs-dir-off": ("                and not walks_dir(root, rch, d)):   # N-G, N-J", "                and False):  # CONTROL runs-dir-off"),
    "recursive-off": ("                and not walks_dir(root, rch, d)):   # N-G, N-J", "                ):  # CONTROL recursive-off"),
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
    for c in no-dir-rule no-whole-rule no-data-rule no-template-rule no-git-rule dashdash-comment binary-as-text narrow-build-off narrow-state-off narrow-literal-blind prose-pairing dir-template-off r3-prose-off r3-joined-off r3c-off sibling-off shdef-off list-git-off scratch-off md-narrow-off data-position-off runs-data-off runs-change-off runs-link-off runs-link-basename runs-dir-off recursive-off recursive-loose whole-coarse-off lsf-scope-off walks-dir-loose runs-self-off; do
        python3 "$(make_copy "$c")" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 'FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: the predictor marks STALE by each of its seven rules, narrows as #188 option B and #286 (a) rule, and carries the rest"
else echo "FAIL: test_static_confirm"; exit 1; fi
