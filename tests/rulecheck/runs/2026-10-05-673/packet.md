THE PACKET

Decision kind: expectation
Subject: 14z-192: #213 re-freeze build/manifest/dispatch_census.toml on the emulated clock
Claim (the working agent's sentence): Re-freeze build/manifest/dispatch_census.toml (tests/audit_dispatch_census.sh, GitHub #213) to the census taken on the emulated clock: tests/lua/dispatch_census.lua now advances its frame counter only when the screen's frame number moves, and the gate FAILs any run whose EMUFRAMES fall short of its CENSUSEND; on PILOT (a worktree of origin/main c71afed7 plus the three changed files) the check run build/agent192/c213/pilot_check.log shows all 56 runs covering every counted frame, site 0x054470 OBSERVED 16 and site 0x05e542 OBSERVED 45, the in-gate control drift-clock FIRED (728 emulated of 1800 counted under the old clock), and the freeze run and its verify run (build/agent192/c213/pilot_freeze2.log, pilot_verify.log) reproduce the same lists, so the frozen observation is replaced by those lists while the toml's leading comment block is kept and records the 14z-89 lists; the single-replay comparison build/agent192/c213/26_don_arcade_mash.{emu,frame_done}.txt shows the old clock covering 4202 emulated frames of 40620 counted. NOT TESTED: whether the 14z-89 runs drifted by the same amount (their logs do not exist; the drift is inferred from the same instrument and clock on today's corpus), the seven indices frozen in 14z-89 and unseen now (0x054470: 20, 51, 55; 0x05e542: 31, 42, 43, 44 — reached under drifted input, not reproduced), runs on any host but PILOT, and the seven other Lua instruments that share the frame_done clock.
Artifacts (read every one, in full):
  - build/agent192/c213/pilot_check.log
  - build/agent192/c213/pilot_freeze2.log
  - build/agent192/c213/pilot_verify.log
  - build/agent192/c213/dispatch_census.frozen.toml
  - build/manifest/dispatch_census.toml
  - build/agent192/c213/26_don_arcade_mash.emu.txt
  - build/agent192/c213/26_don_arcade_mash.frame_done.txt
  - build/agent192/c213/diff.patch
  - tests/audit_dispatch_census.sh
  - tests/lua/dispatch_census.lua
