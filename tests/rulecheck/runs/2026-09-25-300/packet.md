THE PACKET

Decision kind: recommendation
Subject: #174: recommend rigging the eight never-entered a2 attack chains as a dedicated gate — re-check after run 299
Claim (the working agent's sentence): Recommend building #174's rigs as a DEDICATED gate with its own replays outside tests/replays/naming/ rather than as new naming parts: 17 gates glob the naming corpus (t174_corpus_gates.txt), and a gate that globs a corpus follows it — 14z-181's two added parts turned three such gates red (project gotchas, 30 parts read 32); the gate would first run each rig on native vs2 and require it to enter its chain, then compare ours with native through tools/move_parity.py. SCOPE: table a2 as #174 defines it ('Table a2 (the specials)'): 36 distinct never-entered starts, 8 with attack records (the census's unit; it lists 39 seqs, aliases counted); the never-entered attack chains of tables a, b and c are out of this recommendation. The rigs follow a STATIC reading of vs2's code: Phobos a2:0x4b and a2:0x4d are Reflect Wall (his guard cancel, command 0x0e) started with the crouch flag +0x121 set (atlas: 1 while Down is held) and with +0x38 set (atlas: off the ground) — the standing guard cancel the rigs performed entered a2:0x4c (move_naming_huitzil.txt 108-110); Phobos a2:0x50 is Genocide Vulcan's ES version (strength index +0x102 = 6) on the branch taken when +0x26 is set, the catch path, and a2:0x29 an ES-only later phase (+0x21 set and +0x102 = 6; its relation to the catch not read); Donovan a2:0x4f is the pursuit (Foot Stab, command 0x0c) on contact (+0x39) when the victim is not dead (+0x11f clear), the global $10d(a5) is clear and the ES index +0x102 = 6; Pyron a2:0x48 is Piled Hell with the button-pair index +0x107 = 6, which the kick path (command 0x14 is stamped with d1 = 1, selecting the KICK bits) gives for all three kicks pressed; Pyron a2:0x03 and a2:0x05 are, on the move list's measured note alone ('a 6MP that whiffed at pushbox contact came out as a2:0x03 — the odd standing ids are 6+button attacks for Pyron too'), his 6MP and 6HP attacks — no handler was read for them, and 0x05 is inferred from the 0x03 pattern. NOT tested: every one of these readings — no rig has been run for any of them; the call-site scan reads only the nearest immediate load into d0 and attributes sites by address, so a chain started through a subroutine elsewhere or a computed index is not in t174_calls.txt; the 28 non-attack never-entered a2 starts are not addressed.
Artifacts (read every one, in full):
  - build/agent184/t174_census.txt
  - build/agent184/t174_calls.py
  - build/agent184/t174_calls.txt
  - build/agent184/t174_handlers.py
  - build/agent184/t174_handlers.txt
  - build/agent184/t174_handlers.dis
  - build/agent184/t174_corpus_gates.txt
  - build/manifest/moves_pyron.toml.lines-23-37 (lines 23-37 of build/manifest/moves_pyron.toml)
  - build/manifest/moves_huitzil.toml.lines-156-164 (lines 156-164 of build/manifest/moves_huitzil.toml)
  - tests/expected/move_naming_huitzil.txt.lines-108-110 (lines 108-110 of tests/expected/move_naming_huitzil.txt)
  - docs/game/atlas/ram.md.lines-165-166 (lines 165-166 of docs/game/atlas/ram.md)
  - docs/project/gotchas.md.lines-5936-5946 (lines 5936-5946 of docs/project/gotchas.md)
