# NEXT SESSION — orientation (written at the close of 14z-70, 2026-08-09)

**Start with the BEAM. It is fully scoped, the scope is measured rather
than reasoned, and it is written up in
`docs/project/beam_port_scope.md` — read that FIRST, then this.**

**PING #13 = build/hui17 (699de9b7) is current and MAINTAINER-CONFIRMED**
("explosion corrected, my tests confirm it"). `tools/run_hui_behavior.sh`
points at it. Frozen references unchanged (donovan-m3a 4b7d0dc7 /
m5_stock 6c93cfa8; m3a-reproducible PASS).

## What shipped in 14z-70

1. **The 214+P grenade's GROUND explosion** — it drew a solid fuchsia
   rectangle. 569 group-C tiles were remapped bank 3->4 but never copied
   (`extra_tiles/0x10.json`, 2 -> 569). Gfx-only, so hui17 carries the
   same program fingerprint as hui15/16.
2. **`x088512` grown 0x3B40 -> 0x3B98** with a raw tail — three pc-rel
   tables were resolving into the anim region. A real latent repair that
   fixes **nothing observable**; kept on its gate sweep, not on a
   behavioural claim.
3. **`audit_empty_tiles.sh` hardened** — it had passed every build
   through hui16 while this defect was live.

## THE OPENER: build the beam port

Everything below is measured. The scope doc has the tables.

**What is wrong:** the beam's visual object exists on both legs and is
never DRIVEN into its beam states on ours. That is why the FREEZE WORKS
while the muzzle orb and beam are both missing — they are one object.

**Where the builds part company** — most of the path already exists:

| link | native | ours |
|---|---|---|
| effect-type reader | `0x093080` (950 reads) | `0x0844F4` (950) — shared |
| dispatch table | `0x093088`, 32 entries | `0x0844FC`, 32 — shared |
| entry #2 target | `0x093442` | `0x08471A` — shared, byte-identical 0x1C bytes |
| **the next routine** | **`0x093460`** | **absent — vs2-only** |
| the machine | `0x0934A8` | absent — vs2-only |

The missing routine is four instructions:
`movea.w 0x30(A6),A4` (the OWNER -> A4, which is what lets the machine's
id gate read `0x382(A4)`), `move.b 0x04(A6),D0`, then a `jmp` through the
table at `0x093470` whose entry #22 is the machine.

**The hook is an owner-gated diversion**, not a table edit: only objects
whose owner is the tenant take the new path, so legacy dispatch is
untouched by construction. There is NO dead entry to repoint — that was
checked and disproved.

**Two premises already verified, so do not re-derive them**
(`tests/test_beam_variants.sh`, PASS):
- all THREE variants (236+P / 236+K / 236+2P, which is the same move as
  236+2K) are ONE art path — pal 0x0C from the tenant band, the ES just
  uses more tiles. One port covers all three.
- all 147 tiles they draw are ALREADY in group C. The port is not
  expected to need copy-inventory work.

**Remaining before a build:** the machine body's transitive closure
(`extract_char.py` reports it once rooted — the only real unknown, and it
could still make this big); exactly where the diversion goes; and the
pcrel census on the new root before freezing its length (x088512 was
0x50 bytes short for precisely that reason).

**The proof of fix already exists:** `tests/test_beam_anim_walk.sh` flips
`BEAM_WALK_EXPECT=absent` -> `walks`. Then snapshot f3176 (muzzle orb)
and f3192 (beam) against native.

## Then, in order

- **Win quote** — deferred, cosmetic, root-caused.
- **FG pacing** — untouched.
- **H freeze** (registry row + expectation set, maintainer-gated), then
  Pyron's moveset arc and his gfx rung. Run `tests/audit_empty_tiles.sh`
  AND `tests/test_beam_variants.sh`-style tile checks on his first gfx
  build.

## WORKING AGREEMENT with the maintainer (adopted 14z-70)

1. **Send the native/ours capture pair and state the interpretation
   BEFORE measuring on it**, naming the rig assumptions (button strength,
   spacing, which event should be on screen). He reads a frame instantly.
2. **When in doubt, plan and scope FIRST** — measure the extent, write it
   up, show it, then build.
3. **Never ask him a CODE question as if it were a gameplay judgement.**
   "Are these one machine or several" is measurable; asking him to guess
   wastes his expertise. Ask him what it LOOKS like; measure what it IS.

## Method notes from this session — read before the next attribution

1. **THE ANCHOR METHOD (use it first).** Do not reason about object
   layout or which region a machine lives in. Anchor on the data the
   effect must READ — its sprite list — put a read watchpoint on it on
   both legs, and let the registers hand you the object. It is
   self-correcting: if the anchor is never read, that IS the finding. It
   cracked both the explosion and the beam in one run each, after two
   sessions of layout reasoning produced only retracted claims.
   (`docs/game/engine_internals.md`, "THE ANCHOR METHOD".)
2. **Co-location is not causation.** "The machine lives in x088512;
   x088512 has broken tables; therefore they feed it" — all true, and
   false. Put an execution breakpoint on the code that READS a table
   before attributing a symptom to it. One run, before a rebuild.
3. **Prove the rig produces the REPORTED event.** 214+MP from start
   distance hits the opponent; the ground mushroom needs LP and corner
   spacing. Three sessions of analysis went to the wrong event.
4. **A constant delta between two dense code sets is probably an
   artefact.** "+0xA220" matched 41 of 88 codes and meant nothing: two
   ~85-value clusters of similar width overlap about half the time.
   Confirm by CONTENT, never by index arithmetic.
5. **Join by content, never by index, and never per-frame across legs
   that drift in phase.** Per-frame intersection read 0 at every frame
   while the window agreed 76/84.
6. **Assert the STATE, not the input.** ES consumes a meter stock and
   degrades silently, exactly like Dark Force.
7. **Instruments truncate.** `obj_records_dump` reports a multi-tile
   sprite's BASE code only; `audit_empty_tiles.sh` sampled every 25
   frames and found 10 of 113 tiles. Both now fixed — the shape recurs.
