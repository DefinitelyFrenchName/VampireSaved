# RAM atlas — 68k work RAM ($FF0000-$FFFFFF), vsavj

Evidence classes: [C] community (mame-rr cps2-hitboxes.lua family entry,
verified where noted), [D] differential dump experiment, [T] write-trace,
[V] visually verified via snapshot. Every entry lists its evidence.

## Attract-mode demo roster (superset-invariant note)

**[VSE-83]** The attract sequence includes CPU demo matches that feature real characters.
Verified: `01_attract_long` (7200-frame attract, zero input) runs a **Jedah
(id 0x0F) vs Victor** demo starting at **frame ~4278**. Consequence for
patched builds: any change to a character that appears in an attract demo
will alter that attract from the demo's start frame — this is *correct*
superset behavior (the attract "involves" the modified character), not a
violation. The auto-detecting regression runner must treat attract
expectations as build-fingerprint-dependent when a demo-featured slot is
modified. **The full attract-demo roster — MEASURED 14z-118, static + dynamic,
gate `tests/test_attract_roster.sh`:** the assigner `PRG:0x005BEA` reads the
demo counter `RAM:$FF1E2A` (`a5-0x61D6`), masks `#$e`, doubles, and reads an
8-entry x 4-byte table at `PRG:0x005C08` (P1 id, P2 id, venue.w) into the
two id fields (`+0x382` of each player struct) and the venue word `$FF8100`. The eight, in order: Jedah `0F` v Victor `03`
(venue `0x10`); Gallon `02` v Bulleta `00` (`0x0C`); Q-Bee `0C` v Bishamon `08`
(`0x08`); Lilith `0E` v Zabel `04` (`0x04`); Anakaris `06` v Sasquatch `0A`
(`0x02`); Demitri `01` v Morrigan `05` (`0x00`); Aulbath `09` v Felicia `07`
(`0x0A`); Lei-Lei `0D` v Anakaris `06` (`0x06`). Every base id appears once per column; **no variant-half
id can ever be featured**, so a tenant at `0x10-0x1F` never changes attract
(dynamic: 40,000 vanilla attract frames, all eight seen in table order ~3,470
frames apart, counter stepping by 2 and wrapping at 16 —
`build/attract_roster_trace_14z118.log`). The "demo-featured slot" caveat
above therefore applies only to a build that modifies a BASE id's data.)

## Masked windows for hooked-build legacy comparison (CLAUDE.md §4 amendment, 2026-07-25)

The work-RAM windows excluded from legacy comparison on builds
carrying engine hooks. The list has grown by ratification, one basis at a
time — each basis is a `MASK_RANGES` string AND a matching set of vanilla
logs checksummed under it (masked bytes are skipped from the checksum, so
the two sides must share the mask; `tools/freeze_masked_basis.sh`):
- **round 64 / v1** `043c-043d,4182-41a2,7f00-8000` — the original two
  windows (2026-07-25) + row 0x14's staging slot (2026-08-02); vanilla
  logs `tests/expected/vsavj/masked/`; the fallback basis for expectation
  sets that ship no `mask` file of their own. **The string has ONE home:
  `MASKED_DEFAULT_MASK` in `tests/lib/masked_compare.sh`** (14z-97,
  GitHub #70/#96 — it used to be written out again in `run_suite.sh` and a
  third time in `tests/lib/m2a_common.sh`, where it also pinned the M2
  battery to the donovan-m2c generation; both copies are gone and
  `tests/test_m2a_target_policy.sh` fails if one returns). Note the
  CURRENT stock-track sets are on **V2**, not this: `donovan-m8-stock`
  and `donovan-m8-stage4` both ship a `mask` file.
- **V2** `043c-043d,4182-41a2,41c2-41e2,4222-4262,7f00-8000` — + the
  medallion rows' slots 0x16 / 0x19+0x1A (14z-64, ratified with the
  donovan-m3a bundle 2026-08-06); `tests/expected/vsavj/masked-v2/`.
  **EXTENDED 14z-89 from 14 to 49 logs** (the legacy-pairing promotion —
  every replay whose loaded characters equal vanilla's now has a basis
  log). Note the distinction: adding LOGS to a basis is not a basis
  change, because the mask is what the checksum depends on; adding a
  WINDOW is, and needs a new dir. The mask string above is unchanged, and
  the dir now carries its own `MASK` record — `freeze_masked_basis.sh`
  refuses a mask that disagrees with it, and its `VERIFY_BASIS=<name>`
  control re-derived `16_xemu_2p` bit-for-bit before the extension was
  written (that is the proof the mask matches these logs AND that the
  instrument has not moved since 14z-64).
- **V3 (PARKED)** `043c-043d,4182-41a2,41c2-41e2,4222-4262,42a2-42c2,7f00-8000`
  — + row 0x1D's slot (14z-88; ratified 2026-08-15 for the 14z-87b
  medallion move 0x1A→0x1D, WITHDRAWN the same day when the move was
  reverted — the row's palette content cost a legacy pairing one
  main-loop frame at the select→VS fade); `tests/expected/vsavj/masked-v3/`
  kept on disk. Every WIDE set since donovan-m5 is on V2 via its
  `tests/expected/<set>/mask` file — donovan-m14 / huitzil-m21 / pyron-m15
  at 14z-114 (this line named the 14z-8x sets until then).
Mechanism and measurements: docs/GOTCHAS.md "Engine hooks on hot paths"
and the staging-area section below. Additions to this list require a
measured mechanism + maintainer sign-off.

| Address | Meaning | Class | Evidence |
|---|---|---|---|
| `RAM:$FF7F00-$FF7FFF` | system stack reserve; SP rests at $FF8000 at the frame-done sample point, so everything below is dead (stale return addresses, abandoned exception frames, interrupt-time register saves). Hook cycle-skew makes these bytes differ while live state is identical. Observed divergence extent: $FF7FA0-$FF7FFF | ghost (dead at sample) | [D: frame-boundary dumps vanilla vs hooked, session 7] |
| `RAM:$FF043C` | 68k↔QSound handshake latch (values 04/08, toggles per frame); phase-shifts one frame under hook cycle skew — same family as the $FF1CF0 latch under `-debug` (GOTCHAS) | phase | [D: single-byte diff isolation, session 7] |
| `RAM:$FF0460.l` (and `$FF045C.l`) | the SOUND DRIVER's current-record pointer spill (and its SP spill): the driver's dispatch prologue at `PRG:0x0011DE/0x0011E2` (`move.l sp,(-$7BA4,A5); move.l a0,(-$7BA0,A5)`, A5=$FF8000) saves A0 = whichever record it is servicing — the $FF02xx channel records (0x20-stride: $025C/$027C/$029C/$02BC/$02DC…$033C) or the $FF043C latch — dozens of times per frame (FBNEO_HTAP: one writer PC, 415k writes over 04_select_fuzz). At a frame-done sample it normally rests at $00FF043C; a hook-cycle-skewed frame can sample it MID-SCAN (the 14z-81 merged flicker at f2005 read $00FF02DC) — one-frame pointer-phase, no gameplay surface. This retires the WITHDRAWN "sound-queue drain cursor" speculation with a measured owner | phase | [D: FBNEO_HTAP ff0460-ff0463 on vanilla 04_select_fuzz + opcode-view disassembly of 0x11D6-0x11EC, 14z-82] |
| `RAM:$FF4182-$FF41A1` | palette-fade staging buffer: the 0x20-byte slot where select palette-block-A row 14 lands when a venue fade stages block-A rows (buffer family: `$FF4182 + row*0x20`, F-bright applied at staging). The 14z-49 medallion recolor changes that ROM row by design (data_port `med_pal_row14_a`: vsavj `0x3A3A80` ← vs2 `0x3BAFDC`), so the slot's content legitimately differs from vanilla on this build. Display-only (buffer → 90C000; the destination venue overwrites row 14 — legacy win screens pixel-compare 0-diff at f9200/f9400). Masked 14z-49, **maintainer-ratified 2026-08-02 (round 64)**. Expected content while masked — vanilla: `fffcfdc8fb96f973fcfffbcffa9df97af768f658f447f326ff00fc00f800f014`; this build: `fffffda8fc86fb75fa64f743f532f322facef78df458ffd6fb84fc22f922f005` (= vs2's live select row 05). **Audit on suspicion:** `tests/audit_mask_window_ff4182.sh` — reruns the original attribution measurement (05_timeout_idle f9126, vanilla + patched) and asserts the window holds exactly the expected row on each side AND the surrounding buffer bytes (`$FF4140-$FF41DF` outside the window) still match vanilla — i.e., the blind spot hides the designed diff and nothing else. Rerun it whenever: a new divergence lands near `$FF41xx`, row 14's source is retuned, or a new palette-block port is added (Huitzil/Pyron — extend the window per-slot then, never pre-widen) | designed content (this build) | [D: 05_timeout_idle f9126 byte-for-byte attribution + win-screen pixel A/B, session 14z-49; scripted audit added 14z-49d] |
| `RAM:$FF41C2-$FF41E1`, `$FF4222-$FF4261`, `$FF42A2-$FF42C1` | the same staging-buffer family (`slot(row) = $FF3F02 + row*0x20`, section below) for the wheel-medallion rows the WIDE track edits: 0x16 (Donovan), 0x19+0x1A (Huitzil / the 0x1A slot kept — row 0x1A was Pyron's until 14z-87b), and 0x1D (Pyron's medallion row during the 14z-87b move — Donovan's P2-hover portrait draws with row 0x1A by vs2-heritage attr, so the medallion moved rows; REVERTED 14z-88, see below — the row-0x1D slot is not in any live mask). Content lands in the slot at select/venue fades and PERSISTS until reused; display-only, palette path (buffer → palette RAM), no gameplay surface — measured on the 14z-87b triage: f5000 live diff vs vanilla = 0 bytes, f11000 = 30 palette words all inside $FF42A2-$FF42BA. V2 windows ratified 2026-08-06 (bundle), V3 window ratified 2026-08-15 and parked the same day (the medallion move was reverted: its palette content on row 0x1D changed the select→VS fade's CYCLES enough to cost the Victor-vs-Jedah legacy pairing (replay 38) one main-loop iteration on the H/P/merged builds — data-only is not cycle-neutral on a frame at the VBL edge). NOTE the lesson: "the palette path never transits work RAM" is true of the palette WRITE and false of the STAGING copy — a moved palette row means a moved staging slot, and the mask (plus the vanilla basis) must move with it | designed diff (sticky staging copy) | [D: 14z-64 slot identification; 14z-87b byte-attributed triage; tests/audit_mask_window_ff42a2.sh] |
| `RAM:$FF06D0-$FF06EF` (observed `$FF06DE.l`) | a SECONDARY STACK region: return addresses of the per-frame OBJ-builder call chain `PRG:0x1ABFC-0x1AC40` (a run of `bsr.w` into the list walkers 0x1AC68…0x1BC9C, reading `$79A2..$79D3(A5)`). On a heavy screen-transition frame the frame-done sample catches the main loop mid-chain, and a build whose earlier per-frame work costs different cycles (14z-88: the palette-fade staging math is DATA-dependent) sits one `bsr` further along — `0001AC1C` vs `0001AC20`/`0001AC18`, one byte at `$FF06E1`, one frame, identical the next frame. Execution POSITION, not state. NOT masked (it is live stack); attributed per replay by `tests/audit_mask_window_ff42a2.sh`. **EXTENDED 14z-93 (GitHub #78, maintainer-ratified 2026-08-16):** this row used to add "and it appears only on tenant-content replays where no vanilla oracle applies" — that is no longer true. `tests/test_fbneo_legacy_oracle.sh` measures it on LEGACY content under FBNeo, where MAME shows ZERO difference at the same frames, and it is now a RATIFIED §4 phase class bounded by a FROZEN offset inventory (`$FF06D1/D4/DB`); a byte differing inside the window but outside that inventory FAILS as growth | phase (execution position at sample) | [D: 14z-88 full-RAM dump-diff pre/post medallion move on 22/23/24/26/28 (f11862/f12313/f8800/f12407/f12827) + disassembly of the bsr chain; 14z-128 ours-vs-vanilla dump-diff on 105_legacy_2pwin_auto f5868, MAME, all three tenant builds — `$FF06D8-$FF06D9` and `$FF06E1`, 3 bytes, ONE frame, re-converged. Note the offsets: the FROZEN inventory in this row is the FBNeo phase class's (`$FF06D1/D4/DB`); the HOOKED-BUILD case on MAME lands elsewhere in the same window, which is why it is attributed PER REPLAY and not by a shared inventory] |

## System / match globals

| Address | Meaning | Evidence |
|---|---|---|
| `RAM:$FF8004.l` / `$FF8008.l` | match-active check: both == 0x40000 → in-match (alt: $FF8008.w==2 && $FF800A.w>0) | [C] |
| `RAM:$FF0CC9` | EEPROM-derived bootup-count byte (differs per boot count; the FBNeo determinism bug tell) | [D] |
| `RAM:$FF811B` | P1 select-screen cursor slot (changes by ±1 per cursor step) — CAUTION: also observed oscillating every few frames during select (session 3 comparator work); prefer player block +0x382, which tracks the hovered character id live during select | [D] |
| `RAM:$FF8203` | P1 match-config byte, char-correlated but NOT the char ID (00 Demitri / 02 Victor / 02 Bulleta) | [D] |
| `RAM:$FF8290` | screen left edge (camera) | [C] |
| `RAM:$FF8100` | the **arcade-ladder STAGE index**, written by `0x00af10` as `pool[$FF8114]` from the table-B pool at `$FF1E50` (sign-extended byte). Legal values are the even `0x00..0x16` — the twelve stages, decoded by `tools/decode_stage_banners.py`. Consumers: `0x05ffa6` computes `A0 = 0x26775A + 2*v - 4` and STORES it to `$1c(a6)` (the banner-record pointer; the deref of the FOLLOWING row happens downstream), `0x01bf5e` indexes a `0xA0`-strided palette block into `$90C2C0`, `0x004daa` indexes a dispatch at `v/2 + 9`. `v=0x18` selects row 0x1A whose follower is the table's own `0x00400000` terminator → #92. **RETRACTED 14z-94: this row previously called `0x18` "the pool's TERMINATOR" and said consumers "must treat `0x18` as end-of-list, not as a class".** The selector at `0x00aeca` has NO compare against `0x18`; its only exits are the `$FF8138` bound and the in-use mask, and `0x18` in table B is simply a stage value vsav has no stage for. The terminator that reading described lives in the OTHER table — see the `$FF1E48` row below | [D: 14z-93 (chain), corrected 14z-94 by reading `0x05ffa6`/`0x00aeca` and confirmed in-emulator — poking this word changes the venue on screen] |
| `RAM:$FF8114` | the SELECTOR into the voice-class borrow pool (`0x00af10` reads `pool[$FF8114]`). **Nothing measured yet bounds it below the terminator index** — at the #92 crash it was 2 and the pool's terminator was at index 2 | [D: 14z-93] |
| `RAM:$FF8109` | round timer (counts down ~1/sec during match) | [D] |
| `RAM:$FF810E` | ~~rounds-completed counter (+1 per settled down)~~ **RE-MEASURED 14z-118: a round-PHASE byte, not a monotonic counter** — 0 while fighting, 1 the frame the down settles (`f3608` on both timeout legs), back to 0 when the next round spawns (`f4082`), `0xFF` at the match's end/reset (`f4934`), 1 again at the next match's first refill, 0 at its round start (`build/timeout_{ctl2,inv2}_trace_14z118.log`). The 14z-104 reading saw only the 0->1 edge | [D: 14z-118, two vanilla legs, per-frame; supersedes 14z-104's single probe] |
| `RAM:$FF8105`, `RAM:$FF810C` | the WINNING SIDE of the settled down as a code — **1 = P1 won, 2 = P2 won** — written the same frame as `$FF8120`; both clear at match end | [D: 14z-118, ctl (P1-won) = 1/1, inv (P2-won) = 2/2; frozen in `audit_tenant_timeout.sh`] |
| `RAM:$FF8107`, `RAM:$FF810D` | set at the settled down (`0x01`, `0xFF`); `$FF810D` clears at the next round's spawn, `$FF8107` at match end — phase flags, side-agnostic | [D: 14z-118, both legs identical] |
| `RAM:$FF1E2A` | the ATTRACT DEMO counter (`a5-0x61D6`), +2 per attract cycle, wraps at 16; indexes the demo table `PRG:0x005C08` (above) | [D: 14z-118 trace; static `test_attract_roster.sh`] |
| `RAM:$FF8120` | ROUND WINNER code, written when a down settles: 0xFF = P1 won the down, 0x01 = P2 won, **0x00 = DRAW (double KO — measured on mirror trades, 14z-104 (4))**. Verified discriminating in all three directions. Consumed by audit_tenant_timeout / audit_tenant_downwin / audit_edge_cases | [D: 14z-104] |
| `+0x381` (`$FF8781`/`$FF8B81`) | **the PLAYER-SIDE index: 0 = P1, 1 = P2** — written once at init by `PRG:0x0058A4` (`move.b #$0,$781(a5)`) / `0x0058AA` (`move.b #$1,$b81(a5)`) and again by `0x009074` (`move.b d0,$381(a6)` in the per-player init), never at pick time (word-aligned write tap over three replays, `build/c381_tap_14z118.log`). The per-character palette routines use it as `id = BASE + (side<<2) + phase`, so a character's palette-seq block is 4 ids per SIDE — a mirror match never shares a sequence | [T+D: 14z-118; `engine_internals.md` "THE FAMILY RULE"] |
| `RAM:$FF8127` | ~~P1 downs-won counter~~ ~~(14z-118 first reading: 1 after a P2-won down)~~ **RESOLVED 14z-118 by its WRITER: a per-frame COMPARATOR, not match state.** `PRG:0x02228E`: `d1 = (P1 object)+0x10; cmp.b (P2 object)+0x10,d1; beq/bcc -> 0, else 1; move.b d0,$127(a5)` — i.e. **1 while P1's fighter-object byte `+0x10` is LESS than P2's, 0 otherwise**, written every match frame (11,972 writes in 5,300 frames of the timeout rig; toggles for 1-46-frame spans in a 2P match). Both earlier readings were this comparison caught at a down or a refill. **`+0x10` is a byte of each fighter's current ANIM NODE (`+0x1C` → node `+0x10`), not of the fighter object** — a per-pose draw-order/depth key (vocabulary `{42,43,57,58,59,89,91,106,107,121,122,123,139,154,155,170,171,202,203}`), so `$FF8127` selects which fighter draws in FRONT (`1` = P1 in front, `0` = P2). Identity `front = (P1node[+0x10] < P2node[+0x10])` measured exact on every non-capture frame of replay 37 (5,486 agree, 0 violations); during a capture the read is the attacker-supplied pose (all 1,440 exceptions inside capture windows ±8 f). Gate `tests/audit_front_comparator.sh` (this row said "unmapped: OPEN" until 14z-123) | [T+D: 14z-118 write tap `build/c8127_tap_14z118.log`; M: 14z-123 `audit_front_comparator.sh`; the two 14z-104/14z-118 single-edge readings retracted] |
| `RAM:$FF8440` | the "?" (random-select) cell's walker CURSOR — index into the draw table, advanced every 3 frames while the cell is hovered; the one byte that moved on `40_pick_pyron_cell` at the 14z-117 (2) freeze, zero bytes at match | [D: 14z-117 (2), DUMPS diff pyron34 vs pyron35; mechanism `select_screen.md` "THE RANDOM CELL"] |
| `RAM:$FF0000.w` | **CPU-EXCEPTION CODE, written by the game's own exception handlers** (14z-109). Every 68k exception vector (`vec2` bus .. `vec11` line-F, targets `PRG:0xC0-0x140`) runs `move.w #code,($FF0000).l` — code = vector-2 (0 bus, 1 address, 2 illegal, ... 9 line-F) — then saves registers and SOFT-RESTARTS the game (see the two rows below and engine_internals "CPU exceptions"). **A "flaky reset" that reboots to the NAME SCREEN is one of these, and this word says which**; a cold/watchdog reset runs the full gold RAM test instead. Confirmed live: probe-H vec3 wrote 1 here; the 14z-109 field video shows the abbreviated white check list then the name screen | [D: 14z-109 — handler disasm (`verify_op` 0xC0-0x14E) + guarded vec3 + field video] |
| `RAM:$FF0018-$FF0053` | **registers at the last CPU exception**: the handler's `movem.l d0-a6,-(sp)` from SP=`$FF0054` lands D0..D7/A0..A6 ASCENDING here (A1 at `$FF003C`, A3 at `$FF0044`). **Written only if the handler RUNS** — a guard/debugger that freezes the machine AT the exception leaves this region stale (measured: all zeros under the crash guard while the live registers held the answer; read them via `GUARD_PROBE`, not from RAM) | [D: 14z-109, handler disasm + the empty-dump measurement] |
| `RAM:$FF0054.l` | saved SP at the last CPU exception (written by the same handler, before the register block) | [D: 14z-109] |
| `RAM:$FF06CC.w` | one return-address word BELOW the `$FF06D0-$FF06EF` OBJ-builder secondary-stack window — the same execution-position class one bsr level deeper; the ONLY bytes that move on tenant content between donovan-m13 and donovan-m14 (14z-111, the AI-script port: different per-frame interpreter work at select entry / match start), state byte-identical | [D: 14z-111, 9 dumps on 36_pick_tenant_cell] |
| `RAM:$FF05xx` | sound-driver work area (differs between MAME/FBNeo boot phase). **RATIFIED §4 phase class 14z-93 (GitHub #78, maintainer 2026-08-16)** for the FBNeo legacy oracle: the window `$FF0500-$FF05FF` may differ on FBNeo where MAME shows zero at the same frame, bounded by the FROZEN inventory `$FF055B-$FF055D` in `tests/test_fbneo_legacy_oracle.sh`. Not gameplay state; growth outside the inventory FAILS rather than widening | [D] |

## Player blocks — P1 `$FF8400`, P2 `$FF8800` (0x400 apart) [D, corrected]

**Correction (session 3):** the community "P2 = player + 0x100" refers to
sub-object slots; the actual P2 player block is `$FF8800` (verified: 2P
run shows Victor's hitbox base at `$FF8860`, `$FF8500` zeroed). Each block
is 0x400 bytes; combat struct at +0x000, further state above +0x100.

| Extended-block offset | Meaning | Evidence |
|---|---|---|
| +0x382 (`$FF8782`/`$FF8B82`) | selected character ID at select/commit — but IN MATCH it is the **VOICE-FLAVOR CLASS** for the per-node sfx dispatcher (`PRG:0x27F16` → table `0x0BF41A`), and the engine REASSIGNS it mid-match: the voice-class borrow (sequencer event → `PRG:0x0AEF6`) writes a class from the opponent-row candidate list, so a match-time read is NOT the char id (measured 0x06/0x0C/… on a Donovan P1; 14z-87, engine_internals "third pass"). Select-time behavior unchanged: updates live with the hovered slot (verified both emulators); write 0x18 = Oboro (TCRF cheat) | [C:tcrf, D, 14z-87] |
| +0x18B | PALETTE DESTINATION ROW for the object's palette copy — the vanilla copier `PRG:0x02AD20-0x02AD80` does `move.b $18b(a6),d0; lsl.w #5` and writes 16 entries at `palette_page + row*32`. Measured 0x0b on a Donovan P1 during Press of Death (14z-126b) | [D: 14z-126b] |
| +0x3A4 (.l) | PALETTE SOURCE BASE POINTER, read by the copier's `movea.l $3a4(a6),a0` arm at `PRG:0x02ADAC`. CONSTANT in practice — written twice in a 14,375-frame run, at round starts, by `PRG:0x01C68E` (Donovan: `0x0CEB50`, a PORTED block table; vanilla holds 0xFF filler there). The varying part is the SEQ ID the caller passes, not this | [D: 14z-126b] |
| +0x3AE | EFFECT-PALETTE INDEX read from the OWNER by the port's resolver hook `PRG:0x3FFAF0`: when a pool object's owner (`+0x30`) is a tenant, the base is `[0x38C1E4] + (+0x3AE)*128`. Shipped but NOT exercised by Donovan's Press of Death, whose palette is driven by the PLAYER object instead — the lifetime hazard behind #112 (engine_internals "EFFECT PALETTES ARE OWNED BY THE PLAYER") | [D: 14z-126b] |
| +0x392.w (`$FF8792`) | ~~special-meter gauge CANDIDATE~~ NOT an engine meter (14z-121 (4)): its only writer in vs2's engine range is `0x4D0C0` (`move.w (a1,d6.w),$392(a6)` from a small table), inside ONE character's code block (vs2 id 0x0C's, `0x4A9C2-0x4E650`), no engine reader — a per-character work word; the 0→0x500→0x1400 steps were that character's | [D: static, 14z-121 (4)] |
| +0x205 (`$FF8605`/`$FF8A05`) | CPU AI script INDEX into the class's table-0 block (`0x2CCB6`: `move.b (0x205,a6)` -> word offset -> script start) | [D: 14z-111, trace + write tap on crash-merged-m8-01] |
| +0x210 / +0x214 / +0x218 / +0x21C (.l) | CPU AI script CHANNEL CURSORS 0-3 — start written by the four starters `0x2CCB6/0x2CCF2/0x2CD40/0x2CD9C` from tables `PRG:0xBF01A/09A/11A/19A` (row `+0x382<<2`), advanced by `0x2B934` (`move.l a0,(a6,d1.w)`, d1 from a `+0x204`-keyed word table); `+0x224` mirrors channel 0's start. CPU-side ONLY (2P never writes them). Vanilla values live in `PRG:0x100000-0x1122xx`; a tenant's in his relocated `x100000/x100e3c/x101aca` block after 14z-111 | [D: 14z-111] |
| +0x241 (`$FF8641`) | CPU AI script CURRENT COMMAND byte — the 15 nested interpreter dispatchers `0x2B96A..0x2C7D0` do `move.b (0x241,a6),d0; move.w (6,pc,d0.w),d1; jmp (2,pc,d1.w)`; the jump command case at `0x2BD72` writes `move.l #$0200060E,(4,a6)` (class 02 / seq 6 / sub-state 0x0E) | [D: 14z-111] |
| +0x242 / +0x244 / +0x246 (.w) | the three stream words each script command pulls (`move.w (a0)+`); `+0x244` copies to `+0x20B`, `+0x245` to `+0x232` and drives a sub-dispatch, `+0x246` to `+0x208` (countdown) | [D: 14z-111] |
| — the ARCADE-LADDER pick block (14z-87, `A5=$FF8000` frame). `0x00af16` copies **8 bytes from each of two parallel tables** into `$FF1E48` (table A, `0x00B268` — candidate CLASSES) and `$FF1E50` (table B, `0x00BB68` — the STAGE for each), both at row `$382(a0) << 6` plus the venue byte `$FF8121`. `0x00aeca` then scans ONE index across both: it takes the first candidate whose class bit is free in the in-use mask, writes that CLASS to the opponent's `$382`, and writes table B's byte at the same index to `$FF8100` as the STAGE. So one ladder entry is a pair, "fight this class at this stage". **RETRACTED 14z-94 — this row said "THE LIST IS TERMINATOR-DELIMITED BY `0x18`" and that `0x00af10` "read the TERMINATOR as a class".** Two tables were conflated. It is TRUE and universal that **table A** ends each group with `0x18` at index 7 (measured over all 36 rows × 8 groups), but the selector never reaches it — the scan bound `$FF8138` measures 6 — and there is no compare against `0x18` anywhere in the loop. The crash pool `0e 12 18 0a 00 14 16 0a` is a **table-B** group, byte-identical to huitzil's authored row group 3, where `0x18` is not a terminator but a stage vsav does not have. The "pool holds DOUBLED values" reading goes with it: table B values are even because the consumer does `add.w d0,d0` and indexes longs. | pool `RAM:$FF1E48` (8 candidate classes, from ROM `0x00B268` row `(0x382,a0)<<6 + $FF8121`), stage list `RAM:$FF1E50` (from ROM `0x00BB68`, same row and index), in-use mask `RAM:$FF8110.l` (bit = class, `btst` so it is MOD 32 — a class ≥ 32 aliases; sound-state-fed, the run-to-run lottery), chosen index `RAM:$FF8114.w`, scan bound `RAM:$FF8138.w` (=6 measured), venue byte `RAM:$FF8121` — **the venue byte is a plain BYTE OFFSET into the row: the copied pool is `row[venue .. venue+7]`, so an even venue mid-group SHIFTS THE WINDOW across group boundaries** (measured 14z-109: poking all twelve even values `0x00-0x16` before the draw, each first-draw equals `rowA[venue]` exactly — e.g. Donovan row: venue `0x02`->Phobos-on-stage-`0x02`, `0x10`->Bishamon-then-Phobos, the two field crash contexts; 14z-110: an ODD poked venue vec3s the pick itself at `PC 0x00AF46` — steer with EVEN values only, vanilla never writes odd) | [D, 14z-87; retracted and re-derived 14z-94 by reading `0x00af16`/`0x00aeca`; venue-window semantics measured 14z-109 (12-value poke sweep)] |

## Combat struct (player block +0x000) [C, verified D/T]

| Offset | Meaning | Evidence |
|---|---|---|
| +0x0B | flip_x (facing) — **1 = the fighter faces RIGHT** (P1 at the left start, P2 on its right, reads 1; 0 after the engine crossed the fighters — measured 14z-120 (2), `tools/name_moves.py`) | [C; D: 14z-120] |
| +0x0A | attack id (shift 5 for hitbox lookup) — [C]; the sampled value was 0 at every frame-done of the 14z-120 (5) rigs (transient); the attack RECORD a node uses is its `hbA>>8` (engine_internals "Hitboxes and attack records") | [C; D: 14z-120] |
| +0x10.w | X position (signed) | [C: script default, matches update_object] |
| +0x14.w | Y position (signed) | [C] |
| +0x1C | anim ptr (node write: vs2 walker PC 0x2713C / vsavj 0x27EE8 family / ported walker 0xCE38A) | [C] |
| +0x20 | anim node timer (node duration byte countdown; held while +0x5C runs) | [D: 14z-42] |
| +0x32.w | attacker/owner attribution link (word addr, sign-extends to the player block; reaction handlers deref it for attacker-side writes) | [D: 14z-26/42] |
| +0x5C | hit-freeze counter (blocks +0x20 decrement; set per hit on BOTH victim and attacker by the reaction handlers — electric-shake pair: vsavj 0x23AC8 writes 0x18/0x0B where vs2 0x226E0 writes 0x0C/0x04; engine-generation drift, see engine_internals) | [D: 14z-42] |
| +0x50.w | current HP (round start = 0x120 = 288) | [D] |
| +0x52.w | white/displayed HP (regenerating damage). **THE ROUND JUDGE KILLS ON THIS WORD'S SIGN, not +0x50's** (14z-98, GitHub #103): in-match phase-6 handler `PRG:0x97DC` tests `tst.w $852(a5)`/`tst.w $452(a5)` at `0x97FC/0x9804` (vs2 twin `0x800C/0x8014` — same offsets, not a generation drift). The damage pipeline keeps white <= hp (applier `0x18AB0` subtracts staged `$FF3442/44` from BOTH words), so white crosses zero FIRST; the death decision `0x18A46-0x18A66` then runs the kill commit. A state with hp < 0 and white >= 0 is UNJUDGEABLE — the engine never sees the death (#103's stall shape) | [D: 14z-98] |
| +0x54.b | reaction/hit-state id written by the near-death commit `0x18B34` from attack byte `$17(a3)` (observed 0x11 during a death, 0x05 during regen) | [D: 14z-98] |
| +0x56.b / +0x5A.b / +0x59.b / +0x5D.b | per-contact copies from the attack record: `+0x19` → +0x56, `+0xF` → +0x5A, `+0xC` (hit) / `+0xD` (block) → +0x59, and +0x5D = the victim's FACING resolved by the record's `+0xE` rule (vs2 `0x1717E`) | [D: 14z-121 readers, static] |
| +0x38.b | nonzero = OFF THE GROUND (1 on takeoff, `0x22174`; 0xFF while held by a throw — measured 14z-121 victim rig); the pushbox separation gives the whole overlap to the airborne one; the +0x161 accumulator needs it 0 | [D: 14z-121] |
| +0x13A.b / +0x13B.b | the white-damage RECOVERY counter and its reload — `+0x13A` counts down each frame (`0x20DF2`), reloads from `+0x13B` and refills +0x52 by 1; set per contact from table `0x18018[record +0x1B]` (fixed 1/3 while +0x1C3) | [D: 14z-121 static] |
| +0x141.b | the hit-freeze class of the last contact (record `+0x13`), the index into the freeze pairs table `0x17FA4` | [D: 14z-121 static] |
| +0x15B.b | the per-character threshold of the +0x161 accumulator, loaded at init from the bank row `byte15b` (`0x0BE87A`, = 60 for all) | [D: 14z-121] |
| +0x15E.w | the DARK-FORCE ARMOR timer: 0x200 for SASQUATCH's Dark Force (LP+LK / MP+MK activation, `PRG:0x047EDA`, `+0x18F` clear → the +0x161 accumulator gates the armor; an HP+HK activation never arms); 0x7FFF with `+0x18F` = 1 for Aulbath's DF (`PRG:0x045FAA`) and the engine/character 0x7FFF sites (`0x23532/0x23570/0x2377A/0x3DA60`, `0x45FA4`, `0x4C78E/0x4C7A0`, `0x4D020/0x4D040` — full armor, no accumulator); counted down by the timers block `PRG:0x0224AA`; cleared at DF end. (This row said "0x7FFF at four sites … 0 on every rig … arming states OPEN" from 14z-121.) | [M: 14z-123, `tests/audit_df_accumulator.sh`] |
| +0x161.b / +0x162.b | the armor accumulator of attack-record `+0x1C` values while +0x15E is armed and +0x18F clear, and its 240-frame decay (both cleared at expiry `PRG:0x0224B4`, at a normal-reaction contact, and at DF end); the contact whose sum passes +0x15B (60) reacts normally and resets it — Sasquatch's Dark Force, measured: Victor cr.LP +20, cr.MP +30 armored, + cr.HP 40 BREAKS. (This row said "live only for an Aulbath victim" from 14z-121 — retracted.) | [M: 14z-123] |
| +0x1A4.b | per-contact copy of record `+0x1E` | [D: 14z-121 static] |
| +0x59.b | **the PUSHBACK step-table index** of the current reaction (record `+0xC` on hit / `+0xD` on block, `0x172DA`); `0x27038` steps x from `0x2783C[+0x59]` each frame and returns 1 at the list's end = the hold release | [D: 14z-121 (3), write-tapped through 5LP/5MP/5HP] |
| +0x164.w | the pushback step counter (cleared at the contact `0x1714A`, +1 per step at `0x2705A`) | [D: 14z-121 (3)] |
| +0x1B0.w | the ADVANCING-GUARD push step counter (`0x27082` walks `0x2797A[+0x59]`, 91/115/157 px over 11/16/20 steps, on the ATTACKER while `+0x185`) | [M: 14z-123, `tests/test_advancing_guard.sh`] |
| +0x170.b | the guard-MASH counter: fed by each NEW button press (`+0x126 & 0x77`) while the block window `+0x1AB` is open — vs2 adds a strength weight 1/2/3 and fires at >= 10; vsavj adds 1 and below 8 rolls the RNG against the mask table `PRG:0x028D50` (3: 8/32, 4: 16/32, 5: 24/32, 6+: always) | [M: 14z-123] |
| +0x1AB.b | the ADVANCING-GUARD window: 14 on a grounded block (class `0xFF`; OPENED by the grounded-block entry handler at `PRG:0x02395A`-`0x023966` — `+0x140` = 2, `+0x158` = 0xE, `+0x1AB` = 0xE —, COUNTED DOWN by the System Timer Reducer `PRG:0x02246E`, which also decrements `+0x147/+0x174/+0x143/+0x158`; 14z-123 wrote "handler `0x2246E`" from the write tap, which names the decrementer, not the opener — corrected 14z-126, mizuumi's name for `0x2246E` is right), counts down per engine tick; presses after it count for nothing. Never set by a throw (Victor's 6MP hold, Sharirum Luna: 0 throughout) | [M: 14z-123; opener/reducer D: 14z-126] |
| +0x185.b | ATTACKER: guard-push active (set by the check `0x267B8` / vsavj `0x275CE` with `+0x1B0` = 0, `+0x5D` = flip_x ^ 1, `+0x59` = the completing press's strength class; cleared by the list terminator) | [M: 14z-123] |
| +0x184.b / +0x171.b / +0x3B5.b | BLOCKER after a fired guard push: `+0x184` = 1, `+0x171` = 0x10 (a countdown, consumer untraced), `+0x3B5` = 4 (untraced); `+0x5C` = 1 the same frame. Anakaris (`0x06`) never counts and is never pushed | [M: 14z-123; the two consumers open] |
| +0x11F.b | DEATH FLAG, set by the kill commits (`0x18A7C` hp:=-1+white:=-1 flavor; `0x18B12` near-death flavor; `0x2980A/0x29810` the arcade-KO instance measured live). Read with +0x111 by the settle helper `0x995A`, which dispatches the dead fighter per-char through `0x0BF61A` row `$382<<2` (dispatch_19, PORTED at row 0x13) | [D: 14z-98] |
| +0x60.l | per-character hitbox data base (ROM ptr; Demitri 0x93B6A, Victor 0x9769E) — a table of WORD offsets base[0..4] from itself (14z-120 (5)) | [T,D] |
| +0x64.l | per-character ptr from table PRG:0x0BD9FA = the hitbox FAMILY table (`hitbox_comp`): 4 bytes per entry {vuln0, vuln1, vuln2, push}, indexed by the anim node's hb8 word; +0x94.l is the current entry | [T; D: 14z-120 (5), `tests/test_hitbox_encoding.sh`] |
| +0x80/84/88/8C/90.l | hitbox table pointers: +0x80/84/88 = base+base[0..2] (the three VULN tables), **+0x8C = base+base[4] = the ATTACK records (0x20 each), +0x90 = base+base[3] = the PUSH boxes** — measured from the live pointers 14z-120 (5); the community note had the last two crossed. Box = (x, y, hw, hh) signed words, authored for the LEFT-facing sprite (x negated when +0x0B = 1) | [C,T; D: 14z-120 (5)] |
| +0x94..0x97 | current box ids (vuln×3, push) = the family-table entry selected by the node's hb8 | [C; D: 14z-120 (5)] |
| +0x98 | throw box id | [C] |
| +0x102 | resolved strength/flavor byte (written by the ES/strength resolver — ported code 0xCF598 on our build) | [D: 14z-44] |
| +0x105 | ~48f transient raised by performing any special (gauge-blink family; NOT the stock) | [D: 14z-44] |
| +0x107 | resolver marker: 0xFF = single-button, 0xFE = pair downgraded (no stock); NOT meter consumption | [D: 14z-44] |
| +0x109 | **BANKED STOCK COUNT** (cap 0x63=99; the displayed stocks). The ES resolver tests this for two-button presses — poke it (ff8509 P1) to script ES moves | [D: 14z-44, disasm] |
| +0x10A.w | current meter-bar fraction; full bar = 0x90 units -> converts to +1 stock (gauge adder caps/converts here) | [D: 14z-44, disasm] |
| +0x134.b, +0x11E.b | VICTIM-side hit gates: the hit test `PRG:0x018064` refuses the contact while the victim's `+0x134` (throw indicator: 0x01 executing a throw / 0xFF being thrown), `+0x147` or `+0x11E` is non-zero (`tst.b $134/$147/$11e(a1)`, a1 = the victim) | [D: 14z-126 static; the +0x147 branch measured by `tests/audit_df_startup_invuln.sh`] |
| +0x145.b | received MIDAIR combo hits (the hit test compares it against the attack record's `+0x14` juggle byte at `0x01808E`); +0x144 the grounded received-combo counter | [C from mizuumi; D: 14z-126 static for the +0x145 compare] |
| +0x1A4.b | per-contact copy of record `+0x1E` (row above); mizuumi names it "Air Combo Vulnerability Timer" | [D: 14z-121 static] |
| +0x147.b | **the VICTIM's INVINCIBILITY TIMER** — the hit test's gate (row above), decremented once per engine tick by the System Timer Reducer `PRG:0x02246E`. ARMED by: every character's own Dark Force seq-0x16 handler in its first sub-state (**the DF STARTUP INVINCIBILITY**, per character: BU/DE 0x29, GA/AU 0x22, VI 0x3B, ZA 0x46, MO/AN/LI 0x3C, FE 0x2E, BI 0x2B, SA 0x05, QB 0x03, LE 0x04, JE 0x7F re-armed to 4; the tenants' OWN vs2 handlers: Huitzil 0x4F, Pyron 0x29, Donovan 0x40 — `tests/expected/df_startup_invuln.tsv`), guard cancels (mizuumi's "Add N frames of invincibility" = `move.b #N,$147(a6)`, e.g. `0x02E19A` #$1E), and — the 14z-42 reading, still true — vs2's electric-shake handler (0x0C per hit, the multi-hit RE-HIT GATE: ~10f period with it, the victim freeze doubles as the gate without it). Natively on vs2 the DF path writes 1 (`0x025F2A`), cleared before frame_done — no window | [D: 14z-42 periods; 14z-126 gate + DF arm, measured 21 legs] |
| +0x143.b | the THROW invulnerability timer (the throw checks `tst.b $143(a1)` at `0x02941E`-family), same reducer. The SHARED DF activation body `PRG:0x027000` arms 0x14 (20 ticks) — the only GLOBAL half of DF startup protection; Anakaris/Aulbath/Lei-Lei's own handlers overwrite it with 0xFF for the mode (`0x03DA16`/`0x045D8A`/`0x04C6C0`) | [D: 14z-126, static + `audit_df_startup_invuln` samples 0x13 / 0xFF] |
| +0x1B3.b | ANAKARIS's "Dark Force start-up" flag (mizuumi's name is exact and character-specific): set to 1 by his own DF handler (`0x03DA54`), read only by his own moves (`0x03B77C`-family, the Pharaoh's Magic conditions), mass-cleared with the flag block at `0x026F7A`. NOT the general DF startup window — that is `+0x147` | [D: 14z-126 static] |
| +0x161.b | a per-character DARK FORCE WORK BYTE: Sasquatch's accumulator armor sum (measured, `audit_df_accumulator`) — and written by Bishamon's (`0x043664/0x0436C2`), Anakaris's (`0x03DECE`), Aulbath's (`0x046014`) handlers too; mizuumi's "Oboro Fight Flag" is Bishamon/Oboro's use of the same byte. Not a disagreement: one offset, per-character meaning | [D: 14z-123 measured; 14z-126 static writers] |
| +0x132.w | per-character word from table PRG:0x0BE17A | [T] |

## Projectiles

| Address | Meaning | Evidence |
|---|---|---|
| `$FF9400` + n*0x100 | projectile objects, 32 slots, same object layout family | [C] |

## Character ID space (from the per-character tables, see per-set atlas)

IDs are 5-bit: low 4 bits = character slot (16 slots), bit 4 = hidden/alt
variant. vsavj: variant space differs only at slot 0x08 (Bishamon → Oboro
Bishamon); all other alt slots alias the base table. Slot→name map:
docs/game/atlas/character_tables.md.

## The palette staging area — $FF3F02 + row*0x20 (14z-64)

The round-64 masked window `$FF4182-$FF41A1` was ratified as "the
palette-fade staging slot" for the 14z-49 row-0x14 port. 14z-64
identified the WHOLE structure: the engine stages palette-block rows
into per-row work-RAM slots at

    slot(row) = $FF3F02 + row * 0x20     (row 0x00 -> $FF3F02,
                row 0x14 -> $FF4182 = the ratified window,
                row 0x16 -> $FF41C2, 0x19 -> $FF4222, 0x1A -> $FF4242,
                row 0x1D -> $FF42A2 — the V3 window, 14z-88)

Venue events (screen transitions, the game-over sequence at ~f9126 of
replay 05, fades) stage block-A rows here and the copies PERSIST until
the slot is next reused — so any ROM edit to a block-A row shows a
sticky designed diff in its slot on the masked live-RAM basis. The V2
basis (14z-64, ratified with the donovan-m3a bundle) masks the slots of
the three medallion rows the WIDE track edits (0x16/0x19/0x1A), exactly
as round 64 masked row 0x14's; the V3 basis (14z-88, ratified 2026-08-15,
PARKED the same day with the medallion revert) added row 0x1D's slot —
the reminders that a palette-row move is ALSO a staging-slot move, and
that palette content in a fade's row set is cycle-relevant. Two measured
hazards recorded with it:
- block-A row 0x00 is NOT select-private: the game-over starfield
  renders from it (a row-0 edit leaked visible pixels — reverted);
- the slots are the DETECTOR for such leaks: a slot diff plus a pixel
  diff means a shared row; a slot diff alone is the ratified-invisible
  class.

## Object physics, air system, servants [D] (measured 14z-66)

| Field | Meaning | Evidence |
|---|---|---|
| +0x0A (pre-engage) | INTRO-ANIMATION VARIANT, RNG-drawn at char load (table16[rand&15] in the per-char init; per-opponent downgrade branch). Becomes the attack id once play starts | [D: oracle gate] |
| +0x40.l / +0x44.l | X velocity / Y velocity (16.16) | [D: mover disasm] |
| +0x48.l / +0x4C.l | X accel / Y accel (gravity) — the mover 0x27E-family integrates +0x48->+0x40->+0x10 and +0x4C->+0x44->+0x14 | [D] |
| +0x06/+0x07 (of +0x04.l) | seq id byte / sub-state byte (class-02 seqs: stepper 0x225C4, table 0x225EE; jump = seq 06 -> handler 0x22A0E; air dash = seq 0x14) | [D] |
| +0x20/+0x21 | anim node timer / node header flags — bit 7 of +0x21 = the FLOAT LICENSE, installed per node from the header long (node stride 0x18; +0xC low 13 bits = shadow-seq id) | [D] |
| +0x1C0.w | float duration timer (armed 0x78 by the float conversion) | [D] |
| +0x179 | air-action resource counter (0x10 at load; float start decrements) | [D] |
| $FF80D4/D5 | the engine RNG state (routine vsavj 0x14E8A) — poke to determinize cross-game comparisons | [D: oracle gate] |
| +0x2A/+0x2C (extended block) | registered SHADOW/REFLECTION servant slots (the class-0x0C trio per player; installer 0x8237E) — shared shadow tables 0x2083BC/0x2087CA (row space 0x40E each, hardcoded at 0x823E2/0x823F2), sequence data from 0x208BD8 | [D: 14z-66 FG arc] |

Per-char tables decoded (bank scheme: vs2 = vsavj + (0xD7298-0xBD0FA)):
`PRG:0x0BDB7A` jump_params — id*0x30, THREE 0x10 rows (neutral/fwd/back
jump) of (xv,xacc,yv,gravity); RAW id, no fold; 32-row with 0x10-0x1F
byte-aliasing 0x00-0x0F; consumer = the installer every seq-0600
starter bsr's (vsavj 0x27A34 / vs2 0x26C86). Capture-pose per-victim
sets at `PRG:0x0BCE7A/0x0BCEFA/0x0BCF7A/0x0BCFFA` (the Midnight-Bliss
family; 32 rows x 4 bytes each), read by the capture-victim installer
(indexed by VICTIM id, seq id from the ATTACKER's code).
**The installer is `PRG:0x27FA0` and it always uses `0x0BCFFA`
(anim_index_c) — the sibling-selecting entry `0x27FAA` is never executed
(0 hits vs 904, measured 14z-99). The index in D0 comes from the
attacker's capture-positioner node (`0x028072`) and is PER VICTIM; the
convention is shared between vsavj and vs2 (legacy victims install the
same index on both engines). See engine_internals "THE CAPTURE-POSE
INSTALLER" — this is the GitHub #104 surface.**

## Fighter + effect-pool fields (14z-67, measured on the H effect arc)

Fighter object ($FF8400 P1 / $FF8800 P2):
- +0x40 xv, +0x44 yv, +0x48 xacc, +0x4C gravity — 16.16 physics block
  (written together by the physics-row installer vj 0x28386; measured
  live on throw launches).
- +0x54 seq-related id fields (context-dependent; the effect machine
  reads its object's +0x54 as the EFFECT id).
- +0x318 / +0x320 / +0x330 / +0x340 — per-fighter effect-channel
  sub-structs (his handler passes a4 = &fighter+0x3n0 to the channel
  subs 0x28EE6/0x29124/0x29134/0x2916C-family).
- +0x382 char id (the per-char dispatch index — the seq-D head and
  the effect stage-2 record installer both read it).

Effect-piece pool $FFB800-$FFC7FF (32 × 0x80-stride slots; range
CORRECTED 14z-85 — the walker's own count byte is `move.b #0x20,($B5,A5)`
= 32 slots, this row used to say $FFBFFF/16 and understated the pool by
half):
- +0x00 alive/header (fleet spawner writes 0x01000800),
- **+0x02 TYPE byte** — the pool walker 0x5E52A's dispatch index
  (`move.b (2,a6),d0; *4` into the table at 0x5E556); written by header
  longs `move.l #$01xxTTss,(A4)` or byte stamps `move.b #type,(2,A4)`
  (the full frozen inventory: build/manifest/type_stamps.toml, 14z-82).
  On multi-tenant builds, non-first tenants' extended types (114-119)
  are RENUMBERED per tenant (engine_internals "Per-tenant TYPE
  NUMBERS"),
- +0x03 owner id / sub-state (written with the type by the spawn
  idiom; usage differs by family — pods: owner id, effects: sub-state),
- +0x0A subtype (fleet pieces 0x25/0x26),
- +0x1C record chain (head ptr; [head+4] = OBJ record — NULL until
  the anim stepper 0x1378A-family installs it),
- +0x18 bank word (fleet spawner inits 0; the subtype's first tick
  sets the real bank),
- +0x30 owner link (movea.w-compatible fighter pointer),
- +0x54 effect id / +0x56 sub-id,
- +0x7C-+0x7F: OUR hole_b code writes WORDS at +0x7C/+0x7E (PC
  0x3FFFD6) — a word at +0x7E covers byte +0x7F, so +0x7F is NOT free
  on this pool (14z-85; the 14z-84 "free" reading was a word-offset tap
  accounting artifact).

Projectile pool $FF9400-$FFB3FF (32 × 0x100-stride slots; expanded
14z-85 from the one-line row above): the 0x54470-site walker's pool
(head 0x54458: `lea ($1400,A5),A6`, stride `lea ($100,A6),A6`, live
test `tst.b (A6)`). Same layout family as $FFB800 for the low fields:
- +0x00 alive (the walker's own liveness test),
- +0x02 TYPE byte — walker 0x54458's dispatch index into the table at
  0x54484 (59 vanilla entries; extended 59-75 on tenant builds; the
  59-75 stamp inventory: build/manifest/type_stamps.toml),
- **+0x7F OWNER TAG (14z-85, tenant builds only)**: written at spawn by
  the detoured 59-75 stamp sites (`move.b #tenant_id,(0x7F,A4)` in the
  tag thunks; tag_map.json lists the writer PCs), read by the obj_hook
  64-75 tag stubs (`cmpi.b #id,(0x7F,A6)`). Measured free on vanilla
  paths: 804 live-slot obs, zero writes (byte-lane accounting), 3 legs
  incl. live family content — tests/audit_pool_free_byte.sh. Nothing
  clears it; stale tags in reused slots are unread by design.

Local pool $FFC800-$FFCFFF (24 × 0x80-stride slots; 14z-82): walked by
an embedded dispatcher INSIDE the x088512 span (src 0x8B988 =
x088512+0x3476, hui/pyron copies) with its OWN table at x088512+0x3494 —
its +0x02 type bytes are a SEPARATE small numbering space (0..~23),
nothing to do with the 0x5E556 table's numbers.

## CPS-2 VIDEO REGISTERS — CPS-A and CPS-B (documented 14z-108)

**This was a hole in the atlas until 14z-108** — grepping for layer control
returned nothing, and it is what decides whether a VRAM difference is
visible. Authority: MAME 0288 `src/mame/capcom/cps1.h:175-190` (CPS-A
indices), `cps1_v.cpp:499` (`CPS_B_21_DEF`, which **every CPS-2 game shares**
— `cps1_v.cpp:2034` maps the whole platform to the `"cps2"` config), and
`cps2.cpp:1289-1299` (the bus windows).

**THE BUS WINDOWS.** CPS-A `$800100-$80013F` (mirror) and `$804100-$80413F`;
CPS-B `$800140-$80017F` (mirror) and `$804140-$80417F`.
**CPS-A IS WRITE-ONLY** (`.w(...)`, not `.rw(...)`) — the 68k cannot read it
back, so it cannot be captured with a bus dump and the game must keep its own
copy. Reading it needs the emulator's memory SHARE (`cps_a_regs`), which is
how the values below were taken. CPS-B is read/write.

**CPS-A REGISTERS** (index = byte offset from `$804100`; **the register value
x 256 IS the 68k address**, e.g. `0x9080` -> `$908000`):

| off | name | note |
|---|---|---|
| `+00` | OBJ_BASE | |
| `+02` | SCROLL1_BASE | 8x8 layer |
| `+04` | SCROLL2_BASE | 16x16 |
| `+06` | SCROLL3_BASE | 32x32 |
| `+08` | OTHER_BASE | row-scroll table |
| `+0A` | PALETTE_BASE | |
| `+0C`/`+0E` | SCROLL1 X / Y | |
| `+10`/`+12` | SCROLL2 X / Y | |
| `+14`/`+16` | SCROLL3 X / Y | |

**CPS-B LAYER CONTROL is `+26`** (i.e. `$804166`), and the enable masks for
CPS-2 are **scroll1 `0x02`, scroll2 `0x04`, scroll3 `0x08`** (stars share
`0x30`). scroll2 and scroll3 additionally require videocontrol bits 2 and 3
(`cps1_v.cpp:2331-2335`).

**MEASURED ON `36_pick_tenant_cell` AT THE ROUND-1 MATCH ANCHOR (MAME frame
2886, the WIDE romset):**

| register | value | resolves to |
|---|---|---|
| OBJ_BASE | `0x9000` | `$900000` |
| SCROLL1_BASE | `0x9000` | `$900000` |
| SCROLL3_BASE | `0x9040` | `$904000` |
| SCROLL2_BASE | `0x9080` | `$908000` |
| PALETTE_BASE | `0x90c0` | `$90C000` |
| OTHER_BASE | `0x90e8` | `$90E800` |
| SCROLL1 X/Y | `0x0180` / `0x0100` | |
| SCROLL2 X/Y | `0x00c0` / `0x0300` | |
| SCROLL3 X/Y | `0x0180` / `0x0700` | |
| **CPS-B `+26` layer_control** | **`0x2d0e`** | **scroll1, scroll2 and scroll3 ALL ENABLED** |

So at a match anchor the live VRAM map is **scroll1 `$900000-$903FFF`,
scroll3 `$904000-$907FFF`, scroll2 `$908000-$90BFFF`, palette
`$90C000-$90D7FF`, row-scroll `$90E800`** — and everything from `$910000` up
is UNCLAIMED at that moment.
