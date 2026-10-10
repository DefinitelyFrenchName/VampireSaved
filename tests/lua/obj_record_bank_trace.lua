-- obj_record_bank_trace.lua — empirical (record, bank) attribution for the
-- OBJ emitter (session 14o; the f8eda2ca post-mortem mandates runtime
-- evidence, not content heuristics, for x2b7ef4 bank classification).
--
-- Breakpoints at the format handlers (fmt2 0x1B234, fmt0 0x1AFC6; static
-- decode session 14, docs/game/engine_internals.md): A0 = record pointer,
-- A6 = object; the OBJ bank rides object field +0x18 (Y-word bits 13-14).
-- Conditioned on A0 inside the ported windows so only Donovan-ecosystem
-- records stop the CPU. Each unique (record, bank) pair is logged once:
--   REC <a0 hex> BANK <word hex> OBJ <a6 hex> FRAME <n>
--
--   env TRACE_OUT  log path (default obj_record_bank.txt)
--   env REC_LO/REC_HI  A0 window (hex, default bf6a0/100000)
--   env REPLAY, FRAMES (default 4200), INSTR_REFERENCE, INSTR_CLOCK, ANCHOR, MASK_RANGES, ALIGN_OUT:
--       tests/lua/emu_clock.lua (the frame is an EMULATED frame since 14z-197, GitHub #228)

local out_path = os.getenv("TRACE_OUT") or "obj_record_bank.txt"
local rec_lo = os.getenv("REC_LO") or "bf6a0"
local rec_hi = os.getenv("REC_HI") or "100000"

-- THE FRAME CLOCK, THE REPLAY AND THE ALIGNMENT READINGS (14z-197, GitHub #228 step 4): emulated
-- frames, not frame_done calls — tests/lua/emu_clock.lua (REPLAY, FRAMES, INSTR_REFERENCE,
-- INSTR_CLOCK, ANCHOR, MASK_RANGES, ALIGN_OUT). Until 14z-197 this script counted frame_done calls,
-- so every stop's UI frames moved its input early ([MFI-5]).
local C = dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "emu_clock.lua"){
    name = "obj_record_bank_trace", frames = 4200 }

local machine = manager.machine
local debugger = machine.debugger
assert(debugger or C.reference, "run mame with -debug (or INSTR_REFERENCE=1 for the reference leg)")
local cpu = machine.devices[":maincpu"]
local prog = cpu.spaces["program"]

local f = assert(io.open(out_path, "wb"))
local seen = {}

if not C.reference then
    debugger:command("focus 0")
    local cond = string.format("(a0 >= %s) && (a0 < %s)", rec_lo, rec_hi)
    debugger:command(string.format("bpset 1b234,%s", cond))  -- fmt 2 handler
    debugger:command(string.format("bpset 1afc6,%s", cond))  -- fmt 0 handler
end

C.run{ on_end = function(frame)
    f:write(string.format("END %d\n", frame))
    f:close()
end }

emu.register_periodic(function()
    if debugger and debugger.execution_state == "stop" then
        local st = cpu.state
        local a0 = st["A0"].value & 0xffffff
        local a6 = st["A6"].value & 0xffffff
        local bank = prog:read_u16(a6 + 0x18)
        local key = string.format("%x_%x", a0, bank)
        if not seen[key] then
            seen[key] = true
            f:write(string.format("REC %06x BANK %04x OBJ %06x FMT_PC %06x FRAME %d\n",
                a0, bank, a6, st["CURPC"].value, C.frame()))
            f:flush()
        end
        debugger.execution_state = "run"
    end
end)
