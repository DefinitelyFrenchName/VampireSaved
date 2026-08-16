-- read_tap.lua (14z-87, promoted from the ding hunt) — PC-attributed
-- READ (+WRITE) tap on work-RAM addresses, NON-DEBUG so frame counting
-- stays replay-exact. Modeled on tap_writes.lua: same replay/POKES
-- playback, install_read_tap/install_write_tap with the re-install
-- notifier + recursion guard.
--
-- WHY IT EXISTS: this is the instrument that broke the voice-class
-- borrow case — the dispatcher's mid-frame READ of (0x382,A6) showed a
-- value that no frame_done sample and no cross-run write log could
-- explain, because the value is state-dependent and every run allocates
-- it differently (docs/platform/gotchas.md, 14z-87: never correlate a
-- state-dependent value across runs; serialize read+write in ONE run —
-- which is exactly what this script does).
--
-- SCOPE LIMIT: RAM data reads only. A read tap on ROM/opcode fetches is
-- SILENTLY BLIND (cached direct pointers — the RH-15 class,
-- docs/platform/gotchas.md); do not point this at ROM and read the
-- silence as deadness.
--
--   env RTAP     "hexaddr,declen"  (word-aligned start, decimal length)
--   env WINDOW   "lo,hi" frame gate for READ logging (writes always log
--                — the boot POST writes are the liveness control)
--   env REPLAY / POKES / FRAMES / TRACE_OUT as tap_writes.lua
-- Logs: R <frame> PC <pc> off <addr> data <val> mask <m>
--       W <frame> PC <pc> off <addr> data <val> mask <m>
-- END line + PCHIST for liveness assertion (a log without the boot-POST
-- W lines at any work-RAM address is a dead instrument, full stop).

local out_path   = os.getenv("TRACE_OUT") or "read_tap.txt"
local max_frames = tonumber(os.getenv("FRAMES") or "") or 5450
local wa, wb = (os.getenv("WINDOW") or "0,99999999"):match("^(%d+),(%d+)$")
wa, wb = tonumber(wa), tonumber(wb)
local spec = assert(os.getenv("RTAP"), "set RTAP=hexaddr,declen")
local a_s, l_s = spec:match("^(%x+),(%d+)$")
local base, len = tonumber(a_s, 16), tonumber(l_s)

local machine = manager.machine
local cpu     = machine.devices[":maincpu"]
local space   = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))

local frame = 0
local hits, pchist = 0, {}
local tap, wtap
local installing = false
local function install()
    if installing then return end
    installing = true
    tap = space:install_read_tap(base, base + len - 1, "rt", function(offset, data, mask)
        if frame >= wa and frame <= wb then
            hits = hits + 1
            local pc = cpu.state["CURPC"].value & 0xFFFFFF
            pchist[pc] = (pchist[pc] or 0) + 1
            f:write(string.format("R %d PC %06x off %06x data %08x mask %08x\n",
                    frame, pc, offset, data, mask))
        end
    end)
    -- write tap over the same range, always-on (liveness: boot POST must hit)
    wtap = space:install_write_tap(base, base + len - 1, "wt", function(offset, data, mask)
        hits = hits + 1
        local pc = cpu.state["CURPC"].value & 0xFFFFFF
        f:write(string.format("W %d PC %06x off %06x data %08x mask %08x\n",
                frame, pc, offset, data, mask))
    end)
    installing = false
end
install()
space:add_change_notifier(function()
    if tap then tap:remove() end
    if wtap then wtap:remove() end
    install()
end)

-- replay + pokes playback. NOT a verbatim subset of tap_writes.lua —
-- that claim is RETRACTED (14z-90, GitHub issue #10): tap_writes.lua
-- stages `held[frame + 1]` at the end of the frame like replay.lua,
-- this file parses and stages one frame earlier, so the two land a
-- press on different frames. Its consumer audit_voice_borrow pins
-- WINDOW="3985,4005", measured under THIS convention.
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
                                    held[fr + 1] = held[fr + 1] or {}
                                    table.insert(held[fr + 1], fldo)
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
    local p = os.getenv("POKES")
    if p then
        for spec2 in p:gmatch("[^;]+") do
            local fr, addr, hexs = spec2:match("^(%d+):(%x+):(%x+)$")
            if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
        end
    end
end

local pressed = {}
emu.register_frame_done(function()
    frame = frame + 1
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
