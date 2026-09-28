THE PACKET

Decision kind: recommendation
Subject: #176: build tests/audit_rng_draws.sh (per-caller RNG draws, ours vs native, seeded non-zero then free); report 0000 as the RNG's fixed point (re-checked after 348)
Claim (the working agent's sentence): Recommend to the maintainer, for #176 (compare the RNG's per-frame advance between our build and native; the parity gates pin the RNG word every frame): (A) a new MAME gate, tests/audit_rng_draws.sh, and (B) a report that 0000, the value the parity gates pin (gate_rng_pins.txt: `ff80d4:0000` in audit_move_parity, audit_chains174, test_don_immortal_native and audit_df_moves), is the RNG's fixed point.
Every figure below comes from analyse.log. analyse.py produces it from fresh runs of the scripts in the packet, and names each trace's sha1.
The seed-0000 runs come from probe.sh with seed 0000. The seed-5a5a runs come from probe.sh with seed 5a5a, and from callers.sh and callers_t.sh.
THE FIXED POINT (B). The routine is byte-identical on vsavj (0x014E8A) and vs2 (0x01357E) (rng_routine_vsavj.txt, rng_routine_vsav2.txt), and it maps 0000 to 0000: the new high byte is the high byte of 3*W, and the low byte adds that byte. 0000 was poked on 2363..2599 and the RNG left free from 2600. The word read 0000 on every traced frame of all five legs (analyse.log section 1). So under the gates' per-frame 0000 pin, every draw returns 0.
THE MEASUREMENTS BEHIND (A). Seed 5a5a was poked on 2363..2599 and the RNG left free from 2600; the level was pinned to 06 throughout. The rigs are audit_air_gc_legacy's (Lei-Lei vs Demitri) and audit_chains174's (Phobos, Donovan and Pyron vs Demitri).
(1) Frames with zero draws: none on any leg (1 to 10 draws per frame). The draws between two frames are the steps from one word to the next; every frame resolved (section 2).
(2) Legacy on ours against pristine vsavj: the word is equal on all 1602 frames, and each has 2126 draws. The read tap on both matches draw for draw, on frame label, caller and data: 2125 draws each (section 4).
(3) The two engines on legacy content part at 2610. vsavj draws 2126, vsav2 2012.
(4) The read tap at the routine's first instruction logs each draw with its caller (rng_callers.lua; the caller is the return address at USP, since the game runs in user mode). Its draws labelled N equal the chain's count at frame N+1 on every compared frame of all five legs, with 0 differing frames (section 3). Its totals are one lower because frame 2600's single draw falls before the tap's window.
(5) By caller (section 5):
- The object loop (vsavj 0x0220A0, vs2 0x020A50; the same code per caller_0220a0_vsavj.txt and caller_020a50_vsav2.txt) draws alike on every rig: 1969, 4240, 1439 and 1588.
- vsavj's effect-channel caller 0x02A52E (caller_02a52e_vsavj.txt; the same bytes on ours per caller_02a52e_ours.txt) draws 107, 265, 88 and 63 times on ours and on vsavj. No vs2 caller has a count in its place.
- Phobos's own draw is ours 0x42BAE2 and native 0x08A904: the same instructions apart from the relocated jsr target (caller_42bae2_ours.txt, caller_08a904_vsav2.txt), 3 draws each. The native address lies inside Phobos's vs2 extract region, and our placement map translates ours to it (section 6).
- Donovan and Pyron draw nothing from their own code on either leg.
THE GATE (A), not built. Its rigs are the three chains174 tenant rigs plus the Lei-Lei legacy rig, each seeded non-zero and then left free. The scratch instrument is promoted as tests/lua/rng_draws.lua. The checks:
(a) Legacy on ours equals pristine vsavj draw for draw.
(b) Each tenant-code caller draws the same count on both legs. It is mapped by the placement map, and anchored independently: the native address must lie inside the tenant's vs2 extract region, and the instruction bytes at both must match apart from the jsr target.
(c) The object loop's count is equal.
(d) The engine callers seen on one leg only are frozen as an inventory; a new one fails.
(e) The tap's per-frame counts equal the chain counts of a field trace.
Controls, each of which must fail its check: a tenant draw removed from ours; the caller map shifted; one legacy draw's caller relabelled on ours; the stack read from MAME's SP instead of USP; a planted legacy draw on ours.
NOT tested:
- any seed but 5a5a and 0000, and any seed frame but 2600;
- the naming corpus; FBNeo and MiSTer;
- a tenant whose own code draws conditionally on a drawn value: after the two streams part the drawn VALUES differ, so its count could differ with no port defect. It was measured only where Phobos's 3 draws matched and Donovan and Pyron drew none.
That the effect-channel machine's draws are host-engine behaviour is a reading of the callers (a vsavj engine address that draws on legacy content too), not a separate measurement. The consequence for the parity gates' existing verdicts of every draw returning 0 is not measured.
Artifacts (read every one, in full):
  - build/agent185/t176/probe.sh
  - build/agent185/t176/callers.sh
  - build/agent185/t176/callers_t.sh
  - build/agent185/t176/rng_callers.lua
  - build/agent185/t176/analyse.py
  - build/agent185/t176/analyse.log
  - build/agent185/t176/gate_rng_pins.txt
  - build/agent185/t176/rng_routine_vsavj.txt
  - build/agent185/t176/rng_routine_vsav2.txt
  - build/agent185/t176/caller_0220a0_vsavj.txt
  - build/agent185/t176/caller_020a50_vsav2.txt
  - build/agent185/t176/caller_02a52e_vsavj.txt
  - build/agent185/t176/caller_02a52e_ours.txt
  - build/agent185/t176/caller_42bae2_ours.txt
  - build/agent185/t176/caller_08a904_vsav2.txt
