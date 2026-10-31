THE PACKET

Decision kind: recommendation
Subject: recommend poke read-back classes for the 24 new findings under the 14z-181 'asserts a change' rule, re-derived mechanically from a per-read table, with re-worded notes for six ruled rows
Claim (the working agent's sentence): CLAIM (a recommendation to put to the maintainer, proposal.md), after runs 2026-10-31-1471, -1473 and -1474: for the 24 UNCLASSIFIED poke read-back rows of tests/expected/poke_readback.tsv (rows 121-144, from #342/#343/#118's gate changes) recommend the class proposal.md gives each (12 OBSERVES, 9 READS-BACK, 2 CROSS-LEG, 1 CONTROL-PLANT) under the 14z-181 rule as worded in the session proposal the maintainer approved (ruling_14z181.txt: "OBSERVES wherever the gate asserts a CHANGE after the pin, READS-BACK wherever it asserts the pinned value itself"; the approval "The 73 poke read-back rulings are in front of you -> I agree with the proposal"); and re-worded notes for the ruled rows 36, 37, 38, 48, 49 and 50 (class unchanged; row 36 derives OBSERVES under the rule since #343, flagged as the maintainer's re-ruling). It rests on: reads.tsv (202 read sites over 30 findings; per judging read on a poking leg an asserts_change column — YES only where the check would FAIL on the poked value, with the condition quoted in change_condition); check_reads.py/.out (every cited line, read_code, key token and condition quote re-opened; every keyed line of each checker cited: 0 failures) and its control check_reads_control.out (a moved line, dropped rows: exit 1); derive_classes.py/.out (every class re-derived from reads.tsv's columns alone under the rule and compared with proposal.md: 24 compared, 0 mismatches) and its control derive_classes_control.out (one YES flipped to NO: mismatch, exit 1); check_proposal_quotes.py/.out (33 code quotes in proposal.md re-opened: 0 failures) and its control (one quote altered: exit 1); and the cited maintainer rulings in decisions_cited.txt. NOT TESTED: the asserts_change and value_source judgements are one worker's reading of the code — derive_classes.py checks that each class follows from the columns, not that each column is right; four read sites (audit_tenant_downwin.sh:244, :280 and audit_tenant_timeout.sh:197 on p1hurt, :233 on inv and p1hurt) are UNMEASURED by trace on their exact legs (near rigs only) and settle as asserts_change NO by reading, so no class depends on a trace there; rows 122 and 136 have no maintainer precedent (proposal.md says so); the census does not derive pokes whose FIELDS are built at runtime (proposal.md's blind spots, not rows).
Artifacts (read every one, in full):
  - build/agent215/pr/proposal.md
  - build/agent215/pr/reads.tsv.lines-1-70 (lines 1-70 of build/agent215/pr/reads.tsv)
  - build/agent215/pr/reads.tsv.lines-71-140 (lines 71-140 of build/agent215/pr/reads.tsv)
  - build/agent215/pr/reads.tsv.lines-141-204 (lines 141-204 of build/agent215/pr/reads.tsv)
  - build/agent215/pr/derive_classes.py
  - build/agent215/pr/derive_classes.out
  - build/agent215/pr/derive_classes_control.out
  - build/agent215/pr/check_reads.py
  - build/agent215/pr/check_reads.out
  - build/agent215/pr/check_reads_control.out
  - build/agent215/pr/check_proposal_quotes.py
  - build/agent215/pr/check_proposal_quotes.out
  - build/agent215/pr/check_proposal_quotes_control.out
  - build/agent215/pr/ruling_14z181.txt
  - build/agent215/pr/decisions_cited.txt
