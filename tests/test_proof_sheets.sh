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
#   test_gfx_menus' ours leg re-ran on pristine vsavj from ROMDIR).
# HOW: a fixture SHEET_OUT on pristine vsavj (02_demitri_vs_cpu to frame 3001): the frozen masked vanilla log
#   (tests/expected/vsavj/masked-v2) is the "gate's log", the masked-v2 mask the leg's; the field values are taken
#   from tests/lua/field_trace.lua run live on the same inputs; `proof_sheets.py prove` on the fixture; one control.
# EXPECTS: the six verdicts above, each picture present, the S3 refusals (section 6, no build: the checks run on
#   section 3's proven sheet re-labelled `ours`, a scratch git checkout and the tool's own functions); PASS. It does not claim any gate's sheet is complete — the
#   census (tests/test_sheet_census.sh) and each gate's own verdict do that part.
# FOLLOWS: tools/proof_sheets.py tests/lua/sheet_capture.lua tests/lua/pokes_spec.lua tests/lua/field_trace.lua
#   tests/expected/vsavj/masked-v2/logs/02_demitri_vs_cpu.log tests/expected/merged1/mask
#   tests/replays/02_demitri_vs_cpu.rpl tests/lib/controls.sh tools/run_mame.sh tools/setup_mame.sh emu/mame-patches/
#   tests/lua/sheet_tap_capture.lua tests/lua/read_tap.lua build/manifest/ tests/audit_landing_sound.sh
#
# SHEET: none — the sheet tool's own ground truth on pristine vsavj; it compares no leg of ours against a reference set
# MUST-FIRE: shadow-tool: cap-ignored — a copy of tools/proof_sheets.py that drops the capture's ACAP line must leave the capped sheet with no cap note, so the note rests on the line (in-gate: the shadow is run on the capped fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: relative-unresolved — a copy of tools/proof_sheets.py that does not resolve the SHEET_OUT path must fail the relative-path moment (its capture cannot find the replay), so that PROVEN rests on the resolve (in-gate: the shadow is run on a relative fixture path; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: count-only — a copy of tools/proof_sheets.py whose event proof compares only the NUMBER of lines in the window must EVENT-PROVE the moment whose logged value was altered, so the event basis rests on the lines themselves (in-gate: the shadow is run on the event fixture; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: build-blind — a copy of tools/proof_sheets.py whose commit check accepts any rom path must leave the ours leg that ran outside the clean checkout PROVEN, so S3's refusal rests on the check (in-gate: the shadow is run on the re-labelled sheet; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: fingerprint-blind — a copy of tools/proof_sheets.py whose build check never compares fingerprints must accept a track built off the commit's frozen reference, so the run's refusal rests on the comparison (in-gate: the shadow's check_builds on the mismatched set; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: tag-key-blind — a copy of tools/proof_sheets.py whose control check never compares the built track with the freeze tag's program key must accept a control build off its tag, so the refusal rests on the comparison (#291 S4-A; in-gate: the shadow's control_check on the mismatched key; mode: the shadow is the tool under test and the gate FAILs)
# MUST-FIRE: shadow-tool: rompath-unresolved — a copy of tools/proof_sheets.py that keeps a leg's rom path as the gate wrote it must leave a relative element relative, so the capture's rom path rests on the resolve (#291 S4-A; in-gate: the shadow's read_sheet on a fixture leg with a relative element; mode: the shadow is the tool under test and the gate FAILs)
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
TOOL=tools/proof_sheets.py
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

[ "$bad" = 0 ] && { echo "PASS: test_proof_sheets — proven on the judged run, a one-frame shift and a field off refused, anchors proven and a cap said, a relative path resolved, events proven on their lines, ours held to the commit's build"; exit 0; }
echo "FAIL: test_proof_sheets ($bad)"; exit 1
