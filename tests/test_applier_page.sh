#!/bin/sh
# test_applier_page.sh — SLICES A2-A6 OF THE APPLIER APP: the page must EQUAL the tool
# of record, refuse everything it refuses, and carry no way to phone home (2026-09-21).
#
# WHAT: the browser applier page EQUALS the tool of record (apply_release.py) member for
#   member on both variants, refuses everything it refuses, is self-contained (a
#   Content-Security-Policy the browser enforces plus a scan for named network primitives),
#   carries its modules verbatim, and stops demanding qsound_hle.zip under --no-qsound-bios.
# HOW: the shipped apply_release.html of every platform dir compared with a fresh
#   generation; the inlined modules compared with tools/applier/*.mjs; the modules run under
#   node against apply_release.py on $ROMDIR for member order, bytes, zip header fields and
#   the set key (container bytes deliberately not compared); six refusals exercised on both
#   tools; four controls (a fetch() in the shell, the CSP removed, the member check removed,
#   a flipped member).
# EXPECTS: every section green and every control failing; a red names the member, refusal or
#   primitive. The page's own WIRING is test_applier_page_browser's half.
#
# docs/project/applier_app_scope.md §4: the page is an alternative front end to
# tools/apply_release.py, never a second definition of the romset. A5 is the acceptance —
# "not 'it looks right', but 'it equals the tool of record'" — and this gate is that
# acceptance, run over the SHIPPED release with the maintainer's own dumps.
#
# The five sections, and why each exists:
#   1. THE PAGE IS SELF-CONTAINED, AND THE SHIPPED FILE IS THE ONE THAT IS. It is handed a
#      player's commercial dumps, so "it does not upload them" must be checkable, not a
#      promise in a README (§2). TWO INDEPENDENT CHECKS, because a denylist cannot prove
#      absence: the page must carry a Content-Security-Policy of `default-src 'none';
#      connect-src 'none'; form-action 'none'; base-uri 'none'`, which the BROWSER
#      enforces against every primitive including the ones nobody listed; AND a scan for
#      the named primitives plus any src=/href= that is not a #fragment, which catches a
#      mistake at authoring time instead of in someone's console. Also: generating twice
#      is byte-identical, and — added after a rule-checker found it missing — EVERY
#      platform dir's SHIPPED apply_release.html must equal a fresh generation, so a
#      hand-edited or stale page cannot pass while the gate measures a fresh one.
#   2. THE PAGE CONTAINS THE MODULES THIS GATE MEASURES. Section 3 exercises the modules
#      under node; that is only evidence about the PAGE if the page really carries them,
#      so every inlined module body is compared against tools/applier/*.mjs. What this
#      does NOT cover is the page's own WIRING (page_shell.html's calls into those
#      modules), which node never runs: tests/test_applier_page_browser.sh covers that by
#      driving the shipped page and checking the set key it prints.
#   3. FIDELITY (A5): apply_release.py and the page's modules, same $ROMDIR, BOTH variants
#      — same member order, same member bytes, same zip header fields, and the set key the
#      manifest declares. The CONTAINER bytes are deliberately NOT compared: measured
#      2026-09-21, CompressionStream("deflate-raw") is not byte-comparable to
#      zlib.compressobj even at the same level because it flushes on stream chunk
#      boundaries (node 485178 bytes against python 484140 on one real member), and
#      Firefox's encoder differs again. What no encoder can change is the MEMBER bytes,
#      which is what every emulator, every fingerprint and the set key read.
#   4. THE REFUSALS (A3), which are the deliverable. Every static fragment of every
#      refusal apply_release.py can print must exist in the page's applier — read out of
#      the Python file's SYNTAX TREE, so a new refusal there fails this gate until the
#      page has one. THAT IS A PRESENCE TEST: it proves the vocabulary matches and never
#      that a message is REACHABLE. So SIX are exercised for real, on both tools, each
#      requiring both to refuse, both to name the same thing, and NEITHER to write: a
#      modified dump, a truncated dump, a missing dump, a dump with an extra member, a
#      corrupted patch, and a tampered manifest.
#   5. THE OPTIONAL MEMBER (A4): --no-qsound-bios must not merely skip the member, it must
#      stop DEMANDING qsound_hle.zip at all — run with that dump absent from $ROMDIR.
#
# MUST-FIRE: shadow-tool: no-member-check — a copy of applier.mjs with the rebuilt-member sha1 check removed must make section 4 fail, because a corrupted patch would then be accepted instead of refused; if the section still passed, it would not be reading the verification at all (mode: the gate runs against that copy)
# MUST-FIRE: shadow-tool: flipped-member — a copy of applier.mjs that flips one byte of one finished member AND skips the set-key check must make section 3's member-for-member comparison fail; if it still passed, the comparison would not be comparing the bytes (mode: the gate runs against that copy)
# MUST-FIRE: perturbed-copy: page-with-fetch — a copy of the page shell carrying a fetch() call must make section 1 fail; if it passed, the self-containment property would be unchecked and the page's one hard constraint would rest on nothing (mode: the gate generates from that shell)
# MUST-FIRE: perturbed-copy: page-without-csp — a copy of the page shell with its Content-Security-Policy meta removed must make section 1 fail; the CSP is what makes "no network of any kind" a property the BROWSER enforces rather than one a denylist guesses at, and a denylist cannot prove absence, so a page that lost it must not ship (mode: the gate generates from that shell)
#
# Usage: ROMDIR=... tests/test_applier_page.sh [release/merged-m20/fbneo]   # ci_static
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
ROMDIR="${ROMDIR:?set ROMDIR}"
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REL="${1:-release/merged-m20/fbneo}"
[ -f "$REL/manifest.json" ] || { echo "SKIP: no release manifest at $REL"; exit 0; }
command -v node >/dev/null 2>&1 || { echo "SKIP: no node on this host (the page is ES-module JS; a browser is its real target)"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
MOD="$REPO/tools/applier"
SHELL_HTML="$MOD/page_shell.html"
fails=0
note() { echo "  $*"; }

# ── the shadow module directory the two shadow-tool controls perturb ──────────
# Written as ONE function both the control section and the mode call, so what the
# mode proves is what the control claims ([VSP-181]).
shadow_modules() {   # $1 = which perturbation, $2 = destination dir
    mkdir -p "$2"
    cp "$MOD"/vcdiff.mjs "$MOD"/zip.mjs "$MOD"/applier.mjs "$MOD"/apply_node.mjs "$2/"
    python3 - "$1" "$2/applier.mjs" <<'PY'
import sys
kind, path = sys.argv[1:3]
s = open(path).read()
if kind == "no-member-check":
    old = """      if (d.length !== e.size || (await sha1Hex(d)) !== e.sha1) {
        throw new ApplierError(`${zname}/${e.member}: rebuilt member does not match the manifest — NOT writing`);
      }"""
    assert old in s, "the rebuilt-member check is not where this control expects it"
    s = s.replace(old, "      // CONTROL no-member-check: verification removed")
    # the set-key check would otherwise catch a tampered manifest on its own, and then
    # the control would be measuring THAT check rather than the one it names
    old2 = "  if (want && setKey !== want) {"
    assert old2 in s, "the set-key check is not where this control expects it"
    s = s.replace(old2, "  if (false && want && setKey !== want) {  // CONTROL no-member-check")
elif kind == "flipped-member":
    old = "      out.push([e.member, d]);"
    assert old in s, "the member push is not where this control expects it"
    s = s.replace(old, "      if (out.length === 0 && d.length) d[0] ^= 0x01;  // CONTROL flipped-member\n" + old)
    old2 = "  if (want && setKey !== want) {"
    assert old2 in s, "the set-key check is not where this control expects it"
    s = s.replace(old2, "  if (false && want && setKey !== want) {  // CONTROL flipped-member")
else:
    sys.exit(f"unknown shadow perturbation {kind!r}")
open(path, "w").write(s)
PY
}

NODE_APPLIER="$MOD/apply_node.mjs"
if vs_ctl_is no-member-check; then
    shadow_modules no-member-check "$W/shadow"; NODE_APPLIER="$W/shadow/apply_node.mjs"
    note "CONTROL: applier.mjs copy with the rebuilt-member sha1 check removed"
fi
if vs_ctl_is flipped-member; then
    shadow_modules flipped-member "$W/shadow"; NODE_APPLIER="$W/shadow/apply_node.mjs"
    note "CONTROL: applier.mjs copy that flips one byte of one member and skips the set-key check"
fi

# ── 1. the page is self-contained, and generating it is deterministic ─────────
echo "1. the page: self-contained, deterministic"
# ONE function the control section and the mode both call, so what the mode proves is
# what the control claims ([VSP-181]).
break_shell() {   # $1 = which perturbation, $2 = destination shell
    cp "$SHELL_HTML" "$2"
    python3 - "$1" "$2" <<'PY'
import re, sys
kind, p = sys.argv[1:3]
s = open(p).read()
if kind == "page-with-fetch":
    mark = "const $ = (id) => document.getElementById(id);"
    assert mark in s, "the shell no longer has the anchor this control injects at"
    s = s.replace(mark, mark + '\nawait fetch("https://example.invalid/telemetry");', 1)
    print("  CONTROL: a fetch() call injected into a copy of the page shell")
elif kind == "page-without-csp":
    s2 = re.sub(r'<meta http-equiv="Content-Security-Policy"[^>]*>\n?', "", s, count=1)
    assert s2 != s, "the shell carries no Content-Security-Policy to remove"
    s = s2
    print("  CONTROL: the Content-Security-Policy meta removed from a copy of the page shell")
else:
    sys.exit("unknown shell perturbation " + repr(kind))
open(p, "w").write(s)
PY
}

GEN_SHELL="$SHELL_HTML"
for c in page-with-fetch page-without-csp; do
    if vs_ctl_is "$c"; then break_shell "$c" "$W/shell_bad.html"; GEN_SHELL="$W/shell_bad.html"; fi
done

gen_rc=0
python3 tools/gen_applier_page.py "$REL" --shell "$GEN_SHELL" -o "$W/page1.html" > "$W/gen1.txt" 2>&1 || gen_rc=$?
for c in page-with-fetch page-without-csp; do
    vs_ctl_is "$c" || continue
    if [ "$gen_rc" = 0 ]; then
        vs_ctl_dead "$c" "the generator accepted a shell it must refuse" || true
        echo "FAIL: test_applier_page"; exit 1
    fi
    vs_ctl_fired "$c" "the generator refused it: $(sed -n '2p' "$W/gen1.txt" | sed 's/^ *//' | cut -c1-90)"
    echo "FAIL: test_applier_page (control mode: the bad page was correctly refused)"
    exit 1
done
[ "$gen_rc" = 0 ] || { cat "$W/gen1.txt"; echo "FAIL: the page would not generate"; exit 1; }
sed 's/^/  /' "$W/gen1.txt"

python3 tools/gen_applier_page.py "$REL" --shell "$GEN_SHELL" -o "$W/page2.html" >/dev/null
if cmp -s "$W/page1.html" "$W/page2.html"; then
    note "ok: two generations are byte-identical"
else
    note "two generations of the page differ"; fails=$((fails + 1))
fi

# THE SHIPPED FILE IS WHAT PLAYERS GET, AND UNTIL THIS CHECK EXISTED NOTHING LOOKED AT IT.
# Everything else here measures a FRESH generation; "the shipped page is that generation"
# was an unnamed premise (found by the rule-checker, run 2026-09-21-90 Q1). A hand-edited
# page, or a generator change landed without re-packaging, would have passed every gate.
# Checked for EVERY platform dir of the release, because each carries its own copy.
relroot="$(dirname "$REL")"
nship=0
for pdir in "$relroot"/*/; do
    p="$(basename "$pdir")"
    [ -f "$pdir/manifest.json" ] || continue
    if [ ! -f "$pdir/apply_release.html" ]; then
        note "$p/: ships no apply_release.html"; fails=$((fails + 1)); continue
    fi
    python3 tools/gen_applier_page.py "$pdir" -o "$W/fresh_$p.html" >/dev/null
    if cmp -s "$pdir/apply_release.html" "$W/fresh_$p.html"; then
        nship=$((nship + 1))
    else
        note "$p/apply_release.html is NOT what tools/gen_applier_page.py produces today \
— regenerate it (the release is stale, or the file was edited by hand)"
        fails=$((fails + 1))
    fi
done
[ "$nship" = 0 ] || note "ok: the SHIPPED page is byte-identical to a fresh generation in all $nship platform dir(s)"

# the property re-asserted on the OUTPUT, independently of the generator that wrote it
python3 - "$W/page1.html" <<'PY' || fails=1
import re, sys
p = sys.argv[1]; s = open(p).read()
bad = []
for pat, label in ((r"\bfetch\s*\(", "fetch()"), (r"\bXMLHttpRequest\b", "XMLHttpRequest"),
                   (r"\bWebSocket\b", "WebSocket"), (r"\bEventSource\b", "EventSource"),
                   (r"\bsendBeacon\b", "sendBeacon"), (r"\bimport\s*\(", "dynamic import()"),
                   (r"\bimportScripts\s*\(", "importScripts()")):
    for m in re.finditer(pat, s):
        bad.append(f"{label} at line {s.count(chr(10), 0, m.start()) + 1}")
for m in re.finditer(r"""\b(?:src|href)\s*=\s*["'](?!#)([^"']*)["']""", s, re.I):
    bad.append(f"external resource {m.group(1)!r} at line {s.count(chr(10), 0, m.start()) + 1}")
if bad:
    print("  the generated page is NOT self-contained: " + "; ".join(bad[:6])); sys.exit(1)
print(f"  ok: no network primitive and no external resource in {len(s) / 1048576:.2f} MB of page")
PY

# ── 2. the page really carries the modules section 3 measures ────────────────
echo "2. the page carries the modules this gate measures"
python3 - "$W/page1.html" "$MOD" <<'PY' || fails=1
import os, re, sys
page, moddir = sys.argv[1:3]
s = open(page).read()
IMPORT = re.compile(r'^\s*import\s.*\sfrom\s+"\./[A-Za-z0-9_]+\.mjs";\s*$')
EXPORT = re.compile(r"^export\s+(?=(async\s+function|function|class|const|let|var)\b)")
missing = []
for name in ("vcdiff.mjs", "zip.mjs", "applier.mjs"):
    body = "\n".join(EXPORT.sub("", l) for l in open(os.path.join(moddir, name)).read().splitlines()
                     if not IMPORT.match(l))
    if body not in s:
        missing.append(name)
if missing:
    print("  the page does not carry these modules verbatim: " + ", ".join(missing))
    print("  (so this gate's node measurements would not be evidence about the page)")
    sys.exit(1)
print("  ok: vcdiff.mjs, zip.mjs and applier.mjs are inlined verbatim")
PY

# ── 3. fidelity (A5), both variants ──────────────────────────────────────────
echo "3. fidelity: the page's modules against apply_release.py, both variants"
for variant in standalone no-qsound-bios; do
    extra=""
    [ "$variant" = no-qsound-bios ] && extra="--no-qsound-bios"
    rm -rf "$W/py_$variant" "$W/js_$variant"
    python3 tools/apply_release.py --romdir "$ROMDIR" --out "$W/py_$variant" \
        --manifest "$REL/manifest.json" $extra > "$W/py_$variant.log" 2>&1 \
        || { sed 's/^/    /' "$W/py_$variant.log"; echo "  apply_release.py failed ($variant)"; fails=$((fails + 1)); continue; }
    node "$NODE_APPLIER" --romdir "$ROMDIR" --out "$W/js_$variant" \
        --manifest "$REL/manifest.json" $extra > "$W/js_$variant.log" 2>&1 \
        || { sed 's/^/    /' "$W/js_$variant.log"; echo "  the page's applier failed ($variant)"; fails=$((fails + 1)); continue; }
    python3 - "$W/py_$variant" "$W/js_$variant" "$REL/manifest.json" "$variant" <<'PY' || fails=1
import json, sys, zipfile
py, js, mf, variant = sys.argv[1:5]
m = json.load(open(mf))
key_field = "applied_set_key_no_qsound_bios" if variant == "no-qsound-bios" else "applied_set_key"
import hashlib, os
problems = []
names_py = sorted(os.listdir(py))
if names_py != sorted(os.listdir(js)):
    problems.append(f"different zips written: {names_py} vs {sorted(os.listdir(js))}")
built = {}
for zname in names_py:
    a, b = zipfile.ZipFile(os.path.join(py, zname)), zipfile.ZipFile(os.path.join(js, zname))
    na, nb = a.namelist(), b.namelist()
    if na != nb:
        problems.append(f"{zname}: member order differs"); continue
    for n in na:
        da, db = a.read(n), b.read(n)
        if da != db:
            problems.append(f"{zname}/{n}: member bytes differ")
    fa = {i.filename: (i.compress_type, i.date_time, i.CRC, i.create_system,
                       i.external_attr, i.extract_version, i.create_version) for i in a.infolist()}
    fb = {i.filename: (i.compress_type, i.date_time, i.CRC, i.create_system,
                       i.external_attr, i.extract_version, i.create_version) for i in b.infolist()}
    for n in na:
        if fa[n] != fb[n]:
            problems.append(f"{zname}/{n}: zip header fields differ {fa[n]} vs {fb[n]}")
    if b.testzip() is not None:
        problems.append(f"{zname}: the page's zip does not read back cleanly")
    built[zname] = [(n, b.read(n)) for n in nb]
# the set key, computed off the PAGE's output, against the manifest's own declaration
h = hashlib.sha1()
for zname in sorted(built):
    h.update(zname.encode())
    for member, data in sorted(built[zname], key=lambda kv: kv[0]):
        h.update(member.encode()); h.update(data)
want = m.get(key_field)
if want and h.hexdigest() != want:
    problems.append(f"set key {h.hexdigest()[:8]} != the manifest's {key_field} {want[:8]}")
nm = sum(len(v) for v in built.values())
if problems:
    print(f"  {variant}: " + "; ".join(problems[:6]) + (f" (+{len(problems) - 6} more)" if len(problems) > 6 else ""))
    sys.exit(1)
print(f"  ok: {variant}: {nm} members identical, order and header fields identical, "
      f"set key {h.hexdigest()[:8]} as declared")
PY
done

# ── 4. the refusals (A3) ─────────────────────────────────────────────────────
echo "4. the refusals: every message the tool of record can print has a page equivalent"
python3 - tools/apply_release.py "$MOD/applier.mjs" <<'PY' || fails=1
import ast, sys
py, js = sys.argv[1:3]
src = open(py).read()
jsrc = open(js).read()

# Every refusal apply_release.py can print, taken from the SYNTAX TREE rather than by
# matching quotes — an f-string's literal pieces are what survive interpolation, and a
# regex over the source would hand back escape sequences (`\n`) that no message contains.
def literal_pieces(node):
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        yield node.value
    elif isinstance(node, ast.JoinedStr):
        for v in node.values:
            yield from literal_pieces(v)
    elif isinstance(node, ast.BinOp) and isinstance(node.op, ast.Add):
        yield from literal_pieces(node.left); yield from literal_pieces(node.right)

frags = []
for node in ast.walk(ast.parse(src)):
    if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Attribute):
        continue
    owner = getattr(node.func.value, "id", None)
    if (owner, node.func.attr) not in (("sys", "exit"), ("bad", "append")):
        continue
    for arg in node.args:
        for piece in literal_pieces(arg):
            for line in piece.split("\n"):
                line = line.strip()
                if len(line) >= 12:
                    frags.append(line)
frags = sorted(set(frags))
missing = [f for f in frags if f not in jsrc]
if missing:
    print(f"  {len(missing)} of {len(frags)} refusal messages have no page equivalent:")
    for f in missing[:8]:
        print(f"    {f!r}")
    sys.exit(1)
print(f"  ok: all {len(frags)} refusal fragments of apply_release.py appear in the page's applier")
print(f"     (a PRESENCE test: it proves the vocabulary matches, never that a message is REACHABLE;")
print(f"      the cases below exercise the reachable ones for real)")
PY

# exercised for real: both tools must refuse, name the member, and write nothing
mkdir -p "$W/roms"
for z in $(python3 -c "
import json,sys
m=json.load(open('$REL/manifest.json'))
zs=set(m['source']['order'])
zs.update(s['zip'] for s in m.get('pristine_sources',[]))
print(' '.join(sorted(zs)))"); do
    ln -sf "$ROMDIR/$z" "$W/roms/$z"
done
break_dump() {   # $1 = kind, writes a real (broken) copy over the symlink
    rm -f "$W/roms/vsav2.zip"
    python3 - "$ROMDIR/vsav2.zip" "$W/roms/vsav2.zip" "$1" <<'PY'
import shutil, sys, zipfile, os
src, dst, kind = sys.argv[1:4]
if kind == "truncated":
    b = open(src, "rb").read()
    open(dst, "wb").write(b[: len(b) // 2])
else:  # modified: rewrite one member with one byte flipped
    zi = zipfile.ZipFile(src)
    target = sorted(zi.namelist())[0]
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zo:
        for n in zi.namelist():
            d = bytearray(zi.read(n))
            if n == target:
                d[0] ^= 0x01
            zo.writestr(n, bytes(d))
    print(f"    (flipped one byte of vsav2.zip/{target})")
PY
}
refusal_case() {   # $1 = label, $2 = expected fragment
    label="$1"; want="$2"
    prc=0; jrc=0
    rm -rf "$W/r_py" "$W/r_js"
    python3 tools/apply_release.py --romdir "$W/roms" --out "$W/r_py" \
        --manifest "$REL/manifest.json" > "$W/r_py.txt" 2>&1 || prc=$?
    node "$NODE_APPLIER" --romdir "$W/roms" --out "$W/r_js" \
        --manifest "$REL/manifest.json" > "$W/r_js.txt" 2>&1 || jrc=$?
    ok=1
    [ "$prc" = 0 ] && { note "$label: apply_release.py did NOT refuse"; ok=0; }
    [ "$jrc" = 0 ] && { note "$label: the page's applier did NOT refuse"; ok=0; }
    grep -q "$want" "$W/r_py.txt" || { note "$label: apply_release.py's message lacks '$want'"; ok=0; }
    grep -q "$want" "$W/r_js.txt" || { note "$label: the page's message lacks '$want'"; ok=0; }
    [ -e "$W/r_py/vsavjw.zip" ] && { note "$label: apply_release.py wrote a file anyway"; ok=0; }
    [ -e "$W/r_js/vsavjw.zip" ] && { note "$label: the page's applier wrote a file anyway"; ok=0; }
    if [ "$ok" = 1 ]; then
        note "ok: $label — both refuse, both name it, neither writes"
    else
        fails=$((fails + 1))
    fi
}
break_dump modified
refusal_case "a modified dump" "sha1/size mismatch"
break_dump truncated
refusal_case "a truncated dump" "vsav2.zip"
rm -f "$W/roms/vsav2.zip"; ln -sf "$ROMDIR/vsav2.zip" "$W/roms/vsav2.zip"

# a MISSING dump, and a dump carrying an EXTRA member (which moves the source blob's
# sha1 without any member of the recipe being wrong) — two more of the refusal paths
# exercised rather than merely present in the source (the rule-checker's Q4, 2026-09-21-90)
mv "$W/roms/vsav2.zip" "$W/vsav2.hidden"
refusal_case "a missing dump" "missing reference dump"
mv "$W/vsav2.hidden" "$W/roms/vsav2.zip"

rm -f "$W/roms/vsav2.zip"
python3 - "$ROMDIR/vsav2.zip" "$W/roms/vsav2.zip" <<'INNER'
import shutil, sys, zipfile
shutil.copy(sys.argv[1], sys.argv[2])
with zipfile.ZipFile(sys.argv[2], "a") as z:
    z.writestr("zz_extra.bin", b"an extra member the manifest never saw")
INNER
refusal_case "a dump with an extra member" "source blob sha1 mismatch"
rm -f "$W/roms/vsav2.zip"; ln -sf "$ROMDIR/vsav2.zip" "$W/roms/vsav2.zip"

# a corrupted patch: the release copied, one patch byte flipped
rm -rf "$W/relbad"; cp -R "$REL" "$W/relbad"
python3 - "$W/relbad" <<'PY'
import glob, os, sys
f = sorted(glob.glob(os.path.join(sys.argv[1], "patches", "*", "*.xdelta")))[0]
b = bytearray(open(f, "rb").read()); b[len(b) // 2] ^= 0x01
open(f, "wb").write(bytes(b))
PY
prc=0; jrc=0
rm -rf "$W/p_py" "$W/p_js"
python3 tools/apply_release.py --romdir "$ROMDIR" --out "$W/p_py" --manifest "$W/relbad/manifest.json" > "$W/p_py.txt" 2>&1 || prc=$?
node "$NODE_APPLIER" --romdir "$ROMDIR" --out "$W/p_js" --manifest "$W/relbad/manifest.json" > "$W/p_js.txt" 2>&1 || jrc=$?
if [ "$prc" != 0 ] && [ "$jrc" != 0 ] && [ ! -e "$W/p_js/vsavjw.zip" ]; then
    note "ok: a corrupted patch — both refuse, neither writes"
else
    note "a corrupted patch was not refused (apply_release.py rc=$prc, the page's applier rc=$jrc)"
    fails=$((fails + 1))
fi

# a TAMPERED MANIFEST: the patches and dumps are pristine, one declared member sha1 is
# not. The rebuilt-member check is the only thing that can see this — the decode
# succeeds, the adler32 inside the VCDIFF window agrees, and the set key is computed
# from the same (correct) bytes. It is therefore what the no-member-check control
# removes, and this case is what that control must break.
rm -rf "$W/reltamper"; cp -R "$REL" "$W/reltamper"
python3 - "$W/reltamper/manifest.json" <<'PY'
import json, sys
p = sys.argv[1]; m = json.load(open(p))
for entries in m["zips"].values():
    for e in entries:
        if "patch" in e:
            e["sha1"] = "0" * 40
            print(f"    (declared a wrong sha1 for {e['member']})")
            json.dump(m, open(p, "w"))
            sys.exit(0)
sys.exit("no patched entry to tamper with")
PY
prc=0; jrc=0
rm -rf "$W/t_py" "$W/t_js"
python3 tools/apply_release.py --romdir "$ROMDIR" --out "$W/t_py" --manifest "$W/reltamper/manifest.json" > "$W/t_py.txt" 2>&1 || prc=$?
node "$NODE_APPLIER" --romdir "$ROMDIR" --out "$W/t_js" --manifest "$W/reltamper/manifest.json" > "$W/t_js.txt" 2>&1 || jrc=$?
ctl_evidence="$(head -1 "$W/t_js.txt")"
if [ "$prc" != 0 ] && [ "$jrc" != 0 ] \
   && grep -q "does not match the manifest" "$W/t_py.txt" \
   && grep -q "does not match the manifest" "$W/t_js.txt" \
   && [ ! -e "$W/t_js/vsavjw.zip" ]; then
    note "ok: a tampered manifest — both refuse naming the member, neither writes"
else
    note "a tampered manifest was not refused (apply_release.py rc=$prc, the page's applier rc=$jrc)"
    fails=$((fails + 1))
fi

# ── 5. the optional member (A4) ──────────────────────────────────────────────
echo "5. --no-qsound-bios does not merely skip the member, it stops needing the dump"
rm -f "$W/roms/qsound_hle.zip"
rm -rf "$W/nb_js"
if node "$NODE_APPLIER" --romdir "$W/roms" --out "$W/nb_js" --manifest "$REL/manifest.json" \
        --no-qsound-bios > "$W/nb.txt" 2>&1; then
    note "ok: built with qsound_hle.zip absent from the rom directory entirely"
else
    sed 's/^/    /' "$W/nb.txt"
    note "the page's applier still demanded qsound_hle.zip"
    fails=$((fails + 1))
fi
rm -rf "$W/nb_py"
if python3 tools/apply_release.py --romdir "$W/roms" --out "$W/nb_py" --manifest "$REL/manifest.json" \
        --no-qsound-bios > "$W/nbp.txt" 2>&1; then
    note "ok: apply_release.py agrees — the dump is not demanded either"
else
    note "apply_release.py demanded qsound_hle.zip where the page did not — the two disagree"
    fails=$((fails + 1))
fi

# ── the controls, in-gate ────────────────────────────────────────────────────
if vs_ctl_is no-member-check; then
    if [ "$fails" = 0 ]; then
        vs_ctl_dead no-member-check "an applier with no rebuilt-member check still refused the corrupted patch" || true
        echo "FAIL: test_applier_page"; exit 1
    fi
    vs_ctl_fired no-member-check "with the check removed, section 4's cases no longer all refuse — the gate went red as it must"
    echo "FAIL: test_applier_page (control mode: the unverified applier was correctly caught)"
    exit 1
fi
if vs_ctl_is flipped-member; then
    if [ "$fails" = 0 ]; then
        vs_ctl_dead flipped-member "a flipped output member was not caught by the comparison" || true
        echo "FAIL: test_applier_page"; exit 1
    fi
    vs_ctl_fired flipped-member "the member-for-member comparison caught a single flipped byte"
    echo "FAIL: test_applier_page (control mode: the flipped member was correctly caught)"
    exit 1
fi

shadow_modules no-member-check "$W/ctl_a"
crc=0
node "$W/ctl_a/apply_node.mjs" --romdir "$ROMDIR" --out "$W/ctl_a_out" \
    --manifest "$W/reltamper/manifest.json" > "$W/ctl_a.txt" 2>&1 || crc=$?
if [ "$crc" = 0 ]; then
    vs_ctl_fired no-member-check "with the rebuilt-member check removed a manifest declaring a wrong member sha1 is accepted (rc=0), where the real applier refused it by name"
else
    vs_ctl_dead no-member-check "the unverified applier still refused the tampered manifest (rc=$crc)" || true
    fails=$((fails + 1))
fi

shadow_modules flipped-member "$W/ctl_b"
rm -rf "$W/ctl_b_out"
node "$W/ctl_b/apply_node.mjs" --romdir "$ROMDIR" --out "$W/ctl_b_out" \
    --manifest "$REL/manifest.json" > "$W/ctl_b.txt" 2>&1 || true
if [ -e "$W/ctl_b_out/vsavjw.zip" ] && python3 - "$W/py_standalone/vsavjw.zip" "$W/ctl_b_out/vsavjw.zip" <<'PY'
import sys, zipfile
a, b = (zipfile.ZipFile(p) for p in sys.argv[1:3])
sys.exit(0 if any(a.read(n) != b.read(n) for n in a.namelist()) else 1)
PY
then
    vs_ctl_fired flipped-member "a one-byte flip in a finished member makes the member-for-member comparison differ"
else
    vs_ctl_dead flipped-member "the flipped-member copy produced a set identical to the tool of record's" || true
    fails=$((fails + 1))
fi

# each shell perturbation must be refused by the generator
for c in page-with-fetch page-without-csp; do
    break_shell "$c" "$W/ctl_shell_$c.html" >/dev/null
    grc=0
    python3 tools/gen_applier_page.py "$REL" --shell "$W/ctl_shell_$c.html" \
        -o "$W/ctl_page_$c.html" > "$W/ctl_gen_$c.txt" 2>&1 || grc=$?
    case "$c" in
        page-with-fetch)  want="fetch()" ;;
        page-without-csp) want="Content-Security-Policy" ;;
    esac
    if [ "$grc" != 0 ] && grep -q "$want" "$W/ctl_gen_$c.txt"; then
        vs_ctl_fired "$c" "the generator refuses it: $(grep -m1 "$want" "$W/ctl_gen_$c.txt" | sed 's/^ *//' | cut -c1-88)"
    else
        vs_ctl_dead "$c" "the generator produced a page it should have refused (rc=$grc)" || true
        fails=$((fails + 1))
    fi
done

[ "$fails" = 0 ] || { echo "FAIL: test_applier_page ($fails section(s))"; exit 1; }
echo "PASS: test_applier_page — the page equals apply_release.py member for member on both variants, refuses what it refuses, and carries no way to phone home"
