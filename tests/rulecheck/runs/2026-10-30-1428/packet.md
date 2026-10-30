THE PACKET

Decision kind: recommendation
Subject: #338 done, awaiting release (14z-213), after runs 2026-10-30-1414 and -1427: the proof sheets' web build gated, the trial re-drawn with the final tool and shot top and bottom, the clip caption fixed; drawn and published at the next tagged release, which closes it
Claim (the working agent's sentence): CLAIM: post the done-awaiting-release comment awaiting_comment.md on #338 (14z-213), with <CLOSE> filled by the session's close commit (which carries the working-tree changes below), and keep the ticket open (row ticket_row_338.tsv: status open, sessions 14z-212,14z-213), per the DONE, AWAITING RELEASE rule, after rule-checker runs 2026-10-30-1414 (VIOLATED Q1, Q4) and -1427 (VIOLATED Q1), each resolved: ledger_rows.txt. The ticket (issue_338.md) set an eight-point design: (1) tiles 192x112 by Lanczos, WebP q85; (2) no full-size picture ships, no link to one; (3) credits footer on every page from the games' own title screens, unofficial/not affiliated, a reduced-screenshots statement, the same notice in each WebP's metadata, nothing burned into pixels; (4) the plain-language intro and legend replacing the provenance block; (5) the 'no picture shows the fighters' list moved onto each gate's page; (6) no gate .log; (7) a gate with controls planting each fault; (8) drawn at a tagged release; hosting on the maintainer's own site by rsync. It rests on:
1. THE CHANGE: change.diff (e68f8842 to the working tree: tools/proof_sheets.py web/webcheck and helpers, among them the scrub turning a bracketed path into one '(local path)' and a judged clip's caption into 'the recording'; prove() naming a judged .wav a recording; new tools/publish_sheets.sh; new tests/test_proof_sheets_web.sh), records.diff (docs/project/release_format.md «The proof sheets' web build», with the drawing time 'about 1 min 40 s (1 min 41 s and 1 min 39 s on two runs)', tests/ci_cadence.tsv ondemand, tests/ci_portable.txt, HANDOFF.md's routing row). blobs.txt: the files at 0a1b9233 and in the working tree, and the blobs each log ran on (tool 8c0b18a2, gate db3ecfbb, publisher 8368249d).
2. THE GATES: gate_mac.log PASS on the Mac (header: the working-tree blobs), among its checks 'a bracketed one to a single (local path)' and 'a judged sound clip is captioned a recording, a judged image a picture, and the web build corrects an older run's clip caption'; control_modes_mac.txt and mode_*.log: the five modes missing-credits, full-size-tile, log-shipped, local-path, unreduced-clip each exit 1 with the mode's FAIL line. old_scrub_on_fixture.txt: the pre-fix scrub gives '((local path))'; judged_old_tool.txt: the committed tool of 0a1b9233 captions the judged .wav 'the picture', which the new check fails. test_proof_sheets_mac.log: the local sheets gate PASS on the same tool blob.
3. THE TRIAL ON REAL DATA (14z-207's full local run, not a release): trial2.sh draws, checks and shoots one directory in one run; trial2.log: tool blob 8c0b18a2 before and after, 102 pages, 23183 tiles, 152 clips, 0 problems, drawn in 1m41.153s, webcheck PASS, indep_web.py (no code shared with proof_sheets.py) on the same directory: only .html/.wav/.webp, every WebP 192x112, every WAV 1 channel 24000 Hz 2 bytes, 0 media without a CAPCOM credit, 0 pages missing 'CAPCOM' or 'not affiliated', 0 local-path matches; the shot gate page holds 0 'build/agent' and its control-build line reads '(local path)'. web2_sizes.txt: that kind of build's bytes by kind (tiles 223.2 MB, clips 33.9 MB, pages 8.7 MB; du 306M), measured on the d84a7eb1 draw of the same run.
4. THE CREDITS: titles_READING.md and titles_copyrights.png — the copyright line read off each game's title screen in MAME.
5. THE LOOK: index.html.png and g_audit_landing_sound.html.png, the tops of the trial's index and gate page (5000 px), and footer_index.png and footer_gate.png, their bottoms from whole-page shots (shots3_bottoms.txt: each page ended inside its shot), all of the build trial2.log drew. The maintainer: on the tops (shot from the d84a7eb1 draw), 'they look good' (DECISIONS_HISTORY.md lines 9175-9180); on the footers (shot from the d84a7eb1 draw), 'they do', and on fixing the clip caption, 'do it' (lines 9182-9187); on the first shots, which predated the last scrub, 'looks good to me' (lines 9161-9167).
6. THE RULINGS: DECISIONS_HISTORY.md lines 9084-9100 (the design agreed), 9112-9118 (clips kept reduced and described; the path vs-proof-sheets/).
NOT TESTED: no release-commit run has been drawn (point 8 is the release's step, which is why the ticket stays open); publish_sheets.sh has only published to a local folder in the gate (DEPLOY_TARGET is unset), so no upload to the real site has run; the 'Lanczos' and 'q85' parameters are read from the code, not measured from the output; the WebP metadata was checked for the word CAPCOM, not for the full notice text; the trial's pages were looked at in two pages' tops and footers, not page by page; the maintainer looked at shots of the d84a7eb1 draw, and the shots in this packet are of the 8c0b18a2 draw, whose only text changes are the clip captions and the web legend's 'exact image or sound clip'; the clips were not listened to after reduction; the intro's wording was checked by the maintainer's look, not against the design text by a tool; the gates and the trial ran on the Mac only; the size breakdown was measured on the d84a7eb1 draw, not re-measured on 8c0b18a2's; the comment's <CLOSE> commit does not exist yet.
Artifacts (read every one, in full):
  - build/agent213/t338/closure/awaiting_comment.md
  - build/agent213/t338/closure/ticket_row_338.tsv
  - build/agent213/t338/closure/issue_338.md
  - build/agent213/t338/closure/ledger_rows.txt
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
  - build/agent213/t338/closure/judged_old_tool.txt
  - build/agent213/t338/closure/test_proof_sheets_mac.log
  - build/agent213/t338/closure/trial2.sh
  - build/agent213/t338/closure/trial2.log
  - build/agent213/t338/closure/indep_web.py
  - build/agent213/t338/closure/web2_sizes.txt
  - build/agent213/t338/closure/titles_READING.md
  - build/agent213/t338/closure/titles_copyrights.png
  - build/agent213/t338/closure/index.html.png
  - build/agent213/t338/closure/g_audit_landing_sound.html.png
  - build/agent213/t338/closure/footer_index.png
  - build/agent213/t338/closure/footer_gate.png
  - build/agent213/t338/closure/shots3_bottoms.txt
  - DECISIONS_HISTORY.md.lines-9084-9100 (lines 9084-9100 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-212) — the proof sheets get a web build for the community: half-size WebP, ")
  - DECISIONS_HISTORY.md.lines-9112-9118 (lines 9112-9118 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #338: the clips are kept, reduced and described; the web build goes ")
  - DECISIONS_HISTORY.md.lines-9161-9167 (lines 9161-9167 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #335's dashboard sections and #338's web pages accepted on their loo")
  - DECISIONS_HISTORY.md.lines-9175-9180 (lines 9175-9180 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #338: the re-shot web pages accepted")
  - DECISIONS_HISTORY.md.lines-9182-9187 (lines 9182-9187 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-30 (14z-213) — #338: the credits footers accepted; a sound clip's caption no longer")
