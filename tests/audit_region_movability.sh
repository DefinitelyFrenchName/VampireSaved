#!/bin/sh
# audit_region_movability.sh — which regions can actually live in wide_ext?
#
# WHY (M3b, 14z-77). The merge's binding constraint is the CRYPT WINDOW, not
# total size: one tenant already saturates hole_a, and three tenants keeping
# their own region copies need 761,316 bytes of its 264,544
# (tests/test_region_overlap.sh). wide_ext has 2 MB spare, so the merge
# depends entirely on how much can move there.
#
# `region_space` (slice J) makes that a manifest tunable. This audit measures
# what the tunable can actually be USED for, because "not named in near_map or
# a layout_group" turns out NOT to be a sufficient condition for movability:
# moving all ten unconstrained regions at once produced a vec3 ADDRESS ERROR
# (odd A0) at vanilla PC 0x015098, frame 1401. Bisected to ONE region.
#
# FROZEN RESULT (14z-78, donovan-m3a) — **EVERY REGION MEASURED HERE MOVES.**
#   anim         runs     — 0x20F00. Was the ONE crasher and M3b's only
#                          remaining blocker; FIXED 14z-78, see below.
#   aux0_4       runs     — 0xE070 of data
#   x06717c      runs     — 0x154 of CODE. **Code DOES run from the raw
#                          extension**, which is what test_crypt_boundary.sh
#                          predicted and this confirms at runtime.
#   hitbox(+proj) runs    — 0x35C2 of data
#
# HOW anim's CRASH WAS RESOLVED (14z-78). It was never a layout constraint.
# donovan.toml's two select-companion thunks baked `207c000dda1e` (movea.l
# #$000DDA1E,A0) — anim's placed address, hand-computed once into authored
# hex, tracking nothing. Move anim and both bodies still aimed at the vacated
# range, where x2b7ef4 had slid in; the resolver read its bytes as 16-bit
# offsets and took a vec3 address error at vanilla PC 0x015098. Measured: site
# 0x845EC executes at f1401 and f1402 on the working build, and the moved build
# faulted on the SECOND. The fix is `region_subst` (placed[anim]+0xA9AE,
# resolved at emit time) and is inert in the default layout — donovan-m3a stays
# bit-exact at 4b7d0dc7. The class is now a BUILD error: see
# tests/test_thunk_addr_literal.sh.
#
# WHY THAT MATTERS MORE THAN IT LOOKS. anim is 371,712 of the 470,200 bytes
# three tenants needed from a 344,640-byte crypt window. With it movable the
# requirement drops to 98,488 (D 67,314 / H 31,174 / P 0) and the overflow is
# gone — so this audit is what says M3b's binding constraint is CLEARED.
#
# SCOPE, STATED PLAINLY: every case below builds DONOVAN (donovan.toml,
# TENANT_CHAR=0x13, replay 12). The arithmetic above is a three-tenant figure
# but the MEASUREMENT is one tenant's regions. Huitzil's and Pyron's anim are
# UNMEASURED here. Static evidence says they should be fine — huitzil.toml
# already spells its anim reference `region_subst` (:1387) and the 14z-78 sweep
# found no baked placed address in either manifest — but that is an argument,
# not a measurement, and this project's rule is that they are different things.
# Extending this audit to all three is NOT just a loop over manifests: a "runs"
# verdict needs a LIVENESS CONTROL proving the tenant's match actually formed,
# or an unformed match reads as a clean pass (the blind-zero trap, paid for
# twice — see NEXT_SESSION "RIG LESSON"). Donovan needs no such control today
# only because his case USED to crash, which proved the path ran.
#
# The expectations stay frozen in both directions: if anim ever crashes here
# again, a placement-dependent reference has been reintroduced somewhere the
# build-time guard cannot see, and that is news worth stopping for.
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/audit_region_movability.sh
# On-demand: one build + one guarded replay per case (~10 min).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"
if [ ! -x "$MAME_BIN" ] || [ ! -f "$WIDE_ZIP" ]; then
    echo "SKIP: need the WIDE MAME binary and a WIDE overlay romset"
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK" build/manifest/_movability.toml' EXIT
POK="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13"
fail=0

case_probe() {  # case_probe <label> <spec> <expect: crash|runs>
    python3 - "$2" <<'PY'
import sys, pathlib
man = pathlib.Path("build/manifest/donovan.toml").read_text()
anchor = 'hole_b_regions = "aux0_4,hitbox"'
# donovan.toml carries the key TWICE — once in [[tenant]] and once in the
# superseded flat [port] below it. normalise_tenants() prefers [[tenant]], so
# inject into the FIRST occurrence only.
n = man.count(anchor)
assert n >= 1, "manifest shape moved; this probe needs updating"
pathlib.Path("build/manifest/_movability.toml").write_text(
    man.replace(anchor, anchor + '\nregion_space = "%s"' % sys.argv[1], 1))
PY
    if ! KEY_SET=vsavj TENANT_MANIFEST=build/manifest/_movability.toml \
         TENANT_CHAR=0x13 WIDE_ROMSET="$WIDE_ZIP" \
         GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
         tools/build_donovan.sh 6 "$WORK/$1" > "$WORK/$1.build" 2>&1; then
        echo "  FAIL: $1 — the BUILD errored, so runtime says nothing"
        tail -5 "$WORK/$1.build"
        fail=1; return
    fi
    POKES="$POK" MAME_ROMPATH="$WORK/$1/rompath;$ROMDIR" \
        tools/run_replay_guarded.sh vsavjw \
        tests/replays/12_donovan_vs_cpu.rpl "$WORK/$1.rl" "$WORK/$1.box" \
        >/dev/null 2>&1 || true
    if grep -qE '^(CRASH|PCWEEDS|SOFTRESET)' "$WORK/$1.rl"; then got=crash;
    else got=runs; fi
    if [ "$got" = "$3" ]; then
        detail=""
        [ "$got" = crash ] && detail="  ($(grep -m1 '^CRASH' "$WORK/$1.rl"))"
        echo "  ok: $1 -> $got$detail"
    else
        echo "  FAIL: $1 -> $got, expected $3"
        # A region that STOPS moving is a regression of the 14z-78 fix: some
        # reference has gone back to being placement-dependent. Start with the
        # build-time guard's blind spot — a raw longword in embedded data, which
        # tests/test_thunk_addr_literal.sh section 3 documents as out of scope —
        # then probe the faulting PC's base register on both layouts and compare.
        [ "$got" = crash ] && echo "        REGRESSION: this region moved as of" \
            "14z-78. Suspect a placement-dependent" && echo "        reference the" \
            "thunk guard cannot see; see tests/test_thunk_addr_literal.sh"
        grep -m1 '^CRASH' "$WORK/$1.rl" 2>/dev/null || true
        fail=1
    fi
}

echo "== can a region live in wide_ext? (frozen 14z-78) =="
case_probe anim     "anim=wide_ext"                          runs
case_probe aux4     "aux0_4=wide_ext"                        runs
case_probe codereg  "x06717c=wide_ext"                       runs
case_probe hitboxes "hitbox=wide_ext,hitbox_proj=wide_ext"   runs

[ "$fail" = 0 ] || { echo "FAIL: region movability audit"; exit 1; }
echo "PASS: code runs from the raw extension, and every region measured here"
echo "      moves — including anim, which was the merge's binding constraint"
echo "      until 14z-78. On that basis three tenants need 98,488 of the"
echo "      344,640-byte crypt window (was 470,200); the overflow is gone."
echo "      MEASURED ON DONOVAN ONLY — H/P anim movability is still inferred"
echo "      from the manifests, not measured (see the header)"
