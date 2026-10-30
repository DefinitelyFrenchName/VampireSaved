#!/usr/bin/env python3
"""ledger_page.py — THE SESSION LEDGER AS ONE STATIC PAGE, publishable outside claude.ai (GitHub #267, 14z-212).

Reads the datasets `tools/session_metrics.py collect` wrote (figures, rc_runs, tiers, costly, actions .json) and writes
ONE self-contained HTML file: the datasets gzip-compressed and base64-embedded, decoded in the browser
(DecompressionStream), no network fetch of any kind, every figure shown with its class, source and rule as on the
Claude dashboard (#264).

ITS AUDIENCE (the maintainer, 2026-10-29): "people interested in how the self-checking swarm performs" — so the page
must be understandable without this repository: it says what the project and the swarm are, how a rule-checker run
works, what every question means (QUESTIONS below, read from docs/project/rule_checker.md's checklists, the document
the readers are given, never a copy), and what each term means, before any number.

The page is public (ruled 2026-10-29, the maintainer: "gh-pages is fine", published by tools/publish_ledger.sh to the
orphan `gh-pages` branch at the close), so what it carries was ruled too: **"All but your own figures"** — every
figure except those about the maintainer read from the transcripts (PRIVATE below: their message count, the questions
answered, their reply time). The rule-checker texts are already public in tests/rulecheck/ledger.tsv. No ROM byte is
in any dataset.

Usage:
  python3 tools/ledger_page.py DIR --out OUTDIR [--repo DIR]  # DIR: a `session_metrics.py collect --out` directory;
                                                             # OUTDIR gets index.html, ledger.css and ledger.js
  python3 tools/ledger_page.py --extract OUTDIR/index.html  # the data a page embeds, as JSON (what the test reads)
Gate: tests/test_ledger_page.sh.
"""
import argparse, base64, gzip, json, os, re, sys
from datetime import datetime, timezone

DATASETS = ("figures", "rc_runs", "tiers", "costly", "actions")
# the figures about the maintainer, read from the transcripts: never published (ruled 2026-10-29, "All but your own figures")
PRIVATE = ("maint_msgs", "maint_answers", "reply_median_min")
BLOB_OPEN, BLOB_CLOSE = '<script type="application/octet-stream" id="ledger-data">', "</script>"
CHECKLISTS = (("evidence", "<!-- CHECKLIST BEGIN -->", "<!-- CHECKLIST END -->"),
              ("procedure", "<!-- PROCEDURE CHECKLIST BEGIN -->", "<!-- PROCEDURE CHECKLIST END -->"))
QLINE = re.compile(r"^(QP?\d) ([A-Z][A-Z\- ]+?) — (.+)$")


def questions(repo):
    """-> [{id, name, family, text}] read from the rule-checker spec's two checklists (the text the readers get)"""
    p = os.path.join(repo, "docs/project/rule_checker.md")
    if not os.path.exists(p):
        return []
    doc, out = open(p, encoding="utf-8").read(), []
    for fam, b, e in CHECKLISTS:
        if b in doc and e in doc:
            for ln in doc.split(b, 1)[1].split(e, 1)[0].splitlines():
                m = QLINE.match(ln.strip())
                if m:
                    out.append({"id": m.group(1), "name": m.group(2).capitalize(), "family": fam, "text": m.group(3)})
    return out


def catches(repo, path=None):
    """-> the curated worked examples (tests/rulecheck/catches.tsv), each joined to its run's subject and resolution
    (the ledger) and the readers' VIOLATED lines (the run's verdict_real.txt), quoted verbatim; a row whose run has no
    ledger row or no verdict file is refused (exit 1)"""
    path = path or os.path.join(repo, "tests/rulecheck/catches.tsv")
    if not os.path.exists(path):
        return []
    led = {}
    for ln in open(os.path.join(repo, "tests/rulecheck/ledger.tsv"), encoding="utf-8"):
        f = ln.rstrip("\n").split("\t")
        if len(f) == 11 and f[0][:2] == "20":
            led[f[0]] = f
    out = []
    for ln in open(path, encoding="utf-8"):
        if ln.startswith("#") or ln.startswith("run\t") or not ln.strip():
            continue
        run, head, why = ln.rstrip("\n").split("\t")
        vp = os.path.join(repo, "tests/rulecheck/runs", run, "verdict_real.txt")
        if run not in led or not os.path.exists(vp):
            sys.exit(f"ledger_page: catches row {run}: no ledger row or no {vp} — a worked example quotes a real run")
        r = led[run]
        out.append({"run": run, "session": r[2], "decision": r[3], "subject": r[4], "violated": r[8], "resolution": r[9],
                    "findings": [l.strip() for l in open(vp, encoding="utf-8") if re.match(r"QP?\d+: VIOLATED", l.strip())],
                    "headline": head, "why": why})
    return out


def load(d, repo=".", catches_path=None):
    data = {}
    for name in DATASETS:
        p = os.path.join(d, name + ".json")
        data[name] = json.load(open(p)) if os.path.exists(p) else []
    data["figures"] = [f for f in data["figures"] if f.get("metric") not in PRIVATE]
    data["questions"] = questions(repo)
    data["catches"] = catches(repo, catches_path)
    sessions = sorted({f["session"] for f in data["figures"]} | {r["session"] for r in data["rc_runs"]})
    data["meta"] = {"generated": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
                    "sessions": len(sessions), "withheld": list(PRIVATE)}
    return data


def encode(data):
    raw = json.dumps(data, separators=(",", ":"), sort_keys=True).encode()
    return base64.b64encode(gzip.compress(raw, 9, mtime=0)).decode()


def extract(page_text):
    i = page_text.index(BLOB_OPEN) + len(BLOB_OPEN)
    j = page_text.index(BLOB_CLOSE, i)
    return json.loads(gzip.decompress(base64.b64decode(page_text[i:j].strip())))


CSS = """
:root{--paper:#fbfaf7;--surface:#fff;--sunken:#f1efe9;--ink:#1d1c1a;--ink-2:#45423c;--ink-3:#6f6b62;
  --rule:#ddd8cc;--grid:#ebe7de;--accent:#8a2b2b;--bar:#2f62a3;--ok:#2f6b3a;--bad:#9b2c2c;--est:#7a5f14}
@media (prefers-color-scheme:dark){:root{--paper:#16161a;--surface:#1e1e24;--sunken:#26262d;--ink:#ecebe7;
  --ink-2:#c9c6be;--ink-3:#a29e94;--rule:#38373f;--grid:#2c2c33;--accent:#e08a8a;--bar:#7aa9e0;--ok:#7fc28c;--bad:#f08a8a;--est:#e0c070}}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
.wrap{max-width:68rem;margin:0 auto;padding:1.2rem 1rem 4rem}
h1{font-size:1.7rem;margin:.4rem 0 .2rem}h2{font-size:1.25rem;border-bottom:1px solid var(--rule);padding-bottom:.25rem;margin-top:2.2rem}
h3{font-size:1.02rem;margin:1.3rem 0 .4rem}
p{max-width:52rem}.sub{color:var(--ink-3);font-size:.9rem}
.scroller{overflow-x:auto}
table{border-collapse:collapse;font-size:.88rem;margin:.6rem 0;min-width:100%}
th,td{border:1px solid var(--rule);padding:.3rem .5rem;text-align:left;vertical-align:top}
th{background:var(--sunken)}
td.n,th.n{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
.cls{font-size:.68rem;letter-spacing:.04em;border-radius:.2rem;padding:0 .3rem;border:1px solid currentColor;white-space:nowrap}
.MEASURED{color:var(--ok)}.DERIVED{color:var(--ink-2)}.ESTIMATED{color:var(--est)}
.OK{color:var(--ok);font-weight:600}.VIOLATED{color:var(--bad);font-weight:600}.VOID{color:var(--ink-3)}
details{margin:.2rem 0}summary{cursor:pointer}
input{font:inherit;padding:.3rem .5rem;border:1px solid var(--rule);border-radius:.3rem;background:var(--surface);color:var(--ink);width:min(100%,24rem)}
.src{color:var(--ink-3);font-size:.78rem}
.note{border:1px solid var(--rule);background:var(--surface);border-radius:.4rem;padding:.7rem .9rem;margin:.8rem 0;max-width:52rem}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(11rem,1fr));gap:.7rem;margin:1rem 0}
.tile{background:var(--surface);border:1px solid var(--rule);border-radius:.5rem;padding:.7rem .85rem}
.tile .v{font-size:1.75rem;font-weight:650;font-variant-numeric:tabular-nums;line-height:1.2}
.tile .k{font-size:.86rem;color:var(--ink-2)}.tile .d{font-size:.78rem;color:var(--ink-3);margin-top:.2rem}
dl.gloss{display:grid;grid-template-columns:minmax(8rem,12rem) 1fr;gap:.35rem 1rem;max-width:56rem}
dl.gloss dt{font-weight:600}dl.gloss dd{margin:0;color:var(--ink-2)}
@media (max-width:40rem){dl.gloss{grid-template-columns:1fr}dl.gloss dd{margin-bottom:.5rem}}
ol.steps li{margin:.25rem 0;max-width:52rem}
.chart{position:relative;background:var(--surface);border:1px solid var(--rule);border-radius:.5rem;padding:.6rem .6rem .2rem;margin:.6rem 0}
.chart{overflow-x:auto}.chart svg{display:block;width:100%;min-width:38rem;height:auto}
.chart .tip{position:absolute;pointer-events:none;background:var(--ink);color:var(--paper);font-size:.8rem;
  padding:.25rem .45rem;border-radius:.3rem;white-space:nowrap;display:none;z-index:3}
.chart text{fill:var(--ink-3);font-size:11px}
table.matrix{min-width:0}table.matrix td{min-width:3rem}table.matrix td.diag{font-weight:650}
details.catch{border:1px solid var(--rule);border-radius:.5rem;background:var(--surface);padding:.55rem .8rem;margin:.6rem 0;max-width:56rem}
details.catch summary{line-height:1.45}details.catch h4{margin:.8rem 0 .25rem;font-size:.85rem;color:var(--ink-2)}
p.quote{border-left:3px solid var(--rule);padding:.1rem .7rem;margin:.3rem 0;font-size:.86rem;color:var(--ink-2);max-width:none;overflow-wrap:anywhere}
.chart .gl{stroke:var(--grid);stroke-width:1}.chart .bar{fill:var(--bar)}.chart .hit{fill:transparent}
.chart .hit:hover+.bar,.chart g:hover .bar{opacity:.75}
code{background:var(--sunken);border-radius:.24rem;padding:.06em .3em;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.86em}
"""

INTRO = """
<p><strong>Project VAMPIRE SAVED</strong> is a fan modification of the 1997 arcade game <em>Vampire Savior</em>
(Capcom CPS-2): it adds the three characters the game's sibling releases carry, on the original engine, under one rule
— every match that does not involve them must stay bit-for-bit identical to the unmodified game. The engineering is
done by <strong>AI agents</strong> (Claude, in Claude Code sessions): one <em>orchestrator</em> per working session,
which spawns <em>workers</em> to measure and read, with a human maintainer who rules on anything a player could feel.</p>
<p>The agents check their own work. Before an <strong>action</strong> — a build of the game, a freeze of a release,
a change to a test's expected results, a recommendation to the maintainer such as closing a ticket, a session's push
— the orchestrator writes the claim it is about to act on and the evidence it rests on, and an adversarial
<strong>rule-checker</strong> must find nothing wrong with it. This page measures how often the agents get that right
the first time, what the checker catches, and whether the checker itself is alive.</p>
"""

HOW = """
<ol class="steps">
<li><strong>The packet.</strong> The orchestrator states one claim — what it concludes, what it rests on, and what it
did <em>not</em> test — and lists the files that are its evidence. No narrative: a checker handed a summary inherits its
framing.</li>
<li><strong>Two readers, one plant.</strong> Two fresh agents with no other context each get one packet. One packet is
the real one; the other is a <em>plant</em>: a known-bad packet drawn from a calibrated set, built from a real past
mistake. Which reader gets which is drawn at random, and neither knows.</li>
<li><strong>Five questions.</strong> Each reader answers the same five questions (below) from the files alone, each
OK, VIOLATED or N-A with its evidence, and a verdict.</li>
<li><strong>The plant must be caught.</strong> If the planted packet does not come back VIOLATED on its expected
question, the run is VOID: a reader that passes a known-bad packet proves nothing about the real one.</li>
<li><strong>A VIOLATED verdict stops the action.</strong> The orchestrator answers each violated question in writing
(the <em>resolution</em>, recorded verbatim), fixes the work or the claim, and prepares a new packet: a
<em>re-check</em>. The action proceeds only on an OK.</li>
</ol>
"""

GLOSSARY = [
    ("Session", "One sitting of the orchestrator with the maintainer, named 14z-N (a fixed prefix, then a counter)."),
    ("Action", "One thing put to the rule-checker and every re-check of it until one passes or the action is "
               "dropped. Its kind is its decision: build, freeze, expectation, recommendation, procedure."),
    ("Run", "One rule-checker check of one packet: two readers, one real packet, one plant."),
    ("First run", "An action's first run that licensed anything (a VOID run never counts as one)."),
    ("Re-check", "Any run of an action after its first; each follows a written resolution of what was violated."),
    ("Plant / CAUGHT / DEAD", "The known-bad packet beside the real one. CAUGHT: the reader found its violation. "
                              "DEAD: it did not, and the run is VOID."),
    ("VOID", "A run whose plant was not caught: it licenses nothing, and it is not counted in the rates."),
    ("Resolution", "The orchestrator's written answer to each violated question, recorded with the run."),
    ("Calibration", "A run that checks the checker itself on a fixture of known verdict; not an action."),
    ("Not run", "A packet prepared but never sent to readers (its writer caught a fault first); not counted."),
    ("Decision kinds", "build: a romset built for testing; freeze: a release of the romsets and their expected "
                       "results; expectation: a test's frozen expected result changed; recommendation: a report "
                       "or recommendation to the maintainer (closing a ticket among them); procedure: a session's "
                       "working method, read from its transcript before a push or a close."),
    ("MEASURED / DERIVED / ESTIMATED", "Every figure's class. MEASURED: read from a record the work wrote. "
                                       "DERIVED: arithmetic on measured figures, the formula stated. ESTIMATED: a "
                                       "heuristic, its rule stated, and it can be wrong."),
    ("Linking", "The ledger before 2026-10-29 records no action id, so its runs are grouped into actions by rule: a "
                "subject that names the run it follows ('after run 682'), else similar wording within the session "
                "(ESTIMATED). Since then every run records its action."),
]

JS = r"""
(async function(){
  const out = document.getElementById('app');
  function el(t, a, ...k){ const e = document.createElement(t); for (const [x,y] of Object.entries(a||{})) {
      if (x === 'class') e.className = y; else e.setAttribute(x, y); }
    for (const c of k) e.append(c instanceof Node ? c : document.createTextNode(c == null ? '' : String(c))); return e; }
  const NS = 'http://www.w3.org/2000/svg';   // an XML namespace name, not a fetch (the test strips exactly this URI)
  function sv(t, a){ const e = document.createElementNS(NS, t); for (const [x,y] of Object.entries(a||{})) e.setAttribute(x, y); return e; }
  let D;
  try {
    const b = atob(document.getElementById('ledger-data').textContent.trim());
    const u = Uint8Array.from(b, c => c.charCodeAt(0));
    const s = new Response(new Blob([u]).stream().pipeThrough(new DecompressionStream('gzip')));
    D = JSON.parse(await s.text());
  } catch (e) { out.append(el('p', {class:'note'}, 'This browser cannot decode the embedded data (' + e + ').')); return; }
  const keyN = k => { const m = /^14z-(\d+)([a-z]?)$/.exec(k); return m ? [ +m[1], m[2] ] : [1e9, k]; };
  const asc = (a, b) => { const x = keyN(a), y = keyN(b); return x[0] - y[0] || (x[1] > y[1] ? 1 : x[1] < y[1] ? -1 : 0); };
  const pct = (a, b) => b ? Math.round(100 * a / b) + ' %' : '–';
  const sessions = [...new Set(D.figures.map(f => f.session).concat(D.rc_runs.map(r => r.session)))].sort(asc);
  const fig = {}; for (const f of D.figures) (fig[f.session] = fig[f.session] || {})[f.metric] = f;
  // a few early runs recorded their session's TRANSCRIPT id instead of its key: name the session where the data maps it
  const tid = {}; for (const f of D.figures) if (f.metric === 'transcript') tid[String(f.value)] = f.session;
  const sessName = s => tid[s] ? tid[s] : (/^[0-9a-f]{8}$/.test(s) ? 'transcript ' + s : s);
  const v = (s, m) => (fig[s] && fig[s][m]) ? fig[s][m].value : '';
  const date = {}; for (const r of D.rc_runs) { const d = r.id.slice(0, 10); if (!date[r.session] || d < date[r.session]) date[r.session] = d; }
  document.getElementById('meta').textContent = D.meta.sessions + ' sessions · generated ' + D.meta.generated +
    ' · withheld: the maintainer\'s own figures (message count, answers, reply time)';
  const cls = c => el('span', {class: 'cls ' + c}, c);
  const Q = {}; for (const q of D.questions) Q[q.id] = q;
  const A = D.actions, R = D.rc_runs;

  // ---- 1. headline
  const planted = R.filter(r => r.plant === 'CAUGHT' || r.plant === 'DEAD');
  const caught = planted.filter(r => r.plant === 'CAUGHT').length;
  const firstOk = A.filter(a => a.verdict === 'OK').length, finalOk = A.filter(a => a.final === 'OK').length;
  const stopped = A.filter(a => a.final === 'VIOLATED').length;
  const runs = A.reduce((s, a) => s + a.runs, 0);
  const med = xs => { if (!xs.length) return null; const t = xs.slice().sort((a, b) => a - b), m = t.length >> 1; return t.length % 2 ? t[m] : (t[m - 1] + t[m]) / 2; };
  const fmtH = h => h < 1 ? Math.round(h * 60) + ' min' : h.toFixed(1) + ' h';
  const H = A.filter(a => a.hours != null).map(a => a.hours);
  const tile = (val, k, d) => el('div', {class:'tile'}, el('div', {class:'v'}, val), el('div', {class:'k'}, k), el('div', {class:'d'}, d));
  out.append(el('h2', {}, 'At a glance'), el('div', {class:'tiles'},
    tile(A.length, 'actions checked', runs + ' runs of these actions (calibrations not counted)'),
    tile(pct(firstOk, A.length), 'OK at the first check', firstOk + ' of ' + A.length + ' actions passed without a re-check'),
    tile(pct(finalOk, A.length), 'OK in the end', finalOk + ' passed, at once or after re-checks; ' + stopped + ' end on a VIOLATED run: ' +
      'withdrawn, or re-checked under wording the linking did not follow (ESTIMATED)'),
    tile(A.length ? (runs / A.length).toFixed(1) : '–', 'checks per action', 'mean runs until the last one'),
    tile(med(H) == null ? '–' : fmtH(med(H)), 'median time to pass', 'from an action\'s first packet to the one that passed ' +
      '(0 when the first passed); ' + H.length + ' passed actions have both times on record'),
    tile(pct(caught, planted.length), 'plants caught', caught + ' of ' + planted.length + ' runs: the readers stayed alive')));
  out.append(el('p', {class:'sub'}, 'Actions are those of the sessions on this page; runs recorded under a transcript id no session ' +
    'could be given are not among them. Grouping runs into actions is partly ESTIMATED (see Linking, below).'));

  // ---- 2. trends: one single-series bar chart each, oldest session first
  const S = sessions.filter(s => A.some(a => a.session === s));
  function bars(title, desc, rows, fmt, max){
    const W = 960, H = 220, L = 40, B = 34, T = 10, n = rows.length, bw = (W - L - 8) / Math.max(n, 1);
    const svg = sv('svg', {viewBox: `0 0 ${W} ${H}`, role:'img', 'aria-label': title});
    for (const g of [0, .5, 1]) { const y = T + (H - T - B) * (1 - g);
      svg.append(sv('line', {x1: L, x2: W - 4, y1: y, y2: y, class:'gl'}));
      const t = sv('text', {x: L - 6, y: y + 4, 'text-anchor':'end'}); t.textContent = fmt(max * g, true); svg.append(t); }
    const box = el('div', {class:'chart'}), tip = el('div', {class:'tip'});
    rows.forEach((r, i) => {
      const x = L + i * bw, h = (H - T - B) * Math.min(r.y / max, 1), y = H - B - h, g = sv('g', {});
      const hit = sv('rect', {x, y: T, width: bw, height: H - T - B, class:'hit'});
      const bar = sv('path', {class:'bar', d: h > 0 ? `M${x + 1},${H - B} V${y + Math.min(4, h)} q0,-4 4,-4 H${x + bw - 5} q4,0 4,4 V${H - B} Z` : ''});
      g.append(hit, bar);
      g.addEventListener('mousemove', ev => { const rc = box.getBoundingClientRect();
        tip.textContent = r.label; tip.style.display = 'block';
        tip.style.left = Math.min(ev.clientX - rc.left + 10, rc.width - tip.offsetWidth - 4) + 'px'; tip.style.top = (ev.clientY - rc.top - 30) + 'px'; });
      g.addEventListener('mouseleave', () => { tip.style.display = 'none'; });
      svg.append(g);
      if (i === 0 || i === n - 1 || (i % 10 === 0 && i < n - 5)) { const t = sv('text', {x: i === n - 1 ? x + bw : i === 0 ? x : x + bw / 2, y: H - B + 16,
        'text-anchor': i === n - 1 ? 'end' : i === 0 ? 'start' : 'middle'}); t.textContent = r.x; svg.append(t); }
    });
    box.append(svg, tip);
    return [el('h3', {}, title), el('p', {class:'sub'}, desc), box];
  }
  const per = S.map(s => { const a = A.filter(x => x.session === s), ok = a.filter(x => x.verdict === 'OK').length, rn = a.reduce((t, x) => t + x.runs, 0);
    return {s, n: a.length, ok, rn}; });
  out.append(el('h2', {}, 'Over time'),
    ...bars('OK at the first check, per session', 'The share of each session\'s actions whose first run passed. Hover a bar for its session and counts; the sessions table below holds every value.',
      per.map(p => ({x: p.s, y: 100 * p.ok / p.n, label: `${p.s}${date[p.s] ? ' (' + date[p.s] + ')' : ''}: ${p.ok} of ${p.n} actions OK first (${Math.round(100 * p.ok / p.n)} %)`})),
      (y) => Math.round(y) + ' %', 100),
    ...bars('Checks per action, per session', 'Mean runs per action: 1 means every action passed at once.',
      per.map(p => ({x: p.s, y: p.rn / p.n, label: `${p.s}: ${p.rn} runs for ${p.n} actions (${(p.rn / p.n).toFixed(1)} each)`})),
      (y) => y.toFixed(y < 10 && y % 1 ? 1 : 0), Math.max(2, Math.ceil(Math.max(...per.map(p => p.rn / p.n)))))
  );

  // ---- 3. the questions
  const qFirst = {}; for (const a of A) for (const q of (a.violated ? a.violated.split(' ') : [])) qFirst[q] = (qFirst[q] || 0) + 1;
  const qAll = {}; for (const r of R) if (r.verdict === 'VIOLATED') for (const q of (r.violated ? r.violated.split(' ') : [])) qAll[q] = (qAll[q] || 0) + 1;
  const famOf = a => a.decision === 'procedure' ? 'procedure' : 'evidence';
  const firstViol = A.filter(a => a.verdict === 'VIOLATED').length;
  const famViol = {}; for (const a of A) if (a.verdict === 'VIOLATED') famViol[famOf(a)] = (famViol[famOf(a)] || 0) + 1;
  const qt = el('table', {}, el('tr', {}, el('th', {}, 'question'), el('th', {}, 'what it asks'), el('th', {class:'n'}, 'first runs it stopped'), el('th', {class:'n'}, 'all runs it stopped')));
  for (const fam of ['evidence', 'procedure']) {
    const qs = D.questions.filter(q => q.family === fam);
    if (!qs.length) continue;
    qt.append(el('tr', {}, el('th', {colspan: 4}, fam === 'evidence' ? 'The five questions (builds, freezes, expectations, recommendations)' : 'The five procedure questions (a session\'s working method, read from its transcript)')));
    for (const q of qs) { const short = q.text.split(/(?<=[?.])\s/)[0];
      qt.append(el('tr', {}, el('td', {}, el('strong', {}, q.id), ' ', q.name),
        el('td', {}, el('details', {}, el('summary', {}, short), el('p', {class:'src'}, q.text))),
        el('td', {class:'n'}, (qFirst[q.id] || 0) + (famViol[fam] ? ' (' + pct(qFirst[q.id] || 0, famViol[fam]) + ')' : '')),
        el('td', {class:'n'}, qAll[q.id] || 0))); }
  }
  out.append(el('h2', {}, 'What the checker asks, and what it stops'),
    el('p', {}, 'Each question is the reader\'s own text, read from the document the readers are given (open a row for all of it). ' +
      'A run can stop on several questions at once, so the shares do not add up to 100 %: each is the share of its family\'s ' +
      'first runs that were VIOLATED (' + (famViol.evidence || 0) + ' for the five questions, ' + (famViol.procedure || 0) +
      ' for the procedure questions).'),
    el('div', {class:'scroller'}, qt));

  // ---- 3b. which questions fail together, on first runs
  out.append(el('h2', {}, 'Which questions fail together'),
    el('p', {}, 'Each cell counts the VIOLATED first runs that broke both its row\'s and its column\'s question; the diagonal is each ' +
      'question\'s own total, and "alone" counts the first runs it stopped by itself. Darker is more.'));
  for (const fam of ['evidence', 'procedure']) {
    const ids = D.questions.filter(q => q.family === fam).map(q => q.id), V = A.filter(a => a.verdict === 'VIOLATED' && famOf(a) === fam);
    if (!ids.length || !V.length) continue;
    const c = {}, alone = {}; let mx = 1;
    for (const a of V) { const qs = a.violated.split(' ').filter(q => ids.includes(q));
      if (qs.length === 1) alone[qs[0]] = (alone[qs[0]] || 0) + 1;
      for (const x of qs) for (const y of qs) { const k = x + y; c[k] = (c[k] || 0) + 1; if (c[k] > mx) mx = c[k]; } }
    const m = el('table', {class:'matrix'}, el('tr', {}, el('th', {}, ''), ...ids.map(q => el('th', {class:'n', title: Q[q] ? Q[q].name : q}, q)), el('th', {class:'n'}, 'alone')));
    for (const x of ids) m.append(el('tr', {}, el('th', {title: Q[x] ? Q[x].name : x}, x + (Q[x] ? ' ' + Q[x].name : '')),
      ...ids.map(y => { const n = c[x + y] || 0, td = el('td', {class:'n' + (x === y ? ' diag' : ''), title: x + ' with ' + y + ': ' + n + ' first runs'}, n || '');
        td.style.background = n ? `color-mix(in srgb, var(--bar) ${Math.round(12 + 60 * n / mx)}%, transparent)` : ''; return td; }),
      el('td', {class:'n'}, alone[x] || 0)));
    out.append(el('h3', {}, (fam === 'evidence' ? 'The five questions' : 'The procedure questions') + ' — ' + V.length + ' VIOLATED first runs'),
      el('div', {class:'scroller'}, m));
  }

  // ---- 3c. worked examples
  if (D.catches.length) {
    out.append(el('h2', {}, 'Worked examples of real catches'),
      el('p', {}, 'Chosen by hand so each kind of catch appears once. The headline and "why it matters" are ours; what was checked, ' +
        'the readers\' findings and the resolution are quoted from the run\'s own record, unedited.'));
    for (const x of D.catches) {
      const d = el('details', {class:'catch'}, el('summary', {}, el('strong', {}, x.headline), ' ', el('span', {class:'src'}, x.run + ' · ' + sessName(x.session) + ' · ' + x.decision + ' · ' + x.violated)));
      d.append(el('p', {}, x.why), el('h4', {}, 'What was checked'), el('p', {class:'quote'}, x.subject),
        el('h4', {}, 'What the readers found'), ...x.findings.map(f => el('p', {class:'quote'}, f)),
        el('h4', {}, 'The resolution'), el('p', {class:'quote'}, x.resolution));
      out.append(d);
    }
  }

  // ---- 4. per decision kind
  const kinds = [...new Set(A.map(a => a.decision))].sort();
  const kt = el('table', {}, el('tr', {}, el('th', {}, 'decision'), el('th', {class:'n'}, 'actions'), el('th', {class:'n'}, 'OK at the first check'), el('th', {class:'n'}, 'OK in the end'), el('th', {class:'n'}, 'checks per action'), el('th', {class:'n'}, 'median time to pass (0 when the first passed)')));
  for (const k of kinds) { const a = A.filter(x => x.decision === k), f = a.filter(x => x.verdict === 'OK').length, z = a.filter(x => x.final === 'OK').length, rn = a.reduce((t, x) => t + x.runs, 0);
    kt.append(el('tr', {}, el('td', {}, k), el('td', {class:'n'}, a.length), el('td', {class:'n'}, f + ' (' + pct(f, a.length) + ')'), el('td', {class:'n'}, z + ' (' + pct(z, a.length) + ')'), el('td', {class:'n'}, (rn / a.length).toFixed(1)),
      el('td', {class:'n'}, (() => { const h = a.filter(x => x.hours != null).map(x => x.hours); return h.length ? fmtH(med(h)) + ' (' + h.length + ')' : '–'; })()))); }
  out.append(el('h2', {}, 'By kind of action'), el('div', {class:'scroller'}, kt));

  // ---- 5. sessions
  const cols = [['rc_runs','runs'],['actions','actions'],['first_ok_pct','OK first %'],['commits','commits'],
                ['tier_runs','test-tier runs'],['active_h','active hours'],['out_tok','output tokens'],['workers','workers']];
  const t3 = el('table', {}, el('tr', {}, el('th', {}, 'session'), el('th', {}, 'from'), ...cols.map(c => el('th', {class:'n'}, c[1]))));
  for (const s of sessions.slice().reverse()) {
    const d = el('details', {}, el('summary', {}, s));
    const ft = el('table', {}, el('tr', {}, el('th', {}, 'section'), el('th', {}, 'figure'), el('th', {class:'n'}, 'value'), el('th', {}, 'class'), el('th', {}, 'source · rule')));
    for (const f of D.figures.filter(f => f.session === s))
      ft.append(el('tr', {}, el('td', {}, f.section), el('td', {}, f.label), el('td', {class:'n'}, f.value + (f.unit ? ' ' + f.unit : '')),
        el('td', {}, cls(f.class)), el('td', {class:'src'}, f.source + (f.rule ? ' · ' + f.rule : ''))));
    d.append(el('div', {class:'scroller'}, ft));
    t3.append(el('tr', {}, el('td', {}, d), el('td', {}, date[s] || ''), ...cols.map(c => el('td', {class:'n'}, v(s, c[0])))));
  }
  out.append(el('h2', {}, 'Sessions'), el('p', {class:'sub'}, 'Open a session for every figure with its class, its source and, unless MEASURED, its rule.'),
    el('div', {class:'scroller'}, t3));

  // ---- 6. rule-checker runs, filtered
  const box = el('input', {placeholder: 'filter: a session, OK, VIOLATED, Q4, a word…', 'aria-label':'filter the runs'}), t4 = el('tbody');
  const draw = () => { const q = box.value.toLowerCase(); t4.replaceChildren(); let shown = 0;
    for (const r of R.slice().reverse()) { const txt = [r.id, r.session, r.decision, r.verdict, r.violated, r.subject, r.resolution].join(' ').toLowerCase();
      if (q && !txt.includes(q)) continue; if (++shown > 400) break;
      t4.append(el('tr', {}, el('td', {}, r.id), el('td', {}, r.session), el('td', {}, r.decision), el('td', {class: r.verdict}, r.verdict),
        el('td', {}, r.violated), el('td', {}, r.subject), el('td', {class:'src'}, r.resolution))); } };
  box.addEventListener('input', draw); draw();
  out.append(el('h2', {}, 'Every rule-checker run'),
    el('p', {class:'sub'}, 'Newest first, at most 400 shown; filter to find the rest. The resolution is the orchestrator\'s written answer to what was violated.'),
    box, el('div', {class:'scroller'}, el('table', {},
    el('thead', {}, el('tr', {}, ...['run','session','decision','verdict','violated','what was checked','resolution'].map(h => el('th', {}, h)))), t4)));

  // ---- 7. tier runs
  const t5 = el('table', {}, el('tr', {}, ...['run','session','commit','wall s','pass','fail','skip','controls'].map(h => el('th', {}, h))));
  for (const r of D.tiers.slice().sort((a, b) => a.start < b.start ? 1 : -1))
    t5.append(el('tr', {}, el('td', {}, r.run), el('td', {}, r.session), el('td', {}, r.head), el('td', {class:'n'}, r.wall_s),
      el('td', {class:'n'}, r.pass), el('td', {class:'n'}, r.fail), el('td', {class:'n'}, r.skip), el('td', {class:'n'}, r.controls)));
  out.append(el('h2', {}, 'Test-tier runs'), el('p', {class:'sub'}, 'The static test tier (some 160 gates, each with must-fire controls) the sessions ran, newest first.'),
    el('div', {class:'scroller'}, t5));
})();
"""


def render(data):
    gloss = "".join(f"<dt>{k}</dt><dd>{v}</dd>" for k, v in GLOSSARY)
    return ("<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">\n"
            "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\n"
            "<title>Self-checking swarm ledger</title>\n<link rel=\"stylesheet\" href=\"ledger.css\"></head>\n<body><div class=\"wrap\">\n"
            "<h1>A self-checking AI swarm: the ledger</h1>\n<p class=\"sub\" id=\"meta\"></p>\n" + INTRO +
            "<div id=\"app\"><noscript>This page renders its data with JavaScript.</noscript></div>\n"
            "<h2>How a check works</h2>\n" + HOW +
            "<h2>Terms</h2>\n<dl class=\"gloss\">" + gloss + "</dl>\n"
            "<p class=\"sub\">Generated by <code>tools/session_metrics.py</code> and <code>tools/ledger_page.py</code> in the "
            "project's repository (#264, #267, #335); the rule-checker is specified in "
            "<code>docs/project/rule_checker.md</code>.</p></div>\n"
            + BLOB_OPEN + "\n" + encode(data) + "\n" + BLOB_CLOSE + "\n<script src=\"ledger.js\"></script>\n</body></html>\n")


FILES = ("index.html", "ledger.css", "ledger.js")


def write(data, out):
    """the page as THREE files in `out` — no inline script or style, so it runs under a strict Content-Security-Policy
    (`script-src 'self'; style-src 'self'`, the maintainer's own site, 14z-212) as on GitHub Pages; the data stays in
    index.html as a non-executable block"""
    os.makedirs(out, exist_ok=True)
    for name, text in zip(FILES, (render(data), CSS, JS)):
        with open(os.path.join(out, name), "w", encoding="utf-8") as f:
            f.write(text)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("dir", nargs="?")
    ap.add_argument("--out")
    ap.add_argument("--repo", default=".")
    ap.add_argument("--catches", help="the worked examples' file (default tests/rulecheck/catches.tsv under --repo)")
    ap.add_argument("--extract", metavar="FILE")
    a = ap.parse_args()
    if a.extract:
        json.dump(extract(open(a.extract, encoding="utf-8").read()), sys.stdout, sort_keys=True)
        return 0
    if not (a.dir and a.out):
        ap.error("DIR and --out are required")
    data = load(a.dir, a.repo, a.catches)
    write(data, a.out)
    print(f"{a.out}: {sum(os.path.getsize(os.path.join(a.out, n)) for n in FILES):,} bytes in {', '.join(FILES)}; {data['meta']['sessions']} sessions; "
          f"{len(data['figures'])} figures, {len(data['rc_runs'])} runs, {len(data['actions'])} actions, "
          f"{len(data['questions'])} questions, {len(data['catches'])} worked examples; withheld: {', '.join(PRIVATE)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
