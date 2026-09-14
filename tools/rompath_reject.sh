# rompath_reject.sh — A REJECTED BUILD DOES NOT KEEP ITS ROMPATH. Sourced, not
# executed, by tools/build_donovan.sh (bash) and tools/build_merged.sh (sh), so
# it is plain POSIX and both shells run the same code. (14z-155, #139 — the
# residual #1 deferred on 2026-08-16; this EXIT-trap variant maintainer-ruled
# 2026-09-14 over staging the pack through `rompath.tmp`.)
#
# WHY. Both builders pack <outbase>/rompath FIRST and verify it afterwards (the
# group-B check, verify_gfx_build.py, audit_romset_identity.py,
# check_tenant_hud.py). A rejection exited 1 with "BUILD REJECTED … do not
# playtest" and LEFT THE PACKED ZIPS in rompath, so on disk a rejected build
# looked exactly like a finished one: tools/run_wide.sh playtests any rompath,
# and a gate pointed at the directory measures it. The callers' status handling
# (#1) closed the scripted path; this closes the one a person walks. The
# guarantee: a rompath on disk passed its builder's own checks.
#
# HOW.
#   rompath_reject_arm <dir>   once <dir> has been cleared and before anything is
#                              packed into it: removes a <dir>.REJECTED left by an
#                              earlier failure and arms the traps (INT and TERM
#                              exit through EXIT, with 130 and 143).
#   rompath_reject_disarm      immediately before the builder's final OK line.
# On any exit before the disarm, an existing <dir> is RENAMED to <dir>.REJECTED:
# the evidence is kept and nothing resolves it as a build. A directory never
# created (a failure before the pack) is left alone. The exit status is kept,
# except that an exit with status 0 which never reached the disarm becomes 1:
# a builder that stops before its final OK has not succeeded, and on macOS
# bash 3.2 a `${VAR:?}` demand failing under an armed EXIT trap exits 0
# ([VSP-176]).
#
# The traps REPLACE any EXIT/INT/TERM trap set before arming; neither builder
# sets one (checked when this was added). Ground truth: tests/test_rompath_reject.sh.

rompath_reject_arm() {  # rompath_reject_arm <dir>
    _rr_dir="$1"
    _rr_ok=0
    rm -rf "$_rr_dir.REJECTED"
    trap '_rr_rc=$?; rompath_reject_on_exit "$_rr_rc"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

rompath_reject_on_exit() {  # the EXIT trap's body; $1 = the exit status
    trap - EXIT
    _rr_st="$1"
    if [ "$_rr_ok" != 1 ]; then
        if [ "$_rr_st" = 0 ]; then
            echo "BUILD REJECTED: the builder exited before its final OK line" >&2
            _rr_st=1
        fi
        if [ -d "$_rr_dir" ]; then
            if mv "$_rr_dir" "$_rr_dir.REJECTED"; then
                echo "BUILD REJECTED: $_rr_dir moved to $_rr_dir.REJECTED (exit $_rr_st) — kept as evidence; nothing resolves it as a build" >&2
            else
                echo "BUILD REJECTED, AND $_rr_dir COULD NOT BE MOVED ASIDE — do not run anything from it" >&2
            fi
        fi
    fi
    exit "$_rr_st"
}

rompath_reject_disarm() { _rr_ok=1; }
