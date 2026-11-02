THE PACKET

Decision kind: recommendation
Subject: #338 closed done: the M24 release's proof sheets drawn with web and published at alexrichard.org/vs-proof-sheets/ (14z-217), after run 2026-11-02-1567
Claim (the working agent's sentence): #338 can close done with the closing comment closing_338.md. Its condition (issue338.md, the 14z-213 comment's 'What closes it': at the next tagged release, the release commit's local run is drawn with web and published with publish_sheets.sh) is met as follows. The local run build/sheets/be40e6f3f58c is of the release commit: its meta.json reads commit be40e6f3, 58 gates, exit codes [0], the 8 verdicts not starting with PASS each a pass in its gate's own wording, and its provenance record says it was built in a clean checkout of be40e6f3 with each of the five builds equal to the commit's frozen reference (closures_evidence.txt). The web build was drawn from it with --release freeze/merged-m24 (sheets_web.log: 102 pages, 23174 tiles, 152 clips, 0 problems), webcheck --run on that run reads PASS with 0 problems (sheets_webcheck.log), and the index carries the builds sentence counted from the run and the tag freeze/merged-m24 (closures_evidence.txt). It was published not by publish_sheets.sh, whose --dry-run ran webcheck (PASS) and then hung at the ssh password prompt (the maintainer's words, maintainer_words.txt; the mechanism, timeout without --foreground, reproduced under a pty: findings.md item 5; filed as #350, OPEN, new_issue_publish_hang.md), but by the maintainer by hand with the script's own rsync line minus timeout ('manual upload done successfully', maintainer_words.txt). The published copy was then checked from the site by served_check.sh: each of 133 files (index, css, all 101 gate pages, 30 pictures and clips by a seeded shuffle) fetched from its https://alexrichard.org/vs-proof-sheets/ URL with http 200 and equal by sha256 to the local build's file, and its three must-fail controls (a byte flipped in the local copy, the wrong served file, a missing path answering 404) each reading DIFFERS (served_check.txt). NOT TESTED: the other pictures and clips were not compared one by one; the pages were not re-rendered under the site's style-src 'self' policy at this release (done on the 14z-213 trial, issue338.md; webcheck refuses inline style and script); publish_sheets.sh's real upload was never attempted (the hang was in its dry run) and its upload path stays broken until #350; the upload's command line as the maintainer typed it is known only from their words and the line suggested to them, not from a log; the 30-file sample's seed is fixed, not independently drawn; the clean-checkout provenance is the run's own record (tools/proof_sheets.py), not an independent check.
Artifacts (read every one, in full):
  - build/agent217/release/close/closing_338.md
  - build/agent217/release/close/issue338.md
  - build/agent217/release/close/maintainer_words.txt
  - build/agent217/release/closures_evidence.txt
  - build/agent217/release/sheets_web.log
  - build/agent217/release/sheets_webcheck.log
  - build/agent217/release/close/served_check.sh
  - build/agent217/release/close/served_check.txt
  - build/agent217/release/findings.md
  - tools/publish_sheets.sh
  - build/agent217/release/close/new_issue_publish_hang.md
