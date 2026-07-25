-- replay.lua — scripted-input replay runner with per-frame RAM checksums.
-- The oracle-harness core (CLAUDE.md §4): identical inputs must yield
-- identical work-RAM checksum logs across runs/builds/emulators.
--
-- Usage: mame <set> -autoboot_script tests/lua/replay.lua ...
--   env REPLAY        input script path (required)
--   env CHECKSUM_OUT  checksum log path (default replay_checksums.txt)
--   env TAIL_FRAMES   frames to keep running after last scripted input (default 120)
--   env SNAP_FRAMES   optional "300,600,900": save a PNG snapshot at those
--                     frames (to MAME's snapshot dir) — for replay authoring
--   env DUMPS         optional "2900:ff8000-ff8700;3000:ff9400-ff9500":
--                     at end of frame N, dump the RAM range to
--                     <dir of CHECKSUM_OUT>/dump_<frame>_<start>.bin
--                     (differential RE experiments)
--   env MASK_RANGES   optional "7f00-7ff0" (offsets from $FF0000, end
--                     exclusive): exclude window(s) from the checksum.
--                     Unset = canonical whole-work-RAM checksum (matches
--                     all frozen expectations). Analysis use only.
--
-- Replay script format (tests/replays/*.rpl), line-oriented:
--   # comment / blank lines ignored
--   <frame>[-<endframe>] <who>=<tokens> [<who>=<tokens> ...]
-- who: p1, p2, sys. Tokens (concatenated, e.g. p1=D3 for down+button3):
--   p1/p2: U D L R 1 2 3 4 5 6        (directions, buttons 1-6)
--   sys:   S1 S2 C1 C2 SV TS          (starts, coins, service switch, test)
-- "<frame> wait" holds no input but extends the replay to that frame.
-- Lines OR together; a token is held for every frame its ranges cover.
-- Frame 1 = first emulated frame after machine start.
--
-- Log format matches attract_checksum.lua: "<frame> <fnv1a64>" + "END <n>".

local replay_path = assert(os.getenv("REPLAY"), "set REPLAY to the input script path")
local out_path = os.getenv("CHECKSUM_OUT") or "replay_checksums.txt"
local tail_frames = tonumber(os.getenv("TAIL_FRAMES") or "") or 120

-- ── field lookup ─────────────────────────────────────────────────────────────

local ioport = manager.machine.ioport
local function field_of(port, name)
    local p = ioport.ports[port]
    assert(p, "no port " .. port)
    local f = p.fields[name]
    assert(f, "no field '" .. name .. "' in " .. port)
    return f
end

local FIELDS = {
    p1 = {
        U = field_of(":IN0", "P1 Up"), D = field_of(":IN0", "P1 Down"),
        L = field_of(":IN0", "P1 Left"), R = field_of(":IN0", "P1 Right"),
        ["1"] = field_of(":IN0", "P1 Button 1"), ["2"] = field_of(":IN0", "P1 Button 2"),
        ["3"] = field_of(":IN0", "P1 Button 3"), ["4"] = field_of(":IN1", "P1 Button 4"),
        ["5"] = field_of(":IN1", "P1 Button 5"), ["6"] = field_of(":IN1", "P1 Button 6"),
    },
    p2 = {
        U = field_of(":IN0", "P2 Up"), D = field_of(":IN0", "P2 Down"),
        L = field_of(":IN0", "P2 Left"), R = field_of(":IN0", "P2 Right"),
        ["1"] = field_of(":IN0", "P2 Button 1"), ["2"] = field_of(":IN0", "P2 Button 2"),
        ["3"] = field_of(":IN0", "P2 Button 3"), ["4"] = field_of(":IN1", "P2 Button 4"),
        ["5"] = field_of(":IN1", "P2 Button 5"), ["6"] = field_of(":IN2", "P2 Button 6"),
    },
    sys = {
        S1 = field_of(":IN2", "1 Player Start"), S2 = field_of(":IN2", "2 Players Start"),
        C1 = field_of(":IN2", "Coin 1"), C2 = field_of(":IN2", "Coin 2"),
        SV = field_of(":IN2", "Service 1"), TS = field_of(":IN2", "Service Mode"),
    },
}

-- sys tokens are exactly two chars (S1/S2/C1/C2/SV/TS); p1/p2 tokens one
local function split_tokens(who, s)
    local toks, step = {}, (who == "sys") and 2 or 1
    for i = 1, #s, step do toks[#toks + 1] = s:sub(i, i + step - 1) end
    return toks
end

-- ── parse replay ─────────────────────────────────────────────────────────────

-- held[frame] = { field, field, ... } (list may contain duplicates; harmless)
local held = {}
local last_frame = 0

local lineno = 0
for line in io.lines(replay_path) do
    lineno = lineno + 1
    local body = line:gsub("#.*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #body > 0 then
        local range, rest = body:match("^(%S+)%s+(.*)$")
        assert(range, replay_path .. ":" .. lineno .. ": expected '<frame>[-<end>] who=tokens'")
        local a, b = range:match("^(%d+)%-(%d+)$")
        if not a then a = range:match("^(%d+)$"); b = a end
        assert(a, replay_path .. ":" .. lineno .. ": bad frame range '" .. range .. "'")
        a, b = tonumber(a), tonumber(b)
        assert(a >= 1 and b >= a, replay_path .. ":" .. lineno .. ": bad range")
        for spec in rest:gmatch("%S+") do
          if spec ~= "wait" then
            local who, toks = spec:match("^(%a+%d?)=(%S+)$")
            local group = FIELDS[who]
            assert(group, replay_path .. ":" .. lineno .. ": unknown side '" .. tostring(who) .. "'")
            for _, t in ipairs(split_tokens(who, toks)) do
                local field = group[t]
                assert(field, replay_path .. ":" .. lineno .. ": unknown token '" .. t .. "' for " .. who)
                for fr = a, b do
                    held[fr] = held[fr] or {}
                    held[fr][#held[fr] + 1] = field
                end
            end
          end
        end
        if b > last_frame then last_frame = b end
    end
end

local total_frames = last_frame + tail_frames

local snap_at = {}
for n in (os.getenv("SNAP_FRAMES") or ""):gmatch("%d+") do
    local fr = tonumber(n)
    snap_at[fr] = true
    if fr + 1 > total_frames then total_frames = fr + 1 end
end

local dump_at = {}  -- frame -> { {first, last}, ... }
local out_dir = out_path:match("^(.*)/[^/]+$") or "."
for spec in (os.getenv("DUMPS") or ""):gmatch("[^;]+") do
    local fr, first, last = spec:match("^(%d+):(%x+)%-(%x+)$")
    assert(fr, "bad DUMPS spec: " .. spec)
    fr = tonumber(fr)
    dump_at[fr] = dump_at[fr] or {}
    table.insert(dump_at[fr], { tonumber(first, 16), tonumber(last, 16) })
    if fr + 1 > total_frames then total_frames = fr + 1 end
end

-- ── per-frame drive ──────────────────────────────────────────────────────────

local cpu = manager.machine.devices[":maincpu"]
local program = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))
local frame = 0

-- MASK_RANGES (opt-in, e.g. "7f00-7ff0"): exclude work-RAM windows (offsets
-- from $FF0000, end exclusive) from the checksum. Default (unset) is the
-- canonical whole-work-RAM checksum — bit-identical to all frozen
-- expectations. Used for the dead-stack-window analysis (docs/GOTCHAS.md:
-- engine hooks skew interrupt timing; ghost bytes below resting SP differ).
local mask_ranges = {}
for a, b in (os.getenv("MASK_RANGES") or ""):gmatch("(%x+)%-(%x+)") do
    mask_ranges[#mask_ranges + 1] = { tonumber(a, 16), tonumber(b, 16) }
end
table.sort(mask_ranges, function(x, y) return x[1] < y[1] end)

local function read_workram_masked()
    if #mask_ranges == 0 then
        return program:read_range(0xff0000, 0xffffff, 8)
    end
    local parts, pos = {}, 0x0000
    for _, r in ipairs(mask_ranges) do
        if r[1] > pos then
            parts[#parts + 1] = program:read_range(0xff0000 + pos,
                                                   0xff0000 + r[1] - 1, 8)
        end
        pos = r[2]
    end
    if pos <= 0xFFFF then
        parts[#parts + 1] = program:read_range(0xff0000 + pos, 0xffffff, 8)
    end
    return table.concat(parts)
end

local FNV_PRIME = 0x100000001b3
local function fnv1a64(s)
    local h = 0xcbf29ce484222325
    local n = #s - (#s % 8)
    for i = 1, n, 8 do
        h = (h ~ string.unpack("<i8", s, i)) * FNV_PRIME
    end
    for i = n + 1, #s do
        h = (h ~ s:byte(i)) * FNV_PRIME
    end
    return h
end

-- every field we might touch, for release bookkeeping
local all_fields = {}
for _, group in pairs(FIELDS) do
    for _, field in pairs(group) do all_fields[#all_fields + 1] = field end
end
local pressed = {}  -- field -> true while held

emu.register_frame_done(function()
    frame = frame + 1

    -- checksum first: state at END of frame N
    f:write(string.format("%d %016x\n", frame, fnv1a64(read_workram_masked())))
    if snap_at[frame] then manager.machine.video:snapshot() end
    for _, range in ipairs(dump_at[frame] or {}) do
        local df = assert(io.open(string.format("%s/dump_%d_%06x.bin", out_dir, frame, range[1]), "wb"))
        df:write(program:read_range(range[1], range[2], 8))
        df:close()
    end

    -- then stage inputs that should be held DURING frame N+1
    local want = {}
    for _, field in ipairs(held[frame + 1] or {}) do want[field] = true end
    for _, field in ipairs(all_fields) do
        if want[field] and not pressed[field] then
            field:set_value(1); pressed[field] = true
        elseif not want[field] and pressed[field] then
            field:clear_value(); pressed[field] = nil
        end
    end

    if frame >= total_frames then
        f:write(string.format("END %d\n", frame))
        f:close()
        manager.machine:exit()
    end
end)
