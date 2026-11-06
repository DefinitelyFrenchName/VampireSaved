THE PACKET

Decision kind: recommendation
Subject: close #354 done: the built-image dead-span reach gate tests/test_dead_span_reach.sh and its table (14z-221c)
Claim (the working agent's sentence): #354 can be closed done: tests/test_dead_span_reach.sh (test_dead_span_reach.sh) judges every row of tests/expected/dead_span_reach.tsv (dead_span_reach.tsv) on the five tracked builds and PASSes (plain.log: #294's span reached only by its allowed rows 02ADEC:13 and 02A646:8A on merged and donovan, DEAD on huitzil, pyron and stock, 5 judged pairs); its seven controls fire in-gate (plain.log) and are HONOURED as modes (modes_classified.txt, mode_*.log), each failing the span by its OWN rule — A, C, T, the new D (a planted PC-indexed byte read 0x40 below the span) and R (a planted lea), the allowed rows seen 0 times, and a broken fence (test_dead_span_reach.sh's fired_for, one arm per key; an earlier comment had swallowed the row-dropped arm, fixed); a missing build reads UNJUDGED in a mode and FAILs a plain run (mode_plant-jsr_deadinput.log, plain_deadinput.log), and an undeclared mode is REFUSED (mode_bogus.log). The tool (audit_dead_span.py.txt) carries rules A, C, T, D, R and L with the lea/pea match fixed, and accepts a base only for NAMED sites (--allow-pcidx BASE@SITE/SITE): a base read or loaded at any other site is a reference again (site_binding_check.txt: 0x24000 accepted for 0x433B8 alone reads R 1). #294's row accepts three references by those sites — the byte table 0x023F84 at its one reader 0x023F68, which executes 0 times over the 64-replay legacy corpus (dead_span_exec.log), the value 0x00024000 at its two loads 0x0433B8 and 0x077516 (16.16 speeds), and row 0x8A of the 8-byte record 0x02A646 — the same names tests/test_dead_span.sh checks by site on pristine vsavj (test_dead_span.sh, test_dead_span.log: PASS). The closing comment states that resolution (closing_comment_354.md). NOT TESTED: builds other than the five tracked; a read through a base more than 0x100 below a span, or one loaded from a data long; an address formed at run time from no constant (the tool's stated blind spot); the gate's controls beside other gates' controls (it is not on tests/controls_concurrent.txt, so its controls run one after another); #363's span, whose row is staged for the next freeze and judged there; the registration's bookkeeping gates (gate index, coverage, descriptions, must-fire census, annotations), which run in the close's clean checkout after the regeneration and are not shown here.
Artifacts (read every one, in full):
  - build/agent221c/rc354/audit_dead_span.py.txt
  - build/agent221c/rc354/closing_comment_354.md
  - build/agent221c/rc354/dead_span_exec.log
  - build/agent221c/rc354/dead_span_reach.tsv
  - build/agent221c/rc354/mode_bogus.log
  - build/agent221c/rc354/mode_fall-through.log
  - build/agent221c/rc354/mode_plant-jsr.log
  - build/agent221c/rc354/mode_plant-jsr_deadinput.log
  - build/agent221c/rc354/mode_plant-lea.log
  - build/agent221c/rc354/mode_plant-long.log
  - build/agent221c/rc354/mode_plant-pcidx.log
  - build/agent221c/rc354/mode_plant-table.log
  - build/agent221c/rc354/mode_row-dropped.log
  - build/agent221c/rc354/modes_classified.txt
  - build/agent221c/rc354/plain.log
  - build/agent221c/rc354/plain_deadinput.log
  - build/agent221c/rc354/site_binding_check.txt
  - build/agent221c/rc354/test_dead_span.log
  - build/agent221c/rc354/test_dead_span.sh
  - build/agent221c/rc354/test_dead_span_reach.sh
