-- replay_guard.lua — replay.lua plus crash detection. Same env contract and
-- identical checksum-log output, so it can substitute for replay.lua in any
-- gate; adds CRASH/PCWEEDS/SOFTRESET lines when the game leaves the rails.
--
-- Two modes, auto-selected:
--   * authoritative (run with -debug -debugger none): breakpoints on the 68k
--     exception handlers (vector table read from ROM at boot). A trip logs
--     "CRASH <frame> vec<n> PC <fault_pc> SP <sp> [ADDR <fault_addr>]", a
--     stack sketch (ROM-plausible longs walking up from SP), dumps work RAM
--     to crash_<frame>_ff0000.bin, writes "END-CRASH <frame>", exits.
--     Group-0 frames (vec 2/3) carry the fault address + PC at SP+10; other
--     vectors have PC at SP+2.
--   * cheap (no -debug; soak-grade, sampling can miss transient excursions):
--     per-frame CURPC classified against CODE_RANGES; match-active flag
--     watched over GUARD_MATCH. Logs PCWEEDS/SOFTRESET, keeps running.
--
-- CAVEAT (docs/GOTCHAS.md): -debug runs are deterministic but their checksum
-- logs are NOT comparable to non-debug expectations — the debugger changes
-- MAME's scheduler timeslicing, phase-shifting 68k<->sound-CPU interaction.
-- Cheap mode produces canonical (non-debug) checksums.
--
-- Usage: mame <set> [-debug -debugger none] -autoboot_script replay_guard.lua
--   env REPLAY / CHECKSUM_OUT / TAIL_FRAMES / SNAP_FRAMES / DUMPS
--                     exactly as replay.lua
--   env CRASH_VECTORS authoritative mode: vectors to trap (default
--                     "2,3,4,5,6,7,24": bus/address/illegal/div0/CHK/TRAPV/
--                     spurious)
--   env CODE_RANGES   cheap mode: "start-end,start-end" hex PC whitelist;
--                     unset = no PC check
--   env GUARD_MATCH   cheap+auth: "a-b" frames during which $FF8004.l must
--                     stay 0x40000 (in-match flag); unset = no check
--
-- Log grammar (grep-able): normal "<frame> <fnv1a64>" lines, then any of
--   CRASH <frame> vec<n> PC <pc6> SP <sp8> ADDR <addr8>|-
--   STACK <sp8> <val8>            (up to 16 ROM-plausible return addresses)
--   PCWEEDS <frame> <pc6>         (max 10, then suppressed)
--   SOFTRESET <frame> <val8>
-- and finally "END <n>" (clean) or "END-CRASH <frame>" (crashed).

local replay_path = assert(os.getenv("REPLAY"), "set REPLAY to the input script path")
local out_path = os.getenv("CHECKSUM_OUT") or "replay_checksums.txt"
local tail_frames = tonumber(os.getenv("TAIL_FRAMES") or "") or 120

-- ── field lookup (identical to replay.lua) ───────────────────────────────────

local ioport = manager.machine.ioport
local function field_of(port, name)
    local p = ioport.ports[port]
    assert(p, "no port " .. port)
    local f = p.fields[name]
    assert(f, "no field '" .. name .. "' in " .. port)
    return f
end

local FIELDS = {
    p1 = {
        U = field_of(":IN0", "P1 Up"), D = field_of(":IN0", "P1 Down"),
        L = field_of(":IN0", "P1 Left"), R = field_of(":IN0", "P1 Right"),
        ["1"] = field_of(":IN0", "P1 Button 1"), ["2"] = field_of(":IN0", "P1 Button 2"),
        ["3"] = field_of(":IN0", "P1 Button 3"), ["4"] = field_of(":IN1", "P1 Button 4"),
        ["5"] = field_of(":IN1", "P1 Button 5"), ["6"] = field_of(":IN1", "P1 Button 6"),
    },
    p2 = {
        U = field_of(":IN0", "P2 Up"), D = field_of(":IN0", "P2 Down"),
        L = field_of(":IN0", "P2 Left"), R = field_of(":IN0", "P2 Right"),
        ["1"] = field_of(":IN0", "P2 Button 1"), ["2"] = field_of(":IN0", "P2 Button 2"),
        ["3"] = field_of(":IN0", "P2 Button 3"), ["4"] = field_of(":IN1", "P2 Button 4"),
        ["5"] = field_of(":IN1", "P2 Button 5"), ["6"] = field_of(":IN2", "P2 Button 6"),
    },
    sys = {
        S1 = field_of(":IN2", "1 Player Start"), S2 = field_of(":IN2", "2 Players Start"),
        C1 = field_of(":IN2", "Coin 1"), C2 = field_of(":IN2", "Coin 2"),
        SV = field_of(":IN2", "Service 1"), TS = field_of(":IN2", "Service Mode"),
    },
}

local function split_tokens(who, s)
    local toks, step = {}, (who == "sys") and 2 or 1
    for i = 1, #s, step do toks[#toks + 1] = s:sub(i, i + step - 1) end
    return toks
end

-- ── parse replay (identical to replay.lua) ───────────────────────────────────

local held = {}
local last_frame = 0

local lineno = 0
for line in io.lines(replay_path) do
    lineno = lineno + 1
    local body = line:gsub("#.*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #body > 0 then
        local range, rest = body:match("^(%S+)%s+(.*)$")
        assert(range, replay_path .. ":" .. lineno .. ": expected '<frame>[-<end>] who=tokens'")
        local a, b = range:match("^(%d+)%-(%d+)$")
        if not a then a = range:match("^(%d+)$"); b = a end
        assert(a, replay_path .. ":" .. lineno .. ": bad frame range '" .. range .. "'")
        a, b = tonumber(a), tonumber(b)
        assert(a >= 1 and b >= a, replay_path .. ":" .. lineno .. ": bad range")
        for spec in rest:gmatch("%S+") do
          if spec ~= "wait" then
            local who, toks = spec:match("^(%a+%d?)=(%S+)$")
            local group = FIELDS[who]
            assert(group, replay_path .. ":" .. lineno .. ": unknown side '" .. tostring(who) .. "'")
            for _, t in ipairs(split_tokens(who, toks)) do
                local field = group[t]
                assert(field, replay_path .. ":" .. lineno .. ": unknown token '" .. t .. "' for " .. who)
                for fr = a, b do
                    held[fr] = held[fr] or {}
                    held[fr][#held[fr] + 1] = field
                end
            end
        end
        end
        if b > last_frame then last_frame = b end
    end
end

local total_frames = last_frame + tail_frames

local snap_at = {}
for n in (os.getenv("SNAP_FRAMES") or ""):gmatch("%d+") do
    local fr = tonumber(n)
    snap_at[fr] = true
    if fr + 1 > total_frames then total_frames = fr + 1 end
end

local dump_at = {}
local out_dir = out_path:match("^(.*)/[^/]+$") or "."
for spec in (os.getenv("DUMPS") or ""):gmatch("[^;]+") do
    local fr, first, last = spec:match("^(%d+):(%x+)%-(%x+)$")
    assert(fr, "bad DUMPS spec: " .. spec)
    fr = tonumber(fr)
    dump_at[fr] = dump_at[fr] or {}
    table.insert(dump_at[fr], { tonumber(first, 16), tonumber(last, 16) })
    if fr + 1 > total_frames then total_frames = fr + 1 end
end

-- ── guard config ─────────────────────────────────────────────────────────────

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local program = cpu.spaces["program"]
local debugger = machine.debugger  -- nil unless -debug

local code_ranges = {}
for a, b in (os.getenv("CODE_RANGES") or ""):gmatch("(%x+)%-(%x+)") do
    code_ranges[#code_ranges + 1] = { tonumber(a, 16), tonumber(b, 16) }
end

local match_a, match_b
do
    local a, b = (os.getenv("GUARD_MATCH") or ""):match("^(%d+)%-(%d+)$")
    if a then match_a, match_b = tonumber(a), tonumber(b) end
end

local f = assert(io.open(out_path, "wb"))
local frame = 0
local crashed = false
local weeds_logged = 0

-- authoritative mode: map exception-handler address -> vector number.
-- Vector reads are data-space accesses on the 68k, so program-space reads
-- here see the same (unencrypted) values the CPU uses.
local handler_vec = {}
if debugger then
    local vecs = {}
    for n in (os.getenv("CRASH_VECTORS") or "2,3,4,5,6,7,24"):gmatch("%d+") do
        vecs[#vecs + 1] = tonumber(n)
    end
    debugger:command("focus 0")
    for _, n in ipairs(vecs) do
        local h = program:read_u32(n * 4)
        if h < 0x400000 and h % 2 == 0 then
            if not handler_vec[h] then
                handler_vec[h] = n
                -- 0x prefix is load-bearing: bare hex like "d0" parses as
                -- the REGISTER D0 in debugger expressions
                debugger:command(string.format("bpset 0x%x", h))
            end
        end
    end
end

local function rom_plausible(v)
    return v >= 0x000100 and v < 0x400000 and v % 2 == 0
end

local function on_crash(vec)
    crashed = true
    local st = cpu.state
    local sp = (st["A7"] or st["SP"]).value
    local fault_pc, fault_addr
    if vec == 2 or vec == 3 then
        -- group-0 frame: FC.w, fault address.l, IR.w, SR.w, PC.l
        fault_addr = program:read_u32(sp + 2)
        fault_pc = program:read_u32(sp + 10)
    else
        -- group-1/2 frame: SR.w, PC.l
        fault_pc = program:read_u32(sp + 2)
    end
    f:write(string.format("CRASH %d vec%d PC %06x SP %08x ADDR %s\n",
        frame, vec, fault_pc & 0xFFFFFF, sp,
        fault_addr and string.format("%08x", fault_addr) or "-"))
    -- stack sketch: ROM-plausible longs walking up from SP
    local shown = 0
    for off = 0, 63 * 4, 4 do
        local a = sp + off
        if a >= 0xFFFFFC then break end
        local v = program:read_u32(a)
        if rom_plausible(v) then
            f:write(string.format("STACK %08x %08x\n", a, v))
            shown = shown + 1
            if shown >= 16 then break end
        end
    end
    local df = assert(io.open(string.format("%s/crash_%d_ff0000.bin", out_dir, frame), "wb"))
    df:write(program:read_range(0xff0000, 0xffffff, 8))
    df:close()
    f:write(string.format("END-CRASH %d\n", frame))
    f:close()
    machine:exit()
end

if debugger then
    emu.register_periodic(function()
        if crashed then return end
        if debugger.execution_state == "stop" then
            local pc = cpu.state["CURPC"].value & 0xFFFFFF
            local vec = handler_vec[pc]
            if vec then
                on_crash(vec)
            else
                -- initial debugger halt or unrelated stop: resume silently
                debugger.execution_state = "run"
            end
        end
    end)
end

-- ── per-frame drive (replay.lua core + cheap-mode checks) ────────────────────

local FNV_PRIME = 0x100000001b3
local function fnv1a64(s)
    local h = 0xcbf29ce484222325
    local n = #s - (#s % 8)
    for i = 1, n, 8 do
        h = (h ~ string.unpack("<i8", s, i)) * FNV_PRIME
    end
    for i = n + 1, #s do
        h = (h ~ s:byte(i)) * FNV_PRIME
    end
    return h
end

local all_fields = {}
for _, group in pairs(FIELDS) do
    for _, field in pairs(group) do all_fields[#all_fields + 1] = field end
end
local pressed = {}

emu.register_frame_done(function()
    if crashed then return end
    frame = frame + 1

    f:write(string.format("%d %016x\n", frame, fnv1a64(program:read_range(0xff0000, 0xffffff, 8))))
    if snap_at[frame] then machine.video:snapshot() end
    for _, range in ipairs(dump_at[frame] or {}) do
        local df = assert(io.open(string.format("%s/dump_%d_%06x.bin", out_dir, frame, range[1]), "wb"))
        df:write(program:read_range(range[1], range[2], 8))
        df:close()
    end

    -- cheap-mode PC classification (also harmless under -debug)
    if #code_ranges > 0 then
        local pc = cpu.state["CURPC"].value & 0xFFFFFF
        local ok = false
        for _, r in ipairs(code_ranges) do
            if pc >= r[1] and pc < r[2] then ok = true; break end
        end
        if not ok and weeds_logged < 10 then
            f:write(string.format("PCWEEDS %d %06x\n", frame, pc))
            weeds_logged = weeds_logged + 1
            if weeds_logged == 10 then f:write("PCWEEDS suppressed\n") end
        end
    end
    if match_a and frame >= match_a and frame <= match_b then
        local v = program:read_u32(0xff8004)
        if v ~= 0x40000 then
            f:write(string.format("SOFTRESET %d %08x\n", frame, v))
        end
    end

    local want = {}
    for _, field in ipairs(held[frame + 1] or {}) do want[field] = true end
    for _, field in ipairs(all_fields) do
        if want[field] and not pressed[field] then
            field:set_value(1); pressed[field] = true
        elseif not want[field] and pressed[field] then
            field:clear_value(); pressed[field] = nil
        end
    end

    if frame >= total_frames then
        f:write(string.format("END %d\n", frame))
        f:close()
        machine:exit()
    end
end)
