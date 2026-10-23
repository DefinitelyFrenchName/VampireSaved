# qs_voice_build.sh — audit_qs_voice_wav's "ours" romset, built once. Sourced, not executed. (14z-206, #291.)
#
# WHY. audit_qs_voice_wav does not run one of the commit's five tracks: with no build dir it takes the canonical
# overlay build/wide0 and adds the voice batch itself (tools/build_qs_songs.py), in its own temporary dir. A proof
# sheet re-runs that leg and must show it ran on a build made from the commit, so the gate declares this builder
# (`# SHEET-VARIANT:`) and tools/proof_sheets.py run builds it in the clean checkout's build/ and hands it back
# through QSV_OUTBASE. Until 14z-206 the sheet's ours leg named the gate's own temporary copy, and all 74 of its clips
# read NOT THE JUDGED RUN ("outside the clean checkout's build/").
#
# The ledger travels with the romset (build_qs_songs.py's default, <zip>.ledger.json), so the result is a build dir
# the gate takes as it takes any supplied one ($1/rompath/vsavjw.zip and its ledger beside it).
#
# Usage (from the repository root, ROMDIR set):
#   . tests/lib/qs_voice_build.sh
#   qs_voice_build "$WORK" ""          # sets OUTBASE (= $WORK/build); a non-empty second argument is used as-is

# qs_voice_build <workdir> [supplied-outbase]  — sets OUTBASE
qs_voice_build() {
    _qv_work="${1:?qs_voice_build needs a work dir}"
    OUTBASE="${2:-}"
    [ -n "$OUTBASE" ] && return 0
    _qv_repo="${REPO:-$(pwd)}"
    [ -f "$_qv_repo/build/wide0/rompath/vsavjw.zip" ] || {
        echo "FAIL: no canonical overlay at $_qv_repo/build/wide0/rompath/vsavjw.zip" >&2; return 1; }
    OUTBASE="$_qv_work/build"
    mkdir -p "$OUTBASE/rompath"
    cp "$_qv_repo/build/wide0/rompath/vsavjw.zip" "$OUTBASE/rompath/vsavjw.zip" || return 1
    echo "== building the voice batch on build/wide0 (tools/build_qs_songs.py) =="
    python3 "$_qv_repo/tools/build_qs_songs.py" "$OUTBASE/rompath/vsavjw.zip" \
        "${ROMDIR:?set ROMDIR}/vsav2.zip" --vsav "$ROMDIR/vsav.zip" > "$_qv_work/build.log" 2>&1 || {
        echo "FAIL: build_qs_songs.py errored"; tail -20 "$_qv_work/build.log"; return 1; }
    [ -f "$OUTBASE/rompath/vsavjw.zip.ledger.json" ] || {
        echo "FAIL: the builder wrote no ledger beside the romset" >&2; return 1; }
    tail -2 "$_qv_work/build.log" | sed 's/^/  /'
}
