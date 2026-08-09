#!/bin/sh
# build_donovan.sh — the donovan-m2 build driver: checksum gate -> extract
# (vhunt2 oracle) -> generate staged patch -> apply -> pack runnable rompath.
#
# Usage: ROMDIR=... tools/build_donovan.sh <stage 1-5> [outbase=build/donovan]
#
# Output: <outbase>/rompath/vsavj.zip — run with
#   MAME_ROMPATH="<outbase>/rompath;$ROMDIR" tools/run_mame.sh vsavj ...
# All ROM-derived intermediates live under <outbase> (gitignored) and are
# regenerated from $ROMDIR on every run (repo rule 7).
set -eu
set -o pipefail  # 14z-10: a crashed build_gfx must not pack stale tiles silently

STAGE="${1:?usage: build_donovan.sh <stage 1-6> [outbase]}"
OUTBASE="${2:-build/donovan}"
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
mkdir -p "$OUTBASE"

# Tenant selection (14z-65, M3b): the driver serves any single-tenant
# manifest. Defaults preserve the Donovan behavior byte-for-byte
# (tests/test_m3a_reproducible.sh arbitrates). TENANT_CHAR must match the
# manifest's src_char — extract_char anchors on it and the generator
# rewrites its id immediates.
TENANT_MANIFEST="${TENANT_MANIFEST:-build/manifest/donovan.toml}"
TENANT_CHAR="${TENANT_CHAR:-0x13}"

python3 tools/audit_roms.py "$ROMDIR" > /dev/null || {
    echo "ROM audit FAILED — stop (CLAUDE.md §3)"; exit 1; }

# Decrypted analysis views (gitignored intermediates): the extractor and
# generator read build/out/<set>_{opcodes,data}.bin. Regenerate any that
# are missing — deterministic from the audited reference sets.
mkdir -p build/out
for _set in vsavj vsav2 vhunt2; do
    if [ ! -f "build/out/${_set}_opcodes.bin" ] || [ ! -f "build/out/${_set}_data.bin" ]; then
        echo "regenerating decrypted views for $_set ..."
        python3 tools/cps2_decrypt.py "$ROMDIR/${_set}.zip" \
            "build/out/${_set}_opcodes.bin" \
            --data-out "build/out/${_set}_data.bin" | tail -2
    fi
done

# EXTRA_ROOTS: absent-in-vsavj support routines ported as extra code
# regions (found by the stage-4 R1 loop; see docs/project/tables/reconciliation.md).
# Default = the full stage-4 set: the +0x34 newcomer-support zone, the tiny
# VS2 helpers, the id-normalization/char-init engine pair, the source-only
# per-game hook, and the 17 extra secondary-object handlers (types 59-75,
# forced-twin +0x34, caps = inter-handler gaps). Only the handler types
# Donovan actually spawns are ported (59-62); the other extras belong to
# Huitzil/Pyron and stay TRIPWIRED — loud if ever reached (space budget,
# session 5).
DEFAULT_ROOTS="0x5c800:0xd100,0x26142:0x1400,0x28122:0xe00,0x88512:0x2f00:s,0x905ae:0x300:s,0x2b7ef4:0xb20c:t0x2a4398:d"
# x2b7ef4 extends the old x2b8060 root 0x16C earlier: a companion anim
# word table sits just BEFORE the previous bound (session 13 mash crash —
# its ref was tripwired as data and read as an anim table). Twin verified
# byte-identical for the extension.
DEFAULT_ROOTS="$DEFAULT_ROOTS"
DEFAULT_ROOTS="$DEFAULT_ROOTS,0x65952:0x2d0:t0x65986,0x65c22:0x238:t0x65c56,0x65e5a:0x106a:t0x65e8e,0x66ec4:0x2b8:t0x66ef8"
# session 14w-c: type 63 IS spawned by Donovan's own deep-arcade flow —
# 21_don_mash tripped its tripwire (0xCB880) at frame 10050 once the CPU
# Felicia moved correctly (the pair-table fix changed the fight flow).
# The "59-62 only" assumption is measured-wrong for 63; handler ported
# with the standard +0x34 twin. 64-75 remain tripwired (still unseen).
DEFAULT_ROOTS="$DEFAULT_ROOTS,0x6717c:0x154:t0x671b0"
# DEFAULT_ROOTS is DONOVAN'S measured root census — it applies only to his
# char. Another tenant's census accumulates here as its R1 loop finds
# roots (EXTRA_ROOTS overrides for census experiments).
case "$TENANT_CHAR" in
    0x13) : ;;   # Donovan's census above
    0x10)
        # Huitzil census (14z-65, ladder): the widened NEWCOMER_CODE
        # window (0x54000+) absorbs his low handler zone incl. the old
        # 0x55478 root — his "code" region now spans it natively.
        # 0xd143e = the 18-ring velocity-vector family (0x80 B/ring,
        # radius-indexed sin/cos pairs) his code bases at 0xd15be —
        # vs2-only bank data (the vsavj delta candidate is zeros);
        # structure-bounded, sibling-identical, twin at -0x76e.
        DEFAULT_ROOTS="0xd143e:0x900:t0xd0cd0:d"
        # The SHARED newcomer-support zones from Donovan's census — H's
        # code references the same zones (measured 14z-65: 0x5DF74 sits in
        # x05c800, his handler-head jsr 0x8ACD8 and 0x8A5A8 sit in the
        # source-only x088512 zone, plus x026142/x028122 directly). Ported
        # per-tenant for the single-tenant ladder; Phase 2 dedups by span.
        # x088512 is 0x3B40 here, not Donovan's 0x2f00: H's copy of the
        # zone chains dispatch tables past the 0x2f00 bound — transitive
        # closure of its pcrel escapes converges at +0x3B3E (measured
        # 14z-65, 6 rounds). Donovan's bound was HIS census, not the
        # zone's true extent.
        # x2b7ef4 (14z-65): the companion-anim zone — HIS PODS use it too
        # (measured: the pod-node setup at vs2 0x8B156 reads the table at
        # 0x2B8060; unrooted, the operand resolved to a CODE TRIPWIRE and
        # the "table" read returned ILLEGAL-opcode bytes as node offsets).
        # Donovan's root verbatim (newcomer-shared data, same oracle twin).
        #
        # 14z-70 — x088512 grows 0x3B40 -> 0x3B98 with a RAW tail from
        # +0x3B78. The zone's own effect machine ends in a three-call run
        #     08C014 lea (0x74,pc),A0  -> 08C08A     08C018 jsr $09C4F6
        #     08C026 lea (0x72,pc),A0  -> 08C09A     08C02A jsr $09C4F6
        #     08C038 lea (0x68,pc),A0  -> 08C0A2     08C03C jmp $09C4F6
        # whose three tables sat 0x38/0x48/0x50 PAST the old end, so each
        # pc-rel pointer resolved to target+delta = 0x0D8988/98/A0 — inside
        # the ANIM region placed immediately after (0x0D8950). The machine
        # read animation bytes as its parameters, which is how the 214+P
        # explosion's pieces ended up pointed at an unrelated VSAVJ sprite
        # list (verify_pcrel_data.py: 3 BROKEN here). Same defect as
        # x06cac0 (14z-69h/i/j), same fix.
        # Split = the FIRST TABLE (+0x3B78), not the old end: everything
        # already shipped as encrypted code keeps that treatment, and only
        # the newly-pulled-in tail is raw. End = 0x08C0AA (+0x3B98) = the
        # last table's end, where a different 0x14-stride structure with
        # real pointers begins — do NOT swallow it. The three tables are
        # plain word offsets (0x0020-0x00FC, no pointer fields), which is
        # what makes forcing them safe (`:f` copies unvalidated bytes).
        DEFAULT_ROOTS="$DEFAULT_ROOTS,0x5c800:0xd100,0x26142:0x1400,0x28122:0xe00,0x88512:0x3b98:s:f0x3b78,0x2b7ef4:0xb20c:t0x2a4398:d"
        # The secondary-object handler family 64-75 (14z-65): H's moves
        # spawn these (type 72 named by the round-2 soak tripwire); all
        # twelve rooted pre-emptively (caps = inter-handler gaps, twins
        # +0x34 — the zone convention; the oracle bound validates each).
        DEFAULT_ROOTS="$DEFAULT_ROOTS,0x672d0:0x280:t0x67304,0x67550:0x2f6:t0x67584,0x67846:0x1ba:t0x6787a,0x67a00:0x60c:t0x67a34,0x6800c:0x44c:t0x68040,0x68458:0x310:t0x6848c,0x68768:0x264:t0x6879c,0x689cc:0x2ac:t0x68a00,0x68c78:0x3ce:t0x68cac,0x69046:0x2b0:t0x6907a,0x692f6:0x368:t0x6932a,0x6965e:0x400:t0x69692"
        # 14z-71 THE BEAM: effect-CLASS 16's handler family. The per-pool
        # effect dispatcher (`move.b 0x02(a6),d0; add.w d0,d0; add.w d0,d0;
        # movea.l (0x12,pc,d0.w),a0; jsr (a0)` — vsavj 0x080A90) indexes a
        # 38-row table of handler pointers by object field +0x02. vsav ships
        # rows 16/17/19/31 as STUBS (the bare `rts` sitting right after the
        # table); vs2 and vh2 fill 16/17/19. Row 16 is the beam's: measured
        # on both legs, our build ALREADY sets class 16 on the same object at
        # the same frames and loads the stub. That is the entire defect.
        # The bound is MEASURED, not guessed: [0x93460, 0x93766) is the
        # row-16 family exactly — its four-instruction head, its type table,
        # the state machine that selects the beam anim (`movea.l #$24EDD4,a0`
        # = the base 14z-70 traced), the helper at 0x93550 with its 196-entry
        # sub-table, ending on the rts at 0x93764 with row 17's
        # identically-shaped head immediately after. Every pc-relative table
        # AND every one of their targets is inside the span; census: 0
        # lea(pc) data-in-code readers, 0 pcrel escapes of either form.
        # Twin 0x9306C is vhunt2's OWN row-16 entry, so the sibling oracle
        # covers the whole span (its only diffs: 3 engine longs at delta
        # -0x6, 1 anim pointer at +0x13B74).
        # `:f` — the oracle stops at +0x300 and that stop is REAL, not
        # granularity: its next 0x100 chunk reaches row 17's family, whose
        # genuine sibling divergence starts at +0x397. But the family's last
        # instruction pair straddles +0x300 (`move.w 0x14(a4),0x14(a6)` at
        # +0x2FE, then the `rts` at +0x304), so stopping there would place a
        # region that runs off its own end into the allocator's next bytes —
        # the x088512 "0x50 bytes short" class, exactly. The forced tail is
        # SIX bytes (00 14 00 14 4e 75), hand-verified byte-identical in
        # vhunt2 at the twin and carrying no pointer field, which is the
        # only condition under which `:f` copies unvalidated bytes safely.
        DEFAULT_ROOTS="$DEFAULT_ROOTS,0x93460:0x306:t0x9306c:f"
        # 14z-66 item 3: the vs2 JUMP-SEQ HANDLER BODY (sub-state
        # dispatcher 0x2592A + table 0x25936 + all five bodies, ends
        # before the 0x25D80 handler). vs2 rewrote the bodies into the
        # newcomer air system: sub-state 1 = the flavor-forked FLOAT
        # (rise/hover, +0x1C0 timer), 3 = the +0x23-gated air action, 4 =
        # the jump restart. vsavj's twin (0x26A58 family) shares the
        # architecture (incl. the node-bit-7 conversion) but its bodies
        # are the plain vanilla arcs. Cloned whole; the tenant_jump_seq
        # site_thunk dispatches tenant owners into the clone's table.
        # vh2 twin +0x2E, 7/1110 sibling-diff bytes (oracle-clean).
        DEFAULT_ROOTS="$DEFAULT_ROOTS,0x2592a:0x456:t0x25958"
        # 14z-67 (ping #8): THE EFFECT-ZONE CLONE — vs2's effect-object
        # state machine (50 per-state handler sites, the sustained-beam/
        # lightning/explosion segments incl. the four fleet-jmp tails)
        # + the fleet-spawner family. Twins: zone +0x2E (the engine-
        # clone convention), spawners +0x174 (measured, 61-64/64
        # agreement 0x6D240-0x6D73F). Entered via the owner-gated
        # effect_machine site_thunk (huitzil.toml).
        # `:f0xca8` (14z-69i) — x06cac0's own pc-rel param
        # tables (0x6D768-0x6D96C) fall PAST the sibling-oracle boundary
        # (+0xC00), so today they sit outside the region and all 7
        # pointers resolve into unrelated bytes (tools/verify_pcrel_data.py).
        # `0x6cac0:0xebc:t0x6cc34:f` pulls them in and was measured to place
        # them at the right relative address — but the tables then carry the
        # OPCODE image (code regions are stored to execute) while the engine
        # reads them as DATA, so they still decode as garbage. Landing `:f`
        # is only half the fix: it must arrive WITH the five
        # [[data_in_code]] rows the census then reports, and those need the
        # generator's reroute to learn the POST-INCREMENT shape (bsr.w to a
        # `lea.l #table,An; rts` helper — the existing jsr+nop rewrite needs
        # 8 contiguous bytes and the reader is 0x3E away).
        DEFAULT_ROOTS="$DEFAULT_ROOTS,0x22400:0x1600:t0x2242e,0x6cac0:0xebc:t0x6cc34:f0xca8"
        ;;
    0x11)
        # Pyron census (14z-67, moveset arc open). Measured from his
        # code region's 131 unique engine-ref targets:
        # - 0xd143e = the 18-ring velocity-vector family (based at
        #   0xd15be — the SAME vs2-only bank data H's census ports;
        #   structure-bounded, sibling-identical, twin at -0x76e).
        # - The SHARED newcomer-support zones his code references
        #   directly (40 targets in x05c800, 19 in x028122, 15 in
        #   x026142, 1 in x088512 — the H bounds: x088512's true
        #   extent is 0x3B40, measured 14z-65). 0x905ae is NOT
        #   referenced by his code — omitted (minimal census; add it
        #   the moment a tripwire names it).
        # - x2b7ef4 (companion-effect records, data) rides along: the
        #   x088512 zone's spawners reference it (the Donovan/H
        #   precedent) and his secondary types resolve through it.
        # 55 unresolved engine targets remain TRIPWIRED (families:
        # alloc pair 0x15702/2E, sound helpers 0x4F96-0x5038, engine
        # subs 0x28FA0-0x29950 + 0x4223C-0x448D4) — the R1 loop
        # resolves them as probes fire.
        DEFAULT_ROOTS="0xd143e:0x900:t0xd0cd0:d"
        DEFAULT_ROOTS="$DEFAULT_ROOTS,0x5c800:0xd100,0x26142:0x1400,0x28122:0xe00,0x88512:0x3b40:s,0x2b7ef4:0xb20c:t0x2a4398:d"
        # The newcomer-satellite handler family (types 64-75; the same
        # 12 regions H's census ports — SHARED engine-side handlers,
        # proven by P's first satellite spawn tripping obj_hook type 64
        # -> unresolved 0x672d0). Bounds/twins = the measured H rows.
        DEFAULT_ROOTS="$DEFAULT_ROOTS,0x672d0:0x280:t0x67304,0x67550:0x2f6:t0x67584,0x67846:0x1ba:t0x6787a,0x67a00:0x60c:t0x67a34,0x6800c:0x44c:t0x68040,0x68458:0x310:t0x6848c,0x68768:0x264:t0x6879c,0x689cc:0x2ac:t0x68a00,0x68c78:0x3ce:t0x68cac,0x69046:0x2b0:t0x6907a,0x692f6:0x368:t0x6932a,0x6965e:0x400:t0x69692" ;;
    *)  DEFAULT_ROOTS="" ;;
esac
python3 tools/extract_char.py "$ROMDIR/vsav2.zip" "$OUTBASE/extract" \
    --char "$TENANT_CHAR" --oracle "$ROMDIR/vhunt2.zip" \
    --extra-roots "${EXTRA_ROOTS-$DEFAULT_ROOTS}" > "$OUTBASE/extract.log" 2>&1 \
    || { tail -20 "$OUTBASE/extract.log"; exit 1; }

# GEN_FLAGS: extra generator flags (e.g. "--allow-plausible --tripwire-open"
# for stage-4 experiment builds while the R1 map converges)
# shellcheck disable=SC2086
python3 tools/gen_donovan_patch.py "$OUTBASE/extract" "$OUTBASE/patch" \
    --vsavj "$ROMDIR/vsavj.zip" --stage "$STAGE" \
    --port "$TENANT_MANIFEST" ${GEN_FLAGS:-}

python3 tools/patch_prg.py "$ROMDIR/vsavj.zip" "$OUTBASE/prg" \
    --patch "$OUTBASE/patch/patch.json" | tail -3

# Stage 6+: select-screen portrait/name/highlight. Two mechanisms, chosen
# by the tenant's id (patch/tenant.json, written by the generator):
#   base-half id (the substituted slot 0x0F): tools/select_port.py in-place
#     record surgery on the host's records — the frozen-reference mechanism.
#   variant-half id (M3a de-substitution): the records were COMPOSED BY THE
#     GENERATOR into space-model allocations and the six array rows poked in
#     patch.json; select_port must NOT run — the host's records stay
#     vanilla. The generator also emitted the matching tile-placement map.
# Stage-6 gfx is per-tenant via the ratified 3-tenant layout manifest
# (14z-67, build/manifest/gfx_layout3.toml): obj_records span and
# band/delta resolve from the tenant's row. 14z-74: Pyron (0x11) UNLOCKED —
# his gfx rung is in progress, and his one-source-bank premise is measured
# (tests/test_list_type_census.sh: 0 type-4 in his fighter span, against a
# live 26-hit control on Huitzil's), so his delta-0 placement is complete
# with no strip-tiles work. Anyone else still gets refused loudly rather
# than built half-wired.
if [ "$STAGE" -ge 6 ] && [ "$TENANT_CHAR" != "0x13" ] \
   && [ "$TENANT_CHAR" != "0x10" ] && [ "$TENANT_CHAR" != "0x11" ]; then
    echo "build_donovan.sh: stage >= 6 supports tenants 0x13/0x10/0x11 today" >&2
    echo "  (this tenant's stage-6 manifest sections do not exist yet)." >&2
    echo "  Build it at stage <= 5." >&2
    exit 1
fi
TEN_ID="$(python3 -c "import json;print(json.load(open('$OUTBASE/patch/tenant.json'))['id'])")"
if [ "$STAGE" -ge 6 ]; then
    if [ "$TEN_ID" -lt 16 ]; then
        python3 tools/select_port.py "$OUTBASE/prg" --vs2 "$ROMDIR/vsav2.zip" \
            --tiles-out "$OUTBASE/select_tiles.json" | tail -5
    else
        echo "select: tenant at variant id $TEN_ID — records generated" \
             "(select_port skipped; the host's select records stay vanilla)"
        cp "$OUTBASE/patch/select_tiles.json" "$OUTBASE/select_tiles.json"
    fi
fi

rm -rf "$OUTBASE/rompath"
# CPS-2 WIDE builds pack as the vsavjw SET and fold in the profile's appended
# gfx/QSound members, which this pipeline does not produce itself. Detected
# from the generator's own output (patch.json carries an "image" block only
# when a profile-gated space was actually used), so the set name can never
# disagree with what was built.
PACK_SET="vsavj"
PACK_MERGE=""
if python3 -c "import json,sys; sys.exit(0 if json.load(open('$OUTBASE/patch/patch.json')).get('image') else 1)" 2>/dev/null; then
    PACK_SET="vsavjw"
    PACK_MERGE="${WIDE_ROMSET:-build/wide0/rompath/vsavjw.zip}"
    echo "WIDE build: packing as $PACK_SET (merging $PACK_MERGE)"
    ROMDIR="$ROMDIR" tools/pack_build.sh "$OUTBASE/prg" "$OUTBASE/rompath" \
        --set "$PACK_SET" --merge "$PACK_MERGE" > /dev/null
else
    ROMDIR="$ROMDIR" tools/pack_build.sh "$OUTBASE/prg" "$OUTBASE/rompath" > /dev/null
fi

# Stage 6+: gfx side — place Donovan's tiles into vsav's group-B members
# (Jedah band) and carry a patched vsav.zip in the rompath so it fronts
# the pristine ROMDIR copy. Program-side remap is stage-6 generator work
# (donovan.toml [gfx_remap] + stage-gated port_patch rows).
if [ "$STAGE" -ge 6 ]; then
    # STALE-OUTPUT GUARD (14z-62h, found by the maintainer's playtest):
    # build_gfx writes ONLY the members the current mode produces, but the
    # pack step globs the OUTPUT DIR — group-B members left over from a
    # previous (pre-group-C) build were re-packed into vsav.zip, so FBNeo
    # served Donovan's band as Jedah's while MAME silently hash-matched to
    # the pristine ROMDIR copy and hid it. Clean before generating.
    rm -f "$OUTBASE/gfx"/vm3.*m "$OUTBASE/gfx"/vsw.*m
    # the tenant's anim span + cptr window from its layout row (14z-67;
    # the cptr window 0x300000-0x361000 covers all three tenants'
    # coordinate lists — measured, tests/test_gfx_layout3.sh premise)
    OBJ_SPAN="$(python3 - "$TENANT_CHAR" <<'PY'
import sys
sys.path.insert(0, "tools")
from _minitoml import loads
lay = loads(open("build/manifest/gfx_layout3.toml").read())
row = {r["id"]: r for r in lay["tenant"]}[int(sys.argv[1], 16)]
print(f"{row['anim_base']:#x} {row['anim_base'] + row['anim_len']:#x} "
      f"{row['sweep_lo']:#x} {row['sweep_hi']:#x}")
PY
)"
    # shellcheck disable=SC2086
    set -- $OBJ_SPAN
    OBJ_BASE="$1"; OBJ_END="$2"; SWEEP_LO="$3"; SWEEP_HI="$4"
    python3 tools/obj_records.py "$OUTBASE/extract/region_anim.bin" \
        --base "$OBJ_BASE" --start "$OBJ_BASE" --end "$OBJ_END" \
        --cptr-lo 0x300000 --cptr-hi 0x361000 \
        --sweep-lo "$SWEEP_LO" --sweep-hi "$SWEEP_HI" \
        --json "$OUTBASE/donovan_tiles.json" > /dev/null
    # EXTRA TILES (14z-69o): codes the OBJ-record walk above cannot reach
    # (it follows pointers; offset-computed records are invisible to it —
    # docs/project/gotchas.md). Without them the copy inventory has a hole
    # and the sprites that use them resolve to an EMPTY group-C tile, which
    # renders as a solid rectangle. Declared per tenant id, merged here so
    # the copier sees one inventory.
    EXTRA_TILES="build/manifest/extra_tiles/${TENANT_CHAR}.json"
    if [ -f "$EXTRA_TILES" ]; then
        python3 - "$OUTBASE/donovan_tiles.json" "$EXTRA_TILES" <<'PYEOF'
import json, sys
inv_p, extra_p = sys.argv[1], sys.argv[2]
inv = json.load(open(inv_p))
extra = json.load(open(extra_p))["tiles"]
before = len(inv)
merged = sorted(set(inv) | set(extra))
json.dump(merged, open(inv_p, "w"))
added = sorted(set(extra) - set(inv))
print("  extra tiles: +%d (%s), inventory %d -> %d"
      % (len(added), " ".join("0x%04X" % t for t in added), before, len(merged)))
PYEOF
    fi
    OVERLAY_TILES=""
    [ -f build/manifest/overlay/overlay_tiles.json ] && [ "$TENANT_CHAR" = "0x13" ] && \
        OVERLAY_TILES="--overlay-tiles build/manifest/overlay/overlay_tiles.json"
    # effect_map exists only for delta-shifted tenants (Donovan); a
    # delta-0 tenant's tiles never move, so there is nothing to remap
    EFFECTS=""
    [ -f "$OUTBASE/patch/effect_map.json" ] && \
        EFFECTS="--effects $OUTBASE/patch/effect_map.json"
    # shellcheck disable=SC2086
    python3 tools/build_gfx_donovan.py "$ROMDIR" "$OUTBASE/gfx" \
        --tiles "$OUTBASE/donovan_tiles.json" \
        $EFFECTS \
        --select-tiles "$OUTBASE/select_tiles.json" \
        $( [ -f "$OUTBASE/patch/select_bank5.json" ] && \
           echo "--select-bank5 $OUTBASE/patch/select_bank5.json" ) \
        $( [ -f "$OUTBASE/patch/effect_c5.json" ] && \
           echo "--effect-c5 $OUTBASE/patch/effect_c5.json" ) \
        $( [ -f "$OUTBASE/patch/wheel_bank5.json" ] && \
           echo "--wheel-bank5 $OUTBASE/patch/wheel_bank5.json" ) \
        --effect-tail build/manifest/effect_tail.json $OVERLAY_TILES \
        $( [ -f "build/manifest/strip_tiles/${TENANT_CHAR}.json" ] && \
           echo "--strip-tiles build/manifest/strip_tiles/${TENANT_CHAR}.json" ) \
        --tenant "$OUTBASE/patch/tenant.json" | tail -10
    GFXSTAGE="$(mktemp -d)"
    unzip -q -o "$ROMDIR/vsav.zip" -d "$GFXSTAGE"
    cp "$OUTBASE/gfx"/vm3.*m "$GFXSTAGE"/
    ( cd "$GFXSTAGE" && rm -f vsav.zip && zip -q -X vsav.zip * )
    cp "$GFXSTAGE/vsav.zip" "$OUTBASE/rompath/vsav.zip"
    rm -rf "$GFXSTAGE"
    echo "gfx: patched vsav.zip in rompath (ROMDIR untouched)"
    # Group C mode (variant-id tenant): the band+shelf tiles were written
    # as vsw simms; replace the zero-fill members inside the packed
    # vsavjw.zip. The host's group B stays pristine (build_gfx_donovan did
    # not write it), which is the visual half of de-substitution.
    if ls "$OUTBASE/gfx"/vsw.*m > /dev/null 2>&1; then
        RPZIP="$(cd "$OUTBASE/rompath" && pwd)/vsavjw.zip"
        ( cd "$OUTBASE/gfx" && zip -q -X "$RPZIP" vsw.*m )
        echo "gfx: group C members injected into vsavjw.zip (host group B pristine)"
        # ...and ASSERT it, in the zip itself. An emulator over a chained
        # rompath is NOT a member-identity instrument (MAME may hash-match
        # a pristine copy elsewhere in the path — exactly how the stale-
        # member bug stayed invisible to every MAME-side measurement).
        if ! python3 - "$OUTBASE/rompath/vsav.zip" "$ROMDIR/vsav.zip" <<'PY'
import sys, zipfile
b, p = (zipfile.ZipFile(a) for a in sys.argv[1:3])
bad = [n for n in ("vm3.14m", "vm3.16m", "vm3.18m", "vm3.20m")
       if b.getinfo(n).CRC != p.getinfo(n).CRC]
if bad:
    print("group B members differ from pristine:", bad)
    sys.exit(1)
print("  verified: group B members pristine in the packed vsav.zip")
PY
        then
            echo "BUILD REJECTED: group B not pristine in the packed vsav.zip" >&2
            exit 1
        fi
    fi
    # static output verification (record parity + code containment +
    # placed bank table) — the check that caught the fmt-0 count
    # corruption; a failed build must not reach a playtest
    python3 tools/verify_gfx_build.py "$OUTBASE"
fi

# MEMBER-IDENTITY AUDIT (14z-60z) — the LAST thing before fingerprinting,
# because it must see the whole set: the patched program members AND the
# patched vsav.zip the gfx stage writes above. Both emulators resolve a ROM
# entry by hash before name, so any member carrying the pristine bytes of a
# patched member silently reverts that patch at load time. The WIDE romset
# did exactly this for two sessions (merged group C was a byte copy of
# group B), shipping Donovan with vanilla tiles while every RAM gate stayed
# green. A build that fails this must never reach a playtest.
python3 tools/audit_romset_identity.py "$OUTBASE/rompath" || {
    echo "BUILD REJECTED: member-identity audit failed (above)." >&2
    echo "  A merged member shadows a patched one; the patch would revert" >&2
    echo "  silently at load. Do not playtest this build." >&2
    exit 1
}

# Fingerprint the SET WE PACKED. Omitting --set defaulted to vsavj, so a
# WIDE build (packed as vsavjw) found no vsavj.zip in its own rompath and
# silently fell through to the PRISTINE reference in $ROMDIR — reporting the
# untouched ROM's fingerprint as the build's. Caught 14z-59i.
python3 tools/build_fingerprint.py "$OUTBASE/rompath;$ROMDIR" --set "$PACK_SET" --sha-only \
    | sed 's/^/build fingerprint: /'
echo "OK: stage $STAGE build at $OUTBASE/rompath (fingerprint above; register in tests/expected/registry.tsv at freeze time)"
