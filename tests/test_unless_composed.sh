#!/bin/sh
# test_unless_composed.sh — THE `unless_composed` ROW KEY (14z-170): a manifest row naming a tenant applies only to a build whose composition does NOT include that tenant; a name outside the port's roster fails the build; and the only rows carrying the key are Phobos's two Plasma Trap class remaps.
#
# MUST-FIRE: perturbed-copy: typo-accepted — the refusal case run against a vocabulary that already contains the misspelt name must stop refusing, so the refusal is a reading of the vocabulary and not a constant (in-gate: the perturbed vocabulary must accept the typo; mode: the gate's vocabulary is perturbed and the refusal check FAILs)
#
# WHY. The class-0x52 fix is scoped S1 (maintainer-ruled 2026-09-18, DECISIONS_HISTORY.md
# "Ruled 2026-09-18 (14z-169) — the class-0x52 fix is scoped to the tracks that carry its
# machinery"): Phobos's two trap remaps (hitbox_proj +0x17D/+0x19D, 0x52 -> 0x06) stay on a
# build composed WITHOUT Donovan — the solo Phobos track, which lacks the reaction_hook /
# es_type51_dispatch / ls_freeze machinery a native class-0x52 record needs — and drop where
# donovan.toml is composed (the merged build). tools/gen_donovan_patch.py honours the key in
# tenant_rows(), the one funnel every list-row read passes through (composition_allows()), with
# the vocabulary DERIVED from the manifests' own [[tenant]] names (port_tenant_names()).
# A misspelt name would match no composition and leave the row applying everywhere, silently —
# hence the refusal, and this gate's control on it.
#
# WHAT IT CHECKS (no ROM, no build, no emulator):
#   1. the vocabulary: port_tenant_names(build/manifest) is exactly the three tenants the tenant
#      manifests declare;
#   2. the semantics over a truth table (no key; named tenant present / absent; a list; spaces);
#   3. the refusal: an unknown name and an empty list raise;
#   4. the real rows: across build/manifest/*.toml the key appears on exactly Phobos's two trap
#      remaps, each naming "donovan" — and they apply to the solo composition, not the merged one.
# NOT COVERED: that the built images carry the result — tests/test_m3a_reproducible.sh rebuilds
# the four tracks (the solo Phobos image keeps the remaps, the merged one does not), and
# tests/audit_trap_shock.sh measures the trap on both.
#
# Usage: tests/test_unless_composed.sh    (ci_portable, ~1 s)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"; MODE="${VS_CTL:-}"

rc=0
python3 - "$MODE" <<'PY' || rc=$?
import sys
sys.path.insert(0, "tools")
from pathlib import Path
from gen_donovan_patch import port_tenant_names, composition_allows, toml_loads
MODE = sys.argv[1]
bad = 0
def chk(c, m):
    global bad
    print(("  ok    " if c else "  FAIL  ") + m); bad |= not c

def refuses(row, composed, known):
    try:
        composition_allows(row, composed, known)
    except SystemExit:
        return True
    return False

def vocabulary(typo):
    """THE PERTURBATION (one function, the in-gate control and the mode both call it): the
    derived vocabulary, with the misspelt name added when perturbed."""
    known = set(port_tenant_names("build/manifest"))
    return frozenset(known | ({typo} if typo else set()))

TYPO = "donavan"
known = vocabulary(TYPO if MODE == "typo-accepted" else None)
print("== 1. the vocabulary")
real = port_tenant_names("build/manifest")
decl = set()
for t in ("donovan", "huitzil", "pyron"):
    for row in toml_loads(Path(f"build/manifest/{t}.toml").read_text()).get("tenant", []):
        decl.add(row["name"])
chk(set(real) == decl == {"donovan", "huitzil", "pyron"},
    f"port_tenant_names = {sorted(real)} = the three tenant manifests' own [[tenant]] names")

print("== 2. the semantics")
ALL = ["donovan", "huitzil", "pyron"]
cases = [
    ({}, ALL, True, "no key -> applies"),
    ({"unless_composed": "donovan"}, ALL, False, "named tenant composed (merged) -> dropped"),
    ({"unless_composed": "donovan"}, ["huitzil"], True, "named tenant absent (solo Phobos) -> applies"),
    ({"unless_composed": "donovan"}, ["donovan"], False, "named tenant alone (solo Donovan) -> dropped"),
    ({"unless_composed": "donovan,pyron"}, ["pyron"], False, "a list: any one composed -> dropped"),
    ({"unless_composed": " donovan , pyron "}, ["huitzil"], True, "a list with spaces, none composed -> applies"),
    ({"unless_composed": "donovan"}, [], True, "a legacy [port]-only build (no tenants) -> applies"),
]
for row, comp, want, what in cases:
    got = composition_allows(row, comp, real)
    chk(got is want, f"{what}: {got}")

print("== 3. the refusal")
r_typo = refuses({"unless_composed": TYPO}, ALL, known)
chk(r_typo, f"an unknown name ({TYPO!r}) raises")
chk(refuses({"unless_composed": " , "}, ALL, real), "an empty name list raises")
# the in-gate control: the same refusal case against the perturbed vocabulary must NOT raise
if MODE != "typo-accepted":
    if not refuses({"unless_composed": TYPO}, ALL, vocabulary(TYPO)):
        print(f"CONTROL FIRED: typo-accepted — with {TYPO!r} in the vocabulary the same row is accepted, so the refusal reads the vocabulary")
    else:
        print("CONTROL DEAD: typo-accepted — the row is refused even when the vocabulary holds the name")
        bad = 1

print("== 4. the rows that carry the key")
carriers = []
for p in sorted(Path("build/manifest").glob("*.toml")):
    if p.name.startswith("probe_"):
        continue
    for ln, line in enumerate(p.read_text().splitlines(), 1):
        if line.split("#", 1)[0].strip().startswith("unless_composed"):
            carriers.append((p.name, ln))
chk([c[0] for c in carriers] == ["huitzil.toml", "huitzil.toml"],
    f"exactly two lines carry the key, both in huitzil.toml: {carriers}")
hui = toml_loads(Path("build/manifest/huitzil.toml").read_text())
rows = [r for sec in hui.values() if isinstance(sec, list) for r in sec
        if isinstance(r, dict) and "unless_composed" in r]
shape = sorted((r.get("region"), r.get("off"), r.get("old_hex"), r.get("new_hex"), r["unless_composed"]) for r in rows)
chk(shape == [("hitbox_proj", 0x17D, "52", "06", "donovan"), ("hitbox_proj", 0x19D, "52", "06", "donovan")],
    f"they are the two trap remaps (hitbox_proj +0x17D/+0x19D, 52 -> 06), naming donovan: {shape}")
chk(all(composition_allows(r, ["huitzil"], real) and not composition_allows(r, ALL, real) for r in rows),
    "each applies to the solo Phobos composition and not to the merged one")
sys.exit(1 if bad else 0)
PY
[ "$rc" = 0 ] && echo "PASS: test_unless_composed — the key drops a row where a named tenant is composed, refuses an unknown name, and sits on exactly the two trap remaps" && exit 0
echo "FAIL: test_unless_composed"; exit 1
