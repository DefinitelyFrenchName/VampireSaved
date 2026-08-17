#!/bin/sh
# test_replay_stage_census.sh — FREEZE the input-staging convention of every
# replay-driving Lua instrument (14z-93, GitHub issue #10). No ROMs, no
# emulator, ~1s.
#
# THE DEFECT THIS GUARDS (not fixed — deliberately; see below). All replay
# instruments increment `frame` at the top of the same
# `emu.register_frame_done` callback. The CANONICAL convention is
# replay.lua's: parse `held[fr]`, stage `held[frame + 1]`, so a script line
# N is live during emulated frame N. Ten instruments net a +1 shift, in two
# flavours:
#   (i)  parse held[fr],     stage held[frame]      — 8 files
#   (ii) parse held[fr + 1], stage held[frame + 1]  — 2 files
# so a script line N is live during frame N+1 and a frame number out of one
# of those logs is NOT a frame number from replay.lua's checksum log,
# a compare_* first divergence, or a masked window onset.
#
# WHY THIS IS A CENSUS AND NOT A FIX. The frame constants of the consuming
# gates were tuned UNDER the drifted timing (test_beam_variants DUMP_FRAMES,
# test_tenant_hud 3100/3110, test_hui_df_style OBJFR/PALFR,
# audit_trap_parity WINDOWS, audit_voice_borrow WINDOW=3985,4005). Changing
# the staging without re-deriving those does not make the gates right — it
# silently re-dates them. The staging fix and the re-measurement are ONE
# change. Until then this gate does the only thing that is honest: it pins
# the split exactly, so it cannot GROW silently and so a new instrument
# cannot copy the wrong flavour unnoticed — which is exactly how it spread
# (one variant at 23071cc, and every later instrument copied the copy).
#
# WHEN THE REAL FIX LANDS: set EXPECT_DEVIANT=0 and delete the frozen list.
# The gate then asserts the convention is uniform, which is what it is for.
#
# NOTE FOR ANYONE EDITING THIS: strip Lua comments before matching. The
# drifted instruments carry a BANNER that quotes `held[frame + 1]` while
# explaining the canonical convention, so a naive grep reads them as
# canonical — measured 14z-93, it turned a 10-deviant census into a
# 3-deviant one and nearly got reported as "7 of 10 fixed".
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0

python3 - <<'PY' || fail=1
import glob, os, re, sys

# UNIFIED 14z-94: the split is now ZERO. Every replay-driving instrument
# parses `held[fr]` and stages `held[frame + 1]`, so a frame number from any
# of their logs is a replay.lua frame number.
#
# The ten that were deviant, kept as history so a REGRESSION names itself
# rather than appearing as an anonymous new file: bp_regs, obj_records_dump,
# objy_bits, qs_sweep, qs_table_trace, qs_z80_trace, read_tap, ring_tap,
# snapshot_frames, unmapped_probe. Eight staged `held[frame]`; two parsed
# `held[fr + 1]`.
FORMERLY_DEVIANT = {
    "bp_regs.lua", "obj_records_dump.lua", "objy_bits.lua", "qs_sweep.lua",
    "qs_table_trace.lua", "qs_z80_trace.lua", "read_tap.lua", "ring_tap.lua",
    "snapshot_frames.lua", "unmapped_probe.lua",
}
DEVIANT = set()
EXPECT_DEVIANT = int(os.environ.get("EXPECT_DEVIANT", "0"))


def strip_comments(s):
    out = []
    for ln in s.split("\n"):
        i = ln.find("--")
        out.append(ln[:i] if i >= 0 else ln)
    return "\n".join(out)


def classify(raw):
    s = strip_comments(raw)
    if "dofile" in s and "replay.lua" in s:
        return "canonical"          # chains the canonical driver
    parse_n1 = re.search(r"held\[fr\s*\+\s*1\]", s) is not None
    stage_n1 = re.search(r"held\[frame\s*\+\s*1\]", s) is not None
    stage_n = re.search(r"held\[frame\]", s) is not None
    if stage_n1 and not parse_n1:
        return "canonical"
    if stage_n and not parse_n1:
        return "deviant-i"
    if parse_n1 and stage_n1:
        return "deviant-ii"
    return "unclassified"


found, rc = {}, 0
for p in sorted(glob.glob("tests/lua/*.lua")):
    raw = open(p).read()
    if 'os.getenv("REPLAY")' not in raw and "getenv('REPLAY')" not in raw:
        continue
    found[os.path.basename(p)] = (classify(raw), raw)

dev = {n for n, (c, _) in found.items() if c.startswith("deviant")}
unc = {n for n, (c, _) in found.items() if c == "unclassified"}
print(f"  replay-driving instruments: {len(found)}; deviant: {len(dev)}")

if unc:
    print("  FAIL: unclassified instrument(s) — the census cannot see them:")
    for n in sorted(unc):
        print(f"        {n}")
    rc = 1

# GROWTH is the thing to catch: a NEW instrument copying the wrong flavour.
grew = dev - DEVIANT
if grew:
    print("  FAIL: NEW deviant instrument(s) — a new file copied the wrong")
    print("        flavour. Fix the file, do not extend the frozen list:")
    for n in sorted(grew):
        print(f"        {n} ({found[n][0]})")
    rc = 1

fixed = DEVIANT - dev
if fixed and len(dev) != EXPECT_DEVIANT:
    print("  note: instrument(s) no longer deviant — if this is the real fix,")
    print("        re-derive the consuming gates' frame constants and then")
    print("        drop them from DEVIANT here:")
    for n in sorted(fixed):
        print(f"        {n}")

if len(dev) != EXPECT_DEVIANT:
    print(f"  FAIL: deviant count {len(dev)} != expected {EXPECT_DEVIANT}")
    rc = 1
else:
    print(f"  ok: the split is exactly as frozen ({len(dev)} deviant, "
          f"{len(found) - len(dev)} canonical)")

# EVERY deviant must carry its banner. The gotcha promises this ("until
# then every drifted instrument carries a banner saying so") and 2 of 10
# did not when this gate was written — bp_regs.lua, whose header actively
# claimed the OPPOSITE, and ring_tap.lua.
missing = [n for n in sorted(dev)
           if not re.search(r"INPUT-STAGING CONVENTION", found[n][1])]
if missing:
    print("  FAIL: deviant instrument(s) with no INPUT-STAGING banner —")
    print("        the documented mitigation is that every one carries it:")
    for n in missing:
        print(f"        {n}")
    rc = 1
else:
    print(f"  ok: all {len(dev)} deviants carry the INPUT-STAGING banner")

# replay.lua itself must stay canonical, or the whole frame of reference moves.
if classify(open("tests/lua/replay.lua").read()) != "canonical":
    print("  FAIL: replay.lua is no longer canonical — it IS the reference")
    rc = 1
else:
    print("  ok: replay.lua is canonical (the reference convention)")

sys.exit(rc)
PY

echo "== verdict controls =="
python3 - <<'PY' || fail=1
import re, sys
def strip_comments(s):
    return "\n".join(ln[:ln.find("--")] if ln.find("--") >= 0 else ln
                     for ln in s.split("\n"))
def classify(raw):
    s = strip_comments(raw)
    parse_n1 = re.search(r"held\[fr\s*\+\s*1\]", s) is not None
    stage_n1 = re.search(r"held\[frame\s*\+\s*1\]", s) is not None
    stage_n = re.search(r"held\[frame\]", s) is not None
    if stage_n1 and not parse_n1: return "canonical"
    if stage_n and not parse_n1:  return "deviant-i"
    if parse_n1 and stage_n1:     return "deviant-ii"
    return "unclassified"
rc = 0
cases = [
    ("canonical",   "held[fr] = {}\nfor _,f in ipairs(held[frame + 1]) do end"),
    ("deviant-i",   "held[fr] = {}\nprev = held[frame] or {}"),
    ("deviant-ii",  "held[fr + 1] = {}\nfor _,f in ipairs(held[frame + 1]) do end"),
    # THE ONE THAT MATTERS: a deviant whose COMMENT quotes the canonical
    # form. Un-stripped this reads as canonical — the exact mis-census that
    # nearly shipped as "7 of 10 fixed".
    ("deviant-i",   "-- replay.lua stages held[frame + 1] at the end\n"
                    "held[fr] = {}\nprev = held[frame] or {}"),
]
for want, src in cases:
    got = classify(src)
    if got == want:
        print(f"  ok control: {want:11s} classified correctly")
    else:
        print(f"  FAIL control: wanted {want}, got {got} for [{src[:40]}...]")
        rc = 1
sys.exit(rc)
PY

echo
if [ "$fail" = 0 ]; then
    echo "PASS: the input-staging split is exactly as frozen and documented."
else
    echo "FAIL: the input-staging census moved — read GitHub #10 before editing."
fi
exit "$fail"
