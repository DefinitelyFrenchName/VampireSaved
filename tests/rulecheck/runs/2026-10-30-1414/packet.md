THE PACKET

Decision kind: recommendation
Subject: #338 done, awaiting release (14z-213): the proof sheets' web build (proof_sheets.py web/webcheck, publish_sheets.sh) implemented and gated; drawn and published at the next tagged release, which closes it
Claim (the working agent's sentence): CLAIM: post the done-awaiting-release comment awaiting_comment.md on #338 (14z-213) and keep the ticket open (row ticket_row_338.tsv: status open, sessions 14z-212,14z-213), per the DONE, AWAITING RELEASE rule; <COMMIT> in the comment is filled with the session commit that carries the change before posting. The ticket (issue_338.md) set an eight-point design: (1) tiles 192x112 by Lanczos, WebP q85; (2) no full-size picture ships, no link to one; (3) credits footer on every page from the games' own title screens, unofficial/not affiliated, a reduced-screenshots statement, the same notice in each WebP's metadata, nothing burned into pixels; (4) the plain-language intro and legend replacing the provenance block; (5) the 'no picture shows the fighters' list moved onto each gate's page; (6) no gate .log; (7) a gate with controls planting each fault; (8) drawn at a tagged release; hosting on the maintainer's own site by rsync. It rests on:
1. THE CHANGE: change.diff (tools/proof_sheets.py web/webcheck and helpers; new tools/publish_sheets.sh; new tests/test_proof_sheets_web.sh), records.diff (docs/project/release_format.md «The proof sheets' web build», tests/ci_cadence.tsv ondemand, tests/ci_portable.txt, HANDOFF.md's routing row).
2. THE GATE: gate_mac.log PASS on the Mac (header: blobs); control_modes_mac.txt and mode_*.log: the five modes missing-credits, full-size-tile, log-shipped, local-path, unreduced-clip each exit 1 with the mode's FAIL line.
3. THE TRIAL ON REAL DATA (14z-207's full local run, not a release): web_trial_tail.txt (102 pages, 23183 tiles, 152 clips, 0 problems), webcheck_trial.txt PASS; indep_web.py (shares no code with proof_sheets.py) / indep_web.txt: 102 .html, 152 .wav, 23183 .webp and nothing else; every WebP 192x112; every WAV (1 channel, 24000 Hz, 2 bytes); 0 media without a CAPCOM credit in metadata; 0 pages missing 'CAPCOM' or 'not affiliated'; 0 local-path matches.
4. THE CREDITS: titles_READING.md and titles_copyrights.png — the copyright line read off each game's title screen in MAME.
5. THE LOOK: index.html.png and g_audit_landing_sound.html.png (headless-Chrome screenshots of the trial's index and one gate page); the maintainer: 'looks good to me' (DECISIONS_HISTORY.md lines 9158-9164).
6. THE RULINGS: DECISIONS_HISTORY.md lines 9081-9097 (the design agreed), 9109-9115 (clips kept reduced and described; the path vs-proof-sheets/).
NOT TESTED: no release-commit run has been drawn (point 8 is the release's step, which is why the ticket stays open); publish_sheets.sh has only published to a local folder in the gate — DEPLOY_TARGET is unset, so no upload to the real site has run; the 'Lanczos' and 'q85' parameters are read from the code, not measured from the output; the WebP metadata was checked for the word CAPCOM, not for the full notice text; the trial's pages were looked at in two screenshots, not page by page; the clips were not listened to after reduction; the intro's wording was checked by the maintainer's look at the screenshot, not against the design text by a tool.
Artifacts (read every one, in full):
  - build/agent213/t338/closure/awaiting_comment.md
  - build/agent213/t338/closure/ticket_row_338.tsv
  - build/agent213/t338/closure/issue_338.md
  - build/agent213/t338/closure/change.diff
  - build/agent213/t338/closure/records.diff
  - build/agent213/t338/closure/gate_mac.log
  - build/agent213/t338/closure/control_modes_mac.txt
  - build/agent213/t338/closure/mode_missing-credits.log
  - build/agent213/t338/closure/mode_full-size-tile.log
  - build/agent213/t338/closure/mode_log-shipped.log
  - build/agent213/t338/closure/mode_local-path.log
  - build/agent213/t338/closure/mode_unreduced-clip.log
  - build/agent213/t338/closure/web_trial_tail.txt
  - build/agent213/t338/closure/webcheck_trial.txt
  - build/agent213/t338/closure/indep_web.py
  - build/agent213/t338/closure/indep_web.txt
  - build/agent213/t338/closure/titles_READING.md
  - build/agent213/t338/closure/titles_copyrights.png
  - build/agent213/t338/closure/index.html.png
  - build/agent213/t338/closure/g_audit_landing_sound.html.png
  - DECISIONS_HISTORY.md.lines-9081-9097 (lines 9081-9097 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-212) — the proof sheets get a web build for the community: half-size WebP, ")
  - DECISIONS_HISTORY.md.lines-9109-9115 (lines 9109-9115 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #338: the clips are kept, reduced and described; the web build goes ")
  - DECISIONS_HISTORY.md.lines-9158-9164 (lines 9158-9164 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #335's dashboard sections and #338's web pages accepted on their loo")
