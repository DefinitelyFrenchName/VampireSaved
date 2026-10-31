-- tenant_ai_tap.lua — the #129 CPU-AI breakpoint instrument (tests/audit_tenant_cpu_ai.sh, 14z-215; promoted from the
-- capture worker's build/agent215/t129/scripts/t129_tap.lua with its snapshots dropped, its per-frame trace taken from
-- FIELDS in field_trace.lua's grammar, the machine's name written first, and the shadow's class written beside its result).
-- Logging breakpoints (each stop logged with registers and fighter fields, then resumed) and a per-frame field trace in
-- ONE debug run, on tests/lua/emu_clock.lua's emulated-frame clock (replay.lua's input staging; POKES applied per frame
-- before the instrument's own work).
--
-- ENV
--   REPLAY, FRAMES, ALIGN_OUT  (emu_clock)
--   POKES                   pokes_spec grammar (F or F1-F2 entries)
--   SITES                   "addr[@cond]|addr[@cond]|..."  hex addresses; cond = a MAME debugger expression
--   SHADOW                  "addr,addr,..." sites at which to evaluate a Lua re-implementation of vs2 PRG:0x2CD38
--                           (the low-attack test) on the CURRENT memory, opponent = word (a6+0x32)
--   SHADOW_DROP             a hex class byte the shadow answers 0 for (ONLY the gate's shadow-class-removed control)
--   FIELDS                  per-frame trace, "addr:size:name,..." (b/w/l; words and longs signed)
--   TRACE_FROM              first frame of the per-frame trace (default 2880)
--   ADAPT                   "<button>:<period>:<from>[:<dist>]" the adaptive P1 (below)
--   OUT                     output path
-- OUTPUT
--   SYSTEM <name>           the machine that ran (vsav2, vsavjw, ...), first line
--   SHADOW_DROP <class>     when the control is applied
--   S <frame> <pc> ret=<long at the active a7> d0= d3= d4= sr= a4= a6= c382= c1bc= c3b4= c07= c06= c121= o121= o1ba= o38=
--     [sh=<0|1|x> shc=<class byte|-->]
--   F <frame> name=value ...      per-frame trace from TRACE_FROM
--   SITE <addr> <stops>     per armed site, at the end
--   END frames=<n> stops=<n>
local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
local clock = dofile(here .. "emu_clock.lua")
local C = clock{ name = "tenant_ai_tap", frames = 22880 }
local machine = manager.machine
local debugger = machine.debugger
local NOSITES = (os.getenv("SITES") or "") == ""
assert(debugger or NOSITES, "run mame with -debug")
local cpu = machine.devices[":maincpu"]
local prog = cpu.spaces["program"]
local f = assert(io.open(os.getenv("OUT") or "tenant_ai_tap.txt", "wb"))
f:write("SYSTEM " .. machine.system.name .. "\n")

local plist = dofile(here .. "pokes_spec.lua").append({}, os.getenv("POKES"))
local pokes = {}
for _, pk in ipairs(plist) do
    pokes[pk[1]] = pokes[pk[1]] or {}
    table.insert(pokes[pk[1]], pk)
end

local sites = {}
if debugger then debugger:command("focus 0") end
for spec in (os.getenv("SITES") or ""):gmatch("[^|]+") do
    local a, cond = spec:match("^%s*(%x+)@(.-)%s*$")
    if not a then a = spec:match("^%s*(%x+)%s*$") end
    assert(a, "bad SITES entry " .. spec)
    local v = tonumber(a, 16)
    sites[v] = 0
    if cond and cond ~= "" then
        debugger:command(string.format("bpset %x,%s", v, cond))
    else
        debugger:command(string.format("bpset %x", v))
    end
end
local shadow = {}
for a in (os.getenv("SHADOW") or ""):gmatch("[^,%s]+") do shadow[tonumber(a, 16)] = true end
local drop = tonumber(os.getenv("SHADOW_DROP") or "", 16)
if drop then f:write(string.format("SHADOW_DROP %02x\n", drop)) end

local function sext16(v) return (v >= 0x8000) and (0xff0000 | v) or v end

-- vs2 PRG:0x2CD38 in Lua: a4 = opponent; a2 = long(a4+1C); a1 = long(a4+8C); walk a2 records of 0x18 bytes while
-- byte(a2+0A) == 0 and (byte(a2+1) & C0) == 0; then class = byte(a1 + idx*32 + 0x17): <20 -> mask 0C, <40 -> mask
-- 03000000 (class-20), <60 -> mask 0 (class-40), else 0; result = bit (class mod 32) of mask.
-- Returns result, class byte (nil when no class was reached).
local function shadow_2cd38(a6)
    local a4 = sext16(prog:read_u16(a6 + 0x32)) & 0xffffff
    local a2 = prog:read_u32(a4 + 0x1c) & 0xffffff
    local a1 = prog:read_u32(a4 + 0x8c) & 0xffffff
    for _ = 1, 64 do
        local d3 = prog:read_u8(a2 + 0x0a)
        if d3 ~= 0 then
            local off = (d3 << 5) & 0xffff
            if off >= 0x8000 then off = off - 0x10000 end
            local c0 = prog:read_u8(((a1 + off) & 0xffffff) + 0x17)
            if drop and c0 == drop then return 0, c0 end
            local c, mask = c0, nil
            if c < 0x20 then mask = 0x0c
            elseif c < 0x40 then c = c - 0x20; mask = 0x03000000
            elseif c < 0x60 then c = c - 0x40; mask = 0
            else return 0, c0 end
            return (mask >> (c & 31)) & 1, c0
        end
        if (prog:read_u8(a2 + 1) & 0xc0) ~= 0 then return 0, nil end
        a2 = (a2 + 0x18) & 0xffffff
    end
    return "x", nil
end

local stops = 0
emu.register_periodic(function()
    if debugger and debugger.execution_state == "stop" then
        local st = cpu.state
        local pc = st["CURPC"].value & 0xffffff
        if sites[pc] then
            sites[pc] = sites[pc] + 1
            stops = stops + 1
            local a6 = st["A6"].value & 0xffffff
            -- the active A7: MAME names the 68000 stacks SP (supervisor) and USP; the game code here runs in USER mode
            local a7 = (((st["SR"].value & 0x2000) ~= 0) and st["SP"] or st["USP"]).value & 0xffffff
            local opp = sext16(prog:read_u16(a6 + 0x32)) & 0xffffff
            local line = string.format(
                "S %d %06x ret=%06x d0=%08x d3=%08x d4=%08x sr=%04x a4=%06x a6=%06x c382=%02x c1bc=%02x c3b4=%02x c07=%02x c06=%02x c121=%02x o121=%02x o1ba=%02x o38=%02x",
                C.frame(), pc, prog:read_u32(a7) & 0xffffff, st["D0"].value, st["D3"].value, st["D4"].value,
                st["SR"].value & 0xffff, st["A4"].value & 0xffffff, a6,
                prog:read_u8(a6 + 0x382), prog:read_u8(a6 + 0x1bc), prog:read_u8(a6 + 0x3b4), prog:read_u8(a6 + 0x07),
                prog:read_u8(a6 + 0x06), prog:read_u8(a6 + 0x121), prog:read_u8(opp + 0x121), prog:read_u8(opp + 0x1ba),
                prog:read_u8(opp + 0x38))
            if shadow[pc] then
                local r, c = shadow_2cd38(a6)
                line = line .. " sh=" .. tostring(r) .. " shc=" .. (c and string.format("%02x", c) or "--")
            end
            f:write(line .. "\n")
        end
        debugger.execution_state = "run"
    end
end)

local FIELDS = {}
for spec in (os.getenv("FIELDS") or ""):gmatch("[^,]+") do
    local a, sz, name = spec:match("^%s*(%x+):([bwl]):(%S+)%s*$")
    assert(a, "FIELDS entry must be addr:size:name — got '" .. spec .. "'")
    FIELDS[#FIELDS + 1] = { name, tonumber(a, 16), sz }
end
local function rd(a, s)
    if s == "b" then return prog:read_u8(a) end
    if s == "w" then local v = prog:read_u16(a); return v >= 0x8000 and v - 0x10000 or v end
    local v = prog:read_u32(a); return v >= 0x80000000 and v - 0x100000000 or v
end
local trace_from = tonumber(os.getenv("TRACE_FROM") or "") or 2880

-- ADAPT="<button>:<period>:<from>[:<dist>]" — an ADAPTIVE P1 (the B rig): from frame <from>, each <period> frames P1 walks
-- toward the CPU on cycle frames 0-17 while |x1-x2| > <dist> (default 60), then presses <button> (no direction: standing) on
-- cycle frames 20-21 and 32-33. Staged after the replay's own staging, for frame N+1, as replay.lua stages.
local adapt = nil
do
    local b, per, from, dist = (os.getenv("ADAPT") or ""):match("^(%d):(%d+):(%d+):?(%d*)$")
    if b then
        local io = machine.ioport
        local function fld(port, n) return io.ports[port].fields[n] end
        local bf = { ["1"] = fld(":IN0", "P1 Button 1"), ["2"] = fld(":IN0", "P1 Button 2"), ["3"] = fld(":IN0", "P1 Button 3"),
                     ["4"] = fld(":IN1", "P1 Button 4"), ["5"] = fld(":IN1", "P1 Button 5"), ["6"] = fld(":IN1", "P1 Button 6") }
        adapt = { btn = bf[b], per = tonumber(per), from = tonumber(from), L = fld(":IN0", "P1 Left"), R = fld(":IN0", "P1 Right"), on = {}, dist = tonumber(dist) or 60 }
    end
end
local function adapt_stage(frame)
    if not adapt then return end
    local n = frame + 1
    local want = {}
    if n >= adapt.from then
        local t = (n - adapt.from) % adapt.per
        local x1, x2 = rd(0xff8410, "w"), rd(0xff8810, "w")
        if t <= 17 and math.abs(x1 - x2) > adapt.dist then want[(x1 < x2) and adapt.R or adapt.L] = true end
        if t == 20 or t == 21 or t == 32 or t == 33 then want[adapt.btn] = true end
    end
    for _, fo in ipairs({ adapt.L, adapt.R, adapt.btn }) do
        if want[fo] and not adapt.on[fo] then fo:set_value(1); adapt.on[fo] = true
        elseif not want[fo] and adapt.on[fo] then fo:clear_value(); adapt.on[fo] = nil end
    end
end

C.run{
    after_staging = adapt_stage,
    on_pokes = function(frame)
        for _, pk in ipairs(pokes[frame] or {}) do
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do prog:write_u8(a, tonumber(b, 16)); a = a + 1 end
        end
    end,
    on_frame = function(frame)
        if frame >= trace_from and #FIELDS > 0 then
            local parts = { "F " .. frame }
            for _, fd in ipairs(FIELDS) do parts[#parts + 1] = fd[1] .. "=" .. rd(fd[2], fd[3]) end
            f:write(table.concat(parts, " ") .. "\n")
        end
    end,
    on_end = function(frame)
        local keys = {}
        for a in pairs(sites) do keys[#keys + 1] = a end
        table.sort(keys)
        for _, a in ipairs(keys) do f:write(string.format("SITE %06x %d\n", a, sites[a])) end
        f:write(string.format("END frames=%d stops=%d\n", frame, stops))
        f:close()
    end,
}
