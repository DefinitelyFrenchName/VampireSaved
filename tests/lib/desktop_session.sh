# tests/lib/desktop_session.sh — ONE HARNESS AT A TIME ON THE LINUX DESKTOP SESSION (#310 group 7, 14z-223).
# Sourced by tests/audit_release_linux_desktop.sh and tests/audit_dead_leg_linux.sh; tools/desktop_session_play.py reads
# the same owner file. The desktop session is ONE shared thing — its null sink, its PipeWire graph, the X display and its
# keyboard focus — and a write trace cannot see it (docs/project/gotchas.md, 14z-223). Two harnesses on it at once break
# each other, and worse: inside audit_dead_leg_linux a desktop run refused because a sibling plays (the driver's `stray`
# exit 3) reads UNJUDGED, which IS a dead-leg row's frozen class, so the row would pass without its dead instrument having
# been judged. Nothing in tests/run_all_emulator.sh keeps two gates apart in a pooled run, so each gate claims the session.
# SINCE #370 (14z-225) the claim IS the `desktop-session` token's host claim (tests/lib/shares.sh vs_shares_claim, wait 0
# in tests/shares.tsv: refused at once, as before); the owner file stays, as the driver's view of who owns the session.
#
#   vs_desktop_claim <gate>   claim the session for this shell's lifetime: refuse (REFUSED:, exit 3 — UNJUDGED under a
#                             control mode, red in a plain run) when another live harness owns it, or when a release
#                             emulator or the driver's sink recorder is already running; otherwise write the owner file
#                             and export VS_DESKTOP_OWNER. A shell running UNDER the owner (VS_DESKTOP_OWNER names the live
#                             owner: the desktop gate inside audit_dead_leg_linux) claims and checks nothing — the owner
#                             checked the session at its start and checks for leftovers at its end.
#   vs_desktop_release        remove the owner file if this shell wrote it (call it from the gate's EXIT trap).
#   vs_desktop_procs          the pids of release emulators and sink recorders now running, one per line, sorted.
# The owner file: /run/user/<uid>/vampire-saved-desktop.owner, "<pid> <gate>". A file naming a dead pid is stale and ignored.
VS_DESKTOP_OWNER_FILE="/run/user/$(id -u)/vampire-saved-desktop.owner"
. "${REPO:?desktop_session.sh needs REPO}/tests/lib/shares.sh"
VS_DESKTOP_CLAIMED=""

vs_desktop_procs() {   # only the release package's binaries (the path the desktop gate unpacks) and the driver's recorder
    pgrep -f 'emulator/bin/linux-x86_64/(fbneo|cps2)( |$)|pw-record -P \{ stream\.capture\.sink=true' 2>/dev/null | sort -n
}

vs_desktop_claim() {
    _vdo=""; [ -f "$VS_DESKTOP_OWNER_FILE" ] && _vdo="$(cut -d' ' -f1 "$VS_DESKTOP_OWNER_FILE" 2>/dev/null)"
    if [ -n "$_vdo" ] && kill -0 "$_vdo" 2>/dev/null; then
        [ "${VS_DESKTOP_OWNER:-}" = "$_vdo" ] && return 0   # nested under the owner
        echo "REFUSED: $1 — another harness owns the desktop session: $(cat "$VS_DESKTOP_OWNER_FILE" 2>/dev/null) (run one desktop gate at a time)"
        exit 3
    fi
    vs_shares_claim "$1" desktop-session   # DESKTOP-CLAIM (#370): the host claim; REFUSED, exit 3, beside a live holder
    echo "$$ $1" > "$VS_DESKTOP_OWNER_FILE" || { echo "REFUSED: $1 — cannot write $VS_DESKTOP_OWNER_FILE"; exit 3; }
    VS_DESKTOP_CLAIMED=1; VS_DESKTOP_OWNER=$$; export VS_DESKTOP_OWNER
    sleep 3   # a sibling's driver that passed its owner check just before this claim has started its processes by now
    _vdp="$(vs_desktop_procs | tr '\n' ' ')"
    if [ -n "${_vdp% }" ]; then
        echo "REFUSED: $1 — a release emulator or sink recorder is already running on this host (not this gate's; left as it is):"
        for _p in $_vdp; do ps -o pid=,args= -p "$_p" 2>/dev/null | cut -c1-200 | sed 's/^/          /'; done
        vs_desktop_release; exit 3
    fi
    return 0
}

vs_desktop_release() {
    [ -n "$VS_DESKTOP_CLAIMED" ] && [ "$(cut -d' ' -f1 "$VS_DESKTOP_OWNER_FILE" 2>/dev/null)" = "$$" ] && rm -f "$VS_DESKTOP_OWNER_FILE"
    vs_shares_release
    return 0
}
