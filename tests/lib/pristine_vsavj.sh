# pristine_vsavj.sh — WHICH ROM AND WHICH IMAGE A PRISTINE-vsavj GATE MEASURED. Sourced, not executed.
# (14z-209, #229: rule-checker run 2026-10-25-1294 Q1/Q4 — "No ROM or IMG hash appears in [the log] ... No control
# fires if the analysed image or the romset is not pristine vsavj"; the same finding as run 2026-10-08-736 on the
# mizuumi gates, whose inline check this generalises: tests/audit_mizuumi_attack.sh "WHICH ROM RAN".)
#
#   vs_pristine_vsavj <workdir> <image>...
#
# returns 0 and prints one `rom` line when ALL hold, else prints `FAIL:` lines and returns 1:
#   1. every member of every reference zip in ROMDIR matches docs/checksums.txt (tools/audit_roms.py: "all match");
#   2. the vsavj program fingerprint (tools/build_fingerprint.py) equals tests/expected/registry.tsv's vsavj row;
#   3. vsavj.zip decrypted AFRESH from ROMDIR (tools/cps2_decrypt.py, ~8 s) equals, byte for byte, the build/out
#      cache's two views (which decrypt_view copies and three rig tools read directly) and every <image> named;
#   4. the ROMs the MAME legs load are ROMDIR's: tools/run_mame.sh passes `-rompath "$ROMPATH"` as MAME's only ROM
#      search path (its exec line) with ROMPATH="${MAME_ROMPATH:-$ROMDIR}", so MAME_ROMPATH must be unset or ROMDIR
#      itself (rule-checker run 2026-10-25-1295 Q1/Q4: "nothing tests that" the legs load the audited ROMDIR);
#   5. the MAME the legs run is the pin's release: the binary resolved as tools/run_mame.sh resolves it for vsavj
#      (MAME_BIN, else the pinned stock reference ~/.cache/vampire-saved/mame-ref/cps2), named by vs_mame_ident
#      (tests/lib/mame_ident.sh); either pinned build passes — a tier exports the CPS-2 WIDE build, and that it runs
#      stock vsavj as the reference does is the emulator superset invariant ([VSP-2], tests/test_mame_wide.sh).
#
# THE CONTROLS, declared by each caller as two MUST-FIRE lines and run here:
#   foreign-image  — an image one byte off the fresh data view must fail check 3
#                    (in-gate: vs_pristine_vsavj_controls; mode: the check is handed that image and the gate FAILs);
#   foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip must fail check 1
#                    (in-gate: vs_pristine_vsavj_controls; mode: the check audits that ROMDIR and the gate FAILs);
#   foreign-rompath — MAME_ROMPATH pointed at that foreign ROMDIR (the audited ROMDIR left pristine) must fail check 4
#                    (in-gate: vs_pristine_vsavj_controls; mode: the check runs with it set and the gate FAILs);
#   foreign-mame   — MAME_BIN pointed at a binary that is not the pin's release (/bin/echo) must fail check 5
#                    (in-gate: vs_pristine_vsavj_controls; mode: the check runs with it set and the gate FAILs).
# A mode is read from VS_CTL (tests/lib/controls.sh).

_pv_sha() { python3 -c 'import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],"rb").read()).hexdigest())' "$1"; }

# _pv_check <romdir> <workdir> <image>... — the five checks, quietly; prints FAIL lines or the rom and mame lines
_pv_check() {
    _pv_rd="$1"; _pv_w="$2"; shift 2
    if [ -n "${MAME_ROMPATH:-}" ] && [ "$MAME_ROMPATH" != "$_pv_rd" ]; then
        echo "FAIL: MAME_ROMPATH is set ('$MAME_ROMPATH'), so the MAME legs would not load the audited ROMDIR ('$_pv_rd'; tools/run_mame.sh ROMPATH=\${MAME_ROMPATH:-\$ROMDIR})"; return 1; fi
    . "$REPO/tests/lib/mame_ident.sh"
    _pv_mi="$(vs_mame_ident "${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}")" || {
        echo "FAIL: the MAME the legs run is not the pin's release:"; echo "$_pv_mi" | sed 's/^/        /'; return 1; }
    _pv_rc="$(python3 "$REPO/tools/audit_roms.py" "$_pv_rd" 2>&1)" || true
    echo "$_pv_rc" | grep >/dev/null 'all match' || {
        echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"
        echo "$_pv_rc" | tail -3 | sed 's/^/        /'; return 1; }
    _pv_fp="$(python3 "$REPO/tools/build_fingerprint.py" "$_pv_rd" --set vsavj --sha-only 2>/dev/null)" || true
    _pv_reg="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
    [ -n "$_pv_fp" ] && [ "$_pv_fp" = "$_pv_reg" ] || {
        echo "FAIL: vsavj program fingerprint '$_pv_fp' is not tests/expected/registry.tsv's vsavj row '$_pv_reg'"; return 1; }
    mkdir -p "$_pv_w"
    python3 "$REPO/tools/cps2_decrypt.py" "$_pv_rd/vsavj.zip" "$_pv_w/pv_op.bin" --data-out "$_pv_w/pv_data.bin" \
        > /dev/null 2>&1 || { echo "FAIL: vsavj.zip did not decrypt (tools/cps2_decrypt.py)"; return 1; }
    cmp -s "$_pv_w/pv_op.bin" "$REPO/build/out/vsavj_opcodes.bin" || {
        echo "FAIL: build/out/vsavj_opcodes.bin is not vsavj's opcode view decrypted afresh from ROMDIR"; return 1; }
    cmp -s "$_pv_w/pv_data.bin" "$REPO/build/out/vsavj_data.bin" || {
        echo "FAIL: build/out/vsavj_data.bin is not vsavj's data view decrypted afresh from ROMDIR"; return 1; }
    for _pv_i in "$@"; do
        cmp -s "$_pv_w/pv_data.bin" "$_pv_i" || {
            echo "FAIL: the analysed image $_pv_i (sha1 $(_pv_sha "$_pv_i")) is not vsavj's data view decrypted afresh from ROMDIR (sha1 $(_pv_sha "$_pv_w/pv_data.bin"))"
            return 1; }
    done
    echo "  rom   ROMDIR $(echo "$_pv_rc" | grep 'all match' | head -1); vsavj program fingerprint $_pv_fp = registry vsavj row; vsavj.zip sha1 $(_pv_sha "$_pv_rd/vsavj.zip"); data view sha1 $(_pv_sha "$_pv_w/pv_data.bin") = build/out's two views$( [ $# -gt 0 ] && echo " = $*" ), decrypted afresh"
    echo "$_pv_mi"; echo "  rompath MAME_ROMPATH '${MAME_ROMPATH:-}' (unset, or ROMDIR itself): the legs load ROMDIR (tools/run_mame.sh -rompath)"
}

# _pv_foreign <workdir> — the controls' inputs: a one-byte-off data view, and a ROMDIR of links whose vsavj.zip is vsav2's
_pv_foreign() {
    _pv_w="$1"; mkdir -p "$_pv_w/romdir_foreign"
    python3 "$REPO/tools/cps2_decrypt.py" "$ROMDIR/vsavj.zip" "$_pv_w/fx_op.bin" --data-out "$_pv_w/fx_data.bin" > /dev/null 2>&1
    python3 -c 'import sys;b=bytearray(open(sys.argv[1],"rb").read());b[0x100000]^=1;open(sys.argv[2],"wb").write(b)' \
        "$_pv_w/fx_data.bin" "$_pv_w/foreign_data.bin"
    for _pv_z in "$ROMDIR"/*.zip; do ln -sf "$_pv_z" "$_pv_w/romdir_foreign/$(basename "$_pv_z")"; done
    ln -sf "$ROMDIR/vsav2.zip" "$_pv_w/romdir_foreign/vsavj.zip"
}

vs_pristine_vsavj() {
    _pv_W="$1"; shift
    case "${VS_CTL:-}" in
        foreign-image)  _pv_foreign "$_pv_W/ctl"; _pv_check "$ROMDIR" "$_pv_W/chk" "$_pv_W/ctl/foreign_data.bin" ;;
        foreign-romset) _pv_foreign "$_pv_W/ctl"; _pv_check "$_pv_W/ctl/romdir_foreign" "$_pv_W/chk" "$@" ;;
        foreign-rompath) _pv_foreign "$_pv_W/ctl"; ( MAME_ROMPATH="$_pv_W/ctl/romdir_foreign"; _pv_check "$ROMDIR" "$_pv_W/chk" "$@" ) ;;
        foreign-mame)   ( MAME_BIN=/bin/echo; _pv_check "$ROMDIR" "$_pv_W/chk" "$@" ) ;;
        *)              _pv_check "$ROMDIR" "$_pv_W/chk" "$@" ;;
    esac
}

# vs_pristine_vsavj_controls <workdir> — the four controls in-gate: prints a CONTROL FIRED / CONTROL DEAD line for each;
# returns 1 when either is dead
vs_pristine_vsavj_controls() {
    _pv_W="$1"; _pv_dead=0; _pv_foreign "$_pv_W/ctl"
    if _pv_out="$(_pv_check "$ROMDIR" "$_pv_W/c1" "$_pv_W/ctl/foreign_data.bin")"; then
        echo "CONTROL DEAD: foreign-image — an image one byte off vsavj's data view passed the provenance check"; _pv_dead=1
    else echo "CONTROL FIRED: foreign-image — $(echo "$_pv_out" | grep -m1 '^FAIL:' | cut -c7-120)"; fi
    if _pv_out="$(_pv_check "$_pv_W/ctl/romdir_foreign" "$_pv_W/c2")"; then
        echo "CONTROL DEAD: foreign-romset — a ROMDIR whose vsavj.zip is vsav2.zip passed the provenance check"; _pv_dead=1
    else echo "CONTROL FIRED: foreign-romset — $(echo "$_pv_out" | grep -m1 '^FAIL:' | cut -c7-120)"; fi
    if _pv_out="$( MAME_ROMPATH="$_pv_W/ctl/romdir_foreign"; _pv_check "$ROMDIR" "$_pv_W/c3" )"; then
        echo "CONTROL DEAD: foreign-rompath — MAME_ROMPATH pointed away from the audited ROMDIR passed the provenance check"; _pv_dead=1
    else echo "CONTROL FIRED: foreign-rompath — $(echo "$_pv_out" | grep -m1 '^FAIL:' | cut -c7-120)"; fi
    if _pv_out="$( MAME_BIN=/bin/echo; _pv_check "$ROMDIR" "$_pv_W/c4" )"; then
        echo "CONTROL DEAD: foreign-mame — a MAME_BIN that is not the pin's release passed the provenance check"; _pv_dead=1
    else echo "CONTROL FIRED: foreign-mame — $(echo "$_pv_out" | grep -m1 '^FAIL:' | cut -c7-120)"; fi
    return $_pv_dead
}
