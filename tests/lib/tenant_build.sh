# tenant_build.sh — the "fresh --tenant-id 0x13 stage-6 build" block, once.
# Sourced, not executed. (14z-94, GitHub #71.)
#
# WHY. Five gates carried this block byte-for-byte identical, each with the
# stage number `6` and the flags `--allow-plausible --tripwire-open
# --profile cps2-wide-v1 --tenant-id 0x13` inline. That triple — stage,
# profile, tenant id — is exactly the build-shape knowledge CLAUDE.md rule 5
# wants in ONE documented place, and all three have moved repeatedly in this
# project's history: the de-substituted id flipped at 14z-64, the profile name
# arrived with WIDE, the stage number has moved with the pipeline. Five inline
# copies is five places a re-freeze has to find, and four of them will keep
# building the old shape while their static checks assert against a build the
# registry no longer describes.
#
# tests/lib/m2a_common.sh already established the factoring pattern here.
#
# THE SECOND COST, which the ticket also names: each copy runs its OWN full
# build when invoked without an outbase, so a battery running all five pays
# five builds. TENANT13_OUTBASE lets a caller build once and share it; the
# default behaviour is unchanged.
#
# Usage:
#   . "$REPO/tests/lib/tenant_build.sh"
#   tenant_build_13 "$WORK" "${1:-}"      # sets OUTBASE
#
#   OUTBASE given          -> used as-is, nothing is built
#   TENANT13_OUTBASE set   -> reused if it looks like a build, else fatal
#   neither                -> a fresh build at <work>/build

# The build shape, in one place. Changing any of these is a build-shape
# decision and belongs in STATE.md, not in five test scripts.
: "${TENANT13_STAGE:=6}"
: "${TENANT13_PROFILE:=cps2-wide-v1}"
: "${TENANT13_ID:=0x13}"

# tenant_build_13 <workdir> [supplied-outbase]  — sets OUTBASE
tenant_build_13() {
    _tb_work="${1:?tenant_build_13 needs a work dir}"
    OUTBASE="${2:-}"
    [ -n "$OUTBASE" ] && return 0

    if [ -n "${TENANT13_OUTBASE:-}" ]; then
        # Shared build opted into by the caller. Validated rather than
        # trusted: a stale or half-built path here would be read as a
        # legitimate build by five gates at once.
        if [ -f "$TENANT13_OUTBASE/rompath/vsavjw.zip" ]; then
            OUTBASE="$TENANT13_OUTBASE"
            echo "== 0. reusing TENANT13_OUTBASE=$OUTBASE"
            return 0
        fi
        echo "TENANT13_OUTBASE=$TENANT13_OUTBASE has no rompath/vsavjw.zip" >&2
        return 1
    fi

    OUTBASE="$_tb_work/build"
    echo "== 0. building at --tenant-id $TENANT13_ID (fresh) =="
    KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
--profile $TENANT13_PROFILE --tenant-id $TENANT13_ID" \
        tools/build_donovan.sh "$TENANT13_STAGE" "$OUTBASE" \
        > "$_tb_work/build.log" 2>&1 || {
        echo "FAIL: build did not complete"; tail -20 "$_tb_work/build.log"
        return 1; }
    tail -2 "$_tb_work/build.log" | sed 's/^/  /'
}
