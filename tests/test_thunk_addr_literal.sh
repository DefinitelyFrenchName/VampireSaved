#!/bin/sh
# test_thunk_addr_literal.sh — ground truth for the STALE PLACED-ADDRESS guard
# in tools/gen_donovan_patch.py (14z-78).
#
# WHY THIS EXISTS. A `[[site_thunk]]` body is hand-authored machine code, and
# anything the BUILD chooses that gets written into it as a literal is a trap:
# the literal stops tracking the moment the build's choice changes, and nothing
# fails — the thunk just quietly does the wrong thing. The generator already had
# two guards of this shape for the tenant's CHARACTER ID. It had none for the
# ALLOCATOR's output, and that cost M3b a session:
#
#   donovan.toml's two select-companion thunks carried `207c000dda1e`
#   (movea.l #$000DDA1E,A0) — `anim`'s placed address, hand-computed once.
#   Relocating `anim` left both bodies aimed at the vacated range, the resolver
#   read the region that slid in as 16-bit offsets, and the engine took an
#   address error at VANILLA PC 0x015098. The build itself was silent, so
#   "anim cannot move" read as a hardware/layout constraint, and `anim` is
#   371,712 of the 470,200 bytes three tenants need from a 344,640-byte crypt
#   window — i.e. the whole merge was blocked on a hex literal.
#
# The correct spelling is `region_subst`, which resolves placed[region]+offset
# at emit time. This gate proves the guard makes the wrong spelling LOUD, and —
# just as importantly — that it stays quiet on the three real manifests.
#
# Runs the GENERATOR ALONE against an existing extract dir (seconds, no
# emulator, no ROMs beyond vsavj). Never edits a tracked file: every
# perturbation is applied to a COPY of the manifest under $WORK.
#
# Usage: tests/test_thunk_addr_literal.sh [extract_dir]
set -u
cd "$(dirname "$0")/.."

: "${ROMDIR:?set ROMDIR to the reference-set directory}"
EXTRACT="${1:-build/m5_wide/extract}"
if [ ! -d "$EXTRACT" ]; then
    echo "SKIP: no extract dir at $EXTRACT (build dirs are untracked)."
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM
fail=0

# gen <outdir> <manifest> -> runs the generator; exit code is DATA, not an error
gen() {
    python3 tools/gen_donovan_patch.py "$EXTRACT" "$1" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
        --port "$2" --profile cps2-wide-v1 \
        --allow-plausible --tripwire-open > "$1.log" 2>&1
    echo $? > "$1.rc"
}

# NOTE: `grep -c` PRINTS 0 and EXITS 1 when there is no match, so a trailing
# `|| echo 0` emits a second line and every "= 0" comparison below fails. The
# first version of this file had exactly that and reported the guard broken in
# four places while it was working — the harness, not the subject.
guard_hits() { grep -c 'body bakes' "$1.log" 2>/dev/null; }

# The stale form the fix replaced, stated literally so this file records the
# exact bytes the guard is about. The AUTHORED (fixed) row it is substituted
# for lives in the python below and only there — carrying it in two places
# would let the anchor and the replacement drift apart silently.
STALE='thunk_hex = "0c2e00TT000a6708207c002083bc4e75207c000dda1e4e75"'

subst() {   # subst <out.toml> <replacement-block>
    REPL="$2" python3 - "$1" <<'PY'
import os, pathlib, sys
src = pathlib.Path("build/manifest/donovan.toml").read_text()
fixed = ('thunk_hex = "0c2e00TT000a6708207c002083bc4e75207cnnnnnnnn4e75"\n'
         'region_subst = "nnnnnnnn=anim:0xa9ae"')
if fixed not in src:
    sys.exit("ANCHOR NOT FOUND: select_companion_tbl_a no longer carries the "
             "region_subst form this gate perturbs (manifest edited?)")
pathlib.Path(sys.argv[1]).write_text(src.replace(fixed, os.environ["REPL"], 1))
PY
}

echo "== section 0: the guard is QUIET on all three real manifests =="
# The load-bearing half. A guard that fires on correct input is worse than no
# guard, and the three frozen tenants are the only real corpus there is.
# huitzil re-pointed hui27 -> hui46 at 14z-102: the #109 root added region
# x0926e4 to extraction, and an extract that predates a manifest's regions
# fails generation outright (the battery caught it — the #94 rot class).
# RE-POINT the huitzil leg whenever the census gains a root.
for t in donovan:build/m5_wide huitzil:build/hui52 pyron:build/pyron21; do  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
    nm=${t%%:*}; bd=${t##*:}
    if [ ! -d "$bd/extract" ]; then
        echo "  SKIP: $nm (no $bd/extract)"; continue
    fi
    python3 tools/gen_donovan_patch.py "$bd/extract" "$WORK/q_$nm" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
        --port "build/manifest/$nm.toml" --profile cps2-wide-v1 \
        --allow-plausible --tripwire-open > "$WORK/q_$nm.log" 2>&1
    rc=$?
    n=$(guard_hits "$WORK/q_$nm")
    if [ "$rc" = 0 ] && [ "$n" = 0 ]; then
        echo "  ok: $nm generates clean, 0 guard messages"
    else
        echo "  FAIL: $nm -> exit $rc, $n guard message(s)"
        grep -m3 'body bakes' "$WORK/q_$nm.log"
        fail=1
    fi
done

echo "== section 1: a re-staled literal FAILS the build, naming the region =="
subst "$WORK/stale.toml" "$STALE" || { echo "  FAIL: $?"; exit 1; }
gen "$WORK/stale" "$WORK/stale.toml"
if [ "$(cat "$WORK/stale.rc")" != 0 ] && grep -q "body bakes 0x0dda1e" "$WORK/stale.log"; then
    echo "  ok: caught, and the message names the region and the fix:"
    sed -n 's/.*\(body bakes[^"]*region .[a-z0-9_]*.\).*/      \1/p' "$WORK/stale.log" | head -1
    # The message must hand the author the exact spelling to use — a guard that
    # only says "no" costs the next person the arithmetic that caused the bug.
    if grep -q 'region_subst = "<ph>=anim:0xa9ae"' "$WORK/stale.log"; then
        echo "      ok: suggests region_subst = \"<ph>=anim:0xa9ae\" (offset re-derived)"
    else
        echo "      FAIL: message does not suggest the correct region_subst"; fail=1
    fi
else
    echo "  FAIL: a stale placed literal built clean (exit $(cat "$WORK/stale.rc"))"
    fail=1
fi

echo "== section 2: addr_literal_ok silences it (the escape hatch) =="
subst "$WORK/okd.toml" "$STALE
addr_literal_ok = \"0x0dda1e\""
gen "$WORK/okd" "$WORK/okd.toml"
if [ "$(cat "$WORK/okd.rc")" = 0 ] && [ "$(guard_hits "$WORK/okd")" = 0 ]; then
    echo "  ok: an explicitly-declared fixed address is allowed through"
else
    echo "  FAIL: addr_literal_ok did not silence the guard"
    grep -m2 'body bakes' "$WORK/okd.log"; fail=1
fi

echo "== section 3: verdict controls — what must NOT fire =="
# 3a. The vanilla address in the SAME body (0x2083BC) is outside every placed
#     span. If the guard flagged it, section 1 would prove nothing: it would be
#     firing on "there is an address here", not on "this address is placed".
if [ "$(guard_hits "$WORK/q_donovan")" = 0 ]; then
    echo "  ok: the vanilla lea 0x2083bc in the same body does NOT fire"
else
    echo "  FAIL: guard fires on a non-placed address"; fail=1
fi
# 3b. A placed address that is NOT preceded by an absolute-operand opcode must
#     not fire — the anchor is load-bearing, and an unanchored scan reads
#     operand pairs as addresses. Body: `4e71` (nop) + the address bytes.
subst "$WORK/noanchor.toml" 'thunk_hex = "0c2e00TT000a6708207c002083bc4e754e71000dda1e4e75"'
gen "$WORK/noanchor" "$WORK/noanchor.toml"
if [ "$(guard_hits "$WORK/noanchor")" = 0 ]; then
    echo "  ok: an unanchored longword does not fire (documented boundary)"
else
    echo "  FAIL: guard fired without an absolute-operand opcode"; fail=1
fi
# 3c. THE GUARD'S OWN BLIND SPOT, asserted rather than assumed. 3b is not a
#     victory — it is the coverage limit this guard accepts, written down so a
#     future session does not read section 1 as "all stale addresses are
#     caught". If that boundary ever needs closing, this is the case to flip.
echo "  note: raw longwords in embedded data are OUT OF SCOPE by design (3b)"

echo
[ "$fail" = 0 ] || { echo "FAIL: thunk address-literal guard"; exit 1; }
echo "PASS: a placed address baked into a thunk body is a BUILD error; the"
echo "      three real manifests are clean; the escape hatch and the anchor"
echo "      requirement both behave."
