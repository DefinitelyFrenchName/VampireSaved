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
