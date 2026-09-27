THE PACKET

Decision kind: recommendation
Subject: #179: recommend to the maintainer that Phobos's corner landing difference is vsavj's own push-apart rule (close not-ours)
Claim (the working agent's sentence): Recommend closing #179 as not-ours: at huitzil_3 event 8 both fighters stand at the right wall x (1000) as Phobos's Sitting Attack lands, and the push-apart routine — the same instructions in both games (vs2 0x17C6C, vsavj 0x1926A) — moves the fighter in its first register: P1 unless P1's +0x148 is set, which swaps the order; vs2's wall clamp sets +0x148 on the fighter it clamps (st.b at vs2 0x27444 and 0x2745E) and no instruction of vsavj's names +0x148(An) as a store target for a fighter, so on native vs2 P1 (Phobos) keeps the corner and Demitri is pushed out, and on ours — vsavj's engine — Phobos is pushed out; a legacy control (Demitri as P1 against Victor, real picks, both pinned into the corner in one frame) reproduces the same split on pristine vsavj and vs2 (vsavj pushes P1 out, vs2 pushes P2 out and both turn), so the difference is the host engine's rule applied to every character, and making the tenants follow vs2's would either change legacy behaviour or give the tenants a corner rule the other fifteen do not have; NOT tested: a natural legacy case where one fighter lands ON a cornered one (three forward jumps onto a wall-held Victor landed in front of him on both games), the tenant as P2, the branches where a fighter is airborne or +0x115 is set in the resolver, and the other Sitting Attack event (9), which the parity table shows with the same offsets.
Artifacts (read every one, in full):
  - build/agent184/t179/ev8_mechanism.txt
  - build/agent184/t179/push_resolvers.dis
  - build/agent184/t179/push_prologue.dis
  - build/agent184/t179/flag148.txt
  - build/agent184/t179/legacy_control.txt
  - build/agent184/t179/legacy/corner.rpl
  - build/agent184/t179/legacy/run.sh
  - build/agent184/t179/sitting_attack_ev8_landing.png
