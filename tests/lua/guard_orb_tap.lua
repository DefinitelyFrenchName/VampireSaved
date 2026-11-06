-- guard_orb_tap.lua (14z-221c, #357: Donovan's guard orbs). Non-debug, every frame SFROM..STO, one line per frame:
--   F <fr> p1seq=<$FF8406> p1sub=<$FF8407>
-- then one line per live slot of the effect-piece pool RAM:$FFB800 (32 slots x $80) whose type byte +0x02 is 0x72:
--   O <fr> <slot> sub=<+0x03> vis=<+0x01> x=<+0x10 w> y=<+0x14 w>
-- and `END <fr>` after the last frame. A slot is live when its header byte +0x00 is non-zero. vis is the on-screen cull
-- flag (01 = drawn). POKES (tests/lua/pokes_spec.lua) are applied each frame before the read. Used by
-- tests/audit_guard_orbs.sh; from the 14z-219 scratch tap build/agent219/t357/lua/piece_tap.lua (its T and S lines).
local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
local clock = dofile(here .. "emu_clock.lua")
local C = clock{ name = "guard_orb_tap", frames = 9000 }
local pokes = dofile(here .. "pokes_spec.lua").append({}, os.getenv("POKES"))
local byf = {}
for _, p in ipairs(pokes) do byf[p[1]] = byf[p[1]] or {}; table.insert(byf[p[1]], p) end
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local SF = tonumber(os.getenv("SFROM") or "2300"); local STO = tonumber(os.getenv("STO") or "7240")
local out = assert(io.open(assert(os.getenv("SOUT")), "w"))
local function b(a) return sp:read_u8(a) end
local function w(a) return sp:read_u16(a) end
C.run{
    on_pokes = function(fr)
        for _, pk in ipairs(byf[fr] or {}) do
            local a = pk[2]
            for h in pk[3]:gmatch("%x%x") do sp:write_u8(a, tonumber(h, 16)); a = a + 1 end
        end
    end,
    on_frame = function(fr)
        if fr < SF or fr > STO then return end
        out:write(string.format("F %d p1seq=%02x p1sub=%02x\n", fr, b(0xff8406), b(0xff8407)))
        for s = 0, 31 do
            local o = 0xffb800 + s * 0x80
            if b(o) ~= 0 and b(o + 2) == 0x72 then
                out:write(string.format("O %d %02d sub=%02x vis=%02x x=%04x y=%04x\n", fr, s, b(o + 3), b(o + 1),
                    w(o + 0x10), w(o + 0x14)))
            end
        end
    end,
    on_end = function(fr) out:write(string.format("END %d\n", fr)); out:close() end }
