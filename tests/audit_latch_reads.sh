#!/bin/sh
# audit_latch_reads.sh — WHO READS THE SELECT-CONFIRM LATCH IN PLAY, per leg shape, with the VALUE each reader saw: the measured half of the #151 step-3 sweep, frozen (14z-161).
#
# WHAT: who reads the select-confirm latch (+0x3BD/+0x3E0 id copies, +0x3C2 flavour) IN
#   PLAY, per forced-pick leg shape, with the value each reader saw — the dynamic half of
#   the #151 sweep that makes the static reader census's classes evidence (Phobos's flavour
#   readers see 01, Donovan's VH2 flavour, on the #147 shape).
# HOW: seven leg shapes on MAME (Phobos real, Phobos over Donovan, Phobos over Demitri,
#   Donovan over Demitri, the Donovan victim rig, Pyron over Demitri, our WIDE build's
#   Phobos) each under the non-debug PC-attributed read tap over both blocks' latch windows,
#   the in-play readers frozen per leg with the byte seen; controls swap the poked leg for
#   the real path and move the tap windows off the bytes.
# EXPECTS: the frozen per-leg inventories (Phobos real 00, over Donovan 01, no reader for
#   Donovan or Pyron in these rigs, ours only the float fork seeing the shim's 00); the
#   real-path swap reads 00 where the row says 01 and fails, the moved windows read VOID.
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/expected/latch_reads.tsv
#   tests/lua/read_tap.lua tests/replays/ tests/test_latch_readers.sh tools/run_mame.sh
#   tools/setup_mame.sh tools/tap_latch_reads.sh
#
# MUST-FIRE: perturbed-copy: real-instead-of-poked — the phobos-over-donovan leg run with Phobos's REAL cursor path instead of the poke reads flavor 00 where the frozen row says 01, and the comparison must FAIL (in-gate: that leg's values are asserted to differ from the phobos-real leg's; mode: the poked leg is replaced by the real path and the gate FAILs)
# MUST-FIRE: perturbed-copy: tap-window-moved — the tap windows shifted past the latch bytes capture nothing, and a frozen non-empty leg must FAIL (in-gate: the reducer is fed an empty tap and must report VOID rather than an empty inventory; mode: every leg's window is moved and the gate FAILs)
#
# WHY. A forced pick ([VSP-123]) lands AFTER the select confirm, so a poked leg
# carries the CURSOR character's confirm-time latch: +0x3BD/+0x3E0 (id copies)
# and +0x3C2 (the VS2/VH2 flavor), tests/audit_forced_pick_fidelity.sh. That is
# only a defect for a gate whose subject READS one of them, and which code can is
# the static census tests/test_latch_readers.sh. This gate is the dynamic half:
# the same replay shapes the tree's poked legs use, played under the
# non-debug PC-attributed read tap (tools/tap_latch_reads.sh) with BOTH fighter
# blocks' latch windows watched, and the in-play readers frozen per leg with the
# byte value each one saw. The frozen inventory is what makes the census's
# classes evidence:
#   phobos-real            Phobos by his real vsav2 path (L,L,L): his flavor
#                          readers fire every match frame and see 00 — the
#                          positive control for the tap itself;
#   phobos-over-donovan    the #147 shape (R,R confirms Donovan, then the id
#                          poke): the SAME readers see 01 — Donovan's VH2
#                          flavor — the mechanism that shipped a wrong fix;
#   phobos-over-demitri    the shape every hui/ gate uses (no cursor moves, the
#                          poke over Demitri's cell): the readers see 00, the
#                          value a real pick writes — faithful for the flavor;
#   donovan-over-demitri   Donovan poked over Demitri's cell on the DF rig: his
#                          latched flavor is 00 where a real pick writes 01, and
#                          NO reader fires in the rig (his readers are action-
#                          specific: vs2 0x05A650, 0x065FE2, 0x066020);
#   donovan-victim         the naming victim rig (P2 Donovan poked over Victor's
#                          cell): no reader fires;
#   pyron-over-demitri     Pyron poked: no reader fires — Pyron's code never
#                          consults the flavor (the census has no reader of his);
#   ours-phobos            the WIDE build, Phobos poked over Bulleta's cell (R,R
#                          on our wheel): only the float fork reads, and sees the
#                          init shim's 00 — the port writes the flavor AFTER any
#                          poke, so no ours leg can carry a cell's flavor.
# In no leg is an id copy read after the match anchor; the boot RAM test
# (PRG:0x000D32/0x000D36), the select-entry clear (0x01F5C8) and P2's join copy
# (0x007254 / vsavj 0x008A86) are the pre-match readers and are excluded by the
# frame floor.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged28] [LEGS="..."] [FREEZE=1] tests/audit_latch_reads.sh
#   emulator tier, MAME; ~2 min for the seven legs (two tap runs each).
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged28}"
EXPECT="$REPO/tests/expected/latch_reads.tsv"
CONTROL="${CONTROL:-}"
LEGS="${LEGS:-phobos-real phobos-over-donovan phobos-over-demitri donovan-over-demitri donovan-victim pyron-over-demitri ours-phobos}"
FLOOR=2000      # in play: after the confirm (1300), the pokes (1500) and the load
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$REPO/$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|real-instead-of-poked|tap-window-moved) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
R="$REPO/tests/replays"
rig_pokes() { python3 -c "import json; print(';'.join(json.load(open('$1'))['pokes']))"; }
pk() { echo "1400:ff8782:$1;1450:ff8782:$1;1500:ff8782:$1;1400:ff8b82:$2;1450:ff8b82:$2;1500:ff8b82:$2"; }
# ONE function turns the real naming rig into the #147 shape ([VSP-181]: the
# control's perturbation is this function's inverse)
poked_prologue() {  # poked_prologue <real rig.rpl> <out.rpl>: replace P1's L,L,L with R,R
    awk '!/^1(100|160|220)-[0-9]+ p1=L$/ { if ($0 ~ /^1104-/) { print "1100-1102 p1=R"; print "1160-1162 p1=R" } print }' "$1" > "$2"
}

# leg <name> -> prints "<set> <replay> <pokes> <frames> [rompath]"
leg() {
    case "$1" in
        phobos-real)          echo "vsav2 $R/naming/huitzil_1.rpl $(rig_pokes "$R/naming/huitzil_1.json") 4000 -" ;;
        phobos-over-donovan)  poked_prologue "$R/naming/huitzil_1.rpl" "$W/hui1_poked.rpl"
                              if [ "$CONTROL" = real-instead-of-poked ]; then
                                  echo "vsav2 $R/naming/huitzil_1.rpl $(rig_pokes "$R/naming/huitzil_1.json") 4000 -"
                              else
                                  echo "vsav2 $W/hui1_poked.rpl $(pk 10 03);$(rig_pokes "$R/naming/huitzil_1.json") 4000 -"
                              fi ;;
        phobos-over-demitri)  echo "vsav2 $R/hui/80_hui_grab_2p.rpl $(pk 10 03) 6300 -" ;;
        donovan-over-demitri) echo "vsav2 $R/df/97_df_mech.rpl $(pk 13 03);3100:ff8509:03;3120:ff8509:03 7050 -" ;;
        donovan-victim)       echo "vsav2 $R/naming/donovan_victim_1.rpl $(rig_pokes "$R/naming/donovan_victim_1.json") 6300 -" ;;
        pyron-over-demitri)   echo "vsav2 $R/pyron/76_pyron_blink_vs2.rpl $(pk 11 03) 6300 -" ;;
        ours-phobos)          echo "vsavjw $R/hui/90_hui_oracle.rpl $(pk 10 03);2360:ff80d4:42;2360:ff80d5:42;2500:ff8509:09 5000 $REPO/$BUILD/rompath" ;;
        *) echo "FAIL: unknown leg $1" >&2; exit 1 ;;
    esac
}

echo "== 1. the legs under the read tap (both blocks' latch windows)"
: > "$W/got.tsv"
for name in $LEGS; do
    set -- $(leg "$name")
    rp="$5"; [ "$rp" = "-" ] && rp=""
    if [ "$CONTROL" = tap-window-moved ]; then
        # the perturbation: watch +0x3E4.. instead of +0x3BC.. — nothing latched is inside
        sed -e 's/RTAP="\$blk,40"/RTAP="$(printf %x $((0x$blk + 40))),40"/' -e "s|^REPO=.*|REPO=\"$REPO\"|" \
            "$REPO/tools/tap_latch_reads.sh" > "$W/tap_moved.sh"; chmod +x "$W/tap_moved.sh"
        grep -q 'printf %x' "$W/tap_moved.sh" || { echo "FAIL: the tap-window-moved perturbation did not apply"; exit 1; }
        "$W/tap_moved.sh" "$1" "$2" "$3" "$4" "$W/$name.tsv" $rp > "$W/$name.log" 2>&1 || { bad "$name: $(tail -1 "$W/$name.log")"; continue; }
    else
        "$REPO/tools/tap_latch_reads.sh" "$1" "$2" "$3" "$4" "$W/$name.tsv" $rp > "$W/$name.log" 2>&1 || { bad "$name: $(tail -1 "$W/$name.log")"; continue; }
    fi
    # in-play rows only: side, offset, pc, values (reads and frames are reported, not frozen)
    awk -F'\t' -v n="$name" -v fl="$FLOOR" 'NR>1 && $9+0 >= fl {print n"\t"$2"\t"$4"\t"$6"\t"$10}' "$W/$name.tsv" | sort > "$W/$name.rows"
    [ -s "$W/$name.rows" ] || printf '%s\t-\t-\t-\t-\n' "$name" > "$W/$name.rows"
    cat "$W/$name.rows" >> "$W/got.tsv"
    ok "$name: $(awk -F'\t' 'NR>1 && $9+0 >= 2000' "$W/$name.tsv" | wc -l | tr -d ' ') in-play (PC, latched byte) rows — $(awk -F'\t' '{printf "%s:%s=%s ", $3, $4, $5}' "$W/$name.rows")"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_latch_reads (a leg did not run)"; exit 1; }

echo "== 2. the frozen per-leg inventory"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/latch_reads.tsv — the in-play readers of the select-confirm latch bytes per leg shape,"
        echo "# with the byte value each reader saw (tests/audit_latch_reads.sh; tools/tap_latch_reads.sh)."
        echo "# Evidence class: in-emulator (MAME, native vsav2 and the WIDE build; frames >= 2000)."
        echo "# Frozen 14z-161 with FREEZE=1. A new reader row is a finding (read tests/test_latch_readers.sh's census first);"
        echo "# a changed VALUE on phobos-over-donovan means the confirm's flavor table moved — re-derive it before re-freezing."
        echo "# Columns: leg, side, offset, pc, values ('-' = no in-play read of any latched byte)"
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
for name in $LEGS; do
    awk -F'\t' -v n="$name" '!/^#/ && $1==n' "$EXPECT" | sort > "$W/$name.want"
    if diff "$W/$name.want" "$W/$name.rows" > "$W/$name.diff"; then ok "$name: as frozen"
    else bad "$name: differs from the frozen rows"; sed 's/^/        /' "$W/$name.diff"; fi
done

echo "== 3. must-fire controls (in-gate)"
# real-instead-of-poked: the two Phobos-P1 legs must disagree on the value the same reader saw
case "$LEGS" in *phobos-real*phobos-over-donovan*|*phobos-over-donovan*phobos-real*)
    v_real="$(awk -F'\t' '$3=="+0x3C2" && $4=="026322" {print $5}' "$W/phobos-real.rows")"
    v_poke="$(awk -F'\t' '$3=="+0x3C2" && $4=="026322" {print $5}' "$W/phobos-over-donovan.rows")"
    if [ "$CONTROL" = real-instead-of-poked ]; then
        if [ "$fail" = 1 ]; then echo "CONTROL FIRED: real-instead-of-poked — the real path reads $v_poke against the frozen 01"; echo "FAIL: audit_latch_reads (control mode)"; exit 1
        else echo "CONTROL DEAD: real-instead-of-poked — the real path still matched the poked leg's frozen value"; echo "FAIL: audit_latch_reads"; exit 1; fi
    fi
    if [ -n "$v_real" ] && [ -n "$v_poke" ] && [ "$v_real" != "$v_poke" ]; then
        echo "CONTROL FIRED: real-instead-of-poked — PRG:0x026322 reads $v_real on the real pick and $v_poke on the poked one"
    else
        echo "CONTROL DEAD: real-instead-of-poked — real '$v_real' vs poked '$v_poke'"; fail=1
    fi ;;
esac
# tap-window-moved: an EMPTY tap log must be refused by the reducer, never read as 'no reads'
if [ "$CONTROL" = tap-window-moved ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: tap-window-moved — the moved windows lose the frozen rows"; echo "FAIL: audit_latch_reads (control mode)"; exit 1
    else echo "CONTROL DEAD: tap-window-moved — the moved windows still matched"; echo "FAIL: audit_latch_reads"; exit 1; fi
fi
mkdir -p "$W/empty"; : > "$W/empty/tap_ff87bc.txt"; : > "$W/empty/tap_ff8bbc.txt"
if "$REPO/tools/tap_latch_reads.sh" vsav2 "$R/naming/huitzil_1.rpl" - 0 "$W/empty.tsv" > "$W/empty.log" 2>&1; then
    echo "CONTROL DEAD: tap-window-moved — a zero-frame run produced a verdict instead of VOID"; fail=1
else
    grep -q '^VOID' "$W/empty.log" && echo "CONTROL FIRED: tap-window-moved — a tap with no W/END lines is refused as VOID" \
        || { echo "CONTROL DEAD: tap-window-moved — the zero-frame run failed without saying VOID: $(tail -1 "$W/empty.log")"; fail=1; }
fi

if [ "$fail" = 0 ]; then echo "PASS: audit_latch_reads"; else echo "FAIL: audit_latch_reads"; exit 1; fi
