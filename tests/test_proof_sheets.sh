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
#   refused, an empty window is UNPROVEN.
# HOW: a fixture SHEET_OUT on pristine vsavj (02_demitri_vs_cpu to frame 3001): the frozen masked vanilla log
#   (tests/expected/vsavj/masked-v2) is the "gate's log", the masked-v2 mask the leg's; the field values are taken
#   from tests/lua/field_trace.lua run live on the same inputs; `proof_sheets.py prove` on the fixture; one control.
# EXPECTS: the six verdicts above, each picture present; PASS. It does not claim any gate's sheet is complete — the
#   census (tests/test_sheet_census.sh) and each gate's own verdict do that part.
# FOLLOWS: tools/proof_sheets.py tests/lua/sheet_capture.lua tests/lua/pokes_spec.lua tests/lua/field_trace.lua
#   tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log tests/expected/merged1/mask
#   tests/replays/02_demitri_vs_cpu.rpl tests/lib/controls.sh tools/run_mame.sh tools/setup_mame.sh emu/mame-patches/
#   tests/lua/sheet_tap_capture.lua tests/lua/read_tap.lua
#
# SHEET: none — the sheet tool's own ground truth on pristine vsavj; it compares no leg of ours against a reference set
# MUST-FIRE: shadow-tool: cap-ignored — a copy of tools/proof_sheets.py that drops the capture's ACAP line must leave the capped sheet with no cap note, so the note rests on the line (in-gate: the shadow is run on the capped fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: relative-unresolved — a copy of tools/proof_sheets.py that does not resolve the SHEET_OUT path must fail the relative-path moment (its capture cannot find the replay), so that PROVEN rests on the resolve (in-gate: the shadow is run on a relative fixture path; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: count-only — a copy of tools/proof_sheets.py whose event proof compares only the NUMBER of lines in the window must EVENT-PROVE the moment whose logged value was altered, so the event basis rests on the lines themselves (in-gate: the shadow is run on the event fixture; mode: the shadow is the tool under test and the gate FAILs)
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
TOOL=tools/proof_sheets.py
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

[ "$bad" = 0 ] && { echo "PASS: test_proof_sheets — proven on the judged run, a one-frame shift and a field off refused, anchors proven and a cap said, a relative path resolved, events proven on their lines"; exit 0; }
echo "FAIL: test_proof_sheets ($bad)"; exit 1
