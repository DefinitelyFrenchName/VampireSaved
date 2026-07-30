# STATE — living progress log

Updated: 2026-07-29 (session 14r — COMPANION OVERLAY SHIPPED at
cf2109d8 pending gates+playtest: Anita/sword/statue render in-match
and on the win screen; 3 residual sites excluded; session 14q parked
state superseded)

## Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)

Fix shipped for the round-27 shock garble (build 1507c286-family, final
fingerprint in the registry/commit). Mechanism recap: the shock curtain
re-displays OBJ-list tail buckets holding VS-screen leftovers; with
Donovan those leftovers are his portrait pieces (band tiles) = garble.
Fix (two GEN pieces, both Donovan-gated, zero legacy execution):
- init_shim (objram_clear flag) now ARMS a countdown marker 0x50 at
  $FF7F00 (dead-stack scratch, legacy-masked; clobber failure modes
  benign in both directions).
- A new blob detours the ported sword routine's per-frame exit
  (vs2 0x65F00 jmp, placed site 0xCC110): while match-active
  ($FF8004==0x40000) it decrements the marker; at zero it clears the
  full 8KB OBJ list ONCE, in the object-update phase (same-frame
  rebuild repaints all active entries — no visible blank; stale tails
  stay zero).
Journey (measured, in GOTCHAS-worthy detail): single-shot clears at
char-init and at first-sword-exit both LOST to pre-match drawers (VS
screen redraws through ~f2470; char-init runs DURING the VS screen;
the match-active flag is set during the VS screen too). The countdown
makes the timing replay-independent (~80 frames into the round).
Verified: tail buckets all-zero at the shock zap; zap pixels coherent
(no patchwork); pixel probes 17@3479 (spark+Anita) and 31@2618 (sword
arc) IDENTICAL to goldens. New permanent gate tests/test_don_shock.sh.
Note vs native: where vs2 shows benign dark leftovers in the curtain,
we show transparent — an accepted M2a-class approximation (recorded).

## Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)

- Round-27 playtest: SWORD VISIBLE ON EVERY MOVE TRIED — the 14z-5 fix
  is confirmed in play. The blocker is CLOSED (cosmetics remain: blade
  palette family, non-blocker).
- New report: Victor's electricity (236HP) garbles tiles ON Donovan
  (clean on Lilith). Scoped this session (replay pair 32_victor_shock,
  OBJ-RAM dumps + write taps, snapshots):
  * Reproduced deterministically; multi-hit shock connects on both
    games; Donovan's shock POSE anim resolves the correct ported family
    (0xDAF58 ~ vs2 0x287418+skew) and his shock record head
    (fmt2/budget 0x23/count 0x0D) is byte-identical to vs2's.
  * The garbled art = the shock's darkening/cage GRID: native draws a
    uniform repeated-tile grid; ported draws a MIX of correct columns
    (Victor's vsavj codes f76d/fbc9) and STALE OBJ-list entries never
    rewritten since the match-intro (frame ~2313, e.g. code c625 = a
    Donovan band tile from his intro pieces; written by engine drawer
    PC 0x1B8BE, exposed at shock time with zero writes in between —
    proven by whole-run offset taps).
  * => mechanism = Donovan-specific OBJ-list length/terminator
    divergence during the shock composition exposes stale list tail;
    the divergence source (piece counts / budgets of other records in
    the composition, or the curtain drawer's slot arithmetic) is NOT
    yet pinned. Shock ENTRY-node number lookup needs a T-walk (0xDAF58
    is an interior node — direct T_d[2n] search fails).
  * Class: non-blocker (maintainer hierarchy); almost certainly NOT a
    regression — present since the record/tile port (user had not
    fought Victor before).
- Instrumentation ready for the fix session: replays 32_victor_shock_
  {vsavj,vsav2}, OBJ-RAM dump/pairing scripts (transcript), tap_writes
  with 32-bit data logging (this session's fix).

## Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)

The armed-normal sword swing is FIXED at root. Full chain (each link
measured): Donovan's anim nodes carry a sword-pose word at node+0xE;
his ported sword-command routine (vs2 0x65EBA family, placed 0xCC0CA)
adds 0x23 and calls set-anim-by-number on the sword object; numbers are
0x124-0x201. vs2 calls the UNMASKED resolver entry (0x5C77E — vs2
hoisted `andi.w #$ff` to a skippable pre-entry at 0x5C77A); vsavj's
twin embeds the mask, and the auto-matched reconciliation row sent
ported calls into it -> numbers truncated -> wrong-but-valid nodes in
Donovan's own (correctly repointed) number table at 0xBD07A[0x0F] ->
sword idled through every attack. Everything else (pose data, table
repoint, tiles, +0x9C char id) was verified correct along the way.
- Fix: new reconciliation kind `patched_clone` (gen) — vanilla resolver
  bytes minus the andi, placed in hole a, ported refs only; vanilla
  callers untouched (36 vanilla call sites keep the masked original).
- Verified: sword walks 0xE19D8-0xE1AB0 (= vs2 0x28DE98-0x28DF28 swing
  family), idx-0 command lands, SNAP pixel shows the blade arc, Anita
  present, spark clean. New permanent gate tests/test_don_sword.sh
  (replay 31_don_6hp probe, node 0xE1A20 assertion).
- Red-herring bookkeeping (measured, valuable): the type-3 "spark" is
  the GENERIC hit starburst (vs2's global effect table T=0x2B7EF4 = the
  head of ported region x2b7ef4) and renders CORRECTLY on our build;
  the 14z-3 "sword-arc effect object" interpretation was wrong. Effect
  strip tables: vsavj T=0x283690 (12 abs code refs), per-char anim
  number tables: vsavj 0xBD07A / vs2 0xD7218 (row 0x0F repointed to
  0xDDA1E by the bank port — verified correct).

## Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean

On-hit effects verified clean in play; no regression observed. State
clean for further work. Current work: the sword-swing display-side
redirect (the one remaining blocker step; see 14z-3/14z-4 and
NEXT_SESSION for the full map and the atomic-change design rules).

## Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)

- Round-25 report (maintainer): garbled effect sprites on hit. Pixel
  A/B (new probe: SNAP_FRAMES on replay 17, frames 3477-3481) convicts
  BOTH 14z-3 thunks: bank_swap garbles the spark (Donovan tile bank
  under vanilla strips), and spawn_mark makes ANITA vanish while a
  marked spark is live (+0x9A = owner-char-id with display semantics;
  "spare field" assumption WRONG). Both rows staged to 99; per-row
  stage filters added to site_thunk/data_port loops (they were being
  applied unconditionally at stage >= 6). Build restored byte-exact to
  597ae55b (round-24 throw-confirmed); battery green.
- The sword-swing fix design is updated: tile bank + strip redirect +
  a PROVEN-dead discriminator must land as ONE change, accepted only
  with the pixel probe alongside the battery (new GOTCHAS entry).
- 597ae55b hit sparks verified CLEAN pixel-wise (the user's "maybe the
  previous build too" is answered: no — the garble was 14z-3-only).

## Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)

Round-24 continuation. The missing "circular sword attack" on armed
normals is DECODED end-to-end (replay 17, native-vs-ported A/B):

- vs2 draws armed-normal sword swings as TYPE-3 EFFECT objects
  (hit-located, ~10-frame strips). Spawn chain: shared engine spark
  spawner (vsavj 0x18EFC / vs2 0x178C2; a3=attack record, +0x12 spark
  id & 0x7F, remap tables byte-IDENTICAL between the games, allocator
  vsavj 0x16FBA / vs2 0x15702) -> type-3 first-tick case (vsavj 0x5E7B2
  / vs2 0x6A7A6, dispatched through the obj_hook-extended table
  0x5E556) -> variant (+0x59) -> param record (anim number 0x102) ->
  set-anim (0x4CE2: facing adds 0x300) -> COMMAND QUEUE (0x31DA) ->
  display processor resolves number->record via PER-CHAR strip tables.
- On the ported build everything matches native (type 3, variant 3,
  position, timing, 10-frame life) EXCEPT the resolved strip: native
  walks vs2 0x2B8190+ (Donovan sword-arc records, ALREADY PORTED at
  0xF420C+ in region x2b7ef4); ported walks vanilla 0x28391C+ (slot-0F
  = Jedah-family effect art) — because the display-side strip-table
  selection still serves slot-0F vanilla tables. Self-relative 16-bit
  offsets make in-place table repointing impossible (ported records are
  1.6MB away; the effect-table zone is overlap-packed shared pool).
- STAGED (build cfe757a1, gated slot-0F-attacker-only, legacy-inert by
  construction): [[site_thunk]] generic construct (gen) + two thunks:
  spark_spawn_mark (allocator wrapper: marks spark +0x9A=0x0F when the
  ATTACKER (a6!) is char 0x0F) and spark_bank_swap (first-tick: +0x18
  tile-bank 0x0000 -> 0x4000 for marked sparks — the same vs2-bank-3 ->
  vsav-bank-2 remap as his six port_patch bank setters). Verified live:
  mark + bank land; anim unchanged as expected (tile bank != anim
  table).
- REMAINING STEP (next session): redirect the DISPLAY-side strip-table
  selection for slot-0F effect objects to a rebuilt Donovan effect
  table (vs2 T at 0x2B0786 family) — the same per-char display-site
  thunk pattern proven in 14q, and the same site family already
  catalogued by tools/overlay_port.py (VERIFIED_SITES). The +0x9A mark
  gives the consumer a per-object Donovan discriminator if needed.
  Sword-arc RECORDS and TILES are already in the build; only the table
  selection is missing.

## Maintainer priority statement (round 24, 2026-07-30)

Round-24 playtest CONFIRMS the throw fix (597ae55b). Standing compromise
hierarchy from the maintainer, recorded verbatim in intent: the MISSING
SWORD SPRITE on armed normals (e.g. 6HP: circular swing not rendered,
hitbox possibly the unarmed variant) is a TRUE BLOCKER for the port.
Palette issues (win-quote, HUD mini-portrait) and the red/purple
sword/statue blinking are NOT blockers — ship-compromisable if it comes
to it. This is a compromise hierarchy, not an ordering command for the
work queue.

## Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)

- Round 23: throw still broken on byte-exact ad372a6b -> round-21
  confirmation was a sampling miss; winpal conviction was WRONG (as was
  the grab-row one). Mechanism trace (new tools/lua: tap_writes.lua):
  victim X/Y written by ported positioner (PC 0xCE51C, region x026142,
  vs2 0x0272CE) walking the pointer-of-tables 0xBE27A[thrower id] —
  slot 0x0F still pointed at JEDAH's keyframe table (0x0B19F8, stride
  0x198/victim) while Donovan's anim indices assume vs2's 0xC8-stride
  layout. Pre-14w the gap auto-table class covered this table; the 14w
  wholesale disable reverted it (Felicia-fix collateral).
- Fix: new [[data_port]] manifest construct (gen_donovan_patch.py) —
  vs2 Donovan's victim-keyframe table (0x0CA1CA, 0xE50, vhunt2 twin
  0x0C9A5C byte-identical, both asserted at build time) placed in-place
  over Jedah's slot-0F zone (fits in 0x1828), mirror-victim offset word
  fixed [0x0F]: 0x0B30->0x0D88. Replay 27 trace: 21 teleport-scale
  jumps -> 4 structured slam keyframes (authentic cinematic motion).
  Build 597ae55b. Legacy surface: slot-0F throwers only; attract@4278
  unchanged (diverges before any throw).
- 27_don_quotewin/27 drift note: the throw connects at 3050/3650 on
  current builds; re-freeze of the 27 oracle still queued.

## Session 14z (round 22: winpal copies convicted and fully reverted)

- The throw victim-teleport reappeared on e7682289 and the timeline
  convicts the WINPAL COPIES (0x248D80), not the 14v grab rows: the
  zone holds throw-cinematic data; no legacy replay threw (coverage
  blindness). Full revert to byte-exact ad372a6b; 14y doctrine
  amendment VOID (02/05/07 exact restored, pick 1080); new permanent
  masked-EXACT gate 30_demitri_throw. Palettes were NOT visibly
  improved by the copies anyway — the quote/HUD row consumer remains
  UNDECODED (none of 0x1BF56/0x1C1FA/0x1C426/0x7D4FC/0x1C5CE feeds
  the visibly-wrong rows). Next palette attempt starts from a runtime
  trace of the ACTUAL row writes on the quote screen/HUD, with the
  throw + pixel gates watching.

## Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)

- Round 20: triangle jump CONFIRMED FIXED. But the 14v grab-pointer
  reconciliation BROKE Donovan's throw in play — maintainer decision:
  roll it back, keep only the Felicia fixes. Done (the 8 rows gated
  to stage 99 with a full post-mortem note in donovan.toml): the
  vsavj engine consumes its grab-pointer vars with native-throw
  semantics that conflict with the ported throw's flow; the original
  stray writes are silent and the throw worked for 19 rounds with
  them. Re-attempt requires decoding the engine-side consumer first.
- NEW MECHANICS/RENDERING ITEM (round 20): on some normals the SWORD
  ATTACK doesn't render even when equipped — e.g. round-start 6HP:
  Donovan's sprite and damage look right, but the sword's circular
  swing isn't drawn and the hitbox may be the unarmed one. Ties into
  the sword/overlay rendering work (the parked overlay + the sword
  records) — keep in scope for the sword-rendering search: the
  armed/unarmed variant selection may involve the same per-state
  record webs.
- Fingerprint ad372a6b; battery at session end.

## Session 14w-c resolution (ALL GREEN at d6a751cb)

- The halt lifted: the type-63 handler's crash was its hit-reaction
  id 0x50 — past vsavj's vanilla table, below the hook's old ext
  range. One-slot reaction_hook extension (case verified verbatim
  against vs2) closed it. Full battery green including both new
  gates (29_felicia_walljump, pixel menus). SHIPPING d6a751cb.
- PLAYTEST (round 20): (a) Felicia's triangle jump — wall latch back,
  and her walk now byte-exact vanilla; (b) throw anyone repeatedly
  (the grab-pointer fix from 14v rides along); (c) deep arcade runs
  with Donovan — the type-63 moment (~his 2nd match win region)
  should now just work; report anything odd there; (d) win-quote
  palette is STILL Jedah's (known: preload-staging consumer decode
  queued); sword blink unchanged (overlay parked).

## Session 14w-c original halt record (kept for the mechanism)
## Session 14w-c (type-63 chain: RULE-6 HALT — the only open task)

- The pair-table fix changed CPU-Felicia's fight flow in 21_don_mash,
  and at frame ~10050 Donovan's own deep-arcade path SPAWNED
  SECONDARY-OBJECT TYPE 63 for the first time ever — hitting its M2a
  tripwire (0xCB880). The "types 59-62 only" assumption is
  measured-wrong. Handler ported (extra root 0x6717c:0x154:t0x671b0,
  clean extraction: 13 refs, all engine rows verified) — the tripwire
  no longer fires, but 13 frames later the REACTION DISPATCH
  (engine 0x18460) crashes: vec3 at PC 0x18466, ADDR 0x1B6A3.
- Crash math (exact): jump-table fetch with d0 = -8 -> d1 = the
  dispatch's own first opcode word (0x323B) -> odd target 0x1B6A3.
  d0 = -8 means a GARBAGE/UNINITIALIZED reaction id, not an OOB
  vs2 id. Leading hypothesis: OBJECT FIELD LAYOUT divergence
  (same-value class #5 candidate) — the ported handler writes vs2
  object offsets (+0x9E/9F/A2/B0/B3/B4 observed) while vsavj's
  reaction system reads its id from a different offset; the handler
  disassembly (STATE-annotated above) never writes vsavj's +0x38.
  NEXT: diff the two engines' reaction-id field offsets (find vs2's
  site_prefix analog of `tst.b 0x38(a1)` and its dispatch d0 load),
  then add a field-offset port_patch to the handler.
- RULE 6: the battery is RED on 21_don_mash until this lands; no build
  ships. Felicia's legacy fixes are verified and committed (29 gate
  green throughout); the last all-green build (dc6b2d36) is NOT
  shippable knowingly (it carries the Felicia legacy violations).

## Session 14w-b (second Felicia defect: the pair-table stride bug)

- vsav.zip restored; rebuild 53ec9c51 fixed the WALL LATCH (verified
  byte-identical trajectory) — but the freshly frozen 29 gate caught a
  SECOND defect: her walk-back speed off by a subpixel fraction
  (whole-pixel motion vs vanilla's accumulating fractions). Root
  cause: param32_a/b are 8-byte PAIR tables (fwd/back velocities)
  registered at 4-byte stride — "slot 0x0F" hit Felicia's walk-back
  half; the extractor read the equally wrong vs2 half. bank_map fix:
  rec8/stride-0x100; Donovan now ports his true velocity pair onto
  Jedah's true pair. Felicia byte-matches vanilla except one
  spawn-boundary flicker frame (29@2435) — 29 reclassified to the
  approved FLICKER class. Fingerprint 340673da.
- LESSON (GOTCHAS updated): the new-replay-then-freeze loop caught in
  ONE day what 19 playtest rounds missed twice — every mechanics bug
  fix must ship with its oracle replay, and per-char tables' ENTRY
  layout must be verified against vanilla content (pair-sign
  signatures), never assumed from spacing.

## Session 14w (FELICIA'S TRIANGLE JUMP: root-caused to the gap-write
class; gen fixed; REBUILD PENDING vsav.zip restoration)

- Round 19 clarified the float = Felicia's WALL JUMP broken (no wall
  latch; rises off-screen, wraps twice). New replay 29_felicia_walljump
  reproduces it deterministically — in a PURE LEGACY match (Felicia vs
  Bulleta): a superset violation that every RAM gate missed because no
  replay ever played Felicia and per-char physics only surface in use.
- Root cause via restore-bisection (31 candidate groups eliminated:
  winpal, all four engine hooks, the select/pool writes, all data
  members, per-char table rows): the generator's speculative GAP
  writes. gap_bdc7a[0x1F] (vanilla 0xFFFF4800, the wall-jump-back
  velocity) was overwritten with Donovan-derived 0xFFFFEC00. 42 gap
  writes existed, 31 changing vanilla engine bytes — ALL disabled in
  the gen (session-14w comment in gen_donovan_patch.py). With every
  gap restored: Felicia latches at the exact vanilla Y and Donovan
  soaks clean — the writes were pure harm.
- ALSO exonerated this session: the 22 overlay thunk sites (CCR
  audit), the sound-farm stubs (ported-call-only by design).
- **BLOCKED: vsav.zip is missing from ROMDIR** (folder shows recent
  Finder activity — likely the maintainer's reorganization; cfg/nvram
  dirs from some unsandboxed MAME run also present). The audit gate
  correctly halts all builds. Once restored: rebuild, full battery,
  freeze 29_felicia_walljump's expectation (vanilla-exact class — it
  is a LEGACY replay), and re-run the throw-oracle refreeze.

## Session 14v (grab-pointer work vars fixed — the Felicia float)

- Round 18: quote palette STILL Jedah's => the quote screen consumes
  the select-time preload staging; decoding the staging CONSUMER is
  now the path (the 14u copy-and-repoint plumbing stays — correct and
  needed either way). And Felicia floated off-screen after a throw:
  root-caused to 8 unreconciled A5 work-var refs in the ported throw
  code (grab POINTER stores + a state clr through vs2's layout —
  garbage into two vsavj engine vars every throw). The A5 audit
  (open since 14o) is now COMPLETE: no other unreconciled refs in
  0xB000-0xBFFF anywhere in ported code. 8 port_patch rows shipped;
  analogs triple-verified in both engines' native throw code.
- 27_don_throw oracle has drifted (pre-throw hits connect on current
  builds) — re-freeze needed; grab rows shown outcome-neutral on it.
- PLAYTEST asks: (a) throw Felicia (or anyone) repeatedly in a
  Donovan match — the float should be gone; (b) throws should feel
  vs2-correct.

## Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)

- Four masked-gate iterations distilled the survivable design (see
  patch_notes 14u): patched block COPIES in dead space + a private
  pointer table + exactly ONE poked reader site (0x1C1FA, the only
  exclusively-quote-time one) + the 0x60-view lea. Three select-time
  bulk preloaders identified by per-site gate bisection (0x1BF56 /
  0x1C5CE 2P / 0x7D4FC challenger-join) stay vanilla.
- All gates green on 1f5fa38e. PLAYTEST QUESTION: does a Donovan match
  win now show his quote palette? If not, the quote screen consumes
  the preloaded staging and the staging consumer is next.

## Session 14t (win-quote palette: decoded, port REVERTED by the gate)

- Round 17: menus clean. The palette chain is fully decoded (see
  patch_notes 14t) but the in-place slice port DIVERGED legacy 2P
  replays (03/16, 3229/2008 frames from select entry): the per-side
  blocks are bulk-staged through work RAM MID-FRAME on legacy paths —
  transient divergence visible only to the checksum's sample point.
  Reverted; shipping stays 37269fff. Next attempt needs the staging
  reader decoded (find the mid-frame copier of 0x39FDC0/0x3A18E0 and
  make its slot-0F slice source conditional), or a maintainer-approved
  masking amendment for the staging buffer.
- Diagnostic GOTCHA earned: per-frame unmasked checksum/dump runs READ
  the QSound latch and perturb both builds identically — legacy
  comparisons must replicate the gate's exact mask set, and mid-frame
  transients require comparing at the checksum's sample point, not
  frame-done dumps.
- NEW REPLAY 28_don_quotewin: wins a match (23 turned out to LOSE on
  current builds), reaches the story card + continue/quote screens.
  New cosmetic: loss-path quote screen shows Jedah's win-quote art.

## Session 14s (playtest round 16: overlay REVERTED; pixel gate born)

- Round 16 (maintainer): Anita/Donovan render correctly BUT (1) the
  red/purple flicker persists over the grey sword/statue (unpoked
  table families still draw Jedah art on top) and (2) MASSIVE menu
  corruption: title, select, speed menus, VS portraits garbled.
- Overlay PARKED again (build/manifest/overlay.wip). Cause of (2):
  the tile pool used OBJ-dead positions whose BYTES back scroll-layer
  menu art — CPS-2 scroll1/2/3 decode the same ROM bytes (GOTCHAS).
  Every RAM gate was green throughout: gfx is invisible to RAM-basis
  comparison. The overlay redesign needs a BYTE-dead pool.
- **NEW GATE**: tests/test_gfx_menus.sh — pixel-exact comparison of
  title/select/speed-menu frames vs frozen vanilla goldens
  (tests/expected/vsavj/menus/), wired into test_m2b_stage6.sh. On its
  first run it caught a LATENT SHIPPED BUG: the speed-menu TURBO/AUTO
  text sat 8px off since the select-screen work — select_port's
  in-place coordinate write hit one byte of the menu record's list
  (head shared inside Jedah's banner list span). First fix attempt
  (relocate all lists + repoint cptrs) FAILED the masked gate —
  cptr values are RAM-visible on select paths (fourth stored-anchor
  class; 02/03/08 diverged at ~820). Final fix: cptrs untouched,
  in-place list writes kept, and SHARED lists (the banner's) simply
  not written — Donovan's banner draws at Jedah's position. Shipping
  fingerprint 37269fff; pixel gate green; full battery at session
  end.
- Overlay next steps (with the WIP): byte-dead tile pool (candidates:
  bytes of Jedah band art already replaced in group B — his band
  minus scroll-shared spans, TBD by a scroll-usage census — plus 0xFF
  padding); the red/purple flicker = the unpoked families
  (0x2675AA/0x26772A/0x26775A + dead-entry tables).

## Session 14r (overlay port COMPLETED to a 22-site shipping config)

- Round 15 (maintainer): no regressions on f29cf24a.
- The stride-8 stream grammar was completed (flags 0x80 = 12-byte
  jump node — the attack-anim loops that caused every attack-input
  crash; 0x40 = terminal; ptr 0 legal), the heap port regenerated
  (segB collapsed 22KB -> 496B once stream extents were真 bounded),
  and every context-verified site probed individually on the Donovan
  path with the watchdog-proof timer-tick detector. 22 sites ALIVE
  through DP-spam and win screens; 3 crashers excluded and documented
  in tools/overlay_port.py (VERIFIED_SITES / KILLER_SITES policy —
  the emit is deterministic; fingerprint cf2109d8 after the fmtA-opaque fix — the guarded soak caught a frame-8424 address error from streams truncated at skipped fmtA records).
- VISIBLE: Anita fully drawn dragging behind Donovan; sword on his
  back; clean win pose. The Jedah-darkness blink is gone. Open
  question for playtest: the hat piece alternates per frame (vs2
  dither vs residue).
- Remaining for a later pass: the 3 excluded sites (indexing-variant
  decode: ±4-anchored table entries / site-biased ids), the four
  100%-dead tables (0x2A0862 family — win/vignette features via
  whdr-strips partially live), fmtA composite records (20 skipped).
- Gates: full battery re-running clean at session end (a first run
  was voided by a build-tree race with foreground rebuilds — gate
  scripts rebuild build/donovan6 themselves; never rebuild while the
  battery runs).

<!-- superseded header: session 14q -->
Updated (superseded): 2026-07-29 (session 14q — overlay port 80% built, PARKED as
build/manifest/overlay.wip; shipping build = f29cf24a (feet fix,
playtest-confirmed round 14); M2a frozen a02aeeff…, M2b-core frozen
71601263…)

## Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)

- **Round 14 (maintainer): Anita's feet fully clean incl. shadow, no
  regressions** — f29cf24a validated.
- Stage-7 build attempt (topology B) reached a proven architecture with
  one remaining blocker. What is PROVEN (each by masked 02 probes,
  full-length identical unless noted):
  1. **Placement**: vs2 overlay slice [0x2A0426,0x2A63F0) split at
     0x2A4A48 (above max self-relative table reach), segA+cptr-tail at
     0x248D80, segB at 0x2557B0 — inside JEDAH'S OWN ANIM AREA, the
     only proven-dead space (slot 0x0F always runs Donovan). Legacy
     CLEAN. (First two placements failed: Jedah's strip-area "gaps"
     interleave the shared MUSIC POOL — see GOTCHAS.)
  2. **Site repoints**: 25 context-verified Jedah T-sites, thunked
     (`movea.l #T,a0` -> `jsr thunk`; ported T iff match-active AND a
     slot-0x0F participant). Legacy CLEAN with all 25 active. Static
     pokes are IMPOSSIBLE (attract cutscene IS Jedah ~888; shared
     display flows hang other-char matches — measured both).
  3. **Tile pipeline**: 3929 bank-1 pairs (874 blocks; fmt4/6/8 draw
     stored+0x3800 — handler decode) placed at dead-Jedah positions +
     padding; build_gfx --overlay-tiles chain verified.
- **BLOCKER**: with data+rewrites active the DONOVAN path watchdog-
  crashes at match start. Cause class: the slice's 293 blind long
  relocations + 2811 tile-word rewrites in 163 scan-validated records
  include false positives that corrupt stream/coordinate data (fmt4
  validation is cptr-less; coordinate words alias pointer prefixes).
  Fix path: STRUCTURAL CLOSURE — decode the stream node language
  (tables -> strips -> tag-streams -> records), restrict relocation
  and rewrites to the closure, leave everything else byte-intact.
  Groundwork in place: fmt handlers decoded (0x1AFC6/0x1B234/0x1B61A/
  0x1B6AA/0x1B73E/0x1B7CC; A0=rec+2), strip = plain long array,
  tag-stream = (FF-tag,ptr) pairs, walker 0x15082 = T + T[2*id]
  self-relative.
- Everything parked in build/manifest/overlay.wip/ (gen ignores it
  until renamed back to overlay/); tools/overlay_port.py +
  gen thunk assembly + build wiring are committed and inert. Shipping
  fingerprint re-verified f29cf24a after parking.
- New GOTCHAS: attract-cutscene-is-Jedah (conditional thunks), music
  pool interleave (watchpoint read maps have a computed-addressing
  blind spot), blind relocation corrupts mixed data blobs.
- **14q continuation (same session): closure v5 built and iterated.**
  Object-granular heap port (closure walk tables->strips/streams->
  records; heap over Jedah's dead anim areas; per-object placement
  map; table entries recomputed only when validated, verbatim
  otherwise). Grammar discoveries, each verified against data:
  (1) stream nodes = (tag.l, ptr.l) stride 8, tag = (duration.b,
  flags.b, param.w), NULL-ptr nodes legal ("no record this phase");
  (2) grammar-4 = word header + bare long array at +2 (the
  0x2A0862-family targets); (3) fmt4 record size is 14B; (4) the
  engine stepper family ALSO walks 0x10/0x18-stride node forms —
  stride is an OBJECT-STEPPER-CLASS property (0x15030-0x15080 lea
  variants), NOT table- or data-derivable (a longest-run stride
  heuristic corrupts real 8-streams — measured, reverted).
  Probe results (detector: round-timer tick + match flag — earlier
  detectors were fooled by watchdog reboots keeping stale RAM):
  data-only ALIVE and legacy-clean; pokes for the 2671C6/267224/
  267284 tables ALIVE through round start but CRASH ON THE FIRST
  623P (attack-id-indexed entries hit still-dead table slots);
  2671E6 (attack-id table, walker 0x15084/inline variants) worst.
  REMAINING DECODE: map each poked table to its stepper class
  (which stride its streams use) — then re-walk dead entries with
  the right stride and the closure should complete. All probe
  tooling: /Users/koneko/.claude/jobs/*/tmp/donprobe.sh pattern
  (rebuild-with-poke-subset + timer-tick verdict), op_v5_all.json
  site list. Shipping build re-parked at f29cf24a.

## Session 14p (feet fixed; blink mechanism = Jedah's overlay records)

- **ANITA'S FEET FIXED** (build f29cf24a): the garble was record
  0x0FCECA (x2b7ef4) whose 54-record strip draws at BANK 2 (#$4000
  sub-objects) but was triaged by the BANK-1 effect-tail maps (+0x47
  reloc → codes 0x0FD2/3 = wrong-page garbage; the earlier "solid
  green" was the same entries pre-reloc). Empirical attribution per
  the f8eda2ca mandate: handler-breakpoint trace over 9 replays
  (tests/lua/obj_record_bank_trace.lua) found the ONE bank-2 record;
  closure came from its sub-object's record stream (54 recs, 37
  blocks, vs2 codes 0x0F8B-0x0FBC). Data-only fix:
  tools/gen_anita_bank2.py → effect_tail.json bank2_recs/bank2_place
  (shelf rows 0xEAC0-0xEAFF); the generator's surviving bank-2 branch
  does the rest. OBJ RAM + screenshot verified; gates re-run.
- **SWORD/STATUE BLINK ROOT-CAUSED** (no fix yet — next surgery): the
  in-match companion overlay sub-objects ($FFB800-$FFBA00, bank
  #$2000) walk per-char record-pointer strips; on our build the char
  slot resolves to JEDAH's strips (0x2674AA-0x268Axx → records
  0x271D70/0x272156/0x272800/0x272A68…, codes 0xAFxx/0xB4xx/0xCDxx =
  Jedah's bank-1 darkness art, tile content verified vanilla≠vs2). The
  "blinking sword/statue" is Jedah's overlay ANIMATING where Donovan's
  sword-drag/statue belong. vs2 ground truth (handler trace on
  vsav2, 27_don_throw_vsav2): ~16 sub-objects draw records
  0x2A1DAE-0x2A3F80 (codes 0xA3E8-0xA499, strips 0x2A0Axx-0x2A1Cxx
  after root 0x2A05E2). Fix class: select_port-style IN-PLACE
  strip+record replacement inside Jedah's per-char region — all three
  superset traps apply (budgets, cell pokes, legacy coord reads);
  bank-1 codes go through the effect-tail triage (content-match /
  reloc / place), NOT raw copy. New GOTCHAS entries: bank attribution
  is an object property; breakpoint traces are lossy SAMPLERS —
  structural closure required; overlay-strip mechanism.
- New tools (persistent): tests/lua/obj_record_bank_trace.lua,
  tests/lua/obj_record_full_trace.lua (all six fmt handlers via the
  0x1AFBA jump table — vsav2 sibling addresses in header),
  tools/gen_anita_bank2.py.
- **Overlay strip inventory MEASURED** (exact, RAM-dump method — the
  debugger-desync gotcha rules out bp traces for this): 16 sub-objects
  $FFB800-$FFBF80, all bank #$2000, cursors in Jedah strip pages
  0x267xxx/0x268xxx (b800/b880 also walk engine-shared strips
  0x15Axxx); b900/b980/ba00 dual-phase to bank #$4000 with PORTED
  cursors (0x0E2xxx sword-anim / 0x0DDxxx / 0x0F619C feet — already
  correct). Cursor-setter decoded: engine routine 0x15082 computes
  cursor = T + T[2*id] (T = per-char self-relative word-offset table;
  Jedah's T = 0x2671C6 measured at one call). vs2 sibling: same 16-slot
  population walks Donovan strips 0x2A0Axx-0x2A1Cxx → records
  0x2A1DAE-0x2A3F80 (codes 0xA3E8-0xA499, bank 1).
- **Stage-7 surgery sketch (next)**: port vs2 overlay region
  (~[0x2A05E2,0x2A4000), bounds to refine) as a new manifest region;
  reroute the char-0x0F strip-base lookup (find who loads T=0x2671C6 —
  per-char table row or computed; repoint to the ported copy); bank-1
  code triage via the effect-tail classes; coordinate cptrs via the
  pool content-match; placement needs ~15KB (hole A ~0xE80 + hole B
  ~0x650 are TIGHT — space audit first; Jedah dead zones are
  attract-demo-read, gate-guarded by the frozen-4278 class). Vanilla
  Jedah strip bytes stay untouched.
- Throw-damage magnitude (round 13 note "lower than Savior 2"):
  recorded as a maintainer-feel item — the port routes Donovan's raw
  damage through VSAVJ's global defense scaling by design; the oracle
  measured the test throw EQUAL to vs2 (-5). If it should match vs2
  everywhere, that's a rules decision, not a bug.

## Session 14 highlights (M2a FROZEN)

- **Playtest round 3 (maintainer): fully clean** — no crashes over
  multiple matches, no music from any input. The 214P/214K stragglers
  were two sound-farm entries masquerading as `engine_data` rows since
  the session-5 bare-long pass (0x4F14/0x5052 — byte-match locks onto
  the same-id vsavj entry = the same-id-different-meaning trap with a
  verified sticker) + the direct-called helper 0x5122. Full farm-ref
  audit (jsr/bsr/jmp/pea from all ported zones): 25 stubbed / 4 live
  init-zone rows. GOTCHAS entry added: when a structure class gets
  understood, re-audit earlier generic rows in its range by MECHANISM,
  not row kind. Note: sound wrongness is invisible to every RAM-basis
  gate (music state lives in QSound RAM) — playtest is the only surface
  catching this class until an M5 harness exists.
- **M2a FREEZE EXECUTED** (playtest-gated per the standing decision;
  maintainer confirmation 2026-07-28): registry row
  `a02aeeff… -> donovan-m2` in tests/expected/registry.tsv;
  `tests/run_suite.sh` gained the `.masked` expectation kind (exact /
  flicker-frozen-inventory / diverge classes per CLAUDE.md §4 v2, masked
  runs auto-selected) and `.skip` (other-romset replays);
  `tests/expected/donovan-m2/` authored from the frozen gate inventory;
  Donovan-replay self-expectations frozen on a02aeeff; vanilla
  expectations frozen for replays 17-26 (drift check on pre-existing
  vanilla sha1s: none). Validation: `run_suite.sh` GREEN on BOTH builds
  by pure fingerprint auto-detection — the one-command-validates-any-
  build doctrine is now real for hooked builds.

## Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)

- Donovan's throw deals correct damage (oracle-measured: 288->283 = -5,
  byte-matching vs2's result at identical inputs, flowing through
  vsavj's own defense scaling). ROOT CAUSE = the FOURTH same-value
  sibling-coincidence class: A5-relative WORK-VAR DISPLACEMENTS. The
  ported throw-damage writer (x028122, vs2 0x28AC2-0x28AF6) stored
  scaled damage into VS2's work-var layout (-0x4B6C/6A/68) while
  vsavj's post-process reads ITS layout (-0x4BBE/BC/BA) — damage into
  dead variables = landed-but-zero. Six displacement port_patches
  (uniform family shift -0x52; vsavj native analog byte-verified at
  0x29790). Diagnosed AND verified by the NEW 27_don_throw oracle pair
  (permanent suite replays; vanilla expectation frozen 086476eb).
- Fingerprint eb051b12: double gate + oracle/xemu/flavor green.
- OPEN AUDIT: sweep ALL ported code for (d16,A5) vs2-layout work-var
  displacements — other dead-var writes may lurk.

## Session 14n (round 12: revert validated; two new items scoped)

- Round 12 on restored 569859d1: specials correct, NO resets — the
  board reset is pinned to the reverted f8eda2ca with certainty.
- NEW COSMETIC: solid-green background tiles around ANITA'S FEET (her
  sprite clean). Likely one/few mismapped tiles in the effect-map or
  tail placements rendering opaque green where transparency belongs —
  find by dumping her OBJ entries at the artifact moment and checking
  which placed tile draws the green block.
- NEW BEHAVIORAL (present since the beginning, priority — gameplay):
  DONOVAN'S THROW deals almost no damage vs Savior 2 / native chars.
  An R1 damage-path gap: his ported throw handler's damage source
  (immediate value, per-char table row, or engine damage id) resolves
  wrong on vsavj. Method: bp-trace the damage post-process during a
  throw on our build AND on real vsav2 (matching inputs), diff the
  damage arguments; then fix the data path (reconciliation row or
  value repoint) — oracle-gated. Needs a throw replay (the test
  matrix's throw/tech coverage gap — write 27_don_throw as part of
  the fix, per the persistent-suite doctrine).

## Session 14m (f8eda2ca REVERTED — regression + board reset)

- Playtest round 11 on f8eda2ca: blink unchanged, 623P degraded, and a
  BOARD RESET mid-fight (watchdog class). Rule 6 halt: the bank-2
  config stripped from effect_tail.json; the build restores 569859d1
  BYTE-EXACT (the round-10-validated build: specials good, sword
  blinks = known open issue).
- Post-mortem of the failed fix: the content-voting attribution was
  wrong — the ownerbox dump already showed the sword records live in
  the ANIM region (rec 0x0F32C8 ∈ anim dst), not x2b7ef4; the 14
  rerouted records were misattributed and the loose record validation
  (731 detections vs ~151 real) makes false-positive rewrites — the
  likely reset mechanism. LESSONS: content voting is too weak for
  bank attribution; only EMPIRICAL object-correlation counts; and any
  pass that rewrites record bytes must validate records STRICTLY
  (known-record lists, not heuristic scans).
- The blink remains open. Correct next method (fresh session):
  side-by-side sword-object comparison — dump the sword object's
  [0x1C]/records/entries on real vsav2 and on our build at matched
  moments; diff entry-by-entry; fix exactly what differs. No rewrites
  without an empirically-verified record list.

## (reverted) Session 14l (bank-attribution fix)

- The x2b7ef4 walk now attributes records by drawing bank via content
  voting: 14 records (109 blocks, 312 tiles — the sword/statue class,
  bank-2 objects) route through band-tail placements (vs2 bank-3
  content at 0xEA40+, 722 tail positions spare); the rest keep the
  bank-1 effect-tail path. Fingerprint f8eda2ca: double gate green,
  companions green. Playtest verdict wanted on: sword steadiness,
  round-start statue, specials still good, win-quote palette (still
  pending implementation), general sweep.

## Session 14k-b (blink TRULY root-caused: per-record bank attribution)

- The saturation theory was an artifact: the ~540 null entries are the
  CLEARED TAIL of the OBJ list (the drawer processes a separate count;
  real usage ~357/896 — headroom fine). Bisect (worktree rebuild of
  8248296e) also proved the coord surgery innocent (identical state).
- REAL MECHANISM (live object dumps): the sword/statue objects draw at
  BANK 2 (their #\$6000->#\$4000-patched setters) but their records
  (x2b7ef4 region, e.g. 0x0FCECA with entry codes ~0x0FD2) were treated
  with BANK-1 semantics by the effect-tail pass. Their anim frames with
  engine-page codes hit wrong bank-2 positions -> invisible frames =
  blinking at the anim rate (matches the playtest report exactly:
  different rate than vs2, statue identical).
- FIX (next): per-record bank attribution in the x2b7ef4 walk —
  content-addressed (bank-2 records' low codes match vs2 BANK-3 art =
  Donovan effect art; bank-1 records match the engine page) — route
  bank-2 records through the band-tail placement (effect-map style)
  and keep bank-1 records on the effect-tail path.

## (superseded analysis) Session 14k (OBJ budget saturation theory)

- Playtest round 10: specials CONFIRMED fixed; sword still blinks and
  the round-start statue blinks identically (same palette; vs2 clean).
- ROOT CAUSE FOUND: the per-frame OBJ list is SATURATED — 897 of 896
  budgeted entries every frame, of which ~545 are ALL-ZERO entries from
  a runaway record (suspected fmt-0 count-0 -> subq/dbra wraparound
  emitting nulls until the budget dies). The sword/statue draw last and
  get budget-skipped on marginal frames = the blink. NOT the class-7
  queue (only one site, already remapped; no live 0x0E-class objects),
  NOT palette-row conflict (row 3 written once), NOT engine budget
  difference (both games 0x380).
- NEXT (precise): (1) dump objects + correlate [0x1C] to find the
  runaway record's owner; (2) rebuild commit 0867b25 (8248296e) and
  count nulls there to bisect pre/post the coord surgery — the blink
  predates it per playtest, but the 545-null magnitude needs the same
  verification; (3) fix = correct the record/chain terminator (and
  audit the coord-surgery's loose record validation for false-positive
  rewrites in the x2b7ef4 blob — 731 detections vs ~151 real records
  is suspicious in itself).

## Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)

- 623P/214K elemental summons render again (snapshot: the flaming Ifrit
  sword + fire pillar in full). Triage of the 491 companion-effect
  blocks: 344 same-index; 70 relocatable by content match (page shift
  +0x47 class, wrap-safety enforced); 77 blocks (263 tiles = vs2's
  newcomer extension of the engine effect page, 0x0E17-0x0F02) PLACED
  at vsav bank-1's padding run 0x3640+ (460 blank positions before the
  system band). Per-entry code remap in the gen (effect_tail pass,
  build/manifest/effect_tail.json).
- BONUS LATENT BUG FIXED (third sibling-coincidence strike, GOTCHAS):
  the records' coordinate lists point into vs2's GLOBAL X/Y pool —
  same-value across siblings, never relocated; effects have read
  garbage coordinates since M2a. Fix: 114 lists content-matched into
  vsavj's own pool, 617 Donovan-specific lists ported (11.3KB fragment,
  hole B). Sword-glint/blink expected fixed by the same pass.
- Fingerprint 569859d1: double gate green, oracle/xemu/flavor green.
  Playtest wanted: 623P/214K/sword in-match, win-quote palette still
  pending (next), quote text line, HUD name, wheel face, attract pal.

## (earlier) Session 14i-b (round-9 mechanisms pinned)

- WIN-QUOTE "left shift" = NOT a defect: both records' coords are
  identically centered on the object anchor; vsavj's own win-screen
  layout places the winner's art LEFT (Bulleta's screen confirms).
  Recorded as a feel item (default = host layout); no code change.
- WIN-QUOTE PALETTE mechanism found: per-char pointer table at CODE
  0x7F196 (PC-relative, indexed by winner char*4 from $140(a5), rows to
  palette RAM 0x17 band) + the ramp path (PC 0x153C2, per-char fade
  blocks ~0x3A14xx, seeding chain via the win module scripts at
  0x7E662). Pointers are consumed transiently (A0, никогда stored) —
  unlike the record cells, ROW REPOINTS ARE RAM-INVISIBLE here: plan =
  place Donovan's vs2 win-palette blocks (vs2 twin tables to locate by
  the same code idiom) in Jedah's freed region + repoint row 0x0F in
  the vsavj tables. Verify with the masked gate as always.
- Effect tail (elemental swords/sword glint): plan unchanged
  (block-content matching + placement + record remap) — next session's
  main chunk with fresh context.

## (earlier same session) Playtest round 9 diagnosis

Playtest round 9 (on 8248296e): win-quote ASSETS correct but palette
wrong + image shifted left (vs2 layout is right-side); Donovan's sword
blinks/vanishes in-match; the elemental-sword specials (623P Blizzard
/ 214K Ifrit) LOST their big blue/yellow effect sprites. Diagnosis:
- FLASH/SWORD = the deferred x2b7ef4 engine-effect tail, NOT a fresh
  regression: those effect records were never remapped in ANY build
  (deliberately left as-is because 1,070/1,455 tiles are same-index in
  vsav); the elemental-sword and sword-glint art is among the ~385
  tiles whose vsav bank-1 positions moved — codes point at wrong/blank
  art. Promoted from 'minor tail' to MUST-FIX. Plan: block-level
  content matching (vs2 bank-1 blocks -> vsav bank-1 relocated
  positions; place the truly-missing into free bank-1 space), per-entry
  code remap in the ported x2b7ef4/anim records via the gen effect-map
  mechanism.
- WIN-QUOTE X-SHIFT: Donovan's ported coordinate list is vs2-layout
  (right side); fix = constant X translation computed from the two
  records' bounding anchors, applied when writing coords.
- WIN-QUOTE PALETTE: the win screen ramps its palette from ANOTHER
  per-char grid (~0x3A14xx for Bulleta; ramp writer PC 0x153C2,
  source-formula base to pin down like the select grid at 0x3AC000).

## Session 14h highlights (win-quote portrait ported; HUD name found)

- Win-quote screen: the family is d0 = 0x40+char over the same root
  table (found via the Bulleta-quote object dump — no replay reaches
  Donovan's own quote screen, so visual confirmation is playtest's).
  His 35-entry win-pose record replaced in place (host budget kept);
  art fit into Jedah's own freed win tiles + the pool tail (pool-math
  lesson: variant alias rows 0x1F point at the SAME records — skip
  them when computing exclusivity). Fingerprint 8248296e, double gate
  green + companions. The quote TEXT line is a separate object family
  (cell area 0x2681xx) — next target if the playtest shows Jedah's
  line under Donovan's portrait.
- NEW COSMETIC FOUND (snapshot): the in-match HUD name label still
  reads "Jedah" — added to the list (with wheel mugshot face and
  attract palette).

## Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)

- VS-splash busts ported (playtest round 8): the six per-char cells'
  FIRST records are the live ones (object durations read garbage-huge
  values, so chains never advance). Final surgery set: splash P1/P2 +
  pal P1 in place (with the wheel portrait + name from phase 2); the
  hover-P2/pal-P2 records PROVEN SHARED with the win screen on legacy
  paths and left vanilla; 130 more bank-1 tiles placed. Snapshot: the
  VS screen shows Donovan's praying-hands bust, correct colors + name.
- THE MASKED LEGACY GATE CAUGHT THREE REAL SUPERSET VIOLATIONS in this
  surgery series, each root-caused to the byte (GOTCHAS entry): cell
  pokes are RAM-visible via stored anchors; record budget words debit a
  shared frame budget ($FF811B one-byte proof); the win screen reads a
  "select" record's coordinate list on legacy paths (frame-10732 trace,
  PC 0x8C6E2). Fixes: in-place only, host budgets preserved, shared
  records left vanilla. Fingerprint 189fdff3: double gate run green,
  oracle/xemu/flavor green.
- Remaining cosmetics: wheel hexagonal mugshot face (background scroll
  art), win-quote screen (still Jedah — the winner-portrait family, to
  be found the same way), attract palette.

## Session 14f highlights (select palettes fixed; splash/win specified)

- Playtest round 7 (portrait/name correct, PALETTES wrong; splash+win
  still Jedah) -> palette grid found and ported in place (11 variant
  rows; vs2 keeps Donovan's rows behind a code special-case +0xC6).
  Fingerprint 4fc8d14b, full battery green. Splash/win screens fully
  mapped (bust objects, three char-scaled cell families, six pokes
  needed); blocked only on the struct flag-byte termination decode for
  exact chain inventories — then it is the phase-1 zone port with the
  right cells. See engine_internals.

## Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)

- Donovan's big portrait and name banner render at the select screen
  (snapshot-verified) — in-place record surgery (select_port.py phase
  2) + 101 bank-1 tiles placed in Jedah's freed select/splash art.
  Build e98a357a; splash-frame OBJ dump closed the placement safety
  gate; cursor-highlight record deliberately kept Jedah's (vs2 wheel
  geometry mismatch). Full battery: soaks, oracle, xemu, flavor,
  scroll3 green; masked legacy green on rerun x2.
- GATE ANOMALY under standing watch: one invocation failed 02/10 masked
  (84 frames @663 on 10); same build passed everything on reruns,
  deterministically at the frozen inventory. Unreproduced; failing-log
  preservation added (build/gate_failures/). Recurrence = stop and
  root-cause.

## Session 14e (earlier): handles found, surgery specified

- Differential cursor dumps found THE handles: per-wheel-slot pointer
  arrays advanced by cursor movement; Jedah's three record cells
  identified; P2 arrays alias the same records => in-place record
  replacement fixes both sides, zero pokes. Donovan's three records
  dumped live on real vsav2 (all smaller => fit in place). Art fit
  computed (9 blocks incl 8x8 into Jedah's exclusive family art).
  ONE open safety gate: empirically prove the chosen tile positions
  are not shared with other chars' VS-splash art (in-match module
  family, root 0x0B76C0 — structure differs, needs a live dump).
  Then implement + snapshot-verify + battery. Map in engine_internals.

## Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)

- Attempted the select-portrait port via the three traced root cells
  (select_port.py: zone port into Jedah's freed region + pokes). Pokes
  landed, screen unchanged — the live chains are INLINE pointer arrays
  in the shared web, not those cells (live object dumps on the patched
  build; engine_internals corrected). Reverted from the build (stage 6
  back to verified 71601263 byte-for-byte); select_port.py kept as WIP
  machinery. The LIVE PREVIEW at select already shows Donovan+Anita
  correctly; only the big portrait, name banner, and mugshot remain
  Jedah. Next: two-char differential dumps at the hover moment to pin
  the per-char inline groups, then in-place 32-bit pointer surgery.
- Space fact: the eventual select web (~51KB) must live in Jedah's
  freed anim region — both PRG holes are nearly full.

## Session 14c highlights (select-screen pipeline mapped)

- Select-portrait/name pipeline fully mapped by live instrumentation
  (docs/engine_internals.md new section): per-char 32-bit root cells
  enumerated by breakpoint trace (six cells for a full pick), name-table
  row located, vs2 twins located (master 0x2A0426, roots 0x2A05E2,
  name 0x2A0A4A row 0x13), Jedah's freed select art sized (~2K bank-1
  tiles) — the port is a repoint-six-cells + region-port + art-place
  job, all slot-0x0F-only. trace_writes.lua gained breakpoint mode.
- MAME Lua gotchas recorded: single-slot register_frame_done vs
  multi-subscriber notifiers (subscriptions must be pinned).

## Session 14b highlights (M2b static phase — R2 cracked)

- MAME WITHHELD all session (user needs the machine; static analysis
  only). gfx groundwork: canonical CPS-2 tile extraction
  (tools/gfx_tiles.py — the simms are NOT tile-contiguous, see GOTCHAS),
  measured: vsav2/vhunt2 share one gfx layout; vsav2-vs-vsav = same art
  REPACKED (content-addressed match 201K tiles, same-index only 6.5K);
  vsavj is a program-only clone (gfx lives in vsav.zip).
- **R2 RESOLVED STATICALLY** (was: "the hard wall"): OBJ tile codes are
  absolute 16-bit + bank bits from object field +0x18 (Y-word bits
  13-14; per-char slot-indexed init table vsavj 0x282D4). Full decode of
  the OBJ record format + emitter chain in docs/engine_internals.md.
- **Donovan FITS in Jedah's tile band**: 15,171 tiles extent 0x3CB1 vs
  Jedah's 16,658 extent 0x417F (both measured by tools/obj_records.py,
  locked in tests/test_gfx_tiles.sh). Port = tile-data re-encode into
  Jedah's positions + 16-aligned constant delta on record tile words +
  patch his #$6000 bank setters to #$4000 (slot table gives 0x4000
  free). No ROM expansion needed for M2b.
- Exclusivity walk (player-OBJ, all slots): Jedah's band clean except
  a 44-tile Sasquatch-shared head (0xAD3E-0xAD74) — safe floor 0xAD80,
  usable extent 0x413C >= needed 0x3CB1. STILL FITS.
- Tile-data step BUILT AND VERIFIED (tools/build_gfx_donovan.py):
  Donovan's 15,171 tiles placed into patched vm3 group-B members at
  codes 0xAD8F-0xEA3F bank 2 (delta +0x2750), readback + untouched-byte
  verification green, placed range visually renders Donovan art.
  Scroll-side exclusivity: scroll1/2 cannot reach bank 2 (measured from
  the CPS2 draw path, no mapper); scroll3 can, but Jedah's band is
  99.3% saturated by his own OBJ records and renders as pure sprite art
  — residual risk queued as an in-emulator scroll3 watch.
- Playtest round 4 (maintainer, on their own quick build of 06f99f4e):
  sprites GOOD and animating correctly; palette = Jedah's (palette port
  not yet done — expected); blinking/alternating tiles esp. at char
  select. Root cause: format-0 OBJ records have 2-BYTE tile-only
  entries (my unified 4-byte walk remapped alternate tiles) — fixed
  format-aware in obj_records.py + the generator; new stage-6
  fingerprint f83ff57e… (13,177 words remapped; output re-verified;
  2 stray sub-band tiles 0x813C/0x822C belong to the effect-tail
  class). GOTCHAS entry added. PALETTE PORTED same session: per-char
  palette pointer table found (vsavj 0x38C198 / vs2 0x396B94; uploader
  0x1C3FE -> palette RAM 0x90C140), Donovan's 0x500-byte block (all
  confirm variants) placed + row 0x0F poke32'd — stage-6 fingerprint
  5cb2b2a9…, output-verified. Awaiting playtest: colors + blink both
  fixed. Then: effect-record map, portraits (art + palettes), attract
  palette path (0xB0AC/0x3A3CA0) if playtest shows wrong attract colors.
- Playtest round 5 (palettes good; residual blink left-of-P1 + one on
  Anita; specials clean) -> root-caused STATICALLY: the mixed-record
  shared-effect entries (116 tiles drawn at bank 2) were still
  unmapped. Effect map landed: gen shelf-packs their blocks into the
  freed Jedah-band tail (0xEA40+) + build_gfx places the tiles
  (effect_map.json); x2b7ef4 companion-effect records verified
  NO-ACTION (bank 1, engine page byte-identical in place, 1070/1455).
  EN ROUTE: the count+1 misread of fmt-0 records CORRUPTED build
  08a12dc6 (next-record format words clobbered) — caught by the
  output re-walk BEFORE any playtest; fmt-0 = COUNT entries (subq
  before dbra); tools/verify_gfx_build.py now gates every stage-6+
  build (record parity + code containment + table check). Current
  stage-6 fingerprint: 71601263… (parity 1122/1122, all codes in
  [0xAD8F,0xEAB1], stage 5 still a02aeeff). Playtest round 6: SPRITES
  CLEAN (palettes good, blink gone, effects clean; portraits unchanged
  as expected). MACHINE WINDOW USED: full battery green on 71601263 —
  new permanent gates tests/test_m2b_stage6.sh (guarded soaks incl 40K
  marathon + masked legacy, flicker inventory unchanged) and
  tests/test_m2b_scroll3.sh (0 danger frames; scroll3 base boot-
  constant, one write in 42K frames) + oracle/xemu/flavor PASS against
  the stage-6 rompath. M2b CORE IS VERIFIED. Remaining for the M2b
  freeze decision: portraits/name art + their palettes, attract palette
  path, engine-effect tail refinement.
- STAGE 6 (superseded 06f99f4e) — original notes: fingerprint 06f99f4e… —
  gfx_remap (13,171 tile words / 1,122 records), 6 bank setters
  #$6000->#$4000, [table_fix] (ported bank table was TRUNCATED at row 9
  and carried vs2 values — two latent stage-5 defects, now vanilla
  vsavj values), rompath carries patched vsav.zip. Stage 5 still
  reproduces a02aeeff. AWAITING MAME ALL-CLEAR for: legacy gate battery
  on stage 6, first look at Donovan rendered, scroll3 watch.
- Open for next (static): effect-record map (85 resolved/27 open),
  portrait/name inventory, Zabel slot-0x04 walker gap, then SCROLL-side (stage art vs absolute range
  0x2AD80-0x2EEBB — Jedah's stage is legacy and must stay intact),
  Zabel slot-0x04 walker gap, the 112 shared-effect tiles
  (content-map), portrait/name inventory, then the gfx builder +
  in-emulator verification (QUEUED until the maintainer frees the
  machine).

## Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)

- **The session-6 "anim state-index delta" was NOT a state-space delta.**
  It was extraction tooling corruption: the bare-long relocation heuristic
  fused instruction operand pairs (e.g. `clr.b $6(a6); moveq #0,d0` =
  `0006 7000`) into plausible pointers and rewrote them — 47 false
  rewrites latent in the two source-only zones; one destroyed the
  `moveq #0,d0` anim-state reset, sending an X-distance value into the
  engine anim setter (the vec3 at 0x015096/frame 3025). Diagnosed with a
  new guard instrument (`GUARD_PROBE`/`GUARD_PROBE_COND` conditional
  logging breakpoint — the D0 hit sequence told the whole story).
- **Extractor hardened (tools/extract_char.py + scan_code_refs.py):**
  immediate loads (`movea.l #imm`/`move.l #imm`) are now labeled refs;
  every bare-long candidate is validated against the vhunt2 SIBLING
  (context match with labeled operands wildcarded): identical sibling
  bytes → vetoed (operand pair), host-shift-consistent → confirmed,
  conflicting/absent evidence → rejected loudly. 47 vetoed/rejected,
  5 confirmed real, 0 silent keeps. Details: docs/GOTCHAS.md.
- **RESULT: the full 12_donovan_vs_cpu moveset replay (9320 frames) runs
  END-clean under the -debug crash guard.** No crash, no tripwire. The
  stage-4 bring-up ladder has no frontier.
- **Legacy gate measured honestly (this predates session 7's changes):
  the stage-4 build fails bit-exact whole-RAM comparison** — NOT from a
  behavior change: engine hooks cost cycles on the every-object dispatch
  path; interrupts then land at skewed boundaries → dead-stack ghost
  bytes ($FF7F00-$FF7FFF, below resting SP at frame-done) + the QSound
  handshake latch $FF043C phase-shifts one frame. Hooks converted to a
  ghost-clean topology (vanilla `jsr (A0)` kept in place; thunk jmps back
  to it) removing the push-value ghost; the interrupt-skew ghosts are
  physically unavoidable (zero-cycle table extension proven impossible —
  GOTCHAS). **With exactly those two windows masked, 02 is bit-identical
  to vanilla full-length and attract first diverges at exactly 4278 (the
  Jedah demo).** Live state is vanilla.
- `MASK_RANGES` opt-in on replay.lua (canonical checksums unchanged when
  unset); new gate `tests/test_m2a_stage4_code.sh` locks all of the above.
- **Session-7 extension (after the maintainer approved the masked basis):
  widening the masked legacy gate from 1 to all 7 exact replays found the
  v1 masks are not sufficient alone.** Measured:
  - 03/10/16 each show 1-2 ISOLATED single-frame divergences that fully
    re-converge (03: frames 829+2093 — 829 is the S2 input-accept
    boundary; 10: 3007+3129; 16: 829). Transition state captured one
    frame apart; bytes involved: $FF80B5, object-slot heads
    $FF8400/$FF8800. A real bug in this deterministic engine cannot
    re-converge to bit-identical whole-RAM; bounded re-converging
    flickers are a timing-phase signature. New ground-truthed comparator:
    `tools/compare_flicker.py` + `tests/test_compare_flicker.sh`.
  - 06_test_mode diverges PERSISTENTLY from exactly frame 700 — the TS
    press. Root cause is hook-caused, not ROM-content (stage-3 builds,
    ROM-modified but hook-free, ran 06 bit-identical): service-mode code
    reads the phase-shifted QSound latch and the offset propagates into
    live service state (residue: sound mirror + two checksum/accumulator
    words). Benign, no gameplay surface, but a letter violation.
  - 02/05/07 masked-exact full length; attract 4278 and pick 1080 masked
    diverge-constants hold. Whole-live-state identity therefore holds for
    all match gameplay; the exceptions are input-boundary flickers and
    service mode.
- **2026-07-27 (session 11): STAGE 5 BUILT AND FULLY GREEN — M2a is
  functionally complete pending the freeze decision.** Stage-5 build
  fingerprint **d6d8f273…** (updated after the playtest fixes —
  see the session-11 playtest entry below): the Start-hold flavor selector is LIVE
  (init shim reads the per-player Start bitmask $FF8060 at char-init;
  hold YOUR Start through match load → VH2 flavor; verified 3-way by
  the new `tests/test_m2a_flavor_selector.sh` — plain 01 / P1-held 00 /
  P2-held 01, per-player isolated); the unreachable Anita alternate-
  anim-table operand is poisoned (new imm_poison generator mechanism —
  loud vec3 at a named block if a future writer arms the branch); the
  aux_poke survey concluded none are needed for the M2a bar (select
  behavior works via bank repoints; portrait/name = M2b GFX). ALL gates
  green (initially on 4b65bc63; superseded by d6d8f273 after the
  playtest fixes below): guarded moveset, masked legacy, oracle,
  dual-emulator, flavor selector. **Freeze = pending maintainer build
  decision (see Decisions pending).**
- **2026-07-27 (session 11, first human playtest):** four findings, all
- DECIDED (round 22, maintainer): palette-uploader poke ACCEPTED —
  02/05/07 reclassified flicker@829, pick constant 829; revert path
  documented if playtest shows problems. (original entry follows:)
- **Palette-uploader poke vs exact-gate class (session 14y)**: poking
  the select/HUD palette-row uploader (CODE:0x1BF56 -> the patched
  win-palette copies) fixes the HUD mini-portrait green pixels
  (round 21), the select-portrait palettes and most likely the
  win-quote palette — all through one site. Cost: the select-entry
  bulk upload leaves a ONE-FRAME work-RAM trace at the known
  spawn-boundary flicker frame (829), so 02/05/07 would move from
  masked-EXACT to masked-FLICKER (inventory @829, the already-
  approved mechanism class; verified: exactly 1 divergent frame,
  full re-convergence, pixel gates green). Recommendation: accept
  the reclassification — it is the same mechanism class the other
  six legacy replays already carry at the same frame. Until signed
  off, the poke is reverted and the palettes stay Jedah's.

  dispositioned (docs/tables/reconciliation.md "Session 11"): garbled
  sprites = M2b expected; flavor hard to eyeball = expected (QCB+K is
  the fork); 4-option select = REFUTED as port artifact (vanilla shows
  the identical menu on factory EEPROM — snapshot-proven); **DP-spam
  crash = REAL — reproduced deterministically (19_don_dp_spam, ES DP),
  root-caused to a third extended brief-word engine table (defender
  hit-reaction dispatch, vs2 adds ids 0xA2/0xA4/0xA6, ES DP inflicts
  0xA2), FIXED via [reaction_hook]** (verbatim vs2 case stubs from
  config hex, ghost-clean thunk, original dispatch untouched for
  vanilla ids). Also closed a gate coverage gap: 04/08/09 restored to
  the masked legacy gate (measured pure flicker class; frozen logs
  added) — the gate now covers all 13 original replays. 19_don_dp_spam
  joined the code gate's guarded set. New freeze candidate d6d8f273,
  everything green.
- **2026-07-27 (session 12): the palette-seq hijack is FIXED (private
  stub entry; vanilla flows untouched — the session-9 base-swap had
  hijacked LIVE vanilla seq ids 0x2CD+); all gates green on b2e34c87.
  The sustained-mash wedge REMAINS OPEN — deterministic repro, display
  freezes while logic runs; eliminated: palette hijack (fixed, wedge
  persists), meter anomaly (+0x3B2=0 and 99-cap are normal — identical
  on native vs2 AND vanilla), the "Lilith scene" reading (it was the
  post-game-over attract flow). Mechanical bisection protocol written
  (reconciliation.md Session 12). FREEZE ON HOLD until resolved.**
- **2026-07-27 (session 11b, second playtest round): the mash/time crash
  is FIXED.** DP confirmed fixed by the maintainer; new crash on heavy
  activity reproduced with 21_don_mash (input-chaos soak) — the type-114
  effect's creation code loads an ENGINE-SHARED anim table via a raw
  un-hosted movea immediate (vs2 0x1D7428). Fixes: extractor now
  classifies un-hosted movea.l #imm ROM targets as ENGINE refs (row or
  tripwire — retires the manual imm_poison, 0x36784A auto-tripwired);
  new engine_data row 0x1D7428→0x1F3FD2 (unique content match). Round
  transition alone proven clean (20_don_round2); both soaks join the
  code gate (4 guarded replays). Full battery green on the NEW freeze
  candidate **cdf62d8c**.
- **2026-07-27 (session 10): BOTH stage-4 gates PASS on one build
  (fingerprint 67753ee3) — the first all-green run with every system
  active.** The "0x17522 trio" turned out to be the DAMAGE PIPELINE and
  is mapped, not ported: the KO-write signature located vsavj's
  byte-parallel damage wrapper (0x189BA ↔ vs2 0x17330) and every bsr
  position voted — 0x17522→0x18B8C (defense-scaling), 0x17422→0x18AB0
  (post-process), 0x17B22→0x19128 (KO). Donovan uses vsavj's own damage
  machinery (correct superset semantics). Moveset replay END-clean 9320
  frames; code gate green (incl. masked legacy, flickers unchanged);
  oracle gate green. **And the dual-emulator gate PASSED
  (test_m2a_stage4_xemu.sh: patched build on MAME + patched FBNeo,
  anchors 2363/2364 — 1-frame skew — all mapped fields agree at follow
  0/60/180). ALL THREE STAGE-4 GATES GREEN on fingerprint 67753ee3:
  STAGE 4 IS CLOSED.** Next: stage 5 (select plumbing + Start-hold
  flavor selector), soak, freeze.
- **2026-07-27 (session 9): the +0x14E frontier is CLOSED and the
  ORACLE GATE PASSES as a scripted test.** The state hook landed
  (synthesized case stubs + ghost-clean thunks + relocated palette-seq
  records + 4 consumer base-swaps — patch_notes session 9); Donovan's 8
  sound-farm calls stubbed silent (M5 restores; sfx ids recorded in
  reconciliation.toml); anim_index_a2 resolved from gap auto-kind (was
  feeding Jedah's anim rows to Donovan's attacks). Moveset replay
  END-clean again. `tests/test_m2a_stage4_oracle.sh` PASS: anchors equal
  (2363), neutral window exact, P2 HP trajectories equal (hits land,
  same damage), and the comparative bound — ported Donovan diverges
  LESS across the two engines (890 mismatches) than vanilla Demitri
  does (2379): the residual ~1-frame action-latency skew is the
  ENGINES' cross-game difference, proven by the 18_veteran_ctl control
  pair. Remaining stage-4 behavior work: dual-emulator gate (16-pattern
  Donovan replay on MAME + FBNeo), then stage 5.
- **2026-07-27 (session 8): the vsav2-as-oracle behavior gate is BUILT
  and immediately caught two real bugs.** Replay pair 17_don_oracle_*
  (both games anchor at frame 2363 — sibling engines run identical menu
  timelines). Bug 1 FIXED+verified: "gap_bd7fa" was really dispatch_14
  (per-char code dispatch); row 0x0F still ran JEDAH's state routine
  against Donovan's data (the session-4 "ignores inputs" family) —
  reclassified, extractor de-hardcoded (walks all dispatch_NN), rows
  repointed; neutral-idle field compare now agrees on all fields for
  1100 frames. Bug 2 OPEN (the current frontier): the +0x14E engine
  state dispatch (vsavj table 0x2A7E2, 89 entries) is EXTENDED in vs2
  (101 entries — 12 newcomer states); Donovan's VS2-flavor QCB+K writes
  state 0xB6 → indexes past the vanilla table → ILLEGAL → soft reset.
  Fix design + details: docs/tables/reconciliation.md "Session 8".
  HP-decrease sanity holds natively (Victor −11 ×2). NOTE: with
  dispatch_14 active the 12_donovan moveset replay also reaches the
  +0x14E states and crashes at 3815 — stage-4 gate lock 2 is KNOWN-RED
  until the hook lands (legacy gate green; one fix closes both).
- **2026-07-27: v2 approved (see Decisions made) and the Start-hold
  flavor mystery RESOLVED** — community protocol confirmed (Donovan +
  Huitzil only), mechanism pinned end-to-end with the new instruments
  (masked comparison found the behavioral fork at the exact QCB+LK
  frame; read-watch named both consumers, both inside ported regions).
  One consequence gates the upcoming vsav2-as-oracle behavior gate: the
  ported build's latch byte defaults to the WRONG flavor (VH2) — the
  oracle's native side defaults VS2, so QCB+K would diverge at the field
  compare until the default-flavor decision lands (Decisions pending).
  Note: 12_donovan_vs_cpu's battery includes QCB+K — the ported
  VH2-branch code path already runs crash-free under guard.

## Sessions 5-6 highlights (M2a stage 4 — the port runs)

- **Companion (Anita) chain decoded end-to-end**: pool geometries are
  identical per-index in both games; allocator family mapped (never
  ported — it reads the game's own RAM bookkeeping); creation handler's
  anim-table pointer was the last unrelocated piece; class-7 (vs2-only
  update queue) remapped to vsavj's equivalent class.
- **New extraction capabilities** (all in `tools/extract_char.py`):
  data-kind extra roots with forced twins; *segmented* gap-tolerant
  oracle diff (resyncs after cross-game insertions — Anita's 44.2K asset
  region: 2065 pointer fields over 75 segments); self-pointer
  classification for micro-shifted multi-blob regions; chunk-BFS graph
  sizing before committing space; PC-relative word-table discovery with
  full-extent protection.
- **New generator capabilities** (`tools/gen_donovan_patch.py`): layout
  groups (PC-referencing families keep source-relative spacing, gaps
  recycled), near_map satellite placement within d16, pcrel entry
  rewrites with shared per-region tripwires, slot-clearing allocator
  wrappers, port_patch byte edits, stage-1 scaffolding gated to stages
  1-3.
- **SPACE BUDGET CLOSED**: ~335K placed of 336.6K free (hole A ~1.4K
  spare, hole B ~12.9K). Achieved by honest region bounding, porting only
  Donovan's own sub-object handler types (others tripwired), and tighter
  margins.
- **Result**: char-init completes, match runs (timer, CPU opponent, HP
  structs). Crash frontier moved 2886 → 3025.
- **Frontier**: vec3 at engine 0x015096 — the anim word table is
  byte-identical to native vsav2 (data+relocation correct) but the INDEX
  into it is wrong; a state/substate byte carries a vs2-flavored value.
  Full detail + next probe: docs/tables/reconciliation.md "Session 6",
  docs/NEXT_SESSION.md.
- **GOTCHAS paid**: PC-relative reads are decrypted reads on CPS-2;
  PC-relative word tables are DATA (a fused pair of word entries was
  silently corrupting a dispatch table).

## Session 4 highlights (M2a — the real Donovan port)

- **M2a plan approved** (staged: C0 harness → C1 extraction → C2 generator →
  bring-up ladder stages 1-5 → close-out). Stage design: null-relocation of
  Jedah's own data first (tooling proof, zero R1 ambiguity), then Donovan
  data → anim → code dispatch (R1 surface) → select plumbing.
- **C0 COMPLETE (harness primitives, all verdict logic ground-truth tested):**
  - Crash guard: breakpoints on 68k exception handlers, fault PC/ADDR from
    the exception frame, stack sketch, RAM dump (`replay_guard.lua`,
    `run_replay_guarded.sh`, `test_crash_guard.sh` — vec3/vec4 positive
    controls trip correctly).
  - Dual-emulator field comparator per amended §4: debounced match-start
    anchors, stable/settled/phase field classes (`compare_fields.py`,
    `fields_m2a.tsv`, selfcheck green: MAME/FBNeo agree on 16_xemu_2p with
    1-frame skew).
  - Auto-detecting suite runner: program-image fingerprint →
    `tests/expected/<expset>/` dispatch; `.diverge` expectation kind
    (exact-frame divergence vs frozen full logs). Suite green, 12 replays
    (added 11_pick_donovan, 16_xemu_2p).
  - FBNeo verified to load CRC-changed patched zips (no descriptor change
    needed); `run_replay_fbneo.sh` gained `FBNEO_DUMPS`/`FBNEO_ROMPATH`.
- **Cross-emulator findings (GOTCHAS paid):** MAME `-debug` perturbs
  multi-CPU timing (checksum gates must run non-debug); vs-CPU replays have
  emulator-divergent content (different CPU-picked opponents); menu presses
  near transitions land on opposite sides of input-accept boundaries;
  match-start predicate flickers during intros (debounced).
- **C1/C2 COMPLETE:** oracle-validated extraction (`extract_char.py` —
  every cross-sibling diff byte must classify as a pointer field under a
  measured shift; auto-discovers new region shifts, e.g. the sprite/OBJ
  sub-tables at −0x2002C), staged patch generator, `find_equiv.py`
  (validated at score 1.00 on the known loader), `build_donovan.sh` driver.
  Donovan footprint closed at ~235KB, 9+ regions.
- **STAGES 1-3 PASS** (gates in tests/): null relocation (Jedah copy,
  10018 B — matches M1 exactly), Donovan passive data (full round under
  guard), anim + sprite sub-tables (idle-coherent; select-screen hover
  reads anim → pick divergence pin moves 2886→1080 at stage 3+).
- **STAGE 4 (in progress, deep):** R1 mechanized (`reconcile_batch.py`:
  pattern ladder, stub-deref, callsite anchoring via veteran parallelism,
  codebytes, farm-param matching; ~120 verified rows) + per-target
  TRIPWIRES for opens (fault PC names the target). Ported regions: +0x34
  newcomer-support zone, 17 extra secondary-object handlers, engine
  char-init pair, VS2-only 0x8xxxx companion zone (source-only). TWO
  engine hooks live (extended type-dispatch tables 59→76 and 114→124,
  jsr-thunk pattern; vanilla rows byte-identical). **Donovan RUNS on the
  vsavj engine** (match, timer, CPU opponent, HP structs, guard clean,
  screenshot in scratch). [Superseded by sessions 5-6 above: the companion
  chain is decoded and the port fits; see that section for the current
  frontier.]
- Suite GREEN, 13 replays (added 11_pick_donovan, 12_donovan_vs_cpu
  moveset-exercise, 16_xemu_2p; vanilla expectations + full logs frozen).
- **Next actions (stage 4 close):**
  1. Decode the pool-index correspondence + spawn-node field protocol
     (vsav2 node writer = the 0x8A5A8 hook; vsavj consumer =
     `PRG:0x0155D0-0x015650` jump-table on `(0x9,A6)`; watch $FF79BE+
     pool heads). Consider REWRITING the hook to vsavj's protocol
     (synthesized, GEN provenance) instead of porting VS2's.
  2. Then: stage-4 gates (vsav2-as-oracle field compare at anchors —
     native Donovan pick on vsav2 = cursor R×2 from default; dual-emulator
     on 16-pattern replay; legacy gate every build).
  3. Then stage 5 (select plumbing aux pokes) + soak + freeze.

## Session 3 highlights

- CLAUDE.md §4 dual-emulator amendment applied (maintainer-approved).
- **Donovan/Huitzil/Pyron located and pinned** (char IDs 0x13/0x10/0x11,
  hitbox bases + handler code addresses in both vsav2 and vhunt2).
- Per-character table bank semantically labeled (14 dispatch tables +
  hitbox pairs + parameter tables); bank layout identical across all three
  sets (same internal deltas from a per-set origin).
- RAM atlas: round timer $FF8109, HP +0x50/+0x52 (max 0x120), X/Y
  +0x10/+0x14 added.
- Remaining for M1 acceptance: per-character manifests' remaining columns
  (anim scripts, tile ranges, palettes, sound cues); meter/rounds-won RAM
  offsets; formal Aulbath slot-9 pick; vhunt2-side pick verification of
  D/H/P; Start-hold flavor mechanism (VS2-vs-VH2 behavioral deltas are NOT
  in hitbox data — identical across both games).

## Current milestone

**M2 — Proof of life. IN PROGRESS.** Replaced slot = Jedah (0x0F).
- Program-patch tooling (`tools/patch_prg.py`) DONE and MAME-verified: data
  raw, code re-encrypted, null bit-identical (`tests/test_patch_prg.sh`).
- **Mechanism PROVEN end-to-end on trusted tooling** (`tests/test_m2_repoint.sh`):
  repointing vsavj Jedah's hitbox-base bank entry to Demitri's takes effect
  in a live match (RAM:$FF8460 loads the new base), AND the superset
  invariant holds exactly — 6/6 non-Jedah legacy replays bit-identical;
  attract bit-identical through frame 4277, diverges at 4278 precisely where
  its CPU demo shows Jedah (char id 0x0F, verified). Attract legitimately
  involving the modified slot is correct superset behavior, not a violation.
- Feasibility assessed (docs/M2_feasibility.md): behavior data portable via
  ~337KB free vsavj space + data-reads-bypass-encryption; sprite tiles are
  the R2 wall (may pull M3 forward); QSound = M5.
- **M2a IN PROGRESS (sessions 4-7, see highlights above):** extraction,
  generation and relocation tooling complete; stages 1-3 PASS; stage 4
  bring-up DONE — the full moveset replay runs END-clean under guard
  (session 7; the session-6 "state-index delta" was extraction
  corruption, fixed). Legacy-gate basis decided (live-RAM masked windows,
  see Decisions made) and the masked legacy gate is green over all 9
  legacy replays. Remaining for stage-4 close: the behavior gates
  (vsav2-as-oracle field compare at anchors, native pick = cursor R×2;
  dual-emulator on the 16-pattern replay). Then stage 5 (select
  plumbing) and M2b graphics.

### M1 — Map. ACCEPTED (2026-07-25).
Both SPEC §4 clauses met; full assessment in docs/M1_acceptance.md.
Deferred sprite-bound exact addresses (tile/palette/sound) are
proven-reachable and scoped to M3/M4/M5.

### M1 detail (all complete)
- Replay harness: DONE both emulators. Shared `.rpl` input-script format;
  MAME runner (`tests/lua/replay.lua` — inputs, checksums, snapshots, RAM
  dumps) and patched-FBNeo runner (`emu/fbneo-patches/0001-…-harness.patch`,
  `tools/run_replay_fbneo.sh`). Both proven deterministic run-to-run.
- 10-replay legacy suite: DONE, green, expectations frozen
  (`tests/run_suite.sh`, `tests/expected/vsavj/`). Semantics spot-verified by
  snapshot (2P pick, challenger interrupt, mid-attract start all confirmed).
- **Cross-emulator finding (important):** MAME and FBNeo agree bit-exactly
  for the first 71 boot frames, then run the same states on *different frame
  indices* (transitions land ±frames apart; static screens re-sync; ~37
  work-RAM bytes differ at title — phase-shifted counters + sound-driver
  area $FF05xx). **Frame-exact whole-RAM dual-emulator comparison does not
  hold.** Superset-invariant enforcement is unaffected (oracle = same
  emulator, vanilla vs patched). Recommendation for CLAUDE.md §4 amendment
  (human sign-off requested, non-blocking): new-content dual-emulator
  verification = mapped gameplay fields (player structs, HP, positions,
  timer) compared at sync anchors (match start), not whole-RAM checksums.
- RAM map: community anchor imported and verified (player structs
  $FF8400/$FF8500, hitbox ptr offsets, match-active flags), extended by
  differential experiments + write-traces. See docs/atlas/ram.md.
- **Character-data plumbing CRACKED (the big one):** write-trace on
  $FF8480 → per-character loader (vsavj PRG:0x028DD8) → three 32-entry
  tables indexed by 5-bit char id → located in ALL THREE sets by
  instruction-pattern search → a whole bank of ~20 per-character tables
  (vsavj PRG:0x0BD0FA-0x0BE8xx). Slot→name map ~10/16 done empirically
  (pick + snapshot + pointer readback). Variant slots: vsavj {8}=Oboro
  Bishamon; vsav2/vhunt2 {0,1,3,8,9} with per-slot hitbox data
  byte-identical between vsav2 and vhunt2 (both games carry both flavors).
  **vsavj slot→character map COMPLETE** (16/16, one by elimination).
  **DONOVAN/HUITZIL/PYRON LOCATED** (pick-verified on vsav2): char IDs
  0x13/0x10/0x11 — the variant half of slots 3/0/1 — with hitbox bases in
  both vsav2 and vhunt2 recorded. Base-half slot assignments are identical
  across the whole series. Full detail: docs/atlas/character_tables.md.
- Three-way diff: window/masked diff built (`tools/diff_sets.py`);
  **finding:** vsavj↔vsav2 share <10% at window level even pointer-masked —
  engines were rebuilt (shifted code, changed PC-relative displacements) and
  most of the 4MB is game-specific data. The atlas grows from anchored
  RE (traces + tables) — which the character-table crack has now proven out.

### M0 — Bench. COMPLETE (2026-07-25). Acceptance status:
- Null-patch output bit-identical to reference: **PASS** (`tests/test_null_build.sh`)
- 60s attract replay deterministic across two runs: **PASS** (`tests/test_attract_determinism.sh`, MAME)
- Headless MAME runner: **DONE** (`tools/run_mame.sh`, MAME 0.288 via Homebrew)
- Headless FBNeo runner: **DONE** (`emu/fbneo` submodule, SDL2 build,
  `tools/run_fbneo.sh` with dummy SDL drivers + sandboxed HOME;
  `tests/test_fbneo_smoke.sh` PASS). The SDL2 frontend has no scripting, so
  the per-frame RAM-checksum probe on the FBNeo side is a frontend patch —
  first M1 task (see below)

Bonus beyond plan: CPS-2 decryption/encryption pipeline
(`tools/cps2_decrypt.py`) proven bit-identical to MAME's implementation via
opcode-space dump oracle (`tests/test_decrypt_oracle.sh`). Both directions
(decrypt for analysis, encrypt for future patch injection) self-check.

## Next actions

1. **M2b — Donovan graphics** (docs/M2_feasibility.md: the R2 tile
   wall). First step: measure — tile inventory for slot 0x0F (portrait,
   name, sprite banks), what the garbled-but-recognizable rendering
   implies about tile-index vs tile-data remapping, whether M3 (gfx
   ROM extension via descriptor lines) must be pulled forward.
2. Suite/watch duties continue: flicker inventory is frozen — any growth
   or systematic divergence is stop-and-root-cause (CLAUDE.md §4
   standing watch).
3. Parked (register per milestone): M5 sound restoration (25 stubbed
   rows + dispatcher table), Huitzil/Pyron tripwired handlers (M3),
   bank-tail parked tables, 0x2c31xx data opens.

## Open items

- None blocking. Reference collection is COMPLETE: vsav, vsavj, vsav2,
  vhunt2, vhunt2r1, qsound_hle — all MAME `-verifyroms` green, all 76
  members frozen in `docs/checksums.txt` (vsav2 supplied by maintainer
  mid-session 2026-07-25 and folded in; re-freeze recorded here).
- ROM packaging fixes from the 2026-07-25 audit are confirmed applied:
  `vhunt2.key` present in both vhunt2 zips (CRC 61306b20), `qsound_hle.zip`
  present (`dl-1425.bin` CRC d6cf5ef5).

## Decisions made

- **M2b-CORE FROZEN at fingerprint
  `71601263474dfd7e4afd0741dae696cde22eda4e`** — 2026-07-28, maintainer
  ("freeze core deliverables"). Scope: Donovan's sprites, palettes, and
  effects living in Jedah's gfx space — playtest-clean (rounds 4-6) and
  fully gate-verified (M2b gate incl. 40K marathon + masked legacy with
  unchanged flicker inventory; oracle; dual-emulator; flavor; scroll3
  exclusivity live-measured). Registry row `71601263 -> donovan-m2b`
  (gfx member sha1s in the registry note — the program fingerprint does
  not cover them). Deliberately OUT of the core freeze: select-screen
  big portrait/name banner/mugshot (still Jedah's; pipeline mapped,
  in-place pointer surgery pending), attract palette path,
  engine-effect tail. Those continue as follow-up work.
- **M2a FROZEN at fingerprint `a02aeefff4c7a053337b10c923c8c328573788fa`**
  — 2026-07-28, playtest-gated as decided: maintainer's round-3 playtest
  came back fully clean ("no more graphical bug/crash, even over
  multiple matches"; "no more music trigger from inputs"). The M2a bar
  (Donovan selectable, crash-free, behavior observable, R1 logged) is
  met; graphics deliberately garbled (M2b), Donovan's own sfx
  deliberately silent (M5, 25 stubbed rows + the 0x271B6 dispatcher id
  table recorded in reconciliation.toml). Registry row + suite
  expectation kinds landed the same day (session 14 highlights).
- **Legacy-gate basis for hooked builds = live-RAM (masked windows)** —
  2026-07-25, maintainer approved ("the invariant interpretation reads
  sound and reliable which is paramount"). For builds carrying engine
  hooks, legacy comparison masks exactly `RAM:$FF043C` (QSound handshake
  phase latch) and `RAM:$FF7F00-$FF7FFF` (dead stack below resting SP);
  every other byte compared every frame (confinement by construction).
  CLAUDE.md §4 amended; windows documented in docs/atlas/ram.md; masked
  vanilla expectations frozen under tests/expected/vsavj/masked/ (this
  session). Suite-runner masked-expectation-kind support lands with the
  stage-5 freeze. New masked windows require the same route: measured
  mechanism + atlas entry + maintainer sign-off.
- **Ported-Donovan default flavor = VS2** — 2026-07-27, maintainer
  ("Default should be VS2, as you proposed"). Implemented as a tunable
  in `build/manifest/donovan.toml` (`[init_shim] flavor_disp=0x3C2,
  flavor_default=0x01`, rule-5 style): the init shim writes the flavor
  latch into the initing player's struct (A6+0x3C2) — vsavj never writes
  it; the ported QCB+K handler + projectile consume it. Verified live:
  P1 $FF87C2=01 in-match on the flavor-defaulted build. Start-hold
  selector wiring (clear-to-00 on held Start) = stage-5 select-plumbing
  scope, §3.3/§3.4 variant policy (Donovan + Huitzil only).
- **Legacy-gate v2 refinement APPROVED** — 2026-07-27, maintainer
  ("I'd rather we iterate with as tight setups as we can build rather
  than try to be perfect and not go forward"). Per-replay classes on the
  masked basis: exact (02/05/07), flicker-tolerated 03/10/16
  (`tools/compare_flicker.py`, stretch ≤2 / re-converge ≥60 / total ≤8),
  frozen diverge constants 06@700, attract@4278, pick@1080. CLAUDE.md §4
  updated to v2. **Standing watch (maintainer caveat): if flickers grow
  beyond the frozen inventory (5 frames across 3 replays: 03@829+2093,
  10@3007+3129, 16@829) or divergences turn systematic, stop and
  root-cause — that would indicate a deeper issue.** The tolerance caps
  themselves fail loudly on growth; treat any new flicker frame as a
  finding to attribute, not noise to absorb.
- **M2 replaced slot = Jedah (slot 0x0F)** — 2026-07-25, maintainer
  approved. Donovan replaces Jedah in vsavj for the proof-of-life
  milestone. Rationale: footprint fit (Jedah 10018 B ≥ Donovan 9358 B),
  boss character (least playtest disruption), keeps Demitri/Victor so the
  M1 replay suite stays valid.
- **CLAUDE.md §4 dual-emulator amendment** — 2026-07-25, maintainer:
  new-content cross-emulator verification is field-level at sync anchors
  (mapped gameplay state), not whole-RAM frame-exact; within-emulator
  oracles stay whole-RAM frame-exact. Text updated in CLAUDE.md §4.
- **Project name = "Vampire Saved"** — 2026-07-25, maintainer.
- **Base revision = `vsavj` (Japan 970519)** — 2026-07-24, maintainer. Closed.
- **Checksum manifest is per-member**, so zip repackaging never matters —
  2026-07-25, session decision (mechanical, no gameplay impact).
- **Raw-image byte-order convention** — 2026-07-25, session decision: ROM
  files are LE-word storage; all derived images are 68k logical (BE) order.
  See docs/GOTCHAS.md first entry.

## Decisions pending (human)

- **ROSTER ACCESS MECHANISM (M4-defining, raised by maintainer
  2026-07-28):** how players select the 18 characters. Option A: full
  select-screen redesign (new wheel/cursor/portraits — priced by the
  session-14 select-web archaeology as a milestone of its own, highest
  UI-regression surface). Option B: combined-input slot sharing — hold
  Start on a host slot selects the guest (engine-native precedent:
  Oboro Bishamon is exactly this pattern in vanilla; source-game
  precedent: vsav2/vhunt2 gate Donovan/Huitzil behind Hold Start +
  button, community-confirmed; mechanism = generalize the existing
  Start-hold latch + bank repoints to host/guest per-slot switching).
  RECOMMENDATION: B, phased — access first, select-screen indication
  (mugshot/name swap while Start held) as polish; A stays possible
  later. Host/guest pairings = maintainer/community choice. Orthogonal:
  3 extra characters' art needs gfx space beyond freed-Jedah either way
  (the M3 expansion question).
- See SPEC §7 for the rest. Nothing blocks current work.

## Open bugs

None.

## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
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
