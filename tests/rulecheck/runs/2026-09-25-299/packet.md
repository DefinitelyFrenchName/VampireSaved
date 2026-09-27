THE PACKET

Decision kind: recommendation
Subject: #174: recommend rigging the eight never-entered attack chains as a dedicated gate, after a static reading of vs2's command handlers
Claim (the working agent's sentence): Recommend building #174's rigs as a DEDICATED gate with its own replays outside tests/replays/naming/ rather than as new naming parts, because 17 gates glob the naming corpus (t174_corpus_gates.txt) and a new part would move every one of their expectations; the gate would first run each rig on native vs2 and require it to enter its chain, then compare ours with native through tools/move_parity.py. The rigs follow a STATIC reading of vs2's code (t174_calls.txt: every call to the a2 chain-start routine 0x2710c with its index; t174_handlers.txt: the command handler each call sits in beside the chains the naming rigs name; t174_handlers.dis: the four handlers that select the eight): Phobos a2:0x4b and a2:0x4d are Reflect Wall (his guard cancel, command 0x0e) from a crouching block (+0x121 set) and from an air block (+0x38 set) — the rigs only guard-cancelled standing, into a2:0x4c; Phobos a2:0x50 and a2:0x29 are Genocide Vulcan's ES version (strength index +0x102 = 6) after the trap catches the opponent (+0x26 set); Donovan a2:0x4f is the ES pursuit (Foot Stab, command 0x0c) connecting with a live victim; Pyron a2:0x48 is Piled Hell with the button-pair index +0x107 = 6, which the table at 0x2867c gives for all three kicks pressed; Pyron a2:0x03 and a2:0x05 are his 6MP and 6HP attacks (the move list's measured note: 'a 6MP that whiffed at pushbox contact came out as a2:0x03 — the odd standing ids are 6+button attacks for Pyron too'). NOT tested: every one of these readings — no rig has been run for any of them; Pyron's a2:0x05 is inferred from the 0x03 pattern only; the call-site scan reads only the nearest immediate load into d0 and attributes sites by address, so a chain started through a subroutine elsewhere or a computed index is not in t174_calls.txt; the 28 non-attack never-entered chains are not addressed.
Artifacts (read every one, in full):
  - build/agent184/t174_census.txt
  - build/agent184/t174_calls.py
  - build/agent184/t174_calls.txt
  - build/agent184/t174_handlers.py
  - build/agent184/t174_handlers.txt
  - build/agent184/t174_handlers.dis
  - build/agent184/t174_corpus_gates.txt
  - build/manifest/moves_pyron.toml.lines-23-37 (lines 23-37 of build/manifest/moves_pyron.toml)
  - build/manifest/moves_huitzil.toml.lines-31-37 (lines 31-37 of build/manifest/moves_huitzil.toml)
