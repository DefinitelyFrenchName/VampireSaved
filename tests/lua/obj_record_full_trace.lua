-- obj_record_full_trace.lua — log EVERY OBJ record draw (all six format
-- handlers) in a frame window: record addr, format, object, bank, and
-- the record's first entry tile words. Companion to
-- obj_record_bank_trace.lua for "which record draws code X?" questions
-- (session 14o blink diagnosis).
--
-- Handlers (jump table 0x1AFBA, word offsets; decoded from the opcode
-- dump): fmt0 0x1AFC6, fmt2 0x1B234, fmt4 0x1B61A, fmt6 0x1B6AA,
-- fmt8 0x1B73E, fmtA 0x1B7CC. Dispatch is `movea.l 4(a0),a0;
-- move.w (a0)+,d0` — at every handler A0 = record+2.
--
--   env REPLAY      input script
--   env TRACE_OUT   log path (default obj_record_full.txt)
--   env WIN_LO/WIN_HI  frame window to log (default 2590/2615)
--   env FRAMES      hard stop (default WIN_HI+5)
--   env HANDLERS    override handler map "fmt:hexpc,..." (default the
--                   vsavj addresses; vsav2 sibling:
--                   "0:199f6,2:19c64,4:1a04a,6:1a0da,8:1a16e,10:1a236")

local out_path = os.getenv("TRACE_OUT") or "obj_record_full.txt"
local win_lo = tonumber(os.getenv("WIN_LO") or "") or 2590
local win_hi = tonumber(os.getenv("WIN_HI") or "") or 2615
local max_frames = tonumber(os.getenv("FRAMES") or "") or (win_hi + 5)

local machine = manager.machine
local debugger = machine.debugger
assert(debugger, "run mame with -debug")
local cpu = machine.devices[":maincpu"]
local prog = cpu.spaces["program"]

local f = assert(io.open(out_path, "wb"))
local frame = 0

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

debugger:command("focus 0")
local HANDLERS = { [0x1afc6]=0, [0x1b234]=2, [0x1b61a]=4,
                   [0x1b6aa]=6, [0x1b73e]=8, [0x1b7cc]=10 }
local hspec = os.getenv("HANDLERS")
if hspec then
    HANDLERS = {}
    for fmt, pc in hspec:gmatch("(%d+):(%x+)") do
        HANDLERS[tonumber(pc, 16)] = tonumber(fmt)
    end
end
for pc in pairs(HANDLERS) do
    debugger:command(string.format("bpset %x", pc))
end

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
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
        f:write(string.format("END %d\n", frame))
        f:close()
        manager.machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger.execution_state == "stop" then
        if frame >= win_lo and frame <= win_hi then
            local st = cpu.state
            local a0 = st["A0"].value & 0xffffff
            local a6 = st["A6"].value & 0xffffff
            local pc = st["CURPC"].value & 0xffffff
            local fmt = HANDLERS[pc] or -1
            local rec = a0 - 2
            local bank = prog:read_u16(a6 + 0x18)
            -- entry tile words per format layout (rec base offsets)
            local tiles = {}
            if fmt == 0 then
                local cnt = prog:read_u16(rec + 2)
                for k = 0, math.min(cnt - 1, 11) do
                    tiles[#tiles + 1] = string.format("%04x",
                        prog:read_u16(rec + 10 + 2 * k))
                end
            elseif fmt >= 2 then
                local cnt = prog:read_u16(rec + 4)
                for k = 0, math.min(cnt, 11) do
                    tiles[#tiles + 1] = string.format("%04x",
                        prog:read_u16(rec + 10 + 4 * k))
                end
            end
            local cur = prog:read_u32(a6 + 0x1c) & 0xffffff
            local ctx = {}
            for k = -2, 3 do
                ctx[#ctx + 1] = string.format("%08x",
                    prog:read_u32(cur + 4 * k))
            end
            f:write(string.format(
                "F %d REC %06x FMT %d OBJ %06x BANK %04x CUR %06x CTX %s T %s\n",
                frame, rec, fmt, a6, bank, cur, table.concat(ctx, ","),
                table.concat(tiles, ",")))
        end
        debugger.execution_state = "run"
    end
end)
