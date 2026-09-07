# HARNESS SCOPE — extracting the generic black-box harness (`blackbox-harness`) from this project

> **STATUS (written 14z-135, 2026-09-06): THE PLAN BEFORE THE WORK — scope,
> the four bins, the slices and the fidelity contract. H1 LANDED the same
> session** (`~/Developer/blackbox-harness` at `803f372`: the classifier,
> the static runner, the tier classifier, the demand-after-trap lint, the
> config reader, the example consumer, seven selftests 7/0/0, F1 and F3
> green — §4). Two things are already RULED (maintainer, 2026-09-06, at the plan
> stage): the harness is a SEPARATE repository, `~/Developer/blackbox-harness`
> (beside this tree's PARENT `~/Developer/Vampire_Saved/`, not a sibling of the
> tree — measured 14z-138; PUBLIC on GitHub since 14z-135b at the maintainer's
> word — https://github.com/DefinitelyFrenchName/blackbox-harness, branch `main`),
> and this project gains exactly ONE read-only fidelity gate. Everything else in §7 is a default open to veto.
> Slice status is tracked in STATE (the session entries) and in §4's table,
> which is updated in place as slices land. **AS OF 14z-138 (2026-09-07)
> EVERY SLICE IS LANDED — H1-H7 and H9's gate (H8 decided out); the harness
> is at `512747b`, this tree carries `tests/test_bbh_fidelity.sh`, and the
> next deliverable is the SKILL.**

Written 14z-135 as the agreed first step of the maintainer's backlog item
(2), recorded in STATE "Decisions pending" on 2026-09-05 (14z-133b) in their
words: *"go through all our documentation and rules and rulings and
principles regarding our test harness (including files up to CLAUDE.md) and
extract the harness from the specificities of this project. The goal is not
to replace the custom harness of this project but to create a separate, more
generic one, able to be reused in other projects, especially such black-box
adjacent projects. Then after that is done, distill the skill that goes with
that generic harness."* Deliverable order, ruled: the harness FIRST, the
skill AFTER. This project's own harness STAYS AS IT IS.

This document is the sibling of `mister_scope.md` and `skills_scope.md`: it
answers what is generic, what is not, where each piece goes, in what order,
and how the extraction is PROVED — then stops. Every source it names was
READ IN FULL for it by a measured census at the 14z-135 opener (the three
inventories are the session's record): `tests/run_all_static.sh` (269
lines), `tests/run_all_emulator.sh` (536), `tests/run_suite.sh` (203), the
seven `tests/lib/*.sh` (751), `tests/lua/replay.lua` (459),
`tests/lua/replay_guard.lua` (646), the five comparators and
`tools/s4_thresholds.py`, `tools/build_fingerprint.py` (230), the eight doc
tools, the runners' two ground-truth gates (`test_static_runner.sh` 163,
`test_emulator_runner.sh` 404), `tests/expected/PROVENANCE.md`, CLAUDE.md
§4/§5, `oracle_classes.md`, `gate_scoping_method.md`,
`harness_hardening_history.md` "THE CLASSES", and the header of every one
of the 304 gates (machine-read). Nothing here is summarised from session
memory; every count below is reproducible by the grep in the census.

**Ground truth at the time of writing** (git, not prose — read the tree,
not this paragraph, once a slice has landed): this tree at `3f4c00c7`
(14z-134 CLOSE (2)); 304 gates under `tests/*.sh` (233 `test_`, 67
`audit_`, 4 `run_`); registries `tests/ci_portable.txt` (64 gates),
`tests/ci_static.txt` (71), `tests/ci_emulator.tsv` (165 rows); 4,021
frozen expectation files in 52 directories (1,891 `.masked`, 617 `.sha1`,
628 `.skip`, 39 `logs/` directories, ZERO live `.diverge`); 181 replays;
7 tracked `.inp` recordings; 130 `tools/*.py`; 32 `tests/lua/*.lua`. The
SailorMoonS reference (`~/Developer/SailorMoonS`) is on this machine and
was read for its harness shape only (`tools/health.sh`,
`tools/test_regression.lua`, `tools/checkdocs.py`).

---

## 1. The one question the extraction rests on

`docs/README.md` splits the documentation by one question — *would this
still be true if we abandoned the roster hack tomorrow?* — and
`skills_scope.md` §7 lifted 109 of 145 CPS-2 rules by asking it one level
up — *would this still be true if the board were not CPS-2?* The harness
asks it one level further:

**A harness piece is GENERIC if it would still be true when the thing under
test is not this ROM, not CPS-2, not even a game.**

The stranger-test form: *a stranger testing a black-box system that produces
a deterministic per-frame state under scripted inputs — another arcade
board, a console, an emulator of anything, a simulator, a firmware image —
could use the piece unchanged, with every project fact supplied as
configuration.* The mechanical form, applied file by file in §2: if a piece
names `vsavj`, `vsavjw`, a tenant, a build directory, a work-RAM address, a
port tag, a member regex, an emulator binary path, a mask window or a
frozen frame number IN ITS CODE, that name is either a parameter (the piece
lifts) or the piece stays.

Every piece therefore lands in exactly one of FOUR BINS:

| bin | the test it passes | what lands there |
|---|---|---|
| **code** | true for anything under test | the verdict classifier, the two runners, the registry grammar, the transitive "needs an instrument" classifier, the comparators and the log grammar, the masked-comparison vocabulary, the suite's dispatch order, the driver contract, the sandbox discipline, shadow tools, the gate prologue and demand rules, the header contract and the gate index, provenance both-ways, the rot classes, the `.rpl` grammar, the FNV-1a64 checksum |
| **config** | true once the consumer declares a VALUE | every path, every regex that names a wrapper, the placeholder vocabulary, the mask default, the thresholds, the fingerprint member regex and parent set, the field-compare anchor predicate and bases, the gate families, the hooks (precondition, banner, reference-ok predicate) |
| **machine profile** | true for a CPU/board, false for another | CPU and address-space tags, the RAM window, the port map and token widths, the exception vectors and the exception store, the match flag |
| **stays** | true for this game only | `tests/lib/decrypt_cache.sh`, `m2a_common.sh`, `pairing.sh`, `tenant_build.sh`, `tools/cps2_decrypt.py`, `tests/fields_m2a.tsv`, `tools/audit_roms.py`, all 304 gates, all frozen expectation sets, the atlas, the MiSTer/Verilator driver (`tools/run_sim_jtcps2.sh`) |

The harness is the first three bins. It ships with an EXAMPLE CONSUMER (a
deterministic fake machine, §3.4) so that every one of its own selftests
runs without a ROM, without MAME and without this tree — the same test the
level-0 skills passed ("the skill directory is the portable unit").

## 2. The inventory, piece by piece

Column `bin` is the verdict of §1's test; `parameterisation` names what a
consumer must declare for the piece to be true of its system. Source paths
are this tree's; the target paths are §3's.

### 2.1 Runners and registries

| # | piece | source | bin | parameterisation | ground truth that travels |
|---|---|---|---|---|---|
| R1 | THE VERDICT CLASSIFIER — exit≠0 → FAIL; 124/137 → TIMEOUT; exit 0 with the shell's own `<script>.sh: line N: NAME:` line in the log → FAIL; exit 0 with `^ *SKIP` → SKIP; else PASS. SKIP IS NOT PASS; `--strict` makes SKIP fatal | `tests/run_all_static.sh` (the exit/SKIP branches) and `tests/run_all_emulator.sh` (the same plus the TIMEOUT and shell-error branches) — TWO COPIES today, the emulator one stronger | code | `skip_regex`, `shell_error_regex`, `timeout_exits`, `fail_tail` (defaults = today's literals) | the classifier sections of `test_static_runner.sh` and `test_emulator_runner.sh` |
| R2 | the STATIC runner — tiers portable/static, PASS/SKIP/FAIL/MISSING tallied separately, `--strict`, `--list`, `--tier`, the anti-orphan report, the working-tree snapshot before/after | `tests/run_all_static.sh` | code | `gates_dir`, the two registry paths, `static_needs_env` (today `ROMDIR`), runner prefixes to exclude | `tests/test_static_runner.sh` (7 sections, incl. the all-SKIP-is-not-GREEN control and the synthetic unregistered gate) |
| R3 | the SWEEP runner — lanes, scope, cadence, `args` with placeholders, per-row timeout, `--jobs` with per-slot scratch, `--resume`, prereq lane first and a red there stops the run, completeness both ways, the instrument banner | `tests/run_all_emulator.sh` | code | `lanes` (order = run order), `prereq_lane`, `scopes`, `cadences`, `default_timeout`, `precondition` (a command; today `python3 tools/audit_roms.py "$ROMDIR"`), `banner` (a command; today the five build fingerprints + the MAME/FBNeo/jtsim identities), `scratch_lanes`/`scratch_env`, `env_defaults` (today `MAME_BIN`), the placeholder table (today five build roots + the `_RP` suffix) | `tests/test_emulator_runner.sh` (13 sections) |
| R4 | the transitive "needs an instrument" classifier — strip comments, regex over the body, follow sourced `tests/lib/*.sh` to depth 2 — duplicated in both runners | the inline python in both runners | code | `patterns` (today the MAME/FBNeo/Verilator wrapper names and binary variables), `source_regex`, `source_depth` | a new `test_tier` (the project has no separate ground truth; the runner tests exercise it through the anti-orphan report) |
| R5 | the registry grammar — bare names with `#` comments (portable/static); TSV `gate / lane / scope / cadence / args / note [/ timeout]` with `-` = the gate's own defaults and `VAR=value` tokens as environment | `tests/ci_portable.txt`, `ci_static.txt`, `ci_emulator.tsv` headers | code | none — the grammar IS the harness's; the vocabularies of columns 2-4 are config (R3) | R2/R3's tests |
| R6 | the SUITE — fingerprint the build → expectation set; every replay run TWICE (nondeterminism fails); dispatch `.skip` → `.pending` (FAIL) → `.masked` → `.diverge` → `.sha1` → NO-EXPECTATION (FAIL); `--freeze`; the hermetic environment scrub; `SUITE_ONLY` | `tests/run_suite.sh` | code | `replays_dir`, `expected_dir`, `registry`, `default_set`, `driver` (today the MAME wrapper, hard-named at one line), `runs_per_replay`, `mask_env`/`mask_default`, `hermetic_unset`, `hash_cmd` | `tests/test_suite_dispatch.sh` §2 (check_diverge on synthetic logs); the dispatch loop itself has NO ROM-free ground truth today — the harness adds one over the fake driver |
| R7 | the accounting rule — "BATTERY GREEN" cannot print when a gate self-skipped; every gate call goes through the counted wrapper | `tests/run_battery_m2.sh` + `tests/test_battery_accounting.sh` §3 | code (the functions) | none | `test_battery_accounting.sh` §3 |

### 2.2 Comparison: the log grammar, the classes, the checkers

| # | piece | source | bin | parameterisation | ground truth |
|---|---|---|---|---|---|
| C1 | the log grammar — one `<frame> <fnv1a64-hex>` line per frame, `END <n>` last; parsed by three private `load()` copies | `tools/compare_flicker.py`, `compare_window.py`, `compare_composite.py`, `check_diverge.py` | code | none; ONE `logfmt` module replaces the three copies | the four comparator tests |
| C2 | the classes — exact; flicker-tolerated (isolated ≤2-frame divergences, ≥60-frame re-convergence, ≤8 total); frozen first-divergence constant; bounded re-convergent window (one contiguous run, fixed onset, full re-convergence, end state untouched — and a bit-identical pair FAILS it); composite (the strict conjunction); the ≥60 rule intra-mechanism | `oracle_classes.md` v1-v6 (definitions), the three comparators, `tools/s4_thresholds.py` (FLICKER_MAX 2, RECONVERGE 60) | code, with the numbers as config | `flicker_max`, `reconverge`, `flicker_max_total` (defaults 2/60/8) | `test_compare_flicker.sh`, `test_compare_window.sh`, `test_compare_composite.sh`, `test_s4_thresholds.sh` (one declaration, tools agree) |
| C3 | the MASKED vocabulary — the one implementation of `masked_check` (exact/flicker/diverge/window/composite spec lines), `masked_mask_for`, the baseset-vs-mask guard, the `<set>/mask` and `<basis>/MASK` records, `logs/<name>.log` | `tests/lib/masked_compare.sh` | code | `mask_default` (today `043c-043d,4182-41a2,7f00-8000`, offsets from the RAM window's base), `expected_dir` | `tests/test_masked_compare.sh` (fixtures already synthetic) |
| C4 | first-divergence constant — line-identical through frame−1, first divergence exactly at the frozen frame, length mismatch is a hard FAIL | `tools/check_diverge.py` | code | the `<set>/logs/` layout | `test_suite_dispatch.sh` §2 |
| C5 | the expectation-KIND enumeration — so an audit cannot silently ignore a kind | `tests/lib/enumerate_expectations.sh` | code | `replays_dir`; the kind list is the harness's (a new kind is registered here) | `audit_legacy_pairings` uses it; the harness adds a direct test |
| C6 | per-frame dump completeness — `--first/--last`, `--size`, `--addr`, `--contiguous`; exists because the field comparator globs | `tools/check_wram_dumps.py` | code | `dump_regex` (today `dump_<frame>_<addr>.bin`, FBNeo's `<hout>.dump_…` variant) | none today (exercised inside two MiSTer gates); the harness adds `test_check_dumps` |
| C7 | mapped-field comparison at anchors — the §4 dual-implementation protocol: fields TSV, `--anchor` finds the rising edge of a predicate on each side, `--follow`, `--exact` for same-implementation | `tools/compare_fields.py` | code, with the predicate as config | `fields.table`, `bases` (today p1/p2 work-RAM bases), `anchor` (today four `addr/width/value` clauses — HARD-CODED IN SOURCE, the one comparator whose game fact is in code), `dump_regex` | `tests/test_compare_fields_selfcheck.sh` (re-based on fake dumps) |
| C8 | the spec-line proposer and the basis freezer — propose a `.masked` spec from a measured pair; write a basis with the three write-side guards | `tools/describe_masked_shape.py`, `tools/freeze_masked_basis.sh` | code | mask, expected dir, the driver | `test_s4_thresholds.sh` (describe agrees with the comparators); `test_freeze_basis_sandbox.sh` |

### 2.3 Dispatch by fingerprint

| # | piece | source | bin | parameterisation | ground truth |
|---|---|---|---|---|---|
| D1 | fingerprint = sha1 of the PROGRAM members of the first zip found along a `;`-separated search path (mirrors the emulator's resolution); `--set-key` the whole-set key over the build's own directory; two key spaces, whole-set first then program (loudly); exit 2 on an unregistered image | `tools/build_fingerprint.py` — imports `cps2_decrypt` ONLY for the member regex and the parent-set name | code | `kind` (`zip-members` today; `file-sha1` and `command` for consumers that are not zip sets), `set_glob`, `program_member_regex`, `parent_sets`, `region_rules` (for `--full`) | `test_suite_dispatch.sh` §1/1b on SYNTHETIC zips (already ROM-free: the dual key, whole-set-only row unreachable by the program fallback, key independent of the chain) |
| D2 | the registry — `sha1 / expectation-set / notes`, rows only at freeze time, every row an annotated tag | `tests/expected/registry.tsv` | code (grammar) | the file path | `test_freeze_tag_coverage.sh` (stays: tags are this repo's) |

### 2.4 Replays, drivers and the instrument layer

| # | piece | source | bin | parameterisation | ground truth |
|---|---|---|---|---|---|
| I1 | the `.rpl` grammar — `<frame>[-<frame>] <who>=<tokens>`, `who ∈ p1|p2|sys`, one-char player tokens, two-char `sys` tokens, `N wait`, lines OR together, frame 1 = first emulated frame | `tests/lua/replay.lua` lines 36-48 (spec), the parser at ~99-137 | code | the token→port map is the PROFILE's (I5); the grammar is fixed | `test_replay_stage_census.sh` (stays — it pins THIS tree's 10/11 split); the harness adds `rpl.py` (a lint) and `rpl_parse.lua` as one module |
| I2 | THE DRIVER CONTRACT — `<set> <replay.rpl> <out.log> [sandbox]` + environment (`MASK_RANGES`, `DUMPS`, `POKES`, `SNAP_FRAMES`, `VIDEO_OUT`, `INPUT_OUT`, `NO_INPUT_CHECK`), the log grammar out, `END` required, `INPUT-VIOLATION` rejected, exit semantics | `tools/run_replay_mame.sh`, `run_replay_guarded.sh`, `run_replay_fbneo.sh` — already the same shape | code | which driver; a driver that cannot honour a variable REFUSES (the guard's precedent), never ignores | new `test_driver_contract` over the fake driver |
| I3 | the MAME sandbox — fresh `mktemp` for cfg/nvram/diff/snap/sta/home, `SDL_VIDEODRIVER=dummy`, every input provider `none`, `-video none -sound none -nothrottle -skip_gameinfo` | `tools/run_mame.sh` | code — the most reusable file in the tree | `MAME_BIN`, the rompath chain | `test_mame_determinism`, `test_attract_determinism` (stay: they need the ROM); parity only through fidelity F8 |
| I4 | the replay engine — parse, stage per frame, checksum the RAM window (FNV-1a64), `MASK_RANGES` (masked bytes SKIPPED, so a mask is a BASIS), `DUMPS`, `POKES`, `SNAP_FRAMES`, `VIDEO_OUT`, and the always-on INPUT-INTEGRITY assertion | `tests/lua/replay.lua` | code | the PROFILE (I5) | none ROM-free; F8 |
| I5 | THE MACHINE PROFILE — every literal `replay.lua` carries: CPU tag `:maincpu`, space `program`, screen `:screen`, RAM window `0xff0000-0xffffff`, three port tags and 22 field names, `sys` token width 2, the integrity ports and the probe field; plus for the guard: the crash vectors `2,3,4,5,6,7,24`, the group-0 stack layout, the exception store, the match flag | `replay.lua` lines 55-92, 160, 206-224, 261, 279, 337; `replay_guard.lua`; `inp_guard.lua` | machine profile (`profiles/cps2.lua`) | one Lua table per board; `TEMPLATE.lua` says what a new board fills in | `profile.lua` validates required keys; the cps2 profile is proved by F8 |
| I6 | the crash guard — authoritative mode (`-debug`, breakpoints on the CPU's exception vectors read at boot) and cheap mode (per-frame PC vs code ranges); `CRASH/PCWEEDS/SOFTRESET/END-CRASH`; refuses `MASK_RANGES` | `tests/lua/replay_guard.lua`, `tools/run_replay_guarded.sh` | code, with the CPU facts in the profile | profile (vectors, `pc_at_sp`), `GUARD_*` env | `test_crash_guard.sh` (stays: positive controls need the ROM); F8 |
| I7 | the taps — debugger watchpoints (`trace_writes`), the non-debug PC-attributed write tap (`tap_writes`) and read+write tap (`read_tap`), headless snapshots (`snapshot_frames`) | the four Lua files | code (the COLLECT mode's "offset %8 == 4 is a tile code" is CPS-2 and stays as an example) | profile (CPU tag, window) | none ROM-free; the API is MAME's |
| I8 | recordings — `<name>/{NOTE, <name>.inp, nvram/}`, `DEFECT` declares a captured-but-unfixed crash, naming `<what>-<freeze>-NN`, playback against a throwaway nvram copy, the terminator written only when frames > 0 so a dead run stays un-terminated, the corpus gate replays everything and fails on the first exception | `tests/inp/`, `tools/run_inp_guarded.sh`, `tests/lua/inp_guard.lua`, `tests/test_inp_corpus.sh` | code, with the exception-store tap in the profile | profile (`exception_store`, `arm_frame`), the corpus dir | the corpus gate's liveness check (a zero-frame run) travels |
| I9 | the FBNeo leg — the patched frontend's `-hinput/-hout/-hframes/-hdump`, `FBNEO_ROMPATH` overlay (no `-rompath` exists), stale-artifact removal (the frontend returns 0 unconditionally) | `tools/run_replay_fbneo.sh` | code (a second driver of the same contract) | `FBNEO_BIN`, the overlay | none ROM-free |
| I10 | the MiSTer/Verilator driver | `tools/run_sim_jtcps2.sh` | STAYS — jtframe-shaped, the download offset, the per-core RAM-dump offset; a fourth driver later if ever | — | — |

### 2.5 Expectation hygiene and gate hygiene

| # | piece | source | bin | parameterisation | ground truth |
|---|---|---|---|---|---|
| E1 | PROVENANCE — one row per frozen file (`file / owner gate / subject / rests on / re-freeze / since`), a CLOSED evidence-class vocabulary, completeness BOTH ways; `hash-lock` locks currency never correctness | `tests/expected/PROVENANCE.md`, `tests/test_expectation_provenance.sh` | code | `page`, `scope` globs, `columns`, `evidence_classes` | the gate itself (two must-fire controls) |
| E2 | a gate's HEADER states the default its CODE uses — path tokens on a `Usage:` or default line must be one of the code's defaults; backticked tokens and `(verbatim; …)` archive blocks exempt | `tools/audit_header_defaults.py`, `tests/test_header_defaults.sh` | code | `default_token_regex` (today `build/<dir>`) | the gate (`--root` controls) |
| E3 | reference ROT — a hard-coded default that EXISTS but no longer serves (today: a pre-WIDE-v1.1 zip by member count); absent is not rotted; only defaults the code READS are checked | `tests/test_build_ref_rot.sh` | code, with the rot test as a hook | `predicate` (a command; today the member-count rule), `reads_marker_regex` | the gate's own control sections |
| E4 | the demand-after-trap lint — `${VAR:?}` after an armed EXIT trap exits 0 on macOS bash 3.2 | `tests/test_demand_after_trap.sh` | code — fully generic | none | the gate (synthetic scripts, both directions) |
| E5 | THE GATE HEADER CONTRACT — line 1 `#!/bin/sh`, line 2 `# <name>.sh — <claim>` through the first blank `#` (the index sentence), `Usage:`, a runtime `~N min/s`, `MUST-FIRE`, the tier phrase; 304/304 conform today | every gate; read by `tools/gen_gate_index.py` | code (`gate_header` parser) + a documented contract | `title_regex`, `session_regex` | `test_gate_index_current.sh` |
| E6 | THE GATE INDEX — GENERATED from the registries + `gate_index.tsv` (family, needs, since overrides) + each header's first paragraph; families hard-coded today | `tools/gen_gate_index.py`, `tests/gate_index.tsv` | code | `families` table, `index_out` | `test_gate_index_current.sh` (both ways) |
| E7 | shadow tools — a WRITABLE copy of one tool inside a throwaway repo root whose siblings are symlinks, for perturbation controls that must never touch the tracked tree | `tests/lib/shadow_tools.sh` | code | `tools_dir`, `shadow_link_dirs` (today `build tests docs`) | its four callers; the harness adds a direct test |
| E8 | the gate PROLOGUE — `set -eu`, `REPO=$(cd "$(dirname "$0")/.." && pwd)`, demands BEFORE the trap, `mktemp -d` + `trap … EXIT`, a `SKIP:` line + exit 0 for a missing prerequisite (or a loud FAIL under release policy) | 301 of 304 gates | code (`prologue.sh` helpers: `bbh_work`, `bbh_skip`, `bbh_fail`, `bbh_demand`) + the contract text | none | E4 + a prologue test |
| E9 | THE MUST-FIRE CONVENTION — a gate perturbs an input and requires its own check to FAIL for the stated reason; a control that passed for the wrong reason is a failure; a dead control refuses a verdict. Three shapes: perturb one byte (52 gates), shadow copy with a line stripped (4), synthetic tree / known-bad reference (6+3) | 93 of 304 gates | code (the doctrine and helpers) | none | every selftest in the harness carries one |

### 2.6 Method — what the docs say that is not about this game

| # | piece | source | bin | what changes on lifting |
|---|---|---|---|---|
| M1 | THE SEVEN ROT CLASSES — orphan, silent downgrade, dead control, stale reference, outgrown parser, deleted mechanism, missing operand — each with its cure, and the diagnostic that beats all of them (a red gate's runtime vs the runtime its header quotes) | `harness_hardening_history.md` "THE CLASSES" | code (a method document) | the dated pass entries stay here |
| M2 | GATE SCOPING — the reference is the source system and a second leg is an instrument check; scope the observable to what the mechanism can cause; compare ORDER not sets, assert structure and REPORT timing; refuse to judge a leg that did not produce the event; widen by measurement; diff a strengthened gate against what it replaced; capture before characterising; time the walk before choosing the method | `gate_scoping_method.md` §0-10 | code (method) | every Vampire Savior example becomes a fake-machine example; no `[VSP-N]` anchor travels (they are this project's skill lock) |
| M3 | THE ORACLE CLASSES — the definitions, the rule that a non-exact class is mechanism-attributed and frozen, never loosened without a new measured mechanism and sign-off, the standing watch (growth beyond the frozen inventory = stop and root-cause) | `oracle_classes.md` | code (method) | the mask string, the frozen frames and the named exemptions stay here |
| M4 | THE DOCTRINE — no untested change survives; the persistent suite (every in-emulator measurement becomes a rerunnable case); verdict logic is itself tested; recordings before theories; SKIP is not PASS; a red gate is a QUESTION whose first question is which side rests on a measurement; retraction discipline (grep the claim, fix the header first, re-grep); bug archaeology first | CLAUDE.md §4/§5, STATE "RELEASE-TIME TEST SCOPE" | code (method) | cited, restated for a generic reader; the LAW stays law here |

### 2.7 Explicitly NOT the harness

- The eight documentation tools (`checkdocshape`, `doc_anchor_census`,
  `checkdocs`, `checkskills`, `gen_gotchas_index`, `gen_annotations`,
  `gen_skill_guide`, and `gen_gate_index`'s doc side) pass §1's test as
  MECHANISMS, but their value is the documentation DISCIPLINE they enforce,
  which is the living-documentation effort's subject
  (`living_docs_scope.md`). Decided: out of the harness; a sibling package
  later if that effort wants one. `gen_gate_index` lifts because it reads
  GATES.
- Everything in the `stays` bin of §1.
- The skill. It distils something that exists; it comes after H9.

## 3. The repository

### 3.1 Layout (`~/Developer/blackbox-harness`, CLI prefix `bbh`)

```
blackbox-harness/
├── README.md                what it is, the four bins, quick start on the example
├── LICENSE                  §7
├── bbh.toml.example         the whole schema, every key commented
├── bin/
│   ├── bbh                  POSIX sh dispatcher: bbh <cmd> [--config bbh.toml] …; finds lib/ from $0
│   ├── bbh-run-static       <- tests/run_all_static.sh
│   ├── bbh-run-sweep        <- tests/run_all_emulator.sh
│   ├── bbh-run-suite        <- tests/run_suite.sh
│   ├── bbh-classify         CLI over lib/sh/classify.sh: <exit> <logfile> -> PASS|SKIP|FAIL|TIMEOUT
│   └── bbh-doctor           config, driver, python3, timeout(1), lua (optional) present?
├── lib/sh/
│   ├── classify.sh          THE verdict classifier — one copy, sourced by both runners
│   ├── registry.sh          read rows, select, expand placeholders (longest key first)
│   ├── config.sh            bbh_cfg <key> = a shim over lib/py/bbh/config.py (sh has no TOML)
│   ├── prologue.sh          gate-author helpers: bbh_work (mktemp+trap), bbh_skip, bbh_fail, bbh_demand
│   ├── masked_compare.sh    <- tests/lib/masked_compare.sh (verdict strings byte-identical)
│   ├── shadow_tools.sh      <- tests/lib/shadow_tools.sh
│   └── enumerate_expectations.sh
├── lib/py/bbh/
│   ├── config.py            tomllib else _minitoml; defaults; `python3 -m bbh.config get <key>`
│   ├── _minitoml.py         <- tools/_minitoml.py verbatim
│   ├── logfmt.py            the <frame> <hash> / END parser, once
│   ├── thresholds.py        <- tools/s4_thresholds.py, values from config
│   ├── compare_flicker.py  compare_window.py  compare_composite.py  check_diverge.py
│   ├── check_dumps.py       <- tools/check_wram_dumps.py
│   ├── compare_fields.py    <- tools/compare_fields.py, predicate + bases from config
│   ├── fingerprint.py       <- tools/build_fingerprint.py, no cps2_decrypt
│   ├── tier.py              the transitive needs-instrument classifier
│   ├── gate_header.py       the header contract parser (shared by index / defaults / rot)
│   ├── gen_gate_index.py    audit_header_defaults.py  ref_rot.py  provenance.py
│   ├── demand_after_trap.py accounting.py  rpl.py
├── lua/mame/
│   ├── profile.lua          loader: dofile(os.getenv("BBH_PROFILE")); validates required keys
│   ├── rpl_parse.lua        the .rpl parser as ONE module
│   ├── replay.lua  replay_guard.lua  snapshot_frames.lua  trace_writes.lua  tap_writes.lua  read_tap.lua  inp_guard.lua
│   └── profiles/cps2.lua  profiles/TEMPLATE.lua
├── drivers/
│   ├── README.md            THE DRIVER CONTRACT
│   ├── mame.sh  mame_guarded.sh  fbneo.sh
│   └── fake.sh              drives example/fakesys/fakesys.py through the same contract
├── selftest/
│   ├── run.sh               the harness's own pre-commit gate; ROM-free, no MAME
│   └── test_*.sh            one per lifted ground truth (§4 names them per slice)
├── example/                 THE EXAMPLE CONSUMER — a complete tiny project
│   ├── bbh.toml  fakesys/fakesys.py  fakesys/profile.lua
│   ├── tests/  tests/lib/needs_fake.sh  tests/ci_portable.txt  ci_static.txt  ci_sweep.tsv
│   ├── replays/*.rpl  expected/{registry.tsv, PROVENANCE.md, base/, build-a/, build-b/}
│   ├── consumers/bbh.vampire.toml   this project's consumer config (for the fidelity gate)
│   └── README.md            walkthrough: run green, freeze, break a control, watch it fire
├── docs/
│   ├── gate_contract.md  driver_contract.md  config.md  doctrine.md
│   └── method/rot_classes.md  method/gate_scoping.md  method/oracle_classes.md
└── skill/                   placeholder for the later deliverable
```

### 3.2 The config — one `bbh.toml` per consumer

Sections: `[project]` (gates dir, lib dir, runner prefixes, tools dir,
shadow link dirs), `[registries]`, `[tier]` (patterns, source regex, depth),
`[classify]`, `[sweep]` (lanes, prereq lane, scopes, cadences, default
timeout, precondition, banner, scratch lanes, env defaults) +
`[sweep.placeholders]`, `[suite]` (replays, expected, registry, default set,
driver, runs per replay, mask env/default, hermetic unset, hash command),
`[thresholds]`, `[fingerprint]` (kind, set glob, member regex, parent sets,
region rules), `[fields]` (table, dump regex, bases, anchor clauses),
`[gate_header]` (title regex, default-token regex, index out, families),
`[ref_rot]` (predicate, reads-marker regex), `[provenance]` (page, scope,
columns, evidence classes), `[machine]` (profile path). Paths resolve
relative to the config file. The sh runners read it through
`python3 -m bbh.config get <key>` once at start and export `BBH_*`. The full
schema with every key's origin bin is `docs/config.md`; the example's
`bbh.toml` and `consumers/bbh.vampire.toml` are its two worked instances.

### 3.3 The machine profile (`lua/mame/profiles/cps2.lua`)

One Lua table: `cpu`, `space`, `screen`; `ram = {lo, hi}` (the checksum
window; mask offsets count from `lo`); `ports` = the token → `{port tag,
field name}` map per `p1`/`p2`/`sys` with `token_width`; `integrity_ports`
and the `integrity_probe` field; `crash = {vectors, exception_store,
arm_frame, group0, pc_at_sp}`; `guard = {match_flag, match_value}`.
`TEMPLATE.lua` carries every key with a comment; `profile.lua` refuses a
profile missing a required key. The cps2 profile is the FIRST profile and
is proved by fidelity F8, not by inspection.

### 3.4 The example consumer — a fake machine so nothing needs a ROM

`example/fakesys/fakesys.py` is a deterministic machine: a 64 KiB RAM byte
array, three ports with the `sys` token width of 2, one `<frame> <hash>`
line per frame (FNV-1a64 over the window minus the mask) and `END <n>`.
Its behaviour is chosen by environment so every expectation class has a
producer: `FAKE_BUILD=base` (exact / `.sha1`), `hook` (one byte written a
frame late on input-accept frames — flicker), `select` (a contiguous range
touching one byte, then restore — window), `both` (composite), `attract`
(permanent divergence from frame N — diverge), `FAKE_NONDET=1` (the
nondeterministic path), `FAKE_CRASH_AT=n` (the guarded grammar); it honours
`MASK_RANGES`, `DUMPS`, `POKES`, `SNAP_FRAMES` (a `.ppm`), `VIDEO_OUT`,
`INPUT_INJECT_TEST` (an `INPUT-VIOLATION`). Two builds, `build-a` and
`build-b`, differ in one non-program member — the dual-key case (same
program key, different whole-set key) — and a third unregistered image
proves the loud exit 2. The example's gates cover every classifier outcome
(pass, skip, indented skip, prose containing the word, fail, skip-then-fail,
the `${X:?}`-after-trap shell error, a sleep for the timeout), one that
reaches the driver only through a sourced lib (tier transitivity), and one
whose must-fire control is a shadow-tool perturbation, so the selftests can
prove the control fires and refuse a verdict when it does not. This is the
runner ground-truth pattern this tree already uses
(`test_static_runner.sh` drives the real runner over a synthetic fake repo),
promoted to a whole project.

## 4. The slices — each independently shippable, selftests green ROM-free

| slice | lifts | ground truth that travels | status |
|---|---|---|---|
| **H1 core** | R1 (both copies merged, the stronger one wins), R2, R4, R5, E4, `_minitoml`, new `config.py` / `config.sh` / `prologue.sh` / `registry.sh`, `docs/gate_contract.md`, `example/` v1 | `test_static_runner.sh` (7 §), the classifier cases of both runner tests (`test_classify`), `test_demand_after_trap.sh`, new `test_tier` | **LANDED 14z-135**, harness commit `803f372`, 39 files: `bin/bbh`, `bbh-run-static`, `bbh-classify`, `bbh-doctor`; `lib/sh/{classify,config,registry,prologue}.sh`; `lib/py/bbh/{toml_subset,config,tier,demand_after_trap}.py`; `example/` GREEN on both tiers; `selftest/run.sh` 7 PASS / 0 SKIP / 0 FAIL (the tomllib-agreement section reports "not run" on this python 3.9 host). Fidelity: **F1 identical** over a synthetic fake repo (9 stub gates, a MISSING, an orphan, an emulator gate) and, with a shell-crash gate, EXACTLY the known delta (lineage PASS, generic FAIL, 7 diff lines); **F3 exact** — INSTRUMENT − plain registries − `run_` == the 165-row sweep registry, every PLAIN gate registered, every sweep row a real gate. Both rerunnable: `selftest/test_fidelity_vampire.sh` (F2 opt-in, `BBH_FIDELITY_F2=1`). One addition to the plan: `[project].root`, so a consumer config may live outside its tree (`example/consumers/bbh.vampire.toml`) |
| **H2 comparators** | C1-C5 (`logfmt` unifies the three loaders; thresholds from config; `masked_compare.sh` with its verdict strings untouched) | `test_compare_{flicker,window,composite}.sh`, `test_s4_thresholds.sh`, `test_masked_compare.sh` | **LANDED 14z-135b**, harness commit `ef7e899`: `thresholds.py` (declared once, consumer-overridable via `[thresholds]`, the proposer and the enforcers proved to agree under an override), `logfmt.py` (one reader), the five checkers with verdict text UNTOUCHED, `masked_compare.sh` (text frozen; mask default from `[suite].mask_default`), `enumerate_expectations.sh`, `docs/method/oracle_classes.md`; six selftests (lineage cases verbatim + config must-fire controls), suite 13/0/0. **F5 EXACT: all 1,891 `.masked` specs** (window 1,124 / composite 492 / exact 181 / flicker 49 / diverge 45), each paired with a different set's frozen log of the same stem, through both implementations — verdict text identical to the character, 229 s; in `test_fidelity_vampire.sh` (every 4th spec by default, `BBH_FIDELITY_F5=1` for all at a slice's pre-commit) |
| **H3 fingerprint + suite + fake driver** | D1, D2, R6, I2, `drivers/fake.sh`, `fakesys.py`, `drivers/README.md` | `test_suite_dispatch.sh` §1/1b (synthetic zips) and §2; NEW `test_suite_dispatch` over the fake driver — the dispatch loop's first ROM-free ground truth | **LANDED 14z-136**, harness commit `c26ba45`: `fingerprint.py` (the two keys and the dual lookup with the NOTE/UNREGISTERED text verbatim; `[fingerprint]` kind `zip-members` / `file-sha1` / `command`, the program regex, parent sets and region rules as config — no board module imported), `bin/bbh-run-suite` (the dispatch loop with EVERY verdict line the lineage's, `[suite]` driver / runs / mask env / rompath env / input env / hermetic list / hash command), `drivers/README.md` (THE CONTRACT: the four arguments, the replay family, the guard family, the rule that a driver REFUSES what it cannot honour, the grammar, the exit codes), `drivers/fake.sh` + `example/fakesys/fakesys.py` (64 KiB RAM, three ports, an attract → select → match machine; features `hook` / `select` / `attract` produce flicker / window / diverge, `both` composite, `FAKE_NONDET`, `FAKE_CRASH_AT`; honours the whole replay family, refuses the guard family), `rpl.py` (the grammar, pulled forward from H6 because the fake needs it — the Lua twin and the equality selftest stay H6), `make_roms.py` (five byte-reproducible images incl. the dual-key twins and an unregistered one) and `make_expected.sh` (the tree with its provenance: base by `--freeze`, the masked basis from two compared runs, the authored specs as literals). Four new selftests — `test_fingerprint` (§1/1b on synthetic zips + the kinds + the example's images against their generator), `test_driver_contract` (every row of the contract, incl. the INPUT-VIOLATION must-fire and the refusal), `test_suite_dispatch` (every verdict line, `--freeze` incl. the RETIRE, SUITE_ONLY, the hermetic scrub with its must-fire, the mask guard both ways), `test_rpl` (the grammar + every lineage replay parses). One addition to the lineage's enumerate: the `.diverge` kind (its copy would have reported a live one UNKNOWN-KIND; zero live today). The fake's per-frame hash is blake2b-64, not FNV-1a64 as §3.4 said — the grammar names no algorithm. **F6 EXACT** (48 invocations: the synthetic twin + `$ROMDIR` + build dirs, every flag, stdout+stderr+exit) and **F7 EXACT** (both suite runners over the lineage's real expectation trees in a shadow root with a stub driver, every verdict line) — figures in STATE 14z-136 |
| **H4 sweep runner** | R3 (precondition, banner, scratch as hooks/config; placeholder expansion longest-key-first) | `test_emulator_runner.sh` (13 §) over `example/tests/ci_sweep.tsv` with lanes `prereq fake` | **LANDED 14z-136 (the continuation)**, harness commit `81ad426`: `bin/bbh-run-sweep` — lanes in run order, the prereq lane serial and a red there stopping the run, scope and cadence with `--freeze` naming what it dropped, `--only`, `--jobs` with per-slot scratch on the scratch lanes, per-row timeouts, `--resume`, `--dry-run`, `--list`, the banner that fingerprints the builds and names the instruments, the exported env default with its caller-wins rule, the anti-orphan check through the ONE tier classifier; `[sweep]` carries every project noun (lanes, the release scope, the cadences and the drop note, the precondition and its text, the placeholders and the rompath suffix, the build sets, the instruments and env defaults, the scratch lanes, the prereq citation). `example/tests/ci_sweep.tsv` (lanes `prereq fake`, an `out` row) and three gates (the driver as the instrument check, the suite green on `build-a`, the refusal of `hook`). `selftest/test_run_sweep.sh`: the lineage's thirteen sections carried plus `--resume`, `--only`, the precondition hook, the input demand and the shipped example under `--strict`. **F4 EXACT**: `--list` (169 lines) and `--dry-run` (199 lines: the ROM audit, the fingerprinted builds, the instruments, every lane's resolved command, the coverage report) identical over the whole registry, `--scope all --lane all`; in `test_fidelity_vampire.sh` |
| **H5 expectation and gate hygiene** | E1, E2, E3 (predicate hook), E5/E6 (`gate_header.py`, families from config), E7, R7 | their five gates; `test_gate_index_current.sh`'s shape | **LANDED 14z-137**, harness commit `b533715`: `gate_header.py` (THE ONE header parser: the `#` block, the first paragraph as the claim, the session token, the runtime), `gen_gate_index.py` / `bbh gate-index` (`--check` / `--stdout`; `[gate_header]` families, kinds, needs keywords, the preamble as config lines; tier labels DERIVED from the registries' stems and the instrument word), `header_defaults.py` / `bbh header-defaults` (the lineage's rule and its three exemptions; `--fix`; `[header_defaults]` token and prefix regexes), `ref_rot.py` / `bbh ref-rot` (rot vs currency, verbatim lines; `[ref_rot]` a stale MARKER `[prefix, required, reason]` or a `predicate` command, an ORDERED `image_prefer` — the lineage fell back to DIRECTORY order, which on this host happened to list `vsavj.zip` before `vsav.zip`; the family regex; the notes and advice as config), `provenance.py` / `bbh provenance` (scope dirs with row prefixes, exclusions, the closed vocabulary, the `rests on` column; the lineage gate's sections 1-2 verbatim), `lib/sh/shadow_tools.sh` (`bbh_shadow_tool` / `bbh_shadow_restore`; `BBH_TOOLS_DIR`, `BBH_SHADOW_LINK_DIRS`, `REPO` or `BBH_ROOT`), `lib/sh/accounting.sh` (`bbh_bat` / `bbh_bat_group_skip` / `bbh_bat_report`; the verdict from the ONE classifier, so an exit-0 shell error and a timeout stop the battery where the lineage's wrapper read them as PASS). Six selftests (the lineage's controls carried + config must-fires each), the example gains `tests/gate_index.tsv`, `docs/gate_index.md`, `expected/PROVENANCE.md`, `tests/g_hygiene.sh`; `docs/hygiene.md`. **F9 EXACT**: header-defaults, `gate-index --check` AND the rendered index byte-identical to the committed file, provenance (the gate's sections 1-2), ref-rot (the whole 268-line report), demand-after-trap — stdout + exit diffed over this tree. Pre-commit at full scope PASS 24 / SKIP 0 / FAIL 0 (fidelity 767 s). One robustness fix the selftests found: the fingerprint EXITS on an image with no program members and the currency guard caught `Exception` only — a `SystemExit` escaped it |
| **H6 the MAME Lua layer + real drivers** | I1 (`rpl_parse.lua` + `rpl.py`), I3-I9, `profiles/cps2.lua`, `bbh-inp-corpus` | `test_rpl` (lint; `rpl_parse.lua` == `rpl.py` when a standalone `lua` is present, else SKIP), `test_driver_contract`; MAME parity ONLY via F8 | **LANDED 14z-138**, harness commit `512747b`: `lua/mame/profile.lua` (the loader — `BBH_PROFILE`, a REQUIRED key refused by name, the guards' `crash.*` keys), `rpl_parse.lua` (ONE strict grammar module for every script; the lineage's five lenient tap copies dropped unknown tokens silently), `profiles/cps2.lua` (every board literal the three lineage scripts carried), **`profiles/cps2w.lua`** (the WIDE code window — the lineage's two guards disagreed on it), `TEMPLATE.lua`; the seven scripts lifted with their logic intact and canonical staging; `rpl_dump.lua`; `drivers/mame.sh` / `mame_guarded.sh` / `fbneo.sh` under the contract over `lib/sh/mame_sandbox.sh` (a driver REFUSES before the emulator starts; FBNeo's overlay takes a first-wins chain); `bbh inp-play` + `bbh inp-corpus` (verdict text verbatim; a zero-frame playback stays un-terminated); `[machine]` / `[inp]`; `docs/lua.md`. Five selftests: `test_profiles` (static key census + the loader under lua), `test_rpl_lua` (SKIP without a standalone lua — this host), `test_mame_drivers` (the sh half against a STUB emulator), `test_inp_corpus` (every verdict on a stub), `test_fidelity_mame` (F8). **F8 EXACT** (§5). Pre-commit at full scope PASS 30 / SKIP 1 / FAIL 0. Two defects mine found by F8's first run (a bare profile name `dofile`'d literally; `'None'` vs `'nil'` in one error text). **H6b (`7d2456d`, the same session, at the maintainer's question): the DEFAULTS CENSUS — three more board facts into the profile (the store width, the COLLECT record layout, the printed widths), five policy constants into named env, `read_tap`'s lineage-replay-length default aligned, and `[machine].profile` WITHOUT a default (a board is never implied); `docs/lua.md` §5 is the register |
| **H7 fields + dumps** | C6, C7 (predicate + bases into config; the fields TSV may carry `# base p1=…` headers) | `test_compare_fields_selfcheck.sh` on fake dumps, new `test_check_dumps` | **LANDED 14z-137**, harness commit `8867dbb`: `compare_fields.py` / `bbh compare-fields` — every printed line the lineage's; `[fields]` carries the anchor CLAUSES (`[address, width, value]`, all true), the `bases` inline table (a TSV's own `# base p1=…` headers override it), `stable` (the debounce), `settle`, `anchor_hint`, `dump_regex`; the base vocabulary in the error text is `abs|` + the configured names, so the lineage's `abs|p1|p2` renders unchanged. `check_dumps.py` / `bbh check-dumps` — verbatim; `dump_regex` and `integrity_hint` from config. `test_compare_fields` on the FAKE machine: the positive control with a 7-FRAME SKEW between the sides' anchors (401 vs 408 — the fake's mode byte is written before its transition, so the first frame that reads `match` is 401), the negative control (exit 3, the MISMATCH line to the character), the §4 shape (the hooked build agrees at anchors and differs `--exact` on its phase field), settled fields at `--settle`, the debounce NOTE and WARNING on fabricated dumps, a missing follow frame, the bases must-fire, the error texts; `test_check_dumps`: every verdict on fabricated directories, the driver-prefixed name, a custom regex and hint. The example gains `tests/fields.tsv` (with `# base` headers) and `tests/g_fields.sh` (a `fake`-lane sweep row, `%BUILD_A%`). **F10 EXACT**: both comparators over synthetic lineage-shaped dumps in every mode (10 invocations) and both dump checkers for every verdict (11), stdout + stderr + exit. Pre-commit at full scope PASS 26 / SKIP 0 / FAIL 0 (fidelity 761 s) |
| **H8** | OUT (§2.7) | — | decided out |
| **H9 the fidelity gate here + then the skill** | `tests/test_bbh_fidelity.sh` in THIS tree — `ci_static`, never `ci_portable` (CI fails on SKIP and a clean checkout has no harness); locates the harness by `$BBH_HOME` (default `../blackbox-harness`) and SKIPs when absent | §5 | **LANDED 14z-138** (the gate half; the skill is NEXT): `tests/test_bbh_fidelity.sh`, `ci_static`, family `runner`, the index regenerated; asserts the consumer config resolves to THIS tree; runs the harness's ROM-free fidelity (F1, F3-F7, F9, F10) and, with `BBH_MAME_FIDELITY=1`, F8. **The first full fidelity run here: PASS** (`build/bbh_fidelity_first_14z138.log`). MEASURED at that run: the default `../blackbox-harness` was one level short — the ruled location is beside this tree's PARENT (`../../blackbox-harness`); the gate searches both levels (§7.3) |

Order: H1 → H2 → H3 strictly (the suite needs the comparators and the
classifier); H4, H5, H7 depend only on H1; H6 on H3; H9 after H4. Then the
skill. Then the living-documentation slices (`living_docs_scope.md`). Then
the lined-up open items.

## 5. Fidelity — how the extraction is PROVED

The principle: run the generic tool and the project tool over the SAME input
and diff the verdict TEXT. Expected values are never re-derived by hand.
The emulator superset invariant's shape (the patched binary on the pristine
set reproduces the frozen expectations bit-for-bit) applied to the harness:
the generic harness on this tree reproduces its verdicts.

| check | input | project side | generic side | needs |
|---|---|---|---|---|
| F1 classifier | a synthetic fake repo of ~25 stub gates: every case of both runner tests, exit 124/137, exit 0 + `x.sh: line 3: FOO: parameter null`, MAME's benign `line N:  1234 Segmentation fault` | `tests/run_all_static.sh --tier portable` in the fake repo | `bbh-run-static` with the example config | nothing |
| F2 static tier, live | this tree's `ci_portable.txt` then `ci_static.txt` | `tests/run_all_static.sh` | `bbh-run-static --config consumers/bbh.vampire.toml` — diff the verdict column per gate, the tally, the anti-orphan output, the exit status (durations stripped) | nothing / `ROMDIR` |
| F3 tier classifier | `tests/*.sh` (304) | registry membership + the printed unregistered list | `python3 -m bbh.tier --list`: the instrument set == the sweep registry's rows exactly, the rest == portable ∪ static, both unregistered lists empty | nothing |
| F4 sweep registry | `tests/ci_emulator.tsv` | `run_all_emulator.sh --list --scope all --lane all`, then `--dry-run` | `bbh-run-sweep` same flags — diff (placeholders expanded; the precondition hook is skipped by `--dry-run` on both sides) | nothing |
| F5 comparators, corpus-wide | every `.masked` spec (1,891) paired with a DIFFERENT set's frozen log of the same stem (39 `logs/` dirs) as the candidate; plus ~200 generated pairs from the comparator tests' synthetic generators | `masked_check` from `tests/lib/masked_compare.sh` | the harness's — diff verdict strings byte for byte (mostly FAIL lines, which is the point: the text and the class arithmetic match) | nothing |
| F6 fingerprint | `$ROMDIR` and every present `build/*/rompath`; the synthetic zips of `test_suite_dispatch.sh` §1b | `build_fingerprint.py --sha-only / --set-key / --full` + the registry lookup's stderr NOTE | `python3 -m bbh.fingerprint` same flags | `ROMDIR` (nothing for the synthetic twin) |
| F7 suite dispatch | `tests/expected/<set>/` trees | `run_suite.sh` never booting MAME: a shadow root whose `tools/run_replay_mame.sh` stub copies a sibling set's log | `bbh-run-suite --driver fake` — diff per-replay verdict lines (`SKIP (…)`, `PENDING`, `NO-EXPECTATION`, `PASS masked-…`, `FAIL expected … got …`) | nothing |
| F8 the replay engine | one masked replay | `tools/run_replay_mame.sh vsavj <rpl> a.log` | `drivers/mame.sh` with `BBH_PROFILE=cps2.lua` — `cmp` the logs; then `VIDEO_OUT`, `DUMPS`, `POKES`, `SNAP_FRAMES` parity; the guard's CRASH lines on `test_crash_guard`'s positive control | `ROMDIR` + the pinned MAME |
| **F8, MEASURED 14z-138: EXACT** (`selftest/test_fidelity_mame.sh`, opt-in `BBH_MAME_FIDELITY=1`, ~60 s; `BBH_FIDELITY_F8=all` every recording, 188 s) | as above, plus `INPUT_OUT`, `INPUT_INJECT_TEST`, the cheap guard, the grammar under MAME's Lua, every tracked recording, FBNeo | `107_four_directions` unmasked and masked: `cmp` identical; the extras: every artifact byte-identical (the PNGs too); the injection: the same INPUT-VIOLATION line, both exit 1; the cheap guard on `02_demitri_vs_cpu`: identical AND equal to the FROZEN `vsavj` `.sha1`; the authoritative guard on the planted ILLEGAL: CRASH/REGS/STACK/END-CRASH identical, the whole `-debug` log too; `rpl_dump.lua` == `bbh rpl dump` over all 181 replays; `inp_guard.log` identical on every recording and the corpus verdicts identical; FBNeo log + dump + video identical | `ROMDIR` + the pinned MAME (both sides run the SAME binary, so the comparison measures the drivers and the Lua, never the instrument) |
| F9 hygiene tools | this tree | provenance, header defaults, ref rot, demand-after-trap, `gen_gate_index --check` | the generic equivalents with the consumer config — diff full stdout + exit status | nothing |
| F10 fields + dumps (added 14z-137) | SYNTHETIC dump directories shaped like this tree's (its addresses, `tests/fields_m2a.tsv`, a driver-prefixed copy, a hole, a window that starts true, a transient edge) | `compare_fields.py` in every mode, `check_wram_dumps.py` for every verdict | the generic equivalents with the consumer config — diff stdout + stderr + exit status | nothing |

`tests/test_bbh_fidelity.sh` runs F1-F5, F7, F9 and F10 (ROM-free), and F6/F8
when `ROMDIR` and `BBH_MAME_FIDELITY=1` are set. It writes only into a
temporary directory; `--freeze` NEVER runs inside fidelity.

Three rules that follow from the contract:
1. **No verdict-string edit in H1-H4.** `masked_compare.sh` reproduces
   `run_suite.sh`'s output character for character on purpose; a "tidied"
   message breaks F5/F7. Cosmetic changes wait until H9 is green and are
   then an explicit re-baseline of the fidelity gate.
2. **The generic classifier is the STRONGER copy** (the sweep runner's: it
   has the TIMEOUT and the exit-0-after-shell-error branches; the static
   runner today lacks both). A static-tier delta on a gate that exits 0
   after a shell error is a FINDING about this tree, recorded, never a
   fidelity failure — and never fixed by weakening the generic classifier.
3. **Comparison is of TEXT, not of a re-implementation's opinion.** Where
   the project tool prints a number, the generic tool prints the same
   number in the same place, or the diff is not empty.

## 6. Where the boundaries are NOT clean — named now so the lifting does not paper over them

1. **The header contract vs consumer freedom.** E2, E3, E5, E6 all parse
   line 2 `# <name>.sh — <claim>` through the first blank `#`; a consumer
   with another comment style gets nothing from them. The line: H1 does not
   require the contract (the runner reads names); H5 is OPT-IN and
   `docs/gate_contract.md` says exactly what it buys.
2. **The duplicated classifier differs.** Static has no TIMEOUT and no
   shell-error branch; sweep has both. Unifying on the stronger changes what
   the static tier would say about one gate class (§5 rule 2).
3. **sh vs python for the runners.** The runners are POSIX sh with python
   heredocs, and half the harness's guards exist BECAUSE of sh (the
   `${X:?}` exit-0 trap is a bash 3.2 fact). Rewriting them in python would
   lose byte-identical output and the sh trap coverage; keeping sh means the
   config is shimmed through one python start per run. The line: sh for
   runners, drivers and `masked_compare`; python for anything that parses.
4. **MAME-only vs multi-driver.** `run_suite.sh` names the MAME wrapper on
   one line; FBNeo's wrapper differs in variable names (`FBNEO_DUMPS`,
   `FBNEO_ROMPATH`, `FBNEO_HVIDEO`) and has no `MASK_RANGES`; the Verilator
   lane has its own driver with its own download offset. The line: the
   contract is the 4-arg form plus a documented environment; a driver that
   cannot honour a variable REFUSES; `fbneo.sh` maps `DUMPS` to `-hdump`
   and refuses `MASK_RANGES`; the MiSTer driver stays here.
5. **Lua is testable only under MAME.** `rpl_parse.lua` can run under a
   standalone `lua`, which is a second interpreter with its own
   differences; `rpl.py` is a second copy of the grammar — the harness's
   own rot class 5 (deleted mechanism) risk. The line: the equality selftest
   `rpl_parse.lua == rpl.py` is the guard (SKIP with reason when no `lua`),
   and MAME-side parity is F8 only.
6. **Frozen verdict strings are load-bearing** (§5 rule 1).
7. **`--freeze` writes into the consumer's expectation tree.** It is the
   freeze ritual and stays; it never runs in fidelity.
8. **Placeholder expansion order.** `%MERGED_RP%` must expand before
   `%MERGED%`; the generic expander sorts keys longest-first and F4 proves
   it.
9. **The expectation-set layout is frozen as the harness's format** —
   `<set>/<name>.{skip,pending,masked,diverge,sha1}`, `<set>/mask`,
   `<basis>/MASK`, `<basis>/logs/`, and `masked_check`'s root derivation
   from `dirname(expdir)`. A new kind is registered in
   `enumerate_expectations`.
10. **The method documents carry game numbers.** `oracle_classes.md` cites
    measured frames; `gate_scoping_method.md` cites Phobos and a program
    address. The lifted texts keep the rules and replace every number with
    a fake-machine number or drop it; no `[VSP-N]` anchor travels.
11. **`shadow_tools.sh` assumes a tool resolves its repo as
    `parent.parent` and imports siblings by path insert.** Config names the
    tools dir and the linked dirs; the assumption is documented, not hidden.
12. **The instrument banner and the ROM precondition are project facts.**
    Both become hooks (an empty string disables); the banner's
    "builds under test, fingerprinted" section is generic (iterate the
    placeholders, run the fingerprint).

## 7. Decisions — taken under stated assumptions, open to veto

1. **RULED (maintainer, 2026-09-06): a SEPARATE repository,
   `~/Developer/blackbox-harness`.** Git-initialised locally 14z-135; PUSHED
   14z-135b to https://github.com/DefinitelyFrenchName/blackbox-harness (public, `main`) at
   the maintainer's word — *"push it to its own repo on my github … you
   clone/fork it when you need it"* — so pushing the harness is standing-
   authorised from then on.
2. **RULED (maintainer, 2026-09-06): the name is `blackbox-harness`**, CLI
   prefix `bbh`.
3. **The fidelity gate finds the harness by `$BBH_HOME` (default
   `../blackbox-harness`) and SKIPs when it is absent; no submodule.**
   (MEASURED 14z-138: the ruled location `~/Developer/blackbox-harness` is
   beside this tree's PARENT — `../../blackbox-harness` from here — so the
   gate looks at both levels and names the one it found.) A
   submodule pointing at a repository with no remote breaks every fresh
   clone's `git submodule update`. Veto → vendor by `git subtree` once a
   remote exists.
4. **License GPL-3.0**, this repository's. Veto → MIT for wider reuse.
5. **Lifted comments keep their `14z-N` and issue citations as history
   lines** — they are the incident record that makes a guard legible — but
   no `[VSP-N]` / `[MFI-N]` anchor travels (those are this project's skill
   lock, `tools/checkskills.py`). Veto → strip the citations.
6. **Drivers in the harness: MAME, guarded MAME, FBNeo, fake. The
   MiSTer/Verilator driver stays here.** Veto → a fourth driver in a later
   slice.
7. **The eight doc tools are OUT of the harness** (§2.7). Veto → an H8
   sibling package `bbh-docs`.
8. **This project never consumes the harness** (the maintainer: it "stays
   as it is"). Its consumer config `bbh.vampire.toml` therefore lives in
   the harness under `example/consumers/`, and the only file this tree
   gains is `tests/test_bbh_fidelity.sh` with its `ci_static` line and its
   gate-index row. Veto → the config moves here.
9. **The generic classifier is the stronger copy** (§5 rule 2). Veto →
   per-tier `shell_error_regex` so F2 is byte-identical.
10. **No verdict-string change before H9 is green** (§5 rule 1).

## 8. Cost

H1, H2, H3: one session each (each lifts ~500-1,000 lines and brings its
ground truth; H3 also writes the fake machine). H4 + H5 + H7: one session
together. H6: one session (2,100 lines lifted, a profile, F8 measured on
the pinned MAME). H9: half a session (the gate plus the first full fidelity
run on this tree). The skill: one session, after H9. Total: six to seven
sessions before the living-documentation slices begin. Each slice ends with
`selftest/run.sh` green in the harness and the static tier green here; no
slice touches this tree's `tests/` before H9.
