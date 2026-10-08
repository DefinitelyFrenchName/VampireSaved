THE PACKET

Decision kind: recommendation
Subject: #124: the build plan for the next session (after run 742) — map name records, two map drawer-bank gates in place of the approved portrait-tile relocation, width words, pool rows, the score ranking's own bank gate in the same build, the gates
Claim (the working agent's sentence): The map's two tag children set $18 = 0x2000 and draw rows of 0x26752A (name) and 0x26762A (mini-portrait) by the id at $A(a6), as vs2's map does with its own arrays; 0x26762A is the select screen's name_banner P2 array, whose tenant rows hold vs2's native codes drawn from WIDE bank 5 at bank 0x3000 (the name_bank_variant_id thunk), so the map at bank 0x2000 draws other tiles — the portrait the maintainer read as 'neither Buletta nor Phobos' on the 14z-194 sheets; the six readers are unpatched on the merged build (test_map_table_readers) and the pool rows have one reader. The plan: a native_c5 select_records row for 0x26752A, two site_thunk bank gates at 0x05FC36 and 0x05FC76 in the splash form (replacing the approved relocation, whose shared rows the select screen also draws), vs2's width words and pool rows, and — because step 1 changes rows the score ranking also reads with no bank word — the ranking's own bank gate in the same build with a sprite-level tenant check in audit_ranking_tenant; a release-scope gate of tenants against native vs2 and the 16 legacy opponents sprite-identical to vsavj, plus the masked corpus and legacy pairings for the thunks' cycles. Not tested: the ranking's OBJ bank bits, vs2's ranking table rows for the tenant ids, the thunks' cycle cost, a capture comparing the name_banner P2 sprites with vs2's map mini-portrait, the merged composition of three single-id gates at one site, whether legacy draws the vsavj tiles at the tenant codes, and the select-banner effect of re-pointing (an inference) — all under Not measured in plan.md; a recommendation for the maintainer, built in the next session.
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
  - build/agent195/scope124/test_map_table_readers.log
  - build/agent195/scope124/issue124_1494_comment.md
  - build/agent195/scope124/issue124_195_comment.md
  - tests/audit_ranking_tenant.sh
  - tools/overlay_port.py
