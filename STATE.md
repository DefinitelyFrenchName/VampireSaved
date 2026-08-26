# STATE — living progress log

## Session 14z-110 (4) — CLOSE. **THE RULED ORDER IS COMPLETE: FIX -> AUDIT ->
## RE-FREEZE, all green.** donovan-m12 / merged-m7 frozen and tagged; the
## acceptance full suite is GREEN (65 PASS / 18 SKIP / 0 FAIL, zero
## nondeterministic) and the static tier is GREEN (PASS 110 / 0 / 0). The #99
## fix ships in every track; the FIELD pass on the new bundle is the final
## verification (MAME cannot reproduce the crash).

### THE FREEZE, as ratified

| | value |
|---|---|
| donovan-m12 | `60b55a12`, 327 ops; set carried from m11, .sha1s MEASURED IDENTICAL; +16870 flicker ratified (below) |
| merged-m7 | program `761fd35a`, 808 ops; `build/m3b_merged14`; release/merged-m7 packaged (round-trip PASS) |
| stock twin | `cf455760` (`build/m5_stock7`) — MOVED this window (the fix is not profile-gated) |
| huitzil-m20 / pyron-m14 | CARRIED — program bit-exact, whole-artifact delta = the two M7 glyph members only |
| m3a pins | all SIX re-frozen with per-member attribution (incl. MANI_MERGED `75a253ea`, measured twice) |
| MiSTer | fork `fc04a8ec` (2 catalogue commits, PUSHED), pin bumped, patches 0021+0022, twin+mra gates PASS |
| version mark | M7 (gfx-only; program fingerprints held; test_version_string pixel-exact) |

### TWO MAINTAINER RATIFICATIONS THIS CLOSE

1. **24_don_winmash flicker inventory +16870** (solo set only): the ruled d2
   compares' ~18 cycles tip the documented win-screen-fade VBL-edge frame
   (the 14z-89/91 site, this exact replay). Measured before the ask:
   deterministic; NINE bytes, all the OBJ-builder secondary stack
   `$FF06D7-E1` (the ratified execution-position class, ram.md:62); adjacent
   frames zero-diff; 1650 identical after; the SAME fix on the merged image
   HOLDS its inventory — per-image cycle budget, the maintainer's own 14z-89
   framing. Checker still demands exact inventory match.
2. **The M7 mark** (convention: the shipped build's naked-eye tell) — gfx-only
   by measurement.

### THE NO-EXPECTATION DEBT, surfaced and paid for donovan-m12

The first full verify since 14z-108 surfaced four arc-added replays with no
expectations (107/108/109/110) — run_suite counts NO-EXPECTATION as RED by
design. Frozen after review (tenant-determinism .sha1 class). **STILL OPEN,
flagged not fixed: huitzil-m20 / pyron-m14 / merged sets carry the same four
gaps** — their full verifies were not rerun this window (their images did
not move); the gaps predate this window. Freeze them at the next window that
touches those sets.

### INSTRUMENT NOTES (beyond the (2) entry's)

- run_suite reads specs per-replay at comparison time — a spec landed
  mid-run applies to replays not yet reached (measured: the ratified 24 line
  turned a mid-flight run's 24 row green).
- My dump legs collided writing `dump_*` next to a shared log dir —
  contaminated per RH-4, discarded, re-run into separate dirs. Two parallel
  legs of the same replay need separate output dirs.

### POST-CLOSE ADDENDA (same session, during the maintainer's field pass)

- **The dynamic FSM census is now CORPUS-WIDE:** all 83 replays on merged-m7
  (unpoked legs, fsm_census.lua, all three dispatchers) — **ZERO indices
  >= 0x50 dispatched anywhere.** The bound the static census stated is now
  measured across the whole corpus on the shipped image.
- **donovan-m12-stock registry row + carried stock/stage4 expectation sets**
  (the battery's targets — missed in the main batch; the -stock row
  convention was donovan-m8/m9/m10's). Stage-4 fingerprint CORRECTED same
  session: the gate builds stage 4 with ITS OWN recipe (99e92afc), and my
  scratch build's 653e315c used the WIDE-profile flags — a build includes
  its defaults (RH-49).
- **#111 U,U,R triage posted** (33 replays: keep all as frozen legacy
  coverage — the Donovan intent died at 14z-64 and their expectations were
  re-frozen since against the actual content; headers NOT edited in-file,
  replay file sha1s are frozen in sim gates).

### WHAT REMAINS (the next session's opener)

The FIELD TEST of merged-m7: fresh board bundle at `../mister_fieldtest_14z110/`
(regenerated this close; carries the 14z-109 durable extras), the .rbf
unchanged (seed 18269, sha256 `46fc74af…` — the romset moved, the BITSTREAM
did not). The field pass verifies #99 dead on the CRT; #111's remaining
items (33 U,U,R replays triage; H/P/merged NO-EXPECTATION gaps) follow.


## Session 14z-110 (3) — **THE AUDIT PHASE: green across the board; the two
## static reds are the frozen generation itself, resolved by the freeze.**
## (Guard corpus + H/P reproduction checks in flight at the time of writing.)

**Audits on the fix builds (don_m12 `60b55a12` / m3b_merged14 `761fd35a` /
m5_stock7 `cf455760`):**

| audit | verdict |
|---|---|
| FBNeo legacy oracle (don_m12) | **PASS** — frozen phase-class offset inventories held |
| test_dualtrack (stock7 vs don_m12) | **PASS** — onsets 890/4267 held; divergence DATA-only, same writer sets |
| audit_merged_legacy (merged14) | **PASS** — leg a on the ratified legacy classes: **the frozen flicker/window inventories HELD with the d2 compares on the hit-stun path** (the ruling's stop-and-escalate cost gate: it did not move); leg b guard-clean, its vs-old-solo rows REPORT-classified as designed |
| audit_don_vs_cpu (merged14) | **PASS** — Phobos (venue 0x02) + Bishamon (0x10) legs, liveness + guard-clean |
| audit_continue_switch (merged14) | **PASS x2, frame-identical** — re-measured schedule (loss at match 4 ~f31620, re-select f31940-32500, blanket pokes f31960-32520); **assertion 5 now DETERMINISTIC via the venue steer** (post-continue first draw = Phobos); bonus: match 3 is naturally Phobos-vs-CPU-Donovan |
| test_fsm_census / test_reaction_hook_d2 | **PASS** on all three new builds |
| run_battery_m2 (stock7) | **DEFERRED TO THE FREEZE by design** — m2a_common targets the CURRENT FROZEN GENERATION (#96 ruling); an unregistered fingerprint stops it. Pre-registry gates green. Re-run post-registration |
| run_all_static --strict | PASS 108 / SKIP 0 / **FAIL 2** — `test_phasec_spaces` (stock rebuild = `cf455760` = stock7, expected the frozen `883e7d17`) and `test_m3a_reproducible` (WIDE rebuild = `60b55a12` = don_m12, expected the frozen `1de9a027`). **Both are the fix itself: the tree now produces the NEXT generation.** The sanctioned resolution is step 3 of the ruled order — the freeze updates these expectations deliberately. No other gate moved |

**The re-select poke lesson (measured twice):** pokes at f32040-32220 alone
did NOT land the switch (the re-select's class read sits elsewhere in the
window than the initial select's commit era); blanketing the whole measured
window (f31960-32520, every 40) lands it deterministically. The audit's
schedule comment carries this.

**Freeze-naming note (pending the reproduction check):** hui47/pyron31's
manifests are untouched by the fix; if they rebuild bit-exact, their
registrations (huitzil-m20 / pyron-m14) STAY and the batch is
donovan-m12 + merged-m7 + the stock update only — bit-identity needs no new
set names, against NEXT_SESSION's pre-named huitzil-m21/pyron-m15.


## Session 14z-110 (2) — **THE #99 FIX IS BUILT AND MECHANISM-PROVEN
## (A/B, register-forced): old build vec3s at the exact field signature,
## new build runs vs2's copy handler.** Builds: don_m12 + m3b_merged14
## (UNREGISTERED — the freeze is step 3). Audit phase begins.

**The fix, as ruled** (patch_index "14z-110 additions"): `[reaction_hook]`
gains `d2_case_a0/a2/a4/a6` (vs2 dispatcher-2 twin `0x016DE4` handlers,
verbatim — d2 differs from d1 at 0x52/0x53); the emitter
(`gen_donovan_patch.py`) emits an 82-byte thunk whose bne-arm carries the
same `0x50-0x53` window as the d1 arm via a SECOND ext table, falling
through to `jmp 0x018508` for every other index. Without d2 keys the
50-byte thunk is emitted byte-identical (probe manifests unchanged).
Vanilla dispatcher byte-untouched — asserted against vsavj's OWN decrypted
dump, not a build artifact.

**THE RH-43 A/B (GUARD_FORCE rig, `tests/replays/21_don_mash` + Donovan
picked, scratch node in the dead-stack window `$FF7F00/$FF7F80`,
`(0x17,A3)=0x51`, D0/A1/A3 forced at the site 0x018458):**
- don_m11 (old): `FORCE 3462` -> `CRASH 3463 vec3 PC 01850E ADDR 00018511`
  — the EXACT #99 signature, on demand, first time on MAME.
- don_m12 (new): `FORCE 3223` -> END 14120 clean, scratch `+0x54 = 0x51`
  (the copy handler ran — vs2's semantics exactly). **0 INPUT-VIOLATIONS**
  after the instrument fix below.

**INSTRUMENT: `GUARD_FORCE` added to `replay_guard.lua`**
(`hexaddr:minframe:REG=hex,...`, one-shot register forcing) — first version
armed its breakpoint eagerly and every pre-window debugger stop skewed the
frame_done input application by a beat: BOTH parallel legs flagged the SAME
frame 2874 as INPUT-VIOLATION (deterministic bp-stop skew, not host input).
Now lazy-arms at minframe-1 and bpclears after firing; the clean leg shows
zero violations. Filed under "suspect the instrument" — count now NINE.

**Gate: `tests/test_reaction_hook_d2.sh`** (ci_static) — manifest hex
re-derived from vsav2.zip, thunk reconstructed from first principles, the
vanilla dispatcher compared against vsavj's decrypted dump, census 6/6,
three verdict controls; PASS on don_m12 AND m3b_merged14. Its own first
version had wrong ext-table offsets and FAILED the good build — fixed and
the controls now prove it can fail for the right reasons.

**Op-count pins re-frozen with attribution** (`test_tenant_loop`: don
325->327, N=2 600/652->602/654, N=3 806/907->808/909 — +2 = the d2 cases
blob + its ext table, Donovan-declared, nothing dedupes; the thunk grows
50->82 bytes of hex, not an op). Placements: the 82-byte thunk moved to
`0x3FFD50` and six downstream 0x3FFDxx allocs shifted +0x60 (site-operand
carried; pcrel/pointer_flow re-derive at the freeze, the 14z-105 class).

**NOTE FOR THE FREEZE: the STOCK TWIN MOVES THIS TIME.** The reaction_hook
is not profile-gated (the substituted track carries the same six 0x51
nodes and needs the same fix), so m5_stock7 will fingerprint differently —
unlike 14z-105's profile-gated window. Budget the stock re-freeze.

**AUDIT (step 2 of the ruled order) — in flight:** fbneo legacy oracle,
audit_don_vs_cpu + guard corpus on merged14, audit_merged_legacy (the
flicker-inventory gate); results land below before any freeze.


## Session 14z-110 — **THE #99 FIX WINDOW, RE-SCOPED TO MEASURE-FIRST: the
## ruled data-remap is UNSAFE, the census is CLEAN, the #111 coverage gap is
## CLOSED with a deterministic gate.** No shipped byte moved; the fix shape is
## back with the maintainer (see "Decisions pending — #99").

**The session in one line:** planning to implement the ruled `0x51 -> 0x19`
remap found it re-breaks the 14z-43 ES port, so the maintainer said HOLD —
measure first; the measurement produced a consumer-complete census (exactly
the six known 0x51 nodes, no others), a deterministic Donovan-vs-CPU gate, and
a re-ask with a code-side recommendation.

### THE DECISIVE FINDINGS (all measured this session)

| | result |
|---|---|
| the FSM tables | **80 entries** (valid 0x00-0x4F), NOT "~0x28" — corrected in engine_internals/NEXT_SESSION/STATE. vs2 twins 84 -> gap **0x50-0x53** |
| the node byte feeds | **THREE** dispatchers (0x018460/0x018508/0x0185D2). The 14z-43 audit named 1+3, missed **2 (0x018508)** — where #99 crashes |
| data remap 0x51->0x19 | **UNSAFE**: diverges on dispatcher 3 (0x19->0x18694, not copy) AND fails the es_type51 thunk's `cmpi #0x51` |
| any copy-aliased remap (0x4E/0x4F) | dispatcher-exact on all three BUT changes `property[class]` (0x51->0x19 vs 0x4E->0x0F, the ES-freeze family). No safe data value exists |
| the census (static, family-aware) | **exactly SIX out-of-range nodes across all three tenants — the known 0x51 cluster in Donovan's hitbox. Huitzil/Pyron: ZERO.** No escalation members |
| the census (dynamic, 8 combat replays) | **zero idx>=0x50 dispatched anywhere.** Tenant nodes A3 0x3fb462-0x3fbd62 ARE walked (bracketing the #99 cluster 0x3fb862-902) but the six crash nodes are NOT — the honest gap, precisely |
| the #99 crash on MAME | does NOT reproduce from a P1-mash (full venue-0x02 Donovan-vs-Phobos marathon clean to END 40620) — needs the CORE's cross-fighter walk |

### THE RECOMMENDED FIX (maintainer's to ratify — Decisions pending #99)

Code-side on dispatcher 2's arm, INSIDE the `reaction_hook` that already owns
the only entry to it (`bne 0x018508` lives in the site prefix 0x018458): give
its bne-arm the same 0x50-0x53 window the reaction_hook already runs for
dispatcher 1, using vs2's dispatcher-2 twin `0x016DE4` handlers verbatim. Data
stays native 0x51 (dispatcher 3 + property untouched). Cost: ~2 compares on a
legacy path — **must be measured against the frozen flicker inventory before
it ships.** Not a "port the handler" import; it reuses handlers already
present. The fix waits on the ruling (the maintainer said measure first).

### ARTIFACTS (committed, the persistent-suite doctrine)

- **`tools/audit_fsm_census.py`** — static family-aware census (node-record
  signature, vs2 classification oracle). **`build/manifest/fsm_census.toml`**
  frozen inventory (6 nodes). **`tests/test_fsm_census.sh`** — gate + TWO
  negative controls (perturbed +0x17 -> ADDED; cleared -> MISSING), green;
  registered in `ci_static.txt`. The build-time guard #99 asked for.
- **`tests/lua/fsm_census.lua`** — dynamic census instrument (per-site divisor,
  OOR + tenant-node A3 capture, POKES for venue steering).
- **`tests/replays/110_don_arcade_mash.rpl`** — 26's mash body verbatim, WIDE
  L,L,D,D prologue to Donovan 0x13 (26's U,U,R lands on Jedah). 26 untouched.
- **`tests/audit_don_vs_cpu.sh`** — deterministic Donovan-vs-CPU-{Phobos,
  Bishamon,Pyron} via the venue-byte steer ($FF8121: 0x02/0x03/0x05), liveness
  asserted, guard-clean. Closes #111's core gap. Phobos leg smoke-tested green.

### DOCS / RETRACTION (CLAUDE.md §5)

- "~0x28 states" -> "80 entries" in engine_internals (authoritative),
  NEXT_SESSION (live), STATE 14z-109 (marked in place). engine_internals
  dispatcher section rewritten (three dispatchers, 84-vs-80 gap).
- `docs/project/gotchas.md`: the renumbered-family rule sharpened — "enumerate
  EVERY dispatcher a byte reaches" + the property-dependency caveat.
- `docs/project/patch_index.md`: the missing `region_fix` mechanism row added.

### #111 (coverage rot) — PARTIAL, tracked

`audit_don_vs_cpu` + replay 110 close the "no Donovan-vs-CPU-Phobos gate" gap.
STILL OPEN (filed on #111): 33 replays share 26's U,U,R stock-track prologue
(triage list); `audit_continue_switch` still frozen to merged11's trajectory
(re-measure per its header deferred with the re-freeze).

### NOT DONE THIS WINDOW (waits on the ruling / is the next window)

The fix itself; the flicker-inventory cost measurement; the re-freeze
(donovan-m12/huitzil-m21/pyron-m15/merged-m7) + its MiSTer CRC tail.


## Session 14z-109 (4) — **THE #99 CRASH INVESTIGATED ON EMULATOR: a
## confirmed mechanism CLASS, real eliminations, and an HONEST GAP — no
## clean natural repro of the exact field crash yet.** Also surfaced: the
## standing crash-soak coverage has rotted, which is why nothing caught it.

**Maintainer's refined field data (2026-08-26):** 1P-vs-COM ARCADE ONLY,
Donovan P1 vs Phobos, crashes at SOME point in the match (not necessarily a
hit, not necessarily the start); **2P versus Donovan-vs-Phobos does NOT
crash**; first-fight Phobos crashed ~1/2, the ladder second-fight (after
beating Bishamon) is the 100% path.

### CONFIRMED BY DISASSEMBLY — the per-class sfx dispatcher is UNBOUNDED

`PRG:0x27F16`: `move.b (0x382,a6),d1` -> `lsl.w #2,d1` -> `lea 0x0BF41A,a0`
-> `movea.l (0,a0,d1.l),a0` -> jumps through `a0`. **No bounds check.** The
table has valid handler pointers for classes `0x00-0x27` (legacy + arcade +
the three tenants at `0x10`/`0x11`/`0x13` -> WIDE ext); beyond that it reads
non-pointer bytes. **Forcing an out-of-range class into `+0x382` crashes
exactly there** — probe J: class `0x20`/`0x30`/`0x40` -> `vec3` address
error at `~0x02adXX`; `0x12`/`0x14`/`0x18`/`0x28` safe.

### THE FIELD PATTERN FITS THIS, AND 2P-CLEAN IS THE KEY

The voice-class borrow (`PRG:0x0AEF2`, thunked to our `0x3FFC60`) runs in the
ARCADE path and writes `+0x382` from the opponent-candidate list; its value
is sound-fed (`$FF8110`), hence STOCHASTIC. 2P has no borrow, so `+0x382`
stays the char id (`0x13`/`0x10`, both valid) -> never crashes. A bad class
armed at match start FIRES on the next sfx event, which can be any time ->
"crashes at some point, not necessarily a hit". Every field observation is
consistent with a bad `+0x382` reaching the unbounded dispatcher.

### ELIMINATED: the #92 stage-`0x18` mechanism

The 14z-94 #92 crash was table-B stage `0x18` (vs2's 13th stage) indexing the
banner family past its end. **Measured: tenant table-B rows `0x10`/`0x11`/
`0x13` contain NO `0x18`** — the fix covered Donovan too. This is a DIFFERENT
bug in the same subsystem, NOT a #92 regression.

### THE HONEST GAP — no clean natural emulator repro

- probe J crashes but on a FORCED class (artificial).
- probe H crashed (`0x01850e`, a different PC — a state jump-table, not the
  sfx dispatcher) but had in-match class pokes; not trustworthy.
- first-fight-Phobos: 8 sound-state seeds, active Donovan, ZERO crashes.
- the committed `audit_continue_switch.sh` DRIFTED on merged13 — it ran clean
  but never reached the Donovan-vs-Phobos pairing (its trajectory is frozen
  to merged11), so its "clean" is vacuous here. **This also weakens the
  original #99 closure, which the 14z-100 note already flagged as "weak
  evidence".**
- **POSSIBILITY TO HOLD: the crash may be more readily reproducible on the
  CORE than on MAME** (user 100% vs my ~0% natural). Either a stochastic
  state my rigs missed, or a core-specific amplifier. 2P-clean on the core
  argues against a pure asset-streaming collision.

### WHY NOTHING CAUGHT IT — coverage rot (the recurring class)

- `26_don_arcade_mash` (the "Donovan arcade mash" soak) navigates U,U,R,
  which on the EXTENDED wheel lands on **Jedah `0x0F`**, not Donovan — the
  soak lost its nominal subject.
- `audit_continue_switch.sh`'s frozen trajectory no longer reaches the
  pairing. **No current gate exercises Donovan-vs-CPU-Phobos.** Same
  "check that stopped checking" class as 14z-94/95.

### ARTIFACT

`tests/replays/109_2p_don_vs_phobos.rpl` — the first 2P versus replay in the
tree (CLAUDE.md §4 has wanted "vs each of the 18, both sides"), P1 Donovan vs
P2 Phobos via the extended wheel, made possible by tonight's P2 scripting.
Verified P1=Donovan `0x3FA9D0` / P2=Phobos `0x4595B0` load on MAME.

### FIELD CONFIRMATION x2: Donovan-vs-BISHAMON crash + the video

**(1) The maintainer reproduced the crash in Donovan vs BISHAMON.** This is
the root cause's own prediction landing: the bad node is in DONOVAN'S data
block and is walked by his OPPONENT — whoever that is. Phobos was never
special; the ladder just funnels there. Kills every remaining Phobos-specific
theory (and further de-weights the sidekick reading).

**(2) The crash video (`../videos/donovan_phobos-2nd_fight_crash.mp4`, 21 s,
CRT @ 60fps) — read frame by frame:**
- Sequence: Bishamon win quote -> Donovan victory art -> VS screen **Donovan
  vs Phobos, CONCRETE CAVE** (the decoded table pairing, on screen) -> intro
  with the shell + kids -> fight.
- ~1 s before the cut: an effect-heavy CONNECTING exchange — Phobos lands an
  arm-thrust (consistent with the earlier 5+MP/6+MP suspicion).
- **The last gameplay frame is NEUTRAL** — both fighters standing apart. The
  crash follows the exchange by ~0.5-1 s, matching "not necessarily during a
  hit": the bad node is walked in the post-exchange anim chain, not in the
  hit event itself.
- The reset shows a BRIEF white-on-black check list ("WORK RAM OK / CPS0..2
  RAM OK / OBJECT RAM OK / Q SOUND RAM OK") drawing progressively, then the
  name screen — the soft-reset path's abbreviated check, exactly what the
  decoded exception handler predicts (and distinct from the gold full test).

Every observable in the video is downstream of the captured mechanism. The
remaining work is unchanged: identify the record family of `0x3FB882` in the
extraction and the vsavj renumbering of vs2's `0x51` — maintainer-facing,
fix as a remap rule per the 14z-33/35 shape.

### ROOT CAUSE CAPTURED — a vs2-numbered type byte in DONOVAN'S ported data

The extended guard probe (`GUARD_PROBE=1850c`, cond `(d1&1)==1`, PROBE line now
carrying A1/A3) caught the fatal iteration live:

```
PROBE 13918 D0=000000a2 D1=00000001 A0=ffff8400 A1=00ff8800 A3=003fb882
      A6=00ff8400 RET 00ff02dc MEM[A3+17=3fb899]=51
```

- **A1 = `$FF8800`: the P2 PLAYER object — Phobos himself**, not a sidekick
  sub-object. (The sidekick lead was the right NEIGHBORHOOD — a Phobos-side
  1P-only event — but the wrong object.)
- **A3 = `0x3FB882`: a node INSIDE DONOVAN'S relocated data block**
  (base `0x3FA9D0`, node at +0xEB2). Phobos's object walks DONOVAN'S ported
  node — the cross-fighter interaction shape (cf. 14z-73 grab-victim).
- **`(0x17,A3)` = `0x51`** — the fatal index. `D0 = 0x51*2 = 0xA2` runs past
  the state jump table at `0x018510` (80 entries, valid `0x00-0x4F` —
  **CORRECTED 14z-110: was "valid states end ~0x25"; the table is 80-entry,
  vs2's twin 84, gap 0x50-0x53**), fetches the
  word `0x0001`, and `jmp (2,pc,d1.w)` lands on odd `0x18511` -> vec3 ->
  the soft-restart handler -> name screen. Every field observation is downstream
  of this.
- **`0x51` IS THE KNOWN FAMILY:** 14z-35 "type-0x51 cluster — the engines
  RENUMBERED the copy-class record family"; 14z-33 "record-type dispatch
  aliases". A vs2-numbered type byte in ported data, indexing a vsav dispatch
  that numbers the family differently. The 14z-33/35 fixes covered the members
  then known; **this node (`ROM 0x3FB899`, in Donovan's block) is a missed
  member.**

**REMAINING to fix it (build-pipeline, maintainer-facing):** identify WHICH
record family `0x3FB882` belongs to in the extraction (the manifests map
Donovan's block), what vs2's `0x51` MEANS there, and its correct vsavj
renumbering — then the fix is the same shape as 14z-33/35 (a remap rule in the
extraction, not a hand-poke). Also: verify the FIELD path (natural 1P arcade)
funnels through this same node — probe H's trajectory is poke-contaminated,
so the node identification transfers but the path should be confirmed on a
clean repro or on the maintainer's video.

**INSTRUMENT CHANGE, recorded:** `tests/lua/replay_guard.lua`'s PROBE line now
prints A1 and A3 (additive; existing fields unchanged). This is what made the
capture possible.

### THE PROBE-H AUTOPSY REFINES IT: an ODD dispatch index, not merely out-of-range

Probe H's crash is DETERMINISTIC (f13918 every run, vec3, PC 0x01850e, fault
ADDR 0x18511) — a reusable lab rat even though its trajectory is
poke-contaminated. Dense-dump autopsy findings:

- **Fault ADDR 0x18511 => D0 = 1, an ODD index.** The normal state path
  doubles the state (word table), which can only make EVEN indexes. So this is
  NOT a plain too-big state: either the dispatcher was ENTERED from a path
  that did not double the index, or D0 was loaded from the wrong field. An
  odd D0 faults on the table read itself — instantly, cleanly, no corruption
  first — which matches the field signature perfectly.
- **Player-slot `+0x54` states all benign** ($FF8400..$FF9800 at 0x400 stride,
  values 0-5) up to f13910 — the corrupt write either targets an object
  outside that window or lands in the last 8 frames.

**NEXT (deterministic, cheap):** re-run probe H dumping EVERY frame
13910-13918 over a wider window, and capture the guard's stack for the
caller; then PC-attribute the write/entry that produces D0=1. Separately,
the ACCUMULATOR hypothesis stands (first-fight crashes "if long enough";
second-fight crashes at the intro 100% => something counts up across the RUN,
plausibly sidekick voice events — which also explains 2P immunity if the
sidekick path is silent there, as the maintainer heard).

**HARDWARE PROTOCOL AGREED:** the maintainer records 1P crashes on video (CRT,
60fps — the value is the LAST ~10 SECONDS before death: what Phobos and the
sidekick were doing), plus passive observation of sidekick activity before
each crash. No RAM peeking needed on the DE10 — the emulator side owns
instrumentation. Playing Phobos as P2 is LOW-VALUE by our own model (2P
suppresses the sidekick behaviour), noted so it is not over-invested in.

### SYNTHESIS: A PHOBOS OBJECT (LIKELY THE SIDEKICK) DRIVEN TO AN OUT-OF-RANGE STATE

**Maintainer's strongest clue yet:** 1P vs COM crashes reliably "if the fight
is LONG ENOUGH"; 2P versus NEVER crashes despite everything; and in 2P **the
Phobos SIDEKICK had NO voice/SFX** (incl. the "get up, don't give up" lose
animation, which normally speaks) — while in 1P that sidekick voice DOES play.

**Traced the reproduced crash site `0x01850e`:** it is a VANILLA object
state-machine dispatch — `move.w (6,pc,D0.w),d1; jmp (2,pc,D1.w)` — where D0 is
the object's STATE field `(0x54,a1)`. Handlers (0x018694-0x01877c) set next
states including `0x25`(37); a state value beyond the offset table reads a
garbage offset and jumps to an odd address -> `vec3` address error -> the
soft-restart handler -> name screen. So the crash is: **an object's `+0x54`
state got set OUT OF RANGE**, and vanilla's dispatcher faulted on it.

**THE COHERENT PICTURE, every field observation accounted for:**
- Phobos's SIDEKICK is an assist object with its own state machine + voice.
- It acts PERIODICALLY through a match -> "crashes if the fight is long enough"
  (more sidekick events = more chances to hit the bad state).
- Its full behaviour incl. VOICE runs in the 1P/arcade path and is absent in
  2P (maintainer heard exactly this) -> crash is 1P-only, and "2P clean" is
  NOT a coincidence: the triggering event doesn't fire in 2P at all.
- The hits observed near crashes were Phobos's, never Donovan's — **a strong
  hint, NOT a certainty (maintainer-corrected 2026-08-26): the trigger may not
  be an attack at all.** Consistent either way with it being Phobos's OBJECT —
  a periodic sidekick event needs no attack to fire.
- Immediate reboot, no corruption -> a control-flow fault, which this is.

**LEAD (for measurement, not arbitrage): what writes `+0x54` out of range on
a Phobos object in 1P.** Candidates: a ported Phobos sidekick anim node whose
state byte is wrong; the mid-match `+0x382` voice reassignment feeding a
sidekick voice/state path; or a lost/mis-ported sidekick spawner (cf. the
14z-41 lost-spawner and the effect-flow work). The `$FF0000` exception code
and the `+0x54` state value at fault are the two things to capture in a
poke-free 1P Phobos repro.

**DISCRIMINATING, on hardware:** does making Phobos's SIDEKICK active (his
assist/summon moves) bring the crash on FASTER? Does the sidekick look/behave
normally in the frames before a crash? A "yes, faster with sidekick activity"
nails the sidekick object.

### THE CRASH SIGNATURE IS DECODED — it is a CPU EXCEPTION, and my vec3 repros are the SAME EVENT

**Maintainer refined the signature: the reset goes STRAIGHT TO THE GAME NAME
SCREEN (plain white name on black), NOT through the gold-text RAM test.** That
is decisive. A cold/watchdog reset always re-runs the RAM test (it is exactly
what the pre-D5 boot loop did). Skipping it means a SOFTWARE restart from a
point after the RAM test.

**Decoded the 68k exception vectors + handlers (verify_op/verify_data):** every
exception (bus `vec2`, address `vec3`, illegal `vec4`, …) runs a handler that
does `move.w #code,($FF0000)` — storing the exception TYPE (0 bus / 1 addr / 2
illegal / …) — then `movem` all regs, resets SP (`lea ($FF0054),sp`) and
branches to a common restart routine (`0x608`), which reboots to the name
screen. **So "name screen, no RAM test" IS the game's designed response to any
CPU exception.**

**CONSEQUENCE — this softens the "no clean repro" pessimism.** A CPU exception
is exactly what the crash guard trips on, and I HAVE reproduced vec3/vec4
exceptions in-context: probe H `vec3 PC 0x01850e` (a `jmp (2,pc,d1.w)` jump
table, i.e. a bad-pointer jump), probe J `vec3/vec4` on forced classes. **These
are the SAME EVENT CLASS the maintainer sees on hardware** — the guard reports
the vector, hardware runs the handler to the name screen. So the field crash is
confirmed to be a bad-pointer jump / bad access / illegal instruction, NOT data
corruption (which the no-prior-corruption observation already argued).

**NEW INSTRUMENT: `$FF0000` holds the exception code.** Any repro can read it to
know bus vs address vs illegal without guessing from a PC. probe H's is an
ADDRESS error (odd-address jump-table target).

**REMAINING: pin which natural path triggers it.** probe H is the closest
(Donovan arcade context, real vec3) but has select-time pokes; the next step is
a poke-free trajectory that reaches the same `0x01850e` fault, then trace what
value indexes that jump table out of range. The `0x01850e` jump table —
`move.w (6,pc,d0.w),d1; jmp (2,pc,d1.w)` indexed by d0 — is a TYPE/STATE
dispatch, which fits "a specific Phobos move drives a state value out of range".

### CORRECTION + SHARPENED LEAD (same session, after the candidate-row check)

**THE ARCADE-BORROW THEORY IS WEAKENED — stated plainly because it was the
banner above.** I checked Donovan/Phobos/Pyron candidate rows (table A) against
the dispatcher's handler table read from the RIGHT source (member 04d, not the
mis-byte-ordered data view): **every candidate value is `0x00-0x18`, and every
one of those has a valid dispatcher handler.** So the borrow cannot write a
crash-inducing class into `+0x382`. Probe J proved the dispatcher is UNBOUNDED,
but with inputs (`0x20`/`0x30`/`0x40`) the borrow can never actually produce.
Probe J is therefore the right MECHANISM with the wrong INPUT SOURCE.

**THE SHARPENED LEAD, and it fits the field data better: a specific PHOBOS
MOVE.** The maintainer's own refinement — hits near crashes were Phobos's
(possibly 5+MP/6+MP), never Donovan's, "at some point" — **[LATER
maintainer-corrected: a strong hint, NOT a certainty; the trigger may not be an
attack]** — plus the crash signature (immediate
black screen -> the GAME reboots to its RAM test, NO prior graphical/sound
corruption = a clean jump through a bad pointer, not data rot) points at a
Phobos move whose execution dereferences a bad pointer. The CPU AI uses
Phobos's full moveset; a human in 2P may simply never have thrown the exact
move — which makes "2P clean" most likely a COINCIDENCE, exactly as the
maintainer cautioned, not a property of the 1P path.

**This is the 14z-73 grab-victim SHAPE** (a move indexing a per-victim
keyframe/effect table that, for one victim, reads a bad row), possibly UNIFIED
with the unbounded per-node sfx dispatcher (an anim node carrying an
out-of-range sfx class in its `+0x16` trigger -> `0x27F16` jumps through
`table[badclass]`). Both are "a specific move -> a bad pointer jump" and both
fit every observation.

**THE DISCRIMINATING TEST (maintainer, on hardware): 2P, HUMAN Phobos vs human
Donovan, deliberately spam Phobos's suspected move (5MP/6MP).** If it crashes,
the arcade path is IRRELEVANT and the bug is in Phobos's moveset vs a tenant
victim — chase Phobos's move/effect/keyframe data. If Phobos genuinely cannot
crash it in 2P no matter the move, the 1P-arcade path really is special and the
borrow/AI path comes back. Either answer halves the search.

### NEXT (measurement, not arbitrage — per the maintainer's standing ask)

Reach the pairing NATURALLY and TRACE the borrow's actual write to `+0x382`
for a Phobos opponent: re-measure the continue-switch trajectory for
merged13 (its header documents how) OR a fresh venue-steered marathon, then
tap `$FF8782`/`$FF8B82` through the Donovan-vs-Phobos match. If a class
whose `table[class]` is a bad pointer appears, that is the root cause and
the fix is either bounding the dispatcher or fixing what the borrow writes
for a tenant opponent. The 2P sim (core) is a cross-check, not the hunt.

## Session 14z-109 CLOSE — ritual complete. **THE ARC'S QUESTION IS
## ANSWERED AND THE ONE DEFECT IT SURFACED IS ROOT-CAUSED AND RULED.** The
## core WORKS ON HARDWARE — tenants fight, TENANT VOICES PLAY, select
## emulator-identical. The one crash is #99 = vs2 type byte `0x51` in
## Donovan's ported node stream, remap ruled `0x51 -> 0x19` with the census
## + escalation clause. **The next session is the FIX WINDOW.**

**The session in one line:** it opened waiting for a field test, and by
close the field test had passed, its single crash had gone from "flaky
reset on a CRT" to a named byte at a named ROM address with an
instruction-level-exact fix ruled — with the maintainer's live observations
(2P-clean, the sidekick's silence, "long enough", the reset style, the
Bishamon crash) cutting the search space at every step.

### WHAT THE SESSION ESTABLISHED

| | result |
|---|---|
| the FIELD TEST | boots, plays, tenants fight on real silicon; VOICES PLAY; select emulator-identical |
| #99 root cause | node `0x3FB899` (Donovan block) carries vs2 state `0x51`; vsavj table ends ~`0x28`; unbounded dispatch at `0x018508` -> vec3 -> soft reboot |
| the ruling | (a) data-side remap only (b) `0x51 -> 0x19` (byte-identical default handlers) (c) census + escalate non-equivalents; port-the-handler caveat STANDING |
| the OBJ-list oracle | promoted subset field-identical across implementations at match anchor AND select; M6 mark identical |
| P2 scripting | fork `4dfc3734`, file bits 12+, frozen sha1s provably unmoved; first 2P replay in the tree |
| the exception decoder | name-screen reboot = CPU exception, code at `$FF0000`, regs at `$FF0018-53`; gold test = cold/watchdog |
| venue steering | draw pool = `row[venue..venue+7]`, 12/12 measured — deterministic opponent pinning exists now |
| decisions hygiene | `DECISIONS_HISTORY.md` born; STATE pending section: 5 live entries |

### THE CORRECTIONS, because they transfer

Four intermediate theories died by my own measurement and are marked in
place: the arcade voice-class borrow (candidate rows only carry valid
classes); the sidekick OBJECT (right neighborhood — a Phobos-side 1P event —
wrong object: A1 was P2's player block); "Phobos-specific" (Bishamon
crashed it too — the node is DONOVAN'S); and my mis-ID of probes C/D's
opponents from an assumed id map (0x0f = Jedah, not Bishamon — the
authoritative slot map is character_tables.md, assume nothing).

### RITUAL

- **STATE**: this entry; the (3)-(8) sub-entries stand; no rollover needed
  (two session groups live, file ~120 KB).
- **`docs/NEXT_SESSION.md`**: rewritten — the opener is the #99 FIX WINDOW
  (census -> remap `fixes` rows -> #111 coverage -> re-freeze -> the MiSTer
  CRC tail: catalogue fork commit + fresh board bundle).
- **`HANDOFF.md`**: `test_obj_records` + `test_mister_obj_oracle` rows
  registered.
- **Retraction sweep**: "P2 is not expressible" corrected in
  `rpl2siminputs.py`, `docs/platform/mister.md` (x2), NEXT_SESSION history
  marker; the DF-style stale reference in engine_internals fixed in
  passing during the decisions cleanup.
- **GOTCHAS**: three filed and indexed (name-screen exception discriminator;
  the renumbered-family porting rule; the deterministic-lab-rat triage
  method).
- **Memories**: `port-the-handler-is-not-free` (maintainer's standing
  instruction); `decided-items-leave-pending` extended with the
  DECISIONS_HISTORY lifecycle.
- **GitHub**: #99 reopened + root cause + ruling (current); #111 filed
  (coverage rot). Both self-contained.
- **SCRATCH**: `/tmp/vampire-saved-jtsim-14z108` (1.3 GB) SWEPT — the
  14z-108 close kept it for the field test, the field test has reported;
  rebuild is one `tools/setup_jtcores.sh` + `run_sim` away.
  `../mister_fieldtest_14z108/` DURABLE but STALE AT THE RE-FREEZE (CRCs
  move). `../dumps/` is the maintainer's dump folder (root litter swept
  there, README inside, all regenerable). Session scratchpad ephemeral;
  every conclusion is in STATE/docs/#99.
- **PUSH**: everything pushed through the close commit; fork public at
  `4dfc3734`. Verified `git ls-remote`, not prose.

## Session 14z-109 (3) — **THE FIELD TEST RAN, AND THE ARC'S QUESTION IS
## ANSWERED: THE CORE WORKS ON HARDWARE.** Tenants selectable and playable,
## TENANT VOICES PLAY (the one thing simulation could never answer), select
## screen emulator-identical. **AND ONE 100%-REPRODUCIBLE CRASH — which is
## #99 BACK FROM THE DEAD, now with a deterministic repro path it never had.**

**The maintainer's field report (MiSTer, DE10-Nano, 2026-08-26), verbatim in
substance — the primary artifact:**

- Boots; 1P vs COM plays well, general feel BETTER than emulator (likely
  input-lag/handling, the maintainer suggests).
- **Sound plays, INCLUDING THE NEW TENANTS' — all seems good.** ["Fetched is
  not heard" is retired: the QSound extension is now HEARD on hardware.]
- Select screen emulator-identical, usage-wise perfect (parked cosmetics
  aside, out of scope).
- All 3 tenants selectable, playable, no graphical or other issues before,
  during or after matches — with ONE exception:
- **A 100%-reproducible crash-reset: pick DONOVAN 1P in normal mode, first
  fight BISHAMON, WIN it -> second fight is ALWAYS PHOBOS (stage may vary,
  opponent never) -> crash-reset at the end of the character intro or just
  as the fight begins, regardless of input.** Not tried on emulator yet.
  Does NOT happen picking Phobos or Pyron as P1.
- 2P versus not yet tried; confidence high.

### THE CRASH IS #99, AND ITS CLOSURE DID NOT HOLD

Archaeology (CLAUDE.md §5, done BEFORE touching anything):
- **14z-94 (#99):** the SAME signature — Donovan vs CPU-Phobos, "crashed
  right after the character's intro at fight start" — on **MAME**, build
  merged9, reached via continue+switch to match 5. So the crash class is
  NOT MiSTer-specific.
- **14z-100:** `tests/audit_continue_switch.sh` reached the literal
  Donovan-vs-CPU-Phobos pairing at **match 4** on merged11 and ran clean —
  the basis for closing #99, with the caveat recorded at the time: "the
  clean pass is weak evidence" that #103's fix removed the trigger.
- **The field path is DIFFERENT and NEVER TESTED: match 2, reached by
  WINNING match 1 (vs Bishamon), no continue.** The 14z-100 rig cannot have
  exercised it.
- Also on the books: the 14z-94 LEAD, explicitly unmeasured then — the
  voice-class borrow (`ram.md:87`) writes a class from the OPPONENT'S
  candidate row into `+0x382` at match start; a tenant opponent makes that
  a tenant class; and the crash timing (right after the intro) is when the
  dispatcher first fires.

**In flight: an emulator repro attempt** on merged13/MAME under the crash
guard — if it reproduces, the full instrument set (write taps with PC
attribution, per-frame dumps) applies; if it does not, the difference
between implementations is itself the lead.

## Session 14z-109 (2026-08-25/26) — **THE FIELD TEST GAINED A NEGATIVE
## CONTROL IT DID NOT HAVE, AND THE OBJ LIST BECAME THE FIRST WORKING
## CROSS-IMPLEMENTATION VIDEO ORACLE.** Opened while the maintainer's
## hardware test was pending, so everything here is work that does not need
## the board. **IN FLIGHT AT THE TIME OF WRITING: the field test itself.**

**The session in one line:** it started as housekeeping during a wait, found
that the field test was about to be run WITHOUT a control, and ended by
making a video-determining surface agree across two unrelated codebases for
the first time.

### WHAT WAS ESTABLISHED

| | result |
|---|---|
| the field-test bundle | had **ONE MRA and no control**; now carries a STOCK CONTROL leg |
| MRA part resolution | **WIDE 31/31 resolve, STOCK 22/22** after the pristine swap — measured, not assumed |
| the bundle README | item 5 was **STALE**, corrected later in 14z-108 than the README was written |
| the fork README | brought to D0-D5 (was "slice D1", 5 files against the tree's 13) |
| the OBJ list as an oracle | **WORKS** — promoted subset 31 vs 31, field-for-field IDENTICAL |
| the walker | calibrated **1153/1153 lines** against the live-machine one BEFORE use |

### THE RESULT THAT MATTERS

At the frozen tenant anchor (`36_pick_tenant_cell`, MAME 2886 / sim 3546) the
**PROMOTED** subset of the OBJ list is **31 entries on BOTH legs, ORDERED AND
FIELD-FOR-FIELD IDENTICAL**, and the 19-bit tile addresses slice D3 computes
are the same set, **`0x4b0c4-0x4ecda`**. The promote, the group-C redirect and
the 3-bit bank are confirmed against an unrelated codebase at the sprite-list
level. **First cross-implementation agreement this project has on a
video-determining surface, and it is on the content the port exists to add.**
**STILL NOT PIXELS** — this is the LIST, not the rendered frame.

### THE CORRECTION, WHICH IS WORTH MORE THAN THE RESULT

The raw lists do NOT match: **40 entries vs 129**. I reported that mid-run as
"a real difference — the core genuinely holds a shorter list". **THAT WAS
WRONG.** A 1P replay's CPU opponent is the SOUND-STATE-FED LOTTERY
(`atlas/ram.md:99`) and genuinely differs between the legs —
`test_mister_tenant_oracle` **already excludes the P2 fields BY NAME for this
exact reason**, and I had that fact in front of me before I ran anything.
Most of the list is the opponent's sprites.

What rescues the surface: an OBJ list cannot be filtered "by P2" the way a
field table can — **sprites carry no owner** — but OUR content IS labelled.
**y bit 12, the CPS-2 Turbo promote, is set on exactly the group-C sprites
this port adds and on nothing vanilla can emit.** So the promoted subset is
ours, is lottery-free, and must agree exactly; the remainder is REPORTED,
never asserted.

**THE LEGACY CONTROL WAS RUN AND IS ALSO CONFOUNDED — recorded so it is never
read as evidence.** `05_timeout_idle` is 1P arcade too, so it draws different
opponents as well (counts agree 52/57 vs 61, codes barely overlap). **A clean
WHOLE-list comparison needs a PINNED OPPONENT, which needs P2 scripting in
`SimInputs` — still the deferred COVERAGE item, and now with a concrete
reason to want it.**

### THE FIELD TEST HAD NO CONTROL

The bundle shipped one MRA, so any failure — black screen, boot loop, wrong
art — would have been indistinguishable between "our profile is wrong" and
"the bitstream, the card, the SDRAM module or the video chain is wrong".
By this project's own standard that is not a measurement. Added (outside the
repo, rule 7): the **STOCK CONTROL MRA** (vanilla `vsavj` on the SAME `.rbf`
with the profile bit at the `0xFF` fill — verified, the file names
`<rbf>jtcps2w` and contains no `0xFE`), `games/mame/vsavj.zip`, and
`FIELD_TRIAGE.txt` (nine symptoms, each with meaning and next action).
**Measured on the way: pointed at the bundle as shipped the control MRA loses
8 of its 22 parts** — four patched art members AND four program members — and
jtframe `0xFF`-FILLS an unresolved part rather than refusing, so it would have
"run" and shown nonsense.
**The pre-D5 boot loop converted to something usable at a board: ~26.5 s** at
the real 59.6374 Hz (`8 MHz / (512*262)`, MAME `cps1.h:39-45`).

### RETRACTION DISCIPLINE — THE SWEEP HAS TO LEAVE THE TREE

The bundle README's item 5 called the identical 128 KB "scroll tilemap", said
the layer-enable registers were undocumented, and invited treating a
wrong-looking background as "the first hard evidence either way". All three
were corrected LATER in 14z-108 than the README was written. **The bundle
lives OUTSIDE the repo, so the CLAUDE.md §5 grep over `docs tests` could never
have found it.** When a claim is corrected, the sweep must reach artifacts
that have already left the tree.

### NEW INSTRUMENTS, all with must-fire controls

- `tools/check_mra_parts.py` + `tests/test_mra_parts.sh` (ci_portable, ROM-free)
- `tools/oram_obj_records.py` + `tests/test_obj_records.sh` (~2 min, MAME only)
- `tests/test_mister_obj_oracle.sh` (~65 min; `--sim-dir/--mame-log` re-analyse
  finished runs). **Its page selection does NOT hard-code a buffer:** CPS-2
  ORAM is double-buffered with a runtime page select
  (`main_addr_x[13] = main_ram_addr[15] ^ obank`), so it walks both and lets
  the comparison choose. Hard-coding a page is how a phase difference gets
  reported as a content difference.

### PUSH STATE

`origin/main` holds **`613db08`** (verified with `git ls-remote`, not a
tracking ref). The fork README commit `c97e3d14` was **deliberately NOT
pushed** at the maintainer's instruction, and the main-repo commit that bumps
the `emu/jtcores` pin to it is therefore held back too — publishing it would
point public `origin/main` at a fork commit the fork remote does not carry.
**Push the FORK first, then that commit — never that commit alone.**
**[RESOLVED 2026-08-26: the maintainer authorised the fork push. Done in
that order — fork `c97e3d14` first, then the pin bump. `origin/main` now
holds `10cf9ce` and NOTHING is local. The ordering rule above is kept
because it is the general lesson, not because anything is still stranded.]**
The two
commits were reordered (disjoint by file) so everything else could ship; the
resulting tree hash was verified byte-identical before each push.

### VERIFICATION

`tests/run_all_static.sh --strict` GREEN at the session open (PASS 107) and
after the changes (**PASS 108**, SKIP 0, FAIL 0, MISSING 0), with the tree
clean under the run — the 14z-108 discipline (commit first, then run, then do
not type) followed this time.

## Session 14z-108 CLOSE — ritual complete. **THE FUNCTIONAL CHAIN IS
## COMPLETE IN SIMULATION AND THE CORE FITS A CYCLONE V — BUT IT DOES NOT
## RELIABLY CLOSE TIMING.** A tenant FIGHTS on the core and fights
## CORRECTLY against MAME; the QSound extension is FETCHED; bank 1 under
## load is GO; scroll is structurally cleared; the CPS-2 video registers
## are documented for the first time. **AND THE SESSION'S OWN HEADLINE IS
## THAT FOUR OF ITS FINDINGS WERE CORRECTIONS OF THINGS PUBLISHED EARLIER
## THE SAME DAY** — three of them mine. **22 commits, ALL LOCAL.**

**The session in one line:** it opened on a two-data-point inference about
the simulator's joystick, proved that inference wrong by measuring all four
directions, and that one fix unblocked every remaining question in the arc.

### WHAT WAS ESTABLISHED, each with a control that fires

| | result |
|---|---|
| the input path | **REVERSED end for end**, not transposed in two — measured on all four against `RAM:$FF8058` |
| a tenant FIGHTING | obj bank 4: **9,388,928 reads / 1,735 tile codes**, 843 traffic frames INSIDE the match; control leg zero |
| fighting CORRECTLY | §4 oracle agrees with MAME field-for-field; `p1_hitbox_base 0x003FA9D0` on BOTH legs |
| the QSound EXTENSION | **210,180 reads in DSP bank `0x83`**; control leg zero while still streaming 54 M low-bank reads |
| bank 1 under load | peak 15,496 acc/frame = **12.5% of ceiling**, ZERO clashes |
| FIT on a Cyclone V | **+206 ALMs (+1.1%)**, RAM blocks / DSPs / PLLs unchanged |
| scroll | **structurally cleared** — D2 cannot have moved it, by construction |
| the video registers | documented in `atlas/ram.md` for the first time |

### THE ONE HARD RESULT

**`cps2w` does NOT reliably close timing: 4 of 12 seeds fail** (median
+0.038 ns against the control's +0.431; two "passes" clear by under 10 ps).
Every failing path is inside `jtframe_sdram64` — shared infrastructure the
fork does not touch — so it is not WIDE's logic being slow, it is WIDE
loading a cone that was already tight. **Ruled by the maintainer: A + B,
C in reserve, D acceptable, E opposed.** B is IMPLEMENTED: releases are
built from a NAMED seed with slack and sha256 verified.

### FOUR CORRECTIONS, WHICH IS THE PART THAT TRANSFERS

1. **"The main repo is NEVER pushed" was FALSE** — `git ls-remote` showed
   `origin/main` at the 14z-107 close. True when written, copied forward as
   standing fact, including by me into a banner an hour earlier.
   **A tracking ref is a claim about the last fetch; prose is a claim about
   the day it was written.**
2. **The jtseed claim was OVERSTATED, by me more than by its author.**
   `jtseed 4` retrying does NOT ship failing bitstreams (~99% of invocations
   pass) — **it hides FRAGILITY, not correctness. A green run certifies "one
   placement was found that closes", never "this design closes with
   margin".**
3. **I called unclaimed VRAM "scroll tilemap".** No layer base points above
   `$910000`; the agreement was real but misnamed, and the naming made the
   layers sound like they agreed when the opposite was true.
4. **The VRAM difference is NOT ours.** The legacy control — stock `vsavj`,
   vanilla replay, same core — reproduces the same pattern and magnitudes.
   **The useful negative: VRAM is not a viable cross-implementation video
   oracle**, because two implementations legitimately differ there by half
   the palette.

### INSTRUMENT DISCIPLINE

The lane's defect count reached **eight**, and 14z-108 added **five more
caught BEFORE use** — four in one new analysis block (cumulative counters
read as per-interval; a picosecond timestamp read as an index; a clash
counter matching this report's own PROSE; a "peak" that was the ROM
download) and one check that **passed because macOS awk lacks `and()`** and
exited into the `else` arm. A sixth was a control that fired for the WRONG
REASON: byte-swapped dumps have no anchor, so the field comparison never
ran. **A control that never reaches the code under test is not a control.**

### RITUAL

- **STATE**: this entry. **THE ROLLOVER EXECUTED on the SIZE arm** — the
  whole 14z-107 group (4 entries + the sub-entry pointer, 1,087 lines) moved
  BYTE-VERBATIM to `STATE_HISTORY.md` with its ledger line here, verified by
  sha256 and by the absence of any `## Session 14z-107` header.
  **STATE.md 207,725 -> 136,520 B — under the ~150 KB guide for the first
  time in this arc.**
- **`docs/NEXT_SESSION.md`**: rewritten. The opener is **THE FIELD TEST**,
  which is the maintainer's and is the only thing that moves the arc.
- **`HANDOFF.md`**: MiSTer block current, three new gate rows registered.
- **GOTCHAS**: six filed and all six indexed — the reversed directions,
  macOS awk, Quartus needing `--network host`, `git clone --recursive`
  resolving against the default branch, `xjtcore.sh` retrying until a seed
  passes, and the BUILD datestamp defeating hash reproduction.
- **THREE MAINTAINER RULINGS** taken and marked DECIDED in place: the
  timing-margin response, MiSTer packaging (option A now, B later), and the
  field test scheduled.
- **A STANDING WARNING I BROKE THREE TIMES TODAY, recorded because the
  pattern is the point.** "Do not touch the tree while something long is
  reading it" exists because `sh` reads scripts by byte offset — and while I
  never edited a script mid-run, I edited STATE.md/HANDOFF.md under a running
  `run_all_static.sh` three separate times, each of which made the suite
  report the working tree as DIRTIED. Harmless every time (the gates were
  clean; the dirt was mine), which is exactly why it kept happening: a
  warning whose violation is usually harmless is one that erodes. The
  discipline that actually works is the one 14z-107 used — **commit first,
  then run the suite, then do not type until it finishes.**
- **SCRATCH HYGIENE — one clone DELIBERATELY KEPT, against the 14z-107
  precedent.** `/tmp/vampire-saved-jtsim-14z108` (1.3 GB) is rebuild litter by
  the project's own standard and 14z-107 swept eleven such clones. **It is
  kept because a FIELD TEST is imminent and any surprise from it is most
  cheaply diagnosed by a follow-up simulation**, which this clone makes
  immediate instead of costing a full ROM build first. Stated rather than
  left silent so it is a decision and not an omission; sweep it once the
  field test has reported. The session scratchpad (163 MB of dumps, probe
  logs and comparison legs) is ephemeral by construction and every
  conclusion drawn from it is in this entry or the live docs.
  **`../mister_fieldtest_14z108/` (28 MB) is DURABLE and must not be swept**
  — it is the field-test bundle, and it lives outside the repo because it
  carries ROM content (rule 7).

## Session 14z-108 — **THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR
## END, NOT TRANSPOSED IN TWO — measured on all four before one bit was
## changed, and the half nobody had exercised is where the previous reading
## was wrong.** `tools/rpl2siminputs.py` fixed (one dict, no fork commit, no
## RTL), verified against the game's own input mirror on both
## implementations, and the gate rebuilt with a per-direction lock and a
## must-fire control. **One of the two frozen expectations the record said
## would move DID NOT MOVE AND COULD NOT** — which also means the frozen sim
## anchor could not move. **AND THE PAYOFF LANDED THE SAME SESSION: OBJ BANK 4
## — THE FIGHTER ART — IS FETCHED FOR THE FIRST TIME ON ANY FPGA
## IMPLEMENTATION, 843 OF ITS TRAFFIC FRAMES INSIDE A MATCH. A TENANT HAS
## FOUGHT ON THE CORE.** Bank 1 under load answered from the same run and it
## is GO. **Still never: HARDWARE — and no Quartus synthesis has ever been
## run, so resource fit and timing closure are unknown. That is now the
## largest gap in the arc.**

**The opener, and it was the whole point of doing it in the stated order.**
`docs/NEXT_SESSION.md` said: measure all four directions BEFORE changing
anything, because what existed was two data points and the inference on the
table was an inference. It was wrong, and the order caught it.

### THE MEASUREMENT

`tests/replays/107_four_directions.rpl` — U, D, L, R one at a time, 5 frames
each, 40 frames apart, **attract only: no coin, no start, no roster
content**, so this is a property of the INSTRUMENT and runs on stock `vsavj`
in ~15 min instead of a boot-to-select run on the WIDE image. Read off the
game's own P1 input mirror `RAM:$FF8058.w` on both implementations, MAME
against `cps2w` under Verilator, both dump sets integrity-checked (151 and
176 frames), **20 nonzero frames on each leg = exactly the 4 presses x 5
frames the replay scripts**:

| asked | MAME | core, pre-fix | delivered | core, post-fix |
|---|---|---|---|---|
| Up    | `0x0008` | `0x0001` | Right | **`0x0008`** |
| Down  | `0x0004` | `0x0002` | Left  | **`0x0004`** |
| Left  | `0x0002` | `0x0004` | Down  | **`0x0002`** |
| Right | `0x0001` | `0x0008` | Up    | **`0x0001`** |

**THE NIBBLE IS REVERSED END FOR END.** 14z-107 (12) had seen only Left and
Down — the only directions `36_pick_tenant_cell` presses — and inferred a
two-bit SWAP leaving Up and Right untouched, on the strength of the
translator's own docstring. **Up is not untouched: it arrives as Right.** A
two-bit fix would have left half the defect in the tree and the gate would
have frozen it.

**MECHANISM, derived from the bit ORDER and then confirmed.**
`test.cpp:380` copies the file's bits 4-7 straight onto `joystick1[3:0]`, and
jtframe's joystick port is **MSB-FIRST** — `joy[3]=Up [2]=Down [1]=Left
[0]=Right` (`jtframe_keyboard.v:107-110`, the authoritative order;
`_JTFRAME_JOY_RLDU` being a full nibble reversal is only consistent with
that). So the file map is `bit4=Right bit5=Left bit6=Down bit7=Up`, and the
translator had read the macro NAME "UDLR" as "bit4=Up … bit7=Right".

**FAULT ATTRIBUTION: OURS, NOT jtframe's** — unlike the three input-path
defects before it, which were upstream and fixed in the fork. jtframe
documents no `sim_inputs.hex` direction spec; the nibble is simply
`joy[3:0]`. **Fix = one dict. No fork commit, no RTL.** The fork pin is
unchanged at `7b9a0d2d`.

### THE FROZEN EXPECTATIONS: ONE MOVED, ONE COULD NOT

The record said in FIVE places that a bit-map fix would move both of
`test_rpl2siminputs`'s frozen values. **It moved one.**

* check 1's vector: `111 6ee 000 000 080` -> **`181 67e 000 000 010`**,
  re-derived by hand with the mechanism named in the gate header.
* check 3's `05_timeout_idle` sha1 `eb3e1d04e58b3a2b7bf713d40c4d6ac4796e550c`
  **did not move and cannot**: that replay scripts a coin, a start and one
  button-1 tap and **no direction token**.
* **Therefore `test_mister_sim_anchor`'s frozen anchor (MAME 2146 / sim 2609 /
  skew 463) could not move either** — its replay is `05_timeout_idle`, whose
  `sim_inputs.hex` is byte-identical across the fix. It was NOT re-run, and
  the gate header states that as the reason rather than leaving it to be
  assumed. That is a 45-minute gate not run on evidence, not on convenience.

Corrected in place in `STATE.md` (the 14z-107 entry), `NEXT_SESSION`,
`docs/platform/mister.md`, `docs/platform/gotchas.md`, `docs/GOTCHAS.md` and
`HANDOFF.md`. **It mattered: "expect it to move" is how a hash gets re-frozen
without anyone asking why.**

### THE GATE, REBUILT (11 checks, all green)

* **check 5** locks each direction to its measured file bit individually.
  Check 1 presses three directions at once and would pass under ANY
  permutation of the four — which is exactly how the reversal survived.
* **check 5b** is a MUST-FIRE CONTROL: it rebuilds the pre-14z-108 reversed
  map and requires check 5 to reject it.
* **check 6** asserts the anchor-independence MECHANISM directly (05 sets no
  direction bit) instead of resting on a hash, with **6b** its positive
  control.
* **AND 6 PASSED FOR THE WRONG REASON IN ITS FIRST DRAFT** — it used gawk's
  `and()`/`strtonum()` on a BWK awk, so awk exited 2 and the `else` arm read
  as success. Caught by writing the control before trusting the check. THE
  INSTRUMENT PROTOCOL, working on the session that wrote it into a gate.

### THE BANK-LOAD AUDIT CAN NOW TAKE A REPLAY, AND REFUSES TO MISLABEL IT

`tests/audit_sdram_bank_load.sh --rpl FILE` (+ `--stats` on both legs of
`test_mister_gfxc_fetch`), so the tenant match answers the FETCH question and
the BANK-1-UNDER-LOAD question from ONE simulation instead of a third
70-minute run. The four phase boundaries are absolute frames keyed to
`05_timeout_idle`'s anchor, so with `--rpl` the phase table is **REFUSED**
and whole-run figures + the clash count are reported instead.

**THE NEW BLOCK WAS WRONG FOUR TIMES AND EVERY ONE WAS CAUGHT BEFORE USE** —
cumulative counters read as per-interval (means in the tens of millions);
`t` read as a reporter index rather than picoseconds (frame numbers in the
billions); the bare substring `SDRAM reads clashed` counted, which scores
this report's OWN PROSE as evidence (and
`build/sdram_bank_load_14z107.log` is exactly such a file — it is a REPORT,
not a `jtsim.log`); and a "peak" of 100,614 acc/frame IDENTICAL on all four
banks, which is the ROM DOWNLOAD — one write command per byte at a constant
rate to one bank at a time. Validated by construction on synthetic logs
(rates of exactly 10/5/2/3 per frame read back exactly; a pre-transfer
sample that must be dropped, and is; 3 real WARNING lines counted as 3, the
same text as prose counted as 0), and the default path still reproduces the
frozen 14z-107 table unchanged.

### THE PAYOFF: A TENANT HAS FOUGHT ON THE CORE

`tests/test_mister_gfxc_fetch.sh --rpl tests/replays/36_pick_tenant_cell.rpl
--frames 4400` — **PASS in full**, both halves, both controls, 93m26s a leg.

| probe | window | reads | distinct codes | first frame | codes | frozen extent |
|---|---|---|---|---|---|---|
| p0 **obj bank 4, FIGHTER art** | ba1 `800000` | **9,388,928** | **1,735** | 1781 | `0xAD8F-0xEE42` | `0xEE73` INSIDE |
| p1 obj bank 5, wheel art | ba0 `7E0000` | 19,246,336 | 206 | 1556 | `0x74D6-0xFE41` | `0xFFDB` INSIDE |

**Obj bank 4 had never been non-zero on any core.** 843 of its 2,331 traffic
frames are AFTER match start (absolute 3559 = MAME's replay-frame ~2900 plus
the 659-frame WIDE transfer), running to the replay's last frame.

**THE COHERENCE IS THE EVIDENCE, more than either count.** The two group-C
probes behave according to their CONTENT: the wheel art stops at the
select/VS boundary (last traffic frame 3498, zero after) and the fighter art
carries through the match. A promote addressing the wrong thing does not
produce that split.

**THE CONTROL LEG READS ZERO** from both group-C windows — the SAME `.rom`
with header byte 41 `0xFE`->`0xFF`, one byte, the runtime profile bit — while
still issuing 105,418,104 reads in bank 3, and its working set is the LOOPING
boot's 263 distinct blocks against the positive leg's 6,208. So the zero is
about the profile, not about the probe.

**AND THE REPLAY WAS CONFIRMED ON MAME FIRST**, before 2.5 hours of
simulation were spent on it: `36_pick_tenant_cell` on the WIDE romset under
the source-built MAME reaches **P1 `+0x382 = 0x13`** — the tenant's native
vs2 id — with hitbox base `+0x60.l = 0x03FA9D0` (relocated tenant data) and
the match live from replay frame ~2900. So a zero from the sim would have
been a finding about the CORE, not about the replay. That is the
rig-produces-the-real-event discipline, applied before the cost was paid
rather than after.

### BANK 1 UNDER LOAD: ANSWERED FROM THE SAME RUN, AND IT IS GO

`--stats` on the fetch gate's legs (14z-108) means the tenant match answers
`mister_core.md` §12's other open question without a third 70-minute run.
Whole run, 3,738 post-transfer frames:

| bank | acc/frame | peak | % ceiling at peak |
|---|---|---|---|
| ba0 | 40,985 | 54,363 | 43.9% |
| **ba1 (PCM + group-C obj bank 4)** | 11,905 | **15,496** | **12.5%** |
| ba2 | 149 | 3,336 | — |
| ba3 | 3,765 | 6,161 | — |

**ZERO `SDRAM reads clashed` warnings in 3,738 frames.** The 14z-107 (12) run
measured ba1 at 13,890/frame with PCM ALONE (it picked Demitri); the tenant's
fighter art now shares the bank and adds ~1,600 accesses/frame at peak
without contending. **The repack's bank-1 half is GO on measurement.**
Caveat: ONE replay, ONE tenant, one opponent.

### WHAT IS STILL NEVER

**HARDWARE.** Nothing in this lane has left Verilator, and — recorded here
because it had never been named as a gap — **no Quartus synthesis has ever
been run on any slice**, so neither RESOURCE FIT nor TIMING CLOSURE is known
for `cps2w` or, for that matter, for the reference `cps2` on the same
toolchain. Functional simulation says nothing about either. That is now the
largest unknown in the arc and it needs no hardware to answer: Jotego ships
the toolchain as a Docker image (`jotego/jtcore20x`,
`.github/workflows/q20.yaml:51`), so `xjtcore.sh cps2w mister` plus the same
for `cps2` as the REFERENCE LEG produces fmax and utilisation for both.
Quartus is Linux/Windows only, so it cannot run on this Mac. Also still
never: the QSound extension heard, the scroll path with a wide GFX map, and
any frame compared programmatically against MAME's.

### AND THE TENANT FIGHTS *CORRECTLY* — THE §4 ORACLE ON AUTHORED CONTENT

**Fetching art is plumbing; this is the first evidence the tenant BEHAVES.**
CLAUDE.md §4 requires new-character content — for which no vanilla oracle can
exist — to agree with a second implementation on mapped gameplay state at
sync anchors. That protocol had never been run on tenant content against the
core. It has now, and it AGREES.

`36_pick_tenant_cell`, the WIDE romset, MAME against `cps2w` under Verilator,
both dump sets integrity-checked (301 and 351 frames):

| | anchor | |
|---|---|---|
| MAME | **2886** | |
| sim (absolute) | **3546** | |
| skew | **660** | = the 659-frame WIDE transfer **PLUS ONE** |

**THAT +1 IS A RESULT IN ITSELF.** The legacy replay shows skew 463 on a
462-frame transfer — also +1. Two different replays, two different romset
sizes, the same one-frame offset: **the boot-phase difference between MAME
and the core is a CONSTANT, not a function of the content.**

**P1 IS THE TENANT ON BOTH SIDES, byte-identical:**

| field | MAME @2886 | `cps2w` @3546 | |
|---|---|---|---|
| `p1_hitbox_base` | `0x003FA9D0` | `0x003FA9D0` | the RELOCATED tenant record, in `wide_ext` |
| `p1_ptr64` | `0x003FA790` | `0x003FA790` | likewise |
| `p1_hp` / `p2_hp` / `p1_white_hp` | `0x0120` | `0x0120` | |
| timer / `p1_x` / `p1_y` / meter / word132 | — | — | all agree |
| `p2_hitbox_base` | `0x000ABD74` | `0x0009769E` | **EXCLUDED BY NAME** |

**The core did not merely fetch tenant tiles — it LOADED THE TENANT'S
RELOCATED CHARACTER RECORD from above `CPU:$400000` and ran the match on it.**
`compare_fields` reports "all compared fields agree".

**THE ONE DISAGREEMENT IS THE DOCUMENTED ONE, AND ITS BEING LIVE IS USEFUL.**
`p2_hitbox_base` differs because the CPU opponent is a SOUND-STATE-FED lottery
(`ram.md:99`, the #110 mechanism) — the same class as the legacy anchor's
`$0AE9D4` vs `$0A9518`. It is in the skip list for a measured reason. That it
FIRES here proves the field set is not passing vacuously.

**THE COMPARISON WAS PROVEN ABLE TO FAIL BEFORE ITS PASS WAS BELIEVED.** The
first control tried was a byte-swap of the sim dumps — it "fired", but for the
wrong reason: the swapped data has NO ANCHOR, so the field comparison never
ran at all. **A control that never reaches the code under test is not a
control.** Replaced with a perturbation of the TIMER — compared, but not an
input to the anchor predicate — which keeps both anchors intact and is then
caught and NAMED at all three follow offsets. Both controls are in the gate.

**CAPTURED AS A GATE**, per the persistent-suite doctrine:
`tests/test_mister_tenant_oracle.sh` (emulator tier, ~65 min), with the
anchors and skew frozen, the tenant-record assertion on both legs, and the two
controls above plus a third that removes the skip list and requires the legs
to disagree.

### FIRST CROSS-IMPLEMENTATION COMPARISON OF A VIDEO-DETERMINING SURFACE

**"Video compared against MAME" has been NEVER for the whole arc.** Pixels
need infrastructure neither side has, but `$900000-$93FFFF` is VRAM — the
palette and the scroll tilemaps, the data that DETERMINES the frame — and it
is dumpable on both: by address on MAME, and on the core because D2 maps it
to SDRAM bank 0 byte `0x600000` (`VRAM_OFFSET = 23'h30_0000`). 256 KB a
frame, 21 frames a leg, both integrity-checked, compared at the frozen
anchors (MAME 2886 / core 3546).

| region | differing bytes | |
|---|---|---|
| `$900000-$901FFF` | **0 / 8,192** | identical |
| `$902000-$903FFF` | 3,659 / 8,192 | 44.7% |
| `$904000-$907FFF` | 475 / 16,384 | 2.9% |
| `$908000-$90FFFF` | 6,140 / 32,768 | 18.7% |
| **`$910000-$91FFFF`** | **0 / 65,536** | **identical** |
| **`$920000-$92FFFF`** | **0 / 65,536** | **identical** |
| `$930000-$93FFFF` | 0 / 65,536 | zero on both |

**[CORRECTED LATER THE SAME SESSION — READ THE SUBSECTION BELOW. I called
the identical 128 KB "scroll tilemap"; the CPS-A registers say NO LAYER BASE
POINTS THERE at a match anchor, so it is UNCLAIMED VRAM. The agreement is
real and not vacuous — 32,407 nonzero bytes, identical — but it is not what
I said it was, and the regions that DO carry live layers are the ones that
DIFFER.]**

The first video-determining data this project has ever compared, cut at the
time along arbitrary 8/16/32 KB boundaries rather than along the layer map.

**AND `$930000-$93FFFF` IS ZERO ON BOTH** — which matches
`pre_vram_cs <= A[23:18]==6'b1001_00 && A[17:16]!=2'b11`, the RTL decoding
that quarter out. The two implementations agree on the region's SHAPE before
a byte of content is compared.

**THE DIFFERING WINDOW IS `$902000-$90FFFF`, 10,274 bytes = 3.92% of VRAM,
AND IT IS NOT A PHASE ARTEFACT.** Swept across ±20 frames of core dumps
against the fixed MAME anchor the count is FLAT (10,267-10,305), so it is not
the one-frame skew. Both legs are near-static there (a few dozen bytes move
over 20 frames). The word histograms are nearly IDENTICAL — `0x0000`
9,427 vs 9,578, `0x00c0` **4,096 vs 4,096**, `0x0060` 3,575 vs 3,576,
`0x0382` 2,464 vs 2,467 — so it is the same KIND of content in both, differing
in specifics across 1,114 contiguous runs. Where MAME holds `0x0020,0x0000`
pairs the core holds live tile codes (`0x0b91,0x018d`).

### THE VIDEO REGISTERS ARE NOW DOCUMENTED, AND THEY RE-CUT THE RESULT

**The atlas had no entry for layer control at all** — that gap WAS the reason
the VRAM window could not be judged. Closed in `docs/game/atlas/ram.md`,
"CPS-2 VIDEO REGISTERS", from MAME 0288 as authority: CPS-A is at
`$804100` and is **WRITE-ONLY** (so it cannot be captured with a bus dump —
it needs the emulator's `cps_a_regs` SHARE, which is how these were taken),
CPS-B layer control is `+26`, and **every CPS-2 game shares one config**
(`CPS_B_21_DEF`).

**MEASURED AT THE MATCH ANCHOR:** SCROLL1 `$900000`, SCROLL3 `$904000`,
SCROLL2 `$908000`, PALETTE `$90C000`, row-scroll `$90E800`, and
**layer_control `0x2d0e` — scroll1, scroll2 and scroll3 ALL ENABLED.**

**RE-CUTTING THE VRAM DIFF ALONG THOSE BOUNDARIES CHANGES THE READING:**

| region | differing | |
|---|---|---|
| scroll1 `$900000` | 3,659 / 16,384 | 22.3% |
| scroll3 `$904000` | 475 / 16,384 | 2.9% |
| scroll2 `$908000` | 2,901 / 16,384 | 17.7% |
| **palette `$90C000`** | **3,239 / 6,144** | **52.7%** |
| row-scroll `$90E800` | 0 / 2,048 | identical |
| unclaimed `$90D800`, `$90F000`, `$910000+` | 0 / 204,800 | identical, and NOT zero |

**TWO CORRECTIONS TO WHAT I WROTE EARLIER TODAY.**
1. **The identical 128 KB is NOT "scroll tilemap".** No layer base points
   above `$910000` at this frame. It is UNCLAIMED VRAM. The agreement is
   real — 32,407 nonzero bytes, byte-identical — but I named it wrong, and
   naming it "tilemap" made it sound like the layers agreed when the
   opposite is true.
2. **"Neither a defect nor benign" is no longer the right hedge.** The
   differences sit in THREE ENABLED SCROLL LAYERS AND THE PALETTE, with the
   palette the worst at 52.7%. Live surfaces, not dead ones.

**THE LEGACY CONTROL WAS RUN, AND IT SETTLES IT: THE DIFFERENCE IS NOT OURS.**
Same core (`cps2w`), same VRAM region, same comparison — but STOCK `vsavj`
and the LEGACY replay `05_timeout_idle`, with the roster nowhere in sight
(MAME 2146 vs core 2609, the frozen skew 463):

| region | LEGACY (stock) | tenant (WIDE) |
|---|---|---|
| scroll1 | **35.4%** | 22.3% |
| scroll3 | **3.8%** | 2.9% |
| scroll2 | **15.1%** | 17.7% |
| palette | **51.2%** | 52.7% |
| row-scroll | **0%** | 0% |
| unclaimed | **0%** | 0% |

**Same pattern, same magnitudes, on VANILLA CONTENT.** So the palette and
scroll differences are a GENERAL MAME-vs-jtcps2 implementation difference and
say **nothing** about CPS-2 WIDE, the roster, or any slice. The alarm in the
subsection above is answered in the benign direction, and the hedge was the
right call.

**THE USEFUL NEGATIVE RESULT: VRAM IS NOT A VIABLE CROSS-IMPLEMENTATION VIDEO
ORACLE.** Two unrelated implementations legitimately hold different bytes in
the palette and all three scroll tilemaps — the palette by HALF — so
comparing that surface can never distinguish "our port broke something" from
"these are different implementations". Any future attempt at "compare video
against MAME" must use a different surface: rendered frames, the OBJ list, or
the palette AFTER the hardware's own conversion. **This closes off an
approach that looked promising, which is worth more than the measurement
was.**

**AND ONE POSITIVE SIGNAL INSIDE IT:** row-scroll and every unclaimed region
are BYTE-IDENTICAL in BOTH runs — 204,800 bytes, non-zero, across two
different romsets and two different replays. So the VRAM transfer and the
dump path themselves are sound; the differences are real content
differences, not an artefact of how either side is captured.

**WHAT STILL STOPS IT BEING CALLED A DEFECT, stated so the next session does
not over-swing the other way.** Two things are unmeasured: whether the
differing bytes fall in the VISIBLE portion of each tilemap (the layers are
larger than the screen, and the scroll X/Y registers select the window), and
**whether this difference is specific to our content at all.** The obvious
control has not been run: **the same VRAM comparison on a LEGACY replay with
the stock romset.** If MAME and jtcps2 differ there too, this is a general
implementation difference and says nothing about the roster. That control is
the next step and it is one ~60-minute sim leg.

**NOT CALLED A DEFECT AND NOT CALLED BENIGN.** Whether stale or differing
tilemap content is VISIBLE depends on the layer-enable and scroll-base
registers, which VRAM does not carry and **which this project has never
documented** — `grep` for layer control across the atlas and
`engine_internals.md` returns nothing. That is the gap to close before the
window can be judged, and it is now the concrete next step for the video
question rather than "compare frames somehow".
**[RESOLVED LATER THE SAME SESSION — both halves of this paragraph are
answered by the two subsections immediately below, and it is kept only as
the reasoning that got there. The registers ARE now documented
(`atlas/ram.md`, "CPS-2 VIDEO REGISTERS"): at the match anchor
`layer_control 0x2d0e`, all three scroll layers ENABLED. And the control
this paragraph called for WAS run: the difference is NOT ours — stock
`vsavj` on a legacy replay reproduces the same pattern and magnitudes, so
VRAM is not a viable cross-implementation video oracle at all. Do not act
on "the gap to close" above; it is closed. Marked 14z-109.]**

### THE QSOUND EXTENSION IS FETCHED ON THE CORE — the last zero-coverage subsystem

**Stock CPS-2 cannot address these banks at all**: `qsnd_addr[22:16] <=
dsp_ab[6:0]` keeps seven bank bits, so bank `0x8N` plays as `0x0N`. Reaching
them needs slice **D1**'s sample-bank width fix AND slice **D2**'s QSound
split across two SDRAM banks. Until now nothing had ever fetched one on an
FPGA implementation.

`108_tenant_voice.rpl` (36's wheel walk to the tenant, then walk-forward and
mash so the tenant throws attacks that CONNECT), 4,400 frames, `cps2w` + the
WIDE romset:

| probe | window | positive | control (profile bit CLEAR) |
|---|---|---|---|
| **QSound HIGH — the extension** | ba0 `0x6E0000`, 1 MB | **210,180 reads / 76 distinct / first frame 3783** | **0** |
| QSound LOW (liveness) | ba1 `0`, 8 MB | 86,746,380 | **54,113,994** |
| bank 3 (liveness) | ba3 | 171,296,680 | 105,056,248 |

**The addresses are `0x830AA0-0x83FFFE` — DSP bank `0x83`**, inside the
ledger's extension range `0x80-0x8E` and overlapping 8 of its 58 samples. The
first read lands **224 frames INTO the match, during the mash** — where an
attack voice belongs, not at boot.

**THE CONTROL IS WHAT MAKES THE ZERO MEAN SOMETHING.** With `wide_en` clear
the core still issues **54 million** QSound LOW reads — the DSP is
demonstrably streaming samples — and **zero** into the extension. So the zero
is about the PROFILE, not about a silent DSP or a dead probe.

**AND IT CONFIRMS THE `SLOT5_AW=20` TRUNCATION IS SAFE IN PRACTICE, not just
on paper.** Quartus warning 10230 flags `pcmh_addr = pcm_addr[PCM_AW-1:0]`
narrowing 23 bits to 20; that is the window MASK, lossless only while the
extension stays inside 1 MB. **Every address observed has
`pcm_addr[22:20] == 0`**, which is exactly the condition, and the gate
asserts it rather than trusting the arithmetic.

**THE RIG WAS CONFIRMED ON MAME FIRST**, because `36_pick_tenant_cell`
presses nothing after the match starts and a tenant that never attacks would
have produced a meaningless zero — the same ambiguity that cost 14z-107 (12)
its obj-bank-4 measurement. On MAME the new replay drives P2's HP from
`0x120` to `0x00EC`. **Two instrument notes recorded in the replay header:
`p1_attack_id` at `+0x0A` reads 0 for the whole window even at PER-FRAME
sampling, so it is not the indicator to use — `anim_ptr` and the opponent's
HP are; and a 20-frame stride aliases the attacks away entirely and makes a
working rig look dead.** My first pass printed "WEAK RIG" from exactly that
aliased read while its own HP figures said otherwise.

**CAPTURED AS A GATE**: `tests/test_mister_qsound_ext.sh` (emulator tier, two
~75 min legs). It derives the window from the RTL (`PCMH_OFFSET`, `SLOT5_AW`,
and which `u_bankN` carries `pcmh_cs`) rather than hard-coding it, and
**PROVEN ABLE TO FAIL on four fabricated defects**: a control leg that leaks,
a positive leg reading zero, an address outside `0x80-0x8E`, and a dead
liveness probe.

### THE CORE SYNTHESISES AND FITS — BUT TIMING IS SEED-DEPENDENT AND TWO SEEDS IN FOUR MISS

> **[THE HEADLINE BELOW WAS WRITTEN FROM A SINGLE SEED AND IS SUPERSEDED.
> The seed sweep the maintainer approved the same day found that `cps2w`
> does NOT reliably close timing. The corrected verdict is the subsection
> "THE SEED SWEEP INVERTS THE TIMING HALF" further down; FIT is unaffected
> and stands. The single-seed measurement was not WRONG — it is a true
> report of that draw — but read alone it overstates the design's health,
> and the reason it could is `jtseed`, below.]**

**FIT is answered and unambiguous; TIMING is not.** Run on a Windows box by
a peer Claude session from `docs/project/quartus_brief.md`. The
original single-seed reading was taken at pin `7b9a0d2d`, Quartus Prime 20.1.1 Lite
via Jotego's `jotego/jtcore20x` image, device **Cyclone V 5CSEBA6U23I7**,
target mister. **`cps2` was built FIRST as the reference leg**, so every
figure below is an attribution and not just a number.

| resource | `cps2` (control) | `cps2w` | delta |
|---|---|---|---|
| ALMs | 18,258 / 41,910 (44%) | 18,464 / 41,910 (44%) | **+206 (+1.1%)** |
| Registers | 27,860 | 28,426 | +566 |
| Block memory bits | 1,095,825 / 5,662,720 (19%) | 1,097,873 (19%) | +2,048 |
| RAM blocks | 156 / 553 (28%) | 156 / 553 (28%) | 0 |
| DSP blocks | 38 / 112 (34%) | 38 / 112 (34%) | 0 |
| PLLs | 3 / 6 | 3 / 6 | 0 |

**The entire CPS-2 WIDE feature set costs 206 ALMs and 2,048 memory bits.**
Nothing overflowed; nothing is close to overflowing.

**TIMING, and this is the number to carry forward.** SDRAM 96 MHz domain,
setup, slow corner:

| | slack | Fmax |
|---|---|---|
| `cps2` (control) | **+0.144 ns** | 97.35 MHz |
| `cps2w` | **+0.066 ns** | 96.62 MHz |

Every other domain positive on both cores; TNS 0.000 for every domain and
every analysis type; hold/recovery/removal/min-pulse-width all positive;
**ZERO failing paths** (both `.sta.rpt` grepped for negative slack and for
"timing requirements not met"); fitter 0 errors, 0 critical warnings.

**THE HONEST FRAMING, IN THE MEASURING SESSION'S OWN WORDS: the SDRAM domain
is the critical path in BOTH cores, and WIDE eats 0.078 ns of the control's
0.144 ns — a little over half the margin. That is a PASS, NOT A WARNING. But
it is a thin pass on the domain that matters, and it is the number to
re-measure after any future slice.** `cps2` at +0.144 ns shows the margin was
already modest before WIDE touched it.

**CORNER, corrected by the measuring session rather than substituted
silently:** the brief asked for 1100 mV / 85 C. That corner does not exist for
this device — `5CSEBA6U23I7` is INDUSTRIAL grade, so Quartus's slow corner is
1100 mV / **100 C**, which is what the numbers above are. **More conservative
than what was asked for, not less.**

**WARNING (10230) at `jtcps1_sdram.v:284`, flagged by the measuring session
and ANSWERED here:** `assign pcmh_addr = pcm_addr[PCM_AW-1:0]` narrows 23
bits to a 20-bit target. **Benign and intentional.** `SLOT5_AW` is 20 because
the QSound HIGH window IS 1 MB (`PCMH_OFFSET = 23'h37_0000`), and
`mister_map.md:448` covers DSP sample banks `0x80-0x8F` of which `0x80-0x8E`
are downloaded — `0xF0000` B = 15 banks x 64 KB = 983,040 B against
1,048,576 B. **The truncation IS the mask**, the `lint_off WIDTH` pragma is
honest, and the arithmetic closes with exactly ONE spare bank. The constraint
it encodes — sample banks above `0x8F` alias silently — is the same
thin-margin story as the rest of the placement.

### THE SEED SWEEP INVERTS THE TIMING HALF — TWO SEEDS IN FOUR MISS

**Commissioned because the attribution showed a five-path cluster at the
limit on a term that is ROUTING, and routing is what seeds vary. It was the
right call: a single build would never have shown this.**

| core | seed | jtframe gate | SDRAM 96 MHz slack | TNS | ALMs |
|---|---|---|---|---|---|
| `cps2w` | 18269 (base) | **PASS** | +0.066 | 0.000 | 18,464 |
| `cps2w` | 1001 | **PASS** | +0.067 | 0.000 | 18,432 |
| `cps2w` | 2002 | **FAIL** | **-0.110** | -0.260 | 18,436 |
| `cps2w` | 3003 | **FAIL** | **-0.545** | -1.026 | 18,428 |
| `cps2` | 21287 (base) | PASS | +0.144 | 0.000 | 18,258 |
| `cps2` | 4004 | PASS | +0.431 | 0.000 | 18,226 |

**EXTENDED TO 17 BUILDS — `cps2w` n=12, `cps2` n=5 — and the failing
fraction is now PINNED DOWN rather than merely demonstrated:**

    cps2w (n=12):  -0.545 -0.313 -0.110 -0.039 | 0.008 0.009 0.066 0.067
                                                 0.147 0.167 0.202 0.396
    cps2  (n=5) :                                0.144 0.287 0.431 0.511 0.665
                                               ^ zero

    failed   cps2w 4/12          cps2 0/5
    median   cps2w +0.038        cps2 +0.431
    range    cps2w 0.941 ns      cps2 0.521 ns

**THREE COMPARISONS CARRY IT.** The BEST of twelve `cps2w` seeds (+0.396)
is worse than the MEDIAN of five `cps2` seeds (+0.431); `cps2`'s WORST
seed (+0.144) beats EIGHT of twelve `cps2w` seeds; and the medians differ
by more than an order of magnitude. **And two of the eight `cps2w` passes
are +0.008 and +0.009 — a quarter of the passing placements clear the gate
by under 10 PICOSECONDS, which is a pass in the report and not margin in
any engineering sense.**

Observed failure rate 4/12 = 33%, 95% CI roughly **14%-61%** at this n, so
the honest phrasing is "commonly, between about one seed in seven and
three in five", NOT "exactly a third". The DIRECTION is not in doubt.

**THE ATTRIBUTION HOLDS AT n=12, and this is a verified negative:** across
all twelve `cps2w` seeds **the number of failing paths OUTSIDE
`jtframe_sdram64` is ZERO** — checked by grepping every negative-slack row
of every seed's path report, not by sampling. The worst path is a
different register on nearly every seed (`post_act`, `in_busy`, `br`,
`st[0]`, `actd`, `rfsh|help`) landing on `sdram_a[7]`, `[8]` or `[11]`.

**THESE ARE REAL TIMING FAILURES, NOT CRASHES.** Quartus reported "Full
Compilation was successful, 0 errors" on both failing seeds — the fitter
placed and routed fine. **The FAIL verdict is jtframe's OWN timing gate**,
the same one that prints PASS on the passing seeds. It is jtcores'
pass/fail criterion, not an interpretation of a slack number.

**THE CLUSTER RESHUFFLES; IT DOES NOT MOVE AS A BODY.** Different source
register AND different destination pin every seed (`u_bank1|post_act` ->
`sdram_a[11]`; `u_prog|actd` -> `sdram_a[7]`; `u_bank2|post_act` ->
`sdram_a[8]`; `u_bank1|st[0]~DUPLICATE` -> `sdram_a[11]`). Every failing
path is still inside `jtframe_sdram64`, terminating at an SDRAM address
pin. **What is marginal is not one path but the SDRAM controller's
ADDRESS-GENERATION CONE AS A WHOLE.** WIDE loads that cone enough to lose
the seed lottery; the control keeps enough margin to absorb the same
variance.

**AND THE REASON A SINGLE BUILD LOOKED HEALTHY: `jtseed` RETRIES UNTIL IT
PASSES.** `xjtcore.sh` calls `jtseed 4`, which loops `jtcore --seed
$RANDOM` and **BREAKS ON FIRST SUCCESS**. The +0.066 baseline was such a
draw.

**BE PRECISE ABOUT WHAT THAT HIDES — the first statement of this, mine and
the measuring session's, was stronger than the evidence and was sharpened
at n=12.** It does NOT mean the flow ships failing bitstreams: at a 33%
per-seed failure rate the chance all four draws fail is ~1%, so **roughly
99% of invocations produce a gate-passing `.rbf`**. What it hides is
**FRAGILITY, not correctness** — the artifact is a CHERRY-PICKED
PLACEMENT, the first of up to four random draws that closed. **A green run
certifies "one placement was found that closes"; it never certifies "this
design closes with margin".** Only the second is a basis for building on.

**THE VERDICT, not forced into the brief's four boxes because it does not
fit one.** FIT is unambiguous — `cps2w` FITS at 44% ALMs, and (d) is firmly
excluded. TIMING is seed-dependent: (a) on passing seeds, (c) on failing
ones. **It is NEVER (b)** — the control closed on every seed tried, so
there is no inherited failure to attribute this to. The failure IS
attributable to the fork in the sense that the control does not exhibit it,
but it is **NOT located in WIDE's own logic**: every failing path is in
shared jtframe infrastructure the fork does not touch. With n=4 no pass
RATE is quoted; 2-of-4 is not "50%" at this sample size. **What is robust,
from two independent failures: `cps2w` does not reliably close timing at
96 MHz on this toolchain, and `cps2` does.**

**A HAZARD CAUGHT AND FIXED, and it bears on the field test.** **A FAILING
SEED STILL EMITS AN `.rbf`** — Quartus completes and writes a bitstream
even when jtframe's gate says FAIL. The sweep OVERWROTE
`release/mister/jtcps2w.rbf` with seed 3003's output, the worst-failing
seed at -0.545 ns. Anyone pulling that path for an SD card in that window
would have flashed a build that misses timing. The baselines were archived
before the sweep, restored afterwards, and re-hashed to the published
values (`46fc74af…` / `43b94cb1…`); the sweep bitstreams are preserved, not
discarded. **VERIFY THE HASH BEFORE FLASHING ANYTHING FROM THAT TREE.**

**CONSTRAINTS HELD:** only `--seed` varied, `set_global_assignment -name
seed <S>` confirmed in the `.qsf` each run, no fitter/physical-synthesis/
optimisation-effort changes, and **no failing seed was re-run hoping for a
pass**. HEAD `7b9a0d2d`, 0 tracked and 0 RTL files modified.

**WHAT IT MEANS, stated plainly.** It does NOT block shipping by itself: we
distribute a PREBUILT `.rbf`, and the baseline bitstream is a passing draw.
It DOES mean the +0.066 ns is not real headroom — **a future slice cannot
assume it**, any rebuild is a lottery, and a jtframe uprev or a Quartus
version change could move the design from mostly-passing to mostly-failing.
**Whether to spend margin back (pipelining the SDRAM address path, reducing
the load WIDE puts on that cone) is a DESIGN decision under Rule 1 v2 and
is the maintainer's**, not something to fix by seed-hunting.

**WHERE THE 0.078 ns WENT — ATTRIBUTED, AND THE ANSWER IS THE REASSURING
ONE.** Obtained by re-running `quartus_sta` with `report_timing -setup
-npaths 5 -detail full_path` against the EXISTING fitted netlist (6 s a core,
no re-synthesis, no re-fit, the same placement the numbers describe) — the
`.sta.rpt` itself carries only per-clock summaries and no path listing.

| # | `cps2` (control) | | `cps2w` | |
|---|---|---|---|---|
| 1 | **+0.144** | `all_dbusy` -> `sdram_a[11]` | **+0.066** | `u_bank1\|post_act` -> `sdram_a[11]` |
| 2 | +0.418 | `u_bank3\|in_busy~DUP` -> `sdram_a[7]` | +0.079 | `u_rfsh\|rfshing` -> `sdram_a[11]` |
| 3 | +0.427 | `all_dbusy` -> `sdram_a[11]~D1` | +0.103 | `u_bank0\|in_busy` -> `sdram_a[11]` |
| 4 | +0.436 | `all_dbusy` -> `sdram_a[11]` | +0.112 | `u_bank2\|post_act` -> `sdram_a[11]` |
| 5 | +0.449 | `u_bank1\|in_busy` -> `sdram_a[11]` | +0.131 | `u_bank3\|in_busy` -> `sdram_a[11]` |

**THE COST IS NOT IN ANY SLICE.** All ten paths live in `jtframe_sdram64` —
jtframe's own SDRAM controller, SHARED with the control and UNTOUCHED by the
fork. Grepping the table for `jtcps2w_obj_bank`, `jtcps2_main`,
`jtcps2_decrypt`, `jtcps2w_profile` or `jtcps2w_qsnd_bank` returns **zero
matches**, and path #1's full node chain traverses only `jtframe_mister` ->
`jtframe_board` -> `jtframe_sdram64` -> `jtframe_sdram64_bank`. **D2's
seven-slot arbiter, D3's third bank bit and D5's decrypt stage are NOT on the
critical path.**

Worst-path structure, control -> `cps2w`: **same destination pin, same
DDIOOUTCELL, same site** (`sdram_a[11]` via `DDIOOUTCELL_X62_Y0_N10`); data
delay 10.658 -> 10.758 ns (+0.100); combinational levels 6 -> 7 (**+1**); and
the **dominant term is UNCHANGED at ~4.22 ns** — a single interconnect hop
from the fabric (X46,Y26) to the I/O column (X62,Y0), **39% of the whole data
path, and it is routing distance to a pin rather than logic.** WIDE added one
level to the bank-arbitration cloud and did not touch what actually dominates.

**AND THE DISTRIBUTION MATTERS MORE THAN THE SCALAR, which is the finding:**

    cps2 :  0.144 | 0.418  0.427  0.436  0.449   one outlier, then a 0.27 ns gap
    cps2w:  0.066   0.079  0.103  0.112  0.131   FIVE paths inside 0.065 ns

In the control the margin is held by ONE path with room behind it. In `cps2w`
five bank-arbitration paths sit in a tight cluster at the limit. **WIDE did
not shift one path; it pulled a whole front down together.** The verdict is
unchanged — all positive, TNS 0.000 — but the RISK PROFILE is not: the
dominant delay term is routing to a pin, routing is exactly what varies
between fitter seeds, and a five-path cluster has five chances to go negative
where a lone outlier has one. **A single-seed +0.066 is least informative
precisely in this configuration.** A FITTER SEED SWEEP is therefore the
natural follow-up; it costs real build hours and is the maintainer's call.

**THE ARTIFACTS, AND THE SEED BEHIND THEM.** `release/mister/jtcps2w.rbf`, **3,111,944 B**, sha256
`46fc74afb6a6c5c6143db64d9c9f5d2e298cdd5c79449bb0370fbe9c2b3df66f`, built from **SEED 18269**, slack +0.066 ns,
gate PASS — jtseed's own RANDOM draw during the original run, not a chosen
seed, and **it IS the +0.066 row of the n=12 table**. So the artifact a field
test would use is a PASSING DRAW FROM THE DISTRIBUTION IN WHICH A THIRD
FAIL — not a separate or privileged build. Rebuild:
`jtcore cps2w -mister --nodbg --seed 18269`.
**BUT THE HASH WILL NOT REPRODUCE UNLESS IT IS THE SAME CALENDAR DAY.**
`modules/jtframe/target/mister/sys/build_id.tcl` compiles a `%y%m%d`
datestamp into the design (this bitstream carries `260825`; verified in our
own checkout, day granularity, rewritten only when the value changes). Same
seed reproduces the PLACEMENT and the TIMING exactly and a DIFFERENT hash.
**THE HASH IDENTIFIES THE ARTIFACT; THE SEED IDENTIFIES THE RESULT.** Never
read a hash mismatch as a failed reproduction — check the seed and the
reported slack. Control: control
`release/mister/jtcps2.rbf`, 3,162,828 B, sha256
`43b94cb1e4ca59606912ad638a7b1f45370c897f08f2d1100f10efcf0df0f15f`. Each
`release/` copy hashes identically to the fitter output under
`cores/<core>/mister/output_files/`, so `release/` is a true copy and not a
re-emit. **NOT transferred anywhere**; they live on the build machine. An
`.rbf` carries no ROM content — it is our own GPL-3.0 core — so unlike
everything else in this project it is an artifact that CAN be moved, and it
is what a field test needs on the SD card.

**PROVENANCE AND DISCLOSURE, recorded because it belongs in the record even
though it does not affect the answer.** The measuring session verified the
D0-D5 evidence independently rather than taking it on trust (all nine `cps2w`
commits, 13 `.v` files, all four characteristic expressions at the cited
lines, `README:35` stale as described). It also disclosed unprompted that it
touched the tree mid-run: an over-broad `rm -rf` while clearing master-only
submodule artifacts deleted the tracked `modules/jt680x` (restored with
`git checkout --`), and `modules/jttms` had staged deletions after a killed
clone (reset to `fabcbc36`). Both repaired and verified before the builds
ran; final state HEAD `7b9a0d2d`, 0 tracked files modified, 0 RTL files
modified, nothing pushed. **BETAKEY is NOT needed** (the flow warns and
assigns a random one). Full report on that machine at
`C:\Claude\VampireSaved\quartus_report.md`.

**WHAT THIS DOES AND DOES NOT SETTLE.** It settles BUILDABILITY: the design
fits a Cyclone V with room and meets its clock. It does NOT settle hardware —
nothing has been loaded onto a DE10-Nano, no MRA has been run on real
silicon, and no analog output has been seen. An `.rbf` existing is not a
field test.

### A STALE README IN THE PUBLIC FORK, FOUND BY THE QUARTUS SESSION

`emu/jtcores` `cores/cps2w/README.md` at pin `7b9a0d2d` still says
**"Status: slice D1 — the QSound sample-bank width"** and lists the
placement, the object promote and the 68k PRG window as "slices D2-D4 and
not here yet". Its file table lists FIVE `hdl/` files; the tree holds
THIRTEEN. It was written at `4840df8a` (D1) and never updated after
`0df6f000` (D2).

**Found by the Windows Quartus session, which stopped and asked before
building rather than trusting either document.** That is the right
instinct and the reason it matters: a synthesis report reading "slice D1"
would have been filed as a green light for a design four slices larger
than the one measured.

Verified against the tree, not from memory: five slice commits sit above D1
on `cores/cps2w`, and each slice's characteristic expression is present
(`jtcps1_sdram.v:221-222` the group-C offsets; `jtcps2w_obj_bank.v:64` the
promote; `jtcps2_main.v:240/219/116` the decode, the `one_wait` boundary and
the widened `rom_addr`; `jtcps2_decrypt.v:75` `rng_eff`). Stronger still,
this same pin demonstrably RAN the full design in the tenant-match
measurement above, which requires D2, D3, D4 and D5 jointly.

**NOT FIXED IN THIS SESSION, deliberately: a README commit moves the fork
pin out from under a build in flight.** It is queued for after the Quartus
numbers land. **This is the retraction rule pointing at our own public
artifact** — the fork's README is a header a stranger reads first, and it
is confidently wrong.

### RITUAL

- **SCRATCH HYGIENE: the 14z-107 direction evidence is SWEPT, 503 MB.**
  `docs/NEXT_SESSION.md` at the 14z-107 close said to keep
  `/tmp/vs14z107_*` — leg E's 811 work-RAM dumps, the MAME comparison legs
  and the two rendered frames — **until the direction fix was verified**.
  It is verified (all four directions match MAME post-fix), and the finding
  those dumps supported has been SUPERSEDED by the four-direction
  measurement, which has its own evidence. Swept after confirming the two
  rendered frames are committed under `docs/project/images/` (they are, and
  `git ls-files` says so — the durable copies, per rule 7 the dumps
  themselves could never be). `/tmp/vampire-saved-jtsim-14z108` was left
  alone: it is the live simulation clone.
- **THE ROLLOVER EXECUTED, exactly as the 14z-107 CLOSE (final) specified
  it**: the 14z-107 sub-entries **(1)-(9)**, nine sections and 1,582 lines,
  moved BYTE-VERBATIM to the top of `STATE_HISTORY.md`'s body. Verified
  lossless (identical sha256 in the archive; no rolled header remains here).
  **STATE.md 261,112 -> 160,634 B** — the first time since the split that it
  is near the ~150 KB the rule names. **First time a group's SUB-ENTRIES have
  rolled while the group stays live**, which the rule does not contemplate:
  it speaks of whole groups and THE LEDGER carries one line per group, so
  nothing was added to the ledger and a pointer paragraph names all nine.

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

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

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
## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

"vsav vanilla is always better when we can." **When a console port and
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

## Decisions pending (human)

*(Cleaned 14z-109, maintainer-directed: resolved and no-longer-shaping
entries moved VERBATIM to `DECISIONS_HISTORY.md` — grep there by topic.
Lifecycle: rulings are still marked DECIDED in place here first; they move to
the archive once they stop shaping active work.)*

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
  **Option B stays the target shape "in time"**: move those four members
  INTO `vsavjw.zip` so `vsav.zip` can stay pristine and a user's existing
  romset folder works untouched. Not done now because it is a build-pipeline
  change touching the hash-shadowing class that cost two sessions in
  14z-60z/61, and it must not sit between the maintainer and a field test.

- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** Recorded as FUTURE, UNPLANNED work — nothing scheduled.
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

- **THE LIVING-DOCUMENTATION EFFORT, and the option it creates (maintainer
  direction, 2026-08-24).** Recorded as DIRECTION, not as a task — nothing is
  scheduled and MiSTer stays the current arc. In their words: an important
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

Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
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
- **OPEN (cosmetic):** Huitzil's win QUOTE text — root-caused, not built.
  The consumer's `lea -4(a0,d0.w)` bias means it reads index 0x60+id-1.
- **OPEN:** FG pacing — untouched.

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
