#!/bin/sh
# audit_id_writers.sh — which character ids does VANILLA ever assign?
#
# WHAT: no legacy gameplay path in the replay corpus ever writes a character id in the
#   variant half 0x10-0x1F into either player struct — the invariant that makes a tenant on
#   a variant id superset-safe by construction.
# HOW: write taps on both id fields ($FF8782 P1, $FF8B82 P2) over 11 legacy replays on MAME
#   (22 runs), collecting every (writer PC, value) pair; boot RAM-clear PCs excluded.
# MUST-FIRE: known-bad: word-write-variant — two planted tap logs, each on its own copy of the real logs: (a) a WORD write of 0x1300 to the id field (id 0x13 in the high byte, the field's byte on the 68000's big-endian bus) must FAIL naming id 13, and (b) a byte write of 0x13 to +0x383 alone must leave the verdict PASS — a decoder reading the wrong lane misses (a) and fails (b), so the pair separates the lanes (14z-192, rule-checker runs 2026-10-05-675 and -678) (in-gate; as a mode plant (a) joins the real logs and the gate FAILs)
# EXPECTS: every written value is a base id 0x00-0x0F from the known writer sites (attract,
#   init, CPU opponent, challenger, select). Known gap stated in the header: Oboro's 0x18 IS
#   a vanilla variant id no replay here reaches, so the proof is about THIS corpus.
# FOLLOWS: build/manifest/ docs/game/atlas/id_space.md emu/mame-patches/ tests/lib/controls.sh tests/lua/tap_writes.lua
#   tests/expected/registry.tsv tests/replays/ tools/audit_roms.py tools/build_fingerprint.py tools/run_mame.sh
#   tools/setup_mame.sh
#
# ON-DEMAND (22 MAME runs, ~10 min). Not in the battery; run it when the
# claim below is load-bearing for a decision, and after any change that
# could add a writer of the character-id field.
#
# WHY IT MATTERS. The roster plan puts newcomers on ids in the variant half
# (Huitzil 0x10, Pyron 0x11, Donovan 0x13 — docs/game/atlas/id_space.md). If no
# legacy gameplay path can ever PRODUCE such an id, then those rows are
# unreachable by legacy content and the superset invariant holds by
# construction — a much stronger position than the current slot-0x0F port,
# which needs in-place record surgery precisely because legacy cursors
# visit Jedah's cell.
#
# METHOD. Tap the character-id field of BOTH player structs
# (P1 RAM:$FF8782, P2 RAM:$FF8B82 — a6+0x382) across the legacy corpus and
# collect every (writing PC, value) pair. The P2 field is not optional: the
# CPU-opponent picker, the attract assignment and the challenger path write
# only there, and a P1-only tap misses all three.
#
# Measured 14z-60 (vanilla vsavj), 11 replays x 2 fields:
#   005BF4 -> 02 0F   attract, P1          009008 -> 01   P1 init
#   005BFA -> 00 03   attract, P2          00AEF6 -> 0A 0C 0E  CPU opponent
#   008A86 -> 05      challenger join      020A80 -> 00 01 03 05 06 08  select
#   (plus boot RAM-clear at 000D34/000D3A/000DD8/016E4C/016E4E)
#
# KNOWN GAP, deliberately not papered over: 0x18 (Oboro Bishamon) IS a
# variant id vanilla uses — four sites compare against it (PRG:0x018F9A,
# 0x026FBE, 0x0293A8, 0x043000) — and no replay in this corpus reaches it.
# So this audit proves "no legacy replay HERE writes the variant half", not
# "vanilla cannot". A tenant must still avoid 0x18.
#
# Usage: ROMDIR=... [BUILD=build/<merged dir>] tests/audit_id_writers.sh [outdir]
#   BUILD (14z-192): run the same legacy replays on OUR build (set vsavjw from BUILD/rompath)
#   instead of pristine vsavj — the "on our builds" half of #223's ruling.
#
# THE BYTE LANE (14z-192, rule-checker run 2026-10-05-675): the tap covers the WORD at the
# even field address, and the id is that word's HIGH byte (big-endian). Until 14z-192 the
# decoder took the LOW byte whenever the low lane was written, so a word write to +0x382
# would have reported +0x383's value and a byte write to +0x383 alone would have been read
# as an id. Now: the high byte when the high lane is written, otherwise not an id write.
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   on-demand (22 MAME runs): every character-id VALUE vanilla ever assigns,
#   both player structs. Fails if any legacy gameplay path writes an id in
#   0x10-0x1F — the invariant that would make a tenant on a variant id
#   superset-safe by construction
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
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN   # the pinned WIDE build: BUILD= boots vsavjw (14z-192, test_mame_bin_pinned)
cd "$REPO"
OUT="${1:-$(mktemp -d)}"   # GitHub #68: not a predictable default
mkdir -p "$OUT"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
SET=vsavj; RP="$ROMDIR"
if [ -n "${BUILD:-}" ]; then
    [ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: BUILD=$BUILD has no rompath/vsavjw.zip"; exit 1; }
    BUILD="$(cd "$BUILD" && pwd)"; SET=vsavjw; RP="$BUILD/rompath;$ROMDIR"
    # WHICH BUILD RAN (14z-192, rule-checker run 2026-10-05-677, [VSP-108]): print the registry row
    # the opened romset resolves to, its full fingerprint and the zip's sha1 — an image the
    # registry does not know cannot be called "our build", and stops the gate.
    REGNAME="$(python3 tools/build_fingerprint.py --set vsavjw --registry tests/expected/registry.tsv "$RP" 2>/dev/null | tail -1)"
    FULLFP="$(python3 tools/build_fingerprint.py --set vsavjw --sha-only "$RP" 2>/dev/null | tail -1)"
    ZSHA="$(python3 -c "import hashlib,sys;print(hashlib.sha1(open(sys.argv[1],'rb').read()).hexdigest())" "$BUILD/rompath/vsavjw.zip")"
    echo "build: registry row '${REGNAME:-?}', program fingerprint ${FULLFP:-?}, vsavjw.zip sha1 $ZSHA"
    # build_fingerprint.py prints the registry NAME for a registered image and the bare hex otherwise
    if [ -z "$REGNAME" ] || printf '%s' "$REGNAME" | grep -Eq '^[0-9a-f]{40}$'; then
        echo "FAIL: BUILD=$BUILD resolves to no registry row — not a registered build"; exit 1
    fi
fi
echo "set $SET (rompath $RP)"

REPLAYS="01_attract_long 02_demitri_vs_cpu 03_two_player_vs 04_select_fuzz
         05_timeout_idle 06_test_mode 07_mash_storm 08_challenger_join
         09_mirror_pick 10_midattract_start 16_xemu_2p"

python3 tools/audit_roms.py "$ROMDIR" >/dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

for r in $REPLAYS; do
    for who in p1:ff8782 p2:ff8b82; do
        tag=${who%%:*}; addr=${who##*:}
        # NOTE: the exit code is deliberately ignored. MAME can segfault in
        # TEARDOWN after the log is complete (docs/GOTCHAS.md); the END
        # summary line below is the artifact that decides validity.
        REPLAY="tests/replays/$r.rpl" TAP="$addr,2" FRAMES=7000 \
            TRACE_OUT="$OUT/$r.$tag.txt" MAME_SANDBOX="$OUT/sbx_${r}_$tag" MAME_ROMPATH="$RP" \
            tools/run_mame.sh $SET \
            -autoboot_script tests/lua/tap_writes.lua \
            >"$OUT/$r.$tag.log" 2>&1 || true
        printf '.'
    done
done
echo

plant() {  # plant <dir> <a|b> — (a) a word write of id 0x13; (b) a byte write of 0x13 to +0x383 alone
    case "$2" in
    a) printf 'frame 100 PC 020a80 off ff8782 data 00001300 mask 0000ffff\nEND hits 1\n' > "$1/zz_planted.p1.txt" ;;
    b) printf 'frame 101 PC 020a80 off ff8782 data 00000013 mask 000000ff\nEND hits 1\n' > "$1/zz_planted.p1.txt" ;;
    esac
}
if vs_ctl_is word-write-variant; then plant "$OUT" a; fi
cat > "$OUT/analyze.py" <<'PY'
import glob, os, sys, collections
out = sys.argv[1]
BOOT = {0x000D34, 0x000D3A, 0x000DD8, 0x016E4C, 0x016E4E}
bypc = collections.defaultdict(set)
incomplete = []
files = sorted(glob.glob(out + "/*.txt"))
for f in files:
    body = open(f).read()
    if "\nEND " not in body and not body.startswith("END "):
        incomplete.append(os.path.basename(f)); continue
    for line in body.splitlines():
        p = line.split()
        if not p or p[0] != "frame":
            continue
        pc = int(p[3], 16); data = int(p[7], 16); mask = int(p[9], 16)
        if not mask & 0xFF00:
            continue          # only +0x383 written: not the id byte
        bypc[pc].add((data >> 8) & 0xFF)

print("tap logs: %d, complete: %d" % (len(files), len(files) - len(incomplete)))
if incomplete:
    print("INCOMPLETE (no END line): %s" % " ".join(incomplete))

print("\ngameplay writers of the character-id field:")
for pc in sorted(bypc):
    if pc in BOOT:
        continue
    print("  %06X -> %s" % (pc, " ".join("%02X" % v for v in sorted(bypc[pc]))))

gp = {v for pc, vs in bypc.items() if pc not in BOOT for v in vs}
print("\nunion of gameplay-written ids: %s"
      % " ".join("%02X" % v for v in sorted(gp)))
bad = sorted(v for v in gp if 0x10 <= v <= 0x1F)

fail = 0
if incomplete:
    print("\nFAIL: %d tap log(s) lack an END summary line" % len(incomplete))
    fail = 1
if bad:
    print("\nFAIL: a gameplay path wrote a VARIANT-HALF id: %s"
          % " ".join("%02X" % v for v in bad))
    print("  That breaks the 'variant rows are unreachable by legacy'")
    print("  argument in docs/game/atlas/id_space.md — attribute it before")
    print("  planning any tenant on the variant half.")
    fail = 1
if not fail:
    print("\nPASS: no legacy gameplay path writes an id in 0x10-0x1F")
    print("  (caveat in the header: 0x18/Oboro is unexercised by this corpus)")
sys.exit(fail)
PY
rc=0; python3 "$OUT/analyze.py" "$OUT" || rc=$?
# THE IN-GATE CONTROL: plant (a), on a copy of the real logs, must FAIL naming id 13; plant
# (b), on another copy, must leave the verdict PASS (the +0x383 byte is not the id).
if [ -z "${VS_CTL:-}" ]; then
    for k in a b; do
        C="$OUT/ctl_$k"; mkdir -p "$C"; cp "$OUT"/*.txt "$C"/ 2>/dev/null || true; plant "$C" $k
        # the output goes BESIDE the plant directory: a file inside it would be read as a tap log
        eval "crc_$k=0"; python3 "$OUT/analyze.py" "$C" > "$OUT/ctl_$k.out" 2>&1 || eval "crc_$k=\$?"
    done
    if [ "$crc_a" != 0 ] && grep -q 'VARIANT-HALF id: 13$' "$OUT/ctl_a.out" && [ "$crc_b" = 0 ]; then
        vs_ctl_fired word-write-variant "plant (a), a word write of 0x1300 to +0x382, FAILs naming id 13; plant (b), a byte write of 0x13 to +0x383 alone, leaves the verdict PASS"
    else
        vs_ctl_dead word-write-variant "the lanes are not separated (plant a rc=$crc_a, plant b rc=$crc_b)" || rc=1
    fi
else
    vs_ctl_fired word-write-variant "the planted log joined the real ones (mode)"
fi
exit $rc
