# patch_notes — per-change detail: every byte, and why

Newest first.

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
docs/tables/reconciliation.md "Session 8".

## donovan-m2 stage 4 — VS2 default flavor via the init shim (2026-07-27)

The pool-seeding init shim (behind dispatch_00[0x0F]) grows 26→32 bytes:
after the pool-seed branch it now writes the VS2/VH2 flavor latch into
the initing player's struct — `move.b #$01, $3C2(A6)` — before jumping to
Donovan's relocated handler. Both values are manifest tunables
(`[init_shim] flavor_disp / flavor_default`, donovan.toml). Why: vsavj's
engine never writes +0x3C2; Donovan's ported QCB+K handler (vsav2
0x5A654) and its projectile (0x65FE6) read it (0x01=VS2, 0x00=VH2 —
community-confirmed Start-hold mechanism, docs/atlas/character_tables.md);
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
  docs/GOTCHAS.md, docs/tables/reconciliation.md Session 7.
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
protocol (docs/tables/reconciliation.md OPEN FRONTIER).

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
  now refused in normalise_tenants (docs/atlas/id_space.md reservations).
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
- Generator/manifest mechanics (docs/tenant_manifest.md "slot-row
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
