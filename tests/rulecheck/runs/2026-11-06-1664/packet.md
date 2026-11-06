THE PACKET

Decision kind: recommendation
Subject: close #354 done: the built-image dead-span reach gate tests/test_dead_span_reach.sh and its table (14z-221c)
Claim (the working agent's sentence): #354 can be closed done: tests/test_dead_span_reach.sh (test_dead_span_reach.sh) judges every row of tests/expected/dead_span_reach.tsv (dead_span_reach.tsv) on the five tracked builds and PASSes (plain.log: #294's span reached only by its allowed rows 02ADEC:13 and 02A646:8A on merged and donovan, DEAD on huitzil, pyron and stock, 5 judged pairs); its ten controls fire in-gate (plain.log) and are HONOURED as modes (modes_classified.txt, mode_*.log), each failing the span by its OWN rule — A, C, T, the new D (a planted PC-indexed byte read 0x40 below the span) and R (a planted lea), base-reloaded (a planted second loader of the port row's table base reopens its row by rule T), base-reread (a planted second PC-indexed reader of the row's first accepted base, 0x23F84, reopens it by rule D), the allowed rows seen 0 times, a broken fence by a fall-through (nops over the instruction before the span), and a second entry (a planted long naming the span start - 2, so a second reached instruction ends at the span start and falls into it: the fence now judges EVERY reached instruction ending at the span start and refuses one straddling it, where it once judged only the first) (test_dead_span_reach.sh's fired_for, one arm per key; an earlier comment had swallowed the row-dropped arm, fixed); a missing build reads UNJUDGED in a mode and FAILs a plain run (mode_plant-jsr_deadinput.log, plain_deadinput.log), and an undeclared mode is REFUSED (mode_bogus.log). The tool (audit_dead_span.py.txt) carries rules A, C, T, D, R and L with the lea/pea match fixed, and accepts a base or an allowed row only for NAMED sites (--allow-pcidx BASE@SITE/SITE, --allow-table BASE:ROW@SITE/SITE; the table's rows are all bound: 02ADEC:13 at 0x2ADE4/0x2ADE8, 02A646:8A at 0x29DFA): a base read or loaded at any other site is a reference again (site_binding_check.txt, each block with its exact arguments: a planted second loader of 0x2A646 reads T 1, of 0x24000 or 0x23F84 R 1, a planted second PC-indexed reader of 0x23F84 D 1, and 0x24000 named at one of its two loads R 1). #294's row accepts three references by those sites — the byte table 0x023F84 at its one reader 0x023F68, which executes 0 times over the 64-replay legacy corpus (dead_span_exec.log), the value 0x00024000 at its two loads 0x0433B8 and 0x077516 (16.16 speeds), and row 0x8A of the 8-byte record 0x02A646 — the same names tests/test_dead_span.sh checks by site on pristine vsavj (test_dead_span.sh, test_dead_span.log: PASS). The closing comment states that resolution (closing_comment_354.md). NOT TESTED: the acceptances of 0x00024000 and of row 0x8A of 0x02A646 rest on READING the code, not on a measurement — 0x24000's two loads 0x0433B8 and 0x077516 were read as 16.16 speeds and no runtime tap shows the loaded value never used as an address into the span, and row 0x8A's odd target was read as ruling out a jump row, which does not rule out a byte read through that offset; the site binding means only these named loads and this named row reader are accepted, a new one anywhere is a reference again; the runtime bound behind 0x023F84's acceptance ran on PRISTINE vsavj (dead_span_exec.log, the 64-replay legacy corpus), not on the built images, where a tenant path reaching the reader 0x023F68 with a large +0x56 is not measured — the acceptance there rests on the named-site binding alone; builds other than the five tracked; code outside the scanned ranges (the gate's own stated blind spot: rules A, T, D and R read only 0-0x100000 and the manifests' spaces, so a reference from code in 0x100000-0x3EC720 is seen only if a long equals a span address, rule C); rule T's row extent, capped at 0x400 bytes and at the lowest forward target; a read through a base more than 0x100 below a span, or one loaded from a data long; an address formed at run time from no constant (the tool's stated blind spot); the gate's controls beside other gates' controls (it is not on tests/controls_concurrent.txt, so its controls run one after another); #363's span, whose row is staged for the next freeze and judged there; the registration's bookkeeping gates (gate index, coverage, descriptions, must-fire census, annotations), which run in the close's clean checkout after the regeneration and are not shown here.
Artifacts (read every one, in full):
  - build/agent221c/rc354/audit_dead_span.py.txt
  - build/agent221c/rc354/closing_comment_354.md
  - build/agent221c/rc354/dead_span_exec.log
  - build/agent221c/rc354/dead_span_reach.tsv
  - build/agent221c/rc354/mode_base-reloaded.log
  - build/agent221c/rc354/mode_base-reread.log
  - build/agent221c/rc354/mode_bogus.log
  - build/agent221c/rc354/mode_fall-through.log
  - build/agent221c/rc354/mode_plant-jsr.log
  - build/agent221c/rc354/mode_plant-jsr_deadinput.log
  - build/agent221c/rc354/mode_plant-lea.log
  - build/agent221c/rc354/mode_plant-long.log
  - build/agent221c/rc354/mode_plant-pcidx.log
  - build/agent221c/rc354/mode_plant-table.log
  - build/agent221c/rc354/mode_row-dropped.log
  - build/agent221c/rc354/mode_second-entry.log
  - build/agent221c/rc354/modes_classified.txt
  - build/agent221c/rc354/plain.log
  - build/agent221c/rc354/plain_deadinput.log
  - build/agent221c/rc354/reach_363_bound.txt
  - build/agent221c/rc354/site_binding_check.txt
  - build/agent221c/rc354/test_dead_span.log
  - build/agent221c/rc354/test_dead_span.sh
  - build/agent221c/rc354/test_dead_span_reach.sh
