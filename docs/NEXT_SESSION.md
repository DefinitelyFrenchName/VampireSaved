# NEXT_SESSION — 60-second orientation (rewritten every session end)

As of 2026-07-25, end of session 3. **M1 ACCEPTED.**

**Where we are:** M0 + M1 complete. Harness (both emulators, deterministic,
10-replay suite green/frozen) and the full character-data map are done. See
`docs/M1_acceptance.md` for the clause-by-clause sign-off.

**What's solid:**
- vsavj slot→character map 16/16 pick-verified.
- Donovan 0x13 / Pyron 0x11 / Huitzil 0x10 pick-verified in BOTH vsav2 and
  vhunt2; handler code, anim bases, hitbox bases recorded per set.
- Per-character table bank labeled; layout identical across all 3 sets.
- Pipelines mapped end-to-end: code, animation, sprite/tile chain, palette,
  sound — all in docs/atlas/character_tables.md + ram.md.
- **R2 quantified:** CPS2 OBJ tile field is 16-bit; GFX needs 18-19 bit —
  the real graphics ceiling. Top technical risk; first M3 investigation.

**Two things waiting on the maintainer (neither blocks M2 prep):**
1. **M2 replaced-slot sign-off.** Recommendation: **replace Jedah (slot
   0x0F)** — footprint fits Donovan (+660 B headroom), boss character so
   least playtest disruption, keeps Demitri/Victor (harness controls). Full
   size table in STATE.md decisions-pending.
2. **SPEC §2 Start-hold fact** — did not reproduce in vsav2; flagged for
   community check (STATE.md). Since vsav2≡vhunt2 data is byte-identical,
   the VS2-vs-VH2 variant policy may simplify.

**M2 plan (make-or-break milestone):** make Donovan selectable in vsavj by
replacing the chosen slot across the table bank — swap that slot's rows
(hitbox base, +0x64/+0x132, code dispatch, anim base) to point at Donovan's
data, inject his data blobs (from vsav2, since data ≡ vhunt2) into free ROM
that doesn't move legacy content, decrypt/re-encrypt the program changes via
tools/cps2_decrypt.py, build via the manifest pipeline. Acceptance: full
Donovan matches + ALL legacy replays still bit-identical (superset
invariant) + crash-free soak. This is where reconciliation (R1) gets real —
VS2 data on the vsavj engine may hit rule deltas; the harness surfaces them.

**First M3 task (parked):** decode the OBJ `attr` bitfield to learn how tile
high bits / bank are supplied and whether frame tile#s are per-character-
relative — determines M3 difficulty.

**Read:** docs/M1_acceptance.md, STATE.md, docs/atlas/character_tables.md,
docs/atlas/ram.md, docs/GOTCHAS.md.
