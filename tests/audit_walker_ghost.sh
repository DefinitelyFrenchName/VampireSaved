#!/bin/sh
# audit_walker_ghost.sh — WHERE ON THE STACK does each object-pool walker's
# `jsr (A0)` push its return address, and is that longword inside the masked
# dead-stack window?
#
# WHY (14z-91). The obj_hook legacy-cycle regression's fix relocates each
# walker (0x54458 / 0x5E52A, 0x2C bytes) into free space, appends the
# extended type table at copy+0x2C — the site's own `movea.l (0x12,PC,D0.w)`
# displacement lands there BY CONSTRUCTION — and repoints the `jsr <walker>`
# call sites. The vanilla dispatch instruction is never patched, so not one
# instruction is added and not one instruction's timing changes: `jsr abs.l`
# costs the same whatever its operand, `movea.l (d8,PC,Dn.w)` the same
# wherever PC points. That is why this fix is zero-cost BY CONSTRUCTION
# rather than by census (option (b), maintainer 2026-08-15).
#
# EXACTLY ONE BYTE OF STATE DIFFERS: the relocated `jsr (A0)` pushes
# <copy>+0x20 where vanilla pushed <walker>+0x20. Same stack DEPTH, same
# order, same everything else. That longword is invisible to the legacy
# oracle if and only if it lands inside the ratified dead-stack mask window
# RAM:$FF7F00-$FF7FFF (CLAUDE.md §4; docs/game/atlas/ram.md). The push
# occupies [A7-4, A7-1], so the test is:
#
#     min(A7) - 4 >= 0xFF7F00      and      max(A7) <= 0xFF8000
#
# IF THIS FAILS, THE DESIGN STOPS. The answer is NOT to widen the mask —
# that silently redefines the baseline the superset invariant rests on, and
# it would buy a permanent blind spot over live work RAM. Escalate.
#
# DO NOT ASSUME ONE STACK. 14z-89 attributed live divergences to execution
# position at BOTH $FF06B5-$FF06D3 and $FFF991-$FFF9D3, so this engine keeps
# more than one region holding return addresses. The per-page histogram is
# part of the verdict, not decoration: it says where the stack actually is.
#
# COVERAGE. Site 0x54470 fires in only 5 of ~50 corpus replays (the long
# mash/arcade rigs) — the same thin base the dispatch census reports. That
# matters much less here than it does for a deadness claim: this measures
# where the stack IS, not that something never happens, and the stack depth
# at a fixed call site is a structural property of the call chain. Still,
# the per-site replay count is printed so the base is visible.
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=8] [--freeze] tests/audit_walker_ghost.sh
# ~5 min (corpus-wide debug runs, JOBS-parallel).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
JOBS="${JOBS:-8}"
# the `jsr (A0)` of each walker = site + 6 (site = walker + 0x18)
SPSITES="54476,5e548"
FROZEN="build/manifest/walker_ghost.toml"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

names="$(ls tests/expected/vsavj/masked-v2/logs/*.log | xargs -n1 basename | sed 's/\.log$//')"
echo "corpus: $(echo "$names" | wc -w | tr -d ' ') legacy replays (every replay with a vanilla basis log)"
pool=0
for n in $names; do
    rpl="tests/replays/$n.rpl"
    [ -f "$rpl" ] || continue
    lf=$(sed 's/#.*//' "$rpl" | awk 'NF { split($1, r, "-"); f=(r[2]?r[2]:r[1]);
         if (f + 0 > m) m = f + 0 } END { print m + 0 }')
    ( MAME_SANDBOX="$W/sb_$n" REPLAY="$PWD/$rpl" SPSITES="$SPSITES" SP_OUT="$W/$n.txt" \
      FRAMES=$((lf + 120)) MAME_ROMPATH="$ROMDIR" \
      tools/run_mame.sh vsavj -debug -debugger none \
      -autoboot_script "$PWD/tests/lua/walker_sp.lua" >"$W/$n.log" 2>&1 ) &
    pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
wait

W="$W" FROZEN="$FROZEN" python3 - "${1:---check}" <<'PY'
import glob, os, re, sys
W, FROZEN = os.environ["W"], os.environ["FROZEN"]
mode = sys.argv[1]
MASK_LO, MASK_HI = 0xFF7F00, 0xFF8000      # window is [LO, HI), i.e. ..$FF7FFF
sites, per_replay, incomplete = {}, {}, []
nfiles = len(glob.glob(f"{W}/*.txt"))
for f in sorted(glob.glob(f"{W}/*.txt")):
    name = os.path.basename(f)[:-4]
    txt = open(f).read()
    if "SPEND" not in txt:
        incomplete.append(name); continue
    for m in re.finditer(r"SP (\w+) hits (\d+) min (\S+) max (\S+)", txt):
        a, hits = int(m.group(1), 16), int(m.group(2))
        s = sites.setdefault(a, {"hits": 0, "min": None, "max": None,
                                 "live": 0, "pages": {}})
        s["hits"] += hits
        if hits:
            s["live"] += 1
            lo, hi = int(m.group(3), 16), int(m.group(4), 16)
            s["min"] = lo if s["min"] is None else min(s["min"], lo)
            s["max"] = hi if s["max"] is None else max(s["max"], hi)
            per_replay.setdefault(a, []).append((name, hits, lo, hi))
    for m in re.finditer(r"PAGES (\w+) : (.*)", txt):
        a = int(m.group(1), 16)
        if a not in sites: continue
        for tok in m.group(2).split():
            if "=" not in tok: continue
            p, c = tok.split("=")
            sites[a]["pages"][int(p, 16)] = sites[a]["pages"].get(int(p, 16), 0) + int(c)
fail = 0
if incomplete:
    print("  FAIL: incomplete runs: " + ", ".join(incomplete)); fail = 1
frozen = {}
if os.path.exists(FROZEN):
    cur = None
    for ln in open(FROZEN):
        m = re.match(r'site = 0x(\w+)', ln.strip())
        if m: cur = int(m.group(1), 16)
        m = re.match(r'sp_min = 0x(\w+)', ln.strip())
        if m and cur is not None: frozen[cur] = int(m.group(1), 16)
out = ["# build/manifest/walker_ghost.toml — FROZEN stack-depth observation",
       "# at each object-pool walker's `jsr (A0)` (14z-91). Regenerate with",
       "# tests/audit_walker_ghost.sh --freeze. The relocated walker pushes a",
       "# different return address at exactly this depth; it is invisible to",
       "# the legacy oracle only while [sp_min-4, sp_max-1] stays inside the",
       "# masked dead-stack window $FF7F00-$FF7FFF.",
       "schema = 1"]
for a in sorted(sites):
    s = sites[a]
    print(f"\n=== walker jsr at {a:#08x}: {s['hits']:,} dispatches in {s['live']}/{nfiles} replays")
    if s["hits"] == 0:
        print("    FAIL: zero dispatches — dead instrument, not a finding"); fail = 1
        continue
    push_lo, push_hi = s["min"] - 4, s["max"] - 1
    print(f"    A7 range      {s['min']:#08x} .. {s['max']:#08x}")
    print(f"    pushed long   {push_lo:#08x} .. {push_hi:#08x}")
    pg = " ".join(f"{p:#08x}={c:,}" for p, c in sorted(s["pages"].items()))
    print(f"    A7 pages      {pg}")
    if push_lo >= MASK_LO and s["max"] <= MASK_HI:
        print(f"    ok: INSIDE the masked dead-stack window "
              f"{MASK_LO:#08x}-{MASK_HI - 1:#08x} — a relocated walker's return")
        print( "        address is invisible to the legacy oracle here")
    else:
        print(f"    FAIL: OUTSIDE the masked window {MASK_LO:#08x}-{MASK_HI - 1:#08x}.")
        print( "          The relocation would put a differing longword in LIVE work")
        print( "          RAM. STOP — do not widen the mask to accommodate it; that")
        print( "          redefines the baseline the superset invariant rests on.")
        fail = 1
    if s["live"] <= 5:
        print(f"    NOTE: only {s['live']} replays reach this walker — thin base; see header")
        for nm, h, lo, hi in sorted(per_replay.get(a, [])):
            print(f"      {nm:32s} {h:>9,} hits  A7 {lo:#08x}..{hi:#08x}")
    if a in frozen and frozen[a] != s["min"]:
        print(f"    note: sp_min moved {frozen[a]:#08x} -> {s['min']:#08x} since the freeze")
    out += ["", "[[site]]", f"site = 0x{a:05x}", f"sp_min = 0x{s['min']:06x}",
            f"sp_max = 0x{s['max']:06x}", f"hits = {s['hits']}", f"replays = {s['live']}"]
if mode == "--freeze" and not fail:
    open(FROZEN, "w").write("\n".join(out) + "\n")
    print(f"\nFROZE {FROZEN}")
    sys.exit(0)
print("\n" + ("WALKER GHOST: PASS" if not fail else "WALKER GHOST: FAIL"))
sys.exit(fail)
PY
