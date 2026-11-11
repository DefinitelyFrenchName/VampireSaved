#!/bin/sh
# test_desktop_pause_check.sh — THE FBNEO PAUSE DETECTOR READS ITS GROUND TRUTH RIGHT ([VSP-19], #352, 14z-225).
# ROM-free and emulator-free, ~3 s; needs python3 with PIL and the FBNeo source checkout (emu/fbneo, for its font).
#
# WHAT: tools/desktop_pause_check.py, which audit_release_linux_desktop uses to tell a PAUSED FBNeo leg from a real
#   mark or sound failure, reads PAUSED on a frame carrying FBNeo's overlay and NOT on frames that only resemble it.
# HOW: frames drawn here by the tool's own `draw` (FBNeo's font, shadow then ink, as pause_game() draws it): the overlay
#   on a black frame at scale 2 (the 768x576 window of the PILOT runs), on a busy frame at scale 2 and 3, on a black
#   384x224 frame at scale 1 — each must read `PAUSE yes`; a black frame, the busy frame, the ink drawn with no shadow
#   on the busy frame (yellow game art at that place: the M26 fight captures, measured 14z-225 ink 140/140 shadow
#   0/107), the overlay moved 6 renderer pixels right, and the overlay in a dim grey ink — each must read `PAUSE no`;
#   a capture that will not open, a missing font file, and a python with PIL blocked — each must read `PAUSE unread`
#   (exit 2), never a verdict and never a traceback (#352, rule-checker run 2026-11-11-1774).
# EXPECTS: 4 of 4 yes, 5 of 5 no, 3 of 3 unread; each control fails the gate on its own case.
# FOLLOWS: tools/desktop_pause_check.py emu/fbneo/src/burner/sdl/sdl2_inprint.cpp tests/lib/controls.sh tests/lib/classify.sh
#
# SHEET: none — an instrument check on frames it draws itself; no leg of our build compared with a reference set
#
# MUST-FIRE: shadow-tool: shadow-blind — the detector with its shadow test switched off (SHADOW_MAX 255, set in its own process, the tool file untouched) must read the unshadowed ink PAUSED and FAIL the gate (in-gate: that case alone; mode: every case judged by that detector)
# MUST-FIRE: shadow-tool: ink-blind — the detector with its ink test switched off (INK_MIN 0, INK_SPREAD 255, set in its own process) must read the dim-ink overlay PAUSED and FAIL the gate (in-gate: that case alone; mode: every case judged by that detector)
#
# The real-capture ground truth (81 PILOT captures, 10 paused) is in the tool's header and build/agent225/t352/ (local):
# real captures are not kept in the tree, so this gate holds the logic on frames it draws.
# SHARES: none — each run and each control mode writes only its own mktemp directory
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
python3 -c 'import PIL' 2>/dev/null || { echo "SKIP: python3 has no PIL on this host"; exit 0; }
[ -f emu/fbneo/src/burner/sdl/sdl2_inprint.cpp ] || { echo "SKIP: emu/fbneo is not checked out (its font is the template)"; exit 0; }
W="$(mktemp -d)" || { echo "FAIL: test_desktop_pause_check — mktemp -d failed"; exit 2; }
trap 'rm -rf "$W"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
fail=0; : > "$W/main.log"
ok()  { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; echo "  FAIL  $*" >> "$W/main.log"; fail=1; }   # main.log: the check's findings (#369)
T=tools/desktop_pause_check.py

# judge <png> [<perturbation>] -> the detector's one line; a perturbation switches one test off in the detector's own process
judge() {
    python3 - "$1" "${2:-}" <<'PY'
import sys
sys.path.insert(0, "tools")
import desktop_pause_check as m
png, p = sys.argv[1], sys.argv[2]
if p == "shadow-blind":
    m.SHADOW_MAX = 255
elif p == "ink-blind":
    m.INK_MIN, m.INK_SPREAD = 0, 255
sys.argv = ["desktop_pause_check.py", "judge", png]
sys.exit(m.main())
PY
}

echo "== 1. the frames"
python3 - "$W" <<'PY' || { echo "FAIL: test_desktop_pause_check — could not draw the base frames"; exit 1; }
import sys
from PIL import Image
w = sys.argv[1]
Image.new("RGB", (768, 576)).save(w + "/black.png")
Image.new("RGB", (384, 224)).save(w + "/small.png")
busy = Image.new("RGB", (768, 576))
busy.putdata([((x * 7 + y * 3) % 256, (x * 2 + y * 5) % 200, (x + y * 9) % 180) for y in range(576) for x in range(768)])
busy.save(w + "/busy.png")
Image.new("RGB", (1152, 864)).save(w + "/large.png")
PY
python3 "$T" draw "$W/black.png" "$W/y_black.png" > /dev/null &&
python3 "$T" draw "$W/busy.png"  "$W/y_busy.png" > /dev/null &&
python3 "$T" draw "$W/large.png" "$W/y_large3.png" > /dev/null &&
python3 "$T" draw "$W/small.png" "$W/y_small1.png" > /dev/null &&
python3 "$T" draw "$W/busy.png"  "$W/n_inkonly.png" --no-shadow > /dev/null &&
python3 "$T" draw "$W/black.png" "$W/n_moved.png" --dx 6 > /dev/null &&
python3 "$T" draw "$W/black.png" "$W/n_dim.png" --colour 90,90,90 > /dev/null ||
    { echo "FAIL: test_desktop_pause_check — the tool's draw failed"; exit 1; }
cp "$W/black.png" "$W/n_black.png"; cp "$W/busy.png" "$W/n_busy.png"
CASES="y_black y_busy y_large3 y_small1 n_black n_busy n_inkonly n_moved n_dim"

echo "== 2. each frame judged"
P=""; vs_ctl_is shadow-blind && P=shadow-blind; vs_ctl_is ink-blind && P=ink-blind
judged=0
for c in $CASES; do
    line="$(judge "$W/$c.png" "$P")"; rc=$?
    case "$c" in y_*) want=yes ;; *) want=no ;; esac
    case "$line" in "PAUSE $want "*) ok "$c: $line" ;; "PAUSE unread"*|"") bad "$c: unread (exit $rc): $line" ;; *) bad "$c: $line, want PAUSE $want" ;; esac
    case "$line" in "PAUSE yes "*|"PAUSE no "*) judged=$((judged + 1)) ;; esac
done
[ "$judged" -gt 0 ] || { vs_ctl_nj "no frame received a verdict"; bad "no frame received a verdict"; }

echo "== 3. inputs the check cannot read: each must read PAUSE unread (exit 2), never a verdict or a traceback"
printf 'not a png' > "$W/u_corrupt.png"
for u in corrupt nofont nopil; do
    case "$u" in
    corrupt) line="$(python3 "$T" judge "$W/u_corrupt.png" 2>&1)"; rc=$? ;;
    nofont)  line="$(python3 "$T" judge "$W/y_black.png" --font "$W/no_such_font.cpp" 2>&1)"; rc=$? ;;
    nopil)   line="$(python3 -c 'import sys; sys.modules["PIL"] = None; sys.path.insert(0, "tools"); import desktop_pause_check as m; sys.argv = ["desktop_pause_check.py", "judge", sys.argv[1]]; sys.exit(m.main())' "$W/y_black.png" 2>&1)"; rc=$? ;;
    esac
    case "$rc:$line" in "2:PAUSE unread: "*) ok "u_$u: exit 2, $(echo "$line" | cut -c1-90)" ;; *) bad "u_$u: exit $rc, '$(echo "$line" | tail -1 | cut -c1-120)', want exit 2 and PAUSE unread" ;; esac
done

if [ -n "${VS_CTL:-}" ]; then
    [ "$fail" = 1 ] || vs_ctl_left_green "$VS_CTL" "FAIL: test_desktop_pause_check (control mode)"
    case "$VS_CTL" in
    shadow-blind) WANT='^  FAIL  n_inkonly: PAUSE yes .*, want PAUSE no$' ;;
    ink-blind)    WANT='^  FAIL  n_dim: PAUSE yes .*, want PAUSE no$' ;;
    *) WANT='' ;;
    esac
    vs_ctl_caught "$W/main.log" "$WANT" || :
    echo "FAIL: test_desktop_pause_check (control mode)"; exit 1
fi

echo "== 4. controls"
for pc in "shadow-blind n_inkonly" "ink-blind n_dim"; do
    p="${pc% *}"; c="${pc#* }"
    line="$(judge "$W/$c.png" "$p")"
    case "$line" in
        "PAUSE yes "*) vs_ctl_fired "$p" "$c reads '$line' with the test switched off" ;;
        *) vs_ctl_dead "$p" "$c still reads '$line' with the test switched off"; fail=1 ;;
    esac
done

[ "$fail" = 0 ] && echo "PASS: test_desktop_pause_check — 4 paused frames read yes, 5 look-alikes read no, 3 unreadable inputs read unread" || echo "FAIL: test_desktop_pause_check"
exit "$fail"
