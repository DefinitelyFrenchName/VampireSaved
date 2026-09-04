#!/bin/sh
# test_movability_liveness.sh — ground truth that tests/audit_region_movability.sh
# cannot score a DEAD emulator as a successful run (14z-90, GitHub issue #5).
#
# WHY. The audit's verdict used to derive from the ABSENCE of a crash string:
#
#     tools/run_replay_guarded.sh ... || true
#     if grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$log"; then got=crash
#     else got=runs; fi
#
# so every way of producing no output scored `runs` — an empty log, a MISSING
# log (grep exits 2, which lands in the else), a crashed or never-started
# emulator. run_replay_guarded.sh already exits non-zero unless the log ends
# in a clean END line; that signal was discarded by `|| true`. The audit's own
# header demands a liveness control for the Huitzil/Pyron extension and it was
# never applied to the existing legs — this is that control, applied.
#
# HOW, without ~18 minutes of builds: the audit takes two seams, BUILDER_CMD
# and GUARDED_RUNNER, both defaulting to the production tools. The controls
# inject stubs, so what is exercised is exactly the scoring path.
#
# THE POSITIVE LEG IS NOT OPTIONAL. An audit that always FAILs would satisfy
# the negative legs alone; the third case proves the scoring still says `runs`
# when the rig is genuinely alive.
#
# Usage: ROMDIR=... tests/test_movability_liveness.sh   (no emulator, seconds)
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-90 (issue #5): ground truth that tests/audit_region_movability.sh
#   cannot score a DEAD emulator as `runs`. Injects stub builder/runner via
#   BUILDER_CMD and GUARDED_RUNNER: never-started and empty-log rigs must FAIL
#   and be named `dead`; a live rig must still score `runs`. Pre-fix the same
#   rig exited 0 and printed the budget claim. ROMDIR, no emulator, seconds
set -eu

ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail=0
AUDIT=tests/audit_region_movability.sh

# The audit SKIPs (exit 0) without a WIDE MAME binary and a WIDE romset. A
# skip here would make this control vacuous, so refuse to run instead.
MB="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
WZ="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"
if [ ! -x "$MB" ] || [ ! -f "$WZ" ]; then
    echo "FAIL: cannot run — the audit would SKIP, making this control vacuous"
    echo "      need MAME_BIN=$MB and WIDE_ROMSET=$WZ"
    exit 1
fi

# stub builder: instant, always "succeeds", makes the rompath the audit expects
cat > "$WORK/builder" <<'B'
#!/bin/sh
mkdir -p "$2/rompath"; : > "$2/rompath/vsavjw.zip"; exit 0
B
chmod +x "$WORK/builder"

# $1 = dead|alive
write_runner() {
    if [ "$1" = dead ]; then
        cat > "$WORK/runner" <<'R'
#!/bin/sh
# emulator never started: no log written, non-zero exit
exit 1
R
    else
        cat > "$WORK/runner" <<'R'
#!/bin/sh
# alive: a clean run ends with an END line
printf '1 %016x\n' 1 > "$3"
echo "END 1" >> "$3"
exit 0
R
    fi
    chmod +x "$WORK/runner"
}

# 14z-123: the audit gained two TENANT cases whose liveness reads the built
# prg member and placements.json — things the stub builder does not write, so
# under these stubs they can only ever score `dead`. The controls are scoped
# to the four Donovan cases; a positive control that passed on ANY `-> runs`
# line would otherwise hide a tenant case that had quietly stopped proving.
CASES="anim aux4 codereg hitboxes"; export CASES
run_audit() {
    write_runner "$1"
    set +e
    OUT="$(BUILDER_CMD="$WORK/builder" GUARDED_RUNNER="$WORK/runner" \
           ROMDIR="$ROMDIR" "$REPO/$AUDIT" 2>&1)"
    RC=$?
    set -e
}

# --- 1. dead rig must FAIL, and must be NAMED as dead -------------------
echo "== 1. emulator never starts =="
run_audit dead
if [ "$RC" = 0 ]; then
    echo "FAIL: a dead emulator scored a PASS (exit 0)"; fail=1
else
    echo "  ok: audit exited $RC"
fi
if echo "$OUT" | grep -q "DEAD RIG"; then
    echo "  ok: the leg is named dead, not scored as evidence"
else
    echo "FAIL: dead rig was not identified as such"; fail=1
fi
if echo "$OUT" | grep -qE '^ *ok: .* -> runs'; then
    echo "FAIL: a leg still scored 'runs' with no emulator output"; fail=1
else
    echo "  ok: no leg scored 'runs'"
fi
# The anti-SKIP clause: ~33 gates in this repo exit 0 on missing inputs, and a
# control that a SKIP could satisfy proves nothing.
if echo "$OUT" | grep -q '^SKIP'; then
    echo "FAIL: audit SKIPped — this control measured nothing"; fail=1
else
    echo "  ok: audit did not skip"
fi

# --- 2. an empty log (process ran, wrote nothing) also FAILs ------------
echo "== 2. runner exits 0 but writes an empty log =="
cat > "$WORK/runner_empty" <<'R'
#!/bin/sh
: > "$3"
exit 0
R
chmod +x "$WORK/runner_empty"
set +e
OUT="$(BUILDER_CMD="$WORK/builder" GUARDED_RUNNER="$WORK/runner_empty" \
       ROMDIR="$ROMDIR" "$REPO/$AUDIT" 2>&1)"; RC=$?
set -e
if [ "$RC" != 0 ] && echo "$OUT" | grep -q "DEAD RIG"; then
    echo "  ok: an END-less log is dead, not 'runs'"
else
    echo "FAIL: an empty log did not fail the audit (rc=$RC)"; fail=1
fi

# --- 3. POSITIVE CONTROL: a live rig still scores 'runs' ---------------
echo "== 3. positive control: live rig =="
run_audit alive
if [ "$(echo "$OUT" | grep -cE '^ *ok: .* -> runs')" = 4 ]; then
    echo "  ok: a live rig still scores 'runs' (all 4 Donovan cases)"
else
    echo "FAIL: the liveness check rejected a healthy run — over-tightened"
    echo "$OUT" | tail -5
    fail=1
fi

[ "$fail" = 0 ] && echo "PASS: region-movability liveness (2 dead-rig controls + positive control)" \
    || { echo "FAIL: region-movability liveness"; exit 1; }
