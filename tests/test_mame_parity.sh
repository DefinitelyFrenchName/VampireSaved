#!/bin/sh
# test_mame_parity.sh — B5 PREREQUISITE: the pinned MAME source build must be
# indistinguishable from the binary that froze the oracle, BEFORE any profile
# patch is applied to it.
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
#   ROMDIR=... [MAME_SRC_BIN=...] [MAME_REF_BIN=mame] tests/test_mame_parity.sh
set -eu

ROMDIR="${ROMDIR:?set ROMDIR to the reference-set directory}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
# Default: the UNPATCHED source build (WIDE=0 tools/setup_mame.sh), which is
# what this gate is about. The patched build lives in .../mame and is the
# subject of tests/test_mame_wide.sh instead.
SRC_BIN="${MAME_SRC_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"
REF_BIN="${MAME_REF_BIN:-$(command -v mame || true)}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

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
# 5x_vs2_* native ground-truth scripts); everything else runs on vsavj.
for rpl in tests/replays/*.rpl; do
    name="$(basename "$rpl" .rpl)"
    case "$name" in
    *_vsav2|*_vs2_*) echo "$name" >> "$WORK/set_vsav2" ;;
    *)  if [ -f "tests/expected/vsavj/$name.sha1" ]; then
            echo "$name" >> "$WORK/frozen"
        else
            echo "$name" >> "$WORK/set_vsavj"
        fi ;;
    esac
done
touch "$WORK/frozen" "$WORK/set_vsavj" "$WORK/set_vsav2"

echo
echo "== 1. frozen oracle reproduction ($(wc -l < "$WORK/frozen" | tr -d ' ') replays, each run twice) =="
while read -r name; do
    printf '  %-28s ' "$name"
    exp="$(cat "tests/expected/vsavj/$name.sha1")"
    MAME_BIN="$SRC_BIN" tools/run_replay_mame.sh vsavj "tests/replays/$name.rpl" \
        "$WORK/f1_$name.log" "$WORK/sb_f1_$name" >/dev/null 2>&1 \
        || { echo "RUN-FAIL"; fail=1; continue; }
    MAME_BIN="$SRC_BIN" tools/run_replay_mame.sh vsavj "tests/replays/$name.rpl" \
        "$WORK/f2_$name.log" "$WORK/sb_f2_$name" >/dev/null 2>&1 \
        || { echo "RUN-FAIL"; fail=1; continue; }
    if ! cmp -s "$WORK/f1_$name.log" "$WORK/f2_$name.log"; then
        echo "NONDETERMINISTIC"
        diff "$WORK/f1_$name.log" "$WORK/f2_$name.log" | head -3
        keep "nondet_$name" "$WORK/f1_$name.log" "$WORK/f2_$name.log"
        fail=1; continue
    fi
    got="$(shasum "$WORK/f1_$name.log" | cut -d' ' -f1)"
    if [ "$got" = "$exp" ]; then
        echo "ok  $got"
    else
        echo "FAIL expected $exp got $got"
        fail=1
    fi
done < "$WORK/frozen"

# ── A/B sections ────────────────────────────────────────────────────────
ab_section() {   # ab_section <set> <listfile> <label>
    set_name="$1"; listfile="$2"; label="$3"
    n=$(wc -l < "$listfile" | tr -d ' ')
    echo
    echo "== $label ($n replays, no frozen vanilla expectation — direct A/B) =="
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
echo "      oracle log bit-for-bit and is byte-identical to the reference"
echo "      binary on every other replay, on vsavj and vsav2 alike."
echo "      The instrument did not move; B5 may proceed to the profile patch."
