#!/bin/sh
# test_charmap_overrides.sh — the character-data OVERRIDE channel round-trips
# (14z-118). build/manifest/charmap_<tenant>.toml (hand-written) compiles, via
# tools/charmap_compile.py, into the "# BEGIN charmap … # END charmap" block of
# build/manifest/<tenant>.toml; the committed block must equal a fresh compile.
# ci_static (moved from ci_portable 14z-133b): no ROM, no emulator, ~1 s — but it
# reads the freeze dirs' EXTRACTS through the map's recorded extract path, and a
# clean checkout has no build dirs, so on the CI runner it could only SKIP (which
# the portable tier rightly counts as failure).
#
# MUST-FIRE: known-bad: wrong-expect — an override whose `expect` does not match the vs2 bytes must be REFUSED by the compiler (mode: it replaces donovan's override file in the main check)
# MUST-FIRE: known-bad: length-mismatch — an override whose expect and value differ in length must be REFUSED
# MUST-FIRE: known-bad: stale-block — a valid override compiled against a manifest whose block does not carry it must fail --check
#
# MUST-FIRE CONTROLS (RH-9): (a) an override whose `expect` does not match the
# vs2 bytes is REFUSED; (b) an expect/value length mismatch is REFUSED; (c) a
# manifest copy with a stale block FAILS --check.
#
# HANDOFF's gate-table note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   (tier ci_portable (~1 s)) THE OVERRIDE CHANNEL:
#   `build/manifest/charmap_<tenant>.toml` (hand-written: `[[override]]
#   id/path/expect/value/stage/note`, path `region/<name>/<hexoff>` in phase
#   0) compiles via `tools/charmap_compile.py` into the `# BEGIN charmap … #
#   END charmap` block of the tenant manifest as ordinary `[[region_fix]]`
#   rows — gen_donovan_patch.py unchanged. The committed block must equal a
#   fresh compile; wrong `expect` / length mismatch / stale block all fail
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
# THE KNOWN-BAD OVERRIDE FILES, built up front from the real donovan extract;
# under CONTROL=<name> the named one replaces donovan's override file in the
# main check below, which must then FAIL.
m_don="docs/project/tables/chars/donovan.json"; ex_don="build/don_m22/extract"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
OV_DON="build/manifest/charmap_donovan.toml"
if [ -f "$m_don" ] && [ -d "$ex_don" ]; then
    real="$(python3 -c "b=open('$ex_don/region_hitbox.bin','rb').read(); print(b[0x100:0x101].hex())")"
    printf '[[override]]\nid = "x"\npath = "region/hitbox/0x100"\nexpect = "%s"\nvalue = "00"\nstage = 6\nnote = "ctl"\n' "$(python3 -c "print('%02x' % ((0x$real ^ 0xff) & 0xff))")" > "$W/bad_expect.toml"
    printf '[[override]]\nid = "y"\npath = "region/hitbox/0x100"\nexpect = "%s"\nvalue = "0000"\nstage = 6\nnote = "ctl"\n' "$real" > "$W/bad_len.toml"
    printf '[[override]]\nid = "z"\npath = "region/hitbox/0x100"\nexpect = "%s"\nvalue = "%s"\nstage = 6\nnote = "ctl"\n' "$real" "$(python3 -c "print('%02x' % ((0x$real ^ 1) & 0xff))")" > "$W/ok.toml"
    case "$VS_CTL" in
    wrong-expect)    OV_DON="$W/bad_expect.toml" ;;
    length-mismatch) OV_DON="$W/bad_len.toml" ;;
    stale-block)     OV_DON="$W/ok.toml" ;;
    esac
elif [ -n "$VS_CTL" ]; then
    echo "REFUSED: CONTROL=$VS_CTL is not a mode of this gate (no donovan map or extract on this host)"; exit 3
fi

echo "== test_charmap_overrides: override files compile to the manifest blocks =="
for n in donovan huitzil pyron; do
    m="docs/project/tables/chars/$n.json"
    [ -f "$m" ] || { bad "$n: no committed map $m"; continue; }
    ex="$(python3 -c "import json; print(json.load(open('$m'))['sources']['ours']['set'])")/extract"
    [ -d "$ex" ] || { echo "SKIP: $n: extract $ex absent (freeze dir rolled off) — re-point the map"; continue; }
    ov="build/manifest/charmap_$n.toml"; [ "$n" = donovan ] && ov="$OV_DON"
    if python3 tools/charmap_compile.py "$m" "$ov" "build/manifest/$n.toml" --check >"$W/$n.log" 2>&1; then
        ok "$n: $(cat "$W/$n.log")"
    else
        bad "$n: block differs from a fresh compile — run: python3 tools/charmap_compile.py $m build/manifest/charmap_$n.toml build/manifest/$n.toml"
        sed 's/^/        /' "$W/$n.log"
    fi
done

m="docs/project/tables/chars/donovan.json"; ex="build/don_m22/extract"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
if [ -f "$m" ] && [ -d "$ex" ]; then
    cp build/manifest/donovan.toml "$W/don.toml"
    # (a) wrong expect
    if python3 tools/charmap_compile.py "$m" "$W/bad_expect.toml" "$W/don.toml" --check >"$W/a.log" 2>&1; then vs_ctl_dead wrong-expect "a wrong expect was ACCEPTED"; bad "control (a)"
    elif grep -q "expect" "$W/a.log"; then vs_ctl_fired wrong-expect "wrong expect refused"; ok "control (a): wrong expect refused"; else vs_ctl_dead wrong-expect "failed for the wrong reason: $(cat "$W/a.log")"; bad "control (a)"; fi
    # (b) length mismatch
    if python3 tools/charmap_compile.py "$m" "$W/bad_len.toml" "$W/don.toml" --check >"$W/b.log" 2>&1; then vs_ctl_dead length-mismatch "a length mismatch was ACCEPTED"; bad "control (b)"
    elif grep -q "length" "$W/b.log"; then vs_ctl_fired length-mismatch "length mismatch refused"; ok "control (b): length mismatch refused"; else vs_ctl_dead length-mismatch "failed for the wrong reason: $(cat "$W/b.log")"; bad "control (b)"; fi
    # (c) a valid override against a manifest whose block does not carry it must FAIL --check
    if python3 tools/charmap_compile.py "$m" "$W/ok.toml" "$W/don.toml" --check >"$W/c.log" 2>&1; then vs_ctl_dead stale-block "a stale block PASSED --check"; bad "control (c)"
    elif grep -q "differs" "$W/c.log"; then vs_ctl_fired stale-block "stale block fails --check"; ok "control (c): stale block fails --check"; else vs_ctl_dead stale-block "failed for the wrong reason: $(cat "$W/c.log")"; bad "control (c)"; fi
    # and compiling it in place produces exactly one region_fix row in the block
    python3 tools/charmap_compile.py "$m" "$W/ok.toml" "$W/don.toml" >/dev/null 2>&1
    n_rows="$(sed -n '/# BEGIN charmap/,/# END charmap/p' "$W/don.toml" | grep -c '^\[\[region_fix\]\]')"
    [ "$n_rows" = 1 ] && ok "compile writes one [[region_fix]] row into the block" || bad "compile wrote $n_rows rows, expected 1"
    python3 -c "import sys; sys.path.insert(0,'tools'); from _minitoml import _loads_subset; _loads_subset(open('$W/don.toml').read())" \
        && ok "the compiled manifest parses with the SUBSET reader" || bad "the compiled manifest does not parse with _minitoml's subset path"
else
    echo "  SKIP  controls (no committed donovan map or extract)"
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
