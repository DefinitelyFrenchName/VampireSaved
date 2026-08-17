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
--   env INPUT_OUT     optional path: per-frame raw input-port values
--                     ("<frame> <IN0> <IN1> <IN2>"). Proves whether a
--                     divergence was caused by HOST input leaking into the
--                     emulated controls (a MAME window can take focus even
--                     under -video none). tools/run_mame.sh disables all
--                     host input providers; this is the detector for when
--                     something slips past that.
--   env VIDEO_OUT     optional path: per-frame FRAMEBUFFER checksum log, the
--                     MAME twin of FBNeo's FBNEO_HVIDEO. Opt-in and written
--                     to a SEPARATE file, so every frozen RAM expectation is
--                     untouched. Exists because a RAM-only gate is
--                     structurally blind to the entire video path — the
--                     CPS-2 WIDE 19-bit tile address is a rendering change
--                     and produces byte-identical RAM logs whether it works
--                     or draws garbage (session 14z-55 paid for this on the
--                     FBNeo side). Ground-truth it before trusting a null:
--                     tests/test_replay_video_selfcheck.sh
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
-- FIELD_INFO[field] = { port tag, bit mask }, recorded here at construction
-- so the input-integrity check below never has to re-derive which port a
-- field belongs to. Keyed by the exact object stored in FIELDS, which is
-- the only reference the rest of the script ever uses (MAME may hand out a
-- fresh wrapper per lookup, so identity matching against port.fields later
-- would be unreliable).
local FIELD_INFO = {}
local function field_of(port, name)
    local p = ioport.ports[port]
    assert(p, "no port " .. port)
    local f = p.fields[name]
    assert(f, "no field '" .. name .. "' in " .. port)
    FIELD_INFO[f] = { port, f.mask }
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

-- POKES="frame:addr:hexbytes;..." — scheduled RAM writes (mirrors
-- tap_writes.lua; memory experiments inside the replay-exact harness)
local pokes = {}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
end
local f = assert(io.open(out_path, "wb"))
local frame = 0

-- MASK_RANGES (opt-in, e.g. "7f00-7ff0"): exclude work-RAM windows (offsets
-- from $FF0000, end exclusive) from the checksum. Default (unset) is the
-- canonical whole-work-RAM checksum — bit-identical to all frozen
-- expectations. Used for the dead-stack-window analysis (docs/GOTCHAS.md:
-- engine hooks skew interrupt timing; ghost bytes below resting SP differ).
local mask_ranges = {}
local mask_spec = os.getenv("MASK_RANGES") or ""
for a, b in mask_spec:gmatch("(%x+)%-(%x+)") do
    local lo, hi = tonumber(a, 16), tonumber(b, 16)
    -- VALIDATE, do not just parse (GitHub #61). The mask string IS the
    -- definition of the ratified comparison basis (CLAUDE.md §4,
    -- docs/game/atlas/ram.md), so a malformed one makes every expectation
    -- citing it meaningless. freeze_masked_basis.sh grew three guards in
    -- 14z-89 for exactly this reason while the READER validated nothing.
    if lo > hi then
        error(string.format("MASK_RANGES: %04x-%04x is inverted", lo, hi), 0)
    end
    if hi > 0x10000 then
        error(string.format("MASK_RANGES: %04x-%04x runs past work RAM "
                            .. "(offsets from $FF0000, end EXCLUSIVE)", lo, hi), 0)
    end
    mask_ranges[#mask_ranges + 1] = { lo, hi }
end
-- A non-empty spec that parsed to nothing is a typo, not "no mask": it would
-- silently produce a WHOLE-RAM checksum under a name that promises a masked
-- one. Catch it rather than comparing the wrong basis.
if mask_spec:match("%S") and #mask_ranges == 0 then
    error("MASK_RANGES is set but parsed to no ranges: " .. mask_spec, 0)
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
        -- NEVER MOVE POS BACKWARDS (GitHub #61). Ranges are sorted by START,
        -- so a NESTED or overlapping window can have a smaller end than the
        -- one before it — e.g. 1000-2000 then 1500-1800. A bare `pos = r[2]`
        -- rewinds to 0x1800 and the tail read then re-includes 0x1800-0x2000,
        -- silently UNMASKING bytes the spec asked to exclude. The mask would
        -- still look right in the log line and the comparison would be
        -- against a basis nobody ratified.
        if r[2] > pos then pos = r[2] end
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

-- INPUT_OUT: per-frame raw input-port values, written alongside (never into)
-- the RAM log. Defence in depth against the ONE failure mode that can
-- corrupt a replay without corrupting the emulator: host input reaching the
-- emulated controls.
--
-- MAME's "-video none" still creates a window that can take focus, and a
-- stray host keystroke maps straight onto P1 directions/buttons/coins/start.
-- The result is a run whose inputs are no longer the script's — RAM diverges
-- for as long as the key is held and then RE-CONVERGES once the replay's own
-- staging reasserts, which is exactly the signature of the two unexplained
-- 14z-59 divergences. tools/run_mame.sh now disables all four host input
-- providers so this cannot happen; this log makes it PROVABLE rather than
-- suspected if it ever does. On any divergence, diff the input logs first:
-- if they differ, the cause is external input and the investigation is over.
local input_out = os.getenv("INPUT_OUT")
local inf, in_ports
if input_out then
    inf = assert(io.open(input_out, "wb"))
    in_ports = {}
    for _, tag in ipairs({ ":IN0", ":IN1", ":IN2" }) do
        in_ports[#in_ports + 1] = assert(ioport.ports[tag], "no port " .. tag)
    end
end

-- ── INPUT INTEGRITY ASSERTION (always on, no env flag) ──────────────────
-- The log above is evidence after the fact; this is the guard. The harness
-- knows exactly which fields it staged for each frame, so it can verify
-- that the live ports contain THAT AND NOTHING ELSE. Any extra bit means
-- an input arrived from outside the script — a host keystroke on MAME's
-- focus-stealing window, a joystick, a stuck modifier — and the run is no
-- longer a replay of anything. Cheap: three port reads and a compare.
--
-- Deliberately not opt-in. The failure it catches is silent, produces a
-- plausible-looking log, and cost this project three hours of statistics
-- before the maintainer suggested the mechanism.
local inject_frame = tonumber(os.getenv("INPUT_INJECT_TEST") or "")
local INTEGRITY = os.getenv("NO_INPUT_CHECK") == nil
local PORT_TAGS = { ":IN0", ":IN1", ":IN2" }
local integ_ports, baseline, controlled = {}, {}, {}
local violations, first_violation = 0, nil
if INTEGRITY then
    for _, tag in ipairs(PORT_TAGS) do
        integ_ports[tag] = assert(ioport.ports[tag], "no port " .. tag)
        controlled[tag] = 0
    end
    -- Compare ONLY the bits this harness can drive. :IN2 also carries the
    -- EEPROM data line, which legitimately toggles during boot and has
    -- nothing to do with controller input — comparing whole ports flagged
    -- every single replay at frame 77 (ground truth: the check was wrong,
    -- not the runs). Host keystrokes land on controller bits, so masking to
    -- them loses no detection power.
    for _, group in pairs(FIELDS) do
        for _, field in pairs(group) do
            local info = FIELD_INFO[field]
            controlled[info[1]] = controlled[info[1]] | info[2]
        end
    end
end

-- NO IN-EMULATOR CONTROL EXISTS FOR THE FRAME-1 BRANCH, and that is a
-- measured fact rather than an omission (14z-94, GitHub #57). MAME samples
-- the input ports BEFORE the frame_done callback runs, so a Lua
-- `set_value` cannot make frame 1's own read dirty: tried at script load and
-- again at the top of frame 1, and both land at frame 2. The existing
-- INPUT_INJECT_TEST cannot reach it either — its condition is
-- `(frame + 1) == inject_frame`, so INPUT_INJECT_TEST=1 would need frame 0.
--
-- The real scenario — a HOST key physically held before the run — IS in that
-- read, because MAME samples host input ahead of the frame. So the branch is
-- reachable in the field and not from Lua.
--
-- The fix does not depend on a control to be correct: all-ones is the KNOWN
-- idle of active-low controls, so this asserts a constant rather than
-- inferring a baseline. That is the whole point of the change.

-- Expected port values for a given frame's held set: start from the idle
-- baseline and clear each pressed field's mask (CPS-2 inputs are active
-- low). Returns nil until the baseline has been captured on frame 1.
local function expected_ports(frame_held)
    if not baseline[PORT_TAGS[1]] then return nil end
    local exp = {}
    for _, tag in ipairs(PORT_TAGS) do exp[tag] = baseline[tag] end
    for _, field in ipairs(frame_held or {}) do
        local info = FIELD_INFO[field]
        if info then exp[info[1]] = exp[info[1]] & ~info[2] end
    end
    return exp
end

-- VIDEO_OUT: per-frame framebuffer checksum, written alongside (never into)
-- the RAM log. Same FNV-1a64 and same "<frame> <hash>" line format.
local video_out = os.getenv("VIDEO_OUT")
local vf, video_screen
if video_out then
    vf = assert(io.open(video_out, "wb"))
    video_screen = assert(manager.machine.screens[":screen"], "no :screen device")
end

-- every field we might touch, for release bookkeeping
local all_fields = {}
for _, group in pairs(FIELDS) do
    for _, field in pairs(group) do all_fields[#all_fields + 1] = field end
end
local pressed = {}  -- field -> true while held

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

    -- checksum first: state at END of frame N
    f:write(string.format("%d %016x\n", frame, fnv1a64(read_workram_masked())))
    if vf then
        vf:write(string.format("%d %016x\n", frame, fnv1a64(video_screen:pixels())))
    end
    if inf then
        inf:write(string.format("%d %04x %04x %04x\n", frame,
            in_ports[1]:read(), in_ports[2]:read(), in_ports[3]:read()))
    end
    if INTEGRITY then
        -- The set in effect DURING this frame is the one staged at the end
        -- of the previous frame, i.e. held[frame]. (held[1] is never staged
        -- — nothing runs before frame 1 — so frame 1 is always idle and is
        -- where the baseline is captured.)
        if frame == 1 then
            -- THE BASELINE IS ASSERTED, NOT ADOPTED (14z-94, GitHub #57).
            -- This used to take whatever the ports read on frame 1 as "idle".
            -- CPS-2 inputs are ACTIVE LOW, so the true idle value of the
            -- controlled bits is all-ones — and a host key held from before
            -- frame 1 through the whole run reads as baseline on frame 1 and
            -- then matches `exp` on every later frame. Zero violations, a
            -- clean log, and a run whose P1 direction was pressed for its
            -- entire length.
            --
            -- That is the one input pattern with NO divergence signature, and
            -- the positive control cannot reach it: INPUT_INJECT_TEST injects
            -- at a frame > 1, so "tested in both directions" only ever held
            -- for presses that START after frame 1.
            --
            -- So: compare frame 1 against the KNOWN idle, and use the known
            -- idle as the baseline thereafter — a dirty frame 1 must not
            -- become the yardstick for the rest of the run.
            for _, tag in ipairs(PORT_TAGS) do
                local got = integ_ports[tag]:read() & controlled[tag]
                if got ~= controlled[tag] then
                    violations = violations + 1
                    first_violation = first_violation or string.format(
                        "frame 1 port %s: controlled bits %04x are already LOW "..
                        "(active low = HELD before the replay started; stuck "..
                        "host key or modifier?) read %04x, idle %04x",
                        tag, controlled[tag] & ~got, got, controlled[tag])
                end
                baseline[tag] = controlled[tag]
            end
        else
            local exp = expected_ports(held[frame])
            for _, tag in ipairs(PORT_TAGS) do
                local got = integ_ports[tag]:read() & controlled[tag]
                if exp[tag] ~= got then
                    violations = violations + 1
                    first_violation = first_violation or
                        string.format("frame %d port %s expected %04x got %04x (mask %04x)",
                                      frame, tag, exp[tag], got, controlled[tag])
                end
            end
        end
    end
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

    -- TEST-ONLY positive control (INPUT_INJECT_TEST=<frame>): simulate a
    -- stray HOST keypress by pressing a button that held[] does not record,
    -- for exactly one frame. The integrity check above must then fire at
    -- that frame. A check that has only ever been silent is not evidence of
    -- anything; tests/test_input_integrity.sh exercises both directions.
    if inject_frame and (frame + 1) == inject_frame then
        local f = FIELDS.p1["1"]
        f:set_value(1)
        pressed[f] = true   -- so the next frame's staging releases it
    end

    if frame >= total_frames then
        -- A violation means inputs reached the machine from outside the
        -- script, so this log is not a replay of anything. Say so IN the
        -- log, before END, where every consumer will trip over it rather
        -- than silently comparing a corrupt run.
        if violations > 0 then
            f:write(string.format("INPUT-VIOLATION %d %s\n", violations, first_violation))
        end
        f:write(string.format("END %d\n", frame))
        f:close()
        if vf then vf:write(string.format("END %d\n", frame)); vf:close() end
        if inf then inf:write(string.format("END %d\n", frame)); inf:close() end
        manager.machine:exit()
    end
end)
