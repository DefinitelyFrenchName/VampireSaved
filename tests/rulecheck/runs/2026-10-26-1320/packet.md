THE PACKET

Decision kind: expectation
Subject: #244: the tenant charmap pages print the power class (with the raw byte and named flags when set); tests/expected/charmap_pages.sha256 re-frozen
Claim (the working agent's sentence): CLAIM: apply build/agent209/t244/fix244.diff (tools/charmap_md.py power_cell, tools/charmap_html.py power_html, and the three tracked tables docs/project/tables/chars/{donovan,huitzil,pyron}.md regenerated) and freeze tests/expected/charmap_pages.sha256 to the candidate (the three .html hashes change, the three _anim.md hashes stay), so the tenant charmap pages show a record's +8/+9 power byte as its CLASS (b & 0x1F, tools/hitbox_records.py power(), the #241 decode) with the raw byte and its named flags beside it when a flag bit is set, as the maintainer ruled ("Class + flags (Recommended)", DECISIONS_HISTORY.md 8295-8302). Basis: the tool change is only the two cell functions and the column labels (fix244_tools.diff); every one of the 865 record rows of the three tables, HEAD against the diff applied, keeps every other cell, and its two power cells equal power_cell() of HEAD's raw byte — 467 rows change, each one with a flag bit set, 0 mismatches, two perturbed-copy controls FIRED (verify/verify_rows.py, verify_rows.out); in fork C's worktree at 2aacebe8 test_charmap_current PASSes on the candidate with its three controls FIRED and each as a mode exiting with FAIL (after_charmap.log, mode_*.log), FAILs against today's frozen file (after_charmap_vs_frozen.log: the drift is the html), and the candidate was written by the gate's own freeze (freeze_candidate.log); test_power_decode, test_tables_current and test_community_crosscheck PASS (after_*.log). NOT TESTED: the html strips beyond their hash — fork C counted 103 cells relabelled and 0 whose shown value moved, and nothing here re-measures that count; the gates on the main tree with #321 phase 2 applied (they ran in the fork's worktree at 2aacebe8; the commit's static tier runs them); the flag naming goes beyond the ruling's example in one point: bit 6, which no engine reader uses on vsavj (tools/hitbox_records.py's power() docstring), is also named ("bit6") when set, so the 0xFF bytes the fork read as table padding print as e.g. "31 (0xff nostat bit6 nokill)" — the maintainer saw only the bit-5/bit-7 example; that 0xFF records are padding is the ticket's reading, not measured here; the JSON maps keep the raw bytes (unchanged, byte-identical). No gameplay conclusion is drawn: the change is how a documented byte is printed.
Artifacts (read every one, in full):
  - build/agent209/t244/fix244_tools.diff
  - build/agent209/t244/verify/verify_rows.py
  - build/agent209/t244/verify/verify_rows.out
  - tools/hitbox_records.py.lines-60-81 (lines 60-81 of tools/hitbox_records.py)
  - tests/expected/charmap_pages.sha256
  - build/agent209/t244/charmap_pages.sha256.candidate
  - build/agent209/t244/after_charmap.log
  - build/agent209/t244/after_charmap_vs_frozen.log
  - build/agent209/t244/freeze_candidate.log
  - build/agent209/t244/mode_added-override.log
  - build/agent209/t244/mode_changed-built-byte.log
  - build/agent209/t244/mode_empty-page-frozen.log
  - build/agent209/t244/after_power.log
  - build/agent209/t244/after_test_tables_current.log
  - build/agent209/t244/after_test_community_crosscheck.log
  - build/agent209/t244/evidence244.md
  - DECISIONS_HISTORY.md.lines-8295-8302 (lines 8295-8302 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-25 (14z-209) — #244: the tenant charmap pages show the power class, with the raw by")
