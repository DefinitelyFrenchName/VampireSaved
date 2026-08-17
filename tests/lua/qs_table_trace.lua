-- qs_table_trace.lua — WHO reads the Z80 sample table (and any other
-- traced spans) while an id plays? Read tap over data-only spans of the
-- Z80 fixed ROM: opcode fetches never land inside a data table, so every
-- hit is the interpreter, PC-attributed (RH-27: find the interpreter
-- before trusting the data). Drives ids exactly like qs_sweep.lua.
--
-- env: REPLAY, IDLIST (csv hex), STEP/FIRST (frames, default 12/1050),
--      SPANS "lo-hi[,lo-hi...]" (Z80 addresses, hex), RING_IDX,
--      TRACE_OUT, FRAMES
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
local ids = {}
for tok in (os.getenv("IDLIST") or "119"):gmatch("[^,]+") do
    ids[#ids+1] = tonumber(tok, 16)
end
local stepf = tonumber(os.getenv("STEP") or "12")
local firstf = tonumber(os.getenv("FIRST") or "1050")
local ring_idx = tonumber(os.getenv("RING_IDX") or "70", 16)
local out_path = os.getenv("TRACE_OUT") or "qs_table_trace.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "3600")

local machine = manager.machine
local m68k = machine.devices[":maincpu"].spaces["program"]
local z80 = machine.devices[":audiocpu"]
local zsp = z80.spaces["program"]

local held = {}
local replay_path = os.getenv("REPLAY")
if replay_path then
    local ioport = machine.ioport
    local function fld(port, name) return ioport.ports[port].fields[name] end
    local FIELDS = {
        p1 = { U=fld(":IN0","P1 Up"),D=fld(":IN0","P1 Down"),L=fld(":IN0","P1 Left"),R=fld(":IN0","P1 Right"),
               ["1"]=fld(":IN0","P1 Button 1"),["2"]=fld(":IN0","P1 Button 2"),["3"]=fld(":IN0","P1 Button 3"),
               ["4"]=fld(":IN1","P1 Button 4"),["5"]=fld(":IN1","P1 Button 5"),["6"]=fld(":IN1","P1 Button 6") },
        p2 = { U=fld(":IN0","P2 Up"),D=fld(":IN0","P2 Down"),L=fld(":IN0","P2 Left"),R=fld(":IN0","P2 Right"),
               ["1"]=fld(":IN0","P2 Button 1"),["2"]=fld(":IN0","P2 Button 2"),["3"]=fld(":IN0","P2 Button 3"),
               ["4"]=fld(":IN1","P2 Button 4"),["5"]=fld(":IN1","P2 Button 5"),["6"]=fld(":IN2","P2 Button 6") },
        sys = { S1=fld(":IN2","1 Player Start"),S2=fld(":IN2","2 Players Start"),
                C1=fld(":IN2","Coin 1"),C2=fld(":IN2","Coin 2"),
                SV=fld(":IN2","Service 1"),TS=fld(":IN2","Service Mode") },
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
                            local fo = FIELDS[who][toks:sub(i, i+step-1)]
                            if fo then
                                for fr = tonumber(a), tonumber(b) do
                                    held[fr] = held[fr] or {}
                                    held[fr][#held[fr]+1] = fo
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local f = assert(io.open(out_path, "wb"))
local frame = 0
local idx = ring_idx
local n = 0
local prev = {}
local hits = 0

local spans = {}
for lo, hi in (os.getenv("SPANS") or "5219-5a21"):gmatch("(%x+)-(%x+)") do
    spans[#spans+1] = { tonumber(lo, 16), tonumber(hi, 16) }
end

local taps = {}
local installing = false
local function install()
    installing = true
    for i, sp in ipairs(spans) do
        taps[i] = zsp:install_read_tap(sp[1], sp[2], "qtt"..i,
            function(offset, data, mask)
                hits = hits + 1
                if hits <= 200000 then
                    local pc = z80.state["PC"].value
                    f:write(string.format("f%d r %04x pc %04x d %04x m %04x\n",
                                          frame, offset, pc, data, mask))
                end
            end)
    end
    installing = false
end
install()
zsp:add_change_notifier(function(mode)
    if not installing and mode:find("r") then install() end
end)

emu.register_frame_done(function()
    frame = frame + 1
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame + 1] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end
    if frame >= firstf and (frame - firstf) % stepf == 0 then
        n = n + 1
        if n > #ids then
            f:write(string.format("END hits %d\n", hits))
            f:close()
            manager.machine:exit()
            return
        end
        local id = ids[n]
        local base = 0xFF0E0E + idx
        m68k:write_u32(base, id)
        m68k:write_u32(base+4, 0)
        m68k:write_u32(base+8, 0)
        idx = (idx + 0x10) & 0xFF0
        m68k:write_u16(0xFF1E0E, idx)
        f:write(string.format("== f%d id %04x ==\n", frame, id))
    end
    if frame >= max_frames then
        f:write(string.format("END hits %d\n", hits))
        f:close()
        manager.machine:exit()
    end
end)
