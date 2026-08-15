# patch_notes — per-change detail: every byte, and why

## 14z-84 — Phobos' own Dark Force palette block (huitzil-m5 -> m6): byte detail

**Why (maintainer pull-forward, design ratified 2026-08-13):** the proper
fix the 14z-79 withdrawal deferred. His DF was purple because table
`0x02A8A4` row 0x10 ALIASES row 0x00 — Bulleta's routine (0x2A8EE),
which requests HER seq ids `0x1E + step + side*4`. vs2's own row 0x10 is
the bare default; his native gold arrives by a vs2-only path (ids
0x5A5-family reaching 0x3ABEDC through the vs2 resolver's SIGNED lea
wrap below its base 0x3B0A3C — an addressing subtlety worth keeping).

**`code_word df_seq_entry_10`** — 2 bytes: table row 0x10's word
(`0x2A8C4`) `004a` -> `0032`, pointing dispatch at `0x2A8A4+0x32 =
0x2A8D6`. MUST be a code op: the dispatcher reads the table
PC-RELATIVELY (opcode view). The first attempt used aux_poke (data
view); the stored 0x0032 DECRYPTED to 0x56EA — a wild jump and a
watchdog reset on his first palette tick, caught by a boot-screen
capture at f3420 and a byte read of the built image.

**`site_thunk df_gold_variant_id` site** — 6 bytes at `0x2A8D6`
(`004000e40124` = rows 0x19-0x1B's alias words -> `jmp <thunk>`). Those
slots are indexable only by ids 0x19-0x1B, which no track produces
(audit_id_writers; id guards refuse 0x12/0x18; roster = 0x10/0x11/0x13).
Reviewed shared-surface writes (shared_writes.toml, H count 59 -> 62
incl. the 14z-82c hitclass backfill this review surfaced).

**The thunk body** — 0x54 bytes in hole_a: Bulleta's routine TRANSCRIBED
(the beam_list_type6 discipline) with exactly: far pc-rel branches ->
abs `jmp/jsr 0x2ADAC` (the vanilla changed-path); the `0x2A7E0` skip ->
a local rts (that target IS rts); the base add `addi.w #$1e,d0 /
bra 0x2AD82` -> `lsl.w #5,d0; movea.l #gold,a0; adda.w d0,a0;
jmp 0x2AD3C` — the resolver's own computation against OUR block,
entering the shared uploader exactly as every vanilla requester does.
No funnel thunk (the 0x2AD44 never-thunk rule; a resolver compare is
the 14z-64 permanent-phase class), no resolver-window write (the window
has ZERO padding — measured).

**The gold block** — 0x100 bytes placed in wide_ext via `data_subst`:
vs2 `0x3ABEDC` (P1 rows) + `0x3ABF5C` (P2 rows — the `$381(a6)` side
term), vh2 twin `0x38BEB0+0x100` byte-identical (the sibling oracle).

**Gates:** `test_variant_dispatch` GREEN for the first time since 14z-74
(the designed-row licence is exact: only 0x0032 at that row passes);
`tenant_loop` re-frozen 265/443/597 (+4 H ops); screen captures — Phobos
GOLD in DF, Bulleta still purple on the same build.

## 14z-83 S3 — the beam-strip relocation (huitzil-m4 -> m5): byte detail

**Why (maintainer-approved 2026-08-12):** the S0 merged group-C census
(`tests/audit_gfx_merged_census.sh`) found the strip's dst `0x5EA0-0x5FBF`
(288 codes, vs2 group-A source) sitting inside PYRON's native band (vs2
group-B source, different bytes) — the ONE real collision in the whole
3-tenant merged write set. Purely a placement change: tile indices have no
gameplay surface.

**`strip_tiles/0x10.json`** — `shift` `0x1000` -> `0x3800`; dst becomes
`0x86A0-0x87BF`, the head of ratified free pool 1 (16-aligned, so the
type-4 handler's within-row column wrap is preserved; pool measured empty
by the census).

**`beam_list_type6.thunk_hex`** (huitzil.toml) — SIX BYTES:
`addi.l #$52000000,d1` -> `addi.l #$7A000000,d1` (the ported type-4
handler's code bias = vs2's 0x4200 + the shift; the shift and the bias
must move together — `tests/test_beam_list_type6.sh` 1b reconstructs the
handler from vsavj `0x01B61A` + exactly these two constants).

**`gfx_layout3.toml`** — `[[strip]]` row added (the ledger was blind to
side inventories — how the collision shipped unseen for ten sessions);
free pool 1 split `0x8648-0xA42B` -> `0x8648-0x869F` + `0x87C0-0xA42B`.

**Gates moved with it (same commit):** census expectation flips to ZERO
real collisions (old shift kept as the must-fire fixture, controls B/C);
`test_gfx_chain.sh` section 4 flips to FULL 3-tenant chain success
(old-shift fixture keeps the must-fail); `test_gfx_layout3.sh` gains the
strip/extras/pool-honesty locks. New fingerprint
`38188bb12dd6b971a4067b89edaad54eabbfe343` = huitzil-m5.

## 14z-71 — the beam: byte detail

**`code_ptr beam_effect_class16`** — 4 bytes at vsavj `PRG:0x080AEC`,
emitted as a `code` op (the effect-class table is read pc-relatively, so
through the OPCODE view). Old value `00080B44` — the bare `rts` after the
table, i.e. vsav ships row 16 as a STUB. New value = the placed address of
region `x093460`, the ported vs2 row-16 handler family. Effect: the beam
object, which already selected class 16 at the same frames as native, is
dispatched into a real handler instead of a no-op. Legacy-inert: row 16 is
never read by vanilla (0 reads across the frozen suite vs a 1760-hit
control on row 37).

**root `0x93460:0x306:t0x9306c:f`** — the row-16 handler family, bounded
at the family exactly (its head, its type table, the state machine that
selects the beam anim, the helper at `0x93550` and its 196-entry
sub-table), ending on the `rts` at `0x93764`. Twin = vhunt2's own row-16
entry. Six bytes forced past the oracle stop (`:f`), hand-verified
sibling-identical and pointer-free.

**`site_thunk beam_list_type6`** — 6 bytes at vsavj `PRG:0x01B6AA`
(`3a18be456500` -> `jmp <thunk>`), plus a 0x102-byte body. vsav's drawer
has six sprite-list types, vs2 seven; the beam's list is TYPE 12, a
composite. The table cannot grow (entry 0's offset IS its length) or move
(`(d8,PC,Xn)`), so the port takes over vsav's UNUSED type 6.
Body layout: a placed-region range gate; then vs2's composite handler
(`0x01A1FC`) verbatim bar six scratch displacements and a local `bsr`;
then a tripwire + a faithful reproduction of vsav's own type-6 head
rejoining at `0x01B6B2`; then a child dispatcher; then a ported type-4
handler.

**the ported type-4 handler** — vsavj `0x01B61A` verbatim, 0x90 bytes,
with exactly TWO constants changed:
`ori.w #$2000` -> `#$1000` (it composes its own gfx bank; H's art is in
WIDE group C bank 4) and `addi.l #$38000000` -> `#$52000000`
(**vsav biases tile codes +0x3800 where vs2 biases +0x4200** — one byte, in
otherwise byte-identical routines — plus our 0x1000 placement shift).
Without the bias change the strip addressed tiles 0x0A00 low and drew the
freeze/reflection art.

**39 `port_patch` rows** — the type word of each composite list in region
`anim`, `000C` -> `0006`. Each row names its address and asserts the
vanilla word.

**`strip_tiles/0x10.json`** — gfx only: vs2 BANK-1 tiles `0x4EA0-0x4FBF`
copied into group C bank 4 at `+0x1000`. A SPAN, not a sample. Not placed
into vsav's own bank 1, which is measured 160-of-240 occupied at those
codes.

Full rationale: `porting_sprite_lists.md`. Facts:
`../game/atlas/sprite_lists.md`.

## 14z-70 — byte detail

**`extra_tiles/0x10.json` 2 -> 569 tiles** — the 214+P grenade's GROUND
detonation. Codes were remapped bank 3 -> 4 but the tiles were never
copied, so it drew a solid fuchsia rectangle. gfx members only; the
program is unchanged from hui15/16. Reproduce only with
`tests/replays/hui/83d_hui_grenade_ground.rpl` (214+LP, both fighters
cornered) — every earlier rig hit the opponent and photographed the
on-contact explosion instead.

**root `x088512` 0x3B40 -> 0x3B98, `:f0x3b78`** — three pc-relative tables
sat past the old bound and resolved into the ANIM region placed
immediately after (`0x0D8988/98/A0`), so the machine read animation bytes
as its parameters. A real latent repair with no observable effect today
(the code that reads them does not run in any current scenario).

## 14z-69 (session close) — byte detail

**`data_port df_palette_seq_rows`** — **WITHDRAWN 14z-79.** Rows
0x1E-0x21 are BULLETA'S Dark Force block, not free space: she requests
them 236 times in one DF (measured, vanilla). This row rendered a legacy
character wrong on every Huitzil build from 14z-69 to 14z-79 and is now
commented out in the manifest. The claim below ("legacy never requests
these ids") is RETRACTED — the audit that produced it ran replays in
which DF cannot activate. Original text follows.

0x80 bytes at vsavj `0x39ACC0`
(palette-seq rows 0x1E, 0x1F, 0x20, 0x21) replaced with vs2 `0x3ABEDC`
(vh2 twin `0x38BEB0`, byte-identical, unique). Old head at dst:
`05310fff0e9e0ece0d7e093e064d045c` (asserted by the row). Effect: H's
Dark Force flashes his warm gold ramp instead of a purple one. Legacy
never requests these ids (audited, 10,504 calls, only 0x26/0x27).
[RETRACTED 14z-79 — that audit could not activate Dark Force; Bulleta
requests 0x1E-0x21 and 0x26 is Demitri's own block.]

**`extra_tiles/0x10.json`** — tiles `0x0F8B`, `0x0F8C` added to the
group-C copy inventory. gfx members only: `vsw.31m/33m/35m/37m` change,
the program is byte-identical (hui12 and hui13 share fingerprint
`31d576be`). Effect: the child sidekick's shadow core draws real art
instead of an empty tile.

**region `x06cac0` root `0x6cac0:0xebc:t0x6cc34:f0xca8`** — forced past
the oracle boundary (0xC00) to its declared 0xEBC so the row-8 machine's
seven pc-relative tables sit inside it, with `+0xCA8..+0xEBC` emitted as
RAW data from the SOURCE DATA IMAGE (not from the relocated blob — an
`(An)`-based read is a DATA-space read). All seven tables now read
byte-identical to vs2. Behaviour unchanged so far: the beam still does
not draw.

Newest first.

## 14z-65 (6) — the specials hunt: window widened, alias rule, farm verified (2026-08-07)

Build acda6946 (ladder). Native ground truth (vs2 + the same forced-pick
probe = native Phobos firing Plasma Beams on our exact soak inputs)
proved the port's specials never trigger. The chain so far, each link
measured:
- NEWCOMER_CODE widened to 0x054000 (Donovan-inert, measured): 13 of
  his dispatch rows lived below the old window as unrepointed "veteran"
  rows — Bulleta's aliases served his special dispatches. His code
  region is now 0x54C90+0x27C6 (re-frozen in test_extract_hp.sh; the
  old x055478 root absorbed; layout group now "code,x057456").
- 18 farm rows content-verified at the correct 8-byte record
  granularity (the 16-byte compare crossed into neighbor records — a
  false MISMATCH; and params must be read via the DATA view, the
  opcode view shows decrypt-garble). One new row 0x2910c -> 0x29dd2.
- dispatch_07 alias rule (NEW generator pass): per-char rows exist in
  ENGINE space; when the source game's row differs from its alias-char
  row, repoint via the R1 map. Huitzil: 0x23AFE -> vsavj 0x24EA4
  (hand-verified twin, GOTCHAS).
- FRONTIER, precisely bounded: predicate consultation parity is EXACT
  (401 hits native = 401 ours on the same entry over the same soak);
  the state-byte tap still shows the port writing NO nonzero states
  while native writes 0x06/0x16. The divergence is INSIDE or AFTER the
  predicate match: next instruments are the predicate common's verdict
  path and the input-history feed the matcher reads — and first,
  verify WHAT native writes those states (special launch vs reaction).
All gates green (m3a reproducible, ladder, boot, extraction shapes
re-frozen).

## 14z-65 (5) — HUITZIL BOOTS: first match on the vsavj engine (2026-08-07)

Fingerprint 9252ce62 (stage-4 ladder build; not a frozen reference). The
forced-pick probe loads HIS hitbox base (0x3EC840), the guard is clean
over the full run, a live match renders (sprite-garbled body — correct
for this rung: no gfx stage yet — vs a working CPU opponent), and the
legacy replay stays bit-identical. Three fixes, each measured:

1. THE FALL-THROUGH LAYOUT GROUP (the watchdog-reboot root cause): the
   sibling-insertion boundary at 0x57456 splits his dispatch_00 handler
   MID-ROUTINE — region "code" ends with the aux jsr and the handler
   body is x057456's head. Placed apart, the post-jsr fall-through
   executed alloc padding + the next region's bytes; the machine
   wandered and watchdog-reset (GOTCHAS: reboot masquerades as clean
   non-load). huitzil.toml [[layout_group]] "x055478,code,x057456"
   restores source-relative spacing.
2. [init_shim] (pool-seed + flavor latch, flavor_default=0x01 per
   provisional D1) — the Donovan mechanism with engine-fact parameters.
   Necessary by design; measured NOT sufficient alone.
3. FIVE stubbed_sound ROWS (ids 0x72a/0x73c/0x743/0x749/0x74a -> the
   engine rts): his init's first act is enqueueing voice sfx whose
   vsavj same-id entries key DIFFERENT music-class content (QSound
   key-on records — the ids sit BETWEEN the documented music ranges, so
   this was measured, not assumed). First tripwire hit: 0x4e78 at f2887.

NEW gate tests/test_hui_boot.sh (build + probe-loaded-base read from the
build's own patch.json + guard clean + legacy bit-identity) — in the
session's gate set with extract_hp/hui_ladder/m3a_reproducible, all
green. 18 tripwired targets remain for the guarded-soak frontier.

## 14z-65 (4) — Huitzil stage 4 BUILDS; the R1 frontier enumerated (2026-08-07)

Stage 4 (code + engine hooks) builds clean at fingerprint 94f89571 with
the remaining surface fully enumerated. The arc, each step measured:

- pcrel16 both sides fixed (see the 14z-65 (4) commit before this one):
  classifier requires a real PC-relative opcode; generator rewrites true
  displacements against placement.
- Huitzil roots (driver census, 14z-65): 0x55478 (engine-consumed
  routine below the window); the 18-ring velocity-vector family
  0xd143e+0x900 (vs2-only bank data, structure-bounded — radius-indexed
  sin/cos rings, 0x80 B each); the SHARED newcomer-support zones from
  Donovan's census (0x5c800/0x26142/0x28122/0x88512) — his handler-head
  `jsr $8ACD8` resolves INTO the shared source-only zone (mystery
  closed: his aux init lives there).
- x088512 is 0x3B40 for H, not Donovan's 0x2f00: his copy chains
  dispatch tables past the old bound; the transitive closure of the
  zone's pcrel escapes converges at +0x3B3E (6 rounds, measured with
  the extractor's own table-walk rules).
- NEW generator mechanism: pcrel FAR TRAMPOLINE (a pcrel word-table
  entry resolving beyond d16 reach bounces through a near jmp abs.l;
  cached per target; Donovan-inert — the branch was a hard fail before).
  Ended up UNUSED for H once the zone extent was fixed, but it is the
  correct fallback and stays.
- R1 rounds: reconcile_batch x2 into the global map — 50 of H's first
  101 engine targets were ALREADY mapped from the Donovan era; now 219
  rows kept, +49 verified for H across both rounds. Tripwires: 57 ->
  17 -> 36 (zone growth) -> 23.
- The 23 remaining tripwired targets classify into: the companion
  family (0x2b7ef4/0x2b8060/0x36784a — leave tripwired until guarded
  runs prove H's flows reach them), the sound-farm neighborhood
  (0x4ddc/0x4e5e/0x4e78/0x4f48/0x4f96 — needs the M5-style farm triage,
  NEVER blind-resolved), and 15 per-target R1 items (engine subs
  0x4223c/0x42cee/0x448d4/0x3844e + mid-ROM data refs).
- All gates green after every step: extract_hp, hui_ladder,
  m3a_reproducible (Donovan bit-exact throughout, including through two
  global-map rewrites).

## 14z-65 (3) — the Huitzil stage 1-3 ladder opens (2026-08-07)

The single-tenant machinery now serves any tenant manifest; Huitzil climbs
the same falsifiable ladder Donovan's M2a did, at his native variant id.

- `build/manifest/huitzil.toml` (NEW): minimal by design — [[tenant]]
  (huitzil, vsav2 0x10, id 0x10 — variant-id only, every build requires
  --profile) + the three-space model. Stage 4+ rows land only as measured
  for HIS mechanisms; donovan.toml is reference, not template.
- `tools/build_donovan.sh`: TENANT_MANIFEST/TENANT_CHAR selection
  (defaults = Donovan, byte-for-byte); DEFAULT_ROOTS is per-char (his
  census applies only to 0x13; Huitzil's census OPENS with 0x55478 — his
  tail_code_ptr row's engine-consumed routine, appended newcomer-support
  code BELOW the 0x57000 window: the appended zone reaches 0x054xxx,
  measured); `${EXTRA_ROOTS-...}` (unset-only default) so an explicit
  empty means "no roots"; stage >= 6 for a non-Donovan tenant is refused
  loudly (his gfx constants).
- `tools/gen_donovan_patch.py`: the stage-1 scaffold's hitbox repoints
  emit ONLY at stage 1 — at stage >= 2 the passive-data pass owns those
  rows. The overlap assertion caught this on Huitzil's first stage-2
  build (scaffold + real repoint on hitbox_base[0x10], by-design
  last-write-wins in the M2a era). The scaffold COPY still emits at
  stages 2-3, so their allocator layout and final bytes are unchanged
  (the removed pokes were overwritten by identical-final-value ops).
- Ladder measured green (`tests/test_hui_ladder.sh`, NEW): stages 1-3
  build (05edf96f/ba516bd1/c0910a0e); THE OP INVARIANT — every op writes
  free space or a variant row (0x10-0x1F) of a bank-map table, i.e. the
  superset invariant checked per op — holds at all three stages; a
  legacy replay on stage 3 is BIT-IDENTICAL to the frozen vanilla
  expectation (whole-RAM, unmasked).

## 14z-65 (2) — M3b Phase 1: extraction de-Donovanized (2026-08-07)

ZERO byte drift again (`test_m3a_reproducible.sh` PASS after every edit).
Both new tenants now EXTRACT, oracle-validated (`tests/test_extract_hp.sh`
freezes the shapes). Tool changes:

- `tools/extract_char.py`: per-(src_set,char) `CHAR_ANCHORS` (measured
  rows for 0x10/0x11/0x13; a char with NO row is refused — unanchored
  extraction was a silent-drift hole); code-region bounding groups
  dispatch targets by their own pair delta (piecewise window shifts,
  see the atlas section); `oracle_extend` gains the flow-out-gated dead
  filler rule (`filler_dead`, code regions only — a failing chunk is
  tolerated ONLY as one short run after an unconditional flow-out in
  both images that re-diffs clean when masked); sibling-insertion
  boundary resolution (strict probe: matching opcode word + zero
  unexplained) with `ins` zones excluded from diff-ref classification;
  wall-precise tail for coverage-failing floor scans. Donovan's single
  group degenerates to the old behavior byte-identically (proven by the
  gate, not just argued).
- `tools/scan_code_refs.py`: charid immediate scan parameterized on the
  source char (was literal 0x0013 — any other tenant's id sites were
  silently missed); `tools/gen_donovan_patch.py` rewrite side follows
  `src_char`.

Measured facts of record: Huitzil's vs2 handler head carries a 6-byte
`jsr $8ACD8` ABSENT in vhunt2 (undecoded; decode at his port); Pyron's
window is uniform +0x30 with one 12-byte junk-filler run at
`PRG:0x0576F4`; H's +0x30 region contains a `cmpi #$10` charid site in
the SHARED stretch (Phase 2 tenant-attribution hazard, atlas note).

## 14z-65 — M3b Phase 0: op-overlap assertion + tail_data_ptr ownership (2026-08-07)

ZERO byte drift — both frozen references rebuild bit-exact
(`tests/test_m3a_reproducible.sh`: WIDE 4b7d0dc7, stock 6c93cfa8). Two
machinery changes and one emitted-patch change:

- `tools/patch_prg.py`: ops now hard-fail when two write one word, naming
  both ops and the clash address. Word granularity is deliberate — the
  generator's odd-aligned byte pokes merge PRISTINE neighbor bytes, so a
  shared word means the later op resurrects vanilla bytes over the
  earlier write. Ground truth `tests/test_patch_overlap.sh` (2 accepts,
  2 named rejects).
- `tools/gen_donovan_patch.py`: explicit-ownership claims — a
  `[[sound_table]]` row that WILL emit (same stage/profile gating as its
  section) suppresses the generic value-row repoint for its `ptr_table`.
  On WIDE builds both wrote PRG:0x0BF466 (`tail_data_ptr[0x13]`): the
  generic pass pointed it into the relocated hitbox closure (vs2's raw
  sfx records, music ids included), the sound section then overwrote it
  with the id-allowlisted array at 0x400E60 — correct shipped bytes by
  emission order alone (docs/GOTCHAS.md 14z-65). The WIDE patch now
  emits 243 ops (was 244; the dropped poke32 was always overwritten).
  Stock builds are untouched: sound_table is profile-gated off there, so
  the generic repoint still serves rows 0x0F/0x1F.
- `tests/test_m3a_reproducible.sh`: the M3b Phase 0 gate — the frozen
  references must rebuild bit-exact from the tree after every
  machinery commit of the milestone (scratch builds; canonical dirs
  untouched). Written here as a PAIR; extended 14z-76 to **all four**
  (m5_stock, donovan-m3a, huitzil-m2, pyron-m2).

## donovan-m2 stage 5 — the last two music triggers: engine_data masquerade rows (2026-07-28, playtest round 2)

Fingerprint a02aeeff… (supersedes eda50a18). Playtest: 214P/214K still
triggered music after the caller-zone reclassification. Cause: two
sound-farm entries never appeared in the farm inventory because the
session-5 bare-long byte-matcher had already mapped them as generic
`engine_data` — and codebytes-unique matching locks onto the vsavj entry
carrying the SAME ID BYTES, the exact same-id-different-meaning trap.
vs2 0x4F14 (sfx 0x2D4 → vsavj 0x4A5E) and vs2 0x5052 (sfx 0x173 →
vsavj 0x4316), both called from x088512 (special/projectile support —
the 214 path). Confirming detail: 0x5052's id 0x173 is the id whose
OTHER caller (0x43B2) the previous build stubbed — one trigger vanished,
this one stayed. Also stubbed by the same mechanism-audit: vs2 0x5122,
the sound HELPER itself, direct-called by a table-driven dispatcher at
vs2 0x271B6 (x026142) that forwards vs2-semantic ids — wrong by
construction; at M5 the dispatcher's id table needs translation, not the
helper. Full static audit of every farm-range ref (jsr/bsr/jmp/pea) from
ported zones: 25 stubbed (ids recorded — the M5 list), 4 live-mapped,
all init/system-zone (playtest-clean). All gates green; flicker
inventory unchanged.

## donovan-m2 stage 5 — move-sfx reclassification (2026-07-28, playtest-driven)

Fingerprint eda50a18… (supersedes 372b0641). Playtest on the crash-free
build: some specials (e.g. 421P, 214K) deterministically triggered MUSIC
— the session-12/13 sound-farm rows matched vsavj entries BY SOUND-ID
NUMBER, which is only valid where the two games agree on that id's
meaning. Donovan's move-sfx ids collide with vsavj music/other triggers.
Reclassification by CALLER ZONE: the 14 farm entries called from
x05c800 (his move-handler support zone) are MOVE sfx → stubbed to rts
(kind stubbed_sound, ids recorded — the M5 restoration list is now 22
ids); the 4 called from init/system zones stay mapped (stock chime
0x172, init-time 0x115/0x10A/0x1D5 — consistent with no music at round
start). All gates green; soaks END-clean; flicker inventory unchanged.

## donovan-m2 stage 5 — shared-table remap: mash/time crash fix (2026-07-27, session 11b)

Fingerprint cdf62d8c… (supersedes d6d8f273). Playtest round 2 found a
crash on heavy input activity (mash soak repro: 21_don_mash, vec3
@0x1AFB2 frame 3219): the type-114 effect's ported creation code loads
an ENGINE-SHARED anim word table via `movea.l #$1D7428` — un-hosted by
any ported region and previously carried raw (VS2-space pointer on
vsavj). Changes:
- extractor: un-hosted `movea.l #imm,An` ROM targets are now ENGINE refs
  (R1 row or loud tripwire; `move.l #imm,Dn` stays hosted-only —
  constants must not fabricate refs). Retires the manual imm_poison for
  0x36784A (auto-tripwired at 0xC29E0 now — same loudness, one
  mechanism).
- reconciliation: engine_data row vs2 0x1D7428 → vsavj 0x1F3FD2 (same
  shared effect anim table; unique 24-byte content match).
Verified: 21_don_mash (14120 frames of input chaos incl. Start taps,
across the round boundary) and 20_don_round2 (idle through round
transition) both END-clean; both join the code gate's guarded set
(4 guarded replays now). Full battery re-run on cdf62d8c (see STATE).

## donovan-m2 stage 5 — reaction_hook: ES-DP crash fix (2026-07-27, session 11, playtest-driven)

Fingerprint d6d8f273… (supersedes 4b65bc63 as the freeze candidate).
The maintainer's DP-spam crash, reproduced deterministically
(19_don_dp_spam, vec4 @0x18498 frame 3711), was the defender-side
hit-reaction dispatch — a third extended brief-word engine table (vsavj
0x18460/0x18468 ~81 ids; vs2 0x16D2C/0x16D34 adds ids 0xA2/0xA4/0xA6;
ES DP inflicts 0xA2). Fix ([reaction_hook] in donovan.toml + generic
emitter):
- 3 case stubs synthesized VERBATIM from config hex (position-
  independent vs2 one-liners on A1/A3; VS2 provenance), extended long
  table (GEN), 50-byte thunk (GEN).
- Ghost-clean: the preceding `tst.b ($38,A1); bne $18508` pair (8 B at
  0x18458) becomes `jmp thunk`; the thunk re-creates tst/branch
  (beq.s + jmp abs), range-checks D0, dispatches extended ids via
  `jmp (A0)` (cases rts to the dispatch's caller), vanilla ids jmp back
  to the UNTOUCHED original dispatch at 0x18460 — zero pushes, CCR
  semantics preserved.
Coverage additions: 19_don_dp_spam joins the code gate's guarded set
(ES two-button versions were never exercised before — the gap the
playtest found); 04/08/09 restored to the masked legacy gate as flicker
class with frozen masked vanilla logs (they'd fallen out at the v2
rebuild). Playtest finding 3 (4-option select) refuted as a port
artifact: vanilla shows the identical menu on factory EEPROM.

## donovan-m2 stage 5 — Start-hold flavor selector + alternate-table poison (2026-07-27, session 11)

Stage-5 build (fingerprint 4b65bc63…, `tools/build_donovan.sh 5`):

- **Start-hold flavor selector** (init shim 32→68 bytes, GEN): after
  seeding the VS2 default (01) into the initing player's flavor latch
  (+0x3C2), the shim tests the per-player Start bitmask at `RAM:$FF8060`
  (bit 0 = P1 Start, bit 1 = P2 — measured: live through char-init,
  where the menu-context mirror +0x44 is already cleared) and writes 00
  (VH2) when the player's own Start is held. `cmpa.l #$FF8400,A6`
  selects the bit; all added ops are CCR-only — no register clobbers
  before the handler. Tunables in donovan.toml `[init_shim]`:
  flavor_default / flavor_held / flavor_hold_flag. UX matches the
  community-confirmed vs2 protocol (hold your Start from before the
  confirm press through match load).
- **imm_poison mechanism** (generator) + first use: the companion tail's
  unreachable alternate-anim-table operand (`movea.l #$36784A`, taken
  only when the spawn-record sub byte ≠ 0 — Donovan's hook always writes
  0) is repointed at a 16-byte GEN poison table (odd-value words): any
  future writer that makes the branch reachable faults vec3 with A0
  naming the poison block, instead of silently reading unrelated vsavj
  bytes.
- **aux_poke survey result:** none needed for the M2a bar — pick/select
  behavior already works via the bank repoints; portrait/name are GFX
  (M2b, placeholder-acceptable); the attract's CPU demo on slot 0x0F
  runs crash-free every legacy-gate build.

Verification on 4b65bc63: guarded moveset END-clean (9320); masked
legacy gate green (flicker inventory unchanged); oracle gate PASS;
dual-emulator gate PASS (anchors 2363/2364); NEW
`tests/test_m2a_flavor_selector.sh` PASS (plain→01, P1-held→00,
P2-held→01 — per-player isolation). Freeze (registry row + suite
masked-expectation kind) awaits the maintainer's build decision.

## donovan-m2 stage 4 — damage-pipeline R1 rows; BOTH GATES GREEN (2026-07-27, session 10)

No new ops — three R1 rows (reconciliation.toml) turned three tripwires
into real calls: vs2 damage trio 0x17522/0x17422/0x17B22 → vsavj
0x18B8C/0x18AB0/0x19128 (defense-scaling calc / damage post-process /
KO handler), callsite-anchored in the byte-parallel damage wrapper
(vs2 0x17330 ↔ vsavj 0x189BA; found via the KO-write signature). Plus
two pool-family rows (0x15744→0x16FFC, 0x1581A→0x170D2, skeleton-match
at +0x18B8). Donovan now uses VSAVJ's own damage machinery — correct
superset semantics (mapped, never ported, per the allocator rule).

Build fingerprint 67753ee3: `tests/test_m2a_stage4_code.sh` PASS (veto
lock; moveset replay END-clean 9320 frames — real state machine +
VS2-flavor QCB+K + damage pipeline; masked legacy green, flicker
inventory unchanged) AND `tests/test_m2a_stage4_oracle.sh` PASS
(anchors 2363/2363; neutral exact; HP trajectories equal 288,277,266;
comparative bound 890 ≤ 2379). First all-green stage-4 run.

## donovan-m2 stage 4 — +0x14E state hook, sound stubs, anim_index_a2 (2026-07-27, session 9)

- **state_hook** (donovan.toml `[state_hook]`, all GEN except records):
  site 0x02A7C8 first 6 bytes → `jmp thunk`; thunk (50 B, hole A):
  vanilla ids (< 0xB2) jmp back to the untouched `move.w (0x12,PC,D0.w),
  D1; jsr (0xE,PC,D1.w)` — ghost-clean; ids 0xB2-0xC8 dispatch via a
  12-entry long table to synthesized case stubs (32 B each: cmp.b
  +0x14F; beq→jmp 0x2A7E0 rts; clr.b +0x181; clr.w +0x182; move.w
  #0x2CD+k,D0; moveq #1,D1; jmp 0x2AD94). D0 preserved through the thunk
  (stubs compare it). 12 palette-seq records (vs2 0x3B63DC, 0x180 B,
  vhunt2-twin byte-identity asserted at build) placed as raw data; the 4
  seq-table consumers (0x2AD82/0x2AD94/0x2B342/0x2B7E8) each get a 30-B
  base-swap thunk (`movea.l #0x39A900` is exactly 6 bytes → jmp; ids
  0x2CD-0x2D8 → record base swap; no pushes; andi.w follows every site
  so CCR is dead). Provenance: GEN thunks/stubs/table, VS2 records.
- **8 sound-farm stubs** (reconciliation.toml kind=stubbed_sound): vs2
  sfx calls 0x4DF6/0x4E2A/0x506C/0x5086/0x50A0/0x50BA/0x50D4/0x50EE →
  vsavj rts 0x2A7E0. Silent until M5 (sfx ids recorded per row).
- **anim_index_a2** (bank_map): gap_bcefa reclassified data_ptr/anim
  (fourth anim/box-setter table, consumer 0x27EB8); rows 0x0F/0x1F →
  0x000D51BE (vs2 0x281696 relocated). Was feeding Jedah's anim-index
  row to Donovan's attacks.

Verification: moveset replay END-clean (9320 frames); oracle neutral
window exact ×1100 frames; battery HP trajectories equal; comparative
bound vs veteran control passes (890 < 2379 — the residual 1-frame skew
is the two ENGINES' action-latency difference, proven by the control).
Gate: tests/test_m2a_stage4_oracle.sh.

## donovan-m2 stage 4 — dispatch_14 repoint (2026-07-27, session 8)

Two new poke32 ops: rows 0x0F and 0x1F of the per-character CODE dispatch
table at `PRG:0x0BD7FA` (formerly bank_map "gap_bd7fa", kind auto —
consumer now disassembled: engine 0x026244 `movea.l (tbl,id*4),A0; jmp
(A0)`, the per-char idle/system-state routine) → `0x000C0D74`, the
relocated copy of vsav2's Donovan handler 0x5AB64 (inside the already-
ported code region — no new space). Until this, vanilla JEDAH's routine
at 0x529B4 ran against Donovan's data on every idle frame. Found by the
new vsav2-as-oracle field gate (p1_box_ids disagreed at intro-end);
after the fix the 1100-frame neutral-idle comparison agrees on every
field. Extractor change: dispatch tables enumerated from the bank map
(was hardcoded range(14)). Provenance: repoint = GEN pokes; the handler
bytes were already VS2-ported. Full narrative:
docs/project/tables/reconciliation.md "Session 8".

## donovan-m2 stage 4 — VS2 default flavor via the init shim (2026-07-27)

The pool-seeding init shim (behind dispatch_00[0x0F]) grows 26→32 bytes:
after the pool-seed branch it now writes the VS2/VH2 flavor latch into
the initing player's struct — `move.b #$01, $3C2(A6)` — before jumping to
Donovan's relocated handler. Both values are manifest tunables
(`[init_shim] flavor_disp / flavor_default`, donovan.toml). Why: vsavj's
engine never writes +0x3C2; Donovan's ported QCB+K handler (vsav2
0x5A654) and its projectile (0x65FE6) read it (0x01=VS2, 0x00=VH2 —
community-confirmed Start-hold mechanism, docs/game/atlas/character_tables.md);
without the poke the port took the VH2 branch by accident. Maintainer
decision 2026-07-27: default VS2. Verified: P1 $FF87C2=01 live in-match;
the moveset replay now exercises the VS2 branch of QCB+K. Provenance:
GEN (shim), behavior value in the manifest. Attract/legacy unaffected
(shim runs only on slot-0x0F init; masked legacy gate green — see the
gate log for this build's fingerprint).

## donovan-m2 stage 4 — session 7: extraction corruption fixed; ghost-clean hooks (2026-07-25)

Blob-level changes (all via `tools/extract_char.py` regeneration — no ops
added or removed; region sizes and placements unchanged):
- 47 false bare-long rewrites REMOVED from x088512 (44) and x0905ae (3):
  instruction operand pairs (`0006 7000`, `0006 0006`, `0028 3b7c`, …) that
  had fused into ROM-plausible pointers and were being relocated, corrupting
  the ported code. One of these (vs2 0x8A49C `moveq #0,d0`) was the entire
  session-6 crash frontier. Mechanism + new sibling-veto rules:
  docs/GOTCHAS.md, docs/project/tables/reconciliation.md Session 7.
- Real immediate table-base loads (`movea.l #imm,An`, `move.l #imm,Dn`) now
  labeled by scan_code_refs (`movea_imm`/`move_imm`) and relocated through
  the labeled path (host-region membership required).

Engine-hook change (`tools/gen_donovan_patch.py` obj_hook):
- Site patch is now 6 bytes (`jmp thunk` over the movea+moveq); the vanilla
  `jsr (A0)` at site+6 is left byte-identical and the thunk (18 B, GEN,
  hole A) ends `jmp site+6` — so the dispatch push happens at the vanilla
  address with the vanilla return value (ghost-clean; the previous
  jsr-thunk pushed a different return address into the ghost stack).
- Vanilla table rows still byte-identical copies; extra rows unchanged.

Verification (this build, fingerprint 67fa01ec…):
- 12_donovan_vs_cpu (9320 frames) END-clean under -debug guard: no crash,
  no tripwire (previous frontier: vec3 at frame 3025).
- Legacy live-state: 02 bit-identical to vanilla full-length and attract
  first-divergence exactly 4278 under `MASK_RANGES="043c-043d,7f00-8000"`
  (dead-stack window + QSound handshake latch — the only divergence
  sources, both cycle-skew artifacts of hot-path hooks; measured
  impossibility of zero-cycle hooks in docs/GOTCHAS.md). Whole-RAM
  comparison basis for hooked builds: maintainer decision pending
  (STATE.md). Byte-level op lists are generated (never hand-edited): the
authoritative ops for any build come from `tools/gen_donovan_patch.py`
(`build/donovan/patch/patch_notes_fragment.md` reproduces them); this file
records what each patch stage changes and why, at merge time.

## donovan-m2 stage 1 — null relocation (2026-07-25, session 4)

Proves the relocation machinery with ZERO Donovan bytes (any failure is
tooling, not R1). Gate: `tests/test_m2a_stage1_nullreloc.sh` (PASS).

- `PRG:0x0BF6A0 +0x2722` — byte-exact copy of Jedah's player-path hitbox
  block (vanilla `PRG:0x0B0C2E-0x0B3350`, 10018 B — matches the M1-measured
  Jedah footprint exactly), written as raw data INSIDE the encrypted zone
  (proves data-reads-bypass-encryption at the real relocation site).
- `poke32` hitbox_base[0x0F]=`0x0BF7A0`, hitbox_comp[0x0F]=`0x0BF6A0`
  (+ variant rows 0x1F, vanilla-alias asserted) — the +0x60/+0x64 pair
  repointed to the copy.
- `PRG:0x0C1DD0 +6` — `jmp 0x052FCE` trampoline, re-encrypted in hole A,
  behind dispatch_00[0x0F/0x1F]; `PRG:0x3EC720 +6` — `jmp 0x050602`
  trampoline, stored raw above the encrypted range, behind
  dispatch_01[0x0F/0x1F]. Both proven executed (guarded run, no
  exceptions; behavior frame-exact).
- Measured & pinned: slot-0x0F pointer state first lands in RAM at frame
  **2886** of the pick replay (11_pick_donovan .diverge constant); attract
  Jedah demo divergence stays exactly **4278**.
- Provenance: copy = VSAV (byte-identical relocation), trampolines = GEN.
  Build fingerprint `e5e3dc6a76a00cabd38fb3884ff5b160629fc118` (stage
  builds are ephemeral scaffolding — not registered in registry.tsv; only
  the stage-5 freeze registers).

## donovan-m2 stage 2 — passive data (2026-07-25, session 4)

Donovan's hitbox (0x25C2 @ relocated 0x0C1DE0) + projectile-hitbox (0x435A)
blobs injected raw; all per-character value rows poked (params, rec8s,
words, byte, byte2d rows + oracle-classified gap values), slot 0x0F AND
variant row 0x1F (value-table variant rows are dead data in vanilla, poked
unconditionally — the pointer-table alias assert stays). Hitbox pair
repointed to the relocated blobs; Jedah code/anim retained (stage-1
trampolines still on dispatch 00/01). Gate `tests/test_m2a_stage2_data.sh`
PASS: relocated base+comp observed live at $FF8460/$FF8464, full round
(pick to KO/timeout, 9300 frames) completes under guard, -debug window
exception-free, legacy gate green, pick divergence still exactly 2886.
Provenance: VS2. Build fingerprint 4cdf9be9b3b31fa4a26a281bf84f0ad775aac114.

## donovan-m2 stage 3 — anim + sprite sub-tables (2026-07-25, session 4)

Donovan's anim region (0x20F00) + 5 sprite/OBJ sub-table clusters injected
with all internal pointer fields rewritten (3979 fields in anim; cluster
refs by the aux0 delta); the 4 anim-family bank tables repointed (0x0F +
0x1F). Jedah dispatch retained. Gate `tests/test_m2a_stage3_anim.sh` PASS —
no WAIVED-MIXTURE needed: 600-frame idle exception-free under -debug guard,
anim cursor (+0x1C) observed inside the relocated region (15/15 samples),
full round completes, legacy gate green.

Finding (measured, gate constant): the SELECT SCREEN reads the hovered
slot's anim data — with anim repointed, the pick replay's first divergence
moves from 2886 (match init; stages 1-2) to **1080**, the frame the cursor
lands on slot 0x0F. Correct superset behavior (hover involves the modified
slot); explains why 04_select_fuzz/08/09 are in the diverging class.
Build fingerprint e302f16ec3f1e18074acef8b54c3f2b30d378df7.

## donovan-m2 stage 4 — IN PROGRESS (2026-07-25, session 4)

The R1 campaign, mechanized:
- reconcile_batch.py resolves engine targets by: masked pattern search
  (window ladder), jmp-stub dereference, call-site anchoring via veteran
  parallelism, exact code-byte match (position-independent stubs), and
  predicate-farm entry matching by parameter-block content. 100+ targets
  verified; remaining opens route to per-target planted-ILLEGAL TRIPWIRES
  whose fault PC names exactly which unresolved ref fires.
- Ported as oracle-validated extra regions: the +0x34 newcomer-support zone
  (0x5C800+0x6A00), 17 secondary-object handlers (types 59-75), the VS2
  helper 0x15702, id-normalization 0x26142 and 0x28122, and the source-only
  per-game hook 0x8A5A8 (char-id 0x13 imm rewritten to 0x0F).
- FIRST ENGINE HOOK (proj_hook): vsavj's secondary-object dispatch table
  (0x054484) has 59 entries; vsav2 has 76. Donovan spawns high types. The
  8-byte dispatch at 0x054470 is replaced with jsr thunk; the thunk indexes
  a 76-entry extended table (59 vanilla entries byte-identical + ported
  handlers). PC-relative-reads-are-decrypted rule honored (GOTCHAS).
- Two more bank-tail per-char pointer tables discovered (vsavj 0x0BF29A
  code-ptr, 0x0BF41A data-ptr) — mapped + repointed.

STATUS: match RUNS (timer, CPU acts, no crash/tripwire/reset through a full
moveset-exercise replay). OPEN BUG: Donovan ignores inputs (x static, idle
anim loop) and takes no damage — input/command processing or box
resolution; next lead is a vsav2-native ground-truth trace of the walk/X
writer vs the ported build.

### Stage 4 addendum (session 4 close)

Second engine hook added: the type-dispatch at 0x05E542 (table 0x05E556,
114 entries) extended to vsav2's 124 (extra rows = VS2 companion-object
handlers in the 0x08xxxx zone, ported source-only as region x088512).
Allocator-family mapping corrected: vsav2 pool helpers 0x15702/0x1572E map
to vsavj 0x016FBA/0x016FE6 (never ported — they read the game's own RAM
bookkeeping; see reconciliation.md). Frontier: the companion spawn-node
protocol (docs/project/tables/reconciliation.md OPEN FRONTIER).

### Stage 4 progress — sessions 5-6

Session 5 (companion chain + space):
- Anita's asset graph (44.2K at vsav2 0x2B8060, vhunt2 twin 0x2A4504)
  ported as a self-pointer data region via the segmented oracle diff:
  2065 pointer fields rewritten across 75 segments; 21K of unaligned
  dead zones carried raw.
- Class registration: her vs2-only update class remapped to vsavj's
  equivalent (`[[port_patch]]` 0x0E→0x0C on the ported blob, old bytes
  verified at generation).
- Space closed at ~335K/336.6K: stage-1 scaffolding gated to stages 1-3;
  hitbox_proj honestly bounded (0x1000; the old 0x435A was a next-ptr
  fallback artifact); only Donovan's own sub-object handler types ported
  (the other 13 belong to Huitzil/Pyron and stay TRIPWIRED); aux0 tail
  margins 0x400→0x180; per-region hole hints.

Session 6 (PC-relative correctness — the big one):
- Brief-format `(d8,PC,Xn)` dispatch tables inside ported code are now
  discovered, length-bounded by the smallest forward displacement, and
  their FULL extent recorded as DATA so the bare-long relocation
  heuristic can never rewrite them. A fused pair of word entries
  (`0006 0068` read as pointer 0x60068) had been silently corrupting a
  dispatch table — the crash surfaced two states later, far from the
  damage. See docs/GOTCHAS.md.
- Escaping table entries and direct `(d16,PC)` escapes are rewritten as
  displacements against real placement; unresolved targets route to a
  shared per-region ILLEGAL tripwire, gap-fitted within d16 reach.
- `[[layout_group]]` (PC-referencing region families keep source-relative
  spacing, inter-region gaps recycled by the allocator) and `near_map`
  (satellite region placed within d16 of its anchor).
- Slot-clearing allocator wrappers: ported code assumes virgin pool slots
  (vs2 spawns before any recycling); ours are dirty. The wrapper
  zero-fills the 0x80-byte slot preserving the category byte at +8, and
  wraps ONLY Donovan's allocation calls — vanilla allocations untouched.
- Result: character init COMPLETES and the match runs; crash frontier
  2886 → 3025. Remaining: one anim state-index delta (the table is
  byte-identical to native vsav2; the index into it is vs2-flavored).
  Legacy suite GREEN (13 replays) throughout.

Session 14p (Anita's feet — empirical bank-2 attribution):
- Playtest round 13 artifact pinned: the garbled tiles at Anita's feet
  are OBJ entries (bank 2, codes 0x0FD2/0x0FD3 shipped) from record
  0x0FCECA in x2b7ef4 — vs2 source codes 0x0F8B/0x0F8C rewritten +0x47
  by the BANK-1 effect-tail reloc class. The record draws on BANK 2
  (its sub-objects' +0x18 = #$4000), so the bank-1 triage was the wrong
  model for it: the round-10 "solid green" was the RAW vs2 code against
  vsav bank-2 content, and the round-13 "garbled mess" was the same
  entry after the +0x47 mis-reloc landed (build 569859d1).
- Empirical attribution (f8eda2ca post-mortem compliance): runtime
  breakpoint trace on the OBJ format handlers over 9 replays
  (tests/lua/obj_record_bank_trace.lua) — exactly ONE x2b7ef4 record
  observed at bank 0x4000 (0x0FCECA); set closed structurally via the
  emitting sub-object's record stream at dst 0x0F619C (src 0x2BA120):
  54 fmt-2 records 0x0FCECA-0x0FD5A4, 308 tile words, 37 unique
  (code,1x1) blocks, vs2 codes 0x0F8B-0x0FBC.
- Fix is data-only: tools/gen_anita_bank2.py regenerates
  effect_tail.json `bank2_recs` (54 src addresses) + `bank2_place`
  (37 shelf targets, rows 0xEAC0-0xEAFF, cap 0xEEBB) — the generator's
  existing bank-2 branch (kept through the f8eda2ca revert) excludes
  those records from the bank-1 maps, rewrites their tile words to the
  shelf, and appends [src,dst] pairs to effect_map.json for the gfx
  step (vs2 bank-3 source content, group B). 308 bank-2 words reported
  at generation; verified in OBJ RAM (entries now 0xEADA/0xEADB) and
  on-screen (green blobs gone, frame 2600 of 19_don_dp_spam).
- Build fingerprint f29cf24a; gates re-run (see STATE).

Session 14r (COMPANION OVERLAY SHIPPED — sword/statue/Anita in-match):
- The stage-7 overlay port completed to a shippable 22-site
  configuration. Final architecture: object-granular closure port of
  the vs2 overlay zone (9 strip tables + streams + strips + records +
  coordinate lists) into a relocatable heap over JEDAH'S dead anim
  areas (segA 29,512B at 0x248D80 + segB 496B at 0x2557B0); every
  discovered pointer relocated through the placement map, table entry
  words recomputed only when their targets validated (verbatim
  otherwise — over-walked table reads must never fabricate words);
  4,789 bank-1 tile pairs placed at dead-Jedah positions.
- Stream node grammar COMPLETE for the stride-8 stepper (engine
  0x15030; Jedah's module uses only this one — 395-caller census):
  node = (duration.b, flags.b, param.w, ptr.l); flags==0 advance +8;
  flags&0x80 = 12-byte node, cursor JUMPS via the long at +8 (attack
  loops); flags&0x40 = terminal; ptr==0 legal. The 0x10/0x18-stride
  steppers (0x1509C/0x1505A) belong to other characters' modules.
- Site policy (all empirically probed on the Donovan path, timer-tick
  detector): 22 context-verified sites thunked (`movea.l #T,a0` ->
  `jsr thunk`; ported table iff match-active AND slot-0x0F present);
  3 measured crashers excluded (0x5D8B8/0x5EE22/0x918F0 — ids resolve
  into table entries the closure cannot yet validate; those features
  keep Jedah's vanilla tables, wrong-art residue only).
- Visible result (snapshots, 19_don_dp_spam + 23_don_matchwin): Anita
  fully rendered dragging behind Donovan, sword on his back, clean win
  pose with Anita beside the loser — the Jedah-darkness "blinking
  sword/statue" is gone from match and win phases. One overlay piece
  (hat) still alternates per frame — vs2-dither vs residue: playtest
  judges.
- The guarded soak (12_donovan_vs_cpu, frame 8424 — a round/opponent
  state no probe reached) caught an address error in the fmtA
  composite handler: skipped fmtA records truncated their streams.
  Fix: fmtA records carried as OPAQUE objects (verbatim copy, size =
  distance to the next discovered object, no internal rewrites) —
  closure deepened to 431 records once those streams stopped
  truncating. Soaked past frame 8800 clean.
- Fingerprint cf2109d8 (deterministic re-emit via the baked-in
  VERIFIED_SITES/KILLER_SITES policy in tools/overlay_port.py).

Session 14s (round-16 regressions: overlay reverted, pixel gate born,
latent menu bug fixed):
- Playtest round 16: the overlay build corrupted title/select/menu
  graphics (the tile pool's "OBJ-dead" positions back scroll-layer
  tiles — CPS-2 layers share ROM bytes) and the red/purple flicker
  persisted (unpoked table families). Overlay PARKED
  (build/manifest/overlay.wip); shipping reverted to the feet-fix
  lineage.
- NEW PERMANENT GATE: tests/test_gfx_menus.sh — pixel-exact
  title/select/speed-menu comparison vs frozen vanilla goldens
  (tests/expected/vsavj/menus/), wired into test_m2b_stage6.sh. RAM
  and VRAM gates are provably blind to gfx ROM content and to
  coordinate lists (they flow ROM -> OBJ RAM at draw).
- The gate's FIRST RUN caught a latent shipped bug: speed-menu
  TURBO/AUTO text 8px off since the select-screen work. Mechanism:
  Jedah's 1-pair name-banner coordinate list [0x32A196,0x32A19A) IS
  the menu record's first pair (the pool nests lists). First fix
  (relocate lists + repoint cptrs) FAILED the masked gate — cptr
  values are RAM-visible on select paths (fourth stored-anchor
  class). Final: cptrs untouched; SHARED lists never written
  (select_port.py SHARED_LISTS); Donovan's banner draws at the host
  position.
- Fingerprint 37269fff: double M2b gate (now incl. the pixel gate) +
  oracle + dual-emulator + flavor ALL PASS, menu pixels vanilla-exact,
  global pool byte-identical to vanilla outside the five unshared
  list writes.

Session 14t (win-quote palette: mechanism decoded, port REVERTED by
the masked gate; quote-screen coverage begun):
- Round 17 (maintainer): menus confirmed clean on 37269fff.
- WIN/QUOTE PALETTE MECHANISM fully decoded (static): winner rows
  0x16-0x1F upload from per-SIDE blocks (side table CODE:0x38C298 ->
  vsavj P1/P2 0x39FDC0/0x3A18E0) with char*0xA0 slices; vs2 analog
  0x396C94 -> 0x3B727C/0x3B8EDC, Donovan char 0x13. Secondary paths:
  char*0x60 reader (same blocks, ~0x1C42E), select-grid variant-10 row
  (already ported), sprite-table path (already ported).
- The in-place slice port FAILED the masked gate: 03/16 diverged
  3229/2008 frames from select entry — the blocks are BULK-STAGED
  through work RAM mid-frame on legacy 2P paths (transient divergence:
  visible to the earlier-in-frame checksum sample, invisible to
  frame-done dumps — a nasty diagnosis; two whole verification rounds
  were invalidated by dump-read perturbation of the QSound latch
  before the mechanism emerged). REVERTED to 37269fff byte-exact;
  the fix needs the staging reader decoded (slot-conditional at the
  reader, or staged-buffer-aware masking with maintainer sign-off).
- NEW REPLAY 28_don_quotewin (evolved from 23, which LOSES on current
  builds — CPU KOs idle Donovan in round 3): wins the match, reaches
  the "1 WEEK" story card and the continue/quote screen family —
  the suite's first post-match-screen coverage.
- New cosmetics logged: LOSS-path quote/continue screen shows JEDAH's
  win-quote art; (from earlier this session) the map/continue screen
  shows correct Donovan art+name.
- Shipping stays 37269fff; gates green incl. the pixel menu gate.

Session 14u (win-quote palette shipped via copy-and-repoint; four gate
iterations):
- The 14t in-place failure led through four masked-gate iterations to
  a working design: three patched block copies in the proven-dead
  anim area (A1/A2 = per-side 0xA0-view at 0x248D80/0x24A8A0, slice
  [0x960,0xAA0) <- vs2 Donovan; B = 0x60-view at 0x24C3C0, slice
  [0x5A0,0x6E0)), a private side table at 0x24DE00, ONE code-imm
  poke at the exclusively-quote-time reader site 0x1C1FA, and the
  0x60-view lea (0x1C426) -> copy B. Everything else — the original
  blocks, the shared table 0x38C298, and the three PRELOADER sites —
  stays byte-vanilla.
- The hard-won map: per-char win-palette slices are BULK-STAGED
  through work RAM at every select-entry variant on legacy paths, by
  THREE different sites (0x1BF56 normal select, 0x1C5CE 2P/VS select,
  0x7D4FC challenger-join) — each found by per-site gate bisection
  after watchpoint sampling missed two of them. Site attribution is
  PATH-dependent; only build-level bisection against the replay
  matrix is trustworthy.
- Fingerprint 1f5fa38e: double M2b gate (incl. pixel menu gate) +
  oracle + dual-emulator + flavor ALL PASS. CAVEAT for playtest: if
  the quote screen renders from the PRELOADED staging rather than the
  0x1C1FA fresh read, Donovan's quote palette will still be Jedah's —
  then the staging CONSUMER is the next decode target.

Session 14v (Felicia-float class: the grab-pointer work vars — audit
COMPLETED and closed):
- Playtest round 18: win-quote palette still Jedah's (the quote screen
  consumes the select-time PRELOAD staging, not the 0x1C1FA fresh
  read — the staging consumer is the next decode); and Felicia rose
  off-screen after a throw in a Donovan match (Rainbow-Edition-style
  float, correctly flagged as a likely port side effect).
- ROOT CAUSE (the A5 work-var audit, now COMPLETE over 0xB000-0xBFFF
  across all ported code regions): exactly 8 unreconciled (d16,A5)
  refs, all in x028122 — the ported throw code stores the thrower/
  victim OBJECT POINTER WORDS through vs2's layout (-0x4B74/-0x4B72,
  3 sites each) and clears a state byte at vs2's -0x4B3D (2 sites).
  Every throw sprayed pointer-magnitude garbage into two unrelated
  vsavj work vars = the float. Fix: 8 port_patch rows (the -0x52
  family shift: B48C->B43A, B48E->B43C, B4C3->B471), analogs
  triple-verified in BOTH engines' native throw code (vsavj pairs
  0x29694/0x29762/0x29828, clr 0x2968C/0x29738).
- CCR audit of all 22 thunked overlay sites: clean (every post-site
  path re-sets flags before any conditional branch) — the thunk class
  is exonerated for the float.
- Throw-oracle note: 27_don_throw_vsavj has DRIFTED (pre-throw pokes
  now connect on current builds: P2 at 278 pre-throw, so the -5
  full-HP measurement is not reproducible). Bisection showed the grab
  rows change NOTHING on this replay (none/ptr/clr/all identical) —
  no evidence of harm; the float verdict is the maintainer's next
  Donovan-vs-Felicia session. Replay re-freeze queued.

Session 14w-b (the SECOND Felicia defect: pair-table stride bug):
- After the gap-class disable fixed the wall latch, the new
  29_felicia_walljump legacy gate still failed — and paid for itself
  immediately: Felicia's WALK-BACK speed was also corrupted (patched
  walks whole pixels, vanilla accumulates subpixels: -4.80 vs -4.B0
  per frame — a 1px drift invisible to play but not to the oracle).
- Root cause: param32_a/param32_b were registered as value32 tables
  with 4-byte per-char rows; they are PAIR tables (8 bytes per char =
  forward.l, back.l movement velocities). "Slot 0x0F" therefore wrote
  FELICIA's walk-back long (char-7 pair, second half) with a value the
  extractor had read from the equally wrong vs2 address. Fixed in
  bank_map.toml: kind rec8, stride 0x100 — the extractor now reads
  Donovan's true pair and the gen writes Jedah's true pair (0xBD8F2/
  0xBD972 + param32_b analogs).
- 29 reclassified masked-EXACT -> masked-FLICKER with frozen inventory
  29@2435 (one isolated spawn-boundary frame, the existing approved
  mechanism class); walk and wall-jump now byte-match vanilla.
- Fingerprint 340673da; full battery at session end.

Session 14w-c (the type-63 chain closed; ALL GREEN at d6a751cb):
- The pair-table fix changed CPU-Felicia's flow in 21_don_mash and
  Donovan's own deep-arcade path spawned SECONDARY-OBJECT TYPE 63 for
  the first time — the M2a "types 59-62 only" assumption was
  measured-wrong. Chain, each link verified:
  1. Type-63 tripwire (0xCB880) fired at ~10050 -> handler ported as
     extra root 0x6717c:0x154:t0x671b0 (clean extraction, 13 refs,
     all recon rows verified).
  2. The handler's hit-reaction uses id 0x50 — the FIRST id past
     vsavj's 80-entry reaction table and BELOW the hook's old ext
     range (first_ext 0xA2 = scaled id 0x51): it fell through to the
     vanilla table one entry short, read the dispatch's own opcode
     word (0x323B) as a jump offset, and address-errored on the odd
     target (vec3, PC 0x18466, ADDR 0x1B6A3 — the exact crash math
     that unlocked it).
  3. Fix: reaction_hook first_ext 0xA2->0xA0, n_ext 3->4, case_a0 =
     vs2's id-0x50 case verified verbatim (137c000f00544e75 — the
     scaled-id model confirmed by matching all three existing cases
     byte-for-byte against vs2's table).
- Fingerprint d6a751cb: double M2b gate (masked legacy incl. the new
  29_felicia_walljump flicker gate + pixel menu gate) + oracle +
  dual-emulator + flavor ALL PASS. The rule-6 halt is lifted.

Session 14y (palette uploader poked — maintainer-approved doctrine
amendment; HUD/select/quote palette family fix):
- Round 21's HUD mini-portrait note led to re-reading CODE:0x1BF56:
  it uploads palette rows DIRECTLY to palette RAM (the 14u "work-RAM
  bulk preloader" attribution was wrong for this site — only
  0x1C5CE/0x7D4FC stage through work RAM). Poking its side-table imm
  to the patched win-palette copies routes the select/HUD/quote
  palette-row family through Donovan's slices in one stroke.
- Measured cost + doctrine amendment (maintainer-approved, round 22,
  revert-if-problematic): the select-entry upload leaves exactly ONE
  work-RAM trace frame at the known spawn-boundary flicker frame —
  02/05/07 reclassified masked-EXACT -> masked-FLICKER@829 (the
  already-approved mechanism class), pick's frozen first-divergence
  constant 1080 -> 829 (the upload precedes the old anim-hover
  divergence). Attract UNCHANGED at exactly 4278.
- Fingerprint e7682289: full battery green twice; flicker inventory
  grew by exactly the predicted frames and nothing else.

Session 14z (round 22: the copies convicted; full winpal revert; throw
coverage gate):
- Round 22: palettes did NOT visibly improve (win-quote still Jedah's,
  HUD mouth/eyebrow still green on green/tan) AND the throw
  victim-teleport reappeared. The TIMELINE convicts the winpal COPIES
  at 0x248D80 (broken on every copies-active build d6a751cb/e7682289,
  healthy without them on ad372a6b): the 14v grab-row rollback "fixed"
  the throw only because the 14w winpal-disable rode the same build.
  The "dead zone" holds THROW-CINEMATIC/victim-sequence data — and no
  legacy replay ever threw, so the masked gates were blind (the same
  coverage failure class as Felicia's wall jump).
- FULL REVERT: winpal disabled for good at this placement (post-mortem
  in select_port.py); gates restored (02/05/07 masked-EXACT, pick
  constant 1080); the 14y doctrine amendment is VOID. Build byte-exact
  ad372a6b — the round-21 throw-confirmed fingerprint, verified by
  identical hash.
- NEW PERMANENT GATE: 30_demitri_throw (legacy throw coverage,
  masked-EXACT, deterministic freeze) — would have caught the copies
  bug the day they landed. The palette family (quote + HUD rows)
  returns to open decode: none of the three poked uploader sites feeds
  the visibly-wrong rows; the true consumer is still unfound.
- GOTCHAS reinforced (no new entry — the same two lessons): "dead
  zone" claims require per-consumer proof, and every mechanic class
  needs replay coverage BEFORE data lands near its tables.

Session 14z-2 (throw victim-teleport root cause + fix):
- ROOT CAUSE (mechanism-traced, not timeline-inferred): Donovan's throw
  cinematic positions the victim via the pointer-of-tables at
  PRG:0x0BE27A (indexed by thrower id; consumers: vanilla
  0x2804C/0x280C4/0x2813E/0x5316A/0x6E788 + the ported twins in region
  x026142). Slot 0x0F's entry (PRG:0x0B19F8) held Jedah's keyframe
  table (0x198 bytes/victim); Donovan's anim keyframe indices are
  authored for vs2's 0xC8-stride table -> mis-indexed records ->
  garbage thrower-relative offsets -> the victim teleports. The gap
  auto-table class had been covering this table until its 14w disable.
- FIX: [[data_port]] row `throw_victim_keyframes` — vs2 0x0CA1CA
  (0xE50 bytes; vhunt2 twin 0x0C9A5C byte-identical, asserted every
  build) placed over Jedah's zone at PRG:0x0B19F8 (0x1828 available;
  remainder vanilla-dead). Self-relative table, no relocation. One
  in-blob fix: victim-offset word [0x0F] 0x0B30 -> 0x0D88 (vs2's
  Donovan-victim block) for the mirror match. Guards: sibling-oracle
  identity, dest old-content head, dst_end bound, old-verified fixes.
- New generator construct [[data_port]] (gen_donovan_patch.py, stage
  >= 6): bulk source-set data over verified vanilla spans, with the
  guard set above. First user is this row.
- New tool tests/lua/tap_writes.lua: notifier-hardened write taps (see
  GOTCHAS: taps dropped on handler re-install; debugger watchpoints
  desync replays on hot fields).
- Measured: replay 27 victim trace 21 teleport-scale jumps -> 4
  structured slam keyframes (2 per throw, consistent phases). Build
  597ae55b.

Session 14z-3 (sword-swing blocker: staged thunks + generic construct):
- New generator construct [[site_thunk]] (stage >= 6): generic 6-byte
  engine-site -> jsr thunk (the 14q pattern productized). Old bytes
  verified against the vanilla opcode image; thunk hex authored in the
  manifest; placed in hole a; site re-encrypted as a code op.
- spark_spawn_mark @0x018F2E (allocator jsr wrapped): on successful
  spark alloc, if ATTACKER (a6) char id == 0x0F, write 0x0F to the
  spark's spare +0x9A. Gated write: legacy content (no slot-0F
  attacker possible; Jedah replaced in this flavor) never writes.
- spark_bank_swap @0x05E7C6 (type-3 first-tick bank write): marked
  sparks get OBJ tile-bank +0x18 = 0x4000 (vsav bank 2, the Jedah
  band where all Donovan art lives) instead of vanilla 0x0000. Flags
  behavior preserved on the vanilla path (same final move.w; the
  fall-through resets ccr via move.b before any branch).
- Both verified live (replay 17 f3475+: +0x9A=0f, bank18=4000).
  Necessary but NOT sufficient: the swing still resolves vanilla art
  because number->strip resolution is display-side (see STATE 14z-3 and
  the two new GOTCHAS). Fingerprint cfe757a1.

Session 14z-4 (round-25 regression rollback):
- Both 14z-3 site_thunk rows (spark_spawn_mark, spark_bank_swap) staged
  to 99 after pixel A/B convicted them: bank-without-strips garbles the
  spark; the +0x9A mark hides Anita (display semantics, not a spare
  byte). gen_donovan_patch.py: site_thunk and data_port loops now honor
  per-row `stage` (previously unconditional at stage >= 6 — the
  data_port row worked by coincidence of both being 6).
- Build restored to fingerprint 597ae55b (byte-exact round-24 build);
  replay-17 hit-frame snapshots pixel-verified clean.
- New acceptance rule for effect/display changes (GOTCHAS): pixel A/B
  via SNAP_FRAMES on an exercising replay, alongside the battery.

Session 14z-5 (sword swing root-caused and fixed; build 2da7d910):
- Reconciliation row vs2 0x05C77E converted from the FALSE codebytes
  match (-> masked vsavj 0x5459A) to new kind `patched_clone`:
  clone_src 0x5459A, clone_len 0x44, patch removes `andi.w #$ff,d0`
  (024000ff). The generator places the clone once in hole a and routes
  ONLY ported engine refs there; all 36 vanilla call sites keep the
  masked original (legacy surface untouched — the clone is new code in
  formerly-0xFF space).
- gen_donovan_patch.py: `patched_clone` kind in the engine-ref resolver
  (cached, old-bytes uniqueness check on the patch site).
- New behavior gate tests/test_don_sword.sh + replay pair
  31_don_6hp_{vsavj,vsav2}: 6HP whiff at round start; asserts the sword
  object resolves swing node 0x0E1A20 (= vs2 0x28DEF8) with idx 0.
- Measured collaterals recorded in STATE (generic-spark red herring,
  effect table map, number-table map).

Session 14z-6 (no ROM change; Victor-shock garble scoped):
- No patch rows changed. Round-27 confirms the sword fix (14z-5).
- Victor-shock-on-Donovan garble scoped to stale-OBJ-list exposure
  during the shock composition (see STATE 14z-6); fix deferred with
  full instrumentation (replay pair 32, OBJ pairing method) in place.
- tap_writes.lua: 32-bit data logging (GOTCHAS entry).

Session 14z-7 (Victor-shock stale-OBJ fix):
- init_shim objram_clear v2: arms countdown 0x50 at $FF7F00 (was a
  char-init-time 8KB clear — ran mid-VS-screen, repolluted; measured).
- New GEN blob (alloc a, 0x3A bytes): detours the ported sword
  routine's per-frame exit jmp (placed 0xCC110, old target 0x1551A);
  match-active-gated countdown; at zero clears OBJ RAM 0x708000-9FFF
  once in the update phase and falls through to the original target.
  Donovan-only execution by construction; $FF7F00 and the OBJ list are
  legacy-masked/rebuilt state — legacy RAM surface untouched.
- New gate tests/test_don_shock.sh (replay 32, tail buckets zero at
  f2740). Accepted approximation: transparent instead of vs2's benign
  dark leftovers in the shock curtain buckets.

Session 14z-8 (14z-7 revert; real shock mechanism characterized):
- objram_clear = false (manifest, with post-mortem); the init-shim
  marker and sword-exit blob are no longer emitted. Build byte-exact
  2da7d910 (the round-27 sword-confirmed fingerprint).
- tests/test_don_shock.sh removed (asserted the phantom metric).
- New probe pair tests/replays/33_victor_6hp_{vsavj,vsav2}.
- Real defect (round-27 = round-28, one bug): the victim held-pose
  cursor enters Donovan's sequence one jump-node off (nodes visited in
  opposite order vs native) -> body pieces draw ~0x20-adjacent band
  tiles. Entry is computed by the reaction/seq_set machinery — next
  session thread in STATE 14z-8.

Session 14z-9 (no ROM change; electric family verified end-to-end):
- Probe pair 34_victor_5hp_{vsavj,vsav2} added (standing 5HP + f.6HP).
- No defect found: reaction anims, records, codes, attrs, cptr
  relocation, coordinate content all byte-verified; phase-aligned
  pixels coherent. 14z-8's "wrong node" reclassified: cross-game
  Victor script-order difference (see STATE 14z-9 and GOTCHAS).
- REGLOG register capture added to tests/lua/tap_writes.lua.

Session 14z-9c (no ROM change; THE tile-window collision found):
- Vanilla control run proved the curtain buckets and darken behavior
  vanilla-faithful; the real defect is the band-remap target window
  (0xADCF-0xEA3F) overwriting vanilla-referenced tiles (0xC625 curtain
  smoke -> Donovan chunks; visual render-diff confirmed). Fix = audit
  + re-placement, plan in STATE 14z-9c. Probes 35/36 committed.

Session 14z-10 (protected-tile policy; build 272bfbbb):
- New manifest build/manifest/protected_tiles.json (audited vanilla-
  referenced positions + vetted free pool). Generator: unified
  exception allocator (775 band srcs relocated, pairs via effect_map,
  skip list via tile_exceptions.json). build_gfx: skip-aware band loop
  + readback. effect_tail: 11 Anita blocks moved. verify_gfx_build:
  protected-position assertion (standing). build_donovan.sh: pipefail.
- Verified: 358/358 protected positions vanilla-identical; hold frame
  clean; probes 17/31 pixel-identical to goldens.

Session 14z-11 (X-ray overlay sweep; build 6f96f45b):
- obj_records.py walk(): sweep pass (offset-computed record heads,
  strict validation); gen gfx_remap: mirrored sweep + dynamic pool
  trim vs the grown inventory. 38 records / 338 tiles added; parity
  1160/14764 maintained; protected-position assertion green.
- The electrocute X-ray overlay now draws Donovan's own ported art
  (was: raw vs2 codes over vanilla/Donovan-band positions = the
  round-27..31 white-block garble on victims).

Session 14z-12 (effect-palette block; build fbf10960):
- [[palette]] machinery multi-entry; new "effect" entry: vs2 0x3ADFDC
  (0xDC0, Donovan's effect/flash palette block) placed in hole a,
  vsavj table 0x38C218 row 0x0F repointed (the second per-char palette
  table — main+0x80 — uploader family 0x2AD20; was serving Jedah's
  greys = the grey X-ray body of round 32, and likely the sword/statue
  red-purple blink family).
- Purple electricity ruled vanilla-faithful (global palette-seq table;
  vanilla control identical); vs2-yellow recorded as a pending
  maintainer decision in STATE.

Session 14z-13 (no ROM change; sword-blink mechanism decoded):
- Round-33 confirms the electrocute fully (yellow included — per-char
  block carries it; decision dissolved). Sword/statue blink root cause
  measured end-to-end: global palette-seq id collision (see STATE
  14z-13 for the complete map and the wrap-the-trigger fix design).

Session 14z-14 (third palette table; blink driver mapped; build 40256bae):
- [[palette]] extra_tables support; 0x38C258 row 0x0F -> the ported
  effect block (mirrors vanilla table-2/3 sharing).
- Sword-blink red source NOT yet silenced: driver = a palette-JOB
  queue at $FF8280 with ROM script pointers (0x376518 family); the
  id->source computation is the one unpinned link (STATE 14z-14 has
  the full map and the pre-planned next tap).

Session 14z-15 (no ROM change; blink driver fully mapped):
- The $FF8280 job block = engine stage-setup installation (hardcoded
  immediates 0x1F142); per-stage descriptor table 0x1F92E; script
  0x376518 refreshes weapon palette rows 0x0C-0x0D; the red = row
  0x0D sourced from Jedah's block (+0xCD0). One resolution map from
  the fix; see STATE 14z-15.

Session 14z-16 (no ROM change; blink fix design complete):
- vs2 measured STEADY (no weapon-row cycling); vsavj's universal red
  accent identified as the blink source; full fix design (private
  script + countdown-blob pointer swap) in STATE 14z-16.

Session 14z-17 (SWORD/STATUE BLINK FIXED; build f4a7e00e):
- data_port `weapon_accent_rows`: vs2 0x39CBDC (0x40, his pale sword
  rows) over vsavj 0x39FBE0 (the four Jedah-theme accent rows; audited
  slot-0F-exclusive — zero legacy reads across 02/30/29 collectors).
  The accent cycle persists but alternates identical values = steady.
- tap_writes.lua: POKES facility (frame-scheduled RAM writes for
  live experiments).

Session 14z-18 (blink super-cycle + statue; build 53223293):
- data_port weapon_accent_tail (0x39FC20, 0x20) completes the weapon
  accent coverage; statue_accent_rows (0x39B040, 0x40, src_image
  vsavj: base-phase copy) stills the statue. Both ranges audited
  slot-0F-exclusive. data_port gains src_image.

Session 14z-19 (round 35: 14z-18 corrections; the real sword fix; Victor revert):
- REVERT statue_accent_rows (dst 0x39B040): that range is VICTOR's
  accent data (P2 rows 0x10/0x11 are the P2 character's rows; char id
  3 = Victor; 0x38D1A0 is his sprite block). Overwriting it was a
  superset violation — Victor's glow deadened in all matches. Bytes
  pristine again; guarded forever by tests/test_don_accent.sh.
- weapon_accent_rows (0x40 over T0+T1) + weapon_accent_tail (0x39FC20,
  half-row-offset content) RESTRUCTURED into three rows:
  - weapon_accent_t0: vs2 0x39CBDC (row C) -> 0x39FBE0
  - weapon_accent_t1: vs2 0x39CBDC (row C) -> 0x39FC00 (the marched
    second slot — 14z-18 had row D content here = the residual blink)
  - weapon_accent_rowd_slot: vs2 0x39CBFC (row D) -> 0x39FC20 (layout
    companion slot; no observed reader; authentic content either way)
  Mechanism: engine marches row 0x0C sources T0 -> T1 -> block+0x40 ×2
  each 4 frames (vanilla-Jedah control identical); both marched slots
  now carry identical row-C bytes = steady, byte-equal to native vs2
  (measured, 40-frame idle window).
- New gate tests/test_don_accent.sh: static (T0==T1==vs2 rowC, rowD
  slot content, 0x39B040-7F == vanilla) + behavioral (row 0x0C single
  variant == frozen native content; Victor row 0x10 cycle alive).
- Open (next session): palette row 0x0F fixture override port (vs2
  0x3CB7DC 2-row block -> rows 0x0E/0x0F; needs slot-0F-conditional
  hook — vsavj has no per-char override path); table B 0x38C1D8
  slot-0F repoint (alt-color Donovan).

Session 14z-20 (row-0x0F fixture override; shock-aura triage):
- [[site_thunk]] fixture_row0f_override_bank{0,1} (stage 6, hole "b"):
  sites 0x1C586/0x1C59A (`movea.l #$3B5940,a0`, the staged venue
  fixture loads for palette rows 0x0E/0x0F, both banks; shared by
  match intro + attract — measured). Thunk: char id ($FF8782 or
  $FF8B82) == 0x0F -> a0 = embedded vs2 block (vs2 0x3CB7DC, 0x40
  bytes; row 0 == vanilla fixture row 0x0E byte-identical, row 1 = the
  statue red ramp); else vanilla address. Flags dead at both
  fall-throughs (lea/moveq). Six direct fixture sites left unhooked
  (other venues, char-id staleness unproven — add only with measured
  need). Result: palette rows 0x04-0x0F all byte-equal to native vs2
  in-match (build 73f4f5a5).
- gen_donovan_patch.py: site_thunk `hole` option (data-carrying thunks
  MUST use "b" — crypt-range gotcha, first build shipped ciphertext
  palette; docs/GOTCHAS.md).
- test_don_accent.sh: rows 0x0E/0x0F frozen native constants added
  (also guards the crypt-range regression class).
- Shock-aura red-vs-yellow: engine-global vsavj styling (three-way tap:
  Donovan / vanilla Jedah / different victim — identical global
  sources). No defect; maintainer decision recorded in STATE.md.

Session 14z-20 addendum (suite hardening after maintainer discipline check):
- Maintainer confirmed 14z-20 playtest (statue good, keep vsavj shock
  styling — decision recorded + LOCKED).
- test_don_accent.sh section 3: shock-window vanilla lock (arc tuple
  set == frozen vanilla; row-0 pulse within vsavj ramp; override rows
  hold under effect load). Frozen constants derived from a VANILLA run.
- tests/replays/40_victor_5hp_defaultchar_vsavj.rpl: the discriminating
  different-victim control promoted from scratch (persistent-suite
  doctrine).
- tests/run_battery_m2.sh: the deliverable battery codified as one
  script (audit + 6 gate sections) — the pre-commit chain is no longer
  chat-memory.

Session 14z-21 (alt-color/table-B item closed NO-BUG; mirror verified; select-web P2 paths mapped):
- Kick-color Donovan: byte-identical to native vs2 (rows 0x0A-0x0D) —
  the alt set is block+0x180 INSIDE the ported 0x500 sprite block;
  table A repoint covers it. Donovan MIRROR (both slot 0x0F):
  P1+P2 rows 0x0A-0x15 byte-identical to native vs2 (replay 43 ground
  truth) — the mirror alternate is engine-composed from the same
  block. Table B (0x38C1D8) is never consulted on Donovan's paths; the
  14z-19 concern closes with no patch needed.
- Select-screen navigation mapped (live +0x382 hover walks): vsavj P2
  -> Jedah orb = U,U,U (web ids logged in the walk transcripts; P2
  U,U = Gallon 0x02, U,U,L = 0x0C, U,U,L,L,U = 0x07); vs2 P2 ->
  Donovan = L,L,L,L (P2 default hover 0x05). Victor = char id 3
  re-confirmed (ram.md R,R note + replay-31 pick).
- New replays: 41_don_altcolor_{vsavj,vsav2}, 42_don_mirror_vsavj,
  43_don_mirror_vsav2. New gate: tests/test_don_colors.sh (frozen
  native rows for alt + mirror); added to run_battery_m2.sh.

Session 14z-22 (select-sword machinery built + staged 99):
- gen_donovan_patch.py: [[code_word]] kind (guarded 2-byte code patch).
- donovan.toml: select_companion_entry_0f (jump-table 0x84594
  0040->0046) + 4 site_thunks (handler table leas 0x845EC/0x845F8 ->
  ported anim table 0xDDA1E for owner 0x0F; resolver call sites
  0x84602/0x84624 -> inject idx 0x10B + unmasked resolver 0x15088).
  ALL STAGED 99: activation verified byte-perfect on page A, but a
  second select drawer renders an un-walked record subset with raw vs2
  codes (Jedah giant-blade art) — re-enable after the walk-gap fix.
  Staged-99 build reproduces 73f4f5a5 bit-identically.
- Dead end reverted: build_gfx --extra-tiles + pool reservation
  (allocation cascade, 267 moved placements; docs/GOTCHAS.md).

Session 14z-23 (select-sword diagnosis corrected; still staged 99):
- 14z-22's "record-walk gap" retracted: the raw-code entries are stale
  unrendered OBJ junk (write-tap proof). Art verified correct by
  byte-compare AND visual tile render; entry sets byte-identical to
  native. Real defect: the rendered sword sits ~32px right of native
  and in front of the body (coordinate-base/priority, not art). Full
  facts + next-session plan in STATE 14z-23. Build restaged to
  bit-identical 73f4f5a5.

Session 14z-24 (select-sword FIXED; stage 6 live):
- Root cause of the 14z-23 composition defect: OBJ list order. vs2's
  Donovan select handler sets the owner's draw-behind flag (+0x3C=8,
  `move.b #8,$3C(a4)` — no vsavj occurrence); without it the
  companion's second emission draws over the body. The resolver-call
  thunks now set it in the 0x0F branch (owner ptr from $30(a6), a1
  dead at both sites). One-shot set persists (measured).
- The "32px offset" was occlusion illusion; Y-word high bits = tile
  bank field (both games correct). Software-compositor triage caught
  the order difference from identical entry data.
- Gate: test_don_colors.sh section 3 (composition + order + frozen
  codes; replay 44). replay.lua: POKES facility (tap_writes mirror).
- Five manifest rows live at stage 6; build d1db9c0b.

Session 14z-26 (Change Immortal KO: hit-class table extension):
- data_port hit_class_props_ext: vs2 0x28026 (6 bytes, classes
  0x4E-0x53: 0f1b1f190f03) -> vsavj 0x28D4E (zero spare capacity in
  the per-hit-class property table 0x28D00; reaction dispatch 0x2380C
  family). Root cause of round-39's SPECIAL FINISH neutral-pose bug;
  electrocute shake now fires on deity KO. Known-partial: shake->
  collapse handoff still missing (STATE 14z-26). Gate:
  tests/test_don_reactions.sh (+ battery 3c); replay 48 promoted.

Session 14z-27 (Change Immortal: native class remap — complete fix):
- gen_donovan_patch.py: [[region_fix]] kind (guarded byte patches in
  extractor region blobs).
- donovan.toml: 7 region_fix rows — deity attack records' class 0x4E
  -> 0x04 (region "hitbox"); hit_class_props_ext restructured into
  _hi (0x50-0x53 from vs2) + _4e4f (word-aligned pair "231b",
  content-match source; 0x4E slot now unreferenced by any attack).
- Result (no pokes): full native electric death on deity KO; correct
  per-victim aura colors by construction. Gate strengthened to the
  grounded node. Round-40's Lilith-green/Morrigan-red aura explained:
  vs2's effect-row semantics drift on vanilla victims — eliminated by
  the class remap. Legacy control: pure-legacy shock palettes
  byte-identical to vanilla.

Session 14z-28 (round 41: class remap reverted; behavior locked):
- REVERT 14z-27 region_fix class remaps + the 0x4E/0x4F property pair
  (gameplay regression: single-hit knockdown on a standing multi-hit
  move). Interim = round-38 behavior. Three-consumer map + next-fix
  plan in STATE 14z-28; test_don_reactions.sh rewritten as the
  gameplay lock (multi-hit, no standing knockdown).
- Confirmed item: swordless-deity palette (yellow vs vs2 blue) — fold
  into the consumer-2 fix.

Session 14z-31 (color-aware accent; crash pinpointed):
- site_thunks accent_color_aware_{0..3} (uploader family-base sites
  0x2AD82/0x2AD94/0x2B342/0x2B7E8): slot-0F accent jobs read the
  object's cached block ptr +0x40 (selected color) instead of the
  static punch-color slots — the round-44 grey blink (any non-LP
  selection) fixed for select+match; weapon_accent_t0/_t1/rowd_slot
  become inert for slot 0F (kept as layout documentation).
- test_don_colors: kick-color row-0x0C steadiness assertion.
- Column crash: deterministic repro (experiments/421k_ko/50) +
  guarded fault: vec3 @ PC 0x185D8, A3=0xCAA5A (vanilla Jedah attack
  data) on the column projectile's KO — unported record pointer;
  repoint next session.

Session 14z-33 (column crash fixed):
- 9 region_fix rows in hitbox_proj: record types 0x52->0x06 (x3) and
  0x50->0x0F (x6) — vs2-dispatch-alias-proven remaps; vsavj's
  record-type table ends at 0x4F and fetched code bytes as jump
  displacements (vec3 reset). 14z-32's content-match theory retracted
  (aux0 ports are correct). Type-0x51 cluster logged untouched (no
  alias proof). Gate: tests/test_don_column.sh (guarded replay 50) +
  battery 3d.

Session 14z-35 (type-0x51 cluster: latent crash preempted):
- 6 region_fix rows (region hitbox): ES-deity record types 0x51 ->
  0x4E. vs2's type-0x51 handler is byte-identical to vsavj's
  types-0x4E/0x4F handler (the copy-class six-byte routine at
  0x1868C); on vsavj type 0x51 indexed past the 0x50-entry dispatch
  table (wild jump). No handler port needed — the renumbering insight
  closes the record-type saga.

Session 14z-36 (sworded-421P shock+death fixed):
- 7 region_fix rows (hitbox): sworded deity record types 0x4E -> 0x06
  (vs2-alias-proven: vs2 word[0x4E]==word[0x06]) = native class-8
  electric. Full shake + death chain + 10-step multi-hit (electric
  stun holds the victim, matching vs2); no standing knockdown.
  Retires the 14z-28 three-consumer property plan. Gate: death-chain
  assertions restored in test_don_reactions.sh.

Session 14z-49 (HUD mugshot/name + select medallion — per-slot venue
assets, all art/data byte detail):
- effect_tail.json place '0x4D62,2,2' -> '0x3DC8': vs2 Donovan HUD
  mugshot (4 bank-1 tiles 0x14D62/63 + 0x14D72/73) over the cells
  vsavj mugshot-table entry 0x0F (PRG:0x89884 + 0x1E = 0x05C8, +0x3800
  stager base = OBJ 0x3DC8) already points at. No code/table bytes
  touched for the mugshot.
- effect_tail.json place '0x4D55,3,1' -> '0xBE8C': vs2 name-plate art
  (3 tiles) at the bank-1 pool tail 0x1BE8C-0x1BE8E.
- aux_pokes hud_name_entry_0f_hi/lo: name-table (PRG:0x898C4) entry
  0x0F = 8 bytes at 0x8993C rewritten 0x868C0202 0xFFE80003 (code
  0x868C = 0xBE8C - 0x3800; attr/pal + x-offset/width words copied
  from vs2's Donovan row shape).
- effect_tail.json place '0xB10B,3,2' -> '0xB526': vs2 Donovan select
  medallion (6 bank-1 tiles) over Jedah's wheel-cell tiles
  0x1B526-28/0x1B536-38. Cell identity measured (cursor-ring center +
  color render), NOT assumed — first attempt targeted Gallon's 3x3
  b4e3 cell with an attr 2207->1207 poke + coord (8,-112)->(8,-104)
  poke; both REVERTED before commit, tiles restored by rebuild.
- data_port med_pal_row14_a: 0x20 bytes, vsavj 0x3A3A80 (select
  palette block A row 14 — the wheel view's live copy; block B copy
  0x3A3CE0+0x280 left untouched, different content = other sub-venue)
  <- vs2 0x3BAFDC (Donovan icon's row-05 source). Live row 14 lands
  byte-equal to vs2's live select row 05.
- Gates: test_don_reactions ES section + f2600 OBJ locks (mugshot
  entry 200,32,0x3DC8,0x112A; name 144,40,0xBE8C,0x0202);
  test_don_colors select section + row-14 freeze, wheel-record-intact
  and Gallon-cell-intact (264,64,0xB4E3,0x2207) assertions.

Session 14z-62 (M3a select-records half — the tenant's OWN select records
at a variant id; generator section `select_records`, byte detail from the
scratch build `build/m3a_selrec`, fingerprint dd88f343 — addresses of the
allocations are the SPACE MODEL's output and may move with unrelated
manifest changes; the six ARRAY ROW addresses are fixed by the id):
- Emitted ONLY when the tenant id is variant-half (>= 0x10); at slot 0x0F
  the section is inert and select_port.py remains the mechanism — frozen
  references verified rebuilding bit-identical after the change
  (stock `ae701ffb`, WIDE `9bac6ee3`).
- Six poke32s, the whole program-side mechanism (arrays measured 14z-61,
  P2 = P1 + 0x80, row = base + 4*id):
    0x267476 <- portrait/p1 record   (was 0x2719DA, Victor alias)
    0x2674F6 <- portrait/p2 record   (was 0x271DEC)
    0x2675F6 <- name_banner/p1       (was 0x272172)
    0x267676 <- name_banner/p2       (was 0x273080)
    0x268A4E <- highlight/p1         (was 0x272594)
    0x268ACE <- highlight/p2         (was 0x2727C0)
- Twelve data ops (six records + six coord lists), composed independently
  from vs2's OWN arrays (P1 0x2A0762 / 0x2A08E2 / 0x2A18FE, +0x80 for P2;
  row 0x13 = 0x2A63F0/0x2A6416, 0x2A657E/0x2A76A4, 0x2A6750/0x2A6F00):
  vs2 fmt/budget/count kept (budgets 0x5B/0x5B/0xA/0x3/0x5/0x2 — vs2's
  own, NOT the host's: variant rows are unreachable by legacy ids, so the
  budget debits only tenant-drawn frames), coord-list bytes copied
  verbatim, entry tiles remapped via select_port.PLACEMENTS. On the
  scratch build the allocator placed them at 0x400230-0x40034E (wide_ext)
  plus one 4-byte gap-fit at 0x0CF360 (hole_a dead space; data raw inside
  the encryption window, the stage-1 precedent).
- PLACEHOLDER tile codes kept (no placement exists): name_banner/p2
  0xB22C+0xB2A5, highlight/p1 0xB000 (the lit name label), highlight/p2
  0xB129. The ratified medallion policy; they render as wrong pixels until
  the gfx half places select art in WIDE group C.
- select_tiles.json now comes FROM THE GENERATOR on variant-id builds
  (101 pairs — only the composed records' art: portrait both sides + name
  p1). The slot-0x0F splash/win-quote placement families are NOT written,
  so that host art returns to pristine on this track.
- Host program bytes VANILLA again (checked byte-for-byte by the gate):
  record block PRG:0x271900-0x274700, select-palette grid column char 0x0F
  (11 variants at 0x3AC000), shared name-banner coord list 0x32A196.
- MEASURED interim state (scratch build, snapshots in session artifacts):
  tenant cell 0x13 hover shows Donovan portrait + name; pick reaches the
  speed menu; legacy hover (Demitri) vanilla. Host (Jedah) select ART
  still garbles: 89/92 of his portrait tiles sit INSIDE the tenant-placed
  fighter band [0xAD8F,0xEA3F] (his select art lives in his own bank-2
  band, not the select bank) — resolves when the gfx half moves the
  tenant's band to group C. His name banner happens to fall in placement
  gaps and renders correctly.
- Refusals added: tenant ids 0x12 (Gallon select variant) and 0x18 (Oboro)
  now refused in normalise_tenants (docs/game/atlas/id_space.md reservations).
- Gate: tests/test_tenant_select_records.sh (static composition re-derived
  independently + 3 negative controls incl. verdict-logic tests + the
  engine's own row-fetch sequence onto cell 0x13 via replay
  36_pick_tenant_cell.rpl, all three pieces). Wired into
  tests/run_battery_m2.sh with test_tenant_id.sh.

Session 14z-62c (the SLOT-ROW AUDIT — every remaining row-0x0F dependency
follows the tenant or is gated off; the de-substitution acceptance is
MEASURED. Scratch build db0c984d; both frozen references verified
byte-identical after every change):
- Found by the measure-diff loop: replay 11 (pick Jedah) on the 0x13
  build vs frozen vanilla masked logs diverged INTO THE MATCH; work-RAM
  dumps at the divergence named each subsystem in turn.
- Generator/manifest mechanics (docs/project/tenant_manifest.md "slot-row
  vocabulary"): [[palette]]/[[sound_table]] rows always the tenant's
  (fixed row keys are refused); only_base_slot gates on aux_poke +
  data_port; slot_ptr_table place+repoint mode; code_word
  slot_table/slot_stride/slot_off/slot_mirror; site_thunk row_subst +
  the An-relative stale-id guard; flat fixes= syntax + dotted-table ban.
- Rows moved to the tenant at variant ids: sprite palette (0x38C198 row
  -> 0x38C1E4, block 0xCEAF0), effect palette (0x38C218 row -> 0x38C264;
  the "extra table" 0x38C258 is that table's 0x1F MIRROR — base-half
  only), sfx ptr (0x0BF41A row -> 0x0BF466, array in wide_ext), throw
  victim-keyframe block (PLACED 0x400010, ptr table 0xBE27A row 0x13),
  win pos entries (0x5F24C/E), select-companion entry (0x8459C), and the
  ENGINE OBJ bank-word table row (0x282FA -> 0x4000; at slot 0x0F this
  row writes IDENTICAL bytes — Jedah's row already carried the band, the
  "landed for free" gotcha).
- Rows gated off at variant ids (host content returns to vanilla): the
  weapon-accent slots x3, win-pal slices x8, medallion palette row,
  HUD name-plate entry x2 (16-wide folded table — no entry 0x13 exists).
- Thunk bodies now track the tenant: accent_color_aware x4 (TT x2 forms
  + row_subst for the embedded palette row addr), select_companion x4
  (owner-id TT), ls_freeze x2 (a4-relative TT), spark x2 (stage 99,
  hygiene).
- DISCOVERY: [[data_port.fix]] (the 14z-2 mirror-victim fix) never
  parsed on this host — see GOTCHAS; the fix is parked as a flat-syntax
  comment awaiting the M3a re-freeze (applying it changes frozen bytes).
- MEASURED ACCEPTANCE on the 0x13 build (masked basis, vs frozen vanilla
  logs): replay 02 = window 890-1622 +3898 identical; 05 = window
  890-1622 +10498 identical (both EXACTLY the frozen donovan-m5w
  classes); 04 = composite, window 890-1051 + flickers 1525/2009/2195 —
  the frozen inventory to the frame; replay 11 (the host pick, formerly
  `diverge 890` forever) = single window 890-2362, fully re-convergent
  through a complete Jedah-vs-CPU match (tail 1963-2362 is ONE byte,
  $FF06D1, a menu-scoped counter phase reset at match start). Frozen
  into the gate as section 4.
- In-match tenant verified by snapshot: Donovan renders with his own art
  and colors at 0x13 (vs Q-Bee, frame 3300). Known interim: HUD name
  plate shows Victor's (folded 16-wide venue table), win-screen/palette-
  grid/splash colors unported at variant ids, select art still in the
  host band until the gfx half.

Session 14z-62d (THE GFX HALF, first landing: the tenant's FIGHTER BAND
serves from WIDE group C; the host's group B is PRISTINE. Scratch build
464eaf1f; frozen references verified byte-identical throughout):
- Design: keep every record CODE WORD exactly as the 0x0F layout (band
  codes 0xAD8F-0xEA3F + shelf to 0xEEBB), flip only the BANK words
  (0x4000 -> 0x1000, WIDE bank 4 = the bit-12 Turbo promote), and write
  the tile DATA at the same in-group indices into the four vsw simms.
  Records unchanged; mixed records stay coherent because the band and the
  effect shelf move together.
- gfx_tiles.py: GROUP_C (31,33,35,37) + bank_word() — the WIDE encoding
  is NOT bank<<13 (4<<13 is the sprite-list terminator bit). Three
  callers fixed to use it (build_gfx spec/print, verify_gfx want,
  generator table_fix row).
- Bank-word followers at a variant id: the six port_patch OBJ bank
  setters gain new_hex_variant (0x1000 forms), obj_bank_word_slot gains
  new_hex_variant, the ported bank table row writes bank_word(4), and
  normalise_tenants defaults a variant tenant's gfx_bank to 4
  (gfx_bank_variant overrides).
- build_gfx_donovan group-C mode (DST_BANK >= 4): band+effect tiles into
  four zero-based 4MB vsw simms (same interleave, same in-group
  arithmetic), verification "untouched == zero", vsav group B NOT
  written. build_donovan.sh injects the vsw members into the packed
  vsavjw.zip.
- DESCRIPTOR CRCs (both emulator patches, rebuilt + gates green): group C
  rows now carry SENTINEL CRCs 0xdec0de31/33/35/37 (+ sentinel-string
  SHA1s) so the members ALWAYS resolve by name. Two measured wrong
  answers on the way — pristine-B CRCs (the 60z shadow) and the zero-fill
  CRC (hash-collides with the zero QSound members; the B4 canary failed
  whole) — see GOTCHAS. FBNeo profile gate PASS (superset + inertness +
  canary) after the sentinel rebuild.
- MEASURED RESULTS (build 464eaf1f): Donovan renders in-match from group
  C (bank 4) pixel-correct; Jedah's MATCH is PIXEL-IDENTICAL TO VANILLA
  (raw-decoded snapshots at 4 frames; the earlier "garble" was his ES
  super's shred-ribbon art, and the MAME cross-driver VIDEO_OUT
  divergence is an instrument artifact — GOTCHAS); replay-11 RAM window
  890-2362 unchanged; the tenant gate PASSES all four sections.
- REMAINING interim (all bank-1/group-A, mechanism understood): the
  tenant's select-art subset still sits in Jedah's bank-1 hover-figure
  anchors, so Jedah's select-screen BODY figure garbles (face, name, and
  all match art are back). Moving select art to group C needs the
  select-OBJECT bank mechanism measured first (can a select record draw
  from bank 4?) — queued. HUD-plate/palette interims unchanged.

Addendum 14z-62d (the select-object bank MEASUREMENT — the last gfx
piece's unlock, tap at $FFB898 over replay 36):
- venue init frame 468: PC 0x07C428 writes 0x2000 (fixed, bank 1) — the
  PORTRAIT-RECORD object; per-hover frames 889/999/1039/1079/1119: PC
  0x05F9F2 (the `jsr 0x282C8; move.w d0,$18(a6)` at 0x05F9EC) writes the
  HOVERED char's engine-table bank word — 0x6000/0x0000/0x4000/0x6000
  then 0x1000 on cell 0x13, i.e. the obj_bank_word_slot poke already
  feeds the select venue. The figure object therefore draws the tenant
  from group C TODAY; only the portrait object's fixed init needs a
  tenant-gated thunk (hovered==TT -> 0x1000 else #$2000) before the
  select art can move off Jedah's bank-1 anchors.

Addendum 14z-62e (the select-palette resolution at a variant id, MEASURED
— read tap over the grid 0x3AC000+0x1600, replay 36): the uploader (PC
0x1C3AE/0x1C3C2 family, dest palette RAM 0x90C360) reads grid row
(variant*16 + id) with the id UNMASKED — per hover it read rows
0x01/0x05/0x0A/0x09 and then, on cell 0x13, row 0x13 = 0x3AC260 =
VICTOR's variant-1 slot (the overflow, not a fold). So the tenant's
portrait colors are Victor-v1's by arithmetic. The fix is the ported twin
of vs2's OWN mechanism (its uploader special-cases `cmpi #$13` at
0x6B1A0): one tenant-gated site_thunk at the row computation + a
data_port placing Donovan's 10 variant rows (vs2 0x3C117C+0xC6*0x20,
0x140 bytes) in wide_ext. Queued behind the select-art decision.

Session 14z-62e (SPLASH + WIN-QUOTE join the select-records mechanism —
the select-family program side is COMPLETE; scratch build 45730d0f):
- The VS-splash and win-quote records ride the SAME 32-row id-indexed
  array model, in the same region: splash_p1 0x2672AA, splash_p2
  0x26732A (separate pieces, not a +0x80 pair), win_quote 0x2673AA (no
  P2 twin — the portrait array follows immediately). Variant halves
  alias; vs2 carries Donovan's own rows at 0x13 (bases 0x2A05E2 /
  0x2A0662 / 0x2A06E2 -> records 0x2A7F68 / 0x2A7F86 / 0x2A8CF8).
- Three [[select_records]] rows + single-sided support in the generator;
  the checker now verifies NINE rows/records. Composed: splash 5 entries
  each (tiles all in the 14g placement family), win quote 35 entries
  (the 14h family), budgets vs2's own.
- MEASURED at the VS screen (tap, replay 36, frames 2599+): the engine
  interleaves the CPU opponent's VANILLA splash_p2 row (0x06) with THE
  TENANT'S COMPOSED splash_p1 record — frozen into the gate as the
  `splash` runtime section (RT_FRAMES=2800). Win-quote fires only at a
  match win; statics + alias anchors cover it until a 0x13 win replay.
- Stock rebuilds ae701ffb exactly. Both emulator WIDE gates PASS against
  the sentinel descriptors (FBNeo earlier; MAME confirmed this session).

Session 14z-62f (SELECT-PORTRAIT PALETTES at the variant id — the thunk
is Capcom's own pattern extended; scratch build 39597268):
- vsavj's uploader ALREADY special-cases two variant ids in the exact
  window we hook: `cmpi.b #$12,d6 -> row +0xB6` (Gallon variant) and
  `#$18 -> +0xB0` (Oboro) — dedicated row blocks past the 11x16 grid.
  The thunk displaces the 0x12 compare pair at PRG:0x5F146: tenant id ->
  a0 = the placed Donovan block (vs2 0x3C2A3C, 10 variant rows, 0x140B in
  wide_ext via the new site_thunk `data_subst`), d0 = min(variant,9),
  tail-rejoin at the shared row math 0x5F162; both original outcomes
  (the ==0x12 fall-through and the jmp 0x5F152 path) reproduced
  byte-faithfully. `only_variant_slot = true` — at slot 0x0F the thunk
  does not exist and the frozen references rebuild exactly (verified,
  ae701ffb).
- MEASURED: Donovan's select portrait renders in HIS OWN COLORS at 0x13
  (snapshot); replay 02's frozen window class is unchanged (890-1622,
  3,898 identical after) and the full tenant gate passes including the
  890-2362 acceptance window — the hook's cycle cost is invisible on the
  masked basis for the measured corpus.

Addendum 14z-62g (option A DECIDED; the select-screen object census
completed — implementation spec, held for the maintainer's playtest):
- The PORTRAIT-RECORD object is $FFB980 (P1): bank written 0x2000 once by
  the shared venue init (PC 0x07C428, frame 468) and again at select
  entry proper by PC 0x05F0C2 (`move.w #$2000,$18(a6)`, exactly 6 bytes)
  — never per hover, which is why its art must sit in bank 1 today.
- THE KEY SIMPLIFICATION: the landed select_pal_variant_id thunk already
  runs INSIDE this object's per-hover routine (0x5F106+: owner link ->
  d6 = hovered id -> record fetch bsr 0x5F326 -> palette upload) with
  a6 = the portrait object. The bank gate is an EXTENSION of that thunk
  (tenant -> also $18(a6)=0x1000; else -> 0x2000 restore), not a new
  site. P2's twin object runs the same routine — covered a6-relatively.
- Remaining census for the full option-A build-out: the name-banner and
  label drawer objects' banks (same tap method), the SPLASH-screen and
  WIN-screen drawer objects (each screen has its own bank context), then:
  select/splash/quote art into group C at VS2-NATIVE codes (the
  composed records drop the PLACEMENTS remap entirely — the placeholder
  class vanishes), drop the group-A placements, drop vsav.zip from the
  rompath (fully pristine parent).
- NUANCE, flagged for the maintainer at implementation: the WHEEL
  MEDALLIONS cannot ride group C — the wheel record is one object (one
  bank) whose 16 vanilla entries are bank-1 art, so per-entry banks are
  impossible. The three newcomer medallions need bank-1 homes from the
  measured blank pool (a mini option-B for ~18 tiles) or stay
  placeholders until then.

Session 14z-62h (maintainer playtest round 1 — two real bugs found and
fixed; program fingerprint UNCHANGED 39597268, gfx members corrected):
- STALE GROUP B RE-PACKED (the "Jedah completely garbled everywhere"
  report): pre-group-C group-B members left in build/<out>/gfx/ were
  globbed into vsav.zip; FBNeo served them, MAME hash-fell-back to
  ROMDIR-pristine and masked it (GOTCHAS x2). Fix: clean gfx outputs per
  build + a group-C-mode assertion that packed group B == pristine.
  Verified on a RESTRICTED rompath (no pristine reachable): Jedah select
  figure, match art (his ES super was the "white-red garble"), medallion
  and win art all restored.
- HOST-SLOT EFFECT-TAIL PLACES ("his portrait under the health bar seems
  to be Donovan's"): the HUD-mugshot (0x4D62->0x3DC8, Jedah's cells) and
  medallion (0xB10B->0xB526, Jedah's wheel-cell art) placements ran
  ungated at variant ids. Moved to effect_tail.json "place_host_slot",
  applied only at base-half tenants. Jedah's mugshot/medallion pristine
  at 0x13; frozen refs verified reproducing (ae701ffb / 9bac6ee3).
- Remaining KNOWN on Jedah at 0x13 (both die with option A): the
  mid-face horizontal band on his select portrait (group-A select-subset
  anchors clipping his face art — the maintainer's "wrong or shifted"
  band, confirmed on the honest path) and the tenant label placeholders.
- OPEN from the report, needs FBNeo re-test: the three new-cell
  medallions invisible + the cursor ring disappearing on Donovan's cell
  (MAME shows placeholder art + ring; may have been stale-collateral, or
  an FBNeo-side new-cell question — the report will arbitrate).

Session 14z-62i (maintainer round 2 — THE MEDALLIONS NEVER RENDERED, on
any build, ever; fixed. Scratch build 7f2b9d5a):
- The report ("not even as random pixels — the grid is vsav vanilla, SAME
  ON BOTH EMULATORS") was exactly right, and my earlier "placeholder
  medallions visible" claim had misattributed VANILLA bottom cells (the
  random '?' and Q-Bee's medallion). OBJ dump: the three entries WERE
  emitted every frame — at x=480-528, y=344-352, outside the 384x224
  screen. The select_wheel generator appended the layout's ring-centre
  positions VERBATIM into the coordinate list, whose pairs are RELATIVE
  to the wheel drawer object's base — measured (256,176), back-computed
  from Jedah's medallion pair (-20,-119) -> OBJ (236,57) and confirmed on
  Gallon's 3x3. Off-screen sprites are invisible to every RAM-basis gate
  and appear in OBJ RAM (so the frozen select-window divergences were
  REAL) — only a human looking at the screen could catch it.
- Fix: layout gains measured `obj_base` + `corner_offset` (-12,-7 =
  Jedah's empirical 3x2 corner shift); the generator converts pair =
  pos + corner_offset - obj_base. Verified: entries at (212,161) /
  (236,169) / (260,161), medallions render (placeholder art, the
  ratified interim).
- CONSEQUENCE, for the re-freeze bundle: the fix corrects the ratified
  wheel extension's bytes, so the frozen WIDE reference `9bac6ee3` no
  longer rebuilds from the tree (its zips remain valid artifacts; stock
  `ae701ffb` reproduces — no wheel there). Folds into the M3a re-freeze
  with the mirror-victim fix, per the maintainer's plan.
- THE "CURSOR DISAPPEARS" FINDING, now fully characterized: the
  highlight piece IS the cursor ring (the per-cell pal-0x1E ring art =
  the highlight records; measured — Demitri's ring tiles are his
  highlight record's entries). On the tenant cell the engine draws the
  COMPOSED vs2 record (his lit-label, b000) — visible but misplaced: the
  ring drawer's base tracks the hovered CELL through its own per-cell
  position source, which does not know the appended cells (label drawn
  at (152,88) instead of the cell). Queued with the option-A select-art
  session: find the drawer's position source + decide ring-vs-label
  content for the newcomer cells (a look-and-feel choice).

Session 14z-62j (option A phases 1-2 COMPLETE — the whole select family
serves from WIDE group C bank 5; scratch build 1464942a):
- All FOUR pieces native (portrait, name banner, VS splash, win quote):
  records keep vs2 codes, art copied vs2 -> group C upper bank at
  0x10000+code (146 tiles), select_tiles.json = ZERO group-A placements.
  The placeholder class is DEAD for these pieces (B22C/B2A5 etc. now
  real art in bank 5).
- Drawer bank gates, each measured before authoring:
  * portrait objects (FFB980/FFBB80): the select_pal thunk v2 (62j-1).
  * name objects (FFB900/FFBB00): thunk at the per-hover refetch
    0x5FCE0; v1 gated on d0 and NEVER FIRED (d0 is id*4 there —
    measured by bank tap), v2 gates via the live owner ptr
    (cmpi.b #TT,$382(a4)).
  * VS-splash consumer 0x6C0E0: gate on the object-cached id $A(a6).
  * win drawer (FFB800) rides the SHARED consumer 0x5F328 with
    d0 = winner+0x40 (measured at the win transition; its $A is NOT the
    id — measured 0). New TU substitution (tenant+0x40); the thunk
    writes ONLY on a tenant win (the object re-inits 0x2000 per screen;
    zero legacy RAM effect).
- MEASURED RESULTS (honest no-fallback rompath): Donovan — select bust,
  banner, VS splash all his real art in his colors from bank 5
  (a19=5xxxx verified per piece). JEDAH — select portrait COMPLETELY
  clean (the mid-face band gone), VS/match/win art all vanilla-correct
  (win screen: proper victory pose + quote). Group B pristine; group A
  now ADDITIVE-ONLY (the effect-tail engine-page families at verified
  free anchors — full-pristine vsav.zip needs the effect-band move,
  queued). All gates PASS incl. the 890-2362 acceptance window; stock
  reproduces ae701ffb throughout.

Maintainer round 4 (build 1464942a): JEDAH CONFIRMED INDISTINGUISHABLE
FROM VANILLA by human playtest — the visual half of the M3a acceptance.
One NEW finding, correctly outside the expected list: Donovan's
PRE-CONFIRM select sword in a wrong palette (11/12 dark grey, 1/12 deep
red — his real accent). Mechanism identified: the select sword's colors
ride the row-0x0C accent march; at 0x0F the in-place accent-slot
overwrites (weapon_accent_t0/t1) made EVERY march path show his colors,
masking that the pre-confirm marching object does not resolve an owner
link to the hovered id — so the accent thunk's tenant branch never
fires there. At 0x13 the slots are correctly vanilla (62c gating), so
the un-thunked path shows through as Jedah-grey. In-fight/post-confirm
correct (the thunked paths). Fix queued with phase 3: tap the
pre-confirm marcher's owner resolution, extend the 14z-31/47 fallback.

Session 14z-62k (the select-sword palette — maintainer round 4's finding,
fixed; scratch build 048521c2):
- Measured end to end: the figure upload (0x5F9B4+) reads the sprite
  palette table row [hovered id] UNMASKED (the 62c poke already feeds it
  the tenant's block) but uploads ONE row — pal base 0x15/P2 0x18 — and
  the sword sprites ride base+2, whose palette RAM held the INIT GREY
  RAMP (f111 f222 f333 ... — the maintainer's "very dark flat grey",
  measured verbatim in the RAM dump). At slot 0x0F the in-place accent
  slots masked the gap.
- Fix: select_sword_pal_variant_id thunk at the dest lea (0x5F9D0) —
  tenant hover also copies block+0x40 (the color-correct steady accent
  row, via the cached block+color ptr $40(a6)) into base+2's row with
  the copier's F000 alpha OR; P1/P2 dests by $381(a4). Verified: row
  0x17 = his accent row in palette RAM; sword renders colored; full
  gate PASS incl. the acceptance window; stock ae701ffb.

Session 14z-63 (phase 3 item 1: REAL MEDALLION ART — the wheel bank-5
move; evidence build 2c02213d):
- Mechanism measured first (tap + conditioned bank trace + chain decode;
  docs/game/atlas/select_screen.md "The wheel DRAWER"): the wheel drawer is
  $FFB800, its select anim chain is a single stop-flagged entry
  (0x2689FA), its bank word $FFB818 is written ONLY by the select init
  at 0x5F8B2 (`move.w #$2000,$18(a6)` — per-object; the shared attract
  loop 0x07C428 untouched), and the VS-phase re-init 0x5FD02 rewrites
  the field afterwards.
- Bytes: ONE code op — 0x5F8B2: 3d7c 2000 0018 -> 3d7c 3000 0018 (the
  immediate becomes bank_word(5)=0x3000; profile+group-C-gated via
  `[[select_wheel]] bank5=true`, skipped with a note when the tenant's
  gfx bank < 4, so the m5_wide 0x0F+WIDE shape keeps its placeholder
  medallions and rebuilds unchanged).
- Tiles: 103 into group C upper bank at 0x10000+code — 85 host tiles
  (every tile of every vanilla wheel entry, byte-identical from vsav
  group A; 85 = the record's budget word) + 18 vs2 medallion tiles (the
  appended cells' native codes b0f5/b108/b10b, 3x2 each). Zero
  collisions with the 271 existing bank-5 select-family tiles.
  Generator emits wheel_bank5.json; build_gfx_donovan --wheel-bank5
  places + readback-verifies both halves.
- Measured on build 2c02213d: the fmt-2 handler walks the relocated
  record with OBJ ffb800 BANK 3000; snapshot A/B vs build 048521c2 on
  replay 36 (frames 950/1150/1300): every changed pixel inside the three
  appended cells' box (rows 145-184, cols 148-243) — vanilla cells
  pixel-identical; the new cells show the real vs2 busts.
- Legacy consequence, mechanism-attributed: the §4 v3 bounded window on
  the host pick becomes 889-2415 (was 890-2362) — the bank-word write
  surfaces at the frame-889 sample, one frame before the old onset's
  record-pointer caches; divergence ends when 0x5FD02 rewrites $FFB818.
  Single run, 1305 identical frames after, match untouched. Frozen in
  test_tenant_select_records.sh §4; ratification folds into the pending
  re-freeze bundle.
- Gates: tests/test_wheel_bank5.sh NEW (static re-derivation incl. group
  C member identity straight from the zips, two negative controls, the
  engine's own bank-5 walk); tenant select-records + tenant-id PASS;
  stock rebuild reproduces ae701ffb.

Session 14z-63 addendum (phase 3 item 2: THE RING/HIGHLIGHT POSITION
SOURCE — found, and fixed in place; build e9f3286c):
- The source: the ring/highlight drawer ($FFBA00 — identified by walking
  the tenant's composed record) takes its per-cell base from a 32-row
  pc-relative word-pair table at PRG:0x5FAE2 (helper 0x5FAD0,
  `move.w d6,d0; lsl #2; move.w $5FAE2(pc,d0.w),$10(a6); ...$14(a6)`),
  indexed by the hovered cell UNMASKED. The variant half (rows
  0x10-0x1F) is a byte-identical ALIAS of the base half in vsav — the
  TABLE B convention — and vs2's own variant half is UN-ALIASED with
  its newcomers' bases (twin helper 0x6BC66, table 0x6BC78: rows 0x10
  (224,136), 0x11 (192,152), 0x13 (160,136)). So the misplaced-hover
  bug is an alias read, and the fix is Capcom's own move: overwrite
  rows 0x10/0x11/0x13 in place. 12 bytes, THREE code ops (pc-relative
  reads assert the PROGRAM function code — the stored bytes are
  encrypted, so data ops would corrupt them); row 0x12 stays reserved.
- The transform, measured on three independent cases (the misplaced
  bar, Jedah's row-0x0F ring, and the post-fix prediction confirmed
  exact): OBJ_x = base_x + coord_x + 64; OBJ_y = 224 - (base_y +
  coord_y). Bases in the layout (`highlight_base`, rule-5 table):
  derived from the row-0x0F reference so a ring-like record lands
  centred on the cell: base = (pos_x - 56, 248 - pos_y) -> 0x10
  (168,80), 0x11 (192,72), 0x13 (216,80).
- SEMANTIC CORRECTION for the pending hover decision: vs2's highlight
  ARRAY row 0x13 (the composed b000 5x1 record) is vs2's POST-CONFIRM
  NAME BAR (measured: drawn at the top corner at F1320+, never at
  hover), NOT a hover label. vsavj draws the array row at HOVER as the
  cursor ring (per-cell pal-0x1E ring records, all different codes).
  vs2's own hover highlight is ALSO a ring (pal-1e tiles measured
  around his cell). The three mirror/P2/P1 highlight blocks are ALL
  32-row aliased tables (mirror rows 0x50/0x53 alias safely — no
  crash path for a tenant mirror-hover).
- Interim shipped: the composed bar now draws AT the tenant's cell
  (measured OBJ (240,160), predicted exactly); cells 0x10/0x11 draw
  their alias rings at their own cells. The record CHOICE is the
  maintainer's (STATE decisions pending, with recommendation).
- Gates: checker gained the HBROWS section (aliased-site verification
  + per-row code ops + the reserved-row negative); tenant gate PASS
  (window 889-2415 unchanged — the rows are ROM, and legacy replays
  never hover extended cells); stock reproduces ae701ffb.

Session 14z-63 addendum 2 (phase 3 item 4: the variant-id HUD —
mugshot + name plate; build f7210898):
- ATTRIBUTION CORRECTED: the "VICTOR"/wrong-mugshot symptom was carried
  as the $130(a5)/0x00A43E fold (docs/game/atlas/id_space.md). Measured:
  neither HUD consumer reads $130(a5). The mugshot stager (0x8937C..)
  indexes table 0x89884 by $782/$b82(a5) UNMASKED; the name stager
  (0x89684) indexes 0x898C4 by $382(a4) UNMASKED — and both tables are
  32-ROW ALIASED, so id 0x13 read row 0x03's alias (Victor). The fold
  still owns the select/VS palette-block family (colours; still open).
- Fix (all variant-gated; stock byte-identical, ae701ffb verified):
  three aux_pokes (new only_variant_slot flag) fill row 0x13 of both
  tables — mugshot word 0x898AA <- 0x8690, name 8B 0x8995C/0x89960 <-
  0x868C0202/0xFFE80003 — and effect_tail gains place_variant_slot
  ('0x4D62,2,2' -> '0xBE90': the vs2 mugshot at a free-pool anchor,
  blank+unprotected verified in vanilla and built members; name art =
  the existing unconditional 0xBE8C placement). Jedah's own 0x3DC8
  mugshot cells stay pristine (checked by the gate).
- Live-verified in-match (replay 36, f3100): mugshot 0xBE90 2x2 attr
  0x112A at (200,32) + name 0xBE8C 3x1 attr 0x0202 at (144,40) — the
  exact 14z-49 measurement shape — with the opponent's mugshot still
  staging from the vanilla 0x3Dxx page; snapshot shows "Donovan" under
  the P1 bar.
- Gate: tests/test_tenant_hud.sh NEW (static re-derivation + host-cell
  pristineness + negative control + in-match staging), in the battery.

Session 14z-63 addendum 3 (phase 3 item 5: the variant-id WIN-SCREEN
palette — the sparse-block design built and both paths measured; build
e82e0bd3):
- The consumer (0x5F196..0x5F1F6, full disasm now on record): winner id
  UNMASKED in d6 ($382(a4) of the winner object); ids 0x12/0x18 take
  their OWN branches (color*5 + 0x352/0x35C — the reserved pair
  corroborated a third time); normal path = pool 0x3AD700 +
  (color*17 + id)*0xA0 -> 5 rows (0x15-0x19) via uploader 0x1C3A4,
  which ORs F000 alpha into every entry (measured against the 14z-45
  frozen hex). At 0x13 the index lands in the wrong color's slices.
- IMPORTANT SCOPING FACT (measured the hard way): the ARCADE win-quote
  screen (vs-CPU progression) NEVER runs this site — a conditioned
  breakpoint on the thunk saw zero hits through a full arcade match win;
  that screen is the 62j family and already renders the tenant
  correctly. Only 2P victories reach 0x5F1B6 — hence the two new
  permanent replays (61_tenant_2pwin / 62_tenant_2plose, P1-vs-P2 with
  one side idle; ~5.5k frames each). Also: victory-screen inputs SKIP
  the screen — a replay that mashes through it measures a blank.
- Fix ([[win_pal_variant]], variant-id builds only): a wide_ext sparse
  block laid out at the VANILLA color stride (8 sets of 0xA0 at
  0xAA0 apart; vs2 srcs 0x3C365C + color*0xB40, the 14z-45 verified
  addresses) + a 22-byte hole-a thunk at the base load: d6==TT ->
  a0 = block - TT*0xA0 (the vanilla arithmetic then lands each color
  on the tenant's set); else the displaced movea re-executes. CCR safe
  (movea sets no flags; the fall-through defines its own).
- MEASURED, both paths: tenant 2P win -> palette rows 0x15-0x19 ==
  vs2's Donovan color-0 set (F000-alpha) byte-for-byte at f5500+f5700;
  Victor 2P win over the tenant -> rows == the UNTOUCHED vanilla pool
  slice (color 0, id 3) at f5300. Stock reproduces ae701ffb; all other
  tenant gates PASS.
- Gate: tests/test_tenant_winpal.sh NEW (site/thunk/sparse-block
  re-derivation + negative control + both runtime paths), in the
  battery.

Session 14z-63 addendum 4 (maintainer round 6: Phobos/Pyron medallions
unreadable — REAL vs2 PALETTES for the newcomer medallions; build
f86fb1a0):
- Diagnosis: the appended entries' vs2 attr pal rows (0x13/0x11/0x05)
  are SHARED vanilla medallion rows on vsavj's select screen — the real
  art rendered under wrong palettes (Donovan legible by luck, the other
  two noise). Shared rows cannot be overwritten (vanilla medallions ride
  them), so the fix needs FREE rows.
- Free rows MEASURED two ways: OBJ pal-reference sweeps over select
  frames (3 replays: legacy pick, 2P, challenger join — restricted to
  frames where the wheel is actually on screen; an unrestricted sweep
  conflates screens) left {0x00,0x02,0x16,0x19}; a live poke-probe
  (rows forced to loud solids mid-select, snapshot pixel-diff vs
  baseline) changed ZERO pixels — decisive against scroll-layer
  sharing. 0x1A excluded (the P2-tenant sword row, 62k); 0x18/0x1C
  excluded (P2 figure / 2P-referenced).
- Sources: vs2's REAL medallion palettes found by matching vs2's live
  select palette RAM (f1250, de-alpha'd) into its ROM — Donovan
  0x3BAFDC (= the med_pal_row14 source, which retroactively explains
  that row: vs2 block base 0x3BAF3C + pal_row*0x20), Pyron 0x3BB15C,
  Phobos 0x3BB19C. Destination: vsavj select block A (base 0x3A3800,
  the wheel view's live copy) — rows 0x16/0x19/0x00 verified to load
  1:1 into palette RAM; row 0x02 does NOT (its live copy comes from
  0x3B5940) and was rejected.
- Fix (bank5/group-C builds only; layout pal_row/pal_src per cell,
  rule-5 table): the generator re-palms the appended entries' attr pal
  bits (Donovan->0x16, Phobos->0x19, Pyron->0x00) and emits three 0x20-
  byte data ports vs2 -> block A. Measured: live rows == alpha(vs2
  src) byte-for-byte at select; snapshot shows all three busts in
  native colors.
- LEGACY CONSEQUENCE, mechanism-attributed: replay 11 gains ONE
  transient divergent frame at 2836 — 8 bytes at RAM:$FF406A-$FF4071,
  the palette-FADE STAGING area (same family as the ratified $FF4182
  mask window, different slot): the transition fade stages the changed
  block-A rows through it for exactly one frame; byte-diff clean at
  2835/2837, 884 identical frames after, match untouched. The gate's
  section 4 becomes the measured §4 v4 COMPOSITE (window 889-2415 +
  flicker {2836}, compare_composite) — PENDING RATIFICATION in the
  re-freeze bundle alongside the window bounds.
- Gates: checker gained PALROWS (re-palmed entries + block A rows vs
  the vs2 image); all tenant gates PASS; stock reproduces ae701ffb.

Session 14z-63 addendum 5 (round 7: ALL CLEAN + the hover decision
RATIFIED and implemented — ring reuse; build 96a6e737):
- Maintainer round 7 (f86fb1a0): medallion palettes confirmed ("all
  good"), 2P victory screens correct both directions, no regressions.
  Noted for M5: the maintainer can now ear-identify some of Donovan's
  missing sfx (the known 25-stubbed-rows interim).
- HOVER DECISION (phase 3 item 3) ratified: RING REUSE. All three
  extended cells' hover highlight = the host's row-0x0F ring records
  VERBATIM (records encode no cell identity; the 0x5FAE2 base rows do
  the placement). Per-half refs: P1 0x2724A2, P2 0x2726CE, mirror
  0x2728E6 (all fmt-2, read from the vanilla arrays, never copied).
- Implementation: [[select_records]] highlight becomes art="host_ring"
  (the composed vs2 record was vs2's post-confirm NAME BAR — the wrong
  piece; composition dropped, 2 pokes instead), and the wheel section
  gains ring_rows (P1+P2 rows for the non-tenant cells 0x10/0x11 +
  MIRROR rows for all three; each half's 32-row aliasing verified
  before poking). 9 poke32 total, zero new bytes placed.
- check_tenant_select.py: highlight piece re-modeled (host_ring branch:
  extended-cell rows == the per-half ref, all other rows vanilla,
  mirror block included); the gate's runtime highlight sequence follows
  the checker's ROW value automatically and PASSES — the engine
  fetches 0x2724A2 on cell 0x13.
- Snapshot: the tenant hover now draws a real vanilla-class cursor
  ring around his medallion (Jedah's 3x2 outline — per-cell authored
  rings can supersede later without rework). All tenant gates PASS;
  stock reproduces ae701ffb.

Session 14z-63 addendum 6 (phase 3 item 6: the accent/march audit —
CLOSED; round 8 all clean):
- Maintainer round 8 (96a6e737): rings on all three cells + mirror
  rings both sides confirmed, "Donovan is looking really good."
  KNOWN-COSMETIC, deliberately parked (maintainer: polish can wait,
  possibly forever): Phobos/Pyron medallions sit a few px right —
  fixable by nudging the layout cells' `pos` x (one edit moves the
  medallion and its highlight base coherently).
- STATIC CENSUS: the vanilla opcode image holds EXACTLY FOUR accent
  family-base (0x39A900) operand references — 0x2AD82/0x2AD94/0x2B342/
  0x2B7E8, the four accent_color_aware sites, all jsr-routed on
  variant builds — and ZERO direct references to the T0/T1 slots
  (0x39FBE0/0x39FC00). No un-thunked family consumer exists.
- VENUE SWEEP: every tenant-visible accent surface is measured or
  playtest-confirmed (rounds 3-8) — select pre-confirm (62k thunk),
  post-confirm march (14z-47 owner-link fallback), VS splash (62j),
  in-match (own block row), 2P victory (item 5), arcade win-quote
  (62j family), HUD (item 4). The solo CONTINUE screen was chased to
  frame 13100 (idle tenant loses to the CPU): it is the abstract
  vortex + countdown — NO character surface exists there, so nothing
  to port. The 2P continue is a HUD text countdown only.
- Gate: tests/test_accent_census.sh NEW (frozen 4-site census + 0
  slot refs + 4/4 routing + negative control), in the battery. A
  fifth family-base site appearing in a future image fails loudly.
- PHASE 3 IS COMPLETE (items 1-6). Remaining before the M3a close:
  the select/VS palette-block colours (the real $130(a5) fold work,
  venue_assets.md §2) and the RE-FREEZE bundle (maintainer sign-off).

Session 14z-63 addendum 7 (round 10: Phobos nudge; the medallion
WHITE-OUT root-caused and PARKED; build b9c6ca23):
- Phobos 2px further left per maintainer (pos 216->214, ring-fit over
  lattice-fit — ratified trade); highlight base moved with it.
- WHITE-OUT root cause (the maintainer's "shades of white" report):
  Donovan's medallion row 0x16 belongs to the P1 FIGURE FAMILY
  {0x15,0x16,0x17} which the accent march claims in a late select
  venue phase (~15 s in; the pulsing silver sword ramp — invisible on
  vanilla because nothing references the row there). The trigger is
  the select timer, which is why it seemed random. Reproduced
  deterministically on a long moving-select (replay 63, onset ~f1750).
- THREE fix designs measured, all rejected on legacy grounds (detail
  in GOTCHAS "no such thing as a free palette row"): (1) per-frame
  re-assert — the fades read back palette RAM, step counters at
  $FF0E94-family diverge permanently; (2) dest-computation retarget at
  0x2AD44 — bypassed by direct store-tail entries; (3) the 3-call
  triplet thunk — the tail has ~30 enumerated entry points; covering
  all (or thunking the hot tail, which serves matches too) risks the
  frozen flicker inventory. The correct fix is the marcher's JOB-DATA
  origin (the venue row-list datum, 14z-15 script family) — QUEUED.
- Parked state: rows 0x00 (Pyron) and 0x19 (Phobos) hold through the
  maximal select (gate-frozen); row 0x16 whites out after ~15 s on
  select, resets on screen re-entry — select-scoped known cosmetic.
  ALSO flagged: row 0x19 is P2's figure-family middle row — the same
  mechanism may claim it in long 2P selects (unmeasured; the job-data
  fix should relocate all three rows' ownership properly).
- Gates: wheel gate section 3b freezes the honest state (0x00/0x19
  full-life, 0x16 at f1200 + parked-note); all tenant gates PASS;
  stock reproduces ae701ffb.

Session 14z-63 addendum 8 (round 11: the mash-right repro COMPLETES the
white-out mechanism; Donovan moved to the bulletproof row; build
bd7772c9):
- Maintainer protocol (mash RIGHT on the grid, white after 4-5 inputs,
  plus per-input "shimmer") identified the SECOND writer: the marcher's
  per-hover path — the 0xEF92EF96 char-class test at 0x2ADB8 sends
  roughly half the roster's hovers through the family triplet, which
  rewrites rows {0x15,0x16,0x17} on EVERY such hover (the shimmer =
  those rewrites). So row 0x16 has BOTH a periodic venue-phase writer
  and a per-hover writer: it is thoroughly owned, and no hover-time
  hook can hold it (the phase writer re-pulses continuously).
- Interim (rows reassigned in the layout): DONOVAN -> row 0x00, the
  single row proven stable against hovers, phases, fades, and the
  maximal select; Pyron (placeholder) -> 0x19; Phobos (placeholder) ->
  0x16, inheriting the white-out until the job-data fix. Measured on
  the maintainer's own protocol (new permanent replay
  64_select_mashright): Donovan + Pyron hold every sample; Phobos
  whites by f1100 as predicted.
- Gate 3b re-frozen: both stress protocols (maximal select + mash
  right), rows 0x00/0x19 asserted across all samples, row 0x16
  documented-unowned pending item 0. Stock reproduces ae701ffb.

Session 14z-64 (item 0: the WHITE-OUT RETIRED — the mid-row march
retarget, complete by census; build 210d2b75):
- The final mechanism: the marchers write the figure-family MID ROWS
  (0x16 P1 / 0x19 P2 — referenced by NOTHING in vanilla, pure
  vestigial writes) through exactly THREE dest computations, found by
  the add+lsl#5 idiom census over the uploader region:
    0x2AD44  d0 = $18B(a6) + d1   (the d1-carry family)
    0x2B598  d0 = $18B(a6) + 1    (the venue-phase writer)
    0x2B7D8  d0 = $F(a6)   + d1   (the per-hover writer — per-char
             jump table 0x2B640 keyed on $382(a4); found by an
             execution trace triggered on the live clobber after two
             static guesses missed: the tail's d0=0xC0 remnant proved
             a sibling computation)
  Each is a 6-byte site (load+add) jsr-routed to a thunk that
  redirects d0==0x16/0x19 to the scratch row 0x02 (invisible on
  select, like the mid rows themselves). No work-RAM state, pixels
  unchanged on legacy (unreferenced rows either way), cycles on the
  already-hooked march path only.
- MEASURED: all three medallion rows hold the vs2 palettes through
  BOTH stress protocols (maximal select + mash-right), 15/15 samples
  in the gate; the Phobos interim is retired.
- LEGACY BONUS: the fade-staging flicker at 2836 VANISHED (the
  marchers no longer write the changed rows on select, so the
  transition fade never stages them) — replay 11 reverts to the plain
  §4 v3 bounded window 889-2415, re-frozen in the gate; one less
  class for the re-freeze ratification.
- Gates: wheel 3b asserts all three rows across both protocols (a
  fourth census site appearing fails the build); full tenant sweep
  PASS; stock reproduces ae701ffb.

Session 14z-64 (continued): the RE-FREEZE BUNDLE prep — mechanics
applied, awaiting maintainer ratification:
- MIRROR-VICTIM FIX (the 14z-2 defect, parked since 62c) APPLIED:
  data_port throw_victim_keyframes gains `fixes = "0x1E:0b30:0d88"`.
  Byte-attributed: the stock candidate differs from frozen ae701ffb by
  EXACTLY the two bytes PRG:0x0B1A16 (0b30 -> 0d88). Behavior-
  attributed with a matched control pair on NEW permanent replay
  65_don_mirror_throw (both players slot 0x0F — P2's path is U,U,U
  from ITS default cell 0x05, BFS-derived from TABLE B; P2's default
  is NOT P1's): candidate reads the Donovan-victim block 206/0, the
  frozen build 0/206. NEW gate tests/test_don_throw_mirror.sh (static
  word + the control pair; SKIPs on variant builds — correct by
  construction there), in the battery.
- id_by_profile = "cps2-wide-v1=0x13" DECLARED: profile builds now
  default to the native id with no flag; tests/test_tenant_id.sh check
  2 flipped per its own design note (now guards the DECLARATION —
  losing it would silently rebuild the WIDE track at 0x0F).
- MID-ROW RETARGET v3 (the 14z-64 defect found by the bundle's own
  measurement sweep): the v2 thunk on 0x2AD44 sat on the in-match
  accent funnel and PERMANENTLY flipped a frame-boundary parity
  (replays 04/05 diverged to EOF as one stuck byte, $FF8094 — GOTCHAS
  "flicker's evil twin"). v3 thunks ONLY the two measured select
  mid-row writers (0x2B598, 0x2B7D8) and gates the redirect on the
  select screen being live ($FFB818 == 0x3000, the wheel drawer's
  bank word). Measured: medallions still 15/15 stable on both stress
  protocols AND replay 04 back to its EXACT original composite shape
  (flickers 1525/2009/2195, window 889-1104).

Session 14z-64 (continued 2): the medallion FINAL ROW ALLOCATION and the
V2 masked basis (build 4b7d0dc7):
- The bundle's own measurement sweep found TWO more medallion-row
  defects, both fixed:
  * Row 0x00 LEAKS: block-A row 0 feeds the GAME-OVER starfield
    (measured: 1210 candidate-vs-vanilla pixels on the f11800 game-over
    screen of replay 05 — a legacy pixel violation). Reverted.
  * The palette STAGING AREA identified (docs/game/atlas/ram.md): slots at
    $FF3F02 + row*0x20; the ratified $FF4182 window IS row 0x14's slot
    from the 14z-49 port. Any edited block-A row leaves a sticky
    designed diff in its slot (replay 05's f9126+ tail anomaly).
- FINAL ALLOCATION: all three medallions on thunk-protected vestigial
  figure-family MID ROWS — Donovan 0x16, Phobos 0x19, Pyron 0x1A. The
  two select-side dest thunks redirect marcher writes to all three
  (select-gated). KNOWN RESIDUAL (documented trade): row 0x1A doubles
  as the P2 sword-accent row — a 2P Donovan-hover recolors Pyron's
  PLACEHOLDER medallion until screen re-entry.
- V2 MASKED BASIS (pending the bundle ratification, the round-64
  window's siblings): masks the three medallion rows' staging slots
  ($FF41C2-E1 / $FF4222-41 / $FF4242-61). The vanilla masked logs are
  REGENERATED deterministically from the frozen vanilla oracle under
  the v2 basis into tests/expected/vsavj/masked-v2/; run_suite gains
  per-expectation-set masks (old sets keep the round-64 basis — the
  stock track needs no change, verified: its battery ran green with
  the frozen inventories under the old basis).
  - 14z-88 FOLLOW-UP — V3 MASKED BASIS (maintainer-ratified 2026-08-15,
    applied 14z-88): the 14z-87b medallion move (Pyron's wheel pal_row
    0x1A -> 0x1D) moved his medallion's STAGING slot to $FF42A2-C1, outside
    V2 — the three suites went red on exactly that slot (byte-attributed:
    f5000 live diff 0 bytes, f11000 = 30 palette words in $FF42A2-BA).
    Mask entry `42a2-42c2` added to donovan-m6 / huitzil-m14 / pyron-m8;
    vanilla basis regenerated as tests/expected/vsavj/masked-v3/
    (tools/freeze_masked_basis.sh — instrument control: reproduces a v2
    log bit-for-bit under the v2 mask); .masked specs re-based with their
    classes UNCHANGED (11 on the solo Donovan set ratified to composite
    2836 889-2415); the moved tenant-content .sha1s attributed by
    tests/audit_mask_window_ff42a2.sh BEFORE any re-freeze — which found
    the 38 legacy regression (STATE 14z-88 decision) and so NO .sha1 was
    re-frozen. Lessons: "the palette path never transits work RAM" is
    true of the palette write and FALSE of the staging copy — a
    palette-row move is a mask move; and palette CONTENT in a fade's row
    set is cycle-relevant on a frame-critical transition.
- Measured on the final candidate: all three medallions stable through
  both stress protocols (15/15); the game-over screen pixel-identical
  to vanilla; the 14-replay sweep clean except the staging slots (v2
  masks them by design).

## Session 14z-66 — EX-move crash-reset fix: three farm-voice stubs
## (playtest round-1 item 1; manifest-data only, no machinery)

Change: THREE `[[map]]` rows appended to
build/manifest/reconciliation_huitzil.toml (H overlay; the shared map
untouched, Donovan's builds unaffected by construction):
  vsav2 0x004efa -> vsavj 0x02a7e0  stubbed_sound  (sfx id 0x748)
  vsav2 0x004fb0 -> vsavj 0x02a7e0  stubbed_sound  (sfx id 0x729)
  vsav2 0x004fca -> vsavj 0x02a7e0  stubbed_sound  (sfx id 0x72e)
Ids disasm-verified from the farm stanzas (jsr 0x330E; move.l #id,D1;
bsr 0x5122; jmp 0x3306) in vsav2 opcodes view. All 0x7xx newcomer
voice range = the established stub class (six precedent rows).

Byte effect on the stage-4 build (117 -> 114 ops): the three ILLEGAL
tripwire words at hole_a 0xf8720/0xf8730/0xf8740 are no longer
emitted, and the three referencing jsr operands now carry 0x02A7E0
(engine rts) instead of tripwire addresses:
  x067846+0xd2  (was -> 0xf8720)   [family sweep; never seen to fire]
  x067846+0xec  (was -> 0xf8730)   [family sweep; never seen to fire]
  x0689cc+0xec  (was -> 0xf8740)   [the shared one-shot voice cue:
                                    tst.b $23(a6); clr.b; jsr]
Fingerprints: pre-fix e8d95a5c (crashes: ES f3513, FG-connect f3364,
both vec4 at 0xf8740), post-fix 01f6f907 (both EX moves fire to
completion repeatedly; stock 9->6 on the FG-connect replay).

Repro/validation artifacts: replays tests/replays/hui/71_hui_ex_fg.rpl
(mid-range control — clean even pre-fix: a whiffing FG never reaches
the cue), 72_hui_ex_es.rpl, 73_hui_ex_fg_close.rpl; gate
tests/test_hui_ex.sh (guard-clean AND stock-decrement so the coverage
cannot silently evaporate — the 14z-44 lesson).

## Session 14z-66 — velocity port (playtest round-1 item 2): param32
## rows 0x10 + the per-tenant VALUE_SKIP default

Mechanism (measured before any change): both vsavj param32 tables are
32-ROW — rows 0x10-0x1F byte-identical aliases of 0x00-0x0F
(param32_a 0x0BD87A, param32_b 0x0BE2FA, rec8) — and all three
consumers (0x228e2/0x271a8 read a, 0x26484 reads b) index the RAW
+0x382 id via ext.w/lsl #3 with NO fold. Tenant 0x10 therefore read
the alias CONTENT = Bulleta's row 0 — the measured mechanism behind
"feels a bit slower". A write at row 0x10 is a variant row: legal
under the op invariant, zero consumer work.

Changes:
- tools/gen_donovan_patch.py: VALUE_SKIP (the 14w-b crash guard)
  became a per-tenant DEFAULT — [[tenant]] port_param32 = true opts a
  tenant in; absent flag keeps the skip (Donovan's manifest carries no
  flag, so his bytes are unchanged — m3a reproducibility gate PASS).
  normalise_tenants passes the key through.
- build/manifest/huitzil.toml: port_param32 = true.

Byte effect (fingerprint 3a172c52, 114 -> 116 ops): two data ops,
  0x0BD8FA +0x8 = 00032000 fffd4000  (param32_a[0x10] — his true pair:
                                      fwd 3.125 vs alias 3.0, back equal)
  0x0BE37A +0x8 = 0001a000 fffdc000  (param32_b[0x10] — fwd 1.625 vs
                                      alias 2.0, back -2.25 vs -2.75)
Vanilla rows 0x00-0x0F untouched (verified from the built zip's data
view).

Verification: NEW gate tests/test_hui_walk.sh — static rows + the
walk-speed replay 74 (16.16 X deltas over two 15-frame windows before
push-box contact: frozen 0x1C2000/0x384000; the alias build measures
0x1B0000/0x360000 — both windows scale by exactly 25/24 = his fwd /
alias fwd; the walk anim runs a 0.6x/1.2x phase profile, hence the
window asymmetry). The 14w-b hazard RE-EXAMINED for H, second half:
full battery GREEN on the ported tree including the 11k chaos soak
(Donovan's 14w-b crash was at soak f10050 — H shows no analog) + EX
gate + boot masked-v2 EXACT + m3a-reproducible.

## Session 14z-66 — the second FG crash: shadow_seq_guard site thunk
## (round-2 report; the capture-anim shadow over-index)

Root chain (every link measured; instruments: replays 77 + the pair
matrix, GUARD_TRACE 3396-3398, taps, native A/B snapshots):
- Final Guardian is a CAPTURE-class transformation super (native: the
  giant + 7-hit barrage; pieces = poolB secondaries types 0x75/0x77 —
  correctly relocated on our build, cursor byte-exact).
- The per-player SHADOW/REFLECTION servants (class-0x0C trio, spawner
  0x489DE+, installer 0x8237E+) mirror a linked character's anim by
  reading each anim NODE's +0xC word: low 13 bits = a seq id into the
  SHARED shadow tables 0x2083BC/0x2087CA (row space 0x40E each,
  hardcoded at 0x823E2/0x823F2 — NOT per-char; sequence data follows
  at 0x208BD8). Node stride 0x18; walk site 0x8245C -> engine
  installer 0x1508A.
- H's ported anim nodes carry VS2 seq ids; the FG capture anims carry
  0x488 (valid in vs2's larger table at 0x1E42D2, found via the twin
  installer vs2 0x90B08). On vsavj, word[0x488] lands in sequence
  DATA: fetched 0x0021 -> odd cursor -> vec3 f3398 at 0x15098.
- THE VICTIM'S servant crashes, not H's: capture supers make the
  victim play ATTACKER-supplied nodes (measured: crash servant owner
  id 0x0C = P2). A first-attempt owner==tenant gate missed exactly
  this (build 22ea24f9, kept as the negative lesson in the manifest
  comment).

Fix (build 44be1266): [[site_thunk]] shadow_seq_guard in huitzil.toml
— site 0x8245C (old 4ef90001508a, the walk jmp) routed via a
stack-neutral jmp (NEW patch="jmp" emitter option) to a 14-byte body:
  cmpi.w #$40e,d0 ; bcs.s vanilla ; moveq #0,d0 ; vanilla: jmp $1508a
Unconditional by design: no vanilla content can produce seq*2 >= 0x40E
(it would vec3 on vanilla hardware), so legacy behavior is invariant
by construction; the clamp serves any tenant's out-of-range ids
(capture victims included). Clamped seq 0 = the default shadow every
sparse vanilla row already falls back to; the +0x50 cache keeps the
raw id so the walk does not thrash. RESTORE AT THE GFX PASS: same
site, extended table instead of clamp.

Generator changes: site_thunk block gate 6 -> 4 with per-row default
stage raised to 6 (all existing rows declare stage explicitly — no
emission change for Donovan at any stage; m3a gate PASS), and the
patch="jmp" option (guarded: old_hex must be a jmp).

Measured fixed: replay 77 (whiff/mid FG) guard-clean END 4720, stock
9->8, snapshots show the full native sequence (FIRST ATTACK -> the
7-HIT barrage, matching native's hit count). test_hui_ex.sh gained
replay 77 as section 3.

## Session 14z-66 — the THIRD FG crash: embedded data tables in
## crypt-placed code (data_in_code mechanism + census)

Maintainer round 3: FG "still crash-resets, a bit later after the
capture" on 44be1266 (the shadow guard held — this was a THIRD site).
Repro (after plain/kill/victim variants stayed clean): FG + a
deterministic post-capture chaos block (replay 78) — vec3 f3892 at PC
0xC8156, inside the ported x026142 copy: the capture-victim anim
installer walking a VANILLA per-victim capture table (the 0xBCE7A+
Midnight-Bliss-family sets) with seq D0=0xFF.

Root (trace-caught, the whole chain): his FG picks each barrage hit's
victim pose RANDOMLY — seq = table16[rand&15] via engine RNG 0x14E8A —
from a 16-byte DATA table EMBEDDED IN HIS CODE (vs2 0x56074, read
`lea (0x26,pc),a1; move.b (a1,d0.w),d0`). The code region sits in the
crypt hole: placed bytes are stored re-encrypted for opcode fetches,
so the runtime DATA read saw garbage — 0xFF drawn where native reads
01/03/05 (vs2 data view: 01050305050305010305010505010503). Garbage
seqs over-ran the victims' capture tables with per-victim/per-draw
crash signatures; safe draws = clean casts. THE RANDOM DRAW is why
three repro campaigns produced three different-looking crashes and
several clean runs.

Fix: NEW generator mechanism [[data_in_code]] (generalized 14z-20
class, region form): relocates the table's SOURCE-DATA-VIEW bytes to a
raw hole and reroutes the placed reader through a 12-byte helper
(lea abs,An + the verbatim read op + rts; site = jsr helper + nop —
ghost-clean, the read op sets NZ identically). Supported shape:
lea(d16,pc),An + any move.b/w/l via (An,Xn.w).

CENSUS (the class had bitten three times, so: scan of ALL crypt-placed
region bytes for the shape with in-region targets): FIVE instances —
the FG table + 0x56064/0x5649C (the 0x56-0x59 pose set), 0x564AC
(01/03/05 twin), and x088512's 0x8C042 (a word offset/record table the
POD code re-derives a3 from; self-relative, copied 0x100). All five
rerouted in one build. Fingerprint 4317353c; helpers/tables in hole_b.

Measured: replay 78 clean in BOTH timelines; full battery GREEN
(boot masked-v2 EXACT — the reroutes are tenant-code-only; m3a
bit-exact — the mechanism is manifest-driven, Donovan has no rows).
Gate: test_hui_ex.sh section 4 (replay 78 + stock assertion).

## Session 14z-66 — AIR MOVEMENT LIVE (item 3): the per-char jump
## handler clone + the x026142 escape fix

Continuation of the float arc (see the previous entry + STATE 14z-66).
After the float landed, the air dash (66 during the float) dispatched
into his own air-dash physics setter (vs2 0x586F0: xv/yv/gravity
installs, byte-faithful in the x057456 copy) but crashed vec4 at a
mid-instruction address. The trace showed the REAL fault one level up:
the air-dash SEQ STARTER (vs2 0x26E14, inside the x026142 shared-zone
copy) ends with `bra.w` back to the engine stepper — an
oracle-invisible pcrel escape THE x026142 REGION HAS CARRIED SINCE
14z-65. Its other escapes were never reached (or wandered benignly);
the air-dash flow was the first to die on one.

Fix: [[pcrel_escape_fix]] extended to x026142 (7 unique escape
targets, 9 sites -> 6 trampolines + pad 0x60). Targets resolved by the
SITE-TWIN method (per-site interpolation between bracketing known
pairs, reading vsavj's own branch at the twin site): 0x210C0->0x226DC,
0x219C4->0x22FC0 (two sites agree), 0x21C64->0x23244 (two sites
agree), 0x22008->0x23500, 0x25F9A->0x26E16 (unique exact-16),
0x27542->0x282EE (the region-end fall-through), and 0x24CBA->0x26058
(unique wildcarded match; the neutral-reset family). Rows in the H
overlay.

Measured (build 2898c495): jump -> float hover at 109.4 -> 66 -> seq
0x1400 with X +119.6px over 15f at dy=0 (the flat accelerated air
dash) -> dash end -> gravity fall with carry -> landing sub-state ->
grounded. NEW gate tests/test_hui_air.sh (float: Y pinned >= 100px;
air dash: seq byte 0x14 at +0x06 + >=30px flat advance — mode
signatures, not just no-crash). Full battery GREEN incl. boot
masked-v2 EXACT and m3a bit-exact. build/hui4 = 2898c495 (ping #5:
float + air dash + all prior fixes; flavor default now VS2-correct
per measurement — Start-hold selects the other flavor, so D1 is
playtestable for the first time).

## Session 14z-66 — the alias-physics port, first row: jump_params
## (the float ceiling + jump feel)

The one family behind the remaining feel deltas, first consumer
decoded and ported. The JUMP-PARAM INSTALLER (vsavj 0x27A34, vs2
0x26C86 — the routine every seq-0600 starter bsr's) computes id*0x30 +
variant offset (0/0x10/0x20 = neutral/forward/back) into the per-char
jump table (vsavj 0x0BDB7A, vs2 0xD7D18 — EXACTLY the bank-origin
delta, validating the bank scheme), RAW id, no fold. Rows = (xv.l,
xacc.l, yv.l, gravity.l). The vsavj table is 32-row with 0x10-0x1F
byte-aliasing 0x00-0x0F (dumped; ends exactly at the known 0x0BE17A
table), so H's row 0x10 is a superset-safe variant write.

Change: bank_map [[table]] jump_params (rec8, stride 0x600) +
VALUE_SKIP gains "jump_params" (the 14w-b physics caution class;
port_param32 tenants port it — Donovan flagless, bytes unchanged,
m3a PASS). Build 8bea919e emits ONE op: data 0x0BDE7A +0x30 (his
three rows: neutral yv 8.0/grav -0.375 vs the alias 6.75/-0.4375).

Measured: the float ceiling moved 109.4 -> 121.1 = NATIVE EXACT, with
the native rise curve; oracle-battery mismatches dropped 1770 -> 1741;
every gate green (air-gate sample frames retuned to the native rise —
the old frames were calibrated to the alias climb). Residual known
delta: the GROUND dash (ours ~7 vs native ~8.2 px/f) — its per-char
param consumer is not yet decoded; next row of the same family.

## Session 14z-67 — the H gfx rung (D4 opener 3): every byte class, and
## where the detail lives

Build hui6 = b99b7359 (stage 6, 0x10, profile cps2-wide-v1). Per-op
byte detail: `build/hui6/patch/patch_notes_fragment.md` (generated,
op-exact). The manifest-level record:

- **12 OBJ bank setters** (`[[port_patch]]`, huitzil.toml): every
  `move.w #$6000,$18(aN)` in H's ported regions -> `#$1000` (WIDE bank
  4) on the variant build. Sites from a fresh scan (opcode
  `(w & 0xF1FF) == 0x317C`, imm 0x6000, disp 0x0018): x057456 0x5938C;
  x05c800 0x5CF38/0x620D4/0x62194; x088512 0x8873E/0x89D26/0x8B100;
  x06800c 0x68360/0x683A2/0x683EA/0x6842E; x0692f6 0x69490. Donovan's
  six shared-zone rows reproduce as the exact subset (scan validation).
  One near-miss triaged: 0x8BF1A writes #$6000 to +0x1A (the X word),
  not a bank — left alone.
- **[table_fix]** x026142+0x13EE: vanilla vsavj rows EXCEPT row 0x10 =
  0x1000. **[[code_word]]** obj_bank_word_slot: vsavj 0x282D4 row 0x10
  (variant-alias anchored) -> 0x1000.
- **[[palette]] x2**: sprite block vs2 0x39BC9C len 0x500 (head
  0111 0630 0a40 0c60), effect block vs2 0x3AB69C len 0xDC0 (head
  0503 0704 0815 0947), tables 0x38C198/0x38C218 + extra 0x38C258 —
  the Donovan template with H's blocks (pointer-table rows 0x10,
  strides 0x500/0xDC0 verified across rows 0x0F-0x13).
- **Seven [[select_records]]**: same array bases as Donovan's (the
  arrays are engine-global; the generator indexes row = tenant id).
  H's vs2 rows: portrait 0x2A5E4A/0x2A625A, name 0x2A64D6/0x2A7506,
  splash 0x2A7B06/0x2A7E36, win_quote 0x2A881E; vj alias rows = row
  0x00's records (verified equal). Highlight = host_ring; vs2's
  newcomer highlight rows hold sentinels 0x5000000/0x4000000.
- **Drawer bank thunks**: name/splash/winquote rows verbatim (tt/tu
  substitution follows the manifest's tenant).
  **select_pal_variant_id**: H has NO dedicated palette block — vs2's
  uploader remaps id 0x10 INTO the shared grid at column 0x0B
  (`cmpi #$10 -> moveq #$B,d6`, vs2 0x6B1A6; grid base 0x3C117C, row
  = (variant*16+id)*0x20). His 10 rows = 0x3C12DC + v*0x200, gathered
  contiguous by the NEW data_subst form `x10@0x200`.
- **HUD rows**: vs2 DATA-view entries (name 0x9910E row 0x10 =
  04AB 0102 FFE8 0002; mug 0x990CE row 0x10 = 05A0; vs2 stager bias
  +0x4200 -> art 0x46AB 2x1 / 0x47A0 2x2, non-blank verified). Pool
  anchors 0xBE92 (plate) / 0xBE9A (mug; bottom row 0xBEAA-AB). Pokes:
  0x898A4=0x869A, 0x89944=0x86920102, 0x89948=0xFFE80002 (vsavj bias
  -0x3800). Art rides effect_tail `place_variant_slot_huitzil` (the
  NEW per-tenant key — the generic key would leak H's art into
  Donovan's builds and break m3a bit-exactness).
- **[[win_pal_variant]]** hui_win_pal: vs2_src 0x3C347C (= vs2 pool
  0x3C2A7C + 0x10*0xA0; head 0x0111... = his palette family), same
  site/pool/strides as Donovan's row.
- **[[select_wheel]] roster21**: verbatim — the 21-cell extension is
  tenant-independent (cells 0x10/0x11/0x13 from the layout json).
- **[[pcrel_escape_fix]] x05c800** (stage 4, pad 0x20): the census
  find. Sites 0x631D0/0x631D8 (`tst.b $18E/$134(a4); bne.w 0x635FC`);
  target does `subq.b #1,$149(a4); jmp <engine>`. Resolution: vsavj
  0x5B25C — UNIQUE pattern match, jmp targets twin-verified (vs2
  0x15770 / vsavj 0x17028, 60/64 bytes, diffs = A5-operand drift).
  Recon row in reconciliation_huitzil.toml.

Machinery (all Donovan-bit-exact, m3a-reproducible run at every step):
per-tenant layout resolution (gfx_layout3.toml rows by tenant NAME —
the id differs per track), the delta-0 placement path, per-tenant
effect_tail keys, the data_subst gather form, verify_gfx_build
de-Donovanized (span/aux/sweep per tenant), obj_records entry-bounds
check + per-tenant sweep windows (inventories re-frozen H 15,034 /
P 14,225; Donovan unchanged 15,612).

## Session 14z-67b — the ping-round fixes (byte detail)

Builds: hui7 93c9aa44 (c5), hui8 59cf9f85 (+byte map), hui9 9e3105e0
(+throw arc = PING #8). Per-op detail in each build's generated
patch_notes_fragment.md.

- **Effect byte-map rows** (hui8; huitzil.toml aux_pokes
  effect_map_4e4f/5051/5253): DATA 0x28D4E..0x28D53 <- 0F1B 1F19 0F03.
  The id->handler-index map (vj DATA 0x28D00 / vs2 0x27FD8) is
  byte-identical through id 0x4A; vs2's six live entries at 0x4E-0x53
  read zero on vsavj -> every newcomer effect collapsed to index 0.
  Also divergent (not poked): id 0x5F (vs2 0x00 / vj 0xFF). The
  per-char record rows needed nothing (bank_map anim_index_a/a2/b rows
  0x10 already repointed; verified on the built image). Restores the
  236P ray SPAWN (visible but brief/wrong-palette — the segment
  behavior needs the zone flow).
- **c5 mode** (hui7; generator + build_gfx): delta-0 group-C tenants
  keep companion-record bank-1 words NATIVE; effect_c5.json (5,714
  codes) places the art at native codes in group C bank 5; three
  ported spawner setters flip #$2000 -> #$3000 (x088512 0x8B224/
  0x8BF14/0x8BF52). Corrects hui6's wrong-art remaps (records at
  x2b7ef4+0x900C carried effect_tail anchor words 0x0FE7+ where
  native reads 0x0FA0+).
- **Throw-arc superset tables** (hui9; site_thunk throw_arc_tables,
  patch=jmp+jmp_ok at vj 0x28386): full tail replacement of the
  physics-row installer reading PLACED copies of vs2's map1 (0x54B
  from 0x279B4) + table2 (0x370B from 0x27A08). Statically proven
  strict supersets (map1 prefix 0-0x49 and rows 0-0x31 byte-identical
  across the games) -> serves ALL throws unconditionally; boot
  masked-EXACT confirms. vs2's five extra map entries -> rows
  0x32-0x36 (63214 arcs rows 0x33/0x34: yv 16.0/20.0, gravity
  -0.688). Measured: launch yv 0x0010 == native, decay lockstep
  (FBNeo tap A/B on the 2P replay).
- **The effect zone + fleet spawners** (regions x022400 = vs2
  0x22400+0x1600 t+0x2E, x06d240 = 0x6D240+0x500 t+0x174) with
  escape pads (0x180/0x60) and recon rows: stage-2 installer twins
  0x2710C/14/1C -> 0x27EB4/BC/C4; byte-map data rows 0x27FD8/DA ->
  0x28D00/02; per-char pointer table 0xD96B8 -> 0xBF51A
  (shape-matched; per-game pointer content). ENTRY THUNKS PARKED
  (seq_d_dispatch: the real entry, regresses the ray pending the
  flow's dependency closure; effect_machine: wrong entry, hot for
  legacy). The parked bodies + anatomy live as comments in
  huitzil.toml.

## 14z-70 — the ground explosion, and one inert repair

**`extra_tiles/0x10.json`: 2 -> 569 tiles.** The 214+P grenade's GROUND
detonation (NOT the on-contact hit explosion — see the rig note below)
drew a solid fuchsia rectangle. Its sprite codes are correctly remapped
bank 3 -> bank 4 (identical code ranges to native, verified in the same
OBJ dump that shows pal 0a/0c remapped correctly), but the tiles were
never copied into group C, so they resolve to all-zero tiles. Same class
as the child sidekick's shadow (14z-69o), two orders of magnitude bigger.

Rule used: every tile in the effect's span **0x0A00-0x0C40** that vs2
bank 3 has art for and our group C lacks. Source mapping validated on 6
populated tiles — group C bank 4 tile `c` <- vs2 group B index
`0x10000 + c`. Gfx-only: `build/hui17` carries the SAME program
fingerprint as hui15/hui16 (`699de9b7`), which is the evidence that no
program byte moved.

**The first attempt shipped 115 tiles and did not work.** A per-drawn-
tile inventory misses the other 35 tiles of every 6x6 sprite, because
`obj_records_dump` reports only a sprite's BASE code — and the fuchsia
block IS one 6x6 sprite. The span rule is a superset that covers any
multi-tile layout.

**Rig, because it is the whole reason this hid for three sessions:**
`tests/replays/hui/83d_hui_grenade_ground.rpl` — 214+**LP** (shortest
arc) with BOTH fighters walked back to their corners. Every earlier rig
fired 214+MP from 2P start distance, where the bomb reaches the opponent;
those captures show the on-contact explosion, which is correct and always
was.

**`x088512` 0x3B40 -> 0x3B98, raw tail from +0x3B78.** Its own three
`lea (d16,pc),A0` at 0x08C014/26/38 target tables at 0x08C08A/9A/A2,
0x38/0x48/0x50 past the old end, so each resolved to `target + delta`
inside the ANIM region placed immediately after (0x0D8950). Fixed via the
14z-69j mechanism, plus a small `extract_char.py` change so a SOURCE-ONLY
root honours `f<off>` at all. `verify_pcrel_data.py` 72 BROKEN -> 69.

**It fixes nothing observable and is kept on that basis.** The code that
reads those tables never executes in any measured scenario (execution
breakpoint at the placed twin `PRG:0x0D8912`: zero hits), and the
explosion's sprite codes are byte-identical before and after. It is a
latent repair of an already-ratified class, proven safe by legacy
masked-v2 EXACT and both frozen references rebuilding bit-exact.

## Session 14z-76 (Pyron's effect palette; build/pyron20 69e8c6f0)

One `[[palette]]` row added to `build/manifest/pyron.toml`, immediately after
his `sprite` entry:

```toml
[[palette]]
name = "effect"
stage = 6
src = 0x3AC45C          # vs2 0x396C14[0x11]; stride 0xDC0
len = 0xDC0
src_head_hex = "05370639075b088d"
table = 0x38C218
```

Generated delta against `pyron19`, exactly two ops and nothing else:

| op | addr | value | provenance |
|---|---|---|---|
| `data_file` | `0x3FABA0` (hole_b) | `palette_block_effect.bin`, `0xDC0` | `VS2` (vs2 `0x3AC45C`) |
| `poke32` | `0x38C25C` | `0x003FABA0` | `GEN` — effect table row `0x11` |

`0x38C25C` = `0x38C218 + 4*0x11`, i.e. **row 0x11 of the 32-row effect
palette pointer table** — a variant alias row, which legacy never indexes
(`tests/audit_id_writers.sh`). Before this change it held `0x3923E0`, row
0x01's value, so Pyron drew his effect/flash palettes from **Demitri's**
block. No `extra_tables` key: the generator emits extras only on the base
half, so a variant-id tenant has none.

**RETRACTION.** The deferral note in `pyron.toml` (and M3b merge blocker #2 in
`docs/NEXT_SESSION.md`) claimed this table has only 16 rows and that a variant
id spills into a separate table at `0x38C258`. It does not — see
`docs/game/atlas/character_tables.md` "The per-character palette POINTER
tables" and `docs/game/gotchas.md` "A VARIANT ALIAS ROW holds a value vanilla
uses". The comment block in the manifest was rewritten to the measured model,
keeping the still-valid eliminations from the 14z-74/75 blink hunt.

Gates: `run_suite.sh vsavjw` GREEN (55 PASS / 17 SKIP / 0 FAIL — the same
class inventory as `pyron-m1`, so legacy is untouched), `test_pyron_blink.sh`
still `fixed`, plus cosmo / variant_dispatch / gfx_layout3 / empty_tiles /
m3a_reproducible and the new `tests/test_effect_palette_table.sh`.

NOT established: visibility. The block is read 0 times in ordinary play
(two vanilla fighting replays, a 6000-frame Pyron soak; positive control 60
reads of his sprite block on the same rig). It is a rare-event palette whose
only documented trigger is the electrocute X-ray plus DF/status tints.

---

## Session 14z-78 — `anim`'s placed address stops being a literal

**Files:** `build/manifest/donovan.toml` (2 rows + comments),
`tools/gen_donovan_patch.py` (new guard), `tests/test_thunk_addr_literal.sh`
(new), `tests/audit_region_movability.sh` (expectation flipped),
`tests/run_battery_m2.sh` (gate registered).

**Emitted-byte delta on every frozen build: ZERO.** All four references rebuild
bit-exact (donovan-m3a `4b7d0dc7`, m5_stock `6c93cfa8`, huitzil-m2 `9deda080`,
pyron-m2 `69e8c6f0`). The change only alters what is emitted when `anim` is
placed somewhere other than its default `hole_a` address.

### The two rows

`[[site_thunk]] select_companion_tbl_a` (site `0x0845EC`) and
`select_companion_tbl_b` (site `0x0845F8`), authored in 14z-22 (see that
session's entry above, whose "ported anim table 0xDDA1E" is the literal in
question — historical, superseded here):

```
-  thunk_hex = "0c2e00TT000a6708207c002083bc4e75207c000dda1e4e75"
+  thunk_hex = "0c2e00TT000a6708207c002083bc4e75207cnnnnnnnn4e75"
+  region_subst = "nnnnnnnn=anim:0xa9ae"
```

(`_b` identically, with its own vanilla lea `207c002087ca`.)

`207c 000dda1e` is `movea.l #$000DDA1E,A0`. `0x0DDA1E` was `anim`'s placed
address, hand-computed once and tracking nothing thereafter. The offset is
derived from the SOURCE side and cross-checks against the placement side:
vs2 `0x289EF6` (the ported anim table) − anim's src `0x27F548` = `0xA9AE`;
`placed[anim] 0x0D3070 + 0xA9AE = 0x0DDA1E`, the literal itself. In the
default layout `region_subst` therefore emits the identical longword; on a
build with `region_space = "anim=wide_ext"` it emits `207c 0040a9be`.

Placeholder `nnnnnnnn` is deliberately NON-HEX. Substitution is textual, so
the existing `aaaaaaaa` spelling (huitzil.toml:1387) can in principle collide
with a real byte run in a longer body.

### Why it mattered

Relocating `anim` left both bodies aiming into the vacated address range,
where `x2b7ef4` slid in. The resolver at `0x015084` reads
`move.w (0,A0,D0.w),D0` / `lea (0,A0,D0.w),A0` — a base-plus-signed-16-bit
offset table — so it produced an odd A0 and `move.l (A0),(0x20,A6)` took a
vec3 address error in VANILLA code at `PC 0x015098`. That crash was recorded
as M3b's binding constraint for a session. `anim` is 371,712 of the 470,200
bytes three tenants needed from a 344,640-byte crypt window; with it movable
the requirement is 98,488 and the overflow is gone.

### The guard

`gen_donovan_patch.py` gains a third stale-literal guard beside the two that
cover the tenant id. An opcode-anchored (`2n7c` movea.l / `4nf9` lea /
`4ef9`,`4eb9` jmp,jsr / `2n3c` / `4879` pea), word-aligned 32-bit operand in
the PRE-SUBSTITUTION body that lands in any placed region's destination span
fails the build, naming the region and printing the exact `region_subst`
spelling to use. Escape hatch `addr_literal_ok`, mirroring `id_literal_ok`.

Coverage boundary, asserted in the gate rather than assumed: a raw longword in
embedded data is NOT caught. An unanchored scan was tried and rejected — it
reads operand pairs as addresses (`...0040` + `4e75` parses as `0x00404E75`,
inside wide_ext).

## 14z-79 — (b') the index-window thunk, and a withdrawal

**`site_thunk index_window_018468`** — engine site `PRG:0x018460`, 6 bytes
`323b 0006 4efb` replaced by `4ef9 <thunk>` (`patch = "jmp"`, `rts_ok`);
`0x018466-67` orphaned and never executed. Body 470 bytes in `hole_a`,
GENERATED by `tools/gen_index_window_thunk.py` from the two decrypted images
and reconstructed byte-for-byte by `tests/test_index_window_thunk.sh`.

Layout: a 2-instruction filter, the normal path, a 4-way exact-equality
dispatch, the four vs2 handler bodies verbatim, an 80-entry index table, and
23 trampolines.

    +0x00  cmpi.w #$00A0,d0 / bcc.s danger
    +0x06  move.w (0x48,PC,d0.w),d1 / jmp (2,PC,d1.w)      <- normal path
    +0x0e  4x cmpi.w/beq.s -> the four bodies
    +0x26  jmp $00000001                                   <- defined vec3
    +0x2c  80: 137c 000f 0054 4e75     (vs2 0x017024)
    +0x34  81: 136b 0017 0054 4e75     (vs2 0x016F70)
    +0x3c  82: 137c 0052 0054 4e75     (vs2 0x016FEC)
    +0x44  83: 4229 0121 137c 0001 0054 4e75  (vs2 0x016F78)
    +0x50  index table, 80 words: entry n -> (tramp + 10*k(n)) - 0x0e
    +0xf0  23 trampolines: `move.w #<vanilla offset>,d1 / jmp <handler>.l`

TWO THINGS THE BODY DOES THAT THE 14z-78 SPEC DID NOT, both forced by
measurement:

1. **The table copy is LOCAL and read PC-relatively.** The spec's
   `lea 0x018468,a0 / move.w (0,a0,d0.w),d1` is a DATA-space read, and CPS-2
   decrypts program-space fetches only, so it returns ciphertext: 38 of the 80
   legacy targets come out ODD (0 in the opcode view). Because the body is a
   `code` op it re-encrypts with the placed code, so a pc-relative read of an
   embedded table decrypts back to what was authored.
2. **Each trampoline restores D1 to the vanilla offset.** "D1 is dead on ENTRY
   to all 80 handlers" is true and licenses nothing: the handlers `rts` into
   `0x01821A`, a chain of five `bsr.w`. A build without the restore moved every
   self-frozen legacy log and pushed two masked replays from one divergent run
   to two. `move.w #imm,d1` also reproduces vanilla's CCR exactly, so register
   and flag state at handler entry is bit-identical to vanilla.

Cost to legacy: two compares and one extra jmp, touching D1 (rewritten to the
vanilla value) and the CCR, writing NOTHING to RAM. The site is COLD — 22
dispatches per 5,520-frame replay.

**`data_port df_palette_seq_rows` — WITHDRAWN** (see the 14z-69 entry above,
now marked RETRACTED). It overwrote BULLETA'S Dark Force palette block.

## 14z-82 — per-tenant TYPE NUMBERS (the merged obj_hook vec3 fix) + the F2 merged shim

**The defect (14z-81b):** the merged obj_hook union gave multi-owner types
114-120 (site 0x5E542; handlers all inside x088512, which every tenant
ports as an internally tenant-reconciled copy) ONE table entry each,
first-wins → tenant-0's copy — so merged Huitzil's type-117 satellite
consumed Donovan's planted tripwire address 0xCB9C0 as an anim base (the
deterministic char-init vec3). The dispatch-time owner-read stub was
implemented and WITHDRAWN the same day (14z-81c, two measured timing
failure modes); the ratified direction is the build-time route
(docs/project/gotchas.md "Route on facts baked at BUILD time").

**The fix (maintainer-decided scope: FIRST RESOLVER KEEPS ORIGINALS):**

* `build/manifest/type_stamps.toml` — the FROZEN, human-reviewed census of
  every family stamp site / compare / +0x02-+0x03 reader / embedded
  walker, produced by `tools/audit_type_stamps.py` (opcode-anchored;
  positive control on the six measured sites; negative control on the
  three unported stamps). The census found a whole stamp FORM the 14z-81b
  ad-hoc scan was blind to — `move.b #type,(2,A4)` (~20 additional
  type-115 sites, the spawn idiom `beq.s; move.b #1,(A4); type at +2;
  owner at +3`) — and proved NO compare in any tenant's code regions reads
  the type byte (d16 values are 0x54/0x14/0xA8 or register-sourced).
  Dynamically cross-checked by `tests/audit_type_writes.sh` (6 tap legs on
  the ground-truth builds): every observed 114-120 write maps to a frozen
  stamp row; types 118/120 NOT OBSERVED (recorded, not assumed); the
  115→117 "morph" is the 117 header re-stamp at x088512+0x27CE, which
  renumbers with everything else.
* Generator (`tools/gen_donovan_patch.py`): a pre-loop pure map
  (`compute`-style block after `_tenant_list`) assigns new type numbers to
  every NON-first resolver tenant with ≥1 frozen stamp site — 12
  assignments at N=3 (indices 124-135: H/P × types 114-119; type 120 has
  ZERO reachable stamp sites anywhere and keeps first-wins). A
  per-iteration blob pass rewrites ONLY the TT byte of each stamp
  immediate in that tenant's own region copies (full source span verified
  first; 69 rewrites at N=3, reconciled 1:1 against the inventory), and
  the union appends per-tenant entries resolving through the OWNING
  tenant's view (no-gap asserted). Table op grows 0x1F0→0x220; op COUNT
  unchanged. Empty at N=1 — all four frozen fingerprints bit-exact.
* Byte-level proof: hui copy x088512+0x27CE stamps `28BC 0100 8200`
  (130), pyron's `...8300` (131), donovan's untouched `...7500`.

**Measured green:** `audit_merged_vec3.sh` PASS (merged satellite A0 =
0x425FFC = anim@huitzil+0xB8AC, crash-free); new gate
`tests/audit_type_dispatch_range.sh`: merged hui mash = original range
[0x1C8,0x1E4) CLEAN with 5,862 renumbered dispatches (the full stream
moved), donovan originals intact (4,575), verdict control on hui29 sees
5,862 original-range hits.

**F2 (the merged shim served only tenant 0) — fixed the same emit path:**
`flavor_chain_multi()` gives each 54-byte chain block its OWNER's handler
exit (the old chain's uniform `jmp` could only exit into tenant-0);
declaring tenants' handlers are collected per iteration and ONE merged
shim is assembled at engine_here (the 14z-80h shape), planted on BOTH
declaring rows (dispatch_00[0x13] and [0x10] → the shim; pyron [0x11]
stays direct by ratified decision); unmatched id → planted tripwire —
that fall-through tripwire is the ONE op the fix adds (590→591,
re-frozen in test_tenant_loop.sh + audit_merged_legacy.sh FIRST, per the
standing rule). audit_merged_legacy section 0 now asserts the POST-fix
shape (HENT == SHIM, PENT != SHIM).

**Pyron f7997: NOT this class — measured elimination.** Crash-time
instruction history (GUARD_PROBE_HIST now also fires from the guard's
crash handler) names a vanilla dispatcher chain 0x1A77E→0x1A790
`move.b (2,A6),d0` → byte map 0x1A888 → word table → computed jmp; a probe
with `b@(a6+2) >= 0x72` recorded ZERO hits through the whole replay while
the crash still fired identically — so no extended-family type ever enters
that mapper, and the census's exposure claim stands. ~~A3=0x49bb8a (inside
pyron's wide_ext) feeding that vanilla path + the odd derived pointer
$FF31B5 point at a pyron-placed data/table defect one level removed —
open, next session.~~ **RETRACTED same day (14z-82b below): the input was
type 64 (< 0x72, invisible to that probe by construction); A3 was live
register context, not causal; and the crash is LATENT in frozen pyron-m2
itself.**

## 14z-82b — the f7997 fix: vsavj's hit-class byte map extended to vs2's 80 entries (probe build; adoption pending)

**Third instance of the "vs2 widened an index consumer" class** (14z-26:
property table 0x28D00; 14z-35: the 0x50-entry dispatch table; now the
projectile-pool hit sweep). The sweep at `PRG:0x1A770-0x1A886` is SEVEN
dispatchers (4 `bsr.w` + 3 `bsr.s`) that all map BOTH colliding objects'
type bytes through ONE routine:

    0x1A888: move.b (4,PC,D0.w),d0 ; rts     map at 0x1A88E, 64 entries

vs2's sibling (dispatcher 0x1919A, routine 0x19292, map 0x19298) has
**80 entries**. A ported type >= 64 in the $FF94xx pool that LANDS A HIT
(the dispatch runs only on overlap — why it took an 11,017-frame chaos
soak to fire once) indexes past vsavj's map: map[64] = the rts opcode's
0x4E — exactly the crash D0 — then a garbage word-table displacement and
a wild jmp. Measured LATENT in frozen pyron-m2 (type-64 satellite;
crashes solo, no merge), shared by huitzil (68/72 stamped into the same
pool, unexercised by his suite replays), safe for donovan (59-63 fit).

**Body (94 bytes, GENERATED by `tools/gen_hitclass_map_thunk.py` — never
hand-typed):** `cmpi.w #80,d0; bcc.s ILLEGAL; move.b (4,PC,D0.w),d0;
rts; <64 vanilla map bytes verbatim><16 vs2 extension bytes>; ILLEGAL`.
Site patch `jmp body` over the routine's own 6 bytes (`rts_ok`: a
bsr-entered handler; stack-neutral, ghost-clean; final CCR on the normal
path = the loaded byte's NZ, exactly vanilla). The generator ASSERTS the
transplant licence: the engines' 0-58 map prefixes are byte-identical
(vanilla's true domain — its type table has 59 rows), every extension
value lands on a word-table entry byte-identical across the engines or
the do-nothing default (a plain rts), and vs2's map ends at 79. Its own
asserts caught two wrong first readings (an 83-entry miscount via an
odd-alignment impossibility, and the 61/62 divergence below).

**Deliberate policy: map[59-63] keep VANILLA's bytes.** vs2 populates
61/62 (DONOVAN's satellite types) with classes 0x0E/0x04 where vsavj
holds 0 — his projectile hit-class reactions are silently absent on
every shipped build. Adopting vs2's two bytes = a Donovan re-freeze —
recorded as a separate maintainer decision (STATE).

**Measured (probe build; `tests/audit_hitclass_map_cost.sh`):** the
soak that crashes the frozen build END-clean through 11,017 frames;
legacy BIT-IDENTICAL over 30,284 frames on four replays; fire census =
legacy enters the map ZERO times on any measured replay (the probe's
liveness proven by pyron's own f7997 dispatch) — the thunk is
unreachable for measured legacy content. Reconstruction gate:
`tests/test_hitclass_map_thunk.sh` (2 verdict controls).

**NOT ADOPTED in the manifests** — the row moves the huitzil + pyron
frozen fingerprints; decision + recommendation in STATE. Harness repairs
landed with it: `audit_merged_legacy` leg-b now always measures the REF
leg on a crash (MERGE-SPECIFIC vs LATENT verdict), closing the gap that
mis-attributed this crash for two sessions.

### 14z-82c — ADOPTED: huitzil-m4 (e66678d0) + pyron-m3 (6c7f7322)

Maintainer decision 1 adopted the row into BOTH tenant manifests (shared;
dedups to one thunk on the merge; donovan not exposed, does not declare).
pyron-m3 is byte-identical to the measured probe build. Re-freezes in the
re-freeze-FIRST order: m3a constants, tenant_loop 261/207/439/593,
audit_merged_legacy 593. Suites: both builds moved EXACTLY the three
don-mash `.sha1` self-baselines (21/22/26) and no masked entry —
attributed BY BYTES on the checksum timeline (full-RAM dump-diff at a
divergent frame: 3 bytes, all $FF7Fxx dead-stack ghosts, zero live) and
re-frozen; hui30 SUITE GREEN. THE PAIRSWEEP DISSOLVED under the fix with
a control (pyron-m2: CRASH f4638, the f7997 signature; pyron-m3:
END-clean 7,520) — one vanilla map was THREE defects. The merged
instrument now: leg (a) 13/14 verbatim, leg (b) all six guard-clean
(pyron/70 END 11017 merged). Decision 2 (Donovan's map[61]/[62]) leaning
keep-zeros; measured: his sword-companion objects never enter the map in
his replays (0 entries) — unexercised.

## 14z-85 — the spawn-time OWNER TAG (site 0x54470's 59-75 family; maintainer option (a))

The last known merged program-behavior defect class: obj_hook union
entries 64-75 served every tenant through HUITZIL's copies by
declaration-order luck (huitzil declares before pyron). Ruled option (a)
2026-08-13; implemented and verified this session.

**Every byte, and why:**

- **80 stamp-site detours** (blob edits, 0 ops): every frozen 59-75
  stamp row (`build/manifest/type_stamps.toml`; d16==2 only; both
  family forms are exactly 6 bytes) in every declaring tenant's copy —
  donovan 9, huitzil 40, pyron 31 — has its 6-byte stamp instruction
  replaced by `jsr <thunk>` (`4EB9 xxxxxxxx`), full source span
  old-verified before the write (the type_renumber discipline).
- **46 tag thunks** (code ops, alloc chain → wide_ext; memoized per
  (tenant, original-instruction)): `move.b #tenant_id,(0x7F,A4)`
  (`197C 00id 007F`) + the ORIGINAL stamp instruction (CCR-LAST — jsr/
  rts set no flags, so the site's flag result is reproduced exactly) +
  `rts`. A4 = the slot pointer at every family stamp site (all 41
  inventory rows). The jsr push is tenant-code-only; no legacy path
  executes these sites.
- **12 tag stubs** on entries 64-75 (+12 tripwire ops):
  `owner_dispatch_stub` shape `"tag"` — per resolving tenant
  `cmpi.b #id,(0x7F,A6); beq.s exit_i` (A6 = object at the walker's
  dispatch, per the measured 14z-81b entry contract), fall-through
  `jmp <tripwire>` (zero tag = a stamp site the emission missed, LOUD;
  unclaimed tag = same). Exits re-establish vanilla handler entry state
  (`moveq #0,d0; movea.l #handler,a0; jmp (a0)`).
- **The tag byte: +0x7F of the $FF9400 slot** (0x100 stride, walker
  0x54458). Measured free THIS session: 804 live-slot observations,
  zero +0x7F writes across 19,357 tapped pool writes under BYTE-LANE
  accounting, three legs with live family content (types 0x42/0x45).
  The 14z-84 census had measured the WRONG POOL ($FFB800 = the
  0x5E542/114-120 family's) — retracted in place; and its "+0x7F free"
  was itself a word-offset accounting artifact (hole_b writes a word at
  b8+0x7E covering byte +0x7F). A tag there would have been clobbered.
- **Scope**: stubs on 64-75 exactly as ruled. Entries 59-63 are
  single-resolver (donovan's copies) — H/P stamp those types at
  (currently dead) shared sites; their tags emit anyway so any future
  live spawn tripwires under its own tag. Stamper-not-resolver cases
  (donovan stamps 65/66/73/75, places no handler) are printed notes,
  not errors — solo builds already tripwire those types for him and
  playtest green.
- **N=1 inert by construction** (the `len(_tenant_list) >= 2` gate):
  all four frozen solo references rebuild bit-exact
  (4b7d0dc7/6c93cfa8/db4bcd11/6c7f7322). Side file `tag_map.json`
  (only when non-empty) carries site/tenant/tag/thunk rows = the
  writer PCs the pool audit asserts.

**Measured green:** tenant_loop 473/667 (re-frozen; §4b decodes the
stubs per entry) + 5 verdict controls; dispatch-range §0-6 ALL PASS —
2,046 stubbed family dispatches on pyron's mash leg, tripwire SILENT,
0x54470 family visible on the solo control; vec3 GREEN; pool audit
post-tag mode GREEN (293/293 family live-slot obs carry the stamper's
tag; +0x7F writer PCs == the emitted thunks; forced-pre negative
control fails both directions); merged legacy audit 14/14 (04+11
ratified expectations).

**What the fix did NOT change (measured, own before/after):** the ring
inventory on pyron's replays — the music retrigger is the per-node sfx
helper class (see the 14z-85 STATE entry), not 64-75 dispatch.

## 14z-85b — per-tenant sfx records (pyr_sfx_records / hui_sfx_records; maintainer-ruled option (a))

The ACTUAL music-retrigger fix (the mechanism the owner tag was wrongly
credited with — see 14z-85 above). Two manifest rows, the don_sfx_records
precedent verbatim; per-id curation in docs/project/tables/sfx_records.md.

**Every byte, and why:**
- `pyr_sfx_records`: vs2 0x0C8B18, 23 records (exact shape-scanned bound;
  the over-run span holds keep-id lookalikes) → wide_ext, id-allowlisted
  (keep 0x110/0x111/0x112/0x202 — all in don's ratified set; 15 zeroed
  incl. the 0x720-0x72F voice block whose 0x729 WAS the measured music
  retrigger). poke32 ptr row 0x11 (was the vanilla 0x95894 Demitri alias,
  displaced pre-fix by the generic tail_data_ptr repoint at his RAW
  records).
- `hui_sfx_records`: vs2 0x0C742A, 24 records → wide_ext (keep the trio +
  0x198/0x199, measured SHARED 14z-85 — equal keyon signatures, don-0x119's
  sample family; 18 zeroed). poke32 ptr row 0x10 (was 0x938BA).
- Both rows carry the idempotent helper unstub (vs2 0x5122 → vsavj 0x4CE2),
  so SOLO H/P builds gain audible node sfx (they were silent — no build of
  theirs ever carried the unstub). NET +1 op per declaring build (the
  claim machinery suppresses the generic repoint).

**Freeze ceremony:** huitzil-m7 = build/hui33 (284e3b1c), pyron-m4 =
build/pyron22 (ac22418f); expectation sets carried RENAMED; suites GREEN
with --freeze; every .sha1 mover byte-attributed: ONE divergent frame
(f890, the select-init staging of the repointed ptr rows, re-converges
same frame) on every replay, plus one bounded run (f2410-2596, the
tenant's now-audible node sfx) on the two tenant-pick replays ONLY.
tenant_loop re-frozen 266/208 solo, 474/669 merged. Ring gate re-frozen
to EMPTY merged-vs-solo diff — measured: every pre-fix id incl. 0x729
gone, no solo id missing.

**FIELD-CONFIRMED (maintainer, first playtest, 2026-08-13): "the music
triggering is gone, Piled Hell has its hitbox — needs deeper testing but
it does look very good."**

## 14z-85f — the x028122 object-hit damage work-var reconciliation
## (huitzil-m8 / pyron-m5: the FINAL GUARDIAN zero-damage fix)

**The defect (closing the 14z-85e parity item):** FG's beam ticks are
hits BY pool objects (the type-02 beam particles; attacker context a6 =
per-hit ctx), processed by per-hit-class REACTION handlers that live in
ported vs2 code. The reaction (vs2 0x55FA8/combo writer 0x56002; H's
copy at merged 0x4026E2, region "code (grouped)") calls the ported
object-hit damage APPLIER (vs2 0x28A6A → H's copy 0x40C828, region
x028122). The porting machinery reconciled the applier's jsr targets
(vsavj scaler 0x18B8C, post-process 0x18AB0, pre-check 0x5E9B4) but its
A5-relative STAGING DISPLACEMENTS shipped verbatim: scaled damage
staged at vs2's -0x4B6C/-0x4B6A/-0x4B68(a5) = $FF3494/96/98, while
vsavj's post-process reads -0x4BBE/-0x4BBC/-0x4BBA = $FF3442/44/46.
Result: 12 combo-counted beam ticks (hitstop, sparks, satellites all
live), ZERO HP staged. Same-value class #4 — and byte-for-byte
Donovan's session-14n throw-damage defect, whose six port_patch rows
patch the SAME instructions in the SAME region and never propagated to
the H/P manifests (gotcha filed).

**Eliminated by measurement en route (14z-85e's two hypotheses):** the
scaler tables are byte-equivalent between the games (attack
0x0B8140↔0x0D22BE, final 2D maps 0x0B9140/0x0BA1C0↔0x0D32DE/0x0D435E,
combo + RNG-spice; defense/low-HP tables differ only on per-char-id
rows — the roster shuffle), and native hit count is identical (12
ticks). Full pipeline synthesis: docs/game/engine_internals.md "The
DAMAGE pipeline".

**Every byte, and why:** six [[port_patch]] rows per manifest
(huitzil.toml + pyron.toml), stage 6, region x028122 — vs2 src
0x28AC2/0x28AC8/0x28AD8/0x28ADC/0x28AE2/0x28AF2, each a 2-byte
displacement change (b498→b446, b494→b442 ×2, b496→b444 ×2, plus the
flag-word immediates' rows) = 12 bytes per tenant copy. Donovan's rows
verbatim. The 14x rollback family (-0x4B74/-0x4B72/-0x4B3D — attacker/
victim registration + state byte) left at vs2 offsets on purpose:
ported readers consume them (donovan.toml stage-99 parked rows).
Static census after: ZERO vs2 damage-band A5 writes remain in ported
space on either build (the remaining b48c/b48e/b4c3 hits are the
rollback family, by design).

**Measured (tests/replays/hui/89_hui_ex_fg_vs2.rpl — new
native-comparable rig, the 85_hui_df_vs2 opening + five spaced 623+2K
attempts):** before: native 23/23/23/23/52 HP (12 ticks each; the 5th
cornered, 11 ticks + one 30-HP terminal hit) vs ours 1/1/1/1/1. After:
BIT-EXACT parity, both solos and the merged rebuild. audit_fg_damage's
71/73 CPU rigs measure 10 HP UNCHANGED by the fix — those ticks were
fighter-path contacts (never broken); header reframed.

**Gates:** tests/audit_fg_parity.sh NEW (both legs vs the frozen
staircase; per-attempt stock-decrement EX tells; 2 verdict controls;
ground-truthed FAILING on the pre-fix merged), tenant_loop GREEN with
counts UNCHANGED (port_patch rows are region rewrites, not ops),
m3a_reproducible on the new EXPECTs, merged legacy audit PASS (leg a
verbatim incl. ratified 04+11), run_suite on the carried-renamed sets.
Builds: huitzil-m8 = build/hui34 (c48cd722), pyron-m5 = build/pyron23
(65e9a40e), merged = build/m3b_merged2 (moves with generator).
Reconciliation rows added (applier 0x28A6A↔0x29738 verified + the five
scaler-table data rows); verified build-inert (fingerprint unchanged).

**DECIDED (maintainer, 2026-08-14): keep the vanilla vsavj
approximation** for the tenant DEFENSE rows (defender-side; found
during the table compare). The choice, the exact values on both
sides, and the option-(a) change recipe (variant-gated reader thunks,
hitclass precedent; Donovan's row would supersede donovan-m3a) are
documented in docs/project/tables/defense_rows.md. Pyron needs
nothing either way — his rows are byte-identical between the games.

## 14z-85g — the restored trap-detonation chirp (huitzil-m9: the
## sound_stub row + the sound_table remap machinery)

**The finding chain (each step measured):** the four-leg ring A/B
killed the 14z-85e volume/pan hypothesis (entries essentially identical
across legs; 0x049A = periodic ambient, the 14z-82d detonation
attribution retracted); the real delta is native firing
0739/010b/073a per attempt where ours fired 010a. First reading
("record nodes 10/11 zeroed, restoration = M5") was corrected by the
maintainer's field observation and the content check: **vs2 0x73A's
sample bytes are BYTE-IDENTICAL in vsav's own QSound image**
(0x6C0000, bank 108, 0-20480, pitch 12548; vsavj ids 0x198/0x199
family, +0x300 alias 0x498/0x499). And the detonation call is not the
record path: bp-attributed (USP-top return — the bp_regs A7-first fix)
to **sound-farm stub vs2 0x4F2E** (`jsr $330E; move.l #$73A,d1;
moveq 0,d2/d3; bsr $5122; jmp $3306` — a farm of such one-id stubs at
0x4EE0-0x4F60), jsr'd from the mine handler at x068458+0x120. Hui's
recon overlay had silenced it to the 0x2A7E0 rts (the 14z-65 blanket
"0x7xx = voice bank" number rule — see the new GOTCHA).

**Every byte, and why:**
- `reconciliation_huitzil.toml` 0x4F2E row: stubbed_sound → **kind =
  "sound_stub", sfx_id = 0x199**. The generator (new kind, sibling of
  farm_port) synthesizes a 26-byte vsavj twin stub in hole_a:
  `jsr $330E.l; move.l #$199,d1; moveq #0,d2; moveq #0,d3;
  jsr $4CE2.l; jmp $3306.l`. The save (0x330E) / restore (0x3306)
  pair is byte-identical at the SAME address in both games (verified
  rows); the helper is the per-node sfx helper; base id 0x199 lets
  the helper's own (0x70,a6) flag produce the 0x499 alias exactly as
  the engine intends. +1 op (tenant_loop re-frozen 243/267/208 +
  491/678).
- `huitzil.toml` hui_sfx_records gained **remap_ids = "0x73A:0x199"**
  (new sound_table key, target must be in keep_ids or the build
  fails): record node 11 stays content-faithful for any record-path
  dispatch (none observed in the 87/88 rigs — data-only, defense in
  depth). Node 10 (0x739, the mine-ejection sound) stays zeroed: no
  vsavj equivalent exists; fully M5 scope (maintainer-scoped
  2026-08-14).

**Measured after:** ours fires 0x199 at f3500/f4301 — native's 0x73A
timing (f3494/f4295), both attempts, replay 87.

**Gates:** audit_trap_parity RE-FROZEN to the restored state
(ground-truthed failing on pre-fix huitzil-m8); audit_trap_sound
green (re-scoped: spawn + ring liveness); tenant_loop re-frozen;
m3a_reproducible on the new EXPECT_HUI; run_suite on the
carried-renamed set; merged rebuilt (build/m3b_merged3).
Build: huitzil-m9 = build/hui36 (3d9ffc89). Maintainer EAR-CHECK
pending — the final gate for a sound item.

## 14z-85g(2) — the trap SHOCK restoration (huitzil-m10: two
## vs2-licensed class remaps; maintainer-ruled option (a))

**The defect (maintainer field report, same day as the chirp
confirmation):** the trap dome's hit inflicted no shock status. The
dome's hit records carry vs2's EXTENDED class 0x52 (victim +0x54 =
0x52 at the hit, both games — measured on the new deep-overlap rig
92). The victim-side reaction dispatch (`PRG:0x2384E`: class × 2 into
the PC-relative word jump table at 0x2385C) reaches a dedicated shock
handler on vs2 (table 0x22388 entry[0x52] = 0x2CE → 0x22656,
bp-verified firing at the native hit) — but vsavj's table ends before
0x52: entry[0x52] reads CODE BYTES (0x1D7C) and ours took a
wild-but-lucky plain-hit jump (bp-verified: the dispatch runs, no
shock handler fires). Donovan's 14z-33/34 class, one dispatch table
over.

**The licence (the 14z-33 rule — "only remap when the source engine
itself proves equivalence"):** vs2's OWN table aliases class 0x52 ≡
0x06 ≡ 0x38 (one entry), and vsavj entry[0x06] = its native
electric-shake handler 0x23AC8 — a STRUCTURAL TWIN of vs2's 0x22656
(instruction-parallel; same sub-state 4 / freeze 0x18 / property
lookup / common-install tail 0x27EC0 ↔ 0x27114) minus ONE guard:
vs2's `cmpi.b #$52; beq` skips the ATTACKER's 0x0B hit-freeze (the
attacker is a mine). property[0x06] == property[0x52] == 0x0F on both
games (Donovan's ported extension rows cover 0x52 on ours anyway).

**Every byte, and why:** two `[[region_fix]]` rows in huitzil.toml —
hitbox_proj +0x17D and +0x19D (the dome's two records, class byte at
record +0x1D): `52` → `06`. Nothing else; the shock rides pure
vanilla machinery (Victor's own path).

**KNOWN, MAINTAINER-ACCEPTED DEVIATION:** Phobos receives the normal
11-frame attacker hit-freeze when the trap connects (vsavj's 0x06
path applies it; vs2's 0x52 guard exempts him). The gate asserts the
deviation PRESENT so drift in either direction is loud. Option (b) —
a dispatch site_thunk with an inline clone carrying the exemption
(the es_type51_dispatch pattern) — is specified in STATE 14z-85g(2)
if play dislikes the freeze; its cost is jsr cycles on the ENGINE-WIDE
reaction dispatch (legacy flicker-inventory ratification).

**Also measured en route (rig sweep):** the mine's roll is
PROXIMITY-TERMINATED — it stops shorter the closer the opponent
stands (549/545/527/509 across P2-walk N=40-55) — and rolling THROUGH
the opponent triggers nothing: the shock is the dome hit, by vs2's
design.

**Measured after:** vsavj 0x23AC8 fires at the dome hit (D0=0x0C =
class 0x06×2), victim shows the native shock signature (seq7=4,
freeze 0x18 decay — pre-fix ours showed seq7=2), attacker freeze
present. Native leg unchanged (its own 0x52 path).

**Gates:** audit_trap_shock NEW (rig 92 ours+native, per-leg class
expectations, the deviation assertion, verdict control; ground-truthed
FAILING on huitzil-m9); audit_trap_parity green (chirp unaffected);
tenant_loop counts UNCHANGED (region_fix = region rewrite);
m3a_reproducible on the new EXPECT_HUI; run_suite on the
carried-renamed set. Build: huitzil-m10 = build/hui37 (9a948a11),
merged = build/m3b_merged4.
