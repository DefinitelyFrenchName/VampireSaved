THE PACKET

Decision kind: recommendation
Subject: #194 Cosmo class 0x44, and the +0x117 residual
Claim (the working agent's sentence): Recommended: adopt Cosmo Disruption's record class 0x44 in place of 0x4F (the one byte of probe194b_manifest.diff; one byte differs from merged-m21 and one from pyron-m26, probe194b_bytes.txt), staged for the next freeze after the legacy oracle runs on it, and ticket the pursuit gap separately — because on the pyron_4 parity rig (the gate's own replays and pokes, level 6 from 2000, RNG 0000 from 2363) probe 194b equals native vs2 in P2's HP words, seq/sub and timeline on every traced frame +90..+218 where M21 leaves the knockdown at +140 (cls4_summary.txt), turns all five Cosmo rows of audit_move_parity IDENT with every other verdict unchanged (mp_m21.got.tsv against mp_probe2.got.tsv), and the maintainer read its capture as native (maintainer_14z187.txt); and the one residual, P2's +0x117 (vs2 writes it for class 0x51 alone, dis117.txt), is READ by the attacker-side pursuit check on +169..+180 natively (rtap117_summary.txt) and gates Pyron's pursuit after Cosmo: pressed at +170 it connects natively and never starts on M21 or on the probe, while a pursuit off a throw is identical on all three legs and, with no pursuit pressed, the probe's P2 path equals native's (pursuit_summary.txt, p2path_all.txt, rig194.py) — so the probe changes nothing about the pursuit gap, which M21 already has. NOT tested: the merged legacy oracle and the freeze gates on the probe, the solo Pyron probe run in an emulator (built only), victims other than Demitri, pursuit buttons other than LP, Pyron as P2, FBNeo, every other reader of +0x117 (only the reads in this window were tapped), and whether Donovan's deity states (the same 0x51->0x44 remap, 14z-110b) carry the same pursuit gap.
Artifacts (read every one, in full):
  - build/agent187/t194/probe194b_manifest.diff
  - build/agent187/t194/probe194b_bytes.txt
  - build/agent187/t194/cls4_summary.txt
  - build/agent187/t194/cls4.sh
  - build/agent187/t194/mp_m21.got.tsv
  - build/agent187/t194/mp_probe2.got.tsv
  - build/agent187/t194/maintainer_14z187.txt
  - build/agent187/t194/dis117.txt
  - build/agent187/t194/rtap117_summary.txt
  - build/agent187/t194/rtap117_sum.py
  - build/agent187/t194/rtap117.sh
  - build/agent187/t194/pursuit_summary.txt
  - build/agent187/t194/pursuit_sum.py
  - build/agent187/t194/p2path_all.txt
  - build/agent187/t194/rig194.py
  - build/agent187/t194/snap3/cosmo_full_sheet.png
  - build/agent187/t194/psnap/pursuit_sheet.png
