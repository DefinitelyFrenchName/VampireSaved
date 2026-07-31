# 421K match-end KO bug — repro hunt (session 14z-25, round 38 report)

Maintainer report: Donovan's 421K (at least 421HK) ENDING A MATCH
leaves the opponent in NEUTRAL POSE (no KO fly, no knockdown); the
same move ending a non-final ROUND triggers its hard knockdown
normally.

## Facts established (all runs on build d1db9c0b, POKES facility)

- 421HK structure at tested spacings: hit 1 = LAUNCHER (8 dmg, victim
  flies), then a traveling slide that whiffs on the launched victim.
- Match-end KO on the LAUNCHER hit animates CORRECTLY (victim flies +
  lands flat, YOU WIN over a downed body) in BOTH environments:
  - 2P single-round match (45_*, first phase; HP poked to 1)
  - arcade round-2 match end vs CPU (45_* full; Sasquatch)
  So the bug is NOT "any 421K match-end KO" — it needs the specific
  hit/phase that causes the move's HARD KNOCKDOWN (per the report,
  the round-end reaction) as the killer, which these scripts never
  landed:
  - corner attempt (46_*): launcher connects, rest whiffs
  - full-screen slide (47_*): whiffs entirely
  - mid-sequence HP poke: victim recovers from single-hit hitstun
- CPU-behavior determinism trap: changing POKE VALUES changes CPU
  decisions -> whole choreography reshuffles (an HP poke is an input
  to the AI). Scripted multi-round arcade repros must re-verify every
  downstream phase after ANY poke change.
- Useful timeline (45_*): 2P single-round match KO ~2640; winner
  continues to arcade vs CPU; arcade R1 HP reset ~4050 (actionable
  ~4150), arcade R2 reset ~5700 (actionable ~5800).

## Next

Need the killing-hit configuration from the maintainer (spacing /
victim state when the fatal 421K landed: point-blank all-hits?
mid-range slide? victim airborne or grounded?) OR systematic spacing
sweep landing the hard-knockdown hit as the killer. Then: compare the
victim's node path at match-end vs round-end KO (dump obj+0x1C as in
these scripts) and trace the divergence writer.
