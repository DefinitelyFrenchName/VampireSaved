THE PACKET

Decision kind: recommendation
Subject: #295: the plan for a vsavj-vs-ours leg in audit_dmg_legacy_sweep (14z-205)
Claim (the working agent's sentence): Build #295 as plan.md says: section 2's legacy leg run on our merged build (vsavjw) for all 32 legs, judged against the same run's vsavj leg by byte-identical field traces and equal rows hit for hit, with two must-fire controls (ours-diverged, a planted one-HP row; ours-records-swapped, our build with vs2's three records through rom_poke.lua), the ours leg on the sheet, and no frozen expectation changed. The pilot (pilot_result.txt, pilot.sh) measured 4 of the 32 legs identical. What the plan rests on that it does not test is listed in plan.md's last section: the shared rig (poked picks, HP, level and RNG pins), MAME only, one build, three hits by one attacker, and the 28 legs the pilot did not run. The maintainer's request: maintainer_words.txt; the original question and the filing: decision_295.txt
Artifacts (read every one, in full):
  - build/agent205/t295/plan.md
  - build/agent205/t295/pilot_result.txt
  - build/agent205/t295/pilot.sh
  - tests/audit_dmg_legacy_sweep.sh
  - tools/dmg_sweep.py
  - build/agent205/t295/issue_live.md
  - build/agent205/t295/decision_295.txt
  - build/agent205/t295/maintainer_words.txt
