#!/bin/sh
# audit_palette_seq_ids.sh — which palette-seq ids does LEGACY ever request?
#
# *** THIS AUDIT RETURNED A FALSE PASS FOR TEN SESSIONS (retracted 14z-79). ***
# It guarded the 14z-69p DF-palette rewrite of rows 0x1E-0x21, and reported
# "legacy never requests these ids". Legacy requests them constantly — they
# are BULLETA'S DARK FORCE BLOCK (236 calls in one DF, measured on vanilla).
# The rewrite was WITHDRAWN in 14z-79 after a maintainer playtest saw her DF
# rendered wrong.
#
# WHY IT PASSED: every replay in its set is ordinary play, and DARK FORCE
# COSTS A BANKED STOCK. None of them could activate DF, so the census could
# only ever see non-DF ids — and the set is Demitri-heavy, so it saw
# {0x26,0x27}, which is Demitri's own block, and generalised. An audit whose
# replays cannot produce the mode it is guarding cannot report on that mode.
# That is the same provenance failure as the Plasma Trap "0 hits" claim.
#
# WHAT IT DOES NOW. It is an INVENTORY, not a proof of a specific row: it
# reports every palette-seq id legacy requests, in ordinary play AND with
# Dark Force forced on across a character-varied set. Phase B is what makes
# it able to fail. The inventory is the input to the deferred proper fix —
# giving Phobos his OWN palette-seq block requires knowing which ids are
# free, and only a census that includes DF can tell you that.
#
# Method: an UNCAPPED logging breakpoint on the resolver
#   0x02AD82:  a0 = 0x39A900 + (d0 & 0xFFF) * 0x20
# over a character-varied set of vanilla replays, collecting every d0.
# GUARD_PROBE_MAX is essential: the default 400-hit cap silently
# truncated the first run of this audit and hid id 0x27 entirely, which
# would have made the inventory look smaller than it is.
#
# RETRACTED (was: "the ONLY ids legacy ever requests are 0x26 and 0x27",
# measured 14z-69p). That was phase A alone, which cannot enter Dark
# Force; 0x26 is Demitri's block and the set was Demitri-heavy. With
# phase B the inventory includes Bulleta's 0x1E-0x21 and char 0x04's
# 0x44-0x47. Growth is still the signal — re-derive before trusting any
# claim that a palette-seq row is free.
#
# On-demand (not in the battery): ~10 MAME runs, several minutes.
# Usage: ROMDIR=... tests/audit_palette_seq_ids.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-69p: which palette-seq ids does LEGACY ever (14z-118: DFRPL= picks the
#   DF rig — replay 85 never activates Anakaris, df/97 does; a DF-on char with
#   0 calls is reported as NO PALETTE-SEQ PATH; the full-roster result is
#   frozen in tests/expected/df_palette_seq_census.txt) request? (uncapped
#   probe on 0x2AD82, 8 replays). The DF-palette data row is legacy-inert ONLY
#   because the answer is {0x26, 0x27} — and the palette path never transits
#   work RAM, so this audit is its ONLY guard. Use GUARD_PROBE_MAX: the
#   default 400-hit cap truncated it once and hid id 0x27
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
export MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"

# REPLAYS: the phase-A set. Default = the cheap eight. `REPLAYS=all` sweeps
# EVERY vsavj-targeted replay in tests/replays/*.rpl (14z-118: 73 legs, ~30
# min, 4 in parallel) and then requires the union to EQUAL the frozen
# whole-corpus inventory in tests/expected/palette_seq_ids_corpus.txt — the
# census that decides whether a palette-seq block is FREE of any non-DF
# requester (the 0xAA question, engine_internals "THE DARK FORCE
# PALETTE-SEQUENCE BLOCKS"). Growth or shrinkage of that union fails.
REPLAYS="${REPLAYS:-02_demitri_vs_cpu 03_two_player_vs 05_timeout_idle 07_mash_storm
         08_challenger_join 09_mirror_pick 30_demitri_throw 20_don_round2}"
CORPUS=0
if [ "$REPLAYS" = "all" ]; then
    CORPUS=1
    REPLAYS="$(ls tests/replays/*.rpl | grep -v '_vsav2\.rpl$' | sed 's|tests/replays/||;s|\.rpl$||' | tr '\n' ' ')"
fi
FORBIDDEN="1e 1f 20 21"

: > "$W/ids.txt"
total=0
_i=0
for r in $REPLAYS; do
    [ -f "tests/replays/$r.rpl" ] || continue
    d="$W/$r"; mkdir -p "$d"
    ( cd "$d" && GUARD_PROBE=2ad82 GUARD_PROBE_MAX=400000 \
      "$REPO/tools/run_replay_guarded.sh" vsavj "$REPO/tests/replays/$r.rpl" \
      "$d/g.log" "$d/box" > "$d/out" 2>&1 ) &
    _i=$((_i + 1)); [ $((_i % 4)) = 0 ] && wait
done
wait
for r in $REPLAYS; do
    [ -f "tests/replays/$r.rpl" ] || continue
    d="$W/$r"
    n=$(grep -c '^PROBE' "$d/g.log" 2>/dev/null || true)
    [ -n "$n" ] || n=0
    ids=$(grep '^PROBE' "$d/g.log" 2>/dev/null \
          | sed -n 's/.*D0=00000*\([0-9a-f]*\).*/\1/p' | sort -u)
    echo "$ids" >> "$W/ids.txt"
    printf "  %-22s %6s calls   ids: %s\n" "$r" "$n" "$(echo $ids)"
    total=$((total + n))
    if grep -q '^PROBE-CAP' "$d/g.log" 2>/dev/null; then
        echo "FAIL: $r hit the probe cap — the census is truncated"; exit 1
    fi
done

if [ "$CORPUS" = 1 ]; then
    UNION_A=$(sort -u "$W/ids.txt" | grep -v '^$' | tr '\n' ' ' | sed 's/ $//')
    WANT_A=$(grep -v '^#' tests/expected/palette_seq_ids_corpus.txt | tr -s ' \n' ' ' | sed 's/^ //;s/ $//')
    echo
    echo "  whole-corpus (phase A) union: $UNION_A"
    if [ "$UNION_A" != "$WANT_A" ]; then
        echo "FAIL: the whole-corpus non-DF inventory MOVED — frozen: $WANT_A"
        echo "      A new requester is a finding (a block thought free is not);"
        echo "      a lost one means a replay or the probe changed. Root-cause, then re-freeze."
        exit 1
    fi
    echo "  ok: whole-corpus non-DF inventory matches tests/expected/palette_seq_ids_corpus.txt"
fi

# ── PHASE B: the same census WITH DARK FORCE FORCED ON ──────────────────
# The half phase A structurally cannot reach. Replay 85 drives a DF
# activation; $FF8509 banks the stocks so the P+K pair is not downgraded,
# and $FF8782 forces the character. EVERY RUN IS CONTROLLED: $FF802E must
# read 1, or the run is reported as NOT-DF and the audit fails rather than
# quietly contributing a non-DF sample (that is exactly how phase A lied).
# DFRPL: the DF-driving rig. 14z-118 MEASURED that replay 85's activation
# timing does NOT land for every character (Anakaris 0x06: $FF802E stayed 0
# for 7,000 frames on 85; on `df/97_df_mech.rpl` — audit_df_framework's rig —
# it read 1 at frames 3400-3600). A char reported NOT IN DARK FORCE on one rig
# is re-run on the other before it counts as unaccounted for. Full-roster
# census (14z-118, rig 97): see the header of tests/expected/df_palette_seq_census.txt.
DFRPL="${DFRPL:-tests/replays/hui/85_hui_df_vs2.rpl}"
NODF=""
echo
echo "  -- phase B: Dark Force forced (the half phase A cannot reach) --"
# CHARS overrides the sweep set. The default four are the cheap regression
# set (Bulleta 0x00 owns 0x1E-0x21, Demitri 0x01 owns 0x26, Victor 0x03 has no
# DF palette path at all, char 0x04 owns 0x44-0x47). Pass the full roster when
# you need the FREE-BLOCK census — e.g. before giving a tenant his own block:
#   CHARS="00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f" tests/audit_palette_seq_ids.sh
for ch in ${CHARS:-00 01 03 04}; do
    [ -f "$DFRPL" ] || break
    d="$W/df$ch"; mkdir -p "$d"
    PKD="1400:ff8782:$ch;1450:ff8782:$ch;1500:ff8782:$ch;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
    ( cd "$d" && POKES="$PKD" GUARD_PROBE=2ad82 GUARD_PROBE_MAX=200000 \
      DUMPS="3300:ff8020-ff805f;3400:ff8020-ff805f;3500:ff8020-ff805f" \
      "$REPO/tools/run_replay_guarded.sh" vsavj "$REPO/$DFRPL" \
      "$d/g.log" "$d/box" > "$d/out" 2>&1 ) || true
    # SAMPLE SEVERAL FRAMES, accept DF at ANY of them. The first version
    # sampled f3300 only and reported "never in Dark Force" for a run that
    # entered it between f3300 and f3400 — the control was wrong, not the
    # rig, and a one-frame sample of a MODE is a coin toss on its onset.
    dfon=$(python3 -c "
best=0
for f in (3300,3400,3500):
    try:
        v=open('$d/dump_%d_ff8020.bin'%f,'rb').read()[0x0e]
    except Exception:
        v=0
    best=max(best,v)
print(best)")
    n=$(grep -c '^PROBE' "$d/g.log" 2>/dev/null || true); [ -n "$n" ] || n=0
    ids=$(grep '^PROBE' "$d/g.log" 2>/dev/null \
          | sed -n 's/.*D0=00000*\([0-9a-f]*\).*/\1/p' | sort -u)
    if [ "$dfon" != "1" ]; then
        # Report and CONTINUE, but remember it: a char that never entered DF
        # contributes nothing and must not be silently counted as "clean".
        # (0x0B is not a character — it is Shadow/Marionette machinery — so a
        # full-roster census is expected to have at least one of these.)
        printf "  char 0x%-4s NOT IN DARK FORCE (\$FF802E=%s) — CONTRIBUTES NOTHING\n" "$ch" "$dfon"
        NODF="$NODF $ch"
        continue
    fi
    echo "$ids" >> "$W/ids.txt"
    if [ "$n" = 0 ]; then
        # DF entered, resolver never called: this character's Dark Force has NO
        # palette-seq path (Victor 0x03; Anakaris 0x06 measured 14z-118). It
        # owns no block — a real, positive finding, not a missing sample.
        printf "  char 0x%-4s      0 calls   DF=on   NO PALETTE-SEQ PATH (owns no block)\n" "$ch"
    else
        printf "  char 0x%-4s %6s calls   DF=on   ids: %s\n" "$ch" "$n" "$(echo $ids)"
    fi
    total=$((total + n))
done

UNION=$(sort -u "$W/ids.txt" | grep -v '^$' | tr '\n' ' ')
echo
echo "  union of ids legacy requests: $UNION"
echo "  total calls sampled: $total"
[ "$total" -gt 0 ] || { echo "FAIL: no calls seen at all — instrument broken"; exit 1; }

# The verdict is now about the INVENTORY, not about one withdrawn row: any
# id legacy requests is a row no tenant may overwrite. FORBIDDEN keeps
# 0x1E-0x21 named explicitly, because that is the one we got wrong, and a
# hit there must read as "Bulleta's block — do not touch" and not as noise.
bad=""
for f in $FORBIDDEN; do
    case " $UNION " in *" $f "*) bad="$bad $f" ;; esac
done
if [ -n "$bad" ]; then
    echo
    echo "  NOTE: legacy requests$bad — Bulleta's Dark Force block."
    echo "  That is EXPECTED since 14z-79 and is exactly why the 14z-69p"
    echo "  df_palette_seq_rows row was withdrawn. It is a failure only if a"
    echo "  build writes those rows; the manifest must not carry that row."
    if grep -qE '^[^#]*dst = 0x39ACC0' "$REPO/build/manifest/huitzil.toml"; then
        echo "FAIL: huitzil.toml still writes 0x39ACC0 — it overwrites ids$bad"
        exit 1
    fi
    echo "  ok: no manifest writes those rows"
fi
echo
if [ -n "$NODF" ]; then
    echo
    echo "  INCOMPLETE: these chars never entered Dark Force:$NODF"
    echo "  Their ids are NOT in the union below. A block that looks free may"
    echo "  simply belong to one of them — do NOT treat this census as a"
    echo "  free-block proof until every character is accounted for."
    exit 1
fi
echo "PASS: palette-seq id inventory taken WITH Dark Force (phase B controlled"
echo "      on \$FF802E). Union: $UNION"
echo "      Any tenant palette-seq block must avoid every id listed above."
