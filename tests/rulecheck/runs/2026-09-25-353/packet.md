THE PACKET

Decision kind: recommendation
Subject: #176: build tests/audit_rng_draws.sh; report 0000 as the RNG's fixed point and the tenants' channel blocks on the host machine (re-checked after 352)
Claim (the working agent's sentence): Recommend to the maintainer, for #176:
(A) a new MAME gate, tests/audit_rng_draws.sh, as designed below;
(B) two findings.
(B1) 0000, the value the parity gates pin over their windows (gate_rng_pins.txt: `ff80d4:0000` in audit_move_parity, audit_chains174, test_don_immortal_native and audit_df_moves, each over its own frame range), is the RNG's FIXED POINT. The routine is byte-identical on vsavj 0x014E8A and vs2 0x01357E (rng_routine_vsavj.txt, rng_routine_vsav2.txt): the new high byte is the high byte of 3*W, and the low byte adds it. Poked 2363..2599 and then left free, the word read 0000 on every traced frame of all five traced legs (analyse.log section 1). Under those pins every draw returns 0.
(B2) On ours, each tenant's effect-channel block (its per-channel calls) enters the HOST's channel machine, which draws a random delay: by the code (machine_vsavj_delay.txt), each draw stores table[rand&31] from 0x2A55A (values 0x0E..0x13) into the channel's +4 byte, which the machine counts down (subq.b #1,$4(a4) at 0x2A4E8 and 0x2A506). On native the same block enters vs2's machine, and no draw ever happens under it:
- ours' block calls vsavj's channel entries 0x29dca..0x29dfa directly, or through three shims (lea table; jmp $29f4a) (caller_block_ours.txt, shims_ours.txt, against caller_block_vsav2.txt). Each vsavj entry is lea table(pc),a3; bra $29f4a, and 0x29f4a dispatches on the channel's program byte (move.b (a4),d0, then a word jump table) (vsavj_entries.txt). The measured host-machine draws return to 0x2A52E with the tenant's block as the next return address (paths_huitzil.log).
- block_scan.py counts draws with the tenant's channel block ANYWHERE in the 48 dumped stack longs: raw presence, so any helper chain below the block counts. Native: 0, 0 and 0 for Phobos, Donovan and Pyron. Ours: 265, 88 and 63 (block_scan.log). A planted block address makes native read 1 (block_scan_plant.log).
- the block is LIVE on native: every tenant's channel structs were read thousands of times with its block on the stack, frames 2600-2700, by code at 0x292a6..0x298c6 (block_live.sh, block_live.py, block_live.log).
- in code: vsavj's machine calls the RNG at 0x2A528 and 0x2A53E; vs2's range 0x29000-0x2A000, which contains its executed 0x292a6..0x298c6, holds no absolute-long call to the RNG (machine_rng_calls.txt).
- vsavj runs the same machine for legacy characters: 107 draws on Lei-Lei, vsavj and ours alike (analyse.log section 5).
NO conclusion is drawn about what a player sees. The channels' visible effect is not captured.
Each log below names the sha1s of the traces or images it read. Setup: seed 5a5a poked 2363..2599, then free; level pinned to 06. The rigs are audit_air_gc_legacy's Lei-Lei vs Demitri and audit_chains174's three tenant rigs vs Demitri.
(1) On the five field-traced legs, every frame has at least one draw, and the chain of words resolves on each frame (analyse.log section 2). Donovan and Pyron were read by the tap only.
(2) Legacy on ours against pristine vsavj: the tap is identical draw for draw, on frame, caller and data (2125). A relabelled caller fails the check (analyse_relabel.log).
(3) The tap's per-frame counts equal the chain's on every compared frame of five legs. A dropped tap line fails the check (analyse_drop.log).
(4) The stack dump does not perturb the runs: the taps with and without it are identical on nine legs (r2_r3_same.log). mediated.py keys each draw by its innermost return address into the tenant's regions (ours mapped to native).
- Keys on both legs count alike: Phobos 0x8a904 3/3; Donovan 0x28a42 4/4, 0x28ad8 2/2, 0x28af2 2/2.
- The ours-only keys are the channel blocks of (B2).
- The native-only keys are 0x8b99a (65 Phobos, 28 Pyron), 0x2347c and 0x237a4: vs2 engine code inside regions the port copied. Lei-Lei on vs2 draws through 0x8b99a (25) and 0x2347c (3) (mediated.log). Donovan and Pyron draw through 0x237a4 on native (paths_donovan.log, paths_pyron.log, printed by paths.py), and it lies outside both of their regions (neither has it as a key in mediated.log).
- Legacy on ours has no tenant frame.
- Two plants fail the check: a shifted placement map, and a dropped common-key draw (mediated_plant-*.log).
(5) The object loop draws alike on every rig: 1969, 4240, 1439 and 1588.
THE GATE (A), not built. The rigs are above, seeded 5a5a and then free. rng_callers.lua is promoted to tests/lua/rng_draws.lua, with the stack dump. The checks:
(a) legacy on ours equals pristine vsavj, draw for draw;
(b) keys on both legs count alike;
(c) the object loop's count is equal;
(d) the one-leg keys and the channel-block counts are FROZEN, so any change fails;
(e) the tap equals the chain per frame;
(f) legacy on ours has no tenant frame.
Its controls are the five plants above (relabel, drop, map-shift, strip, block), each run as a must-fire mode. If the maintainer later rules that the tenants' channel delays should follow vs2, the frozen rows of (d) move by that ruling.
NOT tested:
- any seed but 5a5a and 0000, and any seed frame but 2600;
- other rigs; FBNeo and MiSTer;
- whether a tenant's conditional draw could count differently after the streams part with no port defect (measured only where the common keys matched);
- a call made by a jmp or a pushed return, which the key's call-instruction check does not see (the block scan is raw and does not depend on it);
- stack deeper than 48 longs (the block scan's native zero also rests on it);
- what the delay does on screen;
- the consequence for the parity gates' existing verdicts of every draw returning 0.
Artifacts (read every one, in full):
  - build/agent185/t176/probe.sh
  - build/agent185/t176/callers.sh
  - build/agent185/t176/callers_t.sh
  - build/agent185/t176/rng_callers.lua
  - build/agent185/t176/analyse.py
  - build/agent185/t176/analyse.log
  - build/agent185/t176/analyse_relabel.log
  - build/agent185/t176/analyse_drop.log
  - build/agent185/t176/mediated.py
  - build/agent185/t176/mediated.log
  - build/agent185/t176/mediated_plant-map.log
  - build/agent185/t176/mediated_plant-strip.log
  - build/agent185/t176/r2_r3_same.log
  - build/agent185/t176/gate_rng_pins.txt
  - build/agent185/t176/block_scan.py
  - build/agent185/t176/block_scan.log
  - build/agent185/t176/block_scan_plant.log
  - build/agent185/t176/block_live.sh
  - build/agent185/t176/block_live.py
  - build/agent185/t176/block_live.log
  - build/agent185/t176/paths.py
  - build/agent185/t176/paths_donovan.log
  - build/agent185/t176/paths_pyron.log
  - build/agent185/t176/paths_huitzil.log
  - build/agent185/t176/machine_vsavj_delay.txt
  - build/agent185/t176/vsavj_entries.txt
  - build/agent185/t176/rng_routine_vsavj.txt
  - build/agent185/t176/rng_routine_vsav2.txt
  - build/agent185/t176/machine_rng_calls.txt
  - build/agent185/t176/caller_block_vsav2.txt
  - build/agent185/t176/caller_block_ours.txt
  - build/agent185/t176/shims_ours.txt
