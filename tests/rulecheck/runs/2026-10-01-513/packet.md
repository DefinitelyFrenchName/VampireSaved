THE PACKET

Decision kind: expectation
Subject: #191/#161 mechanism retracted; DMG-VSAVJ -> P2-RECORD re-freeze; #192 gate freeze (after run 512)
Claim (the working agent's sentence): Three expectation changes rest on one measurement: on 14 of the 16 legacy victims, from both sides, Demitri's 2HK/5HP/623HP damage differs between pristine vsavj and vs2 because vs2 lowered his own attack records (10/14/20 -> 9/13/18): each game given the other's three records takes the other game's frozen damage, red and white, on 176 of 192 rows, the 16 others exactly Sasquatch 0x0A's and Oboro 0x18's, whose own data differs (t191n/gate_run3.log section 5, every one of the 64 swapped legs' record writes verified; the three hits mapped to the record chains' nodes; an own-value poke inert; counterfactual-skipped FIRED and each of the three controls FAILs the gate as a mode, t191n/gate3_mode_*.log; the frozen rows unchanged). (1) tests/expected/move_parity_attribution.tsv re-frozen: its six DMG-VSAVJ roots and their six row lines (attr/freeze.diff) become P2-RECORD, computed from P2 Demitri's node at the hit mapped on both legs' images and that node's record (a2:0x04#2, 13 vs2 / 14 vsavj) lower on vs2 by exactly the HP difference (attr/tool.diff), verify PASS (attr/verify.log); each of the six rows moves to the other leg's value when that byte is set to the other game's value, both ways (t192/cf_six_rows.txt), and an own-value poke reproduces every one of the eight legs' traces (t192/cf_same_summary.txt). (2) tests/expected/demitri_split.tsv frozen for #192 (t192/split_verify.log PASS, control fired; t192/split_mode.log FAIL as a mode). NOT tested: attackers other than Demitri and moves beyond these three and Chaos Flare; FBNeo; why Victor's 2HK reads equal on both games (the swap reproduces it); WHY Sasquatch's and Oboro's rows differ beyond their own data being different (not separated by a swap of their data); whether the engines differ on any hit whose records are equal (nothing here claims they never do); the P2 guard's declared chains outside the ALL=1 parts; the attribution gate carries no must-fire control specific to P2-RECORD (a record-equal case falls to OTHER, which fails the gate).
Artifacts (read every one, in full):
  - tests/expected/move_parity_attribution.tsv
  - build/agent187b/attr/freeze.diff
  - build/agent187b/attr/tool.diff
  - build/agent187b/attr/verify.log
  - build/agent187b/t192/cf_six_rows.txt
  - build/agent187b/t192/cf_same_summary.txt
  - build/agent187b/t191n/gate_tool.diff
  - build/agent187b/t191n/gate_run3.log
  - build/agent187b/t191n/gate3_mode_counterfactual-skipped.log
  - build/agent187b/t191n/gate3_mode_engines-agree.log
  - build/agent187b/t191n/gate3_mode_attacker-swapped.log
  - build/agent187b/t191n/sweep_cf_result.txt
  - tests/expected/dmg_legacy_sweep.tsv
  - tests/expected/demitri_split.tsv
  - tests/audit_demitri_split.sh
  - build/agent187b/t192/split_verify.log
  - build/agent187b/t192/split_mode.log
  - tests/lua/rom_poke.lua
