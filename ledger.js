
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
