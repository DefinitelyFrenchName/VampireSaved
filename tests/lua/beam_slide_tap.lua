-- beam_slide_tap.lua (14z-221, #363: the victim's pushback slide under Phobos's ES Plasma Beam). Non-debug, every frame
-- SFROM..STO, one line:
--   P <fr> p1x=<$FF8410> x=<$FF8810> y=<$FF8814> seq=<+06> sub=<+07> s59=<+0x59> c164=<+0x164 w> hp=<+0x50 w> c54=<+0x54>
--     h5c=<+0x5C> f11e=<+0x11E> s140=<+0x140> a5c=<P1's +0x5C> (14z-221c, #363's fix: the fields vs2's row-0x4F handler
--     writes, PRG:0x02296C; P1 is RAM:$FF8400)
-- for P2's block RAM:$FF8800 (+0x54 the reaction class the hit gave, +0x59 the pushback step-table index, +0x164 its
-- counter); then `END <fr>`. POKES (tests/lua/pokes_spec.lua) are applied each frame before the read. Used by
-- tests/audit_beam_slide.sh; from the 14z-221 investigation tap build/agent221/t358/lua/p2push_tap.lua (its write taps
-- named the writers, recorded in docs/game/engine_internals.md; this tap reads state only).
local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
local clock = dofile(here .. "emu_clock.lua")
local C = clock{ name = "beam_slide_tap", frames = 9000 }
local pokes = dofile(here .. "pokes_spec.lua").append({}, os.getenv("POKES"))
local byf = {}
for _, p in ipairs(pokes) do byf[p[1]] = byf[p[1]] or {}; table.insert(byf[p[1]], p) end
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local SF = tonumber(os.getenv("SFROM") or "2560"); local STO = tonumber(os.getenv("STO") or "3080")
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
        out:write(string.format("P %d p1x=%04x x=%04x y=%04x seq=%02x sub=%02x s59=%02x c164=%04x hp=%04x c54=%02x" ..
            " h5c=%02x f11e=%02x s140=%02x a5c=%02x\n",
            fr, w(0xff8410), w(0xff8810), w(0xff8814), b(0xff8806), b(0xff8807), b(0xff8859), w(0xff8964),
            w(0xff8850), b(0xff8854), b(0xff885c), b(0xff891e), b(0xff8940), b(0xff845c)))
    end,
    on_end = function(fr) out:write(string.format("END %d\n", fr)); out:close() end }
