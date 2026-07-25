# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 2 (M1 in full swing).

**Where we are:** M0 done. M1 harness half DONE: `.rpl` replay format, MAME
runner (`tests/lua/replay.lua`: inputs/checksums/snapshots/RAM dumps),
patched-FBNeo headless runner (patch in `emu/fbneo-patches/`, apply+build
via `tools/setup_fbneo.sh`), both deterministic; 10-replay legacy suite
green and frozen (`tests/run_suite.sh`). M1 mapping half: **character-data
plumbing cracked** — per-character table bank located in all three sets,
vsavj slot→character map COMPLETE (docs/atlas/character_tables.md), RAM
atlas seeded (docs/atlas/ram.md), watchpoint tracer
(`tests/lua/trace_writes.lua`) and pick probe (`tools/pick_probe.sh`)
committed.

**Key open findings to act on:**
1. **vsav2/vhunt2 slot naming** — which slots hold Donovan/Huitzil/Pyron.
   Method ready: probe vsav2's select flow timing (snapshots), then re-run
   the pick-probe pattern there. Blob-similarity hints: vsav2 slots
   {5,7,15} (UNCONFIRMED). Also name the five variant slots {0,1,3,8,9}.
2. **CLAUDE.md §4 amendment awaiting human sign-off** (STATE.md): dual-
   emulator comparison must be field-level at sync anchors, not whole-RAM
   frame-exact (MAME/FBNeo run same states at different frame indices).
3. Table-bank semantic labeling (vsavj PRG:0x0BD0FA-0x0BE8xx: ~16
   code-ptr tables + data tables per character) — label by tracing what
   consumes each (method proven).
4. Work-RAM map completion: HP/timer/positions/meter offsets in the player
   struct (differential experiments; hit/idle comparisons).
5. Formally close slot 0x09 = Aulbath with one pick (path: L L is
   Sasquatch's neighbor; find Aulbath's cursor path).

**Read next:** STATE.md, docs/atlas/character_tables.md, docs/GOTCHAS.md
(three new paid-for entries: ROM byte order, FBNeo SKIPDEPEND, FBNeo shared
EEPROM).
