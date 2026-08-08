-- obj_records_dump.lua — dump the LIVE OBJ sprite list at named frames.
--
-- WHY: "the sprite is drawn with the wrong art" has exactly two possible
-- causes — the game emitted a different tile code/bank (a ROM/build fault)
-- or the emulator fetched a different address from the same record (an
-- emulator fault). Dumping the records the hardware actually walks, on two
-- builds at the same frame, separates them in one measurement. Written for
-- the 14z-60y WIDE sprite garble.
--
-- Walks the list the way the hardware does (y-word bit 15 terminates,
-- attr >= 0xFF00 terminates), both CPS-2 buffers, and prints per entry the
-- raw words plus the composed tile address under BOTH addressing rules:
--   addr18 = code | ((y & 0x6000) << 3)              stock CPS-2
--   addr19 = addr18 | (y & 0x1000 ? 0x40000 : 0)     CPS-2 WIDE / Turbo
--
--   env REPLAY       input script (replay.lua format)
--   env DUMP_FRAMES  comma-separated frames to dump
--   env TRACE_OUT    log path (default obj_records.txt)
--   env FRAMES       hard stop (default max(DUMP_FRAMES))
--   env OBJ_BASE     OBJ RAM base (default 708000), OBJ_LEN unused
--
-- Ends with OBJDUMPSUMMARY for scripted assertion.

local out_path = os.getenv("TRACE_OUT") or "obj_records.txt"
local obj_base = tonumber(os.getenv("OBJ_BASE") or "708000", 16)
local want, want_list = {}, {}
for tok in (os.getenv("DUMP_FRAMES") or ""):gmatch("[^,%s]+") do
    local n = tonumber(tok)
    if n then want[n] = true; want_list[#want_list + 1] = n end
end
assert(#want_list > 0, "DUMP_FRAMES must name at least one frame")
table.sort(want_list)
local max_frames = tonumber(os.getenv("FRAMES") or "") or want_list[#want_list]

local machine = manager.machine
local space = machine.devices[":maincpu"].spaces["program"]
local f = assert(io.open(out_path, "wb"))

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

local frame, prev, dumped, entries = 0, {}, 0, 0

-- POKES (14z-68): same grammar/application point as replay.lua, so the
-- forced-pick rigs can be dumped without hand-editing a replay.
local program = machine.devices[":maincpu"].spaces["program"]
local pokes = {}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
end

emu.register_frame_done(function()
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do
                program:write_u8(a, tonumber(b, 16))
                a = a + 1
            end
        end
    end
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end

    if want[frame] then
        for bi, base in ipairs({ obj_base, obj_base + 0x8000 }) do
            for i = 0, 0x3FF do
                local off = base + i * 8
                local y = space:read_u16(off + 2)
                if (y & 0x8000) ~= 0 then break end
                local attr = space:read_u16(off + 6)
                if attr >= 0xFF00 then break end
                local x = space:read_u16(off)
                local code = space:read_u16(off + 4)
                local a18 = code | ((y & 0x6000) << 3)
                local a19 = a18 | (((y & 0x1000) ~= 0) and 0x40000 or 0)
                entries = entries + 1
                f:write(string.format(
                    "F%d B%d E%03d x=%04x y=%04x code=%04x attr=%04x pal=%02x sz=%dx%d a18=%05x a19=%05x\n",
                    frame, bi - 1, i, x, y, code, attr, attr & 0x1F,
                    ((attr >> 8) & 15) + 1, ((attr >> 12) & 15) + 1, a18, a19))
            end
        end
        dumped = dumped + 1
    end

    if frame >= max_frames then
        f:write(string.format("OBJDUMPSUMMARY frames=%d dumped=%d entries=%d\n",
            frame, dumped, entries))
        f:close()
        machine:exit()
    end
end)
