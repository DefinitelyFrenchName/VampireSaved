THE PACKET

Decision kind: expectation
Subject: #352: audit_release_linux_desktop reads FBNeo's PAUSE overlay and reports a paused leg as not judged, never a mark or sound FAIL; the minimised control a release-time mode
Claim (the working agent's sentence): #352's change can land on main with its commit tier GREEN: audit_release_linux_desktop runs every FBNeo capture up to select (paused0, title, select) through tools/desktop_pause_check.py, which renders FBNeo's "PAUSE" overlay from its own font (emu/fbneo/src/burner/sdl/sdl2_inprint.cpp) and requires a bright uniform ink and a dark shadow at every template pixel; a capture carrying it makes that leg print "fbneo: not judged, PAUSED" with X's active window per capture, drops its mark, link and sound judgements, and the gate still exits FAIL (t352.patch). The new control `minimised` is a CONTROL= mode only, at release, as the maintainer ruled ("build it this way but only as a release-time mode", RULING_352.txt); its in-gate form — the overlay drawn onto a copy of the run's own select capture — is the session's reading of the must-fire contract (must_fire_contract.md "The firing": a passing gate whose declared control did not fire is FAIL), told to the maintainer and not answered (RULING_352.txt). Evidence: the tool's verdict on all 81 real captures (the 14z-217 failure's 34, an unpaused M26 run's 22, three FBNeo runs minimised 3 s after launch with their MAME legs, 25) is PAUSED on exactly the 10 that show the overlay and no on the other 71, yellow game art at the same place among them (truth_table.tsv; the human reading on sheet_352.png, shown to the maintainer); on PILOT's live desktop at scratch 460a2a62 (pilot_t352b.out) the plain run PASSes with all four in-gate controls fired, CONTROL=minimised exits 1 with "fbneo: not judged, PAUSED — ... on: paused0 title" and is classed HONOURED, CONTROL=wrong-mark is classed HONOURED as before; the minimised run's reproduction of the M24 symptom without the change is pilot_t352.out (mark 100 of 147 wrong, link and sound passing); the new static gate test_desktop_pause_check PASSes with both modes HONOURED on their own CAUGHT line at the staged tree (static_gate_runs.txt); the bookkeeping gates PASS on a clean checkout (bookkeeping.txt); the files PILOT ran differ from the staged ones only in the static gate's three header lines (diff_tested_vs_staged.txt). Not tested:
- The minimised mode's HONOURED comes from the pre-#369 fall-through: audit_release_linux_desktop is still on tests/expected/ctl_caught_debt.tsv, so no CONTROL CAUGHT line is required of it; it migrates in a later #369 batch.
- The new pause guards on the in-gate muted-stream and unlinked-recorder controls (a paused FBNeo run is read dead, never the control's finding) never met a paused run: review only.
- The minimised mode's dead-leg branches (the run broke; no capture to read) are review only, and tests/expected/dead_leg_unjudged_linux.tsv has no row for `minimised` (its other three modes have rows): under a dead xwd it should read NOT JUDGED, not measured.
- A pause that begins and ends between two captures is not seen (the tool and the gate header state it).
- Measured on one host: PILOT's GNOME 46 / Xwayland, where XIconifyWindow minimises and the driver's raise-and-focus key step returns focus; other window managers, and whether FBNeo resumes there, are not measured.
- The static gate SKIPs where python has no PIL or emu/fbneo is not checked out; it is in tests/ci_static.txt, not ci_portable.
Artifacts (read every one, in full):
  - build/agent225/t352/RULING_352.txt
  - build/agent225/t352/t352.patch
  - build/agent225/t352/diff_tested_vs_staged.txt
  - build/agent225/t352/truth_table.tsv
  - build/agent225/t352/pilot_t352.out
  - build/agent225/t352/pilot_t352b.out
  - build/agent225/t352/static_gate_runs.txt
  - build/agent225/t352/bookkeeping.txt
  - docs/project/must_fire_contract.md.lines-44-60 (lines 44-60 of docs/project/must_fire_contract.md)
  - tools/desktop_pause_check.py
  - tests/test_desktop_pause_check.sh
