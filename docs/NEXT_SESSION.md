# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 7. **M2a stage-4 bring-up is DONE: the
full Donovan moveset replay (9320 frames) runs END-clean under the crash
guard. Stage-4 acceptance is blocked on ONE maintainer decision.**

**What closed the session-6 frontier:** the "anim state-index delta" was
never a state-space delta — the extractor's bare-long heuristic had fused
instruction operand pairs into fake pointers (47 of them across the two
source-only zones) and one rewrite destroyed the `moveq #0,d0` anim-state
reset. Fixed with a sibling-veto (vhunt2 context match) + immediate-load
labels in scan_code_refs. New instruments that did the work:
`GUARD_PROBE`/`GUARD_PROBE_COND` (conditional logging breakpoint) and
`MASK_RANGES` on replay.lua. Full story: docs/GOTCHAS.md (2 new entries),
docs/tables/reconciliation.md "Session 7".

**THE PENDING DECISION (STATE.md "Decisions pending", first item):**
engine hooks cost cycles → interrupt-timing skew → two divergence windows
in otherwise-vanilla content: dead-stack bytes $FF7F00-$FF7FFF and the
QSound handshake latch $FF043C (one-frame phase). Measured: with exactly
those masked, 02 is bit-identical to vanilla FULL LENGTH and attract
diverges at exactly 4278 (Jedah demo). Zero-cycle hooks are impossible
(GOTCHAS). The maintainer must pick the legacy-gate comparison basis for
hooked builds (recommendation: live-RAM with the two named windows masked
+ confinement lock). Until then stage 4 is unaccepted but fully working.

**Gate:** `tests/test_m2a_stage4_code.sh` — build + veto fact-lock +
guarded moveset clean + masked legacy (02 identical, attract 4278) + pick
diverge 1080. Run it first if anything seems off.

**Small open item:** the companion tail's alternate anim table
(`movea.l #$36784A,A0`, taken when spawn-record sub byte ≠ 0 — Donovan's
hook always writes sub=0; branch never taken in the moveset replay).
Unrelocated on purpose; plant a tripwire or port it at stage-5 close-out
(reconciliation.md Session 7, "Open").

**After the decision:** remaining stage-4 behavior gates (vsav2-as-oracle
field compare at anchors — native Donovan pick on vsav2 = cursor R×2;
dual-emulator agreement on 16_xemu_2p-pattern replay), then stage 5
(select plumbing aux pokes), soak, freeze.

**Build/debug one-liners:** unchanged — HANDOFF.md M2a section.

**Read:** STATE.md (session 7 highlights + the pending decision),
docs/GOTCHAS.md (7 entries; the last two are this session's),
docs/tables/reconciliation.md ("Session 7"), docs/patch_notes.md (top).
