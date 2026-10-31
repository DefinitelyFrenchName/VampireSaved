-- pal_hash.lua (14z-215 scratch, #118 +0x3A8): per frame, HASHES ONLY (FNV-1a 32 over bytes; never a byte logged).
--   P<s> = fighter +0x3A8.l, S<s> = +0x3A4.l, K<s> = +0x3E1, E<s> = +0x3AE, R<s> = +0x18B, C<s> = +0x382, D = $FF80D0.l
--   hp<s>/hq<s> = hash of 32/128 bytes at [+0x3A8] (only when it lies in 0x900000-0x92FFFF, else -)
--   hs<s>/hsq<s> = hash of 32/128 bytes at [+0x3A4] with every word OR 0xF000 (the uploader's brightness OR), hr<s> raw 32 bytes
--   ha/hb = hash of 32 bytes at the fixed 0x90C140 / 0x90C200
--   n<s> = latched OBJ entries (m_cps2_buffered_obj) whose palette (attr & 0x1F) == R<s>; m<s> those == R<s>+1..+3; nt = all
-- POKE_AT=<f>: at frame f write a 32-byte known pattern (i*7+0x11 & 0xFF, not ROM data) at 0x90C140, read it back in the
--   same callback (line PK <f> want=<h> got=<h>) and log the next frames' read normally (the game may rewrite it).
-- Input staging as tests/lua/field_trace.lua (held[frame+1]).
local machine = manager.machine
local mem = machine.devices[":maincpu"].spaces["program"]
local out = assert(io.open(os.getenv("TRACE_OUT") or "pal_hash.txt", "wb"))
local max_frames = tonumber(os.getenv("FRAMES") or "") or 5200
local poke_at = tonumber(os.getenv("POKE_AT") or "") or -1
local from = tonumber(os.getenv("FROM") or "") or 0
local held = {}
do
    local ioport = machine.ioport
    local function fld(port, name) return ioport.ports[port].fields[name] end
    local IO = {
        p1 = { U = fld(":IN0", "P1 Up"), D = fld(":IN0", "P1 Down"), L = fld(":IN0", "P1 Left"), R = fld(":IN0", "P1 Right"),
               ["1"] = fld(":IN0", "P1 Button 1"), ["2"] = fld(":IN0", "P1 Button 2"), ["3"] = fld(":IN0", "P1 Button 3"),
               ["4"] = fld(":IN1", "P1 Button 4"), ["5"] = fld(":IN1", "P1 Button 5"), ["6"] = fld(":IN1", "P1 Button 6") },
        p2 = { U = fld(":IN0", "P2 Up"), D = fld(":IN0", "P2 Down"), L = fld(":IN0", "P2 Left"), R = fld(":IN0", "P2 Right"),
               ["1"] = fld(":IN0", "P2 Button 1"), ["2"] = fld(":IN0", "P2 Button 2"), ["3"] = fld(":IN0", "P2 Button 3"),
               ["4"] = fld(":IN1", "P2 Button 4"), ["5"] = fld(":IN1", "P2 Button 5"), ["6"] = fld(":IN2", "P2 Button 6") },
        sys = { S1 = fld(":IN2", "1 Player Start"), S2 = fld(":IN2", "2 Players Start"), C1 = fld(":IN2", "Coin 1"),
                C2 = fld(":IN2", "Coin 2"), SV = fld(":IN2", "Service 1"), TS = fld(":IN2", "Service Mode") },
    }
    for line in io.lines(assert(os.getenv("REPLAY"))) do
        local body = line:gsub("#.*", "")
        local range, rest = body:match("^%s*(%S+)%s+(.-)%s*$")
        if range then
            local a, b = range:match("^(%d+)%-(%d+)$")
            if not a then a = range:match("^(%d+)$"); b = a end
            if a then
                for spec in rest:gmatch("%S+") do
                    local who, toks = spec:match("^(%a+%d?)=(%S+)$")
                    if who and IO[who] then
                        local st = (who == "sys") and 2 or 1
                        for i = 1, #toks, st do
                            local fo = IO[who][toks:sub(i, i + st - 1)]
                            if fo then for fr = tonumber(a), tonumber(b) do held[fr] = held[fr] or {}; held[fr][#held[fr] + 1] = fo end end
                        end
                    end
                end
            end
        end
    end
end
local function fnv(addr, len, orw)
    local h = 0x811C9DC5
    for i = 0, len - 1, 2 do
        local w = mem:read_u16(addr + i)
        if orw then w = w | 0xF000 end
        for _, b in ipairs({ (w >> 8) & 0xFF, w & 0xFF }) do h = ((h ~ b) * 0x01000193) & 0xFFFFFFFF end
    end
    return string.format("%08x", h)
end
local function fnv_bytes(t)
    local h = 0x811C9DC5
    for _, b in ipairs(t) do h = ((h ~ b) * 0x01000193) & 0xFFFFFFFF end
    return string.format("%08x", h)
end
local latched_idx = false
local function latched()
    if latched_idx == false then
        local ok, idx = pcall(function() return machine.devices[":"].items["0/m_cps2_buffered_obj"] end)
        latched_idx = ok and idx or nil
    end
    return latched_idx and emu.item(latched_idx) or nil
end
local function census(r1, r2)
    local it = latched()
    if not it or it.count < 4 then return -1, -1, -1, -1, -1 end
    local n1, m1, n2, m2, nt = 0, 0, 0, 0, 0
    for i = 0, it.count // 4 - 1 do
        local y, attr = it:read(i * 4 + 1), it:read(i * 4 + 3)
        if (y & 0x8000) ~= 0 or attr >= 0xFF00 then break end
        local p = attr & 0x1F
        nt = nt + 1
        if p == r1 then n1 = n1 + 1 elseif p > r1 and p <= r1 + 3 then m1 = m1 + 1 end
        if p == r2 then n2 = n2 + 1 elseif p > r2 and p <= r2 + 3 then m2 = m2 + 1 end
    end
    return n1, m1, n2, m2, nt
end
local frame, prev = 0, {}
-- WTAP=1: a PC-attributed WRITE tap on the two 32-byte rows 0x90C140 and 0x90C200 (counts only, never the data):
--   line W <frame> <pc> <row 140|200> <count>, flushed each frame; WTAPSUM <total> at the end (liveness)
local wcount, wtotal, wtaps, winst = {}, 0, {}, false
local cpu = machine.devices[":maincpu"]
local function winstall()
    if winst then return end
    winst = true
    for _, base in ipairs({ 0x90C140, 0x90C200 }) do
        wtaps[#wtaps + 1] = mem:install_write_tap(base, base + 31, "pw" .. base, function(offset, data, mask)
            local k = string.format("%06x %x", cpu.state["CURPC"].value & 0xFFFFFF, base & 0xFFF)
            wcount[k] = (wcount[k] or 0) + 1; wtotal = wtotal + 1
        end)
    end
    winst = false
end
if os.getenv("WTAP") == "1" then
    winstall()
    do local r = debug.getregistry(); r.vs_notifier_threads = r.vs_notifier_threads or {}; r.vs_notifier_threads[#r.vs_notifier_threads + 1] = coroutine.running() end
    mem:add_change_notifier(function()
        if winst then return end
        for _, t in ipairs(wtaps) do t:remove() end
        wtaps = {}; winstall()
    end)
end
local SIDE = { 0xFF8400, 0xFF8800 }
emu.register_frame_done(function()
    frame = frame + 1
    if frame == poke_at then
        local pat = {}
        for i = 0, 31 do pat[#pat + 1] = (i * 7 + 0x11) & 0xFF end
        for i = 1, 32 do mem:write_u8(0x90C140 + i - 1, pat[i]) end
        local got = {}
        for i = 0, 31 do got[#got + 1] = mem:read_u8(0x90C140 + i) end
        out:write(string.format("PK %d want=%s got=%s\n", frame, fnv_bytes(pat), fnv_bytes(got)))
    end
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame + 1] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end
    for k, v in pairs(wcount) do out:write(string.format("W %d %s %d\n", frame, k, v)) end
    wcount = {}
    if frame >= from then
        local parts = { string.format("F %d D=%08x", frame, mem:read_u32(0xFF80D0)) }
        local r = {}
        for s, b in ipairs(SIDE) do
            local p, src = mem:read_u32(b + 0x3A8), mem:read_u32(b + 0x3A4)
            r[s] = mem:read_u8(b + 0x18B)
            local hp, hq = "-", "-"
            if p >= 0x900000 and p + 128 <= 0x930000 then hp, hq = fnv(p, 32), fnv(p, 128) end
            local hs, hsq, hr = "-", "-", "-"
            if src > 0 and src + 128 <= 0x400000 then hs, hsq, hr = fnv(src, 32, true), fnv(src, 128, true), fnv(src, 32) end
            parts[#parts + 1] = string.format("C%d=%02x K%d=%02x E%d=%02x R%d=%02x P%d=%08x S%d=%08x hp%d=%s hq%d=%s hs%d=%s hsq%d=%s hr%d=%s",
                s, mem:read_u8(b + 0x382), s, mem:read_u8(b + 0x3E1), s, mem:read_u8(b + 0x3AE), s, r[s], s, p, s, src,
                s, hp, s, hq, s, hs, s, hsq, s, hr)
        end
        if os.getenv("ALT") == "1" then
            -- ALT=1: which row j of the side's 0x500-byte block (base = +0x3A4 - (+0x3AE)*128, 40 rows of 32) equals
            -- the 32 bytes at [+0x3A8] (words OR 0xF000)? j or -1 (the block layout: docs/game/engine_internals.md
            -- "Sprite palette pipeline")
            for s2, b in ipairs(SIDE) do
                local p, src, e = mem:read_u32(b + 0x3A8), mem:read_u32(b + 0x3A4), mem:read_u8(b + 0x3AE)
                local j = -1
                if p >= 0x900000 and p + 32 <= 0x930000 and src > 0x1000 then
                    local hp = fnv(p, 32); local base = src - e * 128
                    for k = 0, 39 do if fnv(base + k * 32, 32, true) == hp then j = k; break end end
                end
                parts[#parts + 1] = string.format("j%d=%d", s2, j)
            end
        end
        local n1, m1, n2, m2, nt = census(r[1], r[2])
        parts[#parts + 1] = string.format("ha=%s hb=%s n1=%d m1=%d n2=%d m2=%d nt=%d", fnv(0x90C140, 32), fnv(0x90C200, 32), n1, m1, n2, m2, nt)
        out:write(table.concat(parts, " ") .. "\n")
    end
    if frame >= max_frames then
        out:write(string.format("WTAPSUM %d\nPALSUMMARY frames=%d\n", wtotal, frame)); out:close(); machine:exit()
    end
end)
