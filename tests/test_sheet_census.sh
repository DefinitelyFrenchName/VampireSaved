#!/bin/sh
# test_sheet_census.sh — EVERY EMULATOR GATE SAYS WHAT ITS COMPARATIVE SHEET SHOWS, OR IS ON THE RETROFIT'S DEBT LIST
# (GitHub #291 slice S1, 14z-204; the design ruled 2026-10-17: "Declared in each gate (Recommended)").
#
# WHAT: every gate of the emulator registry (tests/ci_emulator.tsv) carries exactly one well-formed `# SHEET:` line in
#   its leading comment block (`legs <roles> — moments: … — not comparable: …`, `no-reference-leg — <reason>`, `no-picture — <reason>` or
#   `none — <reason>`) or is on the shrink-only debt list tests/expected/sheet_debt.txt; a `legs` gate sources
#   tests/lib/sheet.sh; the declaration grammar and the sheet file's reader refuse what they must; tests/lib/sheet.sh
#   assigns only `__sheet_` names (sh has no locals, and a gate's own variable must survive a call); the page reads each
#   gate's own verdict line, prefixed forms included, never a control or an indented line (14z-205); every section of
#   docs/project/sheet_notes.md names a gate that exists, and a note renders its paragraphs, bullets, bold, code and
#   issue links with everything else escaped (14z-205); and (#291 S4, 14z-206) every `legs` gate shows about 9 frames
#   per judged event — its code writes span or inputs rows, or it proves only by the event basis or its own files — or
#   is on the shrink-only span debt list tests/expected/sheet_span_debt.txt, and a `# SHEET-VERDICTS:` line is well
#   formed.
# HOW: tools/proof_sheets.py's own reader (`census`, `parse_declaration`, `read_sheet`) — the one the sheet tool uses —
#   over tests/, the registry and the debt list; fixture declarations and sheet files for the refusals; four controls
#   on perturbed copies.
# EXPECTS: PASS with the census counts; a red names the gate with no line, a malformed line, a legs gate that writes no
#   sheet, or a debt row that should be gone. It does not claim a sheet is RIGHT: tests/test_proof_sheets.sh proves
#   the pictures, and each gate's verdict is its own.
# FOLLOWS: tests/ tools/proof_sheets.py tests/lib/sheet.sh tests/ci_emulator.tsv tests/expected/sheet_debt.txt tests/lib/controls.sh
#   tests/expected/sheet_span_debt.txt
#   docs/project/sheet_notes.md
#
# MUST-FIRE: perturbed-copy: dropped-declaration — a copy of tests/ with one declaring gate's `# SHEET:` line neutered must be named as a registered gate with no line and not on the debt list (section 1 fails)
# MUST-FIRE: perturbed-copy: silent-legs — a copy with one legs gate's source line for tests/lib/sheet.sh commented out must be named as declaring legs and writing no sheet (section 1 fails)
# MUST-FIRE: perturbed-copy: leaky-helper — a copy of tests/lib/sheet.sh with one helper variable renamed out of the `__sheet_` prefix (the 14z-204 `_sf` collision, which overwrote audit_merged_legacy's frame variable) must be named (section 4 fails)
# MUST-FIRE: perturbed-copy: orphan-note — a copy of docs/project/sheet_notes.md with a section for a gate that does not exist must be named (section 3c fails), so a note cannot outlive or misname its gate
# MUST-FIRE: perturbed-copy: span-debt-regrown — a copy of the span debt list with a spanned gate added back must be named as a row that should be gone (section 1 fails), or the span list does not only shrink
# MUST-FIRE: perturbed-copy: span-dropped — a copy of tests/ with one spanned gate's span rows neutered must be named as a legs gate with no span and not on the span debt list (section 1 fails)
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

SPAN_DEBT=tests/expected/sheet_span_debt.txt
census() {  # census <tests dir> <debt file> [<span debt file>] -> the tool's rows and PROBLEM lines; status 1 on a problem
    python3 tools/proof_sheets.py census --tests "$1" --registry "$REG" --debt "$2" --span-debt "${3:-$SSPAN}"
}
SPANNED=audit_move_parity     # a gate whose code writes span rows (#291 S4-D)
neuter_span() {  # neuter_span <dir> <gate> — the span-dropped perturbation: the gate's span and trace writers renamed away
    perl -pi -e 's/\bsheet_span\b/sheet_spxn/g; s/span\\t/spxn\\t/g' "$1/$2.sh"
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
SRC=tests; SDEBT="$DEBT"; SSPAN="$SPAN_DEBT"; LIB=tests/lib/sheet.sh; NOTES=docs/project/sheet_notes.md
orphan_copy() {  # orphan_copy <out> — the orphan-note perturbation: a section for a gate that does not exist
    { cat "$NOTES"; printf '\n## audit_no_such_gate\n\nA note whose gate does not exist.\n'; } > "$1"
}
L1="$(first_legs)"
if vs_ctl_is dropped-declaration; then
    mkdir -p "$W/in"; cp tests/*.sh "$W/in/"; SRC="$W/in"; neuter_decl "$SRC" "$L1"
elif vs_ctl_is silent-legs; then
    mkdir -p "$W/in"; cp tests/*.sh "$W/in/"; SRC="$W/in"; neuter_source "$SRC" "$L1"
elif vs_ctl_is leaky-helper; then
    leak_copy "$W/lib_sheet.sh"; LIB="$W/lib_sheet.sh"
elif vs_ctl_is orphan-note; then
    orphan_copy "$W/notes_in.md"; NOTES="$W/notes_in.md"
elif vs_ctl_is debt-regrown; then
    cp "$DEBT" "$W/debt"; echo "$L1" >> "$W/debt"; SDEBT="$W/debt"
elif vs_ctl_is span-debt-regrown; then
    cp "$SPAN_DEBT" "$W/sdebt"; echo "$SPANNED" >> "$W/sdebt"; SSPAN="$W/sdebt"
elif vs_ctl_is span-dropped; then
    mkdir -p "$W/in"; cp tests/*.sh "$W/in/"; SRC="$W/in"; neuter_span "$SRC" "$SPANNED"
fi

echo "== test_sheet_census: every emulator gate declares its comparative sheet, or is on the debt list (#291) =="
echo "== 1. the census"
census "$SRC" "$SDEBT" > "$W/got.txt"; rc=$?
nl="$(command grep -c '^legs	' "$W/got.txt")"; nn="$(command grep -c '^none	' "$W/got.txt")"
nr="$(command grep -c '^no-reference-leg	' "$W/got.txt")"; nd="$(command grep -c '^debt	' "$W/got.txt")"
np="$(command grep -c '^no-picture	' "$W/got.txt")"
echo "  measured: $nl legs, $nr no-reference-leg, $np no-picture, $nn none, $nd on the debt list"
echo "NOTE: sheet.legs $nl no-reference-leg $nr no-picture $np none $nn debt $nd"
nsd="$(command grep -cv '^#' "$SSPAN")"
echo "  span debt: $nsd of the $nl legs gates still show one frame per judged event ($SSPAN)"
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
check no-picture "a no-picture line (ruled 2026-10-18, D4)" "# SHEET: no-picture — a corpus-wide summary, no frame to show"
check ERR "no-picture without a reason" "# SHEET: no-picture"
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
# a tap row's env keeps a value's own ';' (read_tap's RTAP joins ranges with it; 14z-205)
tapf="$(mk tap "$(printf '%s\ntap%sa%sx%stests/lua/read_tap.lua%sRTAP=ff8558,2;ff8506,2;WINDOW=0,10\n' "$good" "$T" "$T" "$T" "$T")")"
got="$(python3 -c "import sys; sys.path.insert(0, 'tools'); import proof_sheets as p; s = p.read_sheet(sys.argv[1])[0]; e = s['legs']['x']['tap']['env']; print(e['RTAP'] + '|' + e['WINDOW'])" "$(dirname "$tapf")" 2>&1)"
if [ "$got" = "ff8558,2;ff8506,2|0,10" ]; then ok "a tap env value keeps its own ';': $got"; else nope "a tap env value lost its ';': $got"; fi
rs "a tap env that starts without NAME=" refused "$(mk tapbad "$(printf '%s\ntap%sa%sx%stests/lua/read_tap.lua%sff8558,2\n' "$good" "$T" "$T" "$T" "$T")")"

echo "== 3b. the page names each gate's own verdict line (tools/proof_sheets.py verdict_line; 14z-205)"
vl() {  # vl <name> <want> <log text> — want is the line the page must show, or `no verdict line`
    got="$(printf '%s' "$3" | python3 -c "import sys; sys.path.insert(0, 'tools'); import proof_sheets as p; print(p.verdict_line(sys.stdin.read()))")"
    if [ "$got" = "$2" ]; then ok "$1: $got"; else nope "$1: got '$got', want '$2'"; fi
}
vl "a column-0 verdict" "PASS: a" "  ok: x
PASS: a"
vl "the last of two" "FAIL: b (1)" "PASS: a
FAIL: b (1)"
vl "a prefixed verdict" "AUDIT PASS (defect state as expected)" "  ok: x
AUDIT PASS (defect state as expected)"
vl "a named verdict" "FLICKER ATTRIBUTION: PASS" "FLICKER ATTRIBUTION: PASS"
vl "a control line is not a verdict" "no verdict line" "CONTROL FIRED: x — the tool would PASS"
vl "an indented line is not a verdict" "no verdict line" "  ok: PASS"

echo "== 3c. the sheet notes (docs/project/sheet_notes.md, read by tools/proof_sheets.py sheet_notes and note_html; 14z-205)"
orphans() {  # orphans <notes file> -> every section whose gate has no tests/<gate>.sh
    python3 -c "import sys; sys.path.insert(0, 'tools'); import proof_sheets as p, os
for g in sorted(p.sheet_notes(sys.argv[1])):
    os.path.exists('tests/%s.sh' % g) or print(g)" "$1"
}
nnotes="$(python3 -c "import sys; sys.path.insert(0, 'tools'); import proof_sheets as p; print(len(p.sheet_notes(sys.argv[1])))" "$NOTES")"
orp="$(orphans "$NOTES" | tr '\n' ' ')"
if [ -z "$orp" ]; then ok "$nnotes note(s), each naming a gate that exists"; else nope "a note names no gate that exists: $orp"; fi
nh() {  # nh <name> <want substring> <note text>
    got="$(printf '%s' "$3" | python3 -c "import sys; sys.path.insert(0, 'tools'); import proof_sheets as p; print(p.note_html(sys.stdin.read()))")"
    case "$got" in *"$2"*) ok "$1" ;; *) nope "$1: got '$got', want it to contain '$2'" ;; esac
}
nh "an issue number is a link" '<a href="https://github.com/DefinitelyFrenchName/VampireSaved/issues/191">#191</a>' "built for #191, not"
nh "bold and code" '<b>Why.</b> see <code>a_b.sh</code>' '**Why.** see `a_b.sh`'
nh "bullets, with a continued line" '<ul><li>one two</li><li>three</li></ul>' "- one
  two
- three"
nh "two paragraphs" '<p>a</p><p>b</p>' "a

b"
nh "markup is escaped" '&lt;script&gt;' "<script>"
nh "an HTML entity's # is not an issue" '&#x27;' "it's"

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

orphan_copy "$W/notes_orphan.md"
if orphans "$W/notes_orphan.md" | command grep -qx audit_no_such_gate; then
    vs_ctl_fired orphan-note "a notes copy with a section for audit_no_such_gate is named"
else vs_ctl_dead orphan-note "a notes copy with a section for a missing gate was not named"; nope "control orphan-note"; fi

cp "$SPAN_DEBT" "$W/sdebt2"; echo "$SPANNED" >> "$W/sdebt2"
if census tests "$DEBT" "$W/sdebt2" | command grep -q "^PROBLEM	$SPANNED: writes spans but is still on the span debt list"; then
    vs_ctl_fired span-debt-regrown "$SPANNED added back to the span debt list is named as a row that should be gone"
else vs_ctl_dead span-debt-regrown "$SPANNED added back to the span debt list was not named"; nope "control span-debt-regrown"; fi
mkdir -p "$W/t3"; cp tests/*.sh "$W/t3/"; neuter_span "$W/t3" "$SPANNED"
if census "$W/t3" "$DEBT" "$SPAN_DEBT" | command grep -q "^PROBLEM	$SPANNED: a \`legs\` gate with no span"; then
    vs_ctl_fired span-dropped "$SPANNED with its span rows neutered is named: no span, not on the span debt list"
else vs_ctl_dead span-dropped "$SPANNED with its span rows neutered was not named"; nope "control span-dropped"; fi

leak_copy "$W/leak.sh"
if [ -n "$(leaks "$W/leak.sh")" ]; then vs_ctl_fired leaky-helper "a copy whose row loop uses _sf is named: $(leaks "$W/leak.sh" | tr '\n' ' ')"
else vs_ctl_dead leaky-helper "a copy whose row loop uses _sf was not named"; nope "control leaky-helper"; fi

[ "$bad" = 0 ] && { echo "PASS: test_sheet_census — $nl legs, $nr no-reference-leg, $np no-picture, $nn none, $nd on the debt list"; exit 0; }
echo "FAIL: test_sheet_census ($bad)"; exit 1
