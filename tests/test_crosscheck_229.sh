#!/bin/sh
# test_crosscheck_229.sh — #229'S COLUMN CLASSIFIER RETURNS THE VERDICT IT SHOULD, ON FIXTURES WHOSE VERDICT IS KNOWN
# (14z-209, CLAUDE.md §4 [VSP-19]: a test's classification code is validated against known ground truth before its
# verdicts are trusted). ci_static, portable: no ROM, no emulator, no workbook; ~1 s.
#
# WHAT: tools/crosscheck_229.py's join-and-classify code — the pure functions under each family's loader
#   (classify_es, aggregate_ct, classify_gc, classify_gt) and the code they stand on (the page's classify in
#   tools/crosscheck_framedata.py, command_throw_rigs.parse_series / match_series, specials_b_rigs.verdicts,
#   gc_rigs.ours_cols / sheet_cols) — run on small synthetic fixtures (a fake workbook, fake gate rows), each built so
#   its verdict is known by construction: EXACT, CONSTANT OFFSET, CONSTANT RATIO, INCONSISTENT and NO DATA from the
#   page's classify; EXACT, IN RANGE (a mashed hit count inside the sheet's range), INCONSISTENT and UNCOMPARABLE (a
#   prose cell) for a hit series; CONTACT rows kept out of a specials timing verdict; an UNRESOLVED ES/EX row and a
#   projectile counted uncomparable with their reasons; a command-throw row that never grabs; the guard cancels'
#   timing read from the HIT and never the whiff (#229 Q6) and their damage read as DEALT on the -3 victim, never
#   from the Demitri event (Q5); a row NAMED a guard cancel but typed otherwise reported NOT RUN with its reason (#331:
#   Demitri's four Demon Cradle GC rows); the normal throws ground and air, the air rows joined on key AIR.
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
import sys, collections
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
# 6b. #331: a row NAMED a guard cancel but typed `special` is reported NOT RUN with its reason, never silently dropped
wbn = WB({"XX": [{"type": "special", "move": "LP FOO GC"}, {"type": "special GC", "move": "MP FOO GC"},
                 {"type": "special", "move": "FOO"}],
          "YY": [{"type": "es special", "move": "ES BAR GC "}]})
nr = x.gc_named_untyped(wbn, ("special gc", "es special gc", "gc", "es gc"), ["YY"])
check("gc named untyped rows", [(t, i) for t, i, *_ in nr], [("XX", 0), ("YY", 0)])
check("gc named untyped no-rig reason", ["no guard-cancel rig" in w for *_, w in nr], [True, False])

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
    for c in "flipped-expectation:es red" "whiff-for-hit:gc startup on the hit" "record-for-dealt:gc dealt red" "contact-counted:sb startup"; do
        name="${c%%:*}"; target="${c#*:}"
        d="$(cases "$name" 2>&1 | grep '^DIFF ')"
        if echo "$d" | grep >/dev/null "^DIFF $target got="; then vs_ctl_fired "$name" "$(echo "$d" | grep "^DIFF $target got=" | head -1)"
        else vs_ctl_dead "$name" "its target case '$target' did not differ (differences: $(echo "$d" | wc -l | tr -d ' '))" || fail=1; fi
    done
fi
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
