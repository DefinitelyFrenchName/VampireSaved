THE PACKET

Decision kind: recommendation
Subject: 14z-166: GitHub #136 meter-fraction family root-caused - the tenant throw's hit-registration pair (28 DIFF rows, 7 parts); a finding, no fix
Claim (the working agent's sentence): At 14z-166 the GitHub #136 METER-FRACTION family - the 28 DIFF rows of tests/expected/move_parity_events.tsv whose first differing field is `meter` (parts donovan_4/5/7/8, huitzil_3/4/7/8, pyron_3/4), every one at an event whose move is kind=throw in build/manifest/moves_<tenant>.toml or a 'Sitting Attack / Foot Stab off throw' event downstream of one (coupled=after) - is attributed to ONE mechanism, MEASURED on the pyron_3 naming rig only (ours = merged-m18 build/m3b_merged26, native = vsav2; the rig, pokes, speed-level and RNG pins and both players' real cursor routes exactly as tests/audit_move_parity.sh builds them, reproduced by build/meter_probe_14z166/meter_probe.sh): on a tenant's throw contact the ATTACKER's meter step is the throw record's +0x14 on native (6 Corona Whip, 18 Planet Burning, 12 Galactic Throw at frames 3050/3943/4988 of build/move_parity_census_14z164/traces/tr_pyron_3_native.txt; 9 for Donovan's throws in tr_donovan_4/7) and a flat 8 on ours at the same frames, BECAUSE the engine's generic hit stager (vs2 0x172F2, vsavj twin 0x18980, disasm.txt) awards `+0x14(a3)` to the fighter registered at A5-0x4B74 (vs2) / A5-0x4BC6 (vsavj) and a flat 8 to the fighter registered at A5-0x4B72 / A5-0x4BC4, and native's throw code writes that pair as (attacker, victim) at vs2 0x289C6/0x289CA and 0x28A94/0x28A98 on the contact frame right before the stager reads it (native_pair.txt: frames 3049 and 3942), while on ours the placed copies of those stores (0x4787C4/C8 and 0x478892/96 in Pyron's x028122 copy) still write vs2's displacements = RAM:$FF348C-F, an address no vsavj engine code reads in play (ours_deadpair.txt: its only readers are the boot RAM test at frames 5-12; its writers in play are exactly the four placed sites) - the 14x rollback of the 14v reconciliation, kept by design in every tenant manifest - so the vsavj stager reads ITS pair at RAM:$FF343A-D, which in play is written only by the per-frame collision registration (vsavj 0x17FF8/0x18000, twice a frame, once per fighter, ours_pair.txt) and whose last write before the throw's damage call leaves (P2, P1): the logging breakpoint at the vsavj adder 0x29A16 (ours_engine.txt) fires with D0=6 on A6=$FF8800 then D0=8 on A6=$FF8400 at frame 3050 (and D0=0x12 on P2 then 8 on P1 at 3943), where native's adder 0x28D48 (native_adder.txt) fires with D0=6 on A6=$FF8400 then D0=8 on A6=$FF8800 - so on ours the VICTIM receives the throw record's meter and the attacker the victim's flat 8, on every tenant throw. The per-character `moveq #N; jsr adder` sites are the SWING costs, fire identically on both legs (probes at frames 2600/3879/4974, census.txt part 2: same immediates on the placed twins), and are NOT the differing step; each tenant calls a placed COPY of vs2's adder (census.txt) that is vs2's routine verbatim except its reconciled tail call, including a gate on fighter +0x1C3 where vsavj's own adder tests +0x111 (a Dark-Force-only consequence, NOT measured here, MEM[A6+1c3]=00 on every hit probed). The same stale pair is also read at the contact frame by four vsavj damage-scaler sites (0x18B9C/0x18C3C/0x18CA6/0x18D28, ours_pair.txt R lines at 3049 and 3942) whose effect on tenant throw DAMAGE was NOT measured (P2's HP drop was equal on both legs on every throw of this rig). This is the family the 14v fix targeted (build/manifest/donovan.toml stage-99 rows: the three pair-store pairs and two state-byte clears reconciled to vsavj's layout) and 14x rolled back because it broke Donovan's throw in play (STATE_HISTORY.md 'Session 14x'); the engine-consumer census 14x demanded before any re-attempt is build/meter_probe_14z166/census.txt part 3 (34 vsavj engine sites on the pair and the state byte). WHAT IS PROPOSED: a FINDING to the maintainer on #136 - the meter family is one mechanism, on OUR side, not a data-port or a vanilla-engine difference - and NO fix; the fix candidate named for a later, separately measured session is reconciling ONLY the pair stores (leaving the state-byte clears at vs2 offsets), and whether the 14x breakage came from the pair stores or from the state-byte clears was NOT tested. Also NOT tested: Donovan's and Phobos's throws under the probe (their attribution rests on the identical flat-8 signature in the 14z-164 traces and on the shared x028122 region carrying the same unreconciled stores per build/manifest/huitzil.toml and pyron.toml); the victim's meter on ours is read off the probe's A6 and D0, not off a P2 meter trace; the -debug probe legs are not checksum-canonical ([VSP-129]) and the native probe leg logged 3 INPUT-VIOLATION lines at frames >= 5880, after every window quoted; the non-debug taps carry no such lines. No shipped ROM byte moved.
Artifacts (read every one, in full):
  - build/meter_probe_14z166/meter_probe.sh
  - build/meter_probe_14z166/meter_probe_pair.sh
  - build/meter_probe_14z166/meter_probe_dead.sh
  - build/meter_probe_14z166/meter_steps.py
  - build/meter_probe_14z166/census.py
  - build/meter_probe_14z166/census.txt
  - build/meter_probe_14z166/disasm.txt
  - build/meter_probe_14z166/ours_tap.txt
  - build/meter_probe_14z166/native_tap.txt
  - build/meter_probe_14z166/ours_engine.txt
  - build/meter_probe_14z166/ours_copy.txt
  - build/meter_probe_14z166/native_adder.txt
  - build/meter_probe_14z166/ours_pair.txt
  - build/meter_probe_14z166/native_pair.txt
  - build/meter_probe_14z166/ours_deadpair.txt
  - build/meter_probe_14z166/ours.rpl
  - build/meter_probe_14z166/native.rpl
  - build/move_parity_census_14z164/traces/tr_pyron_3_native.txt
  - build/move_parity_census_14z164/traces/tr_pyron_3_ours.txt
  - build/move_parity_census_14z164/traces/tr_donovan_4_native.txt
  - build/move_parity_census_14z164/traces/tr_donovan_4_ours.txt
  - build/move_parity_census_14z164/traces/tr_donovan_7_native.txt
  - build/move_parity_census_14z164/traces/tr_donovan_7_ours.txt
  - tests/expected/move_parity_events.tsv
  - tests/audit_move_parity.sh
  - tests/replays/naming/pyron_3.json
  - tests/replays/naming/pyron_3.rpl
  - build/manifest/moves_pyron.toml
  - build/manifest/moves_donovan.toml
  - build/manifest/moves_huitzil.toml
  - build/manifest/donovan.toml.lines-712-770 (lines 712-770 of build/manifest/donovan.toml)
  - build/manifest/pyron.toml.lines-345-395 (lines 345-395 of build/manifest/pyron.toml)
  - build/manifest/huitzil.toml.lines-455-480 (lines 455-480 of build/manifest/huitzil.toml)
  - build/m3b_merged26/patch/placements.json
  - docs/game/engine_internals.md.lines-1020-1055 (lines 1020-1055 of docs/game/engine_internals.md)
  - docs/game/engine_internals.md.lines-3040-3075 (lines 3040-3075 of docs/game/engine_internals.md)
  - docs/game/atlas/ram.md.lines-183-190 (lines 183-190 of docs/game/atlas/ram.md)
  - STATE_HISTORY.md.lines-28855-28875 (lines 28855-28875 of STATE_HISTORY.md)
  - STATE_HISTORY.md.lines-28967-28990 (lines 28967-28990 of STATE_HISTORY.md)
  - docs/project/patch_notes.md.lines-3308-3332 (lines 3308-3332 of docs/project/patch_notes.md)
  - tests/lua/read_tap.lua
  - tests/lua/replay_guard.lua.lines-300-345 (lines 300-345 of tests/lua/replay_guard.lua)
