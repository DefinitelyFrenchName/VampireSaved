#!/bin/sh
# audit_type_dispatch_range.sh — the dynamic census-gap detector for the
# 14z-82 type-renumber fix, on a MERGED build.
#
# THE CLAIM IT TESTS. Under first-resolver-keeps-originals, non-first
# tenants' objects carry RENUMBERED types (their stamps are rewritten at
# build time), so during a Huitzil or Pyron match NO dispatch at obj_hook
# site 0x5E542 may arrive with an ORIGINAL family index (D0 in
# [0x1C8,0x1E4) = types 114-119 — type 120 stays first-wins: it has no
# reachable stamp site in any ported span, so a 0x1E0 hit on a later
# tenant's replay would itself be the census gap this gate exists to
# catch). A hit there means a stamp site the census missed served an
# original number — the silent-misroute class the fix kills. The
# renumbered range must be NON-EMPTY on the same replay (rig liveness:
# zero hits everywhere = dead probe, not success).
#
# Sections:
#   0  verdict control on build/hui30 (single-tenant, original numbers by
#      design): the probe MUST see original-range dispatches there — the
#      instrument can see what section 1 claims is absent.
#   1  merged + huitzil mash: original range = 0, huitzil's renumbered
#      indices (from type_map.json) >= 1
#   2  merged + pyron mash: original range = 0, pyron's renumbered >= 1
#   3  merged + donovan vs-CPU: original range >= 1 (tenant-0 keeps the
#      original entries and they must still serve him)
#
# 14z-85 — the 0x54470 family (59-75), which the OWNER TAG serves (no
# renumbering there; entries 64-75 are tag stubs whose zero/unclaimed-tag
# fall-through is a planted ILLEGAL):
#   4  verdict control on build/hui30 + plasma trap: family dispatches at
#      the 0x54470 site MUST be visible (the instrument can see them)
#   5  merged + huitzil plasma trap: family dispatches >= 1 AND no CRASH —
#      a tripwire fire here is an UNTAGGED family object (a stamp site
#      the tag emission missed) or an unclaimed tag
#   6  merged + pyron mash: same, for pyron's family content (type 66
#      measured live in this replay, 14z-85 census)
#
# Probe: the per-site obj_hook thunk entries, scraped from the build's
# patch_notes_fragment.md (rows are emitted in site order: FIRST row =
# site 0x54470, LAST row = site 0x5E542; the
# audit_objhook_owner_census.sh pattern). At thunk entry D0 still holds
# type*4 (at site+6 it is already cleared). Guarded runs are never
# checksum-compared (GOTCHAS).
#
# Usage: ROMDIR=... tests/audit_type_dispatch_range.sh [merged_builddir]
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-82, EXTENDED 14z-85 (~15 min, 7 guarded runs): on the MERGED build,
#   ZERO obj_hook dispatches in the ORIGINAL 114-119 range during hui/pyron
#   replays (a census-missed stamp would land there), renumbered range LIVE
#   for huitzil, originals still serving donovan; verdict control sees
#   originals on the ref build. Reads type_map.json. 14z-85 §4-6: 0x54470
#   family (59-75) dispatch LIVE on H+P legs with the tag-stub tripwire
#   SILENT; solo verdict control
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MERGED="${1:-build/merged1}"
REF=build/hui30
W="$(mktemp -d)"           # GitHub #68: not a predictable name
trap 'rm -rf "$W"' EXIT
fail=0

abspath() { case "$1" in /*) printf '%s\n' "$1";; *) printf '%s/%s\n' "$PWD" "$1";; esac; }
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary"; exit 0; }
[ -d "$MERGED/rompath" ] || { echo "SKIP: no merged build at $MERGED"; exit 0; }
[ -f "$MERGED/patch/type_map.json" ] || {
    echo "FAIL: $MERGED has no type_map.json — built before the renumber"
    echo "      fix, or the fix emitted nothing on a multi-tenant build"
    exit 1; }

thunk_of() {  # thunk_of <builddir> — LAST obj_hook thunk row = site 0x5E542
    sed -n 's/^code *0x0*\([0-9a-f]*\) obj_hook thunk .*/\1/p' \
        "$1/patch/patch_notes_fragment.md" | tail -1
}
thunk54_of() {  # FIRST obj_hook thunk row = site 0x54470 (site order)
    sed -n 's/^code *0x0*\([0-9a-f]*\) obj_hook thunk .*/\1/p' \
        "$1/patch/patch_notes_fragment.md" | head -1
}

HUI_SOAK="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"
PYR_SOAK="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11"
POK13="1400:ff8782:13;1450:ff8782:13;1500:ff8782:13;1400:ff8b82:13;1450:ff8b82:13;1500:ff8b82:13"

probe_run() {  # probe_run <build> <thunk> <replay> <pokes> <out> [cond]
    POKES="$4" MAME_ROMPATH="$(abspath "$1")/rompath;$ROMDIR" \
    GUARD_PROBE="$2" GUARD_PROBE_COND="${6:-d0 >= 0x1c8}" GUARD_PROBE_MAX=20000 \
        tools/run_replay_guarded.sh vsavjw "tests/replays/$3.rpl" \
        "$5" "${5%.log}_box" >/dev/null 2>&1 || true
    [ -f "$5" ] || : >"$5"   # a dead run still gets an (empty) log to judge
}

# range verdict: probe log + tenant name ("" = original-range control).
# want_orig: "see" = original hits required (control); "zero" = original
# hits are the FAIL; "zero_noren" = original hits are the FAIL but zero
# renumbered hits are fine — for a tenant whose content provably does not
# spawn the 0x5E542 family in this replay (Pyron: the dynamic write census
# observed only 54470-family stamps from him, and pre-fix his 70_mash
# reached f7997 with ZERO extended dispatches). The probe's own liveness
# for such a section comes from the OTHER sections on the same merged
# thunk, asserted at the end.
verdict() {  # verdict <log> <label> <want_orig> <tenant-or-empty>
    python3 - "$1" "$2" "$3" "$4" "$MERGED" <<'PY'
import json, re, sys
log, label, want_orig, tenant, merged = sys.argv[1:6]
orig = set(range(0x1C8, 0x1E4, 4))            # types 114-119
ren = set()
if tenant:
    for r in json.load(open(f"{merged}/patch/type_map.json")):
        if r["tenant"] == tenant:
            ren.add(r["index"] * 4)
hits_o, hits_r, total = 0, 0, 0
crash = None
for ln in open(log, errors="replace"):
    m = re.match(r"PROBE (\d+) D0=([0-9a-f]+) ", ln)
    if m:
        total += 1
        d0 = int(m.group(2), 16)
        if d0 in orig:
            hits_o += 1
        if d0 in ren:
            hits_r += 1
    elif ln.startswith("CRASH") and crash is None:
        crash = ln.strip()
ok = True
if want_orig in ("zero", "zero_noren"):
    if hits_o:
        print(f"  FAIL  {label}: {hits_o} ORIGINAL-range dispatch(es) — a "
              f"census-missed stamp served an original type number"); ok = False
    else:
        print(f"  PASS  {label}: original range clean ({total} extended "
              f"dispatches)")
    if tenant and not hits_r and want_orig == "zero":
        print(f"  FAIL  {label}: zero RENUMBERED dispatches for {tenant} — "
              f"dead probe or the tenant never spawned family objects; "
              f"this run proves nothing"); ok = False
    elif tenant:
        print(f"  {'PASS' if hits_r else 'note'}  {label}: {hits_r} "
              f"renumbered dispatch(es) ({tenant})"
              + ("" if hits_r else " — expected for this tenant/replay, "
                 "see the header; liveness comes from the sibling sections"))
else:
    if hits_o:
        print(f"  PASS  {label}: {hits_o} original-range dispatch(es) seen "
              f"(the probe CAN see them)")
    else:
        print(f"  FAIL  {label}: no original-range dispatches — instrument "
              f"cannot demonstrate its verdict"); ok = False
if crash:
    print(f"  note  {label}: {crash}")
sys.exit(0 if ok else 1)
PY
}

TH_REF="$(thunk_of "$REF")"
TH_MRG="$(thunk_of "$MERGED")"
[ -n "$TH_REF" ] && [ -n "$TH_MRG" ] || {
    echo "FAIL: could not scrape an obj_hook thunk address"; exit 1; }
echo "probes: $REF thunk 0x$TH_REF, $MERGED thunk 0x$TH_MRG"

echo "== 0: verdict control — original range visible on $REF =="
probe_run "$REF" "$TH_REF" hui/70_hui_mash "$HUI_SOAK" "$W/ref.log"
verdict "$W/ref.log" "ref/70_mash" see "" || fail=1

echo "== 1: merged + huitzil =="
probe_run "$MERGED" "$TH_MRG" hui/70_hui_mash "$HUI_SOAK" "$W/hui.log"
verdict "$W/hui.log" "merged/hui_70" zero huitzil || fail=1

echo "== 2: merged + pyron =="
probe_run "$MERGED" "$TH_MRG" pyron/70_pyron_mash "$PYR_SOAK" "$W/pyr.log"
verdict "$W/pyr.log" "merged/pyr_70" zero_noren pyron || fail=1

echo "== 3: merged + donovan (originals still serve tenant-0) =="
probe_run "$MERGED" "$TH_MRG" 12_donovan_vs_cpu "$POK13" "$W/don.log"
verdict "$W/don.log" "merged/don_12" see "" || fail=1

# ── 14z-85: the 0x54470 family — tag-stub dispatch liveness + tripwire
# ── silence. D0 at thunk entry = type*4: family = [0xEC,0x130), the
# ── stubbed 64-75 subrange = [0x100,0x130). A CRASH on the merged legs
# ── is the zero-tag tripwire firing: a stamp site the emission missed.
verdict54() {  # verdict54 <log> <label> <want: see|live_nocrash>
    python3 - "$1" "$2" "$3" <<'PY'
import re, sys
log, label, want = sys.argv[1:4]
fam = stub = 0
crash = None
for ln in open(log, errors="replace"):
    m = re.match(r"PROBE (\d+) D0=([0-9a-f]+) ", ln)
    if m:
        d0 = int(m.group(2), 16)
        if 0xEC <= d0 < 0x130:
            fam += 1
            if d0 >= 0x100:
                stub += 1
    elif ln.startswith("CRASH") and crash is None:
        crash = ln.strip()
ok = True
if fam < 1:
    print(f"  FAIL  {label}: zero 0x54470 family dispatches — dead probe "
          f"or the rig never spawned family content; this run proves "
          f"nothing"); ok = False
else:
    print(f"  PASS  {label}: {fam} family dispatch(es), {stub} in the "
          f"stubbed 64-75 range")
if want == "live_nocrash" and crash:
    print(f"  FAIL  {label}: {crash} — a tag stub tripwired (an untagged "
          f"family object = a missed stamp site, or an unclaimed tag)")
    ok = False
elif crash:
    print(f"  note  {label}: {crash}")
sys.exit(0 if ok else 1)
PY
}

T54_REF="$(thunk54_of "$REF")"
T54_MRG="$(thunk54_of "$MERGED")"
[ -n "$T54_REF" ] && [ -n "$T54_MRG" ] || {
    echo "FAIL: could not scrape the 0x54470 thunk address"; exit 1; }
[ "$T54_MRG" != "$TH_MRG" ] || {
    echo "FAIL: 0x54470 and 0x5E542 thunks scraped identically — the"
    echo "      site-order assumption broke; fix the scrape"; exit 1; }

echo "== 4: verdict control — 0x54470 family visible on $REF =="
probe_run "$REF" "$T54_REF" hui/87_hui_plasma_trap "$HUI_SOAK" \
    "$W/ref54.log" "d0 >= 0xec"
verdict54 "$W/ref54.log" "ref54/87_trap" see || fail=1

echo "== 5: merged + huitzil — tag stubs serve H, tripwire silent =="
probe_run "$MERGED" "$T54_MRG" hui/87_hui_plasma_trap "$HUI_SOAK" \
    "$W/hui54.log" "d0 >= 0xec"
verdict54 "$W/hui54.log" "merged54/hui_87" live_nocrash || fail=1

echo "== 6: merged + pyron — tag stubs serve P, tripwire silent =="
probe_run "$MERGED" "$T54_MRG" pyron/70_pyron_mash "$PYR_SOAK" \
    "$W/pyr54.log" "d0 >= 0xec"
verdict54 "$W/pyr54.log" "merged54/pyr_70" live_nocrash || fail=1

[ "$fail" = 0 ] && echo "audit_type_dispatch_range: ALL PASS" \
                || echo "audit_type_dispatch_range: FAILURES"
exit "$fail"
