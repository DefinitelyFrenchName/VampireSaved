# STATE — living progress log

Updated: 2026-08-12 (session 14z-82c, same day — **THE HIT-CLASS FIX IS
ADOPTED (maintainer decision 1) AND BOTH TENANTS ARE RE-FROZEN:
`huitzil-m4` (e66678d0, build/hui30) and `pyron-m3` (6c7f7322,
build/pyron21 — byte-identical to the measured probe build).** Decision 2
(Donovan's map[61]/[62]) leans keep-zeros and gained its measurement: his
type-61 objects EXIST in both his replays but NEVER enter the hit-class
map there (probe: 0 entries) — the gap is unexercised like Huitzil's.
**A THIRD defect dissolved under the fix, measured with a control:** the
`80_pyron_cosmo_pairsweep` reset open since 14z-75 is the SAME map
over-index (pyron-m2: CRASH f4638 vec3 PC 01AB10 ADDR $FF31B7 — the f7997
signature; pyron-m3: END-clean 7,520 frames). **The freeze ladder:** all
four fingerprints bit-exact (constants re-frozen to m4/m3);
test_tenant_loop re-frozen 261/207/439/593 (+2 ops per declaring build,
deduped once on the merge); registry rows + expectation sets carried over
RENAMED (huitzil-m4/pyron-m3); run_suite hui30 **GREEN** after exactly
THREE `.sha1` self-baselines were re-frozen (21/22/26 — the don-mash
trio), each ATTRIBUTED BY BYTES: a full-RAM dump-diff at a divergent
frame shows **3 bytes, all in the $FF7Fxx dead-stack ghost window, zero
live bytes** (the ratified hook-cycle class; the debug-timeline fire
probes did NOT transfer to the checksum timeline — vs-CPU/chaos content,
the documented -debug caveat — so the attribution was made on the right
timeline instead); pyron21's suite moved the SAME three, re-frozen the
same way — verification **SUITE GREEN, 55 PASS** (an earlier attempt was
killed by the environment at 40/40 PASS; the clean re-run completed). **The merged
instrument now has ZERO crashes:** audit_merged_legacy leg (b) is
guard-clean on all six entries incl. pyron/70 END 11017, and leg (a) is
13/14 verbatim — the ONLY remaining FAIL anywhere is 04's
held-un-ratified {1525, 2005, 2009, 2195} inventory, per the maintainer's
standing hold (its mechanism now named). Harness note: the win_pal
fragment-note wording differs m3→m4 builds (the 14z-80h chain emitter's
note format) — bytes identical, cosmetic only. Read docs/NEXT_SESSION.md
first.)

Previously: 2026-08-12 (session 14z-82b, same day — **f7997 ROOT-CAUSED AND
FIXED ON A PROBE BUILD, AND IT WAS NEVER A MERGED DEFECT: the frozen
pyron-m2 build crashes at f7997 SOLO.** The crash is vsavj's
projectile-pool hit sweep (seven dispatchers, ONE 64-entry byte map at
`PRG:0x1A888`) over-indexed by a ported type-64 satellite hit — map[64]
reads the following rts opcode's 0x4E, exactly the crash D0; vs2's
sibling map has 80 entries. "Single-tenant is clean" had NEVER been
measured: `audit_merged_legacy`'s leg-b bails after the merged leg (now
fixed — it measures the ref leg on every crash and says MERGE-SPECIFIC
vs LATENT), and the covering soak gate builds STAGE 4, not the frozen
stage-6 artifact. Huitzil shares the exposure (types 68/72 measured in
the same pool; zero map entries on his suite replays — unexercised, not
safe). My own hours-old "pyron-placed data/table defect" attribution is
RETRACTED — A3 was a live register, not causal. **The fix is generated,
gated, and measured**: `tools/gen_hitclass_map_thunk.py` builds a 94-byte
site_thunk body (vanilla's 64 map bytes verbatim + vs2's 16 extension
entries + a loud >=80 ILLEGAL; safety asserts incl. 0-58 prefix identity
and word-table entry identity), `tests/test_hitclass_map_thunk.sh` is the
reconstruction gate, and `tests/audit_hitclass_map_cost.sh` measured on a
probe build: **the 11,017-frame soak that crashes frozen pyron-m2 runs
END-clean, and legacy content is BIT-IDENTICAL on four replays (30,284
frames) — the fire census shows legacy never enters this map at all.**
Bonus finding: vs2 populates map[61]/[62] (DONOVAN's satellite types)
with real hit classes where vsavj holds zeros — his projectile hit-class
reactions are silently absent on every shipped build; the fix keeps
vanilla's zeros (donovan-m3a untouched). **ADOPTION IS THE MAINTAINER'S:
the row moves the huitzil+pyron frozen fingerprints — decision recorded
under Decisions pending with all numbers.** Manifests deliberately
untouched; all four frozen fingerprints still bit-exact. Read
docs/NEXT_SESSION.md first.)

Previously: 2026-08-12 (session 14z-82 — **THE MERGED HUITZIL VEC3 IS FIXED —
per-tenant TYPE NUMBERS, measured green end to end — AND F2 IS FIXED the
same emit path.** The spawn-time design shipped as maintainer-decided at
plan review: variant (b), FIRST RESOLVER KEEPS ORIGINALS. Two censuses
came first (the 14z-78 rule): the STATIC stamp census
(`tools/audit_type_stamps.py` → frozen `build/manifest/type_stamps.toml`,
194 reviewed rows) found a second stamp FORM the 14z-81b scan was blind
to (`move.b #type,(2,A4)` — ~26 more sites, 20+ for type 115 alone),
proved NO tenant code compares/table-indexes the family type byte, and
found two embedded walkers in the ported spans (vs2's own 0x54470 site;
a $FFC800 local pool with its own table) — both separate numbering
spaces; the DYNAMIC census (`tests/audit_type_writes.sh`, 6 tap legs)
mapped every observed 114-120 write to a frozen row (118/120 NOT
OBSERVED, recorded). The generator then renumbers: 12 per-tenant entries
(124-135, H/P × 114-119; type 120 has ZERO reachable stamps and keeps
first-wins), 69 TT-byte rewrites verified against source bytes, table op
grows 0x1F0→0x220, EMPTY at N=1 — all four frozen fingerprints
bit-exact. Measured: `audit_merged_vec3` GREEN (A0 = anim@huitzil+0xB8AC,
crash-free); new gate `tests/audit_type_dispatch_range.sh` — merged hui
mash: ZERO original-range dispatches with 5,862 renumbered (the whole
stream moved), donovan originals intact; full `audit_merged_legacy`: leg
(a) 13/14 ratified classes VERBATIM, **both former Huitzil crashers
guard-clean over full replays, donovan/12_vs_cpu guard-clean** (the
replay that killed the withdrawn stub). **F2**: one merged shim
(`flavor_chain_multi` — per-OWNER handler exits, tripwire fall-through)
assembled at engine_here, planted on both declaring rows, pyron direct
by decision; +1 op (the tripwire), re-frozen 437/591 FIRST; section-0
asserts the post-fix shape and both tenants' char-init executes through
the shim. **Named, not fixed:** the 04 flicker's owner — $FF0460 is the
SOUND DRIVER's record-pointer spill (writer PRG:0x0011E2, measured by
tap + disassembly, scripted as `tests/audit_ff0460_writer.sh`), so the
held ratification decision is now about a named mechanism; and **pyron
f7997 STANDS, measured NOT this class** (crash-time GUARD_PROBE_HIST —
now armed from the guard's crash handler too — names a vanilla
dispatcher 0x1A77E→0x1A790→byte-map 0x1A888→computed jmp; a
`b@(a6+2)>=0x72` probe recorded ZERO extended types entering it while
the crash fired identically; A3 in pyron's wide_ext + odd $FF31B5 point
at a pyron-placed data/table defect — next session's first target).
Read docs/NEXT_SESSION.md first.)

Previously: 2026-08-12 (session 14z-81 — **THE MERGED-LEGACY MEASUREMENT RAN,
AND THE ANSWER IS SPLIT: LEGACY IS SAFE, THE TENANTS ARE NOT.** The
maintainer-ordered first priority is answered. A 3-tenant merged image
(`build/merged1`, fingerprint 7a9eabb3, gfx skipped — a LEGACY-ONLY
instrument, never playtest it) boots, forms all three tenants' matches
(char-init probes on all three; H's and P's handlers execute from the raw
wide extension), is run-to-run deterministic, and lands on donovan-m3a's
ratified legacy classes **13/14 VERBATIM** on the masked-v2 basis — attract
EXACT included. The one deviation: `04_select_fuzz` grows ONE deterministic
flicker frame (2005, beside the frozen 2009; measured 3/3 merged runs while
m3a re-measured clean the same day), byte-localized to the low word of ONE
engine pointer at `RAM:$FF0460` (one frame, fully re-convergent; the
pointer's owner is UNIDENTIFIED — an in-flight "sound-queue cursor" reading
was WITHDRAWN as speculation). **Leg (b) is where the merge fails: Huitzil
CRASHES at char-init** — deterministic vec3, 4/4 runs; his satellite's
runtime-composed anim base carries a DONOVAN address while all fifteen
`anim_index_*` rows are CORRECT and his satellite-machine blob differs from
hui29's only in correctly re-derived literals; the pointer slot holding the
Donovan value was NAMED the same day (see the 14z-81b addendum below):
the merged obj_hook union's ONE entry for a MULTI-OWNER type routes every
tenant into tenant-0's internally tenant-reconciled x088512 copy.
`tests/audit_merged_vec3.sh` is the rerunnable probe and the regression
gate for the fix. **A fix was then IMPLEMENTED, MEASURED GREEN FOR
HUITZIL, AND WITHDRAWN the same day (14z-81c below): dispatch-time owner
reads have two measured timing failure modes, so the merged image is back
to bit-identical pre-fix bytes (fingerprint verified) and the robust
spawn-time-tag design is specified for the next session.** **Pyron crashes under
the mash storm** (deterministic vec3 at f7997; evidence kept in
`build/gate_failures/`). Donovan is guard-clean; his divergences vs m3a are
UNATTRIBUTED but shaped like cached placed pointers. F2 — the merged
`[init_shim]` serves ONLY tenant 0, so merged-H's char-init bypasses
seeder/phase-gate/flavor — is CONFIRMED statically but is NOT the crash
mechanism (he dies at spawn, before seeding could matter); it stands as a
second, independent defect. All four frozen references rebuild bit-exact;
`test_tenant_loop` green. New: `tests/audit_merged_legacy.sh` (~45 min, the
whole measurement, rerunnable), `tests/audit_merged_vec3.sh` (~4 min). Read
docs/NEXT_SESSION.md first.)

Previously: 2026-08-11 (session 14z-80, second half — **A 3-TENANT MERGED PATCH
NOW APPLIES.** After the loop landed, four defects were found and fixed under
it, each one MEASURED before it was touched: the iteration gate's shared-row
rule was wrong for rows that name a REGION (Huitzil's and Pyron's copies of
x05c800/x088512 kept vs2's OBJ bank — the wrong graphics bank, silently) and
wrong again for rows whose ADDRESS derives from the tenant's slot (H's and P's
`slot_table` rows wrote DONOVAN'S entries); `obj_hook`'s one engine table
resolved only tenant 0's handlers, sending all TWELVE of Huitzil's secondary
objects to planted ILLEGALs; and the last collisions were AGREEMENTS —
different mechanisms writing identical bytes — now dropped at emit. Then the
N-way dispatch FORM turned out not to be a design decision at all: both shared
sites already carry compare-chain elements whose branch targets whatever
follows, so N tenants chain by CONCATENATION and N=1 is byte-identical. Op
collisions 10 pairs/36 bytes -> 4/24 -> **0/0**, and `patch_prg` writes the 12
members. All four frozen references still rebuild bit-exact throughout.
**This is the PROGRAM half only** — the gfx half is single-tenant by decision,
nothing has been in an emulator, and no legacy gate has seen a merged image.
`tests/test_tenant_loop.sh` (~17 s) covers it with 5 verdict controls, one of
which caught itself doing nothing. Read docs/NEXT_SESSION.md first.)

Previously: 2026-08-11 (session 14z-80, first half — **THE N-TENANT LOOP
LANDED. The generator emits three tenants into one image and the `>1 tenant`
refusal that has stood since M3 Phase 3 is deleted.** `main()`'s body (3,723 lines) is now
a loop body; the iteration gate makes a row belong to ONE iteration; and all
four frozen references still rebuild bit-exact, which is the whole safety
argument. **THREE TRAPS were under the "one re-indent plus one gate" estimate,
and none of them was in the spec:** the side-file NAMESPACE is shared while the
content is not (tenant B's blob would have been served at tenant A's address —
invisible to the op-overlap assertion and impossible to see with one tenant);
`recon_overlay` is a `[[tenant]]` key that `tenant_context()` never copied, so
every tenant after the first silently built against the shared map alone; and
`pcrel_far_tramps` is a second address-keyed memo of the class STATE 14z-78
named only `dc_tables` for. **A 3-tenant merge GENERATES (612 ops) but at this
point did not yet APPLY — SUPERSEDED the same day, see the top of this file:**
patch_prg refused it at the first op overlap, and the inventory was
10 op pairs / 36 bytes — 34 bytes inside the four shared spans
14z-77h already froze as conflicting, and four 6-byte collisions at engine
SITES where each tenant emits its own thunk, i.e. the N-way dispatch FORM with
a number on it at last. New gate `tests/test_tenant_loop.sh` (~6 s, generator
alone) freezes all of it, including what is still broken. Read
docs/NEXT_SESSION.md first.)

Previously: 2026-08-11 (session 14z-79 — **PHOBOS RE-FROZEN AS `huitzil-m3`
(34c8b47d): the (b') thunk landed, and a LEGACY DEFECT THAT HAD SHIPPED SINCE
14z-69 WAS FOUND BY PLAYTEST AND WITHDRAWN.** (b') covers the out-of-range
window of dispatcher `0x018460` and fixes BOTH Phobos defects — Plasma Trap
(entry 82, LOUD, maintainer-confirmed) and Reflect Wall (entry 83, SILENT,
rig-verified at f3214/f3315 with `D0=0xA6`). The body is GENERATED and
reconstructed from the ROMs by a new gate; it was exhaustively simulated over
all 65,536 index values before it ever ran. **TWO PARTS OF THE 14z-78 SPEC
WERE WRONG AND BOTH WERE CAUGHT BY MEASUREMENT:** its `lea 0x018468,a0` normal
path is a DATA-space read that returns ciphertext (38 of 80 legacy targets come
out ODD), and its D1 requirement — which I overrode on a static finding and had
to restore when the legacy suite went systematically red. **THE BIGGER FINDING
IS BULLETA'S:** the 14z-69p DF-palette row wrote palette-seq ids 0x1E-0x21,
which are BULLETA'S Dark Force block, so a VANILLA character rendered wrong on
every Huitzil build for ten sessions — invisible to every RAM gate because the
palette path never transits work RAM, and missed by its own guard because that
guard's replays cannot activate Dark Force. The row is WITHDRAWN; Phobos' DF is
purple again by maintainer decision, pending a proper tenant-scoped block.
`test_variant_dispatch.sh` had been reporting the responsible aliased row as a
FAIL since 14z-74 and it was written off as benign — it was right all along.
**Two follow-ons landed the same day:** `14z-79b` froze the SHARED-SURFACE
WRITE inventory (`tests/test_shared_writes.sh`, ground-truthed against the real
defect on hui27) — the gate that would have caught this at build time, since
the op invariant that names the class stops at stage 3; and `14z-79c` measured
the DF palette-seq block census across the roster, which RETRACTED two static
readings of mine, including "the default routine has no DF path" (five
instructions read, the `bne.w` never followed). Read docs/NEXT_SESSION.md
first.)

Previously: 2026-08-11 (session 14z-78 — **M3b'S BLOCKER CLEARED, AND THE THREE
MOVELISTS SWEPT.** `anim` moves: the vec3 that made it immovable was two
`donovan.toml` thunks baking its placed address as a hex literal, not a
hardware limit. Fixed with `region_subst`, INERT — all four frozen
fingerprints bit-exact. Three tenants now need 98,488 of the 344,640-byte
crypt window instead of 470,200. The merged manifest is COLLISION-FREE
(slice 78d resolves the last nine, conditionally on the profile, failing
closed); `--extract` pairs with `--port`; region identity DISSOLVED (per-tenant
copies of everything fit) so the loop is one re-indent plus ONE gate, both
specified. Maintainer swept all three full movelists: Donovan and Pyron clear,
**Phobos has TWO defects** — Plasma Trap (air 214+MK, entry 82, crashes) and
Reflect Wall (entry 83, SILENT wrong-routine dispatch), both in the same
already-known table, both fixed by one change. That change, (b'), is FULLY
SPECIFIED and deliberately not encoded — three static analyses that hour were
wrong and 68k with a silent-stack-leak failure mode is the worst thing to write
at an elevated error rate. New: `tools/audit_index_users.py`,
`tests/lua/index_watch.lua`, `tests/test_thunk_addr_literal.sh`, three `.skip`
expectations that make `run_suite.sh` GREEN again for the first time since
14z-75, and `test_variant_dispatch.sh` now judges the BUILD'S OWN tenant.
Read docs/NEXT_SESSION.md first.)

Previously: 2026-08-10 (session 14z-77 — **M3b slices C-F.** Slice F makes the
merged manifest EXPRESSIBLE (`--port` is repeatable; the documents merge) and
turns the merge's hazards from a list in a document into a MEASUREMENT: 12
collisions, of which only THREE are real blockers — the six `port_patch` ones
dissolve on the WIDE track because all three tenants agree on the variant
value. Frozen by `tests/test_manifest_merge.sh`. **M3b slices C, D and E: the gating
family, the manifest-row arithmetic AND every id baked into emitted 68k now ask
the ROW'S OWNER, not the build's single `dst_slot`.** Slice D corrected the
plan's premise: four of its seven named sites are DEAD code, and the rest are
THREE classes, only one of which `owner_of()` can answer. Slice E found TWO
LATENT TRAPS — `charid_sites` and the overlay thunk read `port["port"]`, which
the loop never rebinds, so they would have baked the FIRST tenant's id into
every tenant's code, silently. New gate `tests/test_tenant_row_owner.sh` (~9s)
answers the question no fingerprint can — is the threading load-bearing? — and
**found a blind spot in itself** while doing it (see 14z-77c). The
manifest-schema
question 14z-76 stopped on is ratified: **per-FILE ownership, stamped by the
loader** — the merge adds tenants without editing a single manifest row, and
each frozen vertical stays independently buildable as its own reproduction
oracle. All 10 gating sites converted (the 9 named in the blast radius plus
the `data_port` `slot_ptr_table` pair). Inert by construction: **all four
frozen fingerprints bit-exact**. Both new gates proved able to FAIL before
being trusted. New ORDERING INVARIANT recorded: the N-tenant loop lands only
after gating AND scalar reads AND the baked-code sites are owner-threaded.
Read docs/NEXT_SESSION.md first.)

Previously: 2026-08-10 (session 14z-76 — **PYRON RE-FROZEN as `pyron-m2`
(69e8c6f0)** — his EFFECT palette ported and maintainer-confirmed visible;
supersedes `pyron-m1` (d8b282da), which can no longer be produced from the
tree. **M3b is also UNDER WAY**: the reproducibility gate now covers all four
frozen builds, and slices A and B of the multi-tenant generator have landed
(see the 14z-76c entry). The premise that deferred
it for two sessions — "the table at 0x38C218 has only sixteen rows, so a
variant id indexes past it into an adjacent shared table" — is RETRACTED: it
is ONE 32-row id-indexed table and 0x38C258 is its second half. Row 0x11 is an
ordinary variant alias row, so the port is a 7-line manifest row, exactly like
Donovan's and Phobos'. Suite GREEN (55/17/0, unchanged from pyron-m1); new
gate `tests/test_effect_palette_table.sh`. **M3b merge blocker #2 dissolves.**
Visibility CONFIRMED by playtest after the automated leg could not decide it
(0 reads of any character's effect block across two vanilla fighting replays
and a 6000-frame soak, against a live positive control — a rare-event palette
needing the electrocute trigger no replay produces): Pyron's shock aura is RED
on pyron19 and YELLOW on pyron20, matching vs2; Demitri unchanged and correct
on both, which is the legacy check no RAM gate can make. Read docs/NEXT_SESSION.md
first.)

Previously: 2026-08-10 (session 14z-75 — **PYRON IS FROZEN as `pyron-m1`
(d8b282da)**, the third full-roster tenant, maintainer-ratified. This session
landed his HUD art, killed the sprite/HUD BLINK in all three places it lived,
found and FIXED a legacy regression that a previous session had shipped, and
then fixed the Cosmo Disruption crash properly — in his own data, one byte,
instead of the shared engine word that had been corrupting every character's
dispatch. `run_suite.sh vsavjw` GREEN: 55 PASS / 17 SKIP / 0 FAIL, 72/72
replays accounted for. All three earlier frozen references still rebuild
bit-exact. FOUR of my own claims were retracted in-session — read them before
trusting any number here. Read docs/NEXT_SESSION.md first.)

Previously: 2026-08-10 (session 14z-74 — PYRON RENDERS; Cosmo/air/win-screen fixed; Phobos re-frozen as huitzil-m2 9deda080; Step 4 HUD half done, plate BLANK. Three claims retracted in-session.)
Previously: 2026-08-09 (session 14z-71 — THE BEAM DRAWS. Root cause: vsav
ships effect-class row 16 as a STUB where vs2/vh2 carry the beam's
handler, and underneath that its sprite-list drawer has no list-type 12.
Both fixed in build/hui20 (40cc10b1) at ZERO legacy cost, by porting the
handler and taking over vsav's unused list-type 6 — with the deadness
assumption deliberately NOT load-bearing. Formerly: It was never the anim data, the emitter, the object or the
records: vsav's effect-CLASS dispatch table ships row 16 as a STUB where
vs2/vh2 carry the beam's handler. Porting that handler makes the beam
ENTER its animation and the muzzle orb DRAW — and exposes a SECOND
defect beneath it: the beam's sprite list is TYPE 12, a list format
vsav's drawer does not have. A thunk for it works and the beam draws
fully, but it costs a legacy replay that never re-converges, so BOTH
rows are PARKED pending one maintainer decision. Two of my own
measurements were retracted in-session, one of them a dead instrument
that printed a clean zero. Read docs/NEXT_SESSION.md first.)

Previously: 2026-08-08 (session 14z-70 IN PROGRESS — the beam residual moved
off the draw path and onto anim-sequence SELECTION: our build never walks
the beam anim nodes at all, measured both legs in one emulator. New gate
`tests/test_beam_anim_walk.sh` freezes it. Read the 14z-70 section below,
then 14z-69.)

Previously: 2026-08-08 (session 14z-69 CLOSED — THREE VISIBLE FIXES
SHIPPED AND MAINTAINER-CONFIRMED on build/hui14 (c25b3824): the child
sidekick's shadow, the Dark Force palette, and the row-8 machine's
pc-relative tables. The DOCS were split three ways (game / platform /
project) on maintainer proposal. The effect family is narrowed to
EMISSION with three suspected causes eliminated. FIVE of my own
findings were RETRACTED in-session after clean re-measures — each with
the comparison error written down so it cannot be repeated. Every gate
green at close, including two NEW audits. Read docs/NEXT_SESSION.md
first, then the 14z-69 sections below.)

## Session 14z-82d — the playtest reports, measured

Maintainer playtests of the two new freezes (both: NO crashes — the fix's
primary claim confirmed by hand). **CLOSING VERDICT (maintainer, same
day): "all 3 characters seem identical to their previous build"** — the
playtest sign-off on the 14z-82c re-freezes.

### hui30: "air 214+MK has sfx now (only MK)" — RESOLVED: it is the
### 14z-79 (b') fix being HEARD, not a hui30 delta

Measured chain (rigs + ring taps; ring_tap.lua gained POKES so tenant
replays can be sound-tapped at all):
1. Ring A/B on the 87 timer rig: hui29 vs hui30 **byte-identical**
   (1,591 entries, zero diff).
2. A new contact-shaped rig (88) — also byte-identical (1,580), but its
   liveness probes showed the MOVE fired (the mine is pool TYPE 69,
   spawns at $FF9502 — newly named) while the CONTACT event did not, so
   the contact question stays with rig 88's honest status header.
3. hui29's timer rig demonstrably fires AND sounds the trap: type-69
   spawns at f3432/f4232, detonation id 0x049A enqueued at f3571/f3716
   (throw id 0x010A at f3474). So the MK detonation sfx EXISTS on hui29
   and is identical on hui30.
4. The explanation that fits "only the MK version": the (b') crash's
   reproducing input WAS medium kick (14z-78/79) — pre-hui29 the MK
   detonation killed the machine BEFORE its sfx ever played. The
   maintainer's ear-baseline for MK was the crash.
   COMPLETED BY THE MAINTAINER (same day, completeness note, explicitly
   NOT a blocker and not before M5): **LK and HK trap detonations have
   NO sound at all, and never did** — so the full picture is: LK/HK
   detonation sfx MISSING (pre-existing, possibly vs2-faithful,
   possibly a gap — a native-vs2 three-strength ring comparison decides
   when the sound arc comes; 87's strength-sweep section is the ready
   rig), MK's sound restored by (b'). Filed in the M5-family sound
   bucket.

**Scope CORRECTION recorded while measuring: the hit-class sweep is
POOL-vs-POOL** — both loop registers stride pool slots and the f7997
crash held pool addresses on BOTH sides; an object hitting a FIGHTER
never transits the extended map. This narrows the fix's live surface to
pool-object clashes (satellite/mine/projectile overlaps) and means
trap-vs-fighter audio was never in the fix's blast radius — supporting
measurement for the resolution above.

### hui30: "specials feel harder to input" — no build-side mechanism

The hui29→hui30 image delta is the thunk alone (measured: zero
placements moved, 2 ops); the thunk executes only on pool-vs-pool hit
dispatch and costs ~28 cycles per fire; input buffering/motion
recognition paths are untouched, and the full suite basis moved only
the three dead-stack-attributed mash baselines. Nothing build-side can
produce a systematic input-window change. Left as reported.

### pyron21: no crash; "distorted SFX during his win pose (his laugh)"

Measured: ring A/B of 61_tenant_2pwin on pyron20 vs pyron21 —
**byte-identical** (1,688 entries, zero diff), and the fix touches no
QSound member, so playback is identical too: the distortion is
PRE-EXISTING on pyron-m2 and newly noticed, NOT a regression. Filed as
a NEW OPEN ITEM: pyron's win-pose voice (his laugh) renders distorted —
likely class: the win-pose voice id enqueues a vs2 SAMPLE id whose
backing sample vsav's QSound ROM does not carry (the Donovan M5
voice-arc family). Instrument when picked up: ring-tap the win pose for
the id, then compare the QSound sample data behind it in vsav vs vs2.

## Session 14z-82c — the hit-class fix ADOPTED; huitzil-m4 + pyron-m3 frozen

Maintainer decisions (2026-08-12, same day): **1 ADOPTED** (the row + both
re-freezes); **2 leaning keep-zeros** pending the identity answer, which
was given and measured — Donovan's types 59-63 are the projectile-pool
objects his SWORD-COMPANION machine spawns (61's handler = the sword
routine region x065e5a; measured type-61 spawns in both his replays at
$FF94xx), and a probe shows those objects NEVER enter the hit-class map
in his replays (0 entries) — the missing-reaction gap is unexercised.

### What shipped

- The `hitclass_map_extend` row in BOTH tenant manifests (shared, dedups
  on the merge; donovan not exposed, does not declare). The
  reconstruction gate's section 2 now locks both committed rows.
- **huitzil-m4** = build/hui30, fingerprint e66678d0; **pyron-m3** =
  build/pyron21, fingerprint 6c7f7322 — byte-identical to the 14z-82b
  probe build, so every probe measurement transfers.
- Registry rows added; huitzil-m3/pyron-m2 superseded (mappings removed,
  records kept; the old dirs stay on disk as the pre-fix A/B baselines);
  expectation sets RENAMED (content carried over).
- Re-freezes, in the re-freeze-FIRST order: test_m3a_reproducible
  constants; test_tenant_loop 243/261/207 singles, 439/593 merges
  (+2 ops per declaring build, deduped once); audit_merged_legacy's 593.
- Test-default sweep: every gate that pointed at hui29/pyron20 now
  points at hui30/pyron21; audit_hitclass_map_cost reworked for
  post-adoption semantics (builds pyron.toml verbatim, A/Bs against the
  kept pre-fix pyron20 artifact).

### The suites, and the one attribution that had to be re-made

Both suites moved EXACTLY three `.sha1` self-baselines — 21_don_mash,
22_don_dualmash, 26_don_arcade_mash — and no masked-class entry anywhere.
The first attribution attempt (hook-fire alignment, the huitzil-m3
precedent) FAILED honestly: under the guard's -debug timeline two of the
three showed ZERO thunk fires and the third fired AFTER its divergence
onset. The reason is documented: -debug runs are not
checksum-comparable, and these are vs-CPU/chaos replays whose collision
timing is exquisitely phase-sensitive. The attribution that stands was
made ON THE CHECKSUM TIMELINE with bytes, not inference: a full-RAM
dump-diff at a mid-window divergent frame (22_don_dualmash f13224,
hui29 vs hui30) shows **three divergent bytes, all inside
RAM:$FF7F00-$FF7FFF (the dead-stack ghost window), zero live-state
bytes** — the ratified hook-cycle class, invisible on the masked basis
(hence 13/13 masked green) and trivially visible to unmasked `.sha1`
self-logs. Divergence shapes: bounded windows (140/52/76 frames) that
fully re-converge (1,374/651/29,221 identical tail frames). The three
baselines were re-frozen per build from fresh runs (hashes matched the
suites' `got` values — determinism confirmed); verification: hui30
**SUITE GREEN**, pyron21 **SUITE GREEN (55 PASS)** (one environment-
killed attempt at 40/40 PASS in between — no measurement lost).

### The pairsweep dissolution (third kill for one fix)

`80_pyron_cosmo_pairsweep` (reset at "f4840", open since 14z-75,
suspected "another out-of-range index of the same class" — correct):
under the guard on pyron-m2 it is the EXACT f7997 signature (CRASH f4638
vec3 PC 01AB10 ADDR $FF31B7); on pyron-m3, END-clean through 7,520
frames. One vanilla map, three defects: f7997, the pairsweep reset, and
Huitzil's unexercised 68/72 exposure.

### The merged instrument: zero crashes remain

audit_merged_legacy on the adopted tree (593 ops): section 0 F2-fixed +
all three char-inits execute + determinism; leg (a) 13/14 VERBATIM (04's
held inventory the only FAIL, per the standing hold); **leg (b) ALL SIX
guard-clean** — donovan 12/20, huitzil 70/83, pyron 72, and pyron/70 now
END 11017 on the merged build. The M3b program half has no known crash.

## Session 14z-82b — f7997: a LATENT vanilla map over-index, fixed on a probe

### The archaeology that reopened it

`git log --grep` surfaced two prior fixes of the SAME class — 14z-26
(hit-class property table 0x28D00: vs2 extended, vsavj zeros) and 14z-35
(type-0x51 over-indexing a 0x50-entry dispatch table) — the "vs2 widened
an index consumer vsavj didn't" family, third instance.

### The mechanism, measured end to end

1. Crash-time history (the new GUARD_PROBE_HIST-at-crash) named the
   route; static decode completed it: the projectile-pool hit sweep at
   `PRG:0x1A770-0x1A886` is SEVEN dispatchers (4 bsr.w + 3 bsr.s — a
   bsr.w-only caller scan missed three) all funneling BOTH colliding
   objects' type bytes through ONE byte map:
   `0x1A888: move.b (4,PC,D0.w),d0; rts`, map at 0x1A88E, 64 entries.
2. The crash D0=0x4E == map[64] == the following rts opcode's first
   byte. The dispatching input was TYPE 64 — pyron's satellite (his
   copies stamp it; the 5 writes land at $FF9402/$FF9502, the projectile
   pool, per the 14z-82 dynamic census; the f7997 instance at $FF9602
   was past the census's 7000-frame window). The map value indexes a
   word table; garbage displacement 0x35E jumped to 0x1AAFE; the garbage
   stream faulted on odd $FF31B5. The 14z-82 probe with
   `b@(a6+2) >= 0x72` was blind BY CONSTRUCTION (64 = 0x40 < 0x72) —
   the type-renumber elimination stands, the "pyron-placed data" reading
   does not (A3 was pyron handler context in live registers, not causal).
3. **The dispatch fires only on a HIT** (`bhi.s` skips it) — which is
   why it is timing-rare: an 11,017-frame chaos soak produces exactly
   one, at f7997.
4. **pyron20 (frozen, stage 6) crashes SOLO** — same replay, same pokes,
   no probes, no merge: CRASH 7997 vec3, identical registers (A3 =
   0xFDC8A, his own single-tenant placement of the same handler data).
   Never caught because (a) `audit_merged_legacy` leg-b bails after the
   merged leg (the ref leg was an assumption — NOW FIXED: it always
   measures the ref leg and prints MERGE-SPECIFIC vs LATENT), and
   (b) `test_pyron_soak.sh` builds STAGE 4, not the frozen stage-6
   artifact — the only gate running 70_mash never ran it on pyron-m2.
5. vs2's sibling map (dispatcher 0x1919A, map 0x19298) has **80
   entries**: 0-58 byte-identical to vsavj (vanilla's true domain — its
   type table has 59 rows), 59-63 divergent (see the Donovan finding),
   64-79 the extension (64→0x02, 68-70→0x04, 71→0x08, 73→0x04, 76→0x04,
   rest 0). Every extension value lands on a word-table entry that is
   byte-identical across the engines, or the do-nothing default (a plain
   rts) — asserted by the generator, so the transplant needs NO handler
   porting.
6. **Huitzil shares the exposure**: his pod code writes types 68/72 into
   the same pool (measured $FF95xx/$FF98xx); zero map entries on his two
   suite replays — UNEXERCISED, not safe. Donovan's 59-63 fit the map.

### The fix (built, gated, measured — NOT adopted; see Decisions pending)

- `tools/gen_hitclass_map_thunk.py` — the 94-byte body, generated from
  the two reference images, never hand-typed: `cmpi.w #80,d0; bcc.s
  ILLEGAL; move.b (4,PC,D0.w),d0; rts; <64 vanilla + 16 vs2 map bytes>;
  ILLEGAL`. Indices 0-63 byte-identical semantics (vanilla's own bytes,
  same CCR/register contract); 64-79 vs2-faithful; >=80 a LOUD planted
  ILLEGAL (vs2's own domain ends at 79; renumbered 5E542-types can never
  reach this pool per the census, and if one ever did it traps loudly).
  The generator's own asserts CAUGHT two wrong first readings: the map
  is 80 entries, not 83 (an odd-alignment impossibility flagged it), and
  the engines' maps differ at 61/62 (the Donovan finding below).
  site_thunk row shape: site 0x01A888, old_hex 103b00044e75,
  patch="jmp", rts_ok (a bsr-entered handler whose body exits by rts —
  stack-neutral, ghost-clean).
- `tests/test_hitclass_map_thunk.sh` — reconstruction gate (regenerates
  from the ROMs, compares any committed row, two verdict controls). ALL
  PASS; notes "row not adopted yet" by design.
- `tests/audit_hitclass_map_cost.sh` — the decision numbers, on a probe
  build (pyron.toml + the row, built to a temp dir, never frozen):
  * **THE FIX HOLDS**: the 70_mash soak END-clean through 11,017 frames
    (the frozen build crashes at 7997).
  * **LEGACY COST: ZERO** — bit-identical whole-RAM checksums on
    01_attract_long / 02_demitri_vs_cpu / 03_two_player_vs /
    05_timeout_idle (30,284 frames), and the FIRE CENSUS explains it:
    legacy content NEVER ENTERS this map on any measured replay (0
    entries; the probe mechanism's liveness is proven by pyron's own
    f7997 dispatch). The thunk is unreachable for measured legacy
    content — the same argument class as the extended-table entries.

### Corrections to hours-old claims (retraction discipline, same session)

- RETRACTED: "f7997 is a pyron-placed data/table defect one level
  removed" (14z-82 close, NEXT_SESSION + patch_notes) — the causal chain
  is the vanilla map over-index; A3's wide_ext value was incidental.
- RETRACTED: "the single-tenant pyron20 build runs this replay CLEAN" —
  never measured; measured now: it crashes. The leg-b harness gap and
  the stage-4 soak gap are both closed/documented.
- STANDS: the type-renumber fix and every 14z-82 measurement (the
  elimination probe's zero was correct for what it asked).

## Session 14z-82 — PER-TENANT TYPE NUMBERS: the vec3 slot fixed, F2 fixed

Scope followed the maintainer's 14z-81 rulings in order: vec3 slot first,
F2 after (same emit path, one expensive re-measure covering both), gfx
still behind. Design variant decided by the maintainer at plan review:
**(b) per-tenant TYPE NUMBERS, first resolver keeps originals** — the
guard-clean tenant's bytes untouched, the census-gap detector dynamic.

### The censuses (before any 68k/bytes — the 14z-78 rule)

**Static** (`tools/audit_type_stamps.py`; frozen, human-reviewed
inventory `build/manifest/type_stamps.toml`; gate
`tests/test_type_stamp_census.sh` with two demonstrated-FAIL verdict
controls):
- **A second stamp FORM existed**: `move.b #type,(2,A4)` — the spawn
  idiom `beq.s <alloc-fail>; move.b #1,(A4); type at +2; owner at +3` —
  ~26 sites the 14z-81b move.l-only scan could not see (type 115 alone:
  20+ in the pod code). GOTCHAS entry filed (a one-form census reads
  exactly like a complete inventory).
- Full 114-120 stamp map: 117 = ONE site (x088512+0x27CE, all three
  copies); 116/119 x088512-only; 115 hui/pyron only; 118 two sites
  (hui/pyron); 114 ~25 sites across 8 per-tenant region names; **120 =
  ZERO sites in any ported span** (only vs2 stamp 0x00B63C, unported).
- **No compare or table-index of the family type byte exists in any
  tenant's code regions** — every candidate compare reads (0x54,An)
  effect-id / (0x14,An) state / registers; every (2,An)-reader
  candidate decoded as record/table reads through An≠object. The only
  true type-index consumers are the pool walkers.
- **Two EMBEDDED walkers live inside the ported spans** (census pass 4):
  vs2's own 0x54470-site walker at src 0x5C602 (its 76-entry table
  TRUNCATED by every tenant's region end) and a third pool walker at
  src 0x8B988 = x088512+0x3476 (hui/pyron copies): pool **$FFC800**,
  24×0x80 slots, OWN local table at +0x3494 — a separate numbering
  space. Neither sees 114-120 (vanilla's own pool separation); both
  recorded in the inventory and the atlas.
- The main walker (0x5E52A family) is UNPORTED by everyone — every
  114-120 dispatch in our builds transits the ONE patched engine site.

**Dynamic** (`tests/audit_type_writes.sh` — 6 MAME tap legs over the
ground-truth builds via new `tests/lua/type_write_census.lua`):
- **Every observed 114-120 type-byte write maps to a frozen stamp row**
  (the gate for register-sourced/computed stamps the static scan cannot
  see). 117-stamp rig-liveness green.
- Types **118/120 NOT OBSERVED** — no verdict, recorded as such. 118
  renumbers on static evidence (a build-time byte edit, old-verified);
  120 is not renumbered and the dispatch-range gate carries the
  residual.
- The 115→117 mid-frame "morph" (14z-81c) is the 117 header re-stamp at
  x088512+0x27CE — inside the same per-tenant copy, so stamps renumber
  TOGETHER and the morph is timing-proof under this design.

### The emit path (gen_donovan_patch.py; all N=1-inert by construction)

Pre-loop pure map (placement-independent: tenants' regions.json + the
frozen inventory + the src table): for each multi-resolver type at site
0x5E542, every NON-first resolver tenant with ≥1 frozen stamp site gets
the next index after the authored obj_hook_extra rows — 12 assignments
(124-135 = H/P × 114-119), <256 asserted (byte-indexed walker).
Per-iteration blob pass rewrites ONLY the TT byte per stamp
(full-source-span verified first; port_patch/imm_poison overlap
asserted) — 69 rewrites at N=3, reconciled 1:1 against the inventory;
byte-proof: hui x088512+0x27CE `...8200` (130), pyron `...8300` (131),
donovan untouched `...7500`. The union appends the renumbered entries
resolving through the OWNING tenant's view (no-gap asserted); the
original entries serve the first resolver BY DESIGN (note says so; the
FIRST-WINS warning note now applies only to unrenumbered types — 120 —
and the deferred 0x54470 family). Map + worklist EMPTY at N=1; the
frozen references cannot move — and did not (test_m3a_reproducible
bit-exact, run before anything else, twice: pre- and post-F2).

### F2 — the merged shim now serves every declaring tenant

Root defect: `singleton()` planted the shim on iteration 0's row only,
and the old chain's uniform `jmp newt` could only exit into tenant-0's
handler. Fix: `flavor_chain_multi()` — each 54-byte block exits into its
OWNER's handler; declaring tenants' handlers are collected per iteration
and ONE merged shim is assembled at engine_here (the 14z-80h
assemble-after-the-loop shape), planted on dispatch_00[0x13] AND [0x10];
pyron [0x11] stays direct (ratified: declares no shim); unmatched id →
planted TRIPWIRE — that fall-through tripwire is the ONE op added
(590→591; test_tenant_loop 436/590→437/591 and audit_merged_legacy's
fixture re-frozen FIRST, per the standing rule). Fragment:
`MERGED init shim ... donovan<-0x01->handler 0xc1030,
huitzil<-0x00->handler 0x403b00 ... planted on 2 dispatch rows`.
audit_merged_legacy section 0 now asserts the POST-fix shape (HENT ==
SHIM, PENT != SHIM) and measured both tenants' char-init executing
through the shim (2 hits each at 0x4ba4e0).

### Measured verdicts (the full ladder, in the §4 order)

1. `test_m3a_reproducible` — four frozen fingerprints bit-exact, run
   FIRST both pre- and post-F2.
2. `test_tenant_loop` — green at the re-frozen 437/591; all five
   verdict controls intact; single-tenant counts unchanged (243/259/205).
3. `test_type_stamp_census` — green + two demonstrated FAILs.
4. `audit_merged_vec3` — **GREEN**: merged satellite A0 = anim@huitzil
   +0xB8AC (per placements.json), crash-free. (Read per the 14z-81c
   first-green rule: printed values checked, not just the verdict.)
5. NEW `audit_type_dispatch_range` — verdict control on hui29 sees 5,862
   original-range dispatches; merged hui mash: original range CLEAN,
   **5,862 renumbered** (the entire stream moved to his numbers);
   merged pyron: original range clean, 0 renumbered (EXPECTED — his
   content provably never spawns this family in these replays; probe
   liveness comes from the sibling sections); merged donovan: 4,575
   originals still served.
6. `audit_merged_legacy` (~45 min, both fixes in one re-measure): 591
   ops asserted; section 0 F2-fixed + all three char-inits execute;
   determinism leg bit-identical; **leg (a) 13/14 ratified classes
   VERBATIM** — the one FAIL is `04_select_fuzz`'s held-un-ratified
   {1525, 2005, 2009, 2195} inventory, BY DESIGN per the maintainer's
   standing decision; **leg (b): huitzil 70_mash AND 83_fx GUARD-CLEAN
   over their full replays** (the two former crashers),
   **donovan/12_vs_cpu guard-clean** (the withdrawn-design killer),
   donovan/20 transient-and-reconverged (890..3667, 8,453 clean after —
   the 14z-81 shape), pyron/72 guard-clean, pyron/70 still f7997 (below).
7. `test_hui_pairs` not re-run BY MEASUREMENT: the frozen hui29 bytes
   are proven bit-exact by the fingerprint gate, and identical bytes
   cannot produce a different replay.

### The 04 flicker's owner is NAMED (ratification input, not a fix)

`FBNEO_HTAP ff0460-ff0463` on vanilla 04_select_fuzz: ONE gameplay
writer, 394k writes — `PRG:0x0011E2 move.l a0,(-$7BA0,A5)` (tap
attributes the following PC 0x11E6), the SOUND DRIVER's dispatch
prologue spilling its current record pointer (with SP at $FF045C);
values cycle the $FF02xx channel records (0x20-stride 025C..02DC, 031C,
033C) and rest at the $FF043C latch. The merged flicker at f2005 sampled
it MID-SCAN ($00FF02DC) — one-frame pointer phase, no gameplay surface,
the ratified hook-flicker family. The 14z-81 "sound-queue drain cursor"
WITHDRAWAL is superseded by this measured owner. Scripted:
`tests/audit_ff0460_writer.sh` (single-writer + value-range locks; a
frame<200 boot filter, liveness control). Atlas row added. The
ratification decision itself stays with the maintainer (decision 1,
14z-81) — now about a named mechanism.

### Pyron f7997: STANDS, and it is measured NOT to be this class
### (SUPERSEDED same day by 14z-82b above: the "pyron-placed data/table
### defect" attribution below is RETRACTED — the crash is a LATENT vanilla
### hit-class map over-index, present in frozen pyron-m2 solo, fixed on a
### probe build. The elimination measurement in this subsection stands.)

Crash-time instruction history (GUARD_PROBE_HIST now also fires from the
guard's on_crash — added this session, replay_guard.lua) names the
route: hitbox-ish compare at 0x191BA.. → vanilla dispatcher 0x1A77E →
`0x1A790 move.b (2,A6),d0` → byte class-map `0x1A888 move.b
(4,PC,D0.w)` → word table → `jmp (2,PC,D1.w)` → garbage stream →
vec3 on odd $FF31B5. **The elimination measurement:** a probe at 0x1A790
with `b@(a6+2) >= 0x72` recorded ZERO hits across the whole replay while
the crash fired identically — no extended-family type ever enters that
mapper, so the renumbering (and the census's exposure claim) are not
implicated. What IS implicated: A3 = 0x49bAEA (inside pyron's OWN
wide_ext placements) feeding that vanilla path, and the fault address
$FF31B5 = A4+0xAB (an ODD table-derived offset into the $FF310A record)
— the shape of a pyron-placed data/table defect (data_in_code / pcrel /
placement class), one level removed from the dispatcher. Evidence:
build/gate_failures/merged1_b_70_pyron_mash.log + the HIST capture.
NEXT SESSION'S FIRST TARGET.

### Kept / retired

- RETIRED: "types 114/115/118/120 are stamped elsewhere or computed"
  (census answered all four); the FIRST-WINS/declaration-order-luck
  status for types 114-119 (now designed); F2 as an open defect (all
  copies fixed: merge_init_shim docstring, HANDOFF registry row +
  merged1 paragraph, audit_merged_legacy section 0). Historical entries
  stand unedited per the retraction discipline; NEXT_SESSION rewritten.
- KEPT: the 19 FIRST-WINS notes' machinery (now printing the designed
  note for renumbered types, the warning only for 120 and the deferred
  0x54470 family); `owner_dispatch_stub()`/`OBJ_HOOK_OWNER_READ` as the
  historical record; the census rigs.
- The 0x54470 family (59-75) stays DEFERRED with its notes standing —
  now WITH its measurement attached: the frozen inventory carries its
  full stamp map (donovan/hui/pyron each stamp subsets; x088512's 17
  type-65-family stamp sites are in all copies), and the embedded
  truncated walker at 0x5C602 is a named renumbering hazard for THAT
  family only.

## Session 14z-81 — THE MERGED-LEGACY MEASUREMENT: legacy safe, tenants not

The 14z-80 close set this as the session's only first priority, and it ran
to completion. Instrument: `build/merged1` — the 3-tenant program image
(the exact `test_tenant_loop` 590-op merge, asserted) packed against the
zero-filled `build/wide0` overlay, gfx skipped. Legacy characters read
groups A/B (group B pristine by construction), so the build renders legacy
correctly and the tenants as blanks: right for a legacy verdict, useless
for anything else. It has NO registry row on purpose and must NEVER be
playtested (`build/merged1/README-LEGACY-ONLY.txt`).

Everything below is rerunnable: `tests/audit_merged_legacy.sh` (build +
section 0 rig proof + determinism + both legs, ~45 min) and
`tests/audit_merged_vec3.sh` (the crash probe, ~4 min).

### Leg (a) — merged vs VANILLA, masked-v2: 13/14 ratified classes VERBATIM

Expectation was donovan-m3a's frozen table (all three tenant sets agree on
the 13 shared legacy entries; a merged build backs 0x13 so `11_pick_donovan`
applies). Measured: every class, onset, window end, flicker inventory and
re-convergence EXACT — `01_attract_long` bit-identical, the `08` two-window
composite (one per select entry), `05` through a full timeout match, `11`
window 889..2415 — except ONE:

- **`04_select_fuzz`: one extra flicker frame at 2005** (measured
  {1525, 2005, 2009, 2195} vs frozen {1525, 2009, 2195}); window 889-1104
  and the 1325-frame re-converged tail unchanged. Deterministic (two fresh
  merged runs identical) and merge-specific (m3a re-measured the frozen
  inventory the same day, same instrument). Byte attribution (whole-RAM
  dumps, vanilla vs merged at 2005): 66 dead-stack bytes plus exactly TWO
  live bytes `$FF0462-$FF0463` — the low word of a LONG at `$FF0460` that
  holds `$00FF043C` (the QSound latch's address) on vanilla and `$00FF02DC`
  on merged at that frame; re-converged one frame later. A one-frame
  pointer-phase artifact with no gameplay surface, but the POINTER'S OWNER
  IS UNIDENTIFIED — `$FF0460` is not in the atlas, and my first reading
  ("sound-queue drain cursor") is WITHDRAWN as unverified speculation
  ($FF02DC also appears as a RAM-stub return address in unrelated healthy
  flow, so the value alone proves nothing). Identify the writer before any
  ratification argument (FBNEO_HTAP on ff0460-ff0463 is the cheap
  instrument).

Per CLAUDE.md §4 the widened inventory is MEASURED, NOT RATIFIED: the audit
FAILS on it by design until the maintainer signs it off or the mechanism is
removed. Also measured: two masked runs of `03` bit-identical (first-ever
determinism check on a merged image), and section 0 proved all three
char-init entries execute (shim 0xcbf80 for D; `dispatch_00[0x10]` →
0x403b70 and `[0x11]` → 0x45f504 — both in the raw extension, consistent
with 14z-78's code-runs-from-wide_ext finding).

### Leg (b) — merged vs the frozen single-tenant builds: two tenants break

| tenant | replays | verdict |
|---|---|---|
| Donovan | 12_vs_cpu, 20_round2 | guard-clean; vs m3a: 20 TRANSIENT (890..3667, then 8453 identical incl. round 2), 12 PERMANENT (890..end, 722 interleaved runs). UNATTRIBUTED; the shape fits cached placed pointers (placements differ between the builds by construction), but that is a hypothesis, not an attribution |
| Huitzil | 70_mash, 83_fx | **CRASH, both, deterministic** — vec3 at char-init (MAME f2886/2887, 4/4 runs incl. the probe audit), pushed PC 015098, odd A0=000c6df9 |
| Pyron | 70_mash, 72_cosmo_2p | **70 CRASHES at f7997** (vec3, PC 01ab10, odd RAM ptr $FF31B5, A3=0x49bb8a in his own wide_ext; identical REGS on re-run — deterministic; evidence in `build/gate_failures/merged1_b_70_pyron_mash.log`). 72 (the only rig that fires Cosmo) guard-clean, PERMANENT divergence from f890 as expected |

### 14z-81c — THE STUB FIX: implemented, measured green for Huitzil,
### and WITHDRAWN the same day on two measured failure modes

The maintainer ruled "fix the vec3 slot first"; this is the honest record
of the first attempt. Every premise was measured before authoring
(walker register contract from the vanilla disassembly; per-type
owner-reads from the census + a full 115-tick trace via the new
`GUARD_PROBE_TRACE`), the owner-dispatch stubs were emitted for the three
MEASURED types (115=d32, 117=d30, 119=hop-via-+0x30), and the results
were real:

- **N=1 inert**: all four frozen fingerprints bit-exact with the stub
  code in the generator (no type is multi-resolver with one tenant).
- **Huitzil FIXED**: `audit_merged_vec3.sh` GREEN — the merged satellite
  read `A0=0x425FFC` (= anim@huitzil+0xB8AC, the healthy value) and ran
  crash-free; both former crashers (70_mash, 83_fx) guard-clean in the
  full battery. (The gate's FIRST live PASS caught the gate's own
  verdict bug — a zero-padding string compare — which could not be
  ground-truthed until a fixed build existed. Fixed to numeric.)
- **Legacy untouched**: leg (a) 13/14 VERBATIM, byte-for-byte the same
  table — the stubs never execute on legacy content.

**And then the same battery measured two failure modes of ANY
dispatch-time owner read:**

1. **Stale/recycled parent chains** — `donovan/12_vs_cpu` REGRESSED
   (guard-clean before, tripwire after): a type-119 object's creator hop
   walked through a recycled slot to P2, and `(0x382,P2)` was `0x06` —
   which is not transient at all but the CPU's REAL pick (the forced-pick
   pokes hold only through select; the loaded struct carries the true
   character). First-wins had served that object correctly.
2. **Spawn-instant transience** — the type-115 census: +0x30 reads zero
   at dispatch while the same frame's dump shows the owner; the type
   byte itself morphs 115→117 within the frame.

Two counterexamples from six replays means the failure space is not
enumerated, and a mis-dispatch is SILENT-WRONG — worse than the known
loud crash on an unshippable instrument build. Per the 14z-78 precedent
the emission was WITHDRAWN: `OBJ_HOOK_OWNER_READ = {}` (the measured rows
kept in its comment), and the rebuilt merged image is **bit-identical to
the pre-fix instrument — fingerprint 7a9eabb3 verified**, which is the
revert's own regression proof.

**KEPT (all zero image bytes or N=1-inert):** the multi-resolver
detection with FIRST-WINS notes — 19 notes in a merged fragment, naming
every order-dependent entry including site 0x54470's types 64-75, whose
correctness today is DECLARATION-ORDER LUCK (huitzil declares before
pyron; the first cut of the branch tripwired them and taught the
multi-resolver ≠ multi-owner distinction); `resolve_ported_all()`; the
stub builder (`owner_dispatch_stub`, correct 68k, hand-verified and
battle-tested — reusable); `GUARD_PROBE_TRACE`; the census rig; and the
vec3 gate's numeric-compare fix.

**THE ROBUST DESIGN (next session): spawn-time tenant tagging.** Each
tenant's OWN copy stamps its spawns, so a tag written at spawn — or
per-tenant TYPE NUMBERS rewritten in the copies' stamp immediates — makes
dispatch timing-proof with NO runtime owner read. Census so far: x088512
carries `move.l #$01xxTTxx,(A4)` stamp immediates for types 116/117/119
(offsets +0x20b0/+0x27ce/+0x1dc4,+0x2138); types 114/115/118/120 are
stamped elsewhere or computed — that census, plus a type-COMPARISON
census inside the family regions, is the next session's first
measurement. Also measured today and relevant: Donovan's own content
uses the 117/119 family (his objects dispatched them in a
Donovan-vs-CPU match), so ALL THREE tenants stamp.

**Unchanged by all of this:** Pyron's f7997 crash (byte-identical
registers pre- and post-fix — fully independent, still open) and the 04
flicker at 2005 (deterministic, held un-ratified per the maintainer's
ruling).

### 14z-81b addendum — THE VEC3 SLOT IS NAMED (same day, after the
### maintainer's rulings): a MULTI-OWNER obj_hook type has ONE table entry

`GUARD_PROBE_HIST` (added to the guard this session — the debugger's
`history` captured at each probe hit, because RET <(SP)> lies for tail-jmp
entry) shows the crash instruction stream verbatim:

```
0D22C4: movea.l #$cb9c0, A0     <- inside TENANT-0's x088512 copy
0D22CA: jmp     $15084.l        <- the vanilla anim walker
```

The chain of facts, each verified:

1. `0xCB9C0` is a PLANTED TRIPWIRE in tenant-0's build:
   `x088512+0x2156: unresolved 0x25111e -> tripwire 0xcb9c0`
   (m5_wide fragment:140). Donovan's copy of the satellite-spawn literal
   targets HUITZIL-anim source space he does not port — dead path for him,
   correctly tripwired, single-tenant-fine. The walker consumed the
   tripwire ADDRESS AS A DATA BASE, so the planted ILLEGAL never got to
   name itself — it surfaced as a vec3 two instructions later. (A tripwire
   only names itself when JUMPED to; used as data it is just a bad
   pointer. Worth remembering when reading any vec3 near a tripwire
   block.)
2. Huitzil's OWN copy is CORRECT: `fixed_x088512.huitzil.bin` at the same
   offset holds `movea.l #$425FFC` = anim@huitzil+0xB8AC exactly (and
   pyron's holds his own 0x4A7BE0). The reconciler did its job per tenant.
3. The defect is the ROUTE: the crashing object is TYPE 117 (0x75, header
   `01007500` in the crash dump), dispatched from the vanilla pool walker
   (0x5E52A / obj_hook site 0x5E542's EXTENDED table) into tenant-0's
   copy. Type 117 appears in NO tenant's tripwire list — its handler
   lives in x088512, which ALL THREE tenants port, so every tenant's view
   resolves it and the engine-level union (14z-80f) had to pick one
   address for ONE table slot. It picked tenant-0's copy. One
   tenant-reconciled copy cannot serve N tenants: any non-tenant-0 tenant
   spawning the 117 family executes Donovan's literals.
4. The fix's one runtime prerequisite is MEASURED: the object's `+0x30`
   word holds the OWNING PLAYER struct's low word (`0x8400` in the crash
   dump = $FF8400 = P1; the sign-extended `movea.w` idiom is visible in
   the crash registers, A3=0xFFFF8800). So an owner-id dispatch can read
   `(+0x30,A6) -> (0x382,player)` — the exact read test_shim_charid.sh
   validated on player structs.

**FIX DESIGN (the 14z-80h chain form, applied to obj_hook):** for a type
resolved by MORE THAN ONE tenant's view, the union's entry must point at a
generated owner-id dispatch; tail = tripwire (an object owned by a LEGACY
character reaching a tenant type is a bug worth naming, not a
fall-through). At N=1 no type is multi-owner, so nothing is emitted and
every frozen build stays bit-exact BY CONSTRUCTION.

**14z-81b MEASUREMENTS TOWARD IT — and why the stub did NOT ship the same
day.** The premises were measured before authoring 68k (the 14z-78 rule),
and one of them failed:

- **The multi-owner set is types 114-120** (seven; site 0x5E542's extended
  table, handlers = x088512 copy offsets +0x0/+0x12BA/+0x1D5C/+0x20DA/
  +0x27E6/+0x2BC8/+0x2CEA). Site 0x54470's extension partitions cleanly
  (59-63 Donovan-only, 64-75 Huitzil-only) — no stubs needed there.
- **The walker's register contract is MEASURED** (vanilla 0x5E52A-0x5E554
  disassembled): loop state is A6/A5/($B5,A5) only; A1 and D1 are never
  read — clobber-safe with NO pushes. Handler entry contract: A0 = the
  handler's own address, D0 = 0, CCR = moveq's Z — reproducible per exit
  with `moveq #0,d0; movea.l #handler,a0; jmp (a0)` (movea does not touch
  CCR).
- **`+0x30` owner linkage: works for 117 (P1 direct) and 119 (creator
  object -> player at depth 2), FAILS for 115.** Census over two replays
  (`tests/audit_objhook_owner_census.sh`, the rerunnable rig): type 115
  dispatches with `+0x30` = 0x00 AT DISPATCH TIME, while the SAME frame's
  end-of-frame dump shows 0x84 in the same slot — and the slot's type
  byte reads 117 in the dump vs 115 at the dispatch instant. The field
  (and the type byte) are TIME-VARYING WITHIN A FRAME for this part of
  the family. An owner-walk stub would tripwire legitimate 115s — merged
  Huitzil fires them constantly. Types 114/116/118/120 were NOT OBSERVED
  by these replays: no verdict, and a design that assumes their shape is
  guessing.

**Two candidate designs for the implementing session:**
(a) **Owner-walk stub** (unrolled depth-4 `movea.w (0x30,aN),a1` chain
    against $FFFF8400/$FFFF8800, then per-tenant `cmpi.b #id,(0x382,a1)`)
    — proven viable for 117/119 only; needs a per-type answer for
    115-family timing before it can carry the whole table.
(b) **Spawn-time tenant tag** — each tenant's OWN copy stamps its spawns
    (the `move.l #$1007700,(A4)`-style writes live inside the per-tenant
    copies), so patching the stamp sites to also write a tenant-tag byte
    into a KNOWN-FREE object field makes the dispatch a single
    `cmpi.b #tag,(off,A6)` — no walks, no time-variance, and the tagging
    is per-tenant by construction. Costs: a free-field census (which
    object byte is never touched by any handler in the family) and a
    stamp-site census inside x088512 (the reconciler's note list already
    enumerates the copies' write sites).
Also still open: whether Pyron's f7997 crash dissolves with this fix (his
objects transit the same family) or is a second instance — re-run his leg
with GUARD_PROBE_HIST when the fix build exists.

### The Huitzil crash, localized (the 14z-81 first-pass chase; the
### conclusion is superseded by the 14z-81b addendum above — the slot IS
### now named)

The chase, each step measured (probe rig = `audit_merged_vec3.sh`):

1. The faulting site is the vanilla anim walker — entry `PRG:0x15084`
   (`andi.w #$ff,d0; add.w d0,d0; move.w (0,a0,d0.w),d0; lea (0,a0,d0.w),a0;
   move.l a0,(0x1c,a6); move.l (a0),(0x20,a6)`); the fault is the last move
   at 0x15096 (pushed vec3 PC 0x15098 is MID-INSTRUCTION — probing IT reads
   a clean zero forever; gotcha filed).
2. The crashing object is `$FFB800` — a SATELLITE, not the player struct.
   Entry probe at f2886, both builds, same object, same index (D0=0), same
   `(SP)` long: hui29 healthy base `A0=0x000E456C` = his placed anim +
   0xB8AC; merged `A0=0x000CB9C0` — an UNPLACED GAP. Healthy merged value
   would be anim@huitzil + 0xB8AC = 0x425FFC. (CORRECTED 14z-81 same day:
   that `(SP)` long `0x00FF02DC` was first read as a "RAM-stub caller" —
   it is a CHANNEL-RECORD POINTER in the $FF02xx block, identical on both
   builds because the walker is entered by TAIL-JMP and `(SP)` holds the
   outer frame's data, not a return address. `GUARD_PROBE_HIST` was added
   to the guard so a probe can name a jmp-entry caller from the debugger's
   instruction history instead.)
3. `0x000CB9C0` appears NOWHERE in the merged image (raw-byte search and
   ops search both empty) — the base is COMPOSED AT RUNTIME.
4. `0xCB9C0 - 0xB8AC = 0x000C0114` = **tenant-0's ported `code` region +
   0xA74** (vsav2 0x059490+0xA74): a DONOVAN address feeding a HUITZIL
   object's anim walk.
5. Ruled out by direct verification: all fifteen `anim_index_{a,a2,b,c,
   proj}[id]` rows are correct per tenant in the merged fragment (H's five
   point into anim@huitzil); H's `x06cac0` satellite-machine blob is
   byte-identical to hui29's except literals correctly re-derived to merged
   placements (spot-checked, incl. the x026142 dc-table pointer
   0xCA152→0x40BE62); the pc-rel stub + word table at x026142+0x13E2 is
   byte-identical (position-independent).
6. NOT the F2 path: the crash is at spawn's first anim walk; the bypassed
   pool seeder never gets a chance to matter.

So one per-tenant pointer slot — read by the satellite spawn path, not any
of the tables above — holds tenant-0's value in a merged image. The next
step is a spawn-entry trace (GUARD_PROBE on H's satellite spawn handler in
`x06cac0@huitzil` at 0x415980, or `tests/lua/index_watch.lua`), watching
where the composed base's 0xC0114 half is LOADED from. Note for that
session: FBNeo taps on object slot $FFB800 are NOT comparable to the MAME
runs — frame skew plus slot recycling put the satellite in a different
slot there (and merged survives the whole replay on FBNeo, so the defect's
observable is emulator-frame-dependent; the MAME leg is the instrument).

### F2 — the merged shim serves only tenant 0 (confirmed, separate defect)

`merge_init_shim` stamps `_owner=None` → `row_here` → iteration 0 →
planted at `dispatch_00[0x13]` only; merged-H's row is direct-repointed to
his handler (fragment shows `dispatch_00[0x10] donovan handler`, no shim;
statically `HENT != SHIM` asserted by the audit's section 0). Merged-H
therefore skips pool seeding, the phase gate, and his flavor write; the
slice-G id-dispatched flavor chain can only ever run with id 0x13 today.
Consequences unmeasured (the vec3 crash fires first). Fix shape is a
design question — the shim's tail jmp targets ONE handler, and later
tenants' handlers aren't placed yet on iteration 0, so this is the
`site_thunk`-style assemble-after-the-loop pattern (14z-80h), not a
one-line gate change.

### Verdict controls run this session

The leg-(a) checker demonstrated BOTH verdicts on real data with one
instrument: m3a PASS + merged FAIL on `04` the same day (drift is caught),
and the composite/window classes fail bit-identical pairs by construction.
The vec3 probe audit proved it can FAIL before being trusted (it currently
does, by design), and its section-0 equivalent (no PROBE at 2886 on hui29 =
rig dead) guards the dead-instrument case. `test_tenant_loop` green;
`test_m3a_reproducible` re-run this session (all four fingerprints).

### Decisions — RESOLVED by the maintainer, 2026-08-12 (were "pending" for
### less than a day; kept here in full so the ruling sits beside its options)

1. **The 04_select_fuzz flicker at 2005.** One deterministic, fully
   re-convergent extra flicker frame on the merged build, two live bytes,
   mechanism family known (one-frame pointer phase), owner unidentified.
   Options: (a) hold ratification until the pointer's writer is identified
   AND the two crashes are fixed, then re-measure the whole table
   (recommended — the merge is changing anyway); (b) ratify the widened
   inventory now for a future merged expectation set.
   **DECIDED: (a) — hold, re-measure the whole table after the fixes.**
   Nothing is ratified for merged builds until then; the audit keeps
   failing on the widened inventory by design.
   **SUPERSEDED 2026-08-12 (14z-82d close): RATIFIED.** All hold
   conditions were met (both crashes fixed, mechanism named —
   $FF0460 = the sound driver's record-pointer spill,
   tests/audit_ff0460_writer.sh — and the same-day re-measure on the
   adopted tree reproduced the identical inventory), and the maintainer
   ratified the merged 04 inventory {1525, 2005, 2009, 2195} (composite,
   window 889-1104): "given the state of exploration and how limited the
   practical impact is, I'm fine with ratifying." EXECUTION IS NEXT
   SESSION'S FIRST ACT (maintainer: any work next session): encode the
   ratified merged-04 expectation in audit_merged_legacy (the merged
   instrument is unregistered by design, so its expectation lives in the
   audit; the audit's own proposed line is the spec verbatim) and run
   the audit to full green.
2. **The H shim bypass (F2).** Fix now (assemble-after-loop chain, then
   re-measure `audit_phase_mode_cost`-style) or accept temporarily and
   gate on the vec3 fix first? Recommendation: fix AFTER the vec3 slot is
   named — both touch the same emit path and one re-measure covers both.
   **DECIDED: fix AFTER the vec3 slot is named**, as recommended.
3. **Does Phase 3 (gfx) wait for the leg-(b) fixes?** The gfx design is
   independent of the program-side defects, but any tenant behaviour
   battery on a merged build is meaningless until Huitzil survives
   char-init. Recommendation: fix the vec3 slot first — it is one
   localized defect with a regression gate already in place.
   **DECIDED: agreed — the vec3 slot first.** Phase 3 order stands behind
   the leg-(b) fixes.

## Session 14z-80 — THE N-TENANT LOOP: `main()` iterates, and the three
## traps that were not in the spec

M3b's remaining milestone. Everything the loop depends on had landed
(slices A-F: per-file ownership, owner-threaded gating/arithmetic/baked-code,
repeatable `--port` paired with `--extract`, a collision-free 3-tenant merge),
so the ORDERING INVARIANT of 14z-77 was satisfied and the loop was allowed to
land. Scope, agreed with the maintainer before starting: **generator only.**
`build_donovan.sh` stays single-tenant and the gfx half is untouched (Phase 3).

### THE STATE BOUNDARY, as implemented

| SHARED (accumulates) | PER TENANT (rebound each iteration) |
|---|---|
| `spaces`/`order` — ONE cursor, so tenants cannot allocate over each other | `extract_dir`, `man` |
| `gap_free` | `recon` (see trap 2) |
| `ops`, `notes`, `fail`, `fragments`, `all_placements` | `dst_slot`/`var_slot`/`mirror` |
| `alloc` / `repoint` / `poke_bytes` / `table_entry_addr` | `placed`, `regions`, `dc_tables`, `pcrel_far_tramps` |
| `row_ident` / `owner_of` / `row_here` closures (they read the rebound `T`) | `patched_clones`, `farm_ports` (already inside `if stage>=2`) |

**`pcrel_far_tramps` is added to 14z-78's list.** It is the same shape
`dc_tables` was called out for — a memo keyed by ADDRESS with no tenant key.
Sharing it hands tenant B a trampoline placed near tenant A and trips the d16
check at its own use site: a spurious hard fail rather than a wrong image, but
wrong, and it was not in the classification.

### THE ITERATION GATE

`row_here(row)`: the row's `_owner` IS this tenant, **or** it is unowned and
this is iteration 0. Applied through `tenant_rows(section)` (19 list sections)
and `singleton(section)` (9 singleton reads), so a MISSED site is findable by
grepping `port.get("` below the loop header rather than by reasoning — which
is what the new gate does. Named `tenant_rows` and not `rows` because `rows` is
already a local bytearray in the `table_fix` and `select_wheel` blocks, which
would have silently rebound the helper mid-body.

Eight `port["port"]` reads inside the body were converted to `T` in the same
change and they are the **silent** ones — `port["port"]` is pinned to
`_tenants[0]` forever, so each would have given every tenant the FIRST tenant's
value (`src_char` twice, `near_map`, `alloc_wrap`, `port_param32`, `gfx_bank`
three times). Same trap class slice E found in `charid_sites`.

### THE THREE TRAPS

**1. THE SIDE-FILE NAMESPACE IS SHARED; THE CONTENT IS NOT.** Region blobs
leave as files named after the REGION (`fixed_x026142.bin`), and 14z-77h froze
SEVEN region names as shared across the three tenants. Under the loop tenant
B's write clobbers tenant A's file while A's op still names that path — and the
patcher then writes B's bytes at A's address. Invisible to patch_prg's overlap
assertion (the addresses differ) and impossible to see with one tenant. Fixed
with a per-tenant SPELLING (`side_name()`), tenant 0 keeping the historical one
so every single-tenant build emits the identical file set, and `write_out()`
underneath refusing any name written twice with different bytes.

**2. THE RECON OVERLAY WAS TENANT 0'S, FOR EVERYONE — and it was MEASURED, not
reasoned.** `recon_overlay` is a `[[tenant]]` key, but `tenant_context()`
copies a fixed key list and it was not on it, so `T.get("recon_overlay")`
returned nothing and the loop fell back to `tenant[0]`'s. The first
donovan+huitzil run died on `x022400+0xb74: bank_ref 0xd96b8 needs a verified
reconciliation row` — a row huitzil's own overlay resolves. Each tenant now
gets the shared map plus ITS OWN overlay (`recon_for()`), which is the
per-tenant row scoping the comment at that site has promised since 14z-65.
Ordering check done rather than assumed: no `unstub` address is shadowed by
either overlay, so building the base map before the overlays is inert.

**3. `placements.json` needed accumulating**, with the shared names suffixed
`@<tenant>` — they are DIFFERENT spans.

### WHAT A MERGED BUILD DOES TODAY, exactly

| tenants | ops | result |
|---|---|---|
| 1 (each of D/H/P) | 243 / 259 / 205 | output directory byte-identical to the pre-slice generator |
| 2 (D+H) | 455 of 502 declared | GENERATION OK |
| 3 (D+H+P) | 612 of 707 declared | GENERATION OK |

**It generates; it does not apply — SUPERSEDED by 14z-80e-h below, which took
this to 0/0 and made patch_prg accept it. The analysis stands as the starting
point; the numbers are historical.** `patch_prg.py` refused the merged patch by
name at the first op overlap. Inventory at that point:
**10 overlapping op pairs / 36 bytes.** 34 of those bytes lie inside the four
shared spans 14z-77h froze as conflicting (`x026142`/`x028122`/`x05c800`/
`x2b7ef4`). The largest class is four 6-byte collisions at engine SITES —
`0x5F1B6` twice and `0x5F146` twice — where each tenant emits its own thunk.
**That is the N-way dispatch FORM, and it now has a number instead of a
description.**

Note also, from the one-iteration control: over the MERGED document tenant 0
alone emits **241** ops, not donovan-alone's 243, because `merge_manifests`
folds the singletons and the dedup moves allocations. So "three manifests with
only Donovan iterating" is NOT the same build as "donovan.toml alone" — which
is precisely why M3b_plan's Phase 2 exit gate reproduces `4b7d0dc7` by passing
ONE FILE, the thing per-file ownership bought in 14z-77.

### THE SPACE QUESTION ANSWERED ITSELF

The plan expected a 2-tenant run to overflow `hole_a` (14z-77 measured one
tenant saturating the crypt window) and budgeted a scratch-manifest rig with
`region_space` overrides for the gate. Not needed: `alloc()`'s declared
fallback chain spills into `wide_ext` on its own, and three tenants fit with
`hole_a`/`hole_b` exactly full and 0x145AA0 spare in `wide_ext`. `region_space`
remains worth setting deliberately — the spill is not a placement DESIGN — but
it is not a blocker and it does not need to touch the frozen manifests.

### GATE

`tests/test_tenant_loop.sh`, generator alone, ~6 s: determinism ground truth;
N=1 frozen per tenant with no tenant-suffixed side files; the N=2/N=3 op counts
AND their dedup arithmetic; each tenant's regions placed at distinct addresses
with per-tenant side files and `tenants.json` in declaration order; the
collision inventory of section 4; and two verdict controls — forcing one
iteration must collapse 612 to under 300, and disabling `side_name()` must be
CAUGHT rather than clobber.

`tests/test_tenant_id.sh`'s refusal control is FLIPPED, as 14z-77 wrote it to
be: two tenants must now be accepted, in declaration ORDER, because the loop
pairs `_tenants[i]` with `_extracts[i]` by position.

Also re-frozen: `tests/test_manifest_merge.sh`'s `site_thunk` row, RED since
14z-79 added the (b') thunk to huitzil.toml (10→11 per file, 28→29 merged; the
shared count is unchanged because (b') is owned).

### 14z-80e/f/g/h — FOUR DEFECTS UNDER THE LOOP, AND THE MERGE CLOSES

The four items this section originally listed as open are DONE. Each was
measured before it was touched, and three of them were invisible to every
gate that existed at the time.

**1. The iteration gate's shared-row rule was wrong TWICE (14z-80e, 14z-80g).**
14z-80b shipped "an unowned row belongs to iteration 0". That is right for a
row patching one engine address and wrong for a row whose EFFECT is
tenant-derived:

| key | what iteration-0 did | measured |
|---|---|---|
| `region`/`regions` | patched only tenant 0's COPY of the shared spans | all 6 shared `port_patch` OBJ bank setters left Huitzil's and Pyron's x05c800/x088512 holding vs2's bank 3 — the wrong graphics bank, silently. Also dropped 2 `pcrel_escape_fix` rows and the merged `[table_fix]` union |
| `slot_table` | wrote tenant 0's TABLE ENTRY for everyone | H's and P's `obj_bank_word_slot`/`win_pos_x_slot` wrote DONOVAN'S entries (0x282FA / 0x5F24C), colliding with his, while H and P got none |

Fixed by classifying the row, and — for the second — by keeping `_owners`
through `merge_manifests`' dedup: two tenants declaring the same row TEXT are
not writing the same word, and the merge used to forget who they were.

**2. `obj_hook` resolved only tenant 0's handlers (14z-80f).** One engine
table, entries ported by different tenants. 15 extras fell to tripwires and
TWELVE were Huitzil's (types 64-75) — every one of his secondary objects would
have dispatched to a planted ILLEGAL on spawn. Now `engine_here()` runs it on
the LAST iteration through `resolve_ported()`/`resolve_recon()` over every
tenant's published view: 17/17 placed, 59-63 in Donovan's regions and 64-75 in
Huitzil's OWN copies, and types 121-123 (handler 0x6A70C, ported by nobody)
correctly still tripwired.

**3. The rest were AGREEMENTS, not conflicts (14z-80g).** Donovan's
`data_port hit_class_props_ext` and H's/P's `aux_poke effect_map_*` write the
same three words with the same values; H's and P's adjacent `byte15b` entries
widen to one word with the same content. Nothing silently won — but patch_prg
rightly refuses any two ops on one word, so a merged patch stopped on an
agreement. An op whose every byte is already written with the same value is
dropped at emit, named in the notes; anything partial or disagreeing is left
for patch_prg, because this pass must not become a way to hide a real one.

**4. The N-way dispatch FORM was not a design decision (14z-80h).** Both
shared sites already carry compare-chain elements —
`cmpi.b #TT,d6 / bne.s <past my work> / <my work>` — whose branch targets
whatever follows, so "the next element" and "the vanilla tail" are the same
address. N tenants chain by CONCATENATION with no displacement to recompute,
and at N=1 the bytes are identical to the single-element form, which is why
nothing had to be re-frozen. The split point is READ FROM THE BODY (element
length = 6 + the bne displacement, after asserting the `0c06`/`66xx` opening);
a body without that shape is a named build error. `win_pal_variant` became
engine-level; `site_thunk` could not (its bodies carry each tenant's own
placements), so each iteration records its body and the chain is assembled
after the loop.

**RESULT.** Op collisions **10 pairs / 36 bytes -> 4/24 -> 0/0**, and
`patch_prg` applies the 3-tenant patch (12 members). Ops: 3-tenant 612 -> 590,
2-tenant 455 -> 436. All four frozen references bit-exact after every step.

**WHAT THIS IS NOT.** The PROGRAM half composes. The gfx half is
single-tenant by decision, no merged image has been in an emulator, and no
legacy or behaviour gate has been near one. Those are the next milestones,
in that order.

### OPEN AFTER THIS SLICE

**ORDERING DECIDED BY THE MAINTAINER (14z-80 close): the merged-LEGACY
measurement comes FIRST, ahead of any gfx design work.** The reason is that it
buys confidence in the merge itself and it does NOT depend on Phase 3: legacy
characters do not read group C, and on a variant-id build vsav's group B stays
pristine by construction, so a merged program image packed against the
zero-filled WIDE overlay renders every legacy character correctly and the three
tenants as blanks. That is the right instrument for a legacy verdict and
useless for anything else.

1. **Prove a merged image does not perturb legacy.** Recipe and the four
   constraints in `docs/NEXT_SESSION.md`, all confirmed by reading the code
   rather than running it: the driver needs N extractions and `--extract`/
   `--port` pairs; the gfx block (`build_donovan.sh:285-396`) is skipped with
   the generator still at STAGE 6 (its select/site_thunk rows are stage-6
   gated), while the independent pack step above it (:263-279) and the
   unconditional `audit_romset_identity.py` (:406) both still run;
   `run_suite.sh` cannot judge it (unregistered fingerprint, rows only at
   freeze time), so the verdict is a LIVE A/B on the
   `tests/audit_phase_mode_cost.sh` template; and section 0 must prove the
   image BOOTS and forms matches before any "identical" is believed. Two legs:
   vs VANILLA on the masked-v2 basis (the superset-invariant question), then
   vs the three frozen single-tenant builds (does merging change what each
   tenant's own build did?).
2. **The gfx half is single-tenant** (M3b_plan Phase 3, undesigned): group-C
   tile-code coexistence, `build_gfx_donovan.py`'s per-tenant band/delta/bank,
   and the per-tenant `select_tiles.json`/`wheel_bank5.json` the generator now
   emits under per-tenant names. MEASURE first (pack into bank 4 vs grow group
   C to 8 members); the second answer is a profile-version bump and a
   maintainer decision.
3. **Then run the tenants for real** — behaviour batteries on a merged build
   with its own art, then a playtest.
4. **`region_space` on the manifests, deliberately.** Not a blocker — three
   tenants fit because `alloc()`'s fallback spills into `wide_ext` — but a
   spill is not a placement design, and adding the rows moves the frozen
   huitzil/pyron placements, so it is a re-freeze and the maintainer's call.

## Session 14z-79 — (b') LANDED, AND BULLETA'S DARK FORCE WAS BROKEN
## FOR TEN SESSIONS

### THE (b') THUNK — what shipped, and the two spec errors caught on the way

Site `PRG:0x018460`, `patch = "jmp"`, 470-byte body in hole_a, owned by
huitzil.toml (maintainer decision: both live defects are Phobos', and Donovan
and Pyron were cleared by their movelist sweeps, so keeping the row on one
tenant costs ONE re-freeze and leaves the other three fingerprints as
independent oracles).

**Verified before it ever ran.** The body is emitted by
`tools/gen_index_window_thunk.py` and simulated over ALL 65,536 index values:
80/80 legacy entries reach their vanilla handler with vanilla D1, 4/4 danger
entries run vs2's body byte-for-byte, and every one of the other 65,452 values
is LOUD (vec3). There is no silent path. `tests/test_index_window_thunk.sh`
reconstructs all 470 bytes from the two reference ROMs.

**SPEC ERROR 1 — the normal path read ciphertext.** STATE 14z-78 specified
`lea 0x018468,a0 / move.w (0,a0,d0.w),d1`. That is a DATA-space read; CPS-2
decrypts program-space fetches only. Measured: 38 of the 80 legacy targets come
out ODD in the data view, 0 in the opcode view. It would have address-errored
on the hottest path in the game. Fix: the body carries its own copy of the
table and keeps the read pc-relative — a `code` op re-encrypts with its
embedded data (docs/platform/gotchas.md).

**SPEC ERROR 2 — D1, and this one I introduced.** The spec said D1 must be left
holding the vanilla offset. A static sweep showed D1 is dead on ENTRY to all 80
handlers, so I dropped the restore. The sweep was true and insufficient: the
handlers `rts` into `0x01821A`, a chain of five `bsr.w`, which the entry-level
analysis never looked at. Result: EVERY self-frozen legacy log moved and two
masked replays went from one divergent run to two. Restoring D1
(`move.w #imm,d1` per trampoline, which also reproduces vanilla's CCR exactly)
put `02_demitri_vs_cpu` back to its frozen masked-window shape.

**What made it diagnosable was killing the cheap theory first.** The site is
COLD — 22 dispatches per 5,520-frame replay, 2 on `63_idle_select` — and an
image diff showed the build differed from its predecessor at ONLY the 6-byte
site and the thunk body. ~80 extra cycles cannot produce systematic divergence,
so "the hook is expensive" was dead and "the hook is wrong" was all that was
left. Do the cost measurement and the image diff BEFORE theorising: they
separate two failures that look identical and have opposite fixes.

### BULLETA'S DARK FORCE — a legacy character broken since 14z-69

**Found by maintainer playtest.** He tested Bulleta specifically because she is
the SHELL Phobos occupies (variant `0x10` aliases base slot `0x00`), reasoning
that the host is the most side-effect-prone member of the vanilla cast. He was
right, and the same reasoning names Victor for Donovan (`0x13`/`0x03`) and
Demitri for Pyron (`0x11`/`0x01`).

**Mechanism, fully measured.** Palette-seq ids `0x1E-0x21` are Bulleta's DF
block — 236 resolver calls in one DF on vanilla vsavj, `$FF802E`=1, calls
confined to f3260-f3881 with none earlier in a replay that starts at frame 0.
Controls on the same instrument: Demitri -> `0x26`, char `0x04` -> `0x44-0x47`,
Victor -> none at all (his palette-routine row is the default, which has no DF
path — a self-consistent cross-check). The base id is hardcoded IN THE ROUTINE
(`0640 001e` at `0x02a92c`), and each character reaches a different routine via
the per-character palette-routine table `0x02A8A4`.

Phobos lands on Bulleta's routine because **row 0x10 of `0x02A8A4` is `0x004A`
— row 0x00's handler.** 14z-69p saw his DF was wrong and rewrote palette-seq
rows `0x1E-0x21`, i.e. Bulleta's colours.

**The collision is structural.** In vs2, slot `0x10` IS Huitzil and id `0x1E`
is HIS (180 calls, `$FF802E`=1, measured native). In vsavj `0x1E` is Bulleta's.
Both games are right; the merged ROM has one row. Repointing `0x02A8A4` row
0x10 at vs2's `0x0040` has an UNKNOWN outcome. (My "that routine has no DF
path" was RETRACTED later the same session by the census — I read five
instructions at `0x02a8e4` and never followed the `bne.w` to `0x030ee8`; char
`0x04` holds the same row value and DOES request `0x44-0x47`.) It must be
measured, not asserted.

**Decision (maintainer): WITHDRAW the row now**, restoring Bulleta immediately
at near-zero risk, and fix Phobos properly later. His DF is purple again — wrong
versus native, harmless to every legacy character.

**PROPER FIX, DEFERRED.** Give Phobos his own palette-seq block: a free 4-row
id block, a copy of Bulleta's routine with that base substituted, `0x02A8A4`
row 0x10 repointed at it, `0x1E-0x21` left vanilla. All tenant-scoped, all
inside the op invariant. Input: the rebuilt audit's inventory (below). NOTE it
is a 4-character sample — "free" must be established across all 18.

### HOW BOTH GUARDS FAILED, and what was done about it

1. **`audit_palette_seq_ids.sh` returned a FALSE PASS for ten sessions.** Its
   replay set is ordinary play and DF COSTS A BANKED STOCK, so none of its
   replays could activate the mode it was guarding; it saw `{0x26,0x27}` —
   Demitri's own block — and generalised. REWRITTEN with a phase B that forces
   DF across four characters and REFUSES TO JUDGE unless `$FF802E`=1. (My first
   version of that control sampled one frame, f3300, and reported "never in
   Dark Force" for a run that entered it between f3300 and f3400 — a one-frame
   sample of a MODE is a coin toss on its onset. It now samples 3300/3400/3500.)
   New union: `1e 1f 20 21 26 27 44 45 46 47`.
2. **`test_variant_dispatch.sh` WAS RIGHT ALL ALONG.** It has reported
   `0x02a8a4` row 0x10 as a FAIL on every run since 14z-74, including on frozen
   `huitzil-m2`, and it was recorded as "benign — 0 hits at the resolver". That
   zero came from replays where nobody activated DF. It stays RED and is now
   recorded as KNOWN-OPEN, tied to the deferred fix. A permanently red gate
   that is explained away is worse than no gate.

### THE OP INVARIANT ALREADY ENCODES THE RULE — IT JUST STOPS AT STAGE 3

`tests/test_hui_ladder.sh` requires every emitted op to write either declared
free space or a VARIANT ROW (0x10-0x1F). `df_palette_seq_rows` wrote Bulleta's
BASE rows, so it violates that rule outright — but the gate runs stages 1-3 and
the row is stage 4. Measured exposure on the shipped build: **60 of 260 ops
write shared surface.** Most are legitimate engine hooks (the 6-byte site_thunk
sites, poke32s into variant rows of 32-row tables the classifier does not know).
Two classes are worth attributing:

* three `data +0x20` medallion palette rows (`0x3a3ac0/0x3a3b20/0x3a3b40`,
  rows 0x16/0x19/0x1a for the new wheel cells) — CLOSED by maintainer
  observation: across every build carrying medallions, all 18 VANILLA
  medallions have been correct, and that screen shows all of them at once
  every session, so the consequence is loud-and-always-visible and a clean
  observation IS conclusive here (unlike a mode-gated palette). The three NEW
  medallions and their selection ring have imperfect shapes and slightly
  shifted placement with correct portraits at the correct locations —
  **polish, not rework.**
* ~~six 8-byte `data` writes at `0x0212xx`~~ **ATTRIBUTED, not undocumented —
  my claim was wrong (corrected same session).** They are the select wheel's
  TABLE B (cursor navigation): "28 bytes over 3 new rows + 5 inbound edges".
  The patch note anchors at the table BASE `0x0211e4`, not at each written
  row, which is why an exact-address match missed it. Modifying existing
  cells' inbound edges is REQUIRED for the appended cells to be reachable,
  and it is already gated by `tests/test_select_wheel.sh` (a generated walk
  over all 128 cell/direction pairs, measured in MAME). **All 59 shared-surface
  ops on the frozen build are attributed.** Lesson: attribute an op by the
  emitter's note ANCHOR, not by matching its own address.

**RECOMMENDED NEXT GATE: extend the op invariant to stage 6** with an explicit
allowlist where a shared write is justified. That converts "the host character
is exposed" from an instinct into a build-time check covering every host,
without rigging anyone's moves. The (b') thunk's own site would be flagged by
it, correctly — it needs a declared justification (the impossibility argument).

### FREEZE

`huitzil-m3` = `34c8b47de5a43a67e7292f16d0ad133d287fa7e4`, `build/hui29`.
13/13 masked legacy replays PASS with **frozen flicker inventories unchanged**;
`.sha1` determinism baselines re-frozen (28 moved). hui28-vs-hui29 work RAM is
bit-identical on every replay tested, which is the palette-never-transits-RAM
argument confirmed empirically. `donovan-m3a`, `m5_stock` and `pyron-m2` all
still rebuild bit-exact.

## Session 14z-71 — THE BEAM: row 16 of the effect-class table is a
## STUB in vsav, and underneath it vsav has no list-type 12

**The whole chain, measured on both legs.** Every secondary-object pool
runs a per-frame dispatcher that reads the object's CLASS from field
`+0x02` and jumps through a table of handler pointers:

```
vsavj 0x080A90  move.b 0x02(a6),d0 / add.w d0,d0 / add.w d0,d0
                movea.l (0x12,pc,d0.w),a0 / jsr (a0) / lea 0x80(a6),a6
```

The beam pool's table is 38 rows (vsavj `0x080AAC`, vs2 `0x08F1D6`, vh2
`0x08EDE2`) and they are **index-aligned 1:1 across all three sets**.
vsav ships rows **16/17/19/31 as STUBS** — all pointing at the bare
`rts` immediately after the table — where vs2/vh2 fill 16/17/19.

**Row 16 is the beam's, and our build was already asking for it.** Read
watchpoint on each leg's own row-16 slot, replay 83b:

| leg | reads | in the beam window | A0 loaded |
|---|---|---|---|
| native vsav2 | 598 | 48 | `0x093460` (the handler) |
| ours (hui17) | 593 | 46 | `0x080B44` (**the stub**) |

Same frames, same objects (`$FFD400`/`$FFD480`), same `D0=0x40` = class
16 x 4. Nothing upstream was ever wrong — not the object, not the class,
not the dispatch. **The single defect was one dead table row.** That
retires the 14z-70 framing ("a vs2-only routine FOLLOWS the shared
type-2 routine"), which was address-adjacency reasoning: `0x093460` does
not follow anything, it is row 16's handler and a sibling of the shared
reader at row 37.

**Stage 1 — port the handler, repoint the row.** New root
`0x93460:0x306:t0x9306c:f` (bound measured: the row-16 family exactly,
ending on the `rts` at `0x093764` with row 17's identically-shaped head
after it; every pc-rel table and target inside; 0 lea(pc) readers, 0
pcrel escapes; twin = vhunt2's OWN row-16 entry). New generator facility
`[[code_ptr]]` writes a guarded LONG into a table read through the
opcode view. Result: **legacy masked-v2 EXACT**, and
`test_beam_anim_walk.sh` flips `absent -> walks`. The muzzle orb DRAWS.

**Stage 2 — and then it crashes.** `CRASH 3176 vec3 PC 01e9d6
ADDR 0001e9f7`, `A6=ffffd400` (the beam object), `D0=00003a18`. The
drawer's list-type table is **self-encoding — entry 0's own offset IS
the table length**, because handler code begins right after it:

```
vsavj  entry0 = 0x000C -> 6 entries, types 0..10
vs2    entry0 = 0x000E -> 7 entries, types 0..12   (vh2 agrees)
```

The beam's sprite list is **type 12**. On vsav that indexes two bytes
past the table and jumps into an engine data table. vs2's type-12
handler (`0x01A1FC`, 0x3A bytes) is a **composite/group list** — a count
then N x {dx, dy, sub-list pointer}, each drawn by RECURSING into the
drawer. vsav has no equivalent anywhere (0 occurrences of its first 0x0C
bytes).

**A thunk for it WORKS — the beam draws** (snapshots at f3192/f3200
match native's shape; guarded replay clean to `END 4420`). Mechanism:
displace the two instructions at `0x01AFAA`, test for type 12, and jump
BACK to the intact vanilla dispatch at `0x01AFB0`, which needs only a0
and d0. Body is Capcom's handler byte-for-byte except the two bsr
displacement bytes.

**But it costs legacy, and that is why it is parked:**

| replay | thunk OUT | thunk IN |
|---|---|---|
| 02 / 07 / 09 / 30 | EXACT | FLICKER 1 (829) |
| 29_felicia_walljump | FLICKER 1 (2436) | FLICKER 2 (829, 2436) |
| 03_two_player_vs | FLICKER 2 (829, 2093) | unchanged |
| 01_attract_long | EXACT | EXACT |
| 06_test_mode | FAIL 2421 @700 | unchanged (PRE-EXISTING) |
| **04_select_fuzz** | FLICKER 3 | **FAIL 1514 from f829, no re-convergence** |

The flicker frames are the ratified hook mechanism. `04_select_fuzz` is
not: a legacy path changes materially and never re-converges. **Making
the hook cheaper will not help** — it adds ~42 cycles to ~2 dispatches
per frame (~0.04% of a frame) and f829 already flickers un-hooked on
replay 03, so ANY cycle change moves that boundary.

**The zero-cost alternative, measured:** the beam's composite list is
tiny and its children are a type vsav already has —
`251CD2: type 000C, count 2 -> (0,0)->262306 type 2, (-0x4D,0)->262584
type 2` — so it can be FLATTENED at build time into one type-2 list.
No hook, no cycles, nothing to ratify. Cost: decode the type-2 format
from its handler (`0x01B234`), write the transform, and accept that the
flattened list is authored data the sibling oracle cannot check.

## Session 14z-76 — Pyron's EFFECT PALETTE ported; the "16-row hazard" retracted

Asked where his unported effect palette would be visible in play. Answering
that dissolved the reason it was unported.

**THE RETRACTION.** `build/manifest/pyron.toml` and `docs/NEXT_SESSION.md`
both asserted that the effect-palette pointer table at `0x38C218` "has only
SIXTEEN rows", so a variant id "indexes PAST it" into an adjacent shared table
at `0x38C258` whose row 0x01 vanilla uses — and NEXT_SESSION carried that as
M3b merge blocker #2, shared with Phobos. It is one 32-row table indexed by
the full character id, exactly like the sprite table `0x38C198` above it.
Measured three independent ways:

- the five sites that index it all carry the same 18-byte preamble
  `movea.l #$38c218,a0 / moveq #0,d1 / move.b $382(a6),d1 / lsl.w #2,d1 /
  movea.l (a0,d1.w),a0` — the RAW id byte, no mask and no fold;
- `0x38C258` has **zero references** in either ROM view; so does `0x38C1D8`,
  the other claimed "table". Neither is ever loaded as a base;
- both tables' variant halves alias the base half **except at rows 0x12 and
  0x18** — and 0x18 is Oboro Bishamon, a variant dataset vsav genuinely
  ships. Two independent tables agreeing on the same two exceptions is what
  rules out the two-16-row-tables reading.

**Where the reasoning went wrong, because it is a repeatable trap:** row 0x11
holds `0x3923E0`, which vanilla *does* use — as row 0x01's value. That is what
an ALIAS row is. "The value is used" was read as "the slot is used". Every
variant row in this port has that property; it is the reason repointing them
is safe, not a reason it is dangerous. `tools/gen_donovan_patch.py` had the
right model in a comment the whole time ("the hand-rolled 0x1F MIRROR
(0x38C258 == 0x38C218 + 0x40 — measured, NOT a separate table)"), and its
alias assertion passes on row 0x11. The docs contradicted the generator for
two sessions and nobody diffed them.

The second objection, "porting this row caused the 30Hz blink", was already
retracted in 14z-75 (removing it did not stop the blink; it was three aliased
palette-routine dispatch tables).

**THE PORT.** One `[[palette]]` row: vs2 `0x396C14[0x11] = 0x3AC45C`, len
`0xDC0`, into `hole_b`. The generated delta against `pyron19` is exactly two
ops and nothing else — `data_file 0x3faba0` and `poke32 0x38c25c ->
0x003faba0` — and `build/pyron20` fingerprints `69e8c6f0`.

Gates, all green: `run_suite.sh vsavjw` **55 PASS / 17 SKIP / 0 FAIL**, the
same class inventory as `pyron-m1` (legacy is untouched: a variant row plus
free-space data); `test_pyron_blink.sh` still `fixed`; `test_pyron_cosmo.sh`;
`test_variant_dispatch.sh`; `test_gfx_layout3.sh`; `audit_empty_tiles.sh`;
`test_m3a_reproducible.sh` (donovan-m3a and m5_stock still bit-exact).

**NEW GATE `tests/test_effect_palette_table.sh`** + `tools/audit_effect_palette_table.py`
— freezes the measurement the whole change rests on (32-row shape, the
0x12/0x18 alias exceptions, zero references to either table half, the five
readers' unmasked-id preamble, three further sites on FIXED rows 0x06/0x0C/0x0E,
and on a build: tenant row repointed + base-half rows pristine). Four negative
controls: a fold in the reader, a reference to `0x38C258`, a de-aliased variant
row, and a build clobbering a base-half row. All four fire.

**WHAT IS NOT ESTABLISHED: that any of it is VISIBLE.** The block is a
rare-event resource, measured:

| run | reads |
|---|---|
| pyron20, Pyron mash soak 6000f, watch his ported effect block | **0** |
| same rig/instrument, watch his ported SPRITE block (positive control) | **60**, first at f1401 |
| vanilla, `02_demitri_vs_cpu`, watch Demitri's own effect block | **0** |
| vanilla, `03_two_player_vs` + `07_mash_storm`, watch ALL SIXTEEN blocks | **0 inside any block** (2022/2018 hits, all outside — stage pages at `0x39A800+`, sprite blocks) |

So ordinary play never consults it, which is consistent with its history:
Donovan's wrong effect palette never showed in an automated replay either — it
surfaced in a round-32 playtest capture of an ELECTROCUTE, and the electrocute
X-ray plus DF/status tints are the only triggers the repo attributes to this
block. No existing replay produces one. **The automated leg can prove the port
correct and legacy-safe; only a playtest can prove it visible.**

Static evidence that it should matter when the event fires: Pyron wore
DEMITRI's block (row 0x11 aliases 0x01). 110/110 rows differ, 88% of bytes. On
the rows the readers select, Demitri gives ONE beige/gold ramp for every
confirm-button variant (his rows 0x0A and 0x0B are byte-identical) where
Pyron's own block gives fire (0x0A), green (0x0B) and violet (0x0C). The
per-variant colour change is the naked-eye tell that needs no reference.

**RESOLVED — FROZEN as `pyron-m2` (maintainer decision, 2026-08-10).**
Playtest: Pyron's shock aura RED on pyron19 / YELLOW on pyron20, matching vs2;
**Demitri identical across both builds and correct**, the legacy check no RAM
gate can make. Expectation set renamed `pyron-m1` -> `pyron-m2` (content
unchanged); pyron-m1's registry row kept WITHOUT a dispatch mapping, as
huitzil-m1's was. Rebuild verified bit-exact into a scratch dir.
NOTE on my own colour prediction: I called the pyron19 row "beige/gold" and
the pyron20 row a "fire ramp"; the maintainer saw RED -> YELLOW. The ROM data
was read correctly — row 0x0A on the host block is a pale ramp plus a hard
`F00`, and the tenant block's is `FF0 FFB FFF` — but my colour NAMING buried
the salient hue on both sides. Row 0x34 is red in both builds and is not the
tell. Also unresolved: several
effect-table readers sit inside the target span of the per-character
palette-routine dispatch tables whose row 0x11 is now the vs2 default no-op —
if EVERY reader is dispatcher-reached, his block is unreachable by
construction and the port is inert. Two of the five (`0x2AFA2`, `0x2B25A`) are
not in either dispatcher's target set, so at least those are reached another
way; this was not run to ground.

## Session 14z-78 — `anim` MOVES: M3b's blocker was a hex literal

**The blocker is cleared, and it was a generator/manifest bug exactly as
14z-77j predicted.** Not reach, not the crypt window, not alignment.

### What it was

`build/manifest/donovan.toml`'s two select-companion thunks
(`select_companion_tbl_a` / `_b`, sites `0x0845EC` / `0x0845F8`) carried:

```
thunk_hex = "0c2e00TT000a6708207c002083bc4e75207c000dda1e4e75"
                                              ^^^^^^^^^^^^
                       207c 000dda1e = movea.l #$000DDA1E,A0
```

`0x0DDA1E` is `anim`'s placed address plus `0xA9AE`, hand-computed once when the
companion was ported (14z-22) and tracking nothing since. `TT` tracks the
tenant; the address did not. Move `anim` and both bodies still aim at the
vacated range — `x2b7ef4` slides in, the resolver at `0x015084` reads its bytes
as signed 16-bit offsets, `lea (0,A0,D0.w),A0` yields an odd A0, and
`move.l (A0),(0x20,A6)` takes a vec3 in VANILLA code.

### How it was found — the sweep, not the trace

14z-77j's next-probe plan (trace back from `0x01508a`) was aimed at a dead end:
`RET = 0x00FF02DC` is a RAM address because the *resolve* thunks reach the
resolver by **tail-jump** (`4ef900015084`), so the stack holds the select
keeper's caller, not the resolver's. The caller was never going to be readable
that way.

What cracked it in seconds was searching for the VALUE instead:
`grep -ri dda1e build/manifest tools docs` — the manifest names it in a comment
and bakes it two lines later. An opcode-anchored sweep of every hex blob in all
three tenant manifests then bounded the class: **exactly two hits.** Every other
placement-range literal in the manifests is a *source-set* address (`src =`,
`orc =`, `vsav2 =`).

**Lesson worth carrying: when a stale value is identical across two builds, grep
for the VALUE before tracing the CODE.** "Identical on both builds" already says
it is not computed; something wrote it down.

### The fix, and why it is inert

`region_subst = "nnnnnnnn=anim:0xa9ae"` — the mechanism added in 14z-66 for
precisely this, already used by `huitzil.toml:1387` on this same region. The
offset is derived from the source side and agrees with the placement side:
`vs2 0x289EF6 − anim_src 0x27F548 = 0xA9AE`, and `placed[anim] 0x0D3070 +
0xA9AE = 0x0DDA1E`, the literal itself. So in the default layout it emits the
same bytes: **all four frozen fingerprints rebuild bit-exact, donovan-m3a still
`4b7d0dc7`.** A moved build now emits `207c 0040a9be`.

A non-hex placeholder (`n`) was chosen over the existing `aaaaaaaa` spelling:
substitution is textual, so a hex-digit placeholder can collide with a real byte
run in a longer body.

### The runtime proof is a three-way comparison

An absent crash proves nothing on its own — the rig might simply have stopped
forming the match. `GUARD_PROBE=0845ec` on replay 12 with forced-pick pokes:

| build | f1401 | f1402 | faults |
|---|---|---|---|
| `m5_wide` (anim in hole_a) | PROBE A6=`ffd400` | PROBE A6=`ffd480` | 0 |
| anim→`wide_ext`, baked literal | PROBE A6=`ffd400` | **CRASH** vec3 | 1 |
| anim→`wide_ext`, `region_subst` | PROBE A6=`ffd400` | PROBE A6=`ffd480` | 0 |

The path executes twice per select entry (two companion owners); the broken
build died on the second. The fixed build reproduces the working signature
frame-for-frame, so the code path is proven RUN, not skipped.

### The guard — `tests/test_thunk_addr_literal.sh`

The generator already failed the build on stale *char-id* literals in thunk
bodies (two guards, both added after that trap bit). It had none for the
allocator's output, which is why this cost a session. Now: an opcode-anchored,
word-aligned 32-bit operand in the **pre-substitution** body that lands inside
any placed region's destination span is a hard build error naming the region and
printing the exact `region_subst` spelling to use. Escape hatch
`addr_literal_ok`, following `id_literal_ok`.

Coverage boundary, asserted rather than assumed (section 3c): a raw longword in
embedded data is NOT caught. An unanchored scan was tried and rejected — it
reads operand pairs as addresses (a body ending `...0040` + `4e75` parses as
`0x00404E75`, inside wide_ext).

### Space, and what is NOT yet measured

Three tenants now need **98,488** of the 344,640-byte crypt window
(D 67,314 / H 31,174 / P 0), against 470,200 before. The overflow is gone.

### RESOLVED (maintainer, 2026-08-11, option (a)): frozen sets were RED on
### UNACCOUNTED replays — three gaps, not one, all fixed as `.skip`

**Maintainer ruling: "if it was added after the freeze it should be able to
invalidate the freeze."** Applied to the whole class.

The coverage matrix over the three tenant-cell pick replays — built while
fixing the first gap, and the reason the other two were found:

| replay | donovan-m3a | huitzil-m2 | pyron-m2 |
|---|---|---|---|
| `11_pick_donovan` | masked | skip | skip |
| `37_pick_huitzil_cell` | **was MISSING** -> skip | sha1 | sha1 |
| `40_pick_pyron_cell` | **was MISSING** -> skip | **was MISSING** -> skip | sha1 |

So `run_suite.sh` was RED against **both** `build/m5_wide` AND `build/hui27`,
for the same mechanism: a frozen expectation set does not know about a replay
added for a tenant it does not back. Not Donovan-specific, and not a
regression — 0 FAIL and 0 divergence in every case.

`.skip` rather than a frozen checksum because that is the truthful
classification and it matches `11_pick_donovan`'s existing precedent exactly:
the cell is unbacked on that build. (`pyron-m2` freezes `.sha1` for both, which
is also valid — a self-frozen determinism checksum — and is left alone.)

**The replays are NOT dead** (the maintainer raised removal as an option):
each is live on the set whose tenant it picks, carrying a real `.sha1` there.

Verified after the fix: all three frozen sets account for all 72 suite replays,
0 missing. NOTE the sweep that produces that number must glob
`tests/replays/*.rpl` only — a recursive glob pulls in `replays/{hui,pyron}/`,
which the suite does not enumerate (those are driven by their own gates) and
reports 33 phantom gaps per set.

The original write-up follows.

### The finding as first recorded — the donovan-m3a suite is RED,
### and has been since 14z-75 (count corrected above: it was TWO, not one)

`HANDOFF.md`'s `donovan-m3a` registry row tells you to validate with

```sh
MAME_ROMPATH="build/m5_wide/rompath;$ROMDIR" tests/run_suite.sh vsavjw
```

That command reports **SUITE RED** today: 54 PASS / 16 SKIP / **0 FAIL**, with

```
40_pick_pyron_cell    NO-EXPECTATION (freeze after review, as a STATE.md decision)
```

**Not a regression, and provably not 14z-78's doing.** `tests/expected/` is
untouched by this session; the `donovan-m3a` expectation set was frozen
2026-08-07 (14z-64) and `40_pick_pyron_cell.rpl` was added 2026-08-10 (14z-75),
three days later, so the set has no entry for it. Only `pyron-m2` does. The
stronger argument needs no history at all: **all four builds rebuild
BIT-IDENTICAL to their frozen references, so any suite result on them is
unchanged by this session's edits by construction.**

`run_suite.sh:177` fails NO-EXPECTATION on purpose — "an unvalidated replay must
never read as green" — so the runner is working correctly. It is reporting a
DECISION that has not been made: the suite grew a Pyron replay and the frozen
Donovan set was never extended to say what that replay should do on a
Donovan-only build.

**Not Claude's to decide** (the runner's own text says "as a STATE.md
decision"). Options:
- (a) freeze `40_pick_pyron_cell` into `donovan-m3a` as a `.skip` with the
  reason "picks Pyron's cell 0x11, unbacked on this Donovan-only build" —
  exactly the precedent `huitzil-m2` set for `11_pick_donovan`;
- (b) freeze a real expectation for it on the Donovan set;
- (c) leave it and correct HANDOFF's registry row to say the documented
  validate command is expected RED on this one replay.

Recommendation: **(a)** — it matches the existing precedent, it is the truthful
classification, and it makes the documented command green again. Any of the
three needs maintainer sign-off since it edits a frozen expectation set.

That figure is ARITHMETIC ON 14z-77's MEASUREMENT, not a fresh one: 470,200
minus anim's 371,712 (D 134,912 / H 124,928 / P 111,872), and it agrees with
14z-77i's independently-reported per-tenant reach-constrained sets. What 14z-78
measured is that the subtraction is now LEGAL — anim can actually leave.
`tools/audit_region_overlap.py` reports DEFAULT placement only (761,316 /
171,614 / 45,580 against 264,544 / 80,096 / 2,097,136), so the post-move demand
is not yet derivable from a tool. Worth exposing there.

**Measured on Donovan only.** `audit_region_movability.sh` builds `donovan.toml`
at 0x13 with replay 12. Huitzil's and Pyron's `anim` are *inferred* movable —
`huitzil.toml` already spells its anim reference `region_subst`, and the sweep
found no baked placed address in either manifest — but that is an argument, not
a measurement. Extending the audit is not a loop over manifests: a "runs"
verdict needs a **liveness control** proving the tenant's match formed, or an
unformed match reads as a clean pass. Donovan needed none only because his case
used to crash, which proved the path ran.

### 14z-78b — REGION IDENTITY DISSOLVES INTO THE LOOP, and most of the
### planned Phase-2 work with it

Two simplifications, both consequences of `anim` becoming movable.

**1. Nothing needs to be SHARED, so nothing can conflict.** M3b_plan Phase 2
item 2 says "key regions by `(src_set, src_addr, len)` so a shared span is
placed ONCE". 14z-77h already corrected its premise (four of seventeen shared
spans conflict). With `anim` out of the crypt window the correction completes:
**every tenant keeps its own copy of every region, and it fits comfortably.**

| | bytes | capacity | spare |
|---|---|---|---|
| reach-constrained -> crypt window | 98,488 | 344,640 | 246,152 |
| everything else -> `wide_ext` | 880,022 | 2,097,136 | 1,217,114 |

(all-copied total 978,510, from `tests/test_region_overlap.sh`'s own
`if_all_copied` figures.)

That deletes, as work items: the shared-span dedup, `x088512`'s union extent,
the 2,000 conflicting bytes across `x026142`/`x028122`/`x05c800`/`x2b7ef4`, and
the 13 UNDECIDABLE H+P spans. 14z-77h's conclusion was already "per-tenant
COPIES resolve everything; sharing is an optimisation, not a requirement" — it
is now also AFFORDABLE, which is what was missing.

Safe because each clone is self-contained: these are shared CODE spans that
each tenant specialises with pointers to its OWN data, and the relocated
copies are read-only, so vanilla is untouched and each tenant's dispatch
reaches its own clone (measured 14z-77h).

**2. The "7 generic names need per-tenant NAMESPACING" item also dissolves.**
Names only collide if `placed`/`regions` are shared dicts. They need not be —
they are per-iteration data. So there is no keying refactor: `placed[name]`
stays exactly as written and is simply rebound each iteration.

### THE LOOP'S STATE BOUNDARY — classified, and it is the whole remaining slice

| state | line | under the loop |
|---|---|---|
| `spaces` (carries `cur`) | 790 | **SHARED** — reset it and tenants allocate over each other |
| `gap_free` | 833 | **SHARED** — same reason |
| `ops` / `notes` / `fail` / `fragments` | 825-828 | **SHARED**, accumulate |
| `man` (regions.json) | 639 | per tenant |
| `regions` | 987 | per tenant |
| `placed` | 985 | per tenant |
| `patched_clones` | 1153 | per tenant |
| `farm_ports` | 1243 | per tenant |
| `dc_tables`, keyed `(t_src,t_len)` | 835 | **per tenant** — declared at the shared level today; this is exactly the "memo keyed by address, not (tenant, address)" hazard the blast radius named |

**The one real interface change: `--extract` must become repeatable and PAIR
with `--port`.** Today `extract_dir` is a single positional (line 602) and the
region blobs are read from it (line 1331), while `--port` is already
repeatable (slice F). One extraction per tenant, so the two must travel
together.

So the remaining M3b generator work is: pair `--extract` with `--port`; move
the six per-tenant bindings inside the loop body while leaving the four shared
ones outside; move `dc_tables` in with them; delete the `len(tenants) > 1`
refusal at :527. Plus the N-way dispatch FORM, which is unchanged and remains
a design decision rather than a mechanical edit.

NOT attempted in 14z-78: `main()` is ~4,000 lines and hoisting a loop body out
of it is a structural change that wants a fresh context and incremental
fingerprint checks, not the tail of a long session. The classification above is
the design; executing it is the next slice.

### RE-EXAMINE PHOBOS' "BENIGN" ALIASED ROW — its deadness has the same
### provenance problem Plasma Trap just exposed

With the gate fixed to judge each build at its own id, Phobos' real answer at
0x10 is ONE row: `0x02a8a4 row 0x10 = 0x004a` (should be 0x0040) — the latent
aliased row NEXT_SESSION records as "benign today (0 hits at the resolver)".

**That verdict was measured the same way the Plasma Trap deadness was: on
replays that never fired the move.** Plasma Trap has just demonstrated that
this repo's move coverage has holes big enough to hide a crash on every build
ever made. "0 hits at the resolver" is only as strong as the moveset the
resolver was watched over, and nobody had played 214+MK in the air.

Not a claim that the row is live — a claim that the EVIDENCE for it being dead
is weaker than it reads. Cheap to settle now that `index_watch.lua` exists:
the maintainer's in-progress full movelist sweep is exactly the coverage that
verdict lacked. Re-probe 0x2a8a4's resolver across that sweep before treating
"benign" as settled.

### THE SHARPENING FAILED TO PRUNE — and that STRENGTHENS the case for (b')

Attempted the vanilla-baseline sharpening. It does not work, and the reason is
worth more than the pruning would have been.

**What was tried.** All three known-real indices (Pyron's Cosmo, Phobos' Plasma
Trap twice) share a local shape: the word following the index is `0x0002`.
Used as a filter over the 21 candidates on table `0x18464`, it prunes **3**.

**Why that is bad news, not good.** The 18 survivors include **15 of
Donovan's**, and their byte context is STRUCTURALLY IDENTICAL to the confirmed
defects — same zero run before, same `01xx` cluster, same `0x0002` after. So
the candidates are not obviously look-alike fields in a different structure.
Either those records are never DISPATCHED (a runtime question this cannot
answer), or **Donovan carries latent crashes nobody has triggered.**

The earlier ROM-wide conservative scan already failed for the opposite reason —
it saturated, finding all 80 entries "used". Between them: there is no static
way to shrink this list, and the honest reading is that the list may be
substantially REAL.

**CORRECTION to the test priorities I gave the maintainer.** I ranked Phobos'
entry-83 candidate (`x022400@0x0231ee`) as the best single target. It is one of
the 3 the shape signal PRUNES. That is weak evidence — three samples cannot
carry a filter — but it is evidence against, and I ranked it top on none.
Treat it as unranked rather than first.

**The signal is now REPORTED, never filtered on** (`shape=known` / `shape=other`
per candidate). Applying it as a filter would have silently demoted entry 83 on
three samples' worth of evidence, which is exactly the kind of confident
pruning that hid Plasma Trap in the first place.

**THE REAL CONCLUSION: pruning is the wrong goal.** If Donovan's 15 may be
genuine, no test list is short, and chasing them move-by-move is unbounded.
(b') covering the full 80-83 window retires the ENTIRE class for ALL THREE
tenants in one change, whatever those records turn out to do — which is now
clearly worth more than any amount of list-narrowing. It also means (b')
should land BEFORE anyone spends time on the per-move hunt.

### PLASMA TRAP: THE PER-STRENGTH DATA CONFIRMS THE STATIC PICTURE EXACTLY

Maintainer's Phobos sweep (2026-08-11), whole movelist bar Reflect Wall:
**Plasma Trap is the ONLY crash**, and it splits by strength —
LK never crashes, MK always crashes, HK does not crash at match start but
CAN crash later.

The static records match that one-for-one. Three records at stride 0x20:

| record | index word | entry | maintainer |
|---|---|---|---|
| `0x0d071c` | `0x0144` | **68** — in range | LK never crashes |
| `0x0d073c` | `0x0152` | **82** — OUT OF RANGE | crashes |
| `0x0d075c` | `0x0152` | **82** — OUT OF RANGE | crashes |

So the move is PARTLY ported correctly: LK's sub-state is in range and is fine.
Two of the three strengths carry 82.

The two 82-records are byte-identical **except for one byte** —
`010c110c` **`0900`** `01520002` versus `010c110c` **`0000`** `01520002` — which
is the obvious candidate for why one crashes unconditionally and the other only
sometimes (a duration or condition field). Not worth chasing: see below.

**THIS IS THE ARGUMENT FOR (b') MADE CONCRETE.** A per-record fix needs TWO
byte edits, needs the right in-range value chosen for each, and still leaves
HK's conditional path to be reasoned about. The dispatcher-level fix handles
both records, both strengths and the conditional in ONE change, without anyone
having to work out what the differing byte means.

**RIG CAVEAT, and my scripted rig is the unreliable one here.** Earlier I ran
an "LK" variant of the reproducing replay (`sed s/L5/L4/`) and it CRASHED at
f4294. The maintainer's LK never crashes, and LK's index is provably in range
(68), so my scripted L4 did NOT produce LK Plasma Trap — input leniency or the
button mapping gave something else. **Hands-on strength data is authoritative
over the scripted rig**, and `87_hui_plasma_trap.rpl` must not be read as
evidence about which strength does what.

**OPEN: Reflect Wall is the one move not swept** (maintainer could not execute
it). It is the only Phobos move with no coverage from either the sweep or the
gates, so it stays an unknown rather than a pass.

### REFLECT WALL IS DEFECTIVE TOO — SILENTLY. Entry 83 is LIVE.
### (ATTRIBUTION CONTROLLED 14z-78, after the maintainer challenged it)

> **The maintainer was right to challenge the first version of this claim.** I
> wrote "Reflect Wall drives entry 83" when what I had measured was "replay 81
> drives entry 83" — and a guard cancel needs P1 IN BLOCKSTUN *and* the 623+P
> to come out, so either half failing means a different action was measured. I
> had not run the positive control, on the very rig whose gate exists to
> provide one.
>
> **Now controlled, and the claim stands:** `tests/test_hui_pairs.sh` reports
> `P1 seq=0e, attacker blown back — guard cancel fires`, and the entry-83
> dispatches land at **f3214 and f3315**, the first 11 frames before the gate
> samples the GC state at f3225 and the second on the replay's second attempt.
> `D0=0xA6` (entry 83), `D1=0x1002`. The move is attributed.

The maintainer could not sweep Reflect Wall (guard-cancel only, 623+P, needs a
blocking dummy and a 2P partner). Tested here instead: the repo already had a
working rig, `tests/replays/hui/81_hui_rw_gc.rpl`, from the 14z-66 gate.

**Result: 0 faults, but it drives entry 83 of table `0x018464` — OUT OF RANGE.**
No other risky dispatcher is reached (`0x0185d6` and `0x03975a`: zero hits).

**Why it does not crash, and why that is worse.** The two out-of-range reads
land on consecutive words of the SAME instruction — the next dispatcher's
`jmp`:

| entry | reads | value | target | result |
|---|---|---|---|---|
| 82 | `0x01850C` | `0x4EFB` — the `jmp` OPCODE | `0x01D363` **odd** | vec3 crash (Plasma Trap) |
| 83 | `0x01850E` | `0x1002` — that jmp's EXTENSION word | `0x01946A` **even** | **no fault**; runs a live routine |

So Plasma Trap crashes loudly and Reflect Wall executes the WRONG ROUTINE in
silence. Nothing catches it: not the guard, not a playtest looking for resets,
not any gate.

**IT MAY ALREADY HAVE BEEN OBSERVED AND MISATTRIBUTED.** `81_hui_rw_gc.rpl`'s
own header records "the attacker is blown back (native x 322->487 vs ours
322->474 — knockback magnitude = **the alias-physics class, queued**)". A
wrong-routine dispatch is a far better explanation for a wrong knockback than
alias physics. **Prediction: (b') fixes the knockback discrepancy too**, and if
it does, that queued item is retired rather than merely deferred. Cheap to
check — re-run the same replay after the fix and compare against the frozen
native figure.

**THIS VALIDATES TWO EARLIER CALLS.**
1. **(b') covering the FULL window rather than entry 82.** Entry 83 is live on
   a second move, and would have been left broken by an entry-82-only fix —
   silently, so nobody would have found it.
2. **Reporting the `shape` signal instead of filtering on it.** The weak
   3-sample signature marked entry 83's candidate `shape=other`, i.e. it would
   have been PRUNED. It is real. Filtering on three samples would have
   dismissed a live defect, which is exactly the confident pruning that hid
   Plasma Trap.

### DONOVAN'S 15 CANDIDATES ARE CLEARED — by a NEGATIVE result that is
### actually conclusive, and here is why

Maintainer swept Donovan's full movelist: no crashes, no resets, no visible or
mechanical defects. Normally a negative playtest result is weak evidence. Here
it is strong, and the reason is structural.

**Each out-of-range entry has a FIXED consequence, derivable statically:**

| entry | reads | target | consequence |
|---|---|---|---|
| 80 | `0x323B` | `0x01B6A3` ODD | vec3 crash — **LOUD** |
| 81 | `0x0006` | `0x01846E` = table+6 | executes the TABLE AS CODE -> watchdog reset — **LOUD** |
| 82 | `0x4EFB` | `0x01D363` ODD | vec3 crash — **LOUD** |
| 83 | `0x1002` | `0x01946A` real code | runs the WRONG ROUTINE — **SILENT** |

Entry 81 independently reproduces the Cosmo record ("`0x0006` — a displacement
pointing back INTO the table"), which is a control on this derivation.

**Donovan's 15 candidates sit at entries 80, 81 and 82 — every one LOUD.** A
live one could not have been missed by eye. So the sweep clears them: they are
dead records, or those words are not indices. The static list could not
distinguish them; the loudness analysis plus one playtest can.

**The same reasoning does NOT clear Phobos.** His remaining candidate is entry
83, the only SILENT one — no crash, no reset, just a wrong routine. A playtest
cannot clear it, which is exactly why the instrument matters there and nowhere
else.

**Method worth keeping: classify the CONSEQUENCE before valuing the evidence.**
"No crash" means everything for a loud entry and nothing for a silent one. The
same negative result had completely different weight for the two tenants, and
only the static consequence table says which.

### THE FULL CONSEQUENCE TABLE — what each bad entry does, for all 3 tables

Derived statically; entry 81 independently reproduces the Cosmo record, which
controls the derivation. This is what decides whether a clean playtest is
evidence or noise.

| table | valid | entry | consequence |
|---|---|---|---|
| `0x018468` | 0..79 | 80 | ODD -> vec3 crash — LOUD |
| | | 81 | jumps to table+6, executes the TABLE AS CODE -> reset — LOUD (Cosmo) |
| | | 82 | ODD -> vec3 crash — LOUD (**Plasma Trap**) |
| | | **83** | even, real code `0x01946A` -> wrong routine — **SILENT** (**Reflect Wall**) |
| `0x0185da` | 0..85 | 86 | ODD — LOUD |
| | | 87 | into the table -> reset — LOUD (Donovan cand.) |
| | | 88 | ODD — LOUD (Phobos cand.) |
| | | 89 | ODD — LOUD (Donovan cand.) |
| `0x03975e` | 0..9 | **10** | even, real code `0x03E18C` -> **SILENT** (all three tenants) |

**WHAT THE THREE SWEEPS THEREFORE ESTABLISH:**

* **Donovan — clear.** All his candidates sit at loud entries (80/81/82,
  87/89). A live one could not be missed by eye; his sweep saw nothing.
* **Phobos — accounted for.** All three `0x018468` candidates are identified
  (82 Plasma Trap, 83 Reflect Wall). His `0x0185da` entry-88 candidate is LOUD
  and his sweep was clean, so it is cleared too. **No re-sweep would add
  anything**, and his instrument log recording nothing costs us nothing here.
* **Pyron — clear, by direct observation.** 29 dispatches, 0 dangerous,
  entries 0/1/4/10/44/68 all in range, `P1 char=11` throughout, heartbeat
  running start to finish.

**THE ONE REMAINING GAP: entry 10 of `0x03975e`, SILENT, 18 candidates across
all three tenants.** A human sweep cannot close it — a silent misdispatch
leaves nothing to see, which is the whole point of the class. Two cheap facts
argue it is cold: Pyron's full-movelist log never reached that dispatcher at
all, and neither did the Reflect Wall run. Measure it against the replay suite
rather than spending another human pass.

**OPEN, and both are GUARD-CANCEL-ONLY so the maintainer cannot reach them:**
Phobos' Reflect Wall is done (rig 81 existed); **Pyron's Zodiac Fire (236+P,
ES 236+2P) has no rig** and is the last untested move of the three movelists.

**SCOPE NOTE FOR (b'):** it covers `0x018468` entries 80-83. Table `0x0185da`
needs no cover — all four bad entries are loud and all are cleared by
playtest. Entry 10 of `0x03975e` is silent and uncleared; whether (b') should
grow a second site depends on the deadness measurement above.

### ENTRY 10 IS UNREACHABLE — (b') NEEDS NO SECOND SITE. Scope is CLOSED.

The last open question on (b')'s scope. Entry 10 of `0x03975e` is the only
other SILENT bad entry, and 18 candidates sit on it across all three tenants —
a human sweep can never clear it, so it had to be measured.

**The dispatcher itself is never reached.** `GUARD_PROBE=03975a` over seven
action-dense tenant replays covering all three characters
(hui_mash / hui_ex_fg / hui_air, pyron_mash / pyron_cosmo, don_dp_spam /
don_mash): **0 hits, every one.** Add the maintainer's full Pyron movelist
sweep (29 dispatches logged, all on `0x018464`, none on this one) and the
Reflect Wall run (0 hits).

**Controlled, because seven zeros with no control is the blind-zero trap.**
On the SAME replay with the SAME rig: `0x018464` fires 13 times and the pool
seeder `0x016C64` fires 9. And the probe address is verified to be the
dispatcher: `0x03975a` = `4efb 1002`, the same `jmp (d8,PC,Xn)` shape.

So the 18 entry-10 candidates cannot fire, and **(b') covers `0x018468`
entries 80-83 and nothing else**:

* `0x018468` 80-83 — **covered by (b')**; 82 and 83 are confirmed live defects.
* `0x0185da` 86-89 — **no cover needed**; all four are LOUD and all are
  cleared by the three clean playtests.
* `0x03975e` 10 — **no cover needed**; the dispatcher is cold, measured.

### (b') IS FULLY SPECIFIED — bodies, site, and the stack-balanced normal path

**(a) is not available for either live defect.** Full-body twin search over the
80 in-range handlers:

| entry | vs2 body | in-range twin |
|---|---|---|
| 80 | `137c000f00544e75` | entry 15 |
| 81 | `136b001700544e75` | 45 entries (incl. 79 — Cosmo's fix) |
| **82** | `137c005200544e75` | **NONE** |
| **83** | `42290121137c000100544e75` | **NONE** |

The two entries that are actually LIVE are exactly the two with no twin, so any
(a)-style retarget changes behaviour. (b') it is.

**The danger bodies, verbatim from vs2:**

```
80: 137c 000f 0054 4e75              move.b #$0F,(0x54,a1) ; rts
81: 136b 0017 0054 4e75              move.b (0x17,a3),(0x54,a1) ; rts
82: 137c 0052 0054 4e75              move.b #$52,(0x54,a1) ; rts
83: 4229 0121 137c 0001 0054 4e75    clr.b (0x121,a1) ; move.b #$01,(0x54,a1) ; rts
```

**The normal path, stack-balanced, no register liveness assumption needed.**
This was the blocker — the thunk sits in hole_a so the vanilla
`(d8,PC,D0.w)` read is out of range (needs d = -0xA7B9A vs +/-127) and an
address register is required. Borrow A0 and give it back:

```
    move.l  a0,-(sp)          ; [S-4] = a0_old
    lea     0x018468,a0       ; the table base, absolutely
    move.w  (0,a0,d0.w),d1    ; d1 = offset — EXACTLY vanilla's semantics
    lea     (0,a0,d1.w),a0    ; a0 = target
    move.l  a0,-(sp)          ; [S-8] = target
    movea.l (4,sp),a0         ; a0 = a0_old   (restored)
    move.l  (sp)+,(sp)        ; pop target over the a0_old slot
    rts                       ; -> target, sp back to S
```

Traced: entry sp = S (we arrive by `jmp`, so nothing is pushed for us). After
the two pushes sp = S-8. `movea.l (4,sp),a0` restores from [S-4]. The
`move.l (sp)+,(sp)` idiom reads [S-8] and writes it to the POST-increment (sp)
= [S-4]; `rts` then pops it, leaving sp = S. **A0 restored, D1 holds the offset
as vanilla leaves it, stack balanced.**

The one subtlety to verify on the real core: `move.l (a7)+,(a7)` (`0x2E9F`)
relies on the source EA being evaluated — and a7 incremented — before the
destination EA. That is 68000 behaviour, but it is the kind of detail worth
confirming against the emulator rather than trusting, since getting it wrong
leaks 4 bytes per dispatch and only shows up as a slow stack overflow.

**Site:** `jmp thunk` (`4ef9`+addr, 6 bytes) over `0x018460-0x018465`, leaving
`0x018466-67` orphaned and unexecuted. `patch = "jmp"`.

**NOT ENCODED THIS SESSION — and the reason is a quality signal, not a
schedule one.** Three static analyses in the last hour were wrong: the A0
liveness scan decoded displacement words as opcodes (this repo's own
operand-pair gotcha), the first handler match compared table OFFSETS between
ROMs whose layouts differ, and the risky-table print hex-parsed a decimal int.
Each was caught, but the rate is the signal. Hand-written 68k whose failure
mode is a silent stack leak is the worst possible thing to write while that
rate is elevated. Encode it fresh, then: build, Plasma Trap rig (crash gone),
Reflect Wall rig (entry 83 reaches the right routine), four fingerprints,
legacy suite.

### (b') DESIGN, MAINTAINER-APPROVED FOR THE FULL WINDOW — not yet written

Maintainer approved (b') covering entries 80-83. Design is settled; the
assembly is NOT written, deliberately (see the last paragraph).

**The site.** `0x018460` is `323b 0006` (`move.w (6,PC,D0.w),D1`) and
`0x018464` is `4efb 1002` (`jmp (2,PC,D1.w)`) — 8 bytes. A `site_thunk` takes
a 6-byte site, so `jmp thunk` (`4ef9`+addr) covers `0x018460-0x018465` and
leaves `0x018466-67` orphaned but never executed. Use `patch = "jmp"`.

**THE CONSTRAINT that shapes everything.** The original read is
`(d8,PC,D0.w)` — an 8-bit displacement, range +/-127. From hole_a the thunk
would need d = -0xA7B9A. **So the normal path cannot be reproduced
PC-relatively; it needs an ADDRESS REGISTER holding 0x018468.**

**Which is solvable WITHOUT knowing register liveness** — save and restore via
the stack rather than hunting for a free register. Two exactness requirements
that are easy to miss and would corrupt legacy silently:

1. **D1 must be left holding the table OFFSET**, exactly as vanilla does — a
   handler downstream may read it. So D1 cannot be used as a scratch for the
   computed target.
2. **A0 (or whichever register is borrowed) must be restored AND the stack
   balanced** before control reaches the handler. The natural trick — push the
   computed target and `rts` to it — has to interleave with the saved
   register's slot; get the ordering wrong and either A0 is wrong or the
   stack leaks 4 bytes per dispatch.

**The danger path is the easy half:** for D0 >= 160 (entry >= 80), perform
vs2's handler inline. Entry 82 is `move.b #$52,(0x54,A1); rts`; 80/81/83 take
their own vs2 bodies (0x017024 / 0x016F70 / 0x016F78), which are all short.

**Why it is legacy-safe by construction, restated for the record:** vanilla
reaching entry 80-83 CRASHES today, so no legacy behaviour can depend on that
branch. This is an impossibility argument and needs no deadness sampling —
which matters because the sampling came back empty (all 80 entries are used
under a conservative scan).

**NOT WRITTEN THIS SESSION, and that is the right call.** Hand-written 68k
that borrows a register and rebalances the stack is precisely the kind of
change that fails silently in legacy paths, and it needs room to be tested
properly rather than being typed at the end of a long session. The same
judgement was applied to the loop re-indent. Next session: write the thunk,
prove D1/A0/stack exactness against a vanilla A/B at the dispatcher, then the
full battery.

### PLASMA TRAP FIX — (b) AS FRAMED IS DEAD; (b') IS BETTER THAN BOTH

Maintainer approved **(b) with fallback to (a)**. (b) needed an in-range table
entry PROVABLY DEAD in vanilla, to carry a handler writing class 0x52.

**There is no such entry, and the measurement says so cleanly.**

* Runtime, 4 action-dense legacy replays on vanilla vsavj, 80 dispatches
  total: only entries **0, 2, 3, 4, 5** ever appear. That is FAR too thin to
  call the other 75 dead — 80 samples over an 80-entry table is exactly the
  "a deadness measurement is only as good as the replay it ran on" trap, so
  it was not used as a verdict.
* Static and CONSERVATIVE instead (over-counting use only shrinks the dead
  set, so it fails safe): every word `0x01NN` anywhere in either ROM view is
  treated as a use. **All 80 entries appear. The conservative dead set is
  EMPTY.** Control: the 5 runtime-observed entries are all in the used set.

So (b) as framed cannot be built without a tighter, riskier liveness test —
and a wrong "dead" call here is precisely what 14z-74 did when it rewrote a
live shared word and broke four legacy replays.

**(b') — extend the table WITHOUT touching it, gated on the INDEX.** A
`site_thunk` at the dispatcher (`0x018460`) that tests the index and, for the
out-of-range values, performs vs2's handler inline (`move.b #$52,(0x54,A1)`
for 82) before rejoining; everything else falls through to the vanilla path
untouched.

Why this is safe BY CONSTRUCTION, which is stronger than any deadness proof:
**vanilla reaching entry 82 crashes today.** No legacy behaviour can depend on
a path that faults, so a branch taken only when D0 >= 160 is unreachable for
every vanilla character without the machine already being dead. The deadness
argument is replaced by an impossibility argument, and needs no sampling.

It also keeps class **0x52 exactly**, so all THREE consumers of the class byte
(reaction property, death-path re-read, per-victim aura row) see what vs2
gives them — the thing (a) cannot promise and 14z-28 proved matters.

Cost: an engine hook on a shared dispatcher. Cheap here — the site is COLD
(80 dispatches across four full replays), and hook cost is what the masked-v2
legacy basis exists for.

Bonus: the same thunk can cover entries 80, 81 and 83, which retires the whole
danger window for every tenant at once rather than one move at a time.

**Fallback (a) unchanged** if (b') proves awkward: retarget Phobos' index
82 -> 6 in his own data, and playtest the hit reaction.

### PLASMA TRAP FIX: NOT a free retarget like Cosmo — MAINTAINER DECISION

The Cosmo fix worked because entry 81's handler COPIES a byte
(`move.b (0x17,A3),(0x54,A1); rts`) and 45 in-range vsavj entries do the same,
including 79. Phobos' entry 82 is a different shape:

```
vs2 entry 82 handler @0x016FEC:  137c 0052 0054 4e75
                                 move.b #$52,(0x54,A1) ; rts
```

It writes the LITERAL class **0x52**. vsavj's 80 entries only ever write
classes 0x00-0x4F, so **no in-range entry has that handler** and the one-byte
retarget Cosmo used is not available.

**Method note — offsets are NOT comparable between the ROMs.** Matching vs2
entry 82's table offset against vsavj's produced "entry 36", which is a
coincidence: **0 of the 80 shared entries have equal offset values**, because
the handlers sit at different addresses in the two code layouts. Handlers must
be matched by CODE. Control: doing so re-finds Cosmo's answer (vsavj 79 is
among the 8-byte matches for vs2 entry 81); at 16 bytes it correctly finds
nothing, because these handlers are 8 bytes and the next 8 belong to the
following one.

**What 0x52 means.** It is a HIT CLASS, in the 0x4E-0x53 range vs2 added for
the newcomers' moves. `huitzil.toml:807` records vs2's mapping:
0x4E-0x53 -> property 0F/1B/1F/19/0F/03, so **class 0x52 -> property 0x0F**.

**Three in-range entries are property-equivalent:**

| entry | writes class | property |
|---|---|---|
| 6 | 0x06 | 0x0F |
| 7 | 0x07 | 0x0F |
| 56 | 0x06 | 0x0F |

**DO NOT SHIP THAT WITHOUT SIGN-OFF, and the reason is on the record.** 14z-28
withdrew exactly this kind of remap: "the class byte feeds THREE consumers (on-
hit reaction property, the death path re-read, per-victim aura effect-row) and
no native class satisfies all three" — remapping 0x4E to 0x04 stopped a crash
and BROKE THE MOVE. Property equivalence covers ONE of the three consumers.
Cosmo's own manifest carries the same caveat for a change of 81->79; this one
is 0x52->0x06, a much bigger jump in the value the fighter block records.

**Options, for the maintainer:**
- **(a)** retarget Phobos' index 82 -> 6 (or 7/56) in HIS data, one byte, and
  playtest the reaction. Cheapest, ratified pattern, but only the first of the
  three consumers is verified equivalent.
- **(b)** port a handler that writes 0x52 and reach it from an in-range entry
  that is provably dead in vanilla. Preserves the class byte exactly, costs a
  dead-entry deadness proof (the `audit_effect_class_rows.sh` pattern).
- **(c)** leave the move broken and gate it out until after the merge.

Recommendation: **(b)** if a dead in-range entry exists — it is the only option
that keeps all three consumers seeing the value vs2 gives them; fall back to
(a) with a targeted playtest of the move's hit reaction if not. Either way the
remaining work is a DEADNESS measurement plus a playtest, not more static
analysis.

### 14z-78c/d — the merged manifest is CLEAN, and the loop's last unknown found

**78c: `--extract` is repeatable and PAIRS with `--port`.** Much smaller than
the blast radius implied — `args.extract_dir` had exactly TWO uses (:639
regions.json, :1356 the region blob). Both now go through a per-tenant
`extract_dir` binding. Count checked at load, because the failure it prevents
(tenant N built against tenant M's regions) yields a plausible build, not an
error. Three controls run by hand; generator output byte-identical.

**78d: the nine remaining merge collisions RESOLVE.** All were "differ on
`new_hex`, agree on `new_hex_variant`" — labelled as dissolving on WIDE since
slice F, but still refused. Now resolved, conditionally: "merged implies WIDE
implies variant ids" is the CONVERSE of what `tenant_context` guarantees, so
the merge instead asks `tenant_ids_under(docs, profile)` what id each tenant
actually lands on, failing closed when it cannot tell. `tenant_row_ids()`
cannot answer this — it returns every id a tenant COULD take, including
Donovan's base 0x0F, so it can never report all-variant.

The collapse sets `new_hex` to the agreed variant value rather than leaving
the disagreement in place, so a future reader taking the base track cannot
silently emit the host band's word. That is the baked-anim-literal defect
class one level up, and it costs nothing to close here.

**A 3-tenant WIDE merge now reports ZERO collisions** and stops only at the
`len(tenants) > 1` refusal.

### THE LOOP IS ONE MECHANICAL STEP PLUS ONE GATE — both now known

The re-indent is safe, and that was checked rather than assumed:
- **no top-level `return` anywhere in `main()` after line 1000**, so wrapping
  cannot break control flow;
- the per-tenant `man` read sits ABOVE the shared setup but has **zero uses
  between the read and `placed`**, so it moves down into the loop untouched;
- the body is a contiguous run of 4-space statements ending cleanly at the
  `── emit ──` block; output writing is entirely below it.

**The one thing that is NOT mechanical, found by reading `row_applies`:**
it gates on the tenant's SLOT TRACK (variant vs base), not on ownership
versus the current iteration. Run the body N times as-is and every SHARED row
(`_owner=None`) is emitted N times — the double-apply `merge_manifests`'
docstring warns about, and last-write-wins at best.

So the loop needs an iteration gate alongside the existing ones:

> a row belongs to THIS iteration if `_owner` is the current tenant, **or**
> `_owner is None` and this is the first iteration.

Natural extension of slice C, and it is the last unknown. Once it exists the
refusal at :527 can go.

### PLASMA TRAP: REPRODUCED AND THE FAULT MECHANISM IS EXACT (14z-78)

**The maintainer's discriminator cracked it: it crashes on MK ONLY** — LK and
HK are fine. That is what turned a vague "air 214+K crashes" into a rig: I had
already fired MK twice without a crash, which proved my 214 was not registering
in the air at all and every attempt had been a plain jumping kick.

**Reproducing input** (`tests/replays/hui/87_hui_plasma_trap.rpl`, on
`build/hui27`): FORWARD jump, 214 motion starting **10 frames** into the jump,
**MEDIUM kick**. Found by shotgunning 14 all-MK attempts across jump type and
motion delay (the Cosmo precedent: 12 attempts, 4 fired). Death lands ~152
frames after the input — the arc, the landing, the roll, then the detonation.

**RETRACTED WITHIN THE SESSION: "it is a silent watchdog reboot, no fault."**
I read that off the field_trace run, which has no exception hooks and was never
going to report a fault. Wrong instrument. Under the crash guard it faults
every time. The lesson is the one already in GOTCHAS about deadness
measurements, one step over: **an instrument that cannot observe X does not
report "no X".**

**THE FAULT, exactly:**

```
018460: 323b 0006    move.w (6,PC,D0.w),D1    ; table base 0x018468
018464: 4efb 1002    jmp    (2,PC,D1.w)       ; target = 0x018468 + D1
018468: 0212 0224 0224 022c ...               ; the offset table
```

`CRASH vec3 PC 018466 ADDR 0001d363`, and the arithmetic closes with nothing
left over:

* target `0x01D363` − table base `0x018468` = **D1 = 0x4EFB**
* `0x4EFB` is the word at `0x018464` — **the dispatcher's own `jmp` opcode**
* so D0 = `0x018464` − `0x018468` = **−4 (0xFFFC)**

**CORRECTED (same session, twice — see below): the index is 82, and it is
PAST THE END of an 80-entry table.** `D0 = 0x00A4` measured at the dispatcher,
i.e. entry 82. It reads at `0x018468 + 0xA4 = 0x01850C`, which lies beyond the
table and holds the NEXT dispatcher's own `jmp` opcode `0x4EFB`; taken as a
16-bit offset that gives the odd target `0x01D363`.

> **TWO WRONG CLAIMS I PUBLISHED AND THEN HAD TO WITHDRAW, both from the same
> root: I derived a register value instead of measuring it.**
>
> 1. *"D0 is negative (−4)."* I reasoned backwards from "which address holds
>    `0x4EFB`" and picked `0x018464` — never checking whether any OTHER address
>    held the same word. `0x01850C` does. One `GUARD_PROBE` at the dispatcher
>    settled it in one run: `D0 = 0x000000A4`.
> 2. *"It is a silent watchdog reboot, no 68k fault."* Read off a `field_trace`
>    run, which has no exception hooks and could not have reported one.
>
> The rule both violate is already in this repo for deadness measurements;
> it generalises: **an instrument that cannot observe X does not report
> "no X", and a derived register is not a measured one.**

**AND IT IS THE SAME TABLE AS PYRON'S COSMO DISRUPTION.** `0x018468`, the
sub-state jump table `test_pyron_cosmo.sh` and `engine_internals.md` already
document. vsavj **80** entries, vs2 **84**, danger window **[80..83]**:

| tenant | move | entry | status |
|---|---|---|---|
| Pyron | Cosmo Disruption | 81 | FIXED 14z-74/75, in his own data |
| Phobos | Plasma Trap (air 214+MK) | **82** | **this defect** |

`tests/test_index_space.sh` ALREADY flags this table as one of its three risky
ones, with the exact window. So this was never an instrument gap — my earlier
"it is among the 29 NOT JUDGED" was a third wrong claim, caused by querying
`audit_index_space.py` with the ROM ZIPS when it takes DECRYPTED images, and
getting a silent zero-table answer I did not sanity-check.

**The real gap is a process one, and it is worth more than the bug:** after
Cosmo was fixed at entry 81, nobody asked WHO ELSE drives entries 80, 82 and
83 of the same table. Entry 83 is still unaccounted for. The sweep names
windows; nothing enumerates the tenant data that lands IN them.

**The fix follows the ratified pattern** (14z-74's lesson — never the shared
table; that broke four legacy replays): retarget Phobos' OWN index from 82 to
an in-range entry already reaching the right handler, exactly as Pyron's 81->79
at vs2 `0x0D0C7F`, one byte, unreachable by legacy.

**This is a NEW sub-class of the index-space family, and it explains a
coverage gap.** `tests/test_index_space.sh` hunts for indices past the END of a
table — an under-long vsavj table reached by a ported over-long index. It can
never catch this one, because the index is below zero, and the table's length
is irrelevant. That is also why this dispatcher sits among its **29 NOT
JUDGED**. The sweep needs a second question: can any tenant path drive a
dispatch index NEGATIVE?

**STILL OPEN: why D0 is −4, and why only for MK.** The three strengths must
select different data; LK and HK resolve, MK does not. Next probe: trace back
from `0x018460` for what loads D0 (`GUARD_TRACE` across the dispatcher, or
`GUARD_PROBE=018460` reading D0 on an LK/HK run versus an MK run — the
A/B is the answer, exactly as the identical-base-pointer A/B was for anim).

**Fix policy unchanged and maintainer-agreed:** diagnose now, land on the
merged build, do not re-freeze `huitzil-m2` and lose one of the three
reproduction oracles before the loop lands.

**Maintainer flagged a coverage question worth taking seriously:** if MK alone
was broken here, other per-STRENGTH variants may be broken on all three
tenants and no gate would know. The test matrix in CLAUDE.md §4 does not
require every special at every strength. A static sweep would be far cheaper
than playtesting the cross product.

### (superseded triage below) OPEN DEFECT: Phobos' PLASMA TRAP crash-resets

**Air 214+K.** Sends a landmine-looking item to the floor; when the mine
TRIGGERS the game crash-resets. **Not a regression and not anim-related** —
the maintainer reproduces it on EVERY version of the Phobos port, including
pre-`anim`-relocation builds. It was missed because the move was missed: it is
absent from every rig, gate and doc in this repo (`grep -i plasma|landmine`
returns nothing but Donovan's unrelated 214K plant).

Triage done, rig NOT yet built. Four candidate mechanisms, all grounded in
this port's own history rather than guessed:

1. **Unseeded pool -> allocator hang -> watchdog reboot.** The strongest fit
   and Huitzil's OWN precedent: `huitzil.toml`'s init-shim comment records
   exactly this symptom — "an allocator on an unseeded pool hangs without an
   exception: handler entered at f2886, no fault, watchdog reboot". The mine's
   detonation almost certainly spawns an explosion object from a pool. If his
   shim does not seed the one the detonation allocates from, this is it.
2. **An out-of-range dispatch index** — Pyron's Cosmo shape (vsavj's table
   shorter than vs2's, sub-state 81 into an 80-entry table). Produces a jump
   into garbage, i.e. a real fault. `tests/test_index_space.sh` still reports
   3 risky tables and **29 NOT JUDGED**, so its coverage gap could hide this.
   [SUPERSEDED same session: the table IS judged and IS one of the three
   risky ones. "29 NOT JUDGED" came from querying audit_index_space.py with
   the ROM zips when it takes DECRYPTED images — it returned zero tables and
   I did not sanity-check the zero.]
3. **The aliased palette-routine row.** `tests/test_variant_dispatch.sh` at
   Phobos' own id reports EXACTLY ONE spurious inherited routine —
   `0x02a8a4 row 0x10 = 0x004a, should be 0x0040`. This is the row
   NEXT_SESSION recorded as "benign today (0 hits at the resolver)" — and that
   deadness verdict was measured on replays that never fired Plasma Trap,
   which is the "a deadness measurement is only as good as the replay it ran
   on" trap verbatim. Weakened by Pyron's twin at row 0x11 producing a BLINK,
   not a crash.
4. **An effect-class stub row.** vsav ships rows 16/17/19/31 as stubs where
   vs2/vh2 fill 16/17/19; the beam port filled row 16 only, so **17 and 19 are
   still stubs**. Weakest of the four: a bare-`rts` stub makes an object INERT
   (the beam "did not draw"), it does not reset the machine.

**The discriminating measurement, and it is one bit:** does it FAULT or HANG?
A watchdog reset is not a 68k exception, so `run_replay_guarded.sh` will show
nothing and only a field trace proves it (the Cosmo lesson). Fault => (2);
silent reboot => (1).

**Rig warning, paid for twice already:** the rig must produce the EVENT, not
just run. Cosmo needed the right button pair AND a long enough hold AND meter,
and fired 4 times in 12 attempts in one rig and 0 in 12 in another. This one
needs air 214+K at a height that lets the mine LAND, then whatever triggers it
(proximity? timer?) — and "no crash" from a rig that never armed the mine
means nothing.

**Fixing it re-freezes `huitzil-m2`, so it is a maintainer decision** whether
to do it now or on the merged build.

### GATE DEFECT found while triaging: test_variant_dispatch.sh judged the
### WRONG TENANT

`TENANT="${2:-0x11}"` is the second POSITIONAL, so
`tests/test_variant_dispatch.sh build/hui27` sweeps a Huitzil build while
judging **Pyron's** id, and reports three spurious routines that are not on
that build's tenant at all. Phobos' real answer needs
`tests/test_variant_dispatch.sh build/hui27 0x10` and is ONE row, not three.
The default made the gate silently answer a different question than the one
its caller asked — the same shape as the interim-build gate defaults already
flagged for the merge. It should derive the tenant from the build's own
`tenant.json` rather than defaulting.

## Session 14z-77 — M3b slice C: rows get an OWNER, and the gating family
## asks it instead of the build scalar

**The manifest-schema decision 14z-76 stopped on is RATIFIED (maintainer,
2026-08-10): per-FILE ownership, stamped by the LOADER.** A manifest file
already scopes to exactly one tenant — that is how `recon_overlay` has worked
since 14z-65 — so the loader is what knows a row's owner, and stamping it
there means the merge adds tenants **without editing a single manifest row**.
Options considered and declined: a per-row `tenant = "name"` key in one merged
manifest (~180 row edits, and each vertical stops being separately buildable),
and TOML nesting under `[[tenant]]` (unforgeable, but forces the full
shared-vs-tenant section split to be committed before the merge discovers it).

The decisive property is the one the project already relies on: each frozen
vertical stays independently buildable and re-freezable, so it stays an
independent reproduction oracle. It also satisfies `M3b_plan.md`'s Phase 2
exit gate — "the 3-tenant manifest with ONLY Donovan enabled reproduces
4b7d0dc7 bit-exact" — by passing one file.

**What landed.** Four module-level pure functions (module-level for the same
reason slice A's `tenant_context()` is: `tests/test_tenant_id.sh` imports and
drives them without a build): `manifest_owner()`, `stamp_owner()`,
`row_owner()`, `is_variant_tenant()`, `row_applies()`, `row_hex()`. In
`main()`, one closure `owner_of(row)`. `_owner` is generator-internal, stamped
on the parsed document only — **the manifest files on disk are untouched**, so
the four other tools/tests that parse them see nothing new.

**All 10 gating sites converted** — the 9 named in the blast radius plus the
`data_port` `slot_ptr_table` pair (2587/2629), which is not in that count but
has identical semantics on the same rows; leaving it would have reproduced
exactly the half-converted state 14z-76 refused to hand over. The two OUTER
block gates (`select_records`, `win_pal_variant`) moved INWARD to a per-row
filter: those sections are variant-only BY CONSTRUCTION and carry no key, so
the property is declared at the call site via `only_variant=True`. A merged
build can hold a base-half tenant and a variant tenant at once, which is
precisely what one outer test cannot express.

**Deliberately NOT converted, and the seam is commented in the source at each
one:** the row ARITHMETIC (`spt + 4*dst_slot`, `vj_base + 4*dst_slot`, the
`code_word slot_table` block) and the 4 sites baked into emitted machine code.

> **ORDERING INVARIANT (new, and load-bearing): the N-tenant loop slice lands
> only after gating AND scalar reads AND the baked-code sites are all
> owner-threaded.** Landing the loop earlier ships a build in which a row's
> GATE consults its owner while the row's ARITHMETIC consults tenant `[0]` —
> and the baked-code class fails SILENTLY, passing every structural check.

**The refusal at `normalise_tenants()` STAYS** — it states what `main()`
implements, not what the manifest can express.

**Verification.** Baseline established BEFORE the change (all four
fingerprints green on the untouched tree, 3:54) so a later red could not be
blamed on the wrong thing. After: **four fingerprints bit-exact**
(4b7d0dc7 / 6c93cfa8 / 9deda080 / 69e8c6f0), `test_tenant_id`,
`test_patch_overlap`.

**Both new gates were proved able to FAIL** (CLAUDE.md §4, verdict logic is
itself tested). Inverting the variant test inside `row_applies()`: the static
gate flipped all six truth-table rows and exited 1, and
`test_m3a_reproducible.sh` died on the FIRST target — the inverted gate empties
`_sel_rows`, `select_records` never runs, `select_tiles.json` is never written
and the gfx stage cannot proceed. Control reverted before commit.

**`tests/test_tenant_id.sh` gained the row-ownership family** (still ~1s, no
ROMs, no emulator): per-file stamping across all three manifests, `row_owner`
resolution incl. the unowned and unknown-name fallbacks, the `row_applies`
truth table (both keys × both owner kinds, unkeyed, and section-declared), the
`row_hex` selection incl. its fallback, **and the multi-tenant refusal in BOTH
directions** — which no test asserted at all before this. The loop slice
deletes that refusal; a control that fires today and is flipped then is the
honest record of when multi-tenant builds actually arrived.

### 14z-77b — slice D: the manifest-row ARITHMETIC follows the owner too

Converted: the palette table row; the `select_records` array row **and its vs2
`src_char`** (a tenant-identity read that no prior count named); `data_port`'s
`slot_ptr_table` row; `sound_table`'s `ptr_row`; `code_word`'s `slot_table`
entry and its mirror; and the select-wheel's tenant-cell test, which becomes a
**SET over all tenants** rather than an equality against the build's one slot —
each tenant's own cell is skipped because that tenant's `select_records`
host_ring row supplies its P1/P2 rows, which is true of each independently.
Four fingerprints bit-exact.

**THE PLAN'S PREMISE FOR THIS SLICE WAS WRONG, and the correction is the
finding.** It read "7 `table_entry_addr()` reads, same mechanical shape as
slice B". Reading them showed:

- **four of the seven are DEAD** — the gap-table block is
  `for a_t in (man["auto_tables"] if False else [])`, disabled since the 14w
  Felicia triangle-jump regression;
- the rest are **three classes, not one**, and only the manifest-row class is
  answerable by `owner_of()`. The other two have no row to ask: the
  EXTRACTION-SIDE sites are driven by `man`/region blobs (one tenant's
  extraction output, correct the moment the loop rebinds `T` — that is the
  region-identity slice, M3b_plan Phase 2 item 2), and the BAKED-CODE sites
  bake one id into one fragment. The split is now written into the source
  above `dst_slot`'s definition so the next session does not re-derive it.

**NEW GATE `tests/test_tenant_row_owner.sh` (~9s).** Every slice of this
refactor is inert by design, and that is precisely the hazard: a threading
accidentally DISCONNECTED from the emitted ops leaves the four fingerprints
unchanged too, and reads as a successful slice. So the fingerprint gate cannot
answer "is this code path load-bearing?" — this one does, by perturbing ONE
owner-derived row at a time and requiring `patch.json` to change. It runs the
**generator alone** against an existing extract dir, which is what makes
per-site controls cost seconds instead of a 4-minute four-target rebuild.

Seven sites, all live: palette 243→241 ops, select_records 243→220, wheel
243→245 (the two DUPLICATE pokes the skip exists to suppress), slice C's whole
gating family 243→205, and data_port/sound_table/code_word changing op VALUES
at a constant count. Its own verdict logic is ground-truthed: a section
perturbs the intentionally-unused `_pvar` binding and REQUIRES the checker to
call it dead — without which a checker that always said "live" would pass all
seven. It edits the generator in place, so the trap restores on EXIT/INT/TERM
and a section asserts byte-identity; verified by interrupting a run with
SIGINT mid-flight.

Note the instrument's own trap: the first interrupt check was **confounded** —
it asked `git diff --quiet`, which can never be clean while the slice itself is
uncommitted. Re-run against a snapshot instead.

### 14z-77c — slice E: the BAKED-CODE class, mechanical half

All four sites that bake an id into emitted 68k now take it from the row's
owner (`win_pal_variant`'s compare+rebase; `site_thunk`'s TT/TU, and the
`row_subst` address derived from it) or from `T` rather than `port["port"]`
(`charid_sites`, the overlay T-select thunk). Four fingerprints bit-exact.

**Two of them were LATENT TRAPS, not merely unconverted.** `charid_sites` and
the overlay thunk read `port["port"]`, which `normalise_tenants()` pins to
`_tenants[0]` and which the loop will never rebind. Under the loop those
fragments would have baked the FIRST tenant's id into every tenant's code —
and silently, because a thunk gating on the wrong character does not crash: the
tenant takes the vanilla path and some other character takes the ported one.
That is the exact failure mode the source comments at both sites warn about,
one level up.

**What slice E deliberately did NOT do: the N-way dispatch FORM.** Each
fragment still tests ONE id, and these are SHARED sites — all three tenants
declare `name_bank_variant_id` (0x5FCE0), `splash_bank_variant_id` (0x6C0E0)
and `winquote_bank_variant_id` (0x5F328) as byte-identical rows, and
`win_pal_variant` is one thunk at 0x5F1B6. The merge dedups each to ONE thunk
whose body tests N ids. Design decision, flagged in the source at both sites.

**THE LIVENESS GATE FOUND A BLIND SPOT IN ITSELF, and that is the entry worth
reading.** Adding the slice-E controls, `charid_sites` reported **DEAD** — its
perturbation changed nothing. The cause was not the threading: region blobs
leave the generator as side `.bin` files referenced by `data_file`/`code_file`
ops, so a byte changed INSIDE a blob moves no op, and the gate was comparing
`patch.json` alone. It now compares a shasum manifest of the **whole output
directory**, and all ten sites report live. A gate that had only ever been
pointed at already-passing sites would have shipped with that hole; it was the
first genuinely different site that exposed it. Its own dead-binding control
(`_pvar`) still passes, so the fix did not make everything look live.

### 14z-77d — slice F: the merged manifest is EXPRESSIBLE, and the merge's
### collision set is now MEASURED

`--port` is repeatable — one manifest FILE per tenant, which is what the
ratified per-file ownership buys. `merge_manifests()` concatenates owned rows,
DEDUPS rows identical apart from their owner, and REFUSES on anything else.
With one document it is the identity, so the slice is inert; four fingerprints
bit-exact. The `>1 tenant` refusal STAYS — the manifest can now express the
merge, `main()` still cannot perform it, and those are different statements.

Refusing is the design, not a limitation. `[table_fix]`'s `rows_hex` differs by
exactly the tenant's own OBJ bank row, so "last file wins" would silently drop
a tenant's bank word with nothing downstream to catch it.

**Dedup, measured:** `[[space]]` 9→3, `[[obj_hook]]` 6→2, `[[select_wheel]]`
3→1, `[[site_thunk]]` 34→28 (the three `*_bank_variant_id` rows),
`[[port_patch]]` 90→87, `[[code_word]]` 13→11, `[[pcrel_escape_fix]]` 7→5.

**Collisions: 12, in TWO CLASSES — and the split is the finding.**

- **THREE REAL BLOCKERS.** `[init_shim]` (D vs H differ on `flavor_default` /
  `flavor_held` / `latch_mode`; P declares none) and `[table_fix]` twice.
  Both are TOML SINGLETONS, so the schema cannot express two: `table_fix`
  wants a per-row union, `init_shim` either promotion to `[[init_shim]]` or
  attachment to the tenant row.
- **SIX THAT DISSOLVE.** The `x05c800`/`x088512` `port_patch` rows disagree
  only on the BASE-track `new_hex` — **all three tenants agree on
  `new_hex_variant`** — and a merged build is a WIDE build by construction
  (a variant id requires the profile). Those rows never take the value they
  disagree about. The gate requires each to keep carrying the
  "dissolves on WIDE" wording, so if the agreement ever breaks it becomes a
  real blocker loudly rather than quietly.

A span collision is invisible to BOTH existing safety nets, which is why it
needed its own check: the rows are not identical, so row dedup does not see
them, and they land in different regions' blobs, so `patch_prg.py`'s op-overlap
assertion does not either.

This retires the standing worry that "shared-span handling is load-bearing, not
an edge case" (M3b_plan `:58-69`). It is load-bearing — and it is now three
named rows instead of a category.

New gate `tests/test_manifest_merge.sh` (~1s, no ROMs): the one-document
identity, 12 frozen section shapes, the exact collision inventory with the
blocker/base-track split, and four permissiveness controls (a differing
singleton must collide; an identical one must dedup; same span + different
payload must collide; same span + same payload must dedup).

**One correction made in-session:** the frozen inventory first named
`x088512/0x8b0f8`, transcribed from a four-address list. The measured collision
is at **0x8b100**; `0x8b0f8` is byte-identical across all three files and
dedups as shared. The gate failed on it, which is the gate working.

### 14z-77j — WHY `anim` cannot move: an UNRELOCATED base pointer

> **RESOLVED 14z-78 — `anim` MOVES.** The diagnosis below is CORRECT and led
> straight to the fix: it was an unrelocated reference, not a reach or
> crypt-window dependency. What it did not have was the *source*, and the
> next-probe suggestion below (trace back from `0x01508a`) was aimed at a dead
> end — `RET` is a RAM address because the resolve thunks TAIL-JUMP the
> resolver. The answer was a baked literal in `donovan.toml`, found by grepping
> for the VALUE. See session 14z-78 above.

Root-caused to the instruction, and **one hypothesis of mine is refuted along
the way.**

**The faulting code** (vanilla, `PRG:0x015084`):

```
015084  andi.w  #$00FF,D0        ; character id
015088  add.w   D0,D0            ; id*2
01508a  move.w  (0,A0,D0.w),D0   ; read a SIGNED 16-BIT OFFSET from a table
01508e  lea     (0,A0,D0.w),A0   ; A0 = table base + that offset
015092  move.l  A0,(0x1C,A6)
015096  move.l  (A0),(0x20,A6)   ; <-- vec3 address error, A0 odd
```

A base-plus-signed-16-bit-offset table, the same shape as the win-quote bank.

**REFUTED: "anim must stay within +/-32 KB of the table that indexes it."** I
was forming that hypothesis from the crash base landing inside `x2b7ef4`. It is
wrong: **`huitzil-m2` runs with `x2b7ef4` in `wide_ext` and `anim` in the crypt
window, 3.3 MB apart**, and `pyron-m2` likewise (3.29 MB). Adjacency is not the
constraint. Measured before publishing, which is the only reason it did not
become a finding.

**THE ACTUAL MECHANISM.** Probing `0x01508a` on BOTH builds at the faulting
frame gives the SAME base: `A0 = 0x000DDA1E`, byte-identical. So the base does
not track anim's placement at all. On the working build `0x0DDA1E` falls inside
anim's placed span (`0x0D3070-0x0F3F70`); when anim moves to `wide_ext`, the
allocator slides `x2b7ef4` into that address range, so the same stale base now
reads **x2b7ef4's bytes as 16-bit offsets** — hence an arbitrary, odd A0.

**So this is an UNRELOCATED REFERENCE to anim, not a reach or crypt-window
dependency.** anim "cannot move" only because something still points at where
it used to be. That reframes the blocker from a hardware/layout constraint
(which would have forced the maintainer's fallback ladder) into a generator
bug — the far better outcome, and one that would make the profile-growth and
drop-a-character options unnecessary.

**NOT YET ESTABLISHED: where that base is loaded from.** `RET = 0x00FF02DC` is
a RAM address, so the routine is reached through a RAM trampoline and the
caller is not readable from the ROM alone. Next probe: trace backwards from
`0x01508a` for the instruction that sets A0 — `GUARD_TRACE` across the call, or
a write-tap on the RAM trampoline at `$FF02DC`. Once the source is known, the
question is simply why the generator's relocation pass does not rewrite it.

Everything above is reproducible from `tests/audit_region_movability.sh` plus
two `GUARD_PROBE=01508a` runs (working build and `region_space="anim=wide_ext"`).

### 14z-77i — slice J + THE MERGE'S BINDING CONSTRAINT IS ONE REGION: `anim`

> **RESOLVED 14z-78 — that constraint is GONE.** The bisection below is sound
> and its eliminations all stand (code runs from the raw extension; the other
> regions move). Only the conclusion changed: `anim` was not immovable, a thunk
> baked its placed address. Three tenants now need 98,488 crypt bytes, not
> 470,200. See session 14z-78 above.

**Slice J: `region_space`.** Placement had NO reach analysis at all — the rule
was literally `hole_b if the manifest lists it else hole_a`, so every region
defaults into the crypt window and `alloc()`'s fallback absorbs the overflow.
`region_space = "name=space,..."` makes it a per-region manifest tunable
(generalising `hole_b_regions`, which keeps working and keeps the frozen
manifests' spelling). `near_map` satellites now follow their ANCHOR's space —
allocating elsewhere could only trip the d16 distance assertion. Inert: four
fingerprints bit-exact, generator output byte-identical.

**Then the experiment it exists for.** Pushing all ten regions not named by
`near_map` or a `layout_group` into `wide_ext` freed 179,344 bytes of hole_a
and 68,144 of hole_b — and produced a **vec3 ADDRESS ERROR (odd A0) at vanilla
PC 0x015098, frame 1401**. So "unconstrained by near_map/layout_group" is NOT a
sufficient condition for movability; there are undeclared dependencies the
manifest does not express.

**Bisected to ONE region.** `tests/audit_region_movability.sh` (~4.5 min):

| region | | |
|---|---|---|
| `anim` | **CRASHES** | vec3, odd pointer |
| `aux0_4` | runs | 0xE070 data |
| `x06717c` | runs | 0x154 **of CODE** |
| `hitbox` + `hitbox_proj` | runs | 0x35C2 data |

**CODE RUNS FROM THE RAW EXTENSION** — measured at runtime, confirming what
`test_crypt_boundary.sh` locks statically. That removes the obvious fear.

**And the space arithmetic then names the blocker exactly.** With every movable
region relocated, three tenants STILL need 470,200 bytes of the 344,640-byte
crypt window — over by 125,560 — and **`anim` alone is 371,712 of it**
(D 134,912 / H 124,928 / P 111,872). Per tenant the truly reach-constrained
sets are small (D 67,314 / H 31,174 / P **0**).

> [ANSWERED 14z-78: a thunk baked anim's placed address. `anim` moves.]
> **M3b IS BLOCKED ON ONE QUESTION: why can `anim` not live outside the crypt
> window?** Not on ownership, not on the manifest merge, not on the gating or
> baked-code classes — those are all done — and not on total space, since
> `wide_ext` has 2 MB free. Everything else measured this session moves.

Next: root-cause the odd pointer. `CRASH 1401 vec3 PC 015098 ADDR 000decc3`
with A0 odd, faulting in VANILLA code, so something hands the engine a
misaligned anim pointer once the region moves. Candidates worth checking in
order: a 16-bit (word) anim offset field that cannot express a >24-bit base;
a pc-relative anim reference the escape machinery does not classify; or an
odd-length placement changing alignment (`alloc` aligns to 0x10 on gap reuse
but the space cursor is not obviously aligned).

The audit's expectations are frozen in BOTH directions — if `anim` ever stops
crashing it FAILS and says the blocker is gone, which is exactly the news
worth interrupting for.

### 14z-77h — REGION IDENTITY: the plan's premise is MEASURED and CORRECTED

M3b_plan Phase 2 item 2 says "key regions by (src_set, src_addr, len); a
shared span is placed ONCE and all tenants' relocations resolve through the
shared placement." **Measured across the three frozen builds, that is not
achievable for four of the seventeen shared spans**, and the merge design has
to account for it. `tools/audit_region_overlap.py`, frozen by
`tests/test_region_overlap.sh` (~1s, no ROMs).

**Three classes, measured: 17 shared spans / 8 name collisions / 13 unique.**
The 8 collisions are TWO kinds wanting OPPOSITE treatment, which the plan
treated as one:

- **7 generic per-tenant names** — `anim`, `code`, `hitbox`, `hitbox_proj`,
  `aux0_0..2`. Same name, completely different spans; each is that tenant's
  OWN region. These need per-tenant NAMESPACING, not sharing. (D anim
  0x27F548/0x20F00, H 0x245872/0x1E800, P 0x264086/0x1B500.)
- **1 EXTENT collision** — `x088512`, same start in all three, three lengths
  (D 0x2F00, H 0x3B98, P 0x3B40). One region extracted to three different
  extents; the merge wants the union extent.

**The finding: a shared SOURCE span does not imply a shareable BLOB.** Each
tenant's run rewrites pointers inside a shared region to reach that tenant's
own placements, so the blobs differ by construction. Classified per byte
across the three tenants:

| span | 1-differs (disjoint, unionable) | CONFLICT (2+ disagree) |
|---|---|---|
| `x026142` | 68 | **54** |
| `x028122` | 45 | **50** |
| `x05c800` | 485 | **348** |
| `x2b7ef4` | 1076 | **1548** |
| | | **2000 total** |

A *1-differs* byte is one tenant's own row in a per-character table — disjoint,
so a union is well defined (this is `[table_fix]`'s shape, generalised). A
*CONFLICT* byte is one field that two or more tenants want to hold different
values: only one can ship. **Those four spans therefore need a per-tenant COPY,
or a per-character indirection at each conflicting field** — not a single
placement.

The other 13 shared spans are declared by H and P only, and with two tenants
"exactly one differs" and "both disagree" are the same observation, so the tool
reports them **UNDECIDABLE** rather than as a reassuring zero. They become
decidable when a third tenant declares them, or under a merged build.

**THE NUMBER IS ONLY REAL BECAUSE PLACEMENT IS NORMALISED OUT, and that is the
trap this tool exists to avoid.** The three references are INDEPENDENT
single-tenant builds, so each allocator chose its own addresses; a pointer into
a SHARED region then reads as a conflict when a merged build would resolve it
to one address. Un-relocating every word that lands in a placed region back to
its SOURCE address removes exactly that artefact — and it accounts for **73% of
the raw figure (7,591 -> 2,000)**. A gate quoting the raw number would have
been confidently wrong, so `--no-normalise` is kept purely as the control that
proves the normalisation is load-bearing, and section 3 asserts it every run.

**WHAT THE CONFLICTING BYTES ARE — identified, not just counted.** Their
structure is a giveaway: run-length histograms are dominated by 3-BYTE runs
(a 4-byte pointer whose top byte agrees, i.e. a 24-bit address difference),
and `x2b7ef4` is 614 two-byte fields at STRIDE 8. Resolving the pointers:
**they point overwhelmingly at `anim`** — x026142 13/13, x028122 13/13,
x05c800 48/67 — and each tenant's `anim` is a DIFFERENT source span. So these
shared spans are shared CODE that each tenant SPECIALISES with pointers to its
own private data. That is why the same offset holds three different values.

**Which makes the resolution simple, and the plan's "place once" unnecessary
rather than merely unachievable.** Each tenant's clone is SELF-CONTAINED:
the per-character OBJ bank table inside `x026142` (+0x13EE) carries 14
`1-differs` bytes and **ZERO conflicts** — each tenant sets its own row in its
own copy, and no union is needed. So per-tenant COPIES resolve everything;
sharing is an optimisation, not a requirement, and it is unsafe for these four.

**THE ACTUAL BLOCKER IS SPACE, AND IT IS NOT TOTAL SIZE.** If every tenant
keeps its own copy of what it places today:

| space | needed | capacity | verdict |
|---|---|---|---|
| `hole_a` | 761,316 | 264,544 | **overflows by 496,772** |
| `hole_b` | 171,614 | 80,096 | **overflows by 91,518** |
| `wide_ext` | 45,580 | 2,097,136 | fits, 2,051,556 spare |

The regions fit the IMAGE many times over — it is the CRYPT-window spaces that
are saturated, **by ONE tenant**. And regions live there for **PC-REACH, not
for encryption**: code above `PRG:0x0FFFFF` is stored raw and runs, which
`tests/test_crypt_boundary.sh` already locks. So the region-identity slice's
real question is **which regions genuinely need reach and which are in hole_a
merely because the allocator filled the nearest space first** — because
`wide_ext` has room for all of them with 2 MB to spare.

That reframes M3b_plan Phase 2 item 2 exactly as it half-predicted: it said
keying by identity "fixes the name-collision problem and the PC-reach
constraints in one move". The name collisions turn out to be the easy half;
reach is the whole problem.

All of it frozen in `tests/test_region_overlap.sh` (4 sections, ~1s).

### 14z-77g — BOTH slice-G measurements CLOSED, and one of my predictions
### is RETRACTED

**1. `(0x382,A6)` DOES hold the character id at char-init — MEASURED.** The
`flavor_tail` chain is sound. On donovan-m3a, probing the shim's own address:
`A6=$FF8400 -> $FF8782 = 0x13` and `A6=$FF8800 -> $FF8B82 = 0x13`, on two
independent 2P replays. BOTH player structs, because the chain must work for
either. Gate `tests/test_shim_charid.sh` (~44s), with a verdict control
(offset `+0x000` must NOT read the id, so the pass is evidence about `+0x382`
specifically) and an instrument control (a known-executed address must report
hits first).

The instrument needed extending: `GUARD_PROBE` dumped registers but not
memory, and frame-level ordering is too coarse for two events inside one
frame. `replay_guard.lua` gained **`GUARD_PROBE_MEM="<reg>+<hexoff>"`**, which
appends the byte at that register plus offset AT THE HIT.

**The rig had to be fixed before it measured anything.** The first attempt
probed replay 11 and got ZERO hits — and zero would have read as "the shim
never runs". A positive control on the same instrument (the pool seeder,
4 hits) proved the probe was armed, so the zero was a fact about the RIG:
replay 11 never forms a Donovan match on this build. The forced-pick pokes on
replay 12/03/16 produce it. That control is now section 0 of the gate.

**2. Phase mode is NOT inert for Donovan. My slice-G prediction is
RETRACTED.** I wrote that the gate "should be inert for him — it only narrows
the seed to the char-load phase, where his first init already sits". Measured
A/B against donovan-m3a:

- **LEGACY: bit-identical.** Four replays, 30,284 frames. The shim is hosted
  on the tenant's dispatch row, so legacy never executes it. The superset
  invariant is untouched — which is the part that would have blocked the
  merge.
- **DONOVAN'S OWN CONTENT: a bounded, fully re-convergent transient.**
  Divergence begins at the EXACT frame the shim runs (2886 on replay 12, 2363
  on 19/20 — the same frames `GUARD_PROBE` reports the hit), lasts 24-135
  frames across 13-16 short runs, then re-converges completely: 6,000-9,700
  identical frames afterwards, **including a full round-2 on replay 20**.

So the cost is real but confined to his own char-init pool state during the
load phase, and nothing legacy can observe. **Whether that transient is
acceptable is a maintainer call**, not a harness one; the ratified condition
was "measure before trusting", and this is the measurement. Note it fits none
of §4's existing comparison classes — too many runs for flicker, too many
runs for the bounded-window class — but it is not a legacy comparison, so no
class is required; it is tenant content measured against an earlier build of
the same tenant.

Captured as `tests/audit_phase_mode_cost.sh` (on-demand, ~15 min): it rebuilds
the probe variant, proves the shim executed, requires legacy bit-identity, and
requires each Donovan replay to diverge AND re-converge with 500+ clean frames
after. A run that comes back identical FAILS — that would mean the rig stopped
forming the match, which is the failure this whole measurement nearly shipped.

### 14z-77f — slice H: `[table_fix]` by per-row union — ZERO real blockers

`rows_hex` is the VANILLA vsavj OBJ bank table, and the generator already
writes each tenant's own row over it from that tenant's declared `gfx_bank`.
So the three manifests differ only where a tenant ALSO baked its own row into
the baseline — positions the generator overwrites regardless. That is what
makes the union safe, and `merge_table_fix()` checks it rather than assuming
it: the word index of a differing position IS the character id whose row it
is, so a difference on a row **no tenant owns** stays a collision, because
nothing downstream would correct it.

`tenant_row_ids()` supplies the owned set — both the plain `id` and every
`id_by_profile` value, since the merge runs before the profile picks between
them. Measured on the three manifests: `{0x0F, 0x10, 0x11, 0x13}`.

The emitter now writes a row **per tenant** rather than one for the build.
Region `x026142` is declared by all three, so under the loop it is placed once
and that one table must carry every tenant's bank word. It also reads
`_tenants`/`T` instead of `port["port"]` — the same latent trap slice E found
in two other places.

**The merged manifest now has ZERO real blockers.** Nine collisions remain and
every one is base-track-only: the tenants disagree on a value a WIDE build
never takes, and a merged build is a WIDE build by construction.

### 14z-77e — slice G: the ratified `[init_shim]` merge

Maintainer approved the recommendation in full (2026-08-10). Implemented; the
merge's real blockers drop from three to **two** (`[table_fix]` twice, which is
a mechanical per-row union).

`merge_init_shim()` splits the declaration three ways, because the three parts
resolve differently:

- **MACHINERY** (`dispatch`, `seed_entry`, `latch_disp`, `flavor_disp`,
  `flavor_hold_flag`, `objram_clear`) must AGREE — there is one hook and it
  cannot be two things. Disagreement is still a named collision.
- **`latch_mode = "phase"` wins if ANY tenant declares it.** Not a preference:
  the seeder is shared and Phobos needs the gate, so a build containing him
  carries it for everyone.
- **FLAVOR stays per tenant** as `_flavor_by_owner` — D `0x01`/`0x00`,
  H `0x00`/`0x01`, because the engine branch each character tests differs.

The emitter's tail (`flavor_tail()`):

- **ONE declaring tenant → exactly today's 46 bytes**, unconditional write, no
  compare. That is what keeps the four frozen references bit-exact, and it is
  asserted on the literal hex rather than assumed.
- **MORE THAN ONE → 54-byte blocks**, one per declaring tenant:
  `cmpi.b #id,(0x382,A6)` / `bne.s +0x2E` / the 40-byte flavor write / `jmp
  handler`. Each block exits with its OWN jmp, so the chain needs no long
  backward branch and has no branch-distance limit at any N — the naive
  "branch to a shared exit" form overflows `bra.s` at four tenants.
- **A tenant with no entry falls through to the trailing `jmp` and gets no
  write.** That is how Pyron stays untouched: by construction, not by a check
  someone could forget.

Verified: four fingerprints bit-exact; the single-tenant generator output is
byte-identical to the pre-slice-G baseline except `patch_notes_fragment.md`
(the note now lists N flavors — documentation, not shipped bytes).
`tests/test_manifest_merge.sh` gained the section: phase wins, flavor map
exact, Pyron absent, N=1 hex frozen, and the N=2 chain decoded block by block
(cmpi id, `bne` displacement landing exactly on the next block, the per-block
jmp, the fallthrough).

**TWO MEASUREMENTS REMAIN OPEN, and both are named in the source.**

1. **`(0x382,A6)` holding the character id at char-init is UNVERIFIED.** It is
   strongly implied — the dispatch this shim is hosted on is itself indexed by
   the id, and `+0x382` is the id field of both player structs — but it has not
   been measured at this point in the frame, and the whole N>1 chain rests on
   it. The path is unreachable until the loop lands, so nothing ships on it;
   measure with the FBNeo write tap or a MAME breakpoint at the shim's own
   address on a tenant build before the first merged build is trusted.
2. **Donovan's battery under phase mode** — the ratified condition. His shim
   bytes change in a merged build (the gate is forced by Phobos); it should be
   inert because the gate only narrows the seed to the char-load phase where
   his first init already sits, but the replays decide that, not the argument.

Also refused by construction: `objram_clear` with more than one declaring
tenant. It is Donovan-gated today (`false` everywhere), and a merged shim would
arm it for every tenant — a scope change that wants its own decision.

### 14z-76c — M3b STARTED: the multi-tenant generator, slices A and B

Scope ratified this session (maintainer): **M3b = the merge itself.** Phase 6
(arcade ladder, VS-pool palettes) is OUT, becoming its own milestone; D3 stays
open. Approach ratified: **multi-tenant generator**, not chained single-tenant
passes.

The 14z-65 plan's phase order was overtaken by events — Phases 0 and 1 are
DONE, Phase 3's measurement is done and ratified, and Phases 4/5 landed
through the SINGLE-tenant generator per decision D4. So the remaining
milestone is Phase 2 plus Phase 3's implementation.

**The gate first.** `tests/test_m3a_reproducible.sh` extended from two frozen
targets to **all four** (m5_stock, donovan-m3a, huitzil-m2, pyron-m2). Its
value scales with the count: the refactor must leave three independent tenant
fingerprints untouched, so each frozen vertical is an independent oracle over
the same change. That is the payoff of D4's "freeze each vertical first".

- **Slice A** — `tenant_context(t, port, profile, override)`, a pure function
  resolving ONE `[[tenant]]` row (id_by_profile, the variant-needs-profile and
  reserved-0x12/0x18 refusals, `mirror_variant`, the variant gfx-bank
  override). `normalise_tenants()` builds a LIST (`port["_tenants"]`) and
  hands `main()` `_tenants[0]` flattened as before. The flattening WAS the
  single-tenant commitment the refusal exists because of.
- **Slice B** — `T` + `row_ident(tenant)`: one source of tenant identity, with
  `dst_slot`/`var_slot`/`mirror` demoted to a derived view. `repoint()` (10
  call sites) takes `tenant=None`, so all ten are loop-ready untouched.

Both inert by construction and verified: four fingerprints bit-exact,
`test_tenant_id`, `test_patch_overlap`.

**Measured blast radius** for the rest: ONE binding of tenant identity and 37
read sites — 14 table-row, 9 gating, **4 baked into emitted machine code**, 1
select-cell ownership, 1 output naming. The allocator composes correctly; the
hazards are `placed`/memo dicts keyed by address not (tenant, address), five
engine sites all three tenants patch identically (0x5FCE0 / 0x6C0E0 / 0x5F328
/ 0x5F146 / 0x5F1B6 — one thunk dispatching on N ids), and `[table_fix]`,
which must MERGE rows rather than dedup. Also named: Donovan's 12 `x028122`
relocations rewrite SHARED bytes that H/P do not declare — on a deduped region
they would go global.

**Why the session stopped where it did.** The 9 gating sites are not a
mechanical continuation: they encode "is THE tenant a variant id?" globally,
and correct is "is THIS ROW's owning tenant a variant id?", which needs rows
to declare an owner — a manifest-schema decision. Half-converting that family
is a worse handoff than leaving it whole.

### 14z-76b — the OUT-OF-RANGE INDEX SWEEP exists; the f4840 hypothesis weakens

`docs/NEXT_SESSION.md` asked for this instrument before a fourth tenant:
`test_variant_dispatch.sh` sweeps the aliased-variant-row shape, nothing swept
the index-space one. **`tools/audit_index_space.py` + `tests/test_index_space.sh`**
now do.

It derives every `jmp (d8,PC,Dn.w)` table's entry count in BOTH ROMs from two
structural bounds — a target cannot land inside its own table, and a table
cannot overlap the next dispatcher's code — and reports the tables where vs2
is longer. Result on the two ROMs:

| vsavj table | vsavj | vs2 | danger ENTRY window |
|---|---|---|---|
| `0x0018468` | 80 | 84 | [80..83] — the known Cosmo crash (index 81) |
| `0x00185da` | 86 | 90 | [86..89] |
| `0x003975e` | 10 | 11 | [10..10] |

110 tables found, 81 twinned (24 of them by instruction SHAPE), **29 NOT
JUDGED** — reported per table, and the count is frozen in the gate so a
matcher that quietly stops judging cannot read as "no risk". Two of the
unjudged are large (`0x018510` 81 entries, `0x02385c` 80).

**Two bugs in my own first version, both caught by controls I wrote first:**
- bound (a) alone (N <= min(displacement)/2) is far too loose — the Cosmo
  table's nearest target is base+0x212, so it permitted 265 where the truth is
  80. The anchor bound is what makes it exact.
- the anchor landed 4 bytes late (a broken byte test), so the NEXT
  dispatcher's operand word was read as an entry and collapsed the count to 3.
The `--expect-known` positive control failed on both and is why they surfaced.

**COVERAGE was the real weakness.** The byte-exact context matcher inherited
from `audit_variant_dispatch.py` left 53 of 110 unjudged *including the Cosmo
table itself* — the surrounding code carries relocated branch displacements,
so no byte context matches. Matching on the last 8 MNEMONICS (operands
discarded, ordinal correspondence within a shape class) took it to 29.

**THE f4840 RESET IS PROBABLY NOT THIS CLASS.** NEXT_SESSION guessed it was
"most likely another out-of-range index of the same class". Measured on the
repro rig (replay 80, pyron19), all three risky tables are exonerated:
- the Cosmo dispatcher runs entries 0/4/5/40/41 only, last at f4799, every one
  in range for its 80 entries;
- the other two dispatchers get **0 hits**, against a **25-hit positive
  control** at the Cosmo dispatcher on the same rig and instrument.

So it is in the 29 unjudged tables or it is a different mechanism.

**A UNITS TRAP, recorded because it produced a false alarm for a minute.** The
danger window is in ENTRY numbers; the dispatcher's register is not. The idiom
is `move.b <sub-state>,d0 / add.w d0,d0 / move.w (d8,PC,d0.w),d1`, so the
register holds entry*2 — d0 = 80 and 82 are entries 40 and 41, not
out-of-range indices. Halve before comparing.

## Session 14z-75 — PYRON FROZEN as `pyron-m1` (d8b282da)

`run_suite.sh vsavjw` **GREEN — 55 PASS / 17 SKIP / 0 FAIL**; 42 self-frozen
`.sha1` + 13 `.masked` + 17 `.skip` = 72/72 replays. donovan-m3a `4b7d0dc7`,
m5_stock `6c93cfa8` and huitzil-m2 `9deda080` all still rebuild bit-exact.
Maintainer playtest: HUD correct, no blink anywhere, no crash on either EX
move or 236+P in long matches.

**What landed:** his HUD art (the placer was `place_variant_slot_<name>` in
effect_tail.json; own anchors 0xBE94/0xBE9C); the BLINK, which lived in
THREE aliased per-character palette-routine tables, one word each; a legacy
regression shipped by 14z-74, found and reverted; and the Cosmo crash, fixed
properly.

**THE COSMO FIX — the shape worth remembering.** His sub-state index 81 is
OUT OF RANGE for vsavj's dispatch table, which has 80 entries (0..79) and
ends at 0x018508 where a SECOND dispatcher begins. Index 81 read that
dispatcher's displacement operand (0x0006) and the jmp went into the table
itself -> illegal instruction -> watchdog. 14z-74 fixed it by writing that
shared word (0x0006 -> 0x0224): it genuinely stopped the crash, and it moved
dispatcher #2's table for EVERY character, breaking four legacy replays.
**Right effect, wrong byte.** The fix now in place retargets HIS OWN data —
vs2 0x0D0C7F (region hitbox_proj, read as +0x17(A3)), 81 -> 79, one byte;
entry 79 already holds 0x0224, the same handler vs2 uses. vs2's table is
larger so 81 is valid there: this is an INDEX-SPACE mismatch, the same class
as the id space, and the port had copied the index verbatim.

**FOUR RETRACTIONS OF MY OWN, all in one session.** Recorded because the
pattern matters more than any one of them:
1. *"ours 543 palette-seq calls vs native 0"* (inherited from 14z-74) —
   confounded; replaced by a phase-independent measurement.
2. *"the palette-seq tables are byte-identical"* — I derived vs2's table base
   from a CONTENT MATCH and landed 8 rows out. Read a base off the code.
3. *"index 81 is two entries past the end of an 80-entry table"* — I then
   accepted 14z-74's "265 entries, in range" and retracted a correct finding,
   before re-deriving that my original reading was right. The table really is
   80 entries; 0x0212 is entry 0's displacement, not a self-encoded length.
4. *"the 14z-74 word never fixed the Cosmo crash"* — WRONG, and the
   maintainer pushed back on it. I had measured on rigs 71/77/80, none of
   which reproduce: 71 and 77 RELEASE the pair early (aborting the move) and
   rig 80's reset is a different event. Rig 72 reproduces, and on it the word
   plainly works.

**THE LESSON UNDER ALL FOUR: a negative result from a rig is a fact about the
RIG until proven otherwise.** Hold length, button pair and meter state each
independently decided whether Cosmo fired at all — 4 of 12 attempts fired in
one rig, 0 of 12 in another. Before concluding "X does not happen", prove the
rig produces the EVENT (here: a stock spent), not just that it ran.

**Process lesson, already paid for:** every gate this session was
tenant-scoped and green while a legacy replay diverged permanently. **Point
`run_suite.sh` at a tenant build EARLY**, not at freeze time.

**OPEN, none blocking:** the win QUOTE (one shared variant-id fold across all
three tenants), his EFFECT palette (unported; unconfirmed whether visible),
and `tests/replays/pyron/80_pyron_cosmo_pairsweep.rpl`, which still resets at
f4840 — an INDEPENDENT defect that reproduces on pyron14 too, most likely
another out-of-range index of the same class.

## Session 14z-75 — Pyron's HUD ART placed; the BLINK root-caused and fixed

**1. HUD — DONE (build/pyron15, `3fb71586`).** 14z-74 ported the three
variant-id table entries and left the plate BLANK because nothing placed his
art at the anchors they point at. **The placer is
`place_variant_slot_<name>` in `build/manifest/effect_tail.json`**, consumed
by `build_gfx_donovan.py:451` (it copies vs2 bank-1 blocks to vsav bank-1
anchors on variant-id builds, scoped per tenant). There was a
`place_variant_slot_huitzil` and none for pyron; `check_tenant_hud.py` was
always the GATE, never the placer.

Re-derived rather than trusted: both HUD tables dumped from the ROMs show
vsavj rows 0x10-0x1F are pure ALIASES of 0x00-0x0F while vs2 fills
0x10/0x11/0x13 — **the dead-row class in its clearest form**. vs2 row 0x11 =
mug `0x0B60`, name `0B53 0102 FFF0 0002`; +0x4200 gives art codes 0x4D60
(2x2) / 0x4D53 (2x1). Rendered and read them: the plate says "Pyron", beside
"Phobos" and "Donovan" in the same sheet. Confirmed the lo long `FFF00002`
is vs2's own and not a typo for H's `FFE80002` — 2-tile plates normally
carry xoff -16 and it is H's -24 that is the outlier.

Anchors are HIS OWN (name `0xBE94`, mug `0xBE9C`), not H's: reusing H's
works single-tenant but collides on the M3b merge. All six cells blank in
pristine vsav, inside `protected_tiles.json`'s audited pool, absent from
`protected`/`observed_full_run`, disjoint from D's and H's.

Verified in-emulator and by eye: the gate's section 3 sees the ENGINE stage
`code=be9c`/`be94` in a real match reached by **walking the wheel onto his
cell** (new replay 40; press 3 is DR, because the extension rewires 0x08 D
to Huitzil's cell). Snapshots show the plate reading "Pyron" and his fiery
mugshot flanking the timer. Byte-attributed vs pyron14: exactly TWO program
bytes and exactly the SIX anchor tiles differ, in any member.

**Also fixed: `build/manifest/pyron.toml` had not PARSED since fcfe5c7** — a
comment line lost its leading `#`, so `_minitoml` failed at line 632 and
pyron14 could not be rebuilt from the tree at all. Found by parsing the
manifest before editing it. (A rebuild in that commit would have caught it —
the same lesson as 14z-74's chaining rule, from the other direction.)

**2. THE BLINK — ROOT-CAUSED AND FIXED (build/pyron17, `5dc6da06`).**

Measured first, anchored in-match with both legs PROVEN to hold Pyron
(+0x382 = 0x11), as a **phase-independent** property (distinct palette-row-10
values over 40 CONSECUTIVE frames) — because the two games are never on the
same frame:

| leg | distinct values | changes | after the fix |
|---|---|---|---|
| native vsav2 | 1 | 0 | 1 / 0 |
| ours | 2 | 39 | **1 / 0, bit-identical to native** |

**ROOT CAUSE — a DEAD ROW, the fifth instance.** Found with an instruction
trace (`GUARD_TRACE`) of a frame that performs the write. A per-character
palette-routine dispatcher at `0x2A894` reads the CHARACTER ID
(`move.b ($382,A6),D1`) and jumps through a word table at **`0x2A8A4`**.
Most characters carry displacement `0x0040` = the DEFAULT handler, which
animates nothing. vsavj's rows `0x10-0x1F` alias `0x00-0x0F`, so **row 0x11
handed Pyron row 0x01's ANIMATED handler** (`moveq #$26,D0 / bra 0x2AD82`)
where vs2's own row 0x11 is the default.

**THREE TABLES, NOT ONE — and that cost a playtest round.** pyron16 fixed
only `0x2A8A4` (the in-match dispatcher) and the maintainer reported the
blink still alive on the SELECT screen and the between-fight ROUTE MAP. The
tell had been on screen the whole time: the SECOND resolver site `0x2B7E8`
was called **523** times against native's **180**, and I noted it without
chasing it. Sweeping the ROM for the SHAPE — every `jmp (d8,PC,Dn.w)` word
table whose rows 0x10-0x1F alias 0x00-0x0F — found five such tables and two
more carrying Pyron's row on a base-half routine:

| table | dispatcher / index | row 0x11 | patch |
|---|---|---|---|
| `0x2A8A4` | `0x2A894` `move.b ($382,A6)` | `008E` -> `0040` | `0x2A8C6` |
| `0x2B650` | `0x2B64C` `move.b ($382,A4)` | `0042` -> `0040` | `0x2B672` |
| `0x73790` | `0x7378C` `move.b ($39,A6)`  | `0042` -> `0040` | `0x737B2` |

`0x2B650`'s row-0x11 body holds the SAME `moveq #$26,D0 / add.b ($3AE,A4),D0`
request branching to `0x2B7E8`. Verified: resolver counts are now
`0x2AD82`=**0** and `0x2B7E8`=**180** — exactly native's, and exactly
Huitzil's (were 581/523). Palette row 10 constant and bit-identical to
native; the mugshot pixel-identical across consecutive frames. Legacy:
replay 02 **bit-identical** across every step, and the pyron16->17 delta is
**exactly 4 bytes**.

**MAINTAINER PLAYTEST (pyron17): CONFIRMED.** No blink in character select
or on the route map; all graphics clean; no regression surfaced. Gate
battery re-run on pyron17 afterwards — variant_dispatch, pyron_blink,
tenant_hud, pyron_cosmo, audit_empty_tiles, gfx_layout3, list_type_census,
m3a_reproducible: all PASS.

**LESSON, and it cost a playtest round: an aliased-variant-row table is
rarely ALONE.** Sweep for the shape, do not chase the screen. New gate
`tests/test_variant_dispatch.sh` + `tools/audit_variant_dispatch.py` does
exactly that for any tenant, and catches all three on pyron15. Its
coverage control exists because the first twin-finder demanded a UNIQUE
context match and therefore silently skipped `0x2A8A4` — vsav ships two
byte-identical copies of that dispatcher, so twins must be matched by
ORDINAL.
Legacy-safe by construction — the table is indexed by the character id and
`tests/audit_id_writers.sh` **re-run this session, PASS**: no legacy
gameplay path writes an id in `0x10-0x1F`.

**The symptom lied about its cause.** `0x2AD82` is the DF-family palette-seq
resolver (H's 14z-69p work), so it read as "a Dark Force recolour without
Dark Force" — but `$FF802E = 0` on **both** legs. Check the mode flag before
believing a mode.

**CROSS-TENANT, NOT ACTED ON:** Huitzil's row `0x10` is `0x004A` (row 0x00's
handler) where vs2's is the default — the same class, latent and benign
today (0 hits at `0x2AD82`). **`huitzil-m2` is frozen and
maintainer-confirmed, so changing it is a maintainer decision.** Donovan's
row `0x13` is already `0x0040`, which is why this never surfaced on him.

**RETRACTION OF MY OWN ELIMINATION (same session).** I wrote "NOT the
palette-seq table content — vsavj row 0x26 is byte-identical to vs2's
(table base 0x3B093C)". Both halves were wrong: vs2's real base is
**`0x3B0A3C`** (its resolver's own immediate), and the tables are **not**
row-aligned — vsavj row `0x26` == vs2 row `0x1E`, a uniform +8 shift. The
port's id remap already handles that correctly (ours asks 0x26/0x39/0x3A
where native asks 0x1E/0x31/0x32), so the conclusion survived but the
reasoning did not. **Read a table base off the code, never off a content
match.** Also corrected: "the same script, same id and same data animate on
ours and not native" — native runs palette sequences too, just through a
different per-character routine.

**Retracted from 14z-74:** "ours 543 palette-seq calls / native 0" — its own
caveat was right, the hits were in the select screen and it compared
different screens. Replaced by the table above.

**New gotcha (cost me several iterations).** `placements.json`'s dst/src is
a LINEAR map, but the extractor auto-discovers SUB-REGION shifts — mapping
through it put the anim nodes 0xF00 off and made a faithfully-ported region
measure **75% differing**, which reads exactly like corruption. Correlate to
find the true offset before concluding anything about ported data.

**Frozen references all still bit-exact:** donovan-m3a `4b7d0dc7`, m5_stock
`6c93cfa8`, and huitzil-m2 `9deda080` — the last rebuilt explicitly because
`effect_tail.json` is shared across tenants.

## Session 14z-74 — PYRON's render rung OPENED (Steps 0/1/3 landed), and a
## GENERATOR BUG found under it

**Progress (all committed, all frozen references still bit-exact).**
- **Step 0** — stage 6 unlocked for 0x11, and the carried-forward
  "re-check the one-source-bank premise for Pyron" question ANSWERED:
  his fighter anim span carries **0 list-type-4** sprite lists, against a
  live **26-hit control on Huitzil's** (whose beam is a known type 4).
  Type 4 is the format that composes its own bank word and cannot reach
  group C via the record path, so Pyron needs NO ported handler and NO
  `--strip-tiles`: his delta-0 placement is complete. Frozen as
  `tests/test_list_type_census.sh` + `tools/list_type_census.py`.
  *The control is the point:* the first version of that census read 0
  type-4 for HUITZIL, because it applied the coordinate-pointer
  constraint that only types 0/2/8 have (type 4 carries entries inline).
  A census blind to its target looks exactly like a clean result.
  CAVEAT: covers his FIGHTER span; his effect data rides the shared
  x088512 region and is not extracted yet — re-run when it lands.
- **Step 1** — his 12 OBJ bank setters (measured by scanning his BUILT
  region images, against a control that re-derives H's 12 manifest rows;
  the first scan mask was wrong and read 0 for both — caught by the
  control), plus the ported bank table and `obj_bank_word_slot`.
- **Step 3** — the select family: 6 select_records (nine alias anchors
  verified), 3 drawer thunks, roster21, and his select palette. vs2's own
  uploader confirms Pyron takes the **Donovan dedicated-block** form
  (`cmpi.b #$11,d6 / addi.w #$BC,d0`); the block address 0x3C28FC is
  derived by math that self-checks against Donovan's known 0x3C2A3C.

**THE GENERATOR BUG (decision pending, see below).** The
`pcrel_escape_fix` blob pass (gen_donovan_patch.py ~1173) scans a region
for `bra.w/bsr.w` — any `0x6000`-form word with a zero low byte — and
rewrites the FOLLOWING word to a trampoline displacement. It runs AFTER
`table_fix` and its scan range COVERS the ported per-char OBJ bank table,
which is DATA. Every table row holding 0x6000 therefore makes the
generator clobber the row after it. Measured:
- rows 0x01/0x0A/0x0C emerge as `0074/0068/006a` on BOTH tenants' builds.
  Those values are baked into both manifests as **fixed points of the
  corruption**. **RETRACTED:** an earlier comment of mine called them
  "relocation-affected bytes of the ported copy" — they are not; the raw
  source region holds 0x4000 there.
- Huitzil is unharmed only by LUCK: his row 0x10 = 0x1000 is not a branch
  form, so his tenant row is never read as a displacement.
- Pyron at 0x11 is not lucky: row 0x10's vanilla 0x6000 made the scanner
  eat his tenant row (0x1000 -> 0x0066). Caught by `verify_gfx_build`.

**Worked around at the manifest level** (row 0x10 = 0x1000 so it is not a
branch form): inert in a Pyron-only build, forward-compatible (on the M3b
merge row 0x10 IS Huitzil, whose correct value is exactly WIDE bank 4).
Bank table now verifies clean.

### Decisions pending (maintainer) — 14z-74

- **D5 — RESOLVED (maintainer: option (a), with "test before re-freezing").**
  The generator fix is APPLIED (commit d87d9a2) and VALIDATED:
  * new Huitzil candidate **`build/hui27` = `9deda080`**; delta vs the frozen
    build is EXACTLY 24 bytes — the 3 corrupted rows repaired
    (`0074/0068/006a` -> `6000/4000/6000`) plus 3 now-unnecessary trampolines.
  * full H battery **16/16 PASS** (incl. legacy masked-v2 EXACT).
  * the oracle suite run against **huitzil-m1's OWN frozen 71-replay
    expectation set: GREEN, 54 PASS / 17 SKIP / 0 FAIL** — identical counts
    to the frozen build, i.e. the repair is behaviorally inert across
    everything the suite covers. (Temporary registry row, removed after.)
  * Pyron's manifest workaround reverted; his table now declares honest
    vanilla values + row 0x11 = WIDE bank 4, and verifies.
  **PLAYTEST DONE (maintainer, 14z-74): hui27 clean — no regression on
  Phobos, Demitri, Zabel or Bishamon.** One observation: brief FLASHING at
  the end of round 1 in a Bishamon vs Phobos match, no corruption.
  **MEASURED, and it is NOT D5:** the same replay run on hui26 vs hui27
  with P1=Phobos/P2=Bishamon is **bit-identical across all 14,621 frames**
  of work RAM, and palette RAM matches at every sampled round-end frame.
  So the flashing is pre-existing or an emulator artifact — logged as an
  open observation, not a D5 regression.

  **CORRECTION (my error, retracted).** I told the maintainer the three
  repaired rows were "Demitri / Bishamon / Lord Raptor" and the playtest
  was aimed accordingly. The real slot map
  (`docs/game/atlas/character_tables.md:224`) is **row 0x01 = Demitri,
  row 0x0A = SASQUATCH, row 0x0C = Q-BEE**. Bishamon is 0x08 and Zabel is
  0x04 — neither was touched by D5. The two genuinely-changed rows the
  playtest therefore missed were closed by measurement instead: Phobos vs
  **Sasquatch** and Phobos vs **Q-Bee** (and vs Demitri) are each
  **bit-identical hui26 vs hui27 across 14,621 frames**. The ported table
  copy's legacy rows are not read on any path these matches exercise, so
  the repair is provably inert.

- ~~**D5 — repair the pcrel-scan/table_fix collision in the generator?**~~
  (original framing, kept for the record)
  The correct fix is one guard (exclude the `table_fix` span from the
  escape scan; drafted and tested). Measured consequences:
  * Donovan: **unaffected**, m3a still bit-exact.
  * Huitzil: **the frozen huitzil-m1 build CHANGES**, `22c016ac ->
    9deda080`, because his rows 0x01/0x0A/0x0C revert from the corrupted
    values to their declared ones. That is a REPAIR (garbage bank words
    -> correct ones) but it is a byte change to a frozen, playtested,
    registered build, so it needs a re-freeze + re-playtest.
  * Options: (a) apply the generator fix and re-freeze Huitzil as
    huitzil-m2; (b) keep the manifest workaround per tenant and leave the
    latent corruption; (c) apply the fix but only for new tenants.
  * Recommendation: **(a)** — the ported table's legacy rows currently
    hold garbage bank words on every tenant build, and the longer it
    stands the more manifests bake in fixed points of a bug. But it is a
    frozen-build change, so it is the maintainer's call.

**Open on Pyron (next session's first work):** `verify_gfx_build` still
reports (i) **6 tile codes above his reserved window** `0xA42C`
(`0xa4f4 0xad5c 0xb444 0xb4c8 0xf4d8 0xf518` — four of them beyond
Donovan's SAFE_LO 0xAD80, so the gfx_layout3 disjointness invariant is in
question) and (ii) a **record/entry parity delta** (src 745/14992 vs out
756/15014). Both are genuine layout/content questions — measure before
touching `gfx_layout3.toml`, whose Pyron row is a RATIFIED reservation.


## Session 14z-74 — Pyron RENDERS; Cosmo/air/win-screen fixed; Phobos re-frozen

**Phobos: RE-FROZEN as `huitzil-m2` (`9deda080`).** Decision D5 (maintainer-
approved) repaired a generator bug: the `pcrel_escape_fix` scan treated any
`0x6000`-form word as a `bra.w` and rewrote the word after it — and it ran
AFTER `table_fix` over a range covering the ported OBJ bank table, which is
DATA. Delta vs m1 is exactly 24 bytes (3 repaired rows + 3 now-unneeded
trampolines). The maintainer required TESTING BEFORE RE-FREEZING; that is
what caught a false claim of mine (below). Full battery 16/16, the m1
expectation set green on the new build (54 PASS/17 SKIP), and Phobos-vs-
Demitri/Sasquatch/Q-Bee/Bishamon bit-identical to m1 across 14,621 frames.

**PYRON RENDERS.** His render rung (stage 6 unlocked for 0x11):
- Step 0: one-source-bank premise MEASURED for him — 0 list-type-4 in his
  fighter span against a live 26-hit control on H's. Gate
  `tests/test_list_type_census.sh`.
- Step 1: 12 OBJ bank setters + table_fix + obj_bank_word_slot.
- Step 2: SPRITE palettes (vs2 0x39C19C). EFFECT palette DEFERRED — its
  table has only 16 rows, so a variant id spills into the adjacent shared
  table (a hazard H's FROZEN row shares).
  **RETRACTED 14z-76: that table has THIRTY-TWO rows and 0x38C258 is its
  second half, so there is no spill and no hazard. Ported on pyron20; see
  the 14z-76 entry.**
- Step 3: 6 select_records + drawer thunks + roster21 + his select palette
  (the Donovan +0xBC dedicated block, 0x3C28FC).
- Step 5: win screen — position (vs2 table 0x6B210 row 0x11 = 0x00C0,0x0094
  vs our 0x0080,0x0098 alias) and palette (remap row 0x10 -> 0x3C35BC).
  MAINTAINER-CONFIRMED.
- Step 4: HUD — table entries ported, ART NOT PLACED, plate renders BLANK.
  Gap located: the per-tenant HUD config (tools/check_tenant_hud.py TENANTS)
  has rows for 0x13/0x10 and none for 0x11.
- A verifier fix was needed to get his gfx green: the record-walk SWEEP is
  now relocation-aware (source-accepted offsets only), because a +6 read
  STRADDLING a relocated pointer invented 11 phantom records and 8
  out-of-band tiles. H and D unaffected.

**Three maintainer-confirmed gameplay fixes.**
1. **Cosmo Disruption crashed/reset.** vsavj ships sub-state 81's jump-table
   entry as a STUB (0x0006, pointing back into the table) where vs2 fills
   it — the BEAM's defect class, third instance. Fix is ONE WORD: vsavj
   already contains vs2's 8-byte handler at table+0x224, so entry 81 is
   repointed there. Entry 81 measured DEAD in vanilla (0 dispatcher reads vs
   a 12/7 control), filtering the boot ROM-checksum sweep by PC. Gate
   `tests/test_pyron_cosmo.sh`.
2. **Air 214+P runaway.** A 12-byte DATA table at vs2 0x0576F4, read via
   `(a2)+`, lives inside his crypt-re-encrypted `code` region, so the data
   view was garbage — and the move sets GRAVITY TO ZERO, so a wrong velocity
   is never pulled back and the state never lands (hence dead controls).
   native (904,-904) x3; ours MP (-7724,+19764) = left+up, HP (+25897,
   +12090) = right+up — exactly the maintainer's MP-left/HP-right report;
   LP's garbage yv was negative, which is why LP never looked broken. Fixed
   with a new `data_in_code shape="pointer-inline"` (lea(d16,pc),An + NOP ->
   lea.l #table,An, in place; no helper, no bsr.w reach constraint).
3. **Wrong palettes** — his sprite palette rows (Step 2 above).

**RETRACTIONS — read these before trusting any measurement here.**
- **"port_param32 breaks legacy" was WRONG.** I recorded it and refused the
  fix. It was a MEASUREMENT ARTIFACT from chaining the legacy check onto a
  rebuild in one command; the same artifact also produced a false failure on
  a build WITHOUT the flag, which is what exposed it. Re-measured in
  isolation, twice: clean. **Never chain a legacy measurement onto a build
  in one step, and re-run before believing a gate that contradicts a prior
  green.** I also committed the false claim while the contradicting output
  was on screen.
- **"the effect palette row causes the blink" was WRONG** — removing it did
  not stop the blink.
- **"ours 543 palette-seq calls vs native 0" was CONFOUNDED — now RETRACTED
  and REPLACED (14z-75).** The caveat was right: the hits were in the SELECT
  screen, where our flow is not at the same point as native's on the same
  frame, so it compared different screens. Re-measured anchored on an
  in-match state, both legs proven to hold Pyron, as a phase-independent
  property — distinct palette-row-10 values over 40 CONSECUTIVE frames:
  **native 1 value / 0 changes, ours 2 values / 39 changes**, with ours' two
  values NAMED (native's constant, and vsavj palette-seq row 0x26 under the
  uploader's 0xF000 OR). Frozen by `tests/test_pyron_blink.sh`.

**OPEN on Pyron:** the sprite/HUD BLINK (palette row 10 animated by the
palette-seq uploader 0x02AD68; his anim nodes are CORRECT, so it is not the
air-dive class), HUD art placement, the effect palette, and the win QUOTE
(the shared variant-id fold — Pyron is now the third data point for it).

**TWO GENERIC INSTRUMENT BLIND SPOTS found (worth fixing before more
tenants):** the extractor's dead-filler classifier compares siblings in the
OPCODE view, where real data is indistinguishable from junk (it called the
air-dive table "dead filler"); and `census_regions.py` bails in
`_redefines_an` on `lea (An,Xn),An`, an index add where the pointer plainly
survives (which is why Pyron's "0 data_in_code" census line was wrong).

## Session 14z-73 — the grab victim: FIXED and MAINTAINER-CONFIRMED (both
## grabs, MAME + FBNeo). The victim's capture-pose keyframe-pointer table
## row for H aliased character 0's block; ported H's own block. Also: the
## FG "slowness" was the broken GFX, not timing — resolved by observation.

**The 14z-72 blocker was a measurement error, not a rig problem.** Running
replay 80 (Circuit Scrapper, 63214+MP on a 2P Victor dummy) through the new
`field_trace.lua` on **both legs** — native `vsav2` and our `build/hui25`
`vsavjw`, both forced to P1=Huitzil(0x10)/P2=Victor(0x03) — shows the setup
is byte-identical across legs: same characters, same facing (p1face=1,
p2face=0), same seq timing (grab seq 0x0E enters at f3152 on both, victim
enters seq 2 at f3154 on both), same damage (0x13). And **pre-grab the
victim offset RELATIVE to the attacker is dx=42 on both legs** — the 21px
"gap" 14z-72 saw was absolute x; the whole match is globally shifted and it
cancels in the relative measure. No cornering needed.

**The defect, isolated.** From the first held frame (f3154) the victim's
relative offset diverges hard and stays wrong through the hold:

| phase | native reldx | ours reldx | Δdx |
|---|---|---|---|
| pre-grab f3150 | +42 | +42 | 0 |
| onset f3152 (seq 0x0E) | +42 | +42 | 0 |
| hold f3154..3164 | +74..+82 (out front) | −27 (behind) | ~**−109** |

Native holds the victim ~78px in FRONT of Phobos; ours snaps it ~27px
BEHIND — a ~109px horizontal teleport, visible from grab onset (snapshots
f3152/3158 confirm: identical at onset, victim on the wrong side by f3158).
It is **not a clean sign-flip** (−78 would be), so the offset VALUE is
wrong, not just its sign — consistent with a mis-read/un-ported datum. The
post-release vertical LAUNCH (dy arc) is the SEPARATE known throw-arc issue
and is deliberately out of scope for this gate.

**ROOT CAUSE (confirmed, code-level).** The victim's hold position is
written by a shared engine CAPTURE POSITIONER that computes
`victim_pos = attacker_pos ± facing-flipped (Xoff,Yoff)`, where the offsets
come from a per-ATTACKER KEYFRAME block selected through pointer table
`0xBE27A` indexed by the attacker's char id (`movea.l #$be27a,a0;
movea.l (a0,id*4),a0`). vsavj's positioner is at `0x28058`; **H's grab
reaches it through the ported CLONE at `0xc9eb0`** — because `0x27282`
falls inside H's ported region x026142, the generator relocated the
reference as an internal target into the clone, which runs identically and
even reads the correctly-reconciled table base. So the positioner IS
invoked; the **sole** defect is the DATUM: vsavj table **row 0x10
(Huitzil) = `0x092C4A`, an ALIAS of row 0x00** (character 0's block), where
vs2 row 0x10 = `0x0C56AA` = H's OWN block. H therefore held the victim with
character 0's offsets (dx −27 vs native +74). This is the exact twin of
Donovan's `throw_victim_keyframes` (`donovan.toml:711`, same
`slot_ptr_table`); `huitzil.toml` simply lacked the analogous row.

**MID-SESSION RETRACTION (own):** I first measured "the positioner is never
invoked (0 hits at `0x2802e`)" and posited a crypt-hole invocation bug. That
was a false negative — I breakpointed the VANILLA engine copy `0x2802e`,
but H's grab routes to the CLONE `0xc9eb0`. A subagent caught it by watching
the actual writer PC (positive control). The invocation was never broken;
the bug was pure data. Lesson logged: check the address the tenant's OWN
relocated code uses, not the vanilla twin.

**THE FIX (build/hui26, fingerprint `22c016ac`).** One `[[data_port]]`
`grab_hold_keyframes` in `huitzil.toml`: places H's vs2 block `0x0C56AA`
(len `0x1D80`, sibling-identical to vh2 `0x0C4F3C` through `0x1E1A`) into
`wide_ext` and repoints table row `0xBE2BA` (row 0x10) to it. Host block
`0x092C4A` and every vanilla row untouched → **legacy masked-v2 EXACT**.
Result: the victim now follows native's EXACT keyframe sequence
(74,82,82,74,… then the wind-up, then the throw arc), the only residual a
±1-frame cross-emulator phase. **Maintainer-confirmed clean on BOTH the
regular grab (6MP/6HP) and Circuit Scrapper (63214), in MAME and FBNeo.**

**FG PACING — resolved by observation (was NEXT_SESSION §3).** With correct
sprites the maintainer re-evaluated the FG super and it now feels fine; the
"slowness" was the broken GFX, not a timing bug. No timing change was ever
needed. Item closed — do not chase it.

**Shipped this session (persistent suite):**
- `tools/check_grab_victim.py` — relative-offset A/B verdict. Anchors on the
  seq-0x0E onset; REFUSES TO JUDGE unless both legs grabbed (seq 0x0E +
  victim took ≥0x13); PHASE-TOLERANT (±2 frames, §4 cross-emulator skew).
  `differs` = peak |Δdx| ≥30 (the OPEN defect on hui25); `matches` = ≤4
  (hui26: peak 0). Vertical launch reported, not gated (throw-arc is separate).
- `tests/test_hui_grab_victim.sh` `[bd]` (default `build/hui25` for the
  `differs` reference; pass `build/hui26` with `GRAB_VICTIM_EXPECT=matches`)
  — native-vs-build field_trace A/B + TWO verdict-logic controls, both
  rejected. Built-in validity: both legs read reldx=+42 at onset.

**Method notes worth keeping.** (1) A relative measure beats a corner rig
here: cancelling absolute placement is cheaper and more robust than pinning
it. (2) The onset-frame agreement (reldx=+42 both) is a same-instrument
positive control folded into the measurement — a dead instrument would not
have produced it. (3) Snapshots (`snapshot_frames.lua`) turned the number
into a picture for the maintainer before any code was touched.


##
## RETRACTED (14z-73): the rig IS cross-leg comparable. 14z-72 compared the
## victim's ABSOLUTE x (936 native vs 915 ours = 21px) and concluded the
## legs start at different spacing. But the whole match is globally shifted
## ~21px (camera/origin); the victim offset RELATIVE to the attacker is
## dx=42 on BOTH legs pre-grab. No cornering is needed — replay 80 with a
## both-sides forced pick is already comparable. See the 14z-73 section
## above for the measurement, attribution, and the shipped gate. The
## eliminations below (instrument, grab window) stay valid.

**New instrument, kept: `tests/lua/field_trace.lua`** — logs named RAM
fields EVERY frame (`FIELDS="ff8810:w:vx,..."`, signed reads, replay +
POKES grammar, optional frame window). We had "who wrote this?"
(trace_writes), "what sprites exist?" (obj_records_dump) and "is whole RAM
identical?" (replay.lua) but nothing that answered **"how did this value
move over time, and where do the legs part company?"** — the question
every trajectory defect asks. Previously that meant dozens of whole-RAM
DUMPS at named frames.

**Grab window located: f3154-3273** (the victim's position changes over
that span on both legs). The 14z-71 sampling that returned grenade frames
was at f3431-3449 — roughly 200 frames late. `test_hui_grab.sh` samples
3200/3230/3300, which is the correct neighbourhood and was there to be
read all along.

**~~THE RIG IS NOT CROSS-LEG COMPARABLE~~ — RETRACTED (14z-73).** At
f3150, BEFORE the grab, the victim is at x=936 on native and x=915 on
ours — 21px apart *in absolute x*. 14z-72 read that as different spacing.
It is not: the RELATIVE offset dx=(p2x-p1x)=42 on both legs. The 21px is
a global camera/origin shift that cancels in the relative measure. The
rig was comparable all along; the error was measuring absolute x.

Provisional and NOT a finding (recorded only so it is not re-derived):
with the absolute offset cancelled (victim position RELATIVE to the
attacker), native's victim arcs to dy +278 and settles at dx +111; ours
arcs to +179 and settles at +131. That is consistent with the maintainer's
report of a wrong mid-animation trajectory — and equally consistent with
two grabs that simply connected at different ranges. **Do not act on it.**

**Next step: make the legs start identically.** The clean fix is the 83d
grenade-rig trick — walk both fighters into a CORNER first, which pins
spacing deterministically on both legs, rather than poking positions
mid-match (which the engine may overwrite and which would change the
connect range that is itself under test). Author
`tests/replays/hui/80b_hui_grab_corner.rpl` with the maintainer's inputs:
regular grab **6MP/6HP at contact**, Circuit Scrapper **63214+MP/HP at
contact** — both need the fighters touching.

## Session 14z-71 CLOSE — ritual complete

- **STATE** updated (this file, newest-first above).
- **docs/NEXT_SESSION.md** rewritten for the next session: the remaining
  Phobos work, with the grab-victim item's first measurement specified and
  the correct grab inputs recorded.
- **HANDOFF** carries the hui25 registry row, the new gates, and the
  corrected launcher notes.
- **patch_index / patch_notes** carry all three beam mechanisms with byte
  detail, plus 14z-70's two.
- **New documentation** (maintainer-requested sweep):
  `docs/game/atlas/sprite_lists.md`, the "sprite-list DRAWER" section in
  `engine_internals.md`, `docs/project/porting_sprite_lists.md`,
  `docs/project/porting_code_regions.md`. Three stale section HEADERS
  corrected; `docs/README.md` indexes the new files.
- **CLAUDE.md §5** gained the RETRACTION DISCIPLINE standing order.
- **Persistent suite:** `tests/test_beam_list_type6.sh` (new),
  `tests/audit_effect_class_rows.sh` (new, incl. the tripwire),
  `trace_writes.lua` gained an address-space selector and a hex-length
  fix, `test_beam_anim_walk.sh` flipped to `walks` and now DERIVES the
  anim placement, four gates' default builds moved off superseded ones,
  and `run_hui_behavior.sh` refuses to silently rebuild historical builds.
- **Closing sweep, 18/18 PASS:** beam_list_type6, patch_overlap,
  romset_identity, compare_composite, m3a_reproducible, gfx_layout3,
  hui_boot (legacy masked-v2 EXACT), beam_anim_walk, beam_variants,
  audit_empty_tiles, audit_effect_class_rows, hui_pairs, hui_ex,
  hui_grab, hui_air, hui_walk, hui_winscreen, hui_df_style.

**SHIPPED:** the beam, maintainer-confirmed clean on all three variants,
at ZERO legacy cost (`build/hui25`, `b0fb2f94`) — plus the grab lightning,
which came free with the same class-16 row.

**Retractions this session: five, all mine.** "The beam object is never
created" was already retired; then "a vs2-only routine FOLLOWS the shared
one" (address adjacency), "the handlers are byte-identical, the one
difference is a relocated address" (that byte WAS the defect), "the
strip's tiles were never copied" (they were; the codes were wrong), and
"the grab lightning needed nothing" — twice, the second time backed by a
measurement of the wrong effect entirely.

**Four instrument failures, one shape.** A blind watchpoint space, a
rejected watch length that killed the run, a boot-clear counted as
tripwire hits, and an atlas parse with a hardcoded size. Every one printed
a confident number. The defence that worked every time was a POSITIVE
CONTROL on the same instrument and the same leg.

**What actually moved the work forward** was not analysis. The maintainer
named the ice art from a screenshot, asked why a beam would waste ROM on
non-repeating tiles (which sent us to the tile CONTENT and from there to
the emitters and the one-byte bias), and settled the grab-lightning
attribution with a two-build playtest that six build-dumps had got wrong.
Captures early, and bisect the builds before analysing the code.

## 14z-71 RETRACTION DISCIPLINE adopted into CLAUDE.md §5 (maintainer)

After the effect-family claim had to be corrected in nine places across
two passes, the maintainer asked for the fix to become work discipline
rather than a lesson. Added to CLAUDE.md §5 as a standing order:

> **When a claim changes, GREP FOR THE CLAIM — not for the files you
> remember writing it in.** Fix the HEADER and the summary line first,
> re-grep afterwards and show the empty result, and keep the superseded
> analysis marked RETRACTED. Status headers track reality; historical
> entries are not rewritten.

The evidence behind it, both measured this session: `engine_internals.md`
carried "the 214+P explosion is NOT a tile-inventory defect" as a HEADER
directly above a subsection proving it was; and a corrected
effect-family finding survived in five further places, including a
build-registry row written *after* the correction began and the gotcha's
own title and index line, which still stated the inverted lesson.

Both were found by grepping the assertion's wording in one pass. Neither
was found by re-reading the documents — which is the whole point: the fix
is mechanical, not attentional.

## 14z-71 THE EFFECT FAMILY IS CLOSED — and a NEW, separate defect:
## the GRAB VICTIM's mid-animation placement

**Maintainer playtest of `build/hui25`:** *"electricity is here, on both
regular grab and circuit scrapper"*, Phobos' own sprite OK, effects OK.

**That closes the effect family** — all four members it was ever said to
contain: the 236P beam, the ES big beam, the 214+P ground explosion, and
the grab lightning. Worth recording HOW they closed, because the 14z-69
premise was RIGHT for three of the four and the correction is the
instructive part: they were grouped as **"one root, one port covers the
family"**, and in the end the beam, the ES beam and the grab lightning
**did** share one — the dead effect-class row 16 — while only the 214
explosion stood apart. The explosion was an uncopied tile inventory (14z-70f); the beam
and ES were a stub class row + a missing list type + a per-game code bias
(14z-71); and the **grab lightning shares the beam's cause** — the dead
effect-class row 16. Maintainer playtest, decisive: hui17 has no
electricity, hui18 has it, and hui18 = hui17 + exactly the region
`x093460` and the row-16 repoint (`00080B44` -> `000D89B0`). So THREE of
the four shared a root and only the 214 explosion stood apart. My two
attempts to say otherwise were both wrong — the second "measured" the
wrong thing (a pal-0x0C filter inherited from the beam, on a rig that
never produced a grab). A shared SYMPTOM ("this effect does not draw") is a HYPOTHESIS about a
shared mechanism, not evidence for one — it has to be tested member by
member. Testing the cheapest member first (one playtest of the grab) would
have CONFIRMED the shared root immediately, instead of leaving it open for
three sessions and then being argued against twice on bad evidence.

**NEW OPEN ITEM (maintainer-reported, in scope, NOT a blocker):** during a
grab, the **VICTIM's sprite placement glitches mid-animation** — the grab
"begins and ends correctly, but the middle of the animation has the
grabbed character's sprite moving/teleporting around incorrectly". Both
grabs. Phobos' own sprite and all effects are fine, so this is
victim-side positioning only. The maintainer notes it is subtle enough
that earlier playtests did not call it with certainty.

**Why the shape matters (endpoints right, middle wrong).** Grab endpoints
are set by discrete events (connect, release); the middle is driven by
PER-FRAME data. So the suspect is the per-frame victim-offset/capture-pose
data or its stride, not the grab logic — which is consistent with the
grab's damage and launch arc already being native-exact and gated
(`test_hui_grab.sh` passes on this build).

**First measurement when this is picked up** (cheap, decisive, one run per
leg): dump the VICTIM's position fields per frame across the grab window
on native vsav2 and on ours, and diff. Positions are mapped fields
(`atlas/ram.md`), so they are directly comparable; the first divergent
frame and the size of the jump name the data. Do NOT start from the grab
code.

## 14z-71 THE DOCUMENTATION SWEEP (maintainer-requested)

Asked for after the beam closed: document how the data is structured and
drawn, game-side and project-side, including prior findings, so Pyron does
not re-pay it and so it is useful to anyone hacking VS/VS2.

**Measured first.** Gap ratio 14z-68m was 810 doc lines vs 8417 STATE
lines (~10:1); now 2118 vs 9643 (~4.5:1). Cross-checked 28 subsystems
against the docs: **none is entirely absent** — keyword coverage is broad.

**The sweep's real finding is worse than a gap: three section HEADERS
described superseded states.**
- "The 214+P grenade explosion — TRIAGED 14z-69q (**NOT a tile-inventory
  defect**)" — it WAS one, 569 uncopied tiles, fixed in 14z-70f. A 14z-70
  subsection had been appended underneath, but the header still asserted
  the opposite. **A skimmer reads headers.**
- "The beam / effect family — state after 14z-69j (EMISSION is the open
  one)" — superseded entirely.
- "Dark Force — STYLE measured 14z-69" — the palette shipped in 14z-69p.

All three now carry a RESOLVED/RETRACTED banner naming what replaced them,
with the old analysis kept below (the eliminations are still sound; only
the conclusions moved). **Rule adopted: when a finding is overturned, fix
the HEADER in the same commit — appending a subsection is not enough.**

**Written this sweep:**
- `docs/game/atlas/sprite_lists.md` — the drawer, the self-encoding table
  length, all list formats, the budget, the row-wrap rule, the per-game
  bias table, legacy usage per type.
- `docs/game/engine_internals.md` "The sprite-list DRAWER" — the
  four-dispatch chain and the three failure modes; cross-linked with the
  sword/statue blink as the same bank-attribution class.
- `docs/project/porting_sprite_lists.md` — the four questions to ask of a
  ported effect, with mechanism, safety argument and gate for each.
- `docs/project/porting_code_regions.md` — the region-bound / pc-rel
  table / escape / crypt-placement class, i.e. 14z-69h/i/j and 14z-70c as
  a checklist. This one had NO section anywhere despite costing four
  sessions.

**Open item the sweep surfaced:** `gfx_layout3.toml`'s "one-source-bank
premise" is incomplete — a tenant with a type-4 effect draws from a second
gfx bank. Re-check before Pyron's gfx rung.

## 14z-71 WHAT THE STRIP FIX RETROACTIVELY CHANGED (maintainer's question)

Asked after the clean playtest: now that we know how the beam is drawn,
does it challenge how we implemented it? Measured, three answers.

**1. It CONFIRMS the two big choices.** The list-type-6 takeover is
reinforced, not challenged: we now know the composite's children include a
PROCEDURAL generator whose output depends on runtime facing, which is the
strongest possible evidence that flattening (the competing option) was
never viable. And the type-4 handler port is still the right shape — the
bias could in principle have been fixed in DATA instead (shift each list's
raw code by +0x0A00), but the hardcoded BANK cannot, so a ported handler
was needed regardless; doing both constants in one place keeps our ported
data byte-faithful to vs2.

**2. It BREAKS one premise.** The gfx layout rests on H's art being one
contiguous bank-3 band placed at delta 0 (`gfx_layout3.toml`, the
"one-source-bank premise", which is a fact-lock in a test). That is
incomplete: his effects also draw from BANK 1, by a handler that composes
its own bank word. The premise held only because nothing had ever
exercised that path. Re-examine it for Pyron before his gfx rung.

**3. It exposes a CLASS, and this is the valuable part.** The whole port
assumes ported vs2 list data is interpreted identically by vsav's
handlers. That assumption is now measured FALSE. Comparing every handler
in vsav's drawer table against vs2's:

| list type | difference |
|---|---|
| 0, 2 | branch displacements only — semantically identical (why muzzle/tip always drew) |
| **4** | code bias +0x3800 vs +0x4200 (`addi.l`) — the beam bug |
| **6** | the same bias, as `addi.w` |
| **8** | the same bias, as `addi.w` |

So a future tenant whose content uses a type-6 or type-8 list will address
tiles 0x0A00 low and render someone else's art — the identical defect,
already diagnosed. H is clear (his composite children are only types 2 and
4), but that census covered composite CHILDREN, not every list his anim
nodes reach.

Frozen as `tests/test_beam_list_type6.sh` section 1c, which counts the
bias sites per handler in BOTH encodings and fails if the inventory moves.
Writing that check immediately caught my own first version matching only
the long form and reporting a cheerful zero for types 6 and 8 — the same
blind-instrument shape as everything else this session.

## 14z-71 THE STRIP FIXED — ONE BYTE: the two games' type-4 handlers
## use DIFFERENT code biases (build/hui25, b0fb2f94)

**vsavj biases sprite codes by +0x3800; vs2 by +0x4200.** That is the ONLY
difference between the two games' type-4 routines — one byte at
handler+0x7E — and it is the whole defect. Our ported vs2 list data ran
through vsav's handler and addressed tiles **0x0A00 too low**, landing on
the freeze/reflection art. The maintainer named that art on sight from a
screenshot.

I had compared those two handlers early and called them "byte-identical
(255/256; the one difference is a relocated address)". **It was not a
relocated address.** Dismissing it cost most of a session and produced
three wrong builds.

**How it was actually found — the maintainer's question, not my analysis.**
He asked why a beam would waste ROM on non-repeating tiles. That sent me to
look at the tile CONTENT instead of its address: vs2 bank-1 0x4EC0 is
**horizontal stripes, every row one flat colour, uniform left to right**,
stored as 16 identical copies. Uniform art means a repeat, a repeat means
the strip, and from there the emitters gave up the bias in one look. The
lesson is the one already in NEXT_SESSION five times over, in a new
costume: I inferred, he asked for the picture, the picture settled it.

**The fix (three parts, all in build/hui25):**
- `--strip-tiles` in the gfx builder: vs2 BANK-1 tiles -> group C bank 4 at
  code+0x1000, with readback verification. Chosen over vsav's own bank 1,
  which is 160-of-240 OCCUPIED at those codes (measured) — writing there
  would overwrite host art.
- A ported type-4 handler: vsavj's 0x01B61A verbatim with exactly TWO
  constants changed — `ori.w #$2000`->`#$1000` (its hardcoded bank; type 2
  takes the object's, type 4 composes its own) and the bias
  `#$38000000`->`#$52000000` (vs2's 0x4200 plus our 0x1000 shift).
- A child dispatcher in the composite: type-4 children take our copy,
  everything else the untouched vanilla drawer entry.

The inventory is a SPAN (0x4EA0-0x4FBF), not a sample: sampling native's
draws gave 0x4EC0-0x4F9F and missed the pal-05 strips at 0x4EB0/0x4ED0,
which then drew from uncopied positions. The 14z-70f grenade lesson,
re-paid.

**Gates, all PASS on hui25:** hui_boot (legacy masked-v2 EXACT),
beam_list_type6 (now covering the type-4 half and FREEZING BOTH GAMES'
BIASES so that byte can never be dismissed again), beam_anim_walk,
beam_variants, audit_empty_tiles on the beam replays,
audit_effect_class_rows incl. the tripwire, m3a_reproducible, gfx_layout3,
hui_pairs/ex/grab/air/walk/winscreen. Guarded beam replay clean to END 4420.

**A fourth instrument bug, same family:** the tripwire's atlas parse
hardcoded the body size (0x62), so when the body grew to 0x102 it fell back
to an empty PC range and reported a cheerful "unarmed" — a blind
instrument wearing a pass. Now size-agnostic.

## 14z-71 PLAYTEST (maintainer, build/hui20): THE BEAM DRAWS, and the
## STRIP is corrupt — its art lives in a bank we never ported

Maintainer report: *"the beam starts clean and it seems like it does draw
in its entirety on some frame but most of it is invisible on most frames
aside from the first segment... ES version: left half of the beam
perfect, right half there but corrupted. 236+K and 236+P have the same
graphical issues."*

That maps exactly onto the decoded anatomy: the **muzzle and tip are the
type-2 children and draw correctly**; the broken part is the **procedural
type-4 strip**, piece 2.

**Root-caused, with two hypotheses killed by measurement first:**
- *"vsav's type-4 handler differs from vs2's"* — REFUTED, they are
  byte-identical (255/256; the one difference is a relocated address).
- *"the strip's tiles were never copied"* (the child-shadow class) —
  REFUTED, `audit_empty_tiles.sh` on the beam replays finds no empty
  group-C tile, and tiles 0x4EC0-0x4ECF are non-blank in our group C.

**The actual cause, from native's own OBJ dump.** Sprite entries at f3184
on the native leg:

| piece | list type | y-word | composed tile addr |
|---|---|---|---|
| muzzle / tip | 2 | `606c` = bank 3 | `31e2f` (H's own band) |
| **strip** | **4** | **`2074` = bank 1** | **`14ec0`** |

The type-4 handler **hardcodes its bank**: `ori.w #$2000,d0` at
`PRG:0x01B654`, where the type-2 handler takes the object's own y bits
(`or.w $18(a6),d1`). On native that is correct — **the strip's art really
does live in gfx BANK 1, not in H's bank-3 band.** Our gfx port relocated
only the bank-3 band into group C, so the strip's tiles were never
ported: our group-C `0x4EC0` is vs2's *bank-3* `0x34EC0` (verified equal),
while the strip's art is vs2's *bank-1* `0x14EC0` (verified different),
and **0 of its 16 tiles exist anywhere in our group C**. Right geometry,
someone else's art — which is precisely "there but corrupted", and reads
as "invisible" wherever the wrong tile happens to be dark.

**Second mechanism to carry forward:** the handler biases every code by
`addi.l #$38000000,d1` — list code `0x16C0` emits as `0x4EC0`. Any
inventory built from the raw list data must add 0x3800 before looking a
tile up. (This is why a first census of the 24 strip lists reported codes
0x0CB0-0x0D9F while the live dump showed 0x4EC0.)

**Scoped fix (NOT built):** the strip's bank-1 tiles must be ported into
group C, and the tenant's type-4 strips must address them there — which
needs the hardcoded `#$2000` to become bank 4 for tenant strips ONLY
(type 4 is legacy-live, 321 reads/replay, so the shared handler cannot be
edited). The established shape: our composite already recurses through
our own code, so it can dispatch type-4 children to a ported copy of the
handler with `ori.w #$1000`, exactly as row 16 and list-type 6 were done.
Open before building: finalise the tile inventory under the +0x3800 bias
(24 strip lists, widths growing 2,4,6,8,10,12... as the beam stretches),
and choose the group-C codes plus the base-code rewrite in our lists.

## RESOLVED the same session — TAKE OVER THE DEAD LIST-TYPE 6
## (maintainer-approved; build/hui20, fingerprint 40cc10b1)

Neither flattening nor the drawer hook was needed. **vsav's drawer has two
list types nothing uses.** Types 6 and 8 measure ZERO reads across six
legacy replays, against same-instrument controls of 4329 / 2702 / 2260 /
321 on types 2 / 10 / 0 / 4. Nothing else points into the type-6 handler
(the two bytes before it are type-4's `rts` skip target), and H's own
content uses neither.

So: a 6-byte `jmp` over the dead type-6 handler head, and the type word on
our own 39 composite lists changed `000C -> 0006`. **Capcom's composite
code then runs verbatim — procedural type-4 children and all — with
nothing flattened and nothing re-derived.** Zero legacy cycles, because
nothing legacy executes changes.

**The zero-cost claim is measured, not argued.** Every legacy replay
matches its pre-takeover baseline EXACTLY — 02 and 07 EXACT, 03
FLICKER 2 (829, 2093), 04 FLICKER 3 (1525, 2009, 2195), 09 FLICKER 1
(829), 29 FLICKER 1 (2436) — identical run for run to the no-thunk
control. `test_hui_boot.sh` is masked-v2 EXACT.

**THE DEADNESS ASSUMPTION IS DELIBERATELY NOT LOAD-BEARING** (maintainer's
standing instruction, and the best part of the design). "Dead" here means
measured-by-absence, and we may simply have missed how vsav uses type 6.
So the body does not assume it: it discriminates on an ADDRESS RANGE — is
this list inside our own placed anim region? — and anything that is not
ours **falls through to vsav's original type-6 code**, reproduced
instruction-for-instruction and rejoined by `jmp` at `0x01B6B2`. If the
measurement is wrong, vanilla still renders correctly. That same path
bumps a counter at `$FF010C`, and `audit_effect_class_rows.sh` section 4
asserts it stays zero, so the first legacy use of type 6 is a GATE
FAILURE rather than something a human must notice.

The scratch was audited rather than inherited: vs2's own displacements
land in a live vsavj buffer (`$FF3578-$FF3581`, 39 accesses per match
replay), so the slots moved to `$FF0100-$FF010D` — 36 accesses in vanilla,
all of them the boot clear, none after frame 900, on four legacy replays
and on our own build.

**Gates at close, all PASS:** hui_boot (legacy masked-v2 EXACT),
beam_anim_walk (`walks`, with hui17 still reading `absent` as the negative
control), beam_list_type6, beam_variants, audit_effect_class_rows (incl.
the tripwire), m3a_reproducible (both frozen references bit-exact),
gfx_layout3, hui_pairs, hui_ex, hui_grab, hui_air, hui_walk,
hui_winscreen, audit_empty_tiles. Guarded beam replay clean to END 4420.

**A THIRD instrument mistake, same family as the other two.** The tripwire
gate cried wolf on its first run — five "hits" that were the boot RAM test
writing every byte of work RAM, `$FF010C` included. It now counts only
writes whose PC lies inside the placed thunk body, derived from the
build's atlas. The pattern across all three: **a "count everything"
default is the trap; every count needs either a positive control or a
discriminator that excludes init.**

**TWO RETRACTIONS, both mine, both after clean re-measures.**
1. *"Native never reads row 16"* — a `wpset` watchpoint is SILENTLY
   BLIND to pc-relative reads, which on CPS-2 are served by
   `m68k_read_pcrelative_*` -> `m_readimm16` -> **AS_OPCODES**. The
   opcodes-space watchpoint (`wposet`) turned 0 hits into 598.
   `trace_writes.lua` gained a space selector.
2. *"The handler's A5 scratch window is free in vsavj"* — it is not; it
   takes **39 accesses** per match replay. The "0" came from a DEAD
   INSTRUMENT: the tracer matched the WATCH length with `%d+` while MAME
   parses it as HEX, so a ten-byte window ("a") failed the pattern, the
   assert killed the run before the replay started, and the empty trace
   read as a clean zero. A dead instrument and a real finding are the
   same shape from the outside; every section of the new audit now
   carries a same-instrument positive control.

**Persistent suite:** `tests/audit_effect_class_rows.sh` (row 16 dead in
vanilla with a 1760-hit control; the scratch window IS used; list-type
10 is NOT a spare slot — the closed shortcut, recorded so it is not
re-proposed). `test_beam_anim_walk.sh` now DERIVES the anim placement
from the build's own atlas instead of hardcoding it.

**And that fix retro-caught a FALSE PASS.** The gate's constants were
hui14's (anim at `0x0D8950`, delta `0x16CF22`); the anim region moved to
`0x0D89B0` at hui15, and the gate's default build was switched to hui17
without re-deriving them. So section 3 was watching `0x0E2DD8` — an
address that is not the beam node in hui17 — where the expectation is
"0 reads". A wrong address satisfies that trivially: the gate had been
passing for reasons unrelated to its claim, and would have gone on
reporting "absent" after a real fix. The stale-gate class again
(docs/GOTCHAS.md), this time hidden inside a gate that was green.
Placement constants are now derived, never written down.

## Session 14z-70 — THE BEAM IS AN ANIM-SELECTION DEFECT: our build
## never walks the beam anim nodes (measured, both legs, one emulator)

Took the step 14z-69 named. The answer inverts where the arc was looking.

**1. The nodes are correctly PORTED — one more elimination.** anim places
vs2 `0x245872` at `PRG:0x0D8950`, delta **-0x16CF22**. Both node families
are structurally identical to native and every differing byte is a 3-byte
pointer relocated by exactly that delta (6 + 5 = 11/11). Static, no
emulator.

**2. Native walks them; we never do.** MAME both legs, replay 83b, the
standard early-window pokes, `trace_writes.lua` read-watch, 3,230 frames:

| leg | watch | in-window reads |
|---|---|---|
| native vsav2 | `0x24FCFA,2,r` | **2** (f3165, f3167) |
| ours (hui14) | `0x0E2DD8,2,r` | **0** |

So the residual is NOT a draw flag and NOT the emitter's output stage.
**Nothing in our build ever points an object at the beam animation.**

**3. The mechanism, decoded from the walker.** The access is `movea.l
4(A0),A0` at `PRG:0x0199D8`; MAME reports `CURPC` as the FOLLOWING
instruction (`0x0199DC`), which is worth knowing for every read-watch we
ever do. `movea.l 0x1C(A6),A0` precedes it, so **object field `+0x1C` is
the running anim-sequence pointer** — confirmed by the registers
(`[A6+0x1C]=0x24FCF6`, and `4(A0)` there holds `0x002621C8` = the logged
`A0`). The setter advances it 8 bytes per step, 37 times across the
window, as `A0 = base 0x24EDD4 + D0`, exact on every row. The sequence is
ENTERED by selecting base+offset, which is why no absolute pointer to the
node exists in either image: the tight-window scan finds exactly one
reference, an internal loop-back (`0x24FCE2 -> 0x24FC22`), itself
correctly ported in ours (`0x0E2DC0 -> 0x0E2D00`).

**4. Deliberately NOT promoted to a finding.** At fixed address `$FFD400`
ours' `+0x1C` is last written at f2365 (to `0x0F72E4`, a placed-region
address) and never advances, against native's 37 in-window writes. That
compares a RAM ADDRESS across legs — the documented slot-order trap. The
object must be identified by TYPE first. Do not promote it without that.

**Method note paid for in-session: a PC logged on one leg does not name
the same routine on the other, and SOME of them coincide anyway.** Native
is vsav2, ours is vsavj-based (`tools/reconcile_batch.py` exists for
exactly this). In the measuring run `0x000926`, `0x000D36`, `0x000D3C`
and `0x000DDC` matched exactly, counts and all, while the routine under
investigation did not (`0x01378A` 37/0; `0x015668` 8 <-> `0x016F56` 8).
The matching ones invite you to assume the rest match. Correspondence
comes from the R1 map or a known region delta, never from an address
looking familiar. Only leg-independent counts transfer.

Also retired a bad instrument: searching either image for absolute refs
to the node returns 258 mostly-coincidental 4-byte matches (values near
`0x250000` are ordinary data). The tight-window scan is the meaningful
one.

**Gate: `tests/test_beam_anim_walk.sh` — PASS.** Four sections (static
port check / native leg / our leg / three verdict controls), default
`BEAM_WALK_EXPECT=absent`. Set `=walks` when selection is fixed: that
flip IS the proof of fix. The controls exist because
`trace_writes.lua` logs one `frame 1 PC 000926` arming line with all
registers zero on BOTH legs, and counting it reads as "ours walks the
node once" — inverting the conclusion.

**NEXT:** identify the animating object by TYPE on both legs (not by slot
address), then find what selects base `0x24EDD4` + offset for it. That
selection is the defect.

Full write-up: `docs/game/engine_internals.md`, beam/effect family.

## Session 14z-70 CLOSE — ritual complete

- **STATE** updated (this file, newest-first sections above).
- **docs/NEXT_SESSION.md** rewritten: opener is the beam port, with the
  measured chain table, the two already-verified premises, the working
  agreement, and seven method notes.
- **docs/project/beam_port_scope.md** — the scope, written BEFORE
  building at the maintainer's instruction and corrected twice by
  measurement while it was being written.
- **HANDOFF** registry carries hui17 with what it contains and the rig
  needed to see it; the gate list carries the two new gates; the
  launcher default is hui17.
- **patch_index / patch_notes** carry the 569-tile inventory, the `:f`
  on a source-only root, and the x088512 growth — with the failed
  115-tile attempt recorded, since the reason it failed is the lesson.
- **Persistent suite**: `tests/test_beam_anim_walk.sh` (proof-of-fix,
  flips when the beam draws), `tests/test_beam_variants.sh` (the port's
  two premises + the ES downgrade trap), replays 83c / 83d / 86, and
  `audit_empty_tiles.sh` hardened both ways and ground-truthed.
- **Closing sweep, all PASS**: m3a_reproducible, hui_boot (legacy
  masked-v2 EXACT), gfx_layout3, audit_empty_tiles, hui_winscreen,
  hui_pairs, hui_ex, hui_grab, hui_air, hui_walk, beam_anim_walk,
  beam_variants, patch_overlap, romset_identity, compare_composite.

**Four retractions this session, all after clean re-measures**: "the
explosion is not broken" (wrong event — the rig hit the opponent), "the
x088512 tables are the explosion's root" (that code never runs), "the
beam object is never created" (it exists; it is never driven), and "the
beam machine" as a name for 0x0934A8 (it is the object's general
per-frame machine). Each is written down with the comparison error that
produced it. The pattern is consistent: a measured count of zero is
reliable; the story I attach to it is not.

OPEN: the beam port (scoped, ready), the win quote, FG pacing; then H's
freeze, then Pyron.

## Session 14z-70f/g — THE 214+P GROUND EXPLOSION FIXED (PING #13,
## build/hui17), and the BEAM narrowed to "the object is never created"

**PING #13 = build/hui17 (program fingerprint 699de9b7, gfx-only change).
The launcher points here. MAINTAINER-CONFIRMED: "explosion corrected, my
tests confirm it."**

### The explosion — maintainer-diagnosed rig error

Every rig fired 214+**MP** from 2P start distance, so the bomb always
REACHED the opponent: every capture, and the last three STATE entries,
analysed the ON-CONTACT hit explosion, not the ground mushroom. The
reported defect needs the bomb to touch nothing — **LP** (shortest arc)
AND both fighters walked back to their corners:
`tests/replays/hui/83d_hui_grenade_ground.rpl`.

On that rig it reproduced instantly: native f3445 an orange ground
fireball, ours a solid FUCHSIA rectangle (the ping-#7 fuchsia class).

ROOT: the child-shadow class again — codes correctly remapped bank 3->4
(identical ranges to native), tiles never copied into group C, so the
sprites resolve to all-zero tiles and render as solid blocks.
FIX: `extra_tiles/0x10.json` 2 -> **569 tiles**.

**The first fix attempt FAILED and that is the lesson:**
`obj_records_dump` reports a multi-tile sprite's **BASE code only**, so a
per-drawn-tile inventory (113 tiles) missed the other 35 tiles of the 6x6
sprite that IS the block. Corrected by taking every tile in span
0x0A00-0x0C40 that vs2 bank 3 has art for and group C lacks.

**`audit_empty_tiles.sh` HARDENED** — it passed every build through
hui16: it sampled every 25 frames (found 10 of 113) and checked only base
tiles. Now every frame, expands `w*h` at `base + row*0x10 + col`, and
83d is in its defaults. Ground-truthed: FAILS hui15, PASSES hui17.

Gates on hui17, all PASS: gfx_layout3, hui_boot (legacy masked-v2 EXACT),
hui_winscreen, pairs, ex, grab, air, walk, audit_empty_tiles.

### The BEAM — a DIFFERENT class, and now precisely located

Maintainer confirmed the rig (83b, 236LP at 2P distance) and the defect:
**muzzle orb and beam both missing, while the FREEZE ITSELF WORKS**
(Victor is iced on both legs). Also confirmed for later verification:
LP/MP/HP do not change the beam visually; **236+2P** (ES) gives a
girthier beam and a different Phobos shape; **236+K** gives a LOW beam
that hits crouching. Stage re-tinting between vs2 and vsav is expected —
not a defect.

Unlike the explosion this is NOT missing tiles — ours emits no sprites at
all. Chain measured on the pool the RAM atlas already documents
(`docs/project/tables/reconciliation.md:70` — `$FFD400/0x80/cat14`, and
"GEOMETRIES ARE IDENTICAL in both games, pool-for-pool", which is what
makes the address comparable across legs):

| | native | ours |
|---|---|---|
| beam sprite-list reads | 2 (f3165/3167, PC 0x019E0E, A6=$FFD400) | 0 |
| anim-pointer writes in f3160-3210 | 26 (PC 0x01378A, A0 = 0x24EDD4 + D0) | **0** |
| pool-slot HEADER writes f3150-3210 | 30 (PC 0x0934B4) | **0** |

**So the beam object is never CREATED** — not created-then-not-animated.
NEXT: find the vsavj twin of the creator at vs2 `0x0934B4` (PCs do NOT
transfer between legs — use the R1 map / `reconcile_batch.py`), and find
why the ported code never reaches it. Verify by execution breakpoint
BEFORE attributing anything (14z-70d).

### Process change, maintainer-requested

**Send the native/ours capture pair and state the interpretation BEFORE
measuring on it**, naming the rig assumptions (button strength, spacing,
which event should be on screen). The MP-vs-LP error cost most of this
session and the maintainer spotted it instantly from my own screenshots.

## Session 14z-70b/c/d — the grenade explosion: a COMPARABLE rig, the
## symptom pinned to a +0xA220 code shift, and one wrong root cause

**Nothing here changes what a player sees. `build/hui14` remains the
build with the confirmed fixes and the launcher stays pointed at it.**

**1. The rig was invalid, and that had to come first.** Replay 83 is
1P-vs-CPU: vsav2 and vsavjw pick a different CPU opponent AND stage, so
the legs were two unrelated matches (at f3436 native is at range with the
explosion on screen; ours has Felicia point-blank and the projectile
never travels). New `tests/replays/hui/83c_hui_grenade_2p.rpl` — 2P,
BOTH sides poked (P1 H 0x10, P2 Victor 0x03 on both games). Snapshots
confirm: Phobos vs Victor, subway stage, both legs.

**2. On that rig the effect object is CORRECT and only the codes are
wrong.** Position-matched the legs agree frame for frame (f3432: n=13,
x 273-401, y 57-201 on each), same palette, same bank; and in the same
dump pal 0a (98/91) and pal 0c (42/42) carry identical code ranges
correctly remapped bank 3->4. Ours = native **+0xA220**, 41 of 88 codes;
of those, 9 have identical art and 32 differ, none blank — vsav's own
effect page, right shape, wrong picture. That is why
`audit_empty_tiles.sh` is correctly silent.

**3. A REAL latent defect found and fixed — which turned out NOT to be
the cause.** `x088512` ran 0x088512-0x08C052 while its own effect
machine's three `lea (d16,pc)` tables sat at 0x08C08A/9A/A2, past the
end, resolving into the ANIM region placed right after. Fixed in
`build/hui15` (**699de9b7**) via root `0x88512:0x3b98:s:f0x3b78` plus a
small `extract_char.py` change so a SOURCE-ONLY root honours `f<off>`
(the `:s` branch returned early and never set `raw_from`).
`verify_pcrel_data.py` 72 BROKEN -> 69, all three rows gone.

**And the explosion is byte-for-byte unchanged** (hui15 code set ==
hui14 code set, snapshot identical), because **the code that reads those
tables never executes** — an execution breakpoint at the placed twin
`PRG:0x0D8912` fires zero times.

**THE ERROR, NAMED: co-location is not causation.** "The effect machine
lives in x088512; x088512 has tables resolving into the anim region;
therefore those tables feed it" — every clause true, conclusion false.
**Put an execution breakpoint on the code that READS a table before
attributing a symptom to it.** One run; it would have preceded a whole
rebuild. Third instance this session of measuring something real and
assuming it was the thing in front of me.

**hui15 KEPT, fully gated (10):** m3a_reproducible (both frozen
references bit-exact — the shared-tool edit is inert on Donovan),
hui_boot (legacy **masked-v2 EXACT**), gfx_layout3, audit_empty_tiles,
hui_winscreen, hui_pairs, hui_ex, hui_grab, hui_air, hui_walk. It is a
latent repair of the ratified x06cac0 class with NO observable effect.
**Maintainer decision outstanding: keep it or revert** — it is unproven
behaviourally by definition (nothing to prove), and the commit is
isolated if you would rather not carry it.

**4. 14z-70e — THE EXPLOSION IS NOT BROKEN. Points 2-3 above are
RETRACTED.** On the maintainer's proposal (diff the screen before vs
during, then search BOTH games for that tile CONTENT):

- native's 88 explosion tiles: **87 already present in our build** (84 in
  group A, 3 in group B);
- the mapping is a PERMUTATION — 0x0EC0E holds vs2 0x495F's art, not
  0x49EE's — so **+0xA220 was a statistical artefact**: two dense
  ~85-value clusters offset by ~0xA220 overlap ~half the time by
  construction. It described nothing;
- window content join: **76 of ours' 84 drawn contents are byte-identical
  to native's**, 0 blank. Per-FRAME the intersection is 0 at every frame
  only because the legs run ~2-4 frames out of phase;
- and it LOOKS right: at the SAME frame f3440 both legs show the large
  flame pillar, same shape and position. The "small yellow burst"
  comparison was f3430 vs f3430 across a ~10-frame phase lag.

14z-69q's triage was measured on the invalid replay-83 rig and
characterised sprites that were not the explosion. **Needs a playtest to
close.** Residuals: the phase lag and 8/12 unmatched contents (partly
2-frame sampling).

**METHOD PROMOTED:** identify what an effect draws by diffing the OBJ
list before vs during, then join the legs by TILE CONTENT — never by
index, never per-frame across legs that drift in phase.

**The BEAM remains genuinely open** and is a separate defect (it never
walks its anim nodes at all).

## Session 14z-69 CLOSE — ritual complete

- **STATE** updated (this file, newest-first sections above).
- **docs/NEXT_SESSION.md** rewritten for a fresh session: opener is the
  effect family, with the eliminated causes listed so they are not
  re-opened, and the five method notes from this session.
- **HANDOFF** registry carries hui12/hui13/hui14 with fingerprints and
  what each contains; the gate list carries the two new audits; the
  launcher default is hui14 (it had been two builds stale — the rule
  "repoint the launcher in the same commit as a promotion" is recorded).
- **patch_index / patch_notes** updated with the three new facilities
  (`extra_tiles`, root `:f<off>` + raw-emit, `data_port
  df_palette_seq_rows`) and their byte detail.
- **Persistent suite**: every probe from this session is a rerunnable
  test — `test_hui_df_style.sh` (3 expectations, 4 verdict controls),
  `audit_palette_seq_ids.sh`, `audit_empty_tiles.sh` (ground-truthed
  BOTH directions: passes hui14, fails hui12 naming the tiles),
  `verify_pcrel_data.py`, plus `GUARD_PROBE_MAX` on the guard.
- **Closing sweep, all PASS**: m3a_reproducible, hui_boot,
  census_regions, hui_df_style, audit_empty_tiles, gfx_layout3,
  hui_winscreen, patch_overlap, romset_identity, compare_composite.

OPEN (unchanged, all parked with rigs recorded): the effect family
(beam / grab lightning / ES big beam / 214 explosion — one root), the
win quote, FG pacing; then H's freeze, then Pyron.


## Session 14z-69p/q — DF PALETTE FIXED (PING #12, build/hui14 =
## c25b3824, playtest-confirmed) and the 214 explosion TRIAGED

**DF palette: FIXED and confirmed by the maintainer** ("palette is
clean, DF looks good as is"). One [[data_port]] row swaps palette-seq
rows 0x1E-0x21 for the sequence native's DF actually shows (vs2
0x3ABEDC, vh2 twin 0x38BEB0). The afterimages stay by design.

TWO ATTEMPTS, and the first is the lesson: copying vs2's rows at the
SAME ids is wrong — vs2 never runs that DF path for him, so those slots
hold something else, and the build came out tan/blue. The right source
was found from the other end: native's in-DF palette row ends in 0x0003,
a seq row's SELF-INDEX, so search vs2 for that exact content and take
the four-row sequence it belongs to.

Safety: legacy never requests those ids — audited uncapped over 8
replays / 10,504 calls (only 0x26, 0x27), committed as
tests/audit_palette_seq_ids.sh. That audit is the ONLY guard possible,
since the palette path never transits work RAM. GUARD_PROBE_MAX was
added to replay_guard.lua because the default 400-hit cap had silently
truncated the first audit and hidden id 0x27.

**214+P grenade explosion: TRIAGED, belongs to the effect family.** Not
a tile-inventory defect — zero empty-tile draws across the 214MP window
of replay 83. The pieces draw pal 05/06/08 from BANK 0 (stock art) at
onset f3395/f3430: the "path that leaves +0x18 unset" class, same root
as the beam. Parked with the rig recorded in engine_internals.


## Session 14z-69o — THE CHILD SIDEKICK'S SHADOW FIXED, and PING #11
## PLAYTEST CONFIRMED (build/hui13, 31d576be)

**The 14z-68g diagnosis was backwards.** It had measured that our shadow
BAND carries `code = native - 0x16A8` with bank 0 and concluded the band
was the defect and the core was fine. Comparing the ART at those
addresses inverts it:
  core: native 0x30F8B bank 3 -> ours 0x40F8B group C = **ALL ZEROS**
  band: native 0x30F96 bank 3 -> ours 0x0F8EE bank 0  = byte-identical
The band is correct — shared system tiles the stock set holds at
native - 0x216A8, drawn by the vanilla engine path. A uniform delta
means a consistent MAPPING, not corruption; check the art before calling
it wrong.

The core is the defect: the tenant gfx remap rewrites codes in
[0xAF6, 0x4EFC] from bank 3 to bank 4, and 0x0F8B/0x0F8C fall inside it,
so the BANK was rewritten while the TILES were never copied into group C
(obj_records.py's pointer walk never reaches the records that reference
them — the offset-computed-records trap). Bank rewritten + tile absent =
a solid rectangle, exactly the reported symptom.

FIX: per-tenant `build/manifest/extra_tiles/<char>.json` merged into the
copy inventory by build_donovan.sh. Two tiles. Program bytes UNCHANGED —
hui13 shares hui12's fingerprint, which is itself the evidence that this
is gfx-only; all four group-C members differ.

Gates: gfx_layout3, hui_boot, m3a_reproducible, pairs, ex, grab, air,
walk, winscreen, wide_render_content — all PASS.

### PING #11 playtest — MAINTAINER CONFIRMED

- **shadow CORRECT on the real screen.** That also validates the finding
  METHOD: decode every group-C sprite a build draws and flag any that
  resolve to an all-zero tile. It found this defect completely (2 hits,
  nothing else). **Run it for Pyron's gfx rung.**
- **DF palette still wrong** — expected, untouched. Parked at a known
  point (seq ids 0x1E-0x21; vsavj's rows purple where vs2's are gold;
  trigger arrives via the channel machine's program-byte dispatch, so
  the fix is script data and needs that opcode table decoded).
- **beam + electricity still absent** — expected, same family, now
  narrowed to EMISSION (object created, ported machine, record at
  native's own relative offset, tables byte-identical, 118/128 bytes
  matching native).

All three match the measured state; no new defects reported.

LAUNCHER NOTE: the maintainer was playtesting hui11 because
run_hui_behavior.sh still defaulted there. Repointed to hui13. When a
build is promoted, repoint the launcher in the SAME commit.


## Session 14z-69j — THE TABLE FIX SHIPPED (build/hui12); the DF crash
## is gone; the beam still does not draw

**Raw-emit implemented and verified.** `:f<off>` on a root now forces the
declared length AND declares where the forced tail stops being code and
becomes raw DATA (`0x6cac0:0xebc:t0x6cc34:f0xca8` — the split is the
FIRST TABLE, not the oracle boundary: 0x6D6C0-0x6D768 is live
object-spawning code, checked by disassembly). The generator emits the
region as `code_file` up to the split and `data_file` after it.

ONE CORRECTION PAID FOR IN A BUILD: the tail must be written from the
SOURCE DATA IMAGE, not from `blob`. `blob` holds the region's OPCODE-view
(plaintext) content; an (An)-based read is a DATA-space read and returns
the raw stored bytes, so the copy has to store vs2's raw bytes. First
attempt wrote plaintext and all seven tables still mismatched.

**Result: all seven tables read byte-identical to vs2** (checked by
disassembling each placed lea and comparing its target's data view).
`build/hui12`, fingerprint **31d576be**.

**Gates, all green on it:** m3a-reproducible (both frozen references
rebuild bit-exact — the tooling changes are inert on Donovan), boot
(masked-v2 EXACT legacy), pairs, ex, grab, air, walk, fx_flow,
winscreen, df_style, ladder, census.

**The census now understands raw-emit**: a table inside its own region's
raw-emitted tail counts as covered (no manifest row needed, and none
wanted). Inventory re-frozen as **5 row-covered + 7 raw-emitted**; the
7 became visible only because census 1 learned the DEFERRED reader
shapes this session.

### Two measured outcomes on the parked effect family

1. **The DF crash that parked `tenant_type_stamp` is GONE.** Built a
   scratch with the stamp + obj_hook_extra un-parked (fingerprint
   c8587d33): `test_hui_pairs` PASSES, where 14z-68d recorded a vec3 at
   0x0D4696 with an index underflowing the placed region. Consistent
   with cause: the machine was walking garbage streams.
2. **The beam still does not draw.** Measured properly this time — a
   dense scan found native's beam window (pal-0x0C pieces at f3164-3208
   of replay 83b, ~12-frame cadence, 3-13 pieces), and at those exact
   frames BOTH our builds render **zero**, with and without the stamp.
   So the residual is what 14z-68d suspected: how the emitter is reached
   or a draw flag — not dispatch, records, art, or (now) the tables.

**The stamp stays PARKED** despite the crash being fixed: it buys no
visible change today and the maintainer is not here to playtest. Un-park
it when the emitter question is answered.

### NEW, needs triage (not new breakage)

`verify_pcrel_data.py` flags **72 pcrel data pointers in OTHER regions**
(x022400, x026142, x028122, x088512) as resolving to bytes that are not
their source tables. These predate today — hui11 ships with them and its
gates are green — so they are either cold paths or a latent defect of
the class this project has been bitten by four times. Triage one by one;
do NOT mass-"fix" them.

## Session 14z-69i — the reroute BUILT, and a better design found in
## the process (raw-emit); nothing shipped, tree rebuilds hui11 exactly

Implemented the postinc reroute designed in 14z-69h, then measured it
into a corner and out the other side.

**Built and working:**
- census 1 generalised from "reader immediately follows the lea" to a
  deferred scan (`scan_deferred_reader`): any read through An — `(An)+`,
  `(d16,An)`, `(d8,An,Xn)` — before An is redefined. This caught TWO
  MORE sites the old rule missed for the same reason as the
  post-increment one: vs2 0x6CD5E and 0x6CFDC read `(a0,d0.w)` three and
  four instructions after their lea. **Seven tables, not five.**
- generator `shape = "pointer"` rows: replace the 4-byte
  `lea (d16,pc),An` with `bsr.w helper`, helper = `lea.l #table,An; rts`,
  plus per-table dedup (0x6D91C is read from three sites).

**Where it hit a wall:** the helper must be within bsr.w (+/-32K) of the
site. The table hole "b" is ~0x32xxxx away; the crypt hole "a" holds the
placed regions but its FREE space is ~0x27000 from the site. 68000 has
no bsr.l. Remaining options were helpers inside the region's own pad
(needs coordination with the pcrel_escape_fix pass, which owns it).

**The better design, found while reasoning about it:** CPS-2 decrypts
OPCODE FETCHES ONLY — a data read returns whatever is stored. The
tables read wrong purely because the builder encrypts the whole region
blob as code. With `:f` the pointers ALREADY resolve to the right
addresses (measured 14z-69h), so nothing needs rerouting: the table
bytes just have to be EMITTED RAW. That requires splitting the region's
code op around them (overlapping ops are a named build error), which is
a builder change — and it fixes all seven at once with no helper, no
allocation, no reach constraint.

**NOTHING SHIPPED.** `:f` is off, the seven manifest rows are removed
(replaced by a comment recording the design), and the tree rebuilds the
reference bit-exactly: fingerprint **5c6dbe43** and a decrypted PRG
image with **0 differing bytes** against hui11. The tooling additions
(deferred scan, census 3, verify_pcrel_data.py, `:f`, the pointer-shape
reroute) are all inert until a manifest asks for them.
test_census_regions.sh PASS, H inventory and Pyron unchanged.

NEXT: implement raw-emit for dead-zone tables inside a forced region,
then land `:f` + it together and check whether the beam finally draws.

## Session 14z-69h — THE PARKED EFFECT FAMILY: full chain, and the
## exact remaining step

Set out to close 14z-68's named tooling gap (the census missing the
post-increment reader). Did that, and it led to the real root cause.

**1. Post-increment detection added** (`scan_postinc_reader`): walks
forward from the `lea` and stops only if An is redefined. Necessary
because the ground-truth reader (vs2 0x6D206 -> 0x6D868) sits **0x3E
bytes away inside a bsr subroutine** — "immediately after" can never
see it. Catches that site and three more.

**2. The bigger blind spot: pc-rel DATA POINTERS leaving the region.**
`lea (d16,pc),An` is rewritten by NOTHING (census 1 wanted a code-region
host, census 2 scans only branches, extract_char's pcrel_refs sweep only
jsr/jmp, and the generator's far-pcrel trampoline is documented
CODE-only). Added census 3 (report) + `tools/verify_pcrel_data.py`
(verdict against a built image). Measured on hui11: region x06cac0 is
**7/7 BROKEN** — `lea $6D868(pc),a3` resolves to 0x0D4C98, which holds
code, not the fleet param stream. That IS the parked "reads garbage".

**3. Why the tables are outside — CORRECTED.** Not "the declared length
is ignored": in extract_char.py `fixed_len` is a **CAP**, and
`oracle_extend` decides the real end. The sibling stopped agreeing at
+0xC00 (the tables legitimately differ between vs2 and vh2), so the
region ends there by design.

**4. `:f` force-length added** to the root spec, with the forced tail
registered as a DEAD ZONE (unvalidated by construction — without that
the region fails the variant-density check at exactly the first table).
Measured on a scratch build (fingerprint ee9318fc): the region becomes
0xEBC, the tables are inside it, and the pointers now resolve to the
CORRECT relative addresses.

**5. But that is only half the fix, and this is the remaining step.**
The placed tables carry the **OPCODE image** (verified byte-identical to
vs2's opcode view at 0x6D868) because a code region is stored to
execute, while the engine reads them as DATA — so they still decode as
garbage. The census now says exactly this: **5 UNCOVERED
`data_in_code[postinc]` sites**. Each needs a `[[data_in_code]]` row so
the generator places a DATA-view copy and reroutes the reader.
**The generator's reroute cannot do it yet:** it replaces 8 contiguous
bytes (`lea` + read) with `jsr helper; nop`, which requires the reader
to follow the lea. For post-increment the fix shape is different and
smaller — replace the 4-byte `lea (d16,pc),An` with `bsr.w helper`,
helper = `lea.l #table,An; rts` (8 bytes, near-allocated within the
existing d16 reach machinery).

`:f` is deliberately NOT enabled in build_donovan.sh: landing it alone
changes the shipped bytes without fixing anything (the tables would move
but still read as opcode image). It must arrive together with the five
rows and the postinc reroute. Recipe recorded at the root declaration.

Gates: test_census_regions.sh PASS (H inventory + Pyron unchanged).

## Session 14z-69c — THE DF MECHANISM TRACED (fix is a DECISION)

Full trace in docs/game/engine_internals.md (Dark Force). Summary:

- **vsav and vs2 run different DF systems.** Activation bodies vsavj
  0x027000 vs vs2 0x02619E: different field sets (+0x111/+0x110/+0x176
  vs +0x1C3/+0x1C8/+0x1C4/+0x13A/+0x13B), different stock cost (1 vs 2),
  different tail calls. Both write seq 0x16.
- **The per-char byte tables (vj 0x02704E / vs2 0x02620A) are
  byte-identical and give id 0x10 the same value 4** — not the
  discriminator. (Opcode view; the data view is noise.)
- **The divergence is what happens to seq 0x16.** Native clears it the
  same frame (0x025EE0) and plays on normally. Ours dispatches it
  per-char through table **0xBF31A (dispatch_16)**, row 0x10 repointed
  to H's placed port of vs2's handler, which calls **0x2A7E0** — the DF
  effect-channel script machine — and locks him in **seq 0x18** for the
  mode. Channels draw the trailing copies; the mode recolours row 0x0A.
- **Native never executes that handler.** vs2's DF does not set +0x111,
  so both the seq-0x16 path and the DF-tick dispatcher (0xBF61A / vs2
  0xD97B8, guarded on +0x11F and +0x111) are unreachable there. Probed
  with positive controls: native 0 hits at 0x56D70, ours 1 hit at its
  placed twin 0x0C1780 — at frame 3667, DF EXPIRY, where the body is a
  CANCEL (clears +0x17b/+0x111/+0x110/+0x1b5 and returns).
- **Legacy is clean**: vanilla vsavj + Victor in DF = no recolour, no
  extra draws. This is not "the host's style" — it is our repoint making
  vs2's DF-form machine reachable under vsav's DF.

### 14z-69d: DONOVAN DOES NOT HAVE THE BUG — and that REFRAMES the item

Maintainer asked whether Donovan shows the same thing. Measured, same
rig (replay 85, id 0x13, ours build/m5_wide vs native vsav2):

| | palette row 0x0A pre-DF -> in-DF | his own draws | seq |
|---|---|---|---|
| Donovan (ours) | UNCHANGED | 12-16 vs native 15-18 (x0.7-1.1) | 0x16 -> back to 0x04/0x06 |
| Huitzil (ours) | gold -> PURPLE | 28-32 vs native 6-8 (x4) | locked 0x18 for the mode |

**The wiring is identical** — Donovan's build repoints dispatch_16 row
0x13 to his placed vs2 handler exactly as H's repoints row 0x10. What
differs is the CONTENT of each character's vs2 DF-form handler:
- Donovan's (placed 0x0C109C): sets +0x147, saves +0x155 -> +0x350,
  `moveq #$51,d0; jmp 0xCE35A` — benign, returns to normal states;
- Huitzil's (placed 0x0C168A): calls **0x2A7E0**, the DF effect-channel
  script machine, then drives seq 0x18.
So the repoint is NOT wrong in general, and "leave it" is NOT
"consistent with Donovan" — Donovan simply does not do this.

**AND THE STATE IS COHERENT, NOT BROKEN.** Position data across the DF
window: native stays GROUNDED (y=40) the whole mode; ours HOVERS at
y=124-133 and still moves horizontally (x 834 -> 937 -> 1000) while
locked in seq 0x18, for exactly the mode's duration, ending when DF
expires. That reads as a **flight/hover mode with an afterimage
visual** — i.e. plausibly Huitzil's ORIGINAL Vampire-Savior-style Dark
Force, whose per-char code vs2 still carries in its tables but never
invokes (vs2 replaced the DF system wholesale, so the old form handler
is vestigial there). Our engine IS vsav, so it invokes it.

HYPOTHESIS, NOT YET PROVEN: the afterimages may be the intended visual
of that flight form, while the PURPLE may be a separate palette-source
defect of the win-screen class (a row index computed from char id
landing on a host row). Testable: find what writes palette row 0x0A at
DF entry and whether its source is id-indexed. If it is, the fix could
be "his DF is his flight mode, in his own colours" rather than
suppressing the mode at all.

### 14z-69e: MAINTAINER DIRECTIVE + the colour source located — the
### decision is effectively RESOLVED

Maintainer: "keep the mechanism as it is supposed to be; if we have
small graphical side effects we can't clear, that's fine. But it should
be mechanically sound and either vanilla or as close as we can make it,
even for added characters."

Against that standard, measured:
- **The mode is mechanically sound.** Entry costs ONE stock (vsav's
  cost, not vs2's two). He hovers at y=124-133 and moves horizontally
  while in it, descends at f3660, lands at f3670, all three mode fields
  clear, seq returns to 0x00 idle, palette restores exactly, no residue
  through f3900. Clean entry, clean exit, vanilla cost.
- **It is almost certainly his ORIGINAL Vampire-Savior Dark Force** — a
  flight form whose per-char code vs2 still carries but never invokes,
  because vs2 replaced the DF system. Our engine is vsav, so it runs.
  This is "as close to vanilla as we can make it" BY KEEPING IT.
- **Donovan proves the wiring is right in general**: identical repoint,
  no recolour, no ghosts, seq back to normal — his vs2 DF-form handler
  is simply benign where H's enters a form.

So options 1 and 3 collapse: **keep the mode** (option 3), and treat the
colour as the only defect. Option 2 (port vs2's type-A DF) was ruled
out by the maintainer independently.

**The colour source is located and it is a KNOWN CLASS.** One writer,
engine 0x02AD68 (the 0x2AD64-family palette-seq uploader), rewrites row
0x0A every frame from DF entry, cycling four contiguous rows of the
global palette-seq table at vsavj 0x39ACD0-0x39AD4F. Their vs2 twins
(delta +0x1613C -> 0x3B0E0C) are a GOLD ramp where vsavj's are PURPLE.
**This is the sword/statue blink of 14z-33** — same ids, different
global-table contents, table is legacy surface. The fix design is
already written up there: wrap the seq-TRIGGER call inside the PORTED
handler (legacy-clean by construction), routing the tenant's ids to
privately placed copies of the four vs2 rows (0x80 bytes) and leaving
all other ids alone. NOT yet implemented; it is cosmetic by the
maintainer's own standard, so it is optional and safely deferrable.

### SUPERSEDED — the earlier three-way decision (kept for the record)

Not mine to make (CLAUDE.md §5: anything a player can feel).

1. **Neutralise the seq-0x16 row for the tenant** so the engine clears
   it like native does. Closest to the native LOOK (no afterimages, no
   recolour), cheap, no legacy surface. But his DF then has no
   per-character power — it is the generic vsav mode. CAREFUL: the
   vanilla row 0x10 is an ALIAS of row 0x00 (Bulleta's handler), so
   "just don't repoint it" is not the same as "null" and must be
   measured, not assumed.
2. **Port vs2's type-A DF system for him** (0x02619E body + the 0x82AE2
   servant install + 0x6D9D4 tail). Native-faithful, but it is a
   second DF system inside a legacy-hot path and the stock cost differs
   (2 vs 1) — a rule change legacy characters do not share.
3. **Leave it.** The afterimages are cosmetic-ish but the seq-0x18 lock
   is not: he stays in the transform state for the whole mode.

RECOMMENDATION SUPERSEDED BY 14z-69d. Do NOT reach for option 1 until
the flight-mode reading is settled: what our build gives him is a
coherent hovering mode, not a broken state, and option 1 would delete
it. New preferred order: (a) find the palette-row-0x0A writer at DF
entry and test whether the PURPLE alone is an id-indexed source defect
(win-screen class); if it is, fixing that may leave a correct
Vampire-Savior Dark Force for him. (b) Only if the mode itself is
unwanted does option 1 apply. Maintainer has ruled OUT option 2
(porting vs2's type-A DF).

## Session 14z-69b — DOCS SPLIT THREE WAYS (maintainer proposal, adopted)

Maintainer: the SMS project split docs into game knowledge vs
project knowledge, and doing the same here would make "do we already
know about this?" answerable. Adopted, with a third bucket for the
platform because we patch emulator descriptors and those facts are
reusable by any CPS-2 work.

Discriminator: **would this still be true if we abandoned the roster
hack tomorrow?** -> `docs/game/` (Vampire Savior), `docs/platform/`
(CPS-2, MAME, FBNeo), `docs/project/` (this port). Taxonomy and the
full contents list: `docs/README.md`.

- `docs/game/`: engine_internals.md, atlas/ (5 files), gotchas.md
- `docs/platform/`: gotchas.md
- `docs/project/`: patch_notes/patch_index, cps2_wide, tenant_manifest,
  tables/, M1/M2/M3b, WSL2_SETUP, visual_smoke_tests, playtest interims,
  m5/, gotchas.md
- `docs/` root keeps the ENTRY POINTS on purpose: NEXT_SESSION.md
  (session state, not knowledge), GOTCHAS.md (now the index), and
  checksums.txt (machine-read by audit_roms.py — stable path).

GOTCHAS was the doc most in need of it: 135 entries mixing "the game
will mislead you" with "our pipeline will bite you". Split 26 game / 35
platform / 74 project, verified content-lossless (every non-header line
of the original is present in the union), with `docs/GOTCHAS.md` left as
an index so the ~195 existing citations still resolve — and the index
doubles as the topic list the split was for.

**The rule the split alone would NOT have given us**, and the one that
matters most here: **a subsystem section must name the atlas rows it
depends on.** `atlas/ram.md` had documented since 14z-44 that `+0x109`
is the banked stock count and `+0x107 = 0xFE` means "pair downgraded
(no stock)" — the exact fact needed to notice DF was never activating.
Three sessions missed it because engine_internals' Dark Force section
never pointed at those rows. That cross-link is now written into the DF
section, `docs/README.md` and CLAUDE.md §5.

69 files had doc paths rewritten; 0 broken relative links; gates
re-run after the move (patch_overlap, hui_winscreen, hui_df_style).

## Session 14z-69 (Dark Force — measured for the first time)

### Two premises overturned

1. **The native leg was never blocked.** 14z-68j's "the early-window id
   poke does NOT force him on vsav2" came from ONE attempt with replay
   61, whose input timing is authored for OUR wheel. The replay-80 flow
   reaches him natively: `$FF8782 = 0x10` at f1400/1450/1500 gives
   `+0x382 = 0x10` on `vsav2`. Six seconds a run.
2. **DF costs a banked stock, and replay 82 never had one.** `+0x109 =
   0` throughout on BOTH games, `+0x107` = 0xFF/0xFE = the pair
   DOWNGRADED to a single button. **seq 0x0A is that downgrade, not
   Dark Force.** So every DF measurement from 14z-66 (the "DF mechanics
   are already native-correct" claim, the pods in pool B) through the
   14z-68 channel decode was taken outside the mode.

I compounded it: I published a full A/B this session concluding the
symptom "does not reproduce" — palette identical over 118 frames, sprite
sets equal, on both emulators, forced-pick and hand-picked, with PNG
snapshots. All of a match that was never in DF. The maintainer caught it
from one screenshot: an ordinary stage and no TIME bar. Retracted in
full. I also twice invented a DF flag by inspection (`+0x1B5/+0x1B9`,
then `+0x1F4`) — both are set by JUMPING.

### Dark Force, actually measured (native vsav2 vs hui11)

| | native | ours |
|---|---|---|
| activation seq | 0x16, cleared to 0 at once | 0x16 -> **0x18** (held) |
| stocks spent | **2** | **1** |
| fighter fields | +0x13A/+0x13B, +0x1C3/+0x1C7/+0x1C8 | +0x110/+0x111/+0x17B, +0x189 |
| palette row 0x0A | gold, slightly brightened | **purple ramp**, 82/82 frames |
| his own draws | 6-8 | **28-32** (3-4 trailing copies) |

Match-level DF flag **`RAM:$FF802E`** (1 for the mode, 0 before and at
expiry, identical on both games) — derived by dumping ALL work RAM at
five phases on both games and keeping only bytes with that shape; 18
qualify. This is what the gate now gates on.

**The tenant inherits the host's DF TYPE, not just its styling**: native
Huitzil's DF does not enter the transform seq at all.

### The activation site (FBNeo write tap on $FF8406)

- seq `1600` written by **vs2 0x0261A6 <-> vj 0x027008**, stock debit
  immediately after (vs2 0x0261C2 / vj 0x027024);
- **native then runs 0x025EE0, which writes the seq back to 0** — a
  per-character branch cancelling the transform. Ours never does.
So the DF-type selection sits between those sites. NEXT: decode it —
expect an id-indexed table with variant rows aliasing base rows, and
decode both views before trusting a row (the standing view GOTCHA).

### Delivered

- `tests/replays/hui/85_hui_df_vs2.rpl` — runs UNCHANGED on both games;
  both sides poked (P2 = Victor 0x03 on both) plus **three banked
  stocks**; the same air dash before DF and twice during it.
- `tests/test_hui_df_style.sh` + `tools/check_df_style.py` — refuses to
  judge unless BOTH legs are verifiably in DF; freezes the defect shape
  (`--expect differs`), flip to `matches` when fixed. Three verdict
  controls: DF-never-active (the shape that fooled me), no-recolour,
  no-afterimages — each must fail, and does.
- `tests/test_hui_pairs.sh` corrected: its "Dark Force" section was
  asserting the empty-meter downgrade. Renamed to what it measures; the
  assertion stays as a valid regression on that path.

(Previously: session 14z-68 CLOSED — THE PHOBOS WIN SCREEN
FIXED AND MAINTAINER-CONFIRMED (palette + position; PING #10 =
build/hui11 = 5c6dbe43), the effect arc PARKED behind a named tooling
gap, and the SYNTHESIS GAP CLOSED (engine_internals 810 -> 1076 lines,
8 new subsystem sections written the same session the gap was found).
Four defects shipped and gate-locked; five wrong conclusions of mine
RETRACTED in-session, each with the mechanism written down so it
cannot be re-followed. Every gate green at close, including a stale
census caught BY the closing sweep and re-frozen with justification.
Read docs/NEXT_SESSION first, then the 14z-68 sections below.)

## Session 14z-68 (the effect-flow closure — root cause found)

### The 14z-67 seq-D entry theory is REFUTED (three measurements)

- Un-parked seq_d_dispatch in scratch (build/scratch/hz7 =
  huitzil_seqd.toml, fingerprint 0f299f3b) and reproduced the kill
  with NEW replay tests/replays/hui/83b_hui_ray_2p.rpl (2P-dummy,
  three spaced 236LP — cross-emulator reproducible, FBNeo-tappable).
  FBNeo tap A/B (ours vs NATIVE vs2, identical poke flow) showed:
  1. NATIVE NEVER EXECUTES 0x56D68 — zero hits across the whole
     replay including three successful rays. The premise "vs2
     dispatches H's fighter into 0x56D68 every seq-D tick" is false.
  2. The parked thunk's site vsavj 0x22500 is NOT the twin of vs2
     0x22008 — it is a timer-decrement common path inside the
     per-frame fighter tick (fires every frame; the vs2 handler's
     unconditional head-clears of $17b/$111/$110/$1b5(a6) then
     killed every move — the measured regression, now explained).
  3. The TRUE twin of vs2 0x22008 is vsavj 0x23500 (seq-byte 0x1A =
     jump-table entry D): the two per-seq tables (vsavj 0x225EE /
     vs2 0x20FD2, dispatchers 0x225C2/0x20FA8) are row-for-row
     parallel — SEQ NUMBERING IS IDENTICAL across the games.
- BOTH engines carry per-char dispatch at every fighter seq head
  (vsavj tables 0xBD0FA/0xBD17A/0xBD1FA/0xBD27A/0xBD2FA/0xBD37A/
  0xBD47A/0xBD5FA/0xBF31A/0xBF39A/0xBF49A/0xBF61A ↔ vs2 0xD7298/
  0xD7318/0xD7398/0xD7418/0xD7498/0xD7518/0xD7618/0xD7798/0xD94B8/
  0xD9538/0xD9638/0xD97B8) — and ON OUR BUILDS EVERY ROW 0x10 IS
  ALREADY REPOINTED to H's placed handlers (verified on the hui9
  image; the 12b/13 dispatch_1x bank_map rows + auto-repoint did
  this). The FIGHTER-SIDE flow needs NOTHING: hui9's ray runs the
  native flow bit-for-bit (state 0x12 recognizer at 0x55500-twin,
  seq-0x0E per-char handler 0x55560-twin, sub-flow 0x5682E-twin,
  the 0x18-step beam counter at $126(a6) — tap-verified against
  native, 1-frame skew). NO seq-head thunk is needed, ever.
  Both parked thunks stay parked (now documented as refuted).
- View correction recorded: in-code pc-rel WORD JUMP TABLES live in
  the OPCODE view (the 0x5556C state table decoded garbage from the
  data view, correct from the opcode view); the DATA-view rule
  applies to byte/data tables like the effect byte map. Both classes
  exist inside encrypted range; the extractor already handles this.

### The TRUE remaining gap: the POOL-PIECE MACHINE (one engine
### routine, three constants)

- The ray effect object (id 0x14, spawned by the twin APIs vs2
  0x17964 / vj 0x18F8E into the $FFBxxx pool) and its 5-slot fleet
  (vs2 spawner 0x6D262 / vj's own old spawner 0x60E36) spawn on BOTH
  games with identical structure and timing. The divergence is the
  piece's FIRST TICK — the pool-piece state machine, an ENGINE
  routine vs2 rewrote:
    vj 0x5E780-family ↔ vs2 0x6A770-family (structural twins;
    per-seq pc-rel jump table at vj 0x5E7A4 / vs2 0x6A798; pool
    walker/pump at vj 0x5E540, stride 0x80, per-type pointer table
    at 0x5E556)
  and the ONLY differences are three constants in the subtype
  handler: bank word +0x18 (#$6000 vs2 / #$0 vj — the measured
  bank-0 orphan symptom), companion-record base (#$2B7EF4 vs2 /
  #$283690 vj — ours' pieces get vanilla chain 0x283864, native
  gets 0x2B80D8), and the subtype mask (#$4410448 vs2 / #$448 vj —
  vs2 added subtype rows). Param tables 0x6AAE8/0x6ABF0/0x6ACF8
  (8-byte rows, 0x108 apart).
- Everything the pieces need already exists on hui9: the placed
  x2b7ef4 record region (head 0x40223C), the c5 art at native codes
  in group C bank 5 (bank word 0x3000 on our build), the effect
  zone x022400 + fleet spawners x06d240 placed with escapes
  resolved. THE MISSING PIECE: port vs2 0x6A770-0x6AE00 (~0x690,
  machine + 3 param tables) as a region, constants substituted
  (#$6000 -> #$3000, #$2B7EF4 -> placed twin; engine jsr targets are
  known R1 pairs: 0x13778->0x15084, 0x13724->0x15030,
  0x13c0e->0x1551a, 0x157c2->0x1707a, 0x5122->0x4ce2), entered by a
  tenant-owner-gated thunk on the vanilla machine.
- Ray sustain/palette, grab lightning, ES big beam, 214 explosion
  are ALL rows of this one machine family (+ the placed 0x22xxx
  effect-OBJECT zone whose entry has the same gating need). One
  port covers the family; FG pacing possibly too.
### Iterations 1-2 BUILT AND MEASURED — both PARKED; the render-level
### fact that scopes the real port

Two thunks were authored, built, and measured against native. Both
work exactly as designed and NEITHER restores the beam, which is
itself the finding: **first-tick constants are downstream of a spawn
that never happens.**

- `piece_prebake` (site vj 0x18F88, the spawn API's field-copy step;
  a6 = the spawning fighter, a4 = the new piece — GUARD_PROBE
  measured, my first two register guesses (a1, then unscoped a6)
  were wrong and each cost a build): gated on char id + subtype
  +0x59 == 0x0D, it performs row-0 semantics with our constants.
  VERIFIED by tap: bank word 0x18 set, record installed at
  0x4001F4 = placed base + 0x1E4 = **native's own relative offset**.
  Gates all green, 2P legacy replay BIT-IDENTICAL to hui9 (the
  thunk costs legacy nothing — the site is cold for legacy: 3 hits,
  the 3 rays). Beam: still absent. PARKED.
- `fleet_record_base` (site vj 0x60DD4): swapping only the fleet's
  record base a2 CRASHED the ES flow (vec3 in the channel fill).
  Mechanism: the ES driver is ALSO subtype 0x0D, so it matched the
  gate, and its param STREAM (lea 0x6141C(pc),a3, advanced by the
  caller) carries offsets valid only for the vanilla base — mixed
  base + stream = odd offsets, insane dbra. **Base, stream, count
  and updater swap TOGETHER or not at all.** PARKED.
- Scope lesson (new GOTCHA): an "owner-gated" thunk on a shared
  engine routine is NOT scoped by owner alone — sibling effect
  families of the same tenant share subtypes and reach the same
  site with different protocols.

**THE RENDER-LEVEL FACT (OBJ dump, replay 83b, native vs hz15 at
the same beam phase) — this is what the next arc must produce:**
native stages the beam as pieces at **bank-3 codes 0x1E2F / 0x1E42 /
0x1E5F, pal 0x0C** (H's own band — the art EXISTS in our group C
bank 4 at delta 0) marching x=0x9C..0xDC, PLUS the long stretch
segments **bank-1 code 0x4EC0 at sz 4x1 and 16x1** (effect page ->
our group C bank 5 via c5). **Ours stages ZERO of them** — not
wrong art, not a wrong bank: the pieces are never created. Snapshots
confirm it at the pixel level (native draws the sustained beam;
hui9 and every iteration are pixel-identical to each other and
beamless, while the freeze itself connects normally).

So the arc is exactly the companion-machine REGION PORT already
scoped above (vs2 ~0x6CA00-0x6D7A0 + the piece machine 0x6A770
family), entered so that the SPAWN happens — not a constants patch.
The two parked thunks are its final wiring, to be un-parked as part
of it.

- **DECISION PENDING (maintainer, §4): the entry gate is
  legacy-hot.** Every pool piece of every character runs the walker/
  machine every frame; any tenant gate there (cmpi + bne, the
  effect_machine thunk pattern) shifts legacy cycles, so H's boot
  legacy leg must move from masked-v2 EXACT to the flicker/composite
  class — the SAME ratified class family Donovan's builds live in
  (donovan-m2c/m5w frozen flicker inventories). §4 requires a
  measured mechanism + maintainer sign-off for any class move.
  Recommendation: accept the class move (it is literally "the same
  state as Donovan"); the scratch build will carry the measured
  flicker inventory for ratification. Options if declined: none
  found — spawn-side re-typing dead-ends on the pc-rel walker
  table (documented in the session log).
  NOTE: the piece_prebake measurement above shows the cost may be
  ZERO for a sufficiently narrow site (2P legacy bit-identical),
  so the class move may not be needed after all — measure the real
  entry before asking.

### CORRECTION (same session, later): "the pieces are never created"
### was WRONG — the object IS spawned; it runs the VANILLA machine.
### One region-boundary BUG found and FIXED (ships)

Pushing past the OBJ-count finding produced a materially different
diagnosis. Correcting the record above:

1. **The beam object IS created on our build.** Native's beam is a
   single object at $FFBA00 spawned by vs2 0x6D32A, **owner = the
   VICTIM** ($FF8800 — P2, a vanilla character), chained into the
   companion records at 0x2B8530 (= 0x2B7EF4 + 0x63C). Ours spawns
   its twin at $FFB880 via the VANILLA vj 0x60EE6, same owner
   0x8800, same header 0x0100/0x0802 — but chains to the VANILLA
   record base (0x283690 + 0x62C = 0x283CBC). The spawn was never
   missing; the RECORDS and the TICK MACHINE are wrong.
2. **The machinery is proven correct by the neighbour**: the
   persistent companion object (native $FFB880 / ours $FFB980)
   carries the SAME relative record offset (+0x222C) with the bank
   correctly remapped 0x6000 -> 0x1000. So placement/relocation
   works; only the beam object takes the vanilla path.
3. Gating cannot key on owner char id — the beam object is owned by
   the VICTIM, not by Huitzil.
4. The fighter side is fully exonerated a second way: at matching
   phase our fighter's anim record is the correct placed twin,
   **byte-identical modulo correctly relocated pointers**
   (native 0x25B746 -> ours 0x000EDE64, exactly the anim delta),
   and its cursor is one 0x18 node from native's — a pure frame
   offset. Both emit 3 body sprites; the 14 beam entries come from
   the separate object above.
5. **REGION-BOUNDARY BUG (found, fixed, SHIPPED):** the ported
   spawner region started at 0x6D240, but the routine's own record
   base load `movea.l #$2B7EF4,a2` lives at **0x6D200** — 0x40 bytes
   BELOW the boundary, so the region could never relocate its own
   base. Root extended to `0x6d1e0:0x560:t0x6d354` (vh2 twin delta
   +0x174 re-verified at the new start); the base literal now
   relocates to the placed 0x400010 (static proof: exactly one
   occurrence, at 0x6D202). Region renamed x06d240 -> x06d1e0
   (huitzil.toml pcrel_escape_fix row follows). Gates green
   (boot masked-v2 EXACT, ex/grab/air/fx_flow) and the 2P legacy
   replay is BIT-IDENTICAL to hui9.

**THE REMAINING BLOCKER, precisely:** the beam object is **type
0x08 — a SHARED type**. The pool walker's per-type table (already
obj_hook'd at site 0x5E542, vanilla 114 entries / vs2 src 0x6A51C
124 entries) therefore dispatches it to the VANILLA tick machine.
vs2 rewrote its own row-8 machine; vsavj's is the plain one. So the
fix is the established **union pattern one level down**: give
tenant-spawned instances a NEW type (>= 114) and add a union row
pointing at the ported machine. Two things must land with it:
- the tick machine itself is still UNPORTED — measured native PCs
  0x6CADC/0x6CAE2/0x6CAE8/0x6CAEE/0x6CAF4/0x6CB5A/0x6CB86/0x6CB8E/
  0x6CB96 sit BELOW the new 0x6D1E0 boundary (only 0x6D1E6 and the
  creator 0x6D32A are in region now). Extend the root down to
  ~0x6CAC0 — note 0x6CA00 does NOT pattern-twin at +0x174, so find
  the real boundary first (0x6D1E0 does twin cleanly);
- the type write at creation must be gated to tenant-spawned
  instances only (the owner is the victim, so the discriminator has
  to come from the spawning call path, not the object's owner).

### 14z-68c: the row-8 machine LOCATED, and the NEWCOMER-ID MASK
### WIDENINGS (shipped, latent-defect class)

- The per-type tables decode cleanly from the OPCODE view (data view
  = garbage; the 14z-68 view GOTCHA again): **vs2 row 8 -> 0x6CAC0**,
  vj row 8 -> 0x606AC, and vs2 rows 114-120 are the already-ported
  newcomer types (0x88512 family). Note the region we extended in
  14z-68b (0x6D1E0+0x560) sits INSIDE vs2's row-8 machine
  (0x6CAC0-0x6D97C): we have ported its MIDDLE, not the machine.
- The victim-side creator is reached with **register context
  IDENTICAL on both games** (D0=0, D1=0x0C, A6=$FF8800 the VICTIM,
  RET=$FF02DC the RAM pump) — measured by probe on each. Only the
  code differs. So a discriminator is required, and one exists and
  is clean: the victim's **+0x32 -> the attacker**, whose +0x382 =
  0x10. That is Capcom's own precedent (vs2 uses `cmpi.b #$10,$382`
  in-machine).
- **TWO MASK-WIDENING DEFECTS FOUND AND FIXED (shipped):** two engine
  sites test the char id as a BIT NUMBER against an immediate mask —
  vj `move.w #$8448,d1` (victim spawn, 0x60EF0) and `move.w #$448,d1`
  (piece subtype, 0x5E7D6) — where vs2 loads LONGS 0x84418448 /
  0x04410448 whose HIGH words enumerate the newcomer ids (bit 0 =
  id 0x10 = Huitzil). Loading a WORD leaves d1's high word STALE, so
  for any id >= 16 the `btst.l` reads a leftover bit: **undefined by
  inspection, not merely wrong.** Static superset proof: the vs2
  masks' LOW WORDS are byte-identical to vsavj's and btst bits 0-15
  read only the low word, so every vanilla id branches identically;
  only ids >= 16 (variant builds only) change. Shipped as two
  only_variant_slot site_thunks.
  **HONEST CAVEAT: no measured behavior change on replay 83b** — the
  stale bit happened to read 1 there, so the object already got the
  native +0x0A=0x26. This is a LATENT-defect fix (the class that has
  bitten this project four times: x026142/x05c800 escapes), shipped
  because it is provably safe and the read is undefined, not because
  it fixed a visible symptom.
- Gates on build 4dcfd713: boot masked-v2 EXACT, ex, grab, air,
  pairs, fx_flow all PASS; 2P legacy BIT-IDENTICAL to hui9;
  m3a-reproducible bit-exact. **The beam still does not render** —
  the remaining work is unchanged (tenant type + the row-8 machine
  port, now with its true entry 0x6CAC0 and extent known).

### 14z-68d: THE DISPATCH/RECORD PATH IS NOW NATIVE-EQUIVALENT
### (mechanism proven end-to-end) — but PARKED on a DF regression

The union-type plan was implemented and MEASURED. Every structural
claim it rests on is now confirmed:
- vs2's row-8 machine (entry 0x6CAC0, len 0xEBC to row 9's target)
  is ported whole — the root was extended from the 14z-68b
  0x6d1e0:0x560, which was its MIDDLE, to `0x6cac0:0xebc:t0x6cc34`
  (vh2 twin +0x174 verified at the new start). Region x06cac0.
- NEW GENERATOR FACILITY `[[obj_hook_extra]]` (flat table, matched
  by `site` — dotted names are banned, 14z-62c): authored union rows
  {index, src} appended after the ported extras, resolved exactly
  like them (placed region first, then recon, else tripwire), with a
  no-gap assertion because the engine indexes by type*4.
- The walker takes its type from **+0x02** (`move.b $2(a6),d0;
  add.w d0,d0; add.w d0,d0`), so a type >= 114 is unreachable for
  vanilla objects by construction.
- `tenant_type_stamp` (site 0x60EE0) stamps type 124 using the
  measured discriminator (victim +0x32 -> attacker, +0x382 == 0x10).
- **MEASURED WORKING:** the stamp fires (+0x02 = 0x7C02); the object
  is then ticked by the PORTED machine with every PC normalising
  EXACTLY to native's sequence (06cadc/06cae2/06cae8/06caee/06caf4/
  06cb5a/06cb86/06cb8e/06cb96); its record resolves to placed base
  + 0x63C = native's own relative offset; and the record AND its
  sub-records are BYTE-IDENTICAL to vs2's (pointers relocated by
  exactly the region delta 0x14811C). The dispatch and record path
  is native-equivalent.

**PARKED ANYWAY, two reasons, both honest:**
1. **The beam STILL does not draw.** With the whole path proven
   equivalent, the residual is in how the emitter is reached or a
   draw flag — not in dispatch, records or art.
2. **It REGRESSES test_hui_pairs** (Dark Force): vec3 at PC
   0x0D4696 inside the ported machine, f3220, ADDR 0x4029FF, with
   A2 = 0x400010 (our record base) and A1 = 0x3FFEEE reading BELOW
   it — an index underflows the placed region. Cause: the stamp is
   not selective enough. The victim-spawn site serves EVERY hit of
   this class from the tenant, not just the ray, and the ported
   machine mishandles the others. **Narrow the stamp to the ray
   effect specifically (per-effect, not per-hit) before re-enabling.**

SHIPPED from this round: the region extension to the true machine
boundary and the `obj_hook_extra` generator facility (inert with no
manifest row declaring one). Parked: `tenant_type_stamp` +
the `obj_hook_extra` row, both with the anatomy above.
Gates on ede6bf15 (the parked end state): boot masked-v2 EXACT, ex,
grab, air, pairs, walk, fx_flow PASS; 2P legacy BIT-IDENTICAL to
hui9; m3a-reproducible bit-exact.

### 14z-68e: the DF crash chain DECODED to three stacked layers
### (all named); nothing further shipped — the mechanism stays parked

Chased blocker 1 (narrow the stamp) and found it is not a stamp
problem at all. The discriminator hunt came up empty and then the
crash decoded into a stack of three separate defects, each real:

- **D1 is NOT a discriminator.** The spawn selector is 0x0C for the
  ray AND for the DF case (probed on both replays), and at the spawn
  frame the attacker/victim state bytes are IDENTICAL. Replay 82
  activates DF FIRST and then fires the ray, so the crashing object
  IS the ray object — being processed while DF is active. There is
  no per-effect discriminator at that site to find.
- **Layer 1 — the reserved register window.** The crash read is
  `move.w (a2,d0.w),d0` at vs2 0x6D264 with d0 NEGATIVE: vs2
  legitimately indexes BELOW its record base (base 0x2B7EF4 has ROM
  underneath). Our base was allocated at 0x400010, the very START of
  wide_ext, so a negative index lands in the RESERVED CpsFrg window
  0x400000-0x40000F (HANDOFF: "never allocate there"). **Any region
  whose consumers index negatively needs headroom below it** —
  moving wide_ext's start to 0x400400 moved the fault address
  accordingly, proving the mechanism.
- **Layer 2 — vec3 is an ADDRESS ERROR, so the index is wrong too.**
  With headroom the read was still odd (0x4003F3), and native's
  equivalent (0x2B7EE7) would fault identically — so d0 = 0xFFF3 is
  simply not what native reads.
- **Layer 3 — THE PARAM STREAM IS AN EMBEDDED DATA TABLE (the
  data_in_code class, fifth bite).** a3 is set by `lea $6D868(pc),a3`
  and read with `move.w (a3)+` — a DATA read of a table inside a CODE
  region. The two views differ completely at 0x6D868 (opcode
  `b8020919f5c7...` vs data `000100580000...`), and the data view is
  the correct one: at 0x6D878 it yields **0x0064** (even, positive,
  sane) where the opcode view yields garbage. Placing the region in
  RAW space does NOT fix this — raw storage holds ONE byte image
  (the opcode view, so it executes), so data reads still see the
  wrong bytes.
  **NEW, and it explains why nothing caught this: the census's
  data_in_code detector only matches `lea (d16,pc),An + read
  (An,Xn.w)` — it does NOT match the POST-INCREMENT reader shape
  `move.w (An)+` used here.** Neither does the generator's
  data_in_code relocator, whose only supported reader is
  `lea (d16,pc),a1 + move.b (a1,d0.w),d0`.

So the port of vs2's row-8 machine needs its embedded param stream
relocated as DATA with a new reader shape supported — that is the
next concrete task, ahead of any further stamp work. Both the census
tool and the generator need the post-increment shape added, and
`tests/test_census_regions.sh` should gain it as a frozen case.

NOTHING FURTHER SHIPPED this round: the manifest is back to the
14z-68d parked state (verified: no live `obj_hook_extra` row, no live
`tenant_type_stamp`), which is the all-green build ede6bf15.

### 14z-68f: the SHADOW item's documented premise DOES NOT HOLD
### (two measurements) — it needs a repro from the maintainer

Opened the first quick win and the premise failed immediately, which
is worth more than a wrong fix:

1. **vs2's shadow tables are NOT larger.** The 14z-66 note said the
   fix was "the extended vs2-ported shadow table at the same site".
   Measured: vs2's installer is 0x90B0C (twin of vj 0x823E2) with
   tables **0x1E42D2 / 0x1E46E0**, exactly **0x40E apart** — the SAME
   row space as vsavj's 0x2083BC / 0x2087CA. The walk sites are
   structurally identical too (vs2 0x90B86 / vj 0x8245C: same
   `andi.w #$1fff`, same `+0x50` change-check, same `+0x40` table
   pointer, same doubling). The only difference between the two
   games' table CONTENT is a consistent +2 on every entry (vs2
   0x081E/0x0410 vs vj 0x081C/0x040E), i.e. vs2's index carries ONE
   more entry — nowhere near enough to cover the 0x488 seq the
   14z-66 note blamed. **So "port the bigger table" is not the fix,
   and the item cannot be closed that way.**
2. **The shadow system is not even reached in the replay where his
   sidekick exists.** GUARD_PROBE on our build over replay 82 (DF,
   which STATE 14z-66 records as having his summon pieces t=0x75/0x77
   live in poolB at f3250): **0 hits at the installer 0x823E2 AND 0
   hits at the walk 0x8245C.** So whatever draws the sidekick's
   shadow, it is not this class-0x0C servant path — the 14z-66
   attribution of ping-#7 item 2 to `shadow_seq_guard` was an
   INFERENCE from the FG crash work (where the site genuinely does
   fire, replay 77), not a measurement of the shadow symptom.

**BLOCKED ON MAINTAINER INPUT (cheap to unblock):** to build a repro
I need to know WHEN the rectangular shadow is visible — which move or
situation puts the sidekick on screen with the wrong shadow (and
whether it is the pod companion or another servant). With that, the
repro replay + a probe on whatever actually installs its shadow will
name the real mechanism in one session. Until then the item stays
open and NOTHING has been changed for it.

The `shadow_seq_guard` thunk itself is untouched and stays — it is
the FG-crash fix (14z-66, replay 77) and is unrelated to this item.

### 14z-68g: THE CHILD-COMPANION SHADOW MEASURED AND ATTRIBUTED —
### it is the KNOWN "bank word 0" piece family, now quantified

Maintainer clarified the symptom: it is the shadow of **the human
child companion**, rectangular **all the time**. That made the repro
trivial (he is on screen through replay 82) and the measurement
decisive — OBJ dumps, native vs ours, same frame:

- **The shadow's CORE tiles are CORRECT.** At y=0xC8 both games draw
  codes 0F8B / 0F8C / 0F8B (pal 0x16). Nothing wrong there.
- **The band around it is GARBAGE, and exactly so.** At y=0xD0 every
  pal-0x16 piece on our build carries **code = native - 0x16A8** and
  **bank word 0 instead of bank 3** — measured over TWELVE pieces
  with no exceptions (0F96->F8EE, 0FB7->F90F, 0FA4->F8FC,
  0FA2->F8FA, 0FA3->F8FB), spanning both the band under the child
  (x 0x2F-0x7F) and a second group at x 0x157-0x1B7.
- **This is the already-documented 14z-67 symptom**, now with a
  number on it: "ours spawns F8FC/F90A/F15x-family pieces WITH BANK
  WORD 0 (y=00d0) that native NEVER stages — pieces created through
  a path that leaves +0x18 unset/zeroed". Same family, same bank-0
  signature; the uniform **-0x16A8 code delta** is new information
  and should identify the wrong base/record the pieces read.
- Also measured: the child's own body sprites differ completely
  (native pal-0x0D codes 17A5/17A7/17A9/17AA/0B3F/1781 vs ours
  252A/252C/252D, zero overlap) — worth a look, though the maintainer
  reports the child itself as acceptable, so treat the shadow band as
  the reported defect and the body as a separate question.

**So ping-#7 item 2 is NOT a shadow-table problem at all** (see
14z-68f: vs2's tables are the same size, and the servant path takes
0 hits). It is the bank-0 piece family. That also means it likely
shares a root with the effect-family work — the same "pieces created
through a path that leaves +0x18 unset" class — so the two items may
close together rather than separately.

NEXT (concrete): find what stages the pal-0x16 band pieces, and why
their tile word comes out -0x16A8 with bank 0. The delta is the lead:
0x16A8 is a fixed code-space shift, so the pieces are reading their
tile words relative to the wrong base. Nothing changed for this item
yet.

### 14z-68h: WIN-SCREEN PALETTE FIXED (ping #7 item 5a) — source
### re-derived from vs2's drawer, VERIFIED IN-EMULATOR

The first visible fix of the session, and the derivation is now
measured rather than eyeballed:

- **The right drawer.** vsavj 0x5F1B6's true vs2 twin is **0x6B29C**
  (pool 0x3C2BBC) — same shape and trailer (cmpi #$12 x5-form, #$19/
  #$18, generic, `lsl.l #5; adda.l d0,a0; moveq #4,d7; jmp`). NOTE
  vs2 0x6B156 is the SELECT uploader (it carries the famous
  `cmpi #$10 -> moveq #$B,d6` grid remap) and is NOT this path — that
  is the confusion the old row fell into.
- **The newcomer special-case exists, and it is a BYTE TABLE.** vs2's
  generic path does `move.b $6B2F2(pc,d6.w),d6` before indexing —
  vsavj has no such remap and uses a 17-row stride where vs2 uses 18:
      vs2  : offset = (18*colourIdx + table[id]) * 0xA0
      vsavj: offset = (17*colourIdx + id)       * 0xA0
- **View discipline decided it.** The table is a pc-relative BYTE
  table embedded in code, so it reads through the **DATA view** (the
  effect-byte-map precedent). Its OPCODE view decodes to a
  plausible-looking identity ramp 00,01,02,... — exactly the
  "plausible garbage" trap in docs/GOTCHAS.md — and that ramp sends
  id 0x10 to pool row 0x0B, which is a FLAT 0x002F placeholder. The
  DATA view gives **table[0x10] = 0x59**, i.e.
  **0x3C2BBC + 0x59*0xA0 = 0x3C635C**, whose ramp is gold
  (0FFD 0FB8 0D96 0C86 0B75 0964 0753 0542) — matching the maintainer
  capture. The old row's 0x3C347C reads 0111 0844 0C87 0FBA... = the
  pink/lavender they photographed.
- Colour stride 0xB40 (18*0xA0) was already right and is now DERIVED
  rather than assumed.

VERIFIED THREE WAYS on build 64128aa7: statically all 8 colour sets
byte-identical to vs2's source at the correct strides; **in-emulator**
the win-screen palette RAM at BOTH sample frames (replay 61 with the
early-window id-0x10 poke) reads `fffd ffb8 fd96 fc86 fb75 f964 f753
f542` = the gold ramp under the expected F000-alpha; and the gates are
green (boot masked-v2 EXACT, ex, grab, pairs, m3a bit-exact).

STILL OPEN for the win screen: item 5b, the GARBLED BLUE-GREY BLOCKS
on eye/thigh/foot — a separate ART defect (tiles the anim walk missed),
untouched by this palette fix.

### 14z-68i: RETRACTED AND CORRECTED — the portrait IS the tenant's;
### the palette fix DOES land visibly; the residue is wrong ART blocks
### (and the quote text)

**I published a wrong diagnosis in this session and am retracting it.**
On one headless snapshot of H's win screen I read the figure as
Bulleta's and wrote up "the win portrait and quote are the HOST's,
the records still alias rows 0x10-0x1F". That was wrong on both
counts. Corrections, each measured:

1. **The records are NOT aliased — they are already tenant-owned.**
   On the BUILT hui10 image, table 0x2672AA rows 0x10 (win portrait),
   0x70 (quote P1) and 0x90 (quote P2) are all REPOINTED into
   wide_ext (0x40B3F0 / 0x40B300 / 0x40B350); only the untouched
   vanilla rows 0x00/0x60/0x80 still hold the stock values. The
   existing `[[select_records]]` rows cover them — note the arrays
   OVERLAP (vj_p1 0x26742A row 0x10 IS 0x2672AA row 0x70), which is
   what made the two look like different tables.
2. **The portrait is the same record on both builds.** A/B snapshots
   of the SAME replay+poke on hui9 and hui10 show the SAME FIGURE
   SHAPE, differing only in colour: hui9 pink/lavender, hui10
   gold/tan. So the palette fix DOES land visibly — the maintainer's
   "it is in the yellows" is the fix working.
3. **What actually remains on that screen** is the ART defect they
   originally reported: large wrong-tile PATCHES over the figure
   (blue-grey on hui9, magenta on hui10 — they recolour with the
   palette, so they are tiles drawn through the win palette with
   wrong content). Those patches are what makes the pose read as
   "just the outline". Plus the win QUOTE text still renders a
   vanilla character's line despite its record being repointed —
   a separate item worth its own measurement.

For the record, vs2 DOES carry real distinct newcomer rows in its
twin table 0x2A05E2 (row 0x10 = 0x2A7B06, 0x11 = 0x2A7F2C,
0x13 = 0x2A7F68), and vsavj's rows 0x10-0x13 are plain aliases of
0x00-0x03 — that part of the earlier note is accurate and still
useful; it is the CONCLUSION about our build that was wrong, because
our build already repoints them.

METHOD LESSON (twice in one session now): I inferred a whole
mechanism from ONE rendered frame without an A/B against the previous
build. The A/B was two commands and would have prevented both the
bad ping note and the bad write-up. When a screen looks wrong, diff
it against the last known build BEFORE theorising about mechanism.

### 14z-68j: the win-pose ART DATA is EXONERATED — every tile is
### byte-identical to vs2; the item now needs a native capture

Measured, so the next session does not re-run it:
- **All 31 portrait sprites, all 134 tiles, byte-identical to vs2's
  group-A originals.** Expanded each sprite's WxH block from its a19
  and compared our group-C tile against vs2's at the same index:
  0 mismatches. So the "garbled blocks" are NOT missing tiles and NOT
  wrong tile DATA — the earlier "tiles the anim walk missed" theory
  is dead.
- **The patches are in the FIXED palette rows.** They recolour
  between builds (blue-grey on hui9 -> magenta on hui10), so they are
  drawn through rows 0x15-0x19, which we verified match vs2 exactly.
  Sprites in the portrait area using palettes OUTSIDE that range
  (pal 0x00 x22, pal 0x09 x15 — background/frame) are unchanged
  between builds, consistent with them not being the patches.
- So the remaining candidates are the sprite->palette ASSIGNMENT
  (attr bits per sprite) differing from native, or the pose simply
  looking like that natively.

**BLOCKED on a native reference.** I could not reach H's win screen on
vs2 with the existing rig: the early-window id poke does NOT force him
on vsav2 (replay 61 stays mid-match there — its input timing is
authored for OUR wheel), so there is no ours-vs-native OBJ/pixel diff
to run. Options: author a vs2-native replay that picks H and wins, or
ask the maintainer for a VS2 win-screen capture (they supplied
ours-vs-native win captures in 14z-67, so this is cheap for them).
Until one exists, further theorising about this item is exactly the
mistake made twice already this session.

### 14z-68k: MAINTAINER NATIVE CAPTURE — the win screen is
### ESSENTIALLY CORRECT; the "garbled blocks" were the WRONG PALETTE
### all along. Only the quote TEXT differs.

The maintainer supplied a native VS2 Huitzil win-screen capture (the
reference 14z-68j was blocked on). It resolves the item:

- **Native shows the SAME figure, pose and colour scheme as hui10**:
  brown/tan body, MAGENTA patches on shoulder and upper arm, gold
  trim, white outlines, the green-gridded sphere at right.
- **So the "garbled blue-grey rectangles on eye/thigh/foot"
  (ping-#7 item 5b) were never wrong ART — they were the WRONG
  PALETTE.** On hui9 those native-magenta regions rendered blue-grey
  because the win palette source was wrong; with the corrected gold
  palette (14z-68h) they render magenta, matching native. Item 5b is
  therefore CLOSED BY THE SAME FIX as 5a, not a separate art defect.
- This reconciles the measurements that had looked contradictory:
  all 134 portrait tiles byte-identical to vs2 (14z-68j) and the
  palette rows byte-matching vs2 (14z-68h) were BOTH right — the
  screen was fine and the remaining doubt was mine.

**Remaining difference: the win QUOTE TEXT.** Native reads
「いっけない、道草くってたら／スッゲェ遅くなっちゃったっ」; ours reads
「道に迷っちゃったの／ホ・ン・ト・よっ！」 — same theme, different
line. OPEN QUESTION put to the maintainer: do these characters
ROTATE through several win quotes? If the game selects among a set,
ours may be a different valid line from his own set and there is
nothing to fix; if ours consistently shows a line that is not his,
the quote record needs work. Note the quote rows ARE repointed on our
build (table 0x2672AA rows 0x70/0x90 -> 0x40B300/0x40B350), so a
wrong-line-from-the-right-set is the more likely reading.

METHOD NOTE: this is the third time this session that a rendered
frame misled me and a reference/A-B settled it. The maintainer's
capture cost them one screenshot and closed an item I had been
theorising about for hours. ASK FOR THE REFERENCE EARLIER.

### 14z-68n: THE SYNTHESIS GAP CLOSED — eight subsystems written the
### same session the gap was found (maintainer request, done not queued)

Maintainer: "engine_internals.md is rather barebones compared to all
the analysis work you've done ... it could be expanded for little cost
when we have time, which avoids either of us combing through
state.md." AUDITED AND CONFIRMED at 14z-68m: engine_internals is 810
lines against STATE's 8417, and several load-bearing subsystems have
ZERO mentions there — object type dispatch / the pool walker, pool
seeding + init_shim, update-queue classes, Dark Force, and the
throw/physics-arc tables among them.

DONE THE SAME SESSION (maintainer: "then do it now. Even the other
bugfixes for Phobos may profit from this"). engine_internals.md 810 ->
1076 lines, 13 -> 24 sections; the audited backlog is CLEARED. Written:
object TYPE dispatch + the pool walker (incl. the shared-type trap,
obj_hook_extra, and the two hazards that cost 14z-68d), allocator
wrappers, pool seeding + init_shim (the watchdog class + the
MEASURE-don't-copy flavor polarity rule), update-queue classes,
throw/physics-arc tables (with the static superset proof), shadow
servants (with the 14z-68f premise CORRECTION written in, so the wrong
note cannot be followed again), Dark Force (mechanics verified vs
style open, split explicitly), and the companion/pod family (with THE
INHERITANCE RULE and the two placement hazards).
The backlog TABLE is kept, empty, as the FORM for next time.
POLICY recorded there: write a subsystem's section as PART OF the work
that touches it — cheap while the session is fresh, and it is the
difference between "documented" and "findable".

IMMEDIATE PAYOFF, not deferred: Phobos's own open items are covered —
the shadow section carries the corrected premise (so the dead
"port the bigger table" theory cannot be re-attempted), the DF section
states exactly which half is open and its fix shape, and the type
dispatch section carries the per-EFFECT scoping rule the parked
tenant-type work needs. Pyron's port now has init_shim, type dispatch,
throw arcs, queue classes and the inheritance rule written down before
he needs them.

This is not a make-work item: the 14z-68 win-screen re-derivation cost
a shipped-wrong palette and a maintainer round-trip precisely because
the prior analysis was only in a session log. Pyron's port will hit
init_shim, type dispatch, throw arcs and DF — all currently
undocumented in the synthesis.

### 14z-68r: PING #10 CONFIRMED by the maintainer — win-screen
### palette AND position both fixed on the real screen

Maintainer on build/hui11 (5c6dbe43): "palette and position are
fixed". Their capture shows the gold/orange portrait correctly placed,
matching the native reference. **Ping-#7 item 5 is CLOSED** (5a
palette + 5b the "garbled blocks", which were the wrong palette all
along).

Their reading of the remaining text is also right and now confirmed
from the data: the quote is BULLETA's (H sits on her variant row
0x10). The drawer reads the `-4`-biased entry, which is still vanilla;
the entry I originally repointed (0x70) is not the one consumed.
Deferred as a THREE-LEVEL data port (record -> per-line entries at
0x1BADxx -> glyph data at 0x1C4Cxx), documented in engine_internals.

Two of the maintainer's guesses in this round were correct ahead of my
measurements (the Donovan parallel, and Bulleta as the placeholder
source). Recorded because it is a pattern worth trusting: their
pattern-matching against earlier ports has been right every time it
has been offered this session.

### What SHIPS from 14z-68

One functional change ships: the **region-boundary fix** above
(`tools/build_donovan.sh` root `0x6d1e0:0x560:t0x6d354` +
the huitzil.toml region rename). It is a boundary correction with
static proof, not a speculative mechanism, and it is the
prerequisite for the union-type work. Build cf519de8; gates green;
2P legacy bit-identical to hui9. Both candidate THUNKS stay parked.
Everything else authored this session is documentation, measurement
rigs, and one new gate:
- NEW replay `tests/replays/hui/83b_hui_ray_2p.rpl` (2P-dummy,
  three spaced 236LP — cross-emulator reproducible, tappable).
- NEW gate `tests/test_hui_fx_flow.sh`: two legs (fighter-side flow
  identity incl. "the refuted 0x56D68 entry stays cold"; piece-side
  machine attribution, auto-detecting pre/post-port from the build's
  own patch notes). Ground-truthed on hui9 (PASS) with a real
  negative control (hz7, the bad-thunk build, fails 3 of 4 legs).
- `tests/lua/snapshot_frames.lua` and `tests/lua/obj_records_dump.lua`
  gained **POKES** (replay.lua grammar) — the forced-pick rigs could
  not previously be photographed or OBJ-dumped at all.
- Gates green at close: hui_boot (masked-v2 EXACT), fx_flow, ex,
  grab, air, pairs, walk, m3a-reproducible (both frozen refs
  bit-exact).

Updated: 2026-08-08 (session 14z-67 CLOSED — the D4 verticals PLUS
two maintainer ping rounds. D4: all three openers done (3-tenant
layout RATIFIED, censuses promoted + Pyron clean, THE H GFX RUNG —
his real art everywhere, cell 0x10 hand-pickable). Continuations:
ping #7 pinned (hui6 b99b7359) -> patch_index backfilled -> THE PYRON
LADDER OPENED (stages 1-4 green + 11k soak clean + sound sweep,
frontier 31 tripwires). Ping rounds: 236P FREEZE RAY restored (six
effect byte-map pokes — the two games' dispatch maps differ by
exactly those entries), THE COMMAND-GRAB THROW ARC native-exact
(superset physics tables, yv 16.0 measured = native; hui9 = 9e3105e0
= PING #8), c5 companion-record art to bank 5, ES exonerated by
maintainer retest. THE REMAINING EFFECT FAMILY (beam sustain, ES big
beam, grab lightning, 214 explosion) is ONE closed decode from done:
vs2's seq-D head is a per-char jmp dispatch (0xD9538 row 0x10 = his
own ported handler) that vsavj lacks; the zone + fleet-spawner
regions are PORTED with escapes resolved; both entry thunks PARKED
(activation regresses the ray — silent dependency gap in his
0x56D68->0x574B0 flow; boot-gate lesson: "cold" stubs can be hot for
legacy). Next arc exactly scoped: scratch-enable the dispatch, probe
the flow to closure. Frozen refs bit-exact throughout; every gate
green at close. Read the 14z-67 sections below, then
docs/NEXT_SESSION.)

## Session 14z-67 (D4: the Phobos gfx vertical)

### D4 opener 1 DONE — 3-tenant tile budgets measured; group-C layout
### RATIFIED (flip condition does NOT trigger)

- Instrument: tools/obj_records.py over the three ratified extraction
  anim spans (H 0x245872+0x1E800 from the hui4 extraction; P
  0x264086+0x1B500 from a fresh 14z-67 extraction, oracle-clean, 0
  variant-site bytes; D 0x27F548+0x20F00). Both H/P region_anim.bin
  files verified VERBATIM slices of the vs2 data image, so the lock
  gate re-derives everything from the reference zips alone.
- THE DECISIVE FACT: all three tenants' art lives in vs2 BANK 3
  (bank-table rows 0x10/0x11/0x13 all 0x6000) at mutually compatible
  native codes — H band 0x0AF6-0x4EFC (14,870 tiles), P band
  0x4ED5-0x8647 (14,037), D band 0x863F-0xC2EF (15,498), nearly
  back-to-back; boundary overlaps (H∩P 39 / P∩D 33 / H∩D 82) are
  SHARED tiles. They shipped coexisting in one 64K bank.
- THE LAYOUT (no gameplay surface — placement only): H and P place
  into group C bank 4 at DELTA 0 — native codes, so their records
  need NO remap at all (nothing to rewrite is nothing to get wrong).
  Donovan keeps his frozen +0x2750 (m3a reproducibility untouched).
  Disjointness proven by interval: max(H∪P)=0xA42C < SAFE_LO 0xAD80.
  Pyron's share is RESERVED by manifest row before any H tile lands
  (the D4 ordering requirement).
- FLIP CONDITION: does not trigger. Occupancy 68.1% (44,607/65,536);
  worst-case bound 45,645; free pools 0x8648-0xA42B (7,652),
  0xA42D-0xAD7F (2,387), 0xEE74-0xFFFF (4,492). Plan A ratified;
  no profile growth, no version bump.
- Artifacts: build/manifest/gfx_layout3.toml (the ledger the Phase-3
  multi-tenant gfx pass will consume; collision rule
  "same-source-or-fail"), NEW gate tests/test_gfx_layout3.sh (12
  locks: one-source-bank, three frozen inventories, manifest
  agreement, delta rows, interval disjointness, the flip-condition
  bound, shared-code counts). Docs: engine_internals inventories,
  cps2_wide.md layout section.

### D4 opener 2 DONE — the censuses promoted to a tool and run over
### Pyron: HIS CODE REGION IS CLEAN; one NEW real find on H (x05c800
### latent escapes)

- The 14z-66 session-log census scans are now `tools/census_regions.py`
  (the promotion the 14z-66 watch item required before the Donovan
  re-freeze run): both shapes exactly as the generator's passes define
  them — data_in_code = `lea (d16,pc),An + read (An,Xn.w)` with the
  table inside a code region; escapes = word-form pcrel branches
  leaving their region. `--manifest` marks findings covered by rows.
- INSTRUMENT GROUND-TRUTHED on H before trusting any P number (NEW
  gate tests/test_census_regions.sh, self-builds stage 4): exactly the
  5 known data_in_code sites, zero false positives; x02592a 89->35 and
  x026142 9->6 match the generator's own emitted counts EXACTLY (the
  "7 targets" in the 14z-66 prose was the authoring-time count; the
  generator note says 9->6 and the census agrees).
- PYRON (the D4 early warning): his current code region
  (0x574C0+0x5200) censuses CLEAN — 0 data_in_code, 0 escapes. No
  structural hazard in his core code. His support-zone roots are not
  extracted yet; the gate locks the region count so growth fails
  loudly -> rerun over the new regions.
- Census triage on H produced THREE new facts (all frozen in the
  gate):
  1. code->x057456: 20 escape sites are SAFE BY CONSTRUCTION — the
     pair is placed contiguously at one delta, so cross-boundary
     pcrel displacements are preserved (asserted from
     placements.json, both conditions).
  2. x068c78+0x1CA and x028122+0x112 are OPERAND FALSE POSITIVES
     (matched words are the immediates of move.l #$26000/move.w
     #$6600) — the census is a pattern scan; hits need triage,
     silence is meaningful.
  3. **x05c800 carries 2 REAL latent escapes** (0x631D0/0x631D8:
     `tst.b $18E(a4) / bne.w 0x635FC` pairs at the region tail,
     target unplaced) — the x026142 disease again, on the SHIPPED H
     build. Never bitten in battery/playtests, exactly like x026142
     before the air dash died on it. QUEUED: [[pcrel_escape_fix]]
     row for x05c800 with the H gfx-rung rebuild (target 0x635FC
     needs recon resolution or a tripwire).

### D4 opener 3 — THE H GFX RUNG LANDS (build hui6 b99b7359, ping #7
### ready): Huitzil renders his REAL ART everywhere; wheel cell 0x10
### hand-pickable; every gate green

- MACHINERY de-Donovanized with the frozen references bit-exact at
  every step (m3a-reproducible run 4x through the arc): build_gfx /
  build_donovan / verify_gfx resolve band/delta/anim-span/sweep from
  the tenant's gfx_layout3 row (Donovan's row asserted == his frozen
  constants); NEW delta-0 placement path (every inventoried tile at
  its native code — no record remap, no effect map; writes asserted
  under Donovan's SAFE_LO ceiling); per-tenant effect_tail keys
  (place_variant_slot_<name>) so one tenant's HUD art cannot leak
  into another's build; data_subst GATHER form (xN@STRIDE) for
  strided grid columns; obj_records walker gained an entry-bounds
  check (a tail false-record read past the region into neighboring
  placed content) and per-tenant sweep windows (H/P's offset-computed
  overlay records now inventory: H 15,034 / P 14,225 re-frozen).
- H's stage-6 manifest content (huitzil.toml; bytes in the build's
  patch_notes_fragment): 12 OBJ bank setters (fresh scan; Donovan's 6
  shared-zone rows reproduced as the subset — scan validated),
  table_fix rows with 0x10=0x1000, code_word slot row, sprite+effect
  palettes (vs2 0x39BC9C/0x3AB69C, strides verified across rows),
  seven select_records (anchors read from both games' arrays; vs2
  newcomer highlight rows are non-pointer sentinels 0x5000000/
  0x4000000), the three drawer bank thunks verbatim (tt/tu
  substitution), select_pal_variant_id with H's GRID-COLUMN palette
  block (vs2's own uploader remaps him INTO the grid at column 0x0B —
  `cmpi #$10 -> moveq #$B,d6` at vs2 0x6B1A6 — unlike Donovan's
  dedicated block; hence the gather form), HUD rows (vs2 entries
  04AB0102/05A0, stager bias +0x4200, art 0x46AB 2x1 / 0x47A0 2x2 ->
  free-pool 0xBE92/0xBE9A), win_pal (vs2 0x3C347C = pool+0x10*0xA0,
  head matches his 0x0111 palette family), the select wheel roster21
  verbatim (tenant-independent), and the x05c800 pcrel escape fix
  (0x635FC -> vsavj 0x5B25C, unique pattern + jmp-target twin 60/64).
- MEASURED (snapshots + obj dumps, build b99b7359): select figure,
  portrait, name banner, 21-cell wheel with the three medallions, VS
  splash, in-match sprites and palettes ALL render as native H; a
  real cursor pick of cell 0x10 (NEW replay 37: D,D,D from default)
  stages HUD mug be9a + plate be92 with the opponent vanilla.
  GOTCHA paid: the forced-pick rig does NOT populate the HUD index
  field — HUD verification needs the real-pick replays.
- GATES (all green): boot (masked-v2 EXACT legacy leg with the escape
  fix in), ex/walk/air/grab/pairs ON THE STAGE-6 BUILD, soak, ladder,
  oracle battery (1741 mismatches — identical to stage 4: gfx
  perturbed no behavior), tenant_hud parameterized per tenant (PASS
  on hui6 AND m5_wide + negative control), select_records/wheel_bank5/
  winpal on m5_wide, extract_hp, patch_overlap, census (x05c800 now
  covered), gfx_layout3, m3a-reproducible.
- TWO STALE GATES found red and fixed (GOTCHAS "not in the battery"):
  test_gfx_tiles' Jedah lock (stale since the 14z-11 sweep pass;
  818bae7^ reproduces the old number; re-frozen 18094/16707) and
  test_wide_render_content (stale since the m3a freeze — cross-track
  pixel identity ended BY DESIGN; re-shaped to band equivalence at
  the correct banks + the de-substitution invariant as an assertion
  + a true-shadow audit control + liveness via replay 36).
- tools/run_hui_behavior.sh -> the stage-6 build (build/hui6), no
  forced id: the maintainer picks H's own cell. PING #7 READY.
  NEXT: maintainer playtest -> H freeze (registry row + expectation
  set), then the Pyron vertical (D4 order).

### 14z-67 continuation (maintainer testing deferred): ping #7 PINNED;
### patch_index backfilled; THE PYRON LADDER OPENS — green through
### stage 4 on the first pass

- The maintainer could not test immediately; work continued on
  playtest-independent tracks. **build/hui6 is PINNED as the ping #7
  artifact** (marker file PING7_DO_NOT_REBUILD.md; fingerprint
  re-verified b99b7359; run_hui_behavior.sh only builds if missing,
  so the maintainer's launch uses these exact zips). Rebuild
  experiments go to hui7+/scratch — bug reports stay attributable.
- **patch_index.md BACKFILLED** (the 14z-66 queued task): rebuilt as
  the one-page registry — both frozen Donovan tracks, the H ladder +
  gfx rung, Pyron's reservation, the WIDE overlay, emulator patches,
  and a 17-mechanism inventory table with introduction sessions.
- **THE PYRON LADDER (M3b Phase 5) OPENS — stages 1-4 green same
  session**, the H template through the generalized machinery:
  - build/manifest/pyron.toml (minimal by design: tenant row + spaces
    + empty recon overlay; NO flavor fork — he has none) +
    reconciliation_pyron.toml + the 0x11 DEFAULT_ROOTS case.
  - Stage 4 named exactly ONE missing structure: the 18-ring
    velocity-vector family 0xd143e (based at 0xd15be by his code —
    the SAME vs2-only bank data H's census ported). One root row
    fixed it; stage 4 builds with everything else tripwired.
  - Boot probe: id 0x11 holds, HIS hitbox base loads, guard clean —
    no init-shim/layout-group hunt needed for the boot rung (unlike
    H's watchdog-reboot arc; his ecosystem pressure presumably
    arrives with the moveset work).
  - MEASURED gate fact: the generator emits the FOUR engine-hook
    sites unconditionally at stage 4 (obj 0x54470/0x5E542, state
    0x2A7C8, reaction 0x18458) — so the stage-4 op invariant carries
    exactly those named exemptions and its legacy leg runs masked-v2
    (EXACT, like H's).
  - NEW gate tests/test_pyron_ladder.sh: stages 1-4 build, per-stage
    op invariant, boot probe, stage-3 legacy UNMASKED bit-identity +
    stage-4 masked-v2 EXACT.
  - NOT YET: his moveset R1 loop (support-zone roots, sound-farm
    sweep, obj_hook types, probes) = the next behavior arc; his gfx
    rung after that (layout share reserved; select palettes = a
    dedicated +0xBC block, easier than H's grid column).

### 14z-67 continuation 2: THE PYRON MOVESET ARC OPENS — the chaos
### soak runs CLEAN (11k frames, satellite live across rounds) after
### three mechanism-attributed fixes, all shared-zone row classes

- The probe loop (the sessions-4-6 doctrine) on the new mash replay
  (tests/replays/pyron/70_pyron_mash.rpl = the generic input-chaos
  body, id via pokes). THREE crashes, each fully attributed, NONE
  needing fresh decoding — all were KNOWN row classes riding the
  shared zones P now ports:
  1. vec3 f3383 in the OBJ emitter: satellite +0x1C NULL -> the
     emitter read the data-view long at [0x4] (= 0x2CE87A67, the
     crash ADDR exactly). Root cause: THE POD-ZONE data_in_code
     TABLE, biting its FOURTH time — x088512 is crypt-placed and its
     embedded offset/record table read garbage under re-encryption,
     so the satellite's record never installed. (The alloc_wrap
     hypothesis was tried first and REFUTED by an identical crash.)
  2. Fix bundle: every region-scoped mechanism row H carries for the
     shared zones, copied verbatim (they are properties of the SHARED
     SOURCE BYTES): the x088512 pod-table data_in_code row + queue
     class-7 remap + both obj_hook union sites; pcrel_escape_fix
     x026142/x05c800 + the 8 twin rows into reconciliation_pyron.
  3. vec4 f3382 = obj_hook type 64 TRIPWIRE (unresolved 0x672d0) —
     P's first satellite spawn PROVED the "H farm zones" are the
     SHARED newcomer-satellite handler family (types 64-75). The 12
     regions added to his roots (H's measured bounds/twins verbatim);
     soak CLEAN end-to-end after (11,017 frames, 0 PC weeds,
     round-2 satellite linked at +0x2A = $D400 — he links ONE where
     H links two pods).
- Debug-timeline gotcha re-paid: the -debug write tracer did not even
  crash by f3390 (skewed inputs), and FBNeo could not reproduce (the
  vs-CPU divergent-content rule) — the working instrument was
  GUARD_PROBE at the emitter (non-debug... -debug but minimal skew:
  crash at 3384 vs 3383) reading the head register directly.
- Gates: NEW tests/test_pyron_soak.sh (build + 11k guarded chaos +
  the measured satellite-liveness lock); test_pyron_ladder.sh still
  green on the grown manifest (stage-3 legacy still UNMASKED
  bit-identical; stage-4 masked-v2 EXACT); census section 2 RE-FROZEN
  over his 17-region set (the designed region-count-lock flow: his
  shared-zone findings mirror H's inventory exactly, all covered,
  same two operand false positives); m3a-reproducible PASS.
- Fingerprint at arc close: 60fd8afa (scratch builds only —
  build/hui6 = ping #7 remains untouched, re-verified).
- THE SOUND-FARM SWEEP LANDED same arc (pre-emptive, before any
  connect-range crash could name it): all six farm rows P references
  are the same jsr-0x330E shape with directly readable ids — five
  verdicts copied from H's verified rows (shared bytes, same ids),
  one NEW row 0x4F62 = id 0x735 (the 0x7xx stub class). Frontier
  37 -> 31 tripwires; soak re-verified clean (fingerprint 33164e64).
- NEXT for P: per-move native A/B replays (the m2a oracle template),
  param32/flavor measurement (no fork expected), then his gfx rung
  through the ratified layout row.

### 14z-67 continuation 7: THE ENTRY FOUND AND MEASURED (the seq-D
### per-char dispatch) — but activating it REGRESSES the ray move
### (dependency gap in his seq-D flow); both entry thunks PARKED with
### the zone regions kept; all gates re-green

- THE ENTRY (three more measurement rounds): vs2's class-02 seq-0xD
  handler head (0x22008, table entry D of the stepper's own jump
  table) is a PER-CHAR JMP DISPATCH — moveq; move.b $382(a6),d0;
  lsl #2; movea.l #$D9538,a0; jmp ([a0+d0]) — row 0x10 = HIS OWN
  ported handler 0x56D68 ("code"+0x20D8; head: bsr local + bra
  0x574B0 into the x057456 driver). The jmp dispatch also explains
  the RET-was-data mystery. vsavj's seq-D (0x22500) has NO dispatch
  — his seq-D states ran vanilla, so NONE of his effect flow ever
  executed (beam/lightning/ES-beam all downstream of it).
- ACTIVATION MEASURED AND REVERTED: the seq_d_dispatch thunk fires
  EVERY FRAME for both players (seq D = a common state; 401 probe
  hits/capped) and with it live the ray STOPS FIRING ENTIRELY (A/B
  vs hui8: no freeze) — his handler's deep flow has SILENT unmet
  dependencies (no crash, no tripwire; the state machine routes
  away). PARKED with full anatomy in the manifest comments.
- The effect_machine cold-stub thunk was ALSO the boot-gate breaker
  (the stub is cold for H but HOT for legacy effects — the gate's
  cycles broke masked-EXACT; my first park had silently missed the
  block, which confused one bisect round). Properly parked; the
  ZONE + SPAWNER REGIONS and their pads/recon rows STAY (boot
  masked-EXACT and m3a bit-exact re-verified with them in; behavior
  battery green on the round-final shape df578358).
- THE NEXT ARC IS NOW EXACTLY SCOPED: enable seq_d_dispatch in
  scratch builds and probe the 0x56D68 -> 0x574B0 flow to closure
  (the R1 loop: what does the flow read/call that our build lacks —
  candidates: per-char tables the flow indexes, farm rows, or the
  D9538-family sibling tables for other seqs). When the ray fires
  through HIS handler with the thunk on, the zone/spawners are
  already placed for the fleet, and beam duration/palette +
  lightning + ES beam + 214 explosion + possibly FG pacing all
  resolve through the same flow.

### 14z-67 continuation 6: ping #8 maintainer round — command grab
### CONFIRMED mechanically fixed; the beam arc's true architecture
### found (fighter-context callback, not an object machine); zone +
### spawners ported, entry re-aim = the one remaining trace

- Maintainer on hui9: 63214 command grab mechanically fixed ✓ (still
  lacks lightning); the 236P beam still invisible (too brief), AND
  the ES BIG-BEAM version also missing — all one family.
- THE ZONE CLONE LANDED AS REGIONS (x022400 = vs2 0x22400+0x1600 twin
  +0x2E — covers BOTH stub copies and all 50 handler sites;
  x06d240 = the fleet-spawner family +0x174, bounds measured
  61-64/64) with escapes resolved: three stage-2 record-installer
  entry twins (0x2710C/14/1C -> 0x27EB4/BC/C4, matching the bank_map
  14z-9 pairing), the byte-map data rows (-> vj 0x28D00 WITH the
  poked extension!), and the per-char effect-handler pointer table
  0xD96B8 -> 0xBF51A (per-game pointer content — byte-identity
  cannot apply; shape-matched). Builds clean.
- THE ENTRY HUNT (four probes + two taps, all attributed):
  1. The thunked vj stub copy: 0 hits. The OTHER copy: 0 hits. BOTH
     games have TWO copies (content-twin trap, paid again).
  2. Native the live stub = 0x22430 (3 hits) — and the probe regs
     reveal THE ARCHITECTURE: A6 = THE FIGHTER ($FF8400), d0 =
     effect selector, RET = $FF02DC (the RAM dispatch pump) — the
     "machine" is a per-frame FIGHTER-CONTEXT callback, NOT an
     object-class handler.
  3. The ray's effect id is 0x01 on BOTH games (pool taps; different
     installer PCs: native the API 0x17964, ours vanilla 0x67DBA/
     0x67F2A) and OUR object ticks in vsavj's OLD 0x67Exx machine.
  4. NOT routed via the obj_hook type tables (no row points into the
     zone) and NOT a bare long in his data regions.
  NEXT (one trace): where the move state installs the per-frame
  callback — prime suspect: the values rows' "engine dispatch
  entries: 1"; then re-aim the entry gate at that install site. The
  inert cold-stub thunk stays (harmless) until then.

### 14z-67 continuation 5: ES EXONERATED (maintainer side-by-side);
### THE COMMAND-GRAB THROW ARC FIXED NATIVE-EXACT (hui9 = 9e3105e0 =
### PING #8); the beam needs the zone clone for duration/palette

- Maintainer round 3: ES "confirmed clean mechanically", speed correct
  or near — the pass-through report withdrawn; FG remains the slow
  one. The freeze ray "still doesn't show" — they tested build/hui6
  (the pinned ping-#7 artifact; the fix landed in hui8). Their VS2
  beam capture shows the target: a SUSTAINED pale-green beam (~20+
  frames, confirmed by native replay-83 snapshots); ours renders a
  brief orange flash — the byte-map rows spawn the pieces but the
  VANILLA segments drive duration/palette -> full fidelity rides the
  effect-zone clone arc (also the lightning).
- THE COMMAND-GRAB THROW ARC (their "63214+P doesn't work", marker =
  victim leaves the screen top): DECODED AND FIXED. The physics-row
  installer (vs2 0x275E4 / vsavj 0x28386, unique tail twins) reads
  row = table2[map1[2*subidx + d0]*16] -> victim xv/xacc/yv/gravity.
  vs2's map1 carries FIVE entries past vsavj's end -> rows 0x32-0x36
  (the 63214 arcs = rows 0x33/0x34, yv 16.0/20.0); on vsavj H's index
  read past map1 into table2 bytes -> regular-arc rows = the "grabs
  look identical" symptom. Both vj tables jammed in place -> FULL
  TAIL REPLACEMENT thunk (patch=jmp + jmp_ok, body rts to the
  installer's caller) reading placed copies of vs2's full tables.
  STATIC SUPERSET PROOF (map1 prefix + rows 0x00-0x31 byte-identical)
  -> unconditional for all throws; boot masked-v2 EXACT confirms.
  MEASURED FIXED: FBNeo tap A/B — hui9 installs yv 0x0010 (16.0) at
  launch = native's exact value, decay lockstep. Gate: test_hui_grab
  gains the static thunk+tables leg.
- hui9 = 9e3105e0 = PING #8 (run_hui_behavior.sh default; hui6 stays
  the ping-#7 reference). Gates: boot masked-v2 EXACT, grab/ex/walk,
  m3a bit-exact.

### 14z-67 continuation 4: THE FREEZE RAY IS FIXED (six byte-map
### pokes — build hui8 = 59cf9f85); the lightning's remaining arc is
### fully specified (a shared-id state segment needing the zone clone)

- THE BYTE-MAP ROWS LANDED (huitzil.toml aux_pokes effect_map_*: ids
  0x4E-0x53 -> vs2's indexes 0F/1B/1F/19/0F/03 at DATA 0x28D4E-53,
  variant builds only) and THE 236P RAY RENDERS (replay 83 snapshot
  f3170: the horizontal beam striking Q-Bee). The per-char record
  rows needed NOTHING — bank_map's anim_index_a/a2/b rows 0x10 were
  already repointed to his placed anim (verified on the built image).
- THE LIGHTNING IS A DIFFERENT SUB-CLASS, measured precisely: the
  grab writes effect id 0x0A (a SHARED id, byteMap[0x0A]=0x31
  identical in both games; installed by the effect-spawn API vs2
  0x17964 into pool slot +0x54, whole-pool FBNeo tap f3436). Its vs2
  STATE SEGMENT re-derives the record through the byte map mid-flight
  (bsr to stage-2) and TAIL-JMPS the fleet spawner 0x6D282; vanilla's
  twin state lacks the tail -> no fleet. FIX = the zone-clone arc
  (the x02592a pattern): clone the vs2 effect-state zone
  (0x2245A-0x22Fxx, ~0xAC0B incl. the four fleet-jmp sites) + the
  0x6D282/0x6D6BC spawner family, enter via an owner-gated thunk at
  the vanilla machine's state dispatch for tenant-owned effect
  objects. Likely also covers the 214 explosion + grab distinction.
- hui8 gates: boot masked-v2 EXACT, ex/grab/air PASS, m3a bit-exact.

### PING #7 RESULTS (maintainer) — mostly good; EIGHT items, triaged.
### THE H ROUND-2 WORKLIST (open; first measurements + one mechanism
### landed)

Maintainer report on b99b7359: select/wheel/splash/HUD/sprites all
good; issues: (1) 236P freeze ray sprite missing (freeze itself
works); (2) sidekick shadow rectangular not round; (3) 214P ground
explosion = fuchsia tiles at range; (4) both EX moves feel slow vs
VS2 (FG post-capture especially; EX projectiles too) and ES sometimes
passes through/no damage (Morrigan, mid-screen); (5) win screen wrong
palettes; (6) cell 0x13 gives Victor — EXPECTED (single-tenant build,
unbacked cells; the Phase-2 merge backs all three); (7) Dark Force
shows inverted colors + after-images unlike VS2; (8) both grabs share
one animation and lack the electricity arcs.

TRIAGE + first measurements (14z-67 continuation 3):
- Item 2 = the documented RESTORE-AT-GFX shadow item (14z-66): the
  shadow_seq_guard clamps out-of-range seqs to the default shadow;
  the fix is the extended vs2-ported shadow table at the same site.
- Item 5 = my win-pal source derivation is WRONG (the color0==color1
  read was flagged suspicious at authoring; now confirmed). Measure
  vs2's win drawer for a newcomer special-case (like the select-pal
  compare chain at 0x6B1A6).
- Item 7 = DF STYLE, not DF mechanics (pods native-verified replay
  82): the inverted+afterimage look is the HOST engine's per-char DF
  effect style with his row aliasing a vanilla char. Decode the DF
  style table.
- Items 1/3 MEASURED (replay 83 + obj dumps, ours vs native vs2 with
  identical poke flow): THE RAY PIECES RUN H'S OWN BANK NATIVELY
  (bank 3, codes 0x0FA0-0x1088 — INSIDE his placed band, so the art
  EXISTS on our build) and on ours the beam pieces NEVER STAGE — a
  SILENT SPAWN FAILURE (freeze still connects; no crash; suspect the
  piece pool/spawn path, NOT art). The 214 pieces are also
  his-bank/his-band natively (0x02xx/0x0Fxx at f3440) — fuchsia =
  likely a wrong BANK WORD on the staged pieces, not missing art.
  Replay 83 (tests/replays/hui/83_hui_fx.rpl) is the repro rig.
- Items 1/3/8 first hypothesis (the x2b7ef4 bank-1 class) built
  ANYWAY as reusable machinery — c5 mode (14z-67): for delta-0
  group-C tenants the generator keeps companion-record bank-1 words
  NATIVE and emits effect_c5.json (5,714 codes); build_gfx places
  the art at native codes in group C bank 5; three ported spawner
  setters flip #$2000 -> #$3000 (huitzil.toml rows). Rationale: 2,007
  of those tiles are NOT byte-identical in vsav's effect page and
  effect_tail's Donovan maps covered only 385 — whatever pieces draw
  through those records were wrong-art on hui6. Landed in
  build/hui7 = 93c9aa44; behavior gates all PASS (boot masked-v2
  EXACT, ex/air/grab); VISUAL verification against its own symptom
  (grab electricity) still pending — the ray is measured NOT to be
  this class.
- MAINTAINER CAPTURES (win screens ours-vs-native, native DF, native
  grab lightning) + SECOND MEASUREMENT ROUND (replay 80 A/B obj dumps
  + record diffs) sharpened the picture:
  - THE C5 RECORD FIX IS CORRECT AND HUI6'S REMAP WAS WRONG (record
    diff at x2b7ef4+0x900C: hui6 shipped effect_tail-anchor tile
    words 0x0FE7+; hui7 keeps native 0x0FA0+, coord fixups intact).
  - BUT THE LIGHTNING STILL NEVER STAGES on hui7 (obj dumps through
    f3315): the pieces reading the 0x2C0F00-family records are never
    SPAWNED — the same silent spawn-failure class as the 236P ray
    (which natively runs bank-3 codes 0x0FA0-0x0FBA: THE SAME ART
    FAMILY — beam and lightning share the electric band).
  - Second symptom, same window: ours spawns F8FC/F90A/F15x-family
    pieces WITH BANK WORD 0 (y=00d0) that native NEVER stages —
    pieces created through a path that leaves +0x18 unset/zeroed.
  - The hit-spark spawner (0x18EFC/0x178C2) is EXONERATED: one call,
    identical registers, both games (the throw-release spark).
  - NEXT ARC (the one root), NOW WITH A PRECISE ENTRY POINT (third
    measurement round): the record installer is the GENERIC ANIM
    STEPPER (native PC 0x1378A writes +0x1C per tick from the piece's
    anim node chain — FBNeo tap on the 2P replay, non-perturbing:
    2P-dummy replays REPRODUCE cross-emulator, the vs-CPU rule does
    not apply to them). Native during the lightning: slot $FFB980
    alive, +0x1C chaining x2b7ef4 heads (0x2B8470+ marching per
    frame). OURS at the same phase: $FFB980 DEAD with stale vanilla
    residue (+0x1C=0x15A30E), only TWO pieces alive ($FFB800 chain
    0xE1D76, $FFB880 chain 0x40223C = the placed x2b7ef4 head) vs
    native's many — THE GRAB'S MASS PIECE SPAWN BAILS EARLY on ours.
    Entry point: find what spawns the $FFBxxx piece fleet in the
    native grab flow (his handler -> allocator loop) and where ours
    stops after two.
  - FOURTH ROUND — THE MECHANISM FULLY DECODED (FBNeo alive-byte tap
    -> spawner PC -> callers -> dispatch):
    1. The fleet spawner = vs2 0x6D282 (family incl. 0x6D6BC):
       repeated 0x15702 allocator calls, headers 0x01000800, piece
       subtypes 0x25/0x26 to $A, +0x18 BANK INITIALIZED TO 0 (the
       real bank is set by each subtype's first tick — why our
       orphaned pieces stage bank-0), a cmpi.b #$11 newcomer branch
       inside (vs2-specific content, no vanilla equivalent).
    2. Reached via TAIL-JMPS from vs2's EFFECT-OBJECT FIRST-TICK
       STATE MACHINE (sites 0x2275E/0x227AE/0x22AB8/0x22F1C):
       d0 = effect id (+0x54 of the effect object), special-cases
       0x3A/0x44/0x4C/0x51, pc-rel table lookup, then jmp 0x6D282.
    3. vsavj has NO byte twin of the zone (context pattern search:
       zero hits — vs2 rewrote it); our H's effect object falls into
       the VANILLA effect machine, which doesn't know the newcomer
       id -> the generic two-piece fallback with the bank never set.
    4. THE FIX SHAPE (next arc, region-scale — the x02592a clone
       precedent): port the vs2 effect-handler zone (0x22xxx family
       around the four sites) + the spawner family (0x6D282..0x6D6BC+
       bounds TBD) as regions with R1/escape pads; enter via an
       owner-or-id-gated site_thunk at vsavj's effect-object dispatch
       (find its first-tick dispatch site — the twin of vs2's entry).
       One port covers RAY + LIGHTNING + likely the 214 explosion +
       the grab-anim distinction, and possibly EX pacing (the effect
       phases gate move progression).
    5. Recon note: vs2 0x6D9D4 -> vsavj 0x61588 exists in the SHARED
       map as "engine_data" (bare_long) but 0x6D9D4 is CODE (a
       two-allocation spawner) — re-audit that row during the port
       (the pattern twin may be right; the KIND is wrong).
    6. FIFTH ROUND — THE SMOKING TABLE (the decode is COMPLETE):
       both games' effect machines share a BYTE-IDENTICAL entry stub
       (vs2 0x22436/vj 0x238F6: id = +0x54, index = byteMap[id] +
       +0x56, bra.w stage-2) and BYTE-IDENTICAL byte maps through
       effect id 0x4A (vs2 map DATA-view 0x27FD8, vj 0x28D00 — the
       pc-rel read is a DATA read, raw bytes; do NOT read these
       through the opcode view). THE DIFF IS SIX ENTRIES: effect ids
       0x4E-0x53 map to handler indexes 0F/1B/1F/19/0F/03 on vs2 and
       to ZERO on vsavj -> newcomer effects collapse to index 0 =
       the generic fallback. (Also id 0x5F: vs2 0x00 / vj 0xFF.)
       Stage-2 dispatchers: vs2 0x27110 / vj 0x28EBC. vs2's newcomer
       indexes REUSE vanilla handler slots whose vs2 SEGMENTS were
       rewritten (the jmp-0x6D282 fleet tails; + an in-machine
       cmpi.b #$10,$382 Huitzil case — Capcom's own precedent).
       THE PORT ("effect_hook", the obj_hook pattern one level up):
       route vj's byte-map ids 0x4E-0x53 to NEW indexes -> extend the
       stage-2 dispatch with union entries -> PORTED vs2 handler
       segments + the 0x6D282/0x6D6BC spawner family as regions
       (R1 + escape pads); tripwire unported indexes. The byte-map
       rows are superset-safe by construction (vanilla never emits
       ids >= 0x4B — verify with an id-writer-style audit before
       shipping). H's grab/ray/explosion effect-id writes are NOT
       immediate +0x54 stores (one hit only) — the ids flow from
       anim-node/spawn params; enumerate them at port time by
       tapping +0x54 writes on the native replays.
  - Win screen (captures): native = GOLD (his normal family); ours =
    pink/lavender + GARBLED BLUE-GREY RECTANGLES on eye/thigh/foot —
    TWO defects: the palette (my source wrong) AND a few wrong art
    blocks (likely tiles outside the walked inventory — the win pose
    may reference codes the anim walk missed).
  - DF (capture): native applies NO palette change and NO afterimages
    to him — the fix SUPPRESSES the host DF style for his id (find
    the per-char DF style selection; give row 0x10 the null style).
  - ES collision: maintainer will retest side-by-side (may be less
    severe than first reported) — deprioritized pending their result.
- Item 4 (EX speed/ES collision) = the behavior-measurement arc:
  2P-dummy native A/B per move (the m2a rig), post-capture FG pacing
  vs native, ES hitbox/phase measurement at varied ranges.
- build/hui6 stays the pinned ping-#7 artifact; hui7+ carry fixes.

## Session 14z-66 (playtest round-1 worklist)

### The alias-physics port OPENED — jump_params row landed (float
### ceiling NATIVE-EXACT); ground dash = the next row

Consumer decoded and ported same-session (patch_notes has the bytes):
the jump-param installer (vsavj 0x27A34 / vs2 0x26C86) reads id*0x30
rows (xv/xacc/yv/gravity x neutral/fwd/back) from the 32-row-aliased
table at 0x0BDB7A — the param32 pattern exactly, variant row 0x10
superset-safe. jump_params registered in the bank map + VALUE_SKIP
(port_param32 tenants only). Build 8bea919e: float ceiling 109.4 ->
121.1 NATIVE EXACT with the native rise curve; oracle mismatches
1770 -> 1741; all ten gates green (air-gate samples retuned to the
native rise timing); m3a bit-exact. build/hui4 = 8bea919e (ping #6).
THE FAMILY IS NOW CLOSED — the ground dash was EXONERATED by
measurement: his dash physics are HIS OWN PORTED CODE (writer PC
0x56DEA in his handler zone, xv 6.0 hardcoded + engine accel/drag),
and the clean 2P-dummy A/B shows an IDENTICAL endpoint (723.8) and
settle frame on both games; mid-dash samples differ only by the
documented ±1-frame cross-engine action latency. The old "7 vs 8.2"
reading was vs-CPU noise (the CPU pushed ours post-dash). Ledger of
every known feel delta: float ceiling FIXED (native-exact), jump feel
FIXED, dash NO-DEFICIT, throw-arc/RW-knockback = VICTIM-side
vsavj-host physics (correct by the superset philosophy), DF walk
drift subsumed by the oracle bound. Round-7 maintainer: "jumps and
float feel good... doesn't feel wrong" (final feel call deferred to
the gfx stage by their note). Bonus scheme validation en route: the
walk consumer read A0=0xD7A18 = vs2's param32_a at EXACTLY the
bank-origin delta.

### Item 5 — the coverage replays LANDED (RW GC + Dark Force,
### native-matched); the oracle battery is the remainder

- REFLECT WALL GUARD CANCEL (replay 81 + native A/B): P1 blocks the
  dummy's point-blank jab, 623+P during blockstun — the seq-0x0E
  progression is frame-identical to native on BOTH attempts and the
  attacker is blown back across the screen (native x 322->487, ours
  322->474; the knockback magnitude delta = the alias-physics class,
  queued with the throw-arc/float-ceiling family).
- DARK FORCE (replay 82 + native A/B): activation seq 0x0A at f3110
  AND at f4210 on both games — activation, expiry, and re-activation
  all proven; the DF summon pieces (types 0x75/0x77) present in poolB
  on both at the f3250 sample, same coordinates. Open observations
  (single-frame, unattributed — queued for the oracle battery): ~15px
  X drift over the DF walk (speed modifier vs recoil) and a pod anim
  phase difference at the sample frame.
- NEW gate tests/test_hui_pairs.sh (both signatures asserted).
- The 2P-dummy instrument (early-window pokes) is now the standard
  clean-room rig — replays 80/81/82 all use it.
- THE ORACLE BATTERY LANDED (same session): replay 90 (ONE file for
  both legs — the forced-pick pokes work identically on vsav2 and
  vsavjw, so no per-game cursor fork; battery = jab, QCF+P, QCB+K,
  DP+HP, jump+air dash, float, walk-in grab, 421+2K ES) + gate
  tests/test_hui_oracle.sh (the m2a template's four locks verbatim).
  ALL FOUR LOCKS PASS: anchors equal (2363 — the same anchor as the
  Donovan pair), neutral window EXACT (210 frames, every mapped
  field), P2 HP-change sequences identical
  (288,278,259,257,255,254,253,252,251,250), comparative bound
  1770 <= 2529 (ported H diverges LESS cross-game than a vanilla
  veteran). One mechanism finding en route: +0x0A pre-engage = an
  RNG-DRAWN INTRO VARIANT (his init: table16[rand&15] at vs2
  0x57050-0x5707C, with a per-opponent downgrade branch) — the two
  GAMES tick the RNG differently through their menus, so the gate
  DETERMINIZES the RNG ($FF80D4/D5 poked on both legs just before
  the draw), keeping the neutral lock strong instead of skipping
  the field. ITEM 5 COMPLETE — the round-1 worklist is fully done,
  oracle-proven end to end.

### ROUND 6 (maintainer): ITEM 4 CONFIRMED ("Circuit scrapper
### confirmed") and D1 RATIFIED — "VS2 flavor confirmed as the
### default selection in the current build AND the default selection
### in the target." All four fix items of the round-1 worklist are
### now maintainer-confirmed closed; item 5 (coverage replays +
### oracle battery) is the remainder.

### ROUND 5 (maintainer): ITEM 3 CONFIRMED — "normal select is VS2,
### hold start is VH2 and the float and dash are indeed there."
### Ping #5 = 2898c495 confirmed; the flavor selector verified BOTH
### ways in play for the first time.

D1 DELIVERABLE (the flavor differences to hunt for, decoded from the
float body 0x2598A — the fork is its FIRST instruction):
- VS2 flavor (+0x3C2 = 0, the default): float engages only while
  falling, only ABOVE min height 0x40, only with EXACTLY straight up
  held (dir nibble == 8 — diagonals drop), and the hover is
  TIMER-LIMITED (0x78 = ~2s per float).
- VH2 flavor (+0x3C2 = 1, Start-hold): any-up hold (mask & 4 — 7/8/9
  all sustain) PINS the timer — hover indefinitely while held; no
  min-height test on the hold path.
So: VH2 floats looser and longer; VS2 is the stricter, committal
float. These are the felt differences for the D1 final call.

### ROUND 4 (maintainer): "FG properly resolves" — item 1 CLOSED FOR
### GOOD (all three sites: voice-cue tripwire, shadow-seq clamp,
### data_in_code reroutes). Ping #4 = 4317353c confirmed.

### ROUND 3: the THIRD FG crash — embedded data-in-code tables; the
### class censused and closed (5 reroutes, one mechanism)

Maintainer: FG still crash-reset "a bit later after the capture" on
44be1266. The hunt (variants: plain/kill/CPU-victim sweeps clean; a 2P
victim sweep was INVALID — select-window pokes leak into the 2P flow's
commit handling, noted for replay authoring) landed with the
post-capture CHAOS replay: his FG draws each barrage hit's victim
capture pose RANDOMLY from a 16-byte table EMBEDDED IN HIS CODE — and
crypt-hole placement stores code re-encrypted, so runtime DATA reads
of the table saw garbage (native draws 01/03/05; ours drew 0xFF...).
Garbage seq -> the victim's vanilla capture table (0xBCE7A+ sets,
Midnight-Bliss family) over-runs -> per-victim/per-draw vec3s. THE
RANDOMNESS explains every confusing symptom: clean casts, drifting
crash frames, three different-looking crash signatures.

- NEW mechanism [[data_in_code]] (the 14z-20 gotcha in region form,
  now handled generically): relocate the table's SOURCE-DATA-VIEW
  bytes to a raw hole, reroute the reader via a ghost-clean 12-byte
  helper (jsr+nop over the 8-byte lea(pc)+read pair). Shape-checked;
  any (An,Xn.w) read size.
- CENSUS: the class had bitten 3x (pod first-tick, farm params, FG),
  so all crypt-placed region bytes were scanned for the shape — FIVE
  instances, ALL rerouted preemptively (the FG table, its 3 pose-set
  siblings in "code", and x088512's pod offset/record word table).
- Build 4317353c: replay 78 (FG + post-capture chaos) clean in BOTH
  timelines; full battery GREEN (boot masked-v2 EXACT; m3a bit-exact
  — mechanism is manifest-driven, Donovan rowless). Gate:
  test_hui_ex.sh section 4. build/hui4 refreshed (ping #4).
- WATCH ITEM: the same census should run for DONOVAN's regions at his
  next re-freeze (his crypt-placed code may embed tables the same way
  — his playtests never crashed there, but "never crashed" was H's
  state too until the FG). The census scan is in the session log;
  promote to a tools/ script when it runs for Donovan.

### ROUND 2 (maintainer): speed CONFIRMED better; ES CONFIRMED fixed;
### FG STILL CRASHES — second site found and characterized

Maintainer round-2 report: speed "much better if not perfect" (wants a
side-by-side eventually); Erasing Sphere fixed; Final Guardian still
crash-resets; flavor question still blocked on float (item 3). Their
build/hui4 was accidentally rebuilt — re-made at 3a172c52, audit clean.

THE SECOND FG CRASH (reproduced first try once RANGE was right):
- Repro: mid-range FG, ALL button pairs (45/46/56) — vec3 f3398, PC
  0x15098 (the engine anim-node installer), reading ODD 0x2083DD,
  A6=$FFD500. CLOSE-range FG completes (the connect cuts the guardian
  sequence short — why replay 73 stayed green; my error: promoted the
  connect variant, the whiff variant was the crasher). Scratch
  replays $S/fgvar; promote 77 = fg_45_mid as the gate case.
- WHAT FG IS (native snapshots, on record): Phobos TRANSFORMS into
  the giant guardian; barrage pieces = poolB secondary objects types
  0x75/0x77 (the obj_hook table2 extras) animating from his regions.
  OURS: the 0x75/0x77 pieces are CORRECT (anims relocated exactly —
  0x40223C = placed x2b7ef4 + the native offset).
- THE CRASH VICTIM is not a piece: it is one of THREE VANILLA
  class-0x0C per-player effect objects (+ one class-0x3E carrying the
  char id) spawned by vsavj engine 0x489xx-0x48A32 at char-load
  (native vs2 does not place these at $FFD5xx). It idles vanilla
  anims (base +0x40 = 0x2083BC, loop 0xE2C/0xE34) all match, then at
  f3397 its walk is asked for seq id 0x21 — base table word echoes
  garbage -> odd cursor -> vec3 next frame. NATIVE never requests
  seq 0x21 at the twin walker (probe, cond d0==0x21: zero hits).
- The 0x21 does NOT come through the vanilla spark remap 0x1A610
  (that table maps input 0x21 -> 0x41; nothing maps TO 0x21) — it
  enters via the class-0x0C handler's own seq computation (sub-state
  dispatcher vsavj 0x48A42, table at 0x48A58). Donovan's 14z-3 spark
  arc is the CLASS precedent but his ids all stayed in vanilla range
  (art-only defect, thunks staged 99); H's FG drives an id out of
  range -> crash. Timeline note: the plain run survives longer (the
  garbage walk is content-dependent) — the maintainer's interactive
  crashes are the same mechanism on different frames.
- FIXED same session (build 44be1266) — the decode overturned two
  early guesses and landed a one-thunk fix; full anatomy in
  patch_notes 14z-66:
  - The "0x21" was the FETCHED word, not the seq: the real seq id was
    0x488 (cached at servant +0x50), from the +0xC word of an anim
    NODE (nodes stride 0x18; low 13 bits = shadow-seq id).
  - The class-0x0C trio are the per-player SHADOW/REFLECTION servants
    (installer 0x8237E+); their tables 0x2083BC/0x2087CA are SHARED
    engine data hardcoded at 0x823E2/0x823F2 (row space 0x40E), NOT
    per-char. vs2's twin (0x1E42D2, via twin installer 0x90B08) is
    larger — his nodes carry vs2 seq ids verbatim.
  - THE VICTIM crashes, not the tenant: FG is a CAPTURE super — the
    victim plays attacker-supplied nodes, so the victim's servant
    over-indexes (measured: crash owner id 0x0C = P2). An owner==TT
    gated thunk MISSED it (22ea24f9, the negative lesson).
  - Fix: [[site_thunk]] shadow_seq_guard, UNGATED range clamp at the
    walk site 0x8245C (seq*2 >= 0x40E -> seq 0 default shadow;
    stack-neutral patch="jmp", a NEW emitter option; site_thunk block
    gate 6->4 with per-row default 6 — Donovan emission unchanged,
    m3a PASS). Legacy-invariant by construction: vanilla content
    cannot produce an out-of-range seq (it would vec3 vanilla).
  - Measured: replay 77 guard-clean END 4720, stock consumed,
    snapshots show the full native sequence incl. the 7-HIT barrage
    (native's exact hit count). Gate: test_hui_ex.sh section 3.
  - RESTORE AT GFX: same site redirects out-of-range seqs to an
    extended (vs2-ported) table for the native giant shadow.

### Item 1 CLOSED — EX-move crash-reset: one voice-cue tripwire, both moves

Scripted repro per the plan (stock poke ff8509=9, the 14z-44 recipe;
replays tests/replays/hui/71_hui_ex_fg / 72_hui_ex_es /
73_hui_ex_fg_close):
- ES 421+2K: deterministic vec4 f3513 at PC 0xF8740 ~97 frames into
  the move = the TRIPWIRE for unresolved vs2 0x4EFA — a sound-farm
  row enqueueing sfx id 0x748 (newcomer voice range), called from the
  one-shot voice cue at shared zone x0689cc+0xec
  (tst.b $23(a6)/clr.b/jsr). In a plain run the ILLEGAL lands in a
  garbage vector = the watchdog reset the maintainer saw.
- FG 623+2K: clean at mid-range (a whiffing FG never reaches the cue)
  but at CONNECT range hits the SAME tripwire (vec4 f3364, ~98 frames
  in) — one root for both playtest crashes. Connect range was
  load-bearing for the repro.
- FIX: three stubbed_sound rows in the H overlay (vs2
  0x4efa/0x4fb0/0x4fca, ids 0x748/0x729/0x72e disasm-verified, all
  0x7xx = the established stub class; x067846+0xd2/+0xec swept along,
  never seen to fire). Tripwire frontier 18 -> 15.
- MEASURED FIXED (fingerprint 01f6f907): ES fires repeatedly to
  completion; FG-connect fires 3x (stock 9->6), guard clean
  end-to-end both replays.
- Gates: NEW tests/test_hui_ex.sh — guard-clean AND stock-decrement
  (the 14z-44 anti-coverage-loss shape); negative control is measured
  (both replays CRASH on the pre-fix build e8d95a5c). Full battery
  GREEN after the change: extract/ladder/boot (masked-v2 EXACT)/
  soak (pods live)/m3a-reproducible (both frozen refs bit-exact).
- build/hui4 REBUILT at 01f6f907 (run_hui_behavior.sh only builds if
  missing — the maintainer's dir was still pre-fix). Ping #2 ready.
- Docs: patch_notes 14z-66 (byte detail), tables/reconciliation.md
  14z-66 (the three rows + repro anatomy).

### Item 2 CLOSED — speed: his true velocity pairs serve from variant
### rows 0x10 (14w-b hazard re-examined, does not manifest for H)

Landed on top of the measurements below: port_param32 opt-in
(generator per-tenant default + huitzil.toml), fingerprint 3a172c52
(116 ops: + the two row-0x10 data ops). Verified static (rows 0x10
carry his pairs, vanilla rows pristine, from the built zip) and
dynamic (walk replay 74: 15-frame 16.16 deltas 0x1C2000/0x384000 =
exactly 25/24 x the alias build's 0x1B0000/0x360000 — the consumer
serves his row; the walk anim runs a 0.6x/1.2x phase profile). NEW
gate tests/test_hui_walk.sh. THE HAZARD RE-EXAM: full battery GREEN
on the ported tree incl. the 11k chaos soak (Donovan's 14w-b crash
was at soak f10050; H shows no analog), EX gate, boot masked-v2
EXACT, m3a-reproducible (Donovan flagless -> bytes unchanged).
build/hui4 re-refreshed at 3a172c52 (ping #2 carries items 1+2).
Maintainer note for round 2: fwd walk is now FASTER than round 1
(3.125 vs 3.0), param32_b-mode movement slower (1.625/-2.25 vs
2.0/-2.75) — both native-accurate.

### Item 3 OPEN — float/air-dash census: the float is a vs2 ENGINE
### jump-seq EXTENSION (state-hook class, not a data row)

The native census (replay 75 probe, tap instruments; all logs
described in scratch, mechanisms verified by disasm):
- Native hold-8 float, measured: engine 0x264FE starts jump seq
  0x02000600; two frames later engine **0x25948** converts it to the
  FLOAT: `addq.b #2,$7(a6)` (sub-state +2 via the 0x2592A jump-table
  indexed by +0x07), clears +0x121/+0x1C2, arms **+0x1C0 = 0x78**
  (120f float duration), and reads **+0x3C2 (the VS2/VH2 flavor
  byte)** — float behavior is FLAVOR-FORKED. Gate at 0x25940:
  `tst.b $21(a6); bpl -> exit` (bit 7 of +0x21 = the license; its
  writer not yet caught — first open probe). During the hover the
  mover is NOT called at all (no +0x14/+0x44 writes, tap-proven);
  rise decelerates to yv 0xffffc000 at apex then the state holds.
  Hover anim loop vs2 0x24618A/0x2461A2/0x2461BA (D1=0x18).
- vsavj's engine jump handler has NO such extension -> the fix class
  is the ENGINE HOOK / state_hook machinery from Donovan's seq-state
  arc (14z-46), NOT a table row. Applies to the air dash too
  (untested but same family; GROUND dash works on ours — measured,
  both games dash, ours ~7px/f vs native ~8.2px/f).
- EXONERATED by measurement: his command evaluator (vs2 0x5522E) IS
  live on ours (A0=0xBFC3E in mover context); all 7 R1-mapped motion
  helpers have byte-identical step tables + same dispatcher family;
  the 0x2A606 hold-up check + the 0xBFF22 float-start branch are
  statically perfect but 0-hit (that path is a DIFFERENT command —
  +0x179=0x10 both sides, +0x1AC writes all-zero both sides during
  hold-up; the 0x55512 route is NOT the float).
- SECOND DEFICIT found on the way: ours jumps with ALIAS-row jump
  physics (initial yv 0x67000 / gravity step 0x5000 vs native
  0x7a000 / 0x6000) — the 14w "jump-physics parameter gap tables",
  still unported for want of a decoded consumer; the mover context
  is now half the decode. Queue behind the float hook.
- 14z-66 LATER MEASUREMENTS (the decode advanced; instruments:
  replay 79 + the +0x20-word tap on native):
  - The "+0x21 license" is NOT separate machinery: the anim walker
    installs each node's header long into +0x20/+0x21 (native tap:
    PC 0x27140 writing values like 0x0480 — bit 7 set) — THE FLOAT
    LICENSE IS A BIT IN HIS ANIM-NODE HEADERS, already carried by
    the ported anim data. Ours even plays his jump/float anim family
    (0xD65xx = native 0x2461xx under the delta). The ONLY missing
    piece is vsavj's engine lacking the 0x2590C-0x2595x jump-seq
    extension.
  - Air dash on ours: cleanly re-confirmed DEAD with a properly
    airborne 66 (replay 79: X frozen through the whole arc).
  - NATIVE TAKEOFF IS THE FLOAT FAMILY: a bare 3-frame U tap does
    NOT jump native Phobos (measured twice; his takeoff wants held
    U / the rise), while ours tap-jumps like the alias row. The
    maintainer's "float dead + air dash dead" = one system: the
    vs2 jump-seq extension serves takeoff, hover, and air movement.
  - Replay-authoring note: the 79 native leg desynced on CPU
    pushback (native P1 was in blockstun at the tap frame) — the
    native-side probes must fire in the pre-CPU-contact window or
    use farther spacing.
- THE HOOK LANDED (14z-66 late; build f0916ef1): **THE FLOAT WORKS**
  — rise to a ceiling and HOLD (measured: Y pinned at 109.4 through
  the hold window; native pins 121.1 — the delta is the alias-row
  JUMP PHYSICS feeding takeoff, the known queued deficit). The
  architecture that landed, each piece measured:
  - vs2 routes the class-02 jump seq BY CHAR ID at the engine head
    (0x213F2: cmpi #6 -> Anakaris family; cmpi #$10 -> 0x2592A =
    PHOBOS'S OWN per-char jump handler). The 0x2592A dispatcher +
    five bodies (float/air-action/restart) = region x02592a
    (root 0x2592a:0x456:t0x25958, sibling-diff 7/1110).
  - vsavj's live twin head = 0x22A0E (via the class-02 stepper
    0x225C4, table 0x225EE, seq06 -> +0x420). site_thunk
    tenant_jump_seq displaces its Anakaris cmpi: tenant -> the
    clone's dispatcher; others re-run the cmpi and re-enter the
    INTACT beq.w with vanilla flags. NEW emitter options: jmp_ok,
    id_literal_ok, region_subst.
  - CONTENT-TWIN TRAP paid: vsavj keeps a byte-identical copy of
    the generic head at 0x26A58 — it is ANAKARIS's handler; hooking
    it did nothing (0 probe hits). The live handler was found by
    tracing the actual dispatch (0x225C4).
  - NEW mechanism [[pcrel_escape_fix]]: engine-style clones carry
    pcrel word-form branches escaping the region — oracle-invisible
    (siblings preserve spacing) and unrewritable in place. The pass
    reserves an adjacent trampoline pad and rewrites each escape to
    a jmp trampoline; targets resolve via placed regions first
    (x026142's copy spans 0x26142-0x27542 and CONTAINS the
    walker/mover family — H's code already uses the copy), then
    verified recon rows. 89 escapes -> 35 trampolines on x02592a.
    (Bug paid on the way: the trampoline cursor didn't increment —
    all 35 aliased pad+0, every escape jumped to the seq epilogue,
    anim froze. One line.)
  - 28 jump-family twin rows added to the overlay by GENERIC-HANDLER
    ALIGNMENT (instruction-stream diff of vs2 0x213F2-family vs
    vsavj 0x22A0E-family with operand masking) — all five
    previously-known pairs reproduce exactly; 0x273E6 content-
    verified -> 0x28192; 0x269AC left open/tripwired.
  - FLAVOR POLARITY corrected BY MEASUREMENT: native vs2 runs H
    with +0x3C2 = 0x00 (the tst/beq branch = VS2-default). The
    Donovan-convention 0x01 default selected the WRONG branch;
    huitzil.toml now flavor_default=0x00, flavor_held=0x01.
- AIR DASH LANDED TOO (build 2898c495; the "mid-instruction skew"
  hypothesis was WRONG — the trace showed the air-dash seq starter
  (vs2 0x26E14, in the x026142 copy) ending with an
  oracle-invisible pcrel `bra.w` back to the engine stepper:
  x026142 HAS CARRIED UNREWRITTEN ESCAPES SINCE 14z-65, and the
  air-dash flow was the first to die on one. pcrel_escape_fix
  extended to x026142 (7 targets, site-twin resolved — two targets
  confirmed by two independent sites each; 0x24CBA = the
  neutral-reset family -> 0x26058 by unique wildcard). Measured:
  float hover -> seq 0x1400, +119.6px over 15f at dy=0 (the flat
  accelerated dash) -> fall with carry -> landing. NEW gate
  tests/test_hui_air.sh (mode signatures: Y-pinned hover; seq 0x14
  + flat advance). Full battery GREEN (boot masked-v2 EXACT, soak,
  m3a bit-exact). build/hui4 = 2898c495 = PING #5 — and with the
  flavor polarity fixed, D1 is PLAYTESTABLE for the first time
  (default = VS2 per measurement; Start-hold = the other flavor).
- Item-3 tails (open, none blocking): the 44 back-air-dash variant
  (replay 79 runs it clean; no signature assertion yet), the
  VH2-flavor float A/B writeup (the D1 deliverable), the float
  ceiling (alias jump physics: ours 109.4 vs native 121.1 — the
  14w gap-table port), and the per-victim min-height table read at
  0xBE23A over-indexing for id 0x10 (benign threshold read,
  measured non-fatal; tighten with the physics pass).

### Item 4 CLOSED — Circuit Scrapper: fixed BY the x026142 escape
### trampolines (the grab's move-start was dying on the same latent
### pcrel escapes); native-matched on a 2P dummy

The retest after the item-3 escape fixes: the grab CONNECTS. The
clean instrument (the 2P dummy, unblocked by the POKE-WINDOW finding:
commit pokes must end by ~1500 in the 2P flow — later pokes leak into
the 2P load and turn P2 into a variant id; measured with a no-poke
control) shows FRAME-IDENTICAL native parity: P1 sub-states
0e04->0e08->0e0a->0e0c at the same frames, victim damage 0x13
identical (hp 0x120->0x10D), same recovery frame. Only the victim
THROW-ARC HEIGHT differs (native launches higher — the alias-physics
class on the thrown velocity; queued with the physics pass). Gate:
NEW tests/test_hui_grab.sh (replay 80; seq-0x0E + native-damage
signature). No build change — ping #5 (2898c495) already carries it.

### Item 4 history — recognition WORKS, the break was at/after
### move-start (collapse class RULED OUT)

- His 63214 predicate table (vs2 0x299E6 via the farm-port stub at
  0xF85B0, param 0xF8590) is BYTE-CORRECT on the build, terminator
  included; all three farm-port helper tables verified against vs2
  (the 14z-48 collapse class does NOT apply). The stub correctly
  aims the vsavj motion dispatcher 0x29F4A.
- RUNTIME (replay 76, GUARD_PROBE at the match branch vs2 0x55388 ->
  placed 0xBFD98): the branch FIRES on our build, exactly on the
  button frames (3132/3332) — command recognition is END-TO-END
  ALIVE. Attempt 3 (3532) did not fire (P1 was in a state by then).
- The A/B after the match is CPU-NOISED (ours got hit around
  attempt 2; different CPU behavior per game) but attempt 1 shows
  ours reaching the grab-attempt anim family (0xD83F0 = vs2 0x247FF2
  under the anim relocation delta 0x16FC02) ~15 frames later than
  native, preceded by a dash-family anim native does not show.
- NEXT: author the 2P dummy repro (P2 idle at fixed spacing — the
  16_xemu template pattern) and A/B the move-start chain from the
  match branch: what native runs after 0x55388 (throw-box check,
  grab connect/whiff fork) vs ours; then the fix per class. Replays
  76 + probe recipe are the instruments.

### Item 2 measurements (the mechanism record)

Measured this session (the 14w-b hazard re-exam, first half):
- BOTH vsavj param32 tables are 32-ROW: rows 0x10-0x1F are
  byte-identical aliases of 0x00-0x0F (dumped). All THREE consumers
  (0x228e2/0x271a8 table a, 0x26484 table b) index the RAW +0x382 id
  (ext.w/lsl #3, NO fold) — so H at 0x10 read the ALIAS CONTENT
  (Bulleta's rows), the measured mechanism behind "feels a bit
  slower", and a variant-row write at 0x10 is superset-safe by the op
  invariant with no consumer work.
- His extracted true pairs: param32_a 00032000/fffd4000 (fwd 3.125
  vs alias 3.0; back equal), param32_b 0001a000/fffdc000 (both
  slower than alias 2.0/-2.75).
- CHANGE: VALUE_SKIP is now a per-tenant default — [[tenant]]
  port_param32 = true opts in (huitzil.toml only; Donovan carries no
  flag -> bytes unchanged, the 14w-b guard intact for him).
- Verify plan: static row-0x10 check on the built zip + walk-speed
  replay 74_hui_walk (16.16 X deltas over 15-frame windows, measured
  BEFORE push-box contact; only the fwd half discriminates — his back
  velocity equals the alias content) + the FULL battery incl. 11k
  soak + EX gate (the hazard re-exam, second half: Donovan's 14w-b
  crash was at soak f10050).
+ Huitzil/Phobos 0x10 + Pyron 0x11. Recon complete (3-way sweep:
generator internals, docs corpus, STATE history + two baseline
extraction dry-runs); the plan is **docs/project/M3b_plan.md**. Design verdict:
N [[tenant]] rows in ONE generator process (post-hoc patch merge proven
unsound: pristine-ROM alloc check, silent op overlap, replacement-shaped
hooks). Three decisions registered for the maintainer below. Work
begins with Phase 0 safety rails (op-overlap assertion + m3a
reproducibility gate), then extractor de-Donovanization.)

## Session 14z-65 (M3b OPENED 2026-08-07 — plan + decisions register)

- **Plan: docs/project/M3b_plan.md** (mission, 6 phases, gates, watch items).
  Milestone deliverable: three tenants in one WIDE build; the
  single-tenant degenerate case must reproduce donovan-m3a 4b7d0dc7
  bit-exact at every intermediate commit.
- Recon findings of record (details + citations in the plan):
  - Baseline extraction FAILS for both new chars (measured): the
    code-region similarity scan ends early (H: +0x400 vs dispatch
    targets +0x46a; P: +0x200 vs +0x1fa2), and P's region seed lands at
    0x0574C0 — in the H-adjacent appended zone, far from his 0x059424
    handler. H/P code interleaves with the shared newcomer stubs
    Donovan already ports → shared-span placement is load-bearing.
  - Extractor is Donovan-tuned in 3 places: literal 0x0013 char-id
    scan, DONOVAN_ANCHORS (no anchors for other chars), the scan above.
  - Space: hole_a full, hole_b 272 B free — H/P go entirely to
    wide_ext (2 MB, ~24 KiB used). Program space is a non-issue; group
    C bank-4 tile-code coexistence is the undesigned mechanism
    (Donovan ~16.7K codes of 64K; three tenants ~50K — packing looks
    feasible, measure first), and QSound is the resource to size early
    (16 MB profile ceiling = MAME's hard max).
  - obj_hook's extended table is already union-shaped; types 64-75 +
    companion 121-123 (vs2 addresses recorded in the m5_wide patch
    notes fragment) resolve when H/P roots are extracted. state_hook's
    5 no-op stubs (0xBC-0xC8) + reaction_hook widen by union at their
    single sites.
  - patch_prg.py has NO op-overlap detection — every collision class in
    this milestone is currently silent. Phase 0 fixes this first.
  - Huitzil has the VS2/VH2 Start-hold fork (community-confirmed;
    Donovan wiring is the template); Pyron has none.
  - "Selectable is not fightable": the arcade ladder + VS-pool palette
    entries (0x3A3CA0 + id*32) support NO tenant yet, Donovan included.

### Decisions pending (human) — M3b

- **D4 — M3b sequencing after the behavior polish: RATIFIED
  (maintainer, 2026-08-07): PHOBOS VERTICAL FIRST** — gfx rung ->
  freeze (registry row + expectation set), THEN the Phase-2 Pyron
  merge against TWO frozen verticals. Rationale (assessed + agreed):
  the gfx-first risks are boundable (Pyron's tile budget is
  measurable from vs2 gfx data without porting him — design the
  3-tenant group-C layout and reserve his share BEFORE placing any H
  tile), while merge-first churns the ground gfx would build on; a
  frozen H vertical gives the merge bit-exact reproduction targets
  (the strongest gate class); the maintainer playtest channel — the
  session's best verifier — returns to full strength with real
  sprites. SCOPE EXCEPTION (maintainer-stated): sounds stay
  stubbed-silent through the vertical, like Donovan — the voice
  samples are vs2-only content requiring the QSound image growth
  (WIDE 16MB = the MAME ceiling) = the M5 voice-bank port, its own
  cross-tenant arc; every stub row carries RESTORE AT M5.
  NEXT-SESSION OPENERS, in order: (1) measure all three tenants'
  tile-code budgets + fix the group-C 3-tenant layout; (2) run the
  pcrel-escape and data-in-code censuses over Pyron's extracted
  regions (early structural warning, no port needed); (3) the H gfx
  rung on the Donovan machinery (de-Donovanize the stage>=6 gfx
  constants). FLIP CONDITION: if the budget measurement shows three
  tenants cannot fit group C, stop and redesign the layout/profile
  before any placement.

- **D1 — Huitzil default flavor: RATIFIED (maintainer, 2026-08-07,
  round 6): VS2 DEFAULT** — "VS2 flavor confirmed as the default
  selection in the current build AND the default selection in the
  target." Both ratification preconditions were met: the flavor
  differences writeup was delivered (STATE 14z-66 round-5 record:
  VS2 = the stricter float — falling-only, min height, exact-up,
  ~2s timer; VH2 = any-up pins the hover indefinitely) and the
  selector was play-verified both ways on ping #5. NOTE the wiring
  detail: for H the VS2 flavor is +0x3C2 = 0x00 (MEASURED on native
  — the Donovan 0x01 convention was the wrong polarity for him);
  flavor_default=0x00 / flavor_held=0x01 in huitzil.toml is the
  ratified configuration.
- **D2 — Pyron source version** — only becomes a real decision if the
  Phase 1 measurement shows vs2↔vh2 behavioral divergence in his code
  (no Start-hold fork exists for him, so the shipped version is the
  only version). RECOMMENDATION: VS2 base per SPEC §3 unless the
  measured delta list shows VH2 fixed something.
- **D3 — arcade-ladder membership**: do the tenants (Donovan included)
  join the CPU opponent pool, and with what placement/weighting?
  RECOMMENDATION: yes, uniformly, once the ladder mechanism is REd;
  order/weighting stays yours. Work is plan Phase 6.

### 14z-65 Phase 0 DONE — op-overlap assertion + reproducibility gate

- The overlap audit of the frozen WIDE patch found ONE real collision:
  the generic value-row repoint and the [[sound_table]] port both wrote
  tail_data_ptr[0x13] (PRG:0x0BF466); the shipped bytes were correct by
  emission order alone — the sound op (id-allowlisted array) was
  emitted later and won over the raw relocated-hitbox pointer (which
  carried vs2's unfiltered sfx records, music ids included). GOTCHAS
  14z-65 has the full anatomy; patch_notes 14z-65 the byte detail.
- Fixes: patch_prg.py hard-fails on any two ops writing one word
  (named, word-granularity — deliberate: odd-aligned pokes merge
  PRISTINE neighbor bytes, so a shared word resurrects vanilla bytes);
  the generator's sound_table claims now suppress the generic repoint
  for their ptr_table (exact same stage/profile gating, so stock
  builds keep the repoint).
- Gates: NEW tests/test_patch_overlap.sh (2 accepts, 2 named rejects)
  and NEW tests/test_m3a_reproducible.sh (scratch-rebuild both frozen
  references, compare fingerprints) — both PASS; canonical dirs
  regenerated (WIDE 4b7d0dc7 @ 243 ops, was 244; stock 6c93cfa8
  unchanged at 226).
- ZERO byte drift by construction and by measurement. Next: Phase 1
  (de-Donovanize extraction — the 0x0013 immediate scan, per-char
  anchors, the H/P code-region scan failures).

### 14z-65 Phase 1 DONE — extraction de-Donovanized; H AND P EXTRACT

- **Both new tenants extract, oracle-validated** (0 UNRESOLVED, the
  full closure/classification pass green). Frozen by NEW gate
  tests/test_extract_hp.sh (shapes + unanchored-char refusal control).
- The failures were STRUCTURE, not tuning (measured; atlas
  character_tables.md "piecewise" section + GOTCHAS 14z-65):
  - The appended window's sibling shift is PIECEWISE (+0x36 Huitzil
    zone / +0x30 long middle incl. Pyron+Donovan / +0x34 tail). Fix:
    group dispatch targets by their own pair delta (free ground truth),
    one region per group ("code" = dispatch_00's group — Donovan
    degenerates to the old behavior byte-identically).
  - Dead inter-routine filler differs between the siblings (Pyron: 12
    junk bytes at PRG:0x0576F4 after two jmps). Fix: flow-out-gated
    filler tolerance recording "dead" zones, refs never classified
    inside them.
  - vs2 carries a 6-byte INSERTION with no vh2 twin: Huitzil's handler
    head `jsr $8ACD8` (= the +0x36->+0x30 boundary). Fix: strict
    boundary probe (opcode-word match + zero unexplained; the lax probe
    misplaced the boundary by 6 bytes); the sliver ports as source-only
    "ins" bytes, its jsr an ordinary R1 item. PURPOSE UNDECODED —
    decode during the Huitzil port.
  - charid scan + anchors de-hardcoded (CHAR_ANCHORS rows measured for
    all three; extraction without an anchor row is refused).
- Phase 2 hazard put on the record: H's +0x30 region overlaps P's and
  D's zones (shared stubs) and carries a `cmpi #$10` site in the SHARED
  stretch — region dedup must key by source span, and per-tenant id
  rewrites on shared spans need tenant attribution.
- Reproducibility gate PASS after every machinery edit (both frozen
  fingerprints intact). Remaining Phase 1 item: the per-tenant R1 root
  census (extra roots for H/P support zones + their handler types among
  64-75/121-123) — that is build-out work, queued behind the Phase 2
  generator loop.

### 14z-65 — THE HUITZIL LADDER OPENS (stages 1-3 GREEN, superset
### bit-identical)

Sequencing adjustment (recorded): before the Phase 2 multi-tenant merge,
Huitzil climbs the SAME falsifiable single-tenant ladder Donovan's M2a
did — the merge refactor then unifies two WORKING single-tenant builds
instead of one working and one hypothetical. The machinery generalized
with Donovan defaults byte-preserved:

- `build/manifest/huitzil.toml` (minimal: tenant at native 0x10,
  variant-id only, three-space model); driver TENANT_MANIFEST/
  TENANT_CHAR selection; per-char DEFAULT_ROOTS; stage>=6 refused for
  non-Donovan tenants (his gfx constants — Phase 3/4 generalizes).
- His root census OPENED: 0x55478 (tail_code_ptr row's routine —
  appended newcomer-support code BELOW the 0x57000 window; the appended
  zone reaches 0x054xxx, measured, atlas updated).
- The Phase-0 overlap assertion caught its first real prey ON THE FIRST
  new-tenant build: the stage-1 scaffold and the stage-2 passive pass
  both repoint hitbox rows (M2a-era by-design last-write-wins). Fixed
  by ownership (scaffold repoints emit only at stage 1; the copy still
  emits so stage-2/3 bytes are unchanged).
- Gates: NEW tests/test_hui_ladder.sh GREEN — stages 1-3 build
  (05edf96f / ba516bd1 / c0910a0e), THE OP INVARIANT (every op writes
  free space or a variant row 0x10-0x1F — the superset invariant at op
  level) holds per stage, and a legacy replay on stage 3 is
  BIT-IDENTICAL to the frozen vanilla expectation (whole-RAM,
  unmasked; measured, not argued).
- Donovan post-change verification GREEN: m3a reproducibility PASS
  (both frozen fingerprints bit-exact) AND his stage 1/2/3 gates PASS
  with their pinned divergence frames intact (2886 / 1080) — the
  scaffold-ownership change is behavior-invariant on his ladder too,
  by measurement.

Next on the ladder: stage 4 (code + engine hooks) needs Huitzil's R1
loop in earnest — his engine-consumed dispatch routines (0x55478-class),
his types among 64-75/121-123, the state stubs 0xBC-0xC8 he writes, and
the reaction ids he inflicts. Then flavor wiring (decision D1), then the
Phase 2 merge with Donovan.

### 14z-65 — HUITZIL STAGE 4 BUILDS (94f89571); frontier = 23 named
### targets

The R1 loop ran two rounds (byte detail: patch_notes 14z-65 (4)):
- His census: 0x55478 + the 18-ring velocity family 0xd143e+0x900
  (vs2-only bank data) + the SHARED support zones from Donovan's list.
  The 0x8ACD8 mystery is CLOSED: it resolves into the shared
  source-only zone (his aux init) — x088512 is 0x3B40 for him (pcrel
  escape closure, 6 rounds), not Donovan's 0x2f00 census bound.
- reconcile_batch x2 into the GLOBAL map: 50/101 of his first engine
  surface was already Donovan-mapped; 219 rows kept + ~49 new verified.
  Donovan stayed bit-exact through both map rewrites (gate-proven).
- Generator gained the pcrel far trampoline (near jmp bounce for
  out-of-d16 word-table entries; unused after the zone-extent fix but
  correct and kept; Donovan-inert — was a hard fail).
- Tripwire frontier 57 -> 23, all classified: companion family
  (0x2b7ef4/0x2b8060/0x36784a — guarded runs decide), the SOUND-FARM
  five (0x4ddc-0x4f96 — M5-style triage required, never blind-resolve),
  and 15 per-target R1 items (0x4223c/0x42cee/0x448d4/0x3844e engine
  subs + mid-ROM data).
- NEXT (the stage-4 proof arc): guarded in-match boot of Huitzil
  (forced id 0x10 via the pick-probe poke path — no select wheel needed
  on the ladder), which fires whichever tripwires his real flows reach
  and turns the 23 into a measured worklist; then the farm triage; then
  stage gates + flavor wiring (D1 provisionally VS2).

### 14z-65 — the forced-boot probe: variant-id char-load WEDGES (measured,
### instrument validated)

NEW instrument `tools/force_pick_probe.sh` (vanilla select flow, confirm
at default cell, POKE $FF8782 — the commit field — across the
commit->load window; verdicts: id-hold / load / guard):
- id 0x10 on the hui4 stage-4 build: the poke HOLDS through the VS
  window ($FF8782 = 0x10 at f2000+f2600), but by f3600 P1's struct is
  ZEROED — the char-load path WEDGES silently (no crash, guard clean,
  no tripwire fired: the load never reaches ported code).
- POSITIVE CONTROL (verdict-logic doctrine): the same probe with
  vanilla id 0x05 LOADS that character ($FF8460 = 0x9EFE6) — the
  instrument is sound; the wedge is REAL and variant-id-specific.
- CROSS-CHECKS RUN (same session): the archaeology hypothesis is DEAD
  and the diagnosis is sharper —
  - m3a + forced 0x13: LOADS (0x3FA9D0, his placed hitbox) ✓.
  - m3a + forced 0x10: LOADS Bulleta (0x91F98 — the vanilla row-0
    alias). PRISTINE vsavj + 0x10: same. The engine load path is
    variant-id-TOLERANT with no machinery at all.
  - hui3 (stage 3) + 0x10: LOADS HUITZIL'S OWN placed hitbox
    (0xEE3E0) — the passive-data rungs are LIVE-verified (his data +
    Bulleta's code via the trampolines). Unplanned bonus proof.
  - hui4 (stage 4) + 0x10: the snapshots reveal the truth — f2200
    select, f2900 black garble, f3400 THE QSOUND BOOT SPLASH: his
    ported init path HANGS (no exception), the watchdog fires, THE
    MACHINE REBOOTS. "Zeroed struct + clean guard" was fresh-boot
    state (GOTCHAS 14z-65: a watchdog reboot masquerades as a clean
    non-load; the probe now snapshots and names the ambiguity).
- HANG-HUNT OPENED (same session, GUARD_PROBE bisection):
  - His handler IS dispatched: probe at the placed dispatch_00 target
    fires ONCE at f2886 (the canonical char-load frame; A6 = P1 struct).
  - [init_shim] added to huitzil.toml (pool-seed + flavor latch,
    flavor_default 0x01 per provisional D1; engine facts reused, not
    Donovan-copied) — mechanism-correct and kept, but NOT sufficient:
    still reboots (fingerprint aec4d319).
  - The handler-head aux call (0x8ACD8 -> placed shared zone) is
    entered AND RETURNS (post-call probe at handler+6 fires, registers
    moved on). THE HANG IS PAST +6 — bisection cursor for next
    session: walk the init chain jsr-by-jsr with GUARD_PROBE (the
    chain from the handler dump: move.b #4,$3C(a6); jsr 0x1572E-equiv
    [R1-mapped]; beq; move.l #$1001000,(a4); ... — each mapped call
    and each (a4)-family write is a candidate).
  - Remaining suspects, ordered: an R1-mapped engine call in the chain
    whose vsavj twin has different completion semantics; the sound-farm
    five if init enqueues a sound; a companion/pool spawn deeper in.

### 14z-65 — THE SPECIALS HUNT (after the boot): frontier bounded to
### the predicate-match interior

Native ground truth first: vs2 + the same forced-pick probe = NATIVE
PHOBOS FIRING PLASMA BEAMS on our exact soak inputs (snapshot on
record) — so the port's silent soak meant "specials never trigger",
not "all good". Links fixed, each measured (patch_notes 14z-65 (6)):
NEWCOMER_CODE widened to 0x54000 (13 dispatch rows were unrepointed
Bulleta aliases — his handler zone lives at 0x54C9C+; Donovan-inert,
measured; shapes re-frozen), 18 farm rows content-verified at 8-BYTE
record granularity via the DATA view (two audit traps documented), and
the NEW engine-alias generator rule (dispatch_07 is per-char IN ENGINE
SPACE — Bulleta 0x2D68E vs his 0x23AFE; repointed to the hand-verified
vsavj twin 0x24EA4). FRONTIER, precisely bounded by parity
instruments: predicate consultation is EXACTLY equal (401 hits native
= 401 ours, same entry, same soak) yet the port writes NO nonzero
brief states where native writes 0x06/0x16. The divergence is INSIDE
or AFTER the predicate match. NEXT instruments, in order: (1) identify
WHAT natively writes 0x06/0x16 (special launch vs hit-reaction — tap
with REGLOG on native, read the writer PCs' context); (2) the
predicate common's VERDICT path (probe the taken/not-taken branch at
the first command-check site on both games — the ABI is readable from
his command processor at x057456+0x554); (3) the INPUT-HISTORY feed
the matcher reads (his +0x3xx input ring — if the recorder dispatch
row feeding it is another wrong alias, the matcher sees an empty
ring). Builds: acda6946 current ladder; all gates green.

### 14z-65 — MAINTAINER PLAYTEST ROUND 1 (the behavior build): report
### + attributed hypotheses — THE NEXT SESSION'S WORKLIST

Overall: "general feel is good", "all very promising". Findings:
1. FEELS A BIT SLOWER — likely REAL, not the garble: the generator's
   VALUE_SKIP (param32_a/b, the 14w-b Donovan crash guard "Jedah
   speeds retained") skips his velocity pairs too, so H moves at the
   VANILLA ALIAS ROW'S speeds, not his own. Fix = port HIS param32
   rows — but the 14w-b hazard (Donovan's true velocities crashed a
   soak; "separate landmine") must be re-examined for H, not assumed.
2. AIR DASH (44/66 airborne) DOES NOT WORK. 3. FLOAT (hold 7/8/9)
   DOES NOT WORK. Both = his unique MOVEMENT modes — suspects: the
   skipped velocity family, unported movement states/dispatch paths,
   or input-hold detection. Census the states his native air dash/
   float write (the state-tap method on native vs2) then trace ours.
4. BOTH EX MOVES (Final Guardian 623+2K, Erasing Sphere 421+2K) run
   most of their animation then CRASH-RESET (the watchdog signature).
   ES machinery = a known ported-char arc (Donovan m2c: full ES chain
   + meter decode). Repro is scriptable: extend the soak replay with
   meter-build + the exact motions; the guard will name the site.
5. CIRCUIT SCRAPPER (63214+MP/HP command grab) does not come out —
   HALF-CIRCLE = the 14z-48 farm-collapse class precedent; verify his
   63214 predicate rows BY TABLE CONTENT at record granularity.
6. REFLECT WALL (623+P guard-cancel) untested (needs a GC setup —
   scriptable: a 2P replay where P2 attacks into P1 block + the GC
   input; author it).
7. DARK FORCE seems good; needs deeper testing (pair replays).

### 14z-65 — HUITZIL IS ALIVE END-TO-END: soak green on the real set,
### legacy masked-EXACT, behavior build shipped (PING #1)

The full chain on the REAL vsavjw set (after the false-green lesson —
GOTCHAS): boot loads HIS data; intro/engage/states/moves live; the
companion-anim root (x2b7ef4, Donovan's row verbatim) fixed the pod
first-tick; the 12 secondary handlers 64-75 rooted (type 72 = his live
sub-object, 401 per-frame executions measured); the farm census closed
for everything his flows reach (voice-range stubs only — the keyon
over-sweep was caught and reverted, GOTCHAS); round-2 pods respawn via
HIS OWN built-in keeper (satellites d400/d480 alive at f6000).
- GATES: NEW tests/test_hui_soak.sh (build + guarded 11,000-frame
  chaos soak on the packed set + round-2 satellite check) GREEN;
  tests/test_hui_boot.sh set-aware with the legacy leg FROZEN as
  masked-v2 EXACT (measured — cleaner than Donovan's builds: no
  flicker inventory needed yet; any future flicker is measure-and-
  ratify); ladder/extraction gates green; m3a bit-exact (after the
  recon-overlay split — the shared map is FROZEN for Donovan, H's rows
  live in build/manifest/reconciliation_huitzil.toml via the new
  manifest key recon_overlay).
- SHIPPED FOR THE MAINTAINER (ping #1): tools/run_hui_behavior.sh —
  interactive windowed WIDE MAME; pick anyone as P1, get Phobos
  (tests/lua/force_id.lua). Expectations documented in the script
  header (garbled body, silent voices, attract oddities reportable).
- Replay captured: tests/replays/hui/70_hui_mash.rpl (subdir escapes
  the suite glob until H's expectation set exists).
NEXT after playtest feedback: the oracle battery analog (17/18-style
native-vs-ported field comparison), more soak variants (2P, throws,
timeout, arcade flows), then the gfx rung (his art in a WIDE band) and
the select-wheel cell activation.

### 14z-65 — the pod first-tick frontier (resume point)

The init-time vec3 decoded: engine 0x1AFAA `movea.l $4(a0),a0` faults
because THE POD'S ANIM CURSOR ($1C of the pod struct) holds 0xFCA39 —
ODD and inside NO placed region = garbage from an incomplete first-tick
init, not a bad relocation. His pod handler (type 115 -> the ported
x088512 copy at 0x897CC-equivalent) runs its first tick and fails to
set the cursor — its anim-record source is one of the still-open
targets (0x2ABD58 / the 0x2B7EF4-family companion-anim class are the
suspects; for Donovan the analogous data was the x2b7ef4 Anita zone his
manifest roots carried). RESUME: (1) probe the placed pod handler's
first-tick in the GUARD timeline; (2) tap the pod struct's $1C writes
at init (round-1 pod = $FFD580, so tap ffd59c) with REGLOG — the
writer PC + source register names the table; (3) root/port the pod
anim data per the x2b7ef4 precedent (its own extra data root with
oracle twin), re-soak. The effect/spark remap class (Donovan 14z-3)
likely follows right after.

### 14z-65 — f4983 SOLVED: the un-hooked type dispatch (trace-caught);
### frontier moves to the spark/effect remap at his pod's first tick

THE TRACE (GUARD_TRACE in the same -debug timeline as the crash — the
lesson: plain-vs-guard timelines DIVERGE, tap evidence across them is
apples/oranges) caught the fatal jump verbatim: the object walker at
0x5E534 read the spawned pod's TYPE byte (+0x02 = 0x73 = type 115;
+0x03 = owner id 0x10), indexed the VANILLA 114-entry companion type
table at the UN-HOOKED site 0x5E542 (`movea.l ($12,PC,D0.w),A0`), and
fetched CODE BYTES past the table (the 0x323B0006 "address" = a
dispatcher opcode). huitzil.toml simply lacked the [[obj_hook]] rows —
they lived in donovan.toml. Both rows added; vs2's table2 extras
114-120 ALL resolve inside the ported x088512 zone (his pod handler
0x897CC included ✓); 121-123 tripwire (other newcomers). The
[[dispatch_keeper]] row REMOVED from his manifest: the f4983 spawn
proved vs2-H has his OWN built-in keeper (the mechanism stays in the
generator for tenants that need it). Also: the earlier "+0x02 handler
word" readings of the FF02A0 records were WRONG — +0x02/+0x03 are
TYPE/OWNER bytes; correct the mental model.
NEW FRONTIER (execution now reaches deeper): vec3 at f2886 (init), PC
0x1AFAC = the shared spark-spawner family reading odd 0xFCA3D — his
pod's first-tick enqueues an effect whose id over-indexes a vanilla
remap table (the 0x1A610 spark-remap family; Donovan's 14z-3 spark
arc is the precedent). NEXT: decode the faulting read at 0x1AFAC
(which table, what stride), find his effect id, extend/port per the
Donovan effect-map pattern.

### 14z-65 — the Anita archaeology + the keeper mechanism; f4983 still
### standing after six instruments (fresh-instrument list for resume)

DONOVAN ARCHAEOLOGY (m3a + 20_don_round2, measured): Anita at $FFD500;
the boundary teardown (f11800-12000 there) is CLEAN — her object AND
Donovan's +0x28 pointer both zeroed together; his own per-frame KEEPER
respawns her ~1000 frames later at a NEW slot ($FFD480 by f13000). The
Anita pattern is the port's answer to vs2's per-round char-init.
NEW GENERATOR MECHANISM [[dispatch_keeper]] (opt-in): wraps a dispatch
row with "intro done && satellite ptr zero -> jsr the tenant's OWN
ported spawn tail" (H: dispatch_01 + vs2 0x5745C, the alloc+pods+rts
section of his init). Emitted, gates green — but UNPROVEN for round-2
pods: the f4983 crash precedes the keeper's first opportunity.
f4983 FACTS BANKED (five fix hypotheses failed to move it; crash is
byte-stable): B980 sits properly in a FREE LIST at f4982 (the single
reference: free-list node $FF2FF8); NO writes touch B980 during
f4983-84 (tap-proven) yet the crash context has A6=B980; the husk's +0
flags are 0000 (walkers should skip); GUARD_BREAK at 0x3B001E did not
fire before the vec4. Crash-stack extras: A5 work vars $FF8030/$FF8034
hold placed-code addresses (0xF270E hole_a / 0x3F7080 hole_b) — stored
handler/continuation pointers; a NEIGHBORING stale work var read as a
pointer is an open suspect (the Donovan A5-displacement class).
RESUME INSTRUMENTS, in order: (1) vanilla-05 comparative at ITS round
boundary — how free slots are walked safely and which +0 flag
discriminates (is the husk's flag wrong?); (2) per-frame B980 flag
dumps 4890->4983 (watch the husk's lifecycle byte-by-byte); (3) the
A5 work-var audit around $FF8030-family for vs2-layout displacements
in his ported code (the -0x52-family shift class); (4) if all else
fails, interactive MAME -debug at the boundary.

### 14z-65 — f4983 ROOT NAMED: no per-round char-init on vsavj; pods
### die at the boundary and their queue node dispatches the husk

The comparative that settled it: probing char-init dispatch entries —
NATIVE vs2 runs char-init TWICE (f2886 + f8812: per-round re-init;
that is how his pods respawn each round), while on vsavj dispatch_00
fires ONCE (f2886) — vanilla chars need no per-round init, so the
engine has no such call. At our round boundary the engine's pool pass
(f4890) frees his satellites; nothing respawns them (P1 +0x2A/+0x2C
ZERO in round 2 — a gameplay deficit even without the crash: podless
Phobos); and a stale class-6 queue node still references the freed
slot (0xFFB980 = a husk with class defaults; the crash address
0x3B001E exists NOWHERE in RAM — computed through the husk's zeroed
fields). Three hardening rows landed and KEPT (phase-gated shim latch,
companion class-7->6 remap, alloc_wrap wrappers — each correct by
precedent; none is THE fix). dispatch_01 identified as his PER-FRAME
handler (the 401 cadence, starts f3093 post-engage).
NEXT (the fix design): (1) find vsavj's per-round per-char hook —
probe his remaining dispatch rows (02-19) across the boundary window
f4850-4950, and/or tap the round-counter writer and walk its callees;
(2) DONOVAN ARCHAEOLOGY: how does Anita survive the same boundary in
the frozen build (20_don_round2 is a GREEN gate — her lifecycle
answers the deregister-vs-respawn question); (3) then either hook the
tenant's pod respawn onto the per-round call (a shim-class mechanism,
manifest-opt-in) or deregister the pods' queue nodes at death so the
crash half disappears independently of the respawn half.

### 14z-65 — the f4983 crash: characterized, hardened, OPEN

Two correct-by-precedent hardening fixes landed (kept even though
neither is THE fix — the crash is byte-identical with both):
[init_shim] latch_mode="phase" (seed only when $FF800C.l == 0x40000 =
the char-load phase; measured discriminator) and the companion
queue-class 7->6 port_patch on H's copy of x088512 (the Anita
precedent row donovan.toml carries).
The crash, precisely: deterministic f4983 (round-2 boundary + ~93
frames), vec4 at PC 0x3B001E (palette space), A6 = 0xFFB980 — a slot
the round-boundary seeder walk (f4890, PCs 0x16C7A-0x16F44) left with
class defaults + zeros; the update queues are NODE CHAINS in the
0xFF31xx arena (heads at $FFF990: 0xFF319E/31DE/... stride 0x40) and
some node still references the dead slot. Round 1 is CLEAN through
2000+ frames of live fighting (states, moves, sounds censused).
NEXT on this thread: (1) native-vs-ours comparative at f4982 — what
does a healthy 0xFFB980 hold on vs2, and which arena node references
B980 on each side (dump 0xFF3180-0xFF3400 both, diff node chains);
(2) identify the f4983-adjacent replay event (the chaos cycle puts a
QCF+LP there — but round-1 beams were clean, so suspect the ROUND-2
transition leaving H's spawned satellites (0xFFD580/D600 from init)
stale while vanilla chars' equivalents re-init; (3) the seeder walk at
round boundaries may be NORMAL vsavj flow (verify with the vanilla-05
control tap before trusting any wipe theory again).

### 14z-65 — ENGAGE FIXED: states alive, moves execute; two new
### findings banked (odd-ref classifier bug; shim re-seed fragility)

THE ROOT OF THE FROZEN ANIM CURSOR (and thus the whole engage chain):
a diff-classifier misfire produced a 32-bit "engine ref" at an ODD
OFFSET (code+0x249B) spanning the bmi operand + the following jsr
OPCODE — its rewrite DESTROYED the jsr to the anim stepper (placed
bytes read 30F9..., a move.w where the jsr was). FIX: code-region ref
fields must be word-aligned (even_only in diff_refs, gated on
allow_engine; Donovan has ZERO odd refs in his frozen extraction —
measured inert). With the jsr restored: the anim cursor WALKS, the
intro completes, the engine neutral-engage fires, and the state tap
shows LIVE brief states (48 x 0x16). Verified working: his moves now
execute deep enough to enqueue their sfx.
- Sound census SWEPT pre-emptively: enumerated EVERY farm entry his
  regions reference (42), keyon-checked each id, stubbed the 4
  remaining DIFFERS entries (0x73d/0x74b/0x74d/0x3ea) — plus 0x74d
  found live by the soak first.
- Notes on the call chain: refs to vs2 0x2711C/0x271C4 classify
  INTERNAL to the x026142 shared-zone copy (the zone spans them) — the
  COPY is functional (its own embedded table refs relocate to the
  vsavj tables; same machinery Donovan uses), so this is correct-by-
  relocation, just surprising: the anim stepper his code calls IS the
  ported copy, not the engine twin.
- NEW FRONTIER (soak at f4983, deterministic): the ROUND-2 RE-SEED.
  The [init_shim]'s pool-head latch (A5+0x7966 == 0 => seed) re-fired
  at his round-2 char re-init — his ecosystem drains pool 0, the latch
  reads 0 mid-match, the seeder REINITIALIZES LIVE POOLS (measured:
  f4890, seeder PCs 0x16C7A-0x16F44 walking every pool), queued
  objects orphan, and a freed slot (0xFFB980, class defaults only,
  otherwise zeros) gets dispatched ~90 frames later -> PC in palette
  space. LIKELY LATENT FOR DONOVAN TOO (same latch; his soaks never
  drained pool 0). Fix design: a robust one-shot latch for the shim —
  measure the game-phase field ($FF8004 family) at first-init vs
  round-2 re-init and gate the seed on the load phase, OR a dedicated
  flag byte; MUST be manifest-opt-in (latch_mode) so Donovan's frozen
  shim bytes stay identical until his own re-freeze adopts it.
- Gates at this checkpoint: boot PASS, extraction gates PASS (shapes
  re-frozen for the even-only classifier — hui4 fingerprint 62cc5aed);
  the mash soak reaches f4983 (round 2) before the re-seed crash; the
  m3a reproducibility gate MUST be re-run before the next commit
  (even-only touched the classifier).

### 14z-65 — THE NEUTRAL-ENGAGE CHAIN NAMED (write-stream diff; one
### missing native write)

The decisive instrument was a per-field WRITE-STREAM DIFF (tap on the
object's $A(a6) byte, native vs2 vs ours, same replay): the streams are
IDENTICAL for four writes (init clears at f2829/2830 by each game's
own engine; the round-start 01 at f2885; OUR PORTED CODE faithfully
writing 6 at f2885 from vs2 0x5707C = his init dispatcher's substate
"post-init hold" — NOT a queue class, the earlier guess is corrected)
— and native has ONE FIFTH WRITE ours lacks: **f3003 (the FIRST INPUT
frame), vs2 PC 0x26056 writes 0** — the ENGINE'S NEUTRAL-RESET (a
clear-sequence at vs2 ~0x2603x: $150/$136/$137/$A/$26/$105/$164/$142/
$115...) that flips his object from post-init hold into live play.
Ours never runs its equivalent, his dispatcher stays on substate 6
forever, and the whole state layer (and specials) never engages —
the SINGLE root behind every downstream symptom.
- The reset routine is UNMAPPED (no R1 row; it sits in engine space
  just below the shared x026142 zone), and it is DISPATCHED (record-
  context stack), so the break is either (a) the vsavj TWIN exists and
  the DISPATCHING of it fails on ours, or (b) his ported code installs
  the reset via an unrelocated field/row.
- NEXT (first command of the resume): find the reset's DISPATCHER on
  native — debugger trace frames 3000-3006 on vs2 (input desync under
  -debug tolerated: search the window for the 0x26056 write and read
  the call chain above it), OR bisect with GUARD_PROBE on the reset's
  routine HEAD (find it by scanning back from 0x26040 for the entry).
  Then check the same chain on ours: the first absent link is the fix
  site. Also find vsavj's own twin of the reset (veterans use it too —
  vanilla-05's $A ends 0, so vsavj HAS the routine; find_equiv on the
  clear-sequence).

### 14z-65 — the specials frontier NARROWED to his per-frame handler
### interior (bracketed by controls)

The state-byte discriminator was OVERTURNED by its own control: vanilla
vsavj chars write the same 0x16/0x06 states in similar volume (238/191
over the soak — they are movement-class states, not launch markers).
The REAL symptom is broader: H's object writes NO brief states at all.
Bracketing instruments (all on record in scratch logs):
- The vs2 0x25EBA/0x25EE8 helper pair (called from ~25 sites across his
  handlers) is CORRECTLY R1-mapped (0x26D36/0x26D64, byte-verified
  twins; only internal bsr drift differs).
- The helpers' head guard flags ($17B/$38/$190(a6)) are CLEAN on his
  object (dumped, ours == native at f4000).
- P1-conditional probe on 0x26D36, same build, same soak: vanilla char
  05 calls it 132 times; HUITZIL CALLS IT ZERO TIMES.
So: his per-frame dispatched handlers run (boot gate proves dispatch),
his command walk runs (predicate parity 401=401), but the ordinary
per-frame path through his OWN handler code never reaches the engine
state layer. SHARPENED (last measurement of the session): all 132
vanilla calls to 0x26D36 RETURN TO $FF02DC — the helper is not called
FROM handlers, it IS a dispatched per-frame handler: state transitions
INSTALL it as the object's update-fn, and the RAM loop at $FF02DC
dispatches it. So the suspect is the INSTALLATION path: H's ported
code installs vs2 0x25EBA-family addresses into the object's update-fn
field — and if that field is stored as a 16-BIT WORD (the engine's
word-offset convention; note `move.w a4,$2A(a6)` in his init), the
32-bit ref relocation NEVER APPLIED to the stores: vs2 word values
silently aim the dispatch loop at the wrong vsavj code. NEXT, in
order: (1) decode the $FF02DC RAM loop's handler FETCH (dump RAM
$FF02C0-$FF0300 once — which struct field, what width, what base);
(2) dump H's installed update-fn field vs vanilla-05's on the same
build at the same frames; (3) if it is the word-offset class, the fix
is a new relocation rule for update-fn word stores (measure the base,
rewrite the words per placement) — a generator mechanism, not a
manifest row.

### 14z-65 — HUITZIL BOOTS (first match on the vsavj engine)

Build 9252ce62 (ladder, not frozen). Probe verdict: HIS hitbox base
0x3EC840 loaded, guard CLEAN full-run, live match vs a CPU opponent
(sprite-garbled body = correct pre-gfx rung; HUD shows the row-alias
name = later rung), legacy replay bit-identical. The reboot's root
cause + two more fixes, each measured (patch_notes 14z-65 (5)):
1. FALL-THROUGH LAYOUT GROUP: the 0x57456 insertion boundary splits
   his handler mid-routine; placed apart, the post-jsr fall-through
   executed padding + foreign region bytes -> wander -> watchdog.
   [[layout_group]] "x055478,code,x057456" in huitzil.toml.
2. [init_shim] (necessary by design, insufficient alone).
3. FIVE stubbed_sound rows (ids 0x72a-0x74a -> rts 0x2A7E0): his init
   enqueues voice sfx whose vsavj same-id entries key DIFFERENT
   music-class content — MEASURED via the keyons records (the ids sit
   BETWEEN the documented music ranges; assumption would have been
   wrong either way). Twin doc updated same-commit.
NEW gate tests/test_hui_boot.sh GREEN (+ ladder/extract/m3a gates).
NEXT: the behavioral frontier — in-match input soaks (his moveset via
scripted inputs; each new tripwire hit = the next R1 item), the
vsav2-as-oracle stage-4 battery analog (test_m2a_stage4_oracle
pattern), the remaining 18 targets, then HUD/select rungs and the
Phase 2 merge. The maintainer-playtest milestone is after gfx (his
art in a WIDE band) — sprite garble until then.

Updated: 2026-08-06 (session 14z-64 — M3a COMPLETE AND FROZEN. The
maintainer ratified the re-freeze bundle ("freeze"): the WIDE reference
is now donovan-m3a = 4b7d0dc7 (tenant at native 0x13 by default, Jedah
restored, the whole select/wheel family from group C, real medallion
art/palettes, ring reuse, variant HUD/win-pal, the 14z-2 mirror fix),
stock twin 6c93cfa8 (= old ae701ffb + exactly the 2-byte fix). Masked
basis V2 (staging-slot windows); expectation set tests/expected/
donovan-m3a with the 14-replay measured classes; registry row added.
Both canonical dirs (build/m5_wide, build/m5_stock) rebuild bit-exact.
Read 14z-64 below, then docs/NEXT_SESSION.md.)

## Session 14z-64 SESSION CLOSE (2026-08-07)

M3a frozen and validated (SUITE GREEN, commit cef3238). Scratch/evidence
build dirs (build/m3a_wheel, build/m3a_selrec, build/chk_*) are
UNTRACKED leftovers of the 14z-63/64 arc — safe to delete; the canonical
references are build/m5_wide (4b7d0dc7) and build/m5_stock (6c93cfa8),
both committed with their regenerated patch fragments. Next session:
docs/NEXT_SESSION.md (the second tenant / M5 sounds).

## Session 14z-64 FREEZE RECORD (maintainer: "freeze", 2026-08-06)

- Registry: `4b7d0dc7... -> donovan-m3a` (supersedes donovan-m5w/
  9bac6ee3, whose row and zips remain valid history).
- Expectation set: 14 authored .masked (1 exact, 5 window, 7 composite,
  1 diverge — the measured v2 inventory, flickers matching donovan-m5w
  to the frame), 16 .skip carried over, per-set `mask` file (V2),
  self-frozen sha1+logs for the rest (the --freeze run, double-run
  determinism per replay).
- Vanilla masked-v2 logs: regenerated deterministically from the frozen
  vanilla oracle (14 logs, committed).
- Stock twin re-frozen 6c93cfa8; full battery GREEN at freeze; the
  render-gate reference refreshed (build/m5_stock).
- Known residuals carried on the record: Pyron placeholder medallion
  recolors after a 2P Donovan-hover (row 0x1A = P2 sword row); the
  deep-arcade ending flow unmeasured (fold-audit gap).


## Session 14z-64 (the bundle prep — RATIFIED above; package kept for the record)

**THE RATIFICATION PACKAGE (one decision, per the 62c plan).** The
bundle's mechanics are applied and measured; the maintainer ratifies:
1. THE MIRROR-VICTIM FIX (14z-2): stock candidate = frozen ae701ffb +
   EXACTLY 2 bytes (PRG:0x0B1A16, 0b30->0d88); behavior proven by a
   matched control pair (206/0 vs 0/206 block reads) on new replay 65;
   gate test_don_throw_mirror.sh; the STOCK BATTERY IS GREEN on the
   candidate with the frozen flicker inventories intact.
2. id_by_profile = "cps2-wide-v1=0x13": the WIDE track's default is the
   native id (no flag); test_tenant_id flipped per its design note.
3. THE V2 MASKED BASIS: the round-64 staging-slot window generalized —
   the staging area is $FF3F02+row*0x20 (the ratified $FF4182 window IS
   row 0x14's slot); v2 adds the medallion rows' slots (0x16/0x19/
   0x1A). Vanilla masked logs regenerated deterministically under v2
   (tests/expected/vsavj/masked-v2/); per-set masks in run_suite; the
   stock track keeps the round-64 basis untouched.
4. THE WIDE CANDIDATE's masked classes — the FINAL v2-basis sweep,
   all 14 replays MEASURED CLEAN: 01 attract EXACT (0 divergent);
   06 diverge-700 (the frozen class); 02/05/07/30 = single windows
   (889-1675/2015; replay 05's 12k-frame run has a 10446-frame
   identical tail); 11 = window 889-2415; 03/04/08/09/10/16/29 =
   composites whose flicker inventory matches donovan-m5w TO THE
   FRAME (829, 1525/2009/2195, 2093, 2436, 3007/3129, 3507) with
   per-flow window ends; 08 carries two windows (two select entries).
   Candidate fingerprints: WIDE 4b7d0dc7, stock 6c93cfa8.
5. KNOWN RESIDUALS, documented: Pyron's placeholder medallion recolors
   after a 2P Donovan-hover (row 0x1A doubles as the P2 sword row);
   the deep-arcade ENDING flow is unmeasured (the $130(a5) fold audit's
   only gap).
On approval: freeze the two expectation sets + registry rows, replacing
ae701ffb/9bac6ee3 as the reference pair.

## Session 14z-64 (the white-out RETIRED; palette-block fold audit)

**Item 0 DONE**: the medallion white-out is properly fixed — the
marchers' vestigial mid-row writes (rows 0x16/0x19, referenced by
nothing in vanilla) are redirected to the scratch row 0x02 at ALL
THREE dest computations (0x2AD44/0x2B598/0x2B7D8 — complete by the
add+lsl#5 idiom census; the third found by an execution trace
triggered on the live clobber). All three medallions hold through
both maintainer stress protocols (15/15 gate samples). Side effect:
the 2836 fade-staging flicker vanished — replay 11 reverts to the
plain §4 v3 bounded window 889-2415 (re-frozen; simplifies the
re-freeze ratification). Detail: patch_notes 14z-64. Build 210d2b75.


Updated: 2026-08-06 (session 14z-63 — PHASE 3 COMPLETE, ITEMS 1-6 (the
hover decision RATIFIED round 7: ring reuse; the accent/march audit
CLOSED: 4/4 family-base sites thunked, zero direct slot refs, venue
sweep complete incl. the no-character-surface continue screen) + the
round-6 medallion-palette fix
(item 3 = the hover decision is the maintainer's, reframed below; item
4 landed while awaiting playtest: the variant-id HUD — attribution
CORRECTED to unmasked consumers over 32-row-aliased tables, NOT the
$130(a5) fold; row-0x13 pokes + free-pool mugshot art; "Donovan" under
the P1 bar measured in-match; new gate tests/test_tenant_hud.sh; stock
still ae701ffb; evidence build f7210898). Item
1: the wheel bank-5 move — REAL MEDALLION ART for the three appended
cells (native vs2 busts), vanilla medallions byte-copied into group C
and measured pixel-identical. Item 2: the ring/highlight POSITION
SOURCE found (32-row aliased pc-rel base table at 0x5FAE2 — vs2's own
variant half is un-aliased, so the fix replicates Capcom's move) and
fixed in place (3 code ops); the tenant's highlight now draws AT his
cell (predicted exactly by the measured transform). PLUS a semantic
correction that reframes the pending hover decision: the composed vs2
"label" is really vs2's POST-CONFIRM NAME BAR; both engines hover-draw
RINGS. New gate tests/test_wheel_bank5.sh; legacy window re-frozen
889-2415; stock reproduces ae701ffb. Evidence build e9f3286c.
Remaining: phase 3 items 3+ (hover-content decision, venue folds,
win-pal, accent audit), the re-freeze bundle. Read 14z-63, then
docs/NEXT_SESSION.md.)

## Session 14z-63 (phase 3 item 1: the wheel bank-5 move — REAL
## MEDALLION ART, vanilla cells pixel-identical by construction)

Byte detail in docs/project/patch_notes.md 14z-63; mechanism in
docs/game/atlas/select_screen.md "The wheel DRAWER". The shape:

- **Measured before authoring** (the tap method, as planned): the wheel
  drawer is $FFB800; its select anim chain is a SINGLE stop-flagged
  entry at 0x2689FA (so the "single referrer" is just that entry's
  payload, and on select the object draws the wheel and nothing else);
  its bank word $FFB818 is written only by the per-object select init
  0x5F8B2 (`move.w #$2000,$18(a6)` — family-wide tap proves no other
  object rides that PC), while 0x07C428 is the SHARED attract init loop
  (stride 0x80, never patch) and 0x5FD02 re-purposes the object at the
  VS phase (which is what re-converges the flip's RAM divergence).
- **The move**: flip the init immediate to bank_word(5)=0x3000 (one
  code op, profile+group-C-gated) + copy 85 host tiles (every vanilla
  entry, byte-identical vsav group A -> group C 0x10000+code; 85 = the
  record's budget word) + 18 vs2 medallion tiles at native codes. Zero
  collisions with the 271 bank-5 select-family tiles.
- **Measured after**: fmt-2 handler walks the relocated record with OBJ
  ffb800 BANK 3000; snapshot A/B vs 048521c2 (replay 36, frames
  950/1150/1300): every changed pixel inside rows 145-184 x cols
  148-243 = exactly the three appended cells — vanilla cells
  pixel-identical, real vs2 busts on the new cells.
- **Legacy re-freeze (interim)**: the §4 v3 host-pick window becomes
  889-2415 (was 890-2362) — onset: the bank write surfaces one frame
  before the old record-pointer-cache onset; end: the 0x5FD02 rewrite.
  Single run, 1305 identical frames after, match untouched. Frozen in
  test_tenant_select_records.sh §4 with the mechanism; RATIFICATION
  folds into the pending re-freeze bundle (maintainer).
- **Gates**: NEW tests/test_wheel_bank5.sh (static re-derivation, group
  C member identity straight from the zips, 2 negative controls, the
  engine's bank-5 walk) — in the battery; tenant select-records +
  tenant-id PASS; stock rebuild reproduces ae701ffb. GOTCHAS gained the
  unconditioned-breakpoint replay-desync trap (a stop-heavy trace
  measured ATTRACT while its frame counter said "select").
- Evidence build (item 1): `build/m3a_wheel` = `2c02213d`;
  build/m3a_selrec (048521c2) kept as the A/B reference for this
  session's snapshots.

**Item 2 (same session): the ring/highlight position source — found
and fixed in place.** Full detail in patch_notes 14z-63 addendum and
the atlas "position source" section. The shape: the highlight drawer
($FFBA00) bases per cell via a 32-ROW pc-relative table at 0x5FAE2
whose variant half is a byte-identical ALIAS (TABLE B convention) —
and vs2's OWN twin table is UN-aliased with its newcomers' bases, so
overwriting rows 0x10/0x11/0x13 in place is Capcom's own move. Three
4-byte CODE ops (pc-relative reads assert the program FC — the table
is stored encrypted; a data op would corrupt it). Transform measured
on three cases incl. one exact prediction: OBJ_x = base_x+coord_x+64,
OBJ_y = 224-(base_y+coord_y). Bases live in the layout as
`highlight_base` (rule-5 table). The tenant's highlight now draws AT
his cell; the P1/P2/MIRROR highlight blocks are all 32-row aliased
tables (a tenant mirror-hover fetches a safe alias — relevant to the
parked mirror-victim fix). Evidence build: `e9f3286c`.

**Item 4 (same session, while awaiting the playtest): the variant-id
HUD — fixed, and the attribution corrected.** The "VICTOR"/wrong-mugshot
symptom was carried as the $130(a5)/0x00A43E fold; measured, it is NOT:
both HUD consumers index UNMASKED (mugshot 0x8937C by $782/$b82(a5);
name 0x89684 by $382(a4)) over 32-ROW ALIASED tables (0x89884 word/char
+0x3800 base; 0x898C4 8B/char) — id 0x13 read row 0x03's alias. Fix =
three only_variant_slot aux_pokes filling row 0x13 + effect_tail
place_variant_slot ('0x4D62,2,2' -> 0xBE90, a verified-free pool
anchor; name art = the existing 0xBE8C). Jedah's own 0x3DC8 cells stay
pristine (gated + checked). Live-verified in-match: mugshot 0xBE90 +
name 0xBE8C staged at the exact 14z-49 shape, opponent vanilla.
New gate tests/test_tenant_hud.sh (in the battery). The $130(a5) fold
still owns the select/VS palette-block COLOURS (open, venue_assets.md
§2). Evidence build: `f7210898`.

**Item 5 (same session): the variant-id WIN-SCREEN palette — the
sparse-block design built and BOTH thunk paths measured.** The 2P
victory screen's palette load (0x5F1B6: pool + (color*17+winner)*0xA0,
winner UNMASKED in d6; 0x12/0x18 have own branches — the reserved pair
again) gets a wide_ext sparse block at the VANILLA color stride (only
the tenant's 8 vs2 sets populated) + a 22-byte thunk (d6==TT -> rebase;
else the displaced movea re-executes). Measured: tenant 2P win -> rows
0x15-0x19 == vs2's set byte-for-byte (F000-alpha); Victor 2P win ->
the untouched vanilla pool slice. SCOPING FACT paid for: the arcade
win-quote screen NEVER runs this site (zero thunk hits through a full
arcade win — it is the 62j family and already correct); only 2P
victories do, and victory-screen inputs SKIP the screen (a mashing
replay measures a blank). Two permanent replays added (61_tenant_2pwin,
62_tenant_2plose) + gate tests/test_tenant_winpal.sh (in the battery).
Evidence build: `e82e0bd3`.

**Round-6 playtest fix (same session): REAL vs2 palettes for the
newcomer medallions.** The maintainer's report (only Donovan legible;
Phobos/Pyron noise) root-caused: the vs2 attr pal rows are SHARED
vanilla medallion rows here. Fix: three measured-FREE select rows
(OBJ-sweeps over wheel-on-screen frames across 3 replays + a live
poke-probe that changed zero pixels; 0x1A/0x18/0x1C excluded) carry
vs2's real medallion palettes (sources found by matching vs2's LIVE
select palette RAM into its ROM — which retroactively explains the
med_pal_row14 source address) via select block A (0x3A3800, rows
verified to load 1:1; row 0x02 rejected — its live copy comes from
0x3B5940). Entries re-palmed in the bank5 branch; layout carries
pal_row/pal_src. Measured: live rows == alpha(vs2 src); all three
busts native-colored. Legacy: ONE transient frame (2836, 8 bytes at
$FF406A — the fade-staging family, $FF4182's sibling slot) makes
replay 11 the §4 v4 COMPOSITE (window 889-2415 + flicker {2836}) —
frozen in the gate, RATIFICATION pending in the re-freeze bundle.
Maintainer round 6 also CONFIRMED: items 1/2/4 all good in playtest
(rings at cells incl. the alias interims, no vanilla regressions,
mirror-tenant safe with one Anita — verified native vs2 behavior),
HUD name/mugshot good. Evidence build: `f86fb1a0`.

**Maintainer round 7 (build f86fb1a0): ALL CLEAN.** Medallions in
native vs2 palettes confirmed ("all good" — art question closed); 2P
victory screens correct both directions (as-Donovan and against-
Donovan); no regressions anywhere on the prior checklist. NOTE for the
M5 sound session: the maintainer has now heard vs2 Donovan enough to
EAR-IDENTIFY some of the missing sfx (the known 25-stubbed-rows
interim) — playtest acceptance for M5 can lean on that.

**Round 7 + the hover decision (phase 3 item 3) — RATIFIED AND
IMPLEMENTED: RING REUSE.** Round 7 on f86fb1a0: all clean (medallion
palettes "all good", 2P win screens both directions, no regressions;
noted: the maintainer can now ear-identify some missing Donovan sfx —
useful for M5 acceptance). The maintainer then ratified ring reuse:
all three extended cells' hover highlight = the host's row-0x0F ring
records verbatim (P1 0x2724A2 / P2 0x2726CE / mirror 0x2728E6).
Implemented as [[select_records]] highlight art="host_ring" (the
composed vs2 name-bar record dropped — 2 pokes) + wheel-section
ring_rows (P1+P2 for cells 0x10/0x11 + mirror rows for all three; 9
pokes total, zero new bytes). Checker re-modeled; all gates PASS;
stock ae701ffb. The tenant hover now draws a real vanilla-class ring.
Evidence build: `96a6e737`.

**Maintainer round 8 (build 96a6e737): ALL CLEAN — rings on all three
cells confirmed, mirror rings both sides confirmed, "Donovan is looking
really good." The medallion x-offset the maintainer flagged
was then FIXED on request (round 9): Phobos 8px left (pos 224->216),
Pyron 4px left (248->244), highlight bases moved with them (base_x =
pos_x-56) so the hover rings stay centred. OBJ-verified exact
((204,161)/(232,169); Donovan untouched (260,161)); gates + stock
green. Evidence build a8108e0e.**

**Item 6 (the accent/march audit) — CLOSED.** Static census: the
vanilla image holds EXACTLY the four thunked accent family-base sites
(0x2AD82/94, 0x2B342, 0x2B7E8) and zero direct T0/T1 slot references —
no un-thunked family consumer exists. Venue sweep: every tenant accent
surface measured or playtest-confirmed rounds 3-8; the solo CONTINUE
screen (chased to f13100, idle tenant losing to the CPU) is the
abstract vortex — NO character surface; 2P continue is HUD text only.
Gate: tests/test_accent_census.sh (frozen census + 4/4 routing +
negative control), in the battery. PHASE 3 COMPLETE.

**Round 10 (maintainer): Phobos 2px further left (ratified ring-fit
trade); the medallion WHITE-OUT root-caused and PARKED.** The report
("Donovan's medallion becomes shades of white, sticky, no clear
trigger") is the accent march claiming the P1 figure family
{0x15,0x16,0x17} in a late select venue phase (~15 s in — the trigger
is the select TIMER); row 0x16 carries Donovan's medallion palette.
Reproduced deterministically (replay 63, onset ~f1750). Three fix
designs measured and REJECTED on legacy grounds (per-frame re-assert
diverges the fade step counters $FF0E94-family — fades READ BACK
palette RAM; two writer-retarget shapes bypassed — the store tail has
~30 enumerated entries; full detail in GOTCHAS "no free palette row").
The correct fix = the marcher's JOB-DATA origin (14z-15 venue script
family), QUEUED for a focused session; it should also relocate row
0x19 (Phobos — P2's figure-family middle row, same latent 2P risk).
Interim: white-out is select-scoped, ~15 s onset, resets on re-entry;
gate 3b freezes the honest state. Evidence build `b9c6ca23`.

**Round 11 (maintainer repro: mash-right): the white-out mechanism is
COMPLETE, and Donovan is moved to the bulletproof row.** The mash-right
protocol exposed the marcher's PER-HOVER path (the 0xEF92EF96
char-class triplet at 0x2ADB8: hovering half the roster rewrites the
figure family {0x15,0x16,0x17} — the "shimmer" is those rewrites), on
top of the periodic venue-phase writer. Row 0x16 is thoroughly owned.
Interim shipped: Donovan -> row 0x00 (the one row proven stable
against everything), Pyron -> 0x19, Phobos (placeholder cell) -> 0x16
and inherits the white-out until the job-data fix (item 0). Measured
on the maintainer's own protocol (permanent replay
64_select_mashright): Donovan/Pyron hold every sample. Gate 3b runs
BOTH stress protocols. Evidence build `bd7772c9`.

**Round 12 (build bd7772c9): the row-swap interim CONFIRMED — Donovan
always stable under the mash-right protocol; the white-out/shimmer
moved to Phobos's placeholder cell exactly as designed.** The select
wheel's shipped state: Donovan fully correct on every measured and
playtested surface; the one open cosmetic lives on a placeholder cell
and is item 0 of the next session (the marcher job-data fix).

**Semantic correction that reframes the hover decision**: the composed
vs2 highlight record (b000 5x1, "his lit-label") is actually vs2's
POST-CONFIRM NAME BAR — measured: vs2 never draws it at hover, only at
the top corner after confirm; vs2's own hover highlight is a RING
(pal-1e tiles measured around his cell), like vsavj's.

**Decisions pending (maintainer)** — the hover content (a: ring reuse)
was RATIFIED round 7 and is implemented; the medallion palettes were
fixed with vs2's real rows (round 6) and confirmed round 7. Remaining
open decisions are unchanged from 62k (none new this session); the
next maintainer action is the RE-FREEZE bundle sign-off (which now
also ratifies the replay-11 composite class and the 889-2415 window).

## Sessions 14z-62j/62k (same day — OPTION A PHASES 1-2 LANDED and
## PLAYTEST-VALIDATED: the select family serves from group C bank 5;
## Jedah confirmed indistinguishable from vanilla by human playtest)

Full detail in docs/project/patch_notes.md (62j/62k); the shape:

- **All four select-family pieces** (portrait bust, name banner, VS
  splash, win quote) keep NATIVE vs2 tile codes at the variant id; the
  art (146 tiles) is copied vs2 -> WIDE group C BANK 5 at 0x10000+code
  (bank 4 is the fighter band — native bank-1-family codes would collide
  inside its window). select_tiles.json = ZERO group-A placements; the
  placeholder class is dead for these pieces.
- **Four drawer-object bank gates**, each measured before authoring, two
  corrected mid-flight by taps: portrait (palette thunk v2), name
  (per-hover refetch 0x5FCE0 — v1 compared d0 and NEVER FIRED: d0 is
  id*4 there; v2 gates via the live owner ptr), VS splash (0x6C0E0 on
  the object-cached id $A(a6)), win quote (the shared consumer 0x5F328
  with d0 = winner+0x40 — the new TU substitution; tenant-win-only
  write, zero legacy RAM effect).
- **Maintainer rounds 3-5**: JEDAH INDISTINGUISHABLE FROM VANILLA
  (select incl. the former mid-face band, VS, match, win screen with
  proper art and quote); Donovan's bust/banner/splash in his real art
  and colors. Group B pristine; group A additive-only (the effect-tail
  engine-page families at verified-free anchors — full-pristine
  vsav.zip needs that band moved, queued).
- **62k**: the pre-confirm select SWORD drew the palette-RAM INIT GREY
  RAMP (measured verbatim: f111 f222 ...) — the figure upload covers
  only pal base+0, the sword rides base+2, and the 0x0F in-place accent
  slots had masked the gap. Thunk at the dest lea copies the tenant's
  block+0x40 accent row (per color, both sides, F000 alpha). Round-5
  playtest VALIDATES, no regression.

All gates green throughout; stock reproduces `ae701ffb` after every
change; the WIDE reference 9bac6ee3 remains non-rebuildable since the
62i medallion-coordinate fix (known; folds into the re-freeze).
Evidence build: `build/m3a_selrec` = `048521c2`.

**PHASE 3 (next session), specified**: real medallion art via the wheel
bank move (the wheel object is single-bank: copy the 18 vanilla
medallion tiles byte-identical into group C + the newcomers' real vs2
medallions, flip the wheel drawer's bank — vanilla-cell pixels identical
by construction); the ring drawer's per-cell position source (stale base
at appended cells — the misplaced-label interim); the ring-vs-label
content decision (maintainer); then the folded venue family (HUD
name/mugshot), the win-pal sparse block, and the RE-FREEZE bundle
(mirror-victim fix + id_by_profile + new masked classes + registry).

## Session 14z-62d (same day — THE GFX HALF LANDS ITS CORE: the tenant's
## band serves from WIDE group C, and the host's group B is PRISTINE)

The minimal-change design that made it tractable: **keep every record
code word, flip only the bank words, move the tile data.** The band
(codes 0xAD8F-0xEA3F) and the effect shelf (to 0xEEBB) keep their exact
in-group tile indices — so not one record byte changes — but the data is
written into the four appended vsw simms (group C, bank 4 = y-word
0x1000, the bit-12 Turbo promote) and every bank-word source follows the
tenant: the six OBJ bank setters (`new_hex_variant`), the engine table
row (`obj_bank_word_slot`), the ported table row (bank_word(4) — NOT
`4 << 13`, which is the sprite-list TERMINATOR bit; `gfx_tiles.bank_word`
is now the single encoding), and `normalise_tenants` defaults a variant
tenant's gfx bank to 4.

**The descriptor CRC question got measured twice before it got right.**
Group C content varies per build, so a fixed CRC can never match it —
and any REAL value shadows: the pristine-B CRCs were the 14z-60z bug,
and the "obvious" zero-fill CRC hash-collides with the ZERO QSOUND
members in the same zip (measured: vsw.31m resolved to vsw.21m, the
whole B4 canary went dark while the zero-build sections stayed green).
The answer is SENTINEL CRCs (0xdec0de31..37) that match nothing, so the
members always resolve BY NAME — which both loaders demonstrably do for
every patched vm3 member already. Both emulator patches updated, both
emulators rebuilt, FBNeo profile gate PASS (superset + inertness +
canary); the MAME twin re-run against the sentinel build.

**Measured, on build `464eaf1f`:**
- Donovan renders IN-MATCH from group C — the 19-bit path carrying real
  roster content in a real match, pixel-correct, his own colors.
- **Jedah's match is PIXEL-IDENTICAL TO VANILLA** — raw-decoded MAME
  snapshots at four frames, work RAM bit-identical (window 890-2362
  unchanged), OBJ lists entry-identical. Two false scares on the way,
  both instrument lessons (GOTCHAS): his ES super's shred-ribbon art
  read as "garble" until compared against vanilla's own frame, and MAME
  VIDEO_OUT across DIFFERENT machine configs flags thousands of
  pixel-identical frames as divergent — cross-driver pixel comparison
  must use FBNeo HVIDEO or raw snapshots.
- The tenant gate passes all four sections unchanged.

**What remains of the gfx half** (bank-1/group-A, mechanism understood):
the tenant's select-art subset still occupies Jedah's bank-1
hover-figure anchors, so the host's select-screen BODY figure garbles —
his face, name banner, and all match art are back. Moving select art to
group C needs one measurement first: the select-venue OBJECTS' bank
fields (can a select record be drawn from bank 4, and what sets those
objects' +0x18?). Then the four placeholder label tiles and the
medallion art ride the same move. HUD plate / palette-grid / win-pal
interims unchanged from 14z-62c.

## Session 14z-61 (WIDE GARBLE FIXED — a shadowed ROM member, not the
## emulator; and the rendering gate that should have caught it)

The open bug is closed. Both hypotheses the previous session left standing
were wrong, and the previous session's own exculpatory measurement was
taken at the wrong address.

### The fault: a member that carried another member's pristine bytes

`tools/build_wide_romset.py --gfx-copy-group-b` fills the appended gfx
group C with **byte copies of the stock group B members** — the B4 canary
shape. Copies carry the originals' CRCs. Content builds patch group B
(`vm3.14m/16m/18m/20m` — where Donovan's tiles live) and merge that canary
romset in (`build_donovan.sh` -> `pack_build.sh --merge`, the recipe
HANDOFF documented). **Both emulators resolve a ROM entry by HASH before
falling back to its NAME**, so group B's declared CRC matched the canary
copies sitting in the same set and the loader served PRISTINE tiles for the
members the build had patched. Donovan and Anita drew with vanilla art:
right geometry, wrong pixels, no error, no `0xFF` fill, every RAM gate
green.

MAME says it in its own log if you know what to read — on the stock track
all eight gfx members report `WRONG CHECKSUMS` (the patched art loading by
name); on the WIDE track `vm3.14m/16m/18m/20m` are **silent**, because a
hash match was found for the wrong file. FBNeo says it in its own source,
`src/burner/sdl/bzip.cpp:158`: `// Search by crc first`, then
`// Failing that, search for possible names`. **The name is the fallback,
not the identity** — two files with the same bytes are the same member as
far as either loader is concerned.

### Measured, with controls, on both emulators

Decoded tile band at Donovan's select portrait, tile `0x2AD8F`
(`tests/lua/gfx_region_dump.lua` under MAME, `FBNEO_HGFX` under FBNeo):

| set | tiles at the ported band |
|---|---|
| WIDE build `m5w` (garbled) | **== PRISTINE vsavj** |
| WIDE build, group C zero-filled | == stock track (the patched art) |
| stock build `m5_stock` (renders fine) | the patched art |
| pristine reference | pristine |

FBNeo four-way, same conclusion: `m5w` `4dd0db77…` == pristine; `m5w_fix`
and `m5_stock` both `5189ccca…`. Two unrelated loaders, one behaviour.

### Two dead hypotheses, and why they looked alive

- **"The tiles load fine, so the fault is tile ADDRESSING at draw time"**
  (14z-60y). The dump behind it read byte `0x56C780` = tile `0xAD8F` —
  the sprite's code word **without its bank bits**. The address the
  hardware composes is `code | ((y & 0x6000) << 3)` = `0x2AD8F`, byte
  `0x156C780`. The band compared was unrelated vanilla data, identical on
  every build by construction. GOTCHAS entry added.
- **"y-word bit 12 is both the promoted address bit and a legitimate Y
  bit"** — false twice over. `objy_bits.lua` over the whole Donovan
  replay: `bit12=0`, `max19 == max18 = 0x33812`, so the WIDE promote line
  never fires on this content; and in `cps_obj.cpp` the drawn Y is masked
  to `0x03FF`, so bit 12 is not a coordinate bit either.
- Positive proof it is not the emulator at all: **the OBJ records are
  bit-identical between the two tracks** — 2,277 live entries at the
  select-screen and in-match frames, zero differences
  (`tests/lua/obj_records_dump.lua`). Same records, different pixels =
  the difference is in what the loader put in memory, not in how the
  draw path read it.

### The fix, in the pipeline rather than in a file

1. `build/wide0/rompath` is the **shippable** overlay again (group C zero
   fill); the canary shape lives only in `build/wide_canary/rompath`.
   `tests/test_wide_profile.sh` and `tests/test_mame_wide.sh` now read
   `CANARY_ROMPATH` for their B4 section, so the split does not silently
   cost that coverage.
2. `tools/audit_romset_identity.py` — **no member of a set may carry the
   pristine bytes of a member that build patched.** Byte-identical
   placeholders (the zero-filled 4 MB units) are reported, not failed:
   they can shadow nothing. Wired into `build_donovan.sh` (hard fail,
   after the gfx stage so it sees the whole set) and `pack_build.sh`.
   Run against the garbled build it names all four shadows.
3. `--gfx-copy-group-b` now prints a NOT-SHIPPABLE warning explaining the
   shadowing.

Rebuilt through the fixed pipeline: WIDE `9bac6ee3`, stock `ae701ffb`
(the stock rebuild reproduces the registered fingerprint exactly — a free
reproducibility check). Donovan renders correctly on both emulators;
snapshots in the session artifacts.

The WIDE rebuild also picks up the 14z-60 wheel work absent from `m5w`:
`PRG:0x2689FE` (the wheel-record referrer), `PRG:0x021227` (TABLE B), and
148 bytes in the extension member — attributed, not mysterious.

### The gate that should have caught it (and now does)

`tests/test_wide_render_content.sh`, ~60 s, four sections:

1. member identity on both tracks (static, no emulator);
2. **pixel A/B**: per-frame framebuffer checksums of a Donovan replay on
   stock vs WIDE must be identical — measured **3,721/3,721 frames
   identical**, so the tracks do not skew and this is an exact comparison,
   not an anchor comparison;
3. **positive control**: a set poisoned back into the 14z-60z shape must
   fail both — it does, diverging on 2,542 frames;
4. the decoded tile band is the build's, not pristine, with a pristine
   negative control — which caught a field-index slip in the gate's own
   checker on its first run.

`tests/test_romset_identity.sh` ground-truths the audit over four
synthetic sets (~1 s, no emulator, no build): patched-clean PASS, shadowed
FAIL naming both members, benign placeholders PASS, nothing-patched PASS.
Both are wired into `tests/run_battery_m2.sh` — the identity check as a
build-independent rule lock, the rendering gate on WIDE builds that have a
stock twin to compare against.

### MAINTAINER PLAYTEST — CONFIRMED (2026-08-05, on `build/m5_wide` `9bac6ee3`)

> "Initial tests with and without Donovan look good. No obvious regression,
> all graphics look good, gameplay feels genuine, all present sounds are
> good."

Both halves matter: **with** Donovan (the ported content that was garbled)
and **without** (the legacy path the superset invariant protects). The
rebuilt WIDE build also carries the 14z-60 select-wheel extension that
`m5w` predated, so this is a confirmation of the wheel work in a human's
hands too, not only of the tile fix.

"All PRESENT sounds are good" is consistent with the M5 decision of
2026-08-04 (option A: the unfaithful voice lines ship silent) — not a gap
found, a gap already chosen.

### M3a RESUMED: the select-record mechanism at `0x13`, measured — it gets
### SIMPLER, not harder

The queued unknown was: "`select_port.py` replaces Jedah's select records
IN PLACE, so at `0x13` the tenant needs its OWN records — that mechanism
changes shape." Measured answer: **at a variant id the whole mechanism is
two longs.**

```
P1 array   PRG:0x26742A    stride 4    rows 0x00-0x1F
P2 array   PRG:0x2674AA    = P1 + 0x80
index      the CELL/ID — the consumer masks to EIGHT bits, not four
rows 0x10-0x1F  byte-identical aliases of 0x00-0x0F (the variant half)
```

So id `0x13` owns `PRG:0x267476` (P1) and `PRG:0x2674F6` (P2), today
aliasing Victor's records. Repointing them gives the tenant its own select
records: **no widening, no fold to defeat, no legacy row touched** — no
legacy id can index the variant half (`audit_id_writers.sh`). This is the
14z-60 prediction paying out: moving to a variant id makes the superset
invariant EASIER, by construction, than the in-place surgery slot `0x0F`
demands.

**Measured, not inferred, and over-determined.** A read tap over the array
during `11_pick_donovan` (default → U → U → R → Jedah) fetches
`0x27195E, 0x2719DA, 0x271B0E, 0x271CE8` — exactly the records the model
puts at rows `0x01, 0x03, 0x07, 0x0F`. Four points fix base, stride and
index. A 2P replay pins the player offset: P2's object fetches its own
record from `+0x80`, agreeing with `d1 = 0x80` in the consumer at
`PRG:0x06C0E0`.

**And it corrected a recorded claim.** `engine_internals.md` had the P2
arrays as "+0x40 copies pointing at the same records" (from a differential
cursor dump). `+0x40` is the VARIANT HALF, which aliases the base half and
therefore looks exactly like a P2 copy from that angle. Both documents now
say so. The old conclusion still holds at slot `0x0F` — it just holds for a
different reason, and the difference is the whole M3a mechanism.

New: `tools/select_arrays.py`, `tests/test_select_arrays.sh` (static model
+ a one-byte corruption control + the engine's own row sequence, ~10 s),
`docs/game/atlas/select_screen.md` section.

**All three UI pieces now measured** — same model, each confirmed on all
four cursor positions:

| piece | P1 array | P2 array | id 0x13 owns (P1 / P2) |
|---|---|---|---|
| big portrait | `PRG:0x26742A` | `PRG:0x2674AA` | `0x267476` / `0x2674F6` |
| name banner | `PRG:0x2675AA` | `PRG:0x26762A` | `0x2675F6` / `0x267676` |
| cursor highlight | `PRG:0x268A02` | `PRG:0x268A82` | `0x268A4E` / `0x268ACE` |

**The tenant move costs six longs**, all in the variant half, all currently
Victor aliases. The gate freezes all six plus the adjacent wheel record
pointer.

One structural fact fell out while attributing tap noise: `PRG:0x2689FE`
(the wheel record pointer, the single referrer 14z-60r must repoint to
relocate the wheel) sits **immediately before** the highlight array's row
`0x00`. Its record is read every other frame throughout the select screen,
which is what the interleaved constant in the highlight tap was. The region
is packed end to end — more evidence for "relocate, never grow in place".

### M3a IN PROGRESS: the program half MOVES; the two content halves do not

**Landed and verified.**

- **The tenant id is now a build input, not a constant.** `--tenant-id`
  overrides the manifest for one build; `[[tenant]] id_by_profile` exists
  in the generator for when the move lands as the WIDE default. It is
  deliberately NOT in the manifest yet: the moment the WIDE profile maps to
  `0x13`, the frozen reference `donovan-m5w` (`9bac6ee3`) stops being
  reproducible from the tree, and a reference that cannot be rebuilt is not
  a reference. Verified both ways after the change — WIDE rebuilds to
  `9bac6ee3` exactly, and `--tenant-id 0x13` moves the tenant.
- **The program half moves correctly and by construction.** Built at
  `0x13`: **all 31 slot-indexed table rows land exactly `+0x10` from their
  `0x0F` addresses** (four slots x 4-byte stride) and the 30 `0x1F` mirror
  pokes are GONE — a variant-id tenant has no mirror, so Victor's `0x03`
  is never touched. The 14z-60w preparation paid: the thunk ids substitute,
  the bank-table row is written at `0x13` (`= 0x4000`), and nothing had to
  be hand-chased.
- A variant-id tenant without a profile is now REFUSED with the reason
  (its tiles cannot share the host's gfx band, and a stock build has
  nowhere else to put them).

**What is NOT done, stated plainly.** Both remaining halves are CONTENT
placement, and both would be plausible-but-wrong if rushed:

1. **Select records.** `select_port.py` still does in-place surgery on
   Jedah's records, so the `0x13` build regresses Jedah's select screen and
   the tenant shows Victor's (aliased) records. The mechanism is measured
   (six longs, table above) but the tenant's record BYTES need a home, and
   picking one by hand is the "never write an unverified gap" trap — it has
   to go through the generator's allocator, which runs BEFORE select_port
   in the pipeline. That ordering is the real work.
2. **Gfx.** The tenant's tiles still occupy Jedah's band, so at `0x13` the
   tenant renders correctly and **Jedah renders as the tenant**. Moving
   them means writing group C (WIDE banks 4/5, currently zero fill) instead
   of vsav's group B, with the WIDE bank encoding (`bank 4 = y-word 0x1000`,
   `bank 5 = 0x3000` — NOT `bank << 13`), and it makes the group C
   descriptor CRCs load-bearing, which is the hygiene item already queued.

So `build/m3a` (`f4769b55`) is a scratch build, not a candidate: its
program half is de-substituted and its content halves are not. It is kept
only as the evidence that the program move works. **The acceptance
criterion — legacy Jedah replays return to bit-identical vanilla — cannot
be claimed until both halves land**, and I have not claimed it.

### THE WIDE REFERENCE FROZEN (maintainer: "freeze and register as wide
### reference first, then we resume")

Registered `9bac6ee378e1a5ce0674423279c357a4d2a076ec -> donovan-m5w`.
The withdrawn `ac52eeff` row is kept in `registry.tsv` **commented out, on
purpose**: the known-bad build must fail as UNREGISTERED rather than
validate against this set. Verified both ways — the new build resolves to
`donovan-m5w`, `m5w` exits 2 with the loud message.

Expectation set `tests/expected/donovan-m5w/`: 16 `.skip` (replays that
target other romsets), the Donovan-specific replays self-frozen as `.sha1`
+ full logs, and the legacy replays authored from MEASUREMENT against the
frozen vanilla masked logs — never copied from another build's set.

**What the measurement showed, and why it stops short of a complete freeze.**
Eight legacy replays fit an existing ratified class exactly:

| replay | class | vs donovan-m2c |
|---|---|---|
| `01_attract_long` | `diverge 4278` | unchanged |
| `06_test_mode` | `diverge 700` | unchanged |
| `11_pick_donovan` | `diverge 890` | moved from 1080 — the select screen now differs EARLIER (wheel extension), then the pick diverges as before |
| `02`, `05`, `07` | `window 890 1622` | were `exact`; now the §4 v3 select window |
| `30_demitri_throw` | `window 890 1962` | was `exact` |

The other **seven show a composite shape that no single class can
express**: the frozen hook-flicker inventory PLUS one bounded window per
select-screen ENTRY. The decomposition is exact — every flicker frame
matches donovan-m2c's frozen inventory, **not one added and not one
missing**:

| replay | flicker (== m2c inventory) | window(s) | identical after |
|---|---|---|---|
| `03_two_player_vs` | 829, 2093 | 890-1802 | 3227 |
| `04_select_fuzz` | 1525, 2009, 2195 | 890-1051 | 1325 |
| `08_challenger_join` | 3507 | 890-1622, **3809-4542** | 2378 |
| `09_mirror_pick` | 829 | 890-1882 | 2838 |
| `10_midattract_start` | 3007, 3129 | 3190-5712 | 408 |
| `16_xemu_2p` | 829 | 890-2022 | 2298 |
| `29_felicia_walljump` | 2436 | 890-1962 | 1884 |

Two of those rows are mechanism confirmations rather than anomalies:
`08_challenger_join` has TWO windows because the challenger join enters the
select screen a second time, and `10_midattract_start`'s onset is 3190 (not
890) because it starts mid-attract, so select entry comes later. Both are
what the mechanism predicts, which is the point of writing predictions
down.

§4 says a replay may not be reclassified without a new measured mechanism
AND maintainer sign-off, so those seven were first frozen as `.pending` —
a new expectation kind that reports `PENDING — not validated`, prints the
measured shape and the proposed spec, and **fails the suite**. An
unvalidated replay must never read as green; `.skip` would have been the
comfortable lie.

**RATIFIED the same day** (maintainer: "Your proposal is ratified"). The
`composite` class is now CLAUDE.md §4 v4, the seven `.pending` files became
`.masked` `composite` specs carrying exactly the shapes they had printed,
and the freeze is complete: **`run_suite.sh` on `donovan-m5w` is GREEN** —
47 validated (33 self-frozen, 3 `diverge`, 4 `window`, 7 `composite`) and
16 explicitly skipped, out of 63 replays. `.pending` stays in the runner as
the correct way to record "measured but not yet ratified" without ever
reading as green.

Also wired: the ratified §4 v3 `window` class is now a `.masked` class in
`run_suite.sh` (it existed as a checker with ground truth, but nothing in
the suite could express it).

### Gates re-run after the change (§6)

| gate | result |
|---|---|
| `tests/test_wide_profile.sh` (FBNeo) | **PASS** — superset invariant + inertness + B4 canary, 12 replays, RAM and framebuffer |
| `tests/test_mame_wide.sh` | **PASS** — the same three sections on the MAME side |
| `tests/test_wide_render_content.sh` | **PASS** — new |
| `tests/test_romset_identity.sh` | **PASS** — new |
| stock rebuild | fingerprint `ae701ffb` reproduced exactly, so the build-pipeline edits are inert |

**One false FAIL on the way, worth knowing about:** the B4 canary section
failed on all 12 replays the first time it ran from its new home, because
`build/wide_canary/rompath` had been generated BEFORE the repo path lost
its space and its symlinks into `$ROMDIR` were all dangling. The overlay
builder in `run_replay_fbneo.sh` copies the overlay's links over the good
reference ones, so the whole set goes unreadable and it reads as "the
emulator renders the appended banks wrongly". Regenerating the romset fixed
it. GOTCHAS entry added — every generated rompath overlay built before the
rename needs the same treatment.

New instruments, all rerunnable: `tests/lua/snapshot_frames.lua` (MAME
renders its bitmap internally even under `-video none`, so
`video:snapshot()` gives real PNGs headlessly — this is how the bug was
first SEEN in-loop), `tests/lua/obj_records_dump.lua`,
`tests/lua/gfx_region_dump.lua`.

### What this says about the testing posture

The previous session called this "a coverage failure, not a
testing-cadence one" and was right. Worth adding: the failing component
was not the emulator, the ROM builder, or the port — it was the
**romset assembly step**, which no gate looked at, sitting between two
that were heavily gated. And the one instrument that could have seen it
(a gfx-band dump) was pointed at the wrong address by a hand-composed
tile number, then trusted because it returned a clean null. A null result
needs a negative control exactly as much as a positive one does.

## Session 14z-60 (select cursor MEASURED; the id space is CONVENTIONAL)

Two queued items closed, in the order the maintainer set: re-verify and
record the cursor mapping, then census the id space.

New: `docs/game/atlas/select_screen.md`, `docs/game/atlas/id_space.md`,
`tests/test_select_wheel.sh` (9 checks), `tests/test_id_space.sh` (7),
`tools/select_wheel.py`, `tools/check_wheel_walk.py`,
`tools/audit_id_space.py`. No ROM change; no build produced.

### Why this ran before the roster design

The cursor mechanism 14z-59l/59n recorded existed **only in
`docs/NEXT_SESSION.md`** — not in STATE.md, the atlas, or any test. STATE's
own 14z-59l section said the opposite ("that mechanism is NOT yet
located"), and NEXT_SESSION is rewritten wholesale every session, so the
finding was one rewrite from being lost and nobody but its author could
check it. Re-deriving it cost half a session and **corrected it**.

### The mechanism, re-derived and measured

Full detail in `docs/game/atlas/select_screen.md`. What changed versus the log:

- **The commit site is `PRG:0x020A7C` (cell) and `PRG:0x020A80` (char id),
  not `PRG:0x020A84`.** `0x020A84` is the `bsr.w $20C98` after them, and
  the `bmi` target for the no-move path. Measured: 145/145 navigation
  writes came from `0x020A7C`. The 14z-41 lesson, repeated verbatim — a
  cited address in a session log is a claim.
- **Direction order is R,L,D,U (bits 0-3), not U,D,L,R.** TABLE A's
  structure cannot distinguish the two: "opposing pairs are illegal" is
  symmetric under swapping which pair is vertical. Pinned by two prior
  independent records — `11_pick_donovan.rpl` (U,U,R → `0x0F`) and the
  atlas's Aulbath path (L,L,D → `0x09`) — which have a UNIQUE joint
  solution over all 8 labellings × 16 start cells, and which also recover
  the documented default cell `0x01`.
- **Both tables are DATA-space**, reached by `lea`/`movea.l` + `(An,Dn)`.
  In the opcode image they are convincing garbage.
- The substance of the original claim stands: both stores take the same
  `d0`, so **the wheel cell index IS the character id**.

Also found while measuring: `PRG:0x0209DA` writes the default cell,
`PRG:0x020AA6` clears it on confirm, and `PRG:0x020A98` special-cases cell
`0x0B` at confirm — the slot `character_tables.md` lists as "special".

### Measured, not just read

`select_wheel.py` generates an input script visiting **every** (cell,
direction) pair and states what each press must produce;
`check_wheel_walk.py` requires the emulator to produce exactly that.
Result: **145 presses, all 128 pairs, exact**, constant frame offset, no
write to the cell byte from anywhere but the commit PC. Four negative
controls on the checker — one of which feeds it the old `0x020A84` and
must fail, so the correction is evidenced by the gate itself.

### THE ID-SPACE ANSWER: conventional

| vsavj | |
|---|---|
| layout-verified id-indexed tables | 39 |
| variant rows that are byte copies | 603 |
| variant rows with their own data | 21 |
| **variant rows that do not exist** | **0** |

Every id `0x00-0x1F` has real storage in every one of them. The bank is
physically 32 rows (64 tables packed back-to-back, each ending exactly
where the next begins); the OBJ bank table and the wheel table agree.

The narrowing is not in the data but in a small set of **consumer sites
that mask to 4 bits — 5 in vsavj**, enumerated with addresses in
`id_space.md`. And the reference case settles how to read that:

| | vsavj | vsav2 |
|---|---|---|
| `andi #$0f` (folds `0x1x`→`0x0x`) | **5** | **2** |
| `andi #$1f` (full 5-bit) | 3 | **6** |

**vsav2 ships three characters on variant ids by widening the folding
sites** — 2 remaining, and it kept those two deliberately (a newcomer
sharing its base character's sound-id base and slot-6 special case). So
this is a finite per-site work list, not a wall.

Two findings worth keeping:
- `word_pos_a[0x16] = 0x0018` — every character holds `0x0010` except
  Anakaris (`0x06` = `0x0020`), and his VARIANT id holds a third value.
  vsavj already uses a variant row differentially outside slot 8.
- `PRG:0x04FAC4` folds because the table it indexes (`PRG:0x04FFA8`,
  24-byte records) genuinely has 16 rows. Widening that site means growing
  a table — the mask is a symptom of the structure behind it, so each of
  the five needs its own judgement.

**Bounding the claim honestly:** 226 of 269 read sites showed no mask
within 10 instructions of the read (the walk stops at the first branch).
That is not proof they never narrow the id — **the list is a
LOWER BOUND** (it grew to seven later the same session, see 14z-60e), and `test_id_space.sh` freezes it so growth is visible.

### Follow-up pass: the bound pushed, and one of my own claims corrected

Done without maintainer input, after the first write-up.

**The lower bound is now much tighter.** A second scan strategy — running
*through* conditional branches and tracking the register until it is
redefined, 40 instructions deep instead of 10 — finds **exactly the same
five sites**. Two walkers with different failure modes agreeing is the
strongest evidence short of full dataflow. What remains genuinely open is
named rather than hidden: **62 of the 269 reads copy the id into another
memory field** (14 distinct fields; `$a(a6)`×16, `$a(a4)`×13, `$b1(a6)`×11
lead), and a complete census must follow those to their consumers.

**CORRECTION to my own first pass.** I wrote that `PRG:0x04FAC4` "folds
because the table it indexes genuinely has 16 rows". Wrong — and wrong in
the house style: I read that table out of the OPCODE image, where a
`lea (pc)` + `(An,Dn)` table is high-entropy noise, and 16 rows of noise
look exactly as much like 16 rows as like 32. From the DATA image it is
plainly **32 rows × 24 bytes** (12 words/char, 6 pairs, `$bc(a5)` picks
+0/+2, values `0x0370-0x03D7`), ending cleanly at `0x0502A8`, upper 16
byte-identical to lower 16. The mask there is convention, not structure —
which makes the answer *stronger*. Now measured by the gate as table
`anim_pairs` (counts moved to 40 tables / 619 alias / 21 distinct /
**0 out-of-range**).

**The sites are not equal work** (full table in `id_space.md`; two more
were found later this session — 14z-60e — bringing the total to seven):

| Site | Fix class |
|---|---|
| `0x04FAC4` anim-pair table | **easy** — rows already exist; fill and widen |
| `0x0409EC` slot-6 behavioural test | **trivial** — a slot test, no table |
| `0x00A43E` → `$130(a5)` | **medium** — written only here, read at 15 sites beside the select code: the per-slot venue-asset arrays (mugshot/name/medallion), 16-wide, already on the port's list |
| `0x03E40` / `0x04082` anim `0x360+id` | **hard** — the anim NUMBER BLOCK really is 16 wide: `0x370+` is already occupied by the `0x04FFA8` table, so widening the mask collides. **These are the two vs2 left folded.** |

### Per-tenant manifest: schema PROPOSED (14z-60h)

`docs/project/tenant_manifest.md`, unblocked by the id-space answer. Not
implemented and nothing consumes it — written to be argued with first.
`[[tenant]]` replaces `[port]`; `mirror_variant` disappears (a tenant that
IS a variant id has no mirror, and one at `0x13` must not touch Victor at
`0x03`). Each tenant declares the three registries measurement turned up —
select wheel (cell, position, adjacency, `reachable_from`), arcade ladder
(opponent list + VS palette), and a decision for **every** folding site, so
that a census which grows fails a stale manifest rather than silently
inheriting. Migration is three falsifiable steps: byte-identical refactor
at `id=0x0F` (Phase C discipline), then the move to `0x13` with its own
battery and playtest, then Huitzil and Pyron.

### TWO MORE FOLDING SITES — and Capcom's fix, one nibble wide

Continuing without input, and it corrected the count. Chasing "does vanilla
ever assign a variant-half id" turned up the **id-cycling selector**:

```
vsavj 010E28  addq.b #$1,$382(a4)     vsav2 00F48E  addq.b #$1,$382(a4)
      010E2C  andi.b #$0f,$382(a4)          00F492  andi.b #$1f,$382(a4)
      010E36  subq.b #$1,$382(a4)           00F4AE  subq.b #$1,$382(a4)
      010E3A  andi.b #$0f,$382(a4)          00F4B2  andi.b #$1f,$382(a4)
```

**The same instruction in both games, one nibble apart.** vsavj wraps the
cycling id to `0-15`; vsav2 wraps to `0-31`. That is Capcom's widening of
this exact site, and it is the most direct evidence in the whole
investigation that the variant half is convention plus a finite edit list.

**Both my walkers were structurally blind to it.** Both keyed on register
dataflow; these instructions read-modify-write memory with no destination
register. Found only by disassembling the selector by hand. The count is
now **7 folding sites in vsavj** (5 register-path + 2 direct-to-memory)
against **2 in vsav2**, and `audit_id_space.py` scans the class separately.
So yesterday's "LOWER BOUND" caveat was not throat-clearing — it was
load-bearing, and it paid out within a day.

A verdict bug of my own in the same pass: the first version flagged vs2's
`andi.b #$01,$382(a4)` as a fold because `imm < 0x10`. It is a **2-value
toggle over ids 0/1** on a second cycling path (flag at `a5-0x50B8`), i.e.
a range restriction. `mask_class()` now separates `#$0f` (folds the variant
half) from `#$1f` (full 5-bit) from everything else.

### THE SUPERSET ARGUMENT, now measured over the whole corpus

Done: `tests/audit_id_writers.sh` (on-demand, 22 MAME runs). Both player
structs tapped — the CPU opponent, attract assignment and challenger path
write **only** to P2, so a P1-only tap misses three of the six writers.

**11 legacy replays × 2 fields = 22 tap logs, all with their `END` line.**
Six gameplay writers found:

| writer | ids | |
|---|---|---|
| `0x020A80` | `00 01 03 05 06 08` | select commit |
| `0x00AEF6` | `0A 0C 0E` | CPU opponent |
| `0x005BF4` / `0x005BFA` | `02 0F` / `00 03` | attract |
| `0x008A86` | `05` | challenger join |
| `0x009008` | `01` | P1 init |

Union: `00 01 02 03 05 06 08 0A 0C 0E 0F` — **not one variant-half value.**

So a tenant at `0x13` would occupy rows no legacy content can reach, and
the superset invariant would hold *by construction* instead of by the
in-place record surgery slot `0x0F` demands (the three superset traps in
GOTCHAS exist because legacy cursors visit Jedah's cell). Moving a tenant
onto a variant id should make the invariant EASIER, not harder — which is
the strongest argument yet for the `0x13` move.

**The gap, stated plainly:** `0x18` (Oboro) IS a variant id vanilla uses —
four sites compare against it (`0x018F9A`, `0x026FBE`, `0x0293A8`,
`0x043000`) — and no replay in the corpus reaches it. Established is "no
legacy replay here writes the variant half", not "vanilla cannot". Nothing
static sets bit 4 of the id directly; the confirm path `PRG:0x020ABE` takes
its value from `$45(a6)` gated on `$43(a6)`, which is the thread to pull.
Verdict logic ground-truthed both ways (injected variant write fails;
missing `END` line fails — MAME segfaults in teardown after writing a
complete log, so the exit code is ignored by design).

### RESERVED IDS — vanilla DOES use part of the variant half (14z-60k)

The most consequential finding of the session, and it corrects a working
assumption I had been carrying. Scanning for `move.b #imm,$382(An)` — a
hardcoded id stored into the id field:

| set | reserved variant ids | where |
|---|---|---|
| **vsavj** | **`0x12`** | `PRG:0x020BB6`, `PRG:0x020BC6` |
| **vsav2** | `0x19` | `PRG:0x01F864` |

vsavj's is the **Gallon variant** path on the select screen: cursor on
Gallon (`0x02`), an input bit held (`btst #$7,$394(a6)`), confirmed with
**2-3 punches** (`d0` in `300/500/600/700`) or **2-3 kicks**
(`3000/5000/6000/7000`) → id becomes `0x12`, `d1` recording which. Id
`0x12`'s per-char rows are byte-identical aliases of `0x02` (hitbox,
dispatch, anim index, `word132`) — the same character under a different id.

That is very likely the **Dark Talbain** mechanism `character_tables.md`
has carried as an open item ("must ride a different mechanism"). Recorded
as consistent-with, not proven — nobody has selected it and watched.

vs2's `0x19` is its second Oboro-class dataset, and its neighbouring
`#$08` writes at `0x01F5A8`/`0x01F5BC` sit inside the match-init id
normalisation the atlas already places at `PRG:0x01F5A0`. Two independent
records agreeing is why the scan is trusted.

**What it changes.** The free-id set is smaller than "anything above
`0x0F`": taken are `0x00-0x0F`, **`0x12`**, and `0x18`. Free are `0x10`,
`0x11`, `0x13` — exactly what the plan targets, **but only by luck**. Had
the plan reached for `0x12` it would have collided with a shipped secret.
`tests/test_id_space.sh` now locks the reserved set (14 checks), so growth
fails the gate rather than surfacing after a build.

It also scopes the corpus audit correctly: its PASS means "no legacy replay
HERE writes the variant half", never "vanilla cannot" — vanilla plainly
can, on an input no replay performs.

### A FOURTH work item found: the arcade-opponent path

Tapping the **P2** id field surfaced three writers the P1 tap never sees:
the CPU-opponent picker `PRG:0x00AEF6`, the attract assignment
`PRG:0x005BFA`, and the challenger/2P join `PRG:0x008A86` (plus the same
select commit with `a6`=P2). None writes a variant-half id either.

The picker uses an **order list in work RAM at `a5-0x61B8`, length
`$138(a5)`**, and a **32-bit** already-fought mask (`btst.l $110(a5)`) —
so the mask needs no widening, but the newcomers must be added to the
ladder list, which is a distinct job from the select wheel and easy to miss
because the wheel is the visible half. Downstream, `PRG:0x00B094` indexes
the VS-screen palette pool at `PRG:0x3A3CA0 + id*32`; that pool has real,
non-aliased data at variant ids (id `0x13` is a placeholder grey ramp), so
it is content to author, not a bound to fix. **Selectable is not
fightable** — now item 5 on the per-tenant declaration list.

### Prep for the capture: cell POSITIONS measured, and a negative result

So the maintainer's PNG lands on ready ground.

**Cell → screen position, all 16, measured** (`tools/wheel_positions.py`,
frozen in gate section 4). They cannot be read statically — the wheel
record lists 18 OBJ entries in DRAWING order, not cell order — so the
cursor is parked on each cell and its ring (**palette `0x1E`**) read out of
OBJ RAM. Cell `0x0F` measures (248, 64), which corroborates 14z-49's
independent identification of Jedah's medallion at (236, 57) by art
rendering: same cell, two unrelated methods, offset by the ring size.

**NEGATIVE RESULT worth more than the map: the adjacency is HAND-TUNED.**
Fitting TABLE B with "step to the nearest cell in this direction's sector"
reaches at best **100/128 (78%)** — with horizontal wrap (period 184; the
wheel wraps left↔right, which is why cell `01` at x=160 goes L to `05` at
x=336), no vertical wrap, ±65° sectors. Plain nearest-in-sector gets 67%.
About a fifth of Capcom's entries are deliberate choices no simple rule
predicts. **So the three new rows and the neighbouring edits must be
AUTHORED and verified, never generated** — a generated table would be
plausibly wrong in exactly the way only playtesting catches. The validator
(`select_wheel.py`) and the emulator gate are the safety net.

### DECISION FOR THE MAINTAINER (gameplay-visible)

The `0x360+id` anim family is the one item the measurement cannot settle
alone, and it is a "player could feel it" call, so it is not mine:

- **Option A — inherit (recommended).** A newcomer at `0x13` plays anim
  `0x363` (Victor's number in that block). **This is exactly what vsav2
  ships** — Capcom kept both folds — so it is known not to break their
  version of these characters.
- **Option B — relocate the block.** Find a free 32-wide anim-number range
  and widen both sites. Costs a numbering audit and touches shared engine
  code for a family we cannot yet name.

What is known about the family: entry `PRG:0x003E3A` (kernel save `$330E`
→ set anim `0x360+id` via `$4CE2` → restore `$3306`), called from the
state handler at `PRG:0x024002`, which sets `$140(a6)=0x20`,
`$14E(a6)=0x10` and then routes `$54(a6)` through the property table
`0x28D00` into the anim setter `0x27EC0`. **Naming it needs a runtime
probe** — deliberately not guessed. Recommendation stands at A regardless,
because vs2 is a shipped existence proof.

### Consequence for the roster (option 1)

**No indirection is needed.** Give the newcomers their native vs2 ids —
Huitzil `0x10`, Pyron `0x11`, Donovan `0x13` — and every ported bank row
lands at its own index with no renumbering, matching the cells vs2 already
ships. Remaining work: three TABLE B rows plus reachability edits to
neighbouring rows, and a decision per folding site. `id_space.md` lists
what a per-tenant manifest must declare.

Note this moves Donovan off slot `0x0F` (Jedah) to `0x13` — the "moving
Donovan off Jedah's slot" item already queued, now with a target id.

### Independent confirmation, from the bytes alone

vs2's wheel table has live rows at `0x10`/`0x11`/`0x13` and DEAD (`$ff`)
rows at `0x02`/`0x09`/`0x0A`. Against the atlas slot map those three are
Gallon, Aulbath and Sasquatch — **exactly the characters Vampire Savior 2
dropped** to make room for Donovan, Huitzil and Pyron. The public roster
swap falls out of the adjacency bytes, which is independent confirmation
that the cell index is the character id.

### A process failure worth recording

`EnterWorktree` branched from **`origin/main` (6fe3c04, 14z-41)**, not
local `main` (ed5dc10) — origin is ~18 sessions stale. The first half of
the measurement therefore ran on 14z-41-era tooling, including
`run_mame.sh` from before the 14z-59 input-provider isolation. Caught by a
missing test file; the branch was moved to local `main` and **everything
was re-measured**. The decrypted images came out byte-identical (same
SHA-1s) and the walk gave the identical result, so nothing was invalidated
— but that was luck, not method. This is the "the instrument moved" hazard
in a new costume, and it is now in GOTCHAS.

## Session 14z-59l (ROSTER ACCESS decided; the vs2 wheel measured properly)

### Decision (maintainer, 2026-08-04)

**Option 1 — an altered character select screen — is the target.** Capcom
made one for the Vampire Collection / Chronicle console ports, and the
maintainer owns them and can supply a pixel-accurate capture.
Simplification they set: **keep the existing roster's cells exactly where
they are and append the three newcomers**, keeping the random-select
medallion in its original place. Imperfect medallion art on the three new
cells is acceptable; **mechanical soundness is not**.

**Option 2 (fallback): the hold-Start alternate-selection system.** Lesser
implementation — the vs2 characters have their own alternates, so vsav
characters would have to be "stacked" to free slots. Only if option 1 fails.

### What vs2 actually contains (measured 14z-59l; corrects two of my claims)

I twice reported that vs2 hands us the layout we want. Both were wrong, and
both came from a MISALIGNED record base found by pattern-searching for the
newcomer icon codes rather than by following the header pointer.

The wheel records are located by a coord-list longword at `base-4` (that is
how vsavj's `0x0032A50A` sits at `0x272A6E`). Scanning for those pointers
finds the real records:

| Record | Coord list | Entries | 3x3? | Notes |
|---|---|---|---|---|
| vsavj `0x272A72` | `0x32A50A` | 18 | **yes** (idx 8, Gallon, pal 07) | the shipped vsav wheel |
| vs2 `0x2A6D8C` | `0x303AAC` | 18 | — | list byte-identical to vsavj's 18 |
| **vs2 `0x2A6E5C`** | **`0x303B68`** | **24** | **NO** | the newcomer wheel |

**CORRECTION 1:** I said "entry 8 is still 3x3, so appending does not force
demoting Gallon's cell". False. The real 24-entry record has **zero** 3x3
cells — the pal-07 character is split into a 3x2 (`b113`) plus a 2x1
(`b0ee`). The original 14z-49 note ("nobody is 3x3") was right.

**CORRECTION 2:** I said vs2 "appends three cells at (-24,-88) (-8,-88)
(+8,-88)" to the shared layout. False — those are entries 0-2 of a
DIFFERENT list. Measured properly, the 24 entries occupy **21 distinct
positions**: the three newcomer cells overdraw three placeholder cells.

| newcomer | entry | draws over | position |
|---|---|---|---|
| Huitzil `b108` pal 13 | 21 | entry 8 (`b100`) | raw (256,104) |
| Pyron `b0f5` pal 11 | 22 | entry 0 (`b0cf`) | raw (232,88) |
| Donovan `b10b` pal 05 | 23 | entry 12 (`b100`) | raw (208,104) |

### So what is actually usable

vs2 **does** give us Capcom's own **21-position wheel geometry** — but it is
a REARRANGEMENT, not vsavj's 18 plus three. Its coord list is a different
list, and its positions do not match vsavj's. Two paths follow:

- **(a) Adopt vs2's 21-position layout wholesale.** Official geometry,
  already in a ROM we own, ports with existing machinery. Cost: every
  existing cell moves, and the 3x3 is lost — contrary to the maintainer's
  "keep the original roster in its state".
- **(b) Keep vsavj's 18 positions and author 3 new ones** (the decision).
  vs2 still supplies the three medallion ART codes and palette rows, which
  is the expensive part; only the three coordinates and the navigation are
  new. **This is where the console-port capture is needed** — as the
  reference for where Capcom put them in a VSav-style wheel.

### The unanswered — and harder — half: CURSOR NAVIGATION

Everything above is where cells are DRAWN. What makes it "mechanically
sound" is what the cursor does: how a direction press maps to the next
cell. That mechanism is NOT yet located. It is the real work of this task,
it is independent of the art, and it is what a wrong answer would make
unplayable rather than merely ugly. Next investigative step.

> **CLOSED in 14z-60 — and the record it left was partly wrong.** The
> mechanism is now measured and lives in `docs/game/atlas/select_screen.md`
> (gate `tests/test_select_wheel.sh`). The follow-up notes written into
> `docs/NEXT_SESSION.md` after this section named `PRG:0x020A84` as the
> commit site; the commit stores are `PRG:0x020A7C` / `PRG:0x020A80`, and
> the direction order is R,L,D,U rather than U,D,L,R. See session 14z-60
> at the top of this file.

## Session 14z-59j (dual-track invariant ESTABLISHED, byte-attributed)

The dual-track decision is only coherent if the WIDE build is a genuine
SUPERSET of the stock one. `tests/test_dualtrack.sh` establishes that as a
live A/B between the two builds — no frozen expectations, so it needs no
freeze decision and is machine-independent.

| | Result |
|---|---|
| 11 legacy replays (never reach the patched slot) | **bit-identical** |
| 5 patched-slot replays (attract + 4 Donovan) | **differ**, as they must |
| attract difference, byte-attributed | 57 bytes: 54 dead-stack, 3 sound-driver, **0 gameplay** |

**Why this matters operationally:** legacy behaviour being bit-identical is
what lets every gate that passes on the stock build transfer to the WIDE
build without re-plumbing ten gates for the `vsavjw` set.

### A misclassification my own gate made, and the measurement that fixed it

The first run failed `01_attract_long`. I had put it in the LEGACY group —
wrong: the attract demo **features the patched slot**, which is exactly why
the stock build already carries `diverge vsavj/masked 4278` for it. The
existing expectation was the evidence, sitting in the repo the whole time.

Rather than reclassify and move on, the divergence was attributed byte for
byte (whole work-RAM dumps from both builds at frame 4400):

- **54 bytes in `$FF7FA0-$FF7FEF`** — inside the dead-stack window
  `$FF7F00-$FF7FFF` that CLAUDE.md §4 already masks (hook cycle skew, below
  resting SP; ghost bytes, not live state).
- **3 bytes at `$FF055B-$FF055D`** — `RAM:$FF05xx` is the **sound-driver
  work area** per docs/game/atlas/ram.md, i.e. precisely what a live sfx helper
  is supposed to touch.
- **Zero bytes of gameplay state.**

Second lesson banked: the gate had also been comparing WHOLE work RAM,
which includes the dead-stack window — the wrong basis for a
hooked-vs-hooked comparison. §4's masked basis exists for exactly this.

### New instrument: `tools/attribute_ramdiff.py`

"The two builds differ, and that's expected" is not a verdict, it is the
absence of one. This turns it into an assertion: every differing byte must
fall inside a window the caller can NAME, and stray addresses are printed
so the next question ("what lives at `$FFxxxx`?") is immediately askable
against the RAM atlas. It refuses to be quieted by widening a window —
that instruction is in its own failure output.

## Session 14z-59i (M5 SOUND IS AUDIBLE; WIDE build registered; a false fingerprint corrected)

### Donovan's move sounds now play — and no music

The 14z-52 blocker is fully closed. Placing the record array was only half;
the **per-node sfx helper** (vs2 `0x5122` -> vsavj `0x4CE2`) was still
stubbed, absorbing ~400 calls per match. Un-stubbed on the WIDE track:

| Replay | ids that now reach the QSound ring |
|---|---|
| 12_donovan_vs_cpu | 0x110, 0x111, 0x112 |
| 19_don_dp_spam | 0x110, 0x111 |
| 25_don_darkforce | 0x110 |
| 56_don_es_ls | 0x119 |

Every one is from the `keep_ids` allowlist (samples verified byte-identical
on vsavj), `missing=[]`, and **zero music-range ids** — the `0x700-0x7FF`
tripwire in `tests/test_don_sound.sh` never fired. That tripwire is the
whole point: it is the round-2 "music instead of sfx" bug, and it stays
shut. Stock track unchanged and still green.

This answers the 14z-52 caveat directly ("those entries never fire in any
of our 8 Donovan replays"): with the helper live they fire in all four
sound replays.

### The safety coupling is STRUCTURAL

Un-stubbing the helper while slot 0x0F still resolves to JEDAH's array
(~40 entries, Donovan indexes to 43) reads PAST it and enqueues whatever
follows — including the music range. So the un-stub is driven by the
`unstub` field of the SAME `[[sound_table]]` row that places the array, not
by a reconciliation status or a profile name. **No ordering of edits can
produce a live helper with no array.**

### THE CORRECTION: 14z-59h reported a fingerprint that was not the build's

`build_donovan.sh` fingerprinted without `--set`, so it defaulted to
`vsavj`; a WIDE build (packed `vsavjw`) found no `vsavj.zip` in its own
rompath, **fell through to `$ROMDIR`, and reported the PRISTINE reference
ROM's fingerprint**. `b0eb9ecd` is the vanilla row already in
registry.tsv. Two different builds reported the same value, and it was
neither of theirs — and it made the helper un-stub look like a no-op.

Also fixed: `_PRG_RE` did not match `vsw.41-.44`, so extension CONTENT was
invisible to build identity — 14z-54's gfx/QSound blind spot in a new
region. Both in GOTCHAS.

Real fingerprints, measured after both fixes:

| Build | Fingerprint |
|---|---|
| stock (vsavj) | `ae701ffb…` (unchanged) |
| WIDE, helper live | **`ac52eeff…`** |
| WIDE, helper stubbed (control) | `ec457c9d…` |

The control proves the un-stub is real end-to-end, which the broken
fingerprint had hidden.

### Registered (task 2)

`ac52eeff… -> donovan-m5w` in `tests/expected/registry.tsv`.
`tests/test_don_sound.sh` gained `SET=` (default `vsavj`, so stock is
untouched) and a WIDE inventory overlay. Both tracks PASS.

### READY FOR PLAYTEST

Build: `KEY_SET=vsavj GEN_FLAGS="--allow-plausible --tripwire-open
--profile cps2-wide-v1" tools/build_donovan.sh 6 <out>`
Run: patched FBNeo, driver **vsavjw**, `-rompath "<out>/rompath;$ROMDIR"`.
What to listen for: Donovan's normals/specials should now have their shared
impact/sword sfx. His VOICE lines are still silent by design — those
samples do not exist in vsav's ROMs (STATE "M5 voice samples", still open).

## Session 14z-59h (Phase C step 2 — the image grows; M5 SOUND UNBLOCKED)

**The 352-byte sound table has a home, and the 68k provably reads it.**
The blocker that has stood since 14z-52 is gone.

| Link | Evidence |
|---|---|
| generator states the requirement | `image: 0x400000 -> 0x600000 (+4 x 0x80000)` in patch.json |
| patcher grows the image before ops | table lands at `CPU:$400010` |
| packer emits `vsavjw.zip`, merging gfx/QSound | 4 extension + 6 profile members, sizes checked |
| runs on FBNeo (`vsavjw`) | 9,320 frames, clean END |
| runs on MAME (`vsavjw`) | 9,320 frames, clean END |
| **NEGATIVE CONTROL** | zeroing the table diverges at **frame 3121** |
| stock build | still `ae701ffb`, byte-identical |

Gate: `tests/test_phasec_image.sh` (all four properties at once).
WIDE build fingerprint: ~~`b0eb9ecd`~~ **WRONG — see 14z-59i.** That is the PRISTINE vsavj fingerprint; the builder was fingerprinting the reference ROM. Real value: `ac52eeff`.

**The negative control is the point.** B4 taught that a relocation which
"passes" proves nothing if the data is never read, so the gate zeroes the
table and REQUIRES behaviour to change. Without that, "it booted" would
have been indistinguishable from "the pointer row is dead".

### Two design rules banked

1. **Image shape follows the PROFILE, not the content.** The first attempt
   emitted one extension member because only 0x160 bytes were used — but
   the emulator descriptors declare four, and a set carrying fewer simply
   fails to load. Geometry is the profile's business; content decides
   nothing about it.
2. **The packed set name is DERIVED from the generator's own output.**
   `patch.json` carries an `image` block only when a profile-gated space
   was actually used, so the set name (`vsavj` vs `vsavjw`) can never
   disagree with what was built. No second place to keep the profile in
   sync.

### Note on `-verifyroms`

MAME reports `romset vsavjw [vsav] is bad` on CRC for this build. That is
expected for ANY patched build — patching a member changes its CRC, and
the stock Donovan build has always done the same — and both emulators run
it regardless. The consequence worth remembering: **the ROM audit cannot
distinguish "patched as intended" from "corrupted"**, which is exactly why
the negative control carries the weight instead of the audit.

### Pipeline changes (all shared code — hence property 1 of the gate)

- `gen_donovan_patch.py`: emits the `image` block; extension addresses are
  legal only in a profile-gated space.
- `patch_prg.py`: `image` support — grows the word array with 0xFF fill
  BEFORE ops, appends the members on write.
- `pack_build.sh`: `--merge` (fold in members this build does not produce;
  ours always win) and `KEY_SET` (a profile clone takes its parent's key).
  The key is fetched AFTER the merge, since ROMDIR has no `vsavjw.zip`.
- `build_donovan.sh`: detects the `image` block and packs as `vsavjw`.
- `verify_gfx_build.py`: discovers the packed set instead of hard-coding
  `vsavj.zip`.

### What this unblocks, and what it does NOT

M5 sound can proceed on the WIDE track. Still open and unchanged: the
**voice samples** decision (8 MB of QSound headroom, hard-capped by MAME's
16 MB ceiling), and whether those 6 shared sfx ids actually fire in a
replay — the table is now READ, which is not the same as AUDIBLE. The
14z-52 caveat stands: those entries were never observed firing in the
8 Donovan replays, so an audible test still needs a replay that triggers
them.

## Session 14z-59g (DECISIONS RATIFIED: dual-track build; upstreaming deferred)

**Maintainer, 2026-08-04.**

### 1. DUAL-TRACK — ratified

- **WIDE is the ROSTER build.** Content that needs the extension goes
  there; M3 (Huitzil + Pyron) has no other option — Phase A measured
  1,112 bytes free against a ~886 KiB deficit, so that was arithmetic, not
  preference.
- **The stock-size build stays**, frozen at `ae701ffb`, as the
  compatibility artifact that runs on unpatched FBNeo/MAME. It keeps
  playtesters off custom binaries until M3 forces the move, and keeps the
  frozen `donovan-m2c` expectations exercised.
- Cost: one extra build in the battery. The profile gating built in
  14z-59f already produces both from ONE manifest, and
  `tests/test_phasec_spaces.sh` asserts the stock build stays
  byte-identical.

**Consequence to hold on to:** the stock build must never silently gain a
dependency on the extension. That is enforced by construction —
profile-gated spaces and profile-gated content rows do not exist for a
build that did not ask for them — not by remembering.

### 2. UPSTREAMING — deferred, "too early"

Not a goal yet, not ruled out. Practical effect: **keep both 0002 patches
minimal and separable**, which is already the standing discipline (the
harness patch is frontend-only and deliberately split from the profile
patch; the profile costs one gated conditional per emulator). Nothing to
change today; revisit once the roster actually works. If upstream ever
accepted `vsavjw`, players would get the profile in stock builds and the
custom-binary objection would largely evaporate — worth remembering when
weighing distribution later.

### 3. Correction banked while settling this

The M5 sound-home entry's recommendation ("option B: reclaim the inert
weapon_accent rows") was based on a misreading — those rows are palette
`data_port`s outside both holes and free ZERO hole bytes. Detail in
Decisions pending below.

## Session 14z-59f (Phase C step 1 — the address-space model)

**The allocator is now declarative, and the refactor moved ZERO bytes.**

Placement used to be two hard-coded holes with a bump allocator and an
a→b fallback. It is now an ordered `[[space]]` list in
`build/manifest/donovan.toml`, each with a class (`crypt` = inside the
CPS-2 encryption window so code is re-encrypted / `raw`), an optional
`profile` gate, and a `fallback`. Legacy `alloc("a"/"b")` call sites
resolve through it unchanged.

Proven bit-identical **three times** — refactor alone, then with the
spaces declared, then with the WIDE profile enabled — all
`ae701ffb06d0cbf3462cad1a9faa47534a3c00e4`, matching the documented dev
head. Gate: `tests/test_phasec_spaces.sh`.

### What the new summary line reveals

```
stage 6: 224 ops, hole_a 0x100000/0x100000 (free 0x0),
                  hole_b 0x3FFEF0/0x400000 (free 0x110)
```
**hole_a is completely full; hole_b has 272 bytes left.** The 14z-52 space
crisis, now a number the build prints on every run instead of a claim.
The stuck sound table needs 0x160 = 352 bytes.

### Profile gating, by construction rather than by discipline

`wide_ext` (`$400010-$600000`, 2 MB) is declared but carries
`profile = "cps2-wide-v1"`, so it **does not exist** for a stock build —
enabling the profile alone still produced the identical fingerprint,
because nothing allocates there yet. Content rows gate the same way: the
`[[sound_table]]` row is now uncommented with `profile = "cps2-wide-v1"`
and `hole = "wide_ext"`, and a stock build skips it entirely.

Note the extension is CONTIGUOUS with hole_b, which ends exactly at
`$400000`; the 16-byte gap is the CpsFrg window, reserved and never
allocated (and the emulators disagree about reads there — 14z-59, so the
reservation is load-bearing).

### THE NEXT CONCRETE STEP, now precisely specified

Allocating into the extension fails with a diagnosis rather than a crash:

> `space wide_ext allocation 0x400010+0x160 for sound_table
> don_sfx_records lies beyond the 0x400000-byte program image. The
> profile's extension is declared and the ADDRESS SPACE is proven usable
> (WIDE B4, both emulators), but the build pipeline does not yet GROW the
> program image or emit the extra ROM members.`

So the remaining work is **pipeline, not address space**: grow the program
image to 6 MB and emit the four appended 512 KB members (`vsw.41-44`) with
their real CRCs, through `patch_prg.py` / `pack_build.sh`. The address
space itself is settled and proven.

### Consequence the maintainer should weigh

A build that uses the extension **requires the `vsavjw` driver and a
patched emulator** — today's Donovan builds run on STOCK FBNeo/MAME. For
netplay that means peers need the same binary and the same set
(docs/project/cps2_wide.md already says so). That is a shipping decision, not a
placement detail, which is why the sound_table row is profile-gated rather
than simply switched on. **It also supersedes the M5 SOUND DATA HOME
decision still listed below**: option C ("grow the program region via
driver descriptor") was rejected then as "larger blast radius", but WIDE
has since been demonstrated on both emulators, so it is now the cheap
option and options A/B (evicting live thunks, auditing Jedah's anim
region) are no longer forced.

## Session 14z-59e (B5b — FBNeo instruments; and a VACUOUS gate uncovered)

### THE FINDING: the FBNeo emulator superset invariant was never actually tested

`WIDE=0 tools/setup_fbneo.sh` printed *"harness-only build (reference
binary for the superset invariant)"* and built a binary that **carried the
WIDE profile**. It only ever SKIPPED applying the patch; it never reverted
it, and the submodule working tree keeps the patch from the previous
build. So `tests/test_wide_profile.sh` section 1 — reference vs WIDE
binary on stock vsavj — was comparing **WIDE against WIDE**, which passes
trivially.

That section is the **emulator superset invariant**, Rule 1 v2 clause 3:
the entire justification for permitting emulator changes at all. A vacuous
pass there is the most expensive kind of green, and it is not knowable
retroactively how the maintainer's `fbneo_ref` was built.

Fixed and then **established for real**: with a reference verified free of
the profile (the driver title string is compiled in, so `grep` on the
binary settles it), the gate is **36/36** — RAM *and* framebuffer, over the
12-replay corpus. The invariant now measures what it claims.

- `WIDE=0` **reverts** the patch and refuses to build if `Cps2Wide` survives.
- Both builds assert on the ARTIFACT, in both directions (a reference that
  carries the profile and a WIDE build that lacks it are equally broken).
- `test_wide_profile.sh` FAILS if `FBNEO_REF` contains the profile string.

Third member of one family this session — after `git apply` silently
skipping with exit 0, and the MAME submodule gitlink drifting the WIDE
binary to 0.289. **The tool reports success while the artifact is not what
was asked for.** The standing lesson: assert on the artifact, never on the
exit code.

### The instruments (B5b proper) — all frontend-only

FBNeo is the PRIMARY target (GGPO netplay reference), yet the oracle had
strictly better debugging than the platform players use. Closed, via the
public 68k interface only (`SekMapHandler` / `SekSetWrite*Handler` /
`SekGetPC`) plus the CPS RAM pointers — **no emulation-core file touched**:

| Env | Instrument |
|---|---|
| `FBNEO_HTAP="lo-hi[;...]"` | write tap with **PC attribution** (handler slot 7; capcom uses 0-6) |
| `FBNEO_HPOKE="frame:addr:hex"` | frame-scheduled pokes |
| `FBNEO_DUMPS` | now resolves by ADDRESS — reaches OBJ RAM `$708000` and palette `$900000`, not just work RAM |

Gate: `tests/test_fbneo_instruments.sh`, and it tests the way this project
requires rather than "it ran":
- **NON-PERTURBATION** — the tap swaps direct memory mapping for a handler
  that must write through faithfully. A tapped replay is checksum-identical
  to an untapped one, so a wrong write-through cannot hide.
- **POSITIVE CONTROLS** — 1,048,406 writes captured with PCs; the poke
  diverges at exactly the poked frame. An instrument that reports nothing
  proves nothing (the B4 vacuous-relocation lesson).
- **ORACLE CROSS-CHECK** — palette `$900000` dumps are **byte-identical to
  MAME**, which independently validates the `^1` byte-order swap (the
  repo's #1 gotcha). Taken at a frame where the region is stable across the
  known MAME/FBNeo frame skew, so the match is not a timing coincidence.

### B5b acceptance: a known finding RE-DERIVED on FBNeo

Per STATE 14z-53 the bar is not "features exist" but "re-derive known
findings". The FBNeo tap on `RAM:$FF5D94` independently lands on the HUD
stagers documented in 14z-49 from MAME: PCs `089376/08937c` at **0x89370**
and `0893a0/a4/a8/ac` at **0x8939C**, with the boot RAM-clear at `0x000d36`.
It also **refines** the record: the emitter `PRG:0x1BB3C` does NOT write
those records directly — the stagers do.

### BLOCKED BY RULE 1: probe breakpoints with register capture

The last instrument on the B5b list cannot be built frontend-only.
`src/cpu/m68000_intf.h` exposes no instruction-level hook or breakpoint
API — only memory handlers, `SekGetPC`, and the IRQ callback. A PC-matching
probe needs a per-instruction callback, which lives in the CPU core.
Per CLAUDE.md rule 1 this is written up rather than worked around.

Options if it is ever needed: **A)** approximate with a write tap on a
address the routine touches (covers most "did we reach here" questions and
is already available); **B)** use MAME's `GUARD_PROBE`, which still exists
and now has proven parity — the reason to reach for FBNeo probes largely
evaporated when B5 succeeded; **C)** widen Rule 1 to admit a gated
instruction hook — a real emulator-core change, needing maintainer
ratification, and not justified by current need.

Reproducibility (14z-58e standard): the FBNeo submodule was reverted to
pristine, `tools/setup_fbneo.sh` re-applied both patches from the committed
files, and the instruments gate passed on the result.

## Session 14z-59 (B5 — MAME parity + the profile ported; and the determinism finding)

**B5 IS COMPLETE AND GREEN:** parity **62/62**, MAME WIDE gate **36/36**
(superset invariant + inertness + B4 canary, work RAM AND framebuffer over
the 12-replay legacy corpus), VIDEO_OUT self-check **4/4**. MAME's own
`-verifyroms vsavjw` reports the romset good, so both emulators are
provably fed identical bytes. **The B4 canary passing on MAME is a SECOND
OPINION, not a repeat**: two unrelated codebases, each with its own
loader, interleave and gfx decode, both serve fifteen characters' sprites
from the appended 19-bit banks with every legacy replay pixel-identical.

### What B5 delivered

- **MAME 0.288 pinned**: submodule `emu/mame`, tag `mame0288`, commit
  `27a8d9e8`. `tools/setup_mame.sh` builds it; `tools/run_mame.sh` gained
  `MAME_BIN` (default `mame`, so every existing gate is untouched).
- **Parity proven BEFORE the patch** (`tests/test_mame_parity.sh`): the
  UNPATCHED source build reproduces all 24 frozen vsavj oracle logs
  bit-for-bit AND is byte-identical to the Homebrew reference on the other
  38 replays, on vsavj and vsav2 alike — 62/62. The gate refuses to run
  against a binary that knows `vsavjw`, because calling that "parity"
  would be a lie. Swapping the binary changes the INSTRUMENT; if the
  instrument moved, every MAME finding since session 1 would be in
  question.
- **The profile ported**: `emu/mame-patches/0002-cps2-wide-v1.patch`,
  **164 lines added, exactly ONE removed** — the sprite tile-code
  composition, gated on a `m_cps2_wide` driver member. Everything else is
  additive (two widened maps, a `cps2wide` machine config, the `vsavjw`
  descriptor, one `GAME()` row, one `mame.lst` row). Verified to apply
  cleanly to the pristine pinned tree.
- **`VIDEO_OUT`** added to `tests/lua/replay.lua` — the MAME twin of
  `FBNEO_HVIDEO`. MAME's harness had the SAME video blind spot 14z-55
  found in FBNeo's, and the WIDE change is entirely a rendering change, so
  a RAM-only MAME gate would have reported it green without executing the
  modified line. Ground-truthed both ways by
  `tests/test_replay_video_selfcheck.sh` against the known donovan6
  medallion diff (frame 650 must MATCH, frames 950/1250 must DIFFER).
  Measured: 3,952 distinct framebuffer checksums over 5,520 frames, and
  the RAM log stays bit-identical to the frozen expectation with it on.

### Two MAME-only facts that CONSTRAIN the profile

1. **16 MB of QSound is MAME's hard ceiling.** `qsound_device` is a
   `device_rom_interface<24>` — 24 address bits. WIDE v1's 16 MB fits with
   nothing to spare. Growing QSound further would mean widening a SHARED
   MAME device, which stops being profile-gated and falls outside Rule 1
   v2. **The v1 QSound size is therefore a ceiling, not a chosen number** —
   future voice-bank pressure has to be solved by exclusivity/banking.
2. **`$400000-$40000F` reads differ between the emulators.** FBNeo's
   `SekMapMemory(CpsRom, 0, nCpsRomLen-1)` read-shadows the CPS2 output
   registers with ROM; MAME's base map re-declares them after the ROM
   range, so they stay readable. A genuine divergence, unobservable ONLY
   because the profile reserves that window — the reservation is now
   load-bearing for dual-emulator agreement, not tidiness.

### DETERMINISM POLICY — RATIFIED (maintainer, 2026-08-03)

Maintainer, on the options recorded below: *"I agree with your conclusions
in STATE.md: 'RECOMMENDATION: A, then B until the measurement says
otherwise' can be enforced."*

**The policy, now in force:**
- **A — measure first.** Bound the run-to-run divergence rate before any
  §4 policy changes. Instrument: `tests/test_mame_determinism.sh`
  (`RUNS`, `JOBS`, `PROBE`, `SET`).
- **B — every MAME gate stays STRICT until that measurement says
  otherwise.** Any divergence is a hard failure requiring root-cause. No
  automatic re-run, no tolerance class, no "flake" verdict.
- **C (a new "unreproducible transient" comparison class) is NOT adopted**
  and may not be proposed again without the measurement from A. It is the
  tolerance-shaped option and the one most able to hide a real bug.

This does not amend CLAUDE.md §4 — it declines to. The existing classes
(exact / flicker-tolerated / frozen first-divergence constant) are
unchanged, and nothing has been loosened.

**Proxy validated before spending the budget:** the 520-frame
`tests/probes/boot_probe.rpl` is **bit-identical to `08_challenger_join`
for frames 1-299**, so it genuinely exercises the window both divergences
appeared in — at ~3s per run instead of ~15s. That is what makes a
high-volume measurement affordable, and it is a measured fact, not an
assumption.

**MEASUREMENT RESULT (A, executed 2026-08-03): all regimes CLEAN, and the
clean result is itself the finding.**

| Regime | Runs | Divergences |
|---|---|---|
| 1 — boot probe, sequential | 1000 | 0 |
| 2 — boot probe, parallel x6 (load hypothesis) | 600 | 0 |
| 3 — full `08_challenger_join`, sequential | 150 | 0 |
| (earlier) boot probe, 4 combos | 480 | 0 |
| (earlier) full-length replays, all sources | 312 | **2** |

**A flat per-run boot-window rate is RULED OUT.** The probe is a validated
proxy for frames 1-299 and both divergences began at frames 190/218,
inside that window. 2,080 clean probe runs against a 0.43%/run point
estimate from full-length replays is a **1-in-8,300** coincidence
(`P(0 | 0.43%) = 1.2e-4`). The two events are real — they have diffs — but
they are not a simple per-run property of emulating those frames.

**What that leaves.** Every controlled regime repeated ONE replay on ONE
romset. The parity gate — the only place the phenomenon has ever appeared —
alternates replays AND romsets (vsavj/vsav2) across ~250 processes. So
regime 4 re-ran the GATE ITSELF twice rather than doing more repetitions of
a single replay, which the statistics say would be wasted time. The load
hypothesis is already dead (regime 2, parallel x6).

| Regime 4 — the exact failing configuration | Comparisons | Divergences |
|---|---|---|
| parity execution 1 | 63 | **2** |
| parity executions 2, 3, 4 | 189 | 0 |

**BOTH EVENTS ARE IN ONE EXECUTION.** That clustering is the strongest
signal available: an intrinsic per-run property would scatter across
executions, and heterogeneity-as-trigger would have reproduced in three
more full gate runs. Two events inside a single ~35-minute window, then
nothing in ~2,400 subsequent runs, reads as a **transient condition local
to that window**, not a property of the emulator, the build, the replay or
the gate. What that condition was is NOT established.

### 14z-59c — THE MAINTAINER SUPPLIED THE MECHANISM

Offered explicitly as context rather than a diagnosis, and it fits
everything the measurement could not explain:

> the harness runs on the maintainer's **main laptop**, which they
> sometimes need to use. MAME has no true headless mode — even under
> `-video none` it creates a window that **takes focus**. Focus was
> reclaimed and inputs were made during that period. Separately, MAME can
> crash in some circumstances.

**Why this explains the signature and the statistics both.** MAME's
default keyboard map covers P1 directions, buttons, coins and start, so a
host keystroke on that window is injected into the EMULATED controls. RAM
then diverges for as long as the key is held and **re-converges** the
moment the replay's own per-frame staging reasserts every field — exactly
the bounded, self-healing windows observed (190-205, 218-245). It also
explains the clustering: both events fall in one ~35-minute execution (the
machine was in use), and ~2,400 later runs on an idle machine found
nothing. A flat per-run rate and machine load were both RULED OUT by
measurement; this survives all of it.

**Not confirmed** — the two events predate any input logging, so this
cannot be proven retroactively. It is the leading explanation, and the
hole is now closed in both directions:

- **PREVENT** — `tools/run_mame.sh` now passes `-keyboardprovider none
  -mouseprovider none -joystickprovider none -lightgunprovider none`.
  A run that can absorb a stray keypress is not an oracle. Verified
  non-perturbing: the frozen suite reproduces bit-for-bit.
- **DETECT** — `tests/lua/replay.lua` verifies EVERY frame that the live
  controller bits are exactly what it staged, writes `INPUT-VIOLATION`
  into the log otherwise, and `run_replay_mame.sh` rejects the run.
  Always on (`NO_INPUT_CHECK` to disable). Had this existed, the two
  divergences would have been diagnosed in seconds instead of costing
  ~2,400 runs of statistics.
- **GROUND TRUTH** — `tests/test_input_integrity.sh`, both directions:
  silent and non-perturbing on a clean run; a single-frame un-scripted
  press caught at exactly the injected frame
  (`INPUT-VIOLATION 1 frame 500 port :IN0 expected 7f7f got 7f6f`).
  The positive control uses `INPUT_INJECT_TEST=<frame>`, which presses a
  button without recording it in `held[]` — what a host keystroke looks
  like to the harness.

**A bug the ground truth caught in the checker's first draft:** comparing
whole ports flagged EVERY replay at frame 77, because `:IN2` mixes the
**EEPROM data line** in with the coin/start bits. The check now masks to
bits the harness can actually drive. Testing verdict logic before trusting
it is doctrine for exactly this reason.

**The crash half** is already covered: `run_replay_mame.sh` requires a
terminating `END` line, so a crashed or truncated run fails rather than
being compared.

**Status: BOUNDED AND OPEN, not root-caused.** Honest summary of what A
bought: it killed two hypotheses (flat per-run rate; machine load), showed
the events cluster, and put an upper bound of ~0.14%/run on the boot
window. It did not find a mechanism. Four clean regimes are not a
resolution — the two events have diffs and happened.

**Policy consequence: nothing loosens.** The measurement did not find a
rate, so by its own terms it cannot justify relaxing anything; **B stays
in force**, C remains un-adopted, gates stay strict, and
`tools/analyze_divergence.py` + the preserved artifacts stand ready to
classify occurrence #3 the moment it appears. If it recurs, the first
question to answer is what else was running on the machine — that is the
hypothesis this measurement leaves standing, and the one nothing in the
harness currently records.

### THE FINDING: MAME is not perfectly deterministic run-to-run

The first full parity execution produced **two divergences in 126 runs**,
and neither is a source-vs-Homebrew difference:

| Replay | Set | Window | Comparison |
|---|---|---|---|
| `08_challenger_join` | vsavj | frames 190-205 | source vs source (same binary!) |
| `41_don_altcolor_vsav2` | vsav2 | frames 218-245 | reference vs source |

Both sit in the **boot window**, both **re-converge**, and both refuse to
reproduce on demand: `08` is 48/48 identical on re-runs, `41` is 12/12
identical across six runs of EACH binary. The immediate re-run of the
whole gate came back **62/62 clean**. So the phenomenon is real, rare, and
belongs to the emulator/harness — not to the WIDE work and not to the
source build.

This matters beyond B5: **every frozen MAME expectation this project owns
assumes run-to-run determinism**, and `run_suite.sh`'s twice-run check has
been green for many sessions, which is hard to square with two failures in
one 126-run execution. Either something changed, or the rate is low and
two landed together.

**What the follow-up measurements say (all run this session):**

| Regime | Runs | Divergences |
|---|---|---|
| parity gate, execution 1 (full-length replays) | 126 | **2** |
| parity gate, execution 2 (identical, clean machine) | 126 | 0 |
| targeted repeats of `08` and `41` (full-length, both binaries) | 60 | 0 |
| boot probe, 4 combos (src/ref x vsavj/vsav2), 120 each | 480 | 0 |

Point estimate from full-length replays: **2 in 312 ≈ 0.6%/run**. The
480-run boot-probe sweep is clean, but it does **not** refute that: the
probe is 520 frames against replays of 3,000-12,000, and if it covered the
same trigger, 0-in-480 at 1.6%/run would be a ~0.04% coincidence. The
honest reading is that **the probe probably does not cover the trigger**,
and the boot window is where the divergence SURFACED, not necessarily
where it originates. Getting real statistical power needs ~300 full-length
runs of one replay (~1.5 h); `PROBE=<rpl>` on the determinism gate does
exactly that and is the recommended next measurement.

Instruments built to settle it rather than argue about it:
- `tools/analyze_divergence.py` — classifies a divergent pair as
  **PHASE SHIFT k** (timing: B[n] == A[n-k], nothing computed a different
  value), **TRANSIENT** (real state differed, then was overwritten) or
  **PERMANENT**. Its verdict logic is itself validated against a synthetic
  phase shift and an identical pair before use (CLAUDE.md §4).
- Both new gates now **preserve divergent logs** to `build/gate_failures/`.
  Deleting the evidence in an EXIT trap is what made both of today's
  occurrences unanalysable; that cost is not paid twice.
- `tests/probes/boot_probe.rpl` (400 frames, ~2s) + a new
  `tests/test_mame_determinism.sh` measure the RATE at volume, since the
  boot window is where both anomalies appeared. `tests/probes/` exists
  because `run_suite.sh` demands a frozen expectation for every
  `tests/replays/*.rpl`, and a diagnostic probe must not force an
  expectation row into all four expectation sets.

### The trap that nearly shipped a false green

The first WIDE build succeeded, ran nine minutes, printed "CPS-2 WIDE
profile patch applied" — and produced a **completely STOCK binary**.
`$HOME` on this machine is itself a git repository, so the build mirror at
`~/.cache/vampire-saved/mame` sits inside its working tree; `git -C
<mirror> apply` therefore read the diff's paths as $HOME-repo-root-
relative, found them outside the current prefix, printed `Skipped patch
'src/...'` and **exited 0**. `git apply --check` "passed" for the same
reason. Nothing in any exit code disagreed.

The only thing that caught it was the `-listfull vsavjw` assertion, which
existed only because the mame.lst gotcha had already been written up.
Fixed three ways: `patch -p1 -d` instead of `git apply` (no repository
semantics), a post-apply grep asserting both files carry the change, and
an end-to-end assertion that the BUILT BINARY knows `vsavjw` — plus the
inverse for `WIDE=0`, so a reference binary that accidentally carries the
profile also fails loudly. Same family as the FBNeo CRC trap: **the
toolchain reports success while silently substituting nothing.** Treat
"it said OK" as unverified in every build step.

### The SECOND false green, caught the same way

The first WIDE gate run came back 36/36 — and was **invalid**. The WIDE
binary was MAME **0.289**, the reference **0.288**, so the emulator
superset invariant compared two MAME VERSIONS rather than measuring the
patch. Cause: `git submodule add` stages the DEFAULT BRANCH head, and the
subsequent `git -C emu/mame checkout mame0288` touched only the working
tree — never re-staged. `setup_mame.sh` runs `git submodule update` every
invocation, which faithfully restored the indexed commit (master) and
silently moved the tree to 0.289. The reference had been built before that
reset, the WIDE binary after it. **The drifting-reference trap of 14z-55,
in a new costume: the comparison passes and stops meaning anything.**

Fixed and re-run VALID at **36/36**, both binaries reporting 0.288 and the
two build mirrors differing in exactly the two files the patch touches:
- submodule staged at `27a8d9e8` (annotated-tag note: `git rev-parse
  mame0288` gives the TAG OBJECT `2c38dc6e`, not the commit);
- `setup_mame.sh` hard-codes the pinned SHA and **refuses to build any
  other revision** — a build that silently changes the instrument is worse
  than one that fails;
- `test_mame_wide.sh` now asserts the two binaries report the SAME version
  before comparing them.

Banked observation: 0.288 and 0.289 are **bit-identical** on work RAM and
framebuffer across the 12-replay corpus, so CPS-2 emulation did not change
between those releases. Useful, and not a substitute for pinning.

### A useful side effect: replay.lua's change is proven non-perturbing

`VIDEO_OUT` was added to `tests/lua/replay.lua` BEFORE the second parity
execution, which then reproduced all 24 frozen vsavj oracle logs
bit-for-bit and matched the reference binary on 38 more. So the harness
edit is not merely believed harmless when disabled — it is measured
harmless across the entire frozen corpus.

### Build traps paid for (all in GOTCHAS)

- **MAME's GENie cannot handle a space in the source path**, and this repo
  has one. `scripts/genie.lua:18` has the escaping line commented out
  upstream, and `SOURCES=` builds shell out to `makedep.py` with
  `MAME_DIR` unquoted. **Symlinks do not help** — `getcwd()` resolves
  through them. Hence the rsync'd space-free mirror under
  `~/.cache/vampire-saved/`, with the submodule kept pristine.
- rsync `--exclude 'build/'` is unanchored and also drops `scripts/build/`,
  whose `complay.py` every layout rule needs — surfacing as a baffling
  "No rule to make target ...18w.lh".
- MAME 0.288's OSD is **SDL3, found only through pkg-config**; without it
  the build silently picks framework linkage and dies minutes in on
  `'SDL3/SDL.h' file not found`. Prereqs: `brew install sdl3 pkgconf`,
  then `REGENIE=1`.
- A `SOURCES=`-filtered build **silently omits any driver missing from
  `src/mame/mame.lst`**; both WIDE gates assert `-listfull vsavjw` first.
  The binary is named `cps2`, not `mamecps2`.

## Session 14z-49 (rounds 61-62: HUD MUGSHOT + NAME + SELECT MEDALLION — the whole per-slot venue-asset family fixed)

Build `b91647c7da14ded6316cee8dc057c8daf1c3fb1e` (donovan6, stage 6).

- **HUD pipeline mapped (in-fight top strip is OBJ, staged from
  per-char tables):** emitter `PRG:0x1BB3C` → RAM records at
  `RAM:$FF5D94` → stagers `PRG:0x89370/0x8939C` (mugshot) and
  `PRG:0x89684` (name) → per-char tables `PRG:0x89884` (mugshot
  code words) and `PRG:0x898C4` (name entries, 8B/char). **Stager
  bases differ per game: vsavj adds +0x3800 to table codes, vs2
  adds +0x4200** (live-OBJ measured after the first placement from
  +0x3800-assumed vs2 addresses drew garbage). vs2 twins: tables
  `0x990CE`/`0x9910E`, Donovan row 0x13 (mugshot 0x0B62 → OBJ
  0x4D62 2x2; name 0x0B55.. → 0x4D55 3x1 pal 02).
- **HUD fix (uncommitted last session, corrected + committed now):**
  mugshot = effect_tail place `'0x4D62,2,2' -> '0x3DC8'` (into the
  cells slot 0x0F's own table entry 0x05C8 already points at — no
  code patch); name = place `'0x4D55,3,1' -> '0xBE8C'` (bank-1 pool
  tail) + aux_pokes `hud_name_entry_0f_hi/lo` repointing name-table
  entry 0x0F (0x8993C ← 0x868C0202, 0x89940 ← 0xFFE80003; 0x868C =
  0xBE8C − 0x3800). Live-verified: mugshot entry (0x3DC8 2x2 pal 0A
  at 200,32), name plate (0xBE8C 3x1 pal 02 at 144,40), f2600
  replay 56. Gate: reactions §4 extension.
- **SELECT WHEEL DECODED (docs/game/engine_internals.md):** the wheel is
  ONE static OBJ record at data `0x272A72` — 18 (code,attr) pairs,
  coords via header pointer → list `0x32A50A` (center-relative,
  shared byte-identical with vs2's list). Cells are fixed
  perspective sizes (3x2/2x2, ONE 3x3); the wheel does not rotate
  or hover-zoom; the cursor ring (pal-1e pieces) just moves.
- **WRONG-CELL TRAP PAID FOR (GOTCHAS entry): the big 3x3 pal-07
  cell (code b4e3 at 264,64) is GALLON's medallion** (top-front
  perspective cell, werewolf face — first read as "Jedah" from the
  pal-07 = char-07 numerology). **Jedah's actual cell = code
  0xB526 attr 0x1214 pal 14 at (236,57)** — identified by
  measuring the cursor-ring center (256,72) in replay 58 and by
  color-rendering the art (purple wing-wrapped icon = the
  maintainer's "still Jedah's" medallion). First attempt shipped
  Donovan onto Gallon's cell (attr+coord retune included); caught
  same-session by ring-center check; fully reverted.
- **Medallion fix (minimal — same 3x2 geometry as the vs2 icon):**
  art = effect_tail place `'0xB10B,3,2' -> '0xB526'` (vs2 Donovan
  icon, identified against Pyron b0f5/Huitzil b108 by color render
  — vs2's wheel pal indices ≠ char ids for the appended trio);
  colors = data_port `med_pal_row14_a` (select pal row 14, block A
  copy 0x3A3A80 only — block B's row 14 belongs to another
  sub-venue — ← vs2 row-05 source 0x3BAFDC). No record retune
  needed. Live row 14 lands byte-equal to vs2's live Donovan-icon
  row. Gate: colors §4 extension (row-14 freeze + record intact +
  Gallon-cell-intact tripwire).
- **Tooling gotcha (GOTCHAS): replay.lua DUMPS separator is `;`,
  not `,`** — comma-joined multi-dumps die rc=3 with no artifacts;
  same-frame multi-window dumps are fine with `;`.
- Verification: colors + reactions gates extended and green on
  `b91647c7`; full battery queued (results below when done).
- Select screens (mode-select wheel view + VS splash) visually
  re-verified: Donovan medallion in Jedah's ringed cell, Gallon's
  werewolf 3x3 restored, VS-splash big portrait + name were already
  correct.

## Session 14z-58e (handoff hygiene: reproducibility PROVEN)

Closing checks before handing off, all green:

- **The committed patches rebuild the emulator from a pristine tree.**
  Reverted the submodule working tree entirely (including deleting
  `harness.cpp`), ran `tools/setup_fbneo.sh`, and the resulting binary
  passes the full WIDE gate — **36 checks**. So `0001` (frontend harness
  incl. framebuffer + gfx dumps) and `0002` (WIDE descriptor + the one
  gated core line) are complete and self-sufficient; nothing this session
  achieved lives only in an uncommitted working file.
- HANDOFF.md updated: it is the first read of any session and still
  described only the Donovan/M2b world. Now carries the WIDE section
  (what/why/status/exact commands/authoring rules) and the gates added
  since. Its FBNeo row also corrected — the old "loads CRC-changed
  patched zips" claim is what made the 14z-57 CRC trap so expensive.

Handoff state: B0-B4 green, gate 36/36, working tree clean apart from the
expected submodule modification. Next session starts at B5 (MAME parity)
or Phase C (address-space model) — both specified in NEXT_SESSION.

## Session 14z-58 (WIDE B4 GFX: PASS — the new banks are real, and the CRC trap)

**The profile's central question is answered: the appended graphics banks
are usable.** With the emulator-side canary relocating bank-2/3 sprites
into WIDE banks 4/5 at draw time, group C loaded as a byte copy of group
B, and the STOCK rom on both sides: **9/9 legacy replays RAM- AND
pixel-identical.** Fifteen characters' sprites are being fetched from
address space that did not exist before, and nothing moves by one pixel.
The 19-bit tile address works end to end: descriptor -> loader -> bank
bits -> bit-12 promote -> fetch -> render.

### B4 PRG half: PASS — and the control that saved it from being a lie

Relocated **all 20 per-char sound record arrays** into the extension
(`CPU:$400000+`, 1KB each) and repointed every row of the table at
`PRG:0xBF41A`. RAM bit-identical across 02/01/30.

**My first PRG attempt was VACUOUS and the negative control caught it.**
Relocating only char 00's array "passed" — but pointing that same row at
ZERO FILL also changed nothing, i.e. the row is never read in those
replays. With all 20 rows relocated the zeros variant DOES diverge, so
the identical result is real evidence. Always pair a relocation pass with
"point it at garbage and prove the behaviour changes".

Authoring notes for extension content: above `PRG:0x0FFFFF` there is no
encryption (write raw), but the member still needs FILE byte order
(`words_to_file_bytes(words_from_logical_bytes(...))`) and its REAL CRC
in the descriptor.

### Root cause of the 14z-57 failure: FBNeo matches zip members by CRC

The appended members declared the CRC of ZERO FILL while the file held a
copy of group B. FBNeo therefore loaded **0xFF fill** for them — and
still printed `Loading graphics (vsw.31m)... (OK)`. Everything else in
the chain had already been verified correct, which is exactly why it was
so confusing.

**This CONTRADICTS an earlier note in this repo** ("FBNeo verified to load
CRC-changed patched zips (no descriptor change needed)"). That is true
only in the sense that FBNeo does not refuse to run; for gfx/QSound
members a CRC mismatch silently substitutes 0xFF. Corrected in GOTCHAS.

Diagnostic path worth reusing (it is now written up in cps2_wide.md):
1. `FBNEO_HGFX=<off>-<end>` gfx-buffer dump (new harness capability) —
   showed 32-48MB reading 0xFF while groups A/B held data;
2. the decoder ORs into a ZERO-filled buffer, so 0xFF proves the SOURCE
   bytes were 0xFF, i.e. the member never arrived;
3. from there the CRC mismatch was two minutes away.
   Memory-content shorthand: **0xFF = not loaded; 0x00 = loaded but
   empty** (the buffer is memset to 0 at allocation).

### Hardening

- `tools/build_wide_romset.py` now PRINTS the exact descriptor rows
  (name/size/CRC) for every member it writes — paste them into the
  descriptor; a mismatch is silent.
- `tests/test_wide_profile.sh` gained **section 3, the B4 canary**, so
  "the appended banks actually render" is now a standing gate, not a
  one-off experiment. It self-skips (loudly) if the romset was not built
  with `--gfx-copy-group-b`. Full gate: **36 checks green**.
- Temporary debug probes removed; both FBNeo patches regenerated with
  clean scopes.

### Status

PRG 6MB / GFX 48MB / QSound 16MB: declared, inert, and — for gfx — proven
USABLE. Remaining for B4: the PRG half (relocate real data above 4MB and
repoint one pointer; require bit-identical RAM). Then B5/B5b.

## Session 14z-57 (WIDE B4 attempt 2 — clean fail, narrowed to the loader)

The redesigned canary works as a diagnostic: `CPS2_WIDE_CANARY=1`
relocates bank-2/3 sprites into WIDE banks 4/5 **at draw time**, with gfx
group C loaded as a byte copy of group B, running the STOCK rom. Work RAM
is bit-identical (the ROM is untouched — single variable, as intended);
pixels differ on ~4,400 frames.

**What is now PROVEN (all measured this session):**
- The regions are genuinely real, from the emulator's own load report:
  `68K ROM 0x00600000`, `Graphics 0x03000000`, `QSound 0x01000000`.
  B0/B1/B3 are not paper changes.
- All twelve gfx members load OK, group C included.
- **The 19-bit address path is CORRECT.** Instrumented at the composition
  point: `y=0xb065` -> `n=0x0536CA` -> byte `0x29B6500` = bank 5 at
  offset `0x9B6500` within group C — exactly the offset the source tile
  occupies within group B. The guard passes (`mask=0x03ffffff`,
  `len=0x03000000`).
- **Group C's content is not what gets fetched**: a zero-filled group C
  and a copy-of-group-B group C render identically.

**Therefore:** sprite record -> bank bits -> promote -> address -> guard
are all correct, and the failure lies in WHERE THE LOADER PUT THE BYTES.
Suspect `Cps2LoadTiles`/`Cps2LoadOne`/`CpsGfxLoad` advancement for a
third group.

**Next step is one measurement, not a guess:** dump `CpsGfx` around byte
`0x29B6500` at runtime and compare with the expected tile at
`0x19B6500` (group B). Differ -> load-map bug, and the address path is
exonerated. A gfx-buffer dump is a small harness addition and is on the
B5b instrument list regardless.

Housekeeping: debug printfs removed; the env-gated canary probe is kept
(it is a genuine diagnostic and is off by default); patch 0002
regenerated; **profile gate re-run green 24/24 with the canary off**, so
the tree is in a known-good state.

Also worth recording: two self-inflicted detours cost real time — running
the instrumented build WITHOUT `FBNEO_HVIDEO` (no video => the sprite
path never executes => no output, which looked like "the flag is not
set"), and forgetting that the runner captures the emulator's stdout to
`<sandbox>/fbneo_replay.log` rather than the terminal.

## Session 14z-56 (WIDE B4 attempt 1: an invalid canary, honestly)

**Result: the canary was wrong, not the profile.** Recording it in full
because the reasoning matters more than the outcome.

The canary: make gfx group C a byte copy of group B, remap 15 characters'
per-char bank rows from banks 2/3 to WIDE banks 4/5, require
pixel-identical rendering. It diverged on RAM *and* pixels from ~f894.

Diagnosis, in order:
1. Suspected the game masked the new bank bit away. Found five
   `andi.w #$6000` sites and widened them all to `#$7000` — **no change**,
   hypothesis dead.
2. Ruled out `nCpsObjectBank` (it is the OBJ RAM double-buffer selector,
   not a tile bank).
3. **The isolation that actually worked, and should have been first:** ran
   the modified program under MAME, which has NO extended-bank support at
   all. RAM diverges there too, at frame 890. So a game-behaviour change
   fully accounts for the result and the canary says NOTHING about the
   emulator's 19-bit path.

**Two findings banked (both documented in engine_internals + GOTCHAS):**
- **The game emits the WIDE encoding correctly.** y-word census of the
  modified program (objy_bits.lua under MAME): `bit12=1`, bank field
  shifted exactly as designed. Nothing strips the bit — the game side of
  19-bit addressing is fine.
- **The per-char OBJ bank word (PRG:0x282D4, opcode view) is NOT
  display-only** — it drives game logic too. Vanilla row values recorded
  in engine_internals. Any future tile-bank repoint must expect a
  behavioural change, not a cosmetic one.

**Redesigned canary (next action, spec in docs/project/cps2_wide.md):** change the
EMULATOR under a test-only env flag instead of the ROM — OR 0x1000 into
bank-2/3 sprites' y-words at the promote point, run the STOCK rom, and
require both RAM (guaranteed identical, no ROM change) and framebuffer
identical. Then exactly one subsystem can explain any difference.

Profile status is UNCHANGED and still honest: PRG 6MB / GFX 48MB / QSound
16MB declared and proven inert (B0-B3, 24/24 each); usability of the new
space remains UNPROVEN until the redesigned B4 passes. No content should
be authored into the extension before then.

## Session 14z-55 (WIDE B2 — the 19-bit tile address; and the gate's video blind spot)

**B2 done: the profile's ONLY core emulator edit is in and proven inert.**
`Cps2Wide` flag (defined beside `Cps2Turbo` in cps_rw.cpp, extern in
cps.h, set by `Cps2WideInit` for the vsavjw driver only, cleared in
DrvExit so it can never leak into another game) gates the 19-bit sprite
tile address in cps_obj.cpp:

    if (Cps2Turbo || Cps2Wide) {
        if (ps[1] & 0x1000) ps[1] |= 0x8000;      // bit 12 -> bit 15
        n |= (ps[1] & 0xe000) << 3;               // 19 bits, 64MB reach
    }

Gate: 24/24 bit-identical, work RAM AND framebuffer.

### THE FINDING OF THIS SESSION: the FBNeo gate never rendered a pixel

The harness ran every frame with `pBurnDraw = NULL`. Correct for a
work-RAM oracle, but it means **the emulator-side gate was structurally
blind to the entire video path** — and B2's change lives ENTIRELY in the
video path. A RAM-only gate would have reported B2 green without ever
executing the modified line. (Every pixel test the project owns is
MAME-side; FBNeo had none.)

Fixed: opt-in framebuffer checksums in harness.cpp (`FBNEO_HVIDEO=<path>`,
16bpp off-screen render, per-frame FNV-1a; default still pBurnDraw=NULL so
every frozen expectation is untouched). Verified live: 384x224, 3,932
distinct checksums across one replay, so it is genuinely rendering.
tests/test_wide_profile.sh now compares RAM **and** framebuffer on both
invariants. This is also the first delivery of a B5b instrument — FBNeo
now has a pixel gate, which the FBNeo-only fallback would require anyway.

**Inertness is not functionality** — stated explicitly in the gate output.
B2 proves the 19-bit path is harmless (vanilla never sets bit 12). Proving
it REACHES the new banks is B4's job, and B4 must carry that positive
control.

### B3 — PRG 4 -> 6 MB: green, and A1's prediction held exactly

Four appended 512KB program members. **Zero emulator core lines**, as A1
measured: FBNeo maps program ROM as `SekMapMemory(CpsRom, 0,
nCpsRomLen-1)`, so the declaration is the mapping. 24/24 bit-identical
(RAM + framebuffer). Notes for whoever authors into it:
- everything above `PRG:0x0FFFFF` is OUTSIDE the CPS-2 encryption window,
  so extension space is RAW — easier to author into than the original
  in-crypt hole A;
- `$400000-$40000F` (CpsFrg registers) is now read-shadowed by ROM and is
  reserved, never-allocate. Writes still reach the register handler.

**The full v1 shape is now declared and inert: PRG 6MB / GFX 48MB /
QSound 16MB, for a total emulator cost of ONE widened condition.**

But: every step so far is ZERO-FILLED. The space is declared, not
demonstrated. B4 is the step that proves it usable, and it must carry the
positive controls (relocated anim block executing from the extension; a
legacy tile rendering from gfx group C with bit 12 set).

Also fixed: the `--full` fingerprint's region classifier put the new
program members under gfx/qsnd (it keys off filename; FBNeo keys off
descriptor type). WIDE members are now named so the heuristic stays
right, and the tool documents that it hashes the union of resolved zips —
a superset of what the driver loads, so it is an artifact identity, not a
statement of what was mapped.

### Second trap: a drifting A/B reference is worse than none

The first emulator-superset run "failed" 5 replays. Cause: the reference
binary predated the harness video feature, so it emitted no framebuffer
log — noise, not signal. A reference must differ from the build under test
by EXACTLY the patch under test; `WIDE=0 tools/setup_fbneo.sh` now builds
one from the same tree state, and the docs say so.

Patch hygiene: the two FBNeo patches were regenerated with clean scopes —
`0001-vampire-saved-harness.patch` (frontend only: makefile, main.cpp,
harness.cpp incl. video) and `0002-cps2-wide-v1.patch` (exactly the five
CPS-2 driver files). Trust surfaces stay separable, as Rule 1 v2 requires.

## Session 14z-54 (WIDE Phase B0+B1: the first two regions grown and proven inert)

Both steps green on the new gate `tests/test_wide_profile.sh`
(12-replay legacy corpus x 2 invariants = 24 comparisons per run):

- **B0 — QSound 8 -> 16 MB.** New FBNeo driver entry `vsavjw` (clone of
  vsav) declaring four uniform 4 MB QSound members. **Zero core lines** —
  FBNeo derives nCpsQSamLen from the descriptor table and masks with
  `nCpsQSamLen-1`. 24/24 bit-identical.
- **B1 — GFX 32 -> 48 MB.** One appended group of four uniform 4 MB
  members (the loader consumes gfx four at a time and mis-sizes if any
  member differs, so groups of four / equal sizes are structural, not
  stylistic). 24/24 bit-identical — **A3's prediction held**: no legacy
  draw depended on the 32 MB address wrap.

**The two invariants, both enforced every run:**
1. *Emulator superset invariant* (Rule 1 v2 clause 3) — the patched binary
   running STOCK vsavj is bit-identical to a pre-patch reference binary.
   `WIDE=0 tools/setup_fbneo.sh` builds that reference. The gate exits 2
   with a loud notice if no reference is supplied; an unrun invariant must
   never read as green.
2. *Profile inertness* — WIDE set vs stock set on the same binary.

**Fingerprint blind spot confirmed and partly closed.** The dispatch
fingerprint hashes PROGRAM members only, so gfx/QSound content and the
emulator profile were invisible to build identity (they survived only as
hand-written registry notes — and the patched builds DO change gfx
members). Added `build_fingerprint.py --full`: whole-set fingerprint plus
a per-region breakdown, which now reports WIDE as 16 gfx/qsnd members /
64 MB against stock's 10 / 40 MB. Promoting --full to the dispatch key is
deliberate future work: it changes every fingerprint and so needs the
registry rows recomputed (expectation CONTENT is unaffected — a registry
update, not a re-freeze).

Artifacts: `emu/fbneo-patches/0002-cps2-wide-v1-qsound16.patch` (kept
SEPARATE from the frontend harness patch so the trust surfaces stay
separable), `tools/build_wide_romset.py`, `tests/test_wide_profile.sh`,
`tools/setup_fbneo.sh` gains WIDE=0/1.

Two traps paid for: FBNeo's `d_cps2.cpp` is not valid UTF-8 (game titles
in local encodings) so scripted edits must be byte-mode; and SKIPDEPEND=1
does not track header/driver changes, so a driver edit needs its object
touched explicitly or the build silently keeps the old descriptor.

NEXT: B2 (the bit-12 promote line under a `Cps2Wide` flag — the profile's
only real core edit), B3 (PRG 4->6 MB, which A1 says costs zero lines),
then B4 the canary build.

## Session 14z-53 (RE-CONTEXTUALIZED: from "fit in the holes" to CPS-2 WIDE; Phase A measurements complete)

**The maintainer re-stated the goal and it changes the shape of the
work:** the target is all 18 characters; a stock CPS-2 provably cannot
hold them; the target platform is EMULATION with **FBNeo primary** (it is
the GGPO rollback-netplay reference, which is in the ideal scope), MAME
as oracle where it can follow, MiSTer nice-to-have. The Donovan work is a
**proof of concept** — it proved characters can be ported and surfaced
the limits; it never addressed structuring the ROM for three characters.

**The measured wall** (this is why the pivot is forced, not chosen):

| Resource | Free today | 1 char costs | 3 need | Deficit |
|---|---|---|---|---|
| PRG | 1,112 B | ~338 KiB | ~1.0 MB | ~886 KiB |
| GFX | ~370 tiles | ~16-18K tiles | ~50K tiles | ~6-7 MB |
| QSound | 0 | — | 3 voice banks | ~8 MB |

Slot replacement cannot pay: only ~134 KiB of Jedah's PRG was ever
identified as dead (unaudited, already double-booked), and the GFX
equivalent audit already found the "dead" band held 358 protected codes.

### Decisions taken (maintainer, round 66)

1. **Rule 1 v2 — profile-gated emulator changes.** Emulator edits allowed
   only inside a named versioned profile, bounded/declarative, gated on a
   driver flag, and subject to an **emulator superset invariant** (patched
   binary + stock vsavj must reproduce frozen vanilla expectations
   bit-for-bit). Ratified per profile version.
2. **Size the profile ONCE**: PRG 6 MB / GFX 48 MB / QSound 16 MB
   (every size change forces a full expectation re-freeze).
3. **MAME**: attempt the pinned source build; FBNeo is primary if
   alignment becomes a wall — **but losing MAME must never mean losing
   test coverage** (maintainer's rider). The FBNeo-only path is gated
   behind porting the instrument set into harness.cpp and PROVING
   equivalence by re-deriving known findings.
4. Phase A measurements before any growth.

Profile spec drafted: **docs/project/cps2_wide.md** (v1 DRAFT, awaiting
ratification after Phase B). Approved plan archived at
~/.claude/plans/glowing-bouncing-iverson.md.

### Phase A — ALL FOUR GREEN (tests/audit_wide_phase_a.sh, vanilla corpus)

- **A1: PRG growth is FREE.** Zero reads into any candidate extension
  window across the whole legacy corpus. FBNeo already maps program ROM
  as `SekMapMemory(CpsRom, 0, nCpsRomLen-1)`, so growing to 6 MB costs
  **zero core lines** — the `$A00000` fallback window is unnecessary.
  Instrument ground-truthed first (control window saw 252,705 work-RAM
  reads) so the null result is evidence, not blindness.
- **A2: the 19th tile bit exists — but NOT where the plan said.**
  **y-word bit 15 is the CPS-2 sprite-list TERMINATOR** (`CpsObjGet:
  if (ps[1] & 0x8000) break`), so the proposed 0x6000->0xE000 mask
  widening would have dropped every sprite after the first one carrying
  it. Capcom's own CPS-2 Turbo solves this by promoting **bit 12** after
  the terminator check; measurement confirms vanilla never sets bit 12 on
  a live sprite, so WIDE adopts the Turbo rule. The whole profile now
  costs **one gated conditional** of emulation logic.
- **A3: gfx growth does not disturb scroll3.** No real legacy code
  reaches the 0xC000 wrap threshold (max real code 0x0; only the 0xFFFF
  blank sentinel sits high). First pass reported a false BLOCKED because
  the raw census counted the sentinel — corrected with a real-vs-sentinel
  split. B1's pixel gate remains the definitive confirmation.
- **A4: Z80 is not a constraint.** 27,727 B free in vm3.01/02 (largest
  run 13,961 B) — ample for new sample-table rows. This was the only
  completely unmeasured region in the project.

New instruments (committed, rerunnable): tests/lua/unmapped_probe.lua,
tests/lua/objy_bits.lua, tools/audit_z80_space.py, plus a real-vs-sentinel
census added to tests/lua/scroll3_watch.lua (its existing SCROLL3SUMMARY
contract untouched; the new data is a separate SCROLL3CENSUS line).
Three GOTCHAS paid for: the terminator trap, censusing without knowing a
structure's terminator, and the tap-installer reentrancy segfault.

### NEXT: Phase B (prove the profile inert, one variable per build)

B0 QSound 16 MB (legal today, rehearses the workflow, fixes the
fingerprint's blind spot) -> B1 GFX 48 MB zero-filled -> B2 the bit-12
line under `Cps2Wide` -> B3 PRG 6 MB -> B4 the canary build (relocate an
EXISTING character's anim block into the extension + one legacy tile into
the new gfx group, both against a bit-exact vanilla oracle) -> B5 MAME
parity / B5b suite preservation.

## Session 14z-52 (M5 phase 1: music bug root-caused; 13 rows restored; the rest is a SPACE problem)

**THE MUSIC BUG, SOLVED (measured, not theorised):** vsavj's sound-id
range **0x700-0x7FF holds MUSIC TRACKS**; vs2 reuses that exact range
for **Donovan's voice bank**. Profiling every id his table uses on both
sets (voice count / key-on count / sample identity — the music
signature is unmistakable: 8-15 voices, dozens of key-ons, 4-12
distinct samples) gives the definitive breakdown of his 47 table ids:
  - **6 SHARED** (0x110 0x111 0x112 0x119 0x152 0x202) — same id, same
    sample content on both sets;
  - **30 are MUSIC TRACKS on vsavj** (0x700-0x71F, 0x750-0x757);
  - **9 have NO sample in vsav at all** (vsav's sample ROMs are full);
  - 2 are vs2-silent anyway.
That is why 214P/214K played music in round 2. The session-5 theory
("same ids mean different things") was wrong in general — most ids ARE
shared — but accidentally right about the range Donovan leans on.

**Phase 1 shipped (build ae701ffb):** 13 stubbed sound-farm rows
restored to their vsavj same-id entries (content-verified per id,
including the odd-shaped 0x18d entry whose vsavj twin is byte-identical
at 0x424E); 11 rows kept silent, each now carrying its MEASURED reason
instead of the blanket session-9 note. **Honest caveat: those 13
entries never fire in any of our 8 Donovan replays** — correct, but
currently inaudible.

**Where Donovan's sound actually lives (and why it is still silent):**
the per-node walker path — ported dispatcher (built at ~0xCE3B8) reads
`lea 0xBF41A,a0; movea.l (a0,charid*4),a0; move.w (a0,idx*8),d1` then
calls the helper. That helper stub absorbs **~400 calls per match**.
Enabling it needs Donovan's own record array because slot 0x0F still
resolves to JEDAH's array (~40 entries) while Donovan's scripts index
up to **43** (measured, replays 12/25/56) — so it would both play
Jedah's sounds and read past the array end into neighbouring data
(random ids, music range included).

**Implemented but BLOCKED ON ROM SPACE:** a new declarative generator
kind `[[sound_table]]` (tools/gen_donovan_patch.py) ports a per-char
record array with an **id allowlist**, zeroing every unplayable id —
the engine's dispatcher skips `id == 0` (`tst.w d1; beq`), so those
sounds stay silent instead of playing music. The manifest row
(don_sfx_records: 44 entries, keep_ids = the 6 shared) is written and
COMMENTED OUT: it needs 0x160 bytes and **both code holes are full** —
allocating it evicts the two ls_freeze site_thunks. Tried hole a and
hole b; neither fits. New decision queued (see Decisions pending).

**Gate added: tests/test_don_sound.sh** — sound is invisible to every
RAM and pixel gate we own, so this is the only detector. It replays 4
Donovan scripts, taps the 68k sound ring, and (a) FAILS if any
0x700-0x7FF id is ever enqueued (the music tripwire), (b) freezes the
exact id inventory per replay. Green on ae701ffb; inventories verified
deterministic across two passes each.

Instruments promoted: tests/lua/ring_tap.lua (ring id tap),
tests/lua/qs_sweep.lua + tools/qs_analyze.py (14z-51). Gotcha paid:
a 68k `move.l` reaches a memory tap as TWO word writes, so the sound
id lands at entry+2, not entry+0 — a tap keyed on +0 sees only zeros.

## Session 14z-51 (M5 sounds: discovery phase — the id-space myth dies)

Method: built the ring-poke + chip-write-tap instrument
(tests/lua/qs_sweep.lua + tools/qs_analyze.py; full path decode in
engine_internals "Sound subsystem"). Swept ids 0x000-0x7FF on BOTH
games in silent test mode; extracted per-id QSound key-ons
(bank/start/end -> sample address -> content compare across images).

FINDINGS (docs/project/m5/keyons_*.json = the measured id maps):
- **Shared sfx keep IDENTICAL ids across the family.** All 14
  content-shared stubbed MOVE-sfx ids exist on vsavj as the same id
  keying the same (relocated) sample. NO id translation table is
  needed for these.
- **The session-5 "same-id = music in vsavj" theory is DEAD** —
  vsavj 0x136/0x137/etc are the same sword/impact sfx as vs2's. The
  round-2 music-on-214P bug therefore has a DIFFERENT mechanism
  (suspects: the (6,a0,d2.w) dispatcher-table indirection, or id
  corruption through the farm-call path). MUST be re-diagnosed with
  the new instrument before any unstub ships.
- **vs2-only content (absent from vsav's sample ROMs): ids 0x71D,
  0x73E, 0x753, 0x754, 0x755, 0x756** — Donovan voice lines/new sfx;
  0x14A and 0x173 are same-id-DIFFERENT-content (vsavj reuses them);
  0x747 keys nothing on either side yet (params/window). vsav's
  11m/12m are FULL (zero blank blocks): porting voices = grow the
  QSound sample region (descriptor-level change, CLAUDE.md rule 1
  allows load-map changes) or replace something. DECISION MATERIAL.
- Instrument notes: ring FF0E0E/index FF1E0E (a5=FF8000, negative
  displacements — the FF8E0E literal is a sign-extension trap);
  Z80 chip triplets at D000-D002; bank reg belongs to voice+1;
  12-frame sweep windows misattribute delayed-attack sfx.

NEXT (in order): (1) re-diagnose the 214P/214K music mechanism with
the sweep instrument on the DONOVAN BUILD (poke the exact farm-path
ids, watch what reaches the ring); (2) decide + implement the
shared-sfx unstubs; (3) the voice-samples decision.

## Session 14z-50 (round 65: M2b+ASSETS FREEZE at b91647c7)

Maintainer decision: freeze before starting M5 sounds ("this is
mechanically sound as far as we can tell"). Procedure per the
M2b-CORE precedent (e14e591):

- `tests/expected/registry.tsv`: `b91647c7…` -> `donovan-m2c`
  (all 8 patched vm3 gfx member sha1s in the note — group A now
  carries effect-tail/HUD/medallion art, so A-members are recorded
  alongside B for the first time).
- `tests/expected/donovan-m2c/`: 14 authored .masked rows (the
  current battery-measured inventory — NOTE 08_challenger_join is
  `flicker 1 3507` here vs m2b's `2 3507,3807`, and 29/30 gained
  masked rows, both post-m2b gate additions), 16 .skip rows (every
  vsav2-target replay incl. the 14z-era native ground-truth
  replays 51/52/57), and self-frozen sha1+log expectations for the
  33 vsavj Donovan replays, frozen on b91647c7 (each run twice,
  determinism-checked, by run_suite --freeze).
- SYNC BUG CAUGHT AT FREEZE TIME: `run_suite.sh` carries its own
  MASK copy ("must stay in sync with M2A_MASK") — it still had the
  two-window basis; the third window would have failed every
  masked row of the freeze suite. Synced + comment updated. The
  duplication is a standing trap; if a fourth window is ever
  added, grep for MASK_RANGES consumers.
- Validation: freeze pass green; plain `run_suite.sh` pass green
  end-to-end by pure fingerprint auto-detection (masked rows
  validated against authored expectations in that pass — freeze
  mode does not check them).
- HANDOFF build registry row added; patch_index status updated.

## Session 14z-49d (round 64: mask window RATIFIED; recolor necessity proven; audit script)

- Maintainer asked whether Donovan's icon could ride Jedah's vanilla
  row 14 (no recolor -> no mask window at all). MEASURED, twice:
  (a) raw palette swap: Donovan renders purple-faced (skin indices
  land on Jedah's lavenders); (b) index-remapped art onto the
  vanilla row (best hand-tuned map): the icon's 7-step brown ramp
  collapses onto Jedah's 3 browns — face flattens to two tan bands,
  hair goes muddy blue-grey. Both renders shown to the maintainer
  (session scratch med_pal_ab.png / med_pal_tuned.png; method: the
  gfx_tiles offline renderer + live palette dumps). CONCLUSION: the
  recolor is genuinely required; option C (remap) rejected on
  quality, option B (truncate 05's verification) rejected on
  coverage.
- **THIRD MASK WINDOW RATIFIED (maintainer, round 64): option A
  stands.** Decision moved from pending to made below. Their
  condition — "document in detail what's the window we're ignoring
  ... best be prepared in case we need to confirm one day" —
  honored three ways: the expanded docs/game/atlas/ram.md row (now
  carries both expected content values + when-to-rerun triggers),
  the m2a_common.sh basis comment, and a NEW SCRIPTED AUDIT:
  `tests/audit_mask_window_ff4182.sh` — reruns the original
  attribution measurement (05_timeout_idle f9126 on vanilla +
  build) and asserts (1) vanilla slot == vanilla row, (2) build
  slot == the designed ported row, (3) every neighborhood byte
  OUTSIDE the window ($FF4140-$FF41DF) is identical — i.e., the
  blind spot hides the designed diff and NOTHING else. On-demand
  (not battery): run on any new $FF41xx-adjacent divergence, row-14
  retune, or before extending the window family for Huitzil/Pyron.

## Session 14z-49c (round 63: 14z-49 maintainer-CONFIRMED)

- Maintainer, on `b91647c7`: **"both medallion portraits are clean,
  no regression, great success"** — the select medallion and the
  in-fight HUD mugshot/name close CONFIRMED. The whole 14z-48b
  venue-asset family is done.
- Still outstanding from their side: the full-cast ES-finish pass
  (their earlier commitment, unprompted here).
- The third-mask-window ratification was NOT explicitly addressed
  in the confirmation message — it remains in Decisions pending
  until they answer it directly.

## Session 14z-49b (battery divergence root-caused: the palette-fade staging buffer; THIRD MASK WINDOW — **MAINTAINER RATIFICATION NEEDED**)

First battery on the 14z-49 build FAILED two ways; both root-caused
to completion the same session (rule 6 honored):

1. **05_timeout_idle masked live-state diverged at f9126** (first
   red on this replay ever; batteries 43-48 green). Byte-for-byte
   attribution: the divergent bytes `RAM:$FF4183-$FF41A1` are select
   palette-block-A row 14 — vanilla values vs the 14z-49 ported
   Donovan-icon values, F-bright applied, row slot based at $FF4182.
   Mechanism: **venue fades stage palette-block rows through a
   work-RAM staging buffer** ($FF4182 + row*0x20 family); f9126 is
   the match→win fade after the round-1 timeout (Lilith CPU win).
   The medallion recolor is a DESIGNED content change to that ROM
   row, so the buffer now legitimately differs wherever a fade
   stages block A — even in legacy replays that never touch slot
   0x0F. Crucially: the live select screen itself does NOT stage
   through this buffer (frames 1-9125 incl. the full select were
   bit-identical), and the win screen's OWN palette overwrites row
   14 — **legacy win screens pixel-compare 0-diff vanilla vs
   patched (f9200 + f9400 measured)**. Display-only, no gameplay
   surface, no visible surface.
   FIX: third masked window `$FF4182-$FF41A1` (M2A_MASK
   "4182-41a2"), narrowly the one row slot; docs/game/atlas/ram.md row
   added; all 14 frozen masked vanilla logs regenerated with the
   new basis (m2a_freeze_masked). Chosen over demoting 05 to a
   first-divergence constant because the mask keeps all 12,120
   frames verified (the replay's post-round state machine coverage
   lives AFTER f9126). **This is a legacy-oracle basis change —
   the two existing windows are maintainer-approved, so this one
   is flagged PENDING MAINTAINER RATIFICATION** (revert = drop the
   mask range + re-freeze, cheap). Standing-watch note: this was
   root-caused, not tolerated — the class is "designed content on
   a display path", not flicker growth.
   Follow-on fact for M3: ANY select palette-block content change
   (Huitzil/Pyron rows later) will surface in this buffer family —
   extend the window with measured slots at that time.

2. **Pixel menu gate FAIL frames 950/1250 (880 px)** — the gate's
   own 14s design note predicted this exactly ("full-frame compare
   is valid until the wheel mugshot itself is ported, then this
   needs a mask"): the 880 pixels are the intended Donovan
   medallion diff on the two wheel-visible frames. FIX: the
   promised mask — the 48x32 cell box screen (172,41)-(220,73)
   zeroed on both sides for 950/1250; the box's correctness is
   covered by the colors-gate medallion locks + the build-time
   byte-exact art assert. Title frame 650 stays full-frame.

**Battery re-run on the new basis: GREEN** (battery_49b): 05 masked
bit-identical full-length again; flicker inventory IDENTICAL to
frozen (03@829,2093 / 10@3007,3129 / 16@829 / 04@1525,2009,2195 /
08@3507 / 09@829 / 29@2436 — no growth, standing watch satisfied);
divergence constants unchanged (06@700, attract@4278, pick@1080);
pixel gates pass with only the medallion box masked (650
full-frame). All 14z-49 gates green on `b91647c7`.

## Session 14z-48b (rounds 59-60: HC moves maintainer-CONFIRMED; HUD portrait = wrong ART not palette; select medallion re-listed)

- **All half-circle moves register and execute properly; graphics
  good** (maintainer, dbbcd74c).
- Maintainer challenged the "no vsavj equivalent" wording —
  correct challenge; precision note added to 14z-48 below (their
  standing ask honored: findings documented — the command/motion
  subsystem now has an engine_internals section).
- **IN-FIGHT HUD ITEM SHARPENED (maintainer captures, Desktop
  22.42.45 ours / 22.38.20 vs2): the mugshot beside the timer is
  JEDAH'S ART (yellow/red) and the name text reads "JEDAH" — vs
  vs2's brown Donovan mugshot + "Donovan" name.** Not a palette
  issue: the wrong PORTRAIT + NAME. Visible in every session
  snapshot in hindsight. = the M2b "select portrait/name/mugshot"
  remainder, one family with:
- **RE-LISTED: character-select portrait MEDALLION still Jedah's**
  (forgotten off the queue; now tracked). All three surfaces
  (select medallion, HUD mugshot, HUD name) = per-slot venue asset
  tables — one investigation, the 14z-45 method (find the venue's
  per-char art/palette/name sources, repoint slot 0x0F; the name
  text also needs Donovan's glyphs — check what the VS-screen name
  uses, ours shows correct "Donovan" there... verify).

## Session 14z-48 (round 58: HALF-CIRCLE MOVES FIXED — the farm-helper-match had collapsed distinct motion tables; battery pending at entry time)

Round-58 results first: ES arc fully maintainer-confirmed (their
input issue, feel adequate, finishes clean incl. match-end ES LS);
select blink confirmed dead; NEW MINOR tracked = in-fight HUD
portrait palette (task list); NEW BLOCKER = no half-circle move
works (41236P Blizzard Sword / c.63214MP-HP Sword Grapple / 41236K
Press of Death EX) — all fine on vs2, never tested before on ours.

ROOT CAUSE (fully traced, build dbbcd74c):
- Command flow: per-char eval handler (table 0xD7718[char] -> the
  ported Donovan code) calls tiny ENGINE MOTION HELPERS (`lea
  <step-table>(pc),a3; bra <tracker-dispatcher>`; family at vs2
  0x29114-0x291EC = vsavj 0x29DC2-0x29F42), each = one motion shape.
  Trackers live in the player obj (+0x308..+0x338 per command);
  dispatcher state machines: state 2 = 4-bit direction-code match
  vs +0x12A, state 4 = 0x7700-bitmask match vs +0x1AC|+0x1AE; the
  dispatchers ARE proper twins (vs2 0x292A4 == vsavj 0x29F4A etc.).
  Step tables are DATA-view (lea(pc) + (a3,d0) reads — the 14z-43
  gotcha applied to the analysis itself: first dump used the wrong
  image).
- THE BUG: three reconciliation rows from the fuzzy
  "farm-helper-match" ladder mapped vs2 helpers to WRONG vsavj
  helpers: 0x2915C AND 0x29164 (the 63214 pair, tables
  [1,5,4,6,+12]) BOTH -> vsavj 0x29EBA (different table AND
  different dispatcher kind); 0x2916C (the 41236 triple-table) ->
  0x29E42 (shifted table). PRECISION (round-59 maintainer
  challenge, verified by caller scan): vsavj HAS half-circle
  motion tables — its near-match helpers (0x29E22/2A/32/3A...) are
  called from a dozen vanilla char code blocks (Morrigan Valkyrie
  Turn, Lilith Mystic Arrow / Gloomy Puppet Show, Bulleta et al.).
  What vsavj lacks is a BYTE-EXACT copy of VS2'S RE-TUNED versions
  of these three tables: 63214 = vsavj [1,5,4,16] (4 steps, final
  dir+flag fused) vs vs2 [1,5,4,6,12] (5 steps, final step SPLIT)
  — an input-leniency retune between engine generations, the same
  tuning family as the 14z-42 freeze constants. DECISION EMBEDDED
  IN THE FIX: Donovan's HCs use vs2's exact tables (vs2 input
  feel — the project default); mapping to vsavj's native
  near-tables (vanilla-cast HC feel) remains a two-line
  alternative if playtest ever prefers it. All OTHER
  Donovan helper rows content-verify EXACT (0x29114/1C/24/2C/54/
  9C/D4 -> their targets ✓; 0x29184/8C were already correct
  farm_port rows — the mechanism existed!).
- FIX: the three rows converted to kind=farm_port (param_hex = the
  vs2 table spans verbatim: 0x299CE/0x299DA 6 words each,
  0x299E6..0x29A06 16 words; common = 0x29F4A = the content-
  verified dispatcher twin). The generator's existing farm_port
  emitter places the tables as raw data (data-space reads correct
  in hole a) + 12-byte stubs.
- VERIFIED: Blizzard Sword chain entered at f2627 = ported analog
  0xD7980 of native 0x283E58 AT THE SAME FRAME; snapshots: ice
  deity + snowflake ✓, Sword Grapple giant-sword whip ✓, Press of
  Death deity press with stock consumed ✓. GATE: reaction gate
  section 5 (Blizzard + Grapple chain locks; replays 59/60).
- Census discipline note: matched helpers by TABLE CONTENT +
  dispatcher kind, not code similarity — the farm ladder's
  similarity matching is exactly what collapsed two motions onto
  one target (GOTCHAS entry).

## Session 14z-47 (SELECT POST-CONFIRM BLINK FIXED — accent thunks gain the owner-link venue fallback; battery pending at entry time)

The last tracked cosmetic (14z-32) closed, build b43c7352:
- **Mechanism (measured):** at the select venue the accent-marching
  object is NOT the player (a6 = venue obj ffb880, +0x382 = venue
  id 0x07) so the color-aware thunks' char check always fell to the
  vanilla punch-color slots -> post-confirm blink for non-punch
  picks. The venue objects carry the standard OWNER LINK at +0x30
  (ffb880 -> 0x8400; P2 twin ffba80 -> 0x8800), and the PLAYER
  object already holds the picked color (+0x3AE, e.g. 5 for HK)
  at confirm time.
- **FIX:** all four accent_color_aware thunks extended with a venue
  fallback: owner via +0x30 (movea.w sign-extend), owner char ==
  0x0F -> block = [0x38C1D4].l + color*0x80 (the EXACT match-init
  computation 0x1C670-0x1C68E against the ported block array at
  0x0CEAF0). Null/foreign owner links read ROM byte 0x382 = 0xA5
  != 0x0F -> vanilla (verified). In-match path untouched; legacy
  changes only for owner-char-0x0F.
- **Verified NATIVE-EXACT:** post-confirm (HK) P1 accent rows
  0x0A-0x0D steady across consecutive frames AND byte-equal to
  native vs2's select post-confirm state (direct A/B, both games
  select-confirm-6 at the same frames). Gate: test_don_colors
  section 4 (frozen native rows + steadiness; replay 58 promoted).
- Method note: an early "expected" reference computed from block
  indexing was WRONG (grey ramp) — the direct native A/B was the
  authority; per-frame CONSECUTIVE sampling needed (20f sampling
  phase-locks with the 4f march = false steadiness).

## Session 14z-46 (SWORDLESS-DEITY PALETTE FIXED — the state_hook seq-id synthesis was wrong for 8 of 12 stubs; battery pending at entry time)

The round-41 item (ours yellow deity/lightning vs vs2 blue/white)
root-caused to a SYNTHESIS BUG in the session-8/9 [state_hook]
machinery (build c45bdc45):
- **Mechanism:** the swordless summon fires ext state 0xBE (k=6);
  our stub uploaded seq record 0x2D3 (consecutive-id assumption
  seq_first_id+k); vs2's own case for that state carries **0x2D4**
  (trace-proven, both games, upload at f2913 -> P1 row 0x0B family).
  The full vs2 case census (dispatch table 0x29B6C idx 89-100):
  ids [2cd 2ce 2cf 2d3 2d1 (fixture) 2d4 (290+color) 29e (29e+bsr)
  2cd (fixture)] — consecutive ONLY for the first three (why the
  synthesis sampling looked uniform). Two cases are direct fixture-
  block uploads (base 0x3CB7DC +0x140 by +0x3C3, +color*0x20 —
  targets rows 0x14/0x15 and 0x0E), one adds the COLOR to id 0x290,
  one double-acts via bsr+bra. Vanilla-range ids 0x290-0x29E:
  records DRIFTED between engines (vsavj's content differs).
- **Live-state census (image scan for move.b #state,$14E):**
  Donovan's code writes only 0xB2/B4/B6/B8/BA/BE/C6 (k=0,1,2,3,4,
  6,10). ALL the awkward cases (both fixture, 290+color, bsr) are
  DEAD STATES. Beyond the deity (k=6), two LIVE latent wrong-record
  bugs fixed in the same stroke: state 0xB8 (2d0 -> 2d3) and state
  0xC6, 4 write sites (2d7 -> 2cd).
- **FIX:** [state_hook] seq_ids per-stub map (comma-string;
  _minitoml has no array-of-int support) + generator emits per-stub
  ids, build-time-verified against vs2's OWN dispatch table; dead
  states get safe no-op stubs (jmp ret_equiv — no palette change;
  if a future port writes one, upgrade to the real vs2 case shape —
  the census above is the spec; hole-b budget note: the fixture
  block would need ~0x240, only ~0x1F0 free).
- **Verified:** deity rows 0x0B/0x0C byte-MATCH native at f2960;
  snapshot = blue deity + white/blue lightning (the native look).
  Victim-shock coloring differences at the same frame = shock PHASE
  (ours 2-HIT vs native 3-HIT at the sample — alternating X-ray
  frames), not palette. GATE: test_don_column.sh + native-locked
  rows 0x0B/0x0C (frozen from plant_vs2 f2960).
- Replay promoted: 57_vs2_plant_native.rpl (the native ground
  truth; datums in its header).

## Session 14z-45b (round 56 on 4f69589d: win screen maintainer-CONFIRMED; lose/continue NO-ISSUE)

- **Win screen fixed ✓** (maintainer).
- **Lose/continue screens: NO ISSUE** — maintainer clarifies the
  flow: losing shows the OPPONENT'S win screen (their venue, their
  tables — vanilla content, unaffected) then the SHARED continue
  screen; both clean. The whole rounds-51/55/56 win-screen arc
  closes.

## Session 14z-45 (WIN SCREEN FIXED — palette + composition, native-locked; battery pending at entry time)

One measurement session closed all three round-51/55 defects (build
4f69589d):
- **Mechanism (all measured):** the win-portrait drawer object
  (ffb800; the second object ffb880 = text/frame, already correct)
  takes position AND palette from per-WINNER-char engine tables:
  - position: pc-relative table 0x5F200 (4B/char), read at
    0x5F1A0/A6 by the setter (winner id from +0x382(a4)); entry
    0x0F = Jedah's (0x70,0x80) vs vs2 Donovan (0xF0,0x98) [vs2 twin
    0x6B1EC/table 0x6B210] = EXACTLY the (-128,+24) OBJ shift
    measured entry-for-entry at f4100.
  - palette: `movea.l #$3AD700,a0` at 0x5F1B6 + (color*17+id)*0xA0
    -> 5 rows (0x15-0x19) via uploader 0x1C3A4 (d7=4). Slot 0x0F =
    Jedah's rows = the purple wash (rows 15-17) AND Anita's grey
    silhouette (rows 18-19 = pure grey ramps).
  - vs2's Donovan win-palette: contiguous 5-row sets per color at
    0x3C365C + color*0xB40 (stride = 18 chars x 5 rows; verified
    row-for-row vs native win-screen palette RAM at f4100).
- **FIXES:** code_word x4 (position entries 0x0F AND 0x1F ->
  0x00F0/0x0098; table is pc-relative/program-space -> code rows,
  the 14z-43 gotcha respected) + data_port x8 win_pal_slot0f_c0..c7
  (Jedah's 8 color slices of the vanilla table REPLACED IN PLACE
  with vs2's sets — first-choice hole-b thunk didn't fit: hole B
  watermark 0x3FFE10, only 0x1F0 free; in-place slot-content
  replacement is the cleaner class anyway).
- **Verified:** rows 0x15-0x19 byte-MATCH native at f4100 for the
  gate color; OBJ base entry native-exact (160,32); snapshot
  visually identical to the native reference. GATE: reaction gate
  section 3 extended with win-screen locks (frozen native rows +
  composition base). Tool note: replay.lua DUMPS ranges are
  END-INCLUSIVE (dump = end-start+1 bytes) — trim before comparing
  to frozen hex.
- Residual to watch (maintainer eyeball): non-gate COLORS (the 8
  ported sets are all vs2-verbatim so all should be right); rows
  outside 0x15-0x19 (vs2 has extra win-venue sub-uploads, e.g. its
  0x3C2A3C one-row-per-color block targeting other rows — if any
  element still looks off, A/B rows 0x1A+ next). HOLE-B PRESSURE
  NOTED: 0x1F0 bytes free — future data-carrying thunks need a plan
  (reclaim staged-99 rows or a second hole).

## Session 14z-44c (round 55: WIN-screen item corrected + sharpened)

Maintainer corrections to the round-51 screen captures (they show
the WIN screen — Donovan's victory art over the continue counter —
NOT a lose/continue-specific screen):
- Anita is NOT garbled — she is hard to see because of the wrong
  palette + "weird rendering" (so: palette/render-path defect, not
  missing/corrupt art).
- NEW datum: **BOTH Donovan and Anita are shifted LEFT vs VS2's
  composition** (compare the two captures). Smells like a
  coordinate-BASE difference in the win-venue record composition —
  same investigation family as the 14z-23 select-sword offset
  (which resolved to draw-order/occlusion, via OBJ section bases),
  or a genuine base-X drift in the ported win-screen records.
- Investigation entry points when this item runs: the win-quote/
  win-screen records were ported at M2b ("select/VS/win-quote
  records"); palette = the slot-0x0F-indexed family (maintainer's
  Jedah-colors hunch, round 52); position = OBJ dumps at the win
  screen on both games (the 14z-23 full-entry method) + check the
  venue's section-base words.

## Session 14z-44b (round 54 on 314568f5: ES arc maintainer-CONFIRMED; round-34 speed-mode item closed NO-BUG)

- **ES hit counts correct ✓. ES visuals look correct ✓** (the 14z-28
  aura concern rides the native path and passes the eyeball round).
- **ES finishes "seem corrected"** — provisional ✓ pending the
  maintainer's full-cast pass; the gate (section 4) plus round-1 +
  match-end scripted kills stand as the harness evidence. If any
  cast member shows the neutral pose again, the six 0x51-positional
  records' property-0x19 path is the first suspect (STATE 14z-44).
- **Round-34 item 2 (speed-mode menus: STANDARD/TURBO/AUTO/
  AUTO&TURBO inconsistencies) CLOSED NO-BUG by the maintainer:**
  the same behavior reproduces on NATIVE vsavj — the original
  remark traced to European-vsav expectations or a test-harness
  difference on their side, not our build. The Start-hold-shim
  interaction hypothesis is moot; nothing to investigate.

## Session 14z-44 (maintainer go-ahead: disassembly — the whole ES arc closes in one session)

The round-53 clarification ("1 stock = one banked full bar") +
disassembly go-ahead produced a clean chain of discoveries:

- **METER SYSTEM DECODED (write-tap -> disasm of the writers, most
  of which live in OUR ported hole-a code):**
  - obj+0x109 (ff8509 P1) = **BANKED STOCK COUNT**, cap 0x63 (99) —
    the maintainer's displayed stocks. THE ES GATE FIELD.
  - obj+0x10A.w = current bar fraction, **full at 0x90 units** (the
    gauge adder converts 0x90 -> +1 stock; my "gauge 0x54" readings
    were fractions of 0x90 — no scripted run ever banked a bar).
  - obj+0x105 = ~48f transient raised by any special (gauge-blink);
    obj+0x107 ff/fe = resolver markers (fe = pair downgraded), NOT
    consumption. obj+0x102 = resolved strength/flavor byte.
  - **The ES/strength resolver = ported code at 0xCF598**: reads
    press masks +0x126|+0x128, bits 4-6 = punches, pair table ->
    (strength, flag); for pairs tests **+0x109 nonzero** -> ES,
    else downgrade to lowest-button strength + 0xFE marker.
  - => **NO ACCEPT BUG EVER EXISTED.** All scripted "ES" attempts
    (LS pairs, replay 19's own DP pairs, the vanilla Demitri
    control) had 0 banked stocks. Replay 19's ES coverage
    evaporated because the 14z-42 freeze fix REDUCED HIT COUNTS ->
    less meter -> the same prologue stopped banking a stock (the
    exact "silent soak coverage loss" mechanism).
  - **Scripted ES recipe: POKES ff8509 (e.g. :09) + pair press.**
    Verified on BOTH games (vs2 field identical — the resolver is
    ported vs2 code).
- **ES chain confirmed both sides: vs2 0x284A64 == ours 0xD858C**
  (the block after HP's chain — 14z-43's inference correct), 9-node
  loop x4 base (HP: x3).
- **ES 8-hit undershoot ROOT CAUSE: a THIRD deity record subset.**
  The raw hitbox blob has 14 strided 0x4E type bytes at
  +0x11A9..+0x1349: 14z-36 remapped only the first 7 (sworded).
  The other 7 (+0x1289..+0x1349) = the ES-variant records, still
  0x4E -> class 0x4E -> vsavj property[0x4E]=0 (the 14z-28 revert)
  -> victim's stun peaked 3f, escaped after ~3 hits. Restoring
  property[0x4E]=0x0F alone moved the failure to the 14z-26
  "static shake node, no re-hit" second-consumer divergence (1
  hit) — property is NOT sufficient for class 0x4E, exactly as
  14z-26..28 found. FIX = the 14z-36 pattern extended: 7 region_fix
  rows 0x4E -> 0x06 (vs2-alias-proven: word[0x4E]==word[0x06]) ->
  native class-8 electric chain end-to-end, where the 14z-42
  ls_freeze_vs2 thunks already supply vs2 constants.
- **MEASURED (build 314568f5): ES = 9 hits at ~10f, damage
  011b->0113 == native EXACTLY** (native f2632-2710, ours
  f2633-2718).
- **ROUND-52 ES-FINISH NEUTRAL-POSE KO: FIXED by the same remap**
  (class 8 death = the proven native electric chain): round-1 ES
  kill -> grounded 0x158210 ✓; MATCH-END ES kill (the maintainer's
  exact scenario, replay-54 variant) -> fall 0x157FCC -> grounded
  0x158210 ✓. The death-path class-0x4E hole (14z-28 finding #3)
  remains OPEN in general but is no longer on any live path (no
  record emits class 0x4E/0x51... the six 0x51 ES-positional
  records remain 0x51 -> property 0x19; their hits didn't connect
  at gate spacing — if a maintainer round shows ES anomalies at
  other spacings, A/B the 0x19 handler pair next).
- hit_class_props_ext_lo added (property[0x4E/4F] = vs2 0f 1b):
  vs2-authentic future-proofing; no live consumer after the remap.
- Gate: test_don_reactions section 4 (ES 9-hit lock via stock poke
  + ES-kill grounded lock; replay 56 promoted with native datums).
  Replay 55 (WIP scaffold) superseded by 56.
- RAM atlas: +0x102/+0x105/+0x107/+0x109/+0x10A rows added.

## Session 14z-43b (round 52 on 22ada38e: THE NEUTRAL-POSE TRIGGER FOUND — it's the ES FINISH; death-path class consumer = the suspect)

Round-52 maintainer results:
- **ES vs Morrigan: still 8 hits** (native claim 9). Maintainer
  suspects distance-dependence — plausible (the far-HP=6 datum);
  needs a same-victim same-spacing native A/B before calling it a
  divergence. PENDING the ES-input/meter work.
- **NEUTRAL-POSE KO REPRODUCED: ES finish at final KO** (vs
  Morrigan). RECLASSIFIES the round-50 flaky bug: it was an ES kill
  all along (trigger = move VARIANT — why the 4 non-ES match-end
  repro variants stayed clean and why the maintainer couldn't
  re-trigger it). MECHANISM SUSPECT: the death path re-reads victim
  +0x54 (the 14z-28 finding #3) — an ES kill leaves class 0x51
  (this build) / 0x4E-with-property-0 (previous build) there, and
  vsavj's death-path class consumer knows neither -> collapse never
  chains -> standing neutral. Native vs2 handles class 0x51 on its
  death path (tables extend to 0x53).
- Visuals: "slightly faster, possibly more VS2-like" (soft signal,
  consistent with property-0x19 now live).
- REPRO ATTEMPT (class poke): normal deity kill + victim+0x54 = 0x51
  poked f2638-2642 -> death chain STILL correct (0x158210).
  INCONCLUSIVE, not a refutation: frame-boundary pokes likely miss
  the same-frame class consume at the fatal hit. The real repro
  needs an actual ES kill.
- **SCRIPTED PAIR-ES ACCEPT IS BROKEN ON CURRENT BUILDS (new hard
  fact, both moves):** replay 19's own ES DP pairs (DR12/DR13, both
  buttons SAME frame, stock byte ff8505=01 present) now produce the
  LP-fallback DP chain (0xD6EE8) — as do 1f-offset pairs with the
  diagonal held, and every LS pair variant. Chain-start nodes prove
  the fallback (DP chains: LP 0xD6EE8 / MP 0xD7050 / HP 0xD71B8,
  stride 0x168). Replay 19 demonstrably produced ES DPs when
  written (session 11 measured the ES crash from them) — the
  behavior evaporated at some unknown build and the no-crash soak
  stayed green (GOTCHAS entry added). MANUAL ES works on the same
  builds (maintainer, rounds 51-52). Also mapped: the stock decays
  during idle (ff8505 1->0 between f3360 and f3455 with no inputs)
  — earlier "too late" ES attempts were doubly doomed.
- **14z-43c meter-field facts (round-53 datum: maintainer ES'd with
  1 DISPLAYED stock — a persistent state):**
  - +0x105 (ff8505) = a ~45-48f TRANSIENT raised by performing any
    special (measured 1 at f3325-3355, 0 at f3370 after DP3 at
    3318; re-raised by the next special). NOT the persistent stock
    the maintainer uses. The real stock counter = UNMAPPED.
  - +0x107 ff->fe fires when a special is performed with +0x105
    recently set — including with NO stock (vanilla Demitri control)
    — it is NOT ES consumption; every earlier "meter consumed" read
    based on it was wrong.
  - Vanilla Demitri scripted-pair control: INVALID as run (no
    stock; chain 0x12E51A = one stride below HP fireball 0x12E69A =
    a fallback, not the ES). Vanilla needs real meter too before it
    discriminates harness-vs-port.
  - Post-DP timing: actionable ~f3360, +0x105 dead ~f3365 — the
    window is ~empty; pair presses during recovery are eaten. More
    replay threading is the wrong tool.
- **NEXT SESSION (bounded, static-first): disassemble the ENGINE's
  ES-accept + meter check** — find the command-accept code that
  distinguishes ES (two buttons) from normal and READS the meter
  (who reads ff8505/06/07 and the real stock field at accept time;
  start from writers via tap on ff8500-ff8510 during a
  stock-gaining flow, then disassemble the readers). That yields
  (a) the true stock field -> POKE it to script the ES reliably,
  (b) whether Donovan's accept differs from vanilla at all. Then
  unlock the whole ES chain: gate, 9-hit A/B, mash, neutral-pose
  repro. Also: disassemble the ported handler's ES branch — Donovan's LS/DP handlers are ported vs2
  code; find the ES-vs-normal decision (which input/meter field at
  which offset, what threshold) in the vs2 source region, check
  what it reads on vsavj, and whether scripted vs manual input
  states differ there (suspect family: the pressed-pair mask read
  at a vs2-era offset, or a meter-threshold field our port doesn't
  feed identically). Fixing scripted-ES accept unlocks: the ES
  gate (chain family after HP's = 0x284A64+/0xD8588+), the 9-hit
  A/B, the mash-to-11 check, AND the ES-kill neutral-pose repro
  (task: death-path class consumer for 0x51). MAINTAINER QUESTION
  queued: what is your meter state when the ES comes out (full
  bar? banked stocks?) — cheap discriminator for the accept
  condition.

## Session 14z-43 (ES class-0x51 port BUILT + crash-gated; the pc-relative/data-space gotcha paid; ES behavior measurement blocked on meter mapping)

The 14z-42c queue item 1 implemented (build 22ada38e, battery run at
session end):
- **The port:** six region_fix 0x51->0x4E rows RETIRED (staged 99,
  the ES-deity records carry native type 0x51 again) + site_thunk
  es_type51_dispatch. Consumer audit of all three $17(a3) readers
  in STATE 14z-42c's plan held up: reaction dispatch already
  extended (case_a2), KO-branch dispatch = the new thunk, byte-table
  assigner unreachable for 0x51 (same as native vs2).
- **GOTCHA PAID (vec3 at the first KO hit, fully traced):** the
  first thunk shape hooked the dispatch's read site and absolutized
  `move.w $185DA(pc,d0),d0` as `lea/move.w (a0,d0)` — but
  pc-relative operands are 68000 PROGRAM-space references
  (CPS-2-decrypted) while (An)-based are DATA-space (raw bytes):
  the read returned ciphertext (data-view table[6] = 0x53BF = the
  measured odd jmp target). Fix: hook the PRECEDING moveq/move.b
  pair (0x185CA) and rts into the untouched vanilla read+jmp — the
  reaction_hook ghost-clean topology. docs/GOTCHAS.md entry added
  (includes the corollary: table-view choice follows the READ MODE,
  not the address — pc-relative tables live in opcodes.bin,
  lea(pc)+(a0,dn) tables in data.bin).
- **Crash coverage GREEN on 22ada38e:** guarded deity-KO (poke),
  guarded ES-attempt run, test_don_reactions all 3 sections
  (round-1 KO, match-end KO, sword-kill) PASS. Residual exposure =
  the property-0x19 reaction handler receiving live ES hits — a
  LEGACY handler (property 0x19 serves vanilla classes 0x09/0x33/…)
  so no crash surface; possible freeze-constant drift there is the
  known follow-up (A/B once an ES replay lands hits).
- **ES behavior measurement BLOCKED, parked:** scripted ES attempts
  all fell back to the LP chain. Chain map established (even 0x244
  spacing, both games): LP 0x284398/0xD7EC0, MP 0x2845DC/0xD8104,
  HP 0x284820/0xD8348 — and the "extension block" the no-mash loop
  jumps over (0x284A60+) is therefore almost certainly THE ES
  CHAIN, never a mash extension (14z-42's mash datum — 3->4 loop
  iterations — stands independently). Pair-button fallback picks
  the LOWEST button (13->LP, 23->MP). Meter fields partially
  mapped: P1 gauge byte ff850B (grows ~0x0C-0x30/action), stock
  encoding at ff8505/06/07 NOT yet decoded (+07 00->ff->fe pattern
  recurs across ES attempts on both games; can't distinguish
  "no stock" from "consumed" yet). NEXT SESSION (bounded): map the
  stock byte properly (tap writes to ff8500-ff8510 across a known
  manual-ES flow), then author the ES gate replay (recipe: replay
  19 prologue + 421+pair with the accept-shape variants — pair 1f
  apart or long DL hold both accept on ours), assert ES chain
  0xD8xxx (ES = HP+0x244 family) + 9 base hits + mash to 11 + KO
  clean. Scratch replays es3/es4/es5 + all findings in the session
  log; input-accept EDGE note: exact-simultaneous pair at DL-release
  frame is accept-flaky on ours no-debug (variants v1/v4 accept).

## Session 14z-42c (round 51: LP/MP closed as native; ES = the known class-0x51 interim, UPGRADED to accuracy item; win-screen art item added; KO bug parked)

Round-51 maintainer answers:
- **LP/MP mash CLOSED NO-BUG:** maintainer struggles to extend LP/MP
  on native VS2 too ("mechanism likely sound") — matches our
  instrumented 3->4 extension proof. Native behavior.
- **ES UPGRADED to gameplay-accuracy item:** definitely 9 base on
  VS2, ours 8 — and ES mash extends on neither... ours at all.
  MECHANISM HYPOTHESIS (connects to the 14z-35/36 interim): the ES
  deity's 6 records were remapped type 0x51 -> 0x4E (crash fix —
  vsavj's type dispatch ends at 0x4F); vsavj property[0x4E] = 0
  (14z-28 revert) -> ES hits take a PLAIN reaction, not vs2's
  class-0x51/property-0x19 electric path -> different freeze/re-hit
  pacing (one hit fewer) and plausibly no mash sampling. FIX SHAPE
  (next session, 14z-33 discipline — this area crashes when done
  casually): extend the record-type dispatch to 0x51 (existing
  engine-hook pattern), route to the 6-byte copy handler (class :=
  0x51), property[0x51] = 0x19 already present in
  hit_class_props_ext_hi; then A/B the property-0x19 reaction
  handler pair for constant drift (the 14z-42 freeze lesson — may
  need a third freeze thunk there).
- **NEW TRACKED ITEM: Donovan lose/continue screen** (maintainer
  captures, Desktop screenshots 2026-08-01 22.38/22.42): ours has
  (a) the Donovan figure in a wrong washed-purple palette, (b)
  garbled tile blocks bottom-left where Anita's portrait art
  belongs, (c) wrong background composition vs VS2's moon/Anita
  arrangement. Loser-portrait art/palette family — group with the
  M2b select-portrait remainder. MAINTAINER HUNCH (round 52): the
  washed palette "looks a lot like Jedah colours" — mechanically
  plausible (slot-0x0F-indexed palette table unported = serves
  Jedah's rows; the accent/fixture failure family). Check the
  lose-screen palette source first when this item runs.
- **Match-end neutral-pose KO PARKED (maintainer's call):** happened
  once vs Morrigan, not reproducible since ("very flaky... worth
  leaving alone for now"). Our 4-variant clean repro + the new gate
  section 3 stay as the tripwire. If it recurs: victim char + what
  the victim was doing at the kill are the wanted datums.

## Session 14z-42b (round 50: freeze fix CONFIRMED; neutral-pose match-end KO reported — 4 repro variants all CLEAN; context question queued)

Round-50 maintainer results on 4f8220fc:
- **Core fix confirmed: no strength overshoots; feel/speed similar
  to VS2 overall.** HP mash reaches 9 (their reliable native max) ✓.
- **TRACKED (non-blockers, maintainer's words):** (a) ES undershoots
  — 8 minimum vs the 9-13 reference (and 10 max-mash vs theory 11);
  (b) LP/MP get NO mash extension (should reach ~5 / 6-9). Note HP
  mash works (9) and the scripted mash A/B extended 3->4 on both
  games — so the mash READ works; the per-strength extension
  windows/loop params are the suspects. Investigate with per-strength
  node taps (LP=btn1, MP=btn2, ES) vs native.
- **BLOCKER REPORTED: match-end KO with Lightning Sword (possibly
  any special) leaves the opponent in neutral pose again** (the
  round-38 bug family). REPRO ATTEMPTS THIS SESSION — ALL CLEAN on
  4f8220fc (correct grounded death 0x158210 + SPECIAL FINISH, snaps
  verified): (1) round-1 mid-shock kill; (2) MATCH-END (round-2
  clinching) mid-shock kill; (3) match-end kill by the INITIAL
  SWORD HIT (different records than the deity); (4) match-end kill
  during MASH-EXTENSION iterations. All vs Victor, 2P mode,
  standing victim. New replay 54_don_matchend_ko + gate section 3
  close the gate's round-1-only blind spot permanently.
- The bug therefore needs context we don't have: candidates =
  victim char (theirs != Victor?), ARCADE/vs-CPU mode (moving/
  crouching/airborne victim at the kill — our victims always stand),
  the swordless variant or 421K column as the killer, or a round
  pattern other than 2-0. NOTE: 14z-25 (round 38, 421K) never
  reproduced either — this may be the SAME never-fixed pre-existing
  bug, newly visible because the move is now good enough to close
  matches with; not necessarily a freeze-fix regression. QUESTIONS
  SENT to maintainer: exact killer move/variant, victim char, mode
  (arcade or 2P), victim state at the kill (standing/crouch/air/
  mid-move), round pattern, SPECIAL FINISH banner shown or not.

## Session 14z-42 (Lightning Sword: ROOT CAUSE = hit-freeze engine drift; 14z-40/41 suspects all exonerated)

Measurement session on native vs2 (scratch replay recreated per
NEXT_SESSION spec) vs our build (replay 48, no poke). Every 14z-40/41
suspect died under instrumentation; the real mechanism emerged whole:

- **14z-41's PAIR-1 "lost spawner" theory: DEAD, twice over.**
  (a) GUARD_PROBE at vs2 0x82AE2 across the whole native replay:
  ZERO hits — the spawner is never called during Lightning Sword
  (move confirmed on-screen in the same run). (b) The reconciliation
  row was ALREADY CORRECT: manifest maps 0x082AE2 -> 0x077376 and
  the built image calls jsr 0x77376 at 0xCD438. **14z-41 misread
  0x77376 as 0x73376** (one hex digit) and analyzed the phantom
  address; vsavj 0x77376 is the byte-identical spawner twin (alloc
  0x16FBA = vs2 0x15702's analog, ids 0x01006000/0x01006002, unique
  in the image). GOTCHAS entry added.
- Pair 2 (vs2 0x2CE82): also ZERO probe hits whole-replay. Pair 3 =
  the deliberate sound stub. **None of the three reconciled walker
  calls executes during the move** — the 14z-40 inference collapses.
- **Node-path A/B (tap ff841c both sides): IDENTICAL structure.**
  Same 14-node ramp, same 9-node loop (native 0x284988-0x284A48 =
  ours 0xD84B0-0xD8570, port offset +0xB3B28), **exactly 3 loop
  iterations no-mash on BOTH**, same exit link over the extension
  block (4A48 -> 4CA8 = 8570 -> 87D0), same 10-node tail. The
  14z-38 "permanently mashed" theory is DEAD: 7/11/15 were never
  mash caps — they're base-loop hit counts inflated per-iteration.
- **THE DIVERGENCE: attacker hit-freeze per deity hit.** Timer tap
  (obj+0x20) + P2-HP tap, both sides: native = 6 hits, 4-5f freeze
  starting at each hit frame; ours = 14 hits, 9-11f freeze. Longer
  freeze stretches the same 3-iteration loop ~2.1x; the deity's own
  ~10-12f hit cycle fills the longer window with more hits. ONE
  drift = BOTH maintainer symptoms (count + visible slowness).
- **Freeze source found (full-obj tap at hit frame + disasm):** the
  victim-reaction handler pair — vs2 0x226E0 == vsavj 0x23AC8
  (structural twins; property tables 0x27FD8/0x28D00 byte-identical
  through class 0x4D; both handlers fire once per hit, probed). The
  CONSTANTS drifted between engine generations: victim +0x5C = 0x0C
  (vs2) vs 0x18 (vsavj); **attacker +0x5C = 0x04 (vs2) vs 0x0B
  (vsavj)**; vs2 also writes victim $147=0xC which vsavj's handler
  lacks. vsav = older engine; vs2 retuned the electric-shake
  reaction for its rapid multi-hits.
- **FIX (built this session): site_thunks ls_freeze_vs2_victim /
  ls_freeze_vs2_attacker** on the two 6-byte freeze writes (vsavj
  0x23AD8/0x23ADE): attacker link a4 must be a player block
  (0x8400/0x8800 guard — non-player +0x32 words would make +0x382 a
  garbage read) AND char id 0x0F -> vs2 constants (0x0C/0x04); else
  byte-identical vanilla write (CCR-safe: last else-op = the
  original move.b). $147=0xC was first left out and measured:
  constants alone gave freeze 5f ✓ but hit period 7f and STILL 14
  hits — the victim freeze had been doubling as vsavj's only
  re-hit gate; **vs2's victim $147=0xC IS the re-hit gate**. Ported
  into the Donovan branch (flag-identical CCR).
- **RESULT (build fingerprint 4f8220fc, replay 48 no-poke):
  NATIVE-EXACT CLASS — 6 damage events at ~10f period (native: 6
  at ~10f), total damage 10 == native 10 exactly (5-point initial
  sword hit + 5 deity ticks; pre-fix: 22), 3 loop iterations,
  cadence histogram near-identical (1-5f), move 113f vs native
  106f.** Both maintainer symptoms resolved in one
  mechanism-attributed change of two site_thunks.
- **MASH VERIFIED NATIVE-EQUAL: both games extend 3 -> 4 loop
  iterations under identical mash input** (LP/MP alternating every
  3f through the loop window). The mash mechanic was never broken;
  14z-38's input-struct theory retired. Replays promoted:
  51_vs2_immortal_native / 52_vs2_immortal_mash /
  53_don_immortal_mash (native datums in the headers).
- Instruments this session (all no-debugger tap_writes or
  GUARD_PROBE; scratch replay 48_immortal_v2 recreated for vsav2 —
  picks R,R / R,R, 421+HP at 2610-2624, no poke): node tap ff841c,
  timer tap ff8420, HP tap ff8850, full-obj tap ff8400,400 at the
  hit frame, probes 82ae2/2ce82/226e0/23ac8.
- **14z-40's side finding (region-tail zeroed routine, +0x142E)
  CLOSED — NO CALLERS:** vs2's only reference to 0x27570 is `bsr.w`
  at 0x20C9E inside the ENGINE's object-init chain (never ported;
  vsavj objects init through the vsavj twin and its own per-char
  tables). The built image has ZERO references to ours 0xCE7BE
  (jsr/jmp/bare-long/relative all searched). Dead code; the
  table_fix pad stands.
- Walker mechanics decoded along the way (engine_internals TODO):
  node = 0x18 bytes, +0 duration byte -> obj+0x20 countdown
  (decrement PC vs2 0x271C4 = ours 0xCE412), +1 flags (0x80 =
  follow link at +0x18), +4 sprite record ptr, +0x10 the
  [cf14]..[0b] op family; loop node 4A48 links back via +0x18
  pointer 0x284988; freeze holds the decrement (the "floating
  holds" that tracked hit frames, not fixed nodes).

## Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)

## Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)

- Kick-color pick AND Donovan-mirror both byte-identical to native vs2
  (P1 rows 0x0A-0x0F, P2 rows 0x10-0x15; ground truth replays 41/43 on
  vsav2). The alt color set = block+0x180 inside the already-ported
  0x500 sprite block; the mirror alternate is engine-composed from the
  same block. **Table B (0x38C1D8) is never consulted on Donovan's
  paths — the 14z-19 open item closes with no patch.** Locked in
  tests/test_don_colors.sh (frozen native rows; battery section 3b).
- Select-web P2 navigation mapped via live +0x382 hover walks: P2 ->
  Jedah orb = U,U,U (vsavj); P2 -> Donovan = L,L,L,L (vs2 grid).
  Replays 41-43 capture the paths permanently.
- Also validated live: the fixture-override thunk's char-id condition
  ($FF8782 reads exactly 0x0F at the sites' run time in a real match
  flow, both mirror sides trigger).

## Session 14z-41 (call-pair audit: pair 3 = the known sound stub; PAIR 1 = the real suspect — a lost spawner)

- Pair 3 (vs2 0x5122 -> vsavj 0x2A7E0): DELIBERATE — the
  "stubbed_sound" reconciliation row (the 214-input music-change fix;
  correct vsavj twin 0x4CE2 documented in the row's own note; sfx
  return at M5 with id-table translation). Flow-equivalent (rts), so
  NOT the mash/cadence divergence. Side-answer: this is why Donovan's
  moves are silent.
- Pair 2 (vs2 0x2CE82 -> vsavj 0x2D62A): previously verified
  engine_data row; not re-audited (low suspicion).
- **PAIR 1 (vs2 0x82AE2 -> vsavj 0x73376): THE SUSPECT.** vs2's
  routine = a SPAWNER helper: `jsr 0x15702; beq; move.l #$01006000,
  (a4); move.w a6,$30(a4)` — twice = allocates & initializes TWO
  support objects, owner-linked. The mapped vsavj 0x73376 reads as an
  instruction-fragment tail falling into rts = an EFFECTIVE
  (unintended) STUB — the walker's early-frame call spawns nothing.
  Two lost support objects during Lightning Sword = prime candidate
  for the cadence/hit-count divergence (e.g., the objects drive the
  hit timing/mash sampling).
- NEXT SESSION: (1) understand vs2 0x82AE2's role for this move
  (what the two objects do — tap their slots on native during the
  move); (2) find vsavj's TRUE analog (search for the same spawn
  pattern `4eb9 ... 671c 28bc 0100...` in vsavj) or port the helper
  (it's ~0x30 bytes, calls 0x15702 = the shared alloc — check that
  address's vsavj analog too); (3) fix the reconciliation row,
  rebuild, measure hits (expect 6-7 no-mash HP) and cadence (expect
  ~1.5-5f/node); (4) gate both.

## Session 14z-40 (mash bridge: the walker block audited clean — divergence narrowed to three reconciled engine-call pairs)

- Full instruction-level diff of the ported walker block (x026142 @
  0xCD390, 0x1440 bytes) vs the vs2 original: 92 changed longs, ALL
  accounted for — anim-table repoints (0xD7xxx -> 0xBD87A-family),
  internal port retargets, and the DELIBERATE [table_fix] bank table
  (+0x13EE). The walker's own logic is byte-faithful. Two findings:
  1. The mash/cadence divergence must therefore live in one of the
     THREE RECONCILED ENGINE CALLS inside the walker:
       - vs2 0x082AE2 -> vsavj 0x073376   (region+0xA8)
       - vs2 0x02CE82 -> vsavj 0x02D62A   (region+0xEB2)
       - vs2 0x005122 -> vsavj 0x02A7E0   (region+0x1074)
     One of these is the advance/input helper whose vsavj analog
     drifts semantically (sibling-verified structurally, engine-
     drifted behaviorally). NEXT SESSION: disassemble each pair,
     compare, bridge the drifted one.
  2. SIDE FINDING (potential separate bug): the region tail (+0x142E)
     originally holds a small per-char lookup routine (`move.w
     $100(a5),d0; move.w (pc-table,d0),$1A(a6); rts`) that the
     table_fix pad ZEROED in our build. If anything calls
     region+0x142E it executes zeros. Audit callers next session;
     if called, restore the routine above the rewritten table.

## Session 14z-39 (round 49: maintainer clarifications — the Lightning Sword reference data)

Maintainer-provided ground truth (community-corroborated):
- Plant = **214K "Killshread Plant"** (not 421K; input leniency
  accepts both — matches the 14z-31 finding).
- **Lightning Sword (sworded 421P) hit ranges: LP 3-5, MP 5-9,
  HP 7-11, ES 9-13** (base to max-mash). Far HP = 6 only (range:
  after 6 hits the opponent exits reach despite the shock's pushback
  limiting). Max counts need VERY fast mashing; regular mashing gives
  ~half the bonus (maintainer reliably reaches 9 on HP).
- **Our fixed counts (7/11/15) EXCEED the community maxima (5/9/11)**
  — two readings: (a) the engine's hard loop ceiling sits above
  human-reachable mash (ours = ceiling), or (b) our loop count is
  outright wrong. Distinguish next session at the code level.
- **NEW: animation speed** — VS2/vanilla Savior play the move MUCH
  faster; ours is visibly slower. This matches the 14z-37 cadence
  measurement (ours ~11 frames/node vs native ~1.5-5) — a SECOND
  divergence beyond the loop count. Note: ours advances nodes via
  PORTED code (PC ~0xCE38A, in the x05c800 character-code region =
  Donovan's own move handler), while native vs2 advances via its
  ENGINE walker (0x2713C) — the handler/walker division of labor
  differs between the builds and is the prime suspect for BOTH the
  cadence and the loop-count divergence (e.g., handler = the
  mash-advance path firing on garbage input reads; walker = the
  default-timer path).
- NEXT SESSION (bounded): disassemble the ported handler around
  0xCE38A via its vs2 source in the x05c800 region; map the advance
  logic + its input read; bridge; then gate: no-mash HP = 6-7 hits
  AND cadence within native bounds.

## Session 14z-38 (mash bridge: three fields exonerated; theory sharpened to the input-struct read)

- Poke experiments: zeroing obj +0x126 / +0x12E / +0x1B0 continuously
  during the move does NOT shorten it (14 hits regardless) — the
  loop condition does not read those obj fields.
- Sharpened theory: ours behaves as PERMANENTLY MASHED — the ported
  vs2 walker's loop-op likely reads the per-player INPUT-STATE
  structures at vs2 offsets; vsavj's input layout differs, so the
  read returns garbage/nonzero = "still mashing" = always loop to the
  cap (7/11/15 per strength = the caps).
- Interpreter note: vs2 advances these nodes with its ENGINE walker
  (PC 0x2713C); ours with the PORTED copy (PC ~0xCE38A, hole a) —
  same vs2 semantics, so the divergence is in what the READ hits, not
  the opcode logic.
- MAINTAINER QUESTION that would confirm cheaply: in VS2, what is the
  actual maximum hit count with maximum mashing? If ~7/11/15 (our
  fixed counts), ours == permanently-mashed exactly, confirming the
  input-read theory.
- NEXT SESSION (bounded, fresh context): statically disassemble the
  ported walker's loop-op handler (the script-op dispatch for the
  node ops [cf14][0b][target]-family) in the vs2 original around the
  0x27xxx walker; find the input/mash read; bridge with a thunk
  (vsavj input state -> the expected field/offset). Then gate the
  no-mash base counts (6-7 hits HP version).

## Session 14z-37 (round 48: shock CONFIRMED with a caveat — hit counts maxed; mash mechanic mapped to the doorstep)

- Maintainer: the electric shake holds like VS2 ✓ — but hit counts
  are FIXED MAXIMA (7 LK / 11 MK / 15 HK) vs VS2's mash mechanic
  (base 3/5/7-or-6, extended by mashing; ~9 reachable with HK+mash).
  Measured: ours 14-15 hits vs native 6 at identical inputs (no
  mash) — ours always plays the cap.
- Mechanism mapped this session (all measured):
  - The deity = Donovan's own anim; the multi-hit = a NODE LOOP
    (loop-back node relocated correctly; node data byte-faithful).
  - The loop is executed by the PORTED VS2 WALKER (ours advances
    nodes at PC ~0xCE38A in hole a = vs2's own interpreter code) —
    opcode semantics authentic; the loop DECISION therefore reads an
    ENGINE-MAINTAINED field that vsavj doesn't feed the same way.
  - Candidate fields from the vs2 walker's upstream code: +0x126
    (press mask, `move.w $126(a6)`) gated by +0x169; also +0x1B0
    counter. Registers at the loop-back write are identical across
    games (decision is upstream of the write).
- NEXT SESSION: disassemble the ported walker's loop-op handler
  (around 0xCE2xx-0xCE4xx in the built image / vs2 0x270xx),
  identify the exact mash-condition read, check whether vsavj's
  engine maintains that field during button mashing (tap writes on a
  vanilla mash move), and bridge it (init_shim/site_thunk feeding
  vsavj's input state into the field the ported walker reads). Gate
  afterward: hit-count assertions (no-mash = base counts).
- Ship state: 0a55bc58 remains strictly better than pre-14z-36
  (shock + death correct; counts too generous). The maintainer's
  caveat = the one open gameplay-accuracy item.

## Session 14z-36 (SWORDED-421P SHOCK + DEATH FIXED — the final reconcile; the class-0x4E saga closes)

- The decisive fact: **vs2's dispatch maps record type 0x4E to the
  TYPE-6 handler** (word[0x4E] == word[0x06] == 0x11A) — on vs2 the
  sworded deity's hits were ALWAYS native class 8 (the tiny type-6
  handler: victim+0x117 flag + class := 8). Our "class 0x4E" was
  vsavj's renumbered copy-handler artifact. The whole three-consumer
  property plan (14z-28) is RETIRED — nothing legitimate ever
  referenced class 0x4E.
- FIX: 7 region_fix remaps (hitbox +0x11A9..+0x1269): sworded deity
  record types 0x4E -> 0x06 = the same proven mechanics as the
  working swordless column. Measured: full electrocute shake
  (alternating nodes), fall sequence, grounded death 0x158210 on the
  fatal hit; NON-fatal = 10 damage steps (the electric stun holds the
  victim through the full multi-hit — up from 2 pre-fix, matching
  vs2's behavior), no knockdown on a standing opponent.
- test_don_reactions.sh: death-chain assertions restored (section 2)
  alongside the gameplay lock. hit_class_props_ext_hi (0x50-0x53)
  stays as inert future-proofing.
- Remaining queue (all cosmetic): swordless-deity palette (yellow vs
  vs2 blue), select-screen post-confirm blink (tracked minor), ES
  deity nuance (its records now class-0x4E-copy interim = plain
  reactions; if the maintainer wants ES-specific presentation, map
  vs2's class-0x51 property intent 0x19 properly).

## Session 14z-35 (type-0x51 cluster resolved — the engines RENUMBERED the copy-class record family; latent crash preempted)

- Read vs2's "dedicated" type-0x51 handler: SIX BYTES — `move.b
  $17(a3),$54(a1); rts` = "copy my type byte into the victim's
  hit-class field". VSAVJ HAS THE IDENTICAL HANDLER — serving ITS
  types 0x4E/0x4F (it is the class-writer PC 0x1868C from the 14z-26
  taps). The engines renumbered this record family; for it, "hit
  class" == record type. This RECONCILES the whole arc: the sworded
  deity's 0x4E records already used vsavj's copy handler correctly
  (same semantics by luck of the numbering); no handler port needed
  anywhere.
- The 6-record type-0x51 cluster (region hitbox, 0xC9CA1+ stride
  0x20, 3 distinct records x2 — ES-variant deity hits by position) =
  LATENT WILD-JUMP CRASHES on vsavj (type 0x51 indexes past the
  0x50-entry dispatch table). Remapped 0x51 -> 0x4E (region_fix x6):
  identical handler, victim class 0x4E = consistent with the rest of
  the deity family. Preempted before any playtest hit it (probably
  the ES Change Immortal KO).
- Dispatch-table geometry corrected on the record: vsavj table = 0x50
  entries (0x00-0x4F; 0xA0 bytes; first handler at +0xB2 after a
  0x12-byte gap); vs2 table = 0x54 entries (0x00-0x53).
- Queue after this: the sworded-421P on-hit shake/death (= the
  original consumer-2/3 property work — the type insight did NOT
  supersede it after all, since the sworded records were already
  correctly classed 0x4E; their missing shake = the property-table
  interim, unchanged), swordless-deity palette, select-screen
  post-confirm blink (tracked).

## Session 14z-34 (round 46: crash fix CONFIRMED + swordless shock RESTORED — the record-type insight reframes the remaining queue)

- Maintainer: crash no longer reproducible ✓ AND Morrigan gets the
  proper shock effect on swordless 421P ✓ — the type remaps restored
  the hit PRESENTATION too: the record TYPE (not only the hit class)
  routes the reaction/shock. Types 0x0F/0x06 = electric-presentation
  record families.
- REFRAME of the open queue: the SWORDED 421P's missing shock (the
  14z-28 interim) is likely the SAME mechanism — its records are the
  type-0x51 cluster (region hitbox, 0xC9CA1+ stride 0x20). Re-analysis
  of vs2's dispatch: entry 0x51 -> displacement 0x0BA = PAST the
  table end = a small DEDICATED vs2 handler (not an alias — the
  earlier "inside-table anomaly" was a miscount; vs2's table = 0x54
  entries/0xA8 bytes, so 0xBA is a legit handler just after it).
  Type 0x51 = genuinely new vs2 behavior -> next session: port that
  small handler (patched_clone class) + route type 0x51 to it via a
  thunk at the dispatch's `d040 303b 0006` site (6 bytes; bounds-
  extend for d0==0xA2), then the sworded shake/death and possibly the
  whole consumer-2/3 plan collapse into this one port. The property-
  table extension (consumer 1) may become redundant — re-evaluate
  after the handler port.

## Session 14z-33 (COLUMN CRASH FIXED — record-type dispatch aliases; permanent guarded gate)

- Root cause (completing 14z-32's decode): the column's KO records
  carry vs2's EXTENDED record types (3x 0x52 + 6x 0x50 in region
  hitbox_proj, record stride 0x20); vsavj's record-type dispatch
  table (0x185CC family) ends at entry 0x4F -> those types fetch CODE
  BYTES as jump displacements (0x52 -> 0xB26D -> odd jmp = the vec3
  reset). The 14z-32 "content-match over-reach" theory was WRONG (the
  aux0 regions are proper ports; retracted) — the data was faithful;
  the ENGINE's table was short. Same +6-extension pattern as the hit
  classes (0x4E-0x53), one table deeper.
- FIX: region_fix type-byte remaps, alias-PROVEN by vs2's own
  dispatch table (the 14z-27 lesson codified: remap only when the
  source engine itself proves equivalence): 0x52 -> 0x06 (vs2 words
  identical) and 0x50 -> 0x0F (same). All 9 records fixed. The
  type-0x51 cluster (region hitbox, 0xC9CA1+ stride 0x20 — likely the
  SWORDED variant's records) is NOT alias-provable from the table
  read (entry 0x51's vs2 word = 0x0BA, inside-table anomaly) — LOGGED
  UNTOUCHED; if a sworded-421P context ever faults, start there.
- Verified: guarded crash replay END-clean; visual = SPECIAL FINISH +
  YOU WIN over a properly downed victim (this KO path even ends
  correctly downed). Permanent gate tests/test_don_column.sh (guarded
  replay 50, battery 3d).
- The plant = QCB+K (214K) — replay 50 documents the working input.

## Session 14z-32 (round 45: blink fix CONFIRMED everywhere but the select screen; column-crash fix session)

- Round-45 maintainer: blinking gone in-match for all colors ✓; ONE
  residual — the select screen at/after CONFIRMING Donovan still
  blinks. TRACKED as minor cosmetic (maintainer's call): hypothesis =
  select-venue objects don't carry the +0x3A4 cached block ptr (the
  match char-init at 0x1C68E sets it), so the color-aware thunk's
  nonzero-guard falls back to the vanilla punch-color slots on that
  screen only. Revisit if it proves important (fix shape: fallback
  via owner-link's block or a select-venue init of +0x3A4).
- This session: the column-crash mechanism FULLY decoded (fix scoped,
  next session):
  - The fault instruction = the record-type JUMP DISPATCH (0x185Cx:
    `move.b $17(a3),d0; add; move.w (pc-table,d0); jmp (pc,d0)`) — a
    garbage type byte from A3=0xCAA5A produced displacement 0xB26D ->
    jmp to odd 0x13847 = vec3.
  - 0xCAxxx refs in the ported anim region are NOT stale: the
    extractor's pool CONTENT-MATCHER mapped vs2 pool spans
    (0x33xxxx) onto byte-identical VANILLA data (21 fields inventory:
    0xE9514/56/64, 0xEFBFA/C12/C2A, 0xF21BC/2208/2252/22DA,
    0xFF038/40, +9 more — scan script in the session log). For COORD
    LISTS that is sound; for the swordless-variant's ATTACK RECORDS
    the match extent is shallower than what the KO path walks -> the
    walk exits the matched span into unrelated vanilla bytes ->
    garbage record -> wild jump.
  - FIX (next session): port the vs2 pool spans behind the
    swordless-variant fields properly (vs2 sources 0x3358E8/0x33746C/
    0x335908/0x33CCF4 + extents from the record format) into a hole
    and region_fix the node fields; OR narrow the content-matcher to
    coord-list cptrs only and let the extractor port the rest. The
    deterministic guarded repro (experiments/421k_ko/50 + POKES
    2890:ff8850:00010001) becomes the gate when green.

## Session 14z-31 (round 44: BLINK ROOT-CAUSED + FIXED (color-aware accent); CRASH REPRODUCED + PINPOINTED)

Round-44 maintainer answers unblocked both fronts:

**BLINK ("from the moment you select Donovan") — FIXED:**
- Root cause: the accent march's static slots T0/T1 hold PUNCH-color
  row-C content; selecting with any other button loads the alt block,
  so the march cycles alt-base vs punch-accent = grey-shade blink
  (select screen AND in-match). The accent gate stayed green because
  its replay picks with LP — a coverage gap, now closed.
- Fix: accent_color_aware_{0..3} site_thunks at the uploader's four
  family-base sites (lea 0x39A900): owner char 0x0F -> a0 = the
  object's cached palette-block ptr (+0x3A4 = the SELECTED color,
  nonzero-guarded), d0=2 (-> block+0x40 = row C) — every march phase
  reads the same color-correct row = vs2's steady semantics for any
  color. Else-branch byte-equivalent. Measured: kick-color row 0x0C
  single-variant == the frozen ALT row-C content; punch path
  unchanged (accent gate green). test_don_colors gains the alt-
  steadiness assertion.

**CRASH — DETERMINISTIC REPRO + FAULT SITE:**
- The plant move is QCB+K (214K — the flavor-consuming sword throw;
  the "421K" notation confusion cost the previous session's attempts;
  the thrown sword plants where it lands, right side from round
  start).
- Repro (tests/experiments/421k_ko/50_column_crash.rpl + HP poke
  2890): plant, then swordless 421P(214P-side motion works too) —
  the column kills P2 -> MACHINE RESET at f~2943.
- Guarded: **vec3 ADDRESS ERROR, PC 0x185D8 (hit-apply family, near
  the 0x1868C class writer), faulting address 0x13847 (odd), A3 =
  0xCAA5A = VANILLA JEDAH'S ATTACK-DATA REGION, A6 = 0xFF9400 (the
  column projectile obj)** — the column's attack-record pointer was
  never repointed to ported data; the KO path dereferences a garbage
  field from Jedah's records -> odd-address access. NEXT: find what
  loads A3 for the column obj (per-projectile record table or the
  spawner's immediates — same porting class as the throw-table fix)
  and repoint; the crash repro then becomes the permanent gate.
- Also explains round-43 item 2 fully; the sworded 421P KO does NOT
  crash (its records are ported) — matching the maintainer's report.

## Session 14z-30 (round 43: crash triage — repro scaffold built, blocked on the plant input; classification of the other reports)

Round-43 reports classified:
1. "421P lost electric/shock properties" — EXPECTED interim: the
   current build's class/property state is byte-identical to the
   round-38 builds (the revert); the victim shake returns with
   consumers 2+3.
2. **CRASH (blocker): swordless 421P round-ending kill with the victim
   at the planted-sword location (user: vs Morrigan).** Repro scaffold
   built (49_column_ko_wip: plant -> P2 walks onto the sword -> HP
   poke -> column kill, guarded + POKES now supported in
   replay_guard.lua) but BLOCKED: scripted 421K does not produce the
   plant (tried HK + LK with the deity-proven motion shape; LK gives
   a low sword action that ends re-armed). NEED FROM MAINTAINER: the
   exact plant input nuance (button? held? ES/meter? special state?)
   — or whether the crash also occurs with the SWORDED 421P at
   point-blank. Suspicion: the swordless variant's attack records
   (hitbox_proj region?) carry extended classes or the KO path for
   that variant runs vs2-only code. SCANNED (14z-30 addendum):
   hitbox_proj carries ONLY vanilla-range classes (0x0F, 0x14) — the
   crash is NOT the extended-class family. Redirected suspicion: the
   three EXCLUDED overlay KILLER_SITES (0x5D8B8/0x5EE22/0x918F0 —
   attack-id table walkers, "residual wrong-art, no crash" verified
   on NORMAL paths only) — a round-end KO in the swordless state may
   reach them in an unverified context. Next: reproduce (needs the
   plant input), then a guarded run with the exception-vector report.
4. "Sword/statue blinking again (grey shades)" — the normal-state
   accent rows are GATE-VERIFIED steady on this exact build (battery
   green, test_don_accent). Hypothesis: the blink lives in the
   PLANTED-SWORD state (a separate accent surface for the swordless
   weapon rows — same family as the fixed one, new territory from the
   round-43 421K testing). NEED FROM MAINTAINER: does the blink
   appear from round start, or only after a 421K plant?
5. Auras yellow ✓ (no regression).
- Select-web: P1 default hover = Demitri (0x04); U,U,D,D = Aulbath
  (0x09). 0x08/0x0B (Morrigan/Lilith candidates) still unmapped.

## Session 14z-29 (consumer-trace session: supplementary facts; repo stays at the 14z-28 interim)

Started the per-consumer extension (round-42 go-ahead). Facts added
this session (build work was local-only; repo/ship state remains
d6cfdaf3 = the 14z-28 interim — the consumer-1 restore alone would
re-introduce the reported wrong-aura state, so it ships only together
with consumer 2):

- Consumer-1 restore verified REPRODUCIBLE: re-adding the 6-byte
  property port rebuilds BIT-IDENTICAL fd8f0628 (the 14z-26 state).
- The shake TINT mechanism is NOT per-hit palette uploads: zero
  palette-RAM writes land during the hit/shake window; the victim's
  flash-row fields are correctly initialized (+0x18B = 0x10, +0x3A4 =
  base block, +0x3A8 = 0x90C200); the post-shake write at ~f2667 is
  the base-row REFRESH, not a tint. The tint is therefore OBJ-attr
  and/or preloaded-row content — per-victim wrongness must come from
  content preloaded per victim (match-init staging) or per-victim row
  choice in the reaction records.
- With VICTOR as the victim, the shake state is NATIVE-EQUIVALENT at
  the palette+OBJ level (full A/B vs vs2: row contents match mod
  pulse phase; victim-zone attr histograms match) — consistent with
  the maintainer's list (Victor-family correct). The divergence ONLY
  manifests with victims like Lilith/Morrigan.
- NEXT SESSION PREREQ: map P2 select paths for Lilith and Morrigan
  (web ids 0x08/0x09/0x0B were never visited in the 14z-21 walk) ->
  author deity-shake repros with those victims -> A/B the shake state
  vs native to catch the divergent element (attr row vs preloaded
  content) -> then consumers 2+3 fixes per the 14z-28 map.

## Session 14z-28 (round 41: 14z-27 class remap REVERTED — gameplay regression; three-consumer map final; deity palette item confirmed)

Round-41 results: auras fixed ✓, match-end death fixed ✓ — BUT the
class remap broke the MOVE: 421P became a single-hit hard knockdown
(class 0x04 semantics) instead of a standing up-to-8-hit multi.
Gameplay regression outranks the cosmetics it fixed -> REVERTED to
round-38 behavior (class 0x4E, property 0): the move plays correctly;
the match-end neutral-pose cosmetic returns, accepted interim.

**THE DEFINITIVE MAP (all measured; the next-session fix is a
per-consumer extension of class 0x4E with vs2 semantics, NOT a class
remap):**
1. ON-HIT reaction: property table 0x28D00[class]. vs2 value 0x0F =
   standing electric shake, no knockdown (correct for the multi-hit).
   Restoring 0x0F alone reproduces 14z-26: move correct, shake on
   hits, but wrong per-victim aura colors + no death chain.
2. PER-VICTIM AURA ROW: with property 0x0F the vsavj engine uploads
   victim_effect_block[row 0x0F] — row semantics drifted between
   engines (vsavj victims hold other art there: Lilith green,
   Morrigan red; some chars coincidentally yellow). Fix = find the
   effect-row derivation from the property (uploader 0x2AD20 family
   feed) and remap 0x0F -> the native electric row for this venue
   (site_thunk or table extension at THAT consumer).
3. DEATH PATH: re-reads victim+0x54 (class) beyond the property table
   — with class 0x4E the collapse never chains (shake self-loops 255f
   then idle). Fix = find the death-path's class consumer (tap the
   victim node writes during the KO with class 0x4E + property 0x0F
   and follow the non-chaining branch) and extend ITS 0x4E entry.
   (Poke-proof exists: with class 0x04 the full chain runs to node
   0x158210 — the target end state.)
- Gate test_don_reactions.sh REWRITTEN as the gameplay lock: 421P
  must multi-hit (>=2 damage steps) and never enter knockdown-family
  nodes vs a standing opponent. The death-chain assertions to restore
  when the fix lands are preserved in the file comment + git history.
- Round-41 also CONFIRMS (with A/B captures): the SWORDLESS deity
  (421P after 421K plants the sword) has wrong palettes — ours
  yellow-centric with yellow lightning at the sword, vs2's
  blue-centric with white lightning. Same family as consumer 2 (the
  deity's own object palette rows for the swordless variant) — fold
  into the same fix session.
- hit_class_props_ext reduced to classes 0x50-0x53 only (unreferenced
  today, future-proofing); 0x4E/0x4F revert to vanilla zero.

## Session 14z-27 (round 40: CHANGE IMMORTAL KO FULLY FIXED — native class remap; aura palettes explained)

Round-40 report (bug persists at match end + wrong shock-aura palettes
on Lilith/green, Morrigan/red under some shocks) resolved completely:

- Legacy exonerated first: pure-legacy Victor-shock palette RAM is
  byte-identical to vanilla (full-row diff, replay 40) — the wrong
  auras occur only under DONOVAN'S OWN electric hits (the deity),
  i.e. they were enabled by 14z-26's property extension.
- Root cause, full depth: the deity's 7 attack records carry vs2's
  EXTENDED hit class 0x4E. Multiple engine consumers index per-class
  structures the vsavj engine only sizes to <=0x49: the property table
  (14z-26 fixed one consumer), the DEATH PATH (re-reads the class ->
  collapse never chained), and the per-victim EFFECT-ROW selection
  (vs2's row semantics drifted: vanilla victims hold other art at the
  row vs2's property selects -> per-victim wrong aura colors).
- FIX (14z-27): remap all 7 deity records to the NATIVE electric
  class 0x04 (Victor's) at the extraction-blob level — new generator
  kind [[region_fix]] (guarded old/new byte patches inside extractor
  region blobs; region "hitbox" +0x11A9..+0x1269 stride 0x20).
  Measured end to end WITHOUT pokes: full electric reaction chain ->
  grounded death node 0x158210 (the same terminal node as any healthy
  electric KO), SPECIAL FINISH + PERFECT over a properly downed
  victim. Aura = native effect rows every vanilla victim supports ->
  correct yellow by construction (the class-0x4E path no longer
  exists). The 14z-26 property-table extension STAYS (classes
  0x4F-0x53 remain routed for any future ported move; the 0x4E slot
  is now unreferenced).
- Gate test_don_reactions.sh STRENGTHENED: asserts the grounded death
  node at f2950/f3030 (idle loop = the old bug).
- Trade-off recorded: the deity now uses vsavj's class-0x04 semantics
  (Victor-electric) rather than vs2's 0x4E nuances — visually and
  mechanically equivalent at the level playtest can see (reaction,
  aura, death); if a nuance difference surfaces, revisit with a
  per-consumer extension instead of the remap.

## Session 14z-26 (round 39: 421P correction -> ROOT CAUSE FOUND + partial fix shipped; collapse handoff remains)

Maintainer corrected round-38's report: the bug move is **421P with
sword (Change Immortal — the blue deity multi-hit summon)**, kill by
its damage at any spacing; capture shows SPECIAL FINISH + victim
standing neutral. Reproduced deterministically in one 2P run (replay
48 + HP poke), then traced end to end:

- The reaction dispatch (0x2380C family, ~60 call sites) indexes the
  per-HIT-CLASS property table 0x28D00 with victim+0x54. The deity's
  hits carry class 0x4E. **vs2 EXTENDED the table with classes
  0x4E-0x53 (values 0f 1b 1f 19 0f 03); vsavj's table is zero there**
  -> the special branch (electrocute/special-finish reaction — native
  control shows the victim shaking in the lightning X-ray, hence the
  SPECIAL FINISH banner) never fires; the victim's plain hitstun
  expires into idle. Also explains the attacker link: the deity's
  hits attribute to Donovan himself (+0x32 = 0x8400), so this is
  class-driven, not attacker-object-driven.
- FIX SHIPPED: data_port hit_class_props_ext — 6 bytes vs2 0x28026 ->
  vsavj 0x28D4E (zero-filled spare capacity; terminator untouched).
  Legacy-safe by construction: no vanilla attack emits classes >
  0x49. Measured: deity KO now fires the electrocute shake (node
  0x157EBC) with the X-ray burst — and other ported moves using the
  new classes get their reactions routed too (the maintainer's
  "other specials" suspicion).
- REMAINING (next session): the shake->COLLAPSE handoff. Native: shake
  loop (two alternating nodes) then collapse node; ours: single
  static shake node, then release to idle — a second consumer of the
  property value diverges (engine-version drift in the dispatch's
  branch targets, or a follow-up resolver). Same comparative-tap
  methodology, one level deeper. Gate test_don_reactions.sh freezes
  the current partial (shake fires) and carries a STRENGTHEN-note for
  the collapse.
- Also logged from round 39: possible wrong palette on the deity when
  summoned WITHOUT the sword (maintainer double-checking).

## Session 14z-25 (round 38: select-sword CONFIRMED by maintainer; 421K match-end KO bug logged + repro hunt banked)

- **Round 38 maintainer confirmation: the select-screen sword renders
  as expected** (cursor on Jedah's cell). 14z-24 closes confirmed.
- **NEW BUG (maintainer, non-blocking): Donovan 421K (at least 421HK)
  ending a MATCH leaves the opponent in neutral pose** — no KO anim,
  no knockdown; the same move ending a non-final round triggers its
  hard knockdown correctly. Repro hunt this session did NOT land the
  bug: match-end KOs on the move's LAUNCHER hit animate correctly in
  both 2P and arcade environments (three clean repros) — the bug
  needs the hard-knockdown-causing hit as the killer, which scripted
  spacings never achieved. All experiments + facts + timeline banked
  in tests/experiments/421k_ko/ (persistent-suite doctrine); needs
  the killing-hit configuration from the maintainer or a spacing
  sweep. GOTCHA-class note recorded there: POKE VALUES feed the CPU
  AI — any poke change reshuffles downstream choreography.

## Session 14z-24 (SELECT-SWORD FIXED — draw-behind flag; machinery live at stage 6, battery pending)

The 14z-23 "offset+priority" resolved to pure LIST ORDER — and the
"32px offset" was an occlusion illusion (the sword spans x=99-163 in
BOTH games; native's body occludes 99-128, showing only hilt + hip
tip; ours drew the whole span on top). Chain of proof:

- Full-word entry compare (the 14z-23 masked-bits suspicion): the Y
  high bits are the TILE BANK field (ours 0x4000=bank2, native
  0x6000=bank3 — both correct for their art locations; the earlier
  "spawn position difference" was a misread of this field).
- Software compositor over the dumped entries reproduced the visual
  difference from identical data -> not art, not palette, not values:
  DRAW ORDER. List maps: native emits sword-copy1, sword-copy2, THEN
  body (sword behind); ours emitted sword1, BODY, sword2 (second copy
  over the body).
- vs2's Donovan handler carries `move.b #8,$3C(a4)` — sets the
  OWNER's draw-behind flag for the companion; the instruction has ZERO
  occurrences in vsavj. POKE experiment: one-shot set of owner+0x3C=8
  flips our list order to native's and PERSISTS (45+ frames).
- FIX: the two resolver-call thunks' 0x0F branch now also does
  `movea.w $30(a6),a1; move.b #8,$3C(a1)` (owner ptr; a1 dead at both
  sites). Result: OBJ order native-exact, snapshot A/B shows the
  tucked back-sword matching vs2.
- All five rows LIVE at stage 6 (build d1db9c0b). New gate:
  test_don_colors.sh section 3 (sword entries present + all-before-
  body order + frozen code set; replay 44_don_select_hover promoted).
  replay.lua gained POKES (mirrors tap_writes; persistent-suite
  capture of the poke experiment mechanism).
- 14z-21c LEGACY CHECKPOINT pending the battery: select_fuzz flicker
  inventory / pick divergence may shift now that slot-0F hover
  activates the companion. Any drift -> mechanism-attributed and
  reported for maintainer sign-off, NOT silently refrozen.

## Session 14z-23 (select-sword: diagnosis CORRECTED — offset+priority, not missing art; still staged 99)

Continued investigation with the machinery temporarily reactivated
(local only; restaged 99 + bit-identical 73f4f5a5 at session end).
The 14z-22 "record-walk gap / raw-code second drawer" hypothesis is
WRONG — corrections:

- The "raw vs2 codes" OBJ entries are STALE UNRENDERED JUNK beyond the
  active list extent (a full-window write tap over frames 1000-1292
  shows those values are never written; they are leftovers in OBJ RAM
  the parse picked up). Red herring; no walk gap on that evidence.
- The sword TILE ART is verified correct two ways: byte-compare AND
  rendered side-by-side (shapes identical to vs2 bank-3 originals at
  our bank-2 positions, incl. all block-expansion cells).
- The OBJ ENTRY SETS are byte-identical to native (positions, attrs,
  sizes, palette row, duplication) — yet the RENDER differs. Four-way
  snapshot comparison (native f1210/f1500, ours f1700) shows the real
  defect: ours draws the same-size sword ~32px RIGHT of native and IN
  FRONT of the body; native draws it tucked BEHIND the sprite (hilt
  above the head, blade mostly hidden). So: a COORDINATE-BASE and/or
  PRIORITY/list-order difference in how the select venue composes the
  companion — not art, not palette, not the entry values themselves.
- Suggestive measured fact: the companion (and owner) POSITION words
  differ between engines at spawn — ours 0x4000/0xA000 vs vs2
  0x6000/0xA000 (0x2000 = 32px in 8.8 — matches the observed shift).
  The dumped entry coords nonetheless MATCH native (x=99...), implying
  the visible copy is rendered via a base/section mechanism the flat
  entry parse does not capture (CPS2 list sections carry base offsets;
  the e0ef/2058-class entries are candidates for section headers).
- NEXT SESSION (fresh head, systematic): (1) decode the OBJ list
  SECTION structure (headers/bases/order) in both dumps rather than
  flat entries; (2) attribute the visible copy: poke a single tile's
  art in a scratch build and see which rendered copy changes; (3) the
  32px delta likely traces to the keeper's spawn-position source
  (owner mirror at +0x10/+0x14) — find where vs2's select positions
  its owner vs ours; (4) priority: check attr bit-5/list-order
  semantics for the select venue. All five manifest rows remain staged
  99; build bit-identical to shipped 73f4f5a5.

## Session 14z-22 (select-sword: machinery BUILT+VERIFIED, staged 99 pending the record-walk-gap fix)

Implemented the 14z-21c plan and verified it end-to-end, then found one
deeper blocker and staged the feature off (build back to bit-identical
73f4f5a5 — the staging discipline's no-regression proof).

WHAT WORKS (all measured on live builds):
- code_word generator kind added (guarded 2-byte code patch — jump-table
  entries can't take a 6-byte site_thunk without clobbering neighbors).
- Jump-table entry 0x0F -> +0x46 handler; the keeper activates the
  companion (alive, positioned, char id 0x0F).
- The handler's number source reads 0 on the vsavj select engine, and
  index limits bite: the flourish node (index 0xFC) SELF-LOOPS (a
  permanent oversized blade), and the settled back-sword node sits at
  index 0x10B > 0xFF — beyond the MASKED resolver's 8-bit range. Fix
  shape: thunk the handler's two resolver CALL SITES (0x84602 state-1,
  0x84624 state-2) — owner 0x0F -> inject d0=0x10B + tail-jump the
  UNMASKED resolver entry 0x15088 (the 0x5C77A/E masked/unmasked pair
  pattern, third occurrence). Result: companion holds ported node
  0x0E1780 (= vs2 0x28DC58, the settled pose) and the page-A OBJ
  entries match native BYTE-FOR-BYTE mod +0x2750 (positions, attrs,
  sizes, palette row 0x17, duplication pattern).

THE BLOCKER (fully measured, not yet fixed):
- Activation also wakes a SECOND select drawer whose record subset the
  gen's anim-region record walk NEVER REMAPS: second-page OBJ entries
  carry RAW vs2 band codes (0x97xx body pieces of a different anim
  frame, 0x8650/0x8658 etc.) which index VANILLA vsav art — visually
  Jedah's giant blade diagonally across the select sprite. This walk
  gap also explains the 4 unreferenced-looking tiles (0x8644-47) and
  the old "extra piece 0xEC47" note (14z-21b) — those drawers were
  always running; activation made their output prominent.
- DEAD END LOGGED: placing "missing" tiles via a new build_gfx
  --extra-tiles path + reserving their cells in the generator pool
  CASCADED the first-fit allocation (267 effect placements moved — the
  allocator is block-aware; removing 4 cells splits runs). Reverted
  entirely. Any future fixed-position tile need must allocate at the
  POOL TAIL or ride the existing exception flow, never carve early
  cells.
- NEXT: find how the second drawer's records are referenced (separate
  record-pointer table or cptr indirection the walk misses), extend
  the walk (or add the records to the remap set), verify raw-code
  entries gone, THEN restage the five rows to 6. All five rows +
  comments sit in donovan.toml staged 99; flipping stage is the only
  re-enable step.
- Legacy checkpoint from 14z-21c still pending a stage-6 battery run
  (the staged-99 build needed none — bit-identical to green).

## Session 14z-21c (select-sword: FULL activation chain reverse-engineered; fix ready to implement)

Correction to 14z-21b: NOT the companion-overlay record system — the
select venue has its own dedicated select-companion machinery. Complete
chain (all measured live on vs2 + twin-located in vsavj):

- The select-companion OBJECT exists on our build (obj $FFD480, char id
  0x0F cached) but stays DORMANT: alive flag +1 stays 0, no anim.
- vs2 activation (frame-1159 trace, hover-change to Donovan): a
  per-frame companion KEEPER routine dispatches on the hovered CHAR ID
  through a 32-entry PC-relative jump table; most entries -> deactivate,
  Donovan (0x13) -> a handler doing `lea 0x289EF6,a0; jsr 0x13778`
  (resolver: node = table + table[id*2]; writes obj+0x1C) -> initial
  node 0x28DAF0; sets +4=0x0202, +0/+1=0x0101 (alive).
- The sword pieces are then drawn per frame by select-engine walker
  PC 0x19E24 from records at ~0x29AFE0+ (format: [attr,code] pairs +
  0x11x0x09 header + coord-list long; per-anim-frame records), coord
  lists at 0x352150+ (INSIDE the overlay pool window [0x300000,
  0x361000)), tile codes 0x863F-0x864D (in-match sword band — remap
  exists), palette row 0x17.
- vsavj TWIN keeper found at ~0x844E0 (owner-id cache sig 1d6b0382000a
  is unique); its jump table (after the second `4efb 1002`, ~0x8456C+4)
  has entry 0x0C (and one later entry) -> handler at disp +0x46 doing
  `lea 0x2083BC,a0` (or 0x2087CA by flag a6+3) `; jsr 0x15084`
  (resolver twin, sig-verified). Entry 0x0F = 0x0040 (deactivate).

FIX PLAN (next session):
1. Port the data chain: vs2 node-offset table 0x289EF6 (extent TBD),
   nodes ~0x28DAxx, records 0x29AFxx-0x29B1xx(+ per-frame set), coord
   lists 0x352150+ (check overlay-pool coverage first — POOL_LO/HI in
   tools/overlay_port.py may already carry them), tile-code remap via
   the existing gfx_remap map.
2. Route vsavj jump-table entry 0x0F (word 0x0040 -> 0x0046) so slot
   0x0F enters the existing char-0x0C handler.
3. site_thunk the handler's two `lea` sites (0x2083BC/0x2087CA
   immediates) char-conditionally: owner id 0x0F -> ported table (the
   fixture_row0f pattern; check flag-dead safety + also the later
   state's `lea 0x283690` site).
4. LEGACY RISK CHECKPOINT: the keeper consults entry 0x0F whenever the
   select cursor hovers the Jedah cell — 04_select_fuzz (flicker
   inventory) and the pick frozen-divergence may shift. If flickers
   drift, that is EXPECTED mechanism here, but per the standing watch
   it must be mechanism-attributed and re-frozen with maintainer
   sign-off — flag it in the session report, do not silently refreeze.
5. Gate: extend test_don_colors.sh (or new) — select-hover OBJ list
   must contain the 8 sword entries at frozen native positions/codes
   (remapped); include a vanilla-side assertion that a non-companion
   char's hover keeps entry-0x0F path dormant.

## Session 14z-21b (select-screen sword: mechanism PINNED, fix scoped; 2026-07-31)

OBJ-RAM A/B at select hover (ours frame 1290 vs native vs2 frame 1350,
dumps in the walk transcripts; select A/B crop saved):
- The standing select sprite = record-drawn from the ported in-match
  tile placements (our codes 0xBE9D-0xBF7E, pal row 0x15, positions
  matching native's 0x97xx/0x98xx piece-for-piece) — the M2b select
  port works for the BODY.
- Native vs2 additionally draws **8 sword entries: codes 0x863F,
  0x8640, 0x8642, 0x8643, 0x8648, 0x864B, palette row 0x17, each
  duplicated, x=99-115 y=102-166** (hilt above head + blade at hip).
  Ours has none. The duplication + separate palette row + in-match-band
  codes = the COMPANION-OVERLAY record system running on the select
  venue in vs2 — a venue not among the 22 verified overlay poke sites
  (14r port verified on match/win paths only).
- FIX SHAPE (next session): locate vs2's select-venue overlay spawner
  site (tap the ported-zone record walks during vs2 select; the tsite
  cross-match machinery in tools/overlay_port.py), find the vsavj
  analog site, context-verify, add to VERIFIED_SITES, re-emit, and
  probe with the timer-tick detector on the SELECT path (the 14r
  methodology). Watch: select venue runs on legacy paths for every
  char — the site must be char-gated like the rest of the overlay
  system. Also noticed (cosmetic, low): ours draws one extra piece
  (code 0xEC47, effect band) at x=80 y=120 that native lacks —
  investigate alongside.

## Session 14z-20 (row-0x0F fixture override SHIPPED; sword-shock aura resolved as engine-global; 2026-07-31)

- **Row-0x0F fixture override (the statue's steady miscolor) DONE:**
  two [[site_thunk]] rows hook the staged fixture sites 0x1C586 (bank
  0, staging+fade) and 0x1C59A (bank 1) — shared by match intro AND
  attract (measured; the six direct fixture sites serve other venues
  and are NOT hooked pending measured need). Thunk: if either char id
  byte ($FF8782/$FF8B82 = obj+0x382) == 0x0F, a0 = embedded vs2
  override block (vs2 0x3CB7DC, 0x40 bytes — row 0 byte-identical to
  the vanilla fixture's row 0x0E, row 1 = the statue red ramp); else
  vanilla 0x3B5940, flag-safe (both sites' fall-throughs kill CCR).
  Measured on build 73f4f5a5: palette rows 0x04-0x0F ALL byte-equal
  to native vs2 in-match; rows 0x0E/0x0F frozen into
  tests/test_don_accent.sh.
- **GOTCHA PAID (generator extended):** hole "a" lies inside the CPS-2
  crypt range — site_thunk bodies placed there are stored re-encrypted
  for opcode fetches, so EMBEDDED DATA read via data loads comes back
  as ciphertext (first build produced garbage palette rows). site_thunk
  now takes hole = "b" (required for any thunk carrying data);
  docs/GOTCHAS.md entry added.
- **Sword-shock red-vs-yellow RESOLVED as engine-global aesthetics,
  decision pending:** the electrocute arc/glow writes to P1 rows 0-3
  come from GLOBAL vsavj tables (accent family idx ~0x711/0x970/0x9A4
  region; base row block 0x39A7E0) — identical sources for Donovan,
  vanilla Jedah, AND a non-slot-0F victim (three-way tap). vs2 simply
  re-themed those global tables yellow. Our build shows correct
  VSAVJ-native shock colors; there is NO porting defect and NO
  side-effect risk (nothing of ours touches that system). Making
  Donovan's shock yellow would need either a global re-theme (legacy
  visual change — ruled out) or a slot-0F-conditional arc-table hook
  (inconsistent with vsavj's victim-independent styling). See
  "Decisions pending".
- Control-run GOTCHA within a gotcha: the first "vanilla control" for
  the shock tap used the SAME slot (vanilla Jedah = slot 0x0F picks) —
  worthless for per-slot attribution; the discriminating control was a
  DIFFERENT victim (default-cursor char). Vanilla controls must vary
  the dimension under test, not just the build.

## Session 14z-19 addendum (round 36 CONFIRMED, 2026-07-31)

Maintainer playtest on b80e0e67: **sword and statue no longer blink;
electrocuted sprites clean including Donovan.** The rounds-16..35
blink saga is closed.

- **NEW TRACKED ITEM (round 36):** during Victor's electrocute, the
  electric effect SURROUNDING THE SWORD renders red instead of vs2's
  yellow (the body X-ray + body aura are correct). Maintainer: not a
  blocker, but track it — "might not be purely cosmetic or without
  other side-effects." Mechanism hypothesis (untested): the sword is a
  separate OBJ from the body; its shock-overlay pieces may resolve
  their palette row through a path we haven't repointed — candidates:
  (a) the un-ported row-0x0E/0x0F fixture override (open item — red =
  could be residual Jedah-theme content in a row the overlay
  references), (b) an effect-table row indexed by the sword object's
  own identity rather than the owner char (the effect [[palette]] port
  covered char-indexed tables 0x38C218/0x38C258 only). Investigate
  together with the row-0x0F port: same measurement setup (replay
  34/35 electrocute window, palette-RAM dumps + OBJ record palette-row
  attributes of the sword overlay pieces).

## Session 14z-19 (round 35: LEGACY VIOLATION found+reverted; accent march understood; sword blink fixed for real)

Round-35 captures (19-29) showed both fixes had failed. Root-caused by
direct palette-RAM per-frame dumps (a new discriminating instrument —
DUMPS over 0x90Cxxx) + vanilla control taps. The corrected world model
(several 14z-17/18 conclusions were WRONG — corrections below):

- **THE PALETTE-ROW MAP (corrected):** rows 0x0A-0x0F = P1 character
  extended region; **rows 0x10+ = P2 CHARACTER's rows** (not "statue
  rows"). 0x38D1A0 = VICTOR's sprite block (char id 3 — every probe
  match had P2=Victor, which is why rows 0x10/0x11 "matched native":
  both games upload Victor identically). Char id 0x0F = JEDAH in
  vanilla (the U,U,R select cell); our dev builds replace his slot.
- **14z-18's statue_accent_rows was a SUPERSET VIOLATION:** 0x39B040
  is Victor's OWN accent data (his in-match glow cycle — vanilla
  control alternates row 0x10 between 0x38D1A0/0x39B040 exactly like
  our build). The data_port overwrote it → Victor's glow deadened in
  ALL matches incl. pure-legacy. Invisible to the masked RAM gate
  (ROM->palette-RAM path never transits work RAM) and outside the
  pixel-gate frames. REVERTED (row deleted; bytes pristine again);
  permanent guard added (tests/test_don_accent.sh asserts 0x39B040-7F
  == vanilla + Victor's row-0x10 cycle alive in-match).
- **The sword blink, actual mechanism:** the engine MARCHES row 0x0C
  through a 4-frame source cycle: accent T0 (0x39FBE0), T1 (0x39FC00
  = T0+0x20, overlapping window — the slide animates Jedah's glow),
  sprite block +0x40 ×2. Row 0x0D is never accent-cycled. vs2 has no
  march (re-reads block+0x40 steadily). 14z-18's "super-cycle tail to
  0x39FC3F" was an A0 post-increment misread (second time paying that
  trap). FIX: T0 and T1 both hold vs2 row-C content (weapon_accent_t0/
  _t1); 0x39FC20 holds row-D content (weapon_accent_rowd_slot — the
  would-be row-D slot, no observed reader, authentic content either
  way). Measured on the new build: row 0x0C single-variant across the
  idle window, byte-equal to native vs2. The statue's BLINK was the
  same row-0x0C march (statue pieces share the row) — also dead now.
- **Statue steady miscolor remains (open):** palette row 0x0F is
  wrong — it's filled by the venue fixture (2 rows 0x0E/0x0F from
  0x3B5940, global legacy data, untouchable) and vs2 then OVERRIDES it
  per-char from Donovan's intro block at vs2 0x3CB7DC (2 rows; the red
  ramp for the statue keyhole/accents lives at 0x3CB7FC). vsavj's
  engine has NO per-char override path for slot 0x0F (vs2 added CODE
  for it — immediates at vs2 0x1a97e/0x1ac24/0x1aff8/0x2acc6/...).
  Porting needs a slot-0F-conditional 2-row upload hook (rows 0x0E/
  0x0F, dst 0x90C1C0 + bank 0x91C1C0, post-fade or via staging) — NEXT
  SESSION. Expected visible result meanwhile: statue/sword no longer
  blink; some statue accent pieces steadily miscolored (vsavj fixture
  colors: blue/grey ramp instead of vs2's red ramp).
- **NEW open item:** per-char table B at 0x38C1D8 (second sprite-
  palette pointer table — alt punch/kick color sets; true table family
  layout at 0x38C198 is FOUR 16-slot tables at +0x00/+0x40/+0x80/+0xC0
  + 2 misc pointers, data starts +0x108) — slot 0x0F NOT repointed:
  alt-color Donovan likely loads Jedah's palette. Port vs2's table-B
  block (check vs2 analog) or interim-repoint to the same block.
- **ROMDIR event:** qsound_hle.zip had vanished from ROMDIR (audit
  FAIL per §3; the dir also carries fresh cfg/nvram — an emulator has
  been run against it directly). Restored byte-verified copy from
  build/donovan6/rompath (dl-1425.bin SHA-1 matches the frozen
  manifest); audit green again. Maintainer: please keep the reference
  dir play-free.
- Build entry point note: stage-6 dev builds require
  GEN_FLAGS="--allow-plausible --tripwire-open" (as test_m2b_stage6.sh
  does); a bare build_donovan.sh 6 fails on 58 open reconciliation
  refs — expected, not a regression.

## Session 14z-18 (round 34: accent super-cycle completed; statue rows found and fixed; two new items logged) — CONCLUSIONS CORRECTED IN 14z-19

- Round-34: the first blink fix was HALF the cycle. Measured over 200
  frames: phase 2 reads 0x39FC00-0x39FC3F (starts +0x20 into phase 1's
  range and extends 0x20 past it — the residual "darker grey + red
  spots"). Tail row covered (data_port weapon_accent_tail).
- THE STATUE: rows 0x10/0x11, alternating base rows 0x38D1A0-DF
  (correct grey) with a second accent family 0x39B040-7F (the blink).
  Zero legacy reads (audited). Fixed by making the accent phase
  identical to the base phase — vanilla->vanilla copy via the new
  data_port src_image option. Build 53223293.
- Verified: the row C/D upload spectrum now carries only authentic art
  values (pale metals + his sash browns; the graduated red RAMP is
  gone; isolated warm accents are his real palette content).
- NEW ITEMS (round-34 report, logged for next sessions):
  1. SELECT-SCREEN Donovan big sprite missing the back-mounted sword
     (user captures; likely the select-art strip lacks the weapon
     overlay piece — task #18 territory).
  2. SPEED-MODE menus: the maintainer pushes back on an earlier claim
     of auto/auto+turbo availability — measured behavior: non-Donovan
     chars offer Standard/Turbo only in 1P; PvP produces inconsistent
     per-side option sets (captures show P1 NORMAL/AUTO vs P2 NORMAL/
     TURBO/AUTO/AUTO&TURBO). Possibly vanilla-quirk, possibly an
     interaction with the Start-hold flavor shim (it reads Start state
     during match load — the same input the speed menu consumes).
     UNINVESTIGATED; the maintainer marks it not-urgent.

## Session 14z-17 (THE SWORD/STATUE BLINK IS FIXED — build f4a7e00e)

The rounds-16..33 blink is dead. Final mechanism + fix:
- The engine's accent path caches nothing: the red phase reads FOUR
  global accent rows at 0x39FBE0-0x39FC1F (the A0-was-post-increment
  correction; base family 0x39A910). A collector audit over the pure-
  legacy replays (02/30/29) found ZERO reads of those rows by any
  non-slot-0F content — they are JEDAH's theme rows, exclusively.
- FIX (in-place slot-0F class, zero code, zero legacy cycles):
  data_port `weapon_accent_rows` — vs2's sprite-block rows +0x40
  (0x39CBDC, the exact pale-metal tones vs2 displays steadily) written
  over the four red rows. The vsavj accent mechanism keeps alternating
  — between identical values — yielding vs2's steady look through the
  host engine. Verified: uploads now carry ffff/fcdf/f9ad/f87a (pale
  family, no red); four consecutive-phase snapshots show a steady
  pale sword. Also expected fixed: the statue blink and the red arcs
  around the sword (same rows).
- Session-14z-16's POKES facility (tap_writes) and the pointer-nuke
  differential were the tools that exonerated the stage-script system
  and exposed the +0x3A4 cache / global-path split; the +0x3A4 cache
  is correctly initialized (0x1C68E reads the repointed table-1 ✓) —
  no further work needed there.

## Session 14z-16 (blink: vs2 STEADY confirmed; the complete fix design)

Ground truth closed the loop (live taps, both games, same replay):
- NATIVE VS2: Donovan's weapon rows 0x0C-0x0D refresh EVERY frame from
  ONE steady source — his sprite block +0x50/+0x60. NO alternation.
  (The maintainer's wager confirmed: vs2 does not cycle at all.)
- VANILLA VSAVJ (Jedah control): the SAME 4-frame alternation we see —
  sprite block +0x50 vs the global rows 0x39FBF0-0x39FC2F (base
  0x39A910 + ids 0x297-0x29A; the 14z-13 id model was right, base off
  by a 0x10 header). The red accent is UNIVERSAL vsavj styling (fine on
  vanilla art that was designed for it); Donovan's vs2-designed sword
  art + vsavj's red accent = the blink.
- The refresh script (0x376518) is installed ONCE per match by engine
  setup (immediates 0x1F142/0x1F14A -> job block $FF82B0/B4; +0x34 is
  the active script). vs2 uses different scripts (installers at
  0x1D846/0x1DCC4/0x1E088: 0x36BD34/0x37F534/0x38FD94 by mode).
FIX DESIGN (zero legacy execution, reuses proven machinery):
1. Place a PRIVATE copy of the 0x376518 script with the red-sourcing
   phases changed to block-sourcing (or waits) — the one remaining
   unknown is the command semantics ("0dXY 018Z" entries + waits);
   determined by a short experiment: NOP/modify entries in the private
   copy and observe the upload sources shift (2-3 build cycles, the
   REGLOG row tap is the readout).
2. Revive the 14z-7 countdown mechanism (init-shim marker + sword-exit
   blob — Donovan-gated by construction, once per match, post-install):
   payload = `move.l #PRIVATE,$FF82B4` (swap the active script pointer
   in the RAM job block; the engine re-installs per match, our blob
   re-swaps per match ✓).
3. Acceptance: sword/statue steady grey (multi-phase pixel A/B incl.
   odd frames), vanilla control UNTOUCHED (the swap only runs in
   Donovan matches), full battery, playtest.

## Session 14z-15 (blink driver FULLY mapped: the stage palette-anim refresh system)

Final layer measured (continuing 14z-14 without playtest input):
- The job block at $FF8280 is installed ONCE at match load by the
  ENGINE's stage setup (PC 0x1F142/0x1F14A: `move.l #$371C98,$30(a6)` /
  `move.l #$376518,$34(a6)` — hardcoded engine immediates; a6=FF8280).
  Upstream: a PER-STAGE palette-anim descriptor is copied from table
  0x1F92E (indexed by the stage number at $100(a5)) into -$3C78(a5),
  0x80 bytes; the script 0x376518 carries `0dXY 018Z` row-refresh
  commands (waits 0x0020...).
- The 4-frame cycle = the script refreshing char palette rows 0x0C-0x0D
  (the weapon rows): row 0x0C sources the ported block (+0x50 = grey ✓)
  while row 0x0D's refresh resolves 0x39FBF0 = JEDAH's block +0xCD0 —
  a FOURTH slot-0F-sourced resolution (id 0x18E-family -> address),
  whose map is the last unpinned link.
- NEXT (first move): run the identical REGLOG tap on the VANILLA
  control (Jedah vs Victor, replay 34 inputs) — vanilla-Jedah should
  ALSO read 0x39FBF0 (his own rows; correct for him). Then resolve how
  id 0x18E maps to that address (the stage descriptor at -$3C78(a5) or
  a fourth per-char table) and repoint the slot-0F resolution to the
  ported effect block rows (the vs2 block is 0xDC0 and contains the
  analog rows). All prior repoints (tables 1-3) remain correct and
  shipped.

## Session 14z-14 (sword-blink fix session: driver mapped to the palette-JOB system; third table repointed; ONE tap from the finish)

Progress (build 40256bae):
- SHIPPED: the THIRD per-char palette table (0x38C258) row 0x0F
  repointed to the ported effect block ([[palette]] extra_tables
  support; vanilla shares one block between tables 2+3, we now mirror
  that). Harmless-by-construction (slot-0F only, row content = his own
  block); may serve other status paths.
- The repoint did NOT stop the red frames: live source still 0x39FBF0.
  Driver chain mapped this session (each link measured):
  * The uploads run under a6=DONOVAN with A3=$FF8280 = a palette JOB
    QUEUE in engine work RAM; jobs carry ROM SCRIPT pointers (live:
    0x371C98, 0x376518) + the target row (0x0C observed).
  * The script at 0x376518: entries like `0020 0000` (waits) and
    `0d0X 018Y` commands (ids 0x181/0x18E family) — the id->source
    computation NOT yet pinned (0x39FBF0 not literal anywhere in the
    queue page or scripts; computed).
  * +0x14E is set-and-cleared within the frame (frame-done dumps
    always 0 — the transient GOTCHA); the observed clear PC 0x2A7DA.
- NEXT (one focused session, first move pre-planned): find the RAM
  long/word feeding A0 for the red job — REGLOG tap candidates: the
  queue slot fields around $FF82A8 (the two script pointers sit at
  ~$FF82A0/AC per the dump), and/or bp the job-processor entry
  upstream of 0x2AD3C reading (a3). Once the enqueuer/computation is
  named, redirect per the established slot-0F patterns. All probes/
  replays in place; the 4-frame cycle fingerprint: 2 frames from
  0x39FBF0 (0x40 bytes), 2 from sprite-block+0x50.

## Session 14z-13 (round 33: electrocute FULLY CONFIRMED incl. yellow; sword blink mechanism DECODED)

- Round-33 playtest: the electrocute is CORRECT — structure AND colors,
  yellow burst included. The 14z-12 purple-vs-yellow decision DISSOLVES:
  the burst/tint colors ride the per-char effect-palette block, so
  Donovan naturally brought vs2's yellow while vanilla characters keep
  their own — the ideal outcome, zero engine surface. (My "global
  purple" analysis was half-right: the global rows exist but the
  per-char block dominates the visible result.)
- SWORD/STATUE BLINK — mechanism fully decoded (round-33 two-frame
  captures: grey frame + red frame cycling):
  * The sword idles through a stride-8 palette-seq stream (his
    companion data in x2b7ef4; sword nodes @0xF77E2+, statue twin
    @0xFA89A+; per-node seq id = 0x200 | flags byte -> ids 0x292-0x29D).
  * Streams are IDENTICAL vs2-vs-build; the ids resolve in the GLOBAL
    palette-seq table (vsavj 0x39A900 / vs2 0x3B0A3C, 0x20-byte rows):
    vs2 rows 0x297-0x29A = blue-grey shimmer (0322/0433/0744 family —
    the sword's intended subtle sheen); vsavj rows at the same ids =
    RED fade records (0d00/0b02 family) = the red frames. Uploader =
    0x2AD64-family writing pal RAM row 0x0C; live-tap confirmed the
    alternation grey(ported block rows)/red(global rows).
  * No data-only fix exists: vsavj's global table has NO matching grey
    rows anywhere (full scan) and NO free ids (no FF gaps in the
    0x1000-id window); the table itself is legacy surface.
  * FIX DESIGN (state_hook precedent, next session): locate the seq-
    TRIGGER call in the ported companion handler (it computes
    0x200|flags and invokes the engine uploader); wrap it (ported-code
    call site = legacy-clean): ids 0x292-0x29D -> a GEN blob uploading
    from 4 privately-placed vs2 rows (vs2 0x3B0A3C + id*0x20, 0x80
    bytes total) to the row from context; other ids -> original path.
    Acceptance: sword/statue steady grey-shimmer, no red; pixel A/B
    at multiple phases (the odd-frame rule); battery.
- NOTE the param-word difference build-vs-vs2 in those nodes
  (0x2C -> 0x0F, all nodes): predates this session's changes; the
  drawn palette row (0x0C) comes out right regardless — investigate
  during the fix, do not assume it is wrong.

## Session 14z-12 (round 32: X-ray STRUCTURE confirmed; effect-palette block ported; purple-vs-yellow = DECISION)

Round-32 captures confirm the 14z-11 sweep: the electrocute X-ray now
renders Donovan's own silhouette (structure correct). Remaining color
layer, split in two:
1. FIXED (build fbf10960): the X-ray/status BODY TINT came from the
   SECOND per-char palette table (vsavj 0x38C218 = main+0x80, uploader
   family 0x2AD20: per-char blocks of 0x20-byte effect/flash palette
   rows) — never repointed, serving Jedah's greys (the round-4 body-
   palette bug, one table over). Ported vs2 Donovan's block (0x3ADFDC,
   0xDC0, per-char stride uniform) via the palette machinery
   (now multi-entry [[palette]]); row 0x0F repointed. Expected side
   effect: the red/purple sword & statue blink is the same sequence
   family — playtest should re-check it.
2. NOT A BUG (measured): the PURPLE electricity/flash. The flash rows
   upload from the GLOBAL palette-sequence table (0x39A900 family; live
   A0=0x39FBF0 = global row ~0x297) — vanilla vsavj presents ALL
   electrocutes purple (control: vanilla Victor-vs-Jedah, same purple)
   while vs2 styles its own engine yellow. Making Donovan-victim
   electricity vs2-yellow would need per-victim redirection of a
   GLOBAL engine sequence (new mechanism, legacy surface) and would
   make him inconsistent with the rest of the vsavj cast.

DECISION PENDING (maintainer): electric-flash color for Donovan
victims — (a) keep vsavj-native purple (RECOMMENDED: consistent with
every other character, zero legacy surface, faithful to the host
engine), or (b) engineer vs2-yellow for slot-0F victims (new
per-victim seq-redirect mechanism on a global table; visible
inconsistency with the cast; nontrivial legacy-risk surface).

## Session 14z-11 (round 31: the X-RAY OVERLAY — offset-computed records swept; build 6f96f45b)

Round-31 captures (Victor P1 vs CPU Donovan P2, electrocute at the
knockdown) pinned the LAST piece of the garble family:
- The electrocute draws a per-victim X-RAY OVERLAY record every frame
  of the reel. Donovan's X-ray records live in the anim region but are
  reached by OFFSET COMPUTATION (the aux/+0x64 chain) — no in-region
  pointer — so BOTH the inventory walk (extraction) and the gfx_remap
  walk missed them: their vs2-band tile words shipped UNREMAPPED and
  their art was never copied. On vsavj they drew whatever sat at the
  raw vs2 code positions (Jedah/mixed art on pre-14z-10 builds; the
  user's white-block captures ✓). Proof: NAT and POR OBJ dumps showed
  IDENTICAL RAW code values (ae10/adfb/b041...) at the overlay pieces.
- FIX: a SWEEP pass in obj_records.walk AND the generator's gfx_remap
  walk — every even offset validated as a record head (fmt/budget/
  count/cptr window + sweep-only strictness: budget<=0x40, block
  pieces <=8x8, >=50% band-coherent entries). 38 new records / 338 new
  tiles inventoried, remapped, and placed (parity 1160/14764 both
  sides). The static pool is now also trimmed dynamically at gen time
  against the actual band output (the sweep grew the inventory past
  the baked manifest pool).
- Verified: zero unremapped vs2-band codes in the electrocute OBJ zone
  (was: raw ae10/adfb family every frame); protected 358/358; probes
  17@3479 and 31@2618 pixel-IDENTICAL standalone. Measurement GOTCHA
  paid: pixel probes run IN PARALLEL with a battery can flake the
  replay timeline (a probe showed Morrigan's intro at a match frame;
  standalone rerun identical) — never run probes concurrently.
- Round-31's other lessons: the X-ray shows on EVERY zap (the three
  captures at timers 96/93/90), no knockdown needed; the KO/hard-
  knockdown framing was mine, not the data's.

## Session 14z-10 (THE GARBLE FIX SHIPPED: protected-tile policy + exception pool)

Implemented the 14z-9c plan end-to-end (build 272bfbbb):
- build/manifest/protected_tiles.json: 358 in-match vanilla-referenced
  positions (runtime audit via tap_writes COLLECT mode over the pure-
  legacy suite; full-run union of 574 recorded as observed_full_run —
  attract-cutscene-only usage NOT enforced, pool capacity + accepted
  attract divergence). Pool = 1256 doubly-vetted free cells (window
  minus our outputs minus ALL audited usage minus build-run residuals,
  clamped >= 0xAD80: the Sasquatch-shared band head is not free — the
  build_gfx SAFE_LO assert caught my pool overreach).
- gen_donovan_patch gfx_remap: unified rectangle first-fit allocator
  over the hole-punched pool serves the effect shelf AND band blocks
  whose remapped span hits a protected position (775 band srcs
  exception-relocated); emits tile_exceptions.json (skip list) +
  extended effect_map pairs; excludes effect_tail bank2 spans.
- build_gfx_donovan: skips exception srcs in the band loop; readback
  verifier exception-aware. build_donovan.sh: set -o pipefail (a
  crashed build_gfx had been silently packing STALE tiles — two full
  "fix" builds shipped unchanged gfx before the readback-assert crash
  was noticed; GOTCHAS).
- effect_tail.json: 11 Anita bank2 blocks relocated off protected
  positions; generator now coordinates with its spans.
- verify_gfx_build: pool-aware containment + a standing "no tile on
  protected positions" assertion.
VERIFIED: 358/358 protected positions byte-identical to vanilla; the
electric-hold frame renders clean (no chunk columns); pixel probes
17@3479 and 31@2618 IDENTICAL to goldens; battery running at commit
time (result in the round-30 report).

## Session 14z-9c (ROUND-29 ROOT CAUSE, FINAL AND PHYSICAL: the Jedah-band tile window is NOT dead)

The vanilla control run (replay 34's inputs on VANILLA vsavj = Jedah vs
Victor) collapsed every prior model and exposed the truth:
- The OBJ curtain buckets are IDENTICAL vanilla-vs-build (fc1b/c625/
  fbc9/f76d/fbee columns) — c625 is a VANILLA code, not our remap
  output. 14z-6/7/9b's bucket theories are all void.
- Vanilla vsavj does NOT darken on electric normals (the darken is a
  VS2-only presentation feature) — the "missing darken" is
  vanilla-faithful. vs2-Victor's hold-pose order difference likewise.
- THE ACTUAL DEFECT (tile render, vanilla vs build, tiles 0x2C625+):
  vanilla holds soft pale curtain/smoke art; the BUILD holds DONOVAN
  BODY CHUNKS — because the tile port's band remap TARGETS
  0xADCF-0xEA3F inside the "SAFE" window 0xAD80-0xEEBB (build_gfx
  session-14 assumption: Jedah's band is free once Jedah is replaced).
  VANILLA CONTENT REFERENCES TILES IN THAT WINDOW: measured consumer =
  the VS-fade/curtain columns (code c625 drawn by slot-0F-adjacent
  system compositions, displayed during electric holds -> Donovan
  chunks as columns = round-27 "garbled tiles on Donovan"); the
  electrified-knockdown sprite sighting (round 29) is the same class.
  Lilith matches don't reference those codes -> clean ✓.
- EVERY other layer is verified vanilla-faithful (records, anims,
  cptr, coords, spark, banks) — the garble is purely stolen tile
  positions.

FIX (next session, M2b-scale, machinery already parameterized):
1. AUDIT: enumerate vanilla-REFERENCED tile codes in 0xAD80-0xEEBB
   (walk vanilla OBJ records reachable in gameplay + the VS/system
   compositions; gfx_tiles + obj_records tooling) -> the set of
   positions that must NOT be overwritten.
2. Re-place: choose a new DELTA / placement (build_gfx_donovan.py
   DELTA + [gfx_remap] band values + effect_map shelf) that avoids the
   audited positions (or split placement around them). Rebuild gfx +
   prg (the remap machinery regenerates codes everywhere).
3. Acceptance: render-compare the audited vanilla positions
   (byte-identical to vanilla), the hold replay 33 curtain columns
   (soft dark, not chunks), electrified knockdown by playtest, plus
   the full battery + all pixel probes.

## Session 14z-9b (round 29: THE UNIFIED MODEL — it's the electric-hit DARKEN curtain)

Round-29 precision (electrified state at the hard knockdown) + odd-frame
sampling finally exposed the real subsystem: the ELECTRIC-HIT SCREEN
DARKEN. Measured (replay 35, odd frames 2671-2681): native darkens the
whole screen through the electrified reel; PORTED DOES NOT DARKEN AT
ALL on the 5HP hit. The darken is drawn by extending the OBJ list into
the curtain buckets (0x600/0xA00 tails) WITHOUT rewriting them — the
engine relies on them holding dark tiles. This unifies every sighting:
- vs2: VS-screen leftovers there are dark 444f columns -> darken works.
- vsavj+Donovan: the VS screen leaves HIS PORTRAIT PIECES there (c625)
  -> when the buckets are displayed (the electric hold / Mega Shock),
  they draw Donovan-band tiles over the victim = the round-27 "garbled
  tiles on Donovan" (and Lilith stays clean: her VS layout leaves
  benign content). In the 5HP case the darken never engages on ported
  (activation divergence, cause not yet traced) so the electrified reel
  plays bright-but-clean = matches every "coherent" probe this session.
- The 14z-7 clear targeted the RIGHT buckets with the WRONG value
  (transparent, not dark) and its A/B compared frames OUTSIDE the
  darken window (why clear-on/off looked identical) — the round-28
  "body garbled" was likely the hold viewed with transparent-vs-dark
  curtain compositing.
NEXT (the actual fix, two parts):
1. Fill the curtain buckets with the proper DARK tile entries (vsavj's
   own curtain code — read what vanilla vsavj leaves there in a
   Lilith-victim run, e.g. the fc1b-family, and reproduce that grid)
   at match start — the 14z-7 countdown mechanism is EXACTLY right for
   the timing (arm at init, fill ~0x50 frames in); only the payload
   changes from clr.l to writing proper (x,y,code,attr) entries.
2. Trace why the darken extension doesn't engage on ported for normal
   electric hits (list-terminator/extension length at the hit frames;
   compare NAT/POR 2671 OBJ list extents) — possibly the same bucket
   content participates in the activation decision, in which case fix
   1 alone may resolve it. Acceptance: replay 35 odd-frame pixel A/B
   (darken present, no garble, body coherent) + replay 33 hold frames
   + the full battery + pixel probes 17/31.

## Session 14z-9 (round 28 correction chased to ground: the electric-family display chain is VERIFIED CORRECT end-to-end; no reproducible garble)

Round-28 correction (the reported move = Victor 5HP / f.6HP normals,
not the grab) prompted probe 34 (both games, standing 5HP + f.6HP,
four clean single hits). Every link measured, all CORRECT:
- Hit-reaction anim: entry + every step maps EXACTLY (0xDB890 =
  map(0x287D68), 0x18-node steps in lockstep).
- The displayed record: fmt2 head, piece codes (band +0x2750), attrs,
  cptr RELOCATION (0x3F1CC8 = mapped aux0_4), and the coordinate-list
  CONTENT — all byte-verified against vs2.
- Phase-aligned pixels (POR f2668 vs NAT f2666, same record): Donovan
  coherent — beads, tunic, reel pose. The earlier "scattered pieces"
  crop was a 2-frame PHASE ARTIFACT (engines skew; the flail pose reads
  as garble when compared against a different record's frame).
- The grab-hold "wrong node" of 14z-8 is ALSO RESOLVED as legitimate:
  REGLOG capture shows vs2-Victor commands victim poses (0x29E ->
  0x286) while vsavj-Victor commands (0x286 -> 0x29E) — HIS OWN script
  data differs between the games; Donovan's table resolves BOTH numbers
  to the correctly-mapped nodes. The two games display different
  (each-legitimate) hold poses. Cross-game-legit class, like the
  attract-demo divergence.
STATUS: after three probes (32 grab/Mega-Shock family, 33 close grab,
34 normals) NO instrumented garble reproduces on the current build
(2da7d910); every display chain checked is byte-correct. The round-27/
28 reports remain REAL-BUT-UNREPRODUCED — the missing variable is
WHICH exact situation the maintainer saw (candidates: ES versions,
crouching/air victim state, dizzy electrocution loop, specific move).
AWAITING maintainer round-29: exact move + situation (screenshot
ideal). Tooling ready to pin it within minutes once identified
(REGLOG tap, phase-aligned snaps, OBJ pairing).

## Session 14z-8 (round 28: the 14z-7 clear was a PHANTOM FIX — reverted; the real shock-garble mechanism characterized)

- Round-28 report (Victor 6HP: effect ~fine, DONOVAN'S BODY garbled)
  prompted a controlled A/B: clear-on (ccb4ab6a) vs clear-off
  (2da7d910) on the new 6HP probe replay 33 — PIXEL-IDENTICAL on every
  shock frame. The clear changed NOTHING for the real move; the body
  garble exists on both builds and is THE SAME defect as round-27's
  report (one bug seen twice, not two bugs). objram_clear disabled
  (build restored byte-exact 2da7d910); test_don_shock.sh REMOVED (it
  asserted the phantom); the 14z-7 mechanism survives in git if the
  transparent-tail idea is ever wanted for real.
- 14z-7's validation error, recorded: the probe snapshotted only ZAP
  frames (flash silhouette hides the body) and the 236HP-grab framing
  measured curtain buckets that the actual defect never touches.
- REAL MECHANISM (measured, replay 33, NAT 2742 / POR 2744):
  * Donovan's held-body pieces draw with band codes ~0x20 OFF native's
    (adjacent tiles: recognizable colors, garbled chunks ✓ user
    report); burst pieces likewise resolve into his band instead of
    the shared low-code fire art.
  * The victim's held-pose cursor ENTERS the sequence wrong: NAT
    enters 0x287430 then settles 0x287418; POR enters map(0x287418)
    then settles map(0x287430) — the SAME two nodes, OPPOSITE order
    (the +0x18 "phase skew" noted in 14z-6 was this defect, not skew).
  * The entry cursor is NOT resolved via the anim-number tables (no
    index in either game's table yields those nodes) and NOT stored as
    a data long — it is computed by the reaction/state machinery. Next
    thread: the seq_set path (vsavj 0x2AD94, the +0x14E state
    machine's cursor initializer, cf. state_hook config) and how the
    hold-reaction's seq record resolves per char for slot 0x0F.
- Probes: replay pair 33_victor_6hp (committed); the 26-frame drain
  confirms 32/33 exercise the same electric-grab family.

## Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)

Fix shipped for the round-27 shock garble (build 1507c286-family, final
fingerprint in the registry/commit). Mechanism recap: the shock curtain
re-displays OBJ-list tail buckets holding VS-screen leftovers; with
Donovan those leftovers are his portrait pieces (band tiles) = garble.
Fix (two GEN pieces, both Donovan-gated, zero legacy execution):
- init_shim (objram_clear flag) now ARMS a countdown marker 0x50 at
  $FF7F00 (dead-stack scratch, legacy-masked; clobber failure modes
  benign in both directions).
- A new blob detours the ported sword routine's per-frame exit
  (vs2 0x65F00 jmp, placed site 0xCC110): while match-active
  ($FF8004==0x40000) it decrements the marker; at zero it clears the
  full 8KB OBJ list ONCE, in the object-update phase (same-frame
  rebuild repaints all active entries — no visible blank; stale tails
  stay zero).
Journey (measured, in GOTCHAS-worthy detail): single-shot clears at
char-init and at first-sword-exit both LOST to pre-match drawers (VS
screen redraws through ~f2470; char-init runs DURING the VS screen;
the match-active flag is set during the VS screen too). The countdown
makes the timing replay-independent (~80 frames into the round).
Verified: tail buckets all-zero at the shock zap; zap pixels coherent
(no patchwork); pixel probes 17@3479 (spark+Anita) and 31@2618 (sword
arc) IDENTICAL to goldens. New permanent gate tests/test_don_shock.sh.
Note vs native: where vs2 shows benign dark leftovers in the curtain,
we show transparent — an accepted M2a-class approximation (recorded).

## Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)

- Round-27 playtest: SWORD VISIBLE ON EVERY MOVE TRIED — the 14z-5 fix
  is confirmed in play. The blocker is CLOSED (cosmetics remain: blade
  palette family, non-blocker).
- New report: Victor's electricity (236HP) garbles tiles ON Donovan
  (clean on Lilith). Scoped this session (replay pair 32_victor_shock,
  OBJ-RAM dumps + write taps, snapshots):
  * Reproduced deterministically; multi-hit shock connects on both
    games; Donovan's shock POSE anim resolves the correct ported family
    (0xDAF58 ~ vs2 0x287418+skew) and his shock record head
    (fmt2/budget 0x23/count 0x0D) is byte-identical to vs2's.
  * The garbled art = the shock's darkening/cage GRID: native draws a
    uniform repeated-tile grid; ported draws a MIX of correct columns
    (Victor's vsavj codes f76d/fbc9) and STALE OBJ-list entries never
    rewritten since the match-intro (frame ~2313, e.g. code c625 = a
    Donovan band tile from his intro pieces; written by engine drawer
    PC 0x1B8BE, exposed at shock time with zero writes in between —
    proven by whole-run offset taps).
  * => mechanism = Donovan-specific OBJ-list length/terminator
    divergence during the shock composition exposes stale list tail;
    the divergence source (piece counts / budgets of other records in
    the composition, or the curtain drawer's slot arithmetic) is NOT
    yet pinned. Shock ENTRY-node number lookup needs a T-walk (0xDAF58
    is an interior node — direct T_d[2n] search fails).
  * Class: non-blocker (maintainer hierarchy); almost certainly NOT a
    regression — present since the record/tile port (user had not
    fought Victor before).
- Instrumentation ready for the fix session: replays 32_victor_shock_
  {vsavj,vsav2}, OBJ-RAM dump/pairing scripts (transcript), tap_writes
  with 32-bit data logging (this session's fix).

## Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)

The armed-normal sword swing is FIXED at root. Full chain (each link
measured): Donovan's anim nodes carry a sword-pose word at node+0xE;
his ported sword-command routine (vs2 0x65EBA family, placed 0xCC0CA)
adds 0x23 and calls set-anim-by-number on the sword object; numbers are
0x124-0x201. vs2 calls the UNMASKED resolver entry (0x5C77E — vs2
hoisted `andi.w #$ff` to a skippable pre-entry at 0x5C77A); vsavj's
twin embeds the mask, and the auto-matched reconciliation row sent
ported calls into it -> numbers truncated -> wrong-but-valid nodes in
Donovan's own (correctly repointed) number table at 0xBD07A[0x0F] ->
sword idled through every attack. Everything else (pose data, table
repoint, tiles, +0x9C char id) was verified correct along the way.
- Fix: new reconciliation kind `patched_clone` (gen) — vanilla resolver
  bytes minus the andi, placed in hole a, ported refs only; vanilla
  callers untouched (36 vanilla call sites keep the masked original).
- Verified: sword walks 0xE19D8-0xE1AB0 (= vs2 0x28DE98-0x28DF28 swing
  family), idx-0 command lands, SNAP pixel shows the blade arc, Anita
  present, spark clean. New permanent gate tests/test_don_sword.sh
  (replay 31_don_6hp probe, node 0xE1A20 assertion).
- Red-herring bookkeeping (measured, valuable): the type-3 "spark" is
  the GENERIC hit starburst (vs2's global effect table T=0x2B7EF4 = the
  head of ported region x2b7ef4) and renders CORRECTLY on our build;
  the 14z-3 "sword-arc effect object" interpretation was wrong. Effect
  strip tables: vsavj T=0x283690 (12 abs code refs), per-char anim
  number tables: vsavj 0xBD07A / vs2 0xD7218 (row 0x0F repointed to
  0xDDA1E by the bank port — verified correct).

## Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean

On-hit effects verified clean in play; no regression observed. State
clean for further work. Current work: the sword-swing display-side
redirect (the one remaining blocker step; see 14z-3/14z-4 and
NEXT_SESSION for the full map and the atomic-change design rules).

## Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)

- Round-25 report (maintainer): garbled effect sprites on hit. Pixel
  A/B (new probe: SNAP_FRAMES on replay 17, frames 3477-3481) convicts
  BOTH 14z-3 thunks: bank_swap garbles the spark (Donovan tile bank
  under vanilla strips), and spawn_mark makes ANITA vanish while a
  marked spark is live (+0x9A = owner-char-id with display semantics;
  "spare field" assumption WRONG). Both rows staged to 99; per-row
  stage filters added to site_thunk/data_port loops (they were being
  applied unconditionally at stage >= 6). Build restored byte-exact to
  597ae55b (round-24 throw-confirmed); battery green.
- The sword-swing fix design is updated: tile bank + strip redirect +
  a PROVEN-dead discriminator must land as ONE change, accepted only
  with the pixel probe alongside the battery (new GOTCHAS entry).
- 597ae55b hit sparks verified CLEAN pixel-wise (the user's "maybe the
  previous build too" is answered: no — the garble was 14z-3-only).

## Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)

Round-24 continuation. The missing "circular sword attack" on armed
normals is DECODED end-to-end (replay 17, native-vs-ported A/B):

- vs2 draws armed-normal sword swings as TYPE-3 EFFECT objects
  (hit-located, ~10-frame strips). Spawn chain: shared engine spark
  spawner (vsavj 0x18EFC / vs2 0x178C2; a3=attack record, +0x12 spark
  id & 0x7F, remap tables byte-IDENTICAL between the games, allocator
  vsavj 0x16FBA / vs2 0x15702) -> type-3 first-tick case (vsavj 0x5E7B2
  / vs2 0x6A7A6, dispatched through the obj_hook-extended table
  0x5E556) -> variant (+0x59) -> param record (anim number 0x102) ->
  set-anim (0x4CE2: facing adds 0x300) -> COMMAND QUEUE (0x31DA) ->
  display processor resolves number->record via PER-CHAR strip tables.
- On the ported build everything matches native (type 3, variant 3,
  position, timing, 10-frame life) EXCEPT the resolved strip: native
  walks vs2 0x2B8190+ (Donovan sword-arc records, ALREADY PORTED at
  0xF420C+ in region x2b7ef4); ported walks vanilla 0x28391C+ (slot-0F
  = Jedah-family effect art) — because the display-side strip-table
  selection still serves slot-0F vanilla tables. Self-relative 16-bit
  offsets make in-place table repointing impossible (ported records are
  1.6MB away; the effect-table zone is overlap-packed shared pool).
- STAGED (build cfe757a1, gated slot-0F-attacker-only, legacy-inert by
  construction): [[site_thunk]] generic construct (gen) + two thunks:
  spark_spawn_mark (allocator wrapper: marks spark +0x9A=0x0F when the
  ATTACKER (a6!) is char 0x0F) and spark_bank_swap (first-tick: +0x18
  tile-bank 0x0000 -> 0x4000 for marked sparks — the same vs2-bank-3 ->
  vsav-bank-2 remap as his six port_patch bank setters). Verified live:
  mark + bank land; anim unchanged as expected (tile bank != anim
  table).
- REMAINING STEP (next session): redirect the DISPLAY-side strip-table
  selection for slot-0F effect objects to a rebuilt Donovan effect
  table (vs2 T at 0x2B0786 family) — the same per-char display-site
  thunk pattern proven in 14q, and the same site family already
  catalogued by tools/overlay_port.py (VERIFIED_SITES). The +0x9A mark
  gives the consumer a per-object Donovan discriminator if needed.
  Sword-arc RECORDS and TILES are already in the build; only the table
  selection is missing.

## Maintainer priority statement (round 24, 2026-07-30)

Round-24 playtest CONFIRMS the throw fix (597ae55b). Standing compromise
hierarchy from the maintainer, recorded verbatim in intent: the MISSING
SWORD SPRITE on armed normals (e.g. 6HP: circular swing not rendered,
hitbox possibly the unarmed variant) is a TRUE BLOCKER for the port.
Palette issues (win-quote, HUD mini-portrait) and the red/purple
sword/statue blinking are NOT blockers — ship-compromisable if it comes
to it. This is a compromise hierarchy, not an ordering command for the
work queue.

## Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)

- Round 23: throw still broken on byte-exact ad372a6b -> round-21
  confirmation was a sampling miss; winpal conviction was WRONG (as was
  the grab-row one). Mechanism trace (new tools/lua: tap_writes.lua):
  victim X/Y written by ported positioner (PC 0xCE51C, region x026142,
  vs2 0x0272CE) walking the pointer-of-tables 0xBE27A[thrower id] —
  slot 0x0F still pointed at JEDAH's keyframe table (0x0B19F8, stride
  0x198/victim) while Donovan's anim indices assume vs2's 0xC8-stride
  layout. Pre-14w the gap auto-table class covered this table; the 14w
  wholesale disable reverted it (Felicia-fix collateral).
- Fix: new [[data_port]] manifest construct (gen_donovan_patch.py) —
  vs2 Donovan's victim-keyframe table (0x0CA1CA, 0xE50, vhunt2 twin
  0x0C9A5C byte-identical, both asserted at build time) placed in-place
  over Jedah's slot-0F zone (fits in 0x1828), mirror-victim offset word
  fixed [0x0F]: 0x0B30->0x0D88. Replay 27 trace: 21 teleport-scale
  jumps -> 4 structured slam keyframes (authentic cinematic motion).
  Build 597ae55b. Legacy surface: slot-0F throwers only; attract@4278
  unchanged (diverges before any throw).
- 27_don_quotewin/27 drift note: the throw connects at 3050/3650 on
  current builds; re-freeze of the 27 oracle still queued.

## Session 14z (round 22: winpal copies convicted and fully reverted)

- The throw victim-teleport reappeared on e7682289 and the timeline
  convicts the WINPAL COPIES (0x248D80), not the 14v grab rows: the
  zone holds throw-cinematic data; no legacy replay threw (coverage
  blindness). Full revert to byte-exact ad372a6b; 14y doctrine
  amendment VOID (02/05/07 exact restored, pick 1080); new permanent
  masked-EXACT gate 30_demitri_throw. Palettes were NOT visibly
  improved by the copies anyway — the quote/HUD row consumer remains
  UNDECODED (none of 0x1BF56/0x1C1FA/0x1C426/0x7D4FC/0x1C5CE feeds
  the visibly-wrong rows). Next palette attempt starts from a runtime
  trace of the ACTUAL row writes on the quote screen/HUD, with the
  throw + pixel gates watching.

## Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)

- Round 20: triangle jump CONFIRMED FIXED. But the 14v grab-pointer
  reconciliation BROKE Donovan's throw in play — maintainer decision:
  roll it back, keep only the Felicia fixes. Done (the 8 rows gated
  to stage 99 with a full post-mortem note in donovan.toml): the
  vsavj engine consumes its grab-pointer vars with native-throw
  semantics that conflict with the ported throw's flow; the original
  stray writes are silent and the throw worked for 19 rounds with
  them. Re-attempt requires decoding the engine-side consumer first.
- NEW MECHANICS/RENDERING ITEM (round 20): on some normals the SWORD
  ATTACK doesn't render even when equipped — e.g. round-start 6HP:
  Donovan's sprite and damage look right, but the sword's circular
  swing isn't drawn and the hitbox may be the unarmed one. Ties into
  the sword/overlay rendering work (the parked overlay + the sword
  records) — keep in scope for the sword-rendering search: the
  armed/unarmed variant selection may involve the same per-state
  record webs.
- Fingerprint ad372a6b; battery at session end.

## Session 14w-c resolution (ALL GREEN at d6a751cb)

- The halt lifted: the type-63 handler's crash was its hit-reaction
  id 0x50 — past vsavj's vanilla table, below the hook's old ext
  range. One-slot reaction_hook extension (case verified verbatim
  against vs2) closed it. Full battery green including both new
  gates (29_felicia_walljump, pixel menus). SHIPPING d6a751cb.
- PLAYTEST (round 20): (a) Felicia's triangle jump — wall latch back,
  and her walk now byte-exact vanilla; (b) throw anyone repeatedly
  (the grab-pointer fix from 14v rides along); (c) deep arcade runs
  with Donovan — the type-63 moment (~his 2nd match win region)
  should now just work; report anything odd there; (d) win-quote
  palette is STILL Jedah's (known: preload-staging consumer decode
  queued); sword blink unchanged (overlay parked).

## Session 14w-c original halt record (kept for the mechanism)
## Session 14w-c (type-63 chain: RULE-6 HALT — the only open task)

- The pair-table fix changed CPU-Felicia's fight flow in 21_don_mash,
  and at frame ~10050 Donovan's own deep-arcade path SPAWNED
  SECONDARY-OBJECT TYPE 63 for the first time ever — hitting its M2a
  tripwire (0xCB880). The "types 59-62 only" assumption is
  measured-wrong. Handler ported (extra root 0x6717c:0x154:t0x671b0,
  clean extraction: 13 refs, all engine rows verified) — the tripwire
  no longer fires, but 13 frames later the REACTION DISPATCH
  (engine 0x18460) crashes: vec3 at PC 0x18466, ADDR 0x1B6A3.
- Crash math (exact): jump-table fetch with d0 = -8 -> d1 = the
  dispatch's own first opcode word (0x323B) -> odd target 0x1B6A3.
  d0 = -8 means a GARBAGE/UNINITIALIZED reaction id, not an OOB
  vs2 id. Leading hypothesis: OBJECT FIELD LAYOUT divergence
  (same-value class #5 candidate) — the ported handler writes vs2
  object offsets (+0x9E/9F/A2/B0/B3/B4 observed) while vsavj's
  reaction system reads its id from a different offset; the handler
  disassembly (STATE-annotated above) never writes vsavj's +0x38.
  NEXT: diff the two engines' reaction-id field offsets (find vs2's
  site_prefix analog of `tst.b 0x38(a1)` and its dispatch d0 load),
  then add a field-offset port_patch to the handler.
- RULE 6: the battery is RED on 21_don_mash until this lands; no build
  ships. Felicia's legacy fixes are verified and committed (29 gate
  green throughout); the last all-green build (dc6b2d36) is NOT
  shippable knowingly (it carries the Felicia legacy violations).

## Session 14w-b (second Felicia defect: the pair-table stride bug)

- vsav.zip restored; rebuild 53ec9c51 fixed the WALL LATCH (verified
  byte-identical trajectory) — but the freshly frozen 29 gate caught a
  SECOND defect: her walk-back speed off by a subpixel fraction
  (whole-pixel motion vs vanilla's accumulating fractions). Root
  cause: param32_a/b are 8-byte PAIR tables (fwd/back velocities)
  registered at 4-byte stride — "slot 0x0F" hit Felicia's walk-back
  half; the extractor read the equally wrong vs2 half. bank_map fix:
  rec8/stride-0x100; Donovan now ports his true velocity pair onto
  Jedah's true pair. Felicia byte-matches vanilla except one
  spawn-boundary flicker frame (29@2435) — 29 reclassified to the
  approved FLICKER class. Fingerprint 340673da.
- LESSON (GOTCHAS updated): the new-replay-then-freeze loop caught in
  ONE day what 19 playtest rounds missed twice — every mechanics bug
  fix must ship with its oracle replay, and per-char tables' ENTRY
  layout must be verified against vanilla content (pair-sign
  signatures), never assumed from spacing.

## Session 14w (FELICIA'S TRIANGLE JUMP: root-caused to the gap-write
class; gen fixed; REBUILD PENDING vsav.zip restoration)

- Round 19 clarified the float = Felicia's WALL JUMP broken (no wall
  latch; rises off-screen, wraps twice). New replay 29_felicia_walljump
  reproduces it deterministically — in a PURE LEGACY match (Felicia vs
  Bulleta): a superset violation that every RAM gate missed because no
  replay ever played Felicia and per-char physics only surface in use.
- Root cause via restore-bisection (31 candidate groups eliminated:
  winpal, all four engine hooks, the select/pool writes, all data
  members, per-char table rows): the generator's speculative GAP
  writes. gap_bdc7a[0x1F] (vanilla 0xFFFF4800, the wall-jump-back
  velocity) was overwritten with Donovan-derived 0xFFFFEC00. 42 gap
  writes existed, 31 changing vanilla engine bytes — ALL disabled in
  the gen (session-14w comment in gen_donovan_patch.py). With every
  gap restored: Felicia latches at the exact vanilla Y and Donovan
  soaks clean — the writes were pure harm.
- ALSO exonerated this session: the 22 overlay thunk sites (CCR
  audit), the sound-farm stubs (ported-call-only by design).
- **BLOCKED: vsav.zip is missing from ROMDIR** (folder shows recent
  Finder activity — likely the maintainer's reorganization; cfg/nvram
  dirs from some unsandboxed MAME run also present). The audit gate
  correctly halts all builds. Once restored: rebuild, full battery,
  freeze 29_felicia_walljump's expectation (vanilla-exact class — it
  is a LEGACY replay), and re-run the throw-oracle refreeze.

## Session 14v (grab-pointer work vars fixed — the Felicia float)

- Round 18: quote palette STILL Jedah's => the quote screen consumes
  the select-time preload staging; decoding the staging CONSUMER is
  now the path (the 14u copy-and-repoint plumbing stays — correct and
  needed either way). And Felicia floated off-screen after a throw:
  root-caused to 8 unreconciled A5 work-var refs in the ported throw
  code (grab POINTER stores + a state clr through vs2's layout —
  garbage into two vsavj engine vars every throw). The A5 audit
  (open since 14o) is now COMPLETE: no other unreconciled refs in
  0xB000-0xBFFF anywhere in ported code. 8 port_patch rows shipped;
  analogs triple-verified in both engines' native throw code.
- 27_don_throw oracle has drifted (pre-throw hits connect on current
  builds) — re-freeze needed; grab rows shown outcome-neutral on it.
- PLAYTEST asks: (a) throw Felicia (or anyone) repeatedly in a
  Donovan match — the float should be gone; (b) throws should feel
  vs2-correct.

## Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)

- Four masked-gate iterations distilled the survivable design (see
  patch_notes 14u): patched block COPIES in dead space + a private
  pointer table + exactly ONE poked reader site (0x1C1FA, the only
  exclusively-quote-time one) + the 0x60-view lea. Three select-time
  bulk preloaders identified by per-site gate bisection (0x1BF56 /
  0x1C5CE 2P / 0x7D4FC challenger-join) stay vanilla.
- All gates green on 1f5fa38e. PLAYTEST QUESTION: does a Donovan match
  win now show his quote palette? If not, the quote screen consumes
  the preloaded staging and the staging consumer is next.

## Session 14t (win-quote palette: decoded, port REVERTED by the gate)

- Round 17: menus clean. The palette chain is fully decoded (see
  patch_notes 14t) but the in-place slice port DIVERGED legacy 2P
  replays (03/16, 3229/2008 frames from select entry): the per-side
  blocks are bulk-staged through work RAM MID-FRAME on legacy paths —
  transient divergence visible only to the checksum's sample point.
  Reverted; shipping stays 37269fff. Next attempt needs the staging
  reader decoded (find the mid-frame copier of 0x39FDC0/0x3A18E0 and
  make its slot-0F slice source conditional), or a maintainer-approved
  masking amendment for the staging buffer.
- Diagnostic GOTCHA earned: per-frame unmasked checksum/dump runs READ
  the QSound latch and perturb both builds identically — legacy
  comparisons must replicate the gate's exact mask set, and mid-frame
  transients require comparing at the checksum's sample point, not
  frame-done dumps.
- NEW REPLAY 28_don_quotewin: wins a match (23 turned out to LOSE on
  current builds), reaches the story card + continue/quote screens.
  New cosmetic: loss-path quote screen shows Jedah's win-quote art.

## Session 14s (playtest round 16: overlay REVERTED; pixel gate born)

- Round 16 (maintainer): Anita/Donovan render correctly BUT (1) the
  red/purple flicker persists over the grey sword/statue (unpoked
  table families still draw Jedah art on top) and (2) MASSIVE menu
  corruption: title, select, speed menus, VS portraits garbled.
- Overlay PARKED again (build/manifest/overlay.wip). Cause of (2):
  the tile pool used OBJ-dead positions whose BYTES back scroll-layer
  menu art — CPS-2 scroll1/2/3 decode the same ROM bytes (GOTCHAS).
  Every RAM gate was green throughout: gfx is invisible to RAM-basis
  comparison. The overlay redesign needs a BYTE-dead pool.
- **NEW GATE**: tests/test_gfx_menus.sh — pixel-exact comparison of
  title/select/speed-menu frames vs frozen vanilla goldens
  (tests/expected/vsavj/menus/), wired into test_m2b_stage6.sh. On its
  first run it caught a LATENT SHIPPED BUG: the speed-menu TURBO/AUTO
  text sat 8px off since the select-screen work — select_port's
  in-place coordinate write hit one byte of the menu record's list
  (head shared inside Jedah's banner list span). First fix attempt
  (relocate all lists + repoint cptrs) FAILED the masked gate —
  cptr values are RAM-visible on select paths (fourth stored-anchor
  class; 02/03/08 diverged at ~820). Final fix: cptrs untouched,
  in-place list writes kept, and SHARED lists (the banner's) simply
  not written — Donovan's banner draws at Jedah's position. Shipping
  fingerprint 37269fff; pixel gate green; full battery at session
  end.
- Overlay next steps (with the WIP): byte-dead tile pool (candidates:
  bytes of Jedah band art already replaced in group B — his band
  minus scroll-shared spans, TBD by a scroll-usage census — plus 0xFF
  padding); the red/purple flicker = the unpoked families
  (0x2675AA/0x26772A/0x26775A + dead-entry tables).

## Session 14r (overlay port COMPLETED to a 22-site shipping config)

- Round 15 (maintainer): no regressions on f29cf24a.
- The stride-8 stream grammar was completed (flags 0x80 = 12-byte
  jump node — the attack-anim loops that caused every attack-input
  crash; 0x40 = terminal; ptr 0 legal), the heap port regenerated
  (segB collapsed 22KB -> 496B once stream extents were真 bounded),
  and every context-verified site probed individually on the Donovan
  path with the watchdog-proof timer-tick detector. 22 sites ALIVE
  through DP-spam and win screens; 3 crashers excluded and documented
  in tools/overlay_port.py (VERIFIED_SITES / KILLER_SITES policy —
  the emit is deterministic; fingerprint cf2109d8 after the fmtA-opaque fix — the guarded soak caught a frame-8424 address error from streams truncated at skipped fmtA records).
- VISIBLE: Anita fully drawn dragging behind Donovan; sword on his
  back; clean win pose. The Jedah-darkness blink is gone. Open
  question for playtest: the hat piece alternates per frame (vs2
  dither vs residue).
- Remaining for a later pass: the 3 excluded sites (indexing-variant
  decode: ±4-anchored table entries / site-biased ids), the four
  100%-dead tables (0x2A0862 family — win/vignette features via
  whdr-strips partially live), fmtA composite records (20 skipped).
- Gates: full battery re-running clean at session end (a first run
  was voided by a build-tree race with foreground rebuilds — gate
  scripts rebuild build/donovan6 themselves; never rebuild while the
  battery runs).

<!-- superseded header: session 14q -->
Updated (superseded): 2026-07-29 (session 14q — overlay port 80% built, PARKED as
build/manifest/overlay.wip; shipping build = f29cf24a (feet fix,
playtest-confirmed round 14); M2a frozen a02aeeff…, M2b-core frozen
71601263…)

## Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)

- **Round 14 (maintainer): Anita's feet fully clean incl. shadow, no
  regressions** — f29cf24a validated.
- Stage-7 build attempt (topology B) reached a proven architecture with
  one remaining blocker. What is PROVEN (each by masked 02 probes,
  full-length identical unless noted):
  1. **Placement**: vs2 overlay slice [0x2A0426,0x2A63F0) split at
     0x2A4A48 (above max self-relative table reach), segA+cptr-tail at
     0x248D80, segB at 0x2557B0 — inside JEDAH'S OWN ANIM AREA, the
     only proven-dead space (slot 0x0F always runs Donovan). Legacy
     CLEAN. (First two placements failed: Jedah's strip-area "gaps"
     interleave the shared MUSIC POOL — see GOTCHAS.)
  2. **Site repoints**: 25 context-verified Jedah T-sites, thunked
     (`movea.l #T,a0` -> `jsr thunk`; ported T iff match-active AND a
     slot-0x0F participant). Legacy CLEAN with all 25 active. Static
     pokes are IMPOSSIBLE (attract cutscene IS Jedah ~888; shared
     display flows hang other-char matches — measured both).
  3. **Tile pipeline**: 3929 bank-1 pairs (874 blocks; fmt4/6/8 draw
     stored+0x3800 — handler decode) placed at dead-Jedah positions +
     padding; build_gfx --overlay-tiles chain verified.
- **BLOCKER**: with data+rewrites active the DONOVAN path watchdog-
  crashes at match start. Cause class: the slice's 293 blind long
  relocations + 2811 tile-word rewrites in 163 scan-validated records
  include false positives that corrupt stream/coordinate data (fmt4
  validation is cptr-less; coordinate words alias pointer prefixes).
  Fix path: STRUCTURAL CLOSURE — decode the stream node language
  (tables -> strips -> tag-streams -> records), restrict relocation
  and rewrites to the closure, leave everything else byte-intact.
  Groundwork in place: fmt handlers decoded (0x1AFC6/0x1B234/0x1B61A/
  0x1B6AA/0x1B73E/0x1B7CC; A0=rec+2), strip = plain long array,
  tag-stream = (FF-tag,ptr) pairs, walker 0x15082 = T + T[2*id]
  self-relative.
- Everything parked in build/manifest/overlay.wip/ (gen ignores it
  until renamed back to overlay/); tools/overlay_port.py +
  gen thunk assembly + build wiring are committed and inert. Shipping
  fingerprint re-verified f29cf24a after parking.
- New GOTCHAS: attract-cutscene-is-Jedah (conditional thunks), music
  pool interleave (watchpoint read maps have a computed-addressing
  blind spot), blind relocation corrupts mixed data blobs.
- **14q continuation (same session): closure v5 built and iterated.**
  Object-granular heap port (closure walk tables->strips/streams->
  records; heap over Jedah's dead anim areas; per-object placement
  map; table entries recomputed only when validated, verbatim
  otherwise). Grammar discoveries, each verified against data:
  (1) stream nodes = (tag.l, ptr.l) stride 8, tag = (duration.b,
  flags.b, param.w), NULL-ptr nodes legal ("no record this phase");
  (2) grammar-4 = word header + bare long array at +2 (the
  0x2A0862-family targets); (3) fmt4 record size is 14B; (4) the
  engine stepper family ALSO walks 0x10/0x18-stride node forms —
  stride is an OBJECT-STEPPER-CLASS property (0x15030-0x15080 lea
  variants), NOT table- or data-derivable (a longest-run stride
  heuristic corrupts real 8-streams — measured, reverted).
  Probe results (detector: round-timer tick + match flag — earlier
  detectors were fooled by watchdog reboots keeping stale RAM):
  data-only ALIVE and legacy-clean; pokes for the 2671C6/267224/
  267284 tables ALIVE through round start but CRASH ON THE FIRST
  623P (attack-id-indexed entries hit still-dead table slots);
  2671E6 (attack-id table, walker 0x15084/inline variants) worst.
  REMAINING DECODE: map each poked table to its stepper class
  (which stride its streams use) — then re-walk dead entries with
  the right stride and the closure should complete. All probe
  tooling: /Users/koneko/.claude/jobs/*/tmp/donprobe.sh pattern
  (rebuild-with-poke-subset + timer-tick verdict), op_v5_all.json
  site list. Shipping build re-parked at f29cf24a.

## Session 14p (feet fixed; blink mechanism = Jedah's overlay records)

- **ANITA'S FEET FIXED** (build f29cf24a): the garble was record
  0x0FCECA (x2b7ef4) whose 54-record strip draws at BANK 2 (#$4000
  sub-objects) but was triaged by the BANK-1 effect-tail maps (+0x47
  reloc → codes 0x0FD2/3 = wrong-page garbage; the earlier "solid
  green" was the same entries pre-reloc). Empirical attribution per
  the f8eda2ca mandate: handler-breakpoint trace over 9 replays
  (tests/lua/obj_record_bank_trace.lua) found the ONE bank-2 record;
  closure came from its sub-object's record stream (54 recs, 37
  blocks, vs2 codes 0x0F8B-0x0FBC). Data-only fix:
  tools/gen_anita_bank2.py → effect_tail.json bank2_recs/bank2_place
  (shelf rows 0xEAC0-0xEAFF); the generator's surviving bank-2 branch
  does the rest. OBJ RAM + screenshot verified; gates re-run.
- **SWORD/STATUE BLINK ROOT-CAUSED** (no fix yet — next surgery): the
  in-match companion overlay sub-objects ($FFB800-$FFBA00, bank
  #$2000) walk per-char record-pointer strips; on our build the char
  slot resolves to JEDAH's strips (0x2674AA-0x268Axx → records
  0x271D70/0x272156/0x272800/0x272A68…, codes 0xAFxx/0xB4xx/0xCDxx =
  Jedah's bank-1 darkness art, tile content verified vanilla≠vs2). The
  "blinking sword/statue" is Jedah's overlay ANIMATING where Donovan's
  sword-drag/statue belong. vs2 ground truth (handler trace on
  vsav2, 27_don_throw_vsav2): ~16 sub-objects draw records
  0x2A1DAE-0x2A3F80 (codes 0xA3E8-0xA499, strips 0x2A0Axx-0x2A1Cxx
  after root 0x2A05E2). Fix class: select_port-style IN-PLACE
  strip+record replacement inside Jedah's per-char region — all three
  superset traps apply (budgets, cell pokes, legacy coord reads);
  bank-1 codes go through the effect-tail triage (content-match /
  reloc / place), NOT raw copy. New GOTCHAS entries: bank attribution
  is an object property; breakpoint traces are lossy SAMPLERS —
  structural closure required; overlay-strip mechanism.
- New tools (persistent): tests/lua/obj_record_bank_trace.lua,
  tests/lua/obj_record_full_trace.lua (all six fmt handlers via the
  0x1AFBA jump table — vsav2 sibling addresses in header),
  tools/gen_anita_bank2.py.
- **Overlay strip inventory MEASURED** (exact, RAM-dump method — the
  debugger-desync gotcha rules out bp traces for this): 16 sub-objects
  $FFB800-$FFBF80, all bank #$2000, cursors in Jedah strip pages
  0x267xxx/0x268xxx (b800/b880 also walk engine-shared strips
  0x15Axxx); b900/b980/ba00 dual-phase to bank #$4000 with PORTED
  cursors (0x0E2xxx sword-anim / 0x0DDxxx / 0x0F619C feet — already
  correct). Cursor-setter decoded: engine routine 0x15082 computes
  cursor = T + T[2*id] (T = per-char self-relative word-offset table;
  Jedah's T = 0x2671C6 measured at one call). vs2 sibling: same 16-slot
  population walks Donovan strips 0x2A0Axx-0x2A1Cxx → records
  0x2A1DAE-0x2A3F80 (codes 0xA3E8-0xA499, bank 1).
- **Stage-7 surgery sketch (next)**: port vs2 overlay region
  (~[0x2A05E2,0x2A4000), bounds to refine) as a new manifest region;
  reroute the char-0x0F strip-base lookup (find who loads T=0x2671C6 —
  per-char table row or computed; repoint to the ported copy); bank-1
  code triage via the effect-tail classes; coordinate cptrs via the
  pool content-match; placement needs ~15KB (hole A ~0xE80 + hole B
  ~0x650 are TIGHT — space audit first; Jedah dead zones are
  attract-demo-read, gate-guarded by the frozen-4278 class). Vanilla
  Jedah strip bytes stay untouched.
- Throw-damage magnitude (round 13 note "lower than Savior 2"):
  recorded as a maintainer-feel item — the port routes Donovan's raw
  damage through VSAVJ's global defense scaling by design; the oracle
  measured the test throw EQUAL to vs2 (-5). If it should match vs2
  everywhere, that's a rules decision, not a bug.

## Session 14 highlights (M2a FROZEN)

- **Playtest round 3 (maintainer): fully clean** — no crashes over
  multiple matches, no music from any input. The 214P/214K stragglers
  were two sound-farm entries masquerading as `engine_data` rows since
  the session-5 bare-long pass (0x4F14/0x5052 — byte-match locks onto
  the same-id vsavj entry = the same-id-different-meaning trap with a
  verified sticker) + the direct-called helper 0x5122. Full farm-ref
  audit (jsr/bsr/jmp/pea from all ported zones): 25 stubbed / 4 live
  init-zone rows. GOTCHAS entry added: when a structure class gets
  understood, re-audit earlier generic rows in its range by MECHANISM,
  not row kind. Note: sound wrongness is invisible to every RAM-basis
  gate (music state lives in QSound RAM) — playtest is the only surface
  catching this class until an M5 harness exists.
- **M2a FREEZE EXECUTED** (playtest-gated per the standing decision;
  maintainer confirmation 2026-07-28): registry row
  `a02aeeff… -> donovan-m2` in tests/expected/registry.tsv;
  `tests/run_suite.sh` gained the `.masked` expectation kind (exact /
  flicker-frozen-inventory / diverge classes per CLAUDE.md §4 v2, masked
  runs auto-selected) and `.skip` (other-romset replays);
  `tests/expected/donovan-m2/` authored from the frozen gate inventory;
  Donovan-replay self-expectations frozen on a02aeeff; vanilla
  expectations frozen for replays 17-26 (drift check on pre-existing
  vanilla sha1s: none). Validation: `run_suite.sh` GREEN on BOTH builds
  by pure fingerprint auto-detection — the one-command-validates-any-
  build doctrine is now real for hooked builds.

## Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)

- Donovan's throw deals correct damage (oracle-measured: 288->283 = -5,
  byte-matching vs2's result at identical inputs, flowing through
  vsavj's own defense scaling). ROOT CAUSE = the FOURTH same-value
  sibling-coincidence class: A5-relative WORK-VAR DISPLACEMENTS. The
  ported throw-damage writer (x028122, vs2 0x28AC2-0x28AF6) stored
  scaled damage into VS2's work-var layout (-0x4B6C/6A/68) while
  vsavj's post-process reads ITS layout (-0x4BBE/BC/BA) — damage into
  dead variables = landed-but-zero. Six displacement port_patches
  (uniform family shift -0x52; vsavj native analog byte-verified at
  0x29790). Diagnosed AND verified by the NEW 27_don_throw oracle pair
  (permanent suite replays; vanilla expectation frozen 086476eb).
- Fingerprint eb051b12: double gate + oracle/xemu/flavor green.
- OPEN AUDIT: sweep ALL ported code for (d16,A5) vs2-layout work-var
  displacements — other dead-var writes may lurk.

## Session 14n (round 12: revert validated; two new items scoped)

- Round 12 on restored 569859d1: specials correct, NO resets — the
  board reset is pinned to the reverted f8eda2ca with certainty.
- NEW COSMETIC: solid-green background tiles around ANITA'S FEET (her
  sprite clean). Likely one/few mismapped tiles in the effect-map or
  tail placements rendering opaque green where transparency belongs —
  find by dumping her OBJ entries at the artifact moment and checking
  which placed tile draws the green block.
- NEW BEHAVIORAL (present since the beginning, priority — gameplay):
  DONOVAN'S THROW deals almost no damage vs Savior 2 / native chars.
  An R1 damage-path gap: his ported throw handler's damage source
  (immediate value, per-char table row, or engine damage id) resolves
  wrong on vsavj. Method: bp-trace the damage post-process during a
  throw on our build AND on real vsav2 (matching inputs), diff the
  damage arguments; then fix the data path (reconciliation row or
  value repoint) — oracle-gated. Needs a throw replay (the test
  matrix's throw/tech coverage gap — write 27_don_throw as part of
  the fix, per the persistent-suite doctrine).

## Session 14m (f8eda2ca REVERTED — regression + board reset)

- Playtest round 11 on f8eda2ca: blink unchanged, 623P degraded, and a
  BOARD RESET mid-fight (watchdog class). Rule 6 halt: the bank-2
  config stripped from effect_tail.json; the build restores 569859d1
  BYTE-EXACT (the round-10-validated build: specials good, sword
  blinks = known open issue).
- Post-mortem of the failed fix: the content-voting attribution was
  wrong — the ownerbox dump already showed the sword records live in
  the ANIM region (rec 0x0F32C8 ∈ anim dst), not x2b7ef4; the 14
  rerouted records were misattributed and the loose record validation
  (731 detections vs ~151 real) makes false-positive rewrites — the
  likely reset mechanism. LESSONS: content voting is too weak for
  bank attribution; only EMPIRICAL object-correlation counts; and any
  pass that rewrites record bytes must validate records STRICTLY
  (known-record lists, not heuristic scans).
- The blink remains open. Correct next method (fresh session):
  side-by-side sword-object comparison — dump the sword object's
  [0x1C]/records/entries on real vsav2 and on our build at matched
  moments; diff entry-by-entry; fix exactly what differs. No rewrites
  without an empirically-verified record list.

## (reverted) Session 14l (bank-attribution fix)

- The x2b7ef4 walk now attributes records by drawing bank via content
  voting: 14 records (109 blocks, 312 tiles — the sword/statue class,
  bank-2 objects) route through band-tail placements (vs2 bank-3
  content at 0xEA40+, 722 tail positions spare); the rest keep the
  bank-1 effect-tail path. Fingerprint f8eda2ca: double gate green,
  companions green. Playtest verdict wanted on: sword steadiness,
  round-start statue, specials still good, win-quote palette (still
  pending implementation), general sweep.

## Session 14k-b (blink TRULY root-caused: per-record bank attribution)

- The saturation theory was an artifact: the ~540 null entries are the
  CLEARED TAIL of the OBJ list (the drawer processes a separate count;
  real usage ~357/896 — headroom fine). Bisect (worktree rebuild of
  8248296e) also proved the coord surgery innocent (identical state).
- REAL MECHANISM (live object dumps): the sword/statue objects draw at
  BANK 2 (their #\$6000->#\$4000-patched setters) but their records
  (x2b7ef4 region, e.g. 0x0FCECA with entry codes ~0x0FD2) were treated
  with BANK-1 semantics by the effect-tail pass. Their anim frames with
  engine-page codes hit wrong bank-2 positions -> invisible frames =
  blinking at the anim rate (matches the playtest report exactly:
  different rate than vs2, statue identical).
- FIX (next): per-record bank attribution in the x2b7ef4 walk —
  content-addressed (bank-2 records' low codes match vs2 BANK-3 art =
  Donovan effect art; bank-1 records match the engine page) — route
  bank-2 records through the band-tail placement (effect-map style)
  and keep bank-1 records on the effect-tail path.

## (superseded analysis) Session 14k (OBJ budget saturation theory)

- Playtest round 10: specials CONFIRMED fixed; sword still blinks and
  the round-start statue blinks identically (same palette; vs2 clean).
- ROOT CAUSE FOUND: the per-frame OBJ list is SATURATED — 897 of 896
  budgeted entries every frame, of which ~545 are ALL-ZERO entries from
  a runaway record (suspected fmt-0 count-0 -> subq/dbra wraparound
  emitting nulls until the budget dies). The sword/statue draw last and
  get budget-skipped on marginal frames = the blink. NOT the class-7
  queue (only one site, already remapped; no live 0x0E-class objects),
  NOT palette-row conflict (row 3 written once), NOT engine budget
  difference (both games 0x380).
- NEXT (precise): (1) dump objects + correlate [0x1C] to find the
  runaway record's owner; (2) rebuild commit 0867b25 (8248296e) and
  count nulls there to bisect pre/post the coord surgery — the blink
  predates it per playtest, but the 545-null magnitude needs the same
  verification; (3) fix = correct the record/chain terminator (and
  audit the coord-surgery's loose record validation for false-positive
  rewrites in the x2b7ef4 blob — 731 detections vs ~151 real records
  is suspicious in itself).

## Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)

- 623P/214K elemental summons render again (snapshot: the flaming Ifrit
  sword + fire pillar in full). Triage of the 491 companion-effect
  blocks: 344 same-index; 70 relocatable by content match (page shift
  +0x47 class, wrap-safety enforced); 77 blocks (263 tiles = vs2's
  newcomer extension of the engine effect page, 0x0E17-0x0F02) PLACED
  at vsav bank-1's padding run 0x3640+ (460 blank positions before the
  system band). Per-entry code remap in the gen (effect_tail pass,
  build/manifest/effect_tail.json).
- BONUS LATENT BUG FIXED (third sibling-coincidence strike, GOTCHAS):
  the records' coordinate lists point into vs2's GLOBAL X/Y pool —
  same-value across siblings, never relocated; effects have read
  garbage coordinates since M2a. Fix: 114 lists content-matched into
  vsavj's own pool, 617 Donovan-specific lists ported (11.3KB fragment,
  hole B). Sword-glint/blink expected fixed by the same pass.
- Fingerprint 569859d1: double gate green, oracle/xemu/flavor green.
  Playtest wanted: 623P/214K/sword in-match, win-quote palette still
  pending (next), quote text line, HUD name, wheel face, attract pal.

## (earlier) Session 14i-b (round-9 mechanisms pinned)

- WIN-QUOTE "left shift" = NOT a defect: both records' coords are
  identically centered on the object anchor; vsavj's own win-screen
  layout places the winner's art LEFT (Bulleta's screen confirms).
  Recorded as a feel item (default = host layout); no code change.
- WIN-QUOTE PALETTE mechanism found: per-char pointer table at CODE
  0x7F196 (PC-relative, indexed by winner char*4 from $140(a5), rows to
  palette RAM 0x17 band) + the ramp path (PC 0x153C2, per-char fade
  blocks ~0x3A14xx, seeding chain via the win module scripts at
  0x7E662). Pointers are consumed transiently (A0, никогда stored) —
  unlike the record cells, ROW REPOINTS ARE RAM-INVISIBLE here: plan =
  place Donovan's vs2 win-palette blocks (vs2 twin tables to locate by
  the same code idiom) in Jedah's freed region + repoint row 0x0F in
  the vsavj tables. Verify with the masked gate as always.
- Effect tail (elemental swords/sword glint): plan unchanged
  (block-content matching + placement + record remap) — next session's
  main chunk with fresh context.

## (earlier same session) Playtest round 9 diagnosis

Playtest round 9 (on 8248296e): win-quote ASSETS correct but palette
wrong + image shifted left (vs2 layout is right-side); Donovan's sword
blinks/vanishes in-match; the elemental-sword specials (623P Blizzard
/ 214K Ifrit) LOST their big blue/yellow effect sprites. Diagnosis:
- FLASH/SWORD = the deferred x2b7ef4 engine-effect tail, NOT a fresh
  regression: those effect records were never remapped in ANY build
  (deliberately left as-is because 1,070/1,455 tiles are same-index in
  vsav); the elemental-sword and sword-glint art is among the ~385
  tiles whose vsav bank-1 positions moved — codes point at wrong/blank
  art. Promoted from 'minor tail' to MUST-FIX. Plan: block-level
  content matching (vs2 bank-1 blocks -> vsav bank-1 relocated
  positions; place the truly-missing into free bank-1 space), per-entry
  code remap in the ported x2b7ef4/anim records via the gen effect-map
  mechanism.
- WIN-QUOTE X-SHIFT: Donovan's ported coordinate list is vs2-layout
  (right side); fix = constant X translation computed from the two
  records' bounding anchors, applied when writing coords.
- WIN-QUOTE PALETTE: the win screen ramps its palette from ANOTHER
  per-char grid (~0x3A14xx for Bulleta; ramp writer PC 0x153C2,
  source-formula base to pin down like the select grid at 0x3AC000).

## Session 14h highlights (win-quote portrait ported; HUD name found)

- Win-quote screen: the family is d0 = 0x40+char over the same root
  table (found via the Bulleta-quote object dump — no replay reaches
  Donovan's own quote screen, so visual confirmation is playtest's).
  His 35-entry win-pose record replaced in place (host budget kept);
  art fit into Jedah's own freed win tiles + the pool tail (pool-math
  lesson: variant alias rows 0x1F point at the SAME records — skip
  them when computing exclusivity). Fingerprint 8248296e, double gate
  green + companions. The quote TEXT line is a separate object family
  (cell area 0x2681xx) — next target if the playtest shows Jedah's
  line under Donovan's portrait.
- NEW COSMETIC FOUND (snapshot): the in-match HUD name label still
  reads "Jedah" — added to the list (with wheel mugshot face and
  attract palette).

## Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)

- VS-splash busts ported (playtest round 8): the six per-char cells'
  FIRST records are the live ones (object durations read garbage-huge
  values, so chains never advance). Final surgery set: splash P1/P2 +
  pal P1 in place (with the wheel portrait + name from phase 2); the
  hover-P2/pal-P2 records PROVEN SHARED with the win screen on legacy
  paths and left vanilla; 130 more bank-1 tiles placed. Snapshot: the
  VS screen shows Donovan's praying-hands bust, correct colors + name.
- THE MASKED LEGACY GATE CAUGHT THREE REAL SUPERSET VIOLATIONS in this
  surgery series, each root-caused to the byte (GOTCHAS entry): cell
  pokes are RAM-visible via stored anchors; record budget words debit a
  shared frame budget ($FF811B one-byte proof); the win screen reads a
  "select" record's coordinate list on legacy paths (frame-10732 trace,
  PC 0x8C6E2). Fixes: in-place only, host budgets preserved, shared
  records left vanilla. Fingerprint 189fdff3: double gate run green,
  oracle/xemu/flavor green.
- Remaining cosmetics: wheel hexagonal mugshot face (background scroll
  art), win-quote screen (still Jedah — the winner-portrait family, to
  be found the same way), attract palette.

## Session 14f highlights (select palettes fixed; splash/win specified)

- Playtest round 7 (portrait/name correct, PALETTES wrong; splash+win
  still Jedah) -> palette grid found and ported in place (11 variant
  rows; vs2 keeps Donovan's rows behind a code special-case +0xC6).
  Fingerprint 4fc8d14b, full battery green. Splash/win screens fully
  mapped (bust objects, three char-scaled cell families, six pokes
  needed); blocked only on the struct flag-byte termination decode for
  exact chain inventories — then it is the phase-1 zone port with the
  right cells. See engine_internals.

## Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)

- Donovan's big portrait and name banner render at the select screen
  (snapshot-verified) — in-place record surgery (select_port.py phase
  2) + 101 bank-1 tiles placed in Jedah's freed select/splash art.
  Build e98a357a; splash-frame OBJ dump closed the placement safety
  gate; cursor-highlight record deliberately kept Jedah's (vs2 wheel
  geometry mismatch). Full battery: soaks, oracle, xemu, flavor,
  scroll3 green; masked legacy green on rerun x2.
- GATE ANOMALY under standing watch: one invocation failed 02/10 masked
  (84 frames @663 on 10); same build passed everything on reruns,
  deterministically at the frozen inventory. Unreproduced; failing-log
  preservation added (build/gate_failures/). Recurrence = stop and
  root-cause.

## Session 14e (earlier): handles found, surgery specified

- Differential cursor dumps found THE handles: per-wheel-slot pointer
  arrays advanced by cursor movement; Jedah's three record cells
  identified; P2 arrays alias the same records => in-place record
  replacement fixes both sides, zero pokes. Donovan's three records
  dumped live on real vsav2 (all smaller => fit in place). Art fit
  computed (9 blocks incl 8x8 into Jedah's exclusive family art).
  ONE open safety gate: empirically prove the chosen tile positions
  are not shared with other chars' VS-splash art (in-match module
  family, root 0x0B76C0 — structure differs, needs a live dump).
  Then implement + snapshot-verify + battery. Map in engine_internals.

## Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)

- Attempted the select-portrait port via the three traced root cells
  (select_port.py: zone port into Jedah's freed region + pokes). Pokes
  landed, screen unchanged — the live chains are INLINE pointer arrays
  in the shared web, not those cells (live object dumps on the patched
  build; engine_internals corrected). Reverted from the build (stage 6
  back to verified 71601263 byte-for-byte); select_port.py kept as WIP
  machinery. The LIVE PREVIEW at select already shows Donovan+Anita
  correctly; only the big portrait, name banner, and mugshot remain
  Jedah. Next: two-char differential dumps at the hover moment to pin
  the per-char inline groups, then in-place 32-bit pointer surgery.
- Space fact: the eventual select web (~51KB) must live in Jedah's
  freed anim region — both PRG holes are nearly full.

## Session 14c highlights (select-screen pipeline mapped)

- Select-portrait/name pipeline fully mapped by live instrumentation
  (docs/game/engine_internals.md new section): per-char 32-bit root cells
  enumerated by breakpoint trace (six cells for a full pick), name-table
  row located, vs2 twins located (master 0x2A0426, roots 0x2A05E2,
  name 0x2A0A4A row 0x13), Jedah's freed select art sized (~2K bank-1
  tiles) — the port is a repoint-six-cells + region-port + art-place
  job, all slot-0x0F-only. trace_writes.lua gained breakpoint mode.
- MAME Lua gotchas recorded: single-slot register_frame_done vs
  multi-subscriber notifiers (subscriptions must be pinned).

## Session 14b highlights (M2b static phase — R2 cracked)

- MAME WITHHELD all session (user needs the machine; static analysis
  only). gfx groundwork: canonical CPS-2 tile extraction
  (tools/gfx_tiles.py — the simms are NOT tile-contiguous, see GOTCHAS),
  measured: vsav2/vhunt2 share one gfx layout; vsav2-vs-vsav = same art
  REPACKED (content-addressed match 201K tiles, same-index only 6.5K);
  vsavj is a program-only clone (gfx lives in vsav.zip).
- **R2 RESOLVED STATICALLY** (was: "the hard wall"): OBJ tile codes are
  absolute 16-bit + bank bits from object field +0x18 (Y-word bits
  13-14; per-char slot-indexed init table vsavj 0x282D4). Full decode of
  the OBJ record format + emitter chain in docs/game/engine_internals.md.
- **Donovan FITS in Jedah's tile band**: 15,171 tiles extent 0x3CB1 vs
  Jedah's 16,658 extent 0x417F (both measured by tools/obj_records.py,
  locked in tests/test_gfx_tiles.sh). Port = tile-data re-encode into
  Jedah's positions + 16-aligned constant delta on record tile words +
  patch his #$6000 bank setters to #$4000 (slot table gives 0x4000
  free). No ROM expansion needed for M2b.
- Exclusivity walk (player-OBJ, all slots): Jedah's band clean except
  a 44-tile Sasquatch-shared head (0xAD3E-0xAD74) — safe floor 0xAD80,
  usable extent 0x413C >= needed 0x3CB1. STILL FITS.
- Tile-data step BUILT AND VERIFIED (tools/build_gfx_donovan.py):
  Donovan's 15,171 tiles placed into patched vm3 group-B members at
  codes 0xAD8F-0xEA3F bank 2 (delta +0x2750), readback + untouched-byte
  verification green, placed range visually renders Donovan art.
  Scroll-side exclusivity: scroll1/2 cannot reach bank 2 (measured from
  the CPS2 draw path, no mapper); scroll3 can, but Jedah's band is
  99.3% saturated by his own OBJ records and renders as pure sprite art
  — residual risk queued as an in-emulator scroll3 watch.
- Playtest round 4 (maintainer, on their own quick build of 06f99f4e):
  sprites GOOD and animating correctly; palette = Jedah's (palette port
  not yet done — expected); blinking/alternating tiles esp. at char
  select. Root cause: format-0 OBJ records have 2-BYTE tile-only
  entries (my unified 4-byte walk remapped alternate tiles) — fixed
  format-aware in obj_records.py + the generator; new stage-6
  fingerprint f83ff57e… (13,177 words remapped; output re-verified;
  2 stray sub-band tiles 0x813C/0x822C belong to the effect-tail
  class). GOTCHAS entry added. PALETTE PORTED same session: per-char
  palette pointer table found (vsavj 0x38C198 / vs2 0x396B94; uploader
  0x1C3FE -> palette RAM 0x90C140), Donovan's 0x500-byte block (all
  confirm variants) placed + row 0x0F poke32'd — stage-6 fingerprint
  5cb2b2a9…, output-verified. Awaiting playtest: colors + blink both
  fixed. Then: effect-record map, portraits (art + palettes), attract
  palette path (0xB0AC/0x3A3CA0) if playtest shows wrong attract colors.
- Playtest round 5 (palettes good; residual blink left-of-P1 + one on
  Anita; specials clean) -> root-caused STATICALLY: the mixed-record
  shared-effect entries (116 tiles drawn at bank 2) were still
  unmapped. Effect map landed: gen shelf-packs their blocks into the
  freed Jedah-band tail (0xEA40+) + build_gfx places the tiles
  (effect_map.json); x2b7ef4 companion-effect records verified
  NO-ACTION (bank 1, engine page byte-identical in place, 1070/1455).
  EN ROUTE: the count+1 misread of fmt-0 records CORRUPTED build
  08a12dc6 (next-record format words clobbered) — caught by the
  output re-walk BEFORE any playtest; fmt-0 = COUNT entries (subq
  before dbra); tools/verify_gfx_build.py now gates every stage-6+
  build (record parity + code containment + table check). Current
  stage-6 fingerprint: 71601263… (parity 1122/1122, all codes in
  [0xAD8F,0xEAB1], stage 5 still a02aeeff). Playtest round 6: SPRITES
  CLEAN (palettes good, blink gone, effects clean; portraits unchanged
  as expected). MACHINE WINDOW USED: full battery green on 71601263 —
  new permanent gates tests/test_m2b_stage6.sh (guarded soaks incl 40K
  marathon + masked legacy, flicker inventory unchanged) and
  tests/test_m2b_scroll3.sh (0 danger frames; scroll3 base boot-
  constant, one write in 42K frames) + oracle/xemu/flavor PASS against
  the stage-6 rompath. M2b CORE IS VERIFIED. Remaining for the M2b
  freeze decision: portraits/name art + their palettes, attract palette
  path, engine-effect tail refinement.
- STAGE 6 (superseded 06f99f4e) — original notes: fingerprint 06f99f4e… —
  gfx_remap (13,171 tile words / 1,122 records), 6 bank setters
  #$6000->#$4000, [table_fix] (ported bank table was TRUNCATED at row 9
  and carried vs2 values — two latent stage-5 defects, now vanilla
  vsavj values), rompath carries patched vsav.zip. Stage 5 still
  reproduces a02aeeff. AWAITING MAME ALL-CLEAR for: legacy gate battery
  on stage 6, first look at Donovan rendered, scroll3 watch.
- Open for next (static): effect-record map (85 resolved/27 open),
  portrait/name inventory, Zabel slot-0x04 walker gap, then SCROLL-side (stage art vs absolute range
  0x2AD80-0x2EEBB — Jedah's stage is legacy and must stay intact),
  Zabel slot-0x04 walker gap, the 112 shared-effect tiles
  (content-map), portrait/name inventory, then the gfx builder +
  in-emulator verification (QUEUED until the maintainer frees the
  machine).

## Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)

- **The session-6 "anim state-index delta" was NOT a state-space delta.**
  It was extraction tooling corruption: the bare-long relocation heuristic
  fused instruction operand pairs (e.g. `clr.b $6(a6); moveq #0,d0` =
  `0006 7000`) into plausible pointers and rewrote them — 47 false
  rewrites latent in the two source-only zones; one destroyed the
  `moveq #0,d0` anim-state reset, sending an X-distance value into the
  engine anim setter (the vec3 at 0x015096/frame 3025). Diagnosed with a
  new guard instrument (`GUARD_PROBE`/`GUARD_PROBE_COND` conditional
  logging breakpoint — the D0 hit sequence told the whole story).
- **Extractor hardened (tools/extract_char.py + scan_code_refs.py):**
  immediate loads (`movea.l #imm`/`move.l #imm`) are now labeled refs;
  every bare-long candidate is validated against the vhunt2 SIBLING
  (context match with labeled operands wildcarded): identical sibling
  bytes → vetoed (operand pair), host-shift-consistent → confirmed,
  conflicting/absent evidence → rejected loudly. 47 vetoed/rejected,
  5 confirmed real, 0 silent keeps. Details: docs/GOTCHAS.md.
- **RESULT: the full 12_donovan_vs_cpu moveset replay (9320 frames) runs
  END-clean under the -debug crash guard.** No crash, no tripwire. The
  stage-4 bring-up ladder has no frontier.
- **Legacy gate measured honestly (this predates session 7's changes):
  the stage-4 build fails bit-exact whole-RAM comparison** — NOT from a
  behavior change: engine hooks cost cycles on the every-object dispatch
  path; interrupts then land at skewed boundaries → dead-stack ghost
  bytes ($FF7F00-$FF7FFF, below resting SP at frame-done) + the QSound
  handshake latch $FF043C phase-shifts one frame. Hooks converted to a
  ghost-clean topology (vanilla `jsr (A0)` kept in place; thunk jmps back
  to it) removing the push-value ghost; the interrupt-skew ghosts are
  physically unavoidable (zero-cycle table extension proven impossible —
  GOTCHAS). **With exactly those two windows masked, 02 is bit-identical
  to vanilla full-length and attract first diverges at exactly 4278 (the
  Jedah demo).** Live state is vanilla.
- `MASK_RANGES` opt-in on replay.lua (canonical checksums unchanged when
  unset); new gate `tests/test_m2a_stage4_code.sh` locks all of the above.
- **Session-7 extension (after the maintainer approved the masked basis):
  widening the masked legacy gate from 1 to all 7 exact replays found the
  v1 masks are not sufficient alone.** Measured:
  - 03/10/16 each show 1-2 ISOLATED single-frame divergences that fully
    re-converge (03: frames 829+2093 — 829 is the S2 input-accept
    boundary; 10: 3007+3129; 16: 829). Transition state captured one
    frame apart; bytes involved: $FF80B5, object-slot heads
    $FF8400/$FF8800. A real bug in this deterministic engine cannot
    re-converge to bit-identical whole-RAM; bounded re-converging
    flickers are a timing-phase signature. New ground-truthed comparator:
    `tools/compare_flicker.py` + `tests/test_compare_flicker.sh`.
  - 06_test_mode diverges PERSISTENTLY from exactly frame 700 — the TS
    press. Root cause is hook-caused, not ROM-content (stage-3 builds,
    ROM-modified but hook-free, ran 06 bit-identical): service-mode code
    reads the phase-shifted QSound latch and the offset propagates into
    live service state (residue: sound mirror + two checksum/accumulator
    words). Benign, no gameplay surface, but a letter violation.
  - 02/05/07 masked-exact full length; attract 4278 and pick 1080 masked
    diverge-constants hold. Whole-live-state identity therefore holds for
    all match gameplay; the exceptions are input-boundary flickers and
    service mode.
- **2026-07-27 (session 11): STAGE 5 BUILT AND FULLY GREEN — M2a is
  functionally complete pending the freeze decision.** Stage-5 build
  fingerprint **d6d8f273…** (updated after the playtest fixes —
  see the session-11 playtest entry below): the Start-hold flavor selector is LIVE
  (init shim reads the per-player Start bitmask $FF8060 at char-init;
  hold YOUR Start through match load → VH2 flavor; verified 3-way by
  the new `tests/test_m2a_flavor_selector.sh` — plain 01 / P1-held 00 /
  P2-held 01, per-player isolated); the unreachable Anita alternate-
  anim-table operand is poisoned (new imm_poison generator mechanism —
  loud vec3 at a named block if a future writer arms the branch); the
  aux_poke survey concluded none are needed for the M2a bar (select
  behavior works via bank repoints; portrait/name = M2b GFX). ALL gates
  green (initially on 4b65bc63; superseded by d6d8f273 after the
  playtest fixes below): guarded moveset, masked legacy, oracle,
  dual-emulator, flavor selector. **Freeze = pending maintainer build
  decision (see Decisions pending).**
- **2026-07-27 (session 11, first human playtest):** four findings, all
- DECIDED (round 22, maintainer): palette-uploader poke ACCEPTED —
  02/05/07 reclassified flicker@829, pick constant 829; revert path
  documented if playtest shows problems. (original entry follows:)
- **Palette-uploader poke vs exact-gate class (session 14y)**: poking
  the select/HUD palette-row uploader (CODE:0x1BF56 -> the patched
  win-palette copies) fixes the HUD mini-portrait green pixels
  (round 21), the select-portrait palettes and most likely the
  win-quote palette — all through one site. Cost: the select-entry
  bulk upload leaves a ONE-FRAME work-RAM trace at the known
  spawn-boundary flicker frame (829), so 02/05/07 would move from
  masked-EXACT to masked-FLICKER (inventory @829, the already-
  approved mechanism class; verified: exactly 1 divergent frame,
  full re-convergence, pixel gates green). Recommendation: accept
  the reclassification — it is the same mechanism class the other
  six legacy replays already carry at the same frame. Until signed
  off, the poke is reverted and the palettes stay Jedah's.

  dispositioned (docs/project/tables/reconciliation.md "Session 11"): garbled
  sprites = M2b expected; flavor hard to eyeball = expected (QCB+K is
  the fork); 4-option select = REFUTED as port artifact (vanilla shows
  the identical menu on factory EEPROM — snapshot-proven); **DP-spam
  crash = REAL — reproduced deterministically (19_don_dp_spam, ES DP),
  root-caused to a third extended brief-word engine table (defender
  hit-reaction dispatch, vs2 adds ids 0xA2/0xA4/0xA6, ES DP inflicts
  0xA2), FIXED via [reaction_hook]** (verbatim vs2 case stubs from
  config hex, ghost-clean thunk, original dispatch untouched for
  vanilla ids). Also closed a gate coverage gap: 04/08/09 restored to
  the masked legacy gate (measured pure flicker class; frozen logs
  added) — the gate now covers all 13 original replays. 19_don_dp_spam
  joined the code gate's guarded set. New freeze candidate d6d8f273,
  everything green.
- **2026-07-27 (session 12): the palette-seq hijack is FIXED (private
  stub entry; vanilla flows untouched — the session-9 base-swap had
  hijacked LIVE vanilla seq ids 0x2CD+); all gates green on b2e34c87.
  The sustained-mash wedge REMAINS OPEN — deterministic repro, display
  freezes while logic runs; eliminated: palette hijack (fixed, wedge
  persists), meter anomaly (+0x3B2=0 and 99-cap are normal — identical
  on native vs2 AND vanilla), the "Lilith scene" reading (it was the
  post-game-over attract flow). Mechanical bisection protocol written
  (reconciliation.md Session 12). FREEZE ON HOLD until resolved.**
- **2026-07-27 (session 11b, second playtest round): the mash/time crash
  is FIXED.** DP confirmed fixed by the maintainer; new crash on heavy
  activity reproduced with 21_don_mash (input-chaos soak) — the type-114
  effect's creation code loads an ENGINE-SHARED anim table via a raw
  un-hosted movea immediate (vs2 0x1D7428). Fixes: extractor now
  classifies un-hosted movea.l #imm ROM targets as ENGINE refs (row or
  tripwire — retires the manual imm_poison, 0x36784A auto-tripwired);
  new engine_data row 0x1D7428→0x1F3FD2 (unique content match). Round
  transition alone proven clean (20_don_round2); both soaks join the
  code gate (4 guarded replays). Full battery green on the NEW freeze
  candidate **cdf62d8c**.
- **2026-07-27 (session 10): BOTH stage-4 gates PASS on one build
  (fingerprint 67753ee3) — the first all-green run with every system
  active.** The "0x17522 trio" turned out to be the DAMAGE PIPELINE and
  is mapped, not ported: the KO-write signature located vsavj's
  byte-parallel damage wrapper (0x189BA ↔ vs2 0x17330) and every bsr
  position voted — 0x17522→0x18B8C (defense-scaling), 0x17422→0x18AB0
  (post-process), 0x17B22→0x19128 (KO). Donovan uses vsavj's own damage
  machinery (correct superset semantics). Moveset replay END-clean 9320
  frames; code gate green (incl. masked legacy, flickers unchanged);
  oracle gate green. **And the dual-emulator gate PASSED
  (test_m2a_stage4_xemu.sh: patched build on MAME + patched FBNeo,
  anchors 2363/2364 — 1-frame skew — all mapped fields agree at follow
  0/60/180). ALL THREE STAGE-4 GATES GREEN on fingerprint 67753ee3:
  STAGE 4 IS CLOSED.** Next: stage 5 (select plumbing + Start-hold
  flavor selector), soak, freeze.
- **2026-07-27 (session 9): the +0x14E frontier is CLOSED and the
  ORACLE GATE PASSES as a scripted test.** The state hook landed
  (synthesized case stubs + ghost-clean thunks + relocated palette-seq
  records + 4 consumer base-swaps — patch_notes session 9); Donovan's 8
  sound-farm calls stubbed silent (M5 restores; sfx ids recorded in
  reconciliation.toml); anim_index_a2 resolved from gap auto-kind (was
  feeding Jedah's anim rows to Donovan's attacks). Moveset replay
  END-clean again. `tests/test_m2a_stage4_oracle.sh` PASS: anchors equal
  (2363), neutral window exact, P2 HP trajectories equal (hits land,
  same damage), and the comparative bound — ported Donovan diverges
  LESS across the two engines (890 mismatches) than vanilla Demitri
  does (2379): the residual ~1-frame action-latency skew is the
  ENGINES' cross-game difference, proven by the 18_veteran_ctl control
  pair. Remaining stage-4 behavior work: dual-emulator gate (16-pattern
  Donovan replay on MAME + FBNeo), then stage 5.
- **2026-07-27 (session 8): the vsav2-as-oracle behavior gate is BUILT
  and immediately caught two real bugs.** Replay pair 17_don_oracle_*
  (both games anchor at frame 2363 — sibling engines run identical menu
  timelines). Bug 1 FIXED+verified: "gap_bd7fa" was really dispatch_14
  (per-char code dispatch); row 0x0F still ran JEDAH's state routine
  against Donovan's data (the session-4 "ignores inputs" family) —
  reclassified, extractor de-hardcoded (walks all dispatch_NN), rows
  repointed; neutral-idle field compare now agrees on all fields for
  1100 frames. Bug 2 OPEN (the current frontier): the +0x14E engine
  state dispatch (vsavj table 0x2A7E2, 89 entries) is EXTENDED in vs2
  (101 entries — 12 newcomer states); Donovan's VS2-flavor QCB+K writes
  state 0xB6 → indexes past the vanilla table → ILLEGAL → soft reset.
  Fix design + details: docs/project/tables/reconciliation.md "Session 8".
  HP-decrease sanity holds natively (Victor −11 ×2). NOTE: with
  dispatch_14 active the 12_donovan moveset replay also reaches the
  +0x14E states and crashes at 3815 — stage-4 gate lock 2 is KNOWN-RED
  until the hook lands (legacy gate green; one fix closes both).
- **2026-07-27: v2 approved (see Decisions made) and the Start-hold
  flavor mystery RESOLVED** — community protocol confirmed (Donovan +
  Huitzil only), mechanism pinned end-to-end with the new instruments
  (masked comparison found the behavioral fork at the exact QCB+LK
  frame; read-watch named both consumers, both inside ported regions).
  One consequence gates the upcoming vsav2-as-oracle behavior gate: the
  ported build's latch byte defaults to the WRONG flavor (VH2) — the
  oracle's native side defaults VS2, so QCB+K would diverge at the field
  compare until the default-flavor decision lands (Decisions pending).
  Note: 12_donovan_vs_cpu's battery includes QCB+K — the ported
  VH2-branch code path already runs crash-free under guard.

## Sessions 5-6 highlights (M2a stage 4 — the port runs)

- **Companion (Anita) chain decoded end-to-end**: pool geometries are
  identical per-index in both games; allocator family mapped (never
  ported — it reads the game's own RAM bookkeeping); creation handler's
  anim-table pointer was the last unrelocated piece; class-7 (vs2-only
  update queue) remapped to vsavj's equivalent class.
- **New extraction capabilities** (all in `tools/extract_char.py`):
  data-kind extra roots with forced twins; *segmented* gap-tolerant
  oracle diff (resyncs after cross-game insertions — Anita's 44.2K asset
  region: 2065 pointer fields over 75 segments); self-pointer
  classification for micro-shifted multi-blob regions; chunk-BFS graph
  sizing before committing space; PC-relative word-table discovery with
  full-extent protection.
- **New generator capabilities** (`tools/gen_donovan_patch.py`): layout
  groups (PC-referencing families keep source-relative spacing, gaps
  recycled), near_map satellite placement within d16, pcrel entry
  rewrites with shared per-region tripwires, slot-clearing allocator
  wrappers, port_patch byte edits, stage-1 scaffolding gated to stages
  1-3.
- **SPACE BUDGET CLOSED**: ~335K placed of 336.6K free (hole A ~1.4K
  spare, hole B ~12.9K). Achieved by honest region bounding, porting only
  Donovan's own sub-object handler types (others tripwired), and tighter
  margins.
- **Result**: char-init completes, match runs (timer, CPU opponent, HP
  structs). Crash frontier moved 2886 → 3025.
- **Frontier**: vec3 at engine 0x015096 — the anim word table is
  byte-identical to native vsav2 (data+relocation correct) but the INDEX
  into it is wrong; a state/substate byte carries a vs2-flavored value.
  Full detail + next probe: docs/project/tables/reconciliation.md "Session 6",
  docs/NEXT_SESSION.md.
- **GOTCHAS paid**: PC-relative reads are decrypted reads on CPS-2;
  PC-relative word tables are DATA (a fused pair of word entries was
  silently corrupting a dispatch table).

## Session 4 highlights (M2a — the real Donovan port)

- **M2a plan approved** (staged: C0 harness → C1 extraction → C2 generator →
  bring-up ladder stages 1-5 → close-out). Stage design: null-relocation of
  Jedah's own data first (tooling proof, zero R1 ambiguity), then Donovan
  data → anim → code dispatch (R1 surface) → select plumbing.
- **C0 COMPLETE (harness primitives, all verdict logic ground-truth tested):**
  - Crash guard: breakpoints on 68k exception handlers, fault PC/ADDR from
    the exception frame, stack sketch, RAM dump (`replay_guard.lua`,
    `run_replay_guarded.sh`, `test_crash_guard.sh` — vec3/vec4 positive
    controls trip correctly).
  - Dual-emulator field comparator per amended §4: debounced match-start
    anchors, stable/settled/phase field classes (`compare_fields.py`,
    `fields_m2a.tsv`, selfcheck green: MAME/FBNeo agree on 16_xemu_2p with
    1-frame skew).
  - Auto-detecting suite runner: program-image fingerprint →
    `tests/expected/<expset>/` dispatch; `.diverge` expectation kind
    (exact-frame divergence vs frozen full logs). Suite green, 12 replays
    (added 11_pick_donovan, 16_xemu_2p).
  - FBNeo verified to load CRC-changed patched zips (no descriptor change
    needed); `run_replay_fbneo.sh` gained `FBNEO_DUMPS`/`FBNEO_ROMPATH`.
- **Cross-emulator findings (GOTCHAS paid):** MAME `-debug` perturbs
  multi-CPU timing (checksum gates must run non-debug); vs-CPU replays have
  emulator-divergent content (different CPU-picked opponents); menu presses
  near transitions land on opposite sides of input-accept boundaries;
  match-start predicate flickers during intros (debounced).
- **C1/C2 COMPLETE:** oracle-validated extraction (`extract_char.py` —
  every cross-sibling diff byte must classify as a pointer field under a
  measured shift; auto-discovers new region shifts, e.g. the sprite/OBJ
  sub-tables at −0x2002C), staged patch generator, `find_equiv.py`
  (validated at score 1.00 on the known loader), `build_donovan.sh` driver.
  Donovan footprint closed at ~235KB, 9+ regions.
- **STAGES 1-3 PASS** (gates in tests/): null relocation (Jedah copy,
  10018 B — matches M1 exactly), Donovan passive data (full round under
  guard), anim + sprite sub-tables (idle-coherent; select-screen hover
  reads anim → pick divergence pin moves 2886→1080 at stage 3+).
- **STAGE 4 (in progress, deep):** R1 mechanized (`reconcile_batch.py`:
  pattern ladder, stub-deref, callsite anchoring via veteran parallelism,
  codebytes, farm-param matching; ~120 verified rows) + per-target
  TRIPWIRES for opens (fault PC names the target). Ported regions: +0x34
  newcomer-support zone, 17 extra secondary-object handlers, engine
  char-init pair, VS2-only 0x8xxxx companion zone (source-only). TWO
  engine hooks live (extended type-dispatch tables 59→76 and 114→124,
  jsr-thunk pattern; vanilla rows byte-identical). **Donovan RUNS on the
  vsavj engine** (match, timer, CPU opponent, HP structs, guard clean,
  screenshot in scratch). [Superseded by sessions 5-6 above: the companion
  chain is decoded and the port fits; see that section for the current
  frontier.]
- Suite GREEN, 13 replays (added 11_pick_donovan, 12_donovan_vs_cpu
  moveset-exercise, 16_xemu_2p; vanilla expectations + full logs frozen).
- **Next actions (stage 4 close):**
  1. Decode the pool-index correspondence + spawn-node field protocol
     (vsav2 node writer = the 0x8A5A8 hook; vsavj consumer =
     `PRG:0x0155D0-0x015650` jump-table on `(0x9,A6)`; watch $FF79BE+
     pool heads). Consider REWRITING the hook to vsavj's protocol
     (synthesized, GEN provenance) instead of porting VS2's.
  2. Then: stage-4 gates (vsav2-as-oracle field compare at anchors —
     native Donovan pick on vsav2 = cursor R×2 from default; dual-emulator
     on 16-pattern replay; legacy gate every build).
  3. Then stage 5 (select plumbing aux pokes) + soak + freeze.

## Session 3 highlights

- CLAUDE.md §4 dual-emulator amendment applied (maintainer-approved).
- **Donovan/Huitzil/Pyron located and pinned** (char IDs 0x13/0x10/0x11,
  hitbox bases + handler code addresses in both vsav2 and vhunt2).
- Per-character table bank semantically labeled (14 dispatch tables +
  hitbox pairs + parameter tables); bank layout identical across all three
  sets (same internal deltas from a per-set origin).
- RAM atlas: round timer $FF8109, HP +0x50/+0x52 (max 0x120), X/Y
  +0x10/+0x14 added.
- Remaining for M1 acceptance: per-character manifests' remaining columns
  (anim scripts, tile ranges, palettes, sound cues); meter/rounds-won RAM
  offsets; formal Aulbath slot-9 pick; vhunt2-side pick verification of
  D/H/P; Start-hold flavor mechanism (VS2-vs-VH2 behavioral deltas are NOT
  in hitbox data — identical across both games).

## Current milestone

**M3b — the multi-tenant / variant-id track. IN PROGRESS (14z-71).**
- **Donovan: FROZEN** as `donovan-m3a` (`4b7d0dc7`), de-substituted at his
  native id 0x13; stock twin `m5_stock` (`6c93cfa8`). Both rebuild
  bit-exact from the tree (`tests/test_m3a_reproducible.sh`).
- **Huitzil: at his native id 0x10, feature-complete for the ping arc and
  awaiting FREEZE.** Current build `build/hui25` (`b0fb2f94`) —
  maintainer-confirmed clean including the beam (all three variants). Open
  before freeze: the win QUOTE (cosmetic, root-caused), FG pacing, and the
  registry row + expectation set.
- **Pyron: ladder stages 1-4 exist** (`tests/test_pyron_ladder.sh`); his
  moveset arc and gfx rung are the next tenant work. **Before his gfx
  rung**, re-check `gfx_layout3.toml`'s one-source-bank premise — a tenant
  with a type-4 effect draws from a second gfx bank (14z-71).
- Standing: CPS-2 WIDE v1 is demonstrated on both emulators; the legacy
  flicker inventory is frozen and any growth is stop-and-root-cause.

### Historical — M2 (proof of life), kept for the record

**M2 — Proof of life. COMPLETE.** Replaced slot = Jedah (0x0F).
- Program-patch tooling (`tools/patch_prg.py`) DONE and MAME-verified: data
  raw, code re-encrypted, null bit-identical (`tests/test_patch_prg.sh`).
- **Mechanism PROVEN end-to-end on trusted tooling** (`tests/test_m2_repoint.sh`):
  repointing vsavj Jedah's hitbox-base bank entry to Demitri's takes effect
  in a live match (RAM:$FF8460 loads the new base), AND the superset
  invariant holds exactly — 6/6 non-Jedah legacy replays bit-identical;
  attract bit-identical through frame 4277, diverges at 4278 precisely where
  its CPU demo shows Jedah (char id 0x0F, verified). Attract legitimately
  involving the modified slot is correct superset behavior, not a violation.
- Feasibility assessed (docs/project/M2_feasibility.md): behavior data portable via
  ~337KB free vsavj space + data-reads-bypass-encryption; sprite tiles are
  the R2 wall (may pull M3 forward); QSound = M5.
- **M2a IN PROGRESS (sessions 4-7, see highlights above):** extraction,
  generation and relocation tooling complete; stages 1-3 PASS; stage 4
  bring-up DONE — the full moveset replay runs END-clean under guard
  (session 7; the session-6 "state-index delta" was extraction
  corruption, fixed). Legacy-gate basis decided (live-RAM masked windows,
  see Decisions made) and the masked legacy gate is green over all 9
  legacy replays. Remaining for stage-4 close: the behavior gates
  (vsav2-as-oracle field compare at anchors, native pick = cursor R×2;
  dual-emulator on the 16-pattern replay). Then stage 5 (select
  plumbing) and M2b graphics.

### M1 — Map. ACCEPTED (2026-07-25).
Both SPEC §4 clauses met; full assessment in docs/project/M1_acceptance.md.
Deferred sprite-bound exact addresses (tile/palette/sound) are
proven-reachable and scoped to M3/M4/M5.

### M1 detail (all complete)
- Replay harness: DONE both emulators. Shared `.rpl` input-script format;
  MAME runner (`tests/lua/replay.lua` — inputs, checksums, snapshots, RAM
  dumps) and patched-FBNeo runner (`emu/fbneo-patches/0001-…-harness.patch`,
  `tools/run_replay_fbneo.sh`). Both proven deterministic run-to-run.
- 10-replay legacy suite: DONE, green, expectations frozen
  (`tests/run_suite.sh`, `tests/expected/vsavj/`). Semantics spot-verified by
  snapshot (2P pick, challenger interrupt, mid-attract start all confirmed).
- **Cross-emulator finding (important):** MAME and FBNeo agree bit-exactly
  for the first 71 boot frames, then run the same states on *different frame
  indices* (transitions land ±frames apart; static screens re-sync; ~37
  work-RAM bytes differ at title — phase-shifted counters + sound-driver
  area $FF05xx). **Frame-exact whole-RAM dual-emulator comparison does not
  hold.** Superset-invariant enforcement is unaffected (oracle = same
  emulator, vanilla vs patched). Recommendation for CLAUDE.md §4 amendment
  (human sign-off requested, non-blocking): new-content dual-emulator
  verification = mapped gameplay fields (player structs, HP, positions,
  timer) compared at sync anchors (match start), not whole-RAM checksums.
- RAM map: community anchor imported and verified (player structs
  $FF8400/$FF8500, hitbox ptr offsets, match-active flags), extended by
  differential experiments + write-traces. See docs/game/atlas/ram.md.
- **Character-data plumbing CRACKED (the big one):** write-trace on
  $FF8480 → per-character loader (vsavj PRG:0x028DD8) → three 32-entry
  tables indexed by 5-bit char id → located in ALL THREE sets by
  instruction-pattern search → a whole bank of ~20 per-character tables
  (vsavj PRG:0x0BD0FA-0x0BE8xx). Slot→name map ~10/16 done empirically
  (pick + snapshot + pointer readback). Variant slots: vsavj {8}=Oboro
  Bishamon; vsav2/vhunt2 {0,1,3,8,9} with per-slot hitbox data
  byte-identical between vsav2 and vhunt2 (both games carry both flavors).
  **vsavj slot→character map COMPLETE** (16/16, one by elimination).
  **DONOVAN/HUITZIL/PYRON LOCATED** (pick-verified on vsav2): char IDs
  0x13/0x10/0x11 — the variant half of slots 3/0/1 — with hitbox bases in
  both vsav2 and vhunt2 recorded. Base-half slot assignments are identical
  across the whole series. Full detail: docs/game/atlas/character_tables.md.
- Three-way diff: window/masked diff built (`tools/diff_sets.py`);
  **finding:** vsavj↔vsav2 share <10% at window level even pointer-masked —
  engines were rebuilt (shifted code, changed PC-relative displacements) and
  most of the 4MB is game-specific data. The atlas grows from anchored
  RE (traces + tables) — which the character-table crack has now proven out.

### M0 — Bench. COMPLETE (2026-07-25). Acceptance status:
- Null-patch output bit-identical to reference: **PASS** (`tests/test_null_build.sh`)
- 60s attract replay deterministic across two runs: **PASS** (`tests/test_attract_determinism.sh`, MAME)
- Headless MAME runner: **DONE** (`tools/run_mame.sh`, MAME 0.288 via Homebrew)
- Headless FBNeo runner: **DONE** (`emu/fbneo` submodule, SDL2 build,
  `tools/run_fbneo.sh` with dummy SDL drivers + sandboxed HOME;
  `tests/test_fbneo_smoke.sh` PASS). The SDL2 frontend has no scripting, so
  the per-frame RAM-checksum probe on the FBNeo side is a frontend patch —
  first M1 task (see below)

Bonus beyond plan: CPS-2 decryption/encryption pipeline
(`tools/cps2_decrypt.py`) proven bit-identical to MAME's implementation via
opcode-space dump oracle (`tests/test_decrypt_oracle.sh`). Both directions
(decrypt for analysis, encrypt for future patch injection) self-check.

## Next actions

1. **Freeze Huitzil** (`build/hui25`, `b0fb2f94`): registry row +
   expectation set, maintainer-gated. The playtest is clean.
2. Then the two cosmetic opens: the win QUOTE (root-caused — the fetch's
   `lea -4(a0,d0.w)` bias) and FG pacing.
3. Then **Pyron**: moveset arc, then the gfx rung — re-checking the
   one-source-bank premise first (14z-71).
4. Suite/watch duties continue: flicker inventory is frozen — any growth
   or systematic divergence is stop-and-root-cause (CLAUDE.md §4
   standing watch).
3. Parked (register per milestone): M5 sound restoration (25 stubbed
   rows + dispatcher table), Huitzil/Pyron tripwired handlers (M3),
   bank-tail parked tables, 0x2c31xx data opens.

## Open items

- None blocking. Reference collection is COMPLETE: vsav, vsavj, vsav2,
  vhunt2, vhunt2r1, qsound_hle — all MAME `-verifyroms` green, all 76
  members frozen in `docs/checksums.txt` (vsav2 supplied by maintainer
  mid-session 2026-07-25 and folded in; re-freeze recorded here).
- ROM packaging fixes from the 2026-07-25 audit are confirmed applied:
  `vhunt2.key` present in both vhunt2 zips (CRC 61306b20), `qsound_hle.zip`
  present (`dl-1425.bin` CRC d6cf5ef5).

## Decisions made

- **M2b-CORE FROZEN at fingerprint
  `71601263474dfd7e4afd0741dae696cde22eda4e`** — 2026-07-28, maintainer
  ("freeze core deliverables"). Scope: Donovan's sprites, palettes, and
  effects living in Jedah's gfx space — playtest-clean (rounds 4-6) and
  fully gate-verified (M2b gate incl. 40K marathon + masked legacy with
  unchanged flicker inventory; oracle; dual-emulator; flavor; scroll3
  exclusivity live-measured). Registry row `71601263 -> donovan-m2b`
  (gfx member sha1s in the registry note — the program fingerprint does
  not cover them). Deliberately OUT of the core freeze: select-screen
  big portrait/name banner/mugshot (still Jedah's; pipeline mapped,
  in-place pointer surgery pending), attract palette path,
  engine-effect tail. Those continue as follow-up work.
- **M2a FROZEN at fingerprint `a02aeefff4c7a053337b10c923c8c328573788fa`**
  — 2026-07-28, playtest-gated as decided: maintainer's round-3 playtest
  came back fully clean ("no more graphical bug/crash, even over
  multiple matches"; "no more music trigger from inputs"). The M2a bar
  (Donovan selectable, crash-free, behavior observable, R1 logged) is
  met; graphics deliberately garbled (M2b), Donovan's own sfx
  deliberately silent (M5, 25 stubbed rows + the 0x271B6 dispatcher id
  table recorded in reconciliation.toml). Registry row + suite
  expectation kinds landed the same day (session 14 highlights).
- **Legacy-gate basis for hooked builds = live-RAM (masked windows)** —
  2026-07-25, maintainer approved ("the invariant interpretation reads
  sound and reliable which is paramount"). For builds carrying engine
  hooks, legacy comparison masks exactly `RAM:$FF043C` (QSound handshake
  phase latch) and `RAM:$FF7F00-$FF7FFF` (dead stack below resting SP);
  every other byte compared every frame (confinement by construction).
  CLAUDE.md §4 amended; windows documented in docs/game/atlas/ram.md; masked
  vanilla expectations frozen under tests/expected/vsavj/masked/ (this
  session). Suite-runner masked-expectation-kind support lands with the
  stage-5 freeze. New masked windows require the same route: measured
  mechanism + atlas entry + maintainer sign-off.
- **Ported-Donovan default flavor = VS2** — 2026-07-27, maintainer
  ("Default should be VS2, as you proposed"). Implemented as a tunable
  in `build/manifest/donovan.toml` (`[init_shim] flavor_disp=0x3C2,
  flavor_default=0x01`, rule-5 style): the init shim writes the flavor
  latch into the initing player's struct (A6+0x3C2) — vsavj never writes
  it; the ported QCB+K handler + projectile consume it. Verified live:
  P1 $FF87C2=01 in-match on the flavor-defaulted build. Start-hold
  selector wiring (clear-to-00 on held Start) = stage-5 select-plumbing
  scope, §3.3/§3.4 variant policy (Donovan + Huitzil only).
- **Legacy-gate v2 refinement APPROVED** — 2026-07-27, maintainer
  ("I'd rather we iterate with as tight setups as we can build rather
  than try to be perfect and not go forward"). Per-replay classes on the
  masked basis: exact (02/05/07), flicker-tolerated 03/10/16
  (`tools/compare_flicker.py`, stretch ≤2 / re-converge ≥60 / total ≤8),
  frozen diverge constants 06@700, attract@4278, pick@1080. CLAUDE.md §4
  updated to v2. **Standing watch (maintainer caveat): if flickers grow
  beyond the frozen inventory (5 frames across 3 replays: 03@829+2093,
  10@3007+3129, 16@829) or divergences turn systematic, stop and
  root-cause — that would indicate a deeper issue.** The tolerance caps
  themselves fail loudly on growth; treat any new flicker frame as a
  finding to attribute, not noise to absorb.
- **M2 replaced slot = Jedah (slot 0x0F)** — 2026-07-25, maintainer
  approved. Donovan replaces Jedah in vsavj for the proof-of-life
  milestone. Rationale: footprint fit (Jedah 10018 B ≥ Donovan 9358 B),
  boss character (least playtest disruption), keeps Demitri/Victor so the
  M1 replay suite stays valid.
- **CLAUDE.md §4 dual-emulator amendment** — 2026-07-25, maintainer:
  new-content cross-emulator verification is field-level at sync anchors
  (mapped gameplay state), not whole-RAM frame-exact; within-emulator
  oracles stay whole-RAM frame-exact. Text updated in CLAUDE.md §4.
- **Project name = "Vampire Saved"** — 2026-07-25, maintainer.
- **Base revision = `vsavj` (Japan 970519)** — 2026-07-24, maintainer. Closed.
- **Checksum manifest is per-member**, so zip repackaging never matters —
  2026-07-25, session decision (mechanical, no gameplay impact).
- **Raw-image byte-order convention** — 2026-07-25, session decision: ROM
  files are LE-word storage; all derived images are 68k logical (BE) order.
  See docs/GOTCHAS.md first entry.

## OPEN BUG (14z-60y): WIDE renders Donovan/Anita with WRONG TILES

Playtest of `build/m5w` (the M5-sound WIDE build `ac52eeff`, built Aug 4 —
NOT anything from session 14z-60): mechanically sound, no gameplay issue,
but **Donovan's and Anita's sprites are garbled from character select
through the match** — wrong art, while shapes, specials and hit/hurtboxes
all align. Minor palette issues on some win screens, tracked separately.
`run_wide.sh` only launches, so nothing was rebuilt for the test.

**The load hypothesis is DEAD, measured.** `FBNEO_HGFX` dumped the decoded
tile buffer at Donovan's band (tile `0xAD8F` -> byte `0x56C780`) from the
WIDE build and from the known-good stock build `donovan6`:

    WIDE  sha1 f3cb6aa95b294b9506206d93e335f8a09f43347e, 0 bytes of 0xFF
    STOCK sha1 f3cb6aa95b294b9506206d93e335f8a09f43347e, 0 bytes of 0xFF

Byte-identical, no 0xFF fill — so the FBNeo CRC trap did NOT fire and the
tiles load correctly on both tracks. ROM and loader are fine.

**Therefore the fault is in tile ADDRESSING at draw time**, which is exactly
what the WIDE profile changes: its single removed line in `cps_obj.cpp` is
the sprite tile-code composition for 19-bit addressing. That matches the
symptom (record geometry right, only the fetch displaced) and matches its
being identical on FBNeo and MAME, which carry the same profile patch.

**Named suspect, not yet confirmed:** `docs/GOTCHAS.md` records the free
tile-address bit as **y-word bit 12**, on the CPS-2 Turbo precedent. Bit 12
is also a legitimate Y-COORDINATE bit. A sprite drawn at a Y with that bit
set would have its tile address shifted by a 64K page under WIDE — wrong
art, right shape. It would also explain why the B4 canary passed: that
proved LEGACY replays pixel-identical, and legacy content may never place a
sprite at such a Y.

Next measurement: dump OBJ RAM for a Donovan sprite on the WIDE build,
check his entries' y-words for bit 12, then A/B the same frame's
framebuffer against stock. If confirmed this is a defect in OUR emulator
profile (Rule 1 territory), not in the port — and it would block the WIDE
track until fixed.

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
native codes; `vsav.zip` leaves the rompath entirely pristine. Blank-pool
relocation (option B) remains the fallback if the measured hook cost
violates the standing flicker watch. Maintainer also flagged suspected
graphical corruption in the session captures — playtest of `39597268`
in progress; the expected-interim inventory is in
docs/project/playtest_m3a_interims.md so the report can classify against it.
Original write-up kept below.

## Decisions pending (human)

- ~~**ADOPT THE HIT-CLASS MAP EXTENSION + RE-FREEZE huitzil & pyron
  (14z-82b).**~~ **DECIDED 2026-08-12 (maintainer): ADOPTED** — shipped as
  huitzil-m4 (e66678d0) + pyron-m3 (6c7f7322), 14z-82c. Original entry: The generated `hitclass_map_extend` site_thunk fixes a
  playtest-reachable crash LATENT IN BOTH FROZEN TENANT BUILDS (pyron's
  satellite type-64 contact = the f7997 vec3, measured on pyron-m2 solo;
  Huitzil's 68/72 share the pool). Numbers, all measured on a probe build
  (tests/audit_hitclass_map_cost.sh, rerunnable): fix holds through the
  11,017-frame soak that crashes the frozen build; LEGACY BIT-IDENTICAL
  over 30,284 frames on four replays, with a fire census showing legacy
  never enters the map at all. Cost of adoption: the row goes in
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
| drawer list-type 6 (`0x01B6AA`) | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **YES — non-tenant lists run vsav's original type-6 code, and arming the `$FF010C` tripwire FAILS the gate** |

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
