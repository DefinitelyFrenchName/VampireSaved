#!/bin/sh
# test_list_type_census.sh — the ONE-SOURCE-BANK re-check, per tenant (14z-74).
#
# WHY IT EXISTS. `build/manifest/gfx_layout3.toml` asserts that a tenant's art
# is ONE contiguous band in ONE source bank, so a delta-0 placement into WIDE
# group C is complete. Huitzil's beam broke that: a **list type 4** composes its
# OWN bank word (`ori.w #$2000` = bank 1) instead of taking the object's, so its
# art cannot reach group C through the record path — it needs a ported handler
# plus a `--strip-tiles` copy (14z-71, three sessions).
# `docs/project/porting_sprite_lists.md` §4 therefore says: RE-CHECK THIS FOR
# EVERY TENANT BEFORE THEIR GFX RUNG. This gate is that check, frozen.
#
# SECTION 1 IS A POSITIVE CONTROL, AND IT IS THE POINT. The first version of
# this measurement reported "0 type-4" for HUITZIL — whose beam is a known
# type 4 — because the validator applied the coordinate-pointer constraint that
# only types 0/2/8 have (type 4 carries its entries inline). A census blind to
# what it is looking for reads exactly like a clean result; that is the 14z-71
# instrument lesson. So we assert Huitzil's KNOWN type-4 population first, on
# the same instrument, and only then trust the other tenants' numbers.
#
# Frozen expectations (vs2 data view, measured 14z-74):
#   Huitzil fighter anim 0x245872+0x1B500 : 26 type-4   <- the control
#   Donovan fighter anim 0x27F548+0x20F00 :  1 type-4
#   Pyron   fighter anim 0x264086+0x1B500 :  0 type-4   <- premise HOLDS
#
# Pyron's 0 is what licenses his delta-0 static gfx rung with no strip-tiles
# work. It covers his FIGHTER span only: his effect/companion data rides the
# shared x088512 region and is not extracted yet, so his EFFECT rung must
# re-run this over that data when it lands.
#
# Usage: ROMDIR=... tests/test_list_type_census.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-74: the ONE-SOURCE-BANK re-check per tenant. gfx_layout3 assumes a
#   tenant's art is one band in one source bank; a list TYPE 4 composes its
#   OWN bank word and breaks that (Huitzil's beam). Frozen counts: H 26 type-4
#   (the POSITIVE CONTROL — its first version was blind and read 0 for him), D
#   1, PYRON 0 (so his delta-0 placement needs no strip-tiles). Static
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
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== decrypt vs2 data view"
decrypt_view vsav2 "$WORK/op.bin" "$WORK/dat.bin" \
    || { echo "FAIL: decrypt"; exit 1; }

fail=0
run() {  # label start len expect
    python3 tools/list_type_census.py "$WORK/dat.bin" \
        --start "$2" --len "$3" --label "$1" --expect-type4 "$4" || fail=1
}

echo
echo "== 1. POSITIVE CONTROL — Huitzil's KNOWN type-4 beam population"
echo "      (if this reads 0, the instrument is blind: fix it before"
echo "       believing any other line in this file)"
run "huitzil-fighter" 0x245872 0x1B500 26

echo
echo "== 2. Donovan (frozen reference tenant)"
run "donovan-fighter" 0x27F548 0x20F00 1

echo
echo "== 3. PYRON — the one-source-bank premise for his gfx rung"
run "pyron-fighter"  0x264086 0x1B500 0

[ "$fail" = 0 ] || { echo; echo "FAIL: a census differs from its frozen value"; exit 1; }
echo
echo "PASS: list-type census frozen (control alive; Pyron's fighter span"
echo "      carries NO type 4 — his delta-0 placement needs no strip-tiles)"
