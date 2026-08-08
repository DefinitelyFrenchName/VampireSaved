-- trace_writes.lua — log every write hitting a watched RAM range: PC, value,
-- and register state. The standard tool for "who initializes this field?"
-- (used with tools/run_mame.sh; requires -debug on the command line).
--
--   env REPLAY       optional input script (same format as replay.lua)
--   env WATCH        "ff8480,4" (start,len) or "ff8480,4,r" / "...,rw"
--                    (watch mode; default w = writes); mode "b" sets an
--                    EXECUTION BREAKPOINT at the address instead (len
--                    ignored) — log registers at a PC (session 14c)
--   env TRACE_OUT    log path (default trace_writes.txt)
--   env FRAMES       stop after this many frames (default 3600)
--
-- Each hit logs: frame, PC, watched address, and D0/D1/A0-A6 — enough to
-- identify the source table pointer for table-copy loops without a full
-- instruction trace.

local watch = assert(os.getenv("WATCH"), "set WATCH=start,len")
local out_path = os.getenv("TRACE_OUT") or "trace_writes.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local machine = manager.machine
local debugger = machine.debugger
assert(debugger, "run mame with -debug")
local cpu = machine.devices[":maincpu"]

local f = assert(io.open(out_path, "wb"))
local frame = 0
local hits = 0

-- input playback (subset of replay.lua: apply held tokens per frame)
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

local start_addr, len, mode = watch:match("^(%x+),(%d+),?(%a*)$")
assert(start_addr, "WATCH format: hexaddr,len[,r|w|rw]")
if mode == "" then mode = "w" end

-- register the watchpoint (or breakpoint, mode "b") on the maincpu
debugger:command(string.format("focus 0"))
if mode == "b" then
    debugger:command(string.format("bpset %s", start_addr))
else
    debugger:command(string.format("wpset %s,%s,%s", start_addr, len, mode))
end

-- POKES (14z-68): same grammar/application point as replay.lua, so the
-- forced-pick rigs can be traced.
local poke_space = cpu.spaces["program"]
local pokes = {}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
end

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do
                poke_space:write_u8(a, tonumber(b, 16))
                a = a + 1
            end
        end
    end
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
        f:write(string.format("END %d hits %d\n", frame, hits))
        f:close()
        manager.machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger.execution_state == "stop" then
        local st = cpu.state
        f:write(string.format(
            "frame %d PC %06x D0 %08x D1 %08x A0 %08x A1 %08x A2 %08x A3 %08x A4 %08x A6 %08x\n",
            frame, st["CURPC"].value, st["D0"].value, st["D1"].value,
            st["A0"].value, st["A1"].value, st["A2"].value, st["A3"].value,
            st["A4"].value, st["A6"].value))
        hits = hits + 1
        debugger.execution_state = "run"
    end
end)
