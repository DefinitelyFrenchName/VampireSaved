THE PACKET

Decision kind: recommendation
Subject: #127, #162 and #294 closed done against the M24 release published from the freeze commit be40e6f3 (14z-217)
Claim (the working agent's sentence): #127, #162 and #294 can close done on the M24 release, with the closing comments closing_127.md, closing_162.md and closing_294.md. Each issue's condition (issue127.md, issue162.md, issue294.md: the ticket stays open until the release that ships M24) is met: upload.log shows the GitHub release on freeze/merged-m24 created, its 9 assets uploaded and re-verified from GitHub, and merged-m23's 9 zips pruned; closures_evidence.txt shows freeze/merged-m24 resolving to be40e6f3 locally and on origin, the release neither draft nor prerelease, and merged-m23 holding 0 assets. Each ticket's emulator gates (audit_don_row0b, audit_don_row0c, audit_column_flash, audit_column_flash_cause) PASS in ERIS's release run build/emu_rel216_eris/results.tsv, whose commit.txt reads be40e6f3, with each of their 7 control rows reading control honoured. test_perframe_hook and test_dead_span PASS in the static run of record static_rel_record.tsv, reused from the freeze run static_freeze_results_s5.tsv whose tree 9a1fe8b8 equals be40e6f3's tree (closures_evidence.txt). ERIS's 4 SKIP rows each have a PASS row at be40e6f3 on the Mac or PILOT (the results.tsv files named in closures_evidence.txt). The static run of record reads NOT GREEN under --strict on one SKIP, test_release_launcher_bat's Windows half, whose ERIS run at be40e6f3 (bat217.log) reads PASS with 8 CONTROL FIRED lines; the maintainer accepted that SKIP (maintainer_words.txt). #344 and #345, named in closing_294.md as still open, read OPEN (closures_evidence.txt). NOT TESTED: no person played the fixes in the published zips; the published zips were compared file by file with the uploaded ones by the uploader, not re-gated after download; PILOT's desktop gate went red once (FBNeo's window paused, a focus loss inferred, not measured: findings.md item 2) and its run of record is a later fresh run, build/emu_p217_desk2; ERIS's run directory is named emu_rel216_eris because it was started in session 14z-216, though its commit.txt reads be40e6f3.
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
  - build/emu_rel216_eris/results.tsv
  - build/emu_rel216_eris/commit.txt
  - build/emu_rel217_mac_test_release_binaries/results.tsv
  - build/emu_rel217_mac_test_readme_recording/results.tsv
  - build/emu_p217_clean/results.tsv
  - build/emu_p217_desk2/results.tsv
