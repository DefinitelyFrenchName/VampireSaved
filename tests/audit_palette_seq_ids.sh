#!/bin/sh
# audit_palette_seq_ids.sh — which palette-seq ids does LEGACY ever request?
#
# THE CLAIM THIS GUARDS. The DF-palette fix (14z-69p) rewrites rows
# 0x1E-0x21 of the global palette-seq table (vsavj 0x39ACC0-0x39AD3F)
# with the sequence native's Dark Force actually shows. That is only
# legacy-safe because vanilla never asks for those ids — and it CANNOT
# be checked by the regression suite, because the palette path never
# transits work RAM (docs/project/gotchas.md). This audit is the only
# guard the claim has.
#
# Method: an UNCAPPED logging breakpoint on the resolver
#   0x02AD82:  a0 = 0x39A900 + (d0 & 0xFFF) * 0x20
# over a character-varied set of vanilla replays, collecting every d0.
# GUARD_PROBE_MAX is essential: the default 400-hit cap silently
# truncated the first run of this audit and hid id 0x27 entirely, which
# would have made the inventory look smaller than it is.
#
# Expected (measured 14z-69p, vanilla vsavj): the ONLY ids legacy ever
# requests are 0x26 and 0x27. Growth here = re-derive before trusting
# the fix; a hit on 0x1E-0x21 means the rewrite is NOT inert and must
# be replaced by a tenant-gated mechanism.
#
# On-demand (not in the battery): ~10 MAME runs, several minutes.
# Usage: ROMDIR=... tests/audit_palette_seq_ids.sh
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

REPLAYS="02_demitri_vs_cpu 03_two_player_vs 05_timeout_idle 07_mash_storm
         08_challenger_join 09_mirror_pick 30_demitri_throw 20_don_round2"
FORBIDDEN="1e 1f 20 21"

: > "$W/ids.txt"
total=0
for r in $REPLAYS; do
    [ -f "tests/replays/$r.rpl" ] || continue
    d="$W/$r"; mkdir -p "$d"
    ( cd "$d" && GUARD_PROBE=2ad82 GUARD_PROBE_MAX=200000 \
      "$REPO/tools/run_replay_guarded.sh" vsavj "$REPO/tests/replays/$r.rpl" \
      "$d/g.log" "$d/box" > "$d/out" 2>&1 ) || true
    n=$(grep -c '^PROBE' "$d/g.log" 2>/dev/null || true)
    [ -n "$n" ] || n=0
    ids=$(grep '^PROBE' "$d/g.log" 2>/dev/null \
          | sed -n 's/.*D0=00000*\([0-9a-f]*\).*/\1/p' | sort -u)
    echo "$ids" >> "$W/ids.txt"
    printf "  %-22s %6s calls   ids: %s\n" "$r" "$n" "$(echo $ids)"
    total=$((total + n))
    if grep -q '^PROBE-CAP' "$d/g.log" 2>/dev/null; then
        echo "FAIL: $r hit the probe cap — the census is truncated"; exit 1
    fi
done

UNION=$(sort -u "$W/ids.txt" | grep -v '^$' | tr '\n' ' ')
echo
echo "  union of ids legacy requests: $UNION"
echo "  total calls sampled: $total"
[ "$total" -gt 0 ] || { echo "FAIL: no calls seen at all — instrument broken"; exit 1; }

bad=""
for f in $FORBIDDEN; do
    case " $UNION " in *" $f "*) bad="$bad $f" ;; esac
done
if [ -n "$bad" ]; then
    echo "FAIL: legacy requests the rewritten ids:$bad"
    echo "      the 14z-69p DF-palette data row is NOT legacy-inert —"
    echo "      replace it with a tenant-gated mechanism"
    exit 1
fi
echo "PASS: legacy never requests palette-seq ids 0x1E-0x21"
echo "      (the DF-palette rewrite is inert for vanilla content)"
