-- rng_draws.lua (14z-185, GitHub #176; promoted from build/agent185/t176/rng_callers.lua) — every DRAW of the
-- engine RNG with its CALLER and, optionally, the active stack. A copy of tests/lua/read_tap.lua (same replay/POKES
-- playback, the same frame labels: a read labelled N is field_trace's frame N+1) whose READ lines also carry
--   ret <addr>    the long at the ACTIVE stack pointer: the game runs in USER mode (SR bit 13 clear, measured
--                 SR=4), where MAME's "SP" is the supervisor stack, so the caller's return address sits at USP
--   stk <longs>   with RSTACKN=<n>: that many longs of the active stack from its top (the call chain)
-- Filter the reads to the RNG routine's first instruction with RPCS (vsavj/ours 14e8a, vs2 1357e), which reads the
-- word at entry, before anything is pushed. Used by tests/audit_rng_draws.sh.
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
--   env RTAP     "hexaddr,declen"  (word-aligned start, decimal length); since
--                14z-168 several ranges may be given, separated by ";" (both
--                fighter blocks' field in one run — audit_df_field_readers_live.sh)
--   env WINDOW   "lo,hi" frame gate for READ logging (writes always log
--                — the boot POST writes are the liveness control)
--   env RPCS     optional "hexpc,hexpc,..." (14z-169): log a READ only when its CURPC
--                is listed — for a field the engine reads everywhere (+0x382) when one
--                reader is the question (tests/audit_defense_row_reads.sh). Writes and
--                the PCHIST are unaffected; unset, the output is exactly as before.
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
local rpcs = nil
if os.getenv("RPCS") and os.getenv("RPCS") ~= "" then
    rpcs = {}
    for one in os.getenv("RPCS"):gmatch("[^,]+") do rpcs[tonumber(one, 16)] = true end
end
local ranges = {}
for one in spec:gmatch("[^;]+") do
    local a_s, l_s = one:match("^(%x+),(%d+)$")
    assert(a_s, "RTAP range not hexaddr,declen: " .. one)
    ranges[#ranges + 1] = { tonumber(a_s, 16), tonumber(l_s) }
end

local machine = manager.machine
local cpu     = machine.devices[":maincpu"]
local space   = cpu.spaces["program"]
local f = assert(io.open(out_path, "wb"))

local frame = 0
local hits, pchist = 0, {}
local taps = {}
local installing = false
local function install()
    if installing then return end
    installing = true
    for i, r in ipairs(ranges) do
    local base, len = r[1], r[2]
    taps[#taps + 1] = space:install_read_tap(base, base + len - 1, "rt" .. i, function(offset, data, mask)
        if frame >= wa and frame <= wb then
            local pc = cpu.state["CURPC"].value & 0xFFFFFF
            if rpcs == nil or rpcs[pc] then
            hits = hits + 1
            pchist[pc] = (pchist[pc] or 0) + 1
            -- the ACTIVE stack: the game runs in USER mode (SR bit 13 clear; measured SR=4), where MAME's "SP" is the
            -- supervisor stack and the caller's return address sits at USP
            local ok, ret = pcall(function()
                local sup = (cpu.state["SR"].value & 0x2000) ~= 0
                local sp = (sup and cpu.state["SP"] or cpu.state["USP"]).value & 0xFFFFFF
                return space:read_u32(sp) & 0xFFFFFF end)
            if not ok then f:write("E " .. tostring(ret) .. "\n"); ret = 0 end
            -- RSTACKN (14z-185, rule-checker 349 Q4): also dump that many longs of the ACTIVE stack from its top, so a
            -- draw reached THROUGH an engine routine can be attributed to a caller further up the chain
            local stk = ""
            local nst = tonumber(os.getenv("RSTACKN") or "0")
            if nst > 0 then
                local sup = (cpu.state["SR"].value & 0x2000) ~= 0
                local sp = (sup and cpu.state["SP"] or cpu.state["USP"]).value & 0xFFFFFF
                local w = {}
                for k = 0, nst - 1 do w[#w + 1] = string.format("%08x", space:read_u32(sp + 4 * k)) end
                stk = " stk " .. table.concat(w, ",")
            end
            f:write(string.format("R %d PC %06x off %06x data %08x mask %08x ret %06x%s\n",
                    frame, pc, offset, data, mask, ret, stk))
            end
        end
    end)
    -- write tap over the same range, always-on (liveness: boot POST must hit)
    taps[#taps + 1] = space:install_write_tap(base, base + len - 1, "wt" .. i, function(offset, data, mask)
        hits = hits + 1
        local pc = cpu.state["CURPC"].value & 0xFFFFFF
        f:write(string.format("W %d PC %06x off %06x data %08x mask %08x\n",
                frame, pc, offset, data, mask))
    end)
    end
    installing = false
end
install()
space:add_change_notifier(function()
    if installing then return end   -- a tap installed by this pass must not remove its siblings (14z-168: several ranges)
    for _, t in ipairs(taps) do t:remove() end
    taps = {}
    install()
end)

-- replay + pokes playback.
-- INPUT STAGING IS CANONICAL (GitHub #10, unified 14z-94). This instrument
-- follows tests/lua/replay.lua exactly: parse `held[fr]`, stage for the NEXT
-- frame (`held[frame + 1]`). So INPUTS land on the same frames as replay.lua's.
-- A LOGGED ACCESS is labelled with the counter BEFORE its frame's frame_done
-- increments it, while replay.lua (and field_trace.lua) increment first and then
-- checksum or sample: an access logged `W N` belongs to replay.lua's frame N+1.
-- Add one before cross-referencing a compare_* first divergence, a masked
-- window onset or a checksum log (measured 14z-184 on every unpoked frame of
-- four runs; docs/platform/gotchas.md; tests/audit_shared_wall_push.sh re-proves
-- it each run).
--
-- It was one of the ten `+1` deviants until 14z-94. The split is now pinned
-- at ZERO by tests/test_replay_stage_census.sh, which fails any new
-- instrument that copies the old flavour — that is how the drift spread:
-- one variant, then every later file copying the copy.
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
    dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "pokes_spec.lua").append(pokes, os.getenv("POKES"))   -- #201: F and F1-F2 entries
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
