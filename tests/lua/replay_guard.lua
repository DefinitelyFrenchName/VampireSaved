-- replay_guard.lua — replay.lua plus crash detection: identical checksum-log
-- output, plus CRASH/PCWEEDS/SOFTRESET lines when the game leaves the rails.
--
-- SUBSTITUTABILITY, STATED HONESTLY (corrected 14z-94, GitHub #31). The
-- header used to claim "same env contract ... can substitute for replay.lua
-- in ANY gate". It does not implement MASK_RANGES, and it did not implement
-- the input-integrity assertion. It now REFUSES to run when MASK_RANGES or
-- NO_INPUT_CHECK is set rather than ignoring them, and it carries the
-- integrity check. So: substitutable for UNMASKED comparisons; for a masked
-- one, use replay.lua.
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
--   PROBE <frame> D0=.. D1=.. A0=.. A6=.. RET <sp0.l> [MEM[reg+off]=bb]
--                                 (GUARD_PROBE hits; GUARD_PROBE_MEM adds MEM;
--                                 non-fatal, run continues; PROBE-CAP at 400)
-- and finally "END <n>" (clean) or "END-CRASH <frame>" (crashed).

local replay_path = assert(os.getenv("REPLAY"), "set REPLAY to the input script path")
local out_path = os.getenv("CHECKSUM_OUT") or "replay_checksums.txt"
local tail_frames = tonumber(os.getenv("TAIL_FRAMES") or "") or 120

-- ── field lookup (identical to replay.lua) ───────────────────────────────────

local ioport = manager.machine.ioport
-- FIELD_INFO[field] = { port tag, bit mask }, recorded at construction so the
-- input-integrity check below never re-derives which port a field belongs to
-- (MAME may hand out a fresh wrapper per lookup, so identity matching against
-- port.fields later is unreliable). Same construction as replay.lua.
local FIELD_INFO = {}
local function field_of(port, name)
    local p = ioport.ports[port]
    assert(p, "no port " .. port)
    local f = p.fields[name]
    assert(f, "no field '" .. name .. "' in " .. port)
    FIELD_INFO[f] = { port, f.mask }
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

-- ── WHAT THIS SCRIPT DOES NOT IMPLEMENT, STATED LOUDLY (GitHub #31) ──────
-- The header used to advertise "same env contract ... can substitute for
-- replay.lua in any gate". It could not: MASK_RANGES was read by nobody here,
-- so a masked comparison run through the guard produced a WHOLE-work-RAM log
-- with the ratified windows still in it — compared against a masked basis
-- that diverges in the dead-stack window on every hooked build, i.e. a
-- phantom legacy regression with no reachable green state. Silently ignoring
-- an env var that changes what a log MEANS is worse than not supporting it.
if os.getenv("MASK_RANGES") then
    error("replay_guard.lua does not implement MASK_RANGES. Its log would be "
       .. "unmasked and would not be comparable to a masked basis. Use "
       .. "tests/lua/replay.lua for masked comparisons.", 0)
end
if os.getenv("NO_INPUT_CHECK") then
    error("NO_INPUT_CHECK is replay.lua's opt-out; setting it here implies an "
       .. "integrity check you did not get. Remove it, or use replay.lua.", 0)
end

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

-- GUARD_PC_LOG="a-b": log CURPC at end of every frame in [a,b] (loop hunts)
local pclog_a, pclog_b
do
    local a, b = (os.getenv("GUARD_PC_LOG") or ""):match("^(%d+)%-(%d+)$")
    if a then pclog_a, pclog_b = tonumber(a), tonumber(b) end
end

-- GUARD_TRACE="a-b": debugger instruction trace over frames [a,b] to
-- <CHECKSUM_OUT>.trace (needs -debug)
local trace_a, trace_b
do
    local a, b = (os.getenv("GUARD_TRACE") or ""):match("^(%d+)%-(%d+)$")
    if a then trace_a, trace_b = tonumber(a), tonumber(b) end
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
    local regs = {}
    for _, rn in ipairs({"D0","D1","D2","D3","D4","D5","D6","D7",
                         "A0","A1","A2","A3","A4","A5","A6"}) do
        local ok, v = pcall(function() return st[rn].value end)
        regs[#regs + 1] = string.format("%s=%08x", rn, ok and v or 0)
    end
    f:write("REGS " .. table.concat(regs, " ") .. "\n")
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
    -- 14z-82: crash-time instruction history (opt-in via GUARD_PROBE_HIST,
    -- same env as the probe-hit history). The exception pushes a
    -- MID-INSTRUCTION PC for group-0 faults, so the CRASH line alone cannot
    -- name the instruction STREAM into the fault; the debugger's `history`
    -- at the handler breakpoint can — the instrument that named the merged
    -- Huitzil vec3's route (14z-81b), now available without a separate
    -- probe address.
    local nh = tonumber(os.getenv("GUARD_PROBE_HIST") or "") or 0
    if nh > 0 and debugger then
        pcall(function()
            debugger:command(string.format("history maincpu,%d", nh))
            local cl = debugger.consolelog
            local n = #cl
            for i = math.max(1, n - nh), n do
                f:write("HIST " .. tostring(cl[i]) .. "\n")
            end
        end)
    end
    local df = assert(io.open(string.format("%s/crash_%d_ff0000.bin", out_dir, frame), "wb"))
    df:write(program:read_range(0xff0000, 0xffffff, 8))
    df:close()
    f:write(string.format("END-CRASH %d\n", frame))
    f:close()
    machine:exit()
end

-- GUARD_BREAK="hexaddr": break there and report like a crash (with stack
-- sketch) — e.g. the soft-reset entry, to catch who restarted the game
local break_addr = tonumber(os.getenv("GUARD_BREAK") or "", 16)
if debugger and break_addr then
    debugger:command(string.format("bpset 0x%x", break_addr))
end

-- GUARD_PROBE="hexaddr": conditional LOGGING breakpoint — on each hit write
--   PROBE <frame> D0=<v> D1=<v> A0=<v> A6=<v> RET <(SP)>
-- and CONTINUE (unlike GUARD_BREAK, which reports and exits). Optional
-- GUARD_PROBE_COND holds a raw debugger condition (e.g. "a0==0xe2830").
-- Capped at 400 hits by default (then the bp is cleared and a PROBE-CAP
-- line written). GUARD_PROBE_MAX raises the cap: the default silently
-- truncates a census of a HOT site, which is how a 14z-69p audit of
-- palette-seq ids first "proved" legacy uses exactly one id — it had
-- only seen each replay's first 400 calls. Raise it whenever the
-- question is "what values does this site EVER see".
local probe_addr = tonumber(os.getenv("GUARD_PROBE") or "", 16)
-- GUARD_PROBE_MEM="<reg>+<hexoff>" (e.g. "A6+382") appends MEM=<byte> to each
-- PROBE line: the byte at that register plus offset AT THE MOMENT OF THE HIT.
-- Added 14z-77 for the question "does the player struct already hold the
-- character id when the init shim runs?" — a register dump alone cannot
-- answer it, and frame-level ordering is too coarse for two events inside one
-- frame. Offset is hex, register is any name in cpu.state.
local probe_mem_reg, probe_mem_off
do
    local pm = os.getenv("GUARD_PROBE_MEM")
    if pm and #pm > 0 then
        probe_mem_reg, probe_mem_off = pm:match("^(%a%d?)%+(%x+)$")
        probe_mem_off = tonumber(probe_mem_off or "", 16)
    end
end
local probe_cond = os.getenv("GUARD_PROBE_COND")
local probe_hits = 0
local PROBE_MAX = tonumber(os.getenv("GUARD_PROBE_MAX") or "") or 400
-- GUARD_PROBE_HIST=N (14z-81): on each probe hit, append the debugger's
-- last-N-instruction `history` as HIST lines. Exists because a probe's
-- RET <(SP)> names the caller ONLY for jsr entry — a tail-JMP leaves (SP)
-- holding unrelated data, which is how the vec3 chase read a channel-record
-- pointer as a "RAM-stub caller". History names the real instruction stream
-- into the probe site.
-- 14z-82: the same env ALSO arms a crash-time history dump — on_crash()
-- appends HIST lines before END-CRASH, so a vec3's route can be named
-- without knowing a probe-able entry address first (the group-0 pushed PC
-- is mid-instruction and can never be probed — the standing gotcha).
local PROBE_HIST = tonumber(os.getenv("GUARD_PROBE_HIST") or "") or 0
-- GUARD_PROBE_TRACE=<path> (14z-81b): start a full instruction trace at the
-- FIRST probe hit and stop it at the SECOND. `history` shows the stream INTO
-- a site; this captures the stream OUT of it — a handler's complete tick is
-- everything between two consecutive dispatches. The trace file is large
-- (one frame ≈ a few MB of text); this is a diagnosis rig, never a gate.
local PROBE_TRACE = os.getenv("GUARD_PROBE_TRACE") or ""
if debugger and probe_addr then
    if probe_cond and #probe_cond > 0 then
        debugger:command(string.format("bpset 0x%x,%s", probe_addr, probe_cond))
    else
        debugger:command(string.format("bpset 0x%x", probe_addr))
    end
end

if debugger then
    emu.register_periodic(function()
        if crashed then return end
        if debugger.execution_state == "stop" then
            local pc = cpu.state["CURPC"].value & 0xFFFFFF
            local vec = handler_vec[pc]
            if vec then
                on_crash(vec)
            elseif probe_addr and pc == probe_addr then
                local st = cpu.state
                local sp = (st["A7"] or st["SP"]).value
                local memtxt = ""
                if probe_mem_reg and st[probe_mem_reg] then
                    local at = (st[probe_mem_reg].value + probe_mem_off)
                               & 0xFFFFFF
                    memtxt = string.format(" MEM[%s+%x=%06x]=%02x",
                                           probe_mem_reg, probe_mem_off, at,
                                           program:read_u8(at))
                end
                f:write(string.format(
                    "PROBE %d D0=%08x D1=%08x A0=%08x A6=%08x RET %08x%s\n",
                    frame, st["D0"].value, st["D1"].value,
                    st["A0"].value, st["A6"].value, program:read_u32(sp),
                    memtxt))
                if PROBE_HIST > 0 then
                    debugger:command(string.format("history maincpu,%d",
                                                   PROBE_HIST))
                    local cl = debugger.consolelog
                    local n = #cl
                    for i = math.max(1, n - PROBE_HIST), n do
                        f:write("HIST " .. tostring(cl[i]) .. "\n")
                    end
                end
                if PROBE_TRACE ~= "" then
                    if probe_hits == 0 then
                        debugger:command(string.format("trace %s,maincpu",
                                                       PROBE_TRACE))
                        f:write("TRACE-START\n")
                    elseif probe_hits == 1 then
                        debugger:command("trace off,maincpu")
                        f:write("TRACE-STOP\n")
                    end
                end
                probe_hits = probe_hits + 1
                if probe_hits >= PROBE_MAX then
                    debugger:command("bpclear")
                    -- re-arm the crash + break breakpoints the clear removed
                    for h in pairs(handler_vec) do
                        debugger:command(string.format("bpset 0x%x", h))
                    end
                    if break_addr then
                        debugger:command(string.format("bpset 0x%x", break_addr))
                    end
                    f:write("PROBE-CAP\n")
                end
                debugger.execution_state = "run"
            elseif break_addr and pc == break_addr then
                if frame > 100 then  -- ignore the boot-time pass
                    on_crash(99)
                else
                    debugger.execution_state = "run"
                end
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

-- POKES="frame:addr:hexbytes;..." — scheduled RAM writes (mirrors
-- replay.lua / tap_writes.lua; lets guarded runs use HP-poke repros)
local pokes = {}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr, addr, hexs = spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes + 1] = { tonumber(fr), tonumber(addr, 16), hexs } end
end

-- ── INPUT INTEGRITY ASSERTION (GitHub #31) ───────────────────────────────
-- Ported from replay.lua, where it is "deliberately not opt-in". ~17 gates
-- drive replays through this script — test_hui_grab, audit_merged_legacy leg
-- b, audit_objhook_owner_census and the rest — and every one of them ran with
-- no such check, while tools/run_replay_guarded.sh greps only for
-- CRASH/PCWEEDS/SOFTRESET/END. A stray host press therefore produced a clean
-- PASS on a run that was no longer a replay of anything. MAME's window takes
-- focus even under -video none (tests/test_input_integrity.sh).
local PORT_TAGS = { ":IN0", ":IN1", ":IN2" }
local integ_ports, baseline, controlled = {}, {}, {}
local violations, first_violation = 0, nil
for _, tag in ipairs(PORT_TAGS) do
    integ_ports[tag] = assert(ioport.ports[tag], "no port " .. tag)
    controlled[tag] = 0
end
-- Compare ONLY the bits this harness can drive: :IN2 also carries the EEPROM
-- data line, which legitimately toggles during boot. Host keystrokes land on
-- controller bits, so masking to them loses no detection power.
for _, group in pairs(FIELDS) do
    for _, field in pairs(group) do
        local info = FIELD_INFO[field]
        controlled[info[1]] = controlled[info[1]] | info[2]
    end
end
local inject_frame = tonumber(os.getenv("INPUT_INJECT_TEST") or "")

-- Expected port values for a frame's held set: the idle baseline with each
-- pressed field's mask cleared (CPS-2 inputs are active low).
local function expected_ports(frame_held)
    if not baseline[PORT_TAGS[1]] then return nil end
    local exp = {}
    for _, tag in ipairs(PORT_TAGS) do exp[tag] = baseline[tag] end
    for _, field in ipairs(frame_held or {}) do
        local info = FIELD_INFO[field]
        if info then exp[info[1]] = exp[info[1]] & ~info[2] end
    end
    return exp
end

emu.register_frame_done(function()
    if crashed then return end
    frame = frame + 1
    for _, pk in ipairs(pokes) do
        if pk[1] == frame then
            local a = pk[2]
            for b in pk[3]:gmatch("%x%x") do
                program:write_u8(a, tonumber(b, 16))
                a = a + 1
            end
        end
    end

    f:write(string.format("%d %016x\n", frame, fnv1a64(program:read_range(0xff0000, 0xffffff, 8))))
    if snap_at[frame] then machine.video:snapshot() end
    for _, range in ipairs(dump_at[frame] or {}) do
        local df = assert(io.open(string.format("%s/dump_%d_%06x.bin", out_dir, frame, range[1]), "wb"))
        df:write(program:read_range(range[1], range[2], 8))
        df:close()
    end

    if trace_a and frame == trace_a then
        debugger:command(string.format("trace %s.trace,0", out_path))
    end
    if trace_a and frame == trace_b then
        debugger:command("trace off,0")
    end
    if pclog_a and frame >= pclog_a and frame <= pclog_b then
        f:write(string.format("PC %d %06x\n", frame,
                              cpu.state["CURPC"].value & 0xFFFFFF))
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

    -- integrity: frame 1 captures the idle baseline (nothing staged yet);
    -- afterwards the live ports must equal what THIS script staged.
    if not baseline[PORT_TAGS[1]] then
        for _, tag in ipairs(PORT_TAGS) do
            baseline[tag] = integ_ports[tag]:read() & controlled[tag]
        end
    else
        local exp = expected_ports(held[frame])
        for _, tag in ipairs(PORT_TAGS) do
            local live = integ_ports[tag]:read() & controlled[tag]
            if inject_frame and frame == inject_frame and tag == ":IN0" then
                live = live & ~0x01          -- ground truth: a phantom press
            end
            if exp and live ~= (exp[tag] & controlled[tag]) then
                violations = violations + 1
                if not first_violation then
                    first_violation = string.format(
                        "INPUT-VIOLATION %d %s live %04x expected %04x",
                        frame, tag, live, exp[tag] & controlled[tag])
                    f:write(first_violation .. "\n")
                end
            end
        end
    end

    if frame >= total_frames then
        if violations > 0 then
            f:write(string.format("INPUT-VIOLATIONS %d\n", violations))
        end
        f:write(string.format("END %d\n", frame))
        f:close()
        machine:exit()
    end
end)
