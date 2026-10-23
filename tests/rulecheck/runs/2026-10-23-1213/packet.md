THE PACKET

Decision kind: recommendation
Subject: #314 closed done (fork Q, 14z-207), after run 2026-10-23-1212
Claim (the working agent's sentence): #314 can close done when this session's second commit lands (closing_comment.md), after run 2026-10-23-1212: its three to-dos (issue314.md) are met by fork Q's commit faef92f4, whose six changed files equal the main tree's byte for byte (main_vs_faef92f4.txt; REPORT.md). The generator's text opens name their encoding and its page write its newline, and apply_release.py's manifest read names its encoding (forkQ_2a155ba3..faef92f4.patch); before the fix, the generator stopped on ERIS with UnicodeEncodeError at its page write (eris/logs/gen_old_unguarded.out); the guard refuses c494fac2's generator and passes the fixed one, whose page has 0 CR and equals the shipped page (separating.txt). The render runs under the shared guard in test_applier_page with the new control unencoded-page, and the static gate reads the four release text tools: on the main tree (each log's header naming the tree) test_applier_page PASSes with 6 controls fired and test_static_confirm with 44 (main2/test_applier_page.log, main2/test_static_confirm.log), and test_host_text_opens with 4, its new control applier-unencoded perturbing gen_applier_page.py's own page write, every mode exiting 1 (static2/gate.log, static2/modes.txt; the same check names apply_release.py:211 in c494fac2's file, host_text_opens_old.txt), and test_readme_recording, which now imports the shared guard, PASSes with 5 (readme_main.log). On ERIS, under the guard, the three platform pages have CR=0, are valid UTF-8 and equal the Mac's shipped pages (eris/logs/a_pages.txt, its header naming host, tree and command), and run plainly as the packaging does (no guard, cp1252 stdout, PYTHONUTF8 unset) the generator writes the same three pages, exit 0, CR=0, byte-identical to the shipped ones (eris_unguarded.txt); test_readme_recording PASSes there as designed with a source-built MAME, 5 of 5 controls (eris/logs/e_readme_as_designed.log). Not tested: test_applier_page on ERIS (no node there; it SKIPs, eris/logs/b_applier_page.log); a Windows packaging run (ERIS's MSYS2 has no xdelta3, and the pipeline packages on the Mac, REPORT.md); the guard covers builtins.open only, and the static gate builtin open() and pathlib read_text/write_text only; MAME's rec.out CRC-mismatch line on ERIS was not traced; the bookkeeping regenerated pages land in the same commit and are checked by its tier.
Artifacts (read every one, in full):
  - build/agent207/Q/closing_comment.md
  - build/agent207/Q/issue314.md
  - build/agent207/Q/REPORT.md
  - build/agent207/Q/main_vs_faef92f4.txt
  - build/agent207/Q/forkQ_2a155ba3..faef92f4.patch
  - build/agent207/Q/eris/logs/gen_old_unguarded.out
  - build/agent207/Q/separating.txt
  - build/agent207/Q/main2/test_applier_page.log
  - build/agent207/Q/main2/test_static_confirm.log
  - build/agent207/Q/static2/gate.log
  - build/agent207/Q/static2/modes.txt
  - build/agent207/Q/host_text_opens_old.txt
  - build/agent207/Q/readme_main.log
  - build/agent207/Q/eris/logs/a_pages.txt
  - build/agent207/Q/eris_unguarded.txt
  - build/agent207/Q/eris/logs/e_readme_as_designed.log
  - build/agent207/Q/eris/logs/b_applier_page.log
