#!/bin/sh
# test_rule5_census.sh — the rule-5 census is complete, classified and frozen
# (14z-141, living-docs slice L2).
# ci_portable: no ROM, no build dir, no emulator, ~6 s (measured).
#
# MUST-FIRE: perturbed-copy: new-kind-key — a manifest copy with a (kind, key) pair the census has never classified must fail --check as UNCLASSIFIED
# MUST-FIRE: perturbed-copy: aux-poke-no-band — an aux_poke outside every declared band must fail --check
# MUST-FIRE: perturbed-copy: new-baked-value — a NEW baked gameplay value must fail --check (the inventory can only shrink)
# MUST-FIRE: perturbed-copy: edited-inventory — the frozen inventory with its last row deleted must fail --check (it is not hand-editable)
#
# WHAT IT HOLDS. CLAUDE.md rule 5 says behavioural values live in documented
# tables, not in code. `tools/audit_rule5.py` measures how far that holds over
# the canonical manifests and the generators. This gate asserts that the
# census still runs clean (nothing UNCLASSIFIED), that the frozen BAKED
# inventory has not GROWN, and that each of the tool's tripwires still fires.
#
# WHY THE INVENTORY IS GAMEPLAY+CODE ONLY. Freezing `fact` as well made the
# file 8,059 rows of addresses and hex, which ordinary port work adds to on
# every session — the gate would fail on routine edits and be answered by a
# reflexive re-freeze, and a shrink-only signal that fires every commit is not
# a signal. `fact` is reported as a NOTE-class number instead.
#
# WHY IN-TABLE IS POINTER-DRIVEN. A value-matching pass reported 19 gameplay
# rows IN-TABLE and all nineteen were false positives (key `R` matches any row
# containing an `r`). A value counts as documented only when the manifest
# SAYS which table documents it and that table really carries the value.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
TOOL=tools/audit_rule5.py
FROZEN=tests/expected/rule5_baked.tsv

echo "== test_rule5_census: the rule-5 census is classified and frozen =="
[ -f "$TOOL" ]   || { echo "FAIL: $TOOL is absent"; exit 1; }
[ -f "$FROZEN" ] || { echo "FAIL: $FROZEN is absent — run --freeze"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

# The copy lives outside the repo on purpose: `git ls-files` inside the tree
# would list the REAL canon and the perturbation would never be scanned.
# build/ is 4.2 GB of build directories and the census reads exactly one
# subdirectory of it. Copy that, never the parent.
mkcopy() { rm -rf "$1"; mkdir -p "$1/build"
           cp -R build/manifest "$1/build/"; cp -R docs tools "$1/"; }
perturb() {  # perturb <name> <copy dir>; EXPECT = the failure's substring
    case "$1" in
    new-kind-key)     printf '\n[[data_port]]\ndamage = 12\n' >> "$2/build/manifest/donovan.toml"; EXPECT="NEW (kind, key) pair" ;;
    aux-poke-no-band) printf '\n[[aux_poke]]\nname = "x"\naddr = 0x123456\nop = "poke16"\nval = 0x1\n' >> "$2/build/manifest/donovan.toml"; EXPECT="no declared band" ;;
    new-baked-value)  printf '\n[[site_thunk]]\nname = "z"\nonly_variant_slot = true\n' >> "$2/build/manifest/donovan.toml"; EXPECT="NEW baked value" ;;
    esac
}
# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS what the
# main --check reads (or the perturbed inventory is) — and this run must FAIL.
ROOT_ARGS=""
case "$VS_CTL" in
"") ;;
edited-inventory) cp "$FROZEN" "$W/mode.tsv"; sed -i '' '$d' "$W/mode.tsv" 2>/dev/null || sed -i '$d' "$W/mode.tsv"; FROZEN="$W/mode.tsv" ;;
*) mkcopy "$W/mode"; perturb "$VS_CTL" "$W/mode"; ROOT_ARGS="--root $W/mode" ;;
esac

# --- 1. the tool's own ground truth ----------------------------------------
if python3 "$TOOL" --selftest > "$W/self.log" 2>&1; then
    ok "selftest: $(grep -c '^  ok' "$W/self.log") checks pass"
else
    bad "the tool's selftest FAILS:"; sed 's/^/        /' "$W/self.log" | head -12
fi

# --- 2. the census runs clean over the tree --------------------------------
if python3 "$TOOL" $ROOT_ARGS --check "$FROZEN" > "$W/check.log" 2>&1; then
    ok "the census matches the frozen inventory: $(tail -1 "$W/check.log" | sed 's/^ok *//')"
else
    bad "the census does not match the frozen inventory:"
    sed 's/^/        /' "$W/check.log" | head -12
fi

# --- 3. the NOTE-class numbers are printed ---------------------------------
python3 "$TOOL" --report > "$W/report.log" 2>&1
n_note=$(grep -c '^NOTE: rule5\.' "$W/report.log")
if [ "$n_note" = 3 ]; then
    ok "the census reports three NOTE-class numbers"
else
    bad "expected 3 NOTE lines, got $n_note"
fi
# and EMIT them at column 0, which is what run_all_static.sh's advisory block
# greps for. Printing them only inside this gate's own indented output is how
# the mechanism ends up decorative: the first real tier run after the block
# landed reported "(none)" while this gate was passing.
grep '^NOTE: rule5\.' "$W/report.log"

# --- 4. MUST-FIRE controls, each on a COPY of the tree ---------------------
control() {  # control <name>
    mkcopy "$W/c"; perturb "$1" "$W/c"
    if python3 "$TOOL" --root "$W/c" --check "$FROZEN" > "$W/c.log" 2>&1; then
        vs_ctl_dead "$1" "the census ACCEPTED it — the check is not checking"; bad "$1"
    elif grep -q "$EXPECT" "$W/c.log"; then
        vs_ctl_fired "$1" "$EXPECT"; ok "$1: fires"
    else
        vs_ctl_dead "$1" "failed for the wrong reason"; bad "$1:"; sed 's/^/        /' "$W/c.log" | head -4
    fi
}
control new-kind-key
control aux-poke-no-band
control new-baked-value

# a probe_*.toml is UNTRACKED and must never reach the census
mkcopy "$W/c"; printf '[[data_port]]\ndamage = 99\n' > "$W/c/build/manifest/probe_zz.toml"
if python3 "$TOOL" --root "$W/c" --check "$FROZEN" > "$W/c.log" 2>&1; then
    ok "a probe_*.toml in the copy is ignored (no-fire: the canon is git-tracked)"
else
    bad "a probe manifest reached the census:"; sed 's/^/        /' "$W/c.log" | head -4
fi

# --- 5. growth is refused without a stated reason --------------------------
mkcopy "$W/c"; printf '\n[[site_thunk]]\nname = "z"\nonly_variant_slot = true\n' \
    >> "$W/c/build/manifest/donovan.toml"
cp "$FROZEN" "$W/grow.tsv"
if python3 "$TOOL" --root "$W/c" --freeze "$W/grow.tsv" > "$W/grow.log" 2>&1; then
    bad "--freeze GREW the inventory with no --allow-growth"
elif grep -q "would GROW" "$W/grow.log"; then
    ok "growth refused without --allow-growth"
else
    bad "--freeze failed for the wrong reason:"; sed 's/^/        /' "$W/grow.log" | head -4
fi
if python3 "$TOOL" --root "$W/c" --freeze "$W/grow.tsv" \
        --allow-growth "gate control" > "$W/grow2.log" 2>&1; then
    ok "growth allowed when a reason is given, and the reason is written in"
    grep -q "growth allowed: gate control" "$W/grow.tsv" || \
        bad "the reason was not recorded in the frozen file"
else
    bad "--allow-growth did not write:"; sed 's/^/        /' "$W/grow2.log" | head -4
fi

# --- 6. the frozen file is not hand-editable -------------------------------
cp "$FROZEN" "$W/drift.tsv"
sed -i '' '$d' "$W/drift.tsv" 2>/dev/null || sed -i '$d' "$W/drift.tsv"
if python3 "$TOOL" --check "$W/drift.tsv" > "$W/drift.log" 2>&1; then
    vs_ctl_dead edited-inventory "an edited inventory was ACCEPTED"; bad "edited-inventory"
else
    vs_ctl_fired edited-inventory "an edited inventory is caught ($(head -1 "$W/drift.log" | cut -c1-56))"; ok "edited-inventory: fires"
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
