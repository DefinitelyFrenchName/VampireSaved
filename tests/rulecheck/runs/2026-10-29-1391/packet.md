THE PACKET

Decision kind: recommendation
Subject: close #336 as done (14z-212), after runs 2026-10-29-1388 and -1390: test_static_runner section 32 counts dash's write error (I/O error) as well as bash's (Broken pipe), PASS on PILOT in a fresh clone and on the Mac, the traced script shown
Claim (the working agent's sentence): CLAIM: close #336 as done (14z-212): the closing comment closing_comment.md and the row ticket_row_336.tsv state the resolution. tests/test_static_runner.sh section 32 measured #327's premise (a builtin printf of ~1 MB into `grep -q` with SIGPIPE ignored prints the shell's write error; into `grep >/dev/null` it does not) by counting stderr lines holding `Broken pipe`, bash's wording; dash, /bin/sh on every Linux host, words it `I/O error`, so the count read 0 there and the section FAILed on unchanged code. fix.diff makes the count take either wording (and its comment name both); nothing else in the gate changes. It rests on:
1. THE WORDINGS: wording.py, run on both hosts (wording_mac.txt, wording_pilot.txt — each with its host and what /bin/sh resolves to): over 5 runs of the old form per shell, bash (and the Mac's /bin/sh) prints `write error: Broken pipe` and dash (PILOT's /bin/sh, and the Mac's /bin/dash) `printf: I/O error`; the OLD count reads 0 under dash and 5 under bash, the NEW count 5 under each.
2. THE GATE ON BOTH HOSTS: test_static_runner_pilot3.log (PILOT, run by pilot_tsr2.sh in a clone it made fresh for that run alone — rm -rf, git clone --no-checkout, checkout 94323897, nothing else run in it; its header: host, /bin/sh -> /usr/bin/dash, HEAD 94323897, the script's blob c909cf06 at HEAD and on disk, git status --porcelain BEFORE the gate 0 lines tracked and untracked, and its footer the tracked status AFTER, 0 lines; test_static_runner_pilot2.log, an earlier PASS in ~/t212_tr7, a clone a re-trace had run in first, is kept as output only) and test_static_runner_mac2.log (the Mac, its header: bash as /bin/sh, the working tree, the same blob): PASS on both, section 32 reading "the premise holds — the old form printed 5 write-error line(s) in 5 runs". (test_static_runner_mac.log and test_static_runner_pilot.log, the first runs, are byte-identical and carry no host line, so they show the output only; the header logs are the evidence. The Mac's run is on the session's working tree, which carries the sitting's other uncommitted edits.)
3. THE RE-TRACE (the #315 method): pilot_t212r6_static_overlap.txt / _classes.tsv (PILOT, HEAD ad206269 per pilot_head6.txt, /bin/sh -> dash): the 26 controls of the fixed script, SAFE, every run HONOURED. Which script was traced: pilot_retrace6.sh cloned ~/t212_tr4 fresh at ad206269 and traced there; pilot_r6_blob.txt shows tests/test_static_runner.sh in that clone is blob c909cf06 both at HEAD and on disk, tests/ unmodified; and the gate's own run there before the trace (pilot_t212r6_static_runner.log) PASSed with section 32's premise holding — on dash, which the unfixed script FAILs; tests/controls_concurrent.txt row 125 (blob c909cf06, pilot:ad206269) and its TRACES line 30.
4. THE SEARCH: other_readers.txt — no other script in tests/ or tools/ (*.sh, *.py) reads a shell's write-error text; its one hit, "second rewrite errored", only contains the letters.
5. THE GATE'S SECTIONS 32-33: tests/test_static_runner.sh lines 1217-1262. 6. THE RECORD: docs/platform/gotchas.md.lines-3542-3552 "A SHELL'S WRITE-ERROR TEXT IS ITS OWN".
NOT TESTED: shells other than bash and dash (zsh, busybox sh, ksh) — their wording was not measured, and a host whose /bin/sh words it otherwise would FAIL section 32 again (the FAIL names the counts, so it would be seen, not hidden); a locale that translates the shells' messages (PILOT's gate run set LC_ALL=C.UTF-8 per pilot_tsr.sh, the other runs kept the host's default; the messages captured in wording_mac.txt and wording_pilot.txt are English, and a translated one would not match); the new form's count of 0 is measured only inside the gate (section 32's own check), not by wording.py; scripts outside tests/ and tools/, and file types other than .sh and .py, were not searched.
Artifacts (read every one, in full):
  - build/agent212/t336/closure/closing_comment.md
  - build/agent212/t336/closure/ticket_row_336.tsv
  - build/agent212/t336/closure/fix.diff
  - build/agent212/t336/closure/wording.py
  - build/agent212/t336/closure/wording_mac.txt
  - build/agent212/t336/closure/wording_pilot.txt
  - build/agent212/t336/closure/pilot_tsr2.sh
  - build/agent212/t336/closure/test_static_runner_pilot3.log
  - build/agent212/t336/closure/test_static_runner_pilot2.log
  - build/agent212/t336/closure/pilot_tsr.sh
  - build/agent212/t336/closure/test_static_runner_mac2.log
  - build/agent212/t336/closure/test_static_runner_mac.log
  - build/agent212/t336/closure/test_static_runner_pilot.log
  - build/agent212/t336/closure/pilot_head6.txt
  - build/agent212/t336/closure/pilot_retrace6.sh
  - build/agent212/t336/closure/pilot_r6_blob.txt
  - build/agent212/t336/closure/pilot_t212r6_static_runner.log
  - build/agent212/t336/closure/pilot_t212r6_static_overlap.txt
  - build/agent212/t336/closure/pilot_t212r6_static_classes.tsv
  - build/agent212/t336/closure/other_readers.txt
  - build/agent212/t336/closure/verdict_a_1388.txt
  - build/agent212/t336/closure/verdict_b_1390.txt
  - tests/controls_concurrent.txt
  - docs/platform/gotchas.md.lines-3542-3552 (lines 3542-3552 of docs/platform/gotchas.md)
  - tests/test_static_runner.sh.lines-1217-1262 (lines 1217-1262 of tests/test_static_runner.sh)
