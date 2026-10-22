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
local M = {}

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
    return string.format("R %d st=%d ph=%d m4=%x m8=%x a1=%d a2=%d hp1=%d hp2=%d t=%d o0=%d o1=%d fp=%d c1=%d c2=%d lv=%d\n", frame,
        space:read_u8(0xFF812D), space:read_u8(0xFF810E), space:read_u32(0xFF8004), space:read_u32(0xFF8008),
        space:read_u8(0xFF8400), space:read_u8(0xFF8800), s16(0xFF8450), s16(0xFF8850), space:read_u8(0xFF8109),
        o0, walk(0x710000, false), fp, space:read_u8(0xFF8782), space:read_u8(0xFF8B82), space:read_u8(0xFF8116))
end

return M
