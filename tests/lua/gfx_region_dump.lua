-- gfx_region_dump.lua — dump a byte window of MAME's decoded gfx region.
--
-- WHY: "the sprite draws the wrong art" needs the tile bytes the emulator
-- actually holds at the address the sprite record composes. The address is
--   tile = code | ((y & 0x6000) << 3)   ->   byte = tile * 0x80
-- and forgetting the bank bits points the dump at an unrelated band that
-- is vanilla on every build — which is how the 14z-60y load hypothesis was
-- first (wrongly) declared dead. Compare the same window across builds.
--
--   env GFX_WINDOWS  "tileHex[:count],..."  windows given as TILE indices
--                    (count defaults to 1 tile = 0x80 bytes)
--   env GFX_REGION   region tag (default ":gfx")
--   env TRACE_OUT    log path (default gfx_region.txt)
--   env AT_FRAME     dump after this many frames (default 60; the region is
--                    ROM, so any post-load frame gives the same answer)
--
-- Prints per window: tile, byte offset, length, FNV-1a64 of the bytes, the
-- first 32 bytes in hex, and a 0xFF-fill count (the FBNeo CRC trap tell).
-- Ends with GFXDUMPSUMMARY.

local out_path = os.getenv("TRACE_OUT") or "gfx_region.txt"
local region_tag = os.getenv("GFX_REGION") or ":gfx"
local at_frame = tonumber(os.getenv("AT_FRAME") or "") or 60

local windows = {}
for spec in (os.getenv("GFX_WINDOWS") or ""):gmatch("[^,%s]+") do
    local t, n = spec:match("^(%x+):(%d+)$")
    if not t then t, n = spec:match("^(%x+)$"), "1" end
    if t then windows[#windows + 1] = { tile = tonumber(t, 16), tiles = tonumber(n) } end
end
assert(#windows > 0, "GFX_WINDOWS must name at least one tile index")

local f = assert(io.open(out_path, "wb"))
local frame = 0

emu.register_frame_done(function()
    frame = frame + 1
    if frame < at_frame then return end

    local region = manager.machine.memory.regions[region_tag]
    assert(region, "no region " .. region_tag)
    f:write(string.format("REGION %s size=%x\n", region_tag, region.size))

    for _, w in ipairs(windows) do
        local off = w.tile * 0x80
        local len = w.tiles * 0x80
        local h = 0xcbf29ce484222325
        local ff = 0
        local head = {}
        for i = 0, len - 1 do
            local b = (off + i < region.size) and region:read_u8(off + i) or 0
            h = (h ~ b) * 0x100000001b3
            h = h & 0xFFFFFFFFFFFFFFFF
            if b == 0xFF then ff = ff + 1 end
            if i < 32 then head[#head + 1] = string.format("%02x", b) end
        end
        f:write(string.format("GFX tile=%05x byte=%08x len=%x fnv=%016x ff=%d head=%s\n",
            w.tile, off, len, h, ff, table.concat(head)))
    end

    f:write(string.format("GFXDUMPSUMMARY windows=%d frame=%d\n", #windows, frame))
    f:close()
    manager.machine:exit()
end)
