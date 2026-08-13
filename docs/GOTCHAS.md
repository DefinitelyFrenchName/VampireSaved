# GOTCHAS — index

The entries live in three files, split 2026-08-08 by one question:
**would this still be true if we abandoned the roster hack tomorrow?**

| file | what is in it |
|---|---|
| [`game/gotchas.md`](game/gotchas.md) | Vampire Savior itself — engine behaviour, data layout, modes that fail quietly |
| [`platform/gotchas.md`](platform/gotchas.md) | CPS-2 hardware/encryption + MAME and FBNeo behaviour and builds |
| [`project/gotchas.md`](project/gotchas.md) | our pipeline, harness, gates, manifests and method |

**Appending a new one:** put it in the file its FACT belongs to, not the
one your current task belongs to. A trap you hit while porting Huitzil
is a GAME gotcha if it is true of the game regardless of the port.


## Game — Vampire Savior (`game/gotchas.md`)

- OBJ record formats differ in ENTRY STRIDE, not just header meaning
- Loop-count idioms differ per handler: subq-before-dbra means COUNT, not count+1
- "Slot-indexed cell" does not mean "slot-exclusive data" — three surgery traps
- The sibling-coincidence gotcha, third strike: the global coordinate pool
- Same-value class #4: A5-relative work-var displacements
- The companion overlay draws the HOST's records (sword/statue blink)
- The attract INTRO CUTSCENE is Jedah — per-char display sites are legacy surface
- The per-char strip zone interleaves the SHARED MUSIC POOL
- Per-char table entries are PAIRS more often than you think
- In the engine hit-spark spawner, a1 is the VICTIM, a6 the attacker
- Anim numbers: facing adds 0x300; set-anim QUEUES, display resolves
- OBJ-RAM diffing: entries move every frame, stale tails linger, dumps and taps CAN legitimately disagree
- The electric-hit DARKEN displays never-rewritten OBJ buckets — and effect windows need ODD-frame sampling
- "This char's band is free once the char is replaced" — NO: bands hold SYSTEM-REFERENCED tiles too
- Record walks that follow POINTERS miss offset-computed records
- Palette rows 0x10+ belong to the P2 CHARACTER — attribute rows with a roster-varied control, not a same-roster control
- Hit-freeze constants are ENGINE-GENERATION tuning, not ported data — sibling-verified structure can still drift behaviorally
- Venue-asset numerology: palette index ≠ character id; identify cells by MEASURING the cursor, not by suggestive constants
- The per-char OBJ bank word is NOT a display-only attribute
- TABLE A's shape cannot tell U/D from L/R — the direction labelling needs an external fact
- An 0xFF inside a LIVE select-wheel row is committed as character id 0xFF
- There is no such thing as a free palette row on a venue screen (14z-63)
- A WATCHDOG REBOOT masquerades as a clean "nothing happened" (14z-65)
- The content-twin trap: vsavj keeps byte-identical copies of engine code inside per-char families — hook the LIVE one, found by tracing
- Sampling a STATE-gated effect at the wrong moment reads as "not reproduced" (14z-68u)
- A MODE-gated symptom needs the MODE PROVEN ENTERED — pressing the input is not entering it (14z-69, cost this session twice)
- The two games' sprite-list handlers do NOT agree: a per-handler CODE BIAS differs between vsav and vs2 (14z-71)
- A VARIANT ALIAS ROW holds a value vanilla uses — that does not make the SLOT used (14z-76, deferred a fix for two sessions)

## Platform — CPS-2, MAME, FBNeo (`platform/gotchas.md`)

- CPS-2 ROM file byte order is NOT 68k logical order (paid: 2026-07-25, ~1h)
- MAME `logerror` output needs `-log`, not `-verbose` (paid: 2026-07-25)
- FBNeo fresh builds need `SKIPDEPEND=1` (paid: 2026-07-25)
- FBNeo shared EEPROM breaks run-to-run determinism (paid: 2026-07-25, ~45min)
- MAME `-debug` perturbs multi-CPU timing — never compare its checksums to non-debug runs (paid: 2026-07-25, ~1.5h)
- PC-relative reads are DECRYPTED reads on CPS-2 (paid: 2026-07-25, ~45min)
- CPS-2 gfx simms are not tile-contiguous — naive slicing silently "works" on siblings only
- MAME breakpoint logging is a SAMPLER, not an inventory
- Debugger stops DESYNC replay frame counting
- CPS-2 program zips store CODE encrypted — static byte reads of code are noise
- MAME Lua write taps are silently dropped on handler re-install
- OBJ RAM dumps span BOTH pages — filter by code range and you will blame the wrong drawer
- PC-relative reads are PROGRAM-space; (An)-based reads are DATA-space — absolutizing a pc-relative table read on CPS-2 reads CIPHERTEXT
- A 68k move.l reaches a memory tap as TWO word writes — a tap keyed on the entry base sees only the (zero) high word
- OBJ y-word bit 15 is the sprite-list TERMINATOR, not a spare bit
- A MAME Lua tap installer must guard against its own change notifier
- FBNeo's d_cps2.cpp is not valid UTF-8, and SKIPDEPEND hides driver edits
- FBNeo harness: no video means the sprite path never runs, and stdout is captured to the sandbox log
- FBNeo matches zip members by CRC — a mismatch loads 0xFF FILL and still prints "(OK)"
- A MAME watchpoint logs REGISTERS, not the value written — use FBNeo's value tap when the question is "what went in" (14z-76)
- MAME's build system cannot handle a SPACE anywhere in the source path
- rsync `--exclude 'build/'` also excludes `scripts/build/`
- MAME 0.288's OSD is SDL3 and it is found ONLY through pkg-config
- A SOURCES-filtered MAME build silently omits drivers missing from mame.lst
- `src/mame/mame.lst` contains no inline comments — do not add the first
- MAME's "-video none" STILL creates a window that can take focus — and host keystrokes are injected into the EMULATED controls
- The CPS-2 encrypted range is INCLUSIVE of its upper word — 0x100001, not 0x100000 (measured 14z-59k)
- Ported CODE above the encryption window is stored RAW, automatically
- MAME write taps must be WORD-ALIGNED
- FBNeo's SDL frontend has NO `-rompath` — the flag is silently ignored
- A member carrying another member's PRISTINE bytes SHADOWS it — both emulators resolve a ROM entry by HASH before NAME
- Dump a tile band WITH its bank bits, or you will exonerate the guilty
- MAME cross-driver VIDEO_OUT checksums are NOT comparable (14z-62d)
- A chained rompath makes MAME a LIAR about member identity (14z-62h)
- Unconditioned breakpoints DESYNC replay input — the trace measures a screen the replay never left (14z-63)
- In-code pc-rel WORD JUMP TABLES read through the OPCODE view; byte/data tables through the DATA view — both live inside the encrypted range (14z-68)

## Project — our pipeline and method (`project/gotchas.md`)

- Sibling-coincident engine refs are INVISIBLE to the diff oracle — and the coincident vsavj address is usually a WRONG routine (paid: 2026-07-27 sessions 11c-12, ~a full session across three playtest rounds)
- Pre-seeded from the ROM-audit round (2026-07-25, before repo existed)
- Cross-emulator replays: same inputs ≠ same content (paid: 2026-07-25, ~2h)
- Bare-long "pointers" in code are usually operand pairs — sibling-veto them (paid: 2026-07-25 session 7, ~3h incl. diagnosis)
- Engine hooks on hot paths break whole-RAM legacy comparison — by construction (paid: 2026-07-25 session 7, ~2h)
- PC-relative word tables are DATA — never let a pointer heuristic rewrite them (paid: 2026-07-25, ~1h)
- Early-session generic rows can masquerade over later-understood structures
- Per-record BANK attribution: the effect-tail triage has no bank column
- Blind long-relocation over ported data blobs corrupts streams
- GFX and coordinate data are INVISIBLE to every RAM-basis gate
- Mid-frame transients and perturbing probes (win-palette post-mortem)
- Never write an unverified gap (the Felicia wall-jump lesson)
- Disabling a heuristic CLASS wholesale can revert load-bearing writes
- The RAM gate cannot see NEW-CHAR visual wrongness — pixel A/B is the tool
- Sibling twins can differ by ONE hoisted instruction — codebyte-matching lies
- "Run once at match start" is a TIMING TRAP — use a match-active countdown
- Phantom fixes: validate against the USER'S repro, at the RIGHT frames
- Cross-game A/B pixel comparison: align by DISPLAYED RECORD, not frame
- Pipe a build tool through tail and a crash packs STALE artifacts
- A0-at-write is post-increment — SECOND payment (14z-18 tail row)
- Hole "a" is inside the CPS-2 crypt range — thunks with EMBEDDED DATA must go to hole "b"
- A same-slot "vanilla control" controls nothing — vary the dimension under test
- The tile-placement pool is block-aware first-fit — carving cells out CASCADES the whole allocation
- A cited address in a session log is a CLAIM, not a fact — re-verify against the manifest/built image before planning on it
- A no-crash soak can silently lose the behavior it was written to exercise — assert the behavior, not just survival
- Sampled uniformity is not uniformity — extract the FULL set before synthesizing engine cases
- Fuzzy code-similarity reconciliation collapses near-identical helpers — content-verify PARAMETER TABLES, not just code shape
- replay.lua DUMPS separator is ';' — commas die silently late
- Sound is invisible to every RAM and pixel gate — it needs its own
- Censusing a structure without knowing its terminator counts garbage
- The FBNeo gate never rendered a pixel — RAM checksums are blind to video
- An A/B reference binary must differ by exactly one thing
- A canary must change exactly ONE thing, or it cannot answer anything
- A relocation test with no negative control proves nothing
- The MAME replay harness was blind to the video path too — until B5
- `git apply` SILENTLY SKIPS the patch when the target is inside another repo's working tree — and exits 0 (paid: 2026-08-03, B5)
- `git submodule add` stages the DEFAULT BRANCH, not the tag you check out
- The input-integrity check's first draft flagged EVERY replay — :IN2 carries the EEPROM data line
- `WIDE=0 tools/setup_fbneo.sh` did not produce a clean reference — it only SKIPPED applying the profile patch, never reverted it
- A build-fingerprint call without `--set` silently fingerprints the PRISTINE reference ROM (paid: 2026-08-04, 14z-59i)
- `_PRG_RE` did not match the WIDE extension members, so extension content was invisible to the build fingerprint
- The sfx helper and the record array must be impossible to enable separately
- "Unknown system: vsavjw" is an EMULATOR problem, not a ROM problem — and renaming the zip to force it is actively harmful
- A worktree branched from a STALE `origin/main` silently changes the instrument (paid: 2026-08-04, 14z-60)
- capstone m68k mnemonics carry a SIZE SUFFIX — equality tests match nothing and report a confident null (paid: 2026-08-04, 14z-60)
- A register-dataflow walk CANNOT see a mask applied straight to a memory field — two folding sites hid behind that for a whole session
- A slot id baked into hand-authored MACHINE CODE is invisible to a source-level audit — and fails silently, not loudly
- Renaming the project directory silently invalidates a worktree session
- "Inside the placed band window" is NOT "overwritten" (14z-62)
- Dotted TOML table names parse DIFFERENTLY per host (14z-62c)
- "The substitution landed for free" — invisible slot dependencies (14z-62c)
- Descriptor CRCs for variable-content members: use SENTINELS (14z-62d)
- Stale build-output members get re-packed (14z-62h, maintainer-caught)
- A hook on a hot shared path can flip a frame-boundary parity PERMANENTLY — flicker's evil twin (14z-64)
- Two generator sections silently owned one table row — last-write-wins decided the shipped bytes (14z-65)
- A single-shift sibling scan dies at the newcomer window's hidden structure — and junk filler decodes as pointers (14z-65)
- The vanilla-alias assumption fails where per-char rows hide in engine space — and a window constant is a census, not a fact (14z-65)
- An odd-offset "engine ref" ate a jsr opcode — and a pool-head latch re-seeds live pools at round 2 (14z-65)
- Three lessons from the day Huitzil came alive (14z-65)
- PC-relative escapes in engine-style regions are INVISIBLE to the sibling oracle — and unrewritable in place
- 2P forced-pick pokes must end by ~frame 1500 — later pokes leak into the SECOND player's load
- Physics ports move probe windows — retune frame-pinned gates
- Forced-pick pokes do NOT populate the HUD index field — HUD verification needs a REAL wheel pick (14z-67)
- A gate that is not in the battery can sit FAILING for sessions — sweep gates when a design changes (14z-67, paid twice in one day)
- A tenant porting SHARED regions inherits every region-scoped mechanism row those regions carry — copy them ALL, up front (14z-67)
- Per-char dispatch on a COMMON seq state needs the target flow's FULL closure first; and "cold" sites can be legacy-hot (14z-67)
- Twin-site identification by BYTE PATTERN alone can land on the wrong subsystem — derive the pair through the DISPATCH TABLE (14z-68, refutes half of the 14z-67 entry theory)
- An "owner-gated" thunk on a shared engine routine is NOT scoped by owner alone — sibling effect families share subtypes (14z-68)
- Verify a fix at the RENDER layer before believing the RAM layer (14z-68, the beam that never was)
- A ported region must contain the CONSTANTS its own code loads — check the boundary against the routine's literals (14z-68)
- Routing a tenant's objects to a ported machine: the discriminator must be PER-EFFECT, not per-hit (14z-68)
- The data_in_code detector misses the POST-INCREMENT reader shape; and RAW placement does not fix an embedded data table (14z-68)
- A ported region whose consumers index NEGATIVELY needs headroom below its base — never allocate it at the start of wide_ext (14z-68)
- Re-deriving what a previous tenant already solved (14z-68m)
- A `wpset` watchpoint is SILENTLY BLIND to pc-relative reads — dispatch tables need the OPCODES space (14z-71, inverted a finding)
- MAME parses watchpoint LENGTH as hex; a rejected length kills the run and prints a clean-looking zero (14z-71, produced a wrong finding)
- A gate whose expectation is "0 hits" passes on a STALE address — derive placement constants from the build, never hardcode (14z-71, a green gate that proved nothing)
- The boot RAM test writes every byte of work RAM — a bare write-count reports phantom hits (14z-71, a tripwire gate that cried wolf)
- vsav and vs2 sprite-list handlers disagree on a CODE BIAS (types 4/6/8, +0x3800 vs +0x4200) — ported list data lands 0x0A00 low (14z-71)
- A symptom grouping is a HYPOTHESIS — test it member by member, cheapest first (14z-71, the effect family: the premise was right for 3 of 4 and nobody checked for three sessions)
- Cross-build A/B playtest beats analysis for "when did this change" — and settled a question two measurements got wrong (14z-71)
- When a claim changes, grep for the CLAIM not the files — headers and summary lines outlive corrections (14z-71, standing order in CLAUDE.md §5)
- THE DEAD-ROW CLASS: vsav ships table rows as stubs/aliases where vs2 fills them — 6 instances (beam class row 16, drawer type 12, grab keyframe row, Cosmo sub-state 81, the HUD mug/name rows 0x10-0x1F, the per-char palette-routine row 0x11) + the variant-half alias variant; recipe in docs/game/engine_internals.md (14z-74, 5th 14z-75)
- Never chain a legacy measurement onto a build in one step, and re-run before believing a gate that contradicts a prior green — it produced a wrong commit (14z-74)
- A dead-filler / junk classifier that compares siblings in the OPCODE view is blind to embedded DATA tables; compare their DATA views instead (14z-74, cost the air-214+P bug)
- Cross-emulator position A/B: compare the RELATIVE offset (p2x−p1x), never absolute x — the two emulators run the match at a ~21px global camera shift, and comparing absolute x fabricated a "rig not comparable" blocker that cost a session (14z-72→73, the grab victim)
- `placements.json`'s dst/src is a LINEAR map while the extractor auto-discovers SUB-REGION shifts — compare by CORRELATION, or a faithfully-ported region reads as 75% corrupt (14z-75)
- Read a jump/data TABLE BASE off the code that indexes it, never off a content match — a row-content match put vs2's palette-seq base 8 rows out and produced a confidently wrong elimination (14z-75)
- A per-character table aliasing rows 0x10-0x1F onto 0x00-0x0F is usually not ALONE — Pyron's blink lived in THREE such tables and fixing one left two screens broken; sweep for the SHAPE (tests/test_variant_dispatch.sh), don't chase the screen (14z-75)
- A jump-table "entry N" past the table's END is the NEXT routine's instruction operand — count the entries (a table ends where code begins) before writing one; 14z-74's Cosmo fix wrote index 81 of an 80-entry table and corrupted a second dispatcher's displacement for EVERY character. The tenant-side fix is to retarget the TENANT'S index into range, never to write the shared table (14z-75)
- A DEADNESS measurement is only as good as the replay it ran on — 0 reads on 02_demitri_vs_cpu, 6 reads on 05_timeout_idle, same address (14z-75)
- THE INDEX-SPACE CLASS: vsavj's tables are SMALLER than vs2's, so a ported character's verbatim index can dispatch past the end — fix it in the TENANT'S data (retarget his index), never in the shared table (14z-75, the Cosmo crash)
- A negative result from a rig is a fact about the RIG until proven otherwise: prove it produces the EVENT (a stock spent, a mode flag set), not just that it ran — Cosmo needed the right button pair AND a long enough hold AND meter, and "no crash" from a downgraded input means nothing (14z-75, cost four wrong conclusions)
- MAME's -debug can perturb a timing-sensitive crash AWAY, and debug frame numbers do not transfer to non-debug runs (14z-75)
- BUG ARCHAEOLOGY FIRST: before fixing a bug, grep the HISTORY for it — it may already have been fixed once, and the old fix (or its withdrawal) is the fastest route to the mechanism; if the record is ambiguous, ASK THE MAINTAINER, who was there (14z-75, CLAUDE.md §5 standing order)
- A PLACED address baked into a hand-authored `thunk_hex` tracks NOTHING — it made `anim` look immovable and blocked the whole merge; write `region_subst`, and when a stale value is IDENTICAL on two builds grep for the VALUE before tracing the CODE (14z-78, cost a session)
- Relocating a PC-RELATIVE dispatcher away from its table: rewriting the read as An-relative changes the fetch space and returns CIPHERTEXT (38 of 80 vsavj sub-state targets come out ODD in the data view, 0 in the opcode view). When the mover is a thunk, embed a copy of the table in the thunk body — a `code` op re-encrypts with it, so the pc-relative read still decrypts (14z-79, caught before it shipped)
- "Dead on ENTRY" is not "dead": a dispatcher's output register (D1 at 0x018460) is read DOWNSTREAM of the handler's `rts`, so a sweep over handler first-instructions licenses nothing — reproduce the displaced instruction's WHOLE architectural effect instead of proving each part unobserved. Diagnose by killing hook-COST first: measure the dispatch rate and diff the images, because "the hook is wrong" and "the hook is expensive" look alike and have opposite fixes (14z-79, cost a build)
- A PERMANENTLY RED GATE GETS EXPLAINED AWAY, and that is how a real defect hides: `test_variant_dispatch.sh` reported `0x02a8a4` row 0x10 as a FAIL on every run from 14z-74, was recorded as "benign — 0 hits at the resolver", and WAS the Bulleta Dark-Force bug the whole time (the 0 hits came from replays in which nobody activated DF). Either fix a red gate or record it as KNOWN-OPEN with the defect it represents — never as noise (14z-79)
- The pushed group-0 exception PC (vec3/vec2) is MID-INSTRUCTION: a GUARD_PROBE at the CRASH-line PC can never fire and prints the dead instrument's clean zero — probe the routine's ENTRY, and demand a rig-liveness control before believing any zero (14z-81) [project]
- A pre-armed attribution in a script's FAILURE MESSAGE becomes "the finding" for whoever reads it later — pre-arm predictions in comments, print only measured mechanisms or the probe that measures them (14z-81, the F2-vs-vec3 correction) [project]
- FBNeo/MAME frame indices and OBJECT SLOTS do not transfer: a slot-keyed FBNEO_HTAP watched a different object than the MAME crash and the defect's observable moved entirely — key cross-emulator probes on content, not slots, and treat MAME as the instrument for frame-addressed findings (14z-81) [platform]
- Dispatch-time OWNER reads are transient at spawn instants: recycled parent chains and mid-frame field rewrites broke the withdrawn obj_hook stub design in 2 of 6 replays — route per-tenant machinery on BUILD-time facts (spawn tags, per-tenant type numbers), not runtime state near a spawn (14z-81c) [project]
- Forced-pick pokes hold through SELECT only: on a vs-CPU rig (0x382,P2) carries the CPU's REAL pick at match time (0x06 measured), while 2P rigs keep the poked id in both structs — "(0x382,P2)==tenant" checks are rig-dependent (14z-81c) [project]
- A gate born against a live defect has never exercised its PASS path — audit_merged_vec3 mis-verdicted its first real PASS on a zero-padding string compare; treat a gate's first green as a verdict-control moment and read the printed values (14z-81c) [project]
- A stamp census that scans ONE instruction form reads exactly like a complete inventory: the move.l-only 14z-81b scan missed ~26 `move.b #type,(2,An)` stamp sites (20+ for type 115 alone); enumerate write FORMS, control with --expect, cross-check with a dynamic writer-PC audit, and mind d16 ((2,An)=type, (3,An)=owner/sub-state) (14z-82) [project]
- A two-leg A/B that bails on leg 1 never measures leg 2: "the reference is clean" was an assumption and pyron-m2 crashes f7997 SOLO — leg-b now always measures the ref leg and prints MERGE-SPECIFIC vs LATENT; also the covering soak built stage 4, not the frozen stage-6 artifact (14z-82b) [project]
- A hit-path defect fires per COLLISION, not per frame: 11,017 soak frames produced ONE dispatch of the crashing map — pair soaks on dispatch-guarded paths with a fire census, or "never fired" reads as "safe" (14z-82b) [project]
- -debug fire counts do not transfer to checksum timelines on vs-CPU/chaos content: two "zero fires" probe runs contradicted real divergences (the debug timeline plays a different match by f10000+) — attribute .sha1 divergences with non-debug DUMPS diffs (3 dead-stack bytes = the hook-cycle class), and give each leg its own out dir (DUMPS clobber next to CHECKSUM_OUT) (14z-82c) [project]
- Cross-build A/B dumps must run PROBE-FREE — debugger overhead lands differently on two builds (14z-84) — docs/project/gotchas.md
- A write tap bucketed by WORD OFFSET reads a word's low-byte lane as "never written": the 14z-84 "$FFB800 +0x7F free" was our own hole_b word write at +0x7E — split every tap hit by its 16-bit mask into byte lanes before any freeness claim (14z-85) [platform]
- A pool measurement is a claim about ONE pool: the 14z-84 tag-byte census ran on $FFB800 (0x5E542's family) while the 59-75 family lives in $FF9400/0x100-stride — decode the WALKER (its `lea` base + stride) before believing a slot claim transfers (14z-85) [project]
- A port_patch on a shared engine-family region fixes ONE tenant's copy: Donovan's 14n six-row work-var reconciliation (same-value class #4) never reached H/P's x028122 copies — Phobos' FG beam ticked 12 times, combo counted, ZERO HP (damage staged into vs2's $FF3494 family, unread on vsavj); when a tenant imports a region, grep the other manifests' port_patch rows for it — and never blanket-copy the 14x rolled-back families (14z-85f) [project]
