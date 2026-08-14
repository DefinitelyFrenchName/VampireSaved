# Per-tenant sfx record tables (the [[sound_table]] rows)

The per-node sfx helper (vs2 `0x5122` → vsavj twin `0x4CE2`) reads a per-
character record array through vsavj's pointer table `0x0BF41A + 4*char_id`.
Each 8-byte record is `[id.w, alt_id.w, params.l]`; the engine skips a record
whose id word is 0 (`tst.w d1; beq`), so unfaithful ids are ZEROED rather than
translated — silence beats the wrong sound. Restoring the zeroed voice banks
needs ported samples: the standing "M5 voice samples" decision (STATE).

Classification method (14z-52, reproduced 14z-85): per-id key-on profiling on
both sets (`tests/lua/qs_sweep.lua` + `tools/qs_analyze.py`, measured maps in
`docs/project/m5/keyons_*.json`) — keep only ids whose vsavj twin keys the
same sample content; zero music-range ids, vsavj-absent ids, and mismatches.
Array lengths are shape-scanned against the don control (44) — the record
shape `[id,id,…]` breaks crisply at the array end; pyron's over-run span
holds keep-id lookalikes, so bounds are exact, never padded.

## donovan — `don_sfx_records` (44 entries, vs2 `0x0CB01A`; ratified 14z-52)

| class | ids |
|---|---|
| KEPT (6, shared) | 0x110 0x111 0x112 0x119 0x152 0x202 |
| zeroed: vsavj MUSIC | 30 ids in 0x700-0x71F, 0x750-0x757 (his vs2 voice bank) |
| zeroed: no vsav sample | 9 ids |
| zeroed: vs2-silent | 2 ids |

## huitzil/phobos — `hui_sfx_records` (24 entries, vs2 `0x0C742A`; 14z-85)

| class | ids | evidence |
|---|---|---|
| KEPT (5) | 0x110 0x111 0x112 | don's ratified shared trio (content-verified 14z-52) |
| | **0x198 0x199** | measured SHARED 14z-85: identical keyon signatures both sets — (0,20480,12548), the same sample family as don's kept 0x119 |
| zeroed: mismatch | 0x12C | vsavj keys a DIFFERENT sample window ((32768,49151) vs vs2's (16384,32767), same length — a different slice) |
| zeroed: silent | 0x3E2 | no keyons either set |
| zeroed: voice block | 0x735-0x74E (16 ids) | his vs2 voice/sfx bank; vsavj keys OTHER content across that gap (3-8 keyons each) — unfaithful. **14z-85g: nodes 10/11 of this block (0x739 trap spawn / 0x73A trap timer-detonation) are the measured cause of the trap-sound parity gap (native fires them per attempt; audit_trap_parity freezes the delta) — NAMED FIRST TARGETS of the M5 pilot: vs2's samples into the WIDE QSound upper 8MB, NEW free vsavj ids, these two record entries remapped. vs2 0x73A keyon (15,108,0,20480) ≈ a single ~20KB sample; 0x739 keyed nothing in the 12-frame sweep (delayed attack — use the 45-frame re-probe when porting)** |

## pyron — `pyr_sfx_records` (23 entries, vs2 `0x0C8B18`; 14z-85)

| class | ids | evidence |
|---|---|---|
| KEPT (4) | 0x110 0x111 0x112 0x202 | all in don's ratified keep set |
| zeroed: mismatch | 0x101, 0x319 | keyon signatures differ across sets (different windows) |
| zeroed: no vsav sample | 0x31B | vs2 keys (32768,61902); vsavj keys nothing |
| zeroed: silent | 0x3D8 0x3DA | no keyons either set |
| zeroed: voice block | 0x720-0x72F (10 ids) | his vs2 voice/sfx bank; **0x729 is the measured merged-build music retrigger** (a vsavj music-gap id) |

## Instrument caveats carried from the ground-truth run (14z-85)

The keyon maps were swept with 12-frame windows (14z-51): the shared trio
0x110-0x112 and 0x152 captured NO keyons on either set (delayed attacks) —
their keep status rests on the 14z-52 content verification, not on these
maps; bank fields jitter ±1 across sets (voice-attribution artifact — the
comparator drops voice+bank and compares (start,end,len) multisets). Music
tracks show only 2-5 keyons in these maps (window truncation), so keyon
COUNT is not a music detector; range + gap membership is.
