THE PACKET

Decision kind: recommendation
Subject: #127 and #162: recommend vs2's mask bit (M) for both
Claim (the working agent's sentence): CLAIM: recommend to the maintainer option (M) for #127 and #162 together — PRG:0x02ADB4 EF92 -> EF9A, vs2's mask bit 0x13 in the palette reload, built through the pipeline and landed at the next freeze — with #127 closing as fixed by (M) instead of its option (B), and #162 closing, when that release ships (recommendation_127_162.md, the deliverable; it replaces recommendation_127.md after runs 2026-11-01-1525/-1526/-1527 and adds #162). The maintainer's engagement rests only on their own messages of 2026-11-01, verbatim: capture_read_127.txt (the right-hand column of sheet_127_pod_hit.png, ours with the bit in MAME's decrypted-opcode share, '-> yes') and capture_read_162.txt ('probe is indeed the correct behavior ...'); the #112 rulings are quoted in rulings_112.txt; nothing else is attributed to the maintainer. It rests on: rig_window.txt (window.py: row 0x0B index 14 fcff native f2994-3096, f111 ours f2995-3096 after writes at f2994/f3017 by PC 0x02AD78, fcff on the bit leg, readback 223cef9a) — the rig and the sheet SHARE a poke of P1 +0x382 := 0x13 at f1400/1450/1500 on all three legs plus speed, RNG and stock pins (t127 REPORT.md section 6); census_cmp.txt (TOTAL: row 0x0B 36676 differing frames ours vs native, 0 with the bit, rows 0x0A 1904 and 0x0C 2363 unchanged) on legs poking no id (census_ids.txt, census_ids.py parsing census.sh's own PK= line and the naming jsons; pod_rig.lua writes only POKES and the OPATCH share); palrows_0b.txt (t162's palrows_cmp.py over pal8270, donovan_4 f2363-8270, the same json pokes and pins via palrows_legs.sh: native vs probe row 0x0B differs on 0 frames drawn or not, readback ef9aef96; native vs ours 77 drawn frames in five runs, the positive control); inert_window.txt (five legacy replays 01/02/03/07/105 identical work RAM and OBJ palette with and without the bit; 109, 109dump and 12_donovan_vs_cpu listed, not counted) with its positive control inert_pc_window.txt (donovan_4: OBJ palette 5365 frames, RAM 1691); engine_internals_1760_1790.txt and audit_id_writers_40_48.txt (btst.l mod 32; no legacy id 0x13 per audit_id_writers, whose stated gap is Oboro's 0x18, bit 0x18, untouched by a change flipping bit 0x13 only); issue_127.md; the worker reports t127 and t162 REPORT.md. NOT TESTED: nothing is built — every 'with the bit' figure is an emulator opcode-share counterfactual; FBNeo and MiSTer; Donovan as P2; whether Donovan reaches the engine palette states writing rows +1..+3 (if so row +2 stays unrestored where native restores it); a legacy writer outside the audit's corpus giving an id with low five bits 0x13 (the legacy MAME oracle at the freeze, a plan); the 0-legacy-cycle cost is by construction and the Donovan saving derived; the (B) estimate is the worker's; why 109 and 12_donovan_vs_cpu show what they show is not established (uncounted; whether replay 12 picks Donovan on this build was not checked); #162's part-4 legs are the naming rig with its json pokes, whose pokes were not re-parsed for that run beyond palrows_legs.sh's PK= line; the maintainer has not read #127's no-hit control sheet; the gate plan is a plan.
Artifacts (read every one, in full):
  - build/agent216/rc127/recommendation_127_162.md
  - build/agent216/rc127/capture_read_127.txt
  - build/agent216/rc162/capture_read_162.txt
  - build/agent216/rc127/rig_window.txt
  - build/agent216/rc127/window.py
  - build/agent216/t127/census/census_cmp.txt
  - build/agent216/rc127/census_ids.txt
  - build/agent216/rc127/census_ids.py
  - build/agent216/t127/rig/census.sh
  - build/agent216/t127/rig/pod_rig.lua
  - build/agent216/rc162/palrows_0b.txt
  - build/agent216/t162/rig/palrows_cmp.py
  - build/agent216/t162/rig/palrows_legs.sh
  - build/agent216/rc127/inert_window.txt
  - build/agent216/rc127/inert_pc_window.txt
  - build/agent216/rc127/inert_window.py
  - build/agent216/rc127/engine_internals_1760_1790.txt
  - build/agent216/rc127/audit_id_writers_40_48.txt
  - build/agent216/rc127/rulings_112.txt
  - build/agent216/rc127/issue_127.md
  - build/agent216/t127/REPORT.md
  - build/agent216/t162/REPORT.md
  - build/agent216/t127/sheet_127_pod_hit.png
