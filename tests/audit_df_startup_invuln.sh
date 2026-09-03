#!/bin/sh
# audit_df_startup_invuln.sh — THE DARK FORCE STARTUP INVINCIBILITY IS +0x147,
# ARMED PER CHARACTER BY THE seq-0x16 HANDLER, AND THE TENANTS ARM THEIR OWN
# (measured 14z-126; STATE "Decisions pending" DF-startup item).
#
# WHY. The maintainer asked (2026-08-31) whether the three tenants get the
# invulnerable startup window vanilla characters get at Dark Force activation,
# and if so whether it is a GLOBAL property of the activation or INHERITED FROM
# THE SHELL character (their variant ids alias base-half rows in every table
# vsavj did not repoint, [VSE-10]). The static reading (vsavj opcode view):
#   * the SHARED activation body PRG:0x027000 arms only +0x143 = 0x14 — the
#     THROW invulnerability (20 f). It never touches +0x147.
#   * +0x147 — mizuumi's "Invincibility Timer", ram.md's re-hit gate — is the
#     VICTIM-side gate of the hit test (PRG:0x018064 `tst.b $147(a1)`, with
#     +0x134 and +0x11E), decremented once per engine tick by the System Timer
#     Reducer PRG:0x02246E. Mizuumi's per-move "Add N frames of invincibility"
#     is exactly a `move.b #N,$147(a6)` (the guard cancel at 0x2E19A: #$1E).
#   * it is armed for DF by the PER-CHARACTER handler dispatch_16
#     (PRG:0x0BF31A, mizuumi's "Dark Force XX" rows) selects for seq 0x16, in
#     its sub-state 0: BU/DE 0x29, GA/AU 0x22, VI 0x3B, ZA 0x46, AN/LI 0x3C,
#     FE 0x2E, BI 0x2B, QB 0x04, JE 0x7F, MO/SA/LE later in the handler.
#   * the tenants' rows 0x10/0x11/0x13 are REPOINTED on every built image to
#     their own placed vs2 handlers, byte-identical to vs2's rows: Huitzil
#     0x4F (79 f; his shell Bulleta arms 0x29), Pyron 0x29 (41 f; Demitri
#     0x29 — coincident by value, distinct by code path), Donovan 0x40 (64 f;
#     Victor 0x3B). Natively on vs2 the seq-0x16 handler never runs and the
#     DF path writes +0x147 = 1 at 0x25F2A, which the reducer clears before
#     frame_done — NO observable window (measured: never armed on the native
#     leg). vs2's different DF system ([VSE-69]); vsavj semantics govern here
#     (the ruled framework).
# So the answer is NEITHER global NOR inherited: each tenant carries its own
# vs2 window, as every vanilla character carries its own. This audit is the
# in-emulator half ([VSP-3], [VSP-18]).
#
# WHAT IT ASSERTS (MAME, field_trace, legs in parallel):
#   TRACE (replay df/97, activation HP+HK at f3260, then idle): for every
#     character the FIRST non-zero value of P1 +0x147 after the press (the
#     armed window, in engine ticks), its PEAK over the mode entry, the FRAMES
#     it takes to reach zero (fewer than the ticks: ~20% of frames carry two
#     engine ticks, 14z-125b — Donovan's 64 ticks elapse in 52 frames), and
#     +0x143's first sample (0x13 on every leg: written 0x14 by the shared
#     body, one reducer tick before frame_done — the global half), FROZEN in
#     tests/expected/df_startup_invuln.tsv. Legs: the 15 vanilla ids on
#     pristine vsavj; the three shells (00/01/03) AND the three tenants
#     (10/11/13) on the current merged WIDE build; Donovan on native vsav2.
#     A shell's merged trace must be BYTE-IDENTICAL to its pristine trace
#     (legacy content under the superset invariant, checked for free).
#   CONTACT (replay df/98): Victor (P2) walks in and presses 5HP 4 frames
#     after P1's activation (lands INSIDE the window) and again 110 frames
#     after a second activation (OUTSIDE it). Per event the checker requires
#     P2's attack to have FIRED (its node enters a Victor 5HP chain — an
#     unfired leg is UNMEASURED, never "invulnerable"), then: IN -> P1's HP
#     does not move and +0x147 > 0 while the attack is active; OUT -> P1's HP
#     drops and +0x147 == 0. Legs 01 Demitri (legacy control), 13 Donovan,
#     11 Pyron are asserted; 10 Huitzil is REPORTED only — his DF is a flight
#     mode (engine_internals "Huitzil's form is a FLIGHT mode") and the OUT
#     attack may whiff for reasons that are not the window.
#   Both checkers are ground-truth tested in-run ([VSP-19]): a perturbed
#   frozen value must FAIL the trace compare, and the contact verdict must
#   FAIL when the expectation is inverted on the same data.
#
# Usage: ROMDIR=... [MAME_BIN=...] [BUILD=build/m3b_merged22] [JOBS=4]
#        [SECTION=trace|contact|all] [FREEZE=1] [KEEP_DIR=dir [REUSE=1]]
#        tests/audit_df_startup_invuln.sh
#        (~3 min at MAME's headless speed: 22 trace legs + 4 contact legs, JOBS
#        at a time; REUSE=1 re-runs only the checkers on a KEEP_DIR's traces)
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
ROMDIR="${ROMDIR:?set ROMDIR}"
MAME_BIN="${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}"
export MAME_BIN
BUILD="${BUILD:-build/m3b_merged22}"
JOBS="${JOBS:-4}"
SECTION="${SECTION:-all}"
FREEZE="${FREEZE:-0}"
EXP="$REPO/tests/expected/df_startup_invuln.tsv"
[ -f "$BUILD/rompath/vsavjw.zip" ] || { echo "SKIP: no $BUILD/rompath/vsavjw.zip"; exit 0; }
[ -x "$MAME_BIN" ] || { echo "SKIP: no MAME at $MAME_BIN"; exit 0; }
W="${KEEP_DIR:-$(mktemp -d)}"; [ -n "${KEEP_DIR:-}" ] || trap 'rm -rf "$W"' EXIT
mkdir -p "$W"
REUSE="${REUSE:-0}"   # REUSE=1 with KEEP_DIR: re-run the checkers on kept traces, no MAME
. "$REPO/tests/lib/decrypt_cache.sh"
decrypt_view vsavj "$W/vj_op.bin" "$W/vj_data.bin"

RPL97="$REPO/tests/replays/df/97_df_mech.rpl"
RPL98="$REPO/tests/replays/df/98_df_startup_contact.rpl"
F1="ff802e:b:df,ff8547:b:inv,ff8543:b:thr,ff8406:b:seq,ff8407:b:sub,ff8509:b:stocks"
F2="ff802e:b:df,ff8547:b:inv,ff8450:w:p1hp,ff8406:b:p1seq,ff881c:l:p2node,ff8806:b:p2seq,ff8410:w:p1x,ff8810:w:p2x,ff8414:w:p1y"

njobs=0
# run_leg <leg> <set> <rompath> <replay> <pokes> <fields> <from> <to> <frames>
run_leg() {
    [ "$REUSE" = 1 ] && return 0
    d="$W/$1"; mkdir -p "$d/sb"
    ( cd "$d" && MAME_ROMPATH="$3" MAME_SANDBOX="$d/sb" REPLAY="$4" POKES="$5" \
      FIELDS="$6" FIELD_OUT="$d/field.txt" FIELD_FROM="$7" FIELD_TO="$8" FRAMES="$9" \
      "$REPO/tools/run_mame.sh" "$2" -autoboot_script "$REPO/tests/lua/field_trace.lua" \
      > "$d/out" 2>&1 ) &
    njobs=$((njobs + 1))
    if [ "$njobs" -ge "$JOBS" ]; then wait; njobs=0; fi
}
pk_char() {  # pk_char <p1 id hex> -> the replay-97 poke string
    echo "1400:ff8782:$1;1450:ff8782:$1;1500:ff8782:$1;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03;3100:ff8509:03;3120:ff8509:03"
}
MERGED="$REPO/$BUILD/rompath;$ROMDIR"

if [ "$SECTION" = trace ] || [ "$SECTION" = all ]; then
    for id in ${TRACE_VANILLA:-00 01 02 03 04 05 06 07 08 09 0a 0c 0d 0e 0f}; do
        run_leg "v_$id" vsavj "$ROMDIR" "$RPL97" "$(pk_char "$id")" "$F1" 3200 3560 3600
    done
    for id in ${TRACE_MERGED:-00 01 03 10 11 13}; do
        run_leg "m_$id" vsavjw "$MERGED" "$RPL97" "$(pk_char "$id")" "$F1" 3200 3560 3600
    done
    for id in ${TRACE_NATIVE:-13}; do
        run_leg "n_$id" vsav2 "$ROMDIR" "$RPL97" "$(pk_char "$id")" "$F1" 3200 3560 3600
    done
fi
if [ "$SECTION" = contact ] || [ "$SECTION" = all ]; then
    for id in ${CONTACT_LEGS:-01 13 11 10}; do
        PK="1400:ff8782:$id;1450:ff8782:$id;1500:ff8782:$id;1400:ff8b82:03;1450:ff8b82:03;1500:ff8b82:03"
        PK="$PK;3100:ff8509:03;3120:ff8509:03;4100:ff8509:03;4120:ff8509:03"
        PK="$PK;3030:ff8410:0228;3030:ff8810:02d8;4030:ff8410:0228;4030:ff8810:02d8"
        PK="$PK;3240:ff8450:01200120;4240:ff8450:01200120"
        run_leg "c_$id" vsavjw "$MERGED" "$RPL98" "$PK" "$F2" 3200 4560 4600
    done
fi
wait

python3 - "$W" "$EXP" "$SECTION" "$FREEZE" "$REPO" <<'PY' || { echo "FAIL: DF startup invulnerability audit"; exit 1; }
import sys, os
from pathlib import Path
W, EXP, SECTION, FREEZE, REPO = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1", sys.argv[5]
sys.path.insert(0, os.path.join(REPO, "tools"))
NAMES = {0x00:"BU",0x01:"DE",0x02:"GA",0x03:"VI",0x04:"ZA",0x05:"MO",0x06:"AN",0x07:"FE",0x08:"BI",
         0x09:"AU",0x0a:"SA",0x0c:"QB",0x0d:"LE",0x0e:"LI",0x0f:"JE",0x10:"HUI",0x11:"PYR",0x13:"DON"}
T_ACT = 3260          # the activation press in both replays (event 1)
errs, notes = [], []

def samples(path):
    rows = {}
    for ln in Path(path).read_text().splitlines():
        f = ln.split()
        if len(f) < 3 or f[0] != "F": continue
        kv = {}
        for p in f[2:]:
            k, v = p.split("=", 1); kv[k] = int(v)
        rows[int(f[1])] = kv
    return rows

def measure_trace(rows, t=T_ACT):
    """(arm, peak, zero_off, thr, df_off) for one trace leg, or None + reason."""
    fr = sorted(f for f in rows if t - 5 <= f <= t + 260)
    if not fr: return None, "no samples in window"
    df = [f for f in fr if rows[f]["df"] == 1]
    df_off = (df[0] - t) if df else None
    armf = [f for f in fr if rows[f]["inv"] != 0]
    thrf = [f for f in fr if f >= t - 5 and rows[f]["thr"] != 0]
    thr = rows[thrf[0]]["thr"] if thrf else 0
    if not armf:   # never observable: the NATIVE vs2 leg (writes 1, cleared before frame_done)
        return (0, 0, 0, thr, df_off), None
    f0 = armf[0]; arm = rows[f0]["inv"]
    peak = max(rows[f]["inv"] for f in fr if f >= f0 and f <= f0 + 140)
    zero = [f for f in fr if f > f0 and rows[f]["inv"] == 0]
    zero_off = (zero[0] - f0) if zero else None
    return (arm, peak, zero_off, thr, df_off), None

def check_trace():
    meas = {}
    for d in sorted(Path(W).iterdir()):
        if d.name[:2] not in ("v_", "m_", "n_"): continue
        p = d / "field.txt"
        if not p.exists() or not p.read_text().strip():
            errs.append(f"{d.name}: no field trace — dead leg"); continue
        rows = samples(p)
        m, why = measure_trace(rows)
        if m is None:
            errs.append(f"{d.name}: {why}"); continue
        meas[d.name] = m
        arm, peak, zero_off, thr, df_off = m
        cid = int(d.name[2:], 16)
        print(f"  {d.name} {NAMES.get(cid,'?'):3s} arm=0x{arm:02x} ({arm} f) peak=0x{peak:02x} zero@+{zero_off} thr=0x{thr:02x} df@+{df_off}")
        if d.name[0] == "n" and arm != 0:
            errs.append(f"{d.name}: native vs2 armed +0x147 = 0x{arm:02x} — vs2's own DF system never shows a window ([VSE-69])")
        if d.name[0] != "n" and arm == 0:
            errs.append(f"{d.name}: +0x147 never armed on a vsavj-engine leg")
        if d.name[0] != "n" and df_off is None:
            errs.append(f"{d.name}: DF never entered ($FF802E never 1) — downgrade trap")
        # field_trace samples at frame_done, ONE reducer tick after the body's
        # `move.b #$14,$143(a6)` — so the written 0x14 is SAMPLED as 0x13 — unless
        # the character's OWN handler overwrites it the same frame with 0xFF (full
        # throw immunity for the mode: Anakaris 0x3DA16, Aulbath 0x45D8A, Lei-Lei
        # 0x4C6C0 — the reducer never reaches 0xFF's decrement in the window).
        if d.name[0] != "n" and thr not in (0x13, 0xFF):
            errs.append(f"{d.name}: +0x143 sampled 0x{thr:02x}, expected 0x13 (the body's 0x14, one tick gone) or 0xFF (the handler's override)")
    # legacy on merged == pristine, byte for byte
    for leg in [k for k in meas if k.startswith("m_") and int(k[2:], 16) < 0x10]:
        v = Path(W) / ("v_" + leg[2:]) / "field.txt"; m = Path(W) / leg / "field.txt"
        if v.exists() and v.read_bytes() != m.read_bytes():
            errs.append(f"{leg}: merged trace differs from pristine v_{leg[2:]} — a legacy character's DF entry moved on the WIDE build")
    lines = ["# tests/expected/df_startup_invuln.tsv — the Dark Force STARTUP INVINCIBILITY",
             "# window each character's seq-0x16 handler arms in +0x147 (frames), measured",
             "# 14z-126 on MAME with replay df/97 (tests/audit_df_startup_invuln.sh). `arm` is",
             "# the first non-zero value after the activation press, `peak` the maximum over",
             "# the mode entry, `zero` the FRAMES from the arm to the first zero sample (fewer",
             "# than `arm` — the reducer runs per ENGINE TICK and ~20% of frames carry two,",
             "# 14z-125b), `thr` the shared body's +0x143 throw invulnerability as SAMPLED at",
             "# frame_done (written 0x14, one tick gone: 0x13 on every leg — the only GLOBAL",
             "# half). Legs: v_ pristine vsavj, m_ the merged WIDE",
             "# build (shells 00/01/03 + tenants 10/11/13), n_ native vsav2 (Donovan: arm 0 —",
             "# vs2's own DF system shows NO window, [VSE-69]; the small values of SA/QB/LE",
             "# and Jedah's 0x7F-then-4 are real: `zero` is the honest length). Regenerate",
             "# with FREEZE=1, review the",
             "# diff, never hand-edit.",
             "# leg\tchar\tarm\tpeak\tzero\tthr"]
    for leg in sorted(meas):
        arm, peak, zero_off, thr, df_off = meas[leg]
        lines.append(f"{leg}\t{NAMES.get(int(leg[2:],16),'?')}\t0x{arm:02x}\t0x{peak:02x}\t{zero_off}\t0x{thr:02x}")
    if FREEZE:
        Path(EXP).write_text("\n".join(lines) + "\n"); print(f"  FROZEN {EXP} ({len(meas)} legs)"); return
    if not Path(EXP).exists():
        errs.append(f"no frozen expectation {EXP} — run with FREEZE=1 and review"); return
    want = {l.split("\t")[0]: l.split("\t") for l in Path(EXP).read_text().splitlines() if l and not l.startswith("#")}
    got = {l.split("\t")[0]: l.split("\t") for l in lines if l and not l.startswith("#")}
    if compare(want, got, errs):
        print(f"  trace: {len(got)} legs match the frozen table")
    # must-fire control: a perturbed frozen value is caught
    bad = dict(want); k = sorted(k for k in bad if k in got)[0]
    bad[k] = bad[k][:2] + ["0x7e"] + bad[k][3:]
    ctl = []
    if compare(bad, got, ctl): errs.append("CONTROL: a perturbed frozen arm value was NOT caught")
    else: print("  control: perturbed frozen value caught (must-fire)")

def compare(want, got, out):
    ok = True
    for leg in sorted(set(want) | set(got)):
        if leg not in got:   # a frozen leg not run this time is not a failure (SECTION/LEGS overrides)
            continue
        if leg not in want:
            out.append(f"{leg}: measured but not in the frozen table — freeze after review"); ok = False; continue
        if want[leg][2:6] != got[leg][2:6]:
            out.append(f"{leg}: frozen arm/peak/zero/thr {want[leg][2:6]} != measured {got[leg][2:6]}"); ok = False
    return ok

def check_contact():
    import vanilla_join_rig
    img = (Path(W) / "vj_data.bin").read_bytes()
    nm = vanilla_join_rig.node_map(img, 0x03, detail=True)   # Victor's chains
    VIC_5HP = {"a2:0x04", "a2:0x05"}
    for d in sorted(Path(W).iterdir()):
        if not d.name.startswith("c_"): continue
        cid = int(d.name[2:], 16); assert_leg = cid != 0x10
        p = d / "field.txt"
        if not p.exists() or not p.read_text().strip():
            errs.append(f"{d.name}: no field trace — dead leg"); continue
        rows = samples(p)
        for t, expect_hit, label in ((3260, False, "IN"), (4260, True, "OUT")):
            v, why = contact_event(rows, nm, VIC_5HP, t, expect_hit)
            tag = "PASS" if v else ("FAIL" if assert_leg else "report")
            print(f"  {d.name} {NAMES.get(cid,'?'):3s} {label:3s}: {tag} — {why}")
            if not v and assert_leg: errs.append(f"{d.name} {label}: {why}")
            if v and assert_leg:
                # control: the inverted expectation on the same data must NOT pass
                ok, _ = contact_event(rows, nm, VIC_5HP, t, not expect_hit)
                if ok: errs.append(f"{d.name} {label}: CONTROL — the inverted expectation also passed")

def contact_event(rows, nm, chains, t, expect_hit):
    fr = sorted(f for f in rows if t - 30 <= f <= t + 200)
    if not fr: return False, "no samples"
    if not any(rows[f]["df"] == 1 for f in fr if f >= t): return False, "DF never entered (downgrade trap)"
    # P2's attack: the frames whose node lies in a Victor 5HP chain, with its attack nodes
    atk = [f for f in fr if f >= t and (nm.get(rows[f]["p2node"]) or (None,))[0] in chains]
    if not atk: return False, "P2's 5HP never fired (node never in a2:0x04/0x05) — UNMEASURED"
    active = [f for f in atk if nm[rows[f]["p2node"]][2]]
    if not active: return False, "P2's 5HP fired but no attack node observed — UNMEASURED"
    hp0 = rows[atk[0]]["p1hp"]
    drop = hp0 - min(rows[f]["p1hp"] for f in fr if f >= atk[0])
    inv_active = [rows[f]["inv"] for f in active]
    detail = (f"fired@+{atk[0]-t} active@+{active[0]-t}..+{active[-1]-t} inv={min(inv_active)}..{max(inv_active)} "
              f"hp {hp0}->{hp0-drop} dx={rows[active[0]]['p2x']-rows[active[0]]['p1x']} p1y={rows[active[0]]['p1y']}")
    if expect_hit:
        if drop <= 0: return False, "no HP drop OUTSIDE the window — " + detail
        if min(inv_active) != 0: return False, "+0x147 still armed at the OUT contact — " + detail
        return True, "landed, " + detail
    if drop > 0: return False, "HP DROPPED inside the window — " + detail
    if min(inv_active) == 0: return False, "+0x147 was 0 while the attack was active (window not the reason) — " + detail
    return True, "no hit, window armed, " + detail

if SECTION in ("trace", "all"): print("TRACE — the armed window per character"); check_trace()
if SECTION in ("contact", "all"): print("CONTACT — the hit test honours +0x147"); check_contact()
for e in errs: print("  FAIL:", e)
sys.exit(1 if errs else 0)
PY
echo "PASS: DF startup invulnerability audit"
