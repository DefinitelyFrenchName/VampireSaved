THE PACKET

Decision kind: expectation
Subject: #118 rows B (14z-214): freeze audit_mizuumi_rows_b's expectations and record +0x384 (state index), +0x3A8 (a long), +0x3BE/+0x3BF (finish-type counters) and +0x3B6's bit 7 in ram.md, the candidates table re-derived
Claim (the working agent's sentence): CLAIM: freeze tests/audit_mizuumi_rows_b.sh's expectations and record in docs/game/atlas/ram.md (records.diff) +0x384 as a per-player state index, +0x3A8 as a long holding 0x0090C140 / 0x0090C200, +0x3BE as raised only after a finish type 3, 4 or 6, +0x3BF as not observed, and +0x3B6's bit 7; the candidates table re-derived (four NO ROW offsets now NOT ADOPTED x3 and NOT OBSERVED x1; batch columns updated by hand). It rests on the gate (gate.sh.txt, blob in blobs.txt) on pristine vsavj under the pinned reference MAME over six corpus replays (02, 03, 26, 37, 105, 128), each a field leg and a write-tap leg: T1 +0x3A8's value writers 0x01BEE2/0x01C186/0x01C692 always store both words in one frame; T2 +0x3A8 reads only 0 and 0x0090C140 on P1, 0 and 0x0090C200 on P2; T3 no other PC writes it non-zero after f1000 (the boot RAM test at 0x000D34 fills 0xFFFF at f15); T4 each side's +0x384 byte sequence frozen per replay; T5 every 0x009A2C write sets bit 7 of +0x3B6 (9 sets: 0x80, 0x81, 0x83); T6 each 0x05E2DC raise of +0x3BE in the frame of a set whose low bits are 3, 4 or 6; T7 no raise within 600 frames of any other set; T8 counts 9 and 2 frozen. plain.log PASS; mode_*.log: each of the four controls run as a mode FAILs the gate for its own reason. No conclusion about how anything plays is drawn, so no capture was put to the maintainer.
NOT TESTED: finish types 4 and 6 occur in none of the six replays, so T6's rule for them and +0x3BF's raise rest on S0's static read; which finish types the community calls EX is not measured; whether 0x0090C140 is the fighter's palette block is S0's inference (the community name "WORD Palette RAM Pointer" is therefore not adopted, only "WORD" shown not to hold); +0x384's meaning per value (which scene each index is) is not judged, only its sequences; $FF80D0 alternating with 0x0091C000 on some legs is not judged; S0's ladder readers (0x00A79C, 0x0099E0) are static reads, not run; the six replays are corpus replays (no new inputs), one emulator (MAME), no FBNeo leg; +0x354 is not in this gate.
Artifacts (read every one, in full):
  - build/agent214/t118/rowsb/closure/gate.sh.txt
  - build/agent214/t118/rowsb/closure/blobs.txt
  - build/agent214/t118/rowsb/closure/plain.log
  - build/agent214/t118/rowsb/closure/mode_sides-swapped.log
  - build/agent214/t118/rowsb/closure/mode_offset-swapped.log
  - build/agent214/t118/rowsb/closure/mode_lowbits-shifted.log
  - build/agent214/t118/rowsb/closure/mode_word-only.log
  - build/agent214/t118/rowsb/closure/records.diff
