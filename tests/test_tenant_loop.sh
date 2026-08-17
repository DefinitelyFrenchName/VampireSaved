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
# WHAT IT DOES **NOT** CLAIM (read this before quoting a green run). As of
# 14z-80h a 3-tenant patch both generates AND applies — section 5 runs
# patch_prg over it and requires zero op collisions. That is still only "the
# PROGRAM half composes". It has never been run in an emulator, the gfx half
# is single-tenant by decision, and no legacy or behaviour gate has been near
# a merged image. "The generator can emit N tenants", "a merged patch
# applies" and "a merged ROM is correct" are three different statements and
# this file makes the first two.
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
H_EX=build/hui32/extract        # huitzil  (huitzil-m6)
P_EX=build/pyron21/extract      # pyron    (pyron-m3)

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
# RE-FROZEN 14z-82c (was 259/205): the ADOPTED hitclass_map_extend
# site_thunk adds exactly TWO ops (body + site jmp) to each declaring
# build — huitzil and pyron declare it, donovan does not (his types fit
# the vanilla map).
# RE-FROZEN 14z-85b (was 265/207): the per-tenant sfx records
# (hui_sfx_records / pyr_sfx_records, maintainer-ruled) add NET +1 op to
# each declaring build: +2 (record array data + ptr-row poke32) −1 (the
# generic tail_data_ptr repoint is claim-suppressed, 14z-65 machinery).
# Donovan unchanged — his don_sfx_records row predates this.
# RE-FROZEN 14z-86 (D 243->265, H 267->300, P 208->234): THE M5 VOICE
# BATCH — +15 shared aux_poke ops (the voice alias thunk at 0x5FFF00,
# identical rows in all three manifests, deduped on merge) + the
# restored voice farm sound_stubs (kind=sound_stub recon rows, per
# tenant: the shared base farm + each overlay's own) per 14z-86's
# qs_songs voice_batch. Prior re-freeze 14z-85g (hui 266->267): +1 GEN
# op — the kind=sound_stub
# synthesized stub for vs2 farm 0x4F2E (the restored trap-detonation
# chirp, reconciliation_huitzil.toml).
# RE-FROZEN 14z-87 (D 265->270, H 300->305, P 234->239): THE VOICE-CLASS
# BORROW fix, option (b)+(c) (maintainer-decided 2026-08-15) — +5 ops per
# RE-FROZEN 14z-91, TWICE. (a) donovan 270 -> 266 and the merges 538 -> 534
# / 738 -> 734: the two fixture_row0f_override site_thunks deleted, 2 ops
# each. (b) then 266 -> 285 / 534 -> 553 / 734 -> 753, uniformly +19, for the
# obj_walker relocation: the two sites drop 3 ops each (table + thunk + site
# patch = 6) and gain 1 walker+table op plus one 4-byte operand repoint per
# caller (2 + 21 = 23), so -6 +25 = +19. Every tenant carries the same two
# engine rows, so the delta is identical for all three and for every merge.
# The two fixture_row0f_override site_thunks were DELETED (a legacy-regression
# root cause: their venue fixture-load sites are shared by match intro AND
# attract, so legacy paid for them on every venue load). Each thunk is 2 ops
# — body + site patch — so -4 on donovan and -4 on every merge carrying him.
# Huitzil and pyron are unchanged: the type-6 tripwire edit landed in the
# thunk BODY, which emits the same two ops.
#
# declaring tenant: the shared voice_borrow_keep_tenant site_thunk (2 ops:
# body + jsr site, byte-identical rows deduped on merge) + the
# voice_borrow_site_pad code_word (1 op: the stolen 4th word -> nop) + the
# two per-tenant [[data_port]] candidate/voice-number table rows (2 ops).
# All only_variant_slot-gated; the stock twin measured BIT-IDENTICAL.
# RE-FROZEN 14z-94, -1 ON EVERY COUNT THAT INCLUDES HUITZIL (H 324 -> 323,
# N=2 553 -> 552, N=3 753 -> 752; donovan 285 and pyron 258 UNCHANGED, which
# is the confirmation that the delta is huitzil-scoped). Cause: GitHub #91's
# reconciliation row resolves vs2 `0x494de` — a 32-bit divide helper vsavj
# carries byte-identical at `0x47fb6` — so the planted ILLEGAL tripwire that
# stood in for it is no longer emitted. Attributed by a content-multiset diff
# of the merged image before and after: the ONLY blob lost is `4afc` x1, the
# 68000 ILLEGAL opcode; every other difference is a uniform 0x10 allocator
# shift as the hole packs tighter. The second number in each check_n (570,
# 785) is unchanged and was not touched.
FROZEN_1="donovan:285 huitzil:323 pyron:258"
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
# 243 + 265 = 508 declared, 443 emitted (14z-84: +4 huitzil ops — the DF gold thunk, its data block, the trampoline site and the row code_word). The gap is four things and all of
# them are checked below: rows recognised as SHARED and emitted once (the
# iteration gate), tripwire ops no longer needed because the engine union
# resolves Huitzil's handlers (4b), agreeing duplicate ops dropped (4c), and
# N per-tenant thunks folded into one N-way chain (4d). Same for three.
# 14z-81c NOTE: these counts moved to 442/596 for a few hours while the
# multi-owner obj_hook stub fix was in (three owner-dispatch stubs + three
# fallback tripwires), then moved BACK when the stub design was WITHDRAWN
# the same day — two measured timing failure modes; see OBJ_HOOK_OWNER_READ
# in gen_donovan_patch.py and STATE 14z-81c. The multi-resolver DETECTION
# and its FIRST-WINS notes remain (zero ops — notes only).
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
# RE-FROZEN 14z-82 (was 436/590): the F2 fix adds exactly ONE op to any
# multi-tenant merge — the merged init shim's chain fall-through TRIPWIRE
# (an unmatched id at the shim is a named ILLEGAL, never a silent detour
# into tenant-0's handler). The shim itself and the dispatch-row pokes
# rebalance to the same count; the 12 renumbered obj_hook entries grow the
# TABLE op's hex, not the op count. Single-tenant counts above unchanged.
# RE-FROZEN 14z-85 (was 443/597): the spawn-time OWNER TAG (maintainer
# option (a)). N=2 (D+H) +30 = the 30 distinct owner-tag thunks (D 9 +
# H 21; entries 64-75 are SINGLE-resolver without pyron, so no stubs).
# N=3 +70 = 46 thunks (D 9 + H 21 + P 16) + 12 tag stubs on entries
# 64-75 + their 12 tripwires. The 80 site detours are blob edits (0 ops).
# Single-tenant counts above unchanged — the pass is empty at N=1.
# RE-FROZEN 14z-85b (was 473/667): +1 per declaring tenant — the
# hui/pyr_sfx_records rows (see FROZEN_1 note above).
# RE-FROZEN 14z-85c (was 474/669): the 59-63 stub extension (maintainer-
# ruled). N=3 +8 = 4 donovan-only stubs (59/61/62/63) + 4 tripwires.
# N=2 (D+H) +16 = 8 stubs + 8 tripwires: the FOREIGN-STAMPER rule fires
# for 59/61/62/63 (H stamps, D resolves) AND for 65/66/73/75 (D stamps,
# H resolves) — at N=3 the latter four are multi-resolver anyway.
# RE-FROZEN 14z-85g (+1 each: hui's sound_stub op rides every N that
# includes him).
# RE-FROZEN 14z-87 (was 531/560 and 729/770): the voice-borrow fix —
# +7 at N=2 (3 shared thunk/pad ops deduped + 2 data_port ops per tenant)
# and +9 at N=3 (3 shared + 2x3 per-tenant), matching the +5-per-solo
# delta above with the shared rows counted once.
check_n "2 tenants" "$WORK/two"   552 570
check_n "3 tenants" "$WORK/three" 752 785

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
           ("huitzil", "build/hui30/extract",   0x10, ".huitzil"),
           ("pyron",   "build/pyron21/extract", 0x11, ".pyron"))
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
# Donovan's; 64-75 are handler copies BOTH huitzil and pyron place, so
# (14z-85, maintainer option (a)) each of those entries is a TAG STUB
# dispatching on the object's spawn-time owner tag — first-wins into
# huitzil's copies was declaration-order luck and Pyron's family objects
# ran H's copies (music retrigger, STATE 14z-84 finding (3)). Emitted on
# iteration 0 the union saw only tenant 0's placements and sent all twelve
# to TRIPWIRES — an ILLEGAL the moment one of his secondary objects
# spawned. It runs on the LAST iteration through `resolve_ported()`.
#
# The check is per-ENTRY attribution, not a count: an entry pointing into
# SOME placed region is not evidence it points into the RIGHT tenant's copy,
# and the shared spans mean a wrong-tenant target would still look placed.
# For 64-75 the stub's own bytes are decoded: each compare id must route
# to a handler in THAT tenant's copy.
echo "== 4b: the obj_hook union resolves each tenant's own handlers =="
python3 - "$WORK/three" <<'PY' || fail=1
import json, os, re, sys
d = sys.argv[1]
notes = open(os.path.join(d, "patch_notes_fragment.md")).read()
pl = json.load(open(os.path.join(d, "placements.json")))["regions"]
ops = json.load(open(os.path.join(d, "patch.json")))["ops"]
bad = []

# 14z-91: the table no longer stands alone — it is appended to a relocated
# copy of the WALKER, in ONE op, so the dispatch site can stay vanilla. The
# note names both the block address and the table's offset inside it, and
# the op is `code` (the table is read pc-relatively now, not An-relatively).
# The regex still pins the site whose note ends "placed)" with no
# ", N renumbered" — that is 0x54470, the site the 17-extra freeze is about.
m = re.search(r"code\s+(0x[0-9a-f]+) \+0x[0-9a-f]+\s+obj_walker: 0x[0-9a-f]+ "
              r"relocated verbatim \+ its extended type table at "
              r"\+(0x[0-9a-f]+) \((\d+) vanilla \+ (\d+) ported, "
              r"(\d+) placed\)", notes)
if not m:
    print("  FAIL: no obj_walker relocated-walker + extended-table note"); sys.exit(1)
addr, tbl_off, n_van, n_ext, n_placed = (int(m.group(1), 16), int(m.group(2), 16),
                                         int(m.group(3)), int(m.group(4)),
                                         int(m.group(5)))
# FROZEN 14z-80f: 17 of the 17 ported extras resolve. It was 5 before the
# union — the other twelve are Huitzil's.
if n_placed != 17:
    bad.append("%d of %d ported extras placed, frozen at 17 (5 means the "
               "union regressed to tenant 0 only)" % (n_placed, n_ext))

op = [o for o in ops if o.get("addr") == hex(addr) and o["op"] == "code"]
if not op:
    print("  FAIL: the relocated walker + table op is not in patch.json"); sys.exit(1)
blob = bytes.fromhex(op[0]["hex"])
tbl = blob[tbl_off:]          # the walker copy occupies [0, tbl_off)

def owner(a):
    for k, v in pl.items():
        if v["dst"] <= a < v["dst"] + v["len"]:
            return k
    return None

# type 60 is the one direct pointer left in the family: no tenant has a
# stamp site for it, so it keeps donovan's copy without a stub (14z-85c).
for k, who in {60: "donovan"}.items():
    tgt = int.from_bytes(tbl[k * 4:k * 4 + 4], "big")
    o = owner(tgt)
    if o is None:
        bad.append("type %d -> %#x is in no placed region (a tripwire?)"
                   % (k, tgt)); continue
    got = o.split("@")[1] if "@" in o else "donovan"
    if got != who:
        bad.append("type %d resolves into %s's %s, expected %s's"
                   % (k, got, o, who))
# 14z-85 (ext. 14z-85c): family entries are TAG STUBS (owner_dispatch_stub
# shape "tag" — the ruled option (a)). Per-ENTRY attribution, decoded from
# the stub's own bytes: each compare id must route to a handler placed in
# THAT tenant's copy, with one tripwire fall-through for zero/unclaimed
# tags. 59/61/62/63 are donovan-only stubs (single resolver; H/P stamp
# those types at dead co-ported sites — their tags must tripwire, never
# silently run donovan's copy). 64-75 are huitzil+pyron stubs. A direct
# first-wins pointer fails here because it is not a decodable stub op.
code_at = {int(o["addr"], 16): o["hex"] for o in ops if o["op"] == "code"}
TAG_OWNER = {0x13: "donovan", 0x10: "huitzil", 0x11: "pyron"}
EXPECT_IDS = {**{k: [0x13] for k in (59, 61, 62, 63)},
              **{k: [0x10, 0x11] for k in range(64, 76)}}
for k, want_ids in EXPECT_IDS.items():
    tgt = int.from_bytes(tbl[k * 4:k * 4 + 4], "big")
    h = code_at.get(tgt)
    if h is None:
        bad.append("type %d -> %#x is not a generated code op (first-wins "
                   "regression?)" % (k, tgt)); continue
    cmp_ids = [int(x, 16) for x in re.findall(r"0c2e00([0-9a-f]{2})007f", h)]
    exits = [int(x, 16) for x in re.findall(r"7000207c([0-9a-f]{8})4ed0", h)]
    tws = re.findall(r"4ef9([0-9a-f]{8})", h)
    if sorted(cmp_ids) != want_ids or len(exits) != len(want_ids) \
            or len(tws) != 1:
        bad.append("type %d stub %#x does not decode as a %d-tenant tag "
                   "stub (ids %s, %d exits, %d tripwires)"
                   % (k, tgt, len(want_ids), [hex(i) for i in cmp_ids],
                      len(exits), len(tws)))
        continue
    for cid, haddr in zip(cmp_ids, exits):
        o = owner(haddr)
        got = (o.split("@")[1] if "@" in (o or "") else "donovan") if o else None
        if got != TAG_OWNER[cid]:
            bad.append("type %d tag %#x routes to %s (%s), expected %s's copy"
                       % (k, cid, hex(haddr), o, TAG_OWNER[cid]))
# types 121-123 point at 0x6A70C, which NO tenant ports — they must STAY
# tripwires, or the union has started resolving things it cannot.
still = len(re.findall(r"obj_hook@\S+ type 12[123]: unresolved", notes))
if still != 3:
    bad.append("%d of the 3 genuinely-unported types (121-123) still "
               "tripwire — expected all 3" % still)
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: %d/%d ported extras placed; 59/61/62/63 donovan-only TAG "
          "STUBS, 60 his direct pointer, 64-75 H/P TAG STUBS, every "
          "compare routed into its owner's copy with a tripwire "
          "fall-through (14z-85/85c); 121-123 still tripwired"
          % (n_placed, n_ext))
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

# ── 4d: N per-tenant thunks at ONE site fold into one N-way chain ───────
# `win_pal_variant` (0x5F1B6) and the `select_pal_variant_id` site_thunk
# (0x5F146) are each ONE engine site that every tenant patches — the merged
# patch's last 4 op collisions. Both bodies are already compare-chain
# elements: `cmpi.b #TT,d6 / bne.s <past my work> / <my work>`, where the
# branch already targets whatever follows. So N tenants chain by pure
# CONCATENATION, and at N=1 the bytes are identical to the single-element
# form — which is why the three frozen verticals did not move.
#
# Checked by DECODING the emitted chain, not by counting: element count, the
# ids in declaration order, and that each element carries its OWN tenant's
# data pointer. A chain of the right length whose elements all pointed at one
# tenant's block would pass a count check and be wrong.
echo "== 4d: the N-way chains at the shared engine sites =="
python3 - "$WORK/three" <<'PY' || fail=1
import json, re, sys
d = sys.argv[1]
ops = json.load(open(d + "/patch.json"))["ops"]
notes = open(d + "/patch_notes_fragment.md").read()
bad = []

def body_at(addr):
    for o in ops:
        if o.get("addr") == addr and o["op"] == "code" and "hex" in o:
            return bytes.fromhex(o["hex"])
    return None

def decode_chain(b):
    """[(id, own pointer)] for a cmpi.b/bne.s element chain, plus the tail."""
    els, off = [], 0
    while off + 6 <= len(b) and b[off:off + 2] == b"\x0c\x06" and b[off + 4] == 0x66:
        elen = 6 + b[off + 5]
        ptr = None
        for k in range(off + 6, off + elen - 5):
            if b[k:k + 2] == b"\x20\x7c":          # movea.l #imm,a0
                ptr = int.from_bytes(b[k + 2:k + 6], "big")
                break
        els.append((b[off + 3], ptr))
        off += elen
    return els, b[off:]

# FROZEN 14z-80h: three tenants, ids in DECLARATION order.
WANT_IDS = [0x13, 0x10, 0x11]
PATTERNS = (("win_pal_variant",
             r"code\s+(0x[0-9a-f]+) \+0x[0-9a-f]+\s+win_pal_variant thunk, (\d+)-way"),
            ("site_thunk",
             r"code\s+(0x[0-9a-f]+) \+0x[0-9a-f]+\s+site_thunk (\d+)-way chain"))
for what, pat in PATTERNS:
    m = re.search(pat, notes)
    if not m:
        bad.append("%s: no N-way chain emitted at all" % what)
        continue
    b = body_at(m.group(1))
    if b is None:
        bad.append("%s: the chain at %s is not in patch.json" % (what, m.group(1)))
        continue
    els, tail = decode_chain(b)
    ids = [i for i, _ in els]
    if int(m.group(2)) != 3 or ids != WANT_IDS:
        bad.append("%s: %d-way with ids %s, expected 3-way %s"
                   % (what, int(m.group(2)), [hex(i) for i in ids],
                      [hex(i) for i in WANT_IDS]))
        continue
    ptrs = [p for _, p in els]
    if None in ptrs:
        bad.append("%s: an element carries no movea.l pointer" % what)
    elif len(set(ptrs)) != 3:
        bad.append("%s: the 3 elements share pointers %s — every tenant would "
                   "get one tenant's data" % (what, [hex(p) for p in ptrs]))
    if not tail:
        bad.append("%s: the chain has no non-tenant tail" % what)
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: both shared sites carry ONE 3-way chain, ids 0x13/0x10/0x11 "
          "in declaration order, each element with its own data pointer")
sys.exit(1 if bad else 0)
PY

# ── 5: the merged patch APPLIES ─────────────────────────────────────────
# Until 14z-80h this section froze an INVENTORY of collisions, because the
# generator emitted a merged patch that patch_prg refused. It now requires
# ZERO — and then actually runs patch_prg, because "no two ops overlap" is
# this file's own arithmetic while patch_prg is the tool that has to accept
# it. Both, or the check only tests my own opinion.
#
# This is where the honest limit sits: a merged PROGRAM image composes. The
# gfx half is single-tenant, nothing has been in an emulator, and no legacy
# gate has seen a merged image.
echo "== 5: the merged patch has no op collisions AND patch_prg applies it =="
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
# The whole history of this number, because it is the one worth keeping:
#   10 pairs / 36 bytes  the loop's first merged patch (14z-80d)
#    4 / 24              after the slot_table rows followed their tenants and
#                        the AGREEING duplicates were dropped (14z-80g)
#    0 / 0               after the two shared engine sites took N-way chains
#                        (14z-80h). Anything above zero is a REGRESSION now,
#                        not a work list.
bad = []
if pairs:
    bad.append("%d op pair(s) / %d byte(s) collide; a merged patch must have "
               "NONE. Offenders: %s"
               % (len(pairs), nbytes,
                  ", ".join("%s@%s x %s@%s"
                            % (ops[j]["op"], ops[j]["addr"],
                               ops[i]["op"], ops[i]["addr"])
                            for j, i in sorted(pairs)[:6])))
for b in bad:
    print("  FAIL: %s" % b)
if not bad:
    print("  ok: %d ops, no two writing one byte" % len(ops))
sys.exit(1 if bad else 0)
PY

# ...and the tool that has to accept it actually does.
if python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$WORK/prg" \
        --patch "$WORK/three/patch.json" > "$WORK/prg.log" 2>&1; then
    echo "  ok: patch_prg applied the 3-tenant patch ($(grep -c 'sha1' \
"$WORK/prg.log" 2>/dev/null || echo '?') members written)"
else
    echo "  FAIL: patch_prg refused the merged patch:"
    tail -3 "$WORK/prg.log"
    fail=1
fi

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
    echo "  ok: a one-iteration loop collapses 590 -> $ctl_ops ops —"
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
reg = json.loads(Path("build/hui30/extract/regions.json").read_text())["regions"]
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

# The fifth control covers sections 4d AND 5 at once: with the multi-declared
# site set emptied, the site_thunk rows emit one thunk per tenant again — so
# there must be no N-way chain to decode AND the ops must collide. If this
# control passes silently, neither section is measuring anything.
python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/gen_donovan_patch.py")
s = p.read_text()
a = "    _st_multi = {a for a in\n"
assert s.count(a) == 1, "_st_multi moved"
# 14z-84: the mechanism gained a SECOND feeding path (deduped shared rows
# with a tenant-id placeholder, `_st_multi |=`); a control that empties
# only the first leaves chains standing and reads MUDDLED — measured the
# day the path was added: chain-note grep still hit, so the control
# failed against a working build. Empty BOTH.
b = "    _st_multi |= {_int(r[\"site\"]) for r in port.get(\"site_thunk\", [])\n"
assert s.count(b) == 1, "_st_multi extension moved"
# `set() if True else {...}` — NOT `set() or {...}`, which is falsy and
# returns the comprehension, i.e. a control that perturbs nothing. That
# exact mistake was made here first and caught by this control failing.
s = s.replace(a, "    _st_multi = set() if True else {a for a in\n")
s = s.replace(b, "    _st_multi |= set() if True else "
                 "{_int(r[\"site\"]) for r in port.get(\"site_thunk\", [])\n")
p.write_text(s)
PY
gen3 "$WORK/ctl5"
restore
_c5_chain=0; _c5_clash=0
grep -q "site_thunk 3-way chain" "$WORK/ctl5/patch_notes_fragment.md" 2>/dev/null || _c5_chain=1
python3 - "$WORK/ctl5" >/dev/null 2>&1 <<'PY' || _c5_clash=1
import json, os, sys
d = sys.argv[1]
ops = json.load(open(os.path.join(d, "patch.json")))["ops"]
def length(o):
    if "hex" in o: return len(o["hex"]) // 2
    if o["op"] == "poke32": return 4
    if o["op"] == "poke16": return 2
    if "path" in o: return os.path.getsize(os.path.join(d, o["path"]))
    return 2
owner = {}
for i, o in enumerate(ops):
    a = int(o["addr"], 16)
    for b in range(a, a + length(o)):
        if b in owner:
            sys.exit(1)          # collided, as the control requires
        owner[b] = i
sys.exit(0)                      # no collision -> the control did nothing
PY
if [ "$_c5_chain" = 1 ] && [ "$_c5_clash" = 1 ]; then
    echo "  ok: without the multi-site chain the thunks collide again and no"
    echo "      chain is emitted — sections 4d and 5 both measure it"
else
    echo "  FAIL: emptying _st_multi left the build looking healthy"
    echo "        (chain absent=$_c5_chain, ops collided=$_c5_clash) — so"
    echo "        sections 4d/5 would not notice the chain being lost"
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: tenant loop gate"; exit 1; }
echo "PASS: tenant loop gate — N=1 inert for all three tenants; the loop"
echo "      iterates with shared rows emitted once; each tenant's content"
echo "      present; shared region rows reach every copy; the engine union"
echo "      and the N-way chains resolve every tenant; the merged 3-tenant"
echo "      patch has ZERO op collisions and patch_prg applies it; 5"
echo "      verdict controls. (The PROGRAM half only — see the header.)"
