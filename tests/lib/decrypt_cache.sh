# decrypt_cache.sh — materialise a decrypted reference-set view from the
# build/out cache instead of re-running the 10.7 s pure-Python decrypt.
# Sourced, not executed. (14z-94, GitHub #69.)
#
# WHY. The CPS-2 decrypt is deterministic and its output is already on disk:
# tools/build_donovan.sh maintains build/out/<set>_{opcodes,data}.bin and
# regenerates them only when missing. 27 call sites across 22 test scripts
# bypassed that and re-decrypted from the zip — measured 10.7 s each, roughly
# 4.8 minutes of pure re-decryption per full pass. Under the persistent-suite
# doctrine these scripts run constantly, and since 14z-94 they run as one
# command (tests/run_all_static.sh), so the cost is paid on every commit.
#
# AND IT WAS NOT ONLY SLOW. The sharpest site did:
#
#     python3 tools/cps2_decrypt.py ... > /dev/null 2>&1 || true
#     JIMG="$W/vsavj_data.bin"; [ -f "$JIMG" ] || JIMG="build/out/vsavj_data.bin"
#
# — errors discarded, then a fallback keyed on `[ -f ]`. A decrypt that dies
# half-written leaves a file that EXISTS, so the test proceeds against a
# TRUNCATED image and the fallback never fires. This helper closes that:
# generation is atomic (temp file, then mv), and both the cache and the
# delivered copy are size-checked, so a short image is a loud failure rather
# than a quiet wrong answer.
#
# Usage:
#   . "$REPO/tests/lib/decrypt_cache.sh"
#   decrypt_view vsavj "$WORK/vj_op.bin" "$WORK/vj_data.bin"   # data optional
#
# Needs ROMDIR only when the cache has to be built. The cache lives in
# build/out/, shared with the builders, so a suite run warms it for them too.

# Reference-set program images are 4 MiB. A decrypt that produces anything
# else did not finish, whatever its exit status said.
: "${DECRYPT_VIEW_SIZE:=4194304}"

_dv_size() { wc -c < "$1" 2>/dev/null | tr -d ' '; }

_dv_ok() {  # _dv_ok <path> -> 0 if present and full-length
    [ -f "$1" ] || return 1
    [ "$(_dv_size "$1")" = "$DECRYPT_VIEW_SIZE" ]
}

# decrypt_view <set> <op_dest> [<data_dest>]
decrypt_view() {
    _dv_set="$1"; _dv_op="$2"; _dv_dat="${3:-}"
    _dv_repo="${REPO:?decrypt_view needs REPO set}"
    _dv_cop="$_dv_repo/build/out/${_dv_set}_opcodes.bin"
    _dv_cdat="$_dv_repo/build/out/${_dv_set}_data.bin"

    if ! _dv_ok "$_dv_cop" || ! _dv_ok "$_dv_cdat"; then
        : "${ROMDIR:?decrypt_view: cache miss for $_dv_set and ROMDIR is unset}"
        [ -f "$ROMDIR/${_dv_set}.zip" ] || {
            echo "decrypt_view: no $ROMDIR/${_dv_set}.zip" >&2; return 1; }
        mkdir -p "$_dv_repo/build/out"
        # ATOMIC: decrypt to temp names and rename only on success, so an
        # interrupted run can never leave a short file at the cache path for
        # the next `[ -f ]` to accept.
        _dv_tmp="$(mktemp -d)"
        if ! python3 "$_dv_repo/tools/cps2_decrypt.py" "$ROMDIR/${_dv_set}.zip" \
                "$_dv_tmp/op.bin" --data-out "$_dv_tmp/dat.bin" >/dev/null 2>&1; then
            echo "decrypt_view: cps2_decrypt failed for $_dv_set" >&2
            rm -rf "$_dv_tmp"; return 1
        fi
        if ! _dv_ok "$_dv_tmp/op.bin" || ! _dv_ok "$_dv_tmp/dat.bin"; then
            echo "decrypt_view: $_dv_set decrypt produced a SHORT image" \
                 "($(_dv_size "$_dv_tmp/op.bin")/$(_dv_size "$_dv_tmp/dat.bin")" \
                 "bytes, expected $DECRYPT_VIEW_SIZE) — refusing to cache it" >&2
            rm -rf "$_dv_tmp"; return 1
        fi
        mv "$_dv_tmp/op.bin" "$_dv_cop"
        mv "$_dv_tmp/dat.bin" "$_dv_cdat"
        rm -rf "$_dv_tmp"
    fi

    cp "$_dv_cop" "$_dv_op" || return 1
    [ -n "$_dv_dat" ] && { cp "$_dv_cdat" "$_dv_dat" || return 1; }
    # Deliver-side check too: a full cache copied onto a full disk is not a
    # full destination, and the caller is about to read offsets out of it.
    _dv_ok "$_dv_op" || {
        echo "decrypt_view: delivered $_dv_op is short" >&2; return 1; }
    [ -n "$_dv_dat" ] && { _dv_ok "$_dv_dat" || {
        echo "decrypt_view: delivered $_dv_dat is short" >&2; return 1; }; }
    return 0
}
