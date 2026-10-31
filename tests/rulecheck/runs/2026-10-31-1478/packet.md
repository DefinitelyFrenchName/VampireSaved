THE PACKET

Decision kind: recommendation
Subject: close #342 and #343 as done (14z-215): $FF8120 is the winner's perfect flag (side by $FF8105); the time over ends the match; KO rigs put the victim on its last bar; 14z-104's Phobos claim retracted on an independent leg and the maintainer's read; the three gates PASS with every control HONOURED on the committed tree
Claim (the working agent's sentence): CLAIM: close #342 and #343 as done (14z-215), together (one body of evidence: the same three gates), after runs 2026-10-31-1476 (withdrawn unspawned) and -1477. The closing comments closing_comment_342.md and closing_comment_343.md and the rows ticket_row_342.tsv and ticket_row_343.tsv state the resolutions; the tickets are issue_342.md and issue_343.md. It rests on: (1) THE MEASUREMENTS: ff8120_writes.txt (a PC-attributed write tap of $FF8120 on pristine vsavj over seven legs: 0xFF at 0x0098DC, then 0x01 at 0x0098EC when the winner was hurt; the side in $FF8105); round2_ours.out and round2_vanilla.out (the timeout ctl rig on our build and pristine vsavj, identical: the round byte back to 0 at f4082 with no refill, match end 0xFF at f4934, the next match's refill at f4990); edge_hp_vs_lastbar.txt (each audit_edge_cases KO and double-KO leg with HP-only pokes and with last-bar pokes); phobos_legB.txt (the independent leg on our build and native vsav2: the game writes Victor's first down itself from a poked 145 — +0x138 144->0 at f3012, bat 1->0 at f3013 — then only his HP words are lowered to 2 at f3050 and Phobos's throw KOs him: bat 0->0xFF and $FF810E 0->1 at f3265 on ours, f3243 on native); phobos_1_hp_only.png and phobos_3_throw_kills.png (two of the three capture pages shown to the maintainer); maintainer_343.md and rulings_14z215.txt (the maintainer's own words: the game fact, the poke read-back rulings, and "yes" on the Phobos pages). (2) THE FIX: fix_342_core.diff, fix_343_gates_core.diff, fix_343_edge_core.diff (the patches cut to the three gates, ram.md, gotchas.md and poke_readback.tsv) and gate_changes_since_patches.diff (the only later gate changes: one header comment line in downwin, one in edge; timeout unchanged); poke_readback_rows.tsv (the three gates' current rows, classed). (3) THE RESULT ON THE TREE THAT IS COMMITTED: final/identity.txt (HEAD be2ecabc plus a git stash create snapshot of the working tree, the three gates' blobs), final/*.plain.log (each opening with the blob it ran, each PASS) and final/modes.tsv (eleven control modes with their blobs, each HONOURED by tests/lib/classify.sh). NOT TESTED: the commit does not exist yet (the comments say 'the 14z-215 commit that marks this row done', no hash); the combined tree carries #310 groups 1-4 and #118's promotion, which these gates do not read; no leg separates white HP from real HP (the static read names +0x52; said in the #342 comment); native vsav2's leg-B throw-damage hit record differs from native's poked-leg record (0x0C504A against 0x0C50EA, unexplained, both the same throw by its grab record); the 0x0098FC clear, a tenant's first down and the post-double-KO sequence are not covered (named in the comments).
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
  - build/agent215/closure342_343/phobos_legB.txt
  - build/agent215/closure342_343/phobos_1_hp_only.png
  - build/agent215/closure342_343/phobos_3_throw_kills.png
  - build/agent215/closure342_343/maintainer_343.md
  - build/agent215/closure342_343/rulings_14z215.txt
  - build/agent215/closure342_343/poke_readback_rows.tsv
  - build/agent215/closure342_343/gate_changes_since_patches.diff
  - build/agent215/closure342_343/final/identity.txt
  - build/agent215/closure342_343/final/modes.tsv
  - build/agent215/closure342_343/final/audit_tenant_timeout.plain.log
  - build/agent215/closure342_343/final/audit_tenant_downwin.plain.log
  - build/agent215/closure342_343/final/audit_edge_cases.plain.log
  - build/agent215/closure342_343/fix_342_core.diff.lines-1-390 (lines 1-390 of build/agent215/closure342_343/fix_342_core.diff)
  - build/agent215/closure342_343/fix_342_core.diff.lines-391-776 (lines 391-776 of build/agent215/closure342_343/fix_342_core.diff)
  - build/agent215/closure342_343/fix_343_gates_core.diff.lines-1-300 (lines 1-300 of build/agent215/closure342_343/fix_343_gates_core.diff)
  - build/agent215/closure342_343/fix_343_gates_core.diff.lines-301-592 (lines 301-592 of build/agent215/closure342_343/fix_343_gates_core.diff)
  - build/agent215/closure342_343/fix_343_edge_core.diff
