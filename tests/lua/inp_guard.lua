-- inp_guard.lua — crash capture for a MAME .inp PLAYBACK, cheap mode (no
-- -debug, so the playback stays faithful to the recording — GOTCHAS: -debug
-- changes scheduler timeslicing). 14z-111, written for the first natural-path
-- capture of #99 (the maintainer reproduces the crash BY HAND on merged15;
-- every scripted rig ran clean).
--
-- MECHANISM: the game's own exception handlers (vec2..vec11, PRG:0xC0-0x140)
-- begin with `move.w #code,($FF0000).l` (atlas/ram.md:86) and then soft-
-- restart. A WRITE TAP on $FF0000 fires synchronously on that store, while
-- the faulting frame is still on the stack and the registers are untouched
-- (the handler's movem comes AFTER the store). So without a debugger we get:
--   CRASH <frame> vec<n> PC <pc6> SP <sp8> ADDR <addr8>|-   (replay_guard grammar)
--   REGS D0=.. .. A6=..
--   STACK <addr> <val>            ROM-plausible longs above SP (max 16)
--   dump crash_<frame>_ff0000.bin (work RAM, 64 KiB, taken at the store)
-- Boot-time RAM tests also write $FF0000: filtered by ARM_FRAME and by the
-- value (exception codes are 0..9); filtered writes are counted, not hidden.
--
-- env CHECKSUM_OUT   log path (default inp_guard.log)
-- env ARM_FRAME      ignore writes before this frame (default 300)
-- env MAX_FRAMES     stop after this many frames (default 200000)
-- env STOP_AFTER     frames to keep running after the first crash (default 600)
-- env SELFTEST_FRAME verdict control: at this frame the script itself writes
--                    1 to $FF0000.w through the address space; the tap MUST
--                    report it as a (synthetic) CRASH or the detector is dead.
local out_path = os.getenv("CHECKSUM_OUT") or "inp_guard.log"
local arm = tonumber(os.getenv("ARM_FRAME") or "") or 300
local max_frames = tonumber(os.getenv("MAX_FRAMES") or "") or 200000
local stop_after = tonumber(os.getenv("STOP_AFTER") or "") or 600
local selftest = tonumber(os.getenv("SELFTEST_FRAME") or "")
-- env TRACE_FROM   (needs -debug -debugger none): start a 68k instruction
--                  trace at this frame, stop at the first crash. The trace is
--                  the path INTO a computed jump; cheap mode cannot see it
--                  (opcode fetches are blind to taps, RH-15). NOTE -debug
--                  perturbs timeslicing (GOTCHAS) — confirm the crash frame
--                  matches the cheap-mode capture before trusting the trace.
local trace_from = tonumber(os.getenv("TRACE_FROM") or "")
-- env WATCH  "lo-hi[,lo-hi]" hex work-RAM ranges: every WRITE is logged with
--            the writing PC into a ring (last WATCH_KEEP, default 60), flushed
--            to the log at each crash as "W <frame> PC <pc> <addr> <data>".
local watch_keep = tonumber(os.getenv("WATCH_KEEP") or "") or 60
local ring, ring_n = {}, 0
local trace_path = os.getenv("TRACE_OUT") or "inp_guard.trace"
local debugger = manager.machine.debugger
local tracing = false

local cpu = manager.machine.devices[":maincpu"]
local program = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))
local frame, crashes, filtered, stop_at = 0, 0, 0, nil

local function rom_plausible(v)
    return v >= 0x000100 and v < 0x600000 and v % 2 == 0
end

local function on_store(code)
    local st = cpu.state
    local sp = (st["SP"] or st["A7"]).value
    local vec = code + 2
    local fault_pc, fault_addr
    if vec == 2 or vec == 3 then
        fault_addr = program:read_u32(sp + 2)
        fault_pc = program:read_u32(sp + 10)
    else
        fault_pc = program:read_u32(sp + 2)
    end
    local okpc, curpc = pcall(function() return st["CURPC"].value & 0xFFFFFF end)
    f:write(string.format("CRASH %d vec%d PC %06x SP %08x ADDR %s HANDLER %s\n",
        frame, vec, fault_pc & 0xFFFFFF, sp,
        fault_addr and string.format("%08x", fault_addr) or "-",
        okpc and string.format("%06x", curpc) or "?"))
    local regs = {}
    for _, rn in ipairs({"D0","D1","D2","D3","D4","D5","D6","D7",
                         "A0","A1","A2","A3","A4","A5","A6"}) do
        local ok, v = pcall(function() return st[rn].value end)
        regs[#regs + 1] = string.format("%s=%08x", rn, ok and v or 0)
    end
    f:write("REGS " .. table.concat(regs, " ") .. "\n")
    local shown = 0
    for off = 0, 63 * 4, 4 do
        local a = sp + off
        if a >= 0xFFFFFC then break end
        local v = program:read_u32(a)
        if rom_plausible(v) then
            f:write(string.format("STACK %08x %08x\n", a, v))
            shown = shown + 1
            if shown >= 16 then break end
        end
    end
    if ring_n > 0 then
        local first = math.max(1, ring_n - watch_keep + 1)
        for i = first, ring_n do f:write(ring[i]) end
    end
    local dn = string.format("crash_%d_ff0000.bin", frame)
    local d = assert(io.open(dn, "wb"))
    local buf = {}
    for a = 0xFF0000, 0xFFFFFF, 4 do
        buf[#buf + 1] = string.pack(">I4", program:read_u32(a))
    end
    d:write(table.concat(buf)); d:close()
    f:write(string.format("DUMP %d %s\n", frame, dn))
    if tracing then
        debugger:command("trace off"); tracing = false
        f:write(string.format("TRACE %d off -> %s\n", frame, trace_path))
    end
    f:flush()
    crashes = crashes + 1
    if not stop_at then stop_at = frame + stop_after end
end

-- tap + re-install notifier (the read_tap.lua pattern: a memory-map change
-- drops taps silently; without the notifier a capture goes blind).
local tap
local function on_write(offset, data, mask)
    -- a .w store to $FF0000 arrives as one 16-bit access; the code is 0..9
    local code = data & 0xFFFF
    -- the SOFT-RESET path's abbreviated RAM test also writes 0..9 here with
    -- SP outside work RAM (measured crash_m10: SP=0 at frames 4809-4872);
    -- a real handler store has the exception frame on the work-RAM stack.
    local sp = (cpu.state["SP"] or cpu.state["A7"]).value
    if frame < arm or code > 9 or sp < 0xFF0000 or sp > 0xFFFFFF then
        filtered = filtered + 1
        return
    end
    on_store(code)
end
local wtaps = {}
local function install()
    tap = program:install_write_tap(0xFF0000, 0xFF0001, "inp_guard", on_write)
    for lo, hi in (os.getenv("WATCH") or ""):gmatch("(%x+)%-(%x+)") do
        lo, hi = tonumber(lo, 16), tonumber(hi, 16)
        wtaps[#wtaps + 1] = program:install_write_tap(lo, hi, "inp_watch_" .. lo, function(offset, data, mask)
            local ok, pc = pcall(function() return cpu.state["CURPC"].value & 0xFFFFFF end)
            ring_n = ring_n + 1
            ring[ring_n] = string.format("W %d PC %06x %06x %08x mask %08x\n", frame, ok and pc or 0, offset, data, mask)
            if ring_n > watch_keep * 2 then
                local keep = {}
                for i = ring_n - watch_keep + 1, ring_n do keep[#keep + 1] = ring[i] end
                ring, ring_n = keep, #keep
            end
        end)
    end
end
install()
program:add_change_notifier(function()
    if tap then tap:remove() end
    for _, t in ipairs(wtaps) do t:remove() end
    wtaps = {}
    install()
end)

emu.register_frame_done(function()
    frame = frame + 1
    if selftest and frame == selftest then
        f:write(string.format("SELFTEST %d writing 1 to $FF0000.w\n", frame))
        program:write_u16(0xFF0000, 1)
    end
    if trace_from and debugger and frame == trace_from then
        debugger:command("trace " .. trace_path .. ",0")
        tracing = true
        f:write(string.format("TRACE %d on -> %s\n", frame, trace_path))
    end
    if frame % 600 == 0 then
        f:write(string.format("ALIVE %d match=%08x p1=%02x p2=%02x\n", frame,
            program:read_u32(0xFF8004), program:read_u8(0xFF8400 + 2), program:read_u8(0xFF8800 + 2)))
        f:flush()
    end
    if (stop_at and frame >= stop_at) or frame >= max_frames then
        f:write(string.format("END %d crashes=%d filtered_writes=%d\n", frame, crashes, filtered))
        f:close()
        manager.machine:exit()
    end
end)
