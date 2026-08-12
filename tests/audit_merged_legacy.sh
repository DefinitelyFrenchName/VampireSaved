#!/bin/sh
# audit_merged_legacy.sh — does a 3-TENANT MERGED program image perturb LEGACY?
#
# WHY (14z-80 close, maintainer-ordered FIRST priority). The 3-tenant merged
# patch APPLIES (590 ops, 0 collisions) but nothing merged has ever run in an
# emulator, and no legacy gate has seen a merged image. This audit is the
# first evidence the merge BEHAVES rather than merely composes.
#
# THE INSTRUMENT. The merged program image is packed against the zero-filled
# WIDE overlay (build/wide0): legacy characters read gfx groups A/B only, and
# on a variant-id build vsav's group B stays PRISTINE by construction, so
# every legacy character renders correctly and the three tenants draw BLANK
# tiles. That is exactly right for a legacy verdict and useless for anything
# else — build/merged1 is a LEGACY-ONLY INSTRUMENT and must never reach a
# playtest. It has no registry row ON PURPOSE (run_suite.sh refuses it).
#
# WHAT A GREEN RUN PROVES: the merged image's legacy behaviour lands on the
# SAME ratified comparison classes as the frozen single-tenant builds
# (tests/expected/donovan-m3a/*.masked — all three tenant sets agree
# byte-for-byte on the 13 shared legacy entries, and a merged build backs
# 0x13 so 11_pick_donovan applies too). It proves NOTHING about tenant
# correctness: gfx is pristine by design, and the tenants' own behaviour
# batteries wait for the gfx half (M3b Phase 3).
#
# WHAT IS DELIBERATELY ABSENT: merged-vs-single-tenant on the LEGACY replays.
# Leg (a) already compares merged to the invariant's ground truth (vanilla);
# both class tables against vanilla are known, so that differential adds no
# signal. Do not re-add it.
#
# F2 (14z-81, CONFIRMED statically and by section 0's HENT != SHIM check):
# the merged [init_shim] is a singleton (_owner=None, merge_init_shim) ->
# row_here -> emitted on iteration 0 only -> planted at dispatch_00[0x13].
# Huitzil's row is direct-repointed to his handler, so in a MERGED build his
# char-init bypasses pool seeding, the phase gate, and his flavor write (the
# slice-G id-dispatched flavor chain can only ever fire with id 0x13 today).
# Pyron declares no shim (ratified). NOTE (measured 14z-81): F2 is NOT the
# mechanism of the Huitzil leg-(b) crash — that is the satellite anim-base
# defect (tests/audit_merged_vec3.sh); he crashes at spawn, before seeding
# could matter. F2 stands as a second, independent defect whose consequences
# are unmeasured.
#
# CLASS DEVIATIONS ARE MEASURED, NOT RATIFIED. Merged hook chains are longer
# (N=3 concatenation), so cycle skew may shift a flicker frame or a window
# end. Per CLAUDE.md §4 any class that does not match must be
# mechanism-attributed and maintainer-signed before acceptance — this audit
# FAILS on it while printing the measured shape and a proposed expectation
# line, and never widens a tolerance. A PERMANENT class on a legacy replay
# is a superset-invariant violation and halts forward work (CLAUDE.md §2.6).
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/audit_merged_legacy.sh
# On-demand: builds build/merged1 and runs ~26 replay legs (~40 min).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN

OUT="build/merged1"
WIDE_ZIP="${WIDE_ROMSET:-$PWD/build/wide0/rompath/vsavjw.zip}"
EXPECT="tests/expected/donovan-m3a"          # the ratified prior (see header)
BASE_LOGS="tests/expected/vsavj/masked-v2/logs"

# The three frozen extract dirs are the generator's inputs, exactly as
# tests/test_tenant_loop.sh uses them (extraction is deterministic —
# test_m3a_reproducible.sh re-extracts and all four fingerprints are
# bit-exact, so these dirs ARE the fresh-extraction bytes).
D_EX="build/m5_wide/extract"
H_EX="build/hui29/extract"
P_EX="build/pyron20/extract"

missing=""
[ -d "$D_EX" ]      || missing="$missing $D_EX"
[ -d "$H_EX" ]      || missing="$missing $H_EX"
[ -d "$P_EX" ]      || missing="$missing $P_EX"
[ -x "$MAME_BIN" ]  || missing="$missing $MAME_BIN"
[ -f "$WIDE_ZIP" ]  || missing="$missing $WIDE_ZIP"
if [ -n "$missing" ]; then
    echo "SKIP: missing$missing"
    echo "      extract dirs come from the frozen verticals (HANDOFF.md registry):"
    echo "        KEY_SET=vsavj WIDE_ROMSET=... GEN_FLAGS=\"--allow-plausible \\"
    echo "          --tripwire-open --profile cps2-wide-v1\" tools/build_donovan.sh 6 build/m5_wide"
    echo "        (+ TENANT_MANIFEST/TENANT_CHAR for build/hui29 and build/pyron20)"
    echo "      overlay: python3 tools/build_wide_romset.py \"\$ROMDIR\" build/wide0/rompath \\"
    echo "               --qsound 2 --gfx 4 --prg 4"
    exit 0
fi

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0

# Build dirs arrive both relative and absolute; never blindly prepend $PWD
# (the audit_phase_mode_cost lesson — a wrong rompath fails SILENTLY and
# only section 0 catches it).
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }

# describe.py — the measured shape of a divergence, and a proposed
# expectation line in the ratified vocabulary (FLICKER_MAX=2, same as
# compare_composite.py). Used for reporting on any non-matching class.
# Frames are read from the log's first column (compare_window.py's own
# convention: onset/end are FRAME NUMBERS, end = last divergent frame,
# inclusive), so a proposed line drops into a .masked spec verbatim.
cat > "$W/describe.py" <<'PY'
import sys
def load(path):
    out = []
    for line in open(path):
        f = line.split()
        if not f or f[0] == "END":
            continue
        if len(f) >= 2:
            out.append((int(f[0]), f[1]))
    return out
a, b = load(sys.argv[1]), load(sys.argv[2])
n = min(len(a), len(b))
note = "" if len(a) == len(b) else " [LENGTH MISMATCH %d vs %d]" % (len(a), len(b))
d = [i for i in range(n) if a[i] != b[i]]
if not d:
    print("shape: bit-identical%s" % note)
    print("proposed: exact vsavj/masked-v2 -")
    sys.exit(0)
runs, s, p = [], d[0], d[0]
for i in d[1:]:
    if i != p + 1:
        runs.append((s, p)); s = i
    p = i
runs.append((s, p))
tail = n - 1 - runs[-1][1]
fr = lambda i: a[i][0]                       # index -> frame number
flick = [r for r in runs if r[1] - r[0] + 1 <= 2]
wins  = [r for r in runs if r[1] - r[0] + 1 > 2]
print("shape: %d/%d frames differ in %d run(s), first at frame %d, last ends "
      "frame %d, then %d identical%s" % (len(d), n, len(runs), fr(runs[0][0]),
                                         fr(runs[-1][1]), tail, note))
print("runs: " + " ".join("%d-%d" % (fr(x), fr(y)) for x, y in runs))
if tail <= 60:
    print("proposed: NONE — does not re-converge (>=60 identical tail "
          "required); this is not expressible in the ratified vocabulary "
          "and must be root-caused")
elif not wins:
    print("proposed: flicker vsavj/masked-v2 %d %s"
          % (len(d), ",".join(str(fr(i)) for i in d)))
elif not flick:
    print("proposed: window vsavj/masked-v2 %d %d" % (fr(wins[0][0]), fr(wins[0][1]))
          if len(wins) == 1 else
          "proposed: composite vsavj/masked-v2 - " +
          ";".join("%d-%d" % (fr(x), fr(y)) for x, y in wins))
else:
    print("proposed: composite vsavj/masked-v2 %s %s"
          % (",".join(str(fr(i)) for r in flick for i in range(r[0], r[1] + 1)),
             ";".join("%d-%d" % (fr(x), fr(y)) for x, y in wins)))
PY

echo "== B: build the merged image (LEGACY-ONLY INSTRUMENT — never playtest,"
echo "      never register; tenants render BLANK by design) =="
rm -rf "$OUT"; mkdir -p "$OUT"
python3 tools/gen_donovan_patch.py "$D_EX" "$OUT/patch" \
    --extract "$H_EX" --extract "$P_EX" \
    --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
    --port build/manifest/donovan.toml --port build/manifest/huitzil.toml \
    --port build/manifest/pyron.toml \
    --profile cps2-wide-v1 --allow-plausible --tripwire-open \
    > "$OUT/gen.log" 2>&1 || {
        echo "  FAIL: generation errored"; tail -15 "$OUT/gen.log"; exit 1; }
grep -q '^GENERATION OK' "$OUT/gen.log" || {
    echo "  FAIL: no GENERATION OK"; tail -15 "$OUT/gen.log"; exit 1; }
NOPS="$(python3 -c "import json;print(len(json.load(open('$OUT/patch/patch.json'))['ops']))")"
# 591: matches test_tenant_loop.sh's frozen 3-tenant count (which is
# re-frozen FIRST whenever the merge legitimately changes). History: 590
# through 14z-81; 596 for a few hours 14z-81c while the withdrawn stub fix
# was in; 591 since 14z-82 — the F2 merged-shim fall-through tripwire is
# the one added op (the renumbered obj_hook entries grow the table op's
# hex, not the count).
if [ "$NOPS" = 591 ]; then
    echo "  ok: 591 ops (the frozen test_tenant_loop fixture — same merge)"
else
    echo "  FAIL: $NOPS ops, frozen fixture is 591 — the generator drifted;"
    echo "        re-freeze test_tenant_loop.sh FIRST, then revisit this audit"
    exit 1
fi
python3 -c "import json,sys;sys.exit(0 if 'image' in json.load(open('$OUT/patch/patch.json')) else 1)" || {
    echo "  FAIL: no image block — not a WIDE patch, nothing to pack as vsavjw"
    exit 1; }
python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUT/prg" \
    --patch "$OUT/patch/patch.json" > "$OUT/patch_prg.log" 2>&1 || {
        echo "  FAIL: patch_prg refused the merged patch"
        tail -10 "$OUT/patch_prg.log"; exit 1; }
KEY_SET=vsavj ROMDIR="$ROMDIR" tools/pack_build.sh "$OUT/prg" "$OUT/rompath" \
    --set vsavjw --merge "$WIDE_ZIP" > "$OUT/pack.log" 2>&1 || {
        echo "  FAIL: pack"; tail -10 "$OUT/pack.log"; exit 1; }
python3 tools/audit_romset_identity.py "$OUT/rompath" || {
    echo "  FAIL: member-identity audit (above) — do not run anything from this set"
    exit 1; }
FP="$(python3 tools/build_fingerprint.py "$OUT/rompath;$ROMDIR" --set vsavjw --sha-only || true)"
cat > "$OUT/README-LEGACY-ONLY.txt" <<EOF
LEGACY-ONLY INSTRUMENT (tests/audit_merged_legacy.sh, 14z-81).
3-tenant merged program image packed against the zero-filled WIDE overlay:
group C is EMPTY, so Donovan/Huitzil/Pyron render blank tiles BY DESIGN.
Legacy characters are unaffected (they read groups A/B; group B pristine).
NEVER playtest this build. NEVER give it a registry row.
fingerprint: $FP
EOF
echo "  ok: built and packed ($NOPS ops); fingerprint $FP (unregistered ON PURPOSE)"

# ── probe addresses, scraped from the fragment the generator just wrote ────
# ("MERGED init shim" since the 14z-82 F2 fix; the old spelling matches a
# pre-fix build so the negative branch below can still name it)
SHIM="$(sed -n 's/^code *0x0*\([0-9a-f]*\) \(MERGED \)\{0,1\}init shim .*/\1/p' \
        "$OUT/patch/patch_notes_fragment.md" | head -1)"
HENT="$(sed -n 's/^poke32 0x[0-9a-f]* <- 0x0*\([0-9a-f]*\) *dispatch_00\[0x10\].*/\1/p' \
        "$OUT/patch/patch_notes_fragment.md" | head -1)"
PENT="$(sed -n 's/^poke32 0x[0-9a-f]* <- 0x0*\([0-9a-f]*\) *dispatch_00\[0x11\].*/\1/p' \
        "$OUT/patch/patch_notes_fragment.md" | head -1)"
[ -n "$SHIM" ] || { echo "FAIL: no 'init shim' line in the fragment"; exit 1; }
[ -n "$HENT" ] || { echo "FAIL: no dispatch_00[0x10] line (huitzil)"; exit 1; }
[ -n "$PENT" ] || { echo "FAIL: no dispatch_00[0x11] line (pyron)"; exit 1; }
# 14z-82: F2 is FIXED — the assertion is now the POST-fix shape: every
# DECLARING tenant's row routes through the ONE merged shim (Huitzil's row
# = the shim), and Pyron (declares no shim) stays direct BY DECISION.
if [ "$HENT" = "$SHIM" ]; then
    echo "  ok: F2 fixed — Huitzil's dispatch entry IS the merged shim"
    echo "      (0x$SHIM): pool seed + phase gate + his flavor run for him"
else
    echo "  FAIL: Huitzil char-init dispatches to 0x$HENT, BYPASSING the"
    echo "        shim (0x$SHIM) — the F2 defect (STATE 14z-81) is BACK"
    exit 1
fi
if [ "$PENT" = "$SHIM" ]; then
    echo "  FAIL: Pyron's dispatch entry is the shim — he declares NO"
    echo "        [init_shim] and must stay direct (ratified 14z-77)"
    exit 1
fi

MERGED_RP="$(abspath "$OUT")/rompath;$ROMDIR"

pokes_for() {  # pokes_for <hexid> -> both player structs, the template rig
    echo "1400:ff8782:$1;1450:ff8782:$1;1500:ff8782:$1;1400:ff8b82:$1;1450:ff8b82:$1;1500:ff8b82:$1"
}

echo "== 0: the rig FORMS all three tenants' matches (else every verdict"
echo "      below is vacuous). Guarded runs — never checksum-compared. =="
for t in "donovan:13:$SHIM" "huitzil:10:$HENT" "pyron:11:$PENT"; do
    name="${t%%:*}"; rest="${t#*:}"; id="${rest%%:*}"; probe="${rest#*:}"
    POKES="$(pokes_for "$id")" MAME_ROMPATH="$MERGED_RP" \
    GUARD_PROBE="$probe" GUARD_PROBE_MEM=A6+382 \
        tools/run_replay_guarded.sh vsavjw tests/replays/03_two_player_vs.rpl \
        "$W/probe_$name.log" "$W/pbox_$name" >/dev/null 2>&1 || true
    HITS="$(grep -c '^PROBE ' "$W/probe_$name.log" || true)"
    if [ "${HITS:-0}" -ge 1 ]; then
        echo "  ok: $name char-init entry (0x$probe) executed $HITS time(s)"
    else
        echo "  FAIL: $name char-init never ran — the id-$id pokes did not"
        echo "        form a $name match; every 'identical' below would be vacuous"
        exit 1
    fi
done

echo "== 0b: run-to-run determinism on the merged image (never run before) =="
MASK="$(cat "$EXPECT/mask")"
MASK_RANGES="$MASK" MAME_ROMPATH="$MERGED_RP" \
    tools/run_replay_mame.sh vsavjw tests/replays/03_two_player_vs.rpl \
    "$W/a_03_two_player_vs.log" "$W/det1" >/dev/null 2>&1 || {
        echo "  FAIL: masked run did not complete"; exit 1; }
MASK_RANGES="$MASK" MAME_ROMPATH="$MERGED_RP" \
    tools/run_replay_mame.sh vsavjw tests/replays/03_two_player_vs.rpl \
    "$W/det2.log" "$W/det2" >/dev/null 2>&1 || {
        echo "  FAIL: masked run did not complete"; exit 1; }
cmp -s "$W/a_03_two_player_vs.log" "$W/det2.log" || {
    echo "  FAIL: NONDETERMINISTIC — first divergent frame:"
    diff "$W/a_03_two_player_vs.log" "$W/det2.log" | head -3
    exit 1; }
echo "  ok: two masked runs of 03_two_player_vs bit-identical"

echo "== 1 (leg a): merged vs VANILLA on the masked-v2 basis — the superset"
echo "      question. Expectation: donovan-m3a's ratified classes VERBATIM. =="
: > "$W/summary"
for spec in "$EXPECT"/*.masked; do
    name="$(basename "$spec" .masked)"
    printf '%-24s ' "$name"
    sline="$(cat "$spec")"
    class=${sline%% *}; rest=${sline#* }; base=${rest%% *}; args=${rest#* }
    baselog="$REPO/tests/expected/$base/logs/$name.log"
    log="$W/a_$name.log"
    if [ ! -f "$log" ]; then    # 03 already ran in section 0b
        MASK_RANGES="$MASK" MAME_ROMPATH="$MERGED_RP" \
            tools/run_replay_mame.sh vsavjw "tests/replays/$name.rpl" \
            "$log" "$W/abox_$name" >/dev/null 2>&1 || {
                echo "RUN-FAIL"; fail=1
                printf '%s|%s|RUN-FAIL|-\n' "$name" "$class" >> "$W/summary"
                continue; }
    fi
    verdict=""; detail=""
    case "$class" in
    exact)
        if cmp -s "$baselog" "$log"; then verdict=PASS; detail="bit-identical"
        else verdict=FAIL; detail="diverged where the prior is exact"; fi ;;
    flicker)
        got=$(python3 tools/compare_flicker.py "$baselog" "$log") || true
        if [ "$got" = "FLICKER $args" ]; then verdict=PASS; detail="$got"
        else verdict=FAIL; detail="got '$got' want 'FLICKER $args'"; fi ;;
    diverge)
        printf '%s %s' "$base" "$args" > "$W/$name.mdiverge"
        if d=$(python3 tools/check_diverge.py "$log" "$W/$name.mdiverge" \
                   "$REPO/tests/expected"); then verdict=PASS; detail="$d"
        else verdict=FAIL; detail="$d"; fi ;;
    window)
        wonset=${args%% *}; wend=${args##* }
        if d=$(python3 tools/compare_window.py "$baselog" "$log" \
                   --onset "$wonset" --end "$wend" 2>&1); then
            verdict=PASS; detail="$(echo "$d" | head -1)"
        else verdict=FAIL; detail="$(echo "$d" | tr '\n' ' ')"; fi ;;
    composite)
        cfl=${args%% *}; cwin=${args##* }
        if d=$(python3 tools/compare_composite.py "$baselog" "$log" \
                   --flicker "$cfl" --windows "$cwin" 2>&1); then
            verdict=PASS; detail="$(echo "$d" | head -1)"
        else verdict=FAIL; detail="$(echo "$d" | tr '\n' ' ')"; fi ;;
    *)  verdict=FAIL; detail="unknown class '$class' in the prior" ;;
    esac
    if [ "$verdict" = PASS ]; then
        echo "PASS $class ($detail)"
        printf '%s|%s|PASS|%s\n' "$name" "$class" "$detail" >> "$W/summary"
    else
        echo "FAIL $class: $detail"
        echo "        MEASURED, NOT RATIFIED — mechanism-attribute before touching"
        echo "        the expectation (CLAUDE.md §4). Measured shape:"
        python3 tools/analyze_divergence.py "$baselog" "$log" 2>&1 | sed 's/^/        /'
        python3 "$W/describe.py" "$baselog" "$log" | sed 's/^/        /'
        mkdir -p build/gate_failures
        cp "$log" "build/gate_failures/merged1_a_$name.log"
        echo "        log kept: build/gate_failures/merged1_a_$name.log"
        fail=1
        printf '%s|%s|FAIL|%s\n' "$name" "$class" "$detail" >> "$W/summary"
    fi
done
echo "  -- leg (a) summary (replay | expected class | verdict) --"
awk -F'|' '{printf "     %-24s %-10s %s\n", $1, $2, $3}' "$W/summary"

echo "== 2 (leg b): merged vs the frozen single-tenant builds on TENANT"
echo "      content — does MERGING change what each tenant's build did?"
echo "      Whole-RAM identity is NOT expected (placements differ and placed"
echo "      addresses are cached into RAM pointers; the select screens also"
echo "      legitimately differ — single-tenant builds back one medallion,"
echo "      merged backs three). Gate: a clean guarded run, a first"
echo "      divergence no earlier than frame 850 (boot/attract must be"
echo "      unperturbed), and a NON-identical pair (identical = dead rig). =="
# replay | reference build | pokes (the rig each replay was authored for)
POK13="$(pokes_for 13)"
HUI_SOAK="1704:ff8782:10;1760:ff8782:10;1900:ff8782:10;2100:ff8782:10;2400:ff8782:10"
HUI_FX="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"
PYR_SOAK="1704:ff8782:11;1760:ff8782:11;1900:ff8782:11;2100:ff8782:11;2400:ff8782:11"
# 72_pyron_cosmo_2p: the ONLY rig that fires the Cosmo pair (test_pyron_cosmo:
# P2=Victor, meter stocked via $FF8509 — with an empty meter the pair is
# downgraded and the run proves nothing).
PYR_COSMO="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3300:ff8509:03;3700:ff8509:03;4100:ff8509:03"
legb() {  # legb <replay-rel> <refbuild> <pokes> <label>
    rpl="$1"; ref="$2"; pk="$3"; label="$4"
    nm="$(basename "$rpl")"
    printf '%-28s ' "$label"
    if ! POKES="$pk" MAME_ROMPATH="$MERGED_RP" \
         tools/run_replay_guarded.sh vsavjw "tests/replays/$rpl.rpl" \
         "$W/g_$nm.log" "$W/gbox_$nm" > "$W/g_$nm.out" 2>&1; then
        echo "FAIL: guard tripped on the MERGED build:"
        grep -m2 -E "CRASH|SOFTRESET|PCWEEDS|REGS" "$W/g_$nm.log" \
            || tail -5 "$W/g_$nm.out"
        mkdir -p build/gate_failures
        cp "$W/g_$nm.log" "build/gate_failures/merged1_b_$nm.log"
        echo "        log kept: build/gate_failures/merged1_b_$nm.log"
        if [ "${nm#*hui}" != "$nm" ]; then
            echo "        (14z-81 measured this class: the satellite's runtime-"
            echo "         composed anim base carries a DONOVAN address on a"
            echo "         Huitzil object — tests/audit_merged_vec3.sh is the"
            echo "         probe. NOT the F2 pool-seeder path: he crashes at"
            echo "         spawn, before seeding could matter)"
        fi
        # 14z-82b: ALWAYS measure the REFERENCE leg too. Bailing here left
        # "the single-tenant build is clean" as an ASSUMPTION, and it was
        # false — pyron20 crashes at f7997 solo (the latent hit-class map
        # over-index). A guard verdict on the ref leg decides whether the
        # defect is MERGE-SPECIFIC or LATENT IN THE FROZEN BUILD, which are
        # different bugs with different owners.
        if POKES="$pk" MAME_ROMPATH="$(abspath "$ref")/rompath;$ROMDIR" \
             tools/run_replay_guarded.sh vsavjw "tests/replays/$rpl.rpl" \
             "$W/gr_$nm.log" "$W/grbox_$nm" > "$W/gr_$nm.out" 2>&1; then
            echo "        ref leg ($ref): guard CLEAN — the crash is"
            echo "        MERGE-SPECIFIC"
        else
            echo "        ref leg ($ref): guard ALSO trips —"
            grep -m1 -E "CRASH|SOFTRESET|PCWEEDS" "$W/gr_$nm.log" \
                | sed 's/^/        /' || true
            echo "        the defect is LATENT IN THE FROZEN BUILD, not a"
            echo "        merge artifact — attribute it there"
        fi
        fail=1; return 0
    fi
    POKES="$pk" MAME_ROMPATH="$(abspath "$ref")/rompath;$ROMDIR" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$rpl.rpl" \
        "$W/b_${nm}_ref.log" "$W/brbox_$nm" >/dev/null 2>&1 || true
    POKES="$pk" MAME_ROMPATH="$MERGED_RP" \
        tools/run_replay_mame.sh vsavjw "tests/replays/$rpl.rpl" \
        "$W/b_${nm}_new.log" "$W/bnbox_$nm" >/dev/null 2>&1 || true
    if cmp -s "$W/b_${nm}_ref.log" "$W/b_${nm}_new.log"; then
        echo "FAIL: bit-identical to $ref — impossible with moved placements;"
        echo "        the rig stopped forming the match (dead-rig control)"
        fail=1; return 0
    fi
    first="$(python3 - "$W/b_${nm}_ref.log" "$W/b_${nm}_new.log" <<'PY'
import sys
def load(path):
    return [(f[0], f[1]) for f in (l.split() for l in open(path))
            if len(f) >= 2 and f[0] != "END"]
a, b = load(sys.argv[1]), load(sys.argv[2])
n = min(len(a), len(b))
i = next((i for i in range(n) if a[i] != b[i]), None)
print(-1 if i is None else int(a[i][0]))
PY
)"
    if [ "$first" -lt 850 ]; then
        echo "FAIL: first divergence at frame $first (< 850) — the merged"
        echo "        image perturbs BOOT/ATTRACT relative to $ref, which no"
        echo "        select/placement mechanism explains. Root-cause first."
        python3 tools/analyze_divergence.py "$W/b_${nm}_ref.log" \
            "$W/b_${nm}_new.log" 2>&1 | sed 's/^/        /'
        fail=1; return 0
    fi
    echo "ok: guard clean; vs $ref:"
    python3 tools/analyze_divergence.py "$W/b_${nm}_ref.log" \
        "$W/b_${nm}_new.log" 2>&1 | sed 's/^/        /'
    echo "        (classified REPORT for the maintainer, not a gate — see header)"
}
legb 12_donovan_vs_cpu      build/m5_wide  "$POK13"     "donovan/12_vs_cpu"
legb 20_don_round2          build/m5_wide  "$POK13"     "donovan/20_round2"
legb hui/70_hui_mash        build/hui29    "$HUI_SOAK"  "huitzil/70_mash"
legb hui/83_hui_fx          build/hui29    "$HUI_FX"    "huitzil/83_fx"
legb pyron/70_pyron_mash    build/pyron20  "$PYR_SOAK"  "pyron/70_mash"
legb pyron/72_pyron_cosmo_2p build/pyron20 "$PYR_COSMO" "pyron/72_cosmo_2p"

echo
if [ "$fail" != 0 ]; then
    echo "FAIL: merged-legacy audit — read the per-replay verdicts above."
    echo "      A leg-(a) deviation is MEASURED, NOT RATIFIED (CLAUDE.md §4);"
    echo "      a PERMANENT class there halts forward work (§2.6)."
    exit 1
fi
echo "PASS: the 3-tenant merged program image lands on the ratified legacy"
echo "      classes VERBATIM (leg a), and each tenant's own content forms"
echo "      matches, survives the crash guard, and leaves boot/attract"
echo "      untouched relative to its frozen single-tenant build (leg b)."
echo "      This proves LEGACY SAFETY of the merge only — tenant correctness"
echo "      waits for the gfx half (M3b Phase 3)."
