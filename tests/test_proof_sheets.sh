#!/bin/sh
# test_proof_sheets.sh — THE COMPARATIVE SHEETS' PROOF IS ITSELF TESTED ([VSP-19]; GitHub #291 slice S1, 14z-204).
#
# WHAT: tools/proof_sheets.py proves a picture only when the re-run leg's state at that frame equals what the gate
#   logged there: a moment on the gate's own checksum log is PROVEN, the same checksum claimed one frame later is NOT
#   THE JUDGED RUN, a correct field expectation is PROVEN and one value off by one is refused, a basis `none` is shown
#   UNPROVEN; and tests/lua/sheet_capture.lua's masked checksum equals replay.lua's frozen log frame for frame; a
#   sheet asking for anchors gets every anchor its leg reaches, each proven on the log, and a set ANCHOR_MAX is said on
#   the sheet, never silent (rule-checker run 2026-10-18-1118: a silent cap of 16 dropped rounds); and a SHEET_OUT
#   named by a RELATIVE path is proven as an absolute one (14z-205: each capture runs in its own work directory, so an
#   unresolved relative path made every capture fail and every picture NOT THE JUDGED RUN); and the EVENT basis (D2,
#   ruled 2026-10-18): a leg re-run under its gate's own tap instrument (tests/lua/sheet_tap_capture.lua) is
#   EVENT-PROVEN only where its log lines in the window equal the gate's — a one-frame shift and a wrong value are
#   refused, an empty window is UNPROVEN; and S3 (14z-205: "ours" is built from the commit): an `ours` leg is
#   NOT THE JUDGED RUN unless it ran on a build made in the clean checkout's build/ (a rom path outside the checkout,
#   or a tracked path in it, is refused; a built one keeps its own verdict), a build whose fingerprint is not the
#   commit's frozen reference refuses the run, a checkout at another commit is refused for reuse, and an unknown
#   --host is refused; and a CONTROL BUILD (#291 S4-A, 14z-206, Q5): a gate's `# SHEET-BUILD:` line is read (a
#   malformed one refused), the freeze tag's own `program key` is read, and a control track built off it is refused;
#   and a leg's RELATIVE rom path (the registry's %STOCK_RP% expands to one) is read as absolute against the tree its
#   gate ran in (14z-206: a capture runs in its own work directory, where `build/m5_stock22/rompath` named nothing and
#   test_gfx_menus' ours leg re-ran on pristine vsavj from ROMDIR); and #291 S4 (14z-206): each picture's "fighters on
#   screen" is read from the game's state (tests/lua/screen_state.lua) — the select screen, the round-end white and the
#   stage before the drop-in read no, the round start and the round read yes, the predicate chosen on 118 pictures
#   classed by eye and confirmed on 201 (build/agent206/t291/s4b/, local); a SPAN shows about 9 frames of a judged
#   event, each proven on the
#   moment's own basis (the log, or the gate's own per-frame field trace — an altered trace frame refused), a basis that
#   cannot prove each frame refused; an INPUTS sheet photographs at most 18 frames IN EACH ROUND where the replay
#   starts (or, short of that, holds) an input, each proven on the log; and the page defines every tag it shows (an undefined upper-case verdict
#   word is listed at its top), splits a gate's page by sheet above PAGE_TILES pictures, moves each picture into pics/
#   once, and puts a judged frame without a fighter on any leg into the labelled "Judged frames without fighters" strip
#   (the maintainer's Q3).
# HOW: a fixture SHEET_OUT on pristine vsavj (02_demitri_vs_cpu to frame 3001): the frozen masked vanilla log
#   (tests/expected/vsavj/masked-v2) is the "gate's log", the masked-v2 mask the leg's; the field values are taken
#   from tests/lua/field_trace.lua run live on the same inputs; `proof_sheets.py prove` on the fixture; one control.
# EXPECTS: the six verdicts above, section 6's fighters readings, section 7's spans, section 8's inputs and section 9's
#   page checks, each picture present, the S3 refusals (section 6, no build: the checks run on
#   section 3's proven sheet re-labelled `ours`, a scratch git checkout and the tool's own functions); PASS. It does not claim any gate's sheet is complete — the
#   census (tests/test_sheet_census.sh) and each gate's own verdict do that part.
# FOLLOWS: tools/proof_sheets.py tests/lua/sheet_capture.lua tests/lua/pokes_spec.lua tests/lua/field_trace.lua
#   tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log tests/expected/merged1/mask
#   tests/replays/02_demitri_vs_cpu.rpl tests/lib/controls.sh tools/run_mame.sh tools/setup_mame.sh emu/mame-patches/
#   tests/lua/sheet_tap_capture.lua tests/lua/read_tap.lua build/manifest/ tests/audit_landing_sound.sh
#   tests/lua/screen_state.lua
#
# SHEET: none — the sheet tool's own ground truth on pristine vsavj; it compares no leg of ours against a reference set
# MUST-FIRE: shadow-tool: cap-ignored — a copy of tools/proof_sheets.py that drops the capture's ACAP line must leave the capped sheet with no cap note, so the note rests on the line (in-gate: the shadow is run on the capped fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: relative-unresolved — a copy of tools/proof_sheets.py that does not resolve the SHEET_OUT path must fail the relative-path moment (its capture cannot find the replay), so that PROVEN rests on the resolve (in-gate: the shadow is run on a relative fixture path; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: count-only — a copy of tools/proof_sheets.py whose event proof compares only the NUMBER of lines in the window must EVENT-PROVE the moment whose logged value was altered, so the event basis rests on the lines themselves (in-gate: the shadow is run on the event fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: build-blind — a copy of tools/proof_sheets.py whose commit check accepts any rom path must leave the ours leg that ran outside the clean checkout PROVEN, so S3's refusal rests on the check (in-gate: the shadow is run on the re-labelled sheet; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: fingerprint-blind — a copy of tools/proof_sheets.py whose build check never compares fingerprints must accept a track built off the commit's frozen reference, so the run's refusal rests on the comparison (in-gate: the shadow's check_builds on the mismatched set; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: tag-key-blind — a copy of tools/proof_sheets.py whose control check never compares the built track with the freeze tag's program key must accept a control build off its tag, so the refusal rests on the comparison (#291 S4-A; in-gate: the shadow's control_check on the mismatched key; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: rompath-unresolved — a copy of tools/proof_sheets.py that keeps a leg's rom path as the gate wrote it must leave a relative element relative, so the capture's rom path rests on the resolve (#291 S4-A; in-gate: the shadow's read_sheet on a fixture leg with a relative element; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: fighters-blind — a copy of tools/proof_sheets.py whose fighters() always says yes must read the bare stage before the drop-in as showing the fighters, so the no-fighter strip rests on the measured predicate (#291 S4-B; in-gate: the shadow is run on the fighters fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: span-blind — a copy of tools/proof_sheets.py whose fields span never compares the gate's trace must prove the frame whose trace value was altered, so each span frame's proof rests on the trace (#291 S4-D; in-gate: the shadow is run on the span fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: inputs-unbounded — a copy of tools/proof_sheets.py that takes the whole replay as one round must pick input frames outside the round, so the in-round picks rest on the anchors (#291 S4-E; in-gate: the shadow is run on the inputs fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: undefined-tag — a copy of tools/proof_sheets.py whose tag census finds nothing must leave the fixture's undefined verdict word unlisted, so the legend's completeness rests on the census (#291 S4-C; in-gate: the shadow draws the fixture page; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: no-split — a copy of tools/proof_sheets.py that never starts a new page part must put both fixture sheets on one page, so the paging rests on the split (#291 S4-F; in-gate: the shadow draws the fixture page; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: strip-ignored — a copy of tools/proof_sheets.py whose no-fighter test is always false must leave the white frame on the sheet, so the labelled strip rests on the test (#291 Q3; in-gate: the shadow draws the fixture page; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: frame-blind — a copy of tools/proof_sheets.py that accepts a logged checksum found at ANY captured frame, instead of at the moment's own frame, must prove the moment shifted by one frame, so the one-frame refusal rests on the frame-exact lookup (in-gate: the shadow is run on the same fixture; mode: the shadow is the tool under test and the gate FAILs)
#
# Usage: ROMDIR=... [MAME_BIN=...] tests/test_proof_sheets.sh   # emulator tier (MAME), ~17 s (measured 14z-204)
set -u
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN ROMDIR
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
. "$REPO/tests/lib/controls.sh"
vs_ctl_mode "$0"
LOG=tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log
MASK="$(cat tests/expected/merged1/mask)"
RPL=tests/replays/02_demitri_vs_cpu.rpl
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
bad=0; ok() { echo "  ok    $1"; }; nope() { echo "  FAIL  $1"; bad=$((bad + 1)); }

# THE SHADOW (one function, the in-gate control and the mode): checksum proof by membership, not by frame
frame_blind() {  # frame_blind <out.py>
    sed -e 's/        got = cap\["C"\]\.get(fr)$/        got = exp if exp in cap["C"].values() else cap["C"].get(fr)/' \
        -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c 'exp in cap\["C"\].values()' "$1")" = 1 ] || { echo "the frame lookup was not found to replace" >&2; return 1; }
}
cap_ignored() {  # cap_ignored <out.py> — the shadow that drops the ACAP line
    sed -e 's/elif t\[0\] == "ACAP":/elif t[0] == "XACAP-IGNORED":/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c 'XACAP-IGNORED' "$1")" = 1 ] || { echo "the ACAP branch was not found to drop" >&2; return 1; }
}
relative_unresolved() {  # relative_unresolved <out.py> — the shadow that leaves the SHEET_OUT path as given
    sed -e 's/    sheet_dir = Path(sheet_dir)\.resolve()  #/    sheet_dir = Path(sheet_dir)  #/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '    sheet_dir = Path(sheet_dir)  #' "$1")" = 1 ] || { echo "the path resolve was not found to drop" >&2; return 1; }
}
count_only() {  # count_only <out.py> — the shadow whose event proof compares line counts, not lines
    sed -e 's/        if want == got:$/        if len(want) == len(got):/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '        if len(want) == len(got):' "$1")" = 1 ] || { echo "the event comparison was not found to replace" >&2; return 1; }
}
build_blind() {  # build_blind <out.py> — the shadow whose commit check accepts every rom path
    sed -e 's/                why = ours_build_problem(lg\["rompath"\], tree)$/                why = None/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '                why = None$' "$1")" = 1 ] || { echo "the commit check was not found to drop" >&2; return 1; }
}
fingerprint_blind() {  # fingerprint_blind <out.py> — the shadow whose build check never compares a fingerprint
    sed -e 's/        elif built\.get(t) != want:$/        elif False:/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '        elif False:' "$1")" = 1 ] || { echo "the fingerprint comparison was not found to drop" >&2; return 1; }
}
tag_key_blind() {  # tag_key_blind <out.py> — the shadow whose control check never compares the tag's program key
    sed -e 's/    if built != want:$/    if False:/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '    if False:$' "$1")" = 1 ] || { echo "the tag-key comparison was not found to drop" >&2; return 1; }
}
rompath_unresolved() {  # rompath_unresolved <out.py> — the shadow that keeps a leg's rom path as written
    sed -e 's/"rompath": abs_rompath(f\[5\])/"rompath": f[5]/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '"rompath": f\[5\]' "$1")" = 1 ] || { echo "the rom path resolve was not found to drop" >&2; return 1; }
}
fighters_blind() {  # fighters_blind <out.py> — the shadow whose fighters() always says yes
    sed -e 's/^    return "yes" if sc.get("m4") == 0x40000 and sc.get("m8") in MATCH_M8 and sc\["fp"\] >= 1 else "no"$/    return "yes"  # shadow/' \
        -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '# shadow$' "$1")" = 1 ] || { echo "the fighters predicate was not found to replace" >&2; return 1; }
}
span_blind() {  # span_blind <out.py> — the shadow whose fields span never compares the trace
    sed -e 's/^        return prove({"frame": fr, "basis": "fields", "expect": ",".join(.*$/        return "PROVEN", "shadow: not compared"/' \
        -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c 'shadow: not compared' "$1")" = 1 ] || { echo "the span's fields proof was not found to replace" >&2; return 1; }
}
inputs_unbounded() {  # inputs_unbounded <out.py> — the shadow that takes the whole replay as one round
    sed -e 's/^    for k, (a, b) in enumerate(rounds(cap\["A"\], lg\["frames"\])):$/    for k, (a, b) in enumerate([(0, lg["frames"])]):  # shadow/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '# shadow$' "$1")" = 1 ] || { echo "the rounds lookup was not found to replace" >&2; return 1; }
}
undefined_tag() {  # undefined_tag <out.py> — the shadow whose tag census finds nothing
    sed -e 's/^    return sorted({w for w in TAG.findall(verdict or "").*$/    return []  # shadow/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '# shadow$' "$1")" = 1 ] || { echo "the tag census was not found to replace" >&2; return 1; }
}
no_split() {  # no_split <out.py> — the shadow that never starts a new page part
    sed -e 's/^            if cur and cur_n + n > PAGE_TILES:$/            if False:  # shadow/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '# shadow$' "$1")" = 1 ] || { echo "the page split was not found to replace" >&2; return 1; }
}
strip_ignored() {  # strip_ignored <out.py> — the shadow whose no-fighter test is always false
    sed -e 's/^    return bool(vals) and all(v == "no" for v in vals)$/    return False  # shadow/' -e "s|^ROOT = .*|ROOT = Path('$REPO')|" tools/proof_sheets.py > "$1"
    [ "$(command grep -c '# shadow$' "$1")" = 1 ] || { echo "the no-fighter test was not found to replace" >&2; return 1; }
}
TOOL=tools/proof_sheets.py
if vs_ctl_is fighters-blind; then fighters_blind "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is span-blind; then span_blind "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is inputs-unbounded; then inputs_unbounded "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is undefined-tag; then undefined_tag "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is no-split; then no_split "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is strip-ignored; then strip_ignored "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is rompath-unresolved; then rompath_unresolved "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is tag-key-blind; then tag_key_blind "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is build-blind; then build_blind "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is fingerprint-blind; then fingerprint_blind "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is count-only; then count_only "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is relative-unresolved; then relative_unresolved "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is frame-blind; then frame_blind "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi
if vs_ctl_is cap-ignored; then cap_ignored "$W/shadow.py" || exit 3; TOOL="$W/shadow.py"; fi

echo "== test_proof_sheets: a picture is proven only on the run its gate judged (#291) =="
echo "== 1. the field values, live (tests/lua/field_trace.lua on the same inputs)"
( cd "$W" && MAME_SANDBOX="$W/ft" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$RPL" FIELDS="ff8410:w:x,ff8810:w:x2,ff8109:b:timer" \
    FIELD_OUT="$W/ft.txt" FIELD_FROM=3000 FIELD_TO=3000 FRAMES=3001 \
    "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/ft.log" 2>&1 ) </dev/null
FT="$(awk '$1 == "F" && $2 == 3000' "$W/ft.txt")"
[ -n "$FT" ] || { echo "FAIL: field_trace produced no sample at 3000 ($W/ft.log)"; exit 1; }
x="$(printf '%s' "$FT" | sed 's/.* x=\(-*[0-9]*\).*/\1/')"; x2="$(printf '%s' "$FT" | sed 's/.*x2=\(-*[0-9]*\).*/\1/')"
tm="$(printf '%s' "$FT" | sed 's/.*timer=\(-*[0-9]*\).*/\1/')"
ok "f3000: x=$x x2=$x2 timer=$tm"

echo "== 2. the fixture SHEET_OUT"
S="$W/sheet"; mkdir -p "$S/legs"; cp "$RPL" "$S/legs/gt.v.rpl"; cp "$LOG" "$S/legs/gt.v.log"
c650="$(awk '$1 == 650 {print $2}' "$LOG")"; c950="$(awk '$1 == 950 {print $2}' "$LOG")"
[ -n "$c650" ] && [ -n "$c950" ] || { echo "FAIL: the frozen log has no f650/f950"; exit 1; }
T="	"
{ echo "sheet${T}gt${T}ground truth${T}-${T}-${T}-"
  echo "leg${T}gt${T}v${T}vsavj${T}vsavj${T}$ROMDIR${T}legs/gt.v.rpl${T}-${T}3001${T}legs/gt.v.log${T}$MASK"
  echo "moment${T}gt${T}log650${T}on the log${T}-${T}-";        echo "at${T}gt${T}log650${T}v${T}650${T}log${T}-"
  echo "moment${T}gt${T}shift${T}shifted by one${T}-${T}-";     echo "at${T}gt${T}shift${T}v${T}651${T}ram${T}$c650"
  echo "moment${T}gt${T}ram950${T}a given checksum${T}-${T}-";  echo "at${T}gt${T}ram950${T}v${T}950${T}ram${T}$c950"
  echo "moment${T}gt${T}fields${T}fields${T}-${T}-";            echo "at${T}gt${T}fields${T}v${T}3000${T}fields${T}ff8410:w=$x,ff8810:w=$x2,ff8109:b=$tm"
  echo "moment${T}gt${T}fieldoff${T}a field off${T}-${T}-";     echo "at${T}gt${T}fieldoff${T}v${T}3000${T}fields${T}ff8410:w=$((x + 1)),ff8810:w=$x2"
  echo "moment${T}gt${T}none${T}nothing logged${T}-${T}-";      echo "at${T}gt${T}none${T}v${T}700${T}none${T}-"
} > "$S/sheet.tsv"
ok "six moments on one leg (pristine vsavj, masked like the frozen log)"

prove() {  # prove <tool> <dir> -> sid<TAB>label<TAB>leg<TAB>fN<TAB>status<TAB>why
    python3 "$1" prove "$2" --jobs 1
}
want() {  # want <file> <label> <status>
    got="$(awk -F'\t' -v l="$2" '$2 == l {print $5}' "$1")"
    if [ "$got" = "$3" ]; then ok "$2: $got"; else nope "$2: got '$got', want '$3' ($(awk -F'\t' -v l="$2" '$2 == l {print $6}' "$1"))"; fi
}

echo "== 3. the verdicts ($TOOL)"
prove "$TOOL" "$S" > "$W/got.tsv" 2> "$W/got.err" || { nope "prove refused: $(tail -1 "$W/got.tsv")"; }
want "$W/got.tsv" "on the log" PROVEN
want "$W/got.tsv" "shifted by one" "NOT THE JUDGED RUN"
want "$W/got.tsv" "a given checksum" PROVEN
want "$W/got.tsv" "fields" PROVEN
want "$W/got.tsv" "a field off" "NOT THE JUDGED RUN"
want "$W/got.tsv" "nothing logged" UNPROVEN
python3 - "$S/proof.json" > "$W/pics.txt" <<'PYP'
import json, os, sys
d = json.load(open(sys.argv[1]))
cells = [x for s in d for c in s["cols"] for x in c["cells"].values()]
print(sum(1 for x in cells if x["pic"] and os.path.exists(x["pic"])), len(cells))
PYP
read -r np nc < "$W/pics.txt"
[ "$np" = "$nc" ] && [ "$nc" = 6 ] && ok "every moment has its picture ($np of $nc)" || nope "pictures: $np of $nc"

echo "== 3b. a SHEET_OUT named by a relative path ($TOOL, from the repository root)"
R3="$W/rel"; mkdir -p "$R3/legs"; cp "$S/legs/gt.v.rpl" "$S/legs/gt.v.log" "$R3/legs/"
command grep -v -e '	shift	' -e '	ram950	' -e '	fields	' -e '	fieldoff	' -e '	none	' "$S/sheet.tsv" > "$R3/sheet.tsv"
RREL="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$R3" "$REPO")"
prove_rel() {  # prove_rel <tool> <relative dir> -> the label/status rows, run from the repository root
    ( cd "$REPO" && python3 "$1" prove "$2" --jobs 1 )
}
prove_rel "$TOOL" "$RREL" > "$W/rel.tsv" 2>&1
want "$W/rel.tsv" "on the log" PROVEN

echo "== 4. anchors: every one the leg reaches, each proven on the log; a set ANCHOR_MAX is said"
A="$W/anch"; mkdir -p "$A/legs"; cp "$S/legs/gt.v.rpl" "$S/legs/gt.v.log" "$A/legs/"
{ echo "sheet${T}gt${T}anchors${T}-${T}-${T}-"
  echo "leg${T}gt${T}v${T}vsavj${T}vsavj${T}$ROMDIR${T}legs/gt.v.rpl${T}-${T}3001${T}legs/gt.v.log${T}$MASK"
  echo "anchors${T}gt"; } > "$A/sheet.tsv"
cp -R "$A" "$W/anchcap"
prove "$TOOL" "$A" > "$W/anch.tsv" 2>&1
na="$(awk -F'\t' '$2 ~ /^anchor: / {n++} END {print n + 0}' "$W/anch.tsv")"
np_="$(awk -F'\t' '$2 ~ /^anchor: / && $5 == "PROVEN" {n++} END {print n + 0}' "$W/anch.tsv")"
if [ "$na" -ge 2 ] && [ "$na" = "$np_" ] && command grep -q 'anchor: round start' "$W/anch.tsv"; then
    ok "$na anchors to f3001, all PROVEN on the frozen log, the round start among them ($(awk -F'\t' '$2 ~ /^anchor: / {printf "%s %s; ", $2, $4}' "$W/anch.tsv"))"
else nope "anchors: $na found, $np_ proven, round start $(command grep -c 'anchor: round start' "$W/anch.tsv")"; fi
cap_note() {  # cap_note <dir> -> the sheet's cap notes, one per line
    python3 -c "import json, sys; [print(c) for s in json.load(open(sys.argv[1])) for c in s.get('capped', [])]" "$1/proof.json"
}
ANCHOR_MAX=$((na - 1)) prove "$TOOL" "$W/anchcap" > "$W/anchcap.tsv" 2>&1
nc_="$(awk -F'\t' '$2 ~ /^anchor: / {n++} END {print n + 0}' "$W/anchcap.tsv")"
note="$(cap_note "$W/anchcap")"
if [ "$nc_" = $((na - 1)) ] && [ -n "$note" ]; then ok "ANCHOR_MAX=$((na - 1)): $nc_ drawn and the sheet says so: $note"
else nope "ANCHOR_MAX=$((na - 1)): $nc_ drawn, note '$note' — a capped leg must say it was capped"; fi

echo "== 4b. the event basis (D2): a leg re-run under its own tap instrument, proven by its logged events"
E="$W/ev"; mkdir -p "$E/legs" "$E/files" "$W/evgate"
( cd "$W/evgate" && MAME_SANDBOX="$W/evgate/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$RPL" RTAP="ff8410,2" WINDOW="2000,2100" \
    TRACE_OUT="$W/evgate/t.txt" FRAMES=2200 "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/evgate/m.log" 2>&1 ) </dev/null
[ -s "$W/evgate/t.txt" ] || { echo "FAIL: the fixture's read_tap run wrote no log ($W/evgate/m.log)"; exit 1; }
cp "$RPL" "$E/legs/ev.v.rpl"; cp "$W/evgate/t.txt" "$E/files/gate.tap"
awk '$1 == "W" {$2 = $2 + 1} {print}' "$W/evgate/t.txt" > "$E/files/shift.tap"
awk '$1 == "W" && $2 >= 2195 && !done {$8 = "deadbeef"; done = 1} {print}' "$W/evgate/t.txt" > "$E/files/value.tap"
nev="$(awk '$1 == "W" && $2 >= 2195 && $2 <= 2199' "$W/evgate/t.txt" | wc -l | tr -d ' ')"
emp="$(awk '$1 == "W" {s[$2] = 1} END {for (f = 2101; f <= 2185; f++) {e = 1; for (g = f; g < f + 5; g++) if (g in s) e = 0; if (e) {print f; exit}}}' "$W/evgate/t.txt")"
[ "$nev" -ge 1 ] && [ -n "$emp" ] || { echo "FAIL: the fixture log has no event in f2195-2199 ($nev) or no empty 5-frame window ($emp)"; exit 1; }
{ echo "sheet${T}ev${T}event basis${T}-${T}-${T}-"
  echo "leg${T}ev${T}v${T}vsavj${T}vsavj${T}$ROMDIR${T}legs/ev.v.rpl${T}-${T}2200${T}-${T}-"
  echo "tap${T}ev${T}v${T}tests/lua/read_tap.lua${T}RTAP=ff8410,2;WINDOW=2000,2100;FRAMES=2200"
  echo "moment${T}ev${T}ok${T}events reproduced${T}-${T}-";   echo "at${T}ev${T}ok${T}v${T}2198${T}event${T}files/gate.tap:2195-2199"
  echo "moment${T}ev${T}sh${T}events shifted${T}-${T}-";      echo "at${T}ev${T}sh${T}v${T}2198${T}event${T}files/shift.tap:2195-2200"
  echo "moment${T}ev${T}va${T}a value altered${T}-${T}-";     echo "at${T}ev${T}va${T}v${T}2198${T}event${T}files/value.tap:2195-2199"
  echo "moment${T}ev${T}em${T}no event logged${T}-${T}-";     echo "at${T}ev${T}em${T}v${T}$((emp + 2))${T}event${T}files/gate.tap:$emp-$((emp + 4))"
} > "$E/sheet.tsv"
cp -R "$E" "$W/ev_ctl"
prove "$TOOL" "$E" > "$W/ev.tsv" 2>&1
want "$W/ev.tsv" "events reproduced" EVENT-PROVEN
want "$W/ev.tsv" "events shifted" "NOT THE JUDGED RUN"
want "$W/ev.tsv" "a value altered" "NOT THE JUDGED RUN"
want "$W/ev.tsv" "no event logged" UNPROVEN
# the wrapper's frame N is replay.lua's frame N: its f2198 picture equals tests/lua/sheet_capture.lua's f2198, and differs
# from its f2197 and f2199 (the probe of 14z-205, build/agent205/d2/, captured here)
( cd "$W" && mkdir -p sc && cd sc && MAME_SANDBOX="$W/sc/sb" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$RPL" SNAP_FRAMES=2197,2198,2199 \
    CAPTURE_OUT="$W/sc/cap.txt" "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/sheet_capture.lua" > "$W/sc/m.log" 2>&1 ) </dev/null
python3 - "$E/proof.json" "$W/sc" > "$W/frame.txt" <<'PYF'
import glob, json, sys
from pathlib import Path
from PIL import Image, ImageChops
d = json.load(open(sys.argv[1]))
pic = next(c["cells"]["v"]["pic"] for s in d for c in s["cols"] if c["label"] == "events reproduced")
snaps = {int(l.split()[2]): l.split()[1] for l in open(sys.argv[2] + "/cap.txt") if l.startswith("S ")}
w = Image.open(pic).convert("RGB")
same = {f: ImageChops.difference(w, Image.open(glob.glob("%s/sb/snap/*/%04d.png" % (sys.argv[2], int(n)))[0]).convert("RGB")).getbbox() is None for f, n in snaps.items()}
print(" ".join("%d=%s" % (f, "same" if v else "differs") for f, v in sorted(same.items())))
PYF
if [ "$(cat "$W/frame.txt")" = "2197=differs 2198=same 2199=differs" ]; then ok "the tap re-run's f2198 is sheet_capture's f2198 pixel for pixel, not its neighbours ($(cat "$W/frame.txt"))"
else nope "the tap re-run's picture is not frame-exact: $(cat "$W/frame.txt")"; fi

echo "== 4c. S3: ours is the commit's build ($TOOL; no build, no emulator)"
FT="$W/tree"; mkdir -p "$FT/build/manifest" "$FT/build/x/rompath"; : > "$FT/build/manifest/a.toml"
( cd "$FT" && git init -q && git add build/manifest/a.toml && git -c user.name=t -c user.email=t@t commit -qm t ) >/dev/null 2>&1 \
    || { echo "FAIL: could not make the scratch checkout"; exit 1; }
relabel() {  # relabel <proof.json> <rompath> <out.json> — section 3's proven sheet with its leg made `ours` on <rompath>
    python3 -c "import json, sys; d = json.load(open(sys.argv[1]))
for s in d:
    for l in s['legs']: l['role'] = 'ours'; l['rompath'] = sys.argv[2]
json.dump(d, open(sys.argv[3], 'w'))" "$1" "$2" "$3"
}
relabel "$S/proof.json" "$ROMDIR" "$W/c_out.json"; relabel "$S/proof.json" "$FT/build/x/rompath;$ROMDIR" "$W/c_in.json"
relabel "$S/proof.json" "$FT/build/manifest" "$W/c_tr.json"
python3 "$TOOL" commitcheck "$W/c_out.json" "$FT" > "$W/c_out.tsv" 2>&1
python3 "$TOOL" commitcheck "$W/c_in.json" "$FT" > "$W/c_in.tsv" 2>&1
python3 "$TOOL" commitcheck "$W/c_tr.json" "$FT" > "$W/c_tr.tsv" 2>&1
n_out="$(awk -F'\t' '$5 == "NOT THE JUDGED RUN" && $6 ~ /outside the clean checkout/' "$W/c_out.tsv" | wc -l | tr -d ' ')"
[ "$n_out" = 6 ] && ok "ours on ROMDIR (outside the checkout): 6 of 6 pictures NOT THE JUDGED RUN" || nope "ours outside the checkout: $n_out of 6 refused"
want "$W/c_in.tsv" "on the log" PROVEN
want "$W/c_in.tsv" "shifted by one" "NOT THE JUDGED RUN"
n_tr="$(awk -F'\t' '$5 == "NOT THE JUDGED RUN" && $6 ~ /tracked path/' "$W/c_tr.tsv" | wc -l | tr -d ' ')"
[ "$n_tr" = 6 ] && ok "ours on a tracked path of the checkout: 6 of 6 refused" || nope "ours on a tracked path: $n_tr of 6 refused"
s3_units() {  # s3_units <tool> -> one line per case: <case> <result>
    python3 - "$1" "$FT" <<'PYU'
import importlib.util, json, subprocess, sys
spec = importlib.util.spec_from_file_location("ps", sys.argv[1]); ps = importlib.util.module_from_spec(spec); spec.loader.exec_module(ps)
fp = {t: ("%02d" % i) * 20 for i, t in enumerate(ps.TRACKS)}
expect = {ps.TRACK_EXPECT[t]: v for t, v in fp.items()}
print("equal", len(ps.check_builds(dict(fp), expect)))
off = dict(fp); off["HUI"] = "ff" * 20
print("off", len(ps.check_builds(off, expect)), "HUI" in " ".join(ps.check_builds(off, expect)))
print("unfrozen", len(ps.check_builds(dict(fp), {k: v for k, v in expect.items() if k != "MERGED"})))
head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=sys.argv[2], capture_output=True, text=True).stdout.strip()
print("reuse-same", ps.make_checkout(head, sys.argv[2], None, True) is None)
print("reuse-other", ps.make_checkout("0" * 40, sys.argv[2], None, True) is not None)
print("no-reuse", ps.make_checkout(head, sys.argv[2], None, False) is not None)
# the clean checkout from a bundle whose one ref is outside refs/heads, as make_bundle writes it
b = sys.argv[2] + "/../c.bundle"; c = sys.argv[2] + "/../clone"
subprocess.run(["git", "update-ref", "refs/proof-sheets/run-1", head], cwd=sys.argv[2], check=True)
subprocess.run(["git", "bundle", "create", "-q", b, "refs/proof-sheets/run-1"], cwd=sys.argv[2], capture_output=True, check=True)
err = ps.make_checkout(head, c, b, False)
got = subprocess.run(["git", "rev-parse", "HEAD"], cwd=c, capture_output=True, text=True).stdout.strip()
print("clone", err is None and got == head and __import__("os").path.exists(c + "/build/manifest/a.toml"))
# the control build (#291 S4-A, Q5): the declaration, the tag's own key, the check against it
import os, tempfile
fx = tempfile.NamedTemporaryFile("w", suffix=".sh", delete=False)
fx.write("#!/bin/sh\n# x.sh\n# SHEET-BUILD: CTL_BUILD freeze/merged-m22 MERGED \u2014 the control leg\n# SHEET-BUILD: ctl freeze/x NOPE\nset -u\n")
fx.close()
cbs, errs = ps.parse_sheet_builds(fx.name); os.unlink(fx.name)
print("decl", len(cbs) == 1 and cbs[0]["var"] == "CTL_BUILD" and cbs[0]["tag"] == "freeze/merged-m22" and cbs[0]["track"] == "MERGED", len(errs))
real, rerrs = ps.parse_sheet_builds(str(ps.TOOL_ROOT / "tests/audit_landing_sound.sh"))
print("decl-real", [(c["var"], c["tag"], c["track"]) for c in real] == [("CTL_BUILD", "freeze/merged-m22", "MERGED")] and not rerrs)
key = ps.tag_program_key("freeze/merged-m22")
print("tag-key", key == "110467a7ec1cf73d106dce59284be344349e0953")
print("ctl-equal", len(ps.control_check("freeze/merged-m22", "MERGED", key, key)))
print("ctl-off", len(ps.control_check("freeze/merged-m22", "MERGED", "ff" * 20, key)))
print("ctl-nokey", len(ps.control_check("freeze/x", "MERGED", key, None)))
PYU
}
s3_units "$TOOL" > "$W/units.txt" 2>&1
u() { awk -v c="$1" '$1 == c {$1 = ""; sub(/^ /, ""); print}' "$W/units.txt"; }
[ "$(u equal)" = 0 ] && ok "five tracks equal to the commit's frozen references: accepted" || nope "equal tracks: $(u equal) problem(s)"
[ "$(u off)" = "1 True" ] && ok "a track built off its frozen reference: the run is refused, the track named" || nope "a track off its reference: '$(u off)'"
[ "$(u unfrozen)" = 1 ] && ok "a track the commit freezes no reference for: refused" || nope "an unfrozen track: '$(u unfrozen)'"
[ "$(u reuse-same)" = True ] && [ "$(u reuse-other)" = True ] && [ "$(u no-reuse)" = True ] \
    && ok "--reuse-tree takes only a clean checkout of the same commit; an existing tree without it is refused" \
    || nope "checkout reuse: same $(u reuse-same), other $(u reuse-other), no-reuse $(u no-reuse)"
[ "$(u clone)" = True ] && ok "the clean checkout from a bundle whose ref is not a branch lands on the commit" || nope "clone from the bundle: '$(u clone)'"
[ "$(u decl)" = "True 1" ] && [ "$(u decl-real)" = True ] \
    && ok "a gate's # SHEET-BUILD: line is read (audit_landing_sound's: CTL_BUILD freeze/merged-m22 MERGED), a malformed one refused" \
    || nope "the control-build declaration: fixture '$(u decl)', audit_landing_sound '$(u decl-real)'"
[ "$(u tag-key)" = True ] && ok "freeze/merged-m22's own program key is read from its tag: 110467a7" || nope "the tag's program key: '$(u tag-key)'"
[ "$(u ctl-equal)" = 0 ] && [ "$(u ctl-off)" = 1 ] && [ "$(u ctl-nokey)" = 1 ] \
    && ok "a control track equal to its tag's key is accepted; one off it, or a tag with no key, is refused" \
    || nope "the control check: equal $(u ctl-equal), off $(u ctl-off), no key $(u ctl-nokey)"
rp_unit() {  # rp_unit <tool> -> "<resolved rom path>" for a fixture leg written `build/x/rompath;$ROMDIR`
    RPD="$W/rp_$(basename "$1" .py)"; rm -rf "$RPD"; mkdir -p "$RPD"
    awk -F'\t' -v OFS='\t' -v r="build/x/rompath;$ROMDIR" '$1 == "leg" {$6 = r} {print}' "$S/sheet.tsv" > "$RPD/sheet.tsv"
    python3 - "$1" "$RPD" <<'PYR'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("ps", sys.argv[1]); ps = importlib.util.module_from_spec(spec); spec.loader.exec_module(ps)
print(ps.read_sheet(sys.argv[2])[0]["legs"]["v"]["rompath"])
PYR
}
rpg="$(rp_unit "$TOOL" 2>&1)"
[ "$rpg" = "$REPO/build/x/rompath;$ROMDIR" ] && ok "a leg's relative rom path element is read against the gate's tree; the absolute one is kept" \
    || nope "the relative rom path: read as '$rpg'"
python3 "$TOOL" run HEAD --host nosuch > "$W/host.txt" 2>&1; hrc=$?
[ "$hrc" = 2 ] && command grep -q "^REFUSED: unknown host 'nosuch'" "$W/host.txt" && ok "an unknown --host is refused (exit 2)" \
    || nope "unknown host: exit $hrc, $(head -1 "$W/host.txt")"

unset ANCHOR_MAX   # section 4's `ANCHOR_MAX=... prove` outlives the call: in a POSIX sh a prefix assignment to a function persists
echo "== 6. S4-B: fighters on screen, read from the game's state (#291, chosen 14z-206 on 118 pictures classed by eye, confirmed on 201)"
B="$W/fight"; mkdir -p "$B/legs"; cp "$S/legs/gt.v.rpl" "$S/legs/gt.v.log" "$B/legs/"
{ echo "sheet${T}gt${T}fighters${T}-${T}-${T}-"
  echo "leg${T}gt${T}v${T}vsavj${T}vsavj${T}$ROMDIR${T}legs/gt.v.rpl${T}-${T}3001${T}legs/gt.v.log${T}$MASK"
  echo "moment${T}gt${T}sel${T}the select screen${T}-${T}-";       echo "at${T}gt${T}sel${T}v${T}889${T}log${T}-"
  echo "moment${T}gt${T}white${T}the round-end white${T}-${T}-";   echo "at${T}gt${T}white${T}v${T}2090${T}log${T}-"
  echo "moment${T}gt${T}bare${T}the stage before the drop-in${T}-${T}-"; echo "at${T}gt${T}bare${T}v${T}2145${T}log${T}-"
  echo "moment${T}gt${T}start${T}the round start${T}-${T}-";       echo "at${T}gt${T}start${T}v${T}2328${T}log${T}-"
  echo "moment${T}gt${T}fight${T}in the round${T}-${T}-";          echo "at${T}gt${T}fight${T}v${T}2900${T}log${T}-"
} > "$B/sheet.tsv"
cp -R "$B" "$W/fight_ctl"
prove "$TOOL" "$B" > "$W/fight.tsv" 2>&1
wantf() {  # wantf <file> <label> <fighters>
    got="$(awk -F'\t' -v l="$2" '$2 == l {print $5 "/" $7}' "$1")"
    if [ "$got" = "PROVEN/$3" ]; then ok "$2: fighters $3"; else nope "$2: got '$got', want 'PROVEN/$3'"; fi
}
wantf "$W/fight.tsv" "the select screen" no
wantf "$W/fight.tsv" "the round-end white" no
wantf "$W/fight.tsv" "the stage before the drop-in" no
wantf "$W/fight.tsv" "the round start" yes
wantf "$W/fight.tsv" "in the round" yes

echo "== 7. S4-D: a span — about 9 frames of a judged event, each proven on the moment's own basis"
( cd "$W" && MAME_SANDBOX="$W/ft2" MAME_ROMPATH="$ROMDIR" REPLAY="$REPO/$RPL" FIELDS="ff8410:w:x,ff8810:w:x2,ff8109:b:timer" \
    FIELD_OUT="$W/ft2.txt" FIELD_FROM=2980 FIELD_TO=3000 FRAMES=3001 \
    "$REPO/tools/run_mame.sh" vsavj -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/ft2.log" 2>&1 ) </dev/null
[ "$(awk '$1 == "F"' "$W/ft2.txt" | wc -l | tr -d ' ')" = 21 ] || { echo "FAIL: field_trace gave no 21-frame trace ($W/ft2.log)"; exit 1; }
D="$W/span"; mkdir -p "$D/legs"; cp "$S/legs/gt.v.rpl" "$S/legs/gt.v.log" "$D/legs/"
cp "$W/ft2.txt" "$D/legs/gt.v.trace"
awk '$1 == "F" && $2 == 2995 {sub(/ x=-*[0-9]+/, " x=12345")} {print}' "$W/ft2.txt" > "$D/legs/gt.w.trace"
{ echo "sheet${T}gt${T}spans${T}-${T}-${T}-"
  echo "leg${T}gt${T}v${T}vsavj${T}vsavj${T}$ROMDIR${T}legs/gt.v.rpl${T}-${T}3001${T}legs/gt.v.log${T}$MASK"
  echo "leg${T}gt${T}w${T}vsavj${T}vsavj${T}$ROMDIR${T}legs/gt.v.rpl${T}-${T}3001${T}-${T}-"
  echo "trace${T}gt${T}v${T}legs/gt.v.trace${T}ff8410:w:x,ff8810:w:x2,ff8109:b:timer"
  echo "trace${T}gt${T}w${T}legs/gt.w.trace${T}ff8410:w:x,ff8810:w:x2,ff8109:b:timer"
  echo "moment${T}gt${T}lspan${T}a log span${T}-${T}-";   echo "at${T}gt${T}lspan${T}v${T}2900${T}log${T}-"
  echo "span${T}gt${T}lspan${T}v${T}2850-2950"
  echo "moment${T}gt${T}fspan${T}a fields span${T}-${T}-"; echo "at${T}gt${T}fspan${T}v${T}3000${T}fields${T}ff8410:w=$x,ff8810:w=$x2"
  echo "span${T}gt${T}fspan${T}v${T}2980-3000"
  echo "at${T}gt${T}fspan${T}w${T}3000${T}fields${T}ff8410:w=$x,ff8810:w=$x2"
  echo "span${T}gt${T}fspan${T}w${T}2990,2995,3000"
} > "$D/sheet.tsv"
cp -R "$D" "$W/span_ctl"
prove "$TOOL" "$D" > "$W/span.tsv" 2>&1
nl="$(awk -F'\t' '$2 == "a log span [span]" && $5 == "PROVEN"' "$W/span.tsv" | wc -l | tr -d ' ')"
nf="$(awk -F'\t' '$2 == "a fields span [span]" && $3 == "v" && $5 == "PROVEN"' "$W/span.tsv" | wc -l | tr -d ' ')"
[ "$nl" = 8 ] && ok "a log span 2850-2950: 8 more frames (9 with the moment's), every one PROVEN on the log" || nope "the log span: $nl of 8 PROVEN ($(awk -F'\t' '$2 == "a log span [span]" {printf "%s %s; ", $4, $5}' "$W/span.tsv"))"
[ "$nf" = 8 ] && ok "a fields span 2980-3000 on the gate's trace: 8 more frames, every one PROVEN" || nope "the fields span: $nf of 8 PROVEN ($(awk -F'\t' '$2 == "a fields span [span]" && $3 == "v" {printf "%s %s; ", $4, $5}' "$W/span.tsv"))"
sw="$(awk -F'\t' '$2 == "a fields span [span]" && $3 == "w" {printf "%s=%s ", $4, $5}' "$W/span.tsv")"
[ "$sw" = "f2990=PROVEN f2995=NOT THE JUDGED RUN " ] && ok "a trace whose f2995 is altered: that frame refused, its neighbour proven ($sw)" || nope "the altered trace: '$sw'"
python3 - "$TOOL" "$D" > "$W/span_bad.txt" 2>&1 <<'PYB'
import importlib.util, shutil, sys, tempfile
from pathlib import Path
spec = importlib.util.spec_from_file_location("ps", sys.argv[1]); ps = importlib.util.module_from_spec(spec); spec.loader.exec_module(ps)
for case, rows in (("ram-span", "moment\tgt\tr\tr\t-\t-\nat\tgt\tr\tv\t900\tram\t0123456789abcdef\nspan\tgt\tr\tv\t890-910\n"),
                   ("no-trace", "moment\tgt\tq\tq\t-\t-\nat\tgt\tq\tu\t900\tfields\tff8410:w=1\nspan\tgt\tq\tu\t890-910\n")):
    d = Path(tempfile.mkdtemp())
    head = "".join(l for l in open(Path(sys.argv[2]) / "sheet.tsv") if l.startswith(("sheet", "leg")))
    head += "leg\tgt\tu\tvsavj\tvsavj\t-\tlegs/gt.v.rpl\t-\t3001\t-\t-\n"
    (d / "sheet.tsv").write_text(head + rows)
    try:
        ps.read_sheet(d); print(case, "accepted")
    except ValueError as e:
        print(case, "refused")
    shutil.rmtree(d)
print("picks", ps.span_frames("100-200", 150) == [100, 112, 125, 138, 150, 162, 175, 188, 200], ps.span_frames("1,5,3", 4) == [1, 3, 4, 5])
PYB
[ "$(cat "$W/span_bad.txt")" = "ram-span refused
no-trace refused
picks True True" ] && ok "a span on a basis that cannot prove each frame (ram), or a fields span with no trace, is refused; lo-hi gives 9 frames with the moment's, a list is kept whole" \
    || nope "span refusals: $(tr '\n' ';' < "$W/span_bad.txt")"

echo "== 8. S4-E: frames at the replay's own inputs inside rounds (the maintainer: up to 18 per round)"
I="$W/inp"; mkdir -p "$I/legs"; cp "$S/legs/gt.v.rpl" "$S/legs/gt.v.log" "$I/legs/"
{ echo "sheet${T}gt${T}inputs${T}-${T}-${T}-"
  echo "leg${T}gt${T}v${T}vsavj${T}vsavj${T}$ROMDIR${T}legs/gt.v.rpl${T}-${T}3001${T}legs/gt.v.log${T}$MASK"
  echo "anchors${T}gt"; echo "inputs${T}gt${T}18"; } > "$I/sheet.tsv"
cp -R "$I" "$W/inp_ctl"
prove "$TOOL" "$I" > "$W/inp.tsv" 2>&1
rs="$(awk -F'\t' '$2 == "anchor: round start" {sub(/^f/, "", $4); print $4; exit}' "$W/inp.tsv")"
inputs_ok() {  # inputs_ok <prove output> <round start> -> "<picks> <in round> <proven>"
    awk -F'\t' -v rs="$2" '$2 ~ /^input at f/ {n++; f = $4; sub(/^f/, "", f); if (f + 0 > rs + 0 && f + 0 <= 3001) r++; if ($5 == "PROVEN") p++}
        END {print n + 0, r + 0, p + 0}' "$1"
}
read -r ni nr npr <<EOF
$(inputs_ok "$W/inp.tsv" "$rs")
EOF
[ -n "$rs" ] && [ "$ni" -ge 1 ] && [ "$ni" -le 18 ] && [ "$ni" = "$nr" ] && [ "$ni" = "$npr" ] \
    && ok "$ni input frames, all inside the round that starts at f$rs, all PROVEN on the log" \
    || nope "inputs: round start '$rs', $ni picked, $nr inside the round, $npr proven (first line: $(head -1 "$W/inp.tsv" | cut -c1-160))"
python3 - "$TOOL" "$I" > "$W/inp_bad.txt" 2>&1 <<'PYI'
import importlib.util, shutil, sys, tempfile
from pathlib import Path
spec = importlib.util.spec_from_file_location("ps", sys.argv[1]); ps = importlib.util.module_from_spec(spec); spec.loader.exec_module(ps)
d = Path(tempfile.mkdtemp())
head = "".join(l for l in open(Path(sys.argv[2]) / "sheet.tsv") if l.startswith(("sheet", "leg")))
(d / "sheet.tsv").write_text(head + "inputs\tgt\t19\n")
try:
    ps.read_sheet(d); print("19 accepted")
except ValueError:
    print("19 refused")
# the bound is PER ROUND (the maintainer 2026-10-21: "18 per round"): two rounds, onsets every 10 frames, n=3;
# then one long held range per round (few onsets): the rest of each round's n from the held frames
(d / "on.rpl").write_text("".join("%d-%d p1=1\n" % (f, f + 2) for f in range(0, 900, 10)))
(d / "held.rpl").write_text("150-290 p1=R\n600-880 p1=L\n")
A = [(100, "round start"), (300, "down settles (timer 10)"), (500, "round start")]
for rpl in ("on.rpl", "held.rpl"):
    p = ps.input_picks({"legs": {"v": {"frames": 900, "replay": rpl}}, "inputs": 3}, "v", {"A": A}, d)
    r1 = [f for f, l in p if l.endswith("(round 1)") and 100 < f <= 300]
    r2 = [f for f, l in p if l.endswith("(round 2)") and 500 < f <= 900]
    print("perround", rpl, len(r1), len(r2), len(p))
shutil.rmtree(d)
print("rounds", ps.rounds([(100, "round start"), (300, "down settles (timer 10)"), (400, "next round spawns"), (500, "round start")], 900) == [(100, 300), (500, 900)])
PYI
[ "$(cat "$W/inp_bad.txt")" = "19 refused
perround on.rpl 3 3 6
perround held.rpl 3 3 6
rounds True" ] && ok "more than 18 input frames is refused; the bound holds in EACH round (two rounds of n=3 give 3 and 3, from onsets or, when a round has fewer, from its held frames); rounds run from each round start to the down that ends it" || nope "inputs units: $(tr '\n' ';' < "$W/inp_bad.txt")"

echo "== 9. S4-C, S4-F and Q3: every tag defined, pages split, frames without fighters in their own strip"
page_units() {  # page_units <tool> -> one line per case
    python3 - "$1" "$W/pg" <<'PYG'
import importlib.util, json, shutil, sys
from pathlib import Path
from PIL import Image
spec = importlib.util.spec_from_file_location("ps", sys.argv[1]); ps = importlib.util.module_from_spec(spec); spec.loader.exec_module(ps)
print("tags", ps.undefined_tags("WEIRD-TAG, then IDENTICAL and DIFF(p1meter)", {}) == ["WEIRD-TAG"],
      ps.undefined_tags("WEIRD-TAG", {"WEIRD-TAG": "a meaning"}) == [])
out = Path(sys.argv[2]); shutil.rmtree(out, ignore_errors=True); (out / "src").mkdir(parents=True)
def pic(n):
    p = out / "src" / ("%d.png" % n); Image.new("RGB", (8, 8), (n * 20 % 255, 0, 0)).save(p); return str(p)
def cell(n, f):
    return {"frame": 1000 + n, "status": "PROVEN", "why": "w", "pic": pic(n), "screen": None, "fighters": f}
legs = [{"leg": "v", "role": "vsavj", "set": "vsavj", "rompath": "-"}, {"leg": "o", "role": "ours", "set": "vsavjw", "rompath": "-"}]
s1 = {"sid": "a", "title": "A", "chars": [], "tickets": [], "not_comparable": "-", "capped": [], "legs": legs,
      "cols": [{"label": "a fight", "verdict": "WEIRD-TAG", "values": "-", "cells": {"v": cell(1, "yes"), "o": cell(2, "yes")}},
               {"label": "a white frame", "verdict": "-", "values": "-", "cells": {"v": cell(3, "no"), "o": cell(4, "no")}}]}
s2 = {"sid": "b", "title": "B", "chars": [], "tickets": [], "not_comparable": "-", "capped": [], "legs": legs,
      "cols": [{"label": "b fight", "verdict": "SAME", "values": "-", "cells": {"v": cell(5, "yes"), "o": cell(6, "yes")}},
               {"label": "b more", "verdict": "SAME", "values": "-", "cells": {"v": cell(7, "yes"), "o": cell(8, None)}}]}
meta = {"commit": "fixture", "date": "-", "gates": [{"gate": "g_fix", "rc": 0, "verdict": "PASS", "seconds": 0, "tickets": [], "sheets": [s1, s2]}]}
ps.PAGE_TILES = 4
ps.page(out, meta)
g = (out / "g" / "g_fix.html").read_text()
nof = g.split("Judged frames without fighters")[1] if "Judged frames without fighters" in g else ""
print("undefined", len(meta.get("undefined_tags", [])) == 1 and "Undefined tags" in (out / "index.html").read_text())
print("legend", all(w in (out / "index.html").read_text() for w in ("PROVEN", "EVENT-PROVEN", "NOT THE JUDGED RUN", "UNPROVEN", "JUDGED FILE", "IDENTICAL", "j.")))
print("split", (out / "g" / "g_fix.2.html").exists() and "b fight" in (out / "g" / "g_fix.2.html").read_text() and "b fight" not in g)
print("strip", "a white frame" in nof and "a fight" not in nof and "a fight" in g)
print("moved", len(list((out / "pics").glob("*.png"))) == 8 and not any((out / "src").glob("*.png")))
PYG
}
page_units "$TOOL" > "$W/page.txt" 2>&1
pu() { awk -v c="$1" '$1 == c {$1 = ""; sub(/^ /, ""); print}' "$W/page.txt"; }
[ "$(pu tags)" = "True True" ] && ok "an upper-case verdict word the legend does not define is found; one the gate declares (# SHEET-VERDICTS:) is not" || nope "tags: '$(pu tags)'"
[ "$(pu undefined)" = True ] && ok "the page lists an undefined tag at the top of its index" || nope "undefined tag listing: '$(pu undefined)'"
[ "$(pu legend)" = True ] && ok "the index carries the legend: every proof status, the verdict words, the move notation" || nope "legend: '$(pu legend)'"
[ "$(pu split)" = True ] && ok "a gate page over PAGE_TILES pictures is split by sheet into parts" || nope "paging: '$(pu split)'"
[ "$(pu strip)" = True ] && ok "a judged frame with no fighter on any leg goes to the 'Judged frames without fighters' strip; the fight stays on the sheet" || nope "Q3 strip: '$(pu strip)'"
[ "$(pu moved)" = True ] && ok "each picture is moved into pics/, one copy" || nope "pictures moved: '$(pu moved)'"

echo "== 5. must-fire controls"
if frame_blind "$W/fb.py"; then
    S2="$W/sheet2"; cp -R "$S" "$S2"; rm -rf "$S2/capture" "$S2/proof.json"
    prove "$W/fb.py" "$S2" > "$W/fb.tsv" 2>&1
    g="$(awk -F'\t' '$2 == "shifted by one" {print $5}' "$W/fb.tsv")"
    if [ "$g" = PROVEN ]; then vs_ctl_fired frame-blind "a tool proving by membership proves the moment shifted by one frame"
    else vs_ctl_dead frame-blind "the membership shadow read '$g' on the shifted moment"; nope "control frame-blind"; fi
else vs_ctl_dead frame-blind "the frame lookup was not found to replace"; nope "control frame-blind"; fi

if count_only "$W/co.py"; then
    rm -rf "$W/ev_ctl/capture" "$W/ev_ctl/proof.json"
    prove "$W/co.py" "$W/ev_ctl" > "$W/co.tsv" 2>&1
    g="$(awk -F'\t' '$2 == "a value altered" {print $5}' "$W/co.tsv")"
    if [ "$g" = EVENT-PROVEN ]; then vs_ctl_fired count-only "a tool comparing line counts EVENT-PROVES the moment whose logged value was altered"
    else vs_ctl_dead count-only "the count-only shadow read '$g' on the altered value"; nope "control count-only"; fi
else vs_ctl_dead count-only "the event comparison was not found to replace"; nope "control count-only"; fi

if relative_unresolved "$W/ru.py"; then
    rm -rf "$R3/capture" "$R3/proof.json"
    prove_rel "$W/ru.py" "$RREL" > "$W/ru.tsv" 2>&1
    g="$(awk -F'\t' '$2 == "on the log" {print $5}' "$W/ru.tsv")"
    if [ "$g" != PROVEN ]; then vs_ctl_fired relative-unresolved "a tool leaving the relative path unresolved reads '${g:-no row}' on the moment the resolved tool proves"
    else vs_ctl_dead relative-unresolved "the unresolved shadow still proved the relative-path moment"; nope "control relative-unresolved"; fi
else vs_ctl_dead relative-unresolved "the path resolve was not found to drop"; nope "control relative-unresolved"; fi

if cap_ignored "$W/ci.py"; then
    rm -rf "$W/anchcap2"; cp -R "$A" "$W/anchcap2"; rm -rf "$W/anchcap2/capture" "$W/anchcap2/proof.json"
    ANCHOR_MAX=$((na - 1)) prove "$W/ci.py" "$W/anchcap2" > /dev/null 2>&1
    if [ -z "$(cap_note "$W/anchcap2" 2>/dev/null)" ]; then vs_ctl_fired cap-ignored "a tool dropping the ACAP line leaves the capped sheet with no cap note"
    else vs_ctl_dead cap-ignored "the shadow still produced a cap note"; nope "control cap-ignored"; fi
else vs_ctl_dead cap-ignored "the ACAP branch was not found to drop"; nope "control cap-ignored"; fi

if build_blind "$W/bb.py"; then
    python3 "$W/bb.py" commitcheck "$W/c_out.json" "$FT" > "$W/bb.tsv" 2>&1
    g="$(awk -F'\t' '$2 == "on the log" {print $5}' "$W/bb.tsv")"
    if [ "$g" = PROVEN ]; then vs_ctl_fired build-blind "a tool whose commit check accepts any rom path proves the ours leg that ran outside the checkout"
    else vs_ctl_dead build-blind "the shadow read '$g' on the outside leg"; nope "control build-blind"; fi
else vs_ctl_dead build-blind "the commit check was not found to drop"; nope "control build-blind"; fi

if fingerprint_blind "$W/fpb.py"; then
    g="$(s3_units "$W/fpb.py" | awk '$1 == "off" {print $2}')"
    if [ "$g" = 0 ]; then vs_ctl_fired fingerprint-blind "a tool that never compares fingerprints accepts a track built off the commit's frozen reference"
    else vs_ctl_dead fingerprint-blind "the shadow still found $g problem(s)"; nope "control fingerprint-blind"; fi
else vs_ctl_dead fingerprint-blind "the fingerprint comparison was not found to drop"; nope "control fingerprint-blind"; fi

if rompath_unresolved "$W/rpu.py"; then
    g="$(rp_unit "$W/rpu.py" 2>&1)"
    if [ "$g" = "build/x/rompath;$ROMDIR" ]; then vs_ctl_fired rompath-unresolved "a tool keeping the rom path as written leaves '$g' relative"
    else vs_ctl_dead rompath-unresolved "the shadow read '$g'"; nope "control rompath-unresolved"; fi
else vs_ctl_dead rompath-unresolved "the rom path resolve was not found to drop"; nope "control rompath-unresolved"; fi

if tag_key_blind "$W/tkb.py"; then
    g="$(s3_units "$W/tkb.py" | awk '$1 == "ctl-off" {print $2}')"
    if [ "$g" = 0 ]; then vs_ctl_fired tag-key-blind "a tool that never compares the tag's program key accepts a control build off its tag"
    else vs_ctl_dead tag-key-blind "the shadow still found $g problem(s)"; nope "control tag-key-blind"; fi
else vs_ctl_dead tag-key-blind "the tag-key comparison was not found to drop"; nope "control tag-key-blind"; fi

if fighters_blind "$W/fbl.py"; then
    rm -rf "$W/fight_ctl/capture" "$W/fight_ctl/proof.json"
    prove "$W/fbl.py" "$W/fight_ctl" > "$W/fbl.tsv" 2>&1
    g="$(awk -F'\t' '$2 == "the stage before the drop-in" {print $7}' "$W/fbl.tsv")"
    if [ "$g" = yes ]; then vs_ctl_fired fighters-blind "a predicate that always says yes reads the bare stage before the drop-in as showing the fighters"
    else vs_ctl_dead fighters-blind "the shadow read '$g' on the bare stage"; nope "control fighters-blind"; fi
else vs_ctl_dead fighters-blind "the fighters predicate was not found to replace"; nope "control fighters-blind"; fi

if span_blind "$W/sbl.py"; then
    rm -rf "$W/span_ctl/capture" "$W/span_ctl/proof.json"
    prove "$W/sbl.py" "$W/span_ctl" > "$W/sbl.tsv" 2>&1
    g="$(awk -F'\t' '$2 == "a fields span [span]" && $3 == "w" && $4 == "f2995" {print $5}' "$W/sbl.tsv")"
    if [ "$g" = PROVEN ]; then vs_ctl_fired span-blind "a span proof that never compares the trace proves the frame whose trace value was altered"
    else vs_ctl_dead span-blind "the shadow read '$g' on the altered frame"; nope "control span-blind"; fi
else vs_ctl_dead span-blind "the span's fields proof was not found to replace"; nope "control span-blind"; fi

if inputs_unbounded "$W/iub.py"; then
    rm -rf "$W/inp_ctl/capture" "$W/inp_ctl/proof.json"
    prove "$W/iub.py" "$W/inp_ctl" > "$W/iub.tsv" 2>&1
    read -r ui ur up <<EOF
$(inputs_ok "$W/iub.tsv" "$rs")
EOF
    if [ "$ui" != "$ur" ]; then vs_ctl_fired inputs-unbounded "taking the whole replay as one round picks $((ui - ur)) of $ui input frames outside the round"
    else vs_ctl_dead inputs-unbounded "the shadow picked $ui frames, $ur inside the round"; nope "control inputs-unbounded"; fi
else vs_ctl_dead inputs-unbounded "the rounds lookup was not found to replace"; nope "control inputs-unbounded"; fi

for c in undefined-tag no-split strip-ignored; do
    fn="$(printf '%s' "$c" | tr '-' '_')"
    if "$fn" "$W/pg_$fn.py"; then
        page_units "$W/pg_$fn.py" > "$W/pg_$fn.txt" 2>&1
        case "$c" in undefined-tag) k=undefined ;; no-split) k=split ;; strip-ignored) k=strip ;; esac
        g="$(awk -v c="$k" '$1 == c {print $2}' "$W/pg_$fn.txt")"
        if [ "$g" = False ]; then vs_ctl_fired "$c" "the shadow fails the page's $k check"
        else vs_ctl_dead "$c" "the shadow's $k check read '$g'"; nope "control $c"; fi
    else vs_ctl_dead "$c" "the shadow's line was not found to replace"; nope "control $c"; fi
done

[ "$bad" = 0 ] && { echo "PASS: test_proof_sheets — proven on the judged run, a one-frame shift and a field off refused, anchors proven and a cap said, a relative path resolved, events proven on their lines, ours held to the commit's build; fighters read, spans and inputs proven, every tag defined, pages split, frames without fighters in their strip"; exit 0; }
echo "FAIL: test_proof_sheets ($bad)"; exit 1
