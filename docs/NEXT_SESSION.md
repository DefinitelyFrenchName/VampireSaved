# NEXT SESSION — orientation (session 14z-43b, 2026-08-02)

Read STATE.md sessions 14z-42..43b (the Lightning Sword + ES arc)
after this.
The maintainer tests frequently and reports precisely — their reports
are the project's best instrument; reference data they provide goes
straight into gates.

## Ship state — LS fixed + ES class-0x51 port shipped, battery GREEN

Build fingerprint `22ada38e` (dev head; register at freeze time).
Maintainer-confirmed on it (round 52): LS native-class; ES still 8
hits vs Morrigan (range A/B pending); ES finish = the neutral-pose
KO trigger (queue item 1).
Battery: `ROMDIR="/Users/koneko/Developer/Vampire Saved/ROMS" tests/run_battery_m2.sh`
(57 checks; ~35 min; ROM audit first per CLAUDE.md §3).
Dev builds: `GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 6 build/donovan6`
(a bare build FAILS on 58 open reconciliation refs — expected).

## What 14z-42 closed (the active task from 14z-37..41)

**Lightning Sword hit count + animation speed: ONE bug, fixed and
gated.** The 14z-41 "lost spawner" theory was overturned by
measurement (vs2 never calls 0x82AE2 during the move; the
reconciliation row was already correct — 14z-41 misread 0x77376 as
0x73376, GOTCHAS entry added). Real cause: vsavj's electric-shake
reaction handler (0x23AC8, twin of vs2 0x226E0) carries older-engine
freeze tuning (attacker +0x5C = 0x0B vs vs2 0x04; victim 0x18 vs
0x0C) and lacks vs2's victim +0x147 = 0x0C re-hit gate. Fix =
ls_freeze_vs2_{victim,attacker} site_thunks (donovan.toml, 14z-42
block): player-block + char-0x0F guarded, vs2 constants + $147 in
the Donovan branch, byte-identical vanilla else.

Measured on 4f8220fc: 6 damage events / 10 total damage == native
exactly; 3 loop iterations; cadence 1-5f; mash extends 3 -> 4
iterations on BOTH games (mash was never broken — 14z-38 theory
retired). Gate: test_don_reactions.sh extended (total <= 10,
last-hit <= f2700) — PASS. Replays 51/52/53 promoted with native
datums in headers. Engine internals: walker node format + freeze
subsystem documented (docs/engine_internals.md); RAM atlas +0x5C /
+0x147 / +0x20 / +0x32 rows added.

## IMMEDIATE: if the battery was not green at session end

Check the tail of the battery log first. Watch items: the freeze
thunks hook LEGACY code (0x23AD8/0x23ADE) — hook cycle skew may
shift the frozen flicker inventory (standing watch: mechanism-
attribute any drift, maintainer sign-off, never silently refreeze).

## Queued next (in order)

1. **ES scripted-accept root cause (BLOCKS everything ES).** Session
   14z-43b hard fact: every scripted button-pair falls back to the
   LP version on current builds (both DP and LS; stock present;
   same-frame AND offset pairs; chain-start nodes prove it: DP LP
   0xD6EE8/MP 0xD7050/HP 0xD71B8) while MANUAL ES works (rounds
   51-52). Replay 19's ES DPs worked when written (session 11) —
   silent coverage loss (GOTCHAS). Static-first plan: disassemble
   the ported handler's ES-vs-normal branch in the vs2 source
   region, find what it reads (input pair mask? meter threshold?
   which offset), A/B that field scripted-vs-manual-shaped inputs.
   Stock byte = ff8505 (decays during idle!), gauge = ff850B.
   Maintainer question queued: their meter state at a successful
   manual ES. Unlocks: ES gate + 9-hit A/B + mash-to-11 + the
   ES-KILL NEUTRAL-POSE repro (round 52: ES finish at final KO =
   THE trigger; death path likely can't chain class 0x51 — the
   14z-28 finding; class-poke repro inconclusive, needs a real ES
   kill).
2. **ES gate: finish the measurement the 14z-43 port needs.** The
   class-0x51 port is BUILT and crash-gated (build 22ada38e; STATE
   14z-43 — including the pc-relative/data-space GOTCHA that cost a
   vec3). Remaining: (a) decode the meter STOCK byte (ff8505/06/07;
   gauge = ff850B — tap writes across a manual-ES flow); (b) ES
   replay: replay-19 prologue + 421+pair, pair 1f apart (the
   accept-shape that works no-debug); assert the ES CHAIN (family
   0x284A64/ported 0xD81xx+0x244*3 — the block after HP's chain,
   previously mislabeled "mash extension") + 9 base hits + mash to
   ~11 + ES KO clean; (c) A/B the property-0x19 reaction handler
   pair for freeze-constant drift (the 14z-42 lesson) once hits
   land. Chain map + fallback rule (pair -> lowest button) in
   STATE 14z-43.
3. Donovan lose/continue screen (round-51 captures): wrong palette
   on the figure, garbled Anita-portrait blocks, wrong background.
   Loser-portrait family — group with the M2b select-portrait
   remainder (docs/engine_internals select-screen section).
4. Swordless-deity palette (yellow vs vs2 blue figure/lightning —
   maintainer captures round 41). Same family as the deity's obj
   palette rows; untouched so far.
5. Select-screen post-confirm blink (tracked minor): select-venue
   objs lack +0x3A4 (cached block ptr) -> the color-aware accent
   thunks fall back to punch-color slots on that screen only. Fix
   shape: select-venue init of +0x3A4 or owner-link fallback.
6. Match-end neutral-pose KO: UNPARKED — folded into item 1 (the trigger is the ES finish) (round 51, maintainer's call —
   flaky, once vs Morrigan, 4 scripted variants clean; gate section
   3 is the tripwire). Wanted datums if it recurs: victim char +
   victim's state at the kill.
7. Sounds: Donovan sfx silent by design (stubbed_sound rows; M5 task
   = dispatcher id-table translation, NOT unstubbing the helper —
   see reconciliation row note at vsav2=0x005122). NOTE from 14z-42:
   the walker's per-node sfx call site and its param tables are now
   mapped (engine_internals walker section) — useful for M5.

## Measurement kit (14z-42-proven)

- Replays: 48 = deity KO (HP poke 2600:ff8850:00010001 via POKES
  env); 51 = NATIVE vs2 no-mash ground truth; 52/53 = mash pair
  (native/ours); 50 = column crash (guarded).
- P2 HP = ff8850.w; P1 obj ff8400 (+0x1C anim node, +0x20 node
  timer, +0x5C freeze, +0x147 re-hit gate, +0x382 char id).
- tap_writes.lua (no debugger, replay-exact frames): TAP=addr,len
  WINDOW=a,b REPLAY=... TRACE_OUT=...; GUARD_PROBE=hexaddr on
  run_replay_guarded.sh for "does PC X execute" (D0/D1/A0/A6/RET
  logged; -debug mode: moves still come out, verified 14z-42).
- Node-sequence/cadence/hit-period analysis one-liners: session
  14z-42 transcript scripts (parse tap logs, pair ff841c/ff841e
  writes, dedup consecutive, Counter loop visits).

## Gotchas most likely to bite next session

- A cited address in a session log is a CLAIM — grep the manifest
  and xxd the built image before building a theory on it (the
  14z-41 one-digit misread; GOTCHAS).
- Engine-side tuning constants (freeze/shake/gravity) can drift
  between engine generations with zero ported-byte differences —
  A/B-tap the obj fields at event frames, don't audit bytes only.
- Read embedded/code tables from the right image: opcodes.bin for
  CODE, data.bin for embedded DATA. zsh eats `===` in echo args.
- POKE VALUES feed the CPU AI — any poke change reshuffles
  downstream choreography in multi-round scripted replays.
- The battery script builds donovan6 itself — never rebuild while
  it runs. Background any run >10 min.
- ROMDIR must pass tools/audit_roms.py first; keep it play-free.
