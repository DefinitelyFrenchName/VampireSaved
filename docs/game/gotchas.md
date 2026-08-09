# GOTCHAS (game) — traps in VAMPIRE SAVIOR itself

Things about the GAME that will mislead you: engine behaviour, data
layout, and modes that fail quietly. True of `vsav`/`vsav2`/`vhunt2`
whatever you are building — if you are reading these to fix a bug in
this romhack, read `../platform/gotchas.md` and `../project/gotchas.md`
too.

Append the moment one is paid for. Read before touching the related area.

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

## Per-char table entries are PAIRS more often than you think

param32_a/b (movement velocities) span 0x80 per 32 apparent slots and
were registered as 4-byte rows; they are 16-char tables of 8-byte
(forward, back) PAIRS. "Slot 0x0F × 4 bytes" = char 7's second long =
FELICIA'S WALK-BACK — corrupted by Donovan's port since the table
work landed, at 1px-drift scale that 19 playtest rounds never saw.
Verify entry layout against vanilla CONTENT before registering any
table: alternating sign longs (+,-,+,-) are a pair signature; a
16-char pair table and a 32-char value table have identical spacing.
The 29_felicia_walljump oracle caught it the day it was frozen.

## In the engine hit-spark spawner, a1 is the VICTIM, a6 the attacker
The shared spark spawner (vsavj 0x18EFC, vs2 0x178C2 twin) reads the
attack record via a3 and checks `$54(a1)`/`$382(a1)` — but a1 is the
DEFENDER (reaction-side remaps; vs2's char specials 6/0x10/0x11 there are
victim-specific spark handling). The attacker is a6. A thunk gating "is
the attacker Donovan" on `$382(a1)` silently gates on the victim and
never fires (cost a build-and-measure round; measured live: a1=ff8800
victim, a6=ff8400 attacker, bp at the spawn-mark thunk).

## Anim numbers: facing adds 0x300; set-anim QUEUES, display resolves
`jsr $4CE2`-family set-anim helpers add 0x300 to the anim number when the
facing bit ($70) is set, then queue (number, params) into the command
ring at a5-0x71F2 (writer 0x31DA). The number→record-strip resolution
happens LATER in the display processor via per-char strip tables (the
`movea.l #T,a0` site family from the overlay work) — so patching bank
fields or numbers at spawn/first-tick does NOT change which strip is
walked; only the display-side table selection does. Object +0x18/+0x1A
(0x0000/0x4000/0x6000 | 0xE000) are TILE-bank attributes, not anim-table
selectors.

## OBJ-RAM diffing: entries move every frame, stale tails linger, dumps
## and taps CAN legitimately disagree
Three traps from the Victor-shock investigation (session 14z-6):
(1) sprite-list entries relocate between frames — "who writes offset X"
is only meaningful frame-by-frame, and content seen at X may have been
written there thousands of frames ago (the c625 curtain column was an
intro-time leftover exposed mid-match by a longer list);
(2) the region past the active terminator holds STALE entries that
render again the moment a composition extends the list — garble that
looks like bad tiles can be perfectly-good OLD entries;
(3) tap_writes originally logged data as %04x — 32-bit moves (the
common way OBJ entries are written) truncated to the LOW word, hiding
the code word entirely (fixed: %08x). Grep for a 16-bit value must
account for it appearing in either half of a long write.

## The electric-hit DARKEN displays never-rewritten OBJ buckets — and
## effect windows need ODD-frame sampling
The screen-dim on electric hits is drawn by extending the sprite list
into the tail buckets, trusting their CONTENT from long-ago writes (the
VS fade). Any character whose VS screen leaves non-dark pieces there
(ported Donovan's portrait) garbles the darken; and a build change that
empties them (the 14z-7 clear) silently removes the darken instead.
Verification traps paid for: the darken window is ~10 frames and my
even-frame sampling missed it entirely across three sessions; and an
A/B of a curtain change is meaningless unless the compared frames
actually DISPLAY the curtain (check the list extent includes the
buckets at the sampled frame).

## "This char's band is free once the char is replaced" — NO: bands hold
## SYSTEM-REFERENCED tiles too
The session-14 tile placement assumed Jedah's OBJ band (0xAD80-0xEEBB)
was writable once Donovan replaced him. FALSE: vanilla system content
references tiles inside per-char bands — measured: the VS-fade curtain
columns draw code 0xC625 (soft smoke art in vanilla, Donovan body
chunks on the build), displayed during electric holds. Any future tile
placement must AUDIT actual vanilla references into the target window
(not just "whose band is it"), and the round-27/28/29 garble odyssey is
the cost of skipping that audit: five wrong models (stale buckets,
phantom clear, script order, phase artifacts, missing darken) before
the vanilla CONTROL RUN — always run the vanilla control FIRST when a
visual differs; it would have ended this in one session.

## Record walks that follow POINTERS miss offset-computed records
The electrocute X-ray overlays (and by implication other aux-chain
display records) are located by arithmetic (aux table + index*4), not
by any in-region pointer — a pointer-following walk never visits them,
so they silently ship with UNREMAPPED tile words and UNCOPIED art. The
tell in the data: NAT and POR OBJ dumps showing IDENTICAL raw code
values at the same pieces (a ported record should differ by the remap
delta). Fixed with a validated every-even-offset sweep in BOTH walks
(obj_records + gen) — the sweep MUST use identical rules on source and
output or the parity check trips on its own remapped values (band
window widened to cover src+dst). Also: never run pixel probes in
parallel with a running battery — three concurrent MAME instances
flaked a replay timeline into a different attract phase; standalone
reruns are the only trustworthy probe results.

## Palette rows 0x10+ belong to the P2 CHARACTER — attribute rows with a
## roster-varied control, not a same-roster control
The 14z-18 "statue rows 0x10/0x11" attribution was wrong twice over:
every probe match used P2=Victor, so rows 0x10/0x11 "matching native
vs2" proved only that both games upload VICTOR identically — and the
"statue accent family" 0x39B040 was Victor's own glow data. The
data_port that "stilled the statue" actually deadened Victor's glow in
every match including pure-legacy (superset violation, shipped in
fa89812, reverted 14z-19). Two rules paid for: (1) before attributing
a palette row/data block to a new-char object, run the VANILLA control
(P1=Jedah cell picks vanilla Jedah with the same replay — one run
showed the identical row-0x10 alternation) AND a control with a
DIFFERENT P2; (2) ROM->palette-RAM writes never transit work RAM, so
the masked legacy gate is BLIND to palette-data edits — every palette
data_port needs its own static byte guard (test_don_accent.sh
pattern).

## Hit-freeze constants are ENGINE-GENERATION tuning, not ported data —
## sibling-verified structure can still drift behaviorally
The vsavj and vs2 victim-reaction handlers are structural twins
(field-for-field), but the freeze constants inside them differ
(attacker +0x5C: 0x0B vsavj vs 0x04 vs2; victim 0x18 vs 0x0C): vs2
retuned the shared engine for its rapid multi-hits. Any ported move
whose FEEL depends on engine-side constants (freeze, shake, gravity
tables) can diverge with zero byte differences in the ported regions
— A/B-measure the engine fields (tap the obj struct at event frames
on both games), don't audit only the ported bytes. (14z-42: this one
drift WAS both maintainer symptoms — hit count and animation speed.)

## Venue-asset numerology: palette index ≠ character id; identify
## cells by MEASURING the cursor, not by suggestive constants
The select wheel's big 3x3 cell uses pal row 07, and Jedah's vsavj
char id is 0x07 — so it "obviously" was Jedah's medallion. It's
GALLON's (pal indices in the wheel record are display rows; vs2's
appended trio proves the point — Donovan's icon rides vs2 pal row
05, Anakaris' row). First 14z-49 attempt shipped Donovan's face
onto Gallon's cell (with an attr+coord retune on top). The correct
cell (Jedah's, 0xB526 at 236,57) was found in minutes once measured
properly: (a) center the CURSOR RING's pal-1e pieces over the cell
boxes, (b) color-render candidate cell art with its live palette
row and eyeball it against known faces. Both checks are one dump +
one render; do them BEFORE writing any manifest row that targets a
"per-char" venue asset. (Bonus in the same family: vs2's gold
"Donovan" icon guess was actually Huitzil — a color render against
the character's design settles it instantly.)

## The per-char OBJ bank word is NOT a display-only attribute
The per-character OBJ bank table (`PRG:0x282D4`, opcode/decrypted view,
0x18 word rows of 0x0000/0x2000/0x4000/0x6000) looks like a pure
"which gfx bank do this character's tiles live in" display attribute. It
is not: changing a row perturbs GAME STATE. Measured — the same modified
program run under MAME, which has no extended-bank support whatsoever,
diverges in work RAM at frame 890 (FBNeo diverges at 894 on the same
replay). So the word is read on some logic path as well as the sprite
path. Anything that repoints a character's tile bank must expect, and
account for, a behavioural change — it is not a cosmetic edit.

## TABLE A's shape cannot tell U/D from L/R — the direction labelling needs
## an external fact
The select screen's joystick-nibble table marks every opposing pair
illegal. That structure is SYMMETRIC under swapping which bit-pair is
vertical, so "it decodes perfectly" holds for both labellings and proves
neither. The first read of the wheel graph assumed bit0=Up and produced a
self-consistent adjacency matrix that disagreed with a known cursor path.
Pinned instead by two prior independent records (`11_pick_donovan.rpl`'s
U,U,R → `0x0F`, the atlas's L,L,D → `0x09`), which have a unique joint
solution over all 8 labellings × 16 start cells — and which also recover
the documented default cell, a third agreement that was not fitted.
Real order: **bit0=R, bit1=L, bit2=D, bit3=U**. Lesson: when a structure's
symmetry admits several readings, the disambiguating evidence has to come
from outside the structure.

## An 0xFF inside a LIVE select-wheel row is committed as character id 0xFF
(caught before shipping, 2026-08-05, 14z-60o)
The navigation routine reads TABLE B and stores the byte with **no validity
check**:

    020A78  move.b  (a0,d1.w),d0     ; new cell = row[direction]
    020A7C  move.b  d0,$3(a6)        ; committed, unconditionally
    020A80  move.b  d0,$382(a6)      ; ...as the CHARACTER ID too

The `bmi` earlier in the routine guards TABLE A's output (the direction),
**not** this read. So an `0xFF` sitting in a live cell's row is written
straight into the character id, which then indexes ~1KB past every 32-entry
per-character table. Wild pointers, not a clean failure.

Vanilla never does it: no live row contains `0xFF`, and the idiom for "no
move that way" is **self-reference** — cell `0x0B`'s Down and cell `0x0F`'s
Up both point at themselves, exactly at the wheel's bottom and top.

`tools/wheel_layout.py`'s first draft emitted `0xFF` for directions with no
cell in that sector, **and its validator passed the result** — the tool
would have produced a crash-on-Down wheel that looked fine in review. Both
halves are fixed (fallback is self-reference; `0xFF` in a live row is now a
hard error) and pinned by section 5 of `tests/test_select_wheel.sh`.

General form, and the third time this project has paid it: **a generator and
its validator written by the same hand share the same blind spot.** The
validator must encode what the ENGINE does with the data, not what the
generator intended to produce.

## There is no such thing as a free palette row on a venue screen (14z-63)

Three progressively-wrong "free row" proofs, each paid for:
1. "No OBJ references it" (sweeps over 3 replays) — missed that the
   select VENUE PHASES write rows on a ~15 s timer: the accent march
   claims the figure-family rows {0x15,0x16,0x17} (and P2's
   {0x18,0x19,0x1A}) mid-screen. A row that held only a grey ramp all
   session was being rewritten grey-over-grey — invisible to content
   sampling AND to a single-frame poke-probe.
2. Per-frame re-assertion of stolen rows measured CLEAN on stress
   replays but broke the legacy oracle in a subtle way: the fade system
   READS BACK palette RAM to compute steps, so re-asserted values
   diverge its step counters ($FF0E94/A4/B4/C4) on every transition —
   permanently, invisibly, in work RAM.
3. Retargeting the writer at "the" dest computation missed: the store
   tail (0x2AD50) has ~30 ENUMERATED entry points, many with
   precomputed dests (bsr triplets writing base+1..3 with a1 carried).
   Enumerate ALL branches into a routine before claiming a choke point.
Rules:
- Prove a row free against the SCREEN'S WHOLE LIFETIME (the timer-forced
  maximum), with a WRITE TAP, in every player configuration — content
  stability over samples proves nothing when writers rewrite same-values.
- Palette RAM is not write-only to the engine: fades read it back.
  Anything that rewrites it behind the engine's back perturbs work RAM.
- The clean lever for venue-written rows is the VENUE JOB DATA (the
  14z-15 script family), not the shared uploader code.

## A WATCHDOG REBOOT masquerades as a clean "nothing happened" (14z-65)

The forced-boot probe at id 0x10 on the stage-4 ladder build reported:
guard clean, no tripwire, P1 struct zeroed at f3600 — reading like the
char-load path politely declining. The SNAPSHOTS say otherwise: f2200
select screen, f2900 black garbled transition, f3400 THE QSOUND BOOT
SPLASH. The init path HANGS (no exception — nothing for the guard),
the game stops kicking the CPS-2 watchdog, and the MACHINE RESETS; the
"zeroed struct" is fresh-boot state.
Rules:
- Zeroed work-RAM structs + a clean guard at late frames is NOT a
  non-load verdict until a snapshot rules out the boot screen.
- The crash guard catches exceptions and tripwires, not hangs; hang
  hunting needs GUARD_PC_LOG over the ONSET window (before the reboot),
  GUARD_BREAK on the handler entry, or GUARD_TRACE under -debug.
- The probe's "load ZEROS" verdict has been renamed accordingly
  (WEDGED-or-REBOOTED); force_pick_probe now also snapshots.

## The content-twin trap: vsavj keeps byte-identical copies of engine
## code inside per-char families — hook the LIVE one, found by tracing
Searching vsavj for the byte-for-byte twin of vs2's generic jump-seq
head found 0x26A58 — which hooked cleanly and did NOTHING (0 probe
hits): it is ANAKARIS's private copy of the handler, id-routed at
0x22A0E (`cmpi.b #6` at the head). The LIVE generic handler is reached
through the class-02 stepper 0x225C4 (table 0x225EE, seq06 -> +0x420).
Find live engine handlers by TRACING the actual dispatch (GUARD_TRACE
on the acting frames), never by byte search alone — the engine
duplicates handler code per character and the copies diff identical.

## Sampling a STATE-gated effect at the wrong moment reads as "not
## reproduced" (14z-68u)

The Dark Force afterimage/recolour was written up as "not reproduced
on the current build" after measuring sprite counts and palette RAM
across replay 82 at f3050-3250 — with DF verifiably ACTIVE (seq 0x0A
confirmed). The effect is gated on the character MOVING, and that
replay's walk is at f3300-3400. Every measurement was correct and the
conclusion was wrong.
Two habits: (1) when a symptom is reported for a MODE, enumerate what
the mode gates on — active vs moving vs attacking — and sample each,
not just "during the mode"; (2) a maintainer's repro steps ("move
around, especially when air dashing") encode exactly that gating and
are worth asking for BEFORE measuring, not after a negative result.

## A MODE-gated symptom needs the MODE PROVEN ENTERED — pressing the
## input is not entering it (14z-69, cost this session twice)

Dark Force costs one banked stock. With an empty meter the P+K pair is
DOWNGRADED to a single button and the match continues normally: the
tells are `+0x109` (banked stock) staying 0 and `+0x107` reading
0xFF/0xFE. **`seq 0x0A` is that downgrade.** Every DF measurement from
14z-66 through 14z-68 was taken on replay 82, which has no stock — so
none of them were of Dark Force, including a gate that asserted "DF
activates, expires, re-activates" and the claim that DF mechanics are
already native-correct.

Two sessions of mechanism hunting followed, and then a whole A/B
concluding "the symptom does not reproduce", complete with palette
dumps over 118 frames, sprite-set equality on two emulators, and PNG
snapshots. All of it was of a match that was never in the mode. The
maintainer spotted it instantly from one screenshot: **the stage was an
ordinary stage.** DF has its own backgrounds and a cyan TIME bar under
the health bar. Poke the stock in (`$FF8509`, docs/game/atlas/ram.md +0x109)
and the same replay reproduces the defect on the first try.

**Never infer a mode flag from the fighter block by inspection.** In
one session I picked `+0x1B5/+0x1B9` and then `+0x1F4` as "DF active";
both are set by JUMPING. Derive it: dump ALL of work RAM at five phases
on BOTH games — before, during an unrelated action, twice inside the
mode, after expiry — and keep only bytes that are off/off/on/on/off
with identical values on both games. 18 bytes qualified; `$FF802E` is
the one now used, and the checker refuses to judge without it.

Rules that fall out of this, in the order they would have saved time:
1. **Assert the state, not the input.** A rig that presses the button
   proves nothing; a rig that measures the mode flag and the resource
   it consumed cannot silently drift out of the state under test.
2. **Take the screenshot early.** The visual signature (background,
   TIME bar) was decisive and free, and it is exactly what the
   "verify at the RENDER layer" entry above already told us to do.
3. **A negative result about a symptom the maintainer has SEEN is a
   bug in the rig until proven otherwise.** Report it as "I could not
   reach the state", not as "it does not reproduce".
4. A negative result about a RIG belongs to the replay that produced
   it: "the poke does not force him on vsav2" came from replay 61,
   whose timing is authored for OUR wheel, and it blocked the native
   leg for two sessions. Re-run it with a script whose timing is not
   the thing under suspicion.

## The two games' sprite-list handlers do NOT agree: a per-handler CODE
## BIAS differs between vsav and vs2 (14z-71)

Porting a character's sprite-list DATA assumes the host's drawer
interprets it the way the source game does. For three of vsav's six
list-type handlers, it does not:

| list type | vsav | vs2 |
|---|---|---|
| 0, 2 | identical (branch displacements aside) | |
| 4 | `addi.l #$38000000,d1` | `addi.l #$42000000,d1` |
| 6 | `addi.w #$3800,d2` | `addi.w #$4200,d2` |
| 8 | `addi.w #$3800,d2` | `addi.w #$4200,d2` |

Ported vs2 list data run through vsav's handler therefore addresses tiles
**0x0A00 too low** and renders whatever art happens to live there. It cost
most of a session on Huitzil's beam: the strip drew the freeze/reflection
art, and the maintainer identified it from a screenshot faster than the
analysis did.

Worse, the difference is ONE BYTE in an otherwise byte-identical routine.
A diff that reports "255/256 identical" invites "the one difference must
be a relocated address". Here it was the entire defect.

Rules:
- Before porting any sprite list, check its handler's constants against
  the host's — not just whether the routines "look the same".
- A ported handler copy must carry the SOURCE game's bias, plus any
  placement shift (Huitzil's: vs2's 0x4200 + a 0x1000 group-C shift).
- Type 4 also composes its OWN bank word (`ori.w #$2000` = bank 1) where
  type 2 takes the object's — so a tenant's procedural strips cannot reach
  a WIDE group-C bank through the record path at all.
- Frozen inventory: `tests/test_beam_list_type6.sh` section 1c.
