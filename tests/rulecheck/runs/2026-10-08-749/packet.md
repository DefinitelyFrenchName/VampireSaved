THE PACKET

Decision kind: recommendation
Subject: #124: the build plan for the next session (after runs 742-748) — a sampled read watch over every row it rewrites first, then map name records, two map drawer-bank gates in place of the approved portrait-tile relocation, width words, pool rows, the score ranking's own bank gate, the gates
Claim (the working agent's sentence): The map's two tag children set $18 = 0x2000 and draw rows of 0x26752A (name) and 0x26762A (mini-portrait) by the id at $A(a6), as vs2's map does with its own arrays, through the same format dispatcher (PRG:0x01AFA6) that draws the select screen's records; 0x26762A is the select screen's name-banner P2 array (the atlas's table, "Measured for M3a", reached through 0x2675AA + 0x80), whose tenant rows hold vs2's native codes drawn from WIDE bank 5 at bank 0x3000, so the map at bank 0x2000 draws other tiles — the portrait the maintainer read as 'neither Buletta nor Phobos'; the session's earlier 'the select screen reads neither array' is retracted. The plan: FIRST, step 0 of build/agent195/scope124/plan.md, before any byte changes, MAME debugger read watchpoints over the rows the build rewrites — 0x26752A and 0x26762A tenant rows with the P1 twins at 0x2675AA, the three pool rows, and the width-word rows of 0x0603DE/0x06041E at ids 0x10 and 0x13 — across a sample of screens and roles (select, VS splash, the fight, map, win quote, continue, ranking with name entry, ending, attract; a tenant as player and as CPU) on pristine vsavj and merged-m23, with the select screen's known read of 0x26762A's P2 rows as the positive control, each reader found joining the gates; then a native_c5 select_records row for 0x26752A, two site_thunk bank gates at 0x05FC36 and 0x05FC76 in the splash form (replacing the approved relocation, since the select screen draws the same rows), vs2's width words and pool rows, the score ranking's own bank gate in the same build (step 1 changes rows it reads with no bank word), judged on the tenant entry against native vs2 AND on the legacy entries against vsavj, each with a splice control; a release-scope gate of map tenants against native vs2 and the 16 legacy opponents sprite-identical to vsavj, plus the masked corpus and legacy pairings for the map thunks' and the ranking hook's cycles. Not tested: the items under Not measured in plan.md — the ranking's OBJ bank bits, which palette the ranking applies to a portrait, vs2's ranking table rows for the tenant ids, the hooks' cycle cost, a capture of name_banner P2 against vs2's map mini-portrait, the merged composition of three single-id gates, whether legacy draws the vsavj tiles at the tenant codes, the select banner after re-pointing (inferred), a reader of any of the rewritten rows from another base or of the width-word rows other than the map's tag child (until step 0 runs, and after it on any screen, state or role step 0 does not visit; palette RAM is invisible to RAM gates), and how the dispatcher turns $18 into the bank; a recommendation for the maintainer, built in the next session.
Artifacts (read every one, in full):
  - build/agent195/scope124/plan.md
  - build/agent195/scope124/vsavj_map_children.txt
  - build/agent195/scope124/vsavj_ranking_reader.txt
  - build/agent195/scope124/vsavj_ranking_drawer.txt
  - build/agent195/scope124/vs2_map_children.txt
  - build/agent195/scope124/vs2_ranking_reader.txt
  - build/agent195/scope124/vs2_array_refs.txt
  - build/agent195/scope124/splash_thunk_excerpt.txt
  - build/agent195/scope124/name_banner_records_excerpt.txt
  - build/agent195/scope124/name_bank_thunk_excerpt.txt
  - build/agent195/scope124/atlas_select_arrays_excerpt.txt
  - build/agent195/scope124/roulette_mechanism_excerpt.txt
  - build/agent195/scope124/test_map_table_readers.log
  - build/agent195/scope124/issue124_1494_comment.md
  - build/agent195/scope124/issue124_195_comment.md
  - tests/audit_ranking_tenant.sh
  - tools/overlay_port.py
