# GOTCHAS (project) — traps in OUR pipeline and method

## A comparator's own ground-truth test can RATIFY a deviation from the governing spec (paid: 14z-95, GitHub #52)

`tools/compare_flicker.py` exempted the LAST divergent stretch from the
`>=60` re-convergence requirement entirely. CLAUDE.md §4 v2 has no
end-of-log clause — but the code, its docstring ("end of log ok") and
`tests/test_compare_flicker.sh` (`ok: end-of-log flicker -> FLICKER (no
converge window needed)`) all agreed **with each other**. Three artifacts
agreeing looks exactly like a validated behaviour, and CLAUDE.md §4's
"verdict logic is itself tested" is satisfied on its face.

**The trap:** ground truth validates a comparator against ITS AUTHOR'S
INTENT, not against the ratified text. When the two diverge, the test is
what makes the deviation durable — it converts "nobody noticed" into
"someone asserted this on purpose", and the next reader stops there. The
drift direction is what makes it worth catching: this one WIDENED a
tolerance, which is the single thing §4 says may not happen without a
measured mechanism and sign-off.

Two things it cost beyond the exemption itself:
- **The width was mis-stated in the ticket and in my own first reading.**
  It was filed as "the final one or two frames". It is as wide as
  `min-converge` — the check is SKIPPED, not narrowed, so any stretch
  ending within 60 frames of the log's end was exempt.
- **A `len(log)` sentinel is off by the trailer.** These logs end with an
  `END <n>` row, so measuring the tail to `len(a)` counts it as one
  converged frame. Measure to the last row that starts with a digit.

**And the blast-radius measurement that "could not be done" could.** The
14z-94 pass concluded it was unmeasurable statically ("188 of 188"),
having scanned every flicker+composite spec. `compare_flicker` governs
only the **19 `flicker`-kind** specs, and each has a basis log whose tail
after the last frozen flicker frame is a `wc -l` away. Smallest live tail:
**1325 frames**. Scope the population to the instrument before concluding
a question is unanswerable.

## Half the Lua instruments stage inputs one frame off replay.lua — a frame number from one is not a frame number from the other (paid: 14z-90, GitHub issue #10)

`tests/lua/replay.lua` writes its checksum for frame N and THEN stages
inputs for N+1 (`held[frame + 1]`), so "the set in effect during frame N
is the one staged at the end of N-1". Ten of the twenty replay
instruments instead stage at the START of the callback
(`prev = held[frame]`), landing a press one frame earlier. Measured
split: every DIVERGENCE-ATTRIBUTION instrument (tap_writes, field_trace,
trace_writes, type_write_census, dispatch_census, obj_record_*_trace,
pal_poke_heal, replay_guard) is canonical; the drift is in the probe
family (obj_records_dump, ring_tap, read_tap, qs_sweep, objy_bits,
unmapped_probe, snapshot_frames, qs_table_trace, qs_z80_trace, bp_regs).
Origin: `898daea` had one flavour; `23071cc` (14z-51) copied a variant
and every later instrument copied the copy.

The trap is not that the probes are "wrong" — most are passive observers
whose output is unaffected by which frame a press lands on. The trap is
CROSS-REFERENCING: taking a frame number out of a probe log and matching
it against a `compare_*` first divergence, a masked window onset, or
replay.lua's checksum log. Those are one frame apart, and nothing says so.

Why it is not simply fixed: the frame constants in the consuming gates
were tuned UNDER the drifted timing — `test_beam_variants.sh` DUMP_FRAMES
(nine values, duplicated in two places), `test_tenant_hud.sh:104`
DUMP_FRAMES=3100/FRAMES=3110, `test_hui_df_style.sh` OBJFR/PALFR,
`audit_trap_parity.sh` WINDOWS, `audit_voice_borrow.sh` WINDOW=3985,4005.
Correcting the staging without re-deriving those constants does not make
the gates right, it silently re-dates them. The staging fix and the
re-measurement are one change, and it is scheduled after the legacy
re-freeze. Until then every drifted instrument carries a banner saying so.

**STATUS 14z-93 (re-verified at HEAD; GitHub #10 still open).** Nothing has
been fixed and the deferral is still deliberate — but two claims in this
entry were not true when checked:

- **"every drifted instrument carries a banner" was false for THREE of the
  ten.** `bp_regs.lua` and `ring_tap.lua` had none at all, and
  `bp_regs.lua`'s header asserted the OPPOSITE ("Combines tap_writes.lua's
  replay/POKES playback" — tap_writes parses `held[fr]`, bp_regs parses
  `held[fr + 1]`). `read_tap.lua` had one whose direction was backwards: it
  said "one frame earlier" when the press lands one frame LATER. All fixed.
- **The stated precondition has been met.** "Scheduled after the legacy
  re-freeze" — that completed in 14z-91. The item is ripe, not blocked; it
  waits on scheduling and on #91/#92 clearing under rule 6.

**MAINTAINER DECISION 2026-08-16: keep it open, keep it deferred.** The
finding is correct, the mitigation is now real, and the fix is scheduled
rather than dropped — GitHub #10 carries `deferred-with-reason` alongside
`contested` to say exactly that. This entry is the reason, and it should be
read before anyone "just fixes the staging": the one-line edits are not the
work, re-deriving the five gates' frame constants is. And when it is done,
**re-freeze nothing** — `replay.lua` and `replay_guard.lua` are canonical
and untouched, so no frozen log moves.

Now frozen and gated by `tests/test_replay_stage_census.sh`: the split is
pinned at exactly 10 deviant / 11 canonical, a NEW instrument copying the
wrong flavour FAILS, and every deviant must carry the banner. **Strip Lua
comments before classifying** — the banners quote `held[frame + 1]` while
explaining the canonical convention, so a naive grep reads a drifted file as
canonical. Measured 14z-93: that mistake turned the census from 10 deviants
into 3 and was one step from being reported as "7 of 10 already fixed".


The build/extract/patch chain, the replay harness and gates, manifests,
the WIDE profile, and reverse-engineering method that is ours rather
than the game's. Dies with the project; the other two files do not.

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
two windows masked (docs/game/atlas/ram.md); frozen masked vanilla expectations
live in tests/expected/vsavj/masked/, gate helper `m2a_legacy_gate_masked`.
**Addendum (14z-88, paid: one red battery + a triage session): a masked
window is a BASIS, not a flag.** `replay.lua` SKIPS masked bytes from the
checksummed stream, so adding a window changes every frame's checksum on
the build side — the vanilla masked logs must be REGENERATED under the same
mask into a NEW basis dir (v1 `masked`, v2 `masked-v2`, v3 `masked-v3`;
`tools/freeze_masked_basis.sh`), every `.masked` spec's `<baseset>` moved
to it, and every gate that hardcodes the base path or the mask string
updated (grep `masked-v` and `MASK_RANGES` across tests/). And the reason
the fourth window was needed at all: a palette-ROW move (the 14z-87b
medallion 0x1A -> 0x1D) is ALSO a STAGING-SLOT move ($FF3F02 + row*0x20).
"The palette path never transits work RAM" is true of the palette write
and false of the staging copy — the 14z-87b registry note said the work-RAM
streams were unchanged, and the suites said otherwise the same evening.
**And the second half of the lesson (14z-88, paid: the row move itself):
palette CONTENT in a fade's row set is CYCLE-relevant.** The select→VS
fade does data-dependent per-color work on a frame that already runs at
the VBL edge (vanilla's per-iteration counter shows 2 frames/iteration
there); a different palette in a processed row moved one legacy pairing's
main loop across a VBL (replay 38 on the H/P/merged builds: one iteration
lost, whole-RAM never re-converges vs vanilla) while every masked-13
legacy class stayed frozen. Data-only ≠ cycle-neutral. Before moving or
recoloring any select palette row: run the legacy pairings against
vanilla, not just the masked 13; and attribute moved `.sha1`s with
tests/audit_mask_window_ff42a2.sh before re-freezing — that audit is what
caught it. **UPDATED 14z-89: "the P2-human legacy pairings (31-40)" was an
under-count — 35 of the ~43 self-frozen replays per set are legacy
pairings, they are `.masked` now, and `tests/audit_legacy_pairings.sh`
keeps it that way. The same sweep found the class ALREADY PRESENT on the
reverted builds (replay 38 on donovan-m5, replay 24 on all three), so
this is not only a rule for future row moves.**

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

## Mid-frame transients and perturbing probes (win-palette post-mortem)

Two diagnosis traps from session 14t, each of which produced a round of
false conclusions before the mechanism emerged:
1. The masked checksum samples EARLIER in the frame than DUMPS do. A
   divergence in data that is staged into work RAM mid-frame and
   reused/cleared by frame-done is checksum-visible but INVISIBLE to
   frame-done dumps — comparing dumps "at the divergent frame" showed
   byte-identical RAM while 3229 frames of checksums diverged. To
   inspect a masked-gate divergence, compare at the checksum's sample
   point (or diff the checksum halves to localize, then trace writes).
2. Per-frame UNMASKED checksums (and dumps spanning $FF043C) READ the
   QSound handshake latch and perturb the run — both builds get
   perturbed identically, so a live patched-vs-vanilla comparison can
   look clean while the gate's masked (non-perturbing) runs genuinely
   diverge. Legacy comparisons must replicate the gate's exact mask
   set. (This also likely explains the session-14 standing-watch gate
   anomaly: mixed-mask runs are not comparable.)

## Never write an unverified gap (the Felicia wall-jump lesson)

The generator's auto_tables "gap" heuristic treated untyped gaps
between per-char tables as more per-char rows and wrote slot-0x0F
values plus 0x1F "dark mirrors" into them — 42 writes, 31 changing
vanilla engine bytes. The gaps are JUMP-PHYSICS PARAMETER tables:
index 0x1F holds the wall-jump-back velocity, and 0xFFFF4800 ->
0xFFFFEC00 broke Felicia's triangle jump in PURE LEGACY matches
(rounds 18/19; she rides to Y~0x4AB and wraps). Invisible to every
gate: no replay played Felicia (coverage), and per-char physics
tables only surface when that char uses that move. Rules earned:
1. A gap between known tables is NOT a table row. No write without a
   decoded consumer — speculative "it's probably the same layout"
   writes into engine space are how legacy mechanics break.
2. Restore-bisection (copy vanilla bytes over patched spans in a test
   rompath) is the reliable attribution method for engine deltas —
   but spans that cut through EXECUTING ported code crash the boot
   and read as false "fixed"; harden the verdict with liveness
   (timer tick + match flag), and treat only same-sign results as
   evidence.
3. The per-char-row + dark-mirror assumption must be verified PER
   TABLE (the bank table has 0x18 rows with 0x10-0x17 dark forms;
   these physics tables are not char-indexed at all).

## Disabling a heuristic CLASS wholesale can revert load-bearing writes
Session 14w disabled the gap auto-table class to fix Felicia's jump
physics — collateral: the class had ALSO been covering the throw
victim-keyframe pointer table (gap_be27a), so the throw cinematic broke in
the SAME build that carried the 14v grab rows and the winpal copies. Three
suspects on one commit produced two successive wrong convictions (grab
rows, then winpal copies), each "confirmed" by build-timeline correlation.
Lessons: (1) when killing a heuristic class, enumerate what it was
actually writing and re-port the load-bearing members explicitly; (2)
build-timeline correlation is attribution, not proof — only a mechanism
trace (here: the tap on the victim's X/Y naming PC 0xCE51C and its table
read) convicts; (3) a "fixed/broken" verdict from play sampling is weaker
than a replay trace — the round-21 "throw restored" confirmation sampled
clean-looking throws on a build where the replay shows 21 teleport-scale
jumps.

## The RAM gate cannot see NEW-CHAR visual wrongness — pixel A/B is the tool
Round-25 lesson, twice in one change: (1) spark_bank_swap drew garbled
tile blocks (bank 0x4000 under vanilla strips) and (2) spark_spawn_mark
made ANITA vanish while a marked spark was live (+0x9A carries display
semantics — it is the owner-char-id field other spawner paths write).
BOTH passed the full battery: masked legacy gates only cover legacy
content (the thunks were slot-0F-gated), the oracle gate compares mapped
FIELDS, and the menu pixel gate covers menus. New-character VISUAL
correctness has no automated gate — any change touching the effect/
display path must ship with a before/after SNAP_FRAMES pixel comparison
on a replay that exercises it (replay 17 hit frames 3477-3481 is the
ready-made spark probe). Also: never assume an object field is dead
because one path leaves it stale — prove it by pixel A/B, not by RAM.

## Sibling twins can differ by ONE hoisted instruction — codebyte-matching lies
The round-26 sword root cause: vs2 refactored the set-anim-by-number
resolver into TWO entries — 0x5C77A applies `andi.w #$ff,d0` and falls
through; 0x5C77E skips it (so Savior-2 extended anim numbers 0x100+ can
resolve). vsavj's twin embeds the mask MID-routine with a single entry.
The auto-matcher byte-matched the shared prefix and emitted a "verified"
row mapping the UNMASKED vs2 entry to the MASKED vsavj routine — every
ported call truncated its anim number (0x127 -> 0x27) and resolved a
wrong-but-valid node in the right table. Nothing crashed; the sword
simply played idle anims through every attack. Lessons: (1) when a vs2
ref lands a few bytes past a routine head, check what those skipped
bytes DO — an entry that skips a masking/clamping instruction is a
different function; (2) "wrong data, right table" bugs present as
plausible-but-wrong behavior, invisible to every RAM/crash gate — only
behavior probes (the sword gate) catch the regression class. Fix
mechanism: reconciliation kind `patched_clone` (vanilla bytes minus the
divergent instruction, ported refs only).

## "Run once at match start" is a TIMING TRAP — use a match-active countdown
Three failed single-shot placements for the OBJ-tail clear (14z-7, all
measured): char-init fires DURING the VS screen (which redraws the
polluted buckets every frame until ~30 frames before round start); the
sword routine's first per-frame execution ALSO lands mid-VS (companion
objects live from char-init); and $FF8004==0x40000 is set during the VS
screen too, so it cannot distinguish "round visually started". The
robust pattern: arm a counter at init, decrement per frame while
match-active, act at zero (~0x50 frames) — replay-timing independent,
and doing the action in the object-UPDATE phase means the same frame's
list rebuild hides it (no visible blank).

## Phantom fixes: validate against the USER'S repro, at the RIGHT frames
14z-7 shipped a fix validated by (a) a probe move that only resembled
the reported one and (b) snapshots taken only at zap frames, where the
flash silhouette hides the victim's body. The fix cleared buckets the
real defect never reads; a controlled A/B on the correct move (replay
33) showed pixel-identical output with the fix on and off. Rules paid
for: reproduce with the reporter's EXACT input first; snapshot every
phase of a cyclic effect (zap AND between-zap); and before shipping a
visual fix, A/B the fix-on/fix-off builds on the reproducing replay —
"the metric improved" (buckets zeroed) is not "the pixels changed".

## Cross-game A/B pixel comparison: align by DISPLAYED RECORD, not frame
Two false "garble" verdicts in one session (14z-9): the engines skew
1-2 frames, so same-frame snapshots can compare DIFFERENT anim records
— a mid-flail pose against a settle pose reads as scattered garbage.
Align by the victim's cursor value (dump +0x1C, snapshot the frames
where both games display the SAME mapped node). Also: the sibling
games' VANILLA characters have differing script data (vs2-Victor
commands hold poses in the opposite order from vsavj-Victor) — a
divergence in what the two games DISPLAY is not automatically a port
bug; check who commands the difference before blaming the port.

## Pipe a build tool through tail and a crash packs STALE artifacts
build_donovan.sh piped build_gfx through `| tail -10` without pipefail:
when the readback assert crashed build_gfx mid-run, the pipeline kept
going and re-zipped the PREVIOUS build's tiles — two consecutive "fix"
builds shipped byte-identical gfx while printing fresh-looking logs
(the program-side fingerprint still changed, masking it further). Fixed
with set -o pipefail; the tell was mtime: gfx/vm3.14m an hour older
than the rompath zip. Check artifact mtimes when a fix "changes
nothing".

**SECOND payment (14z-90, GitHub issue #1).** The lesson was fixed in
`build_donovan.sh` and then reintroduced in its CALLERS. Three gates
piped the builder through `tail`, so the builder's own rejection paths
(`verify_gfx_build.py` :404, `audit_romset_identity.py` :415) were
discarded — and because the pack at :275/:287 happens BEFORE both, a
REJECTED artifact was already on disk to be soaked, legacy-gated and
stamped PASS. `run_hui_behavior.sh:79` was written 2026-08-07, a week
AFTER the fix above: a documented gotcha does not protect a new call
site, only a test does. Two variants beyond the filed one, both
measured: a build dying before the `rm -rf rompath` at :263 leaves the
PREVIOUS build's rompath and the gate validates yesterday's ROM under
today's name; and on a FRESH outbase it leaves none, at which point
`run_mame.sh`'s chained `-rompath "dir;$ROMDIR"` silently resolves the
PRISTINE set and the legacy gate measures vanilla against vanilla. So
the fix is two assertions, not one: propagate the status (redirect, not
pipe — `pipefail` is a bashism these `#!/bin/sh` gates avoid) AND assert
the rompath exists before measuring it. Ground truth:
`tests/test_build_gate_status.sh`, which fails on the pre-fix tree via
`GATE_SRC=`.

## A0-at-write is post-increment — SECOND payment (14z-18 tail row)
The "accent super-cycle phase 2 reads 0x39FC00-0x39FC3F" conclusion
derived a 0x40-byte window from two logged A0 values without
subtracting the movem batch size: the real march reads exactly T0
(0x39FBE0-FF) and T1 (0x39FC00-1F), overlapping by design (the slide
IS Jedah's glow animation). The misread placed a "tail" replacement on
dead ground and left the visible bug alive through a playtest round.
When deriving a read WINDOW from tap A0 values: subtract batch size
from EVERY logged value first, then take min/max.

## Hole "a" is inside the CPS-2 crypt range — thunks with EMBEDDED DATA
## must go to hole "b"
Placed code is stored re-encrypted wherever the address falls inside
the crypt range, so opcode fetches decrypt correctly — but DATA READS
bypass decryption. A site_thunk carrying an embedded palette block
after its rts placed in hole "a" (0xBF6A0-0x100000) executed fine and
returned the right pointer, while every movem data read of the block
came back as ciphertext: garbage palette rows, code demonstrably
"working". Hole "b" (0x3EC720+) is outside the crypt range — raw
storage, data-readable, still executable. site_thunk rows now take
hole = "b"; use it for ANY thunk whose body is read as data. The tell:
placed bytes plaintext in-zip = outside crypt range; garbled = inside.

## A same-slot "vanilla control" controls nothing — vary the dimension
## under test
The first vanilla control for the shock-aura tap picked vanilla Jedah
— the SAME slot 0x0F as ported Donovan — so identical tap sources
proved nothing about per-slot vs global. The discriminating control
was a different victim (default-cursor char): identical sources there
= engine-global. When testing "is X per-char?", the control must vary
the char, not just the build.

## The tile-placement pool is block-aware first-fit — carving cells out
## CASCADES the whole allocation
Reserving 4 cells (free.discard) for a fixed-position need moved 267
effect-shelf placements: the allocator fits RECTANGLES into runs, and
removing mid-run cells re-routes every later fit. The generated set
stays internally consistent, but the ROM diff explodes and any
frozen/checked-in artifact that referenced old cells silently
mismatches. Fixed-position tile needs must allocate at the pool TAIL
or ride the existing exception flow. (14z-22; the change was reverted
— the "missing" tiles turned out unreferenced anyway.)

## A cited address in a session log is a CLAIM, not a fact — re-verify
## against the manifest/built image before planning on it
Session 14z-41 read the reconciliation row's vsavj target as 0x73376,
disassembled THAT address, found an instruction-fragment tail falling
into rts, and planned a whole next-session fix around the "accidental
stub". The row actually said 0x77376 (one hex digit away) — the
byte-identical true spawner twin — and the built image called it
correctly all along. One digit cost a session plan. When a log entry
names an address as "the mapped target", grep the manifest row AND
xxd the built image at the call site before building any theory on
it. (14z-42; the misread survived two session summaries unchallenged.)

## A no-crash soak can silently lose the behavior it was written to
## exercise — assert the behavior, not just survival
Replay 19's ES DP pairs demonstrably produced ES moves when written
(session 11: the ES crash was MEASURED from them). On current builds
every scripted button-pair falls back to the LP version (chain-start
node proves it) — with a stock present, same-frame or 1f-offset pairs
alike, for both DP and Lightning Sword — while MANUAL ES works fine.
The DP-spam gate stayed green throughout because it only asserts
END-clean. When a soak exists to exercise a specific mechanism, add
one assertion that the mechanism actually fired (here: the ES chain's
node family in a dump), or its coverage can quietly evaporate.
(14z-43b; when the scripted-accept divergence is root-caused, note it
here.)

## Sampled uniformity is not uniformity — extract the FULL set before
## synthesizing engine cases
The state_hook synthesis (session 8) sampled vs2's extension-state
cases, saw three consecutive seq ids (0x2CD/2CE/2CF) and uniform stub
shapes, and generated all 12 as `seq_first_id + k`. The real census
(14z-46): only the first three are consecutive; ids jump (2d3, 2d1,
2d4), repeat (2cd twice, 29e twice), dip into the vanilla range
(0x290+color — whose records DRIFTED between engines), and two
"stubs" are entirely different shapes (direct fixture-block palette
uploads). 8 of 12 synthesized stubs were wrong; three were LIVE bugs
(the yellow swordless deity among them, shipped for ~25 rounds).
When synthesizing N parallel engine cases from a sibling, disassemble
ALL N and diff them against each other first — and add a build-time
assertion against the source engine's own table (the seq_ids
verification pattern) so config drift fails the build.

## Fuzzy code-similarity reconciliation collapses near-identical
## helpers — content-verify PARAMETER TABLES, not just code shape
The motion-helper family (`lea <table>(pc),a3; bra <dispatcher>`) is
30+ near-identical 8-byte routines differing ONLY in table address
and dispatcher target. The farm-helper-match ladder mapped vs2
0x2915C AND 0x29164 to the SAME vsavj helper (two distinct motions
can't share one table) and 0x2916C to a shifted-table neighbor —
all three "verified". Result: every half-circle move dead for ~50
playtest rounds (never tested = never caught; round 58). For
helper-family reconciliation the identity that matters is the
PARAMETER (table content + dispatcher kind), and vs2 CHANGED some
motion definitions so exact twins don't always exist — the
farm_port kind (port table + stub) is the correct fallback, and it
already existed for two hand-done rows. Content-match census script
in the 14z-48 session log.

## replay.lua DUMPS separator is ';' — commas die silently late
`DUMPS="a:r1,b:r2"` exits rc=3 after a full emulator boot with no
dump artifacts and no error text (the lua parser takes the whole
comma-joined string as one malformed spec). Multiple windows —
including several on the SAME frame — work fine ';'-joined (the
existing gates already relied on this; the comma form cost three
blind reruns this session). Symptom to recognize: rc=3 +
FileNotFoundError on the first expected dump.

## Sound is invisible to every RAM and pixel gate — it needs its own
The masked legacy gate, the field oracles and the pixel menu gates were
ALL green while Donovan was completely silent, and equally green when a
sound path was wired to vsavj's music-track id range (the round-2
"214P plays music" bug). Sound state lives in a ring the gates mask as
noise and in a Z80/QSound pipeline they never look at. tests/
test_don_sound.sh exists because of this: it taps the ring, fails on
any id in the music range, and freezes the per-replay id inventory.
Any subsystem whose output leaves the 68k address space (sound today,
anything sent to another processor tomorrow) needs a dedicated
detector — "the battery is green" says nothing about it.

## Censusing a structure without knowing its terminator counts garbage
The first y-word census scanned all of OBJ RAM and reported 841 sprites
with bit 15 set — "vanilla uses the bit, plan dead". Every one of them
was stale data PAST the list terminator, never drawn. The same trap in
the scroll3 tilemap: raw `maxcode` is always 0xFFFF because unused cells
hold that sentinel, which reads as "legacy content reaches the address
wrap" when nothing of the sort is happening. Walk structures the way the
hardware walks them (respect terminators, bounds and buffer selection),
and separate sentinels from real values, or the measurement will confi-
dently answer a question you did not ask.

## The FBNeo gate never rendered a pixel — RAM checksums are blind to video
The FBNeo harness ran every frame with `pBurnDraw = NULL`. That is correct
for speed and for a work-RAM oracle, but it means the emulator-side gate
could not see the video path AT ALL: a change to sprite/tile rendering
produces byte-identical RAM logs whether it works or draws garbage. This
was discovered while trying to verify the CPS-2 WIDE 19-bit tile address,
whose entire effect is in `cps_obj.cpp` — the gate would have "passed" it
without ever executing the modified line. Fixed by an opt-in framebuffer
checksum (`FBNEO_HVIDEO=<path>`, harness.cpp), now compared alongside RAM
in tests/test_wide_profile.sh. General lesson: before trusting a gate on a
change, confirm the gate's instrumentation actually EXECUTES the code path
you changed.

## An A/B reference binary must differ by exactly one thing
The emulator superset invariant compares a patched build against a
reference build. The first reference was an older binary that predated the
harness's video capability, so it produced no framebuffer log and every
comparison "failed" — noise, not signal. Build the reference from the SAME
tree state with only the patch under test reverted (`WIDE=0
tools/setup_fbneo.sh`). Same discipline as any controlled experiment: one
variable. A reference that drifts is worse than no reference, because its
failures look like real findings.

## A canary must change exactly ONE thing, or it cannot answer anything
The first CPS-2 WIDE B4 canary tried to prove the new 19-bit gfx banks
were reachable by remapping 15 characters' bank-table rows to the new
banks and requiring pixel-identical output. It failed — and the failure
was uninterpretable, because the same edit ALSO changed game logic (see
above). Two variables moved at once, so neither "the emulator path is
broken" nor "the game strips the bit" could be concluded. The isolation
that DID work was cheap and should have come first: run the modified
program under the OTHER emulator (which lacks the feature entirely) and
diff — that immediately separated "game behaves differently" from
"emulator renders differently". Design canaries so that exactly one
subsystem can account for the result, and prefer changing the EMULATOR
under a test-only flag over changing the ROM when the ROM change has
side effects.

## A relocation test with no negative control proves nothing
The CPS-2 WIDE PRG canary relocated one character's sound table into the
extension and came back RAM-identical — apparently proving the 68k could
read above 4MB. It proved nothing: pointing the same table at ZERO FILL
was *also* RAM-identical, because that row is never read in those
replays. Any "I moved X and nothing changed, therefore X works" test must
be paired with "I broke X and something changed". The fixed version
relocated all 20 tables, where the zeros variant does diverge and the
identical result is real evidence.

## The MAME replay harness was blind to the video path too — until B5
The FBNeo lesson (14z-55, `pBurnDraw = NULL`) applies verbatim to MAME:
`tests/lua/replay.lua` checksummed work RAM only, so any MAME gate was
structurally blind to rendering — and the CPS-2 WIDE 19-bit tile address
is *entirely* a rendering change. `VIDEO_OUT=<path>` now writes a
per-frame framebuffer checksum alongside (never into) the RAM log, and
`tests/test_replay_video_selfcheck.sh` ground-truths it in both
directions before any gate trusts it. Measured: 5,520 frames of
`02_demitri_vs_cpu` produce 3,952 distinct framebuffer checksums, and the
RAM log stays bit-identical to the frozen expectation with it enabled.

## `git apply` SILENTLY SKIPS the patch when the target is inside another
## repo's working tree — and exits 0 (paid: 2026-08-03, B5)
`tools/setup_mame.sh` builds from a mirror under `~/.cache/vampire-saved/`.
On this machine **`$HOME` is itself a git repository**, so the mirror sits
at prefix `.cache/vampire-saved/mame/` inside it. `git -C <mirror> apply
0002-cps2-wide-v1.patch` therefore read the diff's paths
(`src/mame/capcom/cps2.cpp`) as **$HOME-repo-root-relative**, found them
outside the current prefix, printed `Skipped patch 'src/...'` — and
**returned 0**. `git apply --check` "passed" for the same reason.

Result: the script printed "CPS-2 WIDE profile patch applied", MAME built
cleanly for nine minutes, and produced a completely STOCK binary. Nothing
in any exit code said otherwise. Only `-listfull vsavjw` caught it.

Rules that follow:
- Use **`patch -p1 -d <dir>`** for out-of-tree trees. patch(1) has no
  repository semantics and cannot be confused by an ancestor `.git`.
- **Never treat an exit code as evidence that a patch landed.** Assert on
  the RESULT: grep the patched file for a marker, and assert the built
  ARTIFACT has the feature (`setup_mame.sh` now does both, and also
  asserts that a `WIDE=0` reference binary does NOT know `vsavjw`).
- Same family as the FBNeo CRC trap above: the toolchain reported success
  while silently substituting nothing. Assume this failure mode exists in
  every "it said OK" step of the build.

## `git submodule add` stages the DEFAULT BRANCH, not the tag you check out
(paid: 2026-08-03, B5 — invalidated a green 36/36 gate run)
The sequence

    git submodule add --depth 1 <url> emu/mame
    git -C emu/mame fetch --depth 1 origin tag mame0288
    git -C emu/mame checkout mame0288          # working tree only!

leaves the SUPERPROJECT INDEX pointing at the default branch head — the
`add` staged it before the checkout, and the checkout never re-staged.
Everything looks right (`git -C emu/mame log -1` shows the tag's commit)
until something runs `git submodule update`, which dutifully restores the
INDEXED commit and silently moves the tree back to master.

That is exactly what `tools/setup_mame.sh` does on every invocation. The
reference binary had been built before the reset (0.288) and the WIDE
binary after it (**0.289**), so the emulator superset invariant compared
two different MAME VERSIONS and still reported 36/36. The result was true
about those two binaries and meaningless as the claim it was making —
"the patched binary differs from the reference only by the profile patch".
The drifting-reference trap of 14z-55, in a new costume.

Rules:
- After checking out a tag in a submodule, **`git add <submodule>`**.
- Do not rely on the gitlink alone: `setup_mame.sh` now hard-codes the
  pinned SHA and refuses to build anything else. A build that silently
  changes the instrument is worse than a build that fails.
- Annotated tags: `git rev-parse mame0288` returns the TAG OBJECT sha
  (`2c38dc6e`), not the commit (`27a8d9e8`). Compare with
  `mame0288^{commit}` or you will "discover" a mismatch that is not one.

Side observation worth keeping: 0.288 and 0.289 produced **bit-identical**
work RAM and framebuffers across the 12-replay legacy corpus, so CPS-2
emulation did not change between those releases. Useful to know, and not a
substitute for pinning.

## The input-integrity check's first draft flagged EVERY replay — :IN2
## carries the EEPROM data line
Comparing whole input ports against "baseline with the staged bits
cleared" fired on every single run at frame 77 (`:IN2` expected `ffff`, got
`fffe`). Not external input: **`:IN2` mixes the EEPROM serial data line in
with the coin/start bits**, and it legitimately toggles during boot. The
check now masks to the union of bits the harness can actually drive, which
loses no detection power because host keystrokes land on controller bits.
Caught by testing the checker before trusting it (CLAUDE.md §4) — had it
shipped silent-but-wrong in the other direction, it would have been worse.

## `WIDE=0 tools/setup_fbneo.sh` did not produce a clean reference — it only
## SKIPPED applying the profile patch, never reverted it
(paid: 2026-08-03, B5b — the FBNeo emulator superset invariant may never
have actually been tested)
`setup_fbneo.sh` applies the CPS-2 WIDE patch to the submodule WORKING TREE
and leaves it there. On the next invocation with `WIDE=0` the script took
the "skip" branch, printed **"WIDE=0: harness-only build (reference binary
for the superset invariant)"** — and built a binary that still **carried the
profile**, because the tree had never been reverted.

Consequence: `tests/test_wide_profile.sh` section 1 compares FBNEO_REF
against the WIDE binary. With a contaminated reference it was comparing
**WIDE against WIDE**, which passes trivially. That section is the
*emulator superset invariant* — the entire justification for permitting
emulator changes under Rule 1 v2. A vacuous pass there is the most
expensive kind of green.

Fixes:
- `WIDE=0` now **reverts** the patch (`git apply -R`) and refuses to build
  if `Cps2Wide` survives.
- Both builds assert on the ARTIFACT: the driver title string "CPS-2 WIDE
  v1" is compiled in, so `grep` on the binary answers "does this build carry
  the profile?" in both directions — a reference that has it and a WIDE
  build that lacks it are equally broken.
- `tests/test_wide_profile.sh` now FAILS if `FBNEO_REF` contains that
  string, so a contaminated reference can never quietly pass again.

Third member of the same family this session, after `git apply` silently
skipping (exit 0) and the MAME submodule gitlink drifting to 0.289: **the
tool reports success while the artifact is not what was asked for.** Assert
on the artifact.

## A build-fingerprint call without `--set` silently fingerprints the
## PRISTINE reference ROM (paid: 2026-08-04, 14z-59i)
`tools/build_donovan.sh` ended with
`build_fingerprint.py "$OUTBASE/rompath;$ROMDIR" --sha-only` — no `--set`,
so it defaulted to `vsavj`. That was harmless while every build packed as
`vsavj`. The moment a build packed as **`vsavjw`** (CPS-2 WIDE), the tool
found no `vsavj.zip` in the build's own rompath, **fell through to
`$ROMDIR`**, and reported the UNTOUCHED REFERENCE ROM's fingerprint as the
build's.

Symptom: `b0eb9ecd…` reported for a WIDE build — which is exactly the
`vsavj` row already sitting in `tests/expected/registry.tsv` as "vanilla
vsavj reference program image". Two different builds reported the same
fingerprint, and it was the fingerprint of neither of them. It also made a
real code change (un-stubbing the sfx helper) look like it produced
identical output.

Rules:
- A rompath is a SEARCH PATH. Anything that resolves a set by name through
  one can silently answer from the reference directory. Always name the
  set you actually built.
- If a fingerprint ever equals a known reference row, treat that as a bug
  until proven otherwise — a patched build cannot hash to the pristine ROM.

## `_PRG_RE` did not match the WIDE extension members, so extension content
## was invisible to the build fingerprint
`\.(0[3-9]|10)[a-z]?$` matches the stock program chips but not `vsw.41-.44`.
Two WIDE builds differing ONLY in extension content therefore hashed
identically — the same blind spot 14z-54 found for gfx/QSound members, in a
new region. Widened to `\.(0[3-9]|10|4[1-4])[a-z]?$`; `int("41")` sorts
after `int("10")`, which is the load order. Verified the alternation does
not accidentally catch gfx/QSound names (`.11m`, `.14m`, `.21m`, `.31m` all
still excluded).

## The sfx helper and the record array must be impossible to enable separately
Un-stubbing the per-node sfx helper (vs2 `0x5122` -> vsavj `0x4CE2`) while
slot 0x0F's pointer row still resolves to JEDAH's array means reading PAST
that array (~40 entries) with indices up to 43 — enqueuing whatever follows,
including the vsavj `0x700-0x7FF` MUSIC range. That is the original
214P/214K "music instead of sfx" bug.

So the un-stub is driven by the `unstub` field of the SAME `[[sound_table]]`
manifest row that places the array, NOT by a hand-edited reconciliation
status and NOT by a profile name. If the array is not placed, the helper
stays stubbed by construction, and no ordering of edits can produce a live
helper with no array.

## "Unknown system: vsavjw" is an EMULATOR problem, not a ROM problem —
## and renaming the zip to force it is actively harmful
`vsavjw` is a DRIVER compiled into the patched FBNeo/MAME. Stock MAME (and
Homebrew MAME in particular) will never know it, and reports "unknown
system" — which reads like a bad dump and is not one. A filename cannot
create a driver.

**Do not rename `vsavjw.zip` to `vsavj.zip`.** Stock MAME then loads it
under the STOCK descriptor: 4MB program region, eight members, `vsw.41-44`
absent from the descriptor and therefore ignored. But the code in a WIDE
build has the per-node sfx helper LIVE, with slot 0x0F's sound pointer row
aimed at `$400010` — which on a 4MB map is not ROM at all, it is the CPS2
output register window (CpsFrg). Donovan's dispatcher would read hardware
registers as sound records: garbage ids, potentially inside the
`0x700-0x7FF` MUSIC range. It boots, it looks plausible, and it is exactly
the round-2 music bug the id allowlist exists to prevent.

Use `tools/run_wide.sh <build_dir> [fbneo|mame]`, which asserts all three
things that must agree (patched binary carries the profile, set name
`vsavjw`, rompath fronting the build) and says which one is wrong.

Related: `grep -q "CPS-2 WIDE v1" <binary>` is NOT a reliable way to ask
whether a binary carries the profile — it gave a false negative on FBNeo
here. Use `strings -a | grep`, or ask the emulator (`-listfull vsavjw` for
MAME).

## A worktree branched from a STALE `origin/main` silently changes the
## instrument (paid: 2026-08-04, 14z-60)
`EnterWorktree` (and `git worktree add` with a `fresh` base ref) branches
from **`origin/<default-branch>`**, not from local `main`. On this machine
origin trails local main by ~18 sessions, so a worktree created to do new
work came up on 14z-41-era code: `run_mame.sh` WITHOUT the 14z-59
input-provider isolation, `tests/` missing ten gates, `tools/` predating
several fixes. Half a session of measurement ran on it before a missing
test file gave it away — nothing in the worktree announces which commit it
is based on.

This is the drifting-reference trap (14z-55, the FBNeo `WIDE=0` reference;
14z-58, the MAME gitlink at 0.289) in a new costume: **the tool reported
success while the instrument was not the one being claimed.** The results
survived re-measurement here — byte-identical decrypted images, identical
walk — but that was luck, not method.

Rules:
- After creating a worktree, `git log --oneline -1` and compare against the
  branch you meant to base on. `git reset --hard main` fixes it in place.
- Any measurement that will be QUOTED must record which commit the tooling
  came from, the same way analysis scripts print the SHA-1 of the ROM they
  read.

## capstone m68k mnemonics carry a SIZE SUFFIX — equality tests match
## nothing and report a confident null (paid: 2026-08-04, 14z-60)
`i.mnemonic` is `andi.w`, `move.b`, `add.w` — never bare `andi`/`move`. A
classifier written as `if i.mnemonic in ("andi", "and")` therefore matches
**zero** instructions, and the first run of `tools/audit_id_space.py`
reported "269 read sites, 0 masks — no site narrows the character id",
which is both wrong and exactly the answer the author was hoping for.

Same family as the sound-ring tap that reported "nobody ever plays a
sound" (access width) and the OBJ census that counted stale entries past
the terminator: **a measurement returning a clean null is a bug report
about the measurement until proven otherwise.** Compare on the stem
(`mnemonic.split(".")[0]`), and sanity-check any classifier against one
site you have already read by hand.

## A register-dataflow walk CANNOT see a mask applied straight to a memory
## field — two folding sites hid behind that for a whole session
(paid: 2026-08-04, 14z-60)
`tools/audit_id_space.py` censused every site that narrows the character id
by tracking the register each read went into. Two independent walker
strategies (stop-at-branch, and follow-through-branches-until-redefined)
agreed on five sites, which read as strong corroboration. It was not: the
id-cycling selector masks the field IN PLACE —

    010E28  addq.b  #$1, $382(a4)
    010E2C  andi.b  #$0f,$382(a4)      <- no destination register

— so there is no register to track and neither walker could ever have seen
it. Found only by disassembling the selector by hand while chasing a
different question. Two agreeing measurements are only as good as their
SHARED assumption; here both assumed the value passes through a register.

Rules: when censusing "who narrows/reads value X", enumerate the ADDRESSING
MODES that can touch X (register-destination reads, read-modify-write on
memory, and — still open here — the value being copied into another field
and narrowed there), not just the one the first example used. And treat a
"two methods agree" result as weak when both methods share a premise.

Bonus verdict bug from the same pass: classifying "folds the variant half"
as `imm < 0x10` miscounted vsav2's `andi.b #$01,$382(a4)`, which is a
2-value toggle over ids 0/1 on a second cycling path, not a fold. A mask
folds the variant half only if it keeps the low nibble whole and clears bit
4 — i.e. exactly `#$0f`.

## A slot id baked into hand-authored MACHINE CODE is invisible to a
## source-level audit — and fails silently, not loudly
(paid: 2026-08-05, 14z-60w, while preparing the tenant move)
Auditing "what still assumes slot 0x0F" by grepping `tools/` for `0x0f` and
`jedah` found 19 executable assumptions and felt thorough. It missed the
worst class entirely: **`build/manifest/donovan.toml` carries `thunk_hex`
blobs of hand-authored 68k**, two of which embed the character id as a raw
byte —

    0c39 000f 00ff8782      cmpi.b #$0F,$FF8782
    0c39 000f 00ff8b82      cmpi.b #$0F,$FF8B82

The grep could not see it: the literal is `000f` inside a hex string, not
`0x0f`, and it lives in a DATA file, not in `tools/`.

**Why it matters more than an ordinary stale constant.** These thunks gate
"use the ported tables or the vanilla ones" on the char id. Move the tenant
to 0x13 and leave the byte at 0x0F, and the tenant takes the VANILLA path
while whoever now occupies 0x0F takes the PORTED one. Nothing crashes,
nothing is out of bounds, and both characters render plausible-but-wrong
content — the failure mode this project keeps paying for.

Fixes now in place:
- `TT` in a `thunk_hex` is substituted with the tenant id, so it tracks.
- A LITERAL id compared against `$FF8782`/`$FF8B82` that does not match the
  tenant FAILS the build, naming the hex offset. Deliberately a failure and
  not an automatic rewrite: silently editing authored machine code could
  mask a thunk that compares against another character on purpose.

Rules that generalise:
- **Audit the manifests, not just the code.** Authored machine code lives in
  data files here, and `patch_prg.py` `code`/`data` ops mean any hex string
  may be executable.
- **Grep for the ENCODED form as well as the source form** when hunting a
  constant: `0x0f`, `000f`, `#$0f`, and `15` are all the same slot.
- The control that caught it was cheap: change the tenant id, regenerate,
  and grep the emitted patch for the old byte. Do that for any constant a
  move is supposed to carry.

## Renaming the project directory silently invalidates a worktree session
(paid: 2026-08-05, 14z-60x — cost one turn of uncommitted work)
The repo moved from `.../Vampire Saved/...` to `.../Vampire_Saved/...`
(removing the space — sensible, since MAME's GENie cannot handle one). The
rename is harmless to git: `main` and every branch survived intact. But an
in-flight worktree session was pinned to the OLD absolute path, so the next
command reported the working directory "deleted", and the uncommitted edits
in that worktree were unreachable through the session's own tooling.

What actually happened, in order: `.claude/worktrees/` vanished with the old
path; `git worktree list` still advertised the stale entry as `locked`; and
the session's isolation guard refused every git command aimed anywhere else,
so the state could not even be INSPECTED from inside the session.

Recovery: `ExitWorktree` (keep) -> `git worktree prune` from the renamed
checkout -> `EnterWorktree` afresh. Nothing committed was lost; only the
current turn's edits, which had to be redone from context.

Rules:
- **Commit before anything that moves the tree**, including a rename you did
  not initiate. An uncommitted edit in a worktree is one `mv` from gone.
- After a path change, `git worktree prune` — a stale locked entry survives
  the directory it names.
- A fresh worktree branches from `origin/<default>`, which here trails local
  `main` badly; `git reset --hard main` immediately after creating it (see
  the stale-origin entry above — this is the second time it applied).
- **Every generated rompath overlay is a directory of ABSOLUTE symlinks into
  `$ROMDIR`, and the rename dangled all of them** (found 14z-61). The
  failure does not look like "file not found": `run_replay_fbneo.sh` copies
  the overlay's links OVER the good reference ones, so a whole romset goes
  unreadable and the gate reports the emulator behaving wrongly. It cost a
  false FAIL of the B4 canary section. Regenerate any overlay built before
  the move (`tools/build_wide_romset.py "$ROMDIR" <dir> ...`) and suspect
  this first when a set that used to load stops loading.

## "Inside the placed band window" is NOT "overwritten" (14z-62)

`remap_spec.json`'s `placed` is a `[min, max]` BOUND of the tenant's tile
placement, and the placement inside it is SPARSE (per-record tiles from the
OBJ walk, not a wholesale block copy). Intersecting a record's tiles with
the WINDOW says "may be clobbered", not "is clobbered" — Jedah's name
banner (8/8 tiles inside the window) renders perfectly on the 0x13 build
because its tiles fall in placement gaps, while his portrait (89/92
inside) garbles. Concluding from the window alone gets both wrong.

Rule: to decide whether art survives a placement, intersect with the
ACTUAL placed tile set (expand the placement pairs/records), or measure
the pixels (`test_wide_render_content.sh`-style). The window is a bound,
useful only for a fast "cannot be affected" exoneration when the
intersection is EMPTY.

## Dotted TOML table names parse DIFFERENTLY per host (14z-62c)

`_minitoml` delegates to `tomllib` when the host python has it (>= 3.11)
and falls back to a subset parser otherwise. The subset parser treats
`[[data_port.fix]]` as a TOP-LEVEL array literally named "data_port.fix"
— it never attaches to the data_port row — while tomllib nests it
properly. Consequence: the 14z-2 mirror-victim fix row NEVER APPLIED on
this machine (every build, both frozen references), and a python-3.11
host building the same tree would have produced DIFFERENT bytes. A
manifest feature that resolves per host makes fingerprints
host-dependent, which no gate can catch on a single machine.

Rules:
- Dotted table names are BANNED in build manifests; the generator
  hard-fails on any orphan dotted key (both host shapes).
- Nested structure in a minitoml manifest must be encoded FLAT (the
  `fixes = "off:old:new,..."` shape).

## "The substitution landed for free" — invisible slot dependencies (14z-62c)

The slot-0x0F port never poked the engine's OBJ bank-word table
(`PRG:0x282D4`, PC-relative, unmasked id) because Jedah's row was ALREADY
`0x4000` — the very band the port placed Donovan's tiles in. Nothing
recorded that the row mattered, no gate exercised it, and the first
`0x13` match drew grey blocks: Donovan's remapped codes composed with
row 0x13's Victor alias (`0x2000`, the wrong band). Found only by the
measure-diff loop (snapshot -> OBJ dump -> write tap at `$FF8418` ->
writer PC `0x282C0` -> hand-decode).

Rule: when content substitutes a slot IN PLACE, every per-slot value the
host already had RIGHT is an invisible dependency. Moving the tenant off
the slot converts each one into a defect. The de-substitution acceptance
(pick the host, require the bounded re-convergent window — gate section
4) is the behavioral net for the class; the RAM-diff-at-frame method
names each culprit's subsystem in one measurement.

## Descriptor CRCs for variable-content members: use SENTINELS (14z-62d)

Group C carries per-build content, so its descriptor CRC can never match.
Two wrong answers were paid for before the right one:
- **A real member's CRC** (the pristine group-B copies): resolves BY HASH
  onto any pristine parent in the path — the 14z-60z shadow.
- **The fill member's CRC** (4MB zeros = 0x1147406a): collides with the
  ZERO QSOUND MEMBERS in the same zip — vsw.31m resolved by hash to
  vsw.21m and group C loaded silent zeros. Measured: the whole B4 canary
  section failed at once; sections 1-2 stayed green because zero==zero.
Any CRC that ANYTHING in the search path carries is a latent shadow. The
answer is a SENTINEL that matches nothing (0xdec0de31/33/35/37 + sha1s of
sentinel strings), so the member ALWAYS resolves by NAME — the loaders'
name-fallback demonstrably loads CRC-mismatched members on both emulators
(every patched vm3 member ships that way). -verifyroms reports them bad;
that is the cost, and it is honest.

## Stale build-output members get re-packed (14z-62h, maintainer-caught)

`build_gfx_donovan` writes only the members the current MODE produces, but
`build_donovan.sh` packs by GLOBBING the output dir — so when group-C mode
stopped writing group-B members, the group-B files from the PREVIOUS build
stayed in `build/<out>/gfx/` and were re-packed into vsav.zip every build.
Jedah drew Donovan's band. Caught only by the maintainer's FBNeo playtest.
Fix: the build cleans `gfx/vm3.*m vsw.*m` before generating, and group-C
mode ASSERTS group B pristine in the packed zip. Rule: an output dir that
different modes populate differently must be cleaned per build — "the file
exists" says nothing about WHICH build wrote it (the pipefail lesson's
sibling).

## A hook on a hot shared path can flip a frame-boundary parity
## PERMANENTLY — flicker's evil twin (14z-64)

The mid-row retarget thunk was placed on the uploader dest computation
at 0x2AD44 — which turned out to be the funnel for EVERY in-match
accent upload (all four accent-site entries bra into it). Its ~60
cycles per upload did not add a flicker; it shifted the phase of a
same-frame multi-writer field ($FF8094: three PCs write it every
frame, the end-of-frame sample sees the last) across a frame boundary
PERMANENTLY — replay 04 diverged from f2009 to EOF, replay 05 from
f9126, both as a single stuck byte. The old build showed a one-frame
flicker at exactly 2009: the boundary was ALREADY marginal; the added
cycles locked it to the other side.
Rules:
- Before thunking a site, know its CALLER SET across all screens (the
  bra/bsr census) — a site that looks venue-specific can be the hot
  funnel for everything.
- Cycle-cost review must look at LATE-REPLAY TAILS (identical_tail per
  replay), not just the known divergence windows: a permanent parity
  flip hides where nobody samples.
- A one-frame flicker in the frozen inventory marks a MARGINAL
  boundary; treat its frame as a tripwire when adding cycles anywhere.

## Two generator sections silently owned one table row — last-write-wins
## decided the shipped bytes (14z-65)

`patch_prg.py` applied ops in order with NO overlap detection. The 14z-65
audit of the frozen donovan-m3a patch found exactly one collision: the
generic value-row repoint wrote `tail_data_ptr[0x13]` (PRG:0x0BF466) as a
pointer into the relocated hitbox closure — vs2's RAW sfx records with
music-range ids, relocated whole — and the measured `[[sound_table]]` port
then wrote the same row with the id-allowlisted array. The build was
CORRECT only because the sound op was emitted later. Any refactor that
reordered emission would have aimed the sfx walker at unfiltered vs2
records (the exact class test_don_sound.sh exists for), with every gate
green until the sound gate ran.
Rules:
- Ops must have exactly one writer per word: `patch_prg.py` now hard-fails
  on overlap, naming both ops (`tests/test_patch_overlap.sh`).
- A manifest section that pokes a table row ITSELF must suppress the
  generic repoint for that table (explicit ownership — the sound_table
  claim in the generator), not rely on being emitted later.
- Overlap granularity is the WORD, deliberately: odd-aligned byte pokes
  merge PRISTINE neighbor bytes into their word, so a second op sharing
  the word resurrects vanilla bytes over the first op's write.
- A bank_map region tag is session-4 TRIAGE, not a consumer decode:
  `tail_data_ptr`'s `region = "hitbox"` was a guess that happened to
  cover vs2's row value; the 14z-52 measurement (per-node sfx path)
  is the real consumer. When a measured section contradicts a triage
  tag, the measured section owns the row.

## A single-shift sibling scan dies at the newcomer window's hidden
## structure — and junk filler decodes as pointers (14z-65)

The vs2→vh2 shift over the appended newcomer code window is PIECEWISE
(+0x36/+0x30/+0x34), routines are separated by junk filler differing in
content AND length between the builds, and vs2 carries at least one
6-byte insertion with no vh2 twin (Huitzil's handler-head `jsr $8ACD8`).
Consequences that cost time:
- `oracle_extend` with one shift stops at the first stretch boundary or
  filler run — looking exactly like "misbounded region" when the region
  is fine. Group dispatch targets by their OWN pair delta first (free
  ground truth); only then scan.
- Filler junk decodes as plausible pointer fields (bare-long masquerade
  again) — never classify refs inside a tolerated filler run.
- A lax "does this alignment explain the chunk" probe ACCEPTS wrong
  alignments: allow_engine's envelope plus pcrel16 tolerance can explain
  ~everything in a 0x40 window to within 2 bytes. A boundary probe must
  also require the instruction-start opcode word to MATCH (measured: the
  lax probe placed Huitzil's boundary 6 bytes early, swallowing the
  insertion into the wrong region).
Full mechanism + frozen shapes: docs/game/atlas/character_tables.md "The
appended window's sibling shift is PIECEWISE".

## The vanilla-alias assumption fails where per-char rows hide in engine
## space — and a window constant is a census, not a fact (14z-65)

Two traps from the Huitzil specials hunt, both silent-by-nature:
- NEWCOMER_CODE (0x057000+) was Donovan-era triage. Huitzil's handler
  zone starts at 0x054C9C — with the narrow window, 13 of his dispatch
  rows classified as "veteran rows" (engine_dispatch), were never
  repointed, and vanilla's row-0x10 aliases served BULLETA's handlers
  for his special-move dispatches: no crash, no divergence, just moves
  that never come out. A window constant must be re-derived per tenant.
- dispatch_07 is PER-CHARACTER even though every row targets engine
  space (Bulleta 0x2D68E, Demitri 0x30B9A, Huitzil 0x23AFE): "target is
  in shared engine code" does NOT imply "the alias row is correct". The
  generator now compares the SOURCE game's row against its alias-char
  row and repoints through the R1 map when they differ (Donovan-inert,
  measured).
Verification style that found both: parity instruments, not reading —
the same probe on native vs2 and the port (predicate consultations
matched 401=401 exactly; the state-byte tap showed native writing
states the port never writes).

## An odd-offset "engine ref" ate a jsr opcode — and a pool-head latch
## re-seeds live pools at round 2 (14z-65)

- The sibling-diff classifier accepted a 32-bit engine-ref window at an
  ODD offset spanning an instruction boundary (bmi operand + jsr
  OPCODE); the rewrite replaced the jsr with a move.w and Huitzil's anim
  stepper was simply never called — cursor frozen at its first byte,
  intro never completed, the whole state layer silent. CODE-region ref
  fields are word-aligned by ISA; the classifier now enforces even
  offsets under allow_engine (Donovan: zero odd refs, measured inert).
  Symptom signature for the future: a blob byte sequence that decodes as
  HALF an instruction plus an address = a ref wrote over code.
- The [init_shim]'s idempotence latch is the pool-0 FREE-LIST HEAD —
  "zero means never seeded". False mid-match: a character whose
  ecosystem drains pool 0 makes the round-2 char re-init re-run the
  seeder over LIVE pools (measured f4890: every pool re-walked, queued
  objects orphaned, a freed slot dispatched into palette space 93
  frames later). Latent for ANY shim user in a long enough match. A
  robust latch must be phase-gated or a dedicated one-shot byte — and
  manifest-opt-in, because Donovan's frozen build carries the old shim
  bytes.

## Three lessons from the day Huitzil came alive (14z-65)

- A SET-NAME MISMATCH IS A FALSE GREEN, silently: when a build's first
  wide_ext allocation flips the pack to vsavjw, every probe still run
  with SET=vsavj falls back to the PRISTINE ROM in $ROMDIR — boots,
  plays, soaks "clean", and tests nothing (an 11,000-frame attract-mode
  "soak" passed this way). Every H gate now derives the set from the
  rompath contents. Corollary: a "suspiciously clean" result after a
  build-shape change is a prompt to verify WHAT ROM actually ran
  (the loaded hitbox base names the character; the snapshot names the
  screen).
- RAW KEYON-LIST EQUALITY IS NOT THE M5 VERIFY: it flagged id 0x2D4 as
  "different" when the Donovan arc PROVED it identical (same bank/start
  after relocation). A blanket keyon!=equal sweep condemned 127 shared
  sfx before the contradiction surfaced. The 0x7xx newcomer-voice range
  is the only stub-on-sight class; shared ids go through the batch
  resolver / the real M5 method.
- THE SHARED R1 MAP IS FROZEN FOR THE REFERENCE TENANT: his build
  consumes OPEN rows as tripwires, so resolving any row his extraction
  references CHANGES HIS BYTES (m3a reproducibility caught it). New
  tenants' rows live in a per-tenant recon_overlay
  (build/manifest/reconciliation_huitzil.toml; manifest key
  recon_overlay) until the Phase 2 merge scopes rows properly.

## PC-relative escapes in engine-style regions are INVISIBLE to the
## sibling oracle — and unrewritable in place
A cloned engine region's bra/bsr/Bcc.w branches out of the region keep
their displacements through extraction: both sibling games preserve
spacing, so the displacement bytes diff CLEAN and no ref is flagged.
Placed, they branch into unrelated bytes — sometimes crashing
(air-dash: mid-instruction vec4), sometimes wandering BENIGNLY for
sessions (x026142 carried them from 14z-65; the Circuit Scrapper's
"does not come out" was one). No Bcc abs.l exists, so in-place rewrite
is impossible — [[pcrel_escape_fix]] reserves an ADJACENT trampoline
pad and rewrites each escape to a `jmp <twin>.l` bounce. Run its
census on EVERY engine-style region (clones, shared zones); newcomer
authored code is mostly immune (it calls engine subs via jsr abs.l).

## 2P forced-pick pokes must end by ~frame 1500 — later pokes leak
## into the SECOND player's load
Holding the P1 commit poke ($FF8782) through frames 1700-2400 works in
the 1P flow but in the 2P flow turns P2 into the poked id (measured:
a "victim sweep" where every P2 loaded as 0x10 — crash signatures that
looked per-victim were per-garbage). Early window 1400-1500 only; a
no-poke control run verifies the flow (p2_id stays vanilla).

## Physics ports move probe windows — retune frame-pinned gates
The jump_params port changed the float rise speed; the air gate's
hover samples (tuned to the alias-physics climb reaching 109.4 by
~f3320) then caught the native-speed rise MID-CLIMB and reported "no
hover" while the hover was perfect at 121.1 from f3345. When a gate
pins absolute frames around a physics-dependent event, re-derive the
frames after any physics change — or anchor on the event, not the
clock.

## Forced-pick pokes do NOT populate the HUD index field — HUD
## verification needs a REAL wheel pick (14z-67)

The forced-pick rig (poking the commit field $FF8782) loads the tenant
fine, but the in-match HUD stagers index their 32-row tables through a
SEPARATE field the real pick flow writes and the poke path does not.
Measured: a forced-pick H match staged mugshot row 0x01/0x11 (the
alias) while a REAL cursor pick of cell 0x10 (replay 37) staged his
poked row 0x10 (code be9a) exactly. Symptom pattern: the table pokes
and art are verifiably correct in the built image, yet the staged
codes read an alias row. Instrument, not mechanism — verify HUD rows
with the real-pick replays (36 = cell 0x13, 37 = cell 0x10), never
with the poke rig.

## A gate that is not in the battery can sit FAILING for sessions —
## sweep gates when a design changes (14z-67, paid twice in one day)

Two gates were discovered stale-red in the 14z-67 sweep, both outside
`run_battery_m2.sh`/`run_suite.sh`:
- `test_gfx_tiles.sh`'s Jedah inventory lock (17763) had been failing
  since 14z-11 added the walker's sweep pass (818bae7 moved the number
  to 18094; the commit updated no lock). Attributed by running 818bae7^
  — it reproduces 17763 exactly — then re-frozen.
- `test_wide_render_content.sh` had been failing since the 14z-64 m3a
  freeze: the de-substitution moved Donovan's band to bank 4 (0x4AD8F)
  and restored Jedah in group B, so the gate's cross-track pixel A/B
  (replay 11 renders JEDAH on WIDE now) and its stock-bank band dump
  were both wrong BY DESIGN. Re-shaped to m3a semantics (band
  equivalence incl. the de-substitution invariant as an assertion).
The class: a design change invalidates a gate nobody runs, and the red
gate then reads as "regression" to whoever finally runs it. When a
freeze changes design semantics, grep tests/ for every gate touching
the changed surface and run them BEFORE closing the session.

## A tenant porting SHARED regions inherits every region-scoped
## mechanism row those regions carry — copy them ALL, up front (14z-67)

Pyron's first mash soak crashed three ways, and every fix was a row H
already carried for the same shared zones: the x088512 pod-table
data_in_code reroute (the class's FOURTH bite), the queue class-7
remap, both obj_hook union sites, the x026142/x05c800 escape pads +
twin rows, and the satellite handler family roots (types 64-75 —
"H's farm zones" turned out to be the SHARED newcomer-satellite
handlers, proven when P's first spawn tripped type 64's tripwire).
The rows are properties of the SHARED SOURCE BYTES, not of the tenant.
When a new tenant's roots pull in a shared region, diff the other
tenants' manifests for every row scoped to that region and copy them
BEFORE the first probe run — the crashes are pre-paid knowledge, not
new information. (The Phase-2 merge dedups these by span; until then
the duplication is the mechanism.)

## Per-char dispatch on a COMMON seq state needs the target flow's
## FULL closure first; and "cold" sites can be legacy-hot (14z-67)

Two paid lessons from the effect-entry arc:
1. vs2's seq-D head per-char-dispatches EVERY FRAME for EVERY fighter
   (seq D = a common state, 401 probe hits before the cap). Gating it
   to a ported handler whose deep flow has ANY unmet dependency fails
   SILENTLY — no crash, no tripwire; the state machine just routes
   away and the character's moves stop firing (measured: the ray
   vanished entirely). Scratch-enable such dispatches and close the
   flow's dependencies BEFORE shipping the gate.
2. A site that is cold for TENANT content can be hot for LEGACY
   content (the effect-machine stub served vanilla casts' effects) —
   an owner-gated thunk there costs legacy cycles and breaks
   masked-EXACT legs. Run tests/test_hui_boot.sh after ANY
   site_thunk addition. Corollary: VERIFY a park/comment edit
   actually changed the file (a silently-missed replace left the
   thunk live and burned a bisect round on a false premise).

## Twin-site identification by BYTE PATTERN alone can land on the
## wrong subsystem — derive the pair through the DISPATCH TABLE
## (14z-68, refutes half of the 14z-67 entry theory)

The parked seq_d_dispatch thunk paired vsavj 0x22500 with vs2 0x22008
because the surrounding bytes pattern-matched. Measurement (FBNeo tap
on replay 83b, ours vs native): vsavj 0x22500 is a timer-decrement
run inside the EVERY-FRAME fighter tick; the true twin of vs2 0x22008
is vsavj 0x23500 — reachable in one step by decoding both engines'
per-seq jump tables (vsavj 0x225EE / vs2 0x20FD2, dispatchers
0x225C2 / 0x20FA8), which are row-for-row parallel. The cost of the
wrong pair: the ported handler's unconditional head-clears ran every
frame and silently killed every move, which was then mis-attributed
to "silent dependency gaps" in the handler's deep flow. When pairing
engine sites across the games, FIND THE CONSUMER (the jump table or
dispatch that reaches the site) and pair through its row index —
byte-pattern similarity between two steppers is not identity.
Corollary that closed the arc: before porting ANY per-char handler
entry, check whether the target table's row 0x10 is ALREADY
repointed on the built image — the 12b/13 dispatch_1x bank_map rows
had silently solved the whole fighter-side entry problem, and the
"missing dispatch" being chased did not exist.

## An "owner-gated" thunk on a shared engine routine is NOT scoped by
## owner alone — sibling effect families share subtypes (14z-68)

The fleet_record_base thunk gated on "tenant context + the ray's
subtype 0x0D" and still crashed the ES flow: the ES big-beam driver
is ALSO subtype 0x0D (it is the ray's sibling), so it matched the
gate, and its parameter STREAM — advanced by the caller through
`lea (d16,pc),a3` — carries record OFFSETS valid only for the
VANILLA base. Half-swapping (new base, old stream) produced odd
offsets and an insane dbra count: vec3 inside the channel fill.
Two rules from this: (1) base, stream, count and updater are ONE
unit — swap them together (i.e. port the region) or not at all;
(2) when gating a shared routine, enumerate every family of the
tenant's OWN content that reaches the site, not just every
character — "only my tenant gets here" is a weaker claim than it
sounds, and the crash appears in an unrelated move.

## Verify a fix at the RENDER layer before believing the RAM layer
## (14z-68, the beam that never was)

Two successive thunks measured perfectly at the RAM/tap layer — the
piece got the right bank word and a record at exactly native's own
relative offset — and changed the screen not at all: every iteration
was PIXEL-IDENTICAL to the unfixed build. The OBJ dump then showed
why in one measurement: native stages beam sprites (bank-3 codes
0x1E2F/0x1E42/0x1E5F pal 0x0C, plus bank-1 stretch segments 0x4EC0
at 4x1 and 16x1) and ours stages ZERO — the pieces are never
created, so first-tick constants were downstream of a spawn that
does not happen. Correct-looking writes on the ONE object you are
watching say nothing about the objects that were never spawned.
`tests/lua/obj_records_dump.lua` + `snapshot_frames.lua` (both
POKES-capable since 14z-68) answer "is it actually on screen?"
in a single run — reach for them BEFORE the third RAM-layer
iteration, not after.

## A ported region must contain the CONSTANTS its own code loads —
## check the boundary against the routine's literals (14z-68)

The vs2 companion-spawner region was rooted at 0x6D240, and the
routine's own record base load `movea.l #$2B7EF4,a2` sits at
**0x6D200** — 0x40 bytes below the boundary. The region therefore
placed and relocated cleanly, passed every gate, and could never
relocate the base its code depends on; the ported code ran against
a base literal that was still outside it. Symptom: ported content
silently chained to VANILLA records and drew vanilla (or no) art,
with nothing red anywhere. When rooting a region, disassemble
BACKWARD from the first instruction and check for `movea.l #imm` /
`lea` literals belonging to the same routine that fall below the
start; a boundary that splits a routine from its own constants is
invisible to every existing gate. Extending the root to 0x6D1E0
(twin delta +0x174 re-verified at the NEW start — do not assume the
delta carries) made the base relocate to the placed copy, with
static proof: exactly one occurrence of the placed base in the
region blob.

## Routing a tenant's objects to a ported machine: the discriminator
## must be PER-EFFECT, not per-hit (14z-68)

Giving the tenant's effect object its own union type (so a SHARED
type's rewritten machine can be reached without touching the shared
row) works — dispatch, records and sub-records all became
native-equivalent, verified by normalising the ticking PCs and by
byte-comparing the records. But the stamp was applied at the
victim-spawn site, which serves EVERY hit of that class from the
tenant, so Dark Force's objects were routed into the ported machine
too and it underflowed the placed region (vec3, A1 reading below the
region base). The tenant is not a fine enough filter for a site that
one character reaches through several different moves: pick the
discriminator at the granularity of the EFFECT, not the character.
Corollary for gating: `test_hui_pairs` (Reflect Wall + Dark Force)
is the gate that catches this class — run it on any change that
routes objects, not just the gates for the move you are fixing.

## A ported region's pc-relative DATA POINTERS are copied VERBATIM —
## if the table is outside the region, the pointer lands on garbage
## (14z-69; this is the real root of the parked effect family)

`lea (d16,pc),An` forms a data pointer. Nothing in the toolchain
rewrites it: census 1 skipped it (its target is not inside a code
region), census 2 only scans branch opcodes, and `extract_char.py`'s
`pcrel_refs` sweep only collects `jsr/jmp (d16,PC)` and
`jsr/jmp (d8,PC,Xn)`. `gen_donovan_patch.py`'s far-pcrel trampoline
covers CODE targets only and even says so: *"a far pcrel DATA read
would need its data copied near instead (no such case yet)"*. There
was such a case; it just could not be seen.

Because the displacement is copied verbatim, a relocated region
resolves the pointer to `target + region_delta` — correct ONLY if those
bytes travelled with the region. Measured on build/hui11, region
`x06cac0` (vs2's row-8 machine): **7 of 7 pointers resolve into
unrelated bytes**, e.g. `lea $6D868(pc),a3` -> `0x0D4C98`, where the
image holds code (`74354cc1...`) instead of the fleet param stream
(`0001005800000000...`). So the ported machine walks garbage — which is
exactly the symptom the effect family has been parked on since 14z-68.

**The proximate cause is the region ending before its tables** —
`x06cac0` is `len 0xc00` (ends 0x6D6C0) while the tables live at
0x6D768-0x6D96C. **CORRECTION (same session): the declared root
`0x6cac0:0xebc` is NOT being ignored — in `extract_char.py` a root's
`fixed_len` is a CAP, not a length:**

    cap  = fixed_len if fixed_len else 0x4000
    xlen = oracle_extend(...)        # stops where the sibling stops agreeing
    if fixed_len: xlen = min(xlen, fixed_len)

The sibling oracle stopped at 0xC00, so that is where the region ends —
by design, since the extractor only takes bytes a twin can validate, and
param tables legitimately differ between vs2 and vh2.

So the fix is to make the region CONTAIN its tables, which is the same
principle as "a ported region must contain the CONSTANTS its own code
loads" (14z-68) generalised from literals to tables. Adding the table
block as a SEPARATE root does not work: a pc-rel data pointer is only
correct if the target keeps its relative distance, i.e. the bytes are
inside the region or placed at the identical delta. Use the `:f`
force-length modifier (14z-69) to take the declared length past the
oracle boundary, and check what you are forcing in: bytes beyond the
boundary are unvalidated and their POINTER fields are not classified,
so this is safe for 16-bit param tables and NOT safe for anything
holding ROM pointers.

Instruments (added 14z-69):
- `census_regions.py` census 3 REPORTS every such pointer;
- `tools/verify_pcrel_data.py` DECIDES, by resolving each one in a
  built image and comparing the bytes against the source table.
  Compare DATA views — inside the crypt range the two views differ
  completely.

## The data_in_code detector misses the POST-INCREMENT reader shape;
## and RAW placement does not fix an embedded data table (14z-68;
## post-increment detection ADDED 14z-69)

Two related traps, paid together on vs2's row-8 machine:
1. `tools/census_regions.py` matches data_in_code only as
   `lea (d16,pc),An` + a read of the form `(An,Xn.w)`. vs2's fleet
   param stream is read as `lea $6D868(pc),a3` + `move.w (a3)+` — a
   POST-INCREMENT walk — so the census reports the region clean while
   it carries a live embedded table. The generator's relocator has
   the same blind spot (its only supported reader is
   `lea (d16,pc),a1 + move.b (a1,d0.w),d0`). Add the shape to BOTH,
   with a frozen case in tests/test_census_regions.sh.
   **DONE for the census (14z-69):** `scan_postinc_reader` walks
   forward from the lea to the end of the region and stops only if An
   is redefined, because the ground-truth reader sits 0x3E bytes away
   inside a bsr subroutine — an "immediately after" rule can never see
   it. Verified to catch vs2 0x6D206 -> 0x6D868. The GENERATOR side is
   still open, but see the entry above: for this case the fix is to
   make the region contain its tables, not to rewrite readers.
2. Moving the region to RAW space does NOT solve an embedded data
   table. Raw storage holds ONE byte image, and for a code region
   that image is the OPCODE view (so it executes) — so runtime DATA
   reads through it still see the wrong bytes. Inside the encrypted
   range the two views differ completely (measured at vs2 0x6D868:
   opcode `b8020919f5c7…` vs data `0001005800000000…`). Only
   relocating the table as data fixes it.

## A ported region whose consumers index NEGATIVELY needs headroom
## below its base — never allocate it at the start of wide_ext (14z-68)

vs2's companion machine indexes its record table with signed offsets
that go BELOW the base pointer (measured d0 = 0xFFF3 = -13; on vs2
the base 0x2B7EF4 simply has ROM underneath). Our copy was allocated
at 0x400010 — the very first address of wide_ext — so a negative
index reached 0x400003, inside the RESERVED CpsFrg register window
(`$400000-$40000F`, which HANDOFF says never to allocate near, and
which the two emulators read DIFFERENTLY). Check a region's
consumers for signed indexing before placing it at the bottom of a
space, and leave headroom when they index negatively. (Fixing the
headroom alone is not sufficient if the index itself is wrong — a
vec3 on an ODD address is an address error, which is a much louder
signal than "wrong data" and should be read as such.)

## Re-deriving what a previous tenant already solved (14z-68m)

Huitzil's win screen was analysed from scratch and got two of three
pieces wrong — the palette landed on DONOVAN's row (shipped, and the
maintainer caught it in a side-by-side) and the portrait's left shift
was not even noticed until they pointed at it. Donovan's complete
solution — position table, palette formula, verified addresses — had
been in STATE.md since 14z-45.

The failure was not missing documentation; it was documentation that
could not be reached from the task. Session logs record what happened;
they are not where you look when starting work. Two habits:
1. Before porting a per-character subsystem for tenant B, read the
   `docs/game/engine_internals.md` section for it and DIFF tenant A's
   manifest rows against what you are about to write. If there is no
   section, write one as part of the work.
2. When a maintainer says "this looks like the thing we fixed for
   <other tenant>", treat it as a high-confidence pointer to existing
   analysis, not as a hypothesis to test independently — go read that
   fix first. It was right both times it was said.
Corollary on verification: "matches vs2" is only as good as the ROW
you compared against. The palette RAM matched vs2 exactly and all 134
portrait tiles matched vs2 exactly while the screen was still wrong,
because the comparison target itself was the wrong character's row.
Prefer a check that is self-labelling (the 5*row palette marker) over
a check that only proves internal consistency.

## A symptom grouping is a HYPOTHESIS — test it member by member, cheapest
## first (14z-71, the effect family — three sessions of not doing that)

Four Huitzil defects were grouped in 14z-69 as "the effect family (beam /
grab lightning / ES big beam / 214 explosion) — ONE root; one port covers
the family". They shared a symptom: *this effect does not draw*.

**The grouping turned out to be right for three of the four** — the beam,
the ES beam and the grab lightning all needed the dead effect-class row
16 — and wrong for the fourth (the 214 explosion was an uncopied tile
inventory). The cost was not the grouping; it was that **nobody tested
it**. The premise sat unexamined for three sessions while the expensive
member was investigated, and was then argued against twice on evidence
that turned out to be measuring a different effect entirely.

| member | actual cause |
|---|---|
| 214+P ground explosion | 569 tiles remapped bank 3->4 and never copied |
| beam + ES big beam | a stub effect-class row, then a missing sprite-list type, then a per-game code bias |
| grab lightning | **the class-16 handler port** — the SAME cause as the beam. Maintainer playtest: hui17 has no electricity, hui18 has it, and hui18 = hui17 + exactly two things (region `x093460` and the row-16 repoint `00080B44` -> `000D89B0`) |

The cost was not the wrong fix, it was the wrong SEARCH: sessions spent
hunting a single shared root, and a scope document written around one.
Two of the four were also mis-triaged along the way *because* the family
framing implied the answer must be shared.

**THE GROUPING WAS PARTLY RIGHT, AND THE CORRECTION COST MORE THAN THE
ERROR.** Three of the four DID share a cause — the beam, the ES beam and
the grab lightning all needed the dead effect-class row 16. Only the 214
explosion stood apart. So the right lesson is narrower than "grouping is
wrong": **a symptom grouping is a hypothesis that must be tested member by
member**, and testing the cheapest member first (one playtest of the grab)
would have confirmed the shared root immediately instead of leaving it an
open question for three sessions.

**How the correction went wrong, twice, and it is the more useful story.**
On closing the family the lightning's cause was written up as "nothing —
already working when someone finally looked": an INFERENCE from "nobody
checked recently", asserted as a finding, inside the very entry warning
against that. Challenged, it was then "measured" across six builds —
identical sprite records, identical tile content — and the conclusion
restated with more confidence. **That measurement was of the wrong thing**:
it filtered on palette 0x0C (assumed from the beam, never checked for the
lightning) and its rig never produced a grab at all — the captures sent
alongside it showed GRENADES, which the maintainer had to point out. The
maintainer's original claim, dismissed twice on bad evidence, was correct.

Rules that follow, all paid for here:
- **Measuring something adjacent is not measuring the thing.** Name the
  event you must observe, then prove the rig produced THAT event before
  reading any number off it.
- **Never carry a filter across effects.** Palette, bank and code ranges
  are per-effect facts; inheriting the beam's 0x0C hid the lightning.
- **Look at a capture before sending it.** Sending unexamined frames spends
  the other party's attention to discover your own error.
- A/B ACROSS BUILDS is the cheapest attribution available and it needs no
  analysis: hui17 vs hui18 settled in one playtest what six build-dumps
  got wrong.

Rules:
- A shared symptom is a hypothesis about the mechanism, not evidence for
  it. Write it down as "possibly one root", never as the family's name.
- Before adopting a grouping, ask what measurement would DISTINGUISH the
  members. If none is planned, the grouping is doing no work.
- Check the cheap member first. The grab lightning needed ONE playtest,
  and it would have CONFIRMED the shared root on day one — instead the
  premise sat untested for three sessions and was then argued against
  twice, on evidence that turned out to be measuring the wrong effect.

## Cross-build A/B is the cheapest attribution we have, and it is
## routinely skipped in favour of analysis (14z-71)

Every build from hui6 onward is kept with an intact rompath, and
`tools/run_hui_behavior.sh <build>` plays any of them. Attributing "when
did this start/stop working" is therefore one playtest per candidate
build, with no instrument to get wrong.

It settled in minutes what analysis had got wrong twice: hui17 has no grab
electricity, hui18 has it, hui18 = hui17 + the effect-class row-16 repoint
— so the lightning shares the beam's cause. Before that, a six-build
sprite-and-tile comparison had "shown" the opposite, because it filtered on
a palette inherited from a different effect and used a rig that never
produced a grab.

Rules:
- When the question is *when* did behaviour change, bisect the BUILDS
  before analysing the code. The builds are the ground truth.
- The launcher refuses to rebuild into an existing directory (14z-71): a
  pruned rompath would otherwise be silently refilled with TODAY's
  manifest, destroying exactly the evidence a bisect needs.

## When a claim changes, GREP FOR THE CLAIM — not for the files (14z-71)

Promoted to a standing order in CLAUDE.md §5; the evidence is here.

A finding propagates: section headers, summary lines, build-registry rows,
gate comments, the GOTCHAS index, NEXT_SESSION. Correcting "the places I
remember writing it" leaves the rest asserting the old thing, and headers
are what a skimmer reads.

Measured twice in one session:
- `engine_internals.md` carried **"the 214+P explosion — NOT a
  tile-inventory defect"** as a HEADER, directly above a subsection
  proving it WAS one. The subsection had been appended; the header never
  touched.
- A corrected effect-family finding survived in **five** further places —
  including a build-registry row written *after* the correction began, and
  the gotcha's own title and index line, which still stated the inverted
  lesson.

Both were found by grepping the assertion's wording across the repo, in
one pass. Neither was found by re-reading the documents.

## Cross-emulator position A/B: compare RELATIVE offset, not absolute x
## (14z-72 lost a session to this; 14z-73)

Our new-character A/B runs native `vsav2` against our `vsavjw` — two
different builds of the engine. They traverse the same states but the
match sits at a **fixed ~21px global camera/origin shift** between the two,
so any ABSOLUTE screen coordinate differs by that constant even when
nothing is wrong.

14z-72 measured the grab victim's absolute x (936 native vs 915 ours),
read the 21px as "the fighters start at different spacing", declared the
rig **not cross-leg comparable**, and proposed authoring a whole new
corner-walk replay to pin absolute position. All of that was wasted: the
victim offset RELATIVE to the attacker (`dx = p2x − p1x`) was **42 on both
legs** the whole time. 14z-73 ran the same replay 80, compared the relative
offset, and both measured AND attributed the defect in one session — no new
rig needed.

Rules:
- For any cross-emulator A/B of a POSITION, cancel absolute placement
  first: compare a difference between two objects in the same frame
  (`p2 − p1`), or an offset from a fixed landmark. `tools/check_grab_victim.py`
  is the worked example; `field_trace.lua` logs both blocks so the subtraction
  is trivial.
- A relative measure is CHEAPER and more robust than a corner rig. Reach for
  "cancel the shift" before "pin the position".
- The onset-frame agreement (both legs read the same relative value before
  the event) is a free same-instrument positive control — if it does NOT
  agree pre-event, THEN suspect the rig.

## Never chain a legacy measurement onto a build in one step (14z-74)
## — it produced a WRONG COMMIT

Running a rebuild and then the legacy check inside ONE command block gave a
false FAIL twice in a row: once on a build carrying `port_param32` (which I
then recorded as "breaks legacy" and refused) and once on a build that did
NOT carry it. The second false failure is what exposed the first, because
that same build had passed the identical check minutes earlier.

Re-measured with the build and the check as SEPARATE steps, two independent
runs on a freshly built image: clean both times, the ratified select-wheel
window and nothing more.

Rules:
- Build in one step. Measure in another. Never in the same command.
- **Re-run before believing a gate that contradicts a previous green.** Two
  contradictory results on one image is a broken instrument, not a finding.
- I committed the false claim while the contradicting output was on screen.
  If the text you are writing disagrees with the last tool output, stop.

## A dead-filler classifier that compares the OPCODE view is blind to DATA
## (14z-74, cost the air-214+P bug)

`extract_char.py` labelled 12 bytes at Pyron's `code+0x234` "1 dead filler
zone". They were his air-dive per-strength velocity table — read through the
DATA view, inside a crypt-re-encrypted region, so the port fed the move
garbage and it flew off-screen with gravity zeroed.

The classifier compares the two sibling ROMs in the OPCODE view, where an
embedded data table ALWAYS differs (different keys, different addresses), so
real data is indistinguishable from junk debris.

Cheap discriminator, which flags this run instantly: **if the two siblings'
DATA views of a candidate filler run are byte-identical, it is DATA.**
(vs2 0x0576F4 and vh2 0x057724 are both `0388fc78` x3.)

Related blind spot in the same family: `census_regions.py` bails in
`_redefines_an` on `lea (An,Xn),An` — an INDEX ADD on the destination
register, where the pointer plainly survives. That single test is why
Pyron's manifest carried a wrong "0 data_in_code" census line.

## `placements.json`'s dst/src is a LINEAR map, but the extractor
## auto-discovers SUB-REGION shifts — comparing through it fabricates
## "the ported data is corrupt" (14z-75)

Checking whether Pyron's anim nodes matched their vs2 source, I mapped ours
`0x0D45C6` through the covering region row (`dst 0x0D3560, src 0x263186`) and
got vs2 `0x2641EC`. The bytes disagreed, and the whole region measured **75%
differing**. That reads exactly like a corrupt port — the nodes had in fact
been ported faithfully.

The region row records ONE dst/src pair, but `extract_char.py` resolves
shifts *within* a region (its "auto-discovered region shifts"), so the true
correspondence drifts from the linear estimate — here by `+0xF00`.

Do this instead: **correlate.** Slide the candidate source across a window
around the linear estimate and take the offset with the most matching bytes:

    best = max(range(-0x4000, 0x4001),
               key=lambda sh: sum(ours[A-W//2+i] == vs2[est+sh-W//2+i]
                                  for i in range(W)))

At the true offset (`0x2650EC`) the two are byte-identical apart from
properly relocated pointers — 889/1024 matching bytes, and every mismatch a
pointer field. A structural match that is ~85% bytes with all differences in
pointer positions is what "correctly ported" looks like; do not read a
sub-90% figure as corruption until the alignment has been *found* rather
than assumed.

## "Entry N" past the end of a jump table is the NEXT routine's OPERAND
## (14z-75, cost a shipped legacy regression and a blocked freeze)

14z-74 fixed Pyron's Cosmo Disruption crash by repointing "entry 81 of the
sub-state jump table at 0x018468" from 0x0006 to 0x0224. That table has
EIGHTY entries. It ends at 0x018508, where the next dispatcher starts:

    018460  323b 0006   move.w (6,PC,Dn.w),D1     <- dispatcher #1
    018464  4efb 1002   jmp    (2,PC,D1.w)        ;  table base 0x018468
    018468  ... 80 entries (0..79) ...
    018508  323b 0006   move.w (6,PC,D3.w),D1     <- dispatcher #2
    01850A              ^^^^ ITS DISPLACEMENT      <- what we wrote
    01850C  4efb 1002   jmp    (2,PC,D1.w)        ;  table base 0x018510

`0x018468 + 81*2 = 0x01850A`. Writing there made dispatcher #2 read its jump
table 0x21E bytes away **for every character, legacy included**. Four legacy
replays diverged from vanilla and never re-converged; removing that one word
restored all four.

**A word-displacement jump table ENDS WHERE CODE BEGINS.** Compute the entry
count (`(first_code_addr - table_base) / 2`) and refuse any index >= it. The
manifest's own description was the clue and was read past: it called the
value "a displacement pointing back INTO the table" — it was a displacement
because it IS one, belonging to an instruction.

**And the deadness check that certified it was replay-limited.** Vanilla
reads 0x01850A ZERO times on `02_demitri_vs_cpu` (the replay 14z-74 used) and
SIX times on `05_timeout_idle`. A "0 reads" result proves nothing unless the
replay set exercises the code around the address — a same-instrument positive
control on a live row does NOT cover that, because it only shows the
watchpoint works.

## Check whether the bug was already fixed once — and ask if unsure
## (14z-75, maintainer's lesson; cost most of a session)

The maintainer reported Pyron's Cosmo Disruption crash. It had been "fixed"
in 14z-74 and confirmed by playtest. I withdrew that fix (correctly — it
corrupted legacy), then measured on rigs that never fired the move, and
published **"the 14z-74 word never fixed the Cosmo crash."** That was wrong.
The maintainer pushed back — *"you explicitly fixed Cosmo Disruption before
... if I were you, I'd find this version, look at the diff with its previous
version to isolate the fix and start from there"* — and that is exactly what
cracked it.

**The procedure, in order, BEFORE forming a theory:**

1. `git log --oneline --grep="<symptom>"` and `git log -S "<manifest row>"`.
   A defect being reported now may be a REGRESSION of something already
   solved. Two commands.
2. Identify the build where it was last known good and **diff it against its
   predecessor.** The delta is the answer.
3. **If the record is ambiguous about whether it was ever fixed, ASK.** The
   maintainer was there and will usually remember. One sentence from them
   beats an afternoon of rigs.

The failure is expensive in BOTH directions: re-deriving a fix that already
exists, or — as here — declaring "never fixed" about something that was, and
shipping a build with the crash reintroduced. Note also how it compounded
with the rig lesson: my evidence for "never fixed" was a set of negative
results from rigs that produced no event at all.

## A PLACED address baked into a hand-authored `thunk_hex` tracks NOTHING
## (14z-78, cost a session and read as a hardware limit)

`[[site_thunk]]` bodies are hand-written machine code. Anything the BUILD
chooses that gets typed into them as a literal stops tracking the moment that
choice changes — and nothing fails, because the hex is opaque to every pass
that would otherwise rewrite it.

The generator already guarded this for the tenant's CHARACTER ID (twice; both
guards exist because that trap bit). It did not guard the ALLOCATOR's output.

`donovan.toml`'s two select-companion thunks carried `207c000dda1e` —
`movea.l #$000DDA1E,A0`, `anim`'s placed address, hand-computed once in 14z-22.
Relocating `anim` left both bodies aimed at the vacated range; another region
slid in, the resolver read its bytes as signed 16-bit offsets, and the engine
took a vec3 address error at **vanilla** PC `0x015098`. A crash in untouched
Capcom code, from a manifest typo, three sessions after it was written.

**What it cost:** `anim` is 371,712 of the 470,200 bytes three tenants need
from a 344,640-byte crypt window, so "anim cannot move" was recorded as M3b's
binding constraint, and the maintainer was given a fallback ladder (grow the
profile, or drop a character) for a problem that was a hex literal.

Two lessons, both cheap:

1. **When a stale value is IDENTICAL on two builds, grep for the VALUE before
   tracing the CODE.** "Same on both builds" already proves it is not computed
   — something wrote it down. `grep -ri dda1e build/manifest tools docs` found
   it in seconds; the planned instruction trace was aimed at a dead end (the
   resolve thunks TAIL-JUMP, so the stack held the wrong caller).
2. **Write `region_subst`, never the address.** It resolves
   `placed[region]+offset` at emit time. In the default layout it emits the
   identical byte, so converting a literal is fingerprint-inert.

Now a build error: `tests/test_thunk_addr_literal.sh`. Its coverage boundary is
stated rather than assumed — opcode-anchored and word-aligned, so a raw
longword in embedded data is still out of scope (an unanchored scan reads
operand pairs as addresses and is pure noise).

## The pushed group-0 exception PC is mid-instruction — probing it reads a clean zero (14z-81)

The merged-legacy audit's Huitzil crash reported `CRASH 2886 vec3 PC 015098`.
A `GUARD_PROBE=15098` breakpoint produced ZERO probe lines on the crashing
build — at the crash itself — and zero on the healthy reference across 11,017
frames. Nothing was wrong with the probe machinery: a 68000 group-0 exception
(address/bus error) pushes a PC from INSIDE the faulting instruction, so
`0x15098` is the middle of the `move.l (a0),(0x20,a6)` that starts at
`0x15096`, and no instruction ever BEGINS there for a breakpoint to match.
The dead-instrument class again, in a new coat: a probe that cannot fire
prints the same clean zero as a site that is never reached.

**Rule: probe ENTRY addresses (read the disassembly around the crash PC and
find the routine's entry), never the CRASH-line PC itself.** And demand the
rig-liveness control before believing any zero: `tests/audit_merged_vec3.sh`
hard-fails when its healthy-reference probe reads no hits, which is what
turns this trap into a named error instead of a wrong conclusion.

## A pre-armed attribution is a hypothesis, not a finding — print the measured mechanism (14z-81)

`audit_merged_legacy.sh` was written with F2 (the merged shim serving only
tenant 0 → unseeded pools) as the pre-armed attribution for any Huitzil
leg-(b) crash, and its failure message SAID so. The measured crash was a
different mechanism entirely (the satellite anim-base defect, at spawn,
before seeding could matter) — the message was corrected the same day, but
only because the measurement happened to run the same session. A plausible
mechanism written into a script's output becomes "the finding" the moment
someone reads a failure without re-measuring. Pre-arm attributions in
comments and headers as PREDICTIONS; make the printed verdict carry only
what was measured, or point at the probe that measures it.

## Dispatch-time owner reads are transient at spawn instants — two measured counterexamples (14z-81c)

The withdrawn multi-owner obj_hook stub design read the dispatching
object's owner at runtime (+0x30/+0x32 walks to a player struct, then
`(0x382)` for the id). Six replays produced two distinct failure modes:
a type-119 creator hop walked through a RECYCLED slot to the wrong player
(donovan/12, a regression on a replay first-wins served correctly), and
the type-115 census showed +0x30 AND the type byte itself rewritten
WITHIN the spawn frame. Owner facts measured on healthy steady-state
ticks do not hold at the spawn instants where this family dispatches —
and spawn instants are exactly when a per-tenant machine needs routing.
Route on facts baked at BUILD time (spawn-time tags, per-tenant type
numbers), not on runtime state near a spawn.

## Forced-pick pokes hold through SELECT only — a vs-CPU P2 carries the CPU's REAL pick at match time (14z-81c)

`(0x382,$FF8800)` read 0x06 (the CPU's actual character) at f2886 on
`12_donovan_vs_cpu` despite the rig poking `$FF8B82 = 0x13` at frames
1400-1500 — the pokes force the SELECT commit, and the loaded struct is
rebuilt from the real pick. On 2P replays both structs hold the poked id
(test_shim_charid measured exactly that), which makes it easy to assume
the same on vs-CPU rigs. Any check of the form "(0x382,P2) == my tenant"
is rig-dependent: true on 2P forced-pick replays, false on vs-CPU ones.

## A gate's PASS path is untested until something real passes — treat the first live PASS as a verdict-control moment (14z-81c)

`audit_merged_vec3.sh` was ground-truthed on its FAIL path at birth (the
defect existed) and mis-verdicted its first real PASS on a zero-padding
string compare ("00425ffc" != "425ffc" — the probe pads, the expectation
does not). "The verdict logic is itself tested" (CLAUDE.md §4) cuts both
ways: a gate born against a live defect has never exercised PASS, so its
first green is not routine — read the printed values, not just the
verdict word.

## A stamp census must enumerate WRITE FORMS, not just the known immediate shape (14z-82)

The 14z-81b type-stamp scan matched `move.l #$01xxTTss,(An)` and concluded
"types 114/115/118/120 are stamped elsewhere or computed". Productizing the
census (tools/audit_type_stamps.py) with the `move.b #imm,(d16,An)` form
found ~26 MORE stamp sites — type 115 alone has 20+ byte-stamp sites in the
pod code, all following the one spawn idiom (`beq.s <alloc-fail>; move.b
#1,(A4); move.b #type,(2,A4); move.b #owner,(3,A4)`). A one-form scan reads
exactly like a complete inventory, and a renumbering fix built on it would
have left every missed site serving the ORIGINAL number — the silent
mis-dispatch class the fix exists to kill. The countermeasures that ship
with the census: a positive control (--expect on measured sites), a
DYNAMIC writer-PC audit (tests/audit_type_writes.sh — every observed
family write must map to a frozen row), and the dispatch-range gate on the
merged build (zero original-range dispatches on later tenants' replays).
Also: d16 matters — `move.b #$73,(2,A4)` is a type stamp, `(3,A4)` is the
owner/sub-state byte; a d16-blind match conflates two different fields.

## A two-leg A/B that bails on leg 1 leaves leg 2's health an ASSUMPTION — and the assumption was false (14z-82b)

`audit_merged_legacy`'s leg-b ran the MERGED build first and returned on
its crash, so "the single-tenant reference is clean" was never a
measurement — it was the natural reading of a report that only ever
showed the merged leg failing. pyron-m2 crashes at f7997 SOLO: the defect
sat in the FROZEN build for two sessions while every record called it a
merge artifact, and the fix hunt started in the wrong codebase half. The
repair is structural, not procedural: on a leg-1 crash the gate now runs
the reference leg anyway and prints MERGE-SPECIFIC vs LATENT IN THE
FROZEN BUILD — the attribution is part of the verdict, not homework left
to the reader. Related gap, same lesson: the only gate that ran the
crashing replay at all (`test_pyron_soak.sh`) builds STAGE 4, so the
frozen stage-6 artifact was never soaked — a covering gate that rebuilds
at a different stage covers a DIFFERENT build.

## A hit-path defect fires per COLLISION, not per frame — soak length is not coverage (14z-82b)

The hit-class map over-index needs a specific object's hitbox to OVERLAP
something (`bhi.s` skips the dispatch otherwise): an 11,017-frame chaos
soak produced exactly ONE dispatch, at f7997. A replay battery can be
green for sessions while carrying a one-collision-away crash, and "the
soak is long" says nothing about whether the rare interaction ever
occurred. For dispatch-guarded paths, pair the soak with a FIRE CENSUS
(probe the dispatcher, count entries and input values) so "never fired"
and "fired and survived" stop looking identical.

## -debug fire counts do not transfer to checksum timelines on vs-CPU/chaos content — attribute divergences with DUMPS, not debug probes (14z-82c)

The three moved don-mash `.sha1` baselines were first "attributed" by
probing the new thunk under the guard (-debug): two replays showed ZERO
fires and the third fired 3,000 frames AFTER its divergence onset — a
contradiction that would have read as "the thunk is not the cause" and
sent the hunt somewhere wrong. The documented caveat ("-debug runs are
deterministic but NOT checksum-comparable") cuts deeper than checksums:
on collision-timing-sensitive content (vs-CPU AI, input chaos) the debug
timeline plays a DIFFERENT MATCH by the ten-thousandth frame, so its
event counts say nothing about the run being attributed. The attribution
that works: DUMPS=<frame>:ff0000-ffffff on BOTH builds at a divergent
frame (replay.lua, non-debug, replay-exact) and diff the bytes — here: 3
bytes, all in the $FF7Fxx dead-stack ghost window, zero live state = the
ratified hook-cycle class, re-freeze licensed. Also paid for twice in
one day: DUMPS writes land next to CHECKSUM_OUT, so two runs into one
directory silently clobber the first dump — separate out dirs per leg.

## Cross-build A/B dumps must run PROBE-FREE — debugger overhead lands differently on two different builds (14z-84)

The Bulleta-DF A/B's first run compared vanilla-vs-merged palette RAM
dumps taken under `GUARD_PROBE=2ad82` (hundreds of logging-breakpoint
stops on the palette-seq resolver) and found a persistent 23-byte diff in
row 0x0A — which a probe-free re-run proved to be ZERO. The probe's
per-stop overhead perturbs frame timing, and on two DIFFERENT BUILDS the
perturbation lands at different instruction boundaries, phase-shifting a
palette-seq animation differently per leg: the "diff" was two legs of one
animation sampled at different steps. This is the `-debug`-timeline
caveat's cross-build instance (STATE 14z-82c: "debug timelines do NOT
transfer to checksum timelines"): a probe that is harmless WITHIN one
leg's measurements still invalidates a CROSS-LEG comparison. Rule: any
A/B whose verdict is a byte-diff between two builds' dumps runs with
taps (tap_writes.lua) or plain DUMPS only — never under GUARD_PROBE /
-debug; if a probe is needed to find an address, find it first, then
re-run the A/B clean.

## A pool measurement is a claim about ONE pool — decode the walker first (14z-85)

The 14z-84 owner-tag census measured $FFB800 (0x80-stride) and its
conclusion was carried into the ruling brief as "the tag byte" — but
the 59-75 family the tag serves lives in $FF9400 (0x100-stride, walker
head 0x54458 `lea ($1400,A5),A6`, stride `lea ($100,A6),A6`). The two
pools share a layout family, the same replays exercise both, and the
census numbers looked healthy — nothing about the measurement itself
said "wrong pool". What said it: decoding the DISPATCH WALKER's own
base+stride from the opcode view (two instructions), plus ram.md's
$FF9400 row and the 14z-82 dynamic census's own $FF94xx stamp
addresses, all already on record. Before trusting that a slot-level
fact transfers to a family, decode the family's walker. Re-measured on
the right pool the byte WAS free — the mechanism survived, but only by
luck, and the $FFB800 result turned out doubly wrong (see the platform
byte-lane entry).

## A port_patch on a shared engine-family region fixes ONE tenant's copy (14z-85f)

Every tenant carries his OWN copy of the ported engine-family regions
(x028122 = the vs2 object-hit damage applier + reaction handlers; the
merged image holds three). Donovan's session-14n throw-damage fix — six
port_patch rows reconciling the applier's A5 staging displacements to
the vsavj layout (same-value class #4) — lived only in donovan.toml, so
Huitzil's and Pyron's copies shipped with the vs2 displacements intact:
their object-path hits staged damage into $FF3494/96/98, which the
vsavj engine never reads. Face: Phobos' FINAL GUARDIAN beam ticking 12
times, combo counting, ZERO HP — while hitstop, sparks and satellites
all worked (the applier's other effects don't route through the dead
vars). Cost: the defect survived TWO playtest cycles because most
moves' contacts take the fighter-path stager, which was never broken.
Rule: when a new tenant imports a region that carries port_patch rows
in ANY existing manifest, the rows come with it — grep
`region = "<name>"` across build/manifest/*.toml is the two-second
check. And its converse from 14x still binds: do NOT blanket-copy the
rolled-back families (the grab-pointer/state rows are stage-99 parked
in donovan.toml because ported READERS consume those vars at vs2
offsets).

## A 0x7xx sfx id's faithfulness is a property of its CONTENT, not its number (14z-85g)

The 14z-65 silencing sweep classed every vs2 sound-farm stub playing a
0x7xx id as "newcomer voice-bank range, keep silent pending M5" — a
NUMBER-based rule. For 0x73A (the trap detonation chirp) it was wrong:
the sample bytes are byte-identical in vsav's own QSound image at the
same address (0x6C0000), keyed there as the 0x198/0x199 family
[CORRECTED 14z-95, GitHub #93: for 20,480 of 20,481 bytes — the
INCLUSIVE endpoint 0x6C5000, the played byte, differs: vsav 0xFF,
vsav2 0x00; the gotcha's lesson stands, but "identical" claims must
include the inclusive endpoint] — the
maintainer could HEAR the sound existed in the build while the docs
said it needed a sample port. Cost: the item shipped through two
closure attempts (14z-84 "proximity not-a-bug", 14z-85g first reading
"restoration = M5") before the content check — two python lines
(extract the vs2 keyon's window, bytes.find in vsav's image) — settled
it. Rule: before writing a stubbed_sound row (or planning a sample
port), CONTENT-SEARCH vsav's QSound image for the vs2 keyon's window
and check keyons_vsavj for an id at the hit address; the fix may be a
kind=sound_stub row instead of an M5 dependency. And attribute the
CALL PATH before attributing the record: the trap detonation goes
through the 0x4EE0-0x4F60 farm-stub band, not the per-node record its
array happens to also carry.

## A self-frozen `.sha1` cannot see a legacy regression — and a replay's FILENAME does not tell you what it loads (14z-88 paid it, 14z-89 measured the extent)

`run_suite.sh`'s default expectation kind is `.sha1`: the whole-log
checksum of the build's OWN earlier run. It answers "did this build
change since I froze it", which is a determinism/change detector — and
it is structurally incapable of answering the superset question, because
re-freezing makes any behaviour correct by definition. Only a `.masked`
spec compares against the frozen VANILLA basis.

That is fine as long as self-frozen replays are tenant content. They
were not. The `*_don_*` and `*_victor_*` families were authored on the
SUBSTITUTION track, where select cell 0x0F was Donovan; the M3a
de-substitution restored Jedah to 0x0F and moved the tenants to appended
cells 0x13/0x10/0x11. From that commit on, those replays loaded VANILLA
CHARACTERS while keeping tenant filenames, tenant-sounding gate names,
and self-frozen expectations. **Measured 14z-89: 35 of the ~43
self-frozen replays on each current set are legacy pairings.**

The bill arrived in 14z-88: the medallion row move cost
`38_victor_p1_vsavj` (P1 Victor vs P2 Jedah) one main-loop iteration at
the select→VS fade, never re-converging against vanilla — a
superset-invariant regression that every battery reported GREEN, because
that replay was compared only against itself.

Rules now:
- **Classify by measurement, never by filename or authorship intent.**
  `tests/audit_legacy_pairings.sh` measures each replay's loaded-character
  signature on vanilla and on the build and FAILS if a legacy pairing is
  guarded only by a self-frozen expectation. Run it whenever a replay is
  added, a cell mapping moves, or a tenant changes id.
- **The signature is +0x60, not +0x382.** Player-block +0x382 is the char
  id only at select; in match it is the voice-flavor class and the engine
  reassigns it from a sound-state-fed list (the entry above, 14z-87), so
  it reports "different characters" on voice noise. +0x60.l is the
  per-character hitbox-data base — a ROM pointer, constant for the match,
  distinct per character (Demitri 0x93B6A, Victor 0x9769E).
- **Compare the distinct-value SEQUENCE, not the frame-indexed
  trajectory.** Hooks cost cycles; the build can load the same fighters a
  frame or two later, and a frame-indexed diff calls that a different match.
- **A "select-only" replay is not automatically tenant-affected.**
  63_idle_select looks like the extended-wheel rigs (44/58/64/92, which
  never populate a fighter block) but its timer-forced pick lands on
  vanilla's character — measured LEGACY, promoted. Assumption would have
  left it in the hole.

## The masked-basis canary corrupted the basis it verified (14z-91)

`tools/freeze_masked_basis.sh`'s `freeze_one()` derived its MAME sandbox
paths from the replay NAME alone (`$WORK/sb_${_n}_$_i`), and
`tools/run_mame.sh` treats an explicit `MAME_SANDBOX` as **deliberate
reuse** — its own header says so ("to test nvram-carrying scenarios"). So
calling `freeze_one` twice for one name in a single invocation handed the
second call the first call's `cfg/` and `nvram/eeprom`.

That is not an exotic ordering. It is exactly what the canary command
`docs/NEXT_SESSION.md` documents does, because the name appears twice —
once as `VERIFY_BASIS`, once in the freeze list:

```
verify leg  (fresh sandboxes) -> reproduces the frozen log BIT-FOR-BIT
freeze leg  (dirty sandboxes) -> diverges at frame 73, and WRITES
```

Both legs are internally deterministic, so `freeze_one`'s own pair-`cmp`
and the instrument control were both green while the baseline moved —
4248 of 4321 lines. The tool printed "ok: reproduces ... bit-for-bit" and
then silently redefined the thing it had just verified, which is the
precise failure its own docstring warns against.

Rules now:
- **Clear a sandbox before every run** unless nvram carry-over is the
  point. Fixed in the tool; gated by `tests/test_freeze_basis_sandbox.sh`,
  whose verdict control reconstructs the pre-fix tool and requires it to
  reproduce the defect.
- **"The instrument control passed" is not "nothing moved".** Check
  `git status` on the artifact after running anything that can write it.

## awk compares hex fields as NUMBERS when they happen to look numeric (14z-91)

A gate parsing `SP %06x hits %d` lines with `awk '$2 == s'` reported the
correct count for site `54476` and a confident **0** for its twin
`5e548` — from the same file, same run, same instrument.

`"054476"` vs `"54476"`: both look numeric, so awk compares them
NUMERICALLY and they match. `"05e548"` vs `"5e548"`: awk's numeric
interpretation is scientific notation, and the comparison does not land
the same way — so the field silently never matches.

Rules now:
- **Normalise both sides to the same width in the shell** (`printf '%06x'`)
  and force a string comparison (`($2 "") == (s "")`).
- A per-site zero next to a per-site correct number is the signature. A
  blind instrument and a real zero look identical — if one site of a
  matched pair reads 0, suspect the parser before the finding.

## `_minitoml` accepts no arrays, and only on Python < 3.11 (14z-91)

`tools/_minitoml.py` supports exactly string / int / bool, and
`loads()` delegates to `tomllib` when the host has it. So a manifest row
using a TOML array parses fine on Python 3.11+ and raises
`unsupported value syntax: [` on 3.9 — a portability split that appears
only on the older host.

Rules now:
- **Encode lists as comma-separated STRINGS** in manifests, as `regions`,
  `region_subst` and `callers` do. It is the existing idiom for a reason.
- Extending `_minitoml` is not free: it must then match `tomllib`
  exactly, or the two hosts disagree about what a manifest means.

## A pointer-shaped heuristic is placement-dependent — merged5 passed by luck (14z-92)

`verify_gfx_build.py` compares a walk of the SOURCE anim region against a
walk of the BUILT image. Both of `obj_records.walk`'s passes decide what
is a record using predicates that ask about ADDRESSES, and placement
moves the addresses out from under the same bytes:

| pass | predicate | what moves |
|---|---|---|
| sweep | "does the long at +6 land in an aux region?" | the aux regions |
| pointer | "does this 4-byte value land inside `[start,end)`?" | the region |

14z-74 hardened the sweep (`sweep_allow`) and left the pointer pass
re-deriving structure from the relocated image. #75 was the bill: the
bytes `00 42 1e 94` at Huitzil's anim offset `0x1D160` STRADDLE one
entry's attr and the next entry's tile inside a real record, and read as
`0x00421E94`. The merged placement window `[0x41A7E0,0x438FE0)` contains
that value; the source window and every solo placement do not. So the
pass dereferenced it, landed on bytes that validated as `fmt=0 count=67`,
and invented one record — +67 entries and 34 out-of-band tile codes,
which aborted every merged build from merged6 on.

**The tell that it was never a pointer: the longword is byte-identical in
the source extract and in the build.** A real record pointer must be
relocated (source base `0x245872` → placed `0x41A7E0`); an unrelocated
value cannot be one. A second tell: its target offset tracks the
placement base (`0x7784` at merged5's base, `0x76B4` at merged6's) —
a real pointer's target offset is invariant.

Rules now:
- **A built-image walk VERIFIES the source's structure; it never
  re-derives it.** Both passes now take the source's accepted offsets
  (`sweep_allow`, `ptr_allow`), and `ptr_allow` also requires the target
  to match, which catches a pointer relocated to the WRONG target — a
  defect a count comparison is blind to (control D of the gate proves the
  blindness rather than asserting it).
- **"It was green before" is not evidence.** merged5 passed because the
  same false longword resolved to bytes whose cptr happened to fail. The
  14z-86 voice batch grew `wide_ext` by `+0xD0`, the window slid, and the
  dice came up differently. Nothing gfx-related changed in that batch.
- **A false-positive rate is a property of the placement, not of the
  data.** The old comment claiming "false positives negligible in
  record-zone data" was measuring one address. Do not re-derive structure
  in an address space you did not measure in.
- **The surface does not shrink — the dice re-roll.** Measured: 200
  candidate heads are in-window in the built image and were not in the
  source, and that count is IDENTICAL on merged7 (one validated, build
  aborted) and merged8 (none validated, build clean). "The number went
  down" is not what happened and is not what to look for.
- Latent for every tenant: Pyron moved `+0x320` on the same build and was
  simply lucky. Any allocator growth re-rolls it.
- Corollary paid for in the same session: **the abort had already stopped
  happening.** 14z-91 moved `anim@huitzil` again and the coincidence
  dissolved, so `m3b_merged8` verifies green with the PRE-FIX tool. A
  blocker nobody re-runs can quietly stop blocking — re-measure a
  known-red gate before you build a session around it, and say so when
  the fix turns out not to be what unblocked the work.

## A frozen build stops being a usable REFERENCE when the profile bumps (14z-92)

`test_merged_render_content.sh` — H and P's only render gate — compared the
merged build against `build/hui31`. WIDE v1.1 (14z-86) made the Z80 driver
members `vsw.z01/z02` content members and v1.2 made `vsw.21m/22m` content
members with sentinel CRCs, so MAME **refuses** any build frozen before
that:

```
vsw.z01 NOT FOUND (tried in vsavjw vsav)
vsw.21m WRONG CHECKSUMS: EXPECTED CRC(dec0de3a) FOUND CRC(1147406a)
Fatal error: Required files are missing, the machine cannot be run.
```

The gate had therefore produced **no huitzil measurement at all since
14z-86**, and it did not say so — it printed

```
FAIL: H band 0x40AF6 == hui31 — merged fnv=1060dc5353bfd8c9 != solo
```

i.e. a dead leg rendered as a **content regression on the build under
test**, which is the opposite of the truth. With a live reference the same
comparison passes byte-for-byte.

Rules now:
- **An empty operand is never a verdict.** A comparator must detect a
  missing measurement and name it (`DEAD LEG`) before it compares. Same law
  as the blind-watchpoint and dead-rig entries; this is its comparator form.
- **A profile bump invalidates every frozen build as a REFERENCE**, even
  though it invalidates none of them as a record. When a tenant is
  re-frozen, or the WIDE profile version moves, re-point the gates that
  name a build by path. HANDOFF's COMPAT note covers booting a build for
  PLAYTEST; it did not cover builds used as silent gate references.
- **`-verifyroms` cannot be the liveness check on this project's sets.**
  Group-C descriptor CRCs are deliberate sentinels (`0xdec0de31..37`) and
  content members resolve by NAME, so it reports every content build BAD —
  including builds that boot and render perfectly. Tried as a fail-fast
  precondition in 14z-92; it failed all four rompaths and was reverted. The
  live check is whether the run produced its artifact.
- **FOUR instances in one session (14z-92), which is the real finding.**
  `hui31` (test_merged_render_content), `pyron20`
  (audit_hitclass_map_cost), `pyron17` (test_pyron_blink) and `don_m5`
  (test_obj_walker_relocation). The last is the sharpest: that gate exists
  to verify the 14z-91 walker relocation and defaulted to a build from
  BEFORE it, so its no-argument invocation could only ever fail. A
  path-named default is a dated assertion with no expiry check — when you
  re-freeze a build, grep the suite for the OLD directory name.
- **Only gates that BOOT the reference are exposed.** `test_gfx_chain.sh`
  and `tools/audit_gfx_merged.py` also name `build/hui31`, but they read
  tile inventories and gfx members statically and never start an emulator,
  so the profile bump cannot reach them (both measured green, 14z-92).
  When triaging this class, sort the references by "does it run?" first.

## A PASS line that hard-codes its control's conclusion (paid: 14z-93, caught by reading a red log)

`audit_hitclass_map_cost.sh` section 0 printed, unconditionally:

```
  ok: THE FIX HOLDS — the soak that crashes the no-thunk twin at
      f7997 runs END-clean through 11,017 frames
```

two lines *under* the branch that had just reported `FAIL: CONTROL DEAD —
the soak did NOT crash on the no-thunk twin`. The success message asserted
the very premise its own control had failed to establish, and it is the
line a skimmer reads.

Both branches were individually correct — the control tested the twin, the
verdict tested the fix build — but the verdict's WORDING carried a claim it
had not checked. A reader taking the last line at face value comes away
believing the crash was reproduced this run.

**The rule: a verdict line may state only what its own branch measured.**
If it wants to restate the control's finding, it has to be gated on the
control's result — which is the fix here (`ctl_live`). Grep for success
messages that describe something measured by a DIFFERENT section; they are
where a decayed control keeps looking green.

Related and the reason this matters here: the control had been dead since
before 14z-92 and the audit exits 1 because of it — so the contradictory
line had been printing under a red exit for a session, which is exactly
the state in which nobody re-reads the prose.

## `DUMPS` land next to the LOG, not in the sandbox (paid: 14z-93, caught before the sweep ran)

`tests/lua/replay_guard.lua` computes `out_dir` from the CHECKSUM_OUT path
(`local out_dir = out_path:match("^(.*)/[^/]+$")`), and writes dumps as
`dump_<frame>_<addr>.bin`. The **sandbox argument has nothing to do with
it.** So the natural shape for a parallel sweep —

```sh
tools/run_replay_guarded.sh vsavjw "$rpl" "$WORK/t_$tag.log" "$WORK/box_$tag"
```

— gives every leg its own sandbox and its own log, and then has all 37 legs
write their dumps into the SAME `$WORK`, keyed only by frame and address.
Legs whose dump frames collide overwrite each other silently, and there is
no way afterwards to tell which leg produced which file. In a census whose
whole point is "prove each leg loaded the right character", that reassigns
one leg's evidence to another.

**Give each leg its own DIRECTORY for the log**, not just its own sandbox:
`"$WORK/tl_$tag/probe.log"`. Caught by inspection before the sweep ran; the
failure would have been a plausible-looking table with attributed values,
which is the worst kind.

## A `|| fallback` after a pipeline reads the LAST command's status, not the failing one (paid: 14z-93, GitHub #84's residue)

`tools/force_pick_probe.sh` reported a machine that died at frame 3020 as a
loaded character:

```
load @3600: hitbox base 0x — char LOADED
```

The parse was

```sh
BASE="$(xxd -p "$OUT/dump_3600_ff8460.bin" 2>/dev/null | cut -c1-8 || echo '????????')"
```

and the fallback **cannot fire**. `xxd` exits non-zero on a missing file, but
the status of a pipeline is the status of its LAST command — `cut`, which
succeeds on empty input and returns 0. So an absent dump yielded an EMPTY
string, the `[ "$BASE" = "00000000" ]` wedge test was false, and control fell
through to the `char LOADED` branch.

Two rules out of it, and the second is the general one:

1. **Guard the FILE, not the pipeline.** `[ -s "$f" ] || return 1` before
   reading it. A `|| default` on a pipeline is decoration.
2. **ABSENT, ZEROS and a value are three outcomes, not two.** This probe
   already distinguished ZEROS (the 14z-65 wedge) from a real base — it just
   had nowhere to put "there is no measurement". That is the same shape as
   the `hui31` dead leg printed as a content mismatch (14z-92): an empty
   operand is never a verdict.

Worth knowing when triaging: the crash had been invisible because the gate
that runs this probe was itself building the wrong tenant (#84), so the
probe's own defect and the crash it was hiding surfaced in the same run.

---

## 14z-94: five shell/tooling traps, each paid for in this session

Grouped because they share a shape: **a construct that fails SILENTLY and
leaves a plausible result behind.** None produced an error message.

### 1. Backticks inside a double-quoted shell string are command substitution

Paid for TWICE in one session. Writing a gate's help text:

```sh
fail "      Add the `if not __debug__: raise SystemExit(...)` guard"
```

the shell ran `if not __debug__: raise SystemExit(...)` as a command. The
second time was a `gh issue create --body "...`single credit, P1 Donovan`..."`,
which died with `command not found: P1`.

**Rule: never put backticks in a double-quoted shell string.** Use single
quotes for the string, or `'...'` around the code sample, or — for anything
long — write the body to a file and pass `--body-file`. The file route also
sidesteps `$`, `!` and newline quoting in one move.

### 2. `VAR=value funcname` PERSISTS after a shell function returns

For an external command, `VAR=x cmd` scopes the assignment to that command.
For a **shell function**, POSIX keeps it set afterwards. A test harness did:

```sh
STUB_FAIL=r3 freeze ...      # section 1
STUB_NONDET=r2 freeze ...    # section 3
... freeze ...               # section 6: STILL has STUB_NONDET=r2
```

so every section's failure injection leaked into the next, and the
clean-run control ran with a stale injection. **Set the variables explicitly
and clear them in the function**, or pass them as arguments.

Caught by the control that existed precisely to catch a vacuous pass — which
is the argument for writing that control every time.

### 3. `grep -vxF "$multiline_string"` matches EVERYTHING if any line is blank

Used to compute "lines in AFTER that are not in BEFORE":

```sh
printf '%s\n' "$after" | grep -vxF "$before"
```

`-F` treats the string as a *list* of patterns, one per line, and a blank
line is a pattern that matches every input line. The filter therefore removed
all output and printed an EMPTY diff under a heading that said the tree had
been dirtied — an accusation with no evidence attached.

**Diff via files** (`diff a.txt b.txt`), and print the counts either side so
an empty diff cannot masquerade as a mystery.

### 4. `git tag -l "pattern" | tail -N` sorts LEXICALLY

`git tag -l "freeze/*" | tail -6` showed `pyron-m3 … pyron-m8` and I concluded
three freeze tags were missing and that HANDOFF was asserting tags that did
not exist. They existed. Lexical order puts `pyron-m8` after `merged-m2` and
after `huitzil-m16`.

**Ask about the tag you mean** (`git rev-parse -q --verify refs/tags/<tag>`),
never `| tail`. Same family as the long-standing "pipe hides the exit status"
entry: `tail` answers a different question than the one asked.

### 5. MAME samples the input ports BEFORE `frame_done`

A Lua `set_value` cannot make frame 1's own port read dirty — measured twice
(at script load, and at the top of frame 1); both land at **frame 2**. This
is why the input-integrity guard's frame-1 branch (GitHub #57) has no
in-emulator positive control, and why the control built for it was REMOVED
rather than kept: a control that implies coverage it does not have is worse
than an honest structural assertion.

The real scenario it guards — a host key physically held before the run — IS
in that read, because MAME samples host input ahead of the frame. Reachable
in the field, not from the harness.

## 14z-97b: five traps from the #103 hunt — four are RIG grammar, one is a
## classifier lying by omission

**A blanket opponent-class poke window that overlaps a LIVE match kills the
match.** `+0x382` is live in-match state (the voice-flavor class, ram.md:85);
writing the next opponent's class into `$FF8B82` mid-match ended the running
match at the poke onset and read as a mysterious early game-over — a full
run lost to diagnosis. The opponent poke must be windowed BETWEEN matches,
aimed with selection frames measured from a prior no-poke run of the same
config.

**Repeating HP pokes across a KO can un-KO the loser mid-judge and wedge the
round THEMSELVES.** Two false stalls were produced this way (one with a
100f-cadence HP=1 schedule, one with a burst that landed inside round-2's KO
freeze). The clean shape: kill pokes at ROUND START (+~100f, before any
contact can put a hit-freeze on screen), exactly three pokes 20f apart, then
hands off. Round boundaries come from the previous iteration's dumps, never
from guesses.

**"PRESS START" on screen is not evidence of a continue screen.** The
P2-join prompt prints the same words permanently during any 1P match. A
screen must be identified from the STATE WORDS (`$FF8004/8008/800C`, the
ladder block), never from the banner text — this misread nearly filed the
Phobos stall as "a dead continue screen".

**The `-debug` timeline is a DIFFERENT RUN, not a slower one.** Under
`-debug` the mash's match outcomes changed (Donovan WON the match he loses
non-debug), so frame-scheduled pokes tuned non-debug aim at the wrong
events entirely. Cross-correlating frames was already banned (GOTCHAS);
the extension is that EVENT PLANS must be re-tuned inside the -debug
timeline too — identify events by VALUE, and expect the trajectory itself
to differ.

**A "static state" classifier is only as honest as its field tuple.** The
#103 stall was first read as a PERMANENT hang because the chosen fields
(stage/mask/idx/bound/timer/HP) all sit still during a long slow sequence,
and the dump window ended inside it. A wide byte-slice re-measure showed
every run flowing on at ~KO+8000. Rule: before declaring RAM "frozen",
diff a WIDE slice at two distant times, and make sure the window extends
past the longest plausible timeout. The same class then recurred at
higher level: "Donovan KO'd by Q-Bee -> judged fine" was read off
ladder-mask movement under continuous HP pokes — the strong signal
(+0x1C record pointer + HP-reset) reversed it. A verdict is only as
strong as the weakest signal it was read from.

## 14z-97: two ways a tool measures the wrong thing and says nothing

**A path argument must be CANONICALISED before anything uses it — the
"correct only when called one way" trap, and this is its THIRD instance in
two sessions.** `tools/propose_masked_specs.sh` existence-checked
`$BUILD/rompath` but handed `$PWD/$BUILD/rompath` to MAME and to
`build_fingerprint.py`. With a repo-relative builddir the two agree; with an
ABSOLUTE one they do not — the checks pass, the emulator gets a path that
cannot exist, and MAME falls through the `;`-separated rompath to `$ROMDIR`.
The tool then measures PRISTINE VANILLA and prints the build's name over it.
Measured live: an absolute-path run reported fingerprint `b0eb9ecd` (vanilla)
for a stage-6 build. Two rules: `case "$X" in /*) ;; *) X="$PWD/$X" ;; esac`
at the top (the convention `audit_mask_window_ff42a2.sh` already follows), and
**print the resolved fingerprint of whatever you actually opened** — that
print is what caught this, not the reasoning.

**A chained rompath makes "file not found" look like "measurement complete".**
This is the general shape and it is worth its own line: MAME's
`-rompath "a;b"` cannot fail loudly for a missing `a`, because falling
through to `b` IS the feature. Anything that builds such a path must assert
what it resolved. Related and already recorded: FBNeo has no `-rompath` at
all, so the same class there is an overlay dir silently left behind.

**A verdict control that CRASHES reads as a control that fired.**
`test_baseset_mask_invariant.sh`'s control runs from a temp cwd and expects
its fixture to be REJECTED (nonzero). An edit gave it a repo-relative library
path, so python raised FileNotFoundError, exited 1, and the block printed
"ok: a mispaired spec is caught" over a traceback. Anything that reads an
exit STATUS as a verdict must distinguish "rejected" from "died" — and the
cheap proof that a control is live is to make the fixture GOOD and watch the
control complain (done here; it does).

## 14z-96: three instrument traps, each paid for in this session

**A gate must not depend on the CALLER'S environment — measured twice in
one session.** (1) `ROMDIR=../ROMS` (relative) failed two gates that
resolve the path from a different working directory — a symlink whose
relative target dangles at the symlink's own dir, and an FBNeo overlay
after a `cd` — while the absolute spelling was green; `run_all_static.sh`
now canonicalises at the entrance. (2) A brand-new fact-lock read
`$REPO` from `os.environ`, which its gate SETS but does not EXPORT —
green under any shell that happened to export it (the author's), a
KeyError under the chain. Caught by the chain's first run, i.e. the
SKIP/FAIL discipline working on a gate written the same hour. The rule:
a gate's python blocks take paths as ARGV, never from inherited
environment, and a new gate's first run should be under `env -i`.

**Python's `hash()` in printed output is PER-PROCESS random.** The voice
audit printed `hash(bytes)` values as content signatures; two runs of
the SAME builds printed different numbers, which reads as "the content
moved" when nothing did (PYTHONHASHSEED). In-run comparison was always
sound — only the PRINTED identifiers lied across runs. Fixed with
sha1-derived digests. If a tool prints an identifier a human might
compare across runs, it must be a stable digest.

**A special-move button press must OVERLAP the final direction frames in
a replay.** Rig 83 v1 fired 236+P as motion frames followed by a
separated 4-frame button press — it produced NO special at all (measured
by snapshot; not even the normal came out reliably), and the rig read as
a legitimate-looking zero. The overlap grammar (`p2=L1`, direction+button
held together) is what registers. The 71/73 rigs' separated presses work
for SOME moves, so a motion that "does nothing" should try the overlap
shape before concluding anything about the game. [game-adjacent; filed
here because the trap is the REPLAY GRAMMAR, not the engine]

## 14z-98: two traps from the #103 close — both are -debug INSTRUMENT
## grammar, and both misread a measurement for a full round each

**Every -debug watch configuration is its own TIMELINE, not just
"different from non-debug".** Three trace_writes runs on the SAME rig
with the SAME pokes — differing only in the WATCH argument — took three
different match trajectories: one stalled at f3260, one drained the
white bar to exactly 0 at ~f6957, one cycled round restarts through
f8921. Reading run B's hit inventory against run A's state map produced
"the kill commit never runs for Donovan" from a timeline that contained
no Donovan death at all. The 14z-97b entry said "the -debug timeline is
a different run"; the extension is that EACH -debug configuration is —
two -debug runs are not comparable either. Remedy, now in the
instrument: `trace_writes.lua` takes `DUMPS` (14z-98), so a trace run
carries its own state anchors; interpret hits only against anchors from
the SAME run. (Also worth knowing while reading its logs: the wpset
stop PC is the instruction AFTER the access — the writer/reader is the
instruction before the logged PC.)

**`GUARD_PROBE`'s `RET <(SP)>` is a caller only for jsr-reached code.**
A routine reached by `jmp`/`bra` (every jump-table dispatch in this
engine) shows whatever the stack last held — measured: `RET 00ff02dc`,
which is sound-task DATA, chased as "a RAM-resident caller" for a
round. `GUARD_PROBE_HIST=N` gives the true path; prefer it whenever the
callee could be branch-reached.

**A kill/heal poke that writes ONLY the 2-byte HP word manufactures
#103's unjudgeable state — on ANY character, vanilla engine included.**
The round judge kills on WHITE HP's sign (+0x52, engine_internals "THE
ROUND JUDGE") and the pipeline keeps white <= hp; `f:ff8450:0001`
leaves white at ~288, so the next real hit underflows hp while white
stays positive and the round can NEVER judge. Measured on a pure-legacy
Victor leg: 2-byte shape UNRESOLVED >= 8,760f; the 4-byte idiom
`f:ff8450:00010001` (hp AND white — test_don_column's shape) FLOWED 600.
Frozen both ways in tests/audit_kill_poke_shape.sh. Consequence already
paid: the 14z-97 (7) continue rig's "HP set to 1" pokes (byte-width not
committed) mean "#103 instance 2" (Phobos x Bishamon) is UNVERIFIED —
possibly the rig's own poke. Kill pokes write BOTH words, always.

## 14z-99: two traps from the #104 re-measurement — both produced a
## CONFIDENT WRONG ANSWER from a working instrument

**A placement lookup that hardcodes ONE region name is wrong on a MERGED
build, and it fails by pointing somewhere plausible.** `placements.json`
carries `anim` (Donovan), `anim@huitzil` and `anim@pyron`. A tenant
verdict resolved through `placements["regions"]["anim"]` unconditionally
therefore maps Huitzil and Pyron through DONOVAN's dst/src — arithmetic
that succeeds and yields an address in the right ballpark. Measured cost:
`audit_don_grab_pose.sh` reported "Pyron's held record mismatches too,
ours 0x26654C vs native 0x26614C" in 14z-98 (7); through `anim@pyron` it
maps to `0x26614C`, IDENTICAL to native. That false datum was published to
the issue and then shaped a fix design ("a DIFFERENT delta than Donovan's
-> per-victim wrong row selection"). Resolve the region PER TENANT, and
treat "the delta is different for each tenant" as a smell that the mapping
is wrong before it is a finding about the game.

**A probe's zero is only as good as its SITE, and a plausible site can be
dead code.** Chasing #104's index, `GUARD_PROBE=27faa` — the documented
four-sibling selector entry, the address the static read points at —
returned 0 hits over a full replay. The routine is real and its body is
correct; it is simply never entered, because every live path enters its
sibling `0x27FA0` (which loads `anim_index_c` directly). 904 hits there on
the same rig. A dead site and a real zero are indistinguishable without a
positive control AT THE SITE, not merely at the mechanism.
Corollary paid for in the same hour: the control site must also be
reachable UNDER THE RIG'S OWN CONDITIONS. `GUARD_PROBE=2ad82` (the
palette-seq resolver) gives 501 hits unpoked and **0 with the forced-pick
pokes**, which reproduced twice and looked exactly like "setting POKES
disables GUARD_PROBE" — a serious instrument defect. It is not: the same
poked run gives 904 hits at `0x27FA0`. The forced Donovan/Victor pick
simply never requests a palette sequence. Test the scary instrument claim
before writing it down.

## 14z-99 (2): three traps from the #105 fix arc

**A RENDER verdict from a gfx-free build is void — and it fails by
looking like a new defect.** The merged1-style pack (program image over
the zero-filled overlay) is the right probe for RAM-level questions and
the WRONG one for anything drawn from tenant art: the win-screen
portrait and the VS-splash side art drew blank/pale on the #105 fix
probe, which read as "the fix half-works" and "a SECOND sel-indexed
surface is white" — both observations were VOID (the full-gfx probe
renders both correctly). Ask what the verdict READS: palette/work-RAM
dumps are program-data-driven and gfx-free-safe; pixels are not.

**`recon_overlay` placement is load-bearing, and only a MERGED build can
tell you.** Inside `[[tenant]]` it scopes to that tenant (the 14z-80
fix). At DOC ROOT it still works on a SOLO build — `recon_for()` reads
`port.get("recon_overlay")` first, and on a solo build the doc IS the
tenant's — but on a merged build that same read makes it GLOBAL: it
overrides every other tenant's overlay, huitzil loses its own rows, and
generation dies on `x022400+0xb74 bank_ref 0xd96b8` (the exact failure
quoted in the 14z-80 scoping comment). The #103 staged block said
"top-level key" because its probe was solo; a window that uncommented it
as written would have hit this. Rehearse staged recipes on the MERGED
composition, not only on the vertical they were probed on.

**A staged VALUE swap cannot ride the uncomment convention.** The
bare-# uncomment rule reproduces staged ROWS byte-for-byte, but staging
`#colors = 10` beside a live `colors = 8` would uncomment into a
DUPLICATE KEY, which the manifest parser refuses. Stage value swaps as
an edit instruction in a comment (one sed, written next to the line),
and put the swap in the window checklist.

## A probe PC that is not an instruction boundary measures NOTHING while looking green (14z-100)
`GUARD_PROBE`/breakpoint addresses must sit on the OPCODE word, not inside
an operand: the #107 reachability probe first sat at farm entry +0x3088 —
the middle of the previous `jmp abs.l`'s operand — and produced a clean
"0 fires / END clean" run that measured nothing. A dispatch-farm entry is
6 bytes (`4ef9` + long); compute the entry PC from the FARM BASE, and when
a zero surprises you, re-derive the PC from the bytes before trusting it.
The same session's second instance: the hitclass-map probe only became
meaningful after the Demitri-vs-Demitri control proved 468 fires — a
probe with no must-fire control is not an instrument.

## Rig iterations must NOT share a dump directory (14z-100)
`DUMPS` files are named `dump_<frame>_<lo>.bin` — a second iteration with
overlapping frames silently OVERWRITES the first's evidence. v3 of the
contact rig destroyed v2's satellite-bearing frames and cost a re-run.
One directory per iteration, always.

## `grep -c pattern file || echo 0` DOUBLE-PRINTS on zero (14z-100)
`grep -c` prints "0" itself AND exits 1, so the `|| echo 0` appends a
second line and every `[ "$n" = 0 ]` comparison fails. Use
`n="$(grep -c ... )" || true`. Cost the clash audit its first verdict run.

## The -debug write-trace and non-debug dumps can DISAGREE about one write (14z-100; RESOLVED 14z-101 — they never disagreed)
On the SAME build and replay, `trace_writes.lua` (-debug) recorded the
fighter's `+0x18` receiving table[0x11]=0x6000 from the vanilla init,
while non-debug dumps read 0x1000 at the same phase. **RESOLVED
(14z-101, GitHub #108): there was no instrument disagreement.** The
FBNEO_HTAP tap showed the same single writer (`PRG:0x282C0`) writing
0x1000 on the canonical timeline — the -debug leg's "0x6000" was never
OBSERVED, it was INFERRED by reading the table from the PRISTINE opcode
view, and our own `obj_bank_word_slot` ops patch that table row
(0x282F6 := 0x1000, deliberate). Two lessons, both old ones biting
together: a MAME watchpoint logs REGISTERS, not the datum (14z-76), so
any "value written" quoted from a -debug trace is a table lookup in
disguise — and a table lookup must name WHICH IMAGE it read. Before
declaring a table "not covered by any patch op", grep patch.json for
the table's address range; that archaeology takes one command and would
have skipped the whole paradox. The advice stands for real instances:
when a -debug trace and non-debug state seem to disagree, take the
non-debug tap (FBNEO_HTAP) — here it settled the question in one run.

## zsh: an argument beginning with `=` triggers =cmd expansion (14z-100)
`echo ====` fails with "=== not found" in the Bash tool's zsh — `=word`
expands as "path of command word". Quote it or avoid `=`-leading args in
generated command lines.

## A scripted motion input is NOT the move you named — the buffer FOLDS leading directions, so identify by effects, never by the script (14z-101)
The #109 native-reference hunt scripted "6236+2P" and confidently called
the result the clone-mode EX; it was the ES — vs2's buffer reader kept
the identified pattern 236+2P and IGNORED the leading 6 (the maintainer
named the mechanism). Meanwhile a dp-shaped attempt whiffed entirely and
a 263 shape fired the real EX. Motion parsers are lenient in ways that
make the SCRIPT'S name for an input worthless as an identification: two
different scripted shapes can land the same move, and the shape you
intended can land a different one. The rule: identify an activated move
by its measured EFFECTS (stock cost, seq id, spawned objects, the
screen), and when captures disagree with expectations, send them to the
maintainer BEFORE building on the identification — one reply named three
moves this session. Related trap, same family: the 87 rig's scripted-LK
"crashes where the real LK does not" (scripted strengths are not
authoritative either).

## An "attack-only" entry-set A/B needs a QUIET-FRAME presence profile, or a constant fixture becomes your defect (14z-102)
The 14z-101 (8) #109 A/B compared per-clone OBJ entry sets "at the
attack" on both legs and read the cycling `0x4302/0A/0C` vs
`0x4D00-0x4D0C` pieces as the beam segments 0xA00 low. They were the two
games' STOCK-METER PIP animations — present at EVERY frame of both runs,
and the piece counts even matched the rigs' poked stock counts (ours 3,
native 5). One dump at quiet frames (pre-attack, post-cooldown) would
have excluded them in seconds; instead the misread survived into the
window prep as located sub-defect "A1" and cost the window session its
first hours. The rule: before attributing any entry to an EVENT, profile
its presence across frames far from the event on BOTH legs — an entry
present in quiet frames is scenery, whatever its codes suggest. (Same
family as "the observation window bounds the claim", RH-19 — here the
window was only ever placed ON the event.)

## MAME palette RAM ($90C000) takes Lua pokes for READBACK but not for RENDERING (14z-102)
Poking palette rows from a frame_done hook (POKES or space:write) lands
in the bytes — a later DUMPS readback shows the poked values sticking —
but the rendered frame never changes; only the GAME's own writes
recolor. Two magenta-row controls proved it (poked row read back intact
at the next frames, snapshot unchanged, while the DF seq's writes to the
same row visibly recolor). Do not build a palette A/B on pokes: it is a
dead instrument that passes its own readback liveness check. Use a probe
BUILD (or poke the game's staging buffer, once its per-frame copy source
is measured), and treat any poke-based "no visual change" as
unmeasured.

## A self-test that drives a gate through DELIBERATE failures litters the gate's evidence directory (14z-103)
`test_m2a_flicker_gate.sh` (portable tier, so it runs on every
`run_all_static` pass) stubs the emulator and feeds
`m2a_legacy_gate_masked` logs that MUST fail — and the gate's failure
path faithfully preserved each one to `build/gate_failures/` as
`03_two_player_vs.<epoch>.log`, exactly where a REAL masked-gate failure
leaves its evidence. 141 stub logs accumulated over five days (140 of
them committed), and the newest — written by the close's own portable
re-verify, 30 seconds before the 14z-102 close commit — presented in
`git status` as a post-close gate failure and cost a session-open triage
to clear. The stubs are indistinguishable from evidence by name and
shape (the shrink-case stub is bit-identical to the frozen vanilla
basis). The rule: a fixture's deliberate FAIL must never write into the
shared evidence path — `m2a_common.sh` now honors `M2A_KEEP_DIR` and the
self-test points it at its own workdir. When auditing
`build/gate_failures/`, the four July-29 `03_two_player_vs` logs and the
`merged1_*` logs are real evidence; anything bit-identical to
`tests/expected/vsavj/masked-v2/logs/03_two_player_vs.log` or carrying
`ffffffffffffffff` lines was flicker-gate litter (removed 14z-103).

## A 1P-arcade rig is silently pinned to the ARCADE DRAW — any timing change re-rolls its opponent and stage (14z-103, GitHub #110)
`audit_fg_damage`'s frozen 10/10 and `audit_pool_free_byte`'s pcosmo
formation window were measured on 1P rigs whose opponent came from the
arcade CPU draw. The 14z-87 batch (voice-borrow + beep sound members)
shifted match-setup state enough to re-roll that draw — merged6 fights
char 0x0C on stage 0x12, merged7 and every build since fight char 0x00
on stage 0x0E — so both audits' constants silently described a fight
nobody's build has run for five generations (fgA measured 24-vs-10
against a DIFFERENT victim; the cosmo rig's scripted motions spent the
stock on a different move against the new opponent and formed zero
satellites). The behavioral first-divergence was at MATCH START
(opponent spawn X), not mid-fight cycle skew — a draw change, not
drift. The rule: an audit that freezes fight-derived values must PIN
the opponent (2P + early-window pokes, the replay-80 shape), never
inherit the arcade draw; and when a frozen-value audit goes red on a
build its own generation column says was green, check WHICH match it
is measuring before checking how the fight went. Re-derived rigs:
hui/74, hui/75 (2P dummy, bit-identical across generations), pcosmo ->
106_pyron_cosmo_clash.

## A fixed-frame rig verified on ONE character whiffs on another — reach, knockdown arcs, down windows and wake timing are ALL per-character, on BOTH sides (14z-104)
Three instances in one session, each first misread as a build finding:
Phobos' standing LP WHIFFS at the spacing where Demitri's connects (the
downwin audit's first red); heavies cannot be mashed into a down window
(each whiff's recovery eats the next attempt — the "wider mash" fix made
even the control red); and Victor's sweep throws the victim clear out of
down-attack reach while Demitri's keeps them close. On the VICTIM side
the same applies: Phobos wakes from a knockdown in 24 frames (window
f3086-3092) where Victor lies until ~f3145. The rule extends
rig-must-produce-the-real-event: a multi-character audit needs per-leg
(input, frame) pairs MEASURED per character, and its checker must REFUSE
to judge a leg whose setup event did not happen (whiff/no-knockdown),
never pass it and never report it as the surface failing. All four new
combat audits (timeout/downwin/throws/down_attack) carry that refusal.
- **DO NOT EDIT A SHELL SCRIPT WHILE IT IS RUNNING — `sh` reads it by BYTE
  OFFSET, so even a COMMENT-ONLY edit derails it.** Paid for in
  14z-107 (7): `tools/run_sim_jtcps2.sh`'s header was rewritten while three
  45-minute simulations were mid-flight, and each of them died at its
  collection step with `syntax error near unexpected token 'else'` — the
  interpreter resumed reading at an offset the edit had moved. The same
  edit hit a running `tests/test_mister_sim_anchor.sh`, whose whole verdict
  had to be discarded and re-run. **What survives is what a separate
  PROCESS produced**: the Verilator sims had already written their dumps
  into the scratch clone, so every measurement was recoverable by copying
  `cores/<core>/ver/game/wram` out by hand — only the shell wrapper's
  post-processing was lost. Rule: freeze `tests/*.sh` and `tools/*.sh`
  before launching a long run, and if an edit cannot wait, copy the script
  and run the copy. (This is why 14z-107's own brief says "run the legs
  detached, poll the PID, and never edit a script while it is running" — it
  is in the brief because it is easy to do by accident while filling the
  wait productively.)

## THE INSTRUMENT PROTOCOL — adopted 14z-107 (11), maintainer-directed

**Paid for six times in one arc, and the class is older than the arc** (see
"half the Lua instruments stage inputs one frame off" and "success while the
instrument was not the one being claimed", both above). The maintainer's
direction, 2026-08-24: tighten how agent-driven instrumentation works, choose
the mechanism on the facts, and prefer scoping for context and efficiency.

**The facts it was chosen on.** Every instrument defect in the MiSTer arc was
caught by a CHEAP MECHANICAL CHECK, not by review: an address contradicting
its own label; a demanded comparison against the romset; a physically
impossible percentage; a 2x2 factorial; a first real run. **None was caught by
re-reading the work.** So a standing adversarial reviewer is the wrong buy —
it spends context on the runs that are fine and would have missed most of
these. Three rules instead, all mechanical:

1. **SEPARATE THE AUTHOR FROM THE VERDICT.** The sharpest instance: the agent
   that wrote the verdict tool also believed it, and reported **"D4 WORKS"
   over ten opcode fetches the CPU received as garbage** — because the tool
   judged the RAW word and never compared the LATCHED one. An author cannot
   see the assumption they built in. Judging is small-context by nature (the
   numbers, the control, the frozen expectation), so the split is nearly free:
   measure in one scope, judge in another.
2. **PROVE THE INSTRUMENT BEFORE ITS FIRST REAL USE**, not after a surprise —
   it must FIRE on a known positive, FAIL on a known negative, and its
   IMPLAUSIBLE VALUE must be named in advance. That last one is not
   decoration: "13,624% of the physical ceiling" was caught only because a
   percentage over 100 is obviously wrong, and naming the ceiling up front
   turns that luck into a check. This is CLAUDE.md §4's "verdict logic is
   itself tested" moved EARLIER — the rule existed; what failed was applying
   it before trusting a first result.
3. **AN INSTRUMENT THAT NAMES A PHYSICAL CONSTANT MUST ASSERT IT.** The
   work-RAM dump hook kept reading byte `0x600000` after slice D2 moved work
   RAM, and faithfully reported VRAM as a bit-identity failure in 101 of 101
   frames. It should have derived the offset from the RTL constant rather than
   carrying a literal. This generalises 14z-95's "checks that stopped
   checking": a hardcoded address is a check with an expiry date nobody wrote
   down.

**Corollary for reading a green result:** ask what would have to be true for
it to be green WRONGLY. Two of this arc's defects returned confident correct-
looking answers, and the standing warning "suspect the instrument before the
thing under test" is what a red result deserves — this is its mirror for a
green one.

Strong candidate for the skill distillation recorded under STATE "Decisions
pending", since it is discipline rather than reference data.

## A REPLAY'S NAME IS A CLAIM ABOUT THE BUILD (paid: 2026-08-24, 14z-107)

`tests/replays/11_pick_donovan.rpl` **does not pick Donovan** on any build
after 14z-64's M3a de-substitution. It walks to wheel slot `0x0F`, which was
Donovan only while he was SUBSTITUTED over Jedah; post-M3a the tenants sit at
their native ids (Donovan `0x13`, Huitzil `0x10`, Pyron `0x11`) on appended
cells, and slot `0x0F` is plain **Jedah** again. The filename outlived the
fact by dozens of generations.

**How it cost time:** a MiSTer measurement was scoped to prove obj bank 4 —
the tenants' FIGHTER art — gets fetched on the core, using replay 11 on the
reasoning that it "runs past match start". It does run past match start; it
was simply never going to pick a tenant, so obj bank 4 was unreachable by
that replay at ANY window length. Caught before the 70-minute run by
measuring instead: on MAME + the WIDE romset replay 11 anchors at
`p1_char_id = 0x0F` with `p1_hitbox_base` in VANILLA space, while
`36_pick_tenant_cell` anchors at `0x13` with a base in TENANT space.

**The header said so and was read past.** It opens "pick slot 0x0F (Jedah in
vanilla; Donovan after the M2 port)" — accurate about its own era, on a tree
now many generations past M2. Build-dependence was documented; the reader
generalised anyway.

**The rule.** This is the sibling of "identify moves by measured EFFECTS,
never the script's input name" (14z-102), one level up: **an artifact whose
meaning depends on the build is a CLAIM about the build, and needs asserting
like any other.** A replay named for a character is exactly as trustworthy as
a hardcoded `0x600000` — see THE INSTRUMENT PROTOCOL's rule 3, which this
instance generalises from instruments to fixtures. The cheap assertions
already exist and were not consulted: the expectation class
(`tests/expected/donovan-m11/11_pick_donovan.masked` is a LEGACY class, not a
tenant one) and `tests/test_select_arrays.sh:85`, which says in words
"11_pick_donovan … ending on Jedah".

**Practical:** to reach a tenant on a current build use
`36_pick_tenant_cell` (Donovan `0x13`), `37_pick_huitzil_cell` (`0x10`) or
`40_pick_pyron_cell` (`0x11`). All three tenants carry `gfx_bank: 4`.

