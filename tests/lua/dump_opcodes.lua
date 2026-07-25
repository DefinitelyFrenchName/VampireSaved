-- dump_opcodes.lua — write the CPU's decrypted opcode space to a file.
-- Oracle for tools/cps2_decrypt.py: MAME's own cps2crypt output is truth.
-- Usage: mame <set> -autoboot_script tests/lua/dump_opcodes.lua ...
--   env DUMP_OUT   output path (default opcodes_dump.bin)
--   env DUMP_LEN   bytes to dump (default 0x400000)
-- Output is big-endian words, matching the raw-image convention of the tools.

local out_path = os.getenv("DUMP_OUT") or "opcodes_dump.bin"
local len = tonumber(os.getenv("DUMP_LEN") or "") or 0x400000

local cpu = manager.machine.devices[":maincpu"]
assert(cpu, "no :maincpu device")
local space = cpu.spaces["opcodes"]
assert(space, "maincpu has no separate opcode space")

local f = assert(io.open(out_path, "wb"))
local chunk = {}
for addr = 0, len - 2, 2 do
    local w = space:read_u16(addr)
    chunk[#chunk + 1] = string.char((w >> 8) & 0xff, w & 0xff)
    if #chunk == 0x8000 then
        f:write(table.concat(chunk))
        chunk = {}
    end
end
f:write(table.concat(chunk))
f:close()
print(string.format("dumped 0x%x bytes of opcode space to %s", len, out_path))
manager.machine:exit()
