THE PACKET

Decision kind: expectation
Subject: #244: the tenant charmap pages print the power class (with the raw byte and nostat/nokill when bit 5 or 7 is set); tests/expected/charmap_pages.sha256 re-frozen — after runs 2026-10-26-1320, -1321 and -1322
Claim (the working agent's sentence): CLAIM: the tenant charmap pages print a record's +8/+9 power byte as its CLASS (the low five bits), followed — when bit 5 (nostat) or bit 7 (nokill) is set — by the raw byte with those flags named, e.g. "6 (0x86 nokill)", as the maintainer ruled ("Class + flags (Recommended)": "the class, plus the raw byte and the flag named when bit 5 or 7 is set", DECISIONS_HISTORY.md 8295-8302); a byte with only bit 6 set (no engine reader on vsavj) prints its class alone. The three tracked tables docs/project/tables/chars/{donovan,huitzil,pyron}.md are regenerated and tests/expected/charmap_pages.sha256 is re-frozen (the three .html hashes change — their power cells' label — and the three _anim.md hashes stay). After runs 2026-10-26-1320, -1321 and -1322. Basis, all on the main tree: the whole change to the two tools against HEAD (v3/tools.diff); oracle.py, the ruled form written from the ruling's words alone and independent of the tools; both tools' cell functions equal it on all 256 byte values and on seven hand-written cases, and two mutant cell functions (run 1320's bit-6 naming; the raw byte dropped) each differ from it (v3/verify_cells.py, verify_cells.out); every one of the 865 record rows, HEAD against the regenerated tables, keeps every other cell and its two power cells equal oracle.py's form of HEAD's raw byte — 467 rows change, 0 mismatches, two perturbed-copy controls FIRED (v3/verify_rows.py, verify_rows.out); the json maps are byte-identical to HEAD (v3/json_vs_head.txt); THE PAGES, two legs: HEAD's frozen hashes (v4/charmap_pages.sha256.HEAD) against today's file — the three .html hashes differ, the three _anim.md equal; the pages as they stood before the change, copied aside before regeneration, hash to HEAD's file, the regenerated ones to today's, and diffed line by line the 103 differing html lines are each the "damage" -> "power class" label alone, 0 otherwise (v4/pages_before_after.txt; the regeneration v3/framedata_pages.log); WHAT THE HTML IS HANDED: tools/charmap_html.py run with power_html logged is handed only raw json bytes, 175 cells, none with bit 5 or 7 set though the json's records carry 690 such bytes, and a planted 0x86 in a scratch json prints "(0x86 nokill)" on the page (v4/html_inputs.py, html_inputs.out) — so on today's pages the html change is the label alone, the 103 cells' census agreeing (v3/html_census.py, html_census.out); test_charmap_current froze (v3/freeze.log) and PASSes (v3/plain.log), each of its three controls as a mode exits 1 with FAIL (v3/mode_*.log); test_power_decode, test_tables_current and test_community_crosscheck PASS (v3/*.log). NOT TESTED: a flagged byte on a real page as published (none is displayed today; the planted control shows the markup path); that 0xFF records are table padding (the ticket's reading); any reader of the tracked tables that parsed the old integer cells (none named here; tools read the json maps, which keep the raw bytes). No gameplay conclusion is drawn: the change is how a documented byte is printed.
Artifacts (read every one, in full):
  - build/agent209/t244/v3/tools.diff
  - build/agent209/t244/v3/oracle.py
  - build/agent209/t244/v3/verify_cells.py
  - build/agent209/t244/v3/verify_cells.out
  - build/agent209/t244/v3/verify_rows.py
  - build/agent209/t244/v3/verify_rows.out
  - build/agent209/t244/v3/json_vs_head.txt
  - build/agent209/t244/v4/charmap_pages.sha256.HEAD
  - tests/expected/charmap_pages.sha256
  - build/agent209/t244/v4/pages_before_after.txt
  - build/agent209/t244/v4/html_inputs.py
  - build/agent209/t244/v4/html_inputs.out
  - build/agent209/t244/v3/html_census.py
  - build/agent209/t244/v3/html_census.out
  - build/agent209/t244/v3/framedata_pages.log
  - build/agent209/t244/v3/freeze.log
  - build/agent209/t244/v3/plain.log
  - build/agent209/t244/v3/mode_changed-built-byte.log
  - build/agent209/t244/v3/mode_empty-page-frozen.log
  - build/agent209/t244/v3/mode_added-override.log
  - build/agent209/t244/v3/test_power_decode.log
  - build/agent209/t244/v3/test_tables_current.log
  - build/agent209/t244/v3/test_community_crosscheck.log
  - DECISIONS_HISTORY.md.lines-8295-8302 (lines 8295-8302 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-25 (14z-209) — #244: the tenant charmap pages show the power class, with the raw by")
