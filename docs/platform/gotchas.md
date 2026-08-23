# GOTCHAS (platform) — traps in CPS-2 and in the emulators

Hardware, encryption and gfx-addressing facts, plus MAME/FBNeo
behaviour and their build systems. Reusable by any CPS-2 work; none of
it is specific to this roster hack.

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

## MAME `-debug` perturbs multi-CPU timing — never compare its checksums to non-debug runs (paid: 2026-07-25, ~1.5h)

A vsavj replay run under `-debug -debugger none` produces a checksum log that
diverges from the identical non-debug run at frame 12: `RAM:$FF1CF0.l` (a
latch toggling 0x00000000/0xFFFFFFFF) is phase-shifted by one frame, with
±1 knock-on counters later ($FF8080, $FFE420...). It is fully deterministic
*within* debug mode (two -debug runs are bit-identical) and unaffected by how
the initial debugger halt is resumed (`-debugscript go` vs Lua periodic —
identical output). Working theory: the debugger forces finer scheduler
timeslices, shifting 68k↔Z80/QSound interleave; the mechanism doesn't matter,
the rule does:

- **Checksum-exact gates (superset invariant, determinism) run WITHOUT
  `-debug`** — plain `tests/lua/replay.lua` or `replay_guard.lua` cheap mode
  (`GUARD_DEBUG=0`), which are bit-identical to vanilla expectations.
- `-debug` guard runs (breakpoint crash detection) are for crash/field-level
  verdicts only. If a frozen expectation for a -debug run is ever needed, it
  must be frozen from a -debug run.
- Two misleading dead ends already explored: it is NOT the debugger's
  different initial-RAM fill pattern (real, but game clears RAM first), and
  NOT a lost frame at the initial debugger halt.

Also paid in the same session, worth remembering: in MAME debugger
expressions, bare hex like `d0` parses as the **register** D0 — always write
breakpoint/watchpoint addresses with an explicit `0x` prefix
(`bpset 0xd0`). Symptom: the breakpoint silently never fires (or fires
somewhere bizarre) for addresses that look like register names.

## PC-relative reads are DECRYPTED reads on CPS-2 (paid: 2026-07-25, ~45min)

The 68000 issues PC-relative operand reads with FC = program space, so the
CPS-2 B-board decrypts them like opcode fetches. Consequence: tables read
via `(d8,PC,Dn)` / `(d16,PC)` (e.g. the secondary-object type dispatch at
vsavj `PRG:0x054470`, table `0x054484`) are stored ENCRYPTED — their bytes
only make sense in the opcodes view, while normally-addressed data must be
stored raw. Symptom: a "table" that looks like garbage in the data view but
decodes perfectly in `*_opcodes.bin` (or vice versa).

Port rules that follow:
- Whole code regions ported as `code` ops keep working even when they embed
  PC-read tables — the embedded tables re-encrypt with the code.
- A hook that changes an access from PC-relative to An-relative (like the
  proj_hook thunk) changes the fetch space: the new table must be emitted
  RAW, and its source entries must be COPIED FROM THE DECRYPTED view.
- When reading engine tables for analysis, pick the view by how the ENGINE
  addresses them, not by where they live.

INSTANCE, 14z-79 — RELOCATING a pc-relative dispatcher, not just its table.
The (b') thunk had to reproduce vsavj's `move.w (6,PC,D0.w),D1 / jmp
(2,PC,D1.w)` at `0x018460` from a thunk in hole_a, ~0xE4A48 away — far past
the +/-127 an 8-bit pc-displacement reaches. The design of record (STATE
14z-78) therefore rewrote the read as `lea 0x018468,a0 / move.w (0,a0,d0.w),d1`
— textbook second-rule territory, and it would have shipped: measured on the
two views, **38 of the 80 legacy targets come out ODD in the data view** (all
80 are even in the opcode view), i.e. an address error on the hottest path in
the game. Cheap discriminator, worth running on any table before trusting a
read of it:

    opcode view:  min 0x01867a  max 0x0187a6  odd 0/80
    data   view:  min 0x0104c8  max 0x02025b  odd 38/80   <- ciphertext

The fix used the FIRST rule rather than the second: carry a copy of the table
INSIDE the thunk body, which is emitted as a `code` op and so re-encrypts with
it, and keep reading it pc-relatively. No raw-copy machinery, no view
conversion, and the read decrypts back to exactly what was authored. Prefer
that shape whenever the mover is a thunk rather than a whole ported region.

## CPS-2 gfx simms are not tile-contiguous — naive slicing silently "works" on siblings only

A 16x16 tile's 32 bytes within a simm are 16 two-byte PAIRS at stride 4
(even/odd word streams of each 0x80000 block feed decoded chunks 1MB
apart — see tools/gfx_tiles.py header for the exact mapping, derived
from FBNeo Cps2LoadOne). Slicing contiguous 32-byte runs mixes bytes of
tiles 1MB apart. The trap: same-index comparisons across sets STILL
MATCH under wrong slicing (same wrong neighbors on both sides), so a
sibling calibration (vsav2 vs vhunt2: 200K tiles "match") certifies a
broken method; all cross-set content-addressed lookups then collapse to
~3% and look like "the art was re-encoded". Cost: half a session of
false hypotheses (plane order, palette permutation). Rule: any binary
structure with a hardware interleave gets its layout verified against
the emulator's loader source BEFORE bulk analysis, and the layout
understanding gets a fact-lock test (tests/test_gfx_tiles.sh).

## MAME breakpoint logging is a SAMPLER, not an inventory

The Lua breakpoint pump (periodic callback resuming `debugger.
execution_state`) drops hits: with six handler breakpoints live during
frames 2596-2600, four record draws were logged while a write-watch
proved at least five occurred (obj $FFBC00's draw never appeared).
Runtime traces give EXISTENCE evidence ("this record IS drawn at bank
2"), never completeness ("these are ALL the records"). Any fix scoped
from a trace must be closed structurally (record streams, pointer
arrays) before it can claim coverage — the Anita-feet 54-record list
came from the stream walk, not from the trace that found its first
member.

## Debugger stops DESYNC replay frame counting

While a Lua breakpoint/watchpoint holds the CPU, MAME keeps emitting
video frames: `emu.register_frame_done` fires, the script's frame
counter inflates past emulated time, and replay INPUT PLAYBACK (keyed
by that counter) drifts — so every high-frequency breakpoint trace
runs a silently desynced replay, and its logged frame numbers are not
comparable to replay.lua frame numbers. (Symptom that exposed it: a
bpset on a routine proven to run 40+ times logged one hit; a "window
2596-2600" trace saw a different game moment than the same frames'
RAM dumps.) Use debugger traces only for EXISTENCE evidence at rare
events; for anything frame-accurate or complete, use replay.lua DUMPS
(exact, no debugger) and read state from RAM — companion-slot cursor
fields survive at frame-done even when the live flag is clear.

## CPS-2 program zips store CODE encrypted — static byte reads of code are noise
Paid for in session 14z-2 (an hour of "why does the ported region disassemble
to garbage"). The romset zips (+ .key) hold ENCRYPTED opcodes; only DATA
reads bypass the crypt. Any static analysis of code regions — diffing a
build against vanilla, disassembling a ported routine, searching for an
instruction pattern — must use the DECRYPTED opcode space:
`tests/lua/dump_opcodes.lua` (MAME's own cps2crypt is the oracle), or the
pipeline's `build/out/*_opcodes.bin`. Data tables MAY be read raw from the
zip members (remember ROM_LOAD16_WORD_SWAP byte order). A "code" op in
patch_prg re-encrypts; that's why plaintext jsr bytes are never found in
the members.

## MAME Lua write taps are silently dropped on handler re-install
`space:install_write_tap` dies (no error) whenever anything re-installs
handlers over the space — CPS-2 does this right after boot. Symptom: tap
logs boot writes only, reads as "nobody writes this field," which is a
WRONG conclusion. `tests/lua/tap_writes.lua` carries the fix (re-install
via `add_change_notifier`); use it instead of hand-rolling taps. Taps are
the right tool for hot fields (positions) where trace_writes.lua-style
watchpoint stops would desync the replay.

## OBJ RAM dumps span BOTH pages — filter by code range and you will
## blame the wrong drawer
A 4KB dump at 0x708000 contains multiple drawers' output (main walker,
doubling/fade drawer, second page). Filtering entries to the expected
code band showed a byte-perfect match while the SCREEN showed garbage:
the garbage came from OTHER entries (raw unremapped codes) outside the
filter. When a render contradicts an OBJ-level match, diff the FULL
unfiltered entry set both sides first (14z-22 — found the un-walked
record subset in minutes once unfiltered).

## PC-relative reads are PROGRAM-space; (An)-based reads are DATA-space —
## absolutizing a pc-relative table read on CPS-2 reads CIPHERTEXT
The 68000 classes `(d16,PC)`/`(d8,PC,Xn)` operand fetches as program
references; CPS-2 decrypts program-space accesses in 0x000000-0x100000.
A site_thunk that faithfully "reproduced" `move.w $185DA(pc,d0),d0` as
`lea $185DA,a0; move.w (a0,d0),d0` read the encrypted bytes instead
(data view table[6] = 0x53BF -> odd jmp target -> vec3 at the first KO
hit; 14z-43). Corollary: a table read via `(pc,...)` lives in the
OPCODES image; the same table read via `lea (pc)`+`(a0,...)` (the
property table 0x28D00 pattern) lives in the DATA image — check the
READ MODE, not the address, when choosing the view AND when relocating
code. Fix pattern: hook an instruction BEFORE the pc-relative read and
rts back into the untouched original (the reaction_hook "ghost-clean"
topology).

## A 68k move.l reaches a memory tap as TWO word writes — a tap keyed
## on the entry base sees only the (zero) high word
The sound-ring tap looked for ids at `FF0E0E + n*16` and reported
"nobody ever plays a sound" across eight Donovan replays. The enqueue
is `move.l d1,(a4,d0.w)`; MAME's write tap fires twice, at +0 (high
word, always 0 for a 12-bit id) and at +2 (the id). Keying on `%16==0`
filtered out every real event and left only ring-clear traffic. When a
tap over a known-busy structure reports nothing, suspect the access
WIDTH before concluding the code path is dead — and log a few raw
(addr, data) pairs unfiltered first.

## OBJ y-word bit 15 is the sprite-list TERMINATOR, not a spare bit
The plan for a 19th tile-address bit was "widen the OBJ mask 0x6000 ->
0xE000", i.e. use y-word bit 15. That bit ends the sprite list
(`CpsObjGet`: `if (ps[1] & 0x8000) break;`), so setting it on a sprite
would silently drop every sprite after it. Capcom's own CPS-2 Turbo hits
this and promotes **bit 12** instead (`if (y & 0x1000) y |= 0x8000`)
AFTER the terminator check. Two lessons: (a) the free bit is 12, with
hardware precedent; (b) before treating any bit in a hardware structure
as spare, find the code that CONSUMES the structure — a census of "which
bits are set" cannot tell you which bits are load-bearing.

## A MAME Lua tap installer must guard against its own change notifier
Installing a memory tap can itself fire the space-change notifier; if the
notifier reinstalls taps unguarded, it recurses until the stack dies —
MAME segfaults with no Lua error and no diagnostic. `tap_writes.lua`
carries an `installing` flag for exactly this reason; new instruments
must copy it. (Separately: MAME can segfault during teardown AFTER
`manager.machine:exit()`. The log is already written, so scripted audits
must assert on the instrument's own SUMMARY line, never on the exit code.)

## FBNeo's d_cps2.cpp is not valid UTF-8, and SKIPDEPEND hides driver edits
Two traps when scripting FBNeo descriptor changes. (1) `d_cps2.cpp`
contains game titles in local encodings, so `open(path).read()` dies with
a UnicodeDecodeError — edit it in BYTE mode, and remember a Python bytes
literal cannot contain non-ASCII characters (an em-dash in a comment is
enough to fail the edit while the surrounding script "succeeds"). (2) The
build uses `SKIPDEPEND=1`, which does not track header or driver changes:
after editing a driver, `touch` the source or the link silently reuses the
old object and the emulator keeps the previous descriptor. Symptom: a
grown region that measures exactly like the stock one.

## FBNeo harness: no video means the sprite path never runs, and stdout
## is captured to the sandbox log
Two ways to waste an hour while instrumenting FBNeo. (1) The harness only
renders when `FBNEO_HVIDEO` is set; without it `pBurnDraw` is NULL and
`Cps2ObjDraw` is never called, so a printf in the sprite path produces
NOTHING — which reads exactly like "my feature flag is not being set".
(2) `tools/run_replay_fbneo.sh` redirects the emulator's stdout+stderr to
`<sandbox>/fbneo_replay.log`; grepping the command's own output finds
nothing. That log is also where FBNeo prints its region sizes and
per-member "Loading graphics (x)... (OK)" lines — the fastest way to
confirm a descriptor change actually took effect.

## FBNeo matches zip members by CRC — a mismatch loads 0xFF FILL and
## still prints "(OK)"
This is the single nastiest trap found in the WIDE work, and it
CONTRADICTS an earlier note in this repo ("FBNeo verified to load
CRC-changed patched zips (no descriptor change needed)"). That note is
true only in the narrow sense that FBNeo does not refuse to RUN. What it
actually does when a member's CRC does not match the descriptor is load
**0xFF fill** for that member — while the log still prints
`Loading graphics (name)... (OK)`.

Symptom: an appended gfx group that reports OK, sizes correctly
(`Graphics data: 0x03000000`), has a correct load destination, a correct
computed tile address and a passing bounds check — and renders nothing,
with the region reading 0xFF in memory. Because `Cps2Load100000` ORs into
a zero-filled buffer, "all 0xFF" is proof the SOURCE bytes were 0xFF,
i.e. the file content never arrived.

Rules that follow:
- Any appended/modified member must have its REAL CRC in the descriptor.
  `tools/build_wide_romset.py` now prints the exact descriptor rows
  (name/size/CRC) for everything it writes — paste those in.
- When the patched PROGRAM members change (every Donovan build), the
  program members are loaded by a path that tolerates this; do not
  generalise "CRC does not matter" from that to gfx/QSound members.
- Diagnostic shortcut: 0xFF in a region that should hold data means "not
  loaded"; 0x00 means "loaded but empty/never written" (the buffer is
  memset to 0 at allocation).
- **Refined 14z-61, and the refinement is the dangerous half.** A CRC
  mismatch does not by itself produce 0xFF fill: `bzip.cpp:158` searches by
  CRC *first* and falls back to the NAME, which is why every patched
  program and gfx member in this project loads at all. 0xFF fill is what
  you get when NEITHER matches. The failure mode to fear is the other one:
  when some OTHER file in the set matches the declared CRC, it is loaded
  INSTEAD, silently and successfully. See "A member carrying another
  member's PRISTINE bytes SHADOWS it" at the end of this file.

## MAME's build system cannot handle a SPACE anywhere in the source path
(paid: 2026-08-03, B5 — ~30 min)
This repository lives under `.../Vampire Saved/...`. MAME's GENie build
dies on that. `scripts/genie.lua:18` carries the escaping line
**commented out upstream**, and `SOURCES=` builds shell out to
`makedep.py` with `MAME_DIR` unquoted, so genie reports the useless
`Error creating projects from specified source files` (the same command
run by hand works fine — that is the tell).

**A symlink does NOT fix it.** GENie resolves the physical path through
`getcwd()`, so a space-free symlink into the repo lands right back on the
space. Verified: `cd $HOME/.cache/.../mame-link && pwd -P` prints the
space path.

The fix is `tools/setup_mame.sh`: the pinned submodule stays the pristine
source of truth and never gets built in, and the build runs from an
rsync'd, space-free mirror under `~/.cache/vampire-saved/`.

## rsync `--exclude 'build/'` also excludes `scripts/build/`
(paid: same session, ~10 min)
An unanchored rsync pattern matches a directory of that name at ANY
depth. Mirroring MAME while trying to skip its output `build/` also
dropped `scripts/build/`, whose `complay.py` every layout rule depends
on. Symptom is far from the cause: `make: *** No rule to make target
'build/generated/mame/layout/18w.lh', needed by 'generate'` — a missing
RULE, because the pattern rule's `complay.py` prerequisite could not be
found. Anchor mirror excludes: `--exclude '/build/'`.

## MAME 0.288's OSD is SDL3 and it is found ONLY through pkg-config
(paid: same session, ~8 min of wasted compile)
`scripts/src/osd/sdl3.lua` decides between framework and library linkage
by asking pkg-config. With pkg-config absent it silently picks framework
linkage, and the build then dies **several minutes in** with
`fatal error: 'SDL3/SDL.h' file not found`. Having the sdl3 library
installed is not enough. Prerequisites are `brew install sdl3 pkgconf`,
and after installing pkgconf the build needs `REGENIE=1` — the detection
is baked into the generated project files.

## A SOURCES-filtered MAME build silently omits drivers missing from mame.lst
(noted while porting WIDE to MAME)
`make SUBTARGET=cps2 SOURCES=src/mame/capcom/cps2.cpp` builds only the
CPS-2 drivers — minutes instead of hours — but the driver list is
generated from `src/mame/mame.lst`. A new `GAME(...)` entry that is not
also added to `mame.lst` compiles fine and is then simply ABSENT from the
binary, with no warning. Both WIDE gates therefore assert
`-listfull vsavjw` before trusting anything else. Also note the binary is
named after the SUBTARGET (`cps2`), not `mamecps2`.

## `src/mame/mame.lst` contains no inline comments — do not add the first
16,000+ entries, and the only `//` lines in the whole file are the two
license headers. A trailing `// comment` after a driver name may or may
not survive the list parser; there is no upstream precedent to lean on and
nothing to gain. Add the bare driver name and document it in
docs/project/patch_index.md instead.

## MAME's "-video none" STILL creates a window that can take focus — and
## host keystrokes are injected into the EMULATED controls
(mechanism supplied by the maintainer, 2026-08-03; implicated in the two
unexplained 14z-59 divergences)
MAME has no true headless mode the way some emulators do. Even with
`-video none` it creates a window, and that window can steal focus. Any
key pressed while it has focus goes to MAME's default keyboard map, which
covers **P1 directions, buttons 1-6, coins and start**. The harness runs on
the maintainer's working laptop, so this is a live hazard, not a
theoretical one — the machine gets used, focus gets grabbed back, and
keystrokes land wherever they land.

**Why it matches the observed signature exactly:** a stray press injects
input the replay script never asked for, RAM diverges for as long as the
key is held, and then RE-CONVERGES the moment the script's own per-frame
staging reasserts every field. Both 14z-59 divergences were bounded
windows that fully re-converged (frames 190-205 and 218-245), both in a
single ~35-minute execution, and neither reproduced in ~2,400 later runs
on an idle machine. A per-run rate and machine load were both ruled out by
measurement; this explains what those could not. **Not confirmed as the
cause — the events were not captured with an input log — but it is the
leading explanation and it is now both prevented and detectable.**

Two responses, both in place:
- **PREVENT**: `tools/run_mame.sh` passes `-keyboardprovider none
  -mouseprovider none -joystickprovider none -lightgunprovider none`.
  Verified non-perturbing against the frozen suite.
- **DETECT**: `tests/lua/replay.lua` checks EVERY frame that the live
  controller bits are exactly what it staged, writes `INPUT-VIOLATION`
  into the log if not, and `tools/run_replay_mame.sh` fails the run.
  Ground truth both directions: `tests/test_input_integrity.sh`.

Related: MAME can also crash outright in some circumstances. That is
already caught — `run_replay_mame.sh` requires a terminating `END` line,
so a truncated log fails rather than being compared.

## The CPS-2 encrypted range is INCLUSIVE of its upper word — 0x100001, not
## 0x100000 (measured 14z-59k)
The project quotes vsavj's encrypted range as `PRG:0x000000-0x100000`
("first 1MB only"). The limit test is `<=` on the WORD address, in both our
`Cipher.crypt_words_at` (`lo <= a <= hi`) and MAME's `cps2crypt.cpp`
(`a >= lower_limit && a <= upper_limit`). So the word at byte `0x100000` is
still ENCRYPTED and the first raw word is at `0x100002`.

No current placement is affected — `hole_a` ends at `0x100000` exclusive, so
all of it is inside; `hole_b` and the WIDE extension are far outside. It
matters the moment anything is placed at exactly the boundary.

Found by a test whose FIRST DRAFT asserted the opposite. The code was right
and the new test was wrong — which is the argument for writing the test
before trusting the behaviour, not after.

## Ported CODE above the encryption window is stored RAW, automatically
`patch_prg.py` re-encrypts every `code`/`code_file` op unconditionally, so
it looks like code placed above 1MB would be corrupted. It is not:
`Cipher.crypt_words_at` is RANGE-AWARE and returns out-of-range words
unchanged, matching how the CPU fetches them. That is what makes the CPS-2
WIDE extension (`$400010-$600000`) viable as a home for ported CHARACTER
code — Donovan's port alone is ~338 KiB and Huitzil/Pyron are comparable,
so this property is load-bearing for the whole roster.

Locked by `tests/test_crypt_boundary.sh`, in both directions (inside must
transform and round-trip; outside must pass through byte-identical). If it
ever fails, ported code above 1MB becomes executable garbage rather than a
loud failure — so it fails the build rather than warning.

## MAME write taps must be WORD-ALIGNED
`install_write_tap` on `ff8403,1` dies with "start address has low bits
set, did you mean ff8402?" — and it is a hard error that kills the script
after a full boot. Tap the containing word (`ff8402,2`) and filter on the
logged mask/offset. Byte writes arrive with the value replicated across
the word (`data 00000303` for a byte `0x03`), so mask the low byte.

## FBNeo's SDL frontend has NO `-rompath` — the flag is silently ignored
(paid: 2026-08-05, 14z-60m — cost the maintainer several failed launches)
`tools/run_wide.sh` launched FBNeo as
`fbneo vsavjw -rompath "<build>;$ROMDIR"`. MAME supports `-rompath`; **FBNeo
does not**. Rom paths live in `szAppRomPaths[]`, defaulting to
`/usr/local/share/roms/` and **`roms/` relative to the CWD**
(`src/burner/sdl/drv.cpp:6`), and are otherwise set from the config file.
An unknown option is not rejected — FBNeo simply searches its configured
paths, finds no `vsavjw.zip`, and reports the set as unavailable. The
symptom therefore reads as "my romset is wrong" when the romset is fine.

The working pattern was already in the tree: `run_replay_fbneo.sh` builds a
`roms/` directory of symlinks (reference zips first, the build's zips
overlaying them) and runs FBNeo from that directory. `run_wide.sh` now does
the same.

Two general lessons: **a launcher that wraps two emulators must not assume
they share a CLI** — the same conceptual argument was supported by one and
silently dropped by the other; and **assert on the emulator's own load
output**, not on the process starting. A healthy WIDE start prints
`CPS-2 WIDE v1 profile active` and 31 `(OK)` member lines.

## A member carrying another member's PRISTINE bytes SHADOWS it — both
## emulators resolve a ROM entry by HASH before NAME
(paid: 2026-08-05, 14z-60z — cost two sessions and a wrong root-cause
hypothesis; the bug reached a maintainer playtest)
Donovan and Anita rendered with vanilla art on the WIDE track — right
geometry, wrong pixels — while every automated gate stayed green.

The WIDE romset's appended gfx group C (`vsw.31m/33m/35m/37m`) was built
with `--gfx-copy-group-b`, the **B4 canary** shape: byte copies of the
stock group B members. Copies carry the ORIGINAL CRCs. The content build
patches group B (`vm3.14m/16m/18m/20m` — that is where Donovan's tiles
live), so at load time the descriptor's declared CRC for `vm3.14m` matched
the *canary copy* sitting in the same set, and the loader served **pristine
tiles** for the member the build had patched.

Measured, both emulators, with pristine and stock-track controls
(`tests/lua/gfx_region_dump.lua`, tile `0x2AD8F`):

| set | decoded tiles at the ported band |
|---|---|
| WIDE build (garbled) | == PRISTINE vsavj |
| WIDE build, group C zero-filled | == stock track (the patched art) |

MAME says it out loud if you know to look: on the stock track all eight gfx
members report `WRONG CHECKSUMS` (the patched art loading by name); on the
WIDE track `vm3.14m/16m/18m/20m` are **silent**, because a hash match was
found — for the wrong file.

FBNeo states the rule in its own comment, `src/burner/sdl/bzip.cpp:158`:

```c
if (ri.nCrc) {                      // Search by crc first
    nRet = FindRomByCrc(ri.nCrc);
    if (nRet >= 0) return nRet;
}
for (int nAka = 0; ...) {           // Failing that, search for possible names
```

So the name is the FALLBACK in both emulators, not the identity. A member's
identity in a set is its HASH, and two files with the same bytes are the
same member as far as the loader is concerned.

Rules:
- **No member of a set may carry the pristine bytes of a member that build
  patched.** `tools/audit_romset_identity.py` enforces exactly this and
  runs inside `tools/build_donovan.sh` and `tools/pack_build.sh`; ground
  truth `tests/test_romset_identity.sh`.
- **A canary romset is not a shippable romset.** The copy shape belongs in
  `build/wide_canary/rompath` and is never passed to `pack_build.sh
  --merge`. `build/wide0/rompath` (zero fill) is the shippable overlay.
- Byte-identical PLACEHOLDER members (several zero-filled 4 MB units) are
  harmless — they can shadow nothing, because no patched member has those
  bytes. The audit reports them without failing.
- This refines the "CRC mismatch loads 0xFF fill" entry above: 0xFF fill is
  what happens when NOTHING matches. When something else in the set matches
  the hash, you get that file's bytes instead — silently, and it looks
  exactly like a working load.

## Dump a tile band WITH its bank bits, or you will exonerate the guilty
(paid: 2026-08-05, 14z-60y/60z — one session spent on the wrong hypothesis)
The sprite record's code word for Donovan's select portrait is `0xAD8F`,
but its y-word selects bank 2, so the tile the hardware fetches is

    tile = code | ((y & 0x6000) << 3)   =   0x2AD8F        (byte 0x156C780)

The 14z-60y investigation dumped byte `0x56C780` — tile `0xAD8F`, no bank
bits — found it byte-identical between the WIDE and stock builds, and
concluded "the tiles load correctly on both tracks, so the fault is in
tile ADDRESSING at draw time". Both halves of that were wrong: the band
compared was unrelated vanilla data (identical on every build by
construction), and the real band differed. The next session then hunted an
emulator rendering defect (y-word bit 12) that measurement later showed is
never even set — `objy_bits.lua` over the whole replay: `bit12=0`,
`max19 == max18`.

Rules:
- Compose the address the way the hardware does before dumping, and print
  the composition in the log (`obj_records_dump.lua` prints `a18`/`a19`
  per entry for this reason).
- A null result from a dump is only as good as the address that produced
  it. Give the instrument a NEGATIVE CONTROL — a band that MUST differ
  (pristine vs patched) — or it can prove nothing. `test_wide_render_
  content.sh` section 4 does this, and it caught a field-index slip in its
  own checker on the first run.

## MAME cross-driver VIDEO_OUT checksums are NOT comparable (14z-62d)

Comparing replay.lua VIDEO_OUT streams between the `vsav`/`vsavj` machine
and the `vsavjw` (cps2wide) machine flags THOUSANDS of "divergent" frames
whose actual bitmaps are pixel-identical — verified by decoding
`video:snapshot()` PNGs at four frames inside "divergent" runs (raw
IDAT equal) while work RAM was bit-identical and the OBJ lists matched
entry-for-entry. The checksum evidently samples something the machine
config perturbs (timing/sampling nuance), not the final picture. Rules:
- VIDEO_OUT is valid WITHIN one machine config (its self-check, the
  determinism gates, stock-vs-stock comparisons).
- For cross-driver pixel comparison use FBNeo FBNEO_HVIDEO (proven exact
  across vsavj/vsavjw in test_wide_render_content.sh) or pixel-compare
  MAME snapshots directly.
- A "divergent framebuffer" claim about a WIDE build measured with MAME
  VIDEO_OUT against stock is UNTRUSTWORTHY until snapshot-verified.

## A chained rompath makes MAME a LIAR about member identity (14z-62h)

The same bug was invisible to every MAME-side measurement: with
`MAME_ROMPATH="<build>;$ROMDIR"`, MAME resolved the stale (CRC-mismatched)
group-B members by HASH to the PRISTINE copies in ROMDIR's vsav.zip and
rendered Jedah perfectly — while FBNeo (name-resolution inside its overlay,
where the build's vsav.zip replaces the reference by filename) loaded the
stale bytes. The two instruments disagreed about WHICH ROM was running.
Rules:
- Member identity is asserted ON THE ZIP (CRC compare vs pristine), never
  via rendering through a chained rompath.
- For honest MAME visuals of a patched set, use a RESTRICTED rompath
  (build zips + qsound_hle only) so no pristine twin is reachable.
- When FBNeo and MAME disagree visually, suspect ROM RESOLUTION before
  emulation — this is the third member-resolution trap (60z, the zero-CRC
  collision, now this).

## Unconditioned breakpoints DESYNC replay input — the trace measures a
## screen the replay never left (14z-63)

`obj_record_full_trace.lua` with breakpoints on the hot OBJ format
handlers (thousands of stops per second) produced a trace whose frame
counter said "select screen" while the machine was still in ATTRACT: the
frame counter advances on `frame_done`, which keeps firing for UI frames
while the CPU sits stopped, so scripted inputs land at the wrong EMULATED
time and the replay silently never progresses. The symptom is coherent
and misleading: a stable set of records cycling "at select frames" that
are really the attract screen's menu objects ($FFB800 CUR 0x26810E, REC
0x269032 — the 0x07C428-inited attract chain). The conditioned
`obj_record_bank_trace` run (2 stops total) in the same session showed
the true select-entry facts.
Rules:
- A breakpoint instrument driving replay input is only trustworthy when
  stops are RARE — condition the breakpoint (a0/a6 windows) so it fires
  a handful of times per run, or drive state via write taps (no stops).
- When a stop-based trace and a tap-based trace disagree about what
  frame N contains, believe the tap — its frames are emulated frames.
- Cross-check any stop-based finding against a screen-identifying fact
  (an init PC, a known object base) before attributing it to a screen.

## In-code pc-rel WORD JUMP TABLES read through the OPCODE view;
## byte/data tables through the DATA view — both live inside the
## encrypted range (14z-68)

The effect byte map (vs2 0x27FD8) reads correctly ONLY from the data
view (the standing GOTCHA). The seq-0x0E state-dispatch word table
(vs2 0x5556C, `move.w (pc,d0.w)` consumed) reads correctly ONLY from
the OPCODE view — its data-view bytes decode to garbage targets.
Deciding "which view" by the read instruction's addressing mode is
not sufficient; classify per table by DECODING BOTH VIEWS and taking
the one whose targets land on real code/data. The extractor already
does this right — the trap is for hand analysis, where the wrong
view produces plausible-looking garbage that can send a whole
session down a false trail.

## A `wpset` watchpoint is SILENTLY BLIND to every pc-relative read on
## CPS-2 — jump/handler tables need the OPCODES space (14z-71)

MAME's m68k serves pc-relative reads through `m68k_read_pcrelative_*`
-> `m_readimm16` -> **AS_OPCODES**, not the program space. So a plain
`wpset` on any table the engine indexes with `move.w (d16,pc,Dn),Dm` or
`movea.l (d16,pc,Dn),An` — which is *most* dispatch tables in this
engine — never fires, and the run reports **zero hits**.

Zero hits reads as "nothing ever uses this table". In 14z-71 that
inverted a finding for a whole measuring round: the effect-class row the
beam is dispatched through measured 0 reads on the native leg, which
would have meant the class-table route was wrong. In the OPCODES space
the same watchpoint measured **598**.

Rules:
- Watching a TABLE the engine jumps through? Use the opcodes space —
  `wposet`, i.e. `WATCH=<addr>,<len>,r,o` in `tests/lua/trace_writes.lua`.
- Watching RAM, or ROM data read via an address register (`(a0,d0.w)`)?
  Program space is correct. The discriminator is the ADDRESSING MODE of
  the read, not whether the target is ROM.
- Any "this is never read" conclusion needs a POSITIVE CONTROL taken
  with the same instrument on the same leg — a known-hot row of the same
  table. Silence and blindness are indistinguishable without one.

## MAME parses a watchpoint LENGTH as HEX — and a length the harness
## regex rejects kills the run and prints a clean-looking zero (14z-71)

`wpset addr,len,type` takes `len` in HEX, so `10` is sixteen bytes and
ten bytes is `a`. `tests/lua/trace_writes.lua` matched the WATCH length
with `%d+`, so any hex-lettered length failed the pattern, the `assert`
killed the run **before the replay started**, and the trace file came out
EMPTY. Downstream that is indistinguishable from a real measurement of
zero accesses.

It produced a wrong finding in 14z-71 ("the composite handler's A5
scratch window is free in vsavj"). With the pattern fixed to `%x+` the
same window measures **39 accesses** per match replay — the opposite
conclusion, and the one that decides whether a ported handler can keep
Capcom's own displacements.

Rules:
- A dead instrument and a real finding are the same shape from the
  outside: an empty output file. Assert that the run COMPLETED (the
  `END <frames>` line) before reading a count as a measurement.
- Every audit section carries a same-instrument positive control; see
  `tests/audit_effect_class_rows.sh`, where widening the identical watch
  from `a` to `10` bytes turns 0 into 56 and proves the zero was real.

## The boot RAM test writes EVERY byte of work RAM — a bare write-count
## on any address reports phantom hits (14z-71)

vsav's POST walks all of work RAM (frames ~5-72, PCs `0x000D34`-`0x000DDC`,
plus per-venue clears out to ~f824). So a watchpoint on any RAM address
returns a non-zero write count on a perfectly clean run.

This made the new list-type-6 tripwire gate cry wolf on its first
execution: five "a legacy list reached the taken-over type" hits that were
entirely the POST. The claim it guards is important enough that a false
positive there is nearly as damaging as a false negative — it would have
sent the next session re-opening a settled question.

Rules:
- Never assert on a raw RAM write count. Discriminate first: by PC (the
  strongest — require the write to come from the code you care about, and
  derive that address from the build's own atlas), or failing that by
  frame window (weaker: it blinds the check during boot and attract).
- This is the same family as the other two 14z-71 instrument traps: the
  failure is always a **"count everything" default**, and the defence is
  always a control or a discriminator, never a tuned threshold.

## A MAME watchpoint logs REGISTERS, not the VALUE WRITTEN — reading the
## value off a register snapshot attributed a write to the wrong caller (14z-76)

`tests/lua/trace_writes.lua` logs `frame PC D0 D1 A0..A6` at each hit. It does
**not** log the datum. On a `move.l a1,$30(a4)` it is tempting to read A1 as
"the value written" — and that is right only if the sample came from the call
you care about. In 14z-76 the win-quote installer was sampled on a *different*
invocation in the same frame; A1 read `0x330F4C` while the field actually
received `0x3311C2`. That mis-attribution sent the investigation looking for a
second, non-existent installer, and produced a self-contradiction ("the field
is read before anything writes it") that stood until the right instrument was
used.

**FBNeo's write tap logs the value**, one line per word, with PC attribution
and non-perturbing:

```
FBNEO_HTAP="fff230-fff233" tools/run_replay_fbneo.sh vsavjw <rpl> out.log
    -> out.log.tap:  11996 fff230 0033 W pc=00c8cc
                     11996 fff232 11c2 W pc=00c8cc
```

Two consequences worth internalising:
- **a 68k `move.l` appears as TWO WORD writes**, so a pointer shows up split
  (`0033` + `11c2`); grepping the tap for the full value finds nothing;
- when a MAME register snapshot and a value tap disagree, **the value tap
  wins** — and the disagreement is the signal that you sampled the wrong call,
  not that a second writer exists.

Reach for the FBNeo tap the moment the question is "what value went in", and
keep MAME's for "which code ran".

## FBNeo/MAME frame indices and object slots do not transfer — a slot-keyed tap chases a different object (14z-81)

The merged Huitzil crash is deterministic on MAME at frame 2886, object
`$FFB800`. An `FBNEO_HTAP` on that slot showed healthy writes on BOTH builds
— and the merged build survived the whole 11,017-frame replay on FBNeo. Not
a contradiction: the emulators traverse the same states on different frame
indices (documented since session 2), the RAM state at pick time therefore
differs, and the object ALLOCATOR hands the satellite a different slot — so
the tap watched some other object, and the defect's observable moved. A tap
or probe keyed on an OBJECT SLOT is only meaningful within one emulator's
run; to cross emulators, key on content (the handler PC, the type byte),
and treat MAME as the instrument when the finding is frame-addressed.

## A write tap bucketed by WORD OFFSET reads a word's low-byte lane as "never written" (14z-85)

The 68k bus is 16-bit: one `move.w X,(0x7E,An)` is ONE tap callback at
offset +0x7E — and it writes BYTES +0x7E AND +0x7F. The 14z-84 pool
free-byte audit bucketed `off % stride` without splitting lanes, so slot
byte +0x7F read as "zero writes" while our own hole_b code was writing
it every run (as the low byte of its +0x7E word). A tag byte chosen on
that evidence would have been silently clobbered.

**The rule: bucket write taps by BYTE LANE.** Split every hit by its
16-bit mask (`mask & 0xFF00` → byte at off, `mask & 0x00FF` → off+1;
handle the 32-bit-data defensive case like tap_writes' collect mode),
and only then histogram. `tests/audit_pool_free_byte.sh` (14z-85
rewrite) is the worked example. Symmetric hazard on the read side: a
"nobody writes this byte" claim from a word-bucketed tap is not
evidence — re-derive with lanes before trusting any freeness claim
made before 14z-85.

## A member's REGION layout is not its FILE layout — and the Z80 driver's own address space is a THIRD thing (14z-86)

MAME loads CPS2's `vm3.01` split (`ROM_LOAD` 0x8000 at region 0, then
`ROM_CONTINUE` at region 0x10000; `vm3.02` at region 0x28000). A session of
Z80-driver RE (14z-85d) assumed region==file above the fixed window and read
every table at region-derived offsets: the id table "at FILE 0x11006", entry
bytes "33 07 50 18", an "8-byte table @0x5219" — all plausible-looking bytes
at WRONG offsets, and the garbage the wrong offsets produced for CODE was
confidently explained as "KABUKI encryption" (the Z80 is plain; KABUKI is the
CPS1-QSound generation). One read tap with DATA logging (qs_table_trace,
SPANS over the banked window) collapsed the whole edifice in one run: the
driver's 24-bit logical addresses are FLAT member-concat file offsets, full
stop (flat = CPU + bank*0x4000 in the $8000 window; bank register hw-masked
to 4 bits, MAME `qsound_banksw_w`).

The rules this paid for:
- **Before deriving any file offset from an emulator address, read the
  driver's ROM_LOAD lines** — `ROM_CONTINUE`/split loads make region↔file
  non-affine, and every downstream "FILE 0xNNNNN" claim inherits the error.
- **A tap that logs PC only cannot arbitrate a mapping; log the DATA.** The
  PC flow matched the wrong mapping perfectly — only the data bytes
  (02 9A B2 vs 33 07 50) decided.
- **"It disassembles as garbage" is not evidence of encryption** — it is
  evidence you may be at the wrong offset. Check the emulator's opcode-map
  config (AS_OPCODES) and byte-compare a live-traced PC against the file
  before concluding cipher.

## QSound sample windows must live in ONE HALF of their 64K bank — the DSP compares pointers SIGNED (14z-86)

The M5 voice packer placed sample windows first-fit avoiding only 0x10000
crossings. Four restored voices came out attack-then-silence: their windows
straddled bank offset 0x8000, and the DL-1425 program compares the playback
pointer against END in SIGNED 16-bit — start positive, end "negative" →
the end condition holds at once and the voice collapses to its silent loop
tail. Every NATIVE record respects the half-bank law (checked corpus-wide);
the packer now packs at 0x8000 granularity and refuses >0x8000 windows.

The instrument lesson outranks the law: **register-level and content-level
A/Bs were BLIND to this defect** — the records were arithmetically correct,
the member bytes byte-identical, keyon/pitch/volume registers equal; only
the AUDIO differed. A semantic of the CONSUMER (signed compare) made equal
data behave differently. The catch came from the EAR-LEVEL instrument
(paired -wavwrite captures + per-window RMS/high-band comparison,
tests/audit_qs_voice_wav.sh) — when porting content into a player you do
not fully model, keep one gate at the OUTPUT level, not just the state
level. (Also: MAME -wavwrite works headless by appending
`-sound auto -wavwrite f.wav` AFTER run_mame.sh's -sound none — last
option wins.)

## QSound packing law #2: the destination offset must keep the SOURCE offset's BYTE PARITY (14z-86)

The voice batch still sounded "like PC-speaker synthesis in a DOS game"
(maintainer, on BOTH emulators) after the half-bank fix. The mechanism:
the QSound members are stored PRE-SWAPPED and both emulators byteswap
16-bit pairs at load — so the audio stream a sample yields depends on the
byte LANE of its offset. A window copied from an even source offset to an
odd destination (or vice versa) plays with every byte pair exchanged: RMS
preserved, high band doubled, words recognizable but harsh. File-level
content comparison is BLIND to it (the bytes are equal; the LANES differ),
and so was the first WAV checker (it only flagged collapsed high band, not
elevated — the maintainer's ear caught what the threshold passed; the
checker now flags both directions). The packer keeps parity; the
found-in-vsav path requires parity-matching hits.

## A Lua read tap on a device_rom_interface space sees NOTHING (14z-86)

`install_read_tap` over MAME's `:qsound` "rom" space logged zero hits while
the DSP audibly streamed samples — the rom interface reads through cached
direct pointers, bypassing the tap layer entirely. The instrument was dead,
not the reads absent (RH-15). For chip-side sample questions use the
register stream (the d000-d002 write log), the loaded-region dump
(space:read_u8 works fine for YOUR reads), or the ear-level WAV capture —
not read taps on device ROM spaces.

## A state-dependent value may not be correlated ACROSS runs — serialize read and write in ONE run (14z-87)

The sword-plant "ding" hunt spent most of a session on a phantom
"invisible write": a write tap on `$FF8782` said the last mid-match write
was 0x06, a debugger bp said the dispatcher later READ 0x0C from that
byte, both instruments were provably live — and no mechanism on either
emulator can change RAM without a bus write. The resolution: **the value
is a dynamic ALLOCATION result (the voice-class borrow scan), and every
run allocates differently** — measured 0x06/0x0C/0x09/0x00 across
identical-input MAME runs and 0x04 on FBNeo. The write from run A was
being compared with the read from run B. In one run with read AND write
taps installed together (`tests/lua/read_tap.lua`), the write was 0x0C
and the read was 0x0C: nothing was ever invisible.

Two sub-traps, both paid for here:
- **Debug and non-debug runs are different worlds** (the standing
  checksum gotcha), but so are two IDENTICAL non-debug runs when the
  value derives from sound state: the QSound handshake latch's one-frame
  phase (the documented masked non-determinism) feeds the in-use mask
  the borrow scan consults, so even the canonical timeline is a lottery
  at this one point.
- **The watch window bounds the claim** (RH-26): the 14z-86 byte-watch
  covered the DISPATCH window and concluded "no write"; the write fires
  ~536 frames earlier, at a match-sequencer event. Run write watches
  unwindowed first — the boot-POST hits double as the liveness control.

Rule: before comparing a written value with a read value, demand they
come from the SAME run, serialized by one instrument. For any value fed
by allocation, RNG, or sound state, a cross-run equality argument is not
evidence — it is the phantom-generator.

## A QSound "pure synthetic beep" is a TIGHT-LOOP sample — and a raw-window render can never reproduce it (14z-87b)

The hardware plays samples only; a clean pitched tone is a sample record
whose loop region is a few dozen samples (vsavj record #0x3E: loop
0xFFF4-0xFFFF = 11 saturated bytes → ~1.17kHz pure tone at the driver
rate). Two paid-for corollaries: (1) rendering a record's raw window
start→end ONCE mischaracterizes its in-engine sound completely — the
sustained tone lives in the loop, not the window; render attack + loop
repetitions, or better, isolate the real sound by DIFFERENCING a
silence-probe build's audio against the reference build's (the two runs
are identical until the silenced id's first enqueue, so the difference IS
the sound); (2) a silence-probe verdict must compare the DIFFERENCE
SIGNAL, not envelope peaks at chosen frames — peak equality at two
timestamps "refuted" the true beep source for half a session while the
global diff showed audio removed at exactly the enqueue frame.

## QSound packing law #3: the record's `end` offset PLAYS — copy the inclusive window (14z-87b)

The sword-plant "beep" (maintainer ear-confirmed against a byte-synthesized
prediction): a sample record's `end` field is played/looped INCLUSIVE —
proven by field width, since native windows end at 0xFFFF, which an
exclusive bound could not express — but the voice-batch packer copied
`q2[w0:w1]` EXCLUSIVE. Every packed sample's last played byte therefore
held the NEXT blob's first byte. For a voice whose loop tail is silence,
ONE foreign byte turns the sustained loop into an impulse train (13-sample
period ≈ 1.85kHz — a "pure computer beep" to the ear, ~70ms to keyoff).
Measured: exactly 3 of 57 packed records had a non-zero contaminated end
byte — the others landed on 0x00 neighbors by luck, which is why the batch
otherwise sounded normal and the WAV gate's per-window thresholds passed.
rec#0x3C8 = Donovan voice 0x705 = fired at EVERY sword plant = the report.
Enforced in tools/build_qs_songs.py (inclusive copy, all size math +1) and
gated by test_qs_songs.sh's law-3 section (resolved inclusive window ==
vs2's, per record, + a flipped-end-byte verdict control). The find-in-vsav
path inherits the law automatically (the searched blob now includes the
end byte).

The hunt's meta-lesson, paid in three wrong candidates: the beep was
invisible to every id-level comparison because the defect lives BELOW the
id layer (same ids, same songs, same records-by-construction — one byte of
neighboring content), and it was absent from every rig capture because THE
RIG NEVER FORMED A MATCH (no S1/coin-2/confirms — the p1= inputs went to
nobody, verified by select-screen snapshots; rigs 90/91v1 measured a
timed-out CPU match for two sessions). Verify a rig produces the EVENT
(snapshot the screen, read the ring) before believing any capture of it,
and when a report says "synthetic beep", think TIGHT LOOP / impulse train,
not sample content.

## A pc-relatively-read table must be a `code` op at ANY address (14z-91)

`patch_prg.py` has two byte-emitting op kinds and they are not "inside vs
outside the crypt window":

- `data` stores the bytes verbatim;
- `code` runs `cipher.crypt_words_at(..., decrypt=False)`, which is
  **address-aware** — inside the CPS-2 key range it re-encrypts so the
  CPU's decryption yields your bytes, and outside it returns them
  unchanged, "matching how the CPU would fetch them"
  (`tools/cps2_decrypt.py:325-330`).

So the choice is decided by HOW THE BYTES ARE READ, not by where they
land. Anything the 68000 fetches through AS_OPCODES — instructions, and
every pc-relative table read (`movea.l (d8,PC,Dn.w)`, `move.w (d8,PC,Dn.w)`)
— must be a `code` op wherever it goes. `data` is right for An-relative
and absolute DATA reads only.

The trap has both directions:
- the obj_hook type table was correctly `data` while a thunk read it
  An-relatively, and had to become `code` the moment a relocated walker
  read it pc-relatively;
- embedded data inside a thunk body in crypt space must be `data`
  (`build/manifest/donovan.toml` hole "b" note) or a data read gets
  ciphertext.

Corollary: `alloc(..., fallback=False)` is NOT the way to keep a
pc-relative table out of raw space. There is nothing to keep it out of —
`code` is correct in raw space too. Forcing no-fallback instead makes
every 3-tenant merge fail to generate, because hole_a is full.

## MAME `-aviwrite` is headless-capable but uncompressed (14z-94)

Recording from inside MAME is the right instrument for dating a visual
event — the captured frames are EMULATED frames, so window frame k is
replay frame START+k by construction, and the file is reproducible run to
run. A host screen recorder gives neither.

But `-aviwrite` records the whole run, uncompressed. Measured on the
arcade rig at CPS-2 resolution: **5.7 GB after roughly two minutes of wall
time**, still growing, and it slows the run enough that a frame cap you
believed in stops arriving.

Use `tests/lua/record_window.lua`, which calls
`manager.machine.video:begin_recording(path, format)` at a named frame and
`end_recording()` at another. Defaults to MNG (losslessly compressed):
2.4 MB for 120 frames, whole run 4.5 s. Pass an ABSOLUTE `REC_OUT` —
a relative name goes through MAME's snapshot-filename substitution and
lands in the snapshot directory, not where you ran from.

Ground-truth it before reading anything off a recording
(`tests/test_record_window.sh`): a recorder that drops, duplicates or
blanks frames still produces a file that plays.

---

## 14z-94: TWO BUILDS CAN SHARE A PROGRAM FINGERPRINT — the merged build and
## its legacy-only instrument do, deliberately

The maintainer asked to confirm which merged build to playtest, fearing they
had tested the wrong one. They were right to ask, and the fingerprint would
NOT have settled it:

```
build/m3b_merged9   program fingerprint 081e2e53...   <- the playtest build
build/merged1       program fingerprint 081e2e53...   <- the legacy instrument
```

Identical, and the repo says why: *"the merged build is frozen by TAG +
HANDOFF row and deliberately gets NO registry.tsv row, because the
legacy-only instrument shares its fingerprint"* (14z-92, d716e49).

**Three ways this bites:**

1. `merged1` is **NEWER by 8 minutes**, so "the most recent merged build"
   picks the wrong one.
2. `build_fingerprint.py` covers only the PROGRAM members — 12 of 21,
   8.1% of the shipped bytes — so it cannot see the difference at all.
3. ~~There is **no in-game version string** to A/B by~~ **CLOSED 14z-105:
   the select screen now shows the freeze generation ("M6" bottom-right,
   `test_version_string.sh`) — but it names the GENERATION, not the
   instrument-vs-shippable distinction, and `merged1` shows the same
   string (same program image), so this point still stands for that
   pair.** (Was: open since 14z-92.)

**What actually distinguishes them**, and what to check instead:

| | m3b_merged9 | merged1 |
|---|---|---|
| zips in rompath | **2** (`vsavjw` + patched `vsav`) | 1 (`vsavjw` only) |
| whole-artifact manifest | `904d432f`, 42 members | `d7a5145c`, 21 members |
| `vsw.31m/33m/35m/37m` | tenant graphics | **zero-filled** |
| `vsw.21m` | packed QSound samples | **zero-filled** |
| `vsw.z01/z02` | M5-song driver | stock Z80 driver |

So `merged1` is playable and shows all 18 characters — the program image is
identical — but the tenants render **blank/garbled with no ported voices**.

**Use `tools/artifact_manifest.py` (whole artifact), not
`build_fingerprint.py` (program only), whenever the question is "which build
is this?"** The program fingerprint answers "which code", which is a
different question and, for these two, has the same answer.

## `gfx_tiles.decode` had every 8-pixel half MIRRORED, and nothing noticed for 14 sessions (14z-105)

Within each 8-pixel half of a CPS-2 OBJ tile row, plane bit `i` is pixel
`7-i`. `decode()` mapped bit `i` to pixel `i` from the day it was written,
and its inverse (`encode`, new 14z-105) inherited that — the first tiles
this project ever AUTHORED (the select-screen version glyphs) drew each
half mirrored on the real OBJ path. Caught only because "M6" is not
symmetric: a MAME snapshot pixel-compared against the intended bitmap
showed the "6" scrambled while the near-symmetric "M" looked right.

Why it hid: every consumer of the module compares RAW BYTES (`cmd_match`,
the `BLANK` hashes, every readback assertion). Pixel ORDER had never been
load-bearing; the first authored tile made it so. Also measured on the way:
the transparent pen is **15**, not 0 (pen 0 drew an opaque black box), and
an OBJ entry at `(x, y)` lands at **screen `(x - 64, y - 16)`** on this
screen — the wheel's `_coord_note` had the x half only.

Gate: `tests/test_gfx_tile_codec.sh` (the bit law on single pixels, round
trips both ways, the pre-fix mapping reconstructed and required to
DISAGREE on an asymmetric tile). Rule: any synthesized tile is verified
at the RENDER layer against its intended bitmap (`test_version_string.sh`
§2) — a byte round-trip proves the codec is self-consistent, not that it
matches the hardware.

## `jtsim -setname` re-downloads every run — and on CPS-2 you must download anyway (14z-107)

The ROM download costs **10'43"** of simulated time on jtcps2, and the
obvious way to avoid paying it twice — keep `sdram_bank?.bin` and drop
`-load` — does not work, for TWO independent reasons. `modules/jtframe/bin/jtsim:503-506` guards the
re-link with

    if [[ ! -e rom.bin || `readlink rom.bin` != "$ROMFILE" ]]; then
        ln -srf $ROMFILE rom.bin
        enable_load()

`ln -srf` writes a **relative** symlink while `$ROMFILE` is `$ROM/<set>.rom`,
**absolute** — so the comparison is true on EVERY run, `-setname` always
re-links, and `enable_load()` (`jtsim:249-258`) both defines `LOADROM` and
**`mv sdram_bank?.* sdram.old`**. 14z-106 measured "the second run re-ran the
download" and filed it against `-load`; the flag responsible is `-setname`.

**Drop `-setname`, KEEP `-load` — and this is the second half of the trap.**
It is tempting to drop `-load` too: `test.cpp:611-651` then preloads the four
banks at t=0 and the download is shortened to 32 bytes (`test.cpp:263-281`,
log lines `ROM download shortened to 32 bytes` / `ROM file transfered (frame
0)`), which looks like a free 10 minutes. **It is not.** On CPS-2 the
transfer also latches the DECRYPTION KEY into core registers
(`jtcps1_prom_we` → `cps2_key_we` → `jtcps2_keyload`) and no SDRAM image can
restore that, so a preloaded run boots into ciphertext. **Measured 14z-107:
1,841 simulated frames with the banks preloaded, and 68k work RAM was ALL
ZEROS at every frame** — a dead 68k. The download is mandatory on this core,
which also means the `sdram_bank?.bin` dumps have no use at all.

**AND THE DOWNLOAD BURNS INPUT LINES.** `sim_inputs.next()` fires on every
LVBL fall from t=0, download frames included, while the core is held in reset
— so a scripted input meant for the game's frame 300 lands during the
transfer unless the script is shifted by the download length
(`rpl2siminputs.py --offset 462`).

**THE NEAR-MISS WORTH RECORDING:** the preloaded run's all-zero dumps agreed
with MAME's work RAM on **99.2% of sampled bytes**, because most of a 64 KB
work-RAM image is zero. "High agreement" is not evidence of a live oracle;
the first check on any new dump path is **is it non-constant** — two frames
of the same run must differ. (CLAUDE.md §4: verdict logic is itself tested.)

Two knock-on facts worth having: `rom.bin` must exist and be non-empty
(`jtsim` errors otherwise), and `$ROM/<set>.dip` / `<set>.mod` are only
consulted under `-setname` — for `vsavj` the `.dip` file is EMPTY, so
dropping the flag changes no DIP setting, and `core.mod` can simply be
copied.

## `JTFRAME_SIM_IODUMP` on CPS-2 dumps the EEPROM, not RAM (14z-107)

`jtframe`'s "state out" macro writes `scenes/<frame>/dump.bin` over the
**IOCTL read** path, whose width is `JTFRAME_IOCTL_RD`. On cps2 that is 128
— the 64 words of the serial EEPROM — because cps2 has no `cfg/mem.yaml` and
`ioctl_din` is driven only by `jteeprom` (`cores/cps1/hdl/jtcps1_sdram.v:
462-478`). The companion macro `JTFRAME_SAVESDRAM` looks like the answer and
is not: it exists only inside the **Verilog** SDRAM model
(`modules/jtframe/hdl/ver/mt48lc16m16a2.v:193-209`), which the Verilator lane
never instantiates — there the C++ `SDRAM` class IS the SDRAM, and its
`dump()` fires exactly once, right after a full ROM download.

Reading emulated work RAM out of a Verilator run therefore needs a harness
hook, not a macro that already exists (ours: `JTFRAME_SIM_WRAMDUMP`, fork
commit `553dd56`, `docs/platform/mister.md`). The general lesson is the
14z-71 one in a new place: **a macro named for what you want is not evidence
that it does it — read the module that consumes it.**

## Editing a shell script WHILE it runs corrupts the running execution (14z-107)

`sh` reads a script incrementally and keeps a BYTE OFFSET into the file. Edit
the file while it is executing and the offset now points into the middle of a
different line: the still-running shell resumes at a token boundary that never
existed. Paid for here on a 55-minute gate — `tools/run_sim_jtcps2.sh` had run
its 2,880-frame Verilator simulation to completion, and then died on

    run_sim_jtcps2.sh: line 242: syntax error near unexpected token `('

because the header comment had been rewritten mid-run (a pure comment edit —
the bytes moved, and that was enough). `sh -n` passes on the file the whole
time; the corruption exists only in the running process.

Cost was recoverable only by luck: the collection step is the LAST thing the
script does, so the RAM dumps were still sitting in the scratch clone's
`cores/<core>/ver/game/wram/` and the measurement was salvaged from there
rather than re-simulated. **Rule: while a long job is running, do not edit the
scripts it is executing** — queue the edits, or work on a copy. It applies to
`tests/*.sh` gates too, which is exactly when the temptation is highest (an
hour of waiting with the file open).

## `JTFRAME_SDRAM_XL` without `JTFRAME_SDRAM_CACHE` aliases SILENTLY (14z-107)

Upstream jtframe's 128 MB tier is real (`SDRAMW=24`,
`modules/jtframe/target/mister/hdl/jtframe_emu.sv:175-181`), but the
controller that KNOWS about it exists only on one side of a fork.
`hdl/jtframe_board_sdram.v:158` branches on `JTFRAME_SDRAM_CACHE`: the
`ifdef` arm instantiates `jtframe_burst_sdram` (`:164`), which carries the XL
logic (`localparam XL = AW == 24`, the two-chip select on nCS polarity); the
`else` arm instantiates `jtframe_sdram64` (`:225`), which was **never taught
XL** — its `init`/`rfsh` instances leave `.chip()` unconnected
(`jtframe_sdram64.v:265,279`), and its bank
module's geometry is `localparam ROW=13, COW = AW==22 ? 9 : 10;` — a two-arm
ternary with **no arm for AW=24**.

The macro validator does not catch it. `src/jtframe/macros/public.go:131-140`
rejects `JTFRAME_SDRAM_XL` with `JTFRAME_SDRAM_LARGE`, and rejects
`JTFRAME_SDRAM_XL` with any `JTFRAME_BAx_START` — but **nothing requires
`JTFRAME_SDRAM_CACHE` alongside XL.**

So on a core with explicit slot modules and no `cfg/mem.yaml` — which is
exactly CPS-1/CPS-2 — adding `JTFRAME_SDRAM_XL` to `cfg/macros.def`
**compiles, validates, and produces a broken map**: at AW=24 the row becomes
`addr[22:10]` and the column `{addr[23], addr[8:0]}`, so `addr[9]` is never
driven onto the bus and every address aliases with `addr ^ 0x200`. Per-512-
word corruption, no error message. **A tier macro is not a tier** — check
which controller the macro's logic actually lives in before setting it.

## The Verilator SDRAM model dropped the TOP address bit — and the obvious fix was wrong (14z-107)

**FIXED 14z-107 (3)** (fork commit 3,
`emu/jtcores-patches/0003-jtframe-sim-sdram-top-address-bit.patch`). The
symptom and the eliminations stand; the MECHANISM recorded here first was
wrong, and so was the fix it implied. That is the reusable part.

`modules/jtframe/hdl/ver/test.cpp` sizes its bank BUFFERS from the tier macro
(`:54-58` `BANK_LEN = 0x100'0000` = 16 MB under `_JTFRAME_SDRAM_LARGE`) but
reconstructed only 22 of the 23 address bits from the PINS, so **anything a
core placed above 8 MB within a bank aliased in simulation, quietly** — and
the ROM download aliased with it, so the upper half was never written at all
and the lower half was overwritten by the upper half's content. On jtcps2
that is all of GFX: banks 2 and 3 are 16 MB each and stock `vsav` fills both,
so a Verilator run rendered from a corrupt tile map. Bank 0 (PRG 0-4 MB, VRAM
@4, ORAM @5, work RAM @6, sound @7) is entirely below WORD address
`0x400000`, which is why the 14z-107 work-RAM anchor oracle was unaffected —
but "the frames showed sprites" was NOT evidence that GFX addressing was
faithful.

**THE TRAP, and it is the general lesson: the missing bit was NOT the one the
size arithmetic points at.** "13 row + 9 column = 22 bits, so widen the column
to 10 bits (`<< 10`, `& 0x7fffff`, `0x3ff`)" is the natural reading, and it
would have folded the TOP address bit onto `addr[9]` and produced a
different wrong map. `jtframe_sdram64_bank.v` maps the address like this:

    :75-76  localparam ROW=13, COW= AW==22 ? 9 : 10;
    :127    addr_row = AW==22 ? addr[AW-1:AW-ROW] : addr[AW-2:AW-1-ROW];
    :219    sdram_a[10:0] = { precharge_flag, addr[AW-1], addr[8:0] };

At AW=23: row = `addr[21:9]`, column = `{ addr[22], addr[8:0] }`. The tenth
column bit is **`addr[22]`, the top of the address**, not `addr[9]` —
`addr[9]` is a row bit. So the fix is to rebuild bit 22 from `sdram_a[9]` on
the READ/WRITE command, gated `#ifdef _JTFRAME_SDRAM_LARGE` (at AW=22 that
pin carries `addr[21]`, already a row bit and a don't-care), and to leave the
burst column counter 9-bit (bursts wrap inside the aligned block and never
carry into column bit 9).

**Two general traps, both paid here:**
1. **A simulation model can be a DIFFERENT PART from the one the design
   targets, and it will not tell you** — check the testbench's own geometry
   before trusting any result that depends on the far end of a bank.
2. **Do not infer a bit-level fix from a SIZE.** "22 bits where 23 are
   needed" tells you how many bits are missing, never which one. Read the
   line that drives the pins.

## On jtcps1/jtcps2, GFX ROM CONTENT changes object TIMING (14z-107)

`cores/cps1/hdl/jtcps1_obj_draw.v:137`:

    if( &rom_data ) begin
        // skip blank pixels

The object pipeline SKIPS its 8-pixel draw loop when the fetched GFX word is
all-ones. So the number of cycles the object engine spends, and therefore its
SDRAM request pattern, is a function of the DATA in the GFX ROM — not just of
the object table.

Paid for as a five-frame surprise. Fixing the Verilator SDRAM model
(fork commit 3) changed nothing the 68k can see: bank 0 is untouched, and its
upper 8 MB measures 0.0% non-zero, i.e. it was never even addressed. Yet the
`05_timeout_idle` match-start anchor moved from simulated frame 2507 to 2502.
The chain is: correct GFX -> a different set of tiles is genuinely blank ->
a different skip pattern -> slightly different SDRAM contention -> the 68k
gets a marginally different cycle budget -> five frames of drift over 2,500.

**Consequences worth carrying:**
- an "identical inputs, identical RAM" expectation across two builds that
  differ ONLY in GFX content is not safe on this core;
- the CPS-2 WIDE arc should expect tenant art to shift core timing by the
  same route, and should freeze anchors per build rather than assume they
  travel;
- more generally: **on a shared-bus system, changing the CONTENT of a
  read-only memory can change TIMING**, because content can gate work.

## `jtsim -verilator -stats` reports nothing, for THREE independent reasons (14z-107)

Upstream's SDRAM usage analysis (`jtsim -stats`) is dead on the Verilator
lane at v1.7.3, and each cause hides the next:

1. **The module is never compiled in.** `bin/jtsim:416-418` defines
   `JTFRAME_SDRAM_STATS` and `hdl/ver/game_test.v:380-392` instantiates
   `jtframe_sdram_stats_sim`, but nothing puts
   `hdl/sdram/jtframe_sdram_stats_sim.v` on the compile list — Verilator
   dies with "Cannot find file containing module". Workaround, caller-side:
   `jtsim ... -args <path to the .v>` (`bin/jtsim:289` appends to the
   simulator command line).
2. **Verilator 5 refuses `#` delays without `--timing`** (%Error-NEEDTIMINGOPT)
   — the reporter is an `initial forever #16_666_667`. `--no-timing` compiles
   it into silence, so `--timing` is the only useful answer; also caller-side
   via `-args`.
3. **The model's clock never advances.** `hdl/ver/test.cpp` keeps a private
   `simtime` and never calls `VerilatedContext::time()`, so `$time` reads 0
   forever and every delay deadline is unreachable. Fork commit 4 advances
   it. **And the naive form of that fix aborts the run**: a delay deadline
   lands wherever the design put it, not on the half-period grid, so
   assigning `time() += semi_period` steps over it and Verilator fatals with
   "Encountered process that should've been resumed at an earlier simulation
   time. Missed a time slot?" (`verilated_timing.cpp:85`). The step has to
   land on each pending slot on the way, via the model's own
   `eventsPending()` / `nextTimeSlot()`.

**The general shape: a feature that has a command-line flag is not
necessarily a feature that works.** `-stats` had a documented flag, a help
line and an instantiation, and produced nothing on this simulator.

## The `-stats` reporter's own numbers cannot be differenced (14z-107)

`jtframe_sdram_stats_sim` prints kiB/s figures that are integer-TRUNCATED
deltas and same-row figures that are CUMULATIVE running percentages with the
denominator never printed. Neither can be turned back into "what did ONE
PHASE of the run do". Fork commit 5 adds a raw counter line
(`SDRAM_STATS_RAW`) next to them. **When an instrument reports a rounded
rate and a running average, it is a dashboard, not a measurement** — check
that the raw counters are reachable before planning an analysis on it.

## A CPS-2 tile code IS its SDRAM address — so LIVE BYTES are not a FOOTPRINT (14z-107)

The `.rom` stores GFX in the MAME 4-way 64-bit interleave (`[rom] { name="gfx",
width=64 }`), and `cores/cps1/hdl/jtcps1_prom_we.v:105` applies a CPS-2
address scramble at download time:

```verilog
gfx_addr = { gfx_addr[25:21], gfx_addr[3], gfx_addr[20:4], gfx_addr[2:0] };
```

Composed, the two **cancel**: the SDRAM address of tile code `c` is exactly
`c * 128 + (byte within tile)`, contiguous and monotonic in `c`. The scramble
is not an obfuscation, it is the de-interleaver.

Two consequences that are easy to get wrong, and both were:

1. **You cannot cost a tile set by counting its bytes.** A roster occupying
   6.39 MB of art scattered up to code `0xFFDB` needs **15.45 MB** of SDRAM,
   because the code space between its tiles is address space it owns. Sparse
   art cannot be compacted without renumbering tile codes — which is game
   data, not a mapping choice.
2. **Do not re-derive the tile→member mapping.** A plausible bit-level
   derivation of "which member byte holds tile `t`" produced 978/722/775/977
   blank tiles for vanilla `vsav`; `tools/gfx_tiles.py:112 tile_bytes()` — the
   canonical one, which the whole project already uses — produces
   418/2917/51/642, the figures every earlier census froze. **A derived
   address map is worth nothing until it reproduces a number somebody already
   measured.** Run the known census first, then trust the derivation.

## jtframe `mame2mra`: four silent traps in the MRA generator (14z-107, extended 14z-107 (5))

Four traps in the MRA generator (`modules/jtframe/src/jtframe/mra/`), every
one of them silent — the `.rom` builds, it is just wrong:

- **`rom_len` smaller than the file truncates the emitted bytes but still
  advances `pos` by the FULL file size** (`corerom.go:562-577` — the option
  is designed to pad up, or to duplicate at exactly `2 x size`). Every later
  region's header start word then disagrees with the real `.rom`. To shorten
  a region use `parts=[{name,crc,map,length,offset}]` (`corerom.go:462-479`),
  which is also the only route to a PARTIAL zip member — the reader
  implements a real byte window at `mra2rom.go:177-196`.
- **On CPS-2 the generator's `pos` counts the 20-byte `key` region while the
  RTL's `bulk_addr` starts after it** (`FULL_HEADER = 26'd64` = 44 header +
  20 key, `jtcps1_prom_we.v:58`). Header words are `pos >> 10`, RTL compares
  `bulk_addr[25:10]`; the two agree **only because 20 < 1024 and every region
  start is 1 KiB-aligned**. A CPS-2 region that starts at a non-1 KiB body
  offset puts its header word off by one KiB block, with no warning.

- **`parts=` collapses a multi-member region into ONE `<interleave>`**
  (added 14z-107 (5)). `parse_parts` opens a single `<interleave
  output=W>` when `width>8` and hangs every part off it (`corerom.go:462-479`);
  `interleave2rom` then binds each output byte lane to the FIRST finger whose
  map claims it and stops when the SHORTEST finger runs out
  (`mra2rom.go:238-249`). So `parts=` can express a multi-member 16-bit
  region only if the members' maps are DISJOINT. Three CPS-2 QSound members
  all carrying `map="12"` silently become the first one, truncated. (The one
  in-tree user, Pang!3 at `cores/cps1/cfg/mame2mra.toml:165-173`, has four
  disjoint 64-bit lanes, which is why nobody had hit this.) The way out is
  one REGION per differently-mapped group — and give the extra region a
  generic `{ name=…, skip=true }` row, because **a region with no config at
  all still emits its `<!-- … starts at … -->` comment**, which is enough to
  break a byte-identity twin.
- **An oversized region start is written WRAPPED, with no warning** (added
  14z-107 (5)). `set_header_offset` stores the low 16 bits of `start >> 10`.
  Measured on an untrimmed CPS-2 WIDE image: a firmware start of 71,936 KiB
  came out as **6400** — the same value the `qsound` word carried. Nothing
  in the tool checks the ceiling.
- **`mra2rom` locates zip members by CRC32 and by NOTHING ELSE** (added
  14z-107 (5)). `mra2rom.go:163-172` walks the zips comparing `file.CRC32`;
  the `name` attribute appears only in the warning text. **This diverges
  from FBNeo and MAME**, which resolve by NAME and merely warn on a hash
  mismatch — so a driver that uses SENTINEL CRCs for authored members (as
  this project's WIDE profile does) works there and produces NO `.rom` here.
  An MRA is pinned to the exact bytes of one romset build.

Two more facts about where the tool reads and writes: the zip search path is
a hard-coded `$HOME/.mame/roms/<name>.zip` (`mrazip.go:23`, no flag), so the
output is a function of the invoking user's home directory — stage a private
`$HOME` rather than writing into the real one. And a set must exist in
`$JTROOT/doc/mame.xml`, jtframe's own REDUCED machine catalogue (not a MAME
`-listxml` dump); `[parse] sourcefile` is a REGEX list matched against that
entry's basename, which makes it a usable per-core profile gate.

Related hard ceilings worth knowing before sizing a `.rom`: the GAME-side
port is `input [25:0] ioctl_addr` (**64 MB**,
`modules/jtframe/hdl/inc/jtframe_mem_ports.inc:1`) even though the MiSTer
target carries 27 bits (`jtframe_emu.sv:334`), and each header start word is
**16 bits in KiB units**, i.e. 65,535 KiB max.
