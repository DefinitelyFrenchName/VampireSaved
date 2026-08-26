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
    local dn = string.format("crash_%d_ff0000.bin", frame)
    local d = assert(io.open(dn, "wb"))
    local buf = {}
    for a = 0xFF0000, 0xFFFFFF, 4 do
        buf[#buf + 1] = string.pack(">I4", program:read_u32(a))
    end
    d:write(table.concat(buf)); d:close()
    f:write(string.format("DUMP %d %s\n", frame, dn))
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
    if frame < arm or code > 9 then
        filtered = filtered + 1
        return
    end
    on_store(code)
end
local function install()
    tap = program:install_write_tap(0xFF0000, 0xFF0001, "inp_guard", on_write)
end
install()
program:add_change_notifier(function()
    if tap then tap:remove() end
    install()
end)

emu.register_frame_done(function()
    frame = frame + 1
    if selftest and frame == selftest then
        f:write(string.format("SELFTEST %d writing 1 to $FF0000.w\n", frame))
        program:write_u16(0xFF0000, 1)
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
