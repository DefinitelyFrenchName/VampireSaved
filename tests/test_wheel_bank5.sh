#!/bin/sh
# test_wheel_bank5.sh — the select-wheel bank-5 move (14z-63, phase 3):
# real medallion art for the appended cells, vanilla cells byte-copied.
#
# WHAT: the select-wheel bank-5 move: the drawer's bank-word immediate flipped to bank 5,
#   every referenced wheel tile placed in group C at 0x10000+code (host entries
#   byte-identical to vsav's group A, appended entries from vs2's), and the engine walking
#   the wheel record from bank 5 with the fmt-2 handler seeing bank word 0x3000 and the
#   relocated record.
# HOW: tools/check_wheel_bank5.py re-derives the whole move from the ROM record, the layout
#   and both source zips against the built image; negative controls corrupt a tile byte and
#   strip the code op; runtime on WIDE MAME with replay 36.
# EXPECTS: static equal, both controls failing, the engine's bank-5 walk observed — on an instrument whose input
#   lands on replay.lua's frames (#228 step 4, maintainer-ruled 2026-10-10 "option A"): the trace leg runs on
#   tests/lua/emu_clock.lua's emulated clock, a REFERENCE leg of the same replay (no debugger) reproduces
#   replay.lua's checksum at the trace's last frame, and the trace leg's game clock RAM:$FF8080 equals the
#   reference leg's. One replay, so the staging reference leg IS that replay's reference: the trace leg is held
#   to it live rather than to a frozen value.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lib/decrypt_cache.sh
#   tests/lib/tenant_build.sh tests/lua/obj_record_bank_trace.lua tests/lua/replay.lua
#   tests/replays/ tools/build_donovan.sh tools/check_wheel_bank5.py tools/gfx_tiles.py
#   tools/run_mame.sh tools/setup_mame.sh tests/lua/emu_clock.lua
#
# MUST-FIRE: known-bad: drift-clock — the trace leg under the OLD frame_done clock (INSTR_CLOCK=frame_done, the [MFI-5] desync the gate ran on until 14z-197) must cover fewer emulated frames than it counts or read a game clock unlike the reference leg's (in-gate; as a mode the trace leg runs the old clock and the gate FAILs)
# MUST-FIRE: known-bad: first-frame-skip — the reference leg under the #213 first-frame skip (INSTR_CLOCK=skip_first) must miss replay.lua's checksum at the trace's last frame (in-gate; as a mode the reference leg runs the skip and the gate FAILs)
#
# MECHANISM (measured 14z-63; docs/game/atlas/select_screen.md). The wheel is
# ONE record drawn by ONE object ($FFB800) whose select-screen anim chain
# is a single stop-flagged entry (0x2689FA -> the record) — so per-entry
# banks are impossible and the whole record moves banks together. The
# select init writes the drawer's bank word at PRG:0x5F8B2
# (`move.w #$2000,$18(a6)`, writes ONLY $FFB818 — measured family-wide);
# the build flips that immediate to #$3000 (bank 5) and places every
# referenced tile in group C at 0x10000+code: host entries byte-identical
# from vsav group A (pixels identical by construction), appended entries'
# native vs2 codes from vsav2 group A. The shared attract-screen init
# loop at 0x07C428 (stride 0x80 over every menu object) is NOT patched.
#
#   1. STATIC — tools/check_wheel_bank5.py re-derives the whole move
#      independently (site bytes, code op, tile enumeration from the ROM
#      record + layout, and the built group C members' bytes against both
#      source zips, decoded straight from the zips).
#   2. NEGATIVE CONTROLS — the verdict logic is itself tested: one
#      corrupted tile byte in the built group C member FAILS; a patch
#      stripped of the code op FAILS.
#   3. RUNTIME — the engine walks the wheel record from bank 5: the
#      fmt-2 handler sees OBJ $FFB800 with bank word 0x3000 and A0 at
#      the relocated record (obj_record_bank_trace, replay 36).
#
# Usage: ROMDIR=... tests/test_wheel_bank5.sh [outbase]
#   outbase: an existing variant-id WIDE build (default: builds fresh at
#   --tenant-id 0x13 --profile cps2-wide-v1).
# Env: MAME_WIDE_BIN overrides the WIDE MAME binary
#      (default ~/.cache/vampire-saved/mame/cps2). SKIP_RUNTIME=1 skips
#      section 3.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   the select-wheel bank-5 move (14z-63): site + re-derived tile inventory +
#   group C member identity straight from the zips + negative controls + the
#   engine's own bank-5 walk. Self-builds at 0x13 unless given a build
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
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
. "$REPO/tests/lib/tenant_build.sh"    # GitHub #71
. "$REPO/tests/lib/decrypt_cache.sh"   # GitHub #69
cd "$REPO"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# The build shape lives in tests/lib/tenant_build.sh (GitHub #71): stage,
# profile and tenant id were inline in five gates and all three have moved
# before.
tenant_build_13 "$WORK" "${1:-}" || exit 1
[ -f "$OUTBASE/patch/wheel_bank5.json" ] || {
    echo "FAIL: $OUTBASE/patch/wheel_bank5.json missing — not a bank5 build"
    exit 1; }

OPC="$WORK/vsavj_op.bin"
VAN="$WORK/vsavj_data.bin"
decrypt_view vsavj "$OPC" "$VAN"
LAYOUT="build/manifest/wheel_layout_proposed.json"

echo "== 1. static: site + inventory + group C member bytes =="
python3 tools/check_wheel_bank5.py "$OUTBASE" "$OPC" "$VAN" "$ROMDIR" \
    "$LAYOUT" > "$WORK/static.txt" || {
    echo "FAIL: static check:"; sed 's/^/  /' "$WORK/static.txt"; exit 1; }
sed 's/^/  ok: /' "$WORK/static.txt"

echo "== 2. negative controls: the verdict logic is itself tested =="
# 2a. one corrupted tile byte in the built group C member must FAIL
mkdir -p "$WORK/neg/rompath" "$WORK/neg/patch"
cp "$OUTBASE"/patch/patch.json "$OUTBASE"/patch/wheel_bank5.json \
    "$WORK/neg/patch/"
python3 - "$OUTBASE" "$WORK/neg" <<'PY'
import json, sys, zipfile, zlib
src, dst = sys.argv[1], sys.argv[2]
zin = zipfile.ZipFile(src + "/rompath/vsavjw.zip")
codes = json.load(open(src + "/patch/wheel_bank5.json"))["host"]
with zipfile.ZipFile(dst + "/rompath/vsavjw.zip", "w",
                     zipfile.ZIP_DEFLATED) as zout:
    for n in zin.namelist():
        d = zin.read(n)
        if n == "vsw.31m":
            d = bytearray(d)
            # flip one byte inside the first host tile's contribution
            import importlib.util, pathlib
            spec = importlib.util.spec_from_file_location(
                "gfx_tiles", pathlib.Path("tools/gfx_tiles.py"))
            gt = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(gt)
            t2 = 0x10000 + codes[0]
            b = (128 * t2) // 0x200000
            base = (b * 0x80000 + 64 * ((128 * t2 % 0x100000) // 128)
                    + 2 * (((128 * t2) % 0x200000) // 0x100000))
            d[base] ^= 0xFF
            d = bytes(d)
        zout.writestr(n, d)
PY
if python3 tools/check_wheel_bank5.py "$WORK/neg" "$OPC" "$VAN" "$ROMDIR" \
        "$LAYOUT" > /dev/null 2>&1; then
    echo "  FAIL: a corrupted group C tile PASSED the checker"
    fail=1
else
    echo "  ok: one corrupted tile byte is caught"
fi
# 2b. a patch stripped of the code op must FAIL
mkdir -p "$WORK/neg2/patch"
cp "$OUTBASE"/patch/wheel_bank5.json "$WORK/neg2/patch/"
ln -s "$(cd "$OUTBASE" && pwd)/rompath" "$WORK/neg2/rompath"
python3 - "$OUTBASE" "$WORK/neg2" <<'PY'
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
kept = [o for o in ops
        if not (o.get("op") == "code" and o.get("addr") == "0x5f8b2")]
if isinstance(p, dict) and "ops" in p:
    p["ops"] = kept
else:
    p = kept
json.dump(p, open(sys.argv[2] + "/patch/patch.json", "w"))
PY
if python3 tools/check_wheel_bank5.py "$WORK/neg2" "$OPC" "$VAN" "$ROMDIR" \
        "$LAYOUT" > /dev/null 2>&1; then
    echo "  FAIL: a patch without the bank flip PASSED the checker"
    fail=1
else
    echo "  ok: a stripped code op is caught"
fi

echo "== 3. runtime: the wheel record is walked from bank 5 =="
if [ "${SKIP_RUNTIME:-0}" = 1 ]; then
    echo "  SKIPPED (SKIP_RUNTIME=1)"
else
    WIDE_BIN="${MAME_WIDE_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
    "$WIDE_BIN" -listfull vsavjw > /dev/null 2>&1 || {
        echo "FAIL: $WIDE_BIN does not know vsavjw (tools/setup_mame.sh)"
        exit 1; }
    # the relocated record's address, from the build's own repoint op
    REC="$(python3 - "$OUTBASE" <<'PY'
import json, sys
p = json.load(open(sys.argv[1] + "/patch/patch.json"))
ops = p["ops"] if isinstance(p, dict) and "ops" in p else p
for o in ops:
    if o.get("op") == "poke32" and int(o.get("addr"), 16) == 0x2689FE:
        print(f"{int(str(o['val']), 16):x}")
        break
PY
)"
    [ -n "$REC" ] || { echo "FAIL: no wheel repoint op in patch.json"; exit 1; }
    # THE TRACE LEG, ITS REFERENCE LEG, AND replay.lua (#228 step 4, option A): the trace counts EMULATED frames
    # (tests/lua/emu_clock.lua); the reference leg is the same script without the debugger, anchored at the last
    # frame; replay.lua's own checksum at that frame is the yardstick the reference leg must reproduce.
    T=1000
    trace_leg() {  # trace_leg <tag> <extra env...>
        tag="$1"; shift
        env "$@" REPLAY="$REPO/tests/replays/36_pick_tenant_cell.rpl" FRAMES=$T \
        REC_LO="$REC" REC_HI="$(printf '%x' $((0x$REC + 0x10)))" \
        TRACE_OUT="$WORK/$tag.txt" ALIGN_OUT="$WORK/$tag.align" \
        MAME_SANDBOX="$WORK/sbx_$tag" MAME_BIN="$WIDE_BIN" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavjw -debug -debugger none \
            -autoboot_script tests/lua/obj_record_bank_trace.lua \
            > /dev/null 2>&1 || true
    }
    ref_leg() {  # ref_leg <tag> <extra env...>
        tag="$1"; shift
        env "$@" INSTR_REFERENCE=1 ANCHOR=$T REPLAY="$REPO/tests/replays/36_pick_tenant_cell.rpl" FRAMES=$T \
        TRACE_OUT="$WORK/$tag.txt" ALIGN_OUT="$WORK/$tag.align" \
        MAME_SANDBOX="$WORK/sbx_$tag" MAME_BIN="$WIDE_BIN" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavjw \
            -autoboot_script tests/lua/obj_record_bank_trace.lua \
            > /dev/null 2>&1 || true
    }
    al() { awk -v k="$2" '{for (i = 1; i < NF; i++) if ($i == k) {print $(i + 1); exit}}' "$WORK/$1.align" 2>/dev/null; }
    anc() { awk '{for (i = 1; i < NF; i++) if ($i == "anchor") {print $(i + 2); exit}}' "$WORK/$1.align" 2>/dev/null; }
    TCLOCK=""; vs_ctl_is drift-clock && TCLOCK="INSTR_CLOCK=frame_done"
    RCLOCK=""; vs_ctl_is first-frame-skip && RCLOCK="INSTR_CLOCK=skip_first"
    # shellcheck disable=SC2086
    trace_leg trace $TCLOCK
    # shellcheck disable=SC2086
    ref_leg ref $RCLOCK
    CHECKSUM_OUT="$WORK/rl/cks.log" REPLAY="$REPO/tests/replays/36_pick_tenant_cell.rpl" \
    MAME_SANDBOX="$WORK/sbx_rl" MAME_BIN="$WIDE_BIN" MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
        sh -c 'mkdir -p "$(dirname "$CHECKSUM_OUT")" && tools/run_mame.sh vsavjw -autoboot_script tests/lua/replay.lua' \
        > /dev/null 2>&1 || true
    RL="$(awk -v n=$T '$1==n {print $2}' "$WORK/rl/cks.log" 2>/dev/null)"
    ra="$(anc ref)"; rg="$(al ref gameclock)"
    tf="$(al trace frames)"; te="$(al trace emulated)"; tg="$(al trace gameclock)"
    if [ -n "$RL" ] && [ "$ra" = "$RL" ]; then
        echo "  ok: the reference leg reproduces replay.lua at frame $T ($ra)"
    else
        echo "  FAIL: the reference leg reads ${ra:-nothing} at frame $T, replay.lua ${RL:-nothing}: the instrument's input staging is off replay.lua's"
        fail=1
    fi
    if [ "$tf" = "$T" ] && [ "$te" = "$T" ] && [ -n "$tg" ] && [ "$tg" = "$rg" ]; then
        echo "  ok: the trace leg covered $te emulated frames of $tf counted; game clock $tg = the reference leg's"
    else
        echo "  FAIL: the trace leg counted ${tf:-?} frames over ${te:-?} emulated, game clock ${tg:-?} (reference ${rg:-?}): its input drifted from the replay"
        fail=1
    fi
    # the fmt-2 handler's A0 is record+2 (past the format word)
    REC2="$(printf '%06x' $((0x$REC + 2)))"
    if grep -q "REC ${REC2} BANK 3000 OBJ ffb800" "$WORK/trace.txt"; then
        echo "  ok: \$FFB800 walks the relocated record ($REC) with bank 0x3000"
    else
        echo "  FAIL: expected REC ${REC2} BANK 3000 OBJ ffb800; trace:"
        sed 's/^/        /' "$WORK/trace.txt"
        fail=1
    fi
    if vs_ctl_is drift-clock || vs_ctl_is first-frame-skip; then
        [ "$fail" -ne 0 ] && { echo "FAIL: wheel bank-5 gate (control mode: $VS_CTL)"; exit 1; }
        echo "FAIL: wheel bank-5 gate — control mode $VS_CTL left it green"; exit 1
    fi
    trace_leg ctl_drift INSTR_CLOCK=frame_done
    de="$(al ctl_drift emulated)"; dg="$(al ctl_drift gameclock)"
    if [ -z "$de" ]; then vs_ctl_dead drift-clock "the drift leg wrote no ALIGN line" || fail=1
    elif [ "$de" -lt "$T" ] || [ "$dg" != "$rg" ]; then
        vs_ctl_fired drift-clock "under the frame_done clock the trace leg covered $de emulated frames of $T counted, game clock $dg where the reference leg's reads $rg"
    else vs_ctl_dead drift-clock "the frame_done clock covered $de of $T frames with game clock $dg (reference $rg)" || fail=1; fi
    ref_leg ctl_skip INSTR_CLOCK=skip_first
    sa="$(anc ctl_skip)"
    if [ -z "$sa" ]; then vs_ctl_dead first-frame-skip "the skip leg wrote no anchor" || fail=1
    elif [ "$sa" != "$RL" ]; then vs_ctl_fired first-frame-skip "under the first-frame skip the reference leg reads $sa at frame $T where replay.lua reads $RL"
    else vs_ctl_dead first-frame-skip "the skipped clock still reproduced replay.lua at frame $T" || fail=1; fi

    # 3b. medallion palette stability (14z-63 r10-11 / 14z-64). ALL
    # THREE medallion rows must hold the vs2 palettes through BOTH
    # stress protocols: the maximal select (timer/venue-phase trigger)
    # and the maintainer's mash-right repro (per-hover trigger). The
    # marchers' vestigial MID-ROW writes (rows 0x16/0x19/0x1A —
    # referenced by nothing in vanilla) are redirected to the scratch
    # row 0x02 at the two select-side dest computations (0x2B598/
    # 0x2B7D8, select-gated on $FFB818==0x3000; 0x2AD44 is the
    # in-match funnel and must NEVER be thunked — the $FF8094 parity
    # lesson). THE KNOWN RESIDUAL IS FIXED (14z-116): 0x1A was also the
    # P2 sword-accent row, so a 2P Donovan-hover recolored Pyron's
    # medallion until screen re-entry; the 62k thunk's P2 branch no
    # longer writes. NOTE THIS SECTION COULD NEVER HAVE SEEN IT — both
    # protocols here (replays 63/64) are SINGLE-PLAYER select stress and
    # neither hovers a tenant with P2, which is why it stayed green
    # through every freeze. The P2 half is
    # tests/test_pyron_medallion_2p.sh; run both.
    run_stab() {  # run_stab <tag> <replay> <dumpspec> <frames>
        mkdir -p "$WORK/$1"
        DUMPS="$3" CHECKSUM_OUT="$WORK/$1/cks.log" FRAMES="$4" \
        REPLAY="$REPO/tests/replays/$2" \
        MAME_SANDBOX="$WORK/sbx_$1" MAME_BIN="$WIDE_BIN" \
        MAME_ROMPATH="$OUTBASE/rompath;$ROMDIR" \
            tools/run_mame.sh vsavjw \
            -autoboot_script tests/lua/replay.lua > /dev/null 2>&1 || true
    }
    run_stab stab 63_idle_select.rpl \
        "1900:90c000-90c35f;2800:90c000-90c35f;3600:90c000-90c35f" 3650
    run_stab mash 64_select_mashright.rpl \
        "1400:90c000-90c35f;2300:90c000-90c35f" 2350
    python3 - "$WORK/stab" "$WORK/mash" <<'PY' || fail=1
import sys, glob
vs2 = open("build/out/vsav2_data.bin", "rb").read()
def alpha(b):
    return bytes(((b[i] | 0xF0) if i % 2 == 0 else b[i])
                 for i in range(len(b)))
WANT = {0x16: alpha(vs2[0x3BAFDC:0x3BAFDC + 0x20]),   # Donovan
        0x1A: alpha(vs2[0x3BB15C:0x3BB15C + 0x20]),   # Pyron
        0x19: alpha(vs2[0x3BB19C:0x3BB19C + 0x20])}   # Phobos
n = 0
for d_dir in sys.argv[1:]:
    files = sorted(glob.glob(d_dir + "/dump_*.bin"))
    assert files, f"no dumps in {d_dir}"
    for f in files:
        fr = f.split("_")[-2]
        d = open(f, "rb").read()
        for row, want in WANT.items():
            got = d[row * 0x20:(row + 1) * 0x20]
            assert got == want, (f"{d_dir.split('/')[-1]} f{fr} row "
                                 f"{row:#04x} lost the vs2 palette "
                                 f"(head {got[:8].hex()})")
            n += 1
print(f"  ok: all three medallion rows hold across both stress "
      f"protocols ({n} samples) — the white-out is retired")
PY
fi

if [ "$fail" -ne 0 ]; then
    echo "FAIL: wheel bank-5 gate"
    exit 1
fi
echo "PASS: wheel bank-5 gate (site + re-derived inventory + group C"
echo "      member identity + negative controls + the engine's own walk"
echo "      from bank 5)"
