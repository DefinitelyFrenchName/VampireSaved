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
--   env REPLAY     input script (replay.lua format)
--   env TRACE_OUT  log path (default obj_record_bank.txt)
--   env FRAMES     stop after this many frames (default 4200)
--   env REC_LO/REC_HI  A0 window (hex, default bf6a0/100000)

local out_path = os.getenv("TRACE_OUT") or "obj_record_bank.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 4200
local rec_lo = os.getenv("REC_LO") or "bf6a0"
local rec_hi = os.getenv("REC_HI") or "100000"

local machine = manager.machine
local debugger = machine.debugger
assert(debugger, "run mame with -debug")
local cpu = machine.devices[":maincpu"]
local prog = cpu.spaces["program"]

local f = assert(io.open(out_path, "wb"))
local frame = 0
local seen = {}

-- input playback (same subset as trace_writes.lua)
local held = {}
local replay_path = os.getenv("REPLAY")
local FIELDS = nil
if replay_path then
    local ioport = machine.ioport
    local function fld(port, name) return ioport.ports[port].fields[name] end
    FIELDS = {
        p1 = { U = fld(":IN0", "P1 Up"), D = fld(":IN0", "P1 Down"),
               L = fld(":IN0", "P1 Left"), R = fld(":IN0", "P1 Right"),
               ["1"] = fld(":IN0", "P1 Button 1"), ["2"] = fld(":IN0", "P1 Button 2"),
               ["3"] = fld(":IN0", "P1 Button 3"), ["4"] = fld(":IN1", "P1 Button 4"),
               ["5"] = fld(":IN1", "P1 Button 5"), ["6"] = fld(":IN1", "P1 Button 6") },
        p2 = { U = fld(":IN0", "P2 Up"), D = fld(":IN0", "P2 Down"),
               L = fld(":IN0", "P2 Left"), R = fld(":IN0", "P2 Right"),
               ["1"] = fld(":IN0", "P2 Button 1"), ["2"] = fld(":IN0", "P2 Button 2"),
               ["3"] = fld(":IN0", "P2 Button 3"), ["4"] = fld(":IN1", "P2 Button 4"),
               ["5"] = fld(":IN1", "P2 Button 5"), ["6"] = fld(":IN2", "P2 Button 6") },
        sys = { S1 = fld(":IN2", "1 Player Start"), S2 = fld(":IN2", "2 Players Start"),
                C1 = fld(":IN2", "Coin 1"), C2 = fld(":IN2", "Coin 2"),
                SV = fld(":IN2", "Service 1"), TS = fld(":IN2", "Service Mode") },
    }
    for line in io.lines(replay_path) do
        local body = line:gsub("#.*", "")
        local range, rest = body:match("^%s*(%S+)%s+(.-)%s*$")
        if range then
            local a, b = range:match("^(%d+)%-(%d+)$")
            if not a then a = range:match("^(%d+)$"); b = a end
            if a then
                for spec in rest:gmatch("%S+") do
                    local who, toks = spec:match("^(%a+%d?)=(%S+)$")
                    if who and FIELDS[who] then
                        local step = (who == "sys") and 2 or 1
                        for i = 1, #toks, step do
                            local fldo = FIELDS[who][toks:sub(i, i + step - 1)]
                            if fldo then
                                for fr = tonumber(a), tonumber(b) do
                                    held[fr] = held[fr] or {}
                                    held[fr][#held[fr] + 1] = fldo
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

debugger:command("focus 0")
local cond = string.format("(a0 >= %s) && (a0 < %s)", rec_lo, rec_hi)
debugger:command(string.format("bpset 1b234,%s", cond))  -- fmt 2 handler
debugger:command(string.format("bpset 1afc6,%s", cond))  -- fmt 0 handler

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
    if FIELDS then
        local want = {}
        for _, fldo in ipairs(held[frame + 1] or {}) do want[fldo] = true end
        for _, group in pairs(FIELDS) do
            for _, fldo in pairs(group) do
                if want[fldo] and not pressed[fldo] then fldo:set_value(1); pressed[fldo] = true
                elseif not want[fldo] and pressed[fldo] then fldo:clear_value(); pressed[fldo] = nil end
            end
        end
    end
    if frame >= max_frames then
        f:write(string.format("END %d\n", frame))
        f:close()
        manager.machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger.execution_state == "stop" then
        local st = cpu.state
        local a0 = st["A0"].value & 0xffffff
        local a6 = st["A6"].value & 0xffffff
        local bank = prog:read_u16(a6 + 0x18)
        local key = string.format("%x_%x", a0, bank)
        if not seen[key] then
            seen[key] = true
            f:write(string.format("REC %06x BANK %04x OBJ %06x FMT_PC %06x FRAME %d\n",
                a0, bank, a6, st["CURPC"].value, frame))
            f:flush()
        end
        debugger.execution_state = "run"
    end
end)
