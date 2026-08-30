#!/bin/sh
# test_charmap_overrides.sh — the character-data OVERRIDE channel round-trips
# (14z-118). build/manifest/charmap_<tenant>.toml (hand-written) compiles, via
# tools/charmap_compile.py, into the "# BEGIN charmap … # END charmap" block of
# build/manifest/<tenant>.toml; the committed block must equal a fresh compile.
# ci_portable: no ROM, no build dir, no emulator, ~1 s (uses the committed map JSON
# and the freeze dirs' extracts only through the map's recorded extract path —
# SKIPs if that extract is absent).
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

echo "== test_charmap_overrides: override files compile to the manifest blocks =="
for n in donovan huitzil pyron; do
    m="docs/project/tables/chars/$n.json"
    [ -f "$m" ] || { bad "$n: no committed map $m"; continue; }
    ex="$(python3 -c "import json; print(json.load(open('$m'))['sources']['ours']['set'])")/extract"
    [ -d "$ex" ] || { echo "SKIP: $n: extract $ex absent (freeze dir rolled off) — re-point the map"; continue; }
    if python3 tools/charmap_compile.py "$m" "build/manifest/charmap_$n.toml" "build/manifest/$n.toml" --check >"$W/$n.log" 2>&1; then
        ok "$n: $(cat "$W/$n.log")"
    else
        bad "$n: block differs from a fresh compile — run: python3 tools/charmap_compile.py $m build/manifest/charmap_$n.toml build/manifest/$n.toml"
        sed 's/^/        /' "$W/$n.log"
    fi
done

m="docs/project/tables/chars/donovan.json"; ex="build/don_m18/extract"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
if [ -f "$m" ] && [ -d "$ex" ]; then
    real="$(python3 -c "b=open('$ex/region_hitbox.bin','rb').read(); print(b[0x100:0x101].hex())")"
    cp build/manifest/donovan.toml "$W/don.toml"
    # (a) wrong expect
    printf '[[override]]\nid = "x"\npath = "region/hitbox/0x100"\nexpect = "%s"\nvalue = "00"\nstage = 6\nnote = "ctl"\n' "$(python3 -c "print('%02x' % ((0x$real ^ 0xff) & 0xff))")" > "$W/bad_expect.toml"
    if python3 tools/charmap_compile.py "$m" "$W/bad_expect.toml" "$W/don.toml" --check >"$W/a.log" 2>&1; then bad "control (a): a wrong expect was ACCEPTED"
    elif grep -q "expect" "$W/a.log"; then ok "control (a): wrong expect refused"; else bad "control (a): failed for the wrong reason: $(cat "$W/a.log")"; fi
    # (b) length mismatch
    printf '[[override]]\nid = "y"\npath = "region/hitbox/0x100"\nexpect = "%s"\nvalue = "0000"\nstage = 6\nnote = "ctl"\n' "$real" > "$W/bad_len.toml"
    if python3 tools/charmap_compile.py "$m" "$W/bad_len.toml" "$W/don.toml" --check >"$W/b.log" 2>&1; then bad "control (b): a length mismatch was ACCEPTED"
    elif grep -q "length" "$W/b.log"; then ok "control (b): length mismatch refused"; else bad "control (b): failed for the wrong reason: $(cat "$W/b.log")"; fi
    # (c) a valid override against a manifest whose block is stale (empty) must FAIL --check
    printf '[[override]]\nid = "z"\npath = "region/hitbox/0x100"\nexpect = "%s"\nvalue = "%s"\nstage = 6\nnote = "ctl"\n' "$real" "$(python3 -c "print('%02x' % ((0x$real ^ 1) & 0xff))")" > "$W/ok.toml"
    if python3 tools/charmap_compile.py "$m" "$W/ok.toml" "$W/don.toml" --check >"$W/c.log" 2>&1; then bad "control (c): a stale block PASSED --check"
    elif grep -q "differs" "$W/c.log"; then ok "control (c): stale block fails --check"; else bad "control (c): failed for the wrong reason: $(cat "$W/c.log")"; fi
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
