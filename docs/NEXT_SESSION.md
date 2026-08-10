# NEXT SESSION — orientation (written at the close of 14z-77, 2026-08-10)

**ALL THREE TENANTS ARE FROZEN.** Donovan `donovan-m3a` (4b7d0dc7),
Phobos `huitzil-m2` (9deda080), **Pyron `pyron-m2` (69e8c6f0 — RE-FROZEN
14z-76, supersedes pyron-m1 d8b282da, which can no longer be produced from
the tree)**. `run_suite.sh vsavjw` GREEN (55 PASS / 17 SKIP / 0 FAIL,
72/72 replays). All three rebuild bit-exact.

```sh
export ROMDIR=/path/to/reference/sets
tools/run_wide.sh build/pyron20 fbneo     # play it
ROMDIR=... MAME_BIN=~/.cache/vampire-saved/mame/cps2 \
MAME_ROMPATH="build/pyron20/rompath;$ROMDIR" tests/run_suite.sh vsavjw
```

**So M3b — merging the three into one build — is the next milestone**, and it
is PLANNED (14z-76). Read `docs/project/M3b_plan.md` for the original, but
note its phase order was overtaken: Phase 0 and Phase 1 are DONE, Phase 3's
measurement is done and ratified, and Phases 4/5 (H and P content) landed
through the SINGLE-tenant generator per ratified decision D4. **The whole
remaining milestone is Phase 2 — the multi-tenant generator — plus Phase 3's
implementation.** Phase 6 (arcade ladder, VS-pool) is OUT OF SCOPE by
maintainer decision (2026-08-10); it becomes its own milestone and D3 stays
open.

**The standing gate is `tests/test_m3a_reproducible.sh`, extended 14z-76 from
two frozen targets to all FOUR** (m5_stock, donovan-m3a, huitzil-m2,
pyron-m2). Run it after every machinery commit. Its value scales with the
count: the refactor must leave three independent tenant fingerprints
untouched, so each frozen vertical is an independent oracle over the same
change — the payoff of D4's "freeze each vertical first, then merge".

Measured blast radius for Phase 2: `gen_donovan_patch.py` has ONE binding of
tenant identity (`dst_slot` at :251) and **37 read sites** closing over it —
14 table-row, ~~9 gating~~ (**DONE, slice C 14z-77 — 10 sites; the count was 9
because the `data_port` `slot_ptr_table` pair was not in it**), 4 baked into
emitted machine code (the silent class),
1 select-cell ownership, 1 output naming. The allocator itself composes
correctly; the hazards are `placed`/memo dicts keyed by address not
(tenant, address), five engine sites all three tenants patch identically
(0x5FCE0 / 0x6C0E0 / 0x5F328 / 0x5F146 / 0x5F1B6 — these need ONE thunk
dispatching on N ids), and `[table_fix]`, which must MERGE rows rather than
dedup.

---

## Before the merge: two things that will collide

1. **Free-pool HUD anchors are per tenant and must stay disjoint.** Donovan
   0xBE8C/0xBE90, Phobos 0xBE92/0xBE9A, Pyron 0xBE94/0xBE9C. All six of
   Pyron's cells were chosen blank + inside `protected_tiles.json`'s audited
   pool for exactly this reason.
2. **Phobos carries one latent aliased row.** `0x2A8A4` row 0x10 is `0x004A`
   (row 0x00's handler) where vs2 has the default. Benign today (0 hits at
   the resolver) but not what native does, and `huitzil-m2` is frozen — so
   changing it is a maintainer decision. `tests/test_variant_dispatch.sh`
   reports it every run.

## Open on Pyron (none blocked the freeze)

- **The win QUOTE** — **DECODED, and DEFERRED BY MAINTAINER DECISION
  (14z-76). Do it LAST**, on the merged M3b build, after the mechanical port
  is complete and certified. Do NOT start it opportunistically.
  Cause: the first-level 16-bit offset table at the quote bank
  (`root 0x0112BC -> bank 0x32D28A`) has 32 entries with the variant half
  **exactly aliased** (`0x10->0x00`, `0x11->0x01`, `0x13->0x03`) — the alias
  class, matching the symptom on all three tenants exactly.
  **The cheap fix is impossible:** those offsets are 16-bit SIGNED relative to
  the bank, and the `bank +/- 0x8000` window has **zero** free bytes (scanned;
  not one 0x40 run). `hole_b` and `wide_ext` are both out of reach.
  **The only path is relocating the whole bank** (~`0x40DC` copy + `0xC20` of
  tenant blocks into `wide_ext`, then ONE long at `0x0112BC`) — which is a
  SHARED surface, unlike every other tenant change in this port.
  Full recipe, vs2 source addresses, risk analysis and the required gates:
  `docs/project/patch_index.md` "DEFERRED BY MAINTAINER DECISION — the
  win-quote bank relocation". Mechanism: `docs/game/engine_internals.md`
  "The WIN-QUOTE TEXT SYSTEM".
- ~~**His EFFECT palette**~~ — **CLOSED 14z-76, in `pyron-m2`.** Playtest: Pyron's electrocuted state
  is WRONG on pyron19 (red shock aura) and CORRECT on pyron20 (yellow,
  identical to vs2); **Demitri is identical across both builds and correct**,
  which is the legacy check that no RAM gate can perform — the palette path
  never transits work RAM. The "16-row table" premise that deferred this for
  two sessions is RETRACTED: `0x38C218` is ONE 32-row id-indexed table and
  `0x38C258` is its second half, so row 0x11 is an ordinary variant alias row
  (`tests/test_effect_palette_table.sh`).
- **`tests/replays/pyron/80_pyron_cosmo_pairsweep.rpl` still resets at
  f4840.** INDEPENDENT of everything fixed this session — it reproduces on
  pyron14 too. **"Most likely another out-of-range index of the same class"
  is WEAKENED (14z-76):** the new sweep finds only three tables where vs2 is
  longer, and on this exact rig none explains it — the Cosmo table dispatches
  only entries 0/4/5/40/41 (last at f4799, all in range) and the other two are
  never dispatched at all, 0 hits against a 25-hit positive control on the
  same instrument. So either it lives in the 29 unjudged tables or it is a
  different mechanism. Needs a contrived 12-attempt sequence, so it is low
  priority but it is a real defect. Repro:
  ```sh
  POKES="1400:ff8782:11;1450:ff8782:11;1500:ff8782:11;3300:ff8509:09;3900:ff8509:09;\
  4500:ff8509:09;5100:ff8509:09;5700:ff8509:09;6300:ff8509:09"
  # watch P1 +0x382: 0x11 while alive, 0x00 once the watchdog has cleared RAM
  ```

## THE INDEX-SPACE CLASS — the lesson of this session

vsavj's tables are SMALLER than vs2's. A ported character carries vs2's
indices verbatim, and any index past the end of vsavj's table dispatches into
whatever follows it. Pyron's Cosmo sub-state 81 hit a table with 80 entries
and jumped into the table's own bytes.

**The fix belongs in the TENANT'S DATA, never in the shared table.** 14z-74
wrote the engine word instead: it stopped the crash and corrupted every
character's dispatch, and cost this session a blocked freeze to find. When a
tenant drives an out-of-range index, retarget HIS index to an in-range entry
that already reaches the right handler — one byte, unreachable by legacy.

**Sweep for it:** `tests/test_variant_dispatch.sh` finds the aliased-variant
row shape; **`tests/test_index_space.sh` (14z-76) is now the sweep for THIS
one** — it derives every `jmp (d8,PC,Dn.w)` table's entry count in both ROMs
and reports the tables where vs2 is longer. Ground-truthed: it re-derives the
Cosmo table at 80 entries against vs2's 84, danger window [80..83], which
contains the index that crashed. Result on the two ROMs: **3 risky tables,
29 of 110 honestly NOT JUDGED** (no twin located; two of them are large —
`0x018510` 81 entries and `0x02385c` 80). Closing that coverage gap is the
next improvement to the instrument.

**Trap when using its output at runtime:** the danger window is in ENTRY
numbers but a dispatcher's register holds entry*2 (`add.w d0,d0`). Halve
before comparing, or entries 40/41 read as "80/82, out of range".

## Rules that cost real time — carried forward

- **BUG ARCHAEOLOGY FIRST — grep the history before fixing anything.** It may
  already have been fixed once; the old fix or its withdrawal is the fastest
  route to the mechanism. Find the last-known-good build and diff it against
  its predecessor. **If the record is ambiguous about whether it was ever
  fixed, ASK THE MAINTAINER** — they were there and will usually remember.
  (14z-75: this is what cracked the Cosmo crash, after I had concluded the
  opposite from rigs that never fired the move.)
- **A negative result from a rig is a fact about the RIG until proven
  otherwise.** Prove the rig produces the EVENT, not just that it ran. Cosmo
  needed the right button pair, a long enough hold, AND meter — 4 of 12
  attempts fired in one rig and 0 of 12 in another, and "no crash" from a
  downgraded input means nothing.
- **Point `run_suite.sh` at a tenant build EARLY.** Every tenant-scoped gate
  was green while a legacy replay diverged permanently; only the vanilla
  suite sees that.
- **Never chain a legacy measurement onto a build in one command**, and
  re-run before believing a gate that contradicts a previous green.
- **Read a table BASE off the code that indexes it**, never off a content
  match (cost: a confidently wrong elimination).
- **A jump table ENDS WHERE CODE BEGINS.** Count entries before writing one.
- **A deadness measurement is only as good as the replay it ran on** — 0
  reads on `02_demitri_vs_cpu`, 6 reads on `05_timeout_idle`, same address.
- **Check the MODE FLAG before believing a mode** ($FF802E for Dark Force).
- **MAME's `-debug` can perturb a timing-sensitive crash AWAY**, and its
  frame numbers do not transfer to non-debug runs. Use FBNeo's non-perturbing
  tap when the debugger cannot see the bug.
- **THE DEAD-ROW CLASS** — `docs/game/engine_internals.md`. The most common
  defect shape in this port. When a ported character does something vanilla
  never does, suspect a dead row first.

## M3b is UNDER WAY — slices A, B and C landed (14z-76, 14z-77)

The multi-tenant generator refactor is started. Three slices in, each inert by
construction and verified against ALL FOUR frozen fingerprints:

- **Slice A** (`b7e743a`) — `tenant_context(t, port, profile, override)`, a
  pure function resolving ONE `[[tenant]]` row: id_by_profile, the
  variant-needs-profile and reserved-0x12/0x18 refusals, `mirror_variant`,
  the variant gfx-bank override. `normalise_tenants()` builds a LIST of them
  (`port["_tenants"]`) and hands `main()` `_tenants[0]` flattened as before.
- **Slice B** (`587885e`) — `T` + `row_ident(tenant)` give ONE source of
  tenant identity; `dst_slot`/`var_slot`/`mirror` are now a derived view.
  `repoint()` (10 call sites) takes `tenant=None`, so all ten are already
  correct when the loop lands.
- **Slice C** (14z-77) — **rows have an OWNER, and every gate asks it.**

**The refusal at `gen_donovan_patch.py` stays until `main()` iterates** — it
states what is implemented, not what the manifest can express. It is now
asserted in BOTH directions by `tests/test_tenant_id.sh`; the loop slice
deletes it and flips that control.

### OWNERSHIP IS DECIDED (maintainer, 2026-08-10): per FILE, stamped by the loader

A manifest file scopes to exactly one tenant — as `recon_overlay` already
does — so `stamp_owner()` tags every parsed row with its file's tenant at load
time. **No manifest edits, now or at the merge.** Each vertical therefore stays
independently buildable and re-freezable as its own reproduction oracle, and
`M3b_plan.md`'s Phase 2 exit gate is satisfied by passing one file. `_owner` is
generator-internal and never written to disk, so the other tools that parse
these manifests see nothing new.

The accessors are module-level pure functions (so `test_tenant_id.sh` drives
them with no build, same reason as slice A's `tenant_context`):
`manifest_owner`, `stamp_owner`, `row_owner`, `is_variant_tenant`,
`row_applies`, `row_hex`; plus one `owner_of(row)` closure in `main()`.

- **Slice D** (14z-77) — the MANIFEST-ROW arithmetic follows the owner too:
  palette table row, `select_records` array row **and its vs2 `src_char`**,
  `data_port slot_ptr_table`, `sound_table ptr_row`, `code_word slot_table`
  (+ its mirror), and the select-wheel's tenant-cell test, which became a SET
  over all tenants rather than an equality against the build's one slot.

### THE REMAINING SCALAR READS ARE NOT ONE CLASS (slice D's finding)

The plan assumed "7 `table_entry_addr()` reads, same mechanical shape as slice
B". Reading them showed **three classes, and only one is answerable by
`owner_of()`** — the other two have no manifest row to ask. The split is
written into the source above `dst_slot`'s definition. Also: **four of those
seven calls are DEAD** — the gap-table block is `for a_t in (man["auto_tables"]
if False else [])`, disabled since the 14w Felicia triangle-jump regression.
Do not budget for them.

1. **EXTRACTION-SIDE** — driven by `man` (regions.json) and the region blobs,
   i.e. the output of ONE tenant's extraction. Under the loop these are
   per-iteration data, not shared rows, so they are correct the moment the loop
   rebinds `T`. **This is the REGION-IDENTITY slice** (M3b_plan Phase 2 item 2:
   key regions by `(src_set, src_addr, len)` so a shared span is placed once) —
   and it is the one that also has to solve Donovan's 12 `x028122` relocations
   rewriting shared bytes H/P do not declare. Sites: the stage-1
   scaffold/trampolines, the OBJ bank-table region fixup, `man["values"]`,
   `engine_dispatch`'s alias probe.
2. **BAKED INTO EMITTED MACHINE CODE** — see below.
3. **OUTPUT NAMING** — `tenant.json`, which becomes an array with the loop.

- **Slice E** (14z-77) — the BAKED-CODE class, mechanical half. All four sites
  now take their id from the row's owner (`win_pal_variant`'s compare+rebase,
  `site_thunk`'s TT/TU and the `row_subst` derived from it) or from `T` rather
  than `port["port"]` (`charid_sites`, the overlay T-select thunk). The two
  `port["port"]` reads were **latent traps**: that dict stays `_tenants[0]`
  forever, so under the loop those fragments would have baked the FIRST
  tenant's id — silently, since wrong-character gating does not crash.

- **Slice F** (14z-77) — `--port` is REPEATABLE and the documents MERGE.
  `merge_manifests()` concatenates owned rows, dedups rows identical apart
  from their owner (engine declarations all three tenants make the same way),
  and REFUSES on anything else. With one file it is the identity, which is
  why it is inert. **The merged manifest is now expressible** even though the
  `>1 tenant` refusal still blocks BUILDING it.

### THE MERGE'S COLLISION SET IS NOW MEASURED, NOT PREDICTED (slice F)

`tests/test_manifest_merge.sh` (~1s) freezes it. Merging the three real
manifests: `[[space]]` 9→3, `[[obj_hook]]` 6→2, `[[select_wheel]]` 3→1,
`[[site_thunk]]` 34→28 (the three `*_bank_variant_id` rows), `[[port_patch]]`
90→87, `[[code_word]]` 13→11, `[[pcrel_escape_fix]]` 7→5 — and 12 collisions,
in **two classes**:

**ZERO REAL BLOCKERS** (was three: `[init_shim]` merged by slice G,
`[table_fix]` by slice H). Nine collisions remain and every one is
base-track-only.

**SIX THAT DISSOLVE.** The `x05c800` / `x088512` `port_patch` rows: Donovan
writes the host band's word where H/P write a no-op — **but all three agree on
`new_hex_variant`**, and a merged build is a WIDE build by construction (a
variant id requires the profile, `tenant_context`'s refusal), so those rows
never take the value they disagree about. Measured, not assumed; the gate
requires each to keep carrying the "dissolves on WIDE" wording, so if the
tenants ever stop agreeing on the variant value it becomes a real blocker
loudly.

This retires "shared-span handling is load-bearing, not an edge case" as an
open worry: it is load-bearing, and it is now three named rows rather than a
category.

- **Slice G** (14z-77) — the maintainer-ratified `[init_shim]` merge.
  Machinery keys must agree; `latch_mode = "phase"` wins if ANY tenant asks
  (the seeder is shared and Phobos needs it); flavor stays per tenant and is
  emitted as an id-dispatched chain when more than one declares it. ONE
  declaring tenant emits today's exact 46 bytes, which is what keeps the
  frozen references bit-exact. Pyron declares no shim, gets no entry, and so
  receives NO flavor write — by construction.

- **Slice H** (14z-77) — `[table_fix]` by per-row UNION. `rows_hex` is the
  vanilla bank table and the generator writes each tenant's row over it, so
  differences on a row a tenant OWNS are safe; a difference on any other row
  still collides. The emitter now writes a row per TENANT, not one for the
  build — region `x026142` is declared by all three, so under the loop it is
  placed once and must carry every tenant's bank word.

### ~~TWO OPEN MEASUREMENTS~~ — BOTH CLOSED (14z-77), one RETRACTION

1. **`(0x382,A6)` DOES hold the character id at char-init.** Measured on both
   player structs, two replays: `$FF8782` and `$FF8B82` both read `0x13` at the
   shim's own address. The `flavor_tail` chain is sound. Gate
   `tests/test_shim_charid.sh` (~44s). New instrument:
   `GUARD_PROBE_MEM="<reg>+<hexoff>"` on `replay_guard.lua`.
2. **Phase mode is NOT inert for Donovan — my slice-G prediction is
   RETRACTED.** Legacy is bit-identical (4 replays, 30,284 frames — the shim
   is hosted on the tenant's dispatch row, so legacy never executes it), but
   his OWN content diverges at the exact frame the shim runs, for 24-135
   frames in 13-16 short runs, then **fully re-converges** — 6,000-9,700
   identical frames after, including a complete round-2. A bounded transient
   in his char-init pool state, invisible to legacy. **Whether it is
   acceptable is a maintainer call**; the measurement exists now.
   `tests/audit_phase_mode_cost.sh` (on-demand, ~15 min).

**RIG LESSON, paid for again.** The char-id probe first returned ZERO hits,
which reads as "the shim never runs". A positive control on the same
instrument showed the probe was armed — so the zero was a fact about the RIG:
replay 11 never forms a Donovan match on this build. Forced-pick pokes fixed
it. Both new gates now open with that control.

### NEXT SLICE — region identity, then the N-way dispatch FORM

**1. Region/extraction identity — MEASURED 14z-77, and it is THREE mechanisms,
not one.** M3b_plan Phase 2 item 2's "a shared span is placed ONCE" holds for
most spans but NOT for four of them. `tests/test_region_overlap.sh` (~1s)
freezes the picture; `tools/audit_region_overlap.py` produces it.

- **7 generic names need per-tenant NAMESPACING** — `anim`, `code`, `hitbox`,
  `hitbox_proj`, `aux0_0..2` are the same name for completely different spans,
  one per tenant. Not shared at all.
- **`x088512` needs the UNION EXTENT** — same start in all three, three
  lengths (D 0x2F00, H 0x3B98, P 0x3B40).
- **4 shared spans CONFLICT and cannot be placed once** — `x026142` (54
  bytes), `x028122` (50), `x05c800` (348), `x2b7ef4` (1548): **2,000 bytes**
  where two or more tenants write DIFFERENT values to the SAME field. Only one
  can ship, so each needs a per-tenant COPY or a per-character INDIRECTION.
  The disjoint *1-differs* bytes (1,674) are the `[table_fix]` shape
  generalised — one tenant's own row — and those DO union cleanly.
- 13 further shared spans are H+P only and are reported **UNDECIDABLE**, not
  zero: with two tenants "one differs" and "both disagree" are the same
  observation.

**Do not quote an un-normalised conflict count.** The three references are
independent builds whose allocators chose different addresses, so a pointer
into a shared region reads as a conflict spuriously — that artefact is **73%
of the raw figure (7,591 -> 2,000)**. Section 3 of the gate is the control.

**The conflicting bytes are IDENTIFIED (14z-77), and they make the answer
simple.** 3-byte runs dominate — a 4-byte pointer whose top byte agrees — and
they point overwhelmingly at **`anim`**, which is a different source span per
tenant. These shared spans are shared CODE each tenant specialises with
pointers to its own data. Each tenant's clone is SELF-CONTAINED: the OBJ bank
table inside `x026142` has 14 `1-differs` bytes and ZERO conflicts, so no union
is needed. **Per-tenant COPIES resolve everything; sharing is an optimisation,
not a requirement.**

### THE REAL BLOCKER IS PC-REACH, NOT SIZE — and it is quantified

If every tenant keeps its own copy of what it places today:

| space | needed | capacity | |
|---|---|---|---|
| `hole_a` | 761,316 | 264,544 | **overflows by 496,772** |
| `hole_b` | 171,614 | 80,096 | **overflows by 91,518** |
| `wide_ext` | 45,580 | 2,097,136 | fits, 2,051,556 spare |

The regions fit the image many times over; the CRYPT-window spaces are
saturated **by one tenant**. And regions live there for **reach, not
encryption** — code above `PRG:0x0FFFFF` is stored raw and runs
(`tests/test_crypt_boundary.sh` locks that).

**So the next slice's question is: which regions GENUINELY need PC-reach, and
which are in `hole_a` only because the allocator filled the nearest space
first?** `wide_ext` has room for all three tenants with 2 MB spare. Start from
`near_map` and the pc-relative escape machinery — those name the reach
constraints explicitly. Everything is frozen in
`tests/test_region_overlap.sh`, so the target does not move.

**2. The N-way dispatch form** — what slice E deliberately did NOT do. Each
baked fragment still tests ONE id, and the sites are SHARED: all three tenants
declare `name_bank_variant_id` (0x5FCE0), `splash_bank_variant_id` (0x6C0E0)
and `winquote_bank_variant_id` (0x5F328) as byte-identical rows, and
`win_pal_variant` is one thunk at one site (0x5F1B6). The merge must dedup
each to ONE thunk whose body tests N ids — a compare chain, or a generated
32-row table where the site is semantically a per-char lookup (M3b_plan Phase
2 item 4: "manifest declares bodies; generator owns gates"). That is a design
decision, not a mechanical edit, and it is the last thing before the loop.

> **ORDERING INVARIANT (14z-77).** The N-tenant loop lands only after all four
> classes are converted: gating (C, done), manifest-row arithmetic (D, done),
> baked-code identity (E, done), and extraction/region identity — plus the
> N-way dispatch form above. Landing it earlier ships a build whose gates
> consult the row's owner while its arithmetic consults tenant `[0]`.

### The gate that makes an inert slice checkable

`tests/test_tenant_row_owner.sh` (14z-77, ~9s, needs `ROMDIR` and an extract
dir; SKIPs without one). The fingerprint gate proves the values did not move —
which a threading accidentally **disconnected** from the emitted ops would also
do. This one perturbs ONE owner-derived row at a time, running the GENERATOR
ALONE against an existing extract dir, and requires `patch.json` to change.
Seven sites, plus a negative control that perturbs an intentionally UNUSED
binding and requires the checker to call it dead. **Run it with the fingerprint
gate on every further M3b machinery commit** — the two answer opposite
questions and neither substitutes for the other.

It perturbs `tools/gen_donovan_patch.py` in place; the trap restores on EXIT/
INT/TERM and section 3 asserts byte-identity independently (verified against a
mid-run SIGINT).

## Carried into M3b — gate defaults point at intermediate builds

Several tenant gates default to superseded interim builds (`pyron17`,
`pyron18`, `hui25`) rather than the frozen ones (`pyron20`/`pyron-m2`,
`hui27`/`huitzil-m2`). Left alone deliberately in 14z-76: some of those
defaults are the gate's designed pre-fix REFERENCE (e.g.
`PYRON_BLINK_EXPECT=blinks` reproduces on `pyron15`), so retargeting them
blind would break their semantics, and the build dirs are untracked so a
fresh checkout has none of them anyway. **The merge has to repoint all of
them at the merged build regardless** — do it there, per gate, checking
what each default is FOR. HANDOFF's stated defaults were corrected to match
the code in 14z-76.

## RECOMMENDED: a stale-doc sweep, and a cheap gate that would catch it

`docs/project/playtest_m3a_interims.md` sat stale for FOUR sessions reading as
a live bug list ("HUD plate says VICTOR", "medallions placeholder") when every
item had been fixed in 14z-63/64. It was found by accident, not by process.
Assume others like it exist.

**The sweep, in priority order** (cheap, do it before trusting any doc that
describes defects):
1. `grep -rln "1464942a\|m5w\|hui1[0-9]\|pyron1[0-9]\|donovan-m5w\|huitzil-m1\|pyron-m1" docs/`
   — any doc naming a SUPERSEDED build is a staleness candidate. Check each
   against the registry in `HANDOFF.md`.
2. Grep for defect-list vocabulary — "EXPECTED", "do not report", "known
   issue", "interim", "placeholder" — and verify each item against the current
   frozen builds.
3. Fix HEADERS and status lines first, keep the original text, mark it
   HISTORICAL with the build it describes (CLAUDE.md §5 retraction discipline).

**The gate worth writing (would have caught this one).** Any doc naming a
build fingerprint or build-dir id must EITHER name one that is live in
`tests/expected/registry.tsv`, OR carry an explicit `HISTORICAL` /
`SUPERSEDED` marker. `playtest_m3a_interims.md` named `1464942a`, which is in
no registry row and had no marker — a mechanical check would have flagged it
the session after it went stale. Small, static, no emulator; the same shape as
`test_index_space.sh`'s frozen-counts section.

**The underlying rule this project already has and did not apply to itself:**
a document describing a BUILD must say which build, in its header. Registry
rows do this; playtest guides did not.

## Instrument blind spots still open

1. **The extractor's dead-filler classifier is VIEW-BLIND** — it compares
   siblings in the OPCODE view, where embedded data always differs. It
   labelled the air-dive velocity table "dead filler". Discriminator: if the
   siblings' DATA views match, it is DATA.
2. **`tools/census_regions.py` bails in `_redefines_an`** on
   `lea (An,Xn),An`. Re-run the census across all tenants after fixing.

## Gates added in 14z-75

- `tests/test_variant_dispatch.sh` + `tools/audit_variant_dispatch.py` — the
  aliased-variant-row sweep. Run it for every tenant.
- `tests/test_pyron_blink.sh` + `tools/check_pyron_blink.py` + replay 76.
- `tests/test_pyron_cosmo.sh` — rewritten: the withdrawn engine word must
  stay out, the EX must FIRE, and rig 72 must not reset.
- Replays 76-82 (blink rig, Cosmo rigs incl. the two that reproduce) and
  `40_pick_pyron_cell.rpl` (real wheel pick onto his cell).
