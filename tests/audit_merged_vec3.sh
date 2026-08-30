#!/bin/sh
# audit_merged_vec3.sh — the merged-build Huitzil satellite anim-base probe
# (14z-81). Rerunnable capture of the diagnosis rig that localized the
# merged-legacy audit's Huitzil crash; becomes the REGRESSION GATE for the
# eventual fix.
#
# THE MEASURED DEFECT (14z-81, deterministic, 3/3 MAME runs): on a 3-tenant
# merged build, Huitzil's satellite (object $FFB800 at char-init, MAME frame
# 2886 on hui/70_hui_mash) enters the vanilla anim walker (entry PRG:0x15084;
# the faulting move.l (a0),(0x20,a6) is at 0x15096, pushed vec3 PC 0x15098)
# with base A0 = 0x000CB9C0 — an UNPLACED gap. On hui29 the same probe reads
# A0 = 0x000E456C = his placed anim + 0xB8AC; the healthy merged value would
# be anim@huitzil + 0xB8AC. 0xCB9C0 appears NOWHERE in the merged image
# (raw-byte and ops search both empty): the base is COMPOSED AT RUNTIME, and
# 0xCB9C0 - 0xB8AC = 0x000C0114 = tenant-0's ported `code` region + 0xA74 —
# a DONOVAN address on a HUITZIL object. Ruled out by direct verification:
# all fifteen anim_index_{a,a2,b,c,proj}[id] rows are correct per tenant in
# the merged fragment; the x06cac0 satellite-machine blob differs from
# hui29's only in correctly re-derived literals; the pc-rel stub + word
# table at x026142+0x13E2 is byte-identical.
#
# NAMED same day (14z-81b, via GUARD_PROBE_HIST): the crash executes
# `movea.l #$cb9c0,A0; jmp $15084` INSIDE TENANT-0's x088512 copy — 0xCB9C0
# is Donovan's PLANTED TRIPWIRE for the huitzil-anim pointer he does not
# port (m5_wide fragment:140), consumed as a DATA base instead of jumped
# to. Huitzil's own copy holds the correct 0x425FFC at the same offset.
# The route is the defect: object TYPE 117's handler lives in x088512,
# which ALL tenants port, so the merged obj_hook union's ONE extended-table
# entry can only point at one tenant's internally tenant-reconciled copy.
#
# FIX STATUS: GREEN since 14z-82 — per-tenant TYPE NUMBERS (the shipped
# design; the 14z-81c owner-read STUB was implemented, briefly green, and
# WITHDRAWN on two measured timing failure modes — STATE 14z-81c). Every
# non-first tenant's stamps are renumbered at build time from the frozen
# inventory (build/manifest/type_stamps.toml) and the union carries
# per-tenant entries into each tenant's OWN copy, so this probe reads
# A0 = anim@huitzil + 0xB8AC on the merged build. A FAIL here now is a
# REGRESSION of that mechanism. Still pair any change with
# donovan/12_vs_cpu staying guard-clean — the replay that caught the
# withdrawn design.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/audit_merged_vec3.sh [merged_build]
# Default merged build: build/merged1 (rebuild it with
# tests/audit_merged_legacy.sh). ~4 min: two guarded MAME runs.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-81: the merged Huitzil satellite anim-base probe — the crash localized
#   by the measurement above, made rerunnable (~4 min, 2 guarded runs). Probes
#   the vanilla walker ENTRY (0x15084; the pushed vec3 PC 0x15098 is MID-
#   INSTRUCTION and probes as a clean zero — the dead-instrument trap, gotcha
#   filed) on hui29 and the merged build, same object/frame/index, and
#   compares the base against the placements-derived healthy value. FAILS BY
#   DESIGN until the fix lands; then it is the regression gate. Rig control:
#   no PROBE at 2886 on hui29 = rig dead, hard fail
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
MERGED="${1:-build/merged1}"
REF=build/hui30

for d in "$MERGED/rompath" "$REF/rompath"; do
    [ -d "$d" ] || { echo "SKIP: missing $d (run tests/audit_merged_legacy.sh"; \
                     echo "      first for build/merged1)"; exit 0; }
done
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }
HUI_POKES="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"

# The walker ENTRY (0x15084) is probed, not the fault PC: a 68000 address
# error pushes a PC INSIDE the faulting instruction (0x15098), which never
# matches an instruction start, so a bp there reads as a clean zero — the
# dead-instrument trap, measured 14z-81.
probe() {  # probe <build> <out>
    POKES="$HUI_POKES" MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
    GUARD_PROBE=15084 GUARD_PROBE_COND="a6==0xffb800" GUARD_PROBE_MAX=20000 \
        tools/run_replay_guarded.sh vsavjw tests/replays/hui/70_hui_mash.rpl \
        "$2" "$W/box_$(basename "$2")" >/dev/null 2>&1 || true
}
a0_at_2886() { sed -n 's/^PROBE 2886 .*A0=\([0-9a-f]*\) A6=00ffb800.*/\1/p' "$1" | head -1; }

echo "== the healthy reference (hui29) =="
probe "$REF" "$W/ref.log"
R="$(a0_at_2886 "$W/ref.log")"
[ -n "$R" ] || { echo "FAIL: rig dead — no PROBE at 2886 on hui29 (the replay"; \
                 echo "      or pokes moved; fix the rig before reading verdicts)"; exit 1; }
echo "  ok: hui29 satellite anim base A0=0x$R at frame 2886"

# the healthy merged expectation, computed from the placements (never baked)
EXP="$(python3 - "$MERGED" "$REF" "0x$R" <<'PY'
import json, sys
m = json.load(open(sys.argv[1] + "/patch/placements.json"))["regions"]
h = json.load(open(sys.argv[2] + "/patch/placements.json"))["regions"]
off = int(sys.argv[3], 16) - h["anim"]["dst"]
ha = m.get("anim@huitzil") or m.get("anim")   # single-tenant fallback
print(f"{ha['dst'] + off:x}")
PY
)"

echo "== the build under test ($MERGED) =="
probe "$MERGED" "$W/new.log"
M="$(a0_at_2886 "$W/new.log")"
CRASH="$(grep -m1 '^CRASH' "$W/new.log" || true)"
[ -n "$M" ] || { echo "FAIL: rig dead on $MERGED — no PROBE at 2886"; exit 1; }
echo "  measured A0=0x$M (healthy would be 0x$EXP); ${CRASH:-no crash}"

# numeric compare — the probe prints A0 zero-padded to 8 digits, the
# placements-derived expectation does not, and the FIRST live PASS of this
# gate (14z-81b, the fix build) was mis-verdicted by that string mismatch
M="$(printf '%d' "0x$M")"; EXP="$(printf '%d' "0x$EXP")"
if [ "$M" = "$EXP" ] && [ -z "$CRASH" ]; then
    echo "PASS: the merged satellite reads its anim base from anim@huitzil"
    echo "      and the run is crash-free — the 14z-81 defect is FIXED;"
    echo "      re-run tests/audit_merged_legacy.sh before trusting more"
else
    echo "FAIL: the satellite's runtime-composed base is wrong on the"
    echo "      merged build (see header for everything already ruled out)."
    echo "      Since 14z-82 this gate is GREEN (per-tenant type numbers),"
    echo "      so this is a REGRESSION of the multi-owner dispatch — check"
    echo "      the renumber map/worklist and the frozen stamp inventory"
    echo "      (tests/test_type_stamp_census.sh) first."
    exit 1
fi
