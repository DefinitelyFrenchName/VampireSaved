# Experiment: Start-hold flavor selection (vsav2 Donovan)

Claim under test (SPEC §2): holding Start while selecting Donovan/Huitzil/
Pyron in VS2/VH2 selects the other game's flavor of that character.

Method (rerunnable):
```sh
export ROMDIR=...
# 1. plain pick vs Start-held pick, full-RAM dump after attack chains:
DUMPS="4100:ff0000-ffffff" REPLAY=tests/experiments/start_hold_flavor/don_fight.rpl \
  CHECKSUM_OUT=/tmp/a.log MAME_SANDBOX=/tmp/abox \
  tools/run_mame.sh vsav2 -autoboot_script tests/lua/replay.lua
DUMPS="4100:ff0000-ffffff" REPLAY=tests/experiments/start_hold_flavor/don_fight_hold.rpl \
  CHECKSUM_OUT=/tmp/b.log MAME_SANDBOX=/tmp/bbox \
  tools/run_mame.sh vsav2 -autoboot_script tests/lua/replay.lua
cmp /tmp/abox/../a_dump /tmp/bbox/../b_dump   # (dump files land next to CHECKSUM_OUT)
# 2. read-watch the latch byte during play:
REPLAY=...don_fight.rpl WATCH="ff87c2,1,r" TRACE_OUT=/tmp/t.txt FRAMES=4200 \
  tools/run_mame.sh vsav2 -debug -debugger none -autoboot_script tests/lua/trace_writes.lua
```

Result (2026-07-25, vsav2 Japan 970913): exactly ONE byte differs after
identical attack-chain sequences — RAM:$FF87C2 (the latch itself, default
01, cleared by holding Start through match load). The byte is never read
during play. No behavioral difference. See docs/game/atlas/character_tables.md
"Start-hold flavor: NOT REPRODUCED".

## Session 2026-07-27 follow-up: RESOLVED

Community confirmed the feature (Donovan + Huitzil ONLY, hold Start then
press punch/kick). The session-3 non-reproduction was an observable gap:
the fight section had no command motions. New replays
`don_specials.rpl` / `don_specials_hold.rpl` run a full motion battery
(QCF/DP/QCB × P/K strengths, HCB, charge, double-motion supers, P+K
pairs). Results (vsav2):

- Masked comparison (`MASK_RANGES=87c2-87c3` on replay.lua) of the ± hold
  runs: bit-identical (after transient input-release settling ≤ ~2830)
  until frame 4296 = the QCB+LK completion frame, then permanently
  diverged — the flavor fork is the QCB+K special.
- Read-watch (`WATCH="ff87c2,1,r"`): consumers = vsav2 PRG:0x05A654
  (command handler, at move start) and PRG:0x065FE6 (the move's
  projectile code). Both are inside regions the M2a port relocates.
- On the ported vsavj stage-4 build the latch byte is 00 (vsavj never
  writes it) → ported Donovan takes the VH2 branch by accident. See
  STATE.md decision + docs/game/atlas/character_tables.md.
