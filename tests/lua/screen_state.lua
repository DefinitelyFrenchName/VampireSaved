-- screen_state.lua — what a proof-sheet snapshot shows, as the game's own state at that frame (GitHub #291 S4-B,
-- 14z-206). Loaded by tests/lua/sheet_capture.lua and tests/lua/sheet_tap_capture.lua; READ-ONLY (no write, no tap).
--
-- WHY. A tile is useful to a human only if the fighters are on screen; a frame of the round-end fade, the bare stage
-- before the drop-in, the select screen or the load frame is judged by its gate but shows no fighter (#291 S3: 136 of
-- 3,753 pictures near-blank, more by eye). tools/proof_sheets.py's `fighters()` decides "fighters on screen" from this
-- line, and tests/test_proof_sheets.sh scores that predicate against hand-classified pictures before the page uses it.
--
-- The line, one per snapshot:  R <frame> st=<$FF812D> ph=<$FF810E> m4=<$FF8004.l> m8=<$FF8008.l> a1=<$FF8400.b>
--   a2=<$FF8800.b> hp1=<$FF8450.w> hp2=<$FF8850.w> t=<$FF8109> o0=<OBJ entries at 708000> o1=<OBJ entries at 710000>
--   fp=<OBJ entries at 708000 whose palette (attribute & 0x1F) is 0x01-0x09> c1=<$FF8782> c2=<$FF8B82> lv=<$FF8116>
--   fv=<latched OBJ entries on screen drawn with a fighter's own palette row> r1=<$FF858B> r2=<$FF898B> (below)
-- c1/c2 are the P1/P2 character ids (fighter block +0x382; docs/game/atlas/ram.md, the same ids in vsavj, vsav2 and
-- vhunt2: docs/game/atlas/character_tables.md) and lv the speed level ($FF8116): who plays whom, and at what speed,
-- for the page's per-sheet line (the maintainer, 14z-206: each gate's characters and setup, MEASURED).
-- (docs/game/atlas/ram.md: $FF812D 0 outside a round; $FF810E the round phase, 0 fighting, 1 a down settled, FF the
-- match's end; $FF8004/$FF8008 both 0x40000 in a match; +0x00 the fighter's alive header, +0x50 its HP; the OBJ walk is
-- tests/lua/inp_probe.lua's, hardware-style: stop at a Y with bit 15 or an attribute >= 0xFF00.)
-- fp, MEASURED 14z-206 (#291 S4-B, build/agent206/t291/s4b/, local: gt_pal.py on 118 by-eye-classed pictures, then
-- gt_score.py on all 201): in a match, palettes 0x01-0x09 appeared on every picture showing the fighters (104 of 104)
-- and on none of the 89 showing none; the stage, the HUD and the select/VS screens draw with 0x00 and 0x0A-0x1F (and
-- 0x01-0x04 OUTSIDE a match: the select screen, which the match words exclude).
-- fv r1 r2 (#291, 14z-207, build/agent207/t291/H/, local): the ROUND INTRO shows both fighters with no entry in
-- 0x01-0x09 (fp=0 from the round's load to about 117 frames later on test_hui_oracle's legs, the intro poses drawn the
-- whole time), so `fp` alone read every intro as "no fighters". The fighters draw with their OWN palette rows, the
-- fighter block's +0x18B (docs/game/atlas/ram.md; r1/r2 below, 0x0A/0x10 on that leg), and what the picture shows is
-- the LATCHED list MAME renders from (cps2_state::m_cps2_buffered_obj, copied from OBJ RAM at vblank), which on the
-- measured leg lags the OBJ RAM read above by two frames: OBJ RAM held the fighters from f2363, the latched list and the
-- picture from f2365. fv counts the latched entries drawn with r1 or r2 that put at least one 16x16 tile WHOLLY inside
-- the visible area (MAME's own placement: cps2_render_sprites' xoffs/yoffs from the OBJ offset registers at
-- $400008/$40000A, block sprites nx x ny, the visible area x 64-447 / y 16-239). WHOLLY, measured: on audit_rig_opening's
-- native leg a P2 tile overlapping the right edge by 11 columns drew nothing at f2365 (the picture pixel-equal to the
-- bare f2362) and 10-141 pixels at f2366-2369, so "any overlap" read a bare stage as fighters; a fighter only entering
-- at an edge reads "no", as S4-B's predicate already did. -1 = the latched list cannot be read (no save item).
local M = {}

-- the latched OBJ list, a save item of the driver device; its index is looked up once (the items walk is slow)
local latched_idx = false
local function latched()
    if latched_idx == false then
        local ok, idx = pcall(function() return manager.machine.devices[":"].items["0/m_cps2_buffered_obj"] end)
        latched_idx = ok and idx or nil
    end
    return latched_idx and emu.item(latched_idx) or nil
end

local function visible_fighter_entries(space, r1, r2)
    local it = latched()
    if not it or it.count < 4 then return -1 end
    local xreg, yreg = space:read_u16(0x400008), space:read_u16(0x40000A)
    local xoffs, yoffs = 64 - xreg, 16 - yreg
    local n = 0
    for i = 0, it.count // 4 - 1 do
        local x, y, attr = it:read(i * 4), it:read(i * 4 + 1), it:read(i * 4 + 3)
        if (y & 0x8000) ~= 0 or attr >= 0xFF00 then break end
        local p = attr & 0x1F
        if (p == r1 or p == r2) and p ~= 0 then
            if (attr & 0x80) ~= 0 then x = x + xreg; y = y + yreg end
            local nx, ny = 1, 1
            if (attr & 0xFF00) ~= 0 then nx = ((attr >> 8) & 0xF) + 1; ny = ((attr >> 12) & 0xF) + 1 end
            local seen = false
            for a = 0, ny - 1 do
                local sy = (y + a * 16 + yoffs) & 0x3FF
                if sy >= 16 and sy <= 240 - 16 then
                    for b = 0, nx - 1 do
                        local sx = (x + b * 16 + xoffs) & 0x3FF
                        if sx >= 64 and sx <= 448 - 16 then seen = true; break end
                    end
                end
                if seen then break end
            end
            if seen then n = n + 1 end
        end
    end
    return n
end

function M.line(space, frame)
    local function s16(a) local v = space:read_u16(a); if v >= 0x8000 then v = v - 0x10000 end; return v end
    local fp = 0
    local function walk(base, count_fp)
        local n = 0
        for i = 0, 0x3FF do
            local off = base + i * 8
            if (space:read_u16(off + 2) & 0x8000) ~= 0 then break end
            local attr = space:read_u16(off + 6)
            if attr >= 0xFF00 then break end
            n = n + 1
            if count_fp and (attr & 0x1F) >= 0x01 and (attr & 0x1F) <= 0x09 then fp = fp + 1 end
        end
        return n
    end
    local o0 = walk(0x708000, true)
    local r1, r2 = space:read_u8(0xFF8400 + 0x18B), space:read_u8(0xFF8800 + 0x18B)
    return string.format("R %d st=%d ph=%d m4=%x m8=%x a1=%d a2=%d hp1=%d hp2=%d t=%d o0=%d o1=%d fp=%d c1=%d c2=%d lv=%d fv=%d r1=%d r2=%d\n", frame,
        space:read_u8(0xFF812D), space:read_u8(0xFF810E), space:read_u32(0xFF8004), space:read_u32(0xFF8008),
        space:read_u8(0xFF8400), space:read_u8(0xFF8800), s16(0xFF8450), s16(0xFF8850), space:read_u8(0xFF8109),
        o0, walk(0x710000, false), fp, space:read_u8(0xFF8782), space:read_u8(0xFF8B82), space:read_u8(0xFF8116),
        visible_fighter_entries(space, r1, r2), r1, r2)
end

return M
