-- bp_regs.lua — log registers at named PCs while a replay drives the game
-- (14z-85f, the FG damage-path probe). Takes its replay/POKES playback from
-- the tap_writes.lua family and its auto-resuming debugger breakpoints from
-- index_watch.lua. Needs `-debug -debugger none` (run_mame.sh passes extra
-- args through).
--
-- INPUT STAGING IS CANONICAL (GitHub #10, unified 14z-94). This instrument
-- follows tests/lua/replay.lua exactly: parse `held[fr]`, stage for the NEXT
-- frame (`held[frame + 1]`). So a frame number in this log IS a replay.lua
-- frame number and CAN be cross-referenced with a compare_* first divergence,
-- a masked window onset or a checksum log.
--
-- It was one of the ten `+1` deviants until 14z-94. The split is now pinned
-- at ZERO by tests/test_replay_stage_census.sh, which fails any new
-- instrument that copies the old flavour — that is how the drift spread:
-- one variant, then every later file copying the copy.
--
--   env REPLAY     input script (replay.lua format)
--   env POKES      "frame:addr:hexbytes;..." (same as replay.lua)
--   env BPS        "hexpc,hexpc,..." — breakpoints; each hit logs one line
--   env WINDOW     "a,b" — only log inside this frame window (bps always armed)
--   env TRACE_OUT  log path (default bp_regs.txt)
--   env FRAMES     hard stop
--
-- Each hit logs: frame, PC, D0-D3, A0-A6, and the two longs at SP (a jsr'd
-- routine's return address sits at (SP) while nothing else is pushed).
-- HEARTBEAT lines fire once a second regardless of hits, so "armed but
-- idle" and "never armed" cannot look alike (the index_watch lesson).
--
-- The debugger pauses emulated time during a stop, so frame-counted input
-- playback stays aligned; verify the run's liveness from the log's own
-- event lines, never from a clean exit alone.

local out_path   = os.getenv("TRACE_OUT") or "bp_regs.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600
local wa, wb = (os.getenv("WINDOW") or "0,99999999"):match("^(%d+),(%d+)$")
wa, wb = tonumber(wa), tonumber(wb)

local machine  = manager.machine
local cpu      = machine.devices[":maincpu"]
local space    = cpu.spaces["program"]
local debugger = machine.debugger

local f = assert(io.open(out_path, "wb"))

local BPS = {}
for tok in (os.getenv("BPS") or ""):gmatch("[^,%s]+") do
    BPS[tonumber(tok, 16)] = true
end

if not debugger then
    f:write("# FATAL: no debugger. Run MAME with -debug -debugger none.\n")
    f:flush()
    return
end

for pc in pairs(BPS) do
    debugger:command(string.format("bpset 0x%x", pc))
end
debugger:command("go")

-- input playback (same subset as tap_writes.lua)
local frame = 0
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
                                    table.insert(held[fr], fldo)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local pokes = {}
do
    local p = os.getenv("POKES")
    if p then
        for spec in p:gmatch("[^;]+") do
            local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
            if fr then
                pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs }
            end
        end
    end
end

local hits = 0
local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do
                space:write_u8(a, tonumber(b, 16))
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
    if debugger.execution_state ~= "stop" then return end
    local pc = cpu.state["CURPC"].value & 0xFFFFFF
    if not BPS[pc] then return end
    if frame >= wa and frame <= wb then
        hits = hits + 1
        local st = cpu.state
        local r = {}
        for _, n in ipairs({"D0","D1","D2","D3","A0","A1","A2","A3","A4","A6"}) do
            r[#r + 1] = n .. "=" .. string.format("%08x", st[n].value)
        end
        -- A7 first: MAME's m68k "SP" state can resolve to the inactive
        -- stack pointer (measured 14z-85g: constant garbage ret on every
        -- hit); A7 is the active one.
        local spr = st["A7"] or st["SP"]
        local sp = spr.value
        local ok, ret = pcall(function()
            return string.format("ret=%08x,%08x", space:read_u32(sp), space:read_u32(sp + 4))
        end)
        f:write(string.format("frame %d PC %06x %s %s\n",
                frame, pc, table.concat(r, " "), ok and ret or "reterr"))
        f:flush()
    end
    debugger:command("go")
end)

local ticks, last = 0, -1
emu.register_periodic(function()
    ticks = ticks + 1
    if ticks % 600 ~= 0 then return end
    if hits == last then return end
    last = hits
    f:write(string.format("# heartbeat f%d hits=%d\n", frame, hits))
    f:flush()
end)
