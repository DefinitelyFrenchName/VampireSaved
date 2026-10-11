-- obj_record_full_trace.lua — log EVERY OBJ record draw (all six format
-- handlers) in a frame window: record addr, format, object, bank, and
-- the record's first entry tile words. Companion to
-- obj_record_bank_trace.lua for "which record draws code X?" questions
-- (session 14o blink diagnosis).
--
-- Handlers (jump table 0x1AFBA, word offsets; decoded from the opcode
-- dump): fmt0 0x1AFC6, fmt2 0x1B234, fmt4 0x1B61A, fmt6 0x1B6AA,
-- fmt8 0x1B73E, fmtA 0x1B7CC. Dispatch is `movea.l 4(a0),a0;
-- move.w (a0)+,d0` — at every handler A0 = record+2.
--
--   env TRACE_OUT   log path (default obj_record_full.txt)
--   env WIN_LO/WIN_HI  frame window to log (default 2590/2615)
--   env REPLAY, FRAMES (default WIN_HI+5), INSTR_REFERENCE, INSTR_CLOCK, ANCHOR, MASK_RANGES, ALIGN_OUT:
--       tests/lua/emu_clock.lua — the frame is an EMULATED frame since 14z-197 (GitHub #228 step 4); until
--       then this script counted frame_done calls, so each stop's UI frames moved its input early and its
--       window early ([MFI-5])
--   env HANDLERS    override handler map "fmt:hexpc,..." (default the
--                   vsavj addresses; vsav2 sibling:
--                   "0:199f6,2:19c64,4:1a04a,6:1a0da,8:1a16e,10:1a236")

local win_lo = tonumber(os.getenv("WIN_LO") or "") or 2590
local win_hi = tonumber(os.getenv("WIN_HI") or "") or 2615
local C = dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "emu_clock.lua"){
    name = "obj_record_full_trace", frames = win_hi + 5 }
local out_path = os.getenv("TRACE_OUT") or "obj_record_full.txt"

local machine = manager.machine
local debugger = machine.debugger
assert(debugger or C.reference, "run mame with -debug (or INSTR_REFERENCE=1 for the reference leg)")
local cpu = machine.devices[":maincpu"]
local prog = cpu.spaces["program"]

local f = assert(io.open(out_path, "wb"))

local HANDLERS = { [0x1afc6]=0, [0x1b234]=2, [0x1b61a]=4,
                   [0x1b6aa]=6, [0x1b73e]=8, [0x1b7cc]=10 }
local hspec = os.getenv("HANDLERS")
if hspec then
    HANDLERS = {}
    for fmt, pc in hspec:gmatch("(%d+):(%x+)") do
        HANDLERS[tonumber(pc, 16)] = tonumber(fmt)
    end
end
if not C.reference then
    debugger:command("focus 0")
    for pc in pairs(HANDLERS) do
        debugger:command(string.format("bpset %x", pc))
    end
end

C.run{ on_end = function(frame)
    f:write(string.format("END %d\n", frame))
    f:close()
end }

emu.register_periodic(function()
    if debugger and debugger.execution_state == "stop" then
        local frame = C.frame()
        if frame >= win_lo and frame <= win_hi then
            local st = cpu.state
            local a0 = st["A0"].value & 0xffffff
            local a6 = st["A6"].value & 0xffffff
            local pc = st["CURPC"].value & 0xffffff
            local fmt = HANDLERS[pc] or -1
            local rec = a0 - 2
            local bank = prog:read_u16(a6 + 0x18)
            -- entry tile words per format layout (rec base offsets)
            local tiles = {}
            if fmt == 0 then
                local cnt = prog:read_u16(rec + 2)
                for k = 0, math.min(cnt - 1, 11) do
                    tiles[#tiles + 1] = string.format("%04x",
                        prog:read_u16(rec + 10 + 2 * k))
                end
            elseif fmt >= 2 then
                local cnt = prog:read_u16(rec + 4)
                for k = 0, math.min(cnt, 11) do
                    tiles[#tiles + 1] = string.format("%04x",
                        prog:read_u16(rec + 10 + 4 * k))
                end
            end
            local cur = prog:read_u32(a6 + 0x1c) & 0xffffff
            local ctx = {}
            for k = -2, 3 do
                ctx[#ctx + 1] = string.format("%08x",
                    prog:read_u32(cur + 4 * k))
            end
            f:write(string.format(
                "F %d REC %06x FMT %d OBJ %06x BANK %04x CUR %06x CTX %s T %s\n",
                frame, rec, fmt, a6, bank, cur, table.concat(ctx, ","),
                table.concat(tiles, ",")))
        end
        debugger.execution_state = "run"
    end
end)
