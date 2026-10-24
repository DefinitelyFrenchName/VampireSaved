THE PACKET

Decision kind: recommendation
Subject: #279, #280 and #281 closed done (14z-207, the release-only tickets lane P worked)
Claim (the working agent's sentence): #279, #280 and #281 can close done (closing_279.md, closing_280.md, closing_281.md) when this session's third commit lands, each by its own done-when (issue279.md, issue280.md, issue281.md). #279 ("the release builder's xdelta3 is pinned or checked ... and a Linux-built package passes the round-trip"): tools/package_release.py refuses an xdelta3 older than 3.2.0 (REPORT_P.md), and on PILOT, at commit object 7d38f1b5, a snapshot of the main working tree whose files equal the tree's (pilot_main/PROVENANCE.txt), with xdelta3 3.2.0 installed user-local as the maintainer ruled ("Install user-local (lane P's pick)", ruling_pilot_tools.txt), test_release_roundtrip PASSes with 10 of 10 controls: section 0 refuses apt's 3.0.11 and its control encoder-check-removed fires, the package built on PILOT round-trips, and rule 7 finds no verbatim run in 2,620,439 patch bytes (pilot_main/verdicts.txt, pilot_main/test_release_roundtrip.log, pilot_main/env.txt). #280 ("section 3b passes on Python ≥ 3.12"): on the same PILOT run (Python 3.12.3, Node v24.22.1, installed as ruled), test_applier_page PASSes with 6 of 6 controls and section 3b reads "container identical to this host's: True", its windows-host control firing (pilot_main/test_applier_page.log); on the Mac it PASSes with 6 of 6 (main_gates.txt). #281 ("a recorded limit of the tool that names this gate"): tools/trace_static_reads.py names test_applier_page_browser in TRACE_LIMITS with #281 and the measured reason (8 s traced at three virtual-time budgets, 19 s and PASS untraced, summary.txt), and on the main tree section 4b of test_trace_static_reads holds it, the gate PASSing with its controls (t281_main.log) and the limit-unnamed mode failing section 4b with exit 1 (t281_main_mode.log). Not tested: a whole release packaged on Linux end to end (the round-trip gate packages its own set); the Windows host for #279 and #280 (ERIS has no xdelta3 and no node); the PILOT run's emu/fbneo submodule was dirty ("1 modified tracked files", pilot_main/env.txt) as PILOT's clone always is, and whether either gate reads it was not checked; #281 leaves test_applier_page_browser's reads unscored by any trace, which the closing comment names. The three tickets were filed release-only ("All 4 have value but they also should be release-only", issue279.md); closing them before a release rests on their done-whens being met now, with no release step left in them.
Artifacts (read every one, in full):
  - build/agent207/P/close/issue279.md
  - build/agent207/P/close/issue280.md
  - build/agent207/P/close/issue281.md
  - build/agent207/P/close/REPORT_P.md
  - build/agent207/P/close/REPORT_P2.md
  - build/agent207/P/close/ruling_pilot_tools.txt
  - build/agent207/P/close/pilot_main/PROVENANCE.txt
  - build/agent207/P/close/pilot_main/env.txt
  - build/agent207/P/close/pilot_main/verdicts.txt
  - build/agent207/P/close/pilot_main/test_release_roundtrip.log
  - build/agent207/P/close/pilot_main/test_applier_page.log
  - build/agent207/P/close/main_gates.txt
  - build/agent207/P/close/summary.txt
  - build/agent207/P/close/t281_main.log
  - build/agent207/P/close/t281_main_mode.log
  - build/agent207/P/close/closing_279.md
  - build/agent207/P/close/closing_280.md
  - build/agent207/P/close/closing_281.md
