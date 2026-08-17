-- scratch probe v2: replay-driven venue + id sweep pokes + QSound chip
-- write log. env: REPLAY, SWEEP="s,e,step,first"(hex,hex,dec,dec) or
-- IDLIST (csv hex), RING_IDX, TRACE_OUT
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
local sw = os.getenv("SWEEP") or "0,10,12,1050"
local s_id, e_id, stepf, firstf = sw:match("^(%x+),(%x+),(%d+),(%d+)$")
s_id, e_id, stepf, firstf = tonumber(s_id,16), tonumber(e_id,16), tonumber(stepf), tonumber(firstf)
local ids = {}
local idlist = os.getenv("IDLIST")
if idlist then for tok in idlist:gmatch("[^,]+") do ids[#ids+1]=tonumber(tok,16) end
else for i=s_id,e_id do ids[#ids+1]=i end end
-- STEP overrides the injection spacing (IDLIST mode kept SWEEP's default
-- 12 frames, which is attack-window-blind — the 14z-85/86 lesson)
stepf = tonumber(os.getenv("STEP") or "") or stepf
local ring_idx = tonumber(os.getenv("RING_IDX") or "70", 16)
local out_path = os.getenv("TRACE_OUT") or "qs_sweep.txt"

local machine = manager.machine
local m68k = machine.devices[":maincpu"].spaces["program"]
local z80  = machine.devices[":audiocpu"]
local zsp  = z80.spaces["program"]

-- replay input playback (same subset as replay.lua/tap_writes.lua)
local held = {}
local replay_path = os.getenv("REPLAY")
if replay_path then
    local ioport = machine.ioport
    local function fld(port,name) return ioport.ports[port].fields[name] end
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
        local body = line:gsub("#.*","")
        local range, rest = body:match("^%s*(%S+)%s+(.-)%s*$")
        if range then
            local a,b = range:match("^(%d+)%-(%d+)$")
            if not a then a = range:match("^(%d+)$"); b=a end
            if a then
                for spec in rest:gmatch("%S+") do
                    local who,toks = spec:match("^(%a+%d?)=(%S+)$")
                    if who and FIELDS[who] then
                        local step = (who=="sys") and 2 or 1
                        for i=1,#toks,step do
                            local fo = FIELDS[who][toks:sub(i,i+step-1)]
                            if fo then
                                for fr=tonumber(a),tonumber(b) do
                                    held[fr]=held[fr] or {}; held[fr][#held[fr]+1]=fo
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

local tap
local function install()
    tap = zsp:install_write_tap(0xd000, 0xd002, "qsw", function(offset, data, mask)
        f:write(string.format("f%d w %04x %02x\n", frame, offset, data & 0xff))
    end)
end
install()
zsp:add_change_notifier(function() if tap then install() end end)

emu.register_frame_done(function()
    frame = frame + 1
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame + 1] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end
    if frame >= firstf and (frame - firstf) % stepf == 0 then
        n = n + 1
        if n > #ids then f:write("END\n"); f:close(); manager.machine:exit(); return end
        local id = ids[n]
        local base = 0xFF0E0E + idx
        m68k:write_u32(base, id)
        m68k:write_u32(base+4, 0)
        m68k:write_u32(base+8, 0)
        idx = (idx + 0x10) & 0xFF0
        m68k:write_u16(0xFF1E0E, idx)
        f:write(string.format("== f%d id %04x ==\n", frame, id))
    end
end)
