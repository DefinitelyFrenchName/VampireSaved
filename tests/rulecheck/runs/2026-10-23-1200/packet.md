THE PACKET

Decision kind: recommendation
Subject: #308 closed done (14z-207), after run 2026-10-23-1198
Claim (the working agent's sentence): #308 can close done when this session's commit lands (closing_comment.md), after run 2026-10-23-1198: its to-dos (issue308.md) are met. The main tree's three files equal fork G's 9141f4f8 (main_vs_9141f4f8.diff is empty; code.patch is c494fac2..9141f4f8 of those files): the generator's text opens name encoding and newline and PLAY.bat is binary; the gate writes argv.txt and readme.env with LF; rec_end lets a missing rec.log reach the FAIL line; test_readme_recording gains controls unencoded-launcher, crlf-argv and rec-log-missing on the render path it runs. Every text open in the two generator files is now held by a new static gate, tests/test_host_text_opens.sh (static/test_host_text_opens.sh.txt), which PASSes over 15 text opens with controls unencoded-open and newline-dropped firing and both modes exiting 1 (static/gate.log, static/modes.txt), with the bookkeeping gates PASS in a clean checkout of the tracked tree (static/book_clean_checkout.txt). On ERIS (eris/verdicts.txt: MINGW64, Python 3.14.7, cp1252, utf8 mode 0, PYTHONUTF8 unset, a git archive of 9141f4f8) test_readme_recording PASSes with 5 of 5 controls using the release cps2.exe, whose sha256 equals BINARY.txt's row, and every mode exits 1 HONOURED; the files it wrote have CR=0 except PLAY.bat, with README.md, PLAY.command and EMULATOR.md also valid UTF-8 (eris_bytes.txt). On the Mac it PASSes (mac/gate_v2.log), all five modes HONOURED (mac/modes_v2.txt), the three sibling release gates PASS (mac/siblings.txt). Not tested: a source-built MAME on ERIS (the as-designed run SKIPs), so the Windows PASS rests on the release binary; UTF-8 validity of argv.txt and readme.env (CR only); manifest.json's bytes on ERIS say nothing of the generator, which the gate copies rather than renders; test_readme_recording on this session's main tree (an emulator-tier gate; its files equal the fork's); the static gate reads builtin open() and pathlib read_text/write_text only, not io.open, codecs.open or a mode held in a variable (which it names as a failure); MAME's rec.out CRC mismatch line on ERIS was not traced; tools/gen_applier_page.py keeps the defect, filed as #314.
Artifacts (read every one, in full):
  - build/agent207/t308/closing_comment.md
  - build/agent207/t308/issue308.md
  - build/agent207/t308/REPORT.md
  - build/agent207/t308/code.patch
  - build/agent207/t308/main_vs_9141f4f8.diff
  - build/agent207/t308/static/test_host_text_opens.sh.txt
  - build/agent207/t308/static/gate.log
  - build/agent207/t308/static/modes.txt
  - build/agent207/t308/static/book_clean_checkout.txt
  - build/agent207/t308/eris/verdicts.txt
  - build/agent207/t308/eris_bytes.txt
  - build/agent207/t308/mac/gate_v2.log
  - build/agent207/t308/mac/modes_v2.txt
  - build/agent207/t308/mac/siblings.txt
