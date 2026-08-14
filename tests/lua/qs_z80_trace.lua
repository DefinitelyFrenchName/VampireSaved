-- qs_z80_trace.lua — bounded Z80 execution trace around a ring-injected
-- sound id (14z-86, the M5 voice arc's 0x02E5 decode). Captures (a) an
-- optional `dasm` of the fixed ROM and (b) a `trace ...,noloop` window
-- opened just before each id is injected into the 68k sound ring and
-- closed WINDOW frames later — the per-instruction flow of the driver
-- consuming the id. (The Z80 turned out NOT to be encrypted — the
-- 14z-85d KABUKI claim was the file-mapping artifact, see
-- engine_internals "The QSound Z80 driver" — but the trace remains the
-- ground truth for CONTROL FLOW, which no static view gives you.)
-- Needs `-debug -debugger none` (run_mame.sh passes extra args through).
-- NEVER uses the debugger `focus` command: it suspends the other CPUs
-- and would perturb the very flow being measured.
--
--   env REPLAY   input script — the sweeps' venue is TEST MODE via
--                tests/replays/06_test_mode.rpl (ring index rests at
--                0x70 at f1050 there; engine_internals "qs_sweep").
--                Attract does NOT work: the live game ring owns the
--                head and the injected entry is never forwarded
--                (measured 14z-86, first capture).
--   env IDLIST   csv hex ids to inject (default 119)
--   env FIRST    frame of the first injection (default 1050 — attract)
--   env STEP     frames between injections (default 120)
--   env WINDOW   trace-window length in frames per id (default 10)
--   env PRE      frames the trace opens before the injection (default 2)
--   env RING_IDX hex ring index seed (default 70)
--   env TRACE_OUT  marker/event log (default qs_z80_trace.txt)
--   env ZTR_OUT    Z80 trace file (default z.tr; %d expands to id when
--                  more than one id is given)
--   env DASM     "file:start:len" (hex start/len) — also emit a decrypted
--                disassembly of the Z80 fixed ROM, e.g. "zdasm.txt:0:8000"
--   env FRAMES   hard stop (default 3600)

local ids = {}
for tok in (os.getenv("IDLIST") or "119"):gmatch("[^,]+") do
    ids[#ids+1] = tonumber(tok, 16)
end
local firstf   = tonumber(os.getenv("FIRST") or "1050")
local stepf    = tonumber(os.getenv("STEP") or "120")
local window   = tonumber(os.getenv("WINDOW") or "10")
local pre      = tonumber(os.getenv("PRE") or "2")
local ring_idx = tonumber(os.getenv("RING_IDX") or "70", 16)
local out_path = os.getenv("TRACE_OUT") or "qs_z80_trace.txt"
local ztr_out  = os.getenv("ZTR_OUT") or "z.tr"
local max_frames = tonumber(os.getenv("FRAMES") or "3600")

local machine  = manager.machine
local m68k     = machine.devices[":maincpu"].spaces["program"]
local debugger = machine.debugger

-- replay playback (qs_table_trace.lua's block, verbatim semantics)
local held = {}
local replay_path = os.getenv("REPLAY")
if replay_path then
    local ioport = machine.ioport
    local function fld(port, name) return ioport.ports[port].fields[name] end
    local FIELDS = {
        p1 = { U=fld(":IN0","P1 Up"),D=fld(":IN0","P1 Down"),L=fld(":IN0","P1 Left"),R=fld(":IN0","P1 Right"),
               ["1"]=fld(":IN0","P1 Button 1"),["2"]=fld(":IN0","P1 Button 2"),["3"]=fld(":IN0","P1 Button 3"),
               ["4"]=fld(":IN1","P1 Button 4"),["5"]=fld(":IN1","P1 Button 5"),["6"]=fld(":IN1","P1 Button 6") },
        p2 = { U=fld(":IN0","P2 Up"),D=fld(":IN0","P2 Down"),L=fld(":IN0","P2 Left"),R=fld(":IN0","P2 Right"),
               ["1"]=fld(":IN0","P2 Button 1"),["2"]=fld(":IN0","P2 Button 2"),["3"]=fld(":IN0","P2 Button 3"),
               ["4"]=fld(":IN1","P2 Button 4"),["5"]=fld(":IN1","P2 Button 5"),["6"]=fld(":IN2","P2 Button 6") },
        sys = { S1=fld(":IN2","1 Player Start"),S2=fld(":IN2","2 Players Start"),
                C1=fld(":IN2","Coin 1"),C2=fld(":IN2","Coin 2"),
                SV=fld(":IN2","Service 1"),TS=fld(":IN2","Service Mode") },
    }
    for line in io.lines(replay_path) do
        local body = line:gsub("#.*", "")
        local range, rest = body:match("^%s*(%S+)%s+(.-)%s*$")
        if range then
            local a, b = range:match("^(%d+)%-(%d+)$")
            if not a then a = range:match("^(%d+)$"); b = a end
            if a then
                for spec in rest:gmatch("%S+") do
                    local who, toks = spec:match("^(%a+%d?)=(%S+)$")
                    if who and FIELDS[who] then
                        local step = (who == "sys") and 2 or 1
                        for i = 1, #toks, step do
                            local fo = FIELDS[who][toks:sub(i, i+step-1)]
                            if fo then
                                for fr = tonumber(a), tonumber(b) do
                                    held[fr] = held[fr] or {}
                                    held[fr][#held[fr]+1] = fo
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local f = assert(io.open(out_path, "wb"))

if not debugger then
    f:write("# FATAL: no debugger. Run MAME with -debug -debugger none.\n")
    f:close()
    manager.machine:exit()
    return
end
debugger:command("go")

local dasm_spec = os.getenv("DASM")
if dasm_spec then
    local file, start, len = dasm_spec:match("^([^:]+):(%x+):(%x+)$")
    if file then
        -- 0.288 syntax: dasm <file>,<offset>,<length>[,<bytes bool>[,<device>]]
        -- (the device is the FIFTH param; putting it fourth fails the boolean
        -- validator and the command returns with no output file, silently)
        debugger:command(string.format("dasm %s,0x%x,0x%x,1,:audiocpu",
                                       file, tonumber(start, 16), tonumber(len, 16)))
        f:write(string.format("# dasm %s 0x%x len 0x%x\n",
                              file, tonumber(start, 16), tonumber(len, 16)))
    else
        f:write("# FATAL: bad DASM spec (want file:starthex:lenhex)\n")
        f:close()
        manager.machine:exit()
        return
    end
end

local frame, n, idx = 0, 0, ring_idx
local tracing = false
local prev = {}

emu.register_frame_done(function()
    frame = frame + 1
    for _, fo in ipairs(prev) do fo:set_value(0) end
    prev = held[frame] or {}
    for _, fo in ipairs(prev) do fo:set_value(1) end
    local k = n + 1
    if k <= #ids then
        local open_f  = firstf + n * stepf - pre
        local shot_f  = firstf + n * stepf
        if frame == open_f then
            local file = (#ids > 1) and ztr_out:format(ids[k]) or ztr_out
            debugger:command(string.format("trace %s,:audiocpu,noloop", file))
            tracing = true
            f:write(string.format("== f%d trace-open id %04x -> %s ==\n",
                                  frame, ids[k], file))
        elseif frame == shot_f then
            local base = 0xFF0E0E + idx
            m68k:write_u32(base, ids[k])
            m68k:write_u32(base + 4, 0)
            m68k:write_u32(base + 8, 0)
            idx = (idx + 0x10) & 0xFF0
            m68k:write_u16(0xFF1E0E, idx)
            f:write(string.format("== f%d inject id %04x ring_idx %03x ==\n",
                                  frame, ids[k], idx))
        elseif frame == shot_f + window then
            debugger:command("trace off,:audiocpu")
            tracing = false
            n = n + 1
            f:write(string.format("== f%d trace-close id %04x ==\n",
                                  frame, ids[k]))
            if n >= #ids then
                f:write("END all ids traced\n")
                f:close()
                manager.machine:exit()
                return
            end
        end
    end
    if frame >= max_frames then
        if tracing then debugger:command("trace off,:audiocpu") end
        f:write(string.format("END frames %d ids_done %d/%d\n", frame, n, #ids))
        f:close()
        manager.machine:exit()
    end
end)
