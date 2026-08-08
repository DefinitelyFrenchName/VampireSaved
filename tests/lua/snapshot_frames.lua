-- snapshot_frames.lua — play a replay and save PNG snapshots at named frames.
--
-- WHY: every RAM gate is structurally blind to rendering, and the WIDE
-- sprite-garble bug (14z-60y) was found by a human looking at the screen
-- because nothing else could see it. MAME renders its bitmap internally
-- even under `-video none` + SDL_VIDEODRIVER=dummy (the same reason
-- replay.lua's VIDEO_OUT works), so `manager.machine.video:snapshot()`
-- produces a real frame headlessly. This turns "look at it" into a
-- scripted, rerunnable measurement.
--
-- The snapshot is written to MAME's snapshot directory, which
-- tools/run_mame.sh points at <sandbox>/snap/<set>/NNNN.png. Numbering is
-- MAME's own (0000, 0001, ...) in the order taken, so SNAP_FRAMES order
-- IS the file order; the mapping is also written to TRACE_OUT.
--
--   env REPLAY       input script (replay.lua format)
--   env SNAP_FRAMES  comma-separated frame numbers to capture
--   env TRACE_OUT    index log path (default snapshot_frames.txt)
--   env FRAMES       hard stop (default max(SNAP_FRAMES))
--   env POKES        "frame:addr:hexbytes;..." scheduled RAM writes
--                    (same grammar as replay.lua — added 14z-68 so the
--                    forced-pick rigs can be photographed)
--
-- Ends with a SNAPSUMMARY line for scripted assertion.

local out_path = os.getenv("TRACE_OUT") or "snapshot_frames.txt"
local want = {}
local want_list = {}
for tok in (os.getenv("SNAP_FRAMES") or ""):gmatch("[^,%s]+") do
    local n = tonumber(tok)
    if n then want[n] = true; want_list[#want_list + 1] = n end
end
assert(#want_list > 0, "SNAP_FRAMES must name at least one frame")
table.sort(want_list)
local max_frames = tonumber(os.getenv("FRAMES") or "") or want_list[#want_list]

local machine = manager.machine
local f = assert(io.open(out_path, "wb"))

-- input playback (same subset as objy_bits.lua / replay.lua)
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
local taken = 0
local prev = {}

-- POKES (14z-68): same grammar and application point as replay.lua
local cpu = machine.devices[":maincpu"]
local program = cpu.spaces["program"]
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
        machine.video:snapshot()
        f:write(string.format("SNAP %04d frame %d\n", taken, frame))
        taken = taken + 1
    end

    if frame >= max_frames then
        f:write(string.format("SNAPSUMMARY frames=%d taken=%d wanted=%d\n",
            frame, taken, #want_list))
        f:close()
        machine:exit()
    end
end)
