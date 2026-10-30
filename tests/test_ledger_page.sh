#!/bin/sh
# test_ledger_page.sh — the public session ledger page carries the datasets whole, withholds the maintainer's own
# figures, fetches nothing, and is published as one orphan commit on gh-pages (GitHub #267, 14z-212).
#
# WHAT: tools/ledger_page.py embeds every dataset `tools/session_metrics.py collect` wrote, minus the figures ruled
#   private ("All but your own figures", 2026-10-29: maint_msgs, maint_answers, reply_median_min), in one HTML file that
#   loads nothing from the network; tools/publish_ledger.sh --push makes it one parentless commit (index.html,
#   .nojekyll) on a remote's gh-pages, replacing the previous one under a lease.
# HOW: synthetic datasets (a private figure of each kind beside ordinary ones) -> the page; its embedded data is
#   extracted (`ledger_page.py --extract`) and compared with the datasets less the private figures; the page's text is
#   searched for any way to fetch (a URL, src=, <link, @import, url(, fetch(, XMLHttpRequest); then the publish script
#   runs twice against a throwaway bare repository (one more figure the second time) and the branch must hold one
#   parentless commit whose index.html is the page built, the second replacing the first;
#   every curated worked example (tests/rulecheck/catches.tsv) is embedded. Four controls.
# EXPECTS: data equal; 0 private figures; 0 fetch constructs; gh-pages a single parentless commit holding exactly
#   index.html, ledger.css, ledger.js and .nojekyll, the page equal to the build, after the second publish too; no
#   inline script or style (a 'self'-only Content-Security-Policy serves it: the maintainer's own site's).
# NOT TESTED: how a browser renders the page — tools/ledger_csp_check.sh does that by hand, under a given policy (14z-212:
#   the maintainer's site policy, 0 refusals); the real collect (its own
#   gate is tests/test_session_metrics.sh); a push to GitHub.
#
# MUST-FIRE: shadow-tool: private-kept — a copy of tools/ledger_page.py whose PRIVATE list is empty must embed the maintainer's figures, and the private check must FAIL (mode: the gate reads that copy)
# MUST-FIRE: perturbed-copy: catch-unknown-run — a copy of tests/rulecheck/catches.tsv with one more row naming a run the ledger does not hold must make tools/ledger_page.py refuse to build (exit non-zero, naming the row), so a worked example always quotes a real run (in-gate: that copy is built; mode: the gate builds the page from it)
# MUST-FIRE: perturbed-copy: inline-script — a copy of the built index.html with one inline <script> added must be named by the inline check, which must FAIL: a strict Content-Security-Policy would refuse it (in-gate: that copy is checked; mode: the gate checks that copy instead of the page)
# MUST-FIRE: perturbed-copy: external-fetch — a copy of the built page with one <script src="https://..."> added must be named by the fetch check, which must FAIL (in-gate: that copy is checked; mode: the gate checks that copy instead of the page)
#
# Usage: tests/test_ledger_page.sh      # ci_portable, ~2 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d "${TMPDIR:-/tmp}/ledgerpage.XXXXXX")"   # set -e stops here when mktemp fails (#333)
trap 'rm -rf "$W"' EXIT
fail=0
TOOL=tools/ledger_page.py

# ---- the synthetic datasets
mkdir -p "$W/data"
python3 - "$W/data" <<'PY'
import json, sys, os
d = sys.argv[1]
f = lambda s, m, v, c="MEASURED": {"session": s, "section": "time", "metric": m, "label": m, "value": v, "unit": "",
                                   "class": c, "source": "src", "rule": "" if c == "MEASURED" else "r"}
json.dump([f("14z-1", "rc_runs", 3), f("14z-1", "maint_msgs", 7), f("14z-1", "maint_answers", 2),
           f("14z-2", "reply_median_min", 4.5, "DERIVED"), f("14z-2", "span_h", 1.5, "DERIVED")], open(os.path.join(d, "figures.json"), "w"))
json.dump([{"id": "2026-01-01-01", "session": "14z-1", "decision": "build", "verdict": "OK", "plant": "CAUGHT",
            "violated": "", "subject": "s", "resolution": ""}], open(os.path.join(d, "rc_runs.json"), "w"))
json.dump([{"run": "r", "session": "14z-1", "start": "2026-01-01T00:00:00", "head": "abc", "wall_s": 9, "pass": 1,
            "fail": 0, "skip": 0, "controls": 0}], open(os.path.join(d, "tiers.json"), "w"))
json.dump([], open(os.path.join(d, "costly.json"), "w"))
json.dump([{"action": "2026-01-01-01", "session": "14z-1", "decision": "build", "first": "2026-01-01-01", "verdict": "OK",
            "violated": "", "runs": 1, "links": "NEW"}], open(os.path.join(d, "actions.json"), "w"))
PY

T="$TOOL"
if vs_ctl_is private-kept; then
    mkdir -p "$W/shadow"; sed 's/^PRIVATE = (.*)$/PRIVATE = ()/' "$TOOL" > "$W/shadow/ledger_page.py"
    grep -q '^PRIVATE = ()$' "$W/shadow/ledger_page.py" || { echo "REFUSED: the PRIVATE line was not found to empty"; exit 3; }
    T="$W/shadow/ledger_page.py"
fi

# private_check <page> — 0 when the embedded figures are the datasets' less the private ones, every other dataset whole
private_check() {
    python3 "$T" --extract "$1" > "$W/extract.json" || return 1
    python3 - "$W/extract.json" "$W/data" <<'PY'
import json, sys, os
got = json.load(open(sys.argv[1])); d = sys.argv[2]
PRIVATE = {"maint_msgs", "maint_answers", "reply_median_min"}
src = {n: json.load(open(os.path.join(d, n + ".json"))) for n in ("figures", "rc_runs", "tiers", "costly", "actions")}
leaked = [f["metric"] for f in got["figures"] if f["metric"] in PRIVATE]
if leaked: print("  private figures embedded: " + " ".join(leaked)); sys.exit(1)
if got["figures"] != [f for f in src["figures"] if f["metric"] not in PRIVATE]: print("  the figures differ"); sys.exit(1)
for n in ("rc_runs", "tiers", "costly", "actions"):
    if got[n] != src[n]: print("  dataset " + n + " differs"); sys.exit(1)
PY
}
# fetch_check <page dir> — 0 when no file of the page holds a construct that loads anything but the page's own two files
# (exactly `<link rel="stylesheet" href="ledger.css">` and `<script src="ledger.js">` are stripped first, and the SVG
# namespace name http://www.w3.org/2000/svg, an identifier never fetched)
fetch_check() { ! cat "$1/index.html" "$1/ledger.css" "$1/ledger.js" \
    | sed -e 's#http://www\.w3\.org/2000/svg##g' -e 's#<link rel="stylesheet" href="ledger\.css">##' -e 's#<script src="ledger\.js"></script>##' \
    | grep -nE 'https?://|src=|<link|@import|url\(|fetch\(|XMLHttpRequest'; }
# csp_check <page dir> — 0 when index.html carries no inline script or style, so `script-src 'self'; style-src 'self'`
# serves it (the maintainer's own site's policy): no <style>, no style= attribute, no <script> with a body but the data block
csp_check() { python3 - "$1/index.html" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
bad = re.findall(r"<style|\sstyle=|\son[a-z]+=", s)
bad += [m for m in re.findall(r"<script(?![^>]*\bsrc=)(?![^>]*application/octet-stream)[^>]*>", s)]
if bad: print("  inline: " + " ".join(sorted(set(bad)))); sys.exit(1)
PY
}

echo "== test_ledger_page: #267 — the public session ledger page =="
CATCHES=tests/rulecheck/catches.tsv
if vs_ctl_is catch-unknown-run; then cp "$CATCHES" "$W/catches.tsv"; printf '2099-01-01-01\theadline\twhy\n' >> "$W/catches.tsv"; CATCHES="$W/catches.tsv"; fi
python3 "$T" "$W/data" --out "$W/page" --catches "$CATCHES" > "$W/build.log" 2>&1 || { echo "  FAIL  the page did not build: $(tail -1 "$W/build.log")"; echo "FAIL: test_ledger_page"; exit 1; }
n_cur="$(grep -c '^20' tests/rulecheck/catches.tsv)"
n_emb="$(python3 "$T" --extract "$W/page/index.html" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["catches"]))')"
if [ "$n_cur" = "$n_emb" ] && [ "$n_cur" -ge 1 ]; then echo "  ok    every curated worked example ($n_cur) is embedded, quoted from its run"
else echo "  FAIL  worked examples: $n_emb embedded, $n_cur curated"; fail=1; fi
if private_check "$W/page/index.html" > "$W/pc.txt"; then echo "  ok    the embedded data is the datasets', less the maintainer's own figures"
else echo "  FAIL  embedded data:"; cat "$W/pc.txt"; fail=1; fi
P="$W/page"
if vs_ctl_is external-fetch; then cp -R "$W/page" "$W/ext"; printf '<script src="https://example.invalid/x.js"></script>\n' >> "$W/ext/index.html"; P="$W/ext"; fi
if fetch_check "$P" > "$W/fc.txt"; then echo "  ok    the page fetches nothing but its own two files (no URL, other src=, <link, @import, url(, fetch()"
else echo "  FAIL  the page can fetch: $(head -1 "$W/fc.txt" | cut -c1-120)"; fail=1; fi
C="$W/page"
if vs_ctl_is inline-script; then rm -rf "$W/inl"; cp -R "$W/page" "$W/inl"; printf '<script>document.title="x"</script>\n' >> "$W/inl/index.html"; C="$W/inl"; fi
if csp_check "$C" > "$W/csp.txt"; then echo "  ok    no inline script or style: a 'self'-only Content-Security-Policy serves it"
else echo "  FAIL  $(cat "$W/csp.txt")"; fail=1; fi

# ---- publishing, twice, into a throwaway bare repository
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@test GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@test   # commit-tree needs an identity
git init -q --bare "$W/remote.git"
git -C "$W" init -q pub
git -C "$W/pub" remote add origin "$W/remote.git"
pub_ok() {  # pub_ok <n> — publish, then the branch must be one parentless commit: the page's three files (= the build) + .nojekyll
    sh tools/publish_ledger.sh --data "$W/data" --out "$W/out" --repo "$W/pub" --push > "$W/pub$1.log" 2>&1 || { echo "the publish failed: $(tail -1 "$W/pub$1.log")"; return 1; }
    _c="$(git -C "$W/remote.git" rev-parse refs/heads/gh-pages)" || { echo "no gh-pages"; return 1; }
    [ "$(git -C "$W/remote.git" rev-list --count "$_c")" = 1 ] || { echo "gh-pages is not one parentless commit"; return 1; }
    [ "$(git -C "$W/remote.git" ls-tree --name-only "$_c" | tr '\n' ' ')" = ".nojekyll index.html ledger.css ledger.js " ] || { echo "files: $(git -C "$W/remote.git" ls-tree --name-only "$_c" | tr '\n' ' ')"; return 1; }
    for _f in index.html ledger.css ledger.js; do
        git -C "$W/remote.git" show "$_c:$_f" | cmp -s - "$W/out/site/$_f" || { echo "$_f is not the page built"; return 1; }
    done
    echo "$_c"
}
# the second publish carries one more figure, so its page (and commit) differs and must REPLACE the first
more() { python3 -c "
import json, sys; p = sys.argv[1] + '/figures.json'; r = json.load(open(p)); r.append(dict(r[0], metric='more')); json.dump(r, open(p, 'w'))" "$W/data"; }
if c1="$(pub_ok 1)" && more && c2="$(pub_ok 2)" && [ "$c1" != "$c2" ]; then
    echo "  ok    published twice: gh-pages is one parentless commit holding the page, replaced under a lease"
else echo "  FAIL  publishing: ${c2:-${c1:-}}"; fail=1; fi

# ---- the own-site upload: to a local folder standing for the webroot; refused with no DEPLOY_TARGET
mkdir -p "$W/web"
if DEPLOY_TARGET="$W/web/" sh tools/publish_ledger.sh --data "$W/data" --out "$W/own" --own-site > "$W/own.log" 2>&1 \
   && cmp -s "$W/web/vs-swarm-ledger/index.html" "$W/own/site/index.html" && [ -f "$W/web/vs-swarm-ledger/ledger.js" ] && [ -f "$W/web/vs-swarm-ledger/ledger.css" ]; then
    echo "  ok    --own-site puts the page's three files in <DEPLOY_TARGET>vs-swarm-ledger/"
else echo "  FAIL  --own-site: $(tail -1 "$W/own.log")"; fail=1; fi
if env -u DEPLOY_TARGET sh tools/publish_ledger.sh --data "$W/data" --out "$W/own2" --own-site > "$W/own2.log" 2>&1; then
    echo "  FAIL  --own-site ran with no DEPLOY_TARGET"; fail=1
elif grep -q "needs DEPLOY_TARGET" "$W/own2.log" && [ ! -d "$W/own2/site" ]; then echo "  ok    --own-site with no DEPLOY_TARGET is refused before anything is built"
else echo "  FAIL  --own-site with no DEPLOY_TARGET: $(tail -1 "$W/own2.log")"; fail=1; fi
if env -u DEPLOY_TARGET sh tools/publish_ledger.sh --data "$W/data" --out "$W/own3" --own-site-if-set > "$W/own3.log" 2>&1 \
   && grep -q "SKIPPED the own site" "$W/own3.log" && [ -f "$W/own3/site/index.html" ]; then
    echo "  ok    --own-site-if-set with no DEPLOY_TARGET skips the own site, says so, and builds the page"
else echo "  FAIL  --own-site-if-set with no DEPLOY_TARGET: $(tail -1 "$W/own3.log")"; fail=1; fi
rm -rf "$W/web/vs-swarm-ledger"
if DEPLOY_TARGET="$W/web/" sh tools/publish_ledger.sh --data "$W/data" --out "$W/own4" --own-site-if-set > "$W/own4.log" 2>&1 \
   && [ -f "$W/web/vs-swarm-ledger/index.html" ]; then echo "  ok    --own-site-if-set with DEPLOY_TARGET set uploads as --own-site"
else echo "  FAIL  --own-site-if-set with DEPLOY_TARGET set: $(tail -1 "$W/own4.log")"; fail=1; fi

if [ -z "${VS_CTL:-}" ]; then
    mkdir -p "$W/sh"; sed 's/^PRIVATE = (.*)$/PRIVATE = ()/' "$TOOL" > "$W/sh/ledger_page.py"
    if grep -q '^PRIVATE = ()$' "$W/sh/ledger_page.py"; then
        python3 "$W/sh/ledger_page.py" "$W/data" --out "$W/sh" > /dev/null
        if T="$W/sh/ledger_page.py" private_check "$W/sh/index.html" > "$W/sh.txt"; then vs_ctl_dead private-kept "the copy with no PRIVATE list passed the check" || fail=1
        elif grep -q "private figures embedded: maint_msgs maint_answers reply_median_min" "$W/sh.txt"; then vs_ctl_fired private-kept "$(head -1 "$W/sh.txt" | sed 's/^ *//')"
        else vs_ctl_dead private-kept "the check failed for another reason: $(head -1 "$W/sh.txt")" || fail=1; fi
    else vs_ctl_dead private-kept "the PRIVATE line was not found to empty" || fail=1; fi
    cp tests/rulecheck/catches.tsv "$W/cu.tsv"; printf '2099-01-01-01\theadline\twhy\n' >> "$W/cu.tsv"
    if python3 "$TOOL" "$W/data" --out "$W/cu" --catches "$W/cu.tsv" > "$W/cu.log" 2>&1; then vs_ctl_dead catch-unknown-run "a worked example naming an unknown run was built" || fail=1
    elif grep -q "catches row 2099-01-01-01" "$W/cu.log"; then vs_ctl_fired catch-unknown-run "$(tail -1 "$W/cu.log" | cut -c1-100)"
    else vs_ctl_dead catch-unknown-run "refused for another reason: $(tail -1 "$W/cu.log")" || fail=1; fi
    rm -rf "$W/inl"; cp -R "$W/page" "$W/inl"; printf '<script>document.title="x"</script>\n' >> "$W/inl/index.html"
    if csp_check "$W/inl" > "$W/inl.txt"; then vs_ctl_dead inline-script "a page with an inline script passed" || fail=1
    else vs_ctl_fired inline-script "$(head -1 "$W/inl.txt" | sed 's/^ *//')"; fi
    rm -rf "$W/ext"; cp -R "$W/page" "$W/ext"; printf '<script src="https://example.invalid/x.js"></script>\n' >> "$W/ext/index.html"
    if fetch_check "$W/ext" > "$W/ext.txt"; then vs_ctl_dead external-fetch "a page with an external script passed" || fail=1
    else vs_ctl_fired external-fetch "the planted script is named: $(head -1 "$W/ext.txt" | cut -c1-80)"; fi
fi

if [ "$fail" = 0 ]; then echo "PASS: the ledger page carries the data whole, withholds the maintainer's figures, fetches nothing, publishes as one commit"
else echo "FAIL: test_ledger_page"; exit 1; fi
