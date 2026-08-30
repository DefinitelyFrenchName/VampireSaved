# Per-tenant manifests — HISTORY (blocks moved verbatim from `tenant_manifest.md`)

Moved at 14z-122 by the documentation rationalization pass. Historical
entries are not rewritten; corrections live in `tenant_manifest.md`. These
blocks are the single-tenant-era framing the 14z-118 audit already labelled
HISTORICAL ("true when written, superseded 14z-64 and 14z-8x"): the "Why
this shape" argument for leaving slot 0x0F, and the migration plan whose
steps all happened. The measured id-writer invariant quoted in "The prize
in step 2" lives canonically in `docs/game/atlas/id_space.md`
(`tests/audit_id_writers.sh`). No `**[PFX-N]**` anchor lives in this file.

*(moved from `tenant_manifest.md` at 14z-122)*

---

## Why this shape

"Tenant" = one ported character occupying one character id. Today the port
is single-tenant and hard-wired: `build/manifest/donovan.toml` has one
`[port]` block with `dst_slot = 0x0F`, and `mirror_variant = true` patches
both `0x0F` and `0x1F`. That was right for proof-of-life. It does not
survive three characters, because:

- **Three tenants need three ids, and the ids are no longer a free choice.**
  `docs/game/atlas/id_space.md`: the newcomers should take their **native vs2
  ids** — Huitzil `0x10`, Pyron `0x11`, Donovan `0x13` — so every ported
  bank row lands at its own index with no renumbering, and so the wheel
  cells match what vsav2 already ships.
- **`mirror_variant` stops making sense.** It exists because slot `0x0F`'s
  variant row `0x1F` aliases it in vanilla. A tenant that IS a variant id
  has no mirror; a tenant at `0x13` must not touch `0x03` (Victor).
- **The work is not only "data at index N".** Measurement turned up three
  separate registries a tenant must appear in — the select wheel, the
  arcade opponent ladder, and the id-folding sites — and none of them is
  implied by the others.

## What this replaces, and the migration

`[port]` becomes `[[tenant]]`, and `mirror_variant` disappears. The
single-tenant Donovan build is expressible as one `[[tenant]]` with
`id = 0x0F` — but the point of the change is to move him to `0x13`, which
is a behavioural change and needs the full battery plus a playtest, not a
refactor commit. Sequence that keeps each step falsifiable:

1. Land the schema with **one tenant at `id = 0x0F`** and prove the built
   image is byte-identical to today's (`ae701ffb` stock / `ac52eeff` WIDE).
   A refactor that moves zero bytes is the same discipline Phase C used.
2. Move that tenant to `id = 0x13` as a **separate** commit, with its own
   battery run and playtest. Expect the superset invariant to get *easier*
   here, not harder — see below.
3. Only then add Huitzil and Pyron.

## The prize in step 2

Measured so far (`id_space.md`): across the legacy corpus, every gameplay
writer of the character id writes a value in `0x00-0x0F`. If that holds,
a tenant at `0x13` occupies rows **no legacy path can reach**, and the
superset invariant stops depending on careful in-place surgery — the
current slot-`0x0F` port needs that surgery precisely because legacy
cursors visit Jedah's cell and legacy code reads his records.

That is the strongest argument for the move, and it is exactly why it must
be measured rather than assumed before step 2 is attempted.

