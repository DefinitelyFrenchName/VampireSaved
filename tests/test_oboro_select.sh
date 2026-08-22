#!/bin/sh
# test_oboro_select.sh — THE OBORO SELECT HOOK (W1, 14z-105; maintainer-ruled
# 2026-08-22: vanilla vsavj Oboro, selected by hand).
#
# vsavj ships Oboro Bishamon complete at variant id 0x18 (hitbox base
# 0x0B3450, docs/game/atlas/character_tables.md) and the select commit path
# accepts the id end-to-end; what it lacks is a player-facing way to pick
# him. The hook (site_thunk `oboro_select_hook`, PRG:0x020B9C, every tenant
# manifest, profile-gated) is vanilla's own Gallon-variant idiom one cell
# over: on Bishamon's cell with START held at confirm, commit 0x18.
#
# MEASURED 14z-105 (this file is the rerunnable form): `btst #7,$394(a6)` —
# the input bit vanilla's Gallon path tests at PRG:0x020BA4 — IS the Start
# button (struct +0x394 reads $8000 with Start held on select, $0000
# without); the per-player bitmask $FF8060 reads 1 at the same time. Both
# sources are live at select; the hook uses vanilla's.
#
# Legs (MAME, WIDE build; no pokes — the pick is made with the sticks):
#   A  P1 on Bishamon + P1 Start held at confirm -> id 0x18, the match
#      loads base 0x0B3450 (Oboro's own dataset)            [the feature]
#   B  same, no Start                          -> id 0x08, base 0x0A6418
#                                                            [branch-inert]
#   C  P1 Start held on DEMITRI's cell         -> id 0x01 (cell-gated)
#   D  P2 on Bishamon + P2 Start held (2P game)-> P2 id 0x18, base
#      0x0B3450; P1 (Demitri, no hold) untouched             [per-player]
#   E  STOCK build, leg A's inputs              -> id 0x08 (the row is
#      profile-gated; the stock twin carries no hook)        [superset]
#   F  legs A and B again on FBNeo — the dual-emulator agreement for
#      new-character content (CLAUDE.md §4); skipped with a note when
#      the FBNeo binary is absent                            [dual-emu]
# Every leg asserts BOTH the committed id (+0x382 at confirm+10) and the
# loaded hitbox base (+0x60 in-match), so a passing leg proves the pick
# produced the CHARACTER, not just a byte.
#
# Usage: ROMDIR=... tests/test_oboro_select.sh [wide_rompath] [stock_rompath]
#   defaults: build/m3b_merged13/rompath, build/m5_stock6/rompath
set -eu
ROMDIR="${ROMDIR:?set ROMDIR}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
WIDE="${1:-build/m3b_merged13/rompath}"
STOCK="${2:-build/m5_stock6/rompath}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
for d in "$WIDE" "$STOCK"; do
    [ -d "$d" ] || { echo "SKIP: $d missing (build it first)"; exit 77; }
done
WIDE="$(cd "$WIDE" && pwd)"; STOCK="$(cd "$STOCK" && pwd)"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
fail=0

# P1: default cell 0x01 -> D -> 0x06 -> D -> 0x08 (TABLE B, measured
# tests/test_select_wheel.sh). P2: default cell 0x05 -> D 0x0A -> D 0x09
# -> L 0x0B -> L 0x08 (measured 14z-105, dump at f990 shows P2 on 0x05).
cat > "$WORK/p1.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1000-1002 p1=D
1040-1042 p1=D
1100-1400 sys=S1
1200-1202 p1=1
1600-1602 p1=1
3400 wait
EOF
sed 's/^1100-1400 sys=S1/# no hold/' "$WORK/p1.rpl" > "$WORK/p1_nohold.rpl"
cat > "$WORK/p1_demitri.rpl" <<'EOF'
300-305 sys=C1
800-803 sys=S1
1100-1400 sys=S1
1200-1202 p1=1
1600-1602 p1=1
3400 wait
EOF
cat > "$WORK/p2.rpl" <<'EOF'
300-305 sys=C1
330-335 sys=C2
800-803 sys=S1
830-833 sys=S2
1000-1002 p2=D
1040-1042 p2=D
1080-1082 p2=L
1120-1122 p2=L
1160-1400 sys=S2
1250-1252 p1=1 p2=1
3400 wait
EOF

run() { # run <label> <rompath> <set> <replay> <confirm_frame>
    mkdir -p "$WORK/$1"
    DUMPS="$5:ff8400-ff8c00;3000:ff8400-ff8c00" REPLAY="$4" \
        CHECKSUM_OUT="$WORK/$1/c.log" MAME_SANDBOX="$WORK/$1/box" \
        MAME_ROMPATH="$2;$ROMDIR" tools/run_mame.sh "$3" \
        -autoboot_script tests/lua/replay.lua > "$WORK/$1/mame.log" 2>&1 || {
            echo "FAIL: $1 — MAME run failed"; tail -5 "$WORK/$1/mame.log"; fail=1; return; }
    grep -q '^END ' "$WORK/$1/c.log" || { echo "FAIL: $1 — no END"; fail=1; return; }
}
field() { # field <label> <frame> <side 0|1> <id|base>
    python3 - "$WORK/$1/dump_$2_ff8400.bin" "$3" "$4" <<'PY'
import sys
b = open(sys.argv[1], "rb").read(); o = 0x400 * int(sys.argv[2])
print(f"{b[o + 0x382]:#04x}" if sys.argv[3] == "id"
      else f"{int.from_bytes(b[o + 0x60:o + 0x64], 'big'):#x}")
PY
}
fbfield() { # fbfield <dumpfile> <id|base>  (P1 struct at the dump's start)
    python3 - "$1" "$2" <<'PY'
import sys
b = open(sys.argv[1], "rb").read()
print(f"{b[0x382]:#04x}" if sys.argv[2] == "id"
      else f"{int.from_bytes(b[0x60:0x64], 'big'):#x}")
PY
}
check() { # check <label> <frame> <side> <want_id> <want_base>
    i="$(field "$1" "$2" "$3" id)"; b="$(field "$1" 3000 "$3" base)"
    if [ "$i" = "$4" ] && [ "$b" = "$5" ]; then
        echo "  ok: $1 side $3 -> id $i, base $b"
    else
        echo "FAIL: $1 side $3 -> id $i base $b (want $4 / $5)"; fail=1
    fi
}

echo "== A/B: P1 Start-held pick on Bishamon vs the no-hold control (WIDE) =="
run A "$WIDE" vsavjw "$WORK/p1.rpl" 1210
run B "$WIDE" vsavjw "$WORK/p1_nohold.rpl" 1210
check A 1210 0 0x18 0xb3450
check B 1210 0 0x08 0xa6418
echo "== C: Start held on another cell is inert =="
run C "$WIDE" vsavjw "$WORK/p1_demitri.rpl" 1210
check C 1210 0 0x01 0x93b6a
echo "== D: the P2 side =="
run D "$WIDE" vsavjw "$WORK/p2.rpl" 1260
check D 1260 1 0x18 0xb3450
check D 1260 0 0x01 0x93b6a
echo "== E: the STOCK twin carries no hook (profile-gated) =="
run E "$STOCK" vsavj "$WORK/p1.rpl" 1210
check E 1210 0 0x08 0xa6418

echo "== F: dual-emulator agreement — the same pick on FBNeo (CLAUDE.md §4) =="
# Measured 14z-105: FBNeo agrees with MAME field-for-field on both legs.
if [ -x "$REPO/emu/fbneo/fbneo" ]; then
    for leg in p1:0x18:0xb3450 p1_nohold:0x08:0xa6418; do
        r="${leg%%:*}"; rest="${leg#*:}"; wi="${rest%%:*}"; wb="${rest#*:}"
        mkdir -p "$WORK/fb_$r"
        ( cd "$WORK/fb_$r" && FBNEO_DUMPS="1210:ff8400-ff8800;3000:ff8400-ff8800"             FBNEO_ROMPATH="$WIDE" "$REPO/tools/run_replay_fbneo.sh" vsavjw             "$WORK/$r.rpl" "$WORK/fb_$r/c.log" "$WORK/fb_$r/box" > run.log 2>&1 ) || {
            echo "FAIL: FBNeo leg $r did not run"; fail=1; continue; }
        fi_="$(fbfield "$WORK/fb_$r/c.log.dump_1210_ff8400.bin" id)"
        fb_="$(fbfield "$WORK/fb_$r/c.log.dump_3000_ff8400.bin" base)"
        if [ "$fi_" = "$wi" ] && [ "$fb_" = "$wb" ]; then
            echo "  ok: FBNeo $r -> id $fi_, base $fb_ (agrees with MAME)"
        else
            echo "FAIL: FBNeo $r -> id $fi_ base $fb_ (want $wi / $wb)"; fail=1
        fi
    done
else
    echo "  (FBNeo binary absent — leg F not run; MAME legs stand alone)"
fi

# verdict control: the checker must be able to fail — a deliberately wrong
# expectation against leg A's real dump must print FAIL (run in a subshell
# so the global verdict is untouched)
if (fail=0; check A 1210 0 0x08 0xa6418) | grep -q '^FAIL'; then
    echo "  ok: verdict control — a wrong expectation is refused"
else
    echo "FAIL: verdict control — a wrong expectation was accepted"; fail=1
fi

if [ "$fail" = 0 ]; then
    echo "PASS: Oboro select hook — Start-held Bishamon commits 0x18 and loads"
    echo "      Oboro's dataset (both sides); no-hold / other-cell / stock inert"
else
    echo "FAIL: Oboro select hook"; exit 1
fi
