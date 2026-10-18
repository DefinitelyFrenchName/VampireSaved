#!/bin/sh
# test_sheet_census.sh — EVERY EMULATOR GATE SAYS WHAT ITS COMPARATIVE SHEET SHOWS, OR IS ON THE RETROFIT'S DEBT LIST
# (GitHub #291 slice S1, 14z-204; the design ruled 2026-10-17: "Declared in each gate (Recommended)").
#
# WHAT: every gate of the emulator registry (tests/ci_emulator.tsv) carries exactly one well-formed `# SHEET:` line in
#   its leading comment block (`legs <roles> — moments: … — not comparable: …`, `no-reference-leg — <reason>` or
#   `none — <reason>`) or is on the shrink-only debt list tests/expected/sheet_debt.txt; a `legs` gate sources
#   tests/lib/sheet.sh; the declaration grammar and the sheet file's reader refuse what they must; tests/lib/sheet.sh
#   assigns only `__sheet_` names (sh has no locals, and a gate's own variable must survive a call).
# HOW: tools/proof_sheets.py's own reader (`census`, `parse_declaration`, `read_sheet`) — the one the sheet tool uses —
#   over tests/, the registry and the debt list; fixture declarations and sheet files for the refusals; four controls
#   on perturbed copies.
# EXPECTS: PASS with the census counts; a red names the gate with no line, a malformed line, a legs gate that writes no
#   sheet, or a debt row that should be gone. It does not claim a sheet is RIGHT: tests/test_proof_sheets.sh proves
#   the pictures, and each gate's verdict is its own.
# FOLLOWS: tests/ tools/proof_sheets.py tests/lib/sheet.sh tests/ci_emulator.tsv tests/expected/sheet_debt.txt tests/lib/controls.sh
#
# MUST-FIRE: perturbed-copy: dropped-declaration — a copy of tests/ with one declaring gate's `# SHEET:` line neutered must be named as a registered gate with no line and not on the debt list (section 1 fails)
# MUST-FIRE: perturbed-copy: silent-legs — a copy with one legs gate's source line for tests/lib/sheet.sh commented out must be named as declaring legs and writing no sheet (section 1 fails)
# MUST-FIRE: perturbed-copy: leaky-helper — a copy of tests/lib/sheet.sh with one helper variable renamed out of the `__sheet_` prefix (the 14z-204 `_sf` collision, which overwrote audit_merged_legacy's frame variable) must be named (section 4 fails)
# MUST-FIRE: perturbed-copy: debt-regrown — a copy of the debt list with a declaring gate added back must be named as a row that should be gone (section 1 fails), or the list does not only shrink
#
# Usage: tests/test_sheet_census.sh   # ci_portable, ROM-free, ~2 s
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
REG=tests/ci_emulator.tsv
DEBT=tests/expected/sheet_debt.txt
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
bad=0; ok() { echo "  ok    $1"; }; nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }

census() {  # census <tests dir> <debt file> -> the tool's rows and PROBLEM lines; status 1 on a problem
    python3 tools/proof_sheets.py census --tests "$1" --registry "$REG" --debt "$2"
}
first_legs() {  # the first gate the real census classes `legs`
    census tests "$DEBT" | awk -F'\t' '$1 == "legs" {print $2; exit}'
}
neuter_decl() {  # neuter_decl <dir> <gate> — the dropped-declaration perturbation
    perl -pi -e 's/^# SHEET: /# SHEET-XX: /' "$1/$2.sh"
}
neuter_source() {  # neuter_source <dir> <gate> — the silent-legs perturbation
    perl -pi -e 's/^(\s*)(\.\s+\S*tests\/lib\/sheet\.sh)/$1# $2/' "$1/$2.sh"
}

leaks() {  # leaks <sheet.sh> -> every variable assigned (or looped over) that is not __sheet_-prefixed
    command grep -v '^[[:space:]]*#' "$1" | command grep -oE '(^|[;[:space:]])[A-Za-z_][A-Za-z0-9_]*=|for [A-Za-z_][A-Za-z0-9_]* in' \
        | sed -E 's/^[;[:space:]]*//; s/=$//; s/^for ([A-Za-z0-9_]*) in$/\1/' | command grep -v '^__sheet_' | sort -u
}
leak_copy() {  # leak_copy <out> — the leaky-helper perturbation: the row loop's variable renamed to the old `_sf`
    sed 's/__sheet_f/_sf/g' tests/lib/sheet.sh > "$1"
}

# THE EXECUTABLE FORM: under CONTROL=<name> the perturbed copy IS the input.
SRC=tests; SDEBT="$DEBT"; LIB=tests/lib/sheet.sh
L1="$(first_legs)"
if vs_ctl_is dropped-declaration; then
    mkdir -p "$W/in"; cp tests/*.sh "$W/in/"; SRC="$W/in"; neuter_decl "$SRC" "$L1"
elif vs_ctl_is silent-legs; then
    mkdir -p "$W/in"; cp tests/*.sh "$W/in/"; SRC="$W/in"; neuter_source "$SRC" "$L1"
elif vs_ctl_is leaky-helper; then
    leak_copy "$W/lib_sheet.sh"; LIB="$W/lib_sheet.sh"
elif vs_ctl_is debt-regrown; then
    cp "$DEBT" "$W/debt"; echo "$L1" >> "$W/debt"; SDEBT="$W/debt"
fi

echo "== test_sheet_census: every emulator gate declares its comparative sheet, or is on the debt list (#291) =="
echo "== 1. the census"
census "$SRC" "$SDEBT" > "$W/got.txt"; rc=$?
nl="$(command grep -c '^legs	' "$W/got.txt")"; nn="$(command grep -c '^none	' "$W/got.txt")"
nr="$(command grep -c '^no-reference-leg	' "$W/got.txt")"; nd="$(command grep -c '^debt	' "$W/got.txt")"
echo "  measured: $nl legs, $nr no-reference-leg, $nn none, $nd on the debt list"
echo "NOTE: sheet.legs $nl no-reference-leg $nr none $nn debt $nd"
if [ "$rc" = 0 ] && ! command grep -q '^PROBLEM' "$W/got.txt"; then
    ok "every registered gate declares one well-formed line or is on the debt list; every legs gate sources tests/lib/sheet.sh"
else
    nope "the census found problems:"; command grep '^PROBLEM' "$W/got.txt" | cut -f2 | sed 's/^/        /'
fi
[ "$nl" -ge 1 ] || nope "no gate declares legs — the census reads nothing"

echo "== 2. the grammar refuses what it must (tools/proof_sheets.py parse_declaration)"
decl() {  # decl <name> <line...> -> the parser's verdict on a fixture gate holding those header lines
    _f="$W/decl_$1.sh"; shift
    { echo '#!/bin/sh'; for _l in "$@"; do echo "$_l"; done; echo 'set -e'; } > "$_f"
    python3 -c "import sys; sys.path.insert(0, 'tools'); import proof_sheets as p; d, e = p.parse_declaration(sys.argv[1]); print('ERR' if e else (d['kind'] if d else 'NONE'))" "$_f"
}
check() {  # check <want> <name> <line...>
    _w="$1"; shift; _n="$1"; got="$(decl "$@")"
    if [ "$got" = "$_w" ]; then ok "$_n: $got"; else nope "$_n: got $got, want $_w"; fi
}
check legs "a well-formed legs line" "# SHEET: legs ours,vs2 — moments: each event — not comparable: the stage"
check legs "a hyphen inside the text is not a separator" "# SHEET: legs vsavj,ours — moments: a frame-exact list — not comparable: P2's art - each game's own"
check none "a none line with its reason" "# SHEET: none — vanilla only"
check no-reference-leg "a no-reference-leg line" "# SHEET: no-reference-leg — frozen vs2 values, no vs2 rig"
check NONE "no line at all" "# WHAT: nothing"
check ERR "legs without ours" "# SHEET: legs vsavj,vs2 — moments: x — not comparable: y"
check ERR "legs without a reference" "# SHEET: legs ours — moments: x — not comparable: y"
check ERR "an unknown role" "# SHEET: legs ours,vsav — moments: x — not comparable: y"
check ERR "legs without not comparable" "# SHEET: legs ours,vs2 — moments: x"
check ERR "none without a reason" "# SHEET: none"
check ERR "two lines" "# SHEET: none — a" "# SHEET: none — b"
check NONE "a line below the leading block is not a declaration" "# WHAT: x" "" "echo hi" "# SHEET: none — late"

echo "== 3. the sheet file's reader refuses a malformed row (tools/proof_sheets.py read_sheet)"
rs() {  # rs <name> <want ok|refused> <rows file>
    if python3 -c "import sys; sys.path.insert(0, 'tools'); import proof_sheets as p; p.read_sheet(sys.argv[1])" "$(dirname "$3")" 2> "$W/rs.err"; then got=ok; else got=refused; fi
    if [ "$got" = "$2" ]; then ok "$1: $got"; else nope "$1: $got, want $2 ($(tail -1 "$W/rs.err"))"; fi
}
T="	"
mk() { mkdir -p "$W/s_$1"; printf '%s\n' "$2" > "$W/s_$1/sheet.tsv"; echo "$W/s_$1/sheet.tsv"; }
good="sheet${T}a${T}t${T}-${T}-${T}nc
leg${T}a${T}x${T}ours${T}vsavj${T}rp${T}legs/a.x.rpl${T}-${T}100${T}-${T}-
moment${T}a${T}m1${T}l${T}IDENT${T}-
at${T}a${T}m1${T}x${T}50${T}ram${T}0123456789abcdef"
rs "a well-formed file" ok "$(mk good "$good")"
rs "a short row" refused "$(mk short "$(printf '%s\n' "$good" | sed '3s/	-$//')")"
rs "an at-row for an undeclared leg" refused "$(mk noleg "$(printf '%s\n' "$good" | sed '4s/	x	50/	y	50/')")"
rs "an unknown basis" refused "$(mk basis "$(printf '%s\n' "$good" | sed '4s/	ram	/	guess	/')")"
rs "an unknown role" refused "$(mk role "$(printf '%s\n' "$good" | sed '2s/	ours	/	vsav	/')")"

echo "== 4. tests/lib/sheet.sh assigns only __sheet_ names (sh has no locals)"
lk="$(leaks "$LIB" | tr '\n' ' ')"
if [ -z "$lk" ]; then ok "every variable the helper sets is __sheet_-prefixed"; else nope "the helper sets caller-visible names: $lk"; fi

echo "== 5. must-fire controls on the census"
mkdir -p "$W/t1" "$W/t2"; cp tests/*.sh "$W/t1/"; cp tests/*.sh "$W/t2/"
neuter_decl "$W/t1" "$L1"
if census "$W/t1" "$DEBT" | command grep -q "^PROBLEM	$L1: no \`# SHEET:\` line and not in the debt list"; then
    vs_ctl_fired dropped-declaration "$L1 with its line neutered is named: no line, not on the debt list"
else vs_ctl_dead dropped-declaration "$L1 with its line neutered was not named"; nope "control dropped-declaration"; fi
neuter_source "$W/t2" "$L1"
if census "$W/t2" "$DEBT" | command grep -q "^PROBLEM	$L1: declares legs but never sources tests/lib/sheet.sh"; then
    vs_ctl_fired silent-legs "$L1 with its source line commented out is named: declares legs, writes no sheet"
else vs_ctl_dead silent-legs "$L1 with its source line commented out was not named"; nope "control silent-legs"; fi
cp "$DEBT" "$W/debt2"; echo "$L1" >> "$W/debt2"
if census tests "$W/debt2" | command grep -q "^PROBLEM	$L1: declares .* but is still in the debt list"; then
    vs_ctl_fired debt-regrown "$L1 added back to the debt list is named as a row that should be gone"
else vs_ctl_dead debt-regrown "$L1 added back to the debt list was not named"; nope "control debt-regrown"; fi

leak_copy "$W/leak.sh"
if [ -n "$(leaks "$W/leak.sh")" ]; then vs_ctl_fired leaky-helper "a copy whose row loop uses _sf is named: $(leaks "$W/leak.sh" | tr '\n' ' ')"
else vs_ctl_dead leaky-helper "a copy whose row loop uses _sf was not named"; nope "control leaky-helper"; fi

[ "$bad" = 0 ] && { echo "PASS: test_sheet_census — $nl legs, $nr no-reference-leg, $nn none, $nd on the debt list"; exit 0; }
echo "FAIL: test_sheet_census ($bad)"; exit 1
