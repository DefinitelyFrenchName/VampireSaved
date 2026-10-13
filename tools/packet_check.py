#!/usr/bin/env python3
"""packet_check.py — the PRE-PREPARE check: what a rule-checker packet's readers might find that a script can point
at first (GitHub #272, ruled 2026-10-12 (14z-199): "let's try your proposal and iterate on it, based on measured
data"). `tools/rulecheck.py prepare` runs it on every evidence packet and prints its FLAGS; it never refuses.

WHY FLAGS, NOT REFUSALS — the measurement is in docs/project/rule_checker.md § "The pre-prepare check (#272)": this
tool's --replay over the ledger's real runs, each finding matched to the readers' VIOLATED evidence. As filed —
refusing a claim figure no artifact holds or an unquoted attribution — the check would have refused packets the readers
passed while its refusing flags sat, on reading, on one of their findings; most findings are about MEANING (a premise
not named, a failure mode no control covers, an artifact misread); packet size shows no consistent trend. What did
point at the readers' findings is an absolute or definite word in the DELIVERABLE — the document the packet puts
forward. So the check flags, for a second look, and what it flags is
recorded with the run (precheck.txt) so a later measurement can count what the flags caught live.

THE FLAGS:
  FIGURE      a figure of the claim (tools/agent/extract.py's `figures()`, a run / line / row NUMBER set aside: it
              names where, not what) in no artifact's text and in no artifact's name or line range
  QUOTE       a double-quoted span of four or more words in the claim that no artifact holds verbatim (whitespace
              and quote marks normalised; an ellipsis or a [bracket] splits it into fragments, each checked)
  ATTRIB      a claim sentence that attributes a decision to the maintainer (or the user) and quotes nothing an
              artifact holds (outside the NOT TESTED part; a sentence saying the maintainer was NOT asked is none)
  D-FIGURE    a figure of a deliverable in no OTHER artifact
  D-ABSOLUTE  a deliverable sentence holding an absolute or definite word (every, only, none, all, the one, alone,
              always, never, each, any, entirely, solely, exactly, nothing, whole, fully, completely) and no named
              check in the sentence (an artifact path, a `name`, a control's verdict) — claim_lint's rule, applied
              to the deliverable, which claim_lint does not read
A DELIVERABLE is named at prepare by `--deliverable PATH[:A-B]`, one of the packet's artifacts.

  python3 tools/packet_check.py --claim TEXT --artifact PATH[:A-B] ... [--deliverable PATH[:A-B] ...]
  python3 tools/packet_check.py --replay [--from 14z-N] [--to 14z-N] [--through RUN-ID] [--out TSV]
        the measurement: the check over the ledger's real runs (their staged artifacts under build/rulecheck/; a
        past packet named no deliverable, so a staged markdown document the claim names by file name stands in),
        each finding matched to the readers' VIOLATED evidence — a CO-OCCURRENCE (the figure, or a quote of three
        or more words of the flagged sentence, in a VIOLATED line), an upper bound: read the matches before
        quoting them
  python3 tools/packet_check.py --selftest [--deliverable-ignored | --replay-unbound | --tally-any-flag]
"""
import argparse
import csv
import hashlib
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent / "agent"))
import claim_lint  # noqa: E402
import extract  # noqa: E402

LEDGER = "tests/rulecheck/ledger.tsv"
RUNS = "tests/rulecheck/runs"
STAGING = "build/rulecheck"
DELIVERABLE_READ = True   # --deliverable-ignored: the deliverables are not read — KNOWN-BAD (the gate's control)
REPLAY_BOUND = True       # --replay-unbound: the replay takes slot a when control.txt names none and never checks the
                          # staged copy against manifest.tsv — KNOWN-BAD (the gate's control; run 2026-10-13-962 Q4)

ABSOLUTE = re.compile(r"\b(every|only|none|all|the one|alone|always|never|each|any|entirely|solely|exactly|nothing|"
                      r"whole|fully|completely)\b", re.I)
ATTRIB = re.compile(r"\b(maintainer|the user)\b", re.I)
DECIDES = re.compile(r"\b(rul(?:ed|ing|es)|approv\w*|agree[sd]?|accept\w*|validat\w*|decid\w*|decision|confirm\w*|"
                     r"ch(?:o|oo)se\w*|signed off|sign-off|wants?|wanted|asked for|said|says|told|answered|closed|ratif\w*)\b", re.I)
NOT_ASKED = re.compile(r"\b(not|never|no|without)\b[^.;]{0,60}\b(maintainer|the user)\b"
                       r"|\b(maintainer|the user)\b[^.;]{0,30}\b(not|never)\b", re.I)
REFS = re.compile(r"\b(?:runs?|lines?|rows?|records?|steps?|items?|points?|sessions?|issues?|tickets?|Q)\s+"
                  r"(?:\d{4}-\d\d-\d\d-)?\d+(?:\s*(?:[-–,]|and|to)\s*\d+)*", re.I)
QUOTES = re.compile(r"\"([^\"]+)\"|“([^”]+)”")   # double: a single quote is an apostrophe too often
SQUOTES = re.compile(r"(?<!\w)'([^']+)'(?!\w)")   # an attribution's quote may be single: held in an artifact, it is no apostrophe


def norm(t):
    t = t.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
    return re.sub(r"\s+", " ", t).strip()


def corpus_from_specs(root, specs):
    """-> [(spec, display, text)] for `PATH[:A-B]` specs, read the way rulecheck.stage_artifacts stages them."""
    out = []
    for spec in specs:
        path, _, rng = spec.partition(":")
        p = Path(root) / path
        t = p.read_text(errors="replace") if p.is_file() else None
        if rng and t is not None:
            a, b = rng.split("-")
            t = "".join(t.splitlines(keepends=True)[int(a) - 1:int(b)])
            out.append((spec, f"{path}.lines-{a}-{b} (lines {a}-{b} of {path})", t))
        else:
            out.append((spec, path, t))
    return out


def corpus_from_stage(stage):
    """-> [(display, display, text)] for a staged slot directory (the replay)."""
    return [(str(p.relative_to(stage)),) * 2 + (p.read_text(errors="replace"),)
            for p in sorted(Path(stage).rglob("*")) if p.is_file()]


def quotes(text):
    return [next(g for g in m.groups() if g is not None) for m in QUOTES.finditer(text)]


def quote_held(q, corpus_norm):
    frags = [f.strip(" .,;:") for f in re.split(r"…|\.\.\.|\[[^\]]*\]", norm(q))]
    frags = [f for f in frags if f]
    return bool(frags) and all(any(f in c for c in corpus_norm) for f in frags)


def sentences(doc):
    """a markdown document's sentences: paragraphs and list items, each split outside parentheses"""
    out = []
    for para in re.split(r"\n\s*\n|\n(?=\s*(?:[-*+]|\d+\.|#+|\|)\s)", doc):
        out += claim_lint.split_top(re.sub(r"\s+", " ", para).strip())
    return [x for x in out if x]


def split_keeping_quotes(text):
    """claim_lint's sentences, but a double-quoted span is never cut: a quotation holding a full stop used to split
    its attribution from its quote (run 2026-10-13-957's claim read as an unquoted attribution)"""
    spans = []
    masked = QUOTES.sub(lambda m: spans.append(m.group(0)) or f"\x00{len(spans) - 1}\x00", text)
    return [re.sub(r"\x00(\d+)\x00", lambda m: spans[int(m.group(1))], x) for x in claim_lint.split_top(masked)]


def tied(s):
    return bool(claim_lint.PATH.search(s) or claim_lint.TICK.search(s) or claim_lint.VERDICT.search(s))


def check(claim, corpus, deliverables=()):
    """-> [(kind, item, where)] for a claim, its artifacts [(spec, display, text)] and the specs of its deliverables."""
    m = claim_lint.GAP.search(claim)
    head = claim[:m.start()] if m else claim
    displays = [d for _, d, _ in corpus]
    texts = [t for _, _, t in corpus if t is not None]
    held = [norm(t) for t in texts]
    found = []
    for f in extract.figures(REFS.sub(" ", claim)):
        if not extract.sourced(f, texts + displays):
            found.append(("FIGURE", f, "claim"))
    for q in quotes(claim):
        if len(q.split()) >= 4 and not quote_held(q, held):
            found.append(("QUOTE", q, "claim"))
    for s in split_keeping_quotes(head):
        if ATTRIB.search(s) and DECIDES.search(s) and not NOT_ASKED.search(s) \
                and not any(quote_held(q, held) for q in quotes(s) + SQUOTES.findall(s)):
            found.append(("ATTRIB", s, "claim"))
    for spec, name, doc in corpus:
        if not DELIVERABLE_READ or spec not in deliverables or doc is None:
            continue
        others = [t for sp, _, t in corpus if sp != spec and t is not None] + displays
        for f in extract.figures(REFS.sub(" ", doc)):
            if not extract.sourced(f, others):
                found.append(("D-FIGURE", f, name))
        for s in sentences(doc):
            if ABSOLUTE.search(claim_lint.FREQ.sub(" ", claim_lint.QUOTED.sub(" ", s))) and not tied(s):
                found.append(("D-ABSOLUTE", norm(s), name))
    return found


def render(found):
    lines = [f"  FLAG {k}: {i if len(i) <= 160 else i[:157] + '...'}" + ("" if w == "claim" else f"  [{w}]")
             for k, i, w in found]
    counts = {}
    for k, _, _ in found:
        counts[k] = counts.get(k, 0) + 1
    summary = f"{len(found)} flag(s)" + (": " + ", ".join(f"{k} {n}" for k, n in sorted(counts.items())) if counts else "")
    return lines, summary


# ---------------------------------------------------------------- the replay (the measurement)
def violated_lines(text):
    out = {}
    for ln in text.splitlines():
        m = re.match(r"\s*(Q\d)\s*:\s*VIOLATED\b\s*[—-]*\s*(.*)", ln)
        if m:
            out[m.group(1)] = m.group(2)
    return out


def matched(kind, item, vlines):
    """-> the questions whose VIOLATED evidence names this finding — a co-occurrence, an upper bound."""
    qs = []
    for q, ev in vlines.items():
        if kind in ("FIGURE", "D-FIGURE"):
            hit = extract.sourced(item, [ev])
        elif kind == "QUOTE":
            w = norm(item).split()
            hit = any(" ".join(w[i:i + 3]) in norm(ev) for i in range(max(1, len(w) - 2)))
        elif kind == "ATTRIB":
            hit = q == "Q5"
        else:   # a sentence: a quote of three or more of its words in the evidence
            hit = any(len(x.split()) >= 3 and norm(x)[:40].strip(" .,;:") in norm(item) for x in quotes(ev))
        if hit:
            qs.append(q)
    return qs


def replay_deliverables(claim, corpus):
    """a past packet named no deliverable: a staged markdown document the claim names by file name stands in"""
    out = []
    for spec, _, _ in corpus:
        base = re.sub(r"\.lines-\d+-\d+$", "", spec.split("/")[-1])
        if base.endswith(".md") and base in claim:
            out.append(spec)
    return out


FILED_REFUSALS = ("FIGURE", "ATTRIB")   # the ticket's two refusable items as filed (#272): a claim figure no artifact
                                        # holds, an attribution with no staged quote (absolutes and size: "flags")


def staged_unchanged(rd, stage):
    """-> None when every artifact of the run's manifest.tsv is staged with the sha1 recorded at prepare, else why not.
    A staged copy rewritten after the verdict (a re-prepare under the same id, a hand edit) is not what the readers read."""
    mf = rd / "manifest.tsv"
    if not mf.is_file():
        return "no manifest.tsv"
    for ln in open(mf):
        if ln.startswith("#") or "\t" not in ln:
            continue
        disp, h = ln.rstrip("\n").split("\t")[:2]
        f = stage / disp.split(" (lines ")[0]
        if not f.is_file():
            return f"manifest artifact not staged: {disp}"
        if hashlib.sha1(f.read_bytes()).hexdigest() != h:
            return f"staged artifact changed since prepare: {disp}"
    return None


def replay_recs(root, lo=None, hi=None, through=None):
    """-> [(row, key, vl | None, matches | why-not, size)] for the ledger's real evidence runs in the sittings lo..hi.
    The REAL slot is the one control.txt does not name; a run with no recorded slot, or whose staged copy differs from
    its manifest, is NOT replayable (rule-checker run 2026-10-13-962 Q4)."""
    import recurrence_alarm
    with open(Path(root) / LEDGER) as f:
        rows = list(csv.DictReader((ln for ln in f if not ln.startswith("#")), delimiter="\t"))
    kv = lambda p: dict(ln.rstrip("\n").split("\t", 1) for ln in open(p) if "\t" in ln) if p.is_file() else {}
    recs = []
    for r in rows:
        if r["decision"] in ("calibration", "procedure") or r["verdict"] not in ("OK", "VIOLATED"):
            continue
        key = recurrence_alarm.sitting(r)
        km = re.fullmatch(r"14z-(\d+)[a-z]?", key or "")
        if not km or (lo and int(km.group(1)) < lo) or (hi and int(km.group(1)) > hi):
            continue
        if through and recurrence_alarm.run_key(r["id"]) > recurrence_alarm.run_key(through):
            continue
        rd = Path(root) / RUNS / r["id"]
        meta, ctl = kv(rd / "meta.tsv"), kv(rd / "control.txt")
        if REPLAY_BOUND and ctl.get("slot") not in ("a", "b"):
            recs.append((r, key, None, "no plant slot in control.txt", None))
            continue
        stage = Path(root) / STAGING / r["id"] / ("b" if ctl.get("slot") == "a" else "a")
        if "claim" not in meta or not stage.is_dir() or not (rd / "verdict_real.txt").is_file():
            recs.append((r, key, None, "no claim, staged slot or real verdict", None))
            continue
        why = staged_unchanged(rd, stage) if REPLAY_BOUND else None
        if why:
            recs.append((r, key, None, why, None))
            continue
        corpus = corpus_from_stage(stage)
        found = check(meta["claim"], corpus, replay_deliverables(meta["claim"], corpus))
        vl = violated_lines((rd / "verdict_real.txt").read_text()) if r["verdict"] == "VIOLATED" else {}
        size = (len(corpus), sum(len(t.encode()) for _, _, t in corpus) // 1024)
        recs.append((r, key, vl, [(k, i, matched(k, i, vl)) for k, i, _ in found], size))
    return recs


TALLY_ANY_FLAG = False    # --tally-any-flag: the AS FILED tally refuses on ANY flag kind — KNOWN-BAD (the gate's control;
                          # rule-checker run 2026-10-13-964 Q4: the deciding figures come from this tally)


def tally(recs):
    """-> the AS FILED refusal tally and the size buckets over replayed records: the run ids an AS FILED check (refusing
    on FILED_REFUSALS) would have refused among OK and VIOLATED runs, the VIOLATED ones whose refusing flag matched a
    VIOLATED question, and per size bucket (artifacts, KiB) the VIOLATED count and the total. ROUNDS PER PACKET (#272's
    "done when"): a packet is a sitting plus a subject without its " — re-check after …" tail (recurrence_alarm's
    reading); the rounds are every run of the window; `saved_upper` are the VIOLATED runs whose EVERY violated question
    a flag matched — a co-occurrence, so an upper bound on the rounds a writer acting on the flags could have saved."""
    done = [x for x in recs if x[2] is not None]
    refuses = lambda x: any(TALLY_ANY_FLAG or kk in FILED_REFUSALS for kk, _, _ in x[3])
    by = []
    for label, idx, edges in (("artifacts", 0, (1, 7, 11, 10**9)), ("KiB", 1, (0, 60, 150, 10**9))):
        cells = []
        for a_, b_ in zip(edges, edges[1:]):
            b = [x for x in done if a_ <= x[4][idx] < b_]
            cells.append((a_, b_, sum(x[0]["verdict"] == "VIOLATED" for x in b), len(b)))
        by.append((label, cells))
    import recurrence_alarm
    packets = {(x[1], recurrence_alarm.subject(x[0]["subject"])) for x in recs}
    saved = [x[0]["id"] for x in done if x[0]["verdict"] == "VIOLATED" and x[2]
             and set(x[2]) <= {q for _, _, qs in x[3] for q in qs}]
    return {
        "packets": len(packets), "rounds": len(recs), "saved_upper": saved,
        "ok_refused": [x[0]["id"] for x in done if x[0]["verdict"] == "OK" and refuses(x)],
        "vio_refused": [x[0]["id"] for x in done if x[0]["verdict"] == "VIOLATED" and refuses(x)],
        "vio_refused_matched": [x[0]["id"] for x in done if x[0]["verdict"] == "VIOLATED"
                                and any((TALLY_ANY_FLAG or kk in FILED_REFUSALS) and qs for kk, _, qs in x[3])],
        "by": by,
    }


def replay(root, lo, hi, out, through=None):
    recs = replay_recs(root, lo, hi, through)
    if out:
        with open(out, "w") as fo:
            fo.write("id\tsession\tverdict\tviolated\tflags\tmatched_questions\tunmatched_questions\n")
            for r, key, vl, mt, _ in recs:
                if vl is None:
                    fo.write(f"{r['id']}\t{key}\t{r['verdict']}\t{r['violated']}\tNOT-REPLAYABLE: {mt}\t-\t-\n")
                    continue
                mq = sorted({q for _, _, qs in mt for q in qs})
                fo.write(f"{r['id']}\t{key}\t{r['verdict']}\t{r['violated']}\t"
                         + (" | ".join(f"{k}:{i[:100]}" + (f" ->{'+'.join(qs)}" if qs else "") for k, i, qs in mt) or "-")
                         + f"\t{' '.join(mq) or '-'}\t{' '.join(sorted(set(vl) - set(mq))) or '-'}\n")
    done = [x for x in recs if x[2] is not None]
    vio = [x for x in done if x[0]["verdict"] == "VIOLATED"]
    ok = [x for x in done if x[0]["verdict"] == "OK"]
    mqs = lambda x: {q for _, _, qs in x[3] for q in qs}
    why = {}
    for x in recs:
        if x[2] is None:
            w = re.sub(r":.*", "", x[3])
            why[w] = why.get(w, 0) + 1
    print(f"REPLAY sittings {lo or 'first'}..{hi or 'last'}" + (f" through run {through}" if through else "") + f": runs {len(recs)}, replayable {len(done)} "
          f"(OK {len(ok)}, VIOLATED {len(vio)})" + ("".join(f"; not replayable, {w}: {n}" for w, n in sorted(why.items()))))
    print(f"  VIOLATED runs with a flag matched to a VIOLATED question: {sum(bool(mqs(x)) for x in vio)} of {len(vio)}")
    print(f"  VIOLATED runs with every violated question matched: {sum(bool(x[2]) and set(x[2]) <= mqs(x) for x in vio)} of {len(vio)}")
    for k in ("FIGURE", "QUOTE", "ATTRIB", "D-FIGURE", "D-ABSOLUTE"):
        print(f"  {k:10s} flags {sum(1 for x in done for kk, _, _ in x[3] if kk == k)}"
              f"  matched {sum(1 for x in vio for kk, _, qs in x[3] if kk == k and qs)}"
              f"  on OK runs {sum(1 for x in ok for kk, _, _ in x[3] if kk == k)}"
              f"  | runs flagged: VIOLATED {sum(any(kk == k for kk, _, _ in x[3]) for x in vio)}, "
              f"OK {sum(any(kk == k for kk, _, _ in x[3]) for x in ok)}")
    t = tally(recs)
    print(f"  ROUNDS: packets {t['packets']}, rounds {t['rounds']}, rounds per packet {t['rounds'] / max(1, t['packets']):.2f}; "
          f"without the {len(t['saved_upper'])} VIOLATED runs whose every violated question a flag matched (an upper bound) "
          f"{(t['rounds'] - len(t['saved_upper'])) / max(1, t['packets']):.2f}")
    print(f"  AS FILED, refusing on {'+'.join(FILED_REFUSALS)}: OK runs refused {len(t['ok_refused'])} of {len(ok)} "
          f"({' '.join(t['ok_refused']) or '-'}); VIOLATED runs refused {len(t['vio_refused'])} of {len(vio)}, "
          f"with the refusing flag matched {len(t['vio_refused_matched'])} ({' '.join(t['vio_refused_matched']) or '-'})")
    for label, cells in t["by"]:
        print(f"  by {label}: " + "  ".join(f"[{a_},{b_ if b_ < 10**9 else 'inf'}) {v}/{n} VIOLATED" for a_, b_, v, n in cells))
    return 0


# ---------------------------------------------------------------- the selftest
def selftest():
    report = ("# A report\n\nThe close ran 72 checks (run.log).\n\n"
              "**One case alone failed ten procedure runs over three sessions:** a plant's reader.\n\n"
              "- the gate executes all ten controls in `test_x`;\n- it read 19 files.\n")
    corpus = [("run.log", "run.log", "checks run 72, not as expected 0\nfiles 1539\n"),
              ("DH.md:10-12", "DH.md.lines-10-12 (lines 10-12 of DH.md)", 'The maintainer: "Points 1 and 2 I validated. Point 3 is fine as well."\n'),
              ("report.md", "report.md", report)]
    cases = [
        ("clean", 'The close ran 72 checks (run.log); the maintainer ruled it: "Points 1 and 2 I validated."', (), set()),
        ("FIGURE unstaged", "The close ran 73 checks (run.log).", (), {"FIGURE"}),
        ("FIGURE a run or line number", "Run 945 and line 10 of DH.md hold it (run.log).", (), set()),
        ("FIGURE comma form", "It read 1,539 files (run.log).", (), set()),
        ("QUOTE not held", 'The log says "every check ran as frozen" (run.log).', (), {"QUOTE"}),
        ("QUOTE held across an ellipsis", 'The maintainer: "Points 1 … I validated" (run.log).', (), set()),
        ("ATTRIB unquoted", "The maintainer approved the cadence (run.log).", (), {"ATTRIB"}),
        ("ATTRIB not asked", "This was not put to the maintainer (run.log).", (), set()),
        ("ATTRIB quote holding a full stop", 'The maintainer ruled: "Points 1 and 2 I validated. Point 3 is fine as well" (run.log).', (), set()),
        ("ATTRIB single-quoted and held", "The maintainer ruled 'Points 1 and 2 I validated' (run.log).", (), set()),
        ("a deliverable unread unless named", "The report stands (report.md).", (), set()),
        ("D-ABSOLUTE and D-FIGURE", "The report stands (report.md).", ("report.md",), {"D-ABSOLUTE", "D-FIGURE"}),
    ]
    bad = 0
    for name, claim, dl, want in cases:
        found = check(claim, corpus, dl)
        got = {k for k, _, _ in found}
        good = got == want
        if name == "D-ABSOLUTE and D-FIGURE" and good:
            # exactly the untied sentence and the unsourced figure: the tied one (`test_x`) and 72 (run.log) pass
            dabs = [i for k, i, _ in found if k == "D-ABSOLUTE"]
            dfig = [i for k, i, _ in found if k == "D-FIGURE"]
            good = len(dabs) == 1 and dabs[0].startswith("**One case alone") and dfig == ["19"]
        bad += not good
        print(f"  {'ok  ' if good else 'WRONG'}  {name}: {sorted(got) or '-'} (want {sorted(want) or '-'})")
    vl = {"Q1": 'The figure 73 is in no artifact; "every check ran" is not in run.log; '
                '"One case alone failed ten procedure runs" is not shown', "Q5": "no quote"}
    for kind, item, want in (("FIGURE", "73", ["Q1"]), ("QUOTE", "every check ran as frozen", ["Q1"]),
                             ("ATTRIB", "the maintainer approved", ["Q5"]), ("FIGURE", "74", []),
                             ("D-ABSOLUTE", norm("**One case alone failed ten procedure runs over three sessions:** a plant's reader."), ["Q1"])):
        got = matched(kind, item, vl)
        good = got == want
        bad += not good
        print(f"  {'ok  ' if good else 'WRONG'}  matched {kind} {item[:30]}: {got} (want {want})")
    bad += selftest_replay()
    print("SELFTEST PASS" if not bad else "SELFTEST FAIL")
    return 0 if not bad else 1


def selftest_replay():
    """the replay on a synthetic ledger: it reads the REAL slot (the one control.txt does not name), and a run with no
    recorded slot or a staged copy that differs from its manifest is not replayable (run 2026-10-13-962 Q4)"""
    import tempfile
    bad = 0
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / "tests/rulecheck").mkdir(parents=True)
        led = ["id\tdate\tsession\tdecision\tsubject\tcontrol\tcontrol_verdict\tverdict\tviolated\tresolution\tmodel"]

        def run(rid, verdict, real, plant, slot, tamper=False):
            led.append(f"{rid}\t2099-01-01\t14z-1\trecommendation\ts {rid}\tfx\tCAUGHT\t{verdict}\t"
                       f"{'Q1' if verdict == 'VIOLATED' else '-'}\t-\tm")
            rd = root / RUNS / rid
            rd.mkdir(parents=True)
            (rd / "meta.tsv").write_text("claim\tThe close ran 73 checks (run.log).\n")
            if slot:
                (rd / "control.txt").write_text(f"fixture\tfx\nslot\t{slot}\n")
            (rd / "verdict_real.txt").write_text("Q1: VIOLATED — 73 is in no artifact\n" if verdict == "VIOLATED" else "Q1: OK — x\n")
            rs = "b" if slot == "a" else "a"
            for sl, text in ((rs, real), ("a" if rs == "b" else "b", plant)):
                (root / STAGING / rid / sl).mkdir(parents=True)
                (root / STAGING / rid / sl / "run.log").write_text(text)
            h = hashlib.sha1(real.encode()).hexdigest()
            (rd / "manifest.tsv").write_text(f"# artifact\tsha1\nrun.log\t{h}\n")
            if tamper:
                (root / STAGING / rid / rs / "run.log").write_text(real + "edited after the verdict\n")

        run("2099-01-01-01", "VIOLATED", "checks run 72\n", "checks run 73\n", "a")    # real slot b: 73 unsourced
        run("2099-01-01-02", "OK", "checks run 73\n", "checks run 72\n", "b")          # real slot a: 73 sourced
        run("2099-01-01-03", "VIOLATED", "checks run 72\n", "x\n", None)               # no slot recorded
        run("2099-01-01-04", "VIOLATED", "checks run 72\n", "x\n", "b", tamper=True)  # staged copy changed
        run("2099-01-01-05", "OK", "checks run 73\n", "x\n", "b")
        (root / RUNS / "2099-01-01-05" / "meta.tsv").write_text("claim\tThe maintainer approved the cadence (run.log).\n")
        run("2099-01-01-06", "OK", "checks run 73\n", "x\n", "b")
        (root / RUNS / "2099-01-01-06" / "meta.tsv").write_text('claim\tThe log says "every check ran as frozen" (run.log).\n')
        (root / LEDGER).write_text("\n".join(led) + "\n")
        allrecs = replay_recs(root)
        recs = {x[0]["id"]: x for x in allrecs}
        t = tally(allrecs)
        cases = [
            ("the real slot (b) of a run whose plant is in a: its unsourced 73 flagged and matched",
             recs["2099-01-01-01"][2] is not None and ("FIGURE", "73", ["Q1"]) in recs["2099-01-01-01"][3]),
            ("the real slot (a) of a run whose plant is in b: nothing flagged",
             recs["2099-01-01-02"][2] is not None and recs["2099-01-01-02"][3] == []),
            ("no slot in control.txt: not replayable", recs["2099-01-01-03"][2] is None),
            ("a staged copy changed since prepare: not replayable", recs["2099-01-01-04"][2] is None),
            ("--through stops at the named run", len(replay_recs(root, through="2099-01-01-02")) == 2),
            ("the AS FILED tally refuses the OK run with an unquoted attribution, not the one with a QUOTE flag only",
             t["ok_refused"] == ["2099-01-01-05"]),
            ("the AS FILED tally refuses the VIOLATED run whose FIGURE flag matched, and counts it matched",
             t["vio_refused"] == ["2099-01-01-01"] and t["vio_refused_matched"] == ["2099-01-01-01"]),
            ("rounds per packet: six runs, six packets (one subject each); the one VIOLATED run whose violated "
             "question a flag matched is the upper bound's saved round",
             (t["packets"], t["rounds"], t["saved_upper"]) == (6, 6, ["2099-01-01-01"])),
            ("the size tally buckets every replayed run once (four in [1,7) artifacts, one of them VIOLATED)",
             t["by"][0][1][0][2:] == (1, 4) and sum(c[3] for c in t["by"][0][1]) == 4),
        ]
        for name, good in cases:
            bad += not good
            print(f"  {'ok  ' if good else 'WRONG'}  replay: {name}")
    return bad


def main():
    global DELIVERABLE_READ, REPLAY_BOUND, TALLY_ANY_FLAG
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--claim"); ap.add_argument("--artifact", action="append", default=[])
    ap.add_argument("--deliverable", action="append", default=[])
    ap.add_argument("--replay", action="store_true"); ap.add_argument("--from", dest="lo"); ap.add_argument("--to", dest="hi")
    ap.add_argument("--out"); ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--deliverable-ignored", action="store_true", help="KNOWN-BAD: the deliverables are not read")
    ap.add_argument("--replay-unbound", action="store_true", help="KNOWN-BAD: the replay takes slot a by default and skips the manifest")
    ap.add_argument("--tally-any-flag", action="store_true", help="KNOWN-BAD: the AS FILED tally refuses on any flag kind")
    ap.add_argument("--through", help="replay: the last run id to read (a window that does not grow with the ledger)")
    a = ap.parse_args()
    if a.deliverable_ignored:
        DELIVERABLE_READ = False
    if a.replay_unbound:
        REPLAY_BOUND = False
    if a.tally_any_flag:
        TALLY_ANY_FLAG = True
    if a.selftest:
        return selftest()
    if a.replay:
        n = lambda k: int(re.fullmatch(r"14z-(\d+)[a-z]?", k).group(1)) if k else None
        return replay(REPO, n(a.lo), n(a.hi), a.out, a.through)
    if a.claim is None:
        ap.error("give --claim and --artifact, --replay or --selftest")
    missing = [d for d in a.deliverable if d not in a.artifact]
    if missing:
        ap.error(f"a deliverable must be one of the artifacts: {missing[0]}")
    lines, summary = render(check(a.claim, corpus_from_specs(REPO, a.artifact), a.deliverable))
    print("\n".join(lines + [f"packet_check: {summary}"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
