# NEXT SESSION — orientation (written at the close of 14z-86, 2026-08-15)

> ## START HERE — THE SWORD-PLANT "DING" FIX (rig + design ready)
>
> The M5 voice batch is SHIPPED AND FIELD-CONFIRMED ("the sounds are
> normal now among all 3 newcomers"): donovan-m4 (`build/don_m4`,
> `84f49aaa`) / huitzil-m12 (`build/hui39`, `e1f598d6`) / pyron-m6
> (`build/pyron24`, `4c6e3fb6`), merged **build/m3b_merged6**. Full
> battery green (suites, voice keyon gate, ear-level WAV gate, trap
> gates, merged legacy audit).
>
> **THE ONE OPEN AUDIBLE ITEM** — Donovan 214+K sword plant ends with
> a "ding" vs2 doesn't have. DIAGNOSED, not a port defect
> (engine_internals "per-node sfx dispatch, second pass"): a shared
> engine effect dispatches per-node sound with SOUND CLASS 0x0C (the
> (0x382,A6) byte is a CLASS — engine effects override it); each
> game's own effect anim carries a different sfx node — vs2 node 28 →
> 0x29B (the proper thunk), vsavj node 13 → 0x308 (an ordinary vsavj
> chime, foreign in context). vsavj's 0x29B is content-identical to
> vs2's, so the native sound is expressible.
>
> **THE FIX PLAN**:
> 1. Find the class-0x0C WRITER (the one open measurement): a byte
>    write-watch on $FF8782 caught NO write in the dispatch window —
>    suspect a RAM-MIRROR write (watch the mirrors too) or a
>    wider-window write. Rig: tests/replays/don/90_don_plant.rpl;
>    the dispatch fires ~f3999 (debug timeline), dispatcher head
>    0x27F16, char-read bp at 0x27F1A shows D1=0x0C.
> 2. If the writer is TENANT-REACHED code (Donovan's ported plant
>    handler or an effect it spawns): patch OUR write 0x0C → 0x1C
>    (variant row, no legacy path writes it) + place a curated
>    14-node array at row 0x1C (node 13 = {0x29B, 0x29B, 0}) via the
>    existing table machinery. Native sound, zero legacy surface.
> 3. If the writer is pure engine code: the brief goes back to the
>    maintainer with options (accept as the per-game-voice class like
>    010A/010B, or an aimed thunk).
> 4. Re-run the plant rig ring A/B (ours must fire 0x29B in the
>    window; the 0x62B/0x308 pair gone) + an ear-check.
>
> **THEN: the voice-scope odds** (the remaining M5 sfx tail):
> 0x112 / 0x14a / 0x173 / 0x31B etc. — same-id-different-content ids
> whose vs2 content is absent on vsavj (the don recon KEPT-SILENT
> rows list them). The machinery is complete: resolve statically
> (audit tool), author songs/records via qs_songs (BOTH packing laws
> enforced), remap per tenant, verify with the keyon + WAV gates.
>
> **Carry-forward notes:**
> - The 14z-86 close battery is ALL GREEN incl. the merged6 legacy
>   audit (AUDIT-EXIT 0) — no gap carries to S6.
> - Tenant-content .sha1s were RE-FROZEN deliberately (the restored
>   voices now play, shifting those replays' timelines — don's
>   win/lose, pyron's pick); legacy masked classes held throughout.
> - The facing-alias skip for voice ids 0x58-0xA6 is a DOCUMENTED
>   DEVIATION (channel allocation only — 74/81 native alias songs are
>   slot-only twins); revisit per-id via the 38 free pairs if play
>   ever objects.
> - The flaky Sasquatch-intro crash rig (STATE 14z-85f) stays armed.
> - COMPAT: pre-WIDE-v1.1 builds don't boot on current binaries
>   (vsw.z01/z02); several frozen dirs were upgraded in place with
>   stock members (fingerprint-verified).
>
> ## Load-bearing laws from 14z-86 (do not re-derive)
>
> - QSound playback laws: HALF-BANK (signed pointer compare) +
>   BYTE-PARITY (pre-swapped members) — both enforced in
>   tools/build_qs_songs.py, both gated by audit_qs_voice_wav.sh.
> - Register/content-level A/Bs are BLIND to consumer-semantic
>   classes; keep one gate at the OUTPUT level.
> - The Z80 is NOT KABUKI; driver addresses are flat member-concat
>   offsets; the full decode is engine_internals "The QSound Z80
>   driver" (+ second-pass sections).

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged6 | UNREGISTERED (pending S6 freeze) | moves with generator (729 ops) |
| build/don_m4 | **donovan-m4** | 84f49aaa |
| build/hui39 | **huitzil-m12** | e1f598d6 |
| build/pyron24 | **pyron-m6** | 4c6e3fb6 |
| build/m5_stock | stock twin (unchanged — the batch is profile-gated) | 6c93cfa8 |
| build/hui38, pyron23, m5_wide | superseded m11/m5/m3a (tags are the way back) | — |

## Still open (the short list)

- **The sword-plant ding** (this session's opener — rig + design ready).
- The M5 sfx odds (0x112/0x14a/0x173/0x31B family).
- FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
- Pyron's medallion whitening on 2P hover (row-0x1A family).
- H-vs-P stuck-direction (~1/30, possibly emulator-side).
- Round-end flicker (parked; needs the maintainer's recording).
- Win-screen QUOTE (both tenants); select medallions polish;
  region_space re-freeze; op-tagging for test_shared_writes.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2
tools/build_merged.sh build/m3b_merged6      # ~15 min (729-op fixture)
tests/audit_qs_voice_batch.sh build/m3b_merged6  # ~10 min — keyon A/B
tests/audit_qs_voice_wav.sh build/m3b_merged6    # ~12 min — EAR-level A/B
tests/audit_trap_parity.sh build/m3b_merged6 # ~5 min — ejection+chirp
tests/test_qs_songs.sh                       # ~30 s — song machinery
tests/test_qs_id_table.sh                    # ~5 s — Z80 census
tests/test_tenant_loop.sh                    # generator gate (531/729)
tests/test_m3a_reproducible.sh               # ~6 min (all four refs)
MERGED_OUT=build/m3b_merged6 MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh               # ~45 min (green at close)
```
