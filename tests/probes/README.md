# tests/probes — replays that must NOT join the frozen suite

`tests/run_suite.sh` iterates `tests/replays/*.rpl` and demands a frozen
expectation for every file it finds. That is the right rule for oracle
replays, but it means a short diagnostic script cannot live there without
forcing a new expectation row into every expectation set (vsavj,
donovan-m2, donovan-m2b, donovan-m2c, ...).

Probes live here instead. They are driven by their own gate, never by
run_suite.sh, and they carry no frozen expectation — a probe's verdict is
a property of the run (determinism, timing, liveness), not a comparison
against a stored value.

- `boot_probe.rpl` — 400 frames of pure boot, no input. Deliberately short
  (~2s per run) so a determinism gate can afford dozens of repetitions.
  Covers the boot window where the B5 divergences were observed.
