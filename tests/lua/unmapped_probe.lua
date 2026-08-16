-- unmapped_probe.lua — 68k unmapped-address-space census (WIDE Phase A / A1).
--
-- WHY: CPS-2 WIDE proposes growing the program ROM region from 4MB to 6MB.
-- FBNeo maps program ROM with a single
--     SekMapMemory(CpsRom, 0, nCpsRomLen - 1, MAP_READ)
-- so growing the declared members grows the mapping with ZERO core-code
-- changes — but it also means CPU:$400000-$5FFFFF stops reading as open
-- bus and starts returning ROM content. That is only safe if vanilla
-- content never reads there.
--
-- This installs read taps over the candidate extension windows and logs
-- every access with the PC that made it. Any hit means linear growth is
-- NOT inert and the extension must move to a high unused base instead
-- (costing two declarative SekMapMemory lines).
--
-- Windows probed (all currently undecoded on CPS-2; the known decoded
-- neighbours are 0x400000 CpsFrg, 0x618000 QSound, 0x660000 NVRAM,
-- 0x708000 OBJ RAM, 0x800000 CpsReg, 0x900000 palette/gfx, 0xFF0000 work):
--     0x401000-0x5FFFFF   the linear-growth candidate
--     0x620000-0x65FFFF   gap above QSound
--     0x670000-0x6FFFFF   gap above NVRAM
--     0xA00000-0xDFFFFF   the high-window fallback candidate
--
--   env REPLAY     input script
--   env TRACE_OUT  report path (default unmapped_probe.txt)
--   env FRAMES     stop after N frames (default 3600)
--
-- Ends with UNMAPPEDSUMMARY for scripted assertion.
-- INPUT-STAGING CONVENTION (14z-90, GitHub issue #10). This instrument
-- stages inputs at the START of the frame callback (`prev = held[frame]`),
-- whereas tests/lua/replay.lua stages for the NEXT frame at the END
-- (`held[frame + 1]`). The two therefore land a given press on DIFFERENT
-- frames. That is tolerable here only because this instrument is a PASSIVE
-- OBSERVER — a tap/census whose output is "what happened", not "what
-- happened at replay.lua's frame N". DO NOT cross-reference a frame number
-- from this log with a compare_* first-divergence, a masked window onset, or
-- replay.lua's checksum log: they are one frame apart. Unifying the two
-- conventions would re-date the frozen frame constants in this instrument's
-- consuming gates and is deferred until after the legacy re-freeze.

local out_path = os.getenv("TRACE_OUT") or "unmapped_probe.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local space = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))

local WINDOWS = {
    { name = "prg_linear", lo = 0x401000, hi = 0x5FFFFF },
    { name = "gap_qsnd",   lo = 0x620000, hi = 0x65FFFF },
    { name = "gap_nvram",  lo = 0x670000, hi = 0x6FFFFF },
    { name = "high_win",   lo = 0xA00000, hi = 0xDFFFFF },
}

-- PROBE_CONTROL=1 adds a window over work RAM, which the 68k reads
-- constantly. A "zero hits everywhere" result is only trustworthy if the
-- instrument can demonstrably SEE a hit — this is the ground-truth check
-- the project requires of any verdict logic before its verdicts are used.
if os.getenv("PROBE_CONTROL") then
    WINDOWS[#WINDOWS + 1] = { name = "CONTROL_workram", lo = 0xFF8000, hi = 0xFF80FF }
end

local hits = {}       -- name -> count
local samples = {}    -- first N detail lines per window
local frame = 0

local taps = {}
local installing = false
local function install()
    -- Reentrancy guard: installing a tap itself triggers the space change
    -- notifier, so an unguarded reinstall recurses until the stack dies
    -- (segfault, no diagnostic). tap_writes.lua carries the same guard.
    if installing then return end
    installing = true
    for _, w in ipairs(WINDOWS) do
        hits[w.name] = hits[w.name] or 0
        samples[w.name] = samples[w.name] or {}
        taps[#taps + 1] = space:install_read_tap(w.lo, w.hi, "unmapped_" .. w.name,
            function(offset, data, mask)
                hits[w.name] = hits[w.name] + 1
                local s = samples[w.name]
                if #s < 20 then
                    s[#s + 1] = string.format("f%d %s rd %06x pc %06x",
                        frame, w.name, offset, cpu.state["CURPC"].value)
                end
            end)
    end
    installing = false
end
install()
-- CPS-2 reinstalls handlers after boot; a tap dropped then would read as
-- "nobody ever touched it" (the documented GOTCHA that cost a session).
space:add_change_notifier(function() install() end)

local held = {}
local replay_path = os.getenv("REPLAY")
if replay_path then
    local ioport = machine.ioport
    local function fld(p, n) return ioport.ports[p].fields[n] end
    local F = {
        p1 = { U=fld(":IN0","P1 Up"), D=fld(":IN0","P1 Down"), L=fld(":IN0","P1 Left"), R=fld(":IN0","P1 Right"),
               ["1"]=fld(":IN0","P1 Button 1"), ["2"]=fld(":IN0","P1 Button 2"), ["3"]=fld(":IN0","P1 Button 3"),
               ["4"]=fld(":IN1","P1 Button 4"), ["5"]=fld(":IN1","P1 Button 5"), ["6"]=fld(":IN1","P1 Button 6") },
        p2 = { U=fld(":IN0","P2 Up"), D=fld(":IN0","P2 Down"), L=fld(":IN0","P2 Left"), R=fld(":IN0","P2 Right"),
               ["1"]=fld(":IN0","P2 Button 1"), ["2"]=fld(":IN0","P2 Button 2"), ["3"]=fld(":IN0","P2 Button 3"),
               ["4"]=fld(":IN1","P2 Button 4"), ["5"]=fld(":IN1","P2 Button 5"), ["6"]=fld(":IN2","P2 Button 6") },
        sys = { S1=fld(":IN2","1 Player Start"), S2=fld(":IN2","2 Players Start"), C1=fld(":IN2","Coin 1"),
                C2=fld(":IN2","Coin 2"), SV=fld(":IN2","Service 1"), TS=fld(":IN2","Service Mode") },
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
                    if who and F[who] then
                        local st = (who == "sys") and 2 or 1
                        for i = 1, #toks, st do
                            local fo = F[who][toks:sub(i, i + st - 1)]
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

local prev = {}
emu.register_frame_done(function()
    frame = frame + 1
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end
    if frame >= max_frames then
        local parts, total = {}, 0
        for _, w in ipairs(WINDOWS) do
            for _, l in ipairs(samples[w.name]) do f:write(l .. "\n") end
            parts[#parts + 1] = string.format("%s=%d", w.name, hits[w.name])
            total = total + hits[w.name]
        end
        f:write(string.format("UNMAPPEDSUMMARY frames=%d total=%d %s\n",
            frame, total, table.concat(parts, " ")))
        f:close()
        manager.machine:exit()
    end
end)
