#!/bin/sh
# framedata_pages.sh — regenerate the PER-MOVE FRAME-DATA documents OUT of the
# tree, from the romsets and the committed maps (14z-126).
#
# THE RULE (maintainer, 2026-08-31, STATE 14z-126 "Decisions pending"): per-move
# ROM-derived frame data — the tenants' derived startup/active/recovery pages,
# the vanilla derivation beside the community workbook, the measured dealt
# damage — stays OUT of the public repository, ours and third-party alike. The
# tree ships the READERS and the VERDICTS; the numbers are regenerated here, by
# anyone holding the reference dumps (and, for the cross-check, the workbook),
# into ../charpages/framedata/ — ABOVE the working tree, where git cannot add,
# commit or push them from this repo (the same route as the sprite pages,
# tools/charpages_internal.sh). Nothing here is a source: the sources are the
# generators and the maps; this script only routes their per-move output.
#
# WHAT IT WRITES (FRAMEDATA_OUT overrides the directory):
#   <tenant>_anim.md      the anim-chain appendix with derived frame data
#                         (tools/charmap_md.py --anim, from the committed map)
#   <tenant>.html         the character page (tools/charmap_html.py, from the
#                         solo build; the private artifacts are published from
#                         this output, never from the tree)
#   community_crosscheck_full.md   the move-by-move cross-check (needs the
#                         workbook at ../community/vsav-framedata.xlsx; skipped
#                         with a note when absent)
#   vanilla_hit_damage.tsv is NOT written here — it is a MEASUREMENT, produced
#                         by tests/test_vanilla_frame_join.sh section 4 (which
#                         writes it into the same directory)
# and prints each file's SHA-256 beside the frozen one in
# tests/expected/charmap_pages.sha256, so the run doubles as the currency check.
#
# Usage: ROMDIR=... tools/framedata_pages.sh [DON=build/don_m18 HUI=build/hui52 PYR=build/pyron36]
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
OUT="${FRAMEDATA_OUT:-$REPO/../charpages/framedata}"
# CANONICALISE before judging "inside the repo" ([VSP-108]), and BEFORE creating
# anything: the default is written "$REPO/../charpages/framedata", which TEXTUALLY
# starts with $REPO — a prefix match on the raw string refused the correct path
# while a real in-repo path like ./nope passed (the first draft did exactly that,
# 14z-126). realpath resolves a path that does not exist yet, so a refused run
# leaves no directory behind.
OUT="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$OUT")"
case "$OUT/" in "$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$REPO")"/*)
    echo "refusing: FRAMEDATA_OUT is inside the repository ($OUT) — per-move frame data stays OUT of the tree"; exit 2;; esac
mkdir -p "$OUT"
DON="${DON:-build/don_m18}"; HUI="${HUI:-build/hui52}"; PYR="${PYR:-build/pyron36}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
PAGES="$REPO/tests/expected/charmap_pages.sha256"
sha() { python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$1"; }
frozen() { grep "^$1 " "$PAGES" 2>/dev/null | cut -d' ' -f2; }

echo "== the tenants' anim appendix + character page -> $OUT"
for pair in donovan:$DON huitzil:$HUI pyron:$PYR; do
    n="${pair%%:*}"; b="${pair#*:}"
    [ -d "$b" ] || { echo "  $n: no $b — skipped (build the solo first; HANDOFF 'Running a CPS-2 WIDE build')"; continue; }
    python3 tools/charmap_md.py "docs/project/tables/chars/$n.json" "$W/$n.md" --anim "$OUT/${n}_anim.md" >/dev/null
    python3 tools/charmap_html.py "$n" "$b" "$OUT/$n.html" >/dev/null
    for f in "${n}_anim.md" "$n.html"; do
        s="$(sha "$OUT/$f")"; z="$(frozen "$f")"
        if [ "$s" = "$z" ]; then echo "  $f  sha256 $s  = frozen"; else echo "  $f  sha256 $s  != frozen ${z:-none} (review, then FREEZE=1 tests/test_charmap_current.sh)"; fi
    done
done

echo "== the full community cross-check -> $OUT/community_crosscheck_full.md"
SHEET="${SHEET:-$REPO/../community/vsav-framedata.xlsx}"
if [ -f "$SHEET" ]; then
    . "$REPO/tests/lib/decrypt_cache.sh"
    decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin"
    python3 tools/vanilla_frames.py "$W/vj_data.bin" --json "$W/v.json" >/dev/null
    python3 tools/crosscheck_framedata.py --sheet "$SHEET" --vanilla "$W/v.json" --md-full "$OUT/community_crosscheck_full.md" >/dev/null
    echo "  community_crosscheck_full.md  sha256 $(sha "$OUT/community_crosscheck_full.md")"
else
    echo "  skipped: no workbook at $SHEET (third-party; stays out of the tree)"
fi
[ -f "$OUT/vanilla_hit_damage.tsv" ] && echo "== vanilla_hit_damage.tsv present ($(grep -vc '^#' "$OUT/vanilla_hit_damage.tsv") rows; from tests/test_vanilla_frame_join.sh)" || echo "== vanilla_hit_damage.tsv absent — ROMDIR=... tests/test_vanilla_frame_join.sh writes it"
echo "done: $OUT"
