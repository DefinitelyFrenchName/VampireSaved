#!/bin/sh
# test_tables_current.sh — the community-facing behavioral tables
# (docs/project/tables/{donovan,huitzil,pyron}.md, CLAUDE.md §2 rule 5) are
# GENERATED from the CURRENT builds' extracts and must match what is
# committed. ci_static: needs the three solo build dirs, no ROM read, no
# emulator, ~1 s.
#
# WHY (14z-118, the documentation audit). donovan.md was hand-written on
# 2026-08-09 and never refreshed: by 14z-117 the shipped param32_a was a rec8
# `00030000fffd6000` while the page still said `FFFD0000`; Huitzil and Pyron
# had no page though the README promised them. Rule 5 says the tunables live
# in documented tables so the community can review them — a table that does
# not follow the build is a claim with nothing behind it. This gate makes the
# committed tables a MEASUREMENT of the build: regenerate, diff, fail on drift.
#
# Defaults follow the freeze re-point sweep (build/<track> names below).
#
# MUST-FIRE CONTROL (RH-9): a copy of one extract with a single value byte
# changed must regenerate DIFFERENTLY from the committed page.
#
# Usage: tests/test_tables_current.sh   [DON=build/don_m18 HUI=build/hui52 PYR=build/pyron36]  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
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
    [ -f "$b/extract/regions.json" ] || { echo "SKIP: no $b/extract/regions.json (build dir absent)"; exit 0; }
done

echo "== test_tables_current: docs/project/tables/ follow the builds =="
for pair in "$DON:donovan" "$HUI:huitzil" "$PYR:pyron"; do
    b="${pair%%:*}"; n="${pair##*:}"
    python3 tools/tables_char_md.py "$b/extract" "$W/$n.md" >/dev/null 2>&1 \
        || { bad "$n: generator failed on $b/extract"; continue; }
    if cmp -s "$W/$n.md" "docs/project/tables/$n.md"; then
        ok "$n.md matches a regeneration from $b ($(wc -l < "$W/$n.md" | tr -d ' ') lines)"
    else
        bad "$n.md DRIFTED from $b — regenerate: python3 tools/tables_char_md.py $b/extract docs/project/tables/$n.md"
        diff "docs/project/tables/$n.md" "$W/$n.md" | head -8 | sed 's/^/        /'
    fi
done

# --- must-fire control: one value byte changed -> a different page --------
mkdir -p "$W/ctl"
python3 - "$DON/extract/regions.json" "$W/ctl/regions.json" <<'PY'
import json, sys
j = json.load(open(sys.argv[1]))
for v in j["values"]:
    if v["table"] == "word132":
        v["value"] = "%04x" % ((int(v["value"], 16) + 1) & 0xFFFF)
        break
else:
    sys.exit("control: no word132 row to perturb")
json.dump(j, open(sys.argv[2], "w"))
PY
python3 tools/tables_char_md.py "$W/ctl" "$W/ctl.md" >/dev/null 2>&1 || bad "control: generator failed on the perturbed copy"
if cmp -s "$W/ctl.md" "docs/project/tables/donovan.md"; then
    bad "control: a perturbed word132 regenerated IDENTICAL — the diff is not checking"
else
    ok "control: a perturbed word132 regenerates differently (the check fires)"
fi

if [ "$fail" = 0 ]; then echo "PASS"; else echo "FAIL"; exit 1; fi
