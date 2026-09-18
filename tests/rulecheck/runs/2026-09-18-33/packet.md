THE PACKET

Decision kind: expectation
Subject: 14z-166 (run 2): freeze tests/expected/throw_registration.tsv - the hit-registration pair at every tenant throw contact, ours vs native, the defect frozen as measured; the vs2-pair address's vsavj reader censused statically; the capture put before the maintainer
Claim (the working agent's sentence): At 14z-166 tests/expected/throw_registration.tsv is FROZEN (70 rows) by tests/audit_throw_registration.sh with FREEZE=1 and VERIFIED by a second run without FREEZE (build/gates_14z166/throw_reg_freeze.log, throw_reg_verify.log): for three naming-rig parts, one per tenant (pyron_3, huitzil_3, donovan_5 - the rig, pokes, speed-level and RNG pins and both players' real cursor routes copied from tests/audit_move_parity.sh), on ours (merged-m18, build/m3b_merged26) and native vsav2, under seven NON-DEBUG read taps per part (tests/lua/read_tap.lua: P1 meter RAM:$FF850A and P2 meter $FF890A on both legs, vsavj's hit-registration pair $FF343A-D on ours, vs2's pair $FF348C-F on native, and vs2's pair address on ours as the 'dead-pair' tap), it freezes per part and leg: a CONTACT row for every frame with a throw-site write of that leg's own pair (native: any non-collision writer of vs2's pair; ours: any in-play writer of vs2's pair address) carrying the P1 and P2 meter steps on that frame - native p1=<record> p2=+8 and ours p1=+8 p2=<record> on every contact that awards meter (Corona Whip 6, Planet Burning 18, Phobos's throws 9, Sword Grapple 9), 'none' on the grab-attempt frames that award nothing - and the writer/reader sets: native's live-pair writers are exactly vs2 0289c6/0289ca/028a94/028a98 in every part, ours' live-pair non-collision writers are none in every part, ours' writers of vs2's pair address are exactly each tenant's four placed store sites (pyron 4787c4/4787c8/478892/478896, huitzil 41f554/41f558/41f622/41f626, donovan 0cfc14/0cfc18/0cfce2/0cfce6) and its readers in these rigs exactly the boot RAM test 000d32/000d36. WHAT THAT ADDRESS IS ON VSAVJ (census.txt part 4, disasm.txt): $FF348C-F are two words of a four-word ring -0x4B76..-0x4B70(a5) that the vsavj engine routine PRG:0x0194AE shifts when fighter +0x70 and the staging flag -0x4BBA are clear - the ONLY vsavj instructions reading those addresses (0x0194BA/0x0194C0), reached through a dispatch table rather than a branch (no bsr/jsr/bra targets it in the engine range), whose trigger is UNMEASURED and which fired in none of the three rigs; NO ported instruction reads them: all 28 placed sites naming vs2's displacements -0x4B74/-0x4B72/-0x4B3D are writes, and vs2's own 19 readers of its pair are all in vs2's engine, not in any placed region - which RETRACTS the 14x rollback's stated reason ('ported readers consume those vars', struck and marked in docs/game/engine_internals.md, docs/project/gotchas.md, docs/project/patch_notes.md and build/manifest/huitzil.toml). THE DEFECT IS FROZEN AS MEASURED and the file's header says so: a fix that reconciles the placed stores re-freezes it deliberately. THE CAPTURE: build/meter_probe_14z166/captures/meter_sheet_pyron3.png (native beside ours, 20 frames after Corona Whip 6HP and after Planet Burning MP, the meter bars in frame, tests/lua/snapshot_frames.lua at frames 3070/3980 on the same rig) was produced AFTER the conclusion had been drawn from the RAM taps and was put before the maintainer through the session's file channel before anything is posted on GitHub - the order is stated, not hidden. Controls: legs-swapped (a copy of ours' rows with P1/P2 steps swapped - the fixed shape - must differ from the frozen rows; in-gate FIRED, mode exit 1 on all three parts, throw_reg_ctl_swapped.log) and dead-reader-planted (one in-play R line planted at a game PC in a copy of ours' dead-pair tap must add a reader row; in-gate FIRED, mode exit 1, throw_reg_ctl_planted.log); a tap log without an END line is refused as VOID. Registered: tests/ci_emulator.tsv (mame, release, romset), tests/gate_index.tsv (character-data), tests/expected/PROVENANCE.md (in-emulator), the must-fire census re-frozen at 107 declaring. NOT tested: the contact frames are the rig's (a rig change moves them - the header says re-derive, not re-freeze); the meter step is the difference between consecutive writes to the meter word, so a stock crossing on a contact frame would read as a wrapped negative step (none occurred; the reducer does not unwrap); ours' contact set is DEFINED by the placed sites' writes, so a tenant throw path that does not pass those sites would produce no ours contact row (the huitzil_3 first event, where ours lands a normal instead of throwing, is such an absence and is the frozen DIFF row of move_parity_events.tsv, not a missed contact); Pyron's air throw is not produced by the rig and is uncovered; the ring shift PRG:0x0194AE's trigger, and what the pointer words the placed stores spray into its ring do when it fires, are unmeasured; the four damage-scaler reads of the stale live pair and their effect on tenant throw damage are unmeasured (equal HP drops on every measured throw); the verify run is run-to-run determinism on one host, not an independent measurement; no shipped ROM byte moved.
Artifacts (read every one, in full):
  - tests/audit_throw_registration.sh
  - tests/expected/throw_registration.tsv
  - build/gates_14z166/throw_reg_freeze.log
  - build/gates_14z166/throw_reg_verify.log
  - build/gates_14z166/throw_reg_ctl_swapped.log
  - build/gates_14z166/throw_reg_ctl_planted.log
  - tests/lua/read_tap.lua
  - tests/lua/snapshot_frames.lua
  - tests/audit_move_parity.sh.lines-130-200 (lines 130-200 of tests/audit_move_parity.sh)
  - tests/replays/naming/pyron_3.json
  - tests/replays/naming/huitzil_3.json
  - tests/replays/naming/donovan_5.json
  - tests/expected/move_parity_events.tsv
  - tests/expected/PROVENANCE.md.lines-110-116 (lines 110-116 of tests/expected/PROVENANCE.md)
  - tests/ci_emulator.tsv.lines-270-276 (lines 270-276 of tests/ci_emulator.tsv)
  - tests/expected/must_fire_census.tsv
  - build/meter_probe_14z166/huitzil_3/readout.txt
  - build/meter_probe_14z166/pyron_3/readout.txt
  - build/meter_probe_14z166/donovan_5/readout.txt
  - build/meter_probe_14z166/disasm.txt
  - build/meter_probe_14z166/census.txt
  - build/meter_probe_14z166/census.py
  - build/meter_probe_14z166/captures/meter_sheet_pyron3.png
  - build/meter_probe_14z166/captures/ours/index.txt
  - build/meter_probe_14z166/captures/native/index.txt
  - docs/game/engine_internals.md.lines-3040-3125 (lines 3040-3125 of docs/game/engine_internals.md)
  - docs/game/atlas/ram.md.lines-90-96 (lines 90-96 of docs/game/atlas/ram.md)
  - docs/project/gotchas.md.lines-2230-2250 (lines 2230-2250 of docs/project/gotchas.md)
  - docs/project/gotchas.md.lines-4965-5000 (lines 4965-5000 of docs/project/gotchas.md)
  - docs/project/patch_notes.md.lines-1580-1596 (lines 1580-1596 of docs/project/patch_notes.md)
  - build/manifest/huitzil.toml.lines-455-485 (lines 455-485 of build/manifest/huitzil.toml)
  - docs/project/must_fire_contract.md
