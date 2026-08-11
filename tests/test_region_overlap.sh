#!/bin/sh
# test_region_overlap.sh — freeze what the three tenants' regions do together.
#
# WHY (M3b, 14z-77). M3b_plan Phase 2 item 2 assumes "a shared span is placed
# ONCE and all tenants' relocations resolve through the shared placement".
# This gate freezes the measurement that decides whether that is achievable,
# so the region-identity slice is designed on data instead of on the plan's
# assumption — and so a manifest or extraction change that alters the picture
# fails here, in seconds, instead of inside the merge.
#
# MEASURED, and it CORRECTS the plan: 17 shared spans, but 2,000 bytes across
# four of them are written DIFFERENTLY BY TWO OR MORE TENANTS. Those spans
# cannot be placed once by dedup — only one value can ship — so the merge
# needs a per-tenant copy or a per-character indirection at each such field.
#
# Section 2 is the control that makes the 2,000 trustworthy: without
# placement normalisation the same measurement reports 7,591, so 74% of the
# raw figure is an artefact of comparing three INDEPENDENT builds whose
# allocators chose different addresses. A gate quoting the raw number would
# be confidently wrong.
#
# Usage: tests/test_region_overlap.sh [build...]   (defaults to the frozen 3)
# Static, no ROMs, no emulator. ~40s (the normalisation scans every blob).
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILDS="${*:-build/m5_wide build/hui27 build/pyron20}"
for b in $BUILDS; do
    if [ ! -f "$b/patch/placements.json" ]; then
        echo "SKIP: $b has no patch/placements.json (build dirs are untracked)"
        exit 0
    fi
done

python3 - $BUILDS <<'PY'
import json, subprocess, sys
def run(extra):
    out = subprocess.run([sys.executable, "tools/audit_region_overlap.py",
                          *sys.argv[1:], "--json", *extra],
                         capture_output=True, text=True)
    if out.returncode != 0:
        print("  FAIL: audit tool errored\n" + out.stderr); sys.exit(1)
    return json.loads(out.stdout)

bad = []
def eq(what, got, want):
    if got != want: bad.append("%s: got %r, expected %r" % (what, got, want))

d = run([])
print("== 1: the three span classes are frozen ==")
eq("shared spans", len(d["shared"]), 17)
eq("name collisions", len(d["name_clash"]), 8)
eq("unique to one tenant", len(d["unique"]), 13)
# The name collisions are TWO kinds wanting opposite treatment.
clash = {e["name"]: e["spans"] for e in d["name_clash"]}
generic = sorted(n for n, sp in clash.items()
                 if len({v[0] for v in sp.values()}) > 1)
extent = sorted(n for n, sp in clash.items()
                if len({v[0] for v in sp.values()}) == 1)
eq("generic per-tenant names (need NAMESPACING)", generic,
   ["anim", "aux0_0", "aux0_1", "aux0_2", "code", "hitbox", "hitbox_proj"])
eq("same start, different EXTENT", extent, ["x088512"])
if not bad:
    print("  ok: 17 shared / 8 collisions (7 generic + x088512's extent) / 13 unique")

print("== 2: shared spans CONFLICT — they cannot be placed once by dedup ==")
FROZEN = {"x026142": (68, 54), "x028122": (45, 50),
          "x05c800": (485, 348), "x2b7ef4": (1076, 1548)}
for n, (solo, conf) in FROZEN.items():
    v = d["blobs"].get(n, {})
    eq("%s (1-differs, conflict)" % n, (v.get("solo"), v.get("conflict")),
       (solo, conf))
eq("total conflicting bytes", d["total_conflict"], 2000)
# Two-tenant spans must be reported UNDECIDABLE, never as a reassuring zero:
# with two tenants "exactly one differs" and "both disagree" are the same
# observation.
und = sorted(n for n, v in d["blobs"].items() if v.get("undecidable"))
eq("two-tenant spans reported undecidable", len(und), 13)
if not bad:
    print("  ok: 2000 conflicting bytes over 4 spans; 13 two-tenant spans")
    print("      honestly reported as undecidable rather than as zero")

print("== 3: per-tenant copies do NOT fit today's space model ==")
sp = d.get("space", {})
eq("space accounting present", "error" not in sp, True)
# Frozen 14z-77. The totals are not the constraint — the tenants' regions fit
# the IMAGE many times over. The CRYPT-window spaces are, because that is
# where PC-reach-constrained regions go, and one tenant already saturates them.
eq("hole_a demand if all three copied", sp["if_all_copied"]["hole_a"], 761316)
eq("hole_b demand if all three copied", sp["if_all_copied"]["hole_b"], 171614)
eq("wide_ext demand if all three copied", sp["if_all_copied"]["wide_ext"], 45580)
eq("hole_a capacity", sp["capacity"]["hole_a"], 264544)
eq("hole_b capacity", sp["capacity"]["hole_b"], 80096)
eq("wide_ext capacity", sp["capacity"]["wide_ext"], 2097136)
over = sorted(n for n, c in sp["capacity"].items()
              if sp["if_all_copied"][n] > c)
eq("spaces that overflow", over, ["hole_a", "hole_b"])
if not bad:
    print("  ok: hole_a overflows by 496772, hole_b by 91518; wide_ext has")
    print("      2051556 spare — so the DEFAULT placement overflows, not the")
    print("      image (code above PRG:0x0FFFFF runs raw)")
    # 14z-77 read this as "the binding constraint is PC-REACH". CORRECTED
    # 14z-78: it is neither reach nor size, it is placement POLICY. Every
    # region audit_region_movability.sh measures — anim included — runs from
    # wide_ext once `region_space` puts it there. anim only looked
    # reach-bound because a thunk baked its placed address as a literal.
    print("      NB: these are DEFAULT-placement demands. region_space moves")
    print("      regions out; see tests/audit_region_movability.sh")

print("== 4: control — placement normalisation is LOAD-BEARING ==")
raw = run(["--no-normalise"])
eq("un-normalised total", raw["total_conflict"], 7591)
if raw["total_conflict"] <= d["total_conflict"]:
    bad.append("normalisation did not reduce the count — it is not doing "
               "anything, so section 2's figure is unverified")
if not bad:
    pct = 100 * (raw["total_conflict"] - d["total_conflict"]) // raw["total_conflict"]
    print("  ok: 7591 raw -> 2000 normalised (%d%% of the raw figure is the"
          % pct)
    print("      artefact of three independent builds' allocators)")

for b in bad: print("  FAIL: %s" % b)
sys.exit(1 if bad else 0)
PY

echo "PASS: region overlap frozen — 17 shared spans, 2000 conflicting bytes,"
echo "      the space demand that per-tenant copies would create, and the"
echo "      normalisation control that makes those numbers real"
