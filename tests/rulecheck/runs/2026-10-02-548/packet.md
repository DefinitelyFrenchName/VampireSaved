THE PACKET

Decision kind: recommendation
Subject: #195: the hit-time mark's discriminator (attacker id plus class vs the record address)
Claim (the working agent's sentence): Recommendation for #195's discriminator: key the hit-time mark at PRG:0x01868C on the record address (A3 against the seven placed records, hitbox_proj@pyron+0x2E2 and hitbox+0x10D2 to +0x1172 on the probe build, figs_measurer.txt C6) rather than on attacker id plus class, because A0 at that write is the attacker (loaded by movea.w -$4BC6(a5),a0 at 0x01842C, figs_measurer.txt C8; on the two P2-attacker hits of the conditioned legs dual_p2 and r03_p2, run with no INPUT-VIOLATION, A0 is P2's block and A1 is P1's, figs_measurer2.txt C2 and C5), a tenant attacker's +0x382 read 0x11 on 8 of 8 and 0x13 on 10 of 10 probed hits (figs_measurer.txt C3 and C4), and among the probed class-0x44 hits (figs_measurer2.txt C3 and C4) the record address separates Cosmo's record 21 (4 hits at 0x4B01A2) from Pyron's own record 4 (4 hits at 0x4AFF82) and holds the six Ifrit Sword (ES) records 0x3FB862 to 0x3FB902, whereas id plus class would mark Pyron's record 4 unless a further record check is added and rests on legacy fighters never holding a tenant id in +0x382, which the borrow candidate rows 0x10, 0x11 and 0x13 (12 tenant-class bytes of 64 each, figs_measurer.txt C7) allow when a legacy fighter borrows against a tenant opponent (figs_reader.txt, donovan.toml:2305-2310); the address form costs generator work, because both tenants' target hits pass the same write (cosmo_cls.log, ifrit_cls.log), differing rows concatenate in the merge (gen_donovan_patch.py:195-215), two writers of one word are refused (patch_prg.py:85-107), and region_subst fails when its region is not placed (gen_donovan_patch.py:6043-6065), as Pyron's record region is absent from Donovan's solo build (figs_measurer2.txt C7). NOT TESTED: whether any reachable flow makes a legacy fighter borrow against a tenant (12 write-tap legs saw the borrow fire only on rig 90, whose own header says it is a CPU match, writing 0x00 to P1, borrow_table.txt and 90_don_plant.rpl:1-12); moves of the two tenants that no probed rig enters; the generator extension itself; and the hooks' cycle cost, the legacy oracle and the pursuit gate, which follow the build.
Artifacts (read every one, in full):
  - build/agent188/t195/figs_measurer.txt
  - build/agent188/t195/figs_measurer2.txt
  - build/agent188/t195/figs_reader.txt
  - build/agent188/t195/borrow_table.txt
  - build/agent188/t195/tapborrow.sh
  - build/agent188/t195/probe195.sh
  - build/agent188/t195/probe195b.sh
  - build/agent188/t195/probe195e.sh
  - build/agent188/t195/probe195f.sh
  - build/agent188/t195/out/cosmo_a0.log
  - build/agent188/t195/out/ifrit_a0.log
  - build/agent188/t195/out/cosmo_cls.log
  - build/agent188/t195/out/ifrit_cls.log
  - build/agent188/t195/out/dual_p2.log
  - build/agent188/t195/out/r03_p2.log
  - build/manifest/donovan.toml.lines-2300-2320 (lines 2300-2320 of build/manifest/donovan.toml)
  - tools/gen_donovan_patch.py.lines-195-215 (lines 195-215 of tools/gen_donovan_patch.py)
  - tools/gen_donovan_patch.py.lines-6043-6065 (lines 6043-6065 of tools/gen_donovan_patch.py)
  - tools/patch_prg.py.lines-85-107 (lines 85-107 of tools/patch_prg.py)
  - tests/replays/don/90_don_plant.rpl.lines-1-12 (lines 1-12 of tests/replays/don/90_don_plant.rpl)
