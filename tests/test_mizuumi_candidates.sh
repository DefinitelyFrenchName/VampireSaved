#!/bin/sh
# test_mizuumi_candidates.sh — #118's CLASSIFICATION OF THE MIZUUMI CANDIDATES EQUALS WHAT docs/game/atlas/ram.md SAYS (14z-213). ci_portable: no ROM, ~1 s.
#
# WHAT: docs/game/atlas/mizuumi_candidates.tsv holds the 89 community player-struct candidates of #118's working list;
#   its name, verdict and evidence columns are DERIVED from ram.md by tools/mizuumi_candidates.py (ruled 2026-10-30,
#   14z-213: "Re-derive, beside atlas (Recommended)" — "with a static gate holding each verdict against ram.md"), so a
#   ram.md change that moves a verdict, or a hand edit of the table, shows here.
# HOW: (1) `mizuumi_candidates.py check` over the tree. (2) known answers ([VSP-19]): a synthetic ram.md with one row per
#   verdict rule (R1 REFUTED IN PART .. R8 COVERED, R9 NO ROW) and one no rule decides, and a table of those offsets with
#   the expected verdicts and names: `check` must PASS on it, and `write` from an emptied table must restore it. (3)
#   controls.
# EXPECTS: PASS on the tree; the eleven known answers; each control names its offset DIFFERS.
#
# MUST-FIRE: perturbed-copy: ram-drops-not-adopted — a copy of ram.md with the first "NOT adopted" of a row the table classes NOT ADOPTED removed must make `check` name that offset DIFFERS and FAIL (in-gate: the copy is checked; mode: the gate checks the real table against the copy and FAILs)
# MUST-FIRE: perturbed-copy: table-verdict-edited — a copy of the table with one CONSISTENT verdict rewritten as REFUTED must make `check` name that offset DIFFERS and FAIL (in-gate: the copy is checked; mode: the gate checks that copy and FAILs)
#
# WHY: the table is the community-facing summary of #118; a verdict that drifted from ram.md would misreport what was
#   measured, and the rules that turn ram.md's wording into a verdict are themselves a classifier that must be tested.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
W="$(mktemp -d)" || { echo "FAIL: test_mizuumi_candidates — mktemp -d failed (W)"; exit 2; }; trap 'rm -rf "$W"' EXIT INT TERM
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }
T=tools/mizuumi_candidates.py; TAB=docs/game/atlas/mizuumi_candidates.tsv; RAM=docs/game/atlas/ram.md

echo "== 1. the tree"
cp "$TAB" "$W/tab.tsv"; cp "$RAM" "$W/ram.md"
case "${VS_CTL:-}" in
ram-drops-not-adopted) python3 - "$W" <<'PY'
import sys
w = sys.argv[1]
off = next(l.split("\t")[0] for l in open(w + "/tab.tsv") if "\tNOT ADOPTED\t" in l)
lines = open(w + "/ram.md").read().split("\n")
i = next(k for k, l in enumerate(lines) if l.startswith("| " + off + ".") and "NOT adopted" in l)
lines[i] = lines[i].replace("NOT adopted", "", 1)
open(w + "/ram.md", "w").write("\n".join(lines))
PY
;;
table-verdict-edited) python3 -c "import sys; p=sys.argv[1]; s=open(p).read(); open(p,'w').write(s.replace('\tCONSISTENT\t','\tREFUTED\t',1))" "$W/tab.tsv" ;;
esac
python3 "$T" check --table "$W/tab.tsv" --ram "$W/ram.md" > "$W/tree.out" 2>&1; rc=$?
[ "$rc" = 0 ] && ok "$(tail -1 "$W/tree.out")" || bad "$(grep DIFFERS "$W/tree.out" | head -3 | tr '\n' ' ') $(tail -1 "$W/tree.out")"
[ -n "${VS_CTL:-}" ] && { [ "$fail" = 0 ] && echo "PASS: test_mizuumi_candidates" || echo "FAIL: test_mizuumi_candidates (control mode ${VS_CTL})"; exit "$fail"; }

echo "== 2. known answers: one ram.md row per rule"
cat > "$W/kram.md" <<'MD'
| offset | meaning | provenance |
|---|---|---|
| +0x10.b | a bit set at each jump; consistent with mizuumi's "Alpha" | [M: test] |
| +0x11.b | a counter — RECORDED; mizuumi's "Beta" NOT adopted | [M: test] |
| +0x12.b | Gallon played and never wrote it; mizuumi's "Gamma" not observed (owner not observed) | [M: test] |
| +0x13.b | Felicia's own code writes it; consistent with mizuumi's "Delta" as to OWNER only | [M: test] |
| +0x14.b | mizuumi's "Epsilon": the name REFUTED, it never counts down | [M: test] |
| +0x15.b | mizuumi's "Zeta" is REFUTED as a timer; the rest is consistent | [M: test] |
| +0x40.l | a pointer; mizuumi's "Eta" at +0x41 is this row's | [M: test] |
| +0x50.l | a pointer to the frame's record | [M: test] |
| +0x60.b | written by the select code; meaning unknown, mizuumi's "Theta" | [M: test] |
MD
printf '# known answers\noffset\tname\tverdict\tevidence\tbatch\n' > "$W/ktab.tsv"
python3 - "$W/ktab.tsv" <<'PY'
import sys
rows = [("+0x10", "Alpha", "CONSISTENT"), ("+0x11", "Beta", "NOT ADOPTED"), ("+0x12", "Gamma", "NOT OBSERVED"),
        ("+0x13", "Delta", "OWNER ONLY"), ("+0x14", "Epsilon", "REFUTED"), ("+0x15", "Zeta", "REFUTED IN PART"),
        ("+0x41", "Eta", "CROSS-CHECKED"), ("+0x52", "-", "COVERED"), ("+0x30", "-", "NO ROW"), ("+0x60", "Theta", "UNDECIDED")]
with open(sys.argv[1], "a") as f:
    for o, n, v in rows:
        f.write("\t".join([o, n, v, "?", "-"]) + "\n")
PY
python3 "$T" write --table "$W/ktab.tsv" --ram "$W/kram.md" > "$W/kw.out" 2>&1
got="$(grep -v '^#' "$W/ktab.tsv" | tail -n +2 | awk -F'\t' '{printf "%s=%s/%s ", $1, $3, $2}')"
want="+0x10=CONSISTENT/Alpha +0x11=NOT ADOPTED/Beta +0x12=NOT OBSERVED/Gamma +0x13=OWNER ONLY/Delta +0x14=REFUTED/Epsilon +0x15=REFUTED IN PART/Zeta +0x41=CROSS-CHECKED/Eta +0x52=COVERED/- +0x30=NO ROW/- +0x60=UNDECIDED/Theta "
[ "$got" = "$want" ] && ok "every rule R1-R9 and an undecided row give their verdict and name" || bad "known answers: [$got], want [$want]"
python3 "$T" check --table "$W/ktab.tsv" --ram "$W/kram.md" > "$W/kc.out" 2>&1 && ok "check PASSes on what write derived" || bad "check after write: $(tail -1 "$W/kc.out")"
grep -q "^UNDECIDED	+0x60	" "$W/kc.out" && ok "the undecided row is named with its reason" || bad "the undecided row was not named"

echo "== 3. controls"
cp "$TAB" "$W/c1.tsv"; python3 -c "import sys; p=sys.argv[1]; s=open(p).read(); open(p,'w').write(s.replace('\tCONSISTENT\t','\tREFUTED\t',1))" "$W/c1.tsv"
if python3 "$T" check --table "$W/c1.tsv" --ram "$RAM" > "$W/c1.out" 2>&1; then vs_ctl_dead table-verdict-edited "check passed an edited verdict"; fail=1
elif grep -q "^DIFFERS" "$W/c1.out"; then vs_ctl_fired table-verdict-edited "$(grep -m1 DIFFERS "$W/c1.out" | cut -c1-110)"
else vs_ctl_dead table-verdict-edited "check failed for another reason"; fail=1; fi
cp "$RAM" "$W/c2.md"; python3 - "$TAB" "$W/c2.md" <<'PY'
import sys
off = next(l.split("\t")[0] for l in open(sys.argv[1]) if "\tNOT ADOPTED\t" in l)
lines = open(sys.argv[2]).read().split("\n")
i = next(k for k, l in enumerate(lines) if l.startswith("| " + off + ".") and "NOT adopted" in l)
lines[i] = lines[i].replace("NOT adopted", "", 1)
open(sys.argv[2], "w").write("\n".join(lines))
PY
if python3 "$T" check --table "$TAB" --ram "$W/c2.md" > "$W/c2.out" 2>&1; then vs_ctl_dead ram-drops-not-adopted "check passed a ram.md that no longer says NOT adopted"; fail=1
elif grep -q "^DIFFERS" "$W/c2.out"; then vs_ctl_fired ram-drops-not-adopted "$(grep -m1 DIFFERS "$W/c2.out" | cut -c1-110)"
else vs_ctl_dead ram-drops-not-adopted "check failed for another reason"; fail=1; fi

[ "$fail" = 0 ] && echo "PASS: test_mizuumi_candidates — the classification equals ram.md, every rule gives its known answer, and both controls fire" || echo "FAIL: test_mizuumi_candidates"
exit "$fail"
