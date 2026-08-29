# MiSTer field test and triage — the in-tree carrier (written 14z-114)

**Why this file exists.** `docs/project/mister_scope.md` §4 found that the
field test and its triage were narrated ONLY in `docs/NEXT_SESSION.md`
history banners (14z-108/109), STATE_HISTORY 14z-109, and the
`FIELD_TRIAGE.txt` card inside the out-of-tree bundles
(`../mister_fieldtest_14z11x/`). Skill 2.5 of the distillation needs a live
document to lock to; archived records are never edited and the bundles are
outside the retraction sweep (`README` item 5 went stale that way at
14z-108). This is that document. It is a LOG for the figures it carries — the
skill quotes it — and it names the record each one came from.

## 1. What hardware answers that simulation cannot

Three things, and as of 14z-113 all three have happened by a HUMAN'S verdict
and none by an instrument's:

| question | simulation | the board |
|---|---|---|
| is the picture right? | never compared — VRAM is not an oracle, the OBJ list agrees, pixels have no instrument (`mister_core.md` §12) | select screen "emulator-identical" by eye (14z-109); stock coexists on the same card (14z-113) |
| is a ported voice HEARD? | FETCHED (DSP bank `0x83`, `test_mister_qsound_ext`) — fetched is not heard | HEARD (14z-109); never measured |
| does it survive real SDRAM, real timing, the analog chain? | fit yes, timing a seed lottery (`platform/mister.md` "SYNTHESISING") | boots, plays, feel "better than emulator" (14z-109); re-confirmed 14z-112/113 |

**[MSV-31]** **Every hardware verdict is a person at a CRT.** No frame and no audio has
ever been captured off the board. That is the standing hole, not a
complaint: the cheapest pixel oracle this project has IS the field test.

## 2. Before the board: the bundle and its control

The bundle is `release/<name>/mister/` since merged-m10
(`docs/project/release_format.md`): the WIDE MRA, the `[STOCK CONTROL]`
MRA, `jtcps2w.rbf` (hash-verified against `BITSTREAM.txt` by the packager),
`MISTER.md`. Field bundles before 14z-113 were assembled by hand outside the
tree.

**WHAT IS AND IS NOT A CARD BUNDLE (14z-116 — the maintainer asked, so it is
written down).** A hand-assembled bundle directory holds only two things the
SD card wants — `_Arcade/` (the two MRAs) and `games/mame/` (the zips). The
loose `*.rom` files and the `mra/` tree beside them are jtframe BY-PRODUCTS
of generating those (the download images and the upstream MRA tree); nothing
on the card reads them. **And a sibling directory suffixed `_stock` is the
STOCK LEG of the same run** — `tools/mister_mra.sh --core cps2w` *without*
`--wide`. **Measured 14z-116: it is a STRICT SUBSET of the WIDE bundle** —
every file in it exists there too, byte-identical, except one MRA where the
WIDE bundle's copy is strictly better (it carries the assembled `.rom`'s
`asm_md5`). So it holds nothing the real bundle does not, and there is
nothing in it to field-test. Safe to delete; one command regenerates it.
**Two things it is NOT, both easy to assume:** it is not "Jotego's core"
(its MRAs carry `<rbf>jtcps2w</rbf>` — OURS; the stock CPS-2 core `jtcps2`
appears nowhere in either directory), and it is not how you check stock
behaviour — that is the `[STOCK CONTROL]` MRA in the WIDE bundle's
`_Arcade/`, which runs stock `vsavj` on OUR bitstream and is the superset
invariant on silicon. `_stock` ships no `games/` zips, so on its own it
runs nothing at all. The only thing its `mra/` tree adds over `_Arcade/` is
the full REGION catalogue on our core (Euro/USA/Asia/Brazil/Hispanic/Japan/
Phoenix); no gate covers it and it would need the zips beside it.

**CHECK A BUNDLE'S CURRENCY BY HASH, NOT BY ITS NAME.** A bundle is current
iff its `games/mame/vsavjw.zip` matches the freeze's
`build/<dir>/rompath/vsavjw.zip`; the other three zips are the pristine
parents from `$ROMDIR`. `../mister_fieldtest_14z115/` was verified current
against `build/m3b_merged18` this way at 14z-116; `../mister_fieldtest_14z117/`
(merged-m12, M10) was assembled at 14z-117 from `tools/mister_mra.sh --wide
build/m3b_merged19` output and verified against `build/m3b_merged19`
(vsavjw.zip sha1 `6f566053…`; its STOCK CONTROL MRA is byte-identical to
14z-115's, the `.rbf` unchanged); `../mister_fieldtest_14z117b/` (merged-m13,
M11, random select includes the tenants) likewise at 14z-117b, verified
against `build/m3b_merged20` (vsavjw.zip sha1 `f0f9cd1b…`). **Its README was missing**
— every earlier bundle had one — and was written at 14z-116; if a bundle is
assembled by hand again, the README is part of it.

1. **Verify the `.rbf` hash before flashing** — a timing-failing seed emits an
   indistinguishable bitstream (`platform/gotchas.md`). The record is
   `BITSTREAM.txt`: seed 18269, sha256 `46fc74af…`, 3,111,944 B.
2. **[MSV-21]** **Every MRA part must resolve against the EXACT zips on the card.**
   **[MSC-69]** jtframe fills an unresolved part with `0xFF` rather than refusing, so a
   half-resolved set "runs" and shows nonsense. `tools/check_mra_parts.py`
   / `tests/test_mra_parts.sh`: WIDE 31 of 31 parts, STOCK CONTROL 22 of 22,
   both against the pristine `vsav.zip` (since 14z-112 the build packs no
   parent; the patched group-A members live inside `vsavjw.zip`, so one card
   carries this profile AND stock Vampire Savior — field-confirmed
   2026-08-28).
3. **[MSV-32]** **Never test without the control.** The 14z-108 bundle shipped ONE MRA;
   14z-109 added `[STOCK CONTROL]` before it was run: stock `vsavj` on the
   SAME `jtcps2w.rbf` with the profile byte left at the `0xFF` fill — the
   emulator superset invariant on silicon, not a second core.
   STOCK boots + WIDE fails -> the problem is OURS (highest-value report).
   STOCK fails too -> not ours: the bitstream, the SDRAM module, the card or
   the video chain. **[MSV-22]** Since the bitstream, not the romset, is what this
   control certifies, it needs running once per NEW `.rbf` (seed, slice or
   pin), not per romset release (STATE "Decisions pending", recommendation;
   the maintainer asked, did not rule).

## 3. What a good boot looks like (stopwatch figures)

After the ROM download: the RAM-test pattern for about 4.5 s, the
Capcom/QSound legal screen about 15 s after reset, then attract. Those are
simulated frame counts at the real 59.6374 Hz, so a phone stopwatch is a
valid instrument. The DOWNLOAD is NOT comparable — on hardware it runs at
HPS speed, in simulation at ~1 s/frame.

## 4. The symptom table (from `FIELD_TRIAGE.txt`, 14z-108, kept current)

| symptom | means | do |
|---|---|---|
| no picture, no sync | not us: core not loaded, or the analog/Jammix chain | load any known-good jtcps2 core on the same setup |
| sync, black, nothing ever | core runs, game does not: download incomplete, a part unresolved, or a bad placement | run the STOCK CONTROL; re-verify the `.rbf` hash |
| RAM test, then restart, over and over | **[MSV-33]** **time the loop.** ~26.5 s (a ~1,580-frame cycle) is the pre-D5 decryption signature — the 68k executing ciphertext above 4 MB. Fixed in every shipped build; seeing it means the fix is not reaching hardware. Any other period is a different fault and the number IS the diagnostic | report the period; run the STOCK CONTROL |
| attract fine, select wheel wrong (cells missing / vanilla 18) | an MRA part did not resolve, or the wrong zip on the card | confirm the zips; `check_mra_parts` |
| the three ported characters present but art garbled / wrong character | the group-C art path; historically the CRC hash-shadowing trap, not rendering | photograph; compare `docs/project/images/mister_select_cps2w_f2400.jpg` |
| pick a ported character -> hang / crash / reset | the interesting one: in simulation it fights correctly and matches MAME field-for-field | note EXACTLY when (confirm, VS screen, round start, mid-round) and which character |
| **name-screen reboot after a brief white-on-black check list** | a CPU EXCEPTION — the game's own handler soft-boots (exception code at `RAM:$FF0000`, registers at `$FF0018-53`); distinct from the gold FULL self-test, which is a cold start / watchdog | **record it** (§5) |

## 5. Field reports are recordings (CLAUDE.md §4, maintainer-ruled 14z-111)

**[MSV-34]** A board crash or misbehaviour is captured FIRST as a hand-played MAME
recording on the same freeze — `WIDE_RECORD=<name> tools/run_wide.sh <build>
mame`, named `<what>-<freeze set>-NN` (the freeze it was PLAYED on), tracked
under `tests/inp/<name>/` with a one-line `NOTE` — before any mechanism
theory. `tools/run_inp_guarded.sh` replays it with a write tap on the game's
own exception store and yields vector, fault PC, registers and stack;
`tests/test_inp_corpus.sh` replays every tracked recording at every freeze.
**[MSV-35]** **The board is a witness, not the instrument.** Paid for by #99: the field
crash (Donovan 1P -> beat Bishamon -> CPU Phobos, 100%, board AND MAME by
hand) was game DATA — CPU-Phobos playing Demitri's AI through an aliased
script table (STATE_HISTORY 14z-111) — and never the core; three sessions
were spent on a rig-derived mechanism before the first recording found it in
an evening. Scripted rigs that win fast never give a CPU opponent the time to
reach its rarer scripts.

## 6. Where the records are

| what | where |
|---|---|
| the field verdicts | STATE_HISTORY 14z-109 (3) (first boot, voices heard, the #99 crash), STATE 14z-112 (green board on M8), STATE 14z-113 (bundle 14z112: no regression, stock coexists, STOCK CONTROL boots) |
| the bundle READMEs and the original triage card | `../mister_fieldtest_14z11x/` — outside the repo (rule 7: they carry zips). **[MSV-36]** A claim corrected in the tree does NOT reach them: sweep them by hand |
| the crash-triage kit | `docs/NEXT_SESSION.md` (HISTORY) 14z-109 banner "CRASH-TRIAGE KIT"; `tests/lua/inp_guard.lua`, `tools/run_inp_guarded.sh`, `tools/run_inp_probe.sh` |
| the bitstream record | `release/bitstreams/<CURRENT>/BITSTREAM.txt` |
