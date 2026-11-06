THE PACKET

Decision kind: recommendation
Subject: close #359 done: the split signal traps and tests/test_signal_traps.sh (14z-221c)
Claim (the working agent's sentence): #359 can be closed done: at a152efa7, 228 traps in 221 shell files were `trap '<cleanup>' EXIT INT TERM` with no exit (census_before.txt, every trap command read by tools/tmp_hygiene.py's reader, 0 unread), a form whose action runs on TERM and then RESUMES the script; 225 of them in 218 files were rewritten to `trap '<cleanup>' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM`, the three left being frozen rule-checker fixture text under tests/rulecheck/ (census_after.txt: 3, all fixtures); on the merged Mac tree the fixer re-ran over the same 225 traps in 218 files and the gate's census names 0 of 589 shell files plus the three new untracked gates (merge_check.txt, merged_census.txt). The new gate tests/test_signal_traps.sh (test_signal_traps.sh, tools/signal_traps.py as signal_traps.py.txt) refuses any trap on INT, TERM, HUP or QUIT whose action never exits, exits 0, or cannot be read; it re-measures its premise on sh, bash and dash each run (the old form resumes after TERM; the accepted form exits 143 with its cleanup run once; a normal exit 0/1/3 keeps its status); it PASSes on the merged Mac tree (mac_plain.log), FAILs on the a152efa7 tree with 225 named (gate_on_base.log), and its control resuming-trap is HONOURED as a mode with an undeclared mode REFUSED (mac_mode_classified.txt). TERM proof: under timeout, test_tmp_hygiene and test_docshape printed 18-27 lines after TERM before the fix and 0 after, on the Mac and on PILOT's dash, and test_hitbox_encoding's two false CONTROL DEAD lines after TERM are gone (term_mac_rows.tsv, pilot_term_rows.txt). Normal path on PILOT: 119 changed static-tier gates run plain before and after, 118 with the same exit and verdict, the one other being test_controls_concurrent, red from its own stale rows before the re-trace (pilot_plain_compare.txt); PILOT's write traces at the worker's scratch a10866d0 read 72 static gates and 36 emulator gates SAFE, none SHARED or HOLLOW (pilot_overlap_static.txt, pilot_overlap_emu.txt, pilot_summary.txt). NOT TESTED: the PILOT runs were on the worker's scratch tree a10866d0, not the merged tree, whose 8 differing files differ by this sitting's other edits (merge_check.txt shows the fixer's change on each is the trap line alone); test_signal_traps.sh gained, after PILOT's runs, a MEASURE-only line per shell for an EXIT-only trap under TERM (never asserted; it reads cleanup 0 times under dash, 1 under sh and bash, mac_plain.log) — that EXIT-only finding is outside #359 and not fixed (about 277 files carry EXIT-only traps); an INT delivered to a background job, which POSIX ignores at entry, so only TERM is shown; the five concurrent-list rows this sitting's other edits staled are re-traced separately, not here; the bookkeeping gates (gate index, coverage, descriptions, must-fire census) run at the close's clean checkout.
Artifacts (read every one, in full):
  - build/agent221c/rc359/census_after.txt
  - build/agent221c/rc359/census_before.txt
  - build/agent221c/rc359/closing_comment_359.md
  - build/agent221c/rc359/exit_only_probe_mac.txt
  - build/agent221c/rc359/gate_on_base.log
  - build/agent221c/rc359/mac_mode_bogus.log
  - build/agent221c/rc359/mac_mode_classified.txt
  - build/agent221c/rc359/mac_mode_resuming-trap.log
  - build/agent221c/rc359/mac_plain.log
  - build/agent221c/rc359/merge_check.txt
  - build/agent221c/rc359/merged_census.txt
  - build/agent221c/rc359/pilot_head_base.txt
  - build/agent221c/rc359/pilot_head_fixed.txt
  - build/agent221c/rc359/pilot_overlap_emu.txt
  - build/agent221c/rc359/pilot_overlap_static.txt
  - build/agent221c/rc359/pilot_plain_compare.txt
  - build/agent221c/rc359/pilot_summary.txt
  - build/agent221c/rc359/pilot_term_rows.txt
  - build/agent221c/rc359/signal_traps.py.txt
  - build/agent221c/rc359/syntax_mac.txt
  - build/agent221c/rc359/term_mac_rows.tsv
  - build/agent221c/rc359/test_signal_traps.sh
