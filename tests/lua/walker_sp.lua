-- walker_sp.lua — HOW DEEP IS THE STACK at a named PC? Accumulates the
-- min/max of A7 across every hit and prints only the summary, so a site
-- that fires 100k times in a replay costs one line (the dispatch_census
-- pattern).
--
-- WHY (14z-91). The obj_hook legacy-cycle fix relocates each object-pool
-- WALKER into free space and repoints its `jsr <walker>` call sites, so the
-- vanilla dispatch instruction is never patched and no instruction's timing
-- changes. Exactly ONE byte of state differs: the relocated `jsr (A0)`
-- pushes <copy>+0x20 where vanilla pushed <walker>+0x20. Same stack DEPTH,
-- same everything else.
--
-- That longword is invisible to the legacy oracle ONLY if it lands inside
-- the masked dead-stack window RAM:$FF7F00-$FF7FFF (CLAUDE.md §4, the
-- hooked-build legacy comparison basis; docs/game/atlas/ram.md). This
-- measures whether it does, on VANILLA, before any code is written. If it
-- does not, the relocation is not bit-identical and the design stops — the
-- answer is NOT to widen the mask (that redefines the baseline the superset
-- invariant rests on).
--
-- THE PUSH OCCUPIES [A7-4, A7-1] at the moment of the jsr, so the window
-- test is A7-4 >= 0xFF7F00 AND A7 <= 0xFF8000.
--
-- DO NOT ASSUME ONE STACK. 14z-89 attributed live divergences to return
-- addresses at BOTH $FF06B5-$FF06D3 and $FFF991-$FFF9D3 — this engine has
-- more than one region holding execution position, so the measurement
-- records where the stack actually is rather than checking a guess. The
-- per-page histogram is part of the verdict.
--
--   env SPSITES   "54476,5e548" — hex PCs to breakpoint (the `jsr (A0)`)
--   env SP_OUT    output path (default walker_sp.txt)
--   env REPLAY    input script (replay.lua grammar subset)
--   env FRAMES    stop after this many frames (default 3600)
--
-- Output, one block per site:
--   SP <addr> hits <n> min <a7min> max <a7max>
--   PAGES <addr> : <page>=<count> ...          (A7 >> 8, hex)
-- then "SPEND <frames>". Needs -debug -debugger none.
local machine = manager.machine
local debugger = machine.debugger
assert(debugger, "run mame with -debug")
local cpu = machine.devices[":maincpu"]

local out_path = os.getenv("SP_OUT") or "walker_sp.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local sites = {}          -- [addr] = {hits, min, max, pages = {}}
for spec in (os.getenv("SPSITES") or ""):gmatch("[^,]+") do
    local a = spec:match("^%s*(%x+)%s*$")
    assert(a, "SPSITES entry must be a hex PC — got '" .. spec .. "'")
    sites[tonumber(a, 16)] = { hits = 0, min = nil, max = nil, pages = {} }
end
assert(next(sites), "set SPSITES=hexpc,...")

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
            f:write(string.format("SP %06x hits %d min %s max %s\n", a, s.hits,
                    s.min and string.format("%08x", s.min) or "-",
                    s.max and string.format("%08x", s.max) or "-"))
            local pg = {}
            for p, _ in pairs(s.pages) do pg[#pg + 1] = p end
            table.sort(pg)
            local parts = {}
            for _, p in ipairs(pg) do
                parts[#parts + 1] = string.format("%06x=%d", p << 8, s.pages[p])
            end
            f:write(string.format("PAGES %06x : %s\n", a, table.concat(parts, " ")))
        end
        f:write(string.format("SPEND %d\n", frame))
        f:close()
        machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger.execution_state == "stop" then
        local st = cpu.state
        local pc = st["CURPC"].value & 0xFFFFFF
        local s = sites[pc]
        if s then
            -- A7 is the ACTIVE stack pointer; MAME's "SP" state can resolve
            -- to the inactive one (measured 14z-85g, tests/lua/bp_regs.lua).
            local spr = st["A7"] or st["SP"]
            local sp = spr.value & 0xFFFFFF
            s.hits = s.hits + 1
            if not s.min or sp < s.min then s.min = sp end
            if not s.max or sp > s.max then s.max = sp end
            local p = sp >> 8
            s.pages[p] = (s.pages[p] or 0) + 1
        end
        debugger.execution_state = "run"
    end
end)
