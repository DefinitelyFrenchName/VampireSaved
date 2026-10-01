THE PACKET

Decision kind: build
Subject: #194 stage Cosmo class 0x44 for the next freeze
Claim (the working agent's sentence): Stage build/manifest/staged/194_cosmo44.patch (Pyron's Cosmo Disruption record class 0x4F -> 0x44 in build/manifest/pyron.toml, every track) for the next freeze, as the maintainer ruled (maintainer_14z187.txt), because: the patched manifest builds the merged set fingerprinted 702c98d0, the same as probe 194b (staged_identity.txt), which differs from merged-m21 by one byte and from pyron-m26 by one (probe194b_bytes.txt); on the pyron_4 parity rig probe 194b equals native vs2 on every traced P2 field +90..+218 except +0x117 (cls4_summary.txt; traced: both HP words, class, seq/sub, node, the exception store, +0x117) and turns the five Cosmo rows of audit_move_parity IDENT with every other verdict unchanged (mp_m21.got.tsv, mp_probe2.got.tsv); the merged legacy oracle on the probe PASSES against tests/expected/merged-m21 with the 47 verdict lines it shares with the M21 freeze run identical and six more PASS (oracle_window.txt); the 14z-75 crash gate test_pyron_cosmo passes on the solo probe as on pyron-m26 (cosmo_gate_probe.log, cosmo_gate_m26.log); and the +0x117 residual, which gates Pyron's pursuit after Cosmo (pursuit_cf_summary.txt: poked 1 on the probe it gives native's pursuit, poked 0 on native it removes it), is unchanged from M21 and ticketed (#195). NOT tested: the freeze's own gates and the reproducibility gate on the patched tree (they run at the freeze), the solo Pyron probe in any rig but the crash gate, P2 state outside the traced fields, other consumers of class 0x51/0x44 beyond the 14z-110b five, victims other than Demitri, Pyron as P2, FBNeo and the MiSTer core.
Artifacts (read every one, in full):
  - build/manifest/staged/194_cosmo44.patch
  - build/agent187/t194/staged_identity.txt
  - build/agent187/t194/probe194b_bytes.txt
  - build/agent187/t194/cls4_summary.txt
  - build/agent187/t194/cls4.sh
  - build/agent187/t194/mp_m21.got.tsv
  - build/agent187/t194/mp_probe2.got.tsv
  - build/agent187/t194/oracle_window.txt
  - build/agent187/t194/cosmo_gate_probe.log
  - build/agent187/t194/cosmo_gate_m26.log
  - build/agent187/t194/pursuit_cf_summary.txt
  - build/agent187/t194/pursuit_cf.py
  - build/agent187/t194/maintainer_14z187.txt
  - build/manifest/donovan.toml.lines-1488-1512 (lines 1488-1512 of build/manifest/donovan.toml)
