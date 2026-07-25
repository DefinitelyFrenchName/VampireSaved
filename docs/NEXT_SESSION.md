# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of M0 kickoff session.

**Where we are:** M0 (Bench) essentially complete. Repo scaffolded, git live,
remote `github.com/DefinitelyFrenchName/VampireSaved`. Reference sets audited
and frozen (`docs/checksums.txt`); MAME 0.288 installed and passing; CPS-2
decryption ported to Python and proven bit-identical to MAME's; null-patch
build reproduces vanilla vsavj deterministically; 60s attract determinism
test green. FBNeo added as submodule (SDL2 build — check it completed and
runs vsavj; that was in flight at session end).

**M0 acceptance status:**
- null-patch output SHA-1 == reference: **PASS** (`tests/test_null_build.sh`)
- 60s attract replay checksums identical across two runs: **PASS**
  (`tests/test_attract_determinism.sh`, MAME side)
- FBNeo headless runner: **IN FLIGHT** — SDL2 frontend has no Lua; decide the
  FBNeo-side harness approach (frontend patch with RAM-checksum hook +
  its .fr replay format) at the start of M1.

**Read next:** HANDOFF.md (operational map), then STATE.md (open items:
vsav2.zip missing from ROMDIR — needed for M1's three-way diff).

**Likely next actions (M1 — Map):**
1. Obtain/audit `vsav2.zip`, re-freeze checksums with it.
2. FBNeo harness decision + minimal RAM-checksum hook in SDL2 frontend.
3. Start the three-way diff atlas: `vsavj` vs `vsav2` vs `vhunt2` program
   ROMs (decrypt all three with the now-proven tool first).
4. Work-RAM map for match state (attract traces already checksummable).
