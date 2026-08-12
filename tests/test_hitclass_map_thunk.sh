#!/bin/sh
# test_hitclass_map_thunk.sh — the hit-class map-extension thunk (14z-82b)
# reconstructs from the two reference ROMs, and any committed row matches
# the reconstruction byte-for-byte.
#
# THE CLAIM. vsavj's projectile-pool hit sweep maps BOTH colliding
# objects' type bytes through one 64-entry byte map (routine PRG:0x1A888,
# seven callers); vs2's sibling map has 80 entries. A ported object of
# type >= 64 in the $FF94xx pool that lands a hit over-indexes vsavj's
# map — the f7997 vec3, measured LATENT in the frozen pyron build itself
# (14z-82b; huitzil spawns 68/72 into the same pool and shares the
# exposure; donovan's 59-63 fit). The fix body is GENERATED
# (tools/gen_hitclass_map_thunk.py): vanilla's 64 bytes verbatim + vs2's
# 16 extension entries + a loud >=80 ILLEGAL. The generator carries the
# transplant's safety asserts (0-58 prefix identity, word-table entry
# identity, vs2 bound) — this gate makes reference-image drift and
# committed-row drift loud.
#
# Sections:
#   1  the generator reproduces its body from the ROMs (its own asserts
#      are the safety argument; a failure there is a STOP)
#   2  any [[site_thunk]] hitclass_map_extend row in the real manifests
#      matches the generated hex (SKIP-note if not yet adopted — the row
#      is a maintainer re-freeze decision, STATE 14z-82b)
#   3  verdict controls: a corrupted committed hex must FAIL the compare;
#      a wrong-image invocation must FAIL the generator
#
# Usage: tests/test_hitclass_map_thunk.sh   (no emulator; needs the
# decrypted views in build/out/, ~2 s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="${TMPDIR:-/tmp}/hitclass_thunk_$$"
mkdir -p "$W"
trap 'rm -rf "$W"' EXIT
fail=0

VJ=build/out/vsavj_opcodes.bin
VS2=build/out/vsav2_opcodes.bin
[ -f "$VJ" ] && [ -f "$VS2" ] || { echo "SKIP: no decrypted views"; exit 0; }

# ── 1: reconstruction ────────────────────────────────────────────────────
if GEN="$(python3 tools/gen_hitclass_map_thunk.py "$VJ" "$VS2" 2>"$W/gen.err")"; then
    n=$((${#GEN} / 2))
    if [ "$n" = 94 ]; then
        echo "  PASS  1: body reconstructs from the ROMs (94 bytes)"
    else
        echo "  FAIL  1: generated body is $n bytes, want 94"; fail=1
    fi
else
    echo "  FAIL  1: generator asserts fired — the transplant premise moved:"
    tail -3 "$W/gen.err"
    exit 1
fi

# ── 2: committed rows match ──────────────────────────────────────────────
found=0
for m in build/manifest/huitzil.toml build/manifest/pyron.toml; do
    hx="$(awk '/name = "hitclass_map_extend"/{f=1} f && /^thunk_hex/{print; exit}' \
          "$m" | sed 's/thunk_hex = "\(.*\)"/\1/')"
    [ -n "$hx" ] || continue
    found=1
    if [ "$hx" = "$GEN" ]; then
        echo "  PASS  2: $m row matches the reconstruction"
    else
        echo "  FAIL  2: $m thunk_hex differs from the ROM reconstruction —"
        echo "        regenerate with tools/gen_hitclass_map_thunk.py; never"
        echo "        hand-edit the body"
        fail=1
    fi
done
[ "$found" = 1 ] || echo "  note  2: row not adopted in any manifest yet —" \
    "the fix is a maintainer re-freeze decision (STATE 14z-82b)"

# ── 3: verdict controls ──────────────────────────────────────────────────
BAD="$(printf '%s' "$GEN" | sed 's/^0c400050/0c400051/')"
if [ "$BAD" = "$GEN" ]; then
    echo "  FAIL  3a: control could not corrupt the hex"; fail=1
elif [ "$BAD" != "$GEN" ]; then
    echo "  PASS  3a: a corrupted hex differs from the reconstruction" \
         "(the compare above would catch it)"
fi
if python3 tools/gen_hitclass_map_thunk.py "$VS2" "$VJ" >/dev/null 2>&1; then
    echo "  FAIL  3b: generator accepted swapped images (asserts dead)"; fail=1
else
    echo "  PASS  3b: generator rejects swapped images"
fi

[ "$fail" = 0 ] && echo "test_hitclass_map_thunk: ALL PASS" \
                || echo "test_hitclass_map_thunk: FAILURES"
exit "$fail"
