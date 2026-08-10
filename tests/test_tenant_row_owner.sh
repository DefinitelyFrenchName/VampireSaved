#!/bin/sh
# test_tenant_row_owner.sh — the row-OWNER threading is LIVE, not decoration.
#
# WHY (M3b slices C and D, 14z-77). The multi-tenant refactor replaces "is
# THE tenant a variant id?" (one global scalar) with "is THIS ROW's owning
# tenant a variant id?" at every gate, and the same substitution at every
# manifest-row table address. Each slice is INERT by design — the four frozen
# fingerprints are unchanged — and that is exactly the problem: a threading
# that were accidentally disconnected from the emitted ops would ALSO leave
# the fingerprints unchanged, and would look like a successful slice.
#
# `tests/test_m3a_reproducible.sh` proves the values did not move. This gate
# proves the code path is LOAD-BEARING, which no fingerprint can: it perturbs
# ONE owner-derived row at a time and requires the generator's op list to
# change. A site whose perturbation leaves patch.json identical is dead code.
#
# The instrument is the GENERATOR ALONE against an existing extract dir, so
# each control costs seconds rather than the ~4 minutes of a full four-target
# rebuild. That is what makes per-site controls affordable at all.
#
# Ground truth for the checks themselves: section 0 requires the UNPERTURBED
# run to reproduce the baseline op list exactly, so a control that "changes
# the ops" because the generator is nondeterministic cannot pass silently.
#
# Usage: ROMDIR=... tests/test_tenant_row_owner.sh [extract_dir]
#   extract_dir defaults to build/m5_wide/extract (Donovan, the WIDE
#   reference). SKIPs when no extract dir is present — the build dirs are
#   untracked, so a fresh checkout has none.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"

EXTRACT="${1:-build/m5_wide/extract}"
if [ ! -d "$EXTRACT" ]; then
    echo "SKIP: no extract dir at $EXTRACT (build dirs are untracked)."
    echo "      Make one with:  GEN_FLAGS=\"--allow-plausible --tripwire-open\" \\"
    echo "                      tools/build_donovan.sh 6 build/m5_stock"
    exit 0
fi

# This gate PERTURBS tools/gen_donovan_patch.py in place, so restoring it is
# the trap's FIRST act and section 3 asserts it independently. An interrupted
# run must not leave the generator edited.
WORK="$(mktemp -d)"
cp tools/gen_donovan_patch.py "$WORK.gen"
trap 'cp "$WORK.gen" tools/gen_donovan_patch.py 2>/dev/null || true; rm -rf "$WORK" "$WORK.gen"' EXIT INT TERM
restore() { cp "$WORK.gen" tools/gen_donovan_patch.py; }

gen() {  # gen <outdir> -> generator run, exit code swallowed (fails are data)
    python3 tools/gen_donovan_patch.py "$EXTRACT" "$1" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
        --port build/manifest/donovan.toml --profile cps2-wide-v1 \
        --allow-plausible --tripwire-open > "$1.log" 2>&1 || true
}

fail=0

echo "== 0: baseline op list (the instrument's own ground truth) =="
gen "$WORK/base"
if [ ! -f "$WORK/base/patch.json" ]; then
    echo "  FAIL: baseline generation produced no patch.json"
    tail -5 "$WORK/base.log"
    exit 1
fi
BASE_OPS="$(python3 -c "import json;d=json.load(open('$WORK/base/patch.json'));print(len(d['ops'] if isinstance(d,dict) else d))")"
gen "$WORK/base2"
if cmp -s "$WORK/base/patch.json" "$WORK/base2/patch.json"; then
    echo "  ok: generator is deterministic; baseline carries $BASE_OPS ops"
else
    echo "  FAIL: two identical runs disagree — every control below would be"
    echo "        measuring generator noise, not the threading"
    exit 1
fi

# Each control names ONE owner-derived binding and perturbs it. The row it
# produces must reach the emitted ops; if it does not, the substitution that
# slice C/D made at that site is decoration.
control() {  # control <label> <anchor> <replacement>
    python3 - "$2" "$3" <<'PY' || { echo "  FAIL: anchor not found (site moved?)"; return 1; }
import sys, pathlib
p = pathlib.Path("tools/gen_donovan_patch.py")
s = p.read_text(); a, b = sys.argv[1], sys.argv[2]
if s.count(a) != 1:
    sys.exit("anchor appears %d times" % s.count(a))
p.write_text(s.replace(a, b))
PY
    rm -rf "$WORK/ctl" "$WORK/ctl.log"
    gen "$WORK/ctl"
    restore
    if [ ! -f "$WORK/ctl/patch.json" ]; then
        # generation refused: the perturbed row broke a vanilla-anchor
        # assertion. That IS the site proving itself live.
        echo "  ok (live): $1 — generation REFUSED under the perturbation"
        return 0
    fi
    if cmp -s "$WORK/base/patch.json" "$WORK/ctl/patch.json"; then
        echo "  FAIL: $1 — ops IDENTICAL under the perturbation; this site's"
        echo "        owner threading does not reach the emitted patch"
        return 1
    fi
    n="$(python3 -c "
import json
a=json.load(open('$WORK/base/patch.json')); b=json.load(open('$WORK/ctl/patch.json'))
oa=a['ops'] if isinstance(a,dict) else a; ob=b['ops'] if isinstance(b,dict) else b
print('%d -> %d ops' % (len(oa), len(ob)))")"
    echo "  ok (live): $1 — $n"
}

echo "== 1: per-site liveness (one owner-derived row perturbed at a time) =="
control "palette table row (slice D)" \
    '            prow, _pvar, _pmir = row_ident(owner_of(pal))' \
    '            prow, _pvar, _pmir = row_ident(owner_of(pal)); prow ^= 1' || fail=1
control "select_records array row (slice D)" \
    '            _srow = _int(_sown["dst_slot"])' \
    '            _srow = _int(_sown["dst_slot"]) ^ 1' || fail=1
control "data_port slot_ptr_table row (slice D)" \
    '                _orow = _int(_own["dst_slot"])' \
    '                _orow = _int(_own["dst_slot"]) ^ 1' || fail=1
control "sound_table ptr_row (slice D)" \
    '            ptr_row = _int(owner_of(st)["dst_slot"])   # slice D: the OWNER'"'"'s' \
    '            ptr_row = _int(owner_of(st)["dst_slot"]) ^ 1' || fail=1
control "code_word slot_table row (slice D)" \
    '                _crow, _cvar, _cmir = row_ident(owner_of(cw))' \
    '                _crow, _cvar, _cmir = row_ident(owner_of(cw)); _crow ^= 1' || fail=1
control "select_wheel tenant-cell set (slice D)" \
    '    _tenant_cells = {_int(t["dst_slot"]) for t in (port.get("_tenants") or [T])}' \
    '    _tenant_cells = set()' || fail=1
control "the gating family's owner (slice C)" \
    '        return row_owner(row, port.get("_tenants") or [], T)' \
    '        return dict(row_owner(row, port.get("_tenants") or [], T), dst_slot=0x0E)' || fail=1

# ── the checker's own ground truth ──────────────────────────────────────
# Every verdict above is "the ops CHANGED, so the site is live". That verdict
# is only worth anything if the checker can also say "the ops did NOT change".
# `_pvar` is bound at the palette site and genuinely unused, so perturbing it
# is a real edit to a real line that cannot reach the emitted patch — the
# checker MUST call it dead. Without this, a checker that reported "live"
# unconditionally would pass every case above (CLAUDE.md §4: verdict logic is
# itself tested; SMS shipped a wrong conclusion from a verdict bug once).
echo "== 2: negative control — an UNUSED binding must be called DEAD =="
python3 - <<'PY'
import pathlib
p = pathlib.Path("tools/gen_donovan_patch.py"); s = p.read_text()
a = '            prow, _pvar, _pmir = row_ident(owner_of(pal))'
assert s.count(a) == 1
p.write_text(s.replace(a, a + '; _pvar ^= 1'))
PY
rm -rf "$WORK/dead"
gen "$WORK/dead"
restore
if [ -f "$WORK/dead/patch.json" ] && cmp -s "$WORK/base/patch.json" "$WORK/dead/patch.json"; then
    echo "  ok: perturbing the unused _pvar leaves the ops identical, and the"
    echo "      comparison the section-1 verdicts rest on detects that"
else
    echo "  FAIL: perturbing an UNUSED binding changed the ops (or the run"
    echo "        errored) — section 1's 'live' verdicts are not trustworthy"
    fail=1
fi

echo "== 3: the tree is restored =="
if cmp -s "$WORK.gen" tools/gen_donovan_patch.py; then
    echo "  ok: tools/gen_donovan_patch.py is byte-identical to the start"
else
    echo "  FAIL: the generator was left perturbed — restore it from git"
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: row-owner threading gate"; exit 1; }
echo "PASS: every owner-derived row reaches the emitted ops (7 sites), an"
echo "      unused binding is correctly called dead, the generator is
      deterministic, and the tree is restored"
