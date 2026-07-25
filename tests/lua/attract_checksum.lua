-- attract_checksum.lua — checksum CPS-2 work RAM every frame during attract.
-- The M0 determinism probe and the seed of the oracle-replay harness:
-- identical inputs (none) must yield an identical per-frame checksum log.
--
-- Usage: mame <set> -autoboot_script tests/lua/attract_checksum.lua ...
--   env CHECKSUM_OUT  output log path (default attract_checksums.txt)
--   env FRAMES        frames to run (default 3600 = 60s @ 59.6Hz-ish)
--
-- Log format: "<frame> <fnv1a64-of-work-RAM>" per line, then "END <frames>".
-- Work RAM = RAM:$FF0000-$FFFFFF (68k main RAM, holds all match state).

local out_path = os.getenv("CHECKSUM_OUT") or "attract_checksums.txt"
local target_frames = tonumber(os.getenv("FRAMES") or "") or 3600

local cpu = manager.machine.devices[":maincpu"]
assert(cpu, "no :maincpu device")
local program = cpu.spaces["program"]
assert(program, "no program space")

local f = assert(io.open(out_path, "wb"))
local frame = 0

local FNV_OFFSET = 0xcbf29ce484222325
local FNV_PRIME = 0x100000001b3

local function fnv1a64(s)
    local h = FNV_OFFSET
    -- 8-byte lanes: fast enough per-frame and plenty to catch any divergence
    local n = #s - (#s % 8)
    for i = 1, n, 8 do
        local lane = string.unpack("<i8", s, i)
        h = (h ~ lane) * FNV_PRIME
    end
    for i = n + 1, #s do
        h = (h ~ s:byte(i)) * FNV_PRIME
    end
    return h
end

emu.register_frame_done(function()
    frame = frame + 1
    local ram = program:read_range(0xff0000, 0xffffff, 8)
    f:write(string.format("%d %016x\n", frame, fnv1a64(ram)))
    if frame >= target_frames then
        f:write(string.format("END %d\n", frame))
        f:close()
        manager.machine:exit()
    end
end)
