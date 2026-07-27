# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-27, end of session 11. **STAGE 5 IS BUILT AND FULLY GREEN.
M2a is functionally complete — the freeze is the maintainer's call.**

**Stage-5 build:** fingerprint `4b65bc63…` via
`GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 5
build/donovan5`. New in stage 5: the **Start-hold flavor selector**
(init shim reads the per-player Start bitmask `$FF8060` — bit 0/1 =
P1/P2, live through char-init; hold YOUR Start through match load →
VH2 flavor; default VS2) and the **imm_poison** mechanism (the
unreachable Anita alternate-anim-table operand now faults loudly at a
named block if ever armed). aux_poke survey: none needed for the M2a
bar (portrait/name = M2b GFX).

**Everything green on 4b65bc63:** guarded moveset (END 9320), masked
legacy gate (flicker inventory unchanged), oracle gate, dual-emulator
gate, and the new `tests/test_m2a_flavor_selector.sh` (plain 01 /
P1-held 00 / P2-held 01).

**THE BALL IS IN THE MAINTAINER'S COURT (STATE.md Decisions pending):
the M2a freeze.** Recommended flow: playtest the build (pick slot 0x0F;
try both flavors via Start-hold; expect garbled slot-0x0F GFX = M2b
scope and silent Donovan sfx = M5 scope), then say "freeze": the
mechanics are ~an hour — registry row for 4b65bc63, frozen pick/attract
diverge expectations for this fingerprint, suite masked-expectation-kind
support in run_suite.sh (+ dispatch ground-truth extension). Feel-wrong
findings should become replays.

**After the freeze:** M2b (Donovan graphics — the R2 tile wall; may
pull M3 forward) per docs/M2_feasibility.md. Parked lists: M5 sound
restoration (8 stubbed_sound rows), Huitzil/Pyron handler tripwires
(M3), 0x2c31xx data opens (likely Anita DF-only — revisit with a DF
replay during M2b/M3 soak).

**Read:** STATE.md (sessions 8-11 highlights + the freeze decision),
docs/patch_notes.md (top), docs/tables/reconciliation.md (Sessions
8-10), HANDOFF.md (build registry + gate list), docs/GOTCHAS.md.
