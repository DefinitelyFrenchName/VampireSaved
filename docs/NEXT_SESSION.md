# NEXT SESSION — orientation (written at the close of 14z-88, 2026-08-15)

> ## FIRST TASK — THE MAINTAINER'S RULING ON THE 14z-88 REGRESSION
> ## (STATE "DECISION PENDING — 14z-88"; recommended: REVERT the
> ## medallion move, then fix the collision on the portrait side)
>
> 14z-88 applied the ratified row-0x1D window (V3 basis, below) and, in
> attributing the moved tenant `.sha1`s before re-freezing, MEASURED that
> the 14z-87b medallion move (Pyron pal_row 0x1A -> 0x1D) makes replay 38
> (P1 Victor vs P2 Jedah on cell 0F — ids identical to vanilla, a LEGACY
> pairing) lose one main-loop iteration at the select->VS fade on the
> huitzil-m14 / pyron-m8 / merged7 builds: whole-RAM vs vanilla never
> re-converges (pre-move builds: the ordinary composite 829 + window
> 889-2091, 2909 identical after). Root cause: the fade's per-color work
> is data-dependent and that frame already runs at the VBL edge; the
> palette content on row 0x1D crossed it. A 0x1B probe moved OTHER frozen
> inventories and 0x1B is OBJ-used anyway. Options and recommendation are
> in STATE; NOTHING was re-frozen — the three suites are RED on the tenant
> `.sha1` rows by design until the ruling. If REVERT: `wheel_layout_
> proposed.json` cells.11 pal_row 29 -> 26 reproduces donovan-m5 /
> huitzil-m13 / pyron-m7 (3c599fb6 / 2629561c / 94ce9a48, all frozen
> sets green; the V3 window then hides nothing and the sets go back to
> the V2 basis — keep masked-v3 + the tools; the P2-ring-on-Donovan
> whitening returns until the portrait-side fix). ALSO close the coverage
> gap that let this hide: promote the P2-human legacy pairings (31-40
> victor family, and any replay whose loaded ids equal vanilla's) from
> `.sha1` to `.masked` legacy classes on every set + into
> audit_merged_legacy's list.
>
> ## What landed (14z-88), keep:
> V3 masked basis: mask `043c-043d,4182-41a2,41c2-41e2,4222-4262,42a2-
> 42c2,7f00-8000` + `tests/expected/vsavj/masked-v3/` (`tools/freeze_
> masked_basis.sh` — a window is a BASIS: masked bytes are skipped from
> the checksum, so the vanilla side is regenerated under the same mask);
> the 13 shared legacy `.masked` replays hold their FROZEN classes on all
> three sets; audit_merged_legacy 14/14 + leg (b) clean on V3; hui_boot /
> pyron_ladder / tenant_select_records green. Solo donovan-m6 replay 11 =
> `composite 2836 889-2415` (MAINTAINER-RATIFIED 2026-08-15: the merged-
> ratified one-frame slot-0x0B staging phase, writer PRG:0x01C3BA, now on
> the solo build too). `tests/audit_mask_window_ff42a2.sh` = the pre/post
> attribution instrument (rebuild the pre-move builds in a worktree at
> e6abaa9^; accepted classes: staging area, OBJ-chain return address at
> $FF06DE, the $FF80B5 latch). Maintainer field results the same day:
> merged7 medallions CLEAN for every hover combination (polish check
> CLOSED — but see the decision); H-vs-P stuck-direction not reproduced —
> keep listed, assume emulator-side or resolved.

> ## START HERE — the open list, in order
> - The M5 sfx odds (0x112/0x14a/0x173/0x31B family — machinery ready).
> - FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
> - Round-end flicker (parked; needs the maintainer's recording).
> - Win-screen QUOTE (both tenants); region_space re-freeze; op-tagging
>   for test_shared_writes.
> - H-vs-P stuck-direction (~1/30) — possible; not reproduced recently.
> - Then MiSTer core surgery (stretch, DECIDED below) — after the roster.

> ## ALSO DECIDED (maintainer, 2026-08-15) — MiSTer decision space:
> a "17-character variant" is NOT numerically possible (D+H alone
> overflow 4MB PRG by ~310KB; only ONE added character fits the stock
> image's ~345KB holes — H borderline at +45KB, D/P clean). The two
> real options as the maintainer frames them: (1) current core =
> Donovan-substitution (m5_stock shape; NOTE: loses Jedah, and carries
> pre-M5 voices unless a QSound-extended stock variant + the 4-line
> width fix ships); (2) jtcps PRG-cap surgery for all three (+ our
> 32MB GFX repack profile + the width fix; ~54MB total fits the 64MB
> tier). **DECIDED (maintainer, 2026-08-15, session close): "the only
> way forward for MiSTer is core surgery, full stop."** The substitution
> track is NOT a MiSTer deliverable; MiSTer ships all three or waits.
> Scope when picked up: jtcps PRG-cap lift (+ possibly JTFRAME_SDRAM_XL)
> on the core side; our side = the 4-line QSound width fix + a
> MiSTer-shaped WIDE profile (GFX repacked <=32MB, ~54MB total) with its
> own full gate battery per the dual-track doctrine. Stretch-goal
> priority — after the roster work, not before.

> ## BACKGROUND (14z-87/87b) — the voice-borrow fix, ear-checked clean
>
> 14z-87 root-caused the sword-plant "ding" (the engine VOICE-CLASS
> BORROW at `PRG:0x0AEF6` hands a tenant a random vanilla voice class —
> engine_internals "per-node sfx dispatch, third pass") and, on the
> maintainer's same-day b+c ruling, SHIPPED the fix — since superseded
> by the 14z-87b batch: **donovan-m6 (`build/don_m5`, 57754602) /
> huitzil-m14 (`build/hui40`, 66feb5e8) / pyron-m8 (`build/pyron25`,
> fab92eb7), merged `build/m3b_merged7`**
> (738 ops). Tenants now KEEP their own voice class (the
> `voice_borrow_keep_tenant` thunk, skip-write-only, exact id set
> {0x10,0x11,0x13}) and vs2's candidate/voice-number table rows are
> ported over the variant aliases. Stock twin BIT-IDENTICAL (6c93cfa8).
> Full battery green: three solo suites frozen+verified (only 5/5/6
> tenant-content .sha1s moved, mechanism-attributed — dead-stack
> hook-cycle bytes + intended voice content; legacy masked classes and
> flicker inventories UNCHANGED), audit_voice_borrow own-class on solo
> AND merged (lottery = ground-truth-fail vs build/don_m4, kept), m3a
> all-four, tenant_loop 270/305/239 + 538/738, merged legacy audit PASS,
> trap parity PASS.
>
> **14z-87b (same day): THE PLANT BEEP ITSELF ROOT-CAUSED AND FIXED,
> ear-confirmed** — QSound packing law #3 (the record `end` offset plays
> INCLUSIVE; the packer copied exclusive, so packed samples' last played
> byte held the next blob's head — 3 of 57 records contaminated, one
> fired at every plant as a ~1.85kHz impulse-train beep). Packer fixed,
> law-3 gate added to test_qs_songs (green 57/57 + verdict control),
> all four artifacts rebuilt with PROGRAM FINGERPRINTS UNCHANGED (only
> sound members moved), keyon/WAV/trap gates green. ALSO: rigs 90/91v1
> NEVER FORMED A MATCH (no joins/confirms — gotcha filed); rig 91 is
> the fixed plant rig (verified: authored 0x5D/0x62 fire at the plant).
> **THE FIELD-CHECK ASK:** plants on every strength — no beep; and one
> listen around H/P voices (the two other cleaned records).
>
> **Load-bearing from 14z-87 (do not re-derive):**
> - `(0x382,A6)` is the char id only at SELECT; in match it is the
>   VOICE-FLAVOR CLASS, engine-reassigned (gotcha [game]).
> - Never correlate a state-dependent value across runs — serialize
>   read+write in ONE run (`tests/lua/read_tap.lua`); write watches run
>   UNWINDOWED first (gotcha [platform]).
> - The maintainer's PERFORMANCE RULE (recorded, STATE "Decisions —
>   14z-87"): <1 frame of impact good; 1-2 needs validation; >=2
>   unacceptable. Distinct from the flicker-skew ratification protocol.
> - test_manifest_merge accrues staleness silently when it sits out
>   batteries — it caught three sessions of drift this close; run it on
>   any manifest change.
>
> ## Still open (the short list)
>
> - The maintainer ear-check on the plant end + general tenant voices
>   (this fix changes ALL tenant engine-voice events to their own rows).
> - The M5 sfx odds (0x112/0x14a/0x173/0x31B family — machinery ready).
> - FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
> - Pyron's medallion whitening — REPRODUCED SAME SESSION on the
>   maintainer's trigger (P2 ring onto DONOVAN's cell; nothing else):
>   scripted rig tests/replays/92_p2_ring_walk.rpl on merged7,
>   snapshot pair sent (ring-on-Aulbath = medallion normal orange;
>   ring-on-DONOVAN = shades of white; f1250 vs f1330 in the rig's
>   timeline). Reads as a select-palette row steal (Donovan's P2-hover
>   palette load vs the row Pyron's medallion uses — row-0x1A family).
>   FIXED (14z-87b, same session — see the shipped batch above): the
>   collision is DONOVAN'S P2-HOVER PORTRAIT drawing with pal row
>   0x1A — PYRON'S MEDALLION ROW (OBJ dump at ring-on-Donovan: 20 new
>   sprites, codes ad90-ad9d at the P2 portrait coords, all pal=1a;
>   at ring-on-Pyron pal=1a has ONE entry). Layout rows: D med 0x16 /
>   H med 0x19 / P med 0x1A; generator-reserved {14,15,17,18,1E}.
>   Frame-boundary palette dumps show row 0x1A content UNCHANGED while
>   rows 0x18/0x1C/0x1F move with the hover — so the visible whitening
>   is mid-frame (the hover load vs the per-frame re-assert machinery,
>   "the WHITE-OUT fix" family in donovan.toml's select_wheel section) —
>   attribute the WRITER of the P2-portrait row assignment (his P2
>   select_records portrait row / the select_pal_variant_id thunk)
>   SHIPPED FIX: Pyron's medallion pal_row moved 0x1A -> 0x1D (one
>   field, wheel_layout cells.11; 0x1D verified absent from every
>   measured clobber list + both OBJ censuses; all machinery — pal
>   block, attr re-palm, reassert — derives from the layout).
>   Snapshot-verified: ring-on-Donovan leaves the medallion orange.
>   Rig: 92_p2_ring_walk.rpl (P2 walk D,D,D,L,D,R,R). The polish check
>   (both cursors over all tenant cells) was DONE BY THE MAINTAINER
>   2026-08-15: all medallions clean for every combination — CLOSED.
> - H-vs-P stuck-direction (~1/30) — not reproduced in any recent test
>   (maintainer, 2026-08-15): keep listed, assume emulator-side or resolved.
> - Round-end flicker (parked; needs the maintainer's recording).
> - Win-screen QUOTE (both tenants); select medallions polish;
>   region_space re-freeze; op-tagging for test_shared_writes.

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged7 | UNREGISTERED (pending S6 freeze) | moves with generator (738 ops) |
| build/don_m5 | **donovan-m6** | 57754602 |
| build/hui40 | **huitzil-m14** | 66feb5e8 |
| build/pyron25 | **pyron-m8** | fab92eb7 |
| build/m5_stock | stock twin (unchanged — both fix halves variant-gated) | 6c93cfa8 |
| build/don_m4, hui39, pyron24 | superseded m4/m12/m6 (tags are the way back; don_m4 = audit_voice_borrow's lottery ground-truth reference) | — |

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2
tests/audit_voice_borrow.sh                    # ~6 min — own-class on build/don_m5
tools/build_merged.sh build/m3b_merged7        # ~15 min (738-op fixture)
tests/audit_trap_parity.sh build/m3b_merged7   # ~5 min — ejection+chirp
tests/test_tenant_loop.sh                      # generator gate (538/738)
tests/test_m3a_reproducible.sh                 # ~6 min (all four refs)
MERGED_OUT=build/m3b_merged7 MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh                 # ~45 min (green at close)
```
