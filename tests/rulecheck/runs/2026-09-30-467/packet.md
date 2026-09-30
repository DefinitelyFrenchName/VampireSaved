THE PACKET

Decision kind: recommendation
Subject: open a ticket: Demitri's Chaos Flare differs between vsavj and vsav2 (no port) — a sprite at +47 and node-change timing — and the split reaches an ours-vs-native comparison with Demitri as P2 (after runs 2026-09-30-465 and -466)
Claim (the working agent's sentence): On pristine vsavj against pristine vsav2 with no port in the loop and the level and RNG pinned on both legs, Demitri's Chaos Flare (236+LP) on Victor changes animation nodes on the same frames to +20 and 1-2 frames earlier on vsavj from +45, at both of two inputs (legacy_cf/summary.txt); the capture of +42..+48 (chaos_flare_sheet.png), read by the maintainer, differs at frame 47 only, and the maintainer confirms a SPRITE difference, not that the boxes the engine uses differ (DECISIONS_HISTORY.md, the capture read); the same kind of split is the first ours-vs-native difference in probe p3_don's event 7 on merged-m21 (whole-set key a97d1ace, merged29_fingerprint.txt): P2 Demitri's node changes at +75 on ours against +76 on native while Donovan's node, seq and x match through +80 and P2's HP through +79, and Change Immortal's hit on P2 lands at +81 against +80 only after it (ci_split_frames.txt), both traces reproducing byte for byte (p3_repeat_sha.txt); the ours-vs-native parity rigs use Demitri as P2 on a static chain census that lists his table-a chains as not differing (DECISIONS_HISTORY.md 'the parity rigs' P2 is DEMITRI', same_data_p2.tsv), which this split questions; this justifies a ticket to measure whether the boxes or the move's properties differ or only the art, where the timing difference comes from, and which frozen parity rows it reaches; NOT tested: the mechanism (art retouched on vs2, or engine timing such as hit-freeze), the boxes, Demitri's other moves and strengths, a victim other than Victor, whether any frozen parity row already contains it, and FBNeo.
Artifacts (read every one, in full):
  - build/agent186/legacy_cf/summary.txt
  - build/agent186/legacy_cf/run.sh
  - build/agent186/legacy_cf/legacy_cf.rpl
  - build/agent186/legacy_cf/vsavj/f.ft
  - build/agent186/legacy_cf/vsav2/f.ft
  - build/agent186/legacy_cf/snap.sh
  - build/agent186/legacy_cf/chaos_flare_sheet.png
  - DECISIONS_HISTORY.md.lines-38-38 (lines 38-38 of DECISIONS_HISTORY.md)
  - DECISIONS_HISTORY.md.lines-1394-1409 (lines 1394-1409 of DECISIONS_HISTORY.md)
  - tests/expected/same_data_p2.tsv.lines-1-3 (lines 1-3 of tests/expected/same_data_p2.tsv)
  - build/agent186/ci_split_frames.txt
  - build/agent186/p3_don/tr_native.txt
  - build/agent186/p3_don/tr_ours.txt
  - build/agent186/p3_don/parity.tsv
  - build/agent186/merged29_fingerprint.txt
  - build/agent186/p3_repeat_sha.txt
  - build/agent186/don_c184c.json
  - build/agent186/t184_legs.sh
