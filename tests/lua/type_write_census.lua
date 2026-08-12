-- type_write_census.lua — log every write that lands a FAMILY-TYPE value
-- on an object slot's +0x02 type-byte lane inside a watched pool range.
-- The dynamic half of the 14z-82 type-stamp census: static scanning cannot
-- see register-sourced or computed stamps, so this tap answers "which PCs
-- actually write family type bytes at runtime" on the ground-truth builds.
--
-- Memory tap, NO debugger — frame counting stays replay-exact
-- (tap_writes.lua's mechanism; docs/GOTCHAS.md on watchpoint desync).
--
--   env REPLAY     input script (same format as replay.lua)
--   env TAP        "ff9400,3c00" (start,len hex) — pool range to watch
--   env POKES      "frame:addr:hexbytes;..." forced-pick rig
--   env TRACE_OUT  log path (default type_write_census.txt)
--   env FRAMES     stop after this many frames (default 7000)
--
-- Filter: writes whose word address has (addr & 0x7F) == 2 (the type-byte
-- lane of every 0x80-stride slot; also +2 of 0x100-stride slots, plus
-- mid-slot +0x82 coincidences that post-processing classifies by pool) and
-- whose HIGH byte lane carries a value in [0x3B,0x4B] or [0x72,0x78]
-- (the two obj_hook family ranges). Long stamps (move.l #$01xxTTss,(A4))
-- appear as their second word write — mask 0xFFFF, TT in the high lane.
-- Each hit: "W frame <n> PC <pc> addr <a> data <d> mask <m>". END line
-- carries totals; no END = the run died, the log is not evidence.

local tap_spec = assert(os.getenv("TAP"), "set TAP=start,len")
local out_path = os.getenv("TRACE_OUT") or "type_write_census.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 7000

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local space = cpu.spaces["program"]

local f = assert(io.open(out_path, "wb"))
local frame = 0
local hits = 0

local start_addr, len = tap_spec:match("^(%x+),(%x+)$")
assert(start_addr, "TAP format: hexaddr,hexlen")
start_addr = tonumber(start_addr, 16)
len = tonumber(len, 16)

local function fam(v)
    return (v >= 0x3B and v <= 0x4B) or (v >= 0x72 and v <= 0x78)
end

-- passthrough taps are silently dropped when the space re-installs
-- handlers (CPS-2 does at boot) — re-install on every change notify
-- (tap_writes.lua's paid-for gotcha)
local tap
local installing = false
local function install_tap()
    installing = true
    tap = space:install_write_tap(start_addr, start_addr + len - 1,
        "typecensus", function(offset, data, mask)
            if (offset & 0x7F) == 2 and (mask & 0xFF00) ~= 0 then
                local v = (data >> 8) & 0xFF
                if fam(v) then
                    hits = hits + 1
                    f:write(string.format(
                        "W frame %d PC %06x addr %06x data %08x mask %08x\n",
                        frame, cpu.state["CURPC"].value, offset, data, mask))
                end
            end
        end)
    installing = false
end
install_tap()
local notifier = space:add_change_notifier(function(mode)
    if not installing and mode:find("w") then install_tap() end
end)

-- input playback (same subset as replay.lua / tap_writes.lua)
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

-- POKES (same grammar as replay.lua, so the forced-pick rigs transfer)
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
