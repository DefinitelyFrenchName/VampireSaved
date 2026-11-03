-- class72_tap.lua — EVERY LIVE CLASS-0x72 EFFECT PIECE, with the record its node points at and that record's format word
-- (14z-219, GitHub #345 option A1b / #346; promoted from the census probe build/agent219/t345/lua/c72_tap.lua). Used by
-- tests/audit_don_trail_nodraw.sh. No debugger. At the end of every frame from SFROM to FRAMES it writes:
--   P <fr> seq sub x y   P1 (RAM:$FF8400): state, sub-state, x, y
--   K <fr> <slot> <type> <sub> <state> node=<+0x1C> rec=<[node+4]> fmt=<[rec].w, decimal> own=<+0x30>
--        every live slot of the effect-piece pool RAM:$FFB800 (32 x $80) whose TYPE byte (+0x02) is in TYPES
--   OPATCH <spec> readback <long>   when OPATCH is set
--   END <fr>
-- env SOUT, POKES (tests/lua/pokes_spec.lua grammar), SFROM (default 2300), FRAMES, REPLAY (driven by the clock),
--     TYPES (hex list, default "72"), OPATCH "hexaddr:hexbytes" written once at frame 1 into the board's
--     DECRYPTED-OPCODE share (the emulator only, nothing built; the gate's known-bad leg puts one operand back).
-- WHAT IT CANNOT SEE: pixels; reads of the anim table (the census's read tap, build/agent219/t345/, is not promoted).
local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
local clock = dofile(here .. "emu_clock.lua")
local C = clock{ name = "class72_tap", frames = 9000 }
local pokes = dofile(here .. "pokes_spec.lua").append({}, os.getenv("POKES"))
local byf = {}
for _, p in ipairs(pokes) do byf[p[1]] = byf[p[1]] or {}; table.insert(byf[p[1]], p) end
local machine = manager.machine
local sp = machine.devices[":maincpu"].spaces["program"]
local SF = tonumber(os.getenv("SFROM") or "2300")
local TYPES = {}
for x in (os.getenv("TYPES") or "72"):gmatch("%x+") do TYPES[tonumber(x, 16)] = true end
local out = assert(io.open(assert(os.getenv("SOUT"), "SOUT"), "w"))
local opatch = os.getenv("OPATCH"); if opatch == "" then opatch = nil end
local function b(a) return sp:read_u8(a) end
local function w(a) return sp:read_u16(a) end
local function l(a) return sp:read_u32(a) end
C.run{
    on_pokes = function(fr)
        if opatch and fr == 1 then
            local sh = assert(machine.memory.shares[":decrypted_opcodes"], "no :decrypted_opcodes share")
            local pa, pb = opatch:match("^(%x+):(%x+)$")
            local a = tonumber(pa, 16)
            for h in pb:gmatch("%x%x") do sh:write_u8(a, tonumber(h, 16)); a = a + 1 end
            out:write(string.format("OPATCH %s readback %04x%04x\n", opatch, sh:read_u16(tonumber(pa, 16)),
                sh:read_u16(tonumber(pa, 16) + 2)))
        end
        for _, pk in ipairs(byf[fr] or {}) do
            local a = pk[2]
            for h in pk[3]:gmatch("%x%x") do sp:write_u8(a, tonumber(h, 16)); a = a + 1 end
        end
    end,
    on_frame = function(fr)
        if fr < SF then return end
        out:write(string.format("P %d %02x %02x %04x %04x\n", fr, b(0xff8406), b(0xff8407), w(0xff8410), w(0xff8414)))
        for k = 0, 31 do
            local a = 0xffb800 + k * 0x80
            local t = b(a + 2)
            if b(a) ~= 0 and TYPES[t] then
                local nd = l(a + 0x1c) & 0xffffff
                local rec = (nd ~= 0) and (l(nd + 4) & 0xffffff) or 0
                local fmt = (rec ~= 0) and w(rec) or -1
                out:write(string.format("K %d %02d %02x %02x %02x node=%06x rec=%06x fmt=%d own=%04x\n", fr, k, t,
                    b(a + 3), b(a + 4), nd, rec, fmt, w(a + 0x30)))
            end
        end
    end,
    on_end = function(fr) out:write(string.format("END %d\n", fr)); out:close() end }
