# engine_internals — HISTORY (blocks moved verbatim from `engine_internals.md`)

Moved by the documentation rationalization pass (14z-123 onward), one
document commit at a time. Rules: historical entries are not rewritten
(CLAUDE.md §5 [VSP-13] step 4); a correction is made where the live claim
lives, in `engine_internals.md`, and marked here only if it was already
marked when the block moved. Each block is headed by the section it left
and the commit that moved it, in the order it was moved. Blocks carry the
frontier language of their day: an "OPEN", "RETRACTED" or "ADOPTION
PENDING" here is the status AS IT WAS WRITTEN — the live document and
STATE carry the current one. No `**[PFX-N]**` anchor lives in this file.

## [14z-123 (b)] from «The WIN SCREEN subsystem — opener»

**Read this before touching any tenant's win screen.** Donovan's win
screen was fully solved in 14z-45; Huitzil's was then re-derived from
scratch in 14z-68 and got TWO of three pieces wrong, because the prior
analysis lived only in a session log. Everything a tenant needs is
below, with both characters as worked instances.

**WHICH FLOWS REACH IT (measured 14z-99, corrected by the maintainer the
same session):** the screen shows after match wins in BOTH 1P-vs-COM
(corner: PRESS START) and 2P (corner: the loser's CONTINUE countdown).
An earlier same-session reading — "a 2P-flow surface; 1P never shows it;
a legacy 2P winner skips it" — is RETRACTED: it came from two rig traps,
(a) coarse post-KO sampling landing on the MAP/tally screens that come
AFTER the win screen, and (b) mash inputs running past the KO pressing
through it (game gotchas, 14z-99). Rigs for this screen must end their
inputs at the KO and sample densely between the settle and the map.
**#105 — FIXED 14z-99 (`win_pal colors 8 -> 10`, all three builds — the
AUTO sets; gate `tests/audit_win_pal_auto.sh`; this line read KNOWN-OPEN
until 14z-114). The symptom as reported:** with AUTO (= auto-guard, a handicap
mode — the human still plays) selected by the WINNER, a TENANT winner's
portrait renders WHITE on the merged build: the `0x90C2A0` win-pal
window holds all-0xFFFF during the screen and the real colors arrive
AFTER it — the upload is LATE, not absent. Vanilla renders its AUTO
winner colored (not the engine's own behavior). Locked by
`tests/audit_win_pal_auto.sh` + `replays/103_tenant_2pwin_auto.rpl`.

## [14z-123 (b)] from «The WIN SCREEN subsystem — §3 the fetch index»

**RETRACTED (14z-73): `d0` is `0x40 + WINNER id`, not `0x60+id`.**
Breakpointing `0x5F328` at the actual win screen (replay 28 + forced
pick) measured `d0 = 0x50` for a Huitzil (id 0x10) win — so the slot is
`0x2672AA + 4*(0x40+id) - 4`; for id 0x10 that is `0x2673E6`. The
14z-68/NEXT_SESSION `0x60+id` (index `0x6F`, slot `0x267466`) was wrong;
repointing it changes nothing (measured — hui27 did exactly that and the
screen was unchanged). There is no separate P2 slot in evidence — the id
is the WINNER's, and the arcade win screen (the one with the CONTINUE
counter) always has a P1 winner.

## [14z-123 (b)] from «The WIN SCREEN subsystem — §3 the portrait array»

**The PORTRAIT already WORKS and is a DIFFERENT array from the quote.**
The `[[select_records]]` entry misnamed `win_quote` in `huitzil.toml`
ports Huitzil's victory PORTRAIT correctly (renders since hui16,
maintainer-confirmed hui26): it reads array `0x2A06E2` (index id, NO `-4`
bias) and pokes vsavj `0x2673ea` <- the placed vs2 `0x2A881E` = Huitzil's
portrait record (tiles bank-1 `0xb7xx`, pal 15-19). Its tiles ARE placed.
Do NOT touch it — a 14z-73 attempt to repurpose it for the quote stopped
poking `0x2673ea` and BROKE the portrait (self-inflicted "placeholder"),
reverted. The `d0=0x50 -> 0x2673E6` fetch measured at `0x5F328` was some
OTHER piece; poking `0x2673E6` changed neither portrait nor quote, so it
is not the lever for either.

## [14z-123 (b)] from «The WIN-QUOTE TEXT SYSTEM — §5 the retracted index-space reading»

**RETRACTED (mine, same session):** I first diagnosed this as the INDEX-SPACE
class — "table A is authored only to `0x1EF`, the tenant reads `0x263` in a
zero region and falls back to a default". That is wrong. **Table A
(`0xC912`, vs2 `0xB1EA`) is not the per-character selector at all** — it is a
special-matchup flag, near-entirely zero in BOTH games including for vs2's own
newcomers, its one non-zero being winner 0x01 vs loser 0x01 (a mirror match).
Zero there is the correct default, not a fallback. The deadness measurement I
took of that span is sound but measures a span the fix does not need.

## [14z-123 (b)] from «The projectile-pool HIT-CLASS map — adoption»

Fix — **ADOPTED, not pending** (corrected 14z-91; the "ADOPTION PENDING"
here contradicted HANDOFF's registry row for a whole session). The
`hitclass_map_extend` site_thunk is declared by `huitzil.toml:2048` and
`pyron.toml:1044` and is present in their builds; it was maintainer-adopted
2026-08-12 and huitzil-m4 / pyron-m3 were re-frozen on it.

## [14z-123 (b)] from «The projectile-pool HIT-CLASS map — the falsified deadness claim»

**Because it IS shipped, it is a live hook on a SHARED engine site**, and
**its "legacy never enters the map" evidence was FALSIFIED by measurement
(14z-92, M4).** That claim rested on two census replays, and both of them
happen to score zero. Over the 46-replay legacy corpus legacy enters the map
**230 times** (`24_don_winmash` 2, `26_don_arcade_mash` 228). The fix is
still sound and the argument is now the true one: every observed legacy index
is 0x02/0x04/0x09/0x0b, far below 64, so legacy reads VANILLA's own bytes out
of the thunk — "legacy enters constantly and receives vanilla answers", not
"legacy never enters". Corroborated by 43/46 bit-identical in the same run.
It was the same coverage shape that falsified the list-type 6 deadness claim
and produced the 14z-91 legacy regression, and this time it did fire. It is a `jmp` over `0x1A888` plus a
`cmpi.w`/`bcc` on every collision-map lookup. The dispatch is per-COLLISION,
not per-frame, so it is far colder than the obj_hook site was — but if a
legacy replay ever fails to re-converge and the walker relocation is not the
cause, look here next and re-run `tests/audit_hitclass_map_cost.sh`, whose
corpus IS the full 46 legacy pairings since 14z-92 (it had a four-replay
default until then).

## [14z-123 (b)] from «The projectile-pool HIT-CLASS map — the RETRACTED 14z-92 blockquote»

> **RETRACTED 14z-92.** This paragraph used to end "Legacy content measured
> entering this map ZERO times across four replays — the sweep serves
> secondary-object collisions vanilla content doesn't produce there." The
> four-replay figure was falsified by the corpus-wide run: legacy enters
> **230 times** (see the paragraph above). The sentence survived four lines
> below its own retraction for a session — the §5 failure mode exactly.

## [14z-123 (b)] from «THE CAPTURE-POSE INSTALLER — the superseded 'two exceptions' reading»

**(A superseded reading, kept for the record: "the two exceptions are the
useful part / read them first — their 32-entry tables are the shape the
fix needs" — RETRACTED the same session, 14z-99.** Zabel `0x04` and the
special slot `0x0B` do carry 32 distinct offsets at uniform `0x190`
stride, but their variant-half sub-blocks measure as BYTE-COPIES of the
base sub-blocks, 15/16 rows with `0x1F` the exception — the SAME defect
stored as materialized content, not populated tenant data.)

## [14z-123 (b)] from «THE CAPTURE-POSE INSTALLER — the 'MEASURED FEASIBLE' design-record framing»

**SHIPPED 14z-99 — the 15 `capture_kf` slot_rows data_ports
(`../project/patch_notes.md` "14z-99 — the window", gate
`tests/test_capture_pose_sources.sh`); this heading still read "MEASURED
FEASIBLE" until 14z-114.** The design record as it was written:
**THE FIX IS MEASURED FEASIBLE AND ITS SHAPE IS SETTLED (14z-99;
maintainer-ruled option (a) — full — conditioned on these measurements,
which came back clean; every premise below is frozen in
`tests/test_capture_pose_sources.sh`):**

## [14z-123 (b)] from «The DAMAGE pipeline — the +0x1D -> +0x17 correction note»

(copied from the hit record, byte **+0x17**
of the 0x20-stride hitbox/hitbox_proj records — CORRECTED 14z-120 (5): this
line said "+0x1D", an offset counted from the region start rather than the
record base; the shipped Huitzil rows at `hitbox_proj +0x17D/+0x19D` ARE
+0x17 of projectile records 5 and 6, see "Hitboxes and attack records")

## [14z-123 G2 #3] from «Reactions as the victim — the second step family sentence»

The
  sibling family at `0x27082` (three lists at `0x2797A`: 91 / 115 / 157 px,
  fast-decaying, counter `+0x1B0`) runs while `+0x185` is set — and
  `+0x185` is set on the OTHER fighter by `0x2681E` when a mash counter
  `+0x170` (`+= (d1>>1)+1` per input) reaches 10, together with a facing
  flip and `+0x171/+0x184/+0x5C/+0x3B5` on the masher: the shape of a THROW
  MASH-ESCAPE pushing the thrower away (read, not measured — 14z-121 (4)).

## [14z-123 (a)] from «THE SYNTHESIS BACKLOG (the status paragraphs and the empty FORM table)»

## THE SYNTHESIS BACKLOG — CLEARED 14z-68n, re-swept 14z-71; the table is kept as the FORM

*(Header corrected 14z-114: it still read "NOT YET SYNTHESISED — the standing
backlog (audited 14z-68m)" three status paragraphs after its own
"CLEARED". The intro's "other subsystems are still scattered across the
atlas / reconciliation.md / patch_notes — fold them in as they get touched"
is likewise the session-14 state; every subsystem below has a section now.)*

**This document is thin relative to the analysis that exists.** Measured
at 14z-68m: engine_internals 810 lines vs STATE.md 8417 lines. Most
subsystem knowledge still lives only in session logs, which is where
the 14z-68 win-screen re-derivation came from (Donovan's solution was
in STATE since 14z-45; nobody could find it from the task).

**Policy:** when you work on any subsystem below, write its section as
part of that work — the marginal cost is small while the analysis is
fresh in the session, and it is the difference between "documented"
and "findable". Delete the line when the section exists.

**STATUS 14z-71: swept again, at the maintainer's request.** The gap
ratio is down from ~10:1 (14z-68m: 810 vs 8417 lines) to ~4.5:1 (2118 vs
9643). No subsystem is now absent from the docs — but the sweep found a
worse failure than absence: **three section HEADERS described superseded
states**, and one of them ("the 214+P grenade explosion — NOT a
tile-inventory defect") asserted the opposite of what was later measured.
A skimmer reads headers. When a finding is overturned, fix the HEADER in
the same commit, not just append a subsection under it. Two new documents
came out of the same sweep: `atlas/sprite_lists.md` and
`../project/porting_code_regions.md`.

**STATUS 14z-68n: the audited backlog is now CLEARED** — all eight
subsystems below were written the same session the gap was found
(object type dispatch + pool walker, allocator wrappers, pool seeding
/ init_shim, update-queue classes, throw/physics arcs, shadow
servants, Dark Force, companion/pod family). The table is kept as the
FORM to use next time: when you find a subsystem living only in
STATE, add a row, then delete it by writing the section.

| Subsystem | Where the analysis currently lives | Why it will bite |
|---|---|---|

## [14z-123 (a)] from «OBJ pipeline — the M2b slot-0x0F placement HISTORY block»

**HISTORY — the M2b (slot-0x0F substitution) placement, superseded by WIDE
group C at M3a / 14z-67 (the paragraph above); kept for the inventory
figures and the exclusivity method (status marked 14z-114).**
**M2b consequence: DONOVAN FITS IN JEDAH'S MAIN BAND** (extent 0x3CB1 <=
0x417F, 15,171 <= 16,658) — no gfx ROM expansion needed for him. Port
shape: (1) re-encode Donovan's tile data into vsav gfx members at
Jedah's band positions (bank 2, 16-aligned constant delta); (2) add the
same delta to every main-band tile word in his ported anim records;
(3) patch his hardcoded #$6000 bank setters to #$4000 (slot-0x0F table
row already provides 0x4000 for free); (4) map the 112 shared-effect
tiles via the content-addressed vsav2->vsav relocation map (their art is
shared, positions differ). Exclusivity (measured, session 14): player-OBJ side, Jedah's band is
exclusive across all 0x18 slots EXCEPT Sasquatch (slot 0x0A, also bank
2) sharing 44 tiles at the band head, 0xAD3E-0xAD74 — the safe Donovan
placement floor is 0xAD80 (16-aligned), leaving extent 0x413C >= the
needed 0x3CB1. Caveat: slot 0x04 (Zabel) walked to 0 records (walker
gap — different format or region bounds; he is bank 3, so no
Jedah-band conflict either way, but close the gap before trusting the
walker for other purposes). Remaining exclusivity unknowns: STAGE
(scroll) tiles — scroll layers address the same 32MB via their own
banking, and Jedah's stage is LEGACY content (all stages stay); the
scroll-side inventory must confirm the absolute range 0x2AD80-0x2EEBB
holds no stage art before any tile write. Also open:
portrait/name tiles (select screen) are a separate inventory; Anita's
bank attribution rides the same +0x18 machinery (her spawn sets it).

## [14z-123 (a)] from «OBJ pipeline — the M2b tile-data step (session 14)»

### M2b tile-data step (session 14, static build + verification)

`tools/build_gfx_donovan.py`: places Donovan's 15,171 main-band tiles
from vsav2 group-B simms (bank 3) into copies of vsav's group-B simms
(bank 2) at delta +0x2750 — placed codes 0xAD8F-0xEA3F, above the
Sasquatch-shared head, inside Jedah's band. Uses the canonical
extraction plus its verified inverse (`gfx_tiles.write_tile`;
scatter-back round-trip asserted on every placed tile). Verified every
untouched tile byte-identical. Emits `remap_spec.json` (delta, band,
bank words) for the PRG-side patcher. Visual check: placed range
renders Donovan sprite art.

STAGE 6 BUILT (fingerprint 06f99f4e…, statically verified end to end):
generator gfx_remap pass rewrites the 13,171 main-band tile words in
all 1,122 OBJ records (runs post-relocation — record/coordinate
pointers validated against PLACED addresses); six #$6000 bank setters
port_patched to #$4000 (stage-gated rows); [table_fix] pads x026142 to
0x1440 and rewrites the WHOLE ported per-char bank table with vanilla
vsavj values — fixing two stage-5 latent defects: the table was
truncated at row 9 (the x088512 effect caller d0=0x0A read past the
ported end) and carried VS2 bank values (row 0x0F = 0x0000 => bank-0
reads — likely THE main-sprite garble mechanism; and it WAS: the garble
  did not recur after this rewrite, `tests/test_m2b_stage6.sh` green — a
  hypothesis confirmed by its fix, marked 14z-118). Output-image checks:
placed records walk clean, band exactly 0xAD8F-0xEA3F matching the
placed tiles, table decrypts to vanilla values, setters #$4000. The
rompath carries the patched vsav.zip (ROMDIR pristine); stage-5
rebuilds still reproduce frozen a02aeeff byte-identically.
Still open before playtest-ready graphics: the effect-record map — 85
of 114 low-code effect tiles resolve content-addressed into vsav
(scattered banks 0/2 => per-record bank+code remap; one record = one
object = one bank), 27 unresolved (effects stay garbled this stage,
never crash — tile codes cannot fault); portrait/name (select screen)
tiles; in-emulator verification (QUEUED).
In-emulator verification queued behind the maintainer's machine
availability, incl. the scroll3-vs-band watch (stage art exclusivity has
strong static evidence — 99.3% band saturation by Jedah's own records +
visual — but the frame-level confirmation wants a Jedah-stage replay).

## [14z-123 (a)] from «OBJ pipeline — M2b in-emulator verification (session 14c) + the struck freeze list»

### M2b in-emulator verification (session 14c, machine window)

All green on stage-6 fingerprint 71601263:
- tests/test_m2b_stage6.sh (the permanent M2b gate): stage-6 build with
  static output verification inside, five guarded soaks (moveset, DP
  spam, round-2, input chaos, 40K arcade marathon) END-clean, and the
  full masked legacy gate — flicker inventory UNCHANGED (the gfx work
  perturbs zero bytes of legacy live RAM).
- Oracle + dual-emulator + flavor gates re-run against the stage-6
  rompath: PASS (HP trajectories, anchors, latches identical to the
  frozen-stage behavior).
- tests/test_m2b_scroll3.sh: scroll3-vs-placement exclusivity measured
  live — tests/lua/scroll3_watch.lua scans the scroll3 tilemap every
  frame; 0 danger frames over the attract stage rotation, the arcade
  marathon, and match replays. The scroll3 base register is write-only,
  written ONCE at boot (PC 0x926, base 0 => map at VRAM 0x900000;
  proven constant across 42,000 marathon frames via trace_writes
  WATCH=800106). MAME Lua traps recorded: emu.register_frame_done is a
  single slot (replay.lua clobbers it — use add_machine_frame_notifier)
  and add_machine_*_notifier subscriptions must be pinned in globals.

~~Remaining before an M2b freeze: select-screen portrait/name art (+their
palettes, vsavj 0x3B5988/0x3BAEA8 family), the attract palette path
(0xB0AC/0x3A3CA0), and the x2b7ef4 engine-effect tail (385 non-same-idx
tiles — minor effect artifacts if any).~~ *(M2b-era list; the select art
and palettes shipped 14z-62/63 (`atlas/select_screen.md`), the effect
family closed 14z-71; the `0x3A3CA0` pool MEASURED 14z-123, above.)*

## [14z-123 (a)] from «Select screen — the M2b 'Jedah's select art' bullet»

- Jedah's select art: ~2,000 tiles at codes 0xAxxx-0xBxxx in BANK 1
  (menu objects run +0x18 = 0x2000) — absolute ~0x1A5xx-0x1B9xx; freed
  when he goes. Donovan's equivalents: vs2 root table `0x2A05E2` rows
  0x13/0x33 (P1/P2) + the newcomer select-data zone 0x2A1FDC-0x2A8xxx
  (records/structs; NOT part of any ported region yet), art in vs2
  bank 1 (the 0x10EF6-0x12728-area vsav2-only clusters).

## [14z-123 (a)] from «Select screen — phase 1 attempt (14d), phase 2 (14e), phase 2 SHIPPED, the gate anomaly, select palettes + splash/win map (14f)»

Phase-1 attempt (session 14d) — measured corrections to the map:
- THE LIVE PREVIEW at select ALREADY WORKS in stage 6 (obj $FFB880
  carries [0x1C] into the ported anim region with bank 0x4000).
- The still-Jedah elements at frame 2000 (patched build, live dumps):
  big portrait = obj $FFB980 [0x1C]=0x267462, frame piece = $FFB900
  [0x1C]=0x2675E2, more pieces $FFB800/BA00 at 0x2689FA/0x268A3A,
  wheel = $FFBB00+ at 0x268B8A+ (shared). These chains are INLINE
  POINTER ARRAYS in the shared web (plain 4-byte record pointers, the
  walker's flag bytes overlap pointer bytes — semantics still not fully
  decoded), NOT reached through the three cells phase 1 poked: pokes at
  0x26739A/0x26768A/NAME_ROW landed and changed nothing on screen.
- A Demitri-pick dump shows menu objects riding the SHARED element
  window (0x267F32-0x267F72) during select — the 150-entry records are
  most likely the WHEEL (15 chars x 10 entries) *(14z-118: SUPERSEDED — the
  wheel record is `PRG:0x272A68`, fmt 2, count 17, measured in
  `atlas/select_screen.md` "wheel record"; this M2-era attribution was
  wrong about the address and the count)*; the per-char big-art
  group attribution (0x2719xx Jedah confirm records etc.) still needs a
  two-char differential dump AT THE HOVER moment.
- SPACE FACT for the eventual port: both PRG holes are nearly full
  (hole A free ~0xE80, hole B ~0x32A0); the ported select web (~51KB)
  must live in JEDAH'S FREED ANIM REGION [0x248B88, ~0x267000) — pure
  slot-0x0F data orphaned by the port; the shared tail 0x267xxx+ is
  live and must not be overwritten.
tools/select_port.py holds the phase-1 machinery (zone extraction,
structure-walked relocation, prg-dir chaining) — NOT wired into the
build until the real per-char handles are proven by differential dumps
(hover-moment, two chars). ~~Next session: dump $FFB980's [0x1C] at the
HOVER frame for two different picks; diff the group spans; patch the
inline pointers in place (32-bit, slot-0x0F rows only).~~ *(DONE — phase 2
below; and the whole in-place approach was retired at 14z-62 when the
tenants moved to variant ids: `atlas/select_screen.md` "The RECORD-POINTER
array". Marked 14z-114.)*

### Select-screen phase 2 (session 14e): the real handles, empirically

Differential cursor dumps (menu objects at frames 960-1100 of the pick
replay) settle it:
- The three still-Jedah UI pieces ride PER-WHEEL-SLOT pointer arrays,
  advanced by CURSOR MOVEMENT (stride 8 per wheel step): big portrait
  (obj $FFB980, array ~0x267416+), name/frame (obj $FFB900, ~0x267596+),
  highlight (obj $FFBA00, ~0x2689F6+). Jedah's record cells: [0x267466]
  = 0x271CE8 (big portrait, fmt 2, 17 entries), [0x2675E6] = 0x27221A
  (name), [0x268A3E] = 0x2724A2 (highlight). P2 arrays are +0x40 copies
  POINTING AT THE SAME RECORDS — replacing record CONTENT fixes both
  sides with zero pokes.
  **CORRECTED 14z-61 (docs/game/atlas/select_screen.md, measured):** that
  `+0x40` block is the **VARIANT HALF** (rows 0x10-0x1F, byte-identical
  aliases of 0x00-0x0F), not the P2 array. It looks like P2 from a
  differential dump precisely because it aliases. The real player offset is
  **+0x80**, confirmed both in the consumer code (`d1 = 0x80` at
  `PRG:0x06C0E0`) and in-emulator (P2's object fetches its own record from
  the +0x80 block). The in-place conclusion still holds for slot 0x0F — the
  two players' rows point at the same records there — but the reason
  matters for M3a: at a variant id the tenant has its OWN rows in both
  blocks, so the mechanism becomes a two-long repoint instead of content
  surgery.
- Donovan's equivalents (live dump on real vsav2, oracle replay, cursor
  on him): records 0x2A63F0 (7 entries, 38B) / 0x2A657E (14B) /
  0x2A6750 (14B) — ALL SMALLER than Jedah's → in-place replacement
  fits, coordinate lists fit inside Jedah's cptr space likewise.
- Art: Donovan needs 106 bank-1 tiles (9 blocks incl. an 8x8 portrait
  core); Jedah's select-only exclusive scatter (106 positions) cannot
  host the 8x8, but his full select+confirm family exclusive art
  (1,173 positions incl. the VS-bust rectangles) fits all 9 blocks
  (greedy fit verified; placements recorded in session log).
- ~~OPEN SAFETY GATE before writing tiles~~ *(M2b-era item, SUPERSEDED
  14z-63: the wheel art no longer borrows any vanilla positions — it lives
  in group C bank 5 at `0x10000+code`, zero collisions by construction,
  `tests/test_wheel_bank5.sh`; marked 14z-118)*: the placements borrowed from
  what was believed to be Jedah's VS-splash bust art; the in-match
  module family (root table vsavj 0x0B76C0, helpers 0x3C6CE/0x3DE84 —
  STRUCTURE DIFFERS from the select table, chains did not parse) must
  be empirically dumped (VS-splash frame OBJ list) to prove no OTHER
  character's splash tiles overlap the chosen positions. Then:
  select_port phase 2 = in-place record surgery + tile placement +
  code remap, verified by select-screen snapshots + the M2b gate.

### Select phase 2 SHIPPED (session 14e, fingerprint e98a357a)

In-place record surgery works: Donovan's big portrait and name banner
render on the select screen (snapshot-verified, both the hover and
speed-select phases). tools/select_port.py replaces Jedah's two records
(0x271CE8 big portrait, 0x27221A name) with Donovan's (both smaller;
coordinate lists overwritten inside Jedah's own list space; tile codes
rewritten to the placements), and build_gfx_donovan places the 101
bank-1 tiles into Jedah's freed select/splash art (group-A members now
patched too). The third piece (cursor highlight 0x2724A2) is
deliberately NOT replaced: its vs2 coordinates assume vsav2's wheel
geometry — replacing it drew a displaced label. Remaining select
cosmetics: wheel face (background scroll art), highlight ring, VS
splash bust + win screens (the 0x0B76C0 in-match family), attract
palette. *(Status 14z-114: the ring shipped 14z-63 ("Ring reuse"), the win
screen 14z-68m/73 below, the medallions 14z-63 (bank-5 move); what is
still open is the cosmetic backlog in STATE — win-quote TEXT, ladder
names/pictures, wheel polish.)*

GATE ANOMALY (recorded per the CLAUDE.md §4 standing watch): one gate
invocation showed 02 masked-diverged + 10 with 84 divergent frames from
frame 663; the SAME build then passed 02/10 individually (twice,
deterministic, exact frozen inventory) and a full gate rerun was
entirely green. Unreproduced one-off — possibly environmental; the
masked-legacy helpers now PRESERVE failing logs (build/gate_failures/)
so any recurrence self-documents with a RAM-diffable log. If it recurs,
stop and root-cause before any freeze.

### Select palettes + the splash/win map (session 14f)

- SELECT PALETTE FIXED (playtest round 7): the portrait/name palette
  rows upload from an 11-variant x 16-char grid at vsavj 0x3AC000
  (uploader 0x5F136: row = base + (variant*16 + char)*0x20, char from
  the +0x382 select id; palette RAM rows 0x1B/0x1C). vs2 special-cases
  Donovan in code (0x6B1A0: cmpi #$13 -> += 0xC6): his 10 variant rows
  at 0x3C117C + (0xC6+v)*0x20. select_port overwrites Jedah's 11 grid
  slots in place (clamping to Donovan's last row). Battery green
  (fingerprint 4fc8d14b).
- VS SPLASH / WIN SCREENS mapped: the busts are drawn by objects
  ($FFC100/$FFC180) whose [0x1C] anchors are ROOT-TABLE CELLS in three
  char-scaled families — d0 = char, 4*char, and 0x80+char (P2 = +0x20
  within each) — over the same table (0x2672AA; vs2 0x2A05E2). The
  chains are multi-record slide-in animations whose record sizes do NOT
  pair with Jedah's => in-place replacement impossible; the port needs
  the phase-1 zone machinery (vs2 web -> Jedah's freed region,
  structure-walked relocation) + SIX cell pokes. Blocking decode: exact
  chain termination (flag-byte semantics of the 8-byte structs) so the
  per-chain record/tile inventory is exact (naive walks wander into
  neighbors' chains); then art placement (Jedah's freed pool: ~1,072
  positions left after the select placements).

## [14z-123 (a)] from «Reactions as the victim — the struck 'own table' reading and its retraction»

- ~~**Every tenant's reaction set is its OWN table, entered by the class**
  (Donovan's and Huitzil's in table `c`, Pyron's in table `b`)~~ **RETRACTED
  14z-121 (2): that was a LABELLING artefact.** A reaction node sits on
  MANY chains — the same node is indexed from several seqs of table `b` AND
  of table `c` — and `reaction_map.py` labelled it by whichever chain the
  decoder enumerated LAST, which differed per tenant with the decoder's (then
  truncated) table bound. Labelled deterministically (the previous node's
  chain, else the entering chain with the smallest seq), **the three
  tenants' reaction paths carry the SAME canonical seqs**: light/medium
  `b:0x03`, heavy `b:0x03 -> b:0x23`, the sweep knockdown `b:0x09 -> 0x0a ->
  0x0b -> b:0x44`, an air hit `b:0x03 -> b:0x2a -> b:0x14 -> b:0x15 -> b:0x44`
  (Pyron `b:0x19 -> b:0x2a -> b:0x14 -> b:0x29 -> b:0x44`), a throw `c:0x01`
  (Donovan) / `c:0x0d` (Huitzil) / `c:0x02` (Pyron) held, the block stance
  `a:0x13`/`a:0x14`, the stand `a:0x00` — a cross-character CONVENTION of
  the anim index (the per-victim pose index of [VSE-44] reads the same
  way). The eliminations of 14z-120 (7) (which class enters which nodes,
  the stun lengths) stand; only the "own table" reading is withdrawn.
  `tests/expected/reactions_<tenant>.txt` re-frozen 14z-121 under the
  deterministic rule.

## [14z-123 (a)] from «Reactions as the victim — the struck 'not a velocity' sentence and its retraction»

~~**What moves the
  victim on a light/medium hit is not a velocity** (`+0x40` stays 0): the
  only writer of the victim's x through the stun is the PUSHBOX SEPARATION
  routine~~ **RETRACTED 14z-121 (3) — the 14z-120 (12) tap had watched a
  light hit while the fighters still overlapped and saw only the separation
  routine's first frames (`0x17D5C`, +0..+8).**

## [14z-123 (a)] from «In-fight HUD — the M2b 'Select wheel (the medallion ring)' subsection»

### Select wheel (the medallion ring)

ONE static OBJ record, no rotation, no hover zoom — the cursor ring
(pal-1e pieces) is the only thing that moves:

- Record at data `0x272A92` region (pairs start `0x272A72`): 18
  (code word, attr word) pairs; a header longword `0x0032A50A`
  points at the coordinate list (center-relative x,y word pairs;
  wheel center raw ≈ (256,176); list byte-identical to vs2's at
  `0x303AAC` for the shared 18 entries).
- Cells are fixed perspective sizes: 3x2 close, 2x2 far, ONE 3x3
  (the top-front cell). Cell → char map is by ART, not by pal
  index: **the 3x3 pal-07 cell at (264,64) is GALLON's** (werewolf
  face); **Jedah's cell = code 0xB526 attr 0x1214 pal 14 at
  (236,57)** — the purple wing-wrapped icon, the cell the cursor
  ring brackets when picking slot 0x0F (ring center (256,72),
  replay 58).
- Palette: each cell owns a select-venue palette row (row == attr
  pal index). Row sources live in two 32-row blocks: A `0x3A3800`
  (the wheel view — live-verified rows land at `90C000 + row*0x20`
  with the bright nibble forced to F) and B `0x3A3C00` (another
  sub-venue; its row 14 content differs — only block A's row 14 is
  the wheel's).
- vs2's wheel: same record family at `0x2A6D8C+` with THREE record
  variants (base 18-cell + two 21-cell variants appending the
  newcomers) — there Jedah is demoted to 3x2 `b113 1207` and
  nobody is 3x3. The vs2 newcomer icons: Donovan = `0xB10B` 3x2
  (vs2 pal row 05), Pyron = `0xB0F5` (row 11), Huitzil = `0xB108`
  (row 13, the gold one). Identified by color render, NOT by pal
  numerology (see GOTCHAS).
- Donovan-on-slot-0x0F fix: art `'0xB10B,3,2' -> '0xB526'`
  (effect_tail), colors data_port `med_pal_row14_a` (block A row 14
  <- vs2 `0x3BAFDC`). Record and coords untouched. Gate:
  test_don_colors select section (frozen row 14 + record-intact +
  Gallon-cell tripwire).

## [14z-123 (a)] from «Sound — the id-space result's 're-diagnose before unstubbing' note»

The session-5 "same-id means music in vsavj" theory
is dead — the 214P/214K music bug's real mechanism must be re-diagnosed
(suspect: the per-char dispatcher table indirection `(6,a0,d2.w)` or
corrupted id flow through the farm path) BEFORE unstubbing. **ROOT-CAUSED
14z-52 (STATE_HISTORY "M5 phase 1: music bug root-caused"); this sentence
stood as an open item until 14z-114.**

## [14z-123 (a)] from «Sound — the 'sample ROMs are FULL / maintainer decision material' note»

Sample ROMs are FULL (no blank 64K blocks) — porting voice
samples means growing the QSound region (descriptor change) or
sacrificing content; maintainer decision material. **DECIDED and SHIPPED:
the WIDE profile's 16 MB QSound region (`../project/cps2_wide.md`) and the
M5 voice batch (14z-86, "The QSound Z80 driver" below). Marked 14z-114.**

## [14z-123 (a)] from «Sound — the trap's real sfx bullet, as written with its two in-line corrections»

- **The trap's real sfx (measured end-to-end 14z-85g):** the
  spawn-EJECT sound is per-node record node 10 (id 0x0739, dispatched
  on Phobos' anim context via the record path); the TIMER-DETONATION
  sound is NOT a record dispatch — it is **sound-farm stub vs2
  `0x4F2E`** (`jsr $330E; move.l #$73A,d1; bsr helper; jmp $3306`),
  jsr'd from the mine handler at `x068458+0x120`. vs2's engine
  carries a FARM of such one-id stubs around 0x4EE0-0x4F60. vsavj
  keys MUSIC-family content at the same 0x7xx ids — but 0x73A's
  SAMPLE CONTENT is byte-identical in vsav's own QSound image
  (0x6C0000), keyed as the 0x198/0x199 family [CORRECTED 14z-95,
  GitHub #93: identical for 20,480 of 20,481 bytes — the INCLUSIVE
  endpoint 0x6C5000, the byte packing law #3 says is PLAYED, differs
  between the two games' original sample ROMs (vsav 0xFF, vsav2
  0x00)]: the restoration is a
  synthesized vsavj twin stub playing 0x199 (kind=sound_stub recon
  row, huitzil-m9), no sample port needed. ~~0x739 has no vsavj
  equivalent~~ CORRECTED 14z-86: 0x739's sample content, sample
  record (#0x5C, bank 0x18 @0x18D800) AND note-table-1 entry 0x28
  all exist on vsavj — only the Z80 SONG (id row + song block) is
  missing; see "The QSound Z80 driver" below. CAUTION for future
  silencing calls: a 0x7xx id's FAITHFULNESS is a property of its
  sample CONTENT, not its number — content-search vsav's image
  before writing a stubbed_sound row.

## [14z-123 (a)] from «Sound — the Z80 driver's file-mapping trap narrative»

**THE FILE-MAPPING TRAP that poisoned 14z-85d (read this first).**
MAME loads `vm3.01` split: file 0x0000-0x7FFF at region 0, file
0x8000-0x1FFFF at region 0x10000 (`ROM_CONTINUE`), `vm3.02` at region
0x28000. The 14z-85d session assumed region==file+0 above 0x10000 and
derived "id table at FILE 0x11006, entry for 0x119 = `33 07 50 18`" —
bytes read from the WRONG file offset that happened to look plausible.

## [14z-123 (a)] from «Sound — the per-node sfx dispatch SECOND PASS (RETRACTED 14z-87), whole»

### The per-node sfx dispatch, second pass (14z-86) — RETRACTED 14z-87;
### superseded by "third pass: the VOICE-CLASS BORROW" directly below

[RETRACTED 14z-87 — kept for the eliminations; the conclusions are
superseded. What survives: the dispatcher head decode (`move.b
(0x382,a6),d1; lsl.w #2,d1; lea $BF41A,a0` @vsavj 0x27F16, vs2 twin
0x2716A), the per-game anim-node divergence (vsavj node 13 / vs2 node
28, anim bytes 0x0D@0x1FDF20 vs 0x1C@0x19D832), and the rig. What was
WRONG, each re-measured 14z-87: (1) "the dispatch reads class 0x0C on
both games / the class-0x0C arrays are byte-identical and 0x29B sits at
their node 28" — 0x29B lives at class row 0x07/0x17 node 28 in BOTH
games (exhaustive 32-row × 48-node scan), the 0x0C arrays are NOT
byte-identical over their extent, and the classes actually read were
run-varying (see below); (2) "who writes the class is unmeasured;
mirror-write suspected" — the writer is PRG:0x0AEF6, it fires ~536
frames BEFORE the watched window, and no RAM mirror exists (the MAME
cps2 map is one flat range); the "invisible write" was an artifact of
correlating a STATE-DEPENDENT value across different runs
(docs/platform/gotchas.md, 14z-87); (3) the row-0x1C fix design is dead
— the class is a dynamic borrow result, not a 0x0C constant.]

## [14z-123 (a)] from «Sound — the voice borrow's 14z-87b rig-90 correction bracket»

[CORRECTED 14z-87b: the
  "plant-end fires authored 0x6A" measurement came from rig 90, which
  NEVER FORMED A MATCH (no joins/confirms — the captures observed a
  timed-out CPU game; gotcha filed). On the REAL plant (rig 91, match
  verified by snapshots + ring) the plant fires authored voices
  0x5D/0x62 (vs2 0x705/0x70A). The borrow-mechanism findings stand —
  they were measured on a real (if unintended) running match.]

## [14z-124 (c)] from «THE DARK FORCE PALETTE-SEQUENCE BLOCKS — the two struck 'Anakaris' specimens»

~~**STRONG INFERENCE, NOT A MEASUREMENT:** the routines hardcode seven base
constants — `0x1E 0x26 0x44 0x6F 0xAA 0x264 0x29C` (e.g. `0640 001e` at
`0x02a92c`). Six have measured owners above. The seventh, **`0xAA`, has no
measured owner and Anakaris is the one character not measured**, so `0xAA-0xAD`
is very probably his. Treat it as OCCUPIED until someone reaches his DF.~~
**RETRACTED 14z-118 — the inference was FALSE, and so was the next one.**
Anakaris reached his DF and requested nothing; `0xAA-0xAD` is requested by
no character's Dark Force (all sixteen base ids on rig 97). The whole-corpus
phase-A census that followed (73 vsavj-targeted replays, every leg END-clean,
uncapped, 23,800 calls — `tests/expected/palette_seq_ids_corpus.txt`,
`REPLAYS=all tests/audit_palette_seq_ids.sh`) did not request `0xAA-0xAD`
either — **but it requested `0xAE-0xB1`, from a CPU Sasquatch, and the
routine table then showed the `0xAA` base sits in SASQUATCH's row.**
`0xAA-0xAD` is his P1-side half (`+0x381` = 0). **NOT FREE.** The "no known requester ->
candidate free" reasoning this paragraph carried for an afternoon was the
census fallacy the family rule above names: a block can be owned and never
requested by the corpus. The deferred "give Phobos his own block" fix must
find a block by reading `0x02A8A4` and its routines, not by measuring
absence. *(Both retracted paragraphs are kept struck as the audit's
specimens: an inference that read as a fact for 39 sessions, and its
replacement that lasted one session.)*

## [14z-124 (c)] from «Dark Force — the 14z-79 status blockquote (SUPERSEDED 14z-84; inferred_claims row 10)»

> Status **as written 14z-79 — SUPERSEDED 14z-84 ("THE TENANT ANSWER", the
> gold block in wide_ext reached through the per-character palette-routine
> row, shipped in huitzil-m6)**: the DF palette is **OPEN**, and his DF is purple on purpose.
> The 14z-69p `[[data_port]]` row that rewrote palette-seq rows
> 0x1E-0x21 is WITHDRAWN: those ids are **Bulleta's Dark Force block**
> (236 resolver calls in one vanilla DF, measured), so the row rendered a
> legacy character wrong on every Huitzil build from 14z-69 until 14z-79.
> Phobos only lands on her ids because row 0x10 of the per-character
> palette-routine table `0x02A8A4` is `0x004A` — row 0x00's handler — and
> the base id is hardcoded in that routine (`0640 001e` at `0x02a92c`).
> The collision is structural: in vs2, slot 0x10 IS Huitzil and id 0x1E is
> HIS (180 calls, `$FF802E`=1, measured native). Repointing the row at
> vs2's `0x0040` has an **unknown** outcome (RETRACTED 14z-79b: "that routine
> has no DF path at all" came from reading five instructions at `0x02a8e4` and
> not following the `bne.w` to `0x030ee8`; char `0x04` shares that same row
> value and DOES request `0x44-0x47`). Measure it before assuming either way.
> PROPER FIX, deferred: give him his own free 4-row block plus a copy of
> the routine with that base. Retracted claim: "legacy only ever requests
> seq ids 0x26/0x27" — false; `tests/audit_palette_seq_ids.sh` sampled
> replays in which Dark Force never activates, and 0x26 is Demitri's own
> block. The palette path never transits work RAM, so no RAM gate can see
> any of this; the maintainer's playtest found it. The
> afterimages remain by design, and the underlying MECHANICS are still
> unproven; the analysis below stands.

## [14z-124 (c)] from «Dark Force — the 14z-66..68w readings (split in two / DF STYLE fix shape / measured OUTSIDE the mode / the mechanism as far as decoded / where the trail stops)»

Split the item in two; they have different answers.

**DF MECHANICS are already native-correct for a ported tenant.**
Measured on Huitzil (replay 82, native A/B of record): activation
enters seq **0x0A** at the same frames on both games, expiry and
re-activation both fire, and the DF summon pieces (secondary types
**0x75 / 0x77**) are present in pool B on both at the sample frame.
Nothing in the activation path needs porting.

**DF STYLE is a HOST per-character effect and is what looks wrong.**
The engine applies a per-char DF presentation (palette treatment plus
afterimages) selected by char id, so a tenant on a variant row inherits
the HOST character's style. Maintainer capture of native vs2: Huitzil
gets **no palette change and no afterimages at all**; ours shows
inverted colours + afterimages, i.e. the host's style.
**Fix shape (not yet implemented):** locate the per-char DF style
selection and give the tenant's row the NULL style. This is a
selection-table item of the same family as the win-screen tables
above — expect an id-indexed table with variant rows aliasing base
rows, and expect the same view question (decode both, verify against a
known-good row).

**Measured 14z-68s/t/u — CAUTION, ALL OF IT WAS MEASURED OUTSIDE DARK
FORCE (14z-69).** Every number in this block comes from replay 82, which
presses the pair with an empty meter and therefore never enters the
mode; read it as a description of ordinary movement, not of DF. The
"extra sprites" conclusion happens to be right (DF really does draw him
3-4 times over — but that is measured in 14z-69 below, not here), and
the "palette alternates per frame" reading does not survive: in real DF
the row holds ONE purple ramp for the whole mode. Kept for the ruled-out
list, which is still useful.

**THE EFFECT ONLY APPEARS WHILE THE CHARACTER IS MOVING.** In 14z-68t
I sampled replay 82 at f3050-3250 (the stationary window), measured no
sprite gain and no palette change, and wrote the symptom up as "not
reproduced". That was a SAMPLING ERROR. The maintainer's repro note —
"move around, especially visible when air dashing" — located it
immediately. Replay 82 walks at **f3300-3400**; sample THERE.

Maintainer repro (no replay needed): 1 stock, **HP+HK** to trigger DF
(MP+MK / LP+LK equivalent), then move — air dash shows it best.

Corrected measurements (replay 82, id-0x10 poke, build hui11):
- **The afterimages ARE extra sprites, and they are HIS.** pal-0x0A
  sprite count goes **22 stationary -> 24-29 while moving**, drawn as
  additional groups at trailing positions spanning ~72px. The captures
  show 3-4 ghost copies.
- **The palette ALTERNATES per frame**: some frames render his correct
  gold/yellow, most render purple. So it is not a static recolour —
  it cycles.
- **NOT shadow servants**: the servant installer `0x823E2` and walk
  `0x8245C` take ZERO probe hits across the whole replay, moving
  window included. The copies come from the fighter's own draw path.
- Still true from the earlier pass: there is no DF-specific palette
  ROUTINE (same writer PCs before and during), so the recolour is a
  palette SOURCE/selection change, not different code.

### The mechanism, as far as it is decoded (14z-68v)
DF drives the FIGHTER'S EFFECT CHANNELS — the `+0x318 / +0x320 /
+0x330 / +0x340` sub-structs documented in the effect-system section.
Measured by diffing the fighter block pre-DF vs during-DF-moving: the
channels go from all-zero to populated (`+0x318`=[2,2] `+0x31C`=4
`+0x320`=[2,2] `+0x324`=5 `+0x32C`=13 `+0x330`=[2,2] `+0x334`=11,
plus flags at `+0x395`/`+0x397`).

Those channels run SCRIPTS through a small state machine:
- per-frame CLEAR path (runs always): `0x029F60` / `0x02A57C`;
- the DF-only writers, i.e. the channel actually doing something:
  **`0x029F86`, `0x029F9A`, `0x029FD2`, `0x029FDA`, `0x02A528`,
  `0x02A538`, `0x02A582`** (these PCs appear ONLY while DF is up);
- the machine reads a script through `a3`, matches script words
  against the fighter's `+0x12A`, and steps a channel struct via `a4`;
- the script tables are loaded by `lea $2A768(pc),a3` /
  `lea $2A770(pc),a3` / `lea $2A778(pc),a3`, selected by a
  program-byte dispatch at `0x029F4A`
  (`move.b (a4),d0; move.w (pc,d0.w),d1; jmp`).

**Where the trail stops (14z-68w), and the cheapest way past it:**
- The channels do NOT populate at DF activation. Tapping
  `+0x318..+0x340` across the activation window shows the only write
  is `+0x396` = 0x1100 (the button register, pc `0x014E58`); the first
  non-zero channel write is at **f3150**, coinciding with the next
  MOVE input, not with DF. So the channels are move-driven and are
  probably not themselves the style selector.
- Ruled out as the cause: the seq-0x0A (DF) handler is per-char
  dispatched like every other seq head, and on a tenant build its
  table row 0x10 IS already repointed to H's own placed handler
  (consistent with "DF mechanics are native-correct"). The style is
  therefore applied by something OUTSIDE his handler.
- Native applies NEITHER the trailing copies NOR the recolour to
  Huitzil, so the discriminator is per-character somewhere in the
  shared path.

## [14z-124 (c)] from «Dark Force — the two premises of 14z-69 (the native leg was never blocked; DF costs a stock)»

### 14z-69: THE NATIVE LEG EXISTS — and with a rig that ACTUALLY
### enters Dark Force, the symptom reproduces and is measured

Two premises had to be fixed before anything here was worth measuring.

**1. The native leg was never blocked.** 14z-68j recorded "the early-
window id poke does NOT force him on vsav2" from one attempt with
**replay 61**, whose input timing is authored for OUR wheel. The
replay-80 poke flow reaches him natively in six seconds: on `vsav2`,
`$FF8782 = 0x10` across commit->load gives `+0x382 = 0x10`. No vs2
cursor path, no savestate, no Rule 7 question.

**2. DARK FORCE COSTS A BANKED STOCK, AND NOTHING ABOVE HAD ONE.**
Replay 82 — the rig behind every DF measurement in 14z-66/67/68 — runs
with `+0x109 = 0` on BOTH games. With an empty meter the P+K pair is
DOWNGRADED to a single button (`+0x107` = 0xFF/0xFE) and play continues
normally. **`seq 0x0A` is that downgrade, not Dark Force.** Poke stocks
in (`$FF8509`, the documented ES-scripting poke) and the same input
produces something completely different.

## [14z-124 (c)] from «Dark Force — the 14z-69 'next thing to decode' sentence»

So the DF-type selection sits between those sites. That is the next
thing to decode, and it is the same shape as every other per-character
selection here: expect an id-indexed table with variant rows aliasing
base rows, and decode both views before trusting a row.

## [14z-124 (c)] from «Dark Force — the 14z-69e header and the bank-attribution rule blockquote (a pointer to the drawer section)»

### 14z-69e: the mode is SOUND; only the COLOUR is wrong, and it is a
### known class (the sword/statue blink, STATE 14z-33)

> **The general rule this is an instance of (added 14z-71):** bank
> attribution is **per-record and per-list-type**, never per-character.
> The sword/statue blink came from processing records of two different
> banks with one bank's semantics; the Huitzil beam's corrupt strip came
> from a list type that composes its own bank word instead of taking the
> object's. Both render *real art from the wrong place* — geometry
> correct, content someone else's — which is the signature to recognise.
> See "The sprite-list DRAWER" above and `atlas/sprite_lists.md` §4.

## [14z-124 (c)] from «Dark Force — the purple's pre-fix analysis (14z-69e), the parked fix design and the stale 'Fix shape' paragraph»

**The purple is a separate, known-class defect.** The recolour is a
palette-SEQUENCE animation, not a static swap: one writer, **engine
`0x02AD68`** (the `0x2AD64`-family uploader), rewrites row 0x0A every
frame from DF entry, cycling **four contiguous rows of the global
palette-seq table at vsavj `0x39ACD0`-`0x39AD4F`**. Their vs2 twins
(mapping `+0x1613C`, i.e. `0x3B0E0C`-) hold a GOLD ramp
(`0111 0fea 0fb8 0e96 0b75 ...`) where vsavj holds PURPLE
(`0222 0fff 0faf 0fcf 0e8f ...`).

**The ids are 0x1E, 0x1F, 0x20, 0x21** — rows vsavj `0x39ACC0`,
`0x39ACE0`, `0x39AD00`, `0x39AD20`; vs2 twins `0x3B0DFC`, `0x3B0E1C`,
`0x3B0E3C`, `0x3B0E5C`. Cross-check that these are the right pairs:
each row's last word is its own frame index (0000/0001/0002/0003) and
matches across the two games. The API that resolves them is
**`0x02AD82`**: `a0 = 0x39A900 + (d0 & 0xFFF) * 0x20`, measured taking
152 calls during one DF with d0 cycling 0x1E-0x21. (NOTE for probes:
`0x02AD68` sits after a `movem.l (a0)+`, so the A0 you see there is the
row start PLUS 0x10.)

**A sibling API takes the source as a POINTER instead** — `0x02ADA6` /
`0x02ADAC` use `movea.l $3A4(a6),a0`. If the channel script can be made
to use that variant, the fix is DATA-ONLY: point `+0x3A4` at privately
placed copies of the four vs2 rows. Measured: H's DF takes the id-based
entry (0x2ADA6 zero hits, 0x2ADAC zero during DF), so this is a
candidate route, not the current one.

**PARKED HERE, and why:** the trigger is not a call we own. There is no
absolute `jsr/jmp` to `0x2AD82` anywhere in vanilla or in the built
image — it is reached through the channel machine's program-byte
dispatch at `0x029F4A` (`move.b (a4),d0; move.w (pc,d0.w),d1; jmp`),
i.e. from ENGINE code driven by H's ported SCRIPT data. So the
legacy-clean intervention is in the script, and that needs the opcode
table decoded first — and it does NOT decode as a flat array of pc-rel
words at one base (best single-base fit: 15/24 targets valid, the rest
odd addresses). Decode that table before designing the fix; do not
guess it.

That is exactly the sword/statue blink of 14z-33: same seq ids,
different global-table contents between engines, and the table is
legacy surface so it cannot simply be edited. **The fix design already
exists there** (STATE, "FIX DESIGN (state_hook precedent)"): wrap the
seq-TRIGGER call inside the PORTED handler — legacy-clean by
construction because the call site is our own code — routing the
tenant's ids to privately placed copies of the vs2 rows (0x80 bytes
here) and leaving every other id on the original path.

**Fix shape — [STALE REFERENCE CORRECTED 14z-109: this decision was made
and IMPLEMENTED long ago (the gate is `tests/test_hui_df_style.sh`); the
paragraph below is the pre-fix design discussion, kept as analysis]:** the
tenant's seq-0x16 row must not run vs2's DF-form machine under vsav's
DF. Candidates: leave `dispatch_16` row 0x10 alone (careful: vanilla
row 0x10 is an ALIAS of row 0x00, i.e. Bulleta's handler, not a null),
or point it at a thunk that reproduces native's "clear the seq"
behaviour. Porting vs2's whole type-A DF is the other end of the scale
and is legacy-hot. Measure the candidate with the gate at
`DF_STYLE_EXPECT=matches`.

Gate: `tests/test_hui_df_style.sh` (replay 85). It refuses to judge
unless BOTH legs are verifiably in DF, and freezes the defect's shape
(`--expect differs`) so it goes red if the symptom changes in either
direction; flip to `--expect matches` when the fix lands.

Open observations queued from the same replay, unattributed: ~15px X
drift over the DF walk (speed modifier vs recoil) and a pod anim phase
difference at the f3250 sample.

## [14z-124 (c)] from «The child companion's shadow — the 14z-68g 'band is the defect' diagnosis (inverted 14z-69o)»

The reported symptom was "the human child sidekick's shadow is a
rectangle, all the time". **The 14z-68g diagnosis had it backwards** and
that is the lesson worth keeping.

14z-68g measured, correctly, that our shadow BAND pieces carry
`code = native - 0x16A8` with bank word 0 instead of 3, and concluded
the band was the defect and the core ("both games draw 0F8B/0F8C/0F8B")
was fine. Comparing the ART at those addresses inverts it:

## [14z-124 (c)] from «The 214+P grenade explosion — the 14z-70f header blockquote»

> **Read this before the triage that follows.** The header used to say
> "NOT a tile-inventory defect". It was one: **569 group-C tiles were
> remapped bank 3 -> 4 and never copied**, and the ground detonation drew
> a solid fuchsia rectangle. The triage was not sloppy, it was
> MIS-RIGGED — every rig fired 214+**MP** from 2P start distance, where
> the bomb reaches the opponent, so the capture showed the ON-CONTACT
> explosion and never the ground mushroom. Reproduce only with
> `tests/replays/hui/83d_hui_grenade_ground.rpl` (214+**LP**, both
> fighters walked to their corners). The empty-tile audit also sampled
> every 25 frames and saw 10 of 113. Both instruments are fixed; the
> reasoning below is kept because the *elimination* steps are still
> valid, only the conclusion was wrong.

## [14z-124 (c)] from «The 214+P grenade explosion — the 14z-69q triage (RETRACTED 14z-70f)»

The original triage, superseded. It is
NOT the shadow class: scanning every group-C sprite the build draws
across the 214MP window of replay 83 (f3390-3555) returns **zero**
empty-tile draws, so nothing is missing from the copy inventory.

What it IS: at explosion onset (**f3395** and **f3430** in replay 83)
the pieces draw with **pal 05 / 06 / 08 out of BANK 0 — stock group A/B
art**, while everything of his around them comes from group C bank 4/5.
That is the documented "pieces created through a path that leaves
`+0x18` unset" class (14z-67), the same root as the beam/lightning
work. It belongs to the effect-family arc and cannot be fixed from the
gfx side.

Rig for whoever picks it up: `tests/replays/hui/83_hui_fx.rpl` does a
clean 236LP then a 214MP at f3380 (arcing projectile -> ground
explosion). Dump OBJ over f3390-3560 and compare bank words against a
native leg — the poke flow reaches him on vsav2 unchanged.

## [14z-124 (c)] from «The 214+P grenade explosion — 14z-70: the 'tiles genuinely absent from our set' reading (RETRACTED 14z-70e)»

**What the native leg alone shows.** The explosion is a large orange
flame pillar (snapshot f3436, right of screen). Locating it by screen
position rather than by palette guesswork gives a compact cluster:

```
native f3436, flame region x 210-320 y 30-190:
  pal 06, BANK 0, codes 4a2f 4a4d 4a70 4a76 4a96 4aa0
  across the whole window: pal 06 bank 0, ~95 codes in 0x48EA-0x4C56
```

So the explosion is drawn from **vs2's BANK 0 — its shared/common effect
art**, not from H's own character band (bank 3 native / bank 4 ours).
That is why the port misses it: the tenant gfx work moves his BAND, and
this art is not in it.

**The tiles are genuinely absent from our set.** Comparing vs2 against
the stock vsav gfx at those same indices (`tools/gfx_tiles.py`, group A):
**14 of 14 sampled tiles DIFFER, and none is blank.** Rendered sheets at
0x4A00 confirm it by eye — vs2 holds soft organic flame/smoke texture
there, vsav holds unrelated sharp-edged art.

**This is a DIFFERENT class from the child-shadow defect, and that is why
`audit_empty_tiles.sh` is silent on it:**

| | shadow (14z-69o) | explosion (this) |
|---|---|---|
| code | remapped to bank 4 | NOT remapped — stays bank 0 |
| tile present? | no — empty group C slot | yes, but it is vsav's OWN art |
| renders as | solid rectangle | a wrong, plausible-looking picture |
| empty-tile audit | catches it | cannot see it |

A complete-inventory empty-tile check can only find art that resolves to
nothing. Wrong-but-present art needs a source comparison, which is what
the table above is.

**Consequence for the fix:** these tiles must be COPIED into group C
(they are vs2 content absent from our set) *and* the emitter's codes
remapped to that bank — copying alone leaves the codes pointing at
vsav's art, and remapping alone would point at empty group C slots (the
shadow failure mode). Both halves, or neither.

## [14z-124 (c)] from «The 214+P grenade explosion — 14z-70b: the '+0xA220 constant' reading (RETRACTED 14z-70e)»

**The effect object is running correctly.** Position-matched across the
window, the two legs agree frame for frame:

```
f3432  native  n=13  x 273-401  y 57-201
f3432  ours    n=13  x 273-401  y 57-201
```
Same sprite counts, same screen positions, same palette (06), same bank
(0). For comparison, in the same dump `pal 0a` (98 vs 91 codes) and
`pal 0c` (42 vs 42) carry IDENTICAL code ranges correctly remapped bank
3 -> bank 4, so the band machinery is fine; this effect is the exception.

**Only the codes differ, and by a constant.** Ours = native **+ 0xA220**:

```
native 49EE -> ours EC0E     4A0E -> EC2E
native 49EF -> ours EC0F     4A2A -> EC4A
41 of 88 native codes appear in ours at +0xA220 (the rest are
animation-phase — the legs sample different steps of the animation)
```
Beware: pairing these two legs by SPRITE INDEX or by position alone
gives noise, because the animation is about one step out of phase. The
constant only appears once you test `native_code + D in ours_codes` as
sets. An index-paired delta histogram shows a smear of 0xA1C0-0xA262 and
looks like "no constant" — it was read that way once this session.

**And the art at the shifted index is mostly wrong**, which is the
symptom: of the 41 matched codes, **9 have identical art and 32 differ**
(none blank). So ours draws vsav's own effect page at native+0xA220 —
right shape of thing, wrong picture, and never an empty tile, which is
why `audit_empty_tiles.sh` is correctly silent.

**Where +0xA220 does NOT come from — checked, so do not re-check.**
`build/manifest/effect_tail.json` carries exactly one reloc delta,
`+0x47` (x70), and no `place` target in 0xEC00-0xEF00. It is not the
effect_tail map.

**Prior art that the fix must be reconciled with (14z-67, huitzil.toml
~line 753).** For the `x2b7ef4` companion-effect records the designed
mechanism on a delta-0 group-C tenant is `c5_mode`: keep every tile word
NATIVE (skip the bmap rewrite), emit the referenced codes as
`effect_c5.json` so the art is placed at native codes in group C bank 5,
and flip the ported piece spawners' bank setters `#$2000 -> #$3000`.
This explosion is NOT going through that path — it draws bank 0 with
non-native codes, i.e. neither half applies to it.

## [14z-124 (c)] from «The 214+P grenade explosion — 14z-70c/70d: the x088512 chase and the RETRACTED causal claim»

### 14z-70c: a REAL latent defect in `x088512` — fixed and shipped — but
### it is NOT the explosion's root. Claim RETRACTED, see 14z-70d below.

Chased the emitter down the chain, and it lands on the defect class this
project has now paid for three times.

**The chain, measured on the 83c rig.** The vanilla sprite emitter at
`PRG:0x01B2BC` (`move.w (A0)+,D2` / `(A0)+,D3`, with `or.w 0x18(A6),D1`
folding in the bank word — this is also the authoritative proof that
`+0x18` IS the bank field) draws the pieces for the object at
`RAM:$FFB980`, reading its list from **`0x288C78` — a VSAVJ address**.
The list start `0x288C6E` is fetched at `PRG:0x01AFAE` from the vsavj
table at `0x283C10`.

**Everything ported is correct — that is what makes this diagnosable.**
- the object's `+0x1C` is written on BOTH legs at the same frames from
  exact twins: ours `PC:0x0D7A6E` / `A0=0x40223C`, native `PC:0x08B170`
  / `A0=0x2BA120`, mapping through the `x088512 -> 0x0D4E10` and
  `x2b7ef4 -> 0x400010` deltas;
- that selection table is byte-perfect (16/16 entries relocated);
- the placed `x2b7ef4` is 2054/2060 intra-region pointers correctly
  relocated (the 6 exceptions are word-misaligned false positives);
- the ported list IS present and IS referenced correctly — ours
  `0x400760`/`0x400848 -> 0x40557A` mirrors native `0x2B8644`/`0x2B872C
  -> 0x2BD45E`.

Native, meanwhile, NEVER reads `0x2B8644` in the window (its only
watch hit is the frame-1 arming artefact). So ours is not "using the
host's table where native uses the ported one" — ours is arriving at a
host address that native never visits at all.

**Why: three pc-relative tables resolve past the end of their region.**
`tools/verify_pcrel_data.py build/hui14` reports **72 checked, 72
BROKEN**, and three of them are the effect machine's own:

```
x088512 src 088512-08c052   placed 0d4e10-0d8950   (len 0x3B40)
  lea 08c014 -> table 08c08a   past the region end by 0x38
  lea 08c026 -> table 08c09a   past the region end by 0x48
  lea 08c038 -> table 08c0a2   past the region end by 0x50
```
The `lea`s are INSIDE the region; their targets are not. The
displacement is copied verbatim, so each resolves to `target + delta` =
`0x0D8988` / `0x0D8998` / `0x0D89A0` — which is **inside the anim region
placed at `0x0D8950`**. The machine reads animation bytes as its
parameter tables, and a garbage parameter is exactly how an object ends
up pointed at an unrelated vsavj sprite list.

**This is the x06cac0 defect again** (14z-69h/i/j): a region extracted
shorter than the tables its own code references, because `fixed_len` is
a CAP and `oracle_extend` stops where the sibling stops agreeing. The
fix mechanism already exists and is proven — root spec `:f<off>` force-
length with the forced tail EMITTED RAW (CPS-2 decrypts opcode fetches
only, so a data read returns stored bytes), landed for x06cac0 in
14z-69j and green there.

**Recipe, not yet executed.** Force `x088512` long enough to contain the
furthest table (starts at +0x3B90 against a declared 0x3B40, so the
length must cover 0x3B90 + that table's extent) and split code/data at
the FIRST table, `0x08C08A`. Per 14z-69h the split must be checked by
disassembly rather than assumed, and landing `:f` ALONE changes shipped
bytes — it must arrive with the raw-emit. Then rebuild and re-run the H
gates plus the legacy masked-v2 basis.

Also still unchased: `pal 10` and `pal 11` bank-0 sprites sit in the
same screen region and may belong to the same effect.

### 14z-70d: the fix was BUILT and it does NOT fix the explosion — the
### causal claim above is RETRACTED

Executed the recipe. `build/hui15` (**699de9b7**): root
`0x88512:0x3b98:s:f0x3b78`, plus a small `extract_char.py` change so a
SOURCE-ONLY (`:s`) root honours `f<off>` at all — the `:s` branch
returns early and never set `raw_from`, while the generator already
reads it per region. Extract log confirms: *"x088512: raw DATA tail from
+0x3b78 (0x20 bytes emitted unencrypted for runtime DATA reads)"*.

**The repair is real.** `verify_pcrel_data.py` drops from 72 BROKEN to
69, with all three `x088512` rows gone — the tables now sit inside the
region and resolve to themselves.

**And it changes the explosion not at all.** Measured, not eyeballed:

```
native pal06/bank0 codes : 88
hui14 : 84   shared with native 0   at +0xA220: 41
hui15 : 84   shared with native 0   at +0xA220: 41
hui15 code set == hui14 code set : True
```
Byte-for-byte the same sprite codes, and the snapshot at f3430 is
unchanged. **Why: the code that reads those tables never runs.** An
execution breakpoint at the placed twin `PRG:0x0D8912` (= `0x08C014` +
the `x088512 -> 0x0D4E10` delta) over the whole replay fires **zero**
times (the single logged line is the frame-1 arming artefact).

**The error, named so it is not repeated: co-location is not
causation.** The reasoning was "the effect machine lives in `x088512`;
`x088512` has three tables resolving into the anim region; therefore
those tables feed the effect machine." Every clause was true and the
conclusion still did not follow — the tables are on a path this
scenario never enters. **Before attributing a symptom to a broken
table, put an execution breakpoint on the code that READS it.** That is
one cheap run, and it would have preceded a whole rebuild here. Same
family as this session's other two: measuring something real, then
assuming it was the thing in front of us.

**Status of the change: KEPT, and gates green.** It repairs a genuine
latent defect of the class the project has already ratified a fix for
(x06cac0, 14z-69j), it is behaviourally inert today, and it is proven
safe: `test_m3a_reproducible.sh` PASS (both frozen references rebuild
bit-exact, so the shared-tool edit is inert on Donovan) and
`test_hui_boot.sh` PASS with legacy **masked-v2 EXACT**. It is a latent
repair with no observable effect — worth keeping for the same reason the
x06cac0 one was, but it buys no visible change and should not be
described as fixing anything a player can see.

## [14z-124 (c)] from «The 214+P grenade explosion — 14z-70g: the beam's 'never CREATED' reading (superseded by the 14z-71 closure)»

### 14z-70g: the BEAM — the object is never CREATED, and the creator is
### a vs2-only effect handler that was never ported

Anchor method, one link at a time, both legs, replay 83b (maintainer-
confirmed rig: 236LP, 2P distance; LP/MP/HP look identical, 236+2P is the
girthier ES beam, 236+K is the low beam).

The pool is documented already — `docs/project/tables/reconciliation.md`
`$FFD400/0x80/cat14`, and "GEOMETRIES ARE IDENTICAL in both games,
pool-for-pool", which is what makes the address comparable across legs:

| | native | ours |
|---|---|---|
| beam sprite-list reads | 2 (f3165/3167, `PC:0x019E0E`, `A6=$FFD400`) | 0 |
| anim-pointer writes f3160-3210 | 26 (`PC:0x01378A`) | **0** |
| pool-slot HEADER writes f3150-3210 | 30 (`PC:0x0934B4`) | **0** |

**The beam object is never created.** That also explains the symptom
shape the maintainer confirmed: the FREEZE WORKS (hit logic, elsewhere)
while the muzzle orb and the beam are both missing — they are one object
that never exists.

**The creator is vs2-only code.** `PC:0x0934B4` is the state-0 body of an
effect-object state machine:

```
09349A clr.b 0x38(A6) / 09349E moveq #0,D0 / 0934A0 move.b 0x03(A6),D0  <- sub-state
0934A4 move.w (0x06,pc,D0.w),D1 / 0934A8 jmp (0x02,pc,D1.w)             <- state table 0934AC
0934B0 clr.b 0x01(A6) / 0934B4 move.b 0x382(A4),D0 ; cmp.b 0x0A(A6),D0  <- the id gate
```

Counting that id-gate signature across the images:

```
vs2 (native)   : 4 sites  0x8FAD2 0x91562 0x934B4 0x937BA
vsavj pristine : 2 sites  0x813A8 0x82CD0
our build      : 2 sites  (unchanged)
```
vs2 added two of these machines for the newcomer effects, and **0x0934B4
is outside EVERY ported root** (the nearest, `0x0905AE+0x300`, ends at
0x0908AE). All four sites sit ~0xC after a state-dispatch `jmp`, i.e.
each is the state-0 body of its own machine; none is reached by an
absolute pointer, so entry is a computed dispatch.

**This is a sibling of the 14z-67 effect-zone clone, not a duplicate of
it.** That work cloned the OTHER machine (`x06cac0`, the row-8 /
sustained-beam family) and ported the effect byte-map rows so ids
0x4E-0x53 stop collapsing to index 0. This machine at `0x093xxx` was
never in scope.

**Fix shape (NOT yet executed, and it is a design decision):** port the
vs2-only handler as a new root and route the tenant's effect objects into
it via the owner-gated `site_thunk` pattern the other machines already
use. Open first: which TWO of the four vs2 sites are the newcomer ones
(pair them against vsavj's two through the R1 map — raw addresses do not
transfer), and each machine's extent.

## [14z-124 (c)] from «The 214+P grenade explosion — 14z-70e: the content-join narrative and the 'believed CORRECT' status (SUPERSEDED 14z-70f)»

Maintainer proposal: diff the screen before vs during the explosion, take
the tiles that appear, and search BOTH games for that CONTENT. Doing the
content join instead of an index join overturns the whole entry.

**1. Native's explosion tiles are already in our build.** Hashing all 88
and searching our entire gfx (groups A/B from the patched vsav.zip, C
from vsw): **87 of 88 present**, 84 in group A, 3 in group B.

**2. The mapping is a PERMUTATION, not a constant** — `0x0EC0E` holds
vs2 `0x495F`'s art, NOT `0x49EE`'s. So **+0xA220 was a statistical
artefact**: two dense ~85-value clusters of similar width offset by
~0xA220 will overlap about half the time by construction (41/88 "hits").
It described nothing. Any "constant delta" between two dense code sets
must be confirmed by CONTENT before it is believed.

**3. Ours draws the RIGHT tiles.** Window-level content join over the
explosion:
```
native 88 contents   ours 84 contents
IDENTICAL CONTENT drawn by both: 76      native-only 12   ours-only 8
ours drawing BLANK tiles: 0
```
Per-FRAME the intersection is 0 at every frame, which is what sent this
whole entry wrong — the legs are ~2-4 frames out of phase (ours has 0
explosion sprites at f3426 where native has 7), so a per-frame set
intersection reads as total disagreement while the window agrees 76/84.

**4. And it LOOKS right.** Snapshots at the SAME frame f3440: native and
ours both show the large flame pillar, same shape, same white-blue base
with orange top, same position. The earlier "native has a flame pillar,
ours has a small yellow burst" was f3430 versus f3430 across a ~10-frame
phase lag — ours reaches the same pose at f3440.

**Where the false alarm came from.** 14z-69q's triage ("pieces draw pal
05/06/08 out of BANK 0, the +0x18-unset class") was measured on replay
83 — the 1P-vs-CPU rig where our leg has Felicia point-blank and the
projectile never travels. It characterised sprites that were not the
explosion. The original maintainer report (ping #7, the fuchsia class) is CLOSED
[M: `tests/audit_grenade_ground_tiles.sh`, 14z-123 — this sentence read
"was most likely fixed there" from 14z-70e]: the ground explosion draws
native vs2's own art tile-for-tile (441 distinct pal-06 tiles, intersection
441, ours-only 0, native-only 0, zero blank — the phase-free per-content
measure over every detonation frame of replay 83d); the residual
"ours-only / native-only contents" was the 5-6 frame leg phase lag (the
seq-D thunk's cycle cost), not missing art. The "fuchsia" is pal-06, the
explosion's correct orange→magenta fade.

**Status as written 14z-70e — SUPERSEDED 14z-70f (the section header): it
was NOT correct; 569 uncopied tiles, found by the rig this triage
mis-aimed. "Believed CORRECT" is retracted with the triage.** (Was: the
214+P explosion is believed CORRECT and needs a playtest to close.) Residuals, both unexplained and neither necessarily a defect:
the ~10-frame phase lag, and 8 ours-only / 12 native-only contents (part
of which is sampling — the dump is every 2 frames). If the maintainer
confirms, remove it from the effect-family worklist; the BEAM remains
genuinely open and is a separate defect (never walks its anim nodes).

## [14z-124 (c)] from «The beam / effect family — the 14z-69j state, superseded (69j/69k/69m/69n)»

### The 14z-69j state, superseded

Where the arc stands, measured on replay 83b against native vsav2.

**Native's beam, so you can recognise it:** pal-0x0C sprites in H's own
band at `a19=3xxxx` — codes 0x1DF4/0x1DB4 at the muzzle (f3164-3172),
then 0x1E2F/0x1E42/0x1E52/0x1E5F marching x=0x95..0xEF (f3178-3208) —
plus the long stretch segments `code=4EC0` at `a19=14ec0`, sz 4x1/6x1/
16x1, at y=0x2074. The window is **f3164-f3208** with a ~12-frame
cadence, 3-13 pieces per hit frame. Sample THERE; outside it native
draws none either (a blind sample reads as "native has no beam").

**What is now native-equivalent** (scratch build with `tenant_type_stamp`
+ `obj_hook_extra` + `piece_prebake` un-parked, on top of the shipped
table fix):
- the object is CREATED — our stamp writes type `0x7C02` at f3179 where
  native writes `0x0802` at f3177 (tap on the pool's type word);
- it is routed to the PORTED machine (type >= 114 by construction);
- the machine's seven pc-relative param tables now read byte-identical
  to vs2 (14z-69j raw-emit);
- its record pointer is the PLACED twin at **native's own relative
  offset**: ours `0x40064C` = placed base `0x400010` + 0x63C, native
  `0x2B8530` = `0x2B7EF4` + 0x63C;
- owner (`+0x30` = 0x8800, the victim) and bank word (`+0x18`) match;
- **the whole object is 118/128 bytes identical to native's.**
- the fleet pieces are created too: `type<-080C` fifteen times on both
  (native pc 0x6D218 / ours its placed twin 0x0D4648).

**And it still emits ZERO sprites.** Chased further (14z-69k):

**The beam object is NOT the emitter** — that was an assumption, and it
is now refuted. Its record chain resolves to sprite codes 0x48xx, not
the beam codes. Attribution by killing a pool slot does NOT work: the
object respawns within 3 frames (poke `+0x00` to 0 at f3174 -> the slot
is clear at f3175 and fully back at f3178), so all four kills leave the
beam untouched. Attribute by RECORD CHAIN instead.

**The beam art is ported and correct.** The sprite lists are at vs2
`0x2621D6` / `0x26233A`, inside the `anim` region (src 0x245872, delta
-0x16CF22): ours' `0x0F5418` is byte-identical, and `0x0F52B4` differs
only in one correctly relocated pointer (+0xB61C0, the aux0_1 delta).
They are referenced from anim nodes at `0x24FCFA`-family and
`0x251CDA`-family — so the beam is drawn by an ANIM SEQUENCE, not by a
piece the machine spawns.

**All four pool objects now correspond 1:1 to native's, at native's own
relative record offsets** (beam +0x63C, companion +0x1E4, 0x77 +0x222C).
CAUTION when reading these dumps: the slot ORDER differs between the
games and an object's type byte changes frame to frame — compare the
same object across the same frame, or you will "find" differences that
are phase (this cost a wrong read in-session).

**Traced further (14z-69m), and where it now stands.** The "become the
emitter" sequence is IDENTICAL on both games: at **f2364** slot FFB800's
type word takes `0x7500`, at **f2365** its sub-state takes `08` then
`06`, from twin PCs (native `0x8ACE6` / `0x8A6CA` / `0x8A6DE` <-> ours
the placed `0x0D75E4` / `0x0D6FC8` / `0x0D6FDC`), with A6 = P1 on both
and a single probe hit each at f2363. Between f2365 and f3170 NEITHER
game writes that type word again.

Yet by f3162 native has one 0x75 object at FFB800 with sub-state **06**,
and ours appeared to have one at FFB900 with sub-state **02**. THAT
APPEARANCE WAS AN ARTEFACT — see immediately below before using it.

**BOTH LEADS ABOVE ARE DEAD — the clean re-measure killed them
(14z-69n). This is the useful part of the entry.**

1. The `FFB802 <- 0000` at f2363 from `pc=0x0FB2F8` is **ours' own
   documented slot-clearing alloc wrapper** (`0x0FB2E0`, "0x80 cleared,
   +8 preserved" — the 14z-65 allocator-wrapper family) zeroing a
   freshly allocated slot; `0x0FB2F8` is its `clr.l (a0)+` loop. Native
   has no such write because native's allocator does not clear, which is
   exactly why the wrapper exists. Benign.
2. **The sub-state difference does not exist.** Measured on ONE build in
   ONE run with tap and dumps together (hui18, FBNeo): slot FFB800 takes
   `0x7500` at f2364, sub-state `08` then `06` at f2365, and still reads
   **`type=7506`** at f3162 and f3186 — native's shape exactly.

The earlier "native 7506, ours 7502" came from comparing MAME frame
dumps against FBNeo taps **by frame number**. The emulators traverse
identical states at slightly different frame indices — the very fact §4
dual-emulator agreement rests on — so f3162 is not the same moment in
both, and neither is a slot's occupancy. **Never cross-reference a MAME
dump and an FBNeo tap by frame index: measure both legs in one
emulator, or anchor on an event rather than a frame number.**

So the beam residual is UNATTRIBUTED again — but the eliminations are
real and hold: not the tables, not the records, not the art, not object
creation, not the beam object (its chain resolves to 0x48xx codes), and
not the pod's sub-state. The honest next step is to find which object
walks the `0x24FCFA` / `0x251CDA` anim nodes that carry the beam lists —
measured in ONE emulator, both legs, anchored on an event.
(Also noted, and subject to the SAME caveat since it came from the same
cross-emulator comparison: the beam object's `+0x44` — Y velocity, which
the mover integrates into `+0x14` — read `ffff8000` native vs `0000a000`
ours while the other 118/128 bytes matched. Re-measure it in one
emulator before treating it as a difference.)

Regression state of that scratch build: pairs, ex, grab, air all PASS —
**including the Dark Force crash that parked `tenant_type_stamp` in
14z-68d, which is GONE** (it was a vec3 from an index underflowing the
placed region, consistent with the machine having walked the garbage
param streams the table fix repaired).

The three thunks stay PARKED in the tree: they buy no visible change
until emission is solved, and nobody has playtested them.

## [14z-124 (c)] from «The beam / effect family — 14z-70: the never-walked anim nodes (the chase)»

The step named above was taken. Measured in ONE emulator (MAME), both
legs, replay `83b_hui_ray_2p` with the standard early-window pokes,
`trace_writes.lua` read-watch, 3,230 frames each.

**1. The nodes themselves are correctly ported — a further elimination.**
`anim` places vs2 `0x245872` at `PRG:0x0D8950`, delta **-0x16CF22**
(atlas fragment). Both node families are structurally identical to
native and *every* differing byte is a 3-byte pointer relocated by
exactly that delta — 11/11 correct, verified statically:

```
vs2 0x24FCFA -> ours 0x0E2DD8      vs2 0x251CDA -> ours 0x0E4DB8
vs2 0x2621D6 -> ours 0x0F52B4      vs2 0x26233A -> ours 0x0F5418   (the known-good pair)
```

**2. Native walks them; we never do.**

| leg | watch | reads in 3,230 frames |
|---|---|---|
| native vsav2 | `0x24FCFA,2,r` | **2** (f3165, f3167 — inside the documented f3164-3208 window) |
| ours (hui14) | `0x0E2DD8,2,r` | **0** |

(A `frame 1 PC 000926` line with all registers zero appears on BOTH
legs — that is the watchpoint-arming artefact, not a hit. Count hits
only after it.)

So the residual is NOT a draw flag and NOT the emitter's output stage:
**nothing in our build ever points an object at the beam animation.**

**3. The mechanism, decoded from the walker.** At the native hit the
accessing instruction is `movea.l 4(A0),A0` at `PRG:0x0199D8`; MAME
reports `CURPC` as the FOLLOWING instruction (`0x0199DC`, `move.w
(A0)+,D0`), so read the PC as "the instruction after the access":

```
0199D4  movea.l 0x1C(A6),A0     ; A6 = the animating object
0199D8  movea.l 4(A0),A0        ; <-- the access: node+4 = sprite-list ptr
0199DC  move.w  (A0)+,D0        ; CURPC as logged
```
Confirmed by the registers: `[A6+0x1C] = 0x24FCF6`, and `4(A0)` there
holds `0x002621C8` — exactly the logged `A0`.

So **object field `+0x1C` is the running anim-sequence pointer**. The
setter (vs2 `PRG:0x01378A`) advances it 8 bytes per step, 37 times
across the window, as `A0 = base 0x24EDD4 + D0` — exact on every row
(`D0` 0x0F12, 0x0F1A, 0x0F22 …). The sequence is entered by SELECTING
that base+offset, which is why no absolute pointer to `0x24FCFA` exists
in either image: the tight-window scan finds exactly one reference, an
internal loop-back (`0x24FCE2 -> 0x24FC22`), itself correctly ported in
ours (`0x0E2DC0 -> 0x0E2D00`).

## [14z-124 (c)] from «The beam / effect family — 14z-70: the '$FFD400 +0x1C never advances' suggestion (not promoted)»

**4. Suggestive, NOT yet a finding.** At the fixed address `$FFD400`
ours' `+0x1C` is last written at f2365 (to `0x0F72E4`, a placed-region
address) and never advances again, while native writes it 37 times in
the window. This compares a fixed RAM ADDRESS across legs, which is the
documented slot-order trap above — the object must be identified by
TYPE before this counts. Do not promote it without that.

## [14z-124 (c)] from «The beam / effect family — 14z-70: the NEXT step (taken 14z-71)»

**NEXT:** identify the animating object by TYPE on both legs (not by
slot address), then find what selects base `0x24EDD4` + offset for it.
That selection is the defect.
