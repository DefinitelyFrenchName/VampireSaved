THE PACKET

Decision kind: expectation
Subject: 14z-166 (run 5): the final re-freeze of tests/expected/throw_registration.tsv - the reducer's frame-net steps, the ids rows with writer PCs, the legacy control captured
Claim (the working agent's sentence): At 14z-166 tests/expected/throw_registration.tsv is RE-FROZEN (76 rows: 70 tenant rows unchanged in content from the first freeze, checker runs 2026-09-18-32/-33, plus 6 rows of the legacy control part) by tests/audit_throw_registration.sh with FREEZE=1 and VERIFIED by a second run without FREEZE (build/gates_14z166/throw_reg_freeze4.log, throw_reg_verify4.log). The reducer now takes each contact step as the FRAME's net change of the meter word - the deltas of every write on that frame summed, a frame with more than one write marked `/Nw` - and no contact row in any part carries such a marker, so every frozen step is a single write's change by measurement. The legacy part `legacy_demitri` is the control the maintainer asked for in these words, quoted in the gate's header and in STATE.md row (6): "correct me if I'm wrong but that measurement could give us an answer because if legacy characters exhibit the same behaviour this is a nothing burger but if they don't that at least tells us what it is not" and "the values are quite widly different, we really need that control you're doing with a legacy character" - Demitri throwing Victor by tests/replays/judge/02_throw.rpl as REAL cursor picks with NO id poke (P1's default cell is 0x01 Demitri and P2's R,R is 0x03 Victor on both decoded wheels, build/meter_probe_14z166/wheel_resolve.txt; only the speed-level and RNG pins), on PRISTINE vsavj (leg `vsavj`, MAME_ROMPATH=$ROMDIR, no build) and on vsav2 (leg `native`), under five non-debug taps per leg (P1 meter $FF850A, P2 meter $FF890A, the engine's own pair - $FF343A-D on vsavj, $FF348C-F on vsav2 - and both id bytes as 2-byte windows, only writes carrying the ff00 mask counted, the byte and its writer PC frozen): the ids rows read p1=01@009008 / p2=03@020a80 on vsavj and p1=01@0077d6 / p2=03@01f64a on vsav2 (the last pre-2300 write to each id byte); vsavj registers the pair at its own throw site 0x029694/0x029698 at frame 3062 and pays P1 +9 and P2 +8; vsav2 registers at 0x0289C6/0x0289CA at frame 3061 and pays P1 +9 and P2 +8 - the same rule, the same record value, one frame apart. WHAT THIS SETTLES: the host engine pays a legacy throw as vs2 does, so the tenant rows (ours attacker +8 / victim the record) are a PORT DEFECT of the placed throw code's registration and not an engine-generation difference. THE CAPTURE: build/meter_probe_14z166/captures_legacy/legacy_throw_sheet.png (Demitri's throw on pristine vsavj beside vsav2 at frames 3040 and 3110, the hold and the pay, tests/lua/snapshot_frames.lua on the same replay and pins) was produced AFTER the numbers were read and delivered to the maintainer before this run (captures/DELIVERED.txt) - the order is stated. The two must-fire controls are unchanged, fired in-gate (throw_reg_verify4.log) and both modes exit 1 (throw_reg_ctl_swapped4.log, throw_reg_ctl_planted4.log); they perturb ours' rows and ours' dead-pair tap, which the legacy part has neither of, so the legacy rows read `as frozen` under both - a gap the claim names; a run that does not reach END is refused as VOID, and a tap that ends without hits is caught only by the frozen rows it fails to reproduce, not by the END line. The registry rows (tests/expected/PROVENANCE.md, tests/ci_emulator.tsv) name the control. NOT tested: one legacy throw of one character on one rig - other legacy characters' throw records may carry different +0x14 values in the two games (tests/expected/same_data_p2.tsv lists per character which attack records differ); the ids rows prove which character each block holds at its last pre-match id write, not that no id write lands between 2300 and the contact (none is asserted); the writer PCs are frozen as observed and not attributed to a routine here; the vsavj leg's collision registration PCs are those the reducer excludes for ours (0x017FF8/0x018000); the verify run is run-to-run determinism on one host; no shipped ROM byte moved.
Artifacts (read every one, in full):
  - tests/audit_throw_registration.sh
  - tests/expected/throw_registration.tsv
  - build/gates_14z166/throw_reg_freeze4.log
  - build/gates_14z166/throw_reg_verify4.log
  - build/gates_14z166/throw_reg_ctl_swapped4.log
  - build/gates_14z166/throw_reg_ctl_planted4.log
  - build/meter_probe_14z166/wheel_resolve.txt
  - build/meter_probe_14z166/wheels/vsavj.json
  - build/meter_probe_14z166/wheels/vsav2.json
  - tools/select_paths.py
  - tests/replays/judge/02_throw.rpl
  - tests/lua/read_tap.lua
  - tests/lua/snapshot_frames.lua
  - build/meter_probe_14z166/captures_legacy/legacy_throw_sheet.png
  - build/meter_probe_14z166/captures_legacy/vsavj/index.txt
  - build/meter_probe_14z166/captures_legacy/vsav2/index.txt
  - build/meter_probe_14z166/captures/DELIVERED.txt
  - tests/expected/PROVENANCE.md.lines-110-116 (lines 110-116 of tests/expected/PROVENANCE.md)
  - tests/ci_emulator.tsv.lines-270-276 (lines 270-276 of tests/ci_emulator.tsv)
  - tests/expected/same_data_p2.tsv
  - build/meter_probe_14z166/disasm.txt
  - docs/game/engine_internals.md.lines-3040-3130 (lines 3040-3130 of docs/game/engine_internals.md)
  - STATE.md.lines-44-62 (lines 44-62 of STATE.md)
