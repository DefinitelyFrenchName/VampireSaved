#!/bin/sh
# audit_mizuumi_354_3a8.sh — TWO MIZUUMI PLAYER-STRUCT CANDIDATES ON
# EXISTING REPLAYS — +0x354 IS JEDAH'S CHILD-OBJECT POINTER WORD (AND DEMITRI'S X-HISTORY WORD), +0x3A8 THE GFX-RAM ADDRESS
# OF THE FIGHTER'S OWN PALETTE ROW
#
# WHAT: on pristine vsavj, over eight corpus replays (01 02 07 30 21 22 24 26): after the boot the +0x354 word is written only
#   by Jedah's PRG:0x051118 / 0x0520AA, Demitri's 0x030EE0 / 0x030FF6 and the block clears 0x016E4C / 0x016E4E / 0x0222DA
#   (J1); every side holding any other character reads 0 on every frame (J2); at each Jedah store (157) the word names a live
#   $FFB800 pool slot of type 0x16 whose +0x32 is the storing fighter's block (J3) — the owner word the spawn writes
#   (`move.w a6,$32(a4)`, PRG:0x051114 / 0x05209C), not the pool's documented +0x30, which 0x051118's child holds the sibling
#   word +0x356 in (J3b); between stores the word outlives its child (dead or reused slots while it still names them, J4);
#   each Demitri store writes a value his own +0x10 took 0-63 frames before (J5: an X history, not a pointer).
#   And over 118_sel_b1..6 and 03: MAME's program space reads back a known pattern poked at CPU:$90C140 (A1); +0x3A8 equals
#   0x90C000 + (+0x18B)*0x20, the fighter's own OBJ palette row, on every frame both are set (A2), and MAME's latched OBJ
#   list draws entries with that row on >= 99% of them (A2b); at f4000 the 32 and 128 bytes there hash-equal P1's selected ROM
#   variant (+0x3A4, words OR 0xF000), six distinct for the six confirm buttons, P2's unchanged (A3); from f2300 P1's
#   (Demitri's) row equals the variant on even frames and not on odd ones, identically on all seven legs, P2's on every frame
#   (A4), the row rewritten every frame by the object palette copier PRG:0x02AD64 / 0x02AD78 (A4b); the row never equals the
#   other side's variant (A5); and nothing reads +0x3A8 / +0x3AA over f1000-5200 on b1 (A6). HASHES ONLY: no palette byte is
#   written anywhere.
# HOW: on MAME (the reference binary): per +0x354 replay a FIELD leg (tests/lua/field_trace.lua: both sides' +0x382, +0x10,
#   +0x354.w/.l, +0x356, +0x358, and every $FFB800 slot's +0x00, +0x02, +0x30, +0x32) and a WRITE-TAP leg (tests/lua/read_tap.lua
#   over both sides' +0x354..+0x359 and +0x10); per palette replay a pal_hash.lua leg (FNV-1a 32 hashes of [+0x3A8] and of the
#   [+0x3A4] variant, +0x18B, the latched-OBJ census); a poke leg (pal_hash.lua POKE_AT=3500 on b1), a counts-only write tap
#   on the rows 0x90C140 / 0x90C200 (pal_hash.lua WTAP=1, b1, 2400 frames), and a read tap over both sides' +0x3A4..+0x3AB
#   (read_tap.lua, b1, window f1000-5200). A tap write in tap frame f lands in trace frame f+1. At most three MAME at once.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row — or the gate FAILs before any leg; and it names the MAME
#   (tests/lib/mame_ident.sh), or the gate FAILs. Every leg complete and every tap live. J1-J5 and A1-A6 as in WHAT.
# FOLLOWS: emu/mame-patches/ tests/lua/field_trace.lua tests/lua/read_tap.lua tests/lua/pal_hash.lua tests/lib/controls.sh
#   tests/lib/mame_ident.sh tools/run_mame.sh tools/setup_mame.sh
#   tools/audit_roms.py tools/build_fingerprint.py docs/checksums.txt tests/expected/registry.tsv tests/replays/01_attract_long.rpl
#   tests/replays/02_demitri_vs_cpu.rpl tests/replays/07_mash_storm.rpl tests/replays/30_demitri_throw.rpl
#   tests/replays/21_don_mash.rpl tests/replays/22_don_dualmash.rpl tests/replays/24_don_winmash.rpl
#   tests/replays/26_don_arcade_mash.rpl tests/replays/118_sel_b tests/replays/03_two_player_vs.rpl
#
# SHEET: none — measures pristine vsavj and/or native vsav2 only; no leg of our build
#
# MUST-FIRE: perturbed-copy: slot-shifted — J3 judged against the NEXT pool slot (slot + 1) instead of the one the word names must fail, so the slot is the one named (in-gate; as a mode J3 shifts and the gate FAILs)
# MUST-FIRE: perturbed-copy: owner-30 — J3 judged with the pool's documented owner link +0x30 instead of +0x32 must fail, so the owner word is measured, not assumed (in-gate; as a mode J3 reads +0x30 and the gate FAILs)
# MUST-FIRE: perturbed-copy: sides-swapped — J3 and J5 judged against the OTHER side's block / X must fail, so the owner is this fighter (in-gate; as a mode they swap and the gate FAILs)
# MUST-FIRE: perturbed-copy: offside-source — A3 comparing P1's row with P2's variant must fail, so the match is to this fighter's variant (in-gate; as a mode A3 compares off-side and the gate FAILs)
# MUST-FIRE: perturbed-copy: one-button — A3 judged on b1's trace for all six buttons must fail, so six buttons give six rows (in-gate; as a mode A3 reads b1 six times and the gate FAILs)
# MUST-FIRE: perturbed-copy: row-shifted — A2 expecting 0x90C000 + (+0x18B + 1)*0x20 must fail, so the row is +0x18B's own (in-gate; as a mode A2 shifts and the gate FAILs)
# MUST-FIRE: perturbed-copy: poke-pattern — A1 expecting a different pattern hash must fail, so the read-back compares (in-gate; as a mode A1 expects it and the gate FAILs)
# MUST-FIRE: perturbed-copy: reader-range — A6 counting reads of +0x3A4 (which the copier reads) as if they were +0x3A8 must fail, so the read tap sees reads where they happen (in-gate; as a mode A6 reads +0x3A4 and the gate FAILs)
#
# NOT COVERED: "Graphics RAM Bank Allocation" (mizuumi's +0x354 name) — the slot is a $FFB800 object of type 0x16, not
#   judged to be a gfx bank; Jedah's .l velocity use of +0x354 (PRG:0x0516DC, 0x05179C, ...) never ran in these legs; Lei-Lei's
#   .l store (S0, 0x04B9D6) never ran; whether any reader (0x0511EA's `st.b $39(a4)` kill) runs while the word is stale is not
#   traced. For +0x3A8: only Demitri (P1) and Victor (P2) carry the palette legs; what P1's odd-frame row content is (the
#   copier's alternate source) and that it is Demitri-only is seen on four other replays in the scratch run, not gated here;
#   no reader of +0x3A8 was seen on one leg, so whether the engine ever uses it as a pointer is not judged; rows +1..+3 of the
#   128-byte block are hashed (A3) but which sprites draw with them is not.
#
# Usage: ROMDIR=... [MAME_BIN=...] [KEEP=<dir>] [CONTROL=<name>] tests/audit_mizuumi_354_3a8.sh
#   emulator tier, MAME; scope ondemand (the pristine-only ruling); ~2.5 min on the Mac (26 legs, three at a time)
# SHARES: self
set -u
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"; export ROMDIR
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"; MODE="${VS_CTL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep >/dev/null 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else
    W="$(mktemp -d "${TMPDIR:-/tmp}/a354.XXXXXX")" || { echo "FAIL: mktemp"; exit 2; }; trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

# THE LEGS. +0x354: per replay a FIELD leg (both sides' +0x382/+0x10/+0x354/+0x356/+0x358 and every $FFB800 pool slot's
# +0x00/+0x02/+0x30/+0x32) and a WRITE-TAP leg (both sides' +0x354..+0x359 and +0x10). +0x3A8: tests/lua/pal_hash.lua over
# 118_sel_b1..6 and 03, its poke leg (b1, POKE_AT=3500), its counts-only write tap (WTAP=1) and a read tap over +0x3A4..+0x3AB.
F354=""
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 382:b:id 010:w:x 354:w:w354 354:l:l354 356:w:w356 358:w:w358; do
        F354="$F354${F354:+,}$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"
    done
done
i=0
while [ $i -lt 32 ]; do
    sb=$((0xffb800 + i * 0x80))
    F354="$F354,$(printf '%06x' $sb):b:a$i,$(printf '%06x' $((sb + 2))):b:t$i,$(printf '%06x' $((sb + 0x30))):w:o30_$i,$(printf '%06x' $((sb + 0x32))):w:o32_$i"
    i=$((i + 1))
done
mkdir -p "$W/354" "$W/3a8"
run1() {  # run1 field|tap|pal|wt|rt <name> <replay> <frames> [poke_at]
    case "$1" in field) d="$W/354/$2.f" ;; tap) d="$W/354/$2.t" ;; *) d="$W/3a8/$2.d" ;; esac
    rm -rf "$d"; mkdir -p "$d"
    case "$1" in
    field) ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$3" FIELDS="$F354" \
               FIELD_OUT="$W/354/$2.fields" FRAMES="$4" timeout -k 30 1500 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    tap)   ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$3" RTAP="ff8754,6;ff8b54,6;ff8410,2;ff8810,2" \
               WINDOW="0,0" TRACE_OUT="$W/354/tap$2.tap" FRAMES="$4" timeout -k 30 1500 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    pal)   ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$3" POKE_AT="${5:-}" \
               TRACE_OUT="$W/3a8/$2.pal" FRAMES="$4" timeout -k 30 1200 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/pal_hash.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    wt)    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$3" WTAP=1 FROM=99999 \
               TRACE_OUT="$W/3a8/$2.pal" FRAMES="$4" timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/pal_hash.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    rt)    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$3" RTAP="ff87a4,8;ff8ba4,8" \
               WINDOW="1000,99999" TRACE_OUT="$W/3a8/$2.tap" FRAMES="$4" timeout -k 30 900 "$REPO/tools/run_mame.sh" vsavj \
               -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) ;;
    esac
}
L354="01:tests/replays/01_attract_long.rpl:7200 02:tests/replays/02_demitri_vs_cpu.rpl:5400
 07:tests/replays/07_mash_storm.rpl:4200 30:tests/replays/30_demitri_throw.rpl:4600
 21:tests/replays/21_don_mash.rpl:14000 22:tests/replays/22_don_dualmash.rpl:13800
 24:tests/replays/24_don_winmash.rpl:18400 26:tests/replays/26_don_arcade_mash.rpl:40600"
{
    for l in $L354; do
        n="${l%%:*}"; rest="${l#*:}"; r="${rest%%:*}"; fr="${rest#*:}"
        echo "field $n $r $fr"; echo "tap $n $r $fr"
    done
    for b in 1 2 3 4 5 6; do echo "pal b$b tests/replays/118_sel_b$b.rpl 5200"; done
    echo "pal 03 tests/replays/03_two_player_vs.rpl 5200"
    echo "pal pk tests/replays/118_sel_b1.rpl 3600 3500"
    echo "wt wt tests/replays/118_sel_b1.rpl 2400"
    echo "rt rt tests/replays/118_sel_b1.rpl 5200"
} > "$W/jobs"
echo "== 1. the legs (pristine vsavj, MAME, three at a time)"
k=0
while read -r kind name rpl fr pk; do
    run1 "$kind" "$name" "$rpl" "$fr" "$pk" </dev/null &
    k=$((k + 1)); [ $((k % 3)) = 0 ] && wait
done < "$W/jobs"
wait
fail=0
for l in $L354; do n="${l%%:*}"
    grep -q '^FIELDSUMMARY' "$W/354/$n.fields" 2>/dev/null || { echo "  FAIL  354/$n: no FIELDSUMMARY (see $W/354/$n.f/mame.log) — VOID"; fail=1; }
    grep -q '^END ' "$W/354/tap$n.tap" 2>/dev/null || { echo "  FAIL  354/tap$n: no END (see $W/354/$n.t/mame.log) — VOID"; fail=1; }
done
for n in b1 b2 b3 b4 b5 b6 03 pk wt; do
    grep -q '^PALSUMMARY' "$W/3a8/$n.pal" 2>/dev/null || { echo "  FAIL  3a8/$n: no PALSUMMARY (see $W/3a8/$n.d/mame.log) — VOID"; fail=1; }
done
grep -q '^END ' "$W/3a8/rt.tap" 2>/dev/null || { echo "  FAIL  3a8/rt: no END (see $W/3a8/rt.d/mame.log) — VOID"; fail=1; }
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_354_3a8 (a leg did not complete)"; exit 1; }
echo "  ok    $(wc -l < "$W/jobs" | tr -d ' ') legs complete"

# THE JUDGES, written beside the legs and run once per mode (the plain run re-judges the same legs under each control).
cat > "$W/judge354.py" <<'PY'
#!/usr/bin/env python3
"""judge354.py <rundir> <mode> — the +0x354 checks (audit_mizuumi_354_3a8.sh, 14z-215, #118). Modes: '' or a control name
(slot-shifted, owner-30, sides-swapped). Prints ok/FAIL lines and exits 1 on any FAIL."""
import sys, collections
W, mode = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
LEGS = ["01", "02", "07", "30", "21", "22", "24", "26"]
JEDAH, DEMITRI = 0x0F, 0x01
BLOCK = {1: 0x8400, 2: 0x8800}
PTR_PCS = {0x051118: 0x16, 0x0520AA: 0x16}        # Jedah's pointer stores and the type their spawn stamps (0x01001606 / 0x0100160C)
HIST_PCS = {0x030EE0, 0x030FF6}                     # Demitri's history-ring stores
CLEAR_PCS = {0x016E4C, 0x016E4E, 0x0222DA}          # the block clears (write 0)
def fields(n):
    out = {}
    for l in open(f"{W}/{n}.fields"):
        if l.startswith("F "):
            p = l.split(); out[int(p[1])] = {k: int(v) for k, v in (x.split("=") for x in p[2:])}
    return out
def taps(n):
    for l in open(f"{W}/tap{n}.tap"):
        p = l.split()
        if p and p[0] == "W": yield int(p[1]), int(p[3], 16), int(p[5], 16), int(p[7], 16), int(p[9], 16)
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
F = {n: fields(n) for n in LEGS}; T = {n: list(taps(n)) for n in LEGS}
for n in LEGS:
    say(any(f < 1000 for f, *_ in T[n]) and max(F[n]) > 1000, f"leg {n}: tap live ({sum(1 for f, *_ in T[n] if f < 1000)} boot writes), field {len(F[n])} frames")
def sidekey(s): return (3 - s) if mode == "sides-swapped" else s
# J1: the in-game writers of the +0x354 word, by PC, with the character that held the side
wr = collections.Counter()
for n in LEGS:
    for f, pc, a, d, m in T[n]:
        s = 1 if a < 0xFF8800 else 2
        if f >= 1000 and (a & 0x3FF) == 0x354:
            wr[(pc, F[n].get(f + 1, {}).get(f"id{s}"))] += 1
allowed = {(pc, JEDAH) for pc in PTR_PCS} | {(pc, DEMITRI) for pc in HIST_PCS} | {(pc, c) for pc in CLEAR_PCS for c in range(0x20)}
odd = {k: v for k, v in wr.items() if k not in allowed}
say(not odd and all(any(k[0] == pc for k in wr) for pc in list(PTR_PCS) + list(HIST_PCS)),
    f"J1 after the boot (f1000) the +0x354 word is written only by Jedah's 0x051118/0x0520AA, Demitri's 0x030EE0/0x030FF6 and the clears "
    f"0x016E4C/0x016E4E/0x0222DA, each seen: {dict(sorted((f'{pc:06x}/{c:02x}', v) for (pc, c), v in wr.items()))}; other {odd}")
# J2: on every other character the word reads 0 on every frame
nz = collections.Counter()
for n in LEGS:
    for f, r in F[n].items():
        for s in (1, 2):
            if r[f"id{s}"] not in (JEDAH, DEMITRI) and r[f"w354{s}"] != 0: nz[(n, s, r[f"id{s}"])] += 1
say(not nz, f"J2 every side not holding Jedah or Demitri reads +0x354 = 0 on every frame: {dict(nz)}")
# J3: at each Jedah pointer store (tap frame f, field frame f+1): the stored word names a $FFB800 slot that is alive, carries the
#     type its spawn stamped, and whose owner word +0x32 is this fighter's block (the spawn's `move.w a6,$32(a4)`)
OWNER = 0x30 if mode == "owner-30" else 0x32
n_ok = n_all = 0; fails = []; per = collections.Counter(); o30sib = [0, 0]
for n in LEGS:
    for f, pc, a, d, m in T[n]:
        if pc not in PTR_PCS or (a & 0x3FF) != 0x354: continue
        s = 1 if a < 0xFF8800 else 2
        r = F[n].get(f + 1)
        v = d & 0xFFFF
        n_all += 1; per[pc] += 1
        ok = r is not None and (r[f"w354{s}"] & 0xFFFF) == v and 0xB800 <= v < 0xC800 and (v - 0xB800) % 0x80 == 0
        if ok:
            i = (v - 0xB800) // 0x80
            if mode == "slot-shifted": i = (i + 1) % 32
            ok = r[f"a{i}"] != 0 and (r[f"t{i}"] & 0xFF) == PTR_PCS[pc] and (r[f"o{OWNER:x}_{i}"] & 0xFFFF) == BLOCK[sidekey(s)]
            if pc == 0x051118:
                o30sib[1] += 1; o30sib[0] += (r[f"o30_{(v - 0xB800) // 0x80}"] & 0xFFFF) == (r[f"w356{s}"] & 0xFFFF)
        n_ok += ok
        if not ok: fails.append((n, f, f"{pc:06x}", hex(v)))
say(n_all > 0 and n_ok == n_all, f"J3 at each of {n_all} Jedah pointer stores {dict((f'{k:06x}', v) for k, v in per.items())} the word names a live "
    f"$FFB800 slot of type 0x16 whose +0x{OWNER:x} is the storing fighter's block: {n_ok}/{n_all}; failing {fails[:5]}")
say(o30sib[1] > 0 and o30sib[0] == o30sib[1], f"J3b at each 0x051118 store the child's +0x30 holds the sibling child word +0x356 (spawn 0x05110E): {o30sib[0]}/{o30sib[1]}")
# J4: what the word holds between stores — the pointer stays after its child dies (stale), counted per frame on Jedah's sides
st = collections.Counter()
for n in LEGS:
    for f, r in F[n].items():
        for s in (1, 2):
            if r[f"id{s}"] != JEDAH: continue
            v = r[f"w354{s}"] & 0xFFFF
            if v == 0: st["zero"] += 1; continue
            if not (0xB800 <= v < 0xC800 and (v - 0xB800) % 0x80 == 0): st["not-a-slot"] += 1; continue
            i = (v - 0xB800) // 0x80
            alive, own = r[f"a{i}"] != 0, (r[f"o32_{i}"] & 0xFFFF) == BLOCK[s]
            st["live, +0x32 = this fighter" if alive and own else "live, +0x32 another" if alive else "dead slot (stale)"] += 1
say(st["not-a-slot"] == 0 and st["dead slot (stale)"] > 0, f"J4 on Jedah's frames every non-zero +0x354 word is a $FFB800 slot address (never Jedah's .l velocity "
    f"use, PRG:0x0516DC, which no leg reached); the word outlives its child: {dict(st)}")
# J5: Demitri — each history store writes a value the fighter's own X (+0x10) took within the 64 frames before: the field's
#     frame_done X, or a value written to +0x10 (the tap; two engine ticks can fall in one frame, so frame_done misses some X)
lags = collections.Counter(); miss = []
for n in LEGS:
    xw = collections.defaultdict(set)
    for f, pc, a, d, m in T[n]:
        if (a & 0x3FF) == 0x010: xw[(1 if a < 0xFF8800 else 2, f)].add(d & 0xFFFF)
    for f, pc, a, d, m in T[n]:
        if pc not in HIST_PCS or (a & 0x3FF) != 0x354: continue
        s = 1 if a < 0xFF8800 else 2
        v = d & 0xFFFF; got = None; ss = sidekey(s)
        for lag in range(0, 64):
            r = F[n].get(f + 1 - lag)
            if (r and (r[f"x{ss}"] & 0xFFFF) == v) or v in xw.get((ss, f - lag), ()): got = lag; break
        if got is None: miss.append((n, f, f"{pc:06x}"))
        else: lags[min(got, 16)] += 1
say(lags and not miss, f"J5 each of {sum(lags.values())} Demitri history stores (0x030EE0/0x030FF6) writes a value the same fighter's +0x10 took 0-63 frames "
    f"before (lag histogram, 16 = 16+: {dict(sorted(lags.items()))}); unmatched {miss[:5]}")
print(f"VERDICT {'FAIL' if bad else 'PASS'} ({len(bad)} failing)")
sys.exit(1 if bad else 0)
PY
cat > "$W/judge3a8.py" <<'PY'
#!/usr/bin/env python3
"""judge3a8.py <dir> <mode> — the +0x3A8 palette-read checks (audit_mizuumi_354_3a8.sh, 14z-215, #118). <dir> holds b1..b6.pal, 03.pal, pk.pal
(pal_hash.lua), wt.pal (pal_hash.lua WTAP=1 on b1) and rt.tap (read_tap.lua over +0x3A4..+0x3AB both sides on b1).
Controls (modes): offside-source, one-button, row-shifted, poke-pattern, reader-range. HASHES ONLY."""
import sys, collections
W, mode = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
LEGS = ["b1", "b2", "b3", "b4", "b5", "b6", "03"]
def rows(n):
    d = {}
    for l in open(f"{W}/{n}.pal"):
        if l.startswith("F "):
            p = l.split(); d[int(p[1])] = dict(x.split("=") for x in p[2:])
    return d
bad = []
def say(ok, msg):
    print(("  ok    " if ok else "  FAIL  ") + msg)
    if not ok: bad.append(msg)
for n in LEGS + ["pk", "wt"]:
    say("PALSUMMARY" in open(f"{W}/{n}.pal").read(), f"leg {n}: complete")
R = {n: rows(n) for n in LEGS}
# A1: the instrument reads GFX RAM: a known 32-byte pattern poked at 0x90C140 reads back (same callback)
pk = [l.split() for l in open(f"{W}/pk.pal") if l.startswith("PK ")]
want = (lambda h: format(int(h, 16) ^ 1, "08x")) if mode == "poke-pattern" else (lambda h: h)
say(len(pk) == 1 and want(pk[0][2].split("=")[1]) == pk[0][3].split("=")[1],
    f"A1 poke read-back at CPU:$90C140 (32-byte known pattern, not ROM data): {' '.join(pk[0][1:]) if pk else 'no PK line'}")
# A2: +0x3A8 is the GFX-RAM address of the fighter's own palette row +0x18B (0x90C000 + row*0x20) on every frame both are set
add = 0x20 if mode == "row-shifted" else 0
tot = good = 0; drawn = collections.Counter(); seen = collections.Counter()
for n in LEGS:
    for f, r in R[n].items():
        for s in (1, 2):
            if r[f"P{s}"] == "00000000" or r[f"R{s}"] == "00": continue
            tot += 1; good += int(r[f"P{s}"], 16) == 0x90C000 + int(r[f"R{s}"], 16) * 0x20 + add
            seen[(s, r[f"P{s}"], r[f"R{s}"])] += 1; drawn[s] += int(r[f"n{s}"]) > 0
say(tot > 0 and good == tot, f"A2 +0x3A8 == 0x90C000 + (+0x18B)*0x20 on {good}/{tot} side-frames ({dict((f'P{k[0]} {k[1]} row {k[2]}', v) for k, v in seen.items())})")
say(drawn[1] >= 0.99 * seen[(1, '0090c140', '0a')] and drawn[2] >= 0.99 * seen[(2, '0090c200', '10')],
    f"A2b the latched OBJ list (m_cps2_buffered_obj) holds entries drawn with that row on {drawn[1]} (P1) and {drawn[2]} (P2) of those frames (>= 99%)")
# A3: at f4000 the 32 and 128 bytes there equal the selected ROM variant (+0x3A4, words OR 0xF000), one per button, P2's untouched
F0 = 4000
blk = {}; okv = []
for i, n in enumerate(LEGS[:6]):
    r = R["b1" if mode == "one-button" else n][F0]
    so = "2" if mode == "offside-source" else "1"
    okv.append(r["hp1"] == r[f"hs{so}"] and r["hq1"] == r[f"hsq{so}"] and int(r["K1"], 16) == i and r["E1"] == r["K1"])
    blk[n] = (r["hq1"], r["hp2"])
say(all(okv) and len({v[0] for v in blk.values()}) == 6 and len({v[1] for v in blk.values()}) == 1,
    f"A3 f{F0}: P1's 32/128 bytes at [+0x3A8] == its selected variant on {sum(okv)}/6 buttons (+0x3E1 = +0x3AE = K-1), "
    f"{len({v[0] for v in blk.values()})} distinct P1 blocks, {len({v[1] for v in blk.values()})} P2 block(s)")
# A4: over the match, frames where the block equals the side's own variant, frozen; P1 (Demitri) alternates by frame parity
cnt = {}
for n in LEGS:
    c = collections.Counter()
    for f, r in R[n].items():
        if f < 2300 or r["P1"] == "00000000": continue
        for s in (1, 2): c[(s, f % 2, r[f"hp{s}"] == r[f"hs{s}"])] += 1
    cnt[n] = c
c0 = cnt["b1"]
say(all(cnt[n] == c0 for n in LEGS) and c0[(1, 0, True)] >= 1440 and c0[(1, 1, False)] >= 1430 and c0[(2, 0, False)] + c0[(2, 1, False)] < 100,
    f"A4 from f2300, per leg identical on all seven: P1 block == variant on even frames {c0[(1, 0, True)]}, != on odd {c0[(1, 1, False)]} "
    f"(odd ==: {c0[(1, 1, True)]}, even !=: {c0[(1, 0, False)]}); P2 == {c0[(2, 0, True)] + c0[(2, 1, True)]}, != {c0[(2, 0, False)] + c0[(2, 1, False)]}")
wt = collections.Counter()
for l in open(f"{W}/wt.pal"):
    p = l.split()
    if p and p[0] == "W" and 2200 <= int(p[1]) < 2400: wt[(p[2], p[3])] += 1
say(wt[("02ad64", "140")] == 200 and wt[("02ad78", "140")] == 200,
    f"A4b row 0x140 is rewritten on every frame f2200-2399 by the object palette copier PRG:0x02AD64/0x02AD78 (frames: {dict(wt)})")
# A5: control built in — the block never equals the OTHER side's variant
x = sum(r[f"hp{s}"] == r[f"hs{3 - s}"] for n in LEGS for f, r in R[n].items() if r["P1"] != "00000000" for s in (1, 2))
say(x == 0, f"A5 [+0x3A8]'s 32 bytes never equal the other side's variant: {x} side-frames")
# A6: nothing reads +0x3A8 (f1000-5200, b1) while the tap sees the copier read +0x3A4 (liveness)
rd = collections.Counter()
for l in open(f"{W}/rt.tap"):
    p = l.split()
    if p and p[0] == "R": rd[int(p[5], 16) & 0x3FF] += 1
lo = 0x3A4 if mode == "reader-range" else 0x3A8
say(rd[0x3A4] > 0 and rd[lo] + rd[lo + 2] == 0, f"A6 reads of +0x3A8/+0x3AA over f1000-5200 on b1: {rd[lo] + rd[lo + 2]} (tap live: +0x3A4 read {rd[0x3A4]} times)")
print(f"VERDICT {'FAIL' if bad else 'PASS'} ({len(bad)} failing)")
sys.exit(1 if bad else 0)
PY
echo "== 2. the checks"
python3 "$W/judge354.py" "$W/354" "$MODE"; r1=$?
python3 "$W/judge3a8.py" "$W/3a8" "$MODE"; r2=$?
if [ -n "$MODE" ]; then
    [ "$r1" = 0 ] && [ "$r2" = 0 ] && { echo "PASS: audit_mizuumi_354_3a8 (CONTROL=$MODE did NOT fire)"; exit 0; }
    echo "FAIL: audit_mizuumi_354_3a8 (CONTROL=$MODE)"; exit 1
fi
dead=0
for c in slot-shifted owner-30 sides-swapped; do
    if python3 "$W/judge354.py" "$W/354" "$c" >/dev/null; then echo "CONTROL DEAD: $c — the perturbed check still passed"; dead=1; else echo "CONTROL FIRED: $c — the perturbed check fails"; fi
done
for c in offside-source one-button row-shifted poke-pattern reader-range; do
    if python3 "$W/judge3a8.py" "$W/3a8" "$c" >/dev/null; then echo "CONTROL DEAD: $c — the perturbed check still passed"; dead=1; else echo "CONTROL FIRED: $c — the perturbed check fails"; fi
done
[ "$r1" = 0 ] && [ "$r2" = 0 ] && [ "$dead" = 0 ] || { echo "FAIL: audit_mizuumi_354_3a8"; exit 1; }
echo "PASS: audit_mizuumi_354_3a8 — +0x354 Jedah's live type-0x16 child pointer at every store (+0x32 owner), Demitri's X history; +0x3A8 = 0x90C000 + row +0x18B, holding the selected variant (6/6 buttons), never read"
