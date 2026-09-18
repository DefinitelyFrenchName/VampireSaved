#!/bin/sh
# audit_facing_rule.sh — THE VICTIM FACING RULE 5 ON OUR ENGINE, ours vs native, frozen AS MEASURED (GitHub #159, 14z-167): vs2's facing-rule resolver knows rule 5 and vsavj's does not, so a tenant attack record carrying it is XORed into the victim's facing on our build.
#
# MUST-FIRE: perturbed-copy: rule5-resolved — a copy of our facing rows with the resolver's value replaced by native's at the same frame (what a fixed build would write) must FAIL the frozen compare, so the frozen rows are the defect and a fix is a deliberate re-freeze (in-gate: the perturbed copy must differ from the frozen rows; mode: our reduced rows are replaced before the compare and the table FAILs)
# MUST-FIRE: perturbed-copy: branch-planted — a copy of vsavj's decrypted opcode image with the resolver's rule-4 compare rewritten to `cmpi.b #5` must change vsavj's static row and FAIL, so the static read sees the compare chain it claims to list (in-gate: the planted copy must read differently; mode: the real image is planted before the static read and the table FAILs)
#
# WHY. An attack record's +0xE is the victim's FACING RULE, resolved into the
# victim's +0x5D at every contact (docs/game/engine_internals.md, the attack
# record's fields). vs2's resolver (PRG:0x1717E) tests rules 2, 3, 4 AND 5 ("by
# the attacker's velocity sign"); vsavj's (PRG:0x18854) tests 2, 3 and 4 only,
# so a 5 falls through to `eor.b d0,$5d(a1)` (0x1886C) and 1 XOR 5 = 4 lands in
# the byte. The pushback step routine (vs2 0x27038) signs every step by +0x5D
# (0 -> negated, nonzero -> added), so Killshread Summon (ES)'s returning wave
# drags Demitri 80 px TOWARD Donovan on native, while on ours the same steps are
# ADDED, away from Donovan, and his x holds at 835 (what holds it there is not
# measured; the frozen x rows are the measurement, 835/835 against 835/755). Measured 14z-167 (build/x_family_14z167/; rule-checker run 2026-09-18-42,
# its Q3 resolved by work); the maintainer compared the captures first:
# "But looking at the background it does seems that VS2 has demitri going
# forward while our Demitri stays in place."
#
# WHAT IT FREEZES (tests/expected/facing_rule.tsv):
#   static  <game> <resolver addr> rules=<the cmpi.b #N values of the compare chain>
#   legacy  <game> records=<reachable legacy attack records> rule5=<how many carry rule 5>
#           rules=<the full +0xE histogram>  — tools/audit_facing_rules.py, the legacy control
#           (added 14z-167b: vsavj 0 of 1,085, vsav2 1 of 1,143)
#   facing  <leg> <frame> <writer PC> <+0x5D after the write>  — every write to
#           Demitri's +0x5D from 3850 to 3960 on the #136 rig donovan_3 (event 5,
#           Killshread Summon (ES) at 3840), both legs REAL cursor picks
#   x       <leg> <frame> <Demitri's x>  — sampled per frame (tests/lua/field_trace.lua;
#           a write tap of $FF8810 crashed MAME, 14z-167) at 3924 (the last contact)
#           and 3946 (the slide's end)
# THE DEFECT IS FROZEN AS MEASURED: ours writes 4 at 0x1886C where native's
# rule-5 branch 0x171E0 writes 1 (outgoing wave) and 0 (returning wave), and
# ours' x holds at 835 where native's slides to 755. A fix re-freezes this file
# DELIBERATELY, with its rule-checker run named in the commit.
#
# WHAT IT DOES NOT COVER: the other rule-5 records (Donovan's 0xCA1CA/0xCA1EA,
# 0xD17C2/0xD1822 — GitHub #159); what holds ours at 835; P2-side tenants; the
# one-leg taps are non-debug (tests/lua/read_tap.lua), frames >= 3850 only.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged26] [FREEZE=1] tests/audit_facing_rule.sh
#   emulator tier, MAME; four runs in parallel plus the two views from the build/out decrypt cache —
#   measured 14z-167b on this MacBook, solo: ~5 s wall (verify), each control mode the same
set -eu
[ -n "${ROMDIR:-}" ] || { echo "FAIL: set ROMDIR"; exit 1; }
[ -d "$ROMDIR" ] && ROMDIR="$(cd "$ROMDIR" && pwd)"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
BUILD="${BUILD:-build/m3b_merged26}"
case "$BUILD" in /*) ;; *) BUILD="$REPO/$BUILD" ;; esac
EXPECT="$REPO/tests/expected/facing_rule.tsv"
CONTROL="${CONTROL:-}"
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
[ -f "$ROMDIR/vsav2.zip" ] || { echo "SKIP: no vsav2.zip in $ROMDIR"; exit 0; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no WIDE build at $BUILD"; exit 0; }
case "$CONTROL" in ""|rule5-resolved|branch-planted) ;; *) echo "REFUSED: no control named '$CONTROL' is declared by this gate"; exit 3 ;; esac
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT INT TERM
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
PART=donovan_3; TENANT=donovan; FR=3960; FROM=3850
# --- the rig as tests/audit_move_parity.sh builds it (pokes_for / rpl_for / OURS_PATH, copied) ---
OURS_PATH_donovan="D D DR DR"
pokes_for() {  # pokes_for <json> <frames>
    _b="$(python3 -c "import json;print(';'.join(json.load(open('$1'))['pokes']))")"
    _l="$(python3 -c "print(';'.join(f'{f}:ff8116:06' for f in range(2000,$2)))")"
    _r="$(python3 -c "print(';'.join(f'{f}:ff80d4:0000' for f in range(2363,$2)))")"
    printf '%s;%s;%s' "$_b" "$_l" "$_r"
}
rpl_for() {  # rpl_for <tenant> <rig.rpl> <leg> <out.rpl>
    if [ "$3" = native ]; then cp "$2" "$4"; return; fi
    eval "_path=\$OURS_PATH_$1"
    awk -v path="$_path" '
        /^1104-1106 p2=R$/ && !done { n = split(path, m, " "); t = 1100
            for (i = 1; i <= n; i++) { printf "%d-%d p1=%s\n", t, t + 2, m[i]; t += 60 }; done = 1 }
        /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next }
        { print }' "$2" > "$4"
}
tap() {  # tap <name> <set> <rompath> <rpl> <pokes> <rtap> <out.txt>   (background)
    mkdir -p "$W/$1"
    # (14z-168) MAME can segfault at TEARDOWN after the instrument has closed its log (docs/platform/gotchas.md):
    # `set +e` keeps the status write alive, and a run whose instrument wrote its summary line counts as
    # completed (docs/project/gotchas.md, the set -e capture entry)
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$FR" \
        RTAP="$6" WINDOW="$FROM,$FR" TRACE_OUT="$7" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/read_tap.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$7" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
sample() {  # sample <name> <set> <rompath> <rpl> <pokes> <out.txt>: Demitri's x per frame (tests/lua/field_trace.lua, as the parity gate samples)   (background)
    mkdir -p "$W/$1"
    ( set +e; cd "$W/$1" && MAME_SANDBOX="$W/$1/sb" MAME_ROMPATH="$3" REPLAY="$4" POKES="$5" FRAMES="$FR" \
        FIELDS="ff8810:w:p2x" FIELD_OUT="$6" FIELD_FROM="$FROM" FIELD_TO="$FR" \
        "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$W/$1/mame.log" 2>&1
      _st=$?; grep -q -E '^(FIELDSUMMARY|END )' "$6" 2>/dev/null && _st=0; echo $_st > "$W/$1/rc"; rm -rf "$W/$1/sb" ) </dev/null &
}
# ONE static reader, shared by the gate and the branch-planted control: image -> row
static_row() {  # static_row <game> <opcode image>
    python3 - "$1" "$2" <<'PY'
import sys
g, p = sys.argv[1], sys.argv[2]; d = open(p, "rb").read()
pat = bytes.fromhex("102b000e6b")          # move.b $e(a3),d0 ; bmi — the resolver's head
hits = []; i = -1
while True:
    i = d.find(pat, i + 1)
    if i < 0: break
    hits.append(i)
if len(hits) != 1: sys.exit(f"VOID: {len(hits)} resolver heads in {p} (want exactly one)")
a = hits[0]; rules = []; k = a + 6
while d[k:k + 2] == b"\x0c\x00" and d[k + 4] == 0x67:   # cmpi.b #N,d0 ; beq.b
    rules.append(int.from_bytes(d[k + 2:k + 4], "big")); k += 6
print(f"static\t{g}\t{a:#08x}\trules={','.join(map(str, rules))}")
PY
}
plant_branch() {  # plant_branch <image in> <image out>: the rule-4 compare rewritten to cmpi.b #5
    python3 - "$1" "$2" <<'PY'
import sys
d = bytearray(open(sys.argv[1], "rb").read()); a = d.find(bytes.fromhex("102b000e6b"))
k = d.find(bytes.fromhex("0c000004"), a, a + 0x30)
if a < 0 or k < 0: sys.exit("REFUSED: no rule-4 compare to plant over")
d[k:k + 4] = bytes.fromhex("0c000005"); open(sys.argv[2], "wb").write(d)
PY
}
# ONE reducer: the two tap logs of a leg -> facing and x rows
reduce() {  # reduce <leg> <face tap> <x tap>
    python3 - "$1" "$2" "$3" "$FROM" <<'PY'
import sys
leg, ft, xt, lo = sys.argv[1:5]; lo = int(lo)
def ws(p):
    out, ended = [], False
    for l in open(p):
        t = l.split()
        if not t: continue
        if t[0] == "END": ended = True
        if t[0] == "W": out.append((int(t[1]), t[3], int(t[7], 16), int(t[9], 16)))
    if not ended: sys.exit(f"VOID: {p} has no END line (a dead tap is not evidence)")
    return out
for f, pc, v, m in ws(ft):
    if m & 0xff and f >= lo: print(f"facing\t{leg}\t{f}\t{pc}\t{v & 0xff:02x}")
xs = {}
for l in open(xt):
    t = l.split()
    if t and t[0] == "F": xs[int(t[1])] = dict(kv.split("=", 1) for kv in t[2:]).get("p2x")
for at in (3924, 3946):
    if at not in xs: sys.exit(f"VOID: {xt} has no sample at frame {at}")
    print(f"x\t{leg}\t{at}\t{xs[at]}")
PY
}
fix_rows() {  # fix_rows <native rows> <ours rows>: ours' resolver values replaced by native's at the same frame
    python3 - "$1" "$2" <<'PY'
import sys
nat = {}
for l in open(sys.argv[1]):
    t = l.rstrip("\n").split("\t")
    if t[0] == "facing": nat.setdefault(t[2], []).append(t[4])
seen = {}
for l in open(sys.argv[2]):
    t = l.rstrip("\n").split("\t")
    if t[0] == "facing":
        k = seen.get(t[2], 0); seen[t[2]] = k + 1
        if t[2] in nat and k < len(nat[t[2]]): t[4] = nat[t[2]][k]
    print("\t".join(t))
PY
}

echo "== 1. the static resolvers, both games"
# through the build/out cache helper, never a direct decrypt (tests/test_decrypt_cache.sh §5, GitHub #69: a
# short image is refused loudly instead of being read as garbage)
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vsavj_op.bin" "$W/vsavj_da.bin" || bad "vsavj views not delivered"
decrypt_view vsav2 "$W/vsav2_op.bin" "$W/vsav2_da.bin" || bad "vsav2 views not delivered"
[ "$fail" = 0 ] || { echo "FAIL: audit_facing_rule"; exit 1; }
if [ "$CONTROL" = branch-planted ]; then plant_branch "$W/vsavj_op.bin" "$W/vsavj_op.pl" && mv "$W/vsavj_op.pl" "$W/vsavj_op.bin"; fi
{ static_row vsavj "$W/vsavj_op.bin" && static_row vsav2 "$W/vsav2_op.bin" \
  && python3 "$REPO/tools/audit_facing_rules.py" "$W/vsavj_da.bin" "$W/vsav2_da.bin" --tsv; } > "$W/static.rows" 2> "$W/static.err" || { bad "static read: $(cat "$W/static.err")"; }
sed 's/^/  /' "$W/static.rows"

echo "== 2. the taps, both legs ($PART, frames $FROM-$FR)"
j="$REPO/tests/replays/naming/$PART.json"; r="$REPO/tests/replays/naming/$PART.rpl"
pk="$(pokes_for "$j" "$FR")"
rpl_for "$TENANT" "$r" native "$W/native.rpl"; rpl_for "$TENANT" "$r" ours "$W/ours.rpl"
ORP="$BUILD/rompath;$ROMDIR"
tap n.f vsav2  "$ROMDIR" "$W/native.rpl" "$pk" ff885c,2 "$W/native.face.txt"
sample n.x vsav2  "$ROMDIR" "$W/native.rpl" "$pk" "$W/native.x.txt"
tap o.f vsavjw "$ORP"    "$W/ours.rpl"   "$pk" ff885c,2 "$W/ours.face.txt"
sample o.x vsavjw "$ORP"    "$W/ours.rpl"   "$pk" "$W/ours.x.txt"
wait
for t in n.f n.x o.f o.x; do _rc="$(cat "$W/$t/rc" 2>/dev/null || echo none)"; [ "$_rc" = 0 ] || bad "run $t exited $_rc (an emulator that crashed is not evidence)"; done
for leg in native ours; do
    for k in face x; do [ -s "$W/$leg.$k.txt" ] || { bad "$leg: tap $k produced nothing"; }; done
    reduce "$leg" "$W/$leg.face.txt" "$W/$leg.x.txt" > "$W/$leg.rows" 2> "$W/$leg.err" || bad "$leg: $(cat "$W/$leg.err")"
done
[ "$fail" = 0 ] || { echo "FAIL: audit_facing_rule (a leg did not run or was VOID)"; exit 1; }
if [ "$CONTROL" = rule5-resolved ]; then fix_rows "$W/native.rows" "$W/ours.rows" > "$W/ours.fx" && mv "$W/ours.fx" "$W/ours.rows"; fi
cat "$W/static.rows" "$W/native.rows" "$W/ours.rows" > "$W/got.tsv"
ok "static rows $(wc -l < "$W/static.rows" | tr -d ' '), native $(grep -c '^facing' "$W/native.rows" | tr -d ' ') facing writes, ours $(grep -c '^facing' "$W/ours.rows" | tr -d ' ')"

echo "== 3. the frozen rows"
if [ "${FREEZE:-0}" = 1 ]; then
    {
        echo "# tests/expected/facing_rule.tsv — the victim facing rule 5, ours (merged-m18) vs native vsav2 (tests/audit_facing_rule.sh;"
        echo "# tests/lua/read_tap.lua, non-debug; the static rows from the decrypted opcode images). Evidence class: in-emulator"
        echo "# plus static. Frozen 14z-167 with FREEZE=1 (GitHub #159). THE DEFECT IS FROZEN AS MEASURED: vsavj's resolver lists no rule 5,"
        echo "# ours writes 4 at 0x1886C where native's rule-5 branch 0x171E0 writes 1 / 0, and ours' x holds where native's slides."
        echo "# A fix re-freezes this file DELIBERATELY, with its rule-checker run named in the commit."
        echo "# Columns: kind (static | facing | x), game or leg, address or frame, then rules= / writer PC and value / x"
        echo "#--"
        cat "$W/got.tsv"
    } > "$EXPECT"
    echo "  FROZE  $(basename "$EXPECT") ($(wc -l < "$W/got.tsv" | tr -d ' ') rows) — VERIFY by re-running without FREEZE"; exit 0
fi
[ -f "$EXPECT" ] || { echo "FAIL: no frozen expectation at $EXPECT (FREEZE=1 to create it)"; exit 1; }
grep -v '^#' "$EXPECT" > "$W/want.tsv"
if diff "$W/want.tsv" "$W/got.tsv" > "$W/diff.txt"; then ok "every row as frozen"
else bad "differs from the frozen rows"; sed 's/^/        /' "$W/diff.txt"; fi

echo "== 4. must-fire controls"
if [ "$CONTROL" = rule5-resolved ] || [ "$CONTROL" = branch-planted ]; then
    if [ "$fail" = 1 ]; then echo "CONTROL FIRED: $CONTROL — the perturbed input loses the frozen rows"; echo "FAIL: audit_facing_rule (control mode)"; exit 1
    else echo "CONTROL DEAD: $CONTROL — the perturbed input still matched"; echo "FAIL: audit_facing_rule"; exit 1; fi
fi
fix_rows "$W/native.rows" "$W/ours.rows" > "$W/ctl.rows"
if diff -q "$W/ours.rows" "$W/ctl.rows" > /dev/null; then echo "CONTROL DEAD: rule5-resolved — native's values change nothing in ours' rows"; fail=1
else echo "CONTROL FIRED: rule5-resolved — ours' rows with native's resolver values differ from the frozen rows ($(diff "$W/ours.rows" "$W/ctl.rows" | grep -c '^>' | tr -d ' ') rows)"; fi
plant_branch "$W/vsavj_op.bin" "$W/ctl_op.bin" && static_row vsavj "$W/ctl_op.bin" > "$W/ctl.static" 2>/dev/null || true
if [ -s "$W/ctl.static" ] && ! grep -qxF "$(head -1 "$W/static.rows")" "$W/ctl.static"; then
    echo "CONTROL FIRED: branch-planted — the planted image reads $(cut -f4 "$W/ctl.static") against the real $(head -1 "$W/static.rows" | cut -f4)"
else echo "CONTROL DEAD: branch-planted — the planted compare was not read"; fail=1; fi

if [ "$fail" = 0 ]; then echo "PASS: audit_facing_rule"; else echo "FAIL: audit_facing_rule"; exit 1; fi
