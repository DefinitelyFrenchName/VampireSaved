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
during play. No behavioral difference. See docs/atlas/character_tables.md
"Start-hold flavor: NOT REPRODUCED".
