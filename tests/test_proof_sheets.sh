#!/bin/sh
# test_proof_sheets.sh — THE COMPARATIVE SHEETS' PROOF IS ITSELF TESTED ([VSP-19]; GitHub #291 slice S1, 14z-204).
#
# WHAT: tools/proof_sheets.py proves a picture only when the re-run leg's state at that frame equals what the gate
#   logged there: a moment on the gate's own checksum log is PROVEN, the same checksum claimed one frame later is NOT
#   THE JUDGED RUN, a correct field expectation is PROVEN and one value off by one is refused, a basis `none` is shown
#   UNPROVEN; and tests/lua/sheet_capture.lua's masked checksum equals replay.lua's frozen log frame for frame; a
#   sheet asking for anchors gets every anchor its leg reaches, each proven on the log, and a set ANCHOR_MAX is said on
#   the sheet, never silent (rule-checker run 2026-10-18-1118: a silent cap of 16 dropped rounds).
# HOW: a fixture SHEET_OUT on pristine vsavj (02_demitri_vs_cpu to frame 3001): the frozen masked vanilla log
#   (tests/expected/vsavj/masked-v2) is the "gate's log", the masked-v2 mask the leg's; the field values are taken
#   from tests/lua/field_trace.lua run live on the same inputs; `proof_sheets.py prove` on the fixture; one control.
# EXPECTS: the six verdicts above, each picture present; PASS. It does not claim any gate's sheet is complete — the
#   census (tests/test_sheet_census.sh) and each gate's own verdict do that part.
# FOLLOWS: tools/proof_sheets.py tests/lua/sheet_capture.lua tests/lua/pokes_spec.lua tests/lua/field_trace.lua
#   tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log tests/expected/merged1/mask
#   tests/replays/02_demitri_vs_cpu.rpl tests/lib/controls.sh tools/run_mame.sh tools/setup_mame.sh emu/mame-patches/
#
# SHEET: none — the sheet tool's own ground truth on pristine vsavj; it compares no leg of ours against a reference set
# MUST-FIRE: shadow-tool: cap-ignored — a copy of tools/proof_sheets.py that drops the capture's ACAP line must leave the capped sheet with no cap note, so the note rests on the line (in-gate: the shadow is run on the capped fixture; mode: the shadow is the tool under test and the gate FAILs)
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
TOOL=tools/proof_sheets.py
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

echo "== 5. must-fire controls"
if frame_blind "$W/fb.py"; then
    S2="$W/sheet2"; cp -R "$S" "$S2"; rm -rf "$S2/capture" "$S2/proof.json"
    prove "$W/fb.py" "$S2" > "$W/fb.tsv" 2>&1
    g="$(awk -F'\t' '$2 == "shifted by one" {print $5}' "$W/fb.tsv")"
    if [ "$g" = PROVEN ]; then vs_ctl_fired frame-blind "a tool proving by membership proves the moment shifted by one frame"
    else vs_ctl_dead frame-blind "the membership shadow read '$g' on the shifted moment"; nope "control frame-blind"; fi
else vs_ctl_dead frame-blind "the frame lookup was not found to replace"; nope "control frame-blind"; fi

if cap_ignored "$W/ci.py"; then
    rm -rf "$W/anchcap2"; cp -R "$A" "$W/anchcap2"; rm -rf "$W/anchcap2/capture" "$W/anchcap2/proof.json"
    ANCHOR_MAX=$((na - 1)) prove "$W/ci.py" "$W/anchcap2" > /dev/null 2>&1
    if [ -z "$(cap_note "$W/anchcap2" 2>/dev/null)" ]; then vs_ctl_fired cap-ignored "a tool dropping the ACAP line leaves the capped sheet with no cap note"
    else vs_ctl_dead cap-ignored "the shadow still produced a cap note"; nope "control cap-ignored"; fi
else vs_ctl_dead cap-ignored "the ACAP branch was not found to drop"; nope "control cap-ignored"; fi

[ "$bad" = 0 ] && { echo "PASS: test_proof_sheets — proven on the judged run, a one-frame shift and a field off refused, anchors proven and a cap said"; exit 0; }
echo "FAIL: test_proof_sheets ($bad)"; exit 1
