-- inp_probe.lua — per-frame VIDEO + match-state + OBJ-count log for a MAME
-- .inp PLAYBACK (cheap mode, no -debug — faithful playback, like inp_guard).
-- 14z-112, written for GitHub #113 (the first-down "flash": on the CRT the
-- background stays while the sprites vanish for >=1 frame). A RAM gate is
-- blind to it; a human eye cannot name the frame. This names it.
--
-- Per frame, one line:
--   V <frame> <fnv1a64(framebuffer)> hp1=<h> w1=<w> d1=<death> hp2= w2= d2= rd=<$FF810E> t=<$FF8109> obj=<n0>/<n1> in=<IN0>,<IN1>,<IN2>
--   (in = raw input-port words, active-low — the recording's own inputs)
--   (hp/w = fighter +0x50/+0x52 signed words, d = +0x11F, obj = live OBJ
--    entries walked hardware-style in each CPS-2 buffer at 708000/710000)
-- At SNAP_FRAMES: machine.video:snapshot() (MAME numbering, "SNAP <frame> <k>").
-- At DUMP_FRAMES: the full OBJ record list, obj_records_dump.lua grammar.
-- END <frames>.  env CHECKSUM_OUT, MAX_FRAMES (default 200000), OBJ_BASE,
-- REPLAY (optional: drive a replay.lua script instead of a -playback .inp).
-- POKES  (optional: replay.lua-grammar scheduled writes; e.g. meter bank).
local out_path = os.getenv("CHECKSUM_OUT") or "inp_probe.log"
local max_frames = tonumber(os.getenv("MAX_FRAMES") or "") or 200000
local obj_base = tonumber(os.getenv("OBJ_BASE") or "708000", 16)
local snap, dump = {}, {}
for tok in (os.getenv("SNAP_FRAMES") or ""):gmatch("[^,%s]+") do snap[tonumber(tok)] = true end
for tok in (os.getenv("DUMP_FRAMES") or ""):gmatch("[^,%s]+") do dump[tonumber(tok)] = true end

local machine = manager.machine
local space = machine.devices[":maincpu"].spaces["program"]
local screen = assert(machine.screens[":screen"], "no :screen device")
local f = assert(io.open(out_path, "wb"))
local FNV_PRIME = 0x100000001b3
local function fnv1a64(s)
    local h = 0xcbf29ce484222325
    local n = #s - (#s % 8)
    for i = 1, n, 8 do h = (h ~ string.unpack("<i8", s, i)) * FNV_PRIME end
    for i = n + 1, #s do h = (h ~ s:byte(i)) * FNV_PRIME end
    return h
end
local function s16(a) local v = space:read_u16(a); if v >= 0x8000 then v = v - 0x10000 end; return v end
local function walk(base, emit, frame, bi)
    local n = 0
    for i = 0, 0x3FF do
        local off = base + i * 8
        local y = space:read_u16(off + 2)
        if (y & 0x8000) ~= 0 then break end
        local attr = space:read_u16(off + 6)
        if attr >= 0xFF00 then break end
        n = n + 1
        if emit then
            local x, code = space:read_u16(off), space:read_u16(off + 4)
            local a18 = code | ((y & 0x6000) << 3)
            local a19 = a18 | (((y & 0x1000) ~= 0) and 0x40000 or 0)
            f:write(string.format("F%d B%d E%03d x=%04x y=%04x code=%04x attr=%04x pal=%02x sz=%dx%d a18=%05x a19=%05x\n",
                frame, bi, i, x, y, code, attr, attr & 0x1F, ((attr >> 8) & 15) + 1, ((attr >> 12) & 15) + 1, a18, a19))
        end
    end
    return n
end
-- Optional REPLAY= driving (replay.lua grammar, canonical staging: parse
-- held[fr], stage held[frame+1]) — so the SAME probe runs on a vanilla replay.
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
local in_ports = { machine.ioport.ports[":IN0"], machine.ioport.ports[":IN1"], machine.ioport.ports[":IN2"] }
local pokes = {}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
end
local frame, snaps = 0, 0
emu.register_frame_done(function()
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do space:write_u8(a, tonumber(b, 16)); a = a + 1 end
        end
    end
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame + 1] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end
    local d = dump[frame]
    local n0 = walk(obj_base, d, frame, 0)
    local n1 = walk(obj_base + 0x8000, d, frame, 1)
    f:write(string.format("V %d %016x hp1=%d w1=%d d1=%02x hp2=%d w2=%d d2=%02x rd=%d t=%02x c1=%03x c2=%03x obj=%d/%d in=%04x,%04x,%04x\n",
        frame, fnv1a64(screen:pixels()),
        s16(0xFF8450), s16(0xFF8452), space:read_u8(0xFF851F),
        s16(0xFF8850), s16(0xFF8852), space:read_u8(0xFF891F),
        space:read_u8(0xFF810E), space:read_u8(0xFF8109),
        space:read_u16(0xFF8782), space:read_u16(0xFF8B82), n0, n1,
        in_ports[1]:read(), in_ports[2]:read(), in_ports[3]:read()))
    if snap[frame] then machine.video:snapshot(); f:write(string.format("SNAP %d %04d\n", frame, snaps)); snaps = snaps + 1 end
    if frame >= max_frames then f:write(string.format("END %d\n", frame)); f:close(); machine:exit() end
end)
