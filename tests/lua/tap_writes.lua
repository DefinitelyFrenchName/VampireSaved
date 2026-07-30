-- tap_writes.lua — log writes hitting a RAM range via a memory tap (no
-- debugger: frame counting stays replay-exact, unlike trace_writes.lua —
-- see docs/GOTCHAS.md on debugger stops desyncing replays). The tool for
-- "who writes this field DURING these frames?" on hot fields written
-- every frame (positions), where watchpoint stops would melt the replay.
--
--   env REPLAY     optional input script (same format as replay.lua)
--   env TAP        "ff8810,8" (start,len) — write tap over the range
--   env WINDOW     "3040,3110" — only log hits inside this frame window
--                  (tap installed the whole run; logging gated)
--   env TRACE_OUT  log path (default tap_writes.txt)
--   env FRAMES     stop after this many frames (default 3600)
--
-- Each hit logs: frame, PC (CURPC at tap time = the writing instruction),
-- tap offset, data word, mask. PCs aggregate at END as a histogram.

local tap_spec = assert(os.getenv("TAP"), "set TAP=start,len")
local out_path = os.getenv("TRACE_OUT") or "tap_writes.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600
local wa, wb = (os.getenv("WINDOW") or "0,99999999"):match("^(%d+),(%d+)$")
wa, wb = tonumber(wa), tonumber(wb)

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local space = cpu.spaces["program"]

local f = assert(io.open(out_path, "wb"))
local frame = 0
local hits = 0
local by_pc = {}

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

local start_addr, len = tap_spec:match("^(%x+),(%d+)$")
assert(start_addr, "TAP format: hexaddr,len")
start_addr = tonumber(start_addr, 16)

-- GOTCHA (paid for here): a passthrough tap is silently dropped whenever
-- anything re-installs handlers in the space (CPS-2 does this right after
-- boot) — without the change notifier the tap logs boot writes only and
-- reads as "nobody writes this field". Re-install on every space change.
local tap
local installing = false
local function install_tap()
    installing = true
    tap = space:install_write_tap(start_addr, start_addr + tonumber(len) - 1,
        "tapw", function(offset, data, mask)
            if frame >= wa and frame <= wb then
                local pc = cpu.state["CURPC"].value
                hits = hits + 1
                by_pc[pc] = (by_pc[pc] or 0) + 1
                local extra = ""
                if os.getenv("REGLOG") then
                    -- full register capture at write time (pcall-guarded):
                    -- names the source table pointers for computed cursors
                    local ok, res = pcall(function()
                        local st = cpu.state
                        local r = {}
                        for _, n in ipairs({"D0","D1","D2","D3","A0","A1","A2","A3","A4","A6"}) do
                            r[#r + 1] = n .. "=" .. string.format("%08x", st[n].value)
                        end
                        return " " .. table.concat(r, " ")
                    end)
                    extra = ok and res or (" regerr")
                end
                if os.getenv("STACKLOG") then
                    -- candidate return addresses from the top of the stack:
                    -- caller attribution for engine-internal writer PCs
                    -- (m68k register name differs by MAME version: SP or A7;
                    -- memory reads inside a tap are pcall-guarded)
                    local ok, res = pcall(function()
                        local st = cpu.state
                        local spr = st["SP"] or st["A7"]
                        local sp = spr.value
                        local r = {}
                        for k = 0, 4 do
                            r[#r + 1] = string.format("%08x",
                                                      space:read_u32(sp + k * 4))
                        end
                        return " stack " .. table.concat(r, " ")
                    end)
                    extra = ok and res or (" stackerr " .. tostring(res))
                end
                f:write(string.format("frame %d PC %06x off %06x data %08x mask %08x%s\n",
                                      frame, pc, offset, data, mask, extra))
            end
        end)
    installing = false
end
install_tap()
local notifier = space:add_change_notifier(function(mode)
    if not installing and mode:find("w") then install_tap() end
end)

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
        f:write(string.format("END %d hits %d\n", frame, hits))
        local pcs = {}
        for pc, n in pairs(by_pc) do pcs[#pcs + 1] = { pc, n } end
        table.sort(pcs, function(x, y) return x[2] > y[2] end)
        for _, e in ipairs(pcs) do
            f:write(string.format("PCHIST %06x %d\n", e[1], e[2]))
        end
        f:close()
        manager.machine:exit()
    end
end)
