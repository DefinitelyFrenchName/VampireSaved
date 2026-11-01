THE PACKET

Decision kind: freeze
Subject: M24 freeze: registry rows donovan-m28 huitzil-m35 pyron-m29 merged-m24 and the evidence behind them
Claim (the working agent's sentence): Freeze M24: the four registry rows in registry_rows.txt (donovan-m28, huitzil-m35, pyron-m29, merged-m24) are the six builds' measured keys, reproduced on two machines (fingerprints_mac.txt = fingerprints_eris.txt on program and set key; the four expectation sets file-for-file equal, sets_mac_vs_eris.txt); every fixed site of the merged byte diff is explained (bytediff_fixed_review.txt; bytediff_head.txt is the frozen record's head); the freeze battery's reds were re-frozen and that re-freeze was checked OK (rulecheck_1554_verdicts.txt; s2_results.tsv the verifying battery, its two FAILs re-frozen since and its four SKIPs host-covered); on snapshot S4 (d1aed6a8) the gates staled after S2 re-ran green (eris_s4_stale_results.tsv: PASS 29, SKIP 4 host-only, FAIL 1 = audit_ladder_selector; mac_s4_results.tsv: four PASS); audit_ladder_selector's red was its frame-pinned saturation window left behind by M24's earlier match-2 selection (ladder/: the same 15 advances and stage set, 960 frames earlier; window moved by that amount, ladder_m24_fixed.log PASS with merged-m23's original reading, gate_diff.diff); the Linux release plays and runs on a clean host, recorded through the emulator runner on PILOT at S4 (pilot_rows/desk_* and clean_*: commit.txt d1aed6a8, results.tsv PASS, the runner's GREEN; the only modified tracked paths are the submodules emu/fbneo and emu/jtcores, pilot_status_and_script.txt, which neither gate's FOLLOWS names, follows.txt); the desktop gate's driver targets the client window instead of its mutter frame (tool_diff_vs_head.diff the one change; desktop/plain_framewindow_red.log the red before; its three CONTROL= modes FAIL, desktop/ctl_*.log); the release tested is the frozen build: the applier's set key 8a6366c2 (clean_audit_release_linux_cleanhost.log) is S4's release manifest's applied_set_key beside build_fingerprint 43505a12 (release_manifest_fbneo.json), merged-m24's registry key (registry_rows.txt), and test_release_roundtrip requires the applied set to hash to that key and PASSed in the S3 tier (release_roundtrip_evidence.txt); freeze-cadence staleness at S4 PASSes with those rows (staleness_freeze_at_s4_v2.txt; its two NOTE rows are outside a freeze); both concurrent-controls lists are re-traced at S4 and test_controls_concurrent PASSes on the tree (traces/: static 620 runs, 117 SAFE, 4 SHARED kept off, test_applier_page taken off for two TIMEOUTs and test_applier_page_browser still off; emulator 164 runs on PILOT and ERIS, 45 SAFE, all HONOURED; test_proof_sheets_web re-traced after #338's publisher change, 14 runs SAFE, HONOURED); the maintainer's rulings this freeze rests on are quoted in rulings.txt, maintainer_reading_345.txt, rulings_m_294.txt and rulings_retrace.txt. What this rests on that is NOT tested: (1) the final static freeze tier on the commit's tree has not run yet (it follows this check, on snapshot S5 of the staged tree; the S3 tier was red and its fixes are in the tree); (2) the desktop gate's three CONTROL= modes were run directly on PILOT's S2 checkout with S4's tool blob, not through the runner (a freeze's runner rows run no controls); (3) audit_ladder_selector's PASS after its fix is a direct run, not a runner row (it is outside a freeze's cadence; a runner row on S5 is to follow); (4) nothing was run on hardware (the MiSTer .rbf is unchanged), no release is published, and the release-cadence gates are not part of a freeze; (5) the RNG-dependent rows of #345 are exempt by the maintainer's ruling and the lag frame is a ruled tradeoff (rulings.txt), not parity; (6) the tree also carries #338's publisher change (no batch-mode ssh, --dry-run), tested by test_proof_sheets_web and not part of the builds.
Artifacts (read every one, in full):
  - build/agent216/m24/rc_freeze/registry_rows.txt
  - build/agent216/m24/rc_freeze/fingerprints_mac.txt
  - build/agent216/m24/rc_freeze/fingerprints_eris.txt
  - build/agent216/m24/rc_freeze/sets_mac_vs_eris.txt
  - build/agent216/m24/rc_freeze/bytediff_fixed_review.txt
  - build/agent216/m24/rc_freeze/bytediff_head.txt
  - build/agent216/m24/rc_freeze/rulecheck_1554_verdicts.txt
  - build/agent216/m24/rc_freeze/s2_results.tsv
  - build/agent216/m24/rc_freeze/eris_s4_stale_results.tsv
  - build/agent216/m24/rc_freeze/mac_s4_results.tsv
  - build/agent216/m24/rc_freeze/staleness_freeze_at_s4_v2.txt
  - build/agent216/m24/rc_freeze/ladder/ladder_m23.log
  - build/agent216/m24/rc_freeze/ladder/ladder_m24.log
  - build/agent216/m24/rc_freeze/ladder/ladder_m24_fixed.log
  - build/agent216/m24/rc_freeze/ladder/gate_diff.diff
  - build/agent216/m24/rc_freeze/pilot_rows/desk_commit.txt
  - build/agent216/m24/rc_freeze/pilot_rows/desk_results.tsv
  - build/agent216/m24/rc_freeze/pilot_rows/desk_audit_release_linux_desktop.log
  - build/agent216/m24/rc_freeze/pilot_rows/clean_commit.txt
  - build/agent216/m24/rc_freeze/pilot_rows/clean_results.tsv
  - build/agent216/m24/rc_freeze/pilot_rows/clean_audit_release_linux_cleanhost.log
  - build/agent216/m24/rc_freeze/pilot_rows/pilot_status_and_script.txt
  - build/agent216/m24/rc_freeze/pilot_rows/follows.txt
  - build/agent216/m24/rc_freeze/desktop/ctl_muted-stream.log
  - build/agent216/m24/rc_freeze/desktop/ctl_unlinked-recorder.log
  - build/agent216/m24/rc_freeze/desktop/ctl_wrong-mark.log
  - build/agent216/m24/rc_freeze/desktop/plain_framewindow_red.log
  - build/agent216/m24/rc_freeze/desktop/tool_diff_vs_head.diff
  - build/agent216/m24/rc_freeze/release_manifest_fbneo.json
  - build/agent216/m24/rc_freeze/release_roundtrip_evidence.txt
  - build/agent216/m24/rc_freeze/traces/static_summary.txt
  - build/agent216/m24/rc_freeze/traces/static_overlap.txt
  - build/agent216/m24/rc_freeze/traces/emu_overlap.txt
  - build/agent216/m24/rc_freeze/traces/emu_classes.tsv
  - build/agent216/m24/rc_freeze/traces/psw_overlap.txt
  - build/agent216/m24/rc_freeze/traces/psw_classes.tsv
  - build/agent216/m24/rc_freeze/traces/test_controls_concurrent.log
  - build/agent216/m24/rc_freeze/rulings.txt
  - build/agent216/m24/rc_freeze/maintainer_reading_345.txt
  - build/agent216/m24/rc_freeze/rulings_m_294.txt
  - build/agent216/m24/rc_freeze/rulings_retrace.txt
