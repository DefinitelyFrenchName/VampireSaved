-- dispatch_census.lua — WHICH TYPE INDICES does a PC-relative jump table
-- ever dispatch? Accumulates the SET of indices seen at each site and
-- prints only the summary, so a site that fires 100k times in a replay
-- costs one line of output instead of 100k.
--
-- WHY (14z-89). The legacy-cycle regression's fix (option b, maintainer
-- 2026-08-15) wants the tenant's object types moved onto table entries
-- LEGACY NEVER DISPATCHES — repointing such an entry is a pure data
-- change and costs zero legacy cycles, where any code hook at the site
-- costs cycles on every dispatch and tips VBL-edge frames. That needs a
-- census: 17 free indices in the 59-entry table at 0x054470 and 10 in the
-- 114-entry table at 0x05E542, or route (i) is dead and the fix has to be
-- architectural instead.
--
-- THE SITE SHAPE: `movea.l (0x12,PC,D0.w),A0` — D0 holds index*4 AT the
-- instruction and is cleared by the `moveq #0,D0` right after, so the
-- breakpoint must sit ON the site, not after it (14z-81b).
--
-- A DEADNESS CLAIM IS ONLY AS GOOD AS ITS COVERAGE. This session's own
-- lesson: the type-6 deadness row was measured on four replays and was
-- WRONG. Run this over the whole legacy corpus, and treat "never observed
-- in N replays" as exactly that — never observed, not proven dead.
--
--   env SITES      "54470:59,5e542:114" — addr:n_entries, hex addr
--   env CENSUS_OUT output path (default dispatch_census.txt)
--   env REPLAY     input script (replay.lua grammar subset)
--   env FRAMES     stop after this many frames (default 3600)
--   env CENSUS_CLOCK  "frame_done" restores the OLD drifting clock (the
--                  must-fire control of tests/audit_dispatch_census.sh)
--   env ANCHOR     a frame N: at the end of frame N, BEFORE staging frame N+1's
--                  input (replay.lua's order), print "ANCHOR <N> <fnv1a64>" — the
--                  work-RAM checksum replay.lua writes for that frame, under
--   env MASK_RANGES the same mask (replay.lua's grammar). The gate compares it with
--                  the frozen vanilla basis log, an anchor OUTSIDE this script's
--                  clock (14z-192, rule-checker run 2026-10-05-673).
--
-- THE FRAME CLOCK IS EMULATED TIME (14z-192, GitHub #213; [MFI-5]): while a
-- breakpoint holds the CPU, MAME keeps emitting UI frames and frame_done keeps
-- firing, so a frame_done counter runs ahead of emulated time, replay input
-- keyed to it lands early, and the run stops before the replay's end. The
-- screen's own frame number advances only with emulated frames (the clock
-- tests/lua/pc_count.lua took at 14z-189).
--
-- Output, one block per site:
--   SITE <addr> entries <n> hits <total> seen <count> : <sorted indices>
--   FREE <addr> <count> : <sorted never-observed indices>
-- then "EMUFRAMES <emulated frames since start> UIFRAMES <frame_done calls
-- with no emulated frame>", the ANCHOR/GAMECLOCK lines when ANCHOR is set, and
-- "CENSUSEND <frames>". Needs -debug -debugger none, except with SITES=none (the
-- REFERENCE leg: no breakpoint, no debugger — replay.lua's own game, 14z-192).
--
-- WHY A REFERENCE LEG (14z-192, measured): a breakpoint stop changes how the 68k
-- and the sound CPU interleave, and on some replays that moves the GAME — on
-- 03_two_player_vs the breakpoint leg's work RAM leaves the vanilla basis at frame
-- 469 and differs in fighter and object fields by 5320, while 06_test_mode and
-- 26_don_arcade_mash stay byte-identical to it. So the breakpoint leg cannot be
-- anchored byte for byte; the reference leg can, and the breakpoint leg is tied to
-- it by the game's own vblank counter (GAMECLOCK, RAM:$FF8080).
local machine = manager.machine
local debugger = machine.debugger
local REFERENCE = (os.getenv("SITES") or "") == "none"   -- the reference leg runs without -debug
assert(debugger or REFERENCE, "run mame with -debug")
local cpu = machine.devices[":maincpu"]

local out_path = os.getenv("CENSUS_OUT") or "dispatch_census.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local sites = {}          -- [addr] = {n = entries, seen = {}, hits = 0}
for spec in (os.getenv("SITES") or ""):gmatch("[^,]+") do
    if spec ~= "none" then
        local a, n = spec:match("^%s*(%x+):(%d+)%s*$")
        assert(a, "SITES entry must be hexaddr:entries — got '" .. spec .. "'")
        sites[tonumber(a, 16)] = { n = tonumber(n), seen = {}, hits = 0 }
    end
end
-- SITES="none" (14z-192): the REFERENCE leg — no breakpoint is armed, so the CPU never
-- stops and the run is replay.lua's own game; its ANCHOR must equal the basis exactly.
local reference = REFERENCE
if reference then sites = {} end
assert(reference or next(sites), "set SITES=hexaddr:entries,... (or SITES=none for the reference leg)")

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
    for addr, _ in pairs(sites) do
        debugger:command(string.format("bpset 0x%x", addr))
    end
end

-- THE ANCHOR (replay.lua's checksum, byte for byte: FNV-1a64 over work RAM
-- $FF0000-$FFFFFF minus MASK_RANGES windows, offsets from $FF0000, end exclusive).
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

local screen = assert(machine.screens[":screen"], "no :screen device")
local DRIFT = (os.getenv("CENSUS_CLOCK") or "") == "frame_done"
local fn0 = screen:frame_number()
local last_fn = fn0
local ui_frames = 0
local pressed = {}
local first_frame = true
emu.register_frame_done(function()
    local fn = screen:frame_number()
    -- The FIRST frame_done counts unconditionally, as replay.lua counts it: the screen's
    -- frame number has not moved yet at that call, and skipping it put this script one
    -- frame behind replay.lua — input one frame late, every anchor missed (14z-192,
    -- measured: the no-breakpoint reference leg showed UIFRAMES 1 and missed the basis).
    if fn == last_fn and not DRIFT and not first_frame then ui_frames = ui_frames + 1; return end
    first_frame = false
    last_fn = fn
    frame = frame + 1
    if anchor_frame and frame == anchor_frame then
        -- GAMECLOCK: the game's own vblank frame counter RAM:$FF8080 (a byte), read at the
        -- anchor — the breakpoint leg's comparison with the reference leg, since a
        -- breakpoint stop perturbs the CPU interleaving and so the RNG (14z-192)
        anchor_line = string.format("ANCHOR %d %016x\nGAMECLOCK %d %02x\n", frame,
            fnv1a64(read_workram_masked()), frame, program:read_u8(0xff8080))
    end
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
        local f = assert(io.open(out_path, "wb"))
        local addrs = {}
        for a, _ in pairs(sites) do addrs[#addrs + 1] = a end
        table.sort(addrs)
        for _, a in ipairs(addrs) do
            local s = sites[a]
            local seen, free = {}, {}
            for i = 0, s.n - 1 do
                if s.seen[i] then seen[#seen + 1] = i else free[#free + 1] = i end
            end
            f:write(string.format("SITE %06x entries %d hits %d seen %d : %s\n",
                a, s.n, s.hits, #seen, table.concat(seen, ",")))
            f:write(string.format("FREE %06x %d : %s\n", a, #free, table.concat(free, ",")))
        end
        -- +1: the first frame_done is counted before the screen's frame number moves
        f:write(string.format("EMUFRAMES %d UIFRAMES %d\n", fn - fn0 + 1, ui_frames))
        if anchor_line then f:write(anchor_line) end
        f:write(string.format("CENSUSEND %d\n", frame))
        f:close()
        machine:exit()
    end
end)

emu.register_periodic(function()
    if debugger and debugger.execution_state == "stop" then
        local st = cpu.state
        local pc = st["CURPC"].value
        local s = sites[pc]
        if s then
            -- D0 holds index*4 AT the site; mask to the word the mode uses
            local idx = (st["D0"].value & 0xffff) // 4
            s.hits = s.hits + 1
            if idx < s.n then s.seen[idx] = true else s.seen[-1] = true end
        end
        debugger.execution_state = "run"
    end
end)
