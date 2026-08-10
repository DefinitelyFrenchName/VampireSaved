# NOT A RATIFIED EXPECTATION SET — do not treat these as frozen

Prepared 2026-08-10 (14z-75) for build/pyron17 (5dc6da06) and then STOPPED:
the build does not pass the vanilla-legacy basis, so it must not be frozen.

`tests/expected/registry.tsv` deliberately carries NO dispatch row for this
fingerprint, so `run_suite.sh` will not select this directory. It is kept only
because the measurements below cost several hours and are worth not repeating.

## What was measured

- 42 `.sha1` + 13 `.masked` + 17 `.skip` = 72 of 72 replays accounted for.
- The `--freeze` pass ran clean: no nondeterminism, no run failures.
- 9 of the 13 legacy `.masked` classes (seeded from huitzil-m2 and then
  VERIFIED) pass on pyron17 unchanged — including every `composite` one.
- Final suite tally: **51 PASS / 17 SKIP / 4 FAIL — SUITE RED**.

## Why it is not ratified — FOUR failures (51 PASS / 17 SKIP / 4 FAIL)

| replay | seeded class | measured |
|---|---|---|
| `01_attract_long` | `exact` | live state diverged from vanilla |
| `05_timeout_idle` | `window 889 1675` | 2 runs: `889..1675` **and `4024..12120`**, 0 identical after |
| `07_mash_storm` | `window 889 1675` | 2 runs: `889..1675` and `2241..4320`, 0 identical after |
| `30_demitri_throw` | `window 889 2015` | 2 runs, ends `4720`, 0 identical after |

The first run in each is the ratified select-wheel window and re-converges
cleanly (05: 2348 bit-identical frames, 1676..4023). The SECOND divergence is
the problem: it never re-converges, which under CLAUDE.md §4 means match state
was touched.

## What is already known about it

- **Pre-existing**, not caused by the 14z-75 work: pyron14 measures the
  byte-identical shape (same frames, same run count).
- **Not `port_param32`**: a build with the flag off measures identically.
- **Pyron-specific**: huitzil-m2 on the same replay is ONE run (the select
  window) then 10,446 bit-identical frames.
- **Same matchup on both legs** (P1 0x01 Demitri, P2 0x0E) — it is not the
  cursor landing on a different character.
- RAM diff at the onset frame 4024 (38 live bytes): the P1 fighter block
  (`$FF8401`, `$FF8407`, `$FF841E-21`, `$FF8454`, `$FF846B`, `$FF8494-97`)
  and, notably, `$FFBF00-$FFBF3x` — an **effect-piece pool slot**
  (`$FFB800-$FFBFFF`, 0x80 stride) that is all zeros in vanilla and populated
  in ours. Our build allocates an effect piece vanilla never allocates.
  By frame 4100 it has grown to 1007 live bytes across ~260 ranges.

Prime suspects, untested: the two `[[obj_hook]]` type-dispatch unions
(0x54470 / 0x5E542) and `alloc_wrap`, none of which Huitzil's build carries in
the same shape.
