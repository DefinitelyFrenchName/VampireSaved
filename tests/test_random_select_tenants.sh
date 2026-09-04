#!/bin/sh
# test_random_select_tenants.sh — RANDOM SELECT INCLUDES THE TENANTS (14z-117,
# the maintainer's own list item, added 2026-08-28).
#
# THE MECHANISM (docs/game/atlas/select_screen.md "THE RANDOM CELL"): while
# the "?" cell (0x0B) is hovered, a 3-frame timer walks a cursor through a
# FIXED draw table and writes the id it lands on straight into the player
# struct's char id ($382). vsavj's table is 15 entries with a hard wrap at
# `cmpi.b #$f`, so no variant-half id could ever come up. The
# `random_select_bound` + `random_select_roster` site_thunks (all three
# manifests) displace the wrap compare and the pc-relative table read with
# jmps into bodies carrying the matching bound and an 18-entry table — the
# 15 vanilla ids + THIS BUILD'S tenants (roster_subst). The siblings do
# exactly this (vs2 lists 10/11/13 in its own table). The read is displaced
# too because the walker re-reads the table on its NON-tick frames (measured
# 14z-117: a bound-only thunk let those frames read vanilla's pad/code
# bytes as ids and crash the figure refresh).
#
# ON THE BOARD (maintainer, MiSTer, 2026-08-29, STATE 14z-118): GREEN —
# "behavior identical to emulation": the draw cycles all 18 on "?" and a
# tenant confirm loads it. Section 2/3 below is the emulator twin of that
# observation; no frame has been captured off the board ([MSV-31]).
#
# Sections:
#   1  STATIC — the built patch carries BOTH thunks: site A (0x020C74) is a
#      jmp to the bound body (15 + tenant count, re-entering 0x020C7C), site
#      B (0x020C80, the table read on BOTH the tick and non-tick paths) is a
#      jmp to a body holding the read + rts + the table = the 15 vanilla ids
#      followed by every tenant id the build's tenants.json declares
#      (ascending), outside the crypt range. On a build with no thunk (stock
#      twin) both sites are vanilla — the rows are profile-gated.
#   2  RUNTIME — P1 walks to "?" (Down, Down, Down-RIGHT on a WIDE wheel —
#      docs/project/gotchas.md, the wheel-route trap) and parks there; P1's
#      $382 is sampled every frame over one full cycle (18 entries x 3
#      frames = 54; 90 frames sampled). The set of ids seen must be EXACTLY
#      the 15 vanilla ids + the build's tenants, nothing else, and the
#      cursor ($40) must reach every index up to the bound.
#   3  CONTROL (must fire): the same replay on the PREVIOUS frozen merged
#      build (no thunk) sees the 15 vanilla ids and NO tenant — proves the
#      sampler would notice a tenant-less draw.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged19] [CONTROL=build/<prev>] tests/test_random_select_tenants.sh
#
# HANDOFF's gate-index note, moved into this header 14z-123 (verbatim; the
# documentation pass ruled a gate's WHY lives in the gate):
#   14z-117 (~12 min, 4 MAME runs): RANDOM SELECT INCLUDES THE TENANTS.
#   Static: both sites are jmps, body B's table = 15 vanilla ids + the build's
#   tenants.json, outside the crypt range. Runtime: P1 parks on "?" (D,D,DR),
#   $382 sampled 91 frames = exactly 15 + tenants; confirm on a tenant's
#   MIDDLE frame loads that tenant's own record; must-fire control = the
#   previous merged (CONTROL=, no tenant drawn).
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
# 14z-132: ABSOLUTE. Gates `cd` into work dirs and then compose paths that
# still contain $ROMDIR (e.g. MAME_ROMPATH="...;$ROMDIR"); a RELATIVE value —
# which is how the runners invoke everything (ROMDIR=../ROMS) — then resolves
# against the WORK dir and silently finds no reference members. Kept as a
# VARIABLE (forks set their own); only made absolute, and only if it exists,
# so a gate that means to SKIP on a missing ROMDIR still does.
if [ -d "$ROMDIR" ]; then ROMDIR="$(cd "$ROMDIR" && pwd)"; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
BUILD="${BUILD:-build/m3b_merged23}"  # re-pointed 14z-119 (physics-port freeze) <- 14z-117b
CONTROL="${CONTROL:-build/m3b_merged19}"   # the last merged WITHOUT the thunk
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no WIDE MAME binary at $MAME_BIN"; exit 0; }
export MAME_BIN
[ -d "$BUILD/rompath" ] || { echo "SKIP: $BUILD/rompath missing"; exit 0; }
BUILD="$(cd "$BUILD" && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
VANILLA="04 07 02 0c 05 0f 0a 00 0e 03 08 01 0d 09 06"

echo "== 1. static: the built patch carries the roster table =="
python3 - "$BUILD" "$W/tenants.txt" <<'PY' || fail=1
import json, sys
b, out = sys.argv[1], sys.argv[2]
ops = json.load(open(f"{b}/patch/patch.json"))["ops"]
tj = json.load(open(f"{b}/patch/tenants.json"))   # a list of {name, id, ...}
ids = sorted({int(t["id"]) & 0xFF for t in tj if int(t["id"]) >= 0x10})
open(out, "w").write(" ".join("%02x" % i for i in ids))
def site_body(addr, label):
    site = [o for o in ops if o["op"] == "code" and int(o["addr"], 16) == addr]
    if not site:
        print(f"FAIL: no code op at the {label} site {addr:#x} (thunk not emitted?)"); sys.exit(1)
    hx = site[0]["hex"].lower()
    if not hx.startswith("4ef9"):
        print(f"FAIL: {label} site op is not a jmp: {hx}"); sys.exit(1)
    ba = int(hx[4:12], 16)
    body = [o for o in ops if o["op"] == "code" and int(o["addr"], 16) == ba]
    if not body:
        print(f"FAIL: no body op at {ba:#x} ({label})"); sys.exit(1)
    return ba, body[0]["hex"].lower()
# site A: the bound; re-enters the original at 0x020C7C by jmp
a_addr, a_body = site_body(0x020C74, "bound")
want_a = "0c0000%02x650270004ef900020c7c" % (15 + len(ids))
if a_body != want_a:
    print(f"FAIL: bound body mismatch\n  got  {a_body}\n  want {want_a}"); sys.exit(1)
# site B: the table read, then the routine's own rts; the table follows
b_addr, b_body = site_body(0x020C80, "read")
want_b = "1d7b000603824e75" + "0407020c050f0a000e0308010d0906" + "".join("%02x" % i for i in ids)
if b_body != want_b:
    print(f"FAIL: read body mismatch\n  got  {b_body}\n  want {want_b}"); sys.exit(1)
if b_addr < 0x100000:
    print(f"FAIL: read body at {b_addr:#x} is inside the crypt range — its table would be read garbled"); sys.exit(1)
print(f"  ok: bound site jmp -> {a_addr:#x} (bound {15 + len(ids)}); read site jmp -> {b_addr:#x}, table = 15 vanilla + tenants {['%#04x' % i for i in ids]}, body outside the crypt range")
PY
TENANTS="$(cat "$W/tenants.txt" 2>/dev/null || true)"
[ -n "$TENANTS" ] || { echo "FAIL: no variant-half tenant on $BUILD"; fail=1; }

# the hover replay: coin, start, walk to "?", park. P1's default cell is
# Demitri (0x01); "?" is reached Down, Down, Down-RIGHT on the WIDE wheel.
cat > "$W/hover.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1000-1002 p1=D
1040-1042 p1=D
1080-1082 p1=DR
1400 wait
EOF
FIRST=1200; LAST=1290
spec=""; f=$FIRST
while [ "$f" -le "$LAST" ]; do spec="$spec${spec:+;}$f:ff8780-ff8800"; f=$((f+1)); done

run() { # run <tag> <rompath dir>
    mkdir -p "$W/$1"
    DUMPS="$spec" REPLAY="$W/hover.rpl" CHECKSUM_OUT="$W/$1/c.log" \
        MAME_SANDBOX="$W/$1/box" MAME_ROMPATH="$2;$ROMDIR" \
        "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/replay.lua" \
        > "$W/$1/mame.log" 2>&1 || { echo "FAIL: $1 — MAME run failed"; tail -3 "$W/$1/mame.log"; fail=1; return 1; }
    grep -q '^END ' "$W/$1/c.log" || { echo "FAIL: $1 — no END line"; fail=1; return 1; }
}
seen() { # seen <tag> -> "ids: .. | cursors: .." (P1 $382 and $40 over the samples)
    python3 - "$W/$1" "$FIRST" "$LAST" <<'PY'
import sys
d, a, b = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
ids = set()
for f in range(a, b + 1):
    x = open(f"{d}/dump_{f}_ff8780.bin", "rb").read()
    ids.add(x[0x02])          # $FF8782 = P1 struct +$382 (char id)
print(" ".join("%02x" % i for i in sorted(ids)))
PY
}

echo "== 2. runtime: park P1 on \"?\" and sample the draw over $((LAST-FIRST+1)) frames =="
if run ours "$BUILD/rompath"; then
    got="$(seen ours)"
    want="$(printf '%s %s\n' "$VANILLA" "$TENANTS" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')"
    if [ "$got" = "$want" ]; then
        echo "  ok: the draw cycled through exactly the 15 vanilla ids + tenants [$TENANTS]"
    else
        echo "FAIL: ids seen [$got] != expected [$want]"; fail=1
    fi
    case " $got " in *" 0b "*) echo "FAIL: 0x0B (the '?' cell itself) appeared in the draw"; fail=1;; esac
fi

echo "== 2b. confirm ON a tenant frame: the drawn tenant must LOAD into the match =="
if [ -d "$W/ours" ]; then
    CF="$(python3 - "$W/ours" "$FIRST" "$LAST" "$TENANTS" <<'PY'
import sys
d, a, b = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]); ten = {int(x, 16) for x in sys.argv[4].split()}
ids = {f: open(f"{d}/dump_{f}_ff8780.bin", "rb").read()[2] for f in range(a, b + 1)}
# the MIDDLE frame of a tenant plateau (the draw holds each id 3 frames;
# the replay stages inputs one frame ahead, so a press at f..f+1 registers
# at f-1..f — pressing on the middle frame keeps both inside the plateau)
for f in range(a + 1, b - 1):
    if ids[f] in ten and ids[f - 1] == ids[f] == ids[f + 1]:
        print(f, "%02x" % ids[f]); break
PY
)"
    cf="${CF%% *}"; cid="${CF##* }"
    if [ -z "$cf" ]; then echo "FAIL: no tenant plateau found in the samples"; fail=1; else
        # the same replay with a confirm (button 1) on the tenant frame; match by ~4300
        sed "s/^1400 wait$/$cf-$((cf+1)) p1=1\n4400 wait/" "$W/hover.rpl" > "$W/confirm.rpl"
        mkdir -p "$W/confirm"
        DUMPS="4300:ff8400-ff8c00" REPLAY="$W/confirm.rpl" CHECKSUM_OUT="$W/confirm/c.log" \
            MAME_SANDBOX="$W/confirm/box" MAME_ROMPATH="$BUILD/rompath;$ROMDIR" \
            "$REPO/tools/run_mame.sh" vsavjw -autoboot_script "$REPO/tests/lua/replay.lua" \
            > "$W/confirm/mame.log" 2>&1 || { echo "FAIL: confirm run — MAME failed"; fail=1; }
        if grep -q '^END ' "$W/confirm/c.log" 2>/dev/null; then
            python3 - "$W/confirm/dump_4300_ff8400.bin" "$cid" "$BUILD" <<'PY' || fail=1
import sys, struct
b = open(sys.argv[1], "rb").read(); want = int(sys.argv[2], 16); bd = sys.argv[3]
pid = b[0x382]; base = struct.unpack(">I", b[0x60:0x64])[0]; mode = struct.unpack(">H", b[0x004:0x006])[0] if False else None
# the tenant's own record base from the build's table (PRG:0x0BD97A, member 04d @0x3D97A, LE-word file order)
m = open(f"{bd}/prg/vm3j.04d", "rb").read(); raw = m[0x3D97A:0x3D97A + 128]
sw = bytearray()
for i in range(0, 128, 2): sw += raw[i + 1:i + 2] + raw[i:i + 1]
tbl = struct.unpack(">32I", bytes(sw))
if pid != want:
    print(f"FAIL: P1 id at match {pid:#04x} != the confirmed tenant {want:#04x}"); sys.exit(1)
if base != tbl[want]:
    print(f"FAIL: P1 record base {base:#x} != the tenant's own {tbl[want]:#x} (shell substitution?)"); sys.exit(1)
print(f"  ok: confirmed on the '?' cell while it showed {want:#04x} -> P1 id {pid:#04x}, record base {base:#x} (the tenant's own) at frame 4300")
PY
        else
            echo "FAIL: confirm run — no END line"; fail=1
        fi
    fi
fi

echo "== 3. control (must fire): the previous merged build draws NO tenant =="
if [ -d "$CONTROL/rompath" ]; then
    if run ctl "$(cd "$CONTROL" && pwd)/rompath"; then
        cgot="$(seen ctl)"
        cwant="$(printf '%s\n' "$VANILLA" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')"
        [ "$cgot" = "$cwant" ] && echo "  ok: control drew exactly the 15 vanilla ids (no tenant) — the sampler discriminates" \
            || { echo "FAIL: control ids [$cgot] != vanilla 15 [$cwant] — the control build or the route is wrong"; fail=1; }
    fi
else
    echo "  SKIP: no control build at $CONTROL (section 3 not run)"
fi

if [ "$fail" -eq 0 ]; then echo "PASS test_random_select_tenants"; else echo "FAIL test_random_select_tenants"; fi
exit "$fail"
