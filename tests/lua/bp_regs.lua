-- bp_regs.lua — log registers at named PCs while a replay drives the game
-- (14z-85f, the FG damage-path probe). Takes its replay/POKES playback from
-- the tap_writes.lua family and its auto-resuming debugger breakpoints from
-- index_watch.lua. Needs `-debug -debugger none` (run_mame.sh passes extra
-- args through).
--
-- INPUT STAGING IS CANONICAL (GitHub #10, unified 14z-94). This instrument
-- follows tests/lua/replay.lua exactly: parse `held[fr]`, stage for the NEXT
-- frame (`held[frame + 1]`). So INPUTS land on the same frames as replay.lua's.
-- But the `frame <N> PC` lines are logged from the breakpoint DURING the frame, labelled
-- with the counter BEFORE frame_done increments it: such a line labelled N
-- belongs to replay.lua's frame N+1 — add one before cross-referencing a
-- compare_* first divergence, a masked window onset or a checksum log. Lines
-- written inside frame_done carry replay.lua's number (14z-184,
-- docs/platform/gotchas.md; measured on read_tap.lua, the same mechanism).
--
-- It was one of the ten `+1` deviants until 14z-94. The split is now pinned
-- at ZERO by tests/test_replay_stage_census.sh, which fails any new
-- instrument that copies the old flavour — that is how the drift spread:
-- one variant, then every later file copying the copy.
--
--   env POKES      "frame:addr:hexbytes;..." (same as replay.lua)
--   env BPS        "hexpc,hexpc,..." — breakpoints; each hit logs one line
--   env WINDOW     "a,b" — only log inside this frame window (bps always armed)
--   env TRACE_OUT  log path (default bp_regs.txt)
--   env REPLAY, FRAMES (default 3600), INSTR_REFERENCE, INSTR_CLOCK, ANCHOR, MASK_RANGES, ALIGN_OUT:
--       tests/lua/emu_clock.lua — the frame is an EMULATED frame since 14z-197 (GitHub #228 step 4); until
--       then this script counted frame_done calls, so each stop's UI frames moved its input early ([MFI-5])
--
-- Each hit logs: frame, PC, D0-D3, A0-A6, and the two longs at SP (a jsr'd
-- routine's return address sits at (SP) while nothing else is pushed).
-- HEARTBEAT lines fire once a second regardless of hits, so "armed but
-- idle" and "never armed" cannot look alike (the index_watch lesson).
--
-- ~~The debugger pauses emulated time during a stop, so frame-counted input
-- playback stays aligned~~ — CONTRADICTED (measured 14z-170, [CPE-5]): the frame_done
-- counter this script keyed input playback on ADVANCED on every debugger stop, so a
-- breakpoint that fired often desynced the replay (docs/platform/gotchas.md "Debugger
-- stops DESYNC replay frame counting"). FIXED 14z-197 (#228): the script now counts
-- emulated frames through tests/lua/emu_clock.lua (tests/test_emu_clock.sh section 5).
-- A stop can still move the game itself ([MFI-2]); verify the run's liveness from the
-- log's own event lines, never from a clean exit alone — and for WHEN, trust a non-debug tap.

local C = dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "emu_clock.lua"){
    name = "bp_regs", frames = 3600 }
local out_path   = os.getenv("TRACE_OUT") or "bp_regs.txt"
local wa, wb = (os.getenv("WINDOW") or "0,99999999"):match("^(%d+),(%d+)$")
wa, wb = tonumber(wa), tonumber(wb)

local machine  = manager.machine
local cpu      = machine.devices[":maincpu"]
local space    = cpu.spaces["program"]
local debugger = machine.debugger

local f = assert(io.open(out_path, "wb"))

local BPS = {}
for tok in (os.getenv("BPS") or ""):gmatch("[^,%s]+") do
    BPS[tonumber(tok, 16)] = true
end

if not debugger and not C.reference then
    f:write("# FATAL: no debugger. Run MAME with -debug -debugger none (or INSTR_REFERENCE=1 for the reference leg).\n")
    f:flush()
    return
end

if not C.reference then
    for pc in pairs(BPS) do
        debugger:command(string.format("bpset 0x%x", pc))
    end
    debugger:command("go")
end

local pokes = {}
do
    dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "pokes_spec.lua").append(pokes, os.getenv("POKES"))   -- #201: F and F1-F2 entries
end

local hits = 0
C.run{
    on_pokes = function(frame)
        for _, pk in ipairs(pokes) do
            if pk[1] == frame then
                local a = pk[2]
                for b in pk[3]:gmatch("%x%x") do
                    space:write_u8(a, tonumber(b, 16))
                    a = a + 1
                end
            end
        end
    end,
    on_end = function(frame)
        f:write(string.format("END %d hits %d\n", frame, hits))
        f:close()
    end }

emu.register_periodic(function()
    if not debugger or debugger.execution_state ~= "stop" then return end
    local frame = C.frame()
    local pc = cpu.state["CURPC"].value & 0xFFFFFF
    if not BPS[pc] then return end
    if frame >= wa and frame <= wb then
        hits = hits + 1
        local st = cpu.state
        local r = {}
        for _, n in ipairs({"D0","D1","D2","D3","A0","A1","A2","A3","A4","A6"}) do
            r[#r + 1] = n .. "=" .. string.format("%08x", st[n].value)
        end
        -- THE LIVE STACK (14z-158, docs/platform/gotchas.md): MAME 0.288's
        -- M68000 core has no "A7" state and its "SP" is the SUPERVISOR stack,
        -- so the old `A7 or SP` read the idle stack in this game's user-mode
        -- code (the 14z-85g "constant garbage ret on every hit"). Pick the
        -- live pointer from SR's S bit.
        local sp = ((st["SR"].value & 0x2000) ~= 0) and st["SP"].value or st["USP"].value
        local ok, ret = pcall(function()
            return string.format("ret=%08x,%08x", space:read_u32(sp), space:read_u32(sp + 4))
        end)
        f:write(string.format("frame %d PC %06x %s %s\n",
                frame, pc, table.concat(r, " "), ok and ret or "reterr"))
        f:flush()
    end
    debugger:command("go")
end)

local ticks, last = 0, -1
emu.register_periodic(function()
    ticks = ticks + 1
    if ticks % 600 ~= 0 then return end
    if hits == last then return end
    last = hits
    f:write(string.format("# heartbeat f%d hits=%d\n", C.frame(), hits))
    f:flush()
end)
