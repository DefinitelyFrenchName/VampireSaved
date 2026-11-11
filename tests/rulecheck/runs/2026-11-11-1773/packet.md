THE PACKET

Decision kind: expectation
Subject: #352: audit_release_linux_desktop reads FBNeo's PAUSE overlay and reports a paused leg as not judged, never a mark or sound FAIL; the minimised control a release-time mode
Claim (the working agent's sentence): #352's change can land on main once its commit tier reads GREEN on the commit's tree (the staged tree, with this run's rule-checker records added), which has not run: audit_release_linux_desktop runs every FBNeo capture up to select (paused0, title, select) through tools/desktop_pause_check.py, which renders FBNeo's "PAUSE" overlay from its own font (emu/fbneo/src/burner/sdl/sdl2_inprint.cpp) and requires a bright uniform ink and a dark shadow at every template pixel; a capture carrying it makes that leg print "fbneo: not judged, PAUSED" with X's active window per capture, drops its mark, link and sound judgements, and the gate still exits FAIL; the in-gate muted-stream, unlinked-recorder and wrong-mark controls read a paused FBNeo run DEAD, never as their finding (t352.patch). The new control `minimised` is a CONTROL= mode only, at release, as the maintainer ruled ("build it this way but only as a release-time mode", RULING_352.txt); its in-gate form — the overlay drawn onto a copy of the run's own select capture — is the session's reading of the must-fire contract (must_fire_contract.md "The firing": a passing gate whose declared control did not fire is FAIL), told to the maintainer and not answered (RULING_352.txt). Evidence, all on PILOT's live desktop: at the final staged tree (e931c6ad, tree 20d37c86, 0 lines from the staged code, diff_tested_vs_staged.txt) the plain run with every FBNeo play minimised (a temporary steps edit, restored) prints "fbneo: not judged, PAUSED — ... on: paused0 title" with no FBNeo mark, link or sound line, judges MAME's three, reads muted-stream, unlinked-recorder and wrong-mark DEAD on the pause and minimised FIRED, and exits 1 (pilot_t352d.out), and the plain run unpaused PASSes with all four in-gate controls FIRED (pilot_t352e.out); at 1cb3f88d (2 lines from staged: the wrong-mark guard, added after that tree's paused plain run read wrong-mark FIRED on a paused capture, pilot_t352c.out) CONTROL=muted-stream and CONTROL=unlinked-recorder are classed HONOURED; at 460a2a62 (5 lines from staged: that guard and the static gate's three header lines) CONTROL=minimised exits 1 with "fbneo: not judged, PAUSED" and is classed HONOURED, CONTROL=wrong-mark HONOURED (pilot_t352b.out); the M24 symptom reproduced on the old gate by a minimise, mark 100 of 147 wrong with link and sound passing (pilot_t352.out). The tool's verdict on all 81 real captures (the 14z-217 failure's 34, an unpaused M26 run's 22, three minimised runs with their MAME legs, 25) is PAUSED on 10 and no on 71 (truth_table.tsv); a human looked at 8 of the 81 (the six tiles of sheet_352.png, sent to the maintainer, and three opened one by one) and the tool agrees with each; the 10 PAUSED are the 14z-217 failure's title and select (both copies) and the paused0 and title captures of the three minimised runs; the no verdicts include yellow game art at the overlay's place (ink 140/140, shadow 0/107). The new static gate test_desktop_pause_check PASSes with both modes HONOURED on their own CAUGHT line at the staged tree (static_gate_runs.txt), and the bookkeeping gates PASS on a clean checkout (bookkeeping.txt). Not tested:
- The commit tier on the commit's tree has not run; the commit waits on it.
- The mode runs' HONOURED comes from the pre-#369 fall-through: audit_release_linux_desktop is still on tests/expected/ctl_caught_debt.tsv, so no CONTROL CAUGHT line is required of it; it migrates in a later #369 batch.
- The minimised mode's dead-leg branches (the run broke; no capture to read) are review only, and tests/expected/dead_leg_unjudged_linux.tsv has no row for `minimised` (its other three modes have rows): under a dead xwd it should read NOT JUDGED, not measured.
- CONTROL=minimised and CONTROL=wrong-mark ran at 460a2a62, not at the staged tree; the five lines between are the in-gate wrong-mark guard, which runs only in a plain run, and the static gate's header.
- A pause that begins and ends between two captures is not seen (the tool and the gate header state it).
- Measured on one host: PILOT's GNOME 46 / Xwayland, where XIconifyWindow minimises and the driver's raise-and-focus key step returns focus; other window managers, and whether FBNeo resumes there, are not measured.
- For 73 of the 81 captures the tool's verdict is the only reading; no human looked at them.
- The static gate SKIPs where python has no PIL or emu/fbneo is not checked out; it is in tests/ci_static.txt, not ci_portable.
Artifacts (read every one, in full):
  - build/agent225/t352/RULING_352.txt
  - build/agent225/t352/t352.patch
  - build/agent225/t352/diff_tested_vs_staged.txt
  - build/agent225/t352/truth_table.tsv
  - build/agent225/t352/sheet_352.png
  - build/agent225/t352/pilot_t352.out
  - build/agent225/t352/pilot_t352b.out
  - build/agent225/t352/pilot_t352c.out
  - build/agent225/t352/pilot_t352d.out
  - build/agent225/t352/pilot_t352e.out
  - build/agent225/t352/static_gate_runs.txt
  - build/agent225/t352/bookkeeping.txt
  - docs/project/must_fire_contract.md.lines-44-60 (lines 44-60 of docs/project/must_fire_contract.md)
  - tools/desktop_pause_check.py
  - tests/test_desktop_pause_check.sh
