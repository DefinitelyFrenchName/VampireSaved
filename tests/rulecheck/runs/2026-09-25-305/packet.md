THE PACKET

Decision kind: recommendation
Subject: #174: recommend rigging the eight never-entered a2 attack chains as a dedicated gate — re-check after run 304
Claim (the working agent's sentence): Recommend building #174's rigs as a DEDICATED gate whose replays live in a new subdirectory of tests/replays/ rather than as new naming parts in tests/replays/naming/, because a gate that globs a corpus follows it — 14z-181's two added naming parts turned three corpus gates red (project gotchas) — and 19 tracked files (gates and tools; git ls-files, t174_corpus_gates.txt) glob the naming corpus. The gate's first step runs each rig on native vs2 and REQUIRES it to enter its chain; only then does it compare ours with native through tools/move_parity.py, which takes both traces and the schedule as paths (its argument parser, lines 274-312), so the replays' directory does not enter it. The rigs are designed from HYPOTHESES (t174_hypotheses.md), none claimed as a finding: six rest on the disassembly with every condition it shows; Pyron a2:0x03 and a2:0x05 rest on no disassembly — the move list's measured note for 0x03 and an inference from it for 0x05 — and a2:0x48's path through 0x28534 is not read. SCOPE: #174's set as re-counted at the 14z-181 close (t174_issue_body.md, the comment: 36 never-entered distinct starts of table a2, 8 with attack records), reproduced by t174_census.txt; tables a, b and c are out of this recommendation. NOT tested: whether any existing gate or tool reaches a new subdirectory of tests/replays/ (t174_replay_walkers.txt is a partial census — walkers with variable bases and gate_follows's reconcile are not traced), to be settled after the rig files land by the static tier and a trace of every walker's base, before any expectation is frozen; every hypothesis — one refuted on native means a rig redesign or a question to the maintainer, not a comparison; the 28 non-attack never-entered a2 starts.
Artifacts (read every one, in full):
  - build/agent184/t174_census.txt
  - build/agent184/t174_hypotheses.md
  - build/agent184/t174_corpus_gates.txt
  - build/agent184/t174_replay_walkers.txt
  - build/agent184/t174_issue_body.md
  - tools/move_parity.py.lines-274-312 (lines 274-312 of tools/move_parity.py)
  - docs/project/gotchas.md.lines-5936-5946 (lines 5936-5946 of docs/project/gotchas.md)
