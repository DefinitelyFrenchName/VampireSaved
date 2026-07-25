# GOTCHAS — traps that cost real debugging time

Append the moment one is paid for. Read before touching the related area.

## CPS-2 ROM file byte order is NOT 68k logical order (paid: 2026-07-25, ~1h)

The 16-bit words in the dumped program ROM files are stored **low-byte-first**.
MAME's `cps2_decrypt` operates on the `uint16` values you get from reading the
file little-endian (that's what the region layout gives it on a little-endian
host), NOT on big-endian words. Interpreting the files big-endian and
decrypting "works" (self-consistent, round-trips) but produces garbage that is
deceptively half-right: byte-symmetric words like `0x0000` decrypt identically
either way, and the 68k vector table alternates `0x00xx`/`0xxx00` words, so a
spot check of the first bytes shows a plausible mix of matches. **Symptom to
recognize:** a diff against a known-good image where "every other word
matches" in vector/data areas.

Project conventions locked in after this (see tools/cps2_decrypt.py header):
- ROM **files**: word = little-endian byte pair (as dumped).
- Raw **images** (opcode view, data view, MAME Lua dumps): 68k logical order,
  big-endian words — what the CPU and a disassembler see.
- The decrypt oracle test (tests/test_decrypt_oracle.sh) pins all of this
  against MAME's opcode space; run it after touching any byte-order code.

## MAME `logerror` output needs `-log`, not `-verbose` (paid: 2026-07-25)

`-verbose` only shows OSD chatter. Driver `logerror()` lines (e.g. cps2's
`cps2 decrypt <key0>,<key1>,<lower>,<upper>`) go to `error.log` in the
working directory only when `-log` is passed. That line is the fastest way to
get the authoritative key/range for a set.

## FBNeo fresh builds need `SKIPDEPEND=1` (paid: 2026-07-25)

`make sdl2` on a fresh clone dies with `No rule to make target 'driverlist.h',
needed by 'burn.d'` — the depend-generation path (DEPEND=1 default) wants the
generated `driverlist.h` via a bare-name prerequisite that vpath can't resolve
before the file exists. FBNeo's own CI never builds that path: every workflow
passes `SKIPDEPEND=1`. Use `make sdl2 SKIPDEPEND=1 -j8`. (Consequence: no
header-change tracking — after editing FBNeo headers, `make clean` or touch
the affected .cpp files.)

## FBNeo shared EEPROM breaks run-to-run determinism (paid: 2026-07-25, ~45min)

Symptom: consecutive scripted FBNeo runs of vsavj diverged from frame ~75 by
exactly ONE work-RAM byte (`RAM:$FF0CC9`) whose value differed by 1 — the
game's EEPROM bootup counter. Cause chain: (a) `$HOME` overrides do NOT
sandbox FBNeo on macOS — the user config ini (loaded from the real
`~/Library/Application Support/fbneo/`) carries absolute support paths;
(b) `szAppEEPROMPath` then points every run at the same `vsavj.nv`, and the
bootup counter increments per boot. Runs shorter than the EEPROM write-back
looked deterministic, which disguised the cause. Fix: the harness forces
`szAppEEPROMPath`/hiscore/cheat paths into the per-run sandbox cwd
(`main.cpp`, harness-active branch). Debug method that found it: per-frame
full work-RAM dumps from two runs, diffed → first divergent frame + address
(the standard bug-report format works for emulator bugs too).

## Pre-seeded from the ROM-audit round (2026-07-25, before repo existed)

- **MAME audits the whole board, not just the game:** FBNeo has decryption
  keys compiled in and synthesizes QSound (HLE) without the DSP dump; modern
  MAME requires per-set `.key` files AND the shared device romset
  `qsound_hle.zip` (`dl-1425.bin` — one copy in the rompath serves every
  QSound game, but the audit lists it as missing under *every* dependent
  game, which looks like mass failure). A collection that "works everywhere
  but fails MAME audit" is usually packaging/device ROMs, not bad dumps —
  read the audit line items. Also: `-verifyroms` uses the rompath from
  mame.ini unless `-rompath` is passed — it can "fail" sets it never opened.
- **vhunt2r1 has no key of its own:** its MAME definition loads the parent's
  `vhunt2.key` under that exact filename (identical board key across both
  revisions, CRC 61306b20).
- **Clone/parent split:** `vsavj` and `vhunt2r1` are clones; in split sets
  their gfx/QSound ROMs live in the parent zips (`vsav.zip`, `vhunt2.zip`),
  which must be present alongside.
