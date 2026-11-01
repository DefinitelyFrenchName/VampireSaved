-- pal_rows_tap.lua — PER-FRAME OBJECT-PALETTE ROWS of a fighter, with a write tap on one row (14z-216, GitHub #127/#162;
-- promoted from the #127 analysis probe build/agent216/t127/rig/pod_rig.lua). Used by tests/audit_don_row0b.sh.
-- Drives a replay (replay.lua grammar, staged held[frame+1] like inp_probe.lua),
-- applies POKES, logs per frame: P1/P2 HP, P1 palette row (+0x18B), P1 node (+0x1C),
-- the colour at PALROW idx PALIDX, OBJ entries per palette row of interest (both
-- buffers), and every write to the palette page $90C000-$90C3FF row PALROW with
-- PC/A6/A0 (write tap, re-installed on map change). Snapshots at SNAP_FRAMES.
-- env REPLAY OUT POKES SNAP_FRAMES MAX_FRAMES PALROW(hex, default 0b) PALIDX(default 14)
--     OBJROWS (hex list of palette rows to count in OBJ, default "0b,05")
--     OBJDUMP "f1-f2" dump OBJ entries whose pal is in OBJROWS in that window
--     PALDUMP hex list of palette rows to dump whole every frame ("P <frame> <row>:<16 words>")
--     OPATCH  "addr:hexbytes" written into the DECRYPTED-OPCODE share at frame 1 (the emulator only, nothing built),
--             read back as "OPATCH <spec> readback <word before><word at>"
-- Output lines: V (per-frame state; f1c3 = P1's +0x1C3, vs2's Dark Force flag, added 14z-216 for #294), P (palette rows), W (writes to PALROW idx PALIDX-1, PALIDX or 0), SNAP, END <frame>.
-- WHAT IT CANNOT SEE: palette writes outside PALROW (the P lines carry the state, not the writer); frames are
-- frame_done counts (non-debug, so emulated time).
local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local space = cpu.spaces["program"]
local opath = assert(os.getenv("OUT"), "OUT")
local out = assert(io.open(opath, "wb"))
local max_frames = tonumber(os.getenv("MAX_FRAMES") or "") or 4000
local palrow = tonumber(os.getenv("PALROW") or "0b", 16)
local palidx = tonumber(os.getenv("PALIDX") or "14")
local objrows = {}
for t in (os.getenv("OBJROWS") or "0b,05"):gmatch("[^,]+") do objrows[#objrows+1] = tonumber(t, 16) end
local od_a, od_b = (os.getenv("OBJDUMP") or "0-0"):match("^(%d+)-(%d+)$"); od_a, od_b = tonumber(od_a), tonumber(od_b)
local snap = {}
local paldump = {}
for t in (os.getenv("PALDUMP") or ""):gmatch("[^,]+") do paldump[#paldump+1] = tonumber(t, 16) end
for t in (os.getenv("SNAP_FRAMES") or ""):gmatch("%d+") do snap[tonumber(t)] = true end
local function s16(a) local v = space:read_u16(a); if v >= 0x8000 then v = v - 0x10000 end; return v end
-- replay
local ioport = machine.ioport
local function fld(p, n) local f = ioport.ports[p].fields[n]; assert(f, n); return f end
local F = {
  p1 = { U=fld(":IN0","P1 Up"), D=fld(":IN0","P1 Down"), L=fld(":IN0","P1 Left"), R=fld(":IN0","P1 Right"),
         ["1"]=fld(":IN0","P1 Button 1"), ["2"]=fld(":IN0","P1 Button 2"), ["3"]=fld(":IN0","P1 Button 3"),
         ["4"]=fld(":IN1","P1 Button 4"), ["5"]=fld(":IN1","P1 Button 5"), ["6"]=fld(":IN1","P1 Button 6") },
  p2 = { U=fld(":IN0","P2 Up"), D=fld(":IN0","P2 Down"), L=fld(":IN0","P2 Left"), R=fld(":IN0","P2 Right"),
         ["1"]=fld(":IN0","P2 Button 1"), ["2"]=fld(":IN0","P2 Button 2"), ["3"]=fld(":IN0","P2 Button 3"),
         ["4"]=fld(":IN1","P2 Button 4"), ["5"]=fld(":IN1","P2 Button 5"), ["6"]=fld(":IN2","P2 Button 6") },
  sys = { S1=fld(":IN2","1 Player Start"), S2=fld(":IN2","2 Players Start"), C1=fld(":IN2","Coin 1"), C2=fld(":IN2","Coin 2") },
}
local held = {}
local rpath = assert(os.getenv("REPLAY"), "REPLAY")
for line in io.lines(rpath) do
  local body = line:gsub("#.*", ""):gsub("^%s+", ""):gsub("%s+$", "")
  if #body > 0 then
    local range, rest = body:match("^(%S+)%s+(.*)$")
    local a, b = range:match("^(%d+)%-(%d+)$"); if not a then a = range; b = a end
    a, b = tonumber(a), tonumber(b)
    for spec in rest:gmatch("%S+") do
      if spec ~= "wait" then
        local who, toks = spec:match("^(%a+%d?)=(%S+)$")
        local step = (who == "sys") and 2 or 1
        for i = 1, #toks, step do
          local fo = assert(F[who][toks:sub(i, i + step - 1)], "token " .. toks)
          for fr = a, b do held[fr] = held[fr] or {}; table.insert(held[fr], fo) end
        end
      end
    end
  end
end
local pokes = {}
dofile((debug.getinfo(1, "S").source:match("^@(.*/)") or "./") .. "pokes_spec.lua").append(pokes, os.getenv("POKES"))
local frame = 0
-- palette write tap
local lo = 0x90C000 + palrow * 0x20
local hi = lo + 0x1F
local taps = {}
local function on_w(offset, data, mask)
  local ok, s = pcall(function()
    local st = cpu.state
    local usp, ssp = st["USP"].value, st["SP"].value
    local live = ((st["SR"].value & 0x2000) ~= 0) and ssp or usp
    local stk = {}
    for k = 0, 7 do stk[#stk+1] = string.format("%08x", space:read_u32(live + k * 4)) end
    return string.format("PC %06x A6 %08x A0 %08x D0 %08x stk %s", st["CURPC"].value & 0xFFFFFF, st["A6"].value, st["A0"].value, st["D0"].value, table.concat(stk, " "))
  end)
  local idx = (offset - lo) // 2
  if idx == palidx or idx == palidx - 1 or (offset - lo) == 0 then
    out:write(string.format("W %d off %06x idx %d data %08x mask %08x %s\n", frame, offset, idx, data, mask, ok and s or "regerr"))
  end
end
local function install() taps[#taps+1] = space:install_write_tap(lo, hi, "podw", on_w) end
install()
do local r = debug.getregistry(); r.vs_notifier_threads = r.vs_notifier_threads or {}; r.vs_notifier_threads[#r.vs_notifier_threads + 1] = coroutine.running() end
space:add_change_notifier(function(mode)
  if mode:find("w") then for _, t in ipairs(taps) do t:remove() end; taps = {}; install() end
end)
local function walk(base, counts, dumpit, bi)
  for i = 0, 0x3FF do
    local off = base + i * 8
    local y = space:read_u16(off + 2)
    if (y & 0x8000) ~= 0 then break end
    local attr = space:read_u16(off + 6)
    if attr >= 0xFF00 then break end
    local p = attr & 0x1F
    if counts[p] then
      counts[p] = counts[p] + 1
      if dumpit then
        out:write(string.format("O %d B%d E%03d x=%04x y=%04x code=%04x attr=%04x pal=%02x\n", frame, bi, i,
          space:read_u16(off), y, space:read_u16(off + 4), attr, p))
      end
    end
  end
end
local prev = {}
local opatch = os.getenv("OPATCH"); if opatch == "" then opatch = nil end
emu.register_frame_done(function()
  frame = frame + 1
  if opatch and frame == 1 then
    -- the #162 counterfactual's method (tests/lua/upload_tap.lua): one word into the DECRYPTED-OPCODE share,
    -- nothing built, nothing on disk.
    local sh = assert(machine.memory.shares[":decrypted_opcodes"], "no :decrypted_opcodes share")
    local pa, pb = opatch:match("^(%x+):(%x+)$")
    local a = tonumber(pa, 16)
    for bb in pb:gmatch("%x%x") do sh:write_u8(a, tonumber(bb, 16)); a = a + 1 end
    out:write(string.format("OPATCH %s readback %04x%04x\n", opatch, sh:read_u16(tonumber(pa, 16) - 2), sh:read_u16(tonumber(pa, 16))))
  end
  for _, pk in ipairs(pokes) do
    if pk[1] == frame then
      local a = pk[2]
      for bb in pk[3]:gmatch("%x%x") do space:write_u8(a, tonumber(bb, 16)); a = a + 1 end
    end
  end
  for _, fo in ipairs(prev) do fo:set_value(0) end
  prev = held[frame + 1] or {}
  for _, fo in ipairs(prev) do fo:set_value(1) end
  local dumpit = frame >= od_a and frame <= od_b
  local c0, c1 = {}, {}
  for _, r in ipairs(objrows) do c0[r] = 0; c1[r] = 0 end
  walk(0x708000, c0, dumpit, 0); walk(0x710000, c1, dumpit, 1)
  local cs = {}
  for _, r in ipairs(objrows) do cs[#cs+1] = string.format("r%02x=%d/%d", r, c0[r], c1[r]) end
  out:write(string.format("V %d hp1=%d hp2=%d id1=%02x id2=%02x f1c3=%02x row1=%02x row2=%02x n1=%08x st1=%08x c=%04x stk=%02x x1=%d x2=%d %s\n",
    frame, s16(0xFF8450), s16(0xFF8850), space:read_u8(0xFF8782), space:read_u8(0xFF8B82), space:read_u8(0xFF85C3),
    space:read_u8(0xFF858B), space:read_u8(0xFF898B), space:read_u32(0xFF841C), space:read_u32(0xFF8404),
    space:read_u16(lo + palidx * 2), space:read_u8(0xFF8509), space:read_u16(0xFF8410), space:read_u16(0xFF8810), table.concat(cs, " ")))
  if #paldump > 0 then
    local parts = {}
    for _, r in ipairs(paldump) do
      local o = 0x90C000 + r * 0x20
      local w = {}
      for i = 0, 15 do w[#w+1] = string.format("%04x", space:read_u16(o + i * 2)) end
      parts[#parts+1] = string.format("%02x:%s", r, table.concat(w))
    end
    out:write(string.format("P %d %s\n", frame, table.concat(parts, " ")))
  end
  if snap[frame] then machine.video:snapshot(); out:write(string.format("SNAP %d\n", frame)) end
  if frame >= max_frames then out:write(string.format("END %d\n", frame)); out:close(); machine:exit() end
end)
