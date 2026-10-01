#!/bin/sh
# test_mame_parity.sh — B5 PREREQUISITE: the pinned MAME source build must be
# indistinguishable from the binary that froze the oracle, BEFORE any profile
# patch is applied to it.
#
# WHAT: the pinned MAME source build is indistinguishable from the binary that froze the
#   oracle, BEFORE any profile patch — every frozen vsavj expectation reproduced bit-for-bit
#   (twice, so nondeterminism fails too), every replay of the frozen reference table
#   reproduced the same way, and any replay frozen in neither A/B-identical between the
#   two binaries.
# HOW: section 1 runs every replay with a frozen .sha1 twice on the source build; section 1b
#   runs every row of tests/expected/mame_parity_ab.tsv (the reference binary's own logs,
#   frozen) twice on the source build; sections 2 and 3 run the vsavj and vsav2 replays
#   frozen in neither on both binaries and compare directly (skipped LOUDLY without the
#   reference binary — with every replay frozen, nothing is left to skip).
# EXPECTS: every frozen log reproduced, every A/B identical; a red means the instrument
#   moved and every MAME finding since is in question.
# FOLLOWS: emu/mame-patches/ tests/expected/vsavj/ tests/expected/mame_parity_ab.tsv
#   tests/lib/controls.sh tests/lua/replay.lua tests/replays/ tools/run_mame.sh tools/run_replay_mame.sh
#   tools/setup_mame.sh
# MUST-FIRE: perturbed-copy: wrong-hash — the first frozen reference row's hash with one hex digit changed must FAIL the comparison its real log passed, so section 1b's verdict can refuse a log (in-gate: the perturbed hash against the real log must mismatch; mode: every row of the table is perturbed and the gate FAILs)
#
# THE FROZEN REFERENCE TABLE (14z-187b, 2026-10-01; the maintainer: "option A and pin mame"):
#   sections 2/3 need the reference binary — Homebrew MAME 0.288 on macOS — which no
#   other OS has, so on WSL2/Linux they could only SKIP and the gate could never PASS
#   there (docs/project/WSL2_SETUP.md §7, measured on ERIS: 24/24 frozen, 48 + 16 skipped).
#   tests/expected/mame_parity_ab.tsv freezes the REFERENCE binary's log of each such
#   replay (`<replay> <set> <sha1>`), made by FREEZE=1 on the Mac: the reference run twice
#   and the source build once, all three equal, or nothing is frozen. Any host then
#   reproduces them with no reference binary, and a Homebrew upgrade cannot move them.
#   A table row whose replay is gone, or whose set disagrees with the classification
#   below, FAILS (rot). A replay added later and frozen nowhere falls to sections 2/3.
#
# Why this gate exists, and why it comes first:
#
#   Every MAME-side expectation this project owns was frozen against the
#   Homebrew MAME 0.288 binary. B5 replaces that binary with a source build
#   from the pinned submodule — different compiler, different flags, and a
#   SOURCES-filtered driver set. That is a change of INSTRUMENT, not of
#   subject. If the instrument moved, every MAME finding since session 1 is
#   in question and any WIDE result measured on it means nothing.
#
#   So: prove the UNPATCHED source build is bit-for-bit indistinguishable
#   from the reference, and only then let the profile patch near it. Same
#   discipline as FBNEO_REF in tests/test_wide_profile.sh — a drifting
#   reference is worse than no reference (session 14z-55 paid for that once).
#
# Three sections, because the frozen corpus alone is not full coverage:
#
#   1. FROZEN REPRODUCTION (authoritative) — every replay carrying a frozen
#      .sha1 in tests/expected/vsavj/. Run twice: nondeterminism fails the
#      same as divergence.
#   2. A/B EXTENSION, vsavj — the vsavj-runnable replays that have no frozen
#      vanilla expectation (they were authored later, against Donovan
#      builds). Nothing to reproduce, so compare the two binaries directly.
#   3. A/B EXTENSION, vsav2 — the vsav2-target replays. The oracle gates
#      (test_m2a_stage4_oracle.sh) run on vsav2, so parity there is part of
#      "MAME is still a trustworthy oracle", not an extra.
#
# Sections 2/3 need the reference binary; they skip LOUDLY without it,
# because an unrun check must never read as green.
#
# Usage:
#   ROMDIR=... [MAME_SRC_BIN=...] [MAME_REF_BIN=mame] [PARITY_JOBS=1] tests/test_mame_parity.sh
#   ROMDIR=... FREEZE=1 [PARITY_JOBS=6] tests/test_mame_parity.sh   (needs the reference)
#   PARITY_JOBS runs sections 1/1b and FREEZE N replays at a time (default 1, serial);
#   ~16 s per run serial — 24 x 2 runs took 15 min 50 s on ERIS (WSL2, 2026-10-01).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   B5 PREREQUISITE: the pinned MAME source build reproduces every frozen
#   oracle log bit-for-bit (refuses to run on a WIDE-patched binary)
set -eu

ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
# Default: the UNPATCHED source build (WIDE=0 tools/setup_mame.sh), which is
# what this gate is about. The patched build lives in .../mame and is the
# subject of tests/test_mame_wide.sh instead.
SRC_BIN="${MAME_SRC_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
REF_BIN="${MAME_REF_BIN:-$(command -v mame || true)}"
AB_TABLE="$REPO/tests/expected/mame_parity_ab.tsv"
PARITY_JOBS="${PARITY_JOBS:-1}"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# run_batch <jobs> — each line `<set> <replay> <tag> <bin>` runs the replay on
# <bin> into $WORK/<tag>_<replay>.log, PARITY_JOBS at a time; a failed run
# leaves $WORK/<tag>_<replay>.runfail instead of a verdict.
run_batch() {
    [ -s "$1" ] || return 0
    sed "s|\$| $WORK|" "$1" | xargs -P "$PARITY_JOBS" -L 1 sh -c '
        MAME_BIN="$3" tools/run_replay_mame.sh "$0" "tests/replays/$1.rpl" \
            "$4/$2_$1.log" "$4/sb_$2_$1" >/dev/null 2>&1 || touch "$4/$2_$1.runfail"
        rm -rf "$4/sb_$2_$1"'
}
# twice_verdict <replay> <tag> <expected sha1> — the two runs <tag>1/<tag>2
# must be identical and hash to <expected>.
twice_verdict() {
    printf '  %-28s ' "$1"
    if [ -f "$WORK/${2}1_$1.runfail" ] || [ -f "$WORK/${2}2_$1.runfail" ]; then
        echo "RUN-FAIL"; fail=1; return
    fi
    if ! cmp -s "$WORK/${2}1_$1.log" "$WORK/${2}2_$1.log"; then
        echo "NONDETERMINISTIC"
        diff "$WORK/${2}1_$1.log" "$WORK/${2}2_$1.log" | head -3
        keep "nondet_$1" "$WORK/${2}1_$1.log" "$WORK/${2}2_$1.log"
        fail=1; return
    fi
    got="$(shasum "$WORK/${2}1_$1.log" | cut -d' ' -f1)"
    if [ "$got" = "$3" ]; then
        echo "ok  $got"
    else
        echo "FAIL expected $3 got $got"
        fail=1
    fi
}
perturb() { case "$1" in 0*) echo "1${1#?}" ;; *) echo "0${1#?}" ;; esac; }

# Divergences here are rare and have so far refused to reproduce on demand,
# so the ONE artifact that matters is the divergent pair itself. Keep it:
# a gate that deletes its own evidence makes the next occurrence cost as
# much as the first.
ARTIFACTS="${MAME_PARITY_ARTIFACTS:-$REPO/build/gate_failures/mame_parity}"
keep() {   # keep <label> <fileA> <fileB>
    mkdir -p "$ARTIFACTS"
    cp "$2" "$ARTIFACTS/$1.a.log" 2>/dev/null || true
    cp "$3" "$ARTIFACTS/$1.b.log" 2>/dev/null || true
    diff "$2" "$3" > "$ARTIFACTS/$1.diff" 2>/dev/null || true
    echo "    artifacts: $ARTIFACTS/$1.{a,b}.log + .diff"
}

fail=0
skipped=""

echo "== 0. instrument identity =="
[ -x "$SRC_BIN" ] || {
    echo "  no source-built MAME at $SRC_BIN"
    echo "  build it: tools/setup_mame.sh   (WIDE=0 for the unpatched binary)"
    exit 1; }
echo "  under test : $SRC_BIN"
echo "               sha1 $(shasum "$SRC_BIN" | cut -d' ' -f1)"
echo "               $("$SRC_BIN" -version 2>/dev/null | head -1)"
if [ -n "$REF_BIN" ]; then
    echo "  reference  : $REF_BIN"
    echo "               sha1 $(shasum "$REF_BIN" | cut -d' ' -f1)"
    echo "               $("$REF_BIN" -version 2>/dev/null | head -1)"
else
    echo "  reference  : NONE on PATH"
fi

# The parity statement is only meaningful for an UNPATCHED binary. A WIDE
# build knows the vsavjw driver; calling that "parity" would be a lie.
if "$SRC_BIN" -listfull vsavjw >/dev/null 2>&1; then
    echo "  FAIL: this binary carries the CPS-2 WIDE profile (knows vsavjw)."
    echo "        Parity must be proven on the UNPATCHED source build:"
    echo "        WIDE=0 tools/setup_mame.sh"
    exit 1
fi
echo "  unpatched  : confirmed (driver vsavjw not present)"

# ── replay classification ───────────────────────────────────────────────
# A replay is a vsav2 target if its name says so (the *_vsav2 pairs and the
# 5x_vs2_* native ground-truth scripts); everything else runs on vsavj. A
# vsavj replay with a frozen .sha1 is section 1's; a replay with a row in the
# frozen reference table is section 1b's; anything else is sections 2/3's.
if [ -f "$AB_TABLE" ]; then grep -v '^#' "$AB_TABLE" | awk 'NF' > "$WORK/ab_rows"
elif [ "${FREEZE:-0}" = 1 ]; then : > "$WORK/ab_rows"
else echo "FAIL: no frozen reference table at $AB_TABLE (FREEZE=1 on the reference host makes it)"; exit 1; fi
for rpl in tests/replays/*.rpl; do
    name="$(basename "$rpl" .rpl)"
    case "$name" in
    *_vsav2|*_vs2_*) s=vsav2 ;;
    *) s=vsavj ;;
    esac
    if [ "$s" = vsavj ] && [ -f "tests/expected/vsavj/$name.sha1" ]; then
        echo "$name" >> "$WORK/frozen"
    elif row="$(awk -F'\t' -v n="$name" '$1 == n' "$WORK/ab_rows")" && [ -n "$row" ]; then
        tset="$(printf '%s\n' "$row" | cut -f2)"
        if [ "$tset" != "$s" ]; then
            echo "FAIL: $AB_TABLE row $name says set $tset, the classification says $s"; fail=1
        fi
        printf '%s\n' "$row" >> "$WORK/abfrozen"
    else
        echo "$name" >> "$WORK/set_$s"
    fi
done
touch "$WORK/frozen" "$WORK/abfrozen" "$WORK/set_vsavj" "$WORK/set_vsav2"
# rot: a row whose replay is gone asserts nothing and must not read as green
while IFS="$(printf '\t')" read -r name _ _; do
    [ -f "tests/replays/$name.rpl" ] || { echo "FAIL: $AB_TABLE row $name names no tests/replays/$name.rpl (stale row)"; fail=1; }
done < "$WORK/ab_rows"

# ── FREEZE=1: (re)make the reference table from the REFERENCE binary ───────
if [ "${FREEZE:-0}" = 1 ] && [ -z "$MODE" ]; then
    [ -n "$REF_BIN" ] && [ -x "$REF_BIN" ] || { echo "FAIL: FREEZE needs the reference binary (MAME_REF_BIN, or mame on PATH)"; exit 1; }
    [ "$fail" = 0 ] || { echo "FAIL: not freezing over a failed classification"; exit 1; }
    { cut -f1,2 "$WORK/abfrozen" | awk -F'\t' '{print $2, $1}'
      sed 's/^/vsavj /' "$WORK/set_vsavj"; sed 's/^/vsav2 /' "$WORK/set_vsav2"; } | sort -k2 > "$WORK/fz_list"
    echo; echo "== FREEZE: $(wc -l < "$WORK/fz_list" | tr -d ' ') replays — the reference twice, the source build once =="
    while read -r s n; do
        echo "$s $n z1 $REF_BIN"; echo "$s $n z2 $REF_BIN"; echo "$s $n zs $SRC_BIN"
    done < "$WORK/fz_list" > "$WORK/fz_jobs"
    run_batch "$WORK/fz_jobs"
    # three_agree <ref log 1> <ref log 2> <source log> — the ONE agreement test a row rests on
    three_agree() {
        [ -s "$1" ] && [ -s "$2" ] && [ -s "$3" ] || { echo "MISSING LOG"; return 1; }
        cmp -s "$1" "$2" || { echo "REFERENCE NONDETERMINISTIC"; return 1; }
        cmp -s "$1" "$3" || { echo "FAIL — source build diverges from the reference"; return 1; }
        echo "agree"
    }
    : > "$WORK/fz_rows"
    while read -r s n; do
        printf '  %-28s ' "$n"
        if [ -f "$WORK/z1_$n.runfail" ] || [ -f "$WORK/z2_$n.runfail" ] || [ -f "$WORK/zs_$n.runfail" ]; then
            echo "RUN-FAIL"; fail=1; continue; fi
        if ! three_agree "$WORK/z1_$n.log" "$WORK/z2_$n.log" "$WORK/zs_$n.log"; then
            keep "ab_$n" "$WORK/z1_$n.log" "$WORK/zs_$n.log"; fail=1; continue; fi
        h="$(shasum "$WORK/z1_$n.log" | cut -d' ' -f1)"; echo "       $h"
        printf '%s\t%s\t%s\n' "$n" "$s" "$h" >> "$WORK/fz_rows"
    done < "$WORK/fz_list"
    [ "$fail" = 0 ] || { echo "FAIL: nothing frozen — every replay must agree on all three runs"; exit 1; }
    # the agreement test must be able to refuse: a real source log with one line
    # appended (and, second, the two reference logs made to differ) must not agree
    read -r _ cn < "$WORK/fz_list"
    cp "$WORK/zs_$cn.log" "$WORK/ctl_src.log"; echo "planted-line" >> "$WORK/ctl_src.log"
    cp "$WORK/z2_$cn.log" "$WORK/ctl_ref2.log"; echo "planted-line" >> "$WORK/ctl_ref2.log"
    if three_agree "$WORK/z1_$cn.log" "$WORK/z2_$cn.log" "$WORK/ctl_src.log" >/dev/null \
       || three_agree "$WORK/z1_$cn.log" "$WORK/ctl_ref2.log" "$WORK/zs_$cn.log" >/dev/null; then
        echo "FAIL: the agreement test accepted a perturbed log of $cn — nothing frozen"; exit 1
    fi
    echo "  freeze self-check: $cn's source log and second reference log, each with one line appended, are refused"
    { echo "# tests/expected/mame_parity_ab.tsv — the REFERENCE binary's log of every replay that has no frozen"
      echo "# tests/expected/vsavj/<name>.sha1: <replay> <set> <sha1 of the checksum log>. Read by tests/test_mame_parity.sh"
      echo "# section 1b. Evidence class: in-emulator, MAME. Frozen with FREEZE=1 by that gate: each replay run TWICE on"
      echo "# the reference ($("$REF_BIN" -version 2>/dev/null | head -1), sha1 $(shasum "$REF_BIN" | cut -c1-12)) and ONCE on the"
      echo "# unpatched source build (sha1 $(shasum "$SRC_BIN" | cut -c1-12)), all three logs equal, at revision $(git rev-parse --short=8 HEAD)."
      echo "#--"
      cat "$WORK/fz_rows"; } > "$AB_TABLE"
    echo; echo "FROZE $(wc -l < "$WORK/fz_rows" | tr -d ' ') rows into $AB_TABLE — VERIFY by re-running without FREEZE"
    exit 0
fi

# ── 1 and 1b: reproduction of the frozen logs on the source build ──────────
while read -r n; do echo "vsavj $n f1 $SRC_BIN"; echo "vsavj $n f2 $SRC_BIN"; done < "$WORK/frozen" > "$WORK/jobs_1"
while IFS="$(printf '\t')" read -r n s _; do echo "$s $n a1 $SRC_BIN"; echo "$s $n a2 $SRC_BIN"; done < "$WORK/abfrozen" > "$WORK/jobs_1b"
cat "$WORK/jobs_1" "$WORK/jobs_1b" > "$WORK/jobs_all"
run_batch "$WORK/jobs_all"

echo
echo "== 1. frozen oracle reproduction ($(wc -l < "$WORK/frozen" | tr -d ' ') replays, each run twice) =="
while read -r name; do
    twice_verdict "$name" f "$(cat "tests/expected/vsavj/$name.sha1")"
done < "$WORK/frozen"

echo
echo "== 1b. frozen reference reproduction ($(wc -l < "$WORK/abfrozen" | tr -d ' ') replays, each run twice) =="
while IFS="$(printf '\t')" read -r name s exp; do
    vs_ctl_is wrong-hash && exp="$(perturb "$exp")"
    twice_verdict "$name" a "$exp"
done < "$WORK/abfrozen"
if [ -z "$MODE" ] && [ -s "$WORK/abfrozen" ]; then
    IFS="$(printf '\t')" read -r cn _ cexp < "$WORK/abfrozen"
    cgot="$(shasum "$WORK/a1_$cn.log" 2>/dev/null | cut -d' ' -f1)"
    if [ "$cgot" = "$cexp" ] && [ "$cgot" != "$(perturb "$cexp")" ]; then
        vs_ctl_fired wrong-hash "$cn's real log ($cgot) passes against its frozen hash and fails against the hash with one digit changed ($(perturb "$cexp"))"
    else
        vs_ctl_dead wrong-hash "$cn: the real log did not pass, or the perturbed hash still matched" || fail=1
    fi
fi

# ── A/B sections ────────────────────────────────────────────────────────
ab_section() {   # ab_section <set> <listfile> <label>
    set_name="$1"; listfile="$2"; label="$3"
    n=$(wc -l < "$listfile" | tr -d ' ')
    echo
    echo "== $label ($n replays, frozen nowhere — direct A/B) =="
    [ "$n" != 0 ] || { echo "  (none — every replay is frozen in section 1 or 1b)"; return; }
    if [ -z "$REF_BIN" ] || [ ! -x "$REF_BIN" ]; then
        echo "  SKIPPED: no reference binary (set MAME_REF_BIN, or put mame on PATH)."
        echo "  NOTE: these replays have nothing frozen to reproduce, so the A/B"
        echo "        against the reference IS their parity evidence. Unrun."
        skipped="$skipped $label"
        return
    fi
    while read -r name; do
        printf '  %-28s ' "$name"
        MAME_BIN="$REF_BIN" tools/run_replay_mame.sh "$set_name" "tests/replays/$name.rpl" \
            "$WORK/r_$name.log" "$WORK/sb_r_$name" >/dev/null 2>&1 \
            || { echo "RUN-FAIL (reference)"; fail=1; continue; }
        MAME_BIN="$SRC_BIN" tools/run_replay_mame.sh "$set_name" "tests/replays/$name.rpl" \
            "$WORK/s_$name.log" "$WORK/sb_s_$name" >/dev/null 2>&1 \
            || { echo "RUN-FAIL (source build)"; fail=1; continue; }
        if cmp -s "$WORK/r_$name.log" "$WORK/s_$name.log"; then
            echo "ok  identical"
        else
            echo "FAIL — source build diverges from the reference"
            diff "$WORK/r_$name.log" "$WORK/s_$name.log" | head -3
            keep "ab_$name" "$WORK/r_$name.log" "$WORK/s_$name.log"
            fail=1
        fi
    done < "$listfile"
}

ab_section vsavj "$WORK/set_vsavj" "2. A/B extension on vsavj"
ab_section vsav2 "$WORK/set_vsav2" "3. A/B extension on vsav2"

echo
if [ "$fail" != 0 ]; then
    echo "FAIL: the source build is NOT equivalent to the reference."
    echo "      Do not proceed to the WIDE patch. Either the build differs in a"
    echo "      way that touches emulation, or an expectation is stale —"
    echo "      root-cause before anything else (CLAUDE.md rule 6)."
    exit 1
fi
if [ -n "$skipped" ]; then
    echo "PARTIAL: frozen reproduction green, but these were NOT run:$skipped"
    exit 2
fi
echo "PASS: MAME parity. The pinned source build reproduces every frozen"
echo "      oracle log and every frozen reference log bit-for-bit, and is"
echo "      byte-identical to the reference binary on any replay frozen in"
echo "      neither, on vsavj and vsav2 alike."
echo "      The instrument did not move; B5 may proceed to the profile patch."
