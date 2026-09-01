# CLAUDE.md — Project VAMPIRE SAVED

Full-roster Vampire Savior on the real CPS-2 engine. Emulator-target romhack
(FBNeo primary, MAME as independent verification oracle, MiSTer as stretch goal).
This file governs how Claude Code operates inside this repository. Read it fully
at the start of every session. Read `STATE.md` immediately after.

Condensed 14z-123 at the maintainer's direction ("more concise and to the
point, without losing precious information, especially on the work style and
discipline"). The LAW is verbatim; the correction narratives that had
accreted inside rules are now a rule plus a dated citation — the stories
live in STATE_HISTORY and the documents named. Pass 2 (14z-124,
maintainer-ruled 2026-08-31) made the structural cut: the oracle-class
definitions live in `docs/project/oracle_classes.md` and the document roster
in `docs/README.md`; §4 and §5 keep the law and point. Every `**[VSP-N]**`
marker stays on the paragraph it anchors, wherever that paragraph lives
(`tools/checkskills.py` and `tests/test_doc_anchor_census.sh` lock them).

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

  **[VSP-24]** **Which emulator runs which oracle** (corrected 2026-08-16,
  GitHub #78): the per-frame whole-corpus legacy oracle is **MAME**
  (`tests/lib/m2a_common.sh`, the frozen `.masked` classes below). FBNeo
  carries the **emulator superset invariant** on pristine `vsavj`
  (`test_wide_profile.sh`, reference vs patched binary), **dual-track**
  inertness on one binary (`test_dualtrack.sh`), and a **sampled**
  hacked-vs-vanilla legacy check (`test_fbneo_legacy_oracle.sh`: 4 replays ×
  5 frames, each frame a measured-clean override chosen clear of every
  ratified divergence — 14z-92/110b). The **full** FBNeo legacy track is
  ACCEPTED-AND-DEFERRED: every FBNeo gate is a live A/B by design (no frozen
  corpus), which is what makes them machine-independent; revisit at MiSTer,
  where a third implementation would surface MAME-specific behaviour.

  **[VSP-25]** **Dual-track "inertness" means bit-identical UP TO SELECT
  ENTRY, not for the whole replay** (ratified 2026-08-17, GitHub #95). The
  stock and WIDE builds carry DIFFERENT ROSTERS by construction — a
  stock-size ROM can only hold Donovan by substituting over someone, which is
  why WIDE exists — so every select-reaching replay must differ. Onsets are
  frozen per replay; an onset moving EARLIER is the failure.

  **[VSP-26]** **The two FBNeo-only phase classes** (ratified 2026-08-16,
  GitHub #78): the sound-driver work area `$FF0500-$FF05FF` and the
  OBJ-builder secondary stack `$FF06D0-$FF06EF` may differ on FBNeo where MAME
  shows none — execution POSITION, not state (`atlas/ram.md`), on legacy as
  well as tenant content. **The window is NOT the tolerance:** the
  expectation is FROZEN as the measured offset inventory
  (`$FF055B-$FF055D`, `$FF06D1/D4/DB`, in `test_fbneo_legacy_oracle.sh`) and
  a byte differing inside a window but OUTSIDE it FAILS as GROWTH — stop and
  root-cause, never widen. `FBNEO_ORACLE_EXPECT=exact` demands bit-identity.
- **The hooked-build legacy comparison classes** — the ratified vocabulary
  every `.masked` expectation uses: **exact** (default), **flicker-tolerated**
  (v2), **frozen first-divergence constant**, the **bounded re-convergent
  window** (v3), **composite** (v4 — the strict conjunction of flicker and
  window, no added tolerance), and the v5 ruling that the ≥60-frame rule is
  INTRA-MECHANISM. **The spec of record is `docs/project/oracle_classes.md`**
  — every definition with its date, frozen figures, named exemptions,
  checker and ground-truth test; NOT copied here on purpose (the Rule 1 v2
  principle: two copies drift). Every non-exact class must be
  mechanism-attributed and its expectation frozen; a replay may not be
  reclassified to a looser class without a new measured mechanism and
  maintainer sign-off. **[VSP-31]** **Standing watch
  (maintainer, 2026-07-27): if flickers grow beyond the frozen inventory or
  divergences turn systematic, stop and root-cause — that pattern would
  indicate a deeper issue, not tolerance noise.** Rationale (measured,
  session 7, `docs/GOTCHAS.md`): hooks cost cycles; interrupts land at skewed
  instruction boundaries in otherwise-vanilla frames; zero-cycle hooking is
  impossible on this engine. Whole-RAM frame-exact remains the standard for
  vanilla oracles, run-to-run determinism, and hook-free builds.
- **[VSP-32]** **Dual-emulator agreement** (amended 2026-07-25,
  maintainer-approved): for new-character content (no vanilla oracle exists),
  the same replay is run on patched FBNeo and patched MAME and the two must
  agree on **mapped gameplay state compared at sync anchors** (match start,
  round transitions): character IDs, HP, positions, timer, meter, and the
  other fields in `docs/game/atlas/ram.md` — not whole-work-RAM checksums
  frame-by-frame. Rationale (measured, session 2): the emulators traverse
  identical states on slightly different frame indices after boot, so
  frame-exact whole-RAM equality is unachievable between codebases;
  field-level agreement at anchors preserves the original intent — a bug
  would still have to manifest identically in two unrelated codebases to slip
  through. Whole-RAM frame-exact checksums remain the standard **within**
  each emulator (vanilla-vs-patched superset oracle, run-to-run determinism).
- **Test matrix growth:** every new capability adds replays. Minimum coverage
  for a ported character: vs each of the 18 (both sides), each stage, Dark
  Force activation/expiry, life-marker transition, timeout, throw/tech
  situations, pursuit attacks, Shadow/Marionette interaction once enabled.
- **[VSP-33]** **Edge-case bias:** when writing replays, prefer pathological inputs
  (simultaneous presses, frame-1 actions, corner interactions, KO-frame
  events). The SMS experience: bugs live at state transitions, not in the
  middle of matches.
- **[VSP-20]** **FIELD REPORTS ARE RECORDINGS (maintainer-ruled 2026-08-27, 14z-111).**
  Every reproducible crash or misbehaviour a human can produce — on the
  board or on MAME — is captured FIRST as a hand-played MAME recording
  (the commands: HANDOFF, [VSP-119]), BEFORE any mechanism theory, and
  tracked under `tests/inp/<name>/` (force-added,
  with a one-line `NOTE`). **NAMING: `<what>-<freeze set>-NN`** — the
  freeze the recording was PLAYED on, never the mark or the session
  (`crash-merged-m8-01`; a mark can cover two freezes and a session two
  freezes). **CLEANUP:** the `~/.cache/vampire-saved/inp/<name>/` copy is
  deleted once tracked; a recording neither tracked nor named by any gate or
  doc (grep first) is deleted, not kept. `tools/run_inp_guarded.sh` plays a
  recording back with a write tap on the game's OWN exception-code store
  (`RAM:$FF0000`) — no debugger, faithful playback — and yields the vector,
  fault PC, registers and stack. **`tests/test_inp_corpus.sh`
  replays EVERY tracked recording on the current merged build at every
  freeze and fails on the first exception** (a captured-but-unfixed defect is
  declared by a `DEFECT` file so the capture cannot rot). The cost that made
  this law: 14z-109..111 spent three sessions and two shipped fixes on a
  rig-derived mechanism that was never the field crash; the first recording
  found the real one (#99) in an evening — win-fast rigs never give a CPU
  opponent's AI time to reach its rarer scripts.
- **[VSP-18]** **THE PERSISTENT SUITE DOCTRINE (SMS lesson, promoted to law):** every
  in-emulator test executed during development — measurement, probe, or
  verification — is captured as a scripted, rerunnable case in `tests/` before
  the session ends. No throwaway manual checks. These behavioral tests are the
  project's most valuable artifact, above unit/integration tests; the suite
  only grows. Budget the time; it is time well spent.
- **Auto-detecting regression runner:** the suite runner fingerprints the
  build under test (which features/patches are present) and selects
  expectations accordingly, so one command validates any build variant
  (SMS `test_regression.lua` pattern). Engine-invariant "rule locks" for
  vanilla behavior run on every build. The index of every gate is
  `docs/project/gate_index.md` (generated); the pre-commit command is
  `tests/run_all_static.sh` (HANDOFF "How to test").
- **[VSP-19]** **Verdict logic is itself tested.** A test's classification code
  (HIT/BLOCK/TECH/etc.) must be validated against known ground-truth
  scenarios before its verdicts are trusted — SMS shipped a wrong conclusion
  ("blockable frame trap") from a verdict bug, not a game bug. Never again.
- **Savestate hygiene:** key states are tagged to the exact build they were
  created on, named accordingly, and force-added to git when demos/tests
  depend on them; regeneration procedure documented per state.

## 5. Working style

- **[VSP-17]** Sessions begin by reading `STATE.md` (current milestone, open bugs, decisions
  pending) and end by updating it. STATE.md is the single source of truth for
  progress; do not rely on chat memory. **SPLIT 2026-08-20
  (maintainer-approved): STATE.md holds the newest ~3 session groups, THE
  LEDGER (one line per archived session), and the standing sections;
  `STATE_HISTORY.md` holds every older session record VERBATIM.** The
  rollover procedure lives in STATE.md's own header and is part of the
  session-close ritual. "STATE 14z-XX" references resolve in STATE.md
  first, then STATE_HISTORY.md — section names are preserved in the
  archive, and archived entries are never rewritten (corrections are
  marked in place, as always).
- **[VSP-162]** **THE `14z-N` SESSION KEY — a naming convention AND the
  archive's INDEX, which is why it is never re-based.** A tag names ONE
  SITTING (a working session, several per day at times — not a calendar day,
  not a milestone, not a build). **Three namespaces, never conflated:**
  sessions `14z-N`; milestones `M0`..`M12`; freeze marks `donovan-m18` /
  `merged-m14`. **Shape:** letter suffixes mark CONTINUATIONS, same-day or
  after a close (`14z-82c`, `14z-110b`, `14z-117b`, `14z-125b`, `14z-126b`);
  parenthetical numbers are PHASES within one sitting (`14z-107 (11)`,
  `14z-118 (14)`).
  **It is a LOOKUP KEY, and that is the load-bearing part.** "STATE 14z-XX"
  resolves in STATE.md, then STATE_HISTORY.md, then DECISIONS_HISTORY.md —
  section names are preserved verbatim across every rollover *precisely so
  the key keeps resolving*. Hundreds of pointers into it live in gate
  headers, annotated tag messages, `patch_notes.md`, gotcha datelines and
  THE LEDGER's lines. **So a tag is never renamed, renumbered or tidied**:
  renaming one silently breaks every citation, and a citation that cannot
  resolve cannot be corrected ([VSP-13]).
  **`14z-` IS A FOSSILISED PREFIX — READ IT AS ONE OPAQUE TOKEN. THE LIVE
  COUNTER IS `-N`.** We are NOT "in session 14" and never have been since
  2026-07-30: `14z-126` is the 126th session of the `14z-` series, nothing
  more. Session 14 itself was ONE sitting, 2026-07-28, the M2a freeze — for
  scale, the MiSTer arc did not open until `14z-106`, 2026-08-22, 104
  sessions later. Anyone reading the prefix as a live continuation of
  session 14 has been misled by its ETYMOLOGY, which is only this:
  **ORIGIN — RECONSTRUCTED FROM THE ARCHIVE 2026-09-01, not lost.** The name
  is a CHAIN OF EXHAUSTED COUNTERS, each continued by suffix rather than
  re-based: plain integers (`Session 3`, `4`, `5-6`, `7`, `9`, `13`) →
  `Session 14` continued through the alphabet (`14b`…`14x`, `14z`, with
  `14w-b`/`14w-c`/`14k-b` where a letter itself continued) → the letters
  exhausted at **`14z`**, so continuation moved to a NUMBER (`14z-2`,
  `14z-3`, … `14z-126`) → and letters resumed one level down (`14z-126b`).
  Each stage FOSSILISED the one before it instead of restarting, which is
  why the head of the name stopped carrying meaning. Dates (pickaxed from
  the archive): Session 14 2026-07-28, `14b` 2026-07-28, `14z` 2026-07-30,
  `14z-2` 2026-07-30, `14z-59` 2026-08-03. **They are also what show a
  "session" is a CONTEXT WINDOW rather than a day** — 25 letter sessions
  inside three days, ~8/day.
  **WHAT IS STILL NOT RECORDED, stated as unverified rather than theorised:**
  why session 14 alone began taking letter continuations, and whether the
  practice was inherited with the SMS working discipline. **THE SEARCH THAT
  BACKS THAT: THIS REPOSITORY ONLY** — the archive, every doc, and the git
  history to the first commit (2026-07-25). No commit or document defines
  the convention; it is only ever used. The answer may exist in the SMS
  material or predate the first commit, neither of which was searched.
- **[VSP-11]** Address notation: 68k addresses as `PRG:0x0F1234` (program ROM offset) or
  `CPU:$0F1234` (address-space); tiles as `GFX:tile 0x1A2B3`; RAM as
  `RAM:$FF8000`. Never bare hex without a namespace.
- **[VSP-12]** **Documentation taxonomy (SMS-proven; respect the splits, don't merge).**
  `docs/` is divided by ONE question — **would this still be true if we
  abandoned the roster hack tomorrow?** — into `docs/game/` (Vampire
  Savior itself), `docs/platform/` (CPS-2, MAME, FBNeo) and
  `docs/project/` (this port). Read `docs/README.md`; file by the FACT,
  not by the task you were doing when you learned it. Every hand-written
  document declares its SHAPE in `docs/doc_shape.tsv` (REFERENCE / REGISTER
  / LOG / HIST / INDEX / GENERATED); chronology lives in `<name>_history.md`
  twins, never re-accreting into a reference document
  (`tests/test_docshape.sh`).
  The documents themselves — what each is for, which are GENERATED, and
  the entry points — are the routing table and "The documents, by role" of
  `docs/README.md`: read it first, it is the map. Three disciplines that
  roster carries stay law here: every synthesis section of
  `docs/game/engine_internals.md` names the `atlas/` rows it depends on and
  the gates that lock it (a section that did not is how 14z-69 spent three
  sessions measuring a mode it had never entered); the GENERATED indexes
  (`docs/annotations.md`, `docs/project/gate_index.md`, `docs/GOTCHAS.md`)
  are regenerated in the commit that changes what they index, never
  hand-edited; and the skills (`.claude/skills/<name>/SKILL.md`, the
  DISTILLED DISCIPLINE loaded before the work) are anchored `**[PFX-N]**` in
  the doc paragraph each rule distils and locked by `tools/checkskills.py` —
  a skill quotes a number only from a LOG, and editing an anchored paragraph
  means keeping the marker with the fact or moving the rule. Gotchas are
  appended the moment one is paid for, to the bucket its FACT belongs to.
  Findings land in the right document *at discovery time*, not at milestone
  end. An undocumented discovery is a discovery we will pay for twice.
- **[VSP-13]** **RETRACTION DISCIPLINE (standing order, 14z-71): when a claim changes,
  GREP FOR THE CLAIM — not for the files you remember writing it in.**
  A finding does not live in one place. It propagates into section
  HEADERS, summary lines, registry rows, gate comments, the GOTCHAS index
  and `NEXT_SESSION`, and the copies outlive the correction. Fixing "where
  I remember writing it" is how a document ends up asserting the opposite
  of the subsection directly beneath it (measured twice in one session:
  `engine_internals.md` carried "the 214+P explosion is NOT a tile-inventory
  defect" as a HEADER above the subsection proving it was, and a corrected
  effect-family finding survived in five other places). The procedure, in
  order:
  1. `grep -rn "<the old claim>" docs HANDOFF.md STATE.md STATE_HISTORY.md DECISIONS_HISTORY.md tests build/manifest`
     — search the assertion's WORDING, and its paraphrases, across the repo.
     The archives are in the list on purpose: archived entries are not
     rewritten, but a claim that ONLY survives there must still be found so
     its live carriers can be traced. (DECISIONS_HISTORY.md: resolved
     decisions move there verbatim from STATE.md once they stop shaping
     active work.)
  2. Fix the **HEADER and the summary line** first. A skimmer reads those;
     an appended "actually, it turned out…" subsection does not reach them.
  3. Re-grep afterwards and show the empty result. The pass is not done
     because it feels done.
  4. Keep the superseded analysis, marked RESOLVED/RETRACTED with what
     replaced it — the eliminations usually stay valid even when the
     conclusion does not. **Status headers track reality; historical
     entries are not rewritten.**
  A claim that cannot be found cannot be corrected, and a stale claim in a
  header is worse than no documentation: it is confidently wrong, and it
  is what a future session will act on.

- **[VSP-14]** **BUG ARCHAEOLOGY FIRST (standing order, 14z-75): before fixing a bug,
  check whether it has already been fixed once — and if you are unsure, ASK
  THE MAINTAINER.** They were there and will usually remember.
  1. `git log --oneline --grep="<symptom>"`, `git log -S "<manifest row>"`,
     and `grep STATE_HISTORY.md` for the symptom's wording
     BEFORE forming a theory. A defect the maintainer reports may be a
     REGRESSION of something already solved, and the old fix (or its
     withdrawal) is the fastest route to the mechanism.
  2. Find the build where it was last known good and **diff it against its
     predecessor.** The delta is the answer, and it is cheap.
  3. **If the record is ambiguous about whether it was ever fixed, ask before
     measuring.** One sentence from the maintainer beats an afternoon of
     rigs, and a wrong assumption here is expensive in both directions:
     re-fixing something already fixed, or declaring "never fixed" about
     something that was.
  Paid for in 14z-75: a "never fixed" conclusion published from rigs that
  never fired the move, corrected by the maintainer who remembered the fix
  working; the archaeology took two commands, the wrong conclusion took
  hours and reintroduced the crash.

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
