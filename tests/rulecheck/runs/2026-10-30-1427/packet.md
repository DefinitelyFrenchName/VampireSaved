THE PACKET

Decision kind: recommendation
Subject: #338 done, awaiting release (14z-213), after run 2026-10-30-1414: the proof sheets' web build (proof_sheets.py web/webcheck, publish_sheets.sh) committed in 0a1b9233 and gated; the trial re-drawn with the gated tool and re-shot; drawn and published at the next tagged release, which closes it
Claim (the working agent's sentence): CLAIM: post the done-awaiting-release comment awaiting_comment.md on #338 (14z-213) and keep the ticket open (row ticket_row_338.tsv: status open, sessions 14z-212,14z-213), per the DONE, AWAITING RELEASE rule, after rule-checker run 2026-10-30-1414 (VIOLATED Q1, Q4; resolved: ledger_row_1414.txt). The ticket (issue_338.md) set an eight-point design: (1) tiles 192x112 by Lanczos, WebP q85; (2) no full-size picture ships, no link to one; (3) credits footer on every page from the games' own title screens, unofficial/not affiliated, a reduced-screenshots statement, the same notice in each WebP's metadata, nothing burned into pixels; (4) the plain-language intro and legend replacing the provenance block; (5) the 'no picture shows the fighters' list moved onto each gate's page; (6) no gate .log; (7) a gate with controls planting each fault; (8) drawn at a tagged release; hosting on the maintainer's own site by rsync. It rests on:
1. THE CHANGE, AS COMMITTED: change.diff (e68f8842..0a1b9233: tools/proof_sheets.py web/webcheck and helpers, among them the scrub that turns a bracketed path into one '(local path)'; new tools/publish_sheets.sh; new tests/test_proof_sheets_web.sh), records.diff (docs/project/release_format.md «The proof sheets' web build», tests/ci_cadence.tsv ondemand, tests/ci_portable.txt, HANDOFF.md's routing row). blobs.txt: the three files' blobs at 0a1b9233 equal the blobs gate_mac.log and trial2.log name.
2. THE GATE: gate_mac.log PASS on the Mac (header: blobs), its scrub line 'a bracketed one to a single (local path)'; control_modes_mac.txt and mode_*.log: the five modes missing-credits, full-size-tile, log-shipped, local-path, unreduced-clip each exit 1 with the mode's FAIL line. old_scrub_on_fixture.txt: the pre-fix scrub on the gate's own fixture text gives '((local path))', which the gate now fails.
3. THE TRIAL ON REAL DATA (14z-207's full local run, not a release): trial2.sh draws, checks and shoots one directory in one run; trial2.log: the tool blob d84a7eb1 before and after the run, 102 pages, 23183 tiles, 152 clips, 0 problems, webcheck PASS, indep_web.py (shares no code with proof_sheets.py) on the same directory: only .html/.wav/.webp, every WebP 192x112, every WAV 1 channel 24000 Hz 2 bytes, 0 media without a CAPCOM credit, 0 pages missing 'CAPCOM' or 'not affiliated', 0 local-path matches; the shot gate page holds 0 'build/agent' and its control-build line reads '(local path)'.
4. THE CREDITS: titles_READING.md and titles_copyrights.png — the copyright line read off each game's title screen in MAME.
5. THE LOOK: index.html.png and g_audit_landing_sound.html.png, the re-shot pages of that same trial directory (trial2.log names them); the maintainer on them: 'they look good' (DECISIONS_HISTORY.md lines 9174-9179); on the earlier shots, which predated the last scrub: 'looks good to me' (lines 9160-9166).
6. THE RULINGS: DECISIONS_HISTORY.md lines 9083-9099 (the design agreed), 9111-9117 (clips kept reduced and described; the path vs-proof-sheets/).
NOT TESTED: no release-commit run has been drawn (point 8 is the release's step, which is why the ticket stays open); publish_sheets.sh has only published to a local folder in the gate (DEPLOY_TARGET is unset), so no upload to the real site has run; the 'Lanczos' and 'q85' parameters are read from the code, not measured from the output; the WebP metadata was checked for the word CAPCOM, not for the full notice text; the trial's pages were looked at in two screenshots, not page by page, and the maintainer's look is at those two; the clips were not listened to after reduction; the intro's wording was checked by the maintainer's look, not against the design text by a tool; the gate and the trial ran on the Mac only; the comment names commit 0a1b9233, which reaches GitHub with this session's close push.
Artifacts (read every one, in full):
  - build/agent213/t338/closure/awaiting_comment.md
  - build/agent213/t338/closure/ticket_row_338.tsv
  - build/agent213/t338/closure/issue_338.md
  - build/agent213/t338/closure/ledger_row_1414.txt
  - build/agent213/t338/closure/change.diff
  - build/agent213/t338/closure/records.diff
  - build/agent213/t338/closure/blobs.txt
  - build/agent213/t338/closure/gate_mac.log
  - build/agent213/t338/closure/control_modes_mac.txt
  - build/agent213/t338/closure/mode_missing-credits.log
  - build/agent213/t338/closure/mode_full-size-tile.log
  - build/agent213/t338/closure/mode_log-shipped.log
  - build/agent213/t338/closure/mode_local-path.log
  - build/agent213/t338/closure/mode_unreduced-clip.log
  - build/agent213/t338/closure/old_scrub_on_fixture.txt
  - build/agent213/t338/closure/trial2.sh
  - build/agent213/t338/closure/trial2.log
  - build/agent213/t338/closure/indep_web.py
  - build/agent213/t338/closure/titles_READING.md
  - build/agent213/t338/closure/titles_copyrights.png
  - build/agent213/t338/closure/index.html.png
  - build/agent213/t338/closure/g_audit_landing_sound.html.png
  - DECISIONS_HISTORY.md.lines-9083-9099 (lines 9083-9099 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-212) — the proof sheets get a web build for the community: half-size WebP, ")
  - DECISIONS_HISTORY.md.lines-9111-9117 (lines 9111-9117 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #338: the clips are kept, reduced and described; the web build goes ")
  - DECISIONS_HISTORY.md.lines-9160-9166 (lines 9160-9166 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #335's dashboard sections and #338's web pages accepted on their loo")
  - DECISIONS_HISTORY.md.lines-9174-9179 (lines 9174-9179 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #338: the re-shot web pages accepted")
