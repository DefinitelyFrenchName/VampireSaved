# NEXT SESSION — orientation (written at the close of 14z-87, 2026-08-15)

> ## START HERE — THE VOICE-BORROW FIX AWAITS THE EAR-CHECK
>
> 14z-87 root-caused the sword-plant "ding" (the engine VOICE-CLASS
> BORROW at `PRG:0x0AEF6` hands a tenant a random vanilla voice class —
> engine_internals "per-node sfx dispatch, third pass") and, on the
> maintainer's same-day b+c ruling, SHIPPED the fix: **donovan-m5
> (`build/don_m5`, 3c599fb6) / huitzil-m13 (`build/hui40`, 2629561c) /
> pyron-m7 (`build/pyron25`, 94ce9a48), merged `build/m3b_merged7`**
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
>   MEASURED (14z-87b close, maintainer-confirmed captures): the
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
>   before moving it. FIX SHAPE: data-only — move Donovan's P2-hover
>   portrait row off 0x1A to a free row. Rig: 92_p2_ring_walk.rpl (P2
>   walk D,D,D,L,D,R,R; ring on Pyron @f1250, on Donovan @f1330);
>   OBJ pair + palette dumps + snapshot pair all in the session log.
> - H-vs-P stuck-direction (~1/30, possibly emulator-side).
> - Round-end flicker (parked; needs the maintainer's recording).
> - Win-screen QUOTE (both tenants); select medallions polish;
>   region_space re-freeze; op-tagging for test_shared_writes.

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged7 | UNREGISTERED (pending S6 freeze) | moves with generator (738 ops) |
| build/don_m5 | **donovan-m5** | 3c599fb6 |
| build/hui40 | **huitzil-m13** | 2629561c |
| build/pyron25 | **pyron-m7** | 94ce9a48 |
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
