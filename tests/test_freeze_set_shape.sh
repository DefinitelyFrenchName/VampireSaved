#!/bin/sh
# test_freeze_set_shape.sh — every numbered expectation set LOSES NOTHING its predecessor held, and the committed
# freeze driver carries, pins, verifies and cleans up in that order (`tools/freeze_set_shape.py`,
# `tools/freeze_expectation_set.py`; 14z-185b, GitHub #150).
#
# WHAT: over every numbered set under tests/expected/, against its predecessor (the family's next lower number):
#   no `.masked`/`.skip` name lost, no `.sha1` lost unless reclassified as `.masked`/`.skip`/`.diverge`, the mask
#   unchanged (introduced is allowed), a merged set with zero `.sha1`, and every declared exception
#   (tests/expected/set_shape_exceptions.tsv) still matching a loss; and the driver carries the authored files
#   verbatim, hands the suite a pinned MAME_BIN, verifies a merged set BEFORE removing its `.sha1`, and refuses an
#   existing set or a build registered to another set.
# HOW: runs both tools' selftests, then the shape rule over the real sets; seven controls run copies with one
#   safeguard switched off — four for the shape rule's failure conditions (#185 item 5), three for the driver's
#   (the carry, the pin, the verify-before-cleanup order) — and each must fail its selftest.
# EXPECTS: both selftests PASS, the real sets clean (0 failures), all seven controls fail on their copies.
#
# WHY. The freeze ritual had three silent-green failure modes, hit or nearly hit in one sitting (14z-159): an
# unpinned MAME_BIN, a set frozen into an empty directory (a tautology in place of the vanilla oracle, [VSP-36]),
# and a merged set keeping the tenant `.sha1` a freeze regenerates (#111). The maintainer ruled the design:
# "S1 nothing lost", "P1 by family", "D1 full driver". Measured on 63 historical pairs before landing: no
# `.masked`/`.skip` ever removed, 13 of 14 `.sha1` removals reclassified, one declared exception.
#
# MUST-FIRE: perturbed-copy: lost-ignored — a shape copy that never counts a LOST entry must pass the empty-dir case, and its selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: mask-ignored — a shape copy that never counts a changed MASK must pass that case, and its selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: merged-ignored — a shape copy that never counts a merged set's `.sha1` must pass that case, and its selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: stale-ignored — a shape copy that never counts a STALE exception must pass that case, and its selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: carry-skipped — a driver copy that copies no authored file must fail its carry check, and its selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: unpinned — a driver copy that hands the suite no MAME_BIN must fail its pin check, and its selftest must FAIL (mode: that copy's selftest)
# MUST-FIRE: perturbed-copy: cleanup-first — a driver copy that removes a merged set's `.sha1` BEFORE its verify must read NO-EXPECTATION, and its selftest must FAIL (mode: that copy's selftest)
#
# Usage: tests/test_freeze_set_shape.sh      # ci_portable, ~3 s
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
SHAPE_CTLS="lost-ignored mask-ignored merged-ignored stale-ignored"
DRIVER_CTLS="carry-skipped unpinned cleanup-first"

make_copy() {  # make_copy <control> — a copy of both tools with ONE safeguard switched off; prints the tool to run
    mkdir -p "$W/$1"; cp tools/freeze_set_shape.py tools/freeze_expectation_set.py "$W/$1/"
    python3 - "$W/$1" "$1" <<'PY'
import os, sys; d, name = sys.argv[1:3]
S, D = os.path.join(d, "freeze_set_shape.py"), os.path.join(d, "freeze_expectation_set.py")
edits = {
    "lost-ignored": (S, 'print(f"  LOST        {s}: {n}.{cls} (held by {pred[s]})")\n                bad += 1\n',
                        'print(f"  LOST        {s}: {n}.{cls} (held by {pred[s]})")  # CONTROL lost-ignored\n'),
    "mask-ignored": (S, 'print(f"  MASK        {s}: the mask of {pred[s]} changed or removed")\n                bad += 1\n',
                        'print(f"  MASK        {s}: the mask of {pred[s]} changed or removed")  # CONTROL mask-ignored\n'),
    "merged-ignored": (S, "print(f\"  MERGED SHA1 {s}: {len(B['sha1'])} .sha1 ({' '.join(sorted(B['sha1']))[:120]})\")\n            bad += 1\n",
                          "print(f\"  MERGED SHA1 {s}: {len(B['sha1'])} .sha1 ({' '.join(sorted(B['sha1']))[:120]})\")  # CONTROL merged-ignored\n"),
    "stale-ignored": (S, 'print(f"  STALE       exception {k[0]} {k[1]} {k[2]}: matches no loss")\n                bad += 1\n',
                         'print(f"  STALE       exception {k[0]} {k[1]} {k[2]}: matches no loss")  # CONTROL stale-ignored\n'),
    "carry-skipped": (D, "    for f in auth:\n", "    for f in []:  # CONTROL carry-skipped\n"),
    "unpinned": (D, 'MAME_BIN=os.environ.get("MAME_BIN") or PIN', 'MAME_BIN=os.environ.get("MAME_BIN") or "" '),  # CONTROL unpinned: the pin gone
    "cleanup-first": (D, '    for step, args in (("freeze", ["--freeze", set_key]), ("verify", [set_key])):\n        with L(step) as fh:\n',
                         '    for step, args in (("freeze", ["--freeze", set_key]), ("verify", [set_key])):\n'
                         '        if step == "verify" and new.startswith("merged-m"):  # CONTROL cleanup-first\n'
                         '            [os.remove(os.path.join(root, "tests/expected", new, f)) for f in os.listdir(os.path.join(root, "tests/expected", new)) if f.endswith(".sha1")]\n'
                         '        with L(step) as fh:\n'),
}
p, a, b = edits[name]
s = open(p).read()
assert s.count(a) == 1, name
open(p, "w").write(s.replace(a, b, 1))
print(p)
PY
}

echo "== test_freeze_set_shape: #150 — nothing lost, and the driver's order =="
fail=0
SHAPE=tools/freeze_set_shape.py; DRIVER=tools/freeze_expectation_set.py
case " $SHAPE_CTLS " in *" ${VS_CTL:-none} "*) SHAPE="$(make_copy "$VS_CTL")" ;; esac
case " $DRIVER_CTLS " in *" ${VS_CTL:-none} "*) DRIVER="$(make_copy "$VS_CTL")" ;; esac
python3 "$SHAPE" --selftest > "$W/s.txt" 2>&1 || true
grep -q '^SELFTEST PASS$' "$W/s.txt" && echo "  ok: the shape rule's selftest (nine cases)" || { sed 's/^/  /' "$W/s.txt" | grep -E 'FAIL|SELFTEST'; echo "FAIL: the shape rule's selftest"; fail=1; }
python3 "$DRIVER" --selftest > "$W/d.txt" 2>&1 || true
grep -q '^SELFTEST PASS$' "$W/d.txt" && echo "  ok: the driver's selftest (eight checks)" || { sed 's/^/  /' "$W/d.txt" | grep -E 'FAIL|SELFTEST'; echo "FAIL: the driver's selftest"; fail=1; }
if python3 tools/freeze_set_shape.py > "$W/real.txt" 2>&1; then echo "  ok: the real sets — $(tail -1 "$W/real.txt")"
else grep -E '^  (LOST|MASK|MERGED|STALE|FAIL)' "$W/real.txt" | sed 's/^/  /'; echo "FAIL: a real expectation set lost something its predecessor held"; fail=1; fi

if [ -z "${VS_CTL:-}" ]; then
    for c in $SHAPE_CTLS $DRIVER_CTLS; do
        t="$(make_copy "$c")"
        python3 "$t" --selftest > "$W/ctl_$c.txt" 2>&1 || true
        if grep -q '^SELFTEST FAIL$' "$W/ctl_$c.txt"; then vs_ctl_fired "$c" "$(grep -m1 '  FAIL:' "$W/ctl_$c.txt" | sed 's/^ *//' | cut -c1-120)"
        elif grep -q '^SELFTEST PASS$' "$W/ctl_$c.txt"; then vs_ctl_dead "$c" "the perturbed copy passed its selftest — the selftest cannot see this failure" || fail=1
        else vs_ctl_dead "$c" "the perturbed copy CRASHED before a verdict ($(tail -1 "$W/ctl_$c.txt" | cut -c1-100)) — the perturbation is broken, not the tool" || fail=1; fi
    done
fi

if [ "$fail" = 0 ]; then echo "PASS: every set keeps what its predecessor held, and the driver carries, pins, verifies and cleans up in order"
else echo "FAIL: test_freeze_set_shape"; exit 1; fi
