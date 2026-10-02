THE PACKET

Decision kind: recommendation
Subject: 14z-187 + 14z-187b close: the documentation packet (after runs 533-539)
Claim (the working agent's sentence): The 14z-187 + 14z-187b close's documentation is complete as far as its checks see: the findings table (build/agent187b/close/findings_row.txt, row (18) of STATE.md) names a tracked home for each of its fourteen findings (a)-(n) and a named test or an open ticket — #195 and #200 open in docs/project/tickets.tsv, read by the check open_tickets in the same run after the tickets check refreshed GitHub's issue list and passed (build/agent187b/close/out/runs/open_tickets.out, build/agent187b/close/out/runs/tickets.out PASS), with a planted twin open_tickets_plant that turns #195 to done and must fail (build/agent187b/close/out/runs/open_tickets_plant.out). The close's checks ran FULL with 21 checks and 0 not as expected (build/agent187b/close/out/exits.tsv, its first line "# run: full"): close_findings with its one gap homed (build/agent187b/close/out/runs/close_findings.out), homes_tracked over row (18) (build/agent187b/close/out/runs/homes_tracked.out), the retraction grep for 14z-187b (build/agent187b/close/out/runs/retraction_grep.out) with seven patterns (four first, three variant wordings added after run 2026-10-02-534), whose 37 retracted-class hits were each read by hand, plus one section name a reader found that no pattern matches, and given a verdict (build/agent187b/close/retraction_verdicts.tsv: MARKER, MARKED or ARCHIVE-MARKED), the maintainer's quotes verbatim — the CLOSE row's sixteen instruction quotes among its ok lines — with each message quoted or exempted for a reason (build/agent187b/close/out/runs/rulings_verbatim.out), the promises classed (build/agent187b/close/out/runs/promise_check.out) and the scratch census over both sittings' directories, build/agent187 and build/agent187b (build/agent187b/close/out/runs/scratch_census.out). NOT tested: that the table holds every finding of the two sittings — the checks see addresses, named homes and listed promises, not findings, so a finding never written into the table passes unseen; that each named test reproduces its finding — homes_tracked checks only that a home is tracked, (n)'s test runs only on the freeze that applies the staged patch, and (m)'s test carries both events in its rows, not the lesson itself; that each home's text is right (each was rule-checked when it was written, runs 2026-10-01-512 to 2026-10-02-532); that the by-hand verdicts on the retraction hits are right — no tool judges a hit, so a retracted wording read wrongly as marked passes unseen, and a wording none of the seven patterns matches is never a hit; that the hand classes the promise check and the scratch census pass on are right — build/agent187b/close/promises.tsv classes each promise by a written reason (NOT-A-PROMISE) or a pointer to a section (FULFILLED) whose content is judged by hand, the census counts that each of 63 programs has a classed row, not that its reason is true, and programs outside its two directories (the job's temporary directory, ERIS's ~/t188) are not censused, and a commitment whose wording the promise pattern does not match is not seen (build/agent187b/close/out/runs/promise_check.out says so); that a quote whose label rulings_verbatim reads as OTHER is verbatim (the tool lists and checks only quotes it classes as the maintainer's); that the hand-made exemptions are right (build/agent187b/close/rulings_exempt.tsv matches message prefixes and gives a reason per row, judged by hand); that the CLOSE row's prose figures for steps (2)-(5) match the run of record — read by hand against build/agent187b/close/out/exits.tsv and each check's output, no check compares them; the CLOSE row's later parts (the strict tier, the sweep, the procedure check and the push), which run after this packet.
Artifacts (read every one, in full):
  - build/agent187b/close/findings_row.txt
  - build/agent187b/close/close_row.txt
  - build/agent187b/close/out/exits.tsv
  - build/agent187b/close/out/runs/open_tickets.out
  - build/agent187b/close/out/runs/open_tickets_plant.out
  - build/agent187b/close/out/runs/close_findings.out
  - build/agent187b/close/out/runs/homes_tracked.out
  - build/agent187b/close/out/runs/retraction_grep.out
  - build/agent187b/close/retraction_verdicts.tsv
  - build/agent187b/close/out/runs/rulings_verbatim.out
  - build/agent187b/close/out/runs/promise_check.out
  - build/agent187b/close/out/runs/scratch_census.out
  - build/agent187b/close/classes.tsv
  - build/agent187b/close/out/runs/tickets.out
  - build/agent187b/close/checks.tsv
  - build/agent187b/close/promises.tsv
  - build/agent187b/close/rulings_exempt.tsv
  - tests/rulecheck/retractions/14z-187b.tsv
