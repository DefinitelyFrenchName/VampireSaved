# Per-tenant manifests — proposed schema

**Status: PROPOSAL, not implemented.** Written 2026-08-05 (14z-60h) now that
the id-space question is answered and the shape of the work is measured.
Nothing in the build pipeline consumes this yet. It is here to be argued
with before code is written against it.

## Why this shape

"Tenant" = one ported character occupying one character id. Today the port
is single-tenant and hard-wired: `build/manifest/donovan.toml` has one
`[port]` block with `dst_slot = 0x0F`, and `mirror_variant = true` patches
both `0x0F` and `0x1F`. That was right for proof-of-life. It does not
survive three characters, because:

- **Three tenants need three ids, and the ids are no longer a free choice.**
  `docs/atlas/id_space.md`: the newcomers should take their **native vs2
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

## The schema

```toml
[[tenant]]
name        = "donovan"
src_set     = "vsav2"
src_char    = 0x13
id          = 0x13          # the character id it OCCUPIES in the output.
                            # 5-bit. No mirror: a variant id has none, and
                            # a base id's mirror is a separate tenant's
                            # business or nobody's.

  # ── select wheel (docs/atlas/select_screen.md) ──────────────────────────
  [tenant.wheel]
  cell      = 0x13          # MUST equal `id`: the commit site writes the
                            # same byte to $03(a6) and $382(a6). Declared
                            # anyway so a mismatch is a build error rather
                            # than an assumption.
  position  = [x, y]        # screen centre, same frame as the measured map
  adjacency = { R=..., L=..., D=..., U=..., DR=..., DL=..., UR=..., UL=... }
  # neighbours whose rows must gain an edge INTO this cell; without these
  # the tenant is drawn but unreachable.
  reachable_from = [ { cell = 0x0C, dir = "R" }, ... ]

  # ── arcade ladder (docs/atlas/id_space.md) ─────────────────────────────
  [tenant.ladder]
  in_opponent_list = true   # append to the order list at a5-0x61b8 and
                            # bump its length at $138(a5); the already-
                            # fought mask is btst.l, already 32 bits wide
  vs_palette       = "..."  # content for PRG:0x3A3CA0 + id*32

  # ── id-folding sites (the finite list) ─────────────────────────────────
  # One decision per site, and the build must fail if a site is missing
  # rather than silently inheriting.
  [tenant.folds]
  "0x04FAC4" = "widen"      # its table already has 32 rows: fill + #$1f
  "0x010E2C" = "widen"      # id-cycling selector, exactly as vsav2 ships
  "0x010E3A" = "widen"
  "0x00A43E" = "widen"      # venue-asset arrays (16-wide) must grow first
  "0x0409EC" = "inherit"    # slot-6 behavioural test
  "0x003E40" = "inherit"    # anim block 0x360-0x36F is genuinely 16 wide
  "0x004082" = "inherit"    # MAINTAINER DECISION, STATE "Decisions pending"

  # ── data placement (unchanged in kind from today's manifest) ───────────
  [tenant.space]
  profile   = "cps2-wide-v1"
  hole      = "wide_ext"
```

## Rules the loader should enforce

These are the places a silent wrong answer is possible, so each gets an
assertion rather than a convention:

1. **`wheel.cell == id`.** Measured, not assumed — the commit site writes
   one value to both fields.
2. **No two tenants share an `id`**, and no tenant takes an id vanilla
   uses: `0x00-0x0F`, plus **`0x18`** (Oboro Bishamon) and any other
   variant row measured as `distinct` in `id_space.md`.
3. **Every folding site in the measured list appears in `[tenant.folds]`.**
   If the census grows — and it has already grown once, from five sites to
   seven — a tenant manifest that predates the growth must FAIL rather than
   quietly inherit at the new site. Cross-check the keys against
   `tools/audit_id_space.py` output at build time.
4. **`reachable_from` is non-empty** and every named neighbour's edge is
   actually written. A cell with no inbound edge is invisible to the
   cursor: the wheel graph's `entry-only` class is exactly that failure
   mode, and `tools/select_wheel.py` already detects it.
5. **A tenant may not declare a row in a table whose per-id LAYOUT is
   unverified** (`rec8`, `byte2d`, `auto` gaps). Writing a speculative row
   into engine space is the Felicia wall-jump defect, and the rule earned
   there was "no write without a decoded consumer".
6. **Stock-profile builds reject tenants that need the extension**, by
   construction — the existing profile gating already does this and must
   keep doing it.

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
