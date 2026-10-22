-- sheet_tap_capture.lua — re-run one leg of a TAP gate under the gate's OWN instrument and photograph it at the gate's
-- moments (14z-205, GitHub #291 D2, ruled 2026-10-18 "EVENT-PROVEN basis (D2)"; driven by tools/proof_sheets.py).
--
-- WHY. A tap gate (read_tap.lua, ring_tap.lua, qs_sweep.lua, obj_records_dump.lua, …) logs events, not work RAM, so
-- the checksum proof of tests/lua/sheet_capture.lua has nothing to compare against. This wrapper loads the gate's own
-- instrument with the gate's own environment — the instrument stages the replay's inputs, applies its pokes, taps and
-- writes its log exactly as in the gate — and only adds a snapshot at SNAP_FRAMES. tools/proof_sheets.py then compares
-- the re-run's log with the gate's, line for line, inside a window around each moment: EVENT-PROVEN, a status of its
-- own, weaker than a checksum (it proves the tapped history in that window, not the rest of work RAM).
--
-- Measured 14z-205 (build/agent205/d2/, local): read_tap.lua on 02_demitri_vs_cpu wrapped and plain wrote byte-identical
-- logs (69 lines), and the wrapper's f2050 snapshot is pixel-identical to tests/lua/sheet_capture.lua's f2050 and
-- differs from its f2049 and f2051 — the frame count is replay.lua's. tests/test_proof_sheets.sh section 6 holds it.
--
--   env TAP_SCRIPT   the instrument to load (a path); its own env (REPLAY, POKES, FRAMES, TRACE_OUT, RTAP, …) is set
--                    by the caller exactly as the gate set it
--   env SNAP_FRAMES  comma-separated frames to photograph
--   env WRAP_OUT     where to write `S <n> <frame>` (MAME's snapshot number n, in the order taken) and, before each,
--                    tests/lua/screen_state.lua's `R <frame> ...` line (#291 S4-B)
-- The instrument's frame_done is registered first (dofile), this one after it, so a snapshot of frame N is taken after
-- the instrument's frame-N work; the instrument ends the run (machine:exit) at its own FRAMES.

local want, taken, frame = {}, 0, 0
local screen_state = dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "screen_state.lua")
local space = manager.machine.devices[":maincpu"].spaces["program"]
for tok in (os.getenv("SNAP_FRAMES") or ""):gmatch("[^,%s]+") do want[tonumber(tok)] = true end
local out = assert(io.open(assert(os.getenv("WRAP_OUT"), "set WRAP_OUT"), "w"))
dofile(assert(os.getenv("TAP_SCRIPT"), "set TAP_SCRIPT"))
emu.register_frame_done(function()
    frame = frame + 1
    if want[frame] then
        out:write(screen_state.line(space, frame))   -- #291 S4-B: what the picture shows
        manager.machine.video:snapshot()
        out:write(string.format("S %d %d\n", taken, frame)); out:flush()
        taken = taken + 1
    end
end)
