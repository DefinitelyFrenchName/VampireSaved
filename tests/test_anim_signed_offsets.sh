#!/bin/sh
# test_anim_signed_offsets.sh — THE ANIM INDEX TABLES' OFFSETS ARE READ SIGNED (#318).
# ci_static: needs ROMDIR (or a warm decrypt cache), no build dir, no emulator, ~5 s warm.
#
# WHAT: tools/anim_nodes.py's walk_table reads an anim index table's word offsets SIGNED, as the
#   engine adds them (a sign-extended word add): a negative entry names a chain stored BELOW its
#   table. On vsavj every negative entry of the 15 characters' five tables (a/a2/b/c/proj) starts
#   at table + the sign-extended word, the per-character census of those entries is as frozen (71
#   on 11 characters), and a negative word neither ends a table nor bounds it (each case's entry
#   count as frozen); one known entry per affected character lands on its frozen chain (start,
#   node count, end), plus Pyron's a:0x41 on vsav2, the tenant entry that moved his map.
# HOW: one Python program over the decrypted vsavj and vsav2 data views (the bank rows from
#   build/manifest/bank_map.toml), importing the walker from a directory it is given — the tree's
#   tools/ normally; each control hands it a shadow copy of the walker under a throwaway root.
# EXPECTS: every case, census row and start check as frozen; a red means the walker lands a
#   negative entry 64 KiB past the real chain (the pre-#318 unsigned read) or mis-bounds a table.
#   Each control's shadow copy must FAIL.
#
# SHEET: none — a static reading of the two reference sets' tables; no leg of our build compared with a reference set
#
# MUST-FIRE: shadow-tool: unsigned-read — a copy of tools/anim_nodes.py whose walk_table defaults to the unsigned read (signed=False, the pre-#318 read) must land every negative entry at table + word, 64 KiB past its chain, and the gate must FAIL (mode: the main check imports that copy)
# MUST-FIRE: shadow-tool: negative-ends-table — a copy of tools/anim_nodes.py whose table bound takes a negative word for the table's end must stop the walk at the first negative entry, so the known entries are no longer walked and the census reads 0, and the gate must FAIL (mode: the main check imports that copy)
#
# WHY. #229's fork F2 (14z-205) found the defect with a signed walk of its own: Sasquatch's Big
# Breath and Big Blow (a2:0x24/0x25) read UNFIRED because the tree's walker decoded garbage at
# table + 0xF858. The #229 rigs carry local signed walkers; every other consumer of walk_table
# (the character-data map, the same-data census, the reaction-class census, the facing-rule
# census, the join rigs' node maps) read those 71 entries at the wrong node until #318 fixed the
# shared tool. Both control copies are built from the TRACKED tool by a textual edit that must
# apply (the copy must differ from the tool), so a refactor that moves the line kills the control
# loudly instead of letting it pass.
#
# Usage: ROMDIR=... tests/test_anim_signed_offsets.sh
#        CONTROL=unsigned-read|negative-ends-table tests/test_anim_signed_offsets.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

. "$REPO/tests/lib/decrypt_cache.sh"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"

echo "== 1. the two decrypted data views"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj.bin" || { echo "SKIP: no vsavj decrypt view (set ROMDIR to build the cache)"; exit 0; }
decrypt_view vsav2 "$W/v2_op.bin" "$W/v2.bin" || { echo "SKIP: no vsav2 decrypt view (set ROMDIR to build the cache)"; exit 0; }
ok "vsavj and vsav2 data views materialised"

# THE SHADOW WALKERS, built first from the tracked tool (section 3 runs them as controls; under
# CONTROL=<name> the named one is what section 2 imports). Each edit must APPLY.
perturb() {  # perturb <name> <dir>: a copy of tools/anim_nodes.py with that control's edit
    mkdir -p "$2"
    case "$1" in
        unsigned-read)       sed 's/def walk_table(img, base, table, end=None, max_seq=None, entries=None, signed=True):/def walk_table(img, base, table, end=None, max_seq=None, entries=None, signed=False):/' tools/anim_nodes.py > "$2/anim_nodes.py" ;;
        negative-ends-table) sed 's/if w and (w & 1 or 0 < w < 2 \* (k + 1)):/if w and (w \& 1 or w < 2 * (k + 1)):/' tools/anim_nodes.py > "$2/anim_nodes.py" ;;
    esac
    if cmp -s tools/anim_nodes.py "$2/anim_nodes.py"; then
        echo "  the $1 edit did not apply to tools/anim_nodes.py"; return 1
    fi
}
for c in unsigned-read negative-ends-table; do
    perturb "$c" "$W/shadow_$c" || bad "control $c: its edit no longer applies to the tool (the line moved): rewrite the control"
done

# THE CHECK: tooldir, vsavj view, vsav2 view. Prints `BAD ...` per broken expectation, then a summary.
check() {
python3 - "$1" "$W/vj.bin" "$W/v2.bin" "$REPO" <<'PY'
import sys
from pathlib import Path
tooldir, vj, v2, repo = sys.argv[1:5]
sys.path.insert(0, str(Path(repo) / "tools"))
sys.path.insert(0, tooldir)            # the walker under test FIRST: the tree's tools/ or a shadow copy
import anim_nodes
assert Path(anim_nodes.__file__).resolve().parent == Path(tooldir).resolve(), anim_nodes.__file__
import _minitoml as mt
bank = mt.loads((Path(repo) / "build/manifest/bank_map.toml").read_text())
imgs = {"vsavj": Path(vj).read_bytes(), "vsav2": Path(v2).read_bytes()}
TABLES = ("a", "a2", "b", "c", "proj")
NAMES = {0x00: "BU", 0x01: "DE", 0x02: "GA", 0x03: "VI", 0x04: "ZA", 0x05: "MO", 0x06: "AN", 0x07: "FE",
         0x08: "BI", 0x09: "AU", 0x0A: "SA", 0x0C: "QB", 0x0D: "LE", 0x0E: "LI", 0x0F: "JE",
         0x10: "HU", 0x11: "PY", 0x13: "DO"}


def table_ptr(game, cid, t):
    d = int(bank["origins"][game]) - int(bank["origins"]["vsavj"])
    row = {x["name"]: int(x["vsavj"]) for x in bank["table"]}["anim_index_" + t] + d
    return int.from_bytes(imgs[game][row + cid * 4:row + cid * 4 + 4], "big")


def sext(w):
    return w - 0x10000 if w & 0x8000 else w


bad = 0
def BAD(msg):
    global bad
    bad += 1
    print("BAD " + msg)

# (a) ONE KNOWN NEGATIVE ENTRY PER AFFECTED CHARACTER: game, id, table, seq -> the table address,
# the chain start (table + the signed offset), its node count and end, and the table's entry count.
# Measured 14z-210 (#318, build/agent210/t318/, local) with the fixed walker on the reference views.
CASES = [
    ("vsavj", 0x00, "a2", "0x5e", 0x116e62, 0x11632e, 3, "hold", 107),          # Bulleta
    ("vsavj", 0x01, "c", "0x2e", 0x1307b8, 0x12c362, 12, "loop:0x12c362", 60),  # Demitri
    ("vsavj", 0x02, "a2", "0x75", 0x13d0c6, 0x13c8ba, 8, "loop:0x13c91a", 124), # Gallon
    ("vsavj", 0x03, "a2", "0x3f", 0x151b5c, 0x15120c, 3, "hold", 113),          # Victor
    ("vsavj", 0x04, "a2", "0x24", 0x167398, 0x167146, 17, "hold", 102),         # Zabel
    ("vsavj", 0x06, "a2", "0x42", 0x18efee, 0x18be40, 3, "hold", 107),          # Anakaris
    ("vsavj", 0x07, "b", "0x6e", 0x1b9430, 0x1b19a8, 1, "hold", 181),           # Felicia
    ("vsavj", 0x0A, "a2", "0x24", 0x1eed80, 0x1ee5d8, 8, "hold", 83),           # Sasquatch's Big Breath
    ("vsavj", 0x0C, "a2", "0x42", 0x1fe666, 0x1fd3d2, 12, "loop:0x1fd4c2", 112),# Q-Bee
    ("vsavj", 0x0D, "b", "0x79", 0x21d932, 0x21d79a, 5, "hold", 177),           # Lei-Lei
    ("vsavj", 0x0E, "c", "0x25", 0x23273c, 0x232614, 2, "hold", 130),           # Lilith
    ("vsav2", 0x11, "a", "0x41", 0x264086, 0x263fc6, 6, "out_of_region", 77),   # Pyron (the tenant; not a node chain)
]
for game, cid, t, seq, tab, start, n, end, entries in CASES:
    img = imgs[game]
    got_tab = table_ptr(game, cid, t)
    if got_tab != tab:
        BAD(f"{game} {NAMES[cid]} {t}: table {got_tab:#x}, frozen {tab:#x} (a moved bank row or view)"); continue
    w = int.from_bytes(img[tab + 2 * int(seq, 16):][:2], "big")
    if not w & 0x8000:
        BAD(f"{game} {NAMES[cid]} {t}:{seq}: the entry is not negative on this view (word sign bit clear)"); continue
    if tab + sext(w) != start:
        BAD(f"{game} {NAMES[cid]} {t}:{seq}: table + the signed word is {tab + sext(w):#x}, frozen {start:#x}"); continue
    r = anim_nodes.walk_table(img, 0, tab, len(img))
    if r["entries"] != entries:
        BAD(f"{game} {NAMES[cid]} {t}: {r['entries']} entries, frozen {entries} (a negative word bounded or ended the table)")
    c = r["chains"].get(seq)
    if c is None:
        BAD(f"{game} {NAMES[cid]} {t}:{seq}: not an entry of the walked table"); continue
    got = (c["start"], len(c["nodes"]), c["end"])
    want = (f"{start:#x}", n, end)
    if got != want:
        BAD(f"{game} {NAMES[cid]} {t}:{seq}: walked {got}, frozen {want}")
    else:
        print(f"  case {game} {NAMES[cid]} {t}:{seq}: start {c['start']} = table {tab:#x} {sext(w):+d}; {n} nodes, {end}")

# (b) THE CENSUS AND THE SWEEP: every negative entry of every character's five tables starts at
# table + the signed word; the count per character is frozen (vsavj: the 15 characters; vsav2:
# the three tenants, whose data the port takes from it).
CENSUS = {"vsavj": {"BU": 3, "DE": 2, "GA": 1, "VI": 5, "ZA": 16, "AN": 2, "FE": 1, "SA": 29, "QB": 5, "LE": 2, "LI": 5,
                    "MO": 0, "BI": 0, "AU": 0, "JE": 0},
          "vsav2": {"HU": 0, "PY": 1, "DO": 0}}
for game, want in CENSUS.items():
    img = imgs[game]
    got, swept = {}, 0
    for cid in (k for k, v in NAMES.items() if v in want):
        got[NAMES[cid]] = 0
        for t in TABLES:
            tab = table_ptr(game, cid, t)
            r = anim_nodes.walk_table(img, 0, tab, len(img))
            for seq, c in r["chains"].items():
                w = int.from_bytes(img[tab + 2 * int(seq, 16):][:2], "big")
                if not w & 0x8000:
                    continue
                got[NAMES[cid]] += 1; swept += 1
                if c["start"] != f"{tab + sext(w):#x}":
                    BAD(f"{game} {NAMES[cid]} {t}:{seq}: start {c['start']}, table + the signed word is {tab + sext(w):#x}")
    if got != want:
        BAD(f"{game}: negative entries per character {got}, frozen {want}")
    print(f"  census {game}: {swept} negative entries on {sum(1 for v in got.values() if v)} characters, every start table + the signed word"
          if got == want else f"  census {game}: {got}")
print(f"RESULT bad={bad}")
PY
}

echo "== 2. the walker on the reference views"
TOOLDIR="$REPO/tools"
if vs_ctl_is unsigned-read || vs_ctl_is negative-ends-table; then
    TOOLDIR="$W/shadow_$VS_CTL"
    echo "  CONTROL MODE: $VS_CTL — the check imports the shadow copy $TOOLDIR/anim_nodes.py, and must FAIL"
fi
check "$TOOLDIR" > "$W/main.txt" 2>&1
sed 's/^/  /' "$W/main.txt" | head -40
if command grep -qx 'RESULT bad=0' "$W/main.txt"; then ok "every case, census row and start as frozen"; else bad "the walker does not read the tables as frozen ($(command grep -c '^BAD' "$W/main.txt") findings)"; fi

echo "== 3. the must-fire controls"
if [ -z "${VS_CTL:-}" ]; then
    for c in unsigned-read negative-ends-table; do
        [ -f "$W/shadow_$c/anim_nodes.py" ] && ! cmp -s tools/anim_nodes.py "$W/shadow_$c/anim_nodes.py" \
            || { vs_ctl_dead "$c" "the shadow copy was not built (its edit did not apply)"; fail=1; continue; }
        check "$W/shadow_$c" > "$W/ctl_$c.txt" 2>&1
        n="$(command grep -c '^BAD' "$W/ctl_$c.txt")"
        case "$c" in
            unsigned-read)       hit="$(command grep -c '^BAD .*: walked (.0x' "$W/ctl_$c.txt")" ;;
            negative-ends-table) hit="$(command grep -cE '^BAD .*(: not an entry of the walked table| entries, frozen )' "$W/ctl_$c.txt")" ;;
        esac
        if [ "$n" -gt 0 ] && [ "$hit" -gt 0 ] && ! command grep -qx 'RESULT bad=0' "$W/ctl_$c.txt"; then
            vs_ctl_fired "$c" "$n findings, $hit of the kind it plants ($(command grep -m1 '^BAD' "$W/ctl_$c.txt" | cut -c5-130))"
        else
            vs_ctl_dead "$c" "the shadow copy read the tables as frozen ($n findings, $hit of its kind)"; fail=1
        fi
    done
fi

[ "$fail" = 0 ] && echo "PASS: test_anim_signed_offsets" || { echo "FAIL: test_anim_signed_offsets"; exit 1; }
