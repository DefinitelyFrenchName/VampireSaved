-- scroll3_watch.lua — scroll3-vs-OBJ-band exclusivity instrument (M2b).
-- Wraps replay.lua: installs a write tap on the CPS-A registers to track
-- the scroll3 tilemap base, and each frame scans the active scroll3 map
-- for tile codes whose ABSOLUTE gfx index would land in the Donovan
-- placement window (vsav bank-2 OBJ band). scroll3 absolute index =
-- 0x10000 + 4*code (measured from the CPS2 draw path, no mapper), so
-- the danger codes are [(lo-0x10000)/4, (hi-0x10000)/4].
--
-- env SCROLL3_OUT   report path (required)
-- env SCROLL3_LO/HI absolute tile window (default 0x2AD80/0x2EEBB)
-- plus everything replay.lua takes (REPLAY, CHECKSUM_OUT, ...).
--
-- Report: per-frame lines only when danger codes are present; summary
-- "SCROLL3SUMMARY maxcode=%x bases=... danger=%d" at exit.

local out_path = assert(os.getenv("SCROLL3_OUT"), "set SCROLL3_OUT")
local lo = tonumber(os.getenv("SCROLL3_LO") or "", 16) or 0x2AD80
local hi = tonumber(os.getenv("SCROLL3_HI") or "", 16) or 0x2EEBB
local clo = math.floor((lo - 0x10000) / 4)
local chi = math.floor((hi - 0x10000) / 4)

local cpu = manager.machine.devices[":maincpu"]
local space = cpu.spaces["program"]

-- The scroll3 base register is WRITE-ONLY and written ONCE at boot
-- (PC 0x926 writes #$0000 to the reg block; measured via
-- trace_writes.lua WATCH=800106 — one hit in 2400 frames). The map
-- therefore sits at VRAM base 0x900000; SCROLL3_BASE overrides if a
-- build ever repoints it. Constancy across stages is separately
-- verified by a full-length trace_writes run (tests notes).
local scroll3_base = tonumber(os.getenv("SCROLL3_BASE") or "", 16) or 0
local bases_seen = { [scroll3_base] = true }
local danger_frames = 0
local max_code = 0
local frame = 0
-- WIDE A3 census counters (additive; SCROLL3SUMMARY's contract is unchanged)
s3_blank_cells = 0     -- cells holding the 0xFFFF blank sentinel
s3_high_cells = 0      -- cells holding a REAL code >= 0xC000
s3_high_codes = {}     -- distinct real high codes -> count
s3_max_real = 0        -- max code excluding the sentinel

local rep = io.open(out_path, "w")

-- MAME Lua traps (paid for, session 14b): emu.register_frame_done is a
-- SINGLE slot — replay.lua (dofile'd below) would clobber it; and the
-- add_machine_*_notifier subscriptions are dropped if the return value
-- is garbage-collected. Use the multi-subscriber notifier and pin the
-- subscriptions in globals.
_G.s3_frame_sub = emu.add_machine_frame_notifier(function()
    frame = frame + 1
    -- tilemap: 0x4000 bytes at base<<8 (VRAM $900000 window)
    local base = 0x900000 + ((scroll3_base << 8) & 0x3ffff)
    local n_danger = 0
    for off = 0, 0x3ffe, 4 do          -- (code.w, attr.w) pairs
        local code = space:read_u16(base + off)
        if code > max_code then max_code = code end
        -- WIDE A3 census: scroll3's absolute tile index is 0x10000+4*code,
        -- so code >= 0xC000 exceeds the 0x40000-tile region and today WRAPS
        -- via nCpsGfxMask. Growing the gfx region moves that wrap point, so
        -- we need to know whether any REAL code gets there — 0xFFFF is the
        -- blank/uninitialised sentinel and must be counted separately or it
        -- masquerades as a blocker.
        if code >= 0xC000 then
            if code == 0xFFFF then
                s3_blank_cells = s3_blank_cells + 1
            else
                s3_high_cells = s3_high_cells + 1
                s3_high_codes[code] = (s3_high_codes[code] or 0) + 1
                if code > s3_max_real then s3_max_real = code end
            end
        end
        if code >= clo and code <= chi then
            n_danger = n_danger + 1
        end
    end
    if n_danger > 0 then
        danger_frames = danger_frames + 1
        rep:write(string.format("%d danger=%d base=%04x\n",
                                frame, n_danger, scroll3_base))
        rep:flush()
    end
end)

_G.s3_stop_sub = emu.add_machine_stop_notifier(function()
    local bl = {}
    for b in pairs(bases_seen) do bl[#bl + 1] = string.format("%04x", b) end
    table.sort(bl)
    rep:write(string.format("SCROLL3SUMMARY maxcode=%04x danger_frames=%d bases=%s\n",
                            max_code, danger_frames, table.concat(bl, ",")))
    -- DETERMINISTIC SAMPLE, AND IT SAYS IT IS ONE (14z-94, GitHub #60).
    -- This used to take the first 12 codes in `pairs()` ORDER and sort those,
    -- so the printed set was an arbitrary 12 that could differ between two
    -- runs of the same rig — in a project whose comparisons rest on
    -- run-to-run determinism — and a reader had no way to tell the list was
    -- truncated at all. Collect every code, sort, THEN cut, and name what was
    -- cut. `distinct_high` was already the complete count and still is; only
    -- the sample was arbitrary.
    local all, n = {}, 0
    for c, k in pairs(s3_high_codes) do
        n = n + 1
        all[#all + 1] = { c, k }
    end
    table.sort(all, function(x, y) return x[1] < y[1] end)
    local hl = {}
    for i = 1, math.min(#all, 12) do
        hl[#hl + 1] = string.format("%04x:%d", all[i][1], all[i][2])
    end
    if #all > 12 then
        hl[#hl + 1] = string.format("+%d more", #all - 12)
    end
    rep:write(string.format(
        "SCROLL3CENSUS max_real=%04x high_cells=%d distinct_high=%d blank_cells=%d high=%s\n",
        s3_max_real, s3_high_cells, n, s3_blank_cells, table.concat(hl, ",")))
    rep:close()
end)

-- chain into the standard replay driver (same directory as this script)
local here = debug.getinfo(1, "S").source:match("@(.*/)") or "./"
dofile(here .. "replay.lua")
