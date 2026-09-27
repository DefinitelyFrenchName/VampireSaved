THE PACKET

Decision kind: recommendation
Subject: #179: recommend closing as not-ours with the difference documented and gated — re-check after run 290 on the narrowed claim
Claim (the working agent's sentence): Recommend closing #179 as not-ours, the difference documented and gated, on the maintainer's reading of the Lilith capture ("from what I see it seems indeed to be an engine-wide property. If so, the vanilla engine works BUT we aboslutely must document this difference in the two games"): the push-apart routine is the same code in both games (vsavj 0x01926A, vs2 0x017C6C) and, when both fighters are walled and grounded, moves the fighter in its first register — P1, unless P1's +0x148 is set, which swaps the order; vs2's view clamp sets +0x148 on the fighter it clamps (st.b at 0x027444 and 0x02745E) and vsavj's clamp is the same code without those two stores; so on a shared wall vsavj pushes P1 out and vs2 pushes P2 out — at huitzil_3 event 8 ours pushes Phobos (P1) out at 0x0193B2 and native pushes Demitri (P2) out at 0x017DB4, and the one clean legacy control, Lilith (P1) on Victor (P2) by real picks with the same positions and inputs, identical on pristine vsavj and vs2 until the landing at f3144, splits the same way at the same PCs; tests/audit_shared_wall_push.sh freezes both parts with two must-fire controls. NOT tested: the attacker as P2, the resolver's airborne and +0x115 branches, any +0x148 writer outside the tapped runs, Sitting Attack event 9, and every other legacy character — none of the sweep's other runs is a clean control (they differ from the throw onward, never share x, or run no pursuit), so nothing is concluded from them.
Artifacts (read every one, in full):
  - build/agent184/t179/push_resolvers.dis
  - build/agent184/t179/push_prologue.dis
  - build/agent184/t179/clamp.dis
  - build/agent184/t179/flag148.txt
  - build/agent184/t179/flag148_context.txt
  - build/agent184/t179/lilith_mechanism.txt
  - build/agent184/t179/ev8_mechanism.txt
  - build/agent184/t179/legacy_pursuit_control.txt
  - build/agent184/t179/captures_sent.txt
  - build/agent184/t179/legacy_lilith_pursuit_sheet.png
  - build/agent184/t179/sitting_attack_ev8_landing_labelled.png
  - tests/audit_shared_wall_push.sh
  - tests/expected/shared_wall_push.tsv
  - build/agent184/t179/gate_run_plain.log
  - build/agent184/t179/gate_run_flag-planted.log
  - build/agent184/t179/gate_run_legs-swapped.log
