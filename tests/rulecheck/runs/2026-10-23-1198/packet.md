THE PACKET

Decision kind: recommendation
Subject: #308 closed done: host-encoded text in the release generator and test_readme_recording (fork G, 14z-207)
Claim (the working agent's sentence): #308 can close done when this session's commit lands (closing_comment.md): its to-dos (issue308.md) are met by fork G's change, whose three files in the main tree equal its commit 9141f4f8 (code.patch, the c494fac2..9141f4f8 diff of those files; REPORT.md). The generator's text opens name encoding and newline and PLAY.bat is binary; the gate writes argv.txt and readme.env with LF; rec_end lets a missing rec.log reach the FAIL line; controls unencoded-launcher, crlf-argv and rec-log-missing were added (code.patch). On ERIS (eris/verdicts.txt: MINGW64, Python 3.14.7, preferred encoding cp1252, utf8 mode 0, PYTHONUTF8 unset, a git archive of 9141f4f8) the gate PASSes with 5 of 5 controls fired using the release cps2.exe, whose sha256 equals BINARY.txt's row, and every mode exits 1 HONOURED; the files it wrote have CR=0 and valid UTF-8 except PLAY.bat (eris_bytes.txt). On the Mac it PASSes (mac/gate_v2.log) with all five modes HONOURED (mac/modes_v2.txt) and the three sibling release gates PASS (mac/siblings.txt). Not tested: a source-built MAME on ERIS (the as-designed run SKIPs, eris/verdicts.txt), so the Windows PASS rests on the release binary; the gate on this session's main tree (it is an emulator-tier gate, not run by the commit's static tier; the files are equal to the fork's); the host-text guard covers builtins.open only, not io.open or pathlib (REPORT.md); MAME's own rec.out on ERIS carried a CRC mismatch line that was not traced (REPORT.md); tools/gen_applier_page.py keeps the defect, filed as #314.
Artifacts (read every one, in full):
  - build/agent207/t308/closing_comment.md
  - build/agent207/t308/issue308.md
  - build/agent207/t308/REPORT.md
  - build/agent207/t308/code.patch
  - build/agent207/t308/eris/verdicts.txt
  - build/agent207/t308/eris_bytes.txt
  - build/agent207/t308/mac/gate_v2.log
  - build/agent207/t308/mac/modes_v2.txt
  - build/agent207/t308/mac/siblings.txt
