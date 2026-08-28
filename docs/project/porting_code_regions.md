# Porting a CODE region: bounds, pc-relative tables, and escapes

How to root a block of vs2/vh2 code so it still works after we move it.
Four sessions have been spent on variants of one mistake — **a region's
bound cut off data the code inside it reaches pc-relatively** — so this is
the checklist that mistake earns.

**The underlying facts** (game/platform, true regardless of this project):
the engine reaches most of its tables **pc-relatively**, and CPS-2
**decrypts opcode fetches only** — a data read returns the bytes as
stored. See `../game/atlas/sprite_lists.md`, `../platform/gotchas.md`.

---

## Why a bound is dangerous

A pc-relative reference is only correct if its target keeps the **same
relative distance**. Move the code and leave the table behind, and the
pointer resolves to whatever now sits at PC+displacement — which, because
the allocator packs regions back to back, is usually *the next region's
bytes*. The failure is silent: real code reading real bytes, with no
crash and no empty tile.

Two paid instances:

| region | what was cut | symptom |
|---|---|---|
| `x06cac0` | 7 pc-rel data tables past the declared bound | the row-8 effect machine read unrelated bytes as parameters (14z-69h/i/j) |
| `x088512` | 3 tables 0x38/0x48/0x50 past the old end | resolved to `0x0D8988/98/A0` — **inside the anim region placed immediately after** — so the machine read animation bytes as its parameters (14z-70c) |

The second is the clearest statement of the hazard: the region was
"working" for many sessions, and the corruption was reading the neighbour.

---

## **[VSP-62]** The four checks, before you build

Run all four on any new root. The `x093460` root (14z-71, the beam
handler) is the worked clean case: it passed all four, and it built and
ran correctly first time.

### 1. Bound the region by the SIBLING ORACLE, then check what it cut

`extract_char.py` extends a twinned root while the vs2/vh2 diff keeps
classifying, and stops where the siblings stop agreeing. That stop is
usually right — but it is a *content* boundary, not a *reachability* one.
Ask what falls just past it.

`:f` forces the declared length past the oracle's stop, marking
`[stop, len)` a **dead zone**: unvalidated, copied verbatim, not diffed
and not scanned for pointer fields. Only force **plain-value tables** —
if the forced tail contains pointers, nothing validates them.

*Example:* `0x93460:0x306:t0x9306c:f` — the oracle stopped at +0x300 for a
real reason (its next chunk reaches the neighbouring family's genuine
divergence), but the routine's last instruction pair straddles +0x300.
Six forced bytes, hand-verified byte-identical in the sibling.

### 2. Census the pc-relative DATA tables (`census_regions.py`)

Two reader shapes, both scanned:

- **indexed** — `lea (d16,pc),An` immediately followed by
  `move.x (An,Xn.w)`;
- **post-increment** — `lea (d16,pc),An` … later … `move.x (An)+,<ea>`,
  arbitrarily far away and in another basic block, as long as `An` is not
  redefined. The measured case has its reader 0x3E bytes later inside a
  local subroutine, which is why an "immediately after" rule can never
  see it.

Any hit whose target lands inside a code-kind region needs a
`[[data_in_code]]` row **before that region may be crypt-placed** — see §4.

### 3. Census the pc-relative BRANCH escapes

Word-form `bra/bsr/Bcc.w` whose target leaves the region. Invisible to the
sibling oracle (both siblings preserve spacing) and unrewritable in place.
A relocated region executing one branches into unrelated bytes.

Fix with `[[pcrel_escape_fix]]` (a trampoline pad sized to the escape
count) and resolve each target through the R1 map. Measured inventories:
`x02592a` 35 unique targets (pad 0x120), `x026142` 7 (pad 0x60),
`x05c800` 2.

### 4. Check the region contains the CONSTANTS its own code loads

A routine that loads an absolute or pc-relative literal needs that literal
inside the span, or relocated. Check the boundary against the routine's
own operands, not just against where the disassembly "looks finished".

---

## **[VSP-63]** Crypt placement: opcode vs data views

A region placed in the crypt hole (`hole_a`, below `PRG:0x100000`) is
stored **re-encrypted**, so opcode fetches decrypt correctly and **runtime
DATA reads see garbage**. Any table inside a crypt-placed code region that
is read as data must be emitted RAW.

- `:fN` on a root splits the region: `[oracle_stop, N)` stays encrypted
  code, `[N, len)` is emitted raw. The split point is the **first table**,
  not the oracle boundary — the bytes between can still be live code
  (measured at vs2 `0x6D6C0-0x6D768`, an object-spawning continuation).
- `[[data_in_code]]` handles the other direction: relocate the table's
  data-view bytes to a raw hole and reroute the reader through a 12-byte
  helper. Only the `lea + move.b (a1,d0.w),d0` shape is supported; it is
  ghost-clean because the helper's `move.b` sets NZ exactly as the
  displaced one did.

The FG capture-pose crash was this class: a 16-byte random table embedded
in crypt-placed code, read as data, returning 0xFF where native reads
01/03/05, over-running the victim's capture table.

---

## Verifying afterwards

- `tools/verify_pcrel_data.py` — resolves each region's pc-rel data
  pointers in the BUILT image and reports BROKEN ones. This is what turned
  "the ported machine reads garbage" from a theory into three named
  tables.
- `tests/test_census_regions.sh` — ground-truths the censuses themselves
  against Huitzil's frozen inventory before their numbers are trusted.
- `tests/test_patch_overlap.sh` — two ops writing one word is a named
  build error, not a silent last-writer-wins.

---

## **[VSP-64]** The habit that would have saved all four sessions

**Put an execution breakpoint on code before attributing a symptom to it.**
`x088512` had genuinely broken tables *and* was the region the explosion's
machine lived in — both true, and unrelated: the code that reads those
tables never runs in that scenario. Co-location is not causation, and one
breakpoint costs a single run.
