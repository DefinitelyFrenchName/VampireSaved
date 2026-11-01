THE PACKET

Decision kind: recommendation
Subject: #294: recommend porting vs2's per-frame routine 0x2A316 for Donovan (A)
Claim (the working agent's sentence): CLAIM: recommend to the maintainer option A for #294 — port vs2's per-character per-frame palette routine 0x2A316 into vsavj's per-frame table PRG:0x02ADEC at row 0x13 with a private copy of vs2's sequence rows, after a first feasibility step (at least 6 proven-dead bytes in PRG:0x022DEC-0x032DEB for the jump), with B (a hook at the dispatcher's head) only as a fallback put back to the maintainer, and #294 closing when that release ships (recommendation_294.md, the deliverable). The maintainer's read is quoted verbatim (capture_read_294.txt: sheets s1/s2, 'Yes: Donovan's shock aura is yellow, as it should, but his sword his red on our build, yellow on native.'); the 2026-07-31 ruling and the 14z-19 report are quoted (history.txt). It rests on: palsum.txt (palsum.py over palcmp_3406_3457.txt, written by t294/rig/palcmp.py from fresh sprite_capture dumps of both legs, t294/run/rcp_native and rcp_ours, rig don_electrocuted.rpl, 52 frames f3406-3457: row 0x0C differs f3413-3457 on 45 frames all drawn; rows 0x00, 0x16 and the never-drawn 0x0F differ from f3406; rows 0x01-0x03 not listed, so equal); utap_window.txt (utap_window.py over t294's writer tap u.txt, window f3400-3465: native 162 U lines writing palette row 0x0C for id 0x13, RET 0x029B60, palette states 0/4/6; ours 0 U lines; the PCHIST lines are whole-run counts); the rig's pokes are the speed and RNG pins only (t294/rig/legs.sh pokes()), Donovan picked by input (native real picks, ours the merged cursor path); frame_budget.txt (268,288 cycles per frame, tests/audit_marionette_cost.sh:21); issue_294.md (the ticket's scope and the performance rule); t294 REPORT.md (the routine's static read, the options, the 600-cycle derivation). NOT TESTED: nothing is built; the routine's behaviour is a static read; every cost figure is derived (600 cycles per call, 2,400 worst in a mirror, about 0.9% of a frame; the worker's 1.2% used a wrong ~198k frame); whether the dead bytes exist (unsearched — A's feasibility); which events map to states 2/8/0xC/0xE; the colour-variant count; FBNeo and MiSTer; Donovan as P2; the poke check (native's two words poked into ours) is the maintainer's capture s2, not a measurement; the record corrections (the 2026-07-31 premise, test_don_accent.sh section 3's comment, 14z-171's twin claim) are planned, not made.
Artifacts (read every one, in full):
  - build/agent216/rc294/recommendation_294.md
  - build/agent216/rc294/capture_read_294.txt
  - build/agent216/rc294/palsum.txt
  - build/agent216/rc294/palsum.py
  - build/agent216/rc294/palcmp_3406_3457.txt
  - build/agent216/t294/rig/palcmp.py
  - build/agent216/rc294/utap_window.txt
  - build/agent216/rc294/utap_window.py
  - build/agent216/t294/rig/legs.sh
  - build/agent216/t294/rig/snap.sh
  - build/agent216/t294/rig/utap.sh
  - build/agent216/rc294/frame_budget.txt
  - build/agent216/rc294/history.txt
  - build/agent216/rc294/issue_294.md
  - build/agent216/t294/REPORT.md
  - build/agent216/t294/sheets/s1_electrocuted_sword.png
  - build/agent216/t294/sheets/s2_attribution_poke.png
