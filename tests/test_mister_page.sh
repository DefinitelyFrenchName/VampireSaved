#!/bin/sh
# test_mister_page.sh — the MiSTer synthesis page still draws the map that is
# actually there. (14z-107 (10); docs/project/mister_core.md +
# tools/mk_mister_page.py.)
#
# WHY THIS EXISTS. `docs/project/mister_core.md` is a SYNTHESIS: every number
# in it is a quotation from `mister_map.md`, `mister_fit.md` or a gate, and
# `tools/mk_mister_page.py` draws those numbers to scale. That is exactly the
# shape of document that rots without anybody noticing — the placement moves
# in one slice, the synthesis keeps asserting last month's arithmetic, and the
# picture keeps drawing it. This project has already paid that bill twice in
# the MiSTer arc: `mister_map.md` carried 0.708 MB of slack for four sessions
# against a real figure of 0.125 MB, and `mister_map.md` section 9 still
# quotes SDRAM traffic figures that `mister.md` re-derived at 14z-107 (7).
#
# The generator is therefore its own checker. `--check` re-derives:
#   * every placement offset and length against the frozen `placement()` table
#     in tests/audit_mister_map_fit.sh — the gate that DEFENDS the fit, so the
#     picture cannot drift from the thing that would catch a drift;
#   * the bank tops, the overlap check, "bank 1 is exactly full", "bank 0 has
#     131,072 B free", the .rom image size and all four header words, against
#     what docs/project/mister_map.md section 3 and section 5 state;
#   * every frozen content extent;
#   * the ASCII figures EMBEDDED in docs/project/mister_core.md, which are
#     emitted by the same generator, so the committed markdown cannot drift
#     from the drawn page either;
#   * where the inputs are present, the numbers against the REAL artifacts —
#     the group-C occupancy census recounted from the built WIDE romset, and
#     the page's palette re-read from the decrypted program image. Those two
#     SKIP when their inputs are absent (this gate stays ROM-free), and the
#     skips are printed rather than swallowed.
#
# THE RICH PAGE IS NEVER COMMITTED — a hand-copied artifact goes stale
# silently — so this gate renders it to a TEMP path only, and asserts the
# render is non-trivial and structurally sound rather than eyeballing it.
#
# THREE MUST-FIRE CONTROLS, because a checker with no control asserts nothing:
#   A. move one placement constant (the QSound high window) — the map check
#      must reject it;
#   B. move one frozen content extent (obj bank 4's top code) — the extent
#      check must reject it;
#   C. change one ASCII glyph — the committed-markdown check must reject it.
# Each runs against a COPY of the generator in a temp dir, pointed back at the
# real repo with --repo, so the tree is never touched.
#
# ROM-free, no emulator, ~3 s (or ~5 s with the WIDE build present, which adds
# the real census). ci_portable.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
GEN=tools/mk_mister_page.py
DOC=docs/project/mister_core.md
rc=0
fail() { echo "  FAIL: $*"; rc=1; }

[ -f "$GEN" ] || { echo "SKIP: $GEN is absent"; exit 0; }
[ -f "$DOC" ] || { echo "SKIP: $DOC is absent"; exit 0; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

echo "== 1. the page re-derives every number it draws =="
if python3 "$GEN" --check --verbose > "$W/check.log" 2>&1; then
    sed -n 's/^  ok /  /p' "$W/check.log" | sed 's/^/    /'
    grep -c '^  ok ' "$W/check.log" | sed 's/^/  checks passed: /'
    grep '^  SKIP' "$W/check.log" || true
else
    fail "mk_mister_page.py --check is RED — the synthesis document and the"
    fail "      drawn page no longer agree with the map they quote:"
    grep '^  FAIL' "$W/check.log" | sed 's/^/      /'
fi

echo "== 2. it renders, and the render is structurally sound =="
python3 "$GEN" --standalone "$W/page.html" > "$W/render.log" 2>&1 \
    || fail "the generator could not render the page"
if [ -s "$W/page.html" ]; then
    n=$(wc -c < "$W/page.html" | tr -d ' ')
    [ "$n" -gt 30000 ] || fail "the rendered page is only $n bytes — too small"
    python3 - "$W/page.html" <<'PY' || rc=1
import re, sys, xml.etree.ElementTree as ET
t = open(sys.argv[1], encoding="utf-8").read()
bad = []
svgs = re.findall(r"<svg.*?</svg>", t, re.S)
if len(svgs) < 4:
    bad.append(f"only {len(svgs)} figures on the page, expected at least 4")
for i, s in enumerate(svgs):
    try:
        r = ET.fromstring(s)
    except Exception as e:                                   # noqa: BLE001
        bad.append(f"figure {i} is not well-formed XML: {e}")
        continue
    # ACCESSIBILITY IS PART OF THE CONTRACT, not a nicety: an unlabelled
    # <svg> is an unreadable figure to anyone not looking at it.
    if r.get("role") != "img":
        bad.append(f'figure {i} has no role="img"')
    if not (r.get("aria-label") or "").strip():
        bad.append(f"figure {i} has no aria-label")
    if s.count("<title>") < 3:
        bad.append(f"figure {i} has {s.count('<title>')} region tooltips")
# themes: every colour token must be defined on bare :root AND redefined for
# both dark selectors, or the page borrows the host's theme somewhere.
for sel in ("@media (prefers-color-scheme: dark)", ':root[data-theme="dark"]'):
    if sel not in t:
        bad.append(f"the stylesheet has no {sel} block")
if "--paper" not in t or "background:var(--paper)" not in t:
    bad.append("body has no explicit --paper background")
if "http://" in t or "https://fonts." in t or "<script" in t:
    bad.append("the page is not self-contained (external asset or script)")
for b in bad:
    print("  FAIL:", b)
sys.exit(1 if bad else 0)
PY
    [ "$rc" = 0 ] && echo "  ok: $n bytes, 4 labelled figures, both theme blocks, self-contained"
else
    fail "the generator wrote nothing"
fi

echo "== 3. THE CONTROLS — a checker that cannot fail is not a checker =="
control() {  # control <label> <sed expression> <expected substring in output>
    cp "$GEN" "$W/gen.py"
    sed -i.bak "$2" "$W/gen.py"
    if cmp -s "$GEN" "$W/gen.py"; then
        fail "control '$1' did not perturb anything — its sed no longer matches"
        return
    fi
    if python3 "$W/gen.py" --repo "$REPO" --check > "$W/ctl.log" 2>&1; then
        fail "control '$1' DID NOT FIRE: --check still passes with the"
        fail "      perturbation applied, so it is not testing that number"
    elif ! grep -q "$3" "$W/ctl.log"; then
        fail "control '$1' fired but for the wrong reason (no '$3'):"
        head -4 "$W/ctl.log" | sed 's/^/      /'
    else
        echo "  ok control $1 fired: $(grep -m1 "$3" "$W/ctl.log" | cut -c1-72)"
    fi
}

# A. a placement constant moves (the QSound high window, 1 MB -> 1.5 MB)
control "A (placement constant)" \
    's/^PCM_HIGH = 0x100000/PCM_HIGH = 0x180000/' "QSound PCM high"
# B. a frozen content extent moves (obj bank 4's declared top code)
control "B (frozen extent)" \
    's/(4, 1, GROUPC_BANK, 0xEE73, 45736, 0xEE73)/(4, 1, GROUPC_BANK, 0xEE74, 45736, 0xEE73)/' \
    "frozen extent"
# C. an ASCII figure changes, so the committed markdown is stale
control "C (committed ASCII)" \
    's/(1, 0x800000): "4",/(1, 0x800000): "G",/' \
    "ASCII figure"

if [ "$rc" = 0 ]; then
    echo
    echo "PASS: docs/project/mister_core.md and its drawn page still describe"
    echo "      the map that tests/audit_mister_map_fit.sh defends"
else
    echo
    echo "FAIL: the MiSTer synthesis page is out of step with the map"
fi
exit "$rc"
