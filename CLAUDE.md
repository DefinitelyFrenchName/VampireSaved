# CLAUDE.md — Project VAMPIRE SAVED

Full-roster Vampire Savior on the real CPS-2 engine. Emulator-target romhack
(FBNeo primary, MAME as independent verification oracle, MiSTer as stretch goal).
This file governs how Claude Code operates inside this repository. Read it fully
at the start of every session. Read `STATE.md` immediately after.

Condensed 14z-123 and 14z-124; cut to RULE PLUS POINTER 2026-10-15 (#282 item D, the maintainer: *"Rule +
pointer (Recommended)"*). The LAW (§1, §2) is verbatim. Every other rule keeps its `**[VSP-N]**` anchor and its
statement here; its reasons, history and steps live, verbatim, in the document it names. `tools/checkskills.py` and
`tests/test_doc_anchor_census.sh` lock the anchors.

## 1. Mission and prime constraint

Produce a modified `vsav` romset in which all 18 series characters (the 15+1 of
Vampire Savior plus Donovan, Huitzil/Phobos, and Pyron ported from `vsav2` /
`vhunt2`) are selectable, while vanilla Vampire Savior behavior remains
**bit-identical** for all original content.

**[VSP-1]** **THE SUPERSET INVARIANT (never violate, never weaken):**
Any match, menu path, or attract sequence that does not involve the three new
characters MUST produce frame-identical RAM state to vanilla `vsav` under
identical inputs. This is not a quality goal; it is the definition of the
project. A change that improves the new characters but perturbs one byte of
legacy behavior is a failed change.

## 2. Non-negotiable rules

1. **Emulator cores are never modified, except inside a ratified profile
   (Rule 1 v2).** Only cartridge/driver *descriptors* (ROM region sizes, load
   maps, gfx decode lengths) may change in FBNeo/MAME. If a task appears to
   require touching CPU, sprite, timing, or QSound emulation code, stop and
   write up the problem in `STATE.md` instead. The trust surface of emulator
   changes must remain a small, human-reviewable set of declarative mapping
   lines.

   **[VSP-2]** **THE ONE BOUNDED EXCEPTION**, ratified round 66 and specified in
   `docs/project/cps2_wide.md` "Governance (Rule 1 v2)": the CPS-2 WIDE
   profile carries two gated blocks in `Cps2ObjDraw` (the 19-bit tile
   promote, plus the `CPS2_WIDE_CANARY` positive control). Every such change
   must be bounded and declarative, **profile-gated** by a flag set from a
   new driver entry so stock `vsavj` and every other CPS-2 game are untouched
   by construction, subject to the **emulator superset invariant** (the
   patched binary running stock unmodified `vsavj` reproduces the frozen
   vanilla expectations bit-for-bit, enforced as a battery gate), mirrored in
   a second emulator where practical, and ratified per profile version. The
   spec is NOT copied here on purpose — two copies drift, and that document
   is the one kept current. Anything outside that profile is still
   stop-and-escalate. (This rule named sprite code as stop-and-escalate while
   the tree had modified `cps_obj.cpp` under a ratification it never
   mentioned — corrected 14z-91, GitHub #35.)
2. **[VSP-3]** **No untested change survives a session.** Every patch, however trivial, is
   validated through the headless harness before being committed. "It should
   be equivalent" is not a test result. This standard is inherited from the
   Sailor Moon S project, where systematic in-emulator verification was the
   difference between working and *shipping*.
3. **[VSP-4]** **No hand-edited binaries.** All ROM modifications are produced by the build
   pipeline from source manifests (`build/manifest/*.toml` + assembly sources +
   extracted data tables). The repo must be able to reproduce the output set
   from pristine inputs at any commit.
4. **[VSP-5]** **Provenance is tracked per region.** Every byte range in the output set is
   tagged with its origin: `VSAV` (untouched), `VS2`, `VH2`, `GEN` (generated),
   or `NEW` (authored). The provenance atlas (`docs/game/atlas/`) is updated in the
   same commit as the change that affects it.
5. **[VSP-6]** **Behavioral values live in documented tables, not in code.** Any tunable
   that defines how the ported characters play (damage, timings, meter rules,
   variant selection) must be extracted into the data-table format of
   `docs/project/tables/` so the community can review and adjust without re-engineering.
6. **[VSP-7]** **Failing regression halts forward work.** If the replay-checksum suite
   diverges, fixing that divergence becomes the only task until green.
7. **[VSP-8]** **No copyrighted ROM content in the repo or in any distributed artifact.**
   The repo holds tools, patches (xdelta/BPS against named reference dumps),
   documentation, and authored assets only. Reference romsets live outside the
   tree in `ROMDIR` (env var) and are never committed, quoted at length, or
   uploaded anywhere. **Rendered frames are outside this rule** (ruled 14z-91,
   GitHub #73): the committed PNG goldens under `tests/` are derived work
   produced by our own pipeline, not ROM bytes, and they stay — recorded so it
   is not re-litigated. (`test_gfx_menus.sh` compares masked `tobytes()`, so a
   SHA-256 of the masked buffer would be verdict-identical; that is a
   diagnostics trade, not a rule-7 obligation.) ROM BYTES remain forbidden in
   every form, including excerpts pasted into docs.

## 3. Environment

- **[VSP-9]** Reference sets (decrypted): `vsavj` (**Japan 970519 — DECIDED**, the
  competitive-standard region; do not reopen), `vsav2`, `vhunt2`,
  located in `$ROMDIR`. Verify SHA-1 against `docs/checksums.txt` before any
  session that reads them. If checksums mismatch, stop.
- Toolchain: Python 3 for analysis/extraction; vasm or asmx for 68000 assembly
  hooks; MAME with `-video none` + Lua for tracing and the oracle harness;
  patched FBNeo build under `emu/fbneo/` (submodule + our driver patch). The
  Ghidra project area `re/ghidra/` was never populated — the address → label
  stream is `docs/annotations.md` (generated).
- All analysis scripts are rerunnable, take the ROM path as argument, and
  print the SHA-1 of what they read. Follow the conventions of
  `tools/` (see existing extractors for style — modeled on the SMS project's
  extraction scripts).

## 4. Verification protocol (the harness is the project's spine)

- **Oracle replays:** `tests/replays/` holds input scripts (per-frame joystick/
  button state). The harness runs each script on (a) vanilla `vsav` and (b) the
  hacked set, checksumming work RAM every frame. Legacy-content replays must
  match for the full script length. First divergent frame + RAM diff is the
  standard bug report format.

  **[VSP-24]** **Which emulator runs which oracle** (corrected 2026-08-16, GitHub #78): the per-frame whole-corpus
  legacy oracle is **MAME** (`tests/lib/m2a_common.sh`, the frozen `.masked` classes below). FBNeo carries the
  **emulator superset invariant** on pristine `vsavj`, **dual-track** inertness on one binary, and a **sampled**
  hacked-vs-vanilla legacy check; a measured FBNeo-vs-MAME disagreement on legacy content opens a new ticket
  (restated 2026-09-15, maintainer-agreed). The full rule: `docs/project/oracle_classes.md` § [VSP-24].

  **[VSP-25]** **Dual-track "inertness" means bit-identical UP TO SELECT ENTRY, not for the whole replay**
  (ratified 2026-08-17, GitHub #95; amended 2026-09-05, 14z-133b, maintainer-ruled). Onsets are frozen per replay;
  an onset moving EARLIER is the failure. "Bit-identical" is measured OUTSIDE six frozen execution-position offsets,
  never outside a window; the STATE onset, the first frame with any other byte, is what must equal the frozen
  onset. The full rule: `docs/project/oracle_classes.md` § [VSP-25] (class v6).

  **[VSP-26]** **The two FBNeo-only phase classes** (ratified 2026-08-16, GitHub #78): the sound-driver work area
  `RAM:$FF0500-$FF05FF` and the OBJ-builder secondary stack `RAM:$FF06D0-$FF06EF` may differ on FBNeo where MAME
  shows none — execution POSITION, not state. **The window is NOT the tolerance:** the expectation is FROZEN as the
  measured offset inventory (in `test_fbneo_legacy_oracle.sh`), and a byte differing inside a window but OUTSIDE it
  FAILS as GROWTH — stop and root-cause, never widen. The full rule: `docs/project/oracle_classes.md` § [VSP-26].
- **The hooked-build legacy comparison classes** — the ratified vocabulary every `.masked` expectation uses;
  **the spec of record is `docs/project/oracle_classes.md`**. Every non-exact class must be mechanism-attributed
  and its expectation frozen; a replay may not be reclassified to a looser class without a new measured mechanism
  and maintainer sign-off. **[VSP-31]** **Standing watch (maintainer, 2026-07-27): if flickers grow beyond the
  frozen inventory or divergences turn systematic, stop and root-cause — that pattern would indicate a deeper
  issue, not tolerance noise.** Whole-RAM frame-exact remains the standard for vanilla oracles, run-to-run
  determinism, and hook-free builds. Why hooks skew: `docs/project/oracle_classes.md` § The hooked-build legacy
  comparison classes.
- **[VSP-32]** **Dual-emulator agreement** (amended 2026-07-25, maintainer-approved): for new-character content
  (no vanilla oracle exists), the same replay is run on patched FBNeo and patched MAME and the two must agree on
  **mapped gameplay state compared at sync anchors** (match start, round transitions): character IDs, HP,
  positions, timer, meter, and the other fields in `docs/game/atlas/ram.md` — not whole-work-RAM checksums
  frame-by-frame. Whole-RAM frame-exact checksums remain the
  standard **within** each emulator. Why: `docs/project/oracle_classes.md` § [VSP-32].
- **Test matrix growth:** every new capability adds replays. Minimum coverage
  for a ported character: vs each of the 18 (both sides), each stage, Dark
  Force activation/expiry, life-marker transition, timeout, throw/tech
  situations, pursuit attacks, Shadow/Marionette interaction once enabled.
- **[VSP-33]** **Edge-case bias:** when writing replays, prefer pathological inputs
  (simultaneous presses, frame-1 actions, corner interactions, KO-frame
  events). The SMS experience: bugs live at state transitions, not in the
  middle of matches.
- **[VSP-20]** **FIELD REPORTS ARE RECORDINGS (maintainer-ruled 2026-08-27, 14z-111).** Every reproducible
  crash or misbehaviour a human can produce — on the board or on MAME — is captured FIRST as a hand-played MAME
  recording, BEFORE any mechanism theory, and tracked under `tests/inp/<name>/`, named `<what>-<freeze set>-NN`
  (the freeze it was PLAYED on, never the mark or the session). **`tests/test_inp_corpus.sh` replays EVERY tracked
  recording on the current merged build at every freeze and fails on the first exception.** Naming, cleanup and
  playback: `docs/project/working_methods.md` § [VSP-20].
- **[VSP-18]** **THE PERSISTENT SUITE DOCTRINE (SMS lesson, promoted to law):** every
  in-emulator test executed during development — measurement, probe, or
  verification — is captured as a scripted, rerunnable case in `tests/` before
  the session ends. No throwaway manual checks. These behavioral tests are the
  project's most valuable artifact, above unit/integration tests; the suite
  only grows. Budget the time; it is time well spent.
- **Auto-detecting regression runner:** the suite runner fingerprints the build under test and selects
  expectations accordingly, so one command validates any build variant; engine-invariant "rule locks" for vanilla
  behavior run on every build. The index of every gate is `docs/project/gate_index.md` (generated); the pre-commit
  command is `tests/run_all_static.sh` (HANDOFF "How to test").
- **[VSP-19]** **Verdict logic is itself tested.** A test's classification code
  (HIT/BLOCK/TECH/etc.) must be validated against known ground-truth
  scenarios before its verdicts are trusted — SMS shipped a wrong conclusion
  ("blockable frame trap") from a verdict bug, not a game bug. Never again.
- **Savestate hygiene:** key states are tagged to the exact build they were
  created on, named accordingly, and force-added to git when demos/tests
  depend on them; regeneration procedure documented per state.

## 5. Working style

- **[VSP-17]** Sessions begin by reading `STATE.md` (current milestone, open decisions, standing rulings) and end by
  updating it. STATE.md is the single source of truth for progress; do not rely on chat memory. It holds the latest
  session group — two while a sitting writes its own — and the standing sections; `STATE_HISTORY.md` holds every
  older session record VERBATIM (split 2026-08-20, maintainer-approved; amended 2026-09-14 and 2026-10-14, #282:
  *"At most 2"*). **AN OPEN LIST HOLDS ONLY WHAT IS OPEN (maintainer-ruled 2026-09-14):** STATE.md's "Decisions
  pending" and NEXT_SESSION's START HERE never carry a closed item, however it is marked. **THE CLOSE ENDS WITH A
  PUSH (maintainer-ruled 2026-09-10):** when every check of the close is green and nothing is pending, push `main`
  to GitHub as the ritual's last step; a red, a SKIP or an unresolved item leaves the commits local and the close
  says so. The close's steps: `docs/project/session_close.md`; the full rule: `docs/project/session_records.md`
  § [VSP-17].
- **[VSP-182]** **TICKETS HAVE STRICT SOURCES OF TRUTH (maintainer-ruled 2026-09-14).** Every bug, cosmetic
  item and evolution is a ticket, and each question about one has exactly one source of truth: the list is
  `docs/project/tickets.tsv`, the story its GitHub issue, the facts the subject documents. Live documents name a
  ticket by its issue number and never restate its status or content. **ENOUGH STAYS LOCAL:** without GitHub, the
  tree must answer four questions about every ticket — what it was and how to reproduce it, what was decided, what
  was learned, and what went wrong. **Closed means nothing is left to do.** Done-awaiting-release, closing a ticket
  and copies: `docs/project/session_records.md` § [VSP-182]; `tests/test_tickets.sh` enforces the form.
- **[VSP-162]** **THE `14z-N` SESSION KEY** names ONE SITTING and is the archive's LOOKUP KEY, so a tag is never
  renamed, renumbered or tidied: renaming one silently breaks every citation. Sessions `14z-N`, milestones and
  freeze marks are three namespaces, never conflated. **`14z-` is a fossilised prefix — read it as one opaque token;
  the live counter is `-N`.** Its shape and reconstructed origin: `docs/project/session_records.md` § [VSP-162].
- **[VSP-11]** Address notation: 68k addresses as `PRG:0x0F1234` (program ROM offset) or
  `CPU:$0F1234` (address-space); tiles as `GFX:tile 0x1A2B3`; RAM as
  `RAM:$FF8000`. Never bare hex without a namespace.
- **[VSP-12]** **Documentation taxonomy (SMS-proven; respect the splits, don't merge).** `docs/` is divided by ONE
  question — would this still be true if we abandoned the roster hack tomorrow? — into `docs/game/`,
  `docs/platform/` and `docs/project/`; file by the FACT, not by the task you were doing when you learned it. Every
  hand-written document declares its SHAPE in `docs/doc_shape.tsv`; chronology lives in `<name>_history.md` twins,
  never re-accreting into a reference document. The GENERATED indexes (`docs/annotations.md`,
  `docs/project/gate_index.md`, `docs/GOTCHAS.md`) are regenerated in the commit that changes what they index, never
  hand-edited. Gotchas are appended the moment one is paid for, to the bucket its FACT belongs to. Findings land in
  the right document *at discovery time*: an undocumented discovery is a discovery we will pay for twice. The full
  rule and the roster: `docs/README.md` § [VSP-12].
- **[VSP-13]** **RETRACTION DISCIPLINE (standing order, 14z-71): when a claim changes, GREP FOR THE CLAIM —
  not for the files you remember writing it in.** Search the assertion's wording and its paraphrases across the
  repo, the archives included; fix the HEADER and the summary line first; re-grep afterwards and show the empty
  result; keep the superseded analysis, marked RESOLVED/RETRACTED with what replaced it. **Status headers track
  reality; historical entries are not rewritten.** The procedure: `docs/project/working_methods.md` § [VSP-13].

- **[VSP-14]** **BUG ARCHAEOLOGY FIRST (standing order, 14z-75): before fixing a bug, check whether it has
  already been fixed once — and if you are unsure, ASK THE MAINTAINER.** `git log --grep`, `git log -S` and a grep
  of STATE_HISTORY.md BEFORE forming a theory; find the build where it was last known good and diff it against its
  predecessor; **if the record is ambiguous about whether it was ever fixed, ask before measuring.** The steps:
  `docs/project/working_methods.md` § [VSP-14].

- **[VSP-15]** **Anti-hyperfocus checkpoint (standing order):** deep-dive focus is the
  project's engine but also its failure mode. At natural boundaries — a
  finding confirmed, a test suite green, ~20 tool iterations on one problem —
  stop and do the meta-pass unprompted: update the docs above, capture the
  scratch tests into the suite, reassess whether the current approach is
  still the right one, and check STATE.md for drift. The human should never
  have to be the one to say "step back and document."
- **[VSP-16]** **Build conventions (SMS-proven):** builders are Python, take `(src, out)`
  positionals so they chain onto any input ROM, and every tunable is a
  builder flag — never a hex edit. Bundles are built by chaining builders
  then diffing ONCE against clean; never by chaining standalone binary
  patches (the SMS bank-collision trap). Shipped builds carry a visible
  in-game version string as the naked-eye A/B tell for playtesters, and
  every build's SHA-1 goes in the registry.
- **[VSP-10]** When a decision has gameplay consequences (anything a player could feel),
  it is not Claude's to make: record it in `STATE.md` under "Decisions
  pending" with options and a recommendation, and continue on unblocked work.
- Prefer diff-driven reverse engineering: the three romsets are three official
  builds of one engine. Before free-form disassembly of any subsystem, check
  what the three-way diff says about it.

## 6. What the human provides

Vision and final say on all gameplay-feel decisions; playtesting (structured
reports welcome as replay scripts when possible); base resources (reference
dumps, community docs); community liaison for the VS2-vs-VH2 variant policy.
Claude does the code archaeology, tooling, patch engineering, and testing.
Neither side skips the harness.
