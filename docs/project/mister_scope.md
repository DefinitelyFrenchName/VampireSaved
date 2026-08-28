# MiSTer SCOPE — what the documentation/skill distillation should carry, and where each boundary falls

Written 14z-113 (2026-08-28) as **the agreed first step of the
documentation/skill-distillation effort — SCOPE ONLY, NOT THE SKILLS**
(maintainer, 2026-08-27, STATE 14z-112 "queued"). It answers four questions
and stops: what skills should exist, where each boundary falls, which docs
feed which, and what is known-stale. Every source named below was READ IN
FULL for this document (`docs/platform/mister.md` 2063 lines,
`docs/project/mister_map.md` 1065, `docs/project/mister_core.md` 871,
`docs/project/cps2_wide.md` 635, `docs/project/mister_fit.md` 262, the
HANDOFF "MiSTer" section, `tools/mister_mra.sh`, `tools/run_sim_jtcps2.sh`
and `tools/gen_vsavjw_xml.py` headers, the 14z112 bundle README) — nothing
here is summarised from session memory, and where a source is stale the
staleness is listed in §6 rather than silently corrected.

**Ground truth at the time of writing** (git, not prose): fork pin
`63496069` = `v1.7.3-24-g634960697` (24 fork commits, 24 patches in
`emu/jtcores-patches/`); romset merged-m9 (M8 mark, program fingerprint
`32007911`), repackaged as `build/m3b_merged17` (not registered, not
frozen); field test PASSED on a DE10-Nano at 14z-109, #99 CLOSED at 14z-112;
bundle `../mister_fieldtest_14z112/` awaiting the board's answer on stock
coexistence.

---

## 1. The one rule the split rests on

`docs/README.md` files knowledge by ONE question — *would this still be true
if we abandoned the roster hack tomorrow?* The skill split uses the same
test at one remove: **a skill is game-independent if a stranger porting a
different CPS-2 game onto a wider jtcps2 could use it unchanged.** That is
the line between level 1 and level 2 below, and it is checkable per fact:
if a paragraph names `vsav`, a tenant, a tile ceiling of ours (`0xEE73`,
`0xFFDB`), a fingerprint or a build directory, it is level 2.

Two consequences, stated because they decide several placements:

* **The runtime profile bit (MRA header byte 41) is level 1.** It is a
  jtframe/jtcps2 mechanism — a spare header byte, active-low because
  `[header] fill=0xff`, decoded by `jtcps2w_profile.v` — and nothing about
  it knows Vampire Savior. The VALUE `0xFE` on the `vsavjw` set is level 2.
* **The SDRAM placement is level 1 in its RULES and level 2 in its
  NUMBERS.** "A CPS-2 tile code IS its SDRAM address", "an 8-bit slot caps
  at `SDRAMW`", "the download reserves the declared region, not the live
  footprint" are platform facts. `GFXC5_OFFSET = 23'h3F0000` and "bank 1 is
  exactly full" are consequences of THIS romset's declared sizes and belong
  to level 2 — but the map is one artefact and should not be split down the
  middle; it lives at level 2 with its level-1 rules cited.

---

## 2. Level 1 — CPS-II / WIDE CORE (game-independent)

Five skills. Each row gives the boundary (what it covers / what it must
NOT absorb), the sources it distils, and the gates that keep it honest.

| # | skill | covers | does NOT cover | primary sources (read these) | gates / tools |
|---|---|---|---|---|---|
| 1.1 | **jtcores separate-core mechanism** | how `cores/<x>` pulls shared RTL through `cfg/game.yaml`; why an override costs the whole yaml that pulled it (dedup by path); the twin discipline (reference cores byte-untouched, whole-tree delta enumerated, patch series mirrored); macros.def parity; the uprev bill (paths moved, `.cab` inputs, `files.yaml`) | anything inside the override files themselves (that is 1.3/1.4) | `mister.md` "How the CPS-2 core is put together", "THE COST OF AN OVERRIDE", "What an uprev … would cost", "Measured 14z-106: the twin proof"; `mister_core.md` §1, §11; `cps2_wide.md` "THE MiSTer EDITION" row "bounded and declarative" | `test_jtcores_twin.sh` (pin, twin, series, 2e/2f), `tests/expect/cps2w_game_yaml_delta.txt`, `tools/setup_jtcores.sh` |
| 1.2 | **the runtime profile bit** | which header byte is free and why; active-low forced by `fill=0xff`; `RawData`/`Selectable` scoping in the TOML; `jtcps2w_profile.v` as a static config bit; the `[parse] sourcefile` regex as a SECOND profile gate in the mapping tool; "gated at both ends" (source AND destination) | the list of gated sites (that is the ledger in 1.4) | `mister.md` "The runtime profile gate"; `mister_core.md` §8; `mister_map.md` §9 Q8 | `test_mister_wide_gate.sh` (profile byte in all three copies, polarity controls), `test_mister_mra_map.sh` (byte 41 = `0xFF`/`0xFE` end to end) |
| 1.3 | **SDRAM: tiers, slots and placement rules** | 64 MB is physical at v1.7.3 (bank-core table, ROW/COW ternary, 13 A pins, single nCS); XL exists upstream only, two-chips-on-one-module by nCS polarity, cache-lane only, silent-alias trap; analog I/O vs dual-SDRAM pin conflict; 8-bit slot caps at `SDRAMW` (negative replication); offsets are ADDs, elaboration-time, therefore un-gateable relocations; tile code IS SDRAM address (scramble ∘ interleave); the THREE SIZES of art; bank arbitration `BAPRIO`, autoprecharge on ba0, all-miss ceiling 123,825/frame | our numbers — which region sits where (level 2, skill 2.2) | `mister.md` "The numbers that bound…", "The SDRAM ceiling at our pin", "The 128 MB tier EXISTS UPSTREAM", "XL is NOT reachable by a flag", "jtframe's 8-bit SDRAM slot CAPS", "The per-bank SDRAM traffic profile"; `mister_core.md` §3, §4, §5, §6 "Why bank 1 can take the load"; `mister_map.md` §1, §2, §4; platform gotchas 1115/1142/1188/1258 | `audit_sdram_bank_load.sh` (both legs), `test_mister_wide_gate.sh` 3d/3e, `audit_mister_map_fit.sh` scramble-identity control |
| 1.4 | **the CPS-2 core's format caps and the WIDE RTL** | the five caps (obj bank 2→3 bits via the Turbo promote AFTER the terminator test; flat 4 MB `rom_cs` + `one_wait`; 7-bit QSound latch, `dsp_ab[7]` validated against MAME LLE; scroll 8 MB with no bank input — untouched; the DECRYPTION RANGE word stored complemented — a reference-core defect, not a format); the nine gated sites as a ledger; the four ungated widths and why they are inert; what would break it (declared-region growth, catalogue regeneration, CRC-only member lookup) | the profile's FBNeo/MAME halves (`cps2_wide.md` proper — already its own document) | `mister_core.md` §7, §8 table, §10, §11; `mister.md` "What the CPS-2 CORE caps", "The QSound bank bit IS `dsp_ab[7]`", "CAN THE 68k READ ABOVE 4 MB?", "SLICE D5"; `mister_map.md` §6, §7, §8, §10; `cps2_wide.md` "THE MiSTer EDITION" (gated-site table, ungated widths) | `test_mister_wide_gate.sh` (frozen `tests/expect/cps2w_rtl_delta.txt`, the two exhaustive benches in `tests/rtl/`, section 9), `test_mister_prg_probe.sh`, `test_mister_prg_window.sh` |
| 1.5 | **the simulation lane and its instruments** | jtsim under Verilator on macOS (deps, scratch clone, `-load` mandatory because the key is latched during the transfer, `-setname` re-downloads and moves dumps, ~1 s/frame); `sim_inputs.hex` grammar at the pin (P1 + P2 since 14z-109, buttons 4-6 refused; MSB-first joystick nibble); the work-RAM dump hook (SDRAM address, PER CORE); the SDRAM read probe (burst beats, distinct blocks = tile codes, four slots for honesty); the image census; the 68k program-ROM probe; the OBJ-list oracle (VRAM is NOT an oracle); the harness defects paid for (fork rewind, held buttons, reversed nibble, model top bit) and THE INSTRUMENT PROTOCOL | the replays themselves and the anchor VALUES (level 2) | `mister.md` "The simulation lane", "Recipe", "THE LANE'S SDRAM MODEL WAS WRONG", "The work-RAM oracle", "THE HARNESS'S FRAME WRITER…", "`SimInputs` HELD BUTTONS…", "THE SIMULATED JOYSTICK'S DIRECTIONS…", "THE SDRAM READ PROBE", "Bounding the frame writer", "THE SDRAM IMAGE CENSUS"; `mister_core.md` §9, §12 "Video compared against MAME"; project gotchas 2878 (THE INSTRUMENT PROTOCOL) | `test_sim_wram_contract.sh`, `test_rpl2siminputs.sh`, `test_obj_records.sh`, `tools/run_sim_jtcps2.sh`, `tools/check_wram_dumps.py`, `tools/mister_sdram_census.py`, `tools/prgprobe_verdict.py`, `tools/oram_obj_records.py` |
| 1.6 | **synthesis and release of a bitstream** | Quartus 20.1.1 Lite in Docker (`--network host`, clone-then-checkout ordering, `GIT_TERMINAL_PROMPT=0`, control core FIRST); fit vs timing as SEPARATE verdicts; `xjtcore.sh` = `jtseed 4` retry-until-pass hides fragility; a failing seed still emits an `.rbf`; the build datestamp makes the hash artefact-specific; RELEASE POLICY — named seed, recorded slack and sha256, verify before flashing; attribution of timing paths to shared `jtframe_sdram64`, not the slices | the field-test procedure (level 2, it needs our MRAs) | `mister.md` "SYNTHESISING THE CORE"; `mister_core.md` §12 SYNTHESIS rows; `quartus_brief.md` (historical, four-verdict framing reusable); platform gotchas 1709/1755/1810; NEXT_SESSION (HISTORY) 14z-108 banner | none automated — the seed/slack/hash record is the only defence; **no `.rbf` is tracked in this repo** (see §6) |

**What level 1 deliberately leaves out.** The MRA generator's traps
(`mame2mra`: CRC-only lookup, hard-coded `$HOME/.mame/roms`, `parts=`
collapsing under `width>8`, wrapped header words, the generated
`doc/mame.xml` catalogue, `pos` counting the 20-byte key) are platform
facts and belong in level 1 — but they are ALSO the whole mechanism of the
level-2 catalogue skill, so they are filed once, under **1.7 MRA/`.rom`
generation mechanics** (`mister.md` "HOW THE MRA AND THE `.rom` ARE MADE";
platform gotcha 1304; `mister_map.md` §2, §3), and level 2.3 cites it
rather than repeating it.

---

## 3. Level 2 — VS-specific (dies with the project)

| # | skill | covers | does NOT cover | primary sources | gates / tools |
|---|---|---|---|---|---|
| 2.1 | **what the roster demands** | the deficit per region (836 KB PRG, 13× the blank-tile budget for GFX, 918 KB QSound extension in banks `0x80-0x8E`); the two group-C code counts and why they differ (write set vs non-blank census); the frozen extents `0xEE73`/`0xFFDB`/`0x8E57F0`/`0x5FFF1E` | why the profile is 6/48/16 (that is `cps2_wide.md`) | `mister_fit.md` §1-§4 (its §5/§6 are retracted routing history — keep for eliminations); `mister_core.md` §2 and the two-counts box | `audit_mister_map_fit.sh`, `tests/audit_gfx_merged_census.sh` |
| 2.2 | **the placement map** | where every region lands (bank 0 re-pack, QSound split on `pcm_addr[23]`, group C one obj bank per SDRAM bank), the whole-tier arithmetic (0.125 MB slack, bank 1 exactly full), the trim that is MANDATORY, `jtframe_ram1_7slots`, the measured load figures on the WIDE image, what can and cannot grow | the platform rules it applies (1.3) | `mister_map.md` §0, §3, §5, §9 Q1/Q5; `mister_core.md` §5, §6 | `test_mister_sdram_census.sh` (four legs), `audit_mister_map_fit.sh`, `test_mister_wide_gate.sh` section 7, `test_mister_page.sh` (`tools/mk_mister_page.py --check`, 17 figures) |
| 2.3 | **catalogue, MRA and bundle generation** | `gen_vsavjw_xml.py` (the `vsavjw` entry is `vsavj`'s verbatim except sourcefile/description/ROM map; regenerated from the built zip because members resolve by CRC32); the `qsoundw` trim region and its generic `skip=true` twin; **the MiSTer leg is pinned to ONE romset build's CRCs, so every re-freeze has a MiSTer TAIL** (new fork commit + patch NNNN + pin bump + regenerated bundle); `mister_mra.sh` (private `$HOME` staging, `--wide`, `--toml/--xml` perturbation for controls); ONE-ZIP PACKAGING since 14z-112 (patched group-A members inside `vsavjw.zip`, pristine parent, stock coexists); bundle layout, the STOCK CONTROL MRA, `check_mra_parts.py` (unresolved parts are `0xFF`-filled, never refused) | the generator's mechanics (1.7) | `mister_map.md` §3 "Three things D0 found"; HANDOFF "BUILDING THE MRAs AND THE `.rom`" + registry rows' "MiSTer tail" clauses; STATE 14z-112 "WIDE NO LONGER BREAKS STOCK"; bundle `README.txt`; `tools/mister_mra.sh` header | `test_mister_mra_map.sh`, `test_mra_parts.sh`, `tools/gen_vsavjw_xml.py --check`, `tools/check_mra_parts.py` |
| 2.4 | **the WIDE oracles on the core** | the anchors and their provenance (stock MAME 2146 / sim 2609 / +463; tenant 2886 / 3546 / +660; WIDE transfer 659 vs stock 462, every absolute frame moves by 197); the fetch demonstration (obj bank 5 105 codes, obj bank 4 1,735 codes, control leg zero); QSound extension fetched (DSP bank `0x83`); the tenant field oracle with P2 excluded BY NAME (sound-fed lottery); the OBJ-list oracle on the PROMOTED subset; wide-inert (cps2 == cps2w on stock) | the instruments (1.5) | `mister_core.md` §9 table, §12; `mister.md` "THE ANCHOR MEASUREMENT", "WITH SLICE D5 IN", "The per-bank profile of the WIDE image"; HANDOFF gate table rows | `test_mister_sim_anchor.sh`, `test_mister_wide_inert.sh`, `test_mister_gfxc_fetch.sh`, `test_mister_qsound_ext.sh`, `test_mister_tenant_oracle.sh`, `test_mister_obj_oracle.sh` |
| 2.5 | **field test and triage** | what hardware answers that simulation cannot (pixels, voices heard, real SDRAM/timing/analog chain); the negative control (stock `vsavj` on the same `.rbf`); the triage card (black vs RAM-test vs boot loop and its period; name-screen reboot = CPU exception vs gold test = watchdog); FIELD REPORTS ARE RECORDINGS (CLAUDE.md §4) — a board crash is captured as a MAME `.inp` first; the 14z-109 result and the #99 chain as the worked example | the crash tooling itself (project-level, not MiSTer) | NEXT_SESSION (HISTORY) 14z-108/109 banners; STATE 14z-109 (in STATE_HISTORY) (3)-(8); bundle `FIELD_TRIAGE.txt` (14z111/14z112 bundles); CLAUDE.md §4 "FIELD REPORTS ARE RECORDINGS" | `test_inp_corpus.sh`, `tools/run_inp_guarded.sh`, `tools/run_inp_probe.sh` |

---

## 4. Which docs feed which

```
  platform/mister.md  (LOG — wins on disagreement)
        │  provenance of every number
        ├──────────────► project/mister_core.md  (SYNTHESIS, causal order;
        │                     ▲                    tools/mk_mister_page.py --check
        │                     │                    re-derives 17 figures)
  project/mister_fit.md ──────┤  demand
  project/mister_map.md ──────┤  placement + slice plan + open questions
  project/cps2_wide.md  ──────┘  the profile; "THE MiSTer EDITION" = Rule 1 v2 on FPGA
        │
        ├── HANDOFF.md "MiSTer" section  — operational: commands, gate table, pin,
        │                                  push state, the MiSTer tail of a freeze
        ├── docs/{platform,project}/gotchas.md — the paid-for traps (13 MiSTer
        │                                  headings in platform, the INSTRUMENT
        │                                  PROTOCOL in project)
        ├── project/quartus_brief.md    — historical brief, four-verdict framing
        ├── project/patch_index.md      — registry of emu/jtcores-patches (STALE, §6)
        └── NEXT_SESSION.md (HISTORY)   — the 14z-107..109 banners: the only place
                                          the FIELD TEST and its triage are narrated
```

Reading order for a stranger: `mister_core.md` → the three logs for any
figure they doubt → HANDOFF for the commands → gotchas before touching an
instrument. The skills should preserve that order; a skill that quotes a
number must cite the log, not the synthesis (the synthesis's own
staleness rule).

---

## 5. Where the boundaries are NOT clean, so the skills do not paper over them

1. **`cps2_wide.md` is three documents in one** — the FBNeo/MAME profile
   (ratified), the B4 diagnostic narrative (historical), and "THE MiSTer
   EDITION" (the governance clauses on FPGA). Only the third is MiSTer
   scope; the skill cites it and leaves the rest alone.
2. **The instrument defects are platform facts with project scars.** The
   fork-rewind, the held buttons and the SDRAM-model top bit are upstream
   jtframe bugs (level 1, fixed in the fork, unconditional); the reversed
   direction nibble is OUR translator's (level 2, `tools/rpl2siminputs.py`).
   A skill that says "the sim input path is only as tested as the last
   replay that used it" is level 1; the fix location is level 2.
3. **The freeze ritual's MiSTer tail is level 2 but is triggered from
   outside MiSTer** (any romset re-freeze). It must be cross-referenced
   from the build/freeze skill when that is written, or it will be skipped
   again — it was skipped at 14z-110 and 14z-110b (STATE 14z-111 audit).
4. **The `.rbf` is a release artefact with no home in the tree.**
   `release/mister/jtcps2w.rbf` is cited by `mister_core.md` §12,
   `mister.md` "SYNTHESISING", NEXT_SESSION 14z-108 — and `git ls-files
   release | grep rbf` is empty; the bitstream lives on the Windows box and
   in the field bundles outside the repo. Whether it SHOULD be tracked
   (3.1 MB, GPL output, not ROM content) is a maintainer decision; the
   skill must not imply it is reproducible from the tree (it is not: the
   datestamp).

---

## 6. Known-stale inventory (measured 14z-113) — **THE PASS RAN 14z-113, same session, after the maintainer's board results (ruling (2))**

Each item names the file:line, what it said, what is true now, and the
session that moved it. **Status after the pass: S1-S12, S14-S17, S19, S20
FIXED IN PLACE** (header/summary first, history kept and marked, the
correcting session named at each site); **S13** was never a defect;
**S18** is RE-STATED at each site (the `.rbf` is a build-tree path, to be
tracked in-tree per the 2026-08-28 ruling — the tracking itself is the
open RELEASE FORMAT item, not a doc fix). Line numbers below are as
measured BEFORE the pass. The measurement records inside `mister.md`
that name `build/m3b_merged13` (§ "It is not the romset", the bank-load
runs) were left as written — they are logs of runs on that image; only
the OPERATIONAL commands (HANDOFF, the Recipe) were re-pointed.

| # | where | says | true now | moved at |
|---|---|---|---|---|
| S1 | `docs/project/mister_core.md:24-29` "Ground truth" | pin `dd242a653c2797d3`, "fifteen fork commits", romset `build/m3b_merged13` | pin `63496069` (24 commits; `tools/setup_jtcores.sh:66`), romset merged-m9 / `m3b_merged16` (and `merged17` repackaged) | 14z-108..112 |
| S2 | `docs/project/mister_core.md:83` | "As of slice D4 that diff is twelve files" | THIRTEEN `.v` + `pal_lut.hex` = fourteen since D5 (`cps2_wide.md:200`, HANDOFF:269) | 14z-107 (11) |
| S3 | `docs/project/mister_core.md:855` §12 "Any of this on HARDWARE" | "never — … the MiSTer field test … has not begun" | field test PASSED 14z-109 (boots, tenants play, voices heard, #99 found and later closed) | 14z-109 |
| S4 | `docs/project/mister_core.md:850` §12 QSound row | "Fetched is NOT heard" | tenant voices HEARD on the board ("fetched is not heard" retired, NEXT_SESSION 14z-109) | 14z-109 |
| S5 | `docs/project/mister_core.md:845` §12 "DRAWN — NOT CHECKED" | no cross-implementation check of a picture | still true for PIXELS; but the OBJ-list oracle (row below it) and the board's select screen ("emulator-identical", 14z-109) exist — the row should point at both | 14z-109 |
| S6 | `docs/project/mister_core.md:76`, `mister.md:23-24` | distribution "plus a stock-`vsav` reference-leg MRA" as a plan | shipped: `[STOCK CONTROL].mra` in every bundle since 14z-109; and since 14z-112 the bundle packs NO `vsav.zip` of its own | 14z-109, 14z-112 |
| S7 | `docs/platform/mister.md:32` "the fork's commits" | lists 11 commits, series `0001`-`0011` | 24 commits / 24 patches; D3, D4, D5, the prg probe, P2 scripting (`4dfc3734`), README, and the five catalogue-CRC commits (`0020`-`0024`) are absent | 14z-107 (10) onward |
| S8 | `docs/platform/mister.md:1593-1595` | a 14z-112 correction was spliced INTO the middle of a sentence: "reads a hard-coded **CORRECTED 14z-112: …** Historically the parent was … `$HOME/.mame/roms`." — the sentence no longer parses | needs re-flowing: hard-coded `$HOME/.mame/roms`; parent now pristine | 14z-112 (the edit itself) |
| S9 | `docs/platform/mister.md:60`, `:74`, `:1833` | "exactly eleven entries", "68 lines different", "six files in `cores/cps2w/hdl`" | 22 entries, 73 lines, thirteen files (HANDOFF:476, `mister_core.md:93`) — the D2-era counts were left as-written when D3-D5 landed (the D2 attribution is correct history; the summary lines are not) | 14z-107 (10)-(11) |
| S10 | `docs/platform/mister.md:1927-1933` "Open / to verify" | P1-only harness, `02_demitri_vs_cpu`/`04_select_fuzz` refuse | partially updated in place (P2 done); the bullet still opens with the 14z-106 state as its lead sentence | 14z-109 |
| S11 | `docs/project/mister_map.md:5` | pin `74ed17d` | `63496069` | 14z-107 (5) onward |
| S12 | `docs/project/mister_map.md:34-54` header | "obj bank 4 — the FIGHTER art — has never been fetched", "No tenant has ever been in a match on the core … nothing has run on hardware" | all three happened (14z-108 fetch + match; 14z-109 hardware). The paragraph's own "FIXED 14z-108" was appended without rewriting the header claims | 14z-108, 14z-109 |
| S13 | `docs/project/mister_map.md:9-15`, `mister_fit.md:8-12` | (fine) | — kept in the table so the "log wins" rule is seen to have been checked: both logs still agree with the synthesis on every NUMBER; the disagreements above are all STATUS, not measurement | — |
| S14 | `docs/project/mister_fit.md:1-4` | measured on `build/m3b_merged13` (merged-m6) | the provenance line is stale in NAME only: `audit_mister_map_fit.sh:52` re-derives the frozen ceilings (`0xEE73`, `0xFFDB`, `0x5FFF1E`) from `build/m3b_merged16` on EVERY run and passes, so those extents are verified on the current freeze. What is NOT gate-verified is §1's wide_ext high-water mark `0x4D10F3` — merged-m9 shifted the extension (+0x10D0/+0x1ED0/+0x2B60, STATE 14z-111) and that figure was never re-scanned. Quote it as merged-m6's | 14z-111 |
| S15 | `docs/project/patch_index.md:35-41` | registers `0001`-`0007` only; `0007` marked "**LOCAL-ONLY (not pushed)**" | 24 patches exist; the fork has been public and current since 14z-107 (9) with pushes standing-authorised (HANDOFF:271) | 14z-107 (9) onward |
| S16 | `tools/mister_mra.sh:41-43` usage | `--wide BUILD_DIR stage BUILD_DIR/rompath/{vsavjw,vsav}.zip` | a 14z-112 build has no `rompath/vsav.zip`; the code handles both (line ~125 NOTE), the usage text does not say so. The HEADER (lines 11-21) was corrected at 14z-112 — the correction NEXT_SESSION asked this document to verify is IN PLACE | 14z-112 |
| S17 | `docs/README.md:59-66` `mister_map.md` row | "D0, D1 and D2 done … D3, the obj promote, is next" | D0-D5 done; the whole arc through hardware | 14z-107 (10) |
| S18 | `docs/project/mister_core.md:853`, `mister.md:2062`, `NEXT_SESSION.md:347` | `release/mister/jtcps2w.rbf` as a path in this repo | not tracked (`git ls-files release` has no `.rbf`); it is a path in the jtcores SCRATCH/Windows tree — see §5.4 | 14z-108 (never was) |
| S19 | `docs/project/cps2_wide.md:1-11` | "v1 DRAFT, awaiting ratification … Ratification happens after Phase B" | ratified (round 66 per CLAUDE.md rule 1 v2; B0-B5 PASS; three implementations shipped). The header is the oldest stale claim in the set and is the document Rule 1 v2 points at | 14z-59..66 |
| S20 | HANDOFF "MiSTer" section, lines 173-488 | internally current, but written as accretion: the D3-era boot-failure trace, the pre-D5 commands on `build/m3b_merged13`, and `--wide build/m3b_merged13` in every example | examples should name the current build (`m3b_merged16`/`17`); `merged13` was DELETED in the 14z-112 build-dir sweep (`build_dir_triage.md`), so every quoted command is now non-runnable as written | 14z-112 |

**Not stale, verified:** the nine gated sites and their files
(`mister_core.md` §8 = `cps2_wide.md` table = `test_mister_wide_gate.sh`);
the placement offsets (`mister_map.md` §5 = `mister_core.md` §6 =
HANDOFF gate row); the anchors (2146/2609/463, 2886/3546/660); the
`.rom` sizes and header words; the seed/slack/hash release policy; the
14z-112 correction in `mister_mra.sh`'s HEADER (S16 is its usage text,
not its header).

---

## 7. Holes the skills must state rather than hide

Carried from `mister_core.md` §12 and re-checked against 14z-109..112:

* **Pixels have never been compared programmatically** between the core
  and MAME — the board's "select screen emulator-identical" is a human
  verdict; the OBJ-list oracle is the list, not the frame.
* **Audio has never been compared** — voices are HEARD (14z-109) and not
  measured; jtcps15's missing one-read bank latency vs MAME LLE is
  recorded and unresolved.
* **Timing closure is a seed lottery** (4/12 fail); the shipped `.rbf` is
  seed 18269, slack +0.066, sha256 `46fc74af…`, unchanged since 14z-108.
  Spending margin back is a Rule 1 v2 design decision, not a seed hunt.
* **Bank 1 under load** is measured on ONE replay / ONE tenant / one
  opponent (12.5% peak, zero clashes).
* **The rest of the CPS-2 library under D5's range fix** is deliberately
  unreached (profile-gated); real silicon's decryption window is INFERRED.
* **The 128 MB module's chip-select polarity** is inferred from RTL, never
  from a schematic; XL remains the fallback and is not a flag.
* **`mister_fit.md`'s demand figures are merged-m6's** (S14) — a skill
  quoting "836 KB deficit" must say which freeze it was measured on.

---

## 8. What this document asked the maintainer to decide — ALL RULED 2026-08-28 (STATE 14z-113 "Decisions pending")

**Rulings:** (1) split confirmed as written; (2) the staleness pass is MANDATORY before distillation and WAITS for the board results being produced in parallel — **both happened the same day, the pass ran (§6)**; (3) the `.rbf` and the MRAs are tracked in-tree under `release/`, which opened the RELEASE FORMAT item — **ruled the same day: one self-sufficient directory per platform, every version releases every platform; `docs/project/release_format.md`, first instance `release/merged-m10/`**. Skill 2.3 (catalogue/MRA/bundle generation) should therefore cite `release_format.md` and `tools/package_release_platforms.py` as the bundle's home; §5.4 and S18 are resolved by it. The questions as put:

1. **Confirm the split** (§2 six + one shared, §3 five) or move rows.
   The one judgment call worth a second look: 1.7 (MRA mechanics) filed at
   level 1 with 2.3 citing it.
2. **Whether the staleness pass (§6) runs BEFORE the skills are written.**
   Recommendation: yes, and as its own commit — a skill distilled from S1,
   S3, S12 and S15 as they stand would state that the core has never run on
   hardware and that seven patches exist. Cost: one session's retraction
   pass; the synthesis (`mister_core.md`) and `patch_index.md` are the two
   documents where a skimmer's first read is currently wrong.
3. **The `.rbf`'s home** (§5.4): track it, or state in the docs that it is
   an out-of-tree artefact reproducible only by seed + date.
