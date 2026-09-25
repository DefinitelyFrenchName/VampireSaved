THE PACKET

Decision kind: expectation
Subject: 14z-181 close tier's two reds — re-freeze charmap_pages.sha256 (huitzil/pyron html after a91a555a's move notes) and the must-fire census inventory (+test_close_tools)
Claim (the working agent's sentence): Re-freeze two expectations at the 14z-181 close, the only two reds of the strict tier (PASS 174, FAIL 2): (1) FREEZE=1 tests/test_charmap_current.sh re-freezes huitzil.html and pyron.html in tests/expected/charmap_pages.sha256 to 45a762790a16… and ee3b1456c382…, the pages the move-note edits of commit a91a555a (#169, build/manifest/moves_huitzil.toml and moves_pyron.toml) produce — the separating render from the same build dirs with the pre-a91a555a toml restored reproduces the frozen hashes 3051802fbf20… and 656af2db4357… exactly, and each page differs from it by the one move-note line; the freeze was missed at a91a555a because charmap_pages.sha256 was last frozen at ba7010ed, before it; (2) FREEZE=1 tests/test_must_fire_census.sh adds test_close_tools, the gate this close added, to the declaring inventory — its five MUST-FIRE declarations each fired in the plain run and each of its five modes FAILed on its own plant. The two expectation files' diffs are read before the commit: charmap_pages.sha256 must change exactly the two html rows, must_fire_census.tsv must gain exactly the test_close_tools row. NOT tested: that tools/charmap_html.py renders nothing from the toml but the move list (its docstring says the toml is 'the maintainer's move list'; the render diff shows one line per page); that no OTHER input of the pages changed between ba7010ed and HEAD (the json, md and anim hashes still match in the gate, only the html lines fail); that the donovan page is unaffected (the gate reports it matching); that the census reads a gate's declarations correctly beyond its own two controls (dropped-declaration, neutered-verdict, both FIRED in the run). No behavioural conclusion about how any character plays is drawn: a move-note text and a gate inventory.
Artifacts (read every one, in full):
  - build/agent181/refreeze_close_14z181.txt
  - tests/test_charmap_current.sh
  - tests/test_must_fire_census.sh
  - tests/expected/charmap_pages.sha256
  - tests/expected/must_fire_census.tsv
  - tools/charmap_html.py.lines-1-60 (lines 1-60 of tools/charmap_html.py)
  - build/agent181/tier_close_14z181.log
