#!/bin/sh
# audit_mizuumi_rows_b.sh — THREE MORE MIZUUMI PLAYER-STRUCT CANDIDATES, MEASURED ON EXISTING REPLAYS: +0x3A8 IS A LONG
# (A GFX-RAM ADDRESS), +0x384 A PER-PLAYER STATE INDEX, AND +0x3BE COUNTS ONLY THE KOs WHOSE FINISH TYPE IS
# 3, 4 OR 6 (measured 14z-214, GitHub #118: the static rows and B2's first trace, after S0's static read)
#
# WHAT: on pristine vsavj, over six corpus replays: +0x3A8 is written only by PRG:0x01BEE2, 0x01C186 and 0x01C692 (each seen storing; the
#   engine's clears and the boot RAM test aside) and always as a LONG (both words in one frame), and reads only 0, 0x0090C140 on P1 or
#   0x0090C200 on P2 — S0's $FF80D0 (0x0090C000) + 0x140 / + 0x200 (that it is the fighter's palette block is S0's inference, not judged); the byte +0x384 is
#   a per-player state index: each side's sequence of values (0, 2, 6, 8 and 10 seen) is frozen per replay (P1 0, 6 in all six;
#   P2 0 in 02 and 26 and 2, 0, 2, 6 in 03, 37, 105 and 128, human or CPU not traced; five sides ending 8, 10, 0 — no game state judged), +0x385 a second-level index (0, 2, 4, 6 seen) and
#   +0x386..+0x387 always 0; every write by PRG:0x009A2C sets bit 7 of the
#   +0x3B6 of the side that just won a KO (its HP > 0, the other side's <= 0; finish type in the low bits), and +0x3BE is raised by PRG:0x05E2DC only in the frame of such a set
#   whose low bits are 3, 4 or 6, never after one whose low bits are anything else, and no other PC writes it
#   non-zero in game; PRG:0x05DD0E rewrites each set's value
#   without bit 7 in the same frame; each raise writes the previous value + 1 (the field reading it the next frame; both raises seen go 0 -> 1, so an add
#   is not told from a store of 1: S0 reads an add, static), and the next write to that side's
#   +0x3BE is a 0 from PRG:0x016E4C or 0x016E4E (only 0x016E4E seen; S0 reads the pair as the fighter block's word clear, static); +0x3BF reads 0 on every frame and no
#   in-game write makes it non-zero (the tap shown live on that word by its boot writes); before f1000 the only non-zero +0x3A8 writer besides those three is the boot RAM
#   test PRG:0x000D34. Counts frozen:
#   9 bit-7 sets (0x80, 0x81, 0x83), 2 raises (both after 0x83). Only this behaviour is claimed: what the counters unlock (S0: a ladder
#   reader at 0x00A79C / 0x0099E0), and the community names "Scene Pointer", "WORD Palette RAM Pointer", "EX Finishes
#   Counter" / "Unique Finishes Counter", are not judged here.
# HOW: on MAME (the reference binary), for each replay a FIELD leg (tests/lua/field_trace.lua: +0x384.l, +0x3A8.l,
#   +0x3B6, +0x3BE, +0x3BF on both sides, $FF80D0.l) and a WRITE-TAP leg (tests/lua/read_tap.lua over both sides'
#   +0x384, +0x3A8, +0x3B6 and +0x3BE words). A tap write in tap frame f lands in trace frame f+1.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — or the gate FAILs before any leg; and it
#   names the MAME (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete and every tap live. T1-T3 (+0x3A8),
#   T4 (+0x384), T5-T11 (B2) as stated in WHAT. CONTROLS (in-gate, each must make its check fail): sides-swapped (T2 and
#   T4 judged with P1 and P2 swapped), offset-swapped (T2 expecting $FF80D0 + 0x200 on P1), lowbits-shifted (T6/T7 with
#   the counting finish types taken as {0, 1}), bit7-kept (T9 expecting 0x05DD0E to keep bit 7), loser-side (T12 judging
#   the set side as the KO's loser), raises-forgotten (T7b with no raise on record), byte-shifted (T4b reading +0x386 as
#   +0x385), word-only (T1 judged with the low word of every store dropped from the
#   tap, as if the field were a word) and writer-unseen (T1 also listing PRG:0x01BEE4, a PC the tap never reports storing +0x3A8, so
#   a listed writer that never writes fails T1). The log's header names the commit and host.
# FOLLOWS: emu/mame-patches/ tests/lib/controls.sh tests/lib/mame_ident.sh tests/lua/field_trace.lua tests/lua/read_tap.lua
#   tests/replays/02_demitri_vs_cpu.rpl tests/replays/03_two_player_vs.rpl tests/replays/26_don_arcade_mash.rpl
#   tests/replays/37_victor_ko_vsavj.rpl tests/replays/105_legacy_2pwin_auto.rpl tests/replays/128_shadow_vs_legacy_vsavj.rpl
#   tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py tests/expected/registry.tsv
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: perturbed-copy: sides-swapped — T2 and T4 judged with the two sides' traces swapped must fail, so they see which side is which (in-gate; as a mode they judge the swapped traces and the gate FAILs)
# MUST-FIRE: perturbed-copy: offset-swapped — T2 expecting P1's +0x3A8 at $FF80D0 + 0x200 (P2's offset) must fail, so the offset is measured, not assumed (in-gate; as a mode T2 expects it and the gate FAILs)
# MUST-FIRE: perturbed-copy: lowbits-shifted — T6 and T7 with the counting finish types taken as {0, 1} instead of {3, 4, 6} must fail, so the rule tells the counting KOs from the others (in-gate; as a mode they use {0, 1} and the gate FAILs)
# MUST-FIRE: perturbed-copy: bit7-kept — T9 expecting 0x05DD0E's write to keep the set's bit 7 must fail, so the clear is measured from its data (in-gate; as a mode T9 expects bit 7 kept and the gate FAILs)
# MUST-FIRE: perturbed-copy: loser-side — T12 judging each 0x009A2C set as landing on the side whose HP is <= 0 (the KO's loser) must fail, so the winner is measured from both HP words (in-gate; as a mode T12 judges the loser side and the gate FAILs)
# MUST-FIRE: perturbed-copy: raises-forgotten — T7b judged with no raise on record must fail (the field's 1 after each raise then precedes no raise), so T7b reads the field and pairs it with the raises (in-gate; as a mode T7b forgets the raises and the gate FAILs)
# MUST-FIRE: perturbed-copy: byte-shifted — T4b reading +0x386 as if it were +0x385 must fail, so T4b reads the byte it names (in-gate; as a mode T4b shifts and the gate FAILs)
# MUST-FIRE: perturbed-copy: word-only — T1 judged on a copy of the tap with the low word (+0x3AA) of every store dropped (a word store) must fail, so "long" is measured from the writes (in-gate; as a mode T1 judges words and the gate FAILs)
# MUST-FIRE: perturbed-copy: writer-unseen — T1 with PRG:0x01BEE4 (a PC the tap never reports storing +0x3A8) added to the writer list must fail, so every listed writer is an observed one (in-gate; as a mode T1 lists it and the gate FAILs)
#
# NOT COVERED: only finish types 0, 1 and 3 occur in these replays: that 3 counts and 0 and 1 do not is measured; that 4
#   and 6 count and 2, 5 and 7 do not is S0's static rule, not an observation; the +0x3BF raise (type 4) is never seen; whether $FF80D0 alternating with 0x0091C000 on some legs
#   (01, 10, 21, 26 in the 14z-214 PILOT census) ever moves +0x3A8 is not judged; +0x354 (Jedah's child-slot word) needs a
#   slot-ownership rig and is not here.
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] tests/audit_mizuumi_rows_b.sh
#   emulator tier, MAME; ~1 min (twelve legs in parallel; 26_don_arcade_mash is 40,600 frames)
set -u
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep >/dev/null 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else
    W="$(mktemp -d)" || { echo "FAIL: audit_mizuumi_rows_b — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

F="ff80d0:l:g80d0"; RT=""
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 050:w:hp 384:l:c384 3a8:l:c3a8 3b6:b:c3b6 3be:b:c3be 3bf:b:c3bf; do
        F="$F,$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"
    done
    for o in 384:4 3a8:4 3b6:2 3be:2; do RT="$RT${RT:+;}$(printf '%06x' $((base + 0x${o%%:*}))),${o#*:}"; done
done
leg() {  # leg <name> <replay> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" FIELDS="$F" \
        FIELD_OUT="$W/$1.fields" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj \
        -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
tapleg() {  # tapleg <name> <replay> <frames>
    d="$W/$1"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$2" RTAP="$RT" WINDOW="0,0" \
        TRACE_OUT="$W/$1.tap" FRAMES="$3" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/read_tap.lua" \
        > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) </dev/null 2>/dev/null || true
}
LEGS="02:tests/replays/02_demitri_vs_cpu.rpl:12000 03:tests/replays/03_two_player_vs.rpl:12000
      26:tests/replays/26_don_arcade_mash.rpl:40600 37:tests/replays/37_victor_ko_vsavj.rpl:9600
      105:tests/replays/105_legacy_2pwin_auto.rpl:9600 128:tests/replays/128_shadow_vs_legacy_vsavj.rpl:21000"
echo "== 1. the legs (pristine vsavj, MAME)"
for l in $LEGS; do
    n="${l%%:*}"; rest="${l#*:}"; r="${rest%%:*}"; fr="${rest#*:}"
    leg "$n" "$r" "$fr" & tapleg "tap$n" "$r" "$fr" &
done
wait
fail=0
for l in $LEGS; do
    n="${l%%:*}"
    grep -q '^FIELDSUMMARY' "$W/$n.fields" 2>/dev/null || { echo "  FAIL  $n: no FIELDSUMMARY (see $W/$n/mame.log) — VOID"; fail=1; }
    grep -q '^END ' "$W/tap$n.tap" 2>/dev/null || { echo "  FAIL  tap$n: no END line (see $W/tap$n/mame.log) — VOID"; fail=1; }
done
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_rows_b (a leg did not complete)"; exit 1; }
echo "  ok    twelve legs complete"

echo "== 2. the checks"
python3 - "$W" "$MODE" <<'PY'
import sys
W, mode = sys.argv[1], sys.argv[2]
LEGS = ("02", "03", "26", "37", "105", "128")
def fields(n):
    out = []
    for l in open(f"{W}/{n}.fields"):
        if l.startswith("F "):
            p = l.split(); out.append((int(p[1]), {k: int(v) & 0xFFFFFFFF for k, v in (x.split("=") for x in p[2:])}))
    return out
def writes(n):
    w = []
    for l in open(f"{W}/tap{n}.tap"):
        p = l.split()
        if p and p[0] == "W":   # W <frame> PC <pc> off <addr> data <val> mask <m>
            w.append((int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16), int(p[9], 16)))
    return w
F = {n: fields(n) for n in LEGS}; T = {n: writes(n) for n in LEGS}
if mode == "sides-swapped":
    F = {n: [(f, {k[:-1] + {"1": "2", "2": "1"}.get(k[-1], k[-1]) if k[-1] in "12" else k: v for k, v in r.items()}) for f, r in rows]
         for n, rows in F.items()}
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
for n in LEGS:
    say(any(f < 1000 for f, *_ in T[n]), f"tap {n}: live ({sum(1 for f, *_ in T[n] if f < 1000)} writes before f1000)")
SIDE = {1: 0xFF8400, 2: 0xFF8800}
VALUE_PCS = {0x01BEE2, 0x01C186, 0x01C692}
UNSEEN_PC = 0x01BEE4   # writer-unseen: a PC the tap never reports storing +0x3A8 in these replays
# T1: +0x3A8's value writers store a LONG (both words, same PC, same frame)
def t1(word_only=False, pcs=VALUE_PCS):
    odd = []; per = {pc: 0 for pc in pcs}
    for n in LEGS:
        for s, b in SIDE.items():
            # the control drops the low word of each store from the tap, so the same data reads as a word store
            ws = [(f, pc, a - b) for f, pc, a, d, m in T[n] if pc in pcs and a in (b + 0x3A8, b + 0x3AA)
                  and not (word_only and a == b + 0x3AA)]
            for f, pc, off in ws: per[pc] += off == 0x3A8
            by = {}
            for f, pc, off in ws: by.setdefault((f, pc), set()).add(off)
            odd += [(n, s, k) for k, v in by.items() if v != {0x3A8, 0x3AA}]
    # every listed writer must be seen: a PC that never stores would pass the both-words test vacuously
    return not odd and all(per.values()), odd, per
ok, odd, per = t1(mode == "word-only", VALUE_PCS | ({UNSEEN_PC} if mode == "writer-unseen" else set()))
say(ok, f"T1 +0x3A8 value writes (0x01BEE2/0x01C186/0x01C692) always store both words in one frame: {len(odd)} not; "
        f"stores per writer {dict(sorted((hex(k), v) for k, v in per.items()))}, each writer seen")
# T2: +0x3A8 reads only 0 or $FF80D0's 0x0090C000 + 0x140 (P1) / + 0x200 (P2)
OFF = {1: 0x140, 2: 0x200}
if mode == "offset-swapped": OFF = {1: 0x200, 2: 0x140}
seen = {1: set(), 2: set()}
for n in LEGS:
    for f, v in F[n]:
        for s in (1, 2): seen[s].add(v[f"c3a8{s}"])
want = {s: {0, 0x0090C000 + OFF[s]} for s in (1, 2)}
say(seen[1] <= want[1] and seen[2] <= want[2] and len(seen[1]) == len(seen[2]) == 2,
    f"T2 +0x3A8 values P1 {sorted(hex(x) for x in seen[1])} P2 {sorted(hex(x) for x in seen[2])} (0x0090C000 + 0x140 / + 0x200)")
# T3: those writers are the only non-zero writers
nz = sorted({hex(pc) for n in LEGS for f, pc, a, d, m in T[n] if f >= 1000 and (a & 0xFFF) in (0x7A8, 0x7AA, 0xBA8, 0xBAA) and d & m and pc not in VALUE_PCS})
boot = sorted({hex(pc) for n in LEGS for f, pc, a, d, m in T[n] if f < 1000 and (a & 0xFFF) in (0x7A8, 0x7AA, 0xBA8, 0xBAA) and d & m and pc not in VALUE_PCS})
say(boot == ["0xd34"], f"T3b before f1000 the only other non-zero +0x3A8 writer is the boot RAM test: {boot}")
say(not nz, f"T3 after the boot (f1000; the RAM test at 0x000D34 fills work RAM with 0xFFFF at f15) no other PC writes a non-zero +0x3A8 word: {nz}")
# T4: +0x384's byte, per side, the frozen sequence of values per replay
SEQ = {"02": ([0, 6, 8, 10, 0], [0]), "03": ([0, 6], [0, 2, 0, 2, 6]), "26": ([0, 6, 8, 10, 0], [0]),
       "37": ([0, 6, 8, 10, 0], [0, 2, 0, 2, 6]), "105": ([0, 6], [0, 2, 0, 2, 6, 8, 10, 0]),
       "128": ([0, 6], [0, 2, 0, 2, 6, 8, 10, 0])}
got4 = {}
for n in LEGS:
    sq = []
    for s in (1, 2):
        q = []
        for f, v in F[n]:
            b = (v[f"c384{s}"] >> 24) & 0xFF
            if not q or q[-1] != b: q.append(b)
        sq.append(q)
    got4[n] = tuple(sq)
say(all(list(got4[n]) == list(SEQ[n]) for n in LEGS), f"T4 +0x384 byte sequences per side {got4} (frozen)")
# T4b: the long's other bytes: +0x385 a second-level index (even, 0..6 seen), +0x386..+0x387 always 0
SH385 = 8 if mode == "byte-shifted" else 16   # the control reads +0x386 as if it were +0x385
b385 = sorted({(v[f"c384{s}"] >> SH385) & 0xFF for n in LEGS for f, v in F[n] for s in (1, 2)})
low = sorted({v[f"c384{s}"] & 0xFFFF for n in LEGS for f, v in F[n] for s in (1, 2)})
say(b385 == [0, 2, 4, 6] and low == [0], f"T4b +0x385 values {b385} (frozen 0, 2, 4, 6); +0x386..+0x387 values {low} (frozen 0)")
# B2: bit 7 of +0x3B6 (the even byte of its word) set at 0x009A2C; +0x3BE raised at 0x05E2DC
COUNTING = {0, 1} if mode == "lowbits-shifted" else {3, 4, 6}
sets, raises = [], []
for n in LEGS:
    for f, pc, a, d, m in T[n]:
        s = 1 if a < 0xFF8800 else 2
        if pc == 0x009A2C and (a & 0xFFF) in (0x7B6, 0xBB6): sets.append((n, s, f, (d >> 8) & 0xFF))
        if pc == 0x05E2DC and (a & 0xFFF) in (0x7BE, 0xBBE): raises.append((n, s, f))
say(all(v & 0x80 for *_, v in sets), f"T5 every 0x009A2C write sets bit 7 of +0x3B6: {[(n, s, f, hex(v)) for n, s, f, v in sets]}")
ok6 = all(any(n2 == n and s2 == s and f2 == f and (v & 0x7F) in COUNTING for n2, s2, f2, v in sets) for n, s, f in raises)
say(ok6 and raises, f"T6 every 0x05E2DC raise of +0x3BE comes in the frame of a set whose low bits are in {sorted(COUNTING)}: {raises}")
ok7 = all(not any(n2 == n and s2 == s and f <= f2 <= f + 600 for n2, s2, f2 in raises) for n, s, f, v in sets if (v & 0x7F) not in COUNTING)
say(ok7, f"T7 no raise follows a set whose low bits are not in {sorted(COUNTING)} (600 frames)")
# T7b: no PC but 0x05E2DC writes +0x3BE non-zero in game, and the field reads it non-zero only after a raise on that side
other = sorted({hex(pc) for n in LEGS for f, pc, a, d, m in T[n] if f >= 1000 and (a & 0xFFF) in (0x7BE, 0xBBE) and m & 0xFF00 and (d >> 8) & 0xFF and pc != 0x05E2DC})
def t7b_early(rs):
    return [(n, s, f) for n in LEGS for s in (1, 2) for f, v in F[n] if v[f"c3be{s}"] and not any(n2 == n and s2 == s and f2 < f for n2, s2, f2 in rs)]
early = t7b_early([] if mode == "raises-forgotten" else raises)
say(not other and not early, f"T7b no other PC writes +0x3BE non-zero in game ({other}); no frame reads it non-zero before a raise on that side ({len(early)})")
say(len(sets) == 9 and len(raises) == 2, f"T8 counts: {len(sets)} bit-7 sets, {len(raises)} raises (frozen 9 and 2)")
# T9: 0x05DD0E rewrites each set's value without bit 7, same side, same frame
def t9(keep=False):
    out = []
    for n, s, f, v in sets:
        w = [(d >> 8) & 0xFF for f2, pc, a, d, m in T[n] if pc == 0x05DD0E and f2 == f and a == SIDE[s] + 0x3B6]
        out.append((n, s, f, hex(v), [hex(x) for x in w], w == [v if keep else v & 0x7F]))
    return all(x[-1] for x in out), out
ok9, r9 = t9(mode == "bit7-kept")
say(ok9, f"T9 0x05DD0E rewrites each set without bit 7 in its frame: {[x[:5] for x in r9]}")
# T10: each raise writes the previous value + 1; the next write to that +0x3BE word is a 0 from 0x016E4C/0x016E4E
r10 = []
for n, s, f in raises:
    a = SIDE[s] + 0x3BE
    prev = next((v[f"c3be{s}"] for f2, v in reversed(F[n]) if f2 <= f), None)
    raw = next((d for f2, pc, a2, d, m in T[n] if f2 == f and pc == 0x05E2DC and a2 == a), None)
    nxt = next(((f2, pc, d) for f2, pc, a2, d, m in T[n] if f2 > f and a2 == a), None)
    r10.append((n, s, f, prev, None if raw is None else (raw >> 8) & 0xFF, None if nxt is None else (nxt[0], hex(nxt[1]), nxt[2])))
def field_at(n, f, key):
    return next((v[key] for f2, v in F[n] if f2 == f), None)
after = [field_at(n, f + 1, f"c3be{s}") for n, s, f in raises]
ok10 = all(p is not None and v == p + 1 and nx and nx[2] == 0 and nx[1] in ("0x16e4c", "0x16e4e") for n, s, f, p, v, nx in r10) \
    and after == [x[4] for x in r10]
say(ok10, f"T10 each raise is the previous value + 1, the field reads it the next frame {after}, and the next write is a 0 from the block clear: {r10}")
# T11: +0x3BF reads 0 on every frame of every leg
nz11 = [(n, f) for n in LEGS for f, v in F[n] if v["c3bf1"] or v["c3bf2"]]
w11 = [(n, f, hex(pc)) for n in LEGS for f, pc, a, d, m in T[n] if f >= 1000 and (a & 0xFFF) in (0x7BE, 0xBBE) and m & 0xFF and d & 0xFF]
live11 = [n for n in LEGS if any(f < 1000 and (a & 0xFFF) in (0x7BE, 0xBBE) and m & 0xFF for f, pc, a, d, m in T[n])]
say(not nz11 and not w11 and live11 == list(LEGS),
    f"T11 +0x3BF is 0 on every frame of the six replays ({len(nz11)} frames not) and no in-game write makes it non-zero (tap: {w11}); the tap sees the +0x3BE/+0x3BF word's boot writes on {len(live11)} of 6 legs")
# T12: each 0x009A2C set lands on the side that just won a KO: its HP > 0, the other side's HP <= 0 (field, next frame)
def t12(loser=False):
    out = []
    for n, s, f, v in sets:
        o = 2 if s == 1 else 1
        sgn = lambda x: None if x is None else (x - (1 << 32) if x & 0x80000000 else x)   # the loader masked to 32 bits
        me, other = sgn(field_at(n, f + 1, f"hp{s}")), sgn(field_at(n, f + 1, f"hp{o}"))
        ok = me is not None and other is not None and ((me <= 0 < other) if loser else (other <= 0 < me))
        out.append((n, s, f, me, other, ok))
    return all(x[-1] for x in out), [x[:5] for x in out]
ok12, r12 = t12(mode == "loser-side")
say(ok12, f"T12 each 0x009A2C set lands on the KO winner (its HP > 0, the other's <= 0): {r12}")
if not mode:
    sw = {n: [(f, {k[:-1] + {"1": "2", "2": "1"}[k[-1]] if k[-1] in "12" else k: v for k, v in r.items()}) for f, r in rows] for n, rows in F.items()}
    sw_t2 = {s: set() for s in (1, 2)}
    for n in LEGS:
        for f, v in sw[n]:
            for s in (1, 2): sw_t2[s].add(v[f"c3a8{s}"])
    sw_ok = sw_t2[1] <= {0, 0x0090C140} and sw_t2[2] <= {0, 0x0090C200}
    off_ok = seen[1] <= {0, 0x0090C200}
    lb_ok = all(any(n2 == n and s2 == s and f2 == f and (v & 0x7F) in {0, 1} for n2, s2, f2, v in sets) for n, s, f in raises)
    for name, res in (("sides-swapped", sw_ok), ("offset-swapped", off_ok), ("lowbits-shifted", lb_ok), ("bit7-kept", t9(True)[0]), ("loser-side", t12(True)[0]), ("raises-forgotten", not t7b_early([])),
                      ("byte-shifted", sorted({(v[f"c384{s}"] >> 8) & 0xFF for n in LEGS for f, v in F[n] for s in (1, 2)}) == [0, 2, 4, 6]),
                      ("word-only", t1(True)[0]), ("writer-unseen", t1(False, VALUE_PCS | {UNSEEN_PC})[0])):
        print(f"CONTROL DEAD: {name} — the perturbed check still passed" if res else f"CONTROL FIRED: {name} — the perturbed check fails")
        if res: bad.append(name)
sys.exit(1 if bad else 0)
PY
rc=$?
[ "$rc" = 0 ] || { echo "FAIL: audit_mizuumi_rows_b"; exit 1; }
echo "PASS: audit_mizuumi_rows_b — +0x3A8 a long (0x0090C140 / 0x0090C200), +0x384 a per-player state index, +0x3BE raised after finish type 3, never after 0 or 1, on the KO winner"
