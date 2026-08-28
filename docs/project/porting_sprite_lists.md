# Porting a tenant's sprite lists (and their effects) to the WIDE track

What a tenant port must do so that ported vs2/vh2 sprite lists draw
correctly on vsav, under the CPS-2 WIDE profile.

**Read first:** `../game/atlas/sprite_lists.md` (the drawer, list formats,
the per-game bias table — the FACTS) and
`../game/engine_internals.md` "The sprite-list DRAWER" (the synthesis).
This document is only the project's side: what to build, in what order,
and which checks to run.

Worked instance throughout: **Huitzil's freeze ray** (14z-71), the first
effect that exercised every one of these.

---

## **[VSP-159]** The four questions to ask of any ported effect

Ask them in this order. Each one has cost a session at least once.

### 1. Does the host have the CLASS row?

Object pools dispatch on the object's class byte `+0x02` through a 38-row
handler table (vsavj `0x080AAC`). **vsav ships rows 16/17/19/31 as stubs**
where vs2/vh2 carry handlers. If the tenant's object sets one of those
classes, it is dispatched into a `rts` and nothing happens — while every
other symptom looks healthy.

*Mechanism:* port the vs2 handler family as a region root and repoint the
row with `[[code_ptr]]` (the table is read through the OPCODE view, so it
is a `code` op, never `poke32`).

*Safety:* the row must be dead in vanilla — measured, with a positive
control, in `tests/audit_effect_class_rows.sh`. See **the deadness
register** in `STATE.md`.

### 2. Does the host have the LIST TYPE?

vsav's drawer has six list types, vs2 seven. The table can neither grow
(entry 0's offset *is* its length) nor move (the dispatch is `(d8,PC,Xn)`).
A ported list of a missing type jumps off the end of the table.

*Mechanism:* take over a list type that vsav does not use. Types **6 and 8
are dead in vanilla** (0 reads across the legacy suite, against controls of
4329/2702/2260/321 on types 2/10/0/4). Write a 6-byte `jmp` over the dead
handler's head and retype the tenant's own lists with `[[port_patch]]`
rows.

*Do NOT* repoint type 10 because its handler is a bare `rts` — legacy
dispatches it 2702 times per replay. A no-op handler is not a spare slot.

*Safety:* make the assumption non-load-bearing. The ported handler
discriminates on an **address range** (is this list inside our own placed
region?) and anything else falls through to the host's original code,
reproduced instruction-for-instruction — so if the deadness claim is wrong,
vanilla still renders correctly. The fallback bumps a tripwire counter that
a gate asserts stays zero.

### 3. Does the handler carry a game-specific CONSTANT?

**Types 4, 6 and 8 bias every emitted tile code**, and the two games
disagree: vsav `+0x3800`, vs2 `+0x4200`. Otherwise the routines are
byte-identical. Ported vs2 data lands **0x0A00 low** and draws whatever art
is there.

*Mechanism:* port a copy of the handler carrying the SOURCE game's bias,
plus any placement shift, and dispatch only the tenant's lists to it.
Huitzil's: `0x4200 + 0x3800` (group-C shift) = `addi.l #$7A000000`
(was `0x4200 + 0x1000 = addi.l #$52000000` until the 14z-83 relocation —
the old dst sat inside Pyron's native band, the one real collision in
the merged group-C write set).

*Alternative rejected:* shifting the raw codes in the ported list data
would fix the bias but not the bank (below), so the handler copy is needed
regardless — doing both constants in one place keeps the ported data
byte-faithful to vs2.

### 4. Where does the art's BANK come from?

| list type | bank source | consequence |
|---|---|---|
| 0, 2, 8 | the object's `+0x18` (per-char OBJ bank table row) | relocates with the character — nothing to do |
| **4** | **hardcoded** `ori.w #$2000` = bank 1 | cannot reach WIDE group C at all without a ported handler |

So **a character's effects may draw from more than one gfx bank.** Huitzil's
beam takes its muzzle and tip from his own band (bank 3) and its stretching
middle from bank 1. A layout that assumes one contiguous source band —
which `build/manifest/gfx_layout3.toml` still asserts as its
"one-source-bank premise" — is incomplete for any tenant with a type-4
effect. **Re-check this for Pyron before his gfx rung.**

*Mechanism:* the ported handler supplies the group-C bank
(`ori.w #$1000` = bank 4), and `--strip-tiles` copies the source bank's art
into group C at `code + shift`.

---

## Placing the art

`tools/build_gfx_donovan.py --strip-tiles build/manifest/strip_tiles/<char>.json`

```json
{ "shift": "0x3800", "tiles": [ 20128, 20129, ... ] }
```

Copies **vs2 bank-1** tile `c` to **group C bank 4** tile `c + shift`, with
readback verification. Rules:

- **The shift must be 16-aligned.** Multi-tile sprites wrap the column
  index within the base's row of 16; an unaligned shift breaks the wrap.
- **The shift must equal the one baked into the ported handler's bias.**
  They are the same number in two places; a gate freezes both.
- **Destination must stay below the frozen ceiling** (Donovan's `SAFE_LO`,
  `0xAD80`) and clear of the tenant's own band.
- **Do not place into the host's own bank 1.** It looks free — the handler
  hardcodes that bank, so same-code placement would need no port at all —
  but it is measured **160-of-240 occupied** at Huitzil's codes. Writing
  there overwrites host art.

### **[VSP-160]** Inventories are SPANS, not samples

Sampling what the game draws gives a partial answer, twice over:

- sampling **native** gave `0x4EC0-0x4F9F` and missed the pal-05 strips at
  `0x4EB0`/`0x4ED0`;
- sampling **our build** gave a different set again, because the two legs
  select different lists at the frames sampled.

Take the whole span of the effect's family (Huitzil: `0x4EA0-0x4FBF`). The
extra copies are inert and group C has room. This is the 14z-70f grenade
lesson, re-paid at full price.

---

## **[VSP-161]** Order of work, and the checks at each step

| step | do | check |
|---|---|---|
| 1 | class row (`[[code_ptr]]` + region root) | `test_hui_boot.sh` legacy EXACT; the effect's anim is now entered |
| 2 | list-type takeover (`[[site_thunk]]`, `rts_ok`) | `test_beam_list_type6.sh`; `audit_effect_class_rows.sh` incl. the tripwire |
| 3 | ported type-4 handler (bank + bias) | `test_beam_list_type6.sh` §1b/§1c |
| 4 | tile span (`--strip-tiles`) | `audit_empty_tiles.sh` **on the effect's own replay** |
| 5 | look at it | snapshots vs native at matched frames |

Step 5 is not optional and step 4 does not replace it: `audit_empty_tiles`
passed on a build whose strip was drawing the wrong art at full opacity,
because the tiles it drew were real — just someone else's.

**Run `audit_empty_tiles.sh` with the effect's OWN replay.** Its defaults
never fire the effect you just fixed, so it will pass vacuously.

---

## What this cost, so it is not re-paid

Huitzil's beam took two sessions and five wrong builds. Every wrong turn
was inference where a measurement was available:

- "the beam object is never created" — it existed; it was never *driven*
- "a vs2-only routine FOLLOWS the shared one" — address adjacency; it was a
  sibling row in the same table
- "the handlers are byte-identical, the one difference is a relocated
  address" — that byte was the bias, and the whole defect
- "the strip's tiles were never copied" — they were; the codes were wrong
- three separate blind instruments, each reporting a confident zero

The measurement that ended it was not an analysis at all: the maintainer
asked why a beam would waste ROM on non-repeating tiles, which sent us to
look at the tile CONTENT (horizontal stripes, uniform left-to-right,
16 identical copies) and from there to the emitters.
