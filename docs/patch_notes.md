# patch_notes — per-change detail: every byte, and why

Newest first.

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
