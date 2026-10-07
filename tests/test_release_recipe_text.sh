#!/bin/sh
# test_release_recipe_text.sh — THE `-recipe` ASSET'S TEXT CAN BE FOLLOWED AS WRITTEN (14z-194,
# GitHub #238, #240).
#
# WHAT: the EMULATOR.md the generator writes for each emulator platform carries the Linux MAME
#   build line with the same Qt-debugger switch the project's own Linux builds use, names the
#   build dependencies per OS (qmake6 on Linux for MAME, which tools/setup_mame.sh refuses
#   without), points at no file the asset does not hold, and describes -verifyroms without the
#   "exactly the members inside vsavjw.zip" overstatement; the README's by-hand step no longer
#   says the set was built "in step 1" (step 1 is the emulator) and tells a recipe player that
#   the launchers run only a prebuilt program.
# HOW: tools/package_release_platforms.py's emulator_side() rendered into a scratch directory for
#   fbneo and mame (binaries_side stubbed out: text only), the switch read from tools/setup_mame.sh
#   (QTFLAG) and tools/build_release_emulators.sh (QTNOTE) and required on the rendered Linux make
#   line; the qmake6 requirement read from setup_mame.sh's refusal; three controls perturb the
#   rendered text the way each defect looked before the fix.
# EXPECTS: every check ok on both platforms; each control fails its check.
#
# WHY. #226 step 3 (14z-194) followed the merged-m23 `-recipe` assets on PILOT exactly as written:
# the MAME build stopped after 32 s on "Qt's Meta Object Compiler (moc) wasn't found!" (the
# switch our own builds pass on Linux was missing from the shipped text), and neither recipe named
# a dependency; the README sent a recipe player to a launcher that only runs a prebuilt binary.
#
# MUST-FIRE: perturbed-copy: qtdebug-dropped — the rendered MAME EMULATOR.md with USE_QTDEBUG=0 taken off its Linux make line must FAIL: that is #238, the recipe that stops on a missing moc
# MUST-FIRE: perturbed-copy: deps-dropped — the rendered MAME EMULATOR.md without its Linux dependency line must FAIL: without qmake6 the build dies minutes in on char8_t, and nothing tells the reader why
# MUST-FIRE: perturbed-copy: step1-wording — the rendered README with the pre-#240 "the vsavjw.zip you built in step 1" must FAIL: in the recipe flow step 1 is the emulator, not the set
#
# Usage: tests/test_release_recipe_text.sh      # ci_portable, ~1 s, no ROMDIR, no emulator, no ROM bytes
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
case "${VS_CTL:-}" in ""|qtdebug-dropped|deps-dropped|step1-wording) ;;
*) echo "REFUSED: CONTROL=$VS_CTL is not a mode of this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

render() {  # render <dir> — the generator's EMULATOR.md + README play section for fbneo and mame
    python3 - "$1" <<'PYEOF'
import os, sys
sys.path.insert(0, "tools")
import package_release_platforms as pp
pp.binaries_side = lambda platform, edir: []      # text only: no binary is read or copied
out = sys.argv[1]
for plat in ("fbneo", "mame"):
    d = os.path.join(out, plat); os.makedirs(d, exist_ok=True)
    open(os.path.join(d, "README.md"), "w").write("<!--PLAY-->\n")
    pp.emulator_side(plat, d, "merged-m99")
PYEOF
}

perturb() {  # perturb <control> <dir> — the defect as it looked before the fix
    python3 - "$1" "$2" <<'PYEOF'
import os, re, sys
c, d = sys.argv[1:3]
def edit(p, f):
    s = open(p).read(); t = f(s); assert t != s, (c, p); open(p, "w").write(t)
if c == "qtdebug-dropped":
    edit(os.path.join(d, "mame", "EMULATOR.md"), lambda s: s.replace(" USE_QTDEBUG=0", ""))
elif c == "deps-dropped":
    edit(os.path.join(d, "mame", "EMULATOR.md"), lambda s: re.sub(r"(?m)^- \*\*Linux.*\n(  .*\n)*", "", s))
elif c == "step1-wording":
    edit(os.path.join(d, "fbneo", "README.md"),
         lambda s: s.replace("Put the `vsavjw.zip` you built from your dumps (the README's first part)",
                             "Put the `vsavjw.zip` you built in step 1"))
PYEOF
}

check() {  # check <dir> -> findings on stdout; exit 0 clean, 3 findings
    python3 - "$1" <<'PYEOF'
import os, re, sys
d = sys.argv[1]
bad = []
setup = open("tools/setup_mame.sh").read()
builder = open("tools/build_release_emulators.sh").read()
m1 = re.search(r'if \[ "\$\(uname -s\)" = Linux \]; then QTFLAG="([^"]+)"', setup)
m2 = re.search(r'if \[ "\$HOSTOS" = linux \]; then QTNOTE=" ([^"]+)"', builder)
if not m1 or not m2:
    bad.append("could not read the Linux Qt switch from setup_mame.sh / build_release_emulators.sh")
    flag = None
else:
    flag = m1.group(1)
    if m2.group(1) != flag:
        bad.append(f"setup_mame.sh ({flag}) and build_release_emulators.sh ({m2.group(1)}) disagree")
needs_qmake = "apt install -y qmake6" in setup
for plat in ("fbneo", "mame"):
    emd = open(os.path.join(d, plat, "EMULATOR.md")).read()
    rd = open(os.path.join(d, plat, "README.md")).read()
    if "docs/GOTCHAS.md" in emd:
        bad.append(f"{plat}: EMULATOR.md points at docs/GOTCHAS.md, which the asset does not carry")
    for os_name in ("Linux", "macOS", "Windows"):
        if not re.search(rf"(?m)^- \*\*{os_name}\b", emd):
            bad.append(f"{plat}: EMULATOR.md names no {os_name} dependencies")
    if "you built in step 1" in rd:
        bad.append(f"{plat}: README step 3 says the set was built in step 1 (step 1 is the emulator)")
    if "only\n   run a prebuilt program" not in rd and "only run a prebuilt program" not in rd:
        bad.append(f"{plat}: README does not tell a recipe player the launchers run only a prebuilt program")
    if plat == "mame":
        lines = [l for l in emd.splitlines() if "make SOURCES=" in l and "LINUX" in l]
        if flag and not any(flag in l for l in lines):
            bad.append(f"mame: no Linux make line carrying {flag} (the switch the project's Linux builds pass)")
        deps = re.search(r"(?m)^- \*\*Linux.*$", emd)
        if needs_qmake and (not deps or "qmake6" not in deps.group(0)):
            bad.append("mame: the Linux dependency line does not name qmake6 (setup_mame.sh refuses without it)")
        if "exactly the" in emd:
            bad.append("mame: the -verifyroms comment says it lists exactly the members inside vsavjw.zip")
        if not re.search(r"(?m)^\s+\./cps2 vsavjw -rompath .*-skip_gameinfo", emd):
            bad.append("mame: no by-hand play line with -skip_gameinfo")
for x in bad:
    print("      " + x)
sys.exit(3 if bad else 0)
PYEOF
}

echo "== test_release_recipe_text: the -recipe asset's text, as the generator writes it (#238, #240) =="
fail=0
render "$W/real" > "$W/render.log" 2>&1 || { echo "FAIL: the generator did not render:"; sed 's/^/      /' "$W/render.log"; exit 1; }
[ -z "${VS_CTL:-}" ] || { echo "  mode: $VS_CTL applied to the rendered text"; perturb "$VS_CTL" "$W/real"; }
rc=0; check "$W/real" > "$W/check.txt" 2>&1 || rc=$?
case "$rc" in
0) echo "  ok    both EMULATOR.md: dependencies per OS, no missing-file pointer; mame: the Linux line carries the switch the project's builds use, qmake6 named, -verifyroms described, a play line; both READMEs: step 3 for a recipe player" ;;
3) echo "  FAIL  the rendered recipe text:"; cat "$W/check.txt"; fail=1 ;;
*) echo "  FAIL  the check itself failed (rc=$rc):"; sed 's/^/      /' "$W/check.txt"; fail=1 ;;
esac

if [ -z "${VS_CTL:-}" ]; then
    for c in qtdebug-dropped deps-dropped step1-wording; do
        render "$W/$c" > /dev/null 2>&1
        if ! perturb "$c" "$W/$c" > "$W/$c.perturb" 2>&1; then
            vs_ctl_dead "$c" "the perturbation did not apply: $(tail -1 "$W/$c.perturb")" || true; fail=1; continue
        fi
        rc=0; check "$W/$c" > "$W/$c.txt" 2>&1 || rc=$?
        if [ "$rc" = 3 ]; then vs_ctl_fired "$c" "$(head -1 "$W/$c.txt" | sed 's/^ *//')"
        else vs_ctl_dead "$c" "the perturbed text passed (rc=$rc)" || true; fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: test_release_recipe_text"; exit 0; fi
echo "FAIL: test_release_recipe_text"; exit 1
