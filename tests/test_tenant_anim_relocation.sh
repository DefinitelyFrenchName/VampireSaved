#!/bin/sh
# test_tenant_anim_relocation.sh — EVERY SPRITE-RECORD POINTER IN A TENANT'S
# PLACED ANIM CHAINS IS RELOCATED (14z-126b). ci_static: needs the tenant
# build dirs, no ROMDIR, no emulator, ~5 s.
#
# THE DEFECT CLASS IT LOCKS. A tenant's animation is extracted from vs2 and
# PLACED elsewhere in the built image (Donovan: vs2 `PRG:0x27F548` ->
# `PRG:0x0D3070`, 135,424 bytes). Every node's sprite-record pointer at +4 must be rewritten by
# the placement delta. One left at its SOURCE value does not fault — 68k tile
# codes cannot fault — it silently resolves to whatever VSAVJ has at that
# address and draws vanilla art in a tenant's move. The builder documents the
# family in its own comment (`gen_donovan_patch.py`: "Effect/low codes stay
# untouched ... they render garbled, never crash"), and no gate measured it.
#
# WHY IT EXISTS. #112 (Donovan's Press of Death drawing a black foot) sent two
# sessions after exactly this shape. The measurement that finally excluded it
# — walk the chains, classify every pointer — was a throwaway script; this is
# it captured ([VSP-18]). It reports a CLEAN result today (3722/3722 for
# Donovan), so it is a lock, not a bug hunt: it is what makes "the port does
# not point a tenant at vanilla records" a standing fact instead of a
# one-session measurement.
#
# THE 24-BIT MASK IS LOAD-BEARING. The sprite field's top byte carries FLAGS
# (values like `0x010E4C7C`, `0x020F10B8` are seen on real nodes). 68k
# addresses are 24-bit, so the classifier masks `& 0xFFFFFF` before deciding.
# Without the mask three legitimate Donovan nodes read as wild pointers — the
# first run of this check reported exactly that, and it was the measurement
# that was wrong, not the build ([VSP-148]).
#
# SECTIONS
#   1 HARD  no sprite pointer lands in the tenant's own vs2 SOURCE range
#           (the unrelocated-pointer defect).
#   2 REPORTED, NOT ASSERTED  pointers landing outside the placed region.
#           These are dominated by WALK OVERRUN: the walker takes a seq count
#           that overruns some tables' real per-character entry count and then
#           follows word offsets into unrelated data (Huitzil's anim_index_c:
#           69 of 139 chains end `out_of_region`, "sprites" like 0x159a15fa on
#           nodes reading dur 0 / flags 0 — [VSP-70]'s shape). Asserting on
#           them would gate the INSTRUMENT, not the build; the first draft of
#           this gate did exactly that and went red on two tenants that have
#           no defect. Section 1 is unaffected and stays conservative — it
#           scans every emitted node, garbage included.
#
# MUST-FIRE CONTROL: a COPY of the tenant's verify_data.bin with ONE node's
# +4 rewritten to a source-range address must FAIL section 1. The gate never
# writes into a build dir.
#
# Env: BUILDS="don_m19 hui53 pyron37" to re-point at another freeze.
set -u
cd "$(dirname "$0")/.."
BUILDS="${BUILDS:-don_m20 hui54 pyron38}"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== test_tenant_anim_relocation: tenant anim pointers are relocated =="

present=0
for b in $BUILDS; do
    [ -f "build/$b/verify_data.bin" ] && [ -f "build/$b/patch/placements.json" ] \
        && [ -f "build/$b/extract/regions.json" ] && present=$((present+1))
done
if [ "$present" = 0 ]; then
    echo "SKIP: none of the tenant build dirs are present ($BUILDS)"
    exit 0
fi

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

for b in $BUILDS; do
    D="build/$b"
    if [ ! -f "$D/verify_data.bin" ] || [ ! -f "$D/patch/placements.json" ] \
       || [ ! -f "$D/extract/regions.json" ]; then
        echo "  skip  $b (build dir absent or incomplete)"; continue
    fi
    python3 tools/anim_reloc_audit.py "$D" --json "$W/$b.json" > "$W/$b.log" 2>&1
    rc=$?
    if [ "$rc" != 0 ]; then
        bad "$b: the audit itself failed:"; sed 's/^/        /' "$W/$b.log" | head -8; continue
    fi
    sed 's/^/  /' "$W/$b.log"
    python3 - "$W/$b.json" "$b" <<'PY' || fail=1
import json, sys
d = json.load(open(sys.argv[1])); name = sys.argv[2]
if d["in_source_range"]:
    print(f"  FAIL  {name}: {len(d['in_source_range'])} UNRELOCATED sprite pointer(s) "
          f"in the vs2 source range: {[hex(a) for a in d['in_source_range'][:8]]}")
    sys.exit(1)
if d["outside_placed"]:
    print(f"  note  {name}: {len(d['outside_placed'])} pointer(s) outside the placed "
          f"region — WALK OVERRUN, not asserted (see the tool's header)")
PY
done

# --- must-fire control: plant ONE unrelocated pointer in a COPY ------------
# The copy carries the tenant's real placements/regions and a verify_data.bin
# with ONE node's +4 rewritten to a source-range address. Nothing under
# build/ is written.
CTL=""
for b in $BUILDS; do [ -f "build/$b/verify_data.bin" ] && { CTL="$b"; break; }; done
if [ -n "$CTL" ]; then
    mkdir -p "$W/ctl/patch" "$W/ctl/extract"
    cp "build/$CTL/patch/placements.json" "$W/ctl/patch/"
    cp "build/$CTL/extract/regions.json"  "$W/ctl/extract/"
    python3 tools/plant_anim_reloc_control.py "build/$CTL" "$W/ctl" "$W/$CTL.json" \
        > "$W/ctl.plant.log" 2>&1
    if [ $? = 0 ]; then
        python3 tools/anim_reloc_audit.py "$W/ctl" --json "$W/ctl.json" >/dev/null 2>&1
        n=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["in_source_range"]))' "$W/ctl.json" 2>/dev/null || echo 0)
        if [ "$n" != 0 ]; then
            ok "control: a planted source-range pointer is detected ($CTL)"
        else
            bad "control: a planted source-range pointer was NOT detected — the check is vacuous"
        fi
    else
        bad "control: could not build the perturbed copy:"; sed 's/^/        /' "$W/ctl.plant.log" | head -6
    fi
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
