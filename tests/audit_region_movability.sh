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
# FROZEN RESULT (14z-77, donovan-m3a):
#   anim         CRASHES  — vec3 address error, odd pointer. The animation
#                          region has an undeclared dependency on living in
#                          the crypt window that near_map/layout_group do not
#                          express.
#   aux0_4       runs     — 0xE070 of data
#   x06717c      runs     — 0x154 of CODE. **Code DOES run from the raw
#                          extension**, which is what test_crypt_boundary.sh
#                          predicted and this confirms at runtime.
#   hitbox(+proj) runs    — 0x35C2 of data
#
# WHY THAT MATTERS MORE THAN IT LOOKS. With every movable region relocated,
# three tenants still need 470,200 bytes of the 344,640-byte crypt window —
# an overflow of 125,560 — and `anim` alone is 371,712 of that. So **the merge
# is blocked on anim's movability**, not on anything else measured so far.
#
# The expectations are frozen in both directions: if anim ever stops crashing,
# this audit FAILS and says the blocker is gone. That is the point — a green
# here today and a red here tomorrow are both news.
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
        [ "$3" = crash ] && echo "        anim MOVES NOW — the merge's binding" \
            "constraint is gone; re-run" && echo "        tests/test_region_overlap.sh" \
            "and redo the space arithmetic"
        grep -m1 '^CRASH' "$WORK/$1.rl" 2>/dev/null || true
        fail=1
    fi
}

echo "== can a region live in wide_ext? (frozen 14z-77) =="
case_probe anim     "anim=wide_ext"                          crash
case_probe aux4     "aux0_4=wide_ext"                        runs
case_probe codereg  "x06717c=wide_ext"                       runs
case_probe hitboxes "hitbox=wide_ext,hitbox_proj=wide_ext"   runs

[ "$fail" = 0 ] || { echo "FAIL: region movability audit"; exit 1; }
echo "PASS: code runs from the raw extension; anim does NOT move, and anim is"
echo "      what blocks the merge (371,712 of the 470,200 crypt-window bytes"
echo "      three tenants need, against 344,640 available)"
