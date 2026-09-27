THE PACKET

Decision kind: recommendation
Subject: #181: the emulator tier on a snapshot — design options put to the maintainer (re-check after run 277)
Claim (the working agent's sentence): The recommendation to put to the maintainer for #181's design is Q1 (b) a copy-on-write snapshot of ~/.cache/vampire-saved under a run-private HOME whose other entries are symlinks to the real HOME's, with sha256 hashes of the instrument binaries at start and end, Q2 (a) every tracked file's mtime set to its last-commit time, Q3 (a) the run's build/emu_* copied back into the working tree, Q4 (a) copy-on-write copies of the jtsim scratch clones; it rests on four snapshot runs of the prereq and fbneo lanes (26 gates each: A with an empty HOME, 16 non-PASS; C with a HOME holding only the three cache binaries, which turned 15 of those 16 into PASS and left test_wide_profile failing only on an mtime comparison; B with the real HOME and D with the Q1 (b) prototype, each PASS 25 / FAIL 1 on that same mtime comparison) and on a static grep of the mame and mister lanes; NOT tested: the mame and mister lanes in a snapshot (so neither whether they read anything else through HOME nor whether the prototype breaks them), any option built, the Q2 outcome on test_wide_profile, and whether the host tools (Homebrew SDL, Verilator) moved.
Artifacts (read every one, in full):
  - build/agent184/c181/plan_181.md
  - build/agent184/c181/runA/results.tsv
  - build/agent184/c181/runB/results.tsv
  - build/agent184/c181/runC/results.tsv
  - build/agent184/c181/runD/results.tsv
  - build/agent184/c181/runA_attribution.tsv
  - build/agent184/c181/runAC_transitions.tsv
  - build/agent184/c181/static_census.tsv
  - build/agent184/c181/literal_readers.txt
  - build/agent184/c181/runB/test_wide_profile.log
  - build/agent184/c181/runC/test_wide_profile.log
  - build/agent184/c181/cache_diff.txt
  - tests/test_wide_profile.sh.lines-88-110 (lines 88-110 of tests/test_wide_profile.sh)
  - tools/audit_emulator_staleness.py.lines-55-75 (lines 55-75 of tools/audit_emulator_staleness.py)
  - tests/run_all_emulator.sh.lines-300-330 (lines 300-330 of tests/run_all_emulator.sh)
