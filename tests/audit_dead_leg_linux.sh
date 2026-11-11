#!/bin/sh
# audit_dead_leg_linux.sh — THE LINUX-ONLY RELEASE GATES' DEAD-LEG ROWS (#310 group 7, 14z-223):
# tests/test_dead_leg_unjudged.sh on tests/expected/dead_leg_unjudged_linux.tsv, at release, on PILOT.
#
# WHAT: the five control modes of tests/audit_release_linux_cleanhost.sh (2) and tests/audit_release_linux_desktop.sh (3),
#   run with their leg's instrument dead, read UNJUDGED (a dead leg is not the control firing), their copies with the
#   `# #310 g7 NJ` lines neutered read their frozen pre-fix class, and their plain runs are red and silent — exactly
#   tests/test_dead_leg_unjudged.sh's checks (its header is the specification), on the Linux table; and the runs left no
#   release emulator or sink recorder running (tools/desktop_session_play.py stops them even when a step raises: before
#   14z-223 a dead xwd leaked two runs' emulators and recorders into the session and failed the next desktop run).
# HOW: runs tests/test_dead_leg_unjudged.sh with DLU_TABLE=tests/expected/dead_leg_unjudged_linux.tsv, passing CONTROL
#   through, prints its output, and judges the two controls itself from it: each control's own `CONTROL FIRED:` line
#   there is re-emitted as this gate's firing, anything else is this gate's CONTROL DEAD. Exits with the inner status
#   (1 if a control is dead or a process was left running; such a process is named and killed). The rows run one at a time (their dead instruments are on PATH). Each target gate's plain
#   run writes its kept output dir (build/cleanhost_release, build/desktop_release) with a dead instrument, so run this
#   AFTER the two gates' own release runs, whose logs are the release's record, and ALONE: it claims the desktop session
#   for its whole run (tests/lib/desktop_session.sh) and is REFUSED (exit 3) beside another desktop gate or a release
#   emulator already running — a desktop run refused inside a row reads UNJUDGED, a row's frozen class (14z-223).
# EXPECTS: PASS with 5 rows; a Linux host with podman, a live GNOME session for this user, ROMDIR, and the release's
#   linux-x86_64 binaries under release/<name>/ (or ASSETS=<dir of zips>), as the two target gates need. Elsewhere it
#   SKIPs and says so: at release it runs on PILOT, after the two gates it checks.
# FOLLOWS: tests/test_dead_leg_unjudged.sh tests/expected/dead_leg_unjudged_linux.tsv tests/audit_release_linux_cleanhost.sh tests/lib/shares.sh tests/lib/share_lock.py tests/shares.tsv
#   tests/audit_release_linux_desktop.sh tests/lib/controls.sh tests/lib/classify.sh tools/desktop_session_play.py
#   tests/lib/desktop_session.sh emu/fbneo/ emu/fbneo-patches/ tools/setup_fbneo.sh
#
# SHEET: none — an instrument, emulator, release or host check; no leg of our build compared with a reference set
#
# MUST-FIRE: known-bad: nj-stripped — as tests/test_dead_leg_unjudged.sh's: every row's mode run on its gate's copy with the NJ lines neutered must read its frozen stripped class, and the gate must FAIL (in-gate: the inner section 3; mode: the inner section 2 runs the stripped copies)
# MUST-FIRE: known-bad: plain-loud — as tests/test_dead_leg_unjudged.sh's: a controls.sh whose vs_ctl_nj prints in a plain run too must make the inner section 1's plain case and the rows' plain runs print NOT JUDGED (in-gate on the loud copies; mode: the rows run them)
#
# WHY: #310 group 7 batch 5 (14z-223). Both target gates SKIP off Linux, before any instrument, so tests/test_dead_leg_unjudged.sh
#   (static tier, the Mac) cannot judge their modes. Asked where those rows should run, the maintainer: "A. A small
#   release-cadence emulator gate that judges the 5 rows on PILOT at release (my recommendation). It sits alongside the
#   two gates it checks. Off Linux it SKIPs visibly, like they do, and a red blocks the release. -> agreed."
# SHARES: self desktop-session release-assets
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd -P)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

# ---- where this gate can run at all: the two target gates' own host conditions ----------------------------------
[ "$(uname -s)" = Linux ] || { echo "SKIP: not a Linux host (this is $(uname -s)); at release it runs on PILOT"; exit 0; }
command -v podman >/dev/null 2>&1 || { echo "SKIP: podman is not installed on this host (audit_release_linux_cleanhost's rows need it)"; exit 0; }
ls "/run/user/$(id -u)"/.mutter-Xwaylandauth.* >/dev/null 2>&1 || {
    echo "SKIP: no live GNOME session for this user (audit_release_linux_desktop's rows need one: unlock PILOT's desktop)"; exit 0; }
if [ -z "${ASSETS:-}" ]; then
    have=""
    for d in release/merged-m*/; do
        [ -x "${d}fbneo/emulator/bin/linux-x86_64/fbneo" ] && [ -x "${d}mame/emulator/bin/linux-x86_64/cps2" ] && have="$d"
    done
    [ -n "$have" ] || { echo "SKIP: no release/merged-m*/ holds both linux-x86_64 binaries (copy the release's build there, or give ASSETS=<dir of zips>)"; exit 0; }
fi
[ -n "${ROMDIR:-}" ] && [ -d "$ROMDIR" ] || { echo "FAIL: audit_dead_leg_linux — set ROMDIR to the reference dumps"; exit 1; }

W="$(mktemp -d)" || { echo "FAIL: audit_dead_leg_linux — mktemp -d failed"; exit 2; }
. "$REPO/tests/lib/desktop_session.sh"
trap 'vs_desktop_release; rm -rf "$W"' EXIT
trap 'exit 143' INT TERM
# the desktop rows' runs (tools/desktop_session_play.py) must leave nothing playing: before 14z-223 a dead xwd crashed the
# driver past its stop, and the two runs' emulators and sink recorders kept playing into the session, failing the next
# desktop run's signal and link checks on PILOT. Only processes of the release package (the path the desktop gate
# unpacks) and the driver's sink recorder are counted, so another gate's own MAME (also named cps2, run from its build
# dir) is never touched; a release binary run by another gate meanwhile (a pooled cleanhost run's container) would be,
# and that run would fail red.
# The gate claims the session for its whole run (tests/lib/desktop_session.sh): REFUSED (exit 3) beside another desktop
# gate or a release emulator already running, so a desktop run refused inside a row (which reads UNJUDGED, a row's frozen
# class) can only be one of its own; its nested target-gate runs claim nothing (VS_DESKTOP_OWNER).
vs_desktop_claim audit_dead_leg_linux
vs_shares_claim audit_dead_leg_linux release-assets   # SHARES-CLAIM (#370, 14z-225): the release package it unpacks (desktop-session is vs_desktop_claim's)
leftovers() { vs_desktop_procs; }
leftovers > "$W/procs.before"
DLU_TABLE="$REPO/tests/expected/dead_leg_unjudged_linux.tsv" JOBS=1 /bin/sh "$REPO/tests/test_dead_leg_unjudged.sh" > "$W/inner.log" 2>&1; rc=$?
grep -av '^CONTROL \(FIRED\|DEAD\|CAUGHT\): ' "$W/inner.log"   # the inner gate's control lines are re-judged below, never relayed
sleep 2; leftovers > "$W/procs.after"
new="$(comm -13 "$W/procs.before" "$W/procs.after" | tr '\n' ' ')"
if [ -n "${new% }" ]; then
    echo "  FAIL  the dead-leg runs left a release emulator or sink recorder running (killed now, so later gates are not fed its sound):"
    for p in $new; do ps -o pid=,args= -p "$p" 2>/dev/null | cut -c1-200 | sed 's/^/          /'; done
    kill -9 $new 2>/dev/null; rc=1
else
    echo "  ok    the dead-leg runs left no release emulator or sink recorder running"
fi
if [ -n "${VS_CTL:-}" ]; then   # #369: a mode is honoured only on its own finding in the inner check's output
    # the inner gate's DEAD line for this mode (its vs_ctl_left_green: the mode left IT green) is relayed, so a dead
    # control reads LIES here too, never UNJUDGED (the filter above drops it)
    _dl="$(grep -a "^CONTROL DEAD: $VS_CTL — " "$W/inner.log")"
    if [ -n "$_dl" ]; then printf '%s\n' "$_dl"; echo "FAIL: audit_dead_leg_linux (control mode $VS_CTL: the inner gate's CONTROL DEAD line, relayed above)"; exit 1; fi
    [ "$rc" = 0 ] && vs_ctl_left_green "$VS_CTL" "FAIL: audit_dead_leg_linux (control mode $VS_CTL)"
    case "$VS_CTL" in
    # UNJUDGED-CAUGHT: a migrated row gate's neutered leg (#369 piece 5) — the inner gate prints it too (its line 207);
    # missed by r6, which fixed the twin in audit_crash_sweep_emu (rule-checker run 2026-11-10-1765 Q4)
    nj-stripped) WANT='^  FAIL  [a-z0-9_]+@[a-z0-9-]+ reads (HONOURED|LIES|UNJUDGED-CAUGHT) under a dead emulator, frozen UNJUDGED ' ;;
    plain-loud) WANT='^  FAIL  [a-z0-9_]+: its plain run prints NOT JUDGED \(the helper is not silent without a mode\)$' ;;
    *) WANT='' ;;
    esac
    vs_ctl_caught "$W/inner.log" "$WANT" || :
    echo "FAIL: audit_dead_leg_linux (control mode $VS_CTL)"; exit 1
fi
for c in nj-stripped plain-loud; do
    l="$(grep -am1 "^CONTROL FIRED: $c — " "$W/inner.log")"
    if [ -n "$l" ]; then vs_ctl_fired "$c" "${l#CONTROL FIRED: $c — }"
    else
        vs_ctl_dead "$c" "the inner gate printed no firing for it: $(grep -am1 "^CONTROL DEAD: $c — " "$W/inner.log" | cut -c1-160)" || rc=1
    fi
done
if [ "$rc" = 0 ]; then echo "PASS: audit_dead_leg_linux"; else echo "FAIL: audit_dead_leg_linux"; fi
exit "$rc"
