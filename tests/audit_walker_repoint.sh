#!/bin/sh
# audit_walker_repoint.sh — after the relocation, does ANYTHING still reach
# the vanilla object-pool walkers?
#
# WHY (14z-91). The obj_hook legacy-cycle fix copies each walker into free
# space and rewrites the operand of every `jsr <walker>`. Completeness is
# the correctness argument: a caller left pointing at the vanilla walker
# keeps walking the VANILLA table, which is bit-identical for legacy (it IS
# vanilla) but an over-index — a wild dispatch — for a tenant type.
#
# tools/audit_walker_callers.py enumerates the callers statically and found
# 23 `jsr abs.l` and nothing else: no data longword equals either walker
# address, no jsr/jmp (d16,PC), and every branch hit is the walker's own
# loop or an operand word misread by a linear scan. But a target COMPUTED at
# runtime is invisible to any static scan, and that residual is exactly what
# this closes: run the corpus and require the vanilla entries to be silent.
#
# THE NEGATIVE CONTROL IS NOT OPTIONAL. "Zero hits on the vanilla walker" is
# also what a dead breakpoint says. So the same instrument is pointed at a
# REFERENCE build that has NOT been relocated, where the vanilla entries MUST
# fire — otherwise every zero above is unreadable. Set REF_BUILD to one.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=6] [REF_BUILD=build/don_m5] \
#          [REPLAYS="..."] tests/audit_walker_repoint.sh <builddir>
# ~5 min.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-91: after the relocation, does ANYTHING still reach the vanilla
#   walkers? Closes the residual the static caller scan cannot (a target
#   computed at runtime). Vanilla entries must be SILENT, relocated entries
#   must FIRE. NEGATIVE CONTROL is not optional and is built in: the same
#   instrument on an un-relocated REF_BUILD must see the vanilla walkers, or
#   every zero is just a dead breakpoint. Measured identical counts either
#   side of the move (1243 / 40236). ~5 min
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${1:?usage: audit_walker_repoint.sh <builddir>}"
# DELIBERATE PIN (do not "fix" at a freeze, 14z-103): the negative control
# must be a build WITHOUT the 14z-91 walker relocation, and don_m5 (14z-87)
# is the newest such build. Every current build is relocated, so this can
# never re-point forward; the dir is classed EVIDENCE in the build-dir
# census for exactly this reason.
REF_BUILD="${REF_BUILD:-build/don_m5}"
JOBS="${JOBS:-6}"
# a legacy pair, a long mash rig (the only family that reaches walker A), and
# two tenant rigs so the RELOCATED walkers are exercised by tenant content
REPLAYS="${REPLAYS:-02_demitri_vs_cpu 21_don_mash 24_don_winmash 36_pick_tenant_cell 12_donovan_vs_cpu}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# the relocated entry points, derived from the BUILD's own patch.json
NEW=$(BUILD="$BUILD" python3 - <<'PY'
import json, os, sys
sys.path.insert(0, "tools")
from _minitoml import loads
vj = open("build/out/vsavj_opcodes.bin", "rb").read()
ops = json.load(open(os.path.join(os.environ["BUILD"], "patch/patch.json")))["ops"]
out = []
for r in loads(open("build/manifest/donovan.toml").read())["obj_hook"]:
    pre = vj[r["walker"]:r["walker"] + r["walker_len"]].hex()
    b = [o for o in ops if o["op"] == "code" and o["hex"].startswith(pre)]
    if not b:
        sys.exit(f"no relocated copy of walker {r['walker']:#x} in this build")
    # the `jsr (A0)` sits at walker+0x1E (site = walker+0x18, jsr = site+6)
    out.append("%x" % (int(b[0]["addr"], 16) + 0x1E))
print(",".join(out))
PY
) || { echo "FAIL: $NEW"; exit 1; }
OLD="54476,5e548"
echo "vanilla walker jsr:   $OLD  (must be SILENT)"
echo "relocated walker jsr: $NEW  (must FIRE)"

frames_for() {
    # NOTE the spaces around `=`: tests/test_shell_portability.sh scans for
    # bash-array syntax and `f=(` inside an awk program looks exactly like it.
    sed 's/#.*//' "tests/replays/$1.rpl" | awk 'NF { split($1, r, "-");
        f = (r[2] ? r[2] : r[1]); if (f + 0 > m) m = f + 0 } END { print m + 120 }'
}

run_leg() {   # $1 tag  $2 rompath-build  $3 sites
    _t="$1"; _b="$2"; _s="$3"; pool=0
    for r in $REPLAYS; do
        ( MAME_SANDBOX="$W/sb_${_t}_$r" REPLAY="$PWD/tests/replays/$r.rpl" \
          SPSITES="$_s" SP_OUT="$W/${_t}_$r.txt" FRAMES="$(frames_for "$r")" \
          MAME_ROMPATH="$PWD/$_b/rompath;$ROMDIR" \
          tools/run_mame.sh vsavjw -debug -debugger none \
          -autoboot_script "$PWD/tests/lua/walker_sp.lua" \
          >"$W/${_t}_$r.log" 2>&1 ) &
        pool=$((pool + 1)); [ "$pool" -ge "$JOBS" ] && { wait; pool=0; }
    done
    wait
}

total_for() {  # $1 tag  $2 hex site -> total hits across replays
    # NORMALISE BOTH SIDES, AND COMPARE AS STRINGS. walker_sp.lua prints the
    # site %06x-padded, so a bare `$2 == "5e548"` is an awk string-vs-number
    # trap: "054476" vs "54476" compare NUMERICALLY and match, while
    # "05e548" vs "5e548" compare as strings and do not — the gate reported a
    # confident 0 hits for one site and the right number for its twin. A
    # blind instrument and a real zero look identical, so this is padded in
    # the shell and forced to a string compare in awk.
    _s=$(printf '%06x' $((0x$2)))
    awk -v s="$_s" '$1=="SP" && ($2 "") == (s "") { t += $4 } END { print t + 0 }' \
        "$W/$1"_*.txt 2>/dev/null
}
complete_for() { grep -l SPEND "$W/$1"_*.txt 2>/dev/null | wc -l | tr -d ' '; }

echo
echo "== 1. on $BUILD: vanilla entries silent, relocated entries live =="
run_leg new "$BUILD" "$OLD,$NEW"
n=$(complete_for new)
[ "$n" = "$(echo "$REPLAYS" | wc -w | tr -d ' ')" ] || {
    echo "  FAIL: only $n of $(echo "$REPLAYS" | wc -w | tr -d ' ') runs completed"; fail=1; }
for s in $(echo "$OLD" | tr ',' ' '); do
    h=$(total_for new "$s")
    if [ "${h:-0}" = "0" ]; then echo "  ok: vanilla $s never reached ($h hits)"
    else
        echo "  FAIL: vanilla walker $s still reached $h time(s) — a caller was"
        echo "        MISSED. Legacy stays bit-identical (it is vanilla), but a"
        echo "        tenant object dispatched there over-indexes the vanilla"
        echo "        table. Re-run tools/audit_walker_callers.py and look for a"
        echo "        reference form it does not cover (a computed target)."
        fail=1
    fi
done
for s in $(echo "$NEW" | tr ',' ' '); do
    h=$(total_for new "$s")
    if [ "${h:-0}" -gt 0 ]; then echo "  ok: relocated $s reached $h time(s)"
    else
        echo "  FAIL: relocated walker $s NEVER ran — the repoint did not take,"
        echo "        or this replay set does not reach it."
        fail=1
    fi
done

echo
echo "== 2. NEGATIVE CONTROL on $REF_BUILD (not relocated): vanilla MUST fire =="
if [ ! -f "$REF_BUILD/rompath/vsavjw.zip" ]; then
    echo "  FAIL: no $REF_BUILD/rompath/vsavjw.zip — without this control every"
    echo "        zero above is indistinguishable from a dead breakpoint."
    fail=1
else
    run_leg ref "$REF_BUILD" "$OLD"
    any=0
    for s in $(echo "$OLD" | tr ',' ' '); do
        h=$(total_for ref "$s")
        echo "  ref $s: $h hits"
        [ "${h:-0}" -gt 0 ] && any=1
    done
    if [ "$any" = 1 ]; then
        echo "  ok: the instrument sees the vanilla walkers on an un-relocated"
        echo "      build, so section 1's zeros are real"
    else
        echo "  FAIL: the vanilla walkers did not fire on $REF_BUILD either —"
        echo "        the instrument is dead and section 1 proves nothing."
        fail=1
    fi
fi

echo
[ "$fail" = 0 ] && echo "WALKER REPOINT: PASS" || echo "WALKER REPOINT: FAIL"
exit "$fail"
