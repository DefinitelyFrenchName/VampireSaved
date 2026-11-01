THE PACKET

Decision kind: recommendation
Subject: #294: recommend porting vs2's per-frame routine 0x2A316 for Donovan (A)
Claim (the working agent's sentence): CLAIM: recommend to the maintainer option A for #294 — port vs2's per-character per-frame palette routine 0x2A316 into vsavj's per-frame table PRG:0x02ADEC at row 0x13 with a private copy of vs2's sequence rows, after a first feasibility step (at least 6 proven-dead bytes in PRG:0x022DEC-0x032DEB for the jump), with B (a hook at the dispatcher's head) only as a fallback put back to the maintainer, and #294 closing when that release ships (recommendation_294.md, the deliverable, revised after runs 2026-11-01-1529/-1530/-1531). The maintainer's read is quoted verbatim (capture_read_294.txt); the 2026-07-31 ruling and the 14z-19 report are quoted (history.txt). It rests on: palsum.txt (52 frames f3406-3457 of fresh sprite_capture dumps of both legs: row 0x0C differs f3413-3457 on 45 frames all drawn; rows 0x00, 0x16 and the never-drawn 0x0F differ from f3406; rows 0x01-0x03 equal); rowentries.txt (row 0x00 differs on entries 1-14 every frame and neither leg's row 0x00 changes in the window; native's row 0x0C changes at f3413 and f3452, ours' holds one content); utap_window.txt and native_gaps.txt (native's uploader writes row 0x0C for id 0x13 through f3400-3465 except f3411, RET 0x029B60, palette states 0/4/6; ours none from its listed uploader PCs); dtap_ours_sum.txt (dispatch_tap.lua, a scratch copy of tests/lua/pc_count.lua that applies the rig's POKES and logs A6/+0x382/+0x14E per stop: on ours, Donovan A6=$FF8400 id 0x13 reaches 0x02A7C8, 0x0CC030, 0x02A7D6 and 0x02ADDC on all 66 frames f3400-3465, palette states 0/4/6; 1 call on 51 frames, 2 on 15); dispatch_listing.txt (0x02ADDC indexes 0x02ADEC by the whole id byte) and row13.txt (row 0x13's word 0x0040 -> rts at 0x02AE2C) with engine_internals_1760_1790.txt and audit_id_writers_40_48.txt (no legacy id 0x13 per audit_id_writers; its gap Oboro's 0x18, another row); the rig's pokes are the speed and RNG pins only (legs.sh pokes()), Donovan picked by input; frame_budget.txt (268,288 cycles per frame); issue_294.md; t294 REPORT.md (the routine's static read, the options, the ~600-cycle estimate). NOT TESTED: nothing is built; the routine's behaviour is a static read; the 600 cycles per call is the worker's estimate with no derivation shown, so 2,400 worst in a mirror (about 0.9% of a frame) is derived from it and the measured call count; the call count is measured on ours in this window only; whether the dead bytes exist (unsearched — A's feasibility); which events map to states 2/8/0xC/0xE/0x1C (only 4 and 6 measured), so the Foot Stab (ES) fix rests on #162's worker's reading of 0x1C; the colour-variant count; a legacy writer outside audit_id_writers' corpus giving id 0x13 (the legacy MAME oracle at the freeze, a plan); FBNeo and MiSTer; Donovan as P2; the poke check is the maintainer's capture s2, not a measurement; the record corrections are planned, not made.
Artifacts (read every one, in full):
  - build/agent216/rc294/recommendation_294.md
  - build/agent216/rc294/capture_read_294.txt
  - build/agent216/rc294/palsum.txt
  - build/agent216/rc294/palsum.py
  - build/agent216/rc294/palcmp_3406_3457.txt
  - build/agent216/t294/rig/palcmp.py
  - build/agent216/rc294/rowentries.txt
  - build/agent216/rc294/rowentries.py
  - build/agent216/rc294/utap_window.txt
  - build/agent216/rc294/utap_window.py
  - build/agent216/rc294/native_gaps.txt
  - build/agent216/rc294/dtap_ours_sum.txt
  - build/agent216/rc294/dtap_sum.py
  - build/agent216/rc294/dispatch_tap.lua
  - build/agent216/t294/rig/legs.sh
  - build/agent216/t294/rig/snap.sh
  - build/agent216/t294/rig/utap.sh
  - build/agent216/rc294/dispatch_listing.txt
  - build/agent216/rc294/row13.txt
  - build/agent216/rc294/engine_internals_1760_1790.txt
  - build/agent216/rc294/audit_id_writers_40_48.txt
  - build/agent216/rc294/frame_budget.txt
  - build/agent216/rc294/history.txt
  - build/agent216/rc294/issue_294.md
  - build/agent216/t294/REPORT.md
  - build/agent216/t294/sheets/s1_electrocuted_sword.png
  - build/agent216/t294/sheets/s2_attribution_poke.png
