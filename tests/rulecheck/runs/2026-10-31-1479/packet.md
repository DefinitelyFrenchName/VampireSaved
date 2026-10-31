THE PACKET

Decision kind: recommendation
Subject: close #118 as done (14z-215): every mizuumi candidate has a measured verdict and no batch remains; six new gates PASS with all 50 controls HONOURED on the committed tree; the maintainer's sheet reads recorded verbatim
Claim (the working agent's sentence): CLAIM: close #118 as done (14z-215). The closing comment closing_comment_118.md and the row ticket_row_118.tsv state the resolution; the ticket is issue_118.md (its scope: the mizuumi player-struct candidates, "each adopted only once measured"). It rests on: mizuumi_candidates.tsv (the 89 candidates, verdicts derived from docs/game/atlas/ram.md by tools/mizuumi_candidates.py; no row NO ROW or NOT OBSERVED; the batch column "-" on every row) and histogram.txt (the verdict counts); test_mizuumi_candidates.log (the gate that holds the table equal to ram.md, PASS with its controls, on the tree that is committed); answers_118.md and ruling_118.txt (the maintainer's reads of every batch sheet, verbatim); identity.txt, the six gates' plain logs (each PASS) and modes.tsv (their 50 declared control modes, each HONOURED by tests/lib/classify.sh) on the combined tree, each gate's blob equal to the working tree's. NOT TESTED: the commit does not exist yet (the comment says 'the 14z-215 commit', no hash); "measured" for the 75 rows whose batch was "-" before this sitting rests on their ram.md rows and earlier sessions' gates (tests/audit_mizuumi_struct.sh, audit_mizuumi_rows_b.sh), not re-run here; the measurements behind each verdict live in ram.md and the gates, not in this packet (the ram.md diff is not an artifact); the items named under "Not done here" (Aulbath's and Lei-Lei's +0x14C projectiles, Oboro's +0x316, the 1P ladder readers, the stale +0x354 dereference) were not measured; the combined tree also carries #310 groups 1-4, #342 and #343, which these gates do not read.
Artifacts (read every one, in full):
  - build/agent215/closure118/closing_comment_118.md
  - build/agent215/closure118/ticket_row_118.tsv
  - build/agent215/closure118/issue_118.md
  - build/agent215/closure118/mizuumi_candidates.tsv
  - build/agent215/closure118/histogram.txt
  - build/agent215/closure118/test_mizuumi_candidates.log
  - build/agent215/closure118/answers_118.md
  - build/agent215/closure118/ruling_118.txt
  - build/agent215/closure118/identity.txt
  - build/agent215/closure118/modes.tsv
  - build/agent215/closure118/audit_lilith_gps_counter.plain.log
  - build/agent215/closure118/audit_bishamon_charge_316.plain.log
  - build/agent215/closure118/audit_mizuumi_finishes.plain.log
  - build/agent215/closure118/audit_anakaris_rows.plain.log
  - build/agent215/closure118/audit_mizuumi_rows_c.plain.log
  - build/agent215/closure118/audit_mizuumi_354_3a8.plain.log
