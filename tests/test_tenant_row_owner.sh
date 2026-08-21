#!/bin/sh
# test_tenant_row_owner.sh — the row-OWNER threading is LIVE, not decoration.
#
# WHY (M3b slices C, D and E, 14z-77). The multi-tenant refactor replaces "is
# THE tenant a variant id?" (one global scalar) with "is THIS ROW's owning
# tenant a variant id?" at every gate, and the same substitution at every
# manifest-row table address and every id baked into emitted 68k. Each slice
# is INERT by design — the four frozen fingerprints are unchanged — and that
# is exactly the problem: a threading accidentally DISCONNECTED from the
# emitted output would ALSO leave the fingerprints unchanged, and would read
# as a successful slice.
#
# `tests/test_m3a_reproducible.sh` proves the values did not move. This gate
# proves the code path is LOAD-BEARING, which no fingerprint can: it perturbs
# ONE owner-derived binding at a time and requires the generator's OUTPUT to
# change. A site whose perturbation changes nothing is dead code.
#
# THE COMPARISON IS THE WHOLE OUTPUT DIRECTORY, not patch.json. Region blobs
# leave as side .bin files referenced by data_file/code_file ops, so a byte
# changed inside a blob moves no op at all. The first version of this gate
# compared patch.json alone and called the charid_sites threading DEAD when it
# is live — caught by this file's own controls, which is the argument for
# having them (CLAUDE.md §4: verdict logic is itself tested).
#
# The instrument is the GENERATOR ALONE against an existing extract dir, so
# each control costs seconds rather than the ~4 minutes of a full four-target
# rebuild. That is what makes per-site controls affordable at all.
#
# Ground truth for the checks themselves: section 0 requires two UNPERTURBED
# runs to agree byte-for-byte, so a control that "changed the output" because
# the generator is nondeterministic cannot pass silently; and section 2
# requires an intentionally UNUSED binding to be called DEAD, so a checker
# that always said "live" cannot pass either.
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
    echo "                      tools/build_donovan.sh 6 build/m5_stock5"
    exit 0
fi

# This gate PERTURBS the generator to prove a substitution site is live. It
# does so on a SHADOW COPY, never on tracked source (14z-94, GitHub #81): an
# exit trap covers an ordinary Ctrl-C and nothing else — not SIGKILL, not two
# runs sharing a checkout, not a legitimate edit saved during a long run, all
# of which previously ended with tools/gen_donovan_patch.py either perturbed
# or silently reverted. See tests/lib/shadow_tools.sh for why the shadow is a
# repo ROOT and not just a copy of the file.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM
. "$REPO/tests/lib/shadow_tools.sh"
GEN="$(shadow_tool "$WORK" gen_donovan_patch.py)"; export GEN
restore() { shadow_restore "$WORK" gen_donovan_patch.py; }

gen() {  # gen <outdir> -> generator run, exit code swallowed (fails are data)
    python3 "$GEN" "$EXTRACT" "$1" \
        --vsavj "$ROMDIR/vsavj.zip" --stage 6 \
        --port build/manifest/donovan.toml --profile cps2-wide-v1 \
        --allow-plausible --tripwire-open > "$1.log" 2>&1 || true
    # THE WHOLE OUTPUT DIRECTORY IS THE COMPARISON, not patch.json alone.
    # Region blobs leave as side .bin files referenced by data_file/code_file
    # ops, so a byte changed INSIDE a blob (charid_sites is exactly that
    # shape) moves no op at all. An early version of this gate compared only
    # patch.json and reported the charid_sites threading DEAD when it is
    # live — the blind spot was caught by this file's own controls, which is
    # the argument for having them.
    ( cd "$1" 2>/dev/null && find . -type f ! -name '*.log' | sort \
        | xargs shasum 2>/dev/null ) > "$1.sums" || true
}

fail=0

echo "== 0: baseline output (the instrument's own ground truth) =="
gen "$WORK/base"
if [ ! -f "$WORK/base/patch.json" ]; then
    echo "  FAIL: baseline generation produced no patch.json"
    tail -5 "$WORK/base.log"
    exit 1
fi
BASE_OPS="$(python3 -c "import json;d=json.load(open('$WORK/base/patch.json'));print(len(d['ops'] if isinstance(d,dict) else d))")"
gen "$WORK/base2"
if cmp -s "$WORK/base.sums" "$WORK/base2.sums"; then
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
import os, sys, pathlib
p = pathlib.Path(os.environ["GEN"])
s = p.read_text(); a, b = sys.argv[1], sys.argv[2]
if s.count(a) != 1:
    sys.exit("anchor appears %d times" % s.count(a))
p.write_text(s.replace(a, b))
PY
    rm -rf "$WORK/ctl" "$WORK/ctl.log" "$WORK/ctl.sums"
    gen "$WORK/ctl"
    restore
    if [ ! -f "$WORK/ctl/patch.json" ]; then
        # generation refused: the perturbed row broke a vanilla-anchor
        # assertion. That IS the site proving itself live.
        echo "  ok (live): $1 — generation REFUSED under the perturbation"
        return 0
    fi
    if cmp -s "$WORK/base.sums" "$WORK/ctl.sums"; then
        echo "  FAIL: $1 — the ENTIRE generator output is byte-identical under"
        echo "        the perturbation; this site's owner threading reaches"
        echo "        nothing that ships"
        return 1
    fi
    echo "  ok (live): $1 — $(diff "$WORK/base.sums" "$WORK/ctl.sums" \
        | grep -c '^[<>]') output file(s) changed$(python3 -c "
import json,os
try:
    a=json.load(open('$WORK/base/patch.json')); b=json.load(open('$WORK/ctl/patch.json'))
    oa=a['ops'] if isinstance(a,dict) else a; ob=b['ops'] if isinstance(b,dict) else b
    print(', %d -> %d ops' % (len(oa), len(ob)))
except Exception: print('')")"
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

# The BAKED-CODE class (slice E). These bake an id into emitted 68k, so a
# wrong tenant here produces a build that passes every structural check and
# is wrong in the ROM — the reason the class was held to last. Liveness is
# the only cheap check that exists for them.
control "charid_sites immediate (slice E)" \
    '            _cid = _int(T["dst_slot"])' \
    '            _cid = _int(T["dst_slot"]) ^ 1' || fail=1
control "win-pal thunk compare+rebase (slice E)" \
    '                _wrow = _int(owner_of(wp)["dst_slot"])' \
    '                _wrow = _int(owner_of(wp)["dst_slot"]) ^ 1' || fail=1
control "site_thunk TT/TU + row_subst (slice E)" \
    '            _tid = _int(owner_of(st)["dst_slot"]) & 0xFF' \
    '            _tid = (_int(owner_of(st)["dst_slot"]) & 0xFF) ^ 1' || fail=1

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
import os, pathlib
p = pathlib.Path(os.environ["GEN"]); s = p.read_text()
a = '            prow, _pvar, _pmir = row_ident(owner_of(pal))'
assert s.count(a) == 1
p.write_text(s.replace(a, a + '; _pvar ^= 1'))
PY
rm -rf "$WORK/dead" "$WORK/dead.sums"
gen "$WORK/dead"
restore
if [ -f "$WORK/dead/patch.json" ] && cmp -s "$WORK/base.sums" "$WORK/dead.sums"; then
    echo "  ok: perturbing the unused _pvar leaves the whole output identical,"
    echo "      and the comparison the section-1 verdicts rest on detects that"
else
    echo "  FAIL: perturbing an UNUSED binding changed the output (or the run"
    echo "        errored) — section 1's 'live' verdicts are not trustworthy"
    fail=1
fi

echo "== 3: TRACKED SOURCE WAS NEVER WRITTEN =="
# Stronger than the old check, which compared against a snapshot taken by
# THIS run: that passes even when a concurrent run has clobbered the file,
# and it passes on a restore that silently reverted someone's real edit.
# Asking git makes the claim absolute.
if git -C "$REPO" diff --quiet -- tools/gen_donovan_patch.py 2>/dev/null; then
    echo "  ok: tools/gen_donovan_patch.py is unmodified against git"
elif ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "  note: not a git checkout — cannot assert tracked-source integrity"
else
    echo "  FAIL: tools/gen_donovan_patch.py differs from git. This gate no"
    echo "        longer writes it, so either something else did, or a"
    echo "        perturbation escaped the shadow copy:"
    git -C "$REPO" diff --stat -- tools/gen_donovan_patch.py | sed 's/^/        /'
    fail=1
fi

[ "$fail" = 0 ] || { echo "FAIL: row-owner threading gate"; exit 1; }
echo "PASS: every owner-derived row reaches the emitted output (10 sites), an"
echo "      unused binding is correctly called dead, the generator is
      deterministic, and the tree is restored"
