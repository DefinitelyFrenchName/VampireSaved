THE PACKET

Decision kind: recommendation
Subject: #179: recommend to the maintainer that Phobos's corner landing difference is vsavj's own push-apart rule (close not-ours) — re-check on the maintainer-designed legacy control
Claim (the working agent's sentence): Recommend closing #179 as not-ours: at huitzil_3 event 8 both fighters stand at the right stage corner x (1000) as Phobos's pursuit (the Sitting Attack) lands, and the push-apart routine — the same instructions in both games (vs2 0x17C6C, vsavj 0x1926A) — moves the fighter in its first register: P1 unless P1's +0x148 is set, which swaps the order; vs2's wall clamp sets +0x148 on the fighter it clamps (st.b at vs2 0x27444 and 0x2745E), and the vsavj engine has no writer that sets a fighter's +0x148 (statically: its only stores naming $148 are the push routine's clears, a jump table decoded as code and three stores to the global $148(a5); in the tapped runs every vsavj-engine writer stores 0 but the documented boot RAM test) — so on native vs2 Phobos (P1) keeps the corner and Demitri is pushed out, and on ours Phobos is pushed out; the legacy control the maintainer designed — the same characters, positions and inputs on both games, real picks, no position poke, the victim knocked down in the corner by a throw, then a pursuit — reproduces it with an original character: Lilith's pursuit on Victor is identical on pristine vsavj and vs2 until the landing at f3144, then vsavj pushes Lilith out (Victor keeps the corner) and vs2 pushes Victor out (Lilith keeps the corner, turned), captured and sent to the maintainer; Jedah shows the same end, and the other eleven original characters' pursuits land in front of Victor on both games; so the difference is the host engine's rule applied to original characters as to Phobos, and making the tenants follow vs2's would either change legacy behaviour or give the tenants a corner rule the others do not have; NOT tested: the tenant or the legacy attacker as P2, the branches where a fighter is airborne or +0x115 is set in the resolver, any +0x148 writer outside the runs tapped, the other Sitting Attack event (9), Jedah's run beyond its end state (it differs from the throw on in fields other than x), and the three characters vs2's wheel cannot reach (Gallon, Aulbath, Sasquatch).
Artifacts (read every one, in full):
  - build/agent184/t179/ev8_mechanism.txt
  - build/agent184/t179/push_resolvers.dis
  - build/agent184/t179/push_prologue.dis
  - build/agent184/t179/flag148.txt
  - build/agent184/t179/flag148_context.txt
  - build/agent184/t179/legacy_pursuit_control.txt
  - build/agent184/t179/legacy/sweep.sh
  - build/agent184/t179/legacy/sweep_read.py
  - build/agent184/t179/legacy_lilith_pursuit_sheet.png
  - build/agent184/t179/sitting_attack_ev8_landing_labelled.png
  - build/agent184/t179/captures_sent.txt
  - build/agent184/t179/view_and_reads.txt
