-- sheet_capture.lua — re-run one leg of a comparing gate and photograph it at the gate's moments, with what proves
-- each picture (14z-204, GitHub #291 slice S1; driven by tools/proof_sheets.py).
--
-- WHY. A comparison sheet is a proof for humans only if each picture shows the run the gate JUDGED. So at every
-- moment frame this instrument writes, beside MAME's snapshot, the evidence tools/proof_sheets.py compares with what
-- the gate logged there: the work-RAM checksum (replay.lua's FNV-1a64, with replay.lua's MASK_RANGES) and any named
-- fields (tests/lua/field_trace.lua's reading: words and longs signed). Everything is sampled where replay.lua
-- checksums and field_trace.lua samples: in the frame_done callback, after that frame's pokes — so a value for frame N
-- here is the value those logs hold for frame N. tests/test_proof_sheets.sh holds this to a frozen replay.lua log.
--
-- It is a separate instrument rather than an option of replay.lua on purpose: replay.lua is the oracle core that
-- most emulator gates follow, and an edit there would stale every one of them.
--
--   env REPLAY       input script (replay.lua grammar)
--   env POKES        "frame:addr:hexbytes;..." (replay.lua grammar, tests/lua/pokes_spec.lua)
--   env SNAP_FRAMES  comma-separated frames to photograph and prove
--   env FRAMES       hard stop (default max(SNAP_FRAMES))
--   env MASK_RANGES  replay.lua's mask (offsets from $FF0000, end exclusive); unset = whole work RAM
--   env FIELDS       "ff8410:w,ff8414:w" — read at every snapshot frame
--   env ANCHORS      1 = also photograph and prove each sync anchor (RAM:$FF812D round start 0->non-zero;
--                    RAM:$FF810E the round phase byte, docs/game/atlas/ram.md: 0->1 a down settles, 1->0 the next
--                    round spawns, any other change named by its values); the round timer RAM:$FF8109 is reported
--   env ANCHOR_MAX   at most this many anchors (default: no limit). The first anchor past it is written as
--                    ACAP <frame> <label>, so a capped leg says so — a silent cap of 16 dropped the later rounds of
--                    26_don_arcade_mash at 14z-204 (rule-checker run 2026-10-18-1118)
--   env CAPTURE_OUT  output path (default sheet_capture.txt)
--
-- Output, one line each:  S <n> <frame>  (MAME's snapshot number n, in the order taken)
--                         C <frame> <checksum>   V <frame> <addr:size=value,...>   A <frame> <label>
--                         ACAP <frame> <label>  (the first anchor past ANCHOR_MAX, not photographed)
--                         R <frame> ...  (tests/lua/screen_state.lua: the round state and OBJ count, #291 S4-B)
-- then CAPSUMMARY frames=<n> taken=<k> wanted=<w>.
-- INPUT STAGING IS CANONICAL (replay.lua's: parse held[fr], stage held[frame + 1]); tests/test_replay_stage_census.sh.

local machine = manager.machine
local out_path = os.getenv("CAPTURE_OUT") or "sheet_capture.txt"
local want, want_list = {}, {}
for tok in (os.getenv("SNAP_FRAMES") or ""):gmatch("[^,%s]+") do
    local n = tonumber(tok)
    if n and not want[n] then want[n] = true; want_list[#want_list + 1] = n end
end
local anchors_on = os.getenv("ANCHORS") == "1"
assert(#want_list > 0 or anchors_on, "SNAP_FRAMES must name a frame, or ANCHORS=1")
table.sort(want_list)
local max_frames = tonumber(os.getenv("FRAMES") or "") or want_list[#want_list]
local anchor_max = tonumber(os.getenv("ANCHOR_MAX") or "") or math.huge
local capped = false

local cpu = machine.devices[":maincpu"]
local program = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))

-- input playback: the replay.lua subset every instrument shares
local held = {}
local replay_path = assert(os.getenv("REPLAY"), "set REPLAY")
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

local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
local pokes = {}
dofile(here .. "pokes_spec.lua").append(pokes, os.getenv("POKES"))
local screen_state = dofile(here .. "screen_state.lua")

-- the checksum: replay.lua's FNV-1a64 over work RAM, its mask parsed and validated the same way
local mask_ranges = {}
local mask_spec = os.getenv("MASK_RANGES") or ""
for a, b in mask_spec:gmatch("(%x+)%-(%x+)") do
    local lo, hi = tonumber(a, 16), tonumber(b, 16)
    if lo > hi then error(string.format("MASK_RANGES: %04x-%04x is inverted", lo, hi), 0) end
    if hi > 0x10000 then error(string.format("MASK_RANGES: %04x-%04x runs past work RAM", lo, hi), 0) end
    mask_ranges[#mask_ranges + 1] = { lo, hi }
end
if mask_spec:match("%S") and #mask_ranges == 0 then error("MASK_RANGES is set but parsed to no ranges: " .. mask_spec, 0) end
table.sort(mask_ranges, function(x, y) return x[1] < y[1] end)
local function read_workram_masked()
    if #mask_ranges == 0 then return program:read_range(0xff0000, 0xffffff, 8) end
    local parts, pos = {}, 0x0000
    for _, r in ipairs(mask_ranges) do
        if r[1] > pos then parts[#parts + 1] = program:read_range(0xff0000 + pos, 0xff0000 + r[1] - 1, 8) end
        if r[2] > pos then pos = r[2] end
    end
    if pos <= 0xFFFF then parts[#parts + 1] = program:read_range(0xff0000 + pos, 0xffffff, 8) end
    return table.concat(parts)
end
local FNV_PRIME = 0x100000001b3
local function fnv1a64(s)
    local h = 0xcbf29ce484222325
    local n = #s - (#s % 8)
    for i = 1, n, 8 do h = (h ~ string.unpack("<i8", s, i)) * FNV_PRIME end
    for i = n + 1, #s do h = (h ~ s:byte(i)) * FNV_PRIME end
    return h
end

local fields = {}
for spec in (os.getenv("FIELDS") or ""):gmatch("[^,]+") do
    local a, sz = spec:match("^%s*(%x+):([bwl])%s*$")
    assert(a, "FIELDS entry must be addr:size — got '" .. spec .. "'")
    fields[#fields + 1] = { addr = tonumber(a, 16), size = sz, spec = a:lower() .. ":" .. sz }
end
local function read_field(fd)
    if fd.size == "b" then return program:read_u8(fd.addr) end
    if fd.size == "w" then local v = program:read_u16(fd.addr); return v >= 0x8000 and v - 0x10000 or v end
    local v = program:read_u32(fd.addr); return v >= 0x80000000 and v - 0x100000000 or v
end

local frame, taken, n_anchor = 0, 0, 0
local prev_start, prev_phase = nil, nil
local pressed = {}
local all_fields = {}
for _, group in pairs(F) do for _, fo in pairs(group) do all_fields[#all_fields + 1] = fo end end

local function photograph(label)
    f:write(string.format("C %d %016x\n", frame, fnv1a64(read_workram_masked())))
    if #fields > 0 then
        local parts = {}
        for _, fd in ipairs(fields) do parts[#parts + 1] = string.format("%s=%d", fd.spec, read_field(fd)) end
        f:write(string.format("V %d %s\n", frame, table.concat(parts, ",")))
    end
    if label then f:write(string.format("A %d %s\n", frame, label)) end
    f:write(screen_state.line(program, frame))      -- #291 S4-B: what the picture shows, read from the game's state
    machine.video:snapshot()
    f:write(string.format("S %d %d\n", taken, frame))
    taken = taken + 1
end

emu.register_frame_done(function()
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do program:write_u8(a, tonumber(b, 16)); a = a + 1 end
        end
    end
    local label = nil
    if anchors_on then
        local st, ph = program:read_u8(0xff812d), program:read_u8(0xff810e)
        if prev_start ~= nil then
            local timer = program:read_u8(0xff8109)
            if prev_start == 0 and st ~= 0 then
                label = "round start"
            elseif ph ~= prev_phase then
                if prev_phase == 0 and ph == 1 then label = string.format("down settles (timer %02x)", timer)
                elseif prev_phase == 1 and ph == 0 then label = "next round spawns"
                else label = string.format("round phase %02x->%02x", prev_phase, ph) end
            end
            if label and n_anchor >= anchor_max then
                if not capped then f:write(string.format("ACAP %d %s\n", frame, label)); capped = true end
                label = nil
            elseif label then n_anchor = n_anchor + 1 end
        end
        prev_start, prev_phase = st, ph
    end
    if want[frame] or label then photograph(label) end
    local w = {}
    for _, fo in ipairs(held[frame + 1] or {}) do w[fo] = true end
    for _, fo in ipairs(all_fields) do
        if w[fo] and not pressed[fo] then fo:set_value(1); pressed[fo] = true
        elseif not w[fo] and pressed[fo] then fo:clear_value(); pressed[fo] = nil end
    end
    if frame >= max_frames then
        f:write(string.format("CAPSUMMARY frames=%d taken=%d wanted=%d\n", frame, taken, #want_list))
        f:close()
        machine:exit()
    end
end)
