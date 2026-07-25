# patch_index — one-page registry of every patch

Updated in the same commit as any patch change. Columns: status
(planned/active/deprecated), depends-on, exclusive-with, notes.

| Patch | Status | Depends on | Exclusive with | Notes |
|---|---|---|---|---|
| (null) | active | — | — | `build/manifest/vsavj.toml`: straight member copies, bit-identical vsavj. The baseline every other patch chains onto. |
| donovan-m2 | in progress | patch_prg tooling | replaces Jedah slot 0x0F | M2 proof-of-life: Donovan into vsavj. Program-ROM data via `tools/patch_prg.py` (JSON op list). Not yet authored. |

## Tooling: `tools/patch_prg.py`

Applies a JSON op-list to a CPS-2 program set in 68k word-value space
(addresses = analysis/logical byte addresses). `data`/`poke` write raw;
`code` re-encrypts with the set's key so opcode fetches decrypt correctly
(verified against MAME, `tests/test_patch_prg.sh`). Null patch is
bit-identical (superset-invariant guard). `tools/pack_build.sh` packs the
output into a runnable rompath dir (use `-rompath "<dir>;$ROMDIR"`).

No behavioral patches exist yet. First real entries expected at M2
(Donovan-replaces-slot proof of life).
