THE PACKET

Decision kind: expectation
Subject: #118: audit_mizuumi_struct (C9-C14) re-checked on main after the struct-only merge — run 2026-10-08-907's claim, main's own files
Claim (the working agent's sentence): On pristine vsavj under the pinned reference MAME, On main after cherry-picking the struct-only commit ceed1833 (the files byte-identical to bcde6cd0, build/agent196/t118/mergecheck/check.txt): tests/expected/mizuumi_struct.tsv at bcde6cd0 holds the 84 data lines frozen at 34c84efe unchanged (build/agent196/t118/rec4/struct_first84_vs_34c84efe.txt, diff exit 0) followed by what tests/audit_mizuumi_struct.sh measured for C9-C14 (+0x3B0, +0x3B6, +0x3B2/+0x3E2, +0x3E1, +0x390 and their role-attributed writers), judged against both HP words, the KOs, the round timer and each replay's own input script; at all 10 KOs of 02, 37, 05, 105, 128 and 26 each side's human/CPU label is the game's +0x380 on the KO frame, and C10b holds it, one verdict per leg, to two derivations from the script that never read +0x380 — the side's own START pressed after its last loss (which decides the idle sides: 02, 05 and 26's P2 never started, 128's P2 not restarted after f4791) and a side the script drives in that match reading human — with 0 violations; C10 judges only that the loser reads 0, that 0x019152 writes the winner once on the KO frame and that the time-overs of 03 and 104 read 0, the winner's value frozen and not judged (the four CPU winners read 3, 3, 3 and 0, the six human winners 0 five times and 1 once, so control does not decide it); the run of record PASSed from a clone with zero changed or untracked files before and after (build/agent196/t118/rec4/clone_clean.txt) with controls sides-swapped, refutation-pokes, roles-inverted (failing C10b on each of the six KO legs), poke-3b6 and p2-confirm firing in-gate and failing as modes; NARROWED where it could not be defended: the cause of +0x3B6's value (the static writer's derivation is named, not measured per hit); NOT tested: the ~70 other unadopted candidates, +0x130's per-fighter offset, what +0x15A, +0x18D, +0x3B0 and +0x3B6 are, the finish type behind +0x3BE/+0x3BF, the per-character slots for characters this corpus does not play, a 1P match a human wins for C1-C9 and C11-C13, C9 beyond the six single-outcome legs, C14's AUTO and palette writers on the multi-match legs 128 and 26, the START rule beyond these six replays, whether AUTO's 8 in +0x3E1 adds to K-1, +0x390 beyond replay 02, merged-m23 and FBNeo.
Artifacts (read every one, in full):
  - tests/audit_mizuumi_struct.sh
  - tests/expected/mizuumi_struct.tsv
  - docs/game/atlas/ram.md.lines-160-169 (lines 160-169 of docs/game/atlas/ram.md)
  - tests/replays/128_shadow_vs_legacy_vsavj.rpl
  - tests/replays/05_timeout_idle.rpl
  - tests/replays/26_don_arcade_mash.rpl.lines-1-40 (lines 1-40 of tests/replays/26_don_arcade_mash.rpl)
  - build/agent196/t118/rec4/struct_first84_vs_34c84efe.txt
  - build/agent196/t118/rec4/clone_clean.txt
  - build/agent196/t118/rec4/audit_mizuumi_struct.log
  - build/agent196/t118/rec4/audit_mizuumi_struct__roles-inverted.log
  - build/agent196/t118/rec4/audit_mizuumi_struct__poke-3b6.log
  - build/agent196/t118/rec4/audit_mizuumi_struct__p2-confirm.log
  - build/agent196/t118/rec4/audit_mizuumi_struct__sides-swapped.log
  - build/agent196/t118/rec4/audit_mizuumi_struct__refutation-pokes.log
  - build/agent196/t118/mergecheck/check.py
  - build/agent196/t118/mergecheck/check.txt
  - build/agent196/t118/mergecheck/control.txt
