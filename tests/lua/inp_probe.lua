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
-- PAL_ROWS also auto-logs whenever the #112 foot (pal 05, tile 0x0e7xx) is
-- on screen, so one whole-recording pass captures every Press of Death.
-- PAL_ROWS/PAL_BASE (optional: at DUMP_FRAMES/on foot, log palette rows 'NN,NN' from
--   PAL_BASE (default 90c000, row=base+idx*0x20) as 16 u16 colours + a
--   'dark=' luma sum, for the #112 white-vs-black foot diff).
local out_path = os.getenv("CHECKSUM_OUT") or "inp_probe.log"
local max_frames = tonumber(os.getenv("MAX_FRAMES") or "") or 200000
local obj_base = tonumber(os.getenv("OBJ_BASE") or "708000", 16)
local snap, dump = {}, {}
local pal_base = tonumber(os.getenv("PAL_BASE") or "90c000", 16)
local pal_rows = {}
for tok in (os.getenv("PAL_ROWS") or ""):gmatch("[^,%s]+") do pal_rows[#pal_rows+1] = tonumber(tok, 16) end
local pal_every = os.getenv("PAL_EVERY") ~= nil
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
-- RECT_AUDIT (14z-112, GitHub #112): accumulate every DISTINCT multi-tile OBJ
-- block whose tile code falls in the tenant placement window, over the whole
-- run, and emit them at END as "BLK <code> <w> <h> <attr> <seen>". Feeds
-- tools/audit_effect_rects.py, which checks each block's destination
-- rectangle against the donor's own rectangle (the shelf-pack defect).
local rect_audit = os.getenv("RECT_AUDIT") ~= nil
local rect_lo = tonumber(os.getenv("RECT_LO") or "ad80", 16)
local rect_hi = tonumber(os.getenv("RECT_HI") or "eebb", 16)
local blocks = {}
local foot_seen = false
local function walk(base, emit, frame, bi)
    local n = 0
    for i = 0, 0x3FF do
        local off = base + i * 8
        local y = space:read_u16(off + 2)
        if (y & 0x8000) ~= 0 then break end
        local attr = space:read_u16(off + 6)
        if attr >= 0xFF00 then break end
        n = n + 1
        do
            local code = space:read_u16(off + 4)
            local a18 = code | ((y & 0x6000) << 3)
            if (attr & 0x1F) == 0x05 and a18 >= 0x0e700 and a18 <= 0x0e7ff then foot_seen = true end
            if rect_audit and code >= rect_lo and code <= rect_hi then
                local w = ((attr >> 8) & 15) + 1
                local h = ((attr >> 12) & 15) + 1
                if w * h > 1 then
                    local k = string.format("%04x %d %d %04x", code, w, h, attr)
                    if not blocks[k] then
                        blocks[k] = true
                        f:write(string.format("BLK %s %d\n", k, frame))
                    end
                end
            end
        end
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
-- WRITETAP (14z-112): "lo-hi" program-space range + WRITETAP_FRAMES "a-b".
-- Logs each distinct (PC, address) WRITE in the window as
-- "W <frame> PC <pc> <addr> <data>". Write taps DO fire on this driver
-- (read taps never do — docs/platform/gotchas.md), so this is the way to
-- attribute an OBJ record to the code that emitted it.
-- THE TAP MUST BE RE-INSTALLED ON EVERY MEMORY-MAP CHANGE (inp_guard.lua's
-- pattern): a tap installed once at autoboot is silently dropped when the
-- space is rebuilt, and then reports zero writes forever — measured 14z-112,
-- the control found nothing until this notifier was added.
local wt = os.getenv("WRITETAP")
local wtaps = {}
if wt then
    local lo, hi = wt:match("^(%x+)-(%x+)$")
    lo, hi = tonumber(lo, 16), tonumber(hi, 16)
    local wa, wb = (os.getenv("WRITETAP_FRAMES") or "0-999999"):match("^(%d+)-(%d+)$")
    wa, wb = tonumber(wa), tonumber(wb)
    local wseen = {}
    local function on_w(offset, data, mask)
        if frame >= wa and frame <= wb then
            local ok, pc = pcall(function()
                return machine.devices[":maincpu"].state["CURPC"].value & 0xFFFFFF end)
            -- dedup on (pc, addr, DATA): keying on (pc, addr) alone hides
            -- every later write to the same slot, which is exactly the one
            -- that decides what is drawn (measured 14z-112).
            local k = string.format("%06x@%06x=%04x", ok and pc or 0, offset, data & 0xFFFF)
            if not wseen[k] then
                wseen[k] = true
                f:write(string.format("W %d PC %06x %06x %04x\n",
                    frame, ok and pc or 0, offset, data & 0xFFFF))
            end
        end
        return data
    end
    local function install_w()
        wtaps[#wtaps + 1] = space:install_write_tap(lo, hi, "inp_writetap", on_w)
    end
    install_w()
    space:add_change_notifier(function()
        for _, t in ipairs(wtaps) do t:remove() end
        wtaps = {}
        install_w()
    end)
end

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
    foot_seen = false
    local d = dump[frame]
    local n0 = walk(obj_base, d, frame, 0)
    local n1 = walk(obj_base + 0x8000, d, frame, 1)
    f:write(string.format("V %d %016x hp1=%d w1=%d d1=%02x hp2=%d w2=%d d2=%02x rd=%d t=%02x c1=%03x c2=%03x obj=%d/%d foot=%d in=%04x,%04x,%04x\n",
        frame, fnv1a64(screen:pixels()),
        s16(0xFF8450), s16(0xFF8452), space:read_u8(0xFF851F),
        s16(0xFF8850), s16(0xFF8852), space:read_u8(0xFF891F),
        space:read_u8(0xFF810E), space:read_u8(0xFF8109),
        space:read_u16(0xFF8782), space:read_u16(0xFF8B82), n0, n1, foot_seen and 1 or 0,
        in_ports[1]:read(), in_ports[2]:read(), in_ports[3]:read()))
    if (d or pal_every or foot_seen) and #pal_rows > 0 then
        for _, r in ipairs(pal_rows) do
            local o = pal_base + r * 0x20
            local cols, dark = {}, 0
            for i = 0, 15 do
                local c = space:read_u16(o + i*2); cols[#cols+1] = string.format("%04x", c)
                local R=(c>>8)&0xf; local G=(c>>4)&0xf; local B=c&0xf
                dark = dark + R + G + B  -- CPS2 0xF_RGB; sum over the 16 colours = row brightness
            end
            f:write(string.format("P F%d row=%02x dark=%d %s\n", frame, r, dark, table.concat(cols, " ")))
        end
    end
    if d and os.getenv("CPSREGS") then
        local w = {}
        for a = 0x800100, 0x80013F, 2 do w[#w+1] = string.format("%04x", space:read_u16(a)) end
        f:write(string.format("R F%d 800100: %s\n", frame, table.concat(w, " ")))
    end
    if d and (os.getenv("GFXTILES") or os.getenv("GFXRANGE")) then
        local rg = machine.memory.regions[":gfx"]
        if rg then
            local list = {}
            local rspec = os.getenv("GFXRANGE")          -- "startHex:count" content-scan
            if rspec then
                local st, n = rspec:match("^(%x+):(%d+)$")
                for i = 0, tonumber(n) - 1 do list[#list+1] = tonumber(st, 16) + i end
            else
                for tok in os.getenv("GFXTILES"):gmatch("[^,%s]+") do list[#list+1] = tonumber(tok, 16) end
            end
            for _, t in ipairs(list) do
                local base, nz, sum = t * 0x80, 0, 0
                for i = 0, 0x7F do
                    local b = rg:read_u8(base + i)
                    if b ~= 0 then nz = nz + 1 end
                    sum = (sum * 33 + b) & 0xFFFFFFFF
                end
                local hex = {}
                if os.getenv("GFXHEX") then
                    for i = 0, 0x7F do hex[#hex+1] = string.format("%02x", rg:read_u8(base + i)) end
                end
                f:write(string.format("G F%d tile=%05x nonzero=%d/128 hash=%08x %s\n", frame, t, nz, sum, table.concat(hex)))
            end
        else
            f:write("G no :gfx region\n")
        end
    end
    if d and os.getenv("FINDBYTES") then
        -- scan work RAM for a byte pattern (hex), print every hit. Used to
        -- locate where an OBJ record is STAGED before it reaches OBJ RAM:
        -- write taps DO fire on work RAM, so a hit here is tappable (whereas
        -- read taps never fire at all on this driver — platform gotcha).
        local hex = os.getenv("FINDBYTES")
        local want = {}
        for b in hex:gmatch("%x%x") do want[#want+1] = tonumber(b, 16) end
        local lo = tonumber(os.getenv("FIND_LO") or "ff0000", 16)
        local hi = tonumber(os.getenv("FIND_HI") or "ffffff", 16)
        local hits = 0
        for a = lo, hi - #want do
            local ok = true
            for k = 1, #want do
                if space:read_u8(a + k - 1) ~= want[k] then ok = false; break end
            end
            if ok then
                hits = hits + 1
                f:write(string.format("FIND F%d %06x\n", frame, a))
                if hits >= 32 then break end
            end
        end
        f:write(string.format("FINDSUMMARY F%d pattern=%s hits=%d\n", frame, hex, hits))
    end
    if snap[frame] then machine.video:snapshot(); f:write(string.format("SNAP %d %04d\n", frame, snaps)); snaps = snaps + 1 end
    if frame >= max_frames then
        f:write(string.format("END %d\n", frame)); f:close(); machine:exit()
    end
end)
