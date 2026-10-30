#!/bin/sh
# test_proof_sheets_web.sh — THE PROOF SHEETS' WEB BUILD SHIPS NOTHING THE RULING FORBIDS (GitHub #338, 14z-213). ci_portable: no ROM, no emulator, ~5 s.
#
# WHAT: `tools/proof_sheets.py web <local run> --to <dir>` re-draws a finished local run for the community, as ruled
#   2026-10-30 (14z-212, DECISIONS_HISTORY.md "the proof sheets get a web build for the community"; the clips 14z-213:
#   "Keep, reduced, add a short description to explain that it is short and down sampled"): every picture halved by
#   Lanczos into WebP with the credit in its EXIF and no link to a full-size file; every sound clip mono at most 24 kHz
#   with a credit chunk and a "short, down-sampled" caption; a credits footer on every page; the index's provenance block
#   replaced by the plain-language intro; the "no picture shows the fighters" list moved onto each gate's page; no local
#   path, no log, no PNG anywhere; every page links the one stylesheet sheets.css, with no inline style or script, so a
#   site whose Content-Security-Policy is style-src 'self' serves it (rule-checker run 2026-10-30-1429). `proof_sheets.py webcheck` is the check every web build must pass before it ships.
# HOW: a synthetic local run under a scratch dir (one gate, two sheets, two legs, 384x224 PNG tiles, a 48 kHz stereo
#   16-bit clip, a sheet whose every picture reads "no fighter", and control-build text carrying an absolute path and a
#   session scratch path) is drawn with `web`; the output is checked file by file; `web` must refuse a non-empty --to;
#   then each perturbed copy below (the fourteen controls) must FAIL webcheck, naming the fault; then tools/publish_sheets.sh
#   publishes it into a local folder standing for the webroot (replacing what is there), and refuses with no
#   DEPLOY_TARGET and for a build that fails webcheck.
# EXPECTS: web exit 0 and webcheck PASS; the counts below; every perturbed copy FAILs webcheck on its own fault.
#
# MUST-FIRE: perturbed-copy: missing-credits — a copy of the web build with the credits footer stripped from one gate page must FAIL webcheck naming that page (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: full-size-tile — a copy with one tile replaced by a 384x224 WebP must FAIL webcheck as larger than the reduced size (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: full-size-link — a copy with a link to a full-size picture the build does not ship (a .webp, so no suffix check sees it) added to a gate page must FAIL webcheck naming the link, so no page can reach a full-size file (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: escaping-link — a copy with a link that leaves the build and lands on a real file (the fixture's own full-size clip, ../../src/pics/...wav) added to a gate page must FAIL webcheck as outside the build, so a link is held only by a file inside the build, never by any file on the drawing machine (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: log-shipped — a copy with a gate .log file added must FAIL webcheck as a file type that may not ship (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: local-path — a copy with an absolute /Users/ path written into the index must FAIL webcheck naming the path (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: unscrubbed-path — a copy with /Volumes/Disk/x, a path form the scrub's own pattern does not match, written into the index must FAIL webcheck naming the path, so webcheck does not share the scrub's blind spots (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: unreduced-clip — a copy with one clip replaced by a 48 kHz stereo WAV must FAIL webcheck as not reduced (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: inline-style — a copy with an inline <style> block added to the index must FAIL webcheck as refused by a strict Content-Security-Policy (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: style-attribute — a copy with a style= attribute added to a gate page's <body> must FAIL webcheck as refused by a strict Content-Security-Policy (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: inline-script — a copy with a <script> added to the index must FAIL webcheck as refused by a strict Content-Security-Policy (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: event-handler — a copy with an onclick= handler added to a gate page's <body> must FAIL webcheck as refused by a strict Content-Security-Policy (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: missing-stylesheet — a copy with sheets.css removed must FAIL webcheck naming the missing stylesheet (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
# MUST-FIRE: perturbed-copy: builds-sentence — a copy whose intro says "Every build matched its frozen reference." while the run has an unregistered build must FAIL `webcheck --run` naming the builds sentence (in-gate: the copy is checked; mode: the real output is perturbed and the gate FAILs)
#
# WHY: the sheets are reduced screenshots of a copyrighted game; the ruling allows them public only reduced, credited and
#   free of local paths, and a web build that quietly ships one full-size picture or one page without credits breaks it.
#   Scope `ondemand` (the maintainer, 2026-10-23: gates on the capture sheets "really should be ondemand scope").
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_proof_sheets_web — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
T="$REPO/tools/proof_sheets.py"

echo "== 1. a synthetic local run"
python3 - "$W/src" <<'PY' || { echo "FAIL: test_proof_sheets_web — the fixture could not be made"; exit 1; }
import json, os, struct, sys, wave
from PIL import Image
src = sys.argv[1]; os.makedirs(src + "/pics")
gid = "audit_landing_sound"   # a real gate, so the page reads its own verdict legend
def cell(frame, fighters="yes", pic=None):
    return {"frame": frame, "status": "PROVEN", "why": "the gate's checksum at this frame", "pic": pic or ("/tmp/x/%d.png" % frame),
            "fighters": fighters}
legs = [{"leg": "native", "role": "vs2", "set": "vsav2", "rompath": "/Users/someone/ROMS"},
        {"leg": "ours", "role": "ours", "set": "vsavjw", "rompath": "/Users/someone/tree/out/rompath"}]
s1 = {"sid": "a", "title": "sheet a", "chars": ["huitzil"], "tickets": ["#338"], "not_comparable": "the stage", "capped": [], "legs": legs,
      "cols": [{"label": "moment 1", "verdict": "IDENTICAL", "cells": {"native": cell(100), "ours": cell(100)}},
               {"label": "moment 2", "verdict": "IDENTICAL", "cells": {"native": cell(200, pic="/tmp/x/clip.wav"), "ours": cell(200)}}]}
s2 = {"sid": "b", "title": "sheet b", "chars": ["huitzil"], "tickets": [], "not_comparable": "-", "capped": [], "legs": legs,
      "cols": [{"label": "moment 3", "verdict": "IDENTICAL", "cells": {"native": cell(300, "no"), "ours": cell(300, "no")}}]}
meta = {"commit": "0" * 40, "date": "2026-10-30 12:00", "no_reference_leg": [], "no_picture": [], "debt": [],
        "builds": {"vsavjw on /Users/someone/tree/out/rompath": "registered", "vsav2 on /Users/someone/ROMS": "UNREGISTERED: abc"},
        "provenance": ["commit 000, built in a clean checkout (/Users/someone/tree)"],
        "gates": [{"gate": gid, "rc": 0, "verdict": "PASS: synthetic", "seconds": 1, "tickets": ["338"], "variant_builds": [],
                   "control_builds": ["CTL_BUILD from freeze/x, built in a second clean checkout (/Users/someone/build/agent999/x.ctl.tree) and build/agent999/y.tree"],
                   "sheets": [s1, s2]}]}
json.dump(meta, open(src + "/meta.json", "w"))
for sid, k, legs_ in (("a", 0, ("native", "ours")), ("b", 0, ("native", "ours")), ("a", 1, ("ours",))):
    for leg in legs_:
        Image.new("RGB", (384, 224), (200, 40, 40)).save("%s/pics/%s.%s.%s.%d.png" % (src, gid, sid, leg, k))
with wave.open("%s/pics/%s.a.native.1.wav" % (src, gid), "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(48000)
    w.writeframes(b"".join(struct.pack("<hh", (i * 37) % 2000 - 1000, -((i * 37) % 2000 - 1000)) for i in range(48000)))
PY
ok "the fixture: one gate, two sheets, 5 tiles of 384x224, one 48 kHz stereo clip, local paths in its build text"

echo "== 2. the web build"
python3 "$T" web "$W/src" --to "$W/web" --release test-tag > "$W/web.out" 2>&1; rc=$?
[ "$rc" = 0 ] && ok "web: $(tail -1 "$W/web.out" | sed 's#.*/web/##')" || { bad "web exited $rc: $(tail -3 "$W/web.out" | tr '\n' ' ')"; }
case "${VS_CTL:-}" in   # the modes: the perturbation is applied to the REAL output
missing-credits) python3 -c "import re,sys,glob; p=sorted(glob.glob(sys.argv[1]+'/g/*.html'))[0]; s=open(p).read(); open(p,'w').write(re.sub(r'<footer id=\"credits\".*?</footer>','',s,flags=re.S))" "$W/web" ;;
full-size-tile) python3 -c "import sys,glob; from PIL import Image; p=sorted(glob.glob(sys.argv[1]+'/pics/*.webp'))[0]; Image.new('RGB',(384,224)).save(p,'WEBP')" "$W/web" ;;
full-size-link) printf '<a href="../pics/audit_landing_sound.a.native.0.full.webp">full size</a>' >> "$W/web/g/audit_landing_sound.html" ;;
escaping-link) printf '<a href="../../src/pics/audit_landing_sound.a.native.1.wav">full clip</a>' >> "$W/web/g/audit_landing_sound.html" ;;
log-shipped) echo log > "$W/web/g/audit_landing_sound.log" ;;
local-path) printf '<p>/Users/someone/build/x</p>' >> "$W/web/index.html" ;;
unscrubbed-path) printf '<p>/Volumes/Disk/x</p>' >> "$W/web/index.html" ;;
unreduced-clip) cp "$W/src/pics/audit_landing_sound.a.native.1.wav" "$W/web/pics/" ;;
inline-style) printf '<style>p{color:red}</style>' >> "$W/web/index.html" ;;
style-attribute) python3 -c "import sys,glob; p=sorted(glob.glob(sys.argv[1]+'/g/*.html'))[0]; s=open(p).read(); open(p,'w').write(s.replace('<body>','<body style=\"color:red\">',1))" "$W/web" ;;
inline-script) printf '<script src="x.js"></script>' >> "$W/web/index.html" ;;
event-handler) python3 -c "import sys,glob; p=sorted(glob.glob(sys.argv[1]+'/g/*.html'))[0]; s=open(p).read(); open(p,'w').write(s.replace('<body>','<body onclick=\"x()\">',1))" "$W/web" ;;
missing-stylesheet) rm -f "$W/web/sheets.css" ;;
builds-sentence) python3 -c "import sys,re; p=sys.argv[1]+'/index.html'; s=open(p).read(); open(p,'w').write(re.sub(r'1 of the 2 builds[^<]*\\.', 'Every build matched its frozen reference.', s))" "$W/web" ;;
esac
python3 "$T" webcheck "$W/web" --run "$W/src" > "$W/check.out" 2>&1 && ok "webcheck PASS on the build, its builds sentence checked against the run" || { bad "webcheck: $(grep WEB-PROBLEM "$W/check.out" | head -3 | tr '\n' ' ')"; }
pages="$(find "$W/web" -name '*.html' | wc -l | tr -d ' ')"; foot="$(grep -l 'id="credits"' $(find "$W/web" -name '*.html') | wc -l | tr -d ' ')"
[ "$pages" -ge 2 ] && [ "$foot" = "$pages" ] && ok "every page carries the credits footer ($foot of $pages)" || bad "credits footer on $foot of $pages pages"
# the intro's builds sentence is counted from the run (ruled 14z-213: "Count from the run"): 1 of the fixture's 2 builds is unregistered
want_b='1 of the 2 builds matched their frozen reference; 1 had no frozen reference to match (used by audit_landing_sound).'
grep -qF "$want_b" "$W/web/index.html" && ok "the intro counts the run's builds: $want_b" || bad "the intro's builds sentence: $(grep -o '[0-9]* of the [0-9]* builds[^<]*\|Every build matched[^<]*' "$W/web/index.html" | head -1)"
# a strict CSP (style-src 'self', the maintainer's site, #267) refuses inline style: every page links the one stylesheet
linked="$(grep -l '<link rel="stylesheet" href="\(\.\./\)\{0,1\}sheets.css">' $(find "$W/web" -name '*.html') | wc -l | tr -d ' ')"
inl="$(grep -lE '<style|<script| style=' $(find "$W/web" -name '*.html') | wc -l | tr -d ' ')"
[ -s "$W/web/sheets.css" ] && [ "$linked" = "$pages" ] && [ "$inl" = 0 ] && ok "every page links sheets.css and none carries an inline style or script ($linked of $pages)" \
    || bad "stylesheet: sheets.css $( [ -s "$W/web/sheets.css" ] && echo present || echo MISSING ), linked from $linked of $pages pages, $inl with inline style or script"
python3 - "$W/web" > "$W/files.out" 2>&1 <<'PY'
import glob, sys, wave
from PIL import Image
web = sys.argv[1]
t = sorted(glob.glob(web + "/pics/*.webp")); c = sorted(glob.glob(web + "/pics/*.wav"))
print("tiles", len(t), sorted({Image.open(p).size for p in t}))
print("clips", len(c), sorted({(wave.open(p).getnchannels(), wave.open(p).getframerate()) for p in c}))
print("png", len(glob.glob(web + "/**/*.png", recursive=True)))
PY
grep -q "^tiles 5 \[(192, 112)\]$" "$W/files.out" && ok "5 tiles, every one 192x112 WebP" || bad "tiles: $(grep tiles "$W/files.out")"
grep -q "^clips 1 \[(1, 24000)\]$" "$W/files.out" && ok "the clip: mono, 24 kHz" || bad "clips: $(grep clips "$W/files.out")"
grep -q "^png 0$" "$W/files.out" && ok "no PNG ships" || bad "$(grep png "$W/files.out")"
G="$W/web/g/audit_landing_sound.html"; I="$W/web/index.html"
grep -q 'short clip, down-sampled' "$G" && ok "the clip carries its 'short, down-sampled' caption" || bad "no clip caption on the gate page"
# a JUDGED FILE's caption names what the gate compared: a sound clip is a recording, not a picture (ruled 14z-213: "do it")
python3 - "$T" <<'PY2' > "$W/judged.out" 2>&1
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ps", sys.argv[1]); ps = importlib.util.module_from_spec(spec); spec.loader.exec_module(ps)
for exp in ("files/donovan.native.wav", "files/golden.png"):
    print(exp, "|", ps.prove({"frame": 1, "basis": "file", "expect": exp}, None, None, None)[1])
ps.WEB = {"src": "/nowhere"}
print("scrub |", ps.web_scrub("the picture the gate itself compared (files/donovan.native.wav)"))
PY2
grep -q '^files/donovan.native.wav | the recording the gate itself compared' "$W/judged.out" && grep -q '^files/golden.png | the picture the gate itself compared' "$W/judged.out" && grep -q '^scrub | the recording the gate itself compared (files/donovan.native.wav)$' "$W/judged.out" \
    && ok "a judged sound clip is captioned a recording, a judged image a picture, and the web build corrects an older run's clip caption" || bad "JUDGED FILE captions: $(tr '\n' ' ' < "$W/judged.out")"
grep -q '<a href="../pics/' "$G" && bad "a picture still links to a file" || ok "no picture links to a file"
grep -q 'id="intro"' "$I" && ! grep -q 'built in a clean checkout' "$I" && ok "the index opens with the intro, without the provenance block" || bad "the index's intro or provenance block is wrong"
grep -q 'No picture shows the fighters on 1 sheet(s) of this test: b' "$G" && ! grep -q 'Sheets where no picture shows the fighters' "$I" \
    && ok "the no-fighter sheet is named on its gate's page, not on the index" || bad "the no-fighter note is not where it belongs"
grep -q '(local path)' "$G" && ! grep -qE '/Users/|build/agent[0-9]|\(\(local path\)\)' $(find "$W/web" -name '*.html') && ok "the control-build text's local paths are scrubbed, a bracketed one to a single (local path)" || bad "a local path survives in a page"
mkdir -p "$W/full" && touch "$W/full/x"
python3 "$T" web "$W/src" --to "$W/full" > "$W/full.out" 2>&1 && bad "web wrote into a non-empty --to" || ok "web refuses a non-empty --to"

if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 0 ] && echo "PASS: test_proof_sheets_web" || echo "FAIL: test_proof_sheets_web (control mode ${VS_CTL})"; exit "$fail"
fi

echo "== 3. controls: each perturbed copy must FAIL webcheck on its own fault"
plant() {  # plant <name> <expected WEB-PROBLEM text> <python perturbation on argv[1]>
    rm -rf "$W/p"; cp -R "$W/web" "$W/p"; python3 -c "$3" "$W/p"
    if python3 "$T" webcheck "$W/p" > "$W/p.out" 2>&1; then vs_ctl_dead "$1" "webcheck passed the copy"; fail=1
    elif grep -q "WEB-PROBLEM.*$2" "$W/p.out"; then vs_ctl_fired "$1" "$(grep -m1 "WEB-PROBLEM.*$2" "$W/p.out" | cut -c1-120)"
    else vs_ctl_dead "$1" "webcheck failed for another reason: $(grep -m1 WEB-PROBLEM "$W/p.out")"; fail=1; fi
}
plant missing-credits "no credits footer" "import re,sys,glob; p=sorted(glob.glob(sys.argv[1]+'/g/*.html'))[0]; s=open(p).read(); open(p,'w').write(re.sub(r'<footer id=\"credits\".*?</footer>','',s,flags=re.S))"
plant full-size-tile "larger than the reduced size" "import sys,glob; from PIL import Image; p=sorted(glob.glob(sys.argv[1]+'/pics/*.webp'))[0]; Image.new('RGB',(384,224)).save(p,'WEBP')"
plant full-size-link "links ../pics/audit_landing_sound.a.native.0.full.webp, which the build does not hold" "import sys; open(sys.argv[1]+'/g/audit_landing_sound.html','a').write('<a href=\"../pics/audit_landing_sound.a.native.0.full.webp\">full size</a>')"
[ -f "$W/src/pics/audit_landing_sound.a.native.1.wav" ] && ok "the next control's link target exists: the fixture's full-size clip, outside the build" || bad "the escaping-link target is gone: the control would test a missing file"
plant escaping-link "links ../../src/pics/audit_landing_sound.a.native.1.wav, outside the build" "import sys; open(sys.argv[1]+'/g/audit_landing_sound.html','a').write('<a href=\"../../src/pics/audit_landing_sound.a.native.1.wav\">full clip</a>')"
plant log-shipped "a .log file ships" "import sys; open(sys.argv[1]+'/g/audit_landing_sound.log','w').write('log')"
plant local-path "a local path" "import sys; open(sys.argv[1]+'/index.html','a').write('<p>/Users/someone/build/x</p>')"
# webcheck's path detector is its own (rule-checker run 2026-10-30-1435): the form planted next is one the scrub's pattern
# does not match, so the plant firing shows a path the scrub misses still fails the check
python3 -c "import sys; sys.path.insert(0, sys.argv[1]); import proof_sheets as p; sys.exit(p.WEB_LOCAL_PATH.search('/Volumes/Disk/x') is not None)" "$REPO/tools" \
    && ok "the scrub's own pattern does not match /Volumes/Disk/x (the next control's form)" \
    || bad "the scrub's pattern matches /Volumes/Disk/x: the unscrubbed-path control no longer shows webcheck's own detector"
# web_path_leak asks the scrub's pattern as well as its own detector (run 2026-10-30-1438), so every form the scrub's pattern
# matches fails webcheck by construction; the known answers below include three the own detector alone misses
_cov="$(python3 -c "
import sys; sys.path.insert(0, sys.argv[1]); import proof_sheets as p
forms = ['/Users/a/b', '/home/a/b', '/private/a/b', '/var/folders/a/b', '/tmp/a/b', 'C:' + chr(92) * 2 + 'x', 'build/agent2/x', '(/Users/a/b)', 'rompath:/Users/a/b', 'file:///Users/a/b', 'x/Users/a/b', '/tmp/', '/Volumes/Disk/x']
print('misses', [f for f in forms if not p.web_path_leak(f)], 'own-detector-alone-misses', [f for f in forms if not p.WEB_PATH_LEAK.search(f)], len(forms))" "$REPO/tools" 2>&1)"
[ "$_cov" = "misses [] own-detector-alone-misses ['file:///Users/a/b', 'x/Users/a/b', '/tmp/'] 13" ] \
    && ok "web_path_leak flags all 13 known answers, the 3 its own detector alone misses (file:///Users/..., x/Users/..., /tmp/) among them" \
    || bad "web_path_leak's known answers: $_cov"
plant unscrubbed-path "a local path: /Volumes/Disk/x" "import sys; open(sys.argv[1]+'/index.html','a').write('<p>/Volumes/Disk/x</p>')"
plant unreduced-clip "not reduced" "import sys,shutil,glob; shutil.copy(sys.argv[1]+'/../src/pics/audit_landing_sound.a.native.1.wav', sys.argv[1]+'/pics/')"
plant inline-style "strict Content-Security-Policy" "import sys; open(sys.argv[1]+'/index.html','a').write('<style>p{color:red}</style>')"
plant style-attribute "a style= attribute" "import sys,glob; p=sorted(glob.glob(sys.argv[1]+'/g/*.html'))[0]; s=open(p).read(); open(p,'w').write(s.replace('<body>','<body style=\"color:red\">',1))"
plant inline-script "a <script>" "import sys; open(sys.argv[1]+'/index.html','a').write('<script src=\"x.js\"></script>')"
plant event-handler "an inline event handler" "import sys,glob; p=sorted(glob.glob(sys.argv[1]+'/g/*.html'))[0]; s=open(p).read(); open(p,'w').write(s.replace('<body>','<body onclick=\"x()\">',1))"
plant missing-stylesheet "its stylesheet .* does not exist" "import sys,os; os.remove(sys.argv[1]+'/sheets.css')"

rm -rf "$W/p"; cp -R "$W/web" "$W/p"; python3 -c "import sys,re; p=sys.argv[1]+'/index.html'; s=open(p).read(); open(p,'w').write(re.sub(r'1 of the 2 builds[^<]*\\.', 'Every build matched its frozen reference.', s))" "$W/p"
if python3 "$T" webcheck "$W/p" --run "$W/src" > "$W/p.out" 2>&1; then vs_ctl_dead builds-sentence "webcheck --run passed a false builds sentence"; fail=1
elif grep -q 'WEB-PROBLEM.*builds sentence does not match' "$W/p.out"; then vs_ctl_fired builds-sentence "$(grep -m1 'builds sentence' "$W/p.out" | cut -c1-120)"
else vs_ctl_dead builds-sentence "webcheck failed for another reason: $(grep -m1 WEB-PROBLEM "$W/p.out")"; fail=1; fi

echo "== 4. tools/publish_sheets.sh: to a local folder standing for the webroot"
mkdir -p "$W/site/vs-proof-sheets" && echo stale > "$W/site/vs-proof-sheets/old.html"
if DEPLOY_TARGET="$W/site/" sh tools/publish_sheets.sh "$W/web" > "$W/pub.out" 2>&1 && cmp -s "$W/site/vs-proof-sheets/index.html" "$W/web/index.html" \
   && [ ! -e "$W/site/vs-proof-sheets/old.html" ]; then ok "published into <DEPLOY_TARGET>vs-proof-sheets/, replacing what was there"
else bad "publish: $(tail -1 "$W/pub.out")"; fi
env -u DEPLOY_TARGET sh tools/publish_sheets.sh "$W/web" > "$W/pub2.out" 2>&1 && bad "published with no DEPLOY_TARGET" \
    || { grep -q "DEPLOY_TARGET is not set" "$W/pub2.out" && ok "refused with no DEPLOY_TARGET" || bad "no-target refusal: $(tail -1 "$W/pub2.out")"; }
rm -rf "$W/p" && cp -R "$W/web" "$W/p" && printf '<p>/Users/someone/x</p>' >> "$W/p/index.html"
DEPLOY_TARGET="$W/site2/" sh tools/publish_sheets.sh "$W/p" > "$W/pub3.out" 2>&1 && bad "published a build that fails webcheck" \
    || { grep -q "fails webcheck — nothing published" "$W/pub3.out" && [ ! -e "$W/site2" ] && ok "a build that fails webcheck is refused, nothing written" || bad "webcheck refusal: $(tail -1 "$W/pub3.out")"; }

[ "$fail" = 0 ] && echo "PASS: test_proof_sheets_web — the web build is reduced, credited and free of local paths, and webcheck names each planted fault" || echo "FAIL: test_proof_sheets_web"
exit "$fail"
