import re, sys, json
from collections import defaultdict
# parse sweep log -> per id: list of key-ons (bank,start,end,loop)
# QSound: voice v regs at v*8+k; bank for voice v lives at ((v-1)&15)*8+0
log, out = sys.argv[1], sys.argv[2]
tri={}
regs={}          # last-known reg values
cur=None; curfr=0
markers={}       # frame -> id
events=defaultdict(list)
id_start_frame={}
order=[]
for line in open(log):
    m=re.match(r"== f(\d+) id (\w+) ==", line)
    if m:
        cur=m.group(2); id_start_frame[cur]=int(m.group(1)); order.append(cur); continue
    m=re.match(r"f(\d+) w d00(\d) (\w+)", line)
    if not m: continue
    fr,port,val=int(m.group(1)),int(m.group(2)),int(m.group(3),16)
    tri[port]=val
    if port!=2: continue
    reg=val; data=tri.get(0,0)<<8|tri.get(1,0)
    prev=regs.get(reg)
    regs[reg]=data
    if reg<0x80 and (reg&7)==3 and data==0x8000 and cur is not None:
        v=reg>>3
        fr0=id_start_frame[cur]
        if fr0 <= fr < fr0+12:
            bank = regs.get(((v-1)&15)*8, 0) & 0x7F
            start= regs.get(v*8+1, 0)
            end  = regs.get(v*8+5, 0)
            loop = regs.get(v*8+4, 0)
            events[cur].append((v,bank,start,end,loop))
res={}
for cid in order:
    if events.get(cid):
        res[cid]=events[cid]
json.dump(res, open(out,'w'))
print(f"{len(res)} ids with key-ons of {len(order)} swept")
# quick sanity print
for cid in list(res)[:6]:
    print(cid, [(f"v{v}",f"b{b:02x}",f"s{s:04x}",f"e{e:04x}") for v,b,s,e,l in res[cid][:4]])
