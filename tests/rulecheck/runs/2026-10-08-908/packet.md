THE PACKET

Decision kind: expectation
Subject: tests/expected/mizuumi_chars.tsv first frozen (GitHub #118, HOMING item 5), branch t118-196 at bcde6cd0 — re-prepared after runs 2026-10-08-902, -904 and -906
Claim (the working agent's sentence): On pristine vsavj under the pinned reference MAME over 18 legs (the five rigs and the 14z-194 pilot's 13 census replays), tests/expected/mizuumi_chars.tsv at bcde6cd0 is what tests/audit_mizuumi_chars.sh and tools/mizuumi_chars.py measured for K0, K0b and K1-K12, each judged against the projectile pool, both HP words, the engine pass counter, the replay's own input script or a block's character read from its loaded +0x60 base against vsavj's table PRG:0x0BD97A: every check reads the character that way, a base in no table row reading as unloaded (285,794 lookups per side, crediting nothing), and only K0b reads +0x382, holding it to the base on 197,917 of 197,992 in-match side-frames with the other 75 the arcade ladder's pre-write on a CPU side after the round timer reached 0 (allowed, control prewrite-human); K0 proves both forced picks by the base (control wrong-base); NARROWED where code ownership could not be shown: K8 and K12 credit a write to the character of the BLOCK it lands in, not to the code that ran (Morrigan's kick throw at PRG:0x03B2DA writes the victim's +0x19A and is credited to the victim), so K12's 124 writer PCs over +0x34..+0x37 / +0x360..+0x37F each write only into blocks that held one character, and docs/game/atlas/ram.md's rows now say 'writes landing in X's block' instead of 'X's code'; the ram.md figures runs 902 and 904 named are frozen (slotw_*, c136_writers with values, c14b_side_frames, c14b_other_types_live, pind_motion_lead, pact_demitri_flare_outlives, dash_write_* with dx30); the run of record PASSed from a clone with zero changed or untracked files before and after (build/agent196/t118/rec4/clone_clean.txt) with controls absent-move, wrong-owner (planting at a PC that writes only unnamed bytes), prewrite-human, wrong-base, pool-miscount, passes-inflated, fall-shifted, taps-as-dashes and other-side-credit firing in-gate and failing as modes; the +0x149 type map TYPE149 was read off these same 18 legs and +0x372's value is reported, not judged; NOT tested: which character's CODE writes any byte, the STATIC facts the ram.md rows also carry (the +0x15C routine PRG:0x029930-0x029984, that +0x154 and +0x0AC are read on the opponent through +0x32), +0x15C's dizzy-versus-hold distinction and random amounts, +0x14B for Sasquatch, Lei-Lei and Aqua Spread, +0x1A2 in Lilith's and Demitri's Dark Force, +0x136's camera effect and the moves of its Jedah, Zabel and Lilith writers, +0x3C1's random pick, the meanings of +0x372 and of the per-character slots, the forced picks' id copies +0x3BD/+0x3E0, merged-m23 and FBNeo.
Artifacts (read every one, in full):
  - tests/audit_mizuumi_chars.sh
  - tools/mizuumi_chars.py
  - tests/expected/mizuumi_chars.tsv
  - docs/game/atlas/ram.md.lines-144-158 (lines 144-158 of docs/game/atlas/ram.md)
  - docs/game/atlas/ram.md.lines-167-167 (lines 167-167 of docs/game/atlas/ram.md)
  - docs/game/atlas/ram.md.lines-242-277 (lines 242-277 of docs/game/atlas/ram.md)
  - docs/game/atlas/character_tables.md.lines-25-32 (lines 25-32 of docs/game/atlas/character_tables.md)
  - build/agent196/t118/rec4/clone_clean.txt
  - build/agent196/t118/rec4/audit_mizuumi_chars.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__absent-move.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__wrong-owner.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__wrong-base.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__prewrite-human.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__pool-miscount.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__passes-inflated.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__fall-shifted.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__taps-as-dashes.log
  - build/agent196/t118/rec4/audit_mizuumi_chars__other-side-credit.log
