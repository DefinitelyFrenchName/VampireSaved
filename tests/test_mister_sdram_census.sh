#!/bin/sh
# test_mister_sdram_census.sh — SLICE D2'S CORE EVIDENCE: the CPS-2 WIDE romset
# lands in SDRAM exactly where docs/project/mister_map.md section 5 places it.
# (14z-107 (9).)
#
# WHY A CENSUS AND NOT A REPLAY. D2 PLACES the romset; the fetch that READS
# group C is the obj promote, and that is slice D3. Nothing in D2 changes a
# single frame of anything, by design — so a replay would prove nothing and a
# green replay would prove nothing twice. What D2 can be held to, completely,
# is the SDRAM IMAGE: download the WIDE `.rom` in the simulator, dump all four
# 16 MB banks, and check every one of the 67,108,864 bytes against the map.
# tools/mister_sdram_census.py replays the download mapping (including the
# CPS-2 GFX address scramble) and compares byte for byte, so a region at the
# wrong offset, a region in the wrong BANK, and a byte written anywhere the map
# says nothing lives all fail the same way.
#
# THE FOUR LEGS, and what each one is for:
#   A  cps2w + WIDE  vs the WIDE map   — THE CENSUS.
#   B  cps2  + WIDE  vs the STOCK map  — the REFERENCE core placing the same
#      image the reference way. It is also leg A's must-fire control: without
#      the redirect, group C (GFX bytes 32-48 MB) ALIASES onto banks 2+3,
#      because jtcps1_prom_we drops gfx_addr[25]. So B's banks 2+3 must DIFFER
#      from A's, and B must FAIL the WIDE map.
#      **Note what leg B is NOT: the reference core cannot BUILD the WIDE
#      image.** `cores/cps2` parses `sourcefile=["cps2.cpp"]` and the WIDE
#      machine entry is tagged `cps2w.cpp`, so `jtframe mra cps2` emits no
#      WIDE MRA and no `.rom` — slice D0's profile gate, working. Measured the
#      hard way 14z-107 (9): the first version of this gate asked it to and
#      got "no vsavjw.rom was produced". `run_sim_jtcps2.sh --wide` therefore
#      always GENERATES the image with `cps2w` and only SIMULATES with
#      `--core`.
#   C  cps2w + stock vs the WIDE map   — the bank-0 re-pack, measured on a
#      stock image: PRG/Z80 at the new offsets, no group C, no PCM high, and
#      banks 2+3 exactly as vanilla.
#   D  cps2  + stock vs the STOCK map  — the calibration leg. It is the run in
#      which the census tool is checked against a mapping NOBODY changed; if
#      the tool's model of the download were wrong, D is where it shows.
#
# CROSS-CHECKS BETWEEN LEGS (independent of the tool's model):
#   * C vs D: banks 1, 2 and 3 must be BYTE-IDENTICAL — the re-pack is confined
#     to bank 0 — and bank 0 must DIFFER, or the comparison is vacuous.
#   * A vs B: banks 2 and 3 must DIFFER — the group-C redirect is doing work.
#
# MUST-FIRE CONTROLS ON THE TOOL: leg A re-run with one placement constant of
# the EXPECTED map moved by 1 KiB (`--perturb`) must be REJECTED. Two are run,
# one per bank (z80 in bank 0, gfxc4 in bank 1), because a census that cannot
# say no is not evidence.
#
# COST: four Verilator runs, each paying its ROM transfer (~8 min for the
# 46 MB stock image, ~12 min for the 66 MB WIDE one) and nothing after it —
# `test.cpp:915` dumps the banks the instant the download completes, so
# `--post-frames 2` is enough. ~45 min total. EMULATOR tier: not in
# ci_portable/ci_static.
#
# Usage: ROMDIR=... [JTSIM_SCRATCH=...] [CENSUS_KEEP=<dir outside the repo>]
#        tests/test_mister_sdram_census.sh
#   CENSUS_KEEP re-uses bank images already dumped there instead of simulating.
#   It is a CACHE and it is not validated against the RTL that produced it —
#   delete it after any RTL change.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0; ok(){ echo "  PASS $1"; }; bad(){ echo "  FAIL $1"; fail=1; }

[ -n "${ROMDIR:-}" ] || { echo "SKIP: ROMDIR unset (this gate runs the real romset)"; exit 77; }
command -v verilator >/dev/null 2>&1 || { echo "SKIP: verilator not installed (docs/platform/mister.md Recipe)"; exit 77; }
[ -f "$REPO/emu/jtcores/.gitmodules" ] || { echo "SKIP: emu/jtcores not initialised (tools/setup_jtcores.sh)"; exit 77; }
BUILD="${CENSUS_BUILD:-build/m3b_merged18}"  # re-pointed 14z-115 (select-wheel freeze) <- 14z-113 (merged-m10: one-zip repackaging of merged-m9, same program)
[ -f "$REPO/$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE romset at $BUILD/rompath/vsavjw.zip"; exit 77; }

RPL="$REPO/tests/replays/05_timeout_idle.rpl"
if [ -n "${CENSUS_KEEP:-}" ]; then
    mkdir -p "$CENSUS_KEEP"
    W="$(CDPATH= cd "$CENSUS_KEEP" && pwd)"
    case "$W/" in "$REPO"/*) echo "REFUSING: CENSUS_KEEP is inside the repo (rule 7)"; exit 2 ;; esac
    echo "note: CENSUS_KEEP=$W — legs whose banks already exist are NOT re-simulated"
else
    W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fi

# leg <name> <core> <stock|wide>
leg() {
    _n="$1"; _core="$2"; _set="$3"
    if [ -s "$W/$_n/sdram/sdram_bank0.bin" ] && [ -s "$W/$_n/sdram/sdram_bank3.bin" ]; then
        echo "== leg $_n ($_core, $_set): re-using cached bank images =="
        return 0
    fi
    echo "== leg $_n ($_core, $_set romset): download + dump all four banks =="
    rm -rf "$W/$_n"
    if [ "$_set" = wide ]; then _w="--wide $BUILD"; else _w=""; fi
    # shellcheck disable=SC2086
    "$REPO/tools/run_sim_jtcps2.sh" "$RPL" "$W/$_n" --core "$_core" $_w \
        --frame-output off --post-frames 2 --keep-banks \
        || { bad "leg $_n did not complete"; return 1; }
}

census() {   # census <verdict pass|fail> <leg> <map> [extra args...]
    _want="$1"; _n="$2"; _map="$3"; shift 3
    if [ ! -s "$W/$_n/rom_path.txt" ] || [ ! -s "$W/$_n/sdram/sdram_bank0.bin" ]; then
        bad "census $_n: that leg produced no image, so nothing was compared"
        return
    fi
    if python3 "$REPO/tools/mister_sdram_census.py" "$W/$_n/sdram" \
            --rom "$(cat "$W/$_n/rom_path.txt")" --map "$_map" "$@" > "$W/$_n.$_map.out" 2>&1
    then _got=pass; else _got=fail; fi
    if [ "$_got" = "$_want" ]; then
        sed -n 's/^  \(PASS\|FAIL\) bank/       \1 bank/p' "$W/$_n.$_map.out"
        ok "census $_n vs the $_map map: $_want, as expected $*"
    else
        bad "census $_n vs the $_map map: expected $_want, got $_got"
        sed 's/^/       /' "$W/$_n.$_map.out" | head -40
    fi
}

for spec in "A cps2w wide" "B cps2 wide" "C cps2w stock" "D cps2 stock"; do
    # shellcheck disable=SC2086
    set -- $spec
    leg "$1" "$2" "$3" || continue
    # the .rom is rebuilt per (core,setname) in the scratch clone and would be
    # overwritten by the next leg, so keep the bytes this leg actually used.
    S="${JTSIM_SCRATCH:-${TMPDIR:-/tmp}/vampire-saved-jtsim}"
    if [ "$3" = wide ]; then R="$S/rom/vsavjw.rom"; else R="$S/rom/vsavj.rom"; fi
    if [ ! -s "$W/$1/rom_used.bin" ]; then cp "$R" "$W/$1/rom_used.bin"; fi
    printf '%s\n' "$W/$1/rom_used.bin" > "$W/$1/rom_path.txt"
done

echo
echo "== A: THE CENSUS (cps2w + the WIDE romset, against the D2 map) =="
census pass A wide
echo "== B: the reference core placing the same image the reference way =="
census pass B stock
echo "== B: ...and it must FAIL the WIDE map (no redirect, group C aliases) =="
census fail B wide
echo "== C: the bank-0 re-pack on a stock image =="
census pass C wide
echo "== D: calibration — the reference core, the reference map =="
census pass D stock

echo
echo "== cross-check: the re-pack is confined to bank 0 (C vs D) =="
same=0; diff=0
for b in 1 2 3; do
    if cmp -s "$W/C/sdram/sdram_bank$b.bin" "$W/D/sdram/sdram_bank$b.bin"
    then same=$((same + 1)); else diff=$((diff + 1)); echo "      bank $b DIFFERS"; fi
done
[ "$same" = 3 ] && ok "banks 1, 2 and 3 are BYTE-IDENTICAL between cps2w and cps2 on the stock image" \
                || bad "the re-pack moved something outside bank 0 ($diff of 3 banks differ)"
if cmp -s "$W/C/sdram/sdram_bank0.bin" "$W/D/sdram/sdram_bank0.bin"
then bad "CONTROL DID NOT FIRE: bank 0 is identical too, so the comparison above is vacuous"
else ok "control fired: bank 0 DOES differ (the Z80 region moved 0x700000 -> 0x658000)"; fi

echo "== cross-check: the group-C redirect is doing work (A vs B) =="
# BOTH SIDES MUST EXIST FIRST. `cmp -s` on a MISSING file reports "differ",
# so a leg that never ran would make this comparison pass vacuously — which
# is exactly what this gate's first run did, with leg B absent (14z-107 (9)).
if [ ! -s "$W/B/sdram/sdram_bank2.bin" ] || [ ! -s "$W/B/sdram/sdram_bank3.bin" ]; then
    bad "leg B produced no bank images — the A-vs-B cross-check cannot run"
else
    n=0
    for b in 2 3; do cmp -s "$W/A/sdram/sdram_bank$b.bin" "$W/B/sdram/sdram_bank$b.bin" || n=$((n + 1)); done
    [ "$n" = 2 ] && ok "banks 2 and 3 DIFFER between cps2w and cps2 on the WIDE image — without the redirect group C aliases onto vanilla's art" \
                 || bad "banks 2+3 agree between the two cores on the WIDE image ($n of 2 differ) — the redirect changed nothing"
fi

echo
echo "== must-fire controls: a 1 KiB perturbation of the expected map =="
# NOTE THE VERDICT: with --perturb the TOOL's own exit status is 0 when the
# perturbed map is correctly REJECTED — it is reporting that ITS control
# fired — so the expectation here is `pass`. Getting this backwards makes the
# control vacuous, which is what this gate's first run did (14z-107 (9)).
# And pcm_lo, not gfxc4, for the bank-1 control: bank 1 is EXACTLY FULL, so
# moving obj bank 4 up by 1 KiB does not make a WRONG map, it makes an
# OVERFLOW, and the tool refuses before comparing anything. Shifting the PCM
# region instead makes obj bank 4's first KiB disagree, which is the failure
# this control is supposed to demonstrate.
census pass A wide --perturb z80 --perturb-kib 1
census pass A wide --perturb pcm_lo --perturb-kib 1

[ $fail = 0 ] && echo "PASS test_mister_sdram_census" \
              || { echo "FAIL test_mister_sdram_census"; exit 1; }
