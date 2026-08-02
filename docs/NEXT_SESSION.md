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

0. ~~Half-circle fix round~~ CONFIRMED (round 59): all moves
   register and execute properly, graphics good. Remaining queue:
   (a) SELECT-SCREEN PORTRAIT MEDALLION still Jedah's (re-listed —
   the M2b select-portrait remainder; 14z-45 method); (b) in-fight
   HUD mugshot + NAME = JEDAH'S (round-60 captures: wrong ART and
   name text, not palette — same family as (a), do together; note
   the VS screen already shows correct Donovan art/name, so
   per-venue sources differ); (c) maintainer's
   full-cast ES-finish pass (their side); (d) M5 sounds. The
   command/motion subsystem is now documented in engine_internals
   (14z-48 section).

1. ~~Maintainer round on `314568f5`~~ DONE (round 54): ES hit
   counts ✓, visuals ✓, finishes provisionally ✓ (full-cast pass
   pending on the maintainer's side — if any victim shows the
   neutral pose, suspect the six 0x51-positional records'
   property-0x19 path first). Round-34 speed-mode item closed
   NO-BUG (reproduces on native vsavj).
2. **ES/meter follow-ups (small):** consider a mash A/B for the ES
   version (52/53-style pair with the stock poke); the DP-spam
   soak's lost ES coverage can now be restored cheaply (stock poke
   before its first pair — add an ES-chain assertion per the
   GOTCHAS lesson).
3. ~~Donovan WIN screen~~ FIXED 14z-45 (build 4f69589d, gate-locked):
   per-winner-char tables — position entries 0x0F/0x1F patched to
   vs2's (0xF0,0x98), Jedah's 8 win-palette color slices replaced
   in place with vs2's Donovan sets. Round 56: maintainer CONFIRMED
   fixed; lose/continue = no issue (lose = opponent's win screen +
   shared continue screen). ARC CLOSED. NOTE: hole B nearly full
   (0x1F0 free).
4. ~~Swordless-deity palette~~ FIXED 14z-46 (build c45bdc45,
   gate-locked): the state_hook seq-id synthesis was wrong for 8 of
   12 stubs (full census in STATE 14z-46; GOTCHAS entry). Fixed the
   deity (state 0xBE) + two other LIVE latent states (0xB8, 0xC6);
   dead states = safe no-op stubs with the upgrade spec documented.
5. ~~Select-screen post-confirm blink~~ FIXED 14z-47 (build
   b43c7352, gate-locked): accent thunks gained the owner-link
   (+0x30) venue fallback computing the block exactly like
   match-init. Rows 0x0A-0x0D native-exact + steady post-confirm.
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
