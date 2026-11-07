THE PACKET

Decision kind: expectation
Subject: #310 group 7 batch 3: 48 dead-leg rows over seven MAME gates frozen in tests/expected/dead_leg_unjudged.tsv (14z-223)
Claim (the working agent's sentence): #310 group 7 batch 3 can be frozen as 48 new rows of tests/expected/dead_leg_unjudged.tsv (gate, mode, UNJUDGED, stripped class HONOURED, MAME_BIN) and reported on #310 with comment_310.md: the seven MAME gates audit_ladder_pick_store, audit_marionette_cost, audit_mizuumi_attack, audit_mizuumi_inputs, audit_mizuumi_struct, audit_tick_cadence and test_proof_sheets, every declared mode (48; candidates.tsv). With MAME_BIN=/usr/bin/false at HEAD c5fe01b4 all 48 read HONOURED (base_classes.tsv), audit_marionette_cost's by a set -eu crash of an awk on a control leg's missing output (exit 2); after the fix (batch3.diff.txt: vs_ctl_nj beside each liveness exit, tagged # #310 g7 NJ, and marionette's control-leg output check) all 48 read UNJUDGED (after_all_classes.tsv); with a live emulator every gate's plain run PASSes and all 48 modes read HONOURED (live_classes.tsv), so the fix removes no live verdict. tests/test_dead_leg_unjudged.sh PASSes on all 91 rows with nj-stripped FIRED on 91 and plain-loud FIRED on 89 of 91 (dead_leg_gate.log; 41 of 43 before this batch, batch2_dead_leg_plain.log). The census rows for these gates (census_rows.tsv) number 47; test_proof_sheets' tags-dropped postdates the census. None of the seven gates is on a concurrent-controls list (lists_check.txt: 0 rows in each list). NOT TESTED: an emulator that starts and dies part-way through a leg (the table kills the binary outright, so only the first liveness exit each gate reaches is exercised; the other tagged exits are read, not run dead); the stripped class rests on the pre-fix measurement and on the gate's nj-stripped copy, not on a second independent run; audit_release_linux_cleanhost (podman), the 31 concurrent-list gates and the six held out are not in this batch; the live proof ran on the MacBook only (the gates are ondemand, pristine-only or sheet gates, so no tier runs them).
Artifacts (read every one, in full):
  - build/agent223/t310b3/comment_310.md
  - build/agent223/t310b3/batch3.diff.txt
  - build/agent223/t310b3/candidates.tsv
  - build/agent223/t310b3/base_classes.tsv
  - build/agent223/t310b3/after_all_classes.tsv
  - build/agent223/t310b3/live_classes.tsv
  - build/agent223/t310b3/dead_leg_gate.log
  - build/agent223/t310b3/batch2_dead_leg_plain.log
  - build/agent223/t310b3/census_rows.tsv
  - build/agent223/t310b3/lists_check.txt
  - build/agent223/t310b3/test_dead_leg_unjudged.sh.txt
  - build/agent223/t310b3/classify.sh.txt
  - build/agent223/t310b3/baseline.sh.txt
  - build/agent223/t310b3/live.sh.txt
  - tests/expected/dead_leg_unjudged.tsv
