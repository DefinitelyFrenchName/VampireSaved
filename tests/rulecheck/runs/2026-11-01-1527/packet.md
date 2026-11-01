THE PACKET

Decision kind: recommendation
Subject: #127: recommend vs2's mask bit (M) instead of option (B)
Claim (the working agent's sentence): CLAIM: recommend to the maintainer option (M) for #127 — PRG:0x02ADB4 EF92 -> EF9A, vs2's mask bit 0x13 in the palette reload, built through the pipeline and landed at the next freeze — instead of the ticket's option (B), with #127 closing as fixed by (M) when that release ships (recommendation_127.md, the deliverable, revised after runs 2026-11-01-1525 and -1526). It rests on: the maintainer's verbatim read that the right-hand column of sheet_127_pod_hit.png (ours with the bit set in MAME's decrypted-opcode share) is the Press of Death they expect (capture_read_127.txt); rig_window.txt (window.py over the three rig legs: row 0x0B index 14 fcff on native f2994-3096, f111 on ours f2995-3096 after writes at f2994 and f3017 by PC 0x02AD78, fcff on the bit leg, readback 223cef9a) — the rig and the sheet SHARE a poke of P1 +0x382 := 0x13 at f1400/1450/1500 on all three legs, plus speed, RNG and stock pins (t127 REPORT.md section 6); census_cmp.txt (TOTAL: row 0x0B 36676 differing frames ours vs native, 0 with the bit, rows 0x0A 1904 and 0x0C 2363 unchanged) on legs that poke no id: census_ids.txt (census_ids.py reads each part's naming json pokes and parses census.sh's own PK= line, printed verbatim: no poke touching $FF878x; pod_rig.lua writes memory only from POKES and the OPATCH share; P1 reaches id 0x13 at f1160 native and f1258 ours on every part, the naming parts' shared select prologue); inert_window.txt (inert_window.py over #162's legs: five legacy replays 01/02/03/07/105 identical work RAM and OBJ palette every frame with and without the bit; 109, 109dump and 12_donovan_vs_cpu listed, not counted) with its positive control inert_pc_window.txt (the same legacy_inert.sh on census donovan_4: OBJ palette differs on 5365 frames, RAM on 1691); engine_internals_1760_1790.txt (the reload, the masks, btst.l mod 32, no legacy id 0x13 per audit_id_writers) and audit_id_writers_40_48.txt (that audit's stated gap: Oboro's 0x18 unreached — bit 0x18, untouched by a change that flips bit 0x13 only); rulings.txt (the #112 rulings quoted; the 14z-216 entry); labels_127.tsv (the parked label's removal 2026-10-31T22:33:33Z by DefinitelyFrenchName) with gotchas_478_483.txt (the tree's statement that DefinitelyFrenchName is the maintainer's account and mechanyaa-ai the session's) — the maintainer's own words, 'I unparked 4 tickets on github', name no ticket, so that #127 is among them rests on that label event, and nothing here attributes more to the maintainer than their quoted words; issue_127.md; the worker reports t127 and t162 REPORT.md. NOT TESTED: nothing is built — every 'with the bit' figure is an emulator opcode-share counterfactual; FBNeo and MiSTer; Donovan as P2; whether Donovan reaches the engine palette states writing rows +1..+3; a legacy writer outside the audit's corpus giving an id with low five bits 0x13 (the legacy MAME oracle at the freeze, a plan); the 0-legacy-cycle cost is by construction and the Donovan saving derived; the (B) estimate is the worker's; why 109 shows no palette difference and why 12_donovan_vs_cpu shows no difference at all are not established (both uncounted; whether replay 12 picks Donovan on this build was not checked); the maintainer has not read the no-hit control sheet nor #162's sheets, so #162 is named as also changed, not recommended here; the gate plan is a plan.
Artifacts (read every one, in full):
  - build/agent216/rc127/recommendation_127.md
  - build/agent216/rc127/capture_read_127.txt
  - build/agent216/rc127/rig_window.txt
  - build/agent216/rc127/window.py
  - build/agent216/t127/census/census_cmp.txt
  - build/agent216/rc127/census_ids.txt
  - build/agent216/rc127/census_ids.py
  - build/agent216/t127/rig/census.sh
  - build/agent216/t127/rig/pod_rig.lua
  - build/agent216/rc127/inert_window.txt
  - build/agent216/rc127/inert_pc_window.txt
  - build/agent216/rc127/inert_window.py
  - build/agent216/rc127/engine_internals_1760_1790.txt
  - build/agent216/rc127/audit_id_writers_40_48.txt
  - build/agent216/rc127/rulings.txt
  - build/agent216/rc127/labels_127.tsv
  - build/agent216/rc127/gotchas_478_483.txt
  - build/agent216/rc127/issue_127.md
  - build/agent216/t127/REPORT.md
  - build/agent216/t162/REPORT.md
  - build/agent216/t127/sheet_127_pod_hit.png
