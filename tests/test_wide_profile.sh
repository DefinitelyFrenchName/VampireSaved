#!/bin/sh
# test_wide_profile.sh — CPS-2 WIDE profile gate (Phase B).
#
# WHAT: the CPS-2 WIDE profile is safe on FBNeo: the patched binary runs stock vsavj
#   bit-identically to a pre-patch reference binary (the emulator superset invariant, Rule 1
#   v2), and the WIDE set behaves bit-identically to the stock set on the same binary
#   (inertness) — both on per-frame work-RAM AND framebuffer checksums over the legacy
#   corpus.
# HOW: FBNeo runs of the corpus on the reference and patched binaries and on the stock and
#   WIDE sets; the reference guard refuses a reference that carries the profile; controls
#   point FBNEO_REF at the WIDE binary and stub `strings` to find nothing.
# EXPECTS: both invariants hold on both checksums; the superset leg skips LOUDLY without
#   FBNEO_REF; both controls fail at the guard.
# FOLLOWS: build/manifest/ emu/fbneo-patches/ emu/fbneo/ tests/lib/controls.sh
#   tests/replays/ tools/build_fingerprint.py tools/build_wide_romset.py
#   tools/run_replay_fbneo.sh tools/setup_fbneo.sh
#
# MUST-FIRE: known-bad: contaminated-ref — the reference guard must REFUSE the WIDE binary under test, a reference that carries the profile by construction; in-gate it classifies that binary before any negative on FBNEO_REF is trusted, and the mode points FBNEO_REF at it and must FAIL at the guard (#137)
# MUST-FIRE: shadow-tool: blind-predicate — a `strings` that finds nothing must leave the guard UNPROVEN, so the gate FAILS without trusting any negative on FBNEO_REF; in-gate the stub makes the WIDE binary read as clean, and the mode puts it first on PATH for the run (#137)
#
# Two invariants, both required by Rule 1 v2 (docs/project/cps2_wide.md):
#
#  1. EMULATOR SUPERSET INVARIANT — the patched FBNeo binary, running the
#     STOCK unmodified vsavj set, must behave bit-identically to a
#     pre-patch binary. This is the emulator-side twin of the ROM-side
#     superset invariant: it proves our driver additions cannot perturb
#     vanilla content, and by construction cannot perturb other games.
#     Needs a reference binary (FBNEO_REF); skipped with a loud notice if
#     one is not supplied, because an unrun invariant must never look green.
#
#  2. PROFILE INERTNESS — the WIDE set (grown regions, zero-filled new
#     members, identical program/gfx content) must behave bit-identically
#     to the stock set on the same binary. Any difference means a grown
#     region is NOT inert and the profile is not safe to build content on.
#
# Both compare, over the legacy corpus, BOTH:
#   * the per-frame work-RAM checksum (the basis the ROM-side gates use), and
#   * the per-frame FRAMEBUFFER checksum (FBNEO_HVIDEO).
# The framebuffer half is not optional garnish: the RAM checksum is BLIND to
# the entire video path — the harness historically ran with pBurnDraw=NULL —
# so a rendering change such as the WIDE 19-bit sprite tile address produces
# byte-identical RAM logs whether it works or is catastrophically broken.
#
# Usage:
#   ROMDIR=... [FBNEO_REF=/path/to/pre-wide/fbneo] tests/test_wide_profile.sh
#   FBNEO_REF defaults to ~/.cache/vampire-saved/fbneo_ref and is REFUSED
#   when it is older than emu/fbneo-patches/0001-*.patch.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   WIDE profile gate: emulator superset invariant + inertness + the B4 canary
#   (needs FBNEO_REF)
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
WIDE_ROMPATH="${WIDE_ROMPATH:-$REPO/build/wide0/rompath}"
[ -f "$WIDE_ROMPATH/vsavjw.zip" ] || {
    echo "no WIDE romset at $WIDE_ROMPATH (build it: tools/build_wide_romset.py)"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

CORPUS="${*:-01_attract_long 02_demitri_vs_cpu 03_two_player_vs 04_select_fuzz \
05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join 09_mirror_pick \
10_midattract_start 29_felicia_walljump 30_demitri_throw}"

fail=0

echo "== 0. build identity (the dispatch fingerprint cannot see this) =="
python3 tools/build_fingerprint.py "$WIDE_ROMPATH;$ROMDIR" --set vsavjw --full \
    | sed 's/^/  WIDE  /'
python3 tools/build_fingerprint.py "$ROMDIR" --set vsavj --full \
    | sed 's/^/  stock /'

echo "== 1. emulator superset invariant (stock vsavj: reference binary vs WIDE binary) =="
# THE REFERENCE BINARY HAS A CANONICAL HOME AND A SHELF LIFE (added 14z-128).
# It had neither: the invariant that justifies modifying an emulator at all
# could only be run by remembering an env var and a path, and this gate's own
# premise — "the reference binary MUST differ from the build under test by ONLY
# patch 0002; rebuild it whenever the harness changes" (HANDOFF, CPS-2 WIDE) —
# was documented and unenforced. Measured 14z-128 on this machine:
# ~/.cache/vampire-saved/fbneo_ref was built 2026-08-14 while patch 0001 last
# changed 2026-08-17, so the only reference present was THREE DAYS STALE and
# nothing said so.
FBNEO_REF="${FBNEO_REF:-$HOME/.cache/vampire-saved/fbneo_ref}"
_HARNESS_PATCH="$REPO/emu/fbneo-patches/0001-vampire-saved-harness.patch"
if [ -x "$FBNEO_REF" ] && [ -f "$_HARNESS_PATCH" ] \
   && [ "$_HARNESS_PATCH" -nt "$FBNEO_REF" ]; then
    echo "  FAIL: the reference binary is OLDER than the harness patch."
    echo "        $FBNEO_REF"
    echo "        vs $_HARNESS_PATCH"
    echo "        A reference built with a different harness makes this"
    echo "        comparison measure HARNESS deltas as PROFILE deltas."
    echo "        Rebuild BOTH, in this order:"
    echo "          WIDE=0 tools/setup_fbneo.sh && cp emu/fbneo/fbneo \\"
    echo "              \"$HOME/.cache/vampire-saved/fbneo_ref\""
    echo "          tools/setup_fbneo.sh"
    echo "        (mtime is a WEAK signal — a fresh checkout resets it — so"
    echo "         this refuses conservatively: on this invariant, a false"
    echo "         alarm costs a rebuild and a false pass costs the rule.)"
    fail=1
    FBNEO_REF=""
fi
# THE GUARD'S OWN PREDICATE IS PROVEN BEFORE ITS NEGATIVE CLEARS A REFERENCE
# (#137, maintainer-ruled 2026-09-14 — the residual #63 left open on
# 2026-08-16). The guard below only ever ACTS on a positive, so a predicate
# that cannot see the profile at all would report a contaminated reference as
# CLEAN, and section 1 would compare WIDE against WIDE and pass: `strings`
# missing or failing (its stderr goes to /dev/null and sh has no pipefail), or
# a future profile version renaming the driver string — the POSITIVE call sites
# (tools/setup_fbneo.sh, tools/run_wide.sh) fail loudly on a rename, and this
# negative one never would. So ONE function classifies both binaries, and the
# WIDE binary under test, a contaminated reference by construction, must be
# refused first. Measured when added: 0 matches in the 2026-09-03 reference, 2
# in emu/fbneo/fbneo, 0.11 s. (`WIDE=0 tools/setup_fbneo.sh` keeps its own
# source-level check, `Cps2Wide` in cps.h, so a reference the tool builds is
# defended independently; this covers one that arrives any other way.)
WIDE_BIN="${FBNEO_BIN:-$REPO/emu/fbneo/fbneo}"
carries_profile() {  # carries_profile <binary> — the driver title string is compiled in
    strings -a "$1" 2>/dev/null | grep -q "CPS-2 WIDE v1"
}
# A `strings` that finds nothing is the blind predicate itself: the in-gate
# control shows carries_profile reads the WIDE binary as clean under it, and the
# mode runs the proof below with it first on PATH, where the gate must FAIL.
# The PATH change stays inside a subshell ([VSP-110]: `VAR=x func` persists).
mkdir -p "$WORK/blind"
printf '#!/bin/sh\nexit 127\n' > "$WORK/blind/strings"
chmod +x "$WORK/blind/strings"
if ( PATH="$WORK/blind:$PATH"; carries_profile "$WIDE_BIN" ); then
    vs_ctl_dead blind-predicate "a strings that finds nothing still reported the profile — the stub is not the one being run" || true
    fail=1
else
    vs_ctl_fired blind-predicate "with a strings that finds nothing, carries_profile reads the WIDE binary under test as clean — the blindness the proof below refuses"
fi
vs_ctl_is blind-predicate && PATH="$WORK/blind:$PATH"
_guard_proven=0
if [ -x "$WIDE_BIN" ] && carries_profile "$WIDE_BIN"; then
    _guard_proven=1
    vs_ctl_fired contaminated-ref "the reference guard refuses the WIDE binary under test ($WIDE_BIN), so its negative on FBNEO_REF is evidence"
    echo "  ok: the reference guard sees the profile in the WIDE binary under test"
else
    vs_ctl_dead contaminated-ref "the reference guard does not see the profile in the WIDE binary under test ($WIDE_BIN) — it would clear any reference" || true
    echo "  FAIL: the profile check cannot see the CPS-2 WIDE profile in the WIDE"
    echo "        binary under test ($WIDE_BIN), so it cannot tell a contaminated"
    echo "        reference from a clean one. Section 1 is NOT run on an unproven guard."
    fail=1
    vs_ctl_is blind-predicate && { echo "FAIL: CPS-2 WIDE profile gate"; exit 1; }
fi
# THE MODE: the real reference is replaced by the WIDE binary under test.
vs_ctl_is contaminated-ref && FBNEO_REF="$WIDE_BIN"
if [ "$_guard_proven" != 1 ]; then
    :   # reported above; fail is already set
elif [ -n "${FBNEO_REF:-}" ] && [ -x "${FBNEO_REF}" ] && carries_profile "${FBNEO_REF}"; then
    # Paid for 14z-59e: `WIDE=0 tools/setup_fbneo.sh` used to only SKIP
    # applying the profile patch, never revert it, so a reference built from
    # a tree that already carried it came out WITH the profile. Section 1
    # then compared WIDE against WIDE and passed trivially — the invariant
    # that justifies allowing emulator changes at all was measuring nothing.
    # The driver title string is compiled in, so this catches it statically.
    echo "  FAIL: FBNEO_REF carries the CPS-2 WIDE profile — it is NOT a"
    echo "        pre-patch reference, and this comparison would be vacuous."
    echo "        Rebuild it: WIDE=0 tools/setup_fbneo.sh (now reverts properly)"
    fail=1
    vs_ctl_is contaminated-ref && { echo "FAIL: CPS-2 WIDE profile gate"; exit 1; }
elif [ -n "${FBNEO_REF:-}" ] && [ -x "${FBNEO_REF}" ]; then
    for rp in $CORPUS; do
        FBNEO_HVIDEO="$WORK/ref_$rp.vid" FBNEO_BIN="$FBNEO_REF" tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/ref_$rp.log" "$WORK/sb_ref_$rp" >/dev/null 2>&1
        FBNEO_HVIDEO="$WORK/new_$rp.vid" tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/new_$rp.log" "$WORK/sb_new_$rp" >/dev/null 2>&1
        if cmp -s "$WORK/ref_$rp.log" "$WORK/new_$rp.log" \
           && cmp -s "$WORK/ref_$rp.vid" "$WORK/new_$rp.vid"; then
            echo "  ok: $rp bit-identical (RAM + framebuffer)"
        else
            echo "  FAIL: $rp — the patched binary changed STOCK vsavj behaviour"
            cmp -s "$WORK/ref_$rp.log" "$WORK/new_$rp.log" || echo "    (work RAM differs)"
            cmp -s "$WORK/ref_$rp.vid" "$WORK/new_$rp.vid" || echo "    (framebuffer differs)"
            fail=1
        fi
    done
else
    echo "  SKIPPED: no usable pre-WIDE fbneo binary."
    echo "    Build one:  WIDE=0 tools/setup_fbneo.sh && cp emu/fbneo/fbneo \\"
    echo "                    \"$HOME/.cache/vampire-saved/fbneo_ref\""
    echo "                then tools/setup_fbneo.sh to restore the WIDE binary."
    echo "    (that path is the default; FBNEO_REF overrides it)"
    echo "  NOTE: this invariant is the whole basis for allowing emulator"
    echo "        changes at all (Rule 1 v2 clause 3) — a build that has not"
    echo "        run it is NOT validated, regardless of section 2 below."
    fail_skipped=1
fi

echo "== 2. profile inertness (WIDE set vs stock set, same binary) =="
for rp in $CORPUS; do
    FBNEO_HVIDEO="$WORK/stock_$rp.vid" tools/run_replay_fbneo.sh vsavj \
        "$REPO/tests/replays/$rp.rpl" "$WORK/stock_$rp.log" "$WORK/sb_s_$rp" >/dev/null 2>&1
    FBNEO_HVIDEO="$WORK/wide_$rp.vid" FBNEO_ROMPATH="$WIDE_ROMPATH" tools/run_replay_fbneo.sh vsavjw \
        "$REPO/tests/replays/$rp.rpl" "$WORK/wide_$rp.log" "$WORK/sb_w_$rp" >/dev/null 2>&1
    if cmp -s "$WORK/stock_$rp.log" "$WORK/wide_$rp.log" \
       && cmp -s "$WORK/stock_$rp.vid" "$WORK/wide_$rp.vid"; then
        echo "  ok: $rp bit-identical on the grown regions (RAM + framebuffer)"
    else
        echo "  FAIL: $rp — a grown region is NOT inert"
        cmp -s "$WORK/stock_$rp.log" "$WORK/wide_$rp.log" || echo "    (work RAM differs)"
        cmp -s "$WORK/stock_$rp.vid" "$WORK/wide_$rp.vid" || echo "    (framebuffer differs)"
        fail=1
    fi
done

[ "$fail" = 0 ] || { echo "FAIL: CPS-2 WIDE profile gate"; exit 1; }
if [ -n "${fail_skipped:-}" ]; then
    echo "PARTIAL: profile inert, but the emulator superset invariant was NOT run"
    exit 2
fi
# ── 3. B4 CANARY: are the new gfx banks actually USABLE? ────────────────
# Inertness (sections 1-2) only proves the profile does no harm. This
# proves the 19-bit tile address REACHES the appended banks: with
# CPS2_WIDE_CANARY=1 the emulator relocates bank-2/3 sprites into WIDE
# banks 4/5 at draw time, and the romset must carry group C as a byte copy
# of group B (build with --gfx-copy-group-b). Stock ROM both sides, so RAM
# is identical by construction and only pixels can move.
#
# That copy shape must NEVER ship: it carries group B's CRCs, and both
# emulators resolve a ROM entry by hash before name, so in a set whose
# group B is PATCHED the loader serves pristine tiles for it (14z-60z —
# how the WIDE build rendered Donovan with vanilla art). The canary romset
# therefore lives in its own directory; the shippable overlay is zero-filled.
CANARY_ROMPATH="${CANARY_ROMPATH:-$REPO/build/wide_canary/rompath}"
if python3 - "$CANARY_ROMPATH" <<'PYEOF'
import sys, zipfile, hashlib, os
z = zipfile.ZipFile(os.path.join(sys.argv[1], "vsavjw.zip"))
p = zipfile.ZipFile(os.path.join(os.environ["ROMDIR"], "vsav.zip"))
ok = all(hashlib.sha1(z.read(c)).digest() == hashlib.sha1(p.read(b)).digest()
         for c, b in zip(("vsw.31m","vsw.33m","vsw.35m","vsw.37m"),
                         ("vm3.14m","vm3.16m","vm3.18m","vm3.20m"))
         if c in z.namelist())
sys.exit(0 if ok and "vsw.31m" in z.namelist() else 1)
PYEOF
then
    echo "== 3. B4 canary: sprites served from the appended gfx banks =="
    for rp in $CORPUS; do
        FBNEO_HVIDEO="$WORK/cs_$rp.vid" tools/run_replay_fbneo.sh vsavj \
            "$REPO/tests/replays/$rp.rpl" "$WORK/cs_$rp.log" "$WORK/csb_$rp" >/dev/null 2>&1
        CPS2_WIDE_CANARY=1 FBNEO_HVIDEO="$WORK/cw_$rp.vid" FBNEO_ROMPATH="$CANARY_ROMPATH" \
            tools/run_replay_fbneo.sh vsavjw \
            "$REPO/tests/replays/$rp.rpl" "$WORK/cw_$rp.log" "$WORK/cwb_$rp" >/dev/null 2>&1
        if cmp -s "$WORK/cs_$rp.log" "$WORK/cw_$rp.log" \
           && cmp -s "$WORK/cs_$rp.vid" "$WORK/cw_$rp.vid"; then
            echo "  ok: $rp identical with sprites fetched from banks 4/5"
        else
            echo "  FAIL: $rp — the appended banks do not render correctly"
            fail=1
        fi
    done
else
    echo "== 3. B4 canary: SKIPPED (no canary romset at $CANARY_ROMPATH;"
    echo "     build it THERE — never over the shippable overlay — with"
    echo "     tools/build_wide_romset.py \"\$ROMDIR\" build/wide_canary/rompath \\"
    echo "         --qsound 2 --gfx 4 --prg 4 --gfx-copy-group-b) =="
fi

[ "$fail" = 0 ] || { echo "FAIL: CPS-2 WIDE profile gate"; exit 1; }
echo "PASS: CPS-2 WIDE profile gate (emulator superset invariant + inertness,"
echo "      work RAM AND framebuffer, over $(echo $CORPUS | wc -w | tr -d ' ') replays)"
echo "      plus the B4 canary: the 19-bit path REACHES the appended banks.)"
