# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of M0 kickoff session.

**Where we are:** M0 (Bench) **complete and green**. Repo scaffolded, git
live, remote `github.com/DefinitelyFrenchName/VampireSaved`. Reference sets
audited and frozen (`docs/checksums.txt`); MAME 0.288 installed and passing;
CPS-2 decryption ported to Python and proven bit-identical to MAME's;
null-patch build reproduces vanilla vsavj deterministically; 60s attract
determinism green; FBNeo SDL2 built from submodule and boots vsavj headless
(smoke test green). Four committed tests, all PASS.

**M0 acceptance:** all criteria met — see STATE.md "Current milestone" for
the line-by-line status with test names.

**Read next:** HANDOFF.md (operational map), then STATE.md. No open
blockers: `vsav2.zip` arrived mid-session; the reference collection is
complete, all 76 members frozen, and all three sets decrypt bit-identically
to the MAME oracle (images in `build/out/`, SHA-1s in docs/atlas/README.md).

**Likely next actions (M1 — Map):**
1. FBNeo harness decision + minimal RAM-checksum hook in SDL2 frontend
   (recommendation recorded in STATE.md).
2. Start the three-way diff atlas: `vsavj` vs `vsav2` vs `vhunt2` decrypted
   program images.
3. Work-RAM map for match state (attract traces already checksummable).
