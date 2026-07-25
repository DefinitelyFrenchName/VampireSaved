# STATE — living progress log

Updated: 2026-07-25 (M0 kickoff session — bench built and green)

## Current milestone

M0 — Bench. **Nearly complete.** Acceptance status:
- Null-patch output bit-identical to reference: **PASS** (`tests/test_null_build.sh`)
- 60s attract replay deterministic across two runs: **PASS** (`tests/test_attract_determinism.sh`, MAME)
- Headless MAME runner: **DONE** (`tools/run_mame.sh`, MAME 0.288 via Homebrew)
- Headless FBNeo runner: **IN FLIGHT** — submodule added (`emu/fbneo`), SDL2
  build was compiling at session end; frontend has no Lua, so the FBNeo-side
  harness needs a decision (see below)

Bonus beyond plan: CPS-2 decryption/encryption pipeline
(`tools/cps2_decrypt.py`) proven bit-identical to MAME's implementation via
opcode-space dump oracle (`tests/test_decrypt_oracle.sh`). Both directions
(decrypt for analysis, encrypt for future patch injection) self-check.

## Next actions

1. **Confirm FBNeo build** completed; smoke-run vsavj in it.
2. **FBNeo harness approach (M1 entry):** SDL2 frontend has replay
   (`replay.cpp`) and savestate support but no Lua. Options: (a) small
   frontend patch adding a per-frame work-RAM checksum dump + headless/exit
   flags (frontend, not emulation core — allowed); (b) drive via its .fr
   replay format only. Recommendation: (a); it mirrors the MAME Lua probe.
3. **Obtain `vsav2.zip`** (see Open items) and re-freeze `docs/checksums.txt`.
4. Start M1: decrypt all three sets, three-way program diff, work-RAM map.

## Open items

- **`vsav2.zip` is not in ROMDIR.** Present: vsav, vsavj, vhunt2, vhunt2r1,
  qsound_hle (all audited clean, MAME `-verifyroms` green). VS2 is the
  authoritative character-data base (SPEC §3.1) and one of M1's three
  diff inputs — needed before M1 can fully start. Human to supply the dump.
- ROM packaging fixes from the 2026-07-25 audit are confirmed applied:
  `vhunt2.key` present in both vhunt2 zips (CRC 61306b20), `qsound_hle.zip`
  present (`dl-1425.bin` CRC d6cf5ef5). Frozen in `docs/checksums.txt`.

## Decisions made

- **Project name = "Vampire Saved"** — 2026-07-25, maintainer.
- **Base revision = `vsavj` (Japan 970519)** — 2026-07-24, maintainer. Closed.
- **Checksum manifest is per-member**, so zip repackaging never matters —
  2026-07-25, session decision (mechanical, no gameplay impact).
- **Raw-image byte-order convention** — 2026-07-25, session decision: ROM
  files are LE-word storage; all derived images are 68k logical (BE) order.
  See docs/GOTCHAS.md first entry.

## Decisions pending (human)

- See SPEC §7. None blocks M0 wrap-up or early M1 (diff/atlas work).

## Open bugs

None.

## Findings log

- 2026-07-25: vsavj key master `0xfa8f4e33a4b881b9`; opcode-encrypted range
  is only `PRG:0x000000-0x0FFFFF` (first 1MB of 4MB). Watchdog:
  `cmpi.l #$726A4BAF, D0`. (From key block; confirmed against MAME `-log`.)
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
