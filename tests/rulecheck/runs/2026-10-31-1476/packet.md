THE PACKET

Decision kind: recommendation
Subject: close #342 and #343 as done (14z-215): $FF8120 is the winner's perfect flag (side by $FF8105); the time over ends the match (no round 2); KO rigs put the victim on its last bar; the three gates PASS with every control HONOURED on the committed tree
Claim (the working agent's sentence): CLAIM: close #342 and #343 as done (14z-215), together (one body of evidence: the same three gates). The closing comments closing_comment_342.md and closing_comment_343.md and the rows ticket_row_342.tsv and ticket_row_343.tsv state the resolutions; the tickets are issue_342.md and issue_343.md. It rests on: (1) THE MEASUREMENTS: ff8120_writes.txt (a PC-attributed write tap of $FF8120 on pristine vsavj over ten legs: 0xFF at 0x0098DC, 0x01 at 0x0098EC when the winner's white HP is below full, the side in $FF8105); round2_ours.out and round2_vanilla.out (the timeout ctl rig traced on our merged build and on pristine vsavj, identical: the round byte back to 0 at f4082 with no refill, match end 0xFF at f4934, the next match's refill at f4990); edge_hp_vs_lastbar.txt (each audit_edge_cases KO and double-KO leg run with HP-only pokes and with last-bar pokes, per-leg differences); maintainer_343.md (the maintainer's game fact, verbatim). (2) THE FIX: fix_342.diff, fix_343_gates.diff and fix_343_edge.diff (the three patches as merged). (3) THE RESULT ON THE TREE THAT IS COMMITTED: identity.txt (HEAD be2ecabc plus the working tree, a stash-create object, the three gates' blobs), the plain logs (each PASS) and modes.tsv (eleven control modes, each classified HONOURED by tests/lib/classify.sh). NOT TESTED: the commit itself does not exist yet — the comments say 'the 14z-215 commit that marks this row done', and its hash is not in them; the combined tree carries other changes (#310 groups 1-4, #118's promotion) that these three gates do not read but which were present when they ran; the native vsav2 check of Phobos's throw rests on the edge worker's runs (build/agent215/t343/edge/measure/native_vsav2/, not in this packet), and the natural two-down match on build/agent215/t343/downs_C (not in this packet); the 0x0098FC clear, a tenant's first down and the post-double-KO sequence are not covered (named in the comments); the poke read-back classes rest on the maintainer's ruling recorded in DECISIONS_HISTORY.md, not re-checked here.
Artifacts (read every one, in full):
  - build/agent215/closure342_343/closing_comment_342.md
  - build/agent215/closure342_343/closing_comment_343.md
  - build/agent215/closure342_343/ticket_row_342.tsv
  - build/agent215/closure342_343/ticket_row_343.tsv
  - build/agent215/closure342_343/issue_342.md
  - build/agent215/closure342_343/issue_343.md
  - build/agent215/closure342_343/ff8120_writes.txt
  - build/agent215/closure342_343/round2_ours.out
  - build/agent215/closure342_343/round2_vanilla.out
  - build/agent215/closure342_343/edge_hp_vs_lastbar.txt
  - build/agent215/closure342_343/maintainer_343.md
  - build/agent215/closure342_343/identity.txt
  - build/agent215/closure342_343/modes.tsv
  - build/agent215/closure342_343/audit_tenant_timeout.plain.log
  - build/agent215/closure342_343/audit_tenant_downwin.plain.log
  - build/agent215/closure342_343/audit_edge_cases.plain.log
