THE PACKET

Decision kind: recommendation
Subject: #195: the hit-time mark's discriminator (attacker id plus class vs the record address)
Claim (the working agent's sentence): Recommendation for #195's discriminator: key the hit-time mark at PRG:0x01868C on the record address (A3 against the seven placed records, hitbox_proj@pyron+0x2E2 and hitbox+0x10D2 to +0x1172 on the probe build, figs_measurer.txt C6) and not on attacker id plus class, because the probe logs show A0 is the attacker at that write (loaded by movea.w -$4BC6(a5),a0 at 0x01842C, figs_measurer.txt C8; A0 followed the attacker in both directions on the 5 legacy hits of dual_write.log, C5), a tenant attacker's +0x382 read 0x11 on 8 of 8 and 0x13 on 10 of 10 hits (C3, C4), and A3 separated Cosmo's record 21 (4 hits at 0x4B01A2) from Pyron's own class-0x44 record 4 (4 hits at 0x4AFF82) and gave the six Ifrit Sword (ES) records 0x3FB862 to 0x3FB902 (C3, C4), whereas the borrow candidate rows 0x10, 0x11 and 0x13 each hold 12 tenant-class bytes of 64 (C7) and are read when a legacy fighter borrows against a tenant opponent (figs_reader.txt, donovan.toml:2305-2310), so id plus class rests on a premise the data does not guarantee; the cost of the address form is generator work, because both tenants hook one shared site, differing rows concatenate in the merge (gen_donovan_patch.py:195-215) and two writers of one word are refused (patch_prg.py:85-107), and region_subst fails when its region is not placed (gen_donovan_patch.py:6043-6065), as the other tenant's region is on a solo track. NOT TESTED: whether any reachable flow makes a legacy fighter borrow against a tenant (12 write-tap legs saw the borrow fire only on rig 90, whose own header says it is a CPU match, writing 0x00 to P1, borrow_table.txt and 90_don_plant.rpl:1-12); which caller each tenant's hit arrives through; the generator extension itself; and the hooks' cycle cost, the legacy oracle and the pursuit gate, which follow the build.
Artifacts (read every one, in full):
  - build/agent188/t195/figs_measurer.txt
  - build/agent188/t195/figs_reader.txt
  - build/agent188/t195/borrow_table.txt
  - build/agent188/t195/tapborrow.sh
  - build/agent188/t195/probe195.sh
  - build/agent188/t195/probe195b.sh
  - build/agent188/t195/probe195d.sh
  - build/agent188/t195/out/cosmo_a0.log
  - build/agent188/t195/out/ifrit_a0.log
  - build/agent188/t195/out/dual_write.log
  - build/manifest/donovan.toml.lines-2300-2320 (lines 2300-2320 of build/manifest/donovan.toml)
  - tools/gen_donovan_patch.py.lines-195-215 (lines 195-215 of tools/gen_donovan_patch.py)
  - tools/gen_donovan_patch.py.lines-6043-6065 (lines 6043-6065 of tools/gen_donovan_patch.py)
  - tools/patch_prg.py.lines-85-107 (lines 85-107 of tools/patch_prg.py)
  - tests/replays/don/90_don_plant.rpl.lines-1-12 (lines 1-12 of tests/replays/don/90_don_plant.rpl)
