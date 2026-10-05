THE PACKET

Decision kind: expectation
Subject: 14z-192: #213 re-freeze build/manifest/dispatch_census.toml, anchored to the vanilla basis
Claim (the working agent's sentence): Re-freeze build/manifest/dispatch_census.toml (tests/audit_dispatch_census.sh, GitHub #213) to the census taken on PILOT with the screen-frame clock that counts the first frame_done, a no-breakpoint reference leg per replay and a game-clock anchor: in build/agent192/c213/c213_verify4.log the in-gate control drift-clock FIRED (the old clock covered 729 emulated frames of 1800 counted, its RAM:$FF8080 at frame 1800 reading 7d against the reference leg's ab), all 56 runs covered exactly their counted frames, 56 reference legs reproduced the frozen vanilla basis checksum at the basis log's last frame, every census leg's game frame counter equalled its reference leg's, 9 census legs also equalled the basis byte for byte and 47 did not (the breakpoint stops move the game, stated in the gate's output, the toml header and docs/platform/gotchas.md), and both sites matched the frozen observation (0x054470 OBSERVED 17, 0x05e542 OBSERVED 46) that the freeze run c213_freeze4.log wrote; c213_provenance4.txt records PILOT's host, HEAD c71afed7, the three modified files and their sha1s, equal to this tree's; c213_mode.log is the gate run as CONTROL=drift-clock. NOT TESTED: the frozen lists describe the corpus as perturbed by the breakpoints, not the basis's exact games (no non-perturbing instrument exists: a read tap on ROM is blind); RAM:$FF8080 is one byte, so a drift by a multiple of 256 frames would pass the game-clock check (the coverage check and the reference leg remain); whether the 14z-89 runs drifted by the same amount (their logs do not exist); runs on any host but PILOT; tests/lua/pc_count.lua, which keeps the same first-frame skip, and the six other Lua instruments on the frame_done clock.
Artifacts (read every one, in full):
  - build/agent192/c213/c213_verify4.log
  - build/agent192/c213/c213_freeze4.log
  - build/agent192/c213/c213_mode.log
  - build/agent192/c213/c213_provenance4.txt
  - build/manifest/dispatch_census.toml
  - build/agent192/c213/diff2.patch
  - tests/audit_dispatch_census.sh
  - tests/lua/dispatch_census.lua
  - tests/expected/vsavj/masked-v2/MASK
