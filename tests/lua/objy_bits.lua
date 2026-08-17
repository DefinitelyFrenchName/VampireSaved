-- objy_bits.lua — OBJ y-word bit census (CPS-2 WIDE Phase A / A2).
--
-- WHY: the sprite tile address is composed in the emulator as
--   n = code | (y_word & 0x6000) << 3          (18 bits, 32MB ceiling)
-- and the WIDE profile needs a 19th bit so tiles can live in a third gfx
-- group. MEASURED CORRECTION (Phase A): y-word bit 15 is NOT available —
-- it is the CPS-2 sprite-list TERMINATOR (FBNeo CpsObjGet breaks on it).
-- CPS-2 Turbo solves this by promoting y-word BIT 12 into the address:
--   if (y & 0x1000) y |= 0x8000;  n |= (y & 0xE000) << 3;
-- so bit 12 is the candidate, with Capcom's own hardware as precedent.
-- This audit therefore asks: does vanilla ever set y-word bit 12 on a
-- LIVE (pre-terminator) sprite? If not, the 19th bit is free.
--
-- This scans OBJ RAM every frame and accumulates, over the whole run:
--   * the OR of every y-word of every LIVE entry (which bits ever set),
--   * a histogram of the bank field (bits 13-14),
--   * the max tile code and the max composed address under both the
--     18-bit and the proposed 19-bit rule.
--
--   env REPLAY     input script (same format as replay.lua)
--   env TRACE_OUT  report path (default objy_bits.txt)
--   env FRAMES     stop after N frames (default 3600)
--   env OBJ_BASE   OBJ RAM base (default 708000) and OBJ_LEN (default 2000)
--
-- Report ends with a single OBJYSUMMARY line for scripted assertion.
-- INPUT STAGING IS CANONICAL (GitHub #10, unified 14z-94). This instrument
-- follows tests/lua/replay.lua exactly: parse `held[fr]`, stage for the NEXT
-- frame (`held[frame + 1]`). So a frame number in this log IS a replay.lua
-- frame number and CAN be cross-referenced with a compare_* first divergence,
-- a masked window onset or a checksum log.
--
-- It was one of the ten `+1` deviants until 14z-94. The split is now pinned
-- at ZERO by tests/test_replay_stage_census.sh, which fails any new
-- instrument that copies the old flavour — that is how the drift spread:
-- one variant, then every later file copying the copy.

local out_path = os.getenv("TRACE_OUT") or "objy_bits.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600
local obj_base = tonumber(os.getenv("OBJ_BASE") or "708000", 16)
local obj_len = tonumber(os.getenv("OBJ_LEN") or "2000", 16)

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local space = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))

-- input playback (same subset the other instruments use)
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

local frame = 0
local y_or = 0            -- OR of every live entry's y-word
local bank_hist = {}      -- (y >> 13) & 7  ->  count
local max_code = 0
local max_addr18 = 0
local max_addr19 = 0
local bit12_hits = {}
local entries_seen = 0
local prev = {}

emu.register_frame_done(function()
    frame = frame + 1
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame + 1] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end

    -- Walk the LIVE sprite list exactly as the hardware does. Critical:
    -- y-word bit 15 TERMINATES the list (FBNeo CpsObjGet: `if (ps[1] &
    -- 0x8000) break;`), and attr >= 0xFF00 also terminates. Scanning raw
    -- OBJ RAM instead counts stale entries past the terminator and reports
    -- bits that are never actually presented to the draw path.
    -- CPS-2 keeps two buffers 0x8000 apart, up to 0x400 entries each.
    for _, base in ipairs({ obj_base, obj_base + 0x8000 }) do
        for i = 0, 0x3FF do
            local off = base + i * 8
            local y = space:read_u16(off + 2)
            if (y & 0x8000) ~= 0 then break end
            local attr = space:read_u16(off + 6)
            if attr >= 0xFF00 then break end
            local code = space:read_u16(off + 4)
            entries_seen = entries_seen + 1
            y_or = y_or | y
            local bank = (y >> 13) & 7
            bank_hist[bank] = (bank_hist[bank] or 0) + 1
            if code > max_code then max_code = code end
            local a18 = code | ((y & 0x6000) << 3)
            -- the proposed 19th bit, CPS-2 Turbo style: bit 12 promoted
            local a19 = a18 | (((y & 0x1000) ~= 0) and 0x40000 or 0)
            if a18 > max_addr18 then max_addr18 = a18 end
            if a19 > max_addr19 then max_addr19 = a19 end
            if (y & 0x1000) ~= 0 and #bit12_hits < 40 then
                bit12_hits[#bit12_hits + 1] =
                    string.format("f%d off%06x code %04x y %04x", frame, off, code, y)
            end
        end
    end

    if frame >= max_frames then
        for _, l in ipairs(bit12_hits) do f:write("BIT12 " .. l .. "\n") end
        local banks = {}
        for b = 0, 7 do banks[#banks + 1] = string.format("%d:%d", b, bank_hist[b] or 0) end
        f:write(string.format(
            "OBJYSUMMARY frames=%d entries=%d y_or=%04x bit12=%d maxcode=%04x max18=%05x max19=%05x banks=%s\n",
            frame, entries_seen, y_or, (y_or & 0x1000) ~= 0 and 1 or 0,
            max_code, max_addr18, max_addr19, table.concat(banks, ",")))
        f:close()
        manager.machine:exit()
    end
end)
