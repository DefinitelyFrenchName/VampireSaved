-- trace_writes.lua — log every write hitting a watched RAM range: PC, value,
-- and register state. The standard tool for "who initializes this field?"
-- (used with tools/run_mame.sh; requires -debug on the command line).
--
--   env REPLAY       optional input script (same format as replay.lua)
--   env WATCH        "ff8480,4" (start,len) or "ff8480,4,r" / "...,rw"
--                    (watch mode; default w = writes); mode "b" sets an
--                    EXECUTION BREAKPOINT at the address instead (len
--                    ignored) — log registers at a PC (session 14c).
--                    An optional 4th field selects the ADDRESS SPACE:
--                    "8f216,4,r,o" watches the OPCODES space (wposet),
--                    "…,d" the data space, default/"p" the program space.
--                    THIS MATTERS: on CPS-2 every pc-relative read
--                    (`move.w (d16,pc,Dn),Dm`, `movea.l (d16,pc,Dn),An` —
--                    i.e. every jump/handler table the engine indexes) is
--                    served by m68k_read_pcrelative_*, which goes through
--                    m_readimm16 = AS_OPCODES. A plain wpset on such a
--                    table is SILENTLY BLIND and reports zero hits, which
--                    reads as "this table is never used" (14z-71).
--   env TRACE_OUT    log path (default trace_writes.txt)
--   env FRAMES       stop after this many frames (default 3600)
--   env DUMPS        "frame:lo-hi;..." (replay.lua grammar) — RAM dumps
--                    written next to TRACE_OUT as dump_<frame>_<lo>.bin.
--                    ADDED 14z-98: every -debug watch configuration is
--                    its own TIMELINE (three same-poke trace runs took
--                    three different match trajectories — the 14z-97b
--                    gotcha, extended), so state anchors must come from
--                    the SAME run as the trace or the hits cannot be
--                    interpreted. A trace run should be self-documenting.
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

-- LENGTH IS HEX, and it must be matched as hex (14z-71). MAME's debugger
-- parses `wpset addr,len,...` numbers as HEX, so a length of "a" means ten
-- bytes and "10" means sixteen. The pattern used to demand %d+ for the
-- length, so any hex-lettered length (a, b, c, …) failed the match, the
-- assert killed the run BEFORE the replay started, and the trace file came
-- out EMPTY — which reads downstream as "zero accesses, this address is
-- never touched". That is a false negative that looks exactly like a
-- finding; it nearly shipped one. Callers that passed decimal lengths are
-- unaffected: MAME was already reading them as hex.
local start_addr, len, mode, space = watch:match("^(%x+),(%x+),?(%a*),?(%a*)$")
assert(start_addr, "WATCH format: hexaddr,hexlen[,r|w|rw][,p|d|o]")
if mode == "" then mode = "w" end
if space == "" then space = "p" end
local WPCMD = { p = "wpset", d = "wpdset", o = "wposet" }
assert(WPCMD[space], "WATCH space must be p (program), d (data) or o (opcodes)")

-- register the watchpoint (or breakpoint, mode "b") on the maincpu
debugger:command(string.format("focus 0"))
if mode == "b" then
    debugger:command(string.format("bpset %s", start_addr))
else
    debugger:command(string.format("%s %s,%s,%s", WPCMD[space], start_addr, len, mode))
end

-- POKES (14z-68): same grammar/application point as replay.lua, so the
-- forced-pick rigs can be traced.
local poke_space = cpu.spaces["program"]
-- DUMPS (14z-98): see the header. Same grammar/application point as
-- replay.lua's DUMPS; files land next to TRACE_OUT (the 14z-93 gotcha).
local dumps = {}
for spec in (os.getenv("DUMPS") or ""):gmatch("[^;]+") do
    local fr, lo, hi = spec:match("^(%d+):(%x+)-(%x+)$")
    assert(fr, "DUMPS spec must be frame:hexlo-hexhi — got " .. spec)
    dumps[#dumps + 1] = { tonumber(fr), tonumber(lo, 16), tonumber(hi, 16) }
end
local dump_dir = out_path:match("^(.*)/") or "." 
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
    for _, dm in ipairs(dumps) do
        if dm[1] == frame then
            local df = assert(io.open(string.format("%s/dump_%d_%x.bin",
                                                    dump_dir, frame, dm[2]), "wb"))
            local bytes = {}
            for a = dm[2], dm[3] - 1 do
                bytes[#bytes + 1] = string.char(poke_space:read_u8(a))
            end
            df:write(table.concat(bytes)); df:close()
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
