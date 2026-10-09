#!/bin/sh
# audit_dispatch_census.sh — WHICH type indices does LEGACY ever dispatch at
# the two obj_hook sites, and is the frozen observation still complete?
#
# WHAT: which object-type indices LEGACY ever dispatches at the two obj_hook sites over the
#   corpus, against the frozen inventory build/manifest/dispatch_census.toml — a NEW type
#   observed is a corpus that grew a spawn it never had.
# HOW: breakpoints on both dispatch sites over every replay with a frozen vanilla
#   masked-basis log on MAME (50 short debug runs), D0/4 = the dispatched index.
# EXPECTS: the inventory reproduced exactly; growth fails; every run covered its replay in
#   EMULATED frames (EMUFRAMES == CENSUSEND, the [MFI-5] clock check, #213); a REFERENCE leg
#   per replay (the same script, no breakpoint, no debugger) reproduces, at the basis log's
#   last frame, the frozen vanilla basis checksum (replay.lua's masked FNV-1a64 under
#   masked-v2/MASK) — so the script's frame index and input staging are replay.lua's; and
#   each census leg's game frame counter (RAM:$FF8080) equals its reference leg's there — so
#   under the breakpoint stops the index is still emulated time, by the game's own clock.
#   How many census legs also equal the basis byte for byte is PRINTED, not asserted: a stop
#   can move the game (14z-192: 03_two_player_vs leaves the basis at frame 469). Coverage stated:
#   'never observed' is a bound, not a proof, and no repoint ships on the complement.
# MUST-FIRE: known-bad: drift-clock — one leg (03_two_player_vs, 1800 frames) re-run under the
#   OLD frame_done clock (CENSUS_CLOCK=frame_done, the [MFI-5] desync) must cover FEWER emulated
#   frames than it counted AND show a game frame counter at frame 1800 different from the
#   reference leg's, so both the coverage check and the game-clock anchor see a replay that
#   ran short under the breakpoints (in-gate; as a mode every census leg runs the old clock
#   and the gate FAILs)
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/vsavj/masked-v2/ tests/lib/controls.sh
#   tests/lua/dispatch_census.lua tests/replays/ tools/run_mame.sh tools/setup_mame.sh
#
# WHY (14z-89). The legacy-cycle regression's fix is option (b) (maintainer,
# 2026-08-15): move the tenant's work OFF the legacy path. For obj_hook that
# means putting the tenant's object types on table entries LEGACY NEVER
# DISPATCHES — repointing such an entry is a pure DATA change and costs zero
# legacy cycles, whereas ANY code hook at the site costs cycles on every
# dispatch and tips VBL-edge frames into losing a main-loop iteration (that
# is the 24_don_winmash regression, attributed by tools/probe_hook_removal.sh).
# Repointing is not otherwise available: the dispatch is
# `movea.l (0x12,PC,D0.w),A0` and BOTH tables are followed by live code.
#
# WHAT IT MEASURES: vanilla vsavj, the whole legacy corpus (every replay with
# a frozen vanilla masked-basis log), breakpoint on each site, D0/4 = the
# dispatched index (D0 holds index*4 AT the site and is cleared right after).
#
# THE FROZEN INVENTORY (build/manifest/dispatch_census.toml) is the point.
# A NEW type observed = this corpus just grew a spawn it never had, and this
# FAILS so nobody finds out from a playtest. Drift is never absorbed silently.
#
# CORRECTED 14z-91 — THE COMPLEMENT IS NOT A FREE LIST, AND NO REPOINT
# SHIPPED ON IT. The "50 and 83 never observed" figures below were read as
# indices a tenant type could take over. A pool-attributed STATIC sweep
# (forward from every call site of each pool's allocator: 0x16F8E for
# $FF9400, 0x16FBA for $FFB800) measured the TRUE free lists at 1 and 6.
# This corpus reaches 9 of 58 real spawn types at 0x54470 and 31 of 108 at
# 0x5E542. The obj_hook fix relocates the WALKER instead and leaves the
# dispatch site vanilla, so tenant types stay above the vanilla entry count
# where a vanilla object cannot reach them BY CONSTRUCTION.
#
# COVERAGE IS THE WEAK PART, AND IT IS STATED RATHER THAN HIDDEN. Measured
# 14z-89: site 0x054470 fires in only 5 of 50 replays — 21/22/23/24/26, the
# long mash + arcade rigs — and the observation curve has NOT converged
# (26_don_arcade_mash alone contributed types 51 and 55 that nothing else
# saw). That is the same shape as the type-6 deadness row this session
# falsified: dead in four replays, live in the long ones. So "never observed
# in this corpus" is a BOUND, not a proof. Before shipping a repoint, add
# the STATIC complement — enumerate every type value vsavj's own code can
# stamp (tools/audit_type_stamps.py) — and keep a tripwire on the taken-over
# entry that does NOT write live work RAM (see the 14z-89 ruling (2): the
# gate watches EXECUTION, never a counter).
#
# THE CLOCK, CORRECTED 14z-192 (GitHub #213). Until 14z-192 the Lua keyed its
# replay input and its stop frame to a frame_done counter while two breakpoints
# were armed — the [MFI-5] desync: a CPU held at a breakpoint keeps emitting UI
# frames, so the counter ran ahead of emulated time and each replay stopped
# early with its input landing early. Measured 14z-192 on 26_don_arcade_mash:
# 4,202 emulated frames of the 40,620 counted under the old clock, against
# 40,620 of 40,620 under the screen's own frame number. The 14z-89 inventory
# was taken on the old clock; re-frozen 14z-192 on the emulated one. The
# figures quoted above (9 and 31 types, "5 of 50 replays") are the 14z-89
# drifted figures, kept as history; the run prints the current ones.
# TWO MORE FINDINGS OF THE SAME SITTING (rule-checker run 2026-10-05-673 asked
# for an anchor outside the script's clock): (1) the screen-frame clock, as
# first written (and as tests/lua/pc_count.lua had it until 14z-196, #228), skipped the
# FIRST frame_done, so the census ran one frame behind replay.lua with its
# input one frame late — a no-breakpoint leg missed the basis checksum until
# that frame was counted; (2) a breakpoint stop can move the game itself (the
# 68k/sound-CPU interleaving): 03_two_player_vs's census leg leaves the basis
# at frame 469 and differs in fighter and object fields by 5320, while
# 06_test_mode and 26_don_arcade_mash stay byte-identical. Hence the
# reference leg and the game-clock anchor described under EXPECTS.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=8] tests/audit_dispatch_census.sh
# minutes (the corpus at full emulated length under two breakpoints, JOBS-parallel).
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-89: WHICH type indices does LEGACY ever dispatch at the two obj_hook
#   sites? Vanilla vsavj over the whole legacy corpus (every replay with a
#   vanilla basis log), breakpoint per site, D0/4 = the index, SET-accumulated
#   so a site firing 270k times costs one line. Measured: 0x054470 9 types
#   observed, 0x05E542 31. FROZEN in build/manifest/ dispatch_census.toml — a
#   NEW index FAILS. THE COMPLEMENT IS NOT A FREE LIST (corrected 14z-91). It
#   was read as "50 and 83 indices a tenant type can take over"; a pool-
#   attributed STATIC sweep (forward from each pool's allocator, 0x16F8E /
#   0x16FBA) puts the TRUE free lists at 1 and 6. This corpus reaches 9 of 58
#   real spawn types at one site and 31 of 108 at the other — the same
#   coverage artefact that falsified list-type 6, ~40x larger. NO REPOINT
#   SHIPPED ON IT: the 14z-91 fix relocates the WALKER instead (see obj_hook
#   in patch_index), so tenant types stay above the vanilla entry count where
#   vanilla cannot reach them BY CONSTRUCTION. ~2 min, JOBS-parallel
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
JOBS="${JOBS:-8}"
SITES="54470:59,5e542:114"
FROZEN="build/manifest/dispatch_census.toml"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
CLOCK=""
vs_ctl_is drift-clock && CLOCK=frame_done
BASIS=tests/expected/vsavj/masked-v2
MASK="$(cat "$BASIS/MASK")"   # the basis's own record (tracked as MASK: a lower-case `mask` resolves only on a case-insensitive filesystem)
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/ref"

names="$(ls tests/expected/vsavj/masked-v2/logs/*.log | xargs -n1 basename | sed 's/\.log$//')"
echo "corpus: $(echo "$names" | wc -w | tr -d ' ') legacy replays (every replay with a vanilla basis log)"
pool=0
for n in $names; do
    rpl="tests/replays/$n.rpl"
    [ -f "$rpl" ] || continue
    lf=$(sed 's/#.*//' "$rpl" | awk 'NF { split($1, r, "-"); f=(r[2]?r[2]:r[1]);
         if (f + 0 > m) m = f + 0 } END { print m + 0 }')
    # THE ANCHOR (14z-192, rule-checker run 2026-10-05-673): the basis log's last frame,
    # capped to the run's length; its checksum is compared below.
    an=$(awk '$1 ~ /^[0-9]+$/ {l=$1} END {print l+0}' "$BASIS/logs/$n.log")
    [ "$an" -gt $((lf + 120)) ] && an=$((lf + 120))
    ( MAME_SANDBOX="$W/sb_$n" REPLAY="$PWD/$rpl" SITES="$SITES" CENSUS_OUT="$W/$n.txt" \
      FRAMES=$((lf + 120)) CENSUS_CLOCK="$CLOCK" ANCHOR="$an" MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
      tools/run_mame.sh vsavj -debug -debugger none \
      -autoboot_script "$PWD/tests/lua/dispatch_census.lua" >"$W/$n.log" 2>&1 ) &
    # the REFERENCE leg: no breakpoint, no debugger (14z-192)
    ( MAME_SANDBOX="$W/ref/sb_$n" REPLAY="$PWD/$rpl" SITES=none CENSUS_OUT="$W/ref/$n.txt" \
      FRAMES=$((lf + 120)) ANCHOR="$an" MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
      tools/run_mame.sh vsavj \
      -autoboot_script "$PWD/tests/lua/dispatch_census.lua" >"$W/ref/$n.log" 2>&1 ) &
    pool=$((pool + 2)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
wait

# THE IN-GATE CONTROL (14z-192, #213): the OLD clock on one leg must run short, and its
# game frame counter at frame 1800 must differ from the reference leg's.
ctl=0
if [ -z "$CLOCK" ]; then
    mkdir -p "$W/ctl"
    ( MAME_SANDBOX="$W/ctl/sb" REPLAY="$PWD/tests/replays/03_two_player_vs.rpl" SITES="$SITES" \
      CENSUS_OUT="$W/ctl/drift.txt" FRAMES=1800 CENSUS_CLOCK=frame_done ANCHOR=1800 MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
      tools/run_mame.sh vsavj -debug -debugger none \
      -autoboot_script "$PWD/tests/lua/dispatch_census.lua" >"$W/ctl/drift.log" 2>&1 ) || true
    ( MAME_SANDBOX="$W/ctl/sbr" REPLAY="$PWD/tests/replays/03_two_player_vs.rpl" SITES=none \
      CENSUS_OUT="$W/ctl/ref.txt" FRAMES=1800 ANCHOR=1800 MASK_RANGES="$MASK" MAME_ROMPATH="$ROMDIR" \
      tools/run_mame.sh vsavj \
      -autoboot_script "$PWD/tests/lua/dispatch_census.lua" >"$W/ctl/ref.log" 2>&1 ) || true
    ce="$(awk '$1=="EMUFRAMES" {print $2}' "$W/ctl/drift.txt" 2>/dev/null)"
    cc="$(awk '$1=="CENSUSEND" {print $2}' "$W/ctl/drift.txt" 2>/dev/null)"
    cg="$(awk '$1=="GAMECLOCK" {print $3}' "$W/ctl/drift.txt" 2>/dev/null)"
    rg="$(awk '$1=="GAMECLOCK" {print $3}' "$W/ctl/ref.txt" 2>/dev/null)"
    if [ -z "$ce" ] || [ -z "$cc" ] || [ -z "$cg" ] || [ -z "$rg" ]; then
        vs_ctl_dead drift-clock "the control legs did not complete" || ctl=1
    elif [ "$ce" -lt "$cc" ] && [ "$cg" != "$rg" ]; then
        vs_ctl_fired drift-clock "under the frame_done clock 03_two_player_vs counted $cc frames but covered $ce emulated frames, and its game frame counter at frame 1800 reads $cg where the reference leg's reads $rg — the coverage check and the game-clock anchor both see it"
    else
        vs_ctl_dead drift-clock "the old clock covered $ce of $cc frames, game clock $cg vs reference $rg — the checks cannot see a drifted run" || ctl=1
    fi
else
    vs_ctl_fired drift-clock "every census leg is running the old frame_done clock (mode)"
fi

W="$W" FROZEN="$FROZEN" CTL_FAIL="$ctl" BASIS="$BASIS" python3 - "${1:---check}" <<'PY'
import glob, os, re, sys
W, FROZEN, BASIS = os.environ["W"], os.environ["FROZEN"], os.environ["BASIS"]
mode = sys.argv[1]
# RETIRED as a budget (14z-91): nothing is allocated from the complement
# any more — see the header. Kept only so the report still says how many
# entries the tenants add, which is a useful sanity line next to the counts.
NEED = {0x54470: 17, 0x5e542: 10}     # entries the three tenants ADD today
sites, per_replay, incomplete, short, unanchored, anchored = {}, {}, [], [], [], 0
clockoff, moved, census_exact = [], [], 0
for f in sorted(glob.glob(f"{W}/*.txt")):
    name = os.path.basename(f)[:-4]
    txt = open(f).read()
    if "CENSUSEND" not in txt:
        incomplete.append(name); continue
    # THE CLOCK CHECK (#213): the run must have covered, in EMULATED frames,
    # every frame it counted; a shortfall is the [MFI-5] desync.
    me = re.search(r"EMUFRAMES (\d+)", txt); mc = re.search(r"CENSUSEND (\d+)", txt)
    if not me or int(me.group(1)) != int(mc.group(1)):
        short.append(f"{name} ({me.group(1) if me else 'no EMUFRAMES'} of {mc.group(1)})")
    # THE ANCHORS (14z-192): the REFERENCE leg's checksum at the basis log's last frame
    # must be the basis's; the census leg's game frame counter there must be the
    # reference leg's; whether the census leg ALSO equals the basis is counted only.
    basis = {}
    for ln in open(os.path.join(BASIS, "logs", name + ".log")):
        p = ln.split()
        if len(p) == 2 and p[0].isdigit():
            basis[int(p[0])] = p[1]
    rp = os.path.join(W, "ref", name + ".txt")
    rtxt = open(rp).read() if os.path.exists(rp) else ""
    ra = re.search(r"ANCHOR (\d+) ([0-9a-f]{16})", rtxt)
    rg = re.search(r"GAMECLOCK \d+ ([0-9a-f]{2})", rtxt)
    ca = re.search(r"ANCHOR (\d+) ([0-9a-f]{16})", txt)
    cg = re.search(r"GAMECLOCK \d+ ([0-9a-f]{2})", txt)
    if not ra:
        unanchored.append(f"{name} (reference leg: no ANCHOR line)")
    elif basis.get(int(ra.group(1))) != ra.group(2):
        unanchored.append(f"{name} (reference leg, frame {ra.group(1)}: {ra.group(2)} vs basis {basis.get(int(ra.group(1)), 'absent')})")
    else:
        anchored += 1
    if not cg or not rg or cg.group(1) != rg.group(1):
        clockoff.append(f"{name} (game clock {cg.group(1) if cg else 'none'} vs reference {rg.group(1) if rg else 'none'})")
    if ca and basis.get(int(ca.group(1))) == ca.group(2):
        census_exact += 1
    else:
        moved.append(name)
    for m in re.finditer(r"SITE (\w+) entries (\d+) hits (\d+) seen \d+ : (.*)", txt):
        a, n, hits = int(m.group(1), 16), int(m.group(2)), int(m.group(3))
        s = sites.setdefault(a, {"n": n, "seen": set(), "hits": 0, "live": 0})
        s["hits"] += hits
        if hits:
            s["live"] += 1
            per_replay.setdefault(a, []).append((name, hits, m.group(4)))
        if m.group(4).strip():
            s["seen"].update(int(x) for x in m.group(4).split(","))
# `hard`: what makes the run unfit to freeze from (an incomplete or short run, a dead
# control); growth against the frozen set is a FAIL of the check, never of a --freeze.
hard = 1 if os.environ.get("CTL_FAIL") == "1" else 0
if incomplete:
    print("  FAIL: incomplete census runs: " + ", ".join(incomplete)); hard = 1
nruns = len(glob.glob(f"{W}/*.txt"))
if short:
    print(f"  FAIL: {len(short)} run(s) covered fewer emulated frames than they counted "
          f"(the [MFI-5] desync): " + ", ".join(short)); hard = 1
else:
    print(f"  ok: all {nruns - len(incomplete)} completed runs covered exactly their counted frames in emulated time")
if unanchored:
    print(f"  FAIL: {len(unanchored)} reference leg(s) missed the vanilla basis checksum at their anchor frame "
          f"(the script's frame index or input staging is not replay.lua's): " + ", ".join(unanchored)); hard = 1
else:
    print(f"  ok: {anchored} reference leg(s) reproduced the frozen vanilla basis checksum at the basis log's last frame")
if clockoff:
    print(f"  FAIL: {len(clockoff)} census leg(s) whose game frame counter RAM:$FF8080 at the anchor is not "
          f"their reference leg's (the index is not emulated time under the stops): " + ", ".join(clockoff)); hard = 1
else:
    print(f"  ok: every census leg's game frame counter at the anchor equals its reference leg's ({nruns - len(incomplete)} legs)")
print(f"  info: {census_exact} census leg(s) also equal the basis byte for byte; {len(moved)} moved under the "
      f"breakpoint stops (a legal vanilla game, not the basis's): " + (", ".join(moved) if moved else "none"))
fail = hard
frozen = {}
if os.path.exists(FROZEN):
    cur = None
    for ln in open(FROZEN):
        m = re.match(r'site = 0x(\w+)', ln.strip())
        if m: cur = int(m.group(1), 16)
        m = re.match(r'observed = \[(.*)\]', ln.strip())
        if m and cur is not None:
            frozen[cur] = set(int(x) for x in m.group(1).split(",") if x.strip())
out = ["# build/manifest/dispatch_census.toml — FROZEN legacy dispatch",
       "# observation for the two obj_hook sites (14z-89). Regenerate with",
       "# tests/audit_dispatch_census.sh --freeze. A NEW index here means the",
       "# free list shrank: re-review any repoint that relied on it.",
       "schema = 1"]
# A re-freeze keeps the committed file's own leading comment block (its 14z-91
# and 14z-192 corrections), replacing only the data below `schema = 1`.
if os.path.exists(FROZEN):
    head = []
    for ln in open(FROZEN):
        head.append(ln.rstrip("\n"))
        if ln.strip() == "schema = 1":
            break
    if head and head[-1].strip() == "schema = 1":
        out = head
for a in sorted(sites):
    s = sites[a]
    seen = sorted(s["seen"]); free = sorted(set(range(s["n"])) - s["seen"])
    print(f"\n=== site {a:#08x}: {s['n']} entries, {s['hits']:,} dispatches in "
          f"{s['live']}/{len(glob.glob(f'{W}/*.txt'))} replays")
    print(f"    OBSERVED {len(seen)}: {seen}")
    print(f"    NEVER OBSERVED IN THIS CORPUS {len(free)} "
          f"(tenants add {NEED.get(a,0)} entries ABOVE the vanilla count) — "
          f"NOT a free list, see the header")
    if s["live"] <= 5:
        print(f"    NOTE: only {s['live']} replays reach this site — "
              f"a thin base for a deadness claim; see the header")
        for nm, h, ty in sorted(per_replay.get(a, [])):
            print(f"      {nm:32s} {h:>7,} dispatches  types {ty}")
    if a in frozen:
        new = sorted(s["seen"] - frozen[a]); gone = sorted(frozen[a] - s["seen"])
        if new:
            print(f"    FAIL: NEW indices dispatched, not in the frozen set: {new}")
            print( "          the free list shrank — re-review any repoint relying on them")
            fail = 1
        if gone:
            print(f"    note: frozen indices not seen this run (corpus change?): {gone}")
        if not new and not gone:
            print("    ok: matches the frozen observation exactly")
    else:
        print("    (no frozen entry yet — run with --freeze)")
    if s["hits"] == 0:
        print("    FAIL: zero dispatches — dead instrument, not a finding"); fail = 1; hard = 1
    out += ["", "[[site]]", f"site = 0x{a:05x}", f"entries = {s['n']}",
            f"observed = [{','.join(str(x) for x in seen)}]"]
if mode == "--freeze":
    if hard:
        print("\nREFUSED: --freeze on a run unfit to freeze from (incomplete, short, a dead instrument or a dead control)")
        sys.exit(1)
    open(FROZEN, "w").write("\n".join(out) + "\n")
    print(f"\nFROZE {FROZEN}")
    sys.exit(0)
print("\n" + ("DISPATCH CENSUS: PASS" if not fail else "DISPATCH CENSUS: FAIL"))
sys.exit(fail)
PY
