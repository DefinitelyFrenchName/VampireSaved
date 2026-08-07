-- force_id.lua — playtest helper (14z-65): force P1's character id every
-- frame so ANY select-screen pick becomes the forced character. The
-- behavior-build stand-in for a select-wheel cell that does not exist yet
-- (Huitzil's wheel cell is the gfx-stage milestone).
--
--   env FORCE_ID  hex byte, e.g. "10" (Huitzil/Phobos)
--
-- P1 only; P2 stays a free pick, so human-vs-human works. The id field is
-- $FF8782 (the select commit field, atlas select_screen.md:104). Forcing
-- runs from the first frame — attract demos will also cast P1 as the
-- forced character, which is untested territory: odd attract behavior is
-- REPORTABLE DATA, not a playtest bug in your hands.

local id = tonumber(os.getenv("FORCE_ID") or "10", 16)
local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local space = cpu.spaces["program"]

emu.register_frame_done(function()
    space:write_u8(0xFF8782, id)
end)
print(string.format("force_id: P1 char id forced to 0x%02x", id))
