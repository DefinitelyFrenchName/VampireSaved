-- dispatch_census.lua — WHICH TYPE INDICES does a PC-relative jump table
-- ever dispatch? Accumulates the SET of indices seen at each site and
-- prints only the summary, so a site that fires 100k times in a replay
-- costs one line of output instead of 100k.
--
-- WHY (14z-89). The legacy-cycle regression's fix (option b, maintainer
-- 2026-08-15) wants the tenant's object types moved onto table entries
-- LEGACY NEVER DISPATCHES — repointing such an entry is a pure data
-- change and costs zero legacy cycles, where any code hook at the site
-- costs cycles on every dispatch and tips VBL-edge frames. That needs a
-- census: 17 free indices in the 59-entry table at 0x054470 and 10 in the
-- 114-entry table at 0x05E542, or route (i) is dead and the fix has to be
-- architectural instead.
--
-- THE SITE SHAPE: `movea.l (0x12,PC,D0.w),A0` — D0 holds index*4 AT the
-- instruction and is cleared by the `moveq #0,D0` right after, so the
-- breakpoint must sit ON the site, not after it (14z-81b).
--
-- A DEADNESS CLAIM IS ONLY AS GOOD AS ITS COVERAGE. This session's own
-- lesson: the type-6 deadness row was measured on four replays and was
-- WRONG. Run this over the whole legacy corpus, and treat "never observed
-- in N replays" as exactly that — never observed, not proven dead.
--
--   env SITES      "54470:59,5e542:114" — addr:n_entries, hex addr
--   env CENSUS_OUT output path (default dispatch_census.txt)
--   env REPLAY     input script (replay.lua grammar subset)
--   env FRAMES     stop after this many frames (default 3600)
--
-- Output, one block per site:
--   SITE <addr> entries <n> hits <total> seen <count> : <sorted indices>
--   FREE <addr> <count> : <sorted never-observed indices>
-- then "CENSUSEND <frames>". Needs -debug -debugger none.
local machine = manager.machine
local debugger = machine.debugger
assert(debugger, "run mame with -debug")
local cpu = machine.devices[":maincpu"]

local out_path = os.getenv("CENSUS_OUT") or "dispatch_census.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local sites = {}          -- [addr] = {n = entries, seen = {}, hits = 0}
for spec in (os.getenv("SITES") or ""):gmatch("[^,]+") do
    local a, n = spec:match("^%s*(%x+):(%d+)%s*$")
    assert(a, "SITES entry must be hexaddr:entries — got '" .. spec .. "'")
    sites[tonumber(a, 16)] = { n = tonumber(n), seen = {}, hits = 0 }
end
assert(next(sites), "set SITES=hexaddr:entries,...")

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
for addr, _ in pairs(sites) do
    debugger:command(string.format("bpset 0x%x", addr))
end

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
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
        local f = assert(io.open(out_path, "wb"))
        local addrs = {}
        for a, _ in pairs(sites) do addrs[#addrs + 1] = a end
        table.sort(addrs)
        for _, a in ipairs(addrs) do
            local s = sites[a]
            local seen, free = {}, {}
            for i = 0, s.n - 1 do
                if s.seen[i] then seen[#seen + 1] = i else free[#free + 1] = i end
            end
            f:write(string.format("SITE %06x entries %d hits %d seen %d : %s\n",
                a, s.n, s.hits, #seen, table.concat(seen, ",")))
            f:write(string.format("FREE %06x %d : %s\n", a, #free, table.concat(free, ",")))
        end
        f:write(string.format("CENSUSEND %d\n", frame))
        f:close()
        machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger.execution_state == "stop" then
        local st = cpu.state
        local pc = st["CURPC"].value
        local s = sites[pc]
        if s then
            -- D0 holds index*4 AT the site; mask to the word the mode uses
            local idx = (st["D0"].value & 0xffff) // 4
            s.hits = s.hits + 1
            if idx < s.n then s.seen[idx] = true else s.seen[-1] = true end
        end
        debugger.execution_state = "run"
    end
end)
