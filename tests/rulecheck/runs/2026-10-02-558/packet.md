THE PACKET

Decision kind: recommendation
Subject: open a ticket: the 14z-87 keep-tenant thunk may make a tenant CPU opponent repeat in 1P arcade
Claim (the working agent's sentence): Recommendation: open a GitHub ticket (bug, single-player only) for a possible defect — in 1P arcade the 14z-87 keep-tenant thunk at PRG:0x0AEF2 may make a tenant CPU opponent repeat — as the maintainer ruled ("Retract and file ticket (Recommended)", maintainer_195.txt). Because: the thunk re-does the displaced move.w and writes the scanned id d1 to (0x382,a1) only when (0x382,a1) does not already hold 0x10, 0x11 or 0x13 (donovan.toml:2219-2235, the thunk_hex row below them); on rig 90, whose own header says it never forms its match and times out into a CPU game (90_don_plant.rpl:1-8), that write fired on P1's +0x382 at f3463 in three tap legs (figs_measurer3.txt C7), it replaced a 0x03 poked at f3300 with 00 by f3470 (figs_measurer3.txt C4), and the value held after it decides the character that loads — 0x03, 0x13 and 0x11 poked at f3480 load Victor, Donovan and Pyron by +0x60, three runs each (figs_measurer3.txt C4, figs_measurer5.txt C5 and C6); the existing gate tests/audit_voice_borrow.sh expects that write to be skipped on the same rig when P1 holds 0x13, the class byte holding 0x13 through its window (audit_voice_borrow.sh:55-58 and its check below line 171); and a tenant is drawn as a CPU opponent only when the player is a tenant (engine_internals.md:320-331). NOT TESTED: that a repeat occurs in play — no 1P arcade run as a tenant past a tenant CPU opponent was measured; whether the CPU side's +0x382 still holds the previous opponent's id when the next rung's write comes; what the in-use mask $FF8110 and the stage $FF8100 do on a skipped write; the first rung of a run, continues and a challenger joining; and whether the 2P path ever reaches the write (no store in nine 2P tap legs, figs_measurer14.txt C1).
Artifacts (read every one, in full):
  - build/agent188/t195/maintainer_195.txt
  - build/manifest/donovan.toml.lines-2203-2250 (lines 2203-2250 of build/manifest/donovan.toml)
  - tests/replays/don/90_don_plant.rpl.lines-1-12 (lines 1-12 of tests/replays/don/90_don_plant.rpl)
  - build/agent188/t195/figs_measurer3.txt
  - build/agent188/t195/figs_measurer5.txt
  - build/agent188/t195/figs_measurer14.txt
  - tests/audit_voice_borrow.sh.lines-1-90 (lines 1-90 of tests/audit_voice_borrow.sh)
  - tests/audit_voice_borrow.sh.lines-160-185 (lines 160-185 of tests/audit_voice_borrow.sh)
  - docs/game/engine_internals.md.lines-318-335 (lines 318-335 of docs/game/engine_internals.md)
