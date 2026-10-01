THE PACKET

Decision kind: build
Subject: #201: the POKES grammar takes ranges (after run 527)
Claim (the working agent's sentence): GitHub #201's fix is ready to commit: the POKES grammar takes a range `F1-F2:addr:hex`, parsed by ONE module (tests/lua/pokes_spec.lua) that expands a range IN PLACE into the per-frame entries it stands for, called by all 17 instruments in place of their own loops (t201/lua.diff); 85 contiguous per-frame pin builders in 36 files emit ranges instead (t201/callers.diff; stepped builders, every 20 or 40 frames, are left as they were). Evidence: (1) the new gate tests/test_pokes_ranges.sh runs one replay three ways on vsavj — pins per frame, the same pins as ranges, and a range one frame short — and the per-frame and range runs' whole-work-RAM checksum logs are byte-identical (t201/pokes_gate.log PASS) while the short range differs at its frame 3049 (control range-short FIRED in-gate; FAILs the gate as a mode, t201/pokes_mode.log); (2) the 33 gates whose scripts or tools were edited, plus the new gate, re-ran on the Mac and passed (t201/results.tsv: 33 PASS lines and audit_trap_shock's own 'audit_trap_shock: PASS' in t201/audit_trap_shock.log), against frozen expectations that did not change — git status of tests/expected/ lists only the three census files the new gate was frozen into (t201/expected_status.txt); tools/demitri_split_sheet.sh re-run reproduces its pre-#201 output byte for byte (t201/sheet_compare.txt); (2b) every one of the 85 rewrites is checked syntactically by t201/pair_check.py — each removed range(A, B) builder reappears in its file as {A}-{(B)-1} with the same addr:value text, 85 of 85 (t201/pair_check.txt), its plant (one bound shifted by a frame in a copy of the diff) caught (t201/pair_check_plant.txt); (3) the new gate is registered (prereq lane) and frozen into the FOLLOWS, description and must-fire censuses (t201/census.diff). NOT tested: tools/naming_pair_sheet.sh and tools/trap_air_probe.sh at runtime (their rewrites covered by the pair check only); Linux — the fix's purpose is ERIS, where it has not run yet (the next ERIS tier is the test); emulator gates that use the 17 instruments but were not edited (their POKES strings are unchanged per-entry text, parsed by the same expansion's single-entry branch — not re-run individually here); the order of two writes to one address on one frame is preserved by construction (in-place expansion) and not separately exercised by the gate; gates and tools outside tests/ and tools/ (none found) and FBNeo's own FBNEO_HPOKE grammar (separate, unchanged, fed by no edited script).
Artifacts (read every one, in full):
  - tests/lua/pokes_spec.lua
  - tests/test_pokes_ranges.sh
  - build/agent187b/t201/lua.diff
  - build/agent187b/t201/callers.diff
  - build/agent187b/t201/census.diff
  - build/agent187b/t201/pokes_gate.log
  - build/agent187b/t201/pokes_mode.log
  - build/agent187b/t201/results.tsv
  - build/agent187b/t201/audit_trap_shock.log
  - build/agent187b/t201/sha.txt
  - build/agent187b/t201/pair_check.py
  - build/agent187b/t201/pair_check.txt
  - build/agent187b/t201/pair_check_plant.txt
  - build/agent187b/t201/expected_status.txt
  - build/agent187b/t201/sheet_compare.txt
