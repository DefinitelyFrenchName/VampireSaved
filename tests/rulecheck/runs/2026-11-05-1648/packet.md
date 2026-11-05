THE PACKET

Decision kind: expectation
Subject: freeze tests/audit_beam_slide.sh: #363 as the bug stands (Phobos's ES Plasma Beam slides the victim +81 px on ours, ends +49 px; native vs2 holds him), two controls; with the FIELDS_EXTRA census knob on audit_move_parity and tools/move_parity_p2x.py (14z-221b)
Claim (the working agent's sentence): The new gate tests/audit_beam_slide.sh (audit_beam_slide.sh) can be frozen as written, expecting #363's bug as it stands, with its two controls as declared. Its frozen figures come from measurements: the reaction-table rows it reads in step 0 (vsavj and ours 0x02385C rows 0x00/0x4E/0x4F all 0x0238FC; vsav2 0x022388 rows 0x022430/0x0226E0/0x02296C) are what plain.log prints from the images. The first 0x4F frames 2640 and 2880, native's constant P2 x with sub 08, ours' +81 slide with seq 02 and the +49 end offset are what the gate's own traces show (gate_native.st, gate_ours.st, f2638-2656 and the windows) and agree with the investigation's tap (inv_native.fig.txt, inv_ours.fig.txt: x 0x2D8 to 0x329 on ours, 0x2D8 constant on native) and with the census rows huitzil_4:0 and :1 (p2x_events.tsv: end 49, max 81). Both legs get the part's own pokes; the X pins (2560/2800/3040) fall outside the two judged windows [2600, 2800) and [2840, 3040), and P2's HP, which the part pins at 2950 inside the KK window, is compared on the last frame before the window's first HP pin (f2799 and f2949: 0x111 and 0x102 on both legs, plain.log; fixed after rule-checker run 2026-11-05-1647 found the compare at f3039 forced to agree). Runs at the working tree on the Mac: plain PASS with both in-gate controls FIRED (plain.log); CONTROL=held and CONTROL=class-cleared each FAIL and classify HONOURED (mode_held.log, mode_class-cleared.log); each mode with MAME_BIN=/usr/bin/false classifies UNJUDGED (dead_held.log, dead_class-cleared.log); the plain run on a dead emulator FAILs (dead_plain.log); an undeclared mode is REFUSED, exit 3 (mode_bogus.log). On PILOT at scratch commit 090acd0d (the working tree's tracked changes plus the three new files, parent 0ddac362, pilot_prep_status.txt; its ' M emu/fbneo' is the submodule's working-tree content at the pinned commit, pilot_submodule.txt) the same seven runs give the same results (pilot_runs.txt, seven lines; pilot_dead_plain.out), and the gate's blob there is the working tree's (pilot_blobs.txt). The census that found the slide is made rerunnable without freezing anything: tests/audit_move_parity.sh gains an opt-in FIELDS_EXTRA knob (move_parity_knob.diff) that appends traced fields and is refused under FREEZE=1 (knob_freeze_refused.log, exit 3); the gate run ALL=1 with FIELDS_EXTRA=ff8810:w:p2x,ff8814:w:p2y PASSES (knob_run.sh is the command, knob_gate.log its output; a kept trace line with p2x/p2y is quoted in knob_vs_investigation.diff); and tools/move_parity_p2x.py (move_parity_p2x.py, which differs from the investigation script only in its docstring, usage line and REPO line, p2x_tool_vs_scratch.diff) reproduces the investigation's 526-event table byte for byte from those traces (knob_p2x_events.tsv, knob_vs_investigation.diff: the diff of the two named files, exit 0, 527 lines each). Captures: the maintainer was sent three beam pages together (sent_beam_sheets.txt: 358_zoom_corner.png, 358_beam_3row_p1.png, 358_beam_3row_p2.png) and read them before the slide was measured (quotes.txt, item 0); those pages have no frame inside the slide (f2642-2654). The maintainer then ruled the finding mechanical on the agent's figure, 49 px (item 1), with no picture of the slide in front of them. A capture of the slide itself (363_slide_p1.png, p2: every frame f2638-2655; p3: the launch to f2799; native above ours, tools/naming_pair_sheet.sh) was made and sent to the maintainer before this freeze (sent_slide_clip.txt). The +81 and +49 figures rest on the traces, not on pixels. The maintainer asked for this work (quotes.txt, item 3) and ruled the ticket's form (item 2); freezing the bug state rather than native's behaviour follows the proposal quoted in item 3. NOT TESTED: the maintainer's read of the slide capture (sent, not yet answered); the gate on FBNeo or MiSTer; other moves carrying class 0x4E or 0x4F; row 0x4E's handler; Demitri as P1; a dead leg that runs partway and then dies (only an emulator that exits at once was used); the gate and the knob under the emulator runner (run_all_emulator.sh); the gates' controls beside other gates' controls (write-traced on PILOT for the concurrent-controls list, pilot_overlap.txt and pilot_overlap_move_parity_6993aef7.txt: SAFE; not part of this freeze).
Artifacts (read every one, in full):
  - build/agent221/t358/rc/audit_beam_slide.sh
  - build/agent221/t358/rc/beam_slide_tap.lua
  - build/agent221/t358/rc/plain.log
  - build/agent221/t358/rc/gate_native.st
  - build/agent221/t358/rc/gate_ours.st
  - build/agent221/t358/rc/inv_native.fig.txt
  - build/agent221/t358/rc/inv_ours.fig.txt
  - build/agent221/t358/rc/p2x_events.tsv
  - build/agent221/t358/rc/mode_held.log
  - build/agent221/t358/rc/mode_class-cleared.log
  - build/agent221/t358/rc/dead_held.log
  - build/agent221/t358/rc/dead_class-cleared.log
  - build/agent221/t358/rc/dead_plain.log
  - build/agent221/t358/rc/mode_bogus.log
  - build/agent221/t358/rc/pilot_runs.txt
  - build/agent221/t358/rc/pilot_prep_status.txt
  - build/agent221/t358/rc/move_parity_knob.diff
  - build/agent221/t358/rc/knob_freeze_refused.log
  - build/agent221/t358/rc/knob_gate.log
  - build/agent221/t358/rc/move_parity_p2x.py
  - build/agent221/t358/rc/p2x_tool_vs_scratch.diff
  - build/agent221/t358/rc/knob_p2x_events.tsv
  - build/agent221/t358/rc/knob_vs_investigation.diff
  - build/agent221/t358/rc/quotes.txt
  - build/agent221/t358/rc/358_beam_3row_p1.png
  - build/agent221/t358/rc/358_beam_3row_p2.png
  - build/agent221/t358/rc/pilot_dead_plain.out
  - build/agent221/t358/rc/pilot_submodule.txt
  - build/agent221/t358/rc/knob_run.sh
  - build/agent221/t358/rc/pilot_overlap.txt
  - build/agent221/t358/rc/358_zoom_corner.png
  - build/agent221/t358/rc/sent_beam_sheets.txt
  - build/agent221/t358/rc/363_slide_p1.png
  - build/agent221/t358/rc/363_slide_p2.png
  - build/agent221/t358/rc/363_slide_p3.png
  - build/agent221/t358/rc/sent_slide_clip.txt
  - build/agent221/t358/rc/pilot_blobs.txt
  - build/agent221/t358/rc/pilot_overlap_move_parity_6993aef7.txt
