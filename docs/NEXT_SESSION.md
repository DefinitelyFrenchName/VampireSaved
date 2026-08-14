# NEXT SESSION — orientation (written at the close of 14z-86, 2026-08-14)

> ## START HERE — THE VOICE-BLOCK BATCH (the machinery is COMPLETE)
>
> 14z-86 opened the M5 arc and shipped its pilot end-to-end: the trap
> mine-EJECTION sound is restored (**huitzil-m11** = build/hui38
> `6eed421b`; merged **build/m3b_merged5**) with NO sample port — the
> whole Z80 sound driver is decoded (engine_internals "The QSound Z80
> driver"; the 14z-85d KABUKI/file-mapping detail is RETRACTED at its
> root, banner there). **EAR-CHECK PENDING**: the ejection "pop" at
> mine throw, on build/m3b_merged5 (or the hui38 solo) — first thing
> to ask the maintainer.
>
> **THE MACHINERY NOW IN PLACE (use it, don't re-derive):**
> - WIDE v1.1: Z80 driver members are content members `vsw.z01/z02`
>   (sentinel CRCs; both emulators rebuilt + superset-gated).
> - `tools/build_qs_songs.py` + `build/manifest/qs_songs.toml`:
>   declarative song rows, injected by both build drivers uniformly.
> - `tools/audit_qs_id_table.py`: the census (240 free vsavj rows);
>   gates `test_qs_id_table.sh` / `test_qs_songs.sh`.
> - Facts that make the batch cheap: sample records are 8-bit-bank
>   (WIDE banks 0x80+ expressible); the id space wraps mod 0x6D8;
>   b0==0 rows are free; the interpreters are byte-identical across
>   the games (verbatim stream copies are licensed).
>
> **THE BATCH PLAN (per voice id, in decreasing cheapness):**
> 1. Resolve the vs2 song statically (id table → song → cmd-08 note
>    entries → sample records) — no sweep needed for discovery.
> 2. Content-search vsav's image for the sample bytes (the chirp AND
>    the ejection were both already present). If FOUND: pure song-row
>    work — note-table entry may also exist (check entry-resolution
>    equivalence like 0x28); if the note entry differs, the song needs
>    an authored note-table (cmd 1F selects from the $3B04 ptr array —
>    extending THAT array is new ground, measure its bounds first).
> 3. If ABSENT (the known vs2-only list: 0x71d, 0x73e, 0x753-0x756 +
>    re-verify per id): pack the sample window into the QSound
>    extension (banks 0x80+) — build_wide_romset needs the content
>    hook (still unwritten); authored sample records + note entries
>    then reference the extension banks. NOTE qs_analyze masks banks
>    &0x7F — widen before analyzing extension keyons. MiSTer: banks
>    0x80+ need the jtcores 4-line width fix (cps2_wide.md, verified);
>    banks <0x80 work as-is.
> 4. The 45-frame keyon re-sweep for verification A/Bs (qs_sweep's
>    12-frame default is attack-window-blind; qs_analyze's window is
>    hard-coded — parameterize it).
> 5. Scope per tenant: donovan 0x700-0x71F/0x750-0x757, phobos
>    0x735-0x74E, pyron 0x720-0x72F (+ absent-sample odds like 0x31B,
>    and the pyron win-laugh distortion, an M5-family item). Un-zero
>    ids in the sfx-records keep lists as they land; audible-content
>    curation goes to docs/project/tables/ for review (Rule 5).
>
> **Carry-forward notes:**
> - The merged5 legacy audit is GREEN (AUDIT-EXIT 0 at 14z-86 close,
>   `build/audit_merged5_legacy.log`) — NO gap carries to S6. (Its
>   first run died instrumentally on pre-v1.1 leg-b refs; fixed by
>   the stock-member upgrade below, then rerun clean.)
> - COMPAT: pre-v1.1 builds (hui37 and older, merged4 and older) do
>   NOT boot on the v1.1 binaries (no vsw.z01/z02) — inject stock
>   members (STATE 14z-86 has the recipe) or rebuild. ALREADY UPGRADED
>   IN PLACE (stock members, fingerprints verified unchanged):
>   m5_wide, hui30, pyron21, hui34, hui36, hui37 — the audit leg-b
>   refs and the parity/shock ground-truth refs boot again.
> - The flaky Sasquatch-intro crash rig (STATE 14z-85f) stays armed.
>
> ## Corrections that must outlive 14z-86 (load-bearing)
>
> - The Z80 is NOT KABUKI-encrypted; the driver's 24-bit addresses are
>   FLAT member-concat file offsets (region≠file — ROM_CONTINUE).
>   Everything derived with the old mapping is suspect; the corrected
>   decode is in engine_internals "The QSound Z80 driver".
> - The real sample-record table is at 0x45FA (reader 0x1350); the
>   "0x5219 table" was a misaligned phase. The command table @0x1126
>   is a doubling-mask table, not a dispatch table.
> - A song block below flat 0x10000 is UNREACHABLE (entry b0==0 is
>   the driver's free/no-op marker) — build_qs_songs refuses it.

## Current builds (registry)

| build | set | fingerprint |
|---|---|---|
| build/m3b_merged5 | UNREGISTERED (pending ear-check + S6 freeze) | moves with generator (678 ops) |
| build/m3b_merged4 | superseded (pre-ejection merged; needs member injection to boot on v1.1) | superseded |
| build/hui38 | **huitzil-m11** | 6eed421b |
| build/hui37 | superseded m10 (pre-v1.1: does not boot without member injection) | 9a948a11 |
| build/m5_wide | donovan-m3a | 4b7d0dc7 |
| build/pyron23 | **pyron-m5** | 65e9a40e |
| build/hui34/hui36 | superseded m8/m9 (parity/shock ground-truth refs; pre-v1.1) | c48cd722 / 3d9ffc89 |
| build/hui32, pyron21 | superseded (extract dirs = tenant_loop/build_merged inputs) | db4bcd11 / 6c7f7322 |

## Still open (the short list)

- **EAR-CHECK the restored trap ejection** (huitzil-m11 / m3b_merged5)
  — the trap is otherwise fully CLOSED (chirp 14z-85g, shock
  14z-85g(2), ejection 14z-86; all field-confirmed except the last).
- THE M5 VOICE-BLOCK BATCH (this session's plan above).
- FLAKY CRASH RESET (Sasquatch intro; rig designed, STATE 14z-85f).
- Pyron's medallion whitening on 2P hover (row-0x1A family).
- H-vs-P stuck-direction (~1/30, possibly emulator-side).
- Round-end flicker (parked; needs the maintainer's recording).
- Win-screen QUOTE (both tenants); pyron win-laugh distortion
  (M5-family); select medallions polish; region_space re-freeze;
  op-tagging for test_shared_writes; 14z-83 leg-b staleness notes.

## Build / validate

```sh
export ROMDIR=/path/to/reference/sets
export MAME_BIN=~/.cache/vampire-saved/mame/cps2   # run_suite needs it
tools/build_merged.sh build/m3b_merged5    # ~15 min (678-op fixture)
tests/audit_trap_parity.sh build/m3b_merged5 # ~5 min — ejection+chirp gate
tests/audit_trap_shock.sh build/m3b_merged5  # ~4 min — the shock gate
tests/audit_fg_parity.sh build/m3b_merged5 # ~4 min — the FG parity gate
tests/test_qs_id_table.sh                  # ~5 s — the Z80 census gate
tests/test_qs_songs.sh                     # ~5 s — the song machinery gate
tests/test_tenant_loop.sh                  # generator gate (491/678)
tests/test_m3a_reproducible.sh             # ~6 min (all four refs)
MERGED_OUT=build/m3b_merged5 MERGED_PREBUILT=1 \
  tests/audit_merged_legacy.sh             # ~45 min (ran at 14z-86 close;
                                           # check build/audit_merged5_legacy.log)
```
