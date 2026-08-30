#!/bin/sh
# audit_dispatch_census.sh — WHICH type indices does LEGACY ever dispatch at
# the two obj_hook sites, and is the frozen observation still complete?
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
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=8] tests/audit_dispatch_census.sh
# ~2 min (50 short debug runs, JOBS-parallel).
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
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
JOBS="${JOBS:-8}"
SITES="54470:59,5e542:114"
FROZEN="build/manifest/dispatch_census.toml"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT

names="$(ls tests/expected/vsavj/masked-v2/logs/*.log | xargs -n1 basename | sed 's/\.log$//')"
echo "corpus: $(echo "$names" | wc -w | tr -d ' ') legacy replays (every replay with a vanilla basis log)"
pool=0
for n in $names; do
    rpl="tests/replays/$n.rpl"
    [ -f "$rpl" ] || continue
    lf=$(sed 's/#.*//' "$rpl" | awk 'NF { split($1, r, "-"); f=(r[2]?r[2]:r[1]);
         if (f + 0 > m) m = f + 0 } END { print m + 0 }')
    ( MAME_SANDBOX="$W/sb_$n" REPLAY="$PWD/$rpl" SITES="$SITES" CENSUS_OUT="$W/$n.txt" \
      FRAMES=$((lf + 120)) MAME_ROMPATH="$ROMDIR" \
      tools/run_mame.sh vsavj -debug -debugger none \
      -autoboot_script "$PWD/tests/lua/dispatch_census.lua" >"$W/$n.log" 2>&1 ) &
    pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done
wait

W="$W" FROZEN="$FROZEN" python3 - "${1:---check}" <<'PY'
import glob, os, re, sys
W, FROZEN = os.environ["W"], os.environ["FROZEN"]
mode = sys.argv[1]
# RETIRED as a budget (14z-91): nothing is allocated from the complement
# any more — see the header. Kept only so the report still says how many
# entries the tenants add, which is a useful sanity line next to the counts.
NEED = {0x54470: 17, 0x5e542: 10}     # entries the three tenants ADD today
sites, per_replay, incomplete = {}, {}, []
for f in sorted(glob.glob(f"{W}/*.txt")):
    name = os.path.basename(f)[:-4]
    txt = open(f).read()
    if "CENSUSEND" not in txt:
        incomplete.append(name); continue
    for m in re.finditer(r"SITE (\w+) entries (\d+) hits (\d+) seen \d+ : (.*)", txt):
        a, n, hits = int(m.group(1), 16), int(m.group(2)), int(m.group(3))
        s = sites.setdefault(a, {"n": n, "seen": set(), "hits": 0, "live": 0})
        s["hits"] += hits
        if hits:
            s["live"] += 1
            per_replay.setdefault(a, []).append((name, hits, m.group(4)))
        if m.group(4).strip():
            s["seen"].update(int(x) for x in m.group(4).split(","))
fail = 0
if incomplete:
    print("  FAIL: incomplete census runs: " + ", ".join(incomplete)); fail = 1
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
        print("    FAIL: zero dispatches — dead instrument, not a finding"); fail = 1
    out += ["", "[[site]]", f"site = 0x{a:05x}", f"entries = {s['n']}",
            f"observed = [{','.join(str(x) for x in seen)}]"]
if mode == "--freeze":
    open(FROZEN, "w").write("\n".join(out) + "\n")
    print(f"\nFROZE {FROZEN}")
    sys.exit(0)
print("\n" + ("DISPATCH CENSUS: PASS" if not fail else "DISPATCH CENSUS: FAIL"))
sys.exit(fail)
PY
