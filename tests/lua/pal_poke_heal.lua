-- poke garbage into the medallion palette rows mid-select; log content
-- before, right after the poke, and after the heal window
local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local prog = cpu.spaces["program"]
local out = assert(io.open(os.getenv("TRACE_OUT"), "wb"))
local poke_at = tonumber(os.getenv("POKE_AT") or "1300")
local ROWS = {0x16, 0x19, 0x00}
local frame = 0
local held = {}
local ioport = machine.ioport
local function fld(port, name) return ioport.ports[port].fields[name] end
local FIELDS = { p1={U=fld(":IN0","P1 Up"),D=fld(":IN0","P1 Down"),L=fld(":IN0","P1 Left"),R=fld(":IN0","P1 Right"),
                     ["1"]=fld(":IN0","P1 Button 1")},
                 sys={S1=fld(":IN2","1 Player Start"),C1=fld(":IN2","Coin 1")} }
for line in io.lines(os.getenv("REPLAY")) do
  local body = line:gsub("#.*","")
  local range, rest = body:match("^%s*(%S+)%s+(.-)%s*$")
  if range then
    local a,b = range:match("^(%d+)%-(%d+)$")
    if not a then a = range:match("^(%d+)$"); b=a end
    if a then
      for spec in rest:gmatch("%S+") do
        local who,toks = spec:match("^(%a+%d?)=(%S+)$")
        if who and FIELDS[who] then
          local step = (who=="sys") and 2 or 1
          for i=1,#toks,step do
            local fo = FIELDS[who][toks:sub(i,i+step-1)]
            if fo then for fr=tonumber(a),tonumber(b) do held[fr]=held[fr] or {}; held[fr][#held[fr]+1]=fo end end
          end
        end
      end
    end
  end
end
local pressed = {}
local function rowhex(r)
  local s = ""
  for k = 0, 7 do s = s .. string.format("%04x", prog:read_u16(0x90C000 + r*0x20 + 2*k)) end
  return s
end
emu.register_frame_done(function()
  frame = frame + 1
  local want = {}
  for _,fo in ipairs(held[frame+1] or {}) do want[fo]=true end
  for _,g in pairs(FIELDS) do for _,fo in pairs(g) do
    if want[fo] and not pressed[fo] then fo:set_value(1); pressed[fo]=true
    elseif not want[fo] and pressed[fo] then fo:clear_value(); pressed[fo]=nil end
  end end
  if frame == poke_at - 1 then
    for _,r in ipairs(ROWS) do out:write(string.format("BEFORE row %02x %s\n", r, rowhex(r))) end
  elseif frame == poke_at then
    for _,r in ipairs(ROWS) do
      for k = 0, 15 do prog:write_u16(0x90C000 + r*0x20 + 2*k, 0xFAAA) end
    end
    for _,r in ipairs(ROWS) do out:write(string.format("POKED  row %02x %s\n", r, rowhex(r))) end
  elseif frame == poke_at + 3 then
    for _,r in ipairs(ROWS) do out:write(string.format("AFTER  row %02x %s\n", r, rowhex(r))) end
    out:close(); manager.machine:exit()
  end
end)
-- (installed 14z-63: the white-out heal control for tests/test_wheel_bank5.sh.
--  env: REPLAY, POKE_AT, TRACE_OUT. Pokes 0xFAAA over the three medallion
--  palette rows mid-select and logs BEFORE/POKED/AFTER — the per-frame
--  re-assert thunk must restore them within 3 frames.)
