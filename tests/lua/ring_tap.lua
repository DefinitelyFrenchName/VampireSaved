-- log every sound id enqueued into the 68k ring (FF0E0E, 16B entries),
-- with frame + PC of the writer. env: REPLAY, FRAMES, TRACE_OUT, WINDOW
--
-- INPUT-STAGING CONVENTION (banner added 14z-93, GitHub issue #10). This
-- instrument stages inputs at the START of the frame callback
-- (`prev = held[frame]`, :90), whereas tests/lua/replay.lua stages for the
-- NEXT frame at the END (`held[frame + 1]`). A script line N is therefore
-- live during emulated frame N+1 here and during frame N there — a
-- ONE-FRAME LATE shift. It matters for this instrument because its output
-- IS frame-addressed (WINDOW=a,b) and audit_pyron_ring / audit_trap_sound /
-- audit_voice_borrow pin windows against it. DO NOT cross-reference a frame
-- number from this log with a compare_* first-divergence, a masked window
-- onset, or replay.lua's checksum log.
-- The fix is one line (stage `held[frame + 1]`), but it must move together
-- with re-deriving those pinned windows, which were tuned UNDER this
-- convention — see docs/project/gotchas.md, "Half the Lua instruments stage
-- inputs one frame off replay.lua".
local out_path=os.getenv("TRACE_OUT") or "ring.txt"
local max_frames=tonumber(os.getenv("FRAMES") or "3600")
local wa,wb=(os.getenv("WINDOW") or "0,99999999"):match("^(%d+),(%d+)$")
wa,wb=tonumber(wa),tonumber(wb)
local machine=manager.machine
local cpu=machine.devices[":maincpu"]
local space=cpu.spaces["program"]
local f=assert(io.open(out_path,"wb"))
local frame=0
local held={}
local replay_path=os.getenv("REPLAY")
if replay_path then
    local ioport=machine.ioport
    local function fld(p,n) return ioport.ports[p].fields[n] end
    local F={ p1={U=fld(":IN0","P1 Up"),D=fld(":IN0","P1 Down"),L=fld(":IN0","P1 Left"),R=fld(":IN0","P1 Right"),
                  ["1"]=fld(":IN0","P1 Button 1"),["2"]=fld(":IN0","P1 Button 2"),["3"]=fld(":IN0","P1 Button 3"),
                  ["4"]=fld(":IN1","P1 Button 4"),["5"]=fld(":IN1","P1 Button 5"),["6"]=fld(":IN1","P1 Button 6")},
              p2={U=fld(":IN0","P2 Up"),D=fld(":IN0","P2 Down"),L=fld(":IN0","P2 Left"),R=fld(":IN0","P2 Right"),
                  ["1"]=fld(":IN0","P2 Button 1"),["2"]=fld(":IN0","P2 Button 2"),["3"]=fld(":IN0","P2 Button 3"),
                  ["4"]=fld(":IN1","P2 Button 4"),["5"]=fld(":IN1","P2 Button 5"),["6"]=fld(":IN2","P2 Button 6")},
              sys={S1=fld(":IN2","1 Player Start"),S2=fld(":IN2","2 Players Start"),C1=fld(":IN2","Coin 1"),
                   C2=fld(":IN2","Coin 2"),SV=fld(":IN2","Service 1"),TS=fld(":IN2","Service Mode")} }
    for line in io.lines(replay_path) do
        local body=line:gsub("#.*","")
        local range,rest=body:match("^%s*(%S+)%s+(.-)%s*$")
        if range then
            local a,b=range:match("^(%d+)%-(%d+)$")
            if not a then a=range:match("^(%d+)$"); b=a end
            if a then for spec in rest:gmatch("%S+") do
                local who,toks=spec:match("^(%a+%d?)=(%S+)$")
                if who and F[who] then
                    local st=(who=="sys") and 2 or 1
                    for i=1,#toks,st do local fo=F[who][toks:sub(i,i+st-1)]
                        if fo then for fr=tonumber(a),tonumber(b) do held[fr]=held[fr] or {}; held[fr][#held[fr]+1]=fo end end
                    end
                end
            end end
        end
    end
end
local tap
-- FULL=1 (14z-85g): ALSO log every word write into the ring, tagged with
-- entry index + offset, so the complete 16-byte entry {id.l, d2.l, d3.l,
-- pad} is reconstructable (the trap-parity A/B needs the d2/d3 param
-- fields, not just the id). The id lines above stay UNCHANGED in both
-- modes — audit_trap_sound.sh greps their exact format.
local full = (os.getenv("FULL") or "") ~= ""
local function install()
    tap=space:install_write_tap(0xFF0E0E,0xFF1DFF,"ring",function(offset,data,mask)
        if frame<wa or frame>wb then return end
        local rel = offset - 0xFF0E0E
        if full then
            f:write(string.format("F f%d e%02x +%x %04x pc %06x\n",
                frame, math.floor(rel/16), rel%16, data & 0xFFFF,
                cpu.state["CURPC"].value))
        end
        -- 68k move.l splits into two word writes; the id low word lands at +2
        if rel % 16 ~= 2 then return end
        local id=data & 0xFFFF
        if true then
            f:write(string.format("f%d id %04x pc %06x\n", frame, id, cpu.state["CURPC"].value))
        end
    end)
end
install()
space:add_change_notifier(function() if tap then install() end end)
-- POKES="frame:addr:hexbytes;..." (14z-82d): the forced-pick rig grammar,
-- same as replay.lua/type_write_census.lua — without it no tenant replay
-- can be ring-tapped (the pick never happens and the tap reads a
-- different character's sounds as if they were the tenant's).
local pokes={}
for spec in (os.getenv("POKES") or ""):gmatch("[^;]+") do
    local fr,addr,hexs=spec:match("^(%d+):(%x+):(%x+)$")
    if fr then pokes[#pokes+1]={tonumber(fr),tonumber(addr,16),hexs} end
end
local prev={}
emu.register_frame_done(function()
    frame=frame+1
    for _,pk in ipairs(pokes) do
        if pk[1]==frame then
            local a=pk[2]
            for b in pk[3]:gmatch("%x%x") do
                space:write_u8(a,tonumber(b,16)); a=a+1
            end
        end
    end
    for _,fo in ipairs(prev) do fo:set_value(0) end
    prev=held[frame] or {}
    for _,fo in ipairs(prev) do fo:set_value(1) end
    if frame>=max_frames then f:write("END\n"); f:close(); manager.machine:exit() end
end)
