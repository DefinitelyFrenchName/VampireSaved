#!/bin/sh
# test_charmap_current.sh — THE CHARACTER-DATA MAP follows the builds (14z-118).
# docs/project/tables/chars/{donovan,huitzil,pyron}.{json,md} are GENERATED from
# each current solo build (extract + built image + placements + manifest) by
# tools/charmap_gen.py -> tools/charmap_md.py and must equal a regeneration.
# ci_static: needs the three solo build dirs; no ROM read, no emulator, ~20 s.
#
# WHAT IT HOLDS. The map is the maintainer's instrument for "is our tenant
# VS2-exact, and where not, why?" — every difference carries an attribution
# and the UNATTRIBUTED counts are frozen by this cmp: a byte that starts to
# differ without a manifest row explaining it changes the page and fails here.
# So do a moved placement, a changed physics row, a new override.
#
# MUST-FIRE CONTROLS (RH-9): (a) a copy of a build whose built image has ONE
# value byte changed inside the hitbox region must regenerate a DIFFERENT map
# (and its unattributed count must rise by one); (b) an override row added to
# a copy of the overrides file must show up as ours_source override:<id>.
#
# Usage: tests/test_charmap_current.sh   [DON=build/don_m18 HUI=build/hui52 PYR=build/pyron36]  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
DON="${DON:-build/don_m18}"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
HUI="${HUI:-build/hui52}"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
PYR="${PYR:-build/pyron36}"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM

for b in "$DON" "$HUI" "$PYR"; do
    for f in extract/regions.json verify_data.bin patch/placements.json; do
        [ -f "$b/$f" ] || { echo "SKIP: no $b/$f (build dir absent)"; exit 0; }
    done
done

echo "== test_charmap_current: docs/project/tables/chars/ follow the builds =="
for pair in "$DON:donovan" "$HUI:huitzil" "$PYR:pyron"; do
    b="${pair%%:*}"; n="${pair##*:}"
    python3 tools/charmap_gen.py "$b" "$W/$n.json" >"$W/$n.gen.log" 2>&1 \
        || { bad "$n: charmap_gen failed on $b"; sed 's/^/        /' "$W/$n.gen.log" | tail -5; continue; }
    python3 tools/charmap_md.py "$W/$n.json" "$W/$n.md" --anim "$W/${n}_anim.md" >/dev/null 2>&1 \
        || { bad "$n: charmap_md failed"; continue; }
    if cmp -s "$W/$n.json" "docs/project/tables/chars/$n.json" && cmp -s "$W/$n.md" "docs/project/tables/chars/$n.md" && cmp -s "$W/${n}_anim.md" "docs/project/tables/chars/${n}_anim.md"; then
        ok "$n: json + md match a regeneration from $b ($(grep -o '"region_bytes_unattributed": [0-9]*' "$W/$n.json"))"
    else
        bad "$n: DRIFTED from $b — regenerate: python3 tools/charmap_gen.py $b docs/project/tables/chars/$n.json && python3 tools/charmap_md.py docs/project/tables/chars/$n.json docs/project/tables/chars/$n.md --anim docs/project/tables/chars/${n}_anim.md"
        diff "docs/project/tables/chars/$n.md" "$W/$n.md" | head -6 | sed 's/^/        /'
    fi
done

# --- control (a): one built byte changed inside the hitbox region -> different map, +1 unattributed
mkdir -p "$W/ctl/extract" "$W/ctl/patch"
cp "$DON/extract/regions.json" "$W/ctl/extract/"; cp "$DON"/extract/region_*.bin "$W/ctl/extract/"
cp "$DON/patch/placements.json" "$W/ctl/patch/"; [ -f "$DON/patch/effect_map.json" ] && cp "$DON/patch/effect_map.json" "$W/ctl/patch/"
[ -f "$DON/patch/patch.json" ] && cp "$DON/patch/patch.json" "$W/ctl/patch/"; [ -f "$DON/patch/effect_lists.bin" ] && cp "$DON/patch/effect_lists.bin" "$W/ctl/patch/"
python3 - "$DON/verify_data.bin" "$W/ctl/verify_data.bin" "$W/ctl/patch/placements.json" <<'PY'
import sys, json
img = bytearray(open(sys.argv[1], "rb").read())
dst = json.load(open(sys.argv[3]))["regions"]["hitbox"]["dst"]
img[dst + 0x100] ^= 0x01     # one byte inside the placed hitbox region
open(sys.argv[2], "wb").write(bytes(img))
PY
python3 tools/charmap_gen.py "$W/ctl" "$W/ctl.json" >/dev/null 2>&1 || bad "control (a): generator failed on the perturbed copy"
if cmp -s "$W/ctl.json" "$W/donovan.json"; then
    bad "control (a): a changed built byte regenerated an IDENTICAL map — the check is not checking"
else
    before="$(grep -o '"region_bytes_unattributed": [0-9]*' "$W/donovan.json" | grep -o '[0-9]*$')"
    after="$(grep -o '"region_bytes_unattributed": [0-9]*' "$W/ctl.json" | grep -o '[0-9]*$')"
    if [ "$after" -eq "$((before + 1))" ]; then ok "control (a): one changed built byte -> unattributed $before -> $after (fires)"
    else bad "control (a): unattributed went $before -> $after, expected +1"; fi
fi

# --- control (b): an override row shows as ours_source override:<id>
cat > "$W/ov.toml" <<'EOF'
[[override]]
id = "ctl_row"
path = "region/hitbox/0x100"
expect = "__EXP__"
value = "__VAL__"
stage = 6
note = "control"
EOF
exp="$(python3 -c "import sys; b=open('$DON/extract/region_hitbox.bin','rb').read(); print(b[0x100:0x101].hex())")"
val="$(python3 -c "print('%02x' % ((0x$exp ^ 1) & 0xff))")"
sed -i '' "s/__EXP__/$exp/; s/__VAL__/$val/" "$W/ov.toml"
python3 tools/charmap_gen.py "$W/ctl" "$W/ctl2.json" --overrides "$W/ov.toml" >/dev/null 2>&1 || bad "control (b): generator refused the override"
if grep -q '"override:ctl_row"' "$W/ctl2.json" && [ "$(grep -o '"region_bytes_unattributed": [0-9]*' "$W/ctl2.json" | grep -o '[0-9]*$')" -eq "$before" ]; then
    ok "control (b): the override attributes the changed byte (override:ctl_row; unattributed back to $before)"
else
    bad "control (b): the override did not attribute the byte"
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
