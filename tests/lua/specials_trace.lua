-- specials_trace.lua — tests/lua/field_trace.lua's per-frame field log ON THE SHARED EMULATED-FRAME CLOCK
-- (tests/lua/emu_clock.lua, #228 option A), plus a TICK TAP: one line per engine tick of P1's animation
-- (GitHub #229, 14z-205, fork F1: tests/audit_vanilla_specials_a.sh).
--
-- WHY A NEW INSTRUMENT. field_trace.lua counts frame_done calls and writes no ALIGN line, so a gate built on it
-- cannot hold its legs to a frozen game clock (#228 option A) and has no staging reference leg; and it samples once
-- per VIDEO frame, while ~16-30% of frames run a second logic pass (the speed level's pattern, engine_internals),
-- so frame counts cannot carry the cross-check's startup/active/recovery, which are ENGINE TICKS. field_trace.lua is
-- not edited (the #229 parallel run's brief: new files only).
--
-- THE FIELD LOG is field_trace.lua's, byte for byte: "F <frame> <name>=<value> ..." for each frame in
-- [FIELD_FROM, FIELD_TO], words and longs read signed, then "FIELDSUMMARY frames=<n>". The frame is emu_clock's
-- (the screen's frame number moved; the first frame_done counts), the pokes are applied first (on_pokes), the
-- fields are read in on_frame — the same values field_trace.lua reads, since staging the next frame's input moves
-- no RAM (measured: tests/audit_vanilla_specials_a.sh section 0 holds this trace equal to field_trace.lua's).
--
-- THE TICK TAP (TICK_TAP="ff8420"; TICK_MODE=mask, the default, or pc with TICK_PC="027f70"): a MEMORY write tap over
-- the even, word-aligned word at
-- TICK_TAP (a 1-byte tap on this 16-bit bus reads a clean zero — docs/platform/gotchas.md), no debugger, so no
-- stop and nothing moves the game. A write by the instruction at TICK_PC — vsavj's `subq.b #1,$20(a6)`, ONE
-- engine tick of the animation countdown (engine_internals "THE ENGINE TICK IS DIRECTLY OBSERVABLE";
-- tests/test_tick_durations.sh) — logs "T <frame> <node>", the node pointer +0x1C at the write. TICK_MODE=mask takes
-- the tick as a BYTE write to the countdown (mask 0xff00 on the word: `subq.b`; the node install reloads the word,
-- mask 0xffff — measured raw, 14z-205) and reads no CPU state; TICK_MODE=pc takes it as a write by TICK_PC. The two
-- give byte-identical tick lines (AN's rig: 4,775 of 4,775; the gate's ground truth runs it every time), but reading
-- cpu.state inside the tap crashed MAME at teardown (exit 139, after every output was written) on 8 of the 13 rigs,
-- so mask is the default and pc is the ground truth only. The tap is
-- re-installed on every write-handler change of the space (CPS-2 re-installs handlers after boot and a
-- passthrough tap is dropped silently — tests/lua/tap_writes.lua's paid gotcha). A reference leg (INSTR_REFERENCE=1)
-- installs no tap and logs no field, so its anchor is replay.lua's own game.
--
--   env FIELDS, FIELD_OUT, FIELD_FROM, FIELD_TO   as field_trace.lua
--   env REPLAY, FRAMES, POKES, ANCHOR, ALIGN_OUT, INSTR_REFERENCE, INSTR_CLOCK   as emu_clock.lua / replay_guard.lua
--   env TICK_TAP, TICK_MODE (mask|pc), TICK_PC   the tick tap
local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
local clock = dofile(here .. "emu_clock.lua")
local C = clock{ name = "specials_trace", frames = 3600 }

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

local fields = {}
for spec in (os.getenv("FIELDS") or ""):gmatch("[^,]+") do
    local a, sz, name = spec:match("^%s*(%x+):([bwl]):(%S+)%s*$")
    assert(a, "FIELDS entry must be addr:size:name — got '" .. spec .. "'")
    fields[#fields + 1] = { addr = tonumber(a, 16), size = sz, name = name }
end
local win_lo = tonumber(os.getenv("FIELD_FROM") or "") or 0
local win_hi = tonumber(os.getenv("FIELD_TO") or "") or math.huge
local out_path = os.getenv("FIELD_OUT") or "specials_trace.txt"
local f = (not C.reference) and assert(io.open(out_path, "wb")) or nil
local logged = 0

local pokes = {}
dofile(here .. "pokes_spec.lua").append(pokes, os.getenv("POKES"))

local function read_field(fd)
    if fd.size == "b" then return mem:read_u8(fd.addr) end
    if fd.size == "w" then
        local v = mem:read_u16(fd.addr)
        return v >= 0x8000 and v - 0x10000 or v
    end
    local v = mem:read_u32(fd.addr)
    return v >= 0x80000000 and v - 0x100000000 or v
end

-- the tick tap
local tick_tap, tick_pc = os.getenv("TICK_TAP"), os.getenv("TICK_PC")
local tick_mode = os.getenv("TICK_MODE") or "mask"
assert(tick_mode == "mask" or tick_mode == "pc", "TICK_MODE must be mask or pc")
assert(tick_mode ~= "pc" or (tick_tap and tick_pc), "TICK_MODE=pc needs TICK_TAP and TICK_PC")
local ticks = 0
local tap, notifier, done = nil, nil, false   -- held for the run's whole life
local node = 0                                 -- P1's node pointer +0x1C, tracked by the tap from the game's writes
if f and tick_tap then
    local ta = tonumber(tick_tap, 16); local tp = tick_pc and tonumber(tick_pc, 16)
    assert(ta % 2 == 0, "TICK_TAP must be even and word-aligned")
    -- THE NODE POINTER IS TRACKED, NEVER READ: the tap covers TICK_TAP-4 .. TICK_TAP+1 (+0x1C, +0x1E, +0x20) and
    -- follows the words the game WRITES to +0x1C/+0x1E (each report a 16-bit word, the mask selecting the bytes —
    -- measured raw, 14z-205). Reading the pointer instead crashed MAME at teardown (exit 139) on every run, though
    -- every line logged was right: a read_u32/read_direct_u32 inside the tap, and equally a per-frame read of the
    -- tapped words from the first frame on (the boot frames, while CPS-2 re-installs handlers); the tracked pointer
    -- gives the same 2,960 tick lines as the read on JE's rig and the run exits 0 (bisected 14z-205).
    local installing = false
    local function install()
        installing = true
        tap = mem:install_write_tap(ta - 4, ta + 1, "specials_tick", function(offset, data, mask)
            if done then return end
            local m, d = mask & 0xffff, data & 0xffff
            if offset == ta - 4 then
                local hi = (((node >> 16) & 0xffff) & ~m) | (d & m)
                node = (hi << 16) | (node & 0xffff)
            elseif offset == ta - 2 then
                node = (node & 0xffff0000) | (((node & 0xffff) & ~m) | (d & m))
            elseif offset == ta and ((tick_mode == "mask" and m == 0xff00) or (tick_mode == "pc" and cpu.state["CURPC"].value == tp)) then
                -- the write lands inside the logic of the frame AFTER the last one counted (C.frame() moves at
                -- frame_done), so the tick is labelled C.frame() + 1 — the frame whose field line shows its result
                f:write(string.format("T %d %d\n", C.frame() + 1, node))
                ticks = ticks + 1
            end
        end)
        installing = false
    end
    install()
    notifier = mem:add_change_notifier(function(mode)
        if not done and not installing and mode:find("w") then install() end
    end)
end

C.run{
    on_pokes = function(frame)
        for _, pk in ipairs(pokes) do
            if pk[1] == frame then
                local a = pk[2]
                for b in pk[3]:gmatch("%x%x") do mem:write_u8(a, tonumber(b, 16)); a = a + 1 end
            end
        end
    end,
    on_frame = function(frame)
        if f and frame >= win_lo and frame <= win_hi then
            local parts = { string.format("F %d", frame) }
            for _, fd in ipairs(fields) do parts[#parts + 1] = string.format("%s=%d", fd.name, read_field(fd)) end
            f:write(table.concat(parts, " ") .. "\n")
            logged = logged + 1
        end
    end,
    on_end = function(frame)
        done = true
        -- the tap and the notifier are LEFT installed (tests/lua/tap_writes.lua's shape, which exits clean); the
        -- `done` flag silences them from here
        if f then
            f:write(string.format("FIELDSUMMARY frames=%d\n", logged))
            if tick_tap then f:write(string.format("TICKSUMMARY ticks=%d\n", ticks)) end
            f:close()
        end
    end,
}
