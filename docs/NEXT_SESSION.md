# NEXT SESSION — orientation (session 14z-60, 2026-08-04)

Read STATE.md session **14z-60** first (it closes the two queued items and
corrects the previous session's cursor record), then `14z-59..59m` for the
WIDE/dual-track background, then `docs/cps2_wide.md`. The approved
architecture plan is archived at ~/.claude/plans/glowing-bouncing-iverson.md.
The maintainer tests frequently and reports precisely — their reports are the
project's best instrument; reference data they provide goes straight into gates.

## Ship state — DUAL TRACK, both green

| Track | Fingerprint | Packs as | Runs on |
|---|---|---|---|
| **stock** (compatibility) | `ae701ffb` | `vsavj.zip` | unpatched FBNeo/MAME |
| **WIDE** (roster) | `ac52eeff` → `donovan-m5w` | `vsavjw.zip` | PATCHED emulators only |

Both come from ONE manifest; the stock build is structurally incapable of
depending on the extension.

**M5 sound is AUDIBLE on the WIDE track** — Donovan's shared sfx reach the
QSound ring, zero music-range ids. **Still awaiting the maintainer's FBNeo
playtest of `ac52eeff`.**

```sh
export ROMDIR=/path/to/reference/sets
KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open \
  --profile cps2-wide-v1" tools/build_donovan.sh 6 build/m5w
tools/run_wide.sh build/m5w fbneo        # or: ... mame
```
**Stock MAME says "unknown system" — that is an EMULATOR problem, and
renaming `vsavjw.zip` to `vsavj.zip` re-creates the music bug.** See GOTCHAS.

## The id-space question is ANSWERED (14z-60): CONVENTIONAL

It blocked the roster design and the per-tenant manifest shape. Both are
now unblocked. Full detail: `docs/atlas/id_space.md`.

- Every id `0x00-0x1F` has **real storage** in all 39 layout-verified
  id-indexed tables — **0 out-of-range**. vsavj just fills the upper half
  with copies (except `0x18` Oboro, and `word_pos_a[0x16]`).
- The only narrowing is **5 consumer sites that mask to 4 bits**
  (addresses in the atlas page). **vsav2 folds at only 2** and masks to 5
  bits at 6 sites where vsavj does at 3 — Capcom shipped three characters
  on variant ids by *widening those sites*. Finite work list, not a wall.
- **So option 1 needs NO indirection.** Give the newcomers their native vs2
  ids — **Huitzil `0x10`, Pyron `0x11`, Donovan `0x13`** — and every ported
  bank row lands at its own index with no renumbering.
- Caveat that bounds it: 226 of 269 read sites showed no mask within 10
  instructions; **the five-site list is a LOWER BOUND**, frozen by
  `tests/test_id_space.sh` so growth is visible.

## The select cursor is MEASURED (14z-60) — and the old record was wrong

`docs/atlas/select_screen.md`, gate `tests/test_select_wheel.sh`.

- `TABLE A` `PRG:0x0211D4` (16 B) — joystick nibble → direction 0-7.
- `TABLE B` `PRG:0x0211E4` — 8-way adjacency, 8 bytes/cell, **32 rows**.
- **Commit: `PRG:0x020A7C`** (cursor cell) and **`PRG:0x020A80`** (char id),
  same value — so the wheel cell index IS the character id. *The
  previously recorded `PRG:0x020A84` is the `bsr` after them.*
- **Direction order is R,L,D,U** — not U,D,L,R. TABLE A's shape cannot
  distinguish the two (see GOTCHAS).
- Both tables are **DATA-space**; in the opcode image they are convincing
  garbage.
- Verified live: a generated walk over **all 128 (cell,direction) pairs**
  reproduces TABLE B exactly, every write from the commit PC.

## DO THIS FIRST — the roster edit is now a specified data change

Everything mechanical is measured. Remaining for option 1:

1. **Three TABLE B rows** at `0x10`/`0x11`/`0x13` plus edits to
   neighbouring rows so the three are reachable — 24 bytes of new table
   plus the reachability edits. vs2's own table is the worked example
   (`python3 tools/select_wheel.py build/out/vsav2_data.bin --set vsav2`).
2. **A decision per folding site** (5 listed in `id_space.md`): inherit the
   base character's value, as vs2 chose twice, or widen. `PRG:0x04FAC4`
   folds because its table genuinely has 16 rows — widening it means
   growing a table, so each site needs its own judgement.
3. **Cell coordinates + medallion art** — waiting on the maintainer's
   console-port capture (below).
4. Then per-tenant manifests, on the declaration list in `id_space.md`.

Note this moves Donovan off slot `0x0F` (Jedah) onto `0x13`, which is the
already-queued "move Donovan off Jedah's slot", now with a target id.

## Waiting on the maintainer

- **FBNeo playtest of `ac52eeff`** (the WIDE build with audible M5 sound).
- **A full-frame lossless PNG of the console-port select screen** at native
  resolution, ideally with the cursor on each of the three newcomers (and
  P1/P2 if they differ). It pins the three cell coordinates and lets the
  intended adjacency edits be inferred.
- **M5 voice samples: DECIDED 2026-08-04** — A then B, option C rejected,
  gates stay strict. Nothing to ask.
- **MAME determinism** — policy "A then B" ratified; gates stay STRICT;
  option C (a tolerance class) is NOT adopted and may not be re-proposed.

## Gates added this session

`test_select_wheel.sh` (9 checks: static decode both sets + 128 measured
transitions + 4 negative controls) · `test_id_space.sh` (7 checks).
New instruments: `tools/select_wheel.py`, `tools/check_wheel_walk.py`,
`tools/audit_id_space.py`. New atlas pages: `docs/atlas/select_screen.md`,
`docs/atlas/id_space.md`.

## The lesson this session kept re-teaching

**A finding that lives in only one document is not a finding yet.** The
cursor mechanism existed solely in the previous NEXT_SESSION.md — a file
rewritten wholesale every session — with one address wrong, and STATE.md
flatly contradicting it. Re-deriving it took half a session and corrected
two things. Findings go in the atlas AND a gate, at discovery time.

Second: **a clean null is a bug report about the measurement.** The
id-space classifier's first run said "no site narrows the character id"
because capstone mnemonics carry size suffixes and every comparison
silently matched nothing — the answer the author was hoping for, from a
tool that had measured nothing at all.

## Gotchas most likely to bite next session

- A worktree branches from **`origin/main`**, which here is ~18 sessions
  stale — check `git log -1` after creating one (new GOTCHAS entry).
- MAME write taps must be **word-aligned** (`ff8402,2`, not `ff8403,1`).
- Tables read via `lea (pc)` are DATA-view; `(d8,PC,Dn)` operand fetches are
  OPCODE-view. Check the READ MODE, not the address.
- `grep -q "STRING" <binary>` is unreliable — use `strings -a | grep`.
- Wheel/OBJ records: find them by the coord pointer at `base-4`, never by
  pattern-searching for icon codes.
- A fingerprint equal to a known registry row means a bug, not a match.
- DUMPS separator is `;`; ranges are END-INCLUSIVE.
- `ROMDIR` must pass `tools/audit_roms.py` first; keep it play-free.
