THE PACKET

Decision kind: recommendation
Subject: #322 closed done: test_release_launcher_bat's fixture names its encoding, and the gate passes on ERIS at the fix (14z-208b)
Claim (the working agent's sentence): #322 can close done with the closing comment closing_322.md. Its done-when (issue322.md: the fixture names its encoding, and the gate PASSES on ERIS's MSYS2 with its first-found control firing, at the commit that lands the fix) is met by evidence322.txt: the diff of tests/test_release_launcher_bat.sh gives the fixture's manifest read, README write and README read encoding="utf-8" (the write also newline="\n"); on ERIS (MINGW64_NT) a git archive of the commit object 3c3b6130 (archive commit id checked in the log) prints PASS: test_release_launcher_bat, gate exit 0, with 8 CONTROL FIRED lines against 6 at a14e811e, the two new ones, emu-text-in-mister and megaman-note-in-fbneo, running through the fixture that failed; and the CONTROL=first-found mode run exits 1 with FAIL, as a mode must. The cause it fixes is measured in launcher_cause.txt (ERIS's MSYS2 Python 3.14.7 prefers cp1252; a default-encoded write turns the em dash at the fixture README's byte 16 into 0x97, the traceback's byte; a scratch copy with the encoding added PASSES). The ruling is the maintainer's own words in maintainer_words.txt ("Release a14e811e, fix after (Recommended)"). NOT TESTED: 3c3b6130 is a commit object, not the commit this closure lands in; the landing commit differs from it in record files only (the gate, tools/, release/ and tests/lib/ the same, checked when it is staged), and the fix is not re-run on Windows after the commit; nothing makes a gate's own inline Python name its encoding beyond this one gate (tests/test_host_text_opens.sh reads only the release tools; the lesson is a gotcha, not a gate); the Mac and Linux runs of the gate cannot see this defect (UTF-8 is their default).
Artifacts (read every one, in full):
  - build/agent208/close_rel/issue322.md
  - build/agent208/close_rel/evidence322.txt
  - build/agent208/close_rel/launcher_cause.txt
  - build/agent208/close_rel/maintainer_words.txt
  - build/agent208/close_rel/closing_322.md
