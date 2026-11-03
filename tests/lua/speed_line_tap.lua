-- speed_line_tap.lua — THE EFFECT-PIECE POOL, every frame, with every speed-line piece in full (14z-219, GitHub #356;
-- promoted from the #356 census probe build/agent218/tspeed/lua/speed_tap.lua). Used by tests/audit_don_speed_lines.sh.
-- No debugger. At the end of every frame from SFROM to FRAMES it writes:
--   P <fr> seq sub x y face | seq sub x y id=<p1>/<p2>   P1 (RAM:$FF8400) and P2 (RAM:$FF8800): state, sub-state, x, y,
--        P1's facing byte, and both ids (+0x382)
--   T <fr> <slot>:<type>:<sub>:<vis> ...   every live slot of the effect-piece pool RAM:$FFB800 (32 x $80)
--   S <fr> <slot> hdr x y sub i own st t26 node   every live slot whose TYPE byte (+0x02) is one of STYPES: the header
--        long, world x/y (+0x10/+0x14), sub (+0x03), piece index (+0x38), owner (+0x30), state (+0x04), timer (+0x26)
--        and anim node (+0x1C); vis = header byte +0x01, the on-screen flag the cull routine writes
--   OPATCH <spec> readback <long>   when OPATCH is set
--   END <fr>
-- env SOUT (out file), POKES (tests/lua/pokes_spec.lua grammar), SFROM (default 2300), FRAMES, REPLAY (driven by the
--     clock), STYPES (hex list, default "0f,7c": the shared speed-line class and Donovan's own copy, type 124),
--     OPATCH "hexaddr:hexbytes" written once at frame 1 into the board's DECRYPTED-OPCODE share (the emulator only,
--     nothing built) — the gate's known-bad leg puts a jmp operand back.
-- WHAT IT CANNOT SEE: pixels (the gate's pictures are a separate step), pieces of other types except as T entries.
local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
local clock = dofile(here .. "emu_clock.lua")
local C = clock{ name = "speed_line_tap", frames = 9000 }
local pokes = dofile(here .. "pokes_spec.lua").append({}, os.getenv("POKES"))
local byf = {}
for _, p in ipairs(pokes) do byf[p[1]] = byf[p[1]] or {}; table.insert(byf[p[1]], p) end
local machine = manager.machine
local sp = machine.devices[":maincpu"].spaces["program"]
local SF = tonumber(os.getenv("SFROM") or "2300")
local TYPES = {}
for t in (os.getenv("STYPES") or "0f,7c"):gmatch("[^,]+") do TYPES[tonumber(t, 16)] = true end
local out = assert(io.open(assert(os.getenv("SOUT"), "SOUT"), "w"))
local opatch = os.getenv("OPATCH"); if opatch == "" then opatch = nil end
local function w(a) return sp:read_u16(a) end
local function b(a) return sp:read_u8(a) end
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
        out:write(string.format("P %d %02x %02x %04x %04x %02x | %02x %02x %04x %04x id=%02x/%02x\n", fr, b(0xff8406),
            b(0xff8407), w(0xff8410), w(0xff8414), b(0xff840b), b(0xff8806), b(0xff8807), w(0xff8810), w(0xff8814),
            b(0xff8782), b(0xff8b82)))
        local t = {}
        for k = 0, 31 do
            local a = 0xffb800 + k * 0x80
            if b(a) ~= 0 then
                t[#t + 1] = string.format("%02d:%02x:%02x:%d", k, b(a + 2), b(a + 3), b(a + 1))
                if TYPES[b(a + 2)] then
                    out:write(string.format("S %d %02d hdr=%08x x=%04x y=%04x sub=%02x i=%02x own=%04x st=%02x t26=%02x node=%06x\n",
                        fr, k, sp:read_u32(a), w(a + 0x10), w(a + 0x14), b(a + 3), b(a + 0x38), w(a + 0x30), b(a + 4),
                        b(a + 0x26), sp:read_u32(a + 0x1c) & 0xffffff))
                end
            end
        end
        out:write("T " .. fr .. " " .. table.concat(t, " ") .. "\n")
    end,
    on_end = function(fr) out:write(string.format("END %d\n", fr)); out:close() end }
