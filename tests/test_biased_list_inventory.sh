#!/bin/sh
# test_biased_list_inventory.sh — the #109-B sweep inventory, frozen (14z-102).
#
# WHAT IT LOCKS. tools/enum_biased_lists.py enumerates every biased-type
# (4/6/8) sprite list and composite (12) across a tenant's placed regions and
# classifies them against the retype machinery. The FILTERED inventory — the
# rows OUTSIDE the tool's documented false-positive families (hitbox /
# hitbox_proj / aux*: hitbox records and coordinate data whose values look
# like type words, per the tool's header) — is frozen here with its 14z-102
# review verdicts. A NEW row in the filtered set means new ported data
# carrying a biased list nothing reviewed; a row CHANGING status means the
# retype coverage moved. Both are stop-and-review events, not tolerances.
#
# THE 14z-102 VERDICTS (measured, STATE 14z-102):
#   anim 0x2499f0 / 0x249b18 (hui)  FP — anim-NODE stream misread as list
#       heads (the 0x25729A frame pointers run through the "entries").
#   anim 0x28a300 (don)             FP — same node-stream class
#       (0x29AF78/0x29AF34 pointers, zero-entry "head").
#   x2b7ef4 0x2bc09a / 0x2bc0f8 (ALL tenants — the region is shared)
#       REAL type-4 strips (11x tile 0x0090, flip pair) on a looping 6-node
#       effect anim with no static referent. ACCEPTED-WITH-EVIDENCE:
#       unreached by every instrumented path (0/321 type-4 dispatches on
#       hui/83_hui_fx serve only vanilla lists 0x269034/0x2693AA; zero
#       in-match type-4 dispatches on the DF clone rig df/100; zero on the
#       pyron cosmo rig), and the failure mode if ever reached is a bounded
#       wrong-art draw at vanilla bank-1 0x13890 (type 4 is a valid vanilla
#       list type — no over-index, no crash surface). Re-open trigger: any
#       type-4 dispatch with the list address inside a placed x2b7ef4 copy.
#   x101aca 0x102436 (don, 14z-111)   FP — inside Donovan's CPU AI SCRIPT
#       block (bank_map ai_script_*): word-offset command streams, 0 pointer
#       fields by the segmented oracle (vhunt2 twin shift 0); a 4-entry
#       window of stream words reads as list heads. Not a sprite list; the
#       block is DATA the script interpreter walks with (a0)+.
#   Everything else biased in the placed set is covered-child (the type-6
#       takeover's own strip code serves those — the clone-beam lines among
#       them since the row-31 fix) or orphan-12 noise (the tool's upper
#       bound; unretyped composites are only reachable through paths the
#       retype enumeration bounds).
#
# Usage: ROMDIR unused; needs the three extract-consuming build dirs'
#        placements + the vs2 data view (regenerated if absent).
#        BUILD_D/BUILD_H/BUILD_P override the defaults.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD_D="${BUILD_D:-build/don_m15}"  # re-pointed 14z-115 (select-wheel freeze) <- 14z-110b
BUILD_H="${BUILD_H:-build/hui49}"   # re-pointed 14z-115 (select-wheel freeze) <- 14z-111 (was hui46 since 14z-102 — the sweeps never carried it; the N-2 deletion surfaced it as a SKIP)
BUILD_P="${BUILD_P:-build/pyron33}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

# the vs2 data view (logical byte order); derive it if no cached copy exists
V2DATA=""
for c in build/*/verify_data.bin; do
    [ -f "$c" ] || continue
    V2DATA=""  # verify_data is the BUILD's data view, not vs2 — do not use
    break
done
ROMDIR="${ROMDIR:-}"
if [ -n "$ROMDIR" ] && [ -f "$ROMDIR/vsav2.zip" ]; then
    python3 - "$ROMDIR/vsav2.zip" "$W/vs2_data.bin" <<'PYEOF'
import sys
sys.path.insert(0, 'tools')
import cps2_decrypt as cps
words, kb, prgs, sha1s = cps.load_set(sys.argv[1])
open(sys.argv[2], 'wb').write(cps.words_to_logical_bytes(words))
PYEOF
    V2DATA="$W/vs2_data.bin"
else
    echo "SKIP: needs ROMDIR with vsav2.zip (the sweep reads the vs2 data view)"
    exit 0
fi

fail=0
check() { # tenant builddir manifest expected...
    _t=$1; _b=$2; _m=$3
    if [ ! -f "$_b/patch/placements.json" ]; then
        echo "SKIP: no placements at $_b (build dirs are untracked)"; return
    fi
    python3 tools/enum_biased_lists.py "$V2DATA" "$_b/patch/placements.json" "$_m" 2>/dev/null \
        | awk '$1 ~ /^0x/ && $2 !~ /^(hitbox|hitbox_proj|aux)/ && $4 != "covered-child" && $3 != "12" {print $1, $2, $3}' \
        | sort > "$W/got_$_t"
    shift 3
    printf '%s\n' "$@" | sort > "$W/want_$_t"
    if cmp -s "$W/got_$_t" "$W/want_$_t"; then
        echo "  ok: $_t filtered inventory matches the frozen set ($(wc -l < "$W/got_$_t" | tr -d ' ') rows)"
    else
        echo "  FAIL: $_t filtered inventory drifted from the frozen set:"
        diff "$W/want_$_t" "$W/got_$_t" | sed 's/^/    /'
        echo "    (a NEW row = unreviewed biased list in ported data; a"
        echo "     VANISHED row = the sweep or the placements changed — either"
        echo "     way, review before re-freezing. Verdicts in the header.)"
        fail=1
    fi
}

echo "== #109-B biased-list inventory (filtered; verdicts in header) =="
check donovan "$BUILD_D" build/manifest/donovan.toml \
    "0x102436 x101aca 4" \
    "0x28a300 anim 4" \
    "0x2bc09a x2b7ef4 4" \
    "0x2bc0f8 x2b7ef4 4"
check huitzil "$BUILD_H" build/manifest/huitzil.toml \
    "0x2499f0 anim 4" \
    "0x249b18 anim 4" \
    "0x2bc09a x2b7ef4 4" \
    "0x2bc0f8 x2b7ef4 4"
check pyron "$BUILD_P" build/manifest/pyron.toml \
    "0x2bc09a x2b7ef4 4" \
    "0x2bc0f8 x2b7ef4 4"

[ "$fail" = 0 ] && echo "PASS: biased-list inventory frozen and matching" || echo "FAIL: biased-list inventory gate"
exit "$fail"
