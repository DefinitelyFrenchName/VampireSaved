THE PACKET

Decision kind: recommendation
Subject: #176: build tests/audit_rng_draws.sh (per-caller RNG draws, ours vs native, seeded non-zero then free); report 0000 as the RNG's fixed point
Claim (the working agent's sentence): Recommend to the maintainer, for #176 (compare the RNG's per-frame advance between our build and native; the parity gates pin the RNG word every frame): (A) a new MAME gate, tests/audit_rng_draws.sh, and (B) a report that 0000, the value the parity gates pin, is the RNG's fixed point.
THE FIXED POINT (B). The routine, byte-identical on vsavj (0x014E8A) and vs2 (0x01357E) per rng_routine_vsavj.txt and rng_routine_vsav2.txt, maps 0000 to 0000: new high byte = high byte of 3*W, low byte += that byte. With 0000 poked 2363..2599 and the RNG free from 2600, the word read 0000 on every traced frame of all five legs (seed0000_values.log). So under the gates' per-frame 0000 pin every draw returns 0.
THE MEASUREMENTS BEHIND (A), seed 5a5a poked 2363..2599 then free, the level pinned to 06 throughout, the same rigs as audit_air_gc_legacy (Lei-Lei vs Demitri) and audit_chains174 (Phobos vs Demitri) (probe.sh, provenance in seed5a5a.log):
(1) The word moved on every frame of every leg. Because the routine is deterministic, the draws between two frames are the steps from one word to the next (draws.py). All frames resolved.
(2) Legacy on ours equals pristine vsavj on every frame: 2126 draws each, 0 frames different.
(3) The two engines on legacy content part at 2610 (vsavj 2126 draws, vsav2 2012).
(4) A second instrument, a read tap at the routine's first instruction, logs each draw with its caller (rng_callers.lua, callers.sh, callers.log). The caller is the return address at USP, because the game runs in user mode (SR bit 13 clear). Its totals are one under the chain counts on every leg (2125/2011/4368/4618 against 2126/2012/4369/4619), which is read_tap's one-frame label offset at the window's first frame.
(5) By caller: the object loop (vsavj 0x0220A0, vs2 0x020A50; same code, caller_0220a0_vsavj.txt and caller_020a50_vsav2.txt) draws alike, 1969/1969 on Lei-Lei and 4240/4240 on Phobos. vsavj's effect-channel caller 0x02A52E (caller_02a52e_vsavj.txt, the same bytes on ours per caller_02a52e_ours.txt) draws 107 times on Lei-Lei and 265 times on Phobos, and no vs2 caller has a count in its place. Phobos's own draw has ours 0x42BAE2 and native 0x08A904, the same instructions apart from the relocated jsr target (caller_42bae2_ours.txt, caller_08a904_vsav2.txt): 3 draws on each. The native address lies inside Phobos's vs2 extract region, and our placement map translates ours to it (tenant_caller.log).
THE GATE (A), not built. The rigs are the three chains174 tenant rigs plus the Lei-Lei legacy rig, seeded non-zero and then free. The scratch instrument is promoted as tests/lua/rng_draws.lua. The checks:
(a) Legacy on ours equals pristine vsavj, draw for draw: frame and caller.
(b) Each tenant-code caller draws the same count on both legs. A tenant-code caller is an ours address inside a placement region of that tenant, mapped to native by the placement map, and anchored independently: the native address must lie inside the tenant's vs2 extract region, and the instruction bytes at both must match apart from the jsr target.
(c) The object loop's count is equal.
(d) The engine callers seen on one leg only are frozen as an inventory; a new one fails.
(e) The tap's per-frame counts equal the chain counts of a field trace, the two instruments cross-checked.
Controls, each of which must fail its check: a tenant draw removed from ours; the caller map shifted; the stack read from MAME's SP instead of USP; a planted legacy draw on ours.
NOT tested: tenants other than Phobos (Donovan's and Pyron's rigs were not run); any seed but 5a5a and 0000; any seed frame but 2600; the naming corpus; FBNeo and MiSTer. That per-caller counts stay equal once the two streams have parted is shown only for these two rigs: the drawn VALUES differ after the parting, and a tenant branch that draws conditionally on a drawn value could then count differently with no port defect. That the effect-channel machine's draws are host-engine behaviour rather than a port defect is a reading of the callers (a vsavj engine address drawing on legacy content too), not a separate measurement. The consequence for the parity gates' existing verdicts of every draw returning 0 is not measured.
Artifacts (read every one, in full):
  - build/agent185/t176/probe.sh
  - build/agent185/t176/cmp.py
  - build/agent185/t176/draws.py
  - build/agent185/t176/callers.sh
  - build/agent185/t176/rng_callers.lua
  - build/agent185/t176/seed0000.log
  - build/agent185/t176/seed0000_values.log
  - build/agent185/t176/seed5a5a.log
  - build/agent185/t176/callers.log
  - build/agent185/t176/tenant_caller.log
  - build/agent185/t176/rng_routine_vsavj.txt
  - build/agent185/t176/rng_routine_vsav2.txt
  - build/agent185/t176/caller_0220a0_vsavj.txt
  - build/agent185/t176/caller_020a50_vsav2.txt
  - build/agent185/t176/caller_02a52e_vsavj.txt
  - build/agent185/t176/caller_02a52e_ours.txt
  - build/agent185/t176/caller_42bae2_ours.txt
  - build/agent185/t176/caller_08a904_vsav2.txt
