-- index_watch.lua — attribute a DANGEROUS dispatch index to the MOVE that
-- drove it, while a human plays normally (14z-78).
--
-- WHY THIS EXISTS. `audit_index_users.py` finds tenant data that lands in a
-- dispatch table's danger window, but it reports vs2 ADDRESSES. A player
-- cannot act on "hitbox_proj@0x0d073c" without sifting the whole movelist to
-- guess which move owns it — which is most of the work, and exactly the part
-- the static sweep was supposed to save.
--
-- This closes that loop from the other end. The dispatchers are RARE (one hit
-- in a full replay when measured), so a debugger breakpoint on them is cheap
-- enough to leave armed during live play. Play the movelist once per
-- character; every dispatch that lands in a danger window is logged with the
-- frame, the entry number, the character, and his sequence/sub-state at that
-- instant. The move names itself, because you know what you just pressed.
--
-- It also catches the CRASH the moment it happens, with the index in hand
-- rather than reconstructed afterwards from a faulting address.
--
-- WHAT IT WATCHES. The three tables `audit_index_space.py` reports as risky —
-- vsavj shorter than vs2 — with their last valid entry:
--
--     jmp 0x018464   base 0x018468   vsavj 80 entries   (Cosmo, Plasma Trap)
--     jmp 0x0185d6   base 0x0185da   vsavj 86 entries
--     jmp 0x03975a   base 0x03975e   vsavj 10 entries
--
-- Override with INDEX_WATCH="jmp:n_valid,jmp:n_valid,..." if the sweep's
-- numbers ever move; the defaults are the measured ones.
--
-- THE REGISTER HOLDS entry*2, NOT the entry (the trap NEXT_SESSION records
-- against audit_index_space's output). D0 is halved here before comparing, so
-- everything this logs is in ENTRY numbers.
--
-- Usage:  mame <set> -debug -debugger none -autoboot_script index_watch.lua
--         env INDEX_OUT=<path>   (default index_watch.txt)
--         env INDEX_ALL=1        log EVERY dispatch, not only dangerous ones
--                                (use to prove the watch is ARMED — a silent
--                                log and a broken breakpoint look identical)

local machine    = manager.machine
local cpu        = machine.devices[":maincpu"]
local program    = cpu.spaces["program"]
local debugger   = machine.debugger
local out_path   = os.getenv("INDEX_OUT") or "index_watch.txt"
local log_all    = (os.getenv("INDEX_ALL") or "") ~= ""

-- table -> last valid entry, measured by audit_index_space.py
local WATCH = {}
local spec = os.getenv("INDEX_WATCH")
if spec and #spec > 0 then
    for pair in spec:gmatch("[^,]+") do
        local a, n = pair:match("^%s*(%x+)%s*:%s*(%d+)%s*$")
        if a then WATCH[tonumber(a, 16)] = tonumber(n) end
    end
else
    WATCH[0x018464] = 80
    WATCH[0x0185d6] = 86
    WATCH[0x03975a] = 10
end

local f = io.open(out_path, "w")
local frame, hits, seen = 0, 0, 0

f:write("# index_watch: dangerous dispatch indices, attributed live\n")
for a, n in pairs(WATCH) do
    f:write(string.format("# watching jmp %06x, valid entries 0..%d\n", a, n - 1))
end
if not debugger then
    f:write("# FATAL: no debugger. Run MAME with -debug -debugger none, or\n")
    f:write("#        this file will stay empty and look like a clean result.\n")
    f:flush()
    return
end
f:flush()

for a in pairs(WATCH) do
    debugger:command(string.format("bpset 0x%x", a))
end
debugger:command("go")

emu.register_frame_done(function() frame = frame + 1 end)

emu.register_periodic(function()
    if debugger.execution_state ~= "stop" then return end
    local pc = cpu.state["CURPC"].value & 0xFFFFFF
    local n_valid = WATCH[pc]
    if not n_valid then return end            -- someone else's breakpoint
    -- D0 holds entry*2 at the `move.w (d8,PC,D0.w),Dn` / `jmp` pair.
    local d0 = cpu.state["D0"].value & 0xFFFF
    local entry = d0 >> 1
    local bad = (entry >= n_valid) or (d0 & 1) == 1
    seen = seen + 1
    if bad or log_all then
        -- Which fighter is mid-action decides WHOSE move this is. Both blocks
        -- are logged because a projectile's dispatch can outlive the attacker
        -- and because the victim's state is often what disambiguates.
        local p1c = program:read_u8(0xFF8782)
        local p2c = program:read_u8(0xFF8B82)
        f:write(string.format(
            "%s f%d  jmp %06x  entry %d (valid 0..%d)  " ..
            "P1 char=%02x seq=%02x/%02x  P2 char=%02x seq=%02x/%02x\n",
            bad and "DANGER" or "ok    ", frame, pc, entry, n_valid - 1,
            p1c, program:read_u8(0xFF8406), program:read_u8(0xFF8407),
            p2c, program:read_u8(0xFF8806), program:read_u8(0xFF8807)))
        f:flush()
        if bad then hits = hits + 1 end
    end
    debugger:command("go")
end)

-- MAME 0.288's Lua has no emu.register_stop, so the summary cannot be written
-- at exit. Every line is flushed as it happens instead, and the running totals
-- are written periodically so an interrupted session still leaves a usable
-- record -- which matters here, because a human ends this run by closing the
-- window, not by reaching a frame count.
-- HEARTBEAT. MAME 0.288's Lua has no emu.register_stop, so nothing can be
-- written at exit; and an earlier version only reported once `seen > 0`, which
-- meant a watch that never fired produced a TIDY-LOOKING log with no dispatch
-- lines and no warning. A whole Phobos sweep was recorded that way and told us
-- nothing (14z-78). The heartbeat therefore fires REGARDLESS of seen, so
-- "armed but idle" and "never armed" can never look alike again.
local last_report, ticks = -1, 0
emu.register_periodic(function()
    ticks = ticks + 1
    if ticks % 600 ~= 0 then return end          -- ~ once a second
    if seen == last_report then return end
    last_report = seen
    if seen == 0 then
        f:write(string.format(
            "# WARNING f%d: %d dispatches seen. The watch is ARMED but has " ..
            "observed NOTHING yet. If this is the last line in the file, the " ..
            "run recorded no data and proves nothing.\n", frame, seen))
    else
        f:write(string.format("# progress f%d dispatches_seen=%d dangerous=%d\n",
                              frame, seen, hits))
    end
    f:flush()
end)

-- And say it up front too, so the file is never silent about its own state.
f:write("# NOTE: if no 'ok'/'DANGER' line and no progress line ever appears,\n")
f:write("#       this run observed NOTHING. That is not a clean result.\n")
f:write("#       Verify with INDEX_ALL=1 first: it should log every dispatch.\n")
f:flush()
