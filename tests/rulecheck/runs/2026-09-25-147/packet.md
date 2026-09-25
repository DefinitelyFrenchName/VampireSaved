THE PACKET

Decision kind: expectation
Subject: 14z-181 #171 slice Q6: re-classing the 73 UNCLASSIFIED rows of tests/expected/poke_readback.tsv as the maintainer ruled on 2026-09-25 ("I agree with the proposal") — 41 OBSERVES, 28 READS-BACK (21 of them never-compared FIELDS columns DROPPED from eight gates and RETIRED, 7 labelled in their gates' headers), 3 CONTROL-PLANT and 1 CROSS-LEG (two new classes in the table, the gate and the tool), the pending item moved to DECISIONS_HISTORY and a standing line in STATE
Claim (the working agent's sentence): Every one of the 73 rows takes the class the ruling packet proposed, and each proposal rests on the gate's own compare as quoted by six reader workers (the packet names the deciding path:line per row; the returns are the artifacts), not on the census tool; the 21 dropped columns are RETIRED because the census no longer derives them after the drop, and the eight gates whose FIELDS changed were each re-run on MAME after the drop and PASS with their verdict lines unchanged; the poke read-back gate PASSES with the new counts and each of its four control modes reaches FAIL; NOT tested: whether a per-leg census would classify the three CONTROL-PLANT and the one CROSS-LEG rows differently (the tool still compares addresses per gate, not per leg — recorded in the table's header as a limitation), whether the seven kept READS-BACK rows' header labels are complete against every consumer of those dumps, and the two vanilla join gates' forced picks remain unasserted by any gate (a separate question, not ruled).
Artifacts (read every one, in full):
  - tests/expected/poke_readback.tsv
  - build/agent181/poke_readback_14z181.diff
  - build/agent181/poke_rulings_packet_14z181.tsv
  - build/agent181/reader_returns/groupA_14z181.txt
  - build/agent181/reader_returns/groupBCD_deciding_lines_14z181.txt
  - build/agent181/reader_returns/groupE_14z181.txt
  - build/agent181/measurer_returns_14z181.txt
  - build/agent181/poke_gates_14z181.diff
  - build/agent181/poke_records_14z181.diff
  - build/agent181/pokegate_14z181.log
  - build/agent181/rerun_killshread_es.log
  - build/agent181/rerun_advancing_guard.log
  - build/agent181/rerun_guard_reentry.log
  - build/agent181/rerun_df_startup_invuln.log
  - build/agent181/rerun_reactions.log
  - build/agent181/rerun_move_naming.log
  - build/agent181/rerun_vanilla_frame_join.log
  - build/agent181/rerun_vanilla_aerial_join.log
  - tests/test_poke_readback.sh
  - tools/audit_poke_readback.py
  - DECISIONS_HISTORY.md.lines-30-58 (lines 30-58 of DECISIONS_HISTORY.md)
  - tests/expected/PROVENANCE.md
