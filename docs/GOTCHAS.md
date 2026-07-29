# GOTCHAS — traps that cost real debugging time

Append the moment one is paid for. Read before touching the related area.

## Sibling-coincident engine refs are INVISIBLE to the diff oracle — and the coincident vsavj address is usually a WRONG routine (paid: 2026-07-27 sessions 11c-12, ~a full session across three playtest rounds)

vs2 and vhunt2 are sibling builds: large engine bands (the sound farm,
kernel services) have IDENTICAL layout across them. An engine operand in
ported code that COINCIDES across the siblings is not a diff site, so the
oracle extraction never surfaces it — the operand is carried raw and, on
vsavj (whose layout DID drift), silently calls whatever happens to live
at that address. The mash-wedge hang was exactly this: the ported meter
code's `jsr 0x3B2C` (stock-gain chime, vs2==vhunt2) landed on a DIFFERENT
vsavj farm entry — an unpaired tail that "restores" stale registers via
0x3306 without a matching 0x330E save — handing the caller a garbage D0
and turning a bounded loop into an infinite one (sound-request spam =
"different music"; main loop never returns = display frozen while
interrupt-driven RAM keeps changing; no exception ever fires, so crash
guards are blind to the whole class).

Rules now enforced:
- `tools/extract_char.py` merges scanner-LABELED engine/ROM operands
  (jsr/jmp/pea/lea/movea/move_src — never bare longs) into every twinned
  code region's ref list when the sibling diff didn't already cover the
  offset — each then requires a reconciliation row or rides a loud
  tripwire. First run surfaced 33 such refs (17 were wrong-coincident
  sound-farm entries).
- Identity rows are legal ONLY with byte-verified identical targets
  (24B plaintext compare vs2==vsavj — true for the kernel save/restore
  pair 0x330E/0x3306, false for every farm entry).
- Farm entries resolve by save+sfx-id signature (whole-entry byte match
  fails on positional bsr displacements); dual-entry pairs disambiguate
  by the next opword; duplicate-id entries by helper-target calibration.
- Debug lesson: a deterministic display-freeze with live RAM and no
  exception is diagnosed by VIDEO-HASH BISECTION (snapshots → onset ±10)
  then a full-frame trace — the wedged frame's ~300-unique-PC set reads
  like a table of contents of what still runs.

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

## Cross-emulator replays: same inputs ≠ same content (paid: 2026-07-25, ~2h)

The MAME↔FBNeo frame offset (a few frames at boot) does more than shift
frame indices — near any screen transition it changes WHICH content runs.
Three measured mechanisms, all found while validating `tools/compare_fields.py`:

1. **CPU-chosen opponents differ.** `02_demitri_vs_cpu` picks opponent 0x0E
   on MAME and 0x0A on FBNeo: the coin lands at a different attract-PRNG
   state. Any "vs CPU" replay has emulator-divergent content — dual-emulator
   comparisons must use replays where BOTH characters are scripted picks.
2. **Menu presses near an input-accept boundary.** In `03_two_player_vs`,
   S2 pressed 30 frames after S1 (frames 830-833) joins P2 on MAME but NOT
   on FBNeo (boundary measured between 830 and 836) — FBNeo then runs a
   1P-vs-CPU game and every downstream state differs. P2's input path itself
   is fine (verified with a P2-only replay: bit-identical behavior).
3. **Match-start predicate flickers.** The naive anchor predicate
   (match-active flags + full HP) is transiently true during round intros;
   `compare_fields.py` debounces 30 frames before accepting an anchor.

Even with matched content and a 1-frame anchor skew, anim-cursor-derived
fields (anim ptr, box ids) and mid-intro positions differ by a few frames of
phase slip — the tests/fields_m2a.tsv `phase` column (stable/settled/phase)
encodes what is comparable when.

**Authoring rules for dual-emulator replays** (see `16_xemu_2p.rpl`, the
validated template): both characters scripted; menu presses ≥100 frames
after the enabling transition and ≥10 frames from any expected boundary;
cursor moves short (3 frames, no autorepeat ambiguity) on long-stable
screens; input-neutral after the picks. Within-emulator oracles are
unaffected (whole-RAM frame-exact remains the standard there).

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

## Bare-long "pointers" in code are usually operand pairs — sibling-veto them (paid: 2026-07-25 session 7, ~3h incl. diagnosis)

The bare-long relocation heuristic (any ROM-plausible 32-bit value inside a
ported code region whose target lands in another ported region) is wrong far
more often than right in 68k CODE: adjacent instruction operands fuse into
plausible pointers. Measured in the x088512 companion zone: **47 of ~55
bare-long candidates were false** — e.g. `clr.b $6(a6); moveq #0,d0`
(bytes `0006 7000`) read as "pointer 0x00067000" into a ported region and
rewritten, silently destroying the `moveq`. The resulting crash (vec3 at
engine 0x015096, frame 3025 — the whole "anim state-index delta" frontier
of session 6) surfaced thousands of frames later, in ENGINE code, with a
plausible-looking wrong value: nothing pointed back at the corrupted
instruction. Diagnosis instrument: conditional logging breakpoint
(`GUARD_PROBE`/`GUARD_PROBE_COND` on `run_replay_guarded.sh`) at the engine
consumer, filtering on the relocated table base.

Rules now enforced in `tools/extract_char.py` (source-only regions):
- Immediate loads (`movea.l #imm,An` / `move.l #imm,Dn`) are LABELED refs
  (scan_code_refs), accepted only when the target is inside a ported region
  (immediates may be constants — never fabricate engine refs from them).
- Every remaining bare-long candidate is checked against the SIBLING build
  (vhunt2): its context (exact bytes around a wildcarded long; labeled
  operands wildcarded — they drift between siblings) is located in the
  sibling; a REAL pointer differs there by the host region's sibling shift,
  operand bytes are identical. Identical → veto. Conflicting or absent
  evidence → REJECT (loud in the extract log), never silently rewrite.
- Identical-evidence dominance: a generic context anchor can match several
  sibling sites; one spurious shift-consistent hit must not outvote the
  true twin.

## Engine hooks on hot paths break whole-RAM legacy comparison — by construction (paid: 2026-07-25 session 7, ~2h)

Any hook on a path vanilla executes (the secondary-object dispatch runs for
every object every frame) adds CPU cycles. Two measured consequences on
otherwise-vanilla content, both invisible to gameplay:
1. **Dead-stack ghosts:** interrupts land at skewed instruction boundaries;
   the handler's exception frame + register saves write the same stack
   addresses with different VALUES (e.g. a mid-frame work pointer that has
   advanced further). After return these bytes sit below resting SP
   ($FF8000 at frame-done) — dead, but inside the whole-RAM checksum.
   Observed window: `RAM:$FF7F00-$FF7FFF`.
2. **Sound-handshake phase:** the 68k↔QSound latch byte `RAM:$FF043C`
   (values 04/08) can phase-shift by one frame — the same mechanism as the
   `-debug` timeslice GOTCHA's $FF1CF0 latch.
With BOTH masked (`MASK_RANGES="043c-043d,7f00-8000"` on replay.lua), the
patched stage-4 build is bit-identical to vanilla for the full 02 replay.
Note the dispatch pump also runs for MENU-time objects (cursor sparkles,
UI effects): ghost divergence starts at frame ~470 even in the pick
replay, long before any match — unmasked divergence constants measured on
hook-free stage builds (2886, 1080, 4278) are void on hooked builds;
their masked (live-state) equivalents still hold.
A jsr-thunk hook additionally pushes a DIFFERENT return address than the
vanilla site — the ghost-clean topology (patch only the movea/moveq to
`jmp thunk`, keep the vanilla `jsr (A0)` at its original address, thunk
jumps back to it) eliminates that source; the interrupt-skew ghosts remain.
Zero-cycle table extension was investigated and is IMPOSSIBLE here: the
brief-format dispatch reaches only its inline table, and the code following
both tables is hot engine code with short branches — not relocatable
cycle-exactly. RESOLVED 2026-07-25 (maintainer-approved CLAUDE.md §4
amendment): hooked-build legacy comparison is live-RAM with exactly these
two windows masked (docs/atlas/ram.md); frozen masked vanilla expectations
live in tests/expected/vsavj/masked/, gate helper `m2a_legacy_gate_masked`.

## PC-relative word tables are DATA — never let a pointer heuristic rewrite them (paid: 2026-07-25, ~1h)

68k brief-format dispatch (`jsr/jmp (d8,PC,Dn.w)`) reads a table of 16-bit
self-relative displacements sitting *inline in the code stream*. Two
adjacent entries like `0006 0068` decode, to any 32-bit scanner, as a
plausible ROM pointer `0x00060068` — and a relocation pass will happily
"fix" them, silently corrupting the table (symptom: a jsr through the
table lands in the weeds one or two states into the ported behavior, far
from the actual damage).

Rules now enforced in `tools/extract_char.py`:
- Every discovered word table's FULL extent is recorded (`table_bytes`)
  and excluded from the bare-long relocation heuristic.
- Table length is bounded by the smallest forward displacement (the case
  code follows the table), so code words are never misread as entries.
- Escaping entries are rewritten as displacements against actual
  placement (`pcrel_tblent`), with a shared per-region ILLEGAL tripwire
  for unported targets — within d16 reach, gap-fitted near the region.
- Regions whose tables reference each other must keep source-relative
  spacing: `[[layout_group]]` / `near_map` in build/manifest/donovan.toml.

## Early-session generic rows can masquerade over later-understood structures

The session-5 bare-long pass resolved refs by unique byte match and
labeled everything it placed `engine_data`. Two of those rows were
sound-farm entries — so when session 13's farm audit enumerated
`kind`-tagged farm rows, they were invisible, and the byte match had
locked onto same-id vsavj entries (ids are in the matched bytes), i.e.
the same-id-different-meaning trap with a `verified` sticker on it.
Cost: a second playtest round (214P/214K music). Rule: when a structure
class gets understood (farm, dispatch bank, …), re-audit ALL earlier
generic rows whose vs2 address falls in the structure's range — match
mechanism, not row kind, decides what a row really is.

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

## OBJ record formats differ in ENTRY STRIDE, not just header meaning

Format 2 records: (tile.w, attr.w) 4-byte entries, count at +4. Format 0
records: tile-only 2-BYTE entries, count at +2, a single attr in the
header. A unified 4-byte walk "works" — the validation happens to pass —
but remaps only every other tile of format-0 records. Symptom: sprites
with ALTERNATING correct/garbage tiles (the character-select blink,
playtest round 4, 2026-07-28). Rule: when a structure is
format-dispatched (jump table), decode EVERY handler's field layout
before writing a walker; two formats sharing a header shape is an
assumption, not a fact.

## Loop-count idioms differ per handler: subq-before-dbra means COUNT, not count+1

The fmt-0 OBJ handler does `subq.w #1, d5` before its dbra (entries =
count); fmt 2 does not (entries = count+1). The count+1 misread made
the walker treat the NEXT record's format word as one extra tile entry
— harmless for months (the phantom code 0x0000/0x0002 was outside the
remap band) until the effect map started rewriting NON-band codes, at
which point it CLOBBERED the next record's format word (wild jump
through the format table at runtime). Caught before any playtest by the
output-image re-walk (record parity 1122 -> 1109), now permanent:
tools/verify_gfx_build.py runs in every stage-6+ build. Two rules paid
for here: (1) read the loop-count idiom (subq? dbra initial?) per
handler, never assume; (2) every data-rewriting pass gets an
output-side re-parse that must reproduce the source-side counts.

## "Slot-indexed cell" does not mean "slot-exclusive data" — three surgery traps

The select/splash record surgery tripped the masked legacy gate three
times, each root-caused to the byte (session 14g):
1. CELL POKES are RAM-visible: menu objects store chain anchors in work
   RAM; repointing a cell can change stored pointer values on any
   legacy replay whose cursor VISITS the slot. In-place record
   replacement only.
2. RECORD BUDGET WORDS are globally coupled: the OBJ emitter debits
   each record's budget from the shared frame budget (d7); a changed
   budget flips borderline skip decisions on crowded frames (one-byte
   $FF811B divergence, 04_select_fuzz). Replaced records must keep the
   HOST's budget word.
3. Coordinate lists can be read by OTHER SCREENS on legacy paths: the
   win screen reads the "hover P2" record's coord list (PC 0x8C6E2)
   in matches with no slot-0x0F character at all (322-frame position
   divergence in 05_timeout_idle). Every byte range you replace needs
   a legacy-read proof — the masked legacy gate IS that proof; run it
   after every record replaced, not at the end of a batch.

## The sibling-coincidence gotcha, third strike: the global coordinate pool

The companion-effect records' coordinate-list pointers aim at vs2's
GLOBAL X/Y pool (0x30xxxx) — same-value in vs2 and vhunt2, so the
sibling diff never flagged them, and the region ported with raw
vs2-space cptrs. Latent since M2a: those effects read coordinates from
unrelated vsavj bytes (masked by their art also being wrong). Every
same-value pointer class found so far — engine subs (the sound farm),
engine tables (the OBJ bank table), and now the coordinate pool — was
invisible to the diff for the same reason. Rule stands: same-value !=
same-meaning; any pointer INTO shared engine data needs a reconciliation
row or a content-match, never a pass-through.

## Same-value class #4: A5-relative work-var displacements

The engines' A5 work-variable layouts differ (vsavj damage vars at
-0x4BBE/BC/BA vs vs2 at -0x4B6C/6A/68 — a uniform -0x52 family shift).
Ported code writing engine work vars by displacement writes DEAD MEMORY
on vsavj — no crash, no diff visibility (vs2/vhunt2 share the layout),
just silently-wrong behavior (the zero-damage throw). Any ported code
that communicates with engine routines through A5 work vars needs its
displacements reconciled like ROM refs. Sweep pattern: displacement
words in the vs2 work-var bands inside ported code regions.

## Per-record BANK attribution: the effect-tail triage has no bank column

The x2b7ef4 gfx triage (same-index / +0x47 reloc / tail-place) is a
BANK-1 model. Records drawn by #$4000-bank sub-objects (Anita's feet
strip: 54 records, vs2 codes 0x0F8B-0x0FBC) went through the bank-1
maps and rendered garbage from the wrong page (solid green, then +0x47
garble — playtest rounds 10-13). A record's bank is a property of the
DRAWING OBJECT (+0x18), not of the record: it cannot be derived from
record content (that was f8eda2ca's content-voting failure, reverted).
Attribution method that works: breakpoint the OBJ format handlers
(fmt2 0x1B234 / fmt0 0x1AFC6; A0 = record+2, A6 = object) and read
+0x18(A6) live — tests/lua/obj_record_bank_trace.lua — then close the
set STRUCTURALLY from the sub-object's own record stream (obj+0x1C
cursor), never from a global scan. Fix data lives in
effect_tail.json bank2_recs/bank2_place (tools/gen_anita_bank2.py).

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

## The companion overlay draws the HOST's records (sword/statue blink)

The in-match companion overlay sub-objects ($FFB800-$FFBA00 class, bank
#$2000) walk per-char record-pointer strips selected by CHAR SLOT:
cursor obj+0x1C points into the char's strip region (vsavj Jedah:
0x2674AA-0x268Axx -> records 0x271Dxx-0x272Axx, codes 0xAFxx/0xB4xx/
0xCDxx = Jedah's bank-1 effect art; vs2 Donovan: 0x2A0Axx-0x2A1Cxx ->
records 0x2A1DAE-0x2A3F80, codes 0xA3E8-0xA499 = sword-drag/statue/
Anita-body art). On the ported build the slot resolves to JEDAH's
strips, so his animated darkness overlay renders where Donovan's sword
and statue belong — the "blinking sword/statue with the same palette"
(playtest rounds 8-11) is Jedah's overlay animating, not a tile fault.
Fix class: select_port-style in-place strip+record replacement inside
Jedah's per-char region (superset traps 1-3 above all apply).

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

## The attract INTRO CUTSCENE is Jedah — per-char display sites are legacy surface

VSAV's attract opening is Jedah's resurrection cutscene: his per-char
display code (the strip-table `movea.l #T,a0` sites) executes on every
legacy replay ~frame 888, long before the frozen-4278 demo divergence.
A static repoint of those sites is therefore a legacy break even though
the code "belongs to" Jedah. And the sites are additionally reached in
EVERY match by shared display flows (statically poking them hung a
Demitri match at 1857 — checksum log froze, the hang signature).
Working pattern (session 14q, proven 02-masked-clean full-length):
replace the 6-byte `movea.l #T,a0` with a 6-byte `jsr thunk`; the thunk
selects vanilla vs ported T on `$FF8004.l == 0x40000` (match active)
AND a slot-0x0F participant (`$FF8782`/`$FF8B82` char id). Legacy
matches and the cutscene take the vanilla load byte-exactly; only
slot-0x0F matches (always Donovan, including the attract demo) see the
ported tables.

## The per-char strip zone interleaves the SHARED MUSIC POOL

Placing ported data into apparent "gaps" of Jedah's strip/stream area
(0x267112-0x271CE8) broke legacy replays with sound-driver RAM deltas
(02_demitri masked diverged at 891/1726; $FF00xx/$FF04xx/$FF06xx state,
a fabricated stub materializing at $FF001A): the area interleaves the
music-sequence pool that the sound streamer reads on every path, via
computed addressing that A-register watchpoint sampling cannot see.
Watchpoint-based "read maps" are lossy in exactly this blind spot —
apparent gaps are not evidence of deadness. The only space PROVEN dead
in this build is what only a slot-0x0F in-match path can reach: Jedah's
own anim area (streams 0x248D5C-0x25004E, records 0x25570C-0x2601EC,
attributed via vanilla-demo cursor sampling) — placement there was
02-masked-clean full-length.

## Blind long-relocation over ported data blobs corrupts streams

Relocating every even-aligned long that "looks like" an in-window
pointer (the overlay slice: 293 rebased longs, 2811 tile words in 163
scan-validated records) corrupted enough stream/coordinate data to
crash the Donovan path at match start (watchdog boot-loop), while the
identical placement with no rewrites was stable. Coordinate words and
stream commands alias pointer prefixes at data-blob scale. For record
regions with a known pointer web (anim, x2b7ef4) the narrow window +
record validation held; for a MIXED zone (tables + strips + tag
streams + records + coordinate runs) the rewrite set must come from a
STRUCTURAL CLOSURE walk (tables -> strips -> streams -> records),
never from a flat scan. The closure requires decoding the stream node
language first — that is the stage-7 blocker, not the architecture.

## GFX and coordinate data are INVISIBLE to every RAM-basis gate

Playtest round 16: the overlay build's tile placements corrupted the
title screen, select screen and speed menus — and the full masked
legacy battery stayed green, twice. Three distinct blind spots, now
covered by the pixel gate (tests/test_gfx_menus.sh, wired into
test_m2b_stage6.sh):
1. TILE ROM CONTENT: work-RAM checksums never see gfx ROM bytes. Any
   wrong placement renders garbage with perfect RAM.
2. SCROLL/OBJ BYTE SHARING: CPS-2 scroll1/2/3 layers decode THE SAME
   ROM bytes as OBJ tiles at different granularities. An "OBJ-dead"
   position proves nothing about the scroll tiles backed by those
   bytes — the overlay's dead-Jedah OBJ pool trashed menu tilemap art.
   A placement pool must be BYTE-dead for every consumer, not
   index-dead for one decoder. (The proven-safe classes so far: bytes
   of art the port itself replaced, and 0xFF padding runs.)
3. COORDINATE LISTS flow ROM -> OBJ RAM at draw time, never through
   work RAM. select_port's in-place list write shifted the speed-menu
   TURBO/AUTO text 8px for seven shipped builds: Jedah's 1-pair
   name-banner list [0x32A196,0x32A19A) IS the speed-menu record's
   first coordinate pair — the pool nests lists inside lists.
4. ...but CPTR VALUES ARE RAM-VISIBLE (the fourth stored-anchor
   class): relocate-and-repoint diverged 02/03/08 masked at select
   entry (~frame 820) — select-screen init caches list pointers into
   work RAM on legacy paths. The working rule pair: NEVER change a
   host record's cptr, and NEVER write pool bytes another consumer
   shares (SHARED_LISTS in select_port.py; shared lists keep the
   host's coordinates and the ported art draws at the host position).
   The pixel gate is the detector for class 3; the masked gate for
   class 4 — it takes BOTH to make pool surgery safe.
