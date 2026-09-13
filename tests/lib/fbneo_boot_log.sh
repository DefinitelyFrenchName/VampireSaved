#!/bin/sh
# fbneo_boot_log.sh — what a HEALTHY FBNeo boot of the WIDE romset must show in
# its log. Sourced by tests/test_release_binaries.sh (the real boot, on every
# release host) and tests/test_fbneo_boot_log.sh (ground truth over RECORDED
# logs, ROM-free). ONE copy, so the verdict logic proven on a Mac is the logic a
# Windows host runs.
#
# vs_fbneo_boot_log <log> <hostos> <patch>
#   Prints FAIL lines, plus one "(windows: …)" line where a check cannot apply;
#   returns 1 on any FAIL. <patch> is emu/fbneo-patches/0002-cps2-wide-v1.patch,
#   the patch the release binary is built from.
#
# WHAT IT ASSERTS, and why each is keyed the way it is (2026-09-13):
#  1. THE PREMISE, from the patch: the vsavjw driver entry starts through
#     Cps2WideInit, and that function's first statement is `Cps2Wide = 1;`.
#     Asserted so the inference in 2 cannot silently lose its footing.
#  2. EVERY member of the patch's VsavjwRomDesc loads "(OK)", and nothing else
#     does. The loads run inside Cps2Init, which Cps2WideInit calls after
#     setting the flag (the macOS log prints the profile line, then the loads),
#     so on ANY host they prove the WIDE init ran. An unreadable or vsw-less
#     descriptor REFUSES: "every member of nothing loaded" is the vacuous green
#     [VSP-148] is about.
#  3. `CPS-2 WIDE v1 profile active` WHEREVER THE EMULATOR CORE'S MESSAGES REACH
#     THE LOG AT ALL — detected by the core's own `*** Starting emulation of`
#     line, not by the OS name. FBNeo's SDL frontend connects the core's message
#     function only `#if defined(BUILD_SDL2) && !defined(SDL_WINDOWS)`
#     (src/burner/sdl/main.cpp at our pin), so on Windows it stays burn.cpp's
#     no-op filler and every core line is dropped, the profile line with them —
#     measured on the first Windows boot of the release binary, where the gate
#     went red on a correct boot (docs/platform/gotchas.md). Keyed on the
#     evidence, a future FBNeo that prints on Windows gets the stronger check
#     back by itself, and a macOS/Linux log with no core line still FAILS.
#  4. No "not found" / "error" line anywhere in the log.
vs_fbneo_boot_log() {  # vs_fbneo_boot_log <log> <hostos> <patch>
    python3 - "$1" "$2" "$3" <<'PY'
import re, sys
log, hostos, patch = sys.argv[1:]
text = open(log, errors="replace").read()
p = open(patch, errors="replace").read()
bad = []

# 1. the premise
drv = re.search(r"^\+struct BurnDriver BurnDrvCpsVsavjw = \{\n(.*?)^\+\};", p, re.S | re.M)
if not (drv and re.search(r"^\+\s*Cps2WideInit,", drv.group(1), re.M)):
    bad.append("patch: the vsavjw driver entry does not start through Cps2WideInit — its member loads would not prove the WIDE init")
init = re.search(r"^\+static INT32 Cps2WideInit\(\)\n\+\{\n\+\s*(.*?)\n", p, re.M)
if not (init and init.group(1).strip() == "Cps2Wide = 1;"):
    bad.append("patch: Cps2WideInit does not open with `Cps2Wide = 1;` — its member loads would not prove the flag is set")

# 2. every descriptor member loads (OK), and nothing else does
desc = re.search(r"^\+static struct BurnRomInfo VsavjwRomDesc\[\] = \{\n(.*?)^\+\};", p, re.S | re.M)
want = re.findall(r'^\+\s*\{\s*"([^"]+)"', desc.group(1), re.M) if desc else []
if not want or not any(n.startswith("vsw.") for n in want):
    bad.append(f"patch: could not read the vsavjw descriptor ({len(want)} rows, none of them vsw.*) — REFUSING to call an empty member list loaded")
    want = []
got = []
for line in text.splitlines():
    if "(OK)" not in line:
        continue
    m = re.match(r"^Loading (?:[a-z]+ \(([^)]+)\)|(\S+))\.\.\. \(OK\)\s*$", line)
    if not m:
        bad.append(f"log: an (OK) line this check cannot read: {line!r}")
        continue
    got.append(m.group(1) or m.group(2))
if want:
    missing = [n for n in want if n not in got]
    extra = [n for n in got if n not in want]
    dup = sorted({n for n in got if got.count(n) > 1})
    if missing:
        bad.append(f"log: {len(missing)} of the {len(want)} vsavjw members never loaded (OK): {' '.join(missing)}")
    if extra:
        bad.append(f"log: loaded (OK) but not a vsavjw member: {' '.join(extra)}")
    if dup:
        bad.append(f"log: loaded (OK) more than once: {' '.join(dup)}")

# 3. the profile line, wherever the core's messages print at all
note = ""
core = re.search(r"^\*\*\* Starting emulation of (\S+)", text, re.M)
prof = re.search(r"^CPS-2 WIDE v1 profile active\s*$", text, re.M)
if core:
    if core.group(1) != "vsavjw":
        bad.append(f"log: the core started {core.group(1)}, not vsavjw")
    elif not prof:
        bad.append("log: the core's messages reach this log (`*** Starting emulation of vsavjw`) but `CPS-2 WIDE v1 profile active` does not — vsavjw booted without the WIDE init")
elif hostos == "windows":
    note = ("  (windows: FBNeo's SDL frontend never connects the emulator core's message function here, so no core line"
            " and no profile line can print — the WIDE init is proven by every vsavjw member loading)")
else:
    bad.append(f"log: no `*** Starting emulation of` line on {hostos}, where FBNeo prints the core's messages — the boot never started, or its output went elsewhere")

# 4. no error
errs = [l for l in text.splitlines() if re.search(r"not found|error", l, re.I)]
if errs:
    bad.append("log: carries an error: " + " | ".join(errs[:3]))

if note:
    print(note)
for b in bad:
    print("FAIL: fbneo boot " + b)
sys.exit(1 if bad else 0)
PY
}
