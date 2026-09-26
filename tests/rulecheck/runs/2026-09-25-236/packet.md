THE PACKET

Decision kind: expectation
Subject: M20 freeze: re-freeze the two static build-following expectations (test_reaction_classes' ours build row; test_charmap_current's page hashes) on the M20 builds (after run 235)
Claim (the working agent's sentence): On the M20 builds the only differences from the frozen expectations are the build identity: test_reaction_classes differs from tests/expected/reaction_classes.tsv in exactly its 'ours build' row (merged-m19 61e9815a -> merged-m20 c707b25e) with all 204 census rows otherwise identical (reaction_classes.before.log); the three regenerated charmap pages differ from their committed M19 versions only in the build dir, the manifest hash, the verify_data.bin hash and sha1_ours (chars_pages.diff); the character pages regenerated from the M19 builds with the M19 JSON hash EQUAL to the frozen charmap_pages.sha256 lines (m19_regen_vs_frozen.txt), and the M20 pages differ from those only in the build dir token (the *.html.m19_vs_m20.diff files), while the three anim pages equal their frozen hashes (framedata_pages.log); so FREEZE=1 on both gates records the M20 build and moves nothing else. NOT tested: why verify_data.bin moved is attributed only to the six program words per track (deltas_measurer.txt), not traced byte by byte; the tenant pages' rows did not change, so nothing about the tenants' behaviour is concluded here.
Artifacts (read every one, in full):
  - build/rc183/refreeze/reaction_classes.before.log
  - build/rc183/refreeze/charmap.before.log
  - build/rc183/refreeze/chars_pages.diff
  - build/rc183/refreeze/framedata_pages.log
  - build/rc183/refreeze/m19_regen_vs_frozen.txt
  - build/rc183/refreeze/donovan.html.m19_vs_m20.diff
  - build/rc183/refreeze/huitzil.html.m19_vs_m20.diff
  - build/rc183/refreeze/pyron.html.m19_vs_m20.diff
  - build/rc183/refreeze/deltas_measurer.txt
