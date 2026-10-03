-- upload_tap.lua (14z-189, GitHub #162) — a NON-DEBUG write tap on palette RAM that,
-- on each write by a listed uploader PC, logs the CPU registers at that instant and
-- the requesting object's fields: WHO asked the palette-sequence uploader for a row,
-- WHERE the source row came from, and WHERE it went. Built on read_tap.lua's replay
-- and POKES playback (same canonical input staging, so frames match replay.lua's - 1;
-- see read_tap.lua's note) because a -debug breakpoint would read the same registers
-- but desynchronise the replay ([MFI-5]: frame_done fires while the CPU is stopped).
--
-- The registers are read from cpu.state inside the tap callback, i.e. during the
-- writing instruction: for `movem.l d0-d3,(a1)` a1 is the destination and a0 has
-- already been advanced past the 16 bytes just read (`movem.l (a0)+,d0-d3`), so the
-- source of that half-row is a0 - 0x10. One line per instruction: only the write at
-- offset == a1 is logged (a movem.l of four longs is eight 16-bit bus writes).
--
--   env UTAP     "hexaddr,declen" palette range to tap (e.g. 90c000,1024)
--   env UPCS     "hexpc,hexpc,..." the uploader PCs to attribute (others are only counted)
--   env WINDOW   "lo,hi" frame gate for the U lines (the W liveness lines always log)
--   env OPATCH   optional "hexaddr:hexbytes" written once at frame 1 into the decrypted-opcode share
--   env REPLAY / POKES / FRAMES / TRACE_OUT as read_tap.lua
-- Logs: U <frame> PC <pc> A0 <a0> A1 <a1 as read> DST <the write's address> A5 <a5> A6 <a6> SP <the ACTIVE stack pointer> RET <long at it>
--         ID <+0x382(a6)> ROW <+0x18B(a6)> OWN <+0x30(a6) as a sign-extended word>
--         OID <+0x382(owner)> BLK <+0x3A4(a6)> COL <+0x3AE(a6)> OCOL <+0x3AE(owner)> PST <+0x14E: the palette state the dispatcher
--         PRG:0x02A7C8 switches on> PPST <+0x14F: the previous one> STK <8 longs from the active stack>
--       W <frame> PC <pc> off <addr>   (every write — the boot clear is the liveness control)
-- END line + PCHIST.

local out_path   = os.getenv("TRACE_OUT") or "upload_tap.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 5450
local wa, wb = (os.getenv("WINDOW") or "0,99999999"):match("^(%d+),(%d+)$")
wa, wb = tonumber(wa), tonumber(wb)
local a_s, l_s = assert(os.getenv("UTAP"), "set UTAP=hexaddr,declen"):match("^(%x+),(%d+)$")
assert(a_s, "UTAP not hexaddr,declen")
local base, len = tonumber(a_s, 16), tonumber(l_s)
local upcs = {}
for one in (os.getenv("UPCS") or ""):gmatch("[^,]+") do upcs[tonumber(one, 16)] = true end

local machine = manager.machine
-- OPATCH "hexaddr:hexbytes" (14z-189, #162's counterfactual): written ONCE at frame 1 into the board's
-- DECRYPTED-OPCODE share — the copy the CPU fetches instructions and their immediates from — so a one-word
-- code change can be tried without building or re-encrypting anything. Nothing on disk changes.
local opatch = os.getenv("OPATCH")
if opatch == "" then opatch = nil end
local cpu     = machine.devices[":maincpu"]
local space   = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))

local frame = 0
local hits, pchist = 0, {}
local taps = {}
local installing = false
local function reg(n) return cpu.state[n].value & 0xFFFFFFFF end
local function rd8(a) return space:read_u8(a & 0xFFFFFF) end
local function rd16(a) return space:read_u16(a & 0xFFFFFF) end
local function rd32(a) return space:read_u32(a & 0xFFFFFF) end
local function install()
    if installing then return end
    installing = true
    taps[#taps + 1] = space:install_write_tap(base, base + len - 1, "ut", function(offset, data, mask)
        hits = hits + 1
        local pc = cpu.state["CURPC"].value & 0xFFFFFF
        pchist[pc] = (pchist[pc] or 0) + 1
        f:write(string.format("W %d PC %06x off %06x\n", frame, pc, offset))
        if upcs[pc] and frame >= wa and frame <= wb then
          local okc, err = pcall(function()
            local a1 = reg("A1") & 0xFFFFFF
            -- one line per movem: each half-row write starts 16-byte aligned (a1 read mid-instruction
            -- is NOT the destination on this core — measured 14z-189: logged, never trusted)
            if (offset & 0xF) == 0 then
                local a6 = reg("A6") & 0xFFFFFF
                -- the ACTIVE stack by SR bit 13: this game runs in USER mode, where MAME's SP state is the
                -- supervisor stack and the caller's return address sits at USP (docs/platform/gotchas.md,
                -- "cpu.state[\"SP\"] IS THE SUPERVISOR STACK"; tests/lua/rng_draws.lua)
                local sp = ((reg("SR") & 0x2000) ~= 0 and reg("SP") or reg("USP")) & 0xFFFFFF
                local st = {}
                for k = 0, 7 do st[#st + 1] = string.format("%08x", rd32(sp + 4 * k)) end
                local stk = table.concat(st, ",")
                local ow = rd16(a6 + 0x30)
                local owner = (ow >= 0x8000) and (0xFF0000 | ow) or ow
                f:write(string.format(
                    "U %d PC %06x A0 %06x A1 %06x DST %06x A5 %06x A6 %06x SP %06x RET %06x ID %02x ROW %02x OWN %06x OID %02x BLK %06x COL %02x OCOL %02x PST %02x PPST %02x STK %s\n",
                    frame, pc, reg("A0") & 0xFFFFFF, a1, offset & 0xFFFFFF, reg("A5") & 0xFFFFFF, a6, sp, rd32(sp) & 0xFFFFFF,
                    rd8(a6 + 0x382), rd8(a6 + 0x18B), owner, rd8(owner + 0x382), rd32(a6 + 0x3A4) & 0xFFFFFF,
                    rd8(a6 + 0x3AE), rd8(owner + 0x3AE), rd8(a6 + 0x14E), rd8(a6 + 0x14F), stk))
            end
          end)
          if not okc then f:write("ERR " .. tostring(err) .. "\n") end
        end
    end)
    installing = false
end
install()
space:add_change_notifier(function()
    if installing then return end
    for _, t in ipairs(taps) do t:remove() end
    taps = {}
    install()
end)

-- replay + pokes playback: CANONICAL staging, exactly read_tap.lua's (held[frame + 1];
-- pinned by tests/test_replay_stage_census.sh).
local held = {}
local replay_path = os.getenv("REPLAY")
local FIELDS = nil
if replay_path then
    local ioport = machine.ioport
    local function fld(port, name) return ioport.ports[port].fields[name] end
    FIELDS = {
        p1 = { U = fld(":IN0", "P1 Up"), D = fld(":IN0", "P1 Down"),
               L = fld(":IN0", "P1 Left"), R = fld(":IN0", "P1 Right"),
               ["1"] = fld(":IN0", "P1 Button 1"), ["2"] = fld(":IN0", "P1 Button 2"),
               ["3"] = fld(":IN0", "P1 Button 3"), ["4"] = fld(":IN1", "P1 Button 4"),
               ["5"] = fld(":IN1", "P1 Button 5"), ["6"] = fld(":IN1", "P1 Button 6") },
        p2 = { U = fld(":IN0", "P2 Up"), D = fld(":IN0", "P2 Down"),
               L = fld(":IN0", "P2 Left"), R = fld(":IN0", "P2 Right"),
               ["1"] = fld(":IN0", "P2 Button 1"), ["2"] = fld(":IN0", "P2 Button 2"),
               ["3"] = fld(":IN0", "P2 Button 3"), ["4"] = fld(":IN1", "P2 Button 4"),
               ["5"] = fld(":IN1", "P2 Button 5"), ["6"] = fld(":IN2", "P2 Button 6") },
        sys = { S1 = fld(":IN2", "1 Player Start"), S2 = fld(":IN2", "2 Players Start"),
                C1 = fld(":IN2", "Coin 1"), C2 = fld(":IN2", "Coin 2"),
                SV = fld(":IN2", "Service 1"), TS = fld(":IN2", "Service Mode") },
    }
    for line in io.lines(replay_path) do
        local body = line:gsub("#.*", "")
        local range, rest = body:match("^%s*(%S+)%s+(.-)%s*$")
        if range then
            local a, b = range:match("^(%d+)%-(%d+)$")
            if not a then a = range:match("^(%d+)$"); b = a end
            if a then
                for spec2 in rest:gmatch("%S+") do
                    local who, toks = spec2:match("^(%a+%d?)=(%S+)$")
                    if who and FIELDS[who] then
                        local step = (who == "sys") and 2 or 1
                        for i = 1, #toks, step do
                            local fldo = FIELDS[who][toks:sub(i, i + step - 1)]
                            if fldo then
                                for fr = tonumber(a), tonumber(b) do
                                    held[fr] = held[fr] or {}
                                    table.insert(held[fr], fldo)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local pokes = {}
do
    dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "pokes_spec.lua").append(pokes, os.getenv("POKES"))
end

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
    if opatch and frame == 1 then
        local sh = assert(machine.memory.shares[":decrypted_opcodes"], "no :decrypted_opcodes share")
        local pa, pb = opatch:match("^(%x+):(%x+)$")
        local a = tonumber(pa, 16)
        for b in pb:gmatch("%x%x") do sh:write_u8(a, tonumber(b, 16)); a = a + 1 end
        f:write(string.format("OPATCH %s readback %04x%04x\n", opatch, sh:read_u16(tonumber(pa, 16)), sh:read_u16(tonumber(pa, 16) + 2)))
    end
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do
                space:write_u8(a, tonumber(b, 16)); a = a + 1
            end
        end
    end
    if FIELDS then
        local want = {}
        for _, fldo in ipairs(held[frame + 1] or {}) do want[fldo] = true end
        for _, group in pairs(FIELDS) do
            for _, fldo in pairs(group) do
                if want[fldo] and not pressed[fldo] then fldo:set_value(1); pressed[fldo] = true
                elseif not want[fldo] and pressed[fldo] then fldo:clear_value(); pressed[fldo] = nil end
            end
        end
    end
    if frame >= max_frames then
        f:write(string.format("END %d hits %d\n", frame, hits))
        local rows = {}
        for pc, n in pairs(pchist) do rows[#rows + 1] = { pc, n } end
        table.sort(rows, function(x, y) return x[2] > y[2] end)
        for _, r in ipairs(rows) do
            f:write(string.format("PCHIST %06x %d\n", r[1], r[2]))
        end
        f:close()
        manager.machine:exit()
    end
end)
