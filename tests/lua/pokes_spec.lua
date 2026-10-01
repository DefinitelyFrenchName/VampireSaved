-- pokes_spec.lua — the ONE parser of the POKES grammar, shared by every instrument that applies scheduled RAM
-- writes (14z-187b, GitHub #201).
--
-- GRAMMAR. POKES is a ";"-separated list of entries:
--   F:addr:hex        write the bytes `hex` at `addr` on frame F
--   F1-F2:addr:hex    the same write on EVERY frame from F1 to F2, both included (a RANGE)
-- addr and hex are hexadecimal; hex is the bytes written, two digits a byte.
--
-- WHY THE RANGE. Linux caps ONE environment string at 128 KiB (MAX_ARG_STRLEN; measured on ERIS: 131,072 bytes
-- fails, 131,067 passes), and the parity-style gates pinned the speed level and the RNG with one entry PER FRAME —
-- 146,924 bytes for donovan_3, so the shell could not even exec the leg off macOS. A range says the same in ~20 bytes.
--
-- SEMANTICS ARE UNCHANGED BY CONSTRUCTION: a range is expanded IN PLACE into the per-frame entries it stands for, so
-- every instrument's list — and so the order in which two writes on one frame are applied — is exactly the list the
-- per-frame form gave. A malformed entry is skipped, as before.
--
-- Use: local append = dofile(<this dir> .. "pokes_spec.lua").append
--      append(pokes, os.getenv("POKES"))   -- appends {frame, addr, hex} entries to the list, returns it
local M = {}

function M.append(list, s)
    for spec in (s or ""):gmatch("[^;]+") do
        local a, b, addr, hexs = spec:match("^(%d+)%-(%d+):(%x+):(%x+)$")
        if a then
            local ad = tonumber(addr, 16)
            for f = tonumber(a), tonumber(b) do list[#list + 1] = { f, ad, hexs } end
        else
            local fr, addr1, hexs1 = spec:match("^(%d+):(%x+):(%x+)$")
            if fr then list[#list + 1] = { tonumber(fr), tonumber(addr1, 16), hexs1 } end
        end
    end
    return list
end

return M
