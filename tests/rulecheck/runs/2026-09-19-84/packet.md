THE PACKET

Decision kind: expectation
Subject: 14z-170 close tier: test_phasec_spaces's stock fingerprint re-frozen e86e1d04 -> c54f1fb8 (donovan-m23-stock), and the harness's lineage defaults re-pointed to M19 (after the resolution of 2026-09-19-83)
Claim (the working agent's sentence): test_phasec_spaces's stock-twin fingerprint is re-frozen e86e1d04 -> c54f1fb8, and the close tier's two reds are closed with live homes. The gate builds the stage-6 stock track from the tree and pinned e86e1d04, donovan-m19-stock (registry line 152); the tree now builds c54f1fb8, the stock twin the M19 freeze registered as donovan-m23-stock (registry line 170) — the close tier read the mismatch red (phasec_fail_tier.log, static_close2.log). The move is the freeze's own: attr2_m5_stock18.txt attributes the stock twin's delta against build/m5_stock17 (whose program is e86e1d04: baselines.txt) op by op, and edits_check_m5_stock18.txt recognises every EDIT and INSERTED op as a designed edit kind, 0 unexplained — the checker (edits_check_tracks.py) failing on one undesigned byte planted inside each classifier's op kind: the EX and CASE_A4 sites, two RECORD bytes, the ADDER, the SITE jsr, both BODY thunks, the DEFENSE data op and three INSERTED ops (edits_check_plant_*.txt, twelve, each 'RESULT: FAILURES'); the x2b7ef4 op's 160 bytes on the stock track checked one by one against vs2's (x2b7ef4_sites_check_stock.txt), a plant FLAGGED (x2b7ef4_sites_check_plant.txt); from the other side, which the tool's listing cannot absorb, the stock image holds every op of its patch (image_vs_patch.txt; a byte planted inside a stock op read 'IMAGE AND PATCH DISAGREE': image_vs_patch_plant_stock.txt) and each of its 321/322 changed bytes lies inside an M19 op or is back to the base, 0 neither (image_delta_classes.txt; a byte planted on the stock track reported NEITHER: image_delta_classes_plant_stock.txt), and the tool's SAME on this track is verified pair by pair, 241 listed and each identical (same_class_check.txt), its classes planted (tool_plants.txt). After the re-freeze the gate reads PASS on c54f1fb8 (phasec_after_refreeze.log) and FAIL when handed the old value (phasec_old_expect.log; both logs carry their invocation and EXIT status). Every other M18 fingerprint in tests/*.sh, tests/lib, tests/lua and tools is a comment, an already re-frozen 'was' note, or tools/rulecheck.py's BIRTH_REGISTRY_KEY — merged-m18's whole-set key held on purpose as the rule-checker's permanent birth anchor (tools/rulecheck.py:64-68, its guard at 585-592) — each of the 16 hits classified by reading its line (m18_fp_grep.txt, m18_fp_classified.txt). The second red, test_bbh_fidelity F4, was the harness's lineage defaults still naming the M18 builds (bbh_fail_tier.log): re-pointed to M19 in the four files the M18 re-point moved (bbh_repoint.diff; bbh_census.txt: 10a82d2's seven changed files, four of them that re-point, and a grep over the harness's tracked files at HEAD naming no M18 build or key but the consumer toml's provenance note, the same grep before the re-point finding 6), after which, on the committed re-point with a clean harness tree (6e20d58), the gate reads PASS, F4 identical (bbh_fidelity_at_6e20d58.log), and the harness's selftest GREEN (bbh_selftest_at_6e20d58.log), each log naming the harness state it ran on. Both are homed in docs/project/gotchas.md 'THE RE-POINT SWEEP SEES BUILD NAMES IN THIS TREE — A PINNED FINGERPRINT AND THE HARNESS'S DEFAULTS ARE OUTSIDE IT' and the findings table's last two rows. NOT tested: the edits-checker plants were made on the Donovan and merged builds, not on the stock twin (the same classifiers run on every track); the full static tier on the tree as it now stands runs after this check (its third run); the grep covers the M18 fingerprints' 8-character forms in the gate and tool trees, not every other freeze's pins; the harness commit is not pushed yet.
Artifacts (read every one, in full):
  - tests/test_phasec_spaces.sh.lines-50-68 (lines 50-68 of tests/test_phasec_spaces.sh)
  - build/rc170/phasec_fail_tier.log
  - build/rc170/phasec_after_refreeze.log
  - build/rc170/phasec_old_expect.log
  - build/rc170/static_close2.log
  - build/rc170/freeze/rc_final/attr2_m5_stock18.txt
  - build/rc170/freeze/rc_final/edits_check_m5_stock18.txt
  - build/rc170/freeze/rc_final/edits_check_tracks.py
  - build/rc170/freeze/rc_final/edits_check_plant_0x0bf6a0.txt
  - build/rc170/freeze/rc_final/edits_check_plant_0x0fff53.txt
  - build/rc170/freeze/rc_final/edits_check_plant_edit_0x023ae3.txt
  - build/rc170/freeze/rc_final/edits_check_plant_edit_0x0caa91.txt
  - build/rc170/freeze/rc_final/edits_check_plant_edit_0x0caa92.txt
  - build/rc170/freeze/rc_final/edits_check_plant_edit_0x0cffbd.txt
  - build/rc170/freeze/rc_final/edits_check_plant_edit_0x41a050.txt
  - build/rc170/freeze/rc_final/edits_check_plant_edit_0x41a0c8.txt
  - build/rc170/freeze/rc_final/edits_check_plant_edit_0x45da8d.txt
  - build/rc170/freeze/rc_final/edits_check_plant_ins_0x0b8ba5.txt
  - build/rc170/freeze/rc_final/edits_check_plant_ins_0x0bcc93.txt
  - build/rc170/freeze/rc_final/edits_check_plant_ins_0x41a085.txt
  - build/rc170/freeze/rc_final/x2b7ef4_sites_check_stock.txt
  - build/rc170/freeze/rc_final/x2b7ef4_sites_check_plant.txt
  - build/rc170/freeze/rc_final/image_vs_patch.txt
  - build/rc170/freeze/rc_final/image_vs_patch_plant_stock.txt
  - build/rc170/freeze/rc_final/image_delta_classes.txt
  - build/rc170/freeze/rc_final/image_delta_classes_plant_stock.txt
  - build/rc170/freeze/rc_final/same_class_check.txt
  - build/rc170/freeze/rc_final/tool_plants.txt
  - build/rc170/freeze/rc_final/baselines.txt
  - tests/expected/registry.tsv.lines-152-152 (lines 152-152 of tests/expected/registry.tsv)
  - tests/expected/registry.tsv.lines-170-170 (lines 170-170 of tests/expected/registry.tsv)
  - build/rc170/m18_fp_grep.txt
  - build/rc170/m18_fp_classified.txt
  - tools/rulecheck.py.lines-60-70 (lines 60-70 of tools/rulecheck.py)
  - tools/rulecheck.py.lines-580-595 (lines 580-595 of tools/rulecheck.py)
  - build/rc170/bbh_fail_tier.log
  - build/rc170/bbh_repoint.diff
  - build/rc170/bbh_census.txt
  - build/rc170/bbh_fidelity_at_6e20d58.log
  - build/rc170/bbh_selftest_at_6e20d58.log
  - docs/project/gotchas.md.lines-5344-5358 (lines 5344-5358 of docs/project/gotchas.md)
  - build/rc170/findings_table_14z170.tsv
