THE PACKET

Decision kind: recommendation
Subject: #369 design proposal (markers, verdict names, landing order)
Claim (the working agent's sentence): A design proposal for #369 put to the maintainer before any code is written (build/agent224/t369/design.md). It describes what the tree does today, read at HEAD 8464fa3f: tests/lib/classify.sh vs_classify_control falls through to HONOURED and reads no CONTROL FIRED line; three shapes of mode firing exist (the fail-flag closing, 9 lines in build/agent224/t369/failflag_closings.txt; the specific branch, tests/audit_extra_pass.sh:195; the in-gate control section still run under a mode, tests/test_docshape.sh:156-185); the static table build/agent223/postmortem/static_fired/modes.tsv holds 418 modes with no own line in 84 gates and 276 with one (build/agent224/t369/static_modes_own_line_counts.txt). It asks three decisions (A marker, B verdict names, C landing order), recommending A1 (whose cost is that every declared mode migrates: 1,191 in 312 gates at the 14z-223 re-census, STATE.md 14z-223 (8)), B1 and C1, and lists four pieces of work as the ticket (build/agent224/t369/issue369_body.md) asks. NOT TESTED: nothing is built; the share of the 276 that print only from an in-gate section, and the emulator gate count behind the 117 modes, are not measured.
Artifacts (read every one, in full):
  - build/agent224/t369/design.md
  - build/agent224/t369/issue369_body.md
  - build/agent224/t369/failflag_closings.txt
  - build/agent224/t369/mode_var_firings.txt
  - build/agent224/t369/static_modes_own_line_counts.txt
  - build/agent223/postmortem/static_fired/modes.tsv
  - build/agent223/postmortem/wt_static_fired.sh
  - tests/lib/classify.sh
  - tests/lib/controls.sh
  - docs/project/must_fire_contract.md
  - tests/test_docshape.sh
  - tests/audit_extra_pass.sh
  - tests/audit_rng_draws.sh
  - tests/test_agent_defs.sh
  - tests/test_control_classifier.sh
  - tests/run_all_static.sh.lines-560-590 (lines 560-590 of tests/run_all_static.sh)
  - tests/run_all_emulator.sh.lines-675-700 (lines 675-700 of tests/run_all_emulator.sh)
  - STATE.md.lines-170-195 (lines 170-195 of STATE.md)
