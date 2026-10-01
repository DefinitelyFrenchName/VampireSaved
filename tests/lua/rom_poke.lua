-- rom_poke.lua — write PROGRAM-ROM bytes at boot, each VERIFIED through the CPU's program space, then run another
-- autoboot script unchanged (14z-187b; promoted from build/agent187b/t192/rom_poke_trace.lua).
--
-- WHY. A counterfactual on DATA: "does this one record byte decide the difference?" is answered by setting it to
-- the other game's value, in memory, for one run — no rebuild, nothing shipped, both directions. 14z-187b used it
-- to show that Demitri's damage differs between vsavj and vs2 because vs2 lowered his attack records, not because
-- the engines compute differently (docs/game/engine_internals.md, GitHub #161, #191).
--
-- HOW. ROMPOKE="addr:val[,addr:val...]" (hex, LOGICAL 68k addresses — the DATA view's offsets). MAME keeps a 16-bit
-- CPU's ROM region in host word order, so the region offset of a logical byte is the address or its word-swapped
-- twin (addr ^ 1) depending on the host and the region: both are tried, and a write is KEPT only when the program
-- space then reads the new value back at the logical address; otherwise it is undone and `ROMPOKE FAIL` printed.
-- Every write prints `ROMPOKE ok <addr> <old>-><new> (region offset <off>)` — a caller asserts that line. Only DATA
-- reads see the change: CPS-2 opcode fetches come from the decrypted opcode copy, so poking code bytes this way
-- changes nothing the CPU executes.
--
-- Chained script: NEXT_SCRIPT (default tests/lua/field_trace.lua, resolved from this file's directory).
--
-- CONTROLS a caller should run: the unpoked leg reproduces its reference trace, and a poke writing the byte's OWN
-- value reproduces it too (the poke path is inert) — tests/audit_dmg_legacy_sweep.sh section 5 does both.
-- An own-value write always prints `ROMPOKE ok` (the program space read that value before the write): its `ok` line
-- proves nothing, the inert control is the trace comparison (rule-checker run 2026-10-01-519, a reader's note).
local spec = os.getenv("ROMPOKE") or ""
local space = manager.machine.devices[":maincpu"].spaces["program"]
local region = manager.machine.memory.regions[":maincpu"]
for a, v in spec:gmatch("(%x+):(%x+)") do
  local addr, val = tonumber(a, 16), tonumber(v, 16)
  local before, done = space:read_u8(addr), false
  for _, off in ipairs({addr, addr ~ 1}) do
    local old = region:read_u8(off)
    region:write_u8(off, val)
    if space:read_u8(addr) == val then
      print(string.format("ROMPOKE ok %06x %02x->%02x (region offset %06x)", addr, before, val, off)); done = true; break
    end
    region:write_u8(off, old)
  end
  if not done then print(string.format("ROMPOKE FAIL %06x: program space still reads %02x", addr, space:read_u8(addr))) end
end
local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
dofile(os.getenv("NEXT_SCRIPT") or (here .. "field_trace.lua"))
