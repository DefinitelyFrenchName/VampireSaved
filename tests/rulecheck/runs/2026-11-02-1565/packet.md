THE PACKET

Decision kind: recommendation
Subject: #127, #162 and #294 closed done against the M24 release published from the freeze commit be40e6f3 (14z-217), after runs 2026-11-02-1561 to -1564
Claim (the working agent's sentence): #127, #162 and #294 can close done on the M24 release, with the closing comments closing_127.md, closing_162.md and closing_294.md. Each issue's condition (issue127.md, issue162.md, issue294.md: the ticket stays open until the release that ships M24) is met: upload.log shows the GitHub release on freeze/merged-m24 created, its 9 assets uploaded and re-verified from GitHub, and merged-m23's 9 zips pruned; closures_evidence.txt shows freeze/merged-m24 resolving to be40e6f3 locally and on origin, the release neither draft nor prerelease, and merged-m23 holding 0 assets. The published zips are be40e6f3's release: zips_vs_tree.txt compares the 9 zips downloaded back from GitHub with be40e6f3 file by file (241 equal to the commit's tracked file, 61 binaries equal to the sha256 row naming them in the commit's BINARY.txt, 6 BINARY.txt differing only by their asset line, 0 mismatches), and its two planted controls (zips_vs_tree_controls.txt) each read MISMATCH and exit 1. Every one of the 9 downloaded packages, the MiSTer one included, applied to the reference dumps with its own applier, builds 43505a12 (merged-m24's registry row, closures_evidence.txt), the same set on all 9 (sha256 01e9445b), whose 25 members are byte-identical to build/m3b_merged32/rompath/vsavjw.zip with none differing or missing (applied_all9.txt) and whose 7 other members equal the reference dumps (applied_vs_m3b_merged32.txt); the member comparator zipmembers_cmp.py carries two must-fail controls, a content byte flipped (DIFFERS, exit 1) and a member removed (ONLY IN B, exit 1) (zipmembers_cmp_controls.txt). build/m3b_merged32 is the BUILD default of the four ticket gates (their scripts), and both ERIS's release run (eris_rel216_run.log) and the Mac's (mac_test_mame_parity.log) name it MERGED vsavjw 0e6f423b. Each ticket's emulator gates (audit_don_row0b, audit_don_row0c, audit_column_flash, audit_column_flash_cause) PASS in ERIS's release run build/emu_rel216_eris/results.tsv, whose commit.txt reads be40e6f3, all four in the mame lane, with each of their 7 control rows reading control honoured. test_perframe_hook and test_dead_span PASS in the static run of record static_rel_record.tsv, reused from the freeze run static_freeze_results_s5.tsv whose tree 9a1fe8b8 equals be40e6f3's tree (closures_evidence.txt). ERIS's 4 SKIP rows each have a PASS row at be40e6f3 on another host: test_release_binaries and test_readme_recording on the Mac (macOS binaries) and on PILOT (Linux binaries: build/emu_p217_test_release_binaries, build/emu_p217_test_readme_recording, pilot_test_release_binaries.log), audit_release_linux_desktop and audit_release_linux_cleanhost on PILOT; every control row in those results reads control honoured. The static run of record reads NOT GREEN under --strict on one SKIP, test_release_launcher_bat's Windows half, whose ERIS run at be40e6f3 (bat217.log) reads PASS with 8 CONTROL FIRED lines; the maintainer accepted that SKIP (maintainer_words.txt). #344 and #345, named in closing_294.md as still open, read OPEN (closures_evidence.txt). NOT TESTED, and listed in each closing comment's two blocks ('Not covered by this ticket's gates' with every NOT COVERED or stated-not-tested item of each gate that comment cites, from the gate scripts' headers; 'Not tested at this release'): Donovan as P2; FBNeo and the MiSTer core (all four emulator gates run in the mame lane; the packages for those emulators were applied and build the judged set, but no FBNeo or MiSTer run judged the palette rows); how it looks (no capture of the published build was put to the maintainer at this release); the census parts frozen blind, whose 0 is not evidence: audit_don_row0b's donovan_8 and donovan_13, and audit_don_row0c's ten (donovan_1, 2, 6, 8, 9, 10, 11, 13, 14 and 15), so outside Dark Force audit_don_row0c's evidence for the fix is R1 plus 5 parts; for #162, which sequence id the build uploads at 2807 and 2858, other palette rows, row 11 before the move, and what the census's other DIFF sites do in play; for #294, what the per-frame routine does at run time as test_perframe_hook sees it (audit_don_row0c's job), the stock twin and solo builds, and an address formed at run time from no constant (test_dead_span); no person played the fixes in the published zips; test_release_binaries was not run on the Windows binaries at be40e6f3 (they equal be40e6f3's BINARY.txt rows, and test_release_launcher_bat's Windows half took their launchers to the launch line in a dry run without starting the emulator, bat217.log); PILOT's desktop gate went red once (FBNeo's window paused, a focus loss inferred, not measured: findings.md item 2) and its run of record is a later fresh run, build/emu_p217_desk2. Not in the comments, as bookkeeping: ERIS's run directory is named emu_rel216_eris because it was started in session 14z-216, though its commit.txt reads be40e6f3; the freeze static run S5 that the static run of record reused was taken at head a7fab7d6, whose tree equals be40e6f3's.
Artifacts (read every one, in full):
  - build/agent217/release/close/closing_127.md
  - build/agent217/release/close/closing_162.md
  - build/agent217/release/close/closing_294.md
  - build/agent217/release/close/issue127.md
  - build/agent217/release/close/issue162.md
  - build/agent217/release/close/issue294.md
  - build/agent217/release/close/maintainer_words.txt
  - build/agent217/release/closures_evidence.txt
  - build/agent217/release/upload.log
  - build/agent217/release/static_rel_record.tsv
  - build/agent217/release/static_rel_record.log
  - build/agent217/release/bat217.log
  - build/agent217/release/bat217_ff.log
  - build/agent217/release/findings.md
  - build/agent216/m24/static_freeze_results_s5.tsv
  - build/agent217/release/close/zips_vs_tree.py
  - build/agent217/release/close/zips_vs_tree.txt
  - build/agent217/release/close/zips_vs_tree_controls.txt
  - build/agent217/release/close/gh_download_sha256.txt
  - build/agent217/release/close/zipmembers_cmp.py
  - build/agent217/release/close/zipmembers_cmp_controls.txt
  - build/agent217/release/close/applied_vs_m3b_merged32.txt
  - build/agent217/release/close/applied_all9.txt
  - build/agent217/release/close/eris_rel216_run.log
  - build/agent217/release/mac_test_mame_parity.log
  - build/agent217/release/close/pilot_test_release_binaries.log
  - tests/audit_don_row0b.sh
  - tests/audit_don_row0c.sh
  - tests/audit_column_flash.sh
  - tests/audit_column_flash_cause.sh
  - tests/test_perframe_hook.sh
  - tests/test_dead_span.sh
  - build/emu_rel216_eris/results.tsv
  - build/emu_rel216_eris/commit.txt
  - build/emu_rel217_mac_test_release_binaries/results.tsv
  - build/emu_rel217_mac_test_readme_recording/results.tsv
  - build/emu_p217_test_release_binaries/results.tsv
  - build/emu_p217_test_readme_recording/results.tsv
  - build/emu_p217_test_release_binaries/commit.txt
  - build/emu_p217_test_readme_recording/commit.txt
  - build/emu_p217_clean/results.tsv
  - build/emu_p217_desk2/results.tsv
  - build/emu_p217_desk2/commit.txt
