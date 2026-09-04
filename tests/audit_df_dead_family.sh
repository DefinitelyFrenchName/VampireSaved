#!/bin/sh
# audit_df_dead_family.sh — THE VS-STYLE DARK FORCE FAMILY IS DEAD IN NATIVE
# vs2: its shared field-setter tail at vs2 PRG:0x02622A takes ZERO hits while
# the activation body takes exactly one (measured 14z-126).
#
# WHY. docs/game/preserved_data.md entry 1: vs2/vh2 carry the VS-style
# seq-0x16 Dark Force handlers for all 18 characters and never reach them. The
# listing showed one more member — a vsav-style field setter at vs2 0x02622A
# (`+0x111/+0x110/+0x143/+0x176`, fixed `+0x189` = 5 / `+0x188` = 0x23),
# reached only by `jmp $2622a.l` from ten per-character sites inside the
# handler ranges. "Never reached" is a claim measured by ABSENCE ([VSP-22]),
# so it carries a positive control on the same instrument, leg and frame: the
# vs2 activation body 0x02619E, which MUST fire once at the activation press.
#
# WHAT IT ASSERTS (native vsav2 from $ROMDIR, replay df/97 — activation HP+HK
# at f3260 with poked stocks —, `GUARD_PROBE` logging breakpoints, two
# characters: a newcomer (Donovan 0x13) and a vanilla one (Demitri 0x01)):
#   candidate 0x02622A: 0 PROBE lines on both legs;
#   control   0x02619E: exactly 1 PROBE line on both legs, at frame 3260.
# Four -debug runs of ~7,000 frames; ~3 min in parallel.
#
# Usage: ROMDIR=... tests/audit_df_dead_family.sh
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
RPL="$REPO/tests/replays/df/97_df_mech.rpl"
for leg in don:13 dem:01; do n="${leg%%:*}"; id="${leg#*:}"
    PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
    for pr in 2622a 2619e; do
        ( POKES="$PK" GUARD_PROBE=$pr TAIL_FRAMES=10 tools/run_replay_guarded.sh vsav2 "$RPL" "$W/${n}_$pr.log" "$W/sb_${n}_$pr" > "$W/${n}_$pr.out" 2>&1 ) &
    done
done
wait
bad=0
for n in don dem; do
    for pr in 2622a 2619e; do
        f="$W/${n}_$pr.log"
        grep -q '^END ' "$f" || { echo "  FAIL: $n/$pr: no END line — dead leg"; bad=1; continue; }
        hits="$(grep -c '^PROBE' "$f" || true)"
        if [ "$pr" = 2622a ]; then
            [ "$hits" = 0 ] && echo "  ok    $n: candidate 0x2622A never reached (0 hits)" || { echo "  FAIL: $n: candidate 0x2622A reached $hits times"; bad=1; }
        else
            fr="$(grep -m1 '^PROBE' "$f" | awk '{print $2}')"
            [ "$hits" = 1 ] && [ "$fr" = 3260 ] && echo "  ok    $n: control 0x2619E fired once, at f3260" || { echo "  FAIL: $n: control 0x2619E fired $hits times (first at ${fr:-never})"; bad=1; }
        fi
    done
done
[ "$bad" = 0 ] && echo "PASS audit_df_dead_family" || { echo "FAIL audit_df_dead_family"; exit 1; }
