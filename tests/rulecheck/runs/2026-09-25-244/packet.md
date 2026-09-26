THE PACKET

Decision kind: expectation
Subject: M20 freeze: re-freeze the emulator expectations the battery's pass 1 found red, pin the #112 gate to M19, and add the LANDING-TURN-OPEN class (after runs 238-243)
Claim (the working agent's sentence): Of the ten pass-1 reds on merged-m20 (battery_reds.tsv, one header line and ten gates), each re-freeze moves only what a named cause explains. #157, which the maintainer played on the probe before ruling (maintainer_playtest.txt): the parity table's 34 meter-first DIFF rows become IDENT and 2 (huitzil_3 events 8/9) become DIFF on x, no other verdict moving (move_parity_events.tsv.diff); the attribution — its first freeze refused on exactly those two rows as OTHER (attribution_freeze1.log), the second froze (attribution_freeze2.log) — loses its METER-SWAP roots and names the two rows LANDING-TURN-OPEN, an open class for #179 ruled 'Freeze, ticket it' (decisions_lines_30_58.txt) whose signature (native's x holds and its facing flips within two frames while ours' x moves and its facing holds) matches both rows and none of six plants (class_groundtruth.txt, ev89.txt); the throw-registration rows show every ours contact paying like native with the tenant stores live-pair writers, under a contact rule widened to count live-pair writes (gate_edits.diff), and run against those re-frozen rows the gate PASSES with its three in-gate controls fired while each control mode fails (throwreg_verify_m20.txt); defense_row_reads' attacker-combo rows index the tenants' own rows where merged-m19 read the victim's, and its suite rows move only through replays 110/111, the only two of 88 whole-RAM A/B differences (whole_ram_ab_probe_vs_m19.txt). The naming-corpus and rig commits since each file's last freeze — a91a555a (huitzil_3 and pyron_3 regenerated) and f194f8ca (donovan_15 and pyron_7 added) for the files frozen 09-22, and additionally 3eea059f and 1d9b6a13 (existing parts' rigs rewritten) and 2e296e78 (a prologue refactor in name_moves.py touching no naming rig file, commit_2e296e78_name_moves.txt) for df_field_readers_live, frozen 09-19 (corpus_commits.txt, follows_scan.txt) — with every other declared input ruled out (follows_scan.txt: the gates carry their own copies of the parity rig's paths and pins, changed only in comments; the replay subdirectories added since are outside their globs; instrument_commits.txt: the tap, MAME wrappers and patches unchanged, the MAME binary older than both freezes): pyron_3's two air-throw contacts in the throw rows (on native and merged-m19 too, m19_vs_m20_reds.txt; the per-part M19 exit codes explained in m19_parts_exit.txt), everything df_field_readers_live and reaction_class_live move, and defense_row_reads' rows identical on the two builds — the attacker leg's defense and threshold rows and the non-M20 part of the attacker-combo shift — their whole tables compared across merged-m19 and merged-m20 (*.m19_vs_m20.diff). The build identity only: column_flash, phobos_dmg_residual. test_mister_prg_window's pos pair moves two counters with every structural field unchanged; test_pod_black_foot_palette is not re-frozen but pinned to merged-m19 by ruling. Each real re-freeze is followed by a verify run (pass 2), the must-fire controls with it. NOT tested: which of those commits moves which row (2e296e78 included); the prg_window counter move (recorded as measured, not explained); #179's mechanism and how it plays (a capture is its next step; the class is ground-truthed on huitzil_3 alone); the whole-RAM A/B ran on the probe, whose program equals merged-m20's but whose mark glyphs read P57 — that the glyphs do not change execution is assumed, and the suite rows' attribution to 110/111 rests on it, not traced per replay; the third store pair was never observed writing.
Artifacts (read every one, in full):
  - build/rc183/refreeze2/battery_reds.tsv
  - build/rc183/refreeze2/m19_vs_m20_reds.txt
  - build/rc183/refreeze2/m19_parts_exit.txt
  - build/rc183/refreeze2/summary.txt
  - build/rc183/refreeze2/summary_m19.txt
  - build/rc183/refreeze2/attribution_freeze1.log
  - build/rc183/refreeze2/attribution_freeze2.log
  - build/rc183/refreeze2/move_parity_events.tsv.diff
  - build/rc183/refreeze2/move_parity_attribution.tsv.diff
  - build/rc183/refreeze2/throw_registration.tsv.diff
  - build/rc183/refreeze2/throwreg_verify_m20.txt
  - build/rc183/refreeze2/column_flash.tsv.diff
  - build/rc183/refreeze2/phobos_dmg_residual.tsv.diff
  - build/rc183/refreeze2/df_field_readers_live.tsv.diff
  - build/rc183/refreeze2/reaction_class_live.tsv.diff
  - build/rc183/refreeze2/defense_row_reads.tsv.diff
  - build/rc183/refreeze2/df_field_readers_live.m19_vs_m20.diff
  - build/rc183/refreeze2/reaction_class_live.m19_vs_m20.diff
  - build/rc183/refreeze2/defense_row_reads.m19_vs_m20.diff
  - build/rc183/refreeze2/corpus_commits.txt
  - build/rc183/refreeze2/instrument_commits.txt
  - build/rc183/refreeze2/follows_scan.txt
  - build/rc183/refreeze2/commit_2e296e78_name_moves.txt
  - build/rc183/refreeze2/whole_ram_ab_probe_vs_m19.txt
  - build/rc183/refreeze2/mister_prg_window.txt.diff
  - build/rc183/refreeze2/gate_edits.diff
  - build/rc183/refreeze2/ev89.txt
  - build/rc183/refreeze2/class_groundtruth.txt
  - build/rc183/refreeze2/decisions_lines_30_58.txt
  - build/rc183/refreeze2/maintainer_playtest.txt
