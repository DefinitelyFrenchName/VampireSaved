THE PACKET

Decision kind: recommendation
Subject: #159: fix with Design A (a thunk at vsavj's facing resolver 0x1886C adding vs2's rule 5), measured on a probe first; Design B (data only) not viable (re-checked after 362)
Claim (the working agent's sentence): Recommend to the maintainer, for #159 (the maintainer: "do #182, #176, #174, #159 in that order"; the issue left the fix "the maintainer's to schedule", maintainer_159.txt): fix it with DESIGN A, an engine hook that teaches vsavj's facing resolver vs2's rule 5. Measure it on a probe build first, as #182's Design A was, before any shipped byte moves.
THE TWO RESOLVERS (resolver_vsavj.txt, resolver_vsav2.txt):
- vsavj's (0x18854) tests rules 2, 3 and 4 and the negative case. Anything else falls through to eor.b d0,$5d(a1); bra.b $188b8 at 0x1886C (6 bytes).
- vs2's (0x1717E) adds cmpi.b #5 / beq 0x171D6. There, facing := 1 if the attacker's +0x40 (x velocity) is >= 0, else 0, then rts.
DESIGN A: replace vsavj's 6 bytes at 0x1886C with jmp <thunk>.l. The thunk: cmpi.b #5,d0; bne -> eor.b d0,$5d(a1); jmp $188b8. Rule 5 -> vs2's branch (moveq #0,d0; tst.w $40(a6); bmi; addq.b #1,d0; move.b d0,$5d(a1); rts).
DESIGN B (data only) is NOT viable. It would rewrite the tenants' rule-5 records to a rule vsavj already has; such a fix runs on OURS, through vsavj's resolver. So rules_all.py evaluates every rule vsavj has from OURS' state at each of Killshread Summon (ES)'s six resolver writes (the donovan_3 rig, 3850-3960; probe.sh and facing_probe.lua read every rule's input at the write, with vsavj's own variables). It compares each against what NATIVE writes at the same frame (rules_all.log; the frames match, 6 against 6). Native writes 1, 1, 1, 0, 0, 0. Against that:
- rules 0, 2 and 4 would write 1 at all six. Rule 4's object on ours is $FF8400, the other fighter, the rule's documented meaning.
- rule 1 would write 0 at all six;
- rule 3 would write 6 at all six;
- the negative rule would write 1, 0, 0, 0, 0, 0.
Only vs2's rule 5 reproduces native at every contact.
WHAT A TOUCHES. Every contact whose rule is not 2, 3, 4 or negative runs the thunk. That is legacy records too: vsavj's reachable legacy records (facing_census_doc.txt) are rule 0 on 1017 of 1085 and rule 1 on 23 (facing_rule_head.txt). On ours, three contacts at 2666-2685 already have their resolver write come from the fall-through 0x1886C (rules_vs_probe.log). For those the thunk does the original eor and returns to the original tail, so the result is the same. It adds a jmp, a compare and a branch per such contact. No legacy record carries rule 5 (vsavj 0 of 1085, facing_rule_head.txt), so the new branch is taken only for tenant records.
THE MEASUREMENTS BEFORE A BUILD, on a probe (a copy of the manifest with the row, as for #182):
- tests/audit_facing_rule.sh: ours must write native's values (1, 1, 1, 0, 0, 0) and move Demitri as native does.
- the merged legacy oracle: identical to the shipped build on its replays, and the thunk shown to run on legacy content.
- a capture of the Summon, native / shipped / probe, put before the maintainer.
- the cycle cost, measured rather than estimated.
NOT tested:
- Design A itself (no probe built yet);
- the four other rule-5 records named in the issue (0xCA1CA, 0xCA1EA, 0xD17C2, 0xD1822), whose effect is unmeasured;
- rule 5 reached by a fighter rather than a projectile as the attacker;
- P2-side tenants;
- FBNeo and MiSTer;
- the cycle cost.
Design B was measured on this one move only. The probe ran build/m3b_merged28, while the frozen facing_rule.tsv was taken on merged-m18 (its header). The frozen native writer at 3882 is the pre-resolver write 0x017178, which the probe also logs and uses as rules 0/1's prior.
Artifacts (read every one, in full):
  - build/agent185/t159/maintainer_159.txt
  - build/agent185/t159/resolver_vsavj.txt
  - build/agent185/t159/resolver_vsav2.txt
  - build/agent185/t159/probe.sh
  - build/agent185/t159/facing_probe.lua
  - build/agent185/t159/rules_vs_probe.log
  - build/agent185/t159/rules_all.py
  - build/agent185/t159/rules_all.log
  - build/agent185/t159/facing_rule_head.txt
  - build/agent185/t159/facing_census_doc.txt
