#!/bin/sh
# test_checkdocs_rom.sh — the atlas's ROM-shaped claims are re-derived from the
# decrypted images, and the checker is proven falsifiable (14z-142, living-docs
# slice L3). ci_static: needs ROMDIR (or a warm decrypt cache), no build dir,
# no emulator, ~2 s on a warm cache and ~35 s cold (three sets to decrypt).
#
# WHAT IT HOLDS. `tools/checkdocs_rom.py` runs every registered check over the
# tree: each QUOTES its claim from the atlas (`says()`, so a check cannot
# outlive the sentence it was written for) and DERIVES the same fact from the
# decrypted view, then compares. This gate asserts all of them pass, that every
# `@table` NEGATIVE CONTROL fired, that the coverage NOTE is printed, and that
# the COVERED SET still equals `tests/expected/checkdocs_rom_covered.tsv` —
# the shrink-only half, compared as a MULTISET so a hand-added duplicate row
# fails too (the shape `audit_rule5.py` had to fix at 14z-141).
#
# WHY. Nothing in the tree re-derived an atlas claim from the image. Some of
# those claims have no second home at all — `docs/game/atlas/README.md` SAID of
# its opcode-view SHA-1 column, in the document itself, "it has no second home
# in the tree, so this is the only place it is checked". A human re-derived it
# by hand at 14z-118 and nothing would have caught it going stale. That
# sentence now names THIS gate, and the check quotes the amended wording, so
# the document and its checker moved in one commit.
#
# THE COVERAGE NUMBER IS NOTE-CLASS, NEVER FATAL (ruled 2026-09-07, the L2
# convention): the tool prints `NOTE: checkdocs_rom.coverage <n>/346` at column
# 0, and because this gate CAPTURES the tool's output to a file it must RE-EMIT
# that line itself, unindented — asserting the note inside a captured file
# proves the tool works and says nothing about what the runner receives
# (paid twice; docs/project/gotchas.md). 346 is the atlas tier (473) minus the
# 127 addresses carried only by `ram.md`, whose claims are dataflow and belong
# to the suite (scope §6.5). The COVERED set freezes at the atlas-tier close,
# not here — this is the framework session.
#
# MUST-FIRE CONTROLS, each on a perturbed COPY and each proven to have applied
# before its assertion ([VSP-19]; the tool passes everything on a clean tree,
# so its first green says nothing until these fire):
#   1 a quoted claim reworded in the doc     -> Stale     ("no longer contains")
#   2 one byte flipped at a checked address  -> Mismatch  (the check reads the ROM)
#   3 a PARAPHRASE claim's LITERAL fact perturbed -> Mismatch (the declared
#     class cannot degrade into a silent skip — the reason it is declared)
#   4 a @table validator weakened to accept anything -> Vacuous (a validator
#     its own control cannot break proves nothing)
#   5 a frozen COVERED row the run does not reach -> "no longer covers"
#     (0x38C258 is an atlas address the venue check deliberately does not
#     read: the document itself says it is NOT a table)
# Controls 2 and 3 perturb a COPY of the decrypted view, never the cache;
# control 5 perturbs the frozen set and restores it, asserting both.
set -u
REPO=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO" || exit 1
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; fail=1; }

. "$REPO/tests/lib/decrypt_cache.sh"

echo "== 1. the three decrypted views"
if [ -z "${ROMDIR:-}" ] && [ ! -f "$REPO/build/out/vsavj_opcodes.bin" ]; then
    echo "SKIP: set ROMDIR (or warm build/out) — this gate reads the decrypted images"
    exit 0
fi
mkdir -p "$W/views"
for s in vsavj vsav2 vhunt2; do
    decrypt_view "$s" "$W/views/${s}_opcodes.bin" "$W/views/${s}_data.bin" \
        || { echo "SKIP: decrypt_view $s unavailable"; exit 0; }
done
ok "vsavj, vsav2 and vhunt2 opcode+data views materialised"

echo "== 2. every check, over the tree"
out="$W/run.txt"
python3 tools/checkdocs_rom.py --views "$W/views" --check-covered > "$out" 2>&1
rc=$?
[ "$rc" = 0 ] || { sed 's/^/    /' "$out"; bad "checkdocs_rom exited $rc"; }
grep -q '^MISMATCH' "$out" && bad "a check disagreed with the image"
summary=$(grep -E '^[0-9]+ checks, ' "$out")
[ -n "$summary" ] || bad "no summary line"
echo "    $summary"
nchecks=$(echo "$summary" | sed -n 's/^\([0-9]*\) checks.*/\1/p')
nok=$(echo "$summary"    | sed -n 's/.*, \([0-9]*\) ok,.*/\1/p')
nctl=$(echo "$summary"   | sed -n 's/.*; \([0-9]*\) table controls fired.*/\1/p')
[ "${nchecks:-0}" -ge 15 ] || bad "only ${nchecks:-0} checks registered (expected at least 15)"
[ "${nchecks:-0}" = "${nok:-x}" ] || bad "not every check passed"
[ "${nctl:-0}" -ge 12 ] || bad "only ${nctl:-0} table controls fired (expected at least 12)"
ok "$nchecks checks, all passing, $nctl table controls fired"
grep -q '^  ok: the covered set equals the frozen inventory' "$out" \
    || bad "the covered set does not equal tests/expected/checkdocs_rom_covered.tsv"

note=$(grep '^NOTE: checkdocs_rom.coverage ' "$out")
[ -n "$note" ] || bad "the coverage NOTE is absent from the tool's output"
case "$note" in
    "NOTE: checkdocs_rom.coverage "*"/346 atlas ROM-tier addresses")
        ok "the coverage number reports against the ruled 346 denominator" ;;
    *)  bad "the coverage NOTE does not report against the ruled denominator: $note" ;;
esac
# RE-EMIT IT AT COLUMN 0. The tool's own output is captured to a file, so the
# runner never sees it there; run_all_static.sh greps `^NOTE: ` across each
# gate's .out, and an INDENTED note is invisible to it. That exact mistake
# shipped once already (14z-141, the rule-5 census printed `(none)` in the
# advisory block while its gate PASSED) and it was repeated here — the first
# full tier run of this gate surfaced no number.
echo "$note"

echo "== 3. must-fire controls"
# A perturbable copy of the document tree (the tool resolves docs from --root)
mkdir -p "$W/root/docs/game/atlas" "$W/root/tools" "$W/root/docs"
cp docs/game/atlas/*.md "$W/root/docs/game/atlas/"
cp tools/gen_annotations.py "$W/root/tools/"
cp docs/doc_shape.tsv "$W/root/docs/"

ctl() {  # ctl <label> <expected substring> <root> <views> [tool]
    _lbl="$1"; _want="$2"; _root="$3"; _views="$4"; _tool="${5:-tools/checkdocs_rom.py}"
    python3 "$_tool" --root "$_root" --views "$_views" > "$W/ctl.txt" 2>&1
    _rc=$?
    if [ "$_rc" = 0 ]; then
        bad "control: $_lbl — the checker still exited 0"
    elif grep -q "$_want" "$W/ctl.txt"; then
        ok "control fired: $_lbl"
    else
        sed 's/^/    /' "$W/ctl.txt"
        bad "control: $_lbl — exited $_rc but not for the stated reason"
    fi
}

# 1 — a quoted claim reworded
cp "$W/root/docs/game/atlas/id_space.md" "$W/id_space.orig"
sed -i.bak 's/ending cleanly at `0x0502A8`/ending cleanly at `0x0502A9`/' \
    "$W/root/docs/game/atlas/id_space.md"
if cmp -s "$W/root/docs/game/atlas/id_space.md" "$W/id_space.orig"; then
    bad "control 1: the document perturbation did not apply"
else
    ctl "a reworded claim is STALE" "no longer contains" "$W/root" "$W/views"
fi
cp "$W/id_space.orig" "$W/root/docs/game/atlas/id_space.md"

# 2 — one byte flipped at a checked address, on a COPY of the view
mkdir -p "$W/v2"; cp "$W/views/"*.bin "$W/v2/"
python3 - "$W/v2/vsavj_opcodes.bin" <<'PY'
import sys
p = sys.argv[1]; b = bytearray(open(p, "rb").read())
b[0x028DD8] ^= 0x01          # the loader's first opcode word
open(p, "wb").write(bytes(b))
PY
if cmp -s "$W/v2/vsavj_opcodes.bin" "$W/views/vsavj_opcodes.bin"; then
    bad "control 2: the image perturbation did not apply"
else
    ctl "a flipped ROM byte is a MISMATCH" "0x028DD8" "$W/root" "$W/v2"
fi

# 3 — the PARAPHRASE claim's LITERAL fact perturbed
mkdir -p "$W/v3"; cp "$W/views/"*.bin "$W/v3/"
python3 - "$W/v3/vsavj_opcodes.bin" <<'PY'
import sys
p = sys.argv[1]; b = bytearray(open(p, "rb").read())
b[0x000EF6] ^= 0xFF          # the #$f000f000 the atlas summarises
open(p, "wb").write(bytes(b))
PY
if cmp -s "$W/v3/vsavj_opcodes.bin" "$W/views/vsavj_opcodes.bin"; then
    bad "control 3: the image perturbation did not apply"
else
    ctl "a PARAPHRASE claim's literal fact is checked" "the constant loaded into d0" \
        "$W/root" "$W/v3"
fi

# 4 — a validator weakened until its own control cannot break it
cp tools/checkdocs_rom.py "$W/weak.py"
python3 - "$W/weak.py" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); t = p.read_text()
old = "                  lambda v, i: 0x001000 <= v <= 0x3FFFFF)"
new = "                  lambda v, i: True)"
assert t.count(old) == 1, "the validator line moved — control 4 needs re-aiming"
p.write_text(t.replace(old, new))
PY
if cmp -s "$W/weak.py" tools/checkdocs_rom.py; then
    bad "control 4: the tool perturbation did not apply"
else
    ctl "a vacuous validator is rejected" "Vacuous" "$W/root" "$W/views" "$W/weak.py"
fi

# 5 — a frozen covered row the run does not reach (0x38C258 is an atlas
# address the venue check deliberately does NOT read: the document says it is
# NOT a table). Compared as a MULTISET, so a duplicated row fails too.
COV=tests/expected/checkdocs_rom_covered.tsv
cp "$COV" "$W/cov.bak"
{ cat "$W/cov.bak"; printf 'venue_pointer_table\tvenue_assets.md\tPRG:0x38C258\n'; } > "$W/cov.new"
cp "$W/cov.new" "$COV"
_b=$(wc -l < "$W/cov.bak"); _a=$(wc -l < "$COV")
if [ "$_a" -ne $((_b + 1)) ]; then
    bad "control 5: the frozen-set perturbation did not apply"
else
    python3 tools/checkdocs_rom.py --views "$W/views" --check-covered > "$W/c5.txt" 2>&1
    _rc=$?
    if [ "$_rc" = 0 ]; then
        bad "control 5: a frozen row the run does not cover still exited 0"
    elif grep -q 'no longer covers PRG:0x38C258' "$W/c5.txt"; then
        ok "control fired: a dropped covered address"
    else
        sed 's/^/    /' "$W/c5.txt"; bad "control 5: exited $_rc but not for the stated reason"
    fi
fi
cp "$W/cov.bak" "$COV"
cmp -s "$W/cov.bak" "$COV" || bad "control 5: the frozen set was not restored"

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
