#!/bin/sh
# test_crosscheck_229.sh — #229'S COLUMN CLASSIFIER RETURNS THE VERDICT IT SHOULD, ON FIXTURES WHOSE VERDICT IS KNOWN
# (14z-209, CLAUDE.md §4 [VSP-19]: a test's classification code is validated against known ground truth before its
# verdicts are trusted). ci_static, portable: no ROM, no emulator, no workbook; ~1 s.
#
# WHAT: tools/crosscheck_229.py's join-and-classify code — the pure functions under each family's loader
#   (classify_es, aggregate_ct, classify_gc, classify_gt, classify_tr, classify_tr_air, classify_tr_cmd) and the code they stand on (the page's classify in
#   tools/crosscheck_framedata.py, command_throw_rigs.parse_series / match_series, specials_b_rigs.verdicts,
#   gc_rigs.ours_cols / sheet_cols) — run on small synthetic fixtures (a fake workbook, fake gate rows), each built so
#   its verdict is known by construction: EXACT, CONSTANT OFFSET, CONSTANT RATIO, INCONSISTENT and NO DATA from the
#   page's classify; EXACT, IN RANGE (a mashed hit count inside the sheet's range), INCONSISTENT and UNCOMPARABLE (a
#   prose cell) for a hit series; CONTACT rows kept out of a specials timing verdict; an UNRESOLVED ES/EX row and a
#   projectile counted uncomparable with their reasons; a command-throw row that never grabs; the guard cancels'
#   timing read from the HIT and never the whiff (#229 Q6) and their damage read as DEALT on the -3 victim, never
#   from the Demitri event (Q5); a row NAMED a guard cancel but typed otherwise held in the guard cancels' row set and
#   joined (#331: Demitri's four Demon Cradle GC rows, tools/gc_rigs.py is_gc_row — until 14z-210 reported NOT RUN);
#   the normal throws ground and air, the air rows joined on key AIR; the ground throws' recovery and throw tech
#   (#330, classify_tr: EXACT, a "+ landing 1" cell counted in, INSIDE / OUTSIDE the sheet's range, OFF, INSIDE THE
#   VICTIM RANGE, INCONSISTENT, a prose cell and a row whose events differ UNCOMPARABLE); the air throws against heights
#   (classify_tr_air: a summed cell, INSIDE THE HEIGHT RANGE, a prose cell) and the command whiffs (classify_tr_cmd: the
#   profile 2 + 1(5)1 + 41 against the whiff tick, no whiff, a prose active cell, the tech window counted).
# HOW: one Python program (below) builds every fixture, calls the functions and compares each got verdict with its
#   expected one; CONTROL=<name> or the in-gate control loop re-runs it with that control's perturbation.
# EXPECTS: every case's verdict equals its expected one (the case table below), and each control's perturbation makes
#   at least one case differ — on the case it targets.
# FOLLOWS: tools/crosscheck_229.py tools/crosscheck_framedata.py tools/command_throw_rigs.py tools/specials_b_rigs.py
#   tools/gc_rigs.py tools/ground_throw_rigs.py tools/es_ex_rigs.py tests/lib/controls.sh
#
# SHEET: none — a ROM-free test of verdict code; no leg of any build.
#
# MUST-FIRE: perturbed-copy: flipped-expectation — the case table with the ES/EX red case's expected EXACT flipped to INCONSISTENT must fail that case (in-gate; mode: the gate compares against the flipped table and FAILs)
# MUST-FIRE: perturbed-copy: whiff-for-hit — the guard cancels classified with the WHIFF events as their timing (classify_gc timing_kind="whiff") must change the startup verdict from CONSTANT OFFSET (in-gate; mode: the gate's guard-cancel case runs on the whiff and FAILs)
# MUST-FIRE: perturbed-copy: record-for-dealt — the guard cancels' damage read from the gc (Demitri) event instead of the dealt (-3 victim) event must change the dealt red verdict from EXACT (in-gate; mode: the gate's guard-cancel case reads the gc event and FAILs)
# MUST-FIRE: perturbed-copy: landing-ignored — the throws' recovery cells read without their "+ landing 1" (the base alone) must change the recovery verdicts of the recovery case (in-gate; mode: the gate's recovery case reads the bare base and FAILs)
# MUST-FIRE: perturbed-copy: victim-range-dropped — the ground throws (and, since 14z-212, the air throw tech) classified against the gate's victim alone must lose the INSIDE THE VICTIM RANGE verdict of the throw-tech case (in-gate; mode: the gate's ground case drops the range and FAILs)
# MUST-FIRE: perturbed-copy: height-range-dropped — the air rows classified against the rig's height alone must lose the INSIDE THE HEIGHT RANGE verdict of the air recovery case (in-gate; mode: the gate's air case drops the range and FAILs)
# MUST-FIRE: perturbed-copy: active-gap-dropped — the command profile's active cell "1(5)1" read as its first number alone must move the command whiff case off CONSTANT OFFSET (in-gate; mode: the gate's command case misreads the cell and FAILs)
# MUST-FIRE: perturbed-copy: contact-counted — the specials' CONTACT rows classified as if they had not touched P2 must change the startup verdict from CONSTANT OFFSET (in-gate; mode: the gate's specials case counts them and FAILs)
#
# Usage: tests/test_crosscheck_229.sh            # static tier, ROM-free
#        CONTROL=<name> tests/test_crosscheck_229.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
. "$REPO/tests/lib/controls.sh"; vs_ctl_mode "$0"
fail=0; ok() { echo "  ok    $*"; }; bad() { echo "  FAIL  $*"; fail=1; }

cases() {  # cases <perturbation or ""> -> one line per case: OK|DIFF <case> got=<..> want=<..>; exit 0
    python3 - "$1" <<'PY'
import sys, collections, re
sys.path.insert(0, "tools")
import crosscheck_framedata as cf
import crosscheck_229 as x
import command_throw_rigs as ctr
import specials_b_rigs as sbr
P = sys.argv[1]
out = []
def check(case, got, want):
    if P == "flipped-expectation" and case == "es red":
        want = "INCONSISTENT"
    out.append(f"{'OK' if got == want else 'DIFF'} {case} got={got} want={want}")

class WB:  # the workbook's two methods the classifiers use
    def __init__(self, rows): self._r = rows; self.sheet_names = list(rows)
    def rows(self, tab): return self._r[tab]

# 1. the page's classify (sheet - ours)
check("classify exact", cf.classify([("a", 5, 5), ("b", 7, 7)])[0], "EXACT")
check("classify offset", cf.classify([("a", 6, 5), ("b", 8, 7)])[0], "CONSTANT OFFSET")
check("classify ratio", cf.classify([("a", 10, 5), ("b", 14, 7)])[0], "CONSTANT RATIO")
check("classify inconsistent", cf.classify([("a", 6, 5), ("b", 7, 7), ("c", 9, 7)])[0], "INCONSISTENT")
check("classify no data", cf.classify([])[0], "NO DATA")

# 2. the hit series (command and normal throws)
check("series exact", ctr.match_series(ctr.parse_series("4+4+19"), [4, 4, 19])[0], "EXACT")
check("series in range", ctr.match_series(ctr.parse_series("5x(1~4)+16"), [5, 5, 5, 16])[0], "IN RANGE")
check("series inconsistent", ctr.match_series(ctr.parse_series("4+4+19"), [4, 19])[0], "INCONSISTENT")
check("series prose", ctr.parse_series("varies with the mash"), None)

# 3. specials B: CONTACT rows stay out of a timing verdict
def sbrow(mv, s, o, contact):
    cols = {c: {"sheet": None, "ours": None} for c in sbr.COLS}
    cols["startup"] = {"sheet": s, "ours": o}
    cols["red"] = {"sheet": 9, "ours": 9}
    return {"tab": "LE", "move": mv, "status": "FIRED", "contact": contact, "cols": cols}
rows = [sbrow("A", 6, 5, False), sbrow("B", 9, 8, False), sbrow("C", 20, 4, True)]
if P == "contact-counted":
    rows = [dict(r, contact=False) for r in rows]
v = {(l.split("\t")[0], l.split("\t")[1]): l.split("\t") for l in sbr.verdicts(rows)}
check("sb startup", v[("ALL", "startup")][2], "CONSTANT OFFSET")
check("sb startup uncomparable", v[("ALL", "startup")][5], "uncomparable 1")
check("sb red", v[("ALL", "red")][2], "EXACT")

# 4. ES/EX: a joined row per verdict, an UNRESOLVED row, a projectile
fam = {"es special", "es special projectile"}
ev = {"XX": [("k1", ["MOVE A"], "236PP", None), ("k2", ["MOVE B"], "623PP", None),
             ("k3", ["MOVE C"], "22PP", None), ("k4", ["MOVE D"], "214PP", None)]}
wb = WB({"XX": [{"type": "es special", "move": "MOVE A", "input": "236PP", "red damage": "11", "white damage": "4",
                 "guage hit": "0", "startup": "7", "active": "3", "recovery": "20"},
                {"type": "es special", "move": "MOVE B", "input": "623PP", "red damage": "15", "white damage": "6",
                 "guage hit": "0", "startup": "9", "active": "4", "recovery": "18"},
                {"type": "es special", "move": "MOVE C", "input": "22PP", "red damage": "9", "white damage": "3"},
                {"type": "es special projectile", "move": "MOVE D", "input": "214PP", "red damage": "6", "white damage": "2",
                 "guage hit": "0", "startup": "12"}]})
def esrow(st, ex_):
    return {"move_at": 10, "status": "FIRED", "meter_change_from_move": 0, "tick": {"startup_t": st, "active_t": ex_[0], "recovery_t": ex_[1]}}
rows = {("XX", "near", "k1"): esrow(6, (3, 20)), ("XX", "near", "k2"): esrow(8, (4, 19)),
        ("XX", "near", "k4"): {"move_at": 10, "status": "FIRED", "meter_change_from_move": 0, "tick": {}}}
recs = {("XX", "near", "k1"): {"records": [{"rel": 12, "real": 7, "white": 4}]},
        ("XX", "near", "k2"): {"records": [{"rel": 12, "real": 9, "white": 6}]},
        ("XX", "near", "k4"): {"records": [{"rel": 30, "real": 4, "white": 2}]}}
pairs, unc, st = x.classify_es(wb, rows, recs, ev, fam, {}, {("XX", "k3"): "never pays on vsavj"})
check("es red", cf.classify(pairs["red"])[0], "EXACT")
check("es startup", cf.classify(pairs["startup"])[0], "CONSTANT OFFSET")
check("es recovery", cf.classify(pairs["recovery"])[0], "INCONSISTENT")
check("es unresolved counted", st.get("UNRESOLVED"), 1)
check("es projectile uncomparable", unc["startup"].get(("projectile (P1 carries no attack node)", "XX")), 1)

# 5. command throws: the aggregation of the join's per-row verdicts
joined = [{"sheet": "XX", "row": "GRAB A", "events": ["a"], "grabbed": ["a"], "strengths_agree": True,
           "red": ("EXACT", ""), "white": ("IN RANGE", ""), "gauge": ("EXACT", ""), "startup": ("OFFSET", "sheet 5 - ours 4 = +1")},
          {"sheet": "XX", "row": "GRAB B", "events": ["b"], "grabbed": ["b"], "strengths_agree": True,
           "red": ("INCONSISTENT", ""), "white": ("EXACT", ""), "gauge": ("UNCOMPARABLE", "sheet cell 'x'"), "startup": ("OFFSET", "sheet 7 - ours 6 = +1")},
          {"sheet": "XX", "row": "GRAB C", "events": ["c"], "grabbed": []}]
pairs, unc, st, series, _ = x.aggregate_ct(joined)
check("ct red counts", dict(series["red"]), {"EXACT": 1, "INCONSISTENT": 1})
check("ct white in range", series["white"].get("IN RANGE"), 1)
check("ct gauge uncomparable", series["gauge"].get("UNCOMPARABLE"), 1)
check("ct never grabbed", st.get("RUN, NEVER GRABBED"), 1)
check("ct startup", cf.classify(pairs["startup (press to hold)"])[0], "CONSTANT OFFSET")

# 6. guard cancels: Q6 (the hit's timing) and Q5 (damage dealt on the -3 victim)
def gcrow(kind, b, ts, fall):
    return {"rig": f"{kind}_XX_{b}", "sheet": "XX", "button": b, "gc": True, "t_startup": ts, "t_active": 3, "t_recovery": 20,
            "falls": [fall] if fall else [], "run_records": [[{"idx": 1, "meter": 2, "real": 5, "white": 3}]],
            "meter_before": 0, "meter_end": 2 + (2 if fall else 0), "stock_before": 2, "stock_end": 2, "victim": "0x02"}
rows = {}
for b, ts in (("LP", 5), ("MP", 6)):
    rows[f"gc_XX_{b}"] = gcrow("gc", b, ts, [3000, 3, 9, 1])                        # Demitri: dealt 9 / 6
    rows[f"whiff_XX_{b}"] = gcrow("whiff", b, ts + (4 if b == "LP" else 9), None)   # the whiff ticks differ
    rows[f"dealt_XX_{b}"] = gcrow("dealt", b, ts, [3000, 3, 8, 1])                  # the -3 victim: dealt 8 / 5
wbr = [("XX", 0, {"type": "guard cancel", "input": "623LP", "startup": "6", "active": "3", "recovery": "20", "red damage": "8", "white damage": "5", "gauge whiff": "2", "guage hit": "4"}),
       ("XX", 1, {"type": "guard cancel", "input": "623MP", "startup": "7", "active": "3", "recovery": "20", "red damage": "8", "white damage": "5", "gauge whiff": "2", "guage hit": "4"})]
tk = "whiff" if P == "whiff-for-hit" else "gc"
dk = "gc" if P == "record-for-dealt" else "dealt"
pairs, unc, st, vic = x.classify_gc(wbr, rows, timing_kind=tk, damage_kind=dk)
check("gc startup on the hit", cf.classify(pairs["startup"])[0], "CONSTANT OFFSET")
check("gc dealt red", cf.classify(pairs["red (dealt, -3 victim)"])[0], "EXACT")
check("gc dealt white", cf.classify(pairs["white (dealt, -3 victim)"])[0], "EXACT")
check("gc joined", st.get("JOINED"), 2)
# 6b. #331: a row NAMED a guard cancel but typed `special` is in the row set (and joins), as a typed one is; a plain
# special named otherwise is not
import gc_rigs as gcr
wbn = WB({"XX": [{"type": "special", "move": "LP FOO GC"}, {"type": "special GC", "move": "MP FOO"},
                 {"type": "special", "move": "FOO"}, {"type": "special", "move": "GC FOO"}],
          "YY": [{"type": "es special", "move": "ES BAR GC "}]})
check("gc row set: named or typed", [(t, i) for t in wbn.sheet_names for i, d in enumerate(wbn.rows(t)) if gcr.is_gc_row(d)],
      [("XX", 0), ("XX", 1), ("YY", 0)])
named = [("XX", 0, dict(wbr[0][2], type="special", move="LP FOO GC"))]   # the 623LP row above, typed `special`
_, _, nst, _ = x.classify_gc(named, rows)
check("gc named row joins", nst.get("JOINED"), 1)

# 7. the normal throws, ground and air
def gtrow(key, inp, press_to_hold, recs, meter=9):
    return {"sheet": "XX", "key": key, "input": inp, "press": 3000 if "MP" in inp else 3600, "press_to_hold": press_to_hold,
            "records": [dict(r, landed=True) for r in recs], "meter_end": meter}
r1 = [{"frame": 3001, "site": "0189ea", "real": 15, "white": 9}]
rows = [gtrow("MP", "6MP", 0, r1), gtrow("MP", "6HP", 0, r1),
        gtrow("AIR", "j.6MP", 0, r1), gtrow("AIR", "j.6HP", 0, r1),
        gtrow("K", "6MK", None, [])]
wb = WB({"XX": [{"type": "ground throw", "move": "MP throw", "startup": "1", "red damage": "24", "white damage": "9", "guage hit": "9"},
                {"type": "ground throw", "move": "K throw", "startup": "1", "red damage": "20", "white damage": "8", "guage hit": "9"},
                {"type": "air throw", "move": "", "startup": "1", "red damage": "24", "white damage": "9", "guage hit": "9"}]})
for scope, held, never in (("ground", 1, 1), ("air", 1, None)):
    pairs, unc, st, series, _ = x.classify_gt(wb, rows, scope)
    check(f"gt {scope} held", st.get("HELD"), held)
    check(f"gt {scope} never held", st.get("NEVER HELD"), never)
    check(f"gt {scope} red", dict(series["red"]), {"EXACT": 1})
    check(f"gt {scope} gauge", dict(series["gauge"]), {"EXACT": 1})
    check(f"gt {scope} startup", cf.classify(pairs["startup (press to hold)"])[0], "CONSTANT OFFSET")

# 8. the ground throws' recovery and throw tech (#330): three victims, the gate's own first
import ground_throw_rigs as gtr
gtr.THROWS["XX"] = [("P", "6MP", []), ("K", "6MK", []), ("MP", "6MP", []), ("HP", "6HP", []), ("PB", "4MP", []), ("PB", "4HP", [])]
def tr(rec, adv, vic_thrown=200): return {"thr_thrown": rec, "vic_thrown": vic_thrown, "thr_tech": 50, "vic_tech": 50 + adv}
v0 = {("XX", "P", "6MP"): tr(54, 21), ("XX", "K", "6MK"): tr(98, 2), ("XX", "MP", "6MP"): tr(131, -19),
      ("XX", "HP", "6HP"): tr(248, 5), ("XX", "PB", "4MP"): tr(54, 21), ("XX", "PB", "4HP"): tr(55, 21)}
v1 = {**v0, ("XX", "K", "6MK"): tr(98, 1), ("XX", "MP", "6MP"): tr(131, -18)}
v2 = {**v0, ("XX", "K", "6MK"): tr(98, 3)}
if P == "landing-ignored":     # the sheet's "+ landing 1" read as its base alone
    _cell = x._tr_cell
    x._tr_cell = lambda c: _cell(str(c).split("+")[0]) if c is not None and "landing" in str(c) else _cell(c)
wb = WB({"XX": [{"type": "ground throw", "move": "P THROW", "recovery": "54.0", "throw tech": "21.0"},
                {"type": "k ground throw", "move": "K THROW", "recovery": "97 + landing 1", "throw tech": "0.0"},
                {"type": "ground throw", "move": "MP THROW", "recovery": "131-150", "throw tech": "-18.0"},
                {"type": "ground throw", "move": "HP THROW", "recovery": "250.0", "throw tech": "varies"},
                {"type": "ground throw", "move": "P THROW BACK", "recovery": "78.0", "throw tech": "21.0"}]})
# the control victim-range-dropped: the ground throws classified against the gate's victim alone (the range dropped)
_, verdicts, st, _ = x.classify_tr(wb, [("v0", v0)] if P == "victim-range-dropped" else [("v0", v0), ("v1", v1), ("v2", v2)])
check("tr recovery", dict(verdicts[x.TR_COLS[0]]), {"EXACT": 2, "INSIDE THE SHEET'S RANGE": 1, "OFF": 1, "UNCOMPARABLE": 1})
check("tr throw tech", dict(verdicts[x.TR_COLS[1]]), {"EXACT": 1, "INCONSISTENT": 1, "INSIDE THE VICTIM RANGE": 1, "UNCOMPARABLE": 2})
check("tr rows", dict(st), {"COMPARED": 4, "EVENTS DIFFER": 1})

# 9. the air throws against heights (#330: the cell's terms summed; the rig's height first) and the command whiffs
gtr.AIR["XX"] = [("AIR", "j.6MP", []), ("AIR", "j.6HP", [])]
gtr.AIR["YY"] = [("AIR", "j.6MP", []), ("AIR", "j.6HP", [])]
h0 = {("XX", "AIR", "j.6MP"): tr(64, 14), ("XX", "AIR", "j.6HP"): tr(64, 14), ("YY", "AIR", "j.6MP"): tr(60, 3), ("YY", "AIR", "j.6HP"): tr(60, 3)}
h1 = {**h0, ("YY", "AIR", "j.6MP"): tr(63, 5), ("YY", "AIR", "j.6HP"): tr(63, 5)}
wba = WB({"XX": [{"type": "air throw", "recovery": "40 + 23 + landing 1", "throw tech": "14.0"}],
          "YY": [{"type": "air throw", "recovery": "62", "throw tech": "variable"}]})
# the control height-range-dropped: the air rows classified against the rig's height alone (the range dropped)
av, ast, _ = x.classify_tr_air(wba, [("h0", h0)] if P == "height-range-dropped" else [("h0", h0), ("h1", h1)])
check("tr air recovery", dict(av[x.TR_COLS[0]]), {"EXACT": 1, "INSIDE THE HEIGHT RANGE": 1})
check("tr air tech", dict(av[x.TR_COLS[1]]), {"EXACT": 1, "UNCOMPARABLE": 1})
check("tr air summed cell", x._tr_sum("72+45+landing 12+turning 1"), 130)
check("tr air prose cell", x._tr_sum("variable + landing 1"), None)
# the air throw tech against the other VICTIMS too (14z-212, the maintainer's "Measure them too"): a cell outside the
# heights' figures but within heights and victims together is INSIDE THE VICTIM RANGE, outside both INCONSISTENT; the
# control victim-range-dropped drops the victims here too
gtr.AIR["ZZ"] = [("AIR", "j.6MP", [])]
wbz = WB({"ZZ": [{"type": "air throw", "recovery": "70", "throw tech": "6.0"}, {"type": "air throw", "recovery": "70", "throw tech": "9.0"}]})
zv, _, _ = x.classify_tr_air(wbz, [("h0", {("ZZ", "AIR", "j.6MP"): tr(70, 3)}), ("h1", {("ZZ", "AIR", "j.6MP"): tr(70, 4)})],
                             [] if P == "victim-range-dropped" else [("v1", {("ZZ", "AIR", "j.6MP"): tr(70, 6)})])
check("tr air tech victims", dict(zv[x.TR_COLS[1]]), {"INSIDE THE VICTIM RANGE": 1, "INCONSISTENT": 1})
wbc = WB({"XX": [{"move": "GRAB", "startup": "2", "active": "1(5)1", "recovery": "41", "throw tech": ""},
                 {"move": "SLOW GRAB", "startup": "2", "active": "until landing", "recovery": "2", "throw tech": ""},
                 {"move": "QUICK GRAB", "startup": "2", "active": "3", "recovery": "20", "throw tech": ""}]})
if P == "active-gap-dropped":   # the command profile's active "1(5)1" read as its first number alone
    x._tr_active = lambda c: int(str(c).split("(")[0]) if c is not None and re.match(r"\s*\d", str(c)) else None
cp, cst, cw = x.classify_tr_cmd(wbc, {("XX", "GRAB", "MK"): {"whiff": 49, "window": "none"}, ("XX", "GRAB", "HK"): {"whiff": 49, "window": "1-7"},
                                      ("XX", "SLOW GRAB", "LK"): {"whiff": 30, "window": "none"}, ("XX", "GRAB", "KK"): {"whiff": None, "window": "none"},
                                      ("XX", "QUICK GRAB", "LP"): {"whiff": 24, "window": "none"}})
check("tr command whiff", cf.classify(cp["whiff (startup + active + recovery)"])[0], "CONSTANT OFFSET")
check("tr command rows", dict(cst), {"JOINED": 3, "NO WHIFF (Pit of Blame draws no move; the 24 gated grabs' input is a normal or a jump)": 1, "UNCOMPARABLE (a prose startup / active / recovery)": 1, "THROW TECH CELL EMPTY": 3})
check("tr command window", dict(cw), {"none": 4, "1-7": 1})
print("\n".join(out))
PY
}

echo "== 1. every fixture's verdict equals its known one"
MODE_P=""; [ -n "${VS_CTL:-}" ] && MODE_P="$VS_CTL"
if cases "$MODE_P" > "${TMPDIR:-/tmp}/cc229.$$" 2>&1; then :; else bad "the case program failed:"; sed 's/^/        /' "${TMPDIR:-/tmp}/cc229.$$" | tail -8; fi
n_ok=$(grep -c '^OK ' "${TMPDIR:-/tmp}/cc229.$$"); n_diff=$(grep -c '^DIFF ' "${TMPDIR:-/tmp}/cc229.$$")
if [ "$n_diff" -eq 0 ] && [ "$n_ok" -gt 0 ]; then ok "$n_ok cases, every verdict as expected"
else bad "$n_diff of $((n_ok + n_diff)) cases differ:"; grep '^DIFF ' "${TMPDIR:-/tmp}/cc229.$$" | sed 's/^/        /'; fi
rm -f "${TMPDIR:-/tmp}/cc229.$$"

echo "== 2. must-fire controls"
if [ -n "${VS_CTL:-}" ]; then
    echo "  (control mode $VS_CTL: section 1 ran with its perturbation; the gate must FAIL)"
else
    for c in "flipped-expectation:es red" "whiff-for-hit:gc startup on the hit" "record-for-dealt:gc dealt red" "contact-counted:sb startup" "landing-ignored:tr recovery" "height-range-dropped:tr air recovery" "active-gap-dropped:tr command whiff" "victim-range-dropped:tr throw tech"; do
        name="${c%%:*}"; target="${c#*:}"
        d="$(cases "$name" 2>&1 | grep '^DIFF ')"
        if echo "$d" | grep >/dev/null "^DIFF $target got="; then vs_ctl_fired "$name" "$(echo "$d" | grep "^DIFF $target got=" | head -1)"
        else vs_ctl_dead "$name" "its target case '$target' did not differ (differences: $(echo "$d" | wc -l | tr -d ' '))" || fail=1; fi
    done
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
