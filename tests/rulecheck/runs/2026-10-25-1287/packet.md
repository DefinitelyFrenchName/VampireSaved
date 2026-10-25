THE PACKET

Decision kind: recommendation
Subject: #325 closed done at the next push: run_on_snapshot names each run's snapshot and record with its process id, made atomically (14z-208b, after its close), after withdrawn run 2026-10-25-1286
Claim (the working agent's sentence): #325 can close done at the next push with the closing comment closing_325.md. Its done-when (issue325.md: two snapshot runs of one commit started together each get their own directory, or the second is refused before it touches anything; a gate holds it with a control) is met: evidence325.txt section 1 shows the snapshot and record names gaining the process id and each made by one atomic mkdir that refuses if held; section 2 shows the gate's new section 6 (a stub date pins the stamp, two runs of one commit start together) and control same-name (a copy with the old names); section 3 shows the gate PASS on this Mac, section 6 reading both runs exit 0 in two snapshots with two records, and same-name FIRED (the second run REFUSED); section 4 shows the same-name mode exiting 1; sections 5 and 6 show the 13 controls re-traced SAFE on PILOT on the blob now in the tree and the controls_concurrent row moved to it. The maintainer's words are in maintainer_words325.txt. NOT TESTED: the original mid-setup failures ("unable to write new index file", "Directory not empty") were not reproduced — the control keeps the atomic mkdir, so it shows the shared name and the clean refusal, not the old race; two concurrent snapshot runs of the full tree were not run, only the gate's synthetic tree; the gate ran on this Mac only (PILOT ran its controls under the trace).
Artifacts (read every one, in full):
  - build/agent208/t325/issue325.md
  - build/agent208/t325/evidence325.txt
  - build/agent208/t325/maintainer_words325.txt
  - build/agent208/t325/closing_325.md
