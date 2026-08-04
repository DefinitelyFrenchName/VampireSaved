# NEXT SESSION — orientation (session 14z-59, 2026-08-04)

Read STATE.md sessions **14z-59 .. 14z-59m** (this session: B5, B5b, Phase C
steps 1-2, and the roster decision), then `docs/cps2_wide.md`. The approved
architecture plan is archived at ~/.claude/plans/glowing-bouncing-iverson.md.
The maintainer tests frequently and reports precisely — their reports are the
project's best instrument; reference data they provide goes straight into gates.

## Ship state — DUAL TRACK, both green

| Track | Fingerprint | Packs as | Runs on |
|---|---|---|---|
| **stock** (compatibility) | `ae701ffb` | `vsavj.zip` | unpatched FBNeo/MAME |
| **WIDE** (roster) | `ac52eeff` → `donovan-m5w` | `vsavjw.zip` | PATCHED emulators only |

Both come from ONE manifest; the stock build is structurally incapable of
depending on the extension (profile-gated spaces and content rows do not
exist for a build that did not ask for them).

**M5 sound is AUDIBLE on the WIDE track** — Donovan's shared sfx reach the
QSound ring for the first time, with zero music-range ids. Awaiting playtest.

```sh
export ROMDIR=/path/to/reference/sets
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
  --profile cps2-wide-v1" tools/build_donovan.sh 6 build/m5w
tools/run_wide.sh build/m5w fbneo        # or: ... mame
```
**Stock MAME says "unknown system" — that is an EMULATOR problem, not a ROM
problem, and renaming `vsavjw.zip` to `vsavj.zip` re-creates the music bug
while looking fine.** See GOTCHAS.

## DO THIS FIRST — the id-space question (blocks the roster design)

The select-cursor mechanism is now fully mapped (14z-59l):

- `TABLE A` `PRG:0x0211D4` (16B) — joystick nibble → direction index 0-7.
- `TABLE B` `PRG:0x0211E4` (128B) — **8-way adjacency, 8 bytes per cell,
  16 cells**. Verified period-16, every cell a target, fully connected.
- Commit site `PRG:0x020A84`: `move.b d0,($03,a6)` and `move.b d0,($382,a6)`
  write **the same value** — so **the wheel cell index IS the character id**.

Adding 3 cells is therefore 24 bytes of table plus edits so they are
reachable — a pure data change. **But** ids `0x10-0x1F` are the variant/
alternate half that aliases `0x00-0x0F` (`mirror_variant = true`; every bank
repoint patches both `0x0F` and `0x1F`).

**THE QUESTION: is that aliasing a hard architectural half, or a convention
only some tables follow?** The answer decides whether option 1 needs three
genuinely free ids or an indirection between wheel slot and character id —
and it decides what a per-tenant manifest must declare. **Do this before
designing per-tenant manifests**, or the abstraction will be wrong.
Method: the write tap now exists — `FBNEO_HTAP` on the id-consuming tables,
plus a census of who masks/compares against `0x0F`/`0x10`.

## Roster access — DECIDED (maintainer, 2026-08-04)

**Option 1: an altered select screen.** Keep the existing cells and the
random medallion exactly where they are; **append** the three newcomers.
Imperfect new-medallion art is acceptable; mechanical soundness is not.
Fallback (only if 1 fails): hold-Start alternates, which needs vsav
characters "stacked" to free slots.

Measured, and it corrects two earlier claims of mine (14z-59l):
- vsavj wheel `0x272A72` / coords `0x32A50A`: 18 OBJ entries (2 are 1x1
  decorations), 16 navigable cells, one 3x3 (Gallon, pal 07).
- vs2 `0x2A6E5C` / coords `0x303B68`: 24 entries over **21 distinct
  positions**, **no 3x3**; the three newcomers OVERDRAW placeholder cells.
  So vs2 gives Capcom's 21-position geometry as a **rearrangement**, NOT
  vsavj's 18 plus three. It still supplies the newcomer medallion ART codes
  (`b108` Huitzil pal 13, `b0f5` Pyron pal 11, `b10b` Donovan pal 05) —
  the expensive part.
- Records are found by a coord-list longword at `base-4`. Pattern-searching
  for icon codes finds MISALIGNED bases; that is what produced both wrong
  claims.

**Waiting on the maintainer:** a full-frame lossless PNG of the console-port
select screen at native resolution, ideally with the cursor on each of the
three newcomers (and P1/P2 if both differ). It pins the three cell
coordinates and lets the intended adjacency edits be inferred.

## Still open (maintainer)

- **M5 voice samples** — 8 MB of QSound headroom, hard-capped by MAME's
  16 MB ceiling (`device_rom_interface<24>`). If three voice banks do not
  fit, the answer is exclusivity/banking, not more region.
- **MAME determinism** — policy "A then B" ratified; A measured (~2,400
  clean runs; flat per-run rate and machine load both RULED OUT), leading
  explanation is host input, now closed at source. Gates stay STRICT; option
  C (a tolerance class) is NOT adopted and may not be re-proposed.

## Queued work

1. The id-space question above.
2. **Per-tenant manifests** — after (1). Then slot parameterisation, gfx band
   planning, moving Donovan off Jedah's slot.
3. WSL2 stand-up on the Windows box (`docs/WSL2_SETUP.md`);
   `tests/test_mame_parity.sh` is the machine-migration gate. If it fails
   there, do NOT re-freeze to make it green.

## Gates added this session

`test_mame_parity.sh` (62/62) · `test_mame_wide.sh` (36/36) ·
`test_replay_video_selfcheck.sh` · `test_mame_determinism.sh` ·
`test_input_integrity.sh` · `test_fbneo_instruments.sh` ·
`test_phasec_spaces.sh` · `test_phasec_image.sh` · `test_dualtrack.sh` ·
`test_crypt_boundary.sh`

New instruments: `tools/analyze_divergence.py`, `tools/attribute_ramdiff.py`,
`tools/setup_mame.sh`, `tools/run_wide.sh`; FBNeo `FBNEO_HTAP` /
`FBNEO_HPOKE` / address-resolved dumps; MAME `VIDEO_OUT` / `INPUT_OUT`.

## The lesson this session kept re-teaching

**Four false greens, all the same shape: the tool reported success while
measuring or producing the wrong artifact.** `git apply` silently skipping
and exiting 0; a submodule gitlink drifting the WIDE binary to 0.289; a
fingerprint call without `--set` hashing the PRISTINE reference ROM; and
`WIDE=0` never reverting the profile patch, so the FBNeo superset invariant
had been comparing WIDE against WIDE. **Assert on the artifact, never on the
exit code.** Three further bugs were in my own new tests' verdict logic,
caught only because §4 requires ground-truthing a verdict before trusting it.

## Gotchas most likely to bite next session

- `grep -q "STRING" <binary>` is unreliable — use `strings -a | grep`, or
  ask the emulator (`-listfull vsavjw`).
- Wheel/OBJ records: find them by the coord pointer at `base-4`, never by
  pattern-searching for icon codes.
- Tables read via `lea (pc)` are DATA-view — dumping them from the opcode
  image gives plausible garbage.
- A fingerprint equal to a known registry row means a bug, not a match.
- DUMPS separator is `;`; ranges are END-INCLUSIVE.
- `ROMDIR` must pass `tools/audit_roms.py` first; keep it play-free.
