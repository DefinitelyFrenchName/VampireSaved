#!/bin/sh
# audit_mizuumi_chars.sh — THE CHARACTER-SPECIFIC FIELDS OF THE FIGHTER BLOCK, MEASURED (14z-196, promoted from the #118
# pilot of 14z-194, GitHub #118; HOMING item 5 of build/agent194/t118/HOMING.md)
#
# WHAT: on pristine vsavj, the character-specific rows atlas/ram.md records hold as measured, each judged on EVERY leg and
#   side against a quantity read independently of it (the projectile pool $FF9400 + n*0x100: +0x00 alive, +0x02 type,
#   +0x30 owner; both HP words; the character id +0x382; the engine pass counter $FF8081; the replay's own input script):
#   K1 +0x149 reads 1 only while the side owns a live type-4 projectile (Demitri's flare) and rises on the frame each
#      such projectile appears (offset frozen); K2 +0x14B equals the side's live type-41 projectile count (Q-Bee's) on
#      every in-match frame; K3 every +0x0AC 1-span of a side is followed within 20 frames by a new type-4 projectile of
#      that side, and every such projectile is preceded within 20 frames by a span start (the motion before the flare);
#   K4 every +0x192 1-span of a side starts 0-1 frames after that side's HP fell while the OPPONENT owned a live type-4
#      projectile, every such fall starts one, and each span lasts 37 frames; K5 every 0x030EF4 write of +0x372 is 2 when
#      the opponent stands to the side's right and 3 to its left, +0x372 is nonzero only on a Demitri side (0x01), and
#      118_dash's P1 has exactly as many 0x030EF4 writes as its script has dashes (two same-direction taps <= 8 frames
#      apart); K6 every nonzero +0x15C span falls by at least the engine passes of each frame (Δ$FF8081), never rises
#      inside, and its side neither loses HP nor starts an attack (+0x1B8) during it; K7 +0x1A2 is nonzero on exactly the
#      frames a Gallon side's (0x02) Dark Force mode +0x110 is nonzero, and stays 0 through every other character's Dark
#      Force; K8 every nonzero +0x154 write is by a writer PC credited to one character; K9 on 118_mo_kthrow (P1 forced to
#      Morrigan) each P2 +0x19A 0xFF span holds a P2 HP fall (the throw connected), P1's +0x136 rises on the frame each
#      ends and lasts a frozen length; K10 on 118_anak_taunt (P1 forced to Anakaris) +0x1BB rises once, 0-2 frames after
#      the first START+LP+MP+HP press in the match, holds a frozen length, and on every other leg stays 0; K11 +0x3C1 reads
#      1 only on the side whose script moves D,D,D before its select confirm (118_random's P1), from that confirm; K12 THE
#      SLOT OWNERSHIP CENSUS over the whole tapped range +0x34..+0x37 and +0x360..+0x37F: every non-clear writer PC
#      writes only into blocks holding ONE character (per-character scratch), every written byte's writers and the named
#      slots' owner lines atlas/ram.md quotes are frozen. A WRITE IS CREDITED TO THE BLOCK IT LANDS IN, never to the code
#      that ran (Morrigan's kick throw 0x03B2DA writes the victim's +0x19A and is credited to the victim) — K8 and K12
#      measure which characters' blocks a PC writes, not whose routine it is. A block's CHARACTER is read from its loaded +0x60 character-data base against
#      vsavj's own table PRG:0x0BD97A (the data view, decrypted at run time), never from the poked +0x382 (every check reads
#      the character through it; +0x382 only where a base is in no row, counted): K0 proves each forced pick by it, K0b
#      holds +0x382 to it on every in-match side-frame but the arcade ladder's pre-write on a CPU side after the round
#      timer reached 0 (counted, allowed; control prewrite-human), and K8/K12 credit their writers by it. Every writer set,
#      reader set (the read legs: +0x154 and +0x0AC words on 128 and the flare leg), span and count is frozen in
#      tests/expected/mizuumi_chars.tsv.
# HOW: on MAME (the reference binary), FIELD legs under tests/lua/field_trace.lua — the side fields above plus all 32
#   pool slots — and WRITE-TAP legs under tests/lua/read_tap.lua, on 105_projectile_clash_ctl (P1 Demitri's flares),
#   118_dash, 118_mo_kthrow and 118_anak_taunt (forced picks by POKES, each proved by its loaded +0x60 base), 118_random, and
#   the 13 census replays of the 14z-194 pilot (01 10 26 07 08 29 128 19 21 22 24 30 50 — the corpus replays that play
#   OTHER characters); two READ-TAP legs (WINDOW the whole run) over both blocks' +0x154 and +0x0AC words on 128 and the
#   flare leg. The analysis is tools/mizuumi_chars.py (its --pert modes are the controls). TWO MAME PROCESSES PER LEG
#   (field and tap): K8 and K12 credit each write from the SAME tap run — it logs both blocks' +0x60 base words, so the
#   base in force at a write is the one that run last wrote (rule-checker run 2026-10-08-908) — and wherever a check
#   still joins the two runs, two checks MEASURE the pairing on every leg: KA, frame alignment only (the tap run's write
#   of the vblank counter RAM:$FF8080 in tap frame f equals the field run's sample at f+1 — the counter advances whatever
#   the input; control tap-misaligned) and KS, the same game (both sides' X and HP words rebuilt from the tap run's own
#   writes equal the field run's samples on every frame; control tap-other-game, a tap run of a different game). No leg
#   arms a debugger breakpoint or watchpoint (both scripts are memory taps); that their input stayed aligned (#228's
#   class) is KS's measurement, not an assumption.
# EXPECTS: the header names the ROM — every reference member verified against docs/checksums.txt, the vsavj program
#   fingerprint equal to the registry's vsavj row, each loaded zip's sha1 — and the MAME (tests/lib/mame_ident.sh), or the
#   gate FAILs before any leg; K0, K0b and K1-K12 as stated, each over a nonzero sample; every count equal
#   to the frozen file; each control FAILs.
# FOLLOWS: emu/mame-patches/ tests/expected/mizuumi_chars.tsv tests/lib/controls.sh tests/lib/mame_ident.sh tests/lib/decrypt_cache.sh tools/cps2_decrypt.py
#   tests/lua/field_trace.lua tests/lua/pokes_spec.lua tests/lua/read_tap.lua tests/replays/ tools/mizuumi_chars.py
#   tools/run_mame.sh tools/setup_mame.sh tools/audit_roms.py docs/checksums.txt tools/build_fingerprint.py
#   tests/expected/registry.tsv
#
# MUST-FIRE: perturbed-copy: absent-move — the checks run with every leg's move detector emptied (no own flare, no opponent flare, no Gallon Dark Force, no taunt press, no D,D,D) must fail K1, K3, K4, K7, K10 and K11, so each flag would be seen set where its move is absent (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: wrong-owner — the ownership census with one non-clear writer PC that writes ONLY UNNAMED bytes of the tapped range credited to a second character must fail K12, so a shared-code writer anywhere in +0x34..+0x37 / +0x360..+0x37F would be caught (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: prewrite-human — K0b with the side of the arcade ladder's pre-write frames read as HUMAN must fail, so the 75 allowed frames are allowed only on a CPU side (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: tap-misaligned — KA comparing the tap run's RAM:$FF8080 writes with the field run's samples one frame later than they land must fail, so the two logs are proved FRAME-ALIGNED (the vblank counter cannot tell two games apart: that is KS) (in-gate; as a mode the gate FAILs)
# MUST-FIRE: known-bad: tap-other-game — KS with the flare leg's tap run replaced by a tap run of a DIFFERENT game (the replay with P1's inputs from f3000 two frames later, run in-gate) must fail, so the two runs of a leg are proved to have played the same game (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: next-load-wrong — K0b with each waived span judged against the id after the one the side loads next must fail, so the waiver's "loads next" test is applied (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: wrong-base — K0 with each forced pick judged against ANOTHER character's +0x60 table row (id ^ 1) must fail, so the pick is proved by the base the game loaded, not by the poked +0x382 (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: pool-miscount — K2 with every side's type-41 count shifted by one must fail, so +0x14B is compared with the count, not merely with itself (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: passes-inflated — K6 judged against each frame's engine passes ($FF8081) plus one must fail, so the "falls by at least the passes" check reads the pass counter (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: fall-shifted — K9 with P2's HP falls moved 30 frames later must fail, so the throw's fall is paired with the +0x19A span it ends (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: taps-as-dashes — K5 with 118_dash's script count taking every tap for a dash must fail, so the write count is held to the dashes, not the taps (in-gate; as a mode the gate FAILs)
# MUST-FIRE: perturbed-copy: other-side-credit — K8 with every write credited to the OPPOSITE block's character must fail, so the one-character crediting reads the writing side (in-gate; as a mode the gate FAILs)
#
# NOT COVERED: that +0x154 and +0x0AC are read ON THE OPPONENT through the +0x32 link (static, not measured here — the
#   read tap sees the PC and the block, not which fighter's code runs); +0x15C's dizzy-vs-hold distinction and its
#   random amounts; +0x14B for Sasquatch / Lei-Lei / Aqua Spread (not observed); +0x1A2 for Lilith's and Demitri's Dark
#   Force (not observed); +0x136's camera effect and its Jedah / Zabel / Lilith writers' moves (the census credits them);
#   +0x3C1's random pick itself; the per-character slots' MEANINGS (ownership only); which character's CODE writes a
#   byte (the census credits the block written, so a writer into the opponent's block is credited to the opponent); that the two FORCED picks (POKES at
#   $FF8782 over P1's default cell) carry nothing of that cell their subjects read — the confirm writes the cell's id
#   copies +0x3BD/+0x3E0 ([VSP-123], #151), unread in play on every leg tapped at 14z-161, not re-tapped here, and
#   tools/audit_poked_legs.py scans native vs2 and WIDE legs only, not pristine vsavj; merged-m23; FBNeo (one emulator).
#
# Usage: ROMDIR=... [MAME_BIN=...] [JOBS=12] [KEEP=<dir>] [FREEZE=1] tests/audit_mizuumi_chars.sh
#   emulator tier, MAME; ~5 min at JOBS=12 (38 legs; 26_don_arcade_mash's 40,600 frames are the long pole)
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame-ref/cps2}"; export MAME_BIN
JOBS="${JOBS:-12}"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
. "$REPO/tests/lib/decrypt_cache.sh"
[ -x "$MAME_BIN" ] || { echo "SKIP: no reference MAME binary at $MAME_BIN"; exit 0; }
romchk="$(python3 "$REPO/tools/audit_roms.py" "$ROMDIR" 2>&1)" || true
echo "$romchk" | grep -q 'all match' || { echo "FAIL: ROMDIR is not the pristine reference set (tools/audit_roms.py against docs/checksums.txt):"; echo "$romchk" | tail -5; exit 1; }
romfp="$(python3 "$REPO/tools/build_fingerprint.py" "$ROMDIR" --set vsavj --sha-only 2>/dev/null)" || true
regfp="$(awk -F'\t' '$2 == "vsavj" && $1 !~ /^#/ {print $1}' "$REPO/tests/expected/registry.tsv")"
[ -n "$romfp" ] && [ "$romfp" = "$regfp" ] || { echo "FAIL: vsavj program fingerprint '$romfp' is not the registry's vsavj row '$regfp'"; exit 1; }
echo "  rom   $(echo "$romchk" | grep 'all match' | head -1); vsavj program fingerprint $romfp = registry vsavj row; zips $(python3 -c 'import hashlib,sys; print(" ".join(f"{z}.zip=" + hashlib.sha1(open(f"{sys.argv[1]}/{z}.zip","rb").read()).hexdigest() for z in ("vsavj","vsav","qsound_hle")))' "$ROMDIR")"
EXPECT="$REPO/tests/expected/mizuumi_chars.tsv"
if [ -n "${KEEP:-}" ]; then W="$KEEP"; mkdir -p "$W"; else W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM; fi
W="$(cd "$W" && pwd)"
echo "  head  $(git -C "$REPO" describe --always --dirty --abbrev=40 2>/dev/null || echo no git); tracked files modified $(git -C "$REPO" status --porcelain --untracked-files=no 2>/dev/null | wc -l | tr -d ' '); host $(hostname) $(uname -sm); MAME_BIN $MAME_BIN; JOBS $JOBS"
. "$REPO/tests/lib/mame_ident.sh"; vs_mame_ident "$MAME_BIN" || { echo "FAIL: the MAME binary is not the pinned release (above)"; exit 1; }

# ADDRESSES ARE COMPUTED from the block base, never concatenated (the 14z-189 lesson of audit_mizuumi_struct.sh)
F="ff8109:b:timer,ff8081:b:pass,ff8080:b:gclock"; RT="ff8080,2"   # the vblank counter, in both runs (KA)
for s in 1 2; do
    base=$([ "$s" = 1 ] && echo $((0xff8400)) || echo $((0xff8800)))
    for spec in 00b:b:face 010:w:x 050:w:hp 060:l:base 380:b:playing 0ac:b:pind 110:b:dfm 136:b:c136 149:b:pact 14b:b:c14b 154:b:c154 15c:w:c15c \
                192:b:cfl 19a:b:c19a 1a2:b:c1a2 1b8:w:atk 1bb:b:c1bb 372:b:dash 382:b:char 3c1:b:c3c1; do
        F="$F,$(printf '%06x' $((base + 0x${spec%%:*}))):${spec#*:}$s"
    done
    for o in 010:2 034:4 050:2 060:4 0ac:2 110:2 136:2 148:4 154:2 15c:2 192:2 19a:2 1a2:2 1ba:2 360:32 3c0:2; do   # +0x372 is inside 360:32 (an overlapping word logs each write twice)
        RT="$RT${RT:+;}$(printf '%06x' $((base + 0x${o%%:*}))),${o#*:}"
    done
done
for n in $(seq 0 31); do
    a=$((0xff9400 + n * 0x100))
    F="$F,$(printf '%06x' $a):b:alive$n,$(printf '%06x' $((a + 2))):b:type$n,$(printf '%06x' $((a + 0x30))):w:own$n"
done
RR="ff8554,2;ff8954,2;ff84ac,2;ff88ac,2"   # the read legs: both blocks' +0x154 and +0x0AC words
PK_ANAK="1100:ff8782:06;1110:ff8782:06;1118:ff8782:06;1125:ff8782:06;1300:ff8782:06;1600:ff8782:06;2000:ff8782:06"
PK_MO="1100:ff8782:05;1110:ff8782:05;1118:ff8782:05;1125:ff8782:05;1300:ff8782:05;1600:ff8782:05;2000:ff8782:05"
# tag replay frames pokes(-) — the five rig legs, then the 14z-194 pilot's 13 census replays
cat > "$W/legs.txt" <<EOF
proj 105_projectile_clash_ctl 5600 -
dash 118_dash 4200 -
mokt 118_mo_kthrow 4200 $PK_MO
anak 118_anak_taunt 4200 $PK_ANAK
rnd 118_random 4200 -
c01 01_attract_long 7200 -
c10 10_midattract_start 6000 -
c26 26_don_arcade_mash 40600 -
c07 07_mash_storm 4200 -
c08 08_challenger_join 6800 -
c29 29_felicia_walljump 4200 -
c128 128_shadow_vs_legacy_vsavj 21000 -
c19 19_don_dp_spam 5810 -
c21 21_don_mash 14000 -
c22 22_don_dualmash 13800 -
c24 24_don_winmash 18400 -
c30 30_demitri_throw 4600 -
c50 50_don_column_ko 3400 -
EOF
one() {  # one <kind f|t|r> <tag> <replay> <frames> <pokes|->
    d="$W/$1$2"; rm -rf "$d"; mkdir -p "$d"; pk=""; [ "$5" != - ] && pk="$5"
    rp="$REPO/tests/replays/$3.rpl"; case "$3" in /*) rp="$3" ;; esac   # an absolute path: a perturbed copy (KS's control)
    case "$1" in
    f) ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$rp" FIELDS="$F" POKES="$pk" \
           FIELD_OUT="$W/$2.fields" FRAMES="$4" "$REPO/tools/run_mame.sh" vsavj \
           -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) </dev/null 2>/dev/null || true ;;
    t) ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$rp" RTAP="$RT" WINDOW="0,0" POKES="$pk" \
           TRACE_OUT="$W/$2.tap" FRAMES="$4" "$REPO/tools/run_mame.sh" vsavj \
           -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) </dev/null 2>/dev/null || true ;;
    r) ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$rp" RTAP="$RR" WINDOW="0,999999" \
           TRACE_OUT="$W/read_$2.tap" FRAMES="$4" "$REPO/tools/run_mame.sh" vsavj \
           -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$d/mame.log" 2>&1; rm -rf "$d/sb" ) </dev/null 2>/dev/null || true ;;
    esac
}
# the vsavj DATA view: the +0x60 character-data base table PRG:0x0BD97A the analysis reads every block's character from
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin"
echo "== 1. the legs (pristine vsavj, MAME)"
: > "$W/jobs.txt"
while read -r tag r fr pk; do
    echo "f $tag $r $fr $pk" >> "$W/jobs.txt"; echo "t $tag $r $fr $pk" >> "$W/jobs.txt"
done < "$W/legs.txt"
echo "r proj 105_projectile_clash_ctl 5600 -" >> "$W/jobs.txt"; echo "r c128 128_shadow_vs_legacy_vsavj 21000 -" >> "$W/jobs.txt"
# KS's control leg: a TAP run of the flare replay with P1's inputs from f3000 two frames later — a different game
python3 - "$REPO/tests/replays/105_projectile_clash_ctl.rpl" "$W/projshift.rpl" <<'PY'
import re, sys
out = []
for line in open(sys.argv[1]):
    body = line.split("#")[0].strip()
    m = re.match(r"^(\d+)(?:-(\d+))?\s+(.*)$", body)
    if m and int(m.group(1)) >= 3000 and re.search(r"\bp1=", m.group(3)):
        a = int(m.group(1)) + 2; b = (int(m.group(2)) + 2) if m.group(2) else None
        line = f"{a}-{b} {m.group(3)}\n" if b is not None else f"{a} {m.group(3)}\n"
    out.append(line)
open(sys.argv[2], "w").write("".join(out))
PY
echo "t projshift $W/projshift.rpl 5600 -" >> "$W/jobs.txt"
pool=0
while read -r k tag r fr pk; do
    one "$k" "$tag" "$r" "$fr" "$pk" &
    pool=$((pool + 1)); if [ "$pool" -ge "$JOBS" ]; then wait; pool=0; fi
done < "$W/jobs.txt"
wait
fail=0; nl=0
while read -r k tag r fr pk; do
    nl=$((nl + 1))
    case "$k" in
    f) grep -q '^FIELDSUMMARY' "$W/$tag.fields" 2>/dev/null || { echo "  FAIL  $tag: no FIELDSUMMARY (see $W/f$tag/mame.log) — VOID"; fail=1; } ;;
    t) grep -q '^END ' "$W/$tag.tap" 2>/dev/null || { echo "  FAIL  tap $tag: no END line (see $W/t$tag/mame.log) — VOID"; fail=1; } ;;
    r) grep -q '^END ' "$W/read_$tag.tap" 2>/dev/null || { echo "  FAIL  read $tag: no END line (see $W/r$tag/mame.log) — VOID"; fail=1; } ;;
    esac
done < "$W/jobs.txt"
[ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_chars (a leg did not complete)"; exit 1; }
echo "  ok    $nl legs complete"

an() {  # an <pert> <out.tsv> — the analysis; prints [K] ok/FAIL lines, writes the counts, exits 1 on any FAIL
    python3 "$REPO/tools/mizuumi_chars.py" --work "$W" --replays "$REPO/tests/replays" --legs "$W/legs.txt" --data "$W/vj_data.bin" --pert "$1" --out "$2"
}
echo "== 2. the checks"
if [ -n "${VS_CTL:-}" ]; then
    an "$VS_CTL" "$W/mode.tsv" > "$W/mode.log" 2>&1 && rc=0 || rc=1
    cat "$W/mode.log"
    case "$VS_CTL" in absent-move) want='K1 K3 K4 K7 K10 K11' ;; wrong-owner) want='K12' ;; pool-miscount) want='K2' ;;
        passes-inflated) want='K6' ;; fall-shifted) want='K9' ;; taps-as-dashes) want='K5' ;; other-side-credit) want='K8' ;; wrong-base) want='K0' ;; prewrite-human) want='K0b' ;; tap-misaligned) want='KA' ;;
        tap-other-game) want='KS' ;; next-load-wrong) want='K0b' ;; esac
    ok=1; for k in $want; do grep -q "FAIL  \[$k\]" "$W/mode.log" || ok=0; done
    if [ "$rc" = 1 ] && [ "$ok" = 1 ]; then vs_ctl_fired "$VS_CTL" "the perturbed checks failed $want (mode)"
    else echo "REFUSED: CONTROL=$VS_CTL — the perturbation did not make every check it targets fail (rc $rc; wanted $want): a dead mode, not a verdict"; exit 3; fi
    echo "FAIL: audit_mizuumi_chars (control mode)"; exit 1
fi
an none "$W/got.tsv" > "$W/checks.log" 2>&1 || fail=1
cat "$W/checks.log"
grep -q '\[K12\]' "$W/checks.log" || { echo "  FAIL  the checks did not reach K12 (a crash is not a verdict): $(tail -1 "$W/checks.log")"; exit 1; }

echo "== 3. the must-fire controls (in-gate)"
for c in "absent-move:K1 K3 K4 K7 K10 K11" "wrong-owner:K12" "pool-miscount:K2" "passes-inflated:K6" "fall-shifted:K9" \
         "taps-as-dashes:K5" "other-side-credit:K8" "wrong-base:K0" "prewrite-human:K0b" "tap-misaligned:KA" \
         "tap-other-game:KS" "next-load-wrong:K0b"; do
    name="${c%%:*}"; want="${c#*:}"
    an "$name" "$W/ctl_$name.tsv" > "$W/ctl_$name.log" 2>&1 && rc=0 || rc=1
    miss=""; for k in $want; do grep -q "FAIL  \[$k\]" "$W/ctl_$name.log" || miss="$miss $k"; done
    if [ "$rc" = 1 ] && [ -z "$miss" ]; then
        vs_ctl_fired "$name" "$want failed: $(grep -c '  FAIL' "$W/ctl_$name.log") row(s), e.g. $(grep "FAIL  \[${want%% *}\]" "$W/ctl_$name.log" | head -1 | sed 's/^ *//' | cut -c1-140)"
    else
        vs_ctl_dead "$name" "the perturbed run did not fail$miss (rc $rc): $(tail -1 "$W/ctl_$name.log" | cut -c1-120)" || fail=1
    fi
done

echo "== 4. the frozen counts"
if [ "${FREEZE:-0}" = 1 ]; then
    [ "$fail" = 0 ] || { echo "FAIL: audit_mizuumi_chars (not frozen: fix the red first)"; exit 1; }
    { echo "# tests/expected/mizuumi_chars.tsv — the counts tests/audit_mizuumi_chars.sh measured on pristine vsavj (GitHub #118, HOMING item 5)."
      echo "# Evidence class: in-emulator. Frozen 14z-196 with FREEZE=1; counts, spans, value sets, writer and reader PCs only, no ROM bytes."
      cat "$W/got.tsv"; } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1)"; exit 1; }
if grep -v '^#' "$EXPECT" | diff - "$W/got.tsv" > "$W/diff.txt"; then echo "  ok    every count as frozen"
else echo "  FAIL  the counts moved:"; sed 's/^/        /' "$W/diff.txt" | head -40; fail=1; fi
if [ "$fail" = 0 ]; then echo "PASS: audit_mizuumi_chars"; else echo "FAIL: audit_mizuumi_chars"; exit 1; fi
