THE PACKET

Decision kind: recommendation
Subject: #127, #162 and #294 closed done against the M24 release published from the freeze commit be40e6f3 (14z-217), after run 2026-11-02-1561
Claim (the working agent's sentence): #127, #162 and #294 can close done on the M24 release, with the closing comments closing_127.md, closing_162.md and closing_294.md. Each issue's condition (issue127.md, issue162.md, issue294.md: the ticket stays open until the release that ships M24) is met: upload.log shows the GitHub release on freeze/merged-m24 created, its 9 assets uploaded and re-verified from GitHub, and merged-m23's 9 zips pruned; closures_evidence.txt shows freeze/merged-m24 resolving to be40e6f3 locally and on origin, the release neither draft nor prerelease, and merged-m23 holding 0 assets. The published zips are be40e6f3's release: zips_vs_tree.txt compares the 9 zips downloaded back from GitHub with be40e6f3 file by file (241 equal to the commit's tracked file, 61 binaries equal to the sha256 row naming them in the commit's BINARY.txt, 6 BINARY.txt differing only by their asset line, 0 mismatches), and its two planted controls (zips_vs_tree_controls.txt) each read MISMATCH and exit 1. The downloaded FBNeo recipe package, applied to the reference dumps, builds 43505a12 (merged-m24's registry row, closures_evidence.txt), whose 25 members are byte-identical to build/m3b_merged32/rompath/vsavjw.zip and whose 7 other members equal the reference dumps (applied_vs_m3b_merged32.txt); build/m3b_merged32 is the BUILD default of the four ticket gates (their scripts), and both ERIS's release run (eris_rel216_run.log) and the Mac's (mac_test_mame_parity.log) name it MERGED vsavjw 0e6f423b. Each ticket's emulator gates (audit_don_row0b, audit_don_row0c, audit_column_flash, audit_column_flash_cause) PASS in ERIS's release run build/emu_rel216_eris/results.tsv, whose commit.txt reads be40e6f3, with each of their 7 control rows reading control honoured. test_perframe_hook and test_dead_span PASS in the static run of record static_rel_record.tsv, reused from the freeze run static_freeze_results_s5.tsv whose tree 9a1fe8b8 equals be40e6f3's tree (closures_evidence.txt). ERIS's 4 SKIP rows each have a PASS row at be40e6f3 on another host: test_release_binaries and test_readme_recording on the Mac (macOS binaries) and on PILOT (Linux binaries: build/emu_p217_test_release_binaries, build/emu_p217_test_readme_recording, pilot_test_release_binaries.log), audit_release_linux_desktop and audit_release_linux_cleanhost on PILOT; every control row in those results reads control honoured. The static run of record reads NOT GREEN under --strict on one SKIP, test_release_launcher_bat's Windows half, whose ERIS run at be40e6f3 (bat217.log) reads PASS with 8 CONTROL FIRED lines; the maintainer accepted that SKIP (maintainer_words.txt). #344 and #345, named in closing_294.md as still open, read OPEN (closures_evidence.txt). NOT TESTED: no person played the fixes in the published zips; only the FBNeo recipe package was applied to the dumps (the MAME recipe and the six prebuilt packages were compared with be40e6f3 file by file, not applied); test_release_binaries was not run on the Windows binaries at be40e6f3 (they equal be40e6f3's BINARY.txt rows, and test_release_launcher_bat's Windows half ran them); PILOT's desktop gate went red once (FBNeo's window paused, a focus loss inferred, not measured: findings.md item 2) and its run of record is a later fresh run, build/emu_p217_desk2; ERIS's run directory is named emu_rel216_eris because it was started in session 14z-216, though its commit.txt reads be40e6f3; the freeze static run S5 that the static run of record reused was taken at head a7fab7d6, whose tree equals be40e6f3's.
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
  - build/agent217/release/close/applied_vs_m3b_merged32.txt
  - build/agent217/release/close/eris_rel216_run.log
  - build/agent217/release/mac_test_mame_parity.log
  - build/agent217/release/close/pilot_test_release_binaries.log
  - tests/audit_don_row0b.sh
  - tests/audit_don_row0c.sh
  - tests/audit_column_flash.sh
  - tests/audit_column_flash_cause.sh
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
