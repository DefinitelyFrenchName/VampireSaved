# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-28, end of session 14. **M2a IS FROZEN** and
**M2b-CORE IS FROZEN** (`71601263474dfd7e4afd0741dae696cde22eda4e` ->
expectation set `donovan-m2b`; build with
`tools/build_donovan.sh 6 build/donovan6`, rompath carries BOTH
vsavj.zip and the patched vsav.zip). Sprites/palettes/effects verified;
still Jedah: select big portrait, name banner, mugshot; attract
palette. Select-web map + next step: docs/engine_internals.md
("Select-screen pipeline", phase-1 corrections at the end). Roster
ACCESS mechanism decision recorded in STATE Decisions pending
(recommendation: Oboro-pattern combined input). Older M2a text below
for reference:

Original M2a freeze notes: Fingerprint
`a02aeefff4c7a053337b10c923c8c328573788fa`, registered in
`tests/expected/registry.tsv` as expectation set `donovan-m2`. Maintainer
playtest round 3 fully clean: no crashes over multiple matches, no music
from any input.

**Build it:** `GEN_FLAGS="--allow-plausible --tripwire-open"
tools/build_donovan.sh 5 build/donovan5` (expect the fingerprint above).

**Validate anything with one command:**
`ROMDIR=... [MAME_ROMPATH="<rompath>;$ROMDIR"] tests/run_suite.sh` — the
runner fingerprints the build and auto-selects expectations. New kinds
landed at the freeze: `.masked` (hooked-build legacy basis, CLAUDE.md §4
v2 — exact / flicker-with-frozen-inventory / diverge classes) and
`.skip` (other-romset replays). GREEN on both vanilla and the frozen
build. The stage gates (`tests/test_m2a_stage4_{code,oracle,xemu}.sh`,
`test_m2a_flavor_selector.sh`) remain the deep battery.

**Session 14's lesson (GOTCHAS, paid for twice):** sound-farm entries
mapped by the session-5 bare-long byte-matcher masqueraded as
`engine_data` and byte-matched the SAME-ID vsavj entries — music on
214P/214K. When a structure class gets understood, re-audit earlier
generic rows in its range by mechanism. Also: sound wrongness is
invisible to every RAM-basis gate (QSound RAM) — playtest is the only
detector until M5 builds a harness.

**Next: M2b — Donovan graphics** (docs/M2_feasibility.md: the R2 tile
wall). Start by measuring: slot-0x0F tile inventory (sprites, portrait,
name), what garbled-but-recognizable implies about index-vs-data
remapping, and whether M3 (gfx ROM extension via descriptor lines only)
must be pulled forward. Feel-wrong playtest findings become replays.

**Parked lists:** M5 sound restoration (25 stubbed farm rows + the
0x271B6 dispatcher id table, all recorded in reconciliation.toml),
Huitzil/Pyron tripwired handlers (M3), bank-tail parked tables
(0xBF01A-19A data rows, 0xBF59A engine rows), 0x2c31xx data opens
(likely Anita DF-only).

**Read:** STATE.md (session 14 highlights + Decisions made),
docs/patch_notes.md (top two entries), HANDOFF.md (build registry),
docs/GOTCHAS.md (new masquerade entry).
