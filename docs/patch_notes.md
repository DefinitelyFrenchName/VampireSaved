# patch_notes — per-change detail: every byte, and why

Newest first. Byte-level op lists are generated (never hand-edited): the
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
