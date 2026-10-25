THE PACKET

Decision kind: recommendation
Subject: #319 closed done at the next push: tests/expected/ground_throws.tsv holds hashes, the per-move lines outside the tree (14z-208b, after its close)
Claim (the working agent's sentence): #319 can close done at the next push with the closing comment closing_319.md. Its done-when (issue319.md: the gate that reads ground_throws.tsv freezes a hash or verdicts in the tree and keeps the per-move rows outside it; the file's history left as is unless ruled) is met: evidence319.txt section 1 shows the change to tools/ground_throw_rigs.py (freeze writes the full lines to GT_FULL outside the tree and prints sheet, key, input and a 16-hex SHA-256; expect compares the hashed line; snaps reads the first-fall offsets from the full file); section 2 shows the in-tree file holding 70 data lines of four columns; section 3 shows the 70 full lines outside the tree byte-identical to the plain lines the file held before, and the in-tree hashes equal to those lines hashed; section 4 shows the gate on the hashed file PASS on this Mac, 70 events 0 bad, 70 snapshots, every control fired; section 6 shows the history untouched. The ruling is the maintainer's words in maintainer_words319.txt. NOT TESTED: the gate was run on this Mac only, not on PILOT or ERIS; a host without the full file (no snapshots, the sheet section's NOTE) was not run; the generated page docs/project/tables/community_crosscheck.md, whose generator's prose now says hashes, is not yet regenerated (the close's bookkeeping); the earlier plain-text lines remain in git history by the done-when's default.
Artifacts (read every one, in full):
  - build/agent208/t319/issue319.md
  - build/agent208/t319/evidence319.txt
  - build/agent208/t319/maintainer_words319.txt
  - build/agent208/t319/closing_319.md
