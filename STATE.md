# STATE — living progress log

**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved): this
file holds the RECENT session groups + THE LEDGER; the full detail of every
older session lives verbatim in `STATE_HISTORY.md`.** How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md — section names are preserved verbatim in the archive.
  A reference to `STATE "Decisions pending"` for an entry no longer here
  resolves in `DECISIONS_HISTORY.md` (entries move there verbatim once
  ruled and no longer shaping work — 14z-109 cleanup).
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below its header) and append their one-line
  entries to THE LEDGER below, composed from the group's own banner
  headers. If this file still exceeds ~150 KB, roll the oldest kept group
  early. Standing sections at the bottom of this file (decisions pending,
  the deadness register, open bugs, findings log) are CURRENT STATE — they
  never roll to STATE_HISTORY; entries within them are marked DECIDED/FIXED
  in place, as always. **DECISIONS have their own archive since 14z-109:
  once a ruled decision stops shaping active work, its entry moves
  VERBATIM to `DECISIONS_HISTORY.md`** (grep there by topic; the §5
  retraction grep covers it).

## Session 14z-142 — **L3 LANDED IN ONE SITTING, AND WITH IT THE WHOLE LIVING-DOCUMENTATION EFFORT: the atlas's
## ROM claims are now re-derived from all three decrypted images. The census corrected the execution plan SIX times
## — the denominator was wrong by a hundred, and an atlas "quoted instruction" turned out to be a semantic
## PARAPHRASE. The checker found an unstated exception in a table the atlas has described since M1; the tier run
## found a defect of mine that 14z-141 had already shipped once; and the crypt-view trap was paid AGAIN.
## No build byte moved.**

| | |
|---|---|
| opened with | the opener read (CLAUDE.md, STATE, HANDOFF, `docs/NEXT_SESSION.md`), the ROM audit **76/76**, the skill `vampire-saved-port`, then `living_docs_scope.md` §4/§6 and the execution plan `build/living_docs_plan_14z139.md` §0 and §4. The maintainer's word was **"L3"** |
| **(1) BEAT 1 — MEASURE, and it corrected the plan six times** | A throwaway census importing `gen_annotations.collect()`, not a reading of the scope document. **The denominator is 346, not ~440**: the atlas carries 473 addresses and `ram.md` carries **150** of them, 127 exclusively — the plan's "~30" counted `ram.md`'s `PRG:0x`-FORM tokens (measured, exactly 30) instead of its rows, because the atlas writes most addresses bare. Those 127 are PROGRAM addresses in a RAM document (the PC-attributed writers of RAM fields), and since `gen_annotations` bounds every row to `0x001000-0x3FFFFF`, the plan's RAM and OUTSIDE buckets for `--uncovered` are **empty by construction**. The atlas's spine is a THREE-SET comparison — 41 sibling addresses, 50 table rows carrying two or more — so the plan's "siblings SKIP their half" would have left its largest table unchecked, and `decrypt_view` turns out to be set-generic, so all three cost nothing. Environment: capstone 5.0.7, all three sets cached |
| **the finding that decides whether the tool is trustworthy** | **An atlas "quoted instruction" may be a SEMANTIC PARAPHRASE and the document still correct.** `character_tables.md:173` renders the palette blitter as `move.l (a0)+,(a1); or.l #$F000F000`; the image holds `or.l d0,(a1)+` with `move.l #$f000f000,d0` two instructions earlier. A word compare on that text would report correct documentation as stale — which is how a checker teaches its reader to ignore it. Hence the declared PARAPHRASE class |
| **and why the checks must be hand-written** | Of the 36 instruction spans in the atlas ROM tier, **exactly ONE sits in a paragraph naming exactly one address and 27 name none** — the atlas pairs instruction to address in PROSE. No census can seed the checks, and no later session may grow coverage automatically from one. Also measured: seed check 3 as specified is impossible (the watchdog has no address in the atlas; it occurs **53 times** in vsavj and 53 in vsav2 for its own constant) |
| **the premise, proven before it was written up** | All three opcode-view SHA-1s in `atlas/README.md` reproduce EXACTLY — the document SAID of them *"it has no second home in the tree, so this is the only place it is checked"* — a sentence amended at the landing to name the gate, with the check quoting the new wording. Three transcribed instructions decode byte-exact at the addresses the atlas names, `cmpi.b #$2,$382(a6)` = `0C2E 0002 0382`, exactly the encoding the plan predicted for the no-capstone design |
| **(2) BEAT 2 + THE STOP — all four open decisions ruled the same sitting** | §11 written in the §9/§10 form (commit `3336e10c`), then **RULED (maintainer, 2026-09-07), each as recommended:** all three reference sets REQUIRED; `PARAPHRASE` a declared, printed class, the documentation not edited to suit the tool; the denominator **346**; NOTE now, freeze the covered set at the atlas-tier close. Decisions 1, 4 and 7 were stated as defaults and not vetoed — recorded as that, not as rulings. The NOTE class was not reopened: L2 ruled it and L3 reuses it unchanged |
| **(3) THE FRAMEWORK SHIPPED** | `tools/checkdocs_rom.py` — `Image`/`SETS`/`says()`/`@check`/`@table`/`PARAPHRASE`/`UNENCODABLE`, seed checks 1-8 — and `tests/test_checkdocs_rom.sh` (ci_static, family `docs`, ~2 s warm / ~35 s cold), registered both ways. **8 checks, 8 ok, 9 table controls fired, `NOTE: checkdocs_rom.coverage 13/346`.** Every check QUOTES its claim and DERIVES the fact, so a reworded document is a STALE verdict rather than a silent pass |
| **AND IT FOUND SOMETHING ON ITS FIRST RUN** | `id_space.md` has said since M1 that the `PRG:0x04FFA8` table holds "values `0x0370-0x03D7`". Measured: true of fifteen rows, **false of slot `0x8`**, which carries its own `0x02A5-0x02AD` block — the same slot that is the variant-alias exception in `character_tables.md` (Bishamon). And row `0x0B`'s 24 bytes are a byte copy of row `0x4`'s: the gap slot the random-select table also skips holds Zabel's numbers, not data of its own. Neither was written down. **The atlas was corrected FIRST, in its own commit, and the check asserts the corrected claim** — never the document bent to match a tool |
| **the first green proved falsifiable before it was believed** | The tool passes everything on a clean tree, so [VSP-19] says its first green states nothing. All four controls fire on a perturbed COPY, each proven to have applied first: a reworded claim → `Stale`; one flipped byte at `PRG:0x028DD8` → `Mismatch` (the check reads the ROM, not the doc); the PARAPHRASE claim's LITERAL fact perturbed → `Mismatch` (the declared class cannot decay into a silent skip); a validator weakened to `lambda v,i: True` → `Vacuous`. Exit statuses read directly, not through a pipe |
| **docs** | two gotchas appended and indexed — a classifier over PROSE matches English words as opcodes (`OR`, `NOT`, `tst`: the first yield census was worthless and looked reasonable), and `\|` is a LITERAL PIPE to `grep -E`, which made six present claims read as missing. `id_space.md` corrected; `living_docs_scope.md` §4's L3 row and §11's STATUS brought to the measured figures; HANDOFF gains a "What exists" row and a routing-table row; `annotations.md` regenerated in the same commit each time (the new tool and the atlas edit both move it) |
| **and the tier run found a defect of mine — the same one 14z-141 shipped** | The first full static run came back GREEN with the NOTE block listing only the rule-5 numbers: `test_checkdocs_rom`'s coverage line was **absent**. The TOOL emits at column 0, but the GATE captures the tool's output to a file, asserts `^NOTE: ` inside that file, and reports it as `  ok   NOTE: …` — indented, so the runner's `^NOTE: ` grep never sees it. I had read both the gotcha and `NEXT_SESSION`'s line quoting it (*"Emit at column 0 or the runner cannot see it — that mistake shipped once already"*) at this opener, and still wrote it, because the earlier fix is remembered as being about the TOOL's output when the boundary that matters is the GATE's. Fixed (`echo "$note"` at column 0); the 14z-141 gotcha gained the repeat and its sharper rule — **a gate that captures a tool's output has taken the note off the wire and must put it back**. What caught it, both times, was reading the runner's own NOTE block after a REAL tier run rather than the gate's exit status |
| **(4) SEED CHECKS 9-15, and the crypt-view trap paid AGAIN** | The attract table at `PRG:0x005C08` read out of the DATA view as `9F F7 59 84…` against `id_space.md`'s documented `P1 0F 02 0C 0E…` — which reads exactly like a stale document and is not. **Inside the crypt range the VIEW follows the ACCESS MODE:** that table is PC-relative (`move.b $5c08(pc,d0.w)`) so its truth is the OPCODE image at stride 4, while `select_screen.md`'s tables A and B, two hundred bytes away, are `(An,Dn)` DATA reads. Neither wrong reading announces itself — both return plausible bytes. `select_screen.md` states the rule directly above its own tables and I still hit it, because the reading happened in a different document. **[VSP-155] settled it in one command**: `test_attract_roster.sh` already decodes that table, and the view IT opens was the answer — along with the stride, which my first reading also had wrong. Gotcha appended |
| **(4) what the checks now hold** | 15 checks over all three images: the three opcode-view digests; the watchdog constants; the blitter PARAPHRASE; the loader's immediates (which must EQUAL the table addresses documented below them, so the two claims verify each other); the three per-set table bases and the struct+0x64 / +0x132 tables; the variant-half alias with its slot-8 exception; both id-cycling selectors plus vsav2's `#$1f` twins; the `0x04FFA8` anim table; the attract roster; the two id writers; table A's sixteen bytes **parsed out of the document's own text**; table B; the drawer in all three sets with the dispatch target DERIVED from the PC-relative instruction; the venue pointer table; and the mugshot/name tables with the stager's `lea` resolved. **15 ok, 12 table controls, `NOTE: checkdocs_rom.coverage 30/346`.** One mismatch on the way was mine — `(a4)` encodes `0x102C`, not `0x1028` — and the tool caught it |
| **(5) THE FROZEN COVERED SET, and the multiset defect arrived independently** | `tests/expected/checkdocs_rom_covered.tsv` (31 rows: check, document, address) with its `PROVENANCE.md` row, evidence class `derived`. **The first `--check-covered` compared by LIST MEMBERSHIP, so a duplicated frozen row passed in silence** — the exact defect `audit_rule5.py` shipped at 14z-141, reached here by a different route. Now a `collections.Counter` difference both ways, where a duplicate is itself the signal that the file was hand-edited. **And my first attempt at its control was invalid twice over**: it named an address the venue check genuinely covers, and then `grep file >> file` appended nothing at all (44 lines before and after). The control only became evidence once the perturbation was asserted — the rule the plan already carries |
| **(6) `--uncovered`, and decision 4's fourth bucket** | Per document, sibling addresses starred: `character_tables.md` 129 uncovered, `select_screen.md` 124, `id_space.md` 34, `ram.md` 19 (addresses it shares with a ROM-tier document), `README.md` 3. Those three README rows are `0x0F1234`, `0x01A2B3` and `0x0FFFFF` — the address-NOTATION EXAMPLES and the crypt-range boundary, not data. They are now a declared `NOT_ADDRESSES` list, printed and labelled, and deliberately **kept inside the ruled 346** so a documentation refinement cannot silently move a number the maintainer ruled |
| **(7) the retraction pass** | [VSP-13] on the two claims this slice retires. S1 (§2.3 "No tool re-derives an atlas claim from the decrypted image") reworded. **S4 is the interesting one: `atlas/README.md`'s "this is the only place it is checked" is a sentence my own check QUOTES**, so the document and the check had to move in one commit — the README now names `tests/test_checkdocs_rom.sh` and the check quotes the amended wording. Re-grep shown: every surviving instance is a marked historical quotation (`SAID of`), including the two in the tool's and the gate's own headers |
| **CLOSE** | ROM audit **76/76** at the opener. The eight doc checks green after every doc edit, exit statuses captured directly. **Static tier ALONE, `--strict`, THREE times**: 141/0/0 GREEN (`build/static_14z142_close.log`) — the run that surfaced the missing NOTE; 141/0/0 GREEN after that fix (`_close2.log`), whose advisory block carried the coverage number for the first time; and **141/0/0 GREEN** after step 3 (`_close3.log`), whose advisory block reads `test_checkdocs_rom  checkdocs_rom.coverage 30/346 atlas ROM-tier addresses`. Tree clean during every one, nothing edited while any ran. 141 = 14z-141's 140 + this gate. STATE **rolled early** (153.7 KB): the 14z-140 group verbatim to `STATE_HISTORY.md` with its LEDGER line. **L3 LANDED, and with it the living-documentation effort in all four forms** — routing enforced (L1), the corpus rendered (L4), the fact census frozen (L2), the atlas's ROM claims re-derived (L3). **No build byte moved.** Committed to main, NOT pushed (the maintainer's word, as always) |

## Session 14z-141 — **THE SITE'S `<header>` WAS NEVER CLOSED — THE MAINTAINER FOUND IT BY OPENING THE PAGE —
## AND L2 THE RULE-5 CENSUS LANDED THE SAME SITTING: 15 of 217 gameplay values IN-TABLE, the BAKED inventory
## frozen, the NOTE class shipped in BOTH trees, and the first migration proven end to end. Every gate in this
## session was corrected by RUNNING it; four of the defects were mine. No build byte moved.**

| | |
|---|---|
| opened with | the opener read (CLAUDE.md, STATE, HANDOFF, `docs/NEXT_SESSION.md` — which lives at `docs/`, not `docs/project/`), the ROM audit **76/76**, then `living_docs_scope.md` and the execution plan `build/living_docs_plan_14z139.md`. The maintainer's first question was where to run `mk_docs_site.py` from |
| **(1) THE SITE BUG — found by the maintainer, not by a gate** | The answer to "which root?" was the repo root; the site was complete (84 files) and gitignored by design, but `--verify` found it **two minutes stale** (rendered 18:14; `NEXT_SESSION.md` committed 18:16). Re-rendered. Then the maintainer opened it and reported the nav rendering as a vertically-centred LEFT COLUMN, invisible except mid-page. **CAUSE: `page_html` emitted `<header class="top">` and never closed it**, on all 82 pages — the browser closes it at `</body>`, so `.wrap` (the whole document) became a flex item of a sticky `display:flex; align-items:center` bar as tall as the page it contained. **WHY NO GATE SAW IT: every check in `test_docs_site.sh` reads the page as TEXT** — `--check` parses the markdown, the href walk resolves links, the network check reads origins, determinism compares bytes. A page with an unclosed tag is perfectly deterministic and self-consistent. Nothing was reading the STRUCTURE. Fix + section 9 (a stack-based tag balance over the rendered tree, `html.parser` reading `<script>` as CDATA) + a must-fire control stripping one `</header>` from a copy of the real output; it fires with `index.html: <header> is never closed (</body> closed it)`. Commit `e60acf3a` |
| **(2) L2 BEAT 1 — MEASURE, and the plan was wrong five times** | The canon is **31 tracked files, 29 after the ruled EXCLUDE**; the plan's list misses four JSONs in SUBDIRECTORIES, one of which (`overlay.wip/overlay_tiles.json`, 10,110 scalars) is **48% of the pre-exclude census and INERT** — `2b8fd827` renamed `overlay/` at the 14s revert and `build_donovan.sh:466` still guards the old path ([VSP-14] archaeology before theory). The plan's kind census is TREE-WIDE (the untracked `probe_*.toml` inflate six of nine kinds). **Provenance is attached to PARAGRAPHS, not values: 4,566 standalone comment lines against 237 trailing** — the plan's own figures came from that blind instrument, and so did my first scan (it read `measured` as 0 where the count is 211). **The GAMEPLAY seed names keys that do not exist**: 1 of 389 pairs has a behavioural name, `[[move]]` is an IDENTITY record, and damage/timing/meter travel as ROM DATA REGIONS |
| **the correction that changed a ruling** | I framed the gameplay column as "near-empty by construction" and the maintainer accepted it *unless it creates a risk*. It was too strong: rule 5's fourth category is VARIANT SELECTION, and **`only_variant_slot` appears 151 times across the three shipping manifests** — the superset invariant expressed per row, and a BOOLEAN, so a numeric-literal census would have skipped it entirely. That IS the risk, and it was corrected before the ruling stood |
| **(2) THE STOP — five decisions, all ruled 2026-09-07** | (1) `overlay.wip` OUT by explicit EXCLUDE; (2) the gameplay column INCLUDES variant selection and booleans are in scope; (3) MEASURE the comment-block shapes before choosing the attribution rule; (4) the `code` column counts module-level constants, blind spot stated; (5) the NOTE class approved. Written up as `living_docs_scope.md` §10; commit `c0dfefb4` |
| **ruling (3) paid off immediately** | Measured: 350 blocks — 43.7% tight above a table header, 19.7% inside a table, 9.4% GAPPED. Reading all 33 gapped ones settles them: they are **SECTION BANNERS** (`---- specials ----`), so they attach to the SECTION, never the one table beneath — a better rule than either option I had framed. And it surfaced the trap: some blocks are **RETRACTIONS** (`RETIRED 14z-91`, `NEVER APPLIED`, `REVERT`). Attaching "the block above" blindly would hand a live row the provenance of a withdrawn one — [VSP-13]'s failure mode inside a tool |
| **(3) L2 EXECUTED** (commit `b7b342ec`) | `tools/audit_rule5.py`, `tests/expected/rule5_baked.tsv` (232 rows), `tests/test_rule5_census.sh` (ci_portable, ~6 s, six must-fire controls + one no-fire), `docs/project/tables/rule5_ledger.md` and `select_wheel.md` with their shape rows and README lines. **MEASURED: gameplay 15 IN-TABLE / 202 BAKED of 217; fact 511 derived / 7,812 baked of 8,323; code 30 baked; UNCLASSIFIED 0** |
| **THE FIRST MIGRATION, option B** | Ruled by the maintainer after asking what "migration" meant: the value STAYS in the manifest and gains a documented table row plus a pointer, checked so the two cannot drift — **a documentation edit can never move a shipped ROM byte** (option A, the build reading the table, was declined and is not foreclosed). Executed on the select wheel's **five INBOUND edges**, the only wheel bytes written over LEGACY content, each row citing the 2026-08-05 "vanilla wins ties" ruling. The frozen inventory did NOT grow — the 15 went straight to IN-TABLE. `test_m3a_reproducible` PASS (304 s) proves the `_in_table` keys are byte-neutral |
| **five things execution changed** | IN-TABLE is POINTER-DRIVEN (a value-matching pass returned 19 gameplay rows IN-TABLE and **all nineteen were false positives** — key `R` matches any row containing an `r`); the FROZEN inventory is gameplay+code only (freezing `fact` made it 8,059 rows that ordinary port work adds to every session — a shrink-only signal firing every commit is not a signal); `KNOWN_PAIRS` (389 measured pairs) restores the UNCLASSIFIED tripwire, without which a manifest gaining `damage = 12` passes in SILENCE; `probe_*.toml` excluded by GLOB not by `git ls-files`, because under `--root` the canon falls back to a filesystem walk; and the NOTE class shipped in BOTH trees |
| **four defects of mine, every one caught by RUNNING it** | `--check` diffed by SET while comparing by LIST, so a new row identical to an existing one exited 1 in **silence** (the inventory is a MULTISET); two `continue` branches never consumed a line and HUNG the selftests — the `md_subset` defect of 14z-140 repeated, and the guard I added sat where every `continue` skips it, so it is now at the TOP of the loop and proven live by re-introducing the bug in a copy; the NOTE must-NOT-fire control matched the gate's own RESULT ROW rather than the block; and **the worst, which only a real tier run could show — the first live run printed `(none)` while the gate PASSED**, because the gate reported its numbers indented inside its own output where the runner's `^NOTE: ` grep never looks |
| **the fidelity contract did its job** | `test_bbh_fidelity` F1 went RED: it demands this tree's `run_all_static.sh` and the harness's `bbh run-static` be IDENTICAL, and the NOTE block existed only here. A NOTE-class advisory passes the harness's own extraction question, so it was **MIRRORED** into `bbh` (`b4852e5`, its gates GREEN 30/2/0) rather than re-baselined into a permanent delta |
| **recorded for the maintainer, unresolved** | **`PRG:0x028D50` carries THREE names** — `effect_map_5051` (huitzil.toml), `hit_class_props_ext_hi/_lo` (donovan.toml), and the guard-MASH RNG mask table (`ram.md:156`, the community's "Tech-Hit Chance Tables"). The band is classified GAMEPLAY conservatively and the conflict written into the tool; which name is right needs measurement on a gameplay surface, so it is the maintainer's ([VSP-10]) |
| **CLOSE** | ROM audit **76/76** at the opener. Static tier ALONE, `--strict`, three times (two runs were spent: one KILLED by the OS for low memory — its `test_bbh_fidelity FAIL (exit 143)` is SIGTERM, not a red, and it produced no verdict line; one NOT GREEN on the fidelity red above). Final: **PASS 140 / SKIP 0 / FAIL 0 GREEN** (`build/static_14z141_L2b.log`), tree clean during the run, and the NOTE block verified live in a real tier run. The eight doc checks green after every doc edit, exit statuses captured directly. Five gotchas appended and indexed. S1 CLOSED (`tables/README.md` no longer claims "Nothing gameplay-affecting hides in code or manifests" — never checked, and measured, not true); S3 and §4's option-A wording corrected in place. **No build byte moved.** Three commits here + one in the harness, ALL PUSHED at the maintainer's word |

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

- Session 14z-140 CLOSE — **THE LIVING DOCS EFFORT OPENS AND ITS FIRST TWO SLICES LAND: L1 ROUTING ENFORCEMENT and L4 THE RENDERED SITE.** The map now REACHES every declared document, a history twin must be two-way, and the whole corpus renders as 80 cross-linked pages with an address index over every carrier. Both censuses disagreed with the scope document, and five of L4's six structural findings were absent from the plan. No build byte moved; static 139/0/0  [rolled 14z-142 close, early — STATE was 153.7 KB]
- Session 14z-139 CLOSE — **THE FOUR RECORDED-NOT-FIXED FINDINGS ABOUT THIS TREE, FIXED** (the maintainer's "let's start with" them): ONE verdict classifier `tests/lib/classify.sh` for the three runners, the enumerator's `.diverge` case, the ref-rot gate's image pick NAMED instead of inherited from the filesystem. Then THE EIGHT DEFAULTS of `harness_scope.md` §7 RULED, and THE HARNESS SKILL `blackbox-harness` LANDED (87 rules, H10 the lifted lock, F11 exact, installed as a symlink). Closed by writing THE LIVING DOCS EXECUTION PLAN for another session to execute. No build byte moved; static 137/0/0  [rolled 14z-140 close, early — STATE was 152.7 KB]  [+3 more entries]
- Session 14z-138 CLOSE — **SLICES H6 AND H9 LANDED: the MAME Lua layer under a MACHINE PROFILE, the real drivers and the recording corpus — with FIDELITY F8 EXACT on the real emulators — and the ONE gate this tree gains, green on its first full run** (the maintainer's "do h6 then h9"). Then H6b, THE DEFAULTS CENSUS over the Lua layer: three board facts still hiding as literals, five policy constants that were neither profile nor config nor env, `read_tap.lua`'s `FRAMES` default of 5450 (one lineage replay's length), and the one that reached the EXAMPLE — `[machine].profile` defaulted to `cps2`, so a board is never implied now. No build byte moved; static 136/0/0  [rolled 14z-140 close, early — STATE was 155.9 KB]  [+4 more entries]
- Session 14z-137 CLOSE — **SLICES H5 AND H7 LANDED: the hygiene bin (provenance, header defaults, reference rot, the gate index, shadow tools, the accounting rule) and the field comparator + dump checker — with FIDELITY F9 AND F10 EXACT** (the maintainer's "H5 then H7, in that order"). No build byte moved.  [rolled 14z-139 close, early — STATE was 154 KB]
- Session 14z-136 CLOSE — **SLICES H3 AND H4 LANDED: the fingerprint, the suite runner, THE DRIVER CONTRACT, THE FAKE MACHINE and THE SWEEP RUNNER — with FIDELITY F4, F6 AND F7 EXACT** (the maintainer's "start as planned", then "continue" at 46% context); two findings about this tree recorded, not fixed (no `diverge` case in `enumerate_expectations.sh`; the `$( … )`-under-`set -e` capture trap). No build byte moved; static 135/0/0 twice  [rolled 14z-138 close, early — STATE was 148.8 KB]
- Session 14z-135b CLOSE — **SLICE H2 LANDED: the comparison classes and the masked vocabulary, with FIDELITY F5 EXACT over all 1,891 masked specs** (the continuation, at the maintainer's "continue then" from 49% context); the harness PUSHED TO GITHUB at the maintainer's word (public, `DefinitelyFrenchName/blackbox-harness`), pushing it standing-authorised since; H3 deliberately left for a fresh window. No build byte moved; static 135/0/0  [rolled 14z-138 close]
- Session 14z-135 CLOSE — **THE TWO BACKLOG DIRECTIONS OPENED, IN THE MAINTAINER'S ORDER: the generic harness SCOPED and its first slice LANDED in a separate repository (`~/Developer/blackbox-harness` H1 at `803f372`, selftests 7/0/0, fidelity F1 identical / F3 exact), and the living-documentation effort SCOPED in all three of its forms** — two rulings at the plan stage, two scope documents in the precedent form; the census in numbers (304 gates, one duplicated classifier, 93 must-fire controls, 4,021 frozen expectations); a finding about this tree recorded, not fixed (the static runner has no exit-0-after-shell-error branch). No build byte moved; static 135/0/0  [rolled 14z-137 close]
- Session 14z-134 CLOSE — **M16 RELEASED: the release run PASS 164 / SKIP 1 (approved) / FAIL 0 over 165 gates in three passes, and the run itself found and fixed FIVE harness defects that were never the artifact** (a `${VAR:?}` abort reading PASS 0s, the one-size timeout, a fresh scratch clone unable to simulate, a frozen pair five freezes stale, a liveness probe read by the wrong slot) — while the Verilator lane went PARALLEL (four clones, 1 h 41 for what took ~5 h serial); the DECISIONS_HISTORY pass (STATE 249 -> 134 KB), the LEVEL-0 SKILL CUT (two board-agnostic skills, 109 of 145 rules lifted, a GENERATED guide per skill), the release directory tracked; the learnings audit [VSP-176..178]; pushed  [rolled 14z-135b close, early — STATE was 156 KB]
- Session 14z-133b CLOSE — **THE RUNNER-LEVEL MAME DEFAULT, RULED, SHIPPED AND VALIDATED BY THE FULL SWEEP: 134/0/0/0 AGAIN**, compared row by row with 14z-133 (24 gates changed instrument, all green); then the same sitting: the macOS tmp reaper red root-caused and the scratch tools made to HEAL; FIELD VERDICT GREEN ON M16 (maintainer, MiSTer, 2026-09-05); the out-scope reds fixed; thread 3 (the merged/solo walk) 16/16 green incl. `test_dualtrack` brought in line with the ruling (class v6); B2 DONE (merged-m16 registered, the three legacy-oracle gates on the merged build 53/53); the CI repaired and GREEN on the runner for the first time (62/0/0/0); the BUILD LINE in the WIDE MRA ruled and built with its gate. No build byte moved  [rolled 14z-135 close, early — STATE was 174 KB]
- Session 14z-133 CLOSE — **THE OWED EMULATOR RUN, PAID: 134/0/0/0 GREEN** after a first pass of 131/3 whose three reds were ONE class and none of them the artifact: `MAME_BIN` unpinned, so the `vsavjw` leg ran Homebrew's `mame` and measured nothing, hidden behind a developer shell's export; both defects established by a 2×2, the class pinned AND gated, STATE rolled early. No build byte moved  [rolled 14z-134 close, early — STATE was 166 KB]
- Session 14z-132 CLOSE — **THE RELEASE WINDOW OPENED, AND THE MAINTAINER RULED FOUR TIMES.** The version-numbering mess fixed at its root (the wheel mark IS the merged build number, M16, gated); the M16 tracks built and measured at a two-member delta; the merged-vs-solo scoping question opened, ruled [VSP-175], walked two gates deep into the dispatch-key decision; M16 frozen, registered on whole-set keys, packaged, pushed; static 130/0/0; the emulator tier owed a clean run  [rolled 14z-133b close, early — STATE was 250 KB]
- Session 14z-131 CLOSE — **THE MAINTAINER CHALLENGED A GATE AND WAS RIGHT THREE TIMES RUNNING.** Two rulings executed (Pyron measured, `test_phasec_image` §4 re-targeted and green), then Phobos's three historically-corrected throws MEASURED AGAINST NATIVE VS2 and found MATCHING — but only after captures refuted my own description of the first result, a set-comparison was replaced by an ordered one, and widening to all 18 victims exposed a frozen constant as victim-specific. The method is now `docs/project/gate_scoping_method.md`. No build byte moved; static 130/0/0/0  [rolled 14z-133 close, early — STATE was 213 KB]
- Session 14z-130 CLOSE — **M13 FROZEN, REGISTERED AND TAGGED** (donovan-m19 / huitzil-m26 / pyron-m20 / merged-m15, mark M13, the boot name screen reading VAMPIRE SAVED): the `gap_be27a` fold-in BYTE-NEUTRAL on all five tracks after its ownership question turned out to have a measured answer (the generic repoint would have silently reverted the 14z-64 mirror-victim fix); freeze suite 8/8 SUITE GREEN over 3h05m with every expectation set a PURE CARRY; emulator tier 131/1; the 137-file re-point sweep, which walked into the documented history-rewriting trap and needed 13 dated records restored. Static 130/0/0/0  [rolled 14z-131 close, early — STATE was 193 KB]
- Session 14z-129 CLOSE — THE TRIAGE SESSION: five red gates to green, one (`audit_type_dispatch_range`) DROPPED on measured ground after the maintainer's "better no test than a bad one", and NOT ONE red was a defect in the shipped artifact. Two decisions ruled and implemented (release scope 141/23 + the new `cadence` column that makes the MiSTer ruling enforce itself; `gap_be27a` folded into M13). [VSP-166] ruled by the maintainer against a proposal of mine and it paid for itself within the hour. No build byte moved; twelve commits, all pushed  [rolled 14z-130 close, early — STATE was 171 KB]
- Session 14z-128 CLOSE — THE EMULATOR-TIER SWEEP: the runner built (`run_all_emulator.sh` + `ci_emulator.tsv`, 164 gates enumerated where 132 had been reachable only by typing a filename), THREE DEFECTS FOUND IN IT BY RUNNING IT, the shared-writes guard caught EXEMPTING EIGHT LEGACY ROWS, and a LEGACY replay found guarded by NOTHING for five sessions. Sweep 155 gates: 136 PASS / 19 FAIL / ZERO SKIP — and not one red was a defect in the shipped artifact; eight closed in-session. Strict static 129/0/0/0  [rolled 14z-129 close — STATE was 164 KB]
- Session 14z-127 CLOSE — ONE DAY, TWO OPEN QUESTIONS ANSWERED "THE PORT IS FINE", AND THE INSTRUMENTS THAT PROVE IT: #114 REFUTED then properly scoped (its evidence was JEDAH; the cadence is the HOST ENGINE; the mash ceilings MATCH), the boot title SAVIOR -> SAVED BUILT on all five tracks, and `test_shared_writes` FOUND GREEN AGAINST 14z-91 BUILDS FOR TEN FREEZES. Ten commits, all pushed; strict static 126/0/0/0  [rolled 14z-128 close — STATE was 160 KB]
- Session 14z-126b CLOSE (3) — ritual complete for the LONG CONTINUED session: NINE ARCS — a maintainer correction to a rule I had overstated, the `14z-N` key documented as law, #113 CLOSED then MECHANISED, the MiSTer core-list name + main-MRA fix, a corpus gate that could pass while asserting nothing, #112 ROOT-CAUSED, Jedah ARBITRATED, the aerials part-resolved, and #114 opened on 421+P. No build byte moved; strict static 126/0/0/0  [rolled 14z-127 close, early — STATE was 164 KB]
- Session 14z-126b CLOSE (2) — FIVE ARCS AFTER THE FIRST CLOSE: the three grandfathered tags amended and force-pushed, a red root-caused to the macOS tmp reaper, #112 picked up and its premise refuted, the black foot found by searching the INPUTS, and two gotchas + a gate that came out of it. No build changed; strict static 126/0/0/0  [rolled 14z-127 close]

- Session 14z-126 CLOSE — THE DF-STARTUP QUESTION ANSWERED (the window is `+0x147`, armed PER CHARACTER — neither global nor inherited), which the maintainer's "where do the values come from?" turned into a PRESERVATION FINDING (vs2 and vh2 carry the VS-style DF handlers for all 18 and never reach them, so the port RESTORED Capcom's own values) with its own document `docs/game/preserved_data.md`; and the frame-data privacy rule ruled and shipped the same session. No build changed; strict static 124/0/0/0  [+1 more entries]  [rolled 14z-126b CLOSE (2), early — STATE was 152 KB]
- Session 14z-125b CLOSE — THE COMMUNITY CROSS-CHECK DELIVERED AND THEN FINISHED IN ONE DAY: all 15 vanilla characters derived for the first time, ~96% agreement per column, the JOIN measured in-emulator after a fitted model was overturned, and the residue arbitrated — two families closed, one honestly open; two defects found, both OURS; no build changed; strict static 123/0/0/0  [+2 more entries]  [rolled 14z-126b close, early — STATE was 154 KB]
- Session 14z-124 CLOSE — THE DOCUMENTATION RATIONALIZATION PASS IS DONE (G7): engine_internals' last third rationalized and the document flipped to REFERENCE, doc_shape has ZERO PENDING, the ci floor 15 → 60, inferred_claims CLOSED; one tooling defect found on the way (the wrap-blind atlas-rows splitter); THEN CLAUDE.md PASS 2 the same day (414 → 344 lines; oracle_classes.md is the class spec of record). No build changed; portable 61/0  [rolled 14z-126 close]
- Session 14z-123 CLOSE — THE DOCUMENTATION RATIONALIZATION PASS, ONE DAY: T1 (annotations.md CREATED, generated), G2 (three T3 rigs — EVERY claim RETRACTED: Sasquatch's DF armor, the roulette tag, the advancing guard), G3 (a)+(b), G4, G6 (HANDOFF 3,652 → 1,374; the gate index GENERATED), CLAUDE.md pass 1; no build changed; PUSHED  [+1 more entries]  [rolled 14z-125b close]
- Session 14z-122 CLOSE (2) — ritual complete for the CONTINUED session: two new rulings recorded (the annotations row is CHECK-FIRST; THE CLAUDE.md CONDENSING PASS is a named item), G1 executed after the specimen's ratification — eight document commits, the atlas retagged, 6 docs still PENDING  [+3 more entries]  [rolled 14z-125b close]
- Session 14z-121 CLOSE — ONE DAY, FROM THE M12 VERDICT TO THE CHARACTER PAGES: the board verdict GREEN; the Killshread ruling; the phase-3 remainder; the pushback = a STEP TABLE on record +0xC; the three CHARACTER PAGES; no build changed; PUSHED  [+7 more entries]  [rolled 14z-123 close, early — STATE was 158 KB]
- Session 14z-120 CLOSE — ONE DAY, THE CHARACTER-DATA MAP FROM THE MOVE LISTS TO PHASE 3: the three move lists, every chain NAMED on native vs2 (`test_move_naming`), the hitbox encoding / attack record / reaction sets MEASURED; no build changed; strict 117/0/0/0  [+4 more entries]  [rolled 14z-123 close]
- Session 14z-119 CLOSE — THE PHYSICS-PORT FREEZE: donovan-m18 / huitzil-m25 / pyron-m19 / merged-m14 (mark M12), the stock twin MOVED by design; strict 117/0/0/0; FIELD VERDICT GREEN 14z-121  [+1 more entries]  [rolled 14z-122 close]
- Session 14z-118 CLOSE (3) — the session's close. One day, four arcs: the M11 board verdict  [+4 more entries]  [rolled 14z-121 close]
- Session 14z-117 CLOSE (3) — the session's last act. The VS/VS2 data-architecture page CORRECTED from a row-by-row measurement after the maintainer read it; the next session is RULED: a full documentation audit — measured, consis… [+4 more entries]
- Session 14z-116 CLOSE — THE COSMETIC/EXTRAS ARC: win quotes MEASURED THEN FORGONE, the hidden characters DECODED (Shadow takes the tenant — confirmed on the board), and PYRON'S MEDALLION WHITE-OUT FIXED after two years parked; 13 commits pushed; nothing frozen (the freeze battery = 14z-117). The close ritual audited: patch_notes/patch_index/HANDOFF/gotchas had been skipped on the first pass and were written.
- Session 14z-115 CLOSE — THE SELECT-WHEEL SEPARATION FROZEN (donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11, mark M9, stock twin unchanged), tagged at `b30611a`, strict 111/0/0/0, guard corpus 340/340; emulation verdict "no regression", the maintainer's own mockup the next cut (moved to STATE_HISTORY 14z-118)
- Session 14z-115 — THE SELECT-WHEEL SEPARATION ("E2"): the three tenant medallions repositioned by the maintainer's pixel offsets, hover rings tuned by eye, a 1 px black outline authored per cell; the OPEN FBNeo two-run-family instrument question first recorded (moved to STATE_HISTORY 14z-118)
- Session 14z-114 CLOSE — ALL SIX SKILLS DISTILLED AND LOCKED TO THE DOCS in one session (the MiSTer pair, the CPS-2 pair, the game skill and the port skill — 425 rules, every one anchored in the paragraph it distils, every number in a log; four staleness passes run first, each its own commit) (moved to STATE_HISTORY 14z-117)
- Session 14z-114 — the MiSTer SKILLS distilled with their checker: two skill packages (level 1 `[MSC-1..73]`, level 2 `[MSV-1..36]`), every rule ID-anchored in the doc paragraph it distils; the log gained the 14z-108/109 measurements it never had; the field test got an in-tree carrier (moved to STATE_HISTORY 14z-117)
- Session 14z-113 CLOSE — the MiSTer SCOPE DOCUMENT written and its three decisions ruled; the S1-S20 staleness pass run; bundle 14z112 field-verified; merged-m10 FROZEN; the RELEASE FORMAT ruled and shipped (one self-sufficient directory per platform) (moved to STATE_HISTORY 14z-116)
- Session 14z-113 — `docs/project/mister_scope.md` written (scope only, not the skills): the two-level split, the doc dependency map, and the known-stale inventory S1-S20 (moved to STATE_HISTORY 14z-116)
- Session 14z-112 CLOSE — #99 CLOSED on a green field verdict (the board on bundle 14z111 / merged-m9 M8 does not crash on Bishamon > Phobos; MAME agrees on four hand-played recordings, all guard-clean, tracked as `play-merged-m9-01`, `run-merged-m9-02..05`); #112 (Press-of-Death palette) reproduced, ruled COSMETIC and parked; #113 measured VANILLA on emulator (the one-frame white-out at a down); the WIDE profile stopped breaking stock Vampire Savior — a WIDE set is ONE zip, the four patched group-A members inside `vsavjw.zip`, the parent pristine (`build/m3b_merged17`; frozen as merged-m10 at 14z-113) (moved to STATE_HISTORY 14z-115)
- Session 14z-112 — FIELD VERDICT GREEN on merged-m9 (M8): #99 CLOSED by the maintainer; the four recordings tracked; #113 re-read as a sprite-dropout frame; playback length now MEASURED (a recording ends where the human stopped; `test_inp_corpus` plays to MAX_FRAMES=6000 by default) (moved to STATE_HISTORY 14z-115)
- Session 14z-111 CLOSE — #99 ROOT-CAUSED (CPU-Phobos ran DEMITRI's AI: the four per-class AI action-script tables `PRG:0xBF01A/09A/11A/19A` are 16 classes + the same 16 repeated, so tenant classes read the aliased row) AND FIXED by option A (the tenants' own vs2 AI script blocks as data roots, zero code); frozen donovan-m14 / huitzil-m21 / pyron-m15 / merged-m9, mark M8; board bundle 14z111 ready; FIELD REPORTS ARE RECORDINGS promoted to CLAUDE.md §4 law with `tests/test_inp_corpus.sh` (moved to STATE_HISTORY 14z-114)
- Session 14z-111 — OPENED WITH A CLOSE-RITUAL AUDIT of 14z-110b (clean but unchecked): the three in-flight validations re-run and accepted; then the field verdict RED on merged-m8 (the board STILL crashes on Bishamon > Phobos, MAME by hand too) -> the maintainer's hand-played `.inp` captured under the new `tools/run_inp_guarded.sh` found the real mechanism the two poke-derived fixes never touched (moved to STATE_HISTORY 14z-114)
- Session 14z-110b CLOSE — the 0x51->0x44 remap BUILT, FROZEN (donovan-m13 / merged-m8, M7 mark carried) and MAME-VALIDATED; the board bundle carries merged-m8; the FBNeo partial oracle's reduced refit RULED and in progress; closed at the maintainer's call (context ceiling) with three validations in flight — re-run and accepted at the 14z-111 opening audit
- Session 14z-110b addendum — THE FBNEO ORACLE RED ROOT-CAUSED TO THE RULED d2-WINDOW CYCLES (110), NOT THE REMAP (110b): m12 == m13 RAM at the failing frame; the hunt cost a paid-for instrument trap; resolution = per-replay measured-clean frame overrides, 26_don_arcade_mash dropped for 05_timeout_idle (maintainer-ruled)
- Session 14z-110b — THE RESIDUAL #99 ROOT-CAUSED AND THE REMAP RULED-BY-CONDITION: the STORED state 0x51 over-runs a SECOND 80-vs-84 dispatcher (PRG:0x2384E) the 14z-43 audit also missed; fix = 0x51 -> 0x44 on the six deity nodes + one ported immediate, measured equivalent at every consumer both engines have. (Field: STILL CRASHED — the real #99 was the AI script-table alias, found 14z-111 from the maintainer's recording.)
- Session 14z-110 (4) — CLOSE. THE RULED ORDER IS COMPLETE: FIX -> AUDIT -> RE-FREEZE. The #99 d2-window fix built, audited and frozen (donovan-m12 / merged-m7, mark M7), with the MiSTer CRC tail and a field bundle. Its verdict came later and was RED: the crash survived, and 14z-111 root-caused the real mechanism.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-109 (4) — THE #99 CRASH INVESTIGATED ON EMULATOR after the FIELD TEST PASSED on a real DE10-Nano (tenants selectable, playable, voices heard, feel better than emulator) with one 100%-reproducible crash. Root-caused the same day to vs2 type byte 0x51 in Donovan's ported block — a conclusion 14z-111 later RETRACTED as poke-contaminated. Also: the OBJ-list oracle, the DECISIONS_HISTORY split.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-108 CLOSE — ritual complete. THE FUNCTIONAL CHAIN IS COMPLETE IN SIMULATION AND THE CORE FITS A CYCLONE V — BUT IT DOES NOT RELIABLY CLOSE TIMING. A tenant FIGHTS on the core and fights CORRECTLY against MAME; the QSound extension is FETCHED; bank 1 under load is GO; scroll is structurally cleared; the CPS-2 video registers are documented for the first time. AND THE SESSION'S OWN HEADLINE IS THAT FOUR OF ITS FINDINGS WERE CORRECTIONS OF THINGS PUBLISHED EARLIER THE SAME DAY — three of them mine. 22 commits, ALL LOCAL.  [rolled 14z-111 close]
- Session 14z-108 — THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR END, NOT TRANSPOSED IN TWO — measured on all four before one bit was changed, and the half nobody had exercised is where the previous reading was wrong. `tools/rpl2siminputs.py` fixed (one dict, no fork commit, no RTL), verified against the game's own input mirror on both implementations, and the gate rebuilt with a per-direction lock and a must-fire control. One of the two frozen expectations the record said would move DID NOT MOVE AND COULD NOT — which also means the frozen sim anchor could not move. AND THE PAYOFF LANDED THE SAME SESSION: OBJ BANK 4 — THE FIGHTER ART — IS FETCHED FOR THE FIRST TIME ON ANY FPGA IMPLEMENTATION, 843 OF ITS TRAFFIC FRAMES INSIDE A MATCH. A TENANT HAS FOUGHT ON THE CORE. Bank 1 under load answered from the same run and it is GO. Still never: HARDWARE — and no Quartus synthesis has ever been run, so resource fit and timing closure are unknown. That is now the largest gap in the arc.  [rolled 14z-111 close]
- Session 14z-107 CLOSE (final) — THE WIDE ROMSET BOOTS ON THE CORE, draws our select screen and fetches our wheel art: six RTL slices D0-D5 (the MRA, the runtime profile gate + QSound width, the SDRAM placement, the CPS-2 Turbo object promote, the 6 MB program window, and D5 THE DECRYPTION RANGE — the CPS-2 key's encrypted-opcode range word is stored COMPLEMENTED and jtcps2_dec_ctrl reads it straight, which no stock CPS-2 game could ever expose); 105 distinct tenant tile codes out of obj bank 5 with the control leg at zero; bank 0's traffic under the redirect ANSWERED and GO; both stock legs green. **The arc's headline was methodological: SEVEN instrument and harness defects found in this lane, every one of which would have read as an RTL fault, with D5 the counter-example where the RTL genuinely was at fault.**  [+3 more entries]  [rolled 14z-108 close]
- Session 14z-106 CLOSE — ritual complete: HOUSEKEEPING executed (the 14z-105 evidence logs + the guard-corpus TSV committed, the rehearsal probes attic'd, `../build_attic_14z102` 8.1 GB deleted under the standing policy, `emu/fbneo`'s modified content verified as patches 0001+0002) and THE MiSTer ARC OPENED with no RTL touched — the framing RULED (an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA re-implementation of MAME) and all five alignment questions answered the same day (separate core, GPL-3.0 fork, measure-then-choose profile, sim = gate / hardware = field test, MRA+RBF with a stock-vsavj reference leg); LICENSE = GPL-3.0; slice A landed the public fork `DefinitelyFrenchName/jtcores@vampire-saved` with the separate core `cores/cps2w` -> `jtcps2w.rbf`, pinned as submodule `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`, and the twin proof MEASURED (the vsavj MRA byte-identical to stock cps2's except `<rbf>`); slice B measured the fit (`mister_fit.md`: PRG 4.82 MB, QSound banks 0x80-0x8E all aliasing, GFX 52,347 roster codes / 6.39 MB against 4,028 blank tiles / 0.49 MB in ALL of vanilla's 32 MB — a wider GFX tier REQUIRED) and slice C proved THE VERILATOR SIMULATION LANE ON macOS (stock jtcps2 running vsavj, ~1.4 s/frame, the full recipe in `docs/platform/mister.md`, the `.rpl` -> `sim_inputs.hex` translator gated)  [+3 more entries]  [rolled 14z-107 close (final)]
- Session 14z-105 CLOSE (final) — THE MAINTAINER-DIRECTED WINDOW EXECUTED END TO END and field-confirmed: W1 the OBORO SELECT HOOK (cursor on Bishamon + hold START -> vanilla vsavj's Oboro, id 0x18, P1 and P2, vanilla's own Gallon-variant idiom one cell over) and W2 the VERSION STRING ("M6" at the select screen, the naked-eye A/B tell CLAUDE.md §5 had wanted since 14z-92, authored glyphs pixel-exact) — frozen as donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 with the stock twin m5_stock6 = `883e7d17` BIT-IDENTICAL, every gate and both soaks green, pushed 2026-08-22; the GFX TILE CODEC was found MIRRORED on the way (plane bit i draws at pixel 7-i; 14 sessions old, nothing had ever read pixel ORDER until the first authored tile) and the 14z-104 prediction that more sprites would move the select-window specs DIED by measurement over all 148 specs; RELEASE PACKAGING landed (`release/merged-m6/`, xdelta3 against the reference dumps, no ROM byte in the package) and was ruled IN-TREE until MiSTer  [+3 more entries]  [rolled 14z-107 close]
- Session 14z-104 CLOSE — THE §4 COVERAGE DEBT TACKLED end to end (maintainer-directed): the mandate measured cell by cell, six new audits built and green on merged-m5 and the matrix documented as a maintained artifact; THE PURSUIT answered and instrumented (audit_pursuit_leap); coverage gap 1 (tech roll + throw tech, both directions) and gap 2 closed; THE OBORO QUESTION answered with a live demonstration; the 14z-105 window (Oboro hook + version string) prepped in NEXT_SESSION  [+4 more entries]  [rolled 14z-107 close]
- Session 14z-103 — THE A4 PIN-CLEANUP PASS EXECUTED (every stale reference re-pointed, run green, or ruled a deliberate pin) plus the three findings it surfaced (the gate_failures litter class, GitHub #110, four LEGACY replays promoted off self-frozen .sha1); #110 FIXED AND CLOSED — the mechanism was the ARCADE DRAW, not cycle drift, both audits re-derived on pinned-opponent rigs and green on merged-m5; the Circuit Scrapper report measured and not reproduced  [+1 more entry]  [rolled 14z-107 close]
- Session 14z-102 CLOSE — THE #107+#109 WINDOW frozen as donovan-m10/huitzil-m19/pyron-m13/merged-m5 (#109 re-derived from scratch to effect-class ROW 31, the DF clone-mode beam emitter vsavj stubbed; #107 row flip; gold tint kept; build-dir triage 8.1 GB atticked; N-2 deletion policy adopted)  [+6 more entries]  [rolled 14z-105 close]
- Session 14z-101 CLOSE — the agreed #108->#107->#106 sequence executed windowless (#108 INVERTED to not-a-defect: the satellite word is our own bank row, native satellites equally sweep-inert; #107 twin-anchored statically + tie-refusal landed; #106 closed via verify_pcrel_data --extract); guard-corpus built 316/316; DF mechanics measured ours-vs-native (frameworks differ BY DESIGN; ours == pristine vsavj on the legacy control); #109 found, root-caused through two in-place retractions, and fully prepped  [+9 more entries]  [rolled 14z-104 close]
- Session 14z-100 CLOSE — THE HARDENING PROGRAM opened and executed same-session (pointer/flow comb H1, escape triage H2, the #99 continue-switch lock H3, the contact rig H4 with the -debug/non-debug instrument paradox left to 14z-101); #99 CLOSED (maintainer); #106/#107/#108 filed; the build-dir decision package delivered  [+3 more entries]  [rolled 14z-104 close]
- Session 14z-99 FREEZE + field-confirmation — THE WINDOW EXECUTED END TO END (donovan-m9/huitzil-m18/pyron-m12/merged-m4; #43(b)+#103+#104+#105; merged BIT-FOR-BIT the rehearsal; stock twin moved by design); field pass CLOSED all three tickets same day (incl. transformation throws) and un-parked #99; the skipped close ritual caught up post-freeze  [+7 more entries]  [rolled 14z-102 close]
- Session 14z-98 CLOSE — #103 root-caused+staged (window = uncomment+battery), #102 answered (vanilla's own continue), #104 found/reproduced/mechanism-closed-then-14z-99-corrected, #105 filed + AUTO selection solved, "instance 2" retracted (the 2-byte-poke class); NO SHIPPED BYTE MOVED  [+9 more entries]  [rolled 14z-101 close]
- Session 14z-97 CLOSE — #96 CLOSED (the battery's target FOLLOWS THE BUILD via registry.tsv); the §4 masked-compare vocabulary unified to ONE implementation (tests/lib/masked_compare.sh, proven 3 ways); the #99 continue rig BUILT and blocked one screen short by #103 (instance 2); #102 filed (arcade chaining quirks); 08_challenger_join's 3807 attributed to $FF06E1 (ram.md:62); two measured-wrong-thing defects fixed (propose_masked_specs absolute-builddir trap; the lifted diverge branch)  [+9 more entries]  [rolled 14z-100 close]
- Session 14z-96 CLOSE — ritual complete  [+7 more entries]
- Session 14z-95 — FOUR MAINTAINER RULINGS TAKEN, #52 LANDED, and the Phobos sfx report corrected from "a sound missing" to "a WRONG sound"
- Session 14z-94 (11) — THE MERGED-M2 PLAYTEST RESULT (maintainer, 2026-08-18, build/m3b_merged9 on MAME). NO REGRESSION — and one CRASH.  [+11 more entries]
- Session 14z-93 CLOSE — ritual complete  [+3 more entries]
- Session 14z-92 CLOSE — ritual complete  [+6 more entries, incl. GitHub #75 closed — the merged gfx-verify abort was a verifier artifact]
- Session 14z-91 CLOSE — THE LEGACY REGRESSION FIXED (obj_hook de-thunked: walker relocated, callers repointed; fixture-override deletion; type-6 change), m5/m13/m7 -> m7/m15/m9 re-freeze, EIGHT maintainer rulings applied (Rule 1 v2 retitle #35, PNG goldens ruled outside rule 7 #73, CI drafted #41...). THIS GROUP ALSO HOLDS, as ### sub-entries: 14z-90 (the 2026-08-15 adversarial audit re-judged, tier 1 complete), 14z-83..89 (Phobos DF gold block huitzil-m6, M5 voice samples design + Z80 driver RE, the 14z-85 owner-tag family, 14z-86 M5 voice batch, 14z-87 voice-class borrow + 87b beep/medallion, 14z-88 medallion revert, 14z-89 QSound ledger binding)
- Session 14z-82d — the playtest reports, measured  [+3 more entries]
- Session 14z-81 — THE MERGED-LEGACY MEASUREMENT: legacy safe, tenants not
- Session 14z-80 — THE N-TENANT LOOP: `main()` iterates, and the three traps that were not in the spec
- Session 14z-79 — (b') LANDED, AND BULLETA'S DARK FORCE WAS BROKEN FOR TEN SESSIONS
- Session 14z-71 — THE BEAM: row 16 of the effect-class table is a STUB in vsav, and underneath it vsav has no list-type 12
- Session 14z-76 — Pyron's EFFECT PALETTE ported; the "16-row hazard" retracted
- Session 14z-78 — `anim` MOVES: M3b's blocker was a hex literal
- Session 14z-77 — M3b slice C: rows get an OWNER, and the gating family asks it instead of the build scalar
- Session 14z-75 — PYRON FROZEN as `pyron-m1` (d8b282da)  [+1 more entries]
- Session 14z-74 — PYRON's render rung OPENED (Steps 0/1/3 landed), and a GENERATOR BUG found under it  [+1 more entries]
- Session 14z-73 — the grab victim: FIXED and MAINTAINER-CONFIRMED (both grabs, MAME + FBNeo). The victim's capture-pose keyframe-pointer table row for H aliased character 0's block; ported H's own block. Also: the FG "slowness" was the broken GFX, not timing — resolved by observation.  [+1 more entries]
- Session 14z-71 CLOSE — ritual complete  [+6 more entries]
- RESOLVED the same session — TAKE OVER THE DEAD LIST-TYPE 6 (maintainer-approved; build/hui20, fingerprint 40cc10b1)
- Session 14z-70 — THE BEAM IS AN ANIM-SELECTION DEFECT: our build never walks the beam anim nodes (measured, both legs, one emulator)  [+3 more entries]
- Session 14z-69 CLOSE — ritual complete  [+8 more entries]
- Session 14z-68 (the effect-flow closure — root cause found)
- Session 14z-67 (D4: the Phobos gfx vertical)
- Session 14z-66 (playtest round-1 worklist)
- Session 14z-65 (M3b OPENED 2026-08-07 — plan + decisions register)
- Session 14z-64 SESSION CLOSE (2026-08-07)  [+3 more entries]
- Session 14z-63 (phase 3 item 1: the wheel bank-5 move — REAL MEDALLION ART, vanilla cells pixel-identical by construction)
- Sessions 14z-62j/62k (same day — OPTION A PHASES 1-2 LANDED and PLAYTEST-VALIDATED: the select family serves from group C bank 5; Jedah confirmed indistinguishable from vanilla by human playtest)  [+1 more entries]
- Session 14z-61 (WIDE GARBLE FIXED — a shadowed ROM member, not the emulator; and the rendering gate that should have caught it)
- Session 14z-60 (select cursor MEASURED; the id space is CONVENTIONAL)
- Session 14z-59l (ROSTER ACCESS decided; the vs2 wheel measured properly)  [+1: 14z-59j dual-track invariant established — later SUPERSEDED 14z-94 (#95), see the archive's marked banner]
- Session 14z-59i (M5 SOUND IS AUDIBLE; WIDE build registered; a false fingerprint corrected)  [+5 more entries]
- Session 14z-49 (rounds 61-62: HUD MUGSHOT + NAME + SELECT MEDALLION — the whole per-slot venue-asset family fixed)
- Session 14z-58e (handoff hygiene: reproducibility PROVEN)  [+1 more entries]
- Session 14z-57 (WIDE B4 attempt 2 — clean fail, narrowed to the loader)
- Session 14z-56 (WIDE B4 attempt 1: an invalid canary, honestly)
- Session 14z-55 (WIDE B2 — the 19-bit tile address; and the gate's video blind spot)
- Session 14z-54 (WIDE Phase B0+B1: the first two regions grown and proven inert)
- Session 14z-53 (RE-CONTEXTUALIZED: from "fit in the holes" to CPS-2 WIDE; Phase A measurements complete)
- Session 14z-52 (M5 phase 1: music bug root-caused; 13 rows restored; the rest is a SPACE problem)
- Session 14z-51 (M5 sounds: discovery phase — the id-space myth dies)
- Session 14z-50 (round 65: M2b+ASSETS FREEZE at b91647c7)
- Session 14z-49d (round 64: mask window RATIFIED; recolor necessity proven; audit script)  [+2 more entries]
- Session 14z-48b (rounds 59-60: HC moves maintainer-CONFIRMED; HUD portrait = wrong ART not palette; select medallion re-listed)  [+1 more entries]
- Session 14z-47 (SELECT POST-CONFIRM BLINK FIXED — accent thunks gain the owner-link venue fallback; battery pending at entry time)
- Session 14z-46 (SWORDLESS-DEITY PALETTE FIXED — the state_hook seq-id synthesis was wrong for 8 of 12 stubs; battery pending at entry time)
- Session 14z-45b (round 56 on 4f69589d: win screen maintainer-CONFIRMED; lose/continue NO-ISSUE)  [+1 more entries]
- Session 14z-44c (round 55: WIN-screen item corrected + sharpened)  [+2 more entries]
- Session 14z-43b (round 52 on 22ada38e: THE NEUTRAL-POSE TRIGGER FOUND — it's the ES FINISH; death-path class consumer = the suspect)  [+1 more entries]
- Session 14z-42c (round 51: LP/MP closed as native; ES = the known class-0x51 interim, UPGRADED to accuracy item; win-screen art item added; KO bug parked)  [+2 more entries]
- Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)  [+1 more entries]
- Session 14z-41 (call-pair audit: pair 3 = the known sound stub; PAIR 1 = the real suspect — a lost spawner)
- Session 14z-40 (mash bridge: the walker block audited clean — divergence narrowed to three reconciled engine-call pairs)
- Session 14z-39 (round 49: maintainer clarifications — the Lightning Sword reference data)
- Session 14z-38 (mash bridge: three fields exonerated; theory sharpened to the input-struct read)
- Session 14z-37 (round 48: shock CONFIRMED with a caveat — hit counts maxed; mash mechanic mapped to the doorstep)
- Session 14z-36 (SWORDED-421P SHOCK + DEATH FIXED — the final reconcile; the class-0x4E saga closes)
- Session 14z-35 (type-0x51 cluster resolved — the engines RENUMBERED the copy-class record family; latent crash preempted)
- Session 14z-34 (round 46: crash fix CONFIRMED + swordless shock RESTORED — the record-type insight reframes the remaining queue)
- Session 14z-33 (COLUMN CRASH FIXED — record-type dispatch aliases; permanent guarded gate)
- Session 14z-32 (round 45: blink fix CONFIRMED everywhere but the select screen; column-crash fix session)
- Session 14z-31 (round 44: BLINK ROOT-CAUSED + FIXED (color-aware accent); CRASH REPRODUCED + PINPOINTED)
- Session 14z-30 (round 43: crash triage — repro scaffold built, blocked on the plant input; classification of the other reports)
- Session 14z-29 (consumer-trace session: supplementary facts; repo stays at the 14z-28 interim)
- Session 14z-28 (round 41: 14z-27 class remap REVERTED — gameplay regression; three-consumer map final; deity palette item confirmed)
- Session 14z-27 (round 40: CHANGE IMMORTAL KO FULLY FIXED — native class remap; aura palettes explained)
- Session 14z-26 (round 39: 421P correction -> ROOT CAUSE FOUND + partial fix shipped; collapse handoff remains)
- Session 14z-25 (round 38: select-sword CONFIRMED by maintainer; 421K match-end KO bug logged + repro hunt banked)
- Session 14z-24 (SELECT-SWORD FIXED — draw-behind flag; machinery live at stage 6, battery pending)
- Session 14z-23 (select-sword: diagnosis CORRECTED — offset+priority, not missing art; still staged 99)
- Session 14z-22 (select-sword: machinery BUILT+VERIFIED, staged 99 pending the record-walk-gap fix)
- Session 14z-21c (select-sword: FULL activation chain reverse-engineered; fix ready to implement)  [+1 more entries]
- Session 14z-20 (row-0x0F fixture override SHIPPED; sword-shock aura resolved as engine-global; 2026-07-31)
- Session 14z-19 addendum (round 36 CONFIRMED, 2026-07-31)  [+1 more entries]
- Session 14z-18 (round 34: accent super-cycle completed; statue rows found and fixed; two new items logged) — CONCLUSIONS CORRECTED IN 14z-19
- Session 14z-17 (THE SWORD/STATUE BLINK IS FIXED — build f4a7e00e)
- Session 14z-16 (blink: vs2 STEADY confirmed; the complete fix design)
- Session 14z-15 (blink driver FULLY mapped: the stage palette-anim refresh system)
- Session 14z-14 (sword-blink fix session: driver mapped to the palette-JOB system; third table repointed; ONE tap from the finish)
- Session 14z-13 (round 33: electrocute FULLY CONFIRMED incl. yellow; sword blink mechanism DECODED)
- Session 14z-12 (round 32: X-ray STRUCTURE confirmed; effect-palette block ported; purple-vs-yellow = DECISION)
- Session 14z-11 (round 31: the X-RAY OVERLAY — offset-computed records swept; build 6f96f45b)
- Session 14z-10 (THE GARBLE FIX SHIPPED: protected-tile policy + exception pool)
- Session 14z-9c (ROUND-29 ROOT CAUSE, FINAL AND PHYSICAL: the Jedah-band tile window is NOT dead)  [+2 more entries]
- Session 14z-8 (round 28: the 14z-7 clear was a PHANTOM FIX — reverted; the real shock-garble mechanism characterized)
- Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)
- Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)
- Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)
- Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean
- Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)
- Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)
- Maintainer priority statement (round 24, 2026-07-30)
- Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)
- Session 14z (round 22: winpal copies convicted and fully reverted)
- Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)
- Session 14w-c resolution (ALL GREEN at d6a751cb)  [+4 more entries]
- Session 14v (grab-pointer work vars fixed — the Felicia float)
- Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)
- Session 14t (win-quote palette: decoded, port REVERTED by the gate)
- Session 14s (playtest round 16: overlay REVERTED; pixel gate born)
- Session 14r (overlay port COMPLETED to a 22-site shipping config)
- Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)
- Session 14p (feet fixed; blink mechanism = Jedah's overlay records)
- Session 14 highlights (M2a FROZEN)
- Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)
- Session 14n (round 12: revert validated; two new items scoped)
- Session 14m (f8eda2ca REVERTED — regression + board reset)
- (reverted) Session 14l (bank-attribution fix)
- Session 14k-b (blink TRULY root-caused: per-record bank attribution)
- (superseded analysis) Session 14k (OBJ budget saturation theory)
- Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)
- (earlier) Session 14i-b (round-9 mechanisms pinned)
- (earlier same session) Playtest round 9 diagnosis
- Session 14h highlights (win-quote portrait ported; HUD name found)
- Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)
- Session 14f highlights (select palettes fixed; splash/win specified)
- Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)  [+1 more entries]
- Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)
- Session 14c highlights (select-screen pipeline mapped)
- Session 14b highlights (M2b static phase — R2 cracked)
- Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)
- Sessions 5-6 highlights (M2a stage 4 — the port runs)
- Session 4 highlights (M2a — the real Donovan port)
- Session 3 highlights
- Early standing sections (Current milestone / Next actions / Open items / Decisions made) — 2026-07-era snapshots, STALE, kept verbatim in the archive; the closed early decisions (base revision vsavj, per-member checksums, byte-order convention) are all recorded in CLAUDE.md/HANDOFF too
- OPEN BUG (14z-60y): WIDE renders Donovan/Anita with WRONG TILES — FIXED 14z-61 (the shadowed-ROM-member hash-resolution trap); header kept as written

---

# STANDING SECTIONS (current state — never archived)
## RELEASE-TIME TEST SCOPE (maintainer, 2026-09-02)

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

## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

**[VSP-21]** "vsav vanilla is always better when we can." **When a console port and
arcade vsav differ and both would work, take vanilla.** A console port's
choice is not evidence that vanilla is wrong; it is evidence of what that
port's designers preferred.

This is a general rule, not a one-off: the PS1 capture is a reference for
what is POSSIBLE and for data we cannot otherwise obtain (cell placement,
the adjacency of NEW cells), not a style guide for content vsav already
defines. Paired with the maintainer's other statement — "as long as we can
select characters it's good" — the test is: does keeping vanilla still let
the feature work? If yes, keep vanilla.

Applied immediately, twice:
- **`Bishamon DL` and `Aulbath DR` stay vanilla** (Anakaris / Sasquatch).
  PS1 sets both to "no move"; neither is needed for reachability, so
  vanilla stands.
- **Horizontal wrap stays vanilla.** Vsav wraps left/right (cell `0x01`
  Left goes to `0x05`, measured and confirmed in-emulator); the PS1 report
  of "no wrapping" reflects untested extremes. We touch none of those
  cells, so nothing to decide.

Judgment applied under the same rule, open to veto: the three inbound edges
from `0x0B` (`D`/`DL`/`DR` into the new row) DO diverge from vanilla, and
strictly they are not required — Phobos and Donovan are already reachable
via `Bishamon D` and `Aulbath D`, and Pyron through them. They are kept
because without them, pressing Down on the cell directly above the new row
does nothing while three medallions are visible below it, which is the UX
failure "as long as we can select characters" is meant to exclude. Dropping
them would reduce the legacy footprint from 5 bytes to 2.

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

## Decisions pending (human)

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

- **PYRON'S CAPTURE-KEYFRAME ATTACKER ROW `0x11` IS NOT PORTED. DECIDED
  (maintainer, 2026-09-04): MEASURE FIRST — *"Agreed, that's where to
  start."* **MEASURED 14z-131, AND IT IS A REAL, GROSSLY VISIBLE DEFECT ON A
  2P SURFACE — NOT A COSMETIC.** The port decision is now the maintainer's;
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
  naming the host block it replaces on the base track. Two things to settle
  first, both cheap: the block's LENGTH (its sub-block stride is `0xA0`, 32
  victims, so ~`0x2040`; `test_capture_pose_sources` already has the length
  rule for the other fifteen), and the signed-16-bit `lea (a0,d0.w)` bound
  that section 6 of that gate checks. One freeze.
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
    `[2,1,0,3,11,10,29]`**. So a second mechanism is in play and it may be the
    dominant visible effect.
  * **The obvious big hypothesis is REFUTED**: our Pyron is NOT running
    Demitri's throw. His attacker records are his own — 12 distinct, span
    `0x288`, against native's 12 distinct, span `0x288` (relocated, same
    structure); Demitri's throw walks 8 records, span `0x2D8`.
  **THE NEXT MEASUREMENT, named so it is not re-derived:** the pose installer
  at `PRG:0x27FAA` selects one of FOUR sibling tables
  (`andi.w #$c,d1; movea.l $27fee(pc,d1.w),a0`) before indexing by the
  victim's id, and the requested pose id `d0` comes from the ATTACKER's side.
  So the question is whether our Pyron requests different pose ids, or the
  same ids through a different sibling table. That decides whether row 0x11 is
  the whole story, a part of it, or a red herring.
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

*(Cleaned 14z-109, maintainer-directed, and again 14z-134: resolved and
no-longer-shaping entries moved VERBATIM to `DECISIONS_HISTORY.md` — grep there by topic.
Lifecycle: rulings are still marked DECIDED in place here first; they move to
the archive once they stop shaping active work.)*

- **THE COMMUNITY CROSS-CHECK — our data vs the best community reverse
  engineering (maintainer backlog item, 2026-08-31, 14z-124). ~~RECORDED, not
  started~~ PHASE 1 DELIVERED 14z-125 (the maintainer's order: "start with item
  2 to get proper confirmed data"): all 15 vanilla characters derived, the
  standing-normal join MEASURED in-emulator, and every comparable column
  classified — ~96% agreement per move under one stated convention each
  (`docs/project/tables/community_crosscheck.md`, gates
  `test_community_crosscheck` + `test_vanilla_frame_join`). STILL OPEN, and
  named on the page: **~~the residual ~4% outliers are not yet arbitrated
  in-emulator~~ ARBITRATED 14z-125b — two of the three families closed (the
  damage residue is the WORKBOOK double-counting records that share the engine's
  +0x10 dedup key, confirmed by a hit rig 75/78; the duration bytes are the
  engine's, 334/380, but a frame-rate trace cannot resolve a one-frame
  convention, so startup +1 / recovery +2 stay named conventions). ~~STILL OPEN:
  Jedah's crouching recovery (+3, not +2)~~ **CLOSED 2026-09-02 — ARBITRATED IN
  ENGINE TICKS, AND THE RESIDUE IS THE WORKBOOK'S.** The instrument the entry
  said did not exist does: a write tap fires per WRITE, and `PRG:0x027F70`
  (`subq.b #$1,$20(a6)`) IS one engine tick, so the multi-tick frames that
  defeated the frame-rate trace are fully visible. **18 of 18 derived totals
  equal the engine's measured tick count EXACTLY** (JE, LI, DE crouching
  normals; no tolerance). Our `startup` and `active` are not flagged and agree
  with the workbook's own conventions, and the total is now ground truth — so
  our recovery is right and the workbook's sits one frame below its own
  convention for those seven moves. `tools/tick_durations.py` +
  `tests/test_tick_durations.sh` (with a must-fire control). **THE SEVEN AERIAL OUTLIERS — PARTLY RESOLVED 2026-09-02.**
  `tick_durations.py` separates the move from the jump for chains that LOOP
  (BI 5/6 exact; the miss is the flagged `J.HP`, ours 28 vs the engine's 27; BU
  `J.LK`/`J.LP` exact). NOT separable yet: aerials whose last node HOLDS with no
  further pointer write before landing (VI, FE, SA) — those still report
  AIRTIME, and identical numbers across a character's moves are the tell.
  **THE LIKELY CAUSE IS NOW NAMED, from the community corpus that arrived
  2026-09-02:** mizuumi distinguishes NEUTRAL-jump from FORWARD-jump variants of
  the same button (`8J.LP` vs `9J.LP`, `J.HP8` vs `9J.HP`) where our slot map
  carries ONE chain per aerial button. If the flagged moves are exactly those
  whose variants differ, we are collapsing a variant, not miscounting. Needs a
  two-direction jump rig; not yet measured.
  ~~`red damage` needs the [VSE-40] scaler to be comparable at all~~ **WRONG and
  RETRACTED 14z-125b: the workbook's `red damage` is our `+8` PLUS `+9`, the
  move's total — 266/281 (94%) once compared as the sum;**
  specials / supers / throws / the `CL.` and `6`-prefixed rows need their own
  vsavj naming rigs (the bulk of the workbook's 730 rows); seven workbook
  columns have no counterpart in the tree. The WIKI half — the 146
  player-struct offsets against `ram.md` — was DEFERRED by the maintainer this
  session to item 1's session, whose lead `+0x1B3` sits in the same table; note
  the page carries NO per-move frame data, so it was never a second frame-data
  source. The original entry follows.** Two sources the maintainer will provide: a
  WEBPAGE, and an EXCEL of frame data for the VANILLA characters. What we
  have: frame data DERIVED for the three tenants only (`docs/project/tables/
  chars/<tenant>_anim.md` "Frame data (derived): startup / active /
  recovery", read off anim-node durations + attack records by the charmap,
  phase 2, 14z-120/121; move identities measured on native vs2 by
  `test_move_naming`), and NOTHING collected for vanilla characters; the
  derivation has never been checked against an independent source. Plan:
  (1) inputs — the URL and the `.xlsx`, kept OUTSIDE the tree (third-party
  work; we commit only our comparison and cite the source); (2) derive the
  same figures for the vanilla characters from vsavj's own 32-row bank
  (does `tools/charmap_gen.py` walk a vanilla character? if not, extend it —
  the bank is per-character by law) and compare per move: startup / active /
  recovery, damage, hit counts; (3) every mismatch is MEASURED in-emulator
  on vanilla (a replay + field_trace) — the emulator is the arbiter, not the
  sheet and not our derivation; (4) if the sources cover vs2, compare the
  tenants' derived figures the same way. Deliverable:
  `docs/project/tables/community_crosscheck.md` + a gate freezing the
  agreements and naming the measured disagreements. Cost: T3, one to two
  sessions. **INPUTS RECEIVED 2026-08-31 + THE RULE, maintainer's words:**
  "measurement is king, not a source that we don't know how it was measured;
  however, community information is precious: if it aligns perfectly or
  with a constant offset, then we know the measure is good; if we find an
  inconsistent pattern, then we must search whether the measurement is
  correctly done or not." So every column's deltas are classified EXACT /
  CONSTANT OFFSET (a convention difference — state it) / INCONSISTENT (a
  defect in somebody's measurement — re-measure OURS in-emulator first).
  The sheet: `../community/vsav-framedata.xlsx` — 15 sheets = the 15
  vanilla characters (FE AN AU BI BU DE GA JE LE LI MO QB SA VI ZA; ~37-68
  moves each), per move `startup / active / recovery / on hit / renda on
  hit / on block / renda on block / throw tech / red damage / white damage /
  gauge whiff / gauge block` (AN adds gauge hit / cancel / guard);
  multi-hit actives as text (`2(4)3,2`, `3{(3)3}x6`); NO vs2 characters, no
  Oboro / Dark Gallon. **Sheet names = the first two letters of the
  JAPANESE character name (maintainer-confirmed 2026-08-31), mapped to our
  ids:** BU Bulleta `0x00` · DE Demitri `0x01` · GA Gallon `0x02` · VI
  Victor `0x03` · ZA Zabel `0x04` · MO Morrigan `0x05` · AN Anakaris `0x06`
  · FE Felicia `0x07` · BI Bishamon `0x08` · AU Aulbath `0x09` · SA
  Sasquatch `0x0A` · QB Q-Bee `0x0C` · LE Lei-Lei `0x0D` · LI Lilith `0x0E`
  · JE Jedah `0x0F` (the two to not confuse: LE = Lei-Lei, LI = Lilith).
  The webpage:
  https://mizuumi.wiki/w/Vampire_Savior/Reverse_Engineering ("arguably the
  best source of deep information on Vampire Savior") — BLOCKED for any
  fetcher by a bot challenge (WebFetch 403; curl with a browser UA gets the
  challenge page) — **RESOLVED 2026-08-31: the maintainer saved it as a PDF**
  (`../community/Vampire Savior_Reverse Engineering - Mizuumi Wiki.pdf`,
  74 pages; text extracted with `pypdf` in a scratch venv — poppler is not
  installed — to `../community/mizuumi_reverse_engineering.txt`, 74 K
  chars, 421 address tokens). Both sources stay out of the tree.
  **FIRST-PASS INVENTORY of the wiki page (14z-124; an inventory, NOT an
  adoption — nothing in the atlas changes until measured):** sections =
  the CPS2 memory map, the IVT, RAM maps by base (`$FF8000` globals, `$FF8280`
  stage/camera, `$FF8400/$FF8800` the player struct — CPS2 AND the PS1
  `MIPS 0x8D8400` mirror), graphics/palettes/raster matrices, ROM function
  and per-character data/function tables, per-character move
  "Conditions" (pp. 25-63), data structures, palettes, backgrounds, HUD.
  Method not stated (credits "Thanks Jed"; disassembly-shaped comments);
  region unstated — but `0x275CE` / `0x28D50` / `0x2246E` sit exactly at our
  vsavj addresses. Their player struct: 146 offsets, 52 also named in our
  `ram.md`, 94 only theirs (candidates), ~50 only ours. CONVERGENCES with
  our measurements: `+0x110/+0x111/+0x176` the vsavj DF fields (they name
  `+0x17B` "Dark Force Flight" — Huitzil's form), `+0x189` DF timer
  reduction, `+0x3B4` "CPU Opponent Flag"; and the 14z-123 advancing guard
  field for field under VS's OWN NAME, **Tech Hit**: `0x275CE` "Tech-Hit
  Checks", `0x28D50` "Tech-Hit Chance Tables" (our RNG table), `+0x170`
  Tech Hit Input Counter, `+0x171` Tech Hit Active State (0x10 frames — the
  consumer we never traced), `+0x1AB` Tech-Hit Timer, `+0x1B0` Push-block
  Push-back Timer, `+0x126/+0x127` Mash to Escape. DIRECT LEAD for the DF
  backlog item: **`+0x1B3` "Dark Force Startup"** and `+0x1B5` "Dark Force
  type-2 (HP+HK)" (we had read `+0x1B5` as set by JUMPING — a disagreement),
  `+0x147` "Invincibility Timer" (ours: the multi-hit re-hit gate —
  compatible), `+0x143` Throw Invulnerability Timer; ROM `0x26FD2` DF
  Activate / `0x2706E` DF Deactivate bracket our activation body `0x027000`.
  DISAGREEMENTS to measure: `+0x161` "Oboro Fight Flag" vs our live-measured
  Sasquatch DF accumulator (`audit_df_accumulator`, 9 frozen lines — ours is
  a measurement, theirs a name; the byte may serve both); `0x2246E` "System
  Timer Reducers" vs our "class-0xFF block handler" (14z-123). Naming to
  adopt after measurement: "Tech Hit" beside "advancing guard". **BOTH
  RESOLVED 14z-126 (the opcode listing): `0x2246E` IS the System Timer
  Reducer (one `subq.b` per tick on `+0x147/+0x174/+0x143/+0x158/+0x1AB`);
  the block window is OPENED by the block-entry handler `0x2395A`-`0x23966`
  — 14z-123's write tap had named the decrementer, corrected in `ram.md`,
  engine_internals and `test_advancing_guard.sh`; and `+0x161` is a
  per-character DF WORK BYTE written by Sasquatch's (the measured
  accumulator), Bishamon's, Anakaris's and Aulbath's handlers — mizuumi's
  "Oboro Fight Flag" is Bishamon/Oboro's use of it: both names true. Four
  wiki rows adopted into `ram.md` with the mechanism measured or read
  (`+0x134`, `+0x145`, `+0x143`, `+0x1B3`); the other ~90 candidates stay
  unadopted [C].**

- **ZABEL j.LK PROXIMITY GUARD — A LEGACY-CONTENT PATCH, ITS OWN SESSION
  (maintainer, 2026-08-30, 14z-122). RULED as the SECOND of two future items;
  not started.** The maintainer's report, in substance: Zabel's j.LK does not
  trigger proximity guard properly — "afaik it does, but not all the time it
  should, and definitely unlike any normal of any character". The ask: a
  SURGICAL patch for BOTH vanilla vsav and the WIDE build that corrects this
  and nothing else — no side effects. What that implies for the session that
  takes it: (1) it is a deliberate change to LEGACY behaviour, so by
  definition outside the superset invariant's "untouched" set — it needs its
  own ratified expectation class and its own build flag (CLAUDE.md §1/§4; a
  stock `vsav` patch is a NEW track, not the stock twin); (2) [VSP-20]
  first — a hand-played MAME recording of the whiff BEFORE any theory;
  (3) [VSP-14] — archaeology on "proximity guard" across STATE_HISTORY and
  the engine docs before measuring; (4) measure vanilla's proximity-guard
  test against every other normal (the maintainer's own comparison class)
  so the fix is bounded by a measured difference, not an impression.
  Recommendation: a data-side fix on Zabel's j.LK record (the guard-range or
  a record flag) if the difference is in his data; a code-side change only if
  the engine special-cases the move. Nothing decided beyond "its own session".
- **THE LIVING-DOCUMENTATION EFFORT, and the option it creates (maintainer
  direction, 2026-08-24). STARTED 14z-135 (2026-09-06): scope
  `docs/project/living_docs_scope.md`; RULED at the plan stage the same day
  that it takes ALL THREE forms put to the maintainer — a rendered navigable
  site, routing enforcement in the markdown, fact tables with provenance —
  in the order L1 routing → L4 site → L2 fact census → L3 ROM re-derivation,
  AFTER the harness slices and the harness skill.** ~~Recorded as DIRECTION,
  not as a task — nothing is scheduled and MiSTer stays the current arc.~~ In their words: an important
  documentation effort is coming, "not replacing your logs, but creating a
  living documentation that can easily be referenced by you or me, doesn't go
  stale or lost in a statistically never read file." The SailorMoonS project's
  documentation AND WORK DISCIPLINE are the reference; formats, document types
  and visualisations are to be chosen as the best fit for THIS project rather
  than copied. Motivation: the emulator side is now essentially fully mapped.
  **The option it opens:** after the MiSTer core is finished, potentially
  "go back to the canvas, with all the documentation, and redo the project
  from the docs, because it might create a cleaner, more consistent extended
  codebase." Explicitly a possibility to preserve, not a commitment.
  **Two things worth holding on to when it is scheduled:**
  1. **Staleness is defeated by ENFORCEMENT, not by format.** What keeps the
     SMS docs alive is `tools/checkdocs.py` re-deriving documented addresses
     from the cartridge, `--check` modes on every generator, `health.sh` in
     CI, and the rule that no number reaches a doc without a run that produced
     it in that session ("an unquoted address is a claim nobody can falsify").
     The prose should be shaped so it CAN be checked. Being lost in an unread
     file is a SEPARATE problem with a separate fix — routing: "if you want to
     know X, read Y" tables at every entry point, and every synthesis document
     naming its journal twin and vice versa.
  2. **A rebuild here is unusually provable, and its feasibility is
     MEASURABLE TODAY.** The harness compares ROM BEHAVIOUR, not source
     structure, so a rebuilt artifact has a real acceptance test that already
     exists: bit-identical to vanilla on the legacy corpus, field-identical to
     the current build on tenant content, same replays, same frozen
     expectations. What decides it is not the docs but **how much of the build
     is DATA versus CODE** — the artifact encodes hundreds of measured facts
     (reconciliation rows, planted tripwires, pc-rel escapes, the ~70 re-point
     defaults, the op-count freezes), and a rebuild that does not carry them
     re-pays every debugging session that produced them. CLAUDE.md rule 5
     already requires behavioural values to live in documented tables rather
     than in code, so feasibility is essentially the degree to which rule 5
     has been honoured — which can be MEASURED rather than estimated.
     RECOMMENDATION when the effort is scheduled: make the first structural
     deliverable the EXTRACTION of measured facts from manifests/generators
     into reviewable tables with provenance. It makes the current codebase
     auditable whether or not the rebuild happens, and it is the precondition
     that turns the rebuild from a hope into an option.

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

**[VSP-23]** Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.

## Open bugs

- ~~**WIDE sprite garble (14z-60y)**~~ **FIXED 2026-08-05 (14z-61).** Not a
  rendering defect: the shipped WIDE romset carried group C as byte copies
  of the stock group B, so those copies held group B's CRCs and the loader
  — which resolves by hash before name — served PRISTINE tiles for the
  members the build had patched. Fixed in the pipeline (shippable overlay
  zero-filled, canary romset separated, `tools/audit_romset_identity.py`
  wired into the build), verified on both emulators with pristine and
  stock-track controls, and gated by `tests/test_wide_render_content.sh`
  (pixel A/B vs the stock track + a positive control) and
  `tests/test_romset_identity.sh`. Full write-up: session 14z-61.
  **CLOSED — maintainer playtest of `build/m5_wide` (`9bac6ee3`) confirms
  it**, with and without Donovan: no regression, graphics good, gameplay
  genuine, sounds good.
- ~~Minor win-screen palette issues~~ **FIXED 14z-68m** (build/hui11):
  the palette source is the OPCODE-view remap table, and the portrait
  position row needed vs2's own values. Gate: `tests/test_hui_winscreen.sh`.
- **OPEN (cosmetic):** win QUOTE TEXT — **all THREE tenants still show their
  SHELL's quote** (corrected 2026-08-27 by the maintainer; this entry used to
  say "Huitzil's", which understated the scope). Root-caused, not built: the
  first-level table at the quote bank base ALIASES its variant half
  (`0x10->0x00`, `0x11->0x01`, `0x13->0x03`) — *corrected 14z-116: this entry
  said "consumer bias `lea -4(a0,d0.w)` -> reads index `0x60+id-1`", which is
  the 14z-73 reading of the PORTRAIT fetch and was retracted in
  `engine_internals.md` the same session; it is not the quote mechanism.*
  MEASURED 14z-116 (see the session entry and the win-quote entry in
  `DECISIONS_HISTORY.md`, moved there 14z-134): a
  data-only fix is impossible, the relocation perturbs legacy work RAM, and
  ~330 glyph TILES have to travel. NOTE the
  win-quote ART is already native and complete (14z-62e/62j, group C bank 5) —
  what remains is the TEXT. See the cosmetic backlog below.
- ~~**GitHub #114 — 421+P**~~ **CLOSED BY THE MAINTAINER 2026-09-02T17:53Z.
  THEIR VERDICT, verbatim, and it is a GAMEPLAY RULING that must not be
  re-opened as a defect:** *"Ceilings are the same, mash rate required slightly
  under VS2 for everything but LP, which is not a bad thing given how stringent
  VS2 is for max damage (max number of hits requires well above average
  mashing, it is legitimately very hard), LP is short one hit and comparatively
  slightly nerfed, which is acceptable on the whole, especially given the
  additional bit of leniency for other punch strengths. Close enough, leverages
  VS engine, good tradeoff, closing the ticket."*
  **SO THE LOWER MASH REQUIREMENT IS AN ACCEPTED POSITIVE, NOT A NEUTRAL
  FACT** — VS2's maximum is legitimately very hard to reach, and the host
  clock making ours slightly more forgiving is a good trade. Anyone re-reading
  the §5 numbers should read them that way. Detail of the investigation
  follows (PREMISE REFUTED, SCOPE MEASURED, MASH MEASURED — 14z-127,
  2026-09-02).**
  **(a) THE ISSUE'S EVIDENCE WAS JEDAH.** Replay 48's P1 path (`U,U,R` → slot
  `0x0F`) selects Donovan only on the SUBSTITUTED stock track; since the
  14z-115 wheel separation a WIDE build puts the tenants on their own appended
  row, so that path lands on vanilla **Jedah** (`+0x60 = 0x000b0d2e`) and the
  "3 hits / 11 damage, victim pushed 728 → 852" filed as ours was his 421+HP.
  Pristine `vsavj` reproduces it to the frame and is now the gate's must-fire
  control. **The confound check in the issue was sound and still could not see
  it: positions WERE identical until contact, because Jedah and Donovan stand
  at the same x. A position check establishes SPACING, never IDENTITY.**
  **(b) MEASURED AGAINST NATIVE, all four strengths, no mash, both tracks:
  LP 3h/7d · MP 5h/9d · HP 6h/10d · ES 9h/13d — OURS EQUALS NATIVE IN EVERY
  CELL**, victim held throughout, P1's identity asserted from `bases.tsv` on
  each. Gate `tests/test_don_immortal_native.sh` (native measured in-run).
  **(c) THE FRAME-CADENCE GAP IS THE HOST ENGINE'S, NOT THE PORT'S.** Our
  deity ticks run ~1 video frame slower per ~11 engine ticks. **Controlled on
  VANILLA content: Victor, Demitri, Morrigan and Bishamon mirrors, forced
  picks, identical inputs — the hit-freeze `+0x5C` = 11 drains in 9 video
  frames on vsav2 and 10 on vsavj for ALL FOUR.** vsavj runs fewer engine
  double-ticks per video frame than vsav2. A ported character cannot tick at
  vsav2's frame rate without ticking unlike every other character in the game
  it now lives in. Frozen as section 4 of the gate.
  **RULING (maintainer, 2026-09-02): "we must respect the fact that we are
  porting the character to a different engine and the engine, being vanilla
  vsav, takes precedence."** So the gate asserts HIT COUNT and DAMAGE — the
  quantities the host clock does not set — and never vsav2's frame numbers.
  **(d) MASHING — MEASURED AND CLOSED (14z-127).** Mash extends the node loop:
  each new press adds 1 to the MASH ACCUMULATOR `+0x0A` (gate: `+0x126 &
  0x770F`), and when the deciding routine finds it at **>= 7** it spends one
  unit of the ITERATION BUDGET `+0x27` — **the per-strength cap, and it is
  DATA: 2/3/3/4 for LP/MP/HP/ES, identical in both games.** Verified identical
  at three levels: the 94 chain nodes (every non-pointer field; every link
  relocated by the port delta), the deciding code (vs2 `PRG:0x059EEA` vs ours
  `PRG:0x0C00FA`, instruction for instruction, only the `jmp` relocated), and
  the budget's start value.
  **AT THE TRUE INPUT CEILING MP/HP/ES EQUAL NATIVE EXACTLY** (8/12, 10/14,
  15/19); **LP is ONE HIT SHORT (4 vs 5)** — hit PHASE: ours' last hit lands ON
  the decision node, its freeze holds that node, and the loop re-entry skips one
  node, costing one hitbox window. **RULED (maintainer, 2026-09-02): within
  "altered by the VS engine", NOT chased** — the alternative is a one-frame
  phase change on a shared path, the trade the superset invariant exists to
  refuse. Frozen as §5 of the gate, LP asserted exactly so a move either way
  fails.
  **THE MEASUREMENT TRAP THAT COST THE MOST, now a gotcha:** a one-frame-on /
  one-frame-off mash is HALF the ceiling (the release frame is dead);
  alternating buttons EVERY frame is the ceiling. Below it the two legs sit at
  different points of the same response curve, because the host clock changes
  presses-counted-per-check — which manufactured a reading of "ours never
  extends LP and over-extends HP/ES by 2" that the ceiling erased. Ruled out
  along the way: `+0x12e` (saturates at 3) and the `$FF8058` input mirrors.
  **THE GATE IS A FREEZE-BATTERY LEG (3f) — RULED MANDATORY AT RELEASE
  (maintainer, 2026-09-02): "it's mandatory and cheap whenever we want to
  release a version."** ~15 min, the longest leg of `run_battery_m2.sh`, and
  the only one that MEASURES NATIVE instead of asserting a remembered constant.
  **WHAT THE ISSUE GOT RIGHT:**  **WHAT THE ISSUE GOT RIGHT:** the provenance criticism was fair —
  `native == 10` did enter `test_don_reactions.sh` as testimony (STATE
  14z-42c). It is correct, and is now measured in-run. 14z-42's cadence root
  cause and 14z-43's dispatch fix stand untouched.
- **OPEN:** FG pacing — untouched.

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

### THE COSMETIC BACKLOG (parked, 2026-08-27 — the maintainer's own list)

Ruled a single later pass over "the purely cosmetic things that remain related
to the port", opened when #112 was accepted as cosmetic. Nothing here is
scheduled, and none of it is competitive-2P surface (see the standing
"cosmetic is optional" scope: cosmetic + single-player-only surfaces are
nice-to-have). Collected so the pass does not start from a blank page:

| item | status | what is known |
|---|---|---|
| **Win-quote TEXT for all three tenants** (each still shows its shell's quote) | **FORGONE FOR NOW (maintainer 14z-116); parked WITH A CONSTRAINT — if ever done, the CLEAN way only, vanilla untouched** | the first-level table aliases the variant half; a data-only fix is IMPOSSIBLE (zero free bytes at either hop, re-derived by `tools/scan_quote_window.py`), the bank relocation perturbs `RAM:$FFF230` on legacy win screens, and ~330 glyph tiles must travel. Art side already native (14z-62e/62j) |
| **Arcade ladder OPPONENT-ROULETTE TAG for a tenant opponent** (1P, tenant-plays-1P only — the CPU draws a tenant only on a tenant's ladder row) | measured 14z-123, not fixed | the tag shows the BASE character's name and mini-art (Phobos `0x10` → "BULLETA", a 4-bit-folded consumer, PC not attributed) drawn in pool row `PRG:0x3A3CA0 + id*32`'s own colours (a brown ramp for `0x10`; `0x13` is a grey ramp). The VS screen itself is correct (pixel-identical to the 2P path). Fix shape if ever wanted: author three pool rows (`0x3A3EA0/0x3A3EC0/0x3A3F00`, 32 bytes each, in a table vanilla never indexes past `0x0F` — legacy-invisible by construction) plus un-fold the tag's name/art consumer (its own measurement). Gate `tests/test_ladder_tenant_vs_palette.sh` |
| **Arcade ladder MAP NAMES and PICTURES** | not investigated | the map screen is the one that follows the win screen (a documented rig trap, STATE_HISTORY 14z-99); stage banners decode via `tools/decode_stage_banners.py`, venue byte `$FF8100` |
| **Character SELECT WHEEL polish** | not investigated | the wheel is functionally correct and emulator-identical; this is look-and-feel only. Layout facts in `docs/game/atlas/select_screen.md`, the 21-cell roster and its inbound edges |
| ~~**PYRON'S MEDALLION WHITENS on the select screen**~~ **FIXED 14z-116** | **FIXED and FROZEN 14z-117** as merged-m12 (`build/m3b_merged19` rebuilt with the M10 mark, `cde712e1`; the 14z-116 candidate was `af21bc88` under M9 — same bytes) | **The long-parked residual is closed, and it was never the accent march.** WRITE-TAP ATTRIBUTION (16 word writes, PCs `0x3FFC60-0x3FFCA6`) named **our own 14z-62k sword thunk** at `PRG:0x05F9D0`: its P2 branch wrote `0x90C340` = row `0x1A`, which is also Pyron's medallion row. Not Donovan's portrait (the 14z-87b supposition), and not the marcher — the marcher was already neutralised for `0x16/0x19/0x1A` in 14z-64. **Maintainer chose the fix from three options (2026-08-28): drop the P2 write.** `tst.b $381(a4)` now `bne`s to the pop/rts, two NOPs replace `adda.w #$60,a1` — same byte count, no allocation ripple. **ACCEPTED TRADE, field-observed 2026-08-29 (and NOT what I predicted):** the P2 sword does not revert to grey — it draws with whatever row `0x1A` holds, which is now Pyron's medallion palette, so its pixels go from steel blue-white `(153,170,221)` to orange-gold `(255,136,34)` and, on Donovan's own gold-and-red costume, read as the sword being ABSENT. The grey ramp was the PRE-62k state, before a medallion lived in that row. **A partial fix is IMPOSSIBLE (measured): sword and medallion draw from THE SAME entries of row `0x1A` — 23 shared colours — so the row cannot be split by pen.** **VALIDATED ON THE BOARD (maintainer, 2026-08-29): "Confirmed, the sword is
actually orange, and only on the select wheel screen, this is a good
tradeoff. The fix is validated."** The scope confirmation matters as much as
the verdict: the trade is CONFINED TO THE SELECT SCREEN — no in-match
surface — which is what the thunk's site (`PRG:0x05F9D0`, the select figure
uploader) predicts and the board now measures. MEASURED: row `0x1A` holds Pyron's vs2 palette across the whole select with P2 on Donovan; P1's accent on row `0x17` byte-for-byte unchanged; **`38_victor_p1_vsavj`, `05_timeout_idle` and `63_idle_select` BIT-IDENTICAL to merged18** (the changed path runs only on a P2 tenant hover, which no legacy replay does) — note `38` is the exact replay whose one-main-loop slip forced the 14z-88 revert of the previous attempt. Gate: **`tests/test_pyron_medallion_2p.sh`**, two legs, verified to FAIL on merged18 and PASS on merged19. **It closes a real coverage gap:** `test_wheel_bank5` 3b's two protocols are both SINGLE-PLAYER, so it could never see this and stayed green through every freeze. **NOT FROZEN — a freeze is a separate decision** |
| **#112 Press of Death black foot** (Donovan's EX foot super) | **ROOT-CAUSED 14z-126b; FIX RULED (C) DO-NOTHING (maintainer, 2026-09-02) WITH OPTION (B) EXPLICITLY KEPT OPEN for the future — see the three #112 entries in `DECISIONS_HISTORY.md` (moved 14z-134)**; DECIDED cosmetic, parked; **maintainer 2026-08-28: too risky for a small cosmetic gain** | whole draw path measured VANILLA. ~~why a tenant runs that vanilla sequence is unknown~~ **REFUTED 14z-126b: it does NOT run one** — at every instance on merged-m14 the drawing objects' `+0x1C` point into Donovan's PLACED region and no work-RAM field holds a vsavj record pointer (positive control fired 15/15); `0x28394E` is never stored anywhere (all 7 candidate sites disassembled to instruction-boundary noise); and all 9,755 tenant sprite pointers are relocated (now gated). WHAT REMAINS: the records' TILE CODES — the effect map's coverage, the builder's own "render garbled, never crash" note. The BLACK case does not reproduce on the current build (needs a rebuild from `freeze/merged-m9` or a fresh recording) |
| ~~**RANDOM SELECT should include the three tenants**~~ — ADDED TO THE LIST by the maintainer 2026-08-28; **BUILT 14z-117 at the maintainer's word ("do the random-select includes the tenants then"), gated (`test_random_select_tenants.sh`: draw = 15 vanilla + this build's tenants; confirm on a tenant frame loads the tenant's own record; must-fire control), frozen as merged-m13 (M11); FIELD VERDICT GREEN on the board (maintainer, MiSTer, 2026-08-29, STATE 14z-118)** | DONE 14z-117 — TWO sites, not one: the walker re-reads the table on its non-tick frames (`select_screen.md` "THE WALKER HAS TWO PATHS"); a bound-only thunk crashed the figure refresh with a code byte as id | the "?" cell walks a FIXED 15-entry table at `PRG:0x020C88` (`04 07 02 0C 05 0F 0A 00 0E 03 08 01 0D 09 06` = the base-half roster minus `0x0B`), 3-frame cursor, wrap `cmpi.b #$f`. Both bounds hard -> a tenant can never come up. **The siblings are the precedent**: vsav2's twin table (`PRG:0x01F8B4`) lists `10 11 13`, vhunt2's too — including the newcomers is what the source games do. FIX SHAPE: 18-entry relocated table + bound `#$f` -> `#$12`; it cannot grow in place (15 bytes + 1 pad, then code at `0x020C98`) and the table is read PC-relative, so it is a `site_thunk` on `PRG:0x020C80` + a `code` op, not a data poke. COST TO WATCH: the added cycles land on the select screen, whose legacy replays are already the bounded-window class — measure the onset before and after |
| **MARIONETTE — a vs2 character, PARKED UNTIL FURTHER NOTICE (maintainer, 2026-08-28)** | not ported, not planned | **Assets live in VS2, not in VS.** She is not in Vampire Savior at all, so nothing in our romset is missing or broken by her absence. The maintainer's framing, and it is the right one: **Marionette and Shadow are both just MIRROR-MATCH MECHANISMS** — the shared machinery at `PRG:0x009BB2` copies the opponent's id and palette, so "playing as" either is playing the opponent's character. That makes porting her a low-value item: it adds a second route to a mirror match, not a character. **Not before everything else.** If it is ever revisited, note that vs2's arming counter is the SAME single `#$5` check as vsavj's (`PRG:0x01F8D6`), so whatever arms her in vs2 is a different mechanism and has not been located |
| **Oboro's intro eats into the round** | **DECLINED by the maintainer 2026-08-28 — do NOT delay round start or cut the intro** | recorded so it is not revived: it would be a match-state TIMING change on a shared path for a cosmetic reason, which is the trade the superset invariant exists to refuse. The maintainer will instead check whether vsavj's Oboro has an alternate SHORT intro |
| ~~(#113 first-down white-out)~~ **CLOSED 2026-09-01** | **not ours** — vanilla in vsavj AND vsav2, and the board agrees | the maintainer's MiSTer check came back consistent and they closed GitHub #113 the same day. Mechanism (palette RAM vs CPS-B layer register) still unmeasured — an honest boundary, not an open item |

**THE ARCADE HIDDEN-CHARACTER ROSTER — CONFIRMED BY THE MAINTAINER
2026-08-28.** Exactly THREE exist in the arcade game: **Oboro Bishamon,
Dark Gallon and Shadow.** *(First stated as four including Marionette, then
corrected by the maintainer within the hour: **Marionette is a Vampire
Savior 2 character, not a Vampire Savior one**, and the "7 START presses"
code belongs to vs2. Recorded because the ROM agreed with the correction
before it arrived — see the Shadow row.)* *The alternate Lilith, Aulbath and
Victor are CONSOLE-PORT ONLY* — which independently confirms the 14z-116
table measurement (the only variant datasets in any of the three ROMs are
our three tenants plus two Oboros; there is no Lilith/Victor/Aulbath
alternate anywhere). Status of each on our build, all measured 14z-116:
- **Oboro `0x18`** — shipping, ours, gated (`test_oboro_select.sh`), field-confirmed 14z-105. **CAUTION for the maintainer's floated idea of removing the hold-START hook "since Oboro and Dark Gallon were already in VS" (2026-08-28): that is true of DARK GALLON and NOT of OBORO.** Measured 14z-116: the only immediate writes of a character id in vsavj are `0x02`, `0x04`, `0x0B` and `0x12` — **no vanilla path anywhere writes `0x18` to `$382`.** vsavj ships Oboro's DATA complete (record `0x0B3450`, own palette block, 20 distinct bank rows) but no player-facing select path, which is precisely why 14z-105 added one. Removing the hook would make Oboro UNREACHABLE again; Dark Gallon would survive untouched, since that path is vanilla's own.
- **Dark Gallon `0x12`** — vanilla's own path (Gallon + START + 2-3 punches *or* 2-3 kicks, `PRG:0x020B9C`); our Oboro hook displaces that block's first instruction and re-executes it, so it is preserved BY CONSTRUCTION. Statically certain, **never played** — the maintainer is field-testing it.
- **FIELD VERDICT ON M9 (maintainer, MiSTer, 2026-08-28): "everything seems
  right... the new character wheel already looks almost perfect on CRT,
  Shadow works as intended, Dark Gallon is properly selectable with hold
  start + 3 punches at the same time. All seems perfectly fine."** So the
  E2 wheel is CRT-confirmed, Shadow is confirmed working on silicon, and
  **DARK GALLON IS CONFIRMED PLAYABLE** — which also validates the 14z-116
  static decode of `PRG:0x020C18` (the trigger accepts `0x300`/`0x500`/
  `0x600`/`0x700`, i.e. two OR three punches; the board used three).
  **TWO THINGS HE COULD NOT TEST IN ~2 HOURS OF TRYING, AND BOTH ARE
  STRUCTURALLY IMPOSSIBLE — the time was spent on things that cannot
  happen. Measured, so nobody spends another two hours:**
  1. **A tenant from RANDOM SELECT.** Already measured this session: the
     "?" draw is a fixed 15-entry table (`PRG:0x020C88`) holding no
     variant-half id, bound `cmpi.b #$f`. It is not luck, it cannot occur.
  2. **SHADOW vs a tenant, in 1P arcade.** NEW measurement: scanning ladder
     table A (`PRG:0x00B268`, 36 rows x 8 groups, reachable indices 0-5 —
     the scan bound `$FF8138` is 6) for a tenant candidate returns **rows
     16, 17 and 19 ONLY — i.e. classes `0x10`/`0x11`/`0x13`, the tenants'
     own rows.** A tenant appears as a CPU opponent *only when the player is
     a tenant* (which is exactly the shape of the #99 field crash: Donovan
     1P -> CPU Phobos). **Shadow's own pool is rows 32-34** (`0x800 +
     $3BD*8`) **and contains no tenant in any group.** So Shadow can never
     draw one from the ladder, however long you play.
  **HOW TO TEST IT ON THE BOARD:** 2P VERSUS — P2 picks the tenant with the
  sticks, P1 does the Shadow code. That is exactly what the emulator rig
  does (`tests/replays/113_shadow_vs_tenant.rpl`), and it is the only route
  either implementation has to that matchup.
  **-> DONE, AND GREEN (maintainer, MiSTer, 2026-08-28): "Shadow works
  perfectly even with the VS2 tenants in 2P vs, so that's a win."** The
  board agrees with the emulator leg on the one case that mattered, so the
  Shadow-vs-tenant question is CLOSED on both implementations.
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
- **TENANT CPU AI LOOKS "LACKLUSTER" — maintainer observation (2026-08-28),
  UNPROVEN, DEPRIORITISED.** Verbatim: *"when I do fight against any of the
  VS2 tenants it seems their AI is lackluster to say the least and I'm
  pretty sure that's a side effect of the port although I can't prove it...
  but once again, we're 2P vs focused."* Recorded rather than investigated,
  with the archaeology a future session would start from so it is not
  re-derived: the four per-class AI action-script tables
  (`PRG:0x0BF01A/09A/11A/19A`) are **16 classes THEN THE SAME 16 REPEATED**
  (Capcom's aliasing guard), which is what made CPU-Phobos play DEMITRI's
  AI and was the root cause of #99; 14z-111 fixed it by making each
  tenant's OWN vs2 AI script block a data root (option A, zero code). So
  the tenants do have their own scripts now — but whether those scripts are
  as *deep* as a legacy character's on this engine has never been measured,
  and "feels weaker" is not a measurement. **If it is ever picked up, the
  first question is whether the ported script blocks are COMPLETE** (a
  truncated block would present exactly like this), not whether the tables
  are aliased. CPU-side only — 2P versus never reads them ([VSE-75]).
- **SHADOW vs A TENANT — MEASURED AND GREEN (14z-116).** The maintainer's
  question ("the big problem is not selecting him, it's knowing whether the
  game breaks", INCLUDING "does Shadow take the SHELL character instead of
  the tenant") was answered by a RUN, not by disassembly. Rig:
  `tests/replays/113_shadow_vs_tenant.rpl`, gate `tests/test_shadow_tenant.sh`
  (emulator tier, ~6 min, two runs, must-fire control). **RESULT: Shadow
  takes the TENANT.** P1 armed the code (5 START presses on "?"), beat P2
  Donovan, and at the round end flipped `0x00 -> 0x13` with the loader
  installing **Donovan's own record `0x003FA9D0`** — not Victor's
  `0x0009769E`, the shell `0x13` aliases, which is exactly the quiet failure
  the gate is written to catch. HUD reads "Donovan", art is his, and the run
  is **guard-clean END 21120** across several further morphs.
  **TWO CORRECTIONS TO MY OWN EARLIER STATIC PASS, both from this run:**
  (1) `PRG:0x009BB2` is NOT match init — it is the ROUND/MATCH-END path
  (`$13A`/`$13C` are the winner/loser pointers), so **Shadow does not keep a
  pick, he takes the character he just beat, round by round**; (2) arming
  alone leaves you playing the roulette's pick rendering NORMALLY (measured:
  Bulleta, no silhouette), so what produces the black-silhouette
  presentation on this Japan set is still unestablished — it blocks nothing.
- **Shadow** — present and vanilla: exactly 5 START presses on the "?" cell then any attack button (`select_screen.md`), which matches the community code instruction for instruction. The mechanism copies the OPPONENT's id and palette **UNMASKED** at `PRG:0x009BB2`, and every table the copied id then indexes is 32 rows with our tenant rows populated, **so Shadow-copying a TENANT is structurally expected to work**. Never run — this is the `coverage_matrix` "morphing INTO a tenant" cell, and it now has a mechanism attached rather than an unknown.


## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
