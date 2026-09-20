THE PACKET

Decision kind: expectation
Subject: the per-event stock poke and its two re-freezes
Claim (the working agent's sentence): At 14z-171 tools/name_moves.py replaces the TWO per-part stock pokes (first-60 and the part's MIDPOINT, which tracked nothing: donovan_7 ran 21 events on one 9-stock top-up, donovan_6 19, donovan_4 13) with ONE poke 60 frames before EVERY event of a meter part, so no ES event can fire with an empty meter and degrade silently to its normal version ([VSP-170]); the change moves the poke lists of 14 meter parts and re-freezes tests/expected/move_parity_events.tsv for its `excluded` column ONLY (176 of 506 rows, 531 -> 707 samples, every verdict, offset, field set, live-frame count and coupling byte-identical) and tests/expected/move_parity_attribution.tsv for 4 DF-STOCK roots whose absolute stock at the activation rises while the native-vs-ours delta stays exactly +1. NOT TESTED: no shipped ROM byte moves and no build was rebuilt; the per-event poke EXCLUDES one more stock sample per event from the parity comparison, a coverage loss stated here and not otherwise measured; the separating control is tests/test_move_naming.sh reporting ZERO chain differences with this change alone, but the rig-schedule (PIN_FLOOR) fix that exposed the defect is NOT part of this change and is GitHub #168; whether any OTHER gate outside the eleven re-run here reads these rigs was checked by grep, not by running the full emulator tier.
Artifacts (read every one, in full):
  - tools/name_moves.py
  - tests/expected/move_parity_events.tsv
  - tests/expected/move_parity_attribution.tsv
  - build/rig171/naming_stockonly.log
  - build/rig171/v2/summary.txt
  - build/rig171/mp_verify_stock.log
  - build/rig171/attr_stock.log
