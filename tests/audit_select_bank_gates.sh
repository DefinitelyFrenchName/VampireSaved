#!/bin/sh
# audit_select_bank_gates.sh — the merged drawer bank gates must gate EVERY
# declaring tenant's id (14z-84).
#
# THE DEFECT THIS FREEZES OUT (first full-roster playtest, root-caused from
# the placed bodies): the three `*_bank_variant_id` site_thunks are declared
# by all three tenants with a TT id placeholder; merge_manifests deduped the
# textually-identical rows and the thunk emitted once, substituted with
# TENANT 0's id alone — so hovering H or P never flipped the select/VS name
# drawers to bank 5 and their bank-5 tile codes drew host sprite art
# ("names replaced by body-sprite tiles"). The generator now routes shared
# placeholder rows through the N-way chain (displaced-head shape).
#
# Static over the merged build's patch.json + fragment + the manifests
# (~1s, no emulator, no ROMs). GROUND-TRUTHED against the real defect: run
# against the pre-fix build/m3b_merged, every gate FAILed with only 0x13.
#
# Usage: tests/audit_select_bank_gates.sh [merged builddir]
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${1:-build/m3b_merged13}"
[ -f "$BUILD/patch/patch.json" ] || { echo "SKIP: no $BUILD/patch"; exit 0; }

python3 - "$BUILD" <<'PY'
import json, re, sys
build = sys.argv[1]
fail = 0

# declaring tenants per gate, from the manifests (the ground truth the
# merge must honor), and each tenant's id
GATES = {"name_bank_variant_id": "tt", "splash_bank_variant_id": "tt",
         "winquote_bank_variant_id": "tu"}
IDS = {"donovan": 0x13, "huitzil": 0x10, "pyron": 0x11}
declare = {g: [] for g in GATES}
for t in IDS:
    txt = open(f"build/manifest/{t}.toml").read()
    for g in GATES:
        if f'name = "{g}"' in txt:
            declare[g].append(t)

frag = open(f"{build}/patch/patch_notes_fragment.md").read()
ops = json.load(open(f"{build}/patch/patch.json"))["ops"]
by_addr = {int(o["addr"], 16): o for o in ops if "addr" in o and "hex" in o}

for g, ph in sorted(GATES.items()):
    m = re.search(r"code\s+0x([0-9a-f]+)\s+\+0x[0-9a-f]+\s+site_thunk "
                  r"(?:\d+-way chain[^\n]*" + re.escape(g)
                  + r"|" + re.escape(g) + r")", frag)
    if not m:
        # the chain note names all members: find a chain note listing g
        m = re.search(r"code\s+0x([0-9a-f]+)\s+\+0x[0-9a-f]+\s+site_thunk "
                      r"\d+-way chain[^\n]*", frag)
        m = next((mm for mm in re.finditer(
            r"code\s+0x([0-9a-f]+)\s+\+0x[0-9a-f]+\s+site_thunk "
            r"\d+-way chain[^\n]*", frag) if g in mm.group(0)), None)
    if not m:
        print(f"FAIL: {g}: no placed body found in the fragment")
        fail = 1
        continue
    addr = int(m.group(1), 16)
    body = bytes.fromhex(by_addr[addr]["hex"])
    want = {t: (IDS[t] + 0x40 if ph == "tu" else IDS[t]) & 0xFF
            for t in declare[g]}
    missing = [t for t, i in want.items()
               if (b"\x00" + bytes([i])) not in body]
    got = sorted(f"{t}:{i:#04x}" for t, i in want.items() if t not in missing)
    if missing:
        print(f"FAIL: {g} @{addr:#x} ({len(body)} bytes) gates {got} but "
              f"NOT {missing} — a tenant's hover/win will not flip the "
              f"drawer bank")
        fail = 1
    else:
        print(f"  ok: {g} @{addr:#x} ({len(body)} bytes) gates all "
              f"{len(want)} declarers: {got}")
sys.exit(fail)
PY
rc=$?
[ "$rc" = 0 ] && echo "PASS: merged drawer bank gates cover every declarer" \
              || echo "FAIL: merged drawer bank gates"
exit "$rc"
