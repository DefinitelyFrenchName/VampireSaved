# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 7 (extended). **M2a stage-4 bring-up is
DONE. The maintainer approved the live-RAM masked basis (CLAUDE.md §4
amended, v1). Widening the gate to all 9 legacy replays then measured two
more hook-artifact classes, so a v2 refinement (flicker tolerance for
03/10/16 + a test-mode diverge constant for 06) is implemented
provisionally and AWAITS MAINTAINER SIGN-OFF — STATE.md "Decisions
pending", first item. The full stage-4 gate is green under v2.**

**What happened this session:** (1) the session-6 "anim state-index delta"
was extraction corruption — the bare-long heuristic fused instruction
operand pairs into fake pointers; fixed with a vhunt2 sibling-veto +
immediate-load labels; the full 9320-frame moveset replay runs END-clean.
(2) Stage-4 legacy gates measured honestly: engine hooks cost cycles →
interrupt-skew ghosts (dead stack $FF7F00-$FF7FFF) + QSound latch $FF043C
phase — live state proven bit-identical with exactly those masked.
(3) Maintainer approved the live-RAM basis; §4 amended (v1); windows
documented in docs/atlas/ram.md; masked vanilla logs FROZEN under
`tests/expected/vsavj/masked/` (determinism re-verified at freeze); gate
helper `m2a_legacy_gate_masked` (v2 classes: exact 02/05/07;
flicker-tolerated 03/10/16 via ground-truthed `tools/compare_flicker.py`;
06 diverge@700 = TS press, latch-phase propagation — hook-caused, proven
by hook-free stage-3 builds running 06 bit-identical);
`tests/test_m2a_stage4_code.sh` runs the whole stage-4 gate.

**2026-07-27 update: v2 SIGNED OFF (CLAUDE.md §4 now carries v2 + a
standing watch on flicker growth). Start-hold flavor RESOLVED and
mechanism-pinned (Donovan+Huitzil only; latch $FF87C2; consumers = QCB+K
handler + its projectile, both in ported regions) — see
docs/atlas/character_tables.md and tests/experiments/start_hold_flavor/.**

**Default flavor DECIDED (VS2) and implemented: the init shim seeds the
latch (donovan.toml `[init_shim] flavor_disp/flavor_default`); verified
live (P1 $FF87C2=01); the moveset replay now exercises the VS2 branch of
QCB+K. The vsav2-as-oracle behavior gate is UNGATED — it's the next
work, followed by the dual-emulator gate, then stage 5.**

**NEXT WORK (stage-4 close, then stage 5):**
1. **vsav2-as-oracle behavior gate:** field-level compare at sync anchors
   (docs/atlas/ram.md fields, `tools/compare_fields.py`) between ported
   Donovan on vsavj and native Donovan on vsav2 (pick = cursor **R×2**
   from default). HP-decrease sanity in a real exchange.
2. **Dual-emulator gate:** a Donovan replay in the 16_xemu_2p authoring
   pattern (both picks scripted, GOTCHAS rules) on MAME + FBNeo.
3. Then stage 5: select-screen plumbing (aux pokes), soak, freeze
   (registry row + suite masked-expectation kind land at the freeze).
4. Stage-5 close-out items parked: 0x36784A alternate anim table
   (tripwire or port; branch currently unreachable — spawn sub byte
   always 0), Huitzil/Pyron extra handler types stay tripwired.

**Watch for:** the community answer on the SPEC §2 Start-hold question
(maintainer says imminent) — fold into the variant-policy pending items
(STATE.md) when it lands.

**Build/debug one-liners:** HANDOFF.md M2a section (probe: GUARD_PROBE /
GUARD_PROBE_COND; masks: MASK_RANGES — unset = canonical).

**Read:** STATE.md (session-7 highlights; Decisions made — the new
amendment entry), docs/GOTCHAS.md (7 entries), docs/tables/
reconciliation.md "Session 7", docs/patch_notes.md (top).
