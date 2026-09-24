#!/bin/sh
# test_same_data_p2.sh — NO LEGACY CHARACTER CARRIES THE SAME CHARACTER DATA ON
# vsavj AND vsav2, AND WHICH CHAINS DIFFER FOR EACH IS FROZEN (14z-164, GitHub
# #136 proposition 2, maintainer-agreed 2026-09-17).
#
# WHAT: no legacy character carries the same character data on vsavj and vsav2 (0 of 12),
#   and which chains differ for each is frozen — the measurement behind choosing Demitri as
#   the parity rigs' P2 (table a identical; b:0x10/0x71/0x74 and c:0x2e/0x2f differ).
# HOW: tools/audit_same_data_p2.py over both decrypted data views (the bank's value rows,
#   every anim node's resolved boxes and attack record across tables a/a2/b/c/proj, the
#   defense-curve row), never the indices vs2 renumbered; controls run vsavj's view on both
#   sides (every character must read SAME-DATA and fail the table) and drop Demitri's row.
# EXPECTS: the frozen per-character table equal with its one-sided counts; the self-compare
#   and the dropped row fail. The code_ptr, auto and data_ptr rows are named per row and not
#   compared.
#
# MUST-FIRE: perturbed-copy: self-compare — the audit run with vsavj's data view on BOTH sides (both read with the vsavj layout) must read every character SAME-DATA and so fail the frozen table (mode: the same perturbation on the real run, the compare must FAIL)
# MUST-FIRE: perturbed-copy: dropped-row — a copy of the frozen table with one character's row removed must fail the completeness check (mode: the real table with Demitri's row removed, the gate must FAIL)
#
# WHY. The tenant-move parity rigs (tests/audit_move_parity.sh) put VICTOR on
# P2; on our leg he is Vampire Savior's Victor and on the native leg Vampire
# Savior 2's. The 14z-164 census found five of the 13 first divergences begin
# in his state, and this audit found why: his basic hit reactions b:0x00-0x05
# carry a retuned head hurtbox on vs2 ((0,77,17,11) -> (21,88,27,16)). The
# maintainer agreed to a P2 whose data is the same on both games, found
# statically. tools/audit_same_data_p2.py compares, for every legacy id both
# games carry, the bank's value rows, the resolved hitboxes and attack record
# of every anim node in tables a/a2/b/c/proj, and the defense-curve row.
# MEASURED 14z-164: 0 of 12 are SAME-DATA; "nearest for a victim role" means
# table a identical first, then the fewest differing b chains (shared seqs):
# Demitri (table a identical; b:0x10/0x71/0x74 and c:0x2e/0x2f differ) and
# Bishamon (a:0x1d/0x3e, b:0x10/0x74); Bulleta has the fewest b differences
# (b:0x10 alone) but three table-a chains differ; b:0x10 differs for almost every
# character (a push box vs2 gave a boxless held pose) and is engine-generation
# drift, not tuning. This gate freezes that table so a changed decoder, a
# changed bank map or a changed reference image is loud.
#
# WHAT IT DOES NOT CLAIM: the 21 code_ptr rows (the character's own routines),
# the 19 `auto` rows (counted in their own column, never classed) and six
# data_ptr rows (capture_kf_ptr, tail_data_ptr, ai_script_0-3) are not
# compared and the verdict does not rest on them — the frozen table names
# them per row; a "same-data" verdict would be about data a standing, hit P2
# runs, never about the character as an attacker. "Which chains differ" is over
# the SHARED sequences of a table; the one-sided counts (present in one game
# only) are frozen beside them, and a character whose projectile hitbox tables
# cannot be read on a side has its proj column marked so, never resolved
# through the fighter's tables (rule-checker run 2026-09-17-25).
#
# Usage: [ROMDIR=...] [FREEZE=1] tests/test_same_data_p2.sh   # ci_static, ~20 s;
#   ROMDIR only when the build/out decrypt cache is absent (tests/lib/decrypt_cache.sh)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
CONTROL="${CONTROL:-}"
EXPECT="$REPO/tests/expected/same_data_p2.tsv"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj.bin" || { echo "SKIP: no vsavj decrypt view (set ROMDIR to build the cache)"; exit 0; }
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2.bin" || { echo "SKIP: no vsav2 decrypt view (set ROMDIR to build the cache)"; exit 0; }

# ONE function runs the audit and reduces it to the frozen table, so the control
# perturbs exactly what the gate asserts ([VSP-181]).
run_audit() {  # run_audit <vsavj view> <vsav2 view> <out.tsv> [--layout vsavj]
    python3 "$REPO/tools/audit_same_data_p2.py" "$1" "$2" --json "$W/r.json" ${4:+"$4" "$5"} > "$W/audit.log" 2>&1 || { echo "FAIL: the audit died: $(tail -1 "$W/audit.log")"; exit 1; }
    python3 - "$W/r.json" "$3" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
with open(sys.argv[2], "w") as f:
    f.write("# id\tname\tverdict\ta_differ\tb_differ\tc_differ\ta2_a\tproj\tone_sided(vsavj/vsav2 per a,a2,b,c,proj)\tinvalid_one_side(per a,a2,b,c,proj)\tproj_tables\tunresolved_nodes(vsavj/vsav2)\texternal_links(vsavj/vsav2)\tunknown_links(vsavj/vsav2)\tinvalid_chains(vsavj/vsav2)\tvalues\thitbox_notes\tdefense\tauto_rows_differing\tnot_compared\n")
    for cid, v in r.items():
        d = v.get("anim_seqs_diff", {})
        def seqs(t): return ",".join(d[t]["differ"]) if t in d and d[t]["differ"] else "-"
        def cnt(t): return str(len(d[t]["differ"])) if t in d else "0"
        def one(t): return "%d/%d" % (len(d[t]["only_vsavj"]), len(d[t]["only_vsav2"])) if t in d else "0/0"
        pt = v.get("proj_tables", {})
        f.write("\t".join([cid, v["name"], v["verdict"], seqs("a"), seqs("b"), seqs("c"), cnt("a2"), cnt("proj"),
                           ";".join(one(t) for t in ("a", "a2", "b", "c", "proj")),
                           ";".join((",".join(d[t]["invalid_one_side"]) if t in d and d[t].get("invalid_one_side") else "-") for t in ("a", "a2", "b", "c", "proj")),
                           "vsavj:%s,vsav2:%s" % (pt.get("vsavj", "?"), pt.get("vsav2", "?")),
                           "%d/%d" % (v["unresolved_nodes"]["vsavj"], v["unresolved_nodes"]["vsav2"]),
                           "%d/%d" % (v.get("external_links", {}).get("vsavj", 0), v.get("external_links", {}).get("vsav2", 0)),
                           "%d/%d" % (v["unknown_links"]["vsavj"], v["unknown_links"]["vsav2"]),
                           "%d/%d" % (v.get("invalid_chains", {}).get("vsavj", 0), v.get("invalid_chains", {}).get("vsav2", 0)),
                           ",".join(v["values_diff"]) or "-", ";".join(v["hitbox_diff"]) or "-",
                           "same" if v["defense_same"] else "differs",
                           str(len(v["auto_diff"])), "code_ptr x%d;" % v["code_ptr_rows"] + ",".join(v["data_ptr_not_compared"])]) + "\n")
PY
}

echo "== 1. the audit on the two reference views"
if [ "$CONTROL" = self-compare ]; then run_audit "$W/vj.bin" "$W/vj.bin" "$W/got.tsv" --layout vsavj; else run_audit "$W/vj.bin" "$W/v2.bin" "$W/got.tsv"; fi
n="$(command grep -c . "$W/got.tsv")"; [ "$n" -ge 13 ] || bad "the audit produced $n lines, expected 12 characters + header"
ok "$(( n - 1 )) legacy characters audited"

if [ "${FREEZE:-0}" = 1 ]; then
    cp "$W/got.tsv" "$EXPECT"; echo "  FROZE  $(basename "$EXPECT") from this run (freeze, then VERIFY: re-run without FREEZE)"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }

echo "== 2. the table equals the frozen expectation (completeness both ways)"
EXP_USE="$EXPECT"
if [ "$CONTROL" = dropped-row ]; then command grep -v "^0x01	" "$EXPECT" > "$W/exp_dropped.tsv"; EXP_USE="$W/exp_dropped.tsv"; fi
if command diff -u "$EXP_USE" "$W/got.tsv" > "$W/diff.txt"; then ok "12 rows identical to the frozen table"; else bad "the table moved:"; head -20 "$W/diff.txt"; fi
same="$(awk -F'\t' '!/^#/ && $3=="SAME-DATA"' "$W/got.tsv" | command grep -c . || true)"
[ "$same" = 0 ] && ok "0 of 12 SAME-DATA, as frozen" || bad "$same characters read SAME-DATA — a decoder that stopped seeing, or a moved image"

echo "== 3. must-fire controls"
# self-compare: the same view on both sides must read SAME-DATA everywhere and fail section 2
run_audit "$W/vj.bin" "$W/vj.bin" "$W/self.tsv" --layout vsavj
s="$(awk -F'\t' '!/^#/ && $3=="SAME-DATA"' "$W/self.tsv" | command grep -c . || true)"
if [ "$s" = 12 ] && ! command diff -q "$EXPECT" "$W/self.tsv" > /dev/null; then echo "CONTROL FIRED: self-compare — vsavj against itself reads 12 of 12 SAME-DATA and differs from the frozen table"
else echo "CONTROL DEAD: self-compare — vsavj against itself read $s SAME-DATA"; fail=1; fi
# dropped-row: a table missing one character cannot equal the frozen one
command grep -v "^0x01	" "$W/got.tsv" > "$W/dropped.tsv"
if command diff -q "$EXPECT" "$W/dropped.tsv" > /dev/null; then echo "CONTROL DEAD: dropped-row — a table without Demitri's row still equals the frozen one"; fail=1
else echo "CONTROL FIRED: dropped-row — a table without Demitri's row differs from the frozen one"; fi

if [ "$fail" = 0 ]; then echo "PASS: test_same_data_p2"; else echo "FAIL: test_same_data_p2"; exit 1; fi
