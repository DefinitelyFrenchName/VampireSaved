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
