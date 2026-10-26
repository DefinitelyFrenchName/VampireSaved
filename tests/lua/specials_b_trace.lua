-- specials_b_trace.lua — the vanilla specials rig's instrument (F2's half; named _b because fork F1 wrote its own
-- tests/lua/specials_trace.lua over this file's first copy mid-run) (GitHub #229, 14z-205, fork F2): named RAM fields per
-- EMULATED frame, and, under -debug, a TICK-ACCURATE write tap on the walker's node timer +0x20.
--
-- WHY A NEW INSTRUMENT. tests/lua/field_trace.lua counts frame_done calls; the #228 ruling (option A, maintainer
-- 2026-10-10) puts every leg of a gate on the emulated-frame clock (tests/lua/emu_clock.lua) so it can be held to a
-- frozen game clock and a staging reference leg (tests/lib/instr_align.sh). And the specials' timing columns need
-- ENGINE TICKS, which a per-frame sample reads +-1 at each boundary (a double-pass frame hides a tick): the timer
-- +0x20 is written ONCE PER TICK by the walker (docs/game/engine_internals.md "THE ENGINE TICK IS DIRECTLY
-- OBSERVABLE": PRG:0x027F70 subq = one tick, PRG:0x027EEC move.l = node entry, PRG:0x027F88 st.b +0x21 = not the
-- timer), so a write tap is the tick-accurate re-check. A tap is a -debug breakpoint leg: the #228 class this file
-- exists to put on the frozen clock.
--
-- ENV
--   FIELDS      "addr:size:name,..." as field_trace.lua (b/w/l; words and longs read SIGNED)
--   FIELD_OUT   the per-frame sample file (default specials_b_trace.txt): "F <frame> name=value ..."
--   TRACE_OUT   the tap file (default: FIELD_OUT .. ".tap"): "T <frame> <pc> <object> <node> <timer>" per write,
--               then "END <frame> hits <n>"
--   TAP_FROM    arm the tap at this frame instead of at load (see below)
--   TAP_PASS    0 = no pass-counter tap (default on: every write to the word $FF8080, the pass counter's PC among them)
--   TAP         the objects whose +0x20 is tapped: "ff8400" (P1) and/or the projectile slots, comma separated
--               (default "ff8400,ff9400,ff9500,ff9600,ff9700"); ignored by a reference leg, which arms nothing
--   REPLAY FRAMES POKES INSTR_REFERENCE INSTR_CLOCK ANCHOR MASK_RANGES ALIGN_OUT — tests/lua/emu_clock.lua's
--
-- ORDER WITHIN A FRAME (emu_clock.lua's, replay.lua's): the POKES, the anchor, then the sample — the same settled
-- state field_trace.lua samples (it pokes, stages the next input, samples; staging writes no RAM).
local C = dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "emu_clock.lua"){
    name = "specials_b_trace", frames = 3600 }
local machine = manager.machine
local debugger = machine.debugger
local cpu = machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

local fields = {}
for spec in assert(os.getenv("FIELDS"), "set FIELDS"):gmatch("[^,]+") do
    local a, sz, name = spec:match("^%s*(%x+):([bwl]):(%S+)%s*$")
    assert(a, "FIELDS entry must be addr:size:name — got '" .. spec .. "'")
    fields[#fields + 1] = { addr = tonumber(a, 16), size = sz, name = name }
end
local function read_field(fd)
    if fd.size == "b" then return mem:read_u8(fd.addr) end
    if fd.size == "w" then local v = mem:read_u16(fd.addr); return v >= 0x8000 and v - 0x10000 or v end
    local v = mem:read_u32(fd.addr); return v >= 0x80000000 and v - 0x100000000 or v
end
local fpath = os.getenv("FIELD_OUT") or "specials_b_trace.txt"
local f = assert(io.open(fpath, "wb"))
local t = assert(io.open(os.getenv("TRACE_OUT") or (fpath .. ".tap"), "wb"))
local hits = 0

local pokes = {}
dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "pokes_spec.lua").append(pokes, os.getenv("POKES"))

local tap_from = tonumber(os.getenv("TAP_FROM") or "")
local function arm()
    if C.reference then return end
    assert(debugger, "the tap needs -debug (or INSTR_REFERENCE=1 for a reference leg)")
    debugger:command("focus 0")
    -- THE PASS TAP (on unless TAP_PASS=0): the word $FF8080-$FF8081 — the game task's pass counter $FF8081 is written
    -- once per logic pass (vsavj PRG:0x008E10 addq.b #1,$81(a5), atlas/ram.md), so every other hit in the ONE ordered
    -- tap stream gets an exact pass index. Measured 14z-205 on Morrigan: P1's walker writes 4-10 ticks FEWER than the
    -- engine runs passes over an event (it skips passes on holds), so P1's own tick-writes cannot be the clock.
    if os.getenv("TAP_PASS") ~= "0" then debugger:command("wpset ff8080,2,w") end
    for obj in (os.getenv("TAP") or "ff8400,ff9400,ff9500,ff9600,ff9700"):gmatch("%x+") do
        -- +0x20 and +0x21 share a word: the st.b at PRG:0x027F88 also hits; the analysis keeps the timer's two PCs
        debugger:command(string.format("wpset %x,2,w", tonumber(obj, 16) + 0x20))
    end
end
-- TAP_FROM=<frame> arms the tap at that frame instead of at load. MEASURED 14z-205: a tap armed at load left
-- replay.lua's timeline at frame 15 (its per-frame samples against the INSTR_REFERENCE leg's, Q-Bee's rig) while the
-- game clock still read the same byte at the end ([MFI-2]: a stop can move the game, the clock cannot see it).
if not tap_from then arm() end

C.run{
    on_pokes = function(frame)
        if tap_from and frame == tap_from then arm(); t:write(string.format("ARMED %d\n", frame)) end
        for _, pk in ipairs(pokes) do
            if pk[1] == frame then
                local a = pk[2]
                for b in pk[3]:gmatch("%x%x") do mem:write_u8(a, tonumber(b, 16)); a = a + 1 end
            end
        end
    end,
    on_frame = function(frame)
        local parts = { string.format("F %d", frame) }
        for _, fd in ipairs(fields) do parts[#parts + 1] = string.format("%s=%d", fd.name, read_field(fd)) end
        f:write(table.concat(parts, " ") .. "\n")
    end,
    on_end = function(frame)
        f:write(string.format("FIELDSUMMARY frames=%d\n", frame)); f:close()
        t:write(string.format("END %d hits %d\n", frame, hits)); t:close()
    end,
}

emu.register_periodic(function()
    if debugger and debugger.execution_state == "stop" then
        local st = cpu.state
        local a6 = st["A6"].value
        t:write(string.format("T %d %06x %06x %08x %02x\n", C.frame(), st["CURPC"].value, a6 & 0xFFFFFF,
                              mem:read_u32((a6 & 0xFFFFFF) + 0x1C), mem:read_u8((a6 & 0xFFFFFF) + 0x20)))
        hits = hits + 1
        debugger.execution_state = "run"
    end
end)
