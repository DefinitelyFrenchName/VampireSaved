THE PACKET

Decision kind: recommendation
Subject: report #151 step 1 as done — what a forced-pick native leg gets wrong is measured
Claim (the working agent's sentence): Within the P1 fighter block, a forced-pick native leg differs from a real cursor pick of the same tenant in exactly three LATCHED bytes (+0x3BD, +0x3E0, +0x3C2), for Phobos and Pyron alike; P2's block is asserted empty pre-match on every leg as the negative control; and a same-id poke over Donovan's own confirm latches nothing. What this rests on that the gate does NOT test: the globals ($FF8000-$FF83FF) and the rest of work RAM are reported under MEASURE only and never asserted, so "exactly three" is a statement about the P1 block; two real picks of the same cell by different routes leave route residue (measured under MEASURE, never frozen), so a latched byte is charged to the confirm only inside the P1 block; the SELF leg is a same-value write, so "the poke mechanism is inert" is inferred from SELF together with the donovan-self row rather than from a changed-value write; the rig's shared pokes (the P2 HP pin at $FF8850 from FIRST_EVENT-50, the stock pokes at FIRST_EVENT-60, the level pin from frame 2000 and the RNG pin from 2363, per name_moves.py) address the P2 block or the globals and never the P1 block, so they cannot mask a P1-block latch on both legs; whether any latched byte is READ in play is a separate tap, not this gate. No behavioural conclusion about how the character plays is drawn here.
Artifacts (read every one, in full):
  - audit_forced_pick_fidelity.sh.txt (the gate; a shell script)
  - forced_pick_fidelity.tsv (its frozen expectation)
  - name_moves.py.txt (the rig generator whose schedule and pokes both legs copy)
