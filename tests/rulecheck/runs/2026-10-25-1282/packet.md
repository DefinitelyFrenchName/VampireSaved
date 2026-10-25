THE PACKET

Decision kind: recommendation
Subject: #326 closed done at the next push: test_release_reuse's synthetic repo takes the real .gitignore's bytecode lines (14z-208b, after its close)
Claim (the working agent's sentence): #326 can close done at the next push with the closing comment closing_326.md. Its done-when (issue326.md: the gate PASSes on PILOT with every control firing, and on the Mac as before) is met: evidence326.txt section 1 shows the one change, the synthetic repo's .gitignore made from the real .gitignore's two bytecode lines and checked present, the working tree's script being the same blob as the commit object PILOT ran; section 2 shows, on PILOT in a scratch clone, the gate FAIL before the change (5 controls fired, 2 dead) and PASS after it with 7 controls fired and none dead; section 3 shows PASS with 7 controls fired on the Mac; sections 4 to 6 show the controls re-traced SAFE on PILOT, the controls_concurrent row moved to the new blob, and test_controls_concurrent PASS. The cause (Linux Python writing tools/__pycache__ into the synthetic repo during the freeze run, counted by the identity's untracked key) was measured when the ticket was filed (issue326.md). The maintainer's words are in maintainer_words326.txt. NOT TESTED: other Linux distributions or Python versions; a Linux Python with a pycache prefix set; the before and after runs on PILOT ran once each; the cause was not re-measured on the after run (no identity readout of the after run is in the evidence), only the verdict and the controls.
Artifacts (read every one, in full):
  - build/agent208/t326/issue326.md
  - build/agent208/t326/evidence326.txt
  - build/agent208/t326/maintainer_words326.txt
  - build/agent208/t326/closing_326.md
