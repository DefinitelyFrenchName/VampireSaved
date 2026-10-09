-- pc_count.lua — HOW OFTEN, and in WHICH FRAMES, does the CPU execute each of a
-- set of instruction addresses? Breakpoint on each site; every stop counts one
-- hit against the current frame and resumes. Output is per-frame and compact:
-- only frames with a hit are written, so a site that fires 50 times a frame
-- costs one line per frame, not 50.
--
-- WHY (14z-189, GitHub #128): a hook's LEGACY cost is (executions per frame) x
-- (cycles the hook adds), and the performance rule binds the WORST frame, not
-- the average — so the count is kept per frame, never only summed.
--
-- WHAT IT CANNOT SEE: an address the CPU reaches by a path that does not stop
-- at the breakpoint (none on a 68000 — every executed instruction's first word
-- is fetched at its PC), and what the frame boundary is relative to VBL (it is
-- MAME's frame_done, the same boundary replay.lua and every gate here uses).
--
--   env SITES   "4dda,895c,..." hex addresses (no 0x)
--   env OUT     output path (default pc_count.txt)
--   env REPLAY  input script (replay.lua grammar subset, as dispatch_census.lua)
--   env FRAMES  stop after this many frames (default 3600)
--   env PC_CLOCK frame_done = the old drifting clock; skip_first = the first-frame skip
--                (#228) — each a control only (see below)
--   env ANCHOR   a frame N: at the end of frame N, BEFORE staging frame N+1's input
--                (replay.lua's order), print "ANCHOR <N> <fnv1a64>" — replay.lua's
--                work-RAM checksum for that frame under
--   env MASK_RANGES the same mask (replay.lua's grammar) — and "GAMECLOCK <N> <byte>",
--                the game's own vblank counter RAM:$FF8080 (14z-196, GitHub #228: the
--                method tests/lua/dispatch_census.lua took at 14z-192 for #213)
--   SITES=none   the REFERENCE leg: no breakpoint, no debugger — replay.lua's own game,
--                whose ANCHOR the gate compares with the frozen vanilla basis
--
-- Output:
--   F <frame> <addr>:<hits> ...        one line per frame with any hit
--   SITE <addr> hits <total> frames <frames-with-hits> max <max-in-one-frame>
--   UIFRAMES <frame_done calls with no emulated frame — the stops' UI frames, skipped>
--   EMUFRAMES <emulated frames since start (the screen's frame number, +1 for the first)>
--   ANCHOR / GAMECLOCK                 when ANCHOR is set
--   PCEND <frames>
-- Needs -debug -debugger none, except with SITES=none.
local machine = manager.machine
local debugger = machine.debugger
local REFERENCE = (os.getenv("SITES") or "") == "none"
assert(debugger or REFERENCE, "run mame with -debug")
local cpu = machine.devices[":maincpu"]

local out_path = os.getenv("OUT") or "pc_count.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local sites, order = {}, {}
for a in (REFERENCE and "" or os.getenv("SITES") or ""):gmatch("[^,%s]+") do
    local v = tonumber(a, 16)
    assert(v, "SITES entry must be hex — got '" .. a .. "'")
    sites[v] = { hits = 0, frames = 0, max = 0 }
    order[#order + 1] = v
end
assert(REFERENCE or #order > 0, "set SITES=hexaddr,... (or SITES=none for the reference leg)")
table.sort(order)

local frame = 0
local held = {}
local FIELDS_IO = nil
local replay_path = os.getenv("REPLAY")
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

if debugger then
    debugger:command("focus 0")
    for _, addr in ipairs(order) do
        debugger:command(string.format("bpset 0x%x", addr))
    end
end

-- THE ANCHOR (replay.lua's checksum, byte for byte: FNV-1a64 over work RAM
-- $FF0000-$FFFFFF minus MASK_RANGES windows, offsets from $FF0000, end exclusive) —
-- copied from tests/lua/dispatch_census.lua (#213), so both instruments anchor alike.
local anchor_frame = tonumber(os.getenv("ANCHOR") or "")
local program = cpu.spaces["program"]
local mask_ranges = {}
for lo, hi in (os.getenv("MASK_RANGES") or ""):gmatch("(%x+)%-(%x+)") do
    mask_ranges[#mask_ranges + 1] = { tonumber(lo, 16), tonumber(hi, 16) }
end
table.sort(mask_ranges, function(x, y) return x[1] < y[1] end)
local function read_workram_masked()
    local parts, pos = {}, 0x0000
    for _, r in ipairs(mask_ranges) do
        if r[1] > pos then
            parts[#parts + 1] = program:read_range(0xff0000 + pos, 0xff0000 + r[1] - 1, 8)
        end
        if r[2] > pos then pos = r[2] end
    end
    if pos <= 0xFFFF then
        parts[#parts + 1] = program:read_range(0xff0000 + pos, 0xffffff, 8)
    end
    return table.concat(parts)
end
local FNV_PRIME = 0x100000001b3
local function fnv1a64(str)
    local h = 0xcbf29ce484222325
    local n = #str - (#str % 8)
    for i = 1, n, 8 do h = (h ~ string.unpack("<i8", str, i)) * FNV_PRIME end
    for i = n + 1, #str do h = (h ~ str:byte(i)) * FNV_PRIME end
    return h
end
local anchor_line = nil

-- THE FRAME CLOCK IS EMULATED TIME, NOT frame_done CALLS ([MFI-5]/[MFI-6]): while a
-- breakpoint holds the CPU, MAME keeps emitting UI frames and frame_done keeps firing,
-- so a frame_done counter inflates past emulated time and replay input lands early
-- (measured 14z-189: 03_two_player_vs counted 5320 "frames" in 44 emulated seconds,
-- and the Shadow replay's five START presses missed the "?" cell once 27 sites were
-- armed). The screen's own frame number advances only with emulated frames.
local screen = assert(manager.machine.screens[":screen"], "no :screen device")
-- PC_CLOCK=frame_done restores the OLD (drifting) clock: the must-fire control of
-- tests/audit_marionette_cost.sh ("drift-clock") proves the gate sees the desync.
local DRIFT = (os.getenv("PC_CLOCK") or "") == "frame_done"
local fn0 = screen:frame_number()
local last_fn = fn0
local f = assert(io.open(out_path, "wb"))
local cur = {}            -- [addr] = hits in the current frame
local pressed = {}
local ui_frames = 0
-- PC_CLOCK=skip_first restores the first-frame skip (#228): the must-fire control
-- tests/audit_marionette_cost.sh ("first-frame-skip") runs it on a reference leg,
-- which must then miss the frozen basis checksum at its anchor.
local first_frame = (os.getenv("PC_CLOCK") or "") ~= "skip_first"
emu.register_frame_done(function()
    local fn = screen:frame_number()
    -- The FIRST frame_done counts unconditionally, as replay.lua counts it: the screen's
    -- frame number has not moved yet at that call, and skipping it put this script one
    -- frame behind replay.lua — input one frame late (the skip #213 found and fixed in
    -- tests/lua/dispatch_census.lua at 14z-192; fixed here 14z-196, GitHub #228).
    if fn == last_fn and not DRIFT and not first_frame then ui_frames = ui_frames + 1; return end
    first_frame = false
    last_fn = fn
    frame = frame + 1
    if anchor_frame and frame == anchor_frame then
        anchor_line = string.format("ANCHOR %d %016x\nGAMECLOCK %d %02x\n", frame,
            fnv1a64(read_workram_masked()), frame, program:read_u8(0xff8080))
    end
    local parts = {}
    for _, a in ipairs(order) do
        local n = cur[a]
        if n then
            parts[#parts + 1] = string.format("%x:%d", a, n)
            local s = sites[a]
            s.frames = s.frames + 1
            if n > s.max then s.max = n end
        end
    end
    if #parts > 0 then f:write(string.format("F %d %s\n", frame, table.concat(parts, " "))) end
    cur = {}
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
    if frame >= max_frames then
        for _, a in ipairs(order) do
            local s = sites[a]
            f:write(string.format("SITE %06x hits %d frames %d max %d\n", a, s.hits, s.frames, s.max))
        end
        f:write(string.format("UIFRAMES %d\n", ui_frames))
        -- +1: the first frame_done is counted before the screen's frame number moves
        f:write(string.format("EMUFRAMES %d\n", fn - fn0 + 1))
        if anchor_line then f:write(anchor_line) end
        f:write(string.format("PCEND %d\n", frame))
        f:close()
        machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger and debugger.execution_state == "stop" then
        local pc = cpu.state["CURPC"].value
        local s = sites[pc]
        if s then
            s.hits = s.hits + 1
            cur[pc] = (cur[pc] or 0) + 1
        end
        debugger.execution_state = "run"
    end
end)
