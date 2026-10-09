THE PACKET

Decision kind: expectation
Subject: tests/expected/mizuumi_chars.tsv first frozen (GitHub #118, HOMING item 5), branch t118-196 at 4f0bfb8c — re-prepared after runs 2026-10-08-902 to -913
Claim (the working agent's sentence): On pristine vsavj under the pinned reference MAME over 18 legs (the five rigs and the 14z-194 pilot's 13 census replays, each played by a field run and a write-tap run, and the flare leg and 128 also by a read run), tests/expected/mizuumi_chars.tsv at 4f0bfb8c is what tests/audit_mizuumi_chars.sh and tools/mizuumi_chars.py measured for K0, K0b, K0c, KA, KS, KR and K1-K12; every run a check joins to the field run is tied to it by STATE that depends on the input — KS: both sides' X and HP rebuilt from each write-tap run's own writes equal the field run's samples on every frame from frame 8 of all 18 legs (control tap-other-game); KR: both sides' +0x0AC and +0x154 rebuilt from each read run's own writes equal them on every frame from frame 8 of both read legs, where those bytes change 6 times (flare leg) and 14 times (128) (control read-other-game, which swaps only the flare leg's read run and diverges there on 11 frames from f3409, so 128's tie rests on its 14 changes, not on a control) — and KA shows only that the logs are frame-aligned (control tap-misaligned); frames 1-7 are not compared; K0c holds rows 0x00-0x0F of vsavj's base table PRG:0x0BD97A to 16 distinct bases (control dup-base); K3, K8 and K12 credit each write from the same write-tap run by the +0x60 base THAT run last wrote, and NARROWED to what was measured they credit a write to the character of the BLOCK it lands in, not to the code that ran (Morrigan's kick throw at PRG:0x03B2DA writes the victim's +0x19A and is credited to the victim); K12's 124 writer PCs over +0x34..+0x37 / +0x360..+0x37F each write only into blocks that held one character, the CLEAR set it skips (PRG:0x000Dxx, 0x016E4C/E — the block init that writes every loading character's block — 0x0222DA, 0x026Exx/0x026Fxx) being held by its detector to writing only 0 there, but the boot RAM test 0x000D34's 0xFF, all 1,296 of which land before the run's first character load (control clear-nonzero); the remaining checks read the character from the FIELD run's +0x60 base against that table, a base in no row reading as unloaded, never as +0x382; only K0b reads +0x382, equal to the base on 197,917 of 197,992 in-match side-frames, the other 75 forming three spans on a CPU side after the round timer reached 0 whose +0x382 is the character that side loads next (3/3; controls prewrite-human and next-load-wrong); K0 proves both forced picks by the base (control wrong-base); the docs/game/atlas/ram.md rows this gate provenances state the CLEAR exclusion where they depend on it and were compared to the frozen lines BY HAND at this commit — a script lists every PRG address they cite against the tsv (only the static +0x15C routine 0x029930/0x029984 absent) and the writer lists were read against the frozen lines (the one drift found, +0x366's missing 0x03207E, corrected) — but NO check reads ram.md, a named gap; the run of record PASSed from a clone with zero changed or untracked files before and after (build/agent196/t118/rec10/clone_clean.txt) with controls absent-move, clear-nonzero, dup-base, wrong-owner, prewrite-human, tap-misaligned, tap-other-game, read-other-game, next-load-wrong, wrong-base, pool-miscount, passes-inflated, fall-shifted, taps-as-dashes and other-side-credit firing in-gate and failing as modes; TYPE149 was read off these same legs and +0x372's value is reported, not judged; NOT tested: that ram.md stays equal to the tsv after this commit, whether the runs agree on state other than the compared words, an other-game control on 128's read run, which character's CODE writes any byte, the STATIC facts the ram.md rows also carry (the +0x15C routine, that +0x154 and +0x0AC are read on the opponent through +0x32), +0x15C's dizzy-versus-hold distinction and random amounts, +0x14B for Sasquatch, Lei-Lei and Aqua Spread, +0x1A2 in Lilith's and Demitri's Dark Force, +0x136's camera effect and the moves of its Jedah, Zabel and Lilith writers, +0x3C1's random pick, the meanings of +0x372 and of the per-character slots, the forced picks' id copies +0x3BD/+0x3E0, merged-m23 and FBNeo.
Artifacts (read every one, in full):
  - tests/audit_mizuumi_chars.sh
  - tools/mizuumi_chars.py
  - tests/expected/mizuumi_chars.tsv
  - docs/game/atlas/ram.md.lines-144-159 (lines 144-159 of docs/game/atlas/ram.md)
  - docs/game/atlas/ram.md.lines-167-167 (lines 167-167 of docs/game/atlas/ram.md)
  - docs/game/atlas/ram.md.lines-242-277 (lines 242-277 of docs/game/atlas/ram.md)
  - docs/game/atlas/character_tables.md.lines-25-32 (lines 25-32 of docs/game/atlas/character_tables.md)
  - build/agent196/t118/rec10/clone_clean.txt
  - build/agent196/t118/rec10/audit_mizuumi_chars.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__dup-base.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__clear-nonzero.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__read-other-game.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__tap-other-game.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__tap-misaligned.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__next-load-wrong.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__prewrite-human.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__wrong-owner.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__wrong-base.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__absent-move.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__pool-miscount.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__passes-inflated.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__fall-shifted.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__taps-as-dashes.log
  - build/agent196/t118/rec10/audit_mizuumi_chars__other-side-credit.log
