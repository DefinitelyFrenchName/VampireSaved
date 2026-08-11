#!/bin/sh
# test_tenant_loop.sh — the N-tenant loop ITERATES, and it is inert at N=1.
#
# WHY (M3b, 14z-80). main()'s body is now the body of a loop over the
# tenants. For one tenant the loop runs once and every byte is unchanged —
# which is the whole safety argument, and also the whole blind spot: a loop
# that silently ran once, or that emitted every later tenant's rows against
# tenant 0's data, would leave the four frozen fingerprints green too. That
# is the same gap tests/test_tenant_row_owner.sh exists for, one level up:
# `test_m3a_reproducible.sh` proves the values did not move; this proves the
# loop is real.
#
# THE INSTRUMENT IS THE GENERATOR ALONE, against extract dirs that already
# exist (the test_tenant_row_owner.sh pattern) — seconds per run instead of
# a four-minute rebuild, and no emulator. It SKIPs when the extractions are
# absent, since build dirs are untracked.
#
# WHAT IT DOES **NOT** CLAIM. A merged patch is generated, not applied: the
# ops still collide at the shared engine sites, and section 5 freezes that
# inventory rather than hiding it. "The generator can emit N tenants" and
# "a merged ROM builds" are different statements and this file only makes
# the first.
#
# SECTION 4 IS HERE BECAUSE THE FIRST VERSION OF THIS FILE COULD NOT SEE
# THE DEFECT IT GUARDS. Every other section was green while a merged build
# left two tenants' shared regions holding the wrong OBJ bank — a blob
# patch emits no op, so no count moved. Read its header before trusting a
# green run of the others.
#
# Usage: ROMDIR=... tests/test_tenant_loop.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"

D_EX=build/m5_wide/extract      # donovan  (the WIDE reference)
H_EX=build/hui29/extract        # huitzil  (huitzil-m3)
P_EX=build/pyron20/extract      # pyron    (pyron-m2)

for e in "$D_EX" "$H_EX" "$P_EX"; do
    if [ ! -d "$e" ]; then
        echo "SKIP: no extract dir at $e (build dirs are untracked)."
        echo "      Make them with tools/build_donovan.sh — see HANDOFF.md."
        exit 0
    fi
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM
fail=0

gen1() {  # gen1 <out> <extract> <manifest>  — one tenant
    rm -rf "$1"; mkdir -p "$1"
    python3 tools/gen_donovan_patch.py "$2" "$1" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 --port "$3" \
        --profile cps2-wide-v1 --allow-plausible --tripwire-open \
        > "$1.log" 2>&1 || true
    ( cd "$1" && find . -type f | sort | xargs shasum 2>/dev/null ) > "$1.sums" || true
}
gen2() {  # gen2 <out> — donovan + huitzil
    rm -rf "$1"; mkdir -p "$1"
    python3 tools/gen_donovan_patch.py "$D_EX" "$1" --extract "$H_EX" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
        --port build/manifest/donovan.toml --port build/manifest/huitzil.toml \
        --profile cps2-wide-v1 --allow-plausible --tripwire-open \
        > "$1.log" 2>&1 || true
}
gen3() {  # gen3 <out> — all three
    rm -rf "$1"; mkdir -p "$1"
    python3 tools/gen_donovan_patch.py "$D_EX" "$1" \
        --extract "$H_EX" --extract "$P_EX" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
        --port build/manifest/donovan.toml --port build/manifest/huitzil.toml \
        --port build/manifest/pyron.toml \
        --profile cps2-wide-v1 --allow-plausible --tripwire-open \
        > "$1.log" 2>&1 || true
}

nops() { python3 -c "import json,sys;print(len(json.load(open(sys.argv[1]))['ops']))" "$1/patch.json"; }

# ── 0: determinism, so every later "it changed" verdict means something ──
echo "== 0: the instrument's own ground truth =="
gen1 "$WORK/d1" "$D_EX" build/manifest/donovan.toml
gen1 "$WORK/d2" "$D_EX" build/manifest/donovan.toml
if [ ! -f "$WORK/d1/patch.json" ]; then
    echo "  FAIL: the 1-tenant run produced no patch.json"; tail -5 "$WORK/d1.log"; exit 1
fi
if cmp -s "$WORK/d1.sums" "$WORK/d2.sums"; then
    echo "  ok: two 1-tenant runs agree byte-for-byte ($(nops "$WORK/d1") ops)"
else
    echo "  FAIL: two identical runs disagree — the generator is not"
    echo "        deterministic and nothing below is measuring the loop"
    exit 1
fi

# ── 1: N=1 is inert for EVERY tenant, not just the reference ────────────
# Three independent manifests exercise disjoint sections (only H declares
# data_in_code/code_ptr, only D declares sound_table/region_fix), so three
# passes are three different proofs that the iteration gate did not drop a
# section it happens not to reach on Donovan.
echo "== 1: one tenant per run — the frozen op counts =="
FROZEN_1="donovan:243 huitzil:259 pyron:205"
for row in $FROZEN_1; do
    who="${row%%:*}"; want="${row##*:}"
    case "$who" in donovan) ex="$D_EX" ;; huitzil) ex="$H_EX" ;; *) ex="$P_EX" ;; esac
    gen1 "$WORK/$who" "$ex" "build/manifest/$who.toml"
    if [ ! -f "$WORK/$who/patch.json" ]; then
        echo "  FAIL: $who produced no patch.json"; tail -3 "$WORK/$who.log"; fail=1; continue
    fi
    got="$(nops "$WORK/$who")"
    if [ "$got" = "$want" ]; then echo "  ok: $who $got ops"
    else echo "  FAIL: $who $got ops, frozen at $want"; fail=1; fi
    # tenant 0 keeps the historical side-file spelling: no name may carry a
    # tenant suffix on a single-tenant build, or every consumer breaks.
    if ls "$WORK/$who" | grep -q "\.$who\."; then
        echo "  FAIL: $who emitted per-tenant side-file names at N=1"; fail=1
    fi
done

# ── 2: the loop actually ITERATES ───────────────────────────────────────
# The load-bearing question. A loop that ran once would produce Donovan's
# 243 ops here; a loop that ran twice against tenant 0's data would produce
# 243 twice over. The counts are frozen, and so is the DEDUP they imply:
# 243 + 259 = 502 declared, 440 emitted. The gap is three things and all of
# them are checked below: rows recognised as SHARED and emitted once (the
# iteration gate), tripwire ops no longer needed because the engine union
# resolves Huitzil's handlers (4b), and agreeing duplicate ops dropped (4c).
# Same arithmetic for three.
echo "== 2: N tenants — the loop iterates and shared rows emit once =="
gen2 "$WORK/two"
gen3 "$WORK/three"
check_n() {  # check_n <label> <dir> <want ops> <sum of 1-tenant counts>
    if ! grep -q "GENERATION OK" "$2.log"; then
        echo "  FAIL: $1 did not generate:"; tail -4 "$2.log"; fail=1; return
    fi
    got="$(nops "$2")"
    if [ "$got" = "$3" ]; then
        echo "  ok: $1 $got ops (of $4 declared — $(( $4 - $3 )) shared rows deduped)"
    else
        echo "  FAIL: $1 $got ops, frozen at $3"; fail=1
    fi
}
check_n "2 tenants" "$WORK/two"   440 502
check_n "3 tenants" "$WORK/three" 598 707

# ── 3: every tenant's own content is present ────────────────────────────
# An op count alone cannot tell "both tenants ran" from "tenant 0 ran twice".
# placements.json carries each tenant's placed regions, tenant 1+ suffixed.
echo "== 3: each tenant's regions and side files are really there =="
python3 - "$WORK/three" <<'PY' || fail=1
import json, os, sys
d = sys.argv[1]
pl = json.load(open(os.path.join(d, "placements.json")))["regions"]
bad = []
own = {"donovan": [k for k in pl if "@" not in k],
       "huitzil": [k for k in pl if k.endswith("@huitzil")],
       "pyron":   [k for k in pl if k.endswith("@pyron")]}
for who, keys in own.items():
    if len(keys) < 8:
        bad.append("%s has only %d placed regions" % (who, len(keys)))
# the shared NAMES must be distinct SPANS — that is why they are suffixed
for nm in ("x026142", "x028122", "x05c800", "x2b7ef4"):
    dsts = {pl[k]["dst"] for k in pl if k.split("@")[0] == nm}
    if len(dsts) < 2:
        bad.append("%s: %d distinct placements across tenants — the shared "
                   "region names collapsed" % (nm, len(dsts)))
files = os.listdir(d)
for who in ("huitzil", "pyron"):
    if not any(("." + who + ".") in f for f in files):
        bad.append("no side file carries %s's name" % who)
ten = json.load(open(os.path.join(d, "tenants.json")))
if [t["name"] for t in ten] != ["donovan", "huitzil", "pyron"]:
    bad.append("tenants.json: %r" % [t["name"] for t in ten])
if [t["id"] for t in ten] != [0x13, 0x10, 0x11]:
    bad.append("tenants.json ids: %r" % [hex(t["id"]) for t in ten])
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: 3 tenants' regions placed at distinct addresses, "
          "per-tenant side files, tenants.json in declaration order")
sys.exit(1 if bad else 0)
PY

# ── 4: SHARED region-scoped rows reach EVERY tenant's copy ──────────────
# This section exists because the first version of this gate could not see
# the defect it was meant to guard. 14z-80b shipped the iteration gate as
# "unowned row => iteration 0", which is right for a row that patches one
# engine address and WRONG for a row that names a REGION: every tenant keeps
# its own copy of the shared source spans (14z-78b), so such a row has to be
# applied to every copy. Emitted on iteration 0 alone, the six shared
# port_patch OBJ bank setters patched only Donovan's x05c800/x088512 and left
# Huitzil's and Pyron's holding vs2's bank 3 — the wrong graphics bank,
# silently. Sections 0-3 and 5 were ALL GREEN with that defect present, and
# the op count did not move (a blob patch emits no op), so nothing here could
# have caught it. It is measured directly now.
echo "== 4: shared region-scoped rows applied to every tenant's copy =="
python3 - "$WORK/three" <<'PY' || fail=1
import importlib.util, json, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("g", "tools/gen_donovan_patch.py")
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
out = Path(sys.argv[1])

docs = []
for p in ("donovan", "huitzil", "pyron"):
    d = g.toml_loads(Path("build/manifest/%s.toml" % p).read_text())
    g.stamp_owner(d, g.manifest_owner(d)); docs.append(d)
merged, _ = g.merge_manifests(docs, "cps2-wide-v1")
shared = [r for r in merged["port_patch"] if r.get("_owner") is None]

TENANTS = (("donovan", "build/m5_wide/extract", 0x13, ""),
           ("huitzil", "build/hui29/extract",   0x10, ".huitzil"),
           ("pyron",   "build/pyron20/extract", 0x11, ".pyron"))
bad, checked = [], 0
if len(shared) < 6:
    bad.append("only %d shared port_patch rows — the fixture moved" % len(shared))
for who, ex, tid, suffix in TENANTS:
    regions = json.loads(Path(ex, "regions.json").read_text())["regions"]
    for row in shared:
        nm = row["region"]
        if nm not in regions:
            continue
        blob = out / ("fixed_%s%s.bin" % (nm, suffix))
        if not blob.is_file():
            bad.append("%s: %s not emitted" % (who, blob.name)); continue
        b = blob.read_bytes()
        off = g._int(row["src_addr"]) - regions[nm]["src"]
        old = bytes.fromhex(row["old_hex"])
        new = bytes.fromhex(g.row_hex(row, "new_hex", {"dst_slot": tid}))
        got = b[off:off + len(old)]
        checked += 1
        if got != new:
            bad.append("%s %s+%#x: %s (expected the ported %s) — %s"
                       % (who, nm, off,
                          "UNPATCHED, still vs2's bytes" if got == old
                          else "unexpected " + got.hex(),
                          new.hex(), row["note"][:40]))
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: %d shared-row sites patched across the three tenants' own "
          "copies of x05c800/x088512" % checked)
sys.exit(1 if bad else 0)
PY

# ── 4b: the ENGINE-LEVEL UNION — one table, every tenant's handlers ─────
# `obj_hook`'s extended secondary-object table is ONE table at ONE address
# whose entries point at handlers DIFFERENT TENANTS port: 59-63 are
# Donovan's, 64-75 Huitzil's. Emitted on iteration 0 it saw only tenant 0's
# placements and sent all twelve of Huitzil's to TRIPWIRES — an ILLEGAL the
# moment one of his secondary objects spawned. It now runs on the LAST
# iteration through `resolve_ported()`.
#
# The check is per-ENTRY attribution, not a count: an entry pointing into
# SOME placed region is not evidence it points into the RIGHT tenant's copy,
# and the shared spans mean a wrong-tenant target would still look placed.
echo "== 4b: the obj_hook union resolves each tenant's own handlers =="
python3 - "$WORK/three" <<'PY' || fail=1
import json, os, re, sys
d = sys.argv[1]
notes = open(os.path.join(d, "patch_notes_fragment.md")).read()
pl = json.load(open(os.path.join(d, "placements.json")))["regions"]
ops = json.load(open(os.path.join(d, "patch.json")))["ops"]
bad = []

m = re.search(r"data\s+(0x[0-9a-f]+) \+0x[0-9a-f]+\s+proj_hook extended type "
              r"table \((\d+) vanilla \+ (\d+) ported, (\d+) placed\)", notes)
if not m:
    print("  FAIL: no proj_hook extended-table note"); sys.exit(1)
addr, n_van, n_ext, n_placed = (int(m.group(1), 16), int(m.group(2)),
                                int(m.group(3)), int(m.group(4)))
# FROZEN 14z-80f: 17 of the 17 ported extras resolve. It was 5 before the
# union — the other twelve are Huitzil's.
if n_placed != 17:
    bad.append("%d of %d ported extras placed, frozen at 17 (5 means the "
               "union regressed to tenant 0 only)" % (n_placed, n_ext))

op = [o for o in ops if o.get("addr") == hex(addr) and o["op"] == "data"]
if not op:
    print("  FAIL: the extended table op is not in patch.json"); sys.exit(1)
tbl = bytes.fromhex(op[0]["hex"])

def owner(a):
    for k, v in pl.items():
        if v["dst"] <= a < v["dst"] + v["len"]:
            return k
    return None

EXPECT = {**{k: "donovan" for k in range(59, 64)},
          **{k: "huitzil" for k in range(64, 76)}}
for k, who in EXPECT.items():
    tgt = int.from_bytes(tbl[k * 4:k * 4 + 4], "big")
    o = owner(tgt)
    if o is None:
        bad.append("type %d -> %#x is in no placed region (a tripwire?)"
                   % (k, tgt)); continue
    got = o.split("@")[1] if "@" in o else "donovan"
    if got != who:
        bad.append("type %d resolves into %s's %s, expected %s's"
                   % (k, got, o, who))
# types 121-123 point at 0x6A70C, which NO tenant ports — they must STAY
# tripwires, or the union has started resolving things it cannot.
still = len(re.findall(r"obj_hook@\S+ type 12[123]: unresolved", notes))
if still != 3:
    bad.append("%d of the 3 genuinely-unported types (121-123) still "
               "tripwire — expected all 3" % still)
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: %d/%d ported extras placed; types 59-63 in donovan's "
          "regions and 64-75 in huitzil's OWN copies; 121-123 still "
          "tripwired" % (n_placed, n_ext))
sys.exit(1 if bad else 0)
PY

# ── 4c: slot-table rows follow their DECLARING tenants, and agreeing
# ──     duplicate ops are dropped rather than left to collide ───────────
# `code_word` rows carrying `slot_table` write `table + stride*dst_slot` —
# a DIFFERENT word per tenant, so two tenants declaring the same row text
# are not writing the same word. The dedup used to collapse them to one
# unowned row, which then wrote DONOVAN'S entry (0x282FA / 0x5F24C, two of
# the ten original collisions) while Huitzil and Pyron got none. `_owners`
# now survives the dedup and the row is applied once per declaring tenant.
#
# Separately: ops that write the SAME BYTES at the same address through
# different mechanisms (Donovan's `data_port hit_class_props_ext` vs H's and
# P's `aux_poke effect_map_*`; H's and P's adjacent byte15b entries widened
# to one word) are AGREEMENTS, not conflicts — dropped at emit with a note,
# so patch_prg's assertion stays strict about real ones.
echo "== 4c: slot-table rows per tenant; agreeing duplicates dropped =="
python3 - "$WORK/three" <<'PY' || fail=1
import re, sys
notes = open(sys.argv[1] + "/patch_notes_fragment.md").read()
bad = []
# FROZEN 14z-80g. Three tenants at 0x13/0x10/0x11 over stride 2 and stride 4.
WANT = {"obj_bank_word_slot": {0x282fa, 0x282f4, 0x282f6},
        "win_pos_x_slot":     {0x5f24c, 0x5f240, 0x5f244}}
for nm, want in WANT.items():
    got = {int(a, 16) for a in
           re.findall(r"code\s+(0x[0-9a-f]+) \+0x2\s+code_word " + nm, notes)}
    if got != want:
        bad.append("%s wrote %s, expected one entry per tenant at %s"
                   % (nm, sorted(hex(x) for x in got),
                      sorted(hex(x) for x in want)))
n_drop = len(re.findall(r"DROPPED: already written identically", notes))
if n_drop != 4:
    bad.append("%d agreeing duplicate ops dropped, frozen at 4 — if this "
               "grew, a NEW pair of tenants started agreeing and should be "
               "understood before it is normalised away" % n_drop)
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: 6 slot entries at 3 distinct tenant slots; %d agreeing "
          "duplicate ops dropped" % n_drop)
sys.exit(1 if bad else 0)
PY

# ── 5: what a merged patch STILL cannot do, frozen by name ──────────────
# The generator emits it; patch_prg refuses it. Freezing the inventory is
# the point: it is the work list for the shared-row union / N-way dispatch
# slice, and a SHRINKING number is how that slice will report progress.
echo "== 5: the merged patch's remaining op collisions (frozen) =="
python3 - "$WORK/three" <<'PY' || fail=1
import json, os, sys
d = sys.argv[1]
ops = json.load(open(os.path.join(d, "patch.json")))["ops"]

def length(o):
    if "hex" in o:
        return len(o["hex"]) // 2
    if o["op"] == "poke32":
        return 4
    if o["op"] == "poke16":
        return 2
    if "path" in o:
        return os.path.getsize(os.path.join(d, o["path"]))
    return 2

owner, pairs, nbytes = {}, set(), 0
for i, o in enumerate(ops):
    a = int(o["addr"], 16)
    for b in range(a, a + length(o)):
        if b in owner:
            pairs.add((owner[b], i)); nbytes += 1
        else:
            owner[b] = i
sites = sorted({int(ops[i]["addr"], 16) for _, i in pairs})
# FROZEN 14z-80g at 4 pairs / 24 bytes, down from 10/36: what remains is
# EXACTLY the N-way dispatch FORM and nothing else. Both sites are patched
# once per tenant — 0x5F1B6 by win_pal_variant, 0x5F146 by the site_thunk
# `select_pal_variant_id` — and the fix is one thunk per site whose body
# tests N ids (M3b_plan Phase 2 item 4), which is a design decision, not a
# mechanical edit. Everything else that used to collide was a real defect
# and is fixed: the slot_table rows wrote Donovan's entry for every tenant
# (14z-80g), and the rest were AGREEING duplicates now dropped at emit.
WANT_PAIRS, WANT_BYTES = 4, 24
bad = []
if (len(pairs), nbytes) != (WANT_PAIRS, WANT_BYTES):
    bad.append("collisions moved: %d pairs / %d bytes, frozen at %d/%d. If "
               "they SHRANK, re-freeze and say which slice closed them."
               % (len(pairs), nbytes, WANT_PAIRS, WANT_BYTES))
for s in (0x5F1B6, 0x5F146):
    if s not in sites:
        bad.append("the known N-way dispatch site %#x no longer collides — "
                   "if that is the fix landing, re-freeze this section" % s)
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: %d op pairs / %d bytes collide, incl. the engine sites "
          "0x5F1B6 and 0x5F146 (the N-way dispatch form is still open)"
          % (len(pairs), nbytes))
sys.exit(1 if bad else 0)
PY

# ── 6: verdict controls — the sections above must be able to FAIL ──────
# Without this the whole file could be passing on a loop that never runs.
# The control forces the body to one iteration and requires the counts to
# go back to Donovan's, i.e. requires section 2 to notice.
echo "== 6: verdict controls =="
cp tools/gen_donovan_patch.py "$WORK/gen.bak"
restore() { cp "$WORK/gen.bak" tools/gen_donovan_patch.py; }
trap 'restore; rm -rf "$WORK"' EXIT INT TERM

python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/gen_donovan_patch.py")
s = p.read_text()
a = "    for _ti, T in enumerate(_tenant_list):"
assert s.count(a) == 1, "loop header moved"
p.write_text(s.replace(a, "    for _ti, T in enumerate(_tenant_list[:1]):"))
PY
gen3 "$WORK/ctl1"
restore
# NOT frozen at Donovan's 243, and the reason is worth knowing: over the
# MERGED document, tenant 0 alone emits 241, because merge_manifests folds
# the singletons ([init_shim], [table_fix]) across tenants and the dedup
# changes row order, which moves allocations. So "3 manifests with only
# tenant 0 iterating" is NOT the same build as "donovan.toml alone" — which
# is exactly why M3b_plan's Phase 2 exit gate reproduces 4b7d0dc7 by passing
# ONE FILE (what per-file ownership bought in 14z-77), not by disabling
# tenants in a merged one. The assertion is therefore the one that matters:
# the count must collapse away from the 3-tenant figure.
ctl_ops="$( [ -f "$WORK/ctl1/patch.json" ] && nops "$WORK/ctl1" || echo 0 )"
if [ "$ctl_ops" -gt 0 ] && [ "$ctl_ops" -lt 300 ]; then
    echo "  ok: a one-iteration loop collapses 598 -> $ctl_ops ops —"
    echo "      section 2 is measuring the ITERATION, not the manifest"
else
    echo "  FAIL: the one-iteration control produced $ctl_ops ops; expected"
    echo "        a collapse to well under 300. Section 2 would not notice"
    echo "        a loop that stopped iterating"
    fail=1
fi

# The second control is the side-file guard: two tenants writing one name.
# Disabling side_name() must be CAUGHT by write_out(), not silently clobber.
python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/gen_donovan_patch.py")
s = p.read_text()
a = "        if _ti == 0:\n            return name\n"
assert s.count(a) == 1, "side_name() moved"
p.write_text(s.replace(a, "        if True:\n            return name\n"))
PY
gen2 "$WORK/ctl2"
restore
if grep -q "written twice with DIFFERENT content" "$WORK/ctl2.log"; then
    echo "  ok: a shared side-file name is a NAMED build error, not a clobber"
else
    echo "  FAIL: side_name() disabled and the build did not stop — tenant B's"
    echo "        blob would be served at tenant A's address. Log tail:"
    tail -3 "$WORK/ctl2.log"
    fail=1
fi

# The third control is section 4's, and it is the one this file was missing.
# Reverting row_here() to the 14z-80b rule ("unowned => iteration 0") must be
# CAUGHT — that rule left Huitzil's and Pyron's copies of the shared regions
# holding vs2's OBJ bank, and every other section stayed green through it.
python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/gen_donovan_patch.py")
s = p.read_text()
a = '        if any(k in row for k in ("region", "regions", "slot_table")):'
assert s.count(a) == 1, "row_here()'s shared-row rule moved"
p.write_text(s.replace(a, "        if False:"))
PY
gen3 "$WORK/ctl3"
restore
if python3 - "$WORK/ctl3" >/dev/null 2>&1 <<'PY'
import json, sys
from pathlib import Path
# the huitzil copy must still hold vs2's bytes under the reverted rule
b = Path(sys.argv[1], "fixed_x05c800.huitzil.bin")
sys.exit(0 if b.is_file() else 1)
PY
then
    if tests_out=$(python3 - "$WORK/ctl3" 2>&1 <<'PY'
import importlib.util, json, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("g", "tools/gen_donovan_patch.py")
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
docs = []
for p in ("donovan", "huitzil", "pyron"):
    d = g.toml_loads(Path("build/manifest/%s.toml" % p).read_text())
    g.stamp_owner(d, g.manifest_owner(d)); docs.append(d)
merged, _ = g.merge_manifests(docs, "cps2-wide-v1")
row = [r for r in merged["port_patch"]
       if r.get("_owner") is None and r["region"] == "x05c800"][0]
reg = json.loads(Path("build/hui29/extract/regions.json").read_text())["regions"]
b = Path(sys.argv[1], "fixed_x05c800.huitzil.bin").read_bytes()
off = g._int(row["src_addr"]) - reg["x05c800"]["src"]
old = bytes.fromhex(row["old_hex"])
sys.exit(0 if b[off:off + len(old)] == old else 1)
PY
    ); then
        echo "  ok: the iteration-0 rule leaves huitzil's shared region"
        echo "      UNPATCHED — section 4 is measuring the real defect"
    else
        echo "  FAIL: reverting row_here() did NOT reproduce the unpatched"
        echo "        shared region, so section 4 cannot fail on it"
        fail=1
    fi
else
    echo "  FAIL: the section-4 control produced no huitzil blob"; fail=1
fi

# The fourth control is section 4b's: forcing the engine union back onto
# iteration 0 must send Huitzil's twelve handlers to tripwires again.
python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/gen_donovan_patch.py")
s = p.read_text()
a = "        return _ti == len(_tenant_list) - 1\n"
assert s.count(a) == 1, "engine_here() moved"
p.write_text(s.replace(a, "        return _ti == 0\n"))
PY
gen3 "$WORK/ctl4"
restore
if grep -q "17 ported, 5 placed" "$WORK/ctl4/patch_notes_fragment.md" 2>/dev/null; then
    echo "  ok: the union forced onto iteration 0 drops to 5/17 placed —"
    echo "      section 4b is measuring the real defect"
else
    echo "  FAIL: forcing the union onto iteration 0 did NOT reduce the"
    echo "        placed count, so section 4b cannot fail on it. Got:"
    grep -o "17 ported, [0-9]* placed" "$WORK/ctl4/patch_notes_fragment.md" 2>/dev/null \
        || echo "        (no extended-table note at all)"
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant loop gate"; exit 1; }
echo "PASS: tenant loop gate (N=1 inert for all three tenants, the loop"
echo "      iterates with shared rows emitted once, each tenant's content"
echo "      present, shared region rows reaching every copy, the merged"
echo "      patch's collisions frozen, and 4 verdict controls)"
