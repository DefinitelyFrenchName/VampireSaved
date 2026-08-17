-- record_window.lua (14z-94) — record a MOVIE of a NAMED FRAME WINDOW, from
-- inside MAME, headlessly. The instrument for "let me actually watch what the
-- game did between frame A and frame B".
--
-- WHY IT EXISTS. Screen-capturing the emulator from the host is unreliable for
-- frame analysis: the recorder's frames are host frames, not emulated frames,
-- so they drift against every frame number the harness produces, and nothing
-- ties a captured frame to a replay frame. MAME renders its bitmap internally
-- even under `-video none` + SDL_VIDEODRIVER=dummy (the same reason
-- snapshot_frames.lua and replay.lua's VIDEO_OUT work), so recording from the
-- Lua side captures the EMULATED sequence: window frame k IS replay frame
-- START+k, by construction, and the file is reproducible run to run.
--
-- WHY A WINDOW AND NOT `-aviwrite`. `-aviwrite` works headless — measured —
-- but writes UNCOMPRESSED video for the whole run: **5.7 GB in two minutes of
-- wall time** at this resolution (measured 14z-94, and it will happily fill a
-- disk on a long rig). This records only the frames asked for. Prefer
-- `REC_FORMAT=mng`, which is losslessly compressed; `avi` is there for tools
-- that will not read MNG.
--
-- GROUND TRUTH BEFORE EVIDENCE. A recorder that silently drops or duplicates
-- frames is worse than no recorder, because its output still looks like a
-- video. This script writes a RECSUMMARY line carrying the window it actually
-- recorded; tests/test_record_window.sh checks that against replay.lua's
-- VIDEO_OUT checksum stream over the same frames — same run length, and the
-- frames VIDEO_OUT says changed must be the frames the movie shows changing.
-- Do not read a frame off the movie until that gate is green.
--
-- WHERE THE FILE LANDS. `begin_recording` puts the name through MAME's
-- snapshot-filename substitution, so a relative REC_OUT resolves against the
-- snapshot directory (tools/run_mame.sh points that at <sandbox>/snap). Pass
-- an ABSOLUTE path to put it where you want it. The RECSUMMARY line prints
-- what was requested either way — check it rather than guessing.
--
--   env REPLAY     input script (replay.lua format)
--   env REC_FROM   first frame to record (inclusive)
--   env REC_TO     last frame to record (inclusive)
--   env REC_OUT    movie path (default "window.mng"; see WHERE THE FILE LANDS)
--   env REC_FORMAT "mng" (default, compressed) | "avi" (uncompressed, large)
--   env FRAMES     hard stop (default REC_TO + 60, so the tail is flushed)
--   env TRACE_OUT  index log path (default record_window.txt)
--   env POKES      "frame:addr:hexbytes;..." scheduled writes (replay grammar)
--
-- INPUT STAGING IS CANONICAL (GitHub #10). This instrument follows
-- replay.lua exactly: parse `held[fr]`, stage for the NEXT frame at the END
-- of the callback. So a frame number here IS a replay.lua frame number, and
-- a window recorded from a compare_* first divergence or a masked window
-- onset lands where you asked for it.
--
-- It was written the other way first — copied from snapshot_frames.lua, one
-- of the ten `+1` deviants — and tests/test_replay_stage_census.sh caught it
-- as a NEW deviant on the same day. That gate's instruction is "fix the file,
-- do not extend the frozen list", and it is free to obey here: nothing
-- consumes this instrument's frame constants yet, so there is no
-- re-measurement to pay for (which is the whole reason #10 is deferred for
-- the existing ten).

local out_path = os.getenv("TRACE_OUT") or "record_window.txt"
local rec_from = tonumber(os.getenv("REC_FROM") or "")
local rec_to   = tonumber(os.getenv("REC_TO") or "")
assert(rec_from and rec_to, "set REC_FROM and REC_TO")
assert(rec_to >= rec_from, "REC_TO must not precede REC_FROM")
local rec_out    = os.getenv("REC_OUT") or "window.mng"
local rec_format = os.getenv("REC_FORMAT") or "mng"
local max_frames = tonumber(os.getenv("FRAMES") or "") or (rec_to + 60)

local machine = manager.machine
local f = assert(io.open(out_path, "wb"))

-- input playback (same subset as snapshot_frames.lua / replay.lua)
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
local prev = {}
local started, stopped = nil, nil

-- POKES: same grammar and application point as replay.lua / snapshot_frames.lua
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

    if frame == rec_from then
        machine.video:begin_recording(rec_out, rec_format)
        started = frame
        f:write(string.format("RECSTART frame %d out %s format %s\n",
            frame, rec_out, rec_format))
    end
    if frame == rec_to + 1 and started and not stopped then
        machine.video:end_recording()
        stopped = frame - 1
        f:write(string.format("RECSTOP frame %d\n", stopped))
    end

    -- CANONICAL INPUT STAGING (replay.lua's convention): parse `held[fr]`,
    -- stage for the NEXT frame at the END of the callback. Done here rather
    -- than at the top so a frame number in this instrument's output IS a
    -- replay.lua frame number — see the note in the header.
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame + 1] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end

    if frame >= max_frames then
        -- A window that never closed would leave a truncated file with no
        -- record of how long it is; close it and SAY so rather than letting
        -- the summary imply a clean stop.
        if started and not stopped then
            machine.video:end_recording()
            stopped = frame
            f:write(string.format("RECSTOP frame %d (forced at FRAMES)\n", stopped))
        end
        f:write(string.format(
            "RECSUMMARY frames=%d from=%s to=%s wanted=%d-%d recorded=%s\n",
            frame, tostring(started), tostring(stopped), rec_from, rec_to,
            (started and stopped) and (stopped - started + 1) or 0))
        f:close()
        machine:exit()
    end
end)
