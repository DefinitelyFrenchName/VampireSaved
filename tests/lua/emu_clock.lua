-- emu_clock.lua — ONE frame clock for every breakpoint instrument: emulated frames, replay.lua's
-- input staging, and #213's alignment readings (14z-197, GitHub #228 step 4, maintainer-ruled
-- 2026-10-10 "option A").
--
-- WHY. A CPU held at a debugger breakpoint keeps MAME emitting UI frames, so frame_done fires while
-- emulated time stands still ([MFI-5], docs/platform/gotchas.md). An instrument that counts frame_done
-- calls as frames stages its replay input early and stops before the replay ends: #228 step 3
-- measured it on all 24 gates whose instruments arm breakpoints (audit_walker_ghost covered 4,203
-- emulated frames of 40,620 counted). tests/lua/pc_count.lua was converted first (14z-196); this is
-- that conversion as a shared module, so the other instruments do not each carry a copy (seven by 14z-197:
-- walker_sp, obj_record_bank_trace, trace_writes, replay_guard, bp_regs, fsm_census, obj_record_full_trace).
--
-- THE CLOCK. A frame counts when the screen's frame number has moved since the last counted one,
-- and the FIRST frame_done counts unconditionally, as replay.lua counts it (the number has not moved
-- yet at that call; skipping it put an instrument one frame behind replay.lua, the #213 skip). Input
-- is staged at the end of frame N for frame N+1, after the instrument's own per-frame work —
-- replay.lua's order — from a REPLAY script in replay.lua's grammar (p1=, p2=, sys=).
--
-- USE (from an instrument, BEFORE it arms anything):
--   local clock = dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "emu_clock.lua")
--   local C = clock{ name = "<instrument>", frames = <default max frames> }
--   if not C.reference then ...arm breakpoints/watchpoints... end
--   C.run{ on_pokes = function(frame) ... end,   -- optional: the frame's scheduled RAM writes (POKES), applied
--                                                --   BEFORE the anchor, as replay.lua applies them before its checksum
--          on_frame = function(frame) ... end,   -- optional: the instrument's per-frame work
--          after_staging = function(frame) ... end,  -- optional: work after N+1's input is staged (an input-integrity
--                                                --   check reads the ports there, as replay_guard.lua always has)
--          halted   = function() return bool end,  -- optional: true once the instrument stopped (a crash report):
--                                                --   frames are then neither counted nor staged
--          on_end   = function(frame) ... end }  -- optional: write the trailer; the module exits after
--   OPTIONS (14z-197, replay_guard.lua): `held` + `fields` hand the module the instrument's OWN parsed replay (frame ->
--   fields, and every controllable field) so staging and the instrument's integrity check read one parse; `fixed =
--   true` makes `frames` the run's length whatever FRAMES says (replay_guard derives it from the replay).
--   C.frame()  -- the current frame (for a periodic handler that tags what it sees)
--
-- ENV (read here, the same names for every instrument):
--   REPLAY        input script (optional: none = no input)
--   FRAMES        stop after this many frames (the instrument's own default otherwise)
--   INSTR_REFERENCE=1  the REFERENCE leg: the instrument arms nothing (C.reference is true) and may run
--                 without -debug — replay.lua's own game, whose ANCHOR a gate compares with a basis
--   INSTR_CLOCK   frame_done = the OLD drifting clock (every call a frame); skip_first = the #213
--                 first-frame skip. Each exists ONLY for a gate's must-fire control (drift-clock,
--                 first-frame-skip); unset in every real run.
--   ANCHOR        a frame N: at the end of frame N, BEFORE staging N+1's input (replay.lua's order),
--                 record replay.lua's work-RAM checksum under
--   MASK_RANGES   the same mask (replay.lua's grammar)
--   ALIGN_OUT     a file: at the end, ONE line is APPENDED (legs in parallel may share it):
--     ALIGN <name> <replay or -> frames <counted> emulated <screen frames> uiframes <counted-but-not-
--       emulated calls skipped> gameclock <RAM:$FF8080 at the last frame> [anchor <N> <fnv1a64>]
--   `gameclock` is one byte of the game's own vblank count — independent of this script's frame count, modulo
--   256 (measured 14z-197: one value per frame count over the first 122 frozen rows; a stop that moved the game's
--   work RAM left it unchanged — tests/lib/instr_align.sh "WHAT THE GAME CLOCK IS"): a gate freezes it per replay
--   from its reference legs (option A) and compares every breakpoint leg's with it.
--
-- WHAT IT CANNOT SEE: whether a breakpoint stop moved the GAME without moving $FF8080 ([MFI-2]); a
-- run killed before its last frame writes no ALIGN line, which a gate must count as missing.
return function(opts)
    local name = assert(opts and opts.name, "emu_clock: name required")
    local machine = manager.machine
    local screen = assert(machine.screens[":screen"], "emu_clock: no :screen device")
    local program = machine.devices[":maincpu"].spaces["program"]
    local M = {}
    M.reference = (os.getenv("INSTR_REFERENCE") or "") == "1"
    local max_frames = (not opts.fixed and tonumber(os.getenv("FRAMES") or "")) or opts.frames or 3600
    local mode = os.getenv("INSTR_CLOCK") or ""
    assert(mode == "" or mode == "frame_done" or mode == "skip_first",
        "emu_clock: INSTR_CLOCK must be frame_done or skip_first, got '" .. mode .. "'")
    local replay_path = os.getenv("REPLAY")
    if replay_path == "" then replay_path = nil end

    -- the replay (replay.lua's grammar subset every instrument here carried)
    local held, fields = {}, {}
    if opts.held then
        held, fields = opts.held, assert(opts.fields, "emu_clock: held without fields")
    elseif replay_path then
        local ioport = machine.ioport
        local function fld(port, n) return ioport.ports[port].fields[n] end
        local F = {
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
        for _, group in pairs(F) do for _, fo in pairs(group) do fields[#fields + 1] = fo end end
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
                            local step = (who == "sys") and 2 or 1
                            for i = 1, #toks, step do
                                local fo = F[who][toks:sub(i, i + step - 1)]
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

    -- the anchor: replay.lua's checksum, byte for byte (FNV-1a64 over work RAM $FF0000-$FFFFFF minus
    -- the MASK_RANGES windows, offsets from $FF0000, end exclusive) — as tests/lua/pc_count.lua
    local anchor_frame = tonumber(os.getenv("ANCHOR") or "")
    local mask = {}
    for lo, hi in (os.getenv("MASK_RANGES") or ""):gmatch("(%x+)%-(%x+)") do
        mask[#mask + 1] = { tonumber(lo, 16), tonumber(hi, 16) }
    end
    table.sort(mask, function(x, y) return x[1] < y[1] end)
    local function workram_masked()
        local parts, pos = {}, 0x0000
        for _, r in ipairs(mask) do
            if r[1] > pos then parts[#parts + 1] = program:read_range(0xff0000 + pos, 0xff0000 + r[1] - 1, 8) end
            if r[2] > pos then pos = r[2] end
        end
        if pos <= 0xFFFF then parts[#parts + 1] = program:read_range(0xff0000 + pos, 0xffffff, 8) end
        return table.concat(parts)
    end
    local PRIME = 0x100000001b3
    local function fnv1a64(s)
        local h = 0xcbf29ce484222325
        local n = #s - (#s % 8)
        for i = 1, n, 8 do h = (h ~ string.unpack("<i8", s, i)) * PRIME end
        for i = n + 1, #s do h = (h ~ s:byte(i)) * PRIME end
        return h
    end

    local frame, fn0 = 0, screen:frame_number()
    local last_fn, first, ui = fn0, mode ~= "skip_first", 0
    local anchor_text = ""
    local pressed = {}
    function M.frame() return frame end

    function M.run(cb)
        cb = cb or {}
        emu.register_frame_done(function()
            if cb.halted and cb.halted() then return end
            local fn = screen:frame_number()
            if fn == last_fn and mode ~= "frame_done" and not first then ui = ui + 1; return end
            first = false
            last_fn = fn
            frame = frame + 1
            if cb.on_pokes then cb.on_pokes(frame) end
            if anchor_frame and frame == anchor_frame then
                anchor_text = string.format(" anchor %d %016x", frame, fnv1a64(workram_masked()))
            end
            if cb.on_frame then cb.on_frame(frame) end
            local want = {}
            for _, fo in ipairs(held[frame + 1] or {}) do want[fo] = true end
            for _, fo in ipairs(fields) do
                if want[fo] and not pressed[fo] then fo:set_value(1); pressed[fo] = true
                elseif not want[fo] and pressed[fo] then fo:clear_value(); pressed[fo] = nil end
            end
            if cb.after_staging then cb.after_staging(frame) end
            if frame >= max_frames then
                if cb.on_end then cb.on_end(frame) end
                local out = os.getenv("ALIGN_OUT")
                if out and out ~= "" then
                    local af = assert(io.open(out, "a"))
                    af:write(string.format("ALIGN %s %s frames %d emulated %d uiframes %d gameclock %02x%s\n",
                        name, replay_path or "-", frame, fn - fn0 + 1, ui, program:read_u8(0xff8080), anchor_text))
                    af:close()
                end
                machine:exit()
            end
        end)
    end
    return M
end
