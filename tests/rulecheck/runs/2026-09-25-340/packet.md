THE PACKET

Decision kind: expectation
Subject: #178: freeze Donovan's CONTACT row in tests/expected/df_moves.tsv and close #178 as done
Claim (the working agent's sentence): Freeze tests/expected/df_moves.tsv with one added row, donovan_dfx4 ev1 "Hop Kick in DF, P2 near", and close GitHub #178 as `done`. The row reads DIFFER(p1meter): native=[(12, 1)]@[9] m1=[18], ours=[(12, 1)]@[9] m1=[], m2 [8] on both (df_moves.diff). The rest of the file is unchanged but for its header's build name. It was measured by FREEZE=1 with the extended tests/audit_df_moves.sh (gate.diff) and verified by a plain run: PASS, all ten controls fired (gate_freeze.log, gate_plain.log). Each control, the new contact-emptied included, FAILs the gate as a mode (the gate_<control>.log files). What was added: the event is Hop Kick inside Donovan's Dark Force (ours P+K, native his vs2 EX install, the mode asserted entered on both legs by the gate) with P2's far x pin moved to 640, as the gate already does for Phobos's contact rows; a CONTACT rule refuses the event if either leg has no hit. The probe (probe1.log) found the same hit at P2 640, 680 and 700. The existing far-pin row (donovan_dfx2 ev22) stays SAME with no hit on either leg. The only difference is P1's gauge, native +18 and ours none, which is the ruled no-gauge-in-DF rule. The capture (hopkick_sheet.png) was read by the maintainer, "Same, confirmed; close #178 (Recommended)" (maintainer_178.txt). #178's ask (issue178.txt) is a rig where Hop Kick connects inside Donovan's Dark Force on both legs, comparing hits, damage and class, with a control that an empty SAME cannot pass. The docs (docs.diff) record the fact and a gotcha. NOT tested: that the named move came out AS Hop Kick (the gate's stated limit: it compares hits, and the capture shows the kick); any P2 pin other than 640, 680 and 700; Hop Kick's hitbox or frame data beyond the first hit; any other P2 character; Donovan as P2; FBNeo and the MiSTer lane; the static tier on this commit (it runs before the commit).
Artifacts (read every one, in full):
  - build/agent185/t178/gate.diff
  - build/agent185/t178/df_moves.diff
  - build/agent185/t178/gate_freeze.log
  - build/agent185/t178/gate_plain.log
  - build/agent185/t178/gate_contact-emptied.log
  - build/agent185/t178/gate_hit-dropped.log
  - build/agent185/t178/gate_pins-unpinned.log
  - build/agent185/t178/gate_mode-lost.log
  - build/agent185/t178/probe1.log
  - build/agent185/t178/hopkick_sheet.png
  - build/agent185/t178/maintainer_178.txt
  - build/agent185/t178/issue178.txt
  - build/agent185/t178/docs.diff
