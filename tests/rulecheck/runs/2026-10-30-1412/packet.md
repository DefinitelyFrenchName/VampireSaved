THE PACKET

Decision kind: recommendation
Subject: close #267 as done (14z-213): the session ledger is live on GitHub Pages from gh-pages 12a87ea0; the green guard admits exactly the page's orphan commit; the own-site leg runs at each close once DEPLOY_TARGET is set, skipped until then as ruled
Claim (the working agent's sentence): CLAIM: close #267 as done (14z-213). The closing comment closing_comment.md and the row ticket_row_267.tsv state the resolution. The ticket (issue_267.md: body and comments) asked for the session ledger as a static page generated from the dashboard's datasets and hosted publicly; its 14z-212 comment recorded the first publish REFUSED by the pre-push green guard (#290) and the ruling that the guard be fixed next session with a gate control, nothing bypassing #290, the ticket open until the page is live. It rests on:
1. THE GUARD CHANGE: fix.diff — tools/git-hooks/green_guard.py (edit-locked; drafted by the session, applied by the maintainer, STATE 14z-213 (1) quotes them: 'guard part applied for item 1'; item 1 is #267 per DECISIONS_HISTORY.md lines 9098-9108) gains LEDGER_REF refs/heads/gh-pages, LEDGER_FILES (.nojekyll index.html ledger.css ledger.js) and ledger_page(): a pushed commit is admitted with no tier row only when it is pushed to refs/heads/gh-pages (GUARD-PAGE-REF), has no parent (GUARD-PAGE-ORPHAN) and its tree is exactly those four names, each a 100644 blob (GUARD-PAGE-SHAPE); every other push is judged as before. tests/test_green_guard.sh section 7 (seven page-push cases) and three controls (guard-page-any-ref, guard-page-any-shape, guard-page-any-parent); tests/test_ledger_page.sh's publishing repo now copies the real pre-push hook and green_guard.py and sets core.hooksPath, and requires the guard's page line.
2. THE GATES: test_green_guard.mac.log and test_ledger_page.mac.log — both PASS on the Mac (their headers carry the blobs). pilot_classes.tsv, pilot_overlap.txt, pilot_head.txt: test_green_guard's five controls re-traced on PILOT, SAFE, every run HONOURED (tests/controls_concurrent.txt's row for test_green_guard is at the same blob ed5bfe18). test_ledger_page is not on the concurrent-controls list.
3. THE LIVE SITE: live_site.txt — the Pages API (source gh-pages /, status built, latest build commit 12a87ea0), each served file's SHA-256 equal to git show origin/gh-pages:<file>, the commit's tree (four 100644 blobs), the 11 <h2> sections rendered by headless Chrome after scripts (the count tools/ledger_csp_check.sh requires), 0 console lines matching Refused|Content Security Policy, and the rendered tiles' text. live_render.png: the rendered page.
4. THE RULINGS: DECISIONS_HISTORY.md lines 8876-8922 (unparked; who the page is for; hosted on both GitHub Pages and the own site at the close; the own-site upload may be skipped when not configured: 'Fail or ignore the deploy'), lines 9065-9080 (the first publish waits for the guard).
5. WHAT WAS LEARNED / WENT WRONG: records.diff — docs/project/gotchas.md's new entry (a publish test against a hookless scratch remote never meets the repository's guard), which the row's learned and wrong columns cite.
NOT TESTED: the own-site copy (alexrichard.org/vs-swarm-ledger/) has never been uploaded — DEPLOY_TARGET is unset, so every close SKIPS it, as ruled; its gate section uploads to a local folder only. GitHub Pages sends no Content-Security-Policy header, so the live render was not under a CSP (the strict-CSP render is the gate's and ledger_csp_check.sh's, on a local server). The live page was rendered by one browser (headless Chrome on the Mac), not by Safari or Firefox, and its interactive parts (hover tips, filters) were not exercised. The guard's exception was tested on the gate's synthetic repositories and the one real publish; a push of the page by a client that rewrites the tree's modes was not tried.
Artifacts (read every one, in full):
  - build/agent213/t267/closure/closing_comment.md
  - build/agent213/t267/closure/ticket_row_267.tsv
  - build/agent213/t267/closure/issue_267.md
  - build/agent213/t267/closure/fix.diff
  - build/agent213/t267/closure/records.diff
  - build/agent213/t267/closure/test_green_guard.mac.log
  - build/agent213/t267/closure/test_ledger_page.mac.log
  - build/agent213/t267/closure/pilot_classes.tsv
  - build/agent213/t267/closure/pilot_overlap.txt
  - build/agent213/t267/closure/pilot_head.txt
  - build/agent213/t267/closure/live_site.txt
  - build/agent213/t267/closure/live_render.png
  - DECISIONS_HISTORY.md.lines-8876-8922 (lines 8876-8922 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-29 (14z-212) — #267 unparked: the session ledger as a public page on gh-pages, the ", and the entries after it up to line 8922)
  - DECISIONS_HISTORY.md.lines-9065-9080 (lines 9065-9080 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-212) — #267: the first gh-pages publish waits for the green guard to admit ")
  - DECISIONS_HISTORY.md.lines-9098-9108 (lines 9098-9108 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — the opener: items 1-3 first, then #337, #338, #310; PILOT and ERIS m")
