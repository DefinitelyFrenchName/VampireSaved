THE PACKET

Decision kind: recommendation
Subject: close #354 done: the built-image dead-span reach gate tests/test_dead_span_reach.sh and its table (14z-221c)
Claim (the working agent's sentence): #354 can be closed done: tests/test_dead_span_reach.sh (test_dead_span_reach.sh) judges every row of tests/expected/dead_span_reach.tsv (dead_span_reach.tsv) on the five tracked builds and PASSes (plain.log: #294's span reached only by row 02ADEC:13 with row 02A646:8A accepted, on merged and donovan, DEAD on huitzil, pyron and stock, 5 judged pairs, five controls fired in-gate); its five controls are HONOURED as modes (modes_classified.txt, mode_*.log), a missing build reads UNJUDGED in a mode and FAILs a plain run (mode_plant-jsr_deadinput.log, plain_deadinput.log), and an undeclared mode is REFUSED (mode_bogus.log); the tool it runs (audit_dead_span.py.txt) carries rules A, C, T, D, R and L with the lea/pea match fixed, and #294's row accepts the three references the fixed tool found on its span (the byte table 0x023F84 at its one reader 0x023F68, the value 0x00024000, row 0x8A of the record 0x02A646) by the same names tests/test_dead_span.sh checks by site; the registration and bookkeeping gates the worker ran PASSed (bookkeeping_summary.txt, with its noted red test_sheet_census not from this change). The closing comment states that resolution (closing_comment_354.md). NOT TESTED: builds other than the five tracked; a read through a base more than 0x100 below a span, or one loaded from a data long; an address formed at run time from no constant (the tool's stated blind spot); the gate's controls beside other gates' controls (not on tests/controls_concurrent.txt, so they run one after another); #363's span, whose row is staged for the next freeze and judged there; the bookkeeping gates after the merge with rules D/R, re-run in the close's clean checkout.
Artifacts (read every one, in full):
  - build/agent221c/rc354/audit_dead_span.py.txt
  - build/agent221c/rc354/bookkeeping_summary.txt
  - build/agent221c/rc354/closing_comment_354.md
  - build/agent221c/rc354/dead_span_reach.tsv
  - build/agent221c/rc354/mode_bogus.log
  - build/agent221c/rc354/mode_fall-through.log
  - build/agent221c/rc354/mode_plant-jsr.log
  - build/agent221c/rc354/mode_plant-jsr_deadinput.log
  - build/agent221c/rc354/mode_plant-long.log
  - build/agent221c/rc354/mode_plant-table.log
  - build/agent221c/rc354/mode_row-dropped.log
  - build/agent221c/rc354/modes_classified.txt
  - build/agent221c/rc354/plain.log
  - build/agent221c/rc354/plain_deadinput.log
  - build/agent221c/rc354/test_dead_span_reach.sh
