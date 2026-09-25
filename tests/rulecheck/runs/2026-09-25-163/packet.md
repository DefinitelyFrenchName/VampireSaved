THE PACKET

Decision kind: expectation
Subject: 14z-181 #163: the airborne case measured on both moves (audit_column_shock section 1c: class 7 identical on both legs; audit_trap_airborne: the dome hits the falling victim at height 40 and takes the ground path on both games) and the ticket CLOSED as done
Claim (the working agent's sentence): #163's last open item — "a column hit or a Plasma Trap hit on an AIRBORNE victim (the air stager's case) is not measured" — is measured on both moves and the ticket closed as done: (1) tests/audit_column_shock.sh gains section 1c and frozen `air` rows: the committed #136 rig donovan_4 with one line added (P2 Demitri up at 2826), both legs real cursor picks with the parity gate's pins (level 6, RNG 0000), the victim's class, freeze, sub-state, HP and height and Donovan's freeze traced every frame 2790-2990 and their STEPS frozen per leg — the column hits at 2838 with the victim at height 103, the victim reads class 7 (the air stager's 0x52 case, as reaction_hook's d2_case_a4 writes it), freeze 11 then 48 decaying, sub-state 6, one hit (288 -> 283), Donovan's freeze 11 decaying — and the two legs' rows are IDENTICAL; the gate asserts the victim airborne at the hit and the rows equal, a new control `air-marker` (our air row with the ground marker 0x38 in place of class 7 must differ from native's) fires in-gate and as a mode, the old-shock control and mode unchanged, the table re-frozen (46 rows) and verified; (2) a new gate tests/audit_trap_airborne.sh + tests/expected/trap_airborne.tsv: the deep-overlap trap rig 92 with one line added (P2 Victor up at 3490), native vsav2 and the merged build with the trap gate's forced-pick pokes, level and RNG pins, the same fields traced 3395-3620 — the dome connects with the victim on his way DOWN at height 40 (f3529) on both legs and the shock plays as on the ground (freeze from 0x18, sub-state 4, Phobos never frozen), the class byte 0x52 native / 0x38 merged exactly as the grounded rig reads it, the legs otherwise identical; six jump timings (3480, 3486, 3490, 3500, 3506, 3512) all connected at height 40 and never higher or on the ground, so no dome hit reaches the air stager with this rig; the gate asserts the victim airborne at the hit, the legs equal but for the marker, the ground path taken (marker 0x38, sub-state 4), a control `air-class` (the merged rows with the air stager's 7 in place of the marker must fail the frozen compare) fires in-gate and as a mode; frozen, verified; (3) the ticket's other open item, the maintainer's read of the column-KO capture, was given 2026-09-19 ("looks clean to me", quoted on the ticket); the closing comment states both measurements with their gates, the index row is `done` with the four answers, a capture of the airborne column hit on both legs was produced and sent AFTER the RAM measurement (its delivery recorded), the maintainer's read not given. NOT tested: a dome hit at another height (every timing connected at 40) or from a higher jump arc (Victor's neutral jump only), the solo Phobos track's airborne case, the column on an airborne victim at another height or with another attacker, the ES column, whether height 40 is the dome's top edge or the victim's descent speed (the mechanism of "always 40" is not measured), and the two legs share the parity gates' per-frame level and RNG pins and, for the trap, the forced-pick pokes on both games (the trap rig's design since 14z-85g(2)) — the equalised input accepted in writing at runs 153-162 and before the maintainer; the airborne column's equality is a RAM measurement, the visual read pending.
Artifacts (read every one, in full):
  - build/agent181/column_shock_gate_14z181.diff
  - build/agent181/column_shock_table_14z181.diff
  - build/agent181/column_air_freeze.log
  - build/agent181/column_air_verify.log
  - build/agent181/column_mode_old-shock.log
  - build/agent181/column_mode_air-marker.log
  - tests/audit_trap_airborne.sh
  - tests/expected/trap_airborne.tsv
  - build/agent181/trap_air_freeze.log
  - build/agent181/trap_air_verify.log
  - build/agent181/trap_air_mode.log
  - build/agent181/cap_column_airborne.png
  - build/agent181/captures_sent_14z181.txt
  - build/agent181/issue163_close.md
  - build/agent181/issue163_posted.txt
  - build/manifest/donovan.toml.lines-240-256 (lines 240-256 of build/manifest/donovan.toml)
  - tests/audit_trap_shock.sh.lines-1-40 (lines 1-40 of tests/audit_trap_shock.sh)
  - docs/project/tickets.tsv.lines-1-5 (lines 1-5 of docs/project/tickets.tsv)
