#!/bin/sh
# test_applier_page_browser.sh — THE APPLIER PAGE IN A REAL BROWSER ENGINE (2026-09-21).
#
# WHAT: the shipped applier page RUNS where a player runs it — opened from file:// in a real
#   browser engine and driven through its own drop zone, radio and button: a build prints
#   the manifest's set key, 'leave it out' stops the qsound demand and builds to the other
#   key, a damaged dump is refused by name.
# HOW: headless Chrome drives page_test.html (the shipped file as a byte-prefix plus
#   tests/lib/applier_driver.html) with the maintainer's dumps; an incomplete run is its own
#   verdict, never a content verdict; controls starve the control leg's virtual-time budget
#   and flip a byte of the inlined set key.
# EXPECTS: the three player paths as described; the starved control reads NOT JUDGED, the
#   broken page fails. A stalled driver retries once for incompleteness only, never for a
#   content failure.
#
# tests/test_applier_page.sh proves the page's MODULES equal tools/apply_release.py under
# node, and that the page carries those modules verbatim. This gate answers the other
# half, which node cannot: does the shipped HTML actually RUN where a player runs it —
# opened from `file://`, driven through its own drop zone, radio and button?
#
# That question is not rhetorical. Measured 2026-09-21, a page opened from file:// is
# refused fetch, XHR and cross-file `import` by Chrome and Firefox alike, which is why
# the page is one self-contained file; a gate that only ran the modules under node would
# have said nothing about it. docs/project/applier_app_scope.md §3 left exactly this
# open: "confirming deflate-raw and crypto.subtle behave in real browsers as they did
# under node ... is part of A2, not something this document has already banked."
#
# WHAT IT DRIVES, as a player would, touching no private binding of the page:
#   (a) read the list of dumps THE PAGE asks for, drop them, build — the OK panel must
#       appear and print the set key the manifest declares;
#   (b) tick "leave it out" — the page must stop ASKING for qsound_hle.zip (A4 is about
#       the demand, not just the output) and must build to the other declared key;
#   (c) drop a damaged dump — the refusal panel must appear and NAME the file.
#
# The page under test is the shipped bytes verbatim: page_test.html is
# `cat apply_release.html tests/lib/applier_driver.html`, and the gate asserts the
# shipped file is a byte-prefix of it. `--allow-file-access-from-files` is given to the
# BROWSER so the driver can hand the page its input; the page itself never reads a file
# from disk, which is section 1 of the sibling gate.
#
# MUST-FIRE: perturbed-copy: starved-control-leg — the control leg run with a 1 ms virtual-time budget cannot complete, and the gate must report the control as NOT JUDGED (FAIL) — never as a page verdict, which is what it printed under 14z-176's loaded tier (mode: the gate starves its control leg)
# MUST-FIRE: perturbed-copy: broken-page — a copy of the page with one byte of its inlined manifest's declared set key changed must make the browser run FAIL, because the page would then build a set it cannot vouch for; if the run still passed, the gate would not be reading the page's verdict at all (mode: the gate drives that copy)
#
# Usage: ROMDIR=... tests/test_applier_page_browser.sh [release/merged-m20/fbneo]   # ci_static
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REL="${1:-release/merged-m20/fbneo}"
[ -f "$REL/manifest.json" ] || { echo "SKIP: no release manifest at $REL"; exit 0; }

CHROME="${CHROME_BIN:-}"
if [ -z "$CHROME" ]; then
    for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
             "/Applications/Chromium.app/Contents/MacOS/Chromium" \
             "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
             google-chrome chromium chromium-browser microsoft-edge; do
        if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
    done
fi
[ -n "$CHROME" ] || { echo "SKIP: no Chrome/Chromium/Edge on this host (set CHROME_BIN); the page's node-side fidelity is tests/test_applier_page.sh"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fails=0
note() { echo "  $*"; }

python3 tools/gen_applier_page.py "$REL" -o "$W/apply_release.html" | sed 's/^/  /'

# THE PERTURBATION, as one function the control section and the mode both call:
# change the set key the page carries, so the page builds the right bytes and then
# correctly refuses to vouch for them. It is the page's LAST check, and the only one
# that a browser run can exercise without touching the player's dumps.
break_page() {   # $1 = source page, $2 = destination
    python3 - "$1" "$2" <<'PY'
import re, sys
src, dst = sys.argv[1:3]
s = open(src).read()
m = re.search(r'"applied_set_key":"([0-9a-f]{40})"', s)
if not m:
    sys.exit("the page does not carry an applied_set_key to perturb")
old = m.group(1)
new = ("0" if old[0] != "0" else "1") + old[1:]
open(dst, "w").write(s.replace(f'"applied_set_key":"{old}"', f'"applied_set_key":"{new}"', 1))
print(f"  CONTROL: the page's declared set key changed {old[:8]} -> {new[:8]}")
PY
}

PAGE="$W/apply_release.html"
if vs_ctl_is broken-page; then
    break_page "$W/apply_release.html" "$W/page_broken.html"
    PAGE="$W/page_broken.html"
fi

# THE PAGE UNDER TEST IS THE SHIPPED FILE, loaded as its own document. The driver is a
# SEPARATE page that iframes it — nothing is appended to it and its Content-Security-Policy
# is intact during the run, which a concatenated driver would have to dilute to work
# (measured 2026-09-21: a driver inside the document cannot fetch, because `connect-src
# 'none'` stops it — the CSP doing its job).
mkdir -p "$W/run"
cp "$PAGE" "$W/run/apply_release.html"
cp tests/lib/applier_driver.html "$W/run/driver.html"
if cmp -s "$PAGE" "$W/run/apply_release.html"; then
    note "ok: the browser loads the page byte for byte, as its own document"
else
    note "the copy under test is not the page"; fails=$((fails + 1))
fi
if grep -q 'http-equiv="Content-Security-Policy"' "$W/run/apply_release.html"; then
    note "ok: the page carries its Content-Security-Policy into the run"
else
    note "the page under test carries no Content-Security-Policy"; fails=$((fails + 1))
fi

# the player's dumps, and one damaged copy for the refusal leg
mkdir -p "$W/run/roms" "$W/run/broken"
FIRST=""
for z in $(python3 -c "
import json
m = json.load(open('$REL/manifest.json'))
zs = list(m['source']['order']) + [s['zip'] for s in m.get('pristine_sources', [])]
print(' '.join(dict.fromkeys(zs)))"); do
    [ -f "$ROMDIR/$z" ] || { echo "SKIP: \$ROMDIR has no $z"; exit 0; }
    cp "$ROMDIR/$z" "$W/run/roms/$z"
    [ -n "$FIRST" ] || FIRST="$z"
done
python3 - "$W/run/roms/$FIRST" "$W/run/broken/$FIRST" <<'PY'
import sys, zipfile
src, dst = sys.argv[1:3]
zi = zipfile.ZipFile(src)
target = sorted(zi.namelist())[0]
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zo:
    for n in zi.namelist():
        d = bytearray(zi.read(n))
        if n == target:
            d[0] ^= 0x01
        zo.writestr(n, bytes(d))
PY
note "driving the page from file:// with $(basename "$CHROME")"

# --virtual-time-budget is what makes --dump-dom wait for the page's async work; the
# driver's waits are MutationObservers precisely so they do not spend that budget.
# WARM THE READS FIRST: the driver fetches ~48 MB over file://, and virtual time
# advances while the renderer waits on a cold cache. This does not make the race
# impossible, which is why the retry below exists — it makes it rare.
for _z in "$W/run/roms"/*.zip "$W/run/broken"/*.zip; do [ -f "$_z" ] && cat "$_z" > /dev/null 2>&1 || true; done
drive() {   # drive <dom-output> — one browser run
    "$CHROME" --headless --disable-gpu --no-sandbox --allow-file-access-from-files \
        --virtual-time-budget="${BUDGET:-1800000}" --dump-dom "file://$W/run/driver.html" \
        > "$1" 2>"$W/chrome.err" || true
}
verdict_of() {   # pull the driver's <pre id="verdict"> block out of a dumped DOM
    python3 - "$1" <<'PY'
import html, re, sys
s = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r'<pre id="verdict">(.*?)</pre>', s, re.S)
if not m:
    sys.exit(0)
print(html.unescape(m.group(1)).strip())
PY
}
# run_leg <name> — one browser run into $W/<name>.txt, with ONE retry, and only for an
# INCOMPLETE run — never for a content failure, which is a real verdict and must not be
# re-rolled until it passes. BOTH legs use it: until 14z-176 the in-gate control drove
# Chrome once with no such handling, so an incomplete control run under a loaded tier
# printed "CONTROL DEAD … still reached an ok panel" for a run that had measured no
# panel at all — the 14z-174 lie, surviving in the leg the 14z-174 fix did not touch.
run_leg() {
    drive "$W/$1_dom.html"
    verdict_of "$W/$1_dom.html" > "$W/$1.txt" || true
    if ! grep -q '^DONE=1$' "$W/$1.txt" 2>/dev/null; then
        note "incomplete browser run ($1, no DONE=1) — retrying once with the reads warm"
        drive "$W/$1_dom2.html"
        verdict_of "$W/$1_dom2.html" > "$W/$1_2.txt" || true
        if grep -q '^DONE=1$' "$W/$1_2.txt" 2>/dev/null; then
            mv "$W/$1_2.txt" "$W/$1.txt"; note "  the retry completed"
        else
            note "  the retry did not complete either"
        fi
    fi
}
run_leg verdict
if [ ! -s "$W/verdict.txt" ]; then
    note "the browser produced no verdict at all"
    tail -5 "$W/chrome.err" | sed 's/^/    /'
    echo "FAIL: test_applier_page_browser"; exit 1
fi
sed 's/^/    /' "$W/verdict.txt"

get() { grep -m1 "^$1=" "$W/verdict.txt" | cut -d= -f2-; }
WANT_KEY="$(python3 -c "import json; print(json.load(open('$REL/manifest.json'))['applied_set_key'][:8])")"
WANT_KEY_NB="$(python3 -c "import json; print((json.load(open('$REL/manifest.json')).get('applied_set_key_no_qsound_bios') or '')[:8])")"
check() {   # label, got, want
    if [ "$2" = "$3" ]; then note "ok: $1 = $2"; else note "$1: got '$2', expected '$3'"; fails=$((fails + 1)); fi
}
# AN INCOMPLETE BROWSER RUN IS NOT A PAGE DEFECT, and must not be reported as one.
# Before this (measured 14z-174, one flake in a close tier), a driver that stalled
# during its 48 MB of file:// reads printed EIGHT content-shaped failures — "standalone
# panel: got '', expected 'ok'" and so on — for a run that had measured no content at
# all. That is a gate lying about what it saw, which is #171's own subject.
# MECHANISM: --virtual-time-budget ADVANCES while the renderer sits idle waiting on
# I/O, so a cold page cache lets the budget expire mid-load and Chrome dumps the DOM
# early. The reads are warmed below and the run is retried once; twice incomplete is a
# real failure, and it is reported as an INCOMPLETE RUN with no content verdict claimed.
if [ "$(get DONE)" != "1" ]; then
    note "THE BROWSER RUN DID NOT COMPLETE — the driver stopped after: $(tail -1 "$W/verdict.txt" | cut -c1-60)"
    _de="$(get DRIVER_ERROR)"; note "  driver error: ${_de:-(none — it stalled silently)}"
    note "  NO CONTENT VERDICT IS CLAIMED from this run: the checks below are not evaluated."
    echo "FAIL: test_applier_page_browser (the browser run did not complete; page NOT judged)"
    exit 1
fi
check "(a) standalone panel" "$(get standalone_panel)" "ok"
check "(a) standalone set key" "$(get standalone_setkey)" "$WANT_KEY"
check "(a) download offered" "$(get standalone_download)" "vsavjw.zip"
check "(b) no-BIOS panel" "$(get nobios_panel)" "ok"
check "(b) no-BIOS set key" "$(get nobios_setkey)" "$WANT_KEY_NB"
check "(c) a damaged dump is refused" "$(get refusal_panel)" "bad"
check "(c) the refusal names the file" "$(get refusal_named_it)" "yes"
case "$(get nobios_asks_for)" in
    *qsound_hle*) note "(b) the page still asks for qsound_hle.zip with the member left out"; fails=$((fails + 1)) ;;
    "") note "(b) no asks_for line"; fails=$((fails + 1)) ;;
    *) note "ok: (b) with the member left out the page stops asking for qsound_hle.zip" ;;
esac

if vs_ctl_is broken-page; then
    if [ "$fails" = 0 ]; then
        vs_ctl_dead broken-page "a page declaring the wrong set key still passed the browser run" || true
        echo "FAIL: test_applier_page_browser"; exit 1
    fi
    vs_ctl_fired broken-page "the page with a changed declared set key does not reach an ok panel: standalone_panel=$(get standalone_panel)"
    echo "FAIL: test_applier_page_browser (control mode: the broken page was correctly caught)"
    exit 1
fi

[ "$fails" = 0 ] || { echo "FAIL: test_applier_page_browser ($fails check(s))"; exit 1; }

# judge_ctl <verdict file> — the ONE reading of a control leg, used by the real control
# and by starved-control-leg: prints `fired`, `incomplete` or `dead` and a detail. An
# INCOMPLETE run is never read as a page verdict (14z-176: the old reading printed "still
# reached an ok panel" for a run that had measured no panel at all)
judge_ctl() {
    if ! grep -q '^DONE=1$' "$1"; then
        echo "incomplete the driver stopped after: $(tail -1 "$1" | cut -c1-60)"
    elif [ "$(grep -m1 '^standalone_panel=' "$1" | cut -d= -f2-)" = "bad" ]; then
        echo "fired $(grep -m1 '^standalone_text=' "$1" | cut -c17-92)"
    else
        echo "dead standalone_panel='$(grep -m1 '^standalone_panel=' "$1" | cut -d= -f2-)', not bad"
    fi
}

# the control, in-gate — through the same run_leg and judge_ctl, so an INCOMPLETE control
# run is reported as one and never as a verdict about the page
break_page "$W/apply_release.html" "$W/run/apply_release.html"
if vs_ctl_is starved-control-leg; then BUDGET=1; fi
run_leg ctl
BUDGET=
_j="$(judge_ctl "$W/ctl.txt")"
case "$_j" in
    incomplete*)
        note "THE CONTROL'S BROWSER RUN DID NOT COMPLETE (twice) — ${_j#incomplete }"
        note "  NO VERDICT ABOUT THE BROKEN PAGE IS CLAIMED; the control did not fire, which the contract reads as FAIL"
        echo "FAIL: test_applier_page_browser (the control's browser run did not complete; control NOT judged)"; exit 1 ;;
    fired*)
        vs_ctl_fired broken-page "a page declaring the wrong set key refuses instead of handing over a file: ${_j#fired }" ;;
    *)
        vs_ctl_dead broken-page "the page with a changed declared set key completed its run with ${_j#dead }" || true
        echo "FAIL: test_applier_page_browser"; exit 1 ;;
esac

# starved-control-leg, in-gate: the same broken page with the control leg STARVED (a 1 ms
# virtual-time budget cannot finish), read by the same judge_ctl — it must say INCOMPLETE.
# Reading it as `dead` or `fired` is the lie this gate told under 14z-176's loaded tier
# (docs/platform/gotchas.md); the fix is only real if this path is exercised
BUDGET=1 run_leg starved
_s="$(judge_ctl "$W/starved.txt")"
case "$_s" in
    incomplete*) vs_ctl_fired starved-control-leg "a starved control run is read as INCOMPLETE, not as a page verdict (${_s#incomplete })" ;;
    *) vs_ctl_dead starved-control-leg "a starved control run was read as '${_s%% *}' — a page verdict from a run that measured nothing" || true
       echo "FAIL: test_applier_page_browser"; exit 1 ;;
esac

echo "PASS: test_applier_page_browser — the shipped page runs from file:// in a real engine, builds both variants to the declared set keys, and refuses a damaged dump by name"
