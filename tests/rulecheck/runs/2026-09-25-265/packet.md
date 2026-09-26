THE PACKET

Decision kind: recommendation
Subject: #153 (lever B of #148): the census of what a freeze/release static tier reads from outside git, and the proposed design for running it on a scratch clone at a named commit
Claim (the working agent's sentence): A freeze-cadence static tier run in a plain clone of HEAD 12571807 reads PASS 128, SKIP 30, FAIL 20 where the working tree reads 182/0; every one of the 50 non-passing gates names an input git does not carry (build products, the emu/fbneo and emu/jtcores submodules, the sibling bbh repo, the emulator results record), and the build dirs they read split into the current freeze's tracks (which fingerprint to their registry rows) and older reference builds, several of which have no registry row. So the recommendation is D1-D5 of plan_153.md: rebuild the commit's own builds in the clone and require their registry fingerprints; link older reference builds read-only against a new tracked pin list; initialise submodules at the gitlink; clone under ~/.cache (outside the tmp reaper), checked whole, recorded, removed; first slice = the static tier at freeze/release cadence. Not tested (plan_153.md 'Not tested'): the rebuild in a clone, the provenance of the older reference dirs (a pin list freezes today's dirs only), whether a gate writes into a linked dir, the emulator tier's inputs, and inputs read only by controls (the probe ran without controls). The figures are the agent's own runs, not a worker's.
Artifacts (read every one, in full):
  - build/agent183b/plan_153.md
  - build/agent183b/probe153_static.log
  - build/agent183b/probe_nonpass.txt
  - build/agent183b/nonpass_build_refs_class.txt
  - build/agent183b/build_dir_fingerprints.txt
  - build/agent183b/prior_art_reader.txt
