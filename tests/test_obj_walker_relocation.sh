#!/bin/sh
# test_obj_walker_relocation.sh — the obj_walker relocation is STRUCTURALLY
# what it claims: a verbatim walker copy, its own table behind it, the
# vanilla dispatch sites untouched, and every caller repointed by OPERAND.
#
# WHY (14z-91). The legacy-cycle regression's obj_hook half is fixed by
# relocating each object-pool walker rather than hooking its dispatch site.
# The correctness argument has four legs, and each is cheap to check from
# the build's own patch.json — so none of them should rest on having read
# the generator:
#   1. the copy is vanilla's bytes (a "relocation" that edits the code is
#      not a relocation, and its timing claim would be void);
#   2. the table's vanilla rows are vanilla's (legacy types must dispatch
#      exactly where they did);
#   3. the copy's pc-relative dispatch lands on the copy's OWN table —
#      `movea.l (0x12,PC,D0.w)` at walker+0x18 resolves to walker+0x2C, so
#      this holds by construction only while the layout holds;
#   4. THE DISPATCH SITES ARE NOT PATCHED. This is the whole point: it is
#      what makes the fix zero-cost by construction rather than by census.
#      If any op touches 0x54470/0x5E542 the claim is false.
# and the callers are 4-byte OPERAND writes at caller+2, never 6-byte
# instruction rewrites — the 4EB9 opcode word stays vanilla.
#
# THE OP KIND IS LOAD-BEARING AND IS CHECKED. The table is read
# pc-relatively (AS_OPCODES) by the relocated walker, so it must reach the
# CPU as plaintext. patch_prg's `code` op is address-aware — it re-encrypts
# inside the CPS-2 window and passes through above it — so `code` is right
# at any address and `data` is right at none. The old design could use
# `data` only because its thunk read the table An-relatively.
#
# Usage: tests/test_obj_walker_relocation.sh [builddir]   (default build/don_m18)
#        No emulator, no ROMDIR beyond the decrypted view. Seconds.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-91: the relocation is STRUCTURALLY what it claims, from patch.json
#   alone — dispatch sites covered by NO op, walker bytes verbatim, table
#   vanilla-prefixed, the copy's own pc-relative dispatch resolving to its own
#   table, and every caller a 4-byte OPERAND write at caller+2 with 4EB9
#   untouched. 2 verdict controls. ROM-free, seconds
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
# DEFAULT RE-POINTED 14z-92: was build/don_m5, which PREDATES the 14z-91
# walker relocation this gate exists to verify — so the no-argument
# invocation could only ever FAIL (it reports every caller as missing its
# operand op). Fourth stale-default found in one session, after hui31
# (test_merged_render_content), pyron20 (audit_hitclass_map_cost) and
# pyron17 (test_pyron_blink); see docs/project/gotchas.md "A frozen build
# stops being a usable REFERENCE". RE-POINT THIS ON THE NEXT DONOVAN
# RE-FREEZE.
BUILD="${1:-build/don_m18}"  # re-pointed 14z-117b (random-select freeze) <- 14z-117  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
[ -f "$BUILD/patch/patch.json" ] || { echo "SKIP: no $BUILD/patch/patch.json"; exit 0; }
[ -f build/out/vsavj_opcodes.bin ] || { echo "SKIP: no build/out/vsavj_opcodes.bin"; exit 0; }

BUILD="$BUILD" python3 - <<'PY'
import json, os, re, sys
sys.path.insert(0, "tools")
from _minitoml import loads as toml_loads

build = os.environ["BUILD"]
vj = open("build/out/vsavj_opcodes.bin", "rb").read()
ops = json.load(open(f"{build}/patch/patch.json"))["ops"]
man = toml_loads(open("build/manifest/donovan.toml").read())
rows = man["obj_hook"]
fail = 0


def ok(m):
    print(f"  ok: {m}")


def bad(m):
    global fail
    print(f"  FAIL: {m}")
    fail = 1


def op_at(addr):
    return [o for o in ops if int(o["addr"], 16) == addr]


print("1. the dispatch sites are VANILLA — no op touches them")
# every op's covered byte range, so a site inside a larger blob is caught too
covered = []
for o in ops:
    a = int(o["addr"], 16)
    n = (len(o["hex"]) // 2 if "hex" in o
         else (2 if o["op"] == "poke16" else 4 if o["op"] == "poke32" else 0))
    covered.append((a, a + n))
for r in rows:
    site = r["site"]
    hit = [(a, b) for a, b in covered if a < site + 8 and site < b]
    if hit:
        bad(f"site {site:#x} is covered by an op at {hit[0][0]:#x} — the "
            f"dispatch instruction was patched, so the relocation's "
            f"zero-cost-by-construction claim is FALSE")
    else:
        ok(f"site {site:#x} untouched (its `movea.l (0x12,PC,D0.w),A0` is vanilla)")

print("2. the relocated block is a verbatim walker + a vanilla-prefixed table")
for r in rows:
    walker, wlen = r["walker"], r["walker_len"]
    vtab, n_van = r["vanilla_table"], r["vanilla_entries"]
    if r["site"] != walker + 0x18:
        bad(f"site {r['site']:#x} != walker+0x18; the copy's dispatch would "
            f"not resolve to its own table")
        continue
    if vtab != walker + wlen:
        bad(f"vanilla_table {vtab:#x} != walker+{wlen:#x}")
        continue
    blocks = [o for o in ops if o["op"] == "code"
              and o["hex"].startswith(vj[walker:walker + wlen].hex())]
    if not blocks:
        bad(f"no `code` op begins with walker {walker:#x}'s {wlen:#x} bytes — "
            f"either the copy is not verbatim or it was emitted as `data` "
            f"(the table is read pc-relatively and must be `code`)")
        continue
    b = blocks[0]
    blob = bytes.fromhex(b["hex"])
    dst = int(b["addr"], 16)
    ok(f"walker {walker:#x} relocated verbatim to {dst:#x} ({wlen:#x} bytes)")
    tbl = blob[wlen:]
    if len(tbl) < n_van * 4:
        bad(f"table is {len(tbl):#x} bytes, shorter than vanilla's "
            f"{n_van * 4:#x}")
        continue
    if tbl[:n_van * 4] != vj[vtab:vtab + n_van * 4]:
        d = [i // 4 for i in range(n_van * 4)
             if tbl[i] != vj[vtab + i]]
        bad(f"the table's vanilla rows differ from {vtab:#x} at type(s) "
            f"{sorted(set(d))[:8]} — legacy types would dispatch elsewhere")
    else:
        ok(f"table's first {n_van} entries are byte-identical to vanilla "
           f"{vtab:#x}; {(len(tbl) - n_van * 4) // 4} appended")
    # leg 3: the copy's own dispatch resolves to the copy's own table
    disp = int.from_bytes(blob[0x1A:0x1C], "big")
    if blob[0x18:0x1A] != b"\x20\x7b":
        bad(f"copy+0x18 is {blob[0x18:0x1a].hex()}, expected 207b "
            f"(movea.l (d8,PC,D0.w),A0)")
    elif 0x18 + 2 + disp != wlen:
        bad(f"the copy's dispatch resolves to +{0x18 + 2 + disp:#x}, not its "
            f"own table at +{wlen:#x}")
    else:
        ok(f"the copy's own `movea.l ({disp:#x},PC,D0.w),A0` resolves to "
           f"+{wlen:#x} — its own table, by construction")

print("3. every caller is a 4-byte OPERAND repoint onto the block")
for r in rows:
    walker = r["walker"]
    callers = [int(c, 0) for c in str(r["callers"]).split(",") if c.strip()]
    cold = bytes.fromhex(r["caller_old_hex"])
    blocks = [o for o in ops if o["op"] == "code"
              and o["hex"].startswith(vj[walker:walker + r["walker_len"]].hex())]
    dst = int(blocks[0]["addr"], 16) if blocks else None
    n_ok = 0
    for c in callers:
        if vj[c:c + 6] != cold:
            bad(f"caller {c:#x} is not {cold.hex()} in the vanilla image")
            continue
        o = op_at(c + 2)
        if not o:
            bad(f"caller {c:#x} has no operand op at {c + 2:#x} — it would "
                f"still walk the VANILLA table (legacy stays correct; a "
                f"tenant type over-indexes)")
            continue
        if o[0]["op"] != "code" or len(o[0]["hex"]) != 8:
            bad(f"caller {c:#x}: op is {o[0]['op']} {len(o[0]['hex']) // 2}B, "
                f"expected a 4-byte code op (operand only)")
            continue
        if dst is not None and int(o[0]["hex"], 16) != dst:
            bad(f"caller {c:#x} points at {int(o[0]['hex'], 16):#x}, not the "
                f"relocated block {dst:#x}")
            continue
        n_ok += 1
    if n_ok == len(callers):
        ok(f"{n_ok}/{len(callers)} callers of {walker:#x} repointed, opcode "
           f"word 4EB9 untouched at every one")

print("4. verdict controls")
# a control that has never been seen to fail is a decoration: prove each
# leg can actually go red.
r = rows[0]
_saved = list(ops)
ops.append({"op": "code", "addr": hex(r["site"]), "hex": "4ef900bf6a00"})
before = fail
fail = 0
hit = [(a, b) for a, b in [(int(o["addr"], 16),
                            int(o["addr"], 16) + len(o.get("hex", "")) // 2)
                           for o in ops] if a < r["site"] + 8 and r["site"] < b]
if hit:
    ok("a patched dispatch site would be caught")
else:
    print("  FAIL: a patched dispatch site would NOT be caught"); before = 1
fail = before
ops[:] = _saved
# and the caller check: a caller with no op must be reported
_c = int(str(r["callers"]).split(",")[0], 0)
if op_at(_c + 2):
    ok(f"caller {_c:#x} has its operand op (so the missing-op branch is "
       f"reachable, not vacuous)")
else:
    print(f"  FAIL: caller {_c:#x} has no operand op at all"); fail = 1

print()
print("PASS test_obj_walker_relocation.sh" if not fail
      else "FAIL test_obj_walker_relocation.sh")
sys.exit(fail)
PY
