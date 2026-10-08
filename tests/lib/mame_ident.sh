# mame_ident.sh — WHICH MAME RAN, NAMED IN A GATE'S HEADER (14z-195, rule-checker run 2026-10-08-740 Q1)
#
# A gate that ran $MAME_BIN proved only that it was executable: its log named the path, never which MAME it was.
# vs_mame_ident prints one header line and returns 1 unless `$MAME_BIN -version` names the release of the pin
# tools/setup_mame.sh holds (its `# tag mameNNNN` comment: mame0288 -> 0.288). The line also names WHICH of the two
# pinned builds it is — the stock reference (`-listfull vsavjw` finds no system) or the CPS-2 WIDE build (it knows
# vsavjw; tools/run_mame.sh's default for that set and the emulator tier's exported default) — and the binary's sha1,
# which is host-specific and so REPORTED, never compared.
# NOT PROVEN HERE: that the binary was built from the pinned COMMIT (this build's -version reads "(unknown)", so only
# the release is checkable); that a WIDE build runs stock vsavj as the reference does — that is the emulator superset
# invariant, tests/test_mame_wide.sh ([VSP-2]), not this check.
#
# Usage (sourced, REPO set): . "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: ..."; exit 1; }
vs_mame_ident() {
    _mb="$1"; _why=""
    _tag="$(sed -n 's/^PINNED=.*# tag \(mame[0-9]*\).*/\1/p' "$REPO/tools/setup_mame.sh" | head -1)"
    _want="$(printf '%s' "$_tag" | sed -n 's/^mame\([0-9]\)\([0-9]*\)$/\1.\2/p')"
    _ver="$("$_mb" -version 2>/dev/null | head -1)"
    if command -v sha1sum >/dev/null 2>&1; then _sha="$(sha1sum "$_mb" | cut -d' ' -f1)"; else _sha="$(shasum -a 1 "$_mb" | cut -d' ' -f1)"; fi
    case "$("$_mb" -listfull vsavjw 2>&1 | head -1)" in
        "No matching systems"*) _build="the stock reference build (no vsavjw driver)" ;;
        Name:*) _build="the CPS-2 WIDE build (knows vsavjw)" ;;
        *) _build="UNKNOWN (-listfull vsavjw unreadable)"; _why="-listfull vsavjw gave neither answer" ;;
    esac
    [ -n "$_want" ] || _why="${_why:+$_why; }no pin tag read from tools/setup_mame.sh"
    case "$_ver" in "$_want "*) ;; *) _why="${_why:+$_why; }-version '$_ver' is not the pin's release $_want ($_tag)" ;; esac
    echo "  mame  $_mb: -version '$_ver', pin $_tag's release $_want: $([ -z "$_why" ] && echo yes || echo NO); $_build; sha1 $_sha (host-specific, reported)"
    [ -z "$_why" ] || { echo "  mame  REFUSED: $_why"; return 1; }
}
