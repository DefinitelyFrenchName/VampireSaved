#!/bin/sh
# audit_air_dash_height.sh — PHOBOS'S AIR DASH UNDER vs2's MINIMUM HEIGHT: native refuses it, and since M23
# ours does too (GitHub #222, measured in play 14z-191, closed 14z-192). Emulator tier (MAME), ~2 min.
#
# WHAT: Phobos jumps straight up and inputs the air dash j.66 with the second R at +5..+16 frames; at +5 (height 21,
#   under vs2's table row 0x10 = 24) native vs2 does not dash, and since the M23 build takes vs2's mask bit and row
#   (14z-192, ruled 14z-191: "yes, since Phobos is VS2 only, and its air dash is  character-specific, it should abide
#   by VS2 behavior.") neither does ours; at every later event (height 34 and up) both dash on the same frame at the
#   same height: --expect same. Until M23 the frozen expectation was --expect gap (merged-m22 dashed at height 21),
#   measured 14z-191; EXPECT=gap with BUILD=build/m3b_merged30 reproduces it.
# HOW: tools/air_dash_rigs.py generates the rig on tools/name_moves.py's machinery (Phobos by his real cursor path on
#   native, the merged wheel's D D D on ours — HANDOFF [VSP-123]); both legs traced by tests/lua/field_trace.lua under
#   the ruled level and RNG pins; the comparer refuses a leg whose low event is not under 24 or whose high events did
#   not dash on native (VOID).
# EXPECTS: PASS under --expect same (the default). A red is the gap back (a build changed Phobos's air dash — re-read
#   #222) or a difference above the row.
#
# MUST-FIRE: perturbed-copy: native-dash-planted — native's trace with a dash planted at the low event must FAIL the compare (under same: native then dashes where ours does not) (mode: the compare reads the planted native leg)
# FOLLOWS: build/manifest/ emu/mame-patches/ tests/lib/controls.sh tests/lua/field_trace.lua tools/air_dash_rigs.py
#   tools/build_fingerprint.py tools/name_moves.py tools/run_mame.sh tools/select_paths.py tools/setup_mame.sh
#   tests/lib/sheet.sh
#
# SHEET: legs vs2,ours — moments: one per air-dash event, at the frame the leg enters the air dash (seq 0x14), or at the second R when it does not dash (the low event under vs2's row), on that leg's own field trace — not comparable: each game's stage and palette, and P2's art (each game's own copy; [VSP-168])
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged31] [EXPECT=same|gap] [KEEP=<dir>] tests/audit_air_dash_height.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
: "${ROMDIR:?set ROMDIR}"
BUILD="${BUILD:-build/m3b_merged31}"
EXPECT="${EXPECT:-same}"   # 14z-192: gap until M23, same since
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"; export MAME_BIN
[ -x "$MAME_BIN" ] || { echo "FAIL: no MAME binary at $MAME_BIN (tools/setup_mame.sh)"; exit 1; }
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "FAIL: no $BUILD/rompath/vsavjw.zip"; exit 1; }
W="${KEEP:-$(mktemp -d)}"; mkdir -p "$W"
[ -n "${KEEP:-}" ] || trap 'rm -rf "$W"' EXIT INT TERM
echo "== audit_air_dash_height (#222): build $BUILD ($(python3 tools/build_fingerprint.py "$BUILD/rompath" --set vsavjw --sha-only 2>/dev/null | cut -c1-8))"
python3 tools/air_dash_rigs.py gen "$W" > /dev/null || { echo "FAIL: rig generation"; exit 1; }
J="$W/h222.json"
fr="$(python3 -c "import json;print(json.load(open('$J'))['frames'])")"
pk="$(python3 -c "import json;print(';'.join(json.load(open('$J'))['pokes']))");2000-$((fr - 1)):ff8116:06;2363-$((fr - 1)):ff80d4:0000"
FIELDS="$(python3 -c 'import sys; sys.path.insert(0,"tools"); import air_dash_rigs as a; print(a.FIELDS)')"
awk '/^1104-1106 p2=R$/ && !done { t=1100; n=split("D D D", m, " "); for (i=1;i<=n;i++){ printf "%d-%d p1=%s\n", t, t+2, m[i]; t+=60 }; done=1 }
     /^(1100|1160|1220|1280)-[0-9]+ p1=/ { next } { print }' "$W/h222.rpl" > "$W/h222.ours.rpl"
for side in native ours; do
    if [ $side = native ]; then s=vsav2; rp="$ROMDIR"; R="$W/h222.rpl"; else s=vsavjw; rp="$REPO/$BUILD/rompath;$ROMDIR"; R="$W/h222.ours.rpl"; fi
    d="$W/$side"; rm -rf "$d"; mkdir -p "$d"
    ( cd "$d" && MAME_SANDBOX="$d/sb" MAME_ROMPATH="$rp" REPLAY="$R" POKES="$pk" FIELDS="$FIELDS" FIELD_OUT="$W/tr_$side.txt" \
        FIELD_FROM=2300 FIELD_TO="$fr" FRAMES="$fr" "$REPO/tools/run_mame.sh" "$s" -autoboot_script "$REPO/tests/lua/field_trace.lua" > "$d/mame.log" 2>&1
      rm -rf "$d/sb" ) < /dev/null &
done
wait
fail=0
for side in native ours; do grep -q FIELDSUMMARY "$W/tr_$side.txt" 2>/dev/null || { echo "FAIL: $side: no complete trace ($W/$side/mame.log)"; fail=1; }; done
[ "$fail" = 0 ] || exit 1
PL=""; vs_ctl_is native-dash-planted && PL="--plant-native-dash"
echo "== 1. --expect $EXPECT: the low event under vs2's row, and identical above it"
python3 tools/air_dash_rigs.py compare "$J" "$W/tr_native.txt" "$W/tr_ours.txt" --expect "$EXPECT" $PL; rc=$?
[ "$rc" = 0 ] || fail=1
if vs_ctl_is native-dash-planted; then
    [ "$fail" = 1 ] && { echo "FAIL: audit_air_dash_height (control mode: the planted native dash broke the compare)"; exit 1; }
    echo "FAIL: audit_air_dash_height — the planted native dash still passed"; exit 1
fi
echo "== 2. control"
python3 tools/air_dash_rigs.py compare "$J" "$W/tr_native.txt" "$W/tr_ours.txt" --expect "$EXPECT" --plant-native-dash > "$W/ctl.txt" 2>&1
if grep -q 'MISMATCH' "$W/ctl.txt"; then vs_ctl_fired native-dash-planted "$(grep -m1 MISMATCH "$W/ctl.txt" | sed 's/^ *//')"
else vs_ctl_dead native-dash-planted "no MISMATCH with the native dash planted (a pass, or a crash: $(tail -1 "$W/ctl.txt" | cut -c1-100))"; fail=1; fi
# THE SHEET (#291): with SHEET_OUT set, the two traced legs as this run played them and one moment per event, each
# picture proven on the fields that leg traced at that frame. Nothing the gate decides changes.
. "$REPO/tests/lib/sheet.sh"
if sheet_on && [ -z "${VS_CTL:-}" ]; then
    sheet_new h222 "Phobos jumps straight up and air-dashes (j.66) at +5..+16: native vs2 above ours" huitzil "#222" \
        "each game's stage and palette, and P2's art (each game's own copy; [VSP-168])"
    sheet_leg h222 native vs2 vsav2 "$ROMDIR" "$W/h222.rpl" "$pk" "$fr"
    sheet_leg h222 ours ours vsavjw "$REPO/$BUILD/rompath;$ROMDIR" "$W/h222.ours.rpl" "$pk" "$fr"
    python3 - "$J" "$W/tr_native.txt" "$W/tr_ours.txt" "$FIELDS" > "$W/sheet_rows.tsv" <<'PYS'
import json, sys
sys.path.insert(0, "tools")
import air_dash_rigs as a
js, trn, tro, fields = sys.argv[1:5]
spec = {name: "%s:%s" % (ad.lower(), sz) for ad, sz, name in (f.split(":") for f in fields.split(","))}
R = {"native": a.load(trn), "ours": a.load(tro)}
rows = {"native": a.rows(js, trn), "ours": a.rows(js, tro)}
ev = json.load(open(js))["events"]
for i, (x, y) in enumerate(zip(rows["native"], rows["ours"])):
    f0 = ev[i]["frame"]
    print("moment\th222\tk%d\tair dash completed at +%d (height at the 2nd R: native %s, ours %s)\t%s\tnative %s | ours %s" % (
        x["k"], x["k"], x["h"], y["h"], "IDENTICAL" if x == y else "DIFF", a.fmt(x), a.fmt(y)))
    for leg, r in (("native", x), ("ours", y)):
        f = f0 + (r["dash"] if r["dash"] is not None else r["k"])
        smp = R[leg].get(f)
        exp = ",".join("%s=%s" % (spec[n], v) for n, v in sorted(smp.items()) if n in spec) if smp else "-"
        print("at\th222\tk%d\t%s\t%d\t%s\t%s" % (x["k"], leg, f, "fields" if smp else "none", exp))
        # S4-D (#291): the judged window, the 60 frames from the jump in which tools/air_dash_rigs.py looks for the dash
        live = [g for g in range(f0, f0 + 60) if g in R[leg]]
        if smp and live:
            print("span\th222\tk%d\t%s\t%d-%d" % (x["k"], leg, min(live + [f]), max(live + [f])))
PYS
    sheet_trace h222 native "$W/tr_native.txt" "$FIELDS"
    sheet_trace h222 ours "$W/tr_ours.txt" "$FIELDS"
    sheet_rows "$W/sheet_rows.tsv"
fi
[ "$fail" = 0 ] && echo "PASS: audit_air_dash_height — --expect $EXPECT: Phobos's air dash under vs2's row as expected (#222); identical above" \
                || echo "FAIL: audit_air_dash_height"
exit "$fail"
