-- fsm_census.lua — WHICH node-state indices does the OBJECT-SCRIPT STATE
-- DISPATCHER FAMILY ever see, and — for every OUT-OF-RANGE one — from which
-- data NODE (14z-110, GitHub #99).
--
-- WHY. #99 is a vs2-numbered node-state byte (0x51) in Donovan's ported
-- block over-indexing vsavj's 80-entry FSM table at 0x018510 -> vec3. The
-- 14z-43 consumer audit for the type-0x51 family named dispatchers 1 and 3
-- (0x018460 / 0x0185D2) but NOT dispatcher 2 (0x018508), which is the one
-- that crashes. This census closes that gap by MEASUREMENT: it watches every
-- dispatcher in the family and, whenever the index is >= the table's entry
-- count, logs the frame, the dispatched index, and A3/A1 — A3 is the node
-- address (its +0x17 byte IS the index), so a hit is attributable to a
-- specific ported record without a node-stream walker.
--
-- A "SITE" is a dispatch point where D0 already holds the index scaled by
-- `div` (2 for the word-offset FSM tables after `add.w d0,d0`; 4 for the
-- long-pointer obj_hook tables). Give each site its entry count and divisor:
--
--   env SITES  "1843e:80:2,185d2:80:2"   addr:entries:div  (div default 4)
--   env CENSUS_OUT  output path (default fsm_census.txt)
--   env REPLAY / FRAMES  as dispatch_census.lua (replay.lua grammar subset)
--   env OOR_MIN  only log an OOR hit when idx >= this (default = entries)
--                — set below `entries` to also capture in-range indices of
--                interest (e.g. the 0x50-0x53 window a fix would port).
--
-- Output, one block per site, then per-OOR lines, then CENSUSEND:
--   SITE <addr> entries <n> div <d> hits <total> seen <count> : <indices>
--   OOR  <addr> <idx> frame <f> A3 <a3> A1 <a1>   (one per distinct
--        idx+A3, first frame kept; count on the SITE line's "oor <k>")
--   CENSUSEND <frames>
--
-- THE INSTRUMENT IS ONLY AS GOOD AS ITS COVERAGE (14z-89, the type-6 lesson):
-- "never observed in N replays" is a BOUND, not a proof. Needs -debug
-- -debugger none. Verify against a KNOWN OOR hit (the #99 Donovan-vs-Phobos
-- leg, idx 0x51 at A3=0x3fb882) before believing any absence — a probe that
-- fires nowhere is usually broken, not evidence of nothing.
local machine = manager.machine
local debugger = machine.debugger
assert(debugger, "run mame with -debug -debugger none")
local cpu = machine.devices[":maincpu"]
local program = cpu.spaces["program"]

-- POKES="frame:addr:hexbytes;..." (mirrors replay_guard.lua) — scheduled RAM
-- writes, so this census can venue-steer ($FF8121) or force a class the same
-- way the guarded rigs do. NOTE POKES does NOT disable this census's
-- breakpoints (unlike GUARD_PROBE, STATE_HISTORY:5173) — the two are
-- independent here.
local pokes = {}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
end

local out_path = os.getenv("CENSUS_OUT") or "fsm_census.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600
local oor_min_env = tonumber(os.getenv("OOR_MIN") or "", 16)   -- hex, like addresses
-- TNODE_MIN: also record (as a TNODE line) any hit whose A3 is >= this, at ANY
-- index — so the census maps which TENANT node-record arrays (placed above
-- CPU:$300000) the dispatcher family actually reads. That set is what a static
-- +0x17 scan needs to avoid false candidates in non-node data (14z-110): a
-- raw byte scan of the ported blocks yields hundreds of coincidental 0x50-0x53
-- bytes; only the A3 the dispatcher reads is a real node.
local tnode_min = tonumber(os.getenv("TNODE_MIN") or "", 16) or 0x300000

local sites = {}          -- [addr] = {n, div, oormin, seen={}, hits, oor={}, noor}
for spec in (os.getenv("SITES") or ""):gmatch("[^,]+") do
    local a, n, d = spec:match("^%s*(%x+):(%d+):?(%x*)%s*$")
    assert(a, "SITES entry must be hexaddr:entries[:div] — got '" .. spec .. "'")
    local nn = tonumber(n)
    sites[tonumber(a, 16)] = {
        n = nn, div = (d ~= "" and tonumber(d, 16)) or 4,
        oormin = oor_min_env or nn,
        seen = {}, hits = 0, oor = {}, noor = 0, tnode = {}, ntnode = 0,
    }
end
assert(next(sites), "set SITES=hexaddr:entries[:div],...")

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

local function flush()
    local f = assert(io.open(out_path, "wb"))
    local addrs = {}
    for a, _ in pairs(sites) do addrs[#addrs + 1] = a end
    table.sort(addrs)
    for _, a in ipairs(addrs) do
        local s = sites[a]
        local seen = {}
        for i = 0, s.n - 1 do if s.seen[i] then seen[#seen + 1] = i end end
        if s.seen[-1] then seen[#seen + 1] = -1 end   -- >= n bucket marker
        f:write(string.format("SITE %06x entries %d div %d hits %d seen %d oor %d tnode %d : %s\n",
            a, s.n, s.div, s.hits, #seen, s.noor, s.ntnode, table.concat(seen, ",")))
        local keys = {}
        for k, _ in pairs(s.oor) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local o = s.oor[k]
            f:write(string.format("OOR %06x %02x frame %d A3 %06x A1 %06x count %d\n",
                a, o.idx, o.frame, o.a3, o.a1, o.count))
        end
        local tk = {}
        for k, _ in pairs(s.tnode) do tk[#tk + 1] = k end
        table.sort(tk)
        for _, k in ipairs(tk) do
            local o = s.tnode[k]
            f:write(string.format("TNODE %06x %02x A3 %06x A1 %06x frame %d count %d\n",
                a, o.idx, o.a3, o.a1, o.frame, o.count))
        end
    end
    f:write(string.format("CENSUSEND %d\n", frame))
    f:close()
end

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do
                program:write_u8(a, tonumber(b, 16)); a = a + 1
            end
        end
    end
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
    if frame >= max_frames then flush(); machine:exit() end
end)

emu.register_periodic(function()
    if debugger.execution_state == "stop" then
        local st = cpu.state
        local pc = st["CURPC"].value
        local s = sites[pc]
        if s then
            local idx = (st["D0"].value & 0xffff) // s.div
            s.hits = s.hits + 1
            if idx < s.n then s.seen[idx] = true else s.seen[-1] = true end
            local a3 = st["A3"].value & 0xffffff
            local a1 = st["A1"].value & 0xffffff
            if idx >= s.oormin then
                local key = string.format("%02x@%06x", idx, a3)
                local o = s.oor[key]
                if o then o.count = o.count + 1
                else s.oor[key] = { idx = idx, a3 = a3, a1 = a1, frame = frame, count = 1 }
                     s.noor = s.noor + 1 end
            end
            if a3 >= tnode_min then
                local tkey = string.format("%06x", a3)
                local t = s.tnode[tkey]
                if t then t.count = t.count + 1
                    if idx > t.idx then t.idx = idx end   -- keep the MAX index seen at this node
                else s.tnode[tkey] = { idx = idx, a3 = a3, a1 = a1, frame = frame, count = 1 }
                     s.ntnode = s.ntnode + 1 end
            end
        end
        debugger.execution_state = "run"
    end
end)
