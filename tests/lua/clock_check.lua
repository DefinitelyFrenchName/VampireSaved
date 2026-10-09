-- clock_check.lua — DID THIS RUN'S frame_done CLOCK STAY ON EMULATED TIME? (14z-196, GitHub #228)
--
-- WHY. A CPU held at a debugger breakpoint or watchpoint keeps MAME emitting UI frames, so
-- frame_done keeps firing while emulated time stands still ([MFI-5], docs/platform/gotchas.md
-- "PAID AGAIN, and MEASURED, 14z-192 (GitHub #213)"). An instrument that counts frame_done
-- calls as frames then stages its replay input early and stops before the replay's end — the
-- dispatch census covered 4,202 of the 40,620 frames it counted. This helper measures that per
-- run, for ANY instrument, without touching how the instrument counts.
--
-- USE. An instrument loads it with one line BEFORE it registers its own frame_done handler:
--   dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "clock_check.lua")("<name>", replay_path)
-- It does nothing unless
--   env CLOCK_OUT  a file path: at machine stop, ONE line is APPENDED (legs running in parallel
--                  may share the file):
--     CLOCKCHECK <name> <the replay path the instrument passed, or -> calls <frame_done calls> emulated <emulated frames>
--                uiframes <frame_done calls with no emulated frame> gameclock <RAM:$FF8080>
-- `emulated` is the screen's frame-number delta +1 (the first frame_done precedes the first
-- move, as tests/lua/dispatch_census.lua counts it); `uiframes` = calls - emulated is how far a
-- frame_done-keyed counter ran ahead of emulated time by the end of the run. 0 = no drift.
--
-- WHAT IT CANNOT SEE: whether a stop moved the GAME itself ([MFI-2]: the 68k/sound-CPU
-- interleaving) — that needs a reference leg without the debugger, as #213's method has; and a
-- run that never reaches machine stop (killed by a timeout) writes no line, which the reader
-- must count as missing, never as clean.
return function(name, replay)
    local out = os.getenv("CLOCK_OUT")
    if not out or out == "" then return end
    local machine = manager.machine
    local screen = assert(machine.screens[":screen"], "clock_check: no :screen device")
    local program = machine.devices[":maincpu"].spaces["program"]
    local fn0 = screen:frame_number()
    local calls = 0
    emu.register_frame_done(function() calls = calls + 1 end)
    -- kept in a global so the subscription is not collected
    __clock_check_sub = emu.add_machine_stop_notifier(function()
        local emulated = screen:frame_number() - fn0 + 1
        local f = io.open(out, "a")
        if f then
            f:write(string.format("CLOCKCHECK %s %s calls %d emulated %d uiframes %d gameclock %02x\n",
                name, replay or "-", calls, emulated, calls - emulated,
                program:read_u8(0xff8080)))
            f:close()
        end
    end)
end
