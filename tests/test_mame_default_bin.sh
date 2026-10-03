#!/bin/sh
# test_mame_default_bin.sh — with MAME_BIN unset, tools/run_mame.sh runs the PINNED build for the set, never the
# `mame` on PATH (14z-189, #196). ci_portable: no ROM, no build dir, no emulator, ~1 s.
#
# WHAT: tools/run_mame.sh's binary choice — MAME_BIN when set; unset, the pinned WIDE build for `vsavjw` and the
#   pinned reference build for any stock set (maintainer-ruled 2026-10-02, "By set name"); a missing pinned default
#   is REFUSED (exit 2), never replaced by PATH's `mame`.
# HOW: runs a copy of the wrapper under a fake HOME holding two stub binaries that print their own name, with a
#   third stub named `mame` first on PATH, and reads which one ran for vsavjw, vsavj and vsav2, with MAME_BIN set,
#   and with the reference stub removed. The control runs a copy whose default is the old `${MAME_BIN:-mame}`.
# EXPECTS: vsavjw -> wide, vsavj -> ref, vsav2 -> ref, MAME_BIN -> that binary, missing default -> exit 2 naming it,
#   and the PATH stub never runs.
#
# MUST-FIRE: perturbed-copy: path-fallback — a copy of tools/run_mame.sh whose unset-MAME_BIN default is the old `${MAME_BIN:-mame}` must run the PATH stub and fail (mode: that copy is the wrapper tested)
#
# WHY. Until 14z-189 an unset MAME_BIN ran whatever `mame` was on PATH — Homebrew 0.288 on the Mac, the source-build
# shim on ERIS/PILOT, nothing at all on a fresh Linux host — so a gate run BY HAND outside the runner measured with a
# host-dependent instrument (#196). Measured before the change (build/agent189/t196/, STATE 14z-189): the 15 gates
# that never set MAME_BIN gave the same verdict and output under the PATH binary, the reference build and the WIDE
# build, teardown-segfault PIDs aside; the runner exports MAME_BIN, so a tier is unchanged.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok() { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; fail=1; }

mkstub() {  # mkstub <path> <name>
    mkdir -p "$(dirname "$1")"
    printf '#!/bin/sh\necho "RAN %s $1"\n' "$2" > "$1"; chmod +x "$1"
}
setup() {  # setup <root>: a fake HOME with both pinned stubs, a PATH dir with a `mame` stub
    rm -rf "$1"; mkdir -p "$1/home" "$1/bin" "$1/roms"
    mkstub "$1/home/.cache/vampire-saved/mame/cps2" wide
    mkstub "$1/home/.cache/vampire-saved/mame-ref/cps2" ref
    mkstub "$1/bin/mame" path
}
# the perturbation, ONE function for the control and the mode
old_default() {  # old_default <src> <dst>: the pre-#196 wrapper — an unset MAME_BIN runs `mame` on PATH
    python3 - "$1" "$2" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
s = re.sub(r'if \[ -z "\$\{MAME_BIN:-\}" \]; then\n    case "\$SET" in.*?\nfi\nexec "\$MAME_BIN"', 'exec "${MAME_BIN:-mame}"', s, flags=re.S)
open(sys.argv[2], "w").write(s)
PY
}
run() {  # run <wrapper> <root> <set> [MAME_BIN] -> the stub's RAN line, or "EXIT <rc>: <stderr head>"
    _o="$(cd "$2" && env -u MAME_BIN HOME="$2/home" PATH="$2/bin:$PATH" ROMDIR="$2/roms" ${4:+MAME_BIN="$4"} \
        sh "$1" "$3" 2>"$2/err")"; _rc=$?
    case "$_o" in RAN*) echo "$_o" | cut -d' ' -f1-2 ;; *) echo "EXIT $_rc: $(head -1 "$2/err")" ;; esac
}
check() {  # check <wrapper> <root> — the assertions; returns 1 on any FAIL
    _f=0
    setup "$2"
    for c in "vsavjw:RAN wide" "vsavj:RAN ref" "vsav2:RAN ref"; do
        got="$(run "$1" "$2" "${c%%:*}")"
        if [ "$got" = "${c#*:}" ]; then ok "MAME_BIN unset, set ${c%%:*}: $got"
        else bad "MAME_BIN unset, set ${c%%:*}: got '$got', want '${c#*:}'"; _f=1; fi
    done
    mkstub "$2/explicit" explicit
    got="$(run "$1" "$2" vsavj "$2/explicit")"
    if [ "$got" = "RAN explicit" ]; then ok "MAME_BIN set: $got"; else bad "MAME_BIN set: got '$got'"; _f=1; fi
    rm -f "$2/home/.cache/vampire-saved/mame-ref/cps2"
    got="$(run "$1" "$2" vsavj)"
    case "$got" in
        "EXIT 2: "*mame-ref/cps2*) ok "missing pinned default refused: $got" ;;
        *) bad "missing pinned default: got '$got', want exit 2 naming mame-ref/cps2"; _f=1 ;;
    esac
    return $_f
}

mirror() {  # mirror <dir> [old]: a wrapper copy at <dir>/tools/run_mame.sh beside the real tests/lib it sources
    mkdir -p "$1/tools" "$1/tests"; ln -s "$REPO/tests/lib" "$1/tests/lib"
    if [ "${2:-}" = old ]; then old_default "$REPO/tools/run_mame.sh" "$1/tools/run_mame.sh"
    else cp "$REPO/tools/run_mame.sh" "$1/tools/run_mame.sh"; fi
}

echo "== test_mame_default_bin: an unset MAME_BIN runs the pinned build for the set =="
if [ "${CONTROL:-}" = "path-fallback" ]; then mirror "$W/m" old
elif [ -n "${CONTROL:-}" ]; then echo "REFUSED: CONTROL=$CONTROL is not a mode of this gate"; exit 3
else mirror "$W/m"; fi
check "$W/m/tools/run_mame.sh" "$W/t" || fail=1

# the must-fire control: the old default must run the PATH stub for vsavjw (not die), and fail the checks
mirror "$W/c" old; setup "$W/cr"
ran="$(run "$W/c/tools/run_mame.sh" "$W/cr" vsavjw)"
if grep -q 'MAME_BIN:-mame' "$W/c/tools/run_mame.sh" && [ "$ran" = "RAN path" ] && ! ( check "$W/c/tools/run_mame.sh" "$W/cc" ) > "$W/ctl.log" 2>&1; then
    echo "CONTROL FIRED: path-fallback — the old default ran the PATH stub ($ran) and the checks failed it"
else
    echo "CONTROL DEAD: path-fallback — the old-default copy did not run the PATH stub ('$ran') or passed the checks"; fail=1
fi

if [ "$fail" -eq 0 ]; then echo "PASS: test_mame_default_bin — an unset MAME_BIN runs the pinned build for its set"
else echo "FAIL: test_mame_default_bin"; exit 1; fi
