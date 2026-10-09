THE PACKET

Decision kind: recommendation
Subject: the pristine-only emulator gates: which move to the ondemand scope (the maintainer's ruling of 2026-10-09)
Claim (the working agent's sentence): Of the 69 registered emulator gates whose script text and registry args carry no textual build reference at 2979890c (census_hits.tsv), reading each gate classes 29 as pristine-subject, 17 instrument, 20 build and 3 mixed (CLASSIFY.md); under the maintainer's ruling (DECISIONS_HISTORY.md lines 556-565: pristine-only gates go ondemand except cases 'known to have been broken in the past', which stay at least at release) the recommendation is: 26 pristine-subject gates to ondemand, the 3 with a broken-before record (audit_dispatch_census, audit_palette_seq_ids, test_select_arrays) kept at release, the 40 others unchanged; two of the 26, test_down_flash_vanilla and test_down_flash_mechanism, are kept at release by the maintainer's earlier ruling (a) quoted in tests/ci_emulator.tsv lines 80-86, so for them the recommendation is to put the conflict to the maintainer, not to move them; not tested: gates outside the 69 (the textual filter could pass over a pristine-only gate that names a build path in prose or a dead default), and the completeness of each broken-before search (git log of the gate, its header, tickets.tsv and STATE_HISTORY.md by name).
Artifacts (read every one, in full):
  - build/agent196/pristine_census/CLASSIFY.md
  - build/agent196/pristine_census/census_hits.tsv
  - DECISIONS_HISTORY.md.lines-556-566 (lines 556-566 of DECISIONS_HISTORY.md)
  - tests/ci_emulator.tsv.lines-72-90 (lines 72-90 of tests/ci_emulator.tsv)
