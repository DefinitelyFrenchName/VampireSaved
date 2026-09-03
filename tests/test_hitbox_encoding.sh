#!/bin/sh
# test_hitbox_encoding.sh — THE HITBOX ENCODING AND THE ATTACK RECORD ARE WHAT
# THE ENGINE USES (character-data map, PHASE 2; measured 14z-120 (5)).
#
# WHAT IT HOLDS. tools/hitbox_records.py's reading of a tenant's hitbox data
# (the five tables behind +0x80..+0x90, 8-byte (x,y,hw,hh) boxes authored
# for the LEFT-facing sprite and mirrored when flip_x=1, the family table
# hb8 -> {vuln,vuln,vuln,push}, the 0x20-byte attack record selected by the
# node's hbA>>8 with +8 real / +9 white / +0x10 hit id / +0x17 class) is
# re-measured on native vs2 with Donovan (tools/name_moves.py parts 9 and 10:
# normals that connect, a whiff ladder, a projectile, the multi-hit Lightning
# Sword, Ifrit, the planted-sword column) under TWO instruments:
#   field_trace.lua  — positions, facing, node pointer, the fighters' box ids,
#                      the resolved table pointers, the victim's HP/class;
#   trace_writes.lua — the -debug write tap on the victim's +0x50..+0x55:
#                      PC + A3 (the attack record) at every HP/class write.
# and the gate asserts:
#   1. the resolved table pointers equal base+base[0..2], base+base[4] (attack,
#      +0x8C) and base+base[3] (push, +0x90) — the community mapping had the
#      last two crossed;
#   2. every HP write of part 9 came with A3 = attack table + idx*0x20 where
#      idx = the attacker's node hbA>>8 at that frame;
#   3. under the MIRRORED convention every fighter hit begins on the first
#      frame the attack box overlaps a victim vuln box (8/8), and no whiff
#      window overlaps outside the victim's hitstun; NEGATIVE CONTROL: the
#      un-mirrored convention must fail on most hits;
#   4. the victim's +0x54 after each hit is the record's +0x17 (or 1, the
#      forced generic class) on the fighter path, and EQUALS +0x17 on the
#      projectile / multi-hit / Ifrit / column hits of part 10 (0x14 / 0x4E /
#      0x0A / 0x52) — the "+0x1D class byte" is never what the engine used.
# Emulator tier (MAME, ~4 min: two field legs + two -debug legs, parallel).
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/don_m19] tests/test_hitbox_encoding.sh
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier emulator (MAME, ~4 min, four legs in parallel, two of them -debug))
#   THE HITBOX ENCODING AND THE ATTACK RECORD (14z-120 (5), phase 2): Donovan
#   on native vs2, `name_moves.py` parts 9/10 (normals that connect, a whiff
#   ladder, a projectile, the multi-hit Lightning Sword, Ifrit, the column)
#   under `field_trace.lua` + the `trace_writes.lua` tap on the victim's
#   `+0x50..+0x55`; asserts the five table pointers (`+0x8C` = attack =
#   base[4], `+0x90` = push = base[3]), A3 = attack record of the attacker's
#   node (`hbA>>8`) on every HP write, 8/8 hits on the first overlap frame
#   under the mirrored-x convention with no whiff overlap (negative control:
#   the un-mirrored convention), and victim `+0x54` = record `+0x17` on the
#   fighter, projectile, multi-hit and column paths. Run after any change to
#   `tools/hitbox_records.py`, the rigs or the extracts
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/don_m19}"
EX="$BUILD/extract"
[ -f "$EX/regions.json" ] || { echo "SKIP: no $EX/regions.json"; exit 0; }
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
FIELDS="ff8410:w:x,ff8414:w:y,ff840b:b:face,ff841c:l:node,ff8494:l:boxes,ff8480:l:t0,ff8484:l:t1,ff8488:l:t2,ff848c:l:t3,ff8490:l:t4,ff8460:l:hbase,ff8464:l:hcomp,ff8810:w:p2x,ff8814:w:p2y,ff880b:b:p2face,ff8894:l:p2boxes,ff8854:b:p2cls,ff8850:w:p2hp,ff885c:b:p2frz"

echo "== 1. rigs + chains + decoder"
for p in 9 10; do python3 tools/name_moves.py gen donovan $p "$W/r_$p.rpl" "$W/r_$p.json" >/dev/null || bad "gen part $p"; done
mkdir -p "$W/chains"
python3 - "$EX" "$W/chains" <<'PY' || bad "decode chains"
import json, subprocess, sys
ex, w = sys.argv[1], sys.argv[2]
rj = json.load(open(f"{ex}/regions.json")); r = rj["regions"]["anim"]
ptr = {v["table"]: int(v["ptr"], 16) for v in rj["values"] if v["table"].startswith("anim_index")}
for name in ("a", "a2", "b", "c", "proj"):
    subprocess.check_call(["python3", "tools/anim_nodes.py", f"{ex}/region_anim.bin", "--base", hex(r["src"]), "--table", hex(ptr["anim_index_" + name]),
                           "--name", name, "--end", hex(r["src"] + r["len"]), "--json", f"{w}/{name}.json"], stdout=subprocess.DEVNULL)
PY
[ $fail = 0 ] || { echo FAIL; exit 1; }

echo "== 2. the four native vs2 legs (parallel; two of them -debug)"
for p in 9 10; do
    FR="$(python3 -c "import json;print(json.load(open('$W/r_$p.json'))['frames'])")"
    rm -rf "$W/sbf$p" "$W/sbw$p"; mkdir -p "$W/sbf$p" "$W/sbw$p"
    ( cd "$W" && MAME_SANDBOX="$W/sbf$p" REPLAY="$W/r_$p.rpl" FIELDS="$FIELDS" FIELD_OUT="$W/field_$p.txt" FIELD_FROM=2300 FIELD_TO="$FR" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" vsav2 -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/field_$p.log" 2>&1 ) </dev/null &
    ( cd "$W" && MAME_SANDBOX="$W/sbw$p" REPLAY="$W/r_$p.rpl" WATCH="ff8850,6" TRACE_OUT="$W/writes_$p.txt" FRAMES="$FR" \
      "$REPO/tools/run_mame.sh" vsav2 -debug -autoboot_script "$REPO/tests/lua/trace_writes.lua" > "$W/writes_$p.log" 2>&1 ) </dev/null &
done
wait
for p in 9 10; do [ -s "$W/field_$p.txt" ] || bad "part $p: no field samples"; [ -s "$W/writes_$p.txt" ] || bad "part $p: no write-tap log"; done
[ $fail = 0 ] || { echo FAIL; exit 1; }

echo "== 3. the assertions"
python3 - "$EX" "$W" <<'PY' || fail=1
import sys, re, json
sys.path.insert(0, "tools"); import hitbox_records as hr
ex, w = sys.argv[1], sys.argv[2]
H = hr.HitboxSet(ex)
hbA = {}
for name in ("a", "a2", "b", "c", "proj"):
    for c in json.load(open(f"{w}/chains/{name}.json"))["chains"].values():
        for n in c.get("nodes") or []: hbA[int(n["addr"], 16)] = n["hbA"]
def rows(p):
    out = {}
    for line in open(f"{w}/field_{p}.txt"):
        f = line.split()
        if len(f) < 3 or f[0] != "F": continue
        v = dict(kv.split("=") for kv in f[2:]); out[int(f[1])] = {k: int(x) for k, x in v.items()}
    return out
def taps(p):
    out = []
    for line in open(f"{w}/writes_{p}.txt"):
        m = re.match(r"frame (\d+) PC ([0-9a-f]+) (.*)", line)
        if not m or int(m.group(1)) < 2400: continue
        regs = dict(re.findall(r"(\w\d) ([0-9a-f]{8})", m.group(3))); out.append((int(m.group(1)), int(m.group(2), 16), regs))
    return out
fails = 0
def check(cond, msg):
    global fails
    print(("  ok    " if cond else "  FAIL  ") + msg); fails += (not cond)
R9 = rows(9); T9 = taps(9)
# 1. table pointers
v = R9[3000]
u = lambda x: x & 0xffffffff
check(u(v["hbase"]) == H.base and u(v["hcomp"]) == H.comp, f"+0x60/+0x64 = hitbox_base {H.base:#x} / family table {H.comp:#x}")
check([u(v[k]) for k in ("t0", "t1", "t2")] == [H.tables["vuln0"], H.tables["vuln1"], H.tables["vuln2"]], "+0x80/84/88 = base+base[0..2]")
check(u(v["t3"]) == H.tables["attack"] and u(v["t4"]) == H.tables["push"], f"+0x8C = ATTACK = base+base[4] ({H.tables['attack']:#x}), +0x90 = PUSH = base+base[3] ({H.tables['push']:#x})")
# 2. HP writes: A3 = attack table + idx*0x20, idx = attacker's hbA>>8 at that frame (post-process write at vs2 0x17452 -> logged PC 0x17456)
hp_writes = [(fr, regs) for fr, pc, regs in T9 if pc == 0x17456]
good = 0
for fr, regs in hp_writes:
    a3 = int(regs["A3"], 16); r = R9.get(fr - 1) or R9.get(fr)
    idx = hbA.get(u(r["node"]), 0) >> 8
    if a3 == H.tables["attack"] + idx * 0x20: good += 1
check(good == len(hp_writes) and len(hp_writes) >= 8, f"{good}/{len(hp_writes)} HP writes carried A3 = attack record of the attacker's node (hbA>>8)")
# 3. overlap: for every active frame, mirrored vs unmirrored convention
def first_overlap_runs(mirror):
    runs = []
    for fr in sorted(R9):
        r = R9[fr]; h = hbA.get(u(r["node"]), 0)
        if not h: continue
        att = hr.placed(r["x"], r["y"], r["face"] if mirror else 0, H.record(h >> 8)["box"])
        ids = u(r["p2boxes"]); vids = [(ids >> 24) & 0xff, (ids >> 16) & 0xff, (ids >> 8) & 0xff]
        vul = [hr.placed(r["p2x"], r["p2y"], r["p2face"] if mirror else 0, H.box(H.tables[f"vuln{j}"] + 8 * vids[j])) for j in range(3)]
        if any(hr.overlap(att, q) for q in vul):
            if runs and fr == runs[-1][1] + 1: runs[-1][1] = fr
            else: runs.append([fr, fr, r["p2frz"] or r["p2cls"]])   # the victim already reacting = hitstun (the dedup case)
    return runs
# the hit frames for the overlap test come from the FIELD run itself (the -debug tap is its own timeline, [VSP-130]):
# the frame the victim's HP first drops
hit_frames = []
prev = None
for fr in sorted(R9):
    if prev is not None and R9[fr]["p2hp"] < R9[prev]["p2hp"]: hit_frames.append(fr)
    prev = fr
runs = first_overlap_runs(True)
starts = {a for a, b, frz in runs}
matched = sum(1 for h in hit_frames if any(a in (h, h - 1) for a in starts))
check(matched == len(hit_frames), f"mirrored convention: {matched}/{len(hit_frames)} hits begin on the first overlap frame")
stray = [a for a, b, frz in runs if not any(a in (h, h - 1) for h in hit_frames) and not frz]
check(not stray, f"mirrored convention: no overlap run outside a hit or the victim's hitstun (stray: {stray})")
runs_u = first_overlap_runs(False); starts_u = {a for a, b, frz in runs_u}
matched_u = sum(1 for h in hit_frames if any(a in (h, h - 1) for a in starts_u))
check(matched_u < matched, f"NEGATIVE CONTROL: the un-mirrored convention matches only {matched_u}/{len(hit_frames)} hits (mirrored: {matched})")
# 4. class: fighter path — +0x54 after the hit is rec+0x17 or 1
def cls_after(R, fr):
    for k in range(fr, fr + 4):
        if k in R and R[k]["p2cls"]: return R[k]["p2cls"]
    return 0
n_ok = 0
for fr, regs in hp_writes:
    rec = H.record((int(regs["A3"], 16) - H.tables["attack"]) // 0x20)
    if cls_after(R9, fr - 1) in (rec["cls"], 1): n_ok += 1
check(n_ok == len(hp_writes), f"fighter path: victim +0x54 = record +0x17 or the forced 1 on {n_ok}/{len(hp_writes)} hits")
R10 = rows(10); T10 = taps(10)
seen = []
for fr, pc, regs in T10:
    if pc != 0x17456: continue
    a3 = int(regs["A3"], 16)
    if H.tables["attack"] <= a3 < H.tables["attack"] + 0x20 * 4096 and a3 < H.end: rec = H.record((a3 - H.tables["attack"]) // 0x20)
    else: rec = H.record((a3 - H.proj_attack()) // 0x20, proj=True)
    seen.append((fr, rec["cls"], cls_after(R10, fr - 1)))
special = [(fr, c, got) for fr, c, got in seen if c not in (0, 1)]
check(len(special) >= 3 and all(c == got for fr, c, got in special), f"projectile / multi-hit / column: victim +0x54 == record +0x17 on {sum(1 for _, c, g in special if c == g)}/{len(special)} hits {sorted({c for _, c, _ in special})}")
sys.exit(1 if fails else 0)
PY
[ $fail = 0 ] && echo PASS || echo FAIL
exit $fail
