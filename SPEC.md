# SPEC — Vampire Saved: Full-Roster Vampire Savior (CPS-2, emulator-target)

Status: draft v0.1 — for review before Claude Code work begins.
Companion documents: `CLAUDE.md` (operating rules), `STATE.md` (living progress log).

## 1. Goal

A modified CPS-2 `vsavj` (Japan 970519) romset in which all 18 Vampire series characters are
selectable, running on the genuine Vampire Savior engine with byte-for-byte
vanilla behavior for all original content, playable in FBNeo (primary target)
and MAME (verification target), with a MiSTer CPS-2 core patch as a stretch goal.

### Non-goals (v1)

- Real CPS-2 hardware support. The graphics address-space ceiling that forced
  Capcom to ship two split games makes this a hardware project; explicitly out
  of scope until v1 ships.
- New balance, new moves, new characters beyond the official 18, netplay
  features, or training-mode facilities. (A training hack already exists for
  vanilla vsav; compatibility with it is a nice-to-have, not a requirement.)
- Story-mode completeness for the ported three (endings, arcade-run cutscene
  parity) is a stretch item within v1 polish, not a gate.

## 2. Background facts the design rests on

- `vsav`, `vsav2`, and `vhunt2` are three official builds of the same
  Savior-generation engine (1997). VS2/VH2 contain Donovan, Huitzil, and Pyron
  as native Savior-engine data — no Hunter-engine backporting is required.
- Capcom split the roster across two games because the full cast exceeded the
  CPS-2 graphics ROM address space. Our emulator-target framing turns that
  hard wall into a driver-descriptor change.
- VS2/VH2 differ from vsav in system details (air-chain rules and other
  tweaks). The ported characters' data was authored against those variants;
  reconciling it with vanilla vsav rules is the central design risk (§6, R1).
- In VS2/VH2, holding Start while selecting Donovan/Huitzil/Pyron selects the
  *other* game's flavor of that character. Both behavioral datasets therefore
  exist in Savior-engine form, and Capcom's own VH2 variants are the canonical
  answer to "these characters, Hunter-flavored, on this engine."
- CPS-2 encryption is fully broken; all work happens on decrypted sets.

## 3. Character adaptation policy

1. **Authoritative base = VS2 data.** It is the only ground truth for these
   characters on a Savior-family engine. Port faithfully; do not improvise.
2. **Engine reconciliation is explicit and documented.** Wherever VS2 data
   invokes a mechanic vanilla vsav handles differently, the reconciliation
   (which rule wins, what value was chosen) is recorded per-instance in
   `docs/project/tables/reconciliation.md`. Nothing is silently adapted.
3. **VH2 variants are extracted alongside**, delta-documented against the VS2
   base, and kept buildable — ideally exposed via Capcom's own Start-hold
   convention at character select, otherwise as a build flag.
4. **Everything a player can feel is a table entry**, published for community
   review. Default ship = faithful VS2 base; the community may bless VH2-style
   defaults later by changing config, not code. Expectation to plan for: the
   community may well prefer the Hunter-flavored variants as default.

## 4. Milestones

Each milestone has acceptance criteria; none is passed by inspection alone.

**M0 — Bench.** Repo scaffold, checksummed reference sets, decryption
pipeline, deterministic build producing a byte-identical copy of vanilla
`vsavj` from manifest (the null patch), headless FBNeo/MAME runners working.
*Accept:* null-patch output SHA-1 equals reference; a scripted 60-second
attract-mode replay checksums identically across two runs.

**M1 — Map.** Three-way romset diff atlas (code and data, provenance-tagged);
work-RAM map for match state; identification of: character ID plumbing,
roster/select-screen tables, per-character data manifests (code, animation
scripts, tile ranges, palettes, sound cues) for at least the three ported
characters and two control characters present in all three sets.
*Accept:* atlas documents let us answer "where does character X's <thing>
live in each set" without new disassembly; oracle replay harness runs a
10-replay legacy suite green.

**M2 — Proof of life (make-or-break).** One ported character (Donovan)
selectable in `vsavj` by *replacing* an existing slot — no ROM expansion, no
driver changes, therefore fully trusted vanilla emulator as oracle.
*Accept:* full matches Donovan-vs-several-characters on several stages, both
sides, human-playtested plus replay matrix; all legacy replays (matches not
involving the replaced slot) remain bit-identical; crash-free soak of
scripted arcade runs. Findings decide the reconciliation approach (§3.2)
before any further porting.

**M3 — Expansion.** FBNeo driver descriptor enlarged (gfx + QSound regions);
Donovan *relocated* to new space instead of replacing; matching MAME driver
change; dual-emulator frame-agreement harness live.
*Accept:* legacy suite green on patched builds (proves the descriptor change
is inert for vanilla content); Donovan suite agrees frame-by-frame between
patched FBNeo and patched MAME.

**M4 — Full roster.** Huitzil and Pyron ported via the M2/M3 methodology;
18-slot select screen (layout, portraits, names, cursor logic, order),
character ID space extended everywhere it matters (win quotes, AI opponent
tables, versus screens).
*Accept:* every cell of the 18×18 matchup matrix completes a scripted match
crash-free; select-screen navigation fuzz test clean; legacy suite green.

**M5 — Sound and stage policy.** QSound banks for the three (voices, hit
cues); music/announcer decisions; stage assignments; arcade-mode opponent
order including the new three; behavior with Shadow/Marionette and Oboro
systems defined and tested.
*Accept:* audio present and correct per a human listening pass + cue-trigger
replay tests; secret-mode interaction matrix documented and green.

**M6 — Release engineering.** Patch-only distribution (xdelta/BPS against
named reference dumps), reproducible build docs, the public data-table /
reconciliation dossier for community review, variant toggle finalized,
community beta round, bug-fix cycle.
*Stretch within M6:* MiSTer jtcps2 core patch mirroring the descriptor
change; VS2/VH2-based sibling builds if trivial; story-mode completeness.

## 5. Verification (summary — normative text in CLAUDE.md §4)

Superset invariant enforced by oracle replays against vanilla `vsavj`; new
content verified by dual-emulator (FBNeo/MAME) frame agreement; test matrix
grows monotonically with capabilities; edge-case-biased replay authoring;
divergence reports = first divergent frame + RAM diff.

**Persistent suite doctrine (SMS-proven, project law):** every in-emulator
test performed during development is committed as a scripted, rerunnable case;
the suite is the project's most valuable artifact, above unit/integration
tests. The runner auto-detects the build's feature set via fingerprints and
selects expectations accordingly, so one command validates any build variant.
Test verdict logic is itself validated against ground-truth scenarios before
its classifications are trusted.

## 6. Risk register

- **R1 — Engine delta (highest).** VS2 character data may reference mechanics
  vanilla vsav implements differently or not at all; failure mode is subtle
  (wrong cancel windows) rather than loud (crashes). Mitigation: M2 exists
  precisely to surface this early on trusted tooling; reconciliation log;
  edge-case replay bias; community playtest round per character.
- **R2 — Tile index space.** Animation data references tiles by index; adding
  ~3 characters' sprite sets requires rebasing indices or extending index
  width. If index fields are narrower than the enlarged space, this escalates
  from data rebase to code surgery. Investigate width limits during M1.
- **R3 — RAM layout.** Ported characters' state structures may assume VS2 RAM
  layout details; collisions with vsav's layout would violate the superset
  invariant. Mitigation: full match-state RAM map in M1 before any port.
- **R4 — Select screen rigidity.** 15/16-slot layout assumptions may be baked
  into rendering code in unpleasant ways. Contained risk (cosmetic domain),
  but budget real time in M4.
- **R5 — Emulator-mod trust.** Mitigated structurally (descriptor-only
  changes, dual-emulator agreement, legacy suite proving inertness).
  Residual risk accepted and documented.
- **R6 — Secret systems.** Shadow, Marionette, Dark Talbain, and Oboro
  interact with character ID logic in ways that may assume the original
  roster size. Enumerate ID-dependent code paths in M1; dedicated tests in M5.
- **R7 — Scope creep.** The community will ask for VS2/VH2 system options,
  training features, netplay. All post-v1 by policy (§1 non-goals).

## 7. Decisions made and open questions (tracked in STATE.md)

**Decided:**
- Base revision = **`vsavj`, Japan 970519** (2026-07-24, maintainer): Japan is
  the default for competitive Vampire Savior. All checksums, diffs, and
  patches target this set.

**Open (human decisions):**
1. Replaced-slot choice for M2 (needs to be a character whose absence doesn't
   block early playtesting; recommendation to follow M1 findings).
2. Default variant policy pending community input (§3.4), and where the
   Start-hold toggle should live.
3. Credits and the community-review venue for the tables dossier
   (project name DECIDED 2026-07-25: **Vampire Saved**).
4. Whether Dark Talbain/Oboro-style hidden access or direct select is wanted
   for anything beyond the core 18 (recommendation: core 18 only, v1).

## 8. Legal and distribution stance

No ROM content is committed or distributed, ever. Deliverables are patches
against named commercial dumps, tools, and documentation. Contributors supply
their own reference sets. The dossier documents findings, not extracted assets.
