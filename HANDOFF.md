# HANDOFF — operational map

First read of any session after CLAUDE.md and STATE.md. Keep current in the
same commit as anything it describes.

## What exists (M0 bench, 2026-07-25)

| Piece | Where | Status |
|---|---|---|
| Reference sets | `$ROMDIR` (../ROMS, outside repo) | audited clean; all 6 zips present (vsav, vsavj, vsav2, vhunt2, vhunt2r1, qsound_hle) |
| Frozen checksum manifest | `docs/checksums.txt` | 76 members, per-file SHA-1 |
| ROM audit tool | `tools/audit_roms.py <romdir>` | verify vs manifest; `--freeze` to re-freeze |
| CPS-2 decrypt/encrypt | `tools/cps2_decrypt.py` | bit-identical to MAME oracle (both directions self-checked) |
| Null-patch builder | `tools/build_rom.py <romdir> <out.zip>` | deterministic, bit-identical vsavj |
| Build manifest | `build/manifest/vsavj.toml` | null patch; schema carries provenance |
| MAME headless runner | `tools/run_mame.sh <set> [args]` | MAME 0.288 (brew), fresh sandbox per run |
| Attract determinism | `tests/test_attract_determinism.sh` | PASS 3600 frames |
| Decrypt oracle test | `tests/test_decrypt_oracle.sh` | PASS (python == MAME opcode space) |
| FBNeo | `emu/fbneo` submodule + `tools/run_fbneo.sh` | built (SDL2), headless smoke PASS; harness patch applied (`-hinput/-hout/-hframes/-hdump`), loads CRC-changed patched zips |

FBNeo build: `(cd emu/fbneo && make sdl2 SKIPDEPEND=1 -j8)` — `SKIPDEPEND=1`
is mandatory (docs/GOTCHAS.md). Needs brew `sdl2`(-compat) + `sdl2_image`.

## How to build

```sh
export ROMDIR=/path/to/reference/sets     # holds vsavj.zip, vsav.zip, vhunt2*.zip, qsound_hle.zip
python3 tools/audit_roms.py "$ROMDIR"     # always first; stop on FAIL
python3 tools/build_rom.py "$ROMDIR" build/out/vsavj.zip
```

Decrypted views for analysis (68k logical byte order — see docs/GOTCHAS.md
before touching any byte-order code):

```sh
python3 tools/cps2_decrypt.py "$ROMDIR/vsavj.zip" build/out/vsavj_opcodes.bin --data-out build/out/vsavj_data.bin
```

## How to test

```sh
export ROMDIR=...
tests/test_decrypt_oracle.sh          # decryption == MAME's, both byte orders sane
tests/test_null_build.sh              # null build bit-identical + deterministic
tests/test_attract_determinism.sh     # 60s attract, per-frame RAM checksums, 2 runs
tests/test_fbneo_smoke.sh             # FBNeo headless boot + 15s crash-free soak
tests/test_m2a_stage4_code.sh         # stage-4 gate: veto lock + guarded moveset
                                      # + masked legacy gate (amended §4 basis;
                                      # frozen masked exps in tests/expected/vsavj/masked/)
tests/test_m2a_stage4_oracle.sh [rp]  # vsav2-as-oracle: anchors/neutral-exact/
                                      # HP-trajectory/comparative bound (17+18 replays)
tests/test_m2a_stage4_xemu.sh  [rp]   # dual-emulator: MAME+FBNeo field agreement
tests/test_m2a_flavor_selector.sh [rp]# Start-hold flavor latch (stage 5)
```

All tests are self-contained, take state only via env/args, print PASS/FAIL,
and exit nonzero on failure. Every dev-time in-emulator probe must land here
before session end (persistent suite doctrine, CLAUDE.md §4).

## Build registry

| Build | SHA-1 (zip) | Notes |
|---|---|---|
| null vsavj | `12fbb0e1a137a1420824856d3efb0af8fff57be6` | == reference members; zip repacked deterministically |
| donovan-m2 stage 5 (freeze candidate) | fingerprint `eda50a18d5ff8c666a8f5db193dff789aec16216` | `tools/build_donovan.sh 5 build/donovan5`; all gates green (4 guarded soaks incl. ES-DP spam, round-2, input-chaos / 13-replay masked legacy / oracle / xemu / flavor); supersedes 372b0641 (move-sfx reclassification — music-on-specials fixed; M5 list = 22 sfx ids); registry row lands at the maintainer freeze decision (STATE.md) |

## M1 additions (2026-07-25, session 2)

| Piece | Where |
|---|---|
| Replay format + MAME runner | `.rpl` in `tests/replays/`, `tests/lua/replay.lua`, `tools/run_replay_mame.sh` |
| FBNeo harness (patched frontend) | `emu/fbneo-patches/0001-…`, `tools/setup_fbneo.sh`, `tools/run_replay_fbneo.sh` |
| Legacy suite (10 replays, frozen) | `tests/run_suite.sh`, `tests/expected/vsavj/` |
| Watchpoint write-tracer | `tests/lua/trace_writes.lua` (needs `-debug -debugger none`) |
| Pick probe (slot mapping) | `tools/pick_probe.sh` |
| Structural diff | `tools/diff_sets.py` (`--mask-pointers`) |
| Character tables atlas | `docs/atlas/character_tables.md` (3-set anchor, slot maps, D/H/P located, pipelines) |
| RAM atlas | `docs/atlas/ram.md` |
| M1 acceptance review | `docs/M1_acceptance.md` (both clauses met; R2 quantified) |
| Write/read tracer | `tests/lua/trace_writes.lua` (WATCH=addr,len[,r|w|rw]) |
| Program patcher | `tools/patch_prg.py` (JSON ops, word-value space) + `tools/pack_build.sh` |
| M2 feasibility | `docs/M2_feasibility.md` (3 domains; remaining work list) |
| Patch-tooling test | `tests/test_patch_prg.sh` (null bit-identical, code re-encrypts) |
| M2 repoint proof | `tests/test_m2_repoint.sh` (mechanism + superset invariant) |

Run a patched build: `MAME_ROMPATH="<packed_dir>;$ROMDIR" tools/run_mame.sh vsavj ...`


## M2a port pipeline (2026-07-25, sessions 4-6) — how to build/debug Donovan

```sh
export ROMDIR=/path/to/reference/sets
# full chain: audit -> extract (vhunt2 oracle) -> generate -> patch -> pack
GEN_FLAGS="--allow-plausible --tripwire-open" tools/build_donovan.sh 4 build/donovan
# run it (guarded: exception breakpoints + register dump at fault)
MAME_ROMPATH="$PWD/build/donovan/rompath;$ROMDIR" \
  tools/run_replay_guarded.sh vsavj tests/replays/12_donovan_vs_cpu.rpl out.log box
```

Stages: 1 null-relocation scaffolding, 2 passive data, 3 anim + sprite
sub-tables, 4 code + support zones + engine hooks, 5 select plumbing.
Stage gates: `tests/test_m2a_stage{1,2,3}*.sh` (all PASS).

| Piece | Where | Role |
|---|---|---|
| Extractor | `tools/extract_char.py` | vsav2→vsavj extraction, **vhunt2 as correctness oracle**: every cross-sibling diff byte must classify as a pointer field under a measured shift. Handles: transitive closure, auto-discovered region shifts, extra roots (`addr:len[:tTWIN[:d]|:s]`), segmented gap-tolerant diff, self-pointer regions, PC-relative word tables, **bare-long sibling veto in source-only zones** (operand pairs masquerading as pointers — GOTCHAS) |
| Ref scanner | `tools/scan_code_refs.py` | 68k operand triage (abs.l after known opcodes, bare longs, char-id immediates) |
| R1 resolver | `tools/reconcile_batch.py` | batch vsav2→vsavj engine mapping: pattern ladder, stub-deref, call-site anchoring, code/data byte match, farm-param matching |
| Single lookup | `tools/find_equiv.py` | one wildcarded pattern search (validated at 1.00 on the known loader) |
| Generator | `tools/gen_donovan_patch.py` | staged op-list: hole allocator + layout groups + near_map, pointer/pcrel rewriting, bank repoints (0x0F **and** 0x1F), engine hooks, alloc wrappers, tripwires |
| Driver | `tools/build_donovan.sh` | the whole chain; `EXTRA_ROOTS` / `GEN_FLAGS` override |
| Manifests | `build/manifest/{bank_map,donovan,reconciliation}.toml` | table map / port config (holes, groups, hooks, patches) / R1 map |

**Debug env** (all on `run_replay_guarded.sh`): `GUARD_DEBUG=0` cheap mode
(canonical checksums), `GUARD_TRACE=a-b` instruction trace,
`GUARD_PC_LOG=a-b` per-frame PC, `GUARD_BREAK=hexaddr` break+report,
`GUARD_MATCH=a-b` in-match flag watch, `GUARD_PROBE=hexaddr`
[+`GUARD_PROBE_COND=expr`] conditional LOGGING breakpoint (PROBE lines:
regs + (SP); run continues — how the session-7 corruption was caught).
Faults log `CRASH` + `REGS` + `STACK` lines and dump work RAM.
`MASK_RANGES="043c-043d,7f00-8000"` on replay.lua = live-state comparison
(dead-stack + QSound-latch windows excluded; docs/GOTCHAS.md); unset =
canonical whole-RAM checksums, bit-identical to frozen expectations.

**Ground truth for behavior**: native Donovan on vsav2 — pick with cursor
**R×2** from the default select position.

## M2a C0 additions (2026-07-25, session 4) — verification harness upgrade

| Piece | Where |
|---|---|
| Crash guard | `tests/lua/replay_guard.lua` + `tools/run_replay_guarded.sh` (`GUARD_DEBUG=0` for cheap/checksum-canonical mode; `-debug` mode for breakpoint crash capture — its checksums are NOT comparable to non-debug runs, docs/GOTCHAS.md) |
| Crash-guard ground truth | `tests/test_crash_guard.sh` (clean negative + vec4/vec3 positive controls) |
| Dual-emulator field comparator | `tools/compare_fields.py` + `tests/fields_m2a.tsv` (debounced anchors; stable/settled/phase field classes; `--exact` for same-emulator) |
| Comparator ground truth | `tests/test_compare_fields_selfcheck.sh` (§4 protocol exercised: MAME/FBNeo agree on `16_xemu_2p`, 1-frame skew) |
| Dual-emulator-safe replay template | `tests/replays/16_xemu_2p.rpl` (authoring rules in docs/GOTCHAS.md — vs-CPU replays have emulator-divergent content!) |
| Slot-0x0F pick replay | `tests/replays/11_pick_donovan.rpl` (Jedah on vanilla; per-build expectations via fingerprint dispatch) |
| Auto-detecting suite runner | `tests/run_suite.sh` — `MAME_ROMPATH` fronting, fingerprint → `tests/expected/<expset>/`, `.diverge` expectation kind (exact-frame divergence vs frozen full logs under `expected/<set>/logs/`) |
| Fingerprint / registry | `tools/build_fingerprint.py`, `tests/expected/registry.tsv` (rows only at freeze time, STATE.md decision) |
| Diverge checker | `tools/check_diverge.py` |
| Flicker comparator (hooked-build legacy gate v2) | `tools/compare_flicker.py` + ground truth `tests/test_compare_flicker.sh`; frozen masked vanilla logs `tests/expected/vsavj/masked/` |
| Dispatch ground truth | `tests/test_suite_dispatch.sh` (no emulator; fast) |
| FBNeo runner extensions | `tools/run_replay_fbneo.sh`: `FBNEO_DUMPS` (-hdump), `FBNEO_ROMPATH` zip overlay — **verified to load CRC-changed patched zips** |

## Key findings so far

- vsavj key/range: master `0xfa8f4e33a4b881b9`, encrypted range
  `PRG:0x000000-0x100000` (first 1MB only; the other 3MB of program ROM is
  never opcode-encrypted). Watchdog instruction: `cmpi.l #$726A4BAF, D0`.
- ROM file byte order vs 68k logical order trap: docs/GOTCHAS.md first entry.
- MAME 0.288 `-verifyroms` passes all four sets with `-rompath` pointed at
  `$ROMDIR`; `qsound_hle.zip` and the copied `vhunt2.key` resolved the audit.
