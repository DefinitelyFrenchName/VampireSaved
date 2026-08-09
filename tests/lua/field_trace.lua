-- field_trace.lua — log named RAM FIELDS every frame, for trajectory A/B.
--
-- WHY. The existing instruments answer "who wrote this?" (trace_writes),
-- "what sprites exist?" (obj_records_dump) and "is whole RAM identical?"
-- (replay.lua checksums). None answers "how did this VALUE move over
-- time, and where do the two legs part company?" — which is the question
-- every positioning / trajectory defect asks. Before this existed, the
-- alternative was dozens of whole-RAM DUMPS at named frames.
--
-- Sampling is at frame_done, i.e. the same point replay.lua checksums —
-- so a value logged for frame N is that frame's settled state.
--
-- CROSS-LEG USE. Fields are compared by NAME, never by address: the
-- native leg is vsav2 and the build is vsavj-based. Both happen to place
-- the fighter blocks identically ($FF8400 / $FF8800, atlas/ram.md) which
-- is what makes a position A/B legitimate here — but that is a MEASURED
-- fact about those blocks, not a general licence. Do not point this at an
-- address whose cross-game equivalence has not been established.
--
--   env FIELDS     "ff8810:w:victim_x,ff8814:w:victim_y"
--                  addr:size:name — size is b/w/l (byte/word/long).
--                  Words and longs are read SIGNED (positions are signed).
--   env FIELD_OUT  output path (default field_trace.txt)
--   env REPLAY     input script (replay.lua grammar)
--   env POKES      "frame:addr:hexbytes;..." (replay.lua grammar)
--   env FRAMES     stop after this many frames (default 3600)
--   env FIELD_FROM/FIELD_TO  optional frame window (default: all)
--
-- Output: one line per sampled frame,
--   F <frame> <name>=<value> <name>=<value> ...
-- then "FIELDSUMMARY frames=<n>" for scripted assertion.

local fields_spec = assert(os.getenv("FIELDS"), "set FIELDS=addr:size:name,...")
local out_path = os.getenv("FIELD_OUT") or "field_trace.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600
local win_lo = tonumber(os.getenv("FIELD_FROM") or "") or 0
local win_hi = tonumber(os.getenv("FIELD_TO") or "") or math.huge

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

local fields = {}
for spec in fields_spec:gmatch("[^,]+") do
    local a, sz, name = spec:match("^%s*(%x+):([bwl]):(%S+)%s*$")
    assert(a, "FIELDS entry must be addr:size:name — got '" .. spec .. "'")
    fields[#fields + 1] = { addr = tonumber(a, 16), size = sz, name = name }
end

local f = assert(io.open(out_path, "wb"))
local frame, logged = 0, 0

-- input playback + pokes: the replay.lua subset, same as trace_writes.lua
local held = {}
local replay_path = os.getenv("REPLAY")
local FIELDS_IO = nil
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

local pokes = {}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
end

local function read_field(fd)
    if fd.size == "b" then return mem:read_u8(fd.addr) end
    if fd.size == "w" then
        local v = mem:read_u16(fd.addr)
        return v >= 0x8000 and v - 0x10000 or v
    end
    local v = mem:read_u32(fd.addr)
    return v >= 0x80000000 and v - 0x100000000 or v
end

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do
                mem:write_u8(a, tonumber(b, 16)); a = a + 1
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
    if frame >= win_lo and frame <= win_hi then
        local parts = { string.format("F %d", frame) }
        for _, fd in ipairs(fields) do
            parts[#parts + 1] = string.format("%s=%d", fd.name, read_field(fd))
        end
        f:write(table.concat(parts, " ") .. "\n")
        logged = logged + 1
    end
    if frame >= max_frames then
        f:write(string.format("FIELDSUMMARY frames=%d\n", logged))
        f:close()
        machine:exit()
    end
end)
