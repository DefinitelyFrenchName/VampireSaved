#!/bin/sh
# test_df_startup_provenance.sh — THE TENANTS' DARK FORCE STARTUP WINDOWS ARE
# CAPCOM'S OWN, CARRIED FROM vs2/vh2 — the three-way ROM agreement that backs
# the preservation claim, frozen (14z-126).
#
# WHY. tests/audit_df_startup_invuln.sh measured that each character's
# seq-0x16 Dark Force handler (the row of dispatch_16, PRG:0x0BF31A) arms the
# victim's invincibility timer +0x147 with its own value, and that the
# tenants arm Huitzil 0x4F / Pyron 0x29 / Donovan 0x40 from their own vs2
# handlers. The maintainer asked WHERE those values come from, given native
# vs2 shows no window. The answer this gate locks: the whole VS-style
# seq-0x16 DF family was carried into vs2 and vh2 for ALL 18 characters and
# then made unreachable there (the vs2 activation body clears seq 0x16 the
# same frame, [VSE-69]); the 15 vanilla rows arm the SAME value in vsavj,
# vsav2 and vhunt2, and the three tenant rows arm the same value in vsav2
# and vhunt2 (their handlers differ only by pointer-shifted operands), which
# is NOT the value of the vsavj row they alias (Bulleta/Demitri/Victor). So
# the port, by repointing the tenants' rows to their own handlers, restored
# Capcom's own numbers for them — the maintainer's preservation assessment
# (STATE 14z-126) rests on exactly these equalities.
#
# WHAT IT ASSERTS (static, the decrypted opcode views, seconds):
#   1. every vanilla row 0x00-0x0F whose handler arms +0x147 in its first
#      0xA0 bytes arms the SAME value in all three sets (Lei-Lei arms hers
#      deeper — outside this static window, measured live instead);
#   2. rows 0x10/0x11/0x13 arm 0x4F / 0x29 / 0x40 in BOTH vsav2 and vhunt2,
#      and vsavj's rows 0x10/0x11/0x13 are ALIASES of its rows 0x00/0x01/0x03
#      (the inheritance the port undoes);
#   3. on the current merged WIDE build the placed handlers those rows point
#      at arm the same three values (the port carried them unchanged);
#   4. must-fire control: a perturbed expected value is caught.
#
# Usage: ROMDIR=... [BUILD=build/m3b_merged21] tests/test_df_startup_provenance.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged21}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
. "$REPO/tests/lib/decrypt_cache.sh"
for s in vsavj vsav2 vhunt2; do decrypt_view "$s" "$W/${s}_op.bin" "$W/${s}_data.bin"; done
MERGED_OP=""
[ -f "$BUILD/verify_op.bin" ] && MERGED_OP="$BUILD/verify_op.bin"

python3 - "$W" "$MERGED_OP" <<'PY' || { echo "FAIL: DF startup provenance"; exit 1; }
import sys, struct
W, MERGED = sys.argv[1], sys.argv[2]
ORIG = {"vsavj": 0x0BD0FA, "vsav2": 0x0D7298, "vhunt2": 0x0D6B2A}   # bank_map.toml [origins]
D16_VSAVJ = 0x0BF31A                                                 # dispatch_16 in vsavj
TENANT = {0x10: 0x4F, 0x11: 0x29, 0x13: 0x40}                        # Huitzil / Pyron / Donovan
SHELL = {0x10: 0x00, 0x11: 0x01, 0x13: 0x03}
WIN = 0xA0
errs = []

def rows(name):
    img = open(f"{W}/{name}_data.bin", "rb").read()
    base = D16_VSAVJ - ORIG["vsavj"] + ORIG[name]
    return [struct.unpack(">I", img[base + 4*i:base + 4*i + 4])[0] for i in range(32)]

def first_arm(op, addr, win=WIN):
    """the first `move.b #imm,$147(a6)` (1D7C 00ii 0147) in [addr, addr+win), decoded
    by opcode-word scan — capstone-free so the gate has no extra dependency."""
    blob = op[addr:addr + win]
    for i in range(0, len(blob) - 5, 2):
        if blob[i:i+2] == b"\x1d\x7c" and blob[i+2] == 0x00 and blob[i+4:i+6] == b"\x01\x47":
            return blob[i+3]
    return None

OP = {n: open(f"{W}/{n}_op.bin", "rb").read() for n in ORIG}
R = {n: rows(n) for n in ORIG}
table = {}
for i in range(0x10):
    vals = {n: first_arm(OP[n], R[n][i]) for n in ORIG}
    table[i] = vals
    found = {n: v for n, v in vals.items() if v is not None}
    if len(found) < 3:
        print(f"  row {i:02x}: static arm not in the first 0x{WIN:x} bytes on {sorted(set(ORIG) - set(found))} — measured live by audit_df_startup_invuln")
        continue
    if len(set(found.values())) != 1:
        errs.append(f"row {i:02x}: the three sets disagree: " + ", ".join(f"{n}=0x{v:02x}" for n, v in found.items()))
    else:
        print(f"  row {i:02x}: 0x{vals['vsavj']:02x} in vsavj, vsav2 and vhunt2")
def check_tenants(expect, out):
    ok = True
    for i, want in expect.items():
        for n in ("vsav2", "vhunt2"):
            got = first_arm(OP[n], R[n][i])
            if got != want:
                out.append(f"row {i:02x} on {n}: arm {got} != expected 0x{want:02x}"); ok = False
        if R["vsavj"][i] != R["vsavj"][SHELL[i]]:
            out.append(f"vsavj row {i:02x} does not alias row {SHELL[i]:02x} (0x{R['vsavj'][i]:06x} vs 0x{R['vsavj'][SHELL[i]]:06x})"); ok = False
    return ok
if check_tenants(TENANT, errs):
    print("  tenants: vsav2 == vhunt2 == {Huitzil 0x4f, Pyron 0x29, Donovan 0x40}; vsavj rows 10/11/13 alias 00/01/03")
if MERGED:
    mop = open(MERGED, "rb").read()
    mrows = [struct.unpack(">I", mop[D16_VSAVJ + 4*i:D16_VSAVJ + 4*i + 4])[0] for i in range(32)]
    # the table itself is read as DATA; on the built image the data view of the
    # crypt range is not this file — take the rows from verify_data.bin beside it
    import os
    mdata = open(os.path.join(os.path.dirname(MERGED), "verify_data.bin"), "rb").read()
    mrows = [struct.unpack(">I", mdata[D16_VSAVJ + 4*i:D16_VSAVJ + 4*i + 4])[0] for i in range(32)]
    for i, want in TENANT.items():
        got = first_arm(mop, mrows[i])
        if got != want:
            errs.append(f"merged build row {i:02x} -> 0x{mrows[i]:06x} arms {got}, expected 0x{want:02x}")
        else:
            print(f"  merged build row {i:02x} -> 0x{mrows[i]:06x} arms 0x{want:02x} (the vs2 value, carried)")
else:
    print("  (no BUILD verify_op.bin — the built-image leg skipped; the ROM legs still assert)")
# must-fire control
ctl = []
bad = dict(TENANT); bad[0x13] = 0x41
if check_tenants(bad, ctl): errs.append("CONTROL: a perturbed expected value was NOT caught")
else: print("  control: perturbed expectation caught (must-fire)")
for e in errs: print("  FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS test_df_startup_provenance"
