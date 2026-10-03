-- pc_count.lua — HOW OFTEN, and in WHICH FRAMES, does the CPU execute each of a
-- set of instruction addresses? Breakpoint on each site; every stop counts one
-- hit against the current frame and resumes. Output is per-frame and compact:
-- only frames with a hit are written, so a site that fires 50 times a frame
-- costs one line per frame, not 50.
--
-- WHY (14z-189, GitHub #128): a hook's LEGACY cost is (executions per frame) x
-- (cycles the hook adds), and the performance rule binds the WORST frame, not
-- the average — so the count is kept per frame, never only summed.
--
-- WHAT IT CANNOT SEE: an address the CPU reaches by a path that does not stop
-- at the breakpoint (none on a 68000 — every executed instruction's first word
-- is fetched at its PC), and what the frame boundary is relative to VBL (it is
-- MAME's frame_done, the same boundary replay.lua and every gate here uses).
--
--   env SITES   "4dda,895c,..." hex addresses (no 0x)
--   env OUT     output path (default pc_count.txt)
--   env REPLAY  input script (replay.lua grammar subset, as dispatch_census.lua)
--   env FRAMES  stop after this many frames (default 3600)
--   env PC_CLOCK frame_done = the old drifting clock (a control only; see below)
--
-- Output:
--   F <frame> <addr>:<hits> ...        one line per frame with any hit
--   SITE <addr> hits <total> frames <frames-with-hits> max <max-in-one-frame>
--   UIFRAMES <frame_done calls with no emulated frame — the stops' UI frames, skipped>
--   PCEND <frames>
-- Needs -debug -debugger none.
local machine = manager.machine
local debugger = machine.debugger
assert(debugger, "run mame with -debug")
local cpu = machine.devices[":maincpu"]

local out_path = os.getenv("OUT") or "pc_count.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local sites, order = {}, {}
for a in (os.getenv("SITES") or ""):gmatch("[^,%s]+") do
    local v = tonumber(a, 16)
    assert(v, "SITES entry must be hex — got '" .. a .. "'")
    sites[v] = { hits = 0, frames = 0, max = 0 }
    order[#order + 1] = v
end
assert(#order > 0, "set SITES=hexaddr,...")
table.sort(order)

local frame = 0
local held = {}
local FIELDS_IO = nil
local replay_path = os.getenv("REPLAY")
if replay_path then
    local ioport = machine.ioport
    local function fld(port, name) return ioport.ports[port].fields[name] end
    FIELDS_IO = {
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
                    if who and FIELDS_IO[who] then
                        local step = (who == "sys") and 2 or 1
                        for i = 1, #toks, step do
                            local fo = FIELDS_IO[who][toks:sub(i, i + step - 1)]
                            if fo then
                                for fr = tonumber(a), tonumber(b) do
                                    held[fr] = held[fr] or {}
                                    held[fr][#held[fr] + 1] = fo
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
for _, addr in ipairs(order) do
    debugger:command(string.format("bpset 0x%x", addr))
end

-- THE FRAME CLOCK IS EMULATED TIME, NOT frame_done CALLS ([MFI-5]/[MFI-6]): while a
-- breakpoint holds the CPU, MAME keeps emitting UI frames and frame_done keeps firing,
-- so a frame_done counter inflates past emulated time and replay input lands early
-- (measured 14z-189: 03_two_player_vs counted 5320 "frames" in 44 emulated seconds,
-- and the Shadow replay's five START presses missed the "?" cell once 27 sites were
-- armed). The screen's own frame number advances only with emulated frames.
local screen = assert(manager.machine.screens[":screen"], "no :screen device")
-- PC_CLOCK=frame_done restores the OLD (drifting) clock: the must-fire control of
-- tests/audit_marionette_cost.sh ("drift-clock") proves the gate sees the desync.
local DRIFT = (os.getenv("PC_CLOCK") or "") == "frame_done"
local last_fn = screen:frame_number()
local f = assert(io.open(out_path, "wb"))
local cur = {}            -- [addr] = hits in the current frame
local pressed = {}
local ui_frames = 0
emu.register_frame_done(function()
    local fn = screen:frame_number()
    if fn == last_fn and not DRIFT then ui_frames = ui_frames + 1; return end
    last_fn = fn
    frame = frame + 1
    local parts = {}
    for _, a in ipairs(order) do
        local n = cur[a]
        if n then
            parts[#parts + 1] = string.format("%x:%d", a, n)
            local s = sites[a]
            s.frames = s.frames + 1
            if n > s.max then s.max = n end
        end
    end
    if #parts > 0 then f:write(string.format("F %d %s\n", frame, table.concat(parts, " "))) end
    cur = {}
    if FIELDS_IO then
        local want = {}
        for _, fo in ipairs(held[frame + 1] or {}) do want[fo] = true end
        for _, group in pairs(FIELDS_IO) do
            for _, fo in pairs(group) do
                if want[fo] and not pressed[fo] then fo:set_value(1); pressed[fo] = true
                elseif not want[fo] and pressed[fo] then fo:clear_value(); pressed[fo] = nil end
            end
        end
    end
    if frame >= max_frames then
        for _, a in ipairs(order) do
            local s = sites[a]
            f:write(string.format("SITE %06x hits %d frames %d max %d\n", a, s.hits, s.frames, s.max))
        end
        f:write(string.format("UIFRAMES %d\n", ui_frames))
        f:write(string.format("PCEND %d\n", frame))
        f:close()
        machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger.execution_state == "stop" then
        local pc = cpu.state["CURPC"].value
        local s = sites[pc]
        if s then
            s.hits = s.hits + 1
            cur[pc] = (cur[pc] or 0) + 1
        end
        debugger.execution_state = "run"
    end
end)
