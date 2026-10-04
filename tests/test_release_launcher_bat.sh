#!/bin/sh
# test_release_launcher_bat.sh — THE WINDOWS LAUNCHER, PLAY.bat, and WHAT EACH PACKAGE'S TEXT
# PROMISES ABOUT LAUNCHERS (14z-189, GitHub #145).
#
# WHAT: the PLAY.bat every emulator package carries is plain cmd (no PowerShell), CRLF and
#   ASCII only, every `goto` lands on a label and no parenthesised block can be split by a
#   path holding "(x86)", and it runs the ruled invocation: FBNeo `fbneo.exe vsavjw` from its
#   own folder with the set copied into roms\ beside it, MAME `cps2.exe vsavjw -rompath <the
#   set's folder>`; the release tree's copy is byte-identical to the generator's (both sha1s
#   printed). Every shipped text of every package (README.md, MISTER.md, EMULATOR.md,
#   apply_release.html) names only launchers THAT package ships, and carries no unselected
#   platform marker; and the README the generator writes NOW claims that its package holds an emulator
#   only on fbneo and mame, never on mister (#214). ON A WINDOWS HOST (MSYS2) it also drives BOTH .bat files — the shipped
#   bytes — under cmd with PLAY_DRY_RUN=1: each success path (FBNeo: roms\vsavjw.zip created,
#   the WOULD RUN line; MAME: the WOULD RUN line with -rompath at the set's folder) and each
#   refusal (FBNeo: no romset, no binary, no profile, a junctioned roms\; MAME: no romset, no
#   binary, a stock cps2.exe that does not know vsavjw), each non-zero and named.
# HOW: tools/package_release_platforms.py's launcher_bat_bytes() for both platforms (the
#   bytes the packager writes), read as bytes; the package texts grepped for each launcher's
#   name against the package's files; on Windows, staged copies driven by `cmd //c`, with a
#   stub fbneo.exe that is a text file carrying (or lacking) the profile marker (the FBNeo
#   check is findstr over the file) and two stub cps2.exe COMPILED here with the shell's gcc,
#   one answering `-listfull vsavjw` and one refusing it as a stock MAME does (the MAME check
#   RUNS the binary). The dry run stops before either would be launched.
# EXPECTS: every static property on both launchers and every package text; on Windows every
#   path's exit code and message (a Windows host without gcc is a FAIL, never a skip: these
#   paths went unrun once); elsewhere the Windows section SKIPs and says so. The real launch
#   (the emulator staying up) is not this gate's: measured on ERIS 2026-10-03 (STATE 14z-189).
#
# MUST-FIRE: perturbed-copy: lf-endings — BOTH PLAY.bat files with CRLF turned into LF must FAIL: cmd reads a LF-only batch file in 512-byte blocks and loses `goto` labels across them, so the line-ending rule is the one a working-looking launcher breaks silently
# MUST-FIRE: perturbed-copy: launch-line-changed — the FBNeo PLAY.bat without `vsavjw` on its launch line, and the MAME PLAY.bat without `-rompath`, must FAIL: those are #145's two failures, an emulator with no game name that flashes shut and a MAME that finds no ROMs
# MUST-FIRE: perturbed-copy: emu-text-in-mister — the generator's README rendered for the MiSTer package with the EMULATOR selection must FAIL: that is #214, the MiSTer README telling its reader the package already contains an emulator (step 2, the "why" paragraph, the troubleshooting bullet)
# MUST-FIRE: perturbed-copy: readme-names-absent-launcher — a copy of the release's texts whose mame package no longer ships PLAY.bat while its README still names it must FAIL: that is rule-checker run 2026-10-03-602's finding, the MiSTer README telling its reader to double-click two launchers its package never carried
#
# WHY. #145 (maintainer report 2026-09-16, reproduced on ERIS 2026-10-03): double-clicking
# fbneo.exe exits at once and cps2.exe finds no ROMs; ruled 2026-10-03 "PLAY.bat launcher".
# The package-text check and the MAME half of the Windows section were added after rule-checker
# run 2026-10-03-602 (VIOLATED Q1 Q4): the MiSTer README named PLAY.command and PLAY.bat, and
# the MAME launcher's refusals had never run anywhere.
#
# Usage: tests/test_release_launcher_bat.sh [release/merged-m22]   # ci_portable (no ROMDIR, no emulator, no ROM bytes)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
REL="${1:-release/merged-m22}"
[ -d "$REL" ] || { echo "FAIL: no release tree at $REL (the package-text check needs one)"; exit 1; }
NAME="$(basename "$REL")"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $*"; }
bad() { echo "FAIL: $*"; fail=1; }
case "$VS_CTL" in ""|lf-endings|launch-line-changed|readme-names-absent-launcher|emu-text-in-mister) ;;
*) echo "REFUSED: CONTROL=$VS_CTL is not a mode of this gate"; exit 3 ;; esac
sha1() { python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest()[:12])" "$1"; }

# the generator's bytes, one file per platform, plus the perturbed copies of BOTH
python3 - "$W" "$NAME" <<'PYEOF' || { echo "FAIL: the generator did not run"; exit 1; }
import os, sys
sys.path.insert(0, "tools")
import package_release_platforms as P
w, name = sys.argv[1], sys.argv[2]
LINE = {"fbneo": (b'"%BIN%" vsavjw %*', b'"%BIN%" %*'),
        "mame":  (b'"%BIN%" vsavjw -rompath "%ZIPDIR%" -skip_gameinfo %*', b'"%BIN%" vsavjw -skip_gameinfo %*')}
for p in ("fbneo", "mame"):
    b = P.launcher_bat_bytes(p, name)
    open(os.path.join(w, f"{p}.bat"), "wb").write(b)
    open(os.path.join(w, f"ctl_lf-endings_{p}.bat"), "wb").write(b.replace(b"\r\n", b"\n"))
    old, new = LINE[p]
    assert b.count(old) == 1, f"the {p} launch line is not where the control expects it"
    open(os.path.join(w, f"ctl_launch-line-changed_{p}.bat"), "wb").write(b.replace(old, new))
PYEOF

# check <file> <platform> -> prints the failures; exit 0 clean, 3 findings, anything else a
# CRASH of the checker, never read as a finding (a crashing checker would otherwise "fire"
# every control — it did, on this gate's first run)
check() {
    python3 - "$1" "$2" <<'PYEOF'
import re, sys
path, plat = sys.argv[1], sys.argv[2]
b = open(path, "rb").read()
bad = []
nl, crlf = b.count(b"\n"), b.count(b"\r\n")
if nl != crlf:
    bad.append(f"line endings: {nl - crlf} bare LF of {nl} lines (cmd needs CRLF)")
if any(x > 127 for x in b):
    bad.append("non-ASCII bytes (cmd reads a .bat in the OEM code page)")
t = b.decode("ascii", "replace")
if not t.startswith("@echo off\r\n"):
    bad.append("does not start with @echo off")
lines = t.split("\r\n")
code = [l for l in lines if not l.lower().lstrip().startswith(("rem ", "rem\t", "echo "))]
for l in lines:                     # cmd expands % even on a rem line: "%~a" there is a syntax error
    if l.lower().lstrip().startswith("rem") and "%" in l:
        bad.append(f"a % on a rem line (cmd expands it): {l.strip()[:50]}")
if any(re.search(r"powershell|\.ps1", l, re.I) for l in code):
    bad.append("a line that runs PowerShell (the ruling is plain cmd)")
labels = {l[1:].strip().lower() for l in lines if l.startswith(":")}
for l in lines:
    for g in re.findall(r"\bgoto\s+:?(\S+)", l, re.I):
        if g.lower() not in labels and g.lower() != "eof":
            bad.append(f"goto {g}: no such label")
    if not l.lower().startswith(("rem", "echo")) and re.search(r"\(\s*$|^\s*\)", l):
        bad.append(f"a parenthesised block ({l.strip()[:40]}): a %VAR% holding '(x86)' would end it early")
if plat == "fbneo":
    need = ['set "BIN=%BINDIR%\\fbneo.exe"', 'set "ROMS=%BINDIR%\\roms"',
            'copy /y "%ZIP%" "%ROMS%\\vsavjw.zip"', 'cd /d "%BINDIR%"', '"%BIN%" vsavjw %*']
else:
    need = ['set "BIN=%BINDIR%\\cps2.exe"', 'cd /d "%HERE%"', '"%BIN%" -listfull vsavjw >nul 2>&1',
            '"%BIN%" vsavjw -rompath "%ZIPDIR%" -skip_gameinfo %*']
for n in need:                      # a line that IS n, or starts with it (a trailing >nul)
    if not any(l == n or l.startswith(n + " ") for l in lines):
        bad.append(f"missing the line: {n}")
for n in ("if not defined PLAY_DRY_RUN goto launch", ":fail", "pause", "exit /b 1"):
    if n not in lines:
        bad.append(f"missing the line: {n}")
for x in bad:
    print("      " + x)
sys.exit(3 if bad else 0)   # 3 = findings; anything else non-zero is the checker itself failing
PYEOF
}

# texts <release dir> -> prints the findings; exit 0 clean, 3 findings. Every shipped text names
# only launchers its own package ships, and no platform marker survived the packager's selection.
texts() {
    _f="$W/texts_found.txt"; : > "$_f"
    for _d in "$1"/*/; do
        _p="$(basename "$_d")"
        for _t in README.md MISTER.md EMULATOR.md apply_release.html; do
            [ -f "$_d$_t" ] || continue
            for _l in PLAY.command PLAY.bat; do
                if grep -qF "$_l" "$_d$_t" && [ ! -f "$_d$_l" ]; then
                    echo "      $_p/$_t names $_l, which the $_p package does not ship ($(grep -cF "$_l" "$_d$_t") line(s))" >> "$_f"
                fi
            done
            if grep -qE '<!--/?(EMU|MISTER)-->' "$_d$_t"; then
                echo "      $_p/$_t carries an unselected platform marker" >> "$_f"
            fi
        done
    done
    cat "$_f"; [ -s "$_f" ] && return 3; return 0
}
# a light copy of the release's texts and launchers (no binaries, no patches)
textcopy() {  # textcopy <dst>
    for _d in "$REL"/*/; do
        _p="$(basename "$_d")"; mkdir -p "$1/$_p"
        for _t in README.md MISTER.md EMULATOR.md apply_release.html PLAY.command PLAY.bat; do
            [ -f "$_d$_t" ] && cp "$_d$_t" "$1/$_p/"
        done
    done
    return 0
}

echo "== test_release_launcher_bat: the Windows launcher for $NAME =="
for p in fbneo mame; do
    src="$W/$p.bat"
    case "$VS_CTL" in lf-endings|launch-line-changed) src="$W/ctl_${VS_CTL}_$p.bat" ;; esac
    rc=0; check "$src" "$p" > "$W/check_$p.txt" 2>&1 || rc=$?
    case "$rc" in
    0) ok "$p: PLAY.bat is CRLF + ASCII, plain cmd, every goto lands, no block, the ruled launch line" ;;
    3) bad "$p: PLAY.bat:"; cat "$W/check_$p.txt" ;;
    *) bad "$p: the checker itself failed (rc=$rc):"; sed 's/^/      /' "$W/check_$p.txt" ;;
    esac
    shipped="$REL/$p/PLAY.bat"
    if [ -f "$shipped" ]; then
        if cmp -s "$shipped" "$W/$p.bat"; then ok "$p: $shipped is the generator's bytes (sha1 shipped $(sha1 "$shipped") = generator $(sha1 "$W/$p.bat"))"
        else bad "$p: $shipped (sha1 $(sha1 "$shipped")) differs from the generator's output (sha1 $(sha1 "$W/$p.bat")) — re-package the release"; fi
    else
        bad "$p: $shipped absent — the release predates #145; re-package it"
    fi
done

echo "-- every package's texts name only the launchers it ships"
TREL="$REL"
if [ "$VS_CTL" = readme-names-absent-launcher ]; then
    TREL="$W/texts_mode"; textcopy "$TREL"; rm -f "$TREL/mame/PLAY.bat"
fi
rc=0; texts "$TREL" > "$W/texts.txt" 2>&1 || rc=$?
case "$rc" in
0) ok "$(ls -d "$TREL"/*/ | wc -l | tr -d ' ') package(s): every README/MISTER.md/EMULATOR.md/apply_release.html names only launchers its package ships; no marker left" ;;
*) bad "package texts:"; cat "$W/texts.txt" ;;
esac

# THE GENERATOR'S EMULATOR CLAIMS (14z-190, GitHub #214): the README the packager writes NOW, rendered
# for each platform through its own select_platform_text(), may claim that the package holds an emulator
# only on an emulator platform. The released tree is not checked for this: merged-m22 shipped before the
# fix (#214 stays open until the next release carries it), so the generator is what is held.
gen_claims() {  # gen_claims <mister selection: mister|fbneo> -> prints findings; exit 0 clean, 3 findings
    python3 - "$REL/fbneo/manifest.json" "$W/gen" "$1" <<'PYEOF'
import json, os, sys
sys.path.insert(0, "tools")
import package_release as pr, package_release_platforms as pp
m = json.load(open(sys.argv[1])); out = sys.argv[2]; mister_sel = sys.argv[3]
CLAIMS = ("This package already contains one", "The emulator here", "Use the emulator in this package")
bad = []
for plat, sel in (("fbneo", "fbneo"), ("mame", "mame"), ("mister", mister_sel)):
    d = os.path.join(out, plat); os.makedirs(d, exist_ok=True)
    open(os.path.join(d, "README.md"), "w").write(pr.readme(None, m, 1, 1))
    pp.select_platform_text(d, sel)
    body = open(os.path.join(d, "README.md")).read()
    has = [c for c in CLAIMS if c in body]
    if plat == "mister" and has:
        bad.append(f"the generator's MiSTer README claims an emulator it does not ship: {has}")
    if plat != "mister" and len(has) != len(CLAIMS):
        bad.append(f"the generator's {plat} README lost an emulator passage (positive control): has {has}")
for x in bad:
    print("      " + x)
sys.exit(3 if bad else 0)
PYEOF
}
echo "-- the generator's README claims an emulator only where its package ships one (#214)"
_sel=mister; [ "$VS_CTL" = emu-text-in-mister ] && _sel=fbneo
rc=0; gen_claims "$_sel" > "$W/gen_claims.txt" 2>&1 || rc=$?
case "$rc" in
0) ok "generator: the MiSTer README makes none of the emulator claims; the fbneo and mame READMEs keep all three" ;;
3) bad "generator README claims:"; cat "$W/gen_claims.txt" ;;
*) bad "the generator check itself failed (rc=$rc):"; sed 's/^/      /' "$W/gen_claims.txt" ;;
esac

# the must-fire controls, in-gate: each perturbation must be caught on EVERY launcher it touches
for c in lf-endings launch-line-changed; do
    got=""; dead=""
    for p in fbneo mame; do
        rc=0; check "$W/ctl_${c}_$p.bat" "$p" > "$W/ctl_${c}_$p.txt" 2>&1 || rc=$?
        if [ "$rc" = 3 ]; then got="$got $p:$(head -1 "$W/ctl_${c}_$p.txt" | sed 's/^ *//')"
        else dead="$dead $p(rc=$rc)"; fi
    done
    if [ -z "$dead" ]; then vs_ctl_fired "$c" "caught on both launchers —$got"
    else vs_ctl_dead "$c" "the perturbed PLAY.bat was not caught on:$dead"; fail=1; fi
done
textcopy "$W/texts_ctl"; rm -f "$W/texts_ctl/mame/PLAY.bat"
rc=0; texts "$W/texts_ctl" > "$W/texts_ctl.txt" 2>&1 || rc=$?
if [ "$rc" = 3 ]; then vs_ctl_fired readme-names-absent-launcher "$(head -1 "$W/texts_ctl.txt" | sed 's/^ *//')"
else vs_ctl_dead readme-names-absent-launcher "a mame package without PLAY.bat whose README names it passed (rc=$rc)"; fail=1; fi
rc=0; gen_claims fbneo > "$W/gen_ctl.txt" 2>&1 || rc=$?
if [ "$rc" = 3 ]; then vs_ctl_fired emu-text-in-mister "$(head -1 "$W/gen_ctl.txt" | sed 's/^ *//')"
else vs_ctl_dead emu-text-in-mister "the MiSTer README rendered with the emulator selection passed (rc=$rc)"; fail=1; fi

# ── ON WINDOWS: both .bat files driven by cmd, dry run (nothing is launched past the checks) ──
case "$(uname -s)" in
MINGW*|MSYS*|CYGWIN*) ON_WIN=1 ;;
*) ON_WIN=0 ;;
esac
if [ "$ON_WIN" = 0 ] || ! command -v cmd >/dev/null 2>&1; then
    echo "  SKIP (said): the cmd-driven paths run only on a Windows host (MSYS2); this is $(uname -s)"
else
    # the bytes driven are the SHIPPED ones (asserted equal to the generator's above)
    DRV_fbneo="$REL/fbneo/PLAY.bat"; DRV_mame="$REL/mame/PLAY.bat"
    echo "  driving: fbneo PLAY.bat sha1 $(sha1 "$DRV_fbneo") ($DRV_fbneo), mame PLAY.bat sha1 $(sha1 "$DRV_mame") ($DRV_mame)"
    drive() {  # drive <dir> -> $OUT, $RC
        OUT="$W/drive.txt"; RC=0
        ( cd "$1" && PLAY_DRY_RUN=1 cmd //c PLAY.bat </dev/null ) > "$OUT" 2>&1 || RC=$?
    }
    refuse() {  # refuse <label> <dir> <expected message fragment>
        drive "$2"
        if [ "$RC" != 0 ] && grep -qF "$3" "$OUT"; then ok "windows: $1 refused (rc=$RC): $3"
        else bad "windows: $1 — rc=$RC, expected a refusal naming '$3'"; sed 's/^/      /' "$OUT" | head -6; fi
    }

    # FBNeo: the profile check is findstr over the FILE, so a text stub is exact
    stage_fb() {  # stage_fb <dir> <marker yes|no> <zip yes|no> <bin yes|no>
        rm -rf "$1"; mkdir -p "$1/emulator/bin/windows-x86_64" "$1/rompath"
        cp "$DRV_fbneo" "$1/PLAY.bat"
        if [ "$4" = yes ]; then
            if [ "$2" = yes ]; then printf 'stub, not a program: CPS-2 WIDE v1\n' > "$1/emulator/bin/windows-x86_64/fbneo.exe"
            else printf 'stub, not a program: stock\n' > "$1/emulator/bin/windows-x86_64/fbneo.exe"; fi
        fi
        [ "$3" = yes ] && printf 'not-a-rom' > "$1/rompath/vsavjw.zip"
        return 0
    }
    D="$W/fb_ok"; stage_fb "$D" yes yes yes; drive "$D"
    if [ "$RC" = 0 ] && grep -q "WOULD RUN: .*fbneo.exe\" vsavjw" "$OUT" && [ -f "$D/emulator/bin/windows-x86_64/roms/vsavjw.zip" ]; then
        ok "windows: fbneo dry run reaches 'fbneo.exe vsavjw' with roms\\vsavjw.zip beside it"
    else bad "windows: fbneo dry run rc=$RC"; sed 's/^/      /' "$OUT" | head -8; fi
    D="$W/fb_nozip"; stage_fb "$D" yes no yes; refuse "fbneo, no romset" "$D" "vsavjw.zip not found"
    D="$W/fb_nobin"; stage_fb "$D" yes yes no; refuse "fbneo, no binary" "$D" "no prebuilt fbneo for windows-x86_64"
    D="$W/fb_stock"; stage_fb "$D" no yes yes; refuse "fbneo, an emulator without the profile" "$D" "does not carry the CPS-2 WIDE profile"
    D="$W/fb_junction"; stage_fb "$D" yes yes yes; mkdir -p "$W/elsewhere"
    # `//J`, not `/J`: MSYS2 rewrites a bare /J argument as a path before cmd sees it
    ( cd "$D/emulator/bin/windows-x86_64" && cmd //c mklink //J roms "$(cygpath -w "$W/elsewhere")" ) > "$W/mklink.txt" 2>&1
    if ( cd "$D/emulator/bin/windows-x86_64" && cmd //c "dir /al" ) 2>/dev/null | grep -qi "roms"; then
        refuse "fbneo, a junctioned roms\\" "$D" "link or junction"
    else
        bad "windows: the junction case was not exercised — mklink did not create one:"; sed 's/^/      /' "$W/mklink.txt" | head -3
    fi

    # MAME: the profile check RUNS the binary (`cps2.exe -listfull vsavjw`), so the stub must be
    # a real program — two are compiled here, one that knows vsavjw and one that does not
    CC="$(command -v gcc || command -v cc || true)"
    if [ -z "$CC" ]; then
        bad "windows: no C compiler in this shell, so the MAME launcher's paths cannot run (install mingw-w64-x86_64-gcc) — never skipped: they went unrun once"
    else
        cat > "$W/stub.c" <<'CEOF'
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv) {
    for (int i = 1; i < argc; i++)
        if (!strcmp(argv[i], "-listfull")) {
#if WIDE
            puts("Name:             Description:"); puts("vsavjw           \"Vampire Saved (stub)\""); return 0;
#else
            fprintf(stderr, "No matching machines found for 'vsavjw'\n"); return 1;
#endif
        }
    puts("stub cps2: started"); return 0;
}
CEOF
        "$CC" -DWIDE=1 -o "$W/cps2_wide.exe" "$W/stub.c" > "$W/cc.txt" 2>&1 \
            && "$CC" -DWIDE=0 -o "$W/cps2_stock.exe" "$W/stub.c" >> "$W/cc.txt" 2>&1 \
            || { bad "windows: the cps2 stubs did not compile:"; sed 's/^/      /' "$W/cc.txt" | head -4; }
        stage_mm() {  # stage_mm <dir> <stub wide|stock|none> <zip yes|no>
            rm -rf "$1"; mkdir -p "$1/emulator/bin/windows-x86_64" "$1/rompath"
            cp "$DRV_mame" "$1/PLAY.bat"
            [ "$2" != none ] && cp "$W/cps2_$2.exe" "$1/emulator/bin/windows-x86_64/cps2.exe"
            [ "$3" = yes ] && printf 'not-a-rom' > "$1/rompath/vsavjw.zip"
            return 0
        }
        if [ -f "$W/cps2_wide.exe" ] && [ -f "$W/cps2_stock.exe" ]; then
            D="$W/mm_ok"; stage_mm "$D" wide yes; drive "$D"
            DW="$(cygpath -w "$D")"
            if [ "$RC" = 0 ] && grep -qF "cps2.exe\" vsavjw -rompath \"$DW\\rompath\" -skip_gameinfo" "$OUT"; then
                ok "windows: mame dry run reaches 'cps2.exe vsavjw -rompath <the set's folder> -skip_gameinfo'"
            else bad "windows: mame dry run rc=$RC"; sed 's/^/      /' "$OUT" | head -8; fi
            D="$W/mm_nozip"; stage_mm "$D" wide no; refuse "mame, no romset" "$D" "vsavjw.zip not found"
            D="$W/mm_nobin"; stage_mm "$D" none yes; refuse "mame, no binary" "$D" "no prebuilt mame for windows-x86_64"
            D="$W/mm_stock"; stage_mm "$D" stock yes; refuse "mame, a stock cps2.exe that does not know vsavjw" "$D" "does not know the vsavjw driver"
        fi
    fi
fi

[ "$fail" = 0 ] && echo "PASS: test_release_launcher_bat" || { echo "FAIL: test_release_launcher_bat"; exit 1; }
