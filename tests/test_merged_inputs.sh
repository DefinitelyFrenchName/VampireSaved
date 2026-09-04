#!/bin/sh
# test_merged_inputs.sh — ground truth for tools/ensure_merged_inputs.sh, the
# helper that makes rule 3 ONE COMMAND for the merged build (14z-95, GitHub
# #27, maintainer-ruled 2026-08-18: "it should be one command; the procedure
# should be considered only if a single command cannot work").
#
# THE QUESTION THIS GATE ANSWERS, and the one it deliberately does NOT.
# It does NOT assert that a regenerated extract dir is byte-equal to the
# pinned one. That is the wrong property and it is FALSE today: measured
# 14z-95, `build/m5_wide/extract/regions.json` predates two changes to
# extract_char.py — it carries `null` where the tool now writes `[]`, and it
# lacks one `values` row (`jump_params`) — while `build/hui32` and
# `build/pyron21` regenerate byte-identical. Asserting byte-equality would
# therefore red on a cosmetic staleness in a tracked file.
#
# The property rule 3 actually needs is that the ARTIFACT is reproducible, so
# this compares what the generator EMITS from either input set. Measured
# 14z-95: identical `patch.json` (752 ops, same order, sha1
# 6966e649e8536423038c3aab8d32b261ddcac47d), identical region blobs; the only
# difference anywhere is one extra documentation line in
# `patch_notes_fragment.md` ("# jump_params: velocity pair NOT ported"), which
# the fresher extract surfaces and which reaches no ROM byte.
#
# Sections:
#   1  --check reports without creating (and its verdict is not a lie)
#   2  a MISSING input is regenerated, and the regenerated one produces the
#      byte-identical merged patch  [the load-bearing one]
#   3  create-if-absent: an EXISTING input is never rewritten (the #26 rule)
#   4  verdict controls
#
# ROMDIR + the pinned build dirs. ~2 min (three extractions + two generator
# runs). Not portable: needs $ROMDIR.
#
# HANDOFF's review-triage table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (review-triage, #27) the merged build's four ROM-derived inputs are
#   PRODUCED, not demanded — and a regenerated set yields the identical merged
#   patch. Asserts the ARTIFACT is reproducible rather than that the input
#   dirs are byte-equal, because the latter is false and cosmetic:
#   `build/m5_wide/extract/regions.json` predates two `extract_char.py`
#   changes. **Not portable.**
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
export ROMDIR

D_EX="build/m5_wide/extract"
H_EX="build/hui32/extract"
P_EX="build/pyron21/extract"
WIDE_ZIP="build/wide0/rompath/vsavjw.zip"

for d in "$D_EX" "$H_EX" "$P_EX"; do
    [ -d "$d" ] || { echo "SKIP: $d absent — this gate measures the helper"
                     echo "      against the pinned inputs, so it needs them"; exit 0; }
done
[ -f "$WIDE_ZIP" ] || { echo "SKIP: $WIDE_ZIP absent"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
ok()  { echo "  ok: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

echo "== 1: --check reports, and creates nothing"
if out=$(tools/ensure_merged_inputs.sh --check 2>&1); then
    case "$out" in *"CHECK OK"*) ok "--check passes with every input present";;
                   *) bad "--check odd output: $out";; esac
else
    bad "--check failed with all inputs present: $out"
fi
case "$out" in
    *"regenerating"*|*"made:"*) bad "--check CREATED something — it must only report";;
    *) ok "--check created nothing";;
esac

echo "== 2: a regenerated extract produces the IDENTICAL merged patch"
# Regenerate each tenant's extract into a scratch tree, straight through the
# helper's own mechanism (build_donovan.sh EXTRACT_ONLY), then run the merged
# generator from the scratch set and from the pinned set and compare.
for row in m5_wide:0x13:donovan hui32:0x10:huitzil pyron21:0x11:pyron; do
    dir="${row%%:*}"; rest="${row#*:}"; ch="${rest%%:*}"; man="${rest#*:}"
    EXTRACT_ONLY=1 TENANT_CHAR="$ch" TENANT_MANIFEST="build/manifest/$man.toml" \
        GEN_FLAGS="--allow-plausible --tripwire-open --profile cps2-wide-v1" \
        tools/build_donovan.sh 6 "$W/$dir" >"$W/$dir.extract.log" 2>&1 || {
            bad "extraction failed for $man"; tail -5 "$W/$dir.extract.log"; }
done

gen() { # gen <D> <H> <P> <out>
    python3 tools/gen_donovan_patch.py "$1" "$4" --extract "$2" --extract "$3" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
        --port build/manifest/donovan.toml --port build/manifest/huitzil.toml \
        --port build/manifest/pyron.toml \
        --profile cps2-wide-v1 --allow-plausible --tripwire-open \
        > "$4.log" 2>&1
}
gen "$D_EX" "$H_EX" "$P_EX" "$W/g_pinned" || bad "generator failed on the pinned set"
gen "$W/m5_wide/extract" "$W/hui32/extract" "$W/pyron21/extract" "$W/g_regen" \
    || bad "generator failed on the regenerated set"

if cmp -s "$W/g_pinned/patch.json" "$W/g_regen/patch.json"; then
    n=$(python3 -c "import json;print(len(json.load(open('$W/g_pinned/patch.json'))['ops']))")
    ok "merged patch.json byte-identical from either input set ($n ops)"
else
    bad "merged patch.json DIFFERS between pinned and regenerated extracts"
    echo "     ^ this is a rule-6 finding, not a gate to relax: the merged"
    echo "       program fingerprint moves with it. Attribute before touching."
fi

# every region blob too — patch.json references them by name, so an identical
# patch over different blobs would still be a different ROM
blobdiff=$(diff -r --brief "$W/g_pinned" "$W/g_regen" 2>&1 \
           | grep -v 'patch_notes_fragment\.md' | grep -v '\.log' || true)
if [ -z "$blobdiff" ]; then
    ok "every emitted region blob identical (fragment excluded — see header)"
else
    bad "emitted files differ beyond the documented fragment:"; echo "$blobdiff"
fi

echo "== 2b: the WIDE overlay regenerates byte-identically"
# The other half of the input set, and the one that would otherwise be taken
# on faith. Every packed member of the merged artifact rides on this overlay,
# so a regenerated zip that differed anywhere would change the shipped ROM
# without changing a single op.
python3 tools/build_wide_romset.py "$ROMDIR" "$W/wide/rompath" \
    --qsound 2 --gfx 4 --prg 4 >"$W/wide.log" 2>&1 \
    || bad "build_wide_romset failed"
if [ -f "$W/wide/rompath/vsavjw.zip" ]; then
    python3 tests/lib/cmp_zip_members.py \
        "$WIDE_ZIP" "$W/wide/rompath/vsavjw.zip" \
        && ok "WIDE overlay regenerates byte-identical" \
        || bad "WIDE overlay members differ from the pinned build/wide0"
else
    bad "build_wide_romset produced no vsavjw.zip"
fi

echo "== 3: create-if-absent — an existing input is never rewritten (#26)"
before=$(find "$H_EX" -type f -exec shasum {} \; | shasum | cut -d' ' -f1)
tools/ensure_merged_inputs.sh >"$W/ensure.log" 2>&1 \
    || bad "helper failed with all inputs present"
after=$(find "$H_EX" -type f -exec shasum {} \; | shasum | cut -d' ' -f1)
[ "$before" = "$after" ] && ok "existing extract untouched by a full run" \
    || bad "the helper REWROTE $H_EX — create-if-absent is violated"
grep -q "present, untouched" "$W/ensure.log" \
    && ok "helper reports the existing inputs as untouched" \
    || bad "helper did not report the present inputs"

echo "== 4: verdict controls"
# (a) a missing extract must be REPORTED by --check, not passed over
CTL="$W/ctl"; mkdir -p "$CTL"
if (cd "$CTL" && WIDE_ZIP=nope.zip ROMDIR="$ROMDIR" \
        "$REPO/tools/ensure_merged_inputs.sh" --check >"$W/ctl.log" 2>&1); then
    bad "control (a): --check passed from a tree with no inputs"
else
    grep -q "MISSING" "$W/ctl.log" \
        && ok "control (a): --check names the missing inputs and fails" \
        || bad "control (a): failed without naming what is missing"
fi
# (b) a caller-supplied overlay path is NOT ours to regenerate
if WIDE_ZIP="$W/somebody_elses.zip" tools/ensure_merged_inputs.sh \
        >"$W/ctl2.log" 2>&1; then
    bad "control (b): produced a caller-supplied overlay path"
else
    grep -q "caller-supplied path" "$W/ctl2.log" \
        && ok "control (b): refuses to regenerate a path it does not own" \
        || { bad "control (b): wrong refusal reason"; tail -3 "$W/ctl2.log"; }
fi
# (c) the helper must actually be REACHED by the builder, or none of this
#     applies to the artifact that ships
grep -q "ensure_merged_inputs.sh" tools/build_merged.sh \
    && ok "control (c): tools/build_merged.sh calls the helper" \
    || bad "control (c): build_merged.sh no longer calls the helper"
grep -q "ensure_merged_inputs.sh" tests/audit_merged_legacy.sh \
    && ok "control (c): tests/audit_merged_legacy.sh calls the helper" \
    || bad "control (c): audit_merged_legacy.sh no longer calls the helper"

[ "$fail" = 0 ] && echo "PASS: the merged build's inputs are reproducible (rule 3, one command)" \
    || { echo "FAIL: merged inputs"; exit 1; }
