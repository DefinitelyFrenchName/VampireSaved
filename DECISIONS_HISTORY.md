# DECISIONS HISTORY — resolved and superseded decisions, verbatim

**Split out of STATE.md 14z-109 (maintainer-directed, 2026-08-26).** STATE.md's
standing decision sections had accumulated every ruling since July under
"Decisions pending", struck through in place — the actually-open items were
drowning in the resolved ones. This file holds the RESOLVED and NO-LONGER-
SHAPING entries, moved **byte-verbatim** (strikethroughs, analysis blocks and
all); STATE.md keeps only genuinely pending decisions and recent rulings that
still shape current work.

**How to use it:** decisions resolve by TOPIC — grep this file for the subject
("packaging", "anim block", "composite", ...). Every entry carries its original
dating and ruling inline. Entries are NEVER rewritten here; a decision that is
later reversed gets its reversal recorded in STATE.md and a marker added
ABOVE the old entry, pointing forward.

**The lifecycle rule — AMENDED 2026-09-14 (maintainer-ruled, CLAUDE.md
[VSP-17]):** a decision is born in STATE.md "Decisions pending" -> when it is
RULED, the whole entry moves HERE verbatim in the commit that records the
ruling, and STATE.md keeps one line stating the rule under "Standing rulings"
for as long as it constrains work. Nothing is marked DECIDED in place any more.
*(The superseded rule, 14z-109 to 2026-09-14: the ruling was marked DECIDED in
place first, and the entry moved here only once it stopped shaping work. Entries
moved under it keep their in-place markings verbatim; the rule was replaced
because rulings marked in place stayed in the open list.)* The CLAUDE.md §5
retraction grep covers this file.

---

## Ruled 2026-09-20 (14z-173) — #144 is macOS BLOCKING the binaries, the old workaround is withdrawn; the applier page ships local, per release

**#144, settled by capture.** The maintainer double-clicked both prebuilt binaries and
sent the dialogs: *"fbneo" Not Opened — Apple could not verify "fbneo" is free of malware
that may harm your Mac or compromise your privacy*, with only **Done** and **Move to
Bin**, and the same for `cps2`. Asked directly whether right-click > Open gets past it:
*"Does not open"*. So the advice this project shipped — right-click > Open once — is
**FALSE on current macOS and is WITHDRAWN** from every live carrier
(`build_release_emulators.sh`'s record text, the launcher's refusal in
`package_release_platforms.py`, `release_format.md`, a comment in `bundle_dylibs.py`);
re-grepped, nothing live still recommends it. What is measured to work is clearing the
quarantine flag, which `PLAY.command` offers to do. The four shipped `BINARY.txt` records
still carry the old sentence and correct themselves at the next macOS emulator build,
which the maintainer had already ruled the right move (*"correct move."*). **THE FIRST OF THOSE CAME BACK THE SAME DAY AND IS DECISIVE:** System Settings >
Privacy & Security > "Open Anyway" DOES work — *"yes BUT needs the open anyway for the
executable AND for libSDL3.0.dylib. After that it launches"* — but it is **per blocked
file**, and a bundle is not one file. Counted in the M19 packages: **MAME needs 2**
approvals (executable + `libSDL3.0.dylib`, exactly what the maintainer hit) and **FBNeo
needs 24** (executable + 23 bundled libraries). Twenty-four trips through System Settings
is not a recommended path, so the READMEs give both routes, lead with the one-step
quarantine clear (`PLAY.command`, or one `xattr -dr` line) and state the 2-vs-24 cost so
the player chooses knowingly. The maintainer's reading of the MAME case is also right and
is why the launcher exists: MAME's front-end lists only what is on its configured rom
path, so double-clicking it gives a GUI with no game, and *"the rest is likely 'just'
scripting to launch the emulator directly with the rom as target"* — which is what
`PLAY.command` does. STILL UNMEASURED: whether `PLAY.command` is itself blocked on a
double-click; the maintainer could not find one because the launcher exists only in the
unpushed M19 tree and the published assets are M18, so the file was sent to them
directly. Notarization remains the only fix that removes the question, and it is a paid
Apple Developer account — the maintainer's call.

**#146, the brief for the READMEs**, in the maintainer's own words:

> *"the simplest way for me to describe them is : 'it must have felt clear to the expert
> who wrote them'. Same issue as I encountered often in my work: things arbitrarily
> considered obvious not explained or quoted, step by step than nonetheless assume the
> reader has some understanding of the development of that project, nevermind that the
> user is usually not a developer, and basically never on the project."*

Acted on the same sitting: the player READMEs are rewritten for someone who is not a
developer and has never seen this project — every term glossed on first use (`dump`,
`romset`, `driver`, the fingerprints), the three steps stated before any detail, the
"Play on…" section MOVED to directly after the build step rather than the end of the
file, and the troubleshooting list led by the macOS block because that is the first
thing a Mac player hits.

**The applier page (§6 of `applier_app_scope.md`).** Where it lives: *"preferably a local
file in the asset"*. Whether a browser page is acceptable for players handing over ROM
files: *"I would suppose so, in any case that's not a blocker as of now so we can assume
yes"*. The third question was asked badly — *"not sure what you mean"* — and is answered
in the document rather than re-asked: shipping inside the asset means one page per
release, sitting beside that release's own files, with no version-matching for the player
to get wrong.

## Ruled 2026-09-20 (14z-173) — the applied set is DEFLATED, and the QSound BIOS member is OPTIONAL

Three questions were put to the maintainer after the standalone set landed. Their answers,
verbatim:

**Compression** — *"If it is identical content, I see no reason not to go for the smaller
size (I assume it's loaded decompressed in ram by the emulator/mister anyway so there's no
decompression overhead, right?)"* The applier now writes `ZIP_DEFLATED`: **73.7 MB -> 28.0
MB** for byte-for-byte identical members, which is all any check here compares (per-member
SHA-1), so compression sits outside the comparison. THE ASSUMPTION WAS MEASURED RATHER THAN
AGREED WITH, and it is right about the part that matters and not quite right as stated: the
ROM does end up inflated in RAM, so there is no per-frame cost, but there IS a one-off
inflate at load — MAME boot + 1 s of emulation, two runs each: **stored 1.67 / 1.69 s,
deflate 1.90 / 1.98 s, so about +0.26 s once**, to save 45.7 MB. The MiSTer side is
UNMEASURED (no hardware here): the ARM inflates while streaming to SDRAM, trading that
against 46 MB less SD-card I/O. A first attempt at this changed only the `ZipFile(...)`
argument and left the set at 71 MB, because `writestr` with an explicit `ZipInfo` uses
THAT object's `compress_type`, which defaults to STORED — caught by measuring the output
instead of trusting the flag.

**The QSound BIOS member** — *"Ideally I'd love the option to choose to add it or not. The
main reason is that most people playing on emulator would likely want a fully
self-supporting rom since they already have to use a custom version of the emulator however
MiSTer players will have their own qsound file present on their MiSTer as soon as they play
any CPS-2 game and our wide core should leverage that by default"*. So `dl-1425.bin` is the
one OPTIONAL completion member: `apply_release.py` includes it by default and
`--no-qsound-bios` leaves it out, which also stops the applier demanding `qsound_hle.zip`
among the dumps at all. The manifest marks the entry `optional` and carries a second key,
`applied_set_key_no_qsound_bios`, and the applier checks whichever variant it wrote against
the declaration. The three properties the per-platform READMEs now rely on are ASSERTED, not
stated (`test_release_binaries.sh` 3d): **MAME refuses** the smaller set (`dl-1425.bin - NOT
FOUND`), **FBNeo runs it identically** to the full one (its descriptor omits the member;
zero `(not found)`, same RAM and same framebuffer over 12,120 frames), and the **WIDE MRA
resolves all 31 of its parts — 30 from `vsavjw.zip` and the BIOS from the card's
`qsound.zip`**. The MiSTer page therefore tells players to use `--no-qsound-bios`; the
emulator pages tell them to use the default.

**The four stale `BINARY.txt` run lines** — *"correct move."* The generator is fixed and the
shipped records, which are written at emulator-build time and hash-linked to the binaries,
are left to correct themselves at the next macOS emulator build rather than by a hand edit
of a generated record.

## Ruled 2026-09-20 (14z-173) — THE DELIVERABLES: the order of work, and macOS FIRST

Asked for my view on the state of the deliverables, the maintainer set out theirs and
then ruled the order. Their assessment, verbatim:

> *"There is hardly any pressure on the timing"* — *"MiSTer is basically good"* —
> *"Linux & windows require dedicated environments. which is doable but parallel to
> MacOS"* — *"The most important is the prebuilt libraries, not the full DIY process.
> It implies two things: 1) making sure the OS accepts to run the binary 2) make it
> stupid easy to run, because as things stand users will try by default to run FBNeo
> or Mame and fail because even with the WIDE drivers, using it through the default
> GUI does not work. So either provide an alternate shell script that runs the
> emulator the way we want or at least make it super obvious what to do, and that
> also includes where to put all the ROMS. And speaking of which there is an
> argumetn to make vsavjw standalone because at the moment ir not only requires
> qsound but also vsav and vsavj, or so the patched emulators say"* — and on the
> applier: *"Can't we package a nice tiny app (Web, OS-agnostic or one per OS, I
> don't really care) that is self-supporting executable-wise and just asks the roms
> and provides vsavjw.zip from it? Because the developers won't care but the immense
> majority of the users will."*

THE ORDER, put to them and agreed: **standalone set → launcher per platform →
reproduce #144/#145 on clean hosts → README pass written against the new, smaller
shape → the applier app.** The standalone set is first because it shrinks the
instruction surface everything else has to describe, and because it changes the
layout, so it wants to land BEFORE the READMEs are rewritten.

THE CAVEAT, which is itself the ruling on release scope, verbatim:

> *"Agreed with one caveat: let's focus on MacOS first, even if we were to release
> M19 only for MiSTer and MacOS, the proof of concept would be fully validated and
> we could go forward knowing the windows and linux can run parallel while we go
> forward with other tasks"*

So: **macOS and MiSTer are the proof-of-concept release; Windows and Linux proceed in
parallel and do not block it.** #145 (Windows) leaves the near-term path; #144 (macOS
binaries) and #146 (the READMEs) stay on it. One correction recorded with the ruling:
the emulators want `vsav.zip` + `qsound_hle.zip` at runtime, NOT `vsavj.zip` — that
one is a build-time source only, and the impression came from `tools/run_wide.sh`
symlinking all six reference zips into its play overlay.

## Ruled 2026-09-20 (14z-173) — the standalone set lands in the RELEASE, not the build (route (c))

Two routes were measured and put to the maintainer:

- **(a) build-side** — the build packs the 7 completing members. One artifact: what the
  gates measure is exactly what the user runs. But `wholeset_key()` hashes every member
  of every zip in the rompath, so all four tracks' keys move: new registry rows, carried
  and re-frozen expectation sets, the re-point sweep, a MiSTer catalogue regen plus a
  fork commit (the `mame.xml` entry is CRC-pinned and enumerates members), and the ~5 h
  freeze battery. An **M20 freeze**, with M19 superseded before it ever shipped.
- **(c) release-side** — the applier completes the set. M19 ships as frozen; no
  fingerprint, expectation set, registry row or MiSTer CRC moves. The cost is that the
  shipped zip is a declared SUPERSET of the gated one.

Recommended (c), on the grounds that it ships M19 now — which is what the proof of
concept needs — and that the one honest objection to it, gated artifact ≠ shipped
artifact, is closeable by machine rather than by argument. The maintainer ruled:

> *"C"*

The objection is discharged by `test_release_roundtrip.sh` §1 (every authored member
byte-identical to the build's, every ADDED member byte-identical to the reference member
the manifest declares, an undeclared addition a FAIL, the whole set hashing to
`applied_set_key`) and by the new `test_release_binaries.sh` §2b (the shipped release dir
applied, that set ALONE in the rom path, producing a whole-RAM log bit-identical to the
build arrangement's on the same binary — a live A/B, no frozen expectation, no registry
row for a key that moves every freeze). The spec is `docs/project/release_format.md`
"THE STANDALONE SET". Deferred and NOT bundled: the applier writes `ZIP_STORED`, so the
standalone set is 73.7 MB where deflate gives 28.0 MB — a shipped-shape change outside
what was approved, raised separately.

## Ruled 2026-09-20 (14z-171) — the naming rigs' stock poke: land it ONLY as a DEMONSTRATED prophylactic

The sitting proposed changing the rigs' stock pokes from two per part to one per event,
first as a repair for ES events firing on an empty meter. Put to the maintainer with the
measured cost (176 stock samples excluded from the parity comparison) once the repair
story had been falsified — no part was ever measured to run dry — the ruling was a
CONDITION, in their own words:

> *"I lean landing, if and only if it's a demonstrated prophylactic that will catch
> regression there should they pop up. As usual, it's a matter of : is it measured or is
> it wishful thinking. If it's measured, then it's coverage that might never be useful but
> that is at least relevant, which is a tradeoff I'm ready to accept. But it has to be
> demonstrably the case not just a neat idea"*

The poke ALONE did not meet it: prevention is not detection, and every gate would have
stayed green had it silently stopped landing (the rule-checker's Q4, run `2026-09-20-84`).
So the condition was met by BUILDING the detection half — `audit_move_parity` section 2b,
the stock each leg had at every event of every meter part, demonstrated both ways over the
full corpus. Landed on that basis.

## Ruled 2026-09-20 (14z-171) — land the stock fix, ticket the pin fix as #168, keep it on the next priorities

With the pin fix measured, working and destabilising three input-window-edge events, the
choice put to the maintainer was (1) land the stock fix alone and ticket the pin fix, (2)
land both and re-tune the three recipes, or (3) land both and freeze the regressions
(advised against). Their words:

> *"Do 1 but the complement ticket to reach "2" should be on the list of next priorities,"*

So the pin fix is GitHub **#168**, filed with everything measured and its generator patch
attached, and it sits at START HERE item 4. Earlier in the same sitting, on the narrower
question of whether to fix the stock pokes at all:

> *"let's do A, I think it's safer and the cost we'd have to pay eventually anyway"*

and on where to pick #168 up:

> *"I'd rather pick up #168 first"* — taken with the close finished first, so the next
> session opens on a green pushed tree.

## Ruled 2026-09-20 (14z-171) — #162 is parked, not closed

On the orange flash, once the sitting had answered its open question (it is not a
sequence-id defect; ours' row 11 baseline is Donovan's sprite-palette block):

> *"We can put #162 on ice while we do the rework"*

Parked, not closed: the ticket stays OPEN with one measurement outstanding — which path
sets `a0` to the sprite block — and its facts were homed in
`docs/game/engine_internals.md` [VSP-186] before it was parked, so parking loses nothing.

## Ruled 2026-09-20 (14z-170 close) — M19 is FROZEN, NOT RELEASED: the release waits on the per-OS deliverable tickets

**What was put (the close report, after the freeze, the green close tier and the pushes):** *"Still open: #161 (Phobos's remaining +1), #162 (the orange flash), #163 (the column and the trap on an airborne victim — I extended its open item to the trap, since both were measured only on a grounded victim). M19 is frozen, not released; the release run is yours to call."*

**Ruling (verbatim):** *"let's not release now, especially since we have tickets relative to the deliverables on various OS."*

**What it means.** The M19 release run (`--scope all --lane all --strict --controls`, then the asset upload on `freeze/merged-m19`) does NOT follow this freeze. It waits on the open deliverable tickets: **#144** (macOS blocks the release packages' prebuilt binaries), **#145** (Windows: the prebuilt binaries fail to load the game), **#146** (the player READMEs are not complete enough) — each reported and none yet reproduced or fixed. `release/merged-m19/` stays packaged and gated in-tree; the freeze tags and the registry rows stand. The same sitting's other word, *"I say we close and pick up further work in a fresh session"*, closed 14z-170.

## Ruled 2026-09-19 (14z-170) — the column KO under the class-0x52 rule reads clean on the capture (#163)

**What was put:** rule-checker run 2026-09-19-62 (Q2) found the column-KO finding drawn from RAM traces alone (the reaction class reads 8 on native, M19 and M18, traces matching). A capture was made (`build/rc170/ko_cap/column_ko_sheet.png`: donovan_4 with Demitri's HP poked to 1 so the column's first hit at f2838 KOs; native vs2, M19 and M18 at eight frames) and sent with: *"Column KO (Demitri's HP poked to 1, so the column's first hit at f2838 KOs), shown at the same frames. Rows: native vs2, M19, M18. The column/trap ticket stays open until you've read this one."* A second image, the win-pal lose leg's matched window, was sent for reference only.

**Ruling (verbatim):** *"looks clean to me"*.

**What it means.** The column KO under the M19 rule plays as native. #163 keeps one open item: a column hit on an airborne victim (the air stager's case), not measured.

## Ruled 2026-09-19 (14z-170) — the maintainer's reads of the fixed build's captures: the column, and Phobos's and Donovan's EX inputs

**The question (as put, with four capture sheets sent first — the column, the Plasma Trap, Phobos's and Donovan's EX inputs, `build/rc170/cap_fix/`):** *"From the four sheets I just sent: does the fixed build play the column, the Plasma Trap and Phobos's and Donovan's EX inputs as you expect from vs2? (The rule-checker requires your read of captures before I call the fixes verified.)"*

**The reads (verbatim):** *"Let me proceed one by one, starting with Column_KillshreadLightning_after_fix: - The fix is mechanically perfect - The orange flash at 2860 is cosmetic but strange as it's the sprite of the stand-like entity above Donovan that turns orange instead of staying blue: looks like a wrong palette since the rest is clean, just the colors swapped. Only cosmetic however why it happens would answer whether it's a minor side effect or something that could have impacts elsewhere. Plasma trap : I can't rule for now because the move does not just seem to end at a different frame, it seems it starts at a different frame so I would need more frames from the beginning of the move until the activation of the trap and frames until the end of recovery, on all builds. Phobos_263PP_after_fix -> clean Donovan_421KK_after_fix -> clean"*

**What it means.** The column and both EX inputs read as native on the captures. The trap was re-shot with the speed level and RNG pinned and read *"Yes, as expected"* (the entry below); the flash became #162; the column KO was read on its own capture (the entry above).

## Ruled 2026-09-19 (14z-170) — the orange flash on the column's deity is a cosmetic ticket (#162); the pinned Plasma Trap plays as expected

**The questions (as put, with the captures before the maintainer):** *"The orange flash turns out to be an older cosmetic defect (merged-m18 has it). Our build loads a fire palette into row 11 as the move ends, while native keeps it blue, so the deity's last frame shows orange. How should I treat it?"* — "Ticket it, go on (Recommended)": *"File a cosmetic ticket with the captures and the measurements so far. Root-cause it later, then the freeze proceeds."*; "Root-cause it now". And: *"Pinned, the Plasma Trap plays identically on native and the fixed build, and the fix removes only Phobos's own hit-stop. Does it play as you expect now?"*

**Rulings:** the maintainer selected *"Ticket it, go on (Recommended)"* and *"Yes, as expected"*.

**What it means.** The flash is #162, frozen AS MEASURED by `tests/audit_column_flash.sh`; its writer, first misread from a `-debug` watch, is the palette-SEQUENCE uploader (STATE 14z-170 row (12)). The trap's fix stands as built.

## Ruled 2026-09-19 (14z-170) — Phobos's remaining +1 damage from Demitri's 5HP after the defense-row fix: freeze M19, ticket it

**What was measured first (STATE 14z-170; rule-checker run 2026-09-19-60 found it in the re-frozen attribution table):** after the ruled defense-row fix Phobos takes 12 where native vsav2 takes 11 from Demitri's 5HP (merged-m18: 13), on both parity rigs that land the hit (huitzil_5 f5966, huitzil_6 f7725), deterministic across three RNG pin values (0000, 1234, 5a5a — `build/rc170/freeze/dmg/`), while his curve row and rally threshold answer vs2's bytes live (`tests/audit_defense_row_residue.sh`). A second per-victim factor in the damage chain remains, unidentified.

**The question (as put):** *"How should M19 handle it?"* — "Freeze, ticket it (Recommended)": *"Freeze M19 as built (the ruled fix is in and moves 13->12); the two attribution rows get an honest open class — 'Phobos takes more with the defense rows already native: cause unmeasured', frozen AS MEASURED — and a new bug ticket carries the damage-chain trace for a later session."*

**Ruling:** the maintainer selected *"Freeze, ticket it (Recommended)"*.

## Ruled 2026-09-19 (14z-170) — audit_continue_switch is re-authored: P1 idle to a natural KO, and assertion 2 checks the KO is judged into a new match

**What was measured first (STATE 14z-170):** at the M19 freeze the #99/#103 continue-with-switch marathon went red — Phobos's vs2 defense row lets him survive the scripted mash to a TIMEOUT, so no natural KO loss occurs (phase-1 mapping, `build/rc170/freeze/contsw/`). With P1 idle through the first match, CPU Bulleta KOs him naturally (f8080, no pokes) and the loss is judged: YOU LOSE, the quote, the same-character continue prompt, a new match (captures `build/rc170/freeze/contsw/phase1b_post_ko.png`) — but through `$FF8004` mode 6 -> 2, not the mode 8 the old trajectory showed. The continue landing on Jedah was measured NOT to be a defect: pristine vsavj's Victor on the same rig lands on Jedah too.

**The question (as put):** *"How should I proceed?"* — "Re-author as described (Recommended)": *"Idle P1 until the natural KO, assertion 2 checks the KO is judged into a new match within 1600 frames (mode path recorded, not required), then re-measure the switch window and venue steer until assertions 3-5 hold again; every change written into the gate's header with the measurements."*

**Ruling:** the maintainer selected *"Re-author as described (Recommended)"*.

## Ruled 2026-09-19 (14z-170) — freeze M19 this sitting

**The question (as put, 08:05Z, the four #136 fixes and the x2b7ef4 resolver fix built and verified on a scratch build, uncommitted):** *"The four #136 fixes plus the placeholder-corruption fix are built, verified against native and your captures, and through the rule-checker, all uncommitted, as they must be until a freeze. Freezing M19 means: moving aside the withdrawn M19's leftover build dirs, building the five tracks, re-freezing every expectation the fixes move (each through the rule-checker), registry rows, tags, the re-point sweep, filing the tickets, and the ~5 h emulator battery. That's several hours. How do you want to proceed?"* — "Freeze M19 now (Recommended)": *"Start the freeze ritual this sitting. The battery runs detached, and I report as it goes. The fixes can only be committed green with the freeze."*; "Stop here, freeze next": *"Save the fixes as a patch (the 14z-169 way), commit only what's green against merged-m18, and close. The next sitting starts with the freeze."*

**Ruling (08:10Z):** the maintainer selected *"Freeze M19 now (Recommended)"*.

**What it means.** The M19 freeze ran this sitting (STATE 14z-170 row (8)): five builds, the expectation sets re-frozen, the emulator battery, and the rule-checker's freeze runs 2026-09-19-56..76 — the last reading OK. Recorded here at the close (rule-checker run 2026-09-19-76, its Q5 note): STATE row (8) had kept only the answer; the question, both options and the two times are quoted from the session's own records of the question and the answer.

## Ruled 2026-09-19 (14z-170) — the x2b7ef4 placeholder corruption in the shipped builds: M19 supersedes M18, and its reachability measured first

**What was put (STATE 14z-170 row (5)):** attributing the four #136 fixes' program delta found a latent generator bug — the x2b7ef4 companion-effect pass resolved its `0xEE` coordinate-list placeholders by an in-place scan, which re-read a resolved pointer's `0xEE..` low word as a placeholder — so merged-m18 ships 52 corrupted sites (Donovan's copy 40, Pyron's 12; the 22-site class also in merged-m16 and -m17), each a pointer turned odd; the corrected resolver is required for M19 regardless, since the fixes' +0x30 shift re-rolls three more.

**The questions (as put):** *"What about the published M18?"* — "M19 supersedes it (Recommended)": *"Land the generator fix with the M19 freeze, file a ticket now, and leave merged-m18 as published. It gets replaced when M19 is released."*; "Hotfix M18 first": *"Cut an M18.1 release with only the generator fix …"*. And *"Should I find out which Donovan effect draws the corrupted records before the freeze? That's a read watch over the corrupted addresses across his naming parts, about 15-20 min. It would tell you how exposed M18 players are."* — "Measure it now (Recommended)" / "Skip it".

**Ruling:** the maintainer selected *"M19 supersedes it (Recommended)"* and *"Measure it now (Recommended)"*.

**Measured the same sitting (`build/rc170/reach/`):** a `-debug` read watch on merged-m18 over Donovan's copy (all 14 Donovan naming parts, his movelist) and over Pyron's corrupted span (his 6 parts): the corrupted spans are never read in a match (Donovan: all 53,924 in-match reads fall in one other 1 KB block, each attributed by an address register inside the window — the heuristic's positive control; Pyron: the boot sweep only). Which effect draws the corrupted records is not established.

**CORRECTED later the same sitting (14z-170), marked in place:** the Donovan runs above were VOID. Every debugger stop advances the watch script's frame counter ([CPE-5]), and his watch covered a block read thousands of times per match, so those replays desynced by up to ~5,700 frames and never played the moves. (Pyron's six runs took only the boot stop and were sound.) Re-measured soundly by `tests/audit_x2b7ef4_reach_m18.sh`: the watch covers the corrupted bytes only and is armed at frame 2000, and each debug run's P1 anim-node trajectory is checked against a non-debug run. **The conclusion stands:** no Donovan part (14) and no Pyron part (6) reads a corrupted record on merged-m18. 18 of the 20 runs are frame-exact with the reference to the end; donovan_10 and donovan_12 skew by one frame at f2980 and f3537 with no stop, deterministically, and read none in the runs they played. The hot-block control (the widened watch) hits 5,572 times from f2363 and then desyncs.

## Ruled 2026-09-19 (14z-170) — Pyron's 2623+PP with stock reads NATURALLY (its 623+PP ES move), refining the no-stock ruling below

**What was measured first (14z-170, the EX-route fix built into `build/fix170_all`, `tests/audit_ex_refused.sh`):** the fix (each tenant's EX site takes vs2's no-stock branch at every stock level, one opcode byte) gives Phobos and Donovan vs2's no-stock path at stock 3 exactly — no mode, no stock spent. Pyron's does not: at stock 3 his vs2 EX input falls through to the sub-pattern 623+PP, which the host reads as the ES version when a stock is available — seq 0x10, five hits, the stock 3 -> 2 — where vs2 with no stock does the normal 623+P (seq 0x0E), as ours does with no stock. Capture put before the maintainer first (`build/rc170/cap_pyr/Pyron_2623PP_after_fix_sheet.png`: native vs2 no stock | ours fixed stock 3 | ours fixed no stock).

**The question (as put):** *"With the EX route disabled, Phobos and Donovan now do vs2's no-stock move at every stock level. Pyron doesn't: his 2623+PP falls through to 623+PP, which the game reads as the ES version when a stock is available (middle column: blue ES move, 5 hits, costs 1 stock). With no stock it's the normal 623+P, identical to native. Which should Pyron's 2623+PP do when he has stock?"* — "Natural reading (Recommended)": *"Keep it as built: the input reads as its 623+PP sub-pattern, i.e. the ES move when a stock is available and the normal move without one, the same as any input ending in 623+PP. No extra code."*; "Force the no-stock move": a new check recognising the full 2623+PP pattern to suppress the ES.

**Ruling:** the maintainer selected *"Natural reading (Recommended)"*.

**What it means.** The disabled EX route leaves each tenant's vs2 EX input to be read as whatever its sub-pattern is on our build: for Phobos and Donovan that is the no-stock move at every stock level (their sub-patterns have no ES version); for Pyron it is 623+PP — the ES move when a stock is available, the normal 623+P without one. The 2026-09-18 (14z-169) ruling below stands for Phobos and Donovan and is refined by this one for Pyron.

## Ruled 2026-09-18 (14z-169) — the disabled EX route does the NO-STOCK move, at every stock level

**The question (as put, with three capture sheets of the tenants' vs2 EX inputs with no stock, native vsav2 beside ours, `build/rc169/cap_ex/`):** *"The sheets show what each tenant's vs2 EX input does with NO stock (it can't enter Dark Force): the same move on vs2 and on ours for all three. Should the disabled EX route on our build do exactly that, for every stock level?"*

**Ruling (verbatim):** *"Yes, the no-stock move (I command you for the test you did and I appreciate the test because it shows the same moves are getting out in both cases, which is what we want (and none of these moves are the EX input btw, Pyron is 623+P, Donovan is 1+K, and Phobos I'm unsure but my point is: because there is no stock the pattern being interpreted is a sub-pattern of the VS2 EX input.)"*

**What it means.** With the EX route disabled, each tenant's vs2 EX input produces what vs2 produces when the EX cannot be paid for — the move read from a SUB-PATTERN of the EX input (the maintainer: Pyron's 623+P, Donovan's 1+K; Phobos's unnamed) — whatever the stock. Measured: that move takes the same state path on vs2 and ours (`tests/audit_ex_refused.sh`). Refines the 2026-09-18 (14z-168) EX-route ruling below.

## Ruled 2026-09-18 (14z-169) — the class-0x52 fix is scoped to the tracks that carry its machinery (S1)

**The question (as put):** *"The 0x52 fix for the column and the trap needs machinery that only exists on Donovan's tracks. On the solo Phobos track (not shipped, but it must not crash), how should the trap be handled?"* — S1: *"Keep Phobos's two trap remaps on the solo Phobos build only, via one new generator row key ('apply unless Donovan's manifest is in the composition'). The merged build gets the full fix; the solo Phobos build keeps today's trap behaviour."*; S2: the machinery moved to a shared manifest.

**Ruling:** the maintainer chose *"S1: scoped row (Recommended)"*.

## Ruled 2026-09-18 (14z-169) — the four #136 fixes are GO

**The question (as put):** *"Go-ahead to build the designs? Each gets its own commit, the gates re-frozen through the rule-checker, and the pass-counter lag check over the corpus on the combined build."* — Gauge (#157 tail), Defense rows, 0x52 rule, EX route.

**Ruling:** the maintainer selected all four: *"Gauge (#157 tail),Defense rows,0x52 rule,EX route"*. The designs: STATE 14z-169 rows (8)-(9), `docs/NEXT_SESSION.md`, the ticket drafts `build/rc169/gh/`.

## Ruled 2026-09-18 (14z-168) — the tenants' DEFENSE rows become vs2's (supersedes the 2026-08-14 option (b), 14z-85f)

**The maintainer's first reading (verbatim):** *"My undesrtanding is that Pyron is virtually the same in both options and that Donovan and Phobos see a +/- 1dmg overall through our approximation, whereas using their VS2 values would be a substantial change. If so I say we keep the approximation and create a ticket for a possible evolution. However, I want you to first compare the defense-side rows between characters present in both vsavj and VS2 and whether the approximated rows we are currently using are not, in fact, inherited from the shell characters. With  these additionnal information, I can rule definitively."*

**What was put, measured on both data views (vsavj `d82320a0…`, vs2 `ac31740c…`):**
- The 15 legacy characters' defense rows and rally thresholds are byte-identical between the games, except Sasquatch's row (a vs2 retune). vs2 changed no one else's defense.
- vsavj fills every variant-id row with a copy of its base character's row (Oboro 0x18 alone has its own). So the tenants' current rows are INHERITED FROM THE SHELLS: Phobos rides Bulleta's curve with a 56 HP rally threshold (native: Victor's curve, 40 HP). Donovan rides Victor's curve at 40 HP (native: the curve most of the cast shares, 48 HP). Pyron is identical either way.
- The two curves differ by exactly 2 rows at every attacker column. Measured effects: ±1 on throws, +2 on Demitri's 5HP against Phobos (13 vs 11), +1 on Victor's 5HP — "±1–2 per hit, not ±1 overall".
- The damage code reads the victim's own row (full id, `tests/audit_defense_row_residue.sh`), so rows 0x10/0x13 are the tenants' own storage, which no legacy character reads. That allows a possible data-only edit (the 14z-118 port_param32 pattern), not yet measured for the threshold read.

**Ruling (verbatim):** *"Defense rows: given the measurements we should take the vs2 rows. I hope we can do it in a way that doesn't cost frames and that doesn't create side-effects/regression elsewhere (e.g. it would be wrong to make changes that correct the 3 tenants but break vanilla characters)"*

**What it means.** Phobos and Donovan take vs2's defense rows and thresholds; Pyron needs nothing. The conditions are part of the ruling: no frame cost, and no change to any legacy character's behaviour (the superset invariant). The fix is sequenced by the 14z-168 order (analysis first). `docs/project/tables/defense_rows.md` carries the values and the recipe.

**The meaning of the conditions, clarified by the maintainer the same day (verbatim, of both 2026-09-18 fix rulings):** *"FYI : when I say no frame cost I don't mean " no cost at all", I mean "a total cost that doesn't end up introducing a new frame of lag (i.e. the total overhead cost of our combined changes is less than 1/60s at all times)"* — measurable as NO new zero-pass frame (the pass counter `$FF8081`, `tests/audit_pass_overrun.sh`) anywhere in the corpus with the fixes combined, against the build before them.

## Ruled 2026-09-18 (14z-168) — the column shock and the Plasma Trap take vs2's class-0x52 rule (supersedes the accepted deviation of 14z-85g(2) option (a))

**The question (verbatim):** *"I guess my question is: if we remap the shock as we expect it for Donovan, does that make Plasma trap closer or farther from VS2 behavior?"*

**The answer as put:** both moves carry vs2's class 0x52, whose rule is a 24-frame shock on the victim with the attacker exempt from hit-freeze.
- Plasma Trap today (remapped to vsavj's 0x06): the victim side is already right; the one deviation is Phobos's 11-frame attacker freeze.
- Donovan's column today: victim 12 frames (the 14z-42 Lightning Sword thunks) and a 4-frame freeze on Donovan per hit. Measured: native's recovery gap is 26 frames, ours 14.
- The vs2 rule applied to the class fixes the column AND removes the trap's last deviation. A Donovan-only fix would leave the trap as is, and would give Donovan vsavj's 11-frame attacker freeze.

**Ruling (verbatim):** *"then I'm all for fixing. Once again, as long as we don't introduce noticeable lag and we don't break more things, it's a pure win/win"*

**What it means.** The fix implements vs2's class-0x52 rule (victim shock 0x18, attacker exempt) for the tenants' 0x52-origin hits: Donovan's Killshread Lightning column and Phobos's Plasma Trap. Lightning Sword (class 0x4E natively) keeps its own tuning. The 14z-85g(2) "accepted deviation" (Phobos's attacker freeze on trap connect) is no longer accepted. The conditions: no noticeable lag (the performance rule) and no new breakage. The cost of routes on the existing 0x06-handler thunks is to be measured before a design is picked. The fix is sequenced by the 14z-168 order.

**The meaning of the conditions, clarified by the maintainer the same day (verbatim, of both 2026-09-18 fix rulings):** *"FYI : when I say no frame cost I don't mean " no cost at all", I mean "a total cost that doesn't end up introducing a new frame of lag (i.e. the total overhead cost of our combined changes is less than 1/60s at all times)"* — measurable as NO new zero-pass frame (the pass counter `$FF8081`, `tests/audit_pass_overrun.sh`) anywhere in the corpus with the fixes combined, against the build before them.

## Ruled 2026-09-18 (14z-168) — the maintainer's conclusions on the 14z-168 captures

- **The column shock (the every-frame capture and the RAM timeline):** *"yes but as you noticed it's not that simple because the move doesn't play out exactly the same since the timing of freeze, shock, recovery,etc. are slightly different. And I agree with your analysis."* The fix is in the entry above.
- **The block re-entry (vsavj re-enters the block animation, vs2 does not; ours = vsavj):** put to the maintainer, who proposed the test (*"To be sure we have two avenues: read the values in RAM or have the victim try to act on the first possible frame post blockstun. if the frames align then it's truly identical mechanically imho"*). Measured: first possible attack at hit+35 on all three games, with back held to +21 or to +50. Ruling: *"agreed, all the tests converge : it's identical"*.
- **Pyron's Dark Force form:** the palette was measured identical, and the pose phase realigns inside the move. Ruling: *"so that too is confirmed identical"*.
- **Donovan's Dark Force sword:** not RNG. Its idle loop starts 10 frames later natively; the flight path and hits are identical; the spin angle follows the idle phase. Ruling: *"My conclusion then is that it is identical, just looking slightly different because of the 10 frames of delay, but that is not a bug, just a consequence of the delay and my understanding is that the delay or lack thereof is linked to how the move starts in DF or EX variants, so unless you disagree, to me it's identical."* Not disputed: the delay is measured at the activation; which handler causes it is not traced.

## Ruled 2026-09-18 (14z-168) — no gauge is built during Dark Force: the tenants' `+0x1C3` readers are a defect

**Ruling (verbatim):** to the measurement that the shells gain nothing from a whiffed attack inside Dark Force Change while the tenants gain +6 (their placed copy of vs2's meter adder tests vs2's Power field `+0x1C3`), and to the question *"What is the swing-meter you are referring to?"* answered as the start-up gauge of an attack, the maintainer: *"I see, it makes sense that you can't build meter during DF"*.

**What it means.** The shells' behaviour is the rule; the tenants' swing gauge in the mode is a defect, filed on GitHub #157 (its Dark Force tail, the same placed `x028122` copy). The other placed readers of vs2's Power fields (44 on merged-m18, `tests/test_df_field_readers.sh` — *corrected 14z-168 before this entry was committed: 44 placed instructions, of which 26 are reads, all of `+0x1C3`, and 18 writes*) are candidates of the same class, each to be measured before any is changed. Frozen AS MEASURED: `tests/audit_df_meter.sh`.

## Ruled 2026-09-18 (14z-168) — the tenants' vs2 EX route into Dark Force is DISABLED on our build

**The question as put:** *"The EX route on our build. Keep it, or disable the EX input so P+K is the only way in? My recommendation is to disable it. As it stands it's a second, longer Dark Force for the same one stock, and you described the move as mapped onto DF 'and not being a separate EX move'. Disabling it is a gameplay change, so it's yours to decide."* **Ruling (verbatim):** *"agreed"* (with the next sentence: *"you can also find the community vanilla dark force values in the community docs"*).

**What it means.** On merged-m18 the tenants' vs2 EX inputs (Donovan 421+KK, Phobos 263+PP, Pyron 2623+PP, measured) still run the placed copy of vs2's Change entry `0x02622A`: one stock, period 5, 478/496/478 frames of `+0x111`, the Dark Force flag and background (`tests/audit_df_modes.sh`, frozen AS MEASURED). The fix is scheduled by #136's ruled order (analysis first) and tracked as its own ticket; it re-freezes the `ex ours` rows deliberately.

## Ruled 2026-09-18 (14z-168) — the tenants' Dark Force: vsav's Change with their own vs2 values and personal move; the DURATION stays vsavj's

**The design, in the maintainer's words (verbatim):** *"VS2's dark force power costs 2 meters instead of 1, has no invincibility at startup, is a global buff, has no specific moves while VS dark force (sometimes called dark force change) is a character altering ability with startup invincibility. The only common trait in Dark Force Power and Dark Force Change is the background change and timer but we don't really care about them because in Vampire Saved we leverage the VS dark force change as-is. This leads to the two things we care about : 1) the startup invicibility, which you found in VS2 for the 3 tenants, although it is unreacheable in VS2 since Dark Force Power overrules it for every character (but please double check this!) and 2) the "character-altering" move during dark force change, and they do exist in VS2 but as EX moves. [...] What we did in Vampire Saved is threefold: have the new tenants use the VS Dark Force Change like their shell would (same common DF rules) but use the invincibility values recovered from VS2 instead of using the shell characters value AND have their character altering move activated at the start of DF for the duration of DF, like all the other vanilla characters... except that you had to map the move from VS2 to being activated during DF and not being a separate EX move."* — and: *"at least in principle you implemented it right as Dark Force works as intended for all 3 tenants. That doesn't mean the details and specific values might not be incorrect. But the mechanism is working as expected."* — and: *"we need to check if DF in Vampire Savior has the same timer duration for all characters. If so it's a global setting and it takes precedence as vanilla VS trumps VS2."* — and, on Phobos's hover in DF: *"YES! (and again, the move exists in VS2 but as an EX move, not as DF)"*.

**The double checks, measured (`tests/audit_df_modes.sh`):** vs2's P+K never arms `+0x147` on any of the 15 characters its wheel reaches — but the tenants' vs2 EX moves DO arm it, with the same values (the "unreachable" reading holds for P+K only; `engine_internals.md` corrected in place). vsav's Dark Force duration is NOT global: 112 timer units x a per-character period (3 or 4 ticks, from a 32-row table; 4 for the tenants' rows) plus each character's own form — 269 to 540 frames of `$FF802E` at level 6.

**The question as put:** *"Mode duration. Keep the ruled vsavj period 4 (360 frames), or take vs2's period 5 for the tenants (about 450)? My recommendation is to keep the ruling: it's Vampire Savior's per-character rule, and 'vanilla wins ties'."* **Ruling (verbatim):** *"agreed"*.

**What it means.** The 2026-08-21 ruling ("keep vsavj DF durations") stands, reaffirmed with the measurement: the tenants keep 360/377/360 (`tests/audit_df_framework.sh`). A newcomer's Dark Force is compared against its vs2 EX move, never against vs2's P+K (`docs/game/gotchas.md`, the 14z-168 entry).

## Ruled 2026-09-18 (14z-168) — #136: ALL the analysis first, then the fixes, then relentless regression testing

**Ruling (verbatim), at the opener:** *"let's start with #136. While I usually prefer to fix first, here we have many divergences which may or may not share sources so let's finish all the analysis first. Then we'll fix and then relentlessly test for regressions, so all the rigs we create to test the build against vsavj or VS2 will be valuable at least at freeze/release time."*

**What it means.** No #136 fix lands before every family is attributed; every instrument built for the analysis becomes a gate that runs at freeze and release (the eight 14z-168 gates, registered in `tests/ci_emulator.tsv` / `tests/ci_static.txt`). The fixes #157, #159 and the new tickets wait for the analysis to be complete.

## Ruled 2026-09-18 (14z-167b) — the close checklist lives in STATE.md's header

**Ruling (verbatim):** to the recommendation "It needs a ruling on where the checklist lives. I recommend STATE's header, beside the existing close rules", the maintainer: *"I agree"*.

**What it means.** The six steps sit in STATE.md's header as the bullet "THE CLOSE CHECKLIST", beside the rollover rule and the push rule; the standing line points to it. The checklist is ruled in `DECISIONS_HISTORY.md` "Ruled 2026-09-18 (14z-167b) — the adapted close checklist".

**The entry as drafted (moved verbatim from STATE.md "Decisions pending"):**

### 14z-167b — WHERE THE CLOSE CHECKLIST LIVES (the checklist itself is ruled: DECISIONS_HISTORY.md "Ruled 2026-09-18 (14z-167b)")

The six steps are ruled and applied from the next close. Open: which document carries them. (a) STATE.md's header, beside the rollover and push rules that already carry the close ritual; (b) the `vampire-saved-port` skill's close section; (c) CLAUDE.md [VSP-17], if it should be law. **Recommendation: (a)** — the close ritual already lives there, every session reads it first, and it is not law, so it can still be adjusted as items 2 and 5 are measured.

## Ruled 2026-09-18 (14z-167b) — the adapted close checklist: items 1, 3, 4 and 6 adopted, item 2 kept with two changes, item 5 on trial and measured

**Rulings (verbatim), in order:** *"I agree with 1,3,4 for next session. I really like 2, 5 and 6 as well and though they might be costly, I think it's worth trying it out."* — on the trial: *"Item 6 is good, I really like it, let's keep it. Item 5 I  think has potential, we should measure in the coming sessions how much it brings in value or not"* — and on item 2, after the assessment that it is a net positive only beside items 1 and 6 and a liability when its clean result is read as completeness: *"then let's implement them and keep item 2"*.

**What it means.** At every close: (1) the findings table; (2) `tools/close_findings.py <session>` with the two changes IMPLEMENTED 14z-167b — it prints the GAPS only (never a count of homed addresses) and a REVIEW list of the session's addresses homed only by text older than the session, each answered, and its clean result is never cited as evidence of completeness; (3) pointers on every earlier row the sitting resolves; (4) the promise grep; (5) cited scripts promoted, ON TRIAL — each close records how many scratch scripts had figures quoted by a document or STATE row, and how many were promoted (14z-167 baseline: 3, 2 promoted — the legacy census, the entrance measurement; the cnt-family trace copy not yet), and whether a promoted one later caught something; (6) the documentation packet through the rule-checker. Where the checklist lives is NOT yet ruled; it stays under "Decisions pending".

**The entry as drafted (moved verbatim from STATE.md "Decisions pending"):**

### 14z-167b — THE ADAPTED CLOSE CHECKLIST (drafted at the maintainer's request, trialled on 14z-167's own record)

**Context.** After the 14z-167 close the maintainer asked: *"has all the ritual been done? asking as 1) we might need to adapt it a bit 2) we have a tendency for staleness in documents and/or not documenting all finding"*. The audit found stale rows, a promise not kept, findings with no home and cited scripts outside the tree (STATE 14z-167b (1)), and proposed six additions. The maintainer: *"I agree with 1,3,4 for next session. I really like 2, 5 and 6 as well and though they might be costly, I think it's worth trying it out."* — and *"do it"* to fixing the gaps and drafting this.

**The draft — six steps added to the close, after the STATE close entry and before the tier:**
1. **FINDINGS TABLE.** Every finding of the sitting's STATE group, one line each: its live home (document and heading) and the test that reproduces it. An empty cell is a gap to fill or a stated exception. *(agreed for next session)*
2. **MISSING-HOME CHECK.** `python3 tools/close_findings.py <session>`: every address the group names must appear in a live document (a fighter-block address counts when its `+0xNN` offset is in the atlas). TRIAL 14z-167b: under a second; found 3 unhomed addresses in 14z-167 (the facing seed and the rule-5 write), 1 in 14z-166 (vsavj's meter adder) and 1 false positive in 14z-165 (P2's node pointer, fixed by the offset rule); all homed.
3. **CLOSE THE LOOP.** Every earlier row the sitting resolved (unchecked, not concluded, open) gets a pointer in place, in the same commit. *(agreed)*
4. **PROMISE GREP.** The sitting's STATE rows and ledger resolutions searched for commitments ("from here on", "will", "is stated so", "next session"); each is fulfilled or becomes an open item. *(agreed)*
5. **CITED SCRIPTS PROMOTED.** A script a live document cites for a figure moves into `tools/` or `tests/`, or the citation says it is scratch. TRIAL: the legacy census became `tools/audit_facing_rules.py`, frozen by `tests/audit_facing_rule.sh`; the entrance measurement became `tests/audit_rig_opening.sh`. Captures and traces stay as `build/` evidence, cited as such.
6. **DOCUMENTATION PACKET.** The rule-checker reads the sitting's STATE group and the documents it names, against the claim that every finding has a home (each listed), before the close commit. TRIAL: run `2026-09-18-44` — plant caught; **VIOLATED Q1 Q4, every finding true**: two findings of 14z-167 still had no home (P2's x not being a compared field; the run-id collision), a home was mis-cited, gate headers had to count as live documents, and item 2's prototype proves an ADDRESS present but not the FINDING (an address older text already names homes any new finding about it, `$FF8081`) and had no control. Resolved by work: both homed, a gotcha added, the prototype now reads gate headers and carries `--selftest`. Cost: two fresh agents, the real reader 2 min 43 s. **What the trial shows: 6 finds what 2 cannot, so 2 is necessary, not sufficient, and 1 (the table) stays the sufficient check.**

**Ruling needed: where the checklist lives.** (a) STATE.md's header, beside the rollover and push rules that already carry the close ritual; (b) the `vampire-saved-port` skill's close section; (c) CLAUDE.md [VSP-17], if it should be law. **Recommendation:** adopt 1, 3 and 4 now; adopt 2 as a close step (cheap, necessary, not sufficient — its blind spot is stated in the tool), and make it a `ci_static` gate on the newest group once three closes show no false positive; adopt 5 as a rule; adopt 6 at every close with its verdict resolved like any run. Home: (a).

## Ruled 2026-09-17 (14z-164b) — the in-DF batteries need a RIG change (the words recovered 14z-168)

- **Put to the maintainer at the 14z-164 close (2026-09-17T18:22Z):** *"Also open from today: the
  in-DF batteries outrun the 360-frame Dark Force, so in-DF coverage is 5LP and 5MP only; that needs
  a rig change, not a comparator change."* **The maintainer:** *"agreed and this should be in
  next_session.md"*.
- **Recorded late.** The 14z-164 close recorded only that the item went into NEXT_SESSION "with the
  maintainer's agreement", without the words. Rule-checker run `2026-09-18-47` (Q5) found a gate
  citing the agreement with no quote. The words above are recovered verbatim from that sitting's
  session transcript, 14z-168.
- **What it covers:** that the in-DF coverage is fixed in the RIG. It does not cover the rig's
  form. The per-group re-activation that `tests/audit_df_moves.sh` uses was designed 14z-168 and is
  not ruled.

## Ruled 2026-09-17 (14z-164b) — the parity rigs' P2 is DEMITRI, Bishamon the fallback

- **P2 = DEMITRI, BISHAMON IF DEMITRI CANNOT ANSWER (maintainer, 2026-09-17, after the close):**
  *"And I agree with Demitri for P2 with Bishamon as fallback if we end up in a case that Demitri
  cannot answer"* — on the rationale given at the close from `tests/expected/same_data_p2.tsv`
  (chains differing between vsavj and vs2, shared sequences, invalid-on-one-side classed apart):
  Demitri table a 0 / b 3 / c 0, Bishamon 2 / 2 / 0, Bulleta 3 / 1 / 0, Lei-Lei 4 / 1 / 0, Victor
  0 / 7 / 19 (his hitstun head hurtbox retuned on vs2 — the confound five of #136's 13
  divergences begin in). Demitri's three reaction chains are `b:0x10` (the engine-wide held-pose
  push box every legacy character carries) and `b:0x71`/`b:0x74` (one attack record each), so a
  rig that puts him on P2 asserts he never enters 0x71/0x74; his P2 cursor path is `R` on both
  wheels. A second tenant was the other option and is not taken: its data is vs2's on both legs
  by construction, but its own port would be under test in the same rig. The switch is a session
  of its own: every naming rig's prologue changes (`tools/name_moves.py`), and
  `test_move_naming`, `test_projectile_census` and `audit_move_parity` re-freeze.

---

## Ruled 2026-09-17 (14z-164b) — #152 CLOSED: the rule-checker's real runs are accepted

- **#152 CLOSES ON THE 14z-164 REAL RUNS (maintainer, 2026-09-17, after the close):** *"also I
  believe we have real runs proving #152 is indeed now addressed. If you agree we can close the
  ticket"* — agreed. The 14z-163 ruling held #152 open "until a real run under the bounded
  questions is accepted"; runs `2026-09-17-22` to `-28` (two recommendation packets, five
  expectation packets, all on the current checklist hash) are those runs: plants 7/7 caught,
  every VIOLATED resolved question by question, and the findings were true each time — the
  census's own comparator turning a rig pin into a DIFF (24) and comparing the X pin as an
  absolute inside the previous window (25), a silent projectile fallback and collapsed links (26),
  a chain counted as content when invalid on one side (27), the working agent's figures (28), and
  a defect in the checker's own staging (#156). The checker stays on the default model and its
  questions stay bounded (the 14z-163 rulings stand); what stops constraining work is only the
  "closes after a first real run" clause, met.

---

## Ruled 2026-09-17 (14z-164) — #136's scope census: per-event verdicts, a same-data P2, the 13 rows re-labelled

- **THE THREE PROPOSITIONS OF THE 14z-164 SCOPE CENSUS ARE AGREED (maintainer, 2026-09-17):**
  *"I agree with the 3 propositions"* — put to the maintainer after rule-checker runs
  `2026-09-17-22` and `-23` (both VIOLATED, each answered by work; the verdicts verbatim in
  `tests/rulecheck/runs/`), with the census under `build/move_parity_census_14z164/` and the
  re-labelled table posted on GitHub #136 the same day:
  1. **Per-event verdicts instead of per-part** in `tests/audit_move_parity.sh`, with the
     stock, the meter fraction (`RAM:$FF850A`) and Victor's HP (`RAM:$FF8850`) as compared
     fields, and each event labelled "in DF" asserted IN Dark Force on both legs (21 of the 24
     "in DF" events of Donovan's part 6 ran with the flag 0 on both legs: DF lasts 360 frames,
     the battery spans 3,850).
  2. **A P2 whose data is the same on both games** — a second tenant, or a legacy character
     whose per-character bank is byte-identical between vsavj and vs2, found statically by the
     three-sibling diff. Reason: P2 is Victor, VS's on our leg and VS2's on the native one; five
     of the 13 first divergences begin with Victor's own state, and 15 windows the tenant reads
     identical in carry a differing Victor.
  3. **The 13 rows are re-labelled by their fields before any family is root-caused** (the
     table on #136, 2026-09-17): 5 Victor-first (donovan_3, donovan_4, huitzil_2, huitzil_9,
     pyron_4), 3 DF activations (donovan_6, donovan_7, huitzil_4: the ruled cost plus the two DF
     systems), 2 Phobos-HP-by-1 (huitzil_6, huitzil_8: the defense-curve cell victim 0x10 /
     attacker 0x03 reads 0xFE on vsavj, 0x00 on vs2), donovan_2 (tenant first, at contact),
     huitzil_5 (tenant first, Victor attacking), pyron_3 (a stock crossing). The two HP-by-1
     rows and the three DF rows are not guard-cancel or move defects on the fields.
  On a third checker run of the recommendation: *"fine by me if there's value in running it a
  third time"* — not run; the per-event expectation freeze gets its own `expectation` run instead.

---

## Ruled 2026-09-17 (14z-163) — the rule-checker's questions Q3 and Q4: bounded AND resolved in writing (option C)

**The entry, moved verbatim from STATE "Decisions pending":**

- **14z-163 — THE RULE-CHECKER'S QUESTIONS Q3 AND Q4: BOUNDED, OR KEPT AS WRITTEN WITH A WRITTEN RESOLUTION STEP? (GitHub #152; the design is the maintainer's).** Measured: plants caught 8/8 (every positive fixture, every reader, the false-statement plant 3/3); the honest negative packet OK in 2 of 5 readings, and every VIOLATED reading true of the artifacts — two of them real defects (the `$FF8410` pin the claim denied; #154), the rest uncovered failure modes the claim itself names (Q4) or shared mechanisms no artifact shows (Q3). As worded, Q3 ("a premise such that a defect in it would make them AGREE") and Q4 ("a control that would fire on the specific way THIS claim could be wrong") have no bound a real gate can meet, so under [VSP-184] nearly every honest real run ends VIOLATED and stops. Options: **(A)** keep the five questions as written; a VIOLATED is resolved only by answering each finding in writing through `rulecheck resolve` — the checker never says OK on a real gate and becomes a forcing function for explicit written acceptance of every uncovered mode before the action. **(B)** bound them: Q3 counts only a shared thing the artifacts SHOW can write the compared state; Q4 reads OK when the claim itself names the uncovered mode as untested; every fixture recalibrated. **(C)** both — B's wording and A's written resolution for what remains. Recommendation: **C**: the value the checker proved today is catching false statements and unnamed premises (every one verified), which B keeps, while A keeps the stop honest for what a bounded question still finds. Not the session's call: the questions are the maintainer's proposal and a change moves the instrument.

**Ruling (verbatim):** *"my decision is 'both'"* — option C: Q3 counts only a
shared thing the artifacts SHOW can write or select the compared state; Q4
reads OK when the claim itself names the uncovered failure mode as untested;
and what a bounded question still finds stops the action until
`tools/rulecheck.py resolve` answers EACH violated question in writing (the
tool refuses a resolution that does not). Every fixture is recalibrated on the
new wording, because a changed checklist moves the instrument
(`docs/project/rule_checker.md`).

## Ruled 2026-09-17 (14z-163) — #152 closes after a first REAL run of the rule-checker; the checker stays on the default model

**Context.** The rule-checker was built and calibrated in 14z-163 (seven
calibration runs: both positive fixtures caught, the negative fixture OK twice
on its corrected third version), and the report to the maintainer asked
whether #152 closes on the calibration and which model the checker should run
on.

**Ruling (verbatim):** *"We close after we measure so we need a first real
run. I am fine with default model. We can always recalibrate later if we need,
right?"* — the answer is yes: `tools/rulecheck.py prepare --calibrate` re-runs
any fixture at any time, the ledger keeps every result, and the spec
(`docs/project/rule_checker.md`) repeats calibration whenever the checklist
or the model changes.

**What it means.** #152 stays open until a real run (a `build`, `freeze`,
`expectation` or `recommendation` packet, with its blind plant) is recorded
in `tests/rulecheck/ledger.tsv`; the checker's model is the default until a
later ruling, and a change of model is a recalibration.

## Ruled 2026-09-17 (14z-162) — #148 second cut, #148 closed, lever B its own ticket

**Rulings (verbatim), on the two questions the lever-A measurement left open.** The
three ≤2 s release-set gates (`test_release_asset_shape`, `test_release_os_metadata`,
`test_mister_page`) back to session — *"yes, especially strong value for the
docs-consistency, which besides the speed has likely always value."* The five 35-39 s
gates (`test_suite_dispatch_selftest`, `test_reconcile_matcher`,
`test_frozen_rompath_guard`, `test_accent_census`, `test_emulator_runner`), after the
impact analysis (each locks a property of a small, nameable file set; none a doc or a
rule application; a freeze re-runs all of them on the build commit) — *"second cut to
freeze with those triggers."* On lever B — *"Lever B its own ticket, my gut feeling is
that the gain for session is marginal but the gain for freeze or release is massive
not so much for speed but for integrity and traceability, as demonstrated in bbh and
BBX."* And, on my recommendation to close the session before working #148: *"we abide
by the discipline and we adjust while abiding with the discipline: which is exactly
what #148 is about"* — recorded as the rule it is.

**Result.** `tests/ci_cadence.tsv` lists 12 freeze and 5 release gates; #148 closed
done with lever B filed as its own ticket; the session close runs the session cadence
with every control executed.

## Ruled 2026-09-17 (14z-162) — #148 lever A: the static tier is cadence-tiered (session / freeze / release), the first-cut classification adopted

**Context.** The 14z-162 measurement of the session tier (`run_all_static.sh --strict
--exec-controls none`): 20.4 min of gate time over 156 gates, 121 of them ≤2 s; the
top seven (`test_m3a_reproducible` 215 s, `test_bbh_fidelity` 125 s,
`test_merged_inputs` 78 s, `test_phasec_spaces` 68 s, `test_census_regions` 64 s,
`test_pcrel_escapes` 55 s, `test_hui_winscreen` 50 s) ~11 min, every one re-proving
a build/content invariant that only moves at a freeze. The maintainer's framing
(verbatim, the same day): *"whatever happens when we release we test absolutely
everything, no matter how long it takes. When we freeze by default we test heavily
but we don't go over all the tests including the longest MiSTer tests […] When it
comes to the tests we do in our average session, it's a bit different: some of them
are absolutely mandatory to guarantee quality, some might be just out of scope. So
we need to check."* Two levers proposed on #148: (A) a cadence per static gate,
mirroring the emulator tier's `scope`/`cadence`; (B) running the tier on a scratch
clone as bbh/BBX do.

**Ruling (verbatim).** On the classification — *"the seven expensive gates to freeze
cadence with path triggers, the release and MiSTer gates to release, the fast gates
stay session"* — **"agreed"**. On which lever first — **"lever A"**.

**What it means.** `tests/ci_cadence.tsv` is the registry (unlisted = session);
`run_all_static.sh --cadence session|freeze|release` (default session) defers a
listed gate above the requested cadence BY NAME — never a SKIP, never silent — unless
one of its trigger paths or its own script changed since origin/main or in the
working tree; a freeze runs `--cadence freeze` and a release `--cadence release`,
each on the commit it builds from, which is the safety net. Ground truth:
`tests/test_static_runner.sh` §14-15 (control `trigger-blind`). Lever B is not
built. The three ≤2 s gates among the release set (`test_release_asset_shape`,
`test_release_os_metadata`, `test_mister_page` — the last a docs-consistency
check) are listed as ruled; deferring them saves nothing, and pulling any back to
session is the maintainer's call, raised on #148.

## Ruled 2026-09-17 (14z-162) — #151 (the forced-pick apparatus validation) may be closed, conditionally; #136 stays open and now documents the 13 divergences

**Context.** On the 14z-162 measurement report of #151's steps 1-3 (the forced-pick
native leg reproduces a real cursor pick except for the flavor latch `+0x3C2`,
which no gate in the tree reads with a value a real pick would not write), the
maintainer ruled #151 closable.

**Ruling (verbatim):** *"Based on this information, I rule that #151 can be closed
IF AND ONLY IF, the 13 diverges have been documentated or linked to at least in
#136, AND that #136 is still open."*

**Rationale (verbatim):** *"the rationale is thusly: per your own words 'The 13 are
real defects, which are #136's work.' but if #136 is not aligned with #151 this is
moot and if #136 is closed this is even worse as this means these defects will not
be corrected but also likely assumed corrected."*

**Both conditions met before #151 was closed:** #136 is OPEN, and the 13 DIVERGES
are documented in it — the re-frozen per-part table (comment 2026-09-16) and a
consolidated list with each move's first divergent event and its family (comment
2026-09-17, from `tests/expected/move_parity.tsv`). Closing #151 validates the
apparatus only; the 13 defects remain #136's open work and are NOT assumed fixed.



## Ruled 2026-09-17 (14z-161b) — the close-time safeguards stand until #148; the order of work is stable state, #148, #152, then everything else

**Context.** The 14z-161 close pushed `main` on the mid-session static-tier form (`--strict --exec-controls none`, ~20 min) instead of the close form with every control executed (~40 min). The maintainer asked "closing ritual done?"; it was not. The close tier was then run in full and came out green (PASS 156 / SKIP 0 / FAIL 0, executed 176 honoured 176, wall 2,489 s).

**Ruling 1 (verbatim):** *"To be clear, this is very time consuming and why #148 exists but until we tackle #148 we should not compromise on what we decided in terms of safeguards."* — the 2026-09-14 ruling (14z-154) stands exactly as written: the close runs every control and only then pushes; the cost is #148's business, not a reason to shorten the close.

**Ruling 2 (verbatim):** *"as soon as we are in a state we know to be stable and reliable we should tackle #148, there is much time to gain there"*, refined the same hour to *"the ideal order should be stable state then #148 then #152 then everything else."* — NEXT_SESSION's START HERE carries that order; the #136 divergence families follow #152.

**Recorded on #148** as a comment the same day; the standing lines are in STATE "Standing rulings".
## Ruled 2026-09-16 (14z-160) — entered at ruling time, under the amended lifecycle

- **#136 GOES OVER AGAIN IN FULL, AND STAYS ON THE LIST UNTIL IT HAS (maintainer, 2026-09-16).**
  At the opener, on the proposed order #151 -> #147 -> #149 -> #152 -> #150/#148: *"I agree with
  the order but I also must insist on going over #136 again in the todo list at some point because
  too many things especially with Pyron and Phobos could be wrong in it."* So #151's faithfulness
  control is the FIRST step of the re-examination, not the whole of it: every part of #136 — the
  naming rigs, the pinning protocol, the 27 frozen verdicts of `tests/expected/move_parity.tsv`
  with their twelve divergences and fifteen unknowns, and the Pyron and Phobos legs above all —
  is gone over again before any of it is built on, and the item leaves the open list only when
  that pass is done, never on the control alone.

- **#149 AND #147 CLOSED AS INVALID (maintainer, 2026-09-16, 14z-160).** On the measurements
  of 14z-160 (2)-(4) — the seq-4 startup state is flavor-1-only and a real-cursor native Phobos
  plays it on 0 frames; a real Phobos confirm writes `+0x3C2 = 00` and ours ships 00, movement
  and jump IDENTICAL to native — asked to close both as invalid: *"close #149 and #147 as
  invalid => yes."* The 14z-159 "#149 waits for its measurements" line is retired with it.

- **THE REMAINING PHOBOS DIVERGENCES, THE MAINTAINER'S TESTIMONY (2026-09-16, 14z-160):**
  on the re-frozen #136 table (14 IDENTICAL / 13 DIVERGES): *"the divergences on Phobos are
  aligned with moves that we had trouble with in the past and either had to be imported in
  multiple passes or tweaked, so it's good news in the sense that if something diverges, I
  would expect that to diverge."* Recorded as testimony, not a verdict: the rows stay
  findings, each family (Plasma Trap; the Reflect Wall guard-cancels; Ray of Doom) its own
  root-cause and ticket under the full re-examination of #136.

## Ruled 2026-09-16 (14z-159) — entered at ruling time, under the amended lifecycle

- **THE M19 FREEZE IS WITHDRAWN IN FULL (maintainer, 2026-09-16).** After the
  freeze was assembled the maintainer played it and reported that Phobos floats on a
  single jump press — the VH2 mechanic, not VS2's. GitHub #147's diagnosis was a rig
  artifact (the flavor latch is written at select confirm, before the forced-pick poke
  replaces the character id), so its fix was a regression. Ruled: *"withdraw the freeze
  entirely, #147 needs reopening and honestly #136 needs to be looked at again,
  thoroughly."* The tree is back at merged-m18: no M19, no registry rows, no expectation
  sets, no re-point sweep, `flavor_default` restored to 0x00. #151 carries the
  re-examination. THE NO-RELEASE RULING BELOW IS THEREFORE MOOT as written — it was
  scoped to a freeze that no longer exists — but its REASON stands for the next freeze:
  the release mechanism has open tickets (#144, #145, #146) and more fixes are expected.

- **~~NO RELEASE AT THE M19 FREEZE (maintainer, 2026-09-16).~~ (moot — see above)** Asked whether the
  Phobos-flavor freeze should also ship a release, the maintainer: *"I would argue
  no release right now since we have potential issues with how we release anyway
  and possibly more fixes to come soon."* So the 14z-159 freeze packages nothing:
  `tools/package_release_platforms.py` was not run, there is no
  `release/merged-m19/`, and no assets were uploaded.
  **This is a recorded departure from [VSP-178]**, which says the freeze commit
  carries the release directory and that a release run finding it untracked has
  found an unfinished freeze. It is a decision, not an oversight; the next release
  run must package merged-m19 (or its successor) rather than read the absence as a
  defect. The open release tickets the ruling refers to are #144 (macOS blocks the
  prebuilt binaries), #145 (Windows prebuilt binaries fail to load the game) and
  #146 (the player READMEs are not detailed enough).

- **#149 WAITS FOR ITS MEASUREMENTS (maintainer, 2026-09-16).** On whether to scope
  a fix for Phobos's skipped seq-4 startup state: *"For #149 I think we need all the
  measurements first."* So no thunk design and no scoping until the ticket's own open
  measurement runs — route Phobos's flow at the `vs2 0x026252` / `vsavj 0x02706e`
  call site to the ported copy and confirm the seq 4 sub 4 state appears and the
  parity verdicts flip. Until then the twin-pair difference stays a CANDIDATE cause
  ([VSP-116]), not the cause.

## Ruled 2026-09-16 (14z-158b) — entered at ruling time, under the amended lifecycle

- **#143 FILED, TO BE SOLVED CAUTIOUSLY (maintainer, 2026-09-16).** Asked whether
  `tests/lua/walker_sp.lua`'s supervisor-stack read should become a ticket, the maintainer: *"yes
  but we probably want to be cautious when solving it"*. Filed as #143, measure-first: which stack
  is live at the walker sites, before any change to an instrument two audits consume.
- **README.md's engine-clock line (maintainer, 2026-09-16):** *"I shall commit and let you retract
  or correct the part on 'tick on Vampire Savior's engine clock'"* — the README stays the
  maintainer's file; that one retracted claim (#135) is corrected after their commit.
- **THE MEASUREMENT RULE, RE-WORDED (maintainer, 2026-09-16), amending 2026-09-15's "a measurable
  question is measured":** *"'Measure don't ask' is strange wording because asking is not bad per
  se. Assuming is wrong. Don't assume, measure first, ask if necessary. And yes, this applies first
  and foremost to code measurements but if you can hallucinate the region of a name..."* Said after
  the 14z-158 close report asserted, unmeasured, that "Huitzil is the Japanese name" (vsav2 shows
  Phobos). The failure is ASSUMING; asking stays right when a measurement cannot settle the question.

## Ruled 2026-09-15 (14z-158) — entered at ruling time, under the amended lifecycle

- **THE IMMORTAL GATE AT MATCHED PLAY MODES; #114's "LP ONE HIT SHORT" RETRACTED AS A MODE
  ARTIFACT (maintainer, 2026-09-15).** #135 measured that vsav2 hard-codes P1's play-mode
  default to TURBO at character confirm (`PRG:0x01F98C`, `move.b #$1,$7(a6)`) where vsavj
  defaults to NORMAL (`PRG:0x020D38`, `clr.b $7(a6)`), and that the play mode sets the speed
  level `RAM:$FF8116`, which alone decides the extra logic passes. So every native-vs2 leg that
  never touched the menu ran TURBO (level 8) against vsavj's or our build's NORMAL (level 6).
  At matched levels LP at the mash ceiling is EQUAL (4h/8d at level 6, 5h/9d at level 8), the
  vanilla Victor freeze drains in the same number of frames on both games (§4's "+1" is gone),
  and MP with no mash at level 6 is 5 hits on ours against 4 on native. Asked "How should
  test_don_immortal_native assert from now on?", the maintainer chose *"Matched modes, both
  (Recommended)"*, whose text was: *"Force the same speed level on both legs and assert ours ==
  native at NORMAL (level 6) and TURBO (level 8). Retract LP's 'one hit short' and §4's '+1
  frame' as mode artifacts. The MP-at-NORMAL extra hit is then the one open difference, and the
  gate stays red on it until it's resolved."* The 2026-09-02 ruling that the vanilla vsav engine
  takes precedence is not re-opened; its LP example is what the measurement retracts.
- **THE MP EXTRA HIT IS A TICKET, TO BE ROOT-CAUSED (maintainer, 2026-09-15).** Asked what should
  happen to it, the maintainer chose *"Ticket + root-cause (Recommended)"*: *"File it as a bug and
  find why our build runs one more loop iteration without mashing at level 6."* Filed as #142.
- **THE IMMORTAL GATE ALSO PINS THE RNG AND ASSERTS HIT FRAMES (maintainer, 2026-09-15).** The
  #142 root cause, measured the same sitting: the object loop (vsavj `PRG:0x02207E`, vs2
  `0x020A2E`, the same code) picks P1-first or P2-first on every pass from bit 0 of the engine RNG
  (`RAM:$FF80D4-D5`, vsavj `PRG:0x014E8A`, vs2 `0x01357E`, the same routine), and the two games'
  RNG states differ throughout a match even on vanilla content — so on the pass after MP's fourth
  hit the two legs updated the fighters in opposite orders, ours' attacker stayed frozen one pass
  longer, and a fifth hit landed. With the level AND the RNG pinned on both legs, all 16 legs
  (four strengths, no mash and at the ceiling, levels 6 and 8) are identical in hit count, damage
  and every hit frame. Asked "How should test_don_immortal_native handle the RNG?", the maintainer
  chose *"Pin both, assert frames (Recommended)"*, whose text was: *"Poke the level and
  $FF80D4-D5 = 0000 every frame 2400-2800 on both legs; assert hit count, damage AND hit frames
  equal (measured identical 16/16). Keep a must-fire control that leaves the RNG unpinned and must
  diverge (MP at level 6), so the gate proves it sees the RNG. The gate goes green."* This
  supersedes the previous entry's "the gate stays red on it until it's resolved".
- **#142 CLOSED AS INVALID (maintainer, 2026-09-15).** Asked what becomes of #142, the maintainer
  chose *"Close as invalid (Recommended)"*: *"The premise (a port difference) is refuted by
  measurement. Close it with a comment naming the cause (RNG-picked player order), and point its
  local answers at the rewritten gate and the engine doc."*

## Ruled 2026-09-15 (14z-157) — entered at ruling time, under the amended lifecycle

- **A QUESTION A MEASUREMENT CAN SETTLE IS MEASURED (maintainer, 2026-09-15).** Told that
  RAM:$FF8130's writer count "can be settled by measurement rather than memory": *"then it
  must! We measure, we don't believe or assume and we don't compromise on the discipline"*.
  Measured the same session: `tests/audit_ff8130_writers.sh`.
- **THE STALE-CLAIMS PASS, THREE RULINGS (maintainer, 2026-09-15):** `tests/test_voice_row_range.sh`
  keeps its filename — *"keep it, we don't want to break things needlessly"*; #77's
  `contested` label removed — *"I agree with removing it"*; #112's 14z-154 closing note
  corrected on GitHub — *"Yes, correct please"*.
- **THE #75-#114 RESIDUALS, THIN RECORDS, CALLS AND LABELS (maintainer, 2026-09-15):** *"I
  agree with all recommendations"*, said of each group of the 14z-157 decision sheet:
  - #78: the full FBNeo legacy track becomes its own ticket, #141 (evolution, parked);
    CLAUDE.md [VSP-24]'s "revisit at MiSTer" awaits the maintainer's wording.
  - #80: dropping the `tools/setup_mame.sh` mirror is DECLINED — the space that made it
    necessary is gone, and the mirror now keeps the submodule pristine, separates the
    reference and WIDE roots, and gives the release build its own.
  - #93: option C (a tenant-only authored copy if the chirp tail is ever heard) and the
    standing check on remapped records' played endpoint bytes are both DECLINED.
  - #100: the "after MiSTer" residual is FOLDED INTO #125, cross-linked to #124.
  - #103: naming the move that pinned `hp := 1` is DECLINED — the escape is fixed.
  - #109: the clone-beam positive-contact damage leg is FOLDED INTO #136 (its rigs
    `tests/replays/df/103_clone_beam_contact.rpl` and `df/104_clone_beam_contact_native.rpl`).
  - #111: the merged expectations for replays 107-110 are DECLINED as superseded by the
    14z-133b B2 design, which the maintainer confirms: the merged set carries no
    tenant-content `.sha1` expectations (`tests/expected/merged-m18/README.md`).
  - #96: the pipeline-image registry rows (`donovan-mN-stock` / `-stage4`), proposed at
    14z-97 and registered at every freeze since, are RATIFIED (copied below).
  - #90: no new ruling; its 2026-08-16 ruling is copied below.
  - #78 stays `evolution`, #108 `invalid`, #112 `declined`; #101 and #105 become
    `cosmetic`; the kind labels on #75-#114 applied from the index; the index header
    gains definitions of the three kinds; GitHub's close reason stays unmapped, the
    index being the source of truth for status.
- **CLAUDE.md [VSP-24] RESTATED (maintainer, 2026-09-15):** the proposed wording — the full
  FBNeo legacy track's revisit point, MiSTer, has passed, and the track is parked as #141,
  to be reopened on a measured FBNeo-vs-MAME disagreement on legacy content — *"agreed"*.
- **THE LESSONS WITH NO LIVE CARRIER (maintainer, 2026-09-15):** *"Issue 77, 92, 93, 95, 100,
  101, 102, 112 I agree with the proposals"* — written as drafted in the 14z-157 decision
  sheet: #77 and #95 a sentence in their gate's header; #92 a platform gotcha on a MAME
  breakpoint condition that does not parse, plus links to [MFI-6] and the existing
  breakpoint gotcha; #93 the checker's docstring (the channel field, the one-sided
  compare); #100 links to the 14z-157 `ram.md` and `venue_assets.md` carriers; #101 a
  project gotcha, two symptoms are one defect only if the mechanism predicts both; #102 a
  paragraph in `engine_internals.md`, a continue clears the in-use mask; #112 links to the
  bare-long-pointer gotcha and [VSP-46], with a PAID AGAIN paragraph there.
- **THE 14z-85f FLAKY CRASH RESET, BY TESTIMONY (maintainer, 2026-09-15):** *"the Sasquatch
  flaky reset was never reproduced since we fixed the crashed with the VS2 tenants. I'm
  99.9% sure the problem was Donovan, not Sasquatch"*. No recording of it exists (it
  predates CLAUDE.md [VSP-20]), so nothing can be measured; the archive's note that a link
  from it to #92 is "open" is superseded by this testimony, and no ticket is opened.
- **#91's LESSON CARRIER (maintainer, 2026-09-15):** of the three options offered (link CLAUDE.md
  [VSP-20], a new project gotcha, or `none`), *"Link [VSP-20]"* — FIELD REPORTS ARE RECORDINGS
  is the law for the class #91 was an early instance of: a rig crash taken for an
  unreproduced field crash on a shared signature. With this, every item the #75-#114 threads
  left for the maintainer is ruled.

### Copied 2026-09-15 from GitHub #96 (comments 2026-08-19T06:03:07Z, 10:15:38Z and 10:16:03Z), verbatim excerpts

> ## RULED (maintainer, 2026-08-19): option (a) — the battery targets the CURRENT frozen generation. Scheduled for next session.
>
> **The ruled policy:** the battery asserts "the pipeline, built fresh, reproduces the CURRENT freeze." Its specs re-point at each freeze (donovan-m8 is current). Under this policy a red battery means the pipeline cannot reproduce the current freeze — unambiguously rule-6 territory — which also resolves the standing "does a red dev-build gate trigger rule 6?" question: today's red was an artifact of the dated pin, not a build defect.

> The two registry rows register **pipeline images**, not shipping artifacts — that is what the ruled policy needs to dispatch on, but registry rows are normally added at freeze time as a STATE decision, so I am proposing rather than ratifying. Everything is measured and reversible (two rows plus two directories). Say the word if you would rather they were named differently, scoped differently, or kept out of `registry.tsv` in favour of a battery-local table.

> Closing on the ruling as executed (see the comment above). Reopen if the two registry rows for pipeline images should be named or scoped differently — that is the one thing in the change that is proposed rather than ratified.

### Copied 2026-09-15 from GitHub #90 (the issue body and comment 2026-08-16T21:17:21Z), verbatim excerpts

> ## Why this needs a ruling rather than a patch
>
> There are three defensible answers and they differ in what coverage is retained:
>
> - **(a) Move the probe to a stage-6 rung.** Probes what actually ships; loses the "does an intermediate rung boot" signal. Costs one more build per run.
> - **(b) Keep it at stage 4 and assert the *documented* degraded shape** — the 14z-65 wedge ("poke holds, struct never forms, guard clean"). But Pyron does not wedge, he crashes, so this means freezing a CRASH as an expectation. That is a real cost: a genuine stage-4 regression would then be invisible.
> - **(c) Drop the boot probe from the Pyron ladder**, relying on the frozen build's suite for boot coverage.
>
> **Recommendation: (a).** The probe's value is "a forced pick reaches a formed match", which is only meaningful where the port exists. (b) freezes a crash and (c) loses the check entirely. Note (a) makes the Pyron and Donovan ladders structurally identical in this respect, which is correct given both manifests are stage-6-heavy.

> ## Fixed (maintainer ruling: option (a), move the probe to a stage-6 rung)
>
> `tests/test_pyron_ladder.sh` now builds `1 2 3 4 6` and runs the forced-pick boot probe on the **stage-6** rung — the one that carries Pyron's port and corresponds to what ships.

## Ruled 2026-09-14 (14z-155) — entered at ruling time, under the amended lifecycle

- **#136, TENANT MOVE PARITY AGAINST NATIVE VS2, IS FILED AND NOT STARTED (maintainer,
  2026-09-14).** Told that the VS2 tenants' moves other than throws were never compared
  with VS2 on the WIDE build, the maintainer: *"file it but don't start it"*. The ticket
  is `parked` behind #135; the gap is a row of `docs/project/coverage_matrix.md`.
- **THE #63 RESIDUAL IS DONE, AS #137 (maintainer, 2026-09-14).** *"we must check whether
  this hardening has been done or not and if not whether we should do this hardening
  because it is still applicable and desireable or not"*; given the analysis (not done,
  applicable, worth doing): *"yes"*. The record is `tests/test_wide_profile.sh`'s header.
- **KIND LABELS ON THE 74 AUDIT ISSUES (maintainer, 2026-09-14):** *"do it"* — each label
  taken from the row's `kind` in `docs/project/tickets.tsv`.
- **THE THREE AUDIT RESIDUALS (maintainer, 2026-09-14):** *"#1 : trap variant / #55 : open
  the ticket / #50: add the line"* — #139 (the EXIT-trap variant, over staging the pack
  through `rompath.tmp`; `tools/rompath_reject.sh`), #138 opened, and #50's generator
  refactor policy under STATE.md "Standing rulings".
- **THE HARNESS'S F9 WEAKNESS IS A TICKET, NOT A CHANGE (maintainer, 2026-09-14):** *"yes,
  write that small ticket but don't do it"* — BBH-frame-based #1.
- **THE ORANGE P2 SWORD IS THE MEDALLION FIX'S ACCEPTED TRADE (maintainer, 2026-09-14):**
  *"This is the compromise we made when fixing Pyron's medaillon on the wheel. Something
  had to give and it was less jarring to alter the sword color than the medaillon."* The
  trade was already recorded in `docs/project/patch_index.md` ("Pyron medallion / P2
  sword row collision (14z-116)"); it is not a ticket.
- **THE README (maintainer, 2026-09-14):** *"I'm ok with the commit. Let's finish working
  on the other details of the README in the next session"* — the added sections
  committed at the 14z-155 close; the readability proposals carried in
  `docs/NEXT_SESSION.md`.
- **THE 14z-155 CLOSE IS COMMITTED, NOT PUSHED (maintainer, 2026-09-14).** The close tier's one red was a
  timing flake in `test_bbh_fidelity` F1, and the gate passed re-run alone. Offered three closes — fix it
  now and push on a green re-run, push under a recorded exception, or commit without pushing — the
  maintainer chose *"Commit, don't push"*: the bbh fix, a green close tier and the push open the next
  session.

## Ruled 2026-09-14 (14z-154) — entered at ruling time, under the amended lifecycle

- **THE STATIC TIER'S MUST-FIRE CONTROLS RUN AT THE SESSION CLOSE, NOT AT EVERY
  COMMIT (maintainer-ruled 2026-09-14).** The maintainer's words: *"I lean towards
  running the controls only at session close unless we have a demonstrable history of
  control going dead mid-session; the rationale being that if the probability is low,
  at worst we catch it late rather than earlier but we can always either correct or
  even rollback and redo the work. This might sound bad but our sessions are
  context-size bound anyway since we don't exactly parallelise work to extremes... so
  the worst outcome is maybe a couple hours lost to gain more than 15min for each
  intermediate commit basically"*. **THE CONDITION, MEASURED THE SAME HOUR:** of the
  106 strict-tier logs kept under `build/`, the 27 that executed controls (since
  14z-147c) carry not one control verdict other than HONOURED — every executed tally
  reads `lies 0  refused 0  died 0` — and the dead controls in the archives are
  emulator-tier or audit gates. **THE COST IT SAVES, MEASURED:** a quiet strict tier is
  ~37 min wall, ~20 min of gates and ~17 min of executed controls
  (`build/static_14z153_close.log` 36:57, `build/static_14z152_close.log` 37:23; the
  runner times each control but deletes the record at exit, so the controls' share is
  wall minus gates). **WHAT IT CHANGES:** a mid-session commit runs
  `tests/run_all_static.sh --strict --exec-controls none`, plus `CONTROL=<name>
  tests/<gate>.sh` for every declared control of a gate the commit ADDS or CHANGES; the
  session close runs the default, `--exec-controls all`. Unchanged: the emulator tier's
  `--controls` at release runs (ruled 14z-148) and CI's portable run. **REVISIT** if a
  close ever finds a control dead that a mid-session run would have caught.

## Moved 2026-09-14 (14z-154) — the open-list clean-up, verbatim

Moved byte-verbatim from STATE.md's standing sections by the first clean-up under the
amended lifecycle (CLAUDE.md [VSP-17]); a section moved whole has its heading demoted
one level. Every ruling here that still constrains work left ONE line under STATE.md
"Standing rulings".

### From "Decisions pending": the Windows binaries (done 14z-153)

- ~~**PUBLISHING THE windows-x86_64 PREBUILT BINARIES — AWAITING THE MAINTAINER'S WORD
  (14z-152).**~~ **DECIDED AND DONE 2026-09-13 (14z-153, maintainer: "publish the
  Windows binaries").** Rebuilt on the box with the capturing builder at
  `666b14d9`; `test_release_binaries` PASS there on the rebuilt pair, both controls
  fired; the two folders copied to the Mac and every sha256 row re-verified;
  `release/merged-m18` repackaged (5 tracked files, the availability lists only);
  uploaded FROM THE MAC (`gh` is absent on MSYS2, ruled 2026-09-13): 7 assets on
  `freeze/merged-m18`, each downloaded back and identical. The register entry is the
  tool's (`docs/project/build_environments.md`). The original entry follows. Both are built on the maintainer's box and `test_release_binaries`
  PASSES there (at `8b908cd4` and again at `32268250`). Publishing adds
  `merged-m18-{fbneo,mame}-windows-x86_64.zip` to `freeze/merged-m18` and commits
  their `BINARY.txt` records; the upload runs where the files are (MSYS2), and
  whether `gh` is set up there has not been checked. Outward-facing, so not done
  unasked.


### RELEASE-TIME TEST SCOPE (maintainer, 2026-09-02)

**AT RELEASE TIME, ALL TESTS ARE RUN.** Verbatim: *"at release time, ALL tests
should be run. The only exception would be test whose scope is not applicable
to what is released, which honestly would be specific tests used momentarily or
tests on a different romset or platform. So tests that would measure VS2 or
vsavj for instance are out of scope since we release vsavjw BUT tests on native
VS within vsavjw are absolutely relevant."*

The discriminator is **THE SUBJECT OF THE TEST, NOT THE ROMSETS IT TOUCHES**:
- IN SCOPE — anything whose subject is the released artifact, **including its
  LEGACY / native-VS content**. A gate that uses `vsav2` or pristine `vsavj` as
  an ORACLE is in scope: the reference leg is not the subject.
- OUT OF SCOPE — a gate whose SUBJECT is a different romset or platform
  (a pristine-set rule lock, a stock-twin-only gate, another platform's lane),
  or a momentary//specific probe.

**THE ABSOLUTE (maintainer, 2026-09-02):** *"there is no approximation in our
testing discipline both in general and absolutely at release: unless explicitly
approved AT release time, anything red, anything skipped is a hard fail of the
release process."* And the asymmetry that makes the cost sane: *"we may not
need ALL the tests for every small change but how could we not run them when we
release, since we have them!"* — a subset during development, EVERYTHING at
release.

**CONSEQUENCE FOR SELF-SKIPPING GATES:** a gate that prints `SKIP:` and exits 0
because a prerequisite is absent has NOT been run, and in `run_battery_m2.sh`
`bat` counts a bare exit 0 as PASS — the exact class
`tests/test_battery_accounting.sh` exists to bar ([VSP-101], SKIP IS NOT PASS).
Under this policy a release-scope gate must FAIL LOUDLY on a missing
prerequisite rather than self-skip. `test_don_immortal_native.sh` was corrected
to that convention when the policy was ruled (it had two silent `exit 0`s).


### From "STANDING PRINCIPLE": HOW A RED IS ADJUDICATED

**HOW A RED IS ADJUDICATED — the maintainer's explicit statement of the obvious
(2026-09-02):** *"to know if we should fix the gate or what it caught, we must
use data we can trust, and that means measuring or relying on data that is
known to be true for it was vetted by measurements."* **A RED GATE IS A
QUESTION, NOT AN ANSWER.** Before choosing fix-the-gate / fix-what-it-caught /
delete-as-valueless, establish WHICH SIDE'S EXPECTATION RESTS ON MEASUREMENT.
A frozen expectation whose provenance cannot be named is a claim with a number
in it. **The worked example is this session:** `test_don_reactions.sh` was
GREEN on `native == 10`, a constant of playtest-testimony provenance
(STATE 14z-42c) presented as measured — it happened to be correct, which is
luck, not method. **MEASURED 14z-127, as input to the emulator-tier arc: 30 of
45 frozen expectation files declare their provenance in their header; 15 do
not** (`advancing_guard`, `community_crosscheck`, `df_accumulator`,
`escape_triage`, `front_comparator`, `killshread_es`,
`ladder_tenant_vs_palette`, `move_naming_{donovan,huitzil,pyron}`,
`projectile_census`, `projectile_params`,
`reactions_{donovan,huitzil,pyron}`). That says the provenance is not IN THE
FILE — several have it in their gate header or a STATE entry — but the file is
what a triage is looking at, so those are where the thinking time goes.


### From "Open bugs": the declined static substituted-wheel gate

- **DECLINED (maintainer, 2026-09-02): a STATIC "substituted-wheel replay
  paired with a WIDE set" gate.** *"I don't think the static wheel/track gate
  is valuable at the moment given your arguments."* The arguments, kept so it
  is not re-proposed: 26 gates match that pattern and all 26 were checked —
  most run those replays for LEGACY content where the tenant is irrelevant, and
  every Donovan-semantic one (`audit_don_ko_writer`, `audit_don_lilith_ko`,
  `audit_continue_ladder`) FORCES THE PICK with `ff8782` pokes, so the wheel
  path cannot affect them. No text scan separates those from a real defect, so
  the gate would be 26 false positives plus an allow-list that rots.
  `test_don_sound.sh` was the only live instance and it now refuses. **The
  defence that IS in place: [VSP-163] (assert `+0x60` against `bases.tsv`, or
  force the pick) and the runtime identity assertion in
  `test_don_immortal_native.sh`.**


### From "THE COSMETIC BACKLOG": Oboro's intro (declined)

| item | status | what is known |
|---|---|---|
| **Oboro's intro eats into the round** | **DECLINED by the maintainer 2026-08-28 — do NOT delay round start or cut the intro** | recorded so it is not revived: it would be a match-state TIMING change on a shared path for a cosmetic reason, which is the trade the superset invariant exists to refuse. The maintainer will instead check whether vsavj's Oboro has an alternate SHORT intro |


### Copied 2026-09-14 from the #114 entry (the entry itself moved verbatim to `STATE_HISTORY.md` "Session 14z-154 — CLOSED ITEMS MOVED OUT OF STATE.md's STANDING SECTIONS (the open-list clean-up, verbatim)"): its rulings, as lines

- ~~**GitHub #114 — 421+P**~~ **CLOSED BY THE MAINTAINER 2026-09-02T17:53Z.
  THEIR VERDICT, verbatim, and it is a GAMEPLAY RULING that must not be
  re-opened as a defect:** *"Ceilings are the same, mash rate required slightly
  under VS2 for everything but LP, which is not a bad thing given how stringent
  VS2 is for max damage (max number of hits requires well above average
  mashing, it is legitimately very hard), LP is short one hit and comparatively
  slightly nerfed, which is acceptable on the whole, especially given the
  additional bit of leniency for other punch strengths. Close enough, leverages
  VS engine, good tradeoff, closing the ticket."*

  **RULING (maintainer, 2026-09-02): "we must respect the fact that we are
  porting the character to a different engine and the engine, being vanilla
  vsav, takes precedence."** So the gate asserts HIT COUNT and DAMAGE — the
  quantities the host clock does not set — and never vsav2's frame numbers.

  node, costing one hitbox window. **RULED (maintainer, 2026-09-02): within
  "altered by the VS engine", NOT chased** — the alternative is a one-frame
  phase change on a shared path, the trade the superset invariant exists to
  refuse. Frozen as §5 of the gate, LP asserted exactly so a move either way
  fails.

### Copied 2026-09-14 from the living-docs generalisation entry (now #119): its design rulings and sequencing, as lines

  **THE THREE DESIGN RULINGS, in the maintainer's words:**
  1. **INDEPENDENT BUT COMPATIBLE** — *"living documentation framework should
     be useable independently but fully compatible with BBH and relies on
     mostly the same principles."* So: NOT a bbh subpackage and NOT a
     dependency on it, but the same shape (one entry point, config-driven,
     a fake corpus, selftests, a skill) and the same principles. This settles
     the three-way question about `check-skills` / `skill-guide` /
     `gate-index` in the direction of compatibility rather than reclamation —
     the two packages may both carry a mechanism as long as they agree.
  2. **THE SITE GENERATOR IS IN SCOPE** — *"only a visualisation for humans
     but it's basically a free really-nice-to-have."* `mk_docs_site.py` +
     `md_subset.py` + `_pagestyle.py`, ~1,500 lines, measured at 2-4
     project-noun hits each: the most portable piece in the set.
  3. **FIDELITY: THE PRINCIPLE YES, THE FORM OPEN** — *"I don't know if
     byte-identical is warranted for the living documentation scope but on
     principle I agree."* So the extraction must be PROVEN against this
     tree, but the comparison class is a scoping question, not a given.
     Recorded so the scope document argues it rather than inheriting bbh's
     F-series by reflex: a renderer's HTML may reasonably be compared
     structurally where a checker's verdicts must be exact.


  **SEQUENCING RULED THE SAME DAY: the OPEN ITEMS COME FIRST** (maintainer:
  *"Agreed"* to the recommendation that extracting a second package is
  infrastructure built on infrastructure, and that bbh's usefulness is still
  untested by a second consumer).


### Copied 2026-09-14 from the Linux self-containment anchor entry (now #121): the whole entry

- **THE LINUX SELF-CONTAINMENT ANCHOR — DECIDED 2026-09-13: option 1 now, option 3
  the goal (not scheduled).** The everyday check is `tools/check_host_libs.py`
  against an EXTERNAL list plus five ruled exception groups (DECIDED and
  implemented at `a145562c`). The goal adds a clean-machine resolution at release
  time, on the dedicated Linux server kept free of `-dev` packages — to be built
  when that server exists. The WSL2 Ubuntu 26.04 Linux binaries are a PROOF run,
  never published (DECIDED).


### Copied 2026-09-14 from the community cross-check entry (now #117, #118): the rule for community data, as lines

  sessions. **INPUTS RECEIVED 2026-08-31 + THE RULE, maintainer's words:**
  "measurement is king, not a source that we don't know how it was measured;
  however, community information is precious: if it aligns perfectly or
  with a constant offset, then we know the measure is good; if we find an
  inconsistent pattern, then we must search whether the measurement is
  correctly done or not." So every column's deltas are classified EXACT /


### Copied 2026-09-14 from the hidden-character block: no legacy character meets a tenant in 1P arcade (ruled not a problem)

- **NO LEGACY CHARACTER EVER MEETS A TENANT IN 1P ARCADE — RULED NOT A
  PROBLEM (maintainer, 2026-08-28): "not a problem since we're way focused
  on 2p vs". CLOSED, no work planned.** Kept as a measured fact because it
  explains field observations rather than because it needs fixing.** Rows `0x00-0x0F`
  contain no reachable tenant candidate at all, so a 1P run as Morrigan (or
  anyone vanilla) can never be scheduled against Donovan, Phobos or Pyron.
  The port authored the tenants' OWN rows (what they fight) and never added
  them to anyone else's. This is the same family as the random-select item
  and arguably more noticeable in play — a player's whole arcade experience
  never shows the new characters unless they pick one. **Not built, not
  scoped, no recommendation without a ruling**, and it is a GAMEPLAY-FEEL
  change (who you fight, and the ladder is already a lottery), so it is the
  maintainer's call per CLAUDE.md 5.


### Copied 2026-09-14 from THE COSMETIC BACKLOG's introduction: cosmetic is optional

Ruled a single later pass over "the purely cosmetic things that remain related
to the port", opened when #112 was accepted as cosmetic. Nothing here is
scheduled, and none of it is competitive-2P surface (see the standing
"cosmetic is optional" scope: cosmetic + single-player-only surfaces are
nice-to-have). Collected so the pass does not start from a blank page:


## Moved 2026-09-12 (14z-151) — the 14z-133b..14z-149 rulings that stopped shaping work

Fifteen decisions, byte-verbatim, resolutions and their original entries together.
TWO were marked implemented IN PLACE first, after verifying the implementation
rather than trusting the entry: the Verilator lane's `--jobs N` scratch clones and
`ci_emulator.tsv`'s per-gate timeout column, both landed 14z-134 while their entries
still read "not started" ([VSP-13] — a stale status is what a future session acts on).

- **~~THE RELEASE PAGE'S "SOURCE CODE" ARCHIVES~~ SETTLED 14z-149 (4) by the maintainer's "publish everything available": the three platform packages are release assets and the notes + every README mark the source archives "not needed to play". (Original entry follows.)** the auto-generated
  source zips are the WHOLE repository — logs, dev tooling and all — and bring nothing a clone does not.**
  In the maintainer's words: *"the sources in the release should either be the subset needed for the recipe
  (which is not present yet) or we should remove the sources in my opinion as they bring no value compared to
  cloning the repo."* FACT that shapes it: GitHub attaches "Source code (zip / tar.gz)" to every release
  automatically and no API or setting removes them — so "remove" is not reachable; "make them irrelevant" is.
  **OPTIONS:** **(a)** attach `release/<name>/` itself as an asset, `<name>-release.zip` — exactly the ruled
  inventory (patch set, applier, end-user README, the driver patch + recipe, the MRAs + bitstream), i.e. the
  whole subset a user needs; the emulator SOURCES the recipe names are upstream FBNeo/MAME at the pins, not
  this tree; the release notes then say "take the release zip (and a binary zip for your OS); the source
  archives are the repository at the tag and are not needed". One more zip in `tools/upload_release_assets.sh`
  (it already zips, uploads and re-verifies) plus the notes text. **(b)** notes text only, pointing at
  `release/<name>/` in the repository. **RECOMMENDATION: (a)** — small, and it makes a release usable with no
  clone at all. Not built this sitting: it adds a public asset, so it waits for the word.

- **~~WHERE DO THE PREBUILT BINARIES LIVE — IN GIT, OR AS RELEASE ASSETS?~~ DECIDED (maintainer, 2026-09-11, 14z-149): (b) WITH PRUNING** — *"indeed it's the best choice and my hosting the files can always be a mirror in the future"*, after three questions answered by measurement: a git-committed binary cannot be deleted from history, only a release asset can (so "host only the latest" is reachable with assets and pruning); the maintainer's own web storage works as a mirror; the sizes are fbneo 57 MiB / 16 MiB zipped, mame 81 MiB / 15 MiB zipped (MAME compresses five-fold), ~31 MiB per OS. BUILT the same sitting: `.gitignore` (records tracked, files ignored, both places), `tools/upload_release_assets.sh` (verify → `asset` line → zip → release on the tag → upload → download back and re-verify → `--prune`), the packager's README/EMULATOR.md paragraphs point at the asset on `freeze/<name>`, both gates read a record-only directory as a fresh clone. *(The original entry follows.)*
- **WHERE DO THE PREBUILT BINARIES LIVE — IN GIT, OR AS RELEASE ASSETS? (14z-149, opened by item 1.)**
  Built and verified this session for `macos-arm64`: `release/emulators/fbneo/macos-arm64/` (fbneo + 23 bundled
  libraries, 58 MB) and `release/emulators/mame/macos-arm64/` (cps2 + libSDL3, 82 MB), each with its `BINARY.txt`;
  the packager copies them into every `release/<name>/{fbneo,mame}/emulator/bin/macos-arm64/`, so M18 is now 150 MB
  on disk where it was 11. **Committed as-is, that is ~140 MB into git history PER RELEASE (plus ~140 MB once for the
  resource dir), against a 68 MiB pack today — and Windows + Linux will triple it.** Nothing binary is committed
  until ruled. **OPTIONS:** **(a) commit them** — simplest, the tree is the release; the repository grows by ~0.4 GB
  per release once all three OSes exist, forever (history is not prunable without a rewrite). **(b) gitignore the
  binary FILES everywhere (`release/emulators/*/*/` and `release/*/*/emulator/bin/`), track only each `BINARY.txt`,
  and attach the binary directories as GitHub RELEASE ASSETS on the `freeze/merged-mNN` tag** — the record's
  sha256 rows are what make a downloaded asset verifiable, the packager and both gates keep working on a host that
  has built or fetched them, and a fresh clone sees no `bin/` (allowed by the inventory: "optional"). Cost: one more
  step in the release ritual (`gh release upload`), and a fresh clone's `test_release_binaries` SKIPs until the
  host builds or fetches. **(c) git LFS** — the files stay "in the tree" but every clone pays the LFS quota and
  GitHub's free tier is 1 GB storage / 1 GB bandwidth per month, which one release would consume.
  **RECOMMENDATION: (b).** It is what every emulator project does with its binaries, the hash record keeps the
  trust surface in the tree, and it costs nothing that (a) does not cost more of later.

- **~~DEFINE WHAT IS IN A RELEASE, AND SHIP THE HOW-TO README~~ DONE 14z-148
  (2026-09-11): the inventory MEASURED then RULED (*"I agree with the
  inventory"*), enforced as an allow-list in `test_release_roundtrip` §4 with
  the README's five sections; the applier PURE PYTHON; the stock-emulator
  stall MEASURED and locked; **RULED for the emulators: recipe AND prebuilt
  binaries, each user free to choose (1+2)** — the slot and its record exist,
  the binaries are a FOLLOW-UP (macOS here, Windows/Linux on the remote
  boxes); MiSTer unchanged (RBF + MRA on top of the patch set). Spec:
  `docs/project/release_format.md` "WHAT A RELEASE IS". (maintainer, 2026-09-10,
  14z-147b: *"like with SMS, due to the nature of the deliverables, we should
  define what is in the releases so that each release is limited to exactly
  what is needed to be in the release, with a proper README that includes the
  how-to since we don't provide any ROMS or such copyrighted assets, ever"*).** What exists to start from:
  `docs/project/release_format.md` (one self-sufficient directory per platform
  since merged-m10: the patch set, `manifest.json`, `apply_release.py`, a
  README, the emulator driver patch + `EMULATOR.md`, the MiSTer `.mra` +
  `.rbf` + `BITSTREAM.txt` + `MISTER.md`), `tools/package_release_platforms.py`
  (the producer), `tests/test_release_roundtrip.sh` (the layout gate, rule 7's
  verbatim-chunk scan). What the item asks for beyond that: (1) a DEFINITION
  of the release contents — an explicit inventory of what belongs in a release
  and, as importantly, what does not (nothing derived from the reference
  dumps, nothing a user cannot legally receive; the SMS precedent: the release
  is patches + tools + instructions, and the user supplies their own dumps);
  (2) a README written for the END USER — what you need (which reference sets,
  named by the checksums the applier verifies), how to apply on each platform
  (FBNeo / MAME with the driver patch and the pinned emulator, MiSTer with the
  MRA + bitstream), what "success" looks like (the in-game mark, the name
  screen), and the statement that no ROM or copyrighted asset is ever
  distributed; (3) the gate: `test_release_roundtrip` §4 should assert the
  inventory (nothing outside the definition ships, everything in it does) and
  that the README carries the how-to sections. Cost: T2, one session; no
  gameplay surface, no build byte — a packaging/documentation change, ruled at
  the plan stage by the maintainer as usual (present the inventory before
  writing it).

- **~~THE MUST-FIRE DOCTRINE'S MACHINE READER — STEP TWO AGREED IN SHAPE~~ STEP TWO BUILT 14z-147, PASS 1 (the reader, the runners, the portable tier) LANDED; PASS 2 (the static tier, 19 gates) LANDED 14z-147b; PASS 3 (the emulator tier, 34 gates = the census's `retrofit-debt` class) LANDED 14z-147c — the census is now 83 / 0 / 0, the retrofit COMPLETE across all three tiers; the HONOURED run of the 34 emulator modes is the freeze/release sweep (`run_all_emulator.sh --controls`), not a pre-commit; the last open half RULED (maintainer, 2026-09-10, 14z-148): the cadence of `run_all_emulator.sh --controls` at release is option (a), THE RELEASE RUN — *"I agree with item 2's proposal. We can always adjust later if the need arises."* Recorded in HANDOFF "THE EMULATOR-TIER COMMAND" (the release invocation) and the runner's header.** What landed: `tests/lib/controls.sh` (the four regexes, a COPY of BBX's R10 — and R30 resolved the bare-`#` trap this entry warned about: the header is the leading comment block, a bare `#` continues it), `classify.sh` handing FAIL to a red block (no fourth verdict), `run_all_static.sh --exec-controls` (every declared control run as `CONTROL=<name>` after a PASS; LIES / REFUSED / DIED named), `run_all_emulator.sh --controls` (rows `<gate>@<name>`), the census switched to the grammar with three frozen classes, `test_controls_contract.sh`, and 30 gates declaring under the grammar (every portable declaring gate, each verified plain-PASS with every control FIRED and every mode HONOURED). Spec of record `docs/project/must_fire_contract.md`, rule [VSP-181]. **THE DECISION, two halves — (i) DECIDED 2026-09-10, option (a); (ii) stands at its recommended default, no ruling asked:** (i) the emulator tier's executable controls multiply a tier measured in hours (34 declaring gates, ~2-4 controls each); options (a) `--controls` in the release checklist only, (b) on every freeze sweep, (c) on the mame lane only — RECOMMENDATION (a), measured first at the next release run; (ii) MEASURED 14z-147 on the portable tier: `--exec-controls all` (the default, the agreed shape) makes the pre-commit portable tier ~22 min where the tier alone is ~4 min — keep the default and iterate with `--exec-controls none`, or reserve the executed form for the close and the release? RECOMMENDATION: keep the default (a lying control must not pass a pre-commit); the developer knob exists. *(Original entry follows.)*
- **THE MUST-FIRE DOCTRINE'S MACHINE READER — RULED (maintainer, 2026-09-10, 14z-145): STEP ONE DONE, STEP TWO AGREED IN SHAPE, waiting on BBX's R10 for the contract's line and env name.** Step one shipped: `tests/test_must_fire_census.sh` (78 declaring gates, grows only; 10 header-only, shrinks only — `audit_guard_corpus audit_hui_grunt audit_kill_poke_shape audit_pyron_ring run_battery_m2 test_don_reactions test_pyron_medallion_2p test_ref_rot_image_pick test_suite_dispatch test_tenant_id`). Step two, agreed point by point: (1) the retrofit's acceptance test is IDENTITY — every gate's verdict on this tree (static tier + the emulator sweep) and bbh's selftests/fidelity unchanged before and after — which catches a badly written retrofit but is BLIND to a vacuous control by construction; so (2) the contract makes each control EXECUTABLE — `CONTROL=<name> tests/<gate>.sh` must exit with the gate's own FAIL — and the runner invokes it, which is [VSP-19] run by machine; (3) one pass on a quiet tree, one strict run per pass; (4) NO fourth verdict: a missing "fired" line and a control that leaves its gate green are both plain FAIL. The maintainer's words: *"agreed with everything you just said"*. Not scheduled; the census does not change when the contract lands.
  **R10 SETTLED IN BBX (read 2026-09-10 from `~/Developer/generalized-blackbox-harness/BBX/docs/controls.md`, READ-ONLY to me; GitHub `DefinitelyFrenchName/BBX`, private).** THE GRAMMAR: one header line per control, `# MUST-FIRE: <shape>: <name> — <what must fail, and why that proves the gate can fail>`, shape ∈ `perturbed-copy | shadow-tool | known-bad`, name `[a-z0-9-]+`; a non-asserting gate says `# MUST-FIRE: none — <why>`; the gate prints `CONTROL FIRED: <name> — <evidence>` or `CONTROL DEAD: <name> — <what happened>`; the registry is derived from the headers every run; declared-not-fired, DEAD, and fired-not-declared are all RED and refuse the verdict; the readout counts fired / declared; enforcement is a config switch (`[controls] enforce`), off = bbh's output byte for byte. The one reader is four regexes (`lib/py/bbx/controls.py`). R10 says of itself that it does NOT prove a control is right. **AGAINST OUR FOUR POINTS:** (2) partly — R10's DEAD is the gate's SELF-report ("failed for its stated reason"); the executable form (`CONTROL=<name> gate` must FAIL under the runner) is an ADDITION over R10 and compatible with it (the lines stay, the runner also invokes); (4) agrees — no new verdict word (their R13 keeps the four); (1) and (3) are ours, orthogonal. **ONE COMPATIBILITY TRAP for the retrofit here:** R10 reads the header as "line 2 to the first bare `#`", and this tree's gate headers use bare `#` lines as paragraph separators from line 6 on — so every `# MUST-FIRE:` line must sit directly under the title line, before the first bare `#`, or the reader sees nothing. **FOR THIS TREE:** the grammar is now fixed, so step two = (a) 78 gates gain their `# MUST-FIRE:` lines and print `CONTROL FIRED:`/`CONTROL DEAD:` (the 10 header-only ones gain a real control or `none — <why>`), (b) `tests/lib/classify.sh` reads the same four regexes — a COPY, never a dependency on BBX ("independent but compatible") — and turns a red controls block into FAIL, (c) the census gate switches its regex to the R10 declaration, (d) the executable-control check and the identity bar as agreed. Still not scheduled.

- **~~EXTEND THE FREEZE-ARTIFACT CHECK TO `patch_index.md`'s REGISTRATION CELLS~~ DONE 14z-145** — section 4 of `tests/test_freeze_artifacts_current.sh`; ground-truthed on the REAL stale state, which was worse than this entry says: the four track rows' CURRENT cells had last moved at the 14z-119 freeze (`git log -S`), FOUR freezes stale, edited around by the 14z-144 close. Five controls incl. the history-is-not-a-target negative. STATE 14z-145. *(Original entry follows.)*
- **EXTEND THE FREEZE-ARTIFACT CHECK TO `patch_index.md`'s REGISTRATION CELLS
  (added to the opener at the maintainer's word, 2026-09-09). Not started.**
  `tests/test_freeze_artifacts_current.sh` (14z-144) covers the two artifacts
  that rotted; this is the next named member of the same class, and it has
  MEASURED evidence rather than a hunch — the table has gone stale the same way
  TWICE, and says so about itself:
    * a registration cell read "UNREGISTERED … expectation sets NOT yet frozen"
      from 14z-127 until 14z-132 (the table's own parenthetical records it)
    * the pyron capture row did exactly that from 14z-143 until 14z-144
    * and the donovan WIDE cell carried "KNOWN OPEN DEFECT ON THIS TRACK" for
      hours AFTER the defect was fixed, frozen, released and pushed — [VSP-13]'s
      worst case, a header asserting the opposite of reality
  **IT FITS THE DISCRIMINATOR:** the cells are derived from the build set
  (fingerprints, build dirs, freeze names, registration status) and no
  ci_static gate checks them, which is exactly why they rot while
  pointer_flow/charmap/bases.tsv never have.
  **SHAPE:** parse the fingerprints and `build/<dir>` tokens from the table and
  require CURRENT-marked cells to name the current freeze — `registry.tsv` and
  `run_all_emulator.sh`'s placeholder defaults already state what that is.
  **THE TRAP TO AVOID, paid for in the 14z-144 re-point sweep:** a
  `<freeze-name> (build/<dir>)` pairing and every `prior …` clause are HISTORY,
  never targets. The check keys on CURRENT cells only, or it will demand the
  falsification of dated records.
  Cost: small, static, no gameplay surface, no build byte.

- **~~THE EMULATOR RUNNER PARALLELISES BY BARRIER, NOT BY QUEUE~~ IMPLEMENTED
  14z-144 (maintainer: *"We need to implement according to both items to
  indeed carry forward"*).** `run_all_emulator.sh` now uses a FIFO token
  semaphore whose TOKEN IS THE SLOT NUMBER, so taking work and acquiring a
  scratch clone are one atomic act; serial lanes open no FIFO, so `--jobs 1`
  and the prereq lane are byte-for-byte the old path. **CO-RESIDENCY
  ESTABLISHED, NOT ASSUMED:** the full 130-gate mame lane re-run under the
  queue, every verdict compared against the same gate under the barrier —
  **130/130 agree, 0 disagree**. **MEASURED 3.48x (1.90h -> 1.21h, 41 min
  saved per sweep)** — the RATIO is exactly what the barrier model predicted,
  the ABSOLUTE is not: the same 130 gates sum to 4.23h serial under the queue
  against 3.13h under the barrier, because sustained four-way concurrency
  makes each gate ~35% slower where the barrier left slots idle. **The model
  assumed per-gate cost is independent of load and it is not** — the 0.90h I
  quoted twice was optimistic; 41 min is the honest figure. Three defects in
  my own code were found by reading it before running it (two `[ … ] && x=y`
  set -e aborts, and the gate inheriting the token fd).
  **AND THE 35% IS A PROPERTY OF THIS HOST, NOT OF THE QUEUE (maintainer,
  2026-09-09: *"on a machine with more cores/threads, the improvement may
  improve because the price of parallel processing would be lessened"*).** The
  measurement was taken on the MacBook — 8P+4E, 16 GB — at 4-way, where four
  concurrent MAME runs contend for memory bandwidth and cache. On a wider host
  the per-gate penalty shrinks and the queue's advantage GROWS toward the ideal
  3.13h/N, and `--jobs` above 4 starts paying where today it mostly does not
  (barrier 2.47x vs queue 6.05x at 8, both modelled on the OLD per-gate costs
  and therefore both optimistic on this machine, but the RATIO between them is
  the part that holds). **THE HOSTS ALREADY ON OFFER** (STATE "the Verilator
  lane is serial for one reason"): the Windows Ryzen 9 3900X / 32 GB that built
  the first bitstream (12c/24t) and the coming Linux Ryzen 7 5700G / 64 GB.
  **SO THE NUMBER TO RE-MEASURE, NOT RE-DERIVE, when a wider host is set up:**
  the mame lane's serial sum at N-way on that machine. If it stays near 3.13h
  where this one inflated to 4.23h, the contention was ours and the queue is
  worth substantially more than 41 min there. `test_mame_parity` is the
  migration gate for any new host ([MFI-41]).
  *(Original entry follows, unrewritten.)*
- **THE EMULATOR RUNNER PARALLELISES BY BARRIER, NOT BY QUEUE — MEASURED, AND
  THE MAINTAINER PREFERS THE PULL MODEL (direction, 2026-09-09).** Their words
  on the barrier: *"that's to be expected since it's pushed batching system and
  not 4 separate queues acting as a pulled system (which would have my
  preference by far)"*, and on the shared-queue shape: *"agreed, I just didn't
  think it was on the table"*.
  **MEASURED on the 14z-144 M17 sweep**, and the barrier model reproduces the
  observed wall-clock to two decimals (1.90h predicted, 1.90h actual), which is
  what makes the counterfactuals credible rather than arithmetic:

  | mame lane, 130 gates, 3.13h serial | wall | speedup |
  |---|---|---|
  | barrier, registry order (today) | **1.90h** | 1.65x |
  | barrier, longest-first (reorder only) | 1.00h | 3.13x |
  | true work queue | **0.90h** | 3.48x |

  At `--jobs 8` the gap widens: barrier 2.47x, queue 6.05x — so the 12-core
  machine is largely wasted today.
  **WHY IT IS A BARRIER, established by archaeology rather than guessed:** the
  runner is `#!/bin/sh` = bash 3.2 on macOS, where `wait -n` does not exist
  (checked: `invalid option`), so "wake when any slot frees" is not expressible;
  and the slot->clone binding added at 14z-134 uses `_running` as the index,
  which the barrier is what resets. It was never a trade-off weighed against a
  pull model — it is what falls out of the shell. The one scar in that code is
  14z-128's orphaned background jobs (the lane loop ran in a subshell so `wait`
  had nothing of its own), which is why the rows go through a file.
  **THE SHAPE, and it IS available in this shell:** a FIFO token semaphore
  where THE TOKEN IS THE SCRATCH CLONE NAME, so pulling the next gate and
  acquiring a free clone are one atomic act — which dissolves the positional
  `_running` binding rather than working around it. Token writes are single
  short lines (atomic under PIPE_BUF); the loop stays in the main shell so the
  14z-128 scar does not reopen; `results.tsv` is already appended concurrently
  and `--resume` keys on gate name, so non-deterministic row order costs
  nothing. ONE shared queue with N pullers, not four static queues — static
  per-worker queues reintroduce head-of-line blocking at finer grain.
  **TWO THINGS TO ESTABLISH, not assume:** that gate co-residency is safe under
  a DIFFERENT pairing (the suite's contract says self-contained; that is a claim
  wanting a control, not a given), and that the two-leg gates' `-b` clones
  compose with a token pool rather than fight it.
  **ALSO MEASURED 14z-144, and it revises an earlier warning of mine:** the
  MiSTer gates are NOT core-bound — `test_mister_gfxc_fetch` ran **-46.6%**
  against its M16 figure while sharing the machine with three other sims, and
  the others moved +3.4% / +3.7% / +0.2%. So M16's numbers are the CONTENDED
  ones and `--jobs` above 4 would pay on that lane too. Not started; harness
  only, no RTL.

- **~~[VSP-178]'s CLASS HAS NOW BITTEN AT TWO CONSECUTIVE FREEZES~~ FOUR TIMES,
  AND THE CHECK IS BUILT (14z-144).** `tests/test_freeze_artifacts_current.sh`
  (ci_static, family pipeline): two rows chosen by a stated discriminator —
  tracked, derived from the build set, and NOT already covered by a ci_static
  gate that fails on staleness. GROUND-TRUTHED ON THE REAL HISTORICAL STALE
  STATES: merged1 at 829 ops, merged1 at 831 ops with one value differing
  (which is why it compares op CONTENT, not count), and the pair recording
  merged-m16 — all three caught with accurate diagnoses. The build set is READ
  from the runner's own placeholder defaults so the gate cannot disagree with
  it about which build is current. *(Original entry follows, unrewritten.)*
- **[VSP-178]'s CLASS HAS NOW BITTEN AT TWO CONSECUTIVE FREEZES, and the
  cadence column cannot fix it (14z-144). ON THE OPEN-ITEMS LIST
  (maintainer, 2026-09-09: *"let's add it to the todo list"*) — AGREED as a
  work item, not merely recorded; not yet scheduled against a session.** M17 shipped with
  `tests/expect/mister_prg_window.txt` frozen on merged-m16 and `build/merged1`
  two ops stale; both are tracked artifacts that FOLLOW THE ROMSET. 14z-134
  responded to the first instance by changing that gate's cadence to `romset` —
  which tells the RUNNER what to run, and says nothing to the FREEZE about what
  to refresh. So the same thing happened again one freeze later.
  **THE OBSERVATION:** every other romset-following artifact IS refreshed,
  because a gate fails loudly in the static tier when it is not (pointer_flow,
  charmap, the artifact manifests, bases.tsv). The two that rotted are the two
  whose gates are NOT in the static tier — one is a ~1h Verilator gate, the
  other rebuilds itself and only shows up as working-tree churn.
  **SHAPE IF WANTED:** a freeze-ritual check that enumerates tracked artifacts
  whose content is derived from the build set and asserts each was regenerated
  since the current freeze's commit — cheap, static, and it would have caught
  both. Not a new rule; a rule that runs.
  **THE TWO KNOWN MEMBERS, as the starting inventory:**
  `tests/expect/mister_prg_window.txt` (frozen pair; its gate is a ~1h
  Verilator run, so nothing in the static tier can see it rot) and
  `build/merged1/` (the merged-legacy instrument, which REBUILDS itself and
  therefore surfaces only as working-tree churn a human has to notice).
  **THE DISCRIMINATOR that makes the check writable:** an artifact belongs in
  it when its content is derived from the build set AND no ci_static gate
  already fails on staleness — pointer_flow, charmap, the artifact manifests
  and bases.tsv are all covered today and would be excluded, which is why they
  have never rotted.
  **COST:** small — a static gate plus its must-fire control; no gameplay
  surface, no build byte. Agreed to the list 2026-09-09; not scheduled.

- **~~DONOVAN THROWING JEDAH USES DONOVAN'S OWN VICTIM KEYFRAMES ON EVERY WIDE
  BUILD~~ RULED AND SHIPPED 14z-144 AS M18 (maintainer, 2026-09-09: option (a),
  *"Do the Donovan throwing Jedah fix then finish the release"*). The entry stays
  for the measurement trail. THE FIX: `donovan.toml`'s `throw_victim_keyframes`
  gained `fixes_variant = ""` — the `_variant` twin `row_hex()` already defined
  for `new_hex`, taught to the `data_port` fixes key — so the 14z-64 rewrite
  applies on the BASE-SLOT track only. WIDE program delta EXACTLY TWO BYTES
  (`0d88 -> 0b30` at blob offset `0x1E`); stock twin byte-identical, which is the
  control that the base-slot track kept the fix. `audit_capture_matrix` 640/640
  with its KNOWN set EMPTY on merged-m18 while merged-m17 still fails the cell.
  `test_capture_kf_ownership` rewritten to the two-sided invariant and
  ground-truthed both ways. Detail: patch_notes 14z-144, STATE 14z-144.
  *(Original entry follows, unrewritten.)*
- **DONOVAN THROWING JEDAH USES DONOVAN'S OWN VICTIM KEYFRAMES ON EVERY WIDE
  BUILD — found 14z-143 by the new full-matrix audit, PRE-EXISTING since
  14z-64, and the fix is a gameplay call.** Not a regression from the M17
  freeze: measured identical on `merged23`.
  **THE MECHANISM, measured.** `donovan.toml`'s `throw_victim_keyframes`
  carries `fixes = "0x1E:0b30:0d88"` — the 14z-64 mirror-victim correction,
  which rewrites the blob's VICTIM offset word `[0x0F]` from the
  Jedah-victim sub-block to the DONOVAN-victim one. That is RIGHT on the
  STOCK track, where Donovan substitutes Jedah at slot `0x0F` and victim
  `0x0F` genuinely IS Donovan (the mirror flavour the fix was written for).
  **On a WIDE build Donovan is at `0x13` and `0x0F` is JEDAH, restored** — so
  the rewrite redirects a reachable LEGACY victim's keyframes. The manifest's
  own note calls the fix "harmless" at a variant id because its `[0x0F]`
  entry "is never a TENANT victim there"; that is true, and it is not the
  question — `0x0F` is a legacy victim and an ordinary 2P matchup.
  **MAGNITUDE:** the two sub-blocks differ in **225 of 408 bytes (55%)**;
  early deltas are close (`-60,0` vs `-56,0`) but the last keyframe is
  `(-61,166)` where Jedah's is `(-76,32)` — 134 px of vertical difference —
  and the poses differ (`0,8,6,0,1,0,8,17` vs `0,8,7,1,0,0,9,20`).
  **MEASURED IN-EMULATOR 14z-143, and it confirms the static read exactly**
  (`tools/capture_sheet.sh 13 0f`, merged-m25 vs native `vsav2`):
  **offset-set overlap 0 of union 19** — ours `(56,0) (48,0) (56,0) (74,9)
  (81,15) (61,166) (39,204) (80,211) (97,187) (108,42) (95,0)`, native
  `(60,0) (84,8) (86,16) (76,32) (84,56) (88,72) (94,72) (91,42) (80,0)`.
  Ours reproduces the DONOVAN-victim sub-block's magnitudes (56, 48, 56,
  74/9, 81/15, 61/166) and native reproduces JEDAH's (60, 84/8, 86/16,
  76/32) — the two blocks read statically from vs2's Donovan block. **So
  this is the SECOND cell measured both ways with no shared premise and
  agreeing**, which strengthens [VSP-180]'s anchor rather than merely using
  it. Sheet shown to the maintainer 2026-09-08.
  **OPTIONS:** **(a)** gate the `fixes=` row to the base-slot track (a
  `fixes` twin keyed like `only_base_slot`, or a `fixes_variant = ""`), so
  the WIDE blob keeps vs2's own `[0x0F]` = the Jedah-victim sub-block —
  section 2 of `audit_capture_matrix` proves vs2's legacy victim data is
  byte-identical to vsavj's, so that IS Jedah's real geometry; **(b)** leave
  it and record that Donovan's throw of Jedah uses his own victim geometry as
  accepted; **(c)** measure first with the rig above, then decide.
  **RECOMMENDATION: (c) then (a)** — the measurement is ~4 minutes on an
  existing rig and turns "a row is mis-scoped" into "here is what it looks
  like", exactly as it did for Pyron. (a) is a one-line manifest change but
  it MOVES SHIPPED BYTES on the WIDE tracks, so it is a freeze.
  **LOCKED MEANWHILE:** the cell is frozen as a KNOWN-OPEN divergence in
  `tests/audit_capture_matrix.sh`, so it cannot rot; removing that row is
  what proves a fix landed.

- **THE RELEASE RESUME'S ONE REAL RED — `test_mister_prg_window`'s FROZEN
  PAIR IS STALE (frozen on merged-m10, five freezes ago) — HOW TO CLOSE IT
  (14z-134).** The structural half of the gate passed on merged-m16 (the
  decode is gated, the control leg reads nothing above `$400000`, the
  profile-ON leg executes 1.2 M program reads from the extension); the
  frozen pair failed because the first extension address the 68k executes
  is the relocated OBJ walker, and the hole allocator moved it from `$4BE7C0`
  to `$4C13D0` when later freezes added content before it (STATE 14z-134).
  The numbers measured on merged-m16 are IN THE RUN'S LOG, byte-exact (the
  `>` lines of the diff are the probe's own summary lines the `--freeze` mode
  writes). **OPTIONS:** **(a) re-freeze the pair on merged-m16 from a fresh
  `--freeze` simulation (~108 min) and re-run the gate under the runner** —
  two more simulations, the cleanest record; **(b) re-freeze from THIS run's
  measured lines (they are the measurement; the gate would have written the
  same bytes) and re-run the gate ONCE under `--resume`** (~108 min) so the
  release record holds a runner-produced PASS on the m16 pair; **(c)** accept
  the log as the verdict and hand-edit the results row — refused: the runner
  produces the record. **PLUS, whichever:** the row's cadence becomes
  `romset` (its pair follows the romset like the two ruled exceptions, so it
  re-freezes at every freeze instead of rotting silently until a release),
  and `tests/expect/` joins `test_expectation_provenance`'s scope.
  **RECOMMENDATION: (b)** — one simulation instead of two, and the re-run is
  what makes it evidence. Sequencing: the edit is a tracked-file change, so
  it lands AFTER the current resume exits (the runner's tree check), then a
  second `--resume` for this one gate. **RULED (maintainer, 2026-09-06):
  (b)** — *"let's go with option (b) which is the fastest, and then we'll
  adapt the harness"*. Prepared while the resume ran: the measured pair
  lines extracted from the log, `tests/expect/` brought into
  `test_expectation_provenance`'s scope with three rows (worktree). Executed
  after the resume: see the 14z-134 rows.

- **~~THE VERILATOR LANE IS SERIAL FOR ONE REASON — ONE SCRATCH CLONE~~ IMPLEMENTED 14z-134** (verified 2026-09-12 before archiving: `run_all_emulator.sh --jobs N` gives slot 0 the base `JTSIM_SCRATCH` and slot N `<base>-slotN`, and the lane that took ~11 h serial fits in ~3 h at four jobs). *(Original entry follows.)*
- **THE VERILATOR LANE IS SERIAL FOR ONE REASON — ONE SCRATCH CLONE — AND
  THE MAINTAINER WANTS IT PARALLEL (direction, 2026-09-06; the question:
  *"we're operating under a tenth of this macbook m2 pro's capacity … can't
  we have separate instances of the checker?"*).** Measured before answering:
  every MiSTer gate defaults `JTSIM_SCRATCH` to the one clone and each run
  writes its `rom.bin` link, `sim_inputs.hex`, bank dumps, `wram/`, probe
  files and `obj_dir/` INTO that clone's core dir, so two sims in one clone
  clobber each other; the runner already has `--jobs N` (only prereq is
  forced serial); jtframe's `jtsim` never passes Verilator a threads flag
  (the model is single-threaded by construction, and a threaded build would
  change the instrument); one sim is one core at 99 %, ~97 MB RSS, a clone
  is 1.4 GB (368 MB the generated `.rom`, 57 MB `obj_dir`); the machine is
  8 P + 4 E cores, 16 GB, ~196 GB free. **THE SHAPE:** N scratch clones
  (the heal tool provisions any dir at the pin; the first run per clone pays
  the Verilator build — UNMEASURED, the one number to establish first), the
  runner assigning a clone per job slot via `JTSIM_SCRATCH` for the MiSTer
  lane, optionally the two legs of a gate on two clones. Everything else is
  already isolated (MAME sandboxes, the private `$HOME` for MRA staging,
  per-gate temp dirs). Expected: the ~11 h serial lane becomes the longest
  gate (~3 h) at four clones, ~1.5 h with leg parallelism; the 4-hour cap
  question mostly dissolves. Harness only — tools and tests, no RTL, no fork
  commit; ~half a session plus the measurement. **ALSO ON OFFER (maintainer):
  the Windows box that built the first bitstream (Ryzen 9 3900X, 32 GB) and a
  coming Linux Ryzen 7 5700G / 64 GB — a MacBook setup and a remote-runner
  one may both make sense; cost both shapes when scoping, and
  `test_mame_parity` is the migration gate for any new host ([MFI-41]).**
  Queued behind the release close; not started.

- **~~THE RUNNER'S TIMEOUT IS ONE SIZE FOR 165 GATES~~ OPTION (a) IMPLEMENTED 14z-134** (verified 2026-09-12 before archiving: `ci_emulator.tsv` has the optional 7th column and 10 rows carry a measured per-gate timeout). *(Original entry follows.)*
- **THE RUNNER'S TIMEOUT IS ONE SIZE FOR 165 GATES — HOW SHOULD A GATE'S OWN
  RUNTIME REACH THE RUNNER? (14z-134, from the two release-run TIMEOUTs.)**
  `run_all_emulator.sh` has a single `--timeout` (default 5400 s) while the
  registry rows already DESCRIBE runtimes in prose (`"~93 min a leg, two
  legs"`, `"~65 min"`). The release resume runs under `--timeout 14400`, which
  is correct for the MiSTer lane and eight times too generous for a MAME gate
  that hangs. **OPTIONS:** (a) a `timeout` COLUMN in `ci_emulator.tsv` (a
  seventh field, seconds or `-` for the default) — exact per gate, one schema
  change, the §10 validator and every row touched, the header-defaults rule
  extended to it; (b) a PER-LANE default in the runner (`mister` × 4, the
  others as today) — one line, no schema change, but a lane-wide number that
  a slow MAME soak (the tripwire marathon is ~15 min) cannot use; (c) keep
  the global flag and a `--timeout` in the release checklist — what happened
  today, and it is a ritual step, which is the thing that gets skipped.
  **RECOMMENDATION: (a)**, because the runtime is a property of the GATE (its
  header states it already) and the runner's other per-gate facts live in the
  registry, not in flags; (b) as the stop-gap if (a) waits. Not swept
  unasked; no gameplay surface.

- **~~THE M16 RELEASE RUN'S ONE EXPECTED NON-GREEN — `audit_mask_window_ff42a2`
  SKIPs — NEEDS THE MAINTAINER'S APPROVAL AT RELEASE TIME~~ APPROVED 2026-09-06,
  option (a), a standing exception in the registry note (14z-134; the
  policy: "RELEASE-TIME TEST SCOPE", *"unless explicitly approved AT release
  time, anything red, anything skipped is a hard fail"*).**
  **WHAT THE GATE IS:** the pre/post ATTRIBUTION INSTRUMENT for a
  select-palette row move ([VSP-35]) — it A/Bs a PRE-move build against a
  POST-move build on the replays whose self-frozen `.sha1` the move shifted,
  and requires every differing byte to fall inside the ratified staging
  family. It is what caught the 14z-88 `38_victor_p1_vsavj` superset
  regression (the medallion row move cost the select->VS fade one main-loop
  iteration), and it is kept for the next such move.
  **WHY IT SKIPS, by construction:** its operands DESCRIBE A CHANGE UNDER
  INVESTIGATION — a pre-move rompath, a post-move rompath and the replay names
  the change shifted. There is no default pair because there is no default
  change; invoked bare it prints `SKIP: no operands — this is the pre/post
  attribution INSTRUMENT …` and exits 0 (14z-128, after the sweep recorded a
  shell error as a FAIL). The registry marks it `out` / `momentary:` for that
  reason (ruled 2026-09-03). Under `--strict` the runner counts the SKIP as a
  failure, so **the run's expected end state is PASS 164 / SKIP 1 / FAIL 0
  with the strict verdict RED on that one row.**
  **WHAT APPROVING MEANS:** the SKIP is not a missing measurement of the
  artifact. No select-palette row moved in M16 (the delta is two glyph
  members, `vsw.33m`/`vsw.37m`, and the program fingerprint is unchanged), and
  the merged build's select-screen state IS measured by the gates that ran:
  the frozen masked legacy classes on merged (B2, 53/53), `audit_legacy_pairings`,
  `audit_flicker_attribution`, the pixel gates. Approval says "this instrument
  has nothing to attribute today", not "we did not look".
  **OPTIONS:** **(a) approve the SKIP and RECORD it as a STANDING release
  exception** in the gate's `ci_emulator.tsv` note (e.g. `release: SKIP
  approved 2026-09-05 — an instrument with no default subject`) so the next
  release run does not re-ask — a `tests/` edit, after the run. **(b) give it
  a standing pair** (last freeze vs this freeze, the moved `.sha1` list) — but
  with no row move between them the pair is bit-identical and the audit
  REFUSES to attribute a move that did not happen; a synthetic pair measures
  nothing. **(c) drop it from the registry** — refused by the project's own
  history: it is the instrument that caught the 38 regression. **RECOMMENDATION:
  (a).** One line; the exception is then a reviewed row, not a ritual step.

  **DECIDED (maintainer, 2026-09-06): (a), *"agreed"* — recorded in the gate's
  `ci_emulator.tsv` note the same day. LEFT FOR LATER, in the maintainer's
  words: *"whether to set the skipped gate as either deprecated or
  case-specific, as it kind of is but let's circle back to that later."**
- **TWO BACKLOG ITEMS, RECORDED AS DIRECTION (maintainer, 2026-09-05, 14z-133b)
  — ~~nothing scheduled; both are multi-session and wait behind the field test
  and the release~~ (1) EXECUTED 14z-134 with the maintainer's blessing while
  the M16 release run was in flight, in a worktree ("If item 2 does not
  jeopardize anything ongoing you have my blessing"): `mame-fbneo-instruments`
  `[MFI-1..46]` and `mister-jtframe-core` `[MJC-N]`, 109 of 145 CPS-2 rules
  lifted with their numbers, every old ID kept as a redirect; the three
  decisions in `docs/project/skills_scope.md` §7 RULED accepted the same day
  with one addition — a self-contained GUIDE.md per level-0 skill and a
  self-contained skill for other projects — DONE: `tools/gen_skill_guide.py`
  GENERATES the guide from the anchored paragraphs, `test_skill_guides` keeps
  it current, the skill directory is the portable unit; (2) STARTED 14z-135
  (2026-09-06, the maintainer: *"I need the generic reusable test harness and
  the living documentation effort. After that we'll tackle the open items"*):
  the scope is `docs/project/harness_scope.md` — the four bins, the slices
  H1-H9, the fidelity contract — and two things were RULED at the plan stage
  the same day: a SEPARATE repository, `~/Developer/blackbox-harness`
  (git-initialised locally; GitHub and any push the maintainer's), and this
  tree gains exactly ONE read-only fidelity gate. Slice H1 opened the same
  session (STATE 14z-135).** In the
  maintainer's words:
  **(1) A HIGHER-LEVEL SKILL SPLIT FOR EMULATION AND MiSTer — EXECUTED 14z-134.** *"for skills and
  documentation, look if there an additional split for both emulation and
  MiSTer at the highest level. Namely: are there skills transferable for
  MiSTer or MAME/FBNeo projects that are not necessarily CPS-II based."*
  What exists to start from: the six in-tree skills are cut by the
  `docs/README.md` question ("would this still be true if we abandoned the
  roster hack?") into platform / game / port, and the platform pair is
  CPS-2-SCOPED by name (`cps2-emulation` [CPE], `cps2-hardware` [CPH],
  `mister-cps2-wide-core` [MSC]); the only board-agnostic skills on this
  machine are the SMS-era `romhacking-methodology` and `snes-romhacking`,
  which live OUTSIDE this repo. The candidate cut is one question up: "would
  this still be true if the board were not CPS-2?" — e.g. MAME/FBNeo AS
  INSTRUMENTS (what -debug, breakpoints, write taps and Lua observe and miss;
  CRC-vs-name member resolution; the rompath chain; determinism and the
  sandbox; two-implementation comparison at anchors) and jtframe/MiSTer AS A
  PLATFORM (the Verilator lane and its instrument traps, SDRAM tiers, MRA
  generation by CRC, the fitter seed lottery, the separate-core mechanism).
  Method: walk every [CPE]/[CPH]/[MSC] rule and classify it CPS-2-specific
  or transferable; the transferable ones become two new level-0 skills the
  CPS-2 ones then SIT ON, exactly as `mister-vampire-saved` sits on
  `mister-cps2-wide-core`. `tools/checkskills.py` and the anchor census are
  the enforcement, as for every skill so far (`docs/project/skills_scope.md`
  is the record of the last cut). Cost: T2-T3, one to two sessions.
  **(2) A GENERIC, REUSABLE TEST HARNESS — extracted, then its skill.** *"go
  through all our documentation and rules and rulings and principles
  regarding our test harness (including files up to CLAUDE.md) and extract
  the harness from the specificities of this project. The goal is not to
  replace the custom harness of this project but to create a separate, more
  generic one, able to be reused in other projects, especially such
  black-box adjacent projects. Then after that is done, distill the skill
  that goes with that generic harness."* What exists to start from, all of
  it project-shaped today: CLAUDE.md §4 (the oracle-replay method, the
  frozen expectation classes, dual-emulator agreement at anchors, the
  persistent-suite doctrine, verdict logic itself tested, recordings before
  theories) and §5 (retraction discipline, bug archaeology, the
  anti-hyperfocus checkpoint); `docs/project/oracle_classes.md` (the class
  spec of record); `docs/project/gate_scoping_method.md` [VSP-167..174];
  `tests/run_all_static.sh` / `run_all_emulator.sh` (SKIP is not PASS,
  anti-orphan registries both ways, prereq lane first, cadence and scope
  columns, placeholders); `tests/expected/PROVENANCE.md` and its evidence
  classes; the fingerprint/registry dispatch with the dual key; the
  header-defaults and build-ref-rot locks; the must-fire-control convention
  and `tests/lib/shadow_tools.sh`; the generated gate index and gotcha index
  with their `--check` modes; the replay format and the write-tap /
  frame-dump instruments. The extraction question for every piece is the
  same one the docs use, asked of the HARNESS: "would this still be true if
  the thing under test were not this ROM, not CPS-2, not even a game?" —
  what survives is the generic harness (a separate repository or a
  top-level directory with no dependency on `build/manifest` or the atlas),
  what does not stays here. Deliverable order, in the maintainer's words:
  the harness FIRST, the skill AFTER (a skill distils something that
  exists). Not to be confused with a rewrite of this project's harness,
  which stays as it is. Cost: T3, several sessions; the skill one more.

- **~~PHOBOS'S THREE THROWS — historically problematic, never compared to VS2
  on geometry~~ MEASURED 14z-131 AND THEY MATCH. Maintainer-directed the same
  day; no defect found.** The ask: *"there are throws that have been
  historically problematic with the VS2 tenants as THROWERS, not victims,
  namely Phobos' throws... these have all had their share of corrections,
  especially circuit scrapper and ES circuit scrapper, and even now I am not
  100% sure they are identical both mechanically and visually to their VS2
  versions... these throws involve mostly POSITION of the victim."*
  **RESULT, ours (merged-m15) vs NATIVE vsav2, victim pinned to Victor:**

  **STRENGTHENED the same session after the maintainer's critique** — *"we
  have but 5 frames for moves that last many tens of frames... it might be a
  sample bias"* — from a comparison of SETS (blind to order and dwell) to the
  ORDERED sequence of `(pose, dx, dy)` states with dwell, over EVERY held
  frame, plus damage as `(amount, pose)`:

  | throw | ordered states | damage (amt @ pose) | arc peak |
  |---|---|---|---|
  | standard 6+HP | 29 vs 28, ours +1 tail | 14 @ 13 both | 64 == 64 |
  | circuit scrapper | **23 vs 23, IDENTICAL** | 19 @ 19 both | 278 == 278 |
  | ES circuit scrapper | 46 vs 47, native +1 tail | 2@21 2@21 15@19 both | 380 == 380 |

  **The trajectories traverse the SAME STATES IN THE SAME ORDER, and every
  damage event lands for the same amount at the same POSE.** The only
  structural differences are ONE end-of-hold state, in OPPOSITE directions.
  **AND THE CADENCE WAS MEASURED INDEPENDENTLY, three times, which is what
  turns "consistent with #114" into evidence:** the hold runs +8.5% / +9.1% /
  +8.3% longer than native across the three throws, against #114's documented
  ~1 video frame per ~11 engine ticks = 9.1% — Circuit Scrapper lands exactly
  on it. On ES the damage offsets GROW through the move (+5, +7, +10 frames),
  the signature of a RATE difference rather than a port defect. Dwell and
  frame numbers are therefore REPORTED by the gate and never gated.
  **DELIBERATELY NOT COMPARED: the victim's PIXELS.** Victor in our build is
  VS's Victor; in native vsav2 he is VS2's Victor — different generations of
  his art. A pixel difference in the victim is a cross-game fact, not evidence
  about our port (the maintainer's own second point). The pose INDEX resolves
  through each game's own `anim_index_c`, so a match means the same LOGICAL
  pose slot, which is the comparable thing.
  **A STALE CLAIM REFUTED ON THE WAY:** `80_hui_grab_2p.rpl`'s header said
  *"only the victim throw-arc HEIGHT differs (alias physics, queued)"*. It
  does not — the arcs are identical on all three throws. The claim predates
  the 14z-67 `throw_arc_tables` fix and was never retracted; it is now.
  **AND A RIG TRAP WORTH THE SESSION ON ITS OWN:** the ES version needs
  METER. With an empty stock the ES input degrades SILENTLY to the ordinary
  MP grab and returns numbers byte-identical to replay 80 — same 16 offsets,
  same poses, same 19 damage. The discriminator is P1's stock dropping 9 -> 8
  at the grab frame, which replay 80 under the same poke never does
  ([VSP-131], [VSP-123]). Documented in the new replay's header and asserted
  by the gate.
  **WIDENED TO ALL 18 ROSTER VICTIMS (maintainer asked the cost; it was
  measured, not argued): Victor alone 27.7 s, all eighteen 186 s at 6-way
  parallelism** — ~6.7x the time for 18x the coverage, so it was widened.
  **RESULT: 18/18 victims traverse the SAME states in the SAME order on all
  three throws**, the end-of-hold tail is UNIFORM across every victim (so it
  is frozen as ONE shape per throw, not 54 literals — and the uniformity is
  itself evidence it is a boundary effect rather than per-character data), and
  the ours/native hold ratio has ZERO spread across victims (1.085 / 1.091 /
  1.083), which is what an ENGINE rate looks like rather than a data defect.
  **WIDENING PAID FOR ITSELF TWICE, and both are the argument for doing it:**
  * it found a residue the narrow gate could not see — **5 of 54 victim/throw
    cells differ by exactly ±1 TOTAL damage**, sign per VICTIM not per throw:
    `0x10` +1 on all three throws, `0x13` −1 on all three, `0x0A` −1 on CS
    only. **RULED (maintainer, 2026-09-04): WITHIN TOLERANCE, NOT A DEFECT —
    *"+/- 1 damage is within tolerances. It is interesting to root-cause it to
    deepen our understanding of the engines though so let's keep that open for
    a future session."* So it is a KNOWLEDGE item, not a bug**: frozen with
    its exact deltas so it cannot drift unnoticed, and carried open for a
    future session to explain rather than to fix.
    **WHAT IS ALREADY ELIMINATED, so nobody re-derives it:** victim starting
    HP is 288 on BOTH legs for every victim (not a max-HP effect); it is TOTAL
    damage over the window, not a per-event split artifact; `bank_map`
    declares no per-character defence/damage-scaling table, so the scalar is
    somewhere that map does not model; and the sign is stable per victim
    across all three throws, so it is not throw-specific.
    **THE DISCRIMINATOR THAT MATTERS, and it is a HYPOTHESIS ([VSP-116]) not a
    finding: `0x0A` IS A LEGACY VICTIM.** Sasquatch is not ported — on our leg
    he is VS's Sasquatch, on the native leg VS2's. If Capcom retuned him
    between the games, that cell is a CROSS-GENERATION data difference and
    nothing to do with our port, which would split the residue into two
    unrelated causes (0x0A cross-generation; `0x10`/`0x13` something else).
    Testing that is the cheap first step: compare the two games' per-character
    damage/defence data for `0x0A` directly.
    **THE NAMED NEXT MEASUREMENT:** PC-attribute the writes to the victim's HP
    (`$FF8850`) on both legs with `tests/lua/tap_writes.lua`'s `REGLOG` — the
    same instrument that resolved #112's `a0` — so the routine AND its
    operands are named rather than inferred. That says which table the scalar
    **-> DONE 14z-145, by a READ watch on the table instead: it is the defense curve row (`defense_rows.md`), `tests/audit_defense_row_residue.sh`; the `0x0A` hypothesis above CONFIRMED (a cross-generation retune).**
    lives in.
  * it exposed a frozen constant as victim-specific: the narrow gate froze the
    post-release arc peak at `278`/`380`, which were VICTOR's numbers — the arc
    is victim-dependent and spans ELEVEN values. Not wrong for Victor; wrong
    about what it was freezing, and only a second victim could show it.
  **AND ONE FALSE ALARM WORTH RECORDING:** the first widened run reported all
  three TENANT victims diverging, with unresolved pose pointers. That was the
  RESOLVER — a tenant victim on our leg is held on the PLACED copy of vs2's
  table, not vsavj's, a rule `audit_don_grab_pose` already documents. Applied,
  the unresolved count went to zero and every tenant matched.
  **THE METHOD IS NOW A DOCUMENT** at the maintainer's request (*"I want what
  we went through together documented because it's a typical example of how to
  close gaps on tests, strengthen gates, guarantee that tests are properly
  scoped"*): `docs/project/gate_scoping_method.md`, distilled into the port
  skill as [VSP-167]..[VSP-174].
  Gate: `tests/audit_tenant_throw_geometry.sh`; new replay
  `tests/replays/hui/97_hui_grab_es_2p.rpl` (replay 80 with one token
  changed, so a difference between them is the ES button and nothing else).

- **~~PYRON'S CAPTURE-KEYFRAME ATTACKER ROW `0x11` IS NOT PORTED~~ PORTED
  14z-143 (option (a)), AND CONFIRMED THREE WAYS — the entry stays for the
  measurement trail.** The maintainer took this item at the 14z-143 opener
  from the open-items list. **RESULT: `pyron.toml`'s `[[data_port]]
  pyron_capture_keyframes` places vs2's own block (`0x0C7F98`, `len 0xB80`)
  in `wide_ext` and repoints row `0x11` at `PRG:0x0BE2BE` — ONE word, +2 ops,
  Pyron only.** Confirmed by (1) the shipped image, where the placed block is
  byte-identical to vs2's and the repoint inventory is exactly the frozen set;
  (2) `audit_pyron_capture_block.sh` in-emulator against native `vsav2` —
  hold-offset overlap **9 of union 9**, where 14z-131 measured **0 of 15**,
  legacy control 6/6, `EXPECT_MATCH` default flipped 0 -> 1; and (3) the
  maintainer, on a before/after/native capture sheet at six matched keyframes
  (2026-09-08): *"After and Native look identical or at least consistent,
  whereas before was inconsistent with native"*. Byte detail: patch_notes
  14z-143. Builds `build/pyron39` (`65bf5622`) / `build/m3b_merged24`
  (`4a7c02fb`) — NOT yet frozen.
  *(Original entry follows, unrewritten.)*
  **DECIDED (maintainer, 2026-09-04): MEASURE FIRST — *"Agreed, that's where
  to start."* **MEASURED 14z-131, AND IT IS A REAL, GROSSLY VISIBLE DEFECT ON
  A 2P SURFACE — NOT A COSMETIC.** The port decision is now the maintainer's;
  the measurement it was waiting on is done.
  **MEASURED TWO INDEPENDENT WAYS THAT SHARE NO PREMISE, and they agree:**
  * **STATIC, from the reference ROMs.** vs2's Pyron block `0x0C7F98` vs the
    Demitri block `0x0A3D88` our build serves him: for victim Victor the
    keyframe deltas are `(-79,0) (-97,0) (-65,0) (82,29) (58,124) (100,132)
    (116,-4)` against Demitri's `(-63,0) (-63,0) (-63,0) (-26,0) (-26,0)
    (-10,32) (5,32)`. One of eight agrees, and it is the all-zero kf0.
  * **IN-EMULATOR**, P1 Pyron vs P2 Victor on `judge/02_throw.rpl`, hold
    frames 3010-3039, ours (vsavjw merged) vs native vsav2:
    ours `{(63,0)(26,0)(10,32)(-5,32)(-10,32)(5,32)}`, native
    `{(79,0)(97,0)(65,0)(-82,29)(-58,124)(-100,132)(-116,-4)(-53,116)(12,39)}`
    — **ZERO overlap.** The in-emulator numbers reproduce the static deltas
    exactly, dx sign-flipped by the positioner's own facing `neg.w d0`.
  **WHAT IT LOOKS LIKE — AND A CORRECTION TO MY OWN FIRST DESCRIPTION.**
  ~~"native hurls the victim ~130 px overhead and drops them BEHIND Pyron;
  ours holds them on the ground in front"~~ **RETRACTED 14z-131, the same
  session, after the maintainer required CAPTURES before accepting the
  finding — and they were right to.** That sentence read the raw `dy` sign as
  "up" and the `dx` sign as "behind" without ever establishing the engine's
  screen-coordinate convention for `+0x14`; it was an interpretation of two
  numbers, not an observation.
  **WHAT THE CAPTURES ACTUALLY SHOW** (PNG snapshots, ours vs native vsav2,
  frames 3012/3018/3024/3030/3036 of the same rig): the victim is held in a
  DIFFERENT PLACE and reads at a DIFFERENT ORIENTATION — ours holds Victor
  low and horizontal beside Pyron's flame; native holds him upright and
  higher through the same frames. The difference is unmistakable on screen.
  What is NOT established is any specific "N pixels up / behind" claim.
  **THE LEGACY CONTROL IS IN THE SAME CAPTURE SET AND IS VISUALLY IDENTICAL
  between the two legs** (Demitri throwing Victor, same frames), which is what
  makes the Pyron sheet readable rather than a comparison of two different
  games' art. Throws are core 2P, so the standing "cosmetic is optional"
  scope does NOT cover this.
  **STANDING LESSON, and it is [VSP-153]/[VSP-116] again:** the numbers were
  right and the sentence about them was not. Send the capture before writing
  the characterisation, not after.
  **THE RIG IS SOUND, and that is measured too:** the gate's section 0 runs a
  LEGACY attacker (Demitri) on both legs and gets 6 distinct offsets each with
  overlap 6 of 6 — identical. So the pokes, the frame window, the coordinate
  convention and the comparison all work, and the Pyron disjointness is a fact
  about the data, not the instrument ([VSP-22]).
  **GATE: `tests/audit_pyron_capture_block.sh`** (mame / release / romset),
  `EXPECT_MATCH=0` freezing the OPEN defect, flipping to `1` when the row is
  ported — the same shape `audit_don_grab_pose` used across the #104 fix, so
  the gate proves the fix rather than being rewritten to suit it.
  **THE FIX, if wanted, is the 18th instance of a mechanism used 17 times:**
  a `[[data_port]]` row in `pyron.toml` — `src = 0x0C7F98`, `orc = 0x0C782A`
  (the uniform `0x76E` sibling delta), `slot_ptr_table = 0xBE27A`,
  `hole = "wide_ext"`, `only_variant_slot = true`, with `dst`/`dst_old_head`
  naming the host block it replaces on the base track. ~~Two things to settle
  first, both cheap: the block's LENGTH (its sub-block stride is `0xA0`, 32
  victims, so ~`0x2040`...), and the signed-16-bit `lea (a0,d0.w)` bound~~
  **BOTH SETTLED 14z-142, and the length estimate was WRONG.** A block is a
  32-word victim OFFSET TABLE then 8-byte records `[dx][dy][flags][pose]`; the
  victim offsets ALIAS, so vs2's Pyron block has 32 entries but **18 distinct**
  sub-blocks spaced `0xA0`, last at `+0x0AE0`. **Extent = `0xB80` (2,944 B),
  not ~`0x2040`** — *(CORRECTED 14z-143: this said "zeros follow it";
  measured, a DIFFERENT table begins at `+0xB80`. The extent is unchanged and
  now rests on the tiling `0x40 + 18*0xA0 = 0xB80`, not on a tail of zeros.)* And the `lea (a0,d0.w)` displacement is an
  offset WITHIN the block (measured max `0xB78`), so relocation cannot move it
  and the signed-word bound has enormous margin. Mechanism + structure:
  `engine_internals.md` "THE CAPTURE-POSE INSTALLER". One freeze.
  **STOP — THE MECHANISM IS NOT ESTABLISHED, AND THE PORT IS NOT YET THE
  RECOMMENDATION (corrected 14z-131 after the maintainer challenged the
  test's premise).** What is solid: Pyron's row 0x11 IS unported (static, from
  the manifests and the ROM), and ours-vs-native with attacker AND victim both
  held fixed differs while the Demitri control is identical. What is NOT
  solid is that the capture block CAUSES what is on screen:
  * **The victim's POSE RECORD also differs**, and the positioner cannot do
    that — it writes only `+0x10/+0x14`. Measured, victim pose-record indices
    through the hold: Demitri control ours `[6,5,2,14,23,13]` == native
    `[6,5,2,14,23,13]`; **Pyron ours `[6,5,2]` vs native
    `[2,1,0,3,11,10,29]`**. ~~So a second mechanism is in play and it may be
    the dominant visible effect.~~ **RETRACTED 14z-142, on byte-exact static
    evidence: there is ONE mechanism.** The capture positioner at
    `PRG:0x028072` is a single straight-line stream out of one `A0` — it
    writes the victim's POSITION, then reads the FACING from `(a0)+`, then
    `move.w (a0),d0` (the POSE INDEX) and `bra.w $27fa0` into the installer.
    So the same keyframe stream supplies position, facing and pose; an
    attacker whose capture-keyframe block is wrong produces all three wrong
    at once. The positioner does not write `$1c(a4)` itself — it chooses what
    the installer writes there, one instruction before branching into it.
    `docs/game/engine_internals.md` "THE CAPTURE-POSE INSTALLER".
  * **The obvious big hypothesis is REFUTED**: our Pyron is NOT running
    Demitri's throw. His attacker records are his own — 12 distinct, span
    `0x288`, against native's 12 distinct, span `0x288` (relocated, same
    structure); Demitri's throw walks 8 records, span `0x2D8`.
  **~~THE NEXT MEASUREMENT~~ ANSWERED 14z-142, and the answer was already in
  the tree — [VSP-155] applied to myself, late.** The question was whether our
  Pyron requests different pose ids or the same ids through a different
  SIBLING TABLE. **It cannot be the sibling table:** `engine_internals.md`
  measured at 14z-98/99 that **`PRG:0x27FAA` is never executed** — 0 probe
  hits against 904 at `PRG:0x27FA0`, the live entry, which HARDCODES
  `moveq #$0,d1 ; movea.l #$bcffa,a0` (always `anim_index_c`). A 14z-142
  probe independently reproduced the zero on both `vsavj` and `vsav2`'s twin
  `0x271FE`. So there is one sibling in play, always, and `d0` is the only
  free variable — and `d0` comes from the attacker's own keyframe stream (the
  retraction above). **Row 0x11 is therefore the whole story, not a part of
  it.**
  **THE PORT RECOMMENDATION IS REINSTATED** on that ground: the `[[data_port]]`
  row described above, one freeze. What is still owed is the IN-EMULATOR
  confirmation, and the honest reason it is not here: a probe A/B at
  `0x27FA0` across the two builds does not produce comparable legs — the
  native leg fired 38 times in the hold but took an `INPUT-VIOLATION` at frame
  3015 (debugger stops delay input application) and the ours leg produced no
  hits at all. That is [VSP-129] as documented. The confirming measurement
  needs a probe-free instrument — the gate's own `DUMPS` rig extended to read
  the victim's `+0x1C` node pointer, not a breakpoint.
  **A LEAD RECORDED, NOT A DEFECT:** two per-character pose-id LUTs
  (`PRG:0x373CA`, `PRG:0x3A5EA`; vs2 `0x37842`, `0x3AD6A`) are indexed by the
  VICTIM's id and vsavj ALIASES their variant halves where vs2 does not
  (Pyron-as-victim: vsavj `0x2D` vs vs2 `0x32`). Neither is named by any
  manifest, doc or gate. **But both are reached only through the dead
  `0x27FAA` entry**, so they are off the live path and are a curiosity until
  something is shown to reach them.
  **NO PORT RECOMMENDATION UNTIL THAT IS ANSWERED** — porting row 0x11 on the
  strength of a position measurement, while an unexplained pose difference
  sits beside it, would be fixing the half I happened to measure. Original
  entry — a throw/capture surface, so [VSP-10] (found 14z-130 while folding in the
  `gap_be27a` correction; NOT a regression, this is the state as shipped since
  the #104 work).** The capture-pose installer resolves the ATTACKER's keyframe
  block through `PRG:0x0BE27A[attacker id]`. Every legacy attacker row
  (`0x00-0x0F`, `0x0B`, `0x18`) is ported, and so are Donovan's `0x13`
  (`throw_victim_keyframes`) and Huitzil's `0x10` (`grab_hold_keyframes`).
  **Pyron's `0x11` is not**: vsavj aliases it to `0x00094954` = DEMITRI's
  block, so when PYRON throws, the capture poses are Demitri's. donovan.toml's
  own comment records it as "the recorded Pyron-as-attacker observation".
  **HOW IT SURFACED:** correcting the bank-map row made the generic
  per-character repoint want to write `0x0BE2BE <- 0x004af226`, i.e. to point
  the row at Pyron's own vs2 block (`vs2 0x000C7F98`, inside his extracted
  `hitbox` region). That write is SUPPRESSED in the shipped build — the table
  is hand-owned and the freeze had to be byte-neutral — but it is exactly the
  fix, and the generator would have made it silently.
  **WHAT IS AND IS NOT KNOWN.** Known: the source block exists in vs2 and
  vhunt2 with the uniform `0x76E` sibling delta, it lies inside a region the
  build already extracts and places, and the mechanism to repoint the row is
  the same `slot_ptr_table` one the other 17 rows use. NOT known: whether
  Pyron's throws actually LOOK wrong with Demitri's capture poses — nobody has
  compared them, and the #104 report named Donovan and Phobos precisely
  because Pyron's fold was not noticed. So this is a defect by construction,
  not by observation.
  **OPTIONS:** (a) port it, as a `capture_kf_pyron`-style row with an `orc`
  oracle and a `dst_old_head` — mechanically identical to the fifteen legacy
  rows, one freeze; (b) leave it, and record that Pyron borrows Demitri's
  capture poses as accepted. **RECOMMENDATION: measure before deciding** —
  a hand-played or scripted Pyron throw beside a native vs2 Pyron throw
  ([VSP-123] makes the native leg reachable with an ordinary poke), which
  turns "a row is unported" into "here is what it looks like". Half a session,
  and it is the cheap half of (a).
  **-> (a) EXECUTED 14z-143.** The measurement recommended here was done at
  14z-131/142; the port itself cost one manifest row, two rebuilds and three
  gate moves (`test_tenant_loop` op counts, `test_capture_kf_ownership`
  frozen sets, `audit_pyron_capture_block` EXPECT_MATCH).

*(Cleaned 14z-109, maintainer-directed, and again 14z-134: resolved and
no-longer-shaping entries moved VERBATIM to `DECISIONS_HISTORY.md` — grep there by topic.
Lifecycle: rulings are still marked DECIDED in place here first; they move to
the archive once they stop shaping active work.)*


## Rulings from the pre-pending "Decision(s) made" sections (2026-07-31 .. 2026-08-06)



## Decisions made (maintainer, 2026-08-05): two ratifications

**1. CLAUDE.md §4 comparison class v3 — "bounded re-convergent window".**
Ratified for the select screen, which the roster deliberately alters. A
replay qualifies only when all four hold, frozen per replay: a single
CONTIGUOUS run, a fixed ONSET frame, full RE-CONVERGENCE, and match state
UNTOUCHED. Measured over five replays before the ruling (onset 890 in every
one, one run each, 2469-10498 identical frames afterwards including a full
timeout match). It is STRICTER than the frozen first-divergence constant it
sits beside, which never re-converges at all — a narrower licence for one
screen, not a loosening. §4 amended; checker `tools/compare_window.py`,
ground-truthed both directions by `tests/test_compare_window.sh` including
that a bit-identical pair is NOT a silent pass (the expectation asserts the
divergence exists).

**2. The `[[tenant]]` schema.** Ratified, and already implemented for a
single tenant (14z-60t/u) byte-identically on both tracks with the tenant
still at `0x0F`. `docs/project/tenant_manifest.md` moves PROPOSAL -> RATIFIED; its
wheel/ladder/folds sub-tables stay proposal-only because that work is not
done.

Maintainer: "I validate the two items, I don't need testing to see that they
hold on principle." The measurements above were taken before the ruling
regardless — the class's four clauses are what was measured, not what was
hoped for.

## Decision made (maintainer, 2026-08-05): new cells SNAP to vsav's lattice

"It feels safer to conform to arcade vsav and snap to it. As long as the UX
is good enough, I don't even mind if the look is not great." So the three
appended cells take positions derived from vsav's own hexagon rather than
PS1's pixel coordinates.

Derived layout (`build/manifest/wheel_layout_proposed.json`): vsav's wheel
is a clean hexagon, rows 1-2-3-4-3-2-1 at y=64..144 every 16, then a single
centre-line cell at y=152 (+8). Mirroring that bottom signature downward:

| cell | id | position |
|---|---|---|
| random (unchanged) | `0x0B` | (248, 152) |
| Huitzil/Phobos | `0x10` | (224, 168) |
| Donovan | `0x13` | (272, 168) |
| Pyron | `0x11` | (248, 176) |

This is geometrically IDENTICAL to the PS1 port's shape (pair, then single
on the centre line); only the id assignment differs, per the maintainer's
amendment — random keeps its vsav cell and Pyron goes to the very bottom.
28 bytes of TABLE B change. Adjacency is still a geometric DRAFT pending
the cursor-movement video.

## Decision made (maintainer, 2026-08-05): 0x360+id anim block = INHERIT

Option A: the newcomers inherit their base character's animation from the
shared 16-wide block `0x360-0x36F` (a tenant at `0x13` plays `0x363`),
exactly as vsav2 ships — Capcom left both those folds in place. Sites
`PRG:0x003E40` / `PRG:0x004082` therefore stay folded, recorded as
`inherit` in `docs/project/tenant_manifest.md`. **Fallback, if a playtest shows the
inherited animation is wrong for a newcomer: option B**, relocate the block
to a free 32-wide anim-number range and widen both masks.

## Decision made (maintainer, 2026-08-04): M5 voice samples = A then B

"A then B, gates stay strict, option C is rejected." Ship the unfaithful
voice lines silent now; revisit growing the QSound region at M3 within the
measured 16 MB `device_rom_interface<24>` ceiling; never overwrite vsav
content for sample room. Recorded in full under "Decisions pending" above,
where the option analysis lives.

## Decision made (maintainer, 2026-07-31): electrocute arc colors

Keep vsavj-native shock styling for all victims including Donovan
(option A of the 14z-20 write-up): the arcs/glow are engine-global and
victim-independent; vs2's yellow was a game-wide re-theme, not per-char
data. "Less work, less risk, and we can always come back to it after
all the more important work." LOCKED in tests/test_don_accent.sh
section 3 (shock-window vanilla lock, frozen from a vanilla run) —
revisiting requires changing that gate deliberately.

## Decision made (maintainer, 2026-08-02, round 65): M2b+ASSETS freeze

Freeze `b91647c7` as `donovan-m2c` before starting M5 sounds —
"mechanically sound as far as we can tell" (rounds 52-64 playtest
arc + full battery + suite). Frozen basis: three masked windows.

## Decision made (maintainer, 2026-08-02, round 64): third mask window

`RAM:$FF4182-$FF41A1` (palette-fade staging slot for select block-A
row 14) RATIFIED into the masked legacy basis — option A of the
14z-49b write-up, after the recolor-necessity A/B (14z-49d) showed
options B and C strictly worse. Condition attached and honored:
detailed documentation + a standing confirmation path
(`tests/audit_mask_window_ff4182.sh`; spec in docs/game/atlas/ram.md).
Extension policy stands: future palette-block ports extend the
window per measured slot, never pre-widen.

## Decision made (maintainer, 2026-08-06): select art = option A

Option A of the 14z-62e write-up: the per-hover bank thunk for the
portrait-record object + the tenant's select art in WIDE group C at
native codes; `vsav.zip` leaves the rompath entirely pristine [**14z-105:
not quite — the later effect-tail pass writes four GROUP-A members
(vm3.13m/15m/17m/19m); measured by the release packager**]. Blank-pool
relocation (option B) remains the fallback if the measured hook cost
violates the standing flicker watch. Maintainer also flagged suspected
graphical corruption in the session captures — playtest of `39597268`
in progress; the expected-interim inventory is in
docs/project/playtest_m3a_interims.md so the report can classify against it.
Original write-up kept below.

---

## Entries moved from "Decisions pending" (each was ruled/superseded in place before moving)

- **~~THE FIELD TEST~~ SCHEDULED (maintainer, 2026-08-25): "tonight unless
  I struggle building".** Bundle assembled and verified OUTSIDE the repo at
  `../mister_fieldtest_14z108/` — the WIDE MRA, `vsavjw.zip`, the PATCHED
  `vsav.zip`, `qsound.zip`, and a README. **All 31 CRC-identified parts the
  MRA declares were verified to resolve from those three zips**, because an
  unresolved part is filled with `0xFF` rather than refused. The `.rbf` is
  NOT in the bundle — it comes from the Windows box and its sha256 must be
  checked first, since a timing-FAILING seed emits a bitstream
  indistinguishable from a good one.

- ~~**MiSTer SOURCE SEPARATION — how far does "unmixed" reach? (14z-107 (8))**~~
  **DECIDED (maintainer, 2026-08-23): the CORE stays unmixed; SHARED
  `tools/` and `tests/` STAY AS THEY ARE** — *"shared /tools and /tests are
  a bit messy but acceptable, especially since it's not 100% risk-free."*
  The standing rule the maintainer set: the MiSTer core must not be MIXED
  with the other sources — same repo is fine, same subfolder is not.
  **Already satisfied, and asserted rather than claimed:** our RTL lives in
  `cores/cps2w/hdl` while `cores/cps1`, `cores/cps2` and `cores/cps15` are
  BYTE-UNTOUCHED (`tests/test_jtcores_twin.sh` check 2e is a `git diff`
  assertion, added in D1 — the slice that first added RTL); in this tree
  `emu/fbneo`, `emu/mame` and `emu/jtcores` are separate submodules with
  their patch mirrors in parallel `emu/*-patches/` dirs.
  **NOT to be "tidied" later:** the MiSTer tools (`run_sim_jtcps2.sh`,
  `setup_jtcores.sh`, `mister_mra.sh`, `gen_vsavjw_xml.py`,
  `rpl2siminputs.py`, `check_wram_dumps.py`) and gates (`test_mister_*`,
  `test_jtcores_twin`, `audit_sdram_bank_load`, `test_sim_wram_contract`)
  STAY in the shared `tools/` and `tests/`. A move would touch
  `tests/ci_portable.txt`, `tests/ci_static.txt`, `run_all_static.sh`'s
  orphan check and every doc path naming them — i.e. it risks the
  "checks that stopped checking" class (14z-95, four instances) for zero
  functional gain. Ruled acceptable-as-is; do not re-open it as housekeeping.

- **MiSTer PACKAGING — two questions slice D0 surfaced (14z-107 (5), NEW).**
  Neither blocks D1-D4; both must be answered before a release.
  1. **Which MRA is the core's MAIN one?** `jtframe mra cps2w` puts the Euro
     `vsav` parent at `release/mra/` and everything else — including the
     WIDE set — under `_alternatives/`. For a core whose whole purpose is
     the WIDE set that is backwards. *Recommendation: make the WIDE MRA the
     main one and keep the stock `vsavj` reference leg in `_alternatives/`;*
     it is a `[parse] main_setnames` change in the fork's toml, and it moves
     nothing in the images.
  2. **How does a release carry BOTH `vsav.zip` flavours?** The WIDE romset
     is a CLONE set whose parent is the BUILD's `vsav.zip` (the merged build
     patches `vm3.13m/15m/17m/19m`), while the stock reference-leg MRA needs
     the PRISTINE dump — and both MRAs name the parent zip `vsav.zip`. On
     FBNeo/MAME `run_wide.sh` resolves this by OVERLAYING a rompath, a
     runtime notion MiSTer's MRA does not have. *Options: (a) ship only the
     WIDE MRA and drop the reference leg from the MiSTer package (it lives
     on in the sim gate either way); (b) rename the WIDE parent to a
     distinct set (`vsavw.zip`) via `[parse] parents`, which costs a
     zip-name divergence from the FBNeo/MAME package; (c) make the WIDE
     romset self-contained by carrying its own copies of the eight GFX and
     two QSound parent members — +40 MB of zip, and it stops being a clone
     set. Recommendation: (b), which keeps one romset directory able to feed
     all three emulators. NOT decided; it is a distribution-shape call.*

- ~~**THE BANK-0 SLOT COUNT — a fork-surface call (14z-107 (4), NEW).**~~
  **DECIDED (maintainer, 2026-08-23): option (A), add `jtframe_ram1_7slots.v`
  to the fork.** SDRAM bank 1 stays at exactly the two streams
  (PCM + group-C obj bank 4) that `tests/audit_sdram_bank_load.sh` modelled
  when it returned GO, so the measurement keeps covering the shipped design.
  **AND THE RELATED QUESTION IS RULED TOO — the profile is selected at
  RUNTIME from a spare MRA header bit, NOT by `ifdef`** (maintainer,
  2026-08-23). Consequence, and the reason it matters: stock `vsavj` on our
  own RBF then runs with the wide decode CLEAR, so Rule 1 v2's "profile-gated
  ... so stock `vsavj` is untouched BY CONSTRUCTION" holds on FPGA as a FACT
  rather than as an inertness argument, and the reference-leg MRA becomes a
  real stock leg. It also mirrors the FBNeo shape (a flag set from the driver
  entry). Every gated site takes a `wide_en` wire off that header bit — D1's
  QSound latch is the first.
  **IMPLEMENTED 14z-107 (6): the bit is MRA header byte 41, bit 0, ACTIVE
  LOW** (`0xFF` — the generator's own `[header] fill` — means profile OFF;
  the WIDE MRA writes `0xFE`). The polarity is forced, not chosen: any other
  would change every stock MRA this core emits. RTL
  `cores/cps2w/hdl/jtcps2w_profile.v`; measured end to end in
  `tests/test_mister_mra_map.sh` and exhaustively simulated with three
  must-fire controls in `tests/test_mister_wide_gate.sh`. **Option (A),
  `jtframe_ram1_7slots.v`, is NOT yet written — it is D2's need, not D1's,
  and D1 confirmed it: D1 changes no placement and adds no slot.**
  Original entry:
  **THE BANK-0 SLOT COUNT — a fork-surface call (14z-107 (4), NEW).** The
  placement map (`docs/project/mister_map.md` §5) puts seven consumers in
  SDRAM bank 0 (RAM/VRAM/ORAM, VRAM-DMA, gfx-ORAM, main ROM, Z80, the QSound
  high window, group-C obj bank 5) and upstream's family stops at
  `jtframe_ram1_5slots` (`ram2_4..6slots` are the only 6-slot variants and
  they carry two write ports).
  - **(A) add `jtframe_ram1_7slots.v` to the fork** — a mechanical member of
    an existing formulaic family. Keeps SDRAM bank 1 to exactly the two
    streams (PCM + obj) that `tests/audit_sdram_bank_load.sh` modelled when
    it returned GO.
  - **(B) move the Z80 program to bank 1** — bank 0 drops to six slots
    (`jtframe_ram2_6slots`, second write port tied off) and bank 1 becomes
    `jtframe_rom_3slots`. Zero new jtframe files, but bank 1 then carries
    THREE streams, which is beyond what was measured, and bank 1 lands at
    15.95 of 16 MB.
  - **Recommendation: (A).** The GO verdict is a statement about a two-stream
    bank 1; option (B) spends that evidence to save one boilerplate file.
  Related and unresolved either way: **should the profile be selected at
  RUNTIME from a spare header byte** (`jtcps1_prom_we.v:52-54` — "6 are
  actually used and 10 are reserved") rather than by `ifdef` in `cps2w`? A
  compile-time gate means stock `vsavj` on our RBF gets the widened PRG
  decode and the 3-bit obj bank; both are provably inert for stock content
  (`cps2_wide.md` A1/A2), but a header bit would restore
  gating-by-construction and make the MRA the profile selector.

- ~~**THE MiSTer MEMORY-MAP ROUTE (14z-107 (2)) — NEW, and it is the arc's
  next fork in the road.**~~ **DECIDED (maintainer, 2026-08-23): option (2),
  the BANK REPACK, measuring first; XL is the FALLBACK** — the ruling was
  *"attempt repack (measuring first)"*, with `JTFRAME_SDRAM_XL` (two chips,
  128 MB) kept in reserve if the repack fails. Vanilla's 32 MB of GFX stays
  exactly where it is in banks 2+3 and the ~6.4 MB of tenant art goes into
  bank 1 alongside the QSound PCM, reached by the profile-gated promoted
  tile-code bit. **The measurement the ruling required was taken the same
  day and says GO** — bank 1's PCM is already at a 98.8% row-miss rate so it
  has no locality to lose, and the worst case runs at 26.3% of a single
  bank against the 32.9% bank 0 already sustains
  (`tests/audit_sdram_bank_load.sh`, `build/sdram_bank_load_14z107.log`,
  verdict in STATE 14z-107 (3)). It bounds the headroom; it does not prove
  the repacked design. Original text kept below.

  **THE MiSTer MEMORY-MAP ROUTE (14z-107 (2)) — the arc's next fork in the
  road.** The profile ruling (WIDE v1 verbatim, one romset)
  is NOT in question here; only HOW the bytes reach the FPGA. The facts that
  opened it (all measured 14z-107, `docs/platform/mister.md`): at our pin
  `v1.7.3` **64 MB is PHYSICAL**, not a default — jtframe's own table stops
  at `AW 23 = 64 MB`, the bank geometry `COW = AW==22 ? 9 : 10` has no AW=24
  arm (an AW=24 build never drives `addr[9]`, aliasing every address with
  `addr ^ 0x200`), and `sys.tcl` assigns exactly 13 A pins, 2 BA and one nCS.
  The `JTFRAME_SDRAM_XL` 128 MB tier IS real, but UPSTREAM only (added
  2026-06-19, `5981db26`), implemented as **two chips on one module selected
  by the top address bit with chip select on nCS POLARITY**, and reachable
  only inside the `JTFRAME_SDRAM_CACHE` branch. Meanwhile the fit numbers
  (`docs/project/mister_fit.md` §6) say the roster's **total is ~56.1 MB
  against a 64 MB tier** — PRG 6 MB fits bank 0 today, QSound 16 MB fits
  bank 1 today, and only GFX overflows, by ~6.4 MB. The question is
  placement, not capacity.

  **(1) UPREV to upstream master + `JTFRAME_SDRAM_XL` + convert CPS-2 to
  `cfg/mem.yaml` cache lanes.** The architecturally "correct" long-term path:
  the tier is real, CPS-3 already ships on it at ~80 MB, and it leaves room
  for anything later. Cost: a **3057-commit** jump to an **UNTAGGED moving
  target** (v1.7.3, 2024-01-18, is the newest version tag and predates XL by
  ~2.4 years); re-basing our two fork commits; rewriting the whole simulation
  recipe (`test.cpp` -> `verilator/test.cpp` split, `bin/jtsim` rewritten,
  `game.yaml` -> `files.yaml`, `-inputs` now a `.cab` script so
  `sim_inputs.hex` and `tools/rpl2siminputs.py` are orphaned, input bit 1
  coin2 -> service); converting CPS-2 to `mem.yaml`; and **widening the
  shared CPS-1/2 `jtcps1_sdram.v` `[22:0]` code that upstream never widened**
  (its `// change this when moving to 8MB+ GFX` comment is still there on
  master). Requires the 128 MB module.

  **(2) STAY at the `v1.7.3` pin and fit inside 64 MB by BANK REPACK.**
  Vanilla's 32 MB of GFX stays exactly where it is in banks 2+3, so the
  superset invariant is untouched by construction, and the ~6.4 MB of tenant
  art goes into **bank 1, above the PCM** — which after a 16 MB-capable
  QSound carrying 8.9 MB of real content has **~7.1 MB spare** — reached by
  the promoted tile-code bit,
  [**CORRECTED 14z-107 (4): "~6.4 MB into bank 1" is wrong — that is the
  LIVE-BYTE count. The ADDRESS FOOTPRINT is 15.45 MB and needs BOTH banks'
  spare; see `docs/project/mister_map.md` §1.**] i.e. the RTL expression of the profile-gated
  19-bit promote WIDE v1 already makes on FBNeo. No framework uprev, no
  second chip, no `mem.yaml` conversion, and it would run on a 64 MB module
  as well as on the maintainer's 128 MB one. **Risk, named honestly:** object
  reads would share bank 1 with PCM streaming, on the throughput path jtframe
  hand-tunes per target (`jtcps1_sdram.v:167-175`, `OBJ_LATCH` 0 on MiSTer
  "to increase object throughput"), and it is **UNMEASURED**. Measuring it
  also needs the Verilator SDRAM model fixed first (it decodes 8 MB per bank,
  so bank 1 above 8 MB currently aliases in simulation — ~3 constants).
  **BOTH DONE 14z-107 (3): the model is fixed (fork commit 3 — and it was NOT
  ~3 constants; the dropped bit is `addr[22]` on `sdram_a[9]`, not
  `addr[9]`), and the traffic IS now measured** —
  `tests/audit_sdram_bank_load.sh`, `build/sdram_bank_load_14z107.log`.

  **RECOMMENDATION: (2)**, with (1) as the long-term path if upstream ever
  tags again. Rationale: (2) keeps a pinned, reproducible framework and a
  working simulation gate, needs no dual-chip inference, and widens the
  hardware audience rather than narrowing it; (1) trades all of that for
  headroom we do not need at 56.1 MB. **Both options still require the
  core-side FORMAT work either way** — the GFX tile-code promote, the 68k
  `rom_cs` window (including the `0x400000` objcfg collision), and the
  QSound latch/width fix. Gameplay-visible consequence: none under either
  option; the only player-facing difference is that (2) may drop the 128 MB
  hardware requirement to 64 MB.

- ~~**THE SIM HARNESS'S P2 / 6-BUTTON EXTENSION (14z-107, NOT blocking).**~~
  **DECIDED (maintainer, 2026-08-23): option A, LATER** — *"agreed, we can
  do it later"*.
  **SPLIT AND HALF-CLOSED 14z-107 (8). The FIDELITY half is DONE; the
  COVERAGE half remains deferred by the ruling above.**
  * **FIDELITY — SHIPPED, fork commit `519aff8b` (LOCAL ONLY).** It was a
    BUG, not a gap: `SimInputs` held P1's AND P2's buttons 5 and 6 DOWN
    (`&0xf0` and a `0xff` seed on a `[9:0]` ACTIVE-LOW port), so the two
    legs of `test_mister_sim_anchor` were not running identical inputs.
    Measured before the fix against MAME (`RAM:$FF8058/5A/5C/5E`) and fixed
    with `& ~0xf` / `0x3ff`. The anchor was re-measured and did NOT move
    (2146 / 2609 / 463); every §4 field still agrees and the arcade draw is
    the same pair. Session 14z-107 (8).
  * **COVERAGE — STILL DEFERRED, unchanged by the above.** Making buttons
    5/6 and P2 SCRIPTABLE is still fork work nobody has done;
    `tools/rpl2siminputs.py` still refuses `p2=` and `p1=4/5/6` loudly, so
    `02_demitri_vs_cpu` and `04_select_fuzz` still do not translate, and the
    P2-identity fields are still excluded by name in the anchor gate. The
    motivating case is unchanged: a 2P replay would pin the arcade-draw
    opponent. Nothing here is blocked on it.

  Original 14z-107 (7) framing, kept: **UPGRADED FROM COVERAGE TO FIDELITY,
  and the maintainer may want to re-time it: `SimInputs` does not merely
  LACK buttons 5 and 6, it HOLDS THEM DOWN.** `test.cpp:201` is
  `dut.joystick1 = (dut.joystick1&0xf0) | (v&0xf);` and `&0xf0` discards
  bits 9:8 that the line above had just released; joystick is ACTIVE LOW and
  `jtcps2_main.v:266` wires `joystick1[9:7]` into `in1`. So every simulated
  run this lane has taken had P1 holding buttons 5 and 6 from the first
  input line to the last — and only EOF releases them, so a SHORTER input
  file changes the inputs. The MAME leg does not do this, so the two legs of
  `test_mister_sim_anchor` are not running identical inputs; they still
  agree on every mapped field and pick the same P1 record base, so nothing
  measured is invalidated. The fix is one line (`& ~0xf`) in the SAME commit
  as the P2/6-button work, and it WILL move the frozen anchor again — which
  is why it is a deliberate slice and was not done in 14z-107 (7).
  [DONE 14z-107 (8) — and the anchor did not move; P2's buttons 5/6 were
  held too, by the `0xff` seed `parse_inputs()` never corrects.]
  So the fork's third commit is queued, not open: extend
  `test.cpp`'s `SimInputs` (P2 joystick + buttons 5/6, `dip_test` off
  button 4) when a refused replay is actually needed — the motivating one
  being a 2P replay that pins the arcade-draw opponent and retires the
  P2-identity exclusion in `test_mister_sim_anchor.sh`. Original entry:
  **THE SIM HARNESS'S P2 / 6-BUTTON EXTENSION (14z-107, NOT blocking).**
  jtframe v1.7.3's `SimInputs` is P1-only with 4 buttons (bit 11 doubles as
  `dip_test`), so `02_demitri_vs_cpu` and `04_select_fuzz` still REFUSE
  translation — and 14z-107 gave the question a concrete cost: the only §4
  field disagreement on the MiSTer oracle is the 1P ARCADE DRAW picking a
  different CPU opponent (sound-state-fed, `atlas/ram.md:99`), which a 2P
  replay would pin. Options: **(A) extend `test.cpp`'s `SimInputs` in the
  fork now** (a third commit, same macro-gated shape as the WRAM hook — P2
  joystick + buttons 5/6, and a bit for `dip_test` that is not button 4);
  **(B) leave it and keep excluding the P2-identity fields by name**, as the
  gate does today. **RECOMMENDATION: A, but AFTER the profile-shape ruling
  lands** — it is input coverage, not the oracle, and the oracle is green.
  Gameplay consequence: none (test harness only).

- ~~**THE MiSTer PROFILE SHAPE (14z-106, slice B measured).**~~
  **DECIDED (maintainer, 2026-08-23): OPTION A — WIDE v1 VERBATIM on the
  128 MB tier.** *"verbatim indeed: 128MB always was the target."* So there
  is ONE profile and ONE romset across FBNeo / MAME / MiSTer, and the MiSTer
  work is width plumbing only; the 128 MB module is a stated hardware
  requirement in the README.
  **CORRECTION 14z-107 (2), MARKED IN PLACE — THE RULING STANDS, THE
  IMPLEMENTATION ASSUMPTION DOES NOT.** The PROFILE decision above (WIDE v1
  verbatim, one romset, one release artifact) is unchanged and is not
  reopened. Two things attached to it are now measured false:
  (a) ~~"the MiSTer work is width plumbing only"~~ — the CPS-2 core caps GFX
  at 32 MB in the OBJECT FORMAT (16-bit code + 2-bit bank,
  `jtcps2_obj_scan.v:47,152`), the 68k at a flat 4 MB
  (`jtcps2_main.v:184`), scroll at 8 MB with no bank input, and QSound at a
  7-bit latch. **No SDRAM tier lifts any of them**; the GFX one is the same
  19-bit tile promote WIDE v1 already ratified on FBNeo, so it is the
  profile in RTL rather than a new invention — but it is core work, not
  plumbing. (b) ~~the 128 MB tier being a bit-width away~~ — at our pin
  (`v1.7.3`) 64 MB is PHYSICAL (table, row/column geometry, and pin
  assignments all saturate; `docs/platform/mister.md` "The SDRAM ceiling at
  our pin"), and the `JTFRAME_SDRAM_XL` tier exists only upstream, 3057
  commits away, in a branch that also requires `JTFRAME_SDRAM_CACHE`.
  The route is now its own pending decision, **THE MiSTer MEMORY-MAP
  ROUTE**, above. Option B (a tighter MiSTer-only profile) was
  killed by measurement, not preference: 14z-107 read the bank allocation
  (`jtcps1_sdram.v:158-164`, `:332-410`) and GFX ALONE forces the tier —
  bank 0 has ~8 MB spare (so PRG 6 MB fits the CURRENT tier) and bank 1
  holds PCM alone in 16 MB (so QSound 16 MB fits too), while banks 2+3 are
  full at 32 MB. Any GFX above 32 MB needs banks > 16 MB = `SDRAMW` 24 =
  the same 128 MB module, so B buys zero hardware compatibility while
  forking the romset into a second generation. The only route that would
  keep a 64 MB module is a bank-1 repack (GFX sharing the PCM bank, ~6.4 MB
  of its 8 MB spare) — rejected as arbiter surgery on the object-throughput
  path jtframe already hand-tunes per target (`jtcps1_sdram.v:167-175`),
  and it drags a MiSTer-only layout back in anyway. **That repack, not B,
  is the fallback if the 128 MB tier proves unreachable.** ~~OPEN AND BEING
  MEASURED (14z-107, maintainer: *"as to IF we can address... only one way
  to find out!"*): whether `SDRAMW` 24 is parameter plumbing or controller
  surgery in jtframe at v1.7.3, and whether the physical 128 MB module is
  addressable by its SDRAM controller.~~ **ANSWERED 14z-107 (2): NEITHER —
  at `v1.7.3` `SDRAMW=24` is not reachable at all** (no table row, no AW=24
  arm in the bank geometry, `addr[9]` undriven, 13 A pins / 2 BA / 1 nCS
  assigned); the 128 MB tier is upstream-only, is TWO CHIPS on one module
  selected by nCS polarity, and lives only in the cache-lane controller.
  Two knock-ons for the reasoning above: the repack fallback is now a
  first-class option rather than a last resort (**the total FITS 64 MB** —
  ~56.1 MB measured, `mister_fit.md` §6), and the "arbiter surgery"
  objection to it is still the right one to weigh, but so is a 3057-commit
  uprev to an untagged master. Original entry:
  **THE MiSTer PROFILE SHAPE (14z-106, slice B measured).** The numbers
  (`docs/project/mister_fit.md`) remove the roster trade-off: the group-C
  art (6.39 MB) cannot fit vanilla's 32 MB GFX (0.49 MB blank, upper
  bound), so any MiSTer build needs a wider GFX tier than jtcps2's
  documented 64 MB `JTFRAME_SDRAM_LARGE`. Options: **(A) WIDE v1 verbatim
  (PRG 6 / GFX 48 / QSound 16 MB) on a 128 MB SDRAM tier** — one profile
  and one romset across FBNeo/MAME/MiSTer, MiSTer work = width plumbing
  only (jtframe `SDRAMW` 23→24 and +1 bank/prog/ioctl bit, the core's
  `main_rom_addr`/gfx/`qsnd_addr` buses, the 14z-86 QSound latch fix), no
  content change; cost: framework surgery, profile-gated in the fork,
  ONE hardware requirement (the 128 MB module the maintainer has — users
  with 32/64 MB modules cannot run it, which the README must say). **(B)
  a tighter MiSTer-only profile** (e.g. PRG 5 MB / GFX 40 MB / QS 9 MB):
  saves nothing architecturally — every bus still widens by one bit, and
  it forks the romset/manifests/tests into a second generation for no
  gain. **RECOMMENDATION: A.** Gameplay-visible consequence: none; the
  only player-facing fact is the 128 MB requirement.

- ~~**MiSTer ALIGNMENT (14z-106) — five questions before any RTL.**~~
  **ALL FIVE RULED (maintainer, 2026-08-22).** Rulings, then what each
  one commits us to; the original brief follows unchanged.
  1. **Base tree — RULED: a SEPARATE CORE**, so the reference CPS-II
     core stays separately usable; ours respects Jotego's licence(s) and
     is FOSS "if the licensing scheme allows"; the exact fork mechanism
     is left to my proposal. **Facts (jtcores README, checked
     2026-08-22):** jtcores and jtframe are **GPL-3.0** ("you are
     obliged to publish your code if you use mine") — so our core is
     FOSS by obligation, not just preference, and must ship its source.
     **PROPOSAL (my recommendation, open to veto):** (a) a PUBLIC fork of
     `jotego/jtcores` under the maintainer's GitHub, GPL-3.0 retained,
     branched from a pinned upstream tag; (b) a NEW core directory
     (working name `cores/cps2w`, final name TBD) that reuses the cps2
     RTL the way cps1/cps15/cps2 already share it through jtframe
     macros, producing its OWN RBF (`jtcps2w.rbf`) — the stock
     `jtcps2.rbf` is never rebuilt or touched; (c) pinned here as
     submodule `emu/jtcores` on the fork branch, with the fork's diff
     mirrored as `emu/jtcores-patches/0001-*.patch` for review — the
     MAME/FBNeo pattern, and what keeps Rule 1 v2's "small,
     human-reviewable set of declarative lines" honest on a third
     implementation; (d) upstream PR later, at the maintainer's
     discretion — the separate-core shape is what makes one possible.
     FIRST TASK of the arc: read the fork and VERIFY (b)'s sharing
     mechanism — it is my reading of the tree layout, not a measurement.
     **LICENCE GAP SURFACED:** this repository carries NO LICENSE file.
     The core fork is GPL-3.0 by obligation; the licence of THIS tree
     (tools, patches, docs, authored assets) is the maintainer's call and
     is now a pending decision (below).
  2. **Profile shape — RULED: measure first, choose on numbers** (the
     recommendation adopted). Arc task: merged-m6 GFX occupancy per
     group/bank + the real PRG extent, then the fit options.
  3. **Governance/oracle — RULED: the recommendation adopted** — Rule 1
     v2 extends verbatim; jtframe/Verilator SIMULATION is the gate,
     HARDWARE is the field test (the MAME-oracle / playtest split).
  4. **Environment — RULED: MiSTer with a single SDRAM module, plus a
     Jammix extension card**
     **AMENDED (maintainer, 2026-08-23): DUAL SDRAM IS OFF THE TABLE** —
     *"I don't own any nor plan to"*. This forecloses MiSTer's DUAL-SLOT
     path (`SDRAM2_*` / `sys_dual_sdram.tcl`), which was already
     unreachable in jtframe (no `SDRAM2_*` ports on `jtframe_emu`) and
     which conflicts on pins with the analog I/O board the Jammix CRT
     field test needs. **It does NOT foreclose the upstream XL tier:**
     XL is TWO CHIPS INSIDE ONE MODULE in the ONE slot, selected by the
     top address bit with chip-select carried on nCS POLARITY
     (`jtframe_burst_io.v:158`) — i.e. exactly what a standard MiSTer
     128 MB module is (doc/sdram.md catalogue IDs 1/4/8/9 = 2 units).
     Caveat carried: that the module inverts chip 1's /CS is INFERRED
     from the RTL, never measured — so if the XL fallback is ever taken,
     confirm WHICH 128 MB module is in hand first. The chosen primary
     route (the bank repack) needs no such confirmation: it fits a
     64 MB tier and is module-agnostic. (CRT at original resolution/frequencies —
     the field test can be made on real video timing). **OPEN DETAIL:
     which module size?** jtcps2's own docs: CPS2 games with >= 16 MB GFX
     need a 64 MB module; a MiSTer-shaped WIDE (GFX up to 32 MB + PRG +
     QSound 16 MB) needs at least 64 MB and likely 128 MB
     (JTFRAME_SDRAM_LARGE). Confirm before the profile numbers are fixed.
  5. **Distribution — RULED: MRA + RBF over the same release members**,
     covered by the tagged release; stock `vsavj` in the MRA "if
     necessary and/or makes sense — argue for/against". **ARGUMENT:**
     an MRA binds one romset to one RBF, so a stock-`vsavj` MRA aimed at
     OUR RBF is not redundant with the official core's — it is the
     STOCK LEG of the emulator superset invariant on FPGA (the patched
     core running unmodified vsavj must behave as the reference core
     does), i.e. a test instrument that must exist in-tree regardless.
     Shipping it in the release too costs one small XML and buys players
     a same-RBF A/B and a sanity check that their dump is good. Against:
     a second menu entry people may pick by mistake. RECOMMENDATION:
     ship BOTH, the stock one labelled "(stock vsavj — reference leg)".

  ORIGINAL BRIEF: **MiSTer ALIGNMENT (14z-106) — five questions before any RTL.** Built
  only from what the record already measured (`docs/project/cps2_wide.md`
  "Known limits", source-verified 14z-86 at jtcores @1ae053f3 + jtdsp16
  @71fa564a; STATE_HISTORY 14z-85/86). The facts: jtcps15 QSound is LLE
  (jtdsp16 + the real dl-1425), but its sample path is 23-bit with a
  7-bit bank latch, so content in our QSound extension (banks 0x80+)
  would ALIAS onto legacy samples — a ~4-line RTL width fix; the stock
  core caps 68k PRG at 4 MB and GFX at 32 MB (2 x 16 MB) inside a 64 MB
  SDRAM_LARGE map, so WIDE v1 (PRG 6 / GFX 48 / QS 16) does NOT fit and a
  MiSTer-shaped profile is required; a 17-character variant is impossible
  (ruled 2026-08-15 — full roster or nothing).
  1. **Base tree.** Fork jotego/jtcores at which tag/commit, and is the
     intent an upstreamable separate machine (the `vsavjw` pattern — a
     new MRA/core variant leaving stock `vsav` untouched) or a private
     fork? RECOMMENDATION: pin a tag as a submodule under `emu/jtcores`
     exactly as MAME/FBNeo are pinned, carry our change as a patch file
     in `emu/jtcores-patches/`, and shape it as a separate machine so
     the emulator superset invariant has a stock leg to compare against.
  2. **Profile shape (gameplay-visible, yours).** PRG target: 6 MB as
     WIDE v1, or the measured minimum (D+H alone overflow 4 MB by ~310 KB;
     the three-tenant merged image's real extent should be re-measured
     before picking)? GFX must come back from 48 MB to <= 32 MB: which
     tenant tiles get per-slot exclusivity/banking, i.e. what art may
     not coexist on screen? RECOMMENDATION: measure the merged-m6 GFX
     occupancy per group/bank first (the 14z-62/66 census tooling) and
     present the fit options with numbers; do not choose blind.
  3. **Governance and the oracle.** Rule 1 v2 (profile-gated, stock
     `vsavj` bit-identical on the patched core, ratified per profile
     version) should extend verbatim — but MiSTer has no headless
     per-frame work-RAM harness. Is the gate a Verilator/jtframe
     simulation of the core (slow but deterministic and scriptable), a
     hardware capture protocol (the maintainer plays; no RAM checksum),
     or both? RECOMMENDATION: simulation as the gate, hardware as the
     field test — same split as MAME (oracle) vs playtest today.
  4. **Environment.** Does the maintainer have a MiSTer (with the 128 MB
     SDRAM module — JTFRAME_SDRAM_LARGE needs it) and the Quartus
     toolchain, or is simulation the only lane this side? This decides
     who builds the RBF and how fast the confirmation loop is.
  5. **Distribution.** MRA + RBF over the SAME release members as
     `release/merged-m6/` (the patch artifact does not change shape); the
     tagged GitHub release ruled 14z-105 then covers both. Confirm, and
     whether the MRA should also carry the stock-profile `vsavj` entry.

- ~~**ADOPT THE HIT-CLASS MAP EXTENSION + RE-FREEZE huitzil & pyron
  (14z-82b).**~~ **DECIDED 2026-08-12 (maintainer): ADOPTED** — shipped as
  huitzil-m4 (e66678d0) + pyron-m3 (6c7f7322), 14z-82c. Original entry: The generated `hitclass_map_extend` site_thunk fixes a
  playtest-reachable crash LATENT IN BOTH FROZEN TENANT BUILDS (pyron's
  satellite type-64 contact = the f7997 vec3, measured on pyron-m2 solo;
  Huitzil's 68/72 share the pool). Numbers, all measured on a probe build
  (tests/audit_hitclass_map_cost.sh, rerunnable): fix holds through the
  11,017-frame soak that crashes the frozen build; LEGACY BIT-IDENTICAL
  over 30,284 frames on four replays, with a fire census showing legacy
  never enters the map at all [**THAT FIGURE IS RETRACTED — 14z-92 M4
  measured 230 legacy entries corpus-wide; the adoption still stands and
  the argument is "legacy enters and gets vanilla answers"**]. Cost of
  adoption: the row goes in
  huitzil.toml + pyron.toml (shared, dedups on the merge) → BOTH
  verticals re-freeze (new fingerprints; registry rows; their frozen
  masked legacy self-logs re-measured — expected unchanged given the
  zero-fire census, but measured is the standard). Donovan/stock
  untouched. RECOMMENDATION: adopt — it is the third instance of the
  "vs2 widened an index consumer" class (14z-26, 14z-35 precedents) and
  the crash needs one satellite contact to fire in a real match.

- ~~**DONOVAN's map entries 61/62 (14z-82b, separate and smaller).**~~
  **DECIDED 2026-08-12 (maintainer): (a) KEEP VANILLA'S ZEROS** — his
  sword-companion objects' hit-class reactions stay as every shipped
  build has had them; measured unexercised (0 map entries in his
  replays). Revisit only if his satellite hits ever feel wrong in
  playtest — then it is 2 bytes in the generator's policy + a Donovan
  re-freeze. Original entry:
  MEASURED SINCE: his types 59-63 are the projectile-pool objects his
  SWORD-COMPANION machine spawns (61 = the sword-routine region
  x065e5a's family; spawns measured in both his replays), and they enter
  the hit-class map ZERO times in his replays — the missing reaction is
  UNEXERCISED, so (a) costs nothing observable today. Original entry: vs2
  gives his satellite types 61/62 hit classes 0x0E/0x04 where vsavj
  holds the do-nothing 0 — so his type-61/62 projectile hits currently
  produce NO hit-class reaction on every shipped build, and always have.
  The fix above deliberately keeps vanilla's zeros (donovan-m3a
  byte-untouched). Options: (a) keep zeros — shipped behavior, nothing
  moves; (b) adopt vs2's two bytes in the same thunk body — vs2-faithful
  hit reactions for his satellite, at the cost of a Donovan re-freeze
  and a battery re-measure. If (b) is ever wanted, it is a 2-byte change
  to the generator's policy plus the measurements; playtest feel decides
  whether the missing reaction is real. RECOMMENDATION: (a) for now;
  revisit if his satellite hits ever feel wrong in playtest.

- **IF `anim` CANNOT LEAVE THE CRYPT WINDOW — the fallback order is set
  (maintainer, 2026-08-10).** Framing recorded verbatim in effect: *"we'll see
  if and how we can grow the crypt window and still have everything work, or
  if we need to cut down access to a character (in which case I'll leave Pyron
  aside, but that's kind of a last resort)"*.

  So the ladder, best to worst:
  1. **Make `anim` movable** — root-cause the odd pointer. If this works, no
     decision is needed at all, which is why it is the active task.
  2. **Grow the crypt window in the WIDE profile.** A profile change, so
     maintainer-approved by construction, and it must be shown not to break
     anything (the profile's whole justification is the emulator superset
     invariant — `tests/test_wide_profile.sh` / `test_mame_wide.sh` are the
     gates, plus `test_crypt_boundary.sh` since the window's EDGE is what
     would move). Deficit to cover if nothing else changes: **125,560 bytes**.
  3. **Ship two tenants, Pyron aside.** Explicitly a LAST RESORT. Note the
     measured irony: Pyron's reach-constrained set is **0 bytes** — he is the
     cheapest tenant on every axis except his `anim` (111,872). Dropping any
     one tenant frees roughly its own anim, so on space grounds alone the
     choice between them is close to arbitrary; it is a roster decision, not
     an engineering one.

- ~~**THE MERGED BUILD'S `[init_shim]`: ONE SHIM, THREE TENANTS (14z-77)**~~
  **DECIDED 2026-08-10 (maintainer): the recommendation below, in full** —
  adopt phase mode, dispatch flavor per id, gate the write so Pyron stays
  untouched until his polarity is measured against native, then run Donovan's
  battery on a phase-mode build before trusting the merge. **IMPLEMENTED as
  slice G** (14z-77e); the two measurements it names remain OPEN and are
  listed there. Original entry follows.

  Surfaced by slice F's collision measurement — it was one of the three real
  merge blockers, and unlike the other two it was not purely mechanical.

  **The mechanics, measured.** The shim is emitted ONCE per build at ONE site
  (`dispatch_00`'s seed hook, `seed_entry = 0x016C64` — identical in both
  manifests that declare it). It (a) seeds the object pool if the latch is
  clear, and (b) writes the VS2/VH2 **flavor** byte to `+0x3C2` of the player
  struct being initialised, or `flavor_held` when that player's Start is held.

  Three things follow, and only the first is mechanical:

  1. **Flavor polarity is per tenant and already ratified.** D1 (VS2 default)
     means `0x01` for Donovan and `0x00` for Phobos — the polarity differs
     because the engine branch each character tests differs (14z-66 measured
     it against native). A merged shim must write the id-appropriate byte,
     i.e. the same N-way dispatch the thunks need. No decision required.
  2. **`latch_mode = "phase"` is NOT per tenant — the seeder is shared, so a
     merged build either has the gate or does not.** Phobos NEEDS it: without
     it his ecosystem drains pool 0 and the round-2 char re-init re-runs the
     seeder over LIVE pools (14z-65 measured the f4890 wipe, orphaned queues,
     and a freed slot dispatched into palette space). He is in the merged
     build, so **the merged build must carry the gate**, and Donovan's shim
     bytes therefore change — the generator's own comment says his frozen
     bytes stand "until his own re-freeze adopts the mode". The gate only
     narrows WHEN the seed runs (to `$FF800C == 0x40000`, the char-load
     phase), and Donovan's first init is at that phase, so it SHOULD be inert
     for him — but that is an argument, not a measurement, and this project
     does not ship arguments. **Required before the merged build is trusted:
     Donovan's replay battery on a phase-mode build, compared to
     donovan-m3a.**
  3. **Pyron declares NO `[init_shim]` at all.** In a merged build the shim
     runs at char-init for whatever the hosted dispatch covers, so he could
     be given a `+0x3C2` flavor byte he has never had. Whether he reads that
     byte is UNMEASURED. Options: give him an explicit row (needs his own
     polarity measured against native vs2, the 14z-66 procedure), or gate the
     flavor write so only tenants that declare one receive it.

  **Recommendation:** adopt phase mode for the merged build (2 is forced),
  dispatch the flavor bytes per id (1), and gate the write so Pyron is
  untouched until his polarity is measured (3, the conservative half) — then
  measure Donovan's battery before trusting the merged build. The alternative
  worth the maintainer's attention: if Donovan's battery DOES move under phase
  mode, the fallback is a per-id gate on the phase check itself, which is more
  emitted code at a shared site and wants explicit sign-off.

- ~~**THE BEAM'S LIST-TYPE 12: FLATTEN, OR RATIFY THE HOOK? (14z-71)**~~
  **DECIDED 2026-08-09 (maintainer): NEITHER — take over the dead
  list-type 6**, with the explicit condition that the deadness assumption
  must not be load-bearing. Built as `build/hui20`; see the 14z-71
  RESOLVED section. The maintainer's framing, kept because it generalises:
  *"there is almost always a chance it actually wasn't dead and we just
  missed how it was used... if we encounter regressions in vanilla
  assets/engine, this is one of the first places to check, and should we
  ever encounter something that uses list-type 6 that we didn't know of,
  we should stop, analyse and assess the situation before continuing."*
  That is now enforced by construction (the vanilla fallback) and by a
  gate (the `$FF010C` tripwire), not by memory. See THE DEADNESS REGISTER
  below.

- **THE 14z-62e SELECT-ART ANALYSIS (decided above).** The
  last visual-de-substitution piece: the tenant's select-art subset (101
  bank-1 tiles + 4 placeholder label tiles + the 6-tile medallion) still
  overwrites Jedah's bank-1 select-figure art, garbling his select-screen
  BODY (face/name/match art are all back). Two measured options:

  **A — a per-hover bank thunk + group C (recommended).** The select
  FIGURE object's bank already follows the hovered char through the
  engine table (measured: `PRG:0x05F9EC` jsr's the bank helper; hovering
  the tenant writes 0x1000 and his standing figure draws from group C
  TODAY). The PORTRAIT-record object instead gets bank 1 ONCE at venue
  init (`PRG:0x07C428`). Option A thunks the per-hover record-pointer
  consumers (`PRG:0x05F328`/`0x06C0E0`) to also set that object's bank:
  hovered==tenant -> 0x1000, else -> 0x2000 (the value it already holds,
  so pure-legacy RAM is byte-identical; after a tenant visit the restore
  re-converges). Select art then lives in group C at native codes — NO
  fit problem — and `vsav.zip` leaves the rompath ENTIRELY PRISTINE.
  Cost: a new engine hook on the select path (cycle-only for legacy; the
  ratified hook class, but the re-freeze's flicker/window inventory must
  be re-measured with it in — the standing watch applies). The name/
  highlight-piece objects' banks need the same treatment (their sites
  are one measurement away, same method).

  **B — relocate into blank bank-1 space, no hooks.** Vanilla bank 1 has
  2,917 blank tiles (largest runs: 881 at 0xBE90-0xC200, 460 at 0x3634,
  357 at 0x6C9C — measured). Placing the ~117 tiles there needs a NEW
  greedy fit (block-geometry aware), a reference-exclusivity proof for
  the chosen ranges (blank != unreferenced: a legacy record could use
  blank tiles as transparent filler, and art there would APPEAR — the
  proof method is the medallion's whole-image scan), and `vsav.zip`
  stays patched-but-additive (nothing of Jedah's overwritten). Zero
  engine hooks, zero legacy cycle cost.

  **Recommendation: A.** It finishes the artifact story (pristine
  vsav.zip — the strongest possible provenance), reuses the established
  thunk pattern and the already-poked bank table, and avoids a new fit +
  exclusivity-proof toolchain for a one-off. The hook's legacy cost is
  cycles only, in the class the basis already tolerates; it will be
  measured before the re-freeze ratifies anything. B stays the fallback
  if the measured hook cost violates the standing watch.

- ~~**RATIFY A COMPOSITE §4 CLASS? (14z-61)**~~ **RATIFIED 2026-08-06
  (maintainer: "Your proposal is ratified").** CLAUDE.md §4 amended: the
  `composite` class is the strict CONJUNCTION of flicker-tolerated and
  bounded re-convergent window, adding no tolerance to either. The seven
  `.pending` expectations became `.masked` `composite` specs carrying the
  shapes they had already printed, and the WIDE reference freeze is
  complete — `run_suite.sh` on `donovan-m5w` is GREEN, all 63 replays
  validated or explicitly skipped. Original entry below.

- **RATIFY A COMPOSITE §4 CLASS? (14z-61) — the analysis behind the
  decision above.** Seven legacy replays measure as the frozen
  hook-flicker inventory PLUS one bounded re-convergent window per
  select-screen ENTRY (table in 14z-61). Both halves are already ratified —
  `flicker` (§4 v2) and `window` (§4 v3) — but no single class expresses
  their conjunction, so those replays cannot be frozen without either a new
  class or a fudge. They are `.pending` and fail the suite meanwhile.

  **Proposal: `composite <baseset> <flicker-csv> <window-list>`**, defined
  as the strict CONJUNCTION of the two: every divergent run must be
  accounted for by name, the flicker set must match the frozen inventory
  exactly, the window list must match exactly, and the run must fully
  re-converge. It tolerates nothing that `flicker` and `window` do not each
  tolerate, and it is strictly stronger than either alone.

  Implemented and ground-truthed ahead of the decision so ratification is
  one word rather than a session: `tools/compare_composite.py`,
  `tests/test_compare_composite.sh` (7 synthetic cases + a no-loophole
  check — extra flicker frame FAILS, missing flicker frame FAILS, onset
  moved one frame FAILS, no re-convergence FAILS, bit-identical FAILS, an
  unfrozen second window FAILS). **Nothing validates against it until you
  say so**: accepting means turning each `.pending` file into a `.masked`
  one carrying the spec it already prints.

  **Recommendation: ratify.** The alternative readings are worse — calling
  these replays `skip` hides a real comparison, and widening `flicker` to
  swallow a 900-frame run would be the loosening §4's standing watch exists
  to prevent.

- ~~**FREEZE THE WIDE TRACK? (14z-61).**~~ **DONE 2026-08-05 (maintainer:
  "yes freeze and register as wide reference first, then we resume").**
  `9bac6ee3 -> donovan-m5w`; see 14z-61. Original entry below.

- **FREEZE THE WIDE TRACK? (14z-61) — the analysis behind the decision.** `build/m5_wide` (`9bac6ee3`) is now
  playtest-confirmed with and without Donovan, both WIDE profile gates are
  green, and the new rendering + member-identity gates are green. The
  registry convention is that rows are added at FREEZE time as a STATE.md
  decision, so this is not mine to do.
  **Recommendation: freeze and register it** as the WIDE reference
  (`donovan-m5w` alongside `donovan-m2c`), for one specific reason beyond
  bookkeeping: M3a moves the tenant from `0x0F` to `0x13` and will churn
  the select records, the thunk id and the bank-table row at once. Without
  a registered WIDE reference, a regression during that work has nothing to
  bisect against on this track — which is exactly the position that made
  the sprite garble expensive.
  Cost if we skip it: none today; the risk is only felt later, and by then
  the build may not be reproducible from the tree.

- **THE SELECT SCREEN AND THE SUPERSET INVARIANT (14z-60r).** Drawing three
  new medallions requires the wheel OBJ record to grow from 18 to 21
  entries and its coordinate list likewise. Measured: neither can grow in
  place (another record starts immediately at `0x272ABA`; the coord list is
  immediately followed by the shared global pool), so both must relocate —
  cheap, one referrer at `PRG:0x2689FE`. **The problem is not placement, it
  is the invariant.**

  The record's `count` word changes and its `budget` word is debited from
  the OBJ emitter's shared per-frame budget — GOTCHAS records that exact
  coupling flipping a borderline skip decision into a one-byte work-RAM
  divergence. Three more sprites also render. **So any legacy replay that
  reaches the select screen will diverge in RAM.** M2b's select work avoided
  this by strict in-place replacement preserving the host's budget word;
  adding CELLS makes that impossible by construction.

  CLAUDE.md §1 covers "any match, **menu path**, or attract sequence", so
  this needs an explicit ruling rather than an assumption:

  **A — a bounded select-screen carve-out (recommended).** Legacy replays
  are compared as today up to select entry, and the select-screen
  divergence is MEASURED, mechanism-attributed and frozen per replay, in
  the same style as the existing `diverge` constants and masked windows.
  Rationale: the invariant's purpose is that vanilla *gameplay* is
  untouched, and a select screen that offers three more characters is by
  definition content that involves them. Condition: the divergence is
  measured and frozen BEFORE acceptance, never accepted blind, and must not
  extend past the select screen into match state.

  **B — keep the wheel vanilla**, reach the newcomers by another mechanism
  (the option-2 hold-Start alternates the maintainer already ranked lower).
  Preserves the invariant literally; costs the decided roster UX.

  **C — attempt a RAM-neutral extension.** Not viable: the budget word must
  cover the entries actually emitted, and three extra sprites change OBJ RAM
  regardless. Recorded so it is not re-proposed.

  **Recommendation: A**, with the measurement done first so the ruling is
  made on a number rather than on a prediction.

  **MEASURED 2026-08-05 (14z-60s), and the number is good.** Built
  (`select_wheel roster21`) and compared against the previous WIDE build on
  the masked basis, so the wheel change is the only variable:

  | replay | frames | divergent | window | after |
  |---|---|---|---|---|
  | `04_select_fuzz` | 3520 | 162 | 890-1051 | 2469 identical |
  | `02_demitri_vs_cpu` | 5520 | 733 | 890-1622 | 3898 identical |
  | `03_two_player_vs` | 5320 | 913 | 890-1802 | 3518 identical |
  | `09_mirror_pick` | 4720 | 993 | 890-1882 | 2838 identical |
  | `05_timeout_idle` | 12120 | 733 | 890-1622 | 10498 identical |

  Every replay: **onset at frame 890 — select-screen entry — exactly ONE
  contiguous run, and FULL RE-CONVERGENCE.** Match state is bit-identical
  in all five, including a complete timeout match (10,498 identical frames
  after the window closes). The divergence is confined to the screen we
  deliberately changed and reaches nothing else.

  That is a **stronger** guarantee than the existing frozen-`diverge`
  class, which never re-converges at all. The proposal for ratification is
  therefore a new comparison class: **"bounded select-screen window,
  re-convergent"** — onset frame, window end and run-count frozen per
  replay, with re-convergence and match-state identity as the assertions.
  Mechanism: select-screen init caches the record pointer we repointed
  (`GOTCHAS` class 4), which is why onset is identical across replays.

- ~~**THE `0x360+id` ANIM BLOCK (14z-60)**~~ **DECIDED 2026-08-05
  (maintainer): option A, INHERIT — "since we can. If it fails, we'll
  fall back to option B (relocation)."** So a newcomer at `0x13` plays
  anim `0x363` from the shared `0x360-0x36F` block, exactly as vsav2
  ships; sites `PRG:0x003E40` and `PRG:0x004082` stay folded and are
  recorded as `inherit` in the tenant manifest. Fallback if playtest shows
  the inherited animation is wrong for a newcomer: relocate the block to a
  free 32-wide anim-number range and widen both masks. Original write-up
  kept below.

- **THE `0x360+id` ANIM BLOCK (14z-60) — the analysis behind the decision
  above** — of the seven sites that fold the
  character id to 4 bits, five are ordinary porting work; two
  (`PRG:0x003E40`, `PRG:0x004082`) compute a per-character anim number in a
  block that is genuinely 16 wide (`0x360-0x36F`, with `0x370+` already
  occupied). **Option A: inherit** — a newcomer at `0x13` plays `0x363`,
  which is exactly what vsav2 ships, Capcom having left both folds in
  place. **Option B: relocate** the block to a free 32-wide range and widen
  both sites — a numbering audit plus shared-engine edits, for a family we
  cannot yet name. **Recommendation: A**, on the strength of vs2 being a
  shipped existence proof; revisit only if a playtest shows the inherited
  animation is wrong for a newcomer. Detail in session 14z-60 and
  `docs/game/atlas/id_space.md`.

- ~~**M5 SOUND NEEDS A DATA HOME (14z-52)**~~ **SETTLED 2026-08-04 by the
  dual-track decision below: it lives in `wide_ext`.** Two corrections to
  the record that got it there:
  **(a) Option B was DEAD and the recommendation was wrong.** It proposed
  reclaiming the "inert since 14z-31" `weapon_accent_t0/_t1/rowd_slot`
  rows. Measured 14z-59g: those are `data_port` rows writing 0x20 bytes
  each to `0x39FBE0-0x39FC40`, which is in NEITHER hole (`hole_a`
  `0x0BF6A0-0x100000`, `hole_b` `0x3EC720-0x400000`). They are in-place
  palette overwrites, not hole allocations, so reclaiming them frees
  **zero** of the 352 bytes needed. The original entry mistook them for
  hole tenants.
  **(b) Option C stopped being expensive.** It was rejected as "larger
  blast radius" before WIDE existed; WIDE is now demonstrated on both
  emulators, so it is the cheap option — and option A (Jedah's anim
  region) keeps its unaudited dead space AND stays available for the
  ported select web, which was its earmarked purpose all along.

- ~~**M5 VOICE SAMPLES (14z-51)**~~ **DECIDED 2026-08-04 (maintainer):
  "A then B, gates stay strict, option C is rejected."** Ship M5 with those
  specific sounds silent now (option A — it matches the current
  silent-by-design behaviour for exactly the sounds that cannot be
  faithful); revisit growing the QSound sample region (option B) at M3,
  when Huitzil and Pyron force the same question at scale, inside the
  measured 16 MB ceiling. **Option C (overwriting low-value vsav content)
  is rejected** and may not be re-proposed — it is superset-invariant-
  adjacent. Original entry with the full option analysis kept below.

- **M5 VOICE SAMPLES (14z-51) — the analysis behind the decision above:**
  6-8 of Donovan's sounds (his voice
  lines / vs2-new sfx: ids 0x71D/0x73E/0x753-0x756, likely the "Change
  Immortal" family) do not exist in vsav's sample ROMs, which are
  byte-full. Options: A) ship M5 with those specific sounds silent
  (shared sfx all restorable regardless); B) grow the QSound sample
  region via driver descriptor (vm3.11m/12m from 4MB->8MB members or
  add members; CLAUDE.md rule 1 permits load-map changes; MiSTer
  impact unknown); C) overwrite low-value vsav content (risky,
  superset-invariant-adjacent). Recommendation: A now (matches the
  current "silent by design" behavior for exactly the sounds that
  cannot be faithful), revisit B at M3 when Huitzil/Pyron force the
  same question at scale.
  **UPDATED 14z-59f — option B now has a measured hard ceiling.** CPS-2
  WIDE v1 already declares QSound at **16 MB, which is MAME's maximum**
  (`qsound_device` is a `device_rom_interface<24>`, 24 address bits). So
  B is available and proven on both emulators up to 16 MB and NOT ONE
  BYTE further: growing past it would mean widening a SHARED MAME device,
  which is outside Rule 1 v2. If Donovan + Huitzil + Pyron voice banks do
  not fit in the 8 MB the profile adds, the answer has to be exclusivity
  or banking, not more region. Worth sizing that before committing to B
  at M3. (Two duplicate copies of this entry were merged here.)

- ~~**ROSTER ACCESS MECHANISM**~~ **DECIDED 2026-08-04: option 1, an
  altered select screen keeping the existing cells and appending the three
  newcomers; hold-Start alternates are the fallback. See 14z-59l.**

- See SPEC §7 for the rest. Nothing blocks current work.

- ~~**THE REPOSITORY LICENCE (14z-106).**~~ **DECIDED (maintainer,
  2026-08-22): GPL-3.0 for everything** — `LICENSE` added (the FSF text
  verbatim), README "Licence" section. Original entry: The tree has no LICENSE file.
  The jtcores fork is GPL-3.0 by obligation; the licence of THIS tree
  (tools, patches, docs, authored assets — never ROM bytes, rule 7) is
  undecided. Options: GPL-3.0 across the board (simplest, one licence
  for the whole deliverable); MIT/BSD for tools + GPL-3.0 only for the
  core fork (more permissive tooling, two licences to explain); CC for
  docs/assets on top of either. RECOMMENDATION: GPL-3.0 for the whole
  tree — one licence, compatible with the core by construction, and the
  maintainer's stated wish is FOSS. Maintainer's call.


## Moved 14z-128 (2026-09-03) — four entries that had stopped shaping work

Verbatim from STATE.md's "Decisions pending": the session-series ruling (its own
text says "This entry is now history"), the frame-data privacy rule (implemented
14z-126), the DF-startup question (answered by measurement 14z-126, no change
needed) and the CLAUDE.md condensing pass (pass 2 done 14z-124).

- **A NEW SESSION SERIES — DECIDED (maintainer, 2026-09-02): (d) KEEP `14z-`.**
  *"yes, we keep 14z- for the reasons found in previous sessions."* No seam,
  no second namespace, no regex change: `tools/gen_gate_index.py`'s
  `SESSION_RE` and `tools/checkdocshape.py`'s `SESSION_TOKEN`/`CHRONO` keep
  matching every tag, past and future, and the [VSP-162] documentation of the
  prefix is what resolves the confusion that opened this. The next session is
  `14z-127`. **This entry is now history; the reasoning is kept below.**
  Recorded 2026-09-01 as: RESOLVED TOWARD (d), awaiting the one-word confirm.** The maintainer: "I like
  S127 but if there's a risk, even low, I don't mind keeping the 14z prefix
  honestly." **THE RECOMMENDATION FLIPPED FROM (a) TO (d), and NOT on the
  risk** — the risk is the wrong axis. The `checkdocshape`-blindness failure
  is a known three-line change that a must-fire control eliminates, which is
  this project's own standard for "not a risk"; residual is only an unknown
  fourth consumer (405 files grepped, 3 parses found). **The real reason is
  that the BENEFIT collapsed when the prefix was DOCUMENTED an hour earlier:**
  [VSP-162] fixes the confusion by explaining it, so a reader is un-confused
  in ten seconds, and what a rename adds beyond that is cosmetic legibility —
  bought at a PERMANENT second namespace and a seam that every future grep and
  reader must know, which no control removes. For a key whose whole value is
  resolving cleanly, a boundary is an ongoing cost against a cosmetic gain.
  If it is ever wanted, the cheap moment is a NATURAL BOUNDARY (a new
  milestone, or the MiSTer arc closing), not mid-arc. The options as put:** The existing keys are SETTLED:
  they stay as they are, resolvable forever ([VSP-162]). This is only about
  what the NEXT session is called. **Why it is even on the table:** the
  maintainer read [VSP-162] as written and asked "why are we still on session
  14?" — the prefix is fossilised and actively misleads (session 14 was ONE
  sitting, 2026-07-28, the M2a freeze; MiSTer opened 104 sessions later at
  `14z-106`).
  **Options:**
  **(a) RECOMMENDED — `S127`: drop the dead prefix, KEEP the live counter and
  the whole grammar** (letter suffix = continuation `S127b`; parenthetical =
  phase `S127 (3)`). The seam is one line — "S127 immediately follows
  14z-126b" — chronological order is preserved, every existing habit carries
  over, and nothing in the archive moves.
  **(b) Restart at `S1`. NOT RECOMMENDED: it COLLIDES** with the early bare
  integers still live in the archive (`Session 3`, `4`, `5-6`, `7`, `9`,
  `13`, `14`), so `S1`..`S14` would be ambiguous to exactly the greps the key
  exists to serve.
  **(c) Date-based (`2026-09-01a`).** Self-describing, but sessions are
  context windows (~8/day measured), so it needs letter suffixes anyway and
  buys nothing the counter does not.
  **(d) Do nothing** — defensible; the prefix is inert and now documented, so
  the confusion it caused is a one-time cost already paid.
  **THE COST, MEASURED 2026-09-01 (and it is small but has a TRAP):** of 405
  files mentioning `14z`, only THREE are PARSES —
  `tools/gen_gate_index.py:60` (`SESSION_RE`) and `tools/checkdocshape.py:78`
  and `:79` (`SESSION_TOKEN`, `CHRONO`). Everything else is prose citation,
  which is exactly why renaming old keys is forbidden and why a NEW series is
  nearly free. **THE TRAP: `checkdocshape`'s two regexes are the gate that
  bars a REFERENCE doc from re-accreting chronology (built 14z-126b). A new
  prefix not added there makes that gate SILENTLY BLIND to the new tags** —
  green while checking nothing, the failure mode that let eight freezes of
  chronology accrete in HANDOFF unseen. So the ruling, if it is (a), lands as
  ONE commit: three regexes extended + a must-fire control proving the new
  prefix is caught + the seam line in [VSP-162] and the port skill. No
  gameplay surface; the maintainer's convention, so theirs to rule.

- **FRAME DATA IN A PUBLIC REPO — DECIDED (maintainer, 2026-08-31: "I agree
  with the recommendation") AND IMPLEMENTED 14z-126, option (b).** THE CLASS
  RULE: every per-move ROM-derived table — OURS AND THIRD-PARTY ALIKE — is
  generator output kept OUT of the public tree; the tree ships the READERS
  and the VERDICTS, and currency is locked by hash instead of by publishing
  the numbers. What moved to `../charpages/framedata/` (new producer
  `tools/framedata_pages.sh`, which refuses an in-repo output dir):
  `<tenant>_anim.md` ×3, `<tenant>.html` ×3 (the artifacts are published from
  there now), `community_crosscheck_full.md` (the move-by-move comparison),
  `vanilla_hit_damage.tsv`. What STAYS in the tree: the generators, the
  verdict rows (`tests/expected/community_crosscheck.txt`, 91), the measured
  slot map (chain ids, not frame data), the mechanisms and "What is NOT
  known", and two new hash locks — `tests/expected/charmap_pages.sha256` (6)
  and `tests/expected/vanilla_hit_damage.sha256`. The committed
  `community_crosscheck.md` is now the VERDICT-ONLY rendering (1060 → 359
  lines, zero per-move value rows, no workbook values). History is ACCEPTED,
  not rewritten (the maintainer's call; a rewrite of pushed `main` was not
  done). The original entry follows.
  **The proposal, as recorded before the ruling:** The repo is PUBLIC
  (`DefinitelyFrenchName/VampireSaved`). The maintainer's position, in
  substance: frame data has been published in community docs and in
  Capcom-sanctioned mooks, so the DIFFS forwarded to the community are fine,
  but we should refrain from publishing the data ourselves — remove the
  public documents that carry it, keep them private, and instead ship TOOLS
  that regenerate the frame-data documentation from the romsets, as the
  character pages already do (`tools/charpages_internal.sh` -> `../charpages/`);
  argued as beneficial because the focus moves to the validity of the
  reader/interpreter and the documentation can never go stale. Claude's
  assessment (given in session): agree with the direction — it is [VSP-12]'s
  GENERATED-doc law applied one step further — with four riders: (1)
  regeneration guarantees CURRENCY, not correctness — both 14z-125 defects
  were interpretation defects a hash-locked page would have reproduced; the
  in-emulator rigs (`test_vanilla_frame_join`, the hit rig) stay the validity
  gates and carry no tables; (2) draw the line by CLASS, not file: per-move
  ROM-derived numbers live today in `community_crosscheck.md` (ours + the
  workbook's), the three tenant `_anim.md`/`.html` pages, and
  `tests/expected/vanilla_hit_damage.tsv` — the 91-row
  `community_crosscheck.txt` is already verdict-shaped; (3) the workbook's
  OWN values stay out regardless (the compilation is the author's work) —
  the delta-only `render_md` fix; (4) removing a file from HEAD does not
  remove it from the PUBLIC history (24 pushed commits) — accept-in-history
  is the recommendation; a rewrite of pushed `main` is destructive and the
  maintainer's alone. **Options:** (a) third-party values only out, ours
  stay; (b) RECOMMENDED — every per-move ROM-derived table (ours and theirs)
  becomes generator output under `../charpages/` via one route
  (`tools/framedata_pages.sh` beside `charpages_internal.sh`), the in-tree
  `community_crosscheck.md` keeps verdicts / mechanisms / counts /
  "What is NOT known" only, the tenant pages move to the same route, gates
  lock SHA-256s of the regenerated output under ROMDIR plus the verdict rows;
  (c) leave as is. Half a session for (b); the class boundary and the
  history question are the maintainer's to rule.
- **DF-STARTUP INVINCIBILITY FOR THE TENANTS — ANSWERED 14z-126, MEASURED,
  NO CHANGE NEEDED (DECIDED by measurement; nothing to rule unless a window
  is to be retuned).** The window is `+0x147` (the victim's invincibility
  timer, the hit test's gate at `PRG:0x018064`), armed PER CHARACTER by the
  seq-0x16 handler `dispatch_16` selects — NEITHER global (the shared body
  arms only `+0x143` = 0x14, the throw immunity) NOR inherited (the tenants'
  rows are repointed to their own vs2 handlers): Donovan 64 ticks (Victor 59),
  Huitzil 79 (Bulleta 41), Pyron 41 (Demitri 41, coincident by value). All 15
  vanilla values measured and frozen too (`tests/expected/df_startup_invuln.tsv`,
  gate `tests/audit_df_startup_invuln.sh`; engine_internals "Dark Force" ->
  "The STARTUP INVINCIBILITY window"). Natively on vs2: no window at all
  ([VSE-69]). *[CORRECTED 14z-168: no window from vs2's P+K (Dark Force Power, all 15 characters); the tenants' vs2 EX moves DO arm these windows natively — `tests/audit_df_modes.sh`, "Ruled 2026-09-18 (14z-168) — the tenants' Dark Force" above.]* Retuning a tenant is one data byte in its ported handler, if
  ever wanted. The original entry follows. **RECORDED, not started — and it is THE NEXT ARC
  (maintainer, 2026-08-31: the DF question first, then the Zabel j.LK patch,
  then Jedah's crouching recovery).** THE MAINTAINER SHARPENED IT (2026-08-31):
  not just *do the tenants have the startup invincibility*, but **if they do, is
  it a GLOBAL property of the DF activation or is it INHERITED FROM THE SHELL
  CHARACTER?** That third possibility is the one the tree makes most likely and
  the measurement plan below did not name: the tenants sit at variant ids
  `0x10`/`0x11`/`0x13`, which ALIAS base-half rows in every table vsavj did not
  repoint ([VSE-10]), so a flag read from an id-indexed row would hand Phobos
  Bulleta's, Pyron Demitri's and Donovan Victor's. **So the rig needs three
  legs, not two: the tenant, its SHELL character, and a legacy control** — if
  the tenant matches its shell rather than its vs2 self, the answer is
  inheritance and the fix is a repoint, not a port. The original question: do the VS2
  tenants get the invulnerable STARTUP window vanilla characters get at Dark
  Force activation? What the tree knows: activation is the shared body
  `PRG:0x027000` (seq 0x16, one stock) followed by the PER-CHARACTER
  `dispatch_16` row (`PRG:0x0BF31A`) — the tenants' rows are repointed to
  their ported vs2 handlers, which were written for vs2's DIFFERENT DF system
  ([VSE-69], `oracle`-independent: `engine_internals.md` "Dark Force"). So if
  the window is armed in the shared body the tenants inherit it; if it is
  armed in the per-character handler, they do not — that is the seam to
  measure. `ram.md` names `+0x11E/+0x134/+0x145/+0x1A4` as
  "invulnerability/status flags", class [C] (a candidate, never verified).
  Measurement (T3, half a session): replay 97's activation rig
  (`tests/replays/df/97_df_mech.rpl`, `audit_df_framework.sh`) with the
  opponent's attack timed to land INSIDE the startup window, legacy control
  Demitri (expect no hit) vs each tenant, positive control = the same attack
  landing outside the window; instrument = field_trace of `+0x54` /
  HP / the four flag bytes across the window; freeze as
  `tests/audit_df_startup_invuln.sh`. If a tenant lacks it, the fix is a
  GAMEPLAY decision ([VSP-10]) under the DF ruling above ("adjustments per
  character, never to the general mechanic") — options then: (a) arm the
  vanilla flag from the tenant's ported handler (a thunk on our own code,
  legacy-clean by construction); (b) accept. No recommendation before the
  measurement.
- **THE CLAUDE.md CONDENSING PASS (maintainer-directed 2026-08-30, 14z-122
  close). PASS 1 DONE 14z-123 (441 → 414 lines; narratives → rule + citation;
  anchors and headers intact). PASS 2 DECIDED (maintainer, 2026-08-31: "Then
  do the CLAUDE.md pass 2") AND DONE 14z-124 — (a)+(b)+(c) as recommended:
  414 → 344 lines; [VSP-27..30] live in `docs/project/oracle_classes.md`
  (the spec of record, 105 lines), the document roster in `docs/README.md`
  "The documents, by role", the recordings how-to in HANDOFF; §4/§5 keep the
  law and point; census re-frozen for the four moved anchors. ~~PASS 2 NEEDS
  A RULING~~ — the remaining bulk is
  law-dense, and the honest next cut is STRUCTURAL, by the file's own Rule 1 v2
  principle ("the spec is NOT copied here — two copies drift"): (a) §4's five
  oracle-class definitions ([VSP-27]..[VSP-31], ~75 lines) → a canonical
  `docs/project/oracle_classes.md`, §4 keeping the class NAMES, the standing
  watch and a pointer (the anchors move with the paragraphs; the port skill's
  D.2 rules cite "§4 v1/v2..v5" and would cite the new document; census
  re-frozen); (b) §5's document taxonomy list → `docs/README.md`'s routing
  table, §5 keeping the one-question rule and a pointer (~30 lines); (c) the
  recordings rule's operational how-to (the run/playback commands) → HANDOFF,
  the rule keeping capture-first, naming and cleanup (~10 lines). Estimated
  end state ~290 lines. Recommendation: (a) and (b); (c) is marginal.
  Nothing in pass 2 is Claude's to decide — it moves anchored law out of the
  constitution.** The original ruling: The maintainer's words, in substance: CLAUDE.md
  "has become very big and looks to have been extended like a log. This is
  not bad but wastes resources: we should plan a pass on it to remove
  duplicates if any and rewrite the contents in a more concise and to the
  point manner, without losing precious information, especially on the work
  style and discipline." Constraints the pass's tooling already enforces:
  CLAUDE.md carries **30 `**[VSP-N]**` anchors** (checkskills + the census
  freeze every one by section) and is a LOG for VSP skill numbers — every
  rewrite keeps each marker with its fact or moves the rule ([VSP-13]-grade
  discipline; the census diff is the review artifact). Shape suggestion to
  ratify at the pass: the LAW (rules 1-8, §4's classes, §5's standing
  orders) stays verbatim-precise; the CORRECTION NARRATIVES appended inside
  rules (the 14z-91/94/110b/114 stories) condense to the rule + a dated
  citation, with the narrative in the docs that already carry it. ~~Slot:
  before G7 (the close bumps floors; the law should settle first).~~ (G7
  CLOSED 14z-124 without it — pass 2 stands alone, no slot constraint.)

## Moved 14z-134 (2026-09-05) — thirty entries that had stopped shaping work

Verbatim from STATE.md's "Decisions pending", in the order they stood there, at
the DECISIONS_HISTORY pass owed since 14z-133 (STATE.md was ~250 KB against its
~150 KB target and this section was the bulk). Every entry is DECIDED, DONE,
CLOSED, FORGONE or SUPERSEDED in its own text; two headers were corrected in
STATE before the move (the version-numbering scheme and the boot name screen
both said NOT REGISTERED after their freezes had registered them — marked in
place, 14z-134). What STAYS in STATE: the two backlog directions, the
living-documentation direction, Pyron's row 0x11 (the port decision is open),
the Phobos-throw ±1 damage residue (kept open as a knowledge item by the
maintainer), the community cross-check (aerial outliers and the wiki half still
open) and the Zabel j.LK session (ruled, not started).

- **~~THE DUAL-TRACK GATE ON THE MERGED BUILD — MEASURED IN FULL, RULING NEEDED~~
  DECIDED (maintainer, 2026-09-05, 14z-133b): OPTION (a) — *"in any case it
  has value so we keep it by bringing it in line with the ruling."* The
  maintainer's own rationale on the way, recorded because it is the right
  question for any parallel-run gate: parallel runs compare things known to
  be the same; this gate's legs are the stock-size and WIDE builds of the SAME
  content, so only PROFILE-GATED changes can separate them (the boot title did
  not and could not — both legs carry it); its target, profile inertness
  before select entry, is a "must never be altered" sequence; only its
  INSTRUMENT (raw FBNeo checksums) was stricter than the project's ruled
  definition of identical. It does NOT enforce MAME/FBNeo parity — both legs
  run on FBNeo; parity is `test_mame_parity` + the §4 anchor comparison. BUILT
  the same sitting (see the 14z-133b rows). Original entry:** (the ONE open item of thread 3). [VSP-25] froze the stock-vs-WIDE
  onsets on the SOLO Donovan track (890 per select-reaching replay, 3190 for
  `10_midattract_start`, 4267 for `01_attract_long`) and made "an onset moving
  EARLIER" the failure. `test_dualtrack` was RULED stock-vs-MERGED at 14z-132
  and never re-pointed; run against `build/m3b_merged23` it reports every
  onset EARLIER (890 -> 830, 3190 -> 1672, 4267 -> 1672) and FAILS.**
  **WHAT THE EARLIER "ONSET" IS, dumped and diffed byte by byte over EVERY
  checksum-differing frame before each frozen onset (not sampled;
  `build/dualtrack_merged_14z133b/`):**
  * the nine plain select-reaching replays (`02 03 04 05 07 08 09 29 30`):
    exactly ONE frame each, 830, THREE bytes `$FF7FF3-$FF7FF5` — the
    dead-stack window (`$FF7F00-$FF7FFF`, the MAME masked basis's window);
    frames 831-889 bit-identical again; the real divergence at 890 in the
    same offsets as on solo (`$FF06D4/D5/DB-DD`, `$FF80B5`, `$FFB818`).
  * `01_attract_long`: 1,181 differing frames before 4267, all 1,181 dumped:
    3,543 byte-diffs, EVERY ONE at `$FF055B-$FF055D` — the sound-driver work
    area, the [VSP-26] FBNeo-only phase class whose frozen inventory is
    exactly those three offsets; zero bytes anywhere else; at 4267 the
    divergence starts in the effect-channel pointer `$FF87A5-$FF87A7`
    exactly as frozen.
  * `10_midattract_start`: 569 differing frames before 3190, all dumped: the
    same six offsets (`$FF055B-D`, `$FF7FF3-5`), zero outside.
  **So the merged build is bit-identical to stock up to select entry EXCEPT
  for execution-position flickers inside two classes already ratified for
  exactly this mechanism** (CLAUDE.md §4: hooks cost cycles, interrupts land
  at skewed instruction boundaries; three tenants' hooks skew more than one
  tenant's), and the FROZEN ONSETS DID NOT MOVE. The gate compares raw
  whole-RAM checksums with no mask, so it reads a flicker as an onset.
  **OPTIONS:** **(a) re-point to merged and freeze the merged inventory
  EXACTLY** — the pre-select comparison ignores the six measured offsets
  (never the windows: [VSP-26] "the window is NOT the tolerance", a byte
  inside a window but outside the inventory fails as GROWTH), the onsets stay
  890/3190/4267, and `05_timeout_idle`'s one-frame `$FF7FF3-5` shape is the
  frozen dead-stack flicker. A stock-vs-solo control leg can stay as a
  second assertion. Half a session, mostly the ground-truth control (a byte
  outside the six must fail). **(b) keep the solo default** — green today,
  asserting about a track we do not ship; the [VSP-175] brittleness in its
  purest form. **RECOMMENDATION: (a).** The inventory is measured whole, its
  mechanism is the ratified one, and the artifact's pre-select state is
  proven identical to stock; the release does not wait on this (the gate is
  green on solo at release), but the merged form is the honest one. Not
  changed unasked: the onsets are maintainer-ratified ([VSP-25]).

- **~~WHERE A MiSTer ARTIFACT SHOULD NAME THE MERGED BUILD IT CARRIES~~ DECIDED
  (maintainer, 2026-09-05, 14z-133b): (a) + (c); (b) REFUSED OUTRIGHT — *"I
  absolutely don't want the mark in the MRA name so first and third is
  perfect."* BUILT the same sitting: `tools/mra_header.py --build` writes the
  self-verifying BUILD block, `mister_mra.sh --wide` passes the build and
  fails loudly, gate `tests/test_mra_build_line.sh` (static tier) with the
  wrong-build must-fire control, the bundle convention in `mister_field.md`.
  The current bundle on the board is untouched; the next freeze's MRAs and
  bundle carry it. (Original ask, mid-field-test on M16: *"in the future it
  might be nicer to have the merged build referenced somewhere in the mister
  builds"*.) The options as costed follow.**
  **TODAY, measured on `../mister_fieldtest_14z132/`:** the merged build is
  named ONLY in the bundle README's first line and in
  `release/merged-m16/mister/MISTER.md`'s title; the MRA carries no build
  name (its `<name>` is jtframe's from the fork's `mame.xml` description,
  its comment header is OUR `tools/mra_header.py` text, fixed); the bundle
  directory is named by SESSION (`14z132`), which is the naming the recordings
  law [VSP-20] explicitly rejects for recordings ("the freeze the recording was
  PLAYED on, never the mark or the session"). Answering "is this bundle M16?"
  took five hash comparisons (STATE 14z-133b).
  **OPTIONS, each costed:**
  **(a) A BUILD LINE IN THE MRA's COMMENT HEADER** — `mister_mra.sh --wide
  <build>` already knows the build dir, so `mra_header.py` can emit
  `BUILD merged-m16 (mark M16) · vsavjw.zip sha1 664b14f8…` resolved from
  `registry.tsv` by the whole-set key (falls back to `UNREGISTERED <key>`
  before registration). Zero fork cost, no menu or filename change, travels
  with the card; invisible until someone opens the file. ~1 hour incl. a
  must-fire control in `test_mister_mra_map` (a header naming the wrong
  build must fail).
  **(b) THE MARK IN THE MRA `<name>`** — `Vampire Saved M16 - CPS-2 WIDE
  (Japan 970519)` from the fork's `mame.xml` description: shows in the
  MiSTer MENU, which is the one place a tester picks the artifact, so it is
  the field's naked-eye tell BEFORE boot (the wheel mark is the one after).
  Cost: the description is fork content, so a fork commit per freeze — but
  the CRC tail is already one — AND the `.mra` FILENAME changes per freeze,
  so stale MRAs must be deleted from the card and every path that names the
  file (`package_release_platforms.py`, `test_release_roundtrip` §4,
  `mister_field.md`) is re-pointed per freeze, or made to glob. ~half a
  session.
  **(c) BUNDLE DIRECTORIES NAMED BY FREEZE SET** — `../mister_fieldtest_merged-m16/`,
  the recordings law applied to bundles; forward-only (the 14z11x/14z132
  names are cited in docs and stay). Zero cost; a convention line in
  `mister_field.md`.
  **RECOMMENDATION: (a) + (c) now, and (b) if the menu name is wanted** — (a)
  makes the artifact self-describing for free and is checkable by a gate;
  (c) costs nothing; (b) is the only one visible without opening a file,
  and its per-freeze filename churn is the price of that, which is the
  maintainer's trade to make. Nothing built; the current bundle is not
  touched while it is on the board.

- **~~THE UNPINNED STOCK-SET GATES — WHICH MAME INSTRUMENT DO THEY RUN ON UNDER
  THE RUNNER?~~ DECIDED (maintainer, 2026-09-05, 14z-133b): OPTION (c), THE
  RUNNER-LEVEL DEFAULT — *"yes, runner-level default. Then redo the run to
  validate that the runner-level default is on par with expectations."*
  SHIPPED the same session: `run_all_emulator.sh` exports `MAME_BIN` = the
  WIDE build unless the caller set one, prints which applied beside the
  instruments, and `test_emulator_runner.sh` §11 locks it (default delivered,
  caller wins, must-fire control with the export line removed). Validation =
  the full freeze sweep re-run under the default, compared row by row with
  14z-133's green run, plus the affected set named mechanically — result in
  STATE 14z-133b. (14z-133, found by the class measurement behind the three M16
  sweep reds; maintainer's call, no gameplay surface.)** `tools/run_mame.sh`
  execs `${MAME_BIN:-mame}`, and `tests/run_all_emulator.sh` exports no
  `MAME_BIN` (it prints the instruments it found and leaves the environment
  alone). Of the ~153 gates that reach MAME through the wrappers, 106 pin the
  binary themselves (the `${MAME_BIN:-$HOME/.cache/vampire-saved/mame/cps2}`
  idiom) and **~43 do not**. None of those 43 boots `vsavjw` — the four that
  did were the 14z-133 reds plus one out-scope probe, all pinned and now gated
  by `tests/test_mame_bin_pinned.sh` — so they RUN; but under the runner they
  run on **Homebrew's stock 0.288** rather than on either pinned instrument
  (`mame/cps2` WIDE or `mame-ref/cps2` reference). `test_mame_parity.sh`
  proves the source reference build reproduces every frozen expectation
  bit-for-bit, and the frozen logs were made on Homebrew's binary, so the two
  are verdict-equivalent today; it is still an instrument that nothing pins
  and nothing checks ([CPE-24]: a moved instrument invalidates what it
  measured). **Options:** (a) pin all 43 with the same idiom — they would then
  run on the WIDE binary, which the emulator superset invariant
  (`test_mame_wide.sh`) covers for stock content; ~43 one-line edits, and
  `test_mame_bin_pinned` widened from "boots vsavjw" to "reaches a wrapper";
  (b) pin them to `mame-ref` instead — the reference instrument by name, but a
  SECOND idiom to keep straight; (c) a runner-level default — the runner
  already resolves `_MAME_W`, so exporting `MAME_BIN` when unset makes every
  sweep use the pinned instrument while standalone gates keep their own pins
  (one line + a `test_emulator_runner` assertion), and leaves the 43 scripts
  untouched. **Recommendation: (c), then decide (a) at leisure** — it closes
  the sweep-time variance at the point it is created, and it is the shape the
  ROMDIR fix took (normalise where the value is first read). Not swept unasked.

- **THE VERSION-NUMBERING SCHEME — DECIDED (maintainer, 2026-09-04, 14z-132):
  option (A), the in-game mark IS the merged build number, plus a gate that
  fails a freeze whose `version_text` does not match its registry name.
  ~~BUILT, NOT REGISTERED~~ BUILT AND REGISTERED 14z-132 (`donovan-m20` /
  `huitzil-m27` / `pyron-m21` on whole-set keys, `merged-m16` at 14z-133b B2;
  header corrected 14z-134 — the body below predates the registration).** The maintainer's complaint, verbatim in substance:
  *"It's very disturbing to have a M13 based on a merged-m14 with M14
  appearing on the character wheel (and I'm not touching on possibly other
  numbering elsewhere)."*
  **THE DRIFT, MEASURED from the tags:** the mark started EQUAL to the merged
  number (merged-m6 = M6) and drifted by exactly the two freezes where it was
  not bumped — merged-m7 kept `M6`, merged-m10 kept `M8`. Since merged-m11 the
  mark has been the build number minus two.
  **THE CONDITIONAL ANSWERED ITSELF.** The ruling attached *"we might need to
  update the merged build number for the current release if and only if the
  previous one does not reflect all the changes"*: changing the mark changes
  the glyph tiles, which changes the artifact, so by the project's own rule
  it is a new freeze name. `merged-m15` therefore CANNOT carry `M15`.
  **LANDING: merged-m16 / wheel `M16`**, with donovan-m20 / huitzil-m27 /
  pyron-m21 and the stock twin CARRIED (measured unchanged).
  **BUILT AND MEASURED 14z-132:** delta is exactly `vsw.33m` + `vsw.37m` on
  each of the four WIDE tracks, ZERO members on the stock twin (the
  `bank5_active` prediction, confirmed by rebuild); every program fingerprint
  unchanged; `test_version_string` PASS on all four incl. pixel-exact
  snapshot and both verdict controls. Dirs `don_m20` / `hui54` / `pyron38` /
  `m5_stock15` / `m3b_merged23`.
  **THE GATE'S ANCHOR — DECIDED the same day: the newest annotated
  `freeze/merged-m<N>` git tag**, chosen over HANDOFF's registry row and over
  a new manifest field because it anchors on the reviewed record rather than
  on anything the build says about itself ([VSP-166]). Accepted consequence:
  the gate is RED for the whole freeze window until tagging, which is correct
  signalling. Deliberately NOT tolerant of "N or N+1" — that tolerance would
  have accepted the exact bug being fixed (merged-m7 carrying M6, drift 1).
  **A FIFTH NUMBER, recorded but NOT changed:** the build DIRECTORY counter
  runs at four different offsets from the freeze name — donovan +0, merged +7,
  pyron +17, huitzil +27 (verified over six freezes). Renaming is refused
  (~55 gates reference the paths, re-pointed each freeze).
  **THE "GENERATION N" OPTION — OFFERED 14z-132 AND DECLINED THE SAME DAY,
  on my recommendation, maintainer-validated.** The proposal was to call a
  freeze by a single GENERATION number equal to the merged build's, so one
  number resolves to all five tracks.
  **THE MEASUREMENT THAT KILLED IT: the track offsets DRIFT, and the drift is
  INFORMATION.** At 14z-113 the merged track moved ALONE (m9 -> m10, the
  one-zip repackaging) while donovan-m14 / huitzil-m21 / pyron-m15 CARRIED
  untouched, and the offsets shifted +5/+12/+6 -> +4/+11/+5. They have been
  stable only for the six freezes since.
  **A TRACK NUMBER COUNTS THAT TRACK'S OWN FREEZES AND CARRIES WHEN THE TRACK
  DOES NOT CHANGE**, so a single generation number would either lie about a
  carried track or force a new tag onto a byte-identical artifact — which the
  project deliberately avoids. It would also be a SIXTH namespace rather than
  a replacement: the four track names are simultaneously registry row names,
  expectation-set directories and annotated tags, all cited, so none can be
  retired.
  **A CORRECTION TO MY OWN CLAIM, recorded because it is what made the option
  look attractive:** I reported these offsets as "stable, verified over six
  freezes" — true of those six, and presented as though it were a property of
  the scheme. It is not; it is a coincidence of a run in which all four tracks
  happened to move together. The same caution applies to the build-DIRECTORY
  offsets in the paragraph above: a carried track mints no new build dir
  either, so those drift by the same mechanism.
  **ADOPTED INSTEAD, zero cost:** name a freeze in prose by its MARK (= the
  merged build number) — "the M16 freeze", which HANDOFF's registry table
  nearly did already — and write the carry rule where the registry explains
  itself (`tests/expected/registry.tsv` header), so an offset drift reads as
  "a track carried" rather than as something to tidy.

- **~~MERGED-VS-SOLO TEST SCOPING — THE GENERAL RULE IS RULED AND IS NOW
  [VSP-175] (maintainer, 2026-09-04, 14z-132). THE WALK IS 2 OF 25 DONE;
  NOTHING RE-POINTED YET.~~ CLOSED 14z-133b: thread 3 walked in one pass
  (16/16 green on merged, `test_dualtrack` by ruling with class v6) and B2
  done (the merged registry row + the three legacy-oracle gates on merged,
  53/53). Nothing of the merged-vs-solo question remains open. Original
  entry:** The maintainer's core belief, verbatim:
  *"regardless of how low the odds of a change between a solo build and the
  merged build are for a given test, these odds are not zero, so the test is
  brittle intrinsically. However, unless they are specific to solo builds,
  tests on solo builds are likely to hold value even now, therefore they
  likely should be run but on the merged build."* Plus: a solo-specific gate
  is OUT of the release "run all tests", and *"there's a strong argument for
  keeping the test as a historical artifact but deprecating it permanently if
  there is not meaning in having that test on the merged build."*
  **THE RULE, ruled CORRECT: a gate is solo-specific only if a single-tenant
  build is the SUBJECT of its assertion.** A solo build as a reference leg, a
  fixture or a rig convenience does not qualify. Spec: [VSP-175] +
  `docs/project/gate_scoping_method.md` §9.
  **THE PREDICTION ON RECORD (mine; the maintainer believes it correct but
  declined to make it absolute): the exception clause may have ZERO members** —
  no gate in the 25 has a solo build as its subject. If it holds, the walk is
  24 re-points with costs, not a classification exercise, and the
  "deprecate permanently" branch is empty too.
  **THE INVENTORY (measured 14z-132; BOUND: a static read of each script's
  defaults and hard-wired assignments — the 31 "no build reference" gates are
  UNOPENED, so 25 is a floor).** Of 142 release-scope emulator rows:
  46 merged · **25 solo-only** · 3 both · 36 other build · 31 no build ref.
  `audit_walker_repoint` looks solo but its `ci_emulator.tsv` row supplies
  `%MERGED%` — the `args` column can re-point a gate without touching it,
  and only 3 rows use it today.
  **THE 25, grouped as offered for challenge:** legacy oracle on `don_m19` (4)
  `audit_legacy_pairings` `audit_flicker_attribution` `test_fbneo_legacy_oracle`
  `test_dualtrack`; three-tenant data map (3) `test_move_naming`
  `test_projectile_params` `test_reactions`; harness self-checks using a build
  as a fixture (3) `test_guard_integrity` `test_mask_ranges_reader`
  `test_record_window`; per-tenant subject (15) `audit_df_gold`
  `audit_trap_parity` `audit_trap_shock` `audit_trap_sound`
  `audit_tripwire_reach` `audit_voice_borrow` `test_anim_node_walk`
  `test_beam_anim_walk` `test_beam_variants` `test_hitbox_encoding`
  `test_hui_df_style` `test_hui_grab_victim` `test_hui_oracle`
  `test_pyron_blink` `test_pyron_cosmo`.
  **GATE 1 — `test_dualtrack`: RULED stock vs MERGED.** Not solo-specific:
  its subject is the WIDE build's superset property and the stock twin is the
  reference leg. What a re-point re-measures: §1's frozen per-replay onsets
  (890 / 3190 / none for `06_test_mode`) and §3's onset (frame 4267,
  `$FF87A4-$FF87A7`, same writer PC both legs); §2 should be unaffected.
  **Whether pre-select bit-identity survives three tenants' hooks is UNKNOWN
  and is itself worth knowing.**
  **GATE 2 — `audit_legacy_pairings`: NOT A RE-POINT.** It resolves its
  expectation SET by fingerprint and hard-fails `FAIL: <dir> has no registry
  row`; the merged build deliberately has none. Exactly 3 of the 25 do this
  (this, `audit_flicker_attribution`, `test_fbneo_legacy_oracle`) — the whole
  legacy-oracle group — so all three wait on the dispatch-key entry below.
  **GATE 3 — `test_reactions`: WALKED, AND THE ANSWER WAS A CORRECTION OF MINE.**
  Analysed 14z-132 as a solo-defaulting gate whose frozen expectation was
  captured from our own build, and recommended re-anchoring it on vs2.
  **BOTH HALVES WERE WRONG, found by reading the gate instead of its
  provenance row:** `test_reactions` has exactly ONE emulator invocation and
  it runs **`vsav2`** — native. The three build dirs supply
  `extract/regions.json` to the chain DECODER and nothing more; no leg runs on
  our build at all. So `reactions_*` was reference-anchored all along, exactly
  like `move_naming`, and there is nothing to re-anchor.
  **THE CAUSE, and it is the thing worth keeping:** its PROVENANCE row said
  only "which chains Donovan runs AS THE VICTIM…" and its re-freeze command is
  `FREEZE=1 TENANTS=donovan tests/test_reactions.sh`, so a reader (me) inferred
  "frozen from our run" = "measured on our build". The row was UNDER-DESCRIBED,
  which is precisely the gap the 14z-132 class split exists to close — filling
  the column in is what forced the question and exposed the error. Rows
  corrected, and the description now names the native leg.
  **CONSEQUENCE FOR THE REFACTOR: the candidate set is EMPTY.** After the
  correction, every tracked expectation is reference-anchored, correct by
  construction (`static` / `hash-lock` / `derived`), a ledger, or the ONE
  deliberate open-defect marker (`ladder_tenant_vs_palette`, the
  `audit_pyron_capture_block` pattern, which stays). `df_startup_invuln` is
  honestly labelled `reference + ours` (15 vanilla + three tenants).
  **SO THE PREDICTION "it probably generalises" IS RETRACTED TWICE OVER** —
  once by measurement (4 candidates, not many), once by this correction (0).

  **GATE 4 — THE INVENTORY ITSELF WAS MEASURED ON THE WRONG AXIS (14z-132).**
  The original 25 classified by "the script names a build dir". A build dir is
  one of THREE things and only one makes a gate a merged/solo question:
  a `rompath` the gate BOOTS as vsavjw (the build is the subject, ~18 gates);
  an `extract/` a decoder reads while the only emulator leg runs NATIVE vs2
  (the build is a DATA SOURCE, not a subject — 5 gates); or both.
  **THE FIVE THAT DISSOLVE, each confirmed by reading its invocations:**
  `test_anim_node_walk`, `test_hitbox_encoding`, `test_move_naming`,
  `test_reactions`, `test_projectile_params` — every one runs
  `run_mame.sh vsav2` and nothing else (`projectile_params` touches no rompath
  at all). Gate 3 was the first instance of this class, not a one-off.
  **SO THE WALK IS 25 -> ~16 genuine candidates**, and they are HOMOGENEOUS:
  they boot our build as vsavjw, so [VSP-175] applies uniformly and the only
  per-gate work is what each re-point re-measures.

  **AND THE BELIEF CAME IN, MEASURED — `test_phasec_image` SECTION 4
  (14z-132).** RED on the M16 freeze sweep and reproducible standalone:
  *"the clean leg held the victim on only 0 frames"*. **NOT caused by the
  re-point sweep** (no commit of 14z-132 touches that file) and not a memory
  artifact. **THE MECHANISM, stated as a HYPOTHESIS ([VSP-116]):** 14z-131
  measured this control's hold window — frames 3010-3056, 47 of 47 moving — on
  `build/m3b_merged22`, the MERGED build; but the gate BUILDS ITS OWN
  SINGLE-TENANT DONOVAN WIDE track (`build_donovan.sh 6`, no
  TENANT_MANIFEST, :72) and runs the rig there. A control validated on merged
  and deployed on solo. **The liveness refusal [VSP-137] that 14z-131 added is
  what turned this into a red instead of a vacuous green** — the gate declines
  to judge a leg that produced no event.
  **DISCRIMINATOR RUN 14z-132, AND BOTH OF MY HYPOTHESES WERE WRONG. ROOT
  CAUSE: A RELATIVE `$ROMDIR`. FIXED.**
  1. *"solo vs merged"* — REFUTED by measurement. The rig on `build/don_m20`
     (solo) and on `build/m3b_merged23` (merged) returns **47 held frames, 9
     distinct offsets, window 3010-3056, byte-identical offset sets** on both.
     A single-tenant build produces the hold perfectly well.
  2. *"the gate never pins MAME_BIN"* — TRUE of the gate and NOT the cause;
     pinning it changed nothing.
     **RETRACTED 14z-133: IT WAS A CAUSE — THE SECOND OF TWO.** "Pinning it
     changed nothing" was measured in a shell that already EXPORTED `MAME_BIN`,
     so every cell of that discriminator had the pin and the only variable
     left was `$ROMDIR`. Under the emulator runner — which exports nothing —
     the same gate fell through to Homebrew's `mame` ("Unknown system
     'vsavjw'"), produced no dumps, and reported the same "0 held frames".
     Measured 14z-133 as a 2×2 on the HEAD script (`MAME_BIN` set/unset ×
     `$ROMDIR` relative/absolute): the pin ALONE decides the outcome at HEAD,
     and the pre-14z-132 script fails WITH the pin and a relative `$ROMDIR`, so
     both defects stand on their own measurement (STATE 14z-133). Item 3
     below stands; it was one of two.
  3. **THE CAUSE:** section 4 runs each leg from inside its own temp dir
     (`cd "$WORK/$leg"`) with `MAME_ROMPATH="$WORK/wide/rompath;$ROMDIR"`. A
     RELATIVE `$ROMDIR` — which is how every runner invokes gates
     (`ROMDIR=../ROMS`) — then resolves against the LEG dir, finds no
     reference members, and the run produces NO DUMPS. The liveness check
     faithfully reports "0 held frames", which READS as a defect in the
     artifact and is not one. With an absolute ROMDIR: 47/47 held frames
     move, 9 offsets -> 2, PASS. Fixed by resolving ROMDIR to absolute at the
     top of the gate; the original failing invocation now passes unchanged.
  **SO THE M16 SWEEP'S ONE RED WAS A GATE DEFECT, not the artifact** — the
  same verdict 14z-128/129/130 reached about their own reds.
  **AND IT IS A CLASS, NOT AN INSTANCE — MAINTAINER'S CALL.** 20+ gates share
  the shape (they `cd` into a work dir and then use `$ROMDIR`), and none
  normalises it. They pass today only because their `$ROMDIR` use happens to
  survive the `cd`, or because nobody has run them from the wrong shape. The
  systemic fix is a one-line normalisation per gate, or a shared helper in
  `tests/lib/`. NOT swept unasked.

  **ONE FLAGGED, NOT YET WALKED:** `audit_trap_sound` is release-scope and
  defaults to `build/hui30`, a build frozen at 14z-82c — a release gate
  asserting about a build we do not ship, regardless of the merged question.

- **~~THE DISPATCH KEY — DECIDED (maintainer, 2026-09-04, 14z-132): FORWARD-ONLY
  promotion of the whole-set fingerprint, with MERGED ROWS FULL-SET-KEYED
  ONLY. NOT YET IMPLEMENTED.~~ B1 SHIPPED 14z-133 (dual-key resolver, acceptance
  met); B2 DONE 14z-133b (the first merged row, `2c926c5b -> merged-m16`,
  whole-set-keyed only; the three legacy-oracle gates on merged). Original
  entry:** Why it came up: the three legacy-oracle gates
  cannot run on the merged build until the merged build is registrable.
  **THE MEASUREMENT:** the program key collapses `build/merged1` (the
  blanks-only legacy instrument), merged-m15 and merged-m16 onto ONE value
  (`f42f7569`); `--full` separates all three (`ca7ba8ac` / `033d68cd` /
  `fcc83fc3`). That is exactly the objection `registry.tsv`'s header raises
  against a merged row, so `--full` dissolves it rather than overriding it.
  **(i) "RECOMPUTE EVERY ROW" WAS APPROVED AND IS NOT EXECUTABLE — measured:
  only 20 of 58 live rows are recomputable**, the other 38 having had their
  build dirs pruned under the N-2 policy (donovan-m2b..m16, huitzil-m16..m23,
  pyron-m10..m17 and their stock/stage-4 legs). Those rows are INERT — nothing
  can dispatch on a build that no longer exists — so re-keying them buys
  nothing and would cost 38 tag checkouts and rebuilds at an unknown failure
  rate. The maintainer's ruling on that: *"the rest is valuable history but
  just legacy, we don't lose anything."*
  **THE SHAPE THAT SHIPPED THE DECISION.** No registry FORMAT change: a row's
  key is just a sha1, and the resolver computes BOTH keys and matches a row
  against either — full-set first, program second. New rows carry the full-set
  sha; historical rows keep the program sha; the two spaces are disjoint.
  **Merged rows carry ONLY the full-set sha**, so the program-key fallback can
  never resolve the blanks instrument onto a merged expectation set.
  **THE KEY'S DEFINITION, and it is load-bearing: computed over the BUILD's
  OWN rompath directory, a `;` chain REFUSED.** `--full` is rompath-chain
  dependent (`m3b_merged23/rompath` -> `fcc83fc3`; `...;../ROMS` ->
  `544990c4`), and callers pass both forms, so without this the key depends on
  who asked. `tools/artifact_manifest.py` already refuses a `;` chain for the
  same reason. Cost measured: 0.10 s -> 0.35 s per dispatch call.
  **TWO WARTS, both accepted by the maintainer:** the registry carries two key
  kinds permanently (*"fair"*); and the fallback still cannot disambiguate a
  future program-keyed collision — though after the promotion the
  program-keyed space STOPS GROWING, so a new row-vs-row collision is
  impossible by construction. What remains possible, and is live today, is a
  NEW BUILD colliding with an EXISTING row: `build/don_m20` resolves silently
  as `donovan-m19`. Hence the loud note below.
  **THE PLAN, split so the risky half is separable:**
  **B1 (mechanism only)** — dual lookup, the key defined as above, a LOUD note
  whenever a program-key match fires (after the promotion that always means
  "not registered under a whole-set key"), `test_suite_dispatch_selftest`
  extended over both spaces with a must-fire control.
  **Acceptance: everything resolves exactly as it does today.** Reversible.
  **B2** — the three legacy-oracle gates re-pointed to merged, only after B1
  is green; open-ended, because it re-measures their expectations on merged
  and may surface real differences.
  **Ordering: B1 before M16's registration**, so M16 lands natively in the new
  scheme instead of needing a fourth comment-out row.
  **WHY NOW, in the maintainer's words:** *"our current builds are extremely
  solid and have been for some time. Were it not the case I would still agree
  but I would strengthen my rigor regarding testing even more as I wouldn't
  want side-effects invalidating or, worse, validating tests while I already
  have a flaky build."*

- **~~PYRON AS THROWER~~ RULED (maintainer, 2026-09-04): NOT A CONCERN, BUT
  KEEP THE TEST.** Verbatim: *"from a historical and practical point of view
  Pyron as thrower I don't really care about because we never had any issue
  with him. But if we have the test, might as well keep it because it is a
  good regression marker."* So `tests/audit_pyron_capture_block.sh` STAYS at
  `EXPECT_MATCH=0`, freezing the observed ours-vs-native difference as a
  regression marker; **the pose mechanism (the `PRG:0x27FAA` four-sibling
  question) is NOT to be chased** and no port of row 0x11 is scheduled.
  The maintainer's own scoping caution, recorded because it is the right
  question for any widening: *"the question becomes: do we test all victims
  or only a sample and if it's a sample how to determine it"* — today the gate
  uses ONE victim (Victor), and the per-victim axis is what
  `audit_don_grab_pose` already sweeps from the other side.

- **~~`test_phasec_image` SECTION 4 — ITS NEGATIVE CONTROL HAS BEEN DEAD SINCE
  14z-111~~ DECIDED (maintainer, 2026-09-04) AND **DONE 14z-131: OPTION (a)
  WORKED, SO THE GATE IS UPDATED, NOT DROPPED.** The ruling was *"I agree with
  your recommendation. If it works then we'll be able to update, otherwise
  we'll likely drop."* It works.
  **THE RE-TARGET:** section 4 now zeroes the 32-word PER-VICTIM OFFSET HEAD of
  Donovan's capture-keyframe blob in the extension (`capture_kf_ptr[0x13]`,
  `CPU:$4010E0` on the current freeze) and requires the hold to change.
  **MEASURED on `build/m3b_merged22`, P1 Donovan vs P2 Victor on
  `judge/02_throw.rpl`:** the hold runs 3010-3056 and the victim's offsets
  collapse from NINE distinct values (including a 181 px lift) to `(0,0)` and
  `(56,0)` — **47 of 47 held frames move**, and nothing crashes. The whole
  gate is green.
  **WHY THIS ANCHOR IS LEGITIMATE ([VSP-166], the law that stopped the naive
  re-point):** the blob's ADDRESS comes from the build's own table, but the
  ASSERTION does not — it is the victim position the GAME's vanilla positioner
  computes from those bytes. A wrong pointer makes the control FAIL LOUDLY, it
  cannot pass vacuously, which is the exact opposite of the dead-probe trap.
  The gate also asserts the pointer lands in the extension FIRST, so "the
  extension is read" is the thing under test, and it refuses to judge when the
  clean leg produced no hold or a single-valued one ([VSP-137]).
  **AND IT IS A BETTER CONTROL THAN THE ONE IT REPLACES:** the old one rode a
  CPU-AI read that the chosen replay could never trigger; this one rides a
  path the game runs every frame of every throw, in 2P as well as 1P.
  Original entry — measured 14z-130; [VSP-166] says I may not just
  re-point it.** Section 4 is the B4 lesson made permanent: it zeroes the
  0x160-byte block at `CPU:$400010`, replays `12_donovan_vs_cpu`, and requires
  behaviour to CHANGE — because "a relocation that passes without a control
  proves nothing, the data may simply never be read".
  **WHY IT IS DEAD, measured rather than inferred:** `build/don_m19`'s
  `placements.json` puts region **`x101aca` at `0x400010`** — Donovan's AI
  SCRIPT BLOCK, moved there by the 14z-111 #99 fix — where the control was
  written for the Phase-C SOUND TABLE. And the replay cannot read it:
  `12_donovan_vs_cpu` has Donovan as the PLAYER, so it is the CPU opponent's
  AI script that is read, never his ([VSE-75]: 2P versus never reads them at
  all). So zeroing it correctly changes nothing. Nineteen sessions.
  **SECTION 1 OF THE SAME GATE IS FIXED** (14z-130) and is a separate story:
  it pinned the stock fingerprint to `ae701ffb…`, the donovan-m2c twin from
  14z-64, while the stock twin has since MOVED FOUR TIMES, every move ruled
  and attributed in its own registry row. It now RESOLVES the expected value
  from the newest `*-stock` row in `registry.tsv`, so the anchor is the
  reviewed record and it cannot rot again.
  **THE OPTIONS FOR SECTION 4:**
  **(a) RE-TARGET at content the replay genuinely reads.** The honest
  candidate is the CAPTURE-KEYFRAME BLOB — Donovan's row 0x13 points at
  `0x004010e0`, which IS in `wide_ext` and IS read whenever he throws, on a
  path `audit_don_grab_pose.sh` already locks independently. That gives the
  control an anchor OUTSIDE the build's own placement metadata, which is what
  [VSP-166] requires; it needs a throw replay and a liveness check that the
  unzeroed run really does reach the capture pose.
  **(b) DROP section 4**, the `audit_type_dispatch_range` precedent
  ("better no test than a bad one") — but note this control defends a
  principle the project paid for at B4, and dropping it leaves "the extension
  is genuinely read" ungated dynamically.
  **RECOMMENDATION: (a)**, because unlike the dispatch-range case the liveness
  control here is CONSTRUCTIBLE — a throw either reaches the capture pose or
  it does not, and that is measurable without asking the build what it wrote.
  Cost: half a session. **Meanwhile the gate stays RED and honest**; it is not
  a regression from M13 (section 4 has failed since 14z-111 and section 1
  since 14z-110), and the M13 freeze itself is green on every other gate.

- **~~`audit_type_dispatch_range` PROBES A MECHANISM THAT NO LONGER EXISTS —
  UPDATE OR DROP~~ DECIDED (maintainer, 2026-09-03): DROP. Verbatim:
  *"better no test than a bad one. Let's drop"*.** EXECUTED 14z-129 — the
  script deleted, its `ci_emulator.tsv` and `gate_index.tsv` rows removed, and
  every live carrier marked in place (`engine_internals.md` keeps WHAT IT USED
  TO ASSERT, since the claim is still true of the design and is now simply
  UNGATED dynamically; `patch_index.md`, `harness_hardening_history.md` class
  6, `gen_donovan_patch.py`'s two comments, NEXT_SESSION). The ground is the
  measured one below — the verdict control cannot be rebuilt — NOT the
  superseded-by-`audit_type_writes` ground, which was measured FALSE.
  The measurement that produced [VSP-166] is kept in full. Original entry:
  The gate scrapes an `obj_hook thunk` address out of the build's
  `patch_notes_fragment.md` and probes it to see which type indices the merged
  build dispatches — "the dynamic census-gap detector for the 14z-82
  type-renumber fix". **MEASURED: `build/hui30` (14z-82c) has 2 such rows;
  `build/merged1` has ZERO**, so the scrape returns empty and the gate exits
  with `FAIL: could not scrape an obj_hook thunk address` before measuring
  anything.
  **WHY THERE ARE NONE: 14z-91 DELETED THE THUNKS.** The legacy-regression fix
  left "the obj_hook dispatch sites VANILLA — each 0x2C-byte object-pool walker
  relocated with its union table at copy+0x2C and only the 23 caller OPERANDS
  rewritten". No thunk is emitted any more, so no post-14z-91 build can satisfy
  this gate. Its reference leg still works only because `hui30` predates the
  change. **It has been unrunnable for ~37 sessions**, and like the others in
  this arc, unheard because no runner called it.
  **THE OPTIONS:**
  **(a) RE-TARGET** it at the shipped mechanism — probe the RELOCATED walker's
  union table instead of a thunk. The question it asks (which type indices does
  a merged build actually dispatch?) is still live and still worth a dynamic
  answer.
  **(b) DROP IT** as superseded, if `audit_type_writes` (the "DYNAMIC half of
  the 14z-82 type-stamp census", which maps observed family writes to the
  frozen static inventory) already covers the gap. **I have NOT established
  that it does** — the two ask different questions (which PCs WRITE a type byte
  vs which indices are DISPATCHED), and answering it is the first step either
  way.
  **MEASURED 14z-129, and the decision now rests on data rather than on a
  reading of our own generator ([VSP-166], which this arc produced).**
  **The (b) determination is DONE: `audit_type_writes` does NOT cover it.**
  Different BUILD (it runs on single-tenant builds, where the
  renumbering claim is VACUOUS — the lone tenant IS the first resolver and
  keeps originals by design), different QUESTION (which PCs WRITE a type byte
  vs which indices are DISPATCHED), and different SCOPE (`type_writes`
  explicitly DEFERS the 0x54470 family — "REPORTED per writer class … not
  gated" — which `dispatch_range` sections 4-6 lock). So "drop as superseded"
  is not available on the grounds proposed above.
  **THE RE-TARGET IS TECHNICALLY POSSIBLE — the site exists and carries the
  index.** The relocated walker's SITE is base+0x18 (its `jsr (A0)` is at
  +0x1E, and D0 is ZERO there — 8,990 fires, all `D0=0`, because the index has
  already been consumed to compute A0; probing the jsr would have produced a
  gate that reports "zero original-range dispatches" forever, a perfect false
  green). At base+0x18 D0 carries real dispatch indices: 8,990 fires over 10
  distinct values on `hui/70_hui_mash`.
  **BUT THE CONTROL CANNOT BE RECONSTITUTED, and that is what decides it.**
  The gate's verdict control requires a build that DOES dispatch original
  family indices, so the instrument is proven able to see what the merged legs
  claim is absent. Measured on the gate's own control replay and pokes:
  * `build/hui30` (14z-82c, pre-relocation, the gate's REF): thunk `0xfcb70`,
    **5,862 fires in [0x1C8,0x1E4)** — `D0` = 0x1cc / 0x1d4 / 0x1dc (types
    115 / 117 / 119). The control is alive there.
  * a CURRENT-manifest single-tenant huitzil vertical (`08944a7e`) at the
    equivalent relocated site: **8,990 fires, ZERO in [0x1C8,0x1E4)** — the
    highest value seen is 0x1b8 (type 110).
  So on modern builds the phenomenon the control depends on does not occur,
  and a re-targeted gate would assert "zero originals on merged" with NO
  liveness control — precisely what [VSP-166] forbids. **WHAT IS NOT
  ESTABLISHED: WHY** the modern single-tenant build shows no originals (the
  replay may not spawn those types on it; the renumbering may now apply to the
  first resolver too; something else). That is the one open question, and it is
  the difference between "drop, the class is gone" and "drop, we cannot
  instrument it".
  **RECOMMENDATION: DROP**, on the measured ground that the control is not
  reconstitutible — not on the superseded-by-`type_writes` ground, which is
  false. If the maintainer wants the class kept under watch instead, the
  honest replacement is not this gate but a rebuilt control leg, and that
  starts with the WHY above. Meanwhile the row stays `release` scope and RED,
  honestly.

- **~~REPLAY `105_legacy_2pwin_auto` — THE SPEC IS MEASURED AND READY TO AUTHOR;
  WHAT IS MISSING IS THE ATTRIBUTION OF TWO FRAMES (14z-128).~~ AUTHORED AND
  CLOSED 14z-128 (19), commit `9ae00420`; header corrected 14z-133b at the
  maintainer's word — the body below already said so, the header did not.** The replay
  entered the corpus at 14z-123 as LEGACY content and has been guarded by
  NOTHING since — no `.masked` spec, no self-frozen `.sha1`, in any of the
  three tenant sets. `audit_legacy_pairings` has been saying so for five
  sessions into an empty room ([VSP-103]); tonight's runner is what made it
  audible. **A census of all 88 top-level replays finds this is the ONLY hole**
  (the other expectation-less replay, `111_don_arcade_vs_screen`, is TENANT
  content and correctly has no vanilla oracle).
  **DONE:** the vanilla basis is frozen in `tests/expected/vsavj/masked-v2`
  (sha1 `41fffe38…`, 9,621 lines) under the sets' own mask, with
  `VERIFY_BASIS=01_attract_long` reproducing an already-frozen name
  bit-for-bit — the instrument control `freeze_masked_basis.sh` requires on
  every extension.
  **MEASURED, and IDENTICAL on all three builds** (`don_m18`, `hui52`,
  `pyron36` — which is itself evidence the mechanism is SHARED, not
  tenant-specific):
  ```
  shape: 1605/9620 frames differ in 3 runs, first 889, last ends 5868, then 3752 identical
  runs:  889-2491   2713-2713   5868-5868
  proposed: composite vsavj/masked-v2 2713,5868 889-2491
  ```
  **~~WHY IT IS NOT AUTHORED YET~~ AUTHORED AND CLOSED 14z-128 (19) — THIS
  ENTRY WAS LEFT LOOKING OPEN, corrected 14z-130.** The two flicker frames
  WERE attributed and the spec WAS authored, in commit `9ae00420` ("the two
  flicker frames ATTRIBUTED, and the spec authored — the five-session hole is
  closed"); `tests/expected/{donovan-m18,huitzil-m25,pyron-m19}/105_legacy_2pwin_auto.masked`
  each carry `composite vsavj/masked-v2 2713,5868 889-2491` and the M13 sets
  inherit them. The paragraph below is the state BEFORE that, kept because its
  reasoning is why the attribution was done first. Original text:
  `composite` is a non-exact class, and
  [VSP-27]/[VSP-29] require every non-exact class to be MECHANISM-ATTRIBUTED,
  with the standing watch ([VSP-31]) that flickers appearing outside a frozen
  inventory mean stop and root-cause. The WINDOW half is already attributed:
  onset 889 is the same onset every select-reaching legacy replay in these sets
  carries — the ratified select-wheel window of the 14z-115 separation. **The
  two single-frame flickers at 2713 and 5868 are NOT attributed.** The obvious
  reading — 2713 is the VS-screen transition, 5868 the KO/victory transition —
  is a HYPOTHESIS, not a measurement ([VSP-116]), and freezing an unattributed
  flicker inventory is exactly what the standing watch exists to refuse.
  **THE MEASUREMENT THAT SETTLES IT, ~20 min:** `DUMPS` of work RAM at 2713 and
  5868 on one tenant build and on pristine vsavj, diffed, with the differing
  bytes named against `docs/game/atlas/ram.md`. Then author, per set:
  ```
  echo 'composite vsavj/masked-v2 2713,5868 889-2491' \
      > tests/expected/<set>/105_legacy_2pwin_auto.masked
  ```
  **Authoring it is a STRICT tightening either way** — today the replay is
  compared against nothing, and composite adds no tolerance of its own (a
  bit-identical pair fails it). So the only question the maintainer needs to
  rule is whether to author on the measured shape now and attribute after, or
  attribute first. Recommendation: attribute first — it is one rig and the
  window has been open five sessions already.

- **THE EMULATOR-TIER RELEASE SCOPE — RULED IN FULL (maintainer, 2026-09-03).
  141 release / 23 out, and a NEW `cadence` column carries the MiSTer half.**
  All three judgement calls were ruled and all three are now IN the registry,
  not in prose:
  **(a) THE TWO #113 GATES -> `release`**, against the letter of the subject
  discriminator. Verbatim: *"51s is basically nothing for a release and still
  not enough cost not to run every time we freeze honestly."* Their rows carry
  the exception and the measured cost (23 s + 28 s).
  **(b) THE MiSTer LANE -> release scope KEPT, split onto a BITSTREAM
  CADENCE.** Verbatim: *"AGREED and given the time, it should be applied
  ALWAYS on release but not for a freeze, UNLESS explicitly in scope,
  typically because the changes target MiSTer specifically. If such an
  automation is unrealistic, the question should be asked at freeze if it
  should be included."* **THE AUTOMATION WAS REALISTIC, so it was built rather
  than left as a ritual step** — a ritual step that lives only in prose is the
  step that gets skipped (14z-126b: three freeze tags were missing for exactly
  that reason). `cadence` is `romset` (158 rows: runs at every freeze AND
  release) or `bitstream` (6 rows: runs at every RELEASE, and at a freeze only
  when the freeze targets MiSTer). `--freeze` (= `--cadence romset`) drops them
  AND NAMES THEM, printing the question. The two deliberate MiSTer exceptions:
  `test_mister_sdram_census` and `test_mister_gfxc_fetch` measure where THIS
  ROMSET lands in SDRAM, so they follow the romset and stay on every freeze.
  Only a `mister` row may be `bitstream` — enforced, so the concept cannot
  spread by column edit.
  **(c) THE FOUR `dev-ladder` GATES -> stay `out`.** `test_m3a_reproducible` is
  the real pipeline lock on the released artifact and is already release-scope.
  **AND THE TWO NON-JUDGEMENT OBSERVATIONS WERE AFFIRMED, in the maintainer's
  words: *"AGREED on both counts and this, again, is keeping ourselves honest
  and rely on measurements, not inference or likeliness at all stages."***
  So, recorded as standing readings of the column: **`out` does not mean
  "resolved"** (`audit_hitclass_map_cost` is `out` AND is one of the two dead
  must-fire controls — scope and control-health are orthogonal, [VSP-19]), and
  **`out` does not mean "quietly green"** (`audit_region_movability` and
  `audit_phase_mode_cost` are red right now with exact diagnoses; `out` is only
  what keeps them from blocking).
  Ground truth for the new column: `test_emulator_runner.sh` section 6b (five
  assertions incl. that the drop is NAMED, plus a romset-cadence control) and
  section 10's validator, whose three new rules were must-fire checked.
  **The original proposal follows.** *(Superseded head: PROPOSED 14z-128, THE MAINTAINER'S TO
  RULE.)* `tests/ci_emulator.tsv` gives every one of the 164 emulator-tier
  gates a `scope` of `release` or `out`, and that column is what
  `tests/run_all_emulator.sh` hard-fails on at release. **139 release, 25
  out.** The discriminator is the maintainer's own (STATE "RELEASE-TIME TEST
  SCOPE"): the SUBJECT of the test, not the romsets it touches. Every `out`
  row leads with a reason keyword so the judgement can be checked row by row
  rather than argued in bulk:
  **`romset:`** (12) — the subject is a reference romset's own behaviour, not
  ours: `audit_wide_phase_a`, `audit_id_writers`, `audit_palette_seq_ids`,
  `audit_ladder_selector`, `audit_df_accumulator`, `audit_df_dead_family`,
  `audit_front_comparator`, `test_advancing_guard`, `test_killshread_es`,
  `test_tick_durations`, `test_vanilla_frame_join`, `audit_sdram_bank_load`,
  plus `test_down_flash_vanilla` / `test_down_flash_mechanism` (#113's
  "vanilla, not ours" verdict — kept deliberately, and the borderline one:
  their subject is vanilla vsav but what they protect is a claim about OUR
  build).
  **`momentary:`** (7) — a specific probe for one investigation:
  `audit_ff0460_writer`, `audit_mask_window_ff42a2`, `audit_continue_ladder`,
  `audit_hitclass_map_cost`, `audit_phase_mode_cost`,
  `audit_objhook_owner_census`, `audit_region_movability`.
  **`dev-ladder:`** (4) — the subject is a scratch dev build:
  `test_m2a_stage1_nullreloc`, `test_m2a_stage2_data`, `test_m2a_stage3_anim`,
  `test_m2a_stage4_code`.
  **`out` NEVER MEANS "DO NOT RUN"** — `--scope all` runs them and the sweep
  does, because a gate nobody runs rots whether or not it gates a release.
  **THE JUDGEMENT CALLS worth a look:** (1) the two #113 gates above; (2) the
  MiSTer lane is `release` (a release ships `release/<name>/mister/`), which
  makes a release cost the Verilator lane — hours, and `--lane mister` is
  opt-in for that reason; (3) the four `dev-ladder` gates still exercise the
  BUILDER, so an argument exists for calling them release-scope pipeline
  locks. No change is needed for the arc to proceed; the ruling decides what a
  release hard-fails on.

- **~~THE `gap_be27a` / `gap_be2ba` BANK-MAP ROWS ARE WRONG~~ DECIDED
  (maintainer, 2026-09-03) AND **EXECUTED 14z-130** — folded into the M13
  registration, *"if folding it in allows us to pay only once, that's an easy
  choice: fold it in!"*.** **WHAT SHIPPED:** the two rows became ONE
  `capture_kf_ptr` (`0x0BE27A`, `data_ptr`, `stride 0x80`, `region auto`) and
  the table's hand-ownership was made explicit in the generator, so the
  generic repoint is suppressed. **BYTE-NEUTRAL on all five M13 tracks by
  rebuild** (fingerprint and `patch.json` sha1 identical either side).
  **THE [VSP-10] QUESTION THIS ENTRY RAISED DOES NOT ARISE**, because the two
  candidate pointers are not equivalent: the shipped `0x004010e0` carries
  `0x0d88` at `+0x1E` and the block the generic repoint would have chosen
  (`0x003fbda2`, the hitbox-region copy) carries the UNFIXED `0x0b30` — i.e.
  letting the generic path win would have silently reverted the 14z-64
  mirror-victim fix. Preserving today's bytes is the answer, and it is a
  preservation decision rather than a gameplay one.
  **ONE FIGURE IN THE ENTRY BELOW IS WRONG AND IS CORRECTED HERE:** it says
  "the ~9 writes per tenant that the `auto` containment currently leaves
  unexempted come back under exemption". **Measured: only ONE does** — row
  `0x18` (Oboro) — plus each tenant's OWN row where it has one (`0x13`
  donovan, `0x10` huitzil; pyron has none). Rows `0x08-0x0F` STAY in the
  inventory, correctly: they are LEGACY attacker rows. The root fix NARROWS
  the exemption; it does not restore the hole. Inventory counts D/H/P
  114/112/100 -> 115/113/102 (the +3 each is the M13 boot title).
  Detail: patch_notes 14z-130; gate `tests/test_capture_kf_ownership.sh`.
  Original entry follows. The three couplings
  that make one window cheaper than two, each verified 14z-129 rather than
  argued: (1) `charmap_gen.py` reads `bank_map.toml` directly (`--bank-map`,
  :364) and emits every table's tenant row, and those pages are hash-locked by
  `tests/expected/charmap_pages.sha256` — so a fix moves them and owes a
  charmap re-freeze; (2) `tests/test_m3a_reproducible.sh` pins fingerprints per
  freeze generation, so a bank_map change landing AFTER M13 is registered makes
  the registered fingerprints stale; (3) `build/manifest/shared_writes.toml` is
  per-build and per-write reviewed, M13 already owes it a re-point (the three
  `boot_title_saved_*` rows per tenant, reviewed at 14z-127), and the
  correction changes the exemption window — the ~9 writes per tenant that the
  `auto` containment currently leaves unexempted come back under exemption — so
  separating the two costs a SECOND review pass. The M13 builds exist on disk
  (`don_m19` / `hui53` / `pyron37` / `m5_stock14` / `m3b_merged22`) and are NOT
  in `registry.tsv`, so nothing is locked to them yet: this is the cheapest
  moment in the cycle to disturb them. **If the rebuild shows a named op delta
  rather than zero movement, that delta is understood BEFORE the freeze suite
  runs, not after.** Original entry follows. `bank_map.toml` models
  ONE 32-long table — the capture-keyframe pointer table `PRG:0x0BE27A`,
  entry size 4 — as TWO `kind = "auto"` rows of `stride = 0x40`, i.e. as two
  32-entry WORD tables. **Measured three ways that the entries are longwords:**
  bank_map's own `note` calls it "the 32-LONG capture-keyframe pointer table";
  `donovan.toml`'s `slot_ptr_table = 0xBE27A` places row 0x00 at 0xBE27A and
  row 0x01 at 0xBE27E; the values written are 32-bit ROM pointers.
  **Two consequences already measured.** (1) `audit_shared_writes.py` computes
  its variant-row exemption as `base + 0x10*es .. base + 0x20*es` with
  `es = stride/32`, so the wrong stride put the exemption on LONGWORD ROWS
  0x08-0x0F — eight LEGACY rows — and nine writes per tenant were invisible to
  the shared-surface guard. CONTAINED 14z-128 (a `kind = "auto"` row now grants
  no exemption at all), not fixed at the root. (2) The generated
  character-data pages read both rows at the wrong address —
  `docs/project/tables/chars/huitzil.md` prints `gap_be27a` at `0x0be29a`,
  which is BISHAMON's longword row, and donovan's `0x0be2a0` is not even
  4-aligned.
  **WHY IT IS NOT FIXED HERE:** the correction is one row
  (`vsavj = 0x0BE27A`, `kind = "data_ptr"`, `stride = 0x80`) replacing two,
  and the tiling is preserved exactly (0xBE27A + 0x80 = 0xBE2FA = `param32_b`).
  But `kind` is LOAD-BEARING: `extract_char.py` takes a different extraction
  path for `auto` than for `data_ptr` (:1289 vs :1321) and
  `gen_donovan_patch.py` gives `data_ptr`/`code_ptr` tables pointer treatment
  (:3514). So it can move BUILD OUTPUT, which makes it a measured change with
  a rebuild and a diff, not a manifest tidy.
  **PROBED 14z-129 (the measurement the ruling asked for, run before the M13
  window opens so its cost is known going in). THE ONE-ROW CORRECTION DOES NOT
  BUILD, AND THE REAL SHAPE IS AN OWNERSHIP QUESTION.** Two findings, in order:
  1. **`kind = "data_ptr"` + `stride = 0x80` is INCOMPLETE.** A `data_ptr` row
     also requires a `region` key — `extract_char.py:1291` dies
     `KeyError: 'region'` without one. `region = "auto"` is the right value
     (the 14z-111 #99 handling: the pointer's host is whichever extracted
     region contains it), and with it the build proceeds.
  2. **IT THEN COLLIDES, and the builder catches it:**
     `OP OVERLAP at 0x0BE2C6: op[86] poke32@0xbe2c6 then op[192] poke32@0xbe2c6
     — two ops write the same word and the later silently wins. Fix the
     generator (explicit ownership); do not reorder ops.`
     `0xBE2C6` is longword row **19 = 0x13 — DONOVAN's own slot**. The two
     values disagree: op[86] writes `0x003fbda2` (his placed region), op[192]
     writes `0x004010e0` (wide_ext). Ops 342 -> 343.
  **WHY IT COLLIDES:** modelled correctly, `gap_be27a` is a 32-long pointer
  table and the generic `data_ptr` path emits a pointer for every row —
  INCLUDING row 0x13, which `donovan.toml`'s `throw_victim_keyframes` /
  `grab_hold_keyframes` rows already repoint individually
  (`slot_ptr_table = 0xBE27A`, donovan.toml:831). While the row was `auto`
  with the wrong stride it emitted nothing there, so the conflict was hidden
  by the very defect being fixed.
  **SO THE M13 FOLD-IN IS NOT A MANIFEST TIDY.** It needs an explicit
  ownership rule between the bank_map table and the per-row repoint rows, and
  the rule decides which pointer Donovan's capture keyframes use — a
  throw/capture surface, so if the two values are not equivalent it is a
  [VSP-10] call, not a generator detail. Budget accordingly; the probe cost
  one build.
  **The tree is UNCHANGED — `bank_map.toml` was reverted and verified
  byte-identical to its pre-probe state.**

  **RECOMMENDED (and RULED — see the head of this entry):** do it in a
  build-touching window — rebuild one track,
  diff `patch.json` against the current freeze, and expect either zero op
  movement (then it is a pure map fix + a charmap re-freeze) or a named delta
  that has to be understood before it ships. Half a session. Meanwhile the
  containment holds and `tests/test_shared_writes.sh` section 4 locks it.
  **AND THE OTHER `kind = "auto"` ROWS ARE UNAUDITED:** 21 of them exist; only
  these two were exempting anything, but none of their strides is a
  measurement.

- **THE BOOT NAME SCREEN: "SAVIOR" -> "SAVED" — DECIDED AND SPECIFIED
  (maintainer, 2026-09-02), BUILT 14z-127 ON ALL FIVE TRACKS (mark M13),
  ~~NOT YET REGISTERED — the registration is the arc's own next step~~
  REGISTERED AND FROZEN 14z-130 as donovan-m19 / huitzil-m26 / pyron-m20 /
  merged-m15 (header corrected 14z-134; the "WHY NOT BUILT YET" paragraph
  below is the pre-freeze state, kept).** Scoped and measured 14z-127; the
  mechanism and the trap are in `docs/game/gotchas.md` "THE BOOT NAME SCREEN'S
  DISPLAY SCRIPT TAKES AN EVEN COLUMN".
  **THE EDIT, at its strict minimum (maintainer: "minimal change (i.e. e, d,
  space instead of i, o, r) is perfect for me"):**
  one `data` op, **`PRG:0x01C822`, 6 bytes word-aligned, `" I O R"` ->
  `" E D  "`** — 3 bytes actually differ (`0x01C823` I->E, `0x01C825` O->D,
  `0x01C827` R->space). One program member — **`vm3j.03d`**, ~~`vm3j.10b`~~
  **CORRECTED 14z-130**: measured by member diff on all three tracks at the
  M13 freeze (merged-m14 -> merged-m15, donovan-m18 -> m19, and the stock
  twin), the changed program member is `vm3j.03d` every time. The three
  differing bytes are at ODD addresses (0x01C823/25/27) and vm3j.03d is the
  odd half of the first program pair, so it could not have been anything
  else. The start-COLUMN byte
  is NOT touched: the shorter title simply ends one character earlier and sits
  marginally left of where it did. **Verified: the minimal-span build is
  BYTE-IDENTICAL to the 30-byte-span build that was booted and photographed.**
  **BLAST RADIUS, MEASURED not argued:** work-RAM checksums patched-vs-pristine
  are **IDENTICAL across 1,621 frames of boot and attract**, so no RAM-basis
  expectation moves and the legacy corpus does NOT re-freeze. Same length, so no
  relocation and no shifted coordinates. It is TEXT, not authored tiles — the
  glyphs are an existing gfx-ROM font, reused, so no tile or font work.
  **SCOPE, ruled the same day:** JAPAN entry only (`0x01C806`'s first record) —
  *"Our region of reference is Japan anyway"*; the other six region entries are
  left alone. **The TITLE SCREEN is NOT touched** — *"the fact that the
  character wheel is different is differentiator enough"*.
  **AND A STANDING PRINCIPLE, in the maintainer's words:** *"staff references
  should be intact, after all it's a Capcom game made by Capcom staff, and
  especially since we restored dead code from them, virtually nothing we did was
  a true novelty compared to their creations."* So the staff-roll strings
  (`PRG:0x01301A`, `PRG:0x01D96A`) are NOT to be edited, now or later.
  **WHY NOT BUILT YET:** a manifest row means a rebuild and a re-freeze (new
  fingerprint, registry row, patch_notes, battery). Fold it into the next
  freeze rather than opening one mid-session.

- **#112's FIX — DECIDED (maintainer, 2026-09-02): (C) DO NOTHING TO THE
  BUILD — *"yes it's (C) BUT we keep the option (B) fix as possible in the
  future because depending on the scoping, it may still be a valuable
  option."* So (C) is the ruling for now and **(B) IS NOT CLOSED**: it stays a
  live candidate whose value the scoping below decides. (A) remains refused.
  The half-session that would let (B) be costed — is there a FREE PALETTE ROW,
  and do pool objects carry `+0x30`/`+0x382`/`+0x3AE`/`+0x18B`? — is
  UNSCHEDULED but no longer hypothetical: it is the gate on a decision the
  maintainer has explicitly left open. Scoped 2026-09-01 at their direction
  ("I'd want to scope the second properly before recommending it -> do it").**
  **THE SELECTION POINT, measured:** the palette source is
  `base + seq_id*32` with the base CONSTANT — Donovan's `+0x3A4` is written
  exactly twice in a 14,375-frame run (round starts, `PC 0x01C68E`, value
  `0x0CEB50`) and `[0x38C1E4]` holds the same pointer. So nothing about the
  base or the blocks varies: **only the SEQ ID does** — `1` for the default
  (Donovan's body palette, idx14 = `f111`) and `46` for the effect
  (idx14 = `fcff`). The black foot is seq 1 being re-requested 29 frames
  before the pool object finishes drawing.
  **THE PIECES AND WHO OWNS THEM** (all verified against `vanilla_op/data`):
  the copy routine `0x02AD20-0x02AD80` is VANILLA, byte-identical; the base
  pointer at `[0x38C1E4]`, the palette blocks at `0x0CEB50+`, the char-table
  row for id `0x13`, the resolver hook at `PRG:0x3FFAF0` and the palette
  animator at `PRG:0x471560` are ALL OURS (vanilla holds `0xFF` filler or a
  different pointer at each).
  **AND THE PORT ALREADY HAS OWNER-AWARE EFFECT PALETTES.** `0x3FFAF0`'s
  second branch reads the drawing object's OWNER (`+0x30`) and, if the owner
  is Donovan, resolves `[0x38C1E4] + owner(+0x3AE)*128`. It exists and is
  shipped — but it is NOT exercised here: all 24 palette writes in the window
  carry `A6 = $FF8400`, the PLAYER. The effect's sprites simply draw with
  pal row `0b`, which the player's machinery fills.
  **OPTIONS:**
  **(A) Delay the revert** — gate the seq-1 request while an owned effect is
  alive. Smallest byte-wise, WORST placed: the request site is on a path every
  character runs, so it needs a tenant-only condition on legacy-reachable
  code, plus a flicker-inventory measurement. It also changes WHEN a legacy
  data path writes, which is the class the superset invariant exists to
  refuse. NOT RECOMMENDED without a much stronger reason than a cosmetic.
  **(B) KEPT OPEN AS A FUTURE OPTION (maintainer, 2026-09-02) — The effect owns its palette** — make the pool object request its own
  palette into its own row via the EXISTING owner branch. Architecturally
  right and reuses shipped machinery. **COST, and it is the reason this is not
  free: it needs a FREE PALETTE ROW** (unmeasured, and rows are scarce), the
  pool object must carry the fields the hook reads (`+0x30`, `+0x382`,
  `+0x3AE`, `+0x18B` — none verified present on pool objects), and every
  effect sprite record must be repointed to the new row. Two to three
  sessions, and a new render gate.
  **(C) RULED (maintainer, 2026-09-02) — DO NOTHING TO THE BUILD, and say why
  in the docs.** The
  defect is one palette entry on one frame of one super, on a build the
  maintainer has already accepted as cosmetically imperfect. What CHANGED
  today is not the cost of a fix but the QUALITY OF THE RECORD: the mechanism
  is fully known, the 2026-08-28 "vanilla data" objection is retired as
  FALSE, and the work is now a scoped engineering task rather than an
  unknown. That is worth banking without spending a freeze on it.
  **WHAT IS STILL UNMEASURED, and (B) cannot be costed without it:** whether a
  free palette row exists, and whether pool objects carry the four fields the
  owner branch reads. Both are half a session.

- **DARK FORCE STOCK COST FOR THE TENANTS (14z-120, found by the naming rig). DECIDED (maintainer, 2026-08-30): option (a) — the character-specific DF at VS (vanilla) cost is ON PURPOSE; "vanilla stays untouched and guides how the game should be played"; adjustments, if any, will be per character, never to the general mechanic.** On native vs2 Donovan's Slay Shred spends TWO stocks (`+0x109` 9 -> 7 at activation; Huitzil measured the same 14z-69); on our vsav engine every Dark Force, tenants included, spends ONE (the two engines run different DF systems, [VSE-69]). So a tenant's DF is cheaper here than at home. Options: (a) keep vsav's 1 stock — every character in this cabinet pays the same, "vanilla wins ties" [VSP-21]; (b) charge the tenants VS2's 2 stocks (a per-character cost hook the vsav engine does not have — new code on the DF path). **Recommendation: (a).** Note also (maintainer, 14z-120): Phobos's and Pyron's physics rows were CHECKED — `port_param32 = true` in both manifests and every value field of the 32-row bank equals VS2 for all three tenants (the map, `docs/project/tables/chars/*.json`; only relocated pointers differ). What the bank does NOT cover — throw-arc rows, hit-freeze tuning, the generation-drift class [VSE-6] — is phase 2's measurement.

- **DONOVAN'S PHYSICS ROWS (14z-118, found by the character-data map). DECIDED (maintainer, 2026-08-29): "use VS2 parameters and not the shell character's" — option (a); `port_param32 = true` set, probe + soak below, freeze at the next battery. **FROZEN 14z-119 as donovan-m18 / merged-m14 (M12); the stock twin moved with it, by design — STATE 14z-119.**
  `param32_a` (walk fwd/back), `param32_b` and `jump_params` (three jumps x
  xv/xaccel/yv/gravity) are NOT ported for Donovan: `build/manifest/donovan.toml`
  carries no `port_param32 = true`, so gen's `VALUE_SKIP` leaves his bank
  rows at the vsavj alias — **Victor's** values (row `0x03`). Measured on
  `build/don_m17`: walk 2.5 / −2.25 vs VS2's 3.0 / −2.625; back-jump xv
  −3.625 vs −4.25, neutral yv 8.0 vs 7.75, forward yv 8.0 vs 7.875, gravity
  −0.352 vs −0.375 (16.16). Huitzil (14z-66, after his own soak) and Pyron
  port theirs. The skip was the 14w-b crash guard written for the slot-0x0F
  port ("Jedah speeds retained"); whether the hazard survives the move to a
  variant id was never re-examined for Donovan. **Options:** (a) set
  `port_param32 = true` for Donovan and run the same soak battery Huitzil
  ran (RECOMMENDED — VS2-faithful movement is the project's default; the
  cost is one freeze); (b) keep Victor's physics deliberately (record it as
  a tuning decision in `charmap_donovan.toml`'s header so the map stops
  flagging it). Gameplay feel: the maintainer's call.

- **THE `docs/project/tables/` PROMISE (14z-118, from the documentation
  audit's inventory `docs/project/doc_audit_14z118.md` §3). DECIDED
  (maintainer, 2026-08-29): option (a) — generate the two missing
  manifests and refresh all three.** The
  directory's README says "per-character data manifests for Donovan /
  Huitzil / Pyron" and still opens with "Empty until a ported character
  exists"; it holds `donovan.md` (2026-08-09, never refreshed) and no
  Huitzil or Pyron file. CLAUDE.md §2 rule 5 ([VSP-6]) makes these the
  community-facing tunables. Options: **(a) generate `huitzil.md` /
  `pyron.md` with the extractor that produced `donovan.md` and refresh all
  three from the current manifests — RECOMMENDED, it is what the rule
  says;** (b) retract the promise and name `build/manifest/*.toml` as the
  table of record. Blocks audit step 5 only; steps 1-4 proceed.

- **THE TENANTS' WIN QUOTES — FORGONE FOR NOW (maintainer, 2026-08-28,
  14z-116). DECIDED.** The ruling, verbatim in substance: *"Let's forgo for
  now but document everything so that, should we want to do it in the
  future. And should we ever do it, we'd do it the clean way, not touching
  vanilla."* So this is PARKED, not closed, and it is parked WITH A
  CONSTRAINT ON ANY FUTURE ATTEMPT: **the clean way only — the vanilla bank,
  the four-entry region root, tables A/B and `RAM:$FFF230`'s vanilla value
  all stay byte-identical. The 14z-76 whole-bank relocation is RULED OUT by
  this decision, not merely un-preferred.** The buildable shape is the one
  measured below (group C bank 5's blank font window + the shipping
  `winquote_bank_variant_id` gate + one tenant-only selector thunk), and the
  single open measurement before it could be scoped is named there. Nothing
  in the tree needs undoing: Phase 0 shipped only tools, a gate and
  corrections. Everything below is the measurement record.

  PHASE 0 AS MEASURED (14z-116): The maintainer's framing for this task: cosmetic, no 2P surface,
  so equip the suite against a silent state poison — and **forgo it outright
  if the implementation carries structural risk or costs compatibility**.
  Phase 0 was run before any shipped byte. What it found:
  - **A data-only fix is IMPOSSIBLE, confirmed.** `tools/scan_quote_window.py`
    re-derived the 14z-76 prose claim as a script: **zero** runs of `0x20`+
    free bytes within `±0x8000` of the bank base, and zero around any of the
    16 winner blocks (the second hop). A control at `0x8` finds exactly one
    9-byte run, so the scanner is not blind.
  - **The 14z-76 relocation plan is wrong in three places** (all corrected in
    place, `engine_internals.md` §8 + the `patch_index.md` header): the root
    is a FOUR-ENTRY REGION array whose other three banks are the ENGLISH
    text, not one long; the bank is `0x4104` bytes, not `0x40DC`; and lines
    can be 17 codes — the real bound is the renderer's own 66-word buffer,
    which is exactly what a bad offset overruns.
  - **The relocation is NOT legacy-invisible.** `move.l a1,$30(a4)` installs
    an absolute bank pointer at `RAM:$FFF230`, measured live during the
    VANILLA win screen (replay 23 `0x00331136`, replay 28 `0x0033101E`). So
    the deferral's "change one long" would move legacy work RAM on every
    win-reaching replay and buy a permanent superset-invariant tax, with a
    new ratified class per replay, for a cosmetic.
  - **THE REAL COST IS GLYPHS, and nobody had measured it.** The three vs2
    tenant blocks use 331 distinct codes; at the shared font base **326 of
    327 non-pad codes draw a DIFFERENT character in vsavj**. Every glyph
    DOES exist in vsavj — but at tiles `0x22000-0x2FFFF`, gfx **bank 1**,
    unreachable from a 12-bit code in the quote object's bank — and vsavj's
    bank-0 font window is **4096/4096 non-blank**, so there is no free slot
    to remap into. A code remap cannot fix this: ~330 glyph tiles must
    travel, which no version of the 14z-76 plan budgeted.
  - **AND THERE IS A CLEAN ROUTE, if you want it.** Group C **bank 5's**
    font window (in-group `0x13800-0x147FF`) is **4096/4096 blank** on
    `build/m3b_merged18`, and the shipping `winquote_bank_variant_id` gate
    (14z-62j, `site 0x05F328`, `only_variant_slot`) already flips the
    win-quote drawer to bank 5 on a TENANT WIN ONLY. So the glyphs can be
    authored into space we own, by the same mechanism the 14z-115 outline
    sprites used, with **no vanilla tile touched**; the text would ride one
    `site_thunk` on the selector for winner `>= 0x10`, leaving the vanilla
    bank, the root array and `$FFF230`'s vanilla value byte-identical.
    **NOT YET MEASURED, and it is the one thing left before a build could be
    scoped:** whether the TEXT object (set up at `PRG:0x00C840-0x00C862`,
    fed by `$30(a4)`) takes its bank from the same field that gate writes —
    the gate patches the drawer object at `0x5F328`, which is a different
    chain. If it does not, the thunk writes the bank itself.
  **THE PRICE THAT DECIDED IT:** ~330 authored glyph tiles + a thunk on a
  legacy-reachable site + a new win-quote RENDER gate (pixels — no RAM gate
  can ever see text), for a single-player cosmetic surface the standing
  "cosmetic is optional" scope calls nice-to-have. **RESUMING IT LATER
  COSTS NOTHING EXTRA**: the decoder, the font audit, the reach scan and the
  structure gate are all in the tree and green, so a future session starts
  at Phase 1 with the one open measurement, not at archaeology.

- **THE MiSTer SCOPE DOCUMENT — three decisions, ALL DECIDED (maintainer,
  2026-08-28, 14z-113; `docs/project/mister_scope.md` §8).**
  (1) **The split stands as written** ("in line with what I would do";
  the maintainer defers on the CPS-II-vs-VS specifics and follows the
  recommendation, MRA mechanics at level 1 included).
  (2) **The staleness pass (S1-S20) is MANDATORY before any distillation
  — but WAITS for the board results the maintainer is producing in
  parallel right now** (the #113 hand check and bundle 14z112's stock
  coexistence), so the pass lands on a settled state and does not have to
  be re-done. **Sequencing: board results -> record them -> the S1-S20
  pass (one commit) -> only then the skills.**
  (3) **The `.rbf` AND the MRAs are TRACKED IN-TREE** — the maintainer's
  ruling: they belong with any BPS/xdelta used to patch vanilla ROMs, i.e.
  under `release/`. **This opens a NEW item, the MiSTer RELEASE FORMAT**
  (below): what a `release/<name>/` carries for MiSTer, how and where it is
  generated, and its provenance record.

- **DOES THE STOCK CONTROL MRA STILL HAVE A USE? (maintainer's question,
  2026-08-28, after it booted fine on bundle 14z112.) DECIDED (maintainer,
  2026-08-29, 14z-118): KEEP IT, RE-SCOPED — run once per NEW `.rbf`
  (seed / slice / pin), off the per-release checklist; stays in every
  release's `mister/`. The recommendation as it was put:** It was built (14z-109) to separate a fault in our
  PROFILE from one in the bitstream/card/module/video chain, at a time when
  the bundle's `vsav.zip` was patched and no stock MRA could serve as a
  control. Two of its three jobs are now done by something else: a stock
  MRA on Jotego's own core covers "the board/card/module is fine" (and it
  just did), and the shared pristine `vsav.zip` means no bundle can poison
  stock art any more. **The job nothing else does: it is the EMULATOR
  SUPERSET INVARIANT ON SILICON** — stock `vsavj` running on OUR `.rbf`
  with the profile bit at the `0xFF` fill, i.e. CLAUDE.md rule 1 v2's
  "the patched binary running stock is untouched by construction",
  measured on hardware rather than in Verilator (`test_mister_wide_inert`
  is the simulated form). That claim is about the BITSTREAM, so the control
  needs running **once per new `.rbf` (new seed / new slice / new pin),
  NOT per romset release** — the `.rbf` has not changed since 14z-108, so
  today's pass covers it until the next synthesis. Cost of keeping: one
  XML file in the bundle and one line in the README. Recommendation: keep
  it in the release format (the MRAs are tracked in-tree now), label it
  "run when the bitstream changes", and drop it from the per-release
  checklist. Dropping it outright is also defensible — the maintainer's
  call; no gameplay surface.

- **THE RELEASE FORMAT — DECIDED (maintainer, 2026-08-28, 14z-113) AND
  IMPLEMENTED FOR merged-m10.** The ruling, verbatim in substance: the
  `release/<name>/` recommendation below is accepted WITH the caveat that
  **each platform is self-sufficient per format — not every file at the
  same level; each platform directory holds everything that platform needs
  and only that** (FBNeo needs nothing MiSTer and vice-versa; platform
  drivers packaged with their platform), and **every version releases all
  platforms even when the change touched one.** Two details I asked and the
  maintainer chose: the patch set is COPIED into each platform dir (not one
  shared dir + per-platform zips); FBNeo/MAME carry the driver PATCH + build
  recipe, not binaries. Spec `docs/project/release_format.md`; producer
  `tools/package_release_platforms.py`; gate `test_release_roundtrip.sh`
  §4; first instance `release/merged-m10/{fbneo,mame,mister}/` (manifests
  byte-identical). **Refined the same day (maintainer): the bitstream is a
  BUILD RESOURCE, canonical at `release/bitstreams/<seed>/` with `CURRENT`,
  hash-verified into every release, never copied from another release** —
  the `.rbf` (seed 18269, sha256 `46fc74af…`) is in the tree there and in
  `merged-m10/mister/`. The recommendation as it was put:
  *What ships.* `jtcps2w.rbf` (3.1 MB; GPL-3.0 output of a public fork, not
  ROM content — rule 7 is not engaged), the two MRAs (WIDE + the
  `[STOCK CONTROL]` reference leg — XML metadata: names, CRCs, offsets), and
  a provenance record: fork pin, **seed, reported slack, sha256, build
  datestamp** (the hash identifies the artefact, the seed the result —
  `mister.md` "REPRODUCING THE SHIPPING BITSTREAM"). NOT the `.rom`
  (ROM-derived, rule 7) and NOT any zip.
  *Where.* Recommendation: **inside the same `release/<name>/` as the
  xdelta package**, e.g. `release/merged-m9/mister/{jtcps2w.rbf, *.mra,
  BITSTREAM.txt}` — one release = one directory for all three
  implementations, which is what `package_release.py` already promised
  ("MiSTer later adds a DISTRIBUTION layer over the SAME members", HANDOFF).
  Alternative: a separate `release/mister/` keyed by bitstream, since the
  `.rbf` changes on a DIFFERENT cadence from the romset (it did not move
  from 14z-108 to 14z-112 while the romset moved three times). The two can
  coexist: the bitstream lives once under `release/mister/<seed>/` and each
  romset release's `mister/` holds the MRAs plus a pointer to the bitstream
  it was verified with.
  *How generated.* The MRAs already come from `tools/mister_mra.sh --no-rom`
  (ROM-free, deterministic); the bundle assembly is by hand today
  (`../mister_fieldtest_14z11x/` + README + FIELD_TRIAGE). The natural home
  is a `--mister` mode of `tools/package_release.py` (or a sibling
  `package_mister.py`) that copies the MRAs, verifies the `.rbf` against the
  recorded sha256 and refuses on mismatch, writes the provenance record,
  and runs `check_mra_parts.py` against the release's own members. Gate:
  `test_release_roundtrip.sh` gains a MiSTer leg (MRA parts resolve, hash
  matches record).
  *What it retires.* The out-of-tree field bundles as the only carrier, and
  S18 of the scope document (the untracked `.rbf` path).
  **Not started; waits behind the board results and the staleness pass by
  the maintainer's own sequencing.** No gameplay surface.

- **#112 — ROOT-CAUSED 2026-09-01 (14z-126b): AN OVERWRITE RACE ON PALETTE
  ROW `0b` INDEX 14. Still cosmetic, still accepted — this is knowledge, not a
  fix.** The foot is **row `0b` index 14**, NOT row 05. Row `0b` is written by
  VANILLA engine code (`PRG:0x02AD64` + `PRG:0x02AD78`, a 16-entry palette
  copy; both well below the relocated tenant region). Index 14's DEFAULT value
  is `f111` = rgb(17,17,17), near-black; the effect's own load writes `fcff`,
  bright cyan. Measured over f13400-14375 with `tests/lua/tap_writes.lua`
  (memory tap, no debugger, so playback stays frame-exact): **24 writes to
  index 14, only TWO of them `fcff` — one per Press of Death.**
  * CLEAN: `fcff` at **f13589** survives 56 frames to the foot draw at
    **f13645**.
  * BLACK: `fcff` at **f14313** is **OVERWRITTEN back to `f111` at f14341**,
    29 frames before the foot draws at **f14370**.
  Both values come from the SAME PC, so it is the SOURCE that differs — two
  palette-sequence requests racing, not a bad code path. That is why it is
  intermittent and cannot be reproduced on demand, and it is consistent with
  14z-112's own "the move only reaches the lift phase on some outcomes".
  **THREE PRIOR CLAIMS RETRACTED, all measured on merged-m14:** (a) "draws
  `bbe5`/`bbea` at pal 05 where every clean instance draws `0xe768-0xe796`" —
  those are DIFFERENT ANIMATION PHASES; clean f13645 and black f14370 have
  BYTE-IDENTICAL pal-05 entries (16 codes, same attrs/sizes, same `a18`/`a19`,
  differing only in x/y); (b) "real art fetched from the wrong place" — same
  art, same composed addresses; (c) "not a palette fault" — it IS one, on row
  `0b`. Row 05 is genuinely constant across the whole 14,400-frame run, which
  is why checking it alone said "no palette fault".
  **THE FOOT<->ROW LINK IS NOW CAUSAL, NOT CORRELATIONAL (2026-09-01, after
  the maintainer asked "is it truly complete?" — it was NOT).** As first
  published, "the foot is row `0b` index 14" was ASSERTED from a colour
  coincidence (`f111` = rgb(17,17,17) being the commonest colour near the
  effect) and from comparing pixel boxes at the SAME SCREEN COORDINATES in two
  frames where the effect sits at DIFFERENT positions — i.e. mismatched
  content. That was correlation dressed as a root cause. **Replaced by an
  INTERVENTION:** forcing `$90C17C` = `fcff` across the black frame moves
  EXACTLY 7,007 pixels, every one of them rgb(17,17,17) -> rgb(204,255,255),
  and the black sole and toes vanish from the snapshot. **Control fired:**
  poking the neighbouring entry `$90C17A` moves 8,898 DISJOINT pixels, none of
  them black — so the attribution is index-specific. Gated as
  `tests/test_pod_black_foot_palette.sh`.
  **LANGUAGE CORRECTED: "race" was too strong.** What is measured is an
  OVERWRITE with an ordering: the effect's `fcff` load is followed, before the
  sprite draws, by another write from the SAME palette-copy routine putting
  `f111` back. Whether two requests genuinely race or the ordering is
  deterministic is NOT established.
  **THE DETAIL CHAIN, dug out 2026-09-01 at the maintainer's direction.**
  * **The writer is VANILLA code, byte-identical to pristine vsavj**
    (`PRG:0x02AD20-0x02AD80`, verified against `vanilla_data.bin`). It is a
    generic 16-entry palette copy: dest row from `+0x18B` of the object,
    source from `a0`, and it preserves the destination's top nibble
    (`andi.l #$f000f000`).
  * **Its resolver entry (`0x02AD20`) is a TWO-LEVEL lookup:**
    `a0 = charPaletteBase[(a6+0x382)] + (seq_id & 0xFFF)*32`, with the
    per-character base table at **`PRG:0x38C218`**. `0x02AD3C` is a SECOND
    entry point with `a0` preloaded, and that is the one our writes come
    through — so the caller, not this table, chose the block.
  * **The two source blocks are FOUND:** `PRG:0x0CF110` is the CLEAN one
    (idx 14 = `fcff`) and `PRG:0x0CEB70` the BLACK one (idx 14 = `f111`).
  * **PROVENANCE, AND IT IS THE ANSWER TO THE FIX QUESTION: BOTH BLOCKS ARE
    OURS.** Pristine vsavj holds `0xFF` FILLER at both addresses — unused ROM
    space the port allocated. The char-table row for id `0x13` is also ours
    (vanilla aliases Donovan's slot to `0x393460`, Victor's base; the port
    repoints it to `0x0FF180`). The routine itself is untouched vanilla.
  **SO THE 2026-08-28 REFUSAL OF OPTION (b) RESTED ON A FALSE PREMISE.** It
  read "the sequence is vanilla vsavj data, so editing it breaks the superset
  invariant". The palette data in play is NOT vanilla — it is port-authored
  bytes in filler vanilla never reads. **That does NOT by itself make a fix
  right** (see the caution below); it means the risk must be re-assessed
  rather than assumed. Maintainer's call ([VSP-10]).
  **THE CAUTION, and it is why no fix is proposed here:** what differs
  between clean and black is WHICH BLOCK IS SELECTED, not what the blocks
  contain. Block `0x0CEB70` is used for 22 of the 24 index-14 writes in the
  window, so `f111` is presumably correct for its other uses; editing it
  would be a WORKAROUND that could damage them. A sound fix targets the
  SELECTION.
  **CLOSED 2026-09-01 — `a0` MEASURED** with `tap_writes.lua`'s existing
  `REGLOG` (no tooling needed; its own comment says it exists to "name the
  source table pointers for computed cursors"). Every index-14 write in
  f13400-14375 carries **`A6 = 0x00FF8400`, P1's FIGHTER BLOCK** — the same
  object every time — and the source varies: `0x0CEB70` (idx 0, the DEFAULT,
  20 of 24 writes), `0x0CF050` (39), `0x0CF070` (40), `0x0CF110` (**45**, the
  effect's own, idx14 = `fcff`).
  **THE TIMELINE IS THE WHOLE MECHANISM:**
  * CLEAN — seq 45 loaded f13589, **foot draws f13645**, revert to seq 0 at
    f13697: the revert lands 108 frames after the load, PAST the draw.
  * BLACK — seq 45 loaded f14313, **revert to seq 0 at f14341**, foot draws
    f14370: the revert lands 28 frames after the load, 29 frames BEFORE it.
  **THE TWO TIMELINES ARE DECOUPLED BY DESIGN: the palette is requested by the
  PLAYER OBJECT's state machine (`$FF8400`), while the foot sprite is drawn by
  a SEPARATE POOL OBJECT with its own lifetime.** When the player's state
  advances and reverts the palette before the pool object has finished
  drawing, the sprite renders against the default block. That is why it is
  intermittent, why it cannot be reproduced on demand, and why nothing about
  the tiles, the records or the addresses was ever wrong.
  **THE TRIGGER, MEASURED 11/11 (2026-09-02, the maintainer's question "why
  such a specific issue, on a single move, and not even all the time?"):
  DONOVAN IS HIT WHILE HIS OWN EFFECT IS STILL DRAWING.** The effect palette
  (seq 46) has a FIXED nominal lifetime: across the whole recording it is
  loaded ELEVEN times and survives 108/108/109x7/144 frames — except once, at
  f14313, where it survives **28**. That one load is the ONLY one whose window
  contains P1 taking damage (`hp1` 203 -> 201 exactly at the f14341 revert
  frame). Being hit moves the player's state machine to a reaction, which
  re-requests his DEFAULT body palette (seq 1); the pool object is still
  drawing and borrows his row, so it renders against the wrong block.
  **So the answer to "why only this move, and not always" is exact:** the move
  is a super whose effect OUTLIVES the player's state (~109 frames), and the
  condition is GETTING HIT during that window. Ten clean instances, none hit,
  all held the palette for its full lifetime. **This also RETRACTS the earlier
  guess** that the state advanced at outcome-dependent speeds — it does not;
  the lifetime is fixed and only an interruption shortens it.
  **WHAT A FIX WOULD TARGET, now the mechanism is known:** the LIFETIME
  RELATIONSHIP, not the palette bytes — either the player's revert waits for
  the effect, or the effect owns its palette instead of borrowing the
  player's. Both are gameplay-adjacent and neither is Claude's to choose
  ([VSP-10]). What IS now known is that the bytes in play are OURS, so the
  superset invariant is not the obstacle it was believed to be.
  **A method note worth keeping:** the first discriminator appeared to REFUTE
  this (three clean instances carried the "black" row `0b`) — they never reach
  the `bbxx` foot phase at all. Scope a discriminator to the phase that draws
  the thing, or it measures nothing. Original entry follows.

- **#112 — PRESS OF DEATH BLACK FOOT: ACCEPTED AS COSMETIC. DECIDED
  (maintainer, 2026-08-27): option (c) — accept for now; option (a) (give
  tenants their own effect animation) is PARKED for a later pass over the
  port's remaining purely-cosmetic items.** Option (b) (trim the borrowed
  sequence) is refused outright: the sequence is vanilla vsavj data, so
  editing it breaks the superset invariant regardless of what it does to the
  move. Rationale for (c): the defect is purely visual on a single-player
  surface, the project already carries small cosmetic imprecisions, and the
  mechanism is not understood well enough to patch safely — the whole draw
  path measured VANILLA (writer `PC 0x01B2BE` byte-identical to stock,
  vanilla record `0x287D7C`, vanilla sequence, vanilla art, tile window
  byte-identical to stock), and WHY a tenant runs that sequence is still
  unknown. GitHub #112 stays OPEN as the parked record; do not re-derive the
  eliminations, they are listed in the 14z-112 group above. **When the
  cosmetic pass happens, the entry point is a DISASSEMBLY-based trace of the
  effect spawn — not a byte scan** (two instruction-boundary false positives
  were paid for here: `e768 7105` and `0028394E`).

- **#113 — THE ONE-FRAME WHITE-OUT AT A DOWN IS VANILLA. CLOSED BY THE
  MAINTAINER 2026-09-01 ("I closed #113 since the behavior is indeed
  vanilla"), option (a) — GitHub #113 CLOSED 2026-09-01T11:16:19Z.** The
  board agrees with the emulator measurement: the camera/MiSTer evidence the
  2026-08-28 update was waiting for came back consistent, so the finding
  stands as measured and nothing was re-derived. The accessibility softening
  (b) was NOT taken and needs a fresh ruling if ever revived. **What survives
  as an honest boundary: the MECHANISM (palette RAM blanked vs a CPS-B
  layer/priority register) is still NOT measured — only the framebuffer is.**
  **-> ANSWERED 2026-09-01, SAME DAY THE TOPIC WAS OPENED: THE WHITE FRAME IS
  A DELIBERATE PALETTE-BASE SWAP.** The game writes CPS-A register
  `0x80410a` (`CPS1_PALETTE_BASE`, confirmed from MAME's `cps1.h`
  `CPS1_PALETTE_BASE = 0x0a/2`) from its normal `0x90c0` to **`0x9240`** for
  exactly ONE frame; the region at `0x924000` is filled wall-to-wall with
  `ffff`, so every pixel of every layer resolves to white. The next frame the
  base returns to `0x90c0`. **BOTH CANDIDATES IN THIS ENTRY WERE WRONG:** it
  is NOT palette RAM being blanked (rows `0x00-0x5f` at `0x90c000` change only
  by +/-1 colour cycling across the flash, mean luma 344 -> 344) and NOT a
  CPS-B layer/priority register. It is the palette POINTER.
  **TWO DIFFERENT "WHY"s, AND ONLY ONE IS ANSWERED — corrected 2026-09-01
  after the maintainer read this entry and said "I still don't understand why
  would Capcom want to blink the screen, but now we at least know how".** They
  are right and the first version of this entry overstated it:
  * **WHY THIS IMPLEMENTATION — ANSWERED.** Given that a full-screen flash is
    wanted, a palette-base swap is the cheapest way to get one: a single
    register write flashes every layer at once, disturbs no colour and no
    sprite, and reverses instantly.
  * **WHY A FLASH AT ALL — STILL OPEN, and it is the interesting half.**
    Nothing measured says what design purpose a one-frame white-out serves.
    THE ONE OBSERVATION WORTH CARRYING, stated as an observation and not a
    theory: all four occurrences in the run sit at STATE TRANSITIONS (the
    match-intro pair, match start, and the first down), not at arbitrary
    moments — so "an impact accent" and "a side effect of a palette swap at a
    transition" are both still live. Evidence AGAINST the second: the palette
    at `0x90c000` shows NO bulk reload around the flash (writes are a flat
    ~96/frame across f6640-6652, no burst at f6646), so if it is a swap
    artifact the reload is not happening there. Not pursued further; nothing
    depends on it.
  **DISCRIMINATOR, 4/4:** `0x9240` occurs EXACTLY FOUR TIMES in the 6,700-frame
  run — f1908, f1910, f2147, f6645 — one frame before each of the four known
  white frames (1909/1911/2148/6646) and nowhere else. Cross-implementation:
  FBNeo reproduces the same inventory at +1 frame (hash `0e86f1dc0b964325` at
  1910/1912/2149), so it is not a MAME artifact. The frame is genuinely 100%
  white (86,016 px, ONE distinct colour). Rig: `tests/lua/tap_writes.lua`
  `TAP=80410a,2` + `inp_probe.lua` `PAL_BASE=924000`, on STOCK vsavj with
  `104_1p_auto_ko_win.rpl` — the `test_down_flash_vanilla.sh` rig.
  **TWO INSTRUMENT TRAPS PAID FOR, both caught by controls:** (1) the first
  register tap used `0x800100`, which the driver's own map comments call
  "Mirror (sfa)" — NEVER written by this game, so a "zero writes" elimination
  was measuring a dead address (the tap MECHANISM was control-proven at
  `0x90c000`, which is not the same as proving the ADDRESS meaningful); the
  live block is `0x804100-0x80417f`. (2) `0x90c0` was briefly read as the
  flash value; it is the NORMAL one, and only the whole-run distribution shows
  which is rare. **Nothing is proposed and nothing changes** — vanilla
  behaviour, #113 stays closed, and the superset invariant forbids touching
  it. The original topic follows.
  **-> OPENED AS A RESEARCH TOPIC (maintainer, 2026-09-01): "we don't know the
  mechanism, much less the reason (there has to be one and I must admit I
  wonder why this is like this). We should open a research topic on it and
  tackle it after we get to the bottom of the black foot analysis."
  SEQUENCED AFTER #112.** Note it is TWO questions, and the second is the
  maintainer's real curiosity: (1) the MECHANISM — what makes the frame
  white (palette RAM zeroed vs a CPS-B layer/priority register at that
  frame); (2) the REASON — why Capcom's engine does it at all at a down.
  Knowledge work on VANILLA behaviour, not a port defect and not a fix: the
  superset invariant forbids changing legacy frames, and #113 is closed.
  WHAT EXISTS TO START FROM, so nothing is re-derived: the behaviour is
  frozen and gated (`tests/test_down_flash_vanilla.sh` — one all-white frame,
  fnv `eab1fb569cb99b25`, 57..96 frames after every down, plus the intro pair
  and the match-start frame), it is present in BOTH vsavj and vsav2
  (`37_victor_ko_vsav2`), and the framebuffer half is measured while the
  palette/register half never was. The instrument gap is the whole topic:
  a framebuffer hash cannot distinguish a blanked palette from a disabled
  layer — that wants a palette-RAM dump or a CPS-B register read AT the white
  frame ([CPE-14]: MAME read taps never fire on this driver, so a write tap
  or a frame-anchored dump is the route). `inferred_claims` row 11 is the
  standing record of the unmeasured half.
  The original entry follows. (measured 14z-112,
  `tests/test_down_flash_vanilla.sh` PASS on stock vsavj / reference MAME).
  Stock Vampire Savior draws ONE all-white frame (fnv `eab1fb569cb99b25`,
  whole framebuffer) 57..96 frames after every down, plus the intro pair and
  the match-start frame — merged-m9 reproduces exactly that inventory and
  nothing more. So it is not a port defect, and the photosensitivity concern
  is with Capcom's design. **The decision:** (a) CLOSE as vanilla behaviour
  (RECOMMENDED — the superset invariant forbids changing legacy frames, and
  the flash fires on every legacy down); (b) an OPT-IN accessibility
  softening (dip/config-gated, WIDE-only, default OFF, so default legacy
  output stays bit-identical) — a deliberate legacy-content change that
  needs its own ruling, a measured mechanism (palette-RAM vs CPS-B layer
  register at the white frame — not yet measured) and a gate; not free.
  The CRT "background stays, sprites vanish" is consistent with one white
  frame on phosphor (interpretation, not measured).
  **Maintainer's rule (2026-08-27): vanilla in VS with VS characters =>
  close regardless of vs2; measured BOTH — vsavj (104: +96) AND vsav2
  (37_victor_ko_vsav2, native Donovan: +88) show it. Awaiting the
  maintainer's own hand check on stock vsavj, then CLOSE.**
  **~~UPDATE 2026-08-28~~ SUPERSEDED 2026-09-01 — the camera evidence below
  ARRIVED and AGREED with the emulator finding; #113 is CLOSED. The
  paragraph is kept because its eliminations and its "if the board
  disagrees" clause are the reasoning that made the closure safe.**
  **UPDATE 2026-08-28 (maintainer): NOT closed, and not to be closed yet.
  The maintainer is gathering CAMERA evidence because original
  hardware/MiSTer may DISAGREE with the emulation finding, and wants
  bulletproof evidence before the topic is reopened. Until that arrives:
  the emulator measurement stands as measured, nothing is re-derived, and
  #113 stays OPEN. If the board does show something the emulators do not,
  that is a cross-implementation finding about the white frame's
  rendering (palette/CPS-B layer register at that frame — never measured,
  see (b) above), not about the game data.**

- **~~#99 — THE TYPE-0x51 REMAP~~ RE-RULED (maintainer, 2026-08-26, 14z-110):
  THE REACTION_HOOK D2-WINDOW SHAPE IS APPROVED, in the explicit order
  FIX -> AUDIT -> RE-FREEZE.** "Very well, I agree with all the proposal."
  What is approved, precisely:
  * **Shape: the reaction_hook THUNK BODY is extended — never the vanilla
    dispatcher.** The engine's patched footprint does not grow (still the one
    6-byte `jmp` at `0x018458`); the thunk's bne-arm (the only entry into
    dispatcher 2 at `0x018508`) gains the same `0x50-0x53` window test it
    already runs for dispatcher 1, dispatching via a SECOND ext table to vs2's
    dispatcher-2 twin (`0x016DE4`) handlers VERBATIM; every other index takes
    `jmp 0x018508` exactly as today. Data stays native `0x51` — dispatcher 3,
    the `es_type51_dispatch` thunk and the `property[0x51]=0x19` lookup are
    untouched.
  * **Scope: DATA-TRIGGERED, deliberately NOT tenant-id-gated.** The branch
    keys on the node byte's VALUE (`0x50-0x53`), which only vs2-numbered
    ported data can carry — vanilla data reaching dispatcher 2 with such a
    byte crashes today, so no legacy behavior can depend on the added branch
    (legacy-safe by IMPOSSIBILITY, the index_window_018468 precedent). An
    id-gate would be WRONG: the field proved the walking object can be a
    LEGACY character's (Bishamon) — the trigger is whose DATA the node lives
    in, not whose object walks it.
  * **Ownership: `donovan.toml`'s `[reaction_hook]` singleton** (merged
    inherits; solo Huitzil/Pyron don't declare it and the census measured
    them at ZERO out-of-range nodes, so they don't need it).
  * **The one global cost is CYCLES** — every object on the hit-stun path
    (`+0x38` set) executes the ~2 added compares, all characters. The
    flicker-inventory measurement (step 2 of the order) is the gate: if the
    frozen inventory moves, STOP and return to the maintainer — never widen.
  * **Order is binding: FIX (manifest + emitter) -> AUDIT on the fix build
    (flicker inventory, test_fsm_census still 6/6 native, audit_don_vs_cpu,
    guard soaks, audit_continue_switch re-measure) -> RE-FREEZE
    (donovan-m12/huitzil-m21/pyron-m15/merged-m7) + the MiSTer CRC tail.**
    Field pass on the new bundle is the actual #99 verification (MAME cannot
    reproduce the crash).
  This supersedes the 2026-08-26 (a)+(b)+(c) ruling's part (b); (a) — vanilla
  dispatcher never patched — is honored by construction, and (c)'s census came
  back EMPTY of further members. The measured basis below stands as the trail.
  **Original re-ask (14z-110), kept for the trail:** The census is
  DONE and the fix shape needed a fresh decision; (b) was not implemented.
  **WHAT THE CENSUS FOUND (measured 14z-110, `tools/audit_fsm_census.py` with
  the vs2 oracle + `tests/lua/fsm_census.lua` corpus):**
  1. **There is only ONE out-of-range family, and it is the KNOWN one.** The
     static family-aware census (node-record signature: 0x20-stride, monotonic
     +0x10 counter, +0x17 a valid state) finds exactly SIX out-of-vsavj-range
     node-state bytes across ALL THREE tenants — the six `0x51` records in
     Donovan's hitbox (`0x3FB862`-`0x3FB902`, +0x17 at blob offsets
     `0x10E9..0x1189`), which ARE the 14z-35 cluster. **Huitzil and Pyron have
     ZERO.** No `0x50/0x52/0x53` node clusters exist. **So the escalation
     clause resolves cleanly: there are no OTHER members to classify.** (Bound:
     signature-based; the dynamic corpus census found no idx >= 0x50 dispatched
     on any leg, mapping the reachable tenant node regions — a coverage bound,
     stated, not a universal proof.)
  2. **The node byte feeds THREE dispatchers, not one, and they are 80-entry
     not "~0x28".** `0x018460`/`0x018508`/`0x0185D2` (vs2 twins `0x016D34`/
     `0x016DE4`/`0x016EB6`, 84 entries -> gap `0x50-0x53`). The 14z-43
     `es_type51_dispatch` thunk's consumer audit named dispatchers 1+3 and
     MISSED dispatcher 2 (`0x018508`) — that is where #99 crashes. The records
     were left native `0x51` on purpose (dispatcher 3 + the property lookup
     need it).
  3. **A DATA remap breaks things:** `0x51 -> 0x19` diverges on dispatcher 3
     (there `0x19` -> handler `0x18694`, NOT the copy handler) AND fails the
     `es_type51_dispatch` thunk's `cmpi #0x51`. `0x51 -> 0x4E/0x4F` is
     copy-aliased on all three dispatchers, BUT the copy handler STORES the
     class and a downstream property lookup keys on it
     (`property[0x51]=0x19` vs `property[0x4E]=0x0F`, the 14z-44 ES-freeze
     family) — so it changes gameplay. **No data value is both
     dispatcher-exact on all three AND property-preserving.** Ruling (b) as
     written ("`0x51 -> 0x19`, zero gameplay surface") is therefore wrong on
     both counts.
  **RECOMMENDATION (measure-first order, port-the-handler caveat honored):**
  the clean fix is **CODE-SIDE on dispatcher 2's arm, inside a hook that
  already owns the only entry to it** — the `reaction_hook` site prefix
  (`0x018458`) already re-creates `tst.b (0x38,a1); bne 0x018508`, so its
  bne-arm gains the same `0x50-0x53` window the reaction_hook already runs for
  dispatcher 1, using vs2's dispatcher-2 twin `0x016DE4` handlers verbatim.
  Data stays native `0x51` (dispatcher 3 + property untouched). Cost: ~2
  compares on a path legacy executes when `+0x38` is set — **must be measured
  against the frozen flicker inventory before it ships** (that is the only open
  cost; if it moves the inventory, stop and root-cause). This is NOT a "port
  the handler" import — it reuses handlers already present; it adds a window
  test, not a foreign routine. **Delivered this window regardless of the
  ruling:** the census tool + gate (`test_fsm_census`, negative controls
  green), the deterministic Donovan-vs-CPU-Phobos coverage gate
  (`audit_don_vs_cpu`, closes #111's core gap), replay 110. The fix itself
  waits on this ruling.
  **HONEST GAP unchanged:** #99 does NOT reproduce on MAME from a P1-mash
  (full venue-0x02 Donovan-vs-Phobos marathon ran clean to END 40620) — the
  bad node needs the specific cross-fighter walk the maintainer sees 100% on
  the CORE. So no MAME regression lock is possible; the fix is verified by the
  census (node no longer >= table size on dispatcher 2's reachable path) + a
  field pass.
  **~~ORIGINAL RULING (maintainer, 2026-08-26), SUPERSEDED BY THE ABOVE~~:**
  (a)+(b)+(c) — (a) data-side extraction remap, never the dispatcher; (b)
  `0x51 -> 0x19`; (c) census + escalation. (a) and (c) stand in spirit; (b) is
  the part the measurement overturns. Kept for the trail.**
  **THE MAINTAINER'S STANDING CAVEAT ON (c), recorded verbatim in spirit:**
  for escalated hits, "port the handler" LOOKS like the best default (no
  error states + vs2-consistent tenant behavior) — **but it is NOT free: not
  in memory, not in cycles, and not in side-effects. Measure first. And if
  the maintainer seems too eager to say yes to a port, RAISE THIS POINT** —
  their own instruction. The project's evidence agrees: a ported handler
  imports code that may touch fields vsav lays out differently, may call vs2
  helpers at vs2 addresses (thunk/relocation work), costs bytes and
  per-frame cycles, needs its own gates — and "consistent with vs2" can
  still be WRONG under vsav's engine (the DF-frameworks-differ-BY-DESIGN
  lesson, 14z-101; the effect-class root that pulled cascading dependencies,
  14z-102). Default order for an escalated hit: measure what the state DOES
  and how often our content reaches it -> consider neutralize-to-default ->
  port ONLY when the behavior demonstrably matters to feel.
  **Original measured entry:** Step 1 done (14z-109 (7)), all three answers:
  1. **Family**: the object-script FSM node stream — 0x18-byte nodes whose
     `+0x17` byte is the NEXT-STATE index — inside Donovan's ported
     character block. Our node `0x3FB882` = vs2 `0x0C9CAA`, ported
     byte-verbatim (single content-search hit, 0x28-byte window).
  2. **What vs2's `0x51` means**: vs2's FSM table (dispatcher `0x016D2C`,
     table `0x016D34`) has **0x54 states**; entry `0x51` (offset `0x023C`)
     is vs2's MOST-ALIASED **DEFAULT handler** — `move.b (0x17,a3),(0x54,a1);
     rts`, the plain "advance to the node's next state". ~20 vs2 states
     alias it.
  3. **The vsavj equivalent**: vsavj's default at table offset `0x017C`
     (handler `0x01868C`, aliased by `0x19-0x1C`/`0x20-0x23`/`0x27`) is
     **BYTE-IDENTICAL** to vs2's `0x51` handler.
  **PROPOSED RULING: remap node-state `0x51 -> 0x19`** (the lowest vsavj
  default-alias) — semantically exact, both engines run identical
  instructions, zero gameplay surface. **Plus the census before the fix
  window**: scan ALL THREE tenants' ported node streams for `+0x17` values
  `>= 0x28` (vsavj's table size) and remap each by the same
  handler-equivalence method — one missed member is how THIS one shipped.
  Fix = extraction remap rule (14z-33/35 shape), landing with #111's
  coverage work in one window. Original entry:** Root cause is on the issue: node `ROM 0x3FB899` in Donovan's
  relocated block carries vs2 type byte `0x51`; vsavj's dispatcher at
  `PRG:0x018508` has no row for it and no bounds check. The fix wants THREE
  answers before any byte moves: (1) which record family `0x3FB882` belongs
  to in the extraction; (2) what vs2's `0x51` MEANS there (its handler in
  vs2's own table); (3) the correct vsavj renumbering — then a REMAP RULE in
  the extraction per the 14z-33/35 shape, never a hand-poke. Gameplay
  surface possible (the node does something in vs2 that vsavj may express
  differently), hence maintainer-ruled. **#111 (coverage rot) should land in
  the same window**: re-point or replace `26_don_arcade_mash`, re-measure
  `audit_continue_switch`, and add the missing Donovan-vs-CPU-Phobos gate
  (the venue-byte steer makes a deterministic one possible). The build-time
  guard — validate every ported type/selector byte against the consuming
  dispatch's bounds — is what keeps the NEXT missed family member off a CRT.

- **~~THE TIMING-MARGIN RESPONSE~~ DECIDED (maintainer, 2026-08-25).**
  `cps2w` fails 4 of 12 fitter seeds (14z-108). Options were laid out A-E.
  **RULED: A + B, with C IN RESERVE. D is ACCEPTABLE. E is OPPOSED unless
  there is no better choice.**
  * **A — do nothing to the RTL.** We distribute a PREBUILT `.rbf`, so the
    fragility is ours and not the users'.
  * **B — PIN THE SEED AT RELEASE.** Every shipped bitstream is built from a
    NAMED seed with its slack and sha256 recorded and verified, never from
    an `xjtcore.sh` random draw. The current baseline is **seed 18269,
    +0.066 ns, sha256 `46fc74af…`**. Costs nothing and converts "we got a
    lucky draw" into "we know which draw, and we check it".
  * **C — shed load on the SDRAM address cone** (bank 0 carries SEVEN slots
    since D2; the rejected 14z-107 alternative was moving the Z80 out).
    HELD IN RESERVE: it is the only fix that stays inside Rule 1 v2 and
    touches no shared infrastructure, but it would invalidate the bank-1
    bandwidth measurement, so it is not to be spent on headroom we do not
    currently need. **Revisit BEFORE the next RTL slice, not after.**
  * **D — pipeline the SDRAM address path.** ACCEPTABLE if C is not enough.
    Note it means overriding jtframe's shared controller in `cores/cps2w`.
  * **E — lower the SDRAM clock.** OPPOSED unless nothing else works: bank 0
    already peaks at 43.9% of its 96 MHz ceiling, so the clock is buying
    headroom we are using.

- **~~MiSTer PACKAGING: which MRA is MAIN, and how a release carries both
  `vsav.zip` flavours~~ DECIDED (maintainer, 2026-08-25): OPTION A, a
  WIDE-ONLY RELEASE, with option B as the eventual target.**
  **The collision, named exactly (14z-108):** the four ported-art members
  are `vm3.13m/.15m/.17m/.19m`, and they live in **`vsav.zip`, not
  `vsavjw.zip`**. So the WIDE MRA needs a PATCHED `vsav.zip` while every
  stock MRA needs the PRISTINE one — same filename, one `games/mame/`
  folder — and jtframe resolves members **by CRC32 alone**, so the wrong one
  is silently filled rather than refused.
  **Ruled: ship the WIDE MRA only.** The maintainer's reasoning, recorded
  because it settles the "which MRA is main" half too: **Jotego's own
  `jtcps2` core already runs vanilla**, so our core does not need to, and
  the stock regional MRAs are a development reference leg rather than a user
  feature. The generator currently makes the **Euro** set the main MRA and
  buries the WIDE entry in `_alternatives/`, which is backwards for a core
  whose purpose is the roster.
  ~~**Option B stays the target shape "in time"**~~ **OPTION B WAS SHIPPED AT
  14z-113 AND THIS ENTRY WAS STALE FOR THIRTEEN FREEZES — corrected
  2026-09-02 after the maintainer asked for it to be "made ready for the next
  freeze" and the archaeology ([VSP-14]) found it already done.** Measured on
  `build/m3b_merged21`: the build packs NO `vsav.zip` at all, and
  `vsavjw.zip` carries all 25 members including the four patched group-A ones
  (`vm3.13m/15m/17m/19m`), so `vsav.zip` stays pristine from `$ROMDIR` and a
  user's existing romset folder works untouched. The freeze that did it is the
  14z-113 ONE-ZIP PACKAGING FREEZE (merged-m10). **What was still undone is
  the OTHER half of this decision — "which MRA is MAIN" — and that landed
  2026-09-02:** `parse.main_setnames=["vsavjw"]` in the fork's
  `cores/cps2w/cfg/mame2mra.toml` (fork `5fd9bb9a6`), the upstream mechanism
  kiwi/s16/s16b already use, so the WIDE set is no longer filed under
  `_alternatives/` while a stock regional set takes the main slot. The
  original text follows: move those four members
  INTO `vsavjw.zip` so `vsav.zip` can stay pristine and a user's existing
  romset folder works untouched. Not done now because it is a build-pipeline
  change touching the hash-shadowing class that cost two sessions in
  14z-60z/61, and it must not sit between the maintainer and a field test.

- **THE REMAINING SKILLS — PLANNED AND ALL FOUR SHIPPED 14z-114 (`docs/project/skills_scope.md`,
  now the record); the five decisions were taken under stated assumptions and remain OPEN TO VETO — a veto means re-cutting a shipped skill, which the checker makes mechanical:** (1) FOUR
  skills — `cps2-hardware`, `cps2-emulation` (split per "MiSTer separate
  from emulation"), `vampire-savior-engine`, `vampire-saved-port`; (2) the
  game skill quotes NO ROM addresses (laws + the atlas row it names); (3)
  the port skill anchors into CLAUDE.md and points, never restates it; (4)
  each skill's staleness pass runs in the same session as its distillation
  as its own commit (the MiSTer ruling generalised); (5)
  `engine_internals.md` counts as a LOG for the game skill's number-citation
  check. Sequencing A+B (platform) -> C (game) -> D (port). Distillation of
  A+B began the same session — and all four landed in it: `[CPH-1..30]`, `[CPE-1..42]`, `[VSE-1..83]`, `[VSP-1..161]`; 425 rules across six skills, `checkskills` ALL PASS.

- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** ~~Recorded as FUTURE, UNPLANNED work — nothing scheduled.~~
  **ALL SIX SKILLS ARE DONE 14z-114** (`mister-cps2-wide-core`,
  `mister-vampire-saved`, `cps2-hardware`, `cps2-emulation`,
  `vampire-savior-engine`, `vampire-saved-port`; checker `tools/checkskills.py`;
  STATE 14z-114). The maintainer's sketch — a CPS-II skill separate from a
  VS/VS2/VH2 skill — is met by the `cps2-*` pair and `vampire-savior-engine`;
  the checker shape (docs as the human rendition, anchored IDs, numbers cite
  the log) is the pattern any future skill reuses.
  As was done for Sailor Moon S, distil the project's learnings into agent
  SKILLS, **scoped by subject rather than by task**. The maintainer's sketch:
  at least a **CPS-II** skill separate from a **VS / VS2 / VH2** skill, and
  **MiSTer** separate from **emulation**; exact scopes to be agreed. Stated
  rationale: they make further work markedly easier.
  **The precedent is concrete and observable from inside a session** — the
  SMS project produced `romhacking-methodology` (general RE/patch discipline)
  and `snes-romhacking` (platform-specific hard rules), and both load into
  Claude Code sessions on this machine today.
  **Three observations to carry into the scoping conversation:**
  1. **The split the maintainer proposes is the one `docs/README.md` already
     uses.** "Would this still be true if we abandoned the roster hack
     tomorrow?" separates `platform/` (CPS-2, MAME, FBNeo, MiSTer) from
     `game/` (Vampire Savior itself) from `project/` (this port) — and it is
     the same question that separates a CPS-II skill from a VS/VS2/VH2 skill
     from a port skill. A skill that mixes those scopes fails the same way a
     doc filed by task instead of by fact does.
  2. **A skill is loaded BEFORE the work, so it must carry what you need to
     know before you know you need it** — laws, traps and negative controls,
     not reference data. SMS made this split explicitly:
     `sms_hacking_playbook.md` quotes ZERO addresses on purpose and points at
     the checked docs instead. Skill = the discipline; docs = the facts.
     Candidate content from this project, all paid for: measure-don't-infer,
     probe sparsity, the negative-control rule, "identify moves by measured
     EFFECTS not the script's input name", "a gate that stops checking reads
     GREEN not RED", "suspect the instrument before the thing under test",
     and the §4 vocabulary of frozen non-exact classes.
  3. **Skills go stale exactly like docs, and need the same enforcement.**
     SMS ships `tools/checkskills.py`, which ID-locks the human playbook to
     the agent skill so the two cannot drift. Whatever is distilled here
     should ship with its checker in the same commit.
  Sequencing: this naturally follows the living-documentation effort above
  (a skill is a distillation, so it wants the synthesis to exist first), and
  both follow MiSTer.

- **MiSTer DOCUMENTATION + SKILL DISTILLATION, AT TWO LEVELS (maintainer
  direction, 2026-08-27). DONE 14z-114 — both levels distilled, see the
  14z-114 entry; `mister_scope.md` carries the status.** FIRST STEP AGREED 2026-08-27: produce the SCOPE
  DOCUMENT ONLY — ~~queued in `docs/NEXT_SESSION.md`~~ DONE 14z-113:
  `docs/project/mister_scope.md`; its three follow-on decisions are the
  entry "THE MiSTer SCOPE DOCUMENT — three decisions" above.** The scope document
  names what skills should exist, where each boundary falls, which existing
  docs feed which, and what is known-stale; the skills themselves wait on it.
  Rationale for splitting it out: the sources run ~4,000 lines and must be
  READ, and the state is not settled (merged17 unfrozen, two field checks
  outstanding), so writing reference material now would bake in claims that
  are still moving. Recorded as FUTURE work alongside the existing
  skill-distillation and living-documentation items, not scheduled. The
  maintainer's scoping: document (and possibly distil into skills) the MiSTer
  implementation **at each level** — (1) the **WIDE CPS-II core** level (the
  profile, the runtime profile bit, the SDRAM map, the simulation lane: all
  game-independent), and (2) the **VS-specific** level (this romset's
  placement, catalogue/MRA generation, the field-test bundle). The split
  mirrors `docs/README.md`'s own test ("would this still be true if we
  abandoned the roster hack tomorrow?") and the CPS-II-vs-VS/VS2/VH2 split
  already sketched for the skills. Raw material exists and is large:
  `docs/platform/mister.md` (core, lane, profile gate, SDRAM ceilings) and
  `docs/project/mister_fit.md` (what this port needs vs what jtcps2 offers).
