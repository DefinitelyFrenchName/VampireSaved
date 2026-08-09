# NEXT SESSION — orientation (updated at the close of 14z-73, 2026-08-09)

**Session goal: PYRON.** Phobos is FROZEN (`22c016ac -> huitzil-m1`,
`run_suite.sh vsavjw` GREEN 54/17). The grab-victim teleport was fixed and
maintainer-confirmed on both grabs in MAME + FBNeo (§1); FG pacing is
resolved-by-observation (§3). The only Phobos item left is the cosmetic win
quote (§2), a 3-level data port deferred per docs — it does NOT block Pyron.

**Frozen build: `build/hui26` (`22c016ac -> huitzil-m1`)** — = hui25 + the
grab-hold keyframe fix. Playtest-clean (beam, ES, low beam, grab lightning,
both grabs track native). Full H battery GREEN (15/15) + full oracle suite
GREEN. Rebuilds bit-exact from `huitzil.toml` at `TENANT_CHAR=0x10` stage 6.

---

## 1. THE GRAB VICTIM'S MID-ANIMATION PLACEMENT — FIXED (14z-73) ✓

Maintainer-confirmed clean on BOTH grabs (regular 6MP/6HP and Circuit
Scrapper 63214), in MAME and FBNeo. Build `build/hui26`.

Root cause: the victim's hold position comes from a per-attacker keyframe
block selected via pointer table `0xBE27A` (indexed by attacker id); H's
row 0x10 aliased character 0's block, so H held the victim with the wrong
offsets (−27px vs native +74). Fix: `[[data_port]] grab_hold_keyframes` in
`huitzil.toml` ports H's own vs2 block (`0x0C56AA`) into `wide_ext` and
repoints row `0xBE2BA` — the exact twin of Donovan's `throw_victim_keyframes`.
Legacy masked-v2 EXACT; victim now tracks native's exact keyframe sequence
(gate `test_hui_grab_victim.sh`, `GRAB_VICTIM_EXPECT=matches`, peak Δ=0).

Retraction logged (STATE 14z-73): I first mis-measured "positioner never
invoked" by breakpointing the vanilla engine copy `0x2802e`; H's grab
routes to its ported CLONE `0xc9eb0`. The positioner was always invoked;
the bug was pure data.

## 2. Win quote — cosmetic, root-caused, not built (does NOT block freeze)

The consumer's `lea -4(a0,d0.w)` bias means it reads index `0x60+id-1` =
0x6F where we repointed 0x70. His records are vs2 `0x2A5F36`/`0x2A6346`
via bases `0x267426`/`0x2674A6`.

## 3. FG pacing — RESOLVED by observation (14z-73) ✓

With correct sprites the maintainer re-evaluated the FG super: it feels
fine. The "slowness" was the broken GFX, not a timing bug — no timing change
was ever needed. **Do not chase it.**

## 4. FREEZE Phobos — the remaining step

`build/hui26` is the freeze candidate. Freeze = registry row + expectation
set, maintainer-gated. Only the cosmetic win quote (§2) is open, and it need
not block. Full H battery was GREEN on hui26 (see the 14z-73 build-registry
note). Before freezing: make hui26 the launcher default, confirm the
maintainer wants to freeze with the win quote still open (or fix it first).

---

## After Phobos: Pyron

Ladder stages 1-4 exist and are green; nothing renders yet. Three things
from 14z-71 to carry in:

- **Re-check `gfx_layout3.toml`'s "one-source-bank premise" BEFORE his gfx
  rung.** It is incomplete: a tenant with a type-4 effect draws from a
  second gfx bank. Huitzil's beam takes its muzzle and tip from his own
  band and its stretching middle from bank 1.
- **Read `docs/project/porting_sprite_lists.md` first** — four questions
  to ask of any ported effect, each with its mechanism, safety argument
  and gate. It exists so Pyron does not re-pay Huitzil's beam.
- **A render-layer gate is the outstanding suite gap** (maintainer's
  point): every audit we have — empty tiles, OBJ dumps, tile-content
  hashes — lives on the DATA side. *The tiles being there and fetched does
  not mean they are shown.* The beam and the grab lightning are
  known-good references to seed one from.
- **If Pyron grabs/throws, port his per-attacker `slot_ptr_table` rows
  (14z-73).** Tables like the grab-hold keyframes (`0xBE27A`) and any other
  per-ATTACKER-char pointer table are 32 rows where the variant half
  (0x10-0x1F) ALIASES the vanilla half — a tenant at a variant id silently
  inherits a vanilla character's data until its row is repointed. Huitzil's
  `grab_hold_keyframes` / Donovan's `throw_victim_keyframes` are the
  template; `tests/test_hui_grab_victim.sh` is the A/B gate to clone.

---

## Read before your first attribution

`docs/project/gotchas.md`, the 14z-71 entries: *a symptom grouping is a
hypothesis*, *when a claim changes grep for the claim*, and *cross-build
A/B beats analysis*. Plus **CLAUDE.md §5's RETRACTION DISCIPLINE**, which
is new this session.

**The four instrument failures of 14z-71, because they will recur:**

1. A `wpset` watchpoint is **silently blind to pc-relative reads** — CPS-2
   serves them from AS_OPCODES, so dispatch tables need `wposet`
   (`WATCH=...,r,o`). It reported 0 where the truth was 598.
2. **MAME parses a watch length as HEX.** A ten-byte window (`a`) the
   tracer's regex rejected killed the run before it started and wrote an
   empty trace — indistinguishable from "0 accesses". Truth was 39.
3. **The boot RAM test writes every byte of work RAM**, so a bare write
   count on any address returns phantom hits. Filter by PC.
4. **An atlas parse with a hardcoded size** fell back to an empty range
   and reported a cheerful "unarmed" — a blind instrument wearing a pass.

The defence that worked on all four: **a positive control on the same
instrument and the same leg.** A dead instrument and a real finding are
the same shape from outside.

**And the two things that beat analysis outright:** the maintainer naming
wrong art from a screenshot, and a two-build A/B playtest settling an
attribution that six build-dumps had got backwards. Send captures early;
bisect the builds before analysing the code.

---

## What the beam was, in three lines (for context, not action)

vsav ships effect-class row 16 as a **stub** where vs2/vh2 carry the
beam's handler; its drawer has **no list-type 12** (the composite) and the
table can neither grow nor move; and its type-4 handler biases tile codes
**+0x3800 where vs2 uses +0x4200** — one byte — while composing its own
gfx bank. Fixed by a ported handler on a dead class row, a takeover of the
unused list-type 6, and a ported type-4 copy with both constants
corrected. Zero legacy cycles. Full write-up:
`docs/game/atlas/sprite_lists.md` and `engine_internals.md`'s
"sprite-list DRAWER".
