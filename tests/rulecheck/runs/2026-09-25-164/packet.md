THE PACKET

Decision kind: expectation
Subject: 14z-181 #163: the airborne case measured on both moves (audit_column_shock section 1c: class 7 identical on both legs; audit_trap_airborne: the dome hits the falling victim at height 40 and takes the ground path on both games, SWEEP=1 over five more timings) and the ticket CLOSED as done — the second packet, after run 163
Claim (the working agent's sentence): #163's last open item — "a column hit or a Plasma Trap hit on an AIRBORNE victim (the air stager's case) is not measured" — is measured on both moves and the ticket closed as done, the second packet after run 163's findings (all acted on: the timing sweep in the gate, the HP step in the rows, the delivery ids, the maintainer's ruling as an artifact): (1) tests/audit_column_shock.sh gains section 1c and frozen `air` rows: the committed #136 rig donovan_4 with one line added (P2 Demitri up at 2826), both legs real cursor picks with the parity gate's pins (level 6, RNG 0000), the victim's class, freeze, sub-state, HP and height and Donovan's freeze traced every frame 2790-2990 and their STEPS frozen per leg — the column hits at 2838 with the victim at height 103, the victim reads class 7 (the air stager's 0x52 case, as reaction_hook's d2_case_a4 writes it), freeze 11 then 48 decaying, sub-state 6, one hit, the victim's HP 288 -> 283 (the p2hp= step in the row), Donovan's freeze 11 decaying — and the two legs' rows are IDENTICAL; the gate asserts the victim airborne at the hit and the rows equal, a control `air-marker` (our air row with the ground marker 0x38 in place of class 7 must differ from native's) fires in-gate and as a mode, the old-shock control and mode unchanged, the table re-frozen (46 rows) and verified; (2) a new gate tests/audit_trap_airborne.sh + tests/expected/trap_airborne.tsv: the deep-overlap trap rig 92 with one line added (P2 Victor up at 3490), native vsav2 and the merged build with the trap gate's forced-pick pokes, level and RNG pins, the same fields traced 3395-3620 — the dome connects with the victim on his way DOWN at height 40 (f3529) on both legs, the victim's HP 288 -> 285 (the p2hp= step), and the shock plays as on the ground (freeze from 0x18, sub-state 4, Phobos never frozen), the class byte 0x52 native / 0x38 merged exactly as the grounded rig reads it, the legs otherwise identical; the gate's SWEEP=1 mode runs the five other jump timings (3480, 3486, 3500, 3506, 3512) as leg pairs and asserts each legs-equal-but-marker, on the ground path, with the hit at height 40 — run once this sitting, 15/15 ok — so no dome hit reaches the air stager with this rig; the gate asserts the victim airborne at the hit, the legs equal but for the marker, the ground path taken (marker 0x38, sub-state 4), a control `air-class` (the merged rows with the air stager's 7 in place of the marker must fail the frozen compare) fires in-gate and as a mode; frozen, verified, the control mode at FAIL after the sweep edit; (3) the ticket's other open item, the maintainer's read of the column-KO capture, was given 2026-09-19 — their own words "looks clean to me" recorded in DECISIONS_HISTORY.md (the named lines) — the closing comment states both measurements with their gates, the index row (tickets.tsv line 85) is `done` with the four answers, a follow-up comment on the ticket records the sweep and the HP steps; two captures were produced and sent to the maintainer AFTER the RAM measurements, each with its SendUserFile delivery id on its line (the airborne column hit; the trap dome on the jumping Victor at ten frames), the maintainer's reads not given, and no visual conclusion is drawn here. NOT tested: a dome hit at another height (every timing connected at 40) or from a higher jump arc (Victor's neutral jump only), the solo Phobos track's airborne case, the column on an airborne victim at another height or with another attacker, the ES column, whether height 40 is the dome's top edge or the victim's descent speed (the mechanism of "always 40" is not measured); the two legs share the rig's schedule, the forced-pick pokes on the trap side (ff8782/ff8b82, none inside a compared field) and the per-frame level and RNG pins — the parity gates' equalised input, accepted in writing at runs 153-162 (the resolve texts are artifacts) and put to the maintainer under STATE "Decisions pending"; the trap gate's ground-path assertion reads the class marker and sub-state 4 only and the air-class control is caught by the frozen compare, not by that assertion; the sweep timings are asserted but not frozen.
Artifacts (read every one, in full):
  - build/agent181/column_shock_gate_14z181.diff
  - build/agent181/column_shock_table_14z181.diff
  - build/agent181/column_air_freeze2.log
  - build/agent181/column_air_verify2.log
  - build/agent181/column_mode_old-shock.log
  - build/agent181/column_mode_air-marker2.log
  - tests/audit_trap_airborne.sh
  - tests/expected/trap_airborne.tsv
  - build/agent181/trap_air_freeze2.log
  - build/agent181/trap_air_verify2.log
  - build/agent181/trap_air_mode3.log
  - build/agent181/trap_air_sweep.log
  - build/agent181/trap_airborne_sweep_14z181.txt
  - build/agent181/cap_column_airborne.png
  - build/agent181/cap_trap_airborne.png
  - build/agent181/captures_sent_14z181.txt
  - build/agent181/issue163_close.md
  - build/agent181/issue163_posted.txt
  - build/agent181/issue163_comment2.md
  - build/agent181/issue163_posted2.txt
  - build/manifest/donovan.toml.lines-240-256 (lines 240-256 of build/manifest/donovan.toml)
  - tests/audit_trap_shock.sh.lines-1-40 (lines 1-40 of tests/audit_trap_shock.sh)
  - docs/project/tickets.tsv.lines-85-85 (lines 85-85 of docs/project/tickets.tsv)
  - DECISIONS_HISTORY.md.lines-747-751 (lines 747-751 of DECISIONS_HISTORY.md)
  - tests/rulecheck/runs/2026-09-25-163/verdict_real.txt
  - build/agent181/resolve163.txt
  - build/agent181/resolve153.txt
  - build/agent181/resolve156.txt
  - build/agent181/resolve159.txt
  - build/agent181/resolve162.txt
