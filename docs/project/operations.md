# OPERATIONS — the tool catalogue and the working methods (moved out of HANDOFF.md, #282 item B, 14z-201)

The reference HANDOFF.md used to carry in full: what each tool and instrument is, the native-leg recipe, the
census and method sections, and the measured runs of the tiers. HANDOFF.md keeps the routing table, how to build,
test and run, and the current freeze, and points here. Every block below was moved VERBATIM from HANDOFF.md on
2026-10-14 (#282 item B, maintainer: "yes this looks right"); its anchors moved with it.

## From HANDOFF.md: «What exists» — the tool catalogue

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*


| Piece | Where | Status |
|---|---|---|
| Reference sets | `$ROMDIR` (../ROMS, outside repo) | audited clean; all 6 zips present (vsav, vsavj, vsav2, vhunt2, vhunt2r1, qsound_hle) |
| Frozen checksum manifest | `docs/checksums.txt` | 76 members, per-file SHA-1 |
| ROM audit tool | `tools/audit_roms.py <romdir>` | verify vs manifest; `--freeze` to re-freeze |
| CPS-2 decrypt/encrypt | `tools/cps2_decrypt.py` | bit-identical to MAME oracle (both directions self-checked) |
| Null-patch builder | `tools/build_rom.py <romdir> <out.zip>` | deterministic, bit-identical vsavj |
| Build manifest | `build/manifest/vsavj.toml` | null patch; schema carries provenance |
| MAME headless runner | `tools/run_mame.sh <set> [args]` | MAME 0.288; `MAME_BIN` unset runs the PINNED build for the set (`vsavjw` the WIDE build, stock sets the reference build, both from `tools/setup_mame.sh`; a missing one is refused — #196, 14z-189, `tests/test_mame_default_bin.sh`); fresh sandbox per run |
| Attract determinism | `tests/test_attract_determinism.sh` | PASS 3600 frames |
| Decrypt oracle test | `tests/test_decrypt_oracle.sh` | PASS (python == MAME opcode space) |
**[CPE-32]** **[MFI-32]** | FBNeo | `emu/fbneo` submodule + `tools/setup_fbneo.sh` | built (SDL2); THREE patches, only TWO of which are ever in a DEVELOPMENT binary: `0001` harness (frontend-only: `-hinput/-hout/-hframes/-hdump`, plus `FBNEO_HVIDEO` framebuffer checksums, `FBNEO_HGFX` gfx-buffer dumps, and the B5b set — `FBNEO_HTAP` write tap with PC attribution, `FBNEO_HPOKE` frame-scheduled pokes, address-resolved dumps reaching OBJ/palette RAM) and `0002` the CPS-2 WIDE profile (driver descriptor + TWO gated blocks in `Cps2ObjDraw` — the promote and the canary control; "one gated core line" until 14z-114, corrected per 14z-90). **AND `0003` drop-sdl2-image, RELEASE-ONLY (ratified by the maintainer 2026-09-21):** `tools/build_release_emulators.sh` applies it and `setup_fbneo.sh` does NOT, so the dev binary you measure with still links SDL2_image. It stops FBNeo linking that library — whose only use is an optional per-game preview PNG in FBNeo's own game-browser menu, a path that already did nothing here — which removes 21 transitive image codecs: a shipped macOS bundle is **4 files instead of 24**, and the System Settings route should then cost 4 Gatekeeper approvals instead of 24 — INFERRED from MAME's measured 2-file/2-approval case, exercised at neither count (#144). Proven inert: 12,120 frames of `05_timeout_idle` with and without it are BIT-IDENTICAL in work RAM AND framebuffer. **CRC WARNING:** FBNeo matches zip members by CRC — a mismatched gfx/QSound member is silently replaced by 0xFF fill while still logging `(OK)` (docs/GOTCHAS.md) |
| **THE GENERIC HARNESS — `~/Developer/blackbox-harness` (`bbh`), a SEPARATE repository (14z-135, maintainer-ruled 2026-09-06)** | **Since 14z-196/14z-197 bbh is its OWN PROJECT: this tree neither changes nor runs it, `test_bbh_fidelity` is deleted, and nothing here depends on it (`DECISIONS_HISTORY.md` "Ruled 2026-10-10 (14z-197) — bbh's remaining links").** The record of the extraction: the test harness extracted from this project by the question *would this still be true if the thing under test were not this ROM, not CPS-2, not even a game?* — scope `docs/project/harness_scope.md` (four bins, slices H1-H9, the fidelity contract); H1 landed (the ONE verdict classifier, `bbh run-static`, the transitive tier classifier, the demand-after-trap lint, the TOML-subset config reader, an example consumer, `selftest/run.sh`); H2 the comparison classes and the masked vocabulary; H3 the fingerprint (both keys, the dual lookup), `bbh run-suite` (the dispatch loop, verdict text frozen to this tree's), THE DRIVER CONTRACT (`drivers/README.md`) and the FAKE MACHINE (`drivers/fake.sh` + `example/fakesys/fakesys.py` — every expectation class has a ROM-free producer); H4 `bbh run-sweep` (this tree's `run_all_emulator.sh` with every project noun in `[sweep]` config); H5 the hygiene bin — `bbh provenance` / `header-defaults` / `ref-rot` / `gate-index` under ONE header parser, `shadow_tools.sh`, `accounting.sh` (the verdict from the one classifier); H7 `bbh compare-fields` / `check-dumps` with the anchor predicate, the bases and the debounce as `[fields]` config; **H6 the MAME Lua layer under a MACHINE PROFILE** (`lua/mame/profile.lua` + `profiles/{cps2,cps2w,TEMPLATE}.lua` — every board literal the three lineage scripts carried; `rpl_parse.lua` the grammar as ONE strict module; the seven scripts lifted with their logic intact), the real drivers `drivers/{mame,mame_guarded,fbneo}.sh` under the contract, `bbh inp-play` / `bbh inp-corpus` (the recording corpus, verdict text verbatim), its `lua.md` page in the harness's own docs. **EVERY SLICE IS LANDED (14z-138).** **This tree never consumes it** — it stays as it is and gained exactly ONE file at H9: `tests/test_bbh_fidelity.sh` (`ci_static`, static cadence `ondemand` since 14z-196 — bbh is its own project, a Vampire Saved session changes nothing there, and who does what is to be settled: DECISIONS_HISTORY.md 'Ruled 2026-10-09 (14z-196) — bbh is its own project: …'; run it with `--cadence ondemand` or directly; `$BBH_HOME`, else beside this tree or its PARENT — the harness lives at `~/Developer/blackbox-harness`, i.e. `../../blackbox-harness` from here; SKIP when absent; `BBH_MAME_FIDELITY=1` adds F8, never beside another gate run here); its consumer config lives in the harness at `example/consumers/bbh.vampire.toml`; the eight doc tools are OUT of it by decision. Fidelity: F1 identical, F3 exact, F4 exact (the sweep's `--list` and `--dry-run` over the whole registry), F5 exact over all 1,891 masked specs, F6 exact (the fingerprint over `$ROMDIR` and every `build/*/rompath`), F7 exact (both suite runners over every expectation set here, stub driver, no MAME), **F8 exact** (the Lua layer, the drivers and the recording tools on the REAL emulators: logs `cmp`-identical unmasked and masked, every artifact incl. PNGs, the injection, the cheap guard equal to a FROZEN expectation of this tree, the authoritative guard's CRASH lines on the positive control, the grammar under MAME's Lua over all 181 replays, every recording, FBNeo), F9 exact (the five hygiene tools over this tree, the gate index byte-identical), F10 exact (the field comparator and the dump checker over synthetic dumps, every mode) — `selftest/test_fidelity_vampire.sh` and `test_fidelity_mame.sh` there; the slice pre-commit is `BBH_MAME_FIDELITY=1 BBH_FIDELITY_F8=all BBH_FIDELITY_F5=1 BBH_FIDELITY_F6=all BBH_FIDELITY_F7=all bbh selftest` (30/1/0 on this host — the SKIP is the Lua-equality test, which needs a standalone `lua`). PUBLIC at https://github.com/DefinitelyFrenchName/BBH-frame-based (renamed 2026-09-10 from `blackbox-harness`; the old URL redirects) since 14z-135b (pushing it is standing-authorised). **H10 AND THE SKILL LANDED 14z-139:** `bbh check-skills` / `bbh skill-guide` (the lineage's `tools/checkskills.py` + `gen_skill_guide.py` lifted config-driven, F11 EXACT over this tree's eight skills and two guides), and the skill `blackbox-harness` (`[BBH-1..91]`, `skill/blackbox-harness/`, its lock `skill/skills.toml`, the guide generated) installed as the symlink `~/.claude/skills/blackbox-harness`; the eight defaults ruled and registered (its `conventions.md` page), re-baselines LOUD (its `rebaselines.md` page, the newest line printed by every fidelity run), docs lean + `_history.md` twins. **THE MUST-FIRE CONTRACT'S READER LIFTED 14z-148** as a copy (`lib/sh/controls.sh`, the classifier's 4th argument, `run-static --exec-controls`, `run-sweep --controls`, `classify --gate`/`--control`, the example's `g_control.sh`, [BBH-88..91]); F1 extended over nine declaring stubs and F2 re-measured EXACT at 70 rows; the readout header `== must-fire controls ==` and the `(controls RED: …)` FAIL row are the same text on both sides by construction | H1 `803f372`, H2 `ef7e899`, H3 `c26ba45`, H4 `81ad426`, H5 `b533715`, H7 `8867dbb`, H6 `512747b`, H6b `7d2456d`, the pass `e5bc3a5`, H10 `185158e`, the skill `e643219` |
| **THE RENDERED DOCUMENTATION SITE (14z-140, living-docs L4)** | `tools/mk_docs_site.py` — the whole corpus as a navigable local site: every `doc_shape.tsv` document plus the two skill GUIDEs (80 pages, 6.6 MB), the landing page being `docs/README.md` with its routing table; an ADDRESS INDEX built from `gen_annotations.collect()` rather than from the rendered `annotations.md` (2,958 rows, EVERY carrier where the page shows six, and a section that resolves to no heading FAILS the generator); a client-side search over 1,639 headings, titles and rule IDs; the theme shared with the drawn MiSTer page via `tools/_pagestyle.py`. Its markdown parser is `tools/md_subset.py`, a SUBSET measured as a census rather than guessed. **Generated into `docs/site/`, gitignored, NEVER committed — the markdown is the source and the site is a projection**; `--verify DIR` says whether a directory is what a fresh render produces. Gates: `tests/test_docs_site.sh` and `tests/test_md_subset.sh` (both ci_portable) | live |
| **THE RULE-5 CENSUS (14z-141, living-docs L2)** | `tools/audit_rule5.py` — every behavioural value in the canonical manifests and the generators classified IN-TABLE / BAKED / DERIVED in three columns (`gameplay` = rule 5's obligation, `fact`, `code`). Measured at the close: gameplay **15 IN-TABLE / 202 BAKED of 217**, fact 511 derived / 7,827 baked of 8,338, code 30 baked, UNCLASSIFIED **0**. IN-TABLE is POINTER-DRIVEN (`# in-table:` in TOML, `_in_table` in JSON) because a value-matching pass returned 19 gameplay rows IN-TABLE and all nineteen were false positives. The GAMEPLAY and CODE inventory is frozen at `tests/expected/rule5_baked.tsv` (232 rows) and can only SHRINK; `fact` is a NOTE-class number instead, because port work adds addresses every session and a signal that fires on every commit is not a signal. MIGRATION IS OPTION B (maintainer-ruled 2026-09-07): the manifest KEEPS the value and gains a table row with provenance plus a pointer, checked so the two cannot drift — a documentation edit can never move a shipped ROM byte. Gate: `tests/test_rule5_census.sh` (ci_portable, ~6 s, six must-fire controls). Ledger: `docs/project/tables/rule5_ledger.md` | live |
| **THE ATLAS ROM RE-DERIVATION (14z-142, living-docs L3)** | `tools/checkdocs_rom.py` — the atlas's ROM-shaped claims re-derived from the three decrypted views. Every check QUOTES its claim from the document (`says()`, whitespace-collapsed, so a re-wrapped line is not a false verdict) and DERIVES the same fact from the image: a reworded document is a STALE verdict, never a silent pass. **All three sets are read** (maintainer-ruled 2026-09-07) because the atlas's spine is a three-set comparison — 41 sibling addresses and 50 rows carrying two or more. **Opcode WORDS are the evidence**; capstone is `--disasm`, diagnostic only. **`PARAPHRASE` is a declared, printed class**: `character_tables.md` renders the palette blitter as `or.l #$F000F000` where the image holds `or.l d0,(a1)+` with the constant loaded two instructions earlier — correct documentation a word compare would call stale, so such claims are checked against the literal fact they summarise. Coverage is a NOTE-class number against a denominator of **394** since 14z-189 (379 from 14z-161) (the atlas addresses minus those carried only by `ram.md`, whose claims are dataflow and belong to the suite; **370** at 14z-160, **364** at 14z-157, **346** at the 2026-09-07 ruling, 473 minus 127 — the definition is ruled, the count follows the atlas). At 14z-142: **15 checks, 12 table controls, 30/346**, with the covered set frozen at `tests/expected/checkdocs_rom_covered.tsv` (31 rows, compared as a MULTISET so a hand-added duplicate fails) and five must-fire controls. **The VIEW is a property of the ACCESS MODE**: inside the crypt range a PC-relative read sees the OPCODE image and an `(An,Dn)` read the DATA image, and the wrong one yields plausible garbage rather than an error — each check declares its view. THE CHECKS ARE HAND-WRITTEN AND MUST BE — of 36 instruction spans in the atlas ROM tier, ONE sits in a paragraph naming exactly one address and 27 name none, so no census can seed them. Gate: `tests/test_checkdocs_rom.sh` (ci_static, four must-fire controls) | live |
| The two scope documents (14z-135) | `docs/project/harness_scope.md` and `docs/project/living_docs_scope.md` — the plan before the work for the two backlog directions the maintainer ordered first (harness, then living documentation — all three forms ruled: a rendered site, markdown routing enforcement, fact tables with provenance — then the open items) | live |
| **THE GATE-QUALIFICATION INSTRUMENTS (14z-180, GitHub #171)** | `tools/audit_module_refs.py` — every cross-module Python name the tools and gates reference, resolved by AST at the target module's top level (never by importing; scope-aware, so a function's own `pp` is not the module alias); `--plant` parses the HISTORICAL caller (`git show e01ae8de^:tools/vanilla_join_rig.py`, `name_moves.PROLOGUE` at its line 110) through the same extractor and must report it unresolved — a first form appended the tuple after parsing and proved only the resolve step (rule-checker run `2026-09-24-141` Q4); `--plant-empty` runs the census over no files and must fail the floor; `--floor N`. Gate `tests/test_module_refs.sh` (ci_portable, ~1 s, two controls), floor frozen in `tests/expected/module_refs_floor.txt` (rises only). Slice Q1 of the seven the maintainer ruled 2026-09-24: the scope is `docs/project/gate_qualification_scope.md` — the four failure shapes of the M19 release tier measured against the tree, and Q0 (a WHAT/HOW/EXPECTS description in every gate's header — `docs/project/gate_header_contract.md`, read by `tools/gate_descriptions.py`, frozen by `tests/test_gate_descriptions.sh`, rendered per family into the GENERATED `docs/project/gate_coverage.md` by `tools/gen_gate_coverage.py` — its own page because bbh's F9 renders `gate_index.md` byte-identically) first **Slices Q3-Q5 (same sitting):** `# FOLLOWS:` on all 199 emulator-tier gates, read by `tools/gate_follows.py` (the reader also extracts what a script's text and its run-time harness reference; `--refs`, `--reconcile`, `--subjects LANE`); `tests/test_gate_follows.sh` freezes the census (`tests/expected/gate_follows.tsv`) and holds every declaration no narrower than its text; `tools/audit_lane_carry.py` now DERIVES a lane's subjects from the declarations (an undeclared gate = MUST RE-RUN; ground truth `tests/test_lane_carry.sh`); `tests/run_all_emulator.sh` writes `commit.txt` per run and takes `--stale`; `tools/audit_emulator_staleness.py` + `tests/test_emulator_staleness.sh` name the passed gates whose declared paths moved since that commit — the registry `tests/ci_emulator.tsv` per ROW since 14z-195 (#237: a gate is stale on it only when its own row changed) — (NOTE at session, FAIL at freeze/release via `VS_CADENCE`) and fail any results row at or above half its cap. **Slice Q2 (same sitting):** `# MEASURES: <name> — <floor>` in a gate's header and `MEASURED: <name> = <n>` at run time; `tests/lib/measures.sh` is the reader, read inside `tests/lib/classify.sh` after the controls read (a missing, below-floor or undeclared measurement is plain FAIL); ground truth `tests/test_measures_contract.sh`; five hashed-table gates declare six measurements (charmap anim rows, meter rows, slot-map and hit-damage rows, BINARY.txt rows, zip members). **Slice Q6 (same sitting, the census):** `tools/audit_poke_readback.py` — every gate that SAMPLES an address its own rig POKES (literal pokes and the generated rigs' schedules against FIELDS/DUMPS/taps): 74 findings over 31 gates, one row each in `tests/expected/poke_readback.tsv`, classed by the MAINTAINER (READS-BACK 1, the killshread `stock` column; UNCLASSIFIED 73); `tests/test_poke_readback.sh` keeps the table joined to the census. | live |
| **THE NAMING-RIG PROBES (14z-172, GitHub #168)** | `tools/naming_event_stock.sh <tenant> <part> <out>` — the stock each event of a naming part HAD and SPENT on native vsav2, which is the only discriminator when an ES move and its normal twin enter the SAME chain ([VSP-170]); it is what identified `pyron_5` event 0 as the normal Planet Burning (0 spent, against 1 for all five of the part's ES events). `tools/naming_shift_sheet.sh <out>` — one naming event BEFORE and AFTER a schedule shift, as pictures: the BEFORE leg regenerates the rig from a copy of `name_moves.py` with its round-start floor removed, both legs are native vsav2 and both are sampled at the same offsets from their own event frame. Both are PROBES, not gates — the corpus-wide stock assertion is `audit_move_parity` section 2b and the cadence constants are `audit_tick_phase` |
| **THE AIR-THROW RIG SWEEPS (14z-181, GitHub #169)** | `[LEAD=n] tools/air_throw_sweep.sh walk\|lead\|phase\|press\|xpin [out_dir]` — which chain each of pyron_3's two Galactic Throw events enters on native vs2 while ONE rig variable is swept (the walk-in length, P2's jump lead, the schedule shift, P1's press offset, the pair's pinned x), the pair pinned still where the walk is not the variable; `LEAD` sets P2's jump offset for the other modes (the 14z-181 walk / x / press sweeps ran at 0). An instrument, not a gate; the frozen truth is `tests/expected/move_naming_pyron.txt`, the 14z-181 results `build/agent181/air_throw_sweeps_14z181.txt`. Native only, one leg per value in parallel. |
| **THE PLASMA TRAP AIR-HIT INSTRUMENTS (14z-182, GitHub #175)** | `[LEG=native|merged] [PICK=forced|real] [P2CELL=07] [XPIN=x@a-b] [P1XPIN=x@a-b] [JUMP=f] [DIR=U|UL|UR] [ATK='a-b p2=N'] [ORDER=1] [SNAP=f,..] tools/trap_air_probe.sh [out]` — the trap rig (replay 92) with a victim who jumps, traced every frame and resolved by `tools/trap_air_boxes.py` into world-space boxes: the dome's attack box against each TESTED vuln box (a zero id is no box), the fighters named by hitbox base, the victim's node; `ORDER=1` is a `-debug` write/read tap in execution order, `SNAP` photographs frames. `tools/trap_air_sheet.sh` renders native beside ours for the Felicia rig (the capture the maintainer read, 2026-09-25). `tools/air_hurtbox_census.py <data image> [--layout]` lists every node of every character whose tested hurtbox reaches within `--limit` px of the feet (static; which nodes are AIRBORNE is not in the data). `tools/trap_air_static.py dome|victor|felicia <data image> <layout>` (14z-183) re-derives the static figures the documents quote (the dome's records 5/6, Victor's vuln0-only families, Felicia's `b:0x0f` and `a2:0x14#4` boxes) from any data view. The verdict is the gate `tests/audit_trap_air_hit.sh`. |
| **THE FREEZE'S READ-BACK INSTRUMENTS (14z-185, the M21 freeze; promoted at its close)** | `tools/battery_reach.py --results <results.tsv>... --dirty <name>... [--extra-root <dir>]` — does anything an emulator battery RAN read a file dirtied during the run: the reach through paths AND imports (relative, `-c`, `-m`, heredoc), extra roots, a comment-free STRICT set, the chain to every reader, every unresolved import listed; a planted-reader control first (`docs/project/gotchas.md` "IS A REACH QUESTION"). `tools/attr_placement_moves.py --old <build> --new <build> --log <gate log>...` — every address a freeze moved in a static pin, attributed to a placed region, a MOVED op, or (weaker, labelled) an offset-preserved hole; a `--plant` control. `ROMDIR=... tools/patch_site_read.py --build <dir>... --site ADDR:LABEL...` — which fix each build carries, read from its own decrypted opcode view against pristine (no ROM byte printed) | live `tools/program_bytediff.py <OLD build> <NEW build> [...]` (14z-192, #231) — a freeze's WHOLE program change per track, byte by byte from each build's own decrypted romset (opcode and data views), no op list read: it sees a byte changed inside a placed data file, which an op-set delta cannot; its control is M21 -> M22 (`pyron44 -> pyron45` shows #194's byte at `0x0FDF69`) (`docs/project/gotchas.md` "AN OP-SET DELTA CANNOT SEE A BYTE INSIDE A PLACED FILE"). |
| **THE CLOSE'S FILE-LEVEL CHECKS (14z-181)** | `python3 tools/findings_anchors.py check|plant TITLE STATE.md [OUT]` (14z-189) — every finding's home ANCHOR TEXT is in its home file (homes_tracked checks only that the file is tracked); in the standing close set with its generated plant and `--selftest`; `python3 tools/none_reasons.py [--row TITLE] [STATE.md]` (14z-188) — every finding whose test is `none` says why in parentheses, read live from STATE.md; gated by `tests/test_close_tools.sh` section 2c. `python3 tools/homes_tracked.py "(N) THE FINDINGS TABLE" [out]` — every file the sitting's findings table names as a home or a test is a TRACKED file (three reads: backticked tokens against `git ls-files`, `build/` paths in prose, test clauses that cite an artifact with no script); `python3 tools/retraction_grep.py tests/rulecheck/retractions/<key>.tsv [out]` — the sitting's retracted wordings searched by SHAPE (whole file, whitespace / backticks / `#` prefixes collapsed) over EVERY TRACKED FILE plus the untracked generated pages, with reach controls that must be found (one in a root document, README.md); both exit 1 on a red and are locked by `tests/test_close_tools.sh` (since #268, 14z-199: there the retraction grep judges every sitting's GONE wordings on the files the sitting touched, `--touched LIST --each`; every sitting's file on ONE whole-tree scan, `--each`, is `tests/test_retraction_reach.sh`, freeze cadence). Run BEFORE the documentation packet; the hits' classing is written by hand under the grep's output. |
| **THE CAPTURE-GEOMETRY SHEET (14z-143)** | `tools/capture_sheet.sh <attacker_hex> <victim_hex> [out.png]` — ours vs native `vsav2` as NUMBERS and as a PICTURE, for any (attacker, victim) pair. It dumps both legs, reads the per-frame victim offset, and photographs each leg on the frame it shows the SAME KEYFRAME: the two legs do not run the same video frames per engine tick — native vsav2 at its default TURBO play mode, ours at NORMAL (#135) — so same-frame snapshots compare different keyframes and invent a difference ([VSP-136], [VSE-84]). `BEFORE=<build>` adds a third column for a pre-fix build, drawn at ours' frame numbers because a differing geometry has no matching keyframe by definition. A leg that never made the hold is VOID and refused, not drawn ([VSP-170]). It is an INSTRUMENT, not a gate — the verdicts are `audit_capture_matrix` (all 640 cells, static) and `audit_pyron_capture_block` / `audit_don_grab_pose` / `test_hui_grab_victim` (behavioural). Built because the maintainer twice required captures before accepting a capture-geometry finding and the rig was twice thrown away | live |
| **THE PREBUILT EMULATOR BINARIES (14z-149; ruled 2026-09-11: recipe AND prebuilt)** | `tools/build_release_emulators.sh fbneo\|mame` — EMULATOR.md's recipe run on THIS host into the build resource `release/emulators/<platform>/<os-arch>/` + `BINARY.txt` (sha256 per file, pin, patch sha1, recipe, host, minimum OS, how to run, Gatekeeper): FBNeo from a CLEAN worktree of the pinned commit with ONLY patch 0002 (`setup_fbneo.sh` always applies the harness patch, which never ships; the fresh-tree build takes TWO passes — [CPE-26], corrected), MAME through `setup_mame.sh` into its own mirror. Then `tools/bundle_dylibs.py` makes it SELF-CONTAINED — the recipe links Homebrew's SDL by absolute path, so every non-system library is copied flat beside the binary under `@loader_path` (the `@rpath` siblings Homebrew's own libraries name included), rpaths dropped, everything ad-hoc signed, verified on the artifact. Measured on this MacBook: fbneo 23 libraries / 58 MB, mame libSDL3 only; **the floor is macOS 26.0, arm64** — Homebrew's bottles carry it and the linker inherits it; lowering it means building SDL from source with an older target, a departure from the recipe not taken. Gate `tests/test_release_binaries.sh` (emulator tier, `mame` lane): record, self-containment, signature, profile, NO harness, and a BOOT of the merged set on each binary — FBNeo headless 20 s, MAME `-verifyroms` + `05_timeout_idle` reproducing its frozen masked expectation on the release binary. **ALL THREE OSes SINCE 14z-150** — `tools/bundle_dylibs.py` (macOS, `@loader_path` + ad-hoc signature), `tools/bundle_elf_libs.py` (Linux, `patchelf --set-rpath '$ORIGIN'`, the glibc floor measured from the artifact, the GPU/display/audio stacks left to the host) and `tools/bundle_win_dlls.py` (Windows/MSYS2, the DLLs beside the .exe, nothing to rewrite, no signature to apply); `CHECK=1 tools/build_release_emulators.sh <kind>` prints what a host resolves without building, and the maintainer's step-by-step for their own boxes is **`docs/project/WINDOWS_BUILD.md`** (both tracks on one Windows machine: MSYS2 native -> `windows-x86_64`, WSL2 -> `linux-x86_64`; `tools/preflight_release_build.sh` refuses to let a build start on a host that cannot finish it, `tools/collect_build_report.sh` packages one ROM-free file to send back), with `WSL2_SETUP.md` §10 the shorter form. **~~The Linux and Windows halves have never been RUN~~ BOTH HAVE RUN SINCE 2026-09-13 (14z-152, the maintainer's Windows box, driven over SSH): the Windows gate PASSES on MSYS2, and the `windows-x86_64` pair is PUBLISHED on `freeze/merged-m18` since 14z-153 (rebuilt with the environment capture, gated on the box, uploaded from the Mac because `gh` is absent on MSYS2); on WSL2 the Linux binaries pass every real check, and the Linux self-containment rule was REPLACED after its own control went dead — `tools/check_host_libs.py` against `tests/expected/linux_host_provided.tsv` (manylinux_2_39 plus ruled exceptions), ground truth `tests/test_host_libs.sh` — and the Linux gate then PASSED end to end at `a145562c`, both controls firing. The WSL2 Linux binaries are a PROOF run (glibc 2.43 floor), never published; their register entry was composed by the tool from a rebuild's records. SINCE 14z-191 (maintainer-ruled 2026-10-05) THE PUBLISHED LINUX ROUTE IS PILOT'S (Ubuntu 24.04, glibc 2.39, built and gated at the 14z-190 close): its records are tracked at `release/emulators/{fbneo,mame}/linux-x86_64/BINARY.txt`; the end-to-end player test is #226.** They were written on this Mac; `tests/test_bundle_parsers.sh` (ci_portable) proves their parsers, their closure walk and their refusal of an empty closure against stub tools, and the gate FAILS loudly on an OS it does not know rather than passing silently. **WHERE A BUILD IS KNOWN TO WORK (14z-152, the maintainer's "true minimum bar"): `docs/project/build_environments.md`** — one entry per host where the build AND the gate passed, composed by `tools/record_build_environment.py` from the record's `env` lines (captured at build time by `tests/lib/host_env.sh`) and the gate's PASS line, plus the conditions known to break a build; ground truth `tests/test_build_environment_entry.sh`. **Published by `tools/upload_release_assets.sh freeze/<name> [--prune] [--dry-run]`** (ruled 2026-09-11: release assets, never git content. **RE-CUT 2026-09-12 (14z-151): one asset per platform PER ROUTE, each self-sufficient** — `<name>-<platform>-<os-arch>.zip` = README + patch set + applier + the prebuilt binary and its record, NO driver patch and NO `EMULATOR.md`; `<name>-<platform>-recipe.zip` = the same plus the patch and the recipe, no binary; `<name>-mister.zip` = the whole MiSTer dir. The file list is computed ONCE per asset and drives both the zip and the verification of what GitHub serves back; an empty asset, a prebuilt with no binary and a recipe with no patch are REFUSED. Per asset: verify the records, zip, create the release on the tag if absent, upload, download back and cmp every served file against the tree's, prune every earlier freeze's zips still hosted (#221, 14z-191: freezes never released no longer stop the walk). `--dry-run` writes nothing into the tree and keeps the zips and lists under `build/scratch/release_assets/<name>/` — which is what `tests/test_release_asset_shape.sh` reads); a fresh clone holds the records only and the gates SKIP/note that | live |
| **THE BROWSER APPLIER (14z-173 A1, 14z-174 A2-A6; the maintainer's ask of 2026-09-20)** | `tools/gen_applier_page.py` + `tools/applier/` | **One self-contained HTML file per platform dir of every release**, so a player with no Python and no terminal double-clicks it, picks their dumps and gets `vsavjw.zip`. Modules: `vcdiff.mjs` (the RFC 3284 subset, a port of `apply_release.py`'s decoder), `zip.mjs` (reader for the player's dumps, writer for the romset), `applier.mjs` (the logic, step for step the Python tool's), `page_shell.html` (the UI), `apply_node.mjs` (the same modules behind the Python tool's CLI, for the gate). **It is ONE file because a `file://` page cannot read anything beside it** — `fetch`, XHR and cross-file `import` are all refused by Chrome and Firefox alike, measured 2026-09-21 (`docs/platform/gotchas.md`), so the manifest, the 20 patches (base64) and the modules are inlined, ~3.4 MB. **The page's promise is enforced by a Content-Security-Policy** — `default-src 'none'; connect-src 'none'; form-action 'none'; base-uri 'none'` — which the BROWSER applies to every network primitive, including the ones no denylist names; the generator refuses to emit a page whose policy is missing or weakened, and refuses one carrying any named primitive or any `src=`/`href=` that is not a `#fragment` as a second, independent check. It is not decorative: the browser gate's original driver lived inside the document and stopped working the moment the CSP landed, so it was rewritten to iframe the page from outside rather than dilute the policy to be testable. Gates: `tests/test_applier_page.sh` (member-for-member equality with `apply_release.py` on BOTH variants, the refusal vocabulary read out of the Python file's syntax tree, four refusals exercised, self-containment, three controls) and `tests/test_applier_page_browser.sh` (the shipped file driven from `file://` in headless Chrome through its own drop zone, radio and button). **The container bytes are deliberately NOT compared** — `CompressionStream` is not byte-comparable to `zlib.compressobj`, and Gecko differs from Blink again — while every member, the order, every zip header field and the applied-set key are | live |
| `tools/audit_mame_bin_pin.py` (14z-133) | every script under `tests/` that boots `vsavjw` through a MAME wrapper (`run_mame` / `run_replay_mame` / `run_replay_guarded`) must carry a real `MAME_BIN` pin — `run_mame.sh` falls back to Homebrew's `mame`, which does not know the set, so the leg measures nothing (three M16-sweep reds). `--selftest` is the must-fire control; gate `tests/test_mame_bin_pinned.sh` (ci_portable). A `[MAME_BIN=...]` in a Usage line is not a pin | live |
| **THE FORCED-PICK SWEEP INSTRUMENTS (14z-161, #151 step 3)** | `tools/select_paths.py` (the REAL cursor path to any select cell, either player, either wheel — P1 starts on `0x01`, P2 on `0x05`; `--rpl-prologue` emits the replay lines; `--check` re-derives the 14z-160 paths), `tools/audit_poked_legs.py` (the census of every forced-pick leg in `tests/` and `tools/`, resolved through the game's wheel and classified SAME / CROSS-INERT / CROSS-FLAVOR / PARAM; gate `tests/test_poked_legs.sh`, ci_static), `tools/audit_latch_readers.py` (every instruction touching a fighter block's confirm-latch offsets, by addressing form, positive controls on the documented sites; gate `tests/test_latch_readers.sh`, ci_static), `tools/tap_latch_reads.sh` (one leg under the non-debug read tap over both blocks' latch windows, reduced to (PC, byte, value) — the mask names the byte; gate `tests/audit_latch_reads.sh`, emulator tier) | live |
| **THE SAME-DATA P2 AUDIT (14z-164, GitHub #136 proposition 2)** | `tools/audit_same_data_p2.py <vsavj_data.bin> <vsav2_data.bin>` — for every legacy id both games carry, whether its character data is the same on vsavj and vsav2: the bank's value rows, every anim node's RESOLVED boxes and attack record (tables a/a2/b/c/proj, through `hitbox_records.py`; never the indices, which vs2 renumbered), the defense-curve row; `--layout vsavj` reads both images alike (the gate's self-compare control). MEASURED: 0 of 12; Victor's hitstun head hurtbox is retuned on vs2 (`b:0x00-0x05`), `b:0x10` gained a push box for nearly everyone; the nearest victims are Demitri (P2 path `R` on both wheels) and Bishamon. Gate `tests/test_same_data_p2.sh` (ci_static, two controls). Born of the census that found five of #136's 13 divergences begin in Victor's state | live |
| **THE #136 ATTRIBUTION TOOL (14z-168)** | `tools/move_parity_attribution.py run --build DIR --romdir DIR --work DIR` — every DIFF row of `tests/expected/move_parity_events.tsv` given its ROOT and a measured CLASS: step 0 re-runs the committed rigs and must reproduce the frozen table, step E moves the first event of parts whose first X pin precedes the round start to 2800 (the entrance artifact), then ITERATIVE ABLATION removes each part's first DIFF event's inputs (the rig regenerated through `tools/name_moves.gen` with that recipe emptied, checked byte-identical to the committed rig first) and records which rows vanish; each root is classed by a signature read from its own window (SLOWDOWN, METER-SWAP, DF-STOCK, TRAP-REMAP, COLUMN-SHOCK, GUARD-REENTRY, DEFENSE-ROW, P2-DISPLACEMENT, ENTRANCE; OTHER fails). ~5 min at `--jobs 6`. Gate `tests/audit_move_parity_attribution.sh` (the frozen attribution; `--no-ablate` is its must-fire control) | live |
| **THE #184 CHAIN RIGS (14z-186)** | `tools/chains184_rigs.py gen\|all` (the rigs under `tests/replays/chains184/`, built through `tools/name_moves.py`'s machinery) and its readers `entry` (a chain START read from vs2's chain-start write with a predecessor filter — landing on a start node is not entering it), `agree` (the tap run played what the trace sampled) and `outcome` (P2's HP words fall, or not, from the first target chain) — used by `tests/audit_chains184.sh`. |
| **THE PURSUIT RIGS (14z-188, GitHub #195, #200)** | `tools/pursuit_rigs.py gen\|rows\|compare\|p2rig` — the cosmo, ifrit and lsword rigs under `tests/replays/pursuit195/` (`tools/name_moves.py`'s machinery), their per-event rows (P2's `+0x117` at the press, the red/white drops, P1's states), `compare --expect same\|gap\|inert`, and `p2rig` (a naming rig with the tenant on P2, by the build's real cursor path) — used by `tests/audit_pursuit_flag.sh`. `tools/equal_attack_chains.py <vsavj_data> <vsav2_data>` — which of Demitri's chains are EQUAL on both games and carry a powered attack record (#198), with its two controls. |
| **THE AIR-DASH AND LANDING-SOUND RIGS (14z-191, GitHub #222, #223)** | `tools/air_dash_rigs.py gen\|rows\|compare` — Phobos jumps and inputs the air dash j.66 with the second R at +5..+16 on `tools/name_moves.py`'s machinery (the schedule installed at run time, outside the naming corpus); `compare --expect gap\|same` reads the height (`+0x14 − +0x3A`) and seq `0x14` per event, native vs2 against ours, with VOID checks; used by `tests/audit_air_dash_height.sh`. `tools/landing_sound_ab.py hits\|wav` — the landing-sound site's read-tap hits on both games (`tests/lua/read_tap.lua` on `+0x382`, `RPCS` the site's own read) and two one-second `-wavwrite` windows (a pre-landing control and the landing) compared by difference RMS and direction; used by `tests/audit_landing_sound.sh`. Both gates froze the gap until the ruled fixes landed; at the M23 freeze (14z-192) both turned to `same` against native vs2, each with a control that must still see the gap on the build before the fix. Also 14z-191: `tests/test_py_escapes.sh` (every tracked `.py` under tools/ and tests/ compiles with invalid-escape warnings as errors). |
| **THE FACING-HOOK SPLIT (14z-186, GitHub #186)** | `tools/facing_hook_ab.py variants <build> <out> <vsavj.zip>` builds probe variants of a merged build FROM ITS OWN `patch.json` (`logicoff`: #159's hook runs with rule 5 never taken; `unhooked`: the thunk placed, the site pristine; `ctl`: the build reproduced), each read back from its opcode view; `check` reads the legs `tests/audit_facing_hook_ab.sh` runs. The pattern for any hook: split its cycles, its logic and its placement before attributing a side move. |
| **THE RNG-FORMS COMPARER (14z-186, GitHub #183)** | `tools/rng_forms.py <work> <expected>` — the parity gates' verdicts under their own `0000` RNG pin (form A), a non-zero word every frame (B) and a seed then free (C), every B/C row against form A on the same build, form A against the frozen move_parity table; run by `tests/audit_rng_forms.sh` through the gates' `RNG_WORD`/`RNG_UNTIL` probe knob. |
| **THE DARK FORCE POWER-FIELD CENSUS (14z-168)** | `tools/audit_df_field_readers.py <verify_op.bin> <placements.json> <patch.json>` — every PLACED instruction of a build that addresses one of vs2's Dark Force POWER fields (`+0x1C3/+0x1C4/+0x1C6/+0x1C7/+0x1C8`), which our host engine's Dark Force Change never sets (44 on merged-m18; the x028122 meter-adder copy is the one measured to change play, `tests/audit_df_meter.sh`). Code regions and code ops only; `--plant-first` makes its control. Gate `tests/test_df_field_readers.sh` (ci_static) | live |
| **THE REACTION-CLASS ROUTE (14z-169)** | `tools/audit_reaction_classes.py <vsavj_op> <vsavj_data> <vsav2_op> <vsav2_data> [--ours <build verify_op.bin>]` — for the electric classes (0x06/0x07/0x08/0x38/0x39/0x48/0x4E/0x52), the route of a hit's class from the attack record (`+0x17`) through the three STAGER tables (ground / air / KO: what each handler writes into the victim's `+0x54`) to the reaction table, on pristine vsavj, vs2 and a build; the shock handler's shape on each; the legacy record census by class; every constant write to `+0x54`; every constant compare against the record's class (the GUARD chain) and against `+0x54`; the per-class tables `+0x54` indexes. `--plant` makes its two controls. Gates `tests/test_reaction_classes.sh` (ci_static) and its live half `tests/audit_reaction_class_live.sh` (every write and read of `+0x54` over the legacy suite on vsavj and the #136 parts on ours and native) | live |
| **THE RULE-CHECKER (14z-163, GitHub #152 — the maintainer's proposal of 14z-159)** | `tools/rulecheck.py` — redundancy for rule APPLICATION: before a measurement becomes an action, `prepare` packs the decision kind, ONE claim sentence (what is claimed, what was NOT tested) and the ARTIFACTS by path, stages them under `build/rulecheck/<id>/`, and pairs the packet with a PLANTED known violation (a fixture, by rotation) in two prompts labelled `a`/`b` at random; the working agent spawns two FRESH agents (never a fork) and `record` takes both verdicts verbatim — six structured lines, prose refused — VOIDS the run if the plant was not caught, and exits non-zero on `VIOLATED` until `resolve` records what changed. The five questions live in `docs/project/rule_checker.md` between CHECKLIST markers and the tool reads them from there. Fixtures: `forced-pick-14z159` (Q3/Q4), `inferred-decision-14z162` (Q5), `fidelity-14z160` (the negative). Ledger `tests/rulecheck/ledger.tsv`, run dirs `tests/rulecheck/runs/<id>/`. Gate `tests/test_rule_checker.sh` (ci_portable): every plant caught, every fixture calibrated, every VIOLATED resolved, every registry row after merged-m18 named by an OK `freeze` run, every plant from its run's own FAMILY, every calibration read by the CURRENT pinned reader; five controls (three until 14z-176, four until 14z-178 added `moved-reader`). **THE PROCEDURE FAMILY (14z-176, #172 slice S3):** the `procedure` decision kind reads a transcript EXTRACT (`tools/agent/extract.py`) under a second checklist, QP1 SAID-VS-DONE / QP2 CLAIMED-VS-RUN / QP3 MEASURED-NOT-INFERRED / QP4 ACCOUNTED, with its own four calibrated fixtures (`proc-*`); it is C1 of the agent architecture and runs at the close, before the push | live |
| **THE AGENT HOOKS (14z-175, GitHub #172 slice S1 — the maintainer's proposal of 2026-09-22)** | `tools/agent/` — **C0.1 is LIVE**: the tracked `.claude/settings.json` runs `tools/agent/hooks/pre_bash.py` before every Bash call and DENIES one that detaches a job the harness cannot track (`nohup`, `setsid`, `disown`, a backgrounding `&` with no later `wait`) or loops on `pgrep` — the reason names the tracked alternative, so the task is redone and the session goes on. It fails OPEN on an internal error and records it in `build/agent_hooks/errors.log`. `permissions.deny` locks the settings, the hooks and `tools/agent/agentlib.py` against the edit tools (not against a write through Bash). `agentlib.py` is the ONE classifier, shared with `tools/agent/transcript_gaps.py` — the census of session transcripts (idle gaps and what ended them, detached vs tracked launches; `--tasks <session>` times every tracked task through BOTH notification forms) that justified the hook. `tools/agent/probe_hooks.sh` re-measures the platform mechanisms in a scratch project (`PROBE_MODELS=` adds model reachability). `tools/agent/probe_agents.sh` (14z-177) re-measures what a `.claude/agents/` WORKER DEFINITION binds — its model and effort apply, a missing effort INHERITS the caller's, the call's `model` BEATS the definition's, a frontmatter `hooks:` block does not fire, a project hook sees and names a worker's calls — and `transcript_gaps.py --subagents <session|all>` reads the model and effort each subagent actually ran at (`docs/platform/gotchas.md`). Gate `tests/test_agent_hooks.sh` (ci_portable, ten controls): the hook over `tests/agent/c01_commands.jsonl`, 68 rows cut from real transcripts and edge cases — 14z-174's twelve `nohup` launches must be denied, and since #290 (14z-204) 24 rows hold the green guard's bypass rule (`agentlib.hook_bypass_reason`: `--no-verify`, `commit -n`, a `core.hooksPath` change), with the control `blind-bypass`; the installation check requires the five edit-lock rules, the git hooks' two included, and its control `missing-lock` drops one (this row said two controls and 40 rows until 14z-176; the 14z-175 close's heredoc fix added the third control and four rows; it said three controls and 44 rows until 14z-204). C0.2 was measured and moved to the procedural checker. **C0.3, THE CLOSE SWEEP (14z-176, slice S2): `tools/agent/sweep.py`** lists every process a session left alive — ATTACHED under this session's tool shells (labelled with its tracked task id), and every ORPHAN reparented to launchd that points into the project (cwd, a stream or its command line, an orphaned Claude tool shell, or the session id where macOS lets the environment be read — not for its own binaries nor Chrome, `docs/platform/gotchas.md`); exit 0 CLEAN, 1 SURVIVORS (the kill hint lists each tree leaves first), 2 if it cannot see itself; `--declare PID "REASON"` records a deliberate survivor. It is a step of the close, after the tier and before the push (`docs/project/session_close.md`). First live run: an 18-day `tail -F | ugrep` of 14z-133 that #172's by-hand check had missed. Gate `tests/test_agent_sweep.sh` (ci_portable, ~12 s, three controls): a planted world of a fake Claude, six orphan shapes and three must-stay-quiet cases. **C1, THE PROCEDURE CHECK (14z-176, slice S3):** `tools/agent/extract.py` cuts a session's transcript into the extract a context-free reader judges (statements, calls, result heads, task events, detached launches, unsourced figures; gate `tests/test_agent_extract.sh`), read under the rule-checker's `procedure` family (QP1-QP4) — see THE RULE-CHECKER row. It was a close step until #288 cut it; its push hook, `tools/agent/hooks/pre_push.py`, was INSTALLED (14z-176b) (**UNWIRED 2026-10-16, #288:** the procedure check is cut; the maintainer installed the settings change that removes this hook, *"The cp has been run."*; the hook and its cases stay in the tree): a `git push` of THIS repository is refused until a passed or resolved `procedure` run covers a commit in the pushed range — the refusal names what to run; gated in `tests/test_agent_hooks.sh` (18 cases plus its reading of the REAL ledger checked against `rulecheck.py`'s; controls `open-push-hook`, `misread-ledger`, `no-target-check`). **S4, THE WORKERS (14z-177, ruled the same sitting): `.claude/agents/measurer.md` and `reader.md`** — named definitions at their stated caps (`sonnet`, effort `high`, read-only tools plus Bash for the measurer), driven by a spec written from **`docs/project/worker_spec.md`** (TASK as a question, pinned INPUTS, numbered COMMANDS, one `FIG <name> = <value> <- C<n>` line per figure); `tools/agent/agent_defs.py` + gate `tests/test_agent_defs.sh` (ci_portable, six controls since 14z-178's `context-leak`) refuse a definition that omits its model or effort (either would follow the caller's — `probe_agents.sh` A4, A9), names a model above Opus-class or an effort above `xhigh`, holds a tool outside Bash/Read/Grep/Glob, or carries any other key (`hooks:` did not fire, A6). **Step 2 (14z-177): `tools/agent/extract.py` prints, under every Agent call, the worker's SPEC, the model and effort it RAN at, its own calls and results and its REPORT (read from `<session>/subagents/`), and a `W#` line for any report figure no result of the worker's own contains; `tools/agent/cut_worker_fixture.py` cuts a session to what the extract reads (a raw transcript carries the user's identity — it refuses to write an e-mail address); gate `tests/test_agent_worker.sh` (ci_portable, three controls) holds a frozen real `measurer` run: at its definition's caps, every figure re-derived from the spec command it names, and nothing run off-spec.** **Step 3 (14z-177): THE CALL GATE `tools/agent/hooks/pre_agent.py` is INSTALLED by the maintainer** — a PreToolUse hook on `Agent|Task` that refuses a model above Opus-class, a `model` on a defined worker (the call's model beats the definition's, A2), no model on a type that would inherit the orchestrator's (`general-purpose`, `Plan`, any unknown type — A9; `Explore` excepted, measured capped at Opus-class under a Fable caller, A11), and a template-driven worker's spec missing a heading; FORKS pass (ruled). Verified live both ways; gated in `tests/test_agent_hooks.sh` (27 cases since 14z-178, 25 before; control `open-agent-gate`). A `general-purpose` reader now needs its `model` stated — the rule-checker's readers already pass `opus`. **Step 4 (14z-178): `.claude/agents/rule-checker.md`** (`claude-opus-5-5` — a VERSION id, never the `opus` alias, which could move to a new model with the definition's sha unchanged, #158 — effort `high`, Read/Grep/Glob, **`omitClaudeMd: true`**) — required by `agent_defs.py` and held to carry that key (control `context-leak`), with two call-gate cases. Its first act MEASURED what a subagent sees (`probe_agents.sh` A13): **every definition without the key, and every `general-purpose` call, receives this project's CLAUDE.md** — and, in an interactive session, the auto-memory index too, contrary to Claude Code's docs — while `omitClaudeMd: true` removes CLAUDE.md and the memory index alike; `transcript_gaps.py --subagents` prints each worker's CONTEXT from its `instructions` attachment, which showed every rule-checker reader in the ledger was handed both. A10 now also reads the THIRD report form (the `<result>` of a completion notification, 2.1.281), which `extract.py` sources too. Its first spawn (interactive, 14z-178) ran at opus/`high` with NO attachment: `omitClaudeMd` removes the memory index too. **Step 4 LANDED 14z-178:** the procedure checklist gained QP5 SPEC-CONFORMANCE and QP3 over workers' figures, with a planted fixture (`proc-planted-spec-14z178`) and its clean twin; `rulecheck.py` binds a calibration to the pinned definition's sha (control `moved-reader`) and `spawned` checks each reader was the definition, with no model, on its prompt verbatim; all ten fixtures recalibrated on it (ledger `2026-09-24-114..123`, then `124..133` on the version-id sha). **S5, THE ORCHESTRATOR, RULED 14z-178:** no definition — under `claude --agent` Claude Code's default system prompt is REPLACED by the definition's body (probe A16) — but a plain session the maintainer starts on Fable 5.1, its effort from the per-model settings (A17) — the MODEL superseded 2026-09-25: the orchestrator is Opus 5.5 at effort High (STATE 'Standing rulings'); its gate is that sitting's close with `transcript_gaps.py --subagents <session> --cap` (every worker at most Opus-class, no fallback) — that sitting was 14z-179 (STATE 14z-179), and the `--cap` read is a step of every close since (ruled *"Standing step"*, 14z-179) | live |
| `tools/freeze_masked_basis.sh` (from the gate fence, 14z-123) | 14z-88: (re)generate a vanilla masked basis (logs+sha1, double-run determinism) under a given MASK_RANGES — masked bytes are SKIPPED from the checksum, so every window addition needs a NEW basis dir (masked / masked-v2 / masked-v3) | live |
| `tools/audit_walker_callers.py` (from the gate fence, 14z-123) | 14z-91: every reference that can reach a walker, enumerated BY FORM (abs.l operand / data longword / pc-relative / branch). Found 23 jsr.l and nothing else. Prints decode noise with context rather than filtering it silently. --toml emits the frozen manifest rows | live |
| `tools/probe_hook_removal.sh` (from the gate fence, 14z-123) | 14z-89: CAUSAL attribution for a legacy-cycle regression — rebuild a tenant with named hooks REMOVED and re-measure a legacy replay against the vanilla basis. The probe is not shippable (the tenant loses a feature) and does not need to be: the legacy replay never touches the tenant. Named both 14z-89 root causes after dump diffs stalled at "extra cycles somewhere": 38 <- fixture_row0f_override_bank0/1 (two cmpi.b at venue fixture-load sites LEGACY runs every venue load), 24 <- the two [[obj_hook]] table extensions. Control in the header: the unmodified build must still FAIL the same replay. ~5 min per probe | live |
| `tools/artifact_manifest.py` (from the gate fence, 14z-123) | 14z-90 (issue #8): per-member SHA-1 of every packed zip in a rompath dir. The program fingerprint covers 8.1% of the shipped bytes; this covers all of it. Refuses a ';' rompath chain (that would fold $ROMDIR into the digest) and is timestamp-free by construction. Wired into test_m3a_reproducible.sh: HARD on member inventory, ADVISORY on member content until the legacy re-freeze | live |
| Vanilla frame-data derivation (14z-125) | `tools/vanilla_frames.py <vsavj_data.bin> [--char DE] --json out.json` | per-chain startup/active/recovery + damage/white/meter for ANY vanilla character, from the vsavj data view + `bank_map.toml`. A SIBLING of `charmap_gen.py`, not a flag: that tool needs a port build (`verify_data.bin` + placements) and `extract_char.py` refuses a (set, char) without a `CHAR_ANCHORS` row — there is no vsavj row |
| THE frame-data derivation (14z-125) | `tools/frame_data.py` | the ONE `startup / active / recovery` computation, imported by `charmap_md.py`, `charmap_html.py` and `vanilla_frames.py`. `active` is the ATTACK NODES ONLY (never the first..last span — the 14z-125 defect) and `notation` renders the community runs grammar (`2(4)3`) |
| Frame-data pages, OUT of the tree (14z-126) | `tools/framedata_pages.sh` | regenerates the per-move documents under `../charpages/framedata/` — the tenants' `<tenant>_anim.md` and `<tenant>.html`, and the full move-by-move `community_crosscheck_full.md` — from the romsets and the committed maps. **THE RULE (maintainer-ruled 2026-08-31): per-move ROM-derived frame data, ours and third-party alike, is not published in this repository; the tree ships the READERS and the VERDICTS.** Currency is locked by SHA-256 (`tests/expected/charmap_pages.sha256`, `tests/expected/vanilla_hit_damage.sha256`); it refuses an output directory inside the repo |
| Community frame-data comparator (14z-125) | `tools/crosscheck_framedata.py`, `tools/xlsx_read.py` | our derivation vs `../community/vsav-framedata.xlsx`, classified EXACT / CONSTANT OFFSET / CONSTANT RATIO / INCONSISTENT / UNCOMPARABLE. The reader is stdlib-only and validated cell for cell against openpyxl (28,234 cells). Page: `docs/project/tables/community_crosscheck.md` |
| Vanilla normal-move RIGS (14z-125/125b; the aerial direction 14z-145) | `tools/vanilla_join_rig.py gen\|analyse` — sets `far` `near` `crouch` `jump` (neutral, U) `jump_fwd` (forward, UR) `hit`; `--durations` `--damage` `--airborne` | (a) WHICH CHAIN each character's standing normals enter, measured at two distances from `+0x1C` (180 rows) — it overturned a fixed even/odd close/far model inferred by fitting our numbers against the workbook being checked; (b) the `hit` set: every DROP in a pinned victim's `+0x50`, so hit COUNT and dealt damage are the engine's (90 rows) — this is what proved the workbook double-counts records sharing the `+0x10` dedup key. **Instrument bound, measured: 16% of `field_trace` frames advance the node countdown by TWO engine ticks, so a frame-rate trace CANNOT adjudicate a one-frame convention**. (c) **THE AERIAL JOIN (14z-145, `tests/test_vanilla_aerial_join.sh`, `tests/expected/vanilla_aerial_slots.tsv`, 360 rows since 14z-146 — four directions):** a NEUTRAL jump attack enters a2 `0x12-0x17`, a FORWARD jump attack a2 `0x18-0x1D` — where the character has no forward variant the entry ALIASES the neutral chain and the same address is entered (VI all but HP, BU LP/LK/HK, LI HP); ZABEL's forward jump enters his NEUTRAL set on all six although his `0x18-0x1D` differ; ANAKARIS has NO neutral-jump attacks (his neutral jump is a hover, `a:0x12`, that takes no normal — declared and asserted). The community workbook's one aerial row per button is the FORWARD variant where mizuumi splits the move (`FORWARD_ROWS` in `tools/crosscheck_framedata.py`, from the corpus's own lists, never from the numbers): the seven aerial outliers of 14z-125 were exactly those, joined to the neutral chain — BI/BU/FE/VI's active and damage columns went to EXACT and their startup to the constant offset. The node map walks a2 BEFORE a (a table-a chain with no terminator overran into a2 and mislabelled AU's neutral LP). **14z-146:** the fourth direction (forward jump then D+button) found ANAKARIS's `J.2K` — one chain `a2:0x1e` for all three kicks; the CONNECTING sets `hit_crouch` / `hit_jump` / `hit_jump_down` and `--meter` feed `tests/test_meter_gain.sh`; `tools/rehit_ring.py` and `tools/meter_gain.py` are the reducers of the two 14z-146 gates |
| Replay format + MAME runner (M1/M2a, 2026-07-25) | `.rpl` in `tests/replays/`, `tests/lua/replay.lua`, `tools/run_replay_mame.sh` | live (paths checked 14z-123) |
| FBNeo harness (patched frontend) (M1/M2a, 2026-07-25) | `emu/fbneo-patches/0001-vampire-saved-harness.patch` (+ `0002-cps2-wide-v1.patch`), `tools/setup_fbneo.sh`, `tools/run_replay_fbneo.sh` | live (paths checked 14z-123) |
| Legacy suite (10 replays, frozen) (M1/M2a, 2026-07-25) | `tests/run_suite.sh`, `tests/expected/vsavj/` | live (paths checked 14z-123) |
| Watchpoint write-tracer (M1/M2a, 2026-07-25) | `tests/lua/trace_writes.lua` (needs `-debug -debugger none`; `WATCH=addr,len[,r\|w\|rw\|b][,p\|d\|o]`, + `DUMPS` since 14z-98 so a -debug trace run carries its OWN state anchors — every -debug watch configuration is its own timeline, docs/GOTCHAS.md) | live (paths checked 14z-123) |
| Pick probe (slot mapping) (M1/M2a, 2026-07-25) | `tools/pick_probe.sh` | live (paths checked 14z-123) |
| Forced-id boot probe (14z-65) (M1/M2a, 2026-07-25) | `tools/force_pick_probe.sh <rompath> <id> <out>` — pokes the commit field across commit->load; verdicts id-hold/load/guard. Validated: vanilla ids load, variant 0x10 wedges on the stage-4 ladder | live (paths checked 14z-123) |
| Structural diff (M1/M2a, 2026-07-25) | `tools/diff_sets.py` (`--mask-pointers`) | live (paths checked 14z-123) |
| Character tables atlas (M1/M2a, 2026-07-25) | `docs/game/atlas/character_tables.md` (3-set anchor, slot maps, D/H/P located, pipelines) | live (paths checked 14z-123) |
| RAM atlas (M1/M2a, 2026-07-25) | `docs/game/atlas/ram.md` | live (paths checked 14z-123) |
| M1 acceptance review (M1/M2a, 2026-07-25) | `docs/project/M1_acceptance.md` (both clauses met; R2 quantified) | live (paths checked 14z-123) |
| Write/read tracer (M1/M2a, 2026-07-25) | `tests/lua/trace_writes.lua` (WATCH=addr,len[,r|w|rw]) | live (paths checked 14z-123) |
| Program patcher (M1/M2a, 2026-07-25) | `tools/patch_prg.py` (JSON ops, word-value space) + `tools/pack_build.sh` | live (paths checked 14z-123) |
| M2 feasibility (M1/M2a, 2026-07-25) | `docs/project/M2_feasibility.md` (3 domains; remaining work list) | live (paths checked 14z-123) |
| Patch-tooling test (M1/M2a, 2026-07-25) | `tests/test_patch_prg.sh` (null bit-identical, code re-encrypts) | live (paths checked 14z-123) |
| M2 repoint proof (M1/M2a, 2026-07-25) | `tests/test_m2_repoint.sh` (mechanism + superset invariant) | live (paths checked 14z-123) |
| Select wheel + id space (14z-60) (M1/M2a, 2026-07-25) | `tools/select_wheel.py` (decode/verify TABLE A+B, generate a full-coverage walk), `tools/check_wheel_walk.py` (measured vs predicted), `tools/audit_id_space.py` (id width at every consumer + the variant-row alias matrix), `tools/wheel_positions.py` (cell -> screen position, measured from the palette-0x1E cursor ring in OBJ RAM); atlas `docs/game/atlas/select_screen.md`, `docs/game/atlas/id_space.md` | live (paths checked 14z-123) |
| Crash guard (M1/M2a, 2026-07-25) | `tests/lua/replay_guard.lua` + `tools/run_replay_guarded.sh` (`GUARD_DEBUG=0` for cheap/checksum-canonical mode; `-debug` mode for breakpoint crash capture — its checksums are NOT comparable to non-debug runs, docs/GOTCHAS.md) | live (paths checked 14z-123) |
| Crash-guard ground truth (M1/M2a, 2026-07-25) | `tests/test_crash_guard.sh` (clean negative + vec4/vec3 positive controls) | live (paths checked 14z-123) |
| Dual-emulator field comparator (M1/M2a, 2026-07-25) | `tools/compare_fields.py` + `tests/fields_m2a.tsv` (debounced anchors; stable/settled/phase field classes; `--exact` for same-emulator) | live (paths checked 14z-123) |
| Comparator ground truth (M1/M2a, 2026-07-25) | `tests/test_compare_fields_selfcheck.sh` (§4 protocol exercised: MAME/FBNeo agree on `16_xemu_2p`, 1-frame skew) | live (paths checked 14z-123) |
| Dump-set completeness (M1/M2a, 2026-07-25) | `tools/check_wram_dumps.py` — `compare_fields.py` GLOBS, so a lost dump silently moves the anchor instead of failing. Asserts a per-frame dump directory is complete: `--first/--last`, `--size`, `--addr`, or `--contiguous` for a directory of unknown extent. Run by `tools/run_sim_jtcps2.sh` on every `--wram` run and by `test_mister_sim_anchor` on BOTH legs (14z-107 (7)) | live (paths checked 14z-123) |
| Dual-emulator-safe replay template (M1/M2a, 2026-07-25) | `tests/replays/16_xemu_2p.rpl` (authoring rules in docs/GOTCHAS.md — vs-CPU replays have emulator-divergent content!) | live (paths checked 14z-123) |
| Slot-0x0F pick replay (M1/M2a, 2026-07-25) | `tests/replays/11_pick_donovan.rpl` (Jedah on vanilla; per-build expectations via fingerprint dispatch) | live (paths checked 14z-123) |
| Auto-detecting suite runner (M1/M2a, 2026-07-25) | `tests/run_suite.sh` — `MAME_ROMPATH` fronting, fingerprint → `tests/expected/<expset>/`, `.diverge` expectation kind (exact-frame divergence vs frozen full logs under `expected/<set>/logs/`) | live (paths checked 14z-123) |
| Fingerprint / registry (M1/M2a, 2026-07-25) | `tools/build_fingerprint.py`, `tests/expected/registry.tsv` (rows only at freeze time, STATE.md decision) | live (paths checked 14z-123) |
| Diverge checker (M1/M2a, 2026-07-25) | `tools/check_diverge.py` | live (paths checked 14z-123) |
| Flicker comparator (hooked-build legacy gate v2) (M1/M2a, 2026-07-25) | `tools/compare_flicker.py` + ground truth `tests/test_compare_flicker.sh`; frozen masked vanilla logs `tests/expected/vsavj/masked/` | live (paths checked 14z-123) |
| Dispatch ground truth (M1/M2a, 2026-07-25) | `tests/test_suite_dispatch.sh` (no emulator; fast) | live (paths checked 14z-123) |
| FBNeo runner extensions (M1/M2a, 2026-07-25) | `tools/run_replay_fbneo.sh`: `FBNEO_DUMPS` (-hdump), `FBNEO_ROMPATH` zip overlay — **verified to load CRC-changed patched zips** | live (paths checked 14z-123) |

FBNeo build: `(cd emu/fbneo && make sdl2 SKIPDEPEND=1 -j8)` — `SKIPDEPEND=1`
is mandatory (docs/GOTCHAS.md). Needs brew `sdl2`(-compat) + `sdl2_image`.

## From HANDOFF.md: «Running a CPS-2 WIDE build — the Oboro path»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

**The Oboro path in (2) is OURS and the Dark Gallon one beside it is
VANILLA'S**, which is why the two must not be confused when either is
touched: the shipping `oboro_select_hook` is a `[[site_thunk]]` at
`PRG:0x020B9C` in all three tenant manifests, displacing the confirm-time
`cmpi.b #$2,$382(a6)` and re-executing it, so vanilla's own Gallon-variant
idiom at `PRG:0x020B9C` one cell over (Gallon + START + 2-3 punches or
kicks -> Dark Gallon `0x12`) is preserved BY CONSTRUCTION. Removing the hook
would make Oboro unreachable again and leave Dark Gallon untouched — no
vanilla path anywhere writes `0x18` (STATE "THE ARCADE HIDDEN-CHARACTER
ROSTER"). Detail: `docs/game/atlas/select_screen.md`,
`docs/project/patch_index.md` W1.

## From HANDOFF.md: «Running a CPS-2 WIDE build — the hardening and §4 coverage programs»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

**THE HARDENING PROGRAM (14z-100, maintainer-directed) — the
crash-candidate map of the merged build lives in
`docs/project/hardening_register.md` (maintained in the same commit as
any change to its classes).** Instruments it added, all committed:
`tools/audit_pointer_flow.py` + `tests/test_pointer_flow.sh` (ci_static
— every address the patch introduces, classified against the op map AND
the shipped image; frozen baselines in `tests/expected/pointer_flow/`);
`tools/triage_pcrel_escapes.py` + `tests/test_escape_triage.sh`
(ci_static — uncovered word-form escapes, 25 verdicts frozen, zero
live); `tests/audit_continue_switch.sh` (the #99 lock: continue+switch
through the literal Donovan-vs-CPU-Phobos pairing, five assertions);
`tests/audit_projectile_clash.sh` + replays 105/106 (the pool-vs-pool
contact surface: must-fire control + — since 14z-101 — the frozen
NATIVE-PARITY signature with a vsav2 anchor leg; the former fix mode
is refused); `tests/audit_guard_corpus.sh` (14z-101 — the whole
79-replay corpus × 4 legs under the crash guard on the build under
test; first merged-m4 run 316/316 END-clean; the known hui41 0x494de
crash is its must-fire control). Re-pointed to the current freeze
the same session: `audit_tripwire_reach.sh` (six marathon legs green),
`test_pcrel_escapes.sh` + `pcrel_escapes.toml`, `bases.tsv` (tenant
hitbox bases MOVE with freezes — re-derive at every freeze, note in the
file). Open findings (final 14z-102): #106 CLOSED (14z-101); **#107 and #109
both SHIPPED AND CLOSED at the 14z-102 freeze** (the mid-window
expected-red state resolved — both gates green on re-frozen pins; the
#109 mechanism went through two more retractions before landing on
effect-class ROW 31, see STATE 14z-102 (2) and the issue).
**#108 RESOLVED NOT-A-DEFECT (14z-101):** the satellite
word is our own load-bearing `obj_bank_word_slot` bank row, the sweep
keys on `+0x94`, and native vs2's satellites are equally sweep-inert
(STATE 14z-101). The window state: NEXT_SESSION banner.

**THE §4 COVERAGE PROGRAM (14z-104, maintainer-directed "tackle the
coverage debt") — the census and its instruments live in
`docs/project/coverage_matrix.md` (maintained in the same commit as any
change to what it names).** Six new on-demand audits, all green on
merged-m5, all poke-generic (legs choose characters by the replay-85
doctrine) with legacy controls + discriminating negative controls:
`audit_df_framework.sh` (the ruled DF table: cost 1 stock, durations
360/360/377/360); `audit_tenant_timeout.sh` (the timeout judge awards
the down to the HP leader — $FF8120/$FF810E, atlas rows added);
`audit_tenant_downwin.sh` (KO-path life-marker transition, every tenant
as winner AND victim — the direct #103-class lock);
`audit_tenant_throws.sh` (normal throw both directions; the throw
discriminator is the strength-independent toss); `audit_down_attack.sh`
(hitting a downed opponent both directions — per-character windows,
Phobos wakes in 24f; the §4 "pursuit" cell, naming question with the
maintainer); `audit_stage_sweep.sh` (every tenant x all 12 stages with
contact; the $FF8100 poke at f2150/2200 is measured load-bearing on the
venue assets). `audit_pursuit_leap.sh` (the maintainer-confirmed NW leaping pursuit:
fires per tenant both directions, per-char arcs frozen loosely,
no-knockdown discriminator; CONNECT is the documented open refinement —
a wake-vs-flight knife edge even on the all-legacy control; mechanics
in engine_internals "THE LEAPING PURSUIT"). Rigs:
`tests/replays/judge/01-03` (subdir = gate-owned, outside the suite's
account). `audit_roster_pairings` re-ran 111/111 on merged-m5 (~5 min —
run it at every freeze). Open cells: tech-hit/tech-roll rigs (also
unlocks pursuit-connect); KO-frame/corner edge cases;
Shadow/Marionette (N/A-until-enabled).

## From HANDOFF.md: «the native leg, the DF palette census, the docs split, prior art, the repo path, platform notes»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

## **[VSP-123]** THE NATIVE LEG IS REACHABLE FOR ANY TENANT SCREEN (14z-69)

Huitzil can be forced on **native vsav2** with the ordinary
early-window poke — no vs2 cursor path, no savestate:

```sh
POKES="1400:ff8782:10;1450:ff8782:10;1500:ff8782:10"   # P1; P2 = $FF8B82
tools/run_replay_mame.sh vsav2 <replay> out.log        # ~6 s
```

Verified by `+0x382 = 0x10` on the native leg **(read at select/commit; on a 1P CPU flow the arcade ladder writes the CPU side's next opponent there before it loads — ram.md `+0x382`, corrected 14z-188)**, with DF (seq 0x0A) and
the air dash (seq 0x14) both firing. **Poke BOTH sides** when sprite
lists are compared: the cursor path lands on different characters on
the two wheels (P2 = 0x03 is Victor on vsav *and* vsav2).

**And when the state under test is a MODE, prove it was entered.** Dark
Force costs a banked stock; with an empty meter the P+K pair is
downgraded to a single button and the match looks normal. Poke
`$FF8509` and assert `$FF802E`=1 — never infer a mode flag from the
fighter block (`+0x1F4`, `+0x1B5/+0x1B9` are set by JUMPING).

**THE POKE HOLDS THROUGH SELECT ONLY, AND THE CONFIRM COMES FIRST (measured
14z-160, GitHub #151 — read before using this recipe for anything the confirm
latches).** The select CONFIRM (frame ~1299 in the naming rigs) writes
per-fighter state for the cell the cursor is ON, before the pokes above land:
the VS2/VH2 flavor `+0x3C2` and two id copies `+0x3BD`/`+0x3E0`
(`atlas/ram.md`). A poked "native Phobos" therefore carried Donovan's VH2
flavor for the whole match — #147 shipped a wrong fix on it. For a native leg
whose subject can depend on those, use a REAL cursor path instead: on vsav2
from P1's default cell Phobos is `L,L,L`, Pyron `R,R,R`, Donovan `R,R`; from
P2's, Victor `R,R`, Phobos `L,L`, Pyron `L,L,UL`, Donovan `R,R,R`
(`tools/select_wheel.py` on the vs2 data view). On the merged build from
Demitri's cell: Phobos `D,D,D`, Pyron `D,D,D,D`, Donovan `D,D,DR,DR`
(measured). `tests/audit_forced_pick_fidelity.sh` freezes exactly what the poke
gets wrong; `audit_move_parity` and the naming rigs run real picks since
14z-160. **THE SWEEP OF EVERY OTHER POKED LEG (14z-161, #151 step 3) found the
poke's defect is decided by the CELL and the fighter's READERS, not by the poke:**
the confirm writes the flavor only on Phobos's cell (00) and Donovan's (01), and
only Phobos's and Donovan's code read it — so a Phobos poked over Demitri's cell
(every `tests/hui/` gate) reads the 00 a real pick writes, a Phobos over
Donovan's cell reads 01 (the #147 shape, no longer used by any gate), and the
Donovan-over-other-cell legs latch 00 but no reader fired on any of them under
the tap; the id copies are read in play on no leg. The instruments:
`tools/select_paths.py` (a real path to ANY cell, either player, either wheel —
P2 starts on `0x05`), `tools/audit_poked_legs.py` + `tests/test_poked_legs.sh`
(the census, frozen; a new CROSS-FLAVOR pairing fails until measured and
accepted), `tools/audit_latch_readers.py` + `tests/test_latch_readers.sh` (who
CAN read the latch, every form, frozen) and `tools/tap_latch_reads.sh` +
`tests/audit_latch_reads.sh` (who DOES, per leg shape, with the value seen).

This retires "the native leg is unreachable", which was inherited from
a single 14z-68j attempt with **replay 61** — a replay whose input
timing is authored for OUR wheel and does not transfer. Anything still
parked on "needs a native reference" (the win QUOTE set, the child
shadow, effect art) can now be A/B'd directly. Do not characterise a
tenant symptom without this leg — 14z-69 retracted two findings that
were artefacts of measuring our build alone (docs/GOTCHAS.md).

## **[VSP-151]** THE DF PALETTE-SEQ BLOCK CENSUS — measured, and it had to be (measured 14z-79b)

Which palette-seq ids each character requests in Dark Force, measured on
vanilla vsavj with `$FF802E`=1 asserted per row:
`docs/game/engine_internals.md` "THE DARK FORCE PALETTE-SEQUENCE BLOCKS".
Occupied: `0x1E-0x21` Bulleta, `0x26/0x27` Demitri, `0x44-0x47` Zabel,
`0x6F-0x72` Bishamon+Oboro, `0x264-0x267` Q-Bee, `0x29C-0x2A0` char 0x12
(five ids), and `0xAA-0xAD` **Sasquatch** — the corpus census
`tests/expected/df_palette_seq_census.txt` (14z-118 (14)); this line said
"probably Anakaris — the one character the rig could not put into DF" until
14z-123: RETRACTED 14z-118 (9)/(14), DF on, zero palette-seq calls for him.

**Do not derive this from table `0x02A8A4`.** Ten rows share routine `0x0040`
yet only some request ids; the routine is conditional and a static reading
gives a confident wrong map. **And the resolver masks to 12 bits**
(`0x39A900 + (d0 & 0x0FFF)*0x20`), so a tenant block must live inside
`0x39A900-0x3BA8E0` and CANNOT go in `wide_ext`.

Run it: `CHARS="00 01 02 ... 18" tests/audit_palette_seq_ids.sh`.

## DOCS ARE SPLIT THREE WAYS — `docs/README.md` (since 14z-69)

`docs/game/` (Vampire Savior itself) | `docs/platform/` (CPS-2, MAME,
FBNeo) | `docs/project/` (this port). The discriminator: **would this
still be true if we abandoned the roster hack tomorrow?** File by the
FACT, not by the task you were doing when you learned it.

`docs/GOTCHAS.md` is now an INDEX of every entry, grouped by bucket
(the count used to be quoted here; it was stale by 25 within a few
sessions, so it is deliberately not repeated);
the entries live in `docs/{game,platform,project}/gotchas.md`. Every
existing citation of `docs/GOTCHAS.md` still lands there.

Looking for whether we already know something? The index is the fastest
topic list; `docs/game/atlas/ram.md` is the fastest address lookup, and
each of those two files now opens with a routing table — this one's is at
the top, the atlas README's answers "what IS this address".

**A NEW DOCUMENT NEEDS THREE THINGS IN ONE COMMIT, and since the living-docs
routing slice the third is enforced:** its `docs/doc_shape.tsv` row (class,
history twin, requirements), its line in `docs/README.md`'s `## Contents`
with its declared SHAPE, and — if it is a `<name>_history.md` twin — a
mention of its live document, which must mention it back.
`tools/checkdocshape.py` fails on any of the three; a level-0 entry point
that belongs outside Contents declares `entry-point` in its `requires`
column and must still be named somewhere in `docs/README.md`. A directory
entry (the `atlas/` line) covers the members its own line NAMES in
backticks, never the directory, so a new atlas file is caught too.

## **[VSP-155]** PRIOR ART FIRST — check the subsystem doc before re-deriving (14z-68m)

Huitzil's win screen was re-derived from scratch and got two of three
pieces wrong; Donovan's identical solution had been sitting in
STATE.md since 14z-45. The analysis existed, it just was not
DISCOVERABLE from "I am working on tenant X's screen Y".

**Before porting any per-character screen or subsystem for a new
tenant, read the matching section of `docs/game/engine_internals.md`** —
it now carries the worked instances for BOTH tenants (win screen,
select family, HUD, effect system, palettes). If the subsystem has no
section there, write one as you go: a session-log entry is a record of
what happened, not a document anyone will find later.

Cheap rule that would have caught it: when a symptom on tenant B
resembles one already fixed on tenant A, `grep -n "<subsystem>"
docs/game/engine_internals.md docs/project/patch_index.md` and diff A's manifest
rows against B's BEFORE measuring anything.

## Repo path: `Vampire Saved` -> `Vampire_Saved` (since 2026-08-05)

The project root is now `/Users/koneko/Developer/Vampire_Saved/VampireSaved`
— the space is gone. Nothing in git was affected, but:

- An in-flight worktree pinned to the old absolute path was orphaned
  mid-session. **Commit before anything that moves the tree**, and
  `git worktree prune` after a path change (a stale locked entry survives
  the directory it names).
- A fresh worktree branches from `origin/main`, which trails local `main`
  badly here — `git reset --hard main` immediately after creating one.
- ~~**`tools/setup_mame.sh`'s rsync mirror exists ONLY because GENie could not
  handle the space.** That constraint is gone, so the mirror could be
  dropped — but it changes the INSTRUMENT, so `tests/test_mame_parity.sh`
  must be green before and after. Not attempted yet.~~ **CORRECTED 14z-157:**
  the space is why the mirror was BUILT, and it is gone, but the mirror now
  does other work — the pinned submodule stays pristine while the profile
  patch is applied in the mirror, the WIDE and reference builds get separate
  roots, and the release build gets its own. **Dropping it was declined
  (maintainer, 2026-09-15, #80).**

## Platform / migration notes (14z-59d)

**The focus problem is already solved in place.** `tools/run_mame.sh` now
exports `SDL_VIDEODRIVER=dummy`, so SDL creates **no window at all** — there
is nothing to take focus and nothing for a stray keystroke to land on.
Measured non-perturbing: work RAM bit-identical to the frozen expectations,
and `VIDEO_OUT` still captures a live framebuffer (3,952 distinct checksums
over 5,520 frames — the emulated bitmap is internal to MAME and owes
nothing to SDL). Combined with the input-provider isolation and the
per-frame integrity assertion, a migration is now a *choice*, not a
necessity.

**[CPE-41]** **[MFI-41]** **What is actually at risk in a move: only the MAME expectations.**
- `tests/expected/**` are ABSOLUTE frozen values, and they are **MAME-only**
  — `run_suite.sh` drives MAME.
- Every FBNeo gate (`test_wide_profile.sh`, `test_fbneo_replay_determinism.sh`,
  the xemu gates) is a **live A/B comparison** and carries no frozen file,
  so it is machine-independent by construction. Verified by inspection.
- So `tests/test_mame_parity.sh` **is the migration gate**, and it covers
  the entire exposure. Run it on the target before trusting anything. If it
  fails, do NOT re-freeze to make it green — that silently redefines the
  baseline the superset invariant rests on.

**Does CPU architecture matter (ARM64 vs x86_64)?** It should not, and the
reason is specific rather than hopeful:
- MAME emulates CPS-2's 68000, Z80 and QSound DSP16 with **interpreters**.
  MAME's DRC/UML recompilers cover other CPU families (MIPS/PPC/SH), none
  of which CPS-2 uses — so there is no JIT whose codegen could differ.
- FBNeo ships an **A68K x86 assembly** 68000 core, but `BUILD_A68K` is
  commented out in its makefile and x64 targets undefine it anyway, so both
  ARM64 and x86_64 builds use the portable Musashi C core.
- All candidate hosts are little-endian, and `replay.lua` reads with an
  explicit `"<i8"`, so the checksum stream is endian-pinned regardless.

Still: that is an argument, not a measurement. `test_mame_parity.sh` is the
measurement, it is cheap, and it exists.

**Step-by-step Windows/WSL2 (and Linux) setup: `docs/project/WSL2_SETUP.md`** —
written for someone who has not used WSL2, and section 7 is the acceptance
test that decides whether a machine can be trusted.

**Target ranking for this toolchain** (POSIX shell + SDL builds):
| Target | Verdict |
|---|---|
| **Linux** | Best destination. Native SDL builds for both emulators, every `tests/*.sh` runs unchanged, true headless trivially. Only edits: `sysctl -n hw.ncpu` → `nproc` in `tools/setup_mame.sh`, and note `tools/build_donovan.sh` requires **bash** (it relies on `set -o pipefail`; shebang corrected 14z-90 — the earlier "runs unchanged" claim was written three days after pipefail landed and was never validated under dash). |
| **Intel Mac** | Lowest friction *today* — the scripts are already macOS-shaped and brew provides sdl3/pkgconf. Good stepping stone; architecture is a non-issue per the analysis above. |
| **Windows 10** | Highest porting cost natively: the harness is POSIX shell plus FBNeo's **SDL** frontend, so it needs MSYS2 for both emulators and a POSIX shell for every gate. **Use WSL2 and treat it as the Linux target** — that is the pragmatic path if this is the machine that is free. |

## From HANDOFF.md: «How to test — the review-triage gates and the out-of-range index toolkit»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

### **[VSP-102]** THE REVIEW-TRIAGE GATES (14z-94, GitHub #74's index)

Every one of these was written while closing a finding from the adversarial
review. They are ROM-free and in `tests/ci_portable.txt` unless the row says
otherwise (a "not portable" gate needs ROMDIR, a build dir, or a MAME
binary, and would SKIP on a clean checkout — which `ci_portable` treats as
failure). The portable set's gates run in about four minutes, ~15 more with
their controls executed (79 gates, measured 2026-09-15) — `tests/run_all_static.sh` since
14z-94; if you loop `tests/ci_portable.txt` by hand, **close stdin** — a gate that reads it
swallows the rest of the list, which is how a 32-entry run silently became 28.

These gates are family `review-triage` in `docs/project/gate_index.md` (its count is the generated page's, not this one's)
(each row's header now carries its issue and what it locks); the table as
of 14z-123 is in `HANDOFF_HISTORY.md`.

**One helper worth knowing about:** `tests/lib/shadow_tools.sh` gives a test a
WRITABLE copy of a tool inside a throwaway repo ROOT. The root matters —
`gen_donovan_patch.py` resolves the repo from `Path(__file__).parent.parent`
and imports its siblings off its own directory, so a bare `/tmp` copy finds
neither its manifests nor `cps2_decrypt`. Use it for any control that must
perturb a tool; never edit tracked source from a test.

**Two tools that now exist because of this batch:** `tools/qs_ledger.py`
(resolve the voice ledger BOUND to a romset — the audits call it instead of
carrying their own rule) and `tools/decode_stage_banners.py` (names the #92
value space).

### **[VSP-150]** THE OUT-OF-RANGE INDEX TOOLKIT — three instruments, one class (measured 14z-78)

`audit_index_space.py` names the DANGER WINDOWS (entries vsavj's table cannot
answer but vs2's can). Two crashes had already landed in the same window
before anyone asked who drives them:

| table | valid | entry | consequence | driver |
|---|---|---|---|---|
| `0x018468` | 0..79 | 80 | ODD -> vec3 — LOUD | (none live) |
| | | 81 | jumps into the table -> reset — LOUD | Pyron Cosmo (fixed 14z-75) |
| | | 82 | ODD -> vec3 — LOUD | **Phobos Plasma Trap** |
| | | 83 | even, real code — **SILENT** | **Phobos Reflect Wall** |
| `0x0185da` | 0..85 | 86-89 | all LOUD | none live (cleared by playtest) |
| `0x03975e` | 0..9 | 10 | SILENT | dispatcher never reached (measured) |

**Read the CONSEQUENCE before valuing any evidence.** "No crash" clears a LOUD
entry completely and a SILENT one not at all — the same clean playtest cleared
Donovan's 15 candidates and said nothing about Phobos' entry 83.

- `tools/audit_index_users.py` — WHICH tenant data lands in a window. Learned
  from the ratified Cosmo fix (index = low byte of `0x01NN`), windows taken by
  RUNNING `audit_index_space.py` so the two cannot disagree. Reports a `shape`
  signal, never filters on it: that 3-sample signature would have pruned entry
  83, which is real. **Does NOT narrow the moves to playtest** — it reports
  addresses, not moves, and sees one defect class only.
- `tests/lua/index_watch.lua` — attributes a dangerous dispatch to the MOVE
  during LIVE play (breakpoints are cheap: ~11 dispatches per 130s). Carries a
  HEARTBEAT because a dead watch once produced a tidy-looking empty log for a
  whole sweep; an idle watch now says so. Prove it with `INDEX_ALL=1` before
  trusting quiet. `INDEX_WATCH="jmp:n_valid,..."` overrides the windows.
- `tests/replays/hui/87_hui_plasma_trap.rpl` — reproduces the crash (forward
  jump, 214 at +10f, MK). **NOT a gate**, and its scripted strengths are NOT
  authoritative: its "LK" variant crashes where the maintainer's real LK does
  not.

Diagnostic instruments added with that gate (MAME Lua, all rerunnable):
`tests/lua/snapshot_frames.lua` (real PNG snapshots headlessly — MAME
renders its bitmap internally even under `-video none`, so `video:snapshot()`
works and the screen can be LOOKED at in-loop), `tests/lua/obj_records_dump.lua`
(the live sprite list with the composed 18/19-bit tile address per entry;
**both gained `POKES` in 14z-68** — replay.lua grammar, so forced-pick rigs
can finally be photographed and OBJ-dumped; reach for these BEFORE the third
RAM-layer iteration, docs/GOTCHAS.md "verify at the RENDER layer"),
`tests/lua/gfx_region_dump.lua` (decoded tile bytes at a TILE index —
compose the bank bits first, see GOTCHAS), and **`tests/lua/read_tap.lua`
(14z-87)** — the non-debug PC-attributed READ+WRITE tap that serializes a
state-dependent value's writes and reads in ONE run (work-RAM only; ROM
read taps are RH-15-blind). Reach for it whenever a written value and a
read value must be compared — never correlate them across runs (GOTCHAS).
Since 14z-169 `RPCS="pc,pc,…"` logs a READ only from the listed pcs (writes unaffected, unset
= the old output) — for a field the engine reads everywhere, such as `+0x382`
(`tests/audit_defense_row_reads.sh`).

All tests are self-contained, take state only via env/args, print PASS/FAIL,
and exit nonzero on failure. Every dev-time in-emulator probe must land here
before session end (persistent suite doctrine, CLAUDE.md §4).

## From HANDOFF.md: «THE EMULATOR-TIER COMMAND — measured runs on ERIS and PILOT»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

**AND ON ERIS, SPLIT BY HOST (14z-198, the merged-m23 re-release):** the MiSTer lane on this Mac (`--lane mister --jobs 4`, PASS 12, longest `test_mister_gfxc_fetch` 5,857 s) and prereq/fbneo/mame on ERIS's WSL2 (`--jobs 12`): 413 rows, 404 PASS. **`--jobs 12` there is too many for the headroom rule:** four rows crossed half their cap under the load (`audit_guard_corpus` 10,184 s of 14,400 against its usual ~4,500-5,200; `audit_hitclass_map_cost` and a control 0.51-0.52; `audit_merged_legacy@first-frame-skip` 0.58); re-run one gate per runner, six at a time (`xargs -P 6`), they came back at 0.29-0.32. Start an ERIS tier script headless (`docs/platform/gotchas.md` "ON A WSL2 BOX REACHED ONLY OVER SSH"). Three gates are host-bound at a release: `test_mame_parity` needs a reference MAME distinct from the build under test (this Mac's Homebrew one), `test_release_binaries` and `test_readme_recording` the host's own release binaries; the Linux-release pair runs on PILOT (`podman`, a GNOME Wayland session).

**THE SAME RUN ON PILOT, PER GATE (14z-189 run, read 14z-193, #122; the
answer ruled "Sounds good enough"):** PILOT (`ssh pilot`, 6 vCPU of a Ryzen 5700G, 40 GiB,
Ubuntu 24.04) ran the same command at `--jobs 4` on `9f7d9b45` (the M21-era tree),
2026-10-02 21:08 to 2026-10-03 09:01 UTC — 387 rows (215 gates, 172 control runs), PASS 378 /
SKIP 5 / FAIL 2 / TIMEOUT 2. **Over the 196 rows both runs ran and both passed, PILOT took
2.04× the Mac's seconds** (95,859 s against 47,061): fbneo 1.28× (6 gates), mame 1.75× (133),
mister 2.23× (7; Verilator 5.020 there against the Mac's 5.050, so not the host alone), prereq
1.32× (18); the controls alike (1.16-2.27×). Reproduce with
`python3 tools/emu_run_compare.py build/emu_controls_14z153 <PILOT's results.tsv>` (the run dir is
`~/vampire-saved/build/emu_pilot_14z189_controls` on PILOT). **The wall times do NOT compare**: the
runs differ in content (183 rows PILOT's alone, the M18 set against M21), the two FAILs are the
environment (a non-login `ssh` shell without the PATH `mame`, `docs/project/gotchas.md` "A REMOTE
BATTERY STARTED FROM A NON-LOGIN SHELL"), the two TIMEOUTs are the MiSTer oracles killed at the
7,200 s cap (uncapped there 9,158 / 9,304 s, `docs/platform/mister_history.md`), and at `--jobs 4`
a row's seconds include what ran beside it.

## From HANDOFF.md: «Running a CPS-2 WIDE build» — merged-m1 and the older merged builds

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

**~~KNOWN-OPEN on `merged-m1`~~ RESOLVED 14z-94 (GitHub #91/#92) — kept
because the MECHANISM is still how a tripwire reaches a player.** The fix is
the #91+#92 batch (huitzil-m16 / pyron-m10 / merged-m2), "the first builds on
which a planted tripwire is NOT reachable in extended play"; `merged-m1` is
long superseded (the current merged build is the registry's top row —
merged-m20 at 14z-183; this line said `merged-m14` until 14z-157,
`merged-m18` until 14z-170 and `merged-m19` until 14z-183). What
was measured on merged-m1, and still describes the failure MODE: `tests/audit_tripwire_reach.sh` measures
`CRASH 8887 vec4 PC 456930` — the tripwire for unresolved vs2 `0x494de` —
on the 40,620-frame arcade marathon with Huitzil forced. Deterministic.
~~**NOT Huitzil-only — retracted 14z-93:** the Pyron and Donovan legs' clean
`END 40620` is a TIMING accident, and under a sparse probe Pyron crashes
identically (#92). It is a RACE, which is why three clean playtest matches
prove nothing.~~ **CORRECTED 14z-157 from #91's own thread: this crash IS
Huitzil-only** — its six-leg matrix ran Pyron and Donovan `END 40620` clean on
the solo and merged builds ("Two different bugs"); the Pyron crash under a
sparse probe, and the race, are #92's (`vec3` at the ladder dispatcher
`0x1afb4`). A short playtest still proves little, for #91's own reason: the rig
fires at frame 8887, so depth is not the trigger — a specific action or spawn
under the dense-chord mash is likelier. The reconciliation row that resolves it is COMMITTED but this
fingerprint predated it; resolving it exposed a second crash (#92), which is
why the re-freeze waited for #92 rather than shipping twice — both landed
together at 14z-94. **THE DURABLE PART: `run_suite` does not see this class**
— no suite replay is long enough, which is why that artifact was frozen
green. `tests/audit_tripwire_reach.sh` (on-demand, ~15 min) is the instrument
that does, and playtesting a long arcade run with Phobos is its field
equivalent.
**THE CURRENT MERGED BUILD IS THE REGISTRY'S TOP ROW** — `build/m3b_merged31`
= merged-m23 at 14z-192 (this line named `m3b_merged30` = merged-m22 until
14z-192, `m3b_merged29` = merged-m21 until
14z-189, `m3b_merged28` = merged-m20 until
14z-185, `m3b_merged27` = merged-m19 until
14z-183, `m3b_merged21` = merged-m14 until
14z-157, and `m3b_merged26` = merged-m18 until 14z-170); see "Current WIDE builds" above. `build/m3b_merged8` was `merged-m1`,
frozen 14z-92 and long superseded; the paragraphs below describe IT and are
kept for the superseded-build facts they carry (which dirs are known-bad,
which cannot boot on current binaries), not as a statement of what to run.
The map: `docs/project/tables/qs_voice_map.md`. Superseded:
hui38/pyron23/m5_wide (donovan-m3a — tag `freeze/donovan-m3a` is the
way back; its expectation set carried-renamed `donovan-m4`),
m3b_merged5. **COMPAT (WIDE v1.1,
14z-86): builds made before v1.1 (hui37 and older, m3b_merged4 and
older) lack `vsw.z01/z02` and DO NOT BOOT on the v1.1 emulator
binaries** — inject stock copies (2-line python, see
tests/audit_trap_parity's hui37 ground-truth recipe in STATE 14z-86)
or rebuild. `build/hui34`/`hui36` remain the parity/shock audits'
ground-truth-failing references (a ground-truth run on them now needs
the stock-member injection first — the audits do not inject). Superseded solos hui33/pyron22 stay on disk (their extract
dirs remain the tenant_loop/build_merged inputs).
`build/m5w` (`ac52eeff`) is the KNOWN-BAD artifact of the 14z-60y sprite
garble, kept as evidence — do not playtest it. `tools/audit_romset_identity.py
build/m5w/rompath` names its four shadowed members in a second.
**`build/m3b_merged8` is the MERGED BUILD WITH GFX** (14z-92; supersedes
merged7, which was built at 14z-87 and predates the whole 14z-91 legacy
fix). Fingerprint `952fc731`, **753 ops** — the 3-tenant program image
(owner tag + sfx records + damage work-var rows + the chirp/shock fixes
+ the M5 VOICE BATCH + THE 14z-91 WALKER RELOCATION, fixture deletion
and type-6 change) + the S2 gfx chain (D → H → P, group B pristine) +
the authored Z80/sample members (`vsw.z01/z02`, `vsw.21m` — both
playback laws enforced). All three tenants verify (`verify_gfx_build` +
`check_tenant_hud`). UNREGISTERED until the S6 freeze decision —
run_suite refuses it. **QUALIFIED 14z-92 on the artifact gates:**
`test_merged_render_content` PASS (after its huitzil reference was
repaired — see below), `audit_trap_parity` PASS, `audit_fg_parity`
PASS, `audit_select_bank_gates` PASS. `audit_merged_legacy` NOT run —
it builds its own gfx-free instrument from unchanged manifests, so on
this tree it is a re-run of 14z-91's green 47/47 + 6/6 at the same 753
ops, not coverage.
**`test_merged_render_content`'s huitzil reference was DEAD** (14z-92):
it named `build/hui31`, a pre-WIDE-v1.1 build MAME now refuses
(`vsw.z01 NOT FOUND`), so H/P's only render gate had produced no
huitzil measurement since 14z-86 — and printed the dead leg as a
content mismatch against an empty value. Re-pointed to `hui41`;
an empty operand is now reported as a DEAD LEG. **All three rows were
re-pointed at the 14z-99 window freeze (D/H/P -> `don_m9`/`hui45`/
`pyron29`); the standing rule remains: re-point a tenant's row whenever
it is re-frozen** (the m5_wide/pyron21 pins this paragraph used to warn
about were retired then).
`build/m3b_merged7` is superseded and was the build the #75 abort was
measured on. Superseded merged intermediates (m3b_merged4/5, pre-v1.1)
do not boot on current binaries without member injection. The pre-fix
`build/m3b_merged` (FG) and `build/hui34`/`hui36` (chirp/shock) are
kept as the parity audits' known-bad references (same injection
caveat). Rebuild: `ROMDIR=... tools/build_merged.sh build/m3b_merged11`
**— and that is now genuinely ONE COMMAND from a clean checkout (14z-95,
GitHub #27, maintainer-ruled).** It used to require three untracked
`build/*/extract` dirs plus `build/wide0` that NOTHING IN THE TREE KNEW HOW
TO MAKE — the recipe was this file's prose and an `echo` on
`audit_merged_legacy`'s SKIP path — so rule 3 was false for the milestone
deliverable. `tools/ensure_merged_inputs.sh` now produces whatever is
absent and touches nothing that exists (create-if-absent, so it does not
collide with #26's guard on the same dirs). Measured before landing: a
regenerated input set yields a BYTE-IDENTICAL merged `patch.json` (752
ops, same order) and a byte-identical WIDE overlay (21/21 members).
(~1 min, 753-op fixture); its fingerprint moves with the generator — do
not pin it.
**#75 CLOSED 14z-92, and read the second half of that sentence:** the
huitzil gfx-verify abort was a VERIFIER artifact (obj_records.walk's
pointer pass re-derived record structure from the relocated image, and
the merged placement window happened to contain a straddled datum's
value). Fixed + gated. **But the abort had already stopped happening on
its own**: 14z-91 moved `anim@huitzil` 0x41a7e0 → 0x41a6e0 and the
coincidence dissolved, so merged8 verifies green with the PRE-FIX tool
too (measured, all three tenants). Nobody knew because nobody re-ran
`build_merged.sh` after 14z-91. The fix removes the dice roll, not
today's instance of it.
`build/merged1` is the **MERGED-LEGACY INSTRUMENT** (14z-81; carries the
14z-82 type-renumber + F2 fixes) — the 3-tenant program image with gfx
SKIPPED (group C zero-filled): legacy characters render correctly, the
tenants draw BLANKS by design. **Never playtest it, never give it a
registry row** (its own `README-LEGACY-ONLY.txt` says why); it is rebuilt
from scratch by every `tests/audit_merged_legacy.sh` run, so its
fingerprint moves with the generator — do not pin it in docs. Rebuild the
pair with:

## From HANDOFF.md: «THE PRE-COMMIT COMMAND — what the runner reports, and THE MUST-FIRE CONTRACT ([VSP-181])»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

**One command, every gate that does not need an emulator.** Until 14z-94 there
was no CI and no aggregator, and 101 of 130 test scripts had no shell caller —
so running the reproducibility gate depended on somebody remembering its
filename. What that cost, measured: `test_dualtrack.sh` sat RED for 11 days
(GitHub #95) while CLAUDE.md §4 cited it as one of FBNeo's three guarantees.

It reports **PASS / SKIP / FAIL separately, because SKIP is not PASS**
(GitHub #29): a gate whose build dir is absent prints `SKIP:` and exits 0, and
counting that as a pass is how a fresh checkout reports green while asserting
nothing. `--strict` makes skips fatal.

It also prints a **registry-coverage check** — any emulator-free gate in
neither `tests/ci_portable.txt` nor `tests/ci_static.txt` is named. That check
is the anti-orphan mechanism; without it the runner would just become a
smaller thing to forget to update. Its classifier is TRANSITIVE (follows
`tests/lib/*.sh` sources), because two gates reach an emulator indirectly and
were mis-registered on the first pass.

Emulator gates, soaks and one-off rigs are deliberately NOT here — they have
their own runner since 14z-128 (below). This is also not `run_battery_m2.sh`,
which builds a ROM and is the stage-6 dev-build chain.

Ground truth for the runner itself: `tests/test_static_runner.sh`. **Its
verdict classifier is `tests/lib/classify.sh` (14z-139), THE ONE copy that
`run_all_emulator.sh` and `run_battery_m2.sh` source too** — until then the
static runner and the battery read an exit-0 shell crash ([VSP-176]) as PASS
while the sweep read it as FAIL.

**[VSP-181]** **THE MUST-FIRE CONTRACT (14z-147, step two of the maintainer's
ruling on the BBX finding — spec of record `docs/project/must_fire_contract.md`,
the tree's COPY of BBX's R10/R29/R30, independent but compatible): a control is
DECLARED in the gate's leading comment block as `# MUST-FIRE: <shape>: <name> —
<what must fail>` (shape `perturbed-copy` | `shadow-tool` | `known-bad`, a bare
`#` continues the block; `# MUST-FIRE: none — <why>` for a gate that asserts no
property); FIRED at run time as `CONTROL FIRED: <name> — <evidence>` or
`CONTROL DEAD: <name> — <what happened>` at column 0; and EXECUTABLE as a
mode — `CONTROL=<name> tests/<gate>.sh` applies the perturbation to the REAL
input and must reach the gate's own FAIL (exit 0 is LIES, a `REFUSED:` line
with exit 3 is a dead mode, a crash is DIED).** Every runner hands
`vs_classify` the gate script, and a declared control that did not fire, a
DEAD line or a firing no header declares is plain FAIL — no fourth verdict.
`tests/run_all_static.sh` executes every declared control after a PASS
(`--exec-controls all|portable|none`) and prints `fired N / declared N` plus
the executed tally; `run_all_emulator.sh` reads every block and executes under
`--controls` (rows `<gate>@<name>`). The reader is `tests/lib/controls.sh`
(ground truth `tests/test_controls_contract.sh`); the retrofit's status is the
census's three frozen classes (`declares` grows only, `header-only` and
`retrofit-debt` shrink only). Write each perturbation as ONE function the
control section and the mode both call, so what the mode proves is what the
control claims.

## From HANDOFF.md: «THE EMULATOR-TIER COMMAND — what it costs, and the registry's columns (scope, ondemand, cadence, timeout, prereq, args)»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

**WHAT THE RELEASE RUN COSTS, MEASURED (14z-153, 2026-09-14, this MacBook,
`--jobs 4`, the M18 build set):** `--scope all --lane all --strict --controls`
took **5 h 37 min** wall — 172 gates and 39 control runs, PASS 210 / SKIP 1 (the
approved `audit_mask_window_ff42a2`) / FAIL 0. Serially that is 13.6 h of gate
time plus **4.5 h for the controls (+33%)**, and **90% of the controls' cost is
the four Verilator gates**, where each control is a full re-run of its gate; the
MAME lane's 30 controls cost 15 min in all, because several stop at their first
perturbed input (`audit_guard_corpus@known-crash` 21 s against its gate's
1,830 s). Rows: `build/emu_controls_14z153/results.tsv`.

*(Moved 2026-10-14, #282 item B: THE EMULATOR-TIER COMMAND — measured runs on ERIS and PILOT → `docs/project/operations.md`.)*

**The registry is `tests/ci_emulator.tsv`** — one row per emulator-tier gate:
`gate / lane / scope / cadence / args / note` (173 rows at 14z-157; 163 when
`audit_type_dispatch_range` was dropped 14z-129). Completeness is enforced BOTH WAYS on
every run (an emulator-tier script with no row is UNREGISTERED, a row whose
script is gone is DEAD), with the same transitive classifier
`run_all_static.sh` uses, so a gate cannot fall between the two runners.

**Why it exists, measured at the 14z-127 close and re-derived by the runner
itself: 164 emulator-tier gates, 32 reachable from any runner, 132 reachable
only by typing a filename.** That was survivable while the tier was a
development instrument; it stopped being survivable when the maintainer ruled
that at release ALL tests run and *"anything red, anything skipped is a hard
fail"* (STATE "RELEASE-TIME TEST SCOPE"). A policy of "all tests" cannot
operate over a set nobody enumerates.

**`scope` is the release decision and the CLASSIFICATION IS RULED
(maintainer, 2026-09-03) — 141 release, 23 out** at the ruling (145 / 28 at 14z-157): `release` = the gate's subject is the
released artifact, legacy content inside it included (an oracle leg on `vsav2`
or pristine `vsavj` is a REFERENCE, not the subject); `out` = out of release
scope, and every `out` row leads with its reason keyword — `romset:`,
`platform:`, `momentary:` or `dev-ladder:`. **`out` never means "do not run":**
`--scope all` runs them, and the sweep is how they are kept honest. **And `out`
means NEITHER "resolved" NOR "quietly green"** (both affirmed by the maintainer
at the ruling): `audit_hitclass_map_cost` is `out` AND is one of the two dead
must-fire controls, and two `out` rows are red right now with exact diagnoses.

**`ondemand` is the third scope (maintainer-ruled 2026-10-09, 14z-196: *"let's
make it purely ondemand scope and document how this ondemand scope can be
run"*).** A row is `ondemand` when its subject is PRISTINE content only —
`vsavj`, `vsav2` from `$ROMDIR`, no Vampire Saved build on any leg — so no
change of ours can move its verdict. No tier selects it: not the static tier,
not the close, not `--freeze`, not the release run (`--scope all` skips it).
It runs only when named: `--scope ondemand`, alone or with `--only '<glob>'`,
and every other flag works as for any run. Its reason keyword is `pristine:`
(`tests/test_emulator_runner.sh` §6a holds both rules, control
`ondemand-in-all`), and the staleness audit never judges an `ondemand` row
(`tests/test_emulator_staleness.sh` §2d2, control `ondemand-judged`). **The
exception, in the maintainer's words:** *"The only potential exception I can
imagine of pristine-only gates that shouldn't be ondemand scope are for cases
that are known to have been broken in the past (e.g. maybe we made a change
for a VS2 tenant that affected vsavj characters: that would qualify for being
at least on release)"* — such a gate stays `release`. Which rows are
`ondemand` is the registry's to say (`awk -F'\t' '$3=="ondemand"'
tests/ci_emulator.tsv`), not this page's. The ruling of record is
DECISIONS_HISTORY.md "Ruled 2026-10-09 (14z-196) — #118's gates and every
pristine-only gate move to an ONDEMAND scope".

**`cadence` is a DIFFERENT question from scope — what moving thing the gate
FOLLOWS** (ruled 2026-09-03). `romset` (158 rows at the ruling, 168 at 14z-157) = runs at every freeze and
every release. `bitstream` (6 rows at the ruling, 5 at 14z-157, all MiSTer) = its subject is the core, which
moves on its own cadence — the `.rbf` has not moved since 14z-108 while the
romset moved many times — so it runs at every RELEASE and at a freeze ONLY when
the freeze targets MiSTer. **`--freeze` (= `--cadence romset`) drops them and
NAMES them**, so the "should this freeze include them?" question is asked by the
runner instead of remembered. `test_mister_sdram_census` and
`test_mister_gfxc_fetch` are deliberate exceptions: they measure where THIS
ROMSET lands in SDRAM, so they follow the romset. Only a `mister` row may be
`bitstream`, enforced, so the concept cannot spread by column edit.

**A row's optional 7th column is the gate's OWN timeout in seconds (14z-134)**,
overriding `--timeout` (default 90 min): the M16 release run killed two
3-hour Verilator gates at the one-size cap while their notes said "~93 min a
leg" in prose. Set it from a MEASURED runtime × MORE THAN 2, rounded up to the hour (the HEADROOM rule: a row at half its cap FAILS `test_emulator_staleness`; × ~1.5 until 14z-185). **And the MiSTer lane is
PARALLEL by scratch clone**: `--jobs N` hands slot 0 the base `JTSIM_SCRATCH`
and slot N `<base>-slotN` (provisioned at the pin on first use, ~3 min for the
Verilator build); the three two-leg gates run their legs at once on
`<scratch>` and `<scratch>-b` (`MISTER_LEGS=serial` for one clone). One
simulation is one core and ~100 MB; the lane that took ~11 h serial fits in
~3 h at four jobs. Ground truth: `test_emulator_runner.sh` §13.

**The `prereq` lane runs first, sequentially, and a red there STOPS the run.**
Those gates measure the INSTRUMENTS, and a measurement taken after a moved
instrument is not evidence ([CPE-24] — `test_mame_parity.sh` is the case that
named the rule). `--keep-going` overrides.

**`args` defaults to `-`, the gate's OWN defaults, deliberately.** What a
release run would actually hit is what the sweep must measure — a path-named
default is a dated assertion with no expiry ([VSP-95]). A row is given explicit
arguments only once a triage has established what the gate should measure, and
the `%MERGED% %MERGED_RP% %DON% %HUI% %PYR% %STOCK%` placeholders expand to the
build set under test (env-overridable; the run prints each build's FINGERPRINT,
never just its name).

Ground truth for this runner: `tests/test_emulator_runner.sh` (ROM-free, in
`ci_portable`) — the three verdicts counted separately, SKIP-in-prose,
MISSING, TIMEOUT, both anti-orphan directions, `--strict`, the prereq stop,
scope selection, lane accumulation and placeholder expansion.

## From HANDOFF.md: «Build registry — the two rows that are not builds, and the table's narratives»

*(Moved verbatim from HANDOFF.md 2026-10-14, #282 item B.)*

**TWO REGISTRY ROWS ARE NOT BUILDS** (14z-97, GitHub #96; RATIFIED by the
maintainer 2026-09-15): the M2 battery's two legs, the stock twin
(`donovan-mN-stock`) and the stage-4 image (`donovan-mN-stage4`) — today
`donovan-m24-stock` (`67fdc4de`, MOVED by the 14z-183 M20 freeze) and
`donovan-m23-stage4` (`2fa7c2f1`, UNCHANGED since the 14z-170 M19 freeze,
which moved both — the `donovan-m19-*` pair, `e86e1d04` / `108f7523`, had
carried unchanged by rebuild through the 14z-132, 14z-143 and 14z-144
freezes). They are
registered so the battery can dispatch on the fingerprint instead of a pinned
set name — an unregistered image there means the pipeline no longer reproduces
the current freeze, which is the rule-6 signal the maintainer's ruling asks
for. Neither is playtested, neither is a shipping artifact, neither is tagged;
each freeze rebuilds both and records whether they MOVED (superseded rows stay
in the TSV as history, annotated). Until 14z-157 this paragraph named the m9
rows as current and called the practice unratified in effect; the ruling is
`DECISIONS_HISTORY.md` "Ruled 2026-09-15 (14z-157)".
Their expectation sets are BATTERY-SCOPED and say so in their own READMEs.

**The registry is a TABLE; each row's narrative (what the freeze changed,
how it was measured, what it superseded) is verbatim in `HANDOFF_HISTORY.md`
"Build registry narratives" and in the matching `docs/project/patch_notes.md`
entry and STATE close. Newest first; the top row is the CURRENT freeze.**
